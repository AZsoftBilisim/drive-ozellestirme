
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
	
	EmbeddingParameters = Documents.OrderOfMaterialsForProduction.AvailableRemainingEmbeddingOptions();
	ProvisionInDocumentsServer.AvailableBalancesWhenCreatedOnServer(ThisObject, EmbeddingParameters);
	
	SetConditionalAppearance();
	
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;

	InfobaseUpdate.CheckObjectProcessed(Object, ThisObject);
	
	TMCommonUse.CustomizePeripherals(ThisForm);
	
	// Handler of the "Versioning of objects" mechanism
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	
	If Not ValueIsFilled(Object.Ref) Then
		OnReadCreateAtServer();
		ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);
	EndIf;
	
	// StandardSubsystems.Properties
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("ItemForPlacementName", "GroupAdditionalAttributes");
	PropertyManager.OnCreateAtServer(ThisObject, AdditionalParameters);
	// End StandardSubsystems.Properties
	
	// Handler of the "Destination" mechanism
	Catalogs.Assignments.DocumentFormWhenCreatedOnServer(ThisForm);
	
	Items.CloseOrder.Enabled = AccessRight("Update", Metadata.Documents.OrderOfMaterialsForProduction);
	
	SetAvailabilityOfClipboardCommands();
	
	// Setting the list of available statuses
	Enums.StatusesOfOrdersForMaterialsForProduction.FillChoiceList(Items.Status.ChoiceList);

	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject);
	// End IntegrationWith1CDocumentManagementSubsystem

	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	SetVisibilityOfInputCommandsBasedOn_();

	// StandardSubsystems.FilesOperations
	HyperlinkParameters = FilesOperations.FilesHyperlink();
	HyperlinkParameters.Location = "CommandBar";
	FilesOperations.OnCreateAtServer(ThisObject, HyperlinkParameters);
	// End StandardSubsystems.FilesOperations
	
	sh_ShamsiInit(); // sh_ShamsiInit
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
Procedure BeforeClose(Cancel, StandardProcessing)
	
	ForceCloseTheForm = True;
	
EndProcedure

&AtClient
Procedure OnClose()
	
	EquipmentManagerClient.StartDisablingHardwareWhenClosingForm(Undefined, ThisForm);
	
EndProcedure

&AtClient
Procedure ChoiceProcessing(ValueSelected, ChoiceSource)
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.TimeMeasurement(
		"Document.OrderOfMaterialsForProduction.Form.DocumentForm.Event.ChoiceProcessing");
	
	If ChoiceSource.FormName = "DataProcessor.OrderSupplyForecast.Form.Form" Then
		
		AddressOfTheMovementTable = FillInCollateralFromCollateralStateForm(
			ValueSelected.ActionCode,
			ValueSelected.AddressAnalyst,
			ValueSelected.FillParameters);
			
		// Returning the control to the form of processing the security status.
		RunCallback(ValueSelected.Callback, AddressOfTheMovementTable);
	ElsIf ChoiceSource.FormName = "Document.EngineeringChangeOrder.Form.SubstitutionOfMaterialsWithAlternativeMaterials" Then
		
		Replace_With_Analogues(ValueSelected.AddressInStorage);
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
	
	EmbeddingParameters = Documents.OrderOfMaterialsForProduction.AvailableRemainingEmbeddingOptions();
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
	FillInServiceDetailsOfSupply();
	ProvisionInDocumentsServer.AfterWriteAtServer(ThisObject);
	SetSoftwareVisibility();
	
	ConfigureDependentFormElements(ThisForm);
	If RightToReadSubstitutes And ShowAnalogues Then
		NotePresenceOfAnalogues();
	EndIf;
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
Procedure BeforeLoadDataFromSettingsAtServer(Settings)
	
	If Not Object.Ref.IsEmpty() Then
		Settings.Delete("Object.NotShipInInstallments");
	EndIf;
	
EndProcedure

&AtServer
Procedure OnLoadDataFromSettingsAtServer(Settings)
	
	SetVisibilityOfShipmentReceiptDateElements();
	
	AttributesList = "";
	If RightToReadSubstitutes And ShowAnalogues Then
		
		AttributesList = 
			AttributesList + ?(ValueIsFilled(AttributesList), ",", "") + "ShowAnalogues";
		
		NotePresenceOfAnalogues();
		
	EndIf;
	If ValueIsFilled(AttributesList) Then
		ConfigureDependentFormElements(ThisForm, AttributesList);	
	EndIf;
	
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
	
	UpdateConsumptionForActivities();
	
EndProcedure

&AtClient
Procedure StatusOnChange(Item)
	
	StatusOnChangeServer();
	
EndProcedure

&AtClient
Procedure OrganizationOnChange(Item)
	
	OrganizationOnChangeServer()
	
EndProcedure

&AtClient
Procedure WarehouseOnChange(Item)
	
	WarehouseOnChangeServer();
	
EndProcedure

&AtClient
Procedure ShopFloorStockroomOnChange(Item)
	
	ShopPantryWhenChangingOnServer(True);
	
EndProcedure

&AtClient
Procedure DateOfShipmentOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	
	FillInShipmentDateServer(Object.DateOfShipment, Undefined);
	
EndProcedure

&AtClient
Procedure NotShipInInstallmentsOnChange(Item)
	
	NotShipInInstallmentsOnChangeServer();
	
EndProcedure

&AtClient
Procedure UseTransferDurationOnChange(Item)
	
	If Object.UseTransferDuration Then
		Object.TransferDurationDays = TransferDurationDays;
	Else
		TransferDurationDays = Object.TransferDurationDays;
		Object.TransferDurationDays = 0;
	EndIf;
	
	UseDurationOfMoveOnChangeAtServer();
	
EndProcedure

&AtClient
Procedure TransferDurationDaysOnChange(Item)
	
	DurationOfMovementOnChangeATServer();
	
EndProcedure

&AtClient
Procedure LineOfBusinessOnChange(Item)
	
	LineOfBusinessOnChangeServer();
	
EndProcedure

&AtClient
Procedure ConsumptionForActivityClearing(Item, StandardProcessing)
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

#Region FormTableItemsEventHandlersGoods

&AtClient
Procedure GoodsSelection(Item, RowSelected, Field, StandardProcessing)
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.TimeMeasurement(
		"Document.OrderOfMaterialsForProduction.Form.DocumentForm.Items.Goods.Selection");
	
	If Item.CurrentItem = Items.GoodsAvailable And Not ReadOnly Then
		
		StandardProcessing = False;
		
		FormParameters = ParametersOfQuantityAndSeriesRequestForm(Undefined);
		
		If FormParameters <> Undefined Then
			OpenForm("DataProcessor.QuantityAndBatchRequest.Form", FormParameters, ThisObject);
		EndIf;
	ElsIf Field = Items.GoodsThereAreSubstituteMaterials And Not ReadOnly Then
		
		StandardProcessing = False;
		OpenSelectionOfAnalogues();
	EndIf;
	
EndProcedure

&AtClient
Procedure GoodsProductsOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("CheckCharacteristicsByOwner", CurrentRow.Characteristic);
	StructureOfActions.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));
	StructureOfActions.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
	StructureOfActions.Insert("CheckFillPackageByOwner", CurrentRow.Package);
	StructureOfActions.Insert("RecalculateNumberOfUnits");
	StructureOfActions.Insert("CheckSeriesCalculateStatus", New Structure("Warehouse, SeriesSpecificationParameters", Object.Warehouse, SeriesSpecificationParameters));
	AddCollateralActionsOnClient(StructureOfActions, "SupplyOption,AvailableInOtherLines,WarehouseIsRequired,DateOfShipmentRequired_");
	AddQualityControlActionsToStructure(StructureOfActions, CacheQualityControl, Object.ProductionManagement2_2);
	
	StructureOfActions.Insert("ProductsOnChangeOverridable", New Structure("FormName, TabularSectionName",
		ThisForm.FormName, "Goods"));

	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	ProvisionInDocumentsClientServer.FillInServiceDetails(Object.Goods, DateOfShipmentRequired_, WarehouseIsRequired);
	
	NeedServerCall = False;
	If ProvisionInDocumentsClient.YouNeedToUpdateAvailableColumn(StructureOfActions) Then
		NeedServerCall = True;
	EndIf;
	If RightToReadSubstitutes And ShowAnalogues Then
		NeedServerCall = True;
	EndIf;
	If NeedServerCall Then
		
		GoodsProductsOnChangeServer(Items.Goods.CurrentRow);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure GoodsCharacteristicOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("CharacteristicOnChangeOverridable", New Structure("FormName, TabularSectionName",
		ThisForm.FormName, "Goods"));
	AddCollateralActionsOnClient(StructureOfActions, "SupplyOption,AvailableInOtherLines,WarehouseIsRequired,DateOfShipmentRequired_");
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	ProvisionInDocumentsClientServer.FillInServiceDetails(Object.Goods, DateOfShipmentRequired_, WarehouseIsRequired);
	
	NeedServerCall = False;
	If ProvisionInDocumentsClient.YouNeedToUpdateAvailableColumn(StructureOfActions) Then
		NeedServerCall = True;
	EndIf;
	If RightToReadSubstitutes And ShowAnalogues Then
		NeedServerCall = True;
	EndIf;
	If NeedServerCall Then
		
		GoodsCharacteristicOnChangeServer(Items.Goods.CurrentRow);
		
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
		AddCollateralActionsOnClient(StructureOfActions, "SupplyOption,Available,WarehouseIsRequired,DateOfShipmentRequired_");
		StructureOfActions.Insert("CheckSeriesCalculateStatus",
			New Structure("Warehouse, SeriesSpecificationParameters", Object.Warehouse, SeriesSpecificationParameters));
		BatchProcessingOfTablePartClient.ProcessTSString(Items.Goods.CurrentData, StructureOfActions, CachedValues);
		ProvisionInDocumentsClientServer.FillInServiceDetails(Object.Goods, DateOfShipmentRequired_, WarehouseIsRequired);
	EndIf;

