#Region Variables

&AtClient
Var CachedValues; //used by the mechanism for processing changes in PM details

&AtClient
Var EditingRegistrationSeries; //used to determine that the series selection form is called for the series specified in the header

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
	PropertyManager.OnCreateAtServer(ThisObject, AdditionalParameters);
	
	// Handler of the "Destination" mechanism
	Catalogs.Assignments.DocumentFormWhenCreatedOnServer(ThisObject);
	
	FillInAccordingToDataInRepository();
	
	Items.ProductsNomenclatureWriteOff.ReadOnly        = Parameters.ProhibitChangingProducts;
	Items.ProductsFeatureWriteOff.ReadOnly      = Parameters.ProhibitChangingProducts;
	Items.GoodsProductsRecordingAsReceived.ReadOnly   = Parameters.ProhibitChangingProducts;
	Items.GoodsCharacteristicRecordingAsReceived.ReadOnly = Parameters.ProhibitChangingProducts;
	Items.GoodsCount.ReadOnly                  = Parameters.ProhibitChangingProducts;
	Items.Warehouse.ReadOnly                             = Parameters.ProhibitChangingProducts;
	Items.Organization.ReadOnly                       = Parameters.ProhibitChangingProducts;
	Items.Goods.ChangeRowSet                       = Not Parameters.ProhibitChangingProducts;
	
	RestrictGoodsReceiptWithoutCCDNumbers = GetFunctionalOption("RestrictGoodsReceiptWithoutCCDNumbers");
	
	If Not ValueIsFilled(Object.Ref) Then	
		OnReadCreateAtServer();
	EndIf;
	If IsTempStorageURL(Parameters.AddressOfTheDataInTheStorage)
		Or Not ValueIsFilled(Object.Ref) Then
		ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);
	EndIf;
	
	If Object.ReceiveGoodsAtCostTheyWereIssuedFromWarehouse Then
		Object.PriceKind = Undefined;
		ClearPrices();
	EndIf;
	
	AccountingForTraceableGoodsLocalization.EstablishVisibilityOfRNPTQuantity(ThisObject, Object.Date);
	
	SetSettingsForFormattingArticleFields();
	
	// Selection of articles and analytics.
	ItemsAndDimensionsSelectionParameters = Documents.GoodsMisgrading.ItemsAndDimensionsSelectionParameters(
										Object.ReceiveGoodsAtCostTheyWereIssuedFromWarehouse);
	IncomeAndExpensesServer.OnCreateAtServer(ThisObject, ItemsAndDimensionsSelectionParameters);
	
	DocumentCorrection.OnCreateAtServer(ThisObject, Items.LineCorrection);
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject);
	// End IntegrationWith1CDocumentManagementSubsystem
	
	
	Items.DecorationEDOState.Visible = GetFunctionalOption("UseElectronicDocumentExchangeWithCounterparties");
	
	FormEvents.OnCreateAtServer(ThisObject, Cancel, StandardProcessing);
	
	AccountingForTraceableGoodsLocalization.SetTitleNumberOfCCD(Items, "GoodsCCDNumber");
	
	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	// StandardSubsystems.Properties
	PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
	// End StandardSubsystems.Properties
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands


EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)
	
	DocumentCorrection.OnReadAtServer(ThisObject, Items.LineCorrection);
	
	// StandardSubsystems.AccessManagement
	AccessManagement.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.AccessManagement
	
	// Handler of the "Date-change" mechanism
	PeriodClosingDates.ObjectOnReadAtServer(ThisObject, CurrentObject);
	
	OnReadCreateAtServer();
	
	// Selection of articles and analytics.
	ItemsAndDimensionsSelectionParameters = Documents.GoodsMisgrading.ItemsAndDimensionsSelectionParameters(
										Object.ReceiveGoodsAtCostTheyWereIssuedFromWarehouse);
	IncomeAndExpensesServer.OnReadAtServer(ThisObject, ItemsAndDimensionsSelectionParameters);
	
	PropertyManager.OnReadAtServer(ThisObject, CurrentObject);
	
	FormEvents.OnReadAtServer(ThisObject, CurrentObject);
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	// End StandardSubsystems.AttachableCommands

	
EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	
	// StandardSubsystems.Properties
	PropertyManager.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes);
	// End StandardSubsystems.Properties
	
EndProcedure

&AtClient
Procedure ChoiceProcessing(ValueSelected, ChoiceSource)

	If ChoiceSource.FormName = "Catalog.InventoryKinds.Form.InventoryOwnerAttributesForm" Then	
		
		GetStockTypesFromStorage(ValueSelected);
		
	ElsIf ProductsClient.ThisIsIndicationOfSeries(ChoiceSource) Then
		
		If EditingRegistrationSeries Then
			CurrentData = Items.Goods.RowData(ValueSelected.CurrentRowID);
			
			CurrentRow = New Structure;
			CurrentRow.Insert("Series", CurrentData.BatchReceipt);
			CurrentRow.Insert("BatchesIndicationStatus", CurrentData.BatchesIndicationStatusReceipt);
			
			ProductsClient.ProcessSeriesIndication(ThisObject, SeriesSpecificationParameters, ValueSelected, CurrentRow);
			
			CurrentData.BatchReceipt               = CurrentRow.Series;
			CurrentData.BatchesIndicationStatusReceipt = CurrentRow.BatchesIndicationStatus;
			
		Else
			ProductsClient.ProcessSeriesIndication(ThisObject, SeriesSpecificationParameters, ValueSelected);
		EndIf;
		
	ElsIf PurchasesClient.ThisIsSelectionOfCCDNumber(ChoiceSource) Then
		
		ProcessSelectionOfCCDNumber(ValueSelected);
		
	ElsIf ChoiceSource.FormName = "Catalog.Assignments.Form.ChoiceForm" Then
		
		CurrentData = Items.Goods.CurrentData;
		
		If Items.Goods.CurrentItem.Name = "GoodsPurpose" Then
			
			CurrentData.Purpose = ValueSelected;
			StructureOfActions = New Structure;
			StructureOfActions.Insert("FillInDestinationType", FillingParametersByDestinationType());
			
			BatchProcessingOfTablePartClient.ProcessTSString(CurrentData, StructureOfActions, Undefined);
		ElsIf Items.Goods.CurrentItem.Name = "GoodsAssignmentGoodsReceipt" Then
			CurrentData.AssignmentGoodsReceipt = ValueSelected;
		EndIf;
		
	EndIf;
	
	If Window <> Undefined Then
		Window.Activate();
	EndIf;
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	// Subsystem "Properties"
	If PropertyManagerClient.ProcessNotifications(ThisObject, EventName, Parameter) Then
		UpdateAdditionalAttributesItems();
		PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
	EndIf;
	
	DocumentCorrectionClient.NotificationProcessing(ThisObject, EventName, Parameter, Source);
	
	
	FormEventsClient.NotificationProcessing(ThisObject, EventName, Parameter, Source);
	
EndProcedure

