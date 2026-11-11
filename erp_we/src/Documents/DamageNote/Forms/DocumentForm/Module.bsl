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
	
	TMCommonUse.CustomizePeripherals(ThisForm);
	
	If Not ValueIsFilled(Object.Ref) Then
		OnReadCreateAtServer();
		ProductsServer.FillInStatusesForSpecifyingSeries(Object,SeriesSpecificationParameters);
	EndIf;
	
	Items.GoodsSearchByBarcode.Visible = AccessRight("Read", Metadata.InformationRegisters.ItemsBarcodes);
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	
	// Handler of the "Destination" mechanism
	Catalogs.Assignments.DocumentFormWhenCreatedOnServer(ThisForm);
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject);
	// End IntegrationWith1CDocumentManagementSubsystem
	
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	
	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)

	// StandardSubsystems.AccessManagement
	AccessManagement.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.AccessManagement
	
	// Handler of the "Date-change" mechanism
	PeriodClosingDates.ObjectOnReadAtServer(ThisForm, CurrentObject);
	OnReadCreateAtServer();

	ConfigurationModificationOverridable.OnReadAtServer(ThisForm, CurrentObject);
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	// End StandardSubsystems.AttachableCommands
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)

	// StandardSubsystems.AccessManagement
	AccessManagement.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	// End StandardSubsystems.AccessManagement
	
	FillInServiceDetailsForProductRange();
	
	AssignmentsServer.FillInDestinationTypeInTable(Object.Goods);
	
	ProvisionInDocumentsServer.CheckToRunBackgroundInventoryAllocationJob();
	
	ConfigurationModificationOverridable.AfterWriteAtServer(ThisForm, CurrentObject, WriteParameters);

EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	
	Notify("Write_GoodsShortageNote", WriteParameters, Object.Ref);

	ConfigurationModificationClientOverridable.AfterWrite(ThisForm, WriteParameters);

	// StandardSubsystems.AttachableCommands
	If CommonClient.SubsystemExists("StandardSubsystems.AttachableCommands") Then
		ModuleAttachableCommandsClient = CommonClient.CommonModule("AttachableCommandsClient");
		ModuleAttachableCommandsClient.AfterWrite(ThisObject, Object, WriteParameters);
	EndIf;
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	EquipmentManagerClient.StartConnectingDevicesWhenYouOpenForm(Undefined, ThisForm, "BarcodeScanner");
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands
EndProcedure

&AtClient
Procedure OnClose(Exit)
	
	EquipmentManagerClient.StartDisablingHardwareWhenClosingForm(Undefined, ThisForm);
	
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
	
EndProcedure

&AtClient
Procedure ChoiceProcessing(SelectionResult, ChoiceSource)
	
	If ProductsClient.ThisIsIndicationOfSeries(ChoiceSource) Then
		ProductsClient.ProcessSeriesIndication(ThisForm, SeriesSpecificationParameters, SelectionResult);
	ElsIf ChoiceSource.FormName = "Catalog.Assignments.Form.ChoiceForm" Then			
		
		CurrentData = Items.Goods.CurrentData;
		CurrentData.Purpose = SelectionResult;
		
		StructureOfActions = New Structure;
		StructureOfActions.Insert("FillInDestinationType", FillingParametersByDestinationType());
		
		BatchProcessingOfTablePartClient.ProcessTSString(CurrentData, StructureOfActions, Undefined);
		
	EndIf;
	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)

	ConfigurationModificationOverridable.BeforeWriteAtServer(ThisForm, Cancel, CurrentObject, WriteParameters);

	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.BeforeWriteAtServer(
		ThisObject,
		CurrentObject,
		WriteParameters);
	// End IntegrationWith1CDocumentManagementSubsystem
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure WarehouseOnChange(Item)
	
	WhenChangingWarehousePremisesDate();
	
EndProcedure

&AtClient
Procedure PremiseOnChange(Item)
	
	WhenChangingWarehousePremisesDate();
	
EndProcedure

&AtClient
Procedure DateOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	
	WhenChangingWarehousePremisesDate();
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersGoods

&AtClient
Procedure GoodsProductsOnChange(Item)
	
	Var CurrentRow;
	Var StructureOfActions;
	
	CurrentRow = Items.Goods.CurrentData;
	
	If ValueIsFilled(CurrentRow.ProductsRecordingAsReceived) Then
		ThereIsGradation = ThereIsProductOfDifferentQuality(CurrentRow.Products, CurrentRow.ProductsRecordingAsReceived);
		If Not ThereIsGradation Then
			CurrentRow.ProductsRecordingAsReceived = PredefinedValue("Catalog.Products.EmptyRef");
			CurrentRow.CharacteristicRecordingAsReceived = PredefinedValue("Catalog.ItemsCharacteristics.EmptyRef");
			CurrentRow.ItemVariantsAreUsedRecordingAsReceived = False;
			CurrentRow.PackagingReceipt = PredefinedValue("Catalog.PackagesAndUnitsOfMeasure.EmptyRef");
		EndIf;
	EndIf;
	
	FillInArticleAttribute                  = New Structure("Products, ProductsRecordingAsReceived",
												"SKU", "SKURegistration");
	FillInProductTypeAttribute_          = New Structure("Products, ProductsRecordingAsReceived",
												"ItemsType", "ItemTypePosting");
	CheckSeriesCalculateStatus           = New Structure("Warehouse, SeriesSpecificationParameters",
												Object.Warehouse, SeriesSpecificationParameters);
	FillInMeasuredValueTypeAttribute    = New Structure("Products, ProductsRecordingAsReceived",
												"MeasuredValueType", "TypeOfMeasuredValueEntry");
	FillPackageWeight                     = New Structure("Products, Package", "PackageWeight");
	FillPackageVolume                   = New Structure("Products, Package", "PackageVolume");
	FillInUnitOfWeight            = New Structure("Products, Package", "UnitOfMeasureForWeight");
	FillInVolumeUnit          = New Structure("Products, Package", "UnitOfMeasureForVolume");
	ProductsOnChangeOverridable = New Structure("FormName, TabularSectionName",
												ThisForm.FormName, "Goods");
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("CheckCharacteristicsByOwner", CurrentRow.Characteristic);
	StructureOfActions.Insert("FillInProductTypeAttribute_",    FillInProductTypeAttribute_);
	StructureOfActions.Insert("FillInArticleAttribute",            FillInArticleAttribute);
	If UseBinLocationWarehousing Then
		StructureOfActions.Insert("CheckFillPackageByOwner" , CurrentRow.Package);
	EndIf;
	StructureOfActions.Insert("CheckSeriesCalculateStatus",        CheckSeriesCalculateStatus);
	StructureOfActions.Insert("FillInMeasuredValueTypeAttribute", FillInMeasuredValueTypeAttribute);
	StructureOfActions.Insert("FillPackageWeight",                  FillPackageWeight);
	StructureOfActions.Insert("FillPackageVolume",                FillPackageVolume);
	StructureOfActions.Insert("FillInUnitOfWeight",         FillInUnitOfWeight);
	StructureOfActions.Insert("FillInVolumeUnit",       FillInVolumeUnit);
	StructureOfActions.Insert("RecalculateWeightVolume");
	StructureOfActions.Insert("RecalculateNumberOfUnits");
	StructureOfActions.Insert("CheckFillAssignment");
	
	StructureOfActions.Insert("FillInDestinationType", FillingParametersByDestinationType());
	
	StructureOfActions.Insert("ProductsOnChangeOverridable", ProductsOnChangeOverridable);
	
	StructureOfActions.Insert("RecalculateNumberOfPackages");
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
	RecalculateNumberOfEntries(CurrentRow);
	
