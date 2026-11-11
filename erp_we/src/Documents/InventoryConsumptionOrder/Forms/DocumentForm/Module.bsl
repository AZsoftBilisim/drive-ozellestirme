
#Region Variables

&AtClient
Var FormModified; // it is used to work out the form modification change event

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
	
	EmbeddingParameters = Documents.InventoryConsumptionOrder.AvailableRemainingEmbeddingOptions();
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
	If GetFunctionalOption("UseProduction") 
		And Object.BusinessOperation = Enums.BusinessTransactions.TransferToProduction Then
		Items.BusinessOperation.ChoiceList.Add(Enums.BusinessTransactions.TransferToProduction);
	EndIf;
	If Object.BusinessOperation = Enums.BusinessTransactions.TransferToProduction Then
		// Such documents are used more and are opened only for viewing
		ReadOnly = True;
	EndIf;
	// Selection of articles and analytics.
	ItemsAndDimensionsSelectionParameters = Documents.InventoryConsumptionOrder.ItemsAndDimensionsSelectionParameters(Object.BusinessOperation);
	IncomeAndExpensesServer.OnCreateAtServer(ThisObject, ItemsAndDimensionsSelectionParameters);
	
	If Not ValueIsFilled(Object.Ref) Then
		OnReadCreateAtServer();
		ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);
	EndIf;
	
	If Items.BusinessOperation.ChoiceList.Count() = 1 Then
		Items.BusinessOperation.Visible = False;
	EndIf;
	
	Items.CloseOrder.Enabled = AccessRight("Update",Metadata.Documents.InventoryConsumptionOrder);
	
	SetAvailabilityOfClipboardCommands();
	SetSelectionParameters();
	
	// Setting the list of available statuses
	Enums.InternalOrderStatuses.FillChoiceList(Items.Status.ChoiceList, True);
	
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

&AtClient
Procedure OnOpen(Cancel)
	
	AttachIdleHandler("Attachable_WhenChangingModifiabilityOfForm", 1);
	
	// StandardSubsystems.Properties
	PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
	// End StandardSubsystems.Properties
	
	EquipmentManagerClient.StartConnectingDevicesWhenYouOpenForm(Undefined, ThisForm, "BarcodeScanner");
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// The end of the standard subsystem.Pluggable commands
	// Standard subsystems.Worksfiles
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
		"Document.InventoryConsumptionOrder.Form.DocumentForm.Event.ChoiceProcessing");
	
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
		ShowUserNotification(NStr("vi = 'Hủy các dòng chưa xử lý';
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
	
	// Selection of articles and analytics.
	ItemsAndDimensionsSelectionParameters = Documents.InventoryConsumptionOrder.ItemsAndDimensionsSelectionParameters(Object.BusinessOperation);
	IncomeAndExpensesServer.OnReadAtServer(ThisObject, ItemsAndDimensionsSelectionParameters);
	
	EmbeddingParameters = Documents.InventoryConsumptionOrder.AvailableRemainingEmbeddingOptions();
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
			"Products,Characteristic,Count,,DateOfShipment",
			New CallbackDescription("BeforeRecordingOfferToPickUpMultiTurnContainer", ThisObject, AdditionalParameters));
		
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
	ProvisionInDocumentsServer.AfterWriteAtServer(ThisObject);
	SetSoftwareVisibility();
	SetVisibilityOfGoodsShipCommand();
	FillInServiceDetailsOfDocumentForm();
	
	// Selection of articles and analytics.
	IncomeAndExpensesServer.AfterWriteAtServer(ThisObject);
	
	DocumentsStates.AfterWriteAtServer(ThisObject, WriteParameters);
	
	If DocumentsStates.TaskCheckForReflectingStateOfOrdersIsNotRunning(ThisObject) Then
		RefreshStatusServer();
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
	
	DocumentsStatesClient.AfterWrite(ThisObject, "Attachable_CheckTasksToReflectStateOfOrders");
	
EndProcedure

&AtServer
Procedure BeforeLoadDataFromSettingsAtServer(Settings)
	
	If Not Object.Ref.IsEmpty() Then
		Settings.Delete("Object.NotShipInInstallments");
	EndIf;
	
EndProcedure

&AtServer
Procedure OnLoadDataFromSettingsAtServer(Settings)
	
	SetVisibilityOfShippingDateFormElements();
	
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
	
	UpdateConsumptionForActivities_();
	
EndProcedure

&AtClient
Procedure StatusOnChange(Item)
	
	If Object.Approved
		And Object.Status = PredefinedValue("Enum.InternalOrderStatuses.AwaitingApproval") Then
		
		Object.Approved = False;
		
	EndIf;
	
	StatusOnChangeServer();
	
EndProcedure

&AtClient
Procedure OrganizationOnChange(Item)
	
	OrganizationOnChangeServer();
	
EndProcedure

&AtClient
Procedure BusinessOperationOnChange(Item)
	
	If Not Object.Goods.Count() = 0 Then
		CallbackDescription = New CallbackDescription("BusinessOperationOnChangeCompletion", ThisObject);
		QueryText = NStr("vi = 'Danh sách ""Hàng hóa"" sẽ bị xóa. Tiếp tục?';
						|ru = 'Список ""Товары"" будет очищен. Продолжить?';
						|en = 'The Item list will be cleared. Continue?'; fa = 'The Item list will be cleared. Continue?';
						|it = 'L''elenco ""Merci"" verrà cancellato. Continuare?';
						|pl = 'Lista ""Towaty"" zostanie wyczyszczona. Kontynuować?';
						|tr = '""Ürünler"" listesi temizlenecek. Devam edilsin mi?'");
		ShowQueryBox(CallbackDescription, QueryText, QuestionDialogMode.YesNo);
	Else
		BusinessOperationOnChangeServer(False);
	EndIf;
	
EndProcedure

&AtClient
Procedure BusinessOperationOnChangeCompletion(QuestionResult, AdditionalParameters) Export
	
	If Not QuestionResult = DialogReturnCode.Yes Then
		
		// If the user refused to change the household.operations, you need to return the household.the operation before the change.
		ThisIsWriteOffOnDemand =
			Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.GoodsConsumptionOnDemand");
		
		Object.BusinessOperation =
			?(ThisIsWriteOffOnDemand,
			PredefinedValue("Enum.BusinessTransactions.TransferToOperation"),
			PredefinedValue("Enum.BusinessTransactions.GoodsConsumptionOnDemand"));
		
		Return;
	Else
		BusinessOperationOnChangeServer(True);
	EndIf;
	
EndProcedure

&AtClient
Procedure WarehouseOnChange(Item)
	
	WarehouseOnChangeServer();
	
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
Procedure LineOfBusinessOnChange(Item)
	
	DirectionOfActivityWhenChangingOnServer();
	
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
Procedure ConsumptionForActivityClearing(Item, StandardProcessing)
	StandardProcessing = False;
EndProcedure

&AtClient
Procedure StateClick(Item, StandardProcessing)
	SalesClient.StatusInFormOfDocumentClick(StandardProcessing, ThisObject);
EndProcedure

&AtClient
Procedure ExpenseLineOfBusinessIsSpecifiedInListOnChange(Item)
	
	Object.ExpenseLineOfBusinessIsSpecifiedInList = (ExpenseLineOfBusinessIsSpecifiedInList = 1);
	
	ConfigureDependentFormElementsOnClientOnServer(ThisObject, Item);
	
EndProcedure

#Region Supply

&AtClient
Procedure SecurityStatusHyperlinkClick(Item)
	
	HyperlinkStateOfProvisionClickGeneral();
	
EndProcedure

&AtClient
Procedure HyperlinkSecurityStatusIsBeingShippedClick(Item)
	
	HyperlinkStateOfProvisionClickGeneral();
	
EndProcedure

&AtClient
Procedure HyperlinkSecurityStatusIssueClick(Item)
	
	HyperlinkStateOfProvisionClickGeneral();
	
EndProcedure

#EndRegion

#EndRegion

#Region FormTableItemsEventHandlersGoods

&AtClient
Procedure GoodsSelection(Item, RowSelected, Field, StandardProcessing)
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.StartTimeMeasurement(
		True, "Document.InventoryConsumptionOrder.Form.DocumentForm.Items.Goods.Selection");
	
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
	StructureOfActions.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));
	StructureOfActions.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
	StructureOfActions.Insert("CheckFillPackageByOwner", CurrentRow.Package);
	StructureOfActions.Insert("RecalculateNumberOfUnits");
	
	// Selection of articles and analytics.
	IncomeAndExpensesClientServer.InsertActionFillInItemCostAnalysisOfProducts(
		StructureOfActions,
		ThisObject,
		Object.BusinessOperation,
		Object.Organization,
		Object.Department);
		
	StructureOfActions.Insert("CheckSeriesCalculateStatus", New Structure("Warehouse, SeriesSpecificationParameters", Object.Warehouse, SeriesSpecificationParameters));
	AddCollateralActionsOnClient(StructureOfActions, "SupplyOption,AvailableInOtherLines,WarehouseIsRequired,DateOfShipmentRequired_");
	
	StructureOfActions.Insert("ProductsOnChangeOverridable", New Structure("FormName, TabularSectionName",
		ThisForm.FormName, "Goods"));

	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	ProvisionInDocumentsClientServer.FillInServiceDetails(Object.Goods, DateOfShipmentRequired_, WarehouseIsRequired);
	
	If ProvisionInDocumentsClient.YouNeedToUpdateAvailableColumn(StructureOfActions) Then
		UpdateColumnAvailableServer();
	EndIf;
	