&AtClient
Procedure NewWriteProcessing(NewObject, Source, StandardProcessing)
	
	If PurchasesClient.ThisIsIndicationOfCCDNumber(Source) Then
		
		CurrentData = Items.Goods.CurrentData;
		
		If CurrentData <> Undefined Then
			
			CurrentRow = DescriptionOfTablePartRow(CurrentData);
			CurrentRow.Products = CurrentData.ProductsRecordingAsReceived;
			CurrentRow.Characteristic = CurrentData.CharacteristicRecordingAsReceived;
			
			Actions = New Structure;
			
			AccountingForTraceableGoodsClientServerLocalization.AddDescriptionOfSettingsForRecalculatingDetailsOfTablePart(
				Object,
				Actions);
			
			PurchasesClient.ProcessIndicationOfCCDNumber(ThisObject, NewObject, , CurrentRow, Actions);
			
			CurrentData.QuantityByGBRN		= CurrentRow.QuantityByGBRN;
			CurrentData.CCDNumberType			= CurrentRow.CCDNumberType;
			CurrentData.OriginCountry	= CurrentRow.OriginCountry;
			
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure URLProcessing(FormattedStringURL, StandardProcessing)
	
	FormEventsClient.URLProcessing(ThisObject, FormattedStringURL, StandardProcessing);
	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	// Handler of the "Properties" subsystem
	PropertyManager.BeforeWriteAtServer(ThisObject, CurrentObject);
	
	ConfigurationModificationOverridable.BeforeWriteAtServer(ThisObject, Cancel, CurrentObject, WriteParameters);

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
	AssignmentsServer.FillInDestinationTypeInTable(Object.Goods);
	// Selection of articles and analytics.
	IncomeAndExpensesServer.AfterWriteAtServer(ThisObject);
	
	FormEvents.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	
	ProvisionInDocumentsServer.CheckToRunBackgroundInventoryAllocationJob();
	
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	
	WriteParameters.Insert("NotificationDocumentKeys", OperationsWithDocumentJournalsClient.GetKeyParametersForDocument(
		Object.Ref, Object.Date, Object.BusinessOperation));
	Notify("Write_GoodsMisgrading", WriteParameters, Object.Ref);
	
	
	DocumentCorrectionClient.AfterWrite(Object);
	
	ConfigurationModificationClientOverridable.AfterWrite(ThisObject, WriteParameters);

	// StandardSubsystems.AttachableCommands
	If CommonClient.SubsystemExists("StandardSubsystems.AttachableCommands") Then
		ModuleAttachableCommandsClient = CommonClient.CommonModule("AttachableCommandsClient");
		ModuleAttachableCommandsClient.AfterWrite(ThisObject, Object, WriteParameters);
	EndIf;
	// End StandardSubsystems.AttachableCommands
	
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
	
EndProcedure

&AtClient
Procedure OrganizationOnChange(Item)
	
	OrganizationOnChangeServer();
	
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
Procedure IncomeItemStartChoice(Item, ChoiceData, StandardProcessing)
	
	// Selection of articles and analytics.
	IncomeAndExpensesClient.StartArticleSelection(ThisObject, Item, StandardProcessing);
	
EndProcedure

&AtClient
Procedure ExpenseItemOnChange(Item)
	
	// Selection of articles and analytics.
	IncomeAndExpensesClientServer.AssetRefOnChange(ThisObject, Item);
	
EndProcedure

&AtClient
Procedure ExpenseItemStartChoice(Item, ChoiceData, StandardProcessing)
	
	// Selection of articles and analytics.
	IncomeAndExpensesClient.StartArticleSelection(ThisObject, Item, StandardProcessing);
	
EndProcedure

&AtClient
Procedure ReceiveGoodsAtCostTheyWereIssuedFromWarehouseOnChange(Item)
	
	If Object.ReceiveGoodsAtCostTheyWereIssuedFromWarehouse Then
		Object.PriceKind = Undefined;
		
		ClearPrices();
	EndIf;
	
	SetAvailability(ThisObject);
	ReceiveGoodsAtCostTheyWereIssuedFromWarehouseOnChangeServer();
	
EndProcedure