EndProcedure

&AtClient
Procedure GoodsPackageOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillPackageWeight",New Structure("Products, Package", "PackageWeight"));
	StructureOfActions.Insert("FillPackageVolume",New Structure("Products, Package", "PackageVolume"));
	StructureOfActions.Insert("FillInUnitOfWeight",New Structure("Products, Package", "UnitOfMeasureForWeight"));
	StructureOfActions.Insert("FillInVolumeUnit",New Structure("Products, Package", "UnitOfMeasureForVolume"));
	StructureOfActions.Insert("RecalculateNumberOfPackages");
	StructureOfActions.Insert("RecalculateWeightVolume");
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
	If ValueIsFilled(CurrentRow.ProductsRecordingAsReceived) Then
		
		LowQualityProductData = New Structure("ProductsOfOriginalQuality, Products, Package", 
			CurrentRow.Products, CurrentRow.ProductsRecordingAsReceived, CurrentRow.Package);
		
		StructureOfActionsWithLowQualityGoods = New Structure;
		StructureOfActionsWithLowQualityGoods.Insert("CheckFillPackageByOwner", CurrentRow.Package);
		StructureOfActionsWithLowQualityGoods.Insert("FillInPackagingOfLowQualityGoods", CurrentRow.Package);
		
		BatchProcessingOfTablePartClient.ProcessTSString(LowQualityProductData, StructureOfActionsWithLowQualityGoods, Undefined);
		CurrentRow.PackagingReceipt = LowQualityProductData.Package;
		
	EndIf;
	
	RecalculateNumberOfEntries(CurrentRow);
	
EndProcedure

&AtClient
Procedure GoodsNumberOfPackagesDiscrepancyOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;
	
	StructureOfActions = New Structure;
	AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions);
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
	RecalculateNumberOfEntries(CurrentRow);
	
EndProcedure

&AtClient
Procedure GoodsProductsRecordingAsReceivedStartChoice(Item, ChoiceData, StandardProcessing)
	
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
Procedure GoodsProductsRecordingAsReceivedStartChoiceCompletion(Result, AdditionalParameters) Export
	
	Modified = True;
	
	FillInServiceDetailsOfProductItemRegistration(Result);
	
EndProcedure

&AtClient
Procedure GoodsProductsRecordingAsReceivedOnChange(Item)
	
	StandardProcessing = False;
	
	CurrentData = Items.Goods.CurrentData;
	
	FillInServiceDetailsOfProductItemRegistration(CurrentData);
	
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
	
	If CurrentData <> Undefined And Not ValueIsFilled(CurrentData.Purpose) Then
		CurrentData.ForAssignment = False;
	EndIf;
EndProcedure

&AtClient
Procedure GoodsPackagingReceiptOnChange(Item)
	
	CurrentData = Items.Goods.CurrentData;
	
	RecalculateNumberOfEntries(CurrentData);
	
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
		CurrentRow.NumberOfPackages = ExecutionResult.Weight;
		
		StructureOfActions = New Structure;
		AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions);
		
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
Procedure DownloadFromTSDCompletion(ExecutionResult, Var_Parameters) Export
	
	If ExecutionResult.Result Then
		ProcessBarcodes(ExecutionResult.TableOfGoods);
	Else
		EquipmentManagerTMClient.ReportError(ExecutionResult);
	EndIf;
	
EndProcedure

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
	
	Notification = New CallbackDescription("SplitRowCompletion", ThisObject);
	ProcessingOfTabularFormsClient.SplitRow(TableData, FormTable, Notification);
	
EndProcedure

&AtClient
Procedure SplitRowCompletion(NewRow, AdditionalParameters) Export 
	
	CurrentRow = Items.Goods.CurrentData;
	
	If NewRow <> Undefined Then
		
		StructureOfActions = New Structure;
		AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions);
		
		BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
		BatchProcessingOfTablePartClient.ProcessTSString(NewRow, StructureOfActions, CachedValues);
		
		RecalculateNumberOfEntries(CurrentRow);
		RecalculateNumberOfEntries(NewRow);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure WriteDocument(Command)
	
	TMCommonUseClient.Write(ThisForm);
	