EndProcedure

&AtClient
Procedure GoodsCharacteristicOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;
	
	StructureOfActions = New Structure;
	AddCollateralActionsOnClient(StructureOfActions, "SupplyOption,AvailableInOtherLines,WarehouseIsRequired,DateOfShipmentRequired_");
	StructureOfActions.Insert("CharacteristicOnChangeOverridable", New Structure("FormName, TabularSectionName",
		ThisForm.FormName, "Goods"));
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	ProvisionInDocumentsClientServer.FillInServiceDetails(Object.Goods, DateOfShipmentRequired_, WarehouseIsRequired);
	
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
Procedure GoodsOperationCategoryOnChange(Item)

	CurrentRow = Items.Goods.CurrentData;
	WhenChangingCategoryOfOperation(CurrentRow);
	
EndProcedure

&AtClient
Procedure GoodsExpenseItemOnChange(Item)
	
	// Selection of articles and analytics.
	IncomeAndExpensesClientServer.AssetRefOnChange(ThisObject, Item);
	
EndProcedure

&AtClient
Procedure GoodsOnStartEdit(Item, NewRow, Copy)

	ProcessingOfTabularFormsClient.CacheCurLine(Items.Goods, ThisObject);
	If NewRow Then
		
		Items.Goods.CurrentData.RowCode = 0;
		
	EndIf;
	
	If NewRow And Not Copy Then
		WhenAddingLineOfProductsOnClient_(Items.Goods.CurrentData);
	EndIf;
	
	If Copy Then
		StructureOfActions = New Structure;
		AddCollateralActionsOnClient(StructureOfActions, "SupplyOption,Available,WarehouseIsRequired,DateOfShipmentRequired_");
		StructureOfActions.Insert("CheckSeriesCalculateStatus", New Structure("Warehouse, SeriesSpecificationParameters", Object.Warehouse, SeriesSpecificationParameters));
		BatchProcessingOfTablePartClient.ProcessTSString(Items.Goods.CurrentData, StructureOfActions, CachedValues);
		ProvisionInDocumentsClientServer.FillInServiceDetails(Object.Goods, DateOfShipmentRequired_, WarehouseIsRequired);
	EndIf;

EndProcedure

&AtClient
Procedure GoodsOnEditEnd(Item, NewRow, CancelEdit)
	
	CurrentData = Item.CurrentData;
	
	If CurrentData <> Undefined And Object.NotShipInInstallments Then
		CurrentData.DateOfShipment = Object.DateOfShipment;
	EndIf;
	
	ReusablePackageClient.UpdateFillingStateOfMultiTurnContainer(Object.ReusablePackageFillingStatus);
	
EndProcedure

&AtClient
Procedure GoodsAfterDeleteRow(Item)
	
	ReusablePackageClient.UpdateFillingStateOfMultiTurnContainer(Object.ReusablePackageFillingStatus);
	ProvisionInDocumentsClientServer.FillInServiceDetails(Object.Goods, DateOfShipmentRequired_, WarehouseIsRequired);
	UpdateColumnAvailableServer();
	
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
	AddCollateralActionsOnClient(StructureOfActions, "AvailableInOtherLines,WarehouseIsRequired,DateOfShipmentRequired_");
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	ProvisionInDocumentsClientServer.FillInServiceDetails(Object.Goods, DateOfShipmentRequired_, WarehouseIsRequired);
	
	If ProvisionInDocumentsClient.YouNeedToUpdateAvailableColumn(StructureOfActions) Then
		UpdateColumnAvailableServer();
	EndIf;

EndProcedure

&AtClient
Procedure GoodsDimensionOfExpensesStartChoice(Item, ChoiceData, StandardProcessing)
	
	// Selection of articles and analytics.
	IncomeAndExpensesClient.StartSelectingExpenseAnalytics(ThisObject, Item, StandardProcessing);
	
EndProcedure

&AtClient
Procedure GoodsDimensionOfExpensesAutoComplete(Item, Text, ChoiceData, Var_Parameters, Waiting, StandardProcessing)
	
	// Selection of articles and analytics.
	IncomeAndExpensesClient.AutoSelectionOfExpenseAnalytics(
		ThisObject,
		Item,
		Text,
		ChoiceData,
		Var_Parameters,
		StandardProcessing);
	
EndProcedure

&AtClient
Procedure GoodsDimensionOfExpensesTextEditEnd(Item, Text, ChoiceData, Var_Parameters, StandardProcessing)
	
	// Selection of articles and analytics.
	IncomeAndExpensesClient.EndOfCostAnalyticsTextEntry(
		ThisObject,
		Item,
		Text,
		ChoiceData,
		Var_Parameters,
		StandardProcessing);
	
EndProcedure

&AtClient
Procedure GoodsExpenseItemStartChoice(Item, ChoiceData, StandardProcessing)
	
	// Selection of articles and analytics.
	IncomeAndExpensesClient.StartArticleSelection(ThisObject, Item, StandardProcessing);
	
EndProcedure

