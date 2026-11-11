#Region Variables

&AtClient
Var CachedValues; //used by the mechanism for processing changes in PM details

&AtClient
Var CurDataId; //used to pass the current line to the wait handler

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
	
	// Handler of the "Properties" subsystem
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("Object", Object);
	AdditionalParameters.Insert("ItemForPlacementName", "GroupAdditionalAttributes");
	AdditionalParameters.Insert("DeferredInitialization", True);
	PropertyManager.OnCreateAtServer(ThisForm, AdditionalParameters);
	
	// Handler of the "Destination" mechanism
	Catalogs.Assignments.DocumentFormWhenCreatedOnServer(ThisForm);
	
	FillInAccordingToDataInRepository();
	
	Items.GoodsProducts.ReadOnly   = Parameters.ProhibitChangingProducts;
	Items.GoodsCharacteristic.ReadOnly = Parameters.ProhibitChangingProducts;
	Items.GoodsCount.ReadOnly     = Parameters.ProhibitChangingProducts;
	Items.Warehouse.ReadOnly                = Parameters.ProhibitChangingProducts;
	Items.Organization.ReadOnly          = Parameters.ProhibitChangingProducts;
	Items.Goods.ChangeRowSet          = Not Parameters.ProhibitChangingProducts;
	Items.Fill.Enabled               = Not Parameters.ProhibitChangingProducts;
	
	TMCommonUseClientServer.SetFormItemProperty(Items, "GoodsImportDataFromPDT", "Visible",          True);
	TMCommonUseClientServer.SetFormItemProperty(Items, "GoodsGetWeight", "Visible",                   True);
	TMCommonUseClientServer.SetFormItemProperty(Items, "GoodsCheckQuantityInTheDocument", "Visible", True);
	
	Items.GoodsSearchByBarcode.Visible = AccessRight("Read", Metadata.InformationRegisters.ItemsBarcodes);
	
	TMCommonUse.CustomizePeripherals(ThisForm);
	
	RestrictGoodsReceiptWithoutCCDNumbers = GetFunctionalOption("RestrictGoodsReceiptWithoutCCDNumbers");
	
	If Not ValueIsFilled(Object.Ref) Then
		OnReadCreateAtServer();
	EndIf;
	If IsTempStorageURL(Parameters.AddressOfTheDataInTheStorage)
		Or Not ValueIsFilled(Object.Ref) Then
		ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);
	EndIf;
	
	// Selection of articles and analytics.
	ItemsAndDimensionsSelectionParameters = Documents.InventorySurplusRecognition.ItemsAndDimensionsSelectionParameters();
	IncomeAndExpensesServer.OnCreateAtServer(ThisObject, ItemsAndDimensionsSelectionParameters);
	
	DocumentCorrection.OnCreateAtServer(ThisForm, Items.LineCorrection);
	
	AccountingForTraceableGoodsLocalization.EstablishVisibilityOfRNPTQuantity(ThisForm, Object.Date);
	
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject);
	// End IntegrationWith1CDocumentManagementSubsystem
	
	
	Items.DecorationEDOState.Visible = GetFunctionalOption("UseElectronicDocumentExchangeWithCounterparties");
	
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	
	AccountingForTraceableGoodsLocalization.SetTitleNumberOfCCD(Items, "GoodsCCDNumber");
	
	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	// Subsystem "Properties"
	If PropertyManagerClient.ProcessNotifications(ThisObject, EventName, Parameter) Then
		UpdateAdditionalAttributesItems();
		PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
	EndIf;
	
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
	
	DocumentCorrectionClient.NotificationProcessing(ThisObject, EventName, Parameter, Source);
	
	
	FormEventsClient.NotificationProcessing(ThisObject, EventName, Parameter, Source);
	
EndProcedure

&AtClient
Procedure NewWriteProcessing(NewObject, Source, StandardProcessing)
	
	If PurchasesClient.ThisIsIndicationOfCCDNumber(Source) Then
		Actions = New Structure;
		
		AccountingForTraceableGoodsClientServerLocalization.AddDescriptionOfSettingsForRecalculatingDetailsOfTablePart(
			Object,
			Actions);
		
		PurchasesClient.ProcessIndicationOfCCDNumber(ThisObject, NewObject, , , Actions);
	EndIf;
	
EndProcedure

&AtClient
Procedure URLProcessing(FormattedStringURL, StandardProcessing)
	
	FormEventsClient.URLProcessing(ThisObject, FormattedStringURL, StandardProcessing);
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	// StandardSubsystems.Properties
	PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
	// End StandardSubsystems.Properties

	EquipmentManagerClient.StartConnectingDevicesWhenYouOpenForm(Undefined, ThisForm, "BarcodeScanner");
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	
	ExcisableGoodsAccountingClient.AfterCalculatingNumberOfExcisableItems(ThisObject);
EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	
	// StandardSubsystems.Properties
	PropertyManager.FillCheckProcessing(ThisForm, Cancel, CheckedAttributes);
	// End StandardSubsystems.Properties
	
EndProcedure

&AtClient
Procedure OnClose(Exit)

	EquipmentManagerClient.StartDisablingHardwareWhenClosingForm(Undefined, ThisForm);

EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)

	// StandardSubsystems.AccessManagement
	AccessManagement.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.AccessManagement
	
	// Handler of the "Date-change" mechanism
	PeriodClosingDates.ObjectOnReadAtServer(ThisForm, CurrentObject);
	
	PropertyManager.OnReadAtServer(ThisForm, CurrentObject);
	
	OnReadCreateAtServer();
	
	// Selection of articles and analytics.
	ItemsAndDimensionsSelectionParameters = Documents.InventorySurplusRecognition.ItemsAndDimensionsSelectionParameters();
	IncomeAndExpensesServer.OnReadAtServer(ThisObject, ItemsAndDimensionsSelectionParameters);
	
	DocumentCorrection.OnReadAtServer(ThisForm, Items.LineCorrection);
	
	FormEvents.OnReadAtServer(ThisObject, CurrentObject);
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	// End StandardSubsystems.AttachableCommands

	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	// Handler of the "Properties" subsystem
	PropertyManager.BeforeWriteAtServer(ThisForm, CurrentObject);

	ConfigurationModificationOverridable.BeforeWriteAtServer(ThisForm, Cancel, CurrentObject, WriteParameters);

	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.BeforeWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	// End IntegrationWith1CDocumentManagementSubsystem
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)

	// StandardSubsystems.AccessManagement
	AccessManagement.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	// End StandardSubsystems.AccessManagement
	
	FillInServiceDetailsForProductRange();
	PurchasesServer.FillInServiceAttributesOfCCDNumber(Object.Goods);
	ExcisableGoodsAccounting.UpdateElementsOfAccountingForExcisableItems(ThisObject, False);
	
	
	FormEvents.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	// Selection of articles and analytics.
	IncomeAndExpensesServer.AfterWriteAtServer(ThisObject);
	
	ProvisionInDocumentsServer.CheckToRunBackgroundInventoryAllocationJob();
	
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	Notify("Write_InventorySurplusRecognition", WriteParameters, Object.Ref);
	
	
	DocumentCorrectionClient.AfterWrite(Object);
	
	ConfigurationModificationClientOverridable.AfterWrite(ThisForm, WriteParameters);

	// StandardSubsystems.AttachableCommands
	If CommonClient.SubsystemExists("StandardSubsystems.AttachableCommands") Then
		ModuleAttachableCommandsClient = CommonClient.CommonModule("AttachableCommandsClient");
		ModuleAttachableCommandsClient.AfterWrite(ThisObject, Object, WriteParameters);
	EndIf;
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

