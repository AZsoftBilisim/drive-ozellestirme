#Region Variables

&AtClient
Var CachedValues; // It is used by the mechanism for processing changes in PM details.

&AtClient
Var CurDataId; // Used to pass the current line to the waiting handler.

&AtClient
Var EditingRegistrationSeries; // Used to determine that the series selection form is called for the series specified in the header.

#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetConditionalAppearance();
	
	// Refund upon receipt of the form for analysis.
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(Object, ThisObject);
	
	TMCommonUse.CustomizePeripherals(ThisForm);
	
	
	If Not ValueIsFilled(Object.Ref) Then
		OnReadCreateAtServer();
		ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);
	EndIf;
	
	Items.GoodsSearchByBarcode.Visible = AccessRight("Read", Metadata.InformationRegisters.ItemsBarcodes);
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject);
	// End IntegrationWith1CDocumentManagementSubsystem
	
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	
	// Handler of the "Destination" mechanism
	Catalogs.Assignments.DocumentFormWhenCreatedOnServer(ThisForm);
	
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	
	sh_ShamsiInit(); // sh_ShamsiInit
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
Procedure ChoiceProcessing(SelectionResult, ChoiceSource)
	
	If ProductsClient.ThisIsIndicationOfSeries(ChoiceSource) Then
		
		If EditingRegistrationSeries Then
			
			CurrentData = Items.Goods.RowData(SelectionResult.CurrentRowID);
			
			CurrentRow = New Structure;
			CurrentRow.Insert("Series",               CurrentData.BatchReceipt);
			CurrentRow.Insert("BatchesIndicationStatus", CurrentData.BatchesIndicationStatusReceipt);
			
			ProductsClient.ProcessSeriesIndication(ThisForm, SeriesSpecificationParameters, SelectionResult, CurrentRow);
			
			CurrentData.BatchReceipt               = CurrentRow.Series;
			CurrentData.BatchesIndicationStatusReceipt = CurrentRow.BatchesIndicationStatus;
			
		Else
			ProductsClient.ProcessSeriesIndication(ThisForm, SeriesSpecificationParameters, SelectionResult);
		EndIf;
		
	ElsIf ChoiceSource.FormName = "Catalog.Assignments.Form.ChoiceForm" Then
		
		If Items.Goods.CurrentItem.Name = "GoodsPurpose" Then
			
			CurrentData = Items.Goods.CurrentData;
			CurrentData.Purpose = SelectionResult;
			
			StructureOfActions = New Structure;
			StructureOfActions.Insert("FillInDestinationType", FillingParametersByDestinationType());
			
			BatchProcessingOfTablePartClient.ProcessTSString(CurrentData, StructureOfActions, Undefined);
			
		ElsIf Items.Goods.CurrentItem.Name = "GoodsAssignmentGoodsReceipt" Then
			Items.Goods.CurrentData.AssignmentGoodsReceipt = SelectionResult;
		EndIf;
		
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
	
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)

	// StandardSubsystems.AccessManagement
	AccessManagement.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.AccessManagement
	
	// Handler of the "Date-change" mechanism
	PeriodClosingDates.ObjectOnReadAtServer(ThisForm, CurrentObject);
	
	OnReadCreateAtServer();
	
	FormEvents.OnReadAtServer(ThisObject, CurrentObject);
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	// End StandardSubsystems.AttachableCommands
EndProcedure

&AtClient
Procedure BeforeWrite(Cancel, WriteParameters)
	
	FormEventsClient.BeforeWrite(ThisObject, Cancel, WriteParameters);
	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
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
	
	AssignmentsServer.FillInDestinationTypeInTable(Object.Goods);
	
	ProvisionInDocumentsServer.CheckToRunBackgroundInventoryAllocationJob();
	
	ConfigurationModificationOverridable.AfterWriteAtServer(ThisForm, CurrentObject, WriteParameters);
	
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	
	Notify("Write_GoodsMisgradingNote", WriteParameters, Object.Ref);
	
	ConfigurationModificationClientOverridable.AfterWrite(ThisForm, WriteParameters);
	
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
Procedure WarehouseOnChange(Item)
	
	WhenChangingWarehousePremisesDate(False, True);
	
EndProcedure

&AtClient
Procedure PremiseOnChange(Item)
	
	WhenChangingWarehousePremisesDate();
	
EndProcedure

&AtClient
Procedure DateOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	
	DateOnChangeServer();
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersGoods

&AtClient
Procedure GoodsProductsOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;
	
	FillInArticleAttribute                  = New Structure("Products", "SKU");
	FillInProductTypeAttribute_          = New Structure("Products", "ItemsType");
	FillInMeasuredValueTypeAttribute    = New Structure("Products", "MeasuredValueType");
	ProductsOnChangeOverridable = New Structure("FormName, TabularSectionName",
												ThisForm.FormName, "Goods");
	CheckSeriesCalculateStatus           = New Structure("Warehouse, SeriesSpecificationParameters",
												Object.Warehouse, SeriesSpecificationParameters);
	FillPackageWeight                     = New Structure("Products, Package", "PackageWeight");
	FillPackageVolume                   = New Structure("Products, Package", "PackageVolume");
	FillInUnitOfWeight            = New Structure("Products, Package", "UnitOfMeasureForWeight");
	FillInVolumeUnit          = New Structure("Products, Package", "UnitOfMeasureForVolume");
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInArticleAttribute",                  FillInArticleAttribute);
	StructureOfActions.Insert("FillInProductTypeAttribute_",          FillInProductTypeAttribute_);
	StructureOfActions.Insert("FillInMeasuredValueTypeAttribute",    FillInMeasuredValueTypeAttribute);
	StructureOfActions.Insert("ProductsOnChangeOverridable", ProductsOnChangeOverridable);
	StructureOfActions.Insert("CheckCharacteristicsByOwner",       CurrentRow.Characteristic);
	StructureOfActions.Insert("CheckFillAssignment");
	StructureOfActions.Insert("CheckSeriesCalculateStatus",           CheckSeriesCalculateStatus);
	StructureOfActions.Insert("FillInUnblockableDateOfQualityConfirmation", CacheQualityControl);
	
	If UseBinLocationWarehousing Then
		StructureOfActions.Insert("CheckFillPackageByOwner", CurrentRow.Package);
	EndIf;
	
	StructureOfActions.Insert("FillPackageWeight",            FillPackageWeight);
	StructureOfActions.Insert("FillPackageVolume",          FillPackageVolume);
	StructureOfActions.Insert("FillInUnitOfWeight",   FillInUnitOfWeight);
	StructureOfActions.Insert("FillInVolumeUnit", FillInVolumeUnit);
	
	AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions);
	
	StructureOfActions.Insert("RecalculateNumberOfPackages");
	
	StructureOfActions.Insert("FillInDestinationType", FillingParametersByDestinationType());
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("CheckSeriesCalculateStatus", CheckSeriesCalculateStatus);
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
	RecalculateNumberOfEntries(CurrentRow);
	
EndProcedure

&AtClient
Procedure GoodsControlledLotReferenceOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;
	StructureOfActions = New Structure();
	StructureOfActions.Insert("FillInUnblockableDateOfQualityConfirmation", CacheQualityControl);
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
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
Procedure GoodsSeriesOnChange(Item)
	
	CurrentData     = Items.Goods.CurrentData;
	ValueSelected = ProductsClientServer.SelectedSeries();
	
	ValueSelected.Value                   = CurrentData.Series;
	ValueSelected.CurrentRowID = CurrentData.GetID();
	
	ProductsClient.ProcessSeriesIndication(ThisForm, SeriesSpecificationParameters, ValueSelected);
	
EndProcedure

&AtClient
Procedure GoodsSeriesStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	
	OpenSelectionOfSeries(False, Item.EditText);
	
EndProcedure

&AtClient
Procedure GoodsPackageOnChange(Item)
	
	CurrentData = Items.Goods.CurrentData;
	
	FillPackageWeight            = New Structure("Products, Package", "PackageWeight");
	FillPackageVolume          = New Structure("Products, Package", "PackageVolume");
	FillInUnitOfWeight   = New Structure("Products, Package", "UnitOfMeasureForWeight");
	FillInVolumeUnit = New Structure("Products, Package", "UnitOfMeasureForVolume");
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillPackageWeight",            FillPackageWeight);
	StructureOfActions.Insert("FillPackageVolume",          FillPackageVolume);
	StructureOfActions.Insert("FillInUnitOfWeight",   FillInUnitOfWeight);
	StructureOfActions.Insert("FillInVolumeUnit", FillInVolumeUnit);
	
	StructureOfActions.Insert("RecalculateNumberOfPackages");
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentData, StructureOfActions, CachedValues);
	
	RecalculateNumberOfEntries(CurrentData);
	
EndProcedure