&AtClient
Procedure GoodsSupplyOptionChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	ProvisionInDocumentsClient.SupplyOptionChoiceProcessing(
		ThisObject,
		Items.Goods.CurrentData,
		ValueSelected);
	
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
Procedure GoodsSupplyOptionStartChoice(Item, ChoiceData, StandardProcessing)
	
	NewArray = New Array();
	
	// The Ship collateral option is not available
	If Object.Status = PredefinedValue("Enum.InternalOrderStatuses.AwaitingApproval") Then 
		
		ActionsArray = ProvisionInDocumentsClientServer.AvailableActionsForSelectingCollateralInDefaultRow();
		IndexOf = ActionsArray.Find(PredefinedValue("Enum.SupplyOptions.Ship"));
		If IndexOf <> Undefined Then
			ActionsArray.Delete(IndexOf);
		EndIf;
		
		AllowedActions = New FixedArray(ActionsArray);
		NewParameter1 = New ChoiceParameter("AllowedActions", AllowedActions);
		
		NewArray.Add(NewParameter1);
		
	EndIf;
	
	Item.ChoiceParameters = New FixedArray(NewArray);
	
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
// End StandardSubsystems.FilesOperations

&AtClient
Procedure ImportDataFromPDT(Command)
	
	ClearMessages();
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.StartTimeMeasurement(True,
		"Document.InventoryConsumptionOrder.DocumentForm.Command.ImportDataFromPDT");
	
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
Procedure FillInExpenseItem(Command)
	
	// Selection of articles and analytics.
	IncomeAndExpensesClient.FillInArticleAndAnalyticsInSelectedLines(
		ThisObject,
		Items.GoodsExpenseItem,
		Items.Goods.SelectedRows);
	
EndProcedure