&AtClient
Procedure ChoiceProcessing(ValueSelected, ChoiceSource)

	If ProductsClient.ThisIsIndicationOfSeries(ChoiceSource) Then
		
		ProductsClient.ProcessSeriesIndication(ThisForm, SeriesSpecificationParameters, ValueSelected);
		
	ElsIf PurchasesClient.ThisIsSelectionOfCCDNumber(ChoiceSource) Then
		
		ProcessSelectionOfCCDNumber(ValueSelected);
		
	ElsIf ChoiceSource.FormName = "Catalog.Assignments.Form.ChoiceForm" Then
		
		Items.Goods.CurrentData.Purpose = ValueSelected;
		
	EndIf;
	
	If Window <> Undefined Then
		Window.Activate();
	EndIf;
	
EndProcedure

&AtClient
Procedure BeforeWrite(Cancel, WriteParameters)
	
	FormEventsClient.BeforeWrite(ThisObject, Cancel, WriteParameters);

EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure GroupPagesOnCurrentPageChange(Item, CurrentPage)
	
	// StandardSubsystems.Properties
	If CurrentPage.Name = "AdvancedGroup"
		And Not ThisObject.PropertiesParameters.DeferredInitializationExecuted Then
		
		PropertiesExecuteDeferredInitialization();
		PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
	EndIf;
	// End StandardSubsystems.Properties
	If CurrentPage.Name = "InformationGroup" And ItIsRequiredToUpdateTitleIsSubjectToExciseDuty Then
		CalculateNumberOfExcisableItemsDeferred();
		ExcisableGoodsAccountingClient.AfterCalculatingNumberOfExcisableItems(ThisObject);
	EndIf;
EndProcedure

&AtClient
Procedure DateOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	
	DateOnChangeServer();
	
EndProcedure

&AtClient
Procedure OrganizationOnChange(Item)
	
	OrganizationOnChangeServer();
	
EndProcedure

&AtClient
Procedure PriceKindOnChange(Item)
	
	If ValueIsFilled(Object.PriceKind)
		And Object.Goods.Count() > 0 Then
		QueryText = NStr("vi = 'Điền giá theo dạng giá ""%PriceKind%""?';
						|ru = 'Заполнить цены по виду цен ""%PriceKind%""?';
						|en = 'Fill in prices by price type ""%PriceKind%""?'; fa = 'Fill in prices by price type ""%PriceKind%""?';
						|it = 'Compilare i prezzi per il tipo di prezzi ""%PriceKind%""?';
						|pl = 'Podaj ceny według rodzaju ceny ""%PriceKind%""?';
						|tr = 'Fiyatlar, ""%PriceKind%"" fiyat türüne göre doldurulsun mu?'");
		QueryText = StrReplace(QueryText,"%PriceKind%", Object.PriceKind);
		
		ShowQueryBox(New CallbackDescription("PriceKindOnChangeCompletion", ThisObject), QueryText,QuestionDialogMode.YesNo,,DialogReturnCode.Yes);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure PriceKindOnChangeCompletion(QuestionResult, AdditionalParameters) Export
	
	If QuestionResult = DialogReturnCode.Yes Then
		PricesCalculated = FillInPricesByPriceKindServer();
		SalesClient.NotifyAboutEndOfFillingInPricesByTypeOfPrices(PricesCalculated, Object.PriceKind);
	EndIf;
	
EndProcedure

&AtClient
Procedure CurrencyOnChange(Item)
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.StartTimeMeasurement(True,
		"Document.InventorySurplusRecognition.Form.DocumentForm.Item.Currency.OnChange");
	
	CurrencyOnChangeClient();
	
EndProcedure

&AtClient
Procedure WarehouseOnChange(Item)
	
	WarehouseOnChangeServer(True);
	CurrencyOnChangeClient();
	
EndProcedure

&AtClient
Procedure IncomeItemOnChange(Item)
	
	// Selection of articles and analytics.
	IncomeAndExpensesClientServer.AssetRefOnChange(ThisObject, Item);
	
EndProcedure

&AtClient
Procedure Decorationedonage(Item, StandardProcessing)
	
	
EndProcedure

&AtClient
Procedure IncomeItemStartChoice(Item, ChoiceData, StandardProcessing)
	
	// Selection of articles and analytics.
	IncomeAndExpensesClient.StartArticleSelection(ThisObject, Item, StandardProcessing);
	
EndProcedure

&AtClient
Procedure LineCorrectionURLProcessing(Item, FormattedStringURL, StandardProcessing)
	DocumentCorrectionClient.StringFixHandlingNavigationLinks(
		ThisObject, FormattedStringURL, StandardProcessing);
EndProcedure

&AtClient
Procedure SubjectToExciseOnChange(Item)
	ExcisableGoodsAccountingClientServer.ConfigureProductionDivisionField(ThisObject);
	Return; // Not used in TM
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersGoods

&AtClient
Procedure GoodsProductsOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("CheckCharacteristicsByOwner", CurrentRow.Characteristic);
	StructureOfActions.Insert("FillInSalePrice", New Structure("Date, Currency, PriceKind", Object.Date, Object.Currency, Object.PriceKind));
	StructureOfActions.Insert("RecalculateAmount", "Count");
	StructureOfActions.Insert("FillInCCDTrackingAttribute", New Structure("Products", "TheRecordsAreKeptByCCD"));
	StructureOfActions.Insert("FillInCountryOfOriginOfProduct",
								BatchProcessingOfTablePartClientServer.CountryOfOriginFillingParameters());
	StructureOfActions.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));
	StructureOfActions.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
	StructureOfActions.Insert("CheckSeriesCalculateStatus", New Structure("Warehouse, SeriesSpecificationParameters", Object.Warehouse, SeriesSpecificationParameters));
	StructureOfActions.Insert("CheckFillAssignment");
	StructureOfActions.Insert("FillInUnblockableDateOfQualityConfirmation", CacheQualityControl);
	
	StructureOfActions.Insert("ProductsOnChangeOverridable", New Structure("FormName, TabularSectionName",
		ThisForm.FormName, "Goods"));
	
	AccountingForTraceableGoodsClientServerLocalization.CompleteDescriptionOfSettingsForFillingInServiceDetailsOfTablePart(StructureOfActions);
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
	If Not CurrentRow.TheRecordsAreKeptByCCD Then
		CurrentRow.CCDNumber = Undefined;
		CurrentRow.CCDNumberType = Undefined;
		CurrentRow.OriginCountry = Undefined;
	EndIf;
	ItIsRequiredToUpdateTitleIsSubjectToExciseDuty = UseExcisableGoods;
EndProcedure

&AtClient
Procedure GoodsCharacteristicOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInSalePrice", New Structure("Date, Currency, PriceKind", Object.Date, Object.Currency, Object.PriceKind));
	StructureOfActions.Insert("RecalculateAmount", "Count");
	StructureOfActions.Insert("CheckFillAssignment");
	
	StructureOfActions.Insert("CharacteristicOnChangeOverridable", New Structure("FormName, TabularSectionName",
		ThisForm.FormName, "Goods"));

	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