&AtClient
Procedure PriceKindOnChange(Item)
	If Not Object.ReceiveGoodsAtCostTheyWereIssuedFromWarehouse
		And ValueIsFilled(Object.PriceKind)
		And Object.Goods.Count() > 0 Then
		
		QueryText = NStr("vi = 'Điền giá theo dạng giá ""%PriceKind%""?';
						|ru = 'Заполнить цены по виду цен ""%PriceKind%""?';
						|en = 'Fill in prices by price type ""%PriceKind%""?'; fa = 'Fill in prices by price type ""%PriceKind%""?';
						|it = 'Compilare i prezzi per il tipo di prezzi ""%PriceKind%""?';
						|pl = 'Podaj ceny według rodzaju ceny ""%PriceKind%""?';
						|tr = 'Fiyatlar, ""%PriceKind%"" fiyat türüne göre doldurulsun mu?'");
		QueryText = StrReplace(QueryText,"%PriceKind%", Object.PriceKind);
		
		ShowQueryBox(New CallbackDescription("PriceKindOnChangeCompletion", ThisObject), QueryText,
			QuestionDialogMode.YesNo,,DialogReturnCode.Yes);
		
	EndIf;
EndProcedure

&AtClient
Procedure CurrencyOnChange(Item)
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.StartTimeMeasurement(True,
		"Document.GoodsMisgrading.Form.DocumentForm.Item.Currency.OnChange");
	
	CurrencyOnChangeClient();
	
EndProcedure

&AtClient
Procedure DimensionOfExpensesStartChoice(Item, ChoiceData, StandardProcessing)
	
	// Selection of articles and analytics.
	IncomeAndExpensesClient.StartSelectingExpenseAnalytics(ThisObject, Item, StandardProcessing);
	
EndProcedure

&AtClient
Procedure DimensionOfExpensesAutoComplete(Item, Text, ChoiceData, Var_Parameters, Waiting, StandardProcessing)
	
	// Selection of articles and analytics.
	IncomeAndExpensesClient.AutoSelectionOfExpenseAnalytics(ThisObject, Item, Text, ChoiceData, Var_Parameters,
		StandardProcessing);
	
EndProcedure

&AtClient
Procedure DimensionOfExpensesTextEditEnd(Item, Text, ChoiceData, Var_Parameters, StandardProcessing)
	
	// Selection of articles and analytics.
	IncomeAndExpensesClient.EndOfCostAnalyticsTextEntry(ThisObject, Item, Text, ChoiceData, Var_Parameters,
		StandardProcessing);
	
EndProcedure

&AtClient
Procedure DateOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	
	DateOnChangeServer();
	
EndProcedure

&AtClient
Procedure VATActivityTypeClearing(Item, StandardProcessing)
	StandardProcessing = False;
EndProcedure

&AtClient
Procedure Decorationedonage(Item, StandardProcessing)
	
	
EndProcedure

&AtClient
Procedure LineCorrectionURLProcessing(Item, FormattedStringURL, StandardProcessing)
	DocumentCorrectionClient.StringFixHandlingNavigationLinks(
		ThisObject, FormattedStringURL, StandardProcessing);
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersGoods

&AtClient
Procedure GoodsOnActivateRow(Item)
	
	If Item.CurrentItem = Undefined Then
		Return;
	ElsIf Item.CurrentItem.Name = "GoodsCCDNumber" Then
		PurchasesClient.FillInListOfCCDNumberSelection(
			Items.Goods.CurrentData,
			Items.GoodsCCDNumber.ChoiceList);
	EndIf;
	
EndProcedure

&AtClient
Procedure GoodsProductsOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("CheckCharacteristicsByOwner", CurrentRow.Characteristic);
	StructureOfActions.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
	StructureOfActions.Insert("FillInCCDTrackingAttribute", New Structure("Products", "RecordsAreKeptForCCDWriteOff"));
	StructureOfActions.Insert("FillInUnitOfMeasurementOfFEA", New Structure("Products", "UnitOfMeasurementOfFuelTaxWriteOff"));
	StructureOfActions.Insert("FillInArticleAttribute", New Structure("Products, ProductsRecordingAsReceived", "SKU", "SKURegistration"));
	StructureOfActions.Insert("CheckSeriesCalculateStatus", New Structure("Warehouse, SeriesSpecificationParameters", Object.Warehouse, SeriesSpecificationParameters));
	StructureOfActions.Insert("CheckFillAssignment");
	StructureOfActions.Insert("FillInUnblockableDateOfQualityConfirmation", CacheQualityControl);
	StructureOfActions.Insert("FillInDestinationType", FillingParametersByDestinationType());
	ActionParameters = New Structure("Products", "AccountingIsConductedAccordingToTheRNPTSPISITION");
	AccountingForTraceableGoodsClientServerLocalization.CompleteDescriptionOfSettingsForFillingInServiceDetailsOfTablePart(
		StructureOfActions,
		ActionParameters);
	
	StructureOfActions.Insert("ProductsOnChangeOverridable",
								New Structure("FormName, TabularSectionName", FormName, "Goods"));
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
EndProcedure

&AtClient
Procedure ProductsSeriesWriteOffOnChange(Item)
	ValueSelected = ProductsClientServer.SelectedSeries();
	
	ValueSelected.Value						= Items.Goods.CurrentData.Series;
	ValueSelected.CurrentRowID	= Items.Goods.CurrentData.GetID();
	
	ProductsClient.ProcessSeriesIndication(ThisObject, SeriesSpecificationParameters, ValueSelected);
EndProcedure

&AtClient
Procedure ProductsSeriesWriteOffStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	OpenSelectionOfSeries(False, Item.EditText);
	
EndProcedure

&AtClient
Procedure ProductsFeatureWriteOffOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;
	
	CharacteristicOnChangeOverridable = New Structure;
	CharacteristicOnChangeOverridable.Insert("FormName",          FormName);
	CharacteristicOnChangeOverridable.Insert("TabularSectionName", "Goods");
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("CharacteristicOnChangeOverridable", CharacteristicOnChangeOverridable);
	StructureOfActions.Insert("FillInDestinationType",                     FillingParametersByDestinationType());
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
Procedure GoodsProductsRecordingAsReceivedOnChange(Item)
	
	CurrentData = Items.Goods.CurrentData;
	
	CurrentRow = DescriptionOfTablePartRow(CurrentData);
	CurrentRow.Insert("Products", CurrentData.ProductsRecordingAsReceived);
	CurrentRow.Insert("Characteristic", CurrentData.CharacteristicRecordingAsReceived);
	CurrentRow.Insert("ItemVariantsAreUsed", CurrentData.ItemVariantsAreUsedRecordingAsReceived);
	CurrentRow.Insert("PriceKind", Object.PriceKind);
	CurrentRow.Insert("Package", PredefinedValue("Catalog.PackagesAndUnitsOfMeasure.EmptyRef"));
	CurrentRow.Insert("Series", CurrentData.BatchReceipt);
	CurrentRow.Insert("BatchesIndicationStatus", CurrentData.BatchesIndicationStatusReceipt);
	CurrentRow.Insert("ItemsType", CurrentData.ItemTypePosting);
	CurrentRow.Insert("FEACNUnitOfMeasure", CurrentData.FEACNUnitOfMeasure);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("CheckCharacteristicsByOwner", CurrentData.CharacteristicRecordingAsReceived);
	StructureOfActions.Insert("FillInProductTypeAttribute_", New Structure("ProductsRecordingAsReceived", "ItemTypePosting"));
	StructureOfActions.Insert("FillInCCDTrackingAttribute", New Structure("Products", "TheRecordsAreKeptByCCD"));
	StructureOfActions.Insert("FillInUnitOfMeasurementOfFEA", New Structure("Products", "FEACNUnitOfMeasure"));
	StructureOfActions.Insert("FillInCountryOfOriginOfProduct",
								BatchProcessingOfTablePartClientServer.CountryOfOriginFillingParameters());
	StructureOfActions.Insert("FillInArticleAttribute", New Structure("Products, ProductsRecordingAsReceived", "SKU", "SKURegistration"));
	StructureOfActions.Insert("CheckSeriesCalculateStatus", New Structure("Warehouse, SeriesSpecificationParameters", Object.Warehouse, SeriesSpecificationParameters));
	AccountingForTraceableGoodsClientServerLocalization.CompleteDescriptionOfSettingsForFillingInServiceDetailsOfTablePart(StructureOfActions);
	AccountingForTraceableGoodsClientServerLocalization.AddDescriptionOfSettingsForRecalculatingDetailsOfTablePart(
		Object,
		StructureOfActions);
	
	If Not Object.ReceiveGoodsAtCostTheyWereIssuedFromWarehouse Then
		StructureOfActions.Insert("FillInSalePrice", New Structure("Date, Currency", Object.Date, Object.Currency));
	EndIf;
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
	CurrentData.SKURegistration						= CurrentRow.SKURegistration;
	CurrentData.CharacteristicRecordingAsReceived				= CurrentRow.Characteristic;
	CurrentData.ItemVariantsAreUsedRecordingAsReceived	= CurrentRow.ItemVariantsAreUsed;
	CurrentData.Price										= CurrentRow.Price;
	CurrentData.TheRecordsAreKeptByCCD							= CurrentRow.TheRecordsAreKeptByCCD;
	CurrentData.BatchReceipt						= CurrentRow.Series;
	CurrentData.BatchesIndicationStatusReceipt			= CurrentRow.BatchesIndicationStatus;
	CurrentData.ItemTypePosting				= CurrentRow.ItemTypePosting;
	CurrentData.AccountingForTheRNPTIsMaintained							= CurrentRow.AccountingForTheRNPTIsMaintained;
	CurrentData.OriginCountry						= CurrentRow.OriginCountry;
	CurrentData.QuantityByGBRN							= CurrentRow.QuantityByGBRN;
	CurrentData.FEACNUnitOfMeasure						= CurrentRow.FEACNUnitOfMeasure;
	
	If Not CurrentData.TheRecordsAreKeptByCCD Then
		CurrentData.CCDNumber = Undefined;
		CurrentData.CCDNumberType = Undefined;
		CurrentData.OriginCountry = Undefined;
	EndIf;
	
	StructureOfActions = New Structure();
	StructureOfActions.Insert("FillInUnblockableDateOfQualityConfirmation", CacheQualityControl);
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentData, StructureOfActions, CachedValues);
	
