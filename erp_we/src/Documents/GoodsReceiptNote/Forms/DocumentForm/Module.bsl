#Region Variables

&AtClient
Var CachedValues; //used by the mechanism for processing changes in PM details

&AtClient
Var CurDataId; //used to pass the current line to the wait handler

&AtClient
Var ParametersForRecording Export;

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
	
	TMCommonUse.CustomizePeripherals(ThisForm);
	
	// Handler of the "Versioning of objects" mechanism
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	
	// Handler of the "Properties" subsystem
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("Object", Object);
	AdditionalParameters.Insert("ItemForPlacementName", "GroupAdditionalAttributes");
	AdditionalParameters.Insert("DeferredInitialization", True);
	PropertyManager.OnCreateAtServer(ThisForm, AdditionalParameters);
	
	If Not WarehousesServer.UseOrderStatuses(Object.Warehouse,True,False) Then
		Object.Status = Enums.GoodsReceiptNoteStatuses.Accepted; 
	EndIf;
	
	If Not ValueIsFilled(Object.Ref) Then
		OnReadCreateAtServer();
		ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);
	Else
		Items.GroupPages.CurrentPage = Items.GroupGoods;
	EndIf;
	
	UpdateBlankAutoTag(Object.Status, Items.Goods);
	
	ThereIsTheRightToEdit = False;
	
	CommonClientServer.SetDynamicListFilterItem(ListOfPackagings,   "Owner",      Catalogs.Products.EmptyRef(), DataCompositionComparisonType.Equal,,True);
	CommonClientServer.SetDynamicListFilterItem(BarcodeList, "Products",  Catalogs.Products.EmptyRef(), DataCompositionComparisonType.Equal,,True);
	CommonClientServer.SetDynamicListFilterItem(BarcodeList, "Characteristic",Catalogs.ItemsCharacteristics.EmptyRef(), DataCompositionComparisonType.Equal,,True);
	
	IndividualPackagingSet = Catalogs.PackagingGroups.SpecialForItem;
	
	UnitOfMeasureForWeight = Constants.UnitOfMeasureForWeight.Get();
	UnitOfMeasureForVolume = Constants.UnitOfMeasureForVolume.Get();
	UnitOfMeasurementForLinearDimensions = Constants.UnitOfMeasureForLength.Get();
	
	ColumnTitle = NStr("vi = 'Khối lượng, (%UnitOfMeasureForVolume%)';
						|ru = 'Объем, (%UnitOfMeasureForVolume%)';
						|en = 'Volume, %UnitOfMeasureForVolume%'; fa = 'Volume, %UnitOfMeasureForVolume%';
						|it = 'Volume, (%UnitOfMeasureForVolume%)';
						|pl = 'Objętość, (%UnitOfMeasureForVolume%)';
						|tr = 'Hacim, (%UnitOfMeasureForVolume%)'");
	ColumnTitle = StrReplace(ColumnTitle, "%UnitOfMeasureForVolume%",UnitOfMeasureForVolume);
	Items.ListOfPackagingsVolumeM3.Title = ColumnTitle;
	
	ColumnTitle = NStr("vi = 'Trọng lượng, (%UnitOfMeasureForWeight%)';
						|ru = 'Вес, (%UnitOfMeasureForWeight%)';
						|en = 'Weight, %UnitOfMeasureForWeight%'; fa = 'Weight, %UnitOfMeasureForWeight%';
						|it = 'Peso, (%UnitOfMeasureForWeight%)';
						|pl = 'Waga, (%UnitOfMeasureForWeight%)';
						|tr = 'Ağırlık, (%UnitOfMeasureForWeight%)'");
	ColumnTitle = StrReplace(ColumnTitle, "%UnitOfMeasureForWeight%",UnitOfMeasureForWeight);
	Items.ListOfPackagingsWeight.Title = ColumnTitle;
	
	ColumnTitle = NStr("vi = 'Chiều sâu, (%UnitOfMeasurementForLinearDimensions%)';
						|ru = 'Глубина, (%UnitOfMeasurementForLinearDimensions%)';
						|en = 'Depth, (%UnitOfMeasurementForLinearDimensions%)'; fa = 'Depth, (%UnitOfMeasurementForLinearDimensions%)';
						|it = 'Profondità, (%UnitOfMeasurementForLinearDimensions%)';
						|pl = 'Głębokość, (%UnitOfMeasurementForLinearDimensions%)';
						|tr = 'Derinlik, (%UnitOfMeasurementForLinearDimensions%)'");
	ColumnTitle = StrReplace(ColumnTitle, "%UnitOfMeasurementForLinearDimensions%",UnitOfMeasurementForLinearDimensions);
	Items.ListOfPackagingsDepth.Title = ColumnTitle;
	
	ColumnTitle = NStr("vi = 'Chiều cao, (%UnitOfMeasurementForLinearDimensions%)';
						|ru = 'Высота, (%UnitOfMeasurementForLinearDimensions%)';
						|en = 'Height, (%UnitOfMeasurementForLinearDimensions%)'; fa = 'Height, (%UnitOfMeasurementForLinearDimensions%)';
						|it = 'Altezza, (%UnitOfMeasurementForLinearDimensions%)';
						|pl = 'Wysokość, (%UnitOfMeasurementForLinearDimensions%)';
						|tr = 'Yükseklik, (%UnitOfMeasurementForLinearDimensions%)'");
	ColumnTitle = StrReplace(ColumnTitle, "%UnitOfMeasurementForLinearDimensions%",UnitOfMeasurementForLinearDimensions);
	Items.ListOfPackagingsHeight.Title = ColumnTitle;
	
	ColumnTitle = NStr("vi = 'Chiều rộng, (%UnitOfMeasurementForLinearDimensions%)';
						|ru = 'Ширина, (%UnitOfMeasurementForLinearDimensions%)';
						|en = 'Width, (%UnitOfMeasurementForLinearDimensions%)'; fa = 'Width, (%UnitOfMeasurementForLinearDimensions%)';
						|it = 'Larghezza, (%UnitOfMeasurementForLinearDimensions%)';
						|pl = 'Szerokość, (%UnitOfMeasurementForLinearDimensions%)';
						|tr = 'Genişlik, (%UnitOfMeasurementForLinearDimensions%)'");
	ColumnTitle = StrReplace(ColumnTitle, "%UnitOfMeasurementForLinearDimensions%",UnitOfMeasurementForLinearDimensions);
	Items.ListOfPackagingsWidth.Title = ColumnTitle;
	
	ConfigureDisplayOfAdditionalInformationPanel();

	SetFormItemEnabled();
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands

	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject);
	// End IntegrationWith1CDocumentManagementSubsystem
	
	
	Items.DecorationEDOState.Visible = GetFunctionalOption("UseElectronicDocumentExchangeWithCounterparties");
	
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);

	GoodsReceiptNoteLocalization.EstablishSignOfUseOfLabeledProducts(ThisForm);
	EstablishVisibilityOfPackagingElementsDuringLabeling();
	GoodsReceiptNoteLocalization.OnCreateAtServer(ThisObject, Cancel, StandardProcessing);
	
	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	EquipmentManagerClient.StartConnectingDevicesWhenYouOpenForm(Undefined, ThisForm, "BarcodeScanner");
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	// StandardSubsystems.Properties
	PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
	// End StandardSubsystems.Properties
	
	
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)

	// StandardSubsystems.AccessManagement
	AccessManagement.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.AccessManagement

	// Handler of the "Date-change" mechanism
	PeriodClosingDates.ObjectOnReadAtServer(ThisForm, CurrentObject);
	
	FormEvents.OnReadAtServer(ThisObject, CurrentObject);

	GoodsReceiptNoteLocalization.EstablishSignOfUseOfLabeledProducts(ThisForm);
	EstablishVisibilityOfPackagingElementsDuringLabeling();

	OnReadCreateAtServer();

	// StandardSubsystems.Properties
	PropertyManager.OnReadAtServer(ThisForm, CurrentObject);
	// End StandardSubsystems.Properties
	
	ConfigurationModificationOverridable.OnReadAtServer(ThisForm, CurrentObject);
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	// End StandardSubsystems.AttachableCommands
	
	
EndProcedure

&AtServer
Procedure OnLoadDataFromSettingsAtServer(Settings)
	
	ConfigureDisplayOfAdditionalInformationPanel();
	
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
	
	
	// Changing the nomenclature
	If Upper(EventName) = Upper("Write_Products") Then
		If Items.Goods.CurrentData <> Undefined
			And Items.Goods.CurrentData.Products = Source
			And CachedValues <> Undefined Then
			
			ProductsOnChangeServer(CachedValues);
			
		EndIf;
	EndIf;

	
EndProcedure

&AtClient
Procedure ChoiceProcessing(ValueSelected, ChoiceSource)
	
	CurrentData = Items.Goods.CurrentData;
	
	If ChoiceSource.FormName = "DataProcessor.SelectReusablePackage.Form.Form" Then
		
		FillMultiTurnContainersFromStorageServer(ValueSelected.AddressOfReusableContainerInStorage,CachedValues);
		ReusablePackageClient.NotifyUserAboutFillingMultiTurnContainers();
		
	ElsIf ChoiceSource.FormName = "Document.GoodsReceiptNote.Form.ShippingDocumentChoiceForm" Then
		
		Modified = True;
		If TypeOf(ValueSelected) = Type("Array") Then
			AddLinesForShipmentDocuments(ValueSelected,CachedValues);
		Else
			CurrentData.DocumentShipments = ValueSelected;
		EndIf;
		
	ElsIf ChoiceSource.FormName = "Catalog.Products.Form.ChoiceForm" Then
		
		CurrentData.Products = ValueSelected;
		ProductsOnChangeServer(CachedValues);
		Items.Goods.CurrentItem = Items.GoodsNumberOfPackages;
		Items.Goods.CurrentItem = Items.GoodsProducts;
		
	ElsIf ChoiceSource.FormName = "Document.PackingList.Form.ChoiceForm" Then
		
		CurrentData.PackingList = ValueSelected;
		PackingListWhenChangingColor(CachedValues);
		Items.Goods.EndEditRow(False);
		
	ElsIf ChoiceSource.FormName = "Catalog.Assignments.Form.ChoiceForm" Then

		Items.Goods.CurrentData.Purpose = ValueSelected;

	EndIf;
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)

	// StandardSubsystems.AccessManagement
	AccessManagement.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	// End StandardSubsystems.AccessManagement
	
	Items.InformationGroup.Picture = CommonClientServer.CommentPicture(Object.Comment);
	
	FillInServiceDetailsOfTSGoods();
	PackingListsServer.CreateNavigationLabel(ThisForm,
		Object.Ref.Metadata().ObjectPresentation);
	
	
	FormEvents.OnReadAtServer(ThisObject, CurrentObject);
	
	GoodsReceiptNoteLocalization.EstablishSignOfUseOfLabeledProducts(ThisForm);
	EstablishVisibilityOfPackagingElementsDuringLabeling();
	
	ProvisionInDocumentsServer.CheckToRunBackgroundInventoryAllocationJob();
	
	ConfigurationModificationOverridable.AfterWriteAtServer(ThisForm, CurrentObject, WriteParameters);
	
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	
	Notify("Write_GoodsReceiptNote",WriteParameters,Object.Ref);
	
	
	ConfigurationModificationClientOverridable.AfterWrite(ThisForm, WriteParameters);
	
	TMCommonUseClient.PerformActionsAfterRecording(ThisForm, Object, WriteParameters);
	
	// StandardSubsystems.AttachableCommands
	If CommonClient.SubsystemExists("StandardSubsystems.AttachableCommands") Then
		ModuleAttachableCommandsClient = CommonClient.CommonModule("AttachableCommandsClient");
		ModuleAttachableCommandsClient.AfterWrite(ThisObject, Object, WriteParameters);
	EndIf;
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)
	
	ForceCloseTheForm = True;
	
EndProcedure

&AtClient
Procedure OnClose(Exit)

	EquipmentManagerClient.StartDisablingHardwareWhenClosingForm(Undefined, ThisForm);

EndProcedure // Closing Prize()

&AtClient
Procedure BeforeWrite(Cancel, WriteParameters)
	
	If NotExecuteCheck1BeforeWrite Then
		NotExecuteCheck1BeforeWrite = False;
		Return;
	EndIf;
	
	If WriteParameters.WriteMode = DocumentWriteMode.Posting Then
		
		AdditionalParameters = New Structure;
		AdditionalParameters.Insert("WriteParameters", WriteParameters);
		
		Cancel = True;
		ReusablePackageClient.OfferToPickUpMultiTurnContainer(
			ThisForm,
			"Goods",
			"Products,Characteristic,Count",
			New CallbackDescription("BeforeRecordingOfferToPickUpMultiTurnContainer", ThisObject, AdditionalParameters));
		Return;
		
	EndIf;
	
	TMCommonUseClient.RecordObjectIfNecessary(ThisObject, WriteParameters, Cancel);
	
EndProcedure

&AtClient
Procedure BeforeRecordingOfferToPickUpMultiTurnContainer(Result, AdditionalParameters) Export
	
	TMCommonUseClient.RecordObjectIfNecessary(ThisObject, AdditionalParameters.WriteParameters,,True);
	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	// Handler of the "Properties" mechanism
	PropertyManager.BeforeWriteAtServer(ThisObject, CurrentObject);

	ConfigurationModificationOverridable.BeforeWriteAtServer(ThisForm, Cancel, CurrentObject, WriteParameters);
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.BeforeWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	// End IntegrationWith1CDocumentManagementSubsystem
	
EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	
	If UsePackingLists
		And Not Object.GoodsViewMode Then
		DocumentObject = FormAttributeToValue("Object");
		If Not DocumentObject.CheckFilling() Then
			Object.GoodsViewMode = True;
			DisplayModeOnChangeServer();
			Cancel = True;
		EndIf;
		CheckedAttributes.Clear();
	EndIf;
	
	// StandardSubsystems.Properties
	PropertyManager.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes);
	// End StandardSubsystems.Properties
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure PremiseOnChange(Item)
	
	WarehouseSpaceWhenServerChanges(Item.Name);
	
	If YouCanSpecifySeriesByReference Then
		
		QueryText = NStr("vi = 'Điền vào một loạt hàng hóa theo đơn đặt hàng?';
						|ru = 'Заполнить серии товаров по распоряжению?';
						|en = 'Fill in goods batch by reference?'; fa = 'Fill in goods batch by reference?';
						|it = 'Compilare le serie delle merci per disposizione?';
						|pl = 'Wypełnić serie towarów według zamówienia?';
						|tr = 'Ürün partisi emir üzerine mi doldurulsun?'");
		
		Response = Undefined;

		
		ShowQueryBox(New CallbackDescription("PremiseOnChangeCompletion", ThisObject), QueryText,QuestionDialogMode.YesNo,,DialogReturnCode.Yes);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure PremiseOnChangeCompletion(QuestionResult, AdditionalParameters) Export
    
    Response = QuestionResult;
    
    If Response <> DialogReturnCode.Yes Then
        Return;
    EndIf;
    
    FillInSeriesByReferenceServer(CachedValues);

EndProcedure

&AtClient
Procedure WarehouseOnChange(Item)
	
	WarehouseSpaceWhenServerChanges(Item.Name, True);
	
EndProcedure

&AtClient
Procedure StatusOnChange(Item)
	
	StatusOnChangeServer();
	UpdateBlankAutoTag(Object.Status, Items.Goods);
	
EndProcedure

&AtClient
Procedure DateOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	
	DateOnChangeServer();
	
EndProcedure

&AtClient
Procedure NavigationTextURLProcessing(Item, Var_URL, StandardProcessing)
	
	StandardProcessing = False;
	WhenMovingToAnotherLevelServer(Var_URL);
	
EndProcedure

&AtClient
Procedure DisplayModeOnChange(Item)
	DisplayModeOnChangeServer();
	PackingListsClient.UpdateCachedValuesForPCHSWithPackingLists(Items.Goods, CachedValues, SeriesSpecificationParameters);
	DisplayFilterPageDeselectIfNecessary();
EndProcedure

&AtClient
Procedure DecorationFilterNavigationLinkProcessing(Item, Var_URL, StandardProcessing)
	
	StandardProcessing = False;
	DecorationFilterNavigationLinkProcessingServer(Var_URL);

EndProcedure

&AtClient
Procedure ReferenceOrderPresentationURLProcessing(Item, FormattedStringURL, StandardProcessing)
	StandardProcessing = False;
	
	If FormattedStringURL = "Open_Order" Then
		ShowValue(, Object.ReferenceOrder)
	Else
		
		// &PerformanceMeasurement
		PerformanceMonitorClient.StartTimeMeasurement(True,
			"Document.GoodsReceiptNote.Form.SelectReference");
		
		OrderSelectionFormParameters = New Structure;
		OrderSelectionFormParameters.Insert("Warehouse", Object.Warehouse);
		OrderSelectionFormParameters.Insert("Sender", Object.Sender);
		OrderSelectionFormParameters.Insert("BusinessOperation", Object.BusinessOperation);
		
		CallbackDescription = New CallbackDescription("CustomerSChoice", ThisObject);
		
		OpenForm("Document.GoodsReceiptNote.Form.SelectReference",
						OrderSelectionFormParameters,
						ThisObject,
						,
						,
						,
						CallbackDescription,
						FormWindowOpeningMode.LockOwnerWindow);
	EndIf;
EndProcedure

&AtClient
Procedure Decorationedonage(Item, StandardProcessing)
	
	
	Return;
	
EndProcedure

&AtClient
Procedure GroupPagesOnCurrentPageChange(Item, CurrentPage)
	
	// StandardSubsystems.Properties
	If ThisObject.PropertiesParameters.Property(CurrentPage.Name)
			And Not ThisObject.PropertiesParameters.DeferredInitializationExecuted Then
		
		PropertiesExecuteDeferredInitialization();
		PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
	EndIf;
	// End StandardSubsystems.Properties
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersGoods

&AtClient
Procedure GoodsProductsOnChange(Item)
	
	ProductsOnChangeServer(CachedValues);
	
EndProcedure

&AtClient
Procedure GoodsPackingListOnChange(Item)
	
	PackingListWhenChangingColor(CachedValues);
	Items.Goods.EndEditRow(False);
	
EndProcedure

&AtClient
Procedure PackageOnChange(Item)

	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillPackageWeight",New Structure("Products, Package", "PackageWeight"));
	StructureOfActions.Insert("FillPackageVolume",New Structure("Products, Package", "PackageVolume"));
	StructureOfActions.Insert("FillInUnitOfWeight",New Structure("Products, Package", "UnitOfMeasureForWeight"));
	StructureOfActions.Insert("FillInVolumeUnit",New Structure("Products, Package", "UnitOfMeasureForVolume"));
	StructureOfActions.Insert("RecalculateNumberOfPackages");
	StructureOfActions.Insert("RecalculateWeightVolume");
	
	CurrentRow = Items.Goods.CurrentData;
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
	If Not ValueIsFilled(CurrentRow.PackingListParent) Then
		RecalculateNumberOfSeats();
	EndIf;

EndProcedure

&AtClient
Procedure GoodsWeightOnChange(Item)
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateNumberOfPackagesByWeight");
	
	CurrentRow = Items.Goods.CurrentData;
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);