EndProcedure

&AtClient
Procedure GoodsControlledLotReferenceOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;
	StructureOfActions = New Structure();
	StructureOfActions.Insert("FillInUnblockableDateOfQualityConfirmation", CacheQualityControl);
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
EndProcedure

&AtClient
Procedure GoodsCountOnChange(Item)
	CurrentRow = Items.Goods.CurrentData;

	StructureOfActions = New Structure;
	AddActionsToStructureWhenQuantityChanges(StructureOfActions, Object);

	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
EndProcedure

&AtClient
Procedure GoodsPriceOnChange(Item)

	CurrentRow = Items.Goods.CurrentData;

	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateAmount", "Count");

	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);

EndProcedure

&AtClient
Procedure GoodsCCDNumberOnChange(Item)
	
	CurrentData = Items.Goods.CurrentData;
	
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	FillParameters = New Structure("CCDNumber", CurrentData.CCDNumber);
	
	Actions = New Structure;
	Actions.Insert("FillInCCDNumberType", FillParameters);
	Actions.Insert("FillInCountryOfOriginForCCDNumber", FillParameters);
	
	AccountingForTraceableGoodsClientServerLocalization.AddDescriptionOfSettingsForRecalculatingDetailsOfTablePart(
		Object,
		Actions);
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentData, Actions, Undefined);
	
EndProcedure

&AtClient
Procedure GoodsCCDNumberCreating(Item, StandardProcessing)
	
	StandardProcessing = False;
	
	CurrentData = Items.Goods.CurrentData;
	
	AdditionalParameters = PurchasesClient.AdditionalParametersForCreatingCCDNumber();
	FillPropertyValues(AdditionalParameters, Object);
	FillPropertyValues(AdditionalParameters, ThisObject);
	
	AdditionalParameters.FieldNameQuantity = "Count";
	
	CreationParameters = PurchasesClient.ParametersForCreatingCCDNumber(CurrentData,
																Item.EditText,
																AdditionalParameters);
	CreationParameters.CreatingElementOfAnyType = True;
	
	PurchasesClient.OpenFormForCreatingGTDNumber(ThisObject, CreationParameters);
	
EndProcedure

&AtClient
Procedure GoodsSumOnChange(Item)
	CurrentRow = Items.Goods.CurrentData;

	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculatePriceByAmount", "Count");

	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);

EndProcedure

&AtClient
Procedure GoodsSeriesStartChoice(Item, ChoiceData, StandardProcessing)
	StandardProcessing = False;
	OpenSelectionOfSeries(Item.EditText);
EndProcedure

&AtClient
Procedure GoodsSeriesOnChange(Item)
	
	ValueSelected = ProductsClientServer.SelectedSeries();
	
	ValueSelected.Value            		 = Items.Goods.CurrentData.Series;
	ValueSelected.CurrentRowID = Items.Goods.CurrentData.GetID();
	
	ProductsClient.ProcessSeriesIndication(ThisForm, SeriesSpecificationParameters, ValueSelected);

EndProcedure

&AtClient
Procedure GoodsOnActivateRow(Item)
	If Item.CurrentItem = Undefined Then
		Return
	ElsIf Item.CurrentItem.Name = "GoodsCCDNumber" Then
		PurchasesClient.FillInListOfCCDNumberSelection(
			Items.Goods.CurrentData, 
			Items.GoodsCCDNumber.ChoiceList);
	EndIf;
EndProcedure

&AtClient
Procedure GoodsAfterDeleteRow(Item)
	ItIsRequiredToUpdateTitleIsSubjectToExciseDuty = UseExcisableGoods;
	Return; // Not used in TM
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

// StandardSubsystems.AttachableCommands
&AtServer
Procedure ExecuteCommandAtServer(ExecutionParameters)
	AttachableCommands.ExecuteCommand(ThisObject, ExecutionParameters, Object);
EndProcedure
// End StandardSubsystems.AttachableCommands


// StandardSubsystems.AttachableCommands
&AtClient
Procedure Attachable_ContinueCommandExecutionAtServer(ExecutionParameters, AdditionalParameters) Export
	ExecuteCommandAtServer(ExecutionParameters);
EndProcedure
// End StandardSubsystems.AttachableCommands


&AtClient
Procedure PostDocument(Command)
	
	TMCommonUseClient.Post(ThisForm);
	
EndProcedure

&AtClient
Procedure PostAndClose(Command)
	
	TMCommonUseClient.PostAndClose(ThisForm);
	
EndProcedure

&AtClient
Procedure SplitRow(Command)
	
	FormTable  = Items.Goods;
	TableData = Object.Goods;
	
	StringSplittingParameters = ProcessingOfTabularFormsClient.StringSplittingParameters();
	StringSplittingParameters.FieldNameQuantity = "Count";
	
	AdditionalParameters = AccountingForTraceableGoodsClientServerLocalization.CompleteDescriptionOfParametersForSplittingRowInTablePart(FormTable.CurrentData);
	
	Notification = New CallbackDescription("SplitRowCompletion", ThisObject, AdditionalParameters);
	ProcessingOfTabularFormsClient.SplitRow(TableData, FormTable, Notification, StringSplittingParameters);
	
EndProcedure

&AtClient
Procedure SplitRowCompletion(NewRow, AdditionalParameters) Export 
	
	CurrentRow = Items.Goods.CurrentData;
	
	If NewRow <> Undefined Then
		
		StructureOfActions = New Structure;
		AddActionsToStructureWhenQuantityChanges(StructureOfActions, Object);
		
		BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
		BatchProcessingOfTablePartClient.ProcessTSString(NewRow, StructureOfActions, CachedValues);
		
	EndIf;
	
	AccountingForTraceableGoodsClientServerLocalization.SplitRowCompletion(NewRow, AdditionalParameters);
	ItIsRequiredToUpdateTitleIsSubjectToExciseDuty = UseExcisableGoods;
EndProcedure