EndProcedure

&AtClient
Procedure GoodsCharacteristicRecordingAsReceivedOnChange(Item)
	
	If Object.ReceiveGoodsAtCostTheyWereIssuedFromWarehouse
		Or Not ValueIsFilled(Object.PriceKind) Then
		
		Return;
		
	EndIf;
	
	CurrentData = Items.Goods.CurrentData;
	
	CurrentRow = DescriptionOfTablePartRow(CurrentData);
	CurrentRow.Insert("Products", CurrentData.ProductsRecordingAsReceived);
	CurrentRow.Insert("Characteristic", CurrentData.CharacteristicRecordingAsReceived);
	CurrentRow.Insert("ItemVariantsAreUsed", CurrentData.ItemVariantsAreUsedRecordingAsReceived);
	CurrentRow.Insert("PriceKind", Object.PriceKind);
	CurrentRow.Insert("Package", PredefinedValue("Catalog.PackagesAndUnitsOfMeasure.EmptyRef"));

	StructureOfActions = New Structure;
	If Not Object.ReceiveGoodsAtCostTheyWereIssuedFromWarehouse Then
		StructureOfActions.Insert("FillInSalePrice", New Structure("Date, Currency", Object.Date, Object.Currency));
	EndIf;
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
	CurrentData.Price = CurrentRow.Price;
	
EndProcedure

&AtClient
Procedure GoodsPurposeOnChange(Item)
	CurrentRow = Items.Goods.CurrentData;
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInDestinationType", FillingParametersByDestinationType());
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, Undefined);
	Return; // in UT and KA the handler is empty
	
EndProcedure

&AtClient
Procedure GoodsBatchReceiptOnChange(Item)
	
	ValueSelected = ProductsClientServer.SelectedSeries();
	CurrentData = Items.Goods.CurrentData;
	
	ValueSelected.Value						= CurrentData.BatchReceipt;
	ValueSelected.CurrentRowID	= CurrentData.GetID();
	
	CurrentRow = New Structure;
	CurrentRow.Insert("Series", CurrentData.BatchReceipt);
	CurrentRow.Insert("BatchesIndicationStatus", CurrentData.BatchesIndicationStatusReceipt);
	CurrentRow.Insert("Count", CurrentData.Count);
	
	ProductsClient.ProcessSeriesIndication(ThisObject, SeriesSpecificationParameters, ValueSelected, CurrentRow);
	
	CurrentData.BatchReceipt               = CurrentRow.Series;
	CurrentData.BatchesIndicationStatusReceipt = CurrentRow.BatchesIndicationStatus;
	
EndProcedure

&AtClient
Procedure GoodsBatchReceiptStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	OpenSelectionOfSeries(True, Item.EditText);
	
EndProcedure

&AtClient
Procedure GoodsCCDNumberOnChange(Item)
	
	CurrentData = Items.Goods.CurrentData;
	
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	CurrentRow = DescriptionOfTablePartRow(CurrentData);
	CurrentRow.Products = CurrentData.ProductsRecordingAsReceived;
	CurrentRow.Characteristic = CurrentData.CharacteristicRecordingAsReceived;
	
	FillParameters = New Structure("CCDNumber", CurrentData.CCDNumber);
	
	Actions = New Structure;
	Actions.Insert("FillInCCDNumberType", FillParameters);
	Actions.Insert("FillInCountryOfOriginForCCDNumber", FillParameters);
	
	AccountingForTraceableGoodsClientServerLocalization.AddDescriptionOfSettingsForRecalculatingDetailsOfTablePart(
		Object,
		Actions);
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, Actions, Undefined);
	
	CurrentData.QuantityByGBRN		= CurrentRow.QuantityByGBRN;
	CurrentData.CCDNumberType			= CurrentRow.CCDNumberType;
	CurrentData.OriginCountry	= CurrentRow.OriginCountry;
	
EndProcedure

&AtClient
Procedure GoodsCCDNumberCreating(Item, StandardProcessing)
	
	StandardProcessing = False;
	
	CurrentData = Items.Goods.CurrentData;
	
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	CurrentRow = DescriptionOfTablePartRow(CurrentData);
	CurrentRow.Products = CurrentData.ProductsRecordingAsReceived;
	CurrentRow.Characteristic = CurrentData.CharacteristicRecordingAsReceived;
	
	AdditionalParameters = PurchasesClient.AdditionalParametersForCreatingCCDNumber();
	FillPropertyValues(AdditionalParameters, ThisObject);
	
	AdditionalParameters.FieldNameQuantity	= "Count";
	AdditionalParameters.NameOfAmountField		= "Price";
	
	CreationParameters = PurchasesClient.ParametersForCreatingCCDNumber(CurrentRow,
																Item.EditText,
																AdditionalParameters);
	
	PurchasesClient.OpenFormForCreatingGTDNumber(ThisObject, CreationParameters);
	
EndProcedure

&AtClient
Procedure GoodsCountOnChange(Item)
	
	CurrentData = Items.Goods.CurrentData;
	
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	CurrentRow = DescriptionOfTablePartRow(CurrentData);
	CurrentRow.Insert("Products",		CurrentData.ProductsRecordingAsReceived);
	CurrentRow.Insert("Characteristic",	CurrentData.CharacteristicRecordingAsReceived);
	
	StructureOfActions = New Structure;
	AccountingForTraceableGoodsClientServerLocalization.AddDescriptionOfSettingsForRecalculatingDetailsOfTablePart(
		Object,
		StructureOfActions);
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
	CurrentData.QuantityByGBRN = CurrentRow.QuantityByGBRN;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Attachable_ContinueCommandExecutionAtServer(ExecutionParameters, AdditionalParameters) Export
	ExecuteCommandAtServer(ExecutionParameters);
EndProcedure

&AtClient
Procedure OpenInventoryKinds(Command)
	
	OptionsForEditingInventoryTypes = PutGoodsAndStockTypesInStorage();
	
	FinancesClient.OpenInventoryKinds(ThisObject, OptionsForEditingInventoryTypes);
	
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
		CommonClient.MessageToUser(MessageText,,"Goods","Object");		
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
		
		CommonClient.MessageToUser(MessageText,,"PriceKind","Object");		
	EndIf;
EndProcedure

&AtClient
Procedure WriteDocument(Command)
	
	TMCommonUseClient.Write(ThisObject);
	
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
Procedure PostDocument(Command)
	
	TMCommonUseClient.Post(ThisObject);
	
EndProcedure

&AtClient
Procedure PostAndClose(Command)
	
	TMCommonUseClient.PostAndClose(ThisObject);
	
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
	
EndProcedure // Split the string()