EndProcedure

&AtClient
Procedure GoodsOnEditEnd(Item, NewRow, CancelEdit)
	
	CurrentData = Item.CurrentData;
	
	If CurrentData <> Undefined
		And Not Object.ProductionManagement2_2
		And Object.NotShipInInstallments Then
		CurrentData.ShipmentStart = Object.DateOfShipment;
	EndIf;
	
	ReusablePackageClient.UpdateFillingStateOfMultiTurnContainer(Object.ReusablePackageFillingStatus);
	
EndProcedure

&AtClient
Procedure GoodsAfterDeleteRow(Item)
	
	ReusablePackageClient.UpdateFillingStateOfMultiTurnContainer(Object.ReusablePackageFillingStatus);
	ProvisionInDocumentsClientServer.FillInServiceDetails(Object.Goods, DateOfShipmentRequired_, WarehouseIsRequired);
	
	ProductsAfterDeletionOnServer();
	
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
	StructureOfActions.Insert("CheckSeriesCalculateStatus", New Structure("Warehouse, SeriesSpecificationParameters", Object.Warehouse, SeriesSpecificationParameters));
	AddCollateralActionsOnClient(StructureOfActions, "WarehouseIsRequired,DateOfShipmentRequired_,AvailableInOtherLines");
	AddQualityControlActionsToStructure(StructureOfActions, CacheQualityControl, Object.ProductionManagement2_2);
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	ProvisionInDocumentsClientServer.FillInServiceDetails(Object.Goods, DateOfShipmentRequired_, WarehouseIsRequired);
	
	NeedServerCall = False;
	If ProvisionInDocumentsClient.YouNeedToUpdateAvailableColumn(StructureOfActions) Then
		NeedServerCall = True;
	EndIf;
	If RightToReadSubstitutes And ShowAnalogues Then
		NeedServerCall = True;
	EndIf;
	If NeedServerCall Then
		
		GoodsCanceledOnChangeServer(Items.Goods.CurrentRow);
		
	EndIf;
	
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
		True,
		"GoodsCollateralOptionWhenChangedAfterIssue");
	
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
Procedure GoodsShipmentStartOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;
	
	StructureOfActions = New Structure;
	AddQualityControlActionsToStructure(StructureOfActions, CacheQualityControl, Object.ProductionManagement2_2);
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
EndProcedure

&AtClient
Procedure GoodsReceiptEndOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;
	
	StructureOfActions = New Structure;
	AddQualityControlActionsToStructure(StructureOfActions, CacheQualityControl, Object.ProductionManagement2_2);
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
Procedure SelectGoods(Command)
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.TimeMeasurement(
		"Document.OrderOfMaterialsForProduction.DocumentForm.Command.SelectGoods");
	
	Cancel = False;
	
	If Cancel Then
		Return;
	EndIf;
	
	FormParameters = New Structure;
	FormParameters.Insert("Warehouse",                                     Object.Warehouse);
	FormParameters.Insert("SelectionModeWithoutAmountParameters",         True);
	FormParameters.Insert("FilterByProductType",                   New FixedArray(ProductsClientServer.SelectionByProductMultiTurnContainer(False)));
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
	FormParameters.Insert("AvailableRemainingDocumentParameters",
		ProvisionInDocumentsClient.AvailableRemainingDocumentParameters(ThisObject));
	If Object.ProductionManagement2_2 Then
		FormParameters.Insert("AvailableRemainingDocumentParameters", Undefined);
	EndIf;
	OpenForm("DataProcessor.SelectGoodsToSalesDocument.Form", FormParameters, ThisForm, UUID);
	
EndProcedure

&AtClient
Procedure HandlingSelectionSelectionOnClient(ValueSelected)
	
	If Not ValueIsFilled(ValueSelected) Then
		Return;
	EndIf;
	
	ProvisionInDocumentsClient.ShowQuestionUncheckShipOneDateAfterSelection(
		ThisObject,
		ValueSelected,
		"ProcessingSelectionIsDoneOnClientAfterQuestion");
	
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
		
		AddCollateralActionsOnClient(StructureOfActions,"UpdateProductCache_");
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
Procedure PostDocument(Command)
	
	TMCommonUseClient.Post(ThisForm, True);
	
EndProcedure
// End StandardSubsystems.FilesOperations

&AtClient
Procedure SetDeletionMarkForADocument(Command)
	
	TMCommonUseClient.SetDeletionMarkForADocument(ThisForm);
	
EndProcedure

&AtClient
Procedure PostAndClose(Command)
	
	TMCommonUseClient.PostAndClose(ThisForm, True);
	
EndProcedure

&AtClient
Procedure WriteDocument(Command)
	
	TMCommonUseClient.Write(ThisForm, True);
	
EndProcedure

&AtClient
Procedure FillInTheEndOfReceiptForAllLines(Command)
	
	FillInTheEndOfReceipt();
	
EndProcedure

&AtClient
Procedure FillInTheEndOfReceiptForTheSelectedLines(Command)
	
	If Items.Goods.SelectedRows.Count() > 0 Then
		FillInTheEndOfReceipt(Items.Goods.SelectedRows);
	EndIf;
	
EndProcedure

