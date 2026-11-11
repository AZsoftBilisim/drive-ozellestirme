#Region Variables

&AtClient
Var CachedValues;

&AtClient
Var CurDataId; //used to pass the current line to the wait handler

#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	InitializationOfFillingSettingsByBalances(
		"FillingSchemeByLotBalances",
		AddressOfSchemeSettingUpFillingByBatchBalance,
		FillingSettingsForBatchBalances);
	
	InfobaseUpdate.CheckObjectProcessed(Object, ThisObject);
	
	TMCommonUse.CustomizePeripherals(ThisObject);
	
	// Filling in from the workplace of the product quality control.
	If Parameters.FillInByBalance Then
		
		Analysts = GetFromTempStorage(Parameters.Analysts);
		Object.ControlledLotReference = Analysts[0].ControlledLotReference;
		Documents.GoodsQualityControlCertificate.FillInDetailsFromParty(Object);
		Object.Goods.Load(QualityControl.AnalystBalances(Analysts, False, CurrentSessionDate()));
		FillCleanWarehouseRoomAccordingToTabularPartOfDocument();
		Object.Organization = Documents.GoodsQualityControlCertificate.CompanyFromControlledLotReference(Object);
		
	EndIf;
	
	If Not ValueIsFilled(Object.Ref) Then
		
		OnReadCreateAtServer();
		
	EndIf;
	
	If Parameters.FillInByBalance Then
		
		// The parameters of the series are initialized in the account and created in the server.
		ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);
		
	EndIf;
	
	// Handler of the "Destination" mechanism
	Catalogs.Assignments.DocumentFormWhenCreatedOnServer(ThisObject);
	
	// Working With The Clipboard
	SetAvailabilityOfClipboardCommands();
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	// StandardSubsystems.ObjectsVersioning
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.ObjectsVersioning
	
	// StandardSubsystems.Properties
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("ItemForPlacementName", "GroupAdditionalAttributes");
	AdditionalParameters.Insert("DeferredInitialization", True);
	PropertyManager.OnCreateAtServer(ThisObject, AdditionalParameters);
	// End StandardSubsystems.Properties
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject);
	// End IntegrationWith1CDocumentManagementSubsystem
	
	// StandardSubsystems.FilesOperations
	HyperlinkParameters = FilesOperations.FilesHyperlink();
	HyperlinkParameters.Location = "CommandBar";
	FilesOperations.OnCreateAtServer(ThisObject, HyperlinkParameters);
	// End StandardSubsystems.FilesOperations
	
	FormEvents.OnCreateAtServer(ThisObject, Cancel, StandardProcessing);
	
	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	EquipmentManagerClient.StartConnectingDevicesWhenYouOpenForm(Undefined, ThisObject, "BarcodeScanner");
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	// StandardSubsystems.FilesOperations
	FilesOperationsClient.OnOpen(ThisObject, Cancel);
	// End StandardSubsystems.FilesOperations

	// StandardSubsystems.Properties
	PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
	// End StandardSubsystems.Properties
	
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	
	NotifyAboutDocument(WriteParameters);
	
	// StandardSubsystems.AttachableCommands
	If CommonClient.SubsystemExists("StandardSubsystems.AttachableCommands") Then
		ModuleAttachableCommandsClient = CommonClient.CommonModule("AttachableCommandsClient");
		ModuleAttachableCommandsClient.AfterWrite(ThisObject, Object, WriteParameters);
	EndIf;
	// End StandardSubsystems.AttachableCommands
	
	CommandKey = Undefined;
	If WriteParameters.Property("CommandKey", CommandKey) Then
		
		If Object.Posted Then
			
			IssueDocument(CommandKey);
			
		EndIf;
		
	EndIf;
	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	// StandardSubsystems.Properties
	PropertyManager.BeforeWriteAtServer(ThisObject, CurrentObject);
	// The end of the standard subsystem.Properties
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.BeforeWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	// End IntegrationWith1CDocumentManagementSubsystem
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)
	
	// StandardSubsystems.AccessManagement
	AccessManagement.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	// End StandardSubsystems.AccessManagement
	
	FillInArticleAttribute = New Structure("Products,ProductsRecordingAsReceived",
		"SKU",
		"SKURegistration");
	FillInProductTypeAttribute_ = New Structure("Products,ProductsRecordingAsReceived",
		"ItemsType", 
		"ItemTypePosting");
	FillInMeasuredValueTypeAttribute = New Structure("Products,ProductsRecordingAsReceived",
		"MeasuredValueType",
		"TypeOfMeasuredValueEntry");
	FillInFeatureAttribute = New Structure("Products,ProductsRecordingAsReceived",
		"ItemVariantsAreUsed",
		"ItemVariantsAreUsedRecordingAsReceived");
	FillInSpaceUsageAttribute = New Structure("Date", Object.Date);
	FillInAddressStorageAttribute = New Structure("Date", Object.Date);
	
	StructureOfActions = New Structure();
	StructureOfActions.Insert("FillInArticleAttribute", FillInArticleAttribute);
	StructureOfActions.Insert("FillInProductTypeAttribute_", FillInProductTypeAttribute_);
	StructureOfActions.Insert("FillInMeasuredValueTypeAttribute", FillInMeasuredValueTypeAttribute);
	StructureOfActions.Insert("FillInFeatureAttribute", FillInFeatureAttribute);
	StructureOfActions.Insert("FillInSpaceUsageAttribute", FillInSpaceUsageAttribute);
	StructureOfActions.Insert("FillInAddressStorageAttribute", FillInAddressStorageAttribute);
	
	BatchProcessingOfTablePartServer.TreatTS(Object.Goods, StructureOfActions);
	DeleteUnusedStudies();
	FillOutResearch();
EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	
	// StandardSubsystems.Properties
	PropertyManager.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes);
	// End StandardSubsystems.Properties
	
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)
	
	// StandardSubsystems.AccessManagement
	AccessManagement.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.AccessManagement
	
	OnReadCreateAtServer();
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	// End StandardSubsystems.AttachableCommands
	
	// StandardSubsystems.Properties
	PropertyManager.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.Properties
	
EndProcedure

&AtClient
Procedure ChoiceProcessing(ValueSelected, ChoiceSource)
	
	If ChoiceSource.FormName = "DataProcessor.SelectGoodsToSalesDocument.Form.Form" Then
		
		ProcessingSelectionOfSelectionOnServer(ValueSelected);
		
	ElsIf
	
		ProductsClient.ThisIsIndicationOfSeries(ChoiceSource) Then
		ProductsClient.ProcessSeriesIndication(ThisObject, SeriesSpecificationParameters, ValueSelected);
		
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
	
	// Working With The Clipboard
	If EventName = "CopyingLinesToClipboard" Then
		SetAvailabilityOfClipboardCommandsOnClient();
	EndIf;
	
	// StandardSubsystems.Properties 
	If PropertyManagerClient.ProcessNotifications(ThisObject, EventName, Parameter) Then
		UpdateAdditionalAttributesItems();
		PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
	EndIf;
	// End StandardSubsystems.Properties
	
	// StandardSubsystems.FilesOperations
	FilesOperationsClient.NotificationProcessing(ThisObject, EventName);
	// End StandardSubsystems.FilesOperations
	
EndProcedure

&AtClient
Procedure OnClose(Exit)
	
	EquipmentManagerClient.StartDisablingHardwareWhenClosingForm(Undefined, ThisObject);
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure PagesOnCurrentPageChange(Item, CurrentPage)
	
	// StandardSubsystems.Properties
	If ThisObject.PropertiesParameters.Property(CurrentPage.Name)
			And Not ThisObject.PropertiesParameters.DeferredInitializationExecuted Then
		
		PropertiesExecuteDeferredInitialization();
		PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
	EndIf;
	// End StandardSubsystems.Properties
	
EndProcedure

&AtClient
Procedure DateOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	
	WhenChangingDateServer();
	
EndProcedure

&AtClient
Procedure WarehouseOnChange(Item)
	
	WhenChangingWarehouseServer();
	
EndProcedure

&AtClient
Procedure PremiseOnChange(Item)
	
	OnChangingRoomServer();
	
EndProcedure

&AtClient
Procedure ControlledLotReferenceOnChange(Item)
	
	OnChangingControlledLotReferenceServer();
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersGoods

&AtClient
Procedure GoodsProductsOnChange(Item)
	
	TableRow = Items.Goods.CurrentData;
	
	If ValueIsFilled(TableRow.ProductsRecordingAsReceived) Then
		ThereIsGradation = ThereIsProductOfDifferentQuality(TableRow.Products, TableRow.ProductsRecordingAsReceived);
		If Not ThereIsGradation Then
			TableRow.ProductsRecordingAsReceived = PredefinedValue("Catalog.Products.EmptyRef");
			TableRow.CharacteristicRecordingAsReceived = PredefinedValue("Catalog.ItemsCharacteristics.EmptyRef");
			TableRow.PackagingReceipt = PredefinedValue("Catalog.PackagesAndUnitsOfMeasure.EmptyRef");
		EndIf;
	EndIf;
	
	FillInArticleAttribute = New Structure("Products,ProductsRecordingAsReceived",
		"SKU",
		"SKURegistration");
	FillInProductTypeAttribute_ = New Structure("Products,ProductsRecordingAsReceived",
		"ItemsType", 
		"ItemTypePosting");
	FillInMeasuredValueTypeAttribute = New Structure("Products,ProductsRecordingAsReceived",
		"MeasuredValueType",
		"TypeOfMeasuredValueEntry");
	FillInFeatureAttribute = New Structure("Products,ProductsRecordingAsReceived",
		"ItemVariantsAreUsed",
		"ItemVariantsAreUsedRecordingAsReceived");
	
	CheckSeriesCalculateStatus = New Structure("Warehouse,SeriesSpecificationParameters",
		TableRow.Warehouse,
		SeriesSpecificationParameters);
	
	CheckFillWarehouse = CheckFillWarehouseActionParameters(Object.Warehouse);
	FillInSpaceUsageAttribute = New Structure("Date", Object.Date);
	FillInAddressStorageAttribute = New Structure("Date", Object.Date);
	
	ProductsOnChangeOverridable = New Structure("FormName, TabularSectionName",
		FormName, "Goods");
	
	StructureOfActions = New Structure();
	StructureOfActions.Insert("FillInArticleAttribute", FillInArticleAttribute);
	StructureOfActions.Insert("FillInProductTypeAttribute_", FillInProductTypeAttribute_);
	StructureOfActions.Insert("FillInMeasuredValueTypeAttribute", FillInMeasuredValueTypeAttribute);
	StructureOfActions.Insert("FillInFeatureAttribute", FillInFeatureAttribute);
	StructureOfActions.Insert("ProductsOnChangeOverridable", ProductsOnChangeOverridable);
	StructureOfActions.Insert("CheckCharacteristicsByOwner", TableRow.Characteristic);
	StructureOfActions.Insert("CheckSeriesCalculateStatus", CheckSeriesCalculateStatus);
	StructureOfActions.Insert("CheckFillPackageByOwner", TableRow.Package);
	StructureOfActions.Insert("CheckFillWarehouse", CheckFillWarehouse);
	StructureOfActions.Insert("FillInSpaceInTSLine", Object.Premise);
	StructureOfActions.Insert("FillInSpaceUsageAttribute", FillInSpaceUsageAttribute);
	StructureOfActions.Insert("FillInAddressStorageAttribute", FillInAddressStorageAttribute);
	
	BatchProcessingOfTablePartClient.ProcessTSString(TableRow, StructureOfActions, CachedValues);
	
	RecalculateNumberOfEntries(TableRow);
	
EndProcedure

&AtClient
Procedure GoodsPurposeOnChange(Item)
	
	CurrentData = Items.Goods.CurrentData;
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInDestinationType", FillingParametersByDestinationType());
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentData, StructureOfActions, Undefined);
	
EndProcedure

&AtClient
Procedure GoodsSeriesOnChange(Item)
	
	ValueSelected = ProductsClientServer.SelectedSeries();
	
	ValueSelected.Value = Items.Goods.CurrentData.Series;
	ValueSelected.CurrentRowID = Items.Goods.CurrentData.GetID();
	
	ProductsClient.ProcessSeriesIndication(ThisObject, SeriesSpecificationParameters, ValueSelected);
	
EndProcedure

&AtClient
Procedure GoodsSeriesStartChoice(Item, ChoiceData, ChoiceByAdding, StandardProcessing)
	
	StandardProcessing = False;
	OpenSelectionOfSeries(Item.EditText);
	
EndProcedure

&AtClient
Procedure GoodsPackageOnChange(Item)
	
	TableRow = Items.Goods.CurrentData;
	StructureOfActions = New Structure();
	StructureOfActions.Insert("RecalculateNumberOfPackages");
	
	BatchProcessingOfTablePartClient.ProcessTSString(TableRow, StructureOfActions, CachedValues);
	
	If ValueIsFilled(TableRow.ProductsRecordingAsReceived) Then
		
		LowQualityProductData = New Structure("ProductsOfOriginalQuality, Products, Package", 
			TableRow.Products, TableRow.ProductsRecordingAsReceived, TableRow.Package);
		
		StructureOfActionsWithLowQualityGoods = New Structure;
		StructureOfActionsWithLowQualityGoods.Insert("CheckFillPackageByOwner", TableRow.Package);
		StructureOfActionsWithLowQualityGoods.Insert("FillInPackagingOfLowQualityGoods", TableRow.Package);
		
		BatchProcessingOfTablePartClient.ProcessTSString(
			LowQualityProductData,
			StructureOfActionsWithLowQualityGoods,
			Undefined);
		TableRow.PackagingReceipt = LowQualityProductData.Package;
		
	EndIf;
	
	RecalculateNumberOfEntries(TableRow);
	
EndProcedure

&AtClient
Procedure GoodsActionAutoComplete(Item, Text, ChoiceData, DataGetParameters, Waiting, StandardProcessing)
	
	CurrentData = Items.Goods.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	StandardProcessing = False;
	MethodParameters = New Structure();
	MethodParameters.Insert("ControlledLotReference", Object.ControlledLotReference);
	MethodParameters.Insert("Warehouse", CurrentData.Warehouse);
	MethodParameters.Insert("Date", Object.Date);
	ChoiceData = ActionSelectionData(MethodParameters);
	
EndProcedure

