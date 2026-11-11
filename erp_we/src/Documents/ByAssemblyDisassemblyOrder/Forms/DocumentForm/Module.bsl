#Region Variables

&AtClient
Var CachedValues; //used by the mechanism for processing changes in PM details

&AtClient
Var SeriesIsEditedInHeader; //used to determine that the series selection form is called for the series specified in the header

&AtClient
Var CurDataId; //used to pass the current line to the wait handler

&AtClient
Var FormModified; // it is used to work out the form modification change event

#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If AvailableRemainingEmbeddingOptions = Undefined Then
		EmbeddingParameters = Documents.ByAssemblyDisassemblyOrder.AvailableRemainingEmbeddingOptions(Object);
	Else // the parameters have already been initialized when reading on the server
		EmbeddingParameters = AvailableRemainingEmbeddingOptions;
	EndIf;
	ProvisionInDocumentsServer.AvailableBalancesWhenCreatedOnServer(ThisObject, EmbeddingParameters);
	
	SetConditionalAppearance();
	
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(Object, ThisObject);
	
	TMCommonUse.CustomizePeripherals(ThisForm);
	
	// Handler of the "Versioning of objects" mechanism
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	
	// StandardSubsystems.Properties
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("ItemForPlacementName", "GroupAdditionalAttributes");
	AdditionalParameters.Insert("DeferredInitialization", True);
	PropertyManager.OnCreateAtServer(ThisObject, AdditionalParameters);
	// End StandardSubsystems.Properties
	
	If Not ValueIsFilled(Object.Ref) Then
		
		OnReadCreateAtServer();
		
		ProductsServer.FillInStatusesForSpecifyingSeries(Object,SeriesSpecificationParameters.TS);
		ProductsServer.FillInStatusesForSpecifyingSeries(Object,SeriesSpecificationParameters.Header);
		
	EndIf;
	
	// Handler of the "Destination" mechanism
	Catalogs.Assignments.DocumentFormWhenCreatedOnServer(ThisForm);
	
	Items.CloseOrder.Enabled = AccessRight("Update",Metadata.Documents.ByAssemblyDisassemblyOrder);
	
	SetAvailabilityOfClipboardCommands();
	
	// Setting the list of available statuses
	Enums.InternalOrderStatuses.FillChoiceList(Items.Status.ChoiceList, False);
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject);
	// End IntegrationWith1CDocumentManagementSubsystem
	
	// StandardSubsystems.FilesOperations
	HyperlinkParameters = FilesOperations.FilesHyperlink();
	HyperlinkParameters.Location = "CommandBar";
	FilesOperations.OnCreateAtServer(ThisObject, HyperlinkParameters);
	// End StandardSubsystems.FilesOperations

	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);

	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	AttachIdleHandler("Attachable_WhenChangingModifiabilityOfForm", 1);
	
	// StandardSubsystems.Properties
	PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
	// End StandardSubsystems.Properties
	
	EquipmentManagerClient.StartConnectingDevicesWhenYouOpenForm(Undefined, ThisForm, "BarcodeScanner");
	
	ProductsClient.UpdateCachedHeaderValuesToAccountForSeries(Object,CachedValues,SeriesSpecificationParameters.Header);
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	// StandardSubsystems.FilesOperations
	FilesOperationsClient.OnOpen(ThisObject, Cancel);
	// End StandardSubsystems.FilesOperations
	
EndProcedure

&AtClient
Procedure OnClose(Exit)

	EquipmentManagerClient.StartDisablingHardwareWhenClosingForm(Undefined, ThisForm);

EndProcedure

&AtClient
Procedure ChoiceProcessing(ValueSelected, ChoiceSource)
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.StartTimeMeasurement(True,
		"Document.ByAssemblyDisassemblyOrder.Form.DocumentForm.Event.ChoiceProcessing");
	
	If ChoiceSource.FormName = "DataProcessor.OrderSupplyForecast.Form.Form" Then
		
		AddressOfTheMovementTable = FillInCollateralFromCollateralStateForm(
			ValueSelected.ActionCode,
			ValueSelected.AddressAnalyst,
			ValueSelected.FillParameters);
			
		// Returning the control to the form of processing the security status.
		RunCallback(ValueSelected.Callback, AddressOfTheMovementTable);
		
	ElsIf ChoiceSource.FormName = "DataProcessor.SelectGoodsToSalesDocument.Form.Form" Then
		
		HandlingSelectionSelectionOnClient(ValueSelected);
		
	ElsIf ProductsClient.ThisIsIndicationOfSeries(ChoiceSource) Then
		
		If SeriesIsEditedInHeader Then 
			ProductsClient.ProcessSeriesIndication(ThisForm, SeriesSpecificationParameters.Header, ValueSelected);
			ProductsClient.UpdateCachedHeaderValuesToAccountForSeries(Object,CachedValues,SeriesSpecificationParameters.Header);	
		Else
			ProductsClient.ProcessSeriesIndication(ThisForm, SeriesSpecificationParameters.TS, ValueSelected);
		EndIf;
	ElsIf ChoiceSource.FormName = "DataProcessor.OrderClosureWizard.Form.ClosureForm" Then
		
		CancellationResult = AdjustOrderLines(ValueSelected);
		ShowUserNotification(NStr("vi = 'Hủy bỏ hàng không được xử lý';
									|ru = 'Отмена неотработанных строк';
									|en = 'Cancel unfulfilled lines'; fa = 'Cancel unfulfilled lines';
									|it = 'Annullamento delle righe non elaborate';
									|pl = 'Anulowanie nieprzetworzonych wierzszy';
									|tr = 'İşlenmemiş satır iptali'"), , CancellationResult.Notification);
		
		If ProductsClient.YouNeedToUpdateStatusOfSeriesInHeader(Object, CachedValues, SeriesSpecificationParameters.Header) Then
			ProductsClient.UpdateCachedHeaderValuesToAccountForSeries(Object, CachedValues, SeriesSpecificationParameters.Header);
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
	
	FormEventsClient.NotificationProcessing(ThisObject, EventName, Parameter, Source);
	
EndProcedure

&AtClient
Procedure URLProcessing(FormattedStringURL, StandardProcessing)
	
	FormEventsClient.URLProcessing(ThisObject, FormattedStringURL, StandardProcessing);
	
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)

	// StandardSubsystems.AccessManagement
	AccessManagement.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.AccessManagement

	AvailableRemainingEmbeddingOptions = Undefined;
	EmbeddingParameters = Documents.ByAssemblyDisassemblyOrder.AvailableRemainingEmbeddingOptions(Object);
	ProvisionInDocumentsServer.AvailableBalancesWhenReadingOnServer(ThisObject, EmbeddingParameters);
	
	OnReadCreateAtServer();
	
	FormEvents.OnReadAtServer(ThisForm, CurrentObject);
	
	// StandardSubsystems.Properties	
	PropertyManager.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.Properties
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	// End StandardSubsystems.AttachableCommands
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)
	
	// StandardSubsystems.AccessManagement
	AccessManagement.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	// End StandardSubsystems.AccessManagement
	
	ProvisionInDocumentsServer.AfterWriteAtServer(ThisObject);
	SetPropertiesOfElementsOfFormBusinessOperation();
	FillInServiceDetailsForProductRange();
	
	FormEvents.AfterWriteAtServer(ThisForm, CurrentObject, WriteParameters);
	
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	
	FormModified = Undefined;
	Attachable_WhenChangingModifiabilityOfForm();
	
	NotifyAboutDocument(WriteParameters);
	ProvisionInDocumentsClient.AfterWrite(ThisObject, "Attachable_CheckCompletionOfInventoryAllocationTask");
	
	ConfigurationModificationClientOverridable.AfterWrite(ThisForm, WriteParameters);
	
	If WriteParameters.Property("CreatingAdjustment") Then
		
		AdditionalParameters = WriteParameters.CreatingAdjustment;
		
		If Object.Posted Then
			
			// If the document is recorded for the first time, there is an empty link in the Base object, you need to update it.
			ObjectsOfBases = New Array();
			ObjectsOfBases.Add(Object.Ref);
			
			AdditionalParameters.CommandDetails.Insert("ObjectsOfBases", ObjectsOfBases);
			AdditionalParameters.CommandDetails.Insert("Form", ThisObject);
			
			ProvisionInDocumentsClient.OpenAssignmentAdjustmentFilling(
				AdditionalParameters.Reservation,
				Object.Ref,
				AdditionalParameters.CommandDetails);
			
		EndIf;
		
	EndIf;
	
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
	// End StandardSubsystems.Properties
	
	ConfigurationModificationOverridable.BeforeWriteAtServer(ThisForm, Cancel, CurrentObject, WriteParameters);

	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.BeforeWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	// End IntegrationWith1CDocumentManagementSubsystem
	
EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	
	// StandardSubsystems.Properties
	PropertyManager.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes);
	// End StandardSubsystems.Properties
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure OrganizationOnChange(Item)
	
	UpdateAssemblyForActivity();
	
EndProcedure

&AtClient
Procedure WarehouseOnChange(Item)
	
	WarehouseOnChangeServer(True);
	ProductsClient.UpdateCachedHeaderValuesToAccountForSeries(Object,CachedValues, SeriesSpecificationParameters.Header);
	
EndProcedure

&AtClient
Procedure DateOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	
	PrepareFillSetSeriesVisibility();
	UpdateAssemblyForActivity();
	ProductsClient.UpdateCachedHeaderValuesToAccountForSeries(Object,CachedValues, SeriesSpecificationParameters.Header);
	
EndProcedure

&AtClient
Procedure BusinessOperationOnChange(Item)
	
	BusinessOperationOnChangeServer();
	ProductsClient.UpdateCachedHeaderValuesToAccountForSeries(Object,CachedValues, SeriesSpecificationParameters.Header);
	
EndProcedure

&AtClient
Procedure ProductsOnChange(Item)
	
	ProductsOnChangeServer(CachedValues);
	ProductsClient.UpdateCachedHeaderValuesToAccountForSeries(Object, CachedValues, SeriesSpecificationParameters.Header);
	
	HideCancelGroup();
	
EndProcedure

&AtClient
Procedure CharacteristicOnChange(Item)

	StructureOfActions = New Structure;
	StructureOfActions.Insert("CheckCompleteConfigurationOptionByOwner", Object.ProductKit);
	StructureOfActions.Insert("CheckFillAssignment");
	StringStructure = New Structure;
	StringStructure.Insert("Products",               Object.Products);
	StringStructure.Insert("Characteristic",             Object.Characteristic);
	StringStructure.Insert("ProductKit",        Object.ProductKit);
	StringStructure.Insert("ItemVariantsAreUsed", True);

	StructureOfActions.Insert("CharacteristicOnChangeOverridable", New Structure("FormName, TabularSectionName",
		ThisForm.FormName, "Object"));

	BatchProcessingOfTablePartClient.ProcessTSString(StringStructure, StructureOfActions, CachedValues);

	FillPropertyValues(Object, StringStructure, "ProductKit");
	
	CharacteristicOnChangeServer();
	ConfigurationOptionWhenChangingOnServer();
	
	If ProductsClient.YouNeedToUpdateStatusOfSeriesInHeader(Object,CachedValues,SeriesSpecificationParameters.Header) Then
		
		FillInStatusesOfSpecifyingSeriesWhenChangingProductInHeader(CachedValues);
		ProductsClient.UpdateCachedHeaderValuesToAccountForSeries(Object,CachedValues,SeriesSpecificationParameters.Header);	
		
	EndIf;

EndProcedure

&AtClient
Procedure PackageOnChange(Item)
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateNumberOfUnits");
	
	BatchProcessingOfTablePartClient.ProcessTSString(Object, StructureOfActions, CachedValues);
	LabelPackaging = ?(ValueIsFilled(Object.Package), Object.Package, Items.Package.InputHint);
	PerformKitAssuranceActionsOnClient("Available");
	
EndProcedure

&AtClient
Procedure NumberOfPackagesOnChange(Item)
	
	StructureOfActions = New Structure;
	AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions);
	BatchProcessingOfTablePartClient.ProcessTSString(Object, StructureOfActions, CachedValues);
	
	PerformKitAssuranceActionsOnClient("Available");
	HideCancelGroup();
	
	If ProductsClient.YouNeedToUpdateStatusOfSeriesInHeader(Object,CachedValues,SeriesSpecificationParameters.Header) Then
		
		FillInStatusesOfSpecifyingSeriesWhenChangingProductInHeader(CachedValues);
		ProductsClient.UpdateCachedHeaderValuesToAccountForSeries(Object,CachedValues,SeriesSpecificationParameters.Header);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure HideCancelGroup()
	
	// The quantity has been changed by the user. The value of the cancelled quantity is no longer relevant.
	Object.CountCanceled = 0;
	Object.NumberOfPackagesCanceled = 0;
	// While there are no canceled sets for the document, the corresponding field is hidden.
	Items.CancelGroup.Visible = False;
	