&AtClient
Procedure GoodsProductsRecordingAsReceivedOnChange(Item)
	
	CurrentData = Items.Goods.CurrentData;
	
	CurrentRow = New Structure;
	CurrentRow.Insert("Products",                       CurrentData.ProductsRecordingAsReceived);
	CurrentRow.Insert("ProductsRecordingAsReceived",          CurrentData.ProductsRecordingAsReceived);
	CurrentRow.Insert("SKURegistration",               CurrentData.SKURegistration);
	CurrentRow.Insert("ItemTypePosting",       CurrentData.ItemTypePosting);
	CurrentRow.Insert("TypeOfMeasuredValueEntry", CurrentData.TypeOfMeasuredValueEntry);
	CurrentRow.Insert("Characteristic",                     CurrentData.CharacteristicRecordingAsReceived);
	CurrentRow.Insert("ItemVariantsAreUsed",         CurrentData.ItemVariantsAreUsedRecordingAsReceived);
	CurrentRow.Insert("Package",                           CurrentData.PackagingReceipt);
	CurrentRow.Insert("Series",                              CurrentData.Series);
	CurrentRow.Insert("BatchReceipt",                 CurrentData.BatchReceipt);
	CurrentRow.Insert("BatchesIndicationStatus",                CurrentData.BatchesIndicationStatus);
	CurrentRow.Insert("BatchesIndicationStatusReceipt",   CurrentData.BatchesIndicationStatusReceipt);
	CurrentRow.Insert("Count",                         CurrentData.CountRecordingAsReceived);
	CurrentRow.Insert("NumberOfPackages",                 CurrentData.NumberOfPackages);
	
	FillInArticleAttribute               = New Structure("ProductsRecordingAsReceived", "SKURegistration");
	FillInProductTypeAttribute_       = New Structure("ProductsRecordingAsReceived", "ItemTypePosting");
	CheckSeriesCalculateStatus        = New Structure("Warehouse, SeriesSpecificationParameters",
										Object.Warehouse, SeriesSpecificationParameters);
	FillInMeasuredValueTypeAttribute = New Structure("ProductsRecordingAsReceived",
										"TypeOfMeasuredValueEntry");
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInArticleAttribute",               FillInArticleAttribute);
	StructureOfActions.Insert("FillInProductTypeAttribute_",       FillInProductTypeAttribute_);
	StructureOfActions.Insert("FillInMeasuredValueTypeAttribute", FillInMeasuredValueTypeAttribute);
	StructureOfActions.Insert("CheckCharacteristicsByOwner",    CurrentRow.Characteristic);
	StructureOfActions.Insert("CheckSeriesCalculateStatus", CheckSeriesCalculateStatus);
	
	If UseBinLocationWarehousing Then
		StructureOfActions.Insert("CheckFillPackageByOwner", CurrentRow.Package);
	EndIf;
	
	StructureOfActions.Insert("RecalculateNumberOfUnits");
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
	CurrentData.SKURegistration                    = CurrentRow.SKURegistration;
	CurrentData.ItemTypePosting            = CurrentRow.ItemTypePosting;
	CurrentData.TypeOfMeasuredValueEntry      = CurrentRow.TypeOfMeasuredValueEntry;
	CurrentData.CharacteristicRecordingAsReceived             = CurrentRow.Characteristic;
	CurrentData.ItemVariantsAreUsedRecordingAsReceived = CurrentRow.ItemVariantsAreUsed;
	CurrentData.PackagingReceipt                   = CurrentRow.Package;
	CurrentData.BatchReceipt                      = CurrentRow.BatchReceipt;
	CurrentData.BatchesIndicationStatusReceipt        = CurrentRow.BatchesIndicationStatusReceipt;
	CurrentData.CountRecordingAsReceived                 = CurrentRow.Count;
	
	StructureOfActions = New Structure();
	StructureOfActions.Insert("FillInUnblockableDateOfQualityConfirmation", CacheQualityControl);
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentData, StructureOfActions, CachedValues);
	
EndProcedure

&AtClient
Procedure GoodsBatchReceiptOnChange(Item)
	
	CurrentRow     = New Structure;
	CurrentData     = Items.Goods.CurrentData;
	ValueSelected = ProductsClientServer.SelectedSeries();
	
	ValueSelected.Value                   = CurrentData.BatchReceipt;
	ValueSelected.CurrentRowID = CurrentData.GetID();
	
	CurrentRow.Insert("Series",               CurrentData.BatchReceipt);
	CurrentRow.Insert("BatchesIndicationStatus", CurrentData.BatchesIndicationStatusReceipt);
	
	ProductsClient.ProcessSeriesIndication(ThisForm, SeriesSpecificationParameters, ValueSelected, CurrentRow);
	
	CurrentData.BatchReceipt               = CurrentRow.Series;
	CurrentData.BatchesIndicationStatusReceipt = CurrentRow.BatchesIndicationStatus;
	