&AtClient
Procedure FillInTheEndOfReceipt(ArrayOfSelectedRows = Undefined)
	
	ReceiptEnd = Object.RequestedDeliveryDate;
	
	AdditionalParameters = New Structure("ArrayOfSelectedRows, ReceiptEnd", ArrayOfSelectedRows, ReceiptEnd);
	
	ShowInputDate(
		New CallbackDescription("FillInTheEndOfReceiptCompletion", ThisObject, AdditionalParameters),
		ReceiptEnd,
		NStr("vi = 'Hãy nhập ngày kết thúc tiếp nhận';
			|ru = 'Введите дату окончания поступления';
			|en = 'Enter receipt end date'; fa = 'Enter receipt end date';
			|it = 'Inserire la data del termine di arrivo';
			|pl = 'Wprowadź datę zakończenia wpłaty';
			|tr = 'Girişin bitiş tarihini girin'"),
		DateFractions.Date);
	
EndProcedure

&AtClient
Procedure FillInTheEndOfReceiptCompletion(Date, AdditionalParameters) Export
	
	ArrayOfSelectedRows = AdditionalParameters.ArrayOfSelectedRows;
	ReceiptEnd = ?(Date = Undefined, AdditionalParameters.ReceiptEnd, Date);
	
	If (Date <> Undefined) Then
		FillInEndOfReceiptOnServer(ReceiptEnd, ArrayOfSelectedRows);
	EndIf;
	
EndProcedure

&AtServer
Procedure FillInEndOfReceiptOnServer(ReceiptEnd, Val ArrayOfSelectedRows)
	
	DurationInSeconds = Object.TransferDurationDays * 86400;
	
	RowsToProcess = New Array;
	If ArrayOfSelectedRows = Undefined Then
		For Each TSRow In Object.Goods Do
			TSRow.ShipmentStart = ReceiptEnd - DurationInSeconds;
			TSRow.ReceiptEnd = ReceiptEnd;
			RowsToProcess.Add(TSRow);
		EndDo;
	Else
		For Each RowID In ArrayOfSelectedRows Do
			TSRow = Object.Goods.FindByID(RowID);
			TSRow.ShipmentStart = ReceiptEnd - DurationInSeconds;
			TSRow.ReceiptEnd = ReceiptEnd;
			RowsToProcess.Add(TSRow);
		EndDo;
	EndIf;
	
	StructureOfActions = New Structure;
	AddQualityControlActionsToStructure(StructureOfActions, CacheQualityControl, Object.ProductionManagement2_2);
	BatchProcessingOfTablePartServer.ProcessTSStrings(RowsToProcess, StructureOfActions, Object.Goods);
	
	Modified = True;
	
EndProcedure

#Region Supply

&AtClient
Procedure FillInShipmentDate(Command)
	
	ArrayOfSelectedRows = Items.Goods.SelectedRows;
	If ArrayOfSelectedRows.Count() > 0 Then
		DateOfShipment = Object.DateOfShipment;
		
		Notification = New CallbackDescription("FillInShipmentDateCompletion", ThisObject, New Structure("ArrayOfSelectedRows", ArrayOfSelectedRows));
		
		TMCommonUseClient.EnterDateWithControlOfEmptyValue(DateOfShipment, NStr("vi = 'Hãy nhập ngày giao hàng';
																				|ru = 'Введите дату отгрузки';
																				|en = 'Enter shipment date'; fa = 'Enter shipment date';
																				|it = 'Inserire la data di spedizione';
																				|pl = 'Wprowadź datę wysyłki';
																				|tr = 'Sevkiyat tarihini girin'"), DateFractions.Date, Notification);
		
	Else
		WarningText = NStr("vi = 'Trong chứng từ chưa chọn dòng để điền. Sẽ không điền ngày giao hàng.';
							|ru = 'В документе не выбраны строки для заполнения. Дата отгрузки не будет заполнена.';
							|en = 'No lines to fill in are selected in the document. The shipment date will not be filled in.'; fa = 'No lines to fill in are selected in the document. The shipment date will not be filled in.';
							|it = 'Nel documento non sono selezionate le righe per la compilazione. La data di spedizione non verrà compilata.';
							|pl = 'W dokumencie nie wybrano wierszy do wypełnienia. Nie będzie wypełniono daty wysyłki.';
							|tr = 'Belgede doldurulacak herhangi bir satır seçilmedi. Sevkiyat tarihi doldurulmayacaktır.'");
		ShowMessageBox(Undefined, WarningText);
	EndIf;
	
EndProcedure

&AtClient
Procedure FillInShipmentDateCompletion(SelectedDate, AdditionalParameters) Export
	
	If SelectedDate <> Undefined And ValueIsFilled(SelectedDate) Then
		
		DateOfShipment = SelectedDate;
		ArrayOfSelectedRows = AdditionalParameters.ArrayOfSelectedRows;
		
		FillInShipmentDateServer(DateOfShipment, ArrayOfSelectedRows);
		SalesClient.NotifyEndOfFillingInShipmentDates(DateOfShipment, True);
	
	EndIf; 
	
EndProcedure

&AtClient
Procedure CreateAnAssignmentAdjustmentReservation(Command)
	
	ObjectsOfBases = New Array();
	ObjectsOfBases.Add(Object.Ref);
	
	CommandDetails = New Structure();
	CommandDetails.Insert("ObjectsOfBases", ObjectsOfBases);
	
	If Not Object.Posted Or Modified Then
		AdditionalParameters = New Structure();
		AdditionalParameters.Insert("Reservation", True);
		AdditionalParameters.Insert("CommandDetails", CommandDetails);
		
		QueryText = NStr("vi = 'Để trích lập dự phòng theo chỉ định, trước tiên cần kết chuyển chứng từ. Kết chuyển chứng từ và tiếp tục?';
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
	
	ObjectsOfBases = New Array();
	ObjectsOfBases.Add(Object.Ref);
	
	CommandDetails = New Structure();
	CommandDetails.Insert("ObjectsOfBases", ObjectsOfBases);
	
	If Not Object.Posted Or Modified Then
		AdditionalParameters = New Structure();
		AdditionalParameters.Insert("Reservation", False);
		AdditionalParameters.Insert("CommandDetails", CommandDetails);
		
		QueryText = NStr("vi = 'Để hoàn nhập dự phòng theo hỉ định, trước tiên cần kết chuyển chứng từ. Kết chuyển chứng từ và tiếp tục?';
						|ru = 'Для снятия резерва под назначение необходимо предварительно провести документ. Выполнить проведение документа и продолжить?';
						|en = 'To remove the reserve for assignment, post the document first. Post the document and continue?'; fa = 'To remove the reserve for assignment, post the document first. Post the document and continue?';
						|it = 'Per rimuove la prenotazione per destinazione, è necessario innanzitutto registrare il documento. Eseguire la registrazione del documento e continuare?';
						|pl = 'W celu usunięcia rezerwy do przeznaczenia najpierw należy zatwierdzić dokument. Wykonać zatwierdzenie dokumentu i kontynuować?';
						|tr = 'Atama kapsamında rezervin iptali için öncelikle belgenin kaydedilmesi gerekmektedir. Belge onaylansın ve devam edilsin mi?'");
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

#Region Substitutes

&AtClient
Procedure ShowAnalogues(Command)
	ShowAnalogues = Not ShowAnalogues;
	If RightToReadSubstitutes And ShowAnalogues Then
		NotePresenceOfAnalogues();
	EndIf;
	
	ConfigureDependentFormElements(ThisForm, "ShowAnalogues");
	Return; // in UT and KA the handler is empty
	
EndProcedure

&AtClient
Procedure SelectSubstitutes(Command)
	PerformanceMonitorClient.TimeMeasurement(
		"Document.OrderOfMaterialsForProduction.Form.DocumentForm.Command.SelectSubstitutes");
	
	OpenSelectionOfAnalogues();
	Return; // in UT and KA the handler is empty
	
EndProcedure

&AtClient
Procedure ReplaceWithAnalogues(Command)
	Replace_With_Analogues();
	Return; // in UT and KA the handler is empty
	
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

// StandardSubsystems.AttachableCommands
&AtClient
Procedure Attachable_ExecuteCommand(Command)
	AttachableCommandsClient.StartCommandExecution(ThisObject, Command, Object);
EndProcedure

&AtClient
Procedure Attachable_UpdateCommands()
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
EndProcedure

&AtClient
Procedure ProcessingSelectionIsDoneOnClientAfterQuestion(Response, AdditionalParameters) Export
	
	If Response = DialogReturnCode.Cancel Then
		Return;
	EndIf;
	
	If Response = DialogReturnCode.Yes Then
		Object.NotShipInInstallments = False;
		SetVisibilityOfShipmentReceiptDateElements();
	EndIf;
	
	ProcessingSelectionOfSelectionOnServer(AdditionalParameters);
	
EndProcedure
// End StandardSubsystems.AttachableCommands

#EndRegion

#Region Private

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

// End StandardSubsystems.Properties

&AtServer
Procedure SetConditionalAppearance()

	ConditionalAppearance.Items.Clear();
	
	// Standard design
	#Region StandardAppearance
	ProductsServer.SetConditionalAppearanceOfUnitsOfMeasurement(ThisForm);
	TMCommonUse.SetConditionalAppearanceOfPriority(ThisObject);
	ProductsServer.EstablishConditionalAppearanceOfProductCharacteristics(ThisForm);
	ProductsServer.EstablishConditionalAppearanceOfProductSeries(ThisForm, "SeriesAlwaysWHGoods");
	#EndRegion
	
	// Conditional registration of collateral.
	TMCommonUse.SetUncheckBlank(
		ConditionalAppearance, "DateOfShipment", "Object.DateOfShipment", "DateOfShipmentRequired_");
	
	TMCommonUse.SetUncheckBlank(
		ConditionalAppearance, "Warehouse", "Object.Warehouse", "WarehouseIsRequired");
	
	TMCommonUse.SetUncheckBlank(
		ConditionalAppearance, "GoodsShipmentStart", "Object.Goods.ShipmentStart", "Object.Goods.DateOfShipmentRequired_");
	
	ProvisionInDocumentsServer.SetConditionalAppearanceApart(
		ConditionalAppearance,
		Items.GoodsWithAssignment,
		"Object.Goods.SupplyOption",
		"Object.Goods.ItemsType");
		
	ProvisionInDocumentsServer.AvailableLeftoversAddColumnLayoutAvailable(ThisObject);
	
	// Color of canceled lines
	#Region GoodsCanceled
	
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

	#EndRegion
	
	// Conditional appearance of quality control Attributes.
	Fields = QualityControl.Fields(
		Items.GoodsToControlQuality,
		Items.GoodsQualityConfirmationDate);
	FlagDisabled = New Array();
	DateIsOptional = New Array();
	QualityControl.AddFilter(FlagDisabled, "Object.Goods.Canceled", True);
	QualityControl.AddFilter(FlagDisabled, "Object.ProductionManagement2_2", False);
	QualityControl.AddFilter(DateIsOptional, "Object.Goods.ReceiptEnd", '00010101');
	QualityControl.SetupAppearance(ConditionalAppearance, Fields, FlagDisabled, DateIsOptional);
	
EndProcedure

#Region FormSettings

// The procedure is called when changing the details that depend on the properties of other details, such as visibility.
//
&AtClientAtServerNoContext
Procedure ConfigureDependentFormElements(Form, AttributesList = "")
	
	Items = Form.Items;
	
	Initialize = IsBlankString(AttributesList);
	AttributesStructure1 = New Structure(AttributesList);
	
	// Substitutes
	#Region Substitutes
	
	If AttributesStructure1.Property("ShowAnalogues") Or Initialize Then
		
		Items.GoodsShowAnalogues.Check = Form.ShowAnalogues;
		Items.GoodsThereAreSubstituteMaterials.Visible = Form.ShowAnalogues;
		
	EndIf;
	
	#EndRegion
	
EndProcedure

#EndRegion


#Region OnChangeAttributes

&AtServer
Procedure StatusOnChangeServer()
	
	SeriesSpecificationParameters = New FixedStructure(ProductsServer.SeriesSpecificationParameters(Object, Documents.OrderOfMaterialsForProduction));
	ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);
	
EndProcedure

&AtServer
Procedure OrganizationOnChangeServer()
	
	UpdateConsumptionForActivities();
	
EndProcedure

&AtServer
Procedure ShopPantryWhenChangingOnServer(DirectModificationOfWarehouseField = False)
	
	UpdateConsumptionForActivities();
	
	If QualityControl.UpdateActionParameters(
			Documents.OrderOfMaterialsForProduction,
			Object,
			CacheQualityControl,
			DirectModificationOfWarehouseField) Then
		StructureOfActions = New Structure;
		AddQualityControlActionsToStructure(StructureOfActions, CacheQualityControl, Object.ProductionManagement2_2);
		BatchProcessingOfTablePartServer.TreatTS(Object.Goods, StructureOfActions);
	EndIf;
	
EndProcedure

&AtServer
Procedure WarehouseOnChangeServer()
	
	PrepareFillSetSeriesVisibility();
	ProvisionInDocumentsServer.WhenChangingDocumentDetails(ThisObject);
	
EndProcedure

&AtServer
Procedure UseDurationOfMoveOnChangeAtServer()
	
	If Object.ProductionManagement2_2 And Not Object.UseTransferDuration Then
		For Each TableRow In Object.Goods Do
			TableRow.ReceiptEnd = TableRow.ShipmentStart;
		EndDo;
	EndIf;
	
	If QualityControl.UpdateActionParameters(Documents.OrderOfMaterialsForProduction, Object, CacheQualityControl) Then
		StructureOfActions = New Structure();
		AddQualityControlActionsToStructure(StructureOfActions, CacheQualityControl, Object.ProductionManagement2_2);
		BatchProcessingOfTablePartServer.TreatTS(Object.Goods, StructureOfActions);
	EndIf;
	
	SetVisibilityOfDurationUsageElements();
	
EndProcedure

&AtServer
Procedure DurationOfMovementOnChangeATServer()
	
	If QualityControl.UpdateActionParameters(Documents.OrderOfMaterialsForProduction, Object, CacheQualityControl) Then
		StructureOfActions = New Structure();
		AddQualityControlActionsToStructure(StructureOfActions, CacheQualityControl, Object.ProductionManagement2_2);
		BatchProcessingOfTablePartServer.TreatTS(Object.Goods, StructureOfActions);
	EndIf;
	
EndProcedure

&AtServer
Procedure UpdateConsumptionForActivities(Fill = True)
	
	FillParameters = Documents.OrderOfMaterialsForProduction.ParametersForFillingInVATActivityType(Object);
	If Fill Then
		VATAccountingERP.FillInTypeOfActivityVAT(
			Object.ConsumptionForActivity,
			FillParameters,
			VATAccountingCachedParameterValues);
	EndIf;
	
	VATAccountingERP.FillInActivitySelectionList(
		Items.ConsumptionForActivity,
		Object.ConsumptionForActivity,
		FillParameters,
		VATAccountingCachedParameterValues);
	
EndProcedure

&AtServer
Procedure GoodsProductsOnChangeServer(RowID)
	
	CurrentRow = Object.Goods.FindByID(RowID);
	
	UpdateColumnAvailableServer();
	If RightToReadSubstitutes And ShowAnalogues Then
		NotePresenceOfAnalogues();
	EndIf;
EndProcedure

&AtServer
Procedure GoodsCharacteristicOnChangeServer(RowID)
	
	CurrentRow = Object.Goods.FindByID(RowID);
	
	UpdateColumnAvailableServer();
	If RightToReadSubstitutes And ShowAnalogues Then
		NotePresenceOfAnalogues();
	EndIf;
EndProcedure

&AtServer
Procedure GoodsCanceledOnChangeServer(RowID)
	
	UpdateColumnAvailableServer();
	If RightToReadSubstitutes And ShowAnalogues Then
		NotePresenceOfAnalogues();
	EndIf;
EndProcedure

#EndRegion

#Region SelectionAndProcessingOfQuantityVerification

&AtServer
Procedure ProcessingSelectionOfSelectionOnServer(ValueSelected)
	
	TableOfGoods = GetFromTempStorage(ValueSelected.GoodsAddressInStorage);
	
	CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	
	StructureOfActions = New Structure;
	AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions);
	AddQualityControlActionsToStructure(StructureOfActions, CacheQualityControl, Object.ProductionManagement2_2);
	StructureOfActions.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
	AddCollateralActionsOnServer(StructureOfActions, "WarehouseIsRequired,DateOfShipmentRequired_");

	BegOfDay = BegOfDay(CurrentSessionDate());
	RowsToProcess = New Array;
	ShippingDates = New Map;
	
	For Each RowOfProduct In TableOfGoods Do
		
		CurrentRow = Object.Goods.Add();
		
		FillPropertyValues(CurrentRow, RowOfProduct,
			"Products,Characteristic,ItemVariantsAreUsed,Package,NumberOfPackages,SupplyOption,
			|WithAssignment,Series");
		CurrentRow.ShipmentStart = RowOfProduct.DateOfShipment;
		ShippingDates.Insert(CurrentRow, RowOfProduct.DateOfShipment);
		RowsToProcess.Add(CurrentRow);
		
	EndDo;
		
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		RowsToProcess,
		StructureOfActions,
		Object.Goods,
		CachedValues);
	
	For Each CurrentRow In RowsToProcess Do
		
		If Object.ProductionManagement2_2 Then
			
			CurrentRow.ShipmentStart = ProvisionInDocumentsServer.ShipmentDateProcessingSelectionSelection(
				ShippingDates.Get(CurrentRow),
				CurrentRow.SupplyOption,
				Max(BegOfDay, Object.RequestedDeliveryDate - 86400 * Object.TransferDurationDays));
				
			If ValueIsFilled(CurrentRow.ShipmentStart) Then
				
				CurrentRow.ReceiptEnd = Max(CurrentRow.ShipmentStart + 86400 * Object.TransferDurationDays,
					BegOfDay + 86400 * Object.TransferDurationDays,
					Object.RequestedDeliveryDate);
					
			EndIf;
			
		Else
			
			CurrentRow.ShipmentStart = ProvisionInDocumentsServer.ShipmentDateProcessingSelectionSelection(
				ShippingDates.Get(CurrentRow),
				CurrentRow.SupplyOption,
				BegOfDay);
			
		EndIf;
		
	EndDo;
	
	If Not Object.ProductionManagement2_2 Then
		
		ProvisionInDocumentsServer.UpdateShipmentDateWithSingleDate(
			Object.NotShipInInstallments,
			Object.DateOfShipment,
			Object.Goods,
			"ShipmentStart");
			
	EndIf;
	
	FillInServiceDetailsForProductRange();
	ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);
	
	ReusablePackageServer.UpdateFillingStateOfMultiTurnContainer(Object.ReusablePackageFillingStatus);
	If RightToReadSubstitutes And ShowAnalogues Then
		NotePresenceOfAnalogues();
	EndIf;
	UpdateColumnAvailableServer();
	
EndProcedure

&AtClientAtServerNoContext
Procedure AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions)
	
	StructureOfActions.Insert("RecalculateNumberOfUnits");
	
EndProcedure

&AtClientAtServerNoContext
Procedure AddQualityControlActionsToStructure(StructureOfActions, CacheQualityControl, ProductionManagement2_2)
	
	If ProductionManagement2_2 Then
		StructureOfActions.Insert("FillInCheckQualityDateOfQualityConfirmation", CacheQualityControl);
	EndIf;
	
EndProcedure

&AtServer
Procedure FillInServiceDetailsForProductRange()
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInFeatureAttribute", 
									New Structure("Products", "ItemVariantsAreUsed"));
								
	StructureOfActions.Insert("FillInProductTypeAttribute_", 
									New Structure("Products", "ItemsType"));
									
	StructureOfActions.Insert("FillInArticleAttribute", 
									New Structure("Products", "SKU"));
									
	ProductsServer.FillInServiceDetailsForProductInCollection(
		Object.Goods,
		StructureOfActions);
	
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
	AddActionsToStructureWhenChangingPackagesNumber(StructureOfActionsWithAddedStrings);
	AddQualityControlActionsToStructure(StructureOfActionsWithAddedStrings, CacheQualityControl, Object.ProductionManagement2_2);
	
	StructureOfActionsWithModifiedStrings = New Structure;
	AddActionsToStructureWhenChangingPackagesNumber(StructureOfActionsWithModifiedStrings);
	
	StructureOfActions = BarcodingOfItemsClient.BarcodeProcessingParameters();
	StructureOfActions.Barcodes                              = BarcodeData_5;
	StructureOfActions.StructureOfActionsWithAddedStrings = StructureOfActionsWithAddedStrings;
	StructureOfActions.StructureOfActionsWithModifiedStrings  = StructureOfActionsWithModifiedStrings;
	StructureOfActions.SeriesSpecificationParameters                 = SeriesSpecificationParameters;
	StructureOfActions.GoodsOnly                           = True;
	
	ProcessBarcodesServer(StructureOfActions, CachedValues);
	ProvisionInDocumentsClientServer.FillInServiceDetails(Object.Goods, DateOfShipmentRequired_, WarehouseIsRequired);
	
	BarcodingOfItemsClient.ProcessUnknownBarcodes(StructureOfActions, CachedValues, ThisObject);
	
	If BarcodingOfItemsClient.YouNeedToOpenFormForSpecifyingSeriesAfterProcessingBarcodes(StructureOfActions) Then
		CurDataId = StructureOfActions.ArrayOfRowsWithSeries_[0];
		
		AttachIdleHandler("OpenSeriesSelectionWhenScanningProductBarCode",0.1,True);
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

&AtServer
Procedure PrepareFillSetSeriesVisibility()
	
	SeriesSpecificationParameters = New FixedStructure(ProductsServer.SeriesSpecificationParameters(Object, Documents.OrderOfMaterialsForProduction));
	ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);
	SetFormFunctionalOptionParameters(New Structure("Warehouse",Object.Warehouse));
	
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
Procedure OpenSeriesSelectionWhenScanningProductBarCode()

	If CurDataId = Undefined Then
		Return;
	EndIf;
	
	CurrentData = Object.Goods.FindByID(CurDataId);
	OpenSelectionOfSeries(,CurrentData);