EndProcedure

&AtClient
Procedure BatchesIndicationStatusClick(Item, StandardProcessing)
	OpenSelectionOfKitSeries();
EndProcedure

&AtClient
Procedure SeriesStartChoice(Item, ChoiceData, StandardProcessing)
	StandardProcessing = False;
	OpenSelectionOfKitSeries(Item.EditText);
EndProcedure

&AtClient
Procedure SeriesOnChange(Item)
	ValueSelected = ProductsClientServer.SelectedSeries();
	
	ValueSelected.Value            		 = Object.Series;
	
	ProductsClient.ProcessSeriesIndication(ThisForm, SeriesSpecificationParameters.Header, ValueSelected);
	ProductsClient.UpdateCachedHeaderValuesToAccountForSeries(Object,CachedValues,SeriesSpecificationParameters.Header);	
EndProcedure

&AtClient
Procedure AssemblyDisassemblyDurationDaysOnChange(Item)
	
	If ValueIsFilled(Object.AssemblyDisassemblyStart) Then
		
		Object.AssemblyDisassemblyEnd = Object.AssemblyDisassemblyStart + Object.AssemblyDisassemblyDurationDays * 86400;
		
	ElsIf ValueIsFilled(Object.AssemblyDisassemblyEnd) Then
		
		Object.AssemblyDisassemblyStart = Object.AssemblyDisassemblyEnd - Object.AssemblyDisassemblyDurationDays * 86400;
		
	EndIf;
	
	UpdateQualityControlAttributes();
	
EndProcedure

&AtClient
Procedure AssemblyDisassemblyStartOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	
	AssemblyDisassemblyStartOnChangeServer();
	
EndProcedure

&AtClient
Procedure AssemblyDisassemblyEndOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	
	AssemblyDisassemblyEndOnChangeServer();
	
EndProcedure

&AtClient
Procedure LineOfBusinessOnChange(Item)
	
	LineOfBusinessOnChangeServer();
	
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

&AtClient
Procedure AssemblyForActivityClearing(Item, StandardProcessing)
	StandardProcessing = False;
EndProcedure

&AtClient
Procedure PurposeOnChange(Item)
	
	PurposeOnChangeServer();
	
EndProcedure

&AtClient
Procedure SupplyOptionOnChange(Item)
	
	Var FormParameters;
	If ProvisionInDocumentsClient.OpenWarehouseAndSeriesSelectionForm(ThisObject) Then
		OptionForGettingParameters = ProvisionInDocumentsClientServer.ActionSelectionMode();
		FormParameters = ParametersOfKitQuantityAndSeriesRequestForm(OptionForGettingParameters); // A call to the server
	EndIf;
	
	ProvisionInDocumentsClient.SupplyOptionOnChange(
		ThisObject,
		FormParameters,
		"ProcessSelectionOfWarehouseAndKitSeries",
		False,
		"SecurityOptionWhenChangingOnClient");
	
EndProcedure

&AtClient
Procedure SupplyOptionClearing(Item, StandardProcessing)
	
	StandardProcessing = False;
	
EndProcedure

&AtClient
Procedure SupplyOptionChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	ProvisionInDocumentsClient.SupplyOptionChoiceProcessing(
		ThisObject,
		Object,
		ValueSelected);
	
EndProcedure

&AtClient
Procedure WithAssignmentOnChange(Item)
	
	UpdateColumnAvailableServer();
	
EndProcedure

&AtClient
Procedure AvailableClick(Item, StandardProcessing)
	
	StandardProcessing = False;
	FormParameters = ParametersOfKitQuantityAndSeriesRequestForm(Undefined);
	
	If FormParameters <> Undefined Then
		OpenForm("DataProcessor.QuantityAndBatchRequest.Form", FormParameters, ThisObject);
	EndIf;
	
EndProcedure

&AtClient
Procedure SecurityStatusHyperlinkClick(Item)
	
	HyperlinkStateOfProvisionClickGeneral();
	
EndProcedure

&AtClient
Procedure HyperlinkSecurityStatusIssueClick(Item)
	
	HyperlinkStateOfProvisionClickGeneral();
	
EndProcedure

&AtClient
Procedure HyperlinkSecurityStatusIsBeingShippedClick(Item)
	
	HyperlinkStateOfProvisionClickGeneral();
	
EndProcedure

// StandardSubsystems.FilesOperations
&AtClient
Procedure Attachable_PreviewFieldClick(Item, StandardProcessing)
	
	FilesOperationsClient.PreviewFieldClick(ThisObject, Item, StandardProcessing);
	
EndProcedure

&AtClient
Procedure Attachable_PreviewFieldDrag(Item, DragParameters, StandardProcessing)
	
	FilesOperationsClient.PreviewFieldDrag(ThisObject, Item,
				DragParameters, StandardProcessing);
	
EndProcedure

&AtClient
Procedure Attachable_PreviewFieldCheckDragging(Item, DragParameters, StandardProcessing)
	
	FilesOperationsClient.PreviewFieldCheckDragging(ThisObject, Item,
				DragParameters, StandardProcessing);
	
EndProcedure
// End StandardSubsystems.FilesOperations

&AtClient
Procedure ToControlQualityOnChange(Item)
	
	If Object.ToControlQuality Then
		Object.QualityConfirmationDate = '00010101';
	EndIf;
	ToControlQualityOnChangeServer();
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersGoods

&AtClient
Procedure GoodsSelection(Item, RowSelected, Field, StandardProcessing)
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.StartTimeMeasurement(
		True, "Document.ByAssemblyDisassemblyOrder.Form.DocumentForm.Items.Goods.Selection");
	
	If Item.CurrentItem = Items.GoodsAvailable And Not ReadOnly Then
		
		StandardProcessing = False;
		
		FormParameters = ParametersOfQuantityAndSeriesRequestForm(Undefined);
		
		If FormParameters <> Undefined Then
			OpenForm("DataProcessor.QuantityAndBatchRequest.Form", FormParameters, ThisObject);
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure GoodsProductsOnChange(Item)

	CurrentRow = Items.Goods.CurrentData;
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("CheckCharacteristicsByOwner", CurrentRow.Characteristic);
	StructureOfActions.Insert("CheckFillPackageByOwner"      , CurrentRow.Package);
	StructureOfActions.Insert("RecalculateNumberOfUnits");
	StructureOfActions.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
	StructureOfActions.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));
	StructureOfActions.Insert("CheckSeriesCalculateStatus", New Structure("Warehouse, SeriesSpecificationParameters", Object.Warehouse, SeriesSpecificationParameters.TS));
	StructureOfActions.Insert("FillInCheckQualityDateOfQualityConfirmation",
		QualityControlClientServer.CacheByKey(CacheQualityControl, "Goods"));
	AddCollateralActionsOnClient(StructureOfActions, "SupplyOption,AvailableInOtherLines");
	LinesOfBusinessClientServer.StructureOfInsertActionsWhenAddingRow(ThisForm, StructureOfActions);
	StructureOfActions.Insert("ProductsOnChangeOverridable", New Structure("FormName, TabularSectionName",
		ThisForm.FormName, "Goods"));
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
	If ProvisionInDocumentsClient.YouNeedToUpdateAvailableColumn(StructureOfActions) Then
		UpdateColumnAvailableServer();
	EndIf;
	
EndProcedure

&AtClient
Procedure GoodsCharacteristicOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;
	
	StructureOfActions = New Structure;
	AddCollateralActionsOnClient(StructureOfActions, "SupplyOption,AvailableInOtherLines");
	LinesOfBusinessClientServer.StructureOfInsertActionsWhenAddingRow(ThisForm, StructureOfActions);
	StructureOfActions.Insert("CharacteristicOnChangeOverridable", New Structure("FormName, TabularSectionName",
		ThisForm.FormName, "Goods"));
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
	If ProvisionInDocumentsClient.YouNeedToUpdateAvailableColumn(StructureOfActions) Then
		UpdateColumnAvailableServer();
	EndIf;
	
EndProcedure

&AtClient
Procedure GoodsPackageOnChange(Item)

	CurrentRow = Items.Goods.CurrentData;
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateNumberOfUnits");
	AddCollateralActionsOnClient(StructureOfActions, "AvailableInOtherLines");
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
	If ProvisionInDocumentsClient.YouNeedToUpdateAvailableColumn(StructureOfActions) Then
		UpdateColumnAvailableServer();
	EndIf;

EndProcedure

&AtClient
Procedure GoodsNumberOfPackagesOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;
	
	StructureOfActions = New Structure;
	AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions);
	AddCollateralActionsOnClient(StructureOfActions, "AvailableInOtherLines");
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
	If ProvisionInDocumentsClient.YouNeedToUpdateAvailableColumn(StructureOfActions) Then
		UpdateColumnAvailableServer();
	EndIf;
	
EndProcedure

&AtClient
Procedure GoodsOnStartEdit(Item, NewRow, Copy)
	
	ProcessingOfTabularFormsClient.CacheCurLine(Items.Goods, ThisObject);
	If NewRow Then
		
		Items.Goods.CurrentData.RowCode = 0;
		
	EndIf;
	
	If Copy Then
		StructureOfActions = New Structure;
		AddCollateralActionsOnClient(StructureOfActions, "SupplyOption,Available");
		StructureOfActions.Insert("CheckSeriesCalculateStatus", New Structure("Warehouse, SeriesSpecificationParameters", Object.Warehouse, SeriesSpecificationParameters.TS));
		BatchProcessingOfTablePartClient.ProcessTSString(Items.Goods.CurrentData, StructureOfActions, CachedValues);
	EndIf;
	
EndProcedure

&AtClient
Procedure GoodsSeriesStartChoice(Item, ChoiceData, StandardProcessing)
	StandardProcessing = False;
	OpenSelectionOfSeries(Item.EditText);
EndProcedure

&AtClient
Procedure GoodsSeriesOnChange(Item)
	ValueSelected = ProductsClientServer.SelectedSeries();
	
	ValueSelected.Value					 = Items.Goods.CurrentData.Series;
	ValueSelected.CurrentRowID = Items.Goods.CurrentData.GetID();
	
	ProductsClient.ProcessSeriesIndication(ThisForm, SeriesSpecificationParameters.TS, ValueSelected);
EndProcedure

&AtClient
Procedure GoodsSupplyOptionOnChange(Item)
	
	Var FormParameters;
	If ProvisionInDocumentsClient.OpenWarehouseAndSeriesSelectionForm(ThisObject) Then
		OptionForGettingParameters = ProvisionInDocumentsClientServer.ActionSelectionMode();
		FormParameters = ParametersOfQuantityAndSeriesRequestForm(OptionForGettingParameters); // A call to the server
	EndIf;
	
	ProvisionInDocumentsClient.SupplyOptionOnChange(
		ThisObject,
		FormParameters,
		"ProcessWarehouseAndBatchSelection",
		False,
		"ItemsAreCollateralOptionWhenChangedOnClient");
	
EndProcedure

&AtClient
Procedure GoodsSupplyOptionClearing(Item, StandardProcessing)
	
	StandardProcessing = False;
	
EndProcedure

&AtClient
Procedure GoodsCanceledOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;
	
	StructureOfActions = New Structure;
	AddCollateralActionsOnClient(StructureOfActions, "AvailableInOtherLines");
	StructureOfActions.Insert("CheckSeriesCalculateStatus", New Structure("Warehouse, SeriesSpecificationParameters", Object.Warehouse, SeriesSpecificationParameters.TS));
	StructureOfActions.Insert("FillInCheckQualityDateOfQualityConfirmation",
		QualityControlClientServer.CacheByKey(CacheQualityControl, "Goods"));
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
	If ProvisionInDocumentsClient.YouNeedToUpdateAvailableColumn(StructureOfActions) Then
		UpdateColumnAvailableServer();
	EndIf;
	
	CalculateOrderTotals();
	
EndProcedure

&AtClient
Procedure GoodsAfterDeleteRow(Item)
	
	If Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.AssemblyFromComponents") Then
		UpdateColumnAvailableServer();
	EndIf;
	
EndProcedure

&AtClient
Procedure GoodsSupplyOptionChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	ProvisionInDocumentsClient.SupplyOptionChoiceProcessing(
		ThisObject,
		Items.Goods.CurrentData,
		ValueSelected);
		
EndProcedure

&AtClient
Procedure GoodsWithAssignmentOnChange(Item)
	
	TableRow = Items.Goods.CurrentData;
	ProvisionInDocumentsClient.WithAssignmentOnChange(TableRow);
	StructureOfActions = New Structure();
	AddCollateralActionsOnClient(StructureOfActions, "AvailableInOtherLines");
	BatchProcessingOfTablePartClient.ProcessTSString(TableRow, StructureOfActions, Undefined);
	
	If ProvisionInDocumentsClient.YouNeedToUpdateAvailableColumn(StructureOfActions) Then
		UpdateColumnAvailableServer();
	EndIf;
	