&AtClient
Procedure SelectGoods(Command)
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.StartTimeMeasurement(True,
		"Document.InventoryConsumptionOrder.DocumentForm.Command.SelectGoods");
	
	Cancel = False;
	
	If Not ValueIsFilled(Object.Warehouse) Then
		ClearMessages();
		CommonClientServer.MessageToUser(NStr("vi = 'Chưa điền trường ""Kho bãi""';
												|ru = 'Поле ""Склад"" не заполнено';
												|en = '""Warehouse"" is required'; fa = '""Warehouse"" is required';
												|it = 'Il campo ""Magazzino"" non è compilato';
												|pl = 'Nie wypełniono pola ""Magazyn""';
												|tr = '""Ambar"" alanı doldurulmamış'"), Object.Ref, "Object.Warehouse",, Cancel);
	EndIf;
	
	If Cancel Then
		Return;
	EndIf;
	
	FormParameters = New Structure;
	FormParameters.Insert("Warehouse",                                     Object.Warehouse);
	FormParameters.Insert("SelectionModeWithoutAmountParameters",         True);
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
	
	If Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.GoodsConsumptionOnDemand") Then
		FormParameters.Insert("FilterByProductType", New FixedArray(ProductsClientServer.SelectionByProductReusablePackagingWork(False)));
	Else
		FormParameters.Insert("FilterByProductType", New FixedArray(ProductsClientServer.SelectionByProductMultiTurnContainer(False)));
	EndIf;
	
	If Object.Status = PredefinedValue("Enum.InternalOrderStatuses.AwaitingApproval") Then
		AllowedNonIsolatedActions = ProvisionInDocumentsClientServer.AllActions();
		AllowedNonIsolatedActions.Delete(AllowedNonIsolatedActions.FindByValue(
			PredefinedValue("Enum.SupplyOptions.Ship")));
		AcceptableSeparateActions = AllowedNonIsolatedActions.Copy();
		FormParameters.Insert("AllowedNonIsolatedActions", AllowedNonIsolatedActions);
		FormParameters.Insert("AcceptableSeparateActions", AcceptableSeparateActions);
	EndIf;
	
	OpenForm("DataProcessor.SelectGoodsToSalesDocument.Form", FormParameters, ThisObject, UUID);
	
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
	
	TMCommonUseClient.Post(ThisForm, True);
	
EndProcedure

&AtClient
Procedure SetDeletionMarkForADocument(Command)
	
	TMCommonUseClient.SetDeletionMarkForADocument(ThisForm);
	
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
		"Products,Characteristic,Count,,DateOfShipment");
	
EndProcedure

&AtClient
Procedure FillInInventory(Command)
	
	FillInShoppingCenterOnServer();

EndProcedure

&AtClient
Procedure FillInCategoryOfOperation(Command)
	
	AdditionalParameters = New Structure();
	AdditionalParameters.Insert("SelectedRows", Items.Goods.SelectedRows);
	CallbackDescription = New CallbackDescription("FillInCategoryOfOperationCompletion", ThisObject, AdditionalParameters);

	InventoryInOperationClient.FillInCategoryOfOperation(
		Object.Goods,
		Items.Goods.SelectedRows,
		Undefined,
		CallbackDescription);
	
EndProcedure

&AtClient
Procedure FillInIndividual(Command)
	InventoryInOperationClient.FillInIndividual(Object.Goods, Items.Goods.SelectedRows);
	Return // the UT has an empty handler
	
EndProcedure

&AtClient
Procedure FillInDirectionOfActivity(Command)
	
	StringsList = New Array;
	For Each RowID In Items.Goods.SelectedRows Do
		StringsList.Add(RowID);
	EndDo;
	
	If StringsList.Count() = 0 Then
		ShowMessageBox(, NStr("vi = 'Cần chọn các dòng cần điền lĩnh vực hoạt động';
								|ru = 'Необходимо выбрать строки, в которых требуется заполнить направление деятельности';
								|en = 'Select lines in which line of business must be filled in'; fa = 'Select lines in which line of business must be filled in';
								|it = 'Select lines in which line of business must be filled in';
								|pl = 'Select lines in which line of business must be filled in';
								|tr = 'İş kolunun doldurulması gereken satırların seçilmesi gerekir'"));
		Return;
	EndIf;
	
	ChoiceFormParameters = TMCommonUseClientServer.ChoiceParameters(Items.GoodsLineOfBusiness, ThisObject);

	CallbackDescription = New CallbackDescription("FillInDirectionOfActivityCompletion", ThisObject, StringsList);
	
	OpenForm("Catalog.LinesOfBusiness.ChoiceForm", 
					ChoiceFormParameters,,,,,
					CallbackDescription, 
					FormWindowOpeningMode.LockOwnerWindow);
	
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
// End StandardSubsystems.AttachableCommands

&AtClient
Procedure PostAndClose(Command)
	
	TMCommonUseClient.PostAndClose(ThisForm, True);
	
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
				|tr = 'Bir işlemin gerçekleştirilmesi için belgenin düzenlenmesi gerekir. Belge düzenlensin mi?'"), QuestionDialogMode.YesNo);
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
		ConditionalAppearance, "DateOfShipment", "Object.DateOfShipment", "DateOfShipmentRequired_");
	
	TMCommonUse.SetUncheckBlank(
		ConditionalAppearance, "Warehouse", "Object.Warehouse", "WarehouseIsRequired");
	
	TMCommonUse.SetUncheckBlank(
		ConditionalAppearance, "GoodsDateOfShipment", "Object.Goods.DateOfShipment", "Object.Goods.DateOfShipmentRequired_");

	ProvisionInDocumentsServer.SetConditionalAppearanceApart(
		ConditionalAppearance,
		Items.GoodsWithAssignment,
		"Object.Goods.SupplyOption",
		"Object.Goods.ItemsType");
		
	ProvisionInDocumentsServer.AvailableLeftoversAddColumnLayoutAvailable(ThisObject);

	//

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
	ItemField.Field = New DataCompositionField(Items.State.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("State");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.SalesOrderStates.Closed;

	Item.Appearance.SetParameterValue("TextColor", StyleColors.ClosedDocument);
	
	//

	ProductsServer.EstablishConditionalAppearanceOfProductSeries(ThisForm, "SeriesAlwaysWHGoods");
	
	LinesOfBusinessServer.EstablishConditionalAppearanceOfDirectionOfActivity(ThisForm);
	
	#Region ProductsCostAnalytics_Visibility
	
	ConditionalAppearanceItem = ConditionalAppearance.Items.Add();
	
	ItemField = ConditionalAppearanceItem.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsDimensionOfExpenses.Name);
	
	ItemFilter = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.AccountAsGroupFA");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	ConditionalAppearanceItem.Appearance.SetParameterValue("TextColor", StyleColors.InaccessibleCellTextColor);
	ConditionalAppearanceItem.Appearance.SetParameterValue("MarkIncomplete", False);
	ConditionalAppearanceItem.Appearance.SetParameterValue("ReadOnly", True);
	ConditionalAppearanceItem.Appearance.SetParameterValue("Text", NStr("vi = '<chỉ định khi chuyển giao>';
																		|ru = '<указывается при передаче>';
																		|en = '<specified upon transfer>'; fa = '<specified upon transfer>';
																		|it = '<viene indicato al trasferimento>';
																		|pl = '<podaje się podczas przekazania>';
																		|tr = '<iletim sırasında belirtilir>'"));
	
	#EndRegion
	
EndProcedure

#Region OnChangeAttributes

&AtServer
Procedure ConfigureDependentFormElementsOnServer(Val ChangedDetailsOrElement = "")

	ConfigureDependentFormElementsOnClientOnServer(ThisObject, ChangedDetailsOrElement);

	If TypeOf(ChangedDetailsOrElement) = Type("String") Then
		ChangedBankingDetails = ChangedDetailsOrElement;
	Else
		ChangedBankingDetails = ChangedDetailsOrElement.Name;
	EndIf;
	
	StructureOfChangedProps = New Structure(ChangedBankingDetails);
	
	UpdateAll = StructureOfChangedProps.Count() = 0;
	
	If UpdateAll
		Or StructureOfChangedProps.Property("BusinessOperation") Then
		
		SetVisibility1(True);
		UpdateConsumptionForActivities_();
		
		ParametersArray = New Array;
		
		ArrayOfProductTypes = New Array();
		ArrayOfProductTypes.Add(PredefinedValue("Enum.ItemsTypes.OwnGoods"));
		ArrayOfProductTypes.Add(PredefinedValue("Enum.ItemsTypes.ReusablePackage"));
		If Object.BusinessOperation = Enums.BusinessTransactions.GoodsConsumptionOnDemand Then
			ArrayOfProductTypes.Add(PredefinedValue("Enum.ItemsTypes.Work_5"));
		EndIf;
		
		FixedArrayOfProductTypes = New FixedArray(ArrayOfProductTypes);
		ParametersArray.Add(New ChoiceParameter("Filter.ItemsType", FixedArrayOfProductTypes));
		
		Items.GoodsProducts.ChoiceParameters = New FixedArray(ParametersArray);
		
	EndIf; 
	
EndProcedure

&AtClientAtServerNoContext
Procedure ConfigureDependentFormElementsOnClientOnServer(Form, ChangedDetailsOrElement = "")
	
	If TypeOf(ChangedDetailsOrElement) = Type("String") Then
		ChangedBankingDetails = ChangedDetailsOrElement;
	Else
		ChangedBankingDetails = ChangedDetailsOrElement.Name;
	EndIf;
	
	Object = Form.Object;
	Items = Form.Items;
	
	StructureOfChangedProps = New Structure(ChangedBankingDetails);
	
	UpdateAll = StructureOfChangedProps.Count() = 0;
	
	If StructureOfChangedProps.Property("ExpenseLineOfBusinessIsSpecifiedInList")
		Or UpdateAll Then
		
		Items.GoodsLineOfBusiness.Visible = Object.ExpenseLineOfBusinessIsSpecifiedInList;
		Items.GoodsFillInDirectionOfActivity.Visible = Object.ExpenseLineOfBusinessIsSpecifiedInList;
		
	EndIf;
	
EndProcedure

&AtServer
Procedure StatusOnChangeServer()
	
	SeriesSpecificationParameters = New FixedStructure(ProductsServer.SeriesSpecificationParameters(Object, Documents.InventoryConsumptionOrder));
	ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);
	
	If Object.Status = Enums.InternalOrderStatuses.AwaitingApproval Then
		EnsuringToSetActionWhenChangingStatusForApproval("rollback_Actions_Ship");
	EndIf;
	
	SetVisibilityOfGoodsShipCommand();
	
EndProcedure

&AtServer
Procedure OrganizationOnChangeServer()
	
	UpdateConsumptionForActivities_();
	
EndProcedure

&AtServer
Procedure BusinessOperationOnChangeServer(ClearGoods)
	
	ChangedBankingDetails = "BusinessOperation";
	
	If ClearGoods Then
		Object.Goods.Clear();
	EndIf;
	
	// Selection of articles and analytics.
	ItemsAndDimensionsSelectionParameters = Documents.InventoryConsumptionOrder.ItemsAndDimensionsSelectionParameters(Object.BusinessOperation);
	IncomeAndExpensesServer.WhenChangingArticleSelectionParameters(ThisObject, ItemsAndDimensionsSelectionParameters);
	
	ConfigureNavigationBar();

	ConfigureDependentFormElementsOnServer(ChangedBankingDetails);
	
EndProcedure

&AtServer
Procedure WarehouseOnChangeServer()
	
	PrepareFillSetSeriesVisibility();
	UpdateConsumptionForActivities_();
	
	ProvisionInDocumentsServer.WhenChangingDocumentDetails(ThisObject);
	
EndProcedure

&AtServer
Procedure DirectionOfActivityWhenChangingOnServer()
	
	LinesOfBusinessServer.WhenChangingDirectionOfActivity(ThisObject);
	ProvisionInDocumentsServer.WhenChangingDocumentDetails(ThisObject);
	UpdateConsumptionForActivities_();
	
EndProcedure

&AtServer
Procedure UpdateConsumptionForActivities_(Validate = True)
	
	FillParameters = Documents.InventoryConsumptionOrder.ParametersForFillingInVATActivityType(Object);
	
	If Validate Then
		
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

#EndRegion

#Region SelectionAndProcessingOfQuantityVerification

&AtServer
Procedure ProcessingSelectionOfSelectionOnServer(ValueSelected)
	
	TableOfGoods = GetFromTempStorage(ValueSelected.GoodsAddressInStorage);
	
	CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	StructureOfActions = New Structure;
	AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions);
	AddCollateralActionsOnServer(StructureOfActions, "WarehouseIsRequired,DateOfShipmentRequired_");
	
	// Selection of articles and analytics.
	IncomeAndExpensesClientServer.InsertActionFillInItemCostAnalysisOfProducts(
		StructureOfActions,
		ThisObject,
		Object.BusinessOperation,
		Object.Organization,
		Object.Department);
	
	BegOfDay = BegOfDay(CurrentSessionDate());
	RowsToProcess = New Array;
	ShippingDates = New Map;
	
	For Each RowOfProduct In TableOfGoods Do
		
		CurrentRow = Object.Goods.Add();
		FillPropertyValues(CurrentRow, RowOfProduct,
			"Products,Characteristic,ItemVariantsAreUsed,Package,DateOfShipment,NumberOfPackages,
			|SupplyOption,WithAssignment,Series");
		WhenAddingLineOfProductsOnServer_(CurrentRow);
		ShippingDates.Insert(CurrentRow, RowOfProduct.DateOfShipment);
		RowsToProcess.Add(CurrentRow);
		
	EndDo;
	
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		RowsToProcess,
		StructureOfActions,
		Object.Goods,
		CachedValues);
		
	For Each CurrentRow In RowsToProcess Do
		
		CurrentRow.DateOfShipment = ProvisionInDocumentsServer.ShipmentDateProcessingSelectionSelection(
			ShippingDates.Get(CurrentRow),
			CurrentRow.SupplyOption,
			BegOfDay);
			
	EndDo;
	
	ProvisionInDocumentsServer.UpdateShipmentDateWithSingleDate(
		Object.NotShipInInstallments,
		Object.DateOfShipment,
		Object.Goods,
		"DateOfShipment");
	
	FillInServiceDetailsForProductRange();
	ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);
	UpdateColumnAvailableServer();
	
	ReusablePackageServer.UpdateFillingStateOfMultiTurnContainer(Object.ReusablePackageFillingStatus);
	
EndProcedure

&AtClientAtServerNoContext
Procedure AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions)
	
	StructureOfActions.Insert("RecalculateNumberOfUnits");
	
