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

	InfobaseUpdate.CheckObjectProcessed(Object, ThisObject);
	
	// Handler of the subsystem "Versioning of objects"
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	
	// Handler of the "Properties" mechanism
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("Object", Object);
	AdditionalParameters.Insert("ItemForPlacementName", "GroupAdditionalAttributes");
	AdditionalParameters.Insert("DeferredInitialization", True);
	PropertyManager.OnCreateAtServer(ThisForm, AdditionalParameters);
	
	// Handler of the "Destination" mechanism
	Catalogs.Assignments.DocumentFormWhenCreatedOnServer(ThisForm);
	
	FillInAccordingToDataInRepository();

	FillInListOfSpoilageCauses();
	
	Items.GoodsProducts.ReadOnly                = Parameters.ProhibitChangingProducts;
	Items.GoodsCharacteristic.ReadOnly              = Parameters.ProhibitChangingProducts;
	Items.GoodsProductsRecordingAsReceived.ReadOnly   = Parameters.ProhibitChangingProducts;
	Items.GoodsCount.ReadOnly                  = Parameters.ProhibitChangingProducts;
	Items.Warehouse.ReadOnly                             = Parameters.ProhibitChangingProducts;
	Items.Organization.ReadOnly                       = Parameters.ProhibitChangingProducts;
	Items.Fill.Enabled                            = Not Parameters.ProhibitChangingProducts;
	Items.Goods.ChangeRowSet                       = Not Parameters.ProhibitChangingProducts;
	
	If Not ValueIsFilled(Object.Ref) Then
		OnReadCreateAtServer();
	EndIf;
	If IsTempStorageURL(Parameters.AddressOfTheDataInTheStorage)
		Or Not ValueIsFilled(Object.Ref) Then
		ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);
	EndIf;
	
	SetAvailabilityViewPrices();
	
	// Selection of articles and analytics.
	ItemsAndDimensionsSelectionParameters = Documents.GoodsDamage.ItemsAndDimensionsSelectionParameters(
										Object.BusinessOperation, Object.ReceiveGoodsAtCostTheyWereIssuedFromWarehouse);
	IncomeAndExpensesServer.OnCreateAtServer(ThisObject, ItemsAndDimensionsSelectionParameters);
	
	DocumentCorrection.OnCreateAtServer(ThisForm, Items.LineCorrection);
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject);
	// End IntegrationWith1CDocumentManagementSubsystem
	
	
	Items.DecorationEDOState.Visible = GetFunctionalOption("UseElectronicDocumentExchangeWithCounterparties");
	
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	
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
	
	DocumentCorrection.OnReadAtServer(ThisForm, Items.LineCorrection);
	
	// StandardSubsystems.AccessManagement
	AccessManagement.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.AccessManagement
	
	// Handler of the "Date-change" mechanism
	PeriodClosingDates.ObjectOnReadAtServer(ThisForm, CurrentObject);
	PropertyManager.OnReadAtServer(ThisForm, CurrentObject);
	
	OnReadCreateAtServer();
	
	// Selection of articles and analytics.
	ItemsAndDimensionsSelectionParameters = Documents.GoodsDamage.ItemsAndDimensionsSelectionParameters(
										Object.BusinessOperation, Object.ReceiveGoodsAtCostTheyWereIssuedFromWarehouse);
	IncomeAndExpensesServer.OnReadAtServer(ThisObject, ItemsAndDimensionsSelectionParameters);
	
	FormEvents.OnReadAtServer(ThisObject, CurrentObject);
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	// End StandardSubsystems.AttachableCommands
	
	
EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	
	// StandardSubsystems.Properties
	PropertyManager.FillCheckProcessing(ThisForm, Cancel, CheckedAttributes);
	// End StandardSubsystems.Properties
	
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
	
	
	FormEvents.AfterWriteAtServer(ThisForm, CurrentObject, WriteParameters);
	
	ProvisionInDocumentsServer.CheckToRunBackgroundInventoryAllocationJob();
	