EndProcedure

&AtClient
Procedure GoodsPurposeOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;
	
	StructureOfActions = New Structure();
	AddCollateralActionsOnClient(StructureOfActions, "AvailableInOtherLines");
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
	If ProvisionInDocumentsClient.YouNeedToUpdateAvailableColumn(StructureOfActions) Then
		UpdateColumnAvailableServer();
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

// StandardSubsystems.AttachableCommands
&AtServer
Procedure ExecuteCommandAtServer(ExecutionParameters)
	AttachableCommands.ExecuteCommand(ThisObject, ExecutionParameters, Object);
EndProcedure

&AtClient
Procedure Attachable_ContinueCommandExecutionAtServer(ExecutionParameters, AdditionalParameters) Export
	ExecuteCommandAtServer(ExecutionParameters);
EndProcedure

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
Procedure ImportDataFromPDT(Command)
	
	ClearMessages();
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.StartTimeMeasurement(True,
		"Document.ByAssemblyDisassemblyOrder.DocumentForm.Command.ImportDataFromPDT");
	
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
Procedure FillInWithComponents(Command)
	
	ClearMessages();
	If Not ValueIsFilled(Object.ProductKit) Then

		CommonClientServer.MessageToUser(NStr("vi = 'Chưa chỉ ra trường ""Đóng bộ""';
												|ru = 'Не указано поле ""Комплектация""';
												|en = 'Product kit is not specified'; fa = 'Product kit is not specified';
												|it = 'Il campo ""Completamento"" non è specificato';
												|pl = 'Nie jest podane pole ""Komplektacja""';
												|tr = '""Ürün seti"" alanı belirtilmedi'"),,
				"ProductKit",
				"Object");

		Return;
		
	EndIf;

	FillInProductsByConfigurationOption();

EndProcedure

&AtClient
Procedure SelectGoods(Command)
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.StartTimeMeasurement(True,
		"Document.ByAssemblyDisassemblyOrder.DocumentForm.Command.SelectGoods");
	
	Cancel = False;
	
	If Cancel Then
		
		Return;
		
	EndIf;
	
	FormParameters = New Structure;
	FormParameters.Insert("Warehouse",                                     Object.Warehouse);
	FormParameters.Insert("SelectionModeWithoutAmountParameters",         True);
	FormParameters.Insert("FilterByProductType",                   New FixedArray(ProductsClientServer.SelectionByProductMultiTurnContainer(False)));
	FormParameters.Insert("HideTheViewPriceColumn",                    True);
	FormParameters.Insert("UseShipmentDates",                  True);
	FormParameters.Insert("HideTheItemPricesCommand",           True);
	FormParameters.Insert("Title",                                 NStr("vi = 'Chọn hàng hóa';
																		|ru = 'Подбор товаров';
																		|en = 'Pick goods'; fa = 'انتخاب کالاها';
																		|it = 'Selezione delle merci';
																		|pl = 'Wybór towarów';
																		|tr = 'Ürünlerin seçimi'"));
	FormParameters.Insert("Date",                                      Object.Date);
	FormParameters.Insert("Document",                                  Object.Ref);
	FormParameters.Insert("SeriesSpecificationParameters",                    SeriesSpecificationParameters.TS);
	FormParameters.Insert("Purpose",                                Object.AssignmentGoods);
	FormParameters.Insert("Department",                             Object.Department);
	FormParameters.Insert("SelectSupplyOptions",                True);
	FormParameters.Insert("AvailableRemainingDocumentParameters",        Undefined);
	
	OpenForm("DataProcessor.SelectGoodsToSalesDocument.Form", FormParameters, ThisForm, UUID);
	
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
		
		NewRow.RowCode = 0;
		
		StructureOfActions = New Structure;
		AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions);
		BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
		If Object.BusinessOperation
				= PredefinedValue("Enum.BusinessTransactions.AssemblyFromComponents") Then
			AddCollateralActionsOnClient(StructureOfActions,"UpdateProductCache_");
		EndIf;
		BatchProcessingOfTablePartClient.ProcessTSString(NewRow, StructureOfActions, CachedValues);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure SpecifySeriesInHeader(Command)
	
	OpenSelectionOfKitSeries();
	
EndProcedure

&AtClient
Procedure InsertRows(Command)
	
	NumberOfProductsBeforeInsertion = Object.Goods.Count();
	
	GetLinesFromClipboard();
	
	NumberOfInserted = Object.Goods.Count()- NumberOfProductsBeforeInsertion;
	ProcessingOfTabularFormsClient.NotifyUserAboutInsertingRows(NumberOfInserted);
	
EndProcedure

&AtClient
Procedure CopyRows(Command)
	
	If ProcessingOfTabularFormsClient.SelectedLineToExecuteCommand(Items.Goods) Then
		CopyLinesOnServer();
		ProcessingOfTabularFormsClient.NotifyUserAboutCopyingStrings(Items.Goods.SelectedRows.Count());
	EndIf;

EndProcedure

#Region Supply

&AtClient
Procedure CreateAnAssignmentAdjustmentReservation(Command)
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.StartTimeMeasurement(True,
		"Document.ByAssemblyDisassemblyOrder.DocumentForm.Command.CreateAnAssignmentAdjustmentReservation");
	
	ObjectsOfBases = New Array();
	ObjectsOfBases.Add(Object.Ref);
	
	CommandDetails = New Structure();
	CommandDetails.Insert("ObjectsOfBases", ObjectsOfBases);
	
	If Not Object.Posted Or Modified Then
		AdditionalParameters = New Structure();
		AdditionalParameters.Insert("Reservation", True);
		AdditionalParameters.Insert("CommandDetails", CommandDetails);
		
		QueryText = NStr("vi = 'Để lập dự phòng, trước tiên phải kết chuyển chứng từ. Thực hiện kết chuyển chứng từ và tiếp tục?';
						|ru = 'Для резервирования под назначение необходимо предварительно провести документ. Выполнить проведение документа и продолжить?';
						|en = 'To reserve for assignment, it is required to post the document first. Post the document and continue?'; fa = 'To reserve for assignment, it is required to post the document first. Post the document and continue?';
						|it = 'Per prenotare per destinazione, è necessario innanzitutto registrare il documento. Eseguire la registrazione del documento e continuare?';
						|pl = 'W celu rezerwacji do przeznaczenia najpierw należy zatwierdzić dokument. Wykonać zatwierdzenie dokumentu i kontynuować?';
						|tr = 'Atama için rezerve edilebilmesi amacıyla belgenin önce kaydedilmesi gerekir. Belge kaydedilip devam edilsin mi?'");
		ShowQueryBox(
			New CallbackDescription("CreateAnAssignmentAdjustmentCompletion", ThisObject, AdditionalParameters), 
				QueryText, QuestionDialogMode.YesNo);
	Else
		
		CommandDetails.Insert("Form", ThisObject);
		ProvisionInDocumentsClient.OpenAssignmentAdjustmentFilling(
			True,
			Object.Ref,
			CommandDetails);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure CreateAssignmentAdjustmentRemoveFromReserve(Command)
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.StartTimeMeasurement(True,
		"Document.ByAssemblyDisassemblyOrder.DocumentForm.Command.CreateAssignmentAdjustmentRemoveFromReserve");
	
	ObjectsOfBases = New Array();
	ObjectsOfBases.Add(Object.Ref);
	
	CommandDetails = New Structure();
	CommandDetails.Insert("ObjectsOfBases", ObjectsOfBases);
	
	If Not Object.Posted Or Modified Then
		AdditionalParameters = New Structure();
		AdditionalParameters.Insert("Reservation", False);
		AdditionalParameters.Insert("CommandDetails", CommandDetails);
		
		QueryText = NStr("vi = 'Để hoàn dự phòng, trước tiên phải kết chuyển chứng từ. Thực hiện kết chuyển chứng từ và tiếp tục?';
						|ru = 'Для снятия резерва под назначение необходимо предварительно провести документ. Выполнить проведение документа и продолжить?';
						|en = 'To remove the reserve for assignment, post the document first. Post the document and continue?'; fa = 'To remove the reserve for assignment, post the document first. Post the document and continue?';
						|it = 'Per rimuove la prenotazione per destinazione, è necessario innanzitutto registrare il documento. Eseguire la registrazione del documento e continuare?';
						|pl = 'W celu usunięcia rezerwy do przeznaczenia najpierw należy zatwierdzić dokument. Wykonać zatwierdzenie dokumentu i kontynuować?';
						|tr = 'Bir atama için rezervasyonun iptali için önceden bir belgenin kaydedilmesi gerekir. Belge onaylansın ve devam edilsin mi?'");
		ShowQueryBox(
			New CallbackDescription("CreateAnAssignmentAdjustmentCompletion", ThisObject, AdditionalParameters), 
				QueryText, QuestionDialogMode.YesNo);
	Else
		
		CommandDetails.Insert("Form", ThisObject);
		ProvisionInDocumentsClient.OpenAssignmentAdjustmentFilling(
			False,
			Object.Ref,
			CommandDetails);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure CloseOrder(Command)
	
	If Modified Or Not Object.Posted Then
		Response = Undefined;
		ShowQueryBox(New CallbackDescription("CloseOrderCompletion", ThisObject),
			NStr("vi = 'Cần kết chuyển chứng từ để thực hiện giao dịch. Kết chuyển chứng từ?';
				|ru = 'Необходимо провести документ для выполнения операции. Провести документ?';
				|en = 'To proceed, you need to post the document. Do you want to post the document?'; fa = 'To proceed, you need to post the document. Do you want to post the document?';
				|it = 'È necessario registrare il documento per eseguire operazione. Registrare documento?';
				|pl = 'Należy zaksięgować dokument aby wykonać operację. Zaksięgować dokument?';
				|tr = 'Bir işlemin gerçekleştirilmesi için belgenin kaydedilmesi gerekir. Belge kaydedilsin?'"), QuestionDialogMode.YesNo);
		Return;
	EndIf;
	
	CloseOrderFragment();
	
EndProcedure

&AtClient
Procedure CloseOrderFragment()
	
	ListOfOrdersToClose = New ValueList;
	ListOfOrdersToClose.Add(Object.Ref);
	
	ClosureStructure = New Structure;
	ClosureStructure.Insert("Orders",                       ListOfOrdersToClose);
	ClosureStructure.Insert("DocumentInitiator",            Object.Ref);
	ClosureStructure.Insert("CancelUnprocessedLines", True);
	ClosureStructure.Insert("CloseOrders",              True);
	
	OpenForm("DataProcessor.OrderClosureWizard.Form.ClosureForm", 
					ClosureStructure, ThisForm,,,, Undefined, FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure CloseOrderCompletion(QuestionResult, AdditionalParameters) Export
	
	Response = QuestionResult;
	
	If Response = DialogReturnCode.No Then
		Return;
	ElsIf Not Write(New Structure("WriteMode", DocumentWriteMode.Posting)) Then
		Return;
	EndIf;
	
	CloseOrderFragment();
	
EndProcedure

&AtClient
Procedure EnableStandAloneSoftware(Command)
	
	ProvidingSetAction("FLAG_UNITED");
	
EndProcedure

&AtClient
Procedure DisableStandAloneSoftware(Command)
	
	ProvidingSetAction("FLAG_NOTABLE");
	
EndProcedure

&AtClient
Procedure ToSupply(Command)
	
	ProvidingSetActionWithQuestion("ACTION_COOPERATION");
	
EndProcedure

&AtClient
Procedure ReserveAsReceived(Command)
	
	ProvidingSetAction("ACTION_RESERVATION_REFERENCES");
	
EndProcedure

&AtClient
Procedure NotProvide(Command)
	
	ProvidingSetActionWithQuestion("ACTION_NOTABLE");
	
EndProcedure

&AtClient
Procedure Ship(Command)
	
	ProvidingSetActionWithQuestion("ACTION_LOAD");
	
EndProcedure

&AtClient
Procedure ToReserve_(Command)
	
	ProvidingSetActionWithQuestion("ACTION_RESERVE");
	
EndProcedure

#EndRegion

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

// StandardSubsystems.Properties
&AtClient
Procedure Attachable_PropertiesExecuteCommand(ItemOrCommand, Var_URL = Undefined, StandardProcessing = Undefined)
	PropertyManagerClient.ExecuteCommand(ThisObject, ItemOrCommand, StandardProcessing);
EndProcedure
// End StandardSubsystems.Properties

// StandardSubsystems.FilesOperations
&AtClient
Procedure Attachable_AttachedFilesPanelCommand(Command)

	FilesOperationsClient.AttachmentsControlCommand(ThisObject, Command);

EndProcedure
// End StandardSubsystems.FilesOperations

#EndRegion

#Region Private

// StandardSubsystems.Properties

&AtServer
Procedure PropertiesExecuteDeferredInitialization()
	PropertyManager.FillAdditionalAttributesInForm(ThisObject);
EndProcedure

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

&AtServer
Procedure UpdateQualityControlAttributes()

	If QualityControl.UpdateActionParameters(
			Documents.ByAssemblyDisassemblyOrder,
			Object,
			QualityControlClientServer.CacheByKey(CacheQualityControl, "Goods")) Then
			
		StructureOfActions = New Structure();
		StructureOfActions.Insert("FillInCheckQualityDateOfQualityConfirmation",
			QualityControlClientServer.CacheByKey(CacheQualityControl, "Goods"));
		BatchProcessingOfTablePartServer.TreatTS(Object.Goods, StructureOfActions);
		
	EndIf;
	
	If QualityControl.UpdateActionParameters(
			Documents.ByAssemblyDisassemblyOrder,
			Object,
			QualityControlClientServer.CacheByKey(CacheQualityControl, "Header")) Then
			
		Actions = New Structure();
		Actions.Insert("FillInCheckQualityDateOfQualityConfirmation",
			QualityControlClientServer.CacheByKey(CacheQualityControl, "Header"));
		Header = New Structure(
			"Products,
			|ToControlQuality,
			|QualityConfirmationDate");
		FillPropertyValues(Header, Object);
		BatchProcessingOfTablePartServer.ProcessTSString(Header, Actions, Undefined);
		FillPropertyValues(Object, Header);
		
	EndIf;
	SetDesignOfQualityControlFields();
	
EndProcedure

&AtServer
Procedure SetConditionalAppearance()

	ConditionalAppearance.Items.Clear();

	ProductsServer.SetConditionalAppearanceOfUnitsOfMeasurement(ThisForm);
	
	//

	TMCommonUse.SetConditionalAppearanceOfPriority(ThisObject);
	
	//

	ProductsServer.EstablishConditionalAppearanceOfProductCharacteristics(ThisForm);

	//

	ProductsServer.EstablishConditionalAppearanceOfProductSeries(ThisForm, "SeriesAlwaysWHGoods");
	ProductsServer.EstablishConditionalAppearanceOfProductSeries(ThisForm, Undefined,
		"Series", "Object.BatchesIndicationStatus", "ItemsType");
	ProductsServer.EstablishConditionalAppearanceOfProductSeries(ThisForm, "SeriesAlwaysWHGoods",
		"Series", "Object.BatchesIndicationStatus", "ItemsType");

	//

	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.NumberOfPackages.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.CountCanceled");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Greater;
	ItemFilter.RightValue = 0;
	
	Item.Appearance.SetParameterValue("MarkIncomplete", False);

	//

	ProductsServer.SetConditionalAppearanceOfProductAssignment(ThisForm);
	
	#Region Supply
	
	// Color highlighting of the canceled row of the table part
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.Goods.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.Canceled");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	Item.Appearance.SetParameterValue("TextColor", StyleColors.TextColorOfCanceledRowOfDocument);
	//
	
	ProvisionInDocumentsServer.SetConditionalAppearanceApart(
		ConditionalAppearance,
		Items.GoodsWithAssignment,
		"Object.Goods.SupplyOption",
		"Object.Goods.ItemsType");
	
	AvailableBalanceEmbeddingParametersAreOld = AvailableRemainingEmbeddingOptions;
	Operation = New Structure("BusinessOperation", Enums.BusinessTransactions.AssemblyFromComponents);
	AvailableRemainingEmbeddingOptions = Documents.ByAssemblyDisassemblyOrder.AvailableRemainingEmbeddingOptions(Operation);
	ProvisionInDocumentsServer.AvailableLeftoversAddColumnLayoutAvailable(ThisObject);
	Operation = New Structure("BusinessOperation", Enums.BusinessTransactions.DisassemblyIntoComponents);
	AvailableRemainingEmbeddingOptions = Documents.ByAssemblyDisassemblyOrder.AvailableRemainingEmbeddingOptions(Operation);
	ProvisionInDocumentsServer.AvailableLeftoversAddColumnLayoutAvailable(ThisObject);
	AvailableRemainingEmbeddingOptions = AvailableBalanceEmbeddingParametersAreOld;
	
	// The text of the forbidden cell, if the stock is redistributed in the warehouse.
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.LabelPackaging.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField(
		AvailableRemainingEmbeddingOptions.ConditionalAppearance.DataPaths.ReallocateInventory);
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.InaccessibleCellTextColor);
	
	#EndRegion
	LinesOfBusinessServer.EstablishConditionalAppearanceOfDirectionOfActivity(ThisForm);
	
	// Conditional appearance of quality control Attributes.
	Fields = QualityControl.Fields(
		Items.GoodsToControlQuality,
		Items.GoodsQualityConfirmationDate);
	FlagDisabled = New Array();
	QualityControl.AddFilter(FlagDisabled, "Object.Goods.Canceled", True);
	QualityControl.SetupAppearance(ConditionalAppearance, Fields, FlagDisabled);
	
EndProcedure

#Region Supply

&AtClient
Procedure ItemsAreCollateralOptionWhenChangedOnClient(Result, AdditionalParameters) Export
	
	WhatIsSoftwareOptionWhenChangingOnServer();
	
EndProcedure

&AtClient
Procedure SecurityOptionWhenChangingOnClient(Result, AdditionalParameters) Export
	
	SecurityOptionWhenChangedOnServer();
	
EndProcedure

&AtClient
Procedure Attachable_CheckCompletionOfInventoryAllocationTask()
	
	Error = False;
	If ProvisionInDocumentsClient.NeedToUpdateAvailabilityAfterRecording(ThisObject,
		"Attachable_CheckCompletionOfInventoryAllocationTask", Error) Then
		ProvisionInDocumentsClient.ConfigureHyperlinksSupplyForecastAfterRecording(ThisObject, Error);
		UpdateColumn = ProvisionInDocumentsClient.ToUpdateColumnAvailableAfterInventoryAllocation(ThisObject);
		If UpdateColumn Then
			UpdateColumnAvailableAfterInventoryAllocation();
		EndIf;
	EndIf;
	
EndProcedure

&AtServer
Procedure UpdateColumnAvailableAfterInventoryAllocation()
	ProvisionInDocumentsServer.UpdateAvailabilityAfterRecording(ThisObject);
EndProcedure

&AtServer
Function SoftwareSelectionParameters(Mode)
	
	FormParameters = ProvisionInDocumentsServer.SoftwareSelectionParameters(
		ThisObject,
		Items.Goods.CurrentRow,
		Mode);
	
	Return FormParameters;
	
EndFunction

&AtClient
Function ParametersOfQuantityAndSeriesRequestForm(Mode)
	
	CheckParameters = SupplyClientServer.InitializeFillVerificationParameters("Goods",
		NStr("vi = 'Thành phần chi tiết';
			|ru = 'Комплектующие';
			|en = 'Components'; fa = 'اجزا';
			|it = 'Componenti';
			|pl = 'Części';
			|tr = 'Bileşenler'"));
	
	If Not SupplyClient.CheckFilling(
				Object,
				Object.Goods,
				Items.Goods.CurrentRow,
				CheckParameters,
				Object.Warehouse,
				Mode) Then
		Return Undefined;
	EndIf;
	
	FormParameters = SoftwareSelectionParameters(Mode);
	FormParameters.SeriesSpecificationParameters = SeriesSpecificationParameters.TS;
	
	Return FormParameters;
	
EndFunction

&AtServer
Function KitSecuritySelectionParameters(Mode)
	
	FormParameters = ProvisionInDocumentsServer.SoftwareSelectionParameters(
		ThisObject,
		Undefined,
		Mode);
		
	Return FormParameters;
	
EndFunction

&AtServer
Procedure WhatIsSoftwareOptionWhenChangingOnServer()
	
	Changes = ProvisionInDocumentsServer.SupplyOptionOnChange(
		ThisObject,
		Items.Goods.CurrentRow);
		
	Mode = ProvisionInDocumentsClientServer.ModeSelectActionDirectly();
	AfterFillingOutCollateral(Changes, Mode, Undefined);
	
EndProcedure

&AtServer
Procedure SecurityOptionWhenChangedOnServer()
	
	InternalParameters = AvailableRemainingEmbeddingOptions.InternalParameters;
	SecurityOptionSelectedValue = InternalParameters.SecurityOptionSelectedValue;
	Object.SupplyOption = SecurityOptionSelectedValue.SupplyOption;
	
	AfterFillingOutSecurityKit();
	
EndProcedure

&AtServer
Function FillInCollateralFromCollateralStateForm(ActionCode, AddressAnalyst, FillParameters)
	
	Modified = True;
	Changes = ProvisionInDocumentsServer.FillInCollateralFromCollateralStateForm(
		ActionCode,
		AddressAnalyst,
		ThisObject);
	
	Mode = ProvisionInDocumentsClientServer.SoftwareStateMode();
	AfterFillingOutCollateral(Changes, Mode, FillParameters);
	AddressOfTheMovementTable = AddressOfMovementTableInRepository();
	Return AddressOfTheMovementTable;
	
EndFunction

&AtServer
Function AddressOfMovementTableInRepository()
	
	Return ProvisionInDocumentsServer.AddressOfMovementTableInRepository(ThisObject);
	
EndFunction

&AtClientAtServerNoContext
Function DocumentParametersForSoftwareActions(Form, DateOfShipment)
	
	DocumentParameters = New Structure();
	DocumentParameters.Insert("Form",                              Form);
	DocumentParameters.Insert("Collection",                          Form.Object.Goods);
	DocumentParameters.Insert("SecurityOptionAndFlagSeparately", Undefined);
	
	Return DocumentParameters;
	
EndFunction

&AtClient
Procedure HyperlinkStateOfProvisionClickGeneral()
	
	FormParameters = ProvisionInDocumentsClient.SecurityStatusHyperlinkClick(ThisObject);
	
	If FormParameters.ContextOfUse = "TABLE" Then
		
		FormParameters.AddressOfTheMovementTable = AddressOfMovementTableInRepository();
		
	EndIf;
	
	OpenForm("DataProcessor.OrderSupplyForecast.Form", FormParameters, ThisObject, UUID,,,,
		FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure AddCollateralActionsOnClient(StructureOfActions, StringFields_)
	
	If ThisIsAssemblyFromComponents Then
		DocumentParameters = DocumentParametersForSoftwareActions(ThisObject, Undefined);
		ProvisionInDocumentsClientServer.AddCollateralActions(StructureOfActions, StringFields_, DocumentParameters);
	EndIf;
	
EndProcedure

&AtServer
Procedure AddCollateralActionsOnServer(StructureOfActions, Val StringFields_, DateOfShipment = Undefined)
	
	If ThisIsAssemblyFromComponents Then
		DocumentParameters = DocumentParametersForSoftwareActions(ThisObject, DateOfShipment);
		ProvisionInDocumentsClientServer.AddCollateralActions(StructureOfActions, StringFields_, DocumentParameters);
	EndIf;
	
EndProcedure

&AtClient
Procedure AddKitAssuranceActionsOnClient(StructureOfActions, StringFields_)
	
	DocumentParameters = DocumentParametersForSoftwareActions(ThisObject, Undefined);
	ProvisionInDocumentsClientServer.AddCollateralActions(StructureOfActions, StringFields_, DocumentParameters);
	
EndProcedure

&AtServer
Procedure AddKitAssuranceActionsOnServer(StructureOfActions, Val StringFields_, DateOfShipment = Undefined)
	
	DocumentParameters = DocumentParametersForSoftwareActions(ThisObject, DateOfShipment);
	ProvisionInDocumentsClientServer.AddCollateralActions(StructureOfActions, StringFields_, DocumentParameters);
	If StructureOfActions.Property("FillInAvailableColumn") Then
		StructureOfActions.FillInAvailableColumn.Insert("IDOfRowReceived", Undefined);
	EndIf;
	
EndProcedure

&AtServer
Function ProvidingSetAction(ActionCode)
	
	Result = ProvisionInDocumentsServer.ProvidingSetActionResultStructure();
	
	If ActionCode = "FLAG_UNITED" Or ActionCode = "FLAG_NOTABLE" Then
		
		Changes = ProvisionInDocumentsServer.SetActionApart(
			ActionCode,
			ThisObject,
			Items.Goods.SelectedRows);
			
		UpdateColumnAvailableServer();
		
	Else
		
		Changes = ProvisionInDocumentsServer.SetAction(
			ActionCode,
			ThisObject,
			Items.Goods.SelectedRows);
		
		FillPropertyValues(Result, Changes);
		
		If Changes.ChangesTable <> Undefined Then
			AfterFillingOutCollateral(
				Changes.ChangesTable,
				ProvisionInDocumentsClientServer.ActionSelectionMode(),
				Result);
		EndIf;
		
	EndIf;
	
	Return Result;
	
EndFunction

&AtClient
Procedure ProvidingSetActionWithQuestion(ActionCode)
	
	Result = ProvidingSetAction(ActionCode);
	
	ProvisionInDocumentsClient.ShowIssueOfFillingSoftwareWithWholePackages(
		ThisObject,
		Object.Goods,
		Result,
		"AfterQuestionOfFillingPackageWithWholePackages");
	
EndProcedure

&AtClient
Procedure AfterQuestionOfFillingPackageWithWholePackages(Response, Result) Export
	
	EnsuringToSetActionAfterQuestion(Response, Result);
	
EndProcedure

&AtServer
Procedure EnsuringToSetActionAfterQuestion(Response, Result)
	
	ResultStructure1 = ProvisionInDocumentsServer.SetActionAfterQuestion(Response, Result, ThisObject);
	AfterFillingOutCollateral(
		ResultStructure1.ChangesTable,
		ProvisionInDocumentsClientServer.ActionSelectionMode(),
		ResultStructure1);
	
EndProcedure

&AtClient
Procedure Attachable_WhenChangingModifiabilityOfForm()
	
	If Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.AssemblyFromComponents") Then
		
		If FormModified <> Modified Then
			
			FormModified = Modified;
			ProvisionInDocumentsClient.ConfigureHyperlinkedSoftwareState(ThisObject);
			
		EndIf;
		
	EndIf;
	
EndProcedure

&AtServer
Procedure AfterFillingOutCollateral(Changes, Mode = Undefined, FillParameters = Undefined)
	
	Documents.ByAssemblyDisassemblyOrder.AfterFillingOutCollateral(Object, Changes, Mode, FillParameters);
	
	StructureOfActions = New Structure();
	CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	
	CollectionOnForm = ProvisionInDocumentsClientServer.CollectionOnForm(
		ThisObject, AvailableRemainingEmbeddingOptions);
	
	RowsToProcess = New Array();
	
	For Each Update In Changes Do
		RowsToProcess.Add(Update.String);
	EndDo;
	
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		RowsToProcess,
		StructureOfActions,
		CollectionOnForm,
		CachedValues);
	
	UpdateColumnAvailableServer();
	
EndProcedure

&AtServer
Procedure UpdateColumnAvailableServer()
	
	ProvisionInDocumentsServer.UpdateColumnAvailable(ThisObject);
	
EndProcedure

&AtServer
Procedure AfterFillingOutSecurityKit(Mode = Undefined)
	
	Documents.ByAssemblyDisassemblyOrder.AfterFillingOutCollateral(Object, Undefined, Mode, Undefined);
	UpdateColumnAvailableServer();
	SetElementLayoutSeparately();
	SetElementDesignAvailable();
	SetSeriesAvailabilityInHeader();
	
EndProcedure

&AtClient
Function ParametersOfKitQuantityAndSeriesRequestForm(Mode)
	
	UserErrors = Undefined;
	HasErrors = False;
	If Object.Count = 0 Then
		Field  = "Object.NumberOfPackages";
		Text = NStr("vi = 'Chưa điền trường ""Số lượng""';
					|ru = 'Поле ""Количество"" не заполнено';
					|en = '""Quantity"" is not filled in'; fa = '""Quantity"" is not filled in';
					|it = 'Il campo ""Quantità"" non è compilato';
					|pl = 'Nie wypełniono pole ""Количество""';
					|tr = '""Miktar"" alanı doldurulmadı'");
		CommonClientServer.AddUserError(UserErrors, Field, Text, "");
		HasErrors = True;
	EndIf;
	
	If Not ValueIsFilled(Object.Products) Then
		Field  = "Object.Products";
		Text = NStr("vi = 'Chưa điền trường ""Mặt hàng""';
					|ru = 'Поле ""Номенклатура"" не заполнено';
					|en = '""Product"" is not filled in'; fa = '""Product"" is not filled in';
					|it = 'Il campo ""Articolo"" non è compilato';
					|pl = 'Nie wypełniono pola ""Номенклатура""';
					|tr = '""Ürün gamı"" alanı doldurulmadı'");
		CommonClientServer.AddUserError(UserErrors, Field, Text, "");
		HasErrors = True;
	EndIf;
	
	If Not ValueIsFilled(Object.Characteristic) And ItemVariantsAreUsed Then
		Field  = "Object.Characteristic";
		Text = NStr("vi = 'Chưa điền trường ""Đặc tính""';
					|ru = 'Поле ""Характеристика"" не заполнено';
					|en = '""Variant"" is not filled in'; fa = '""Variant"" is not filled in';
					|it = 'Il campo ""Caratteristica"" non è compilato';
					|pl = 'Pole ""Charakterystyka"" nie jest wypełnione';
					|tr = '""Özellik"" alanı doldurulmadı'");
		CommonClientServer.AddUserError(UserErrors, Field, Text, "");
		HasErrors = True;
	EndIf;
	
	If Not ValueIsFilled(Object.Warehouse) Then
		Field  = "Object.Warehouse";
		Text = NStr("vi = 'Chưa điền trường ""Kho bãi""';
					|ru = 'Поле ""Склад"" не заполнено';
					|en = '""Warehouse"" is required'; fa = '""Warehouse"" is required';
					|it = 'Il campo ""Magazzino"" non è compilato';
					|pl = 'Nie wypełniono pola ""Magazyn""';
					|tr = '""Ambar"" alanı doldurulmadı'");
		CommonClientServer.AddUserError(UserErrors, Field, Text, "");
		HasErrors = True;
	EndIf;
	
	If HasErrors Then
		ClearMessages();
		CommonClientServer.ReportErrorsToUser(UserErrors);
		Return Undefined;
	Else
		FormParameters = KitSecuritySelectionParameters(Mode);
	EndIf;
	
	If Object.BatchesIndicationStatus = 10
		Or Object.BatchesIndicationStatus = 9
		Or Object.BatchesIndicationStatus = 11 Then
		
		SetOfSeries = New Array;
		For Each RowSeries In Object.SetOfSeries Do
			If RowSeries.Products = FormParameters.Products
				And RowSeries.Characteristic = FormParameters.Characteristic Then
					Series = New Structure("Series, Count", RowSeries.Series, RowSeries.Count);
					SetOfSeries.Add(Series);
			EndIf;
		EndDo;
		FormParameters.Series = SetOfSeries;
		
	EndIf;
	
	FormParameters.SeriesSpecificationParameters = SeriesSpecificationParameters.Header;
	FormParameters.ItIsForbiddenToSplitStrings = True;
	
	Return FormParameters;
	
EndFunction

&AtClient
Procedure ProcessWarehouseAndBatchSelection(ValueSelected, FormParameters) Export
	
	If Not ProvisionInDocumentsClient.ThereAreSelectedProducts(ValueSelected) Then
		Return;
	EndIf;
	
	Notification = ProcessWarehouseAndBatchSelectionOnServer(ValueSelected, FormParameters);
	NotificationText1 = ProvisionInDocumentsClient.TextProcessingAlertsWarehouseAndBatchSelection(FormParameters.Mode);
	ShowUserNotification(NotificationText1, , Notification);
	
EndProcedure

&AtClient
Procedure ProcessSelectionOfWarehouseAndKitSeries(ValueSelected, FormParameters) Export 
	
	If Not ProvisionInDocumentsClient.ThereAreSelectedProducts(ValueSelected) Then
		Return;
	EndIf;
	
	Notification = ProcessWarehouseAndBatchSelectionOnKitServer(ValueSelected, FormParameters);
	NotificationText1 = ProvisionInDocumentsClient.TextProcessingAlertsWarehouseAndBatchSelection(FormParameters.Mode);
	ShowUserNotification(NotificationText1, , Notification);
	
EndProcedure

&AtServer
Function ProcessWarehouseAndBatchSelectionOnServer(ValueSelected, FormParameters)
	
	Modified = True;
	Changes = ProvisionInDocumentsServer.WhenChoosingWarehouse(
		ValueSelected,
		ThisObject,
		Items.Goods.CurrentRow,
		FormParameters.FieldsToFillIn);
		
	AfterFillingOutCollateral(Changes, FormParameters.Mode);
	TextProcessedLines = ProvisionInDocumentsServer.TextProcessedLines(Changes.Count());
	Return TextProcessedLines;
	
EndFunction

&AtServer
Function ProcessWarehouseAndBatchSelectionOnKitServer(ValueSelected, FormParameters)
	
	Modified = True;
	If Documents.ByAssemblyDisassemblyOrder.SeriesAreIndicatedInSeparateTabularPart(Object) Then
		
		FilterParameters = New Structure("Products, Characteristic", Object.Products, Object.Characteristic);
		FoundRows = Object.SetOfSeries.FindRows(FilterParameters);
		For Each FoundRow In FoundRows Do
			Object.SetOfSeries.Delete(FoundRow);
		EndDo;
		
		Object.Count = 0;
		For Each String In ValueSelected.SelectedGoods Do
			
			Object.Count = Object.Count + String.Count;
			
			If (String.SupplyOption = Enums.SupplyOptions.Ship
						Or String.SupplyOption = Enums.SupplyOptions.FromWarehouse)
					And ValueIsFilled(String.Series) Then
					
						RowSeries = Object.SetOfSeries.Add();
						RowSeries.Products   = Object.Products;
						RowSeries.Characteristic = Object.Characteristic;
						RowSeries.Series          = String.Series;
						RowSeries.Count     = String.Count;
						
						If String.WithAssignment Then
							RowSeries.Purpose = Object.Purpose;
						Else
							RowSeries.Purpose = Catalogs.Assignments.EmptyRef();
						EndIf;
					
			EndIf;
		
		EndDo;
		
	Else
		
		Object.Count = ValueSelected.SelectedGoods[0].Count;
		Object.Series = ValueSelected.SelectedGoods[0].Series;
		
	EndIf;
	
	Object.SupplyOption = ValueSelected.SelectedGoods[0].SupplyOption;
	
	AfterFillingOutSecurityKit(FormParameters.Mode);
	
EndFunction

&AtServer
Procedure PerformKitAssuranceActionsOnServer(Fields)
	
	If Object.BusinessOperation = Enums.BusinessTransactions.DisassemblyIntoComponents Then
		
		Actions = New Structure();
		AddKitAssuranceActionsOnServer(Actions, Fields);
		
		ObjectFields = "Count,Products,Characteristic,SupplyOption,WithAssignment,Department,
			|Warehouse,Purpose,Status,AssemblyDisassemblyStart,BusinessOperation,NumberOfPackages,Package,Series,Date,Priority";
		ObjectFieldsAndLink = ObjectFields + ",Ref";
		FormFields   = "Available,ReallocateInventory,ShipIfAvailable,ReallocateInventory";
		FieldsOfFiction  = "LineNumber";
		Header = New Structure(ObjectFieldsAndLink + "," + FormFields + "," + FieldsOfFiction);
		Header.Insert("ItemsType", ItemsType);
		FillPropertyValues(Header, Object, ObjectFieldsAndLink);
		FillPropertyValues(Header, ThisObject, FormFields);
		BatchProcessingOfTablePartServer.ProcessTSString(Header, Actions, Undefined);
		FillPropertyValues(Object, Header, ObjectFields);
		FillPropertyValues(ThisObject, Header, FormFields);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure PerformKitAssuranceActionsOnClient(Fields)
	
	If Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.DisassemblyIntoComponents") Then
		
		Actions = New Structure();
		AddKitAssuranceActionsOnClient(Actions, Fields);
		
		ObjectFields = "Count,Products,Characteristic,SupplyOption,WithAssignment,Department,
			|Warehouse,Purpose,Status,AssemblyDisassemblyStart,BusinessOperation,NumberOfPackages,Package,Series,Date,Priority";
		ObjectFieldsAndLink = ObjectFields + ",Ref";
		FormFields   = "Available,ReallocateInventory,ShipIfAvailable,ReallocateInventory";
		FieldsOfFiction  = "LineNumber";
		Header = New Structure(ObjectFieldsAndLink + "," + FormFields + "," + FieldsOfFiction);
		Header.Insert("ItemsType", ItemsType);
		FillPropertyValues(Header, Object, ObjectFieldsAndLink);
		FillPropertyValues(Header, ThisObject, FormFields);
		BatchProcessingOfTablePartClient.ProcessTSString(Header, Actions, Undefined);
		FillPropertyValues(Object, Header, ObjectFields);
		FillPropertyValues(ThisObject, Header, FormFields);
		
	EndIf;
	
EndProcedure

#EndRegion

#Region OnChangeAttributes

&AtServer
Procedure ToControlQualityOnChangeServer()
	
	SetDesignOfQualityControlFields();
	
EndProcedure

&AtServer
Procedure SetDesignOfQualityControlFields()
	
	ThisIsBuild = (Object.BusinessOperation = Enums.BusinessTransactions.AssemblyFromComponents);
	Items.GoodsToControlQuality.Visible = Not ThisIsBuild;
	Items.GoodsQualityConfirmationDate.Visible = Not ThisIsBuild;
	Items.GoodsGroupCheckQualityBefore.Visible = Not ThisIsBuild;
	Items.ToControlQuality.Visible = ThisIsBuild;
	Items.QualityConfirmationDate.Visible = ThisIsBuild;
	Items.GroupCheckQualityBefore.Visible = ThisIsBuild;
	Items.QualityConfirmationDate.Enabled = Object.ToControlQuality;
	Items.QualityConfirmationDate.AutoMarkIncomplete = Object.ToControlQuality;
	
EndProcedure

&AtServer
Procedure WarehouseOnChangeServer(DirectModificationOfWarehouseField = False)
	
	UpdateQualityControlAttributes();
	ProvisionInDocumentsServer.WhenChangingDocumentDetails(ThisObject);
	PrepareFillSetSeriesVisibility();
	UpdateAssemblyForActivity();
	
EndProcedure

&AtServer
Procedure BusinessOperationOnChangeServer()
	
	ThisIsAssemblyFromComponents = Object.BusinessOperation = Enums.BusinessTransactions.AssemblyFromComponents;
	AvailableRemainingEmbeddingOptions = Undefined;
	EmbeddingParameters = Documents.ByAssemblyDisassemblyOrder.AvailableRemainingEmbeddingOptions(Object);
	ProvisionInDocumentsServer.AvailableBalancesWhenCreatedOnServer(ThisObject, EmbeddingParameters);
	
	SetPropertiesOfElementsOfFormBusinessOperation();
	Object.Purpose = Undefined;
	Object.LineOfBusiness = Catalogs.LinesOfBusiness.EmptyRef();
	LineOfBusinessOnChangeServer();
	
	SeriesSpecificationParameters = New FixedStructure(ProductsServer.SeriesSpecificationParameters(Object, Documents.ByAssemblyDisassemblyOrder));
	ProductsServer.FillInStatusesForSpecifyingSeries(Object,SeriesSpecificationParameters.TS);
	ProductsServer.FillInStatusesForSpecifyingSeries(Object,SeriesSpecificationParameters.Header);
	CustomizeSeriesItems();
	
	If ThisIsAssemblyFromComponents Then
		
		StructureOfActions = New Structure();
		AddCollateralActionsOnServer(StructureOfActions, "SupplyOption");
		CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
		TableRows = Object.Goods.FindRows(
			New Structure("SupplyOption", Enums.SupplyOptions.EmptyRef()));
		BatchProcessingOfTablePartServer.ProcessTSStrings(
			TableRows,
			StructureOfActions,
			Object.Goods,
			CachedValues);
		
	EndIf;
	
	UpdateQualityControlAttributes();
	
EndProcedure

&AtServer
Procedure ProductsOnChangeServer(ValuesCache)
	
	ItemsType = Common.ObjectAttributeValue(Object.Products, "ItemsType");
	
	Actions = New Structure("
		|CheckCharacteristicsByOwner, RecalculateNumberOfUnits, CheckCompleteConfigurationOptionByOwner,
		|CheckFillPackageByOwner");
	
	Actions.Insert("FillInCheckQualityDateOfQualityConfirmation",
		QualityControlClientServer.CacheByKey(CacheQualityControl, "Header"));
	
	LinesOfBusinessClientServer.StructureOfInsertActionsWhenAddingRow(ThisForm, Actions);
	
	Actions.CheckCharacteristicsByOwner = Object.Characteristic;
	Actions.CheckCompleteConfigurationOptionByOwner = Object.ProductKit;
	Actions.CheckFillPackageByOwner = Object.Package;
	Header = New Structure(
		"Products,
		|Characteristic,
		|Purpose,
		|ProductKit,
		|SupplyOption,
		|Package,
		|ItemsType,
		|Count,
		|NumberOfPackages,
		|ItemVariantsAreUsed,
		|ToControlQuality,
		|QualityConfirmationDate");
	FillPropertyValues(Header, Object);
	Header.ItemVariantsAreUsed = ItemVariantsAreUsed;
	
	BatchProcessingOfTablePartServer.ProcessTSString(Header, Actions, ValuesCache);
	
	FillPropertyValues(Object, Header);
	If Object.BusinessOperation = Enums.BusinessTransactions.DisassemblyIntoComponents Then
		PerformKitAssuranceActionsOnServer("SupplyOption,Available");
	EndIf;
	
	ConfigurationOptionWhenChangingOnServer();
	
	ItemVariantsAreUsed = Header.ItemVariantsAreUsed;
	Items.Characteristic.Enabled = ItemVariantsAreUsed;
	
	Catalogs.PackagesAndUnitsOfMeasure.DisplayInformationAboutStorageUnit(Object.Products, Items.Package);
	LabelPackaging = ?(ValueIsFilled(Object.Package), Object.Package, Items.Package.InputHint);
	
	SetDestinationAvailabilityInHeader();
	
	If SeriesSpecificationParameters.Header.UseItemsBatch Then
		FillInStatusesOfSpecifyingSeriesWhenChangingProductInHeader(ValuesCache);
	EndIf;
	SetElementLayoutSeparately();
	SetElementDesignAvailable();
	SetDesignOfQualityControlFields();
	
EndProcedure

&AtServer
Procedure CharacteristicOnChangeServer()
	
	ConfigurationOptionWhenChangingOnServer();
	
EndProcedure

&AtServer
Procedure PurposeOnChangeServer()
	
	ProvisionInDocumentsServer.WhenChangingDocumentDetails(ThisObject);
	
EndProcedure

&AtServer
Procedure AssemblyDisassemblyStartOnChangeServer()
	
	If ValueIsFilled(Object.AssemblyDisassemblyStart) Then
		
		Object.AssemblyDisassemblyEnd = Object.AssemblyDisassemblyStart + Object.AssemblyDisassemblyDurationDays * 86400;
		
	Else
		
		Object.AssemblyDisassemblyEnd = '00010101';
		
	EndIf;
	
	UpdateQualityControlAttributes();
	
EndProcedure

&AtServer
Procedure AssemblyDisassemblyEndOnChangeServer()
	
	If ValueIsFilled(Object.AssemblyDisassemblyEnd) Then
		
		Object.AssemblyDisassemblyStart = Object.AssemblyDisassemblyEnd - Object.AssemblyDisassemblyDurationDays * 86400;
		
	Else
		
		Object.AssemblyDisassemblyStart = '00010101';
		
	EndIf;
	
	UpdateQualityControlAttributes();
	
EndProcedure

#EndRegion

#Region SelectionAndProcessingOfQuantityVerification

&AtClient
Procedure HandlingSelectionSelectionOnClient(ValueSelected)
	
	If Not ValueIsFilled(ValueSelected) Then
		Return;
	EndIf;
	
	ProcessingSelectionOfSelectionOnServer(ValueSelected);
	
EndProcedure

&AtServer
Procedure ProcessingSelectionOfSelectionOnServer(ValueSelected)

	TableOfGoods = GetFromTempStorage(ValueSelected.GoodsAddressInStorage);

	If TableOfGoods.Count() > 0 Then
		Changes = New Array(TableOfGoods.Count());
	Else
		Changes = New Array();
	EndIf;
	For IndexOf = 0 To TableOfGoods.Count() - 1 Do
		
		RowOfProduct = TableOfGoods[IndexOf];
		
		CurrentRow = Object.Goods.Add();
		Changes[IndexOf] = CurrentRow;
		
		FillPropertyValues(CurrentRow, RowOfProduct,
			"Products,Characteristic,ItemVariantsAreUsed,Package,NumberOfPackages,SupplyOption,
			|WithAssignment,Series");
		
	EndDo;
	StructureOfActions = New Structure();
	AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions);
	StructureOfActions.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
	StructureOfActions.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));
	StructureOfActions.Insert("FillInCheckQualityDateOfQualityConfirmation",
		QualityControlClientServer.CacheByKey(CacheQualityControl, "Goods"));
	AssignmentsClientServer.StructureOfInsertActionsWhenAddingRow(ThisObject, StructureOfActions, True);
	AddCollateralActionsOnServer(StructureOfActions, "SupplyOption");
	
	CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		Changes,
		StructureOfActions,
		Object.Goods,
		CachedValues);
	
	Documents.ByAssemblyDisassemblyOrder.FillInBeginningEndOfBuildDuringInstallationShipOrReserve(Object, Changes);
	
	ProductsServer.FillInStatusesForSpecifyingSeries(Object,SeriesSpecificationParameters.TS);
	UpdateColumnAvailableServer();
	
EndProcedure

&AtClientAtServerNoContext
Procedure AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions)
	
	StructureOfActions.Insert("RecalculateNumberOfUnits");
	
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
	StructureOfActionsWithAddedStrings.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
	StructureOfActionsWithAddedStrings.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));
	StructureOfActionsWithAddedStrings.Insert("FillInCheckQualityDateOfQualityConfirmation",
		QualityControlClientServer.CacheByKey(CacheQualityControl, "Goods"));
	LinesOfBusinessClientServer.StructureOfInsertActionsWhenAddingRow(ThisObject, StructureOfActionsWithAddedStrings);
	AddActionsToStructureWhenChangingPackagesNumber(StructureOfActionsWithAddedStrings);
	
	StructureOfActionsWithModifiedStrings = New Structure;
	AddActionsToStructureWhenChangingPackagesNumber(StructureOfActionsWithModifiedStrings);	
	
	StructureOfActions = BarcodingOfItemsClient.BarcodeProcessingParameters();
	StructureOfActions.Barcodes                              = BarcodeData_5;
	StructureOfActions.StructureOfActionsWithAddedStrings = StructureOfActionsWithAddedStrings;
	StructureOfActions.StructureOfActionsWithModifiedStrings  = StructureOfActionsWithModifiedStrings;
	StructureOfActions.SeriesSpecificationParameters                 = SeriesSpecificationParameters.TS;
	StructureOfActions.GoodsOnly                           = True;
	StructureOfActions.AddContainers                         = False;
	
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
	
	AddCollateralActionsOnServer(
		StructureOfActionParameters.StructureOfActionsWithAddedStrings,
		"SupplyOption");
	
	BarcodingOfItemsServer.ProcessBarcodes(ThisObject, Object, StructureOfActionParameters, CachedValues);
	
	ProvisionInDocumentsClientServer.RemoveCollateralActions(StructureOfActionParameters.StructureOfActionsWithAddedStrings);
	UpdateColumnAvailableServer();
	
EndProcedure

#EndRegion

#Region SetOfSeries

&AtServer
Procedure CustomizeSeriesItems()
	
	Items.GoodsSeries.Visible = SeriesSpecificationParameters.TS.UseItemsBatch;
	
	Items.SpecifySeriesInHeader.Visible  = SeriesSpecificationParameters.Header.UseItemsBatch;
	Items.BatchesIndicationStatus.Visible = SeriesSpecificationParameters.Header.UseItemsBatch;
	Items.Series.Visible               = SeriesSpecificationParameters.Header.UseItemsBatch;
	
	SetSeriesAvailabilityInHeader();
	
EndProcedure

&AtServer
Procedure SetSeriesAvailabilityInHeader()
	If Object.BatchesIndicationStatus > 12 Then
		Items.Series.Enabled = True;
	Else
		Items.Series.Enabled = False;
	EndIf;
	Items.SpecifySeriesInHeader.Enabled =
		  Object.BatchesIndicationStatus > 0
		And Object.BatchesIndicationStatus < 13;
EndProcedure

&AtServer
Procedure ProcessSeriesIndication_Server(ParametersOfSeriesIndicationForm, ProductInHeader)
	
	If ProductInHeader Then
		
		ProductsServer.ProcessSeriesIndication_(Object,SeriesSpecificationParameters.Header,ParametersOfSeriesIndicationForm);
		
	Else
		
		Actions = New Structure();
		Actions.Insert("FillInCheckQualityDateOfQualityConfirmation",
			QualityControlClientServer.CacheByKey(CacheQualityControl, "Goods"));
		ProductsServer.ProcessSeriesIndication_(Object,SeriesSpecificationParameters.TS,ParametersOfSeriesIndicationForm, Actions);
		
	EndIf;
	
EndProcedure

&AtServer
Procedure FillInStatusesOfSpecifyingSeriesWhenChangingProductInHeader(CachedValues)
	
	ProductsServer.FillInStatusesOfSpecifyingSeriesWhenChangingProductInHeader(Object, 
				SeriesSpecificationParameters.Header, CachedValues);
	SetSeriesAvailabilityInHeader();
				
EndProcedure

&AtServer
Procedure PrepareFillSetSeriesVisibility()
	
	SeriesSpecificationParameters = New FixedStructure(ProductsServer.SeriesSpecificationParameters(Object, Documents.ByAssemblyDisassemblyOrder));
	ProductsServer.FillInStatusesForSpecifyingSeries(Object,SeriesSpecificationParameters.TS);
	ProductsServer.FillInStatusesForSpecifyingSeries(Object,SeriesSpecificationParameters.Header);
	CustomizeSeriesItems();
	
EndProcedure

&AtClient
Procedure OpenSeriesSelectionWhenScanningProductBarCode()
	If CurDataId = Undefined Then
		Return;
	EndIf;
	
	CurrentData = Object.Goods.FindByID(CurDataId);
	OpenSelectionOfSeries(, CurrentData);
EndProcedure

&AtClient
Procedure OpenSelectionOfSeries(Text = "", CurrentData = Undefined)
	
	FormParameters = ParametersOfQuantityAndSeriesRequestForm(ProvisionInDocumentsClientServer.SeriesSelectionMode());
	
	If FormParameters <> Undefined Then
		
		OpenForm(
			"DataProcessor.QuantityAndBatchRequest.Form",
			FormParameters,
			ThisObject,
			,
			,
			,
			New CallbackDescription("ProcessWarehouseAndBatchSelection", ThisObject, FormParameters));
			
	EndIf;
	
EndProcedure

&AtClient
Procedure OpenSelectionOfSeriesCompletion(Result, AdditionalParameters) Export
    
    ParametersOfSeriesIndicationForm = AdditionalParameters.ParametersOfSeriesIndicationForm;
    ProductInHeader = AdditionalParameters.ProductInHeader;
    
    
    ReturnValue_1 = Result;
    
    If ReturnValue_1 <> Undefined Then
        ProcessSeriesIndication_Server(ParametersOfSeriesIndicationForm, ProductInHeader);
    EndIf;
    If ProductInHeader Then
        ProductsClient.UpdateCachedHeaderValuesToAccountForSeries(Object,CachedValues,SeriesSpecificationParameters.Header);	
    EndIf;

EndProcedure

&AtClient
Procedure OpenSelectionOfKitSeries(Text = "")
	
	FormParameters = ParametersOfKitQuantityAndSeriesRequestForm(ProvisionInDocumentsClientServer.SeriesSelectionMode());
	
	If FormParameters <> Undefined Then
		
		OpenForm(
			"DataProcessor.QuantityAndBatchRequest.Form",
			FormParameters,
			ThisObject,
			,
			,
			,
			New CallbackDescription("ProcessSelectionOfWarehouseAndKitSeries", ThisObject, FormParameters));
			
	EndIf;
	
EndProcedure

#EndRegion

#Region WorkingWithClipboard

&AtServer
Procedure CopyLinesOnServer()
	
	ProcessingOfTabularForms.CopyRowsToClipboard(Object.Goods, Items.Goods.SelectedRows);
	
EndProcedure

&AtServer
Procedure GetLinesFromClipboard()
	
	FilterParameters = New Map;
	FilterParameters.Insert("Products.ItemsType", ProductsClientServer.SelectionByProductMultiTurnContainer(False));
	
	Columns = "Products,Characteristic,Package,NumberOfPackages";
	
	TableOfGoods = ProcessingOfTabularForms.RowsFromClipboard(FilterParameters, Columns);
	
	If Not ValueIsFilled(TableOfGoods) Then
		Return;
	EndIf;
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInCheckQualityDateOfQualityConfirmation",
		QualityControlClientServer.CacheByKey(CacheQualityControl, "Goods"));
	AddCollateralActionsOnServer(StructureOfActions, "SupplyOption");
	AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions);
	LinesOfBusinessClientServer.StructureOfInsertActionsWhenAddingRow(ThisForm, StructureOfActions);
	CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	RowsToProcess = New Array();
	
	For Each RowOfProduct In TableOfGoods Do

		CurrentRow = Object.Goods.Add();
		FillPropertyValues(CurrentRow, RowOfProduct);
		RowsToProcess.Add(CurrentRow);
		
	EndDo;
	
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		RowsToProcess,
		StructureOfActions,
		Object.Goods,
		CachedValues);
	
	FillInServiceDetailsForProductRange();
	ProductsServer.FillInStatusesForSpecifyingSeries(Object,SeriesSpecificationParameters.TS);
	UpdateColumnAvailableServer();

EndProcedure

&AtServer
Procedure SetAvailabilityOfClipboardCommands()
	
	ItemArray = New Array();
	ItemArray.Add("GoodsInsertRows");
	ItemArray.Add("GoodsContextMenuInsertRows");
	
	TMCommonUseClientServer.SetPropertyOfFormElements(Items, ItemArray, "Enabled",
		ProcessingOfTabularForms.ThereAreLinesInClipboard());
	
EndProcedure

&AtClient
Procedure SetAvailabilityOfClipboardCommandsOnClient()
	
	ItemArray = New Array();
	ItemArray.Add("GoodsInsertRows");
	ItemArray.Add("GoodsContextMenuInsertRows");
	
	TMCommonUseClientServer.SetPropertyOfFormElements(Items, ItemArray, "Enabled", True);
	
EndProcedure

#EndRegion

#Region Other

&AtServer
Procedure LineOfBusinessOnChangeServer()
	
	If Object.BusinessOperation = Enums.BusinessTransactions.AssemblyFromComponents Then
		
		If ValueIsFilled(Object.LineOfBusiness) Then
			Object.Purpose = Catalogs.Assignments.EmptyRef();
		EndIf;
		
		DestinationPattern = Documents.ByAssemblyDisassemblyOrder.DestinationPattern(Object);
		If ValueIsFilled(Object.Ref) Or DestinationPattern.OrderDocument = Undefined Then
			Object.AssignmentGoods = Catalogs.Assignments.FindByTemplate(DestinationPattern);
		Else
			Object.AssignmentGoods = Undefined;
		EndIf;
		
	Else
		
		LinesOfBusinessServer.WhenChangingDirectionOfActivity(ThisObject);
		
	EndIf;
	
	Object.AssignByOrderAssignment = Constants.OptionOfGoodsAssignmentInAssembly.Get()
		<> Enums.OptionsOfGoodsAssignmentInAssembly.AssignmentOfAssembledKit;
	
	ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters.TS);
	ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters.Header);
	
	UpdateAssemblyForActivity();
	ProvisionInDocumentsServer.WhenChangingDocumentDetails(ThisObject);
	
EndProcedure

&AtServer
Procedure SetGroupVisibilityAdditionally()
	
	Items.AdvancedGroup.Visible =
		GetFunctionalOption("EmployeeInChargeInDocuments")
		Or GetFunctionalOption("UseBusinessUnits")
		Or GetFunctionalOption("UseSalesOpportunitiesToCustomer");

EndProcedure

&AtServer
Procedure SetDestinationAvailabilityInHeader()
	
	TypeOfNomeclature = Common.ObjectAttributeValue(Object.Products,"ItemsType");
	If TypeOfNomeclature = Enums.ItemsTypes.OwnGoods Then
		Items.Purpose.Enabled = True;
		Items.Purpose.InputHint =  NStr("vi = '<không mục đích>';
										|ru = '<без назначения>';
										|en = '<without assignment>'; fa = '<بدون تخصیص>';
										|it = '<senza assegnazione>';
										|pl = '<bez przeznaczenia>';
										|tr = '<atama olmadan>'");
	Else
		Items.Purpose.Enabled = False;
		Items.Purpose.InputHint =  NStr("vi = '<cho hàng hóa>';
										|ru = '<для товаров>';
										|en = '<for goods>'; fa = '<for goods>';
										|it = '<per le merci>';
										|pl = '<dla towarów>';
										|tr = '<ürünler için>'");
	EndIf;
	
EndProcedure

&AtServer
Procedure OnReadCreateAtServer()
	
	If Not AccessRight("Insert", Metadata.Documents.InventoryAssignmentAdjustment)
		Or Not GetFunctionalOption("UseOrderSupplyWithAssignment") Then
		Items.GoodsCreateAssignmentAdjustmentRemoveFromReserve.Visible = False;
		Items.GoodsCreateAnAssignmentAdjustmentReservation.Visible = False;
	EndIf;
	
	SeriesSpecificationParameters = New FixedStructure(ProductsServer.SeriesSpecificationParameters(Object, Documents.ByAssemblyDisassemblyOrder));
	
	ItemsType = Common.ObjectAttributeValue(Object.Products, "ItemsType");
	FillInServiceDetailsForProductRange();

	ItemVariantsAreUsed = Catalogs.Products.ItemVariantsAreUsed(Object.Products);
	Items.Characteristic.Enabled = ItemVariantsAreUsed;
	
	Catalogs.PackagesAndUnitsOfMeasure.DisplayInformationAboutStorageUnit(Object.Products, Items.Package);
	
	UpdateAssemblyForActivity(False);
	
	SetGroupVisibilityAdditionally();
	SetDestinationAvailabilityInHeader();
	
	CustomizeSeriesItems();
	Items.DocumentBasis.Visible = ValueIsFilled(Object.DocumentBasis);

	Items.SupplyOption.Enabled = Not ThereIsDisassemblyOnRequest();

	// While there are no canceled sets for the document, we do not display the corresponding field.
	Items.CancelGroup.Visible = Object.CountCanceled > 0;
	
	LinesOfBusinessServer.OnReadCreateAtServer(ThisObject);
	
	SetPropertiesOfElementsOfFormBusinessOperation();
	LabelPackaging = ?(ValueIsFilled(Object.Package), Object.Package, Items.Package.InputHint);
	ProcessingOfTabularForms.InitializeRowCache(Items.Goods);
	ThisIsAssemblyFromComponents = Object.BusinessOperation = Enums.BusinessTransactions.AssemblyFromComponents;
	CacheQualityControl = QualityControl.DataCacheOfMechanism(Object);
	
EndProcedure

&AtServer
Procedure FillInServiceDetailsForProductRange()
	
	ParametersForFillingInBankingDetails = New Structure;
	ParametersForFillingInBankingDetails.Insert("FillInFeatureAttribute",
											New Structure("Products", "ItemVariantsAreUsed"));
	ParametersForFillingInBankingDetails.Insert("FillInProductTypeAttribute_",
											New Structure("Products", "ItemsType"));
	ParametersForFillingInBankingDetails.Insert("FillInArticleAttribute",
											New Structure("Products", "SKU"));
	
	ProductsServer.FillInServiceDetailsForProductInCollection(Object.Goods,ParametersForFillingInBankingDetails);
	
EndProcedure

&AtServer
Procedure FillInProductsByConfigurationOption()

	If Object.Ref.IsEmpty() Or Not Documents.ByAssemblyDisassemblyOrder.ThereIsAssemblyOnRequest(Object.Ref) Then

		UpdateAttributeForUsingCharacteristics = True;
		Object.Goods.Load(Catalogs.ProductKitConfigurations.GetProductComponents(
								Object.ProductKit, , Object.Count));
								
	Else
		
		// Lines will not be added. Quantity update only.
		UpdateAttributeForUsingCharacteristics = False;

		Catalogs.ProductKitConfigurations.UpdateNumberOfComponentsByNumberOfSets(
			Object.Goods, Object.Count, Object.ProductKit);
	
	EndIf;

	StructureOfActions = New Structure();
	StructureOfActions.Insert("FillInCheckQualityDateOfQualityConfirmation",
		QualityControlClientServer.CacheByKey(CacheQualityControl, "Goods"));
	AddCollateralActionsOnServer(StructureOfActions, "SupplyOption");
	LinesOfBusinessClientServer.StructureOfInsertActionsWhenAddingRow(ThisForm, StructureOfActions);
	BatchProcessingOfTablePartServer.TreatTS(Object.Goods, StructureOfActions, Undefined);
		UpdateColumnAvailableServer();
	
	If UpdateAttributeForUsingCharacteristics Then
		
		FillInServiceDetailsForProductRange();
		
	EndIf;
	
	ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters.TS);
	
EndProcedure

&AtClient
Procedure NotifyAboutDocument(WriteParameters)

	NotificationParameters = New Structure;
	NotificationParameters.Insert("WriteMode",      WriteParameters.WriteMode);
	NotificationParameters.Insert("ThereIsOrder_", True);

	Notify("Write_ByAssemblyDisassemblyOrder", NotificationParameters, Object.Ref);

EndProcedure

&AtServer
Function ThereIsDisassemblyOnRequest()

	If Not ValueIsFilled(Object.Ref) Then

		Result = False;

	Else

		Query = New Query();
		Query.Text =
			"SELECT TOP 1
			|	TRUE AS ThereIsShipment
			|FROM
			|	AccumulationRegister.AssemblyOrders AS T
			|WHERE
			|	T.ByAssemblyDisassemblyOrder = &Ref
			|	AND T.AssemblyType = VALUE(Enum.InventoryMovementTypes.Shipment)
			|	AND T.RecordType = VALUE(AccumulationRecordType.Expense)
			|	AND T.ToRegister > 0";

		Query.SetParameter("Ref", Object.Ref);

		SetPrivilegedMode(True);
		Result = Not Query.Execute().IsEmpty();

	EndIf;

	Return Result;

EndFunction

&AtClient
Procedure ProductKitOnChange(Item)
	ConfigurationOptionWhenChangingOnServer();
EndProcedure

&AtServer
Procedure ConfigurationOptionWhenChangingOnServer()
	
	Object.AssemblyDisassemblyDurationDays = Common.ObjectAttributeValue(Object.ProductKit, "AssemblyDisassemblyDurationDays");
	
	If ValueIsFilled(Object.AssemblyDisassemblyStart) Then
		
		Object.AssemblyDisassemblyEnd = Object.AssemblyDisassemblyStart + Object.AssemblyDisassemblyDurationDays * 86400;
		
	ElsIf ValueIsFilled(Object.AssemblyDisassemblyEnd) Then
		
		Object.AssemblyDisassemblyStart = Object.AssemblyDisassemblyEnd - Object.AssemblyDisassemblyDurationDays * 86400;
		
	EndIf;
	StructureOfActions = New Structure();
	StructureOfActions.Insert("FillInCheckQualityDateOfQualityConfirmation",
		QualityControlClientServer.CacheByKey(CacheQualityControl, "Goods"));
	BatchProcessingOfTablePartServer.TreatTS(Object.Goods, StructureOfActions);
	
EndProcedure

&AtServer
Procedure SetPropertiesOfElementsOfFormBusinessOperation()
	
	ThisIsBuild = Object.BusinessOperation = Enums.BusinessTransactions.AssemblyFromComponents;
	
	If ThisIsBuild Then
		
		// The "Quantity" field is renamed according to the type of operation.
		Items.NumberOfPackages.Title = NStr("vi = 'Để thu thập';
											|ru = 'Собрать';
											|en = 'To assemble'; fa = 'برای جمع‌آوری';
											|it = 'Da assemblare';
											|pl = 'To assemble';
											|tr = 'Topla'");
		Commands.CancelUnprocessed.ToolTip = NStr("vi = 'Số lượng bộ chưa được lắp ráp và các thành phần không sử dụng có thể bị hủy';
													|ru = 'Отмене подлежит несобранное количество комплектов и неиспользованные комплектующие';
													|en = 'Unassembled kits and unused components must be canceled'; fa = 'کیت‌های مونتاژنشده و اجزای استفاده‌نشده باید لغو شوند';
													|it = 'Il numero di kit non assemblati e i componenti non utilizzati vengono annullati';
													|pl = 'Anulowaniu podlega niezmontowana ilość zestawów i niewykorzystane części';
													|tr = 'Montaj yapılmamış set sayısı ve kullanılmayan bileşenler iptal edilebilir'");
		ProvisionInDocumentsServer.ConfigureHyperlinkedSoftwareState(ThisObject);
		
	Else
		
		// The "Quantity" field is renamed according to the type of operation.
		Items.NumberOfPackages.Title = NStr("vi = 'Tháo rời';
											|ru = 'Разобрать';
											|en = 'Disassemble'; fa = 'دمونتاژ';
											|it = 'Analizzare';
											|pl = 'Disassemble';
											|tr = 'Demonte et'");
		Commands.CancelUnprocessed.ToolTip = NStr("vi = 'Số lượng bộ dụng cụ không sử dụng và các thành phần không nhận được có thể bị hủy';
													|ru = 'Отмене подлежит неиспользованное количество комплектов и неполученные комплектующие';
													|en = 'Unused kits and unreceived components are subject to cancellation'; fa = 'Unused kits and unreceived components are subject to cancellation';
													|it = 'Il numero dei set non utilizzati e i componenti non ricevuti vengono annullati';
													|pl = 'Anulowaniu podlega nieużywana ilość zestawów i nieotrzymane części';
													|tr = 'İptal, kullanılmayan set sayısına ve teslim alınmayan bileşenlere tabidir'");
		
	EndIf;
	
	Items.SupplyOption.Visible      = Not ThisIsBuild;
	Items.WithAssignment.Visible             = Not ThisIsBuild;
	Items.GoodsPurpose.Visible        = Not ThisIsBuild;
	
	Items.Purpose.Visible                 = ThisIsBuild;
	Items.GoodsSupplyOption.Visible   = ThisIsBuild;
	HasRight = ProvisionInDocumentsServer.HaveRightToViewStateHyperlink();
	Items.PagesHyperlinkSoftwareStatus.Visible = HasRight And ThisIsBuild;
	
	Items.GoodsWithAssignment.Visible                      = ThisIsBuild;
	Items.ProductsActionGroup.Visible                   = ThisIsBuild;
	Items.ProductsGroupFlagSeparately.Visible            = ThisIsBuild;
	Items.ProductsContextMenuGroupSoftware.Visible = ThisIsBuild;
	Items.GoodsAvailable.Visible                         = ThisIsBuild;
	
	SetDesignOfQualityControlFields();
	SetElementLayoutSeparately();
	SetElementDesignAvailable();
	
EndProcedure

&AtServer
Procedure SetElementLayoutSeparately()
	
	Items.WithAssignment.Enabled = ItemsType = Enums.ItemsTypes.OwnGoods
		And Object.SupplyOption <> Enums.SupplyOptions.Ship;
	
EndProcedure

&AtServer
Procedure SetElementDesignAvailable()
	
	ThisIsBuild = Object.BusinessOperation = Enums.BusinessTransactions.AssemblyFromComponents;
	NeedColumnAvailable =
		Object.SupplyOption = Enums.SupplyOptions.ReserveAsReceived
			Or Object.SupplyOption = Enums.SupplyOptions.ToSupply
			Or Object.SupplyOption = Enums.SupplyOptions.NotRequired;
	
	Items.Available.Visible = Not ThisIsBuild And NeedColumnAvailable;
	Items.LabelPackaging.Visible = Not ThisIsBuild And NeedColumnAvailable;
	
EndProcedure

&AtServer
Procedure CalculateOrderTotals()

	AllLinesAreCanceled = True;
	OnlyNotRequired = True;
	OptionNotRequired = Enums.SupplyOptions.NotRequired;
	For Each LineProducts_ In Object.Goods Do
		AllLinesAreCanceled = AllLinesAreCanceled And LineProducts_.Canceled;
		OnlyNotRequired = OnlyNotRequired And (LineProducts_.Canceled Or LineProducts_.SupplyOption = OptionNotRequired);
	EndDo;

EndProcedure

#Region CancelLines

&AtClient
Procedure CancelUnprocessed(Command)
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.StartTimeMeasurement(True,
		"Document.ByAssemblyDisassemblyOrder.DocumentForm.Command.CancelUnprocessed");
	
	CancellationResult = CancelUnprocessedServer();
	
	ShowUserNotification(NStr("vi = 'Hủy bỏ hàng không được xử lý';
								|ru = 'Отмена неотработанных строк';
								|en = 'Cancel unfulfilled lines'; fa = 'Cancel unfulfilled lines';
								|it = 'Annullamento delle righe non elaborate';
								|pl = 'Anulowanie nieprzetworzonych wierzszy';
								|tr = 'İşlenmemiş satır iptali'"), , CancellationResult.Notification);

	If ProductsClient.YouNeedToUpdateStatusOfSeriesInHeader(Object, CachedValues, SeriesSpecificationParameters.Header) Then
		ProductsClient.UpdateCachedHeaderValuesToAccountForSeries(Object, CachedValues, SeriesSpecificationParameters.Header);
	EndIf;
	
EndProcedure

&AtServer
Function CancelUnprocessedServer()
	
	OrderLineAdjustmentStructure = OrdersServer.OrderLineAdjustmentStructure();
	OrderLineAdjustmentStructure.CancelUnprocessedLines = True;
	
	Return AdjustOrderLines(OrderLineAdjustmentStructure);
	
EndFunction

&AtClient
Procedure CancelSelectedLines(Command)
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.StartTimeMeasurement(True,
		"Document.ByAssemblyDisassemblyOrder.DocumentForm.Command.CancelSelectedLines");
	
	CancelSelectedLinesServer();
	
	ShowUserNotification(NStr("vi = 'Hủy các dòng được chọn';
								|ru = 'Отмена выделенных строк';
								|en = 'Cancel selected lines'; fa = 'لغو سطرهای انتخاب‌شده';
								|it = 'Annullamento delle righe selezionate';
								|pl = 'Anulowanie wybranych wierszy';
								|tr = 'Seçili satırların iptali'"), , NStr("vi = 'Các dòng đã chọn bị hủy bỏ';
																		|ru = 'Выделенные строки отменены';
																		|en = 'Selected lines are canceled'; fa = 'Selected lines are canceled';
																		|it = 'Righe selezionate annullate';
																		|pl = 'Zaznaczone wiersze anulowano';
																		|tr = 'Seçili satırlar iptal edildi'"));
	
EndProcedure

&AtServer
Procedure CancelSelectedLinesServer()
	
	SelectedRows = Items.Goods.SelectedRows;
	
	StructureOfActions = New Structure();
	StructureOfActions.Insert("FillInCheckQualityDateOfQualityConfirmation",
		QualityControlClientServer.CacheByKey(CacheQualityControl, "Goods"));
	CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	RowsToProcess = New Array();
	
	For Each Id In SelectedRows Do
		
		String = Object.Goods.FindByID(Id);
		String.Canceled = True;
		RowsToProcess.Add(String);
		
	EndDo;
	
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		RowsToProcess,
		StructureOfActions,
		Object.Goods,
		CachedValues);
	
	ProductsServer.FillInStatusesForSpecifyingSeries(Object,SeriesSpecificationParameters.TS);
	ProductsServer.FillInStatusesForSpecifyingSeries(Object,SeriesSpecificationParameters.Header);
		UpdateColumnAvailableServer();
	
EndProcedure

&AtServer
Function AdjustOrderLines(StructureOfAdditionalParameters)
	
	OrderObject = FormAttributeToValue("Object");
	
	StructureOfAdditionalParameters.CheckBalance = True;
	
	ResultStructure1 = OrderObject.AdjustOrderLines(StructureOfAdditionalParameters);
	
	If StructureOfAdditionalParameters.CloseOrders Then
		OrderObject.Status = Enums.InternalOrderStatuses.Closed;
	EndIf;
	
	ValueToFormAttribute(OrderObject, "Object");
	
	// While there are no canceled sets for the document, we do not display the corresponding field.
	Items.CancelGroup.Visible = Object.CountCanceled > 0;
	
	FillInServiceDetailsForProductRange();
	UpdateColumnAvailableServer();
	
	Modified = True;
	
	Return ResultStructure1;
	
EndFunction

&AtServer
Procedure UpdateAssemblyForActivity(Fill = True)
	
	FillParameters = Documents.ByAssemblyDisassemblyOrder.ParametersForFillingInVATActivityType(Object);
	
	If Fill Then
		
		VATAccountingERP.FillInTypeOfActivityVAT(
			Object.AssemblyForActivity,
			FillParameters,
			VATAccountingCachedParameterValues);
		
	EndIf;
	
	VATAccountingERP.FillInActivitySelectionList(
		Items.AssemblyForActivity,
		Object.AssemblyForActivity,
		FillParameters,
		VATAccountingCachedParameterValues);
	
EndProcedure

#EndRegion

#EndRegion

&AtClient
Procedure CreateAnAssignmentAdjustmentCompletion(QuestionResult, AdditionalParameters) Export
	
	Response = QuestionResult;
	If Response = DialogReturnCode.No Then
		Return;
	Else
		ClearMessages();	
		Write(New Structure("WriteMode,CreatingAdjustment", DocumentWriteMode.Posting, AdditionalParameters));
	EndIf;
	
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
	ElsIf Item.Name = "sh_ShamsiInput_AssemblyDisassemblyStart" Then
		AssemblyDisassemblyStartOnChange(Items.AssemblyDisassemblyStart);
	ElsIf Item.Name = "sh_ShamsiInput_AssemblyDisassemblyEnd" Then
		AssemblyDisassemblyEndOnChange(Items.AssemblyDisassemblyEnd);
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