EndProcedure

&AtServer
Procedure FillInServiceDetailsForProductRange()
	
	StructureOfActions = New Structure();
	StructureOfActions.Insert("FillInFeatureAttribute", New Structure("Products", "ItemVariantsAreUsed"));
	StructureOfActions.Insert("FillInProductTypeAttribute_",            New Structure("Products", "ItemsType"));
	StructureOfActions.Insert("FillInArticleAttribute",                    New Structure("Products", "SKU"));
	
	ProductsServer.FillInServiceDetailsForProductInCollection(Object.Goods, StructureOfActions);
	
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
	
	// Selection of articles and analytics.
	IncomeAndExpensesClientServer.InsertActionFillInItemCostAnalysisOfProducts(
		StructureOfActionsWithAddedStrings,
		ThisObject,
		Object.BusinessOperation,
		Object.Organization,
		Object.Department);
	
	StructureOfActionsWithAddedStrings.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
	StructureOfActionsWithAddedStrings.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));
	AddActionsToStructureWhenChangingPackagesNumber(StructureOfActionsWithAddedStrings);
	
	StructureOfActionsWithModifiedStrings = New Structure;
	AddActionsToStructureWhenChangingPackagesNumber(StructureOfActionsWithModifiedStrings);
	
	ThisIsWriteOffOnDemand =
		Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.GoodsConsumptionOnDemand");
	
	StructureOfActions = BarcodingOfItemsClient.BarcodeProcessingParameters();
	StructureOfActions.Barcodes                              = BarcodeData_5;
	StructureOfActions.StructureOfActionsWithAddedStrings = StructureOfActionsWithAddedStrings;
	StructureOfActions.StructureOfActionsWithModifiedStrings  = StructureOfActionsWithModifiedStrings;
	StructureOfActions.SeriesSpecificationParameters                 = SeriesSpecificationParameters;
	StructureOfActions.OnlyGoodsAndWork                    = ThisIsWriteOffOnDemand;
	StructureOfActions.GoodsOnly                           = Not ThisIsWriteOffOnDemand;
	
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

&AtServer
Procedure PrepareFillSetSeriesVisibility()
	
	SeriesSpecificationParameters = New FixedStructure(ProductsServer.SeriesSpecificationParameters(Object, Documents.InventoryConsumptionOrder));
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

&AtClient
Procedure Attachable_CloseForm()
	
	Close();
	
EndProcedure

&AtServer
Procedure SetVisibility1(ClearArticles = False)
	
	Var ArrayOfAllProps;
	Var ArrayOfOperationDetails;
	Var ArrayOfAllElements;
	Var ArrayOfOperationElements;
	
	Documents.InventoryConsumptionOrder.FillInNamesOfBusinessTransactionDetails(
		Object.BusinessOperation,
		ArrayOfAllProps,
		ArrayOfOperationDetails);
	
	CashServer.SetVisibilityOfElementsByArray(
		Items,
		ArrayOfAllProps,
		ArrayOfOperationDetails);
	
	Documents.InventoryConsumptionOrder.FillInNamesOfElementsForBusinessOperation(
		Object.BusinessOperation,
		ArrayOfAllElements,
		ArrayOfOperationElements);
	TMCommonUseClientServer.SetPropertyOfFormElements(
		Items,
		ArrayOfAllElements,
		"Visible",
		False);
	TMCommonUseClientServer.SetPropertyOfFormElements(
		Items,
		ArrayOfOperationElements,
		"Visible",
		True);
	
EndProcedure

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
	
EndProcedure

&AtClient
Procedure NotifyAboutDocument(WriteParameters)

	NotificationParameters = New Structure;
	NotificationParameters.Insert("WriteMode",      WriteParameters.WriteMode);
	NotificationParameters.Insert("ThereIsOrder_", True);
	NotificationParameters.Insert("NotificationDocumentKeys", OperationsWithDocumentJournalsClient.GetKeyParametersForDocument(
		Object.Ref, Object.Date, Object.BusinessOperation));
		
	Notify("Write_InventoryConsumptionOrder", NotificationParameters, Object.Ref);

EndProcedure

&AtServer
Procedure FillMultiTurnContainersFromStorageServer(AddressOfContainerInStorage)
	
	ActionStructureModifiedStrings = New Structure;
	
	ActionStructureModifiedStrings.Insert("RecalculateNumberOfPackages");
	StructureOfActionsAddedLines = New Structure;
	
	StructureOfActionsAddedLines.Insert("RecalculateNumberOfPackages");
	AddCollateralActionsOnServer(StructureOfActionsAddedLines,
		"SupplyOption,WarehouseIsRequired,DateOfShipmentRequired_");
	
	// Selection of articles and analytics.
	IncomeAndExpensesClientServer.InsertActionFillInItemCostAnalysisOfProducts(
		StructureOfActionsAddedLines,
		ThisObject,
		Object.BusinessOperation,
		Object.Organization,
		Object.Department);
	
	ReusablePackageServer.FillMultiTurnContainersFromStorage(
		Object,
		AddressOfContainerInStorage,
		"Goods",
		"Products,Characteristic,,DateOfShipment",
		ActionStructureModifiedStrings,
		StructureOfActionsAddedLines);
	
	FillInServiceDetailsForProductRange();
	ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);
	UpdateColumnAvailableServer();
	
EndProcedure

&AtServer
Procedure OnReadCreateAtServer()
	
	ExpenseLineOfBusinessIsSpecifiedInList = ?(Object.ExpenseLineOfBusinessIsSpecifiedInList, 1, 0);

	SeriesSpecificationParameters = New FixedStructure(ProductsServer.SeriesSpecificationParameters(Object, Documents.InventoryConsumptionOrder));
	SetFormFunctionalOptionParameters(New Structure("Warehouse",Object.Warehouse));
	FillInServiceDetailsForProductRange();
	
	Items.BaseGroup_.Visible = ValueIsFilled(Object.DocumentBasis);
	
	SetVisibility1(False);
	SetVisibilityOfShippingDateFormElements();
	SetSoftwareVisibility();
	SetVisibilityOfGoodsShipCommand();
	
	RefreshStatusServer();
		
	LinesOfBusinessServer.OnReadCreateAtServer(ThisObject);
	
	UpdateConsumptionForActivities_(False);
	
	FillInServiceDetailsOfDocumentForm();
	ProcessingOfTabularForms.InitializeRowCache(Items.Goods);
	
	ConfigureNavigationBar();
		
	ConfigureDependentFormElementsOnClientOnServer(ThisObject);
			