EndProcedure

&AtClient
Procedure GoodsVolumeM3OnChange(Item)
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateNumberOfPackagesByVolume");
	
	CurrentRow = Items.Goods.CurrentData;
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);

EndProcedure

&AtClient
Procedure NumberOfPackagesOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;
	StructureOfActions = New Structure;
	AddActionsToStructureWhenChangingPackagesNumber(ThisObject, StructureOfActions);
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	If Not ValueIsFilled(CurrentRow.PackingListParent) Then
		RecalculateNumberOfSeats();
	EndIf;
	
EndProcedure

&AtClient
Procedure GoodsOnStartEdit(Item, NewRow, Copy)
	
	ProcessingOfTabularFormsClient.CacheCurLine(Items.Goods, ThisObject);
	
	PackingListsClient.AtBeginningOfEditingPMWithPackingLists(ThisForm, CachedValues, NewRow);
	If Copy Then
		CurrentRow = Items.Goods.CurrentData;
		If Not ValueIsFilled(CurrentRow.PackingListParent) Then
			RecalculateNumberOfSeats();
		EndIf;
	EndIf;
	ProductsClient.UpdateCachedValuesToAccountForSeries(
		Item,CachedValues,SeriesSpecificationParameters,Copy);
	
EndProcedure

&AtClient
Procedure GoodsOnEditEnd(Item, NewRow, CancelEdit)
	
	GoodsOnEditEndServer(NewRow And CancelEdit);
	
	PackingListsClient.AtEndOfEditingPMWithPackingLists(ThisForm, NewRow, CancelEdit);
	
	If ProductsClient.SeriesStatusesNeedToBeUpdated(Item, CachedValues, SeriesSpecificationParameters) Then
		
		FillInStatusesOfSpecifyingSeriesWhenEditingLineTS(Items.Goods.CurrentRow, CachedValues);
		PackingListsClient.UpdateCachedValuesForPCHSWithPackingLists(Item,CachedValues,SeriesSpecificationParameters);
		
	EndIf;
	
	ReusablePackageClient.UpdateFillingStateOfMultiTurnContainer(Object.ReusablePackageFillingStatus);
	
	CurrentData = Items.Goods.CurrentData;
	If Not CancelEdit
		And Items.Goods.CurrentData <> Undefined
		And Not Items.Goods.CurrentData.ThisIsAPackingList Then // For the packing list, the call will occur when changing
		
		If Not ValueIsFilled(CurrentData.Barcode) Then
			CurrentData.BarcodeIsNotRecognized = 0;
		EndIf;
		DataProcessorIsRequired = CurrentData.DataProcessorIsRequired;
		StructureOfActions = New Structure;
		StructureOfActions.Insert("FillInPlaceAttributeThatRequiresProcessing");
		BatchProcessingOfTablePartClient.ProcessTSString(CurrentData, StructureOfActions, CachedValues);
		If DataProcessorIsRequired <> CurrentData.DataProcessorIsRequired Then
			DisplayFilterPageDeselectIfNecessary();
		EndIf;
		
	EndIf;
	
	AdditionalParameters = New Structure;
	FormEventsClient.WhenChangingElement(ThisObject, Items.Goods, AdditionalParameters);
	If AdditionalParameters.Property("ServerCallRequired__") Then
		AttachIdleHandler("GoodsAtEndOfEditingForServerCall", 0.5, True);
	EndIf;
	
EndProcedure

&AtServer
Procedure GoodsOnEditEndServer(ThisIsCancellationOfNewLine)

	GoodsReceiptNoteLocalization.EstablishSignOfUseOfLabeledProducts(ThisForm);
	EstablishVisibilityOfPackagingElementsDuringLabeling();
	If ThisIsCancellationOfNewLine Then
		RecalculateNumberOfSeats();
	EndIf;
	
EndProcedure

&AtClient
Procedure GoodsBeforeDeleteRow(Item, Cancel)
	
	PackingListsClient.BeforeDeletingPMLinesWithPackingSheets(Items.Goods, CachedValues, SeriesSpecificationParameters);
	
EndProcedure

&AtClient
Procedure GoodsAfterDeleteRow(Item)
	
	GoodsAfterDeleteRowServer(CachedValues);
	PackingListsClient.UpdateCachedValuesForPCHSWithPackingLists(Items.Goods, CachedValues, SeriesSpecificationParameters);
	
	ReusablePackageClient.UpdateFillingStateOfMultiTurnContainer(Object.ReusablePackageFillingStatus);
	UpdateBlankAutoTag(Object.Status, Items.Goods);
	
EndProcedure

&AtClient
Procedure GoodsSelection(Item, RowSelected, Field, StandardProcessing)
	
	If PackingListsClient.CheckPrepareTransitionToPackingListWhenSelecting(Items.Goods, Field.Name) Then
		WhenMovingToAnotherLevelServer(Items.Goods.CurrentData.PackingList);
	ElsIf Field = Items.GoodsBatchesIndicationStatus Then
		OpenSelectionOfSeries();
	EndIf;
	
EndProcedure

&AtClient
Procedure GoodsDocumentShipmentsStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	OpenShipmentDocumentSelectionForm(True);
	
EndProcedure

&AtClient
Procedure GoodsProductsStartChoice(Item, ChoiceData, StandardProcessing)
	
	PackingListsClient.StartOfProductPlaceSelection(ThisForm, Item, StandardProcessing, Object.GoodsViewMode);
	
EndProcedure

&AtClient
Procedure GoodsBeforeAddRow(Item, Cancel, Copy, Parent, Var_Group, Parameter)
	
	PackingListsClient.BeforeYouStartAddingVTCHSPackingLists(Items.Goods, Cancel, Copy, CachedValues);
	
EndProcedure

&AtClient
Procedure ProductsPackingListParentOpening(Item, StandardProcessing)
	StandardProcessing = False;
	ShowValue(Undefined, Items.Goods.CurrentData.PackingListParent);
EndProcedure

&AtClient
Procedure ProductsPackingListParentClearing(Item, StandardProcessing)
	
	StandardProcessing = False;
	
EndProcedure

&AtClient
Procedure GoodsOnChange(Item)
	
	If Not HideAdditionalInformation Then
		AttachIdleHandler("ProductsWhenActivatingLineOnClient", 0.2, True);
	EndIf;
	
EndProcedure

&AtClient
Procedure GoodsToControlQualityOnChange(Item)
	
	CurrentData = Items.Goods.CurrentData;
	If Not CurrentData.ToControlQuality Then
		CurrentData.QualityConfirmationDate = '00010101';
	EndIf;
	
EndProcedure

&AtClient
Procedure GoodsQualityConfirmationDateOnChange(Item)
	
	CurrentData = Items.Goods.CurrentData;
	If Not CurrentData.ToControlQuality Then
		CurrentData.QualityConfirmationDate = '00010101';
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
Procedure ChangeTheQualityOfTheItem(Command)
	
	CurrentRow = Items.Goods.CurrentData;
	ClearMessages();
	
	If CurrentRow = Undefined Then
		MessageText = NStr("vi = 'Hãy chọn dòng của phần bảng';
							|ru = 'Выберите строку табличной части';
							|en = 'Select a table row'; fa = 'Select a table row';
							|it = 'Selezionare una riga della parte tabulare';
							|pl = 'Wybierz wiersz części tabelarycznej';
							|tr = 'Tablo bölümündeki satırı seçin'");
		CommonClient.MessageToUser(MessageText);
		Return
	EndIf;
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("CheckCharacteristicsByOwner", CurrentRow.Characteristic);
	StructureOfActions.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
	StructureOfActions.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));
	StructureOfActions.Insert("CheckFillPackageByOwner", CurrentRow.Package);
	StructureOfActions.Insert("FillInMeasuredValueTypeAttribute", New Structure("Products", "MeasuredValueType"));
	StructureOfActions.Insert("FillPackageWeight",New Structure("Products, Package", "PackageWeight"));
	StructureOfActions.Insert("FillPackageVolume",New Structure("Products, Package", "PackageVolume"));
	StructureOfActions.Insert("FillInUnitOfWeight",New Structure("Products, Package", "UnitOfMeasureForWeight"));
	StructureOfActions.Insert("FillInVolumeUnit",New Structure("Products, Package", "UnitOfMeasureForVolume"));
	StructureOfActions.Insert("RecalculateWeightVolume");
	StructureOfActions.Insert("FillInCheckQualityDateOfQualityConfirmation", CacheQualityControl);
	StructureOfActions.Insert("FillInUnblockableDateOfQualityConfirmation", CacheQualityControl);
	
	StructureOfActions.Insert("CheckFillAssignment");
	
	If ValueIsFilled(CurrentRow.Characteristic) Then
		StructureOfActions.Insert("FillInDescriptionOfPoorQualityProduct", CurrentRow.Characteristic);
	EndIf;
	
	If ValueIsFilled(CurrentRow.Package) Then
		StructureOfActions.Insert("FillInPackagingOfLowQualityGoods", CurrentRow.Package);
	EndIf;
	
	PackingListsClient.UpdateCachedValuesForPCHSWithPackingLists(Items.Goods,CachedValues,SeriesSpecificationParameters);
	
	Notification = New CallbackDescription("ChangeTheQualityOfTheItemCompletion", ThisObject, 
		New Structure("CurrentRow", CurrentRow));
	WarehousesClient.ChangeQuality(CurrentRow, StructureOfActions, CachedValues, Notification);
	
EndProcedure

// Parameters:
// 	Result - Undefined - 
// 	AdditionalParameters - Structure - Contains:
// 		* CurrentRow - FormDataStructure - 
&AtClient
Procedure ChangeTheQualityOfTheItemCompletion(Result, AdditionalParameters) Export
	
	If ProductsClient.SeriesStatusesNeedToBeUpdated(Items.Goods, 
		CachedValues, SeriesSpecificationParameters) Then
		
		IDCurrentRow = AdditionalParameters.CurrentRow.GetID();
		
		FillInStatusesOfSpecifyingSeriesWhenEditingLineTS(IDCurrentRow, CachedValues);
		
		PackingListsClient.UpdateCachedValuesForPCHSWithPackingLists(Items.Goods,CachedValues,SeriesSpecificationParameters);
		
	EndIf;

EndProcedure

&AtClient
Procedure FillInOnlyProducts(Command)
	
	Autotest_FillInByOrder("Products");
	
EndProcedure

&AtClient
Procedure WriteDocument(Command)
	
	TMCommonUseClient.Write(ThisForm, True);
	
EndProcedure

&AtClient
Procedure FillInProductsAndQuantity(Command)
	
	Autotest_FillInByOrder("ProductsQuantity_");
	
EndProcedure

&AtClient
Procedure FillInOnlyQuantity(Command)
	
	Autotest_FillInByOrder("Count");
	
EndProcedure

&AtClient
Procedure FillInTheReturnedQuantity(Command)
	
	FillInReturnedAmountOnServer(CachedValues);
	
EndProcedure

&AtClient
Procedure VerifyQuantity(Command)
	
	CheckQuantityInTheDocumentClient();
	
EndProcedure

&AtClient
Procedure SplitRow(Command)
	
	FormTable  = Items.Goods;
	TableData = Object.Goods;
	
	Notification = New CallbackDescription("SplitRowCompletion", ThisObject);
	PackingListsClient.BreakUpPMStringWithPackingLists(TableData, FormTable, Notification);
	
EndProcedure

&AtClient
Procedure SplitRowCompletion(NewRow, AdditionalParameters) Export 
	
	CurrentRowID = Items.Goods.CurrentRow;	
	
	If NewRow <> Undefined Then
		
		StructureOfActions = New Structure;
		AddActionsToStructureWhenChangingPackagesNumber(ThisObject, StructureOfActions);		
		
		IDOfNewLine = NewRow.GetID();
				
		ProcessAndRenumberTSStrings(IDOfNewLine, CurrentRowID, StructureOfActions, CachedValues);
		
	EndIf;
	
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
		AddActionsToStructureWhenChangingPackagesNumber(ThisObject, StructureOfActions);				
		
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
Procedure SpecifySeries(Command)
	
	OpenSelectionOfSeries();
	
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
Procedure AddReusablePackage(Command)

	ReusablePackageClient.SelectReusablePackage(
		ThisForm,
		"Goods",
		"Products,Characteristic,Count");
	
EndProcedure

&AtClient
Procedure ImportFromExternalFile(Command)
	
	ImportParameters = ProcessingOfTabularFormsClient.ProductLoadingParameters();
	ImportParameters.ImportPackingLists = True;
	ImportParameters.FilterParameters.Insert("ItemsType",
		ProductsClientServer.SelectionByProductMultiTurnContainer(False));
	
	Notification = New CallbackDescription("ImportFromExternalFileCompletion", ThisObject);
	ProcessingOfTabularFormsClient.ShowProductUploadForm(ImportParameters, Notification);
	
EndProcedure

&AtClient
Procedure ImportFromExternalFileCompletion(ImportedDataAddress, AdditionalParameters) Export
	
	If ValueIsFilled(ImportedDataAddress) Then
		GetUploadedProductsFromStorage(ImportedDataAddress, CachedValues);
	EndIf;
	
EndProcedure

&AtClient
Procedure AddFromShipmentDocuments(Command)
	
	OpenShipmentDocumentSelectionForm();
	
EndProcedure

&AtClient
Procedure PostDocument(Command)
	
	TMCommonUseClient.Post(ThisForm, True);
	
EndProcedure

&AtClient
Procedure SetDeletionMarkForADocument(Command)
	
	TMCommonUseClient.SetDeletionMarkForADocument(ThisForm);
	
EndProcedure

&AtClient
Procedure PostAndClose(Command)
	
	TMCommonUseClient.PostAndClose(ThisForm, True);
	
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

&AtClient
Procedure Attachable_PropertiesExecuteCommand(ItemOrCommand, Var_URL = Undefined, StandardProcessing = Undefined)
	
	PropertyManagerClient.ExecuteCommand(ThisObject, ItemOrCommand, StandardProcessing);
	
EndProcedure


&AtClient
Procedure UpLevel(Command)
	UpLevelServer();
EndProcedure

&AtClient
Procedure Unpack(Command)
	PackingListsClient.UnpackPackingList(ThisForm);
EndProcedure