EndProcedure

#EndRegion

#Region Other

&AtServer
Procedure SetSoftwareVisibility()
	
	HasRight = ProvisionInDocumentsServer.HaveRightToViewStateHyperlink();
	Items.PagesHyperlinkSoftwareStatus.Visible = HasRight;
	
	If Not AccessRight("Insert", Metadata.Documents.InventoryAssignmentAdjustment)
		Or Not GetFunctionalOption("UseOrderSupplyWithAssignment") Then
		Items.GoodsCreateAssignmentAdjustmentRemoveFromReserve.Visible = False;
		Items.GoodsCreateAnAssignmentAdjustmentReservation.Visible = False;
	EndIf;
	
	ProvisionInDocumentsServer.ConfigureHyperlinkedSoftwareState(ThisObject);
	Items.DateOfShipment.ToolTip = ProvisionInDocumentsServer.HintShipmentDate();
	ReflectAnalogsInSupplyForecastHyperlink(ThisObject);
EndProcedure

&AtClient
Procedure Attachable_CloseForm()
	
	Close();
	
EndProcedure

&AtClient
Procedure NotifyAboutDocument(WriteParameters)

	NotificationParameters = New Structure;
	NotificationParameters.Insert("WriteMode",      WriteParameters.WriteMode);
	NotificationParameters.Insert("ThereIsOrder_", True);

	Notify("Write_OrderOfMaterialsForProduction", NotificationParameters, Object.Ref);

EndProcedure