EndProcedure

&AtServer
Procedure WhenAddingLineOfProductsOnServer_(String)
	
	// Selection of articles and analytics.
	IncomeAndExpensesClientServer.WhenAddingRowToTable(ThisObject, String, "Object.Goods");
	
EndProcedure

&AtClient
Procedure WhenAddingLineOfProductsOnClient_(String)
	
	// Selection of articles and analytics.
	IncomeAndExpensesClientServer.WhenAddingRowToTable(ThisObject, String, "Object.Goods");
	
EndProcedure

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
Procedure WhenChangingRows(ModifiedRows)

	StructureOfActions = New Structure;
	AddCollateralActionsOnServer(StructureOfActions, "SupplyOption,WarehouseIsRequired,DateOfShipmentRequired_");
	
	// Selection of articles and analytics.
	IncomeAndExpensesClientServer.InsertActionFillInItemCostAnalysisOfProducts(
		StructureOfActions,
		ThisObject,
		Object.BusinessOperation,
		Object.Organization,
		Object.Department);
	
	CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	
	For Each NewRow In ModifiedRows Do
		WhenAddingLineOfProductsOnServer_(NewRow);
	EndDo;
	
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		ModifiedRows,
		StructureOfActions,
		Object.Goods,
		CachedValues);
	
	FillInServiceDetailsForProductRange();
	FillInServiceDetailsOfDocumentForm();
	UpdateColumnAvailableServer();
	
EndProcedure

&AtServer
Procedure SetSelectionParameters()
	
	#Region GoodsExpenseItem
	NewSelectionParameterRelationships = New Array;

	NewLink = New ChoiceParameterLink("AccountAsGroupFA", "Items.Goods.CurrentData.AccountAsGroupFA", LinkedValueChangeMode.DontChange);
	NewSelectionParameterRelationships.Add(NewLink);

	Items.GoodsExpenseItem.ChoiceParameterLinks = New FixedArray(NewSelectionParameterRelationships);
	#EndRegion
	
	#Region GoodsDimensionOfExpenses
	NewSelectionParameterRelationships = New Array;

	NewLink = New ChoiceParameterLink("Filter.Owner", "Items.Goods.CurrentData.ExpenseItem", LinkedValueChangeMode.Clear);
	NewSelectionParameterRelationships.Add(NewLink);

	NewLink = New ChoiceParameterLink("AccountAsGroupFA", "Items.Goods.CurrentData.AccountAsGroupFA", LinkedValueChangeMode.DontChange);
	NewSelectionParameterRelationships.Add(NewLink);

	Items.GoodsDimensionOfExpenses.ChoiceParameterLinks = New FixedArray(NewSelectionParameterRelationships);
	#EndRegion
	
EndProcedure
 
&AtServer
Procedure ConfigureNavigationBar()

	SettingsStructure = New Structure;
	SettingsStructure.Insert("UseMaterialsInOperation",
		Object.BusinessOperation = Enums.BusinessTransactions.TransferToOperation
		Or Object.BusinessOperation = Enums.BusinessTransactions.PutOutOfOperation);
	
	TMCommonUse.ConfigureFormByParameters(ThisObject, SettingsStructure);
	
EndProcedure

&AtServer
Procedure FillInShoppingCenterOnServer()

	Object.Goods.Clear();
	
	If GetFunctionalOption("TradeManagement") Then
		
		QueryText = 
		"SELECT
		|	LotsOfInventoryInOperation.Ref
		|INTO Lots
		|FROM
		|	Catalog.LotsOfInventoryInOperation AS LotsOfInventoryInOperation
		|WHERE
		|	NOT LotsOfInventoryInOperation.DeletionMark
		|	AND ENDOFPERIOD(LotsOfInventoryInOperation.CompletionDate_, MONTH) = &Period
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	GoodsTable.Products,
		|	GoodsTable.Characteristic,
		|	GoodsTable.Individual,
		|	GoodsTable.OperationCategory AS OperationCategory,
		|	GoodsTable.Count AS Count,
		|	GoodsTable.Count AS NumberOfPackages
		|FROM
		|	Document.InventoryConsumption.Goods AS GoodsTable
		|WHERE
		|	GoodsTable.Ref.Organization = &Organization
		|	AND GoodsTable.Ref.Department = &Department
		|	AND GoodsTable.Ref.Posted
		|	AND GoodsTable.Lot IN
		|		(SELECT
		|			Lots.Ref
		|		FROM
		|			Lots AS Lots)";
	
	Else
		QueryText = 
		"SELECT
		|	LotsOfInventoryInOperation.Ref
		|INTO Lots
		|FROM
		|	Catalog.LotsOfInventoryInOperation AS LotsOfInventoryInOperation
		|WHERE
		|	NOT LotsOfInventoryInOperation.DeletionMark
		|	AND ENDOFPERIOD(LotsOfInventoryInOperation.CompletionDate_, MONTH) = &Period
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	InventoryInOperation.Products,
		|	InventoryInOperation.Characteristic,
		|	InventoryInOperation.Individual,
		|	InventoryInOperation.Lot.OperationCategory AS OperationCategory,
		|	InventoryInOperation.CountBalance AS Count,
		|	InventoryInOperation.CountBalance AS NumberOfPackages
		|FROM
		|	AccumulationRegister.InventoryInOperation.Balance(
		|			&Period,
		|			Organization = &Organization
		|				AND Department = &Department
		|				AND Lot IN
		|					(SELECT
		|						Lots.Ref
		|					FROM
		|						Lots AS Lots)) AS InventoryInOperation
		|WHERE
		|	InventoryInOperation.CountBalance > 0";
	EndIf;
		
	Query = New Query(QueryText);
	Query.SetParameter("Period", EndOfMonth(?(ValueIsFilled(Object.Date), Object.Date, CurrentSessionDate())));
	Query.SetParameter("Organization", Object.Organization);
	Query.SetParameter("Department", Object.Department);
	
	SetPrivilegedMode(True);
	Selection = Query.Execute().Select();
	SetPrivilegedMode(False);
	
	ModifiedRows = New Array;
	
	While Selection.Next() Do
		NewRow = Object.Goods.Add();
		FillPropertyValues(NewRow, Selection);
		ModifiedRows.Add(NewRow);
	EndDo;
	
	WhenChangingRows(ModifiedRows);
	
EndProcedure
 
 &AtClient
Procedure FillInCategoryOfOperationCompletion(Result, AdditionalParameters) Export
	
	SelectedRows = AdditionalParameters.SelectedRows;
	
	For Each RowID In SelectedRows Do
		
		CurrentRow = Object.Goods.FindByID(RowID);
		WhenChangingCategoryOfOperation(CurrentRow);
		
	EndDo;
	
EndProcedure

&AtClient
Procedure WhenChangingCategoryOfOperation(CurrentRow)
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInCategoryAttributes");
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
	IncomeAndExpensesClientServer.AssetRefOnChange(ThisObject, Items.GoodsExpenseItem);
	
	If Not CurrentRow.AccountingForIndividuals Then
		CurrentRow.Individual = PredefinedValue("Catalog.Persons.EmptyRef");
	EndIf;
		
