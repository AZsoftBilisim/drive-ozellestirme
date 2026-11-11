#Region Variables

&AtClient
Var CachedValues; //used by the mechanism for processing changes in PM details

&AtClient
Var CurDataId; //used to pass the current line to the wait handler

&AtClient
Var FormModified; // it is used to work out the form modification change event

&AtClient
Var ParametersForRecording Export;

#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	EmbeddingParameters = Documents.TransferOrder.AvailableRemainingEmbeddingOptions();
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
	
	// Handler of the "Destination" mechanism
	Catalogs.Assignments.DocumentFormWhenCreatedOnServer(ThisForm);
	
	If Not ValueIsFilled(Object.Ref) Then
		
		OnReadCreateAtServer();
		
		ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);
	EndIf;
	
	Items.BaseGroup_.Visible = ValueIsFilled(Object.DocumentBasis);
	
	Items.CloseOrder.Enabled = AccessRight("Update",Metadata.Documents.TransferOrder);
	
	SetAvailabilityOfClipboardCommands();
	
	ElementsToFillIn = New Array;
	ElementsToFillIn.Add(Items.DeliveryTimeFrom);
	ElementsToFillIn.Add(Items.DeliveryTimeTo);
	ElementsToFillIn.Add(Items.DeliveryTimeFrom1);
	ElementsToFillIn.Add(Items.DeliveryTimeTo1);
	GoodsDeliveryClientServer.FillTimeFieldSelectionList(ElementsToFillIn);
	
	// Setting the list of available statuses
	Enums.InternalOrderStatuses.FillChoiceList(Items.Status.ChoiceList, False);
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject);
	// End IntegrationWith1CDocumentManagementSubsystem
	
	
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	
	// StandardSubsystems.FilesOperations
	HyperlinkParameters = FilesOperations.FilesHyperlink();
	HyperlinkParameters.Location = "CommandBar";
	FilesOperations.OnCreateAtServer(ThisObject, HyperlinkParameters);
	// End StandardSubsystems.FilesOperations
	
	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtServer
Procedure OnReadCreateAtServer()
	
	ControlledLotReferenceLinkNew = Catalogs.ControlledLots.GetRef();
	ThereIsAccessToSenderWarehouse = ThereIsAccessToSenderWarehouse();
	SeriesSpecificationParameters = New FixedStructure(ProductsServer.SeriesSpecificationParameters(Object, Documents.TransferOrder));
	Items.GoodsSeries.Visible = SeriesSpecificationParameters.UseItemsBatch;
	
	FillInServiceDetailsForProductRange();
	
	SetSoftwareVisibility();
	EstablishVisibilityOfQualityControlGroup();
	CacheQualityControl = QualityControl.DataCacheOfMechanism(Object);
	SecurityOptionAndFlagSeparately = Documents.TransferOrder.SecurityOptionAndFlagSeparately(Object);
	
	SetOrganizationSelectionParameters();
	FormItemsManagement();
	
	GoodsDelivery.WhenReadingCreatingOrdersOnServer(Items,Object);
	
	ControlProductRange = ProductRangeServerCached.ControlProductRange(Object.DestinationWarehouse, Object.Date);
	
	SetVisibilityOfDurationUsageElements();
	
	TransferDurationDays = Object.TransferDurationDays;
	
	LinesOfBusinessServer.OnReadCreateAtServer(ThisObject);
	
	UpdateMovementUnderActivity(False);
	
	FillInServiceDetailsOfDocumentForm();
	ProcessingOfTabularForms.InitializeRowCache(Items.Goods);
	SetSoftwareAvailability();
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	AttachIdleHandler("Attachable_WhenChangingModifiabilityOfForm", 1);
	
	// StandardSubsystems.Properties
	PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
	// End StandardSubsystems.Properties
	
	EquipmentManagerClient.StartConnectingDevicesWhenYouOpenForm(Undefined, ThisForm, "BarcodeScanner");
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	// StandardSubsystems.FilesOperations
	FilesOperationsClient.OnOpen(ThisObject, Cancel);
	// End StandardSubsystems.FilesOperations
	
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)
	
	ForceCloseTheForm = True;
	
EndProcedure

&AtClient
Procedure OnClose(Exit)
	
	EquipmentManagerClient.StartDisablingHardwareWhenClosingForm(Undefined, ThisForm);
	
EndProcedure