&AtClient
Procedure FillInPricesByPriceKind(Command)
	
	ClearMessages();
	
	If Object.Goods.Count() = 0 Then
		MessageText = NStr("vi = 'Trong chứng từ không điền bảng ""Hàng hóa"". Không thể điền đơn giá';
							|ru = 'В документе не заполнена таблица ""Товары"". Цены не могут быть заполнены';
							|en = 'The ""Goods"" table in the document is not filled in. Cannot fill in the prices'; fa = 'The ""Goods"" table in the document is not filled in. Cannot fill in the prices';
							|it = 'Nel documento non è compilata la tabella ""Merci"". I prezzi non possono essere compilati';
							|pl = 'W dokumencie nie jest wypełniona tabela ""Wiersze pozycji"". Ceny nie mogą być wypełnione.';
							|tr = 'Belgedeki ""Ürünler"" tablosu doldurulmadı. Fiyatlar doldurulamıyor'");
		CommonClientServer.MessageToUser(MessageText,,"Goods","Object");
		Return;
	EndIf;
	
	If ValueIsFilled(Object.PriceKind) Then
		PricesCalculated = FillInPricesByPriceKindServer();
		SalesClient.NotifyAboutEndOfFillingInPricesByTypeOfPrices(PricesCalculated, Object.PriceKind);
	Else
		MessageText = NStr("vi = 'Chưa chỉ ra dạng giá';
							|ru = 'Не указан вид цены';
							|en = 'Price type is not specified'; fa = 'Price type is not specified';
							|it = 'Il tipo di prezzo non è indicato';
							|pl = 'Nie podano rodzaju ceny';
							|tr = 'Fiyat türü belirtilmedi'");
		CommonClientServer.MessageToUser(MessageText,,"PriceKind","Object");
	EndIf;
	
EndProcedure

&AtClient
Procedure FillInPricesByCosts(Command)
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.StartTimeMeasurement(True,
		"Document.InventorySurplusRecognition.Form.DocumentForm.Command.FillInPricesByCosts");
	
	ClearMessages();
	
	If Object.Goods.Count() = 0 Then
		MessageText = NStr("vi = 'Trong chứng từ không điền bảng ""Hàng hóa"". Không thể điền đơn giá';
							|ru = 'В документе не заполнена таблица ""Товары"". Цены не могут быть заполнены';
							|en = 'The ""Goods"" table in the document is not filled in. Cannot fill in the prices'; fa = 'The ""Goods"" table in the document is not filled in. Cannot fill in the prices';
							|it = 'Nel documento non è compilata la tabella ""Merci"". I prezzi non possono essere compilati';
							|pl = 'W dokumencie nie jest wypełniona tabela ""Wiersze pozycji"". Ceny nie mogą być wypełnione.';
							|tr = 'Belgedeki ""Ürünler"" tablosu doldurulmadı. Fiyatlar doldurulamıyor'");
		CommonClientServer.MessageToUser(MessageText, , "Goods", "Object");		
		Return;
	EndIf;
	
	FillInPricesByCostsServer(False);

EndProcedure

&AtClient
Procedure FillInPricesAtCostWithoutVAT(Command)
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.StartTimeMeasurement(True,
		"Document.InventorySurplusRecognition.Form.DocumentForm.Command.FillInPricesByCosts");
	
	ClearMessages();
	
	If Object.Goods.Count() = 0 Then
		MessageText = NStr("vi = 'Trong chứng từ chưa điền bảng ""Hàng hóa"". Không thể điền đơn giá';
							|ru = 'В документе не заполнена таблица ""Товары"". Цены не могут быть заполнены';
							|en = 'The ""Goods"" table in the document is not filled in. Cannot fill in the prices'; fa = 'The ""Goods"" table in the document is not filled in. Cannot fill in the prices';
							|it = 'Nel documento non è compilata la tabella ""Merci"". I prezzi non possono essere compilati';
							|pl = 'W dokumencie nie jest wypełniona tabela ""Wiersze pozycji"". Ceny nie mogą być wypełnione.';
							|tr = 'Belgedeki ""Mallar"" tablosu doldurulmamıştır. Fiyatlar doldurulamıyor'");
		CommonClientServer.MessageToUser(MessageText, , "Goods", "Object");
		Return;
	EndIf;
	
	FillInPricesByCostsServer(True);

EndProcedure

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
Procedure GetWeight(Command)
	
	CurrentRow = EquipmentManagerTMClient.CurrentRow(ThisForm);
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
		CurrentRow.Count = ExecutionResult.Weight;
		
		StructureOfActions = New Structure;
		AddActionsToStructureWhenQuantityChanges(StructureOfActions, Object);
		
		BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	Else
		EquipmentManagerTMClient.ReportError(ExecutionResult);
	EndIf;
	
EndProcedure

&AtClient
Procedure FillInCCDNumbers(Command)
	
	NotificationParameters	= New Structure("CCDNumbersFilledIn", Undefined);
	CallbackDescription	= New CallbackDescription("FillInCCDNumbersCompletion", ThisObject, NotificationParameters);
	
	OpenForm("Catalog.CCDNumbers.ChoiceForm",
				,
				ThisObject,
				UUID,
				,
				,
				CallbackDescription,
				FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure FillInCCDNumbersCompletion(Result, AdditionalParameters) Export
	
	CCDNumber = Result;
	CCDNumbersFilledIn = AdditionalParameters.CCDNumbersFilledIn;
	
	If ValueIsFilled(CCDNumber) Then
		FillInCCDNumbersOnServer(CCDNumber, CCDNumbersFilledIn);
	EndIf;
	
	PurchasesClient.NotifyAboutFillingInGTNumbersInTabularPart(CCDNumbersFilledIn, CCDNumber);
	
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
Procedure WriteDocument(Command)
	
	TMCommonUseClient.Write(ThisForm);
	
EndProcedure

&AtClient
Procedure Fill(Command)

	If Object.Goods.Count() > 0 Then
		Response = Undefined;

		ShowQueryBox(New CallbackDescription("FillCompletion", ThisObject), NStr("vi = 'Phần bảng sẽ bị xóa và điền bởi tất cả hàng hóa cần tạo ghi tăng. Tiếp tục?';
																				|ru = 'Табличная часть будет очищена и заполнена всеми товарами, по которым нужно оформить оприходование. Продолжить?';
																				|en = 'The table will be refilled. Do you want to continue?'; fa = 'The table will be refilled. Do you want to continue?';
																				|it = 'La parte tabulare verrà cancellata e compilata con tutti i prodotti per i quali è necessario formalizzare la registrazione in contabilità. Continuare?';
																				|pl = 'Część tabelaryczna zostanie wyczyszczona i wypełniona wszystkimi towarami, dla których należy sporządzić rejestrowanie. Kontynuować?';
																				|tr = 'Tablo bölümü temizlenecek ve envanter girişi düzenlenmesi gereken tüm ürünlerle doldurulacaktır. Devam edilsin mi?'"), QuestionDialogMode.YesNo);
        Return;
	EndIf;

	FillInBasedOnServer();
EndProcedure

&AtClient
Procedure FillCompletion(QuestionResult, AdditionalParameters) Export
    
    Response = QuestionResult;
    If Response <> DialogReturnCode.Yes Then
        Return;
    EndIf;
    
    FillInBasedOnServer();

EndProcedure

&AtClient
Procedure Attachable_PropertiesExecuteCommand(ItemOrCommand, Var_URL = Undefined, StandardProcessing = Undefined)
	PropertyManagerClient.ExecuteCommand(ThisObject, ItemOrCommand, StandardProcessing);
EndProcedure

&AtClient
Procedure CheckQuantityInTheDocument(Command)
	
	OpeningParameters = New Structure;
	OpeningParameters.Insert("AddressInTempStorage",            PutTablePartOfGoodsInTemporaryStorageToCheckQuantity());
	OpeningParameters.Insert("TabularSectionName",                    "Goods");
	OpeningParameters.Insert("Ref",                               Object.Ref);
	OpeningParameters.Insert("GoodsQuantityExcessIsAllowed", True);
	OpeningParameters.Insert("NotUsePackages",               True);
	OpeningParameters.Insert("SeriesSpecificationParameters",               SeriesSpecificationParameters);
	OpeningParameters.Insert("Warehouse",                                Object.Warehouse);
	
	ReturnParameters = Undefined;

	
	OpenForm("CommonForm.CheckDocumentPopulation", OpeningParameters,,,,, New CallbackDescription("CheckQuantityInTheDocumentCompletion", ThisObject), FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure CheckQuantityInTheDocumentCompletion(Result, AdditionalParameters) Export
    
    ReturnParameters = Result;
    If ReturnParameters <> Undefined Then
        ChangeTablePartBasedOnResultsOfCheck(ReturnParameters, ?(CachedValues = Undefined, BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues(), CachedValues));
        
        Modified = True;
        
    EndIf;

EndProcedure

// IntegrationWith1CDocumentManagementSubsystem
&AtClient
Procedure Attachable_ExecuteIntegrationCommand(Command)
	
	IntegrationWith1CDocumentManagementCoreClient.ExecutePlugInIntegrationCommand(Command, ThisObject, Object);
	
EndProcedure
// End IntegrationWith1CDocumentManagementSubsystem

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

#EndRegion

#Region Private

// StandardSubsystems.Properties

&AtServer
Procedure PropertiesExecuteDeferredInitialization()
	PropertyManager.FillAdditionalAttributesInForm(ThisObject);
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


&AtServer
Procedure SetConditionalAppearance()
	
	ConditionalAppearance.Items.Clear();
	
	//
	ProductsServer.EstablishConditionalAppearanceOfProductCharacteristics(ThisForm);
	
	//
	ConditionalDesignParameters = ProductsServer.ParametersForSettingConditionalAppearanceOfCCDNumber();
	ConditionalDesignParameters.NameOfFieldForEnteringCCDNumber = "GoodsCCDNumberOriginCountry";
	
	ProductsServer.SetConditionalAppearanceOfCCDNumber(ThisObject);
	ProductsServer.SetConditionalAppearanceOfCCDNumber(ThisObject, ConditionalDesignParameters);
	
	//
	AccountingForTraceableGoodsLocalization.SetConditionalAppearanceOfCCDNumber(ThisObject);
	AccountingForTraceableGoodsLocalization.SetConditionalAppearanceOfQuantityAccordingToRNPT(ThisObject);
	AccountingForTraceableGoodsLocalization.ToEstablishConditionalAppearanceOfAccountingForGTDVStockSurplusRecognition(ThisObject);
	
	//
	ProductsServer.EstablishConditionalAppearanceOfProductSeries(ThisForm, "SeriesAlwaysWHGoods");
	
	//
	ProductsServer.SetConditionalAppearanceOfProductAssignment(ThisForm);
	
	// Quality control.
	
	QualityControl.ConditionalAppearanceOfDateOfConfirmationOfQualityOfSurplus(
		ConditionalAppearance,
		Items.GoodsQualityConfirmationDate);
	
EndProcedure

#Region OnChangeAttributes

&AtServer
Procedure DateOnChangeServer()
	
	UseTraceableImportedGoodsAccounting = AccountingForTraceableGoodsLocalization.UseTraceableImportedGoodsAccounting(
														Object.Date);
	
	AccountingForTraceableGoodsLocalization.EstablishVisibilityOfRNPTQuantity(ThisForm, Object.Date);
	
	If Not Items.ProductsGroupQuantityByRNPT.Visible Then
		RecalculateNumberOfRNPT();
	EndIf;
	ExcisableGoodsAccounting.UpdateElementsOfAccountingForExcisableItems(ThisObject);
	
	SetVisibilityOfQualityControlAttributes();
	If QualityControl.UpdateActionParameters(
			Documents.InventorySurplusRecognition,
			Object,
			CacheQualityControl) Then
			
		StructureOfActions = New Structure();
		StructureOfActions.Insert("FillInUnblockableDateOfQualityConfirmation", CacheQualityControl);
		BatchProcessingOfTablePartServer.TreatTS(Object.Goods, StructureOfActions);
		
	EndIf;
	
EndProcedure

&AtServer
Procedure WarehouseOnChangeServer(DirectModificationOfWarehouseField = False)
	
	Object.PriceKind = Catalogs.Warehouses.AccountingPriceType(Object.Warehouse);
	Object.Currency = IncomeAndExpensesServer.GetCurrencyOfManagementAccounting(
		Catalogs.TypesOfPrices.GetPriceTypeDetails(Object.PriceKind).PriceCurrency);
	SetFormFunctionalOptionParameters(New Structure("Warehouse", Object.Warehouse));
	OrderSchemeIsUsedWhenReflectingSurplusShortages = 
		WarehousesServer.UseWarehouseManagemantSystemForGoodsSurplusesShortages(Object.Warehouse, Object.Date);
	
	Items.Fill.Visible = OrderSchemeIsUsedWhenReflectingSurplusShortages;
	SeriesSpecificationParameters = New FixedStructure(ProductsServer.SeriesSpecificationParameters(
		Object,
		Documents.InventorySurplusRecognition));
	
	RecalculateNumberOfRNPT();
	
	ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);
	
	SetVisibilityOfQualityControlAttributes();
	If QualityControl.UpdateActionParameters(
			Documents.InventorySurplusRecognition,
			Object,
			CacheQualityControl,
			DirectModificationOfWarehouseField) Then
			
		StructureOfActions = New Structure();
		StructureOfActions.Insert("FillInUnblockableDateOfQualityConfirmation", CacheQualityControl);
		BatchProcessingOfTablePartServer.TreatTS(Object.Goods, StructureOfActions);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure CurrencyOnChangeClient()
	
	If PriceManagementSystemClient.CurrencyConversionRequired(Object, DocumentCurrency) Then
		CurrencyOnChangeServer();
		PriceManagementSystemClient.NotifyAboutEndOfConversionOfAmountsIntoCurrency(DocumentCurrency, Object.Currency);
	EndIf;
	
	DocumentCurrency = Object.Currency;
	
EndProcedure

&AtServer
Procedure CurrencyOnChangeServer()
	
	OldCurrency                = DocumentCurrency;
	NewCurrency                 = Object.Currency;
	DocumentDate               = ?(ValueIsFilled(Object.Date), Object.Date, CurrentSessionDate());
	StructureOfOldCurrencyRates = ProcessingOfExchangeRatesTM.GetCurrencyRate(OldCurrency, DocumentDate);
	StructureOfNewCurrencyRates  = ProcessingOfExchangeRatesTM.GetCurrencyRate(NewCurrency,  DocumentDate);
	
	// Recalculate the price
	PriceManagementSystem.ConvertAmountsToCurrencyProducts(
		Object,
		OldCurrency,
		NewCurrency,
		StructureOfOldCurrencyRates,
		StructureOfNewCurrencyRates,
		False);
	
	// Recalculate the amount
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateAmount", "Count");
	CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	BatchProcessingOfTablePartServer.TreatTS(Object.Goods, StructureOfActions, CachedValues);
	
EndProcedure

&AtServer
Procedure OrganizationOnChangeServer()
	
	RecalculateNumberOfRNPT();
	ExcisableGoodsAccounting.UpdateElementsOfAccountingForExcisableItems(ThisObject);
	
EndProcedure

#EndRegion

#Region PricingAndDiscounts

&AtServer
Function FillInPricesByPriceKindServer()
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateAmount", "Count");
	
	ColumnsByValue = New Structure("Package", Catalogs.PackagesAndUnitsOfMeasure.EmptyRef());
	
	FillParameters = New Structure;
	
	FillParameters.Insert("Date", Object.Date);
	FillParameters.Insert("Organization", Object.Organization);
	FillParameters.Insert("Currency", Object.Currency);
	FillParameters.Insert("PriceKind", Object.PriceKind);
	FillParameters.Insert("ColumnsByValue", ColumnsByValue);
	
	Return EnterprisePricesFillingServer.FillInPrices(
		Object.Goods, // Table part
		 , // Selected lines (fill in all lines)
		FillParameters,
		StructureOfActions);
	
EndFunction

&AtServer
Function FillInPricesByCostsServer(EXCLUDINGVAT)
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateAmount", "Count");
	
	RequestingPreliminaryData = New Query;
	RequestingPreliminaryData.Text =  
	"SELECT
	|	COUNT(InventoryCostCalculationCompanies.Ref) AS Count
	|FROM
	|	Document.InventoryCostCalculation.Companies AS InventoryCostCalculationCompanies
	|WHERE
	|	InventoryCostCalculationCompanies.Ref.Posted
	|	AND InventoryCostCalculationCompanies.Ref.EntryType = VALUE(Enum.LotRecordTypes.EmptyRef)
	|	AND InventoryCostCalculationCompanies.Organization = &Organization";
	
	RequestingPreliminaryData.SetParameter("Organization", Object.Organization);
	PreliminaryData = RequestingPreliminaryData.Execute().Select();
	
	While PreliminaryData.Next() Do
		If PreliminaryData.Count = 0 Then
			MessageText = NStr("vi = 'Chưa tính giá vốn hàng hóa theo doanh nghiệp ""%Organization%"".';
								|ru = 'Не было произведено ни одного расчета себестоимости товаров по организации ""%Organization%"".';
								|en = 'No inventory costs were calculated for company ""%Organization%"".'; fa = 'No inventory costs were calculated for company ""%Organization%"".';
								|it = 'Non è stato effettuato un solo calcolo del costo di produzione delle merci per società ""%Organization%"".';
								|pl = 'Nie było przeprowadzono ani jednego rozliczenia kosztów własnych towarów według firmy ""%Organization%"".';
								|tr = 'İş yeri ""%Organization%"" için ürün maliyeti hesaplaması yapılmadı.'");
			MessageText = StrReplace(MessageText, "%Organization%", Object.Organization);
			CommonClientServer.MessageToUser(MessageText);
			Return False;
		EndIf;
	EndDo;
	
	OtherColumnNames = New Structure("Products, Characteristic", "Products", "Characteristic");
	
	FillParameters = New Structure;
	FillParameters.Insert("Date", Object.Date);
	FillParameters.Insert("Organization", Object.Organization);
	FillParameters.Insert("Currency", Object.Currency);
	FillParameters.Insert("Warehouse", Object.Warehouse);
	FillParameters.Insert("OtherColumnNames", OtherColumnNames);
	FillParameters.Insert("EXCLUDINGVAT", EXCLUDINGVAT);
	
	Return SalesServer.FillInPricesByCosts(
		Object.Goods, // Table part
		Undefined, // Selected lines (fill in all lines)
		FillParameters,
		StructureOfActions);
	
EndFunction

#EndRegion

#Region SelectionAndProcessingOfQuantityVerification

&AtServer
Function PutTablePartOfGoodsInTemporaryStorageToCheckQuantity()
	
	TabularPartProducts = Object.Goods.Unload(,"Products, Characteristic, ItemVariantsAreUsed, Count, Series, BatchesIndicationStatus, ItemsType");
	TabularPartProducts.GroupBy("Products, Characteristic, ItemVariantsAreUsed, Series, BatchesIndicationStatus, ItemsType", "Count");
	TabularPartProducts.Columns.Add("NumberOfPackages");
	For Each TSRow In TabularPartProducts Do
		TSRow.NumberOfPackages = TSRow.Count;
	EndDo;
	AddressInTempStorage = PutToTempStorage(TabularPartProducts, UUID);
	Return AddressInTempStorage;
	
EndFunction

&AtServer
Procedure ChangeTablePartBasedOnResultsOfCheck(ReturnParameters, CachedValues)
	
	GoodsTable = GetFromTempStorage(ReturnParameters.Goods);
	
	RowsToProcess = New Array;
	ProcessedLinesAreNew = New Array;	
	LinesToDelete = New Array;
	For Each SourceRow In GoodsTable Do
		
		Filter = New Structure("Products, Characteristic, Series, BatchesIndicationStatus");
		FillPropertyValues(Filter, SourceRow);
		FoundRows = Object.Goods.FindRows(Filter);
		
		For Each TSRow In FoundRows Do
			
			If SourceRow.NumberOfPackages = 0 Then
				Break;
			EndIf;
			
			If TSRow.Count = 0
				And SourceRow.NumberOfPackages < 0 Then
				
				Continue;
				
			EndIf;
			
			If SourceRow.NumberOfPackages >= 0 Then
				
				TSRow.Count = TSRow.Count + SourceRow.NumberOfPackages;
				SourceRow.NumberOfPackages = 0;
				
			Else
				
				QuantityToWriteOff = -SourceRow.NumberOfPackages;
				QuantityPerLine   = TSRow.Count;
				
				If QuantityToWriteOff > QuantityPerLine Then
					SourceRow.NumberOfPackages = QuantityPerLine - QuantityToWriteOff;
					TSRow.Count       = 0;
				Else
					SourceRow.NumberOfPackages = 0;
					TSRow.Count               = QuantityPerLine - QuantityToWriteOff;
				EndIf;
				
			EndIf;
			
			If TSRow.Count > 0 Then
				
				RowsToProcess.Add(TSRow);
				
			EndIf;
			
		EndDo;
		
		If FoundRows.Count() = 0 Then
			
			TSRow = Object.Goods.Add();
			FillPropertyValues(TSRow, SourceRow);
			TSRow.Count = SourceRow.NumberOfPackages;
			
			ProcessedLinesAreNew.Add(TSRow);
			
		EndIf;
		
	EndDo;

	StructureOfActions = New Structure;
	AddActionsToStructureWhenQuantityChanges(StructureOfActions, Object);
	StructureOfActions.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));
	StructureOfActions.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));

	BatchProcessingOfTablePartServer.ProcessTSStrings(
		RowsToProcess,
		StructureOfActions,
		Object.Goods,
		CachedValues);

	StructureOfActions.Insert("FillInSalePrice", New Structure("Date, Currency, PriceKind", Object.Date, Object.Currency, Object.PriceKind));
	StructureOfActions.Insert("FillInFeatureAttribute", New Structure("Products", "ItemVariantsAreUsed"));
	StructureOfActions.Insert("FillInCCDTrackingAttribute", New Structure("Products", "TheRecordsAreKeptByCCD"));
	StructureOfActions.Insert("FillInUnblockableDateOfQualityConfirmation", CacheQualityControl);
	AccountingForTraceableGoodsClientServerLocalization.CompleteDescriptionOfSettingsForFillingInServiceDetailsOfTablePart(StructureOfActions);
	
	AddActionsToStructureWhenQuantityChanges(StructureOfActions, Object);

	BatchProcessingOfTablePartServer.ProcessTSStrings(
		ProcessedLinesAreNew,
		StructureOfActions,
		Object.Goods,
		CachedValues);

	FilterCriterion = New Structure("Count", 0);
	FoundRows = Object.Goods.FindRows(FilterCriterion);
	
	For Each TSRow In FoundRows Do
		LinesToDelete.Add(TSRow);
	EndDo;
	
	For Each TSRow In LinesToDelete Do
		Object.Goods.Delete(TSRow);
	EndDo;
	
	ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);
	PurchasesServer.FillInServiceAttributesOfCCDNumber(Object.Goods);
	ItIsRequiredToUpdateTitleIsSubjectToExciseDuty = UseExcisableGoods;
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
	StructureOfActionsWithAddedStrings.Insert("FillInSalePrice", New Structure("Date, Currency, PriceKind", Object.Date, Object.Currency, Object.PriceKind));
	StructureOfActionsWithAddedStrings.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));
	StructureOfActionsWithAddedStrings.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
	StructureOfActionsWithAddedStrings.Insert("FillInFeatureAttribute", New Structure("Products", "ItemVariantsAreUsed"));
	StructureOfActionsWithAddedStrings.Insert("FillInCCDTrackingAttribute", New Structure("Products", "TheRecordsAreKeptByCCD"));
	StructureOfActionsWithAddedStrings.Insert("CheckSeriesCalculateStatus", New Structure("Warehouse, SeriesSpecificationParameters", Object.Warehouse, SeriesSpecificationParameters));
	StructureOfActionsWithAddedStrings.Insert("FillInUnblockableDateOfQualityConfirmation", CacheQualityControl);
	AccountingForTraceableGoodsClientServerLocalization.CompleteDescriptionOfSettingsForFillingInServiceDetailsOfTablePart(StructureOfActionsWithAddedStrings);
	
	AddActionsToStructureWhenQuantityChanges(StructureOfActionsWithAddedStrings, Object);
	
	StructureOfActionsWithModifiedStrings = New Structure;
	AddActionsToStructureWhenQuantityChanges(StructureOfActionsWithModifiedStrings, Object);
	
	StructureOfActions = BarcodingOfItemsClient.BarcodeProcessingParameters();
	StructureOfActions.Barcodes                              = BarcodeData_5;
	StructureOfActions.StructureOfActionsWithAddedStrings = StructureOfActionsWithAddedStrings;
	StructureOfActions.StructureOfActionsWithModifiedStrings  = StructureOfActionsWithModifiedStrings;
	StructureOfActions.SeriesSpecificationParameters                 = SeriesSpecificationParameters;
	StructureOfActions.ColumnNameQuantity                   = "Count";
	StructureOfActions.NotUsePackages                 = True;
	StructureOfActions.GoodsOnly                           = True;
	
	ProcessBarcodesServer(StructureOfActions, CachedValues);
	
	BarcodingOfItemsClient.ProcessUnknownBarcodes(StructureOfActions, CachedValues, ThisObject);
	
	If BarcodingOfItemsClient.YouNeedToOpenFormForSpecifyingSeriesAfterProcessingBarcodes(StructureOfActions) Then
		CurDataId = StructureOfActions.ArrayOfRowsWithSeries_[0];
		
		AttachIdleHandler("OpenSeriesSelectionWhenScanningProductBarCode", 0.1, True);
	EndIf;
	
	If StructureOfActions.CurrentRow <> Undefined Then
		Items.Goods.CurrentRow = StructureOfActions.CurrentRow;
	EndIf;
	
EndProcedure

&AtServer
Procedure ProcessBarcodesServer(StructureOfActionParameters, CachedValues)
	
	BarcodingOfItemsServer.ProcessBarcodes(ThisObject, Object, StructureOfActionParameters, CachedValues);
	PurchasesServer.FillInServiceAttributesOfCCDNumber(Object.Goods);
	ItIsRequiredToUpdateTitleIsSubjectToExciseDuty = UseExcisableGoods;
EndProcedure

#EndRegion

#Region SetOfSeries

&AtClient
Procedure OpenSelectionOfSeries(Text = "", CurrentData = Undefined)
	If ProductsClient.YouNeedServerCallToSpecifySeries(ThisForm,SeriesSpecificationParameters,Text, CurrentData)Then
		ExceptionText = NStr("vi = 'Lỗi khi thử chỉ ra sê-ri - để chỉ ra sê-ri trong chứng từ này, không cần gọi ra Server.';
							|ru = 'Ошибка при попытке указать серии - в этом документе для указания серий не нужен серверный вызов.';
							|en = 'An error occurred when attempting to specify batch. No server call is required to specify batch in this document.'; fa = 'An error occurred when attempting to specify batch. No server call is required to specify batch in this document.';
							|it = 'Si è verificato un errore durante il tentativo di indicare le serie - in questo documento non è necessaria la chiamata al server per indicare le serie.';
							|pl = 'Błąd podczas próby określenia serii - w tym dokumencie nie jest wymagane wywołanie serwera, aby wskazać serię.';
							|tr = 'Bir parti belirtmeye çalışırken hata oluştu - bu belgede bir parti belirtmek için sunucu çağrısı gerekmez.'");
		Raise ExceptionText;
	EndIf;
EndProcedure

&AtClient
Procedure OpenSeriesSelectionWhenScanningProductBarCode()

	If CurDataId = Undefined Then
		Return;
	EndIf;
	
	CurrentData = Object.Goods.FindByID(CurDataId);
	OpenSelectionOfSeries(,CurrentData);

EndProcedure

#EndRegion

#Region CCDNumbers

&AtClient
Procedure ProcessSelectionOfCCDNumber(CalculationResult1)
	
	CurrentData = Items.Goods.CurrentData;
	
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	RowID = CurrentData.GetID();
	
	If RowID = Undefined Then
		Return;
	EndIf;
	
	CCDNumbersFilledIn = False;
	CCDNumber = Undefined;
	
	ProcessIndicationOfCCDNumberServer(RowID, CalculationResult1, CCDNumbersFilledIn, CCDNumber);
	
	PurchasesClient.NotifyAboutFillingInGTNumbersInTabularPart(CCDNumbersFilledIn, CCDNumber);
	
EndProcedure

&AtServer
Procedure ProcessIndicationOfCCDNumberServer(RowID,
											CalculationResult1,
											CCDNumbersFilledIn,
											CCDNumber)
	
	SelectionData_1	= GetFromTempStorage(CalculationResult1.AddressInTempStorage);
	CCDNumber		= ?(SelectionData_1.ResidualNumberOfCCD <> Undefined,
						CCDNumber,
						SelectionData_1.MainNumberOfCCD);
	
	CCDNumberSelectionParameters = PurchasesServer.CCDNumberSelectionParameters();
	CCDNumberSelectionParameters.FieldNameNumberOfPackages = "Count";
	
	ProcessingActions = New Structure;
	
	If SelectionData_1.ResidualNumberOfCCD <> Undefined Then
		AddActionsToStructureWhenQuantityChanges(ProcessingActions, Object);
	Else
		AccountingForTraceableGoodsClientServerLocalization.AddDescriptionOfSettingsForRecalculatingDetailsOfTablePart(
			Object,
			ProcessingActions);
	EndIf;
	
	PurchasesServer.ProcessIndicationOfCCDNumber(ThisObject,
												RowID,
												SelectionData_1,
												CCDNumbersFilledIn,
												CCDNumberSelectionParameters,
												ProcessingActions);
	
EndProcedure

&AtServer
Procedure FillInCCDNumbersOnServer(Val CCDNumber, CCDNumbersFilledIn)
	
	FillParameters = PurchasesServer.ParametersForFillingInGTDVNumberOfTabularPart();
	FillParameters.FieldNameNumberOfPackages = "Count";
	
	PurchasesServer.FillInGTNumbersInTabularPart(
		Object.Goods,
		CCDNumber,
		Items.Goods.SelectedRows,
		CCDNumbersFilledIn,
		FillParameters);
	
EndProcedure

#EndRegion

#Region Other

&AtServer
Procedure OnReadCreateAtServer()
	
	UseTraceableImportedGoodsAccounting = AccountingForTraceableGoodsLocalization.UseTraceableImportedGoodsAccounting(
														Object.Date);
	
	SeriesSpecificationParameters = New FixedStructure(ProductsServer.SeriesSpecificationParameters(Object,
																									Documents.InventorySurplusRecognition));
	
	SetFormFunctionalOptionParameters(New Structure("Warehouse", Object.Warehouse));
	ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);
	FillInServiceDetailsForProductRange();
	
	OrderSchemeIsUsedWhenReflectingSurplusShortages = 
		WarehousesServer.UseWarehouseManagemantSystemForGoodsSurplusesShortages(Object.Warehouse, Object.Date);
	UseExcisableGoods = GetFunctionalOption("UseExcisableGoods");
	ExcisableGoodsAccounting.UpdateElementsOfAccountingForExcisableItems(ThisObject, Object.Ref.IsEmpty());
	CalculateNumberOfExcisableItemsDeferred();
	DocumentCurrency = Object.Currency;
	
	Items.InventoryRecount.Visible = ValueIsFilled(Object.InventoryRecount);
	Items.Fill.Visible = OrderSchemeIsUsedWhenReflectingSurplusShortages;
	
	PurchasesServer.FillInServiceAttributesOfCCDNumber(Object.Goods);
	CacheQualityControl = QualityControl.DataCacheOfMechanism(Object);
	
	SetVisibilityOfQualityControlAttributes();
	
EndProcedure

&AtServer
Procedure SetVisibilityOfQualityControlAttributes()
	
	ElementsAreVisible = Not WarehousesServer.UseWarehouseManagemantSystemForGoodsSurplusesShortages(Object.Warehouse, Object.Date);
	Items.GoodsControlledLotReference.Visible = ElementsAreVisible;
	Items.GoodsQualityConfirmationDate.Visible = ElementsAreVisible;
	
EndProcedure

&AtClientAtServerNoContext
Procedure AddActionsToStructureWhenQuantityChanges(StructureOfActions, Object)
	StructureOfActions.Insert("RecalculateAmount","Count");
	AccountingForTraceableGoodsClientServerLocalization.AddDescriptionOfSettingsForRecalculatingDetailsOfTablePart(
		Object,
		StructureOfActions);
EndProcedure

&AtServer
Procedure FillInBasedOnServer()
	
	TimeObject = FormAttributeToValue("Object");
	
	DocumentBasis = ?(ValueIsFilled(TimeObject.Basis),
							TimeObject.Basis,
							TimeObject.InventoryRecount);
	
	TimeObject.Goods.Clear();
	TimeObject.FillInTablePart(DocumentBasis);
	
	ValueToFormAttribute(TimeObject, "Object");
	FillInServiceDetailsForProductRange();
	
	If Object.Goods.Count() > 0
		And ValueIsFilled(Object.PriceKind) Then
		
		FillInPricesByPriceKindServer();
		
	EndIf;
	
	ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);
	PurchasesServer.FillInServiceAttributesOfCCDNumber(Object.Goods);
	ItIsRequiredToUpdateTitleIsSubjectToExciseDuty = UseExcisableGoods;