&AtClient
Procedure Attachable_PropertiesExecuteCommand(ItemOrCommand, Var_URL = Undefined, StandardProcessing = Undefined)
	PropertyManagerClient.ExecuteCommand(ThisObject, ItemOrCommand, StandardProcessing);
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
Procedure FillInPricesByCosts(Command)
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.StartTimeMeasurement(True,
		"Document.GoodsMisgrading.Form.DocumentForm.Command.FillInPricesByCosts");
	
	ClearMessages();
	If Object.Goods.Count() = 0 Then
		MessageText = NStr("vi = 'Trong chứng từ không điền bảng ""Hàng hóa"". Không thể điền đơn giá';
							|ru = 'В документе не заполнена таблица ""Товары"". Цены не могут быть заполнены';
							|en = 'The ""Goods"" table in the document is not filled in. Cannot fill in the prices'; fa = 'The ""Goods"" table in the document is not filled in. Cannot fill in the prices';
							|it = 'Nel documento non è compilata la tabella ""Merci"". I prezzi non possono essere compilati';
							|pl = 'W dokumencie nie jest wypełniona tabela ""Wiersze pozycji"". Ceny nie mogą być wypełnione.';
							|tr = 'Belgedeki ""Ürünler"" tablosu doldurulmadı. Fiyatlar doldurulamıyor'");
		CommonClient.MessageToUser(MessageText, , "Goods", "Object");		
		Return;
	EndIf;
	
	FillInPricesByCostsServer();
	
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
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ProductsFeatureWriteOff.Name);
	
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
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsCharacteristicRecordingAsReceived.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.ItemVariantsAreUsedRecordingAsReceived");
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
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ProductsPriceRegistration.Name);
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ProductsPriceRegistrationOffBalance.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.ReceiveGoodsAtCostTheyWereIssuedFromWarehouse");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.TextColorOfCanceledRowOfDocument);
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<đưa vào giá vốn>';
													|ru = '<приходуется по себестоимости>';
													|en = '<recorded as received at cost>'; fa = '<recorded as received at cost>';
													|it = '<viene registrato in contabilità al costo di produzione>';
													|pl = '<przyjęcie według kosztu własnego>';
													|tr = '<maliyet üzerinden tüketilir>'"));
	Item.Appearance.SetParameterValue("ReadOnly", True);
	
	//
	ConditionalDesignParameters = ProductsServer.ParametersForSettingConditionalAppearanceOfCCDNumber();
	ConditionalDesignParameters.NameOfFieldForEnteringCCDNumber = "GoodsCCDNumberOriginCountry";
	
	ProductsServer.SetConditionalAppearanceOfCCDNumber(ThisObject);
	ProductsServer.SetConditionalAppearanceOfCCDNumber(ThisObject, ConditionalDesignParameters);
	
	AccountingForTraceableGoodsLocalization.SetConditionalAppearanceOfCCDNumber(ThisObject);
	AccountingForTraceableGoodsLocalization.SetConditionalAppearanceOfQuantityAccordingToRNPT(ThisObject);
	
	AccountingForTraceableGoodsLocalization.ToEstablishConditionalAppearanceOfAccountingForCCDAtGoodsMisgrading(ThisObject);
	
	//
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ProductsSeriesWriteOff.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.BatchesIndicationStatus");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = 0;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.TextColorOfCanceledRowOfDocument);
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<chưa chỉ ra sê-ri>';
													|ru = '<серия не указывается>';
													|en = '<batch is not specified>'; fa = '<بچ مشخص نشده است>';
													|it = '<serie non è indicata>';
													|pl = '<seria nie jest określana>';
													|tr = '<parti belirtilmemektedir>'"));
	Item.Appearance.SetParameterValue("ReadOnly", True);
	
	//
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsBatchReceipt.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.BatchesIndicationStatusReceipt");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = 0;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.TextColorOfCanceledRowOfDocument);
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<chưa chỉ ra sê-ri>';
													|ru = '<серия не указывается>';
													|en = '<batch is not specified>'; fa = '<بچ مشخص نشده است>';
													|it = '<serie non è indicata>';
													|pl = '<seria nie jest określana>';
													|tr = '<parti belirtilmemektedir>'"));
	Item.Appearance.SetParameterValue("ReadOnly", True);
	
	//
	ProductsServer.SetConditionalAppearanceOfProductAssignment(ThisObject,
																			"GoodsPurpose",
																			"Object.Goods.ItemsType");
	
	//
	ProductsServer.SetConditionalAppearanceOfProductAssignment(ThisObject,
																			"GoodsAssignmentGoodsReceipt",
																			"Object.Goods.ItemTypePosting");
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsAssignmentGoodsReceipt.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.AssignmentGoodsReceipt");
	ItemFilter.ComparisonType  = DataCompositionComparisonType.NotFilled;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue  = New DataCompositionField("Object.Goods.ItemTypePosting");
	ItemFilter.ComparisonType   = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.ItemsTypes.OwnGoods;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue  = New DataCompositionField("Object.Goods.AssignmentType");
	ItemFilter.ComparisonType   = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.AssignmentTypes.Giveaway2_5;
	
	Item.Appearance.SetParameterValue("MarkIncomplete", True);
	
	// Quality control.
	
	QualityControl.ConditionalAppearanceOfDateOfConfirmationOfQualityOfSurplus(
		ConditionalAppearance,
		Items.GoodsQualityConfirmationDate);
	
EndProcedure

#Region OnChangeAttributes

&AtServer
Procedure OrganizationOnChangeServer()
	
	UpdateTypeOfVATActivity(True);
	RecalculateNumberOfRNPT();
	
EndProcedure