EndProcedure

&AtClient
Procedure ChoiceProcessing(ValueSelected, ChoiceSource)

	If ChoiceSource.FormName = "Catalog.InventoryKinds.Form.InventoryOwnerAttributesForm" Then
		
		GetStockTypesFromStorage(ValueSelected);
		
	ElsIf ProductsClient.ThisIsIndicationOfSeries(ChoiceSource) Then
		
		ProductsClient.ProcessSeriesIndication(ThisForm, SeriesSpecificationParameters, ValueSelected);

	ElsIf ChoiceSource.FormName = "Catalog.Assignments.Form.ChoiceForm" Then	
		
		CurrentData = Items.Goods.CurrentData;
		CurrentData.Purpose = ValueSelected;	
		StructureOfActions = New Structure;
		StructureOfActions.Insert("FillInDestinationType", FillingParametersByDestinationType());
		
		BatchProcessingOfTablePartClient.ProcessTSString(CurrentData, StructureOfActions, Undefined);
		If CurrentData <> Undefined And Not ValueIsFilled(CurrentData.Purpose)Then
			CurrentData.ForAssignment = False;
		EndIf;
		
	EndIf;

EndProcedure

&AtClient
Procedure URLProcessing(FormattedStringURL, StandardProcessing)
	
	FormEventsClient.URLProcessing(ThisObject, FormattedStringURL, StandardProcessing);
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	// Subsystem "Properties"
	If PropertyManagerClient.ProcessNotifications(ThisForm, EventName, Parameter) Then
		UpdateAdditionalAttributesItems();
		PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
	EndIf;
	
	DocumentCorrectionClient.NotificationProcessing(ThisForm, EventName, Parameter, Source);
	
	
	FormEventsClient.NotificationProcessing(ThisObject, EventName, Parameter, Source);
	
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

&AtClient
Procedure AfterWrite(WriteParameters)
	
	WriteParameters.Insert("NotificationDocumentKeys", OperationsWithDocumentJournalsClient.GetKeyParametersForDocument(
		Object.Ref, Object.Date, Object.BusinessOperation));
	Notify("Write_GoodsDamage", WriteParameters, Object.Ref);
	
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
Procedure WarehouseOnChange(Item)
	
	WarehouseOnChangeServer();
	CurrencyOnChangeClient();
	
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
		"Document.GoodsDamage.Form.DocumentForm.Item.Currency.OnChange");
	
	CurrencyOnChangeClient();
	
EndProcedure

&AtClient
Procedure SourseOfInformationAboutPricesForPrintingOnChange(Item)
	
	SourseOfInformationAboutPricesForPrintingOnChangeServer();
	
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
Procedure VATActivityTypeClearing(Item, StandardProcessing)
	StandardProcessing = False;
EndProcedure

&AtClient
Procedure LineCorrectionURLProcessing(Item, FormattedStringURL, StandardProcessing)
	DocumentCorrectionClient.StringFixHandlingNavigationLinks(
		ThisObject, FormattedStringURL, StandardProcessing);
EndProcedure

&AtClient
Procedure Decorationedonage(Item, StandardProcessing)
	
	
	Return;
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersGoods

&AtClient
Procedure GoodsProductsOnChange(Item)

	CurrentRow = Items.Goods.CurrentData;
	
	If ValueIsFilled(CurrentRow.ProductsRecordingAsReceived) Then
		ThereIsGradation = ThereIsGradationOfQuality(CurrentRow.Products, CurrentRow.ProductsRecordingAsReceived);
		If Not ThereIsGradation Then
			CurrentRow.ProductsRecordingAsReceived = PredefinedValue("Catalog.Products.EmptyRef");
			CurrentRow.CharacteristicRecordingAsReceived = PredefinedValue("Catalog.ItemsCharacteristics.EmptyRef");
			CurrentRow.ItemVariantsAreUsedRecordingAsReceived = False;
		EndIf;
	EndIf;

	StructureOfActions = New Structure;
	StructureOfActions.Insert("CheckCharacteristicsByOwner", CurrentRow.Characteristic);
	StructureOfActions.Insert("FillInArticleAttribute", New Structure("Products, ProductsRecordingAsReceived", "SKU", "SKURegistration"));
	StructureOfActions.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
	StructureOfActions.Insert("CheckSeriesCalculateStatus", New Structure("Warehouse, SeriesSpecificationParameters", Object.Warehouse, SeriesSpecificationParameters));
	StructureOfActions.Insert("CheckFillAssignment");
	StructureOfActions.Insert("FillInDestinationType", FillingParametersByDestinationType());
	StructureOfActions.Insert("ProductsOnChangeOverridable", New Structure("FormName, TabularSectionName",
		ThisForm.FormName, "Goods"));

	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);

EndProcedure

&AtClient
Procedure GoodsCharacteristicOnChange(Item)

	CurrentRow = Items.Goods.CurrentData;

	StructureOfActions = New Structure;

	StructureOfActions.Insert("CharacteristicOnChangeOverridable", New Structure("FormName, TabularSectionName",
		ThisForm.FormName, "Goods"));
	StructureOfActions.Insert("CheckFillAssignment");
	StructureOfActions.Insert("FillInDestinationType", FillingParametersByDestinationType());
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);

EndProcedure

&AtClient
Procedure GoodsProductsRecordingAsReceivedOnChange(Item)
	CurrentData = Items.Goods.CurrentData;
	
	CurrentRow = New Structure;
	CurrentRow.Insert("Products", CurrentData.ProductsRecordingAsReceived);
	CurrentRow.Insert("Characteristic", CurrentData.CharacteristicRecordingAsReceived);
	CurrentRow.Insert("ItemVariantsAreUsed", CurrentData.ItemVariantsAreUsedRecordingAsReceived);
	CurrentRow.Insert("Price", CurrentData.Price);
	CurrentRow.Insert("PriceKind", Object.PriceKind);
	CurrentRow.Insert("Package", PredefinedValue("Catalog.PackagesAndUnitsOfMeasure.EmptyRef"));
	CurrentRow.Insert("SKU", CurrentData.SKU);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("CheckCharacteristicsByOwner", CurrentData.CharacteristicRecordingAsReceived);
	StructureOfActions.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));
	
	If Not Object.ReceiveGoodsAtCostTheyWereIssuedFromWarehouse Then
		StructureOfActions.Insert("FillInSalePrice", New Structure("Date, Currency", Object.Date, Object.Currency));
	EndIf;

	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);

	CurrentData.CharacteristicRecordingAsReceived = CurrentRow.Characteristic;
	CurrentData.ItemVariantsAreUsedRecordingAsReceived = CurrentRow.ItemVariantsAreUsed;
	CurrentData.SKURegistration = CurrentRow.SKU;
	CurrentData.Price = CurrentRow.Price;
	
EndProcedure