&AtClient
Procedure GoodsActionOnChange(Item)
	
	TableRow = Items.Goods.CurrentData;
	CheckClearAccountAttributes(TableRow);
	
EndProcedure

&AtClient
Procedure GoodsNumberOfPackagesOnChange(Item)
	
	TableRow = Items.Goods.CurrentData;
	StructureOfActions = New Structure();
	StructureOfActions.Insert("RecalculateNumberOfUnits");
	
	BatchProcessingOfTablePartClient.ProcessTSString(TableRow, StructureOfActions, CachedValues);
	
	RecalculateNumberOfEntries(TableRow);
	
EndProcedure

&AtClient
Procedure GoodsWarehouseOnChange(Item)
	
	TableRow = Items.Goods.CurrentData;
	
	CheckSeriesCalculateStatus = New Structure("Warehouse, SeriesSpecificationParameters", TableRow.Warehouse, SeriesSpecificationParameters);
	FillInSpaceUsageAttribute = New Structure("Date", Object.Date);
	FillInAddressStorageAttribute = New Structure("Date", Object.Date);
	
	StructureOfActions = New Structure();
	StructureOfActions.Insert("FillInSpaceUsageAttribute", FillInSpaceUsageAttribute);
	StructureOfActions.Insert("FillInAddressStorageAttribute", FillInAddressStorageAttribute);
	StructureOfActions.Insert("CheckSeriesCalculateStatus", CheckSeriesCalculateStatus);
	BatchProcessingOfTablePartClient.ProcessTSString(TableRow, StructureOfActions, CachedValues);
	ClearPackagingForStringsWithoutAddressStorageInString(TableRow);
	
	MethodParameters = New Structure();
	MethodParameters.Insert("ControlledLotReference", Object.ControlledLotReference);
	MethodParameters.Insert("Warehouse", TableRow.Warehouse);
	MethodParameters.Insert("Date", Object.Date);
	ChoiceData = ActionSelectionData(MethodParameters);
	If ChoiceData.FindByValue(TableRow.Action) = Undefined Then
		TableRow.Action = PredefinedValue("Enum.ActionsOnGoodsInQualityControlCertificate.EmptyRef");
	EndIf;
	
EndProcedure

&AtClient
Procedure GoodsPremiseOnChange(Item)
	
	TableRow = Items.Goods.CurrentData;
	
	FillInAddressStorageAttribute = New Structure("Date", Object.Date);
	
	StructureOfActions = New Structure();
	StructureOfActions.Insert("FillInAddressStorageAttribute", FillInAddressStorageAttribute);
	BatchProcessingOfTablePartClient.ProcessTSString(TableRow, StructureOfActions, CachedValues);
	ClearPackagingForStringsWithoutAddressStorageInString(TableRow);
	
EndProcedure

&AtClient
Procedure GoodsPackagingReceiptOnChange(Item)
	
	TableRow = Items.Goods.CurrentData;
	RecalculateNumberOfEntries(TableRow);
	
EndProcedure

&AtClient
Procedure GoodsProductsRecordingAsReceivedOnChange(Item)
	
	TableRow = Items.Goods.CurrentData;
	FillInServiceDetailsOfProductItemRegistration(TableRow);
	
EndProcedure

&AtClient
Procedure GoodsProductsRecordingAsReceivedStartChoice(Item, ChoiceData, ChoiceByAdding, StandardProcessing)
	
	StandardProcessing = False;
	
	CurrentData = Items.Goods.CurrentData;
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("CheckCharacteristicsByOwner", CurrentData.Characteristic);
	StructureOfActions.Insert("CheckFillPackageByOwner", CurrentData.Package);
	StructureOfActions.Insert("FillInArticleAttribute", New Structure("Products, ProductsOfOriginalQuality", "SKU", "SKURegistration"));
	
	If ValueIsFilled(CurrentData.Characteristic) Then
		StructureOfActions.Insert("FillInDescriptionOfPoorQualityProduct", CurrentData.Characteristic);
	EndIf;
	
	If ValueIsFilled(CurrentData.Package) Then
		StructureOfActions.Insert("FillInPackagingOfLowQualityGoods", CurrentData.Package);
	EndIf;
	
	Notification = New CallbackDescription("GoodsProductsRecordingAsReceivedStartChoiceCompletion", ThisObject);
	
	WarehousesClient.ChangeQuality(CurrentData, StructureOfActions, CachedValues, Notification);
	
EndProcedure

&AtClient
Procedure GoodsSelection(Item, RowSelected, Field, StandardProcessing)
	
	CurrentData = Items.Goods.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	If Field = Items.GoodsResearchProject Then
		If ValueIsFilled(CurrentData.ResearchProject) And Not CurrentData.SeveralStudies Then
			FormParameters = New Structure("Key", CurrentData.ResearchProject);
			OpenForm("Document.GoodsQualityResearch.Form.DocumentForm",FormParameters,ThisObject)
		ElsIf CurrentData.SeveralStudies Then
			ListOfStudies = TableOfSelectedRowsInArrayOfStructures(CurrentData.RowID, "ResearchProject,ClosingStatement,Control");
			FormParameters = New Structure("ListOfStudies", ListOfStudies);
			OpenForm("Document.GoodsQualityResearch.Form.QualityResearchResults",FormParameters,ThisObject)
		EndIf;
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

#Region AttachableCommands

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

// StandardSubsystems.Properties
&AtClient
Procedure Attachable_PropertiesExecuteCommand(ItemOrCommand, Var_URL = Undefined, StandardProcessing = Undefined)
	PropertyManagerClient.ExecuteCommand(ThisObject, ItemOrCommand, StandardProcessing);
EndProcedure
// End StandardSubsystems.Properties

#EndRegion

&AtClient
Procedure WriteDocument(Command)
	
	TMCommonUseClient.Write(ThisObject);
	
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
Procedure CopyRows(Command)
	
	If ProcessingOfTabularFormsClient.SelectedLineToExecuteCommand(Items.Goods) Then
		SelectedRows = Items.Goods.SelectedRows;
		CopyLinesOnServer(SelectedRows);
		ProcessingOfTabularFormsClient.NotifyUserAboutCopyingStrings(SelectedRows.Count());
	EndIf;
	
EndProcedure

&AtClient
Procedure InsertRows(Command)
	
	ClearMessages();
	NumberOfProductsBeforeInsertion = Object.Goods.Count();
	
	GetLinesFromClipboard();
	
	NumberOfInserted = Object.Goods.Count() - NumberOfProductsBeforeInsertion;
	ProcessingOfTabularFormsClient.NotifyUserAboutInsertingRows(NumberOfInserted);

EndProcedure

&AtClient
Procedure SplitRow(Command)
	
	FormTable  = Items.Goods;
	TableData = Object.Goods;
	
	Notification = New CallbackDescription("SplitRowCompletion", ThisObject);
	ProcessingOfTabularFormsClient.SplitRow(TableData, FormTable, Notification);
	
EndProcedure

&AtClient
Procedure SearchByBarcode(Command)
	
	ClearMessages();
	Notification = New CallbackDescription("GoodsSearchByBarcodeCompletion", ThisObject);
	BarcodingOfItemsClient.ShowBarcodeInput(Notification);
	
EndProcedure