&AtClient
Procedure ChoiceProcessing(ValueSelected, ChoiceSource)
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.StartTimeMeasurement(True,
		"Document.TransferOrder.Form.DocumentForm.Event.ChoiceProcessing");
	
	If ChoiceSource.FormName = "DataProcessor.OrderSupplyForecast.Form.Form" Then
		
		AddressOfTheMovementTable = FillInCollateralFromCollateralStateForm(
			ValueSelected.ActionCode,
			ValueSelected.AddressAnalyst,
			ValueSelected.FillParameters);
			
		// Returning the control to the form of processing the security status.
		RunCallback(ValueSelected.Callback, AddressOfTheMovementTable);
		
	ElsIf ChoiceSource.FormName = "DataProcessor.SelectReusablePackage.Form.Form" Then
		
		FillMultiTurnContainersFromStorageServer(ValueSelected.AddressOfReusableContainerInStorage);
		ReusablePackageClient.NotifyUserAboutFillingMultiTurnContainers();
		
	ElsIf ChoiceSource.FormName = "DataProcessor.SelectGoodsToSalesDocument.Form.Form" Then
		
		HandlingSelectionSelectionOnClient(ValueSelected);
		
	ElsIf ProductsClient.ThisIsIndicationOfSeries(ChoiceSource) Then
		
		ProductsClient.ProcessSeriesIndication(ThisForm, SeriesSpecificationParameters, ValueSelected);
		
	ElsIf ChoiceSource.FormName = "DataProcessor.OrderClosureWizard.Form.ClosureForm" Then
		
		CancellationResult = AdjustOrderLines(ValueSelected);
		ShowUserNotification(NStr("vi = 'Hủy bỏ hàng không được xử lý';
									|ru = 'Отмена неотработанных строк';
									|en = 'Cancel unfulfilled lines'; fa = 'Cancel unfulfilled lines';
									|it = 'Annullamento delle righe non elaborate';
									|pl = 'Anulowanie nieprzetworzonych wierzszy';
									|tr = 'İşlenmemiş satır iptali'"), , CancellationResult.Notification);
		
	EndIf;
	ProvisionInDocumentsClientServer.FillInServiceDetails(Object.Goods, DateOfShipmentRequired_, WarehouseIsRequired);
	
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
	
	If EventName = "Closing_EditingSet"
		And Parameter.OwnerForm = UUID Then
		AtEndOfEditingSet(Parameter.AddressInTempStorage);
	EndIf;
	
	If EventName = "EditSet"
		And Parameter.OwnerForm = UUID Then
		
		SetParameters = New Structure;
		SetParameters.Insert("ProductsInSet", Parameter.ProductsInSet);
		SetParameters.Insert("ItemVariantOfSet", Parameter.ItemVariantOfSet);
		SetParameters.Insert("DialColumns", DialColumns(ThisObject));
		
		SetAddressInTemporaryStorage = SetAddressInTemporaryStorage(SetParameters);
		
		OpeningParameters = New Structure;
		OpeningParameters.Insert("AddressInTempStorage", SetAddressInTemporaryStorage);
		OpeningParameters.Insert("ProductsInSet",   Parameter.ProductsInSet);
		OpeningParameters.Insert("ItemVariantOfSet", Parameter.ItemVariantOfSet);
		OpeningParameters.Insert("Date", Object.Date);
		OpeningParameters.Insert("Ref", Object.Ref);
		OpeningParameters.Insert("Warehouse", Object.SourceWarehouse);
		OpeningParameters.Insert("HideCommandRemainingQuantityInWarehouses", False);
		OpeningParameters.Insert("Organization", Object.Organization);
		OpeningParameters.Insert("ProhibitPriceEditing", True);
		OpeningParameters.Insert("HideSetPrice", True);
		
		OpenForm("DataProcessor.EditSet.Form.Form", OpeningParameters, ThisObject, UUID);
		
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

&AtServer
Procedure OnReadAtServer(CurrentObject)

	// StandardSubsystems.AccessManagement
	AccessManagement.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.AccessManagement
	
	EmbeddingParameters = Documents.TransferOrder.AvailableRemainingEmbeddingOptions();
	ProvisionInDocumentsServer.AvailableBalancesWhenReadingOnServer(ThisObject, EmbeddingParameters);
	
	OnReadCreateAtServer();

	ConfigurationModificationOverridable.OnReadAtServer(ThisForm, CurrentObject);
	
	// StandardSubsystems.Properties	
	PropertyManager.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.Properties
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	// End StandardSubsystems.AttachableCommands
EndProcedure

&AtClient
Procedure BeforeWrite(Cancel, WriteParameters)
	
	If NotExecuteCheck1BeforeWrite Then
		NotExecuteCheck1BeforeWrite = False;
		Return;
	EndIf;
	
	If WriteParameters.WriteMode = DocumentWriteMode.Posting Then
		
		Cancel = True;
		AdditionalParameters = New Structure;
		AdditionalParameters.Insert("WriteParameters", WriteParameters);
		
		ReusablePackageClient.OfferToPickUpMultiTurnContainer(
			ThisForm,
			"Goods",
			"Products,Characteristic,Count,,ShipmentStart",
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
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)

	// StandardSubsystems.AccessManagement
	AccessManagement.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	// End StandardSubsystems.AccessManagement
	
	FillInServiceDetailsForProductRange();
	FillInServiceDetailsOfDocumentForm();
	
	ProvisionInDocumentsServer.AfterWriteAtServer(ThisObject);
	SetSoftwareVisibility();
	
	ConfigurationModificationOverridable.AfterWriteAtServer(ThisForm, CurrentObject, WriteParameters);

EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	
	FormModified = Undefined;
	Attachable_WhenChangingModifiabilityOfForm();
	
	NotifyAboutDocument(WriteParameters);
	ProvisionInDocumentsClient.AfterWrite(ThisObject, "Attachable_CheckCompletionOfInventoryAllocationTask");
	
	ConfigurationModificationClientOverridable.AfterWrite(ThisForm, WriteParameters);
	
	TMCommonUseClient.PerformActionsAfterRecording(ThisForm, Object, WriteParameters);
	
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
Procedure DateOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	
	UpdateMovementUnderActivity();
	
EndProcedure

&AtClient
Procedure SourceWarehouseOnChange(Item)
	
	SourceWarehouseOnChangeServer();
	
EndProcedure

&AtClient
Procedure BusinessOperationOnChange(Item)
	
	BusinessOperationOnChangeServer();
	
EndProcedure

&AtClient
Procedure OrganizationOnChange(Item)
	
	If CurrentCompany <> Object.Organization Then
		
		OrganizationOnChangeServer();
		CurrentCompany = Object.Organization;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure DestinationWarehouseOnChange(Item)
	
	DestinationWarehouseOnChangeServer(True);
	
EndProcedure

&AtClient
Procedure LockedGoodsTransferOnChange(Item)
	
	LockedGoodsTransferOnChangeServer();
	
EndProcedure

&AtClient
Procedure ControlledLotOfTheSenderOnChange(Item)
	
	ControlledLotOfTheSenderOnChangeServer();
	
EndProcedure

&AtClient
Procedure UseTransferDurationOnChange(Item)
	
	UseTransferDurationOnChangeServer();
	
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
Procedure TransferForActivityClearing(Item, StandardProcessing)
	StandardProcessing = False;
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

#EndRegion

#Region EventHandlers

&AtClient
Procedure DecorationDeliveryServiceCreateClick(Item)
	
	
	Return;
	
EndProcedure

&AtClient
Procedure DecorationDeliveryServiceOrderListClick(Item)
	
	
	Return;
	
EndProcedure

&AtClient
Procedure DecorationDeliveryServiceAddToDeliveryOrderClick(Item)
	
	
EndProcedure


&AtClient
Procedure MethodPlaceOfDeliveryCarrierIfChanged(Item)
	
	FillInAndSetDeliveryAttributesServer(Item.Name);
	
EndProcedure

&AtClient
Procedure DeliveryAddressOnChange(Item)
	
	ProcessAddressChange(Item, "DeliveryAddress");
	
EndProcedure

&AtClient
Procedure DeliveryAddressClearing(Item, StandardProcessing)
	
	StandardProcessing = False;
	
	NamesOfDetailsOfDeliveryAddresses = GoodsDeliveryClientServer.NamesOfDetailsOfDeliveryAddresses("DeliveryAddress");
	
	GoodsDeliveryClient.ClearAddressPresentation(
		Object[NamesOfDetailsOfDeliveryAddresses.NameOfDetailsOfDeliveryAddress],
		Object[NamesOfDetailsOfDeliveryAddresses.AttributeNameOfDeliveryAddressFieldValues],
		Object[NamesOfDetailsOfDeliveryAddresses.NameOfAttributeOfDeliveryAddressValue]);
	
EndProcedure

&AtClient
Procedure DeliveryAddressStartChoice(Item, ChoiceData, StandardProcessing)
	
	NamesOfDetailsOfDeliveryAddresses = GoodsDeliveryClientServer.NamesOfDetailsOfDeliveryAddresses("DeliveryAddress");
	
	GoodsDeliveryClient.OpenAddressSelectionFormAndProcessResult(
		Item,
		Object,
		NamesOfDetailsOfDeliveryAddresses,
		StandardProcessing);
	
EndProcedure

&AtClient
Procedure DeliveryAddressChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	StandardProcessing = False;
	
	GoodsDeliveryClient.DeliveryAddressChoiceProcessing(Items, Object, Item.Name, ValueSelected);
	
	Modified = True;
	
EndProcedure

&AtClient
Procedure DeliveryAddressOfCarrierOnChange(Item)
	
	ProcessAddressChange(Item, "DeliveryAddressOfCarrier");
	
EndProcedure

&AtClient
Procedure DeliveryAddressOfCarrierClearing(Item, StandardProcessing)
	
	StandardProcessing = False;
	
	NamesOfDetailsOfDeliveryAddresses = GoodsDeliveryClientServer.NamesOfDetailsOfDeliveryAddresses("DeliveryAddressOfCarrier");
	
	GoodsDeliveryClient.ClearAddressPresentation(
		Object[NamesOfDetailsOfDeliveryAddresses.NameOfDetailsOfDeliveryAddress],
		Object[NamesOfDetailsOfDeliveryAddresses.AttributeNameOfDeliveryAddressFieldValues],
		Object[NamesOfDetailsOfDeliveryAddresses.NameOfAttributeOfDeliveryAddressValue]);
	
EndProcedure

&AtClient
Procedure DeliveryAddressOfCarrierStartChoice(Item, ChoiceData, StandardProcessing)
	
	NamesOfDetailsOfDeliveryAddresses = GoodsDeliveryClientServer.NamesOfDetailsOfDeliveryAddresses("DeliveryAddressOfCarrier");
	
	GoodsDeliveryClient.OpenAddressSelectionFormAndProcessResult(
		Item,
		Object,
		NamesOfDetailsOfDeliveryAddresses,
		StandardProcessing);
	
EndProcedure

&AtClient
Procedure DeliveryAddressOfCarrierChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	StandardProcessing = False;
	
	GoodsDeliveryClient.DeliveryAddressChoiceProcessing(Items, Object, Item.Name, ValueSelected);
	
	Modified = True;
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersGoods

&AtClient
Procedure GoodsSelection(Item, RowSelected, Field, StandardProcessing)
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.StartTimeMeasurement(
		True, "Document.TransferOrder.Form.DocumentForm.Items.Goods.Selection");
	
	If Item.CurrentItem = Items.GoodsAvailable And Not ReadOnly Then
		
		StandardProcessing = False;
		
		FormParameters = ParametersOfQuantityAndSeriesRequestForm(Undefined);
		
		If FormParameters <> Undefined Then
			OpenForm("DataProcessor.QuantityAndBatchRequest.Form", FormParameters, ThisObject);
		EndIf;
		
	ElsIf SetsClient.ItemToLock(Field) Then
		
		CurrentRow = Object.Goods.FindByID(RowSelected);
		If ValueIsFilled(CurrentRow.ProductsInSet) Then
			
			NotificationParameter1 = New Structure;
			NotificationParameter1.Insert("ProductsInSet",   CurrentRow.ProductsInSet);
			NotificationParameter1.Insert("ItemVariantOfSet", CurrentRow.ItemVariantOfSet);
			NotificationParameter1.Insert("OwnerForm",        UUID);
			
			Notify("EditSet", NotificationParameter1, ThisForm);
			
		EndIf;
		
	ElsIf Field = Items.GoodsProductsInSet Then
		ShowValue(Undefined, Items.Goods.CurrentData.ProductsInSet);
	EndIf;
	
EndProcedure

&AtClient
Procedure GoodsProductsOnChange(Item)
	
	ClearMessages();
	
	CurrentRow = Items.Goods.CurrentData;
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("CheckCharacteristicsByOwner", CurrentRow.Characteristic);
	StructureOfActions.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
	StructureOfActions.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));
	StructureOfActions.Insert("CheckFillPackageByOwner", CurrentRow.Package);
	StructureOfActions.Insert("RecalculateNumberOfUnits");
	StructureOfActions.Insert("FillInCheckQualityDateOfQualityConfirmation", CacheQualityControl);
	StructureOfActions.Insert("FillInUnblockableDateOfQualityConfirmation", CacheQualityControl);
	AddCollateralActionsOnClient(StructureOfActions, "SupplyOption,AvailableInOtherLines,WarehouseIsRequired,DateOfShipmentRequired_");
	StructureOfActions.Insert("CheckFillAssignment");
	
	SeriesVerificationParameters = New Structure("Warehouse, SeriesSpecificationParameters");
	SeriesVerificationParameters.Warehouse = New Structure("Sender, Recipient", Object.SourceWarehouse, Object.DestinationWarehouse);
	SeriesVerificationParameters.SeriesSpecificationParameters = SeriesSpecificationParameters;
	StructureOfActions.Insert("CheckSeriesCalculateStatus", SeriesVerificationParameters);
	
	If ControlProductRange Then
		AssortmentInspectionStructure = ProductRangeClientServer.AssortmentVerificationParameters();
		AssortmentInspectionStructure.Ref = Object.Ref;
		AssortmentInspectionStructure.Warehouse = Object.DestinationWarehouse;
		AssortmentInspectionStructure.Date = ?(ValueIsFilled(Object.RequestedDeliveryDate), Object.RequestedDeliveryDate, Object.Date);
		AssortmentInspectionStructure.MessageText = NStr("vi = 'Hàng hóa %1 không thuộc phân loại của cửa hàng nhận. Không nên đặt mặt hàng này.';
														|ru = 'Товар %1 не включен в ассортимент магазина-получателя. Заказывать его не рекомендуется.';
														|en = 'Product %1 is not included in the receiving store''s product range. It is not recommended that you order it.'; fa = 'Product %1 is not included in the receiving store''s product range. It is not recommended that you order it.';
														|it = 'La merce %1 non è inclusa nell''assortimento del negozio-destinatario. Ordinarla non è consigliabile.';
														|pl = 'Towar %1 nie jest włączony do asortymentu sklepu odbiorcy. Jego zamawianie nie jest zalecane.';
														|tr = 'Ürün %1 alıcı mağazanın ürün yelpazesine dahil değildir. Sipariş önerilmemektedir.'");
		AssortmentInspectionStructure.NameOfAssortmentResource = "PurchasesAreAllowed";
		AssortmentInspectionStructure.CheckedYouCanAdd = True;
		AssortmentInspectionStructure.AllowAdding = True;
		
		StructureOfActions.Insert("CheckRowAssortment", AssortmentInspectionStructure);
	EndIf;

	StructureOfActions.Insert("ProductsOnChangeOverridable", New Structure("FormName, TabularSectionName",
		ThisForm.FormName, "Goods"));

	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
	If ProvisionInDocumentsClient.YouNeedToUpdateAvailableColumn(StructureOfActions) Then
		UpdateColumnAvailableServer();
	EndIf;
	
	ProvisionInDocumentsClientServer.FillInServiceDetails(Object.Goods, DateOfShipmentRequired_, WarehouseIsRequired);
	
EndProcedure

&AtClient
Procedure GoodsCharacteristicOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("CharacteristicOnChangeOverridable", New Structure("FormName, TabularSectionName",
		ThisForm.FormName, "Goods"));
	AddCollateralActionsOnClient(StructureOfActions, "SupplyOption,AvailableInOtherLines,WarehouseIsRequired,DateOfShipmentRequired_");
	StructureOfActions.Insert("CheckFillAssignment");
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
	If ProvisionInDocumentsClient.YouNeedToUpdateAvailableColumn(StructureOfActions) Then
		UpdateColumnAvailableServer();
	EndIf;
	
	ProvisionInDocumentsClientServer.FillInServiceDetails(Object.Goods, DateOfShipmentRequired_, WarehouseIsRequired);
	
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
		AddCollateralActionsOnClient(StructureOfActions, "SupplyOption,Available,WarehouseIsRequired,DateOfShipmentRequired_");
		SeriesVerificationParameters = New Structure("Warehouse, SeriesSpecificationParameters");
		SeriesVerificationParameters.Warehouse = New Structure("Sender, Recipient", Object.SourceWarehouse, Object.DestinationWarehouse);
		SeriesVerificationParameters.SeriesSpecificationParameters = SeriesSpecificationParameters;
		StructureOfActions.Insert("CheckSeriesCalculateStatus", SeriesVerificationParameters);
		BatchProcessingOfTablePartClient.ProcessTSString(Items.Goods.CurrentData, StructureOfActions, CachedValues);
		ProvisionInDocumentsClientServer.FillInServiceDetails(Object.Goods, DateOfShipmentRequired_, WarehouseIsRequired);
	EndIf;

EndProcedure

&AtClient
Procedure GoodsOnEditEnd(Item, NewRow, CancelEdit)
	
	ReusablePackageClient.UpdateFillingStateOfMultiTurnContainer(Object.ReusablePackageFillingStatus);
	
EndProcedure

&AtClient
Procedure GoodsAfterDeleteRow(Item)
	
	ReusablePackageClient.UpdateFillingStateOfMultiTurnContainer(Object.ReusablePackageFillingStatus);
	ProvisionInDocumentsClientServer.FillInServiceDetails(Object.Goods, DateOfShipmentRequired_, WarehouseIsRequired);
	UpdateColumnAvailableServer();
	
EndProcedure

&AtClient
Procedure GoodsBeforeAddRow(Item, Cancel, Copy, Parent, IsFolder, Parameter)
	If Copy Then
		SetsClient.BeforeDeletingRowOfTablePart(ThisForm, "Goods", Cancel, True);
	EndIf;
EndProcedure

&AtClient
Procedure GoodsBeforeDeleteRow(Item, Cancel)
	SetsClient.BeforeDeletingRowOfTablePart(ThisForm, "Goods", Cancel);
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
Procedure GoodsCanceledOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;
	
	StructureOfActions = New Structure;
	
	SeriesVerificationParameters = New Structure("Warehouse, SeriesSpecificationParameters");
	SeriesVerificationParameters.Warehouse = New Structure("Sender, Recipient", Object.SourceWarehouse, Object.DestinationWarehouse);
	SeriesVerificationParameters.SeriesSpecificationParameters = SeriesSpecificationParameters;
	StructureOfActions.Insert("CheckSeriesCalculateStatus", SeriesVerificationParameters);
	StructureOfActions.Insert("FillInCheckQualityDateOfQualityConfirmation", CacheQualityControl);
	StructureOfActions.Insert("FillInUnblockableDateOfQualityConfirmation", CacheQualityControl);
	AddCollateralActionsOnClient(StructureOfActions, "AvailableInOtherLines,WarehouseIsRequired,DateOfShipmentRequired_");
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
	If ProvisionInDocumentsClient.YouNeedToUpdateAvailableColumn(StructureOfActions) Then
		UpdateColumnAvailableServer();
	EndIf;
	
	ProvisionInDocumentsClientServer.FillInServiceDetails(Object.Goods, DateOfShipmentRequired_, WarehouseIsRequired);
	
EndProcedure

&AtClient
Procedure GoodsSupplyOptionStartChoice(Item, ChoiceData, ChoiceByAdding, StandardProcessing)
	
	NewArray = New Array();
	If Object.LockedGoodsTransfer Then
		
		UnacceptableActions = New Array();
		
		UnacceptableActions.Add(PredefinedValue("Enum.SupplyOptions.ToSupply"));
		UnacceptableActions.Add(PredefinedValue("Enum.SupplyOptions.NotRequired"));
		
		ActionsArray = ProvisionInDocumentsClientServer.AvailableActionsForSelectingCollateralInDefaultRow();
		For Each InvalidAction In UnacceptableActions Do
			IndexOf = ActionsArray.Find(InvalidAction);
			If IndexOf <> Undefined Then
				ActionsArray.Delete(IndexOf);
			EndIf;
		EndDo;
		AllowedActions = New FixedArray(ActionsArray);
		NewParameter1 = New ChoiceParameter("AllowedActions", AllowedActions);
		NewArray.Add(NewParameter1);
		
	EndIf;
	Item.ChoiceParameters = New FixedArray(NewArray);
	
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
	
	StructureOfActions = New Structure;
	AddCollateralActionsOnClient(StructureOfActions, "AvailableInOtherLines");
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
	If ProvisionInDocumentsClient.YouNeedToUpdateAvailableColumn(StructureOfActions) Then
		UpdateColumnAvailableServer();
	EndIf;
	
EndProcedure

&AtClient
Procedure GoodsReceiptEndOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;
	
	StructureOfActions = New Structure();
	StructureOfActions.Insert("FillInCheckQualityDateOfQualityConfirmation", CacheQualityControl);
	StructureOfActions.Insert("FillInUnblockableDateOfQualityConfirmation", CacheQualityControl);
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
EndProcedure

&AtClient
Procedure GoodsShipmentStartOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;
	If Not Object.UseTransferDuration Then
		CurrentRow.ReceiptEnd = CurrentRow.ShipmentStart;
	EndIf;
	
	StructureOfActions = New Structure();
	StructureOfActions.Insert("FillInCheckQualityDateOfQualityConfirmation", CacheQualityControl);
	StructureOfActions.Insert("FillInUnblockableDateOfQualityConfirmation", CacheQualityControl);
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
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
// End StandardSubsystems.AttachableCommands


// StandardSubsystems.AttachableCommands
&AtClient
Procedure Attachable_ContinueCommandExecutionAtServer(ExecutionParameters, AdditionalParameters) Export
	ExecuteCommandAtServer(ExecutionParameters);
EndProcedure
// End StandardSubsystems.AttachableCommands


&AtClient
Procedure ImportDataFromPDT(Command)
	
	ClearMessages();
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.StartTimeMeasurement(True,
		"Document.TransferOrder.DocumentForm.Command.ImportDataFromPDT");
	
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
	
	TMCommonUseClient.Write(ThisForm, True);
	
EndProcedure

&AtClient
Procedure SelectGoods(Command)
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.StartTimeMeasurement(True,
		"Document.TransferOrder.DocumentForm.Command.SelectGoods");
	
	Cancel = False;
	
	If Not ValueIsFilled(Object.SourceWarehouse) Then
		
		ClearMessages();
		CommonClientServer.MessageToUser(NStr("vi = 'Chưa điền trường ""Người gửi""';
												|ru = 'Поле ""Отправитель"" не заполнено';
												|en = '""Sender"" is not filled in'; fa = '""Sender"" is not filled in';
												|it = 'Il campo ""Mittente"" non è compilato';
												|pl = 'Nie wypełniono pola ""Отправитель""';
												|tr = '""Gönderen"" alanı doldurulmadı'"), Object.Ref, "Object.SourceWarehouse",, Cancel);
		
	EndIf;
	
	If Cancel Then
		
		Return;
		
	EndIf;
	
	ControlledLotReference = Object.ControlledLotOfTheSender;
	If Object.LockedGoodsTransfer And Not ValueIsFilled(ControlledLotReference) Then
		ControlledLotReference = ControlledLotReferenceLinkNew; // so that Balances without Lot references are not displayed.
	EndIf;
	
	FormParameters = New Structure;
	FormParameters.Insert("Warehouse",                                     Object.SourceWarehouse);
	FormParameters.Insert("SelectionModeWithoutAmountParameters",         True);
	FormParameters.Insert("FilterByProductType",                   New FixedArray(ProductsClientServer.SelectionByProductMultiTurnContainer()));
	FormParameters.Insert("UseShipmentDates",                  True);
	FormParameters.Insert("HideTheViewPriceColumn",                    True);
	FormParameters.Insert("HideTheItemPricesCommand",           True);
	FormParameters.Insert("Title",                                 NStr("vi = 'Chọn hàng hóa';
																		|ru = 'Подбор товаров';
																		|en = 'Pick goods'; fa = 'انتخاب کالاها';
																		|it = 'Selezione delle merci';
																		|pl = 'Wybór towarów';
																		|tr = 'Ürünlerin seçimi'"));
	FormParameters.Insert("Date",                                      Object.Date);
	FormParameters.Insert("Document",                                  Object.Ref);
	FormParameters.Insert("SeriesSpecificationParameters",                    SeriesSpecificationParameters);
	FormParameters.Insert("Purpose",                                Object.Purpose);
	FormParameters.Insert("Department",                             Object.Department);
	FormParameters.Insert("SelectSupplyOptions",                True);
	FormParameters.Insert("AvailableRemainingDocumentParameters",        Undefined);
	FormParameters.Insert("ControlledLotReference",                      ControlledLotReference);
	FormParameters.Insert("SecurityOptionAndFlagSeparately",        SecurityOptionAndFlagSeparately);
	If Object.LockedGoodsTransfer Then
		
		Actions = ProvisionInDocumentsClientServer.AllActions();
		Actions.Delete(Actions.FindByValue(PredefinedValue("Enum.SupplyOptions.NotRequired")));
		Actions.Delete(Actions.FindByValue(PredefinedValue("Enum.SupplyOptions.ToSupply")));
		FormParameters.Insert("AcceptableSeparateActions", Actions);
		FormParameters.Insert("AllowedNonIsolatedActions", Actions);
		
	EndIf;
	
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
		AddCollateralActionsOnClient(StructureOfActions, "UpdateProductCache_");
		BatchProcessingOfTablePartClient.ProcessTSString(NewRow, StructureOfActions, CachedValues);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure InsertRows(Command)
	
	NumberOfProductsBeforeInsertion = Object.Goods.Count();
	
	GetLinesFromClipboard();
	ProvisionInDocumentsClientServer.FillInServiceDetails(Object.Goods, DateOfShipmentRequired_, WarehouseIsRequired);
	
	NumberOfInserted = Object.Goods.Count()-NumberOfProductsBeforeInsertion;
	ProcessingOfTabularFormsClient.NotifyUserAboutInsertingRows(NumberOfInserted);
	
EndProcedure

&AtClient
Procedure CopyRows(Command)
	
	If ProcessingOfTabularFormsClient.SelectedLineToExecuteCommand(Items.Goods) Then
		CopyLinesOnServer();
		ProcessingOfTabularFormsClient.NotifyUserAboutCopyingStrings(Items.Goods.SelectedRows.Count());
	EndIf;

EndProcedure

&AtClient
Procedure AddReusablePackage(Command)

	ReusablePackageClient.SelectReusablePackage(
		ThisForm,
		"Goods",
		"Products,Characteristic,Count,,ShipmentStart");
	
EndProcedure

&AtClient
Procedure SetComposition(Command)
	
	RowSelected = Items.Goods.CurrentRow;
	
	If RowSelected = Undefined Then
		Return;
	EndIf;
	
	CurrentRow = Object.Goods.FindByID(RowSelected);
	
	If Not ValueIsFilled(CurrentRow.ProductsInSet) Then
		ShowMessageBox(,NStr("vi = 'Chỉ có thể mở thành phần bộ sản phẩm đối với bộ sản phẩm.';
							|ru = 'Открытие состава набора возможно только для набора.';
							|en = 'You can open a set only for the set.'; fa = 'You can open a set only for the set.';
							|it = 'L''apertura della composizione del kit è possibile solo per il kit.';
							|pl = 'Otwarcie składu zestawu jest możliwe tylko dla zestawu.';
							|tr = 'Set kompozisyonunun açılması sadece bir set için mümkündür.'"));
		Return;
	EndIf;
	
	KitParameters = New Structure;
	KitParameters.Insert("ProductsInSet",   CurrentRow.ProductsInSet);
	KitParameters.Insert("ItemVariantOfSet", CurrentRow.ItemVariantOfSet);
	KitParameters.Insert("DialColumns",        DialColumns(ThisForm));
	
	SetAddressInTemporaryStorage = SetAddressInTemporaryStorage(KitParameters);
	
	OpeningParameters = New Structure;
	OpeningParameters.Insert("AddressInTempStorage", SetAddressInTemporaryStorage);
	OpeningParameters.Insert("ProductsInSet", CurrentRow.ProductsInSet);
	OpeningParameters.Insert("ItemVariantOfSet", CurrentRow.ItemVariantOfSet);
	OpeningParameters.Insert("Partner", Object.CarrierPartner);
	OpeningParameters.Insert("Ref", Object.Ref);
	OpeningParameters.Insert("Date", Object.Date);
	OpeningParameters.Insert("Warehouse", Object.SourceWarehouse);
	OpeningParameters.Insert("HideCommandRemainingQuantityInWarehouses", False);
	OpeningParameters.Insert("Organization", Object.Organization);
	OpeningParameters.Insert("HideSetPrice", True);
	
	OpenForm("DataProcessor.EditSet.Form.Form", OpeningParameters, ThisForm, UUID);
	
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

#Region Supply

&AtClient
Procedure CreateAnAssignmentAdjustmentReservation(Command)
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.StartTimeMeasurement(True,
		"Document.TransferOrder.DocumentForm.Command.CreateAnAssignmentAdjustmentReservation");
	
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
		"Document.TransferOrder.DocumentForm.Command.CreateAssignmentAdjustmentRemoveFromReserve");
	
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
Procedure CloseOrderFragment(Result = Undefined, AdditionalParameters = Undefined) Export
	
	ListOfOrdersToClose = New ValueList;
	ListOfOrdersToClose.Add(Object.Ref);
	
	ClosureStructure = New Structure;
	ClosureStructure.Insert("Orders",                       ListOfOrdersToClose);
	ClosureStructure.Insert("DocumentInitiator",            Object.Ref);
	ClosureStructure.Insert("CancelUnprocessedLines", True);
	ClosureStructure.Insert("CloseOrders",              True);
	
	OpenForm("DataProcessor.OrderClosureWizard.Form.ClosureForm", ClosureStructure,
					ThisForm,,,, Undefined, FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure CloseOrderCompletion(QuestionResult, AdditionalParameters) Export
	
	CallbackDescription = New CallbackDescription("CloseOrderFragment", ThisObject);
	WriteParameters = New Structure;
	WriteParameters.Insert("ActionAfterRecording",CallbackDescription);
	WriteParameters.Insert("WriteMode", DocumentWriteMode.Posting);
	
	If QuestionResult = DialogReturnCode.No Then
		Return;
	Else
		Write(WriteParameters);
	EndIf;
	
EndProcedure

&AtClient
Procedure FillInTheEndOfReceipt(Command)
	
	If Items.Goods.SelectedRows.Count() > 0 Then
		
		CallbackDescription = New CallbackDescription("FillInTheEndOfReceiptCompletion", ThisForm);
		
		If Object.UseTransferDuration Then
			TitleOfDateEntryForm = NStr("vi = 'Hãy nhập ngày kết thúc tiếp nhận';
										|ru = 'Введите дату окончания поступления';
										|en = 'Enter receipt end date'; fa = 'Enter receipt end date';
										|it = 'Inserire la data del termine di arrivo';
										|pl = 'Wprowadź datę zakończenia wpłaty';
										|tr = 'Giriş bitiş tarihini gir'");
		Else
			TitleOfDateEntryForm = NStr("vi = 'Nhập ngày giao hàng';
										|ru = 'Введите дату отгрузки';
										|en = 'Enter shipment date'; fa = 'Enter shipment date';
										|it = 'Inserire la data di spedizione';
										|pl = 'Wprowadź datę wysyłki';
										|tr = 'Sevkiyat tarihini girin'");
		EndIf;
		ShowInputDate(CallbackDescription, Object.RequestedDeliveryDate, TitleOfDateEntryForm, DateFractions.Date);
		
	EndIf;
	
EndProcedure

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
Procedure SetConditionalAppearance()

	ConditionalAppearance.Items.Clear();

	// Conditional registration of collateral.
	TMCommonUse.SetUncheckBlank(
		ConditionalAppearance, "GoodsShipmentStart", "Object.Goods.ShipmentStart", "Object.Goods.DateOfShipmentRequired_");
	
	TMCommonUse.SetUncheckBlank(
		ConditionalAppearance, "SourceWarehouse", "Object.SourceWarehouse", "WarehouseIsRequired");
	
	ProvisionInDocumentsServer.SetConditionalAppearanceApart(
		ConditionalAppearance,
		Items.GoodsWithAssignment,
		"Object.Goods.SupplyOption",
		"Object.Goods.ItemsType");
		
	ProvisionInDocumentsServer.AvailableLeftoversAddColumnLayoutAvailable(ThisObject);
	
	ProductsServer.SetConditionalAppearanceOfUnitsOfMeasurement(ThisForm);

	//
	
	TMCommonUse.SetConditionalAppearanceOfPriority(ThisObject);
	
	//

	ProductsServer.EstablishConditionalAppearanceOfProductCharacteristics(ThisForm);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.Goods.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.Canceled");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	Item.Appearance.SetParameterValue("TextColor", StyleColors.TextColorOfCanceledRowOfDocument);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsShipmentStart.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsReceiptEnd.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.Canceled");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	Item.Appearance.SetParameterValue("MarkIncomplete", False);

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsShipmentStart.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsReceiptEnd.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.SupplyOption");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotEqual;
	ItemFilter.RightValue = Enums.SupplyOptions.Ship;

	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	//

	ProductsServer.EstablishConditionalAppearanceOfProductSeries(ThisForm, "SeriesAlwaysWHGoods");

	
	//
	
	ProductsServer.SetConditionalAppearanceOfProductAssignment(ThisForm);
	
	//
	
	SetsServer.SetConditionalAppearance(ThisForm, "Goods");
	
	// Conditional appearance of quality control Attributes.
	Fields = QualityControl.Fields(
		Items.GoodsToControlQuality,
		Items.GoodsQualityConfirmationDate);
	FlagDisabled = New Array();
	DateIsOptional = New Array();
	EmptyBatch = Catalogs.ControlledLots.EmptyRef();
	NotEqual = DataCompositionComparisonType.NotEqual;
	QualityControl.AddFilter(FlagDisabled, "Object.Goods.Canceled", True);
	QualityControl.AddFilter(FlagDisabled, "Object.ControlledLotOfTheSender", EmptyBatch, NotEqual);
	QualityControl.AddFilter(DateIsOptional, "Object.Goods.ReceiptEnd", '00010101');
	QualityControl.SetupAppearance(ConditionalAppearance, Fields, FlagDisabled, DateIsOptional);
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsQualityConfirmationDate.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.LockedGoodsTransfer");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	OrGroup = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	OrGroup.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	
	ItemFilter = OrGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.SubjectToUnlocking");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	ItemFilter = OrGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.ControlledLotOfTheSender");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
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

#Region OnChangeAttributes

&AtServer
Procedure DestinationWarehouseOnChangeServer(DirectModificationOfWarehouseField = False)
	
	ControlProductRange = ProductRangeServerCached.ControlProductRange(Object.DestinationWarehouse, Object.Date);
	
	If ControlProductRange Then
		ProductRangeServer.CheckAssortmentOfTableOfSelectedProducts(Object, "DestinationWarehouse");
	EndIf;
	
	PrepareFillSetSeriesVisibility();
	
	FillInAndSetDeliveryAttributesServer("DestinationWarehouse");
	
	UpdateMovementUnderActivity();

	If QualityControl.UpdateActionParameters(
			Documents.TransferOrder,
			Object,
			CacheQualityControl,
			DirectModificationOfWarehouseField) Then
		
		StructureOfActions = New Structure();
		StructureOfActions.Insert("FillInCheckQualityDateOfQualityConfirmation", CacheQualityControl);
		StructureOfActions.Insert("FillInUnblockableDateOfQualityConfirmation", CacheQualityControl);
		BatchProcessingOfTablePartServer.TreatTS(Object.Goods, StructureOfActions);
		
	EndIf;
	
EndProcedure

&AtServer
Procedure BusinessOperationOnChangeServer()
	
	FillInSubordinatePropertiesForStatistics("BusinessOperation");
	
	If QualityControl.UpdateActionParameters(
			Documents.TransferOrder,
			Object,
			CacheQualityControl) Then
		
		StructureOfActions = New Structure();
		StructureOfActions.Insert("FillInCheckQualityDateOfQualityConfirmation", CacheQualityControl);
		StructureOfActions.Insert("FillInUnblockableDateOfQualityConfirmation", CacheQualityControl);
		BatchProcessingOfTablePartServer.TreatTS(Object.Goods, StructureOfActions);
		
	EndIf;
	
	SetOrganizationSelectionParameters();
	Documents.TransferOrder.CheckAndClearOrganization(Object, Object.CompanyRecipient);
	Documents.TransferOrder.CheckAndClearOrganization(Object, Object.Organization);
	
	FormItemsManagement();
	
EndProcedure

&AtServer
Procedure OrganizationOnChangeServer()
	
	FillInSubordinatePropertiesForStatistics("Organization");
	
	If QualityControl.UpdateActionParameters(
			Documents.TransferOrder,
			Object,
			CacheQualityControl) Then
		
		StructureOfActions = New Structure();
		StructureOfActions.Insert("FillInCheckQualityDateOfQualityConfirmation", CacheQualityControl);
		StructureOfActions.Insert("FillInUnblockableDateOfQualityConfirmation", CacheQualityControl);
		BatchProcessingOfTablePartServer.TreatTS(Object.Goods, StructureOfActions);
		
	EndIf;
	
	Documents.TransferOrder.CheckAndClearOrganization(Object, Object.CompanyRecipient);
	UpdateMovementUnderActivity();
	
EndProcedure

&AtServer
Procedure UpdateMovementUnderActivity(Fill = True)
	
	FillParameters = VATAccountingERPClientServer.ParametersForFillingInVATActivityType();
	FillParameters.Organization = Object.Organization;
	FillParameters.Date = ?(ValueIsFilled(Object.Date), Object.Date, CurrentSessionDate());
	FillParameters.Warehouse = Object.DestinationWarehouse;
	FillParameters.MovementOfGoodsInWarehouses = True;
	
	If Fill Then
		
		VATAccountingERP.FillInTypeOfActivityVAT(
			Object.TransferForActivity, 
			FillParameters,
			VATAccountingCachedParameterValues);
		
	EndIf;
	VATAccountingERP.FillInActivitySelectionList(
		Items.TransferForActivity, 
		Object.TransferForActivity, 
		FillParameters, 
		VATAccountingCachedParameterValues);
	
EndProcedure

&AtServer
Procedure LineOfBusinessOnChangeServer()
	
	LinesOfBusinessServer.WhenChangingDirectionOfActivity(ThisObject);
	
	Object.AssignByOrderAssignment = Constants.OptionOfGoodslAssignmentInTransfer.Get()
		<> Enums.OptionsOfGoodslAssignmentInTransfer.AssignmentRecipient;
		
	ProvisionInDocumentsServer.WhenChangingDocumentDetails(ThisObject);
	
EndProcedure

&AtServer
Procedure FillInSubordinatePropertiesForStatistics(ParentPropsName)
	ObjectsFillingByStatistics.FillInSubordinateDetailsOfObject(Object, ParentPropsName);
EndProcedure

&AtServer
Procedure SourceWarehouseOnChangeServer()
	
	PrepareFillSetSeriesVisibility();
	ProvisionInDocumentsServer.WhenChangingDocumentDetails(ThisObject);
	ThereIsAccessToSenderWarehouse = ThereIsAccessToSenderWarehouse();
	SetSoftwareVisibility();
	SetSoftwareAvailability();
	
EndProcedure

&AtServer
Procedure LockedGoodsTransferOnChangeServer()
	
	SeriesSpecificationParameters = New FixedStructure(
		ProductsServer.SeriesSpecificationParameters(Object, Documents.TransferOrder));
	
	SetSoftwareVisibility();
	EstablishVisibilityOfQualityControlGroup();
	SecurityOptionAndFlagSeparately = Documents.TransferOrder.SecurityOptionAndFlagSeparately(Object);
	
	If Object.LockedGoodsTransfer Then
		
		InstallableOption = Enums.SupplyOptions.ReserveAsReceived;
		For Each TableRow In Object.Goods Do
			
			If TableRow.SupplyOption = Enums.SupplyOptions.ToSupply
					Or TableRow.SupplyOption = Enums.SupplyOptions.NotRequired Then
				TableRow.SupplyOption = InstallableOption;
			EndIf;
			
		EndDo;
		
	Else
		
		Object.ControlledLotOfTheSender = Catalogs.ControlledLots.EmptyRef();
		
	EndIf;
	
	ProvisionInDocumentsServer.WhenChangingDocumentDetails(ThisObject);
	
	If QualityControl.UpdateActionParameters(
			Documents.TransferOrder,
			Object,
			CacheQualityControl) Then
		
		StructureOfActions = New Structure();
		StructureOfActions.Insert("FillInCheckQualityDateOfQualityConfirmation", CacheQualityControl);
		StructureOfActions.Insert("FillInUnblockableDateOfQualityConfirmation", CacheQualityControl);
		BatchProcessingOfTablePartServer.TreatTS(Object.Goods, StructureOfActions);
		
	EndIf;
	 
EndProcedure

&AtServer
Procedure ControlledLotOfTheSenderOnChangeServer()
	
	ProvisionInDocumentsServer.WhenChangingDocumentDetails(ThisObject);
	If QualityControl.UpdateActionParameters(
			Documents.TransferOrder,
			Object,
			CacheQualityControl) Then
		
		StructureOfActions = New Structure();
		StructureOfActions.Insert("FillInCheckQualityDateOfQualityConfirmation", CacheQualityControl);
		StructureOfActions.Insert("FillInUnblockableDateOfQualityConfirmation", CacheQualityControl);
		BatchProcessingOfTablePartServer.TreatTS(Object.Goods, StructureOfActions);
		
	EndIf;
	
EndProcedure

&AtServer
Procedure UseTransferDurationOnChangeServer()
	
	If Object.UseTransferDuration Then
		Object.TransferDurationDays = TransferDurationDays;
	Else
		For Each TableRow In Object.Goods Do
			TableRow.ReceiptEnd = TableRow.ShipmentStart;
		EndDo;
		TransferDurationDays = Object.TransferDurationDays;
		Object.TransferDurationDays = 0;
	EndIf;
	
	If Not Object.UseTransferDuration Then
		For Each TableRow In Object.Goods Do
			TableRow.ReceiptEnd = TableRow.ShipmentStart;
		EndDo;
	EndIf;
	
	If QualityControl.UpdateActionParameters(
			Documents.TransferOrder,
			Object,
			CacheQualityControl) Then
		
		StructureOfActions = New Structure();
		StructureOfActions.Insert("FillInCheckQualityDateOfQualityConfirmation", CacheQualityControl);
		StructureOfActions.Insert("FillInUnblockableDateOfQualityConfirmation", CacheQualityControl);
		BatchProcessingOfTablePartServer.TreatTS(Object.Goods, StructureOfActions);
		
	EndIf;
	
	SetVisibilityOfDurationUsageElements();
	
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

	CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();

	StructureOfActions = New Structure;

	StructureOfActions.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
	StructureOfActions.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));
	
	AddCollateralActionsOnServer(StructureOfActions, "WarehouseIsRequired,DateOfShipmentRequired_");
	
	BegOfDay = BegOfDay(CurrentSessionDate());
	
	FieldsForFillIn = "ProductsInSet,ItemVariantOfSet,Products,Characteristic,ItemVariantsAreUsed,Package,
		|NumberOfPackages,Count,SupplyOption,WithAssignment,Series";
	SearchFields = "ProductsInSet, ItemVariantOfSet, Products, Characteristic, Package, 
		|SupplyOption, WithAssignment, Series";
	FilterParameters = New Structure(SearchFields);
	RowsToProcess = New Array;
	ShippingDates = New Map;
	
	RecalculationOfPackagesIsRequired = False;
	
	For Each RowOfProduct In TableOfGoods Do
		
		If ValueIsFilled(RowOfProduct.ProductsInSet) Then
			// For sets, you should increase the number in the set lines that have already been added to the TS.
			
			FillPropertyValues(FilterParameters, RowOfProduct);
			FoundRows = Object.Goods.FindRows(FilterParameters);
			
			If FoundRows.Count() > 0 Then
				CurrentRow = FoundRows[0];
				CurrentRow.Count = CurrentRow.Count + RowOfProduct.Count;
				RecalculationOfPackagesIsRequired = True;
			Else
				CurrentRow = Object.Goods.Add();
				FillPropertyValues(CurrentRow, RowOfProduct, FieldsForFillIn);
			EndIf;
		Else
			// For non-sets, you should always add a new line, regardless of the availability of such an item in the TS.
			
			CurrentRow = Object.Goods.Add();
			FillPropertyValues(CurrentRow, RowOfProduct, FieldsForFillIn);
		EndIf;
		
		CurrentRow.SetIndex = ?(ValueIsFilled(CurrentRow.ProductsInSet), 1, 0);
		ShippingDates.Insert(CurrentRow, RowOfProduct.DateOfShipment);
		RowsToProcess.Add(CurrentRow);
		
	EndDo;
	
	If RecalculationOfPackagesIsRequired Then
		StructureOfActions.Insert("RecalculateNumberOfPackages");
	EndIf;
	
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		RowsToProcess,
		StructureOfActions,
		Object.Goods,
		CachedValues);
	
	For Each CurrentRow In RowsToProcess Do
		
		CurrentRow.ShipmentStart = ProvisionInDocumentsServer.ShipmentDateProcessingSelectionSelection(
			ShippingDates.Get(CurrentRow),
			CurrentRow.SupplyOption,
			Max(BegOfDay, Object.RequestedDeliveryDate - 86400 * Object.TransferDurationDays));
			
		If ValueIsFilled(CurrentRow.ShipmentStart) Then
			
			CurrentRow.ReceiptEnd = Max(CurrentRow.ShipmentStart + 86400 * Object.TransferDurationDays,
				BegOfDay + 86400 * Object.TransferDurationDays,
				Object.RequestedDeliveryDate);
				
		EndIf;
			
	EndDo;
	
	StructureOfActions = New Structure();
	StructureOfActions.Insert("FillInCheckQualityDateOfQualityConfirmation", CacheQualityControl);
	StructureOfActions.Insert("FillInUnblockableDateOfQualityConfirmation", CacheQualityControl);
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		RowsToProcess,
		StructureOfActions,
		Object.Goods,
		CachedValues);
	
	If ControlProductRange Then
		ProductRangeServer.CheckAssortmentOfTableOfSelectedProducts(Object, "DestinationWarehouse", TableOfGoods);
	EndIf;
	ProvisionInDocumentsClientServer.FillInServiceDetails(Object.Goods, DateOfShipmentRequired_, WarehouseIsRequired);
	UpdateColumnAvailableServer();
	
	ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);
	
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
	AddActionsToStructureWhenChangingPackagesNumber(StructureOfActionsWithAddedStrings);
	StructureOfActionsWithAddedStrings.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
	StructureOfActionsWithAddedStrings.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));
	StructureOfActionsWithAddedStrings.Insert("FillInCheckQualityDateOfQualityConfirmation", CacheQualityControl);
	StructureOfActionsWithAddedStrings.Insert("FillInUnblockableDateOfQualityConfirmation", CacheQualityControl);
	
	StructureOfActionsWithModifiedStrings = New Structure;
	AddActionsToStructureWhenChangingPackagesNumber(StructureOfActionsWithModifiedStrings);

	StructureOfActions = BarcodingOfItemsClient.BarcodeProcessingParameters();
	StructureOfActions.Barcodes                              = BarcodeData_5;
	StructureOfActions.StructureOfActionsWithAddedStrings = StructureOfActionsWithAddedStrings;
	StructureOfActions.StructureOfActionsWithModifiedStrings  = StructureOfActionsWithModifiedStrings;
	StructureOfActions.SeriesSpecificationParameters                 = SeriesSpecificationParameters;
	StructureOfActions.CalculateSets                     = True;
	StructureOfActions.GoodsOnly                           = True;
	
	If ControlProductRange Then
		AssortmentInspectionStructure = ProductRangeClientServer.AssortmentVerificationParameters();
		AssortmentInspectionStructure.Ref = Object.Ref;
		AssortmentInspectionStructure.Warehouse = Object.DestinationWarehouse;
		AssortmentInspectionStructure.Date = ?(ValueIsFilled(Object.RequestedDeliveryDate), Object.RequestedDeliveryDate, Object.Date);
		AssortmentInspectionStructure.MessageText = NStr("vi = 'Hàng hóa %1 không thuộc phân loại của cửa hàng nhận. Không nên đặt mặt hàng này.';
														|ru = 'Товар %1 не включен в ассортимент магазина-получателя. Заказывать его не рекомендуется.';
														|en = 'Product %1 is not included in the receiving store''s product range. It is not recommended that you order it.'; fa = 'Product %1 is not included in the receiving store''s product range. It is not recommended that you order it.';
														|it = 'La merce %1 non è inclusa nell''assortimento del negozio-destinatario. Ordinarla non è consigliabile.';
														|pl = 'Towar %1 nie jest włączony do asortymentu sklepu odbiorcy. Jego zamawianie nie jest zalecane.';
														|tr = 'Ürün %1 alıcı mağazanın ürün yelpazesine dahil değildir. Sipariş önerilmemektedir.'");
		AssortmentInspectionStructure.NameOfAssortmentResource = "PurchasesAreAllowed";
		AssortmentInspectionStructure.CheckedYouCanAdd = True;
		AssortmentInspectionStructure.AllowAdding = True;
		//
		StructureOfActions.AssortmentVerificationParameters = AssortmentInspectionStructure;
	EndIf;
	
	ProcessBarcodesServer(StructureOfActions, CachedValues);
	
	ProvisionInDocumentsClientServer.FillInServiceDetails(Object.Goods, DateOfShipmentRequired_, WarehouseIsRequired);
	
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
		"SupplyOption,WarehouseIsRequired,DateOfShipmentRequired_");
	
	BarcodingOfItemsServer.ProcessBarcodes(ThisObject, Object, StructureOfActionParameters, CachedValues);
	
	ProvisionInDocumentsClientServer.RemoveCollateralActions(StructureOfActionParameters.StructureOfActionsWithAddedStrings);
	
	UpdateColumnAvailableServer();
	
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

