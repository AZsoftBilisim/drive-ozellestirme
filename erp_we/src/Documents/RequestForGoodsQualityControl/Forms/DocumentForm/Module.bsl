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
	InitializationOfFillingSettingsByBalances(
		"FillingSchemeByBalances",
		AddressOfSchemeSettingUpBalanceFilling,
		FillingSettingsByBalance);

	
	InfobaseUpdate.CheckObjectProcessed(Object, ThisObject);
	
	TMCommonUse.CustomizePeripherals(ThisObject);
	Items.GoodsIssueStudy.Enabled = AccessRight("Insert",
		Metadata.Documents.GoodsQualityResearch);
	Items.IssueControlReport.Enabled = AccessRight("Insert",
		Metadata.Documents.GoodsQualityControlCertificate);
	
	If Parameters.FillInByBalance Then
		
		Analysts = GetFromTempStorage(Parameters.Analysts);
		Object.Goods.Load(QualityControl.AnalystBalances(Analysts, True, CurrentSessionDate()));
		FillCleanWarehouseRoomAccordingToTabularPartOfDocument();
		Object.Organization = Documents.RequestForGoodsQualityControl.CompanyFromControlledLotReference(Object);
		FillPropertyValues(Object, Parameters.FillingData);
		
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
	SetState();
	FillInArticleAttribute = New Structure("Products", "SKU");
	FillInProductTypeAttribute_ = New Structure("Products", "ItemsType");
	FillInMeasuredValueTypeAttribute = New Structure("Products", "MeasuredValueType");
	FillInFeatureAttribute = New Structure("Products", "ItemVariantsAreUsed");
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
Procedure ToScheduleGoodsUnlockOnChange(Item)
	If Not Object.ToScheduleGoodsUnlock Then
		Object.QualityConfirmationDate = '00010101';
	EndIf;
	SetAvailabilityDateOfQualityConfirmationOnClient();
EndProcedure

&AtClient
Procedure ReasonForGoodsLockOnChange(Item)
	
	ReasonForGoodsLockOnChangeServer();
	SetAvailabilityDateOfQualityConfirmationOnClient();
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersGoods

&AtClient
Procedure GoodsProductsOnChange(Item)
	
	TableRow = Items.Goods.CurrentData;
	
	FillInArticleAttribute = New Structure("Products", "SKU");
	FillInProductTypeAttribute_ = New Structure("Products", "ItemsType");
	FillInMeasuredValueTypeAttribute = New Structure("Products", "MeasuredValueType");
	FillInFeatureAttribute = New Structure("Products", "ItemVariantsAreUsed");
	CheckSeriesCalculateStatus = New Structure("Warehouse,SeriesSpecificationParameters",
		TableRow.Warehouse, SeriesSpecificationParameters);
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
	
EndProcedure