&AtClient
Procedure GoodsCharacteristicRecordingAsReceivedOnChange(Item)
	
	If Object.ReceiveGoodsAtCostTheyWereIssuedFromWarehouse
		Or Not ValueIsFilled(Object.PriceKind) Then
		Return;
	EndIf;
	
	CurrentData = Items.Goods.CurrentData;
	
	CurrentRow = New Structure;
	CurrentRow.Insert("Products", CurrentData.ProductsRecordingAsReceived);
	CurrentRow.Insert("Characteristic", CurrentData.CharacteristicRecordingAsReceived);
	CurrentRow.Insert("ItemVariantsAreUsed", CurrentData.ItemVariantsAreUsedRecordingAsReceived);
	CurrentRow.Insert("Price", CurrentData.Price);
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
Procedure GoodsProductsRecordingAsReceivedStartChoice(Item, ChoiceData, StandardProcessing)
	StandardProcessing = False;
	CurrentData = Items.Goods.CurrentData;
	
	If CurrentData = Undefined Then
		ShowMessageBox(Undefined, NStr("vi = 'Hãy chọn dòng mà bạn muốn thay đổi chất lượng';
										|ru = 'Выберите строку, для которой Вы хотите изменить качество';
										|en = 'Select a line you want to change quality for'; fa = 'Select a line you want to change quality for';
										|it = 'Seleziona la riga per la quale si desidera modificare la qualità';
										|pl = 'Wybierz wiersz, dla którego chcesz zmienić jakość';
										|tr = 'Kalitesini değiştirmek istediğiniz satırı seçin'"));
		Return;
	EndIf;
	
	CurrentData = Items.Goods.CurrentData;
	
	CurrentRow = New Structure;
	CurrentRow.Insert("Products", CurrentData.Products);
	CurrentRow.Insert("Characteristic", CurrentData.Characteristic);
	CurrentRow.Insert("ItemVariantsAreUsed", CurrentData.ItemVariantsAreUsed);
	CurrentRow.Insert("ProductsRecordingAsReceived");
	CurrentRow.Insert("CharacteristicRecordingAsReceived");
	CurrentRow.Insert("ItemVariantsAreUsedRecordingAsReceived");
	CurrentRow.Insert("Price", CurrentData.Price);
	CurrentRow.Insert("PriceKind", Object.PriceKind);
	CurrentRow.Insert("Package", PredefinedValue("Catalog.PackagesAndUnitsOfMeasure.EmptyRef"));
	CurrentRow.Insert("SKU", CurrentData.SKU);
	CurrentRow.Insert("SKURegistration", CurrentData.SKURegistration);

	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInArticleAttribute", New Structure("Products, ProductsOfOriginalQuality", "SKU", "SKURegistration"));
	StructureOfActions.Insert("CheckCharacteristicsByOwner", CurrentData.Characteristic);
	If ValueIsFilled(CurrentData.Characteristic) Then
		StructureOfActions.Insert("FillInDescriptionOfPoorQualityProduct", CurrentData.Characteristic);
	EndIf;
	If Not Object.ReceiveGoodsAtCostTheyWereIssuedFromWarehouse Then
		StructureOfActions.Insert("FillInSalePrice", New Structure("Date, Currency", Object.Date, Object.Currency));
	EndIf;
	
	Notification = New CallbackDescription("GoodsProductsRecordingAsReceivedStartChoiceCompletion", 
		ThisObject, New Structure("CurrentData", CurrentData));
	WarehousesClient.ChangeQuality(CurrentRow, StructureOfActions, CachedValues, Notification);
	
EndProcedure

&AtClient
Procedure GoodsProductsRecordingAsReceivedStartChoiceCompletion(CurrentRow, AdditionalParameters) Export 
	
	FillPropertyValues(AdditionalParameters.CurrentData, CurrentRow);

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
Procedure GoodsPurposeOnChange(Item)
	
	CurrentData = Items.Goods.CurrentData;
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInDestinationType", FillingParametersByDestinationType());
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentData, StructureOfActions, Undefined);
	If CurrentData <> Undefined And Not ValueIsFilled(CurrentData.Purpose)Then
		CurrentData.ForAssignment = False;
	EndIf;
	
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
Procedure WriteDocument(Command)
	
	TMCommonUseClient.Write(ThisForm);
	
EndProcedure

&AtClient
Procedure Fill(Command)

	If Object.Goods.Count() > 0 Then
		Response = Undefined;

		ShowQueryBox(New CallbackDescription("FillCompletion", ThisObject), NStr("vi = 'Phần bảng sẽ bị xóa và điền bởi tất cả hàng hóa cần tạo phần hư hỏng. Tiếp tục?';
																				|ru = 'Табличная часть будет очищена и заполнена всеми товарами, по которым нужно оформить порчу. Продолжить?';
																				|en = 'The table will be refilled with damaged items. Do you want to continue?'; fa = 'The table will be refilled with damaged items. Do you want to continue?';
																				|it = 'La parte tabulare verrà cancellata e compilata con tutti i prodotti per i quali è necessario formalizzare il danno. Continuare?';
																				|pl = 'Część tabelaryczna zostanie wyczyszczona i wypełniona wszystkimi towarami, dla których chcesz wskazać uszkodzenia. Kontynuować?';
																				|tr = 'Tablo bölümü temizlenecek ve stok kalite değişikliği düzenlenmesi gereken tüm ürünlerle doldurulacaktır. Devam edilsin mi?'"), QuestionDialogMode.YesNo);
        Return;
	EndIf;

	FillAtServer();
EndProcedure

&AtClient
Procedure FillCompletion(QuestionResult, AdditionalParameters) Export
    
    Response = QuestionResult;
    If Response <> DialogReturnCode.Yes Then
        Return;
    EndIf;
    
    FillAtServer();

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
		
		CommonClientServer.MessageToUser(MessageText, , "Goods", "Object");
		Return;
	EndIf;
	
	PriceKind = PriceManagementSystemServerCall.PriceTypePriceList_();
	
	If ValueIsFilled(Object.PriceKind)
		Or PriceKind <> Undefined Then
		
		PriceKind = ?(ValueIsFilled(Object.PriceKind), Object.PriceKind, PriceKind);
		PricesCalculated = FillInPricesByPriceKindServer(PriceKind);
		
		SalesClient.NotifyAboutEndOfFillingInPricesByTypeOfPrices(PricesCalculated, PriceKind);
		
	Else
		MessageText = NStr("vi = 'Chưa chỉ ra dạng giá';
							|ru = 'Не указан вид цены';
							|en = 'Price type is not specified'; fa = 'Price type is not specified';
							|it = 'Il tipo di prezzo non è indicato';
							|pl = 'Nie podano rodzaju ceny';
							|tr = 'Fiyat türü belirtilmedi'");
		
		CommonClientServer.MessageToUser(MessageText, , "PriceKind", "Object");
	EndIf;
	
EndProcedure

&AtClient
Procedure FillInPricesByCosts(Command)
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.StartTimeMeasurement(True,
		"Document.GoodsDamage.Form.DocumentForm.Command.FillInPricesByCosts");
	
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
	
	FillInPricesByCostsServer();
	
EndProcedure

&AtClient
Procedure OpenInventoryKinds(Command)
	
	OptionsForEditingInventoryTypes = PutGoodsAndStockTypesInStorage();
	
	FinancesClient.OpenInventoryKinds(ThisObject, OptionsForEditingInventoryTypes);

EndProcedure

&AtClient
Procedure Attachable_PropertiesExecuteCommand(ItemOrCommand, Var_URL = Undefined, StandardProcessing = Undefined)
	PropertyManagerClient.ExecuteCommand(ThisObject, ItemOrCommand, StandardProcessing);
EndProcedure // Edit the Properties()

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
	
	ProcessingOfTabularFormsClient.SplitRow(TableData, FormTable,, StringSplittingParameters);
	
EndProcedure // Split the string()

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
	InventoriesServer.EstablishConditionalAppearanceOfDivisionForTypesOfStocks(ThisObject);
	
	// Setting the Conditional appearance of a different quality item.
	ProductsServer.SetConditionalAppearanceOfDifferentQualityItem(ThisObject);
	
	//
	ProductsServer.EstablishConditionalAppearanceOfProductCharacteristics(ThisObject);
	
	//
	ProductsServer.EstablishConditionalAppearanceOfProductCharacteristics(ThisObject,
																			"GoodsCharacteristicRecordingAsReceived",
																			"Object.Goods.ItemVariantsAreUsedRecordingAsReceived");
	
	//
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsPrice.Name);
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsPriceOffBalance.Name);
	
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
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsForAssignment.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue  = New DataCompositionField("Object.Goods.AssignmentType");
	ItemFilter.ComparisonType   = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.AssignmentTypes.Giveaway2_5;
	
	Item.Appearance.SetParameterValue("ReadOnly", True);
	
	//
	ProductsServer.EstablishConditionalAppearanceOfProductSeries(ThisObject, "SeriesAlwaysWHGoods");
	
	// Visibility of the "Under appointment" column
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsForAssignment.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.Purpose");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	Item.Appearance.SetParameterValue("Show", False);
	
	//
	ProductsServer.SetConditionalAppearanceOfProductAssignment(ThisObject);
	
EndProcedure

#Region OnChangeAttributes

&AtServer
Procedure WarehouseOnChangeServer()
	
	UpdateTypeOfVATActivity(True);
	
	Object.SourseOfInformationAboutPricesForPrinting = Catalogs.Warehouses.SourseOfInformationAboutPricesForPrinting(Object.Warehouse);
	Object.Currency = IncomeAndExpensesServer.GetCurrencyOfManagementAccounting(Catalogs.TypesOfPrices.GetPriceTypeDetails(
																				Catalogs.Warehouses.AccountingPriceType(Object.Warehouse)).PriceCurrency);
	
	SourseOfInformationAboutPricesForPrintingOnChangeServer();
	SeriesSpecificationParameters = New FixedStructure(ProductsServer.SeriesSpecificationParameters(Object,
																									Documents.GoodsDamage));
	
	ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);
	SetFormFunctionalOptionParameters(New Structure("Warehouse", Object.Warehouse));
	
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
Procedure SourseOfInformationAboutPricesForPrintingOnChangeServer()
	
	SetValueForPriceType(Object.SourseOfInformationAboutPricesForPrinting);
	SetAvailabilityViewPrices();
	
EndProcedure

&AtServer
Procedure ReceiveGoodsAtCostTheyWereIssuedFromWarehouseOnChangeServer()
	
	Items.FillInPrices.Enabled						= Not Object.ReceiveGoodsAtCostTheyWereIssuedFromWarehouse;
	Items.SourseOfInformationAboutPricesForPrinting.Enabled	= Not Object.ReceiveGoodsAtCostTheyWereIssuedFromWarehouse;
	
	Object.SourseOfInformationAboutPricesForPrinting = ?(Object.ReceiveGoodsAtCostTheyWereIssuedFromWarehouse,
												Enums.SourcesOfPriceInformationForPrinting.ByCost,
												Object.SourseOfInformationAboutPricesForPrinting);
	
	If Object.ReceiveGoodsAtCostTheyWereIssuedFromWarehouse Then
		Object.PriceKind = Undefined;
		
		ClearPrices();
	EndIf;
	
	FillInArticleSelectionParameters();
	SetAvailabilityViewPrices();
	
EndProcedure

&AtServer
Procedure DateOnChangeServer()
	
	UpdateTypeOfVATActivity(True);
	
	ResponsiblePersonsServer.WhenChangingRelatedDocumentDetails(Object);
	
EndProcedure

&AtServer
Procedure OrganizationOnChangeServer()
	
	UpdateTypeOfVATActivity(True);
	
	ResponsiblePersonsServer.WhenChangingRelatedDocumentDetails(Object);
	
EndProcedure

#EndRegion

#Region PricingAndDiscounts

&AtServer
Function FillInPricesByPriceKindServer(PriceKind = Undefined)
	
	If PriceKind = Undefined Then
		PriceKind = Object.PriceKind;
	EndIf;
	
	ColumnsByValue = New Structure("Package", Catalogs.PackagesAndUnitsOfMeasure.EmptyRef());
	OtherColumnNames = New Structure("ProductsRecordingAsReceived, CharacteristicRecordingAsReceived", "Products", "Characteristic");
	
	FillParameters = New Structure;
	FillParameters.Insert("Date", Object.Date);
	FillParameters.Insert("Organization", Object.Organization);
	FillParameters.Insert("Currency", Object.Currency);
	FillParameters.Insert("PriceKind", PriceKind);
	FillParameters.Insert("ColumnsByValue", ColumnsByValue);
	FillParameters.Insert("OtherColumnNames", OtherColumnNames);
	
	Return EnterprisePricesFillingServer.FillInPrices(
		Object.Goods, // Table part
		 , // Selected lines (fill in all lines)
		FillParameters);
	
EndFunction

&AtServer
Function FillInPricesByCostsServer()
	
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
	FillParameters.Insert("PopulationFields", "Price, PriceOffBalance");
	
	Return SalesServer.FillInPricesByCosts(
		Object.Goods, // Table part
		Undefined, // Selected lines (fill in all lines)
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
Procedure OpenSelectionOfSeries(Text = "")
	If ProductsClient.YouNeedServerCallToSpecifySeries(ThisForm,SeriesSpecificationParameters,Text)Then
		ExceptionText = NStr("vi = 'Lỗi khi thử chỉ ra sê-ri - để chỉ ra sê-ri trong chứng từ này, không cần gọi ra Server.';
							|ru = 'Ошибка при попытке указать серии - в этом документе для указания серий не нужен серверный вызов.';
							|en = 'An error occurred when attempting to specify batch. No server call is required to specify batch in this document.'; fa = 'An error occurred when attempting to specify batch. No server call is required to specify batch in this document.';
							|it = 'Si è verificato un errore durante il tentativo di indicare le serie - in questo documento non è necessaria la chiamata al server per indicare le serie.';
							|pl = 'Błąd podczas próby określenia serii - w tym dokumencie nie jest wymagane wywołanie serwera, aby wskazać serię.';
							|tr = 'Bir parti belirtmeye çalışırken hata oluştu - bu belgede bir parti belirtmek için sunucu çağrısı gerekmez.'");
		Raise ExceptionText;
	EndIf;
EndProcedure

#EndRegion

#Region Other

&AtServer
Procedure OnReadCreateAtServer()
	
	SeriesSpecificationParameters = New FixedStructure(
		ProductsServer.SeriesSpecificationParameters(Object,
			Documents.GoodsDamage));
	
	SetFormFunctionalOptionParameters(New Structure("Warehouse", Object.Warehouse));
	
	FillInServiceDetailsForProductRange();
	AssignmentsServer.FillInDestinationTypeInTable(Object.Goods);
	Items.FillInPrices.Enabled = Not Object.ReceiveGoodsAtCostTheyWereIssuedFromWarehouse;
	
	Items.InventoryRecount.Visible = ValueIsFilled(Object.InventoryRecount);
	
	DocumentCurrency = Object.Currency;
	
	UpdateTypeOfVATActivity();
	
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
	
	InventoriesServer.ProcessInputOfInventoryTypesManually(ValueSelected, ThisForm);
	
EndProcedure

&AtServer
Procedure FillAtServer()

	TimeObject = FormAttributeToValue("Object");

	TimeObject.Goods.Clear();
	
	TimeObject.FillInTablePart();
	
	ValueToFormAttribute(TimeObject, "Object");

	FillInServiceDetailsForProductRange();
	AssignmentsServer.FillInDestinationTypeInTable(Object.Goods);
	FillInListOfSpoilageCauses();
	
	ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);
	
EndProcedure

&AtServer
Procedure FillInServiceDetailsForProductRange()
	ParametersForFillingInBankingDetails = New Structure;
	ParametersForFillingInBankingDetails.Insert("FillInFeatureAttribute",
											New Structure("Products, ProductsRecordingAsReceived", "ItemVariantsAreUsed", "ItemVariantsAreUsedRecordingAsReceived"));
	ParametersForFillingInBankingDetails.Insert("FillInArticleAttribute",
											New Structure("Products, ProductsRecordingAsReceived", "SKU", "SKURegistration"));
	ParametersForFillingInBankingDetails.Insert("FillInProductTypeAttribute_",
											New Structure("Products", "ItemsType"));
											
	ProductsServer.FillInServiceDetailsForProductInCollection(Object.Goods,ParametersForFillingInBankingDetails);	
EndProcedure

&AtServer
Procedure FillInListOfSpoilageCauses()
	Query = New Query;
	Query.Text =
	"SELECT ALLOWED TOP 100
	|	GoodsDamage.CauseForDamage AS CauseForDamage,
	|	GoodsDamage.Date AS DocumentDate
	|INTO CausesOfDamageToGoods
	|FROM
	|	Document.GoodsDamage AS GoodsDamage
	|WHERE
	|	GoodsDamage.Posted
	|	AND GoodsDamage.BusinessOperation = &BusinessOperation
	|	AND GoodsDamage.CauseForDamage <> """"
	|
	|ORDER BY
	|	DocumentDate DESC
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT TOP 30
	|	CausesOfDamageToGoods.CauseForDamage
	|FROM
	|	CausesOfDamageToGoods AS CausesOfDamageToGoods";
	
	Query.SetParameter("BusinessOperation", Object.BusinessOperation);
	
	Result = Query.Execute().Unload();
	Items.CauseForDamage.ChoiceList.LoadValues(Result.UnloadColumn("CauseForDamage"));
	
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

&AtServer
Function ThereIsGradationOfQuality(ProductOfOriginalQuality, NonconformingProducts)
	
	 Return InformationRegisters.AnotherQualityGoods.CheckForGradation(ProductOfOriginalQuality, NonconformingProducts);
	
EndFunction

&AtServer
Procedure UpdateAdditionalAttributesItems()
	PropertyManager.UpdateAdditionalAttributesItems(ThisForm);
EndProcedure

&AtServer
Procedure SetAvailabilityViewPrices()
	
	If Object.SourseOfInformationAboutPricesForPrinting = Enums.SourcesOfPriceInformationForPrinting.ByCost 
		And Object.ReceiveGoodsAtCostTheyWereIssuedFromWarehouse Then
		
		Items.PriceKind.Enabled = False;
		
	Else
		Items.PriceKind.Enabled = True;
	EndIf;
	
EndProcedure

&AtServer
Procedure FillInArticleSelectionParameters()
	
	// Selection of articles and analytics.
	ItemsAndDimensionsSelectionParameters = Documents.GoodsDamage.ItemsAndDimensionsSelectionParameters(
										Object.BusinessOperation, Object.ReceiveGoodsAtCostTheyWereIssuedFromWarehouse);
	IncomeAndExpensesServer.WhenChangingArticleSelectionParameters(ThisObject, ItemsAndDimensionsSelectionParameters);
	
EndProcedure

&AtServer
Procedure SetValueForPriceType(SourseOfInformationAboutPricesForPrinting)
	
	If ValueIsFilled(Object.Warehouse)
		And SourseOfInformationAboutPricesForPrinting = Enums.SourcesOfPriceInformationForPrinting.ByPriceType Then
		
		Object.PriceKind = Catalogs.Warehouses.AccountingPriceType(Object.Warehouse);
		
	ElsIf SourseOfInformationAboutPricesForPrinting = Enums.SourcesOfPriceInformationForPrinting.ByCost Then
		Object.PriceKind = Undefined;
	EndIf;
	
EndProcedure

&AtServer
Procedure UpdateTypeOfVATActivity(Check = False) 
	
	FillParameters = Documents.GoodsDamage.ParametersForFillingInVATActivityType(Object);
	
	If Check Then
		VATAccountingERP.FillInTypeOfActivityVAT(Object.VATActivityType, FillParameters,
			VATAccountingCachedParameterValues);
	EndIf;
	
	VATAccountingERP.FillInActivitySelectionList(Items.VATActivityType,
														Object.VATActivityType,
														FillParameters,
														VATAccountingCachedParameterValues);
	
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
&AtClientAtServerNoContext
Function FillingParametersByDestinationType()
	
	Parameters = AssignmentsClientServer.FillParameters();
	Parameters.NameOfFieldToFillIn = "ForAssignment";
	Parameters.Simple        = True;
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