&AtServer
Procedure PrepareFillSetSeriesVisibility()
	
	SeriesSpecificationParameters = New FixedStructure(ProductsServer.SeriesSpecificationParameters(Object, Documents.TransferOrder));
	ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);
	Items.GoodsSeries.Visible = SeriesSpecificationParameters.UseItemsBatch;
	
EndProcedure

#EndRegion

#Region FormItemsManagement

&AtServer
Procedure FormItemsManagement()
	
	Var ArrayOfAllProps;
	Var ArrayOfOperationDetails;
	
	Documents.TransferOrder.FillInNamesOfBusinessTransactionDetails(
		Object.BusinessOperation,
		ArrayOfAllProps,
		ArrayOfOperationDetails);
	
	CashServer.SetVisibilityOfElementsByArray(
		Items,
		ArrayOfAllProps,
		ArrayOfOperationDetails);
	
	ThisIsTransferOfGoodsBetweenSeparateUnits = (Object.BusinessOperation = Enums.BusinessTransactions.TransferOfGoodsBetweenBranchOffices);
	
	Items.Organization.Title = ?(ThisIsTransferOfGoodsBetweenSeparateUnits,
		NStr("vi = 'Doanh nghiệp-người gửi';
			|ru = 'Организация-отправитель';
			|en = 'Shipping company'; fa = 'شرکت ارسال‌کننده';
			|it = 'Azienda-mittente';
			|pl = 'Shipping company';
			|tr = 'Gönderen iş yeri'"), NStr("vi = 'Doanh nghiệp';
												|ru = 'Организация';
												|en = 'Company'; fa = 'Company';
												|it = 'Azienda';
												|pl = 'Company';
												|tr = 'İş yeri'"));

EndProcedure

&AtServer
Procedure EstablishVisibilityOfQualityControlGroup()
	
	Items.GroupQualityControlIndentation.Visible = Object.LockedGoodsTransfer;
	
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
	
	Columns = "Products,Characteristic,Package,NumberOfPackages,ShipmentStart, ProductsInSet, ItemVariantOfSet";
	
	TableOfGoods = ProcessingOfTabularForms.RowsFromClipboard(FilterParameters, Columns);
	
	If Not ValueIsFilled(TableOfGoods) Then
		Return;
	EndIf;
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInCheckQualityDateOfQualityConfirmation", CacheQualityControl);
	StructureOfActions.Insert("FillInUnblockableDateOfQualityConfirmation", CacheQualityControl);
	AddCollateralActionsOnServer(StructureOfActions, "SupplyOption,WarehouseIsRequired,DateOfShipmentRequired_");
	AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions);
	RowsToProcess = New Array;
		
	For Each RowOfProduct In TableOfGoods Do
		
		CurrentRow = Object.Goods.Add();
		FillPropertyValues(CurrentRow, RowOfProduct);
		
		If Not Object.UseTransferDuration Then
			CurrentRow.ReceiptEnd = CurrentRow.ShipmentStart;
		EndIf;
		
		CurrentRow.SetIndex = ?(ValueIsFilled(CurrentRow.ProductsInSet), 1, 0);
		RowsToProcess.Add(CurrentRow);
		
	EndDo;
	
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		RowsToProcess,
		StructureOfActions,
		Object.Goods);
	
	ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);
	UpdateColumnAvailableServer();
	
	FillInServiceDetailsForProductRange();
	ReusablePackageServer.UpdateFillingStateOfMultiTurnContainer(Object.ReusablePackageFillingStatus);

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