&AtServer
Procedure FillMultiTurnContainersFromStorageServer(AddressOfContainerInStorage)
	
	ActionStructureModifiedStrings = New Structure;
	ActionStructureModifiedStrings.Insert("RecalculateNumberOfPackages");
	StructureOfActionsAddedLines = New Structure;
	StructureOfActionsAddedLines.Insert("RecalculateNumberOfPackages");
	AddQualityControlActionsToStructure(StructureOfActionsAddedLines, CacheQualityControl, Object.ProductionManagement2_2);
	AddCollateralActionsOnServer(StructureOfActionsAddedLines, "SupplyOption,WarehouseIsRequired,DateOfShipmentRequired_");
	
	ReusablePackageServer.FillMultiTurnContainersFromStorage(
		Object,
		AddressOfContainerInStorage,
		"Goods",
		"Products,Characteristic,,ShipmentStart",
		ActionStructureModifiedStrings,
		StructureOfActionsAddedLines);
	
	FillInServiceDetailsForProductRange();
	ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);
	UpdateColumnAvailableServer();
	
EndProcedure

&AtServer
Procedure OnReadCreateAtServer()
	
	SeriesSpecificationParameters = New FixedStructure(ProductsServer.SeriesSpecificationParameters(Object, Documents.OrderOfMaterialsForProduction));
	SetFormFunctionalOptionParameters(New Structure("Warehouse",Object.Warehouse));
	FillInServiceDetailsForProductRange();
	
	ItemsNames = New Array;
	ItemsNames.Add("ShopFloorStockroom");
	ItemsNames.Add("GoodsToControlQuality");
	ItemsNames.Add("GoodsQualityConfirmationDate");
	TMCommonUseClientServer.SetPropertyOfFormElements(Items, ItemsNames, "Visible", Object.ProductionManagement2_2);
	
	Items.Department.Visible   = Not Object.ProductionManagement2_2;
	Items.BaseGroup_.Visible = ValueIsFilled(Object.DocumentBasis);
	
	SetVisibilityOfShipmentReceiptDateElements();
	SetSoftwareVisibility();
	
	TransferDurationDays = Object.TransferDurationDays;
	
	UpdateConsumptionForActivities(False);
	
	LinesOfBusinessServer.OnReadCreateAtServer(ThisObject);
	AssistantForPerformingSubstitutionsIsAvailable = Documents.EngineeringChangeOrder.AssistantForPerformingSubstitutionsIsAvailable();
	
	RightToReadSubstitutes = GetFunctionalOption("UseAlternativeMaterials")
						  And AccessRight("Read", Metadata.InformationRegisters.AlternativeMaterials) 
						  And Object.ProductionManagement2_2;
	
	If RightToReadSubstitutes And ShowAnalogues Then
		NotePresenceOfAnalogues();
	EndIf;
	
	Items.GoodsThereAreSubstituteMaterials.Visible = RightToReadSubstitutes And ShowAnalogues;
	Items.GroupProvidingAnalogs.Visible = RightToReadSubstitutes;
	If Object.ProductionManagement2_2 Then
		CacheQualityControl = QualityControl.DataCacheOfMechanism(Object);
	EndIf;
	
	FillInServiceDetailsOfSupply();
	ProcessingOfTabularForms.InitializeRowCache(Items.Goods);
	
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
	
	Columns = "Products,Characteristic,Package,NumberOfPackages,ProductsGroup,ShipmentStart";
	
	TableOfGoods = ProcessingOfTabularForms.RowsFromClipboard(FilterParameters, Columns);
	
	If Not ValueIsFilled(TableOfGoods) Then
		Return;
	EndIf;
	
	StructureOfActions = New Structure;
	AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions);
	AddCollateralActionsOnServer(StructureOfActions, "SupplyOption,WarehouseIsRequired,DateOfShipmentRequired_");
	AddQualityControlActionsToStructure(StructureOfActions, CacheQualityControl, Object.ProductionManagement2_2);
	
	CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	RowsToProcess = New Array();
	
	For Each RowOfProduct In TableOfGoods Do
		
		CurrentRow = Object.Goods.Add();
		FillPropertyValues(CurrentRow, RowOfProduct);
		
		If Not Object.ProductionManagement2_2 And Object.NotShipInInstallments Then
			CurrentRow.ShipmentStart = Object.DateOfShipment;
		EndIf;
		RowsToProcess.Add(CurrentRow);
		
	EndDo;
	
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		RowsToProcess,
		StructureOfActions,
		Object.Goods,
		CachedValues);
	
	ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);
	FillInServiceDetailsForProductRange();
	
	ReusablePackageServer.UpdateFillingStateOfMultiTurnContainer(Object.ReusablePackageFillingStatus);
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

#Region Supply

&AtClient
Procedure Attachable_CheckCompletionOfInventoryAllocationTask()
	
	Error = False;
	If ProvisionInDocumentsClient.NeedToUpdateAvailabilityAfterRecording(ThisObject,
		"Attachable_CheckCompletionOfInventoryAllocationTask", Error) Then
		ProvisionInDocumentsClient.ConfigureHyperlinksSupplyForecastAfterRecording(ThisObject, Error);
		ReflectAnalogsInSupplyForecastHyperlink(ThisObject);
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
	FormParameters.SeriesSpecificationParameters = SeriesSpecificationParameters;
	
	Return FormParameters;
	
EndFunction

&AtServer
Procedure FillInShipmentDateServer(DateOfShipment, ArrayOfSelectedRows)
	
	ProvisionInDocumentsServer.FillInDetailsInCollection(Object.Goods, "ShipmentStart", DateOfShipment, ArrayOfSelectedRows);
	
EndProcedure

&AtServer
Procedure NotShipInInstallmentsOnChangeServer()
	
	If Object.NotShipInInstallments Then
		Object.DateOfShipment = ProvisionInDocumentsServer.MaximumValueInCollection(Object.Goods, "ShipmentStart", '00010101');
		ProvisionInDocumentsServer.FillInDetailsInCollection(Object.Goods, "ShipmentStart", Object.DateOfShipment);
	EndIf;
	
	SetVisibilityOfShipmentReceiptDateElements();
	
EndProcedure

&AtServer
Procedure LineOfBusinessOnChangeServer()
	
	LinesOfBusinessServer.WhenChangingDirectionOfActivity(ThisObject);
	
	Object.AssignByOrderAssignment = Constants.OptionOfMaterialAssignmentWhenTransferringToProduction.Get()
		<> Enums.OptionsOfMaterialAssignmentWhenTransferringToProduction.AssignmentRecipient;
	
	UpdateConsumptionForActivities();
	ProvisionInDocumentsServer.WhenChangingDocumentDetails(ThisObject);
	
EndProcedure

&AtClient
Procedure GoodsCollateralOptionWhenChangedAfterIssue(Response, AdditionalParameters) Export
	
	FillParameters = ProvisionInDocumentsClient.ParametersForProcessingShipmentDatesAfterFillingInCollateral(Response);
	WhatIsSoftwareOptionWhenChangingOnServer(FillParameters);
	
EndProcedure

&AtServer
Procedure WhatIsSoftwareOptionWhenChangingOnServer(FillParameters)
	
	Changes = ProvisionInDocumentsServer.SupplyOptionOnChange(
		ThisObject,
		Items.Goods.CurrentRow);
		
	Mode = ProvisionInDocumentsClientServer.ModeSelectActionDirectly();
	AfterFillingOutCollateral(Changes, Mode, FillParameters);
	
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
	
	If AssistantForPerformingSubstitutionsIsAvailable And ThereAreAnalogues And RightToReadSubstitutes Then
		
		OpeningParameters = ParametersOfReplacementAssistantForm();
		
		Notification = New CallbackDescription("AfterReplacementViaAssistant", ThisObject);
		
		OpenForm("Document.EngineeringChangeOrder.Form.ReplacementWizard", OpeningParameters, ThisObject, UUID,,,
			Notification,FormWindowOpeningMode.LockOwnerWindow);
			
	Else	
		FormParameters = ProvisionInDocumentsClient.SecurityStatusHyperlinkClick(ThisObject);
	
		If FormParameters.ContextOfUse = "TABLE" Then
			
			FormParameters.AddressOfTheMovementTable = AddressOfMovementTableInRepository();
			
		EndIf;
		
		OpenForm("DataProcessor.OrderSupplyForecast.Form", FormParameters, ThisObject, UUID,,,,
			FormWindowOpeningMode.LockOwnerWindow);
	EndIf;
EndProcedure

&AtClient
Procedure AddCollateralActionsOnClient(StructureOfActions, StringFields_)
	
	DocumentParameters = DocumentParametersForSoftwareActions(ThisObject, Undefined);
	ProvisionInDocumentsClientServer.AddCollateralActions(StructureOfActions, StringFields_, DocumentParameters);
	
EndProcedure

&AtServer
Procedure AddCollateralActionsOnServer(StructureOfActions, StringFields_, DateOfShipment = Undefined)
	
	DocumentParameters = DocumentParametersForSoftwareActions(ThisObject, DateOfShipment);
	ProvisionInDocumentsClientServer.AddCollateralActions(StructureOfActions, StringFields_, DocumentParameters);
	
EndProcedure

&AtServer
Procedure FillInServiceDetailsOfSupply()
	
	DocumentParameters = DocumentParametersForSoftwareActions(ThisObject, Undefined);
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
	
	QuestionAsked = ProvisionInDocumentsClient.ShowIssueOfFillingSoftwareWithWholePackages(
		ThisObject,
		Object.Goods,
		Result,
		"AfterQuestionOfFillingPackageWithWholePackages");
		
	If Not Object.ProductionManagement2_2 Then
		
		If Not QuestionAsked Then
			
			ProvisionInDocumentsClient.ShowQuestionUncheckShipByOneDate(
				ThisObject,
				Object.Goods,
				Result,
				"AfterQuestionRemoveFlagShipByOneDate");
				
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure AfterQuestionOfFillingPackageWithWholePackages(Response, Result) Export
	
	If Object.ProductionManagement2_2 Then
		
		EnsuringToSetActionAfterQuestion(Response, Result);
		
	Else
		
		QuestionAsked = ProvisionInDocumentsClient.ShowQuestionUncheckShipOneDateAfterQuestion(
			ThisObject,
			Object.Goods,
			Result,
			Response,
			"AfterQuestionRemoveFlagShipByOneDate");
			
		If Not QuestionAsked Then
			
			EnsuringToSetActionAfterQuestion(Response, Result);
			
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure AfterQuestionRemoveFlagShipByOneDate(Response, Result) Export
	
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
		ReflectAnalogsInSupplyForecastHyperlink(ThisObject);
	EndIf;
	