&AtClient
Procedure GoodsNumberOfPackagesOnChange(Item)
	
	TableRow = Items.Goods.CurrentData;
	StructureOfActions = New Structure();
	StructureOfActions.Insert("RecalculateNumberOfUnits");
	
	BatchProcessingOfTablePartClient.ProcessTSString(TableRow, StructureOfActions, CachedValues);
	
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
	
	If Object.ReasonForGoodsLock = PredefinedValue("Catalog.GoodsLockReasons.InputQualityControlOfGoods") Then
		Address = AddressOfSchemeSettingUpFillingByBatchBalance;
		Settings = FillingSettingsForBatchBalances;
	Else
		Address = AddressOfSchemeSettingUpBalanceFilling;
		Settings = FillingSettingsByBalance;
	EndIf;
	
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
				FoundItem.Use = True;
			EndIf;
		EndDo;
	EndIf;
	FormParameters.Insert("ListSettings", Settings);
	FormParameters.Insert("Title", NStr("vi = 'Điền theo tồn kho của hàng hóa bị khóa';
										|ru = 'Заполнение по остаткам заблокированных товаров';
										|en = 'Fill in by locked goods balance'; fa = 'Fill in by locked goods balance';
										|it = 'Fill in by locked goods balance';
										|pl = 'Fill in by locked goods balance';
										|tr = 'Kilitli ürünlerin bakiyelerine göre doldurma'"));
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
Procedure FillInControlledLotReference(Command)
	
	If Not ThereAreLinesToExecuteCommand(NStr("vi = '""Lô hàng được kiểm soát""';
												|ru = '""Контролируемая партия""';
												|en = '""Controlled lot""'; fa = '""Controlled lot""';
												|it = '""Controlled lot""';
												|pl = '""Controlled lot""';
												|tr = 'Kontrole tabi lot'")) Then
		Return;
	EndIf;
	
	CallbackDescription = New CallbackDescription(
		"FillInControlledLotReferenceAfterSelection",
		ThisObject);
	
	FormParameters = QualityControlClient.NewSelectionFormParametersControlledBatches();
	FormParameters.Source = "Document.RequestForGoodsQualityControl";
	FormParameters.Insert("Filter", New Structure("DeletionMark", False));
	OpenForm(
		"Catalog.ControlledLots.Form.ChoiceForm",
		FormParameters,
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
Procedure IssueStudy(Command)
	ClearMessages();
	If Not Object.Posted Or Modified Then

		Buttons = New ValueList;
		Buttons.Add(DialogReturnCode.Yes, NStr("vi = 'Kết chuyển và tiếp tục';
												|ru = 'Провести и продолжить';
												|en = 'Post and continue'; fa = 'Post and continue';
												|it = 'Pubblicare e continuare';
												|pl = 'Zatwierdzić i kontynuować';
												|tr = 'Kaydet ve devam et'"));
		Buttons.Add(DialogReturnCode.Cancel);

		QueryText = NStr("vi = 'Để đến nơi làm việc ""Chỉ định nghiên cứu"", cần kết chuyển chứng từ.';
						|ru = 'Для перехода в рабочее место ""Назначение исследований"" необходимо провести документ.';
						|en = 'To go to the ""Assignment of research"" workspace, post the document.'; fa = 'To go to the ""Assignment of research"" workspace, post the document.';
						|it = 'To go to the ""Assignment of research"" workspace, post the document.';
						|pl = 'To go to the ""Assignment of research"" workspace, post the document.';
						|tr = '""İnceleme Atama"" çalışma alanına geçmek için belgenin kaydedilmesi gerekir.'");

		CallbackDescription = New CallbackDescription("OpenIssueStudyEnd", ThisObject);
		ShowQueryBox(CallbackDescription, QueryText, Buttons);

	Else

		OpenResearchAssignment();

	EndIf;
	Return;
	
EndProcedure

&AtClient
Procedure IssueControlReport(Command)
	ClearMessages();
	If Not Object.Posted Or Modified Then

		Buttons = New ValueList;
		Buttons.Add(DialogReturnCode.Yes, NStr("vi = 'Kết chuyển và tiếp tục';
												|ru = 'Провести и продолжить';
												|en = 'Post and continue'; fa = 'Post and continue';
												|it = 'Pubblicare e continuare';
												|pl = 'Zatwierdzić i kontynuować';
												|tr = 'Kaydet ve devam et'"));
		Buttons.Add(DialogReturnCode.Cancel);

		QueryText = NStr("vi = 'Để lập ""Biên bản kiểm soát"", cần phải kết chuyển chứng từ.';
						|ru = 'Для оформления ""Акта контроля"" необходимо провести документ.';
						|en = 'To issue a control certificate, post the document.'; fa = 'To issue a control certificate, post the document.';
						|it = 'To issue a control certificate, post the document.';
						|pl = 'To issue a control certificate, post the document.';
						|tr = '""Kontrol Tutanağı"" düzenlemek için belgenin kaydedilmesi gerekir.'");

		CallbackDescription = New CallbackDescription("OpenIssueControlReportEnd", ThisObject);
		ShowQueryBox(CallbackDescription, QueryText, Buttons);

	Else

		OpenQualityControlReport();

	EndIf;
	Return;
	
EndProcedure

&AtClient
Procedure SetQualityConfirmed(Command)
	
	If Not ThereAreLinesToExecuteCommand(NStr("vi = 'Chất lượng được xác nhận""';
												|ru = '""Качество подтверждаю""';
												|en = '""Quality confirmed""'; fa = '""Quality confirmed""';
												|it = '""Quality confirmed""';
												|pl = '""Quality confirmed""';
												|tr = '""Kaliteyi onaylıyorum""'")) Then
		Return;
	EndIf;
	
	FillInQualityConfirmedServer(True);
	
EndProcedure


&AtClient
Procedure RemoveQualityIsConfirmed(Command)
	
	If Not ThereAreLinesToExecuteCommand(NStr("vi = 'Chất lượng được xác nhận""';
												|ru = '""Качество подтверждаю""';
												|en = '""Quality confirmed""'; fa = '""Quality confirmed""';
												|it = '""Quality confirmed""';
												|pl = '""Quality confirmed""';
												|tr = '""Kaliteyi onaylıyorum""'")) Then
		Return;
	EndIf;
	
	FillInQualityConfirmedServer(False);
	
EndProcedure

#EndRegion

#Region Private

#Region VisibilityManagement

&AtServer
Procedure SetVisibilityOfControlledLotReferenceColumn()
	
	ThisIsInputControl = Object.ReasonForGoodsLock = Catalogs.GoodsLockReasons.InputQualityControlOfGoods;
	Items.GoodsControlledLotReference.Visible = ThisIsInputControl;
	Items.FillInControlledLotReference.Visible = ThisIsInputControl;
	
EndProcedure

&AtServer
Procedure SetConditionalAppearance()
	
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
	
	// Items.Series.
	
	ProductsServer.EstablishConditionalAppearanceOfProductSeries(ThisObject, "SeriesAlwaysWHGoods");
	
	// Items.Characteristics.
	
	ProductsServer.EstablishConditionalAppearanceOfProductCharacteristics(ThisObject, "GoodsCharacteristic");
	
	// Goods.Units of measurement.
	
	ConditionalDesignParameters = ProductsServer.NewParametersForConditionalDesignOfUnitsOfMeasurement(True, True);
	ConditionalDesignParameters.PathToFieldUseBinLocationSystem = "Object.Goods.UseBinLocationWarehousing";
	ProductsServer.SetConditionalAppearanceOfUnitsOfMeasurement(ThisObject, ConditionalDesignParameters);
	
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
	
EndProcedure

&AtServer
Procedure EstablishVisibilityOfGoodsQualityResearchElements()

	UseGoodsQualityResearch = GoodsResearchIsIncluded();
	Items.State.Visible = UseGoodsQualityResearch;
	Items.IssueControlReport.Visible = UseGoodsQualityResearch;
	Items.GoodsIssueStudy.Visible = UseGoodsQualityResearch;

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
		|ControlledLotReference,
		|Series,
		|Warehouse,
		|Premise,
		|Cell,
		|Package,
		|NumberOfPackages,
		|QualityIsConfirmed";
	
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
		RowsToProcess.Add(TableRow);
		
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
		
	EndIf;
	
EndProcedure

&AtClient
Procedure FillInControlledLotReferenceAfterSelection(ValueSelected, AdditionalParameters) Export
	
	If ValueSelected = Undefined Then
		Return;
	EndIf;
	FillInControlledLotReferenceAfterSelectionServer(ValueSelected);
	
EndProcedure

&AtServer
Procedure FillInControlledLotReferenceAfterSelectionServer(ValueSelected)
	
	For Each Id In Items.Goods.SelectedRows Do
		
		Object.Goods.FindByID(Id).ControlledLotReference = ValueSelected;
		
	EndDo;
	
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
	
	Schema = Documents.RequestForGoodsQualityControl.GetTemplate(Schema_Name);
	Address = PutToTempStorage(Schema, UUID);
	Settings.Initialize(New DataCompositionAvailableSettingsSource(Address));
	Settings.LoadSettings(Schema.DefaultSettings);
	
EndProcedure

&AtServer
Procedure FillInByBalanceServer(Val SettingsComposer)
	
	If Object.ReasonForGoodsLock = PredefinedValue("Catalog.GoodsLockReasons.InputQualityControlOfGoods") Then
		Schema_Name = "FillingSchemeByLotBalances";
		Settings = FillingSettingsForBatchBalances;
		FillInWithGoodsOfProvenQuality = False;
	Else
		Schema_Name = "FillingSchemeByBalances";
		Settings = FillingSettingsByBalance;
		FillInWithGoodsOfProvenQuality = True;
	EndIf;
	
	Object.Goods.Clear();
	Settings.LoadSettings(SettingsComposer.GetSettings());
	Settings.LoadUserSettings(SettingsComposer.UserSettings);
	
	DataCompositionSchema = Documents.RequestForGoodsQualityControl.GetTemplate(Schema_Name);
	CompositionSettings = Settings.GetSettings();
	CompositionSettings.DataParameters.Items.Find("Recorder").Value = Object.Ref;
	TemplateComposer = New DataCompositionTemplateComposer;
	CompositionTemplate = TemplateComposer.Execute(DataCompositionSchema,
		CompositionSettings, , , Type("DataCompositionValueCollectionTemplateGenerator"));
	CompositionProcessor = New DataCompositionProcessor;
	CompositionProcessor.Initialize(CompositionTemplate);
	OutputProcessor = New DataCompositionResultValueCollectionOutputProcessor;
	Analysts = OutputProcessor.Output(CompositionProcessor);
	QualityControl.AddColumnsDisabledByFOToAnalystTable(Analysts);
	Object.Goods.Load(
		QualityControl.AnalystBalances(
			Analysts,
			True,
			Object.Date,
			Object.Ref,
			FillInWithGoodsOfProvenQuality));
	ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);
	
	ClearWarehouseRoomIfThereAreSeveralOfThem();
	
	SetVisibilityOfWarehouseAndPremises();
	FillInServiceAttributesWhenFillingOutTablePart();
	
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

&AtServer
Procedure FillInQualityConfirmedServer(ValueSelected)
	
	For Each Id In Items.Goods.SelectedRows Do
		
		Object.Goods.FindByID(Id).QualityIsConfirmed = ValueSelected;
		
	EndDo;
	
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
Procedure ReasonForGoodsLockOnChangeServer()
	
	SetVisibilityOfControlledLotReferenceColumn();
	If Object.ReasonForGoodsLock = Catalogs.GoodsLockReasons.InputQualityControlOfGoods Then
		
		Object.ToScheduleGoodsUnlock = True;
		
	Else
		
		EmptyBatch = Catalogs.ControlledLots.EmptyRef();
		For Each TableRow In Object.Goods Do
			TableRow.ControlledLotReference = EmptyBatch;
		EndDo;
		
		Texts = New Array();
		Text = ProvisionInDocumentsServer.TempTableYearsOfEnterpriseSchedule();
		Texts.Add(Text);
		
		Text =
			"SELECT
			|	ReasonsForBlocking.ToScheduleGoodsUnlock AS ToScheduleGoodsUnlock,
			|	DateCalculation.DateFound AS QualityConfirmationDate
			|FROM
			|	Catalog.GoodsLockReasons AS ReasonsForBlocking
			|		LEFT JOIN DateCalculation ON TRUE
			|WHERE
			|	ReasonsForBlocking.Ref = &Ref";
		
		Substitutions = ProvisionInDocumentsServer.AddToDateAccordingToEnterpriseCalendar(
			"&Date",
			"ReasonsForBlocking.QualityControlDuration");
		
		Text = StrReplace(Text, "DateCalculation.DateFound", Substitutions.Field);
		Text = StrReplace(Text, "LEFT JOIN DateCalculation ON TRUE", Substitutions.Joins);
		
		Texts.Add(Text);
		
		Query = New Query();
		Query.Text = StrConcat(Texts, Common.QueryBatchSeparator());
		Query.SetParameter("Date", BegOfDay(?(ValueIsFilled(Object.Date), Object.Date, CurrentSessionDate())));
		Query.SetParameter("Ref", Object.ReasonForGoodsLock);
		Selection = Query.Execute().Select();
		
		Object.ToScheduleGoodsUnlock = False;
		Object.QualityConfirmationDate = '00010101';
		
		If Selection.Next() Then
			
			Object.ToScheduleGoodsUnlock = Selection.ToScheduleGoodsUnlock;
			If Selection.ToScheduleGoodsUnlock Then
				Object.QualityConfirmationDate = Selection.QualityConfirmationDate;
			EndIf;
		
		EndIf;
		
	EndIf;
	
EndProcedure

&AtServer
Procedure WhenChangingWarehouseServer()
	
	SetVisibilityOfWarehouseAndPremises();
	
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

&AtServer
Procedure SetVisibilityOfWarehouseAndPremises()
	
	UseWarerooms = WarehousesServer.UseWarerooms(Object.Warehouse, Object.Date)
		And ValueIsFilled(Object.Warehouse);
	Items.Premise.Visible = UseWarerooms;
	Items.GoodsWarehouse.Visible = Not ValueIsFilled(Object.Warehouse);
	Items.GoodsPremise.Visible = Not ValueIsFilled(Object.Warehouse)
		Or Not ValueIsFilled(Object.Premise) And UseWarerooms;
	
EndProcedure

&AtClient
Procedure SetAvailabilityDateOfQualityConfirmationOnClient()
	Items.QualityConfirmationDate.Enabled = Object.ToScheduleGoodsUnlock;
EndProcedure

&AtServer
Procedure SetAvailabilityDateOfQualityConfirmationAtServer()
	Items.QualityConfirmationDate.Enabled = Object.ToScheduleGoodsUnlock;
EndProcedure

#EndRegion
#Region Research

&AtClient
Procedure OpenIssueStudyEnd(QuestionResult, AdditionalParameters) Export
	
	If QuestionResult <> DialogReturnCode.Yes Then
		Return;
	EndIf;
	
	WriteParameters = New Structure;
	WriteParameters.Insert("WriteMode", DocumentWriteMode.Posting);
	WriteParameters.Insert("PostingMode", DocumentPostingMode.Regular);
	WriteParameters.Insert("NewObject", Not ValueIsFilled(Object.Ref));
	
	If Write(WriteParameters) Then
		OpenResearchAssignment();
	EndIf;
	
EndProcedure

&AtClient
Procedure OpenIssueControlReportEnd(QuestionResult, AdditionalParameters) Export
	
	If QuestionResult <> DialogReturnCode.Yes Then
		Return;
	EndIf;
	
	WriteParameters = New Structure;
	WriteParameters.Insert("WriteMode", DocumentWriteMode.Posting);
	WriteParameters.Insert("PostingMode", DocumentPostingMode.Regular);
	WriteParameters.Insert("NewObject", Not ValueIsFilled(Object.Ref));
	
	If Write(WriteParameters) Then
		OpenQualityControlReport();
	EndIf;
	
EndProcedure

&AtClient
Procedure OpenResearchAssignment()
	
	SelectedRows = Items.Goods.SelectedRows;
	
	If SelectedRows.Count() = 0 Then
		ShowMessageBox(, NStr("vi = 'Chưa chọn dòng nào, lệnh không thể thực hiện.';
								|ru = 'Не выбраны строки, команда не может быть выполнена.';
								|en = 'No lines are selected, cannot run the command.'; fa = 'No lines are selected, cannot run the command.';
								|it = 'No lines are selected, cannot run the command.';
								|pl = 'No lines are selected, cannot run the command.';
								|tr = 'atır seçilmedi, komut gerçekleştirilemez.'"));
		Return;
	EndIf;
	
	LinesForPurposeOfResearch = New Array;
	For Each Id In SelectedRows Do
		TableRow = Object.Goods.FindByID(Id);
		If Not TableRow.QualityIsConfirmed Then
			LinesForPurposeOfResearch.Add(Id);
		EndIf;
	EndDo;
	
	If LinesForPurposeOfResearch.Count() = 0 Then
		ShowMessageBox(, NStr("ru = 'Для выбранных строк качество уже подтверждено, не требуется назначение исследований.';
								|vi = 'For the selected lines, the quality is already confirmed, no research is required.';
								|en = 'For the selected lines, the quality is already confirmed, no research is required.'; fa = 'For the selected lines, the quality is already confirmed, no research is required.';
								|it = 'For the selected lines, the quality is already confirmed, no research is required.';
								|pl = 'For the selected lines, the quality is already confirmed, no research is required.';
								|tr = 'Seçilen satırlar için kalite onaylandı, inceleme ataması gerekmiyor.'"));
		Return;
	EndIf;
	
	FormParameters = New Structure;
	FormParameters.Insert("RequestForControl", Object.Ref);
	FormParameters.Insert("AllRows", False);
	GoodsList = TableOfSelectedRowsInArrayOfStructures(LinesForPurposeOfResearch,
		GoodsResearchClient.AttributesOfGoodsLineOfQualityControlRequest());
	FormParameters.Insert("GoodsList", GoodsList);
	OpenForm("Document.GoodsQualityResearch.Form.GenerationWizard", FormParameters, ThisObject);

EndProcedure

// Converts selected rows from a table into an array of structures.
//
// Parameters:
//   SelectedRows - Array of Number - Selected table rows
//   AttributesList - String - Comma-separated list of Attributes
// Returns:
// 	Array of Structure:
//   * Fields - Arbitrary - The fields correspond to the columns passed in the list of requests.
&AtServer
Function TableOfSelectedRowsInArrayOfStructures(SelectedRows, AttributesList)

	Result = New Array;
	
	For Each Id In SelectedRows Do

		String = Object.Goods.FindByID(Id);
		StringStructure = New Structure(AttributesList);
		FillPropertyValues(StringStructure, String);
		StringStructure.ProductKind = Common.ObjectAttributeValue(String.Products, "ProductKind");
		StringStructure.UnitOfMeasure = Common.ObjectAttributeValue(String.Products, "UnitOfMeasure");
		Result.Add(StringStructure);

	EndDo;

	Return Result;

EndFunction

&AtClient
Procedure OpenQualityControlReport()
	
	FormParameters = GetParametersOfQualityControlReportForm();
	If FormParameters <> Undefined Then
		OpenForm("Document.GoodsQualityControlCertificate.Form.DocumentForm", FormParameters);
	EndIf;

EndProcedure

&AtClient
Function GetParametersOfQualityControlReportForm()
	
	ListOfStudies = New Array;
	State = CalculateStateOfControlApplication(Object.Ref);
	
	If State = PredefinedValue("Enum.StatesOfResearchRequests.PendingResearch") Then
		ShowMessageBox(, NStr("vi = 'Chưa chỉ định nghiên cứu, lệnh không thể thực hiện.';
								|ru = 'Исследования не назначены, команда не может быть выполнена.';
								|en = 'The research is not assigned. Cannot run the command.'; fa = 'The research is not assigned. Cannot run the command.';
								|it = 'The research is not assigned. Cannot run the command.';
								|pl = 'The research is not assigned. Cannot run the command.';
								|tr = 'İncelemeler atanmamış, komut gerçekleştirilemez.'"));
		Return Undefined;
	EndIf;
	
	If State= PredefinedValue("Enum.StatesOfResearchRequests.InResearchProcess") Then
		ShowMessageBox(, NStr("vi = 'Chưa hoàn thành tất cả các nghiên cứu, lệnh không thể thực hiện.';
								|ru = 'Не все исследования завершены, команда не может быть выполнена.';
								|en = 'Not all the research is done. Cannot run the command.'; fa = 'Not all the research is done. Cannot run the command.';
								|it = 'Not all the research is done. Cannot run the command.';
								|pl = 'Not all the research is done. Cannot run the command.';
								|tr = 'Tüm incelemeler tamamlanmamış, komut gerçekleştirilemez.'"));
		Return Undefined;
	EndIf;
	
	ListOfStudies = ListOfStudiesWithCompletedQualityControlCertificates(Object.Ref);
	If ListOfStudies.Count() = 0 Then
		ShowMessageBox(, NStr("vi = 'Không có nghiên cứu nào để lập chứng từ kiểm soát, lệnh không thể thực hiện.';
								|ru = 'Нет исследований для оформления акта контроля, команда не может быть выполнена.';
								|en = 'There is no research to register the control certificate. Cannot run the command.'; fa = 'There is no research to register the control certificate. Cannot run the command.';
								|it = 'There is no research to register the control certificate. Cannot run the command.';
								|pl = 'There is no research to register the control certificate. Cannot run the command.';
								|tr = 'Kontrol tutanağı düzenlemek için inceleme yok, komut gerçekleştirilemez.'"));
		Return Undefined;
	EndIf;
	
	FillingData = New Structure;
	FillingData.Insert("DocumentBasis", Object.Ref);
	FillingData.Insert("AccordingToResearchDocuments", ListOfStudies);
	
	FormParameters = New Structure("Basis", FillingData);
	
	Return FormParameters;
	
EndFunction

&AtServerNoContext
Function ListOfStudiesWithCompletedQualityControlCertificates(RequestForControl)
	
	ListOfStudies = GoodsResearch.ListOfStudiesOnApplicationForControl(RequestForControl);

	ListOfStudiesWithCompletedCertificates = GoodsResearch.ListOfStudiesWithCompletedQualityControlCertificates(
		ListOfStudies, RequestForControl);
	
	Return CommonClientServer.ArraysDifference(ListOfStudies, ListOfStudiesWithCompletedCertificates);

EndFunction

&AtServerNoContext
Function CalculateStateOfControlApplication(RequestForControl)
	Return GoodsResearch.CalculateStateOfControlApplication(RequestForControl);
EndFunction

#EndRegion

#Region OtherItems

&AtServer
Function GoodsResearchIsIncluded()
	
	UseResearch = False;
	UseResearch = GetFunctionalOption("UseGoodsQualityResearch");
	Return UseResearch;
	
EndFunction

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
	Notify("Write_RequestForGoodsQualityControl", NotificationProcessingParameter, Object.Ref);
	
EndProcedure

&AtServer
Procedure OnReadCreateAtServer()
	
	// Visibility management.
	SetConditionalAppearance();
	Items.BaseGroup_.Visible = ValueIsFilled(Object.DocumentBasis);
	Items.GoodsIssueStudy.Enabled = AccessRight("Insert",
		Metadata.Documents.GoodsQualityResearch);
	CurParametersForSpecifyingSeries = ProductsServer.SeriesSpecificationParameters(
		Object,
		Documents.RequestForGoodsQualityControl);
	SeriesSpecificationParameters = New FixedStructure(CurParametersForSpecifyingSeries);
	
	SetVisibilityOfWarehouseAndPremises();
	SetAvailabilityDateOfQualityConfirmationAtServer();
	SetVisibilityOfControlledLotReferenceColumn();
	FillInServiceAttributesWhenFillingOutTablePart();
	
	EstablishVisibilityOfGoodsQualityResearchElements();
	SetState();
EndProcedure

&AtServer
Procedure FillInServiceAttributesWhenFillingOutTablePart()
	
	FillInArticleAttribute = New Structure("Products", "SKU");
	FillInProductTypeAttribute_ = New Structure("Products", "ItemsType");
	FillInMeasuredValueTypeAttribute = New Structure("Products", "MeasuredValueType");
	FillInFeatureAttribute = New Structure("Products", "ItemVariantsAreUsed");
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
	
EndProcedure
&AtServer
Procedure SetState()
	
	Documents.RequestForGoodsQualityControl.CalculateStatus(Object.Ref, ThisObject);
	
EndProcedure
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