EndProcedure

&AtClient
Procedure FillInWithStockBalanceInBins(Command)
	
	If Items.Premise.Visible
		And Not ValueIsFilled(Object.Premise) Then
		
		MessageText = NStr("vi = 'Chưa điền trường ""Nhà kho""';
							|ru = 'Поле ""Помещение"" не заполнено';
							|en = '""Wareroom"" is not filled in'; fa = '""Wareroom"" is not filled in';
							|it = 'Il campo ""collocamento"" non è compilato';
							|pl = 'Pole ""Pomieszczenie"" nie jest wypełnione';
							|tr = '""Alan"" alanı doldurulmadı'");
		CommonClientServer.MessageToUser(MessageText, Object.Ref, "Object.Premise");
		
		Return;
		
	EndIf;
	
	If Object.Goods.Count() > 0 Then
		Notification = New CallbackDescription("FillInRemainingItemsInCellsOpenSelectionForm", ThisObject);
		MessageText = NStr("vi = 'Phần bảng sẽ được xóa và chứa đầy hàng hóa mà thiệt hại phải được thực hiện. Tiếp tục?';
							|ru = 'Табличная часть будет очищена и заполнена товарами, по которым нужно оформить порчу. Продолжить?';
							|en = 'The table will be refilled. Do you want to continue?'; fa = 'The table will be refilled. Do you want to continue?';
							|it = 'La parte tabulare verrà cancellata e compilata con i prodotti per i quali è necessario formalizzare il danneggiamento. Continuare?';
							|pl = 'Część tabelaryczna będzie oczyszczona i wypełniona towarami, według których należy zarejestrować uszkodzenie. Kontynuować?';
							|tr = 'Tablo bölümü temizlenecek ve stok kalite değişikliği gereken ürünlerle doldurulacaktır. Devam edilsin mi?'");
		
		ShowQueryBox(Notification, MessageText, QuestionDialogMode.YesNo);
		Return;
	EndIf;
	
	FillInRemainingItemsInCellsOpenSelectionForm(DialogReturnCode.Yes, New Structure);
	
EndProcedure

&AtClient
Procedure FillInRemainingItemsInCellsOpenSelectionForm(QuestionResult, AdditionalParameters) Export
	
	If QuestionResult <> DialogReturnCode.Yes Then
		Return;
	EndIf;
	
	FormParameters = New Structure("Warehouse, Premise", Object.Warehouse, Object.Premise);
	ClosingNotification_ = New CallbackDescription("FillInWithStockBalanceInBinsCompletion", ThisObject);
	
	OpenForm("Document.GoodsPickingPlacement.Form.StorageBinChoiceForm", FormParameters, ThisForm, , , ,
		ClosingNotification_, FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure FillInWithStockBalanceInBinsCompletion(Result, AdditionalParameters) Export
	
	If ValueIsFilled(Result) Then
		FillInRemainingGoodsInCellsOnServer(Result);
		
		If Object.Goods.Count() > 0 Then
			MessageText = NStr("vi = 'Phần bảng được điền';
								|ru = 'Табличная часть заполнена';
								|en = 'Table is filled'; fa = 'Table is filled';
								|it = 'Parte tabulare è compilata';
								|pl = 'Część tabelaryczna jest wypełniona';
								|tr = 'Tablo bölümü dolduruldu'");
			ExplanationText = NStr("vi = 'Phần bảng được điền số dư của hàng hóa trong các ô';
									|ru = 'Табличная часть заполнена остатками товаров в ячейках';
									|en = 'Table is filled with bin stock balance'; fa = 'Table is filled with bin stock balance';
									|it = 'La parte tabulare è compilata con le rimanenze delle merci nelle celle';
									|pl = 'Część tabelaryczna jest wypełniona ostatkami towarów w komórkach';
									|tr = 'Tablo bölümü hücrelerde olan ürün bakiyeleri ile dolduruldu'");
			
			ShowUserNotification(MessageText, , ExplanationText, PictureLib.Information32);
		Else
			MessageText = NStr("vi = 'Phần bảng chưa điền';
								|ru = 'Табличная часть не заполнена';
								|en = 'Table is not filled in'; fa = 'Table is not filled in';
								|it = 'Parte tabulare non compilata';
								|pl = 'Część tabelaryczna nie jest wypełniona';
								|tr = 'Tablo bölümü doldurulmadı'");
			ExplanationText = NStr("vi = 'Không có hàng hóa cân bằng trong các tế bào';
									|ru = 'Нет остатков товаров в ячейках';
									|en = 'No stock balance in bins'; fa = 'No stock balance in bins';
									|it = 'Nelle celle non ci sono rimanenze dei merci';
									|pl = 'Brak ostatków towarów w komórkach';
									|tr = 'Hücrelerde ürün bakiyeleri mevcut değil'");
			
			ShowUserNotification(MessageText, , ExplanationText, PictureLib.Information32);
		EndIf;
	EndIf;
	
EndProcedure

// IntegrationWith1CDocumentManagementSubsystem
&AtClient
Procedure Attachable_ExecuteIntegrationCommand(Command)
	
	IntegrationWith1CDocumentManagementCoreClient.ExecutePlugInIntegrationCommand(
		Command,
		ThisObject,
		Object);
	
EndProcedure
// End IntegrationWith1CDocumentManagementSubsystem

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()

	ConditionalAppearance.Items.Clear();
	
	// Setting the Conditional appearance of a different quality item.
	ProductsServer.SetConditionalAppearanceOfDifferentQualityItem(ThisObject);
	
	//
	ProductsServer.EstablishConditionalAppearanceOfProductCharacteristics(ThisObject);
	
	//
	ProductsServer.EstablishConditionalAppearanceOfProductCharacteristics(ThisObject,
																			"GoodsCharacteristicRecordingAsReceived",
																			"Object.Goods.ItemVariantsAreUsedRecordingAsReceived");
	
	//
	ProductsServer.EstablishConditionalAppearanceOfProductSeries(ThisForm, "SeriesAlwaysWHGoods");
	
	//
	ConditionalDesignParameters = ProductsServer.NewParametersForConditionalDesignOfUnitsOfMeasurement(True, True);
	ProductsServer.SetConditionalAppearanceOfUnitsOfMeasurement(ThisObject, ConditionalDesignParameters);
	
	//
	ConditionalDesignParameters = ProductsServer.NewParametersForConditionalDesignOfUnitsOfMeasurement(True, True);
	ConditionalDesignParameters.NameOfUnitField = "GoodsProductsRecordingAsReceivedUnitOfMeasure";
	ConditionalDesignParameters.PathToPackagingUnitField = "Object.Goods.PackagingReceipt";
	ProductsServer.SetConditionalAppearanceOfUnitsOfMeasurement(ThisObject, ConditionalDesignParameters);
	
	//
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsPackage.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.Package");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.ItemsType");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.ItemsTypes.OwnGoods;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.EmptyTableField);
	
	//
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsPackagingReceipt.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.PackagingReceipt");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.ItemTypePosting");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.ItemsTypes.OwnGoods;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.EmptyTableField);
	
	//
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsPackage.Name);
	
	FilterGroup1 = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup1.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	
	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("UseBinLocationWarehousing");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;

	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.ItemsType");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotEqual;
	ItemFilter.RightValue = Enums.ItemsTypes.OwnGoods;

	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.MeasuredValueType");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotEqual;
	ItemFilter.RightValue = Enums.TypesOfMeasuredValues.NumberOfPieces;
	
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	
	//
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsPackagingReceipt.Name);
	
	FilterGroup1 = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup1.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	
	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("UseBinLocationWarehousing");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.ItemTypePosting");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotEqual;
	ItemFilter.RightValue = Enums.ItemsTypes.OwnGoods;
	
	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.TypeOfMeasuredValueEntry");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotEqual;
	ItemFilter.RightValue = Enums.TypesOfMeasuredValues.NumberOfPieces;
	
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	
	//
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsWeight.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.PackageWeight");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = 0;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.TextColorOfCanceledRowOfDocument);
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<không sử dụng>';
													|ru = '<не используется>';
													|en = '<not used>'; fa = '<استفاده نمی‌شود>';
													|it = '<non viene utilizzato>';
													|pl = '<nie używa się>';
													|tr = '<kullanılmayan>'"));
	Item.Appearance.SetParameterValue("ReadOnly", True);
	
	//
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsVolumeM3.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.PackageVolume");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = 0;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.TextColorOfCanceledRowOfDocument);
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<không sử dụng>';
													|ru = '<не используется>';
													|en = '<not used>'; fa = '<استفاده نمی‌شود>';
													|it = '<non viene utilizzato>';
													|pl = '<nie używa się>';
													|tr = '<kullanılmayan>'"));
	Item.Appearance.SetParameterValue("ReadOnly", True);
	
	//
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsUnitOfMeasureForWeight.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.PackageWeight");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = 0;
	
	Item.Appearance.SetParameterValue("Show", False);
	
	//
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsUnitOfMeasureForVolume.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.PackageVolume");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = 0;
	
	Item.Appearance.SetParameterValue("Show", False);
	
	//
	ProductsServer.SetConditionalAppearanceOfProductAssignment(ThisObject);

	// Visibility of the "Under appointment" column
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsForAssignment.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.Purpose");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;

	Item.Appearance.SetParameterValue("Show", False);
	
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
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsProductsRecordingAsReceived.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue  = New DataCompositionField("Object.Goods.Products");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	Item.Appearance.SetParameterValue("ReadOnly", True);
	Item.Appearance.SetParameterValue("TextColor", StyleColors.TextColorOfCanceledRowOfDocument);
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<cần chọn hàng hóa có chất lượng ban đầu>';
													|ru = '<необходимо выбрать товар исходного качества>';
													|en = '<select the goods of original quality>'; fa = '<select the goods of original quality>';
													|it = '<select the goods of original quality>';
													|pl = '<select the goods of original quality>';
													|tr = '<başlangıç kalitesindeki ürün seçilmelidir>'"));
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	
EndProcedure

&AtServer
Procedure OnReadCreateAtServer()
	
	FillInServiceDetailsForProductRange();
	
	AssignmentsServer.FillInDestinationTypeInTable(Object.Goods);
	
	WhenChangingWarehousePremisesDate(True);
	
EndProcedure

#Region OnChangeAttributes

&AtServer
Procedure WhenChangingWarehousePremisesDate(CallWhenReading = False)
	
	SetFormFunctionalOptionParameters(New Structure("Warehouse, Premise", Object.Warehouse, Object.Premise));
	
	UseBinLocationWarehousing = WarehousesServer.UseBinLocationWarehousing(Object.Warehouse, Object.Premise, Object.Date);
	
	Items.Premise.Visible = WarehousesServer.UseWarerooms(Object.Warehouse,Object.Date);
	Items.GoodsFillInWithStockBalanceInBins.Visible = UseBinLocationWarehousing;
	
	TMCommonUseClientServer.SetPropertyOfFormElements(Items,
		"GoodsPackage, GoodsPackagingReceipt, GoodsCell",
		"Visible", UseBinLocationWarehousing);
		
	SeriesSpecificationParameters = New FixedStructure(ProductsServer.SeriesSpecificationParameters(Object, Documents.DamageNote));
	
	If Not CallWhenReading Then
		ProductsServer.FillInStatusesForSpecifyingSeries(Object,SeriesSpecificationParameters);
		If Not(UseBinLocationWarehousing) Then
			For Each String In Object.Goods Do
				String.Package = Catalogs.PackagesAndUnitsOfMeasure.EmptyRef();
				String.PackagingReceipt = Catalogs.PackagesAndUnitsOfMeasure.EmptyRef();
				String.Count = String.NumberOfPackages;
			EndDo;
		EndIf;
	EndIf;
	
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
	StructureOfActionsWithAddedStrings.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));
	StructureOfActionsWithAddedStrings.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
	StructureOfActionsWithAddedStrings.Insert("CheckSeriesCalculateStatus", New Structure("Warehouse, SeriesSpecificationParameters", Object.Warehouse, SeriesSpecificationParameters));
	StructureOfActionsWithAddedStrings.Insert("FillInMeasuredValueTypeAttribute", New Structure("Products", "MeasuredValueType"));
	StructureOfActionsWithAddedStrings.Insert("FillPackageWeight",New Structure("Products, Package", "PackageWeight"));
	StructureOfActionsWithAddedStrings.Insert("FillPackageVolume",New Structure("Products, Package", "PackageVolume"));
	StructureOfActionsWithAddedStrings.Insert("FillInUnitOfWeight",New Structure("Products, Package", "UnitOfMeasureForWeight"));
	StructureOfActionsWithAddedStrings.Insert("FillInVolumeUnit",New Structure("Products, Package", "UnitOfMeasureForVolume"));
	
	AddActionsToStructureWhenChangingPackagesNumber(StructureOfActionsWithAddedStrings);
	
	StructureOfActionsWithModifiedStrings = New Structure;
	AddActionsToStructureWhenChangingPackagesNumber(StructureOfActionsWithModifiedStrings);
	
	StructureOfActions = BarcodingOfItemsClient.BarcodeProcessingParameters();
	StructureOfActions.Barcodes                              = BarcodeData_5;
	StructureOfActions.StructureOfActionsWithAddedStrings = StructureOfActionsWithAddedStrings;
	StructureOfActions.StructureOfActionsWithModifiedStrings  = StructureOfActionsWithModifiedStrings;
	StructureOfActions.SeriesSpecificationParameters                 = SeriesSpecificationParameters;
	StructureOfActions.GoodsOnly                           = True;
	StructureOfActions.NotUsePackages                 = Not UseBinLocationWarehousing;
	
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
	