EndProcedure

&AtServer
Procedure AfterFillingOutCollateral(Changes, Mode = Undefined, FillParameters = Undefined)
	
	Documents.OrderOfMaterialsForProduction.AfterFillingOutCollateral(Object, Changes, Mode, FillParameters);
	SetVisibilityOfShipmentReceiptDateElements();
	
	StructureOfActions = New Structure();
	AddCollateralActionsOnServer(StructureOfActions, "WarehouseIsRequired,DateOfShipmentRequired_");
	CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	RowsToProcess = New Array;
	For Each Update In Changes Do
		RowsToProcess.Add(Update.String);
	EndDo;
	
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		RowsToProcess,
		StructureOfActions,
		Object.Goods,
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
	
	ProvisionInDocumentsClient.ShowQuestionUncheckShipByOneDateAfterSelectingCollateral(
		ThisObject,
		ValueSelected,
		FormParameters,
		"ProcessSelectionWarehouseAndBatchAfterQuestion");
	
EndProcedure

&AtClient
Procedure ProcessSelectionWarehouseAndBatchAfterQuestion(Response, Var_Parameters) Export
	
	FillParameters = ProvisionInDocumentsClient.ParametersForProcessingShipmentDatesAfterFillingInCollateral(Response);
	
	Notification = ProcessWarehouseAndBatchSelectionOnServer(
		Var_Parameters.ValueSelected,
		Var_Parameters.FormParameters,
		FillParameters);
		
	NotificationText1 = ProvisionInDocumentsClient.TextProcessingAlertsWarehouseAndBatchSelection(Var_Parameters.FormParameters.Mode);
	ShowUserNotification(NotificationText1, , Notification);

EndProcedure

&AtServer
Function ProcessWarehouseAndBatchSelectionOnServer(ValueSelected, FormParameters, FillParameters)
	
	Modified = True;
	Changes = ProvisionInDocumentsServer.WhenChoosingWarehouse(
		ValueSelected,
		ThisObject,
		Items.Goods.CurrentRow,
		FormParameters.FieldsToFillIn);
		
	AfterFillingOutCollateral(Changes, FormParameters.Mode, FillParameters);
	TextProcessedLines = ProvisionInDocumentsServer.TextProcessedLines(Changes.Count());
	Return TextProcessedLines;
	
EndFunction

#EndRegion
#Region Substitutes

&AtServer
Procedure NotePresenceOfAnalogues()
	
	TableName = "Goods";
	AlternativeMaterials.NotePresenceOfAnalogues(Object[TableName], AnalogSelectionParameters(TableName, 0), ThisObject);
	ReflectAnalogsInSupplyForecastHyperlink(ThisObject);
	
EndProcedure