#Region Sets

&AtServer
Function AddToFullSet()
	
	TabularSection = Object.Goods;
	SelectedRows = Items.Goods.SelectedRows;
	
	RowsArray = New Array;
	For Each CurRow In SelectedRows Do
		TableRow = TabularSection.FindByID(CurRow);
		RowsArray.Add(TableRow);
	EndDo;
	
	SetsServerCall.AddToFullSet(TabularSection, RowsArray);
	
	Result = New Array;
	For Each TSRow In RowsArray Do
		Result.Add(TSRow.GetID());
	EndDo;
	
	Return Result;
	
EndFunction

&AtClientAtServerNoContext
Function DialColumns(Form)
	
	Columns = New Array;
	Columns.Add("Products");
	Columns.Add("Characteristic");
	
	Columns.Add("Package");
	Columns.Add("Count");
	Columns.Add("NumberOfPackages");
	Columns.Add("Canceled");
	
	Return Columns;
	
EndFunction

&AtClient
// Called via the description of the message from the general module setclient 
Procedure WhenRemovingComponents(Action, AdditionalParameter) Export
	
	If SetsClient.EditSetAction(Action) Then
		SetsClient.WhenRemovingComponents(ThisForm, "Goods", AdditionalParameter);
	ElsIf SetsClient.DeleteEntireSetAction(Action) Then
		WhenRemovingComponentsOnServer("Goods", AdditionalParameter);
	EndIf;
	