EndProcedure

&AtServer
Procedure FillInServiceDetailsForProductRange()
	
	ParametersForFillingInBankingDetails = New Structure;
	ParametersForFillingInBankingDetails.Insert("FillInFeatureAttribute",
											New Structure("Products", "ItemVariantsAreUsed"));
	ParametersForFillingInBankingDetails.Insert("FillInArticleAttribute",
											New Structure("Products", "SKU"));
	ParametersForFillingInBankingDetails.Insert("FillInCCDTrackingAttribute",
											New Structure("Products", "TheRecordsAreKeptByCCD"));
	ParametersForFillingInBankingDetails.Insert("FillInProductTypeAttribute_",
											New Structure("Products", "ItemsType"));
	AccountingForTraceableGoodsClientServerLocalization.CompleteDescriptionOfSettingsForFillingInServiceDetailsOfTablePart(ParametersForFillingInBankingDetails);
	
	ProductsServer.FillInServiceDetailsForProductInCollection(Object.Goods,ParametersForFillingInBankingDetails);
	
EndProcedure

&AtServer
Procedure FillInAccordingToDataInRepository()
	
	If Not IsTempStorageURL(Parameters.AddressOfTheDataInTheStorage) Then
		Return;
	EndIf;
	
	StructureOfData = GetFromTempStorage(Parameters.AddressOfTheDataInTheStorage);
	
	If Not ValueIsFilled(Object.Ref) Then
		
		Object.Date = StructureOfData.Header.Date;
		
		TimeObject = FormAttributeToValue("Object");
		TimeObject.Fill(Undefined);
		ValueToFormAttribute(TimeObject, "Object");
		
		FillPropertyValues(Object,StructureOfData.Header);
	EndIf;	
	
	For Each RowOfTables In StructureOfData.GoodsTable Do
		NewRow = Object.Goods.Add();
		FillPropertyValues(NewRow,RowOfTables);
	EndDo;
	
	If ValueIsFilled(Object.Ref) Then
		FillInServiceDetailsForProductRange();
		ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);
		PurchasesServer.FillInServiceAttributesOfCCDNumber(Object.Goods);
		ItIsRequiredToUpdateTitleIsSubjectToExciseDuty = UseExcisableGoods;
	EndIf;
	
EndProcedure

&AtServer
Procedure UpdateAdditionalAttributesItems()
	PropertyManager.UpdateAdditionalAttributesItems(ThisForm);
EndProcedure

&AtServer
Procedure RecalculateNumberOfRNPT()
	
	If ValueIsFilled(Object.Warehouse)
		And ValueIsFilled(Object.Organization) Then
		
		ParametersForObtainingRnptCoefficient = AccountingForTraceableGoodsClientServerLocalization.ParametersForObtainingRnptCoefficient(
												Object);
		AccountingForTraceableGoodsLocalization.FillInQuantityByRNPTVOfTablePart(ParametersForObtainingRnptCoefficient,
																						Object.Goods);
		
	EndIf;
	
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
&AtServer
Procedure CalculateNumberOfExcisableItemsDeferred()
	
	DataForCalculatingNumberOfExcisableGoods =
		ExcisableGoodsAccounting.StartCalculatingNumberOfExcisableItems(Object);
	
EndProcedure

&AtClient
Procedure Attachable_UpdateFieldHeaderIsSubjectToExciseDuty()
	
	ExcisableGoodsAccountingClient.AfterCalculatingNumberOfExcisableItems(ThisObject);
	
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
