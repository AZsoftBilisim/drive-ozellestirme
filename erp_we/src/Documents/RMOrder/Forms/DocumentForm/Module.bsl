#Region Variables

&AtClient
Var CachedValues;

&AtClient
Var CurDataId; //used to pass the current line to the wait handler

&AtClient
Var LineBeforeEditing; // See NewLineBeforeEditing 

&AtClient
Var FormModified; // it is used to work out the form modification change event

#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	EmbeddingParameters = Documents.RMOrder.AvailableRemainingEmbeddingOptions();
	ProvisionInDocumentsServer.AvailableBalancesWhenCreatedOnServer(ThisObject, EmbeddingParameters);
	
	SetConditionalAppearance();
	
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(Object, ThisObject);
	
	UseBusinessUnits = GetFunctionalOption("UseBusinessUnits");
	
	If Not ValueIsFilled(Object.Ref) Then
		OnReadCreateAtServer();
		ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);
	EndIf;
	
	If Not AccessRight("Edit", Metadata.Documents.RMOrder) Then
		Items.CloseOrder.Visible = False;
		Items.MaterialsAndWorksPickUpProducts.Enabled = False;
	EndIf;
	
	SetAvailabilityOfClipboardCommands();
	
	AddressDataForTheSelectionOfMaterialsByTypeOfRepairs = PutToTempStorage(Undefined, UUID);
	
	#Region StandardSubsystems
	
	TMCommonUse.CustomizePeripherals(ThisForm);

	ObjectsVersioning.OnCreateAtServer(ThisObject);
	
	// StandardSubsystems.Properties
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("ItemForPlacementName", "GroupAdditionalAttributes");
	AdditionalParameters.Insert("DeferredInitialization", True);
	PropertyManager.OnCreateAtServer(ThisObject, AdditionalParameters);
	// End StandardSubsystems.Properties
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	// StandardSubsystems.FilesOperations
	FilesHyperlink = FilesOperations.FilesHyperlink();
	FilesHyperlink.Location = "CommandBar";
	FilesOperations.OnCreateAtServer(ThisObject, FilesHyperlink);
	// End StandardSubsystems.FilesOperations

	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	
	#EndRegion
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject);
	// End IntegrationWith1CDocumentManagementSubsystem
	
	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)
	
	EmbeddingParameters = Documents.RMOrder.AvailableRemainingEmbeddingOptions();
	ProvisionInDocumentsServer.AvailableBalancesWhenReadingOnServer(ThisObject, EmbeddingParameters);
	
	OnReadCreateAtServer();
	
	PeriodClosingDates.ObjectOnReadAtServer(ThisForm, CurrentObject);
	
	// StandardSubsystems.Properties	
	PropertyManager.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.Properties
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	// End StandardSubsystems.AttachableCommands
	
	ConfigurationModificationOverridable.OnReadAtServer(ThisForm, CurrentObject);
	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	CurrentObject.MatchRepairKeysInTablePart(CurrentObject.MaterialsAndWorks);
	CurrentObject.MatchRepairKeysInTablePart(CurrentObject.LaborCosts);

	// StandardSubsystems.Properties
	PropertyManager.BeforeWriteAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.Properties
	
	ConfigurationModificationOverridable.BeforeWriteAtServer(ThisForm, Cancel, CurrentObject, WriteParameters);

	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.BeforeWriteAtServer(
		ThisObject,
		CurrentObject,
		WriteParameters);
	// End IntegrationWith1CDocumentManagementSubsystem
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)
	
	Items.CommentPage.Picture = CommonClientServer.CommentPicture(Object.Comment);
	
	ProvisionInDocumentsServer.AfterWriteAtServer(ThisObject);
	SetSoftwareVisibility();
	FillInServiceDetailsOfDocumentForm();
	
	FillInServiceDetailsForProductRange();
	FillInDataOfInformationTableOfWorkCenters();
	UpdateRepairSelectionLists_();
	
	ConfigurationModificationOverridable.AfterWriteAtServer(ThisForm, CurrentObject, WriteParameters);
	
EndProcedure

&AtClient
Procedure ChoiceProcessing(ValueSelected, ChoiceSource)
	
	Var CurrentOperation1;
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.StartTimeMeasurement(True,
		"Document.RMOrder.Form.DocumentForm.Event.ChoiceProcessing");
	
	If ChoiceSource.FormName = "DataProcessor.OrderSupplyForecast.Form.Form" Then
		
		
		AddressOfTheMovementTable = FillInCollateralFromCollateralStateForm(
			ValueSelected.ActionCode,
			ValueSelected.AddressAnalyst,
			ValueSelected.FillParameters);
			
		// Returning the control to the form of processing the security status.
		RunCallback(ValueSelected.Callback, AddressOfTheMovementTable);
		
	ElsIf ChoiceSource.FormName = "DataProcessor.SelectGoodsToSalesDocument.Form.Form" Then
		
		HandlingSelectionSelectionOnClient(ValueSelected);
		
	ElsIf TypeOf(ValueSelected) = Type("Structure") And ValueSelected.Property("CurrentOperation1", CurrentOperation1) Then
		
		If Upper(CurrentOperation1) = Upper("SelectRepairs") Then
			
			ProcessingSelectionOfRepairs(ValueSelected.Tables);
			
		EndIf;
		
	ElsIf ProductsClient.ThisIsIndicationOfSeries(ChoiceSource) Then
		
		ProductsClient.ProcessSeriesIndication(ThisForm, SeriesSpecificationParameters, ValueSelected);
		
	ElsIf ChoiceSource.FormName = "DataProcessor.OrderClosureWizard.Form.ClosureForm" Then
		
		CancellationResult = AdjustOrderLines(ValueSelected);
		ShowUserNotification(NStr("vi = 'Hủy bỏ dòng không được xử lý';
									|ru = 'Отмена неотработанных строк';
									|en = 'Cancel unfulfilled lines'; fa = 'Cancel unfulfilled lines';
									|it = 'Annullamento delle righe non elaborate';
									|pl = 'Anulowanie nieprzetworzonych wierzszy';
									|tr = 'İşlenmemiş satır iptali'"), , CancellationResult.Notification);
		
	EndIf;
	ProvisionInDocumentsClientServer.FillInServiceDetails(Object.MaterialsAndWorks, DateOfShipmentRequired_, WarehouseIsRequired);
	
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	
	WriteParameters.Insert("NotificationDocumentKeys", OperationsWithDocumentJournalsClient.GetKeyParametersForDocument(
		Object.Ref, Object.Date, Object.BusinessOperation));
	Notify("Write_RMOrder", WriteParameters, Object.Ref);
	TMCommonUseClient.NotifyAboutEntryOfDocumentInJournal();
	
	FormModified = Undefined;
	Attachable_WhenChangingModifiabilityOfForm();
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

&AtClient
Procedure OnOpen(Cancel)
	
	AttachIdleHandler("Attachable_WhenChangingModifiabilityOfForm", 1);
	
	EquipmentManagerClient.StartConnectingDevicesWhenYouOpenForm(Undefined, ThisObject, "BarcodeScanner");
	
	// StandardSubsystems.Properties
	PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
	// End StandardSubsystems.Properties
	
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
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	// Peripherals
	If IsInputAvailable()
		And Source = "Peripherals" Then
		
		If EventName = "ScanData"
			And EquipmentManagerTMClient.ThereIsRawEvent() Then
			
			ProcessProductBarcodes(EquipmentManagerTMClient.ConvertDataFromScannerToArray(Parameter));
			
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
		
		ProcessProductBarcodes(BarcodeData_5);
		
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
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	
	// StandardSubsystems.Properties
	PropertyManager.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes);
	// End StandardSubsystems.Properties
	
EndProcedure

&AtServer
Procedure OnLoadDataFromSettingsAtServer(Settings)
	
	HideShowLines(ThisObject);

EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure DateOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	
	UpdateConsumptionForActivities();
	
EndProcedure

&AtClient
Procedure BusinessOperationOnChange(Item)
	BusinessOperationWhenChangingOnServer();
EndProcedure

&AtClient
Procedure AssetOnChange(Item)
	ObjectOfOperationWhenChangedOnServer()
EndProcedure

&AtClient
Procedure StatusOnChange(Item)
	StatusChangedOnServer();
EndProcedure

&AtServer
Procedure StatusChangedOnServer()
	If Object.Status = Enums.RMOrderStatuses.Running
		And Not ValueIsFilled(Object.StartDateActual) Then
		
		Object.StartDateActual = CurrentSessionDate();
		
	ElsIf Object.Status = Enums.RMOrderStatuses.Closed
		And Not ValueIsFilled(Object.ActualCompletionDate)Then
		
		Object.ActualCompletionDate = CurrentSessionDate();
		
	EndIf;
	FillInServiceDetailsOfDocumentForm();
	
EndProcedure

&AtClient
Procedure PagesOnCurrentPageChange(Item, CurrentPage)
	
	If UpdateRepairSelectionLists Then
		UpdateRepairSelectionLists_();
	EndIf;
	
	// StandardSubsystems.Properties
	If ThisObject.PropertiesParameters.Property(CurrentPage.Name)
			And Not ThisObject.PropertiesParameters.DeferredInitializationExecuted Then
		
		PropertiesExecuteDeferredInitialization();
		PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
	EndIf;
	// End StandardSubsystems.Properties
	
EndProcedure

&AtClient
Procedure OrganizationOnChange(Item)
	
	OrganizationWhenChangedOnServer();
	
EndProcedure

&AtClient
Procedure LineOfBusinessOnChange(Item)
	
	DirectionOfActivityWhenChangingOnServer();
	
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

#Region FormTableItemsEventHandlersRM

&AtClient
Procedure RMOnStartEdit(Item, NewRow, Copy)
	
	If NewRow Then
		
		UpdateRepairSelectionLists = True;
		
		If Copy Then
			CurrentData = Items.RM.CurrentData;
			CurrentData.RMCode = 0;
		EndIf;
		
	EndIf;

EndProcedure

&AtClient
Procedure RMAfterDeleteRow(Item)
	
	UpdateRepairSelectionLists = True;
	
	ConfigureDependentFormElementsOnServer("RM");
	
EndProcedure

&AtClient
Procedure RMNodeOnChange(Item)
	RepairsNodeWhenItChangesOnServer(Items.RM.CurrentRow);
EndProcedure

&AtClient
Procedure RMRMTypeOnChange(Item)
	
	RepairsTypeOfRepairWhenModifiedOnServer();
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersMaterialsAndWorks

&AtClient
Procedure MaterialsAndWorksSelection(Item, RowSelected, Field, StandardProcessing)
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.StartTimeMeasurement(
		True, "Document.RMOrder.Form.DocumentForm.Item.MaterialsAndWorks.Selection");
	
	If Item.CurrentItem = Items.MaterialsAndWorksAvailable And Not ReadOnly Then
		
		StandardProcessing = False;
		
		FormParameters = ParametersOfQuantityAndSeriesRequestForm(Undefined);
		
		If FormParameters <> Undefined Then
			OpenForm("DataProcessor.QuantityAndBatchRequest.Form", FormParameters, ThisObject);
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure MaterialsAndWorksOnStartEdit(Item, NewRow, Copy)
	
	ProcessingOfTabularFormsClient.CacheCurLine(Items.MaterialsAndWorks, ThisObject);
	CurrentData = Items.MaterialsAndWorks.CurrentData;
	
	If NewRow Then
		
		CurrentData.RowCode = 0;
		
	EndIf;
	
	If Copy Then
		StructureOfActions = New Structure;
		AddCollateralActionsOnClient(StructureOfActions, "SupplyOption,Available,WarehouseIsRequired,DateOfShipmentRequired_");
		StructureOfActions.Insert("CheckSeriesCalculateStatus", New Structure("Warehouse, SeriesSpecificationParameters", CurrentData.Warehouse, SeriesSpecificationParameters));
		BatchProcessingOfTablePartClient.ProcessTSString(CurrentData, StructureOfActions, CachedValues);
	EndIf;
	ProvisionInDocumentsClientServer.FillInServiceDetails(Object.MaterialsAndWorks, DateOfShipmentRequired_, WarehouseIsRequired);
	
EndProcedure

&AtClient
Procedure MaterialsAndWorksProductsOnChange(Item)
	
	CurrentRow = Items.MaterialsAndWorks.CurrentData;
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("CheckCharacteristicsByOwner", CurrentRow.Characteristic);
	StructureOfActions.Insert("CheckFillPackageByOwner", CurrentRow.Package);
	StructureOfActions.Insert("RecalculateNumberOfUnits");
	StructureOfActions.Insert("FillInFeatureAttribute", New Structure("Products", "ItemVariantsAreUsed"));
	StructureOfActions.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
	StructureOfActions.Insert("CheckSeriesCalculateStatus", New Structure("Warehouse, SeriesSpecificationParameters", CurrentRow.Warehouse, SeriesSpecificationParameters));

	StructureOfActions.Insert("ProductsOnChangeOverridable", New Structure("FormName, TabularSectionName",
		ThisForm.FormName, "MaterialsAndWorks"));

	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
	FillOutWarehouseByContentTransferSettings();
	
	StructureOfActions = New Structure;
	AddCollateralActionsOnClient(StructureOfActions, "SupplyOption,AvailableInOtherLines,WarehouseIsRequired,DateOfShipmentRequired_");
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
	If ProvisionInDocumentsClient.YouNeedToUpdateAvailableColumn(StructureOfActions) Then
		UpdateColumnAvailableServer();
	EndIf;
	
	ProvisionInDocumentsClientServer.FillInServiceDetails(Object.MaterialsAndWorks, DateOfShipmentRequired_, WarehouseIsRequired);
	
EndProcedure

&AtClient
Procedure MaterialsAndWorksCharacteristicOnChange(Item)
	
	CurrentRow = Items.MaterialsAndWorks.CurrentData;
	
	StructureOfActions = New Structure;
	AddCollateralActionsOnClient(StructureOfActions, "SupplyOption,AvailableInOtherLines,WarehouseIsRequired,DateOfShipmentRequired_");
	
	StructureOfActions.Insert("CharacteristicOnChangeOverridable", New Structure("FormName, TabularSectionName",
		ThisForm.FormName, "MaterialsAndWorks"));

	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
	FillOutWarehouseByContentTransferSettings();
	
	ProvisionInDocumentsClientServer.FillInServiceDetails(Object.MaterialsAndWorks, DateOfShipmentRequired_, WarehouseIsRequired);
	If ProvisionInDocumentsClient.YouNeedToUpdateAvailableColumn(StructureOfActions) Then
		UpdateColumnAvailableServer();
	EndIf;
	
EndProcedure

&AtClient
Procedure MaterialsAndWorksPackageOnChange(Item)
	
	CurrentRow = Items.MaterialsAndWorks.CurrentData;
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateNumberOfUnits");
	AddCollateralActionsOnClient(StructureOfActions, "AvailableInOtherLines");
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	If ProvisionInDocumentsClient.YouNeedToUpdateAvailableColumn(StructureOfActions) Then
		UpdateColumnAvailableServer();
	EndIf;
	
EndProcedure

&AtClient
Procedure MaterialsAndWorksNumberOfPackagesOnChange(Item)
	
	CurrentRow = Items.MaterialsAndWorks.CurrentData;
	
	StructureOfActions = New Structure;
	AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions);
	AddCollateralActionsOnClient(StructureOfActions, "AvailableInOtherLines");
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	If ProvisionInDocumentsClient.YouNeedToUpdateAvailableColumn(StructureOfActions) Then
		UpdateColumnAvailableServer();
	EndIf;
	