EndProcedure

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
	
	If ProductsClient.YouNeedServerCallToSpecifySeries(ThisForm,SeriesSpecificationParameters,Text, CurrentData) Then
		If CurrentData = Undefined Then
			CurDataId = Items.Goods.CurrentData.GetID();
		Else
			CurDataId = CurrentData.GetID();
		EndIf;
		
		ParametersOfSeriesIndicationForm = ParametersOfSeriesIndicationForm(CurDataId);
		
		CallbackDescription = New CallbackDescription("OpenSelectionOfSeriesCompletion",
														ThisObject,
														New Structure("ParametersOfSeriesIndicationForm", ParametersOfSeriesIndicationForm));
		
		OpenForm(ParametersOfSeriesIndicationForm.FormName,
					ParametersOfSeriesIndicationForm,
					ThisForm,
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
	
	Actions = New Structure;
	Actions.Insert("FillInFeatureAttribute", New Structure("Products, ProductsRecordingAsReceived","ItemVariantsAreUsed", "ItemVariantsAreUsedRecordingAsReceived"));
	Actions.Insert("FillInProductTypeAttribute_", New Structure("Products, ProductsRecordingAsReceived", "ItemsType", "ItemTypePosting"));
	Actions.Insert("FillInArticleAttribute", New Structure("Products, ProductsRecordingAsReceived", "SKU", "SKURegistration"));
	Actions.Insert("FillInMeasuredValueTypeAttribute", New Structure("Products, ProductsRecordingAsReceived", "MeasuredValueType", "TypeOfMeasuredValueEntry"));
	Actions.Insert("FillPackageWeight",New Structure("Products, Package", "PackageWeight"));
	Actions.Insert("FillPackageVolume",New Structure("Products, Package", "PackageVolume"));
	Actions.Insert("FillInUnitOfWeight",New Structure("Products, Package", "UnitOfMeasureForWeight"));
	Actions.Insert("FillInVolumeUnit",New Structure("Products, Package", "UnitOfMeasureForVolume"));
	Actions.Insert("RecalculateWeightVolume");
	Actions.Insert("CheckSeriesCalculateStatus", New Structure("Warehouse, SeriesSpecificationParameters",
																		Object.Warehouse, SeriesSpecificationParameters));
	
	ProductsServer.ProcessSeriesIndication_(Object,SeriesSpecificationParameters,ParametersOfSeriesIndicationForm,Actions,CachedValues);
	
	FillInNumberOfEntries();
	
EndProcedure

&AtServer
Function ParametersOfSeriesIndicationForm(CurDataId)
	
	Return ProductsServer.ParametersOfSeriesIndicationForm(Object, SeriesSpecificationParameters, CurDataId, ThisForm);
	
EndFunction

#EndRegion

#Region Other

&AtServer
Function ThereIsProductOfDifferentQuality(ProductOfOriginalQuality, NonconformingProducts)
	
	Return InformationRegisters.AnotherQualityGoods.CheckForGradation(ProductOfOriginalQuality, NonconformingProducts);
	
EndFunction

&AtClientAtServerNoContext
Procedure AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions)
	
	StructureOfActions.Insert("RecalculateNumberOfUnits");
	StructureOfActions.Insert("RecalculateWeightVolume");
	StructureOfActions.Insert("RecalculateNumberOfSuffixPacks", "Registered_");
	
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
Procedure FillInServiceDetailsForProductRange()
	
	ParametersForFillingInBankingDetails = New Structure;
	ParametersForFillingInBankingDetails.Insert("FillInFeatureAttribute", New Structure("Products, ProductsRecordingAsReceived", "ItemVariantsAreUsed", "ItemVariantsAreUsedRecordingAsReceived"));
	ParametersForFillingInBankingDetails.Insert("FillInProductTypeAttribute_", New Structure("Products, ProductsRecordingAsReceived", "ItemsType", "ItemTypePosting"));
	ParametersForFillingInBankingDetails.Insert("FillInArticleAttribute", New Structure("Products, ProductsRecordingAsReceived", "SKU", "SKURegistration"));
	ParametersForFillingInBankingDetails.Insert("FillInMeasuredValueTypeAttribute", New Structure("Products, ProductsRecordingAsReceived", "MeasuredValueType", "TypeOfMeasuredValueEntry"));
	ParametersForFillingInBankingDetails.Insert("FillPackageWeight",New Structure("Products, Package", "PackageWeight"));
	ParametersForFillingInBankingDetails.Insert("FillPackageVolume",New Structure("Products, Package", "PackageVolume"));
	ParametersForFillingInBankingDetails.Insert("FillInUnitOfWeight",New Structure("Products, Package", "UnitOfMeasureForWeight"));
	ParametersForFillingInBankingDetails.Insert("FillInVolumeUnit",New Structure("Products, Package", "UnitOfMeasureForVolume"));
	
	ProductsServer.FillInServiceDetailsForProductInCollection(Object.Goods,ParametersForFillingInBankingDetails);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateWeightVolume");
	
	BatchProcessingOfTablePartServer.TreatTS(Object.Goods, StructureOfActions);
	
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
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, Undefined);
	
	CurrentData.ItemVariantsAreUsedRecordingAsReceived = CurrentRow.ItemVariantsAreUsed;
	CurrentRow.Property("Characteristic", CurrentData.CharacteristicRecordingAsReceived);
	CurrentData.SKURegistration = CurrentRow.SKU;
	CurrentData.ItemTypePosting = CurrentRow.ItemsType;
	CurrentData.TypeOfMeasuredValueEntry = CurrentRow.MeasuredValueType;
	
	RecalculateNumberOfEntries(CurrentData);
	
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