&AtClient
Procedure FillInSeriesByReference(Command)
	ClearMessages();
	Filled1 = FillInSeriesByReferenceServer(CachedValues);
	
	If Filled1 Then
		NotificationText1 = NStr("vi = 'Seri được điền theo lệnh tiếp nhận';
								|ru = 'Серии заполнены по данным распоряжения на поступление.';
								|en = 'Batches are filled in by the receipt reference information.'; fa = 'Batches are filled in by the receipt reference information.';
								|it = 'Le serie sono compilate in base ai dati della disposizione di arrivo.';
								|pl = 'Serie wypełniono według zamówień na wpływy?';
								|tr = 'Parti giriş emrine göre dolduruldu.'");
		ShowUserNotification(NotificationText1, , , PictureLib.Information32);
	EndIf;
	
EndProcedure

&AtClient
Procedure SortAsc(Command)
	CurrentColumn = Items.Goods.CurrentItem;
	
	If CurrentColumn <> Undefined Then
		SortRows(CurrentColumn.Name, "ASC");
	EndIf;
EndProcedure

&AtClient
Procedure SortDesc(Command)
	CurrentColumn = Items.Goods.CurrentItem;
	
	If CurrentColumn <> Undefined Then
		SortRows(CurrentColumn.Name, "DESC");
	EndIf;
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()

	ConditionalAppearance.Items.Clear();

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsPackage.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.Package");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	Item.Appearance.SetParameterValue("TextColor", StyleColors.EmptyTableField);

	//

	ConditionalDesignParameters = ProductsServer.NewParametersForConditionalDesignOfUnitsOfMeasurement(True, True);
	ProductsServer.SetConditionalAppearanceOfUnitsOfMeasurement(ThisObject, ConditionalDesignParameters);

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
	ItemFilter.LeftValue = New DataCompositionField("Object.Status");
	ItemFilter.ComparisonType = DataCompositionComparisonType.InList;
	ValueList = New ValueList;
	ValueList.Add(Enums.GoodsReceiptNoteStatuses.ToReceive);
	ValueList.Add(Enums.GoodsReceiptNoteStatuses.InProgress);
	ValueList.Add(Enums.GoodsReceiptNoteStatuses.DataProcessorIsRequired);
	ItemFilter.RightValue = ValueList;
	
	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.MeasuredValueType");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotEqual;
	ItemFilter.RightValue = Enums.TypesOfMeasuredValues.NumberOfPieces;
	
	Item.Appearance.SetParameterValue("MarkIncomplete", False);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsNumberOfPackages.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Status");
	ItemFilter.ComparisonType = DataCompositionComparisonType.InList;
	ValueList = New ValueList;
	ValueList.Add(Enums.GoodsReceiptNoteStatuses.ToReceive);
	ValueList.Add(Enums.GoodsReceiptNoteStatuses.InProgress);
	ValueList.Add(Enums.GoodsReceiptNoteStatuses.DataProcessorIsRequired);
	ItemFilter.RightValue = ValueList;

	Item.Appearance.SetParameterValue("MarkIncomplete", False);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsProducts.Name);
	ItemField.Field = New DataCompositionField(Items.ProductsAdditionalInfoNomenclature.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Status");
	ItemFilter.ComparisonType = DataCompositionComparisonType.InList;
	ValueList = New ValueList;
	ValueList.Add(Enums.GoodsReceiptNoteStatuses.ToReceive);
	ValueList.Add(Enums.GoodsReceiptNoteStatuses.InProgress);
	ValueList.Add(Enums.GoodsReceiptNoteStatuses.DataProcessorIsRequired);
	ItemFilter.RightValue = ValueList;
	
	FilterGroup1 = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup1.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	
		ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
		ItemFilter.LeftValue = New DataCompositionField("Object.Goods.Barcode");
		ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
		
		ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
		ItemFilter.LeftValue = New DataCompositionField("Object.Goods.PackingListParent");
		ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	
	//

	ProductsServer.EstablishConditionalAppearanceOfProductCharacteristics(ThisForm);
	
	//
	ProductsServer.EstablishConditionalAppearanceOfProductSeries(ThisForm,
																		"SeriesAlwaysWHGoods");
	//

	ProductsServer.SetConditionalAppearanceOfStatusIndicationSeries(ThisForm,
																			True);
	
	//
	
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.PackagingGroup.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("PackagingGroup");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	Item.Appearance.SetParameterValue("Font", New Font(WindowsFonts.DefaultGUIFont, , , True, False, False, False, ));

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.BarcodeListProductsUnitOfMeasure.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.BarcodeListPackage.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("BarcodeList.Package");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	Item.Appearance.SetParameterValue("TextColor", StyleColors.EmptyTableField);

	//
	
	ConditionalDesignParameters = ProductsServer.NewParametersForConditionalDesignOfUnitsOfMeasurement();
	ConditionalDesignParameters.NameOfUnitField = "BarcodeListProductsUnitOfMeasure";
	ConditionalDesignParameters.PathToPackagingUnitField = "BarcodeList.Package";
	ProductsServer.SetConditionalAppearanceOfUnitsOfMeasurement(ThisObject, ConditionalDesignParameters);
	
	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.LabelsTemplate.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("LabelsTemplate");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;

	Item.Appearance.SetParameterValue("Font", New Font(WindowsFonts.DefaultGUIFont, , , True, False, False, False, ));

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.PriceTagTemplate.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("PriceTagTemplate");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;

	Item.Appearance.SetParameterValue("Font", New Font(WindowsFonts.DefaultGUIFont, , , True, False, False, False, ));

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ItemWeight.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("WeightBoolean");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;

	Item.Appearance.SetParameterValue("Font", New Font(WindowsFonts.DefaultGUIFont, , , True, False, False, False, ));

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.TheVolumeOfTheItem.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("VolumeBoolean");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;

	Item.Appearance.SetParameterValue("Font", New Font(WindowsFonts.DefaultGUIFont, , , True, False, False, False, ));

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.WarehouseGroupLine.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("WarehouseGroupBoolean");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;

	Item.Appearance.SetParameterValue("Font", New Font(WindowsFonts.DefaultGUIFont, , , True, False, False, False, ));

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.PackagingGroup.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("PackagingGroup");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;

	Item.Appearance.SetParameterValue("Font", New Font(WindowsFonts.DefaultGUIFont, , , True, False, False, False, ));
	
	//
	
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ProductsAdditionalInfoPackingList.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ProductsAdditionalInfoNomenclature.Name);
	
	FilterGroup1 = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup1.GroupType = DataCompositionFilterItemsGroupType.AndGroup;

	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.Barcode");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	
	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.BarcodeIsNotRecognized");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = 1;
	
		FilterGroup2 = FilterGroup1.Items.Add(Type("DataCompositionFilterItemGroup"));
		FilterGroup2.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
		
			FilterGroup3 = FilterGroup2.Items.Add(Type("DataCompositionFilterItemGroup"));
			FilterGroup3.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
			
				ItemFilter = FilterGroup3.Items.Add(Type("DataCompositionFilterItem"));
				ItemFilter.LeftValue = New DataCompositionField("Object.Goods.ThisIsAPackingList");
				ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
				ItemFilter.RightValue = True;
				
				ItemFilter = FilterGroup3.Items.Add(Type("DataCompositionFilterItem"));
				ItemFilter.LeftValue = New DataCompositionField("Object.Goods.PackingList");
				ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
			FilterGroup4 = FilterGroup2.Items.Add(Type("DataCompositionFilterItemGroup"));
			FilterGroup4.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
		
				ItemFilter = FilterGroup4.Items.Add(Type("DataCompositionFilterItem"));
				ItemFilter.LeftValue = New DataCompositionField("Object.Goods.ThisIsAPackingList");
				ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
				ItemFilter.RightValue = False;
				
				ItemFilter = FilterGroup4.Items.Add(Type("DataCompositionFilterItem"));
				ItemFilter.LeftValue = New DataCompositionField("Object.Goods.Products");
				ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<mã vạch không xác định>';
													|ru = '<неизвестный штрихкод>';
													|en = '<unknown barcode>'; fa = '<unknown barcode>';
													|it = '<codice a barre sconosciuto>';
													|pl = '<nieznany kod kreskowy>';
													|tr = '<bilinmeyen barkod>'"));
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsPackingList.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsProducts.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ProductsAdditionalInfoPackingList.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ProductsAdditionalInfoNomenclature.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.DataProcessorIsRequired");
	ItemFilter.RightValue = 1;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.SpecialTextColor);
	
	//
	
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsDocumentShipments.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.ThisIsAPackingList");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
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

	ProductsServer.SetConditionalAppearanceOfProductAssignment(ThisForm);
	
	//
	
	PackingListsServer.EstablishConditionalAppearanceTakingIntoAccountPackingLists(ThisForm);
	
	// Conditional appearance of quality control Attributes.
	Fields = QualityControl.Fields(
		Items.GoodsToControlQuality,
		Items.GoodsQualityConfirmationDate);
	FlagDisabled = New Array();
	QualityControl.AddFilter(FlagDisabled, "Object.Goods.ThisIsAPackingList", True);
	QualityControl.AddFilter(FlagDisabled, "QualityControlIsSupported", False);
	QualityControl.AddFilter(FlagDisabled, "Object.RecordOfAPreviouslyReceivedLot", True);
	QualityControl.SetupAppearance(ConditionalAppearance, Fields, FlagDisabled);
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsQualityConfirmationDate.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.SubjectToUnlocking");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsQualityConfirmationDate.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.ToControlQuality");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	Item.Appearance.SetParameterValue("ReadOnly", True);
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<chỉ dành cho các lô hàng cần được mở khóa>';
													|ru = '<только для партий подлежащих разблокировке>';
													|en = '<only for lots to be unlocked>'; fa = '<only for lots to be unlocked>';
													|it = '<only for lots to be unlocked>';
													|pl = '<only for lots to be unlocked>';
													|tr = '<yalnızca kilidi kaldırılacak lotlar için>'"));
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	Item.Appearance.SetParameterValue("TextColor", StyleColors.TextColorOfCanceledRowOfDocument);
	
EndProcedure

&AtServer
Procedure OnReadCreateAtServer()
	
	If ValueIsFilled(Object.ReferenceOrder) Then
		TMCommonUseClientServer.AddSelectionParameter(Items.Warehouse, "Ref", Documents.GoodsReceiptNote.AdvancedWarehouses(Object));
	EndIf;
	
	SetFormFunctionalOptionParameters(New Structure("Warehouse, Premise",Object.Warehouse, Object.Premise));
	
	RetailPriceType        = Common.ObjectAttributeValue(Object.Warehouse, "RetailPriceType");
	
	SetPrivilegedMode(True);
	If ValueIsFilled(Object.ReferenceOrder) Then 
		ReferenceCompany = Common.ObjectAttributeValue(Object.ReferenceOrder, "Organization");
	EndIf;
	SetPrivilegedMode(False);
	
	SeriesSpecificationParameters = New FixedStructure(ProductsServer.SeriesSpecificationParameters(Object, Documents.GoodsReceiptNote));
	
	InstallAddressDependentStorage();
	
	Items.InformationGroup.Picture = CommonClientServer.CommentPicture(Object.Comment);
	
	Items.Premise.Visible = WarehousesServer.UseWarerooms(Object.Warehouse,Object.Date);
	
	If Object.WarehouseOperation = Enums.WarehouseTransactions.ReturnOfGoodsNotReceivedByRecipient
		Or Object.WarehouseOperation = Enums.WarehouseTransactions.ReturnOfGoodsNotReceivedByRecipientNotUsed Then
		Items.IncomingDocumentDate.Visible  = False;
		Items.IncomingDocumentNumber.Visible = False;
		
		Items.FillInTheReturnedQuantity.Visible    = True;
		Items.FillInOnlyQuantity.Visible          = False;
		Items.FillInOnlyProducts.Visible        = False;
		Items.FillInProductsAndQuantity.Visible   = False;
		Items.GoodsFillInSeriesByReference.Visible = False;
		Items.GoodsVerifyQuantity.Visible          = False;
		Items.ReferenceOrderPresentation.Visible          = False;
	Else
		Items.ReferenceOrderPresentation.Visible = True;
		Items.GoodsDocumentShipments.Visible    = False;
		
		Items.FillInTheReturnedQuantity.Visible    = False;
		
		Items.GoodsAddFromShipmentDocuments.Visible = False;
	EndIf;
	
	UsePackages              = GetFunctionalOption("UseItemPackages");
	Items.ListOfPackagings.Visible = UsePackages;
	Items.PackagingGroup.Visible  = UsePackages;
	
	Items.BarcodeListCreateBarcode.Visible = AccessRight("Update", Metadata.InformationRegisters.ItemsBarcodes);
	Items.ListOfBarcodePrintingCodes.Visible = AccessRight("View", Metadata.DataProcessors.PrintPriceTagsAndLabels);
	
	PackingListsServer.WhenReadingCreatingFormWithPackingLists(ThisForm, Object.Goods,
		Object.Ref.Metadata().ObjectPresentation);
	FillInServiceDetailsOfTSGoods(False);
	
	DisplayFilterPageDeselectIfNecessary();
	
	YouCanSpecifySeriesByReference = Documents.GoodsReceiptNote.YouCanSpecifySeriesByReference(Object, False);
	
	ShowOrderPresentation(ReferenceOrderPresentation, Object.ReferenceOrder);
	
	ProcessingOfTabularForms.InitializeRowCache(Items.Goods);
	CacheQualityControl = QualityControl.DataCacheOfMechanism(Object);
	
	QualityControlIsSupported = QualityControl.QualityControlIsSupported(Object.ReferenceOrder);
	
EndProcedure

&AtClient
Procedure OpenSelectionOfSeries(Text = "", CurrentData = Undefined)
	
	If ProductsClient.YouNeedServerCallToSpecifySeries(ThisForm, SeriesSpecificationParameters, Text, CurrentData)Then
		
		If CurrentData = Undefined Then
			CurDataId = Items.Goods.CurrentData.GetID();
		Else
			CurDataId = CurrentData.GetID();
		EndIf;

		ParametersOfSeriesIndicationForm = ParametersOfSeriesIndicationForm(CurDataId);
		
		ReturnValue_1 = Undefined;

		CallbackDescription = New CallbackDescription("OpenSelectionOfSeriesCompletion",
														ThisObject,
														New Structure("ParametersOfSeriesIndicationForm", ParametersOfSeriesIndicationForm));
		
		OpenForm(ParametersOfSeriesIndicationForm.FormName,
						ParametersOfSeriesIndicationForm,
						ThisForm
						,
						,
						,
						,
						CallbackDescription,
						FormWindowOpeningMode.LockOwnerWindow);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure OpenSelectionOfSeriesCompletion(Result, AdditionalParameters) Export
    
    ParametersOfSeriesIndicationForm = AdditionalParameters.ParametersOfSeriesIndicationForm;
    
    
    ReturnValue_1 = Result;
    
    If ReturnValue_1 <> Undefined Then
        ProcessSeriesIndication_Server(ParametersOfSeriesIndicationForm);
    EndIf;

EndProcedure

#Region OnChangeAttributes

&AtServer
Procedure WarehouseSpaceWhenServerChanges(TagName, DirectModificationOfWarehouseField = False)
	
	SetFormFunctionalOptionParameters(New Structure("Warehouse, Premise",Object.Warehouse, Object.Premise));
	
	InstallAddressDependentStorage();
	
	WarehouseDetails = Common.ObjectAttributesValues(Object.Warehouse, "RetailPriceType, 
		|UseGoodsReceiptNoteStatuses");
	
	RetailPriceType                    = WarehouseDetails.RetailPriceType;
	UseGoodsReceiptNoteStatuses = WarehouseDetails.UseGoodsReceiptNoteStatuses;
	
	UseGoodsReceiptNoteStatuses = ?(ValueIsFilled(UseGoodsReceiptNoteStatuses), 
		UseGoodsReceiptNoteStatuses, False);
	
	If UseGoodsReceiptNoteStatuses Then
		Object.Status = Enums.GoodsReceiptNoteStatuses.ToReceive;
	Else
		Object.Status = Enums.GoodsReceiptNoteStatuses.Accepted;
	EndIf;
	
	SeriesSpecificationParameters = New FixedStructure(ProductsServer.SeriesSpecificationParameters(Object, Documents.GoodsReceiptNote));
	ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);
	If QualityControl.UpdateActionParameters(
			Documents.GoodsReceiptNote,
			Object,
			CacheQualityControl,
			DirectModificationOfWarehouseField) Then
			
		StructureOfActions = New Structure();
		StructureOfActions.Insert("FillInCheckQualityDateOfQualityConfirmation", CacheQualityControl);
		StructureOfActions.Insert("FillInUnblockableDateOfQualityConfirmation", CacheQualityControl);
		BatchProcessingOfTablePartServer.TreatTS(Object.Goods, StructureOfActions);
		
	EndIf;
	
	Items.Premise.Visible = WarehousesServer.UseWarerooms(Object.Warehouse,Object.Date);
	
EndProcedure

&AtServer
Procedure StatusOnChangeServer()
	
	UpdateBlankAutoTag(Object.Status, Items.Goods);
	
	SeriesSpecificationParameters = New FixedStructure(ProductsServer.SeriesSpecificationParameters(Object, Documents.GoodsReceiptNote));
	ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);
	
EndProcedure

&AtServer
Procedure DateOnChangeServer()
	
	InstallAddressDependentStorage();
	PrepareFillSetSeriesVisibility();
	Items.Premise.Visible = WarehousesServer.UseWarerooms(Object.Warehouse,Object.Date);
	If QualityControl.UpdateActionParameters(
			Documents.GoodsReceiptNote,
			Object,
			CacheQualityControl) Then
			
		StructureOfActions = New Structure();
		StructureOfActions.Insert("FillInCheckQualityDateOfQualityConfirmation", CacheQualityControl);
		StructureOfActions.Insert("FillInUnblockableDateOfQualityConfirmation", CacheQualityControl);
		BatchProcessingOfTablePartServer.TreatTS(Object.Goods, StructureOfActions);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure GoodsAtEndOfEditingForServerCall()

	GoodsAtEndOfEditingOnServer();

EndProcedure

&AtServer
Procedure GoodsAtEndOfEditingOnServer()

	FormEvents.WhenChangingElement(ThisObject, "Goods");
	
EndProcedure

#EndRegion

#Region SelectionAndProcessingOfQuantityVerification