&AtClient
Procedure SelectGoods(Command)
	
	FormParameters = New Structure;
	FormParameters.Insert("Warehouse", Object.Warehouse);
	FormParameters.Insert("SelectionModeWithoutAmountParameters", True);
	FormParameters.Insert("HideTheViewPriceColumn", True);
	FormParameters.Insert("HideTheItemPricesCommand", True);
	FormParameters.Insert("Title", NStr("vi = 'Chọn hàng hóa';
										|ru = 'Подбор товаров';
										|en = 'Pick goods'; fa = 'انتخاب کالاها';
										|it = 'Selezione delle merci';
										|pl = 'Wybór towarów';
										|tr = 'Ürünlerin seçimi'"));
	FormParameters.Insert("Date", Object.Date);
	FormParameters.Insert("Document", Object.Ref);
	FormParameters.Insert("SeriesSpecificationParameters", SeriesSpecificationParameters);
	FormParameters.Insert("FilterByProductType", 
		New FixedArray(ProductsClientServer.SelectionByProductMultiTurnContainer(False)));
	
	OpenForm("DataProcessor.SelectGoodsToSalesDocument.Form", FormParameters, ThisObject, UUID);
	
EndProcedure

&AtClient
Procedure FillInByBalance(Command)
	
	If Not ValueIsFilled(Object.ControlledLotReference) Then
		Text = NStr("vi = 'Không thực hiện việc điền. Để điền theo tồn kho, vui lòng chỉ định lô hàng được kiểm soát.';
					|ru = 'Заполнение не выполнено. Для заполнения по остаткам укажите контролируемую партию.';
					|en = 'The filling is not performed. To fill in by balance, specify the controlled lot.'; fa = 'The filling is not performed. To fill in by balance, specify the controlled lot.';
					|it = 'The filling is not performed. To fill in by balance, specify the controlled lot.';
					|pl = 'The filling is not performed. To fill in by balance, specify the controlled lot.';
					|tr = 'Doldurma gerçekleştirilmedi. Stoklara göre doldurmak için kontrole tabi lotu belirtin.'");
		ShowMessageBox(, Text);
		Return;
	EndIf;
	
	Address = AddressOfSchemeSettingUpFillingByBatchBalance;
	Settings = FillingSettingsForBatchBalances;
	
	FormParameters = New Structure();
	FormParameters.Insert("SchemaURL", Address);
	If ValueIsFilled(Object.Warehouse) Then
		For Each FilterElement In Settings.Settings.Filter.Items Do
			If FilterElement.LeftValue = New DataCompositionField("Warehouse") Then
				FoundItem = Settings.UserSettings.Items.Find(
					FilterElement.UserSettingID);
				FoundItem.RightValue = Object.Warehouse;
				FoundItem.ComparisonType = DataCompositionComparisonType.Equal;
				FoundItem.Use = True;
			EndIf;
		EndDo;
	EndIf;
	
	If ValueIsFilled(Object.Premise) Then
		For Each FilterElement In Settings.Settings.Filter.Items Do
			If FilterElement.LeftValue = New DataCompositionField("Premise") Then
				FoundItem = Settings.UserSettings.Items.Find(
					FilterElement.UserSettingID);
				FoundItem.RightValue = Object.Premise;
				FoundItem.ComparisonType = DataCompositionComparisonType.Equal;
			EndIf;
		EndDo;
	EndIf;
	FormParameters.Insert("ListSettings", Settings);
	FormParameters.Insert("Title", NStr("vi = 'Điền theo tồn kho của hàng hóa bị khóa';
										|ru = 'Заполнение по остаткам заблокированных товаров';
										|en = 'Fill in by locked goods balance'; fa = 'Fill in by locked goods balance';
										|it = 'Fill in by locked goods balance';
										|pl = 'Fill in by locked goods balance';
										|tr = 'Kilitli ürünlerin stoklarına göre doldurma'"));
	FormParameters.Insert("TitleOfFinishEditingButton", NStr("vi = 'Điền';
															|ru = 'Заполнить';
															|en = 'Fill'; fa = 'پرکردن';
															|it = 'Fill';
															|pl = 'Fill';
															|tr = 'Doldur'"));
	CallbackDescription = New CallbackDescription("SettingUpFillingByBalanceEnd", ThisObject);
	OpenForm("Report.ListSettings.Form.ListSettings", FormParameters, , , , , CallbackDescription);
	
EndProcedure

&AtClient
Procedure FillInUnlockAction(Command)
	
	If Not ThereAreLinesToExecuteCommand(NStr("vi = '""Thao tác""';
												|ru = '""Действие""';
												|en = '""Action""'; fa = '""Action""';
												|it = '""Action""';
												|pl = '""Action""';
												|tr = '""Eylem""'")) Then
		Return;
	EndIf;
	
	ClearMessages();
	ProcessedRows_ = FillInActionColumn(
		PredefinedValue("Enum.ActionsOnGoodsInQualityControlCertificate.Unlock"));
	ShowUserNotification(NStr("vi = 'Điền thao tác';
								|ru = 'Заполнение действия';
								|en = 'Action population'; fa = 'Action population';
								|it = 'Compilazione dell''azione';
								|pl = 'Wypełnienie działania';
								|tr = 'İşlem doldurma'"), ,
		StrTemplate(NStr("vi = 'Đã xử lý dòng: %1';
						|ru = 'Обработано строк: %1';
						|en = 'Processed lines: %1'; fa = 'Processed lines: %1';
						|it = 'Elaborate righe: %1';
						|pl = 'Przetworzono wierszy: %1';
						|tr = 'İşlenen satır: %1'"), ProcessedRows_));
	
EndProcedure

&AtClient
Procedure FillInActionToIssueDamage(Command)
	
	If Not ThereAreLinesToExecuteCommand(NStr("vi = '""Thao tác""';
												|ru = '""Действие""';
												|en = '""Action""'; fa = '""Action""';
												|it = '""Action""';
												|pl = '""Action""';
												|tr = '""Eylem""'")) Then
		Return;
	EndIf;
	
	ClearMessages();
	ProcessedRows_ = FillInActionColumn(
		PredefinedValue("Enum.ActionsOnGoodsInQualityControlCertificate.RegisterStockQualityChange"));
	ShowUserNotification(NStr("vi = 'Điền thao tác';
								|ru = 'Заполнение действия';
								|en = 'Action population'; fa = 'Action population';
								|it = 'Compilazione dell''azione';
								|pl = 'Wypełnienie działania';
								|tr = 'İşlem doldurma'"), ,
		StrTemplate(NStr("vi = 'Đã xử lý dòng: %1';
						|ru = 'Обработано строк: %1';
						|en = 'Processed lines: %1'; fa = 'Processed lines: %1';
						|it = 'Elaborate righe: %1';
						|pl = 'Przetworzono wierszy: %1';
						|tr = 'İşlenen satır: %1'"), ProcessedRows_));
	
EndProcedure

&AtClient
Procedure FillInReturnAction(Command)
	
	If Not ThereAreLinesToExecuteCommand(NStr("vi = '""Thao tác""';
												|ru = '""Действие""';
												|en = '""Action""'; fa = '""Action""';
												|it = '""Action""';
												|pl = '""Action""';
												|tr = '""Eylem""'")) Then
		Return;
	EndIf;
	
	ClearMessages();
	ProcessedRows_ = FillInActionColumn(
		PredefinedValue("Enum.ActionsOnGoodsInQualityControlCertificate.RegisterReturn"));
	ShowUserNotification(NStr("vi = 'Điền thao tác';
								|ru = 'Заполнение действия';
								|en = 'Action population'; fa = 'Action population';
								|it = 'Compilazione dell''azione';
								|pl = 'Wypełnienie działania';
								|tr = 'İşlem doldurma'"), ,
		StrTemplate(NStr("vi = 'Đã xử lý dòng: %1';
						|ru = 'Обработано строк: %1';
						|en = 'Processed lines: %1'; fa = 'Processed lines: %1';
						|it = 'Elaborate righe: %1';
						|pl = 'Przetworzono wierszy: %1';
						|tr = 'İşlenen satır: %1'"), ProcessedRows_));
	
EndProcedure

&AtClient
Procedure FillInFormalizeMoveAction(Command)
	
	If Not ThereAreLinesToExecuteCommand(NStr("vi = '""Thao tác""';
												|ru = '""Действие""';
												|en = '""Action""'; fa = '""Action""';
												|it = '""Action""';
												|pl = '""Action""';
												|tr = '""Eylem""'")) Then
		Return;
	EndIf;
	
	ClearMessages();
	ProcessedRows_ = FillInActionColumn(
		PredefinedValue("Enum.ActionsOnGoodsInQualityControlCertificate.RegisterGoodsTransfer"));
	ShowUserNotification(NStr("vi = 'Điền thao tác';
								|ru = 'Заполнение действия';
								|en = 'Action population'; fa = 'Action population';
								|it = 'Compilazione dell''azione';
								|pl = 'Wypełnienie działania';
								|tr = 'İşlem doldurma'"), ,
		StrTemplate(NStr("vi = 'Đã xử lý dòng: %1';
						|ru = 'Обработано строк: %1';
						|en = 'Processed lines: %1'; fa = 'Processed lines: %1';
						|it = 'Elaborate righe: %1';
						|pl = 'Przetworzono wierszy: %1';
						|tr = 'İşlenen satır: %1'"), ProcessedRows_));
	
EndProcedure

&AtClient
Procedure FillInWriteOffAction(Command)
	
	If Not ThereAreLinesToExecuteCommand(NStr("vi = '""Thao tác""';
												|ru = '""Действие""';
												|en = '""Action""'; fa = '""Action""';
												|it = '""Action""';
												|pl = '""Action""';
												|tr = '""Eylem""'")) Then
		Return;
	EndIf;
	
	ClearMessages();
	ProcessedRows_ = FillInActionColumn(
		PredefinedValue("Enum.ActionsOnGoodsInQualityControlCertificate.MakeDebit"));
	ShowUserNotification(NStr("vi = 'Điền thao tác';
								|ru = 'Заполнение действия';
								|en = 'Action population'; fa = 'Action population';
								|it = 'Compilazione dell''azione';
								|pl = 'Wypełnienie działania';
								|tr = 'İşlem doldurma'"), ,
		StrTemplate(NStr("vi = 'Đã xử lý dòng: %1';
						|ru = 'Обработано строк: %1';
						|en = 'Processed lines: %1'; fa = 'Processed lines: %1';
						|it = 'Elaborate righe: %1';
						|pl = 'Przetworzono wierszy: %1';
						|tr = 'İşlenen satır: %1'"), ProcessedRows_));
	
EndProcedure

&AtClient
Procedure FillInChangeQualityAction(Command)
	
	If Not ThereAreLinesToExecuteCommand(NStr("vi = '""Thao tác""';
												|ru = '""Действие""';
												|en = '""Action""'; fa = '""Action""';
												|it = '""Action""';
												|pl = '""Action""';
												|tr = '""Eylem""'")) Then
		Return;
	EndIf;
	
	ClearMessages();
	ProcessedRows_ = FillInActionColumn(
		PredefinedValue("Enum.ActionsOnGoodsInQualityControlCertificate.ChangeQuality"));
	ShowUserNotification(NStr("vi = 'Điền thao tác';
								|ru = 'Заполнение действия';
								|en = 'Action population'; fa = 'Action population';
								|it = 'Compilazione dell''azione';
								|pl = 'Wypełnienie działania';
								|tr = 'İşlem doldurma'"), ,
		StrTemplate(NStr("vi = 'Đã xử lý dòng: %1';
						|ru = 'Обработано строк: %1';
						|en = 'Processed lines: %1'; fa = 'Processed lines: %1';
						|it = 'Elaborate righe: %1';
						|pl = 'Przetworzono wierszy: %1';
						|tr = 'İşlenen satır: %1'"), ProcessedRows_));
	
EndProcedure

&AtClient
Procedure FillInActionReturnToSupplier(Command)
	
	If Not ThereAreLinesToExecuteCommand(NStr("vi = '""Thao tác""';
												|ru = '""Действие""';
												|en = '""Action""'; fa = '""Action""';
												|it = '""Action""';
												|pl = '""Action""';
												|tr = '""Eylem""'")) Then
		Return;
	EndIf;
	
	ClearMessages();
	ProcessedRows_ = FillInActionColumn(
		PredefinedValue("Enum.ActionsOnGoodsInQualityControlCertificate.ToReturnToVendor"));
	ShowUserNotification(NStr("vi = 'Điền thao tác';
								|ru = 'Заполнение действия';
								|en = 'Action population'; fa = 'Action population';
								|it = 'Compilazione dell''azione';
								|pl = 'Wypełnienie działania';
								|tr = 'İşlem doldurma'"), ,
		StrTemplate(NStr("vi = 'Đã xử lý dòng: %1';
						|ru = 'Обработано строк: %1';
						|en = 'Processed lines: %1'; fa = 'Processed lines: %1';
						|it = 'Elaborate righe: %1';
						|pl = 'Przetworzono wierszy: %1';
						|tr = 'İşlenen satır: %1'"), ProcessedRows_));
	
EndProcedure

&AtClient
Procedure FillInDoNotReceiveGoodsAction(Command)
	
	If Not ThereAreLinesToExecuteCommand(NStr("vi = '""Thao tác""';
												|ru = '""Действие""';
												|en = '""Action""'; fa = '""Action""';
												|it = '""Action""';
												|pl = '""Action""';
												|tr = '""Eylem""'")) Then
		Return;
	EndIf;
	
	ClearMessages();
	ProcessedRows_ = FillInActionColumn(
		PredefinedValue("Enum.ActionsOnGoodsInQualityControlCertificate.DoNotReceiveGoods"));
	ShowUserNotification(NStr("vi = 'Điền thao tác';
								|ru = 'Заполнение действия';
								|en = 'Action population'; fa = 'Action population';
								|it = 'Compilazione dell''azione';
								|pl = 'Wypełnienie działania';
								|tr = 'İşlem doldurma'"), ,
		StrTemplate(NStr("vi = 'Đã xử lý dòng: %1';
						|ru = 'Обработано строк: %1';
						|en = 'Processed lines: %1'; fa = 'Processed lines: %1';
						|it = 'Elaborate righe: %1';
						|pl = 'Przetworzono wierszy: %1';
						|tr = 'İşlenen satır: %1'"), ProcessedRows_));
	
EndProcedure

&AtClient
Procedure FillInQualityControlResult(Command)
	
	If Not ThereAreLinesToExecuteCommand(NStr("vi = '""Kết quả kiểm tra chất lượng""';
												|ru = '""Результат проверки качества""';
												|en = '""Quality check result""'; fa = '""Quality check result""';
												|it = '""Quality check result""';
												|pl = '""Quality check result""';
												|tr = '""Kalite kontrol sonucu""'")) Then
		Return;
	EndIf;
	
	CallbackDescription = New CallbackDescription(
		"FillInQualityControlResultAfterSelection",
		ThisObject);
	
	OpenForm(
		"Enum.GoodsQualityCheckResults.ChoiceForm",
		,
		ThisObject,
		,
		,
		,
		CallbackDescription,
		FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure ImportDataFromPDT(Command)
	
	ClearMessages();
	
	PeripheralsPortableDataTerminalsServerClient.StartDownloadingDataFromTSD(
		New CallbackDescription("DownloadFromTSDCompletion", ThisObject),
		UUID);
		
EndProcedure

&AtClient
Procedure RegisterDiscrepancyCertificate(Command)
	
	AskQuestionAndIssueDocument(KeyIsToIssueDiscrepancyReport(), Items.RegisterDiscrepancyCertificate.Title);
	
EndProcedure

&AtClient
Procedure RegisterReturn(Command)
	
	AskQuestionAndIssueDocument(KeyIsToIssueReturn(), Items.RegisterReturn.Title);
	
EndProcedure

&AtClient
Procedure RegisterGoodsTransfer(Command)
	
	AskQuestionAndIssueDocument(KeyToMakeMove(), Items.RegisterGoodsTransfer.Title);
	
EndProcedure

&AtClient
Procedure RegisterStockQualityChange(Command)
	
	AskQuestionAndIssueDocument(KeyIsToArrangeDamage(), Items.RegisterStockQualityChange.Title);
	
EndProcedure

&AtClient
Procedure MakeDebit(Command)
	
	AskQuestionAndIssueDocument(KeyToIssueWriteOff(), Items.MakeDebit.Title);
	
EndProcedure

#EndRegion

#Region Private

#Region GenerateFrom

&AtClient
Procedure AskQuestionAndIssueDocument(CommandKey, CommandName)
	
	If Object.Status = PredefinedValue("Enum.StatusesOfQualityControlCertificates.InProgress") Then
		
		ErrorText = StrTemplate(NStr("vi = 'Để thực hiện lệnh ""%1"", cần phải đặt trạng thái ""%2"" hoặc ""%3"".';
									|ru = 'Для выполнения команды ""%1"" необходимо установить статус ""%2"" или ""%3"".';
									|en = 'To run the ""%1"" command, set the ""%2"" or ""%3"" status.'; fa = 'To run the ""%1"" command, set the ""%2"" or ""%3"" status.';
									|it = 'To run the ""%1"" command, set the ""%2"" or ""%3"" status.';
									|pl = 'To run the ""%1"" command, set the ""%2"" or ""%3"" status.';
									|tr = '""%1"" komutunu gerçekleştirmek için durumun ""%2"" veya ""%3"" olarak ayarlanması gerekir.'"),
			CommandName,
			String(PredefinedValue("Enum.StatusesOfQualityControlCertificates.AwaitingDecision")),
			String(PredefinedValue("Enum.StatusesOfQualityControlCertificates.IsProcessed")));
		ShowMessageBox(, ErrorText);
		
	ElsIf Not Object.Posted Or Modified Then
		AdditionalParameters = New Structure();
		AdditionalParameters.Insert("CommandKey", CommandKey);
		
		QueryText =  StrTemplate(NStr("vi = 'Để thực hiện lệnh ""%1"", chứng từ sẽ được kết chuyển. Tiếp tục?';
										|ru = 'Для выполнения команды ""%1"" документ будет проведен. Продолжить?';
										|en = 'The document will be posted in order to run the ""%1"" command. Continue?'; fa = 'The document will be posted in order to run the ""%1"" command. Continue?';
										|it = 'The document will be posted in order to run the ""%1"" command. Continue?';
										|pl = 'The document will be posted in order to run the ""%1"" command. Continue?';
										|tr = '""%1"" komutunu gerçekleştirmek için belge işlenecek. Devam edilsin mi?'"), CommandName);
		ShowQueryBox(
			New CallbackDescription("AnswerAboutNeedForConductingHasBeenReceived", ThisObject, AdditionalParameters), 
				QueryText, QuestionDialogMode.YesNo);
	Else
		
		IssueDocument(CommandKey);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure AnswerAboutNeedForConductingHasBeenReceived(QuestionResult, AdditionalParameters) Export
	
	Response = QuestionResult;
	If Response = DialogReturnCode.No Then
		Return;
	Else
		ClearMessages();
		WriteParameters = New Structure("WriteMode", DocumentWriteMode.Posting);
		WriteParameters.Insert("CommandKey", AdditionalParameters.CommandKey);
		Write(WriteParameters);
	EndIf;
	
EndProcedure

&AtClient
Procedure IssueDocument(CommandKey)
	
	ExecutionParameters = AttachableCommandsClient.CommandExecuteParameters();
	ExecutionParameters.CommandDetails = New Structure("MultipleChoice", False);
	ExecutionParameters.ReferencesArrray = CommonClientServer.ValueInArray(Object.Ref);
	ExecutionParameters.Form = ThisObject;
	
	If CommandKey = KeyToMakeMove() Then
		GenerationByReferenceTMClient.CreateMovementOfGoodsBasedOnGroupOfWarehouses(Object.Ref, ExecutionParameters);
	ElsIf CommandKey = KeyToIssueWriteOff() Then
		GenerationByReferenceTMClient.CreateStockShortagesRecognitionBasedOnGroupOfWarehouses(Object.Ref, ExecutionParameters);
	ElsIf CommandKey = KeyIsToArrangeDamage() Then
		GenerationByReferenceTMClient.CreateDamageToGoodsBasedOnGroupOfWarehouses(Object.Ref, ExecutionParameters);
	ElsIf CommandKey = KeyIsToIssueReturn() Then
		If ReturnOfGoodsToSupplierIsAvailable(Object.LotBusinessTransaction) Then
			GenerationByReferenceTMClient.CreateReturnOfGoodsToSupplierBasedOnWarehouseGroup(Object.Ref, ExecutionParameters);
		ElsIf RegistrationOfShipmentOfGoodsFromStorageIsAvailable(Object.LotBusinessTransaction) Then
			GenerationByReferenceTMClient.CreateShipmentOfGoodsFromStorageBasedOnGroupOfWarehouses(Object.Ref, ExecutionParameters);
		Else
			Text = StrTemplate(
				NStr("vi = 'Đối với nghiệp vụ ""%1"" mà theo đó đã nhập hàng, không đề xuất tạo trả hàng. Việc nhập trên cơ sở chứng từ bị cấm.';
					|ru = 'Для операции ""%1"", по которой поступил товар, не предполагается создание возврата товаров. Ввод на основании документа запрещен.';
					|en = 'Cannot create a goods return based on the ""%1"" transaction, under which the goods were received. Generation based on the document is not allowed.'; fa = 'Cannot create a goods return based on the ""%1"" transaction, under which the goods were received. Generation based on the document is not allowed.';
					|it = 'Cannot create a goods return based on the ""%1"" transaction, under which the goods were received. Generation based on the document is not allowed.';
					|pl = 'Cannot create a goods return based on the ""%1"" transaction, under which the goods were received. Generation based on the document is not allowed.';
					|tr = 'Ürünün girişinin yapıldığı ""%1"" eylemi için ürün iadesi oluşturulması öngörülmemiştir. Belgeye dayanarak giriş yapılması yasaktır.'"),
				Object.LotBusinessTransaction);
			ShowMessageBox(, Text);
		EndIf;
	ElsIf CommandKey = KeyIsToIssueDiscrepancyReport() Then
		
		If DrawUpActOfAcquisition Then
			
			If UseNonConformanceCertificatesFollowingAcceptance Then
				
				OpenForm(
					"Document.DiscrepancyReportFollowingReceipt.Form.DocumentForm",
					New Structure("Basis", Object.Ref),
					ThisObject,
					True);
					
			Else
				Text = NStr("vi = 'Chức năng sử dụng biên bản về sai lệch sau khi nhập hàng từ nhà cung cấp / khách hàng đã bị tắt, vui lòng liên hệ với quản trị viên.';
							|ru = 'Функциональная возможность использования актов о расхождениях после приемки от поставщика / клиента отключена, обратитесь к администратору.';
							|en = 'Receipt discrepancy reports from vendor or customer are disabled, contact the administrator.'; fa = 'Receipt discrepancy reports from vendor or customer are disabled, contact the administrator.';
							|it = 'Receipt discrepancy reports from vendor or customer are disabled, contact the administrator.';
							|pl = 'Receipt discrepancy reports from vendor or customer are disabled, contact the administrator.';
							|tr = 'Tedarikçiden/müşteriden teslim alma sonrası tutarsızlık tutanağı kullanma işlevi devre dışı, yöneticiye başvurun.'");
				ShowMessageBox(, Text);
			EndIf;
			
		ElsIf DrawUpRecyclingReportOnSide Then
			
			If UseDiscrepancyReportFollowingReceiptFromSubcontractor2_5 Then
				
				OpenForm(
					"Document.DiscrepancyReportFollowingReceipt.Form.DocumentForm",
					New Structure("Basis", Object.Ref),
					ThisObject,
					True);
					
			Else
				Text = NStr("vi = 'Chức năng sử dụng biên bản về sai lệch sau khi nhập hàng / trả hàng từ bên gia công đã bị tắt, vui lòng liên hệ với quản trị viên.';
							|ru = 'Функциональная возможность использования актов о расхождениях после приемки/возврата от переработчика отключена, обратитесь к администратору.';
							|en = 'Receipt discrepancy reports from the subcontractor and discrepancy reports following ""Goods return — Subcontracting services received"" are disabled, contact the administrator.'; fa = 'Receipt discrepancy reports from the subcontractor and discrepancy reports following ""Goods return — Subcontracting services received"" are disabled, contact the administrator.';
							|it = 'Receipt discrepancy reports from the subcontractor and discrepancy reports following ""Goods return — Subcontracting services received"" are disabled, contact the administrator.';
							|pl = 'Receipt discrepancy reports from the subcontractor and discrepancy reports following ""Goods return — Subcontracting services received"" are disabled, contact the administrator.';
							|tr = 'Fason üreticiden teslim alma/iade sonrası Tutarsızlık Tutanağı kullanma işlevi devre dışı, yöneticiye başvurun.'");
				ShowMessageBox(, Text);
			EndIf;
			
		ElsIf ToDrawUpActOnProcessingOfTollFreeRawMaterials Then
			
			If UseCertificatesOfDiscrepanciesAfterAcceptanceForAcceptanceOfGiverSGoods2_5 Then
				
				OpenForm(
					"Document.DiscrepancyReportFollowingReceipt.Form.DocumentForm",
					New Structure("Basis", Object.Ref),
					ThisObject,
					True);
					
			Else
				Text = NStr("vi = 'Chức năng sử dụng biên bản về sai lệch sau khi nhập hàng từ bên giao gia công đã bị tắt, vui lòng liên hệ với quản trị viên.';
							|ru = 'Функциональная возможность использования актов о расхождениях после приемки от давальца отключена, обратитесь к администратору.';
							|en = 'Discrepancy reports following receipt from provider are disabled, contact the administrator.'; fa = 'Discrepancy reports following receipt from provider are disabled, contact the administrator.';
							|it = 'Discrepancy reports following receipt from provider are disabled, contact the administrator.';
							|pl = 'Discrepancy reports following receipt from provider are disabled, contact the administrator.';
							|tr = 'Sağlayacıdan teslim alma sonrası Tutarsızlık Tutanağı kullanma işlevi devre dışı, yöneticiye başvurun. '");
				ShowMessageBox(, Text);
			EndIf;
			
			ElsIf DrawUpTransferCertificate Then
			
			If UseNonConformanceCertificatesFollowingTransfer Then
				
				OpenForm(
					"Document.DiscrepancyReportFollowingTransfer.Form.DocumentForm",
					New Structure("Basis", Object.Ref),
					ThisObject,
					True);
					
			Else
				
				Text = NStr("vi = 'Chức năng sử dụng biên bản về sai lệch sau khi điều chuyển đã bị tắt, vui lòng liên hệ với quản trị viên.';
							|ru = 'Функциональная возможность использования актов о расхождениях после перемещения отключена, обратитесь к администратору.';
							|en = 'Stock transfer discrepancy reports are disabled, contact the administrator.'; fa = 'Stock transfer discrepancy reports are disabled, contact the administrator.';
							|it = 'Stock transfer discrepancy reports are disabled, contact the administrator.';
							|pl = 'Stock transfer discrepancy reports are disabled, contact the administrator.';
							|tr = 'Transfer sonrası Tutarsızlık Tutanağı kullanma işlevi devre dışı, yöneticiye başvurun.'");
				ShowMessageBox(, Text);
				
			EndIf;
			
		ElsIf TypeOf(Lot) = Type("CatalogRef.CounterpartyContracts") Then
			
			Text = NStr("vi = 'Không hỗ trợ tạo Biên bản chênh lệch, khi việc nhập hàng vào kho được thực hiện theo hợp đồng. Việc nhập trên cơ sở chứng từ bị cấm.';
						|ru = 'Создание Акта о расхождениях, когда приемка товаров на склад осуществлялась по договорам, не поддерживается. Ввод на основании документа запрещен.';
						|en = 'Cannot create a discrepancy report when the goods were received to the warehouse under contracts. Generation from such base documents is not allowed.'; fa = 'Cannot create a discrepancy report when the goods were received to the warehouse under contracts. Generation from such base documents is not allowed.';
						|it = 'Cannot create a discrepancy report when the goods were received to the warehouse under contracts. Generation from such base documents is not allowed.';
						|pl = 'Cannot create a discrepancy report when the goods were received to the warehouse under contracts. Generation from such base documents is not allowed.';
						|tr = 'Ürünlerin ambara kabulünün sözleşmelere göre yapıldığı durumlarda Tutarsızlık Tutanağı oluşturulması desteklenmez. Belgeye dayanarak giriş yapılması yasaktır.'");
			ShowMessageBox(, Text);
			
		ElsIf TypeOf(Lot) = Type("CatalogRef.TermsOfPurchaseFromVendors") Then
			
			Text = NStr("vi = 'Không hỗ trợ tạo Biên bản chênh lệch, khi việc nhập hàng vào kho được thực hiện theo thỏa thuận. Việc nhập trên cơ sở chứng từ bị cấm.';
						|ru = 'Создание Акта о расхождениях, когда приемка товаров на склад осуществлялась по соглашениям, не поддерживается. Ввод на основании документа запрещен.';
						|en = 'Cannot create a discrepancy report when the goods were received to the warehouse under agreements. Generation from such base documents is not allowed.'; fa = 'Cannot create a discrepancy report when the goods were received to the warehouse under agreements. Generation from such base documents is not allowed.';
						|it = 'Cannot create a discrepancy report when the goods were received to the warehouse under agreements. Generation from such base documents is not allowed.';
						|pl = 'Cannot create a discrepancy report when the goods were received to the warehouse under agreements. Generation from such base documents is not allowed.';
						|tr = 'Ürünlerin ambara kabulünün anlaşmalara göre yapıldığı durumlarda Tutarsızlık Tutanağı oluşturulması desteklenmez. Belgeye dayanarak giriş yapılması yasaktır.'");
			ShowMessageBox(, Text);
			
		ElsIf TypeOf(Lot) = Type("DocumentRef.RequestForGoodsQualityControl") Then
			
			Text = NStr("vi = 'Không hỗ trợ tạo Biên bản chênh lệch, khi kiểm soát chất lượng theo yêu cầu kiểm soát. Việc nhập trên cơ sở chứng từ bị cấm.';
						|ru = 'Создание Акта о расхождениях, при контроле качества по заявкам на контроль, не поддерживается. Ввод на основании документа запрещен.';
						|en = 'Cannot create a discrepancy report if the quality control was performed under control requests. Generation from such base documents is not allowed.'; fa = 'Cannot create a discrepancy report if the quality control was performed under control requests. Generation from such base documents is not allowed.';
						|it = 'Cannot create a discrepancy report if the quality control was performed under control requests. Generation from such base documents is not allowed.';
						|pl = 'Cannot create a discrepancy report if the quality control was performed under control requests. Generation from such base documents is not allowed.';
						|tr = 'Kalite kontrol taleplerine göre kalite kontrol yapılırken Tutarsızlık Tutanağı oluşturulması desteklenmez. Belgeye dayanarak giriş yapılması yasaktır.'");
			ShowMessageBox(, Text);
			
		ElsIf TypeOf(Lot) = Type("DocumentRef.PurchaseOrder")
					Or TypeOf(Lot) = Type("DocumentRef.SalesOrder")
					Or TypeOf(Lot) = Type("DocumentRef.RequestForReturnOfGoodsFromCustomer")
					Or TypeOf(Lot) = Type("DocumentRef.MaterialProviderOrder2_5")
					Or TypeOf(Lot) = Type("DocumentRef.SubcontractOrder2_5")
					Or TypeOf(Lot) = Type("DocumentRef.TransferOrder") Then
			
			Text = NStr("vi = 'Không hỗ trợ tạo Biên bản chênh lệch, khi việc nhập hàng vào kho được thực hiện theo đơn hàng. Việc nhập trên cơ sở chứng từ bị cấm.';
						|ru = 'Создание Акта о расхождениях, когда приемка товаров на склад осуществлялась по заказам, не поддерживается. Ввод на основании документа запрещен.';
						|en = 'Cannot create a discrepancy report when the goods were received to the warehouse under orders. Generation from such base documents is not allowed.'; fa = 'Cannot create a discrepancy report when the goods were received to the warehouse under orders. Generation from such base documents is not allowed.';
						|it = 'Cannot create a discrepancy report when the goods were received to the warehouse under orders. Generation from such base documents is not allowed.';
						|pl = 'Cannot create a discrepancy report when the goods were received to the warehouse under orders. Generation from such base documents is not allowed.';
						|tr = 'Ürünlerin ambara kabulünün siparişlere göre yapıldığı durumlarda Tutarsızlık Tutanağı oluşturulması desteklenmez. Belgeye dayanarak giriş yapılması yasaktır.'");
			ShowMessageBox(, Text);
			
		ElsIf TypeOf(Lot) = Type("DocumentRef.ReceiptOfGoodsToWarehouse") Then
			
			Text = NStr("vi = 'Không hỗ trợ tạo Biên bản chênh lệch cho lô hàng kiểm soát liên quan đến chứng từ ""Tiếp nhận hàng vào kho"". Việc nhập trên cơ sở chứng từ bị cấm.';
						|ru = 'Создание Акта о расхождениях по контролируемой партии, связанной с документом ""Поступление товаров на склад"", не поддерживается. Ввод на основании документа запрещен.';
						|en = 'Cannot create a discrepancy report for a controlled lot related to the ""Warehouse receipt"" document. Generation from such base documents is not allowed.'; fa = 'Cannot create a discrepancy report for a controlled lot related to the ""Warehouse receipt"" document. Generation from such base documents is not allowed.';
						|it = 'Cannot create a discrepancy report for a controlled lot related to the ""Warehouse receipt"" document. Generation from such base documents is not allowed.';
						|pl = 'Cannot create a discrepancy report for a controlled lot related to the ""Warehouse receipt"" document. Generation from such base documents is not allowed.';
						|tr = '""Ürünlerin ambara girişi"" belgesiyle ilişkili kontrollü lot için Tutarsızlık Tutanağı oluşturulması desteklenmez. Belgeye dayanarak giriş yapılması yasaktır.'");
			ShowMessageBox(, Text);
			
		Else
			
			Text = StrTemplate(
				NStr("vi = 'Đối với nghiệp vụ ""%1"" mà theo đó đã nhập hàng, không đề xuất tạo Biên bản về sai lệch. Việc nhập trên cơ sở chứng từ bị cấm.';
					|ru = 'Для операции ""%1"", по которой поступил товар, не предполагается создание Акта о расхождениях. Ввод на основании документа запрещен.';
					|en = 'Cannot create a discrepancy report based on the ""%1"" transaction, under which the goods were received. Generation based on the document is not allowed.'; fa = 'Cannot create a discrepancy report based on the ""%1"" transaction, under which the goods were received. Generation based on the document is not allowed.';
					|it = 'Cannot create a discrepancy report based on the ""%1"" transaction, under which the goods were received. Generation based on the document is not allowed.';
					|pl = 'Cannot create a discrepancy report based on the ""%1"" transaction, under which the goods were received. Generation based on the document is not allowed.';
					|tr = 'Ürünün girişinin yapıldığı ""%1"" eylemi için Tutarsızlık Tutanağı oluşturulması öngörülmemiştir. Belgeye dayanarak giriş yapılması yasaktır.'"),
				Object.LotBusinessTransaction);
			ShowMessageBox(, Text);
			
		EndIf;
	EndIf;
	
EndProcedure

&AtServer
Procedure FillInDetailsOfFormDependentOnControlledLotReference()
	
	SetPrivilegedMode(True);
	Lot = Common.ObjectAttributeValue(Object.ControlledLotReference, "Lot");
	SetPrivilegedMode(False);
	
	DrawUpActOfAcquisition = TypeOf(Lot) = Type("DocumentRef.VendorInvoice")
		Or TypeOf(Lot) = Type("DocumentRef.ReturnOfGoodsFromCustomer")
		Or TypeOf(Lot) = Type("DocumentRef.ReceiptOfGoodsFromCustodian")
			And (Object.LotBusinessTransaction = PredefinedValue("Enum.BusinessTransactions.ReturnFromCustodian")
		Or Object.LotBusinessTransaction = PredefinedValue("Enum.BusinessTransactions.ReturnFromCommissionAgent"))
			Or TypeOf(Lot) = Type("DocumentRef.GoodsReceiptForStorage")
			And Object.LotBusinessTransaction = PredefinedValue("Enum.BusinessTransactions.ReceivingForStorageWithRightOfSale");
			
	DrawUpRecyclingReportOnSide = False;
	DrawUpRecyclingReportOnSide = TypeOf(Lot) = Type("DocumentRef.ReceiptOfGoodsFromCustodian")
			And (Object.LotBusinessTransaction = PredefinedValue("Enum.BusinessTransactions.ReturnFromProcessingCompany2_5")
		Or Object.LotBusinessTransaction = PredefinedValue("Enum.BusinessTransactions.ReceiptFromToller2_5"));
	ToDrawUpActOnProcessingOfTollFreeRawMaterials = False;
	ToDrawUpActOnProcessingOfTollFreeRawMaterials = TypeOf(Lot) = Type("DocumentRef.GoodsReceiptForStorage")
		And Object.LotBusinessTransaction = PredefinedValue("Enum.BusinessTransactions.ReceiptFromMaterialProvider2_5");
	DrawUpTransferCertificate = TypeOf(Lot) = Type("DocumentRef.InventoryTransfer");
	
EndProcedure

&AtClientAtServerNoContext
Function KeyToMakeMove()
	Return "RegisterGoodsTransfer";
EndFunction

&AtClientAtServerNoContext
Function KeyToIssueWriteOff()
	Return "MakeDebit";
EndFunction

&AtClientAtServerNoContext
Function KeyIsToArrangeDamage()
	Return "RegisterStockQualityChange";
EndFunction

&AtClientAtServerNoContext
Function KeyIsToIssueReturn()
	Return "RegisterReturn";
EndFunction

&AtClientAtServerNoContext
Function KeyIsToIssueDiscrepancyReport()
	Return "RegisterDiscrepancyCertificate";
EndFunction

#EndRegion

#Region VisibilityManagement

&AtServer
Procedure SetConditionalAppearance()
	
	ConditionalAppearance.Items.Clear();
	
	// Items.The result of the Quality check.
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsQualityCheckResult.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Status");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.StatusesOfQualityControlCertificates.InProgress;
	
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	
	// Items.Action.
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsAction.Name);
	
	StatusesList = New ValueList;
	StatusesList.Add(Enums.StatusesOfQualityControlCertificates.InProgress);
	StatusesList.Add(Enums.StatusesOfQualityControlCertificates.AwaitingDecision);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Status");
	ItemFilter.ComparisonType = DataCompositionComparisonType.InList;
	ItemFilter.RightValue = StatusesList;
	
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	
	// Items.Packaging.
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsPackage.Name);
	
	Items_Group = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	Items_Group.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	
	ItemFilter = Items_Group.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.UseBinLocationWarehousing");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	ItemFilter = Items_Group.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.Package");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	
	ItemFilter = Items_Group.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.ItemsType");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotEqual;
	ItemFilter.RightValue = Enums.ItemsTypes.OwnGoods;
	
	ItemFilter = Items_Group.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.MeasuredValueType");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotEqual;
	ItemFilter.RightValue = Enums.TypesOfMeasuredValues.NumberOfPieces;
	
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	
	// Items.Packaging.
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsPackage.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.Package");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.EmptyTableField);
	
	// Items.Packaging Arrival.
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsPackagingReceipt.Name);
	
	Items_Group = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	Items_Group.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	
	ItemFilter = Items_Group.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.UseBinLocationWarehousing");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	ItemFilter = Items_Group.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.PackagingReceipt");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	
	ItemFilter = Items_Group.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.ItemTypePosting");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotEqual;
	ItemFilter.RightValue = Enums.ItemsTypes.OwnGoods;
	
	ItemFilter = Items_Group.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.TypeOfMeasuredValueEntry");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotEqual;
	ItemFilter.RightValue = Enums.TypesOfMeasuredValues.NumberOfPieces;
	
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	
	// Items.Packaging Arrival.
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsPackage.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.PackagingReceipt");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.ItemTypePosting");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.ItemsTypes.OwnGoods;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.EmptyTableField);
	
	// Items.Series.
	
	ProductsServer.EstablishConditionalAppearanceOfProductSeries(ThisObject, "SeriesAlwaysWHGoods");
	
	// Items.Characteristics.
	
	ProductsServer.EstablishConditionalAppearanceOfProductCharacteristics(ThisObject, "GoodsCharacteristic");
	
	// Items.Characterization of arrival.
	
	ProductsServer.EstablishConditionalAppearanceOfProductCharacteristics(
		ThisObject, 
		"GoodsCharacteristicRecordingAsReceived",
		"Object.Goods.ItemVariantsAreUsedRecordingAsReceived");
	
	// Goods.Units of measurement.
	
	ConditionalDesignParameters = ProductsServer.NewParametersForConditionalDesignOfUnitsOfMeasurement(True, True);
	ConditionalDesignParameters.PathToFieldUseBinLocationSystem = "Object.Goods.UseBinLocationWarehousing";
	ProductsServer.SetConditionalAppearanceOfUnitsOfMeasurement(ThisObject, ConditionalDesignParameters);
	
	// Items.Unit of measurmentreception.
	
	ConditionalDesignParameters = ProductsServer.NewParametersForConditionalDesignOfUnitsOfMeasurement(True, True);
	ConditionalDesignParameters.PathToFieldUseBinLocationSystem = "Object.Goods.UseBinLocationWarehousing";
	ConditionalDesignParameters.NameOfUnitField = "GoodsProductsRecordingAsReceivedUnitOfMeasure";
	ConditionalDesignParameters.PathToPackagingUnitField = "Object.Goods.PackagingReceipt";
	ProductsServer.SetConditionalAppearanceOfUnitsOfMeasurement(ThisObject, ConditionalDesignParameters);

	//

	// Goods.The room.
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsPremise.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.UseWarerooms");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<không sử dụng nhà kho>';
													|ru = '<помещения не используются>';
													|en = '<premises are not used>'; fa = '<premises are not used>';
													|it = '<i locali non vengono usati>';
													|pl = '<pomieszczenie nie są używane>';
													|tr = '<alanlar kullanılmıyor>'"));
	Item.Appearance.SetParameterValue("TextColor", StyleColors.TextColorOfCanceledRowOfDocument);
	Item.Appearance.SetParameterValue("ReadOnly", True);
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	
	// Products.Cell.
	
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsCell.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.UseBinLocationWarehousing");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<không sử dụng ô hàng>';
													|ru = '<ячейки не используются>';
													|en = '<storage bins are not used>'; fa = '<storage bins are not used>';
													|it = '<le celle non vengono usate>';
													|pl = '<komórki nie są używane>';
													|tr = '<hücreler kullanılmıyor>'"));
	Item.Appearance.SetParameterValue("TextColor", StyleColors.TextColorOfCanceledRowOfDocument);
	Item.Appearance.SetParameterValue("ReadOnly", True);
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	
	// Items.Sub-assignment.

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsForAssignment.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.Purpose");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;

	Item.Appearance.SetParameterValue("Show", False);
	
	// Items.Sub-assignment.
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsForAssignment.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue  = New DataCompositionField("Object.Goods.AssignmentType");
	ItemFilter.ComparisonType   = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.AssignmentTypes.Giveaway2_5;
	
	Item.Appearance.SetParameterValue("ReadOnly", True);
	
	// All fields of the goods are of a different quality.
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsProductsRecordingAsReceived.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsCharacteristicRecordingAsReceived.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsPackagingReceipt.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsProductsRecordingAsReceivedCode.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ProductsNomenclatureRegistrationArticle.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsForAssignment.Name);
	
	ChangeQualityList = New ValueList();
	ChangeQualityList.Add(Enums.ActionsOnGoodsInQualityControlCertificate.ChangeQuality);
	ChangeQualityList.Add(Enums.ActionsOnGoodsInQualityControlCertificate.RegisterStockQualityChange);
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.Action");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotInList;
	ItemFilter.RightValue = ChangeQualityList;
	
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<chỉ để thay đổi chất lượng>';
													|ru = '<только для изменения качества>';
													|en = '<only for quality change>'; fa = '<only for quality change>';
													|it = '<only for quality change>';
													|pl = '<only for quality change>';
													|tr = '<yalnızca kalite değişikliği için>'"));
	Item.Appearance.SetParameterValue("TextColor", StyleColors.TextColorOfCanceledRowOfDocument);
	Item.Appearance.SetParameterValue("ReadOnly", True);
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	
	For Each Action In Actions Do
		
		Item = ConditionalAppearance.Items.Add();
		
		ItemField = Item.Fields.Items.Add();
		ItemField.Field = New DataCompositionField(Items.GoodsAction.Name);
		
		ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
		ItemFilter.LeftValue = New DataCompositionField("Object.Goods.Action");
		ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
		ItemFilter.RightValue = Action.Value;
		
		Item.Appearance.SetParameterValue("Text", Action.Presentation);
		
	EndDo;
	
	// Several Studies
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsResearchProject.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.SeveralStudies");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	Item.Appearance.SetParameterValue("Text", NStr("vi = 'Hiển thị các nghiên cứu';
													|ru = 'Показать исследования';
													|en = 'Show research'; fa = 'Show research';
													|it = 'Show research';
													|pl = 'Show research';
													|tr = 'İncelemeleri göster'"));
	Item.Appearance.SetParameterValue("TextColor", StyleColors.TabularFormHyperlink);
	Item.Appearance.SetParameterValue("ReadOnly", True);
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	
EndProcedure

#EndRegion

#Region CommandService

&AtClientAtServerNoContext
Function CheckFillWarehouseActionParameters(TheStockCaps)
	
	If ValueIsFilled(TheStockCaps) Then
		ActionParameters = New Structure("DefaultWarehouse", TheStockCaps);
	Else
		ActionParameters = New Structure("DefaultWarehouseFromCurrentLine");
	EndIf;
	Return ActionParameters;
	
EndFunction

#Region WorkingWithClipboard

&AtServer
Procedure CopyLinesOnServer(SelectedRows)
	
	ProcessingOfTabularForms.CopyRowsToClipboard(Object.Goods, SelectedRows);
	
EndProcedure

&AtServer
Procedure GetLinesFromClipboard()
	
	FilterParameters = New Map;
	FilterParameters.Insert("Products.ItemsType",
		ProductsClientServer.SelectionByProductMultiTurnContainer(False));
	
	Columns =
		"Products,
		|Characteristic,
		|Purpose,
		|Series,
		|Warehouse,
		|Premise,
		|Cell,
		|Action,
		|Package,
		|NumberOfPackages,
		|QualityCheckResult,
		|ProductsRecordingAsReceived,
		|PackagingReceipt,
		|CountRecordingAsReceived,
		|ForAssignment,
		|CharacteristicRecordingAsReceived";
	
	TableOfGoods = ProcessingOfTabularForms.RowsFromClipboard(FilterParameters, Columns);
	
	If Not ValueIsFilled(TableOfGoods) Then
		Return;
	EndIf;
	
	RowsToProcess = New Array();
	For Each RowOfProduct In TableOfGoods Do
		
		TableRow = Object.Goods.Add();
		FillPropertyValues(TableRow, RowOfProduct);
		If ValueIsFilled(Object.Premise) Then
			TableRow.Premise = Object.Premise;
		EndIf;
		CheckClearAccountAttributes(TableRow);
		RowsToProcess.Add(TableRow);
		
	EndDo;
	
	FillInArticleAttribute = New Structure("Products,ProductsRecordingAsReceived",
		"SKU",
		"SKURegistration");
	FillInProductTypeAttribute_ = New Structure("Products,ProductsRecordingAsReceived",
		"ItemsType", 
		"ItemTypePosting");
	FillInMeasuredValueTypeAttribute = New Structure("Products,ProductsRecordingAsReceived",
		"MeasuredValueType",
		"TypeOfMeasuredValueEntry");
	FillInFeatureAttribute = New Structure("Products,ProductsRecordingAsReceived",
		"ItemVariantsAreUsed",
		"ItemVariantsAreUsedRecordingAsReceived");
	FillInSpaceUsageAttribute = New Structure("Date", Object.Date);
	FillInAddressStorageAttribute = New Structure("Date", Object.Date);
	CheckFillWarehouse = CheckFillWarehouseActionParameters(Object.Warehouse);
	ProductsOnChangeOverridable = New Structure("FormName, TabularSectionName",
		FormName, "Goods");
	
	StructureOfActions = New Structure();
	StructureOfActions.Insert("FillInArticleAttribute", FillInArticleAttribute);
	StructureOfActions.Insert("FillInProductTypeAttribute_", FillInProductTypeAttribute_);
	StructureOfActions.Insert("FillInMeasuredValueTypeAttribute", FillInMeasuredValueTypeAttribute);
	StructureOfActions.Insert("FillInFeatureAttribute", FillInFeatureAttribute);
	StructureOfActions.Insert("ProductsOnChangeOverridable", ProductsOnChangeOverridable);
	StructureOfActions.Insert("RecalculateNumberOfUnits");
	StructureOfActions.Insert("FillInSpaceUsageAttribute", FillInSpaceUsageAttribute);
	StructureOfActions.Insert("FillInAddressStorageAttribute", FillInAddressStorageAttribute);
	StructureOfActions.Insert("CheckFillWarehouse", CheckFillWarehouse);
	CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		RowsToProcess,
		StructureOfActions,
		Object.Goods,
		CachedValues);
	
	EmptyRoom = Catalogs.Warerooms.EmptyRef();
	EmptyCell = Catalogs.StorageBins.EmptyRef();
	For Each TableRow In RowsToProcess Do
		
		If Not TableRow.UseWarerooms Then
			TableRow.Premise = EmptyRoom;
			TableRow.Cell = EmptyCell;
		EndIf;
		
		If Not TableRow.UseBinLocationWarehousing Then
			TableRow.Cell = EmptyCell;
		EndIf;
		
	EndDo;
	
	ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters, RowsToProcess);
	
EndProcedure

&AtServer
Procedure SetAvailabilityOfClipboardCommands()
	
	ItemArray = New Array();
	ItemArray.Add("InsertRows");
	ItemArray.Add("GoodsContextMenuInsertRows");
	
	TMCommonUseClientServer.SetPropertyOfFormElements(Items, ItemArray, "Enabled",
		ProcessingOfTabularForms.ThereAreLinesInClipboard());
	
EndProcedure

&AtClient
Procedure SetAvailabilityOfClipboardCommandsOnClient()
	
	ItemArray = New Array();
	ItemArray.Add("InsertRows");
	ItemArray.Add("GoodsContextMenuInsertRows");
	
	TMCommonUseClientServer.SetPropertyOfFormElements(Items, ItemArray, "Enabled", True);
	
EndProcedure

#EndRegion

&AtClient
Procedure SplitRowCompletion(NewRow, AdditionalParameters) Export 
	
	CurrentRow = Items.Goods.CurrentData;
	
	If NewRow <> Undefined Then
		
		StructureOfActions = New Structure();
		StructureOfActions.Insert("RecalculateNumberOfUnits");
		BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
		BatchProcessingOfTablePartClient.ProcessTSString(NewRow, StructureOfActions, CachedValues);
		RecalculateNumberOfEntries(CurrentRow);
		RecalculateNumberOfEntries(NewRow);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure FillInQualityControlResultAfterSelection(ValueSelected, AdditionalParameters) Export
	
	If ValueSelected = Undefined Then
		Return;
	EndIf;
	FillInQualityControlResultAfterSelectionServer(ValueSelected);
	
EndProcedure

&AtServer
Procedure FillInQualityControlResultAfterSelectionServer(ValueSelected)
	
	For Each Id In Items.Goods.SelectedRows Do
		
		Object.Goods.FindByID(Id).QualityCheckResult = ValueSelected;
		
	EndDo;
	
EndProcedure

&AtServer
Procedure InitializationOfFillingSettingsByBalances(Schema_Name, Address, Settings)
	
	Schema = Documents.GoodsQualityControlCertificate.GetTemplate(Schema_Name);
	Address = PutToTempStorage(Schema, UUID);
	Settings.Initialize(New DataCompositionAvailableSettingsSource(Address));
	Settings.LoadSettings(Schema.DefaultSettings);
	
EndProcedure

&AtServer
Procedure FillInByBalanceServer(Val SettingsComposer)
	
	Schema_Name = "FillingSchemeByLotBalances";
	Settings = FillingSettingsForBatchBalances;
	
	Object.Goods.Clear();
	Settings.LoadSettings(SettingsComposer.GetSettings());
	Settings.LoadUserSettings(SettingsComposer.UserSettings);
	
	DataCompositionSchema = Documents.GoodsQualityControlCertificate.GetTemplate(Schema_Name);
	CompositionSettings = Settings.GetSettings();
	CompositionSettings.DataParameters.Items.Find("ControlledLotReference").Value = Object.ControlledLotReference;
	CompositionSettings.DataParameters.Items.Find("Recorder").Value = Object.Ref;
	TemplateComposer = New DataCompositionTemplateComposer;
	CompositionTemplate = TemplateComposer.Execute(DataCompositionSchema,
		CompositionSettings, , , Type("DataCompositionValueCollectionTemplateGenerator"));
	CompositionProcessor = New DataCompositionProcessor;
	CompositionProcessor.Initialize(CompositionTemplate);
	OutputProcessor = New DataCompositionResultValueCollectionOutputProcessor;
	Analysts = OutputProcessor.Output(CompositionProcessor);
	QualityControl.AddColumnsDisabledByFOToAnalystTable(Analysts);
	Object.Goods.Load(QualityControl.AnalystBalances(Analysts, False, Object.Date, Object.Ref));
	ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);
	ClearWarehouseRoomIfThereAreSeveralOfThem();
	FillInServiceAttributesWhenFillingOutTablePart();
	SetVisibilityOfWarehouseAndPremises();
	
EndProcedure

&AtClient
Procedure SettingUpFillingByBalanceEnd(ClosingResult, AdditionalParameters) Export

	If TypeOf(ClosingResult) = Type("DataCompositionSettingsComposer") Then
		FillInByBalanceServer(ClosingResult);
	EndIf;
	
EndProcedure

&AtServer
Procedure ProcessingSelectionOfSelectionOnServer(ValueSelected)
	
	TableOfGoods = GetFromTempStorage(ValueSelected.GoodsAddressInStorage);
	
	RowsToProcess = New Array();
	For Each RowOfProduct In TableOfGoods Do
		
		TableRow = Object.Goods.Add();
		RowsToProcess.Add(TableRow);
		FillPropertyValues(TableRow, RowOfProduct,
			"Products,Characteristic,Package,NumberOfPackages,Series");
		
	EndDo;
	
	FillInArticleAttribute = New Structure("Products", "SKU");
	FillInProductTypeAttribute_ = New Structure("Products", "ItemsType");
	FillInMeasuredValueTypeAttribute = New Structure("Products", "MeasuredValueType");
	FillInFeatureAttribute = New Structure("Products", "ItemVariantsAreUsed");
	FillInSpaceUsageAttribute = New Structure("Date", Object.Date);
	FillInAddressStorageAttribute = New Structure("Date", Object.Date);
	CheckFillWarehouse = CheckFillWarehouseActionParameters(Object.Warehouse);
	ProductsOnChangeOverridable = New Structure("FormName, TabularSectionName",
		FormName, "Goods");
	
	StructureOfActions = New Structure();
	StructureOfActions.Insert("FillInArticleAttribute", FillInArticleAttribute);
	StructureOfActions.Insert("FillInProductTypeAttribute_", FillInProductTypeAttribute_);
	StructureOfActions.Insert("FillInMeasuredValueTypeAttribute", FillInMeasuredValueTypeAttribute);
	StructureOfActions.Insert("FillInFeatureAttribute", FillInFeatureAttribute);
	StructureOfActions.Insert("ProductsOnChangeOverridable", ProductsOnChangeOverridable);
	StructureOfActions.Insert("RecalculateNumberOfUnits");
	StructureOfActions.Insert("CheckFillWarehouse", CheckFillWarehouse);
	StructureOfActions.Insert("FillInSpaceInTSLine", Object.Premise);
	StructureOfActions.Insert("FillInSpaceUsageAttribute", FillInSpaceUsageAttribute);
	StructureOfActions.Insert("FillInAddressStorageAttribute", FillInAddressStorageAttribute);
	
	CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		RowsToProcess,
		StructureOfActions,
		Object.Goods,
		CachedValues);
		
	ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters, RowsToProcess);
	
EndProcedure

&AtClient
Procedure GoodsSearchByBarcodeCompletion(BarcodeData_2, AdditionalParameters) Export
	
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
	
	FillInArticleAttribute = New Structure("Products", "SKU");
	FillInProductTypeAttribute_ = New Structure("Products", "ItemsType");
	FillInMeasuredValueTypeAttribute = New Structure("Products", "MeasuredValueType");
	FillInFeatureAttribute = New Structure("Products", "ItemVariantsAreUsed");
	FillInSpaceUsageAttribute = New Structure("Date", Object.Date);
	FillInAddressStorageAttribute = New Structure("Date", Object.Date);
	ProductsOnChangeOverridable = New Structure("FormName, TabularSectionName",
		FormName, "Goods");
	CheckFillWarehouse = CheckFillWarehouseActionParameters(Object.Warehouse);
	CheckSeriesCalculateStatus = New Structure("Warehouse, SeriesSpecificationParameters", Object.Warehouse, SeriesSpecificationParameters);
	
	StructureOfActionsWithAddedStrings = New Structure();
	StructureOfActionsWithAddedStrings.Insert("FillInArticleAttribute", FillInArticleAttribute);
	StructureOfActionsWithAddedStrings.Insert("FillInProductTypeAttribute_", FillInProductTypeAttribute_);
	StructureOfActionsWithAddedStrings.Insert("FillInMeasuredValueTypeAttribute", FillInMeasuredValueTypeAttribute);
	StructureOfActionsWithAddedStrings.Insert("FillInFeatureAttribute", FillInFeatureAttribute);
	StructureOfActionsWithAddedStrings.Insert("ProductsOnChangeOverridable", ProductsOnChangeOverridable);
	StructureOfActionsWithAddedStrings.Insert("RecalculateNumberOfUnits");
	StructureOfActionsWithAddedStrings.Insert("CheckFillWarehouse", CheckFillWarehouse);
	StructureOfActionsWithAddedStrings.Insert("FillInSpaceInTSLine", Object.Premise);
	StructureOfActionsWithAddedStrings.Insert("FillInSpaceUsageAttribute", FillInSpaceUsageAttribute);
	StructureOfActionsWithAddedStrings.Insert("FillInAddressStorageAttribute", FillInAddressStorageAttribute);
	StructureOfActionsWithAddedStrings.Insert("CheckSeriesCalculateStatus", CheckSeriesCalculateStatus);
	
	StructureOfActionsWithModifiedStrings = New Structure();
	StructureOfActionsWithModifiedStrings.Insert("RecalculateNumberOfUnits");
	
	BarcodeProcessingParameters = BarcodingOfItemsClient.BarcodeProcessingParameters();
	
	BarcodeProcessingParameters.Barcodes = BarcodeData_5;
	BarcodeProcessingParameters.StructureOfActionsWithAddedStrings = StructureOfActionsWithAddedStrings;
	BarcodeProcessingParameters.StructureOfActionsWithModifiedStrings = StructureOfActionsWithModifiedStrings;
	BarcodeProcessingParameters.SeriesSpecificationParameters = SeriesSpecificationParameters;
	BarcodeProcessingParameters.ChangeQuantity = True;
	BarcodeProcessingParameters.GoodsOnly = True;
	BarcodeProcessingParameters.TSName = "Goods";
	
	ProcessBarcodesServer(BarcodeProcessingParameters, CachedValues);
	
	BarcodingOfItemsClient.ProcessUnknownBarcodes(BarcodeProcessingParameters,
		CachedValues, ThisObject);
	
	If BarcodingOfItemsClient.YouNeedToOpenFormForSpecifyingSeriesAfterProcessingBarcodes(BarcodeProcessingParameters) Then
		CurDataId = BarcodeProcessingParameters.ArrayOfRowsWithSeries_[0];
		
		AttachIdleHandler("OpenSeriesSelectionWhenScanningProductBarCode", 0.1, True);
	EndIf;
	
	If BarcodeProcessingParameters.CurrentRow <> Undefined Then
		Items.Goods.CurrentRow = BarcodeProcessingParameters.CurrentRow;
	EndIf;
	
EndProcedure

&AtServer
Procedure ProcessBarcodesServer(StructureOfActionParameters, CachedValues)
	
	ItemsTypes = ProductsServer.AcceptableItemTypesToChooseFrom(
		Enums.BusinessTransactions.GoodsQualityControl);
	
	ThereAreWorks = ItemsTypes.Find(Enums.ItemsTypes.Work_5) <> Undefined;
	ThereAreServices = ItemsTypes.Find(Enums.ItemsTypes.OperationService) <> Undefined;
	
	StructureOfActionParameters.GoodsOnly = Not (ThereAreWorks Or ThereAreServices);
	StructureOfActionParameters.OnlyGoodsAndWork = ThereAreWorks And Not ThereAreServices;
	StructureOfActionParameters.OnlyGoodsAndServices = ThereAreServices And Not ThereAreWorks;
	
	BarcodingOfItemsServer.ProcessBarcodes(ThisObject,
		Object, StructureOfActionParameters, CachedValues);
	
EndProcedure

// Parameters:
//  FillValue - EnumRef.ActionsOnGoodsInQualityControlCertificate - action to fill in
// Returns:
//  Number - number of processed rows
&AtServer
Function FillInActionColumn(FillValue)
	
	RowsIDs = Items.Goods.SelectedRows;
	If Actions.FindByValue(FillValue) = Undefined Then
		Return 0;
	EndIf;
	
	CheckingWarehouseOrderness = False;
	If FillValue = Enums.ActionsOnGoodsInQualityControlCertificate.ChangeQuality Then
		CheckingWarehouseOrderness = True;
		Warehouses = Object.Goods.Unload(, "Warehouse").UnloadColumn("Warehouse");
		SetPrivilegedMode(True);
		DetailsOfWarehouses = Common.ObjectsAttributesValues(Warehouses,
			"UseWarehouseManagemantSystemForGoodsReceipt,StartDateOfWarehouseManagemantSystemForGoodsReceipt");
		SetPrivilegedMode(False);
		DocumentDate = ?(ValueIsFilled(Object.Date), Object.Date, BegOfDay(CurrentSessionDate()));
	EndIf;
	
	For Each RowID In RowsIDs Do
		TableRow = Object.Goods.FindByID(RowID);
		If Not (CheckingWarehouseOrderness
					And ValueIsFilled(TableRow.Warehouse)
					And (Not DetailsOfWarehouses[TableRow.Warehouse].UseWarehouseManagemantSystemForGoodsReceipt
						Or DetailsOfWarehouses[TableRow.Warehouse].StartDateOfWarehouseManagemantSystemForGoodsReceipt > DocumentDate)) Then
			TableRow.Action = FillValue;
			CheckClearAccountAttributes(TableRow);
		EndIf;
	EndDo;
	
	Return RowsIDs.Count();
	
EndFunction

&AtClient
Function ThereAreLinesToExecuteCommand(Field)
	
	If Object.Goods.Count() = 0 Then
		
		Text = NStr("vi = 'Trong chứng từ chưa điền danh sách ""Hàng hóa"". Trường %1 không thể được điền.';
					|ru = 'В документе не заполнен список ""Товары"". Поле %1 не может быть заполнено.';
					|en = 'The ""Goods"" list in the document is not filled in. Cannot fill in the ""%1"" field.'; fa = 'The ""Goods"" list in the document is not filled in. Cannot fill in the ""%1"" field.';
					|it = 'The ""Goods"" list in the document is not filled in. Cannot fill in the ""%1"" field.';
					|pl = 'The ""Goods"" list in the document is not filled in. Cannot fill in the ""%1"" field.';
					|tr = 'Belgede ""Ürünler"" listesi doldurulmamış. %1 alanı doldurulamaz.'");
		ShowMessageBox(, StrTemplate(Text, Field));
		Return False;
		
	ElsIf Items.Goods.SelectedRows.Count() = 0 Then
		
		Text = NStr("vi = 'Trong chứng từ không có dòng hàng hóa nào được chọn. Vui lòng chọn các dòng để điền vào trường %1.';
					|ru = 'В документе отсутствуют выделенные строки товаров. Выделите строки для заполнения поля %1.';
					|en = 'The document has no selected item rows. Select rows to fill the ""%1"" field.'; fa = 'The document has no selected item rows. Select rows to fill the ""%1"" field.';
					|it = 'The document has no selected item rows. Select rows to fill the ""%1"" field.';
					|pl = 'The document has no selected item rows. Select rows to fill the ""%1"" field.';
					|tr = 'Belgede seçili ürün satırı yok. %1 alanını doldurmak için satırları seçin.'");
		ShowMessageBox(, StrTemplate(Text, Field));
		Return False;
		
	EndIf;
	Return True;
	
EndFunction

&AtServer
Procedure ClearWarehouseRoomIfThereAreSeveralOfThem()
	
	If ValueIsFilled(Object.Warehouse) Or ValueIsFilled(Object.Premise) Then
		For Each LineProducts_ In Object.Goods Do
			If ValueIsFilled(Object.Warehouse) And LineProducts_.Warehouse <> Object.Warehouse Then
				Object.Warehouse = Catalogs.Warehouses.EmptyRef();
			EndIf;
			If ValueIsFilled(Object.Premise) And LineProducts_.Premise <> Object.Premise Then
				Object.Premise = Catalogs.Warerooms.EmptyRef();
			EndIf;
		EndDo;
	EndIf;
	
EndProcedure

&AtServer
Procedure FillCleanWarehouseRoomAccordingToTabularPartOfDocument()
	QualityControl.FillCleanWarehouseRoomAccordingToTabularPartOfDocument(Object);
EndProcedure

#EndRegion

#Region Subsystems

// IntegrationWith1CDocumentManagementSubsystem

&AtClient
Procedure Attachable_ExecuteIntegrationCommand(Command)
	
	IntegrationWith1CDocumentManagementCoreClient.ExecutePlugInIntegrationCommand(Command,
		ThisObject, Object);
	
EndProcedure

// End IntegrationWith1CDocumentManagementSubsystem

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisObject, Command);
	
EndProcedure

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

&AtServer
Procedure PropertiesExecuteDeferredInitialization()
	PropertyManager.FillAdditionalAttributesInForm(ThisObject);
EndProcedure

// End StandardSubsystems.Properties

#EndRegion

#Region SetOfSeries

&AtClient
Procedure OpenSeriesSelectionWhenScanningProductBarCode()
	
	If CurDataId = Undefined Then
		Return;
	EndIf;
	
	CurrentData = Object.Goods.FindByID(CurDataId);
	OpenSelectionOfSeries(,CurrentData);
	
EndProcedure

&AtClient
Procedure OpenSelectionOfSeries(Text = "", CurrentData = Undefined)
	
	NeedServerCall = ProductsClient.YouNeedServerCallToSpecifySeries(
		ThisObject,
		SeriesSpecificationParameters,
		Text,
		CurrentData);
		
	If NeedServerCall Then
		
		If CurrentData = Undefined Then
			CurDataId = Items.Goods.CurrentData.GetID();
		Else
			CurDataId = CurrentData.GetID();
		EndIf;
		
		ParametersOfSeriesIndicationForm = ParametersOfSeriesIndicationForm(CurDataId);
		
		CurParametersForSpecifyingSeries = New Structure("ParametersOfSeriesIndicationForm", ParametersOfSeriesIndicationForm);
		
		CallbackDescription = New CallbackDescription(
			"OpenSelectionOfSeriesCompletion",
			ThisObject,
			CurParametersForSpecifyingSeries);
		
		OpenForm(
			ParametersOfSeriesIndicationForm.FormName,
			ParametersOfSeriesIndicationForm,
			ThisObject,
			,
			,
			,
			CallbackDescription,
			FormWindowOpeningMode.LockOwnerWindow);
			
	EndIf;
		
EndProcedure

&AtClient
Procedure OpenSelectionOfSeriesCompletion(Result, AdditionalParameters) Export
	
	ReturnValue_1 = Result;
	If ReturnValue_1 <> Undefined Then
		ProcessSeriesIndication_Server(AdditionalParameters.ParametersOfSeriesIndicationForm, CachedValues);
	EndIf;
	
EndProcedure

&AtServer
Procedure ProcessSeriesIndication_Server(ParametersOfSeriesIndicationForm, CachedValues)
	
	CheckSeriesCalculateStatus = New Structure("Warehouse, SeriesSpecificationParameters", Object.Warehouse, SeriesSpecificationParameters);
	
	StructureOfActions = New Structure();
	StructureOfActions.Insert("CheckSeriesCalculateStatus", CheckSeriesCalculateStatus);
	
	ProductsServer.ProcessSeriesIndication_(
		Object,
		SeriesSpecificationParameters,
		ParametersOfSeriesIndicationForm,
		StructureOfActions,
		CachedValues);
	
EndProcedure

&AtServer
Function ParametersOfSeriesIndicationForm(CurDataId)
	
	Return ProductsServer.ParametersOfSeriesIndicationForm(
		Object,
		SeriesSpecificationParameters,
		CurDataId,
		ThisObject);
	
EndFunction

#EndRegion

#Region ChangingDocumentAttributes

&AtServer
Procedure WhenChangingWarehouseServer()
	
	// Clearing the warehouse only means that it and the premises are now listed in the table.
	If ValueIsFilled(Object.Warehouse) Then
		
		EmptyRoom = Catalogs.Warerooms.EmptyRef();
		Object.Premise = EmptyRoom;
		
		CheckFillWarehouse = CheckFillWarehouseActionParameters(Object.Warehouse);
		FillInSpaceUsageAttribute = New Structure("Date", Object.Date);
		FillInAddressStorageAttribute = New Structure("Date", Object.Date);
		CheckSeriesCalculateStatus = New Structure("Warehouse, SeriesSpecificationParameters", Object.Warehouse, SeriesSpecificationParameters);
		
		StructureOfActions = New Structure();
		StructureOfActions.Insert("CheckFillWarehouse", CheckFillWarehouse);
		StructureOfActions.Insert("FillInSpaceInTSLine", Object.Premise);
		StructureOfActions.Insert("FillInSpaceUsageAttribute", FillInSpaceUsageAttribute);
		StructureOfActions.Insert("FillInAddressStorageAttribute", FillInAddressStorageAttribute);
		StructureOfActions.Insert("CheckSeriesCalculateStatus", CheckSeriesCalculateStatus);
		BatchProcessingOfTablePartServer.TreatTS(Object.Goods, StructureOfActions);
		ClearPackagingForStringsWithoutAddressableStorage();
		
	EndIf;
	
	SetVisibilityOfWarehouseAndPremises();
	ConfigureActions();
	ClearInvalidActions();
	
EndProcedure

&AtServer
Procedure WhenChangingDateServer()
	
	FillInSpaceUsageAttribute = New Structure("Date", Object.Date);
	FillInAddressStorageAttribute = New Structure("Date", Object.Date);
	
	StructureOfActions = New Structure();
	StructureOfActions.Insert("FillInSpaceUsageAttribute", FillInSpaceUsageAttribute);
	StructureOfActions.Insert("FillInAddressStorageAttribute", FillInAddressStorageAttribute);
	
	BatchProcessingOfTablePartServer.TreatTS(Object.Goods, StructureOfActions);
	
	VisibilityOfRoomBeforeChange = Items.Premise.Visible;
	SetVisibilityOfWarehouseAndPremises();
	CleanRoom = VisibilityOfRoomBeforeChange And Not Items.Premise.Visible;
	
	If CleanRoom Then
		EmptyRoom = Catalogs.Warerooms.EmptyRef();
		Object.Premise = EmptyRoom;
		For Each String In Object.Goods Do
			String.Premise = EmptyRoom;
		EndDo;
		ClearPackagingForStringsWithoutAddressableStorage();
	EndIf;
	
	ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);
	
	ConfigureActions();
	ClearInvalidActions();
	
EndProcedure

&AtServer
Procedure OnChangingRoomServer()
	
	// Cleaning the room only means that it is now indicated in the table.
	If ValueIsFilled(Object.Premise) Then
		For Each String In Object.Goods Do
			String.Premise = Object.Premise;
		EndDo;
		StructureOfActions = New Structure();
		FillInAddressStorageAttribute = New Structure("Date", Object.Date);
		StructureOfActions.Insert("FillInAddressStorageAttribute", FillInAddressStorageAttribute);
		BatchProcessingOfTablePartServer.TreatTS(Object.Goods, StructureOfActions);
		ClearPackagingForStringsWithoutAddressableStorage();
	EndIf;
	SetVisibilityOfWarehouseAndPremises();
	
EndProcedure

&AtServer
Procedure OnChangingControlledLotReferenceServer()
	
	SetPrivilegedMode(True);
	Documents.GoodsQualityControlCertificate.FillInDetailsFromParty(Object);
	SetPrivilegedMode(False);
	
	FillInDetailsOfFormDependentOnControlledLotReference();
	ConfigureActions();
	ClearInvalidActions();
	
EndProcedure

&AtServer
Procedure ClearInvalidActions()
	
	Warehouses = Object.Goods.Unload(, "Warehouse").UnloadColumn("Warehouse");
	SetPrivilegedMode(True);
	DetailsOfWarehouses = Common.ObjectsAttributesValues(Warehouses,
		"UseWarehouseManagemantSystemForGoodsReceipt,StartDateOfWarehouseManagemantSystemForGoodsReceipt");
	SetPrivilegedMode(False);
	
	EmptyAction = Enums.ActionsOnGoodsInQualityControlCertificate.EmptyRef();
	ActonToChangeQuality = Enums.ActionsOnGoodsInQualityControlCertificate.ChangeQuality;
	DocumentDate = ?(ValueIsFilled(Object.Date), Object.Date, BegOfDay(CurrentSessionDate()));
	For Each TableRow In Object.Goods Do
		
		If Actions.FindByValue(TableRow.Action) = Undefined
				Or TableRow.Action = ActonToChangeQuality
					And ValueIsFilled(TableRow.Warehouse)
					And (Not DetailsOfWarehouses[TableRow.Warehouse].UseWarehouseManagemantSystemForGoodsReceipt
						Or DetailsOfWarehouses[TableRow.Warehouse].StartDateOfWarehouseManagemantSystemForGoodsReceipt > DocumentDate) Then
			TableRow.Action = EmptyAction;
			CheckClearAccountAttributes(TableRow);
		EndIf;
		
	EndDo;
	
EndProcedure

#EndRegion

&AtServer
Procedure SetVisibilityOfWarehouseAndPremises()
	
	UseWarerooms = WarehousesServer.UseWarerooms(Object.Warehouse, Object.Date)
		And ValueIsFilled(Object.Warehouse);
	Items.Premise.Visible = UseWarerooms;
	Items.GoodsWarehouse.Visible = Not ValueIsFilled(Object.Warehouse);
	Items.GoodsPremise.Visible = Not ValueIsFilled(Object.Warehouse)
		Or Not ValueIsFilled(Object.Premise) And UseWarerooms;
	
EndProcedure

&AtServerNoContext
Function ActionSelectionData(MethodParameters)
	
	Actions = Enums.ActionsOnGoodsInQualityControlCertificate.GetChoiceData(MethodParameters);
	Return Actions;
	
EndFunction

&AtServer
Procedure ConfigureActions()
	
	MethodParameters = New Structure();
	MethodParameters.Insert("ControlledLotReference", Object.ControlledLotReference);
	MethodParameters.Insert("Warehouse", Object.Warehouse);
	MethodParameters.Insert("Date", Object.Date);
	Actions = Enums.ActionsOnGoodsInQualityControlCertificate.GetChoiceData(MethodParameters);
	
	AllActions = Enums.ActionsOnGoodsInQualityControlCertificate;
	CommandsAndActions = New Map();
	CommandsAndActions.Insert(AllActions.ChangeQuality, Items.FillInChangeQualityAction);
	CommandsAndActions.Insert(AllActions.ToReturnToVendor, Items.FillInActionReturnToSupplier);
	CommandsAndActions.Insert(AllActions.DoNotReceiveGoods, Items.FillInDoNotReceiveGoodsAction);
	CommandsAndActions.Insert(AllActions.RegisterStockQualityChange, Items.FillInActionToIssueDamage);
	CommandsAndActions.Insert(AllActions.RegisterReturn, Items.FillInReturnAction);
	CommandsAndActions.Insert(AllActions.RegisterGoodsTransfer, Items.FillInFormalizeMoveAction);
	CommandsAndActions.Insert(AllActions.MakeDebit, Items.FillInWriteOffAction);
	
	For Each Item In CommandsAndActions Do
		ValueFound = Actions.FindByValue(Item.Key);
		Item.Value.Visible = ValueFound <> Undefined;
		If ValueFound <> Undefined Then
			Item.Value.Title = ValueFound.Presentation;
		EndIf;
	EndDo;
	
	Items.RegisterDiscrepancyCertificate.Visible =
		Actions.FindByValue(AllActions.ChangeQuality) <> Undefined
			Or Actions.FindByValue(AllActions.ToReturnToVendor) <> Undefined
			Or Actions.FindByValue(AllActions.DoNotReceiveGoods) <> Undefined;
			
	Items.RegisterStockQualityChange.Visible = Actions.FindByValue(AllActions.RegisterStockQualityChange) <> Undefined;
	Items.RegisterReturn.Visible = Actions.FindByValue(AllActions.RegisterReturn) <> Undefined;
	Items.RegisterGoodsTransfer.Visible = Actions.FindByValue(AllActions.RegisterGoodsTransfer) <> Undefined;
	Items.MakeDebit.Visible = Actions.FindByValue(AllActions.MakeDebit) <> Undefined;
	NameOfRight = "Insert"; // @Access-right-1
	Items.RegisterDiscrepancyCertificate.Enabled =
		AccessRight(NameOfRight, Metadata.Documents.DiscrepancyReportFollowingReceipt)
				And (DrawUpActOfAcquisition
					Or DrawUpRecyclingReportOnSide
					Or ToDrawUpActOnProcessingOfTollFreeRawMaterials)
			Or AccessRight(NameOfRight, Metadata.Documents.DiscrepancyReportFollowingTransfer)
				And DrawUpTransferCertificate
			Or (AccessRight(NameOfRight, Metadata.Documents.DiscrepancyReportFollowingReceipt)
					Or AccessRight(NameOfRight, Metadata.Documents.DiscrepancyReportFollowingTransfer))
				And Not DrawUpActOfAcquisition
				And Not DrawUpRecyclingReportOnSide
				And Not ToDrawUpActOnProcessingOfTollFreeRawMaterials
				And Not DrawUpTransferCertificate;
	
	NameOfRight = "Insert"; // @Access-right-1
	Items.RegisterStockQualityChange.Enabled = AccessRight(NameOfRight, Metadata.Documents.GoodsDamage);
	Items.RegisterReturn.Enabled = AccessRight(NameOfRight, Metadata.Documents.ReturnOfGoodsToVendor)
		Or AccessRight(NameOfRight, Metadata.Documents.GoodsShipmentFromStorage);
	Items.RegisterGoodsTransfer.Enabled = AccessRight(NameOfRight, Metadata.Documents.InventoryTransfer);
	Items.MakeDebit.Enabled = AccessRight(NameOfRight, Metadata.Documents.WriteOffOfGoodsShortages);
	
	FieldsVisibility = Actions.FindByValue(AllActions.ChangeQuality) <> Undefined
		Or Actions.FindByValue(AllActions.RegisterStockQualityChange) <> Undefined;
	ConfigureQualityChangeFields(FieldsVisibility);
	SetConditionalAppearance();
	
EndProcedure

&AtServer
Procedure ConfigureQualityChangeFields(Visible);
	
	Items.DamagedGoodsGroup.Visible = Visible;
	Items.GoodsProductsRecordingAsReceivedCode.Visible = Visible;
	Items.ProductsNomenclatureRegistrationArticle.Visible = Visible;
	Items.GoodsProductsRecordingAsReceived.Visible = Visible;
	Items.GoodsCharacteristicRecordingAsReceived.Visible = Visible;
	Items.GoodsForAssignment.Visible = Visible;
	Items.GoodsRecordingAsReceivedGroupPackagingUnitOfMeasure.Visible = Visible;
	Items.GoodsPackagingReceipt.Visible = Visible;
	Items.GoodsProductsRecordingAsReceivedUnitOfMeasure.Visible = Visible;
	Items.GroupProductOfInitialQuality.ShowInHeader = Visible;
	
EndProcedure

&AtServer
Procedure ClearPackagingForStringsWithoutAddressableStorage()
	
	For Each String In Object.Goods Do
		
		If Not String.UseBinLocationWarehousing Then
			String.Package = Catalogs.PackagesAndUnitsOfMeasure.EmptyRef();
			String.Count = String.NumberOfPackages;
		EndIf;
		
	EndDo;

EndProcedure

&AtClient
Procedure ClearPackagingForStringsWithoutAddressStorageInString(TableRow)
	
	If Not TableRow.UseBinLocationWarehousing Then
		TableRow.Package = PredefinedValue("Catalog.PackagesAndUnitsOfMeasure.EmptyRef");
		TableRow.Count = TableRow.NumberOfPackages;
	EndIf;

EndProcedure

#Region Research

&AtServer
Procedure FillOutResearch()

	For Each String In Object.Goods Do
		Filter = New Structure;
		Filter.Insert("RowID", String.RowID);
		FoundRows = Object.ResearchResults.FindRows(Filter);
		If FoundRows.Count() = 1 Then
			FillPropertyValues(String, FoundRows[0]);
			String.SeveralStudies = False;
		ElsIf FoundRows.Count() > 0 Then
			String.SeveralStudies = True;
		EndIf;
	EndDo;

EndProcedure

&AtServer
Function TableOfSelectedRowsInArrayOfStructures(RowID, AttributesList)

	Result = New Array;
	FoundRows = Object.ResearchResults.FindRows(New Structure("RowID", RowID));
	For Each String In FoundRows Do

		StringStructure = New Structure(AttributesList);
		FillPropertyValues(StringStructure, String);
		StringStructure.Control = Common.ObjectAttributeValue(String.ResearchProject, "Control");
		Result.Add(StringStructure);

	EndDo;

	Return Result;

EndFunction

&AtServer
Procedure DeleteUnusedStudies()
	
	RowsCount = Object.ResearchResults.Count()-1;
	For RowIndex = -RowsCount To 0 Do
		TableRow = Object.ResearchResults.Get(-RowIndex);
		Filter = New Structure();
		Filter.Insert("RowID", TableRow.RowID);
		FoundRows = Object.Goods.FindRows(Filter);
		If FoundRows.Count() = 0 Then
			Object.ResearchResults.Delete(-RowIndex);
		EndIf;
	EndDo;

EndProcedure

#EndRegion

&AtClient
Procedure NotifyAboutDocument(WriteParameters)
	
	NotificationProcessingParameter = CommonClient.CopyRecursive(WriteParameters);
	If TypeOf(FormOwner) = Type("ClientApplicationForm") Then
		IdOfOwnerSForm = FormOwner.UUID;
	Else
		IdOfOwnerSForm = Undefined;
	EndIf;
	NotificationDocumentKeys = OperationsWithDocumentJournalsClient.GetKeyParametersForDocument(
		Object.Ref, Object.Date, Undefined);
	NotificationProcessingParameter.Insert("IdOfOwnerSForm", IdOfOwnerSForm);
	NotificationProcessingParameter.Insert("NotificationDocumentKeys", NotificationDocumentKeys);
	Notify("Write_GoodsQualityControlCertificate", NotificationProcessingParameter, Object.Ref);
	
EndProcedure

&AtServer
Procedure OnReadCreateAtServer()
	
	UseNonConformanceCertificatesFollowingTransfer = GetFunctionalOption("UseNonConformanceCertificatesFollowingTransfer");
	UseNonConformanceCertificatesFollowingAcceptance = GetFunctionalOption("UseNonConformanceCertificatesFollowingAcceptance");
	UseCertificatesOfDiscrepanciesAfterAcceptanceForAcceptanceOfGiverSGoods2_5 = False;
	UseCertificatesOfDiscrepanciesAfterAcceptanceForAcceptanceOfGiverSGoods2_5 = GetFunctionalOption("UseCertificatesOfDiscrepanciesAfterAcceptanceForAcceptanceOfGiverSGoods2_5");
	UseDiscrepancyReportFollowingReceiptFromSubcontractor2_5 = False;
	UseDiscrepancyReportFollowingReceiptFromSubcontractor2_5 = GetFunctionalOption("UseDiscrepancyReportFollowingReceiptFromSubcontractor2_5");
	CurParametersForSpecifyingSeries = ProductsServer.SeriesSpecificationParameters(
		Object,
		Documents.GoodsQualityControlCertificate);
	SeriesSpecificationParameters = New FixedStructure(CurParametersForSpecifyingSeries);
	
	FillInDetailsOfFormDependentOnControlledLotReference();
	ConfigureActions();
	
	SetVisibilityOfWarehouseAndPremises();
	FillInServiceAttributesWhenFillingOutTablePart();
	Items.BaseGroup_.Visible = ValueIsFilled(Object.DocumentBasis);
	Items.GoodsResearchGroup.Visible = GetFunctionalOption("UseGoodsQualityResearch");
	FillOutResearch();
EndProcedure

&AtServer
Procedure FillInServiceAttributesWhenFillingOutTablePart()
	
	FillInArticleAttribute = New Structure("Products,ProductsRecordingAsReceived",
		"SKU",
		"SKURegistration");
	FillInProductTypeAttribute_ = New Structure("Products,ProductsRecordingAsReceived",
		"ItemsType", 
		"ItemTypePosting");
	FillInMeasuredValueTypeAttribute = New Structure("Products,ProductsRecordingAsReceived",
		"MeasuredValueType",
		"TypeOfMeasuredValueEntry");
	FillInFeatureAttribute = New Structure("Products,ProductsRecordingAsReceived",
		"ItemVariantsAreUsed",
		"ItemVariantsAreUsedRecordingAsReceived");
	
	FillInSpaceUsageAttribute = New Structure("Date", Object.Date);
	FillInAddressStorageAttribute = New Structure("Date", Object.Date);
	
	StructureOfActions = New Structure();
	StructureOfActions.Insert("FillInArticleAttribute", FillInArticleAttribute);
	StructureOfActions.Insert("FillInProductTypeAttribute_", FillInProductTypeAttribute_);
	StructureOfActions.Insert("FillInMeasuredValueTypeAttribute", FillInMeasuredValueTypeAttribute);
	StructureOfActions.Insert("FillInFeatureAttribute", FillInFeatureAttribute);
	StructureOfActions.Insert("FillInSpaceUsageAttribute", FillInSpaceUsageAttribute);
	StructureOfActions.Insert("FillInAddressStorageAttribute", FillInAddressStorageAttribute);
	
	StructureOfActions.Insert("FillInDestinationType", FillingParametersByDestinationType());
	
	BatchProcessingOfTablePartServer.TreatTS(Object.Goods, StructureOfActions);
	
EndProcedure

&AtClient
Procedure RecalculateNumberOfEntries(CurrentData)
	
	CurrentRow = New Structure;
	CurrentRow.Insert("Products",       CurrentData.ProductsRecordingAsReceived);
	CurrentRow.Insert("Package",           CurrentData.PackagingReceipt);
	CurrentRow.Insert("Count",         CurrentData.CountRecordingAsReceived);
	CurrentRow.Insert("NumberOfPackages", CurrentData.NumberOfPackages);
	
	StructureOfActions = New Structure("RecalculateNumberOfUnits");
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
	CurrentData.CountRecordingAsReceived = CurrentRow.Count;
	
EndProcedure

&AtClient
Procedure GoodsProductsRecordingAsReceivedStartChoiceCompletion(Result, AdditionalParameters) Export
	
	Modified = True;
	
	FillInServiceDetailsOfProductItemRegistration(Result);
	
EndProcedure

&AtClient
Procedure FillInServiceDetailsOfProductItemRegistration(CurrentData)

	CurrentRow = New Structure;
	CurrentRow.Insert("Products", CurrentData.ProductsRecordingAsReceived);
	CurrentRow.Insert("ItemVariantsAreUsed");
	CurrentRow.Insert("Characteristic", CurrentData.CharacteristicRecordingAsReceived);
	CurrentRow.Insert("ItemsType", CurrentData.ItemTypePosting);
	CurrentRow.Insert("MeasuredValueType", CurrentData.TypeOfMeasuredValueEntry);
	CurrentRow.Insert("SKU", CurrentData.SKURegistration);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("CheckCharacteristicsByOwner", CurrentData.Characteristic);
	StructureOfActions.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));
	StructureOfActions.Insert("FillInMeasuredValueTypeAttribute", New Structure("Products", "MeasuredValueType"));
	StructureOfActions.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
	StructureOfActions.Insert("FillInFeatureAttribute", New Structure("Products", "ItemVariantsAreUsed"));
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, Undefined);
	
	CurrentData.ItemVariantsAreUsedRecordingAsReceived = CurrentRow.ItemVariantsAreUsed;
	CurrentData.CharacteristicRecordingAsReceived = CurrentRow.Characteristic;
	CurrentData.SKURegistration = CurrentRow.SKU;
	CurrentData.ItemTypePosting = CurrentRow.ItemsType;
	CurrentData.TypeOfMeasuredValueEntry = CurrentRow.MeasuredValueType;
	CurrentData.ItemVariantsAreUsedRecordingAsReceived = CurrentRow.ItemVariantsAreUsed;
	
	RecalculateNumberOfEntries(CurrentData);
	
EndProcedure

&AtClientAtServerNoContext
Function FillingParametersByDestinationType()
	
	FillParameters = AssignmentsClientServer.FillParameters();
	FillParameters.NameOfFieldToFillIn = "ForAssignment";
	FillParameters.Simple        = True;
	FillParameters.AssignmentType       = PredefinedValue("Enum.AssignmentTypes.Giveaway2_5");
	
	Return FillParameters;
	
EndFunction

&AtServerNoContext
Function ThereIsProductOfDifferentQuality(ProductOfOriginalQuality, NonconformingProducts)
	
	Return InformationRegisters.AnotherQualityGoods.CheckForGradation(ProductOfOriginalQuality, NonconformingProducts);
	
EndFunction

&AtClientAtServerNoContext
Procedure CheckClearAccountAttributes(TableRow)
	
	If TableRow.Action <> PredefinedValue("Enum.ActionsOnGoodsInQualityControlCertificate.ChangeQuality")
			And TableRow.Action <> PredefinedValue("Enum.ActionsOnGoodsInQualityControlCertificate.RegisterStockQualityChange") Then
		TableRow.ProductsRecordingAsReceived = PredefinedValue("Catalog.Products.EmptyRef");
		TableRow.CharacteristicRecordingAsReceived = PredefinedValue("Catalog.ItemsCharacteristics.EmptyRef");
		TableRow.ForAssignment = False;
		TableRow.PackagingReceipt = PredefinedValue("Catalog.PackagesAndUnitsOfMeasure.EmptyRef");
		TableRow.CountRecordingAsReceived = 0;
	EndIf;
	
EndProcedure

&AtServerNoContext
Function ReturnOfGoodsToSupplierIsAvailable(BusinessTransactionReceipts)
	
	BusinessOperation = PurchasesServer.GetRefundTransactionOnReceipt(
		BusinessTransactionReceipts);
	AllDocumentOperationsOfOperations = New ValueList();
	Documents.ReturnOfGoodsToVendor.FillInListOfBusinessOperations(AllDocumentOperationsOfOperations);
	Return AllDocumentOperationsOfOperations.FindByValue(BusinessOperation) <> Undefined;
	
EndFunction

&AtServerNoContext
Function RegistrationOfShipmentOfGoodsFromStorageIsAvailable(BusinessTransactionReceipts)
	
	BusinessOperation = PurchasesServer.GetRefundTransactionOnReceipt(
		BusinessTransactionReceipts);
	AllDocumentOperationsOfOperations = New ValueList();
	Documents.GoodsShipmentFromStorage.FillInListOfBusinessOperations(AllDocumentOperationsOfOperations);
	Return AllDocumentOperationsOfOperations.FindByValue(BusinessOperation) <> Undefined;
	
EndFunction

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