&AtServer
Procedure FillInNumberOfEntries()
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	GoodsTable.LineNumber	AS LineNumber,
	|	GoodsTable.Count	AS CountRecordingAsReceived
	|INTO Goods
	|FROM
	|	&GoodsTable AS GoodsTable
	|WHERE
	|	GoodsTable.Count <> GoodsTable.CountRecordingAsReceived
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	GoodsTable.LineNumber				AS LineNumber,
	|	GoodsTable.CountRecordingAsReceived	AS CountRecordingAsReceived
	|FROM
	|	Goods AS GoodsTable";
	
	Query.SetParameter("GoodsTable", Object.Goods.Unload());
	
	GoodsTable = Query.Execute().Unload();
	
	SearchCondition = New Structure("LineNumber");
	
	For Each RowOfProduct In GoodsTable Do
		FillPropertyValues(SearchCondition, RowOfProduct);
		
		MutableStrings = Object.Goods.FindRows(SearchCondition);
		For Each CurrentRow In MutableStrings Do
			CurrentRow.CountRecordingAsReceived = RowOfProduct.CountRecordingAsReceived;
		EndDo;
	EndDo;
	
EndProcedure

&AtClient
Procedure GoodsWeightOnChange(Item)
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateNumberOfPackagesByWeight");
	
	CurrentRow = Items.Goods.CurrentData;
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);

	RecalculateNumberOfEntries(CurrentRow);