EndProcedure

&AtClient
Procedure GoodsBatchReceiptStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	
	CurrentRow = New Structure;
	CurrentData = Items.Goods.CurrentData;
	
	CurrentRow.Insert("CurrentRowID", CurrentData.GetID());
	CurrentRow.Insert("Products",               CurrentData.ProductsRecordingAsReceived);
	CurrentRow.Insert("Characteristic",             CurrentData.CharacteristicRecordingAsReceived);
	CurrentRow.Insert("ItemVariantsAreUsed", CurrentData.ItemVariantsAreUsedRecordingAsReceived);
	CurrentRow.Insert("Purpose",                 CurrentData.AssignmentGoodsReceipt);
	CurrentRow.Insert("Package",                   CurrentData.PackagingReceipt);
	CurrentRow.Insert("Series",                      CurrentData.BatchReceipt);
	CurrentRow.Insert("BatchesIndicationStatus",        CurrentData.BatchesIndicationStatusReceipt);
	CurrentRow.Insert("ControlledLotReference",       CurrentData.ControlledLotReference);
	CurrentRow.Insert("Count",                 CurrentData.CountRecordingAsReceived);
	CurrentRow.Insert("NumberOfPackages",         CurrentData.NumberOfPackages);
	
	OpenSelectionOfSeries(True, Item.EditText, CurrentRow);
	
EndProcedure

&AtClient
Procedure GoodsPackagingReceiptOnChange(Item)
	
	CurrentData = Items.Goods.CurrentData;
	
	RecalculateNumberOfEntries(CurrentData);
	
EndProcedure

&AtClient
Procedure GoodsNumberOfPackagesOnChange(Item)
	
	StructureOfActions = New Structure;
	CurrentData     = Items.Goods.CurrentData;
	
	AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions);
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentData, StructureOfActions, CachedValues);
	
	RecalculateNumberOfEntries(CurrentData);
	
EndProcedure

&AtClient
Procedure GoodsWeightOnChange(Item)
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateNumberOfPackagesByWeight");
	
	CurrentData = Items.Goods.CurrentData;
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentData, StructureOfActions, CachedValues);
	
	RecalculateNumberOfEntries(CurrentData);
	
EndProcedure

&AtClient
Procedure GoodsVolumeM3OnChange(Item)
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateNumberOfPackagesByVolume");
	
	CurrentData = Items.Goods.CurrentData;
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentData, StructureOfActions, CachedValues);
	
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


// IntegrationWith1CDocumentManagementSubsystem
&AtClient
Procedure Attachable_ExecuteIntegrationCommand(Command)
	
	IntegrationWith1CDocumentManagementCoreClient.ExecutePlugInIntegrationCommand(Command, ThisObject, Object);
	
EndProcedure
// End IntegrationWith1CDocumentManagementSubsystem

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

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