&AtClient
Procedure CheckQuantityInTheDocumentClient()
	
	StorageAddress = "";
	OnlyNonLabeledProductsHaveBeenUnloaded = False;
	
	ClearMessages();
	
	If CheckGoodsAndPutThemInTemporaryStorage(StorageAddress, OnlyNonLabeledProductsHaveBeenUnloaded) Then 
		
		If ThereAreLabeledProducts Then
			
			OpeningParameters = New Structure;
			OpeningParameters.Insert("AddressInTempStorage",             StorageAddress);
			OpeningParameters.Insert("TabularSectionName",                     "Goods");
			OpeningParameters.Insert("Ref",                                Object.Ref);
			OpeningParameters.Insert("GoodsQuantityExcessIsAllowed",  True);
			OpeningParameters.Insert("SeriesSpecificationParameters",                SeriesSpecificationParameters);
			OpeningParameters.Insert("OutputWeightVolume",                      True);
			OpeningParameters.Insert("OnlyNonLabeledProductsHaveBeenUnloaded", OnlyNonLabeledProductsHaveBeenUnloaded);
			
			CallbackDescription = New CallbackDescription("CheckQuantityInTheDocumentCompletion", ThisForm);
			OpenForm("CommonForm.CheckDocumentPopulation", 
				OpeningParameters,,,,, CallbackDescription, FormWindowOpeningMode.LockOwnerWindow);
			
		Else
			
//			Modifiability = Truth;
			
			OpeningParameters = New Structure;
			OpeningParameters.Insert("AddressInTempStorage",            StorageAddress);
			OpeningParameters.Insert("SeriesSpecificationParameters",               SeriesSpecificationParameters);
			OpeningParameters.Insert("Warehouse",                                Object.Warehouse);
			OpeningParameters.Insert("Premise",                            Object.Premise);
			OpeningParameters.Insert("Status",                               Object.Status);
			OpeningParameters.Insert("WarehouseOperation",                    Object.WarehouseOperation);
			OpeningParameters.Insert("ReferenceOrder",                         Object.ReferenceOrder);
			OpeningParameters.Insert("WarehouseDocument",                                Object.Ref);
			OpeningParameters.Insert("PackingListParent",              PackingListParent);
			OpeningParameters.Insert("ThereAreLabeledProducts",             ThereAreLabeledProducts);
			OpeningParameters.Insert("ControlledLotReference",                 Object.ControlledLotReference);
			OpeningParameters.Insert("RecordOfAPreviouslyReceivedLot",       Object.RecordOfAPreviouslyReceivedLot);
			
			CallbackDescription = New CallbackDescription("ChangeTablePartBasedOnResultsOfCheck", ThisForm);
			OpenForm("DataProcessor.GoodsQuantityCheckInGoodsReceiptNote.Form.Form",
				OpeningParameters, ThisForm, UUID,,,CallbackDescription);
				
		EndIf;
			
	EndIf;
	
EndProcedure

&AtClient
Procedure ChangeTablePartBasedOnResultsOfCheck(Result, Var_Parameters) Export
	
	If Not ValueIsFilled(Result) Then
		Return;
	EndIf;
	
	ChangeTablePartBasedOnResultsOfCheckServer(Result, CachedValues);
	
EndProcedure

&AtClient
Procedure CheckQuantityInTheDocumentCompletion(Result, AdditionalParameters) Export

	ReturnParameters = Result;
	If ReturnParameters <> Undefined Then
		ChangeTabularPartBasedOnResultsOfAddCheck(ReturnParameters, ?(CachedValues = Undefined, BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues(), CachedValues));
		Modified = True;
	EndIf;

EndProcedure

&AtServer
Procedure ChangeTabularPartBasedOnResultsOfAddCheck(ReturnParameters, CachedValues)
	
	Modified = True;
	
	GoodsTable = GetFromTempStorage(ReturnParameters.Goods);
	
	LinesToDelete = New Array;
	RowsToProcess = New Array;
	ProcessedRowsAttribute = New Array;
	
	StructureOfActions = New Structure;
	AddActionsToStructureWhenChangingPackagesNumber(ThisObject, StructureOfActions);
	
	For Each SourceRow In GoodsTable Do
		
		Filter = New Structure("Products, Characteristic, Series, BatchesIndicationStatus, Package");
		FillPropertyValues(Filter, SourceRow);
		FoundRows = Object.Goods.FindRows(Filter);
		
		If FoundRows.Count() = 0 Then
			
			TSRow = Object.Goods.Add();
			FillPropertyValues(TSRow, SourceRow);
			ProcessedRowsAttribute.Add(TSRow);
			
		Else
			For Each TSRow In FoundRows Do
				If SourceRow.NumberOfPackages = 0 Then
					Break;
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
					LinesToDelete.Add(TSRow);
				Else
					RowsToProcess.Add(TSRow);
				EndIf;
				
			EndDo;
		EndIf;
		
	EndDo;
	
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		RowsToProcess,
		StructureOfActions,
		Object.Goods,
		CachedValues);
	
	StructureOfActions.Insert("FillInPlaceAttributeThatRequiresProcessing");
	StructureOfActions.Insert("FillInCheckQualityDateOfQualityConfirmation", CacheQualityControl);
	StructureOfActions.Insert("FillInUnblockableDateOfQualityConfirmation", CacheQualityControl);
	
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		ProcessedRowsAttribute,
		StructureOfActions,
		Object.Goods,
		CachedValues);
	
	For Each TSRow In LinesToDelete Do
		Object.Goods.Delete(TSRow);
	EndDo;
	
	FillInServiceDetailsOfTSGoods(False,CachedValues);
	
	ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);
	RecalculateNumberOfSeats();
	
	DisplayFilterPageDeselectIfNecessary();
	
	ReusablePackageServer.UpdateFillingStateOfMultiTurnContainer(Object.ReusablePackageFillingStatus);

	FormEvents.WhenChangingElement(ThisObject, "Goods");

EndProcedure

&AtServer
Procedure ChangeTablePartBasedOnResultsOfCheckServer(Result, CachedValues)
	
	Modified = True;
	
	TSResult = GetFromTempStorage(Result);
	
	Object.Goods.Load(TSResult);
	
	StructureOfActions = New Structure();
	StructureOfActions.Insert("FillInCheckQualityDateOfQualityConfirmation", CacheQualityControl);
	StructureOfActions.Insert("FillInUnblockableDateOfQualityConfirmation", CacheQualityControl);
	
	BatchProcessingOfTablePartServer.TreatTS(Object.Goods, StructureOfActions);
	
	FillInServiceDetailsOfTSGoods(False,CachedValues);
	
	ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);
	RecalculateNumberOfSeats();
	
	DisplayFilterPageDeselectIfNecessary();
	
	ReusablePackageServer.UpdateFillingStateOfMultiTurnContainer(Object.ReusablePackageFillingStatus);

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
	StructureOfActionsWithAddedStrings.Insert("FillInPlaceAttributeThatRequiresProcessing");
	StructureOfActionsWithAddedStrings.Insert("FillInMeasuredValueTypeAttribute", New Structure("Products", "MeasuredValueType"));
	StructureOfActionsWithAddedStrings.Insert("FillPackageWeight",New Structure("Products, Package", "PackageWeight"));
	StructureOfActionsWithAddedStrings.Insert("FillPackageVolume",New Structure("Products, Package", "PackageVolume"));
	StructureOfActionsWithAddedStrings.Insert("FillInUnitOfWeight",New Structure("Products, Package", "UnitOfMeasureForWeight"));
	StructureOfActionsWithAddedStrings.Insert("FillInVolumeUnit",New Structure("Products, Package", "UnitOfMeasureForVolume"));
	StructureOfActionsWithAddedStrings.Insert("RecalculateWeightVolume");
	StructureOfActionsWithAddedStrings.Insert("FillInCheckQualityDateOfQualityConfirmation",
		CacheQualityControl);
	StructureOfActionsWithAddedStrings.Insert("FillInUnblockableDateOfQualityConfirmation",
		CacheQualityControl);
	
	AddActionsToStructureWhenChangingPackagesNumber(ThisObject, StructureOfActionsWithAddedStrings);
	
	StructureOfActionsWithModifiedStrings = New Structure;
	StructureOfActionsWithModifiedStrings.Insert("FillInPlaceAttributeThatRequiresProcessing");
	StructureOfActionsWithModifiedStrings.Insert("RecalculateWeightVolume");
	
	AddActionsToStructureWhenChangingPackagesNumber(ThisObject, StructureOfActionsWithModifiedStrings);
	
	StructureOfActionsWithLinesFromPackingLists = New Structure;
	
	StructureOfActionsWithLinesFromPackingLists.Insert("FillInFeatureAttribute",
		New Structure("Products", "ItemVariantsAreUsed"));
	StructureOfActionsWithLinesFromPackingLists.Insert("FillInProductTypeAttribute_",
		New Structure("Products", "ItemsType"));
	StructureOfActionsWithLinesFromPackingLists.Insert("FillInArticleAttribute",
		New Structure("Products", "SKU"));
	StructureOfActionsWithLinesFromPackingLists.Insert("FillInMeasuredValueTypeAttribute", New Structure("Products", "MeasuredValueType"));
	StructureOfActionsWithLinesFromPackingLists.Insert("FillPackageWeight",New Structure("Products, Package", "PackageWeight"));
	StructureOfActionsWithLinesFromPackingLists.Insert("FillPackageVolume",New Structure("Products, Package", "PackageVolume"));
	StructureOfActionsWithLinesFromPackingLists.Insert("FillInUnitOfWeight",New Structure("Products, Package", "UnitOfMeasureForWeight"));
	StructureOfActionsWithLinesFromPackingLists.Insert("FillInVolumeUnit",New Structure("Products, Package", "UnitOfMeasureForVolume"));
	StructureOfActionsWithLinesFromPackingLists.Insert("RecalculateWeightVolume");
	
	StructureOfActions = BarcodingOfItemsClient.BarcodeProcessingParameters();
	StructureOfActions.Barcodes                              = BarcodeData_5;
	StructureOfActions.StructureOfActionsWithAddedStrings = StructureOfActionsWithAddedStrings;
	StructureOfActions.StructureOfActionsWithModifiedStrings  = StructureOfActionsWithModifiedStrings;
	StructureOfActions.SeriesSpecificationParameters                 = SeriesSpecificationParameters;
	StructureOfActions.GoodsOnly                           = True;
	StructureOfActions.WHBarcodes                           = True;
	StructureOfActions.ConsiderPackingLists              = UsePackingLists;
	StructureOfActions.StructureOfActionsWithLinesFromPackingLists = StructureOfActionsWithLinesFromPackingLists;
	StructureOfActions.WorkOutChangingPackingLists   = True;
	StructureOfActions.CurrentPackingList                 = PackingListParent;
	StructureOfActions.ToFillTheAppointment                    = Not (Object.WarehouseOperation = PredefinedValue("Enum.WarehouseTransactions.ReturnOfGoodsNotReceivedByRecipient"));
	
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
Procedure ProcessBarcodesServer(StructureOfActions, CachedValues)
	
	BarcodingOfItemsServer.ProcessBarcodes(ThisObject, Object, StructureOfActions, CachedValues);
	
	If StructureOfActions.CurrentRow <> Undefined Then
		StructureOfActionsWithCurLine = New Structure;
		StructureOfActionsWithCurLine.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
		StructureOfActionsWithCurLine.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));
		StructureOfActionsWithCurLine.Insert("FillInMeasuredValueTypeAttribute", New Structure("Products", "MeasuredValueType"));
		StructureOfActionsWithCurLine.Insert("FillPackageWeight",New Structure("Products, Package", "PackageWeight"));
		StructureOfActionsWithCurLine.Insert("FillPackageVolume",New Structure("Products, Package", "PackageVolume"));
		StructureOfActionsWithCurLine.Insert("FillInUnitOfWeight",New Structure("Products, Package", "UnitOfMeasureForWeight"));
		StructureOfActionsWithCurLine.Insert("FillInVolumeUnit",New Structure("Products, Package", "UnitOfMeasureForVolume"));
		StructureOfActionsWithCurLine.Insert("RecalculateWeightVolume");
		
		CurrentRow = Object.Goods.FindByID(StructureOfActions.CurrentRow);
		
		BatchProcessingOfTablePartServer.ProcessTSString(CurrentRow, StructureOfActionsWithCurLine, CachedValues);
	EndIf;
	
	PackingSheetsBeforeProcessing = PackingLists.Unload(, "PackingList");
	
	PackingSheetsAfterProcessing = PackingLists.Unload(, "PackingList");
	CommonClientServer.ArraysDifference(PackingSheetsAfterProcessing, PackingSheetsBeforeProcessing);
	
	DeleteDuplicatesOfProductsWithoutQuantity(True, PackingSheetsAfterProcessing);
	RecalculateNumberOfSeats();
	DecorationFilterNavigationLinkProcessingServer("RemoveSelection_");
	
EndProcedure

#EndRegion

#Region SetOfSeries

&AtServer
Procedure FillInStatusesOfSpecifyingSeriesWhenEditingLineTS(IDCurrentRow, CachedValues)
	
	ProductsServer.FillInStatusesOfSpecifyingSeriesWhenEditingLineTS(Object, 
				SeriesSpecificationParameters, IDCurrentRow, CachedValues);
	
	If IDCurrentRow = Undefined Then
		Return;
	EndIf;
	
	CurrentData = Object.Goods.FindByID(IDCurrentRow);
	
	If CurrentData <> Undefined
		And CurrentData.ThisIsAPackingList Then
		CurrentData.BatchesIndicationStatus = 0;
	EndIf;
	
EndProcedure

&AtServer
Procedure ProcessSeriesIndication_Server(ParametersOfSeriesIndicationForm)
	
	Actions = New Structure;
	Actions.Insert("UpdateNumberOfProductsWhenRegistering", True);
	AddActionsToStructureWhenChangingPackagesNumber(ThisObject, Actions);
	Actions.Insert("FillInFeatureAttribute", New Structure("Products", "ItemVariantsAreUsed"));
	Actions.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
	Actions.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));
	Actions.Insert("CheckSeriesCalculateStatus", New Structure("Warehouse, SeriesSpecificationParameters", Object.Warehouse, SeriesSpecificationParameters));
	Actions.Insert("FillInMeasuredValueTypeAttribute", New Structure("Products", "MeasuredValueType"));
	Actions.Insert("FillPackageWeight",New Structure("Products, Package", "PackageWeight"));
	Actions.Insert("FillPackageVolume",New Structure("Products, Package", "PackageVolume"));
	Actions.Insert("FillInUnitOfWeight",New Structure("Products, Package", "UnitOfMeasureForWeight"));
	Actions.Insert("FillInVolumeUnit",New Structure("Products, Package", "UnitOfMeasureForVolume"));
	Actions.Insert("RecalculateWeightVolume");
	Actions.Insert("FillInCheckQualityDateOfQualityConfirmation", CacheQualityControl);
	Actions.Insert("FillInUnblockableDateOfQualityConfirmation", CacheQualityControl);
	
	ProductsServer.ProcessSeriesIndication_(Object, SeriesSpecificationParameters, ParametersOfSeriesIndicationForm, Actions);
	
	PackingListsServer.RenumberLines(ThisObject, Object.Goods);
	
EndProcedure

&AtClient
Procedure OpenSeriesSelectionWhenScanningProductBarCode()
	
	If CurDataId = Undefined Then
		Return;
	EndIf;
	
	CurrentData = Object.Goods.FindByID(CurDataId);
	OpenSelectionOfSeries(,CurrentData);
	
EndProcedure

&AtServer
Function ParametersOfSeriesIndicationForm(CurDataId)
	
	Return ProductsServer.ParametersOfSeriesIndicationForm(Object, SeriesSpecificationParameters, CurDataId, ThisObject);
	
EndFunction

#EndRegion

#Region AdditionalInformationPanel

&AtServer
Procedure TransferPackage(Package, Id, CachedValues)
	
	CurrentRow = Object.Goods.FindByID(Id);
	CurrentRow.Package = Package;
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateNumberOfPackages");
	StructureOfActions.Insert("FillPackageWeight",New Structure("Products, Package", "PackageWeight"));
	StructureOfActions.Insert("FillPackageVolume",New Structure("Products, Package", "PackageVolume"));
	StructureOfActions.Insert("FillInUnitOfWeight",New Structure("Products, Package", "UnitOfMeasureForWeight"));
	StructureOfActions.Insert("FillInVolumeUnit",New Structure("Products, Package", "UnitOfMeasureForVolume"));
	StructureOfActions.Insert("RecalculateNumberOfPackages");
	StructureOfActions.Insert("RecalculateWeightVolume");
	
	BatchProcessingOfTablePartServer.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
	LockFormDataForEdit();
	Modified = True;
	
EndProcedure

&AtClient
Procedure ProductsWhenActivatingLineOnClient()
	
	CurrentRow = Items.Goods.CurrentData;
	
	If CurrentRow <> Undefined Then
		
		DisplayAdditionalInformationOnProducts(
			CurrentRow.Products,
			CurrentRow.Characteristic,
			CurrentRow.Package);
		
		Items.ListOfPackagings.CurrentRow = CurrentRow.Package;
		
	Else
		
		DisplayAdditionalInformationOnProducts();
		
	EndIf;
	
EndProcedure