&AtClient
Procedure OpenSelectionOfAnalogues()
	
	TableName = "Goods";
	
	If Items[TableName].SelectedRows.Count() = 0 Then
		ShowMessageBox(, NStr("vi = 'Cần chọn (các) dòng';
								|ru = 'Необходимо выделить строку(и)';
								|en = 'Highlight the line(s)'; fa = 'Highlight the line(s)';
								|it = 'È necessario evidenziare la riga (le righe)';
								|pl = 'Należy zaznaczyć wiersz(e)';
								|tr = 'Satır(lar) vurgulanmalıdır'"));
		Return;
	EndIf;
	
	AlternativeMaterialsClient.OpenSelectionOfAnalogues(AnalogSelectionParameters(TableName, 1), ThisObject);
	
EndProcedure

&AtServer
Procedure Replace_With_Analogues(AddressInStorage = Undefined)
	
	TableName = "Goods";
	
	Result = ?(AddressInStorage = Undefined,
		AlternativeMaterials.PerformReplacementWithAnaloguesAutomatically(Object[TableName], AnalogSelectionParameters(TableName, 2),, "Action_Substitutes_ToReserve_"),
		AlternativeMaterials.PerformReplacementForAnalogues(Object[TableName], AddressInStorage,, "Action_Substitutes_ToReserve_"));
	
	IndexesOfModifiedRows = Result.IndexesOfModifiedRows;
	IndexesOfNewRows = Result.IndexesOfNewRows;
	
	NumberOfReplacementsMade = IndexesOfModifiedRows.Count() + IndexesOfNewRows.Count();
	MessageText  = StrTemplate(NStr("vi = 'Dòng được thay đổi: %1';
									|ru = 'Измененных строк: %1';
									|en = 'Changed lines: %1'; fa = 'Changed lines: %1';
									|it = 'Измененных строк: %1';
									|pl = 'Changed lines: %1';
									|tr = 'Değiştirilen satırlar: %1'"), NumberOfReplacementsMade);
	Common.MessageToUser(MessageText);

	If NumberOfReplacementsMade = 0 Then
		Return;
	EndIf;	
	
	PerformActionsAfterReplacingWithAnalogs(Result);
		
EndProcedure

// Generates parameters for selecting analogs
//
// Parameters:
//	TableName - String - Name of the table to be processed
//	Mode      - Number  - 0-show analogs
//                        1 - choose the analogues
//                        2-replace with analogs
// 
// Returns:
//  Structure - See AlternativeMaterials.AnalogSelectionParameters
//
&AtServer
Function AnalogSelectionParameters(TableName, Mode)

	SourceType = New TypeDescription("DocumentRef.OrderOfMaterialsForProduction");
	FormParameters = AlternativeMaterials.AnalogSelectionParameters(SourceType);
	
	// GeneralParameters
	FormParameters.GeneralParameters.ShowBalance = True;
	
	// GoodsParameters
	FieldsStructure = AlternativeMaterials.StructureOfTableFieldsToReplaceWithAnalogues();
	FieldsStructure.AdditionalFields.Insert("Ref", New TypeDescription("DocumentRef.OrderOfMaterialsForProduction"));
	FieldsStructure.DefaultValues.Insert("Ref", Object.Ref);
	FieldsStructure.DefaultValues.Insert("Warehouse", Object.Warehouse);
	
	RowFilter = New Structure;
	RowFilter.Insert("Canceled", New Array);
	RowFilter.Canceled.Add(False);
	
	ObjectName = "Object";
	
	FormData1 = New Structure;
	FormData1.Insert("AvailableRemainingEmbeddingOptions", ThisObject.AvailableRemainingEmbeddingOptions);
	FormData1.Insert("Items", Items);
	FormData1.Insert("UUID", UUID);
	FormData1.Insert(ObjectName, New Structure);
	FormData1[ObjectName].Insert(TableName, Object[TableName].Unload(?(Mode = 0, Undefined, New Array)));
	
	If Mode = 2 Then
		
		FormData1.Insert("Modified", Modified);
		
		EmbeddingParameters = Documents.OrderOfMaterialsForProduction.AvailableRemainingEmbeddingOptions();
		
		For Each SerializationPattern In EmbeddingParameters.FormDataSerializationPattern.Object Do
			
			TemplateFieldName = SerializationPattern.Key;
			If TemplateFieldName = TableName Then
				Continue;
			EndIf;
			
			FormData1[ObjectName].Insert(TemplateFieldName);
			
		EndDo;
		
		FillPropertyValues(FormData1[ObjectName], Object,, TableName);
		
		FormData1[ObjectName][TableName].Columns.Add("RowID", Common.TypeDescriptionNumber(15));
		
		If GetFunctionalOption("DynamicStructureOfProductionOrders") Then
		
			SelectionOfPermissions = New Map();
			TMCommonUse.AddSelectionItemToCollection(SelectionOfPermissions, "AlternativeMaterials.UseItForAutocorrectInOrders", "&UseItForAutocorrectInOrders");
			
			PermissionSelectionParameters = New Map();
			PermissionSelectionParameters.Insert("UseItForAutocorrectInOrders", CommonClientServer.ValueInArray(True));
			
			FormParameters.GeneralParameters.SelectionOfPermissions = SelectionOfPermissions;
			FormParameters.GeneralParameters.PermissionSelectionParameters = PermissionSelectionParameters;	
		
		EndIf;
		
	EndIf;	
			
	If Mode <> 0 Then
		
		ObjectTable = Object[TableName].Unload(); // ValueTable
		ObjectTable.Columns.Add("RowID", Common.TypeDescriptionNumber(15));
		
		MatchingAssignmentTypes = Common.ObjectsAttributesValues(
										ObjectTable.UnloadColumn("Purpose"), "AssignmentType");
			
		For Each TableRow In ObjectTable Do
			
			If Not TableRow.WithAssignment Then
				TableRow.Purpose = Catalogs.Assignments.EmptyRef();	
			ElsIf Not ValueIsFilled(TableRow.Purpose)
					Or Object.AssignByOrderAssignment 
						And MatchingAssignmentTypes.Get(TableRow.Purpose) = Enums.AssignmentTypes.Own Then
				TableRow.Purpose = Object.Purpose;
			EndIf;
			
			TableRow.RowID = Object[TableName][TableRow.LineNumber - 1].GetID();
			
			If Mode = 1 And Items[TableName].SelectedRows.Find(TableRow.RowID) = Undefined Then
				Continue;
			EndIf;
			
			FillPropertyValues(FormData1[ObjectName][TableName].Add(), TableRow);
			
		EndDo;	
		
	EndIf;	
	
	AddlParameters = AlternativeMaterials.AdditionalParameters();
	AddlParameters.RowFilter     = RowFilter;
	AddlParameters.SourceOfResults = ObjectTable;
	
	ProductData_9 = AlternativeMaterials.GetProductData(
		FormData1, ObjectName, TableName, Mode, ?(Mode = 2, True, False), FieldsStructure, AddlParameters);
		
	If Mode = 1 Then	
		
		ProductData_9.InventoryAllocation = AlternativeMaterials.PlaceInventoryDistributionInTemporaryStorage(ThisObject,
			ProductData_9.Goods);
		
	EndIf;
		
	FillPropertyValues(FormParameters.GoodsParameters, ProductData_9);
	
	// SubstitutesParameters
	ParametersTable = FormParameters.SubstitutesParameters.ParametersTable;
	
	TableRow = ParametersTable.Add();
	TableRow.PermissionValidityDate = BegOfDay(CurrentSessionDate());
	TableRow.Ref = Object.Ref;
	TableRow.Department = Object.Department;
	TableRow.LineOfBusiness = Object.LineOfBusiness;
	
	FormParameters.SubstitutesParameters.ParametersTable = 
		PutToTempStorage(ParametersTable, UUID);
		
	FormParameters.SubstitutesParameters.Warehouse = Object.Warehouse;	
	
	Return FormParameters;
	
EndFunction

#EndRegion
#Region CancelLines

&AtClient
Procedure CancelUnprocessed(Command)
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.TimeMeasurement(
		"Document.OrderOfMaterialsForProduction.Form.DocumentForm.Command.CancelUnprocessed");
	
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
	PerformanceMonitorClient.TimeMeasurement(
		"Document.OrderOfMaterialsForProduction.DocumentForm.Command.CancelSelectedLines");
	
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
																		|tr = 'Belirtilen satırlar iptal edildi'"));
	
EndProcedure

&AtServer
Procedure CancelSelectedLinesServer()
	
	SelectedRows = Items.Goods.SelectedRows;
	
	StructureOfActions = New Structure;
	AddCollateralActionsOnServer(StructureOfActions, "WarehouseIsRequired,DateOfShipmentRequired_");
	AddQualityControlActionsToStructure(StructureOfActions, CacheQualityControl, Object.ProductionManagement2_2);
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

	ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);
	If RightToReadSubstitutes And ShowAnalogues Then
		NotePresenceOfAnalogues();
	EndIf;
	UpdateColumnAvailableServer();
	
EndProcedure

&AtServer
Function AdjustOrderLines(StructureOfAdditionalParameters)
	
	OrderObject = FormAttributeToValue("Object");
	
	StructureOfAdditionalParameters.CheckBalance = True;
	
	ResultStructure1 = OrderObject.AdjustOrderLines(StructureOfAdditionalParameters);
	
	RowsToProcess = Object.Goods.FindRows(New Structure("Canceled", True));
	StructureOfActions = New Structure();
	AddQualityControlActionsToStructure(StructureOfActions, CacheQualityControl, Object.ProductionManagement2_2);
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		RowsToProcess,
		StructureOfActions,
		Object.Goods,
		Undefined);
	
	If StructureOfAdditionalParameters.CloseOrders Then
		OrderObject.Status = Enums.StatusesOfOrdersForMaterialsForProduction.Closed;
	EndIf;
	
	ValueToFormAttribute(OrderObject, "Object");
	
	FillInServiceDetailsOfSupply();
	
	FillInServiceDetailsForProductRange();
	If RightToReadSubstitutes And ShowAnalogues Then
		NotePresenceOfAnalogues();
	EndIf;
	UpdateColumnAvailableServer();
	
	Modified = True;
	
	Return ResultStructure1;
	
EndFunction

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

&AtClient
Procedure CloseOrder(Command)
	
	If Modified Or Not Object.Posted Then
		ShowQueryBox(New CallbackDescription("CloseOrderCompletion", ThisObject),
						NStr("vi = 'Cần kết chuyển chứng từ để hoàn thành giao dịch. Kết chuyển chứng từ?';
							|ru = 'Необходимо провести документ для выполнения операции. Провести документ?';
							|en = 'To proceed, you need to post the document. Do you want to post the document?'; fa = 'To proceed, you need to post the document. Do you want to post the document?';
							|it = 'È necessario registrare il documento per eseguire operazione. Registrare documento?';
							|pl = 'Należy zaksięgować dokument aby wykonać operację. Zaksięgować dokument?';
							|tr = 'İşlemin gerçekleştirilmesi için belgenin kaydedilmesi gerekmektedir. Belge kaydedilsin mi?'"),QuestionDialogMode.YesNo);
		Return;
	EndIf;
	
	CloseOrderFragment();
	
EndProcedure

&AtClient
Procedure CloseOrderFragment(Result = Undefined, AdditionalParameters = Undefined) Export
	
	PerformanceMonitorClient.TimeMeasurement(
		"Document.OrderOfMaterialsForProduction.DocumentForm.Command.CloseOrderFragment");
	
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
	ElsIf Not Write(WriteParameters) Then
		Return;
	EndIf;
	
EndProcedure

&AtServer
Procedure SetVisibilityOfShipmentReceiptDateElements()
	
	Items.GroupShipmentDateDoNotShipInParts.Visible = Not Object.ProductionManagement2_2;
	
	Items.GoodsShipmentStart.Visible = Object.ProductionManagement2_2 Or Not Object.NotShipInInstallments;
	Items.DateOfShipment.Visible = Not Object.ProductionManagement2_2 And Object.NotShipInInstallments;
	Items.FillInShipmentDate.Visible = Not Object.ProductionManagement2_2 And Not Object.NotShipInInstallments;
	
	Items.TransferTerms.Visible = Object.ProductionManagement2_2;
	
	Items.CommandPanelCommandsForFillingInTheReceiptDate.Visible = Object.ProductionManagement2_2;
	
	SetVisibilityOfDurationUsageElements();
	
EndProcedure

&AtServer
Procedure SetVisibilityOfDurationUsageElements()
	
	If Object.ProductionManagement2_2 And Object.UseTransferDuration Then
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
	Items.GoodsReceiptEnd.Visible = Object.ProductionManagement2_2 And Object.UseTransferDuration;
	
	Items.FillInTheEndOfReceiptForAllLines.Visible = Object.ProductionManagement2_2 And Object.UseTransferDuration;
	Items.FillInTheEndOfReceiptForTheSelectedLines.Visible = Object.ProductionManagement2_2 And Object.UseTransferDuration;
	
EndProcedure

&AtServer
Procedure SetVisibilityOfInputCommandsBasedOn_()
	AttachableCommandsClientServer.UpdateCommands(ThisForm, Object);
EndProcedure

&AtClient
Procedure Attachable_ProcessObjectEntry()
	
	TMCommonUseClient.ProcessObjectEntryInForm(ThisObject, ParametersForRecording);
	
EndProcedure

&AtServer
Procedure ProductsAfterDeletionOnServer()
	
	UpdateColumnAvailableServer();
	If RightToReadSubstitutes And ShowAnalogues Then
		NotePresenceOfAnalogues();
	EndIf;
EndProcedure
&AtServer
Function ParametersOfReplacementAssistantForm()

	OpeningParameters = New Structure;
	
	Rows = New Array;
	Columns = "LineNumber, Products, Characteristic, ItemVariantsAreUsed, Purpose, WithAssignment, SupplyOption, Count";
	For Each TSRow In Object.Goods Do
			
		If TSRow.ThereAreSubstituteMaterials
		   And Not TSRow.Canceled
		   And Not TSRow.SupplyOption = Enums.SupplyOptions.Ship Then
		
			Rows.Add(TSRow);
		
		EndIf;
		
	EndDo;
		
	VT = Object.Goods.Unload(Rows, Columns);
	VT.Columns.Add("Ref", New TypeDescription("DocumentRef.OrderOfMaterialsForProduction"));
	VT.Columns.Add("Stage", New TypeDescription("DocumentRef.OrderOfMaterialsForProduction"));
	VT.Columns.Add("StageOfResourceBillOfMaterials", New TypeDescription("CatalogRef.ProductionStages"));
	VT.Columns.Add("Warehouse", New TypeDescription("CatalogRef.Warehouses"));
	VT.Columns.Add("Department", New TypeDescription("CatalogRef.BusinessStructure"));
	VT.Columns.Add("BillOfMaterials", New TypeDescription("CatalogRef.BillsOfMaterials"));
	VT.Columns.Add("LineOfBusiness", New TypeDescription("CatalogRef.LinesOfBusiness"));
	VT.Columns.Add("ProductionOrder", New TypeDescription("DocumentRef.ProductionOrder2_2"));
	VT.Columns.Add("Product", New TypeDescription("CatalogRef.Products"));	
	VT.Columns.Add("ItemVariantOfProduct", New TypeDescription("CatalogRef.ItemsCharacteristics"));
	
	VT.Columns.Add("LineNumberDocument", Common.TypeDescriptionNumber(5));
	VT.Columns.Add("Shipped", Common.TypeDescriptionNumber(15, 3));
	VT.Columns.Add("Supplied", Common.TypeDescriptionNumber(15, 3));
	VT.Columns.Add("Total", Common.TypeDescriptionNumber(15, 3));
		
	For Each SpecificationRow In VT Do
		
		SpecificationRow.Ref = Object.Ref;
		SpecificationRow.Stage = Object.Ref;
		SpecificationRow.LineOfBusiness = Object.LineOfBusiness;
		SpecificationRow.Department = Object.Department;
		SpecificationRow.Warehouse = Object.Warehouse;
		SpecificationRow.LineNumberDocument = SpecificationRow.LineNumber;
		SpecificationRow.Total = SpecificationRow.Count;
		
		If SpecificationRow.SupplyOption = Enums.SupplyOptions.ReserveAsReceived
		 Or SpecificationRow.SupplyOption = Enums.SupplyOptions.FromWarehouse Then
			
			SpecificationRow.Supplied = SpecificationRow.Count;
			
		EndIf;
	
	EndDo;
	
	AdditionalParametersAnaloguesOfMaterials = AlternativeMaterials.AdditionalParameters();
	AdditionalParametersAnaloguesOfMaterials.RowFilter = New Structure("Canceled", CommonClientServer.ValueInArray(False));
		
	FieldsStructure = AlternativeMaterials.StructureOfTableFieldsToReplaceWithAnalogues();
	FieldsStructure.AdditionalFields.Insert("Ref", New TypeDescription("DocumentRef.OrderOfMaterialsForProduction"));
	FieldsStructure.DefaultValues.Insert("Ref", Object.Ref);
	FieldsStructure.DefaultValues.Insert("Warehouse", Object.Warehouse);
	
	ProductData_9 = AlternativeMaterials.GetProductData(
		ThisObject, "Object", "Goods", 1, True, FieldsStructure, AdditionalParametersAnaloguesOfMaterials);
		
	OpeningParameters.Insert("InventoryAllocation", ProductData_9.InventoryAllocation);
	OpeningParameters.Insert("Stage", Object.Ref);
	OpeningParameters.Insert("GoodsTableAddress", PutToTempStorage(VT));
	
	Return OpeningParameters;

EndFunction
	
&AtClient
Procedure AfterReplacementViaAssistant(Result, AdditionalParameters) Export
	
	If Result <> Undefined Then
		
		AddressOfTheMovementTable = Undefined;
		UpdateDataAfterReplacementViaAssistant(Result, AddressOfTheMovementTable);
		
		FormParameters = ProvisionInDocumentsClient.SecurityStatusHyperlinkClick(ThisObject);
	
		If FormParameters.ContextOfUse = "TABLE" Then
			
			FormParameters.AddressOfTheMovementTable = AddressOfTheMovementTable;
			
		EndIf;
		
		OpenForm("DataProcessor.OrderSupplyForecast.Form", FormParameters, ThisObject, UUID,,,,
			FormWindowOpeningMode.LockOwnerWindow);
	
	EndIf;

EndProcedure

&AtServer
Procedure UpdateDataAfterReplacementViaAssistant(Address, AddressOfTheMovementTable)

	TableOfCompletedReplacements = GetFromTempStorage(Address);
	DeleteFromTempStorage(Address);
	
	ArrayOfCompletedReplacements = TableOfCompletedReplacements.FindRows(New Structure("NumberHasChanged", True));
	HasChanges = ArrayOfCompletedReplacements.Count() > 0;
	
	If Not HasChanges Then
		Return;
	EndIf;
	
	StructureOfModifiedRows = New Structure;
	StructureOfModifiedRows.Insert("IndexesOfModifiedRows", New Array);
	StructureOfModifiedRows.Insert("IndexesOfNewRows", New Array);
	
	EmptyPackaging = Catalogs.PackagesAndUnitsOfMeasure.EmptyRef();
	
	LinesToDelete = New Array;
	
	For Each RowOfReplacementTable In ArrayOfCompletedReplacements Do
	
		If RowOfReplacementTable.ThisIsASubstitute Then
			
			NewRow = Object.Goods.Add();
			FillPropertyValues(NewRow, RowOfReplacementTable);
			NewRow.NumberOfPackages = NewRow.Count;
			NewRow.WithAssignment = ValueIsFilled(RowOfReplacementTable.Purpose);
			NewRow.Purpose = NewRow.Purpose;
			StructureOfModifiedRows.IndexesOfNewRows.Add(NewRow.LineNumber - 1);
			
		Else
			
			DocumentLine = Object.Goods[RowOfReplacementTable.LineNumberDocument - 1];
			DocumentLine.Count = RowOfReplacementTable.Count;
			DocumentLine.NumberOfPackages = RowOfReplacementTable.Count;
			DocumentLine.Package = EmptyPackaging;
			
			If DocumentLine.Count = 0 Then
				LinesToDelete.Add(DocumentLine);
			EndIf;
			
			StructureOfModifiedRows.IndexesOfModifiedRows.Add(RowOfReplacementTable.LineNumberDocument - 1);
		
		EndIf;
	
	EndDo;
	
	PerformActionsAfterReplacingWithAnalogs(StructureOfModifiedRows);
	
	TMCommonUse.DeleteTableRows(Object.Goods, LinesToDelete);
	
	If Modified
		Or Not AvailableRemainingEmbeddingOptions.InternalParameters.ReadyForSupply
		Or Not ValueIsFilled(Object.Ref)
		Or Not SupplyInDocumentsServerCall.HyperlinkStateOfProvisionClickDocumentCompleted(Object.Ref) Then
	
		AddressOfTheMovementTable = AddressOfMovementTableInRepository();
	
	EndIf;
	
EndProcedure

&AtServer
Procedure PerformActionsAfterReplacingWithAnalogs(Result)
	
	TableName = "Goods";
	
	IndexesOfModifiedRows = Result.IndexesOfModifiedRows;
	IndexesOfNewRows = Result.IndexesOfNewRows;
	
	NewlineIDs_ = New Array;
	
	Modified = True;
	
	StructureOfActions = New Structure;
	CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	
	AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions);
	
	RowsToProcess = New Array();
	
	For Each RowIndex In IndexesOfModifiedRows Do
		
		TableRow = Object[TableName][RowIndex];
		
		If TableRow.Count > 0 Then
			RowsToProcess.Add(TableRow);
		EndIf;
		
	EndDo;
	
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		RowsToProcess,
		StructureOfActions,
		Object[TableName],
		CachedValues);
	
	FillInStartOfShipment = Not Object.ProductionManagement2_2 And Object.NotShipInInstallments;
	
	StructureOfActions.Clear();
	StructureOfActions.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));
	StructureOfActions.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
	
	StructureOfActions.Insert(
		"FillInFeatureAttribute", New Structure("Products", "ItemVariantsAreUsed"));
	
	AddCollateralActionsOnServer(StructureOfActions, "WarehouseIsRequired,DateOfShipmentRequired_");
	
	RowsToProcess = New Array();
	
	For Each RowIndex In IndexesOfNewRows Do
		
		TSRow = Object[TableName][RowIndex];
		TSRow.SupplyAssignment = TSRow.Purpose;
		
		If FillInStartOfShipment Then
			TSRow.ShipmentStart = Object.DateOfShipment;
		EndIf;
		RowsToProcess.Add(TSRow);
		
		NewlineIDs_.Add(TSRow.GetID());
		
	EndDo;
	
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		RowsToProcess,
		StructureOfActions,
		Object[TableName],
		CachedValues);
	
	CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	StructureOfActions.Clear();
	RowsToProcess.Clear();
	
	AddCollateralActionsOnServer(StructureOfActions, "SupplyOption");
	For Each RowIndex In IndexesOfNewRows Do
		
		TSRow = Object[TableName][RowIndex];
		
		If Not ValueIsFilled(TSRow.SupplyOption) Then
			RowsToProcess.Add(TSRow);
		EndIf;
		
	EndDo;

	BatchProcessingOfTablePartServer.ProcessTSStrings(
		RowsToProcess,
		StructureOfActions,
		Object[TableName],
		CachedValues);
	
	StructureOfActions.Clear();
	AddQualityControlActionsToStructure(StructureOfActions, CacheQualityControl, Object.ProductionManagement2_2);
	
	RowsToProcess.Clear();
	
	For Each RowIndex In IndexesOfNewRows Do
		TSRow = Object[TableName][RowIndex];
		If ValueIsFilled(TSRow.ShipmentStart) Then
			TSRow.ReceiptEnd = TSRow.ShipmentStart + Object.TransferDurationDays * 86400;
		EndIf;
		RowsToProcess.Add(TSRow);
	EndDo;
	
	NotShipInInstallmentsOnChangeServer();
	
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		RowsToProcess,
		StructureOfActions,
		Object[TableName],
		CachedValues);
		
	ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);
	ReusablePackageServer.UpdateFillingStateOfMultiTurnContainer(Object.ReusablePackageFillingStatus);
	
	If RightToReadSubstitutes And ShowAnalogues Then
		NotePresenceOfAnalogues();
	EndIf;
	UpdateColumnAvailableServer();