#Region FormTableCommandHandlersGoods

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
Procedure ImportDataFromPDT(Command)
	
	ClearMessages();
	
	Notification = New CallbackDescription("DownloadFromTSDCompletion", ThisObject);
	
	EquipmentManagerClient.StartDownloadingDataFromTSD(
		Notification,
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
Procedure GetWeight(Command)
	
	CurrentRow = EquipmentManagerTMClient.CurrentRow(ThisForm);
	
	If CurrentRow = Undefined Then
		Return;
	EndIf;
	
	Notification = New CallbackDescription("GetWeightCompletion", ThisObject, CurrentRow);
	
	EquipmentManagerClient.StartGettingWeightWithElectronicScales(Notification, UUID);
	
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
		MessageText = NStr("vi = 'Phần bảng sẽ được xóa và chứa đầy hàng hóa mà bạn cần phát hành phân loại. Tiếp tục?';
							|ru = 'Табличная часть будет очищена и заполнена товарами, по которым нужно оформить пересортицу. Продолжить?';
							|en = 'The table will be refilled. Do you want to continue?'; fa = 'The table will be refilled. Do you want to continue?';
							|it = 'La parte tabulare verrà cancellata e compilata con i prodotti per i quali è necessario formalizzare la riclassificazione. Continuare?';
							|pl = 'Część tabelaryczna zostanie wyczyszczona i wypełniona towarami, dla których należy sporządzić przeklasyfikację. Kontynuować?';
							|tr = 'Tablo bölümü temizlenecek ve yeniden sınıflandırmanın düzenlenmesi gereken ürünlerle doldurulacaktır. Devam edilsin mi?'");
		
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

&AtClient
Procedure FillInRecordedAsReceivedGoodsByWrittenOffOnes(Command)
	
	SelectedRows = Items.Goods.SelectedRows;
	
	If SelectedRows.Count() > 0 Then
		FillInIncomingGoodsForDebitedOnServer(SelectedRows);
		
		MessageText = NStr("vi = 'Hàng hóa đến điền';
							|ru = 'Приходуемый товар заполнен';
							|en = 'Stock surplus is filled in'; fa = 'Stock surplus is filled in';
							|it = 'La merce in fase di registrazione in contabilità è compilata';
							|pl = 'Przyjmowany na stan towar jest wypełniony';
							|tr = 'Stok fazlası dolduruldu'");
		ExplanationText = NStr("vi = 'Phiếu nhập được điền theo phiếu xuất';
								|ru = 'Приходуемый товар заполнен по списываемому';
								|en = 'Stock surplus is filled in by stock shortage'; fa = 'Stock surplus is filled in by stock shortage';
								|it = 'La merce in fase di registrazione in contabilità è compilata per quella in fase di storno';
								|pl = 'Przyjmowany na stan towar jest wypełniony na podstawie rozchodowanego';
								|tr = 'Stok fazlası zarara yazılacak ile dolduruldu'");
		
		ShowUserNotification(MessageText, , ExplanationText, PictureLib.Information32);
	Else
		MessageText = NStr("vi = 'Phiếu nhập không được điền';
							|ru = 'Приходуемый товар не заполнен';
							|en = 'Stock surplus is not specified'; fa = 'Stock surplus is not specified';
							|it = 'La merce in fase di registrazione in contabilità non è compilata';
							|pl = 'Nie wypełniono towaru przyjmowanego na stan';
							|tr = 'Stok fazlası doldurulmadı'");
		ExplanationText = NStr("vi = 'Phiếu nhập không được điền theo phiếu xuất';
								|ru = 'Приходуемый товар не заполнен по списываемому';
								|en = 'Stock surplus is not filled in by stock shortage'; fa = 'Stock surplus is not filled in by stock shortage';
								|it = 'La merce in fase di registrazione in contabilità non è compilata per quella in fase di storno';
								|pl = 'Przyjmowany na stan towar nie jest wypełniony na podstawie rozchodowanego';
								|tr = 'Stok fazlası zarara yazılacak ile doldurulmadı'");
		
		ShowUserNotification(MessageText, , ExplanationText, PictureLib.Information32);
	EndIf;
	
EndProcedure

#EndRegion

&AtClient
Procedure PostAndClose(Command)
	
	TMCommonUseClient.PostAndClose(ThisForm);
	
EndProcedure

&AtClient
Procedure WriteDocument(Command)
	
	TMCommonUseClient.Write(ThisForm);
	
EndProcedure

&AtClient
Procedure PostDocument(Command)
	
	TMCommonUseClient.Post(ThisForm);
	
EndProcedure

#EndRegion

#Region Private

#Region OnChangeAttributes

&AtServer
Procedure DateOnChangeServer()
	
	WhenChangingWarehousePremisesDate();
	
EndProcedure

&AtServer
Procedure WhenChangingWarehousePremisesDate(CallWhenReading = False, DirectModificationOfWarehouseField = False)
	
	FOParameters = New Structure("Warehouse, Premise", Object.Warehouse, Object.Premise);
	UseBinLocationWarehousing = WarehousesServer.UseBinLocationWarehousing(Object.Warehouse, Object.Premise, Object.Date);
	
	SetFormFunctionalOptionParameters(FOParameters);
	
	Items.Premise.Visible = WarehousesServer.UseWarerooms(Object.Warehouse, Object.Date);
	Items.GoodsFillInWithStockBalanceInBins.Visible = UseBinLocationWarehousing;
	
	SeriesSpecificationParameters = New FixedStructure(
		ProductsServer.SeriesSpecificationParameters(Object, Documents.GoodsMisgradingNote));
	
	TMCommonUseClientServer.SetPropertyOfFormElements(Items,
		"GoodsPackage, GoodsPackagingReceipt, GoodsCell", "Visible", UseBinLocationWarehousing);
	
	If Not CallWhenReading Then
		ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);
		
		If Not(UseBinLocationWarehousing) Then
			For Each String In Object.Goods Do
				String.Package              = Catalogs.PackagesAndUnitsOfMeasure.EmptyRef();
				String.PackagingReceipt = Catalogs.PackagesAndUnitsOfMeasure.EmptyRef();
				String.Count            = String.NumberOfPackages;
			EndDo;
		EndIf;
	EndIf;
	If QualityControl.UpdateActionParameters(
			Documents.GoodsMisgradingNote,
			Object,
			CacheQualityControl,
			DirectModificationOfWarehouseField) Then
			
		StructureOfActions = New Structure();
		StructureOfActions.Insert("FillInUnblockableDateOfQualityConfirmation", CacheQualityControl);
		BatchProcessingOfTablePartServer.TreatTS(Object.Goods, StructureOfActions);
		
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
	
	Modified = True;
	
	FillInArticleAttribute                    = New Structure("Products", "SKU");
	FillInProductTypeAttribute_            = New Structure("Products", "ItemsType");
	FillInMeasuredValueTypeAttribute      = New Structure("Products", "MeasuredValueType");
	CheckSeriesCalculateStatus             = New Structure("Warehouse, SeriesSpecificationParameters",
																Object.Warehouse, SeriesSpecificationParameters);
	FillPackageWeight                       = New Structure("Products, Package", "PackageWeight");
	FillPackageVolume                     = New Structure("Products, Package", "PackageVolume");
	FillInUnitOfWeight              = New Structure("Products, Package", "UnitOfMeasureForWeight");
	FillInVolumeUnit            = New Structure("Products, Package", "UnitOfMeasureForVolume");
	
	StructureOfActionsWithAddedStrings = New Structure;
	StructureOfActionsWithAddedStrings.Insert("FillInArticleAttribute",         FillInArticleAttribute);
	StructureOfActionsWithAddedStrings.Insert("FillInProductTypeAttribute_", FillInProductTypeAttribute_);
	StructureOfActionsWithAddedStrings.Insert("CheckSeriesCalculateStatus",  CheckSeriesCalculateStatus);
	StructureOfActionsWithAddedStrings.Insert("FillInMeasuredValueTypeAttribute",
													FillInMeasuredValueTypeAttribute);
	StructureOfActionsWithAddedStrings.Insert("FillPackageWeight",            FillPackageWeight);
	StructureOfActionsWithAddedStrings.Insert("FillPackageVolume",          FillPackageVolume);
	StructureOfActionsWithAddedStrings.Insert("FillInUnitOfWeight",   FillInUnitOfWeight);
	StructureOfActionsWithAddedStrings.Insert("FillInVolumeUnit", FillInVolumeUnit);
	StructureOfActionsWithAddedStrings.Insert("FillInUnblockableDateOfQualityConfirmation", CacheQualityControl);
	
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
	
	BarcodingOfItemsServer.ProcessBarcodes(ThisObject, Object, StructureOfActionParameters,
		CachedValues);
	
EndProcedure

#EndRegion

#Region SetOfSeries

&AtClient
Procedure OpenSeriesSelectionWhenScanningProductBarCode()
	
	If CurDataId = Undefined Then
		Return;
	EndIf;
	
	OpenSelectionOfSeries(False);
	
EndProcedure

&AtClient
Procedure OpenSelectionOfSeries(ThisIsSeriesOfLogging, Text = "", CurrentData = Undefined)
	
	EditingRegistrationSeries = ThisIsSeriesOfLogging;
	
	If ProductsClient.YouNeedServerCallToSpecifySeries(ThisForm, SeriesSpecificationParameters, Text, CurrentData) Then
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
Procedure SetConditionalAppearance()
	
	ConditionalAppearance.Items.Clear();
	
	// Setting the conditional design for the items of the written-off nomenclature of the "Goods" tabular part.
	ProductsServer.EstablishConditionalAppearanceOfProductCharacteristics(ThisForm);
	ProductsServer.SetConditionalAppearanceOfProductAssignment(ThisForm);
	ProductsServer.EstablishConditionalAppearanceOfProductSeries(ThisForm, "SeriesAlwaysWHGoods");
	ConditionalDesignParameters = ProductsServer.NewParametersForConditionalDesignOfUnitsOfMeasurement(True, True);
	ProductsServer.SetConditionalAppearanceOfUnitsOfMeasurement(ThisObject, ConditionalDesignParameters);
	
	// Setting the conditional design for the elements of the incoming nomenclature of the tabular part 'Goods'.
	ProductsServer.EstablishConditionalAppearanceOfProductCharacteristics(ThisForm,
		"GoodsCharacteristicRecordingAsReceived", "Object.Goods.ItemVariantsAreUsedRecordingAsReceived");
	ProductsServer.SetConditionalAppearanceOfProductAssignment(ThisForm,
		"GoodsAssignmentGoodsReceipt", "Object.Goods.ItemTypePosting");
	ProductsServer.EstablishConditionalAppearanceOfProductSeries(ThisForm, "SeriesAlwaysWHGoods",
		"GoodsBatchReceipt", "Object.Goods.BatchesIndicationStatusReceipt",
		"Object.Goods.ItemTypePosting");
	ConditionalDesignParameters = ProductsServer.NewParametersForConditionalDesignOfUnitsOfMeasurement(True, True);
	ConditionalDesignParameters.NameOfUnitField = "GoodsProductsRecordingAsReceivedUnitOfMeasure";
	ConditionalDesignParameters.PathToPackagingUnitField = "Object.Goods.PackagingReceipt";
	ProductsServer.SetConditionalAppearanceOfUnitsOfMeasurement(ThisForm, ConditionalDesignParameters);
	
	// Setting the text color for the 'Packaging' element of the 'Products' tabular part.
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
	
	// Setting the text color for the "Packaging Arrival" element of the "Products" tabular part.
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
	
	// Setting the blank mark for the 'Packaging' element of the 'Products' tabular part.
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
	
	// Setting the blank mark for the "Packaging Arrival" element of the "Goods" tabular part.
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
	
	// Setting the conditional design for the 'Weight' element of the 'Products' tabular part.
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
	
	// Setting the conditional design for the 'Volume' element of the 'Products' tabular part.
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
	
	// Setting the conditional design for the 'Unit of measurement of Weight' element of the 'Products' tabular part.
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsUnitOfMeasureForWeight.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.PackageWeight");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = 0;
	
	Item.Appearance.SetParameterValue("Show", False);
	
	// Setting the conditional design for the 'Unit of measurement of volume' element of the 'Goods' tabular part.
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsUnitOfMeasureForVolume.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.PackageVolume");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = 0;
	
	Item.Appearance.SetParameterValue("Show", False);
	
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

&AtServer
Procedure OnReadCreateAtServer()
	
	FillInServiceDetailsForProductRange();
	
	AssignmentsServer.FillInDestinationTypeInTable(Object.Goods);
	
	CacheQualityControl = QualityControl.DataCacheOfMechanism(Object);
	WhenChangingWarehousePremisesDate(True);
	
EndProcedure

&AtServer
Procedure FillInServiceDetailsForProductRange()
	
	FillInArticleAttribute                    = New Structure("Products, ProductsRecordingAsReceived",
												"SKU", "SKURegistration");
	FillInProductTypeAttribute_            = New Structure("Products, ProductsRecordingAsReceived",
												"ItemsType", "ItemTypePosting");
	FillInMeasuredValueTypeAttribute      = New Structure("Products, ProductsRecordingAsReceived",
												"MeasuredValueType", "TypeOfMeasuredValueEntry");
	FillInFeatureAttribute = New Structure("Products, ProductsRecordingAsReceived",
												"ItemVariantsAreUsed", "ItemVariantsAreUsedRecordingAsReceived");
	FillPackageWeight                       = New Structure("Products, Package", "PackageWeight");
	FillPackageVolume                     = New Structure("Products, Package", "PackageVolume");
	FillInUnitOfWeight              = New Structure("Products, Package", "UnitOfMeasureForWeight");
	FillInVolumeUnit            = New Structure("Products, Package", "UnitOfMeasureForVolume");
	
	ParametersForFillingInBankingDetails = New Structure;
	ParametersForFillingInBankingDetails.Insert("FillInArticleAttribute",         FillInArticleAttribute);
	ParametersForFillingInBankingDetails.Insert("FillInProductTypeAttribute_", FillInProductTypeAttribute_);
	ParametersForFillingInBankingDetails.Insert("FillInMeasuredValueTypeAttribute",
											FillInMeasuredValueTypeAttribute);
	ParametersForFillingInBankingDetails.Insert("FillInFeatureAttribute",
											FillInFeatureAttribute);
	ParametersForFillingInBankingDetails.Insert("FillPackageWeight",            FillPackageWeight);
	ParametersForFillingInBankingDetails.Insert("FillPackageVolume",          FillPackageVolume);
	ParametersForFillingInBankingDetails.Insert("FillInUnitOfWeight",   FillInUnitOfWeight);
	ParametersForFillingInBankingDetails.Insert("FillInVolumeUnit", FillInVolumeUnit);
	
	ProductsServer.FillInServiceDetailsForProductInCollection(Object.Goods, ParametersForFillingInBankingDetails);
	
	StructureOfActions = New Structure("RecalculateWeightVolume");
	
	BatchProcessingOfTablePartServer.TreatTS(Object.Goods, StructureOfActions);
	
EndProcedure

&AtClientAtServerNoContext
Procedure AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions)
	
	StructureOfActions.Insert("RecalculateNumberOfUnits");
	StructureOfActions.Insert("RecalculateWeightVolume");
	StructureOfActions.Insert("RecalculateNumberOfSuffixPacks", "Registered_");
	
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
	|	ResiduesInCells.Products                                                       AS ProductsRecordingAsReceived,
	|	ResiduesInCells.Characteristic                                                     AS CharacteristicRecordingAsReceived,
	|	ResiduesInCells.Purpose                                                         AS AssignmentGoodsReceipt,
	|	ResiduesInCells.Package                                                           AS PackagingReceipt,
	|	ResiduesInCells.Series                                                              AS BatchReceipt,
	|	SUM(ResiduesInCells.Count)                                                  AS Count,
	|	SUM(ResiduesInCells.NumberOfPackages)                                          AS NumberOfPackages,
	|	SUM(ResiduesInCells.Count)                                                  AS CountRecordingAsReceived
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
	|			(Package = VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
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
	|				THEN -ResiduesInCells.InStock
	|			ELSE -ResiduesInCells.InStock * &QueryTextPackagingFactor
	|		END,
	|		-ResiduesInCells.InStock
	|	FROM
	|		AccumulationRegister.GoodsInStorageBins AS ResiduesInCells
	|	WHERE
	|		ResiduesInCells.Recorder = &Ref
	|		AND ResiduesInCells.Active
	|		AND ResiduesInCells.RecordType = VALUE(AccumulationRecordType.Receipt)
	|		AND ResiduesInCells.Cell IN (&Cells)
	|		AND (ResiduesInCells.Package = VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
	|			OR ResiduesInCells.Package.PackageType <> VALUE(Enum.TypesOfItemsPackages.CargoItem))
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
	|
	|ORDER BY
	|	ResiduesInCells.Cell.TabIndex,
	|	ResiduesInCells.Cell.Code,
	|	ResiduesInCells.Products.Description,
	|	ResiduesInCells.Characteristic.Description,
	|	ResiduesInCells.Purpose.Description,
	|	ResiduesInCells.Series.Description";
	
	Query.Text = StrReplace(Query.Text,
		"&QueryTextPackagingFactor",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
			"ResiduesInCells.Package", "ResiduesInCells.Products"));
	
	CellTable = GetFromTempStorage(AddressOfCells);
	
	Query.SetParameter("Ref", Object.Ref);
	Query.SetParameter("Cells", CellTable.UnloadColumn("Cell"));
	
	Object.Goods.Load(Query.Execute().Unload());
	StructureOfActions = New Structure();
	StructureOfActions.Insert("FillInUnblockableDateOfQualityConfirmation", CacheQualityControl);
	BatchProcessingOfTablePartServer.TreatTS(Object.Goods, StructureOfActions);
	
	FillInServiceDetailsForProductRange();
	ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);
	
	AssignmentsServer.FillInDestinationTypeInTable(Object.Goods);
	
EndProcedure

&AtServer
Procedure FillInIncomingGoodsForDebitedOnServer(SelectedRows)
	
	RowsArray = New Array;
	
	For Each SelectedRow In SelectedRows Do
		RowsArray.Add(Object.Goods.FindByID(SelectedRow));
	EndDo;
	
	For Each RowOfGoods In RowsArray Do
		RowOfGoods.ItemTypePosting            = RowOfGoods.ItemsType;
		RowOfGoods.SKURegistration                    = RowOfGoods.SKU;
		RowOfGoods.ProductsRecordingAsReceived               = RowOfGoods.Products;
		RowOfGoods.TypeOfMeasuredValueEntry      = RowOfGoods.MeasuredValueType;
		RowOfGoods.CharacteristicRecordingAsReceived             = RowOfGoods.Characteristic;
		RowOfGoods.ItemVariantsAreUsedRecordingAsReceived = RowOfGoods.ItemVariantsAreUsed;
		RowOfGoods.AssignmentGoodsReceipt                 = RowOfGoods.Purpose;
		RowOfGoods.BatchReceipt                      = RowOfGoods.Series;
		RowOfGoods.CountRecordingAsReceived                 = RowOfGoods.Count;
	EndDo;
	
	CheckSeriesCalculateStatus = New Structure("Warehouse, SeriesSpecificationParameters", Object.Warehouse, SeriesSpecificationParameters);
	StructureOfActions = New Structure;
	StructureOfActions.Insert("CheckSeriesCalculateStatus", CheckSeriesCalculateStatus);
	BatchProcessingOfTablePartServer.ProcessTSStrings(RowsArray, StructureOfActions, Object.Goods);
	
EndProcedure

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