&AtServer
Procedure WarehouseOnChangeServer(DirectModificationOfWarehouseField = False)
	
	UpdateTypeOfVATActivity(True);
	
	Object.PriceKind = Catalogs.Warehouses.AccountingPriceType(Object.Warehouse);
	Object.Currency  = IncomeAndExpensesServer.GetCurrencyOfManagementAccounting(
						Catalogs.TypesOfPrices.GetPriceTypeDetails(Object.PriceKind).PriceCurrency);
	
	SetFormFunctionalOptionParameters(New Structure("Warehouse", Object.Warehouse));
	
	SeriesSpecificationParameters = New FixedStructure(ProductsServer.SeriesSpecificationParameters(Object,
																									Documents.GoodsMisgrading));
	
	ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);
	
	RecalculateNumberOfRNPT();
	
	SetVisibilityOfQualityControlAttributes();
	If QualityControl.UpdateActionParameters(
			Documents.GoodsMisgrading,
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
	
EndProcedure

&AtServer
Procedure DateOnChangeServer()
	
	UseTraceableImportedGoodsAccounting = AccountingForTraceableGoodsLocalization.UseTraceableImportedGoodsAccounting(
														Object.Date);
	
	AccountingForTraceableGoodsLocalization.EstablishVisibilityOfRNPTQuantity(ThisObject, Object.Date);
	
	If Not Items.ProductsGroupQuantityByRNPT.Visible Then
		RecalculateNumberOfRNPT();
	EndIf;
	
	UpdateTypeOfVATActivity(True);
	
	SetVisibilityOfQualityControlAttributes();
	
	If QualityControl.UpdateActionParameters(
			Documents.GoodsMisgrading,
			Object,
			CacheQualityControl) Then
			
		StructureOfActions = New Structure();
		StructureOfActions.Insert("FillInUnblockableDateOfQualityConfirmation", CacheQualityControl);
		BatchProcessingOfTablePartServer.TreatTS(Object.Goods, StructureOfActions);
		
	EndIf;
	
EndProcedure

&AtServer
Procedure ReceiveGoodsAtCostTheyWereIssuedFromWarehouseOnChangeServer()
	
	SetSettingsForFormattingArticleFields();
	
	// Selection of articles and analytics.
	ItemsAndDimensionsSelectionParameters = Documents.GoodsMisgrading.ItemsAndDimensionsSelectionParameters(
										Object.ReceiveGoodsAtCostTheyWereIssuedFromWarehouse);
	IncomeAndExpensesServer.WhenChangingArticleSelectionParameters(ThisObject, ItemsAndDimensionsSelectionParameters);
	
EndProcedure

#EndRegion

#Region PricingAndDiscounts

&AtClient
Procedure PriceKindOnChangeCompletion(QuestionResult, AdditionalParameters) Export
	
	If QuestionResult = DialogReturnCode.Yes Then
		PricesCalculated = FillInPricesByPriceKindServer();
		SalesClient.NotifyAboutEndOfFillingInPricesByTypeOfPrices(PricesCalculated, Object.PriceKind);
	EndIf;
	
EndProcedure

&AtServer
Function FillInPricesByPriceKindServer()
	
	ColumnsByValue = New Structure("Package", Catalogs.PackagesAndUnitsOfMeasure.EmptyRef());
	OtherColumnNames = New Structure("ProductsRecordingAsReceived, CharacteristicRecordingAsReceived", "Products", "Characteristic");
	
	FillParameters = New Structure;
	FillParameters.Insert("Date", Object.Date);
	FillParameters.Insert("Currency", Object.Currency);
	FillParameters.Insert("PriceKind", Object.PriceKind);
	FillParameters.Insert("ColumnsByValue", ColumnsByValue);
	FillParameters.Insert("OtherColumnNames", OtherColumnNames);
	
	Return EnterprisePricesFillingServer.FillInPrices(
		Object.Goods, // Table part
		 , // Selected lines (fill in all lines)
		FillParameters);
EndFunction

&AtServer
Procedure ClearPrices()
	For Each String In Object.Goods Do
		String.Price = 0;
		String.PriceOffBalance = 0;
	EndDo;
EndProcedure

#EndRegion

#Region SetOfSeries

&AtClient
Procedure OpenSelectionOfSeries(ThisIsSeriesOfLogging, Text = "")
	EditingRegistrationSeries = ThisIsSeriesOfLogging;
	If ThisIsSeriesOfLogging Then
		CurrentData = Items.Goods.CurrentData;
		
		CurrentRow = New Structure;
		CurrentRow.Insert("Products", CurrentData.ProductsRecordingAsReceived);
		CurrentRow.Insert("Characteristic", CurrentData.CharacteristicRecordingAsReceived);
		CurrentRow.Insert("ItemVariantsAreUsed", CurrentData.ItemVariantsAreUsedRecordingAsReceived);
		CurrentRow.Insert("ControlledLotReference", CurrentData.ControlledLotReference);
		CurrentRow.Insert("Series", CurrentData.BatchReceipt);
		CurrentRow.Insert("BatchesIndicationStatus", CurrentData.BatchesIndicationStatusReceipt);
		CurrentRow.Insert("CurrentRowID", CurrentData.GetID());
		CurrentRow.Insert("Count", CurrentData.Count);
		
		If ProductsClient.YouNeedServerCallToSpecifySeries(ThisObject,SeriesSpecificationParameters,Text,CurrentRow)Then
			ExceptionText = NStr("vi = 'Lỗi khi thử chỉ ra sê-ri - để chỉ ra sê-ri trong chứng từ này, không cần gọi ra Server.';
								|ru = 'Ошибка при попытке указать серии - в этом документе для указания серий не нужен серверный вызов.';
								|en = 'An error occurred when attempting to specify batch. No server call is required to specify batch in this document.'; fa = 'An error occurred when attempting to specify batch. No server call is required to specify batch in this document.';
								|it = 'Si è verificato un errore durante il tentativo di indicare le serie - in questo documento non è necessaria la chiamata al server per indicare le serie.';
								|pl = 'Błąd podczas próby określenia serii - w tym dokumencie nie jest wymagane wywołanie serwera, aby wskazać serię.';
								|tr = 'Bir parti belirtmeye çalışırken hata oluştu - bu belgede bir parti belirtmek için sunucu çağrısı gerekmez.'");
			Raise ExceptionText;
		EndIf;
	Else	
		If ProductsClient.YouNeedServerCallToSpecifySeries(ThisObject,SeriesSpecificationParameters,Text)Then
			ExceptionText = NStr("vi = 'Lỗi khi thử chỉ ra sê-ri - để chỉ ra sê-ri trong chứng từ này, không cần gọi ra Server.';
								|ru = 'Ошибка при попытке указать серии - в этом документе для указания серий не нужен серверный вызов.';
								|en = 'An error occurred when attempting to specify batch. No server call is required to specify batch in this document.'; fa = 'An error occurred when attempting to specify batch. No server call is required to specify batch in this document.';
								|it = 'Si è verificato un errore durante il tentativo di indicare le serie - in questo documento non è necessaria la chiamata al server per indicare le serie.';
								|pl = 'Błąd podczas próby określenia serii - w tym dokumencie nie jest wymagane wywołanie serwera, aby wskazać serię.';
								|tr = 'Bir parti belirtmeye çalışırken hata oluştu - bu belgede bir parti belirtmek için sunucu çağrısı gerekmez.'");
			Raise ExceptionText;
		EndIf;
	EndIf;
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
	
	Goods = Object.Goods;
	
	CurrentRow = Goods.FindByID(RowID);
	
	If CurrentRow = Undefined Then
		Return;
	EndIf;
	
	CCDNumbersFilledIn = True;
	
	CurrentRow.CCDNumber = SelectionData_1.MainNumberOfCCD;
	
	AttributesNames = "CCDNumberType, OriginCountry";
	AttributesOfCCD	= Common.ObjectAttributesValues(CurrentRow.CCDNumber, AttributesNames);
	
	FillPropertyValues(CurrentRow, AttributesOfCCD);
	
	FillParameters = PurchasesServer.ParametersForFillingInGTDVNumberOfTabularPart();
	FillParameters.FieldNameNumberOfPackages = "Count";
	
	Actions = New Structure;
	AccountingForTraceableGoodsClientServerLocalization.AddDescriptionOfSettingsForRecalculatingDetailsOfTablePart(
		Object,
		Actions);
	
	If SelectionData_1.ResidualNumberOfCCD <> Undefined Then
		NewRow = Goods.Insert(Goods.IndexOf(CurrentRow) + 1);
		FillPropertyValues(NewRow, CurrentRow);
		
		NewRow.CCDNumber = SelectionData_1.ResidualNumberOfCCD;
		
		BatchProcessingOfTablePartClientServer.RecalculateNumberOfPackagesWhenSelectingCCDNumber(
			CurrentRow,
			NewRow,
			FillParameters.FieldNameNumberOfPackages);
		
		CurrentData = DescriptionOfTablePartRow(NewRow);
		CurrentData.Products = NewRow.ProductsRecordingAsReceived;
		CurrentData.Characteristic = NewRow.CharacteristicRecordingAsReceived;
		
		BatchProcessingOfTablePartServer.ProcessTSString(CurrentData, Actions, Undefined);
		
		NewRow.QuantityByGBRN = CurrentData.QuantityByGBRN;
		
		Items.Goods.CurrentRow = NewRow.GetID();
	EndIf;
	
	CurrentData = DescriptionOfTablePartRow(CurrentRow);
	CurrentData.Products = CurrentRow.ProductsRecordingAsReceived;
	CurrentData.Characteristic = CurrentRow.CharacteristicRecordingAsReceived;
	
	BatchProcessingOfTablePartServer.ProcessTSString(CurrentData, Actions, Undefined);
	
	CurrentRow.QuantityByGBRN = CurrentData.QuantityByGBRN;
	
EndProcedure

&AtServer
Procedure FillInCCDNumbersOnServer(Val CCDNumber, CCDNumbersFilledIn)
	
	FillParameters = PurchasesServer.ParametersForFillingInGTDVNumberOfTabularPart();
	FillParameters.NameOfProductsField = "ProductsRecordingAsReceived";
	FillParameters.FieldNameNumberOfPackages = "Count";
	
	PurchasesServer.FillInGTNumbersInTabularPart(
		Object.Goods,
		CCDNumber,
		Items.Goods.SelectedRows,
		CCDNumbersFilledIn,
		FillParameters);
	
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

#EndRegion

#Region Other

&AtServer
Procedure OnReadCreateAtServer()
	
	UseTraceableImportedGoodsAccounting = AccountingForTraceableGoodsLocalization.UseTraceableImportedGoodsAccounting(
														Object.Date);
	
	SetFormFunctionalOptionParameters(New Structure("Warehouse", Object.Warehouse));
	
	SetAvailability(ThisObject);
	
	FillInServiceDetailsForProductRange();
	AssignmentsServer.FillInDestinationTypeInTable(Object.Goods);
	SeriesSpecificationParameters = New FixedStructure(ProductsServer.SeriesSpecificationParameters(Object,
																									Documents.GoodsMisgrading));
	
	Items.InventoryRecount.Visible = ValueIsFilled(Object.InventoryRecount);
	
	DocumentCurrency = Object.Currency;
	
	UpdateTypeOfVATActivity();
	CacheQualityControl = QualityControl.DataCacheOfMechanism(Object);
	SetVisibilityOfQualityControlAttributes();
	
EndProcedure

&AtServer
Procedure FillInServiceDetailsForProductRange()
	
	ParametersForFillingInBankingDetails = New Structure;
	ParametersForFillingInBankingDetails.Insert("FillInProductTypeAttribute_",
											New Structure("Products, ProductsRecordingAsReceived",
											"ItemsType", "ItemTypePosting"));
	ParametersForFillingInBankingDetails.Insert("FillInFeatureAttribute",
											New Structure("Products, ProductsRecordingAsReceived",
															"ItemVariantsAreUsed", "ItemVariantsAreUsedRecordingAsReceived"));
	ParametersForFillingInBankingDetails.Insert("FillInArticleAttribute",
											New Structure("Products, ProductsRecordingAsReceived",
															"SKU", "SKURegistration"));
	ParametersForFillingInBankingDetails.Insert("FillInCCDTrackingAttribute",
											New Structure("Products, ProductsRecordingAsReceived",
															"RecordsAreKeptForCCDWriteOff", "TheRecordsAreKeptByCCD"));
	ParametersForFillingInBankingDetails.Insert("FillInUnitOfMeasurementOfFEA",
											New Structure("Products, ProductsRecordingAsReceived",
															"UnitOfMeasurementOfFuelTaxWriteOff", "FEACNUnitOfMeasure"));
	
	PaarmetersOfAction = New Structure("Products, ProductsRecordingAsReceived",
										"AccountingIsConductedAccordingToTheRNPTSPISITION", "AccountingForTheRNPTIsMaintained");
	AccountingForTraceableGoodsClientServerLocalization.CompleteDescriptionOfSettingsForFillingInServiceDetailsOfTablePart(
		ParametersForFillingInBankingDetails, PaarmetersOfAction);
	
	ProductsServer.FillInServiceDetailsForProductInCollection(Object.Goods,ParametersForFillingInBankingDetails);
	
	FillParameters = PurchasesServer.ParametersForFillingInServiceAttributesOfCCDNumber();
	FillParameters.NameOfProductsField = "ProductsRecordingAsReceived";
	
	PurchasesServer.FillInServiceAttributesOfCCDNumber(Object.Goods, FillParameters);
	
EndProcedure

&AtServer
Function PutGoodsAndStockTypesInStorage()
	
	OptionsForEditingInventoryTypes = InventoriesServer.OptionsForEditingInventoryTypes();
	If GetFunctionalOption("UseExcisableGoods") Then
		OptionsForEditingInventoryTypes.UseExcisableGoods = True;
	EndIf;
	Return InventoriesServer.PutGoodsAndStockTypesInStorage(ThisObject, OptionsForEditingInventoryTypes);
	
EndFunction

&AtServer
Procedure GetStockTypesFromStorage(ValueSelected)
	
	InventoriesServer.ProcessInputOfInventoryTypesManually(ValueSelected, ThisObject);
	
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
		AssignmentsServer.FillInDestinationTypeInTable(Object.Goods);
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Procedure SetAvailability(Form)
	
	Form.Items.FillInPrices.Enabled = Not Form.Object.ReceiveGoodsAtCostTheyWereIssuedFromWarehouse;
	Form.Items.PriceKind.Enabled       = Not Form.Object.ReceiveGoodsAtCostTheyWereIssuedFromWarehouse;
	
EndProcedure

&AtServer
Procedure SetVisibilityOfQualityControlAttributes()
	
	ElementsAreVisible = Not WarehousesServer.UseWarehouseManagemantSystemForGoodsSurplusesShortages(Object.Warehouse, Object.Date);
	Items.GoodsControlledLotReference.Visible = ElementsAreVisible;
	Items.GoodsQualityConfirmationDate.Visible = ElementsAreVisible;
	
EndProcedure

&AtServer
Procedure SetSettingsForFormattingArticleFields()
	
	MarkingBlankArticles =
		Not Object.ReceiveGoodsAtCostTheyWereIssuedFromWarehouse;
	
	Items.ExpenseItem.AutoMarkIncomplete	= MarkingBlankArticles;
	Items.ExpenseItem.MarkIncomplete		= MarkingBlankArticles;
	
	Items.IncomeItem.AutoMarkIncomplete	= MarkingBlankArticles;
	Items.IncomeItem.MarkIncomplete		= MarkingBlankArticles;
	
EndProcedure

&AtServer
Procedure UpdateAdditionalAttributesItems()
	PropertyManager.UpdateAdditionalAttributesItems(ThisObject);
EndProcedure

&AtServer
Function FillInPricesByCostsServer()
	
	RequestingPreliminaryData = New Query;
	RequestingPreliminaryData.Text =  
	"SELECT
	|	InventoryCostCalculationCompanies.Ref.PreliminaryCalculation AS PreliminaryCalculation
	|FROM
	|	Document.InventoryCostCalculation.Companies AS InventoryCostCalculationCompanies
	|WHERE
	|	InventoryCostCalculationCompanies.Ref.Posted
	|	AND InventoryCostCalculationCompanies.Organization = &Organization
	|	AND InventoryCostCalculationCompanies.Ref.EntryType = VALUE(Enum.LotRecordTypes.EmptyRef)
	|	AND InventoryCostCalculationCompanies.Ref.Date BETWEEN BEGINOFPERIOD(&Date, MONTH) AND ENDOFPERIOD(&Date, MONTH)";
	
	RequestingPreliminaryData.SetParameter("Date", Object.Date);
	RequestingPreliminaryData.SetParameter("Organization", Object.Organization);
	PreliminaryData = RequestingPreliminaryData.Execute().Select();
	
	If PreliminaryData.Next() Then
		PreliminaryCalculation = PreliminaryData.PreliminaryCalculation;
	Else 
		MessageText = NStr("vi = 'Không thể điền đơn giá theo giá vốn trong chứng từ %Document%: trong %Period% chưa tính giá vốn.';
							|ru = 'Не удалось заполнить цены по себестоимости в документе %Document%: на %Period% не произведен расчет себестоимости.';
							|en = 'Cannot fill in prices by cost in document %Document%: cost is not calculated for %Period%.'; fa = 'Cannot fill in prices by cost in document %Document%: cost is not calculated for %Period%.';
							|it = 'Impossibile compilare i prezzi al costo di produzione per il documento %Document%: al %Period% non è stato calcolato il costo di produzione.';
							|pl = 'Nie można wypełnić cen w dokumencie %Document%: na okres %Period% wartość kosztu własnego nie została obliczona.';
							|tr = 'Maliyet fiyatları %Document%belgeye doldurulamadı: %Period% üzerinde maliyet hesaplaması yapılmadı.'");
		MessageText = StrReplace(MessageText, "%Document%", Object.Ref);
		MessageText = StrReplace(MessageText, "%Period%", Format(BegOfMonth(Object.Date),"DLF=DD"));
		Common.MessageToUser(MessageText);
		Return False;
	EndIf;
	
	OtherColumnNames = New Structure("ProductsRecordingAsReceived, CharacteristicRecordingAsReceived", "Products", "Characteristic");
	
	FillParameters = New Structure;
	FillParameters.Insert("Date", Object.Date);
	FillParameters.Insert("Organization", Object.Organization);
	FillParameters.Insert("Currency", Object.Currency);
	FillParameters.Insert("Warehouse", Object.Warehouse);
	FillParameters.Insert("PreliminaryCalculation", PreliminaryCalculation);
	FillParameters.Insert("OtherColumnNames", OtherColumnNames);
	FillParameters.Insert("PopulationFields", "Price, PriceOffBalance");
	
	Return SalesServer.FillInPricesByCosts(
		Object.Goods, // Table part
		Undefined, // Selected lines (fill in all lines)
		FillParameters);
	
EndFunction

&AtServer
Procedure UpdateTypeOfVATActivity(Check = False) 
	
	FillParameters = Documents.GoodsMisgrading.ParametersForFillingInVATActivityType(Object);
	
	If Check Then
		VATAccountingERP.FillInTypeOfActivityVAT(Object.VATActivityType, FillParameters,
			VATAccountingCachedParameterValues);
	EndIf;
	
	VATAccountingERP.FillInActivitySelectionList(Items.VATActivityType,
														Object.VATActivityType,
														FillParameters,
														VATAccountingCachedParameterValues);
	
EndProcedure

&AtServer
Procedure RecalculateNumberOfRNPT()
	
	If ValueIsFilled(Object.Warehouse)
		And ValueIsFilled(Object.Organization) Then
		
		RecalculationParameters = AccountingForTraceableGoodsClientServerLocalization.ParametersForObtainingRnptCoefficient(
								Object);
		
		FieldNamesWithSuffix = RecalculationParameters.FieldNamesWithSuffix;
		FieldNamesWithSuffix.Insert("Products",	"ProductsRecordingAsReceived");
		FieldNamesWithSuffix.Insert("Characteristic",	"CharacteristicRecordingAsReceived");
		
		AccountingForTraceableGoodsLocalization.FillInQuantityByRNPTVOfTablePart(RecalculationParameters,
																						Object.Goods);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure SplitRowCompletion(NewRow, AdditionalParameters) Export
	
	AccountingForTraceableGoodsClientServerLocalization.SplitRowCompletion(NewRow, AdditionalParameters);
	
EndProcedure

// StandardSubsystems.AttachableCommands
&AtClient
Procedure Attachable_ExecuteCommand(Command)
	AttachableCommandsClient.StartCommandExecution(ThisObject, Command, Object);
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


&AtClientAtServerNoContext
Function DescriptionOfTablePartRow(CurrentRow = Undefined)
	
	Keys = "Products, Characteristic, Purpose, Series, BatchesIndicationStatus, ProductsRecordingAsReceived,
		|CharacteristicRecordingAsReceived, AssignmentGoodsReceipt, BatchReceipt, BatchesIndicationStatusReceipt,
		|CCDNumber, Price, Count, QuantityByGBRN, InventoryOwnerAttribute, ItemsLocationAttributes,
		|ItemsLocationAttributesReceipt, ItemVariantsAreUsed,
		|ItemVariantsAreUsedRecordingAsReceived, TheRecordsAreKeptByCCD, SKU, SKURegistration,
		|ItemsType, CCDNumberType, ItemTypePosting, OriginCountry, AccountingForTheRNPTIsMaintained,
		|UnitOfMeasurementOfFuelTaxWriteOff, ControlledLotReference, QualityConfirmationDate, SubjectToUnlocking";
	
	ReturnedDescription = New Structure(Keys);
	
	If CurrentRow <> Undefined Then
		FillPropertyValues(ReturnedDescription, CurrentRow);
	EndIf;
	
	Return ReturnedDescription;
	
EndFunction
&AtClientAtServerNoContext
Function FillingParametersByDestinationType()
	
	Parameters = AssignmentsClientServer.FillParameters();
	Parameters.NameOfFieldToFillIn = "AssignmentGoodsReceipt";
	Parameters.TSFieldName           = "Purpose";
	Parameters.AssignmentType       = PredefinedValue("Enum.AssignmentTypes.Giveaway2_5");
	
	Return Parameters;
	
EndFunction
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