EndProcedure

&AtClientAtServerNoContext
Procedure ReflectAnalogsInSupplyForecastHyperlink(Form)
	
	If Form.RightToReadSubstitutes Then
	
		Object = Form.Object;
		Items = Form.Items;
		ThereAreAnalogues = Form.ThereAreAnalogues;
		HintAvailabilityOfAnalogues = NStr("vi = ' (cho phép thay thế sang vật tư tương tự)';
											|ru = ' (доступна замена на аналоги)';
											|en = ' (replacement with substitutes is available)'; fa = ' (replacement with substitutes is available)';
											|it = ' (replacement with substitutes is available)';
											|pl = ' (replacement with substitutes is available)';
											|tr = ' (İkamelerle değiştirme mümkündür)'");
		
		HyperlinkProperties = SupplyInDocumentsServerCall.PropertiesOfSoftwareStateHyperlink(
			Form.Modified,
			Object.Ref,
			Form.AvailableRemainingEmbeddingOptions.InternalParameters.ReadyForSupply);
		
		ItemsNames = Form.AvailableRemainingEmbeddingOptions.ItemsNames;
			
		FormItem = Items[ItemsNames[HyperlinkProperties.HyperlinkName]];
		
		HyperlinkHeader = FormItem.Title;
		HyperlinkHeader = StrReplace(HyperlinkHeader, HintAvailabilityOfAnalogues, "");
		
		If ThereAreAnalogues Then
			ArrayOfHintTexts = New Array;
			ArrayOfHintTexts.Add(HyperlinkHeader);
			ArrayOfHintTexts.Add(HintAvailabilityOfAnalogues);
			HyperlinkHeader = StrConcat(ArrayOfHintTexts);
		EndIf;
		
		FormItem.Title = HyperlinkHeader;
	
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
	ElsIf Item.Name = "sh_ShamsiInput_DateOfShipment" Then
		DateOfShipmentOnChange(Items.DateOfShipment);
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