EndProcedure

&AtClient
Procedure MaterialsAndWorksRMCodeOnChange(Item)
	
	CurrentData = Items.MaterialsAndWorks.CurrentData;
	MaterialsWhenChangingRepairCode(CurrentData);
	
EndProcedure

&AtClient
Procedure MaterialsAndWorksCanceledOnChange(Item)
	
	CurrentRow = Items.MaterialsAndWorks.CurrentData;
	
	StructureOfActions = New Structure;
	AddCollateralActionsOnClient(StructureOfActions, "AvailableInOtherLines,WarehouseIsRequired,DateOfShipmentRequired_");
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	If ProvisionInDocumentsClient.YouNeedToUpdateAvailableColumn(StructureOfActions) Then
		UpdateColumnAvailableServer();
	EndIf;
	
	ProvisionInDocumentsClientServer.FillInServiceDetails(Object.MaterialsAndWorks, DateOfShipmentRequired_, WarehouseIsRequired);
	
EndProcedure

&AtClient
Procedure MaterialsAndWorksSeriesStartChoice(Item, ChoiceData, StandardProcessing)
	StandardProcessing = False;
	OpenSelectionOfSeries(Item.EditText);
EndProcedure

&AtClient
Procedure MaterialsAndWorksSeriesOnChange(Item)
	
	ValueSelected = ProductsClientServer.SelectedSeries();
	
	ValueSelected.Value            		 = Items.MaterialsAndWorks.CurrentData.Series;
	ValueSelected.CurrentRowID = Items.MaterialsAndWorks.CurrentData.GetID();
	
	ProductsClient.ProcessSeriesIndication(ThisForm, SeriesSpecificationParameters, ValueSelected);

EndProcedure

&AtClient
Procedure MaterialsAndWorksWarehouseOnChange(Item)
	
	CurrentRow = Items.MaterialsAndWorks.CurrentData;
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("CheckSeriesCalculateStatus", New Structure("Warehouse, SeriesSpecificationParameters", CurrentRow.Warehouse, SeriesSpecificationParameters));
	AddCollateralActionsOnClient(StructureOfActions, "AvailableInOtherLines");

	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
	If ProvisionInDocumentsClient.YouNeedToUpdateAvailableColumn(StructureOfActions) Then
		UpdateColumnAvailableServer();
	EndIf;
	
	ProvisionInDocumentsClientServer.FillInServiceDetails(Object.MaterialsAndWorks, DateOfShipmentRequired_, WarehouseIsRequired);
	
EndProcedure

&AtClient
Procedure MaterialsAndWorksRMCodeOpening(Item, StandardProcessing)
	
	StandardProcessing = False;
	
	CurrentData = Items.MaterialsAndWorks.CurrentData;
	
	If Not ValueIsFilled(CurrentData.RMCode) Then
		Return;
	EndIf;
	
	TheStructureOfTheSearch = New Structure("RMCode", CurrentData.RMCode);
	StringsList = Object.RM.FindRows(TheStructureOfTheSearch);
	If StringsList.Count() <> 0 And ValueIsFilled(StringsList[0].RMType) Then
		ShowValue(, StringsList[0].RMType);
	EndIf;
	
EndProcedure

&AtClient
Procedure MaterialsAndWorksSupplyOptionOnChange(Item)
	
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
		"MaterialsAndWorksAreSecurityOptionWhenChangingOnClient");
	
EndProcedure

&AtClient
Procedure MaterialsAndWorksSupplyOptionClearing(Item, StandardProcessing)
	
	StandardProcessing = False;
	
EndProcedure

&AtClient
Procedure MaterialsAndWorksSupplyOptionChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	ProvisionInDocumentsClient.SupplyOptionChoiceProcessing(
		ThisObject,
		Items.MaterialsAndWorks.CurrentData,
		ValueSelected);
	
EndProcedure

&AtClient
Procedure MaterialsAndWorksWithAssignmentOnChange(Item)
	
	TableRow = Items.MaterialsAndWorks.CurrentData;
	ProvisionInDocumentsClient.WithAssignmentOnChange(TableRow);
	StructureOfActions = New Structure();
	AddCollateralActionsOnClient(StructureOfActions, "AvailableInOtherLines");
	BatchProcessingOfTablePartClient.ProcessTSString(TableRow, StructureOfActions, Undefined);
	
	If ProvisionInDocumentsClient.YouNeedToUpdateAvailableColumn(StructureOfActions) Then
		UpdateColumnAvailableServer();
	EndIf;
	
EndProcedure

&AtClient
Procedure MaterialsAndWorksWarehouseStartChoice(Item, ChoiceData, StandardProcessing)
	
	FormParameters = ParametersOfQuantityAndSeriesRequestForm(ProvisionInDocumentsClientServer.WarehouseSelectionMode());
	
	If TypeOf(FormParameters) = Type("Structure") Then
		
		StandardProcessing = False;
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
Procedure MaterialsAndWorksAfterDeleteRow(Item)
	
	ProvisionInDocumentsClientServer.FillInServiceDetails(Object.MaterialsAndWorks, DateOfShipmentRequired_, WarehouseIsRequired);
	UpdateColumnAvailableServer();
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersLaborCosts

&AtClient
Procedure LaborCostsRMCodeOnChange(Item)
	
	CurrentData = Items.LaborCosts.CurrentData;
	If ValueIsFilled(CurrentData.RMCode) Then
		RepairStructure = RepairStructure(CurrentData.RMCode, ThisObject);
		If RepairStructure = Undefined Then
			RepairStructure = New Structure("RMCode, RepairPerformance", 0, "");
		EndIf;
		FillPropertyValues(CurrentData, RepairStructure);
	EndIf;
	
EndProcedure

&AtClient
Procedure LaborCostsOnStartEdit(Item, NewRow, Copy)
	
	CurrentData = Items.LaborCosts.CurrentData;
	
	If NewRow Then
		CurrentData.RowCode = 0;
	EndIf;
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersWorkCenters

&AtClient
Procedure WorkCentersOnStartEdit(Item, NewRow, Copy)
	
	CurrentData = Items.WorkCenters.CurrentData;
	
	LineBeforeEditing = NewLineBeforeEditing();
	FillPropertyValues(LineBeforeEditing, CurrentData);
	
	If NewRow Then
		// When adding a line, fill in the details "Start Date" and "End Date" according to the header of the document.
		FillPropertyValues(CurrentData, Object, "StartDate, CompletedOn");
	EndIf;
	
EndProcedure