EndProcedure

&AtServer
Procedure RefreshStatusServer()
	
	Documents.InventoryConsumptionOrder.CalculateStatus(Object.Ref, ThisObject);
	Items.State.CellHyperlink = AccessRight("View", Metadata.Reports.DocumentFulfillmentStatus);
	
EndProcedure

&AtClient
Procedure RefreshStatusClient(CheckTasksToReflectStateOfOrders = False, OrderState = Undefined)
	
	OrderState = New Structure();
	OrderState.Insert("State", Undefined);
	
	If CheckTasksToReflectStateOfOrders Then
		DocumentsStatesClient.CompleteStructureOfOrderState(OrderState);
	EndIf;
	
	FillPropertyValues(OrderState, ThisObject);
	
	CalculateStateOfOrder(
		Object.Ref,
		OrderState,
		Items.State.Hyperlink,
		CheckTasksToReflectStateOfOrders);
	
	FillPropertyValues(ThisObject, OrderState);
	
EndProcedure

&AtServerNoContext
Procedure CalculateStateOfOrder(
			Ref,
			OrderState,
			Hyperlink,
			CheckTasksToReflectStateOfOrders = False)
	
	Documents.InventoryConsumptionOrder.CalculateStatus(
		Ref,
		OrderState,
		CheckTasksToReflectStateOfOrders);
	
	Hyperlink = AccessRight("View", Metadata.Reports.DocumentFulfillmentStatus);
	
EndProcedure

&AtServer
Procedure SetVisibilityOfGoodsShipCommand()
	
	StatusUnderApproval = Object.Status = Enums.InternalOrderStatuses.AwaitingApproval;
	Items.GoodsShip.Visible = Not StatusUnderApproval;
	Items.GoodsContextMenuShip.Visible = Not StatusUnderApproval;
	
EndProcedure

&AtClient
Procedure Attachable_CheckTasksToReflectStateOfOrders()
	
	If DocumentsStatesClient.TaskIsBeingCheckedToReflectStateOfOrders(ThisObject) Then
		
		OrderState = Undefined;
		RefreshStatusClient(True, OrderState);
		
		DocumentsStatesClient.ProcessTaskVerificationResultToReflectStateOfOrders(
			ThisObject,
			OrderState.ThereAreTasksToReflectStateOfOrders,
			"Attachable_CheckTasksToReflectStateOfOrders");
		
	ElsIf DocumentsStatesClient.StartOfTaskVerificationToReflectStateOfOrders(ThisObject) Then
		
		DocumentsStatesClient.SetTaskCheckToReflectStateOfOrdersFlagInProgress(ThisObject);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure FillInDirectionOfActivityCompletion(Result, StringsList) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	For Each RowID In StringsList Do
		RowData = Object.Goods.FindByID(RowID);
		RowData.LineOfBusiness = Result;
	EndDo;
	
EndProcedure

#Region WorkingWithClipboard

&AtServer
Procedure CopyLinesOnServer()
	
	ProcessingOfTabularForms.CopyRowsToClipboard(Object.Goods, Items.Goods.SelectedRows);
	
EndProcedure

&AtServer
Procedure GetLinesFromClipboard()
	
	FilterParameters = New Map;
	If Object.BusinessOperation = Enums.BusinessTransactions.GoodsConsumptionOnDemand Then
		FilterParameters.Insert("Products.ItemsType", ProductsClientServer.SelectionByProductReusablePackagingWork(False));
	Else
		FilterParameters.Insert("Products.ItemsType", ProductsClientServer.SelectionByProductMultiTurnContainer(False));
	EndIf;
	
	Columns = "Products,Characteristic,Package,NumberOfPackages,ProductsGroup,DateOfShipment,
		|Individual,OperationCategory";
	
	TableOfGoods = ProcessingOfTabularForms.RowsFromClipboard(FilterParameters, Columns);
	
	If Not ValueIsFilled(TableOfGoods) Then
		Return;
	EndIf;
	
	StructureOfActions = New Structure;
	AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions);
	
	// Selection of articles and analytics.
	IncomeAndExpensesClientServer.InsertActionFillInItemCostAnalysisOfProducts(
		StructureOfActions,
		ThisObject,
		Object.BusinessOperation,
		Object.Organization,
		Object.Department);
		
	AddCollateralActionsOnServer(StructureOfActions, "SupplyOption,WarehouseIsRequired,DateOfShipmentRequired_");
	
	CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	RowsToProcess = New Array();
	
	For Each RowOfProduct In TableOfGoods Do
		
		CurrentRow = Object.Goods.Add();
		FillPropertyValues(CurrentRow, RowOfProduct);
		WhenAddingLineOfProductsOnServer_(CurrentRow);
		
		If Object.NotShipInInstallments Then
			CurrentRow.DateOfShipment = Object.DateOfShipment;
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
	UpdateColumnAvailableServer();
	
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

#EndRegion

#EndRegion

#Region Supply

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
							|tr = 'Belgede doldurulacak herhangi bir satır seçilmemiştir. Sevkiyat tarihi doldurulmayacaktır.'");
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
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.StartTimeMeasurement(True,
		"Document.InventoryConsumptionOrder.DocumentForm.Command.CreateAnAssignmentAdjustmentReservation");
	
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
		"Document.InventoryConsumptionOrder.DocumentForm.Command.CreateAssignmentAdjustmentRemoveFromReserve");
	
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

#EndRegion

#Region ShippingDates

&AtServer
Procedure SetVisibilityOfShippingDateFormElements()

	Items.GoodsDateOfShipment.Visible = Not Object.NotShipInInstallments;
	Items.DateOfShipment.Visible = Object.NotShipInInstallments;
	Items.FillInShipmentDate.Visible = Not Object.NotShipInInstallments;

EndProcedure

&AtServer
Procedure FillInShipmentDateServer(DateOfShipment, ArrayOfSelectedRows)

	ProvisionInDocumentsServer.FillInDetailsInCollection(Object.Goods, "DateOfShipment", DateOfShipment, ArrayOfSelectedRows);

EndProcedure

&AtServer
Procedure NotShipInInstallmentsOnChangeServer()

	If Object.NotShipInInstallments Then
		Object.DateOfShipment = ProvisionInDocumentsServer.MaximumValueInCollection(Object.Goods, "DateOfShipment", '00010101');
		ProvisionInDocumentsServer.FillInDetailsInCollection(Object.Goods, "DateOfShipment", Object.DateOfShipment);
	EndIf;

	SetVisibilityOfShippingDateFormElements();

EndProcedure

#EndRegion

#Region CancelLines