&AtServer
Procedure ProductsOnChangeServer(CachedValues)
	
	CurrentRow = Object.Goods.FindByID(Items.Goods.CurrentRow);
	
	StructureOfActionsWithCurLine = New Structure;
	StructureOfActionsWithCurLine.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
	StructureOfActionsWithCurLine.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));
	StructureOfActionsWithCurLine.Insert("CheckCharacteristicsByOwner", CurrentRow.Characteristic);
	StructureOfActionsWithCurLine.Insert("CheckFillPackageByOwner", CurrentRow.Package);
	StructureOfActionsWithCurLine.Insert("RecalculateNumberOfUnits");
	StructureOfActionsWithCurLine.Insert("ProductsOnChangeOverridable", New Structure("FormName, TabularSectionName",
		FormName, "Goods"));
	StructureOfActionsWithCurLine.Insert("CheckFillAssignment");
	StructureOfActionsWithCurLine.Insert("FillInMeasuredValueTypeAttribute", New Structure("Products", "MeasuredValueType"));
	StructureOfActionsWithCurLine.Insert("FillPackageWeight",New Structure("Products, Package", "PackageWeight"));
	StructureOfActionsWithCurLine.Insert("FillPackageVolume",New Structure("Products, Package", "PackageVolume"));
	StructureOfActionsWithCurLine.Insert("FillInUnitOfWeight",New Structure("Products, Package", "UnitOfMeasureForWeight"));
	StructureOfActionsWithCurLine.Insert("FillInVolumeUnit",New Structure("Products, Package", "UnitOfMeasureForVolume"));
	StructureOfActionsWithCurLine.Insert("RecalculateWeightVolume");
	StructureOfActionsWithCurLine.Insert("FillInCheckQualityDateOfQualityConfirmation",
		CacheQualityControl);
	StructureOfActionsWithCurLine.Insert("FillInUnblockableDateOfQualityConfirmation",
		CacheQualityControl);
	StructureOfActionsWithCurLine.Insert("CheckSeriesCalculateStatus", 
		New Structure("Warehouse, SeriesSpecificationParameters", Object.Warehouse, SeriesSpecificationParameters));
	
	PackingListsServer.ProductsPackingListWhenChanged(ThisObject, Object.Goods,
		"GoodsProducts", CachedValues, StructureOfActionsWithCurLine);
		
	DisplayAdditionalInformationOnProducts(CurrentRow.Products, CurrentRow.Characteristic, CurrentRow.Package);
	
EndProcedure