EndProcedure

&AtServer
Procedure WhenRemovingComponentsOnServer(TSName, AdditionalParameter)
	SetsServer.WhenRemovingComponents(ThisForm, TSName, AdditionalParameter);
EndProcedure

&AtServer
Function SetAddressInTemporaryStorage(Var_Parameters)
	
	Return SetsServer.SetAddressInTemporaryStorage(ThisForm, Var_Parameters, "Goods");
	
EndFunction

&AtServer
Procedure AtEndOfEditingSet(AddressInTempStorage)
	
	StructureOfActionsWithAddedStrings = New Structure;
	StructureOfActionsWithAddedStrings.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
	StructureOfActionsWithAddedStrings.Insert("FillInFeatureAttribute", New Structure("Products", "ItemVariantsAreUsed"));
	StructureOfActionsWithAddedStrings.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));
	StructureOfActionsWithAddedStrings.Insert("WhenChangingProductType", New Structure("ThereAreWorks, IsCanceled", True, False));
	StructureOfActionsWithAddedStrings.Insert("FillInCheckQualityDateOfQualityConfirmation", CacheQualityControl);
	StructureOfActionsWithAddedStrings.Insert("FillInUnblockableDateOfQualityConfirmation", CacheQualityControl);
	
	StructureOfActionsWithModifiedStrings = New Structure;
	StructureOfActionsWithModifiedStrings.Insert("FillInCheckQualityDateOfQualityConfirmation", CacheQualityControl);
	StructureOfActionsWithModifiedStrings.Insert("FillInUnblockableDateOfQualityConfirmation", CacheQualityControl);
	
	DataParameters = New Structure;
	DataParameters.Insert("Data", GetFromTempStorage(AddressInTempStorage));
	DataParameters.Insert("StructureOfActionsWithModifiedStrings", StructureOfActionsWithModifiedStrings);
	DataParameters.Insert("StructureOfActionsWithAddedStrings", StructureOfActionsWithAddedStrings);
	DataParameters.Insert("DialColumns", DialColumns(ThisForm));
	
	SetsServer.AtEndOfEditingSet(ThisForm, "Goods", DataParameters);
	
	FormEvents.WhenChangingElement(ThisObject, "Goods");
	