&AtClient
Procedure CancelUnprocessed(Command)
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.StartTimeMeasurement(True,
		"Document.InventoryConsumptionOrder.DocumentForm.Command.CancelUnprocessed");
	
	CancellationResult = CancelUnprocessedServer();
	ShowUserNotification(NStr("vi = 'Hủy các dòng chưa xử lý';
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
		"Document.InventoryConsumptionOrder.DocumentForm.Command.CancelSelectedLines");
	
	CancelSelectedLinesServer();
	ProvisionInDocumentsClientServer.FillInServiceDetails(Object.Goods, DateOfShipmentRequired_, WarehouseIsRequired);
	
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
	
	StructureOfActions = New Structure;
	AddCollateralActionsOnServer(StructureOfActions, "WarehouseIsRequired,DateOfShipmentRequired_");
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

&AtServer
Function AdjustOrderLines(StructureOfAdditionalParameters)
	
	OrderObject = FormAttributeToValue("Object");
	
	StructureOfAdditionalParameters.CheckBalance =
		OrderObject.Status <> Enums.InternalOrderStatuses.AwaitingApproval;
	
	ResultStructure1 = OrderObject.AdjustOrderLines(StructureOfAdditionalParameters);
	
	If StructureOfAdditionalParameters.CloseOrders Then
		OrderObject.Status = Enums.InternalOrderStatuses.Closed;
	EndIf;
	
	ValueToFormAttribute(OrderObject, "Object");
	FillInServiceDetailsOfDocumentForm();
	
	FillInServiceDetailsForProductRange();
	UpdateColumnAvailableServer();
	
	Modified = True;
	
	Return ResultStructure1;
	
EndFunction
#EndRegion

&AtClient
Procedure Attachable_ProcessObjectEntry()
	
	TMCommonUseClient.ProcessObjectEntryInForm(ThisObject, ParametersForRecording);
	
EndProcedure

#Region Supply

&AtClient
Procedure Attachable_CheckCompletionOfInventoryAllocationTask()
	
	Error = False;
	If ProvisionInDocumentsClient.NeedToUpdateAvailabilityAfterRecording(ThisObject,
		"Attachable_CheckCompletionOfInventoryAllocationTask", Error) Then
		ProvisionInDocumentsClient.ConfigureHyperlinksSupplyForecastAfterRecording(ThisObject, Error);
		UpdateColumn = ProvisionInDocumentsClient.ToUpdateColumnAvailableAfterInventoryAllocation(ThisObject);
		If UpdateColumn Then
			UpdateColumnAvailableAfterInventoryAllocation();
		Else
			RefreshStatusClient();
		EndIf;
	EndIf;
	
EndProcedure

&AtServer
Procedure UpdateColumnAvailableAfterInventoryAllocation()
	ProvisionInDocumentsServer.UpdateAvailabilityAfterRecording(ThisObject);
	RefreshStatusServer();
EndProcedure

&AtServer
Function AddressOfMovementTableInRepository()
	
	Return ProvisionInDocumentsServer.AddressOfMovementTableInRepository(ThisObject);
	
EndFunction

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

&AtServer
Function EnsuringToSetActionWhenChangingStatusForApproval(ActionCode)
	
	Result = ProvisionInDocumentsServer.ProvidingSetActionResultStructure();
	
	RowsWithShipAction = New Array;
	For Each TableRow In Object.Goods Do
		If TableRow.SupplyOption = Enums.SupplyOptions.Ship Then
			RowsWithShipAction.Add(TableRow.GetID());
		EndIf;
	EndDo;

	Changes = ProvisionInDocumentsServer.SetAction(
			ActionCode, ThisObject, RowsWithShipAction);

	FillPropertyValues(Result, Changes);

	If Changes.ChangesTable <> Undefined Then
		AfterFillingOutCollateral(
				Changes.ChangesTable, ProvisionInDocumentsClientServer.ActionSelectionMode(), Result);
	EndIf;

	Return Result;

EndFunction

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
	
	If Object.Status = PredefinedValue("Enum.InternalOrderStatuses.AwaitingApproval")
			Or Object.Status = PredefinedValue("Enum.InternalOrderStatuses.EmptyRef") Then
		
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
	
	DocumentParameters = DocumentParametersForSoftwareActions(ThisObject, Undefined);
	ProvisionInDocumentsClientServer.AddCollateralActions(StructureOfActions, StringFields_, DocumentParameters);
	
EndProcedure

&AtServer
Procedure AddCollateralActionsOnServer(StructureOfActions, StringFields_, DateOfShipment = Undefined)
	
	DocumentParameters = DocumentParametersForSoftwareActions(ThisObject, DateOfShipment);
	ProvisionInDocumentsClientServer.AddCollateralActions(StructureOfActions, StringFields_, DocumentParameters);
	
EndProcedure

&AtServer
Procedure FillInServiceDetailsOfDocumentForm()
	
	DocumentParameters = DocumentParametersForSoftwareActions(ThisObject, Undefined);
	ProvisionInDocumentsServer.FillInServiceDetailsOfDocumentForm(DocumentParameters);
	Catalogs.OperationCategories.FillInCategoryAttributes(Object.Goods);
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
Procedure ProvidingSetActionWithQuestion(ActionCode)
	
	Result = ProvidingSetAction(ActionCode);
	
	QuestionAsked = ProvisionInDocumentsClient.ShowIssueOfFillingSoftwareWithWholePackages(
		ThisObject,
		Object.Goods,
		Result,
		"AfterQuestionOfFillingPackageWithWholePackages");
	
	If Not QuestionAsked Then
		
		ProvisionInDocumentsClient.ShowQuestionUncheckShipByOneDate(
			ThisObject,
			Object.Goods,
			Result,
			"AfterQuestionRemoveFlagShipByOneDate");
			
	EndIf;
	
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

&AtClient
Procedure Attachable_WhenChangingModifiabilityOfForm()
	
	If FormModified <> Modified Then
		
		FormModified = Modified;
		ProvisionInDocumentsClient.ConfigureHyperlinkedSoftwareState(ThisObject);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure AfterQuestionOfFillingPackageWithWholePackages(Response, Result) Export
	
	QuestionAsked = ProvisionInDocumentsClient.ShowQuestionUncheckShipOneDateAfterQuestion(
		ThisObject,
		Object.Goods,
		Result,
		Response,
		"AfterQuestionRemoveFlagShipByOneDate");
		
	If Not QuestionAsked Then
		
		EnsuringToSetActionAfterQuestion(Response, Result);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure AfterQuestionRemoveFlagShipByOneDate(Response, Result) Export
	
	EnsuringToSetActionAfterQuestion(Response, Result);
	
EndProcedure

&AtServer
Procedure AfterFillingOutCollateral(Changes, Mode = Undefined, FillParameters = Undefined)
	
	Documents.InventoryConsumptionOrder.AfterFillingOutCollateral(Object, Changes, Mode, FillParameters);
	SetVisibilityOfShippingDateFormElements();
	
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
Procedure WhatIsSoftwareOptionWhenChangingOnServer(FillParameters)
	
	Changes = ProvisionInDocumentsServer.SupplyOptionOnChange(
		ThisObject,
		Items.Goods.CurrentRow);
		
	Mode = ProvisionInDocumentsClientServer.ModeSelectActionDirectly();
	AfterFillingOutCollateral(Changes, Mode, FillParameters);
	
EndProcedure

&AtClient
Procedure GoodsCollateralOptionWhenChangedAfterIssue(Response, AdditionalParameters) Export
	
	FillParameters = ProvisionInDocumentsClient.ParametersForProcessingShipmentDatesAfterFillingInCollateral(Response);
	WhatIsSoftwareOptionWhenChangingOnServer(FillParameters);
	
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
Procedure ProcessingSelectionIsDoneOnClientAfterQuestion(Response, AdditionalParameters) Export
	
	If Response = DialogReturnCode.Cancel Then
		Return;
	EndIf;
	
	If Response = DialogReturnCode.Yes Then
		Object.NotShipInInstallments = False;
		SetVisibilityOfShippingDateFormElements();
	EndIf;
	
	ProcessingSelectionOfSelectionOnServer(AdditionalParameters);
	
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