&AtServer
Procedure DisplayAdditionalInformationOnProducts(Products = Undefined , Characteristic = Undefined, Package = Undefined)
	
	ProductAttributes = New Structure;
	ProductAttributes.Insert("ViewLabelTemplate");
	ProductAttributes.Insert("PriceTagTemplateOfForm");
	ProductAttributes.Insert("ProductPriceTagTemplate");
	ProductAttributes.Insert("ProductLabelTemplate");
	ProductAttributes.Insert("PackagingGroup");
	ProductAttributes.Insert("PicturesFile");
	ProductAttributes.Insert("WarehouseGroup");
	
	If Not ValueIsFilled(Products) Then
		
		Products = Catalogs.Products.EmptyRef();
		Characteristic = Catalogs.ItemsCharacteristics.EmptyRef();
		Package = Catalogs.PackagesAndUnitsOfMeasure.EmptyRef();
		
		LabelTemplateLine = "";
		PriceTagTemplateLine = "";
		PictureAddress = "";
		PackagingSetLine = "";
		
	Else
		
		ProductAttributes.Insert("ViewLabelTemplate", "ProductKind.LabelsTemplate");
		ProductAttributes.Insert("PriceTagTemplateOfForm", "ProductKind.PriceTagTemplate");
		ProductAttributes.Insert("ProductPriceTagTemplate", "PriceTagTemplate");
		ProductAttributes.Insert("ProductLabelTemplate", "LabelsTemplate");
		ProductAttributes.Insert("PackagingGroup", "PackagingGroup");
		ProductAttributes.Insert("PicturesFile", "PicturesFile");
		ProductAttributes.Insert("WarehouseGroup", "WarehouseGroup");
		ProductAttributes = Common.ObjectAttributesValues(Products,ProductAttributes);
		
	EndIf;
		
	// Update the warehouse group.
	If Not ValueIsFilled(ProductAttributes.WarehouseGroup) Then
		Label = NStr("vi = '<Chưa chỉ ra>';
					|ru = '<Не указан>';
					|en = '<not specified>'; fa = '<مشخص نشده>';
					|it = '<non specificato>';
					|pl = '<Nie określono>';
					|tr = '<Belirtilmedi>'");
		WarehouseGroupBoolean = False;
		WarehouseGroupLine = Label;
	Else
		WarehouseGroupBoolean = True;
		WarehouseGroupLine = String(ProductAttributes.WarehouseGroup);
	EndIf;
	
	PackingStructure = Catalogs.PackagesAndUnitsOfMeasure.CoefficientWeightVolumeOtherPackingDetails(Package,Products,,False);
	ProductAttributes.Insert("Weight", PackingStructure.Net_Weight);
	ProductAttributes.Insert("VolumeM3", PackingStructure.VolumeM3);
	
	// Update the spring nomenclature.
	If Not ValueIsFilled(ProductAttributes.Weight) Then
		Label = NStr("vi = '<Chưa chỉ ra>';
					|ru = '<Не указан>';
					|en = '<not specified>'; fa = '<مشخص نشده>';
					|it = '<non specificato>';
					|pl = '<Nie określono>';
					|tr = '<Belirtilmedi>'");
		WeightBoolean = False;
		ItemWeight = Label;
	Else
		WeightBoolean = True;
		ItemWeight = String(ProductAttributes.Weight) + " " + UnitOfMeasureForWeight;
	EndIf;
	
	// Update the volume nomenclature.
	If Not ValueIsFilled(ProductAttributes.VolumeM3) Then
		Label = NStr("vi = '<Chưa chỉ ra>';
					|ru = '<Не указан>';
					|en = '<not specified>'; fa = '<مشخص نشده>';
					|it = '<non specificato>';
					|pl = '<Nie określono>';
					|tr = '<Belirtilmedi>'");
		VolumeBoolean = False;
		TheVolumeOfTheItem = Label;
	Else
		VolumeBoolean = True;
		TheVolumeOfTheItem = String(ProductAttributes.VolumeM3) + " " + UnitOfMeasureForVolume;
	EndIf;
	
	// Update the label template.
	If Not ValueIsFilled(ProductAttributes.ProductLabelTemplate) Then
		If Not ValueIsFilled(ProductAttributes.ViewLabelTemplate) Then
			Label = NStr("vi = '<Chưa chỉ ra>';
						|ru = '<Не указан>';
						|en = '<not specified>'; fa = '<مشخص نشده>';
						|it = '<non specificato>';
						|pl = '<Nie określono>';
						|tr = '<Belirtilmedi>'");
			LabelsTemplate = False;
			LabelTemplateLine = Label;
		Else
			LabelsTemplate = True;
			LabelTemplateLine = String(ProductAttributes.ViewLabelTemplate);
		EndIf;
	Else
		LabelsTemplate = True;
		LabelTemplateLine = String(ProductAttributes.ProductLabelTemplate);
	EndIf;
	
	// Update the Price tag template.
	If Not ValueIsFilled(ProductAttributes.ProductPriceTagTemplate) Then
		If Not ValueIsFilled(ProductAttributes.PriceTagTemplateOfForm) Then
			Label = NStr("vi = '<Chưa chỉ ra>';
						|ru = '<Не указан>';
						|en = '<not specified>'; fa = '<مشخص نشده>';
						|it = '<non specificato>';
						|pl = '<Nie określono>';
						|tr = '<Belirtilmedi>'");
			PriceTagTemplateLine = Label;
			PriceTagTemplate = False;
		Else
			PriceTagTemplate = True;
			PriceTagTemplateLine = String(ProductAttributes.PriceTagTemplateOfForm);
		EndIf;
	Else
		PriceTagTemplate = True;
		PriceTagTemplateLine = String(ProductAttributes.ProductPriceTagTemplate);
	EndIf;
	
	// Update the set of packages.
	If Not ValueIsFilled(ProductAttributes.PackagingGroup) Then
		Label = NStr("vi = '<Không sử dụng đóng gói>';
					|ru = '<Упаковки не используются>';
					|en = '<Packaging units are not used>'; fa = '<Packaging units are not used>';
					|it = '<Imballaggi non vengono usati>';
					|pl = '<Opakowania nie są wykorzystywane>';
					|tr = '<paketleme üniteleri kullanılmamaktadır>'");	
		PackagingSetLine = Label;
		PackagingGroup = False;
	Else
		PackagingGroup = True;
		PackagingSetLine = String(ProductAttributes.PackagingGroup);
	EndIf;
	
	// Refresh the picture.
	If ValueIsFilled(ProductAttributes.PicturesFile) Then
		Try
			PictureAddress = FilesOperations.FileData(ProductAttributes.PicturesFile, UUID).RefToBinaryFileData;
		Except
			PictureAddress = "";
			Items.PictureAddress.NonselectedPictureText = NStr("vi = 'Lỗi đọc tập tin hình ảnh';
																|ru = 'Ошибка при чтении файла изображения';
																|en = 'An error occurred when reading the image file'; fa = 'An error occurred when reading the image file';
																|it = 'Errore durante la lettura del file d''immagine';
																|pl = 'Błąd przy czytaniu pliku obrazu';
																|tr = 'Resim dosyası okunurken hata oluştu'");
			Items.PictureAddress.TextColor 			   = StyleColors.ErrorNoteText;
		EndTry;
	Else
		PictureAddress = "";
		Items.PictureAddress.NonselectedPictureText = NStr("vi = 'Không có hình ảnh';
															|ru = 'Изображение отсутствует';
															|en = 'No image'; fa = 'بدون تصویر';
															|it = 'Nessuna immagine';
															|pl = 'Brak obrazu';
															|tr = 'Görsel yok'");
		Items.PictureAddress.TextColor               = StyleColors.NotSelectedPictureTextColor;
	EndIf;
	
	// Set selections in lists.
	If Not ValueIsFilled(Products)
		Or ProductAttributes.PackagingGroup = IndividualPackagingSet Then
		CommonClientServer.SetDynamicListFilterItem(ListOfPackagings, "Owner", Products,
			DataCompositionComparisonType.Equal,,True);
	Else
		CommonClientServer.SetDynamicListFilterItem(ListOfPackagings, "Owner", ProductAttributes.PackagingGroup,
			DataCompositionComparisonType.Equal,,True);
	EndIf;
	
	CommonClientServer.SetDynamicListFilterItem(ListOfPackagings, "MeasuredValueType", Enums.TypesOfMeasuredValues.Package,
			DataCompositionComparisonType.Equal,,True);
	
	CommonClientServer.SetDynamicListFilterItem(BarcodeList, "Products",Products,
		DataCompositionComparisonType.Equal,,True);
	
	CommonClientServer.SetDynamicListFilterItem(BarcodeList, "Characteristic",Characteristic,
		DataCompositionComparisonType.Equal,,True);
	
EndProcedure

&AtServer
Procedure PackingListWhenChangingColor(CachedValues)
	
	CurrentRow = Object.Goods.FindByID(Items.Goods.CurrentRow);
	
	StructureOfActionsWithCurLine = New Structure;
	StructureOfActionsWithCurLine.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
	StructureOfActionsWithCurLine.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));
	StructureOfActionsWithCurLine.Insert("CheckCharacteristicsByOwner", CurrentRow.Characteristic);
	StructureOfActionsWithCurLine.Insert("CheckFillPackageByOwner", CurrentRow.Package);
	StructureOfActionsWithCurLine.Insert("RecalculateNumberOfUnits");
	StructureOfActionsWithCurLine.Insert("ProductsOnChangeOverridable", New Structure("FormName, TabularSectionName",
		FormName, "Goods"));
	StructureOfActionsWithCurLine.Insert("FillInMeasuredValueTypeAttribute", New Structure("Products", "MeasuredValueType"));
	StructureOfActionsWithCurLine.Insert("FillPackageWeight",New Structure("Products, Package", "PackageWeight"));
	StructureOfActionsWithCurLine.Insert("FillPackageVolume",New Structure("Products, Package", "PackageVolume"));
	StructureOfActionsWithCurLine.Insert("FillInUnitOfWeight",New Structure("Products, Package", "UnitOfMeasureForWeight"));
	StructureOfActionsWithCurLine.Insert("FillInVolumeUnit",New Structure("Products, Package", "UnitOfMeasureForVolume"));
	StructureOfActionsWithCurLine.Insert("RecalculateWeightVolume");
	StructureOfActionsWithCurLine.Insert("CheckFillAssignment");
	
	StructureOfActionsWithAddedStrings_ = New Structure;
	StructureOfActionsWithAddedStrings_.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
	StructureOfActionsWithAddedStrings_.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));
	StructureOfActionsWithAddedStrings_.Insert("FillInFeatureAttribute",
		New Structure("Products", "ItemVariantsAreUsed"));
	StructureOfActionsWithAddedStrings_.Insert("FillInMeasuredValueTypeAttribute", New Structure("Products", "MeasuredValueType"));
	StructureOfActionsWithAddedStrings_.Insert("FillPackageWeight",New Structure("Products, Package", "PackageWeight"));
	StructureOfActionsWithAddedStrings_.Insert("FillPackageVolume",New Structure("Products, Package", "PackageVolume"));
	StructureOfActionsWithAddedStrings_.Insert("FillInUnitOfWeight",New Structure("Products, Package", "UnitOfMeasureForWeight"));
	StructureOfActionsWithAddedStrings_.Insert("FillInVolumeUnit",New Structure("Products, Package", "UnitOfMeasureForVolume"));
	StructureOfActionsWithAddedStrings_.Insert("FillInCheckQualityDateOfQualityConfirmation",
		CacheQualityControl);
	StructureOfActionsWithAddedStrings_.Insert("FillInUnblockableDateOfQualityConfirmation",
		CacheQualityControl);
	
	PackingSheetsBeforeProcessing = PackingLists.Unload(, "PackingList");
	
	PackingListsServer.ProductsPackingListWhenChanged(ThisObject, Object.Goods,
		"GoodsPackingList", CachedValues, StructureOfActionsWithCurLine, StructureOfActionsWithAddedStrings_);
	
	PackingSheetsAfterProcessing = PackingLists.Unload(, "PackingList");
	CommonClientServer.ArraysDifference(PackingSheetsAfterProcessing, PackingSheetsBeforeProcessing);
	
	If ValueIsFilled(CachedValues.Products) Then
		DisplayAdditionalInformationOnProducts();
	EndIf;
	
	If Not ValueIsFilled(CurrentRow.Barcode) Then
		CurrentRow.BarcodeIsNotRecognized = 0;
	EndIf;
	
	If ValueIsFilled(CurrentRow.DocumentShipments) Then
		CurrentRow.DocumentShipments = Undefined;
	EndIf;
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInPlaceAttributeThatRequiresProcessing");
	BatchProcessingOfTablePartServer.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
	If ValueIsFilled(CurrentRow.PackingList) Then
		DeleteDuplicatesOfProductsWithoutQuantity(True, PackingSheetsAfterProcessing);
	EndIf;
	
	DisplayFilterPageDeselectIfNecessary();
	
EndProcedure

&AtServer
Procedure DeleteDuplicatesOfProductsWithoutQuantity(Renumber, AddedPackingSheets)
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	GoodsTable.Products            AS Products,
	|	GoodsTable.Characteristic          AS Characteristic,
	|	GoodsTable.Purpose              AS Purpose
	|INTO GoodsPackingSheets
	|FROM
	|	&GoodsTable AS GoodsTable
	|WHERE
	|	GoodsTable.PackingListParent IN(&AddedPackingSheets)
	|	AND NOT GoodsTable.ThisIsAPackingList
	|	AND GoodsTable.Count <> 0
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////// 1
	|SELECT
	|	GoodsTable.LineNumber             AS LineNumber,
	|	GoodsTable.Barcode                AS Barcode,
	|	GoodsTable.Products            AS Products,
	|	GoodsTable.Characteristic          AS Characteristic,
	|	GoodsTable.Purpose              AS Purpose
	|INTO DuplicatesTable
	|FROM
	|	&GoodsTable AS GoodsTable
	|WHERE
	|	GoodsTable.PackingListParent = VALUE(Document.PackingList.EmptyRef)
	|	AND NOT GoodsTable.ThisIsAPackingList
	|	AND GoodsTable.Count = 0
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////// 2
	|SELECT
	|	DuplicatesTable.LineNumber AS LineNumber
	|FROM
	|	GoodsPackingSheets AS GoodsTable
	|		INNER JOIN DuplicatesTable AS DuplicatesTable
	|		ON GoodsTable.Products = DuplicatesTable.Products
	|			AND GoodsTable.Characteristic = DuplicatesTable.Characteristic
	|			AND GoodsTable.Purpose = DuplicatesTable.Purpose
	|			AND DuplicatesTable.Barcode = """"
	|
	|ORDER BY
	|	DuplicatesTable.LineNumber DESC";
	
	Query.SetParameter("GoodsTable",               Object.Goods.Unload());
	Query.SetParameter("AddedPackingSheets", AddedPackingSheets);
	
	Selection = Query.Execute().Select();
	
	While Selection.Next() Do
		Object.Goods.Delete(Selection.LineNumber - 1);
	EndDo;
	
	If Renumber
		And Selection.Count() > 0 Then
		
		PackingListsServer.RenumberLines(ThisObject, Object.Goods);
		
	EndIf;
	
EndProcedure

&AtClient
Function PrintOptions(SelectedRows, HasErrors = False)
	
	Order         = 1;
	ProductsForPrinting = New Array;
	
	For Each Id In SelectedRows Do
		
		RowOfGoods = Object.Goods.FindByID(Id);
		
		PrintLine = New Structure("Order, Products, Characteristic, Package, Count");
		FillPropertyValues(PrintLine, RowOfGoods);
		PrintLine.Order = Order;
		
		ProductsForPrinting.Add(PrintLine);
		
		If Not ValueIsFilled(RowOfGoods.Products) Then
			MessageText = NStr("vi = 'Cột ""mặt hàng"" không được điền vào dòng %LineNumber% của danh sách ""Sản phẩm"".';
								|ru = 'Не заполнена колонка ""Номенклатура"" в строке %LineNumber% списка ""Товары"".';
								|en = 'Column ""Items"" in line %LineNumber% of the ""Goods"" list is not filled in.'; fa = 'Column ""Items"" in line %LineNumber% of the ""Goods"" list is not filled in.';
								|it = 'Non è compilata la colonna ""Nomenclatura"" nella riga %LineNumber% dell''elenco ""Merci"".';
								|pl = 'Kolumna ""Nomenklatura"" we wierszu %LineNumber% na liście ""Produkty"" nie jest wypełniona.';
								|tr = '""Ürünler"" listesinin%LineNumber% satırında ""Öğe"" sütunu doldurulmadı.'");
			MessageText = StrReplace(MessageText, "%LineNumber%", RowOfGoods.LineNumber);
			
			CommonClient.MessageToUser(MessageText, Undefined, "", "", HasErrors);
		EndIf;
		If Not ValueIsFilled(RowOfGoods.Count) Then
			MessageText = NStr("vi = 'Cột ""Số lượng"" trong dòng %LineNumber% của danh sách ""Sản phẩm"" không được điền.';
								|ru = 'Не заполнена колонка ""Количество"" в строке %LineNumber% списка ""Товары"".';
								|en = 'Column ""Quantity"" in line %LineNumber% of the ""Goods"" list is not filled in.'; fa = 'Column ""Quantity"" in line %LineNumber% of the ""Goods"" list is not filled in.';
								|it = 'Non è compilata la colonna ""Quantità"" nella riga %LineNumber% dell''elenco ""Merci"".';
								|pl = 'Nie jest wypełniona kolumna ""Ilość"" w wierszu %LineNumber% listy ""Wiersze pozycji"".';
								|tr = '""Ürünler"" listesinin %LineNumber% satırında ""Miktar"" sütunu doldurulmadı.'");
			MessageText = StrReplace(MessageText, "%LineNumber%", RowOfGoods.LineNumber);
			
			CommonClient.MessageToUser(MessageText, Undefined, "", "", HasErrors);
		EndIf;
		
		Order = Order + 1;
		
	EndDo;
	
	// Preparation of the action structure for processing the printing of price tags and labels
	StructureOfActions = New Structure;
	
	If Not Object.WarehouseOperation = PredefinedValue("Enum.WarehouseTransactions.ReturnOfGoodsNotReceivedByRecipient")
		And Not Object.WarehouseOperation = PredefinedValue("Enum.WarehouseTransactions.ReturnOfGoodsNotReceivedByRecipientNotUsed") Then
		
		StructureOfActions.Insert("FillInOrganization", ReferenceCompany);
		
	EndIf;
	
	StructureOfActions.Insert("FillInTheWarehouse",                        Object.Warehouse);
	StructureOfActions.Insert("FillInPriceView",                      RetailPriceType);
	StructureOfActions.Insert("ShowQuantityColumnInDocument", True);
	StructureOfActions.Insert("SetMode",                       "PrintLabels");
	StructureOfActions.Insert("SetPrintModeFromDocument");
	StructureOfActions.Insert("FillInTheGoodsTable");
	StructureOfActions.Insert("FillInTheNumberOfLabelsForTheDocument");
	
	// Preparation of data for filling in the tabular part of the processing of printing price tags and labels.
	FillParameters = New Structure;
	FillParameters.Insert("Goods",            ProductsForPrinting);
	FillParameters.Insert("StructureOfActions", StructureOfActions);
	
	PrintOptions = New Structure("AddressInStorage, FillParameters, PrintToPrinter", "", FillParameters,
		True);
	
	Return PrintOptions;
	
EndFunction

&AtClient
Procedure CreateBarcode(Command)
	
	If Items.Goods.CurrentData = Undefined Then
		Return;
	EndIf;
	
	FillingValues = New Structure;
	FillingValues.Insert("Products",		Items.Goods.CurrentData.Products);
	FillingValues.Insert("Characteristic",	Items.Goods.CurrentData.Characteristic);
	FillingValues.Insert("Series",			Items.Goods.CurrentData.Series);
	
	If Items.ListOfPackagings.CurrentData <> Undefined Then
		FillingValues.Insert("Package", Items.ListOfPackagings.CurrentData.Ref);
	EndIf;
	
	FormParameters = New Structure("FillingValues", FillingValues);
	
	OpenForm("InformationRegister.ItemsBarcodes.RecordForm",
				FormParameters,
				ThisObject,
				,
				,
				,
				,
				FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure ListOfPackagingsBeforeAddRow(Item, Cancel, Copy, Parent, Var_Group)
	If PackagingGroup = False Then
		Cancel = True;
		Text = NStr("vi = 'Không thể thêm đóng gói, bởi vì mặt hàng chưa bật sử dụng đóng gói.
				|Hãy mở thẻ mặt hàng và bật sử dụng đóng gói.';
				|ru = 'Добавить упаковку невозможно, т.к. для номенклатуры не включено использование упаковок.
				|Откройте карточку номенклатуры и включите использование упаковок.';
				|en = 'Cannot add packaging unit as the packaging unit usage is not enabled for products.
				|Open the item profile and enable the packaging unit usage.'; fa = 'Cannot add packaging unit as the packaging unit usage is not enabled for products.
				|Open the item profile and enable the packaging unit usage.';
				|it = 'È impossibile aggiungere imballaggio perché per la nomenclatura non è incluso l''utilizzo di imballaggi.
				|Aprire la scheda nomenclatura e abilitare l''utilizzo di imballaggi.';
				|pl = 'Nie można dodać opakowania, ponieważ dla wykazu towarów nie jest włączone wykorzystanie opakowań.
				|Otwórz kartę wykazu towarów i włącz korzystanie z opakowań.';
				|tr = 'Paketleme ünitesi eklemek mümkün değil çünkü ürünler, paketleme ünitesi kullanımını içermez.
				|Ürün profilini açın ve paketleme ünitesi kullanımını etkinleştirin.'");
		ShowMessageBox(Undefined, Text);
	EndIf;	
EndProcedure

&AtServer
Procedure ConfigureDisplayOfAdditionalInformationPanel()
	
	Items.AdditionalWorkplace.Visible = Not HideAdditionalInformation;
	
	If HideAdditionalInformation Then
		TextShowHide = NStr("vi = 'Hiển thị thanh lệnh thông tin bổ sung';
							|ru = 'Показать панель дополнительной информации';
							|en = 'Show additional information panel'; fa = 'Show additional information panel';
							|it = 'Visualizzare il pannello delle informazioni aggiuntive';
							|pl = 'Pokaz panel informacji dodatkowych';
							|tr = 'Ek bilgi panelini göster'");
	Else
		TextShowHide = NStr("vi = 'Ẩn thanh thông tin bổ sung';
							|ru = 'Скрыть панель дополнительной информации';
							|en = 'Hide additional information panel'; fa = 'Hide additional information panel';
							|it = 'Nascondere il pannello delle informazioni aggiuntive';
							|pl = 'Ukryj panel informacji dodatkowych';
							|tr = 'Ek bilgi panelini gizle'");;
	EndIf;
	
	Items.AdditionalBar.Title = TextShowHide;
	
EndProcedure

&AtServer
Procedure InstallAddressDependentStorage()
	
	UseBinLocationWarehousing = WarehousesServer.UseBinLocationWarehousing(Object.Warehouse, Object.Premise, Object.Date);
	
	If UseBinLocationWarehousing Then
		Object.ReceivingArea = Catalogs.StorageBins.DefaultAcceptanceZone(Object.Warehouse, Object.Premise, Object.ReceivingArea);
	EndIf;
	
	Items.ReceivingArea.Visible = UseBinLocationWarehousing;
	
EndProcedure

&AtServer
Procedure PrepareFillSetSeriesVisibility()
	
	SeriesSpecificationParameters = New FixedStructure(ProductsServer.SeriesSpecificationParameters(Object, Documents.GoodsReceiptNote));
	ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);
	SetVisibilityOfSeriesElements();
	
EndProcedure

&AtServer
Procedure SetVisibilityOfSeriesElements()
	
	Items.GoodsBatchesIndicationStatus.Visible = SeriesSpecificationParameters.UseItemsBatch;
	Items.GoodsSpecifySeries.Visible = SeriesSpecificationParameters.UseItemsBatch;
	
EndProcedure

&AtServer
Procedure FillInServiceDetailsOfTSGoods(Renumber = True, CachedValues = Undefined)
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateWeightVolume");
	StructureOfActions.Insert("FillInFeatureAttribute",
		New Structure("Products", "ItemVariantsAreUsed"));
	StructureOfActions.Insert("FillInProductTypeAttribute_",
		New Structure("Products", "ItemsType"));
	StructureOfActions.Insert("FillInArticleAttribute",
		New Structure("Products", "SKU"));
	StructureOfActions.Insert("FillInMeasuredValueTypeAttribute", New Structure("Products", "MeasuredValueType"));
	StructureOfActions.Insert("FillPackageWeight",New Structure("Products, Package", "PackageWeight"));
	StructureOfActions.Insert("FillPackageVolume",New Structure("Products, Package", "PackageVolume"));
	StructureOfActions.Insert("FillInUnitOfWeight",New Structure("Products, Package", "UnitOfMeasureForWeight"));
	StructureOfActions.Insert("FillInVolumeUnit",New Structure("Products, Package", "UnitOfMeasureForVolume"));
	
	PackingListsServer.FillInServiceDetails(ThisObject, Object.Goods, StructureOfActions, ,Renumber, CachedValues);
	
	// To fill in the barcode attribute, we will get data on barcodes
	VTBarcodes = Object.Goods.Unload(,"Barcode");
	VTBarcodes.GroupBy("Barcode");
	ArrayOfBarcodes = VTBarcodes.UnloadColumn("Barcode");
	
	CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	InformationRegisters.ItemsBarcodes.GetBarcodeData(CachedValues, ArrayOfBarcodes);
	
	If Object.Goods.FindRows(New Structure("ThisIsAPackingList", True)).Count() > 0 Then
		Documents.PackingList.AddDataOnBarcodes(CachedValues, ArrayOfBarcodes);
	EndIf;
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInPlaceAttributeThatRequiresProcessing");
	
	RowsToProcess = New Array;
	
	For Each TSRow In Object.Goods Do
		If Not ValueIsFilled(TSRow.Barcode)
			Or ValueIsFilled(CachedValues.Barcodes[TSRow.Barcode])
				And Not CachedValues.Barcodes[TSRow.Barcode].UnknownBarcode Then
			TSRow.BarcodeIsNotRecognized = 0;
		Else
			TSRow.BarcodeIsNotRecognized = 1;
		EndIf;
		RowsToProcess.Add(TSRow);
	EndDo;
	
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		RowsToProcess,
		StructureOfActions,
		Object.Goods,
		CachedValues);
	
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
Procedure AddLinesForShipmentDocuments(ReferencesArrray,CachedValues)
	
	Query = New Query;
	Query.Text = 
	"SELECT DISTINCT
	|	GoodsForShipmentTurnover.DocumentShipments AS DocumentShipments,
	|	GoodsForShipmentTurnover.Products AS Products,
	|	GoodsForShipmentTurnover.Products.ItemsType AS ItemsType,
	|	GoodsForShipmentTurnover.Products.SKU AS SKU,
	|	GoodsForShipmentTurnover.Characteristic AS Characteristic,
	|	GoodsForShipmentTurnover.Purpose,
	|	CASE
	|		WHEN GoodsForShipmentTurnover.Products.UseVariants IN (VALUE(Enum.ItemVariantsUsageOptions.SpecialForItems), VALUE(Enum.ItemVariantsUsageOptions.CommonForItemKind), VALUE(Enum.ItemVariantsUsageOptions.CommonWithOtherItemKind))
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS ItemVariantsAreUsed
	|FROM
	|	AccumulationRegister.GoodsForIssue.Turnovers(,
	|			,
	|			,
	|			DocumentShipments IN(&ReferencesArrray)
	|	
	|	) AS GoodsForShipmentTurnover";
	
	Query.SetParameter("ReferencesArrray", ReferencesArrray);
	Table = Query.Execute().Unload();
	ReadyForProcessing_ = New Array();
	For Each String In Table Do
		NewRow = Object.Goods.Add();
		FillPropertyValues(NewRow, String);
		ReadyForProcessing_.Add(NewRow);
	EndDo;
	StructureOfActions = New Structure();
	StructureOfActions.Insert("FillInCheckQualityDateOfQualityConfirmation", CacheQualityControl);
	StructureOfActions.Insert("FillInUnblockableDateOfQualityConfirmation", CacheQualityControl);
	BatchProcessingOfTablePartServer.ProcessTSStrings(ReadyForProcessing_, StructureOfActions, Object.Goods);
	
	FillInServiceDetailsOfTSGoods(False,CachedValues);
	ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);
	
EndProcedure

&AtClient
Procedure OpenShipmentDocumentSelectionForm(SelectByProduct = False)
	
	FormParameters = New Structure;
	FormParameters.Insert("Warehouse", Object.Warehouse);
	If SelectByProduct Then
		CurrentRow = Items.Goods.CurrentData;
		FormParameters.Insert("Products", CurrentRow.Products);
		FormParameters.Insert("Characteristic", CurrentRow.Characteristic);
	EndIf;
	FormParameters.Insert("SelectByProduct", SelectByProduct);
	OpenForm("Document.GoodsReceiptNote.Form.ShippingDocumentChoiceForm",
		FormParameters, ThisObject, UUID);
	
EndProcedure

&AtClientAtServerNoContext
Procedure UpdateBlankAutoTag(Status, FormTable)
	
	If Status = PredefinedValue("Enum.GoodsReceiptNoteStatuses.ToReceive") 
		Or Status = PredefinedValue("Enum.GoodsReceiptNoteStatuses.InProgress") Then
		
		FormTable.AutoMarkIncomplete = False;
		FormTable.MarkIncomplete = False;
		
	Else
		
		FormTable.AutoMarkIncomplete = True;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure PictureAddressClick(Item, StandardProcessing)
	
	StandardProcessing = False;
	
	ViewImage();
	
EndProcedure

#EndRegion

#Region Other

&AtClient
Procedure Attachable_CloseForm()
	
	If IsOpen() Then
		Close();
	EndIf;
	
EndProcedure

&AtServer
Procedure FillAtServer(TypeOfFilling, DateOfReceipt, CachedValues)
	
	CurObject = FormAttributeToValue("Object");
	CurObject.FillInItemsByItemsDue(TypeOfFilling,DateOfReceipt);
	ValueToFormAttribute(CurObject, "Object");
	
	FillInServiceDetailsOfTSGoods(False,CachedValues);
	ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);
	PackingListsServer.RenumberLines(ThisObject, Object.Goods);
	
	PackingListsServer.WhenReadingCreatingFormWithPackingLists(ThisObject, Object.Goods,
		Object.Ref.Metadata().ObjectPresentation);
		
	CurrentObject = FormAttributeToValue("Object");	
	FormEvents.OnReadAtServer(ThisObject, CurrentObject);
	
	GoodsReceiptNoteLocalization.EstablishSignOfUseOfLabeledProducts(ThisObject);
	EstablishVisibilityOfPackagingElementsDuringLabeling();
	
	DisplayFilterPageDeselectIfNecessary();
	
EndProcedure

// The procedure is called in the acceptance AutoTest for orders in the order warehouse
//
//	 Parameters:
//		TypeOfFilling - String - the option of filling (Nomenclature, nomenclature, Quantity).
//
&AtClient
Procedure Autotest_FillInByOrder(TypeOfFilling) Export
	
	ClearMessages();
	
	If Not ValueIsFilled(Object.ReferenceOrder)Then
		CommonClient.MessageToUser(NStr("vi = 'Chưa chỉ ra lệnh.';
										|ru = 'Не указано распоряжение.';
										|en = 'Reference is not specified.'; fa = 'Reference is not specified.';
										|it = 'Disposizione non indicata.';
										|pl = 'Nie podano zamówienia';
										|tr = 'Emir belirtilmedi.'"));
		
		Return;
	EndIf;
	
	If TypeOfFilling = "Count" Then
		
		If Object.Goods.Total("NumberOfPackages") <> 0 Then
			
			If SeriesSpecificationParameters.UseItemsBatch Then 
				MessageText = NStr("vi = 'Trong một số dòng, số lượng đã được điền và sẽ được điền lại theo lệnh, điền sê-ri sẽ bị xóa. Tiếp tục?';
									|ru = 'В некоторых строках количество уже заполнено и будет перезаполнено остатками по распоряжению, заполненные серии будут очищены. Продолжить?';
									|en = 'In some lines, quantity has already been populated and will be repopulated with remaining quantity under the reference, populated batch will be cleared. Continue?'; fa = 'In some lines, quantity has already been populated and will be repopulated with remaining quantity under the reference, populated batch will be cleared. Continue?';
									|it = 'In alcune righe la quantità è già compilata e verrà ricompilata con le rimanenze per disposizione, le serie compilate verranno cancellate. Continuare?';
									|pl = 'W niektórych wierszach ilość jest już wypełniona i zostanie wypełniona ponownie resztkami według zamówienia, wypełnione serie zostaną wyczyszczone. Kontynuować?';
									|tr = 'Bazı satırlarda miktar zaten doldurulmuştur ve emre göre bakiyelerle yeniden doldurulacaktır, doldurulan partiler silinecektir. Devam edilsin mi?'");
			Else
				MessageText = NStr("vi = 'Trong một số dòng số lượng đã điền và sẽ điền lại theo lệnh. Tiếp tục?';
									|ru = 'В некоторых строках количество уже заполнено и будет перезаполнено остатками по распоряжению. Продолжить?';
									|en = 'In some lines, quantity has already been populated and will be repopulated with remaining quantity under the reference. Continue?'; fa = 'In some lines, quantity has already been populated and will be repopulated with remaining quantity under the reference. Continue?';
									|it = 'In alcune righe la quantità è già compilata e verrà ricompilata con le rimanenze per disposizione. Continuare?';
									|pl = 'W niektórych wierszach ilość jest już wypełniona i zostanie wypełniona ponownie resztą według zamówienia. Kontynuować?';
									|tr = 'Bazı satırlarda miktar zaten doldurulmuştur ve emirdeki bakiyelerle birlikte yeniden doldurulacaktır. Devam edilsin mi?'");
			EndIf;
			
			NotificationParameters	= New Structure("TypeOfFilling", TypeOfFilling);
			CallbackDescription	= New CallbackDescription("Autotest_FillInByOrderCompletion2",
															ThisObject,
															NotificationParameters);
			
			ShowQueryBox(CallbackDescription, MessageText, QuestionDialogMode.YesNo);
			
			Return;
			
		EndIf;
		
	Else
		
		If Object.Goods.Count() > 0 Then
			
			If SeriesSpecificationParameters.UseItemsBatch Then 
				MessageText = NStr("vi = 'Trước khi điền, phần bảng sẽ bị xóa, sê-ri đã chỉ ra sẽ bị xóa. Tiếp tục?';
									|ru = 'Перед заполнением табличная часть будет очищена, указанные серии будут очищены. Продолжить?';
									|en = 'The table and batches will be cleared. Do you want to continue?'; fa = 'The table and batches will be cleared. Do you want to continue?';
									|it = 'Prima della compilazione, la parte tabulare sarà cancellata, le serie specificate verranno cancellate. Continuare?';
									|pl = 'Przed wypełnieniem część tabelaryczna zostanie wyczyszczona, wskazane serie zostaną wyczyszczone. Kontynuować?';
									|tr = 'Tablo bölümü doldurulmadan önce silinecek, belirtilen partiler temizlenecektir. Devam edilsin mi?'");
			Else
				MessageText = NStr("vi = 'Trước khi điền, phần bảng sẽ bị xóa. Tiếp tục?';
									|ru = 'Перед заполнением табличная часть будет очищена. Продолжить?';
									|en = 'The table will be cleared. Do you want to continue?'; fa = 'جدول پاک خواهد شد. آیا می‌خواهید ادامه دهید؟';
									|it = 'Prima della compilazione, la parte tabulare sarà cancellata. Continuare?';
									|pl = 'Przed wypełnieniem część tabelaryczna zostanie wyczyszczona. Kontynuować?';
									|tr = 'Tablo bölümü doldurulmadan önce temizlenecektir. Devam edilsin mi?'");
			EndIf;
			
			NotificationParameters	= New Structure("TypeOfFilling", TypeOfFilling);
			CallbackDescription	= New CallbackDescription("Autotest_FillInByOrderAfterQuestion",
															ThisObject,
															NotificationParameters);
			
			ShowQueryBox(CallbackDescription, MessageText, QuestionDialogMode.YesNo);
			
			Return;
			
		EndIf;
		
	EndIf;
	
	Autotest_FillInFragmentByOrder1(TypeOfFilling);
	
EndProcedure

&AtClient
Procedure Autotest_FillInByOrderCompletion2(QuestionResult, AdditionalParameters) Export
	
	TypeOfFilling = AdditionalParameters.TypeOfFilling;
	
	If QuestionResult <> DialogReturnCode.Yes Then
		Return;
	EndIf;
	
	Autotest_FillInFragmentByOrder1(TypeOfFilling);
	
EndProcedure

&AtClient
Procedure Autotest_FillInFragmentByOrder1(Val TypeOfFilling)
	
	Autotest_FillInFragmentByOrder(TypeOfFilling);
	
EndProcedure

&AtClient
Procedure Autotest_FillInByOrderAfterQuestion(QuestionResult, AdditionalParameters) Export
	
	TypeOfFilling = AdditionalParameters.TypeOfFilling;
	
	If QuestionResult <> DialogReturnCode.Yes Then
		Return;
	EndIf;
	
	Autotest_FillInFragmentByOrder(TypeOfFilling);
	
EndProcedure

&AtClient
Procedure Autotest_FillInFragmentByOrder(Val TypeOfFilling)
	
	DateSelectionFormParameters = New Structure;
	DateSelectionFormParameters.Insert("CurrentDocument",	Object.Ref);
	DateSelectionFormParameters.Insert("ReferenceOrder",		Object.ReferenceOrder);
	DateSelectionFormParameters.Insert("Warehouse",				Object.Warehouse);
	
	NotificationParameters	= New Structure("TypeOfFilling", TypeOfFilling);
	CallbackDescription	= New CallbackDescription("Autotest_FillInByOrderCompletion",
													ThisObject,
													NotificationParameters);
	
	OpenForm("Document.GoodsReceiptNote.Form.DateOfReceiptChoiceForm",
				DateSelectionFormParameters,
				,
				,
				,
				,
				CallbackDescription,
				FormWindowOpeningMode.LockOwnerWindow);
EndProcedure

&AtClient
Procedure Autotest_FillInByOrderCompletion(Result, AdditionalParameters) Export
	
	TypeOfFilling	= AdditionalParameters.TypeOfFilling;
	DateOfReceipt	= Result;
	
	If ValueIsFilled(DateOfReceipt) Then
		FillAtServer(TypeOfFilling, DateOfReceipt, CachedValues);
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Procedure AddActionsToStructureWhenChangingPackagesNumber(Form, Actions)
	
	Actions.Insert("RecalculateNumberOfUnits");
	Actions.Insert("RecalculateWeightVolume");
	Actions.Insert("CheckSeriesCalculateStatus",
			New Structure("Warehouse, SeriesSpecificationParameters", Form.Object.Warehouse, Form.SeriesSpecificationParameters));
	
EndProcedure

&AtClient
Procedure GoodsOnActivateRow(Item)
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.StartTimeMeasurement(True,
		"Document.GoodsReceiptNote.DocumentForm.Item.Goods.OnActivateRow");
	
	If Not HideAdditionalInformation Then
		AttachIdleHandler("ProductsWhenActivatingLineOnClient", 0.2, True);
	EndIf;
	
EndProcedure

&AtClient
Procedure ListOfPackagingsSelection(Item, RowSelected, Field, StandardProcessing)
	
	StandardProcessing = False;
	TransferPackage(RowSelected,Items.Goods.CurrentData.GetID(),CachedValues);
	
EndProcedure

&AtClient
Procedure GoodsCharacteristicOnChange(Item)
	
	If Not HideAdditionalInformation Then
		CommonClientServer.SetDynamicListFilterItem(BarcodeList,
			"Characteristic",
			Items.Goods.CurrentData.Characteristic,
			DataCompositionComparisonType.Equal,
			,
			True);
	EndIf;
	
EndProcedure

&AtClient
Procedure SelectPackaging(Command)
	
	If Items.ListOfPackagings.CurrentData <> Undefined Then
		TransferPackage(Items.ListOfPackagings.CurrentData.Ref,Items.Goods.CurrentData.GetID(),CachedValues);
	EndIf;
	
EndProcedure

&AtClient
Procedure Edit(Command)
	
	If Items.Goods.CurrentData <> Undefined Then
		
		If Not Items.Goods.CurrentData.Products.IsEmpty() Then	
			
			PackingListsClient.AtBeginningOfEditingPMWithPackingLists(ThisForm, CachedValues, False);
			ProductsClient.UpdateCachedValuesToAccountForSeries(Items.Goods, CachedValues,
				SeriesSpecificationParameters, False);
			ShowValue(Undefined, Items.Goods.CurrentData.Products);
			
			Return;
			
		EndIf;
		
	EndIf;
	
	MessageText = NStr("vi = 'Chọn dòng với mặt hàng.';
						|ru = 'Выберете строку с номенклатурой.';
						|en = 'Select a line with products.'; fa = 'Select a line with products.';
						|it = 'Selezionare la riga con nomenclatura.';
						|pl = 'Wybierz wiersz z wykazem towarów';
						|tr = 'Ürün gamı ile olan satırı seç.'");
	ShowMessageBox(Undefined, MessageText);
	
EndProcedure

&AtClient
Procedure AdditionalBar(Command)
	
	HideAdditionalInformation = Not HideAdditionalInformation;
	ConfigureDisplayOfAdditionalInformationPanel();
	
EndProcedure

&AtClient
Procedure Print(Command)
	
	ClearMessages();
	
	SelectedRows = Items.Goods.SelectedRows;
	
	If SelectedRows.Count() = 0 Then
		WarningText = NStr("vi = 'Không có hàng hóa được lựa chọn.';
							|ru = 'Не выбрано ни одного товара.';
							|en = 'No goods selected.'; fa = 'No goods selected.';
							|it = 'Nessuna merce è stata selezionata.';
							|pl = 'Nie wybrano ani jednego towaru.';
							|tr = 'Hiç bir ürün seçilmedi.'");
		
		ShowMessageBox(Undefined, WarningText);
		Return;
	EndIf;
	
	HasErrors      = False;
	PrintParameters = PrintOptions(SelectedRows, HasErrors);
	
	If Not HasErrors Then
		UniquenessID = New UUID;
		
		OpenForm("DataProcessor.PrintPriceTagsAndLabels.Form.FormGoods", PrintParameters, , UniquenessID);
	EndIf;
	
EndProcedure

&AtServer
Procedure FillMultiTurnContainersFromStorageServer(AddressOfContainerInStorage,CachedValues)
	
	ActionStructureModifiedStrings = New Structure;
	ActionStructureModifiedStrings.Insert("RecalculateNumberOfPackages");
	ActionStructureModifiedStrings.Insert("FillPackageWeight",New Structure("Products, Package", "PackageWeight"));
	ActionStructureModifiedStrings.Insert("FillPackageVolume",New Structure("Products, Package", "PackageVolume"));
	ActionStructureModifiedStrings.Insert("FillInUnitOfWeight",New Structure("Products, Package", "UnitOfMeasureForWeight"));
	ActionStructureModifiedStrings.Insert("FillInVolumeUnit",New Structure("Products, Package", "UnitOfMeasureForVolume"));
	ActionStructureModifiedStrings.Insert("RecalculateWeightVolume");
	
	ActionStructureModifiedStrings.Insert(
		"RecalculateNumberOfPackages",
		BatchProcessingOfTablePartClientServer.StructureOfRecalculationOfNumberOfPackages());
		
	StructureOfActionsAddedLines = New Structure;
	StructureOfActionsAddedLines.Insert("RecalculateNumberOfPackages");
	StructureOfActionsAddedLines.Insert("FillPackageWeight",New Structure("Products, Package", "PackageWeight"));
	StructureOfActionsAddedLines.Insert("FillPackageVolume",New Structure("Products, Package", "PackageVolume"));
	StructureOfActionsAddedLines.Insert("FillInUnitOfWeight",New Structure("Products, Package", "UnitOfMeasureForWeight"));
	StructureOfActionsAddedLines.Insert("FillInVolumeUnit",New Structure("Products, Package", "UnitOfMeasureForVolume"));
	StructureOfActionsAddedLines.Insert("RecalculateWeightVolume");
	StructureOfActionsAddedLines.Insert("FillInCheckQualityDateOfQualityConfirmation",
		CacheQualityControl);
	StructureOfActionsAddedLines.Insert("FillInUnblockableDateOfQualityConfirmation",
		CacheQualityControl);
	
	StructureOfActionsAddedLines.Insert(
		"RecalculateNumberOfPackages",
		BatchProcessingOfTablePartClientServer.StructureOfRecalculationOfNumberOfPackages());
	
	ReusablePackageServer.FillMultiTurnContainersFromStorage(
		Object,
		AddressOfContainerInStorage,
		"Goods",
		"Products,Characteristic",
		ActionStructureModifiedStrings,
		StructureOfActionsAddedLines);
	
	FillInServiceDetailsOfTSGoods(False,CachedValues);
	
	If SeriesSpecificationParameters.UseItemsBatch Then 
		For Each RowOfTables In Object.Goods Do
			If RowOfTables.ItemsType = Enums.ItemsTypes.ReusablePackage Then
				RowOfTables.Series = Catalogs.ItemsBatches.EmptyRef();
			EndIf;
		EndDo;
	EndIf;
	
	ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);
	
EndProcedure

&AtServer
Procedure GetUploadedProductsFromStorage(GoodsAddressInStorage, CachedValues)
	
	ItemsFromStorage = GetFromTempStorage(GoodsAddressInStorage);
	ReadyForProcessing_ = New Array();
	LinesToSupplement = New Array;
	For Each RowOfGoods In ItemsFromStorage Do
		If ValueIsFilled(RowOfGoods.PackingList)
			And Object.Goods.FindRows(New Structure("PackingList",RowOfGoods.PackingList)).Count() > 0 Then
			MessageText = NStr("vi = '%PackingList% đã được thêm vào phần bảng.';
								|ru = '%PackingList% уже был добавлен в табличную часть.';
								|en = '%PackingList% has already been added to the table.'; fa = '%PackingList% has already been added to the table.';
								|it = '%PackingList% è stato già aggiunto alla parte tabulare.';
								|pl = '%PackingList% już został dodany do części tabelarycznej';
								|tr = '%PackingList% zaten tablo kısmına eklenmiş.'");
			MessageText = StrReplace(MessageText, "%PackingList%", RowOfGoods.PackingList);
			Common.MessageToUser(MessageText);
			Continue;
		EndIf;
		StringTSGoods = Object.Goods.Add();
		FillPropertyValues(StringTSGoods, RowOfGoods);
		ReadyForProcessing_.Add(StringTSGoods);
		If ValueIsFilled(RowOfGoods.PackingList) Then
			LinesToSupplement.Add(StringTSGoods);
			StringTSGoods.ThisIsAPackingList = True;
			StringTSGoods.Count = 1;
			StringTSGoods.NumberOfPackages = 1;
		EndIf;
	EndDo;
	StructureOfActions = New Structure();
	StructureOfActions.Insert("FillInCheckQualityDateOfQualityConfirmation", CacheQualityControl);
	StructureOfActions.Insert("FillInUnblockableDateOfQualityConfirmation", CacheQualityControl);
	BatchProcessingOfTablePartServer.ProcessTSStrings(ReadyForProcessing_, StructureOfActions, Object.Goods);
	
	PackingSheetsBeforeProcessing = PackingLists.Unload(, "PackingList");
	
	PackingListsServer.AddLinesOnPackingLists(ThisForm, Object.Goods, LinesToSupplement);
	BatchProcessingOfTablePartServer.ProcessTSStrings(LinesToSupplement, StructureOfActions, Object.Goods);
	
	PackingSheetsAfterProcessing = PackingLists.Unload(, "PackingList");
	CommonClientServer.ArraysDifference(PackingSheetsAfterProcessing, PackingSheetsBeforeProcessing);
	
	DeleteDuplicatesOfProductsWithoutQuantity(False, PackingSheetsAfterProcessing);
	FillInServiceDetailsOfTSGoods(False,CachedValues);
	ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);
	
	// The download goes to the upper level, you need to go
	If Not Object.GoodsViewMode Then
		PackingListsServer.WhenMovingToAnotherLevel(ThisForm,
			Object.Goods, "0", Object.Ref.Metadata().ObjectPresentation);
	EndIf;
	RecalculateNumberOfSeats();
	
EndProcedure

&AtServer
Procedure WhenMovingToAnotherLevelServer(Var_URL)
	PackingListsServer.WhenMovingToAnotherLevel(ThisForm,
		Object.Goods, Var_URL, Object.Ref.Metadata().ObjectPresentation);
EndProcedure

&AtServer
Procedure DisplayModeOnChangeServer()
	
	PackingListsServer.DisplayModeOnChange(ThisForm, Object.Goods, Object.Ref.Metadata().ObjectPresentation);
	
EndProcedure

&AtServer
Procedure GoodsAfterDeleteRowServer(CachedValues)
	
	GoodsReceiptNoteLocalization.EstablishSignOfUseOfLabeledProducts(ThisForm);
	EstablishVisibilityOfPackagingElementsDuringLabeling();
	FillInStatusesOfSpecifyingSeriesWhenEditingLineTS(Undefined, CachedValues);
	PackingListsServer.AfterRemovalOfVTCHSPackingSheets(ThisForm, Object.Goods, Object.GoodsViewMode);
	DisplayFilterPageDeselectIfNecessary();
	
EndProcedure

&AtServer
Procedure DecorationFilterNavigationLinkProcessingServer(Var_URL)
	
	If Var_URL = "Pick" Then
		Items.PagesFilter.CurrentPage = Items.PageFilterReset;
		RowFilter = New FixedStructure("ThisIsAPackingList, DataProcessorIsRequired", False, 1);
		Object.GoodsViewMode = True;
		DisplayModeOnChangeServer();
	Else
		Items.PagesFilter.CurrentPage = Items.PageFilterSet;
		If Object.GoodsViewMode Then
			RowFilter = New FixedStructure("ThisIsAPackingList", False);
		Else
			RowFilter = New FixedStructure(
			"PackingListParent, ThisIsInternalRowOfEmptyPackingList",
			PackingListParent, 0);
		EndIf;
	EndIf;
	Items.Goods.RowFilter = RowFilter;
	
EndProcedure

&AtServer
Procedure DisplayFilterPageDeselectIfNecessary()
	
	NumberOfRowsToProcess = Object.Goods.Total("DataProcessorIsRequired") - Object.Goods.Total("ThisIsInternalRowOfEmptyPackingList");
	If NumberOfRowsToProcess = 0 Then
		Items.PagesFilter.CurrentPage = Items.PageFilterEmpty;
		If Object.GoodsViewMode Then
			Items.Goods.RowFilter = New FixedStructure("ThisIsAPackingList", False);
		Else
			Items.Goods.RowFilter = New FixedStructure(
				"PackingListParent, ThisIsInternalRowOfEmptyPackingList", PackingListParent, 0);
		EndIf;
	ElsIf Items.PagesFilter.CurrentPage <> Items.PageFilterReset Then
		Items.PagesFilter.CurrentPage = Items.PageFilterSet;
		
		RowsArray = New Array;
		RowsArray.Add(
			StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Có vị trí hàng hóa cần xử lý (%1).';
					|ru = 'Есть товарные места, требующие обработки (%1).';
					|en = 'There are cargo items that require processing (%1).'; fa = 'There are cargo items that require processing (%1).';
					|it = 'Ci sono i colli di merce che richiedono l''elaborazione (%1).';
					|pl = 'Są pozycje towarowe które wymagają przetwarzania (%1)';
					|tr = 'İşleme gerektiren ürün yerleri mevcut (%1).'"),
			NumberOfRowsToProcess));
		RowsArray.Add(" ");
		RowsArray.Add(New FormattedString("Pick",,,,"Pick"));
		LabelFilter = New FormattedString(RowsArray);
	EndIf;
	
EndProcedure

// The handler that will be called after closing a question about unpacking
//
&AtClient
Procedure AfterClosingUnboxingQuestion(Result, Var_Parameters) Export
	
	If Result = DialogReturnCode.Yes Then
		UnpackServer();
		DisplayFilterPageDeselectIfNecessary();
	EndIf;
	
EndProcedure

&AtServer
Procedure UnpackServer()
	
	PackingListsServer.UnpackPackingList(ThisForm);
	
EndProcedure

&AtServer
Procedure UpLevelServer()
	
	FoundRows = PackingLists.FindRows(New Structure("PackingList",PackingListParent));
	WhenMovingToAnotherLevelServer(FoundRows[0].PackingListParent);
	
EndProcedure

&AtServer
Procedure RecalculateNumberOfSeats()
	
	PackingListsServer.RecalculateNumberOfSeats(ThisForm, Object.Goods)
	
EndProcedure

&AtClient
Procedure GoodsSeriesOnChange(Item)
	ValueSelected = ProductsClientServer.SelectedSeries();
	
	ValueSelected.Value            		 = Items.Goods.CurrentData.Series;
	ValueSelected.CurrentRowID = Items.Goods.CurrentData.GetID();
	
	ProductsClient.ProcessSeriesIndication(ThisForm, SeriesSpecificationParameters, ValueSelected);
EndProcedure

&AtClient
Procedure GoodsSeriesStartChoice(Item, ChoiceData, StandardProcessing)
	StandardProcessing = False;
	OpenSelectionOfSeries(Item.EditText);
EndProcedure

&AtServer
Function FillInSeriesByReferenceServer(CachedValues)
	
	Filled1 = Documents.GoodsReceiptNote.FillInSeriesByReference(Object, True);	
	If Filled1 Then
		ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);
		FillInServiceDetailsOfTSGoods(True,CachedValues);
		StructureOfActions = New Structure();
		StructureOfActions.Insert("FillInCheckQualityDateOfQualityConfirmation", CacheQualityControl);
		StructureOfActions.Insert("FillInUnblockableDateOfQualityConfirmation", CacheQualityControl);
		BatchProcessingOfTablePartServer.TreatTS(Object.Goods, StructureOfActions);
	EndIf;
	
	Return Filled1;
EndFunction

&AtServer
Procedure ProcessAndRenumberTSStrings(IDOfNewLine, CurrentRowID, StructureOfActions, CachedValues)
	
	NewRow = Object.Goods.FindByID(IDOfNewLine);
	CurrentRow = Object.Goods.FindByID(CurrentRowID);
	
	BatchProcessingOfTablePartServer.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	BatchProcessingOfTablePartServer.ProcessTSString(NewRow, StructureOfActions, CachedValues);
	
	PackingListsServer.RenumberLines(ThisForm, Object.Goods);
	
EndProcedure

&AtServer
Function CheckGoodsAndPutThemInTemporaryStorage(StorageAddress, OnlyNonLabeledProductsHaveBeenUnloaded = False)
	
	MessageTemplate = NStr("vi = 'Để mở quy trình kiểm tra số lượng hàng hóa theo đơn hàng, cần điền vào mặt hàng trong dòng %LineNumber%.';
							|ru = 'Для открытия обработки проверки количества товаров в ордере необходимо заполнить номенклатуру в строке %LineNumber%.';
							|en = 'Fill in items in line %LineNumber% to open the data processor for checking goods quantity in the note.'; fa = 'Fill in items in line %LineNumber% to open the data processor for checking goods quantity in the note.';
							|it = 'Per aprire l''elaborazione del controllo quantità di merci nel mandato, è necessario compilare la nomenclatura nella riga %LineNumber%.';
							|pl = 'Aby otworzyć proces sprawdzania ilości towarów w zleceniu, należy wypełnić pozycję wykazu towaru w wierszu %LineNumber%.';
							|tr = 'Siparişteki ürün miktarını kontrol etme işlemini açmak için satırdaki ürün gamının doldurulması gerekir %LineNumber%.'");
	CheckPassed = True;
	
	TabularPartProducts = Object.Goods.Unload();
	
	If ThereAreLabeledProducts And Modified Then
	
		SpendRecord	= ?(Object.Posted, NStr("vi = 'Kết chuyển';
												|ru = 'Провести';
												|en = 'Post'; fa = 'ثبت';
												|it = 'Registrare';
												|pl = 'Zatwierdź';
												|tr = 'Kaydet'"), NStr("vi = 'Ghi lại';
																	|ru = 'Записать';
																	|en = 'Save'; fa = 'ذخیره';
																	|it = 'Salvare';
																	|pl = 'Zapisz';
																	|tr = 'Kaydet'"));
		ErrorMessage	= StrTemplate(NStr("vi = 'Chứng từ đã thay đổi. Trước khi kiểm tra chứng từ, cần %1.';
											|ru = 'Документ был изменен. Перед проверкой его необходимо %1.';
											|en = 'The document was changed. %1 before checking it.'; fa = 'The document was changed. %1 before checking it.';
											|it = 'Documento modificato. Prima della verifica è necessario %1.';
											|pl = 'Dokument został zmieniony. Przed sprawdzeniem go należy %1.';
											|tr = 'Belge değiştirildi. Kontrol etmeden önce gereklidir %1.'"), SpendRecord);
		
		Common.MessageToUser(ErrorMessage, , , "Object");
		CheckPassed = False;
	EndIf;
	
	If CheckPassed Then
		For Each String In TabularPartProducts Do
			If Not ValueIsFilled(String.Products) 
				And Not ValueIsFilled(String.PackingList) 
				And Not ValueIsFilled(String.PackingListParent) Then
				
				ErrorMessage = StrReplace(MessageTemplate, "%LineNumber%", String.LineNumberDisplayed);
				
				Field = CommonClientServer.PathToTabularSection("Goods", String.LineNumber, "Products");
				Common.MessageToUser(ErrorMessage, , Field, "Object");
				CheckPassed = False;
			EndIf;
		EndDo;
	EndIf;
	
	If CheckPassed Then
		
		If ThereAreLabeledProducts 
			And TabularPartProducts.Columns.Find("ProductTypeIS") <> Undefined Then
			
			CurrentRowNumber = TabularPartProducts.Count()-1;
			While CurrentRowNumber >= 0 Do
				
				PieceByPieceAccountingOfProductsIsConducted = False;
				GoodsReceiptNoteLocalization.DefinitionOfFeatureOfOccasionalAccountingOfProductsOnDate(TabularPartProducts[CurrentRowNumber].ProductTypeIS, Object.Date, PieceByPieceAccountingOfProductsIsConducted);
			
				If PieceByPieceAccountingOfProductsIsConducted Then
					TabularPartProducts.Delete(CurrentRowNumber);
					OnlyNonLabeledProductsHaveBeenUnloaded = True;
				EndIf;
				CurrentRowNumber = CurrentRowNumber - 1;
			EndDo;
			
		EndIf;
		
		StorageAddress = PutToTempStorage(TabularPartProducts);
		
	EndIf;
	
	Return CheckPassed;
	
EndFunction

&AtClient
Procedure ViewImage()
	
	ClearMessages();
	
	CurrentData  = Items.Goods.CurrentData;
	MessageText = NStr("vi = 'Không có hình ảnh để xem.';
						|ru = 'Отсутствует изображение для просмотра.';
						|en = 'No preview image.'; fa = 'No preview image.';
						|it = 'Manca l''immagine per la visualizzazione.';
						|pl = 'Brakuje obrazku do przeglądania';
						|tr = 'Önizleme görüntüsü yok'");
	
	If Not ValueIsFilled(PictureAddress) Then
		CommonClient.MessageToUser(MessageText);
		
		Return;
	EndIf;
	
	If CurrentData <> Undefined
		And ValueIsFilled(CurrentData.Products) Then
		
		AttachedFile = ProductImageFile(CurrentData.Products);
		
		If ValueIsFilled(AttachedFile) Then
			FilesOperationsClient.OpenFile(
				FilesOperationsInternalServerCall.GetFileData(AttachedFile, UUID));
		Else
			CommonClient.MessageToUser(MessageText);
		EndIf;
		
	EndIf;
	
EndProcedure

&AtServer
Function ProductImageFile(Products)
	
	PicturesFile = Common.ObjectAttributeValue(Products, "PicturesFile");
	
	Return PicturesFile;
	
EndFunction

&AtServer
Procedure FillInReturnedAmountOnServer(CachedValues)
	
	References = Object.Goods.Unload(, "DocumentShipments").UnloadColumn("DocumentShipments");
	References = CommonClientServer.CollapseArray(References);
	
	Query = New Query();
	Query.Text = 
	"SELECT
	|	GoodsForShipmentTurnover.DocumentShipments AS DocumentShipments,
	|	GoodsForShipmentTurnover.Products     AS Products,
	|	GoodsForShipmentTurnover.Characteristic   AS Characteristic,
	|	GoodsForShipmentTurnover.Purpose       AS Purpose,
	|	GoodsForShipmentTurnover.Series            AS Series,
	|	GoodsForShipmentTurnover.ToShipExpense  AS Count
	|FROM
	|	AccumulationRegister.GoodsForIssue.Turnovers(
	|		,
	|		,
	|		Recorder,
	|		Warehouse = &Warehouse
	|		AND Recipient = &Recipient
	|		AND DocumentShipments IN (&References)
	|	) AS GoodsForShipmentTurnover";
	
	Query.SetParameter("References", References);
	Query.SetParameter("Warehouse",        Object.Warehouse);
	Query.SetParameter("Recipient",   Object.Sender);
	
	Goods = Object.Goods.Unload();
	Goods.FillValues(0, "Count");
	
	TableOrders = Query.Execute().Unload();
	
	Var_Key = "DocumentShipments, Products, Characteristic, Purpose, Series";
	Condition = "";
	InvoicesServer.AllocateQuantity(TableOrders, Goods, "Count", Var_Key, Condition, True);
	
	Var_Key = "DocumentShipments, Products, Characteristic, Purpose";
	Condition = "";
	InvoicesServer.DistributeQuantityAndFill(TableOrders, Goods, "Count", Var_Key, Condition, True, "Series");
	
	Object.Goods.Load(Goods);
	
	StructureOfActions = New Structure();
	StructureOfActions.Insert("RecalculateNumberOfPackages");
	StructureOfActions.Insert("RecalculateWeightVolume");
	StructureOfActions.Insert("CheckSeriesCalculateStatus",
			New Structure("Warehouse, SeriesSpecificationParameters", Object.Warehouse, SeriesSpecificationParameters));
	StructureOfActions.Insert("FillInCheckQualityDateOfQualityConfirmation", CacheQualityControl);
	StructureOfActions.Insert("FillInUnblockableDateOfQualityConfirmation", CacheQualityControl);
	
	BatchProcessingOfTablePartServer.TreatTS(Object.Goods, StructureOfActions);
	
EndProcedure

&AtServer
Procedure SortRows(ColumnName, Direction)
	ColumnNameDirection = StrReplace(Items[ColumnName].DataPath, "Object.Goods.","") + " " + Direction; 
	
	Object.Goods.Sort(ColumnNameDirection);
	If UsePackingLists Then
		PackingListsServer.RenumberLines(ThisObject, Object.Goods);
	EndIf;
EndProcedure

&AtClient
Procedure CustomerSChoice(ValueSelected, Var_Parameters) Export
	
	If ValueSelected = Undefined Then
		Return;
	EndIf;
	
	Modified = True;
	
	FillPropertyValues(Object, ValueSelected);
	
	Object.WarehouseOperation = WarehousesClientServer.WarehouseAcceptanceOperationForBusinessOperation(
									Object.BusinessOperation);
	
	ShowOrderPresentation(ReferenceOrderPresentation, Object.ReferenceOrder);
	
	If Object.WarehouseOperation <> PredefinedValue("Enum.WarehouseTransactions.ReturnOfGoodsNotReceivedByRecipient") Then
		If Object.WarehouseOperation = PredefinedValue("Enum.WarehouseTransactions.ReceivingByTransfer")
			Or Object.WarehouseOperation = PredefinedValue("Enum.WarehouseTransactions.ProductReceivingFromManufacturing") Then
			
			Autotest_FillInByOrder("ProductsQuantity_");
			
		Else
			Autotest_FillInByOrder("Products");
		EndIf;
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Procedure ShowOrderPresentation(ReferenceOrderPresentation, ReferenceOrder)
	
	RowsArray = New Array;
	
	If ValueIsFilled(ReferenceOrder) Then
		RowsArray.Add(New FormattedString(String(ReferenceOrder),
														,
														,
														,
														"Open_Order"));
		RowsArray.Add("  ");
		RowsArray.Add(New FormattedString(NStr("vi = 'Thay đổi';
												|ru = 'Изменить';
												|en = 'Change'; fa = 'تغییر';
												|it = 'Modificare';
												|pl = 'Change';
												|tr = 'Değiştir'"),
													,
													,
													,
													"SelectReference"));
	Else
		RowsArray.Add(New FormattedString(NStr("vi = '<không chọn>';
												|ru = '<не выбрано>';
												|en = '<not selected>'; fa = '<not selected>';
												|it = '<non selezionato>';
												|pl = '<nie wybrano>';
												|tr = '<seçilmedi>'")));
		RowsArray.Add("  ");
		RowsArray.Add(New FormattedString(NStr("vi = 'Chọn';
												|ru = 'Выбрать';
												|en = 'Select'; fa = 'انتخاب';
												|it = 'Selezionare';
												|pl = 'Select';
												|tr = 'Seç'"),
														,
														,
														,
														"SelectReference"));
	EndIf;		
		
	ReferenceOrderPresentation = New FormattedString(RowsArray);
	
EndProcedure

&AtServer
Procedure EstablishVisibilityOfPackagingElementsDuringLabeling()

	VisibilityOfElements = GetFunctionalOption("UsePackingLists") 
									And Not ThereAreLabeledProducts;

	Items.GoodsPackingListCode.Visible = VisibilityOfElements;
	
	Items.TotalNumberOfPackageItems.Visible           = VisibilityOfElements;
	Items.DecorationOfPlaces.Visible       = VisibilityOfElements;
	
	Items.GroupViewModeNavigation.Visible = VisibilityOfElements;
	Items.GoodsButtonGroupPackingList.Visible = VisibilityOfElements;

	Items.ProductsPictureOfThePackingList.Visible = VisibilityOfElements;
	Items.ProductsAdditionalInfoPackingList.Visible = VisibilityOfElements;
	
	Items.GoodsPackingList.Visible = VisibilityOfElements;
	Items.ProductsPackingListParent.Visible = VisibilityOfElements;
	Items.GoodsLineNumberDisplayed.Visible = VisibilityOfElements;
	
EndProcedure

&AtServer
Procedure SetFormItemEnabled()

	Items.GoodsVerifyQuantity.Enabled = Not ReadOnly;
	
EndProcedure

#EndRegion

&AtClient
Procedure Attachable_ProcessObjectEntry()
	
	TMCommonUseClient.ProcessObjectEntryInForm(ThisObject, ParametersForRecording);
	
EndProcedure

// StandardSubsystems.Properties

&AtServer
Procedure UpdateAdditionalAttributesItems()
	
	PropertyManager.UpdateAdditionalAttributesItems(ThisObject);
	
EndProcedure

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