&AtClient
Procedure WorkCentersOnEditEnd(Item, NewRow, CancelEdit)
	
	CurrentData = Items.WorkCenters.CurrentData;
	If Not CancelEdit
		And Not (LineBeforeEditing.WorkCenter = CurrentData.WorkCenter
				And LineBeforeEditing.StartDate = CurrentData.StartDate
				And LineBeforeEditing.CompletedOn = CurrentData.CompletedOn) Then
		
		FillInDataOfInformationTableOfWorkCenters(Items.WorkCenters.CurrentRow);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure WorkCentersSelection(Item, RowSelected, Field, StandardProcessing)
	
	SelectedData = Object.WorkCenters.FindByID(RowSelected);
	
	If Field.Name = "WorkCentersAvailabilityPicture"
		And ValueIsFilled(SelectedData.WorkCenter) Then
		
		If SelectedData.AvailabilityPicture = 1 Then
			WarningText = NStr("vi = 'Đối với nguồn lực sản xuất ""%RC%"" trong kỳ được chọn đã chỉ ra tính khả dụng.
			|Cần thống nhất các công việc sửa chữa với lịch biểu khả dụng của nguồn lực sản xuất';
			|ru = 'Для рабочего центра ""%RC%"" на указанный период указана доступность.
			|Необходимо согласовать ремонтные работы с графиком доступности рабочего центра';
			|en = 'Availability is specified for the ""%RC%"" work center for the given period.
			|Reconcile R&M activities with the work center availability schedule'; fa = 'Availability is specified for the ""%RC%"" work center for the given period.
			|Reconcile R&M activities with the work center availability schedule';
			|it = 'Per il centro di lavoro ""%RC%"" per il periodo specificato viene indicata la disponibilità.
			|È necessario coordinare i lavori di manutenzione con il piano di disponibilità del centro di lavoro';
			|pl = 'Dla centrum pracy ""%RC%"" na wskazany okres jest wskszana dostępność.
			|Należy uzgodnić prace remontowe z harmonogramem dostępności centrum pracy';
			|tr = '""%RC%"" iş merkezi için, belirtilen süre için kullanılabilirlik belirtilir. 
			| Onarım çalışmalarını iş merkezi kullanılabilirlik programı ile koordine etmek gerekir'");
		ElsIf SelectedData.AvailabilityPicture = 2 Then
			WarningText = NStr("vi = 'Đối với nguồn lực sản xuất ""%RC%"" trong kỳ được chọn đã lập kế hoạch công việc.
			|Cần thống nhất các công việc sửa chữa với lịch biểu sản xuất';
			|ru = 'Для рабочего центра ""%RC%"" на указанный период запланированы работы.
			|Необходимо согласовать ремонтные работы с графиком производства';
			|en = 'Works are scheduled for the ""%RC%"" work center for the specified period.
			|Reconcile R&M activities with the production schedule'; fa = 'Works are scheduled for the ""%RC%"" work center for the specified period.
			|Reconcile R&M activities with the production schedule';
			|it = 'Per il centro di lavoro ""%RC%"" per il periodo specificato sono pianificati i lavori.
			|È necessario coordinare i lavori di manutenzione con il programma di produzione';
			|pl = 'Dla centrum pracy ""%RC%"" na wskazany okres są zaplanowane prace.
			|Należy uzgodnić prace remontowe z harmonogramem produkcji';
			|tr = '""%RC%"" iş merkezi için belirtilen süre boyunca çalışma planlanmıştır.
			| Onarım çalışmalarının üretim programı ile koordine edilmesi gereklidir'");
		Else
			WarningText = NStr("vi = 'Nguồn lực sản xuất ""%RC%"" trong kỳ được chỉ định có thể sử dụng cho công việc sửa chữa';
								|ru = 'Рабочий центр ""%RC%"" на указанный период доступен для ремонтных работ';
								|en = 'Work center ""%RC%"" is available for R&M activities within the specified period'; fa = 'Work center ""%RC%"" is available for R&M activities within the specified period';
								|it = 'Il centro di lavoro ""%RC%"" per il periodo specificato è disponibile per i lavori di manutenzione';
								|pl = 'Centrum pracy ""%RC%"" na wskazany okres jest dostępny dla prac remontowych';
								|tr = '""%RC%"" iş merkezi belirtilen süre boyunca onarım çalışmaları için kullanılabilir'");
		EndIf;
		
		WarningText = StrReplace(WarningText, "%RC%", SelectedData.WorkCenter);
		
		ShowMessageBox(Undefined, WarningText);
		
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

#Region Header

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

&AtClient
Procedure CloseOrder(Command)
	
	If Modified Or Not Object.Posted Then
		ShowQueryBox(New CallbackDescription("CloseOrderCompletion", ThisObject),
			NStr("vi = 'Cần kết chuyển chứng từ để hoàn thành giao dịch. Kết chuyển chứng từ?';
				|ru = 'Необходимо провести документ для выполнения операции. Провести документ?';
				|en = 'To proceed, you need to post the document. Do you want to post the document?'; fa = 'To proceed, you need to post the document. Do you want to post the document?';
				|it = 'È necessario registrare il documento per eseguire operazione. Registrare documento?';
				|pl = 'Należy zaksięgować dokument aby wykonać operację. Zaksięgować dokument?';
				|tr = 'Bir işlemin gerçekleştirilmesi için belgenin düzenlenmesi gerekir. Belge düzenlensin mi?'"), QuestionDialogMode.YesNo);
		Return;
	EndIf;
	
	CloseOrderFragment();
	
EndProcedure

#EndRegion

#Region RM

&AtClient
Procedure RepairsPickUp(Command)
	
	FormParameters = RepairSelectionFormParameters();
	
	OpenForm("Document.RMOrder.Form.RMChoiceForm", 
		FormParameters, 
		ThisForm,,,, 
		Undefined, 
		FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure RepairsSearchByBarcode(Command)
	
	ClearMessages();
	Notification = New CallbackDescription("RepairsSearchByBarcodeCompletion", ThisObject);
	BarcodingOfItemsClient.ShowBarcodeInput(Notification);

EndProcedure

#EndRegion

#Region MaterialsAndWorks

&AtClient
Procedure SelectGoods(Command)
	
	FormParameters = New Structure;
	FormParameters.Insert("SelectionModeWithoutAmountParameters", True);
	FormParameters.Insert("FilterByProductType", New FixedArray(ProductsClientServer.SelectionByProductReusablePackagingWork(False)));
	FormParameters.Insert("UseShipmentDates", True);
	FormParameters.Insert("HideTheViewPriceColumn", True);
	FormParameters.Insert("HideTheItemPricesCommand", True);
	FormParameters.Insert("Title", NStr("vi = 'Lựa chọn nguyên vật liệu và công việc';
										|ru = 'Подбор материалов и работ';
										|en = 'Pick materials and works'; fa = 'انتخاب مواد و کارها';
										|it = 'Selezione di materiali e lavori';
										|pl = 'Dobór materiałów i prac';
										|tr = 'Malzeme ve iş seçimi'"));
	FormParameters.Insert("Date", Object.Date);
	FormParameters.Insert("Document", Object.Ref);
	FormParameters.Insert("SeriesSpecificationParameters", SeriesSpecificationParameters);
	FormParameters.Insert("Purpose", Object.Purpose);
	FormParameters.Insert("Department", Object.Department);
	FormParameters.Insert("SelectSupplyOptions", True);
	FormParameters.Insert("AvailableRemainingDocumentParameters", Undefined);
	FormParameters.Insert("AllWarehouseBalance", True);
	
	OpenForm("DataProcessor.SelectGoodsToSalesDocument.Form", FormParameters, ThisForm, UUID);
	
EndProcedure

&AtClient
Procedure MaterialsToFillInForRepairs(Command)
	
	PrepareDataForSelectionOfMaterialsForTypesOfRepairs();

	CallbackDescription = New CallbackDescription("SelectMaterialsByRMTypesCompletion", ThisObject);
	FormParameters = New Structure;
	FormParameters.Insert("AddressOrderDetails", AddressDataForTheSelectionOfMaterialsByTypeOfRepairs);	
	OpenForm("Document.RMOrder.Form.SelectMaterialsByRMTypes", 
		FormParameters,, UUID,,, CallbackDescription);
	
EndProcedure

&AtClient
Procedure MaterialsToSplitTheString(Command)
	
	FormTable  = Items.MaterialsAndWorks;
	TableData = Object.MaterialsAndWorks;
	
	Notification = New CallbackDescription("MaterialsAndWorksSplitLineCompletion", ThisObject);
	ProcessingOfTabularFormsClient.SplitRow(TableData, FormTable, Notification);
	
EndProcedure

&AtClient
Procedure MaterialsToCancelTheSelectedRow(Command)
	
	UndoSelectedLinesOfLineServer();
	ProvisionInDocumentsClientServer.FillInServiceDetails(Object.MaterialsAndWorks, DateOfShipmentRequired_, WarehouseIsRequired);
	
EndProcedure

&AtClient
Procedure CancelUnprocessedMaterials_3(Command)
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.StartTimeMeasurement(True,
		"Document.RMOrder.Form.DocumentForm.Command.MaterialsAndWorksCancelUnprocessed");
	
	CancellationResult = CancelUnprocessedServer();
	ShowUserNotification(NStr("vi = 'Hủy bỏ hàng không được xử lý';
								|ru = 'Отмена неотработанных строк';
								|en = 'Cancel unfulfilled lines'; fa = 'Cancel unfulfilled lines';
								|it = 'Annullamento delle righe non elaborate';
								|pl = 'Anulowanie nieprzetworzonych wierzszy';
								|tr = 'İşlenmemiş satır iptali'"), , CancellationResult.Notification);
	
EndProcedure

&AtClient
Procedure MaterialsFillInTheWarehouseBySettingUp(Command)
	
	FillOutWarehouseByContentTransferSettings();
	
EndProcedure

&AtClient
Procedure MaterialsFillInTheWarehouse(Command)

	SelectedRows = Items.MaterialsAndWorks.SelectedRows;
	
	If WarehousesClient.CheckPossibilityOfFillingWarehousesInTablePart(Object, Object.MaterialsAndWorks, NStr("vi = 'Nguyên vật liệu và nhân công';
																												|ru = 'Материалы и работы';
																												|en = 'Materials and works'; fa = 'Materials and works';
																												|it = 'Materiali e lavori';
																												|pl = 'Materiały i prace';
																												|tr = 'Malzemeler ve işler'"), SelectedRows) Then
		
		FilterArray = New Array();
		FilterArray.Add(PredefinedValue("Enum.SelectWarehouseGroup.AllowInOrders"));
		FilterArray.Add(PredefinedValue("Enum.SelectWarehouseGroup.AllowInOrdersAndInvoices"));
		FilterStructure1 = New Structure("SelectGroup, IsFolder", FilterArray, False);
		ParametersStructure = New Structure("Filter", FilterStructure1);
		
		CallbackDescription = New CallbackDescription("MaterialsFillInTheWarehouseCompletion",
			ThisObject, New Structure("SelectedRows", SelectedRows));
		
		OpenForm("Catalog.Warehouses.ChoiceForm", 
			ParametersStructure, ThisObject,,,, CallbackDescription, FormWindowOpeningMode.LockOwnerWindow);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure MaterialsHideCanceledLines_3(Command)
	
	HideShowLines(ThisObject);
	
EndProcedure

&AtClient
Procedure UsedMaterials_ImportDataFromPDT(Command)
	
	ClearMessages();
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.StartTimeMeasurement(True,
		"Document.RMOrder.DocumentForm.Command.UsedMaterials_ImportDataFromPDT");
	
	EquipmentManagerClient.StartDownloadingDataFromTSD(
		New CallbackDescription("UsedMaterials_ImportDataFromPDTCompletion", ThisObject),
		UUID);
	
EndProcedure

&AtClient
Procedure MaterialsSearchByBarcode(Command)
	
	ClearMessages();
	Notification = New CallbackDescription("MaterialsSearchByBarcodeCompletion", ThisObject);
	BarcodingOfItemsClient.ShowBarcodeInput(Notification);

EndProcedure

&AtClient
Procedure MaterialsFillInTheTypeOfRepair(Command)
	
	If Items.MaterialsAndWorks.SelectedRows.Count() = 0 Then
		ShowMessageBox(, NStr("vi = 'Cần chọn các dòng trong danh sách mà cần điền dạng sửa chữa';
								|ru = 'Необходимо выбрать строки в списке, для которых нужно заполнить вид ремонта';
								|en = 'Select the lines in the list that require the R&M work to be filled in'; fa = 'Select the lines in the list that require the R&M work to be filled in';
								|it = 'È necessario selezionare le righe nell''elenco per le quali deve essere compilato il tipo di riparazione';
								|pl = 'Należy wybrać wiesze na liście, dla których należy wypełnić rodzaj naprawy';
								|tr = 'Listede, onarım türünü doldurmak istediğiniz satırları seçmeniz gerekir'"));
		Return;
	EndIf;
	
	ChoiceList = New ValueList();
	
	For Each RowData In Object.RM Do
		If ValueIsFilled(RowData.RMType)
			And ChoiceList.FindByValue(RowData.RMCode) = Undefined Then
			ChoiceList.Add(RowData.RMCode, String(RowData.RMType));
		EndIf;
	EndDo;

	If ChoiceList.Count() = 0 Then
		ShowMessageBox(, NStr("vi = 'Trong danh sách ""Sửa chữa"" cần điền dạng sửa chữa';
								|ru = 'Необходимо в списке ""Ремонты"" заполнить вид ремонта';
								|en = 'Fill in R&M work in the ""R&M"" list'; fa = 'Fill in R&M work in the ""R&M"" list';
								|it = 'È necessario compilare il tipo di riparazione nell''elenco ""Riparazioni""';
								|pl = 'Na liście ""Naprawy"" należy wypełnić rodzaj naprawy';
								|tr = '""Onarımlar"" listesindeki onarım türünü doldurmak gerekir'"));
		Return;
	EndIf;

	CallbackDescription = New CallbackDescription("MaterialsFillInTheTypeOfRepairCompletion", ThisObject);
	ChoiceList.ShowChooseItem(CallbackDescription, NStr("vi = 'Hãy chọn dạng sửa chữa';
														|ru = 'Выберите вид ремонта';
														|en = 'Select R&M work'; fa = 'Select R&M work';
														|it = 'Selezionare il tipo di riparazione';
														|pl = 'Wybierz rodzaj naprawy';
														|tr = 'Onarım türünü seçin'"));
	
EndProcedure

#EndRegion

#Region WorkCenters

&AtClient
Procedure WorkCentersFillIn(Command)
	
	If Object.WorkCenters.Count() = 0 Then
		
		WorkCentersFillUpOnServer();
		
	Else
		
		QueryText = NStr("vi = 'Trong phần bảng có các dòng điền';
						|ru = 'В табличной части имеются заполненные строки';
						|en = 'Filled rows are found in the table'; fa = 'Filled rows are found in the table';
						|it = 'Nella parte tabulare ci sono righe compilate';
						|pl = 'W części tabelarycznej są wypełnione wiersze';
						|tr = 'Tablo bölümünde doldurulmuş çizgiler vardır'");
		AnswersOptions = New ValueList;
		AnswersOptions.Add(DialogReturnCode.OK, NStr("vi = 'Điền lại phần bảng';
													|ru = 'Перезаполнить таблицу';
													|en = 'Refill table'; fa = 'Refill table';
													|it = 'Ricompilare la tabella';
													|pl = 'Ponownie wypełni tabelę';
													|tr = 'Tabloyu yeniden doldur'"));
		AnswersOptions.Add(DialogReturnCode.Cancel, NStr("vi = 'Hủy bỏ';
														|ru = 'Отменить';
														|en = 'Cancel'; fa = 'انصراف';
														|it = 'Annullare';
														|pl = 'Cancel';
														|tr = 'İptal et'"));
		
		ShowQueryBox(New CallbackDescription("WorkCentersFillInCompletion", ThisObject), QueryText, AnswersOptions);
		
	EndIf;
	
EndProcedure

#EndRegion

#Region LaborCosts

&AtClient
Procedure LaborCostsToFillInForRepairs(Command)
	
	If Object.LaborCosts.Count() = 0 Then
		
		FillLaborCostsForRepairs();
		
	Else
		
		QueryText = NStr("vi = 'Trong phần bảng có các dòng điền';
						|ru = 'В табличной части имеются заполненные строки';
						|en = 'Filled rows are found in the table'; fa = 'Filled rows are found in the table';
						|it = 'Nella parte tabulare ci sono righe compilate';
						|pl = 'W części tabelarycznej są wypełnione wiersze';
						|tr = 'Tablo bölümünde doldurulmuş çizgiler vardır'");
		AnswersOptions = New ValueList;
		AnswersOptions.Add(DialogReturnCode.OK, NStr("vi = 'Điền lại phần bảng';
													|ru = 'Перезаполнить таблицу';
													|en = 'Refill table'; fa = 'Refill table';
													|it = 'Ricompilare la tabella';
													|pl = 'Ponownie wypełni tabelę';
													|tr = 'Tabloyu yeniden doldur'"));
		AnswersOptions.Add(DialogReturnCode.Cancel, NStr("vi = 'Hủy bỏ';
														|ru = 'Отменить';
														|en = 'Cancel'; fa = 'انصراف';
														|it = 'Annullare';
														|pl = 'Cancel';
														|tr = 'İptal et'"));
		
		ShowQueryBox(New CallbackDescription("LaborCostsToFillInForRepairsCompletion", ThisObject), QueryText, AnswersOptions);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure TheEffortToUndoTheHighlightedRows(Command)
	
	StructureOfCancelledRow = New Structure("Canceled", True);
	
	For Each RowID In Items.LaborCosts.SelectedRows Do
		
		TableRow = Object.LaborCosts.FindByID(RowID);
		
		If TableRow <> Undefined Then
			
			FillPropertyValues(TableRow, StructureOfCancelledRow);
			
		EndIf;
		
	EndDo;
	
EndProcedure

&AtClient
Procedure TheEffortToCancelTheOutstandingLine(Command)
	
	CheckBalance = True;
	
	If Not Object.Posted Then
		
		QueryText = NStr("vi = 'Chưa kết chuyển đơn hàng, chưa lập kế hoạch cho công việc của người lao động theo đơn hàng.
							|Tất cả các dòng sẽ bị hủy. Tiếp tục?';
							|ru = 'Заказ не проведен, оформление работ сотрудников по заказу не запланировано.
							|Будут отменены все строки. Продолжить?';
							|en = 'The order has not been posted, employees'' works have not been scheduled.
							|All lines will be canceled. Continue?'; fa = 'The order has not been posted, employees'' works have not been scheduled.
							|All lines will be canceled. Continue?';
							|it = 'L''ordine non è registrato, la formalizzazione dei lavori dei dipendenti per l''ordine non è prevista.
							|Tutte le righe verranno annullate. Continuare?';
							|pl = 'Zamówienie nie jest zatwierdzone, sporządzenie prac pracowników według zamówienia nie jest zaplanowane.
							|Będą anulowane wszystkie wiersze. Kontynuować?';
							|tr = 'Sipariş verilmemiştir, sipariş için herhangi bir çalışan planlanmamıştır.
							| Tüm satırlar iptal edilecektir. Devam edilsin mi?'");
							
		CallbackDescription = New CallbackDescription("LaborToCancelUnfulfilledRowsAfterQuestion", ThisObject);
		ShowQueryBox(CallbackDescription, QueryText, QuestionDialogMode.YesNo);
        
        Return;
		
	ElsIf Object.Status = PredefinedValue("Enum.RMOrderStatuses.Created") Then
		
		QueryText = NStr("vi = 'Đã kết chuyển đơn hàng với trạng thái %Status%, chưa lập kế hoạch cho công việc của người lao động theo đơn hàng.
							|Tất cả các dòng sẽ bị hủy. Tiếp tục?';
							|ru = 'Заказ проведен в статусе %Status%, оформление работ сотрудников по заказу не запланировано.
							|Будут отменены все строки. Продолжить?';
							|en = 'The order is posted with status %Status%, works for employees have not been planned for this order.
							|All lines will be canceled. Continue?'; fa = 'The order is posted with status %Status%, works for employees have not been planned for this order.
							|All lines will be canceled. Continue?';
							|it = 'L''ordine è registrato nello stato %Status%, la formalizzazione dei lavori dei dipendenti per l''ordine non è prevista.
							|Tutte le righe verranno annullate. Continuare?';
							|pl = 'Zamówienie jest zatwierdzone w statusie %Status%, sporządzenie prac pracowników według zamówienia nie jest zaplanowano.
							|Będą anulowane wszystkie wiersze. Kontynuować?';
							|tr = 'Sipariş %Status% durumundadır, sipariş için herhangi bir personel görevi planlanmamıştır. 
							|Devam edilsin mi?'");
		QueryText = StrReplace(QueryText, "%Status%", Object.Status);
		CallbackDescription = New CallbackDescription("TheEffortToCancelTheOutstandingLineCompletion", ThisObject);
		ShowQueryBox(CallbackDescription, QueryText, QuestionDialogMode.YesNo);
		
        Return;
		
	EndIf;
	
	LaborCostsUndoUnfulfilledLineSnippet(CheckBalance);
	
EndProcedure

#EndRegion

#Region WorkingWithClipboard

&AtClient
Procedure MaterialsToInsertRows(Command)
	
	NumberOfProductsBeforeInsertion = Object.MaterialsAndWorks.Count();
	
	GetLinesFromClipboard();
	
	NumberOfInserted = Object.MaterialsAndWorks.Count() - NumberOfProductsBeforeInsertion;
	ProcessingOfTabularFormsClient.NotifyUserAboutInsertingRows(NumberOfInserted);
	
EndProcedure

&AtClient
Procedure MaterialsCopyOfTheString(Command)
	
	If ProcessingOfTabularFormsClient.SelectedLineToExecuteCommand(Items.MaterialsAndWorks) Then
		CopyLinesOnServer();
		ProcessingOfTabularFormsClient.NotifyUserAboutCopyingStrings(Items.MaterialsAndWorks.SelectedRows.Count());
	EndIf;
	
EndProcedure

#EndRegion

#Region Supply

&AtClient
Procedure CreateAnAssignmentAdjustmentReservation(Command)
	
	ObjectsOfBases = New Array();
	ObjectsOfBases.Add(Object.Ref);
	
	CommandDetails = New Structure();
	CommandDetails.Insert("ObjectsOfBases", ObjectsOfBases);
	
	If Object.Status = PredefinedValue("Enum.RMOrderStatuses.Created") Then
		MinimumStatus = PredefinedValue("Enum.RMOrderStatuses.ForCompletion");
		SupplyClient.ReportRequiredMinimumDocumentStatus(True, String(MinimumStatus));
	ElsIf Not Object.Posted Or Modified Then
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
	
	If Object.Status = PredefinedValue("Enum.RMOrderStatuses.Created") Then
		MinimumStatus = PredefinedValue("Enum.RMOrderStatuses.ForCompletion");
		SupplyClient.ReportRequiredMinimumDocumentStatus(False, String(MinimumStatus));
	ElsIf Not Object.Posted Or Modified Then
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
Procedure MaterialsAndWorksIncludeSeparateSupport(Command)
	
	ProvidingSetAction("FLAG_UNITED");
	
EndProcedure

&AtClient
Procedure MaterialsAndWorksTurnOffSeparateSoftware(Command)
	
	ProvidingSetAction("FLAG_NOTABLE");
	
EndProcedure

&AtClient
Procedure MaterialsAndWorksToEnsure(Command)
	
	ProvidingSetActionWithQuestion("ACTION_COOPERATION");
	
EndProcedure

&AtClient
Procedure ReserveMaterialsAndWorksAsTheyBecomeAvailable(Command)
	
	ProvidingSetAction("ACTION_RESERVATION_REFERENCES");
	
EndProcedure

&AtClient
Procedure DoNotProvideMaterialsAndWorks(Command)
	
	ProvidingSetActionWithQuestion("ACTION_NOTABLE");
	
EndProcedure

&AtClient
Procedure MaterialsAndWorksToShip(Command)
	
	ProvidingSetActionWithQuestion("ACTION_LOAD");
	
EndProcedure

&AtClient
Procedure ReserveMaterialsAndWorks(Command)
	
	ProvidingSetActionWithQuestion("ACTION_RESERVE");
	
EndProcedure

#EndRegion

#Region StandardSubsystems

&AtClient
Procedure Attachable_ExecuteCommand(Command)
	AttachableCommandsClient.StartCommandExecution(ThisObject, Command, Object);
EndProcedure

&AtClient
Procedure Attachable_AttachedFilesPanelCommand(Command)
	 FilesOperationsClient.AttachmentsControlCommand(ThisObject, Command);
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

#EndRegion

#Region Private

#Region Supply

&AtClient
Procedure MaterialsAndWorksAreSecurityOptionWhenChangingOnClient(Result, AdditionalParameters) Export
	
	MaterialsAndSoftwareWorksWhenModifiedOnServer();
	
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
		Items.MaterialsAndWorks.CurrentRow,
		Mode);
	
	Return FormParameters;
	
EndFunction

&AtClient
Function ParametersOfQuantityAndSeriesRequestForm(Mode)
	
	CheckParameters = SupplyClientServer.InitializeFillVerificationParameters("MaterialsAndWorks",
			NStr("vi = 'Nguyên vật liệu và nhân công';
				|ru = 'Материалы и работы';
				|en = 'Materials and works'; fa = 'Materials and works';
				|it = 'Materiali e lavori';
				|pl = 'Materiały i prace';
				|tr = 'Malzemeler ve işler'"));
	CheckParameters.Fields.Delete("Warehouse");
	
	If Not SupplyClient.CheckFilling(
				Object,
				Object.MaterialsAndWorks,
				Items.MaterialsAndWorks.CurrentRow,
				CheckParameters,
				Undefined,
				Mode) Then
		Return Undefined;
	EndIf;
	
	FormParameters = SoftwareSelectionParameters(Mode);
	FormParameters.SeriesSpecificationParameters = SeriesSpecificationParameters;
	
	Return FormParameters;
	
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

&AtServer
Procedure MaterialsAndSoftwareWorksWhenModifiedOnServer()
	
	Changes = ProvisionInDocumentsServer.SupplyOptionOnChange(
		ThisObject,
		Items.MaterialsAndWorks.CurrentRow);
		
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
		Items.MaterialsAndWorks.CurrentRow,
		FormParameters.FieldsToFillIn);
		
	AfterFillingOutCollateral(Changes, FormParameters.Mode);
	TextProcessedLines = ProvisionInDocumentsServer.TextProcessedLines(Changes.Count());
	Return TextProcessedLines;
	
EndFunction

&AtClientAtServerNoContext
Function DocumentParametersForSoftwareActions(Form)
	
	DocumentParameters = New Structure();
	DocumentParameters.Insert("Form",                              Form);
	DocumentParameters.Insert("Collection",                          Form.Object.MaterialsAndWorks);
	DocumentParameters.Insert("SecurityOptionAndFlagSeparately", Undefined);
	
	Return DocumentParameters;
	
EndFunction

&AtClient
Procedure HyperlinkStateOfProvisionClickGeneral()
	
	FormParameters = ProvisionInDocumentsClient.SecurityStatusHyperlinkClick(ThisObject);
	
	If Object.Status = PredefinedValue("Enum.RMOrderStatuses.Created") Then
		
		FormParameters.AcceptableSecurityOptions = ProvisionInDocumentsClient.AllValidSecurityOptions();
		FormParameters.AcceptableSecurityOptions.Delete(
			PredefinedValue("Enum.SupplyOptions.FromWarehouse"));
		
	EndIf;
	
	If FormParameters.ContextOfUse = "TABLE" Then
		
		FormParameters.AddressOfTheMovementTable = AddressOfMovementTableInRepository();
		
	EndIf;
	
	OpenForm("DataProcessor.OrderSupplyForecast.Form", FormParameters, ThisObject, UUID);
	
EndProcedure

&AtClient
Procedure AddCollateralActionsOnClient(StructureOfActions, StringFields_)
	
	DocumentParameters = DocumentParametersForSoftwareActions(ThisObject);
	ProvisionInDocumentsClientServer.AddCollateralActions(StructureOfActions, StringFields_, DocumentParameters);
	
EndProcedure

&AtServer
Procedure AddCollateralActionsOnServer(StructureOfActions, StringFields_)
	
	DocumentParameters = DocumentParametersForSoftwareActions(ThisObject);
	ProvisionInDocumentsClientServer.AddCollateralActions(StructureOfActions, StringFields_, DocumentParameters);
	
EndProcedure

&AtServer
Procedure FillInServiceDetailsOfDocumentForm()
	
	DocumentParameters = DocumentParametersForSoftwareActions(ThisObject);
	ProvisionInDocumentsServer.FillInServiceDetailsOfDocumentForm(DocumentParameters);
	
EndProcedure

&AtServer
Function ProvidingSetAction(ActionCode)
	
	Result = ProvisionInDocumentsServer.ProvidingSetActionResultStructure();
	
	If ActionCode = "FLAG_UNITED" Or ActionCode = "FLAG_NOTABLE" Then
		
		Changes = ProvisionInDocumentsServer.SetActionApart(
			ActionCode,
			ThisObject,
			Items.MaterialsAndWorks.SelectedRows);
			
		UpdateColumnAvailableServer();
		
	Else
		
		Changes = ProvisionInDocumentsServer.SetAction(
			ActionCode,
			ThisObject,
			Items.MaterialsAndWorks.SelectedRows);
			
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
		Object.MaterialsAndWorks,
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
	
	Documents.RMOrder.AfterFillingOutCollateral(Object, Changes, Mode, FillParameters);
	
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
	
	UpdateColumnAvailableServer();
	
EndProcedure

&AtServer
Procedure UpdateColumnAvailableServer()
	
	ProvisionInDocumentsServer.UpdateColumnAvailable(ThisObject);
	
EndProcedure

#EndRegion

#Region WorkingWithClipboard

&AtServer
Procedure CopyLinesOnServer()
	
	ProcessingOfTabularForms.CopyRowsToClipboard(Object.MaterialsAndWorks, Items.MaterialsAndWorks.SelectedRows);
	
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
	
	AddedRows = New Array;
	For Each RowOfProduct In TableOfGoods Do
		
		CurrentRow = Object.MaterialsAndWorks.Add();
		FillPropertyValues(CurrentRow, RowOfProduct);
		AddedRows.Add(CurrentRow);
		
	EndDo;
	
	AfterChangingMaterialsAndWorks(AddedRows);
	
EndProcedure

&AtServer
Procedure SetAvailabilityOfClipboardCommands()
	
	ItemArray = New Array();
	ItemArray.Add("MaterialsToInsertRows");
	ItemArray.Add("MaterialsAndWorksContextMenuInsertLines");
	
	TMCommonUseClientServer.SetPropertyOfFormElements(Items, ItemArray, "Enabled",
		ProcessingOfTabularForms.ThereAreLinesInClipboard());
	
EndProcedure

&AtClient
Procedure SetAvailabilityOfClipboardCommandsOnClient()
	
	ItemArray = New Array();
	ItemArray.Add("MaterialsToInsertRows");
	ItemArray.Add("MaterialsAndWorksContextMenuInsertLines");
	
	TMCommonUseClientServer.SetPropertyOfFormElements(Items, ItemArray, "Enabled", True);
	
EndProcedure

#EndRegion

#Region SetOfSeries

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

#EndRegion

#Region StandardSubsystems

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

&AtClient
Procedure Attachable_PropertiesExecuteCommand(ItemOrCommand, Var_URL = Undefined, StandardProcessing = Undefined)
	PropertyManagerClient.ExecuteCommand(ThisObject, ItemOrCommand, StandardProcessing);
EndProcedure

&AtClient
Procedure Attachable_PreviewFieldCheckDragging(Item, DragParameters, StandardProcessing)
	 FilesOperationsClient.PreviewFieldCheckDragging(ThisObject, Item, DragParameters, StandardProcessing);
EndProcedure

&AtClient
Procedure Attachable_PreviewFieldDrag(Item, DragParameters, StandardProcessing)
	 FilesOperationsClient.PreviewFieldDrag(ThisObject, Item, DragParameters, StandardProcessing);
EndProcedure

&AtClient
Procedure Attachable_PreviewFieldClick(Item, StandardProcessing)
	 FilesOperationsClient.PreviewFieldClick(ThisObject, Item, StandardProcessing);
EndProcedure

&AtClient
Procedure Attachable_UpdateCommands()
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
EndProcedure

&AtServer
Procedure ExecuteCommandAtServer(ExecutionParameters)
	AttachableCommands.ExecuteCommand(ThisObject, ExecutionParameters, Object);
EndProcedure

&AtClient
Procedure Attachable_ContinueCommandExecutionAtServer(ExecutionParameters, AdditionalParameters) Export
	ExecuteCommandAtServer(ExecutionParameters);
EndProcedure

#EndRegion

#Region BarcodesAndTradeEquipment

&AtClient
Procedure UsedMaterials_ImportDataFromPDTCompletion(Result, Var_Parameters) Export
	
	If Result.Result Then
		ProcessProductBarcodes(Result.TableOfGoods);
	Else
		EquipmentManagerTMClient.ReportError(Result);
	EndIf;
	
EndProcedure

&AtClient
Procedure ProcessNodeBarcodes(BarcodeData_5)
	
	If Not ProcessNodeBarcodesOnServer(BarcodeData_5) Then
		RMManagementClient.ReportThatNodesCouldNotBeFoundByBarcode();
	EndIf;
	
EndProcedure

&AtServer
Function ProcessNodeBarcodesOnServer(Val BarcodeData_5)
	
	ObjectOfOperationIsNotFilled = Not ValueIsFilled(Object.Asset);
	
	AddedRows = RMManagement.AddNodesByBarcode(
		BarcodeData_5, Object, Object.RM, "Node", Object.Asset);
	
	If AddedRows = Undefined Then
		Return False;
	EndIf;
	
	For Each NewRow In AddedRows Do
		RepairsNodeWhenItChangesOnServer(NewRow.GetID());
	EndDo;

	If ObjectOfOperationIsNotFilled And ValueIsFilled(Object.Asset) Then
		ObjectOfOperationWhenChangedOnServer();
	EndIf;
	
	Return True;
	
EndFunction

&AtClient
Procedure ProcessProductBarcodes(BarcodeData_5)
	
	ClearMessages();
	
	If Not BarcodingOfItemsClient.BarcodesAreValid(BarcodeData_5) Then
		Return;
	EndIf;
	
	StructureOfActionsWithAddedStrings = New Structure;
	
	StructureOfActionsWithAddedStrings.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
	StructureOfActionsWithAddedStrings.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));
	StructureOfActionsWithAddedStrings.Insert("CheckSoftware", New Structure("FillInSeparately", False));
	StructureOfActionsWithAddedStrings.Insert("WhenChangingTypeOfProductOrSoftwareOption",
		New Structure("ThereAreWorks, IsCanceled", True, True));
	
	AddActionsToStructureWhenChangingPackagesNumber(StructureOfActionsWithAddedStrings);
	
	StructureOfActionsWithModifiedStrings = New Structure;
	AddActionsToStructureWhenChangingPackagesNumber(StructureOfActionsWithModifiedStrings);
	
	BarcodeProcessingParameters = BarcodingOfItemsClient.BarcodeProcessingParameters();
	BarcodeProcessingParameters.Barcodes                              = BarcodeData_5;
	BarcodeProcessingParameters.StructureOfActionsWithAddedStrings = StructureOfActionsWithAddedStrings;
	BarcodeProcessingParameters.StructureOfActionsWithModifiedStrings  = StructureOfActionsWithModifiedStrings;
	BarcodeProcessingParameters.TSName                                  = "MaterialsAndWorks";
	BarcodeProcessingParameters.SeriesSpecificationParameters                 = SeriesSpecificationParameters;
	BarcodeProcessingParameters.OnlyGoodsAndWork                    = True;
	
	ProcessBarcodesServer(BarcodeProcessingParameters, CachedValues);
	
	BarcodingOfItemsClient.ProcessUnknownBarcodes(BarcodeProcessingParameters, CachedValues, ThisObject);
	
	If BarcodingOfItemsClient.YouNeedToOpenFormForSpecifyingSeriesAfterProcessingBarcodes(BarcodeProcessingParameters) Then
		CurDataId = BarcodeProcessingParameters.ArrayOfRowsWithSeries_[0];
		
		AttachIdleHandler("OpenSeriesSelectionWhenScanningProductBarCode", 0.1, True);
	EndIf;

	If BarcodeProcessingParameters.CurrentRow <> Undefined Then
		Items.MaterialsAndWorks.CurrentRow = BarcodeProcessingParameters.CurrentRow;
	EndIf;
	
EndProcedure

&AtServer
Procedure ProcessBarcodesServer(StructureOfActionParameters, CachedValues)
	
	AddCollateralActionsOnServer(
		StructureOfActionParameters.StructureOfActionsWithAddedStrings,
		"SupplyOption,WarehouseIsRequired,DateOfShipmentRequired_");
	
	BarcodingOfItemsServer.ProcessBarcodes(ThisObject, Object, StructureOfActionParameters, CachedValues);
	
	ProvisionInDocumentsClientServer.RemoveCollateralActions(StructureOfActionParameters.StructureOfActionsWithAddedStrings);
	
	AfterChangingMaterialsAndWorks();
	
EndProcedure

&AtClient
Procedure OpenSeriesSelectionWhenScanningProductBarCode()

	If CurDataId = Undefined Then
		Return;
	EndIf;
	
	CurrentData = Object.MaterialsAndWorks.FindByID(CurDataId);
	OpenSelectionOfSeries(,CurrentData);

EndProcedure

&AtClient
Procedure RepairsSearchByBarcodeCompletion(BarcodeData_2, AdditionalParameters) Export
	
	ProcessNodeBarcodes(BarcodeData_2);
	
EndProcedure

&AtClient
Procedure MaterialsSearchByBarcodeCompletion(BarcodeData_2, AdditionalParameters) Export
	
	ProcessProductBarcodes(BarcodeData_2);
	
EndProcedure

#EndRegion

#Region Other

&AtServer
Procedure OnReadCreateAtServer()
	
	If Not ValueIsFilled(ThereIsAccessRightLaborCosts) Then
		ThereIsAccessRightLaborCosts = ThereIsAccessRightLaborCosts();
	EndIf;
	
	Items.CommentPage.Picture = CommonClientServer.CommentPicture(Object.Comment);
	
	AnyRepairPresentation = NStr("vi = '<sửa chữa ngoài kế hoạch>';
								|ru = '<произвольный ремонт>';
								|en = '<any R&M>'; fa = '<any R&M>';
								|it = '<manutenzione arbitraria>';
								|pl = '<dowolny remont>';
								|tr = '<keyfi onarım>'");
	
	FillInServiceDetailsOfDocumentForm();
	
	FillInServiceDetailsForProductRange();
	FillInDisplayParameters();
	SetVisibility1();
	
	FillInDataOfInformationTableOfWorkCenters();
	
	UpdateRepairSelectionLists = True;
	UpdateRepairSelectionLists_();
	SeriesSpecificationParameters = New FixedStructure(ProductsServer.SeriesSpecificationParameters(Object, Documents.RMOrder));
	LinesOfBusinessServer.OnReadCreateAtServer(ThisObject);
	
	UpdateConsumptionForActivities(False);
	
	ConfigureDependentFormElementsOnServer();
	ProcessingOfTabularForms.InitializeRowCache(Items.MaterialsAndWorks);
	UseBusinessUnits = GetFunctionalOption("UseBusinessUnits");
	
EndProcedure

&AtServer
Procedure SetConditionalAppearance()
	
	ConditionalAppearance.Items.Clear();
	
	TMCommonUse.SetUncheckBlank(
		ConditionalAppearance, "MaterialsAndWorksWarehouse", "Object.MaterialsAndWorks.Warehouse", "Object.MaterialsAndWorks.WarehouseIsRequired");
	
	#Region RepairExecutionPeriod
	
	// Blank repair start date.
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.StartDate.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Status");
	ItemFilter.ComparisonType = DataCompositionComparisonType.InList;
	ValueList = New ValueList;
	ValueList.Add(Enums.RMOrderStatuses.ForCompletion);
	ValueList.Add(Enums.RMOrderStatuses.Running);
	ValueList.Add(Enums.RMOrderStatuses.Closed);
	ItemFilter.RightValue = ValueList;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.StartDate");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	Item.Appearance.SetParameterValue("MarkIncomplete", True);
	
	// The completed repair start date.
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.StartDate.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.StartDate");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.StartDate.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Status");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.RMOrderStatuses.Created;
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	
	// Blank repair completion date.
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.CompletedOn.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Status");
	ItemFilter.ComparisonType = DataCompositionComparisonType.InList;
	ValueList = New ValueList;
	ValueList.Add(Enums.RMOrderStatuses.ForCompletion);
	ValueList.Add(Enums.RMOrderStatuses.Running);
	ValueList.Add(Enums.RMOrderStatuses.Closed);
	ItemFilter.RightValue = ValueList;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.CompletedOn");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	Item.Appearance.SetParameterValue("MarkIncomplete", True);
	
	// The completed repair start date.
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.CompletedOn.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.CompletedOn");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.CompletedOn.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Status");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.RMOrderStatuses.Created;
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	
	#EndRegion

	#Region ActualRepairPeriod
	
	// The blank repair start date is the actual one.
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.StartDateActual.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Status");
	ItemFilter.ComparisonType = DataCompositionComparisonType.InList;
	ValueList = New ValueList;
	ValueList.Add(Enums.RMOrderStatuses.Running);
	ValueList.Add(Enums.RMOrderStatuses.Closed);
	ItemFilter.RightValue = ValueList;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.StartDateActual");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	Item.Appearance.SetParameterValue("MarkIncomplete", True);
	
	// The completed repair start date is actual.
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.StartDateActual.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.StartDateActual");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	
	// Blank repair completion date.
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ActualCompletionDate.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Status");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.RMOrderStatuses.Closed;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.ActualCompletionDate");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	Item.Appearance.SetParameterValue("MarkIncomplete", True);
	
	// The completed repair completion date.
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ActualCompletionDate.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.ActualCompletionDate");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	
	#EndRegion
	
	#Region TabularPartRepairs
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.RMNode.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("YouCanSortDataByTheAssemblies");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	Item.Appearance.SetParameterValue("Visible", False);
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.RMNode.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.RM.Node");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	Item.Appearance.SetParameterValue("Text", Object.Asset);
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.RMRMType.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.RM.RMType");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	Item.Appearance.SetParameterValue("Text", AnyRepairPresentation);
	
	#EndRegion
	
	#Region TabularPartMaterialsAndWorks
	
	ProvisionInDocumentsServer.AvailableLeftoversAddColumnLayoutAvailable(ThisObject);
	
	ProvisionInDocumentsServer.SetConditionalAppearanceApart(
		ConditionalAppearance,
		Items.MaterialsAndWorksWithAssignment,
		"Object.MaterialsAndWorks.SupplyOption",
		"Object.MaterialsAndWorks.ItemsType");
		
	//
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.MaterialsAndWorksCharacteristic.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.MaterialsAndWorks.ItemVariantsAreUsed");
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
	
	ConditionalDesignParameters = ProductsServer.NewParametersForConditionalDesignOfUnitsOfMeasurement();
	ConditionalDesignParameters.NameOfUnitField = "MaterialsAndWorksProductsUnitOfMeasure";
	ConditionalDesignParameters.PathToPackagingUnitField = "Object.MaterialsAndWorks.Package";
	ProductsServer.SetConditionalAppearanceOfUnitsOfMeasurement(ThisForm, ConditionalDesignParameters);
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.MaterialsAndWorksLineNumber.Name);
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.MaterialsAndWorksProducts.Name);
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.MaterialsAndWorksCharacteristic.Name);
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.MaterialsAndWorksNumberOfPackages.Name);
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.MaterialsAndWorksPackage.Name);
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.MaterialsAndWorksProductsUnitOfMeasure.Name);
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.MaterialsAndWorksSupplyOption.Name);
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.MaterialsAndWorksRMCode.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.MaterialsAndWorks.Canceled");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.TextColorOfCanceledRowOfDocument);
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	Item.Appearance.SetParameterValue("ReadOnly", True);
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.MaterialsAndWorksWarehouse.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.MaterialsAndWorks.ItemsType");
	ItemFilter.ComparisonType = DataCompositionComparisonType.InList;
	ValueList = New ValueList;
	ValueList.Add(Enums.ItemsTypes.OperationService);
	ValueList.Add(Enums.ItemsTypes.Work_5);
	ItemFilter.RightValue = ValueList;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.InaccessibleCellTextColor);
	Item.Appearance.SetParameterValue("ReadOnly", True);
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<Không bắt buộc>';
													|ru = '<не требуется>';
													|en = '<not required>'; fa = '<الزامی نیست>';
													|it = '<non richiesto>';
													|pl = '<nie jest wymagane>';
													|tr = '<gerekli değil>'"));
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.MaterialsAndWorksRMCode.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.MaterialsAndWorks.RMCode");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	
	Item.Appearance.SetParameterValue("Text", New DataCompositionField("Object.MaterialsAndWorks.RepairPerformance"));
	
	#EndRegion
	
	#Region TabularPartLaborCosts
	
	If Not ValueIsFilled(ThereIsAccessRightLaborCosts) Then
		ThereIsAccessRightLaborCosts = ThereIsAccessRightLaborCosts();
	EndIf;
	
	If ThereIsAccessRightLaborCosts Then
		
		Item = ConditionalAppearance.Items.Add();
		
		ItemField = Item.Fields.Items.Add();
		ItemField.Field = New DataCompositionField(Items.LaborCostsTeam.Name);
		
		ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
		ItemFilter.LeftValue = New DataCompositionField("Object.Status");
		ItemFilter.ComparisonType = DataCompositionComparisonType.InList;
		ValueList = New ValueList;
		ValueList.Add(Enums.RMOrderStatuses.Created);
		ValueList.Add(Enums.RMOrderStatuses.ForCompletion);
		ItemFilter.RightValue = ValueList;
		
		Item.Appearance.SetParameterValue("MarkIncomplete", False);
		
		//
		
		Item = ConditionalAppearance.Items.Add();
		
		ItemField = Item.Fields.Items.Add();
		ItemField.Field = New DataCompositionField(Items.LaborCostsLineNumber.Name);
		
		ItemField = Item.Fields.Items.Add();
		ItemField.Field = New DataCompositionField(Items.LaborCostsTeam.Name);
		
		ItemField = Item.Fields.Items.Add();
		ItemField.Field = New DataCompositionField(Items.LaborCostsWorkKind.Name);
		
		ItemField = Item.Fields.Items.Add();
		ItemField.Field = New DataCompositionField(Items.LaborCostsUnitOfMeasurement.Name);
		
		ItemField = Item.Fields.Items.Add();
		ItemField.Field = New DataCompositionField(Items.LaborCostsCount.Name);
		
		ItemField = Item.Fields.Items.Add();
		ItemField.Field = New DataCompositionField(Items.LaborCostsRMCode.Name);
		
		ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
		ItemFilter.LeftValue = New DataCompositionField("Object.LaborCosts.Canceled");
		ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
		ItemFilter.RightValue = True;
		
		Item.Appearance.SetParameterValue("TextColor", StyleColors.TextColorOfCanceledRowOfDocument);
		Item.Appearance.SetParameterValue("MarkIncomplete", False);
		Item.Appearance.SetParameterValue("ReadOnly", True);
		
		//
		
		Item = ConditionalAppearance.Items.Add();
		
		ItemField = Item.Fields.Items.Add();
		ItemField.Field = New DataCompositionField(Items.LaborCostsRMCode.Name);
		
		ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
		ItemFilter.LeftValue = New DataCompositionField("Object.LaborCosts.RMCode");
		ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
		Item.Appearance.SetParameterValue("Text", New DataCompositionField("Object.LaborCosts.RepairPerformance"));
		
	EndIf;
	
	#EndRegion
	
	#Region SetOfSeries
	
	ProductsServer.EstablishConditionalAppearanceOfProductSeries(
		ThisForm,
		"SeriesAlwaysWHGoods",
		"MaterialsAndWorksSeries",
		"Object.MaterialsAndWorks.BatchesIndicationStatus",
		"Object.MaterialsAndWorks.ItemsType");
	
	#EndRegion
	
	LinesOfBusinessServer.EstablishConditionalAppearanceOfDirectionOfActivity(ThisForm);
	TMCommonUse.SetConditionalAppearanceOfPriority(ThisObject);
	
EndProcedure

&AtServer
Procedure SetVisibility1()
	
	Var ArrayOfAllProps;
	Var ArrayOfOperationDetails;
	
	Documents.RMOrder.NamesOfBusinessTransactionDetails(
		Object.BusinessOperation,
		ArrayOfAllProps,
		ArrayOfOperationDetails);
	
	CashServer.SetVisibilityOfElementsByArray(
		Items,
		ArrayOfAllProps,
		ArrayOfOperationDetails);
	
	SetSoftwareVisibility();
	
	Items.LaborCosts.Visible = ThereIsAccessRightLaborCosts;
	
	If Not Object.LaborCostsAreAvailable And Object.LaborCosts.Count() = 0 Then
		Items.LaborCosts.Visible = False;
		Items.RMPayrollExpensesPostingMethod.Visible = False;
	EndIf;
	
EndProcedure

&AtServer
Procedure SetSoftwareVisibility()
	
	HasRight = ProvisionInDocumentsServer.HaveRightToViewStateHyperlink();
	Items.PagesHyperlinkSoftwareStatus.Visible = HasRight;
	
	If Not AccessRight("Insert", Metadata.Documents.InventoryAssignmentAdjustment)
		Or Not GetFunctionalOption("UseOrderSupplyWithAssignment") Then
		Items.CreateAssignmentAdjustmentRemoveFromReserve.Visible = False;
		Items.CreateAnAssignmentAdjustmentReservation.Visible = False;
	EndIf;
	ProvisionInDocumentsServer.ConfigureHyperlinkedSoftwareState(ThisObject);

EndProcedure

&AtServer
Procedure FillInDisplayParameters()
	
	SetPrivilegedMode(True);
	
	Query = New Query;
	Query.SetParameter("Asset", Object.Asset);
	Query.Text=
	"SELECT TOP 1
	|	Nodes.Ref
	|FROM
	|	Catalog.SubAssets AS Nodes
	|WHERE
	|	Nodes.Owner = &Asset";
	
	UseSubAssets = GetFunctionalOption("UseSubAssets");
	
	YouCanSortDataByTheAssemblies =
		UseSubAssets
		And ValueIsFilled(Object.Asset)
		And Not Query.Execute().IsEmpty()
	
EndProcedure

// Updates the repair selection lists in the table parts of materials/works and labor
// 		costs according to the table part of repairs.
//
&AtServer
Procedure UpdateRepairSelectionLists_()
	
	RepairPresentationTemplate = NStr("vi = '%LineNumber%. %RMType%';
										|ru = '%LineNumber%. %RMType%';
										|en = '%LineNumber%. %RMType%'; fa = '%LineNumber%. %RMType%';
										|it = '%LineNumber%.%RMType%';
										|pl = '%LineNumber%. %RMType%';
										|tr = '%LineNumber%. %RMType%'");
	If YouCanSortDataByTheAssemblies Then
		RepairPresentationTemplate = NStr("vi = '%LineNumber%. %ObjectOrNode%, %RMType%';
											|ru = '%LineNumber%. %ObjectOrNode%, %RMType%';
											|en = '%LineNumber%. %ObjectOrNode%, %RMType%'; fa = '%LineNumber%. %ObjectOrNode%, %RMType%';
											|it = '%LineNumber%.%ObjectOrNode%,%RMType%';
											|pl = '%LineNumber%. %ObjectOrNode%, %RMType%';
											|tr = '%LineNumber%. %ObjectOrNode%, %RMType%'");
	EndIf;
	
	MatchingRepairs = New Map;
	Items.MaterialsAndWorksRMCode.ChoiceList.Clear();
	Items.LaborCostsRMCode.ChoiceList.Clear();
	For Each RepairLine In Object.RM Do
		
		If RepairLine.RMCode = 0 Then
			Object.MaximumRMCode = Object.MaximumRMCode + 1;
			RepairLine.RMCode = Object.MaximumRMCode;
		EndIf;
		
		RepairStructure = New Structure("RepairPerformance");
		RepairStructure.RepairPerformance = StrReplace(RepairPresentationTemplate, "%LineNumber%", RepairLine.LineNumber);
		RepairStructure.RepairPerformance = StrReplace(RepairStructure.RepairPerformance, "%ObjectOrNode%", ?(ValueIsFilled(RepairLine.Node),RepairLine.Node, Object.Asset));
		RepairStructure.RepairPerformance = StrReplace(RepairStructure.RepairPerformance, "%RMType%", ?(ValueIsFilled(RepairLine.RMType),RepairLine.RMType, AnyRepairPresentation));
		MatchingRepairs.Insert(RepairLine.RMCode, RepairStructure);
		
		Items.MaterialsAndWorksRMCode.ChoiceList.Add(RepairLine.RMCode, RepairStructure.RepairPerformance);
		Items.LaborCostsRMCode.ChoiceList.Add(RepairLine.RMCode, RepairStructure.RepairPerformance);
	EndDo;
	
	RM = New FixedMap(MatchingRepairs);
	
	FillInPresentationsOfRepairsInTablePart("MaterialsAndWorks");
	FillInPresentationsOfRepairsInTablePart("LaborCosts");
	
	UpdateRepairSelectionLists = False;
	
EndProcedure

&AtServer
Procedure UndoSelectedLinesOfLineServer()
	
	StructureOfCancelledRow = New Structure("Canceled", True);
	
	StructureOfActions = New Structure;
	CachedValues = Undefined;
	AddCollateralActionsOnServer(StructureOfActions, "WarehouseIsRequired,DateOfShipmentRequired_");
	RowsToProcess = New Array();
	
	For Each RowID In Items.MaterialsAndWorks.SelectedRows Do
		
		TableRow = Object.MaterialsAndWorks.FindByID(RowID);
		
		If TableRow <> Undefined Then
			
			FillPropertyValues(TableRow, StructureOfCancelledRow);
			RowsToProcess.Add(TableRow);
			
		EndIf;
		
	EndDo;
	
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		RowsToProcess,
		StructureOfActions,
		Object.MaterialsAndWorks,
		CachedValues);
	
	ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);
	UpdateColumnAvailableServer();
	
EndProcedure

&AtServer
Function CancelUnfulfilledLaborLinesServer(Val CheckBalance = False)
	
	NumberOfCanceledLines = Documents.RMOrder.CancelUnfulfilledLaborLines(Object, CheckBalance);
	
	Return NumberOfCanceledLines;
	
EndFunction

&AtServer
Procedure FillOutWarehouseByContentTransferSettings()
	
	RowsArray = New Array;
	For Each RowID In Items.MaterialsAndWorks.SelectedRows Do
		RowsArray.Add(Object.MaterialsAndWorks.FindByID(RowID));
	EndDo;
	
	Documents.RMOrder.FillOutWarehouseByContentTransferSettings(Object, RowsArray);
	ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);
	UpdateColumnAvailableServer();
	
EndProcedure

&AtServer
Procedure FillInDataOfInformationTableOfWorkCenters(RowID=Undefined)
	
	Query = New Query(
		"SELECT
		|	(CAST(FillingData.LineNumber AS NUMBER)) - 1 AS RowIndex,
		|	CAST(FillingData.WorkCenter AS Catalog.WorkCenters) AS WorkCenter,
		|	CAST(FillingData.StartDate AS DATE) AS StartDate,
		|	CAST(FillingData.CompletedOn AS DATE) AS CompletedOn
		|INTO WorkCenters
		|FROM
		|	&FillingData AS FillingData
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	WorkCenters.RowIndex AS RowIndex,
		|	MAX(CASE
		|			WHEN NOT AvailabilityOfWorkCenterTypes.IsRecordOfWorkCentersCapacityChange
		|				THEN 2
		|			ELSE 1
		|		END) AS AvailabilityPicture
		|FROM
		|	WorkCenters AS WorkCenters
		|		LEFT JOIN AccumulationRegister.AvailabilityOfWorkCenterTypes AS AvailabilityOfWorkCenterTypes
		|		ON WorkCenters.WorkCenter.WorkCenterType = AvailabilityOfWorkCenterTypes.WorkCenterType
		|			AND (AvailabilityOfWorkCenterTypes.IntervalDate BETWEEN CASE
		|				WHEN WorkCenters.WorkCenter.WorkCenterType.Department.PlanningInterval = VALUE(Enum.ProductionScheduleAccuracy.DAY)
		|					THEN BEGINOFPERIOD(WorkCenters.StartDate, DAY)
		|				WHEN WorkCenters.WorkCenter.WorkCenterType.Department.PlanningInterval = VALUE(Enum.ProductionScheduleAccuracy.Shift)
		|					THEN BEGINOFPERIOD(WorkCenters.StartDate, DAY)
		|				WHEN WorkCenters.WorkCenter.WorkCenterType.Department.PlanningInterval = VALUE(Enum.ProductionScheduleAccuracy.WEEK)
		|					THEN BEGINOFPERIOD(WorkCenters.StartDate, WEEK)
		|				WHEN WorkCenters.WorkCenter.WorkCenterType.Department.PlanningInterval = VALUE(Enum.ProductionScheduleAccuracy.MONTH)
		|					THEN BEGINOFPERIOD(WorkCenters.StartDate, MONTH)
		|				ELSE BEGINOFPERIOD(WorkCenters.StartDate, HOUR)
		|			END AND CASE
		|				WHEN WorkCenters.WorkCenter.WorkCenterType.Department.PlanningInterval = VALUE(Enum.ProductionScheduleAccuracy.DAY)
		|					THEN BEGINOFPERIOD(WorkCenters.CompletedOn, DAY)
		|				WHEN WorkCenters.WorkCenter.WorkCenterType.Department.PlanningInterval = VALUE(Enum.ProductionScheduleAccuracy.Shift)
		|					THEN ENDOFPERIOD(WorkCenters.CompletedOn, DAY)
		|				WHEN WorkCenters.WorkCenter.WorkCenterType.Department.PlanningInterval = VALUE(Enum.ProductionScheduleAccuracy.WEEK)
		|					THEN BEGINOFPERIOD(WorkCenters.CompletedOn, WEEK)
		|				WHEN WorkCenters.WorkCenter.WorkCenterType.Department.PlanningInterval = VALUE(Enum.ProductionScheduleAccuracy.MONTH)
		|					THEN BEGINOFPERIOD(WorkCenters.CompletedOn, MONTH)
		|				ELSE BEGINOFPERIOD(WorkCenters.CompletedOn, HOUR)
		|			END)
		|
		|GROUP BY
		|	WorkCenters.RowIndex");
	
	RowsArray = Undefined;
	If RowID <> Undefined Then
		RowsArray = New Array;
		RowsArray.Add(Object.WorkCenters.FindByID(RowID));
	EndIf;
	
	Query.SetParameter("FillingData", Object.WorkCenters.Unload(RowsArray));
	
	SetPrivilegedMode(True);
	
	Result = Query.Execute();
	Selection = Result.Select();
	
	While Selection.Next() Do
		
		TableRow = Object.WorkCenters[Selection.RowIndex];
		TableRow.AvailabilityPicture = Selection.AvailabilityPicture;
		
	EndDo;
	
	SetPrivilegedMode(False);
	
EndProcedure

&AtServer
Function RepairSelectionFormParameters()
	
	If UpdateRepairSelectionLists Then
		UpdateRepairSelectionLists_();
	EndIf;
	
	FormParameters = New Structure;
	FormParameters.Insert("Asset", Object.Asset);
	FormParameters.Insert("Tables", New Structure);
	
	FormParameters.Tables.Insert("RM", PutToTempStorage(Object.RM.Unload(), ThisForm.UUID));
	
	Return FormParameters;
	
EndFunction

&AtServer
Procedure ProcessingSelectionOfRepairs(TableStructure)
	
	RepairsFromSelection = GetFromTempStorage(TableStructure.RM);
	
	Object.RM.Load(RepairsFromSelection);
	
	FillInCostItem(New Structure("RMCode", 0));
	
	UpdateRepairSelectionLists = True;
	
	ConfigureDependentFormElementsOnServer("RM");
	
EndProcedure

&AtServer
Procedure PrepareDataForSelectionOfMaterialsForTypesOfRepairs()

	OrderData = New Structure;
	OrderData.Insert("RM", Object.RM.Unload());
	OrderData.Insert("MaterialsAndWorks", Object.MaterialsAndWorks.Unload());

	PutToTempStorage(OrderData, AddressDataForTheSelectionOfMaterialsByTypeOfRepairs);
	
EndProcedure

&AtClient
Procedure SelectMaterialsByRMTypesCompletion(ClosingResult, AdditionalParameters) Export
	
	If ClosingResult <> Undefined
		And IsTempStorageURL(ClosingResult) Then
		FillInRepairWorkMaterials(ClosingResult);
	EndIf;
	
EndProcedure

&AtServer
Procedure FillInRepairWorkMaterials(Val AddressOfChoice)
	
	TableOfSelectedMaterials = GetFromTempStorage(AddressOfChoice);
	
	AddedRows = New Array;
	LinesToDelete = New Array;
	TheStructureOfTheSearch = New Structure("Products,Characteristic,Package,RMCode");
	
	For Each RowData In TableOfSelectedMaterials Do
		
		FillPropertyValues(TheStructureOfTheSearch, RowData);
		StringsList = Object.MaterialsAndWorks.FindRows(TheStructureOfTheSearch);
		
		If StringsList.Count() = 0 Then
			
			// These are new materials
			
			NewMaterials = Object.MaterialsAndWorks.Add();
			FillPropertyValues(NewMaterials, TheStructureOfTheSearch);
			
			NewMaterials.Count = RowData.Count;
			NewMaterials.NumberOfPackages = RowData.NumberOfPackages;
		
			AddedRows.Add(NewMaterials);
			
		Else
		
			// The materials are in the order
			
			If RowData.Count > 0 Then
				
				// The user has specified the required quantity, it is necessary to leave the materials in the order exactly for this amount
				
				NewNumberOfPackages = RowData.NumberOfPackages;
				NewCount = RowData.Count;
				
				For Each NewMaterials In StringsList Do
					
					If NewNumberOfPackages <= 0 Then
						LinesToDelete.Add(NewMaterials);
						Continue
					EndIf;
					
					If NewMaterials.NumberOfPackages > NewNumberOfPackages Then
						
						NewMaterials.NumberOfPackages = NewNumberOfPackages;
						NewMaterials.Count = NewCount;
						
						NewNumberOfPackages = 0;
						NewCount = 0;
						
					Else
						NewNumberOfPackages = NewNumberOfPackages - NewMaterials.NumberOfPackages;
						NewCount = NewCount - NewMaterials.Count;
					EndIf;
					
				EndDo;
				
				If NewNumberOfPackages > 0 Then
					
					NewMaterials = Object.MaterialsAndWorks.Add();
					FillPropertyValues(NewMaterials, TheStructureOfTheSearch);
					
					NewMaterials.Count = NewCount;
					NewMaterials.NumberOfPackages = NewNumberOfPackages;
					
					AddedRows.Add(NewMaterials);
					
				EndIf;
			
			Else
				
				// The user decided to delete the materials
				
				For Each NewMaterials In StringsList Do
					LinesToDelete.Add(NewMaterials);
				EndDo;
				
			EndIf;
		
		EndIf;
		
	EndDo;
	
	For Each NewMaterials In LinesToDelete Do
		Object.MaterialsAndWorks.Delete(NewMaterials);
	EndDo;
	
	FillInPresentationsOfRepairsInTablePart("MaterialsAndWorks");
	
	Documents.RMOrder.FillOutWarehouseByContentTransferSettings(Object);
	
	AfterChangingMaterialsAndWorks(AddedRows);
	
EndProcedure

&AtServer
Procedure FillLaborCostsForRepairs()
	
	Object.LaborCosts.Clear();
	
	Query = New Query(
		"SELECT
		|	CAST(FillingData.LineNumber AS NUMBER) AS LineNumber,
		|	CAST(FillingData.RMType AS Catalog.RMTypes) AS RMType,
		|	CAST(FillingData.RMCode AS NUMBER) AS RMCode
		|INTO FillingData
		|FROM
		|	&FillingData AS FillingData
		|
		|INDEX BY
		|	RMType
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	RMTypesLaborCosts.WorkKind,
		|	RMTypesLaborCosts.Count,
		|	FillingData.RMCode AS RMCode
		|FROM
		|	FillingData AS FillingData
		|		INNER JOIN Catalog.RMTypes.LaborCosts AS RMTypesLaborCosts
		|		ON FillingData.RMType = RMTypesLaborCosts.Ref
		|
		|ORDER BY
		|	FillingData.LineNumber");
	
	Query.SetParameter("FillingData", Object.RM.Unload( ,"LineNumber, RMType, RMCode"));
	
	Result = Query.Execute();
	If Result.IsEmpty() Then
		Return;
	EndIf;
	
	Object.LaborCosts.Load(Result.Unload());
	
	FillInPresentationsOfRepairsInTablePart("LaborCosts");
	
EndProcedure

&AtServer
Procedure FillInPresentationsOfRepairsInTablePart(TabularSectionName)
	
	StructureOfNotSpecifiedRepair = New Structure("RMCode, RepairPerformance", 0, "");
	
	For Each String In Object[TabularSectionName] Do
		If ValueIsFilled(String.RMCode) Then
			
			RepairStructure = RepairStructure(String.RMCode, ThisObject);
			If RepairStructure = Undefined Then
				RepairStructure = StructureOfNotSpecifiedRepair;
			EndIf;
			FillPropertyValues(String, RepairStructure);
			
		EndIf;
	EndDo;
	
EndProcedure

&AtServer
Procedure RepairsTypeOfRepairWhenModifiedOnServer()

	UpdateRepairSelectionLists = True;

	FillInCostItem(Items.RM.CurrentRow);

	ConfigureDependentFormElementsOnServer("RM");
	
EndProcedure

&AtServer
Procedure RepairsNodeWhenItChangesOnServer(Val RowFilter = Undefined)
	
	FillInCostItem(RowFilter);
	
EndProcedure

// Fills in the cost item in the table part "Repairs" by the settings for reflecting expenses.
//
// Parameters:
// 		RowFilter - Number, Structure - Numeric ID of the line to be filled in or the structure by which the lines to be filled in should be selected.
//
&AtServer
Procedure FillInCostItem(Val RowFilter = Undefined)
	
	If RowFilter <> Undefined
		And TypeOf(RowFilter) = Type("Number") Then
		
		RowID = RowFilter;
		
		RowFilter = New Array;
		RowFilter.Add(Object.RM.FindByID(RowID));
	EndIf;
	
	QueryText = 
	"SELECT
	|	CAST(FillingData.LineNumber AS NUMBER) AS LineNumber,
	|	CAST(&Asset AS Catalog.Assets) AS Asset,
	|	CAST(FillingData.Node AS Catalog.SubAssets) AS Node,
	|	CAST(FillingData.RMType AS Catalog.RMTypes) AS RMType
	|INTO FillingData
	|FROM
	|	&FillingData AS FillingData
	|
	|INDEX BY
	|	RMType
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	FillingData.LineNumber - 1 AS RowIndex,
	|	ExpenseItems.Ref AS ExpenseItem
	|FROM
	|	FillingData AS FillingData
	|		LEFT JOIN Catalog.GeneralRMTypes AS GeneralRMTypes
	|		ON FillingData.RMType.GeneralRMType = GeneralRMTypes.Ref
	|			AND (GeneralRMTypes.DefaultExpenseItem)
	|		LEFT JOIN Catalog.SubAssets AS Nodes
	|		ON FillingData.Node = Nodes.Ref
	|			AND (Nodes.ExpenseItem <> VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef))
	|		LEFT JOIN ChartOfCharacteristicTypes.ExpenseItems AS ExpenseItems
	|		ON (ExpenseItems.Ref = ISNULL(GeneralRMTypes.ExpenseItem, ISNULL(Nodes.ExpenseItem, FillingData.Asset.ExpenseItem)))
	|WHERE
	|	ExpenseItems.RMOrderExpenses
	|		OR ExpenseItems.ExpensesOnAssets";
	
	Query = New Query(QueryText);
	Query.SetParameter("FillingData", Object.RM.Unload(RowFilter));
	Query.SetParameter("Asset", Object.Asset);
	
	Selection = Query.Execute().Select();
	
	While Selection.Next() Do
		FillPropertyValues(Object.RM[Selection.RowIndex], Selection);
	EndDo;
	
EndProcedure

&AtServer
Procedure WorkCentersFillUpOnServer()
	
	Object.WorkCenters.Clear();
	
	If Object.RM.Count() = 0 Then
		Return;
	EndIf;
	
	ThereAreRepairsOfObjectOfOperation = Object.RM.FindRows(New Structure("Node", Catalogs.SubAssets.EmptyRef())).Count()<>0;
	
	Query = New Query(
		"SELECT TOP 1
		|	SubAssets.Owner AS Asset
		|INTO ObjectByNodes
		|FROM
		|	Catalog.SubAssets AS SubAssets
		|WHERE
		|	SubAssets.Ref IN(&NodesArray)
		|	AND SubAssets.InfluenceOnWorkCenterAvailability
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	WorkCenters.WorkCenter,
		|	&StartDate AS StartDate,
		|	&CompletedOn AS CompletedOn
		|FROM
		|	Catalog.Assets.WorkCenters AS WorkCenters
		|WHERE
		|	(WorkCenters.Ref = &Asset
		|				AND &ThereAreRepairsOfObjectOfOperation
		|			OR WorkCenters.Ref IN
		|				(SELECT
		|					ObjectByNodes.Asset
		|				FROM
		|					ObjectByNodes AS ObjectByNodes))");
	Query.SetParameter("StartDate", Object.StartDate);
	Query.SetParameter("CompletedOn", Object.CompletedOn);
	
	Query.SetParameter("Asset", Object.Asset);
	Query.SetParameter("NodesArray", ?(ThereAreRepairsOfObjectOfOperation, New Array, Object.RM.Unload(, "Node").UnloadColumn("Node")));
	Query.SetParameter("ThereAreRepairsOfObjectOfOperation", ThereAreRepairsOfObjectOfOperation);
	
	Object.WorkCenters.Load(Query.Execute().Unload());
	
	FillInDataOfInformationTableOfWorkCenters();
	
EndProcedure

// Adds actions to the structure when changing the number of packages
//
&AtClientAtServerNoContext
Procedure AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions)
	
	StructureOfActions.Insert("RecalculateNumberOfUnits");
	
EndProcedure

&AtServerNoContext
Function ThereIsAccessRightLaborCosts()
	
	Return (
		AccessRight("Read", Metadata.Catalogs.Teams)
		And AccessRight("Read", Metadata.Catalogs.EmployeeWorkKinds));
	
EndFunction

&AtServer
Function CancelUnprocessedServer()
	
	OrderLineAdjustmentStructure = OrdersServer.OrderLineAdjustmentStructure();
	OrderLineAdjustmentStructure.CancelUnprocessedLines = True;
	OrderLineAdjustmentStructure.TabularSectionName = "MaterialsAndWorks";
	
	Return AdjustOrderLines(OrderLineAdjustmentStructure);
	
EndFunction

&AtServer
Function AdjustOrderLines(StructureOfAdditionalParameters)
	
	OrderObject = FormAttributeToValue("Object");
	
	StructureOfAdditionalParameters.CheckBalance = OrderObject.Status <> Enums.RMOrderStatuses.Created;
	
	ResultStructure1 = OrderObject.AdjustOrderLines(StructureOfAdditionalParameters);
	
	If StructureOfAdditionalParameters.CloseOrders Then
		OrderObject.Status = Enums.RMOrderStatuses.Closed;
	EndIf;
	
	ValueToFormAttribute(OrderObject, "Object");
	
	FillInServiceDetailsForProductRange();
	FillInPresentationsOfRepairsInTablePart("MaterialsAndWorks");
	FillInServiceDetailsOfDocumentForm();
	UpdateColumnAvailableServer();
	
	Modified = True;
	
	Return ResultStructure1;
	
EndFunction

&AtServer
Procedure ConfigureDependentFormElementsOnServer(ChangedBankingDetails = "")

	StructureOfChangedProps = New Structure(ChangedBankingDetails);
	
	UpdateAll = StructureOfChangedProps.Count() = 0;
	
	If StructureOfChangedProps.Property("RM")
		Or UpdateAll Then
		
		FillInSelectionOfGeneralRAndMType(UpdateAll);
		
	EndIf;
	
EndProcedure

&AtServer
Procedure FillInServiceDetailsForProductRange()
	
	StructureOfActions = New Structure();
	StructureOfActions.Insert("FillInFeatureAttribute", New Structure("Products", "ItemVariantsAreUsed"));
	StructureOfActions.Insert("FillInProductTypeAttribute_",            New Structure("Products", "ItemsType"));
	StructureOfActions.Insert("FillInArticleAttribute",                    New Structure("Products", "SKU"));
	
	ProductsServer.FillInServiceDetailsForProductInCollection(Object.MaterialsAndWorks, StructureOfActions);
	
EndProcedure

&AtServer
Procedure DirectionOfActivityWhenChangingOnServer()
	
	LinesOfBusinessServer.WhenChangingDirectionOfActivity(ThisObject);
	ProvisionInDocumentsServer.WhenChangingDocumentDetails(ThisObject);
	UpdateConsumptionForActivities();
	
EndProcedure

&AtServer
Procedure OrganizationWhenChangedOnServer()
	
	FillInSubordinatePropertiesForStatistics("Organization");
	UpdateConsumptionForActivities();
	
EndProcedure

&AtServer
Procedure FillInSubordinatePropertiesForStatistics(ParentPropsName)
	ObjectsFillingByStatistics.FillInSubordinateDetailsOfObject(Object, ParentPropsName);
EndProcedure

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
	
	AddedRows = New Array;
	
	For Each RowOfProduct In TableOfGoods Do
		
		CurrentRow = Object.MaterialsAndWorks.Add();
		FillPropertyValues(CurrentRow, RowOfProduct,
			"Products,Characteristic,ItemVariantsAreUsed,Package,NumberOfPackages,Warehouse,
			|SupplyOption,WithAssignment,Series");
		AddedRows.Add(CurrentRow);
		
	EndDo;
	
	AfterChangingMaterialsAndWorks(AddedRows);
	
EndProcedure

&AtServer
Procedure AfterChangingMaterialsAndWorks(AddedRows = Undefined)

	If AddedRows <> Undefined Then
		
		CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
		
		StructureOfActions = New Structure;
		AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions);
		AddCollateralActionsOnServer(StructureOfActions, "WarehouseIsRequired,DateOfShipmentRequired_");
		
		RowsToProcess = New Array;
		ProcessedLinesFillingInSupplyOption = New Array;
		For Each CurrentRow In AddedRows Do
			
			If Not ValueIsFilled(CurrentRow.SupplyOption) Then
				ProcessedLinesFillingInSupplyOption.Add(CurrentRow);
			Else
				RowsToProcess.Add(CurrentRow);
			EndIf;
			
		EndDo;
		
		BatchProcessingOfTablePartServer.ProcessTSStrings(
			RowsToProcess,
			StructureOfActions,
			Object.MaterialsAndWorks,
			CachedValues);
			
		AddCollateralActionsOnServer(StructureOfActions, "SupplyOption");
		
		BatchProcessingOfTablePartServer.ProcessTSStrings(
			ProcessedLinesFillingInSupplyOption,
			StructureOfActions,
			Object.MaterialsAndWorks,
			CachedValues);
			
	EndIf;

	FillInServiceDetailsForProductRange();
	ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);
	
	FillInServiceDetailsOfDocumentForm();
	UpdateColumnAvailableServer();
	
EndProcedure

&AtServer
Procedure UpdateConsumptionForActivities(Fill = True)
	
	FillParameters = Documents.RMOrder.ParametersForFillingInVATActivityType(Object);
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

&AtClient
Procedure LaborCostsToFillInForRepairsCompletion(QuestionResult, AdditionalParameters) Export
	
	If QuestionResult = DialogReturnCode.OK Then
		FillLaborCostsForRepairs();
	EndIf;
	
EndProcedure

&AtClient
Procedure LaborToCancelUnfulfilledRowsAfterQuestion(QuestionResult, AdditionalParameters) Export
    
    UserAnswer = QuestionResult;
    CheckBalance = False;
    
    If UserAnswer = DialogReturnCode.No Then
        Return;
    EndIf;
    
    
    LaborCostsUndoUnfulfilledLineSnippet(CheckBalance);

EndProcedure

&AtClient
Procedure TheEffortToCancelTheOutstandingLineCompletion(QuestionResult, AdditionalParameters) Export
    
    UserAnswer = QuestionResult;
    CheckBalance = False;
    
    If UserAnswer = DialogReturnCode.No Then
        Return;
    EndIf;
    
    
    LaborCostsUndoUnfulfilledLineSnippet(CheckBalance);

EndProcedure

&AtClient
Procedure LaborCostsUndoUnfulfilledLineSnippet(Val CheckBalance)
    
    Var RowsCountCanceled;
    
    RowsCountCanceled = CancelUnfulfilledLaborLinesServer(CheckBalance);
    
    If RowsCountCanceled = 0 Then
        
        ShowUserNotification(
        NStr("vi = 'Chưa hủy bỏ dòng';
			|ru = 'Строки не отменены';
			|en = 'Lines were not canceled'; fa = 'Lines were not canceled';
			|it = 'Righe non annullate';
			|pl = 'Wiersze nie są anulowane';
			|tr = 'Satırlar iptal edilmedi'"),
        ,
        NStr("vi = 'Chứng từ được lập trên tất cả các dòng. Các dòng không thể bị hủy';
			|ru = 'По всем строкам оформлены документы. Строки не могут быть отменены';
			|en = 'The documents are registered for all rows. Rows cannot be canceled'; fa = 'The documents are registered for all rows. Rows cannot be canceled';
			|it = 'Per tutte le righe sono stati formalizzati i documenti. Le righe non possono essere annullate';
			|pl = 'Według wszystkich wierszy są sporządzone dokumenty. Wiersze nie mogą być anulowane';
			|tr = 'Tüm satırlar belgelenmiştir. Satırlar iptal edilemez'"),
        PictureLib.Information32);
        
    Else
        
        If CheckBalance Then
            
            ShowUserNotification(
            NStr("vi = 'Hủy bỏ dòng';
				|ru = 'Строки отменены';
				|en = 'Lines were canceled'; fa = 'Lines were canceled';
				|it = 'Righe annullate';
				|pl = 'Wiersze są anulowane';
				|tr = 'Satırlar iptal edildi'"),
            ,
            NStr("vi = 'Tất cả các dòng không định dạng bị hủy';
				|ru = 'Все неоформленные строки отменены';
				|en = 'All pending lines are canceled'; fa = 'All pending lines are canceled';
				|it = 'Tutte le righe non formalizzate sono annullate';
				|pl = 'Wszystkie niesporządzone wiersze są anulowane';
				|tr = 'Biçimlendirilmemiş tüm satırlar iptal edilir'"),
            PictureLib.Information32);
            
        Else
            
            ShowUserNotification(
            NStr("vi = 'Hủy bỏ dòng';
				|ru = 'Строки отменены';
				|en = 'Lines were canceled'; fa = 'Lines were canceled';
				|it = 'Righe annullate';
				|pl = 'Wiersze są anulowane';
				|tr = 'Satırlar iptal edildi'"),
            ,
            NStr("vi = 'Tất cả dòng đều bị hủy bỏ';
				|ru = 'Все строки отменены.';
				|en = 'All items are canceled.'; fa = 'All items are canceled.';
				|it = 'Tutte le righe sono annullate.';
				|pl = 'Wszystkie wiersze anulowano.';
				|tr = 'Tüm satırlar iptal edildi.'"),
            PictureLib.Information32);
            
        EndIf;
        
    EndIf;

EndProcedure

&AtClient
Procedure WorkCentersFillInCompletion(QuestionResult, AdditionalParameters) Export
	
	If QuestionResult = DialogReturnCode.OK Then
		WorkCentersFillUpOnServer();
	EndIf;
	
EndProcedure

&AtClient
Procedure MaterialsAndWorksSplitLineCompletion(NewRow, AdditionalParameters) Export 
	
	If NewRow = Undefined Then
		Return;
	EndIf;
	
	CurrentRow = Items.MaterialsAndWorks.CurrentData;
			
	NewRow.RowCode = 0;
	
	StructureOfActions = New Structure;
	AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions);
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	AddCollateralActionsOnClient(StructureOfActions,"UpdateProductCache_");
	BatchProcessingOfTablePartClient.ProcessTSString(NewRow, StructureOfActions, CachedValues);
	
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
	
	OpenForm("DataProcessor.OrderClosureWizard.Form.ClosureForm", ClosureStructure,
					ThisForm,,,, Undefined, FormWindowOpeningMode.LockOwnerWindow);
	
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

// 
// Returns:
// 	Structure - LongDesc:
// * WorkCenter - CatalogRef.WorkCenters -
// * StartDate - Date -
// * CompletedOn - Date -
&AtClient
Function NewLineBeforeEditing()
	Return New Structure("WorkCenter, StartDate, CompletedOn");
EndFunction

&AtServer
Procedure BusinessOperationWhenChangingOnServer()
	SetVisibility1();
EndProcedure

&AtServer
Procedure ObjectOfOperationWhenChangedOnServer()
	
	Department = Common.ObjectAttributeValue(Object.Asset, "RMBusinessUnit");
	If ValueIsFilled(Department) Then
		Object.Department = Department;
	EndIf;
	
	FillInDisplayParameters();
	UpdateRepairSelectionLists_();
	
EndProcedure

&AtClient
Procedure MaterialsFillInTheWarehouseCompletion(Result, AdditionalParameters) Export
    
    If Not ValueIsFilled(Result) Then
    	Return;
	EndIf;
    
    SelectedRows = AdditionalParameters.SelectedRows;
 	FilledWithRows = FillWarehouseInSelectedLinesOnServer(SelectedRows, Result);
    WarehousesClient.ShowNotificationAboutFillingOfWarehouseInTablePart(Result, FilledWithRows, SelectedRows.Count());

EndProcedure

&AtServer
Function FillWarehouseInSelectedLinesOnServer(Val ArrayOfSelectedRows, Val Warehouse)
	
	FilledWithRows = WarehousesServer.FillInWarehousesInSelectedLines(Object.MaterialsAndWorks, ArrayOfSelectedRows, Warehouse);
	
	If FilledWithRows > 0 Then
		
		ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);
	
	EndIf;
	
	Return FilledWithRows;
	
EndFunction

&AtClientAtServerNoContext
Procedure HideShowLines(Form)
	
	Items = Form.Items;
	Form.HideCanceledLines = Not Form.HideCanceledLines;
	
	If Form.HideCanceledLines Then
		Items.MaterialsAndWorks.RowFilter = New FixedStructure("Canceled", False);
	Else
		Items.MaterialsAndWorks.RowFilter = Undefined;
	EndIf;
	
	Items.MaterialsHideCanceledLines_3.Check = Form.HideCanceledLines;
	
EndProcedure

&AtClient
Procedure MaterialsFillInTheTypeOfRepairCompletion(SelectedElement, AdditionalParameters) Export
	
	If SelectedElement = Undefined Then
		Return;
	EndIf;
	
	For Each CurrentRow In Items.MaterialsAndWorks.SelectedRows Do
		
		CurrentData = Object.MaterialsAndWorks.FindByID(CurrentRow);
		CurrentData.RMCode = SelectedElement.Value;
		MaterialsWhenChangingRepairCode(CurrentData);
		
	EndDo;	
	
EndProcedure

&AtClient
Procedure MaterialsWhenChangingRepairCode(CurrentData)

	If ValueIsFilled(CurrentData.RMCode) Then
		RepairStructure = RepairStructure(CurrentData.RMCode, ThisObject);
		If RepairStructure = Undefined Then
			RepairStructure = New Structure("RMCode, RepairPerformance", 0, "");
		EndIf;
		FillPropertyValues(CurrentData, RepairStructure);
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Function RepairStructure(RMCode, Form)
	
	RepairsCompliance = Form.RM; // FixedMap
	
	RepairStructure = RepairsCompliance.Get(RMCode); // Structure
	
	Return RepairStructure;
	
EndFunction

&AtServer
Procedure FillInSelectionOfGeneralRAndMType(UpdateAll)
	
	If ReadOnly Then
		Return;
	EndIf;
	
	ListOfTypesOfRepairs = New Array;
	For Each RowData In Object.RM Do
		If ValueIsFilled(RowData.RMType)
			And ListOfTypesOfRepairs.Find(RowData.RMType) = Undefined Then
			ListOfTypesOfRepairs.Add(RowData.RMType);
		EndIf; 
	EndDo;
	
	If ListOfTypesOfRepairs.Count() <> 0 Then
		
		QueryText = 
		"SELECT ALLOWED DISTINCT
		|	RMTypes.GeneralRMType AS GeneralRMType,
		|	RMTypes.GeneralRMType.Description AS GeneralRAndMTypeName
		|FROM
		|	Catalog.RMTypes AS RMTypes
		|WHERE
		|	RMTypes.Ref IN (&ListOfTypesOfRepairs)
		|
		|ORDER BY
		|	GeneralRAndMTypeName";
		
		Query = New Query(QueryText);
		Query.SetParameter("ListOfTypesOfRepairs", ListOfTypesOfRepairs);
		
		AvailableCommonTypesOfRepairs = Query.Execute().Unload().UnloadColumn("GeneralRMType");
		Items.GeneralRMType.ChoiceList.LoadValues(AvailableCommonTypesOfRepairs);
		Items.GeneralRMType.ListChoiceMode = True;
		
		If Not UpdateAll
			And AvailableCommonTypesOfRepairs.Find(Object.GeneralRMType) = Undefined Then
			If AvailableCommonTypesOfRepairs.Count() = 1 Then
				Object.GeneralRMType = AvailableCommonTypesOfRepairs[0];
			Else
				Object.GeneralRMType = Undefined;
			EndIf;
		EndIf; 
		
	Else
		Items.GeneralRMType.ChoiceList.Clear();
		Items.GeneralRMType.ListChoiceMode = False;
	EndIf;
	
EndProcedure

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