EndProcedure

#EndRegion

#Region Supply

&AtServer
Function ThereIsAccessToSenderWarehouse()
	
	If ValueIsFilled(Object.SourceWarehouse) Then
		
		If Not AccessRight("Read", Object.SourceWarehouse.Metadata()) Then
			Return False;
		EndIf;
		Query = New Query(
			"SELECT ALLOWED
			|	TRUE AS ThereAreRecords
			|FROM
			|	Catalog.Warehouses AS Warehouses
			|WHERE
			|	Warehouses.Ref = &Ref");
		Query.SetParameter("Ref", Object.SourceWarehouse);
		Return Not Query.Execute().IsEmpty();
		
	EndIf;
	
	Return True;
	
EndFunction

&AtServer
Procedure SetSoftwareAvailability()
	
	Items.GoodsShip.Enabled = ThereIsAccessToSenderWarehouse;
	Items.GoodsToReserve_.Enabled = ThereIsAccessToSenderWarehouse;
	Items.GoodsReserveAsReceived.Enabled = ThereIsAccessToSenderWarehouse;
	Items.GoodsToSupply.Enabled = ThereIsAccessToSenderWarehouse;
	Items.GoodsNotProvide.Enabled = ThereIsAccessToSenderWarehouse;
	Items.GoodsContextMenuShip.Enabled = ThereIsAccessToSenderWarehouse;
	Items.GoodsContextMenuToReserve_.Enabled = ThereIsAccessToSenderWarehouse;
	Items.GoodsContextMenuReserveAsReceived.Enabled = ThereIsAccessToSenderWarehouse;
	Items.GoodsContextMenuToSupply.Enabled = ThereIsAccessToSenderWarehouse;
	Items.GoodsContextMenuNotProvide.Enabled = ThereIsAccessToSenderWarehouse;
	Items.GoodsAvailable.Visible = ThereIsAccessToSenderWarehouse;
	
EndProcedure

&AtClient
Procedure ItemsAreCollateralOptionWhenChangedOnClient(Result, AdditionalParameters) Export
	
	WhatIsSoftwareOptionWhenChangingOnServer();
	
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
	
	CheckParameters = SupplyClientServer.InitializeFillVerificationParameters();
	CheckParameters.Fields.Warehouse = "Object.SourceWarehouse";
	CheckParameters.Texts.Warehouse = NStr("vi = 'Chưa điền trường ""Kho gửi""';
											|ru = 'Поле ""Склад-отправитель"" не заполнено';
											|en = '""Origin warehouse"" is not filled in'; fa = '""Origin warehouse"" is not filled in';
											|it = 'Il campo ""Magazzino-mittente"" non è compilato';
											|pl = 'Nie wypełniono pola ""Magazyn wysyłki""';
											|tr = '""Çıkış ambarı"" alanı doldurulmadı'");
	
	If Not SupplyClient.CheckFilling(
				Object,
				Object.Goods,
				Items.Goods.CurrentRow,
				CheckParameters,
				Object.SourceWarehouse,
				Mode) Then
		Return Undefined;
	EndIf;
	
	FormParameters = SoftwareSelectionParameters(Mode);
	FormParameters.SeriesSpecificationParameters = SeriesSpecificationParameters;
	
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
Function DocumentParametersForSoftwareActions(Form, SecurityOptionAndFlagSeparately)
	
	DocumentParameters = New Structure();
	DocumentParameters.Insert("Form",                              Form);
	DocumentParameters.Insert("Collection",                          Form.Object.Goods);
	DocumentParameters.Insert("SecurityOptionAndFlagSeparately", SecurityOptionAndFlagSeparately);
	
	Return DocumentParameters;
	
EndFunction

&AtClient
Procedure HyperlinkStateOfProvisionClickGeneral()
	
	FormParameters = ProvisionInDocumentsClient.SecurityStatusHyperlinkClick(ThisObject);
	
	If Object.Status = PredefinedValue("Enum.InternalOrderStatuses.AwaitingApproval") Then
		
		FormParameters.AcceptableSecurityOptions = ProvisionInDocumentsClient.AllValidSecurityOptions();
		FormParameters.AcceptableSecurityOptions.Delete(
			PredefinedValue("Enum.SupplyOptions.FromWarehouse"));
		FormParameters.AcceptableSecurityOptions.Delete(
			PredefinedValue("Enum.SupplyOptions.Ship"));
		
	EndIf;
	
	If FormParameters.ContextOfUse = "TABLE" Then
		
		FormParameters.AddressOfTheMovementTable = AddressOfMovementTableInRepository();
		
	EndIf;
	
	OpenForm("DataProcessor.OrderSupplyForecast.Form", FormParameters, ThisObject, UUID,,,,
		FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure AddCollateralActionsOnClient(StructureOfActions, StringFields_)
	
	DocumentParameters = DocumentParametersForSoftwareActions(ThisObject, SecurityOptionAndFlagSeparately);
	ProvisionInDocumentsClientServer.AddCollateralActions(StructureOfActions, StringFields_, DocumentParameters);
	
EndProcedure

&AtServer
Procedure AddCollateralActionsOnServer(StructureOfActions, StringFields_)
	
	DocumentParameters = DocumentParametersForSoftwareActions(ThisObject, SecurityOptionAndFlagSeparately);
	ProvisionInDocumentsClientServer.AddCollateralActions(StructureOfActions, StringFields_, DocumentParameters);
	
EndProcedure

&AtServer
Procedure FillInServiceDetailsOfDocumentForm()
	
	DocumentParameters = DocumentParametersForSoftwareActions(ThisObject, SecurityOptionAndFlagSeparately);
	ProvisionInDocumentsServer.FillInServiceDetailsOfDocumentForm(DocumentParameters);
	
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
	
	If FormModified <> Modified Then
		
		FormModified = Modified;
		ProvisionInDocumentsClient.ConfigureHyperlinkedSoftwareState(ThisObject);
		
	EndIf;
	
EndProcedure

&AtServer
Procedure AfterFillingOutCollateral(Changes, Mode = Undefined, FillParameters = Undefined)
	
	Documents.TransferOrder.AfterFillingOutCollateral(Object, Changes, Mode, FillParameters);
	
	StructureOfActions = New Structure();
	AddCollateralActionsOnServer(StructureOfActions, "WarehouseIsRequired,DateOfShipmentRequired_");
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
	
	ProvisionInDocumentsClientServer.FillInServiceDetails(Object.Goods, DateOfShipmentRequired_, WarehouseIsRequired);
	UpdateColumnAvailableServer();
	
EndProcedure

&AtServer
Procedure UpdateColumnAvailableServer()
	
	ProvisionInDocumentsServer.UpdateColumnAvailable(ThisObject);
	
EndProcedure

&AtClient
Procedure ProcessWarehouseAndBatchSelection(ValueSelected, FormParameters) Export
	
	If Not ProvisionInDocumentsClient.ThereAreSelectedProducts(ValueSelected) Then
		Return;
	EndIf;
	
	Notification = ProcessWarehouseAndBatchSelectionOnServer(ValueSelected, FormParameters);
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

#EndRegion

#Region Delivery

&AtServer
Procedure FillInAndSetDeliveryAttributesServer(FormItemName);
	
	GoodsDelivery.FillInDeliveryDetails(Items, FormItemName, Object);
	
EndProcedure

&AtClient
Procedure ProcessAddressChange(Item, NameOfAddressDetails)
	
	AttributesNames = GoodsDeliveryClientServer.NamesOfDetailsOfDeliveryAddresses(NameOfAddressDetails);
	
	If IsBlankString(Object[AttributesNames.NameOfDetailsOfDeliveryAddress]) Then
		
		GoodsDeliveryClient.ClearAddressPresentation(
			Object[AttributesNames.NameOfDetailsOfDeliveryAddress],
			Object[AttributesNames.AttributeNameOfDeliveryAddressFieldValues],
			Object[AttributesNames.NameOfAttributeOfDeliveryAddressValue]);
		
	Else
		
		GoodsDeliveryClient.WhenChangingAddressPresentation(
			Item,
			Object[AttributesNames.NameOfDetailsOfDeliveryAddress],
			Object[AttributesNames.NameOfAttributeOfDeliveryAddressValue]);
		
		DeliveryAddressOnChangeATServer(
			Object[AttributesNames.NameOfDetailsOfDeliveryAddress],
			Object[AttributesNames.NameOfAttributeOfDeliveryAddressValue],
			Object[AttributesNames.AttributeNameOfDeliveryAddressFieldValues]);
		
	EndIf;
	
EndProcedure

&AtServer
Procedure DeliveryAddressOnChangeATServer(Address, AddressValue, FieldValueAddress)
	
	CustomFormatAddress = ContactsManager.AddressEnteredInFreeFormat(AddressValue);
	If Not CustomFormatAddress Then
		
		CountryData1 = ContactsManager.ContactInformationAddressCountry(AddressValue);
		
		NewAddressStructure = ContactsManager.InfoAboutAddress();
		NewAddressStructure.Presentation = Address;
		NewAddressStructure.Country = CountryData1.Description;
		NewAddressStructure.CountryCode = CountryData1.Code;
		
		AddressValue = ContactsManager.ContactInformationInJSON(
			NewAddressStructure,
			Enums.ContactInformationTypes.Address);
		
		SetAddressTypeInFreeForm(AddressValue);
		
	EndIf;
	
	FieldValueAddress = ContactsManager.ContactInformationToXML(
		AddressValue,
		Address,
		Enums.ContactInformationTypes.Address);
	
EndProcedure

&AtServerNoContext
Procedure SetAddressTypeInFreeForm(DeliveryAddressValue)
	
	StringTypeToReplace = """addressType"": ""Administrative-territorial""";
	StringIsFreeType = """addressType"": ""FreeForm""";
	DeliveryAddressValue = StrReplace(DeliveryAddressValue, StringTypeToReplace, StringIsFreeType);
	
EndProcedure

#EndRegion

#Region Other

&AtServer
Procedure SetSoftwareVisibility()
	
	HasRight = ProvisionInDocumentsServer.HaveRightToViewStateHyperlink()
		And ThereIsAccessToSenderWarehouse;
	Items.PagesHyperlinkSoftwareStatus.Visible = HasRight And Not Object.LockedGoodsTransfer;
	Items.GoodsToSupply.Visible = Not Object.LockedGoodsTransfer;
	Items.GoodsNotProvide.Visible = Not Object.LockedGoodsTransfer;
	Items.GoodsContextMenuToSupply.Visible = Not Object.LockedGoodsTransfer;
	Items.GoodsContextMenuNotProvide.Visible = Not Object.LockedGoodsTransfer;
	
	If Not AccessRight("Insert", Metadata.Documents.InventoryAssignmentAdjustment)
		Or Not GetFunctionalOption("UseOrderSupplyWithAssignment")
		Or Object.LockedGoodsTransfer Then
		Items.GoodsCreateAssignmentAdjustmentRemoveFromReserve.Visible = False;
		Items.GoodsCreateAnAssignmentAdjustmentReservation.Visible = False;
	EndIf;
	
	ProvisionInDocumentsServer.ConfigureHyperlinkedSoftwareState(ThisObject);
	
EndProcedure

&AtClient
Procedure Attachable_CloseForm()
	
	Close();
	
EndProcedure

&AtServer
Procedure FillMultiTurnContainersFromStorageServer(AddressOfContainerInStorage)
	
	ActionStructureModifiedStrings = New Structure;
	ActionStructureModifiedStrings.Insert("RecalculateNumberOfPackages");
	StructureOfActionsAddedLines = New Structure;
	StructureOfActionsAddedLines.Insert("RecalculateNumberOfPackages");
	StructureOfActionsAddedLines.Insert("FillInCheckQualityDateOfQualityConfirmation", CacheQualityControl);
	StructureOfActionsAddedLines.Insert("FillInUnblockableDateOfQualityConfirmation", CacheQualityControl);
	AddCollateralActionsOnServer(StructureOfActionsAddedLines, "SupplyOption,WarehouseIsRequired,DateOfShipmentRequired_");
	
	ReusablePackageServer.FillMultiTurnContainersFromStorage(
		Object,
		AddressOfContainerInStorage,
		"Goods",
		"Products,Characteristic,,ShipmentStart",
		ActionStructureModifiedStrings,
		StructureOfActionsAddedLines);
	
	If Not Object.UseTransferDuration Then
		For Each TableRow In Object.Goods Do
			TableRow.ReceiptEnd = TableRow.ShipmentStart;
		EndDo;
	EndIf;
	
	FillInServiceDetailsForProductRange();
	
	ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);
	ReusablePackageServer.UpdateFillingStateOfMultiTurnContainer(Object.ReusablePackageFillingStatus);
	UpdateColumnAvailableServer();
	
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
	
	SetsServer.FillInServiceDetails(ThisForm);
	
EndProcedure

&AtClient
Procedure FillInTheEndOfReceiptCompletion(Date, AdditionalParameters) Export
	
	If Date = Undefined Then
		Return;
	EndIf;
	FillInEndOfReceiptOnServer(Date);
	
EndProcedure

&AtServer
Procedure FillInEndOfReceiptOnServer(ReceiptEnd)
	
	RowsToProcess = New Array();
	
	TransferDurationDays = Object.TransferDurationDays * 86400;
	
	SelectedRows = Items.Goods.SelectedRows;
	
	For Each Id In SelectedRows Do
		TSRow = Object.Goods.FindByID(Id);
		RowsToProcess.Add(TSRow);
		TSRow.ShipmentStart = ReceiptEnd - TransferDurationDays;
		TSRow.ReceiptEnd = ReceiptEnd;
	EndDo;
	
	StructureOfActions = New Structure();
	StructureOfActions.Insert("FillInCheckQualityDateOfQualityConfirmation", CacheQualityControl);
	StructureOfActions.Insert("FillInUnblockableDateOfQualityConfirmation", CacheQualityControl);
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		RowsToProcess,
		StructureOfActions,
		Object.Goods,
		Undefined);
	
	Modified = True;
	
EndProcedure

&AtClient
Procedure NotifyAboutDocument(WriteParameters)

	NotificationParameters = New Structure;
	NotificationParameters.Insert("WriteMode",      WriteParameters.WriteMode);
	NotificationParameters.Insert("ThereIsOrder_", True);

	Notify("Write_TransferOrder", NotificationParameters, Object.Ref);

EndProcedure

&AtServer
Procedure SetOrganizationSelectionParameters()
	
	ParametersArray = New Array;
	
	If Object.BusinessOperation = Enums.BusinessTransactions.TransferOfGoodsBetweenBranchOffices Then
		ParametersArray.Add(New ChoiceParameter("ModeForSelectingRelatedOrganizations", "OnlyInterconnected"));
	EndIf;
	
	Items.Organization.ChoiceParameters = New FixedArray(ParametersArray);
	
EndProcedure

#Region CancelLines

&AtClient
Procedure CancelUnprocessed(Command)
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.StartTimeMeasurement(True,
		"Document.TransferOrder.DocumentForm.Command.CancelUnprocessed");
	
	CancellationResult = CancelUnprocessedServer();
	ShowUserNotification(NStr("vi = 'Hủy bỏ hàng không được xử lý';
								|ru = 'Отмена неотработанных строк';
								|en = 'Cancel unfulfilled lines'; fa = 'Cancel unfulfilled lines';
								|it = 'Annullamento delle righe non elaborate';
								|pl = 'Anulowanie nieprzetworzonych wierzszy';
								|tr = 'İşlenmemiş satır iptali'"), , CancellationResult.Notification);
	
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
		"Document.TransferOrder.DocumentForm.Command.CancelSelectedLines");
	
	CancelSelectedLinesServer();
	ProvisionInDocumentsClientServer.FillInServiceDetails(Object.Goods, DateOfShipmentRequired_, WarehouseIsRequired);
	
	ShowUserNotification(NStr("vi = 'Hủy các dòng được tô sáng';
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
	
	SelectedRows = AddToFullSet();
	
	StructureOfActions = New Structure;
	AddCollateralActionsOnServer(StructureOfActions, "WarehouseIsRequired,DateOfShipmentRequired_");
	StructureOfActions.Insert("FillInCheckQualityDateOfQualityConfirmation", CacheQualityControl);
	StructureOfActions.Insert("FillInUnblockableDateOfQualityConfirmation", CacheQualityControl);
	CachedValues = Undefined;
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
	
	ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);
	UpdateColumnAvailableServer();
	
EndProcedure

#EndRegion

#EndRegion

&AtServer
Function AdjustOrderLines(StructureOfAdditionalParameters)
	
	OrderObject = FormAttributeToValue("Object");
	
	StructureOfAdditionalParameters.CheckBalance = True;
	
	ResultStructure1 = OrderObject.AdjustOrderLines(StructureOfAdditionalParameters);
	
	RowsToProcess = Object.Goods.FindRows(New Structure("Canceled", True));
	StructureOfActions = New Structure();
	StructureOfActions.Insert("FillInCheckQualityDateOfQualityConfirmation", CacheQualityControl);
	StructureOfActions.Insert("FillInUnblockableDateOfQualityConfirmation", CacheQualityControl);
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		RowsToProcess,
		StructureOfActions,
		Object.Goods,
		Undefined);
	
	If StructureOfAdditionalParameters.CloseOrders Then
		OrderObject.Status = Enums.InternalOrderStatuses.Closed;
	EndIf;
	
	ValueToFormAttribute(OrderObject, "Object");
	
	FillInServiceDetailsForProductRange();
	FillInServiceDetailsOfDocumentForm();
	UpdateColumnAvailableServer();
	
	Modified = True;
	
	Return ResultStructure1;
	
EndFunction

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

&AtClient
Procedure SpecialTransportationConditionsOnChange(Item)
	
	SpecialTransportationConditionsOnChangeServer();
	
EndProcedure

&AtClient
Procedure SupplementDeliveryInformationWithContacts(Command)
	
	SupplementDeliveryInformationWithContactsServer();
	
EndProcedure

&AtServer
Procedure SpecialTransportationConditionsOnChangeServer()
	
	GoodsDelivery.SpecialTransportationConditionsOnChange(Items, Object);
	
EndProcedure

&AtServer
Procedure SupplementDeliveryInformationWithContactsServer()
	
	GoodsDelivery.SupplementDeliveryInformationWithContacts(Object);
	
EndProcedure

&AtServer
Procedure SetVisibilityOfDurationUsageElements()
	
	If Object.UseTransferDuration Then
		Items.GoodsShipmentStart.Title = NStr("vi = 'Bắt đầu giao hàng';
												|ru = 'Начало отгрузки';
												|en = 'Shipment start'; fa = 'شروع ارسال';
												|it = 'Inizio della spedizione';
												|pl = 'Początek wysyłki';
												|tr = 'Sevkiyat başlangıcı'");
	Else
		Items.GoodsShipmentStart.Title = NStr("vi = 'Ngày giao hàng';
												|ru = 'Дата отгрузки';
												|en = 'Shipment date'; fa = 'تاریخ ارسال';
												|it = 'Data di spedizione';
												|pl = 'Data wysyłki';
												|tr = 'Sevkiyat tarihi'");
	EndIf;
	
	Items.TransferDurationDays.ReadOnly = Not Object.UseTransferDuration;
	Items.GoodsReceiptEnd.Visible = Object.UseTransferDuration;
	
	Items.FillInTheEndOfReceipt.Title = ?(Object.UseTransferDuration,
		NStr("vi = 'Điền kết thúc tiếp nhận';
			|ru = 'Заполнить окончание поступления';
			|en = 'Populate receipt end'; fa = 'Populate receipt end';
			|it = 'Compilare il termine dell''arrivo';
			|pl = 'Wypełnia zakończenie wpływu';
			|tr = 'Giriş bitişini doldur'"),
		NStr("vi = 'Điền ngày giao hàng';
			|ru = 'Заполнить дату отгрузки';
			|en = 'Fill in shipment date'; fa = 'تکمیل تاریخ ارسال';
			|it = 'Compila la data di spedizione';
			|pl = 'Wypełnij datę wysyłki';
			|tr = 'Sevkiyat tarihini doldur'"));
		
EndProcedure

&AtClient
Procedure Attachable_ProcessObjectEntry()
	
	TMCommonUseClient.ProcessObjectEntryInForm(ThisObject, ParametersForRecording);
	
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