EndProcedure

&AtClient
Procedure GoodsVolumeM3OnChange(Item)
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateNumberOfPackagesByVolume");
	
	CurrentRow = Items.Goods.CurrentData;
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);

	RecalculateNumberOfEntries(CurrentRow);

EndProcedure

&AtServer
Procedure FillInRemainingGoodsInCellsOnServer(AddressOfCells)
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	CAST(ResiduesInCells.Cell AS Catalog.StorageBins)                    AS Cell,
	|	CAST(ResiduesInCells.Products AS Catalog.Products)                 AS Products,
	|	CAST(ResiduesInCells.Characteristic AS Catalog.ItemsCharacteristics) AS Characteristic,
	|	CAST(ResiduesInCells.Purpose AS Catalog.Assignments)                     AS Purpose,
	|	CAST(ResiduesInCells.Package AS Catalog.PackagesAndUnitsOfMeasure)         AS Package,
	|	CAST(ResiduesInCells.Series AS Catalog.ItemsBatches)                   AS Series,
	|	SUM(ResiduesInCells.Count)                                                  AS Count,
	|	SUM(ResiduesInCells.NumberOfPackages)                                          AS NumberOfPackages
	|INTO ResiduesInCells
	|FROM
	|	(SELECT
	|		ResiduesInCells.Cell                                           AS Cell,
	|		ResiduesInCells.Products                                     AS Products,
	|		ResiduesInCells.Characteristic                                   AS Characteristic,
	|		ResiduesInCells.Purpose                                       AS Purpose,
	|		ResiduesInCells.Package                                         AS Package,
	|		ResiduesInCells.Series                                            AS Series,
	|		CASE
	|			WHEN ResiduesInCells.Package = VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
	|				THEN ResiduesInCells.InStockBalance - ResiduesInCells.ForPickingBalance
	|			ELSE (ResiduesInCells.InStockBalance - ResiduesInCells.ForPickingBalance) * &QueryTextPackagingFactor
	|		END                                                            AS Count,
	|		ResiduesInCells.InStockBalance - ResiduesInCells.ForPickingBalance AS NumberOfPackages
	|	FROM
	|		AccumulationRegister.GoodsInStorageBins.Balance(,
	|			Products.Quality = VALUE(Enum.QualityLevels.New)
	|			AND(Package = VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
	|				OR Package.PackageType <> VALUE(Enum.TypesOfItemsPackages.CargoItem))
	|			AND Cell IN (&Cells)) AS ResiduesInCells
	|	WHERE
	|		ResiduesInCells.InStockBalance > 0
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		ResiduesInCells.Cell,
	|		ResiduesInCells.Products,
	|		ResiduesInCells.Characteristic,
	|		ResiduesInCells.Purpose,
	|		ResiduesInCells.Package,
	|		ResiduesInCells.Series,
	|		CASE
	|			WHEN ResiduesInCells.Package = VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
	|				THEN ResiduesInCells.InStock
	|			ELSE ResiduesInCells.InStock * &QueryTextPackagingFactor
	|		END,
	|		ResiduesInCells.InStock
	|	FROM
	|		AccumulationRegister.GoodsInStorageBins AS ResiduesInCells
	|	WHERE
	|		ResiduesInCells.Recorder = &Ref
	|		AND ResiduesInCells.Active
	|		AND ResiduesInCells.RecordType = VALUE(AccumulationRecordType.Expense)
	|		AND ResiduesInCells.Cell IN (&Cells)
	|		AND (ResiduesInCells.Package = VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
	|			OR ResiduesInCells.Package.PackageType <> VALUE(Enum.TypesOfItemsPackages.CargoItem))) AS ResiduesInCells
	|
	|GROUP BY
	|	ResiduesInCells.Cell,
	|	ResiduesInCells.Products,
	|	ResiduesInCells.Characteristic,
	|	ResiduesInCells.Purpose,
	|	ResiduesInCells.Package,
	|	ResiduesInCells.Series
	|
	|HAVING
	|	SUM(ResiduesInCells.Count) > 0
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////// 1
	|SELECT DISTINCT
	|	ResiduesInCells.Products                                                                 AS Products,
	|	ISNULL(DefectiveGoods_.OtherQualityGoods, VALUE(Catalog.Products.EmptyRef)) AS OtherQualityGoods
	|INTO TTMatchedProducts
	|FROM
	|	ResiduesInCells AS ResiduesInCells
	|		LEFT JOIN InformationRegister.AnotherQualityGoods AS DefectiveGoods_
	|		ON ResiduesInCells.Products = DefectiveGoods_.Products
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////// 2
	|SELECT
	|	MatchedGoods.Products                 AS Products,
	|	COUNT(MatchedGoods.OtherQualityGoods) AS LinkCount
	|INTO TableOfProductLinks
	|FROM
	|	TTMatchedProducts AS MatchedGoods
	|
	|GROUP BY
	|	MatchedGoods.Products
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////// 3
	|SELECT DISTINCT
	|	MatchedGoods.Products AS Products,
	|	CASE
	|		WHEN TableOfProductLinks.LinkCount < 2
	|			THEN CAST(MatchedGoods.OtherQualityGoods AS Catalog.Products)
	|		ELSE VALUE(Catalog.Products.EmptyRef)
	|	END                             AS OtherQualityGoods
	|INTO MatchedGoods
	|FROM
	|	TTMatchedProducts AS MatchedGoods
	|		INNER JOIN TableOfProductLinks AS TableOfProductLinks
	|		ON MatchedGoods.Products = TableOfProductLinks.Products
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////// 4
	|SELECT DISTINCT
	|	ResiduesInCells.Products   AS Products,
	|	ResiduesInCells.Characteristic AS Characteristic,
	|	ISNULL(MatchedGoods.OtherQualityGoods, VALUE(Catalog.Products.EmptyRef)) AS OtherQualityGoods,
	|	CASE
	|		WHEN (ResiduesInCells.Products.UseVariants = VALUE(Enum.ItemVariantsUsageOptions.CommonForItemKind)
	|					AND ResiduesInCells.Products.ProductKind = MatchedGoods.OtherQualityGoods.ProductKind)
	|				OR (ResiduesInCells.Products.UseVariants = VALUE(Enum.ItemVariantsUsageOptions.CommonWithOtherItemKind)
	|					AND ResiduesInCells.Products.ItemVariantsOwner = MatchedGoods.OtherQualityGoods.ItemVariantsOwner)
	|			THEN ResiduesInCells.Characteristic
	|		ELSE VALUE(Catalog.ItemsCharacteristics.EmptyRef)
	|	END                          AS CharacteristicsDefectiveGoods
	|INTO MatchedProductsByCharacteristics
	|FROM
	|	ResiduesInCells AS ResiduesInCells
	|		LEFT JOIN MatchedGoods AS MatchedGoods
	|		ON ResiduesInCells.Products = MatchedGoods.Products
	|WHERE
	|	ResiduesInCells.Products.UseVariants <> VALUE(Enum.ItemVariantsUsageOptions.SpecialForItems)
	|
	|UNION ALL
	|
	|SELECT DISTINCT
	|	ResiduesInCells.Products,
	|	ResiduesInCells.Characteristic,
	|	ISNULL(MatchedGoods.OtherQualityGoods, VALUE(Catalog.Products.EmptyRef)),
	|	ISNULL(ItemsCharacteristics.Ref, VALUE(Catalog.ItemsCharacteristics.EmptyRef))
	|FROM
	|	ResiduesInCells AS ResiduesInCells
	|		LEFT JOIN MatchedGoods AS MatchedGoods
	|		ON ResiduesInCells.Products = MatchedGoods.Products
	|
	|		LEFT JOIN Catalog.ItemsCharacteristics AS ItemsCharacteristics
	|		ON MatchedGoods.OtherQualityGoods = ItemsCharacteristics.Owner
	|			AND CAST(ResiduesInCells.Characteristic.Description AS STRING(500)) = CAST(ItemsCharacteristics.Description AS STRING(500))
	|WHERE
	|	ResiduesInCells.Products.UseVariants = VALUE(Enum.ItemVariantsUsageOptions.SpecialForItems)
	|	AND NOT ISNULL(ItemsCharacteristics.DeletionMark, FALSE)
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////// 5
	|SELECT DISTINCT
	|	ISNULL(MatchedGoods.OtherQualityGoods, VALUE(Catalog.Products.EmptyRef)) AS OtherQualityGoods,
	|	CASE
	|		WHEN ResiduesInCells.Products.UsePackages
	|				AND ResiduesInCells.Package.Owner = MatchedGoods.OtherQualityGoods.PackagingGroup
	|			THEN ResiduesInCells.Package
	|		ELSE VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
	|	END                        AS PackagingDefectiveGoods,
	|	ResiduesInCells.Products AS Products,
	|	ResiduesInCells.Package     AS Package
	|INTO MatchedGoodsByPackaging
	|FROM
	|	ResiduesInCells AS ResiduesInCells
	|		LEFT JOIN MatchedGoods AS MatchedGoods
	|		ON ResiduesInCells.Products = MatchedGoods.Products
	|WHERE
	|	ResiduesInCells.Products.PackagingGroup <> VALUE(Catalog.PackagingGroups.SpecialForItem)
	|
	|UNION ALL
	|
	|SELECT DISTINCT
	|	ISNULL(MatchedGoods.OtherQualityGoods, VALUE(Catalog.Products.EmptyRef)),
	|	ISNULL(ProductPackages.Ref, VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)),
	|	ResiduesInCells.Products,
	|	ResiduesInCells.Package
	|FROM
	|	ResiduesInCells AS ResiduesInCells
	|		LEFT JOIN MatchedGoods AS MatchedGoods
	|		ON ResiduesInCells.Products = MatchedGoods.Products
	|
	|		LEFT JOIN Catalog.PackagesAndUnitsOfMeasure AS ProductPackages
	|		ON MatchedGoods.OtherQualityGoods = ProductPackages.Owner
	|			AND CAST(ResiduesInCells.Package.Description AS STRING(500)) = CAST(ProductPackages.Description AS STRING(500))
	|WHERE
	|	ResiduesInCells.Products.PackagingGroup = VALUE(Catalog.PackagingGroups.SpecialForItem)
	|	AND NOT ISNULL(ProductPackages.DeletionMark, FALSE)
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////// 6
	|SELECT
	|	ResiduesInCells.Cell             AS Cell,
	|	ISNULL(GoodsCharacteristics.Products, VALUE(Catalog.Products.EmptyRef)) AS Products,
	|	ISNULL(GoodsCharacteristics.Characteristic, VALUE(Catalog.ItemsCharacteristics.EmptyRef)) AS Characteristic,
	|	ResiduesInCells.Purpose         AS Purpose,
	|	PackagingOfGoods.Package           AS Package,
	|	ResiduesInCells.Series              AS Series,
	|	ISNULL(GoodsCharacteristics.OtherQualityGoods, VALUE(Catalog.Products.EmptyRef)) AS ProductsRecordingAsReceived,
	|	ISNULL(GoodsCharacteristics.CharacteristicsDefectiveGoods, VALUE(Catalog.ItemsCharacteristics.EmptyRef)) AS CharacteristicRecordingAsReceived,
	|	CASE
	|		WHEN ResiduesInCells.Purpose = VALUE(Catalog.Assignments.EmptyRef)
	|			THEN FALSE
	|		ELSE TRUE
	|	END                              AS ForAssignment,
	|	ISNULL(PackagingOfGoods.PackagingDefectiveGoods, VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)) AS PackagingReceipt,
	|	ResiduesInCells.Count         AS Count,
	|	ResiduesInCells.NumberOfPackages AS NumberOfPackages
	|INTO GoodsOfOrder
	|FROM
	|	ResiduesInCells AS ResiduesInCells
	|		LEFT JOIN MatchedProductsByCharacteristics AS GoodsCharacteristics
	|		ON ResiduesInCells.Products = GoodsCharacteristics.Products
	|			AND ResiduesInCells.Characteristic = GoodsCharacteristics.Characteristic
	|
	|		LEFT JOIN MatchedGoodsByPackaging AS PackagingOfGoods
	|		ON ResiduesInCells.Products = PackagingOfGoods.Products
	|			AND ResiduesInCells.Package = PackagingOfGoods.Package
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////// 7
	|SELECT
	|	GoodsOfOrder.Cell                      AS Cell,
	|	GoodsOfOrder.Products                AS Products,
	|	GoodsOfOrder.Characteristic              AS Characteristic,
	|	GoodsOfOrder.Purpose                  AS Purpose,
	|	GoodsOfOrder.Package                    AS Package,
	|	GoodsOfOrder.Series                       AS Series,
	|	GoodsOfOrder.ProductsRecordingAsReceived   AS ProductsRecordingAsReceived,
	|	GoodsOfOrder.CharacteristicRecordingAsReceived AS CharacteristicRecordingAsReceived,
	|	GoodsOfOrder.ForAssignment               AS ForAssignment,
	|	GoodsOfOrder.PackagingReceipt       AS PackagingReceipt,
	|	GoodsOfOrder.Count                  AS Count,
	|	GoodsOfOrder.NumberOfPackages          AS NumberOfPackages,
	|	GoodsOfOrder.Count                  AS CountRecordingAsReceived
	|FROM
	|	GoodsOfOrder AS GoodsOfOrder
	|
	|ORDER BY
	|	GoodsOfOrder.Cell.TabIndex,
	|	GoodsOfOrder.Cell.Code,
	|	GoodsOfOrder.Products.Description,
	|	GoodsOfOrder.Characteristic.Description,
	|	GoodsOfOrder.Purpose.Description,
	|	GoodsOfOrder.Series.Description";
	
	
	Query.Text = StrReplace(Query.Text,
		"&QueryTextPackagingFactor",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
			"ResiduesInCells.Package", "ResiduesInCells.Products"));
	
	CellTable = GetFromTempStorage(AddressOfCells);
	
	Query.SetParameter("Ref", Object.Ref);
	Query.SetParameter("Cells", CellTable.UnloadColumn("Cell"));
	
	Object.Goods.Load(Query.Execute().Unload());
	
	FillInServiceDetailsForProductRange();
	ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);
	
	AssignmentsServer.FillInDestinationTypeInTable(Object.Goods,, FillingParametersByDestinationType());
	
EndProcedure

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
