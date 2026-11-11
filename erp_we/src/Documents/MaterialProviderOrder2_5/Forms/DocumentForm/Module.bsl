#Region Variables

&AtClient
Var CachedValues; //used by the mechanism for processing changes in PM details

&AtClient
Var FormModified; // it is used to work out the form modification change event

&AtClient
Var CurDataId; //used to pass the current line to the wait handler

&AtClient
Var NameOfCurTablePart; //used to pass the name of the table part being processed to the wait handler

&AtClient
Var ParametersForRecording Export;

#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	EmbeddingParameters = Documents.MaterialProviderOrder2_5.AvailableRemainingEmbeddingOptions();
	ProvisionInDocumentsServer.AvailableBalancesWhenCreatedOnServer(ThisObject, EmbeddingParameters);
	
	SetConditionalAppearance();
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(Object, ThisObject);
	
	Items.ManufacturedProductPriceKind.QuickChoice = Not GetFunctionalOption("UseSeveralPriceTypes");

	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject);
	// End IntegrationWith1CDocumentManagementSubsystem

	// Handler of the "Versioning of objects" mechanism
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	
	// Handler of the "Properties" mechanism
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("Object", Object);
	AdditionalParameters.Insert("ItemForPlacementName", "GroupAdditionalAttributes");
	AdditionalParameters.Insert("DeferredInitialization", True);
	PropertyManager.OnCreateAtServer(ThisObject, AdditionalParameters);
	
	// Handler of the "Destination" mechanism
	Catalogs.Assignments.DocumentFormWhenCreatedOnServer(ThisObject);
	
	// The connected equipment
	TMCommonUse.CustomizePeripherals(ThisObject, "ManufacturedProduct,UsedMaterials");
	
	If Not ValueIsFilled(Object.Ref) Then
		
		OnReadCreateAtServer();
		WhenYouChangeDestinationTemplateInDocument();
		
	EndIf;
	
	If ClientApplication.CurrentInterfaceVariant() = ClientApplicationInterfaceVariant.Version8_2 Then
		Items.GroupTotalManufacturedProducts.BackColor = New Color();
	EndIf;
	
	// ItemsAndDimensionsSelectionParameters
	ItemsAndDimensionsSelectionParameters = Documents.MaterialProviderOrder2_5.ItemsAndDimensionsSelectionParameters();
	IncomeAndExpensesServer.OnCreateAtServer(ThisObject, ItemsAndDimensionsSelectionParameters);
	// End ItemsAndDimensionsSelectionParameters
	
	SalesServer.SetModeForSelectingGroupsOfWarehouseItems(Items.Warehouse);
	PurchasesServer.SetModeForSelectingGroupsOfWarehouseItems(Items.WarehouseForReceipt);
	
	UpdateDestinationPresentation();
	
	SetVisibilityOfElementsByFO();
	
	SetAvailabilityOfClipboardCommands();
	SetVisibilityOfElementsByTaxationServer();
	
	CalculateOrderTotals(ThisObject);
	
	UpdateSpecificationSelectionList(Items, Object.ManufacturedProduct);

	ElementsToFillIn = New Array;
	ElementsToFillIn.Add(Items.DeliveryTimeFrom);
	ElementsToFillIn.Add(Items.DeliveryTimeTo);
	GoodsDeliveryClientServer.FillTimeFieldSelectionList(ElementsToFillIn);
	
	FormEvents.OnCreateAtServer(ThisObject, Cancel, StandardProcessing);
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	
	// ARAPAccounting
	ARAPAccountingFormWork.FormWhenCreatedOnServer(ThisObject);
	NotifyAboutCreationOfCalculationObject = Parameters.NotifyAboutCreationOfCalculationObject;
	// End ARAPAccounting
	
	// StandardSubsystems.FilesOperations
	HyperlinkParameters = FilesOperations.FilesHyperlink();
	HyperlinkParameters.Location = "CommandBar";
	FilesOperations.OnCreateAtServer(ThisObject, HyperlinkParameters);
	// End StandardSubsystems.FilesOperations
	
	AddSBPPaymentStatusUpdateCommand();
	
	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)

	// StandardSubsystems.AccessManagement
	AccessManagement.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.AccessManagement
	
	EmbeddingParameters = Documents.MaterialProviderOrder2_5.AvailableRemainingEmbeddingOptions();
	ProvisionInDocumentsServer.AvailableBalancesWhenReadingOnServer(ThisObject, EmbeddingParameters);
	
	OnReadCreateAtServer();
	
	PropertyManager.OnReadAtServer(ThisObject, CurrentObject);
	
	// ARAPAccounting
	ARAPAccountingFormWork.FormWhenReadingOnServer(ThisObject);
	// End ARAPAccounting
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	// End StandardSubsystems.AttachableCommands
	
	// ItemsAndDimensionsSelectionParameters
	ItemsAndDimensionsSelectionParameters = Documents.MaterialProviderOrder2_5.ItemsAndDimensionsSelectionParameters();
	IncomeAndExpensesServer.OnReadAtServer(ThisObject, ItemsAndDimensionsSelectionParameters);
	// End ItemsAndDimensionsSelectionParameters
	
	ConfigurationModificationOverridable.OnReadAtServer(ThisObject, CurrentObject);
	
EndProcedure

&AtClient
Procedure BeforeWrite(Cancel, WriteParameters)
	
	If NotExecuteCheck1BeforeWrite Then
		NotExecuteCheck1BeforeWrite = False;
		Return;
	EndIf;
	
	// If the document is held, fill in the empty shipping dates in the TS Products
	// and the empty receipt dates in the TS Materials, fill in the payment schedule.
	
	If WriteParameters.WriteMode = DocumentWriteMode.Posting Then
		
		Cancel = True;
		AdditionalParameters = New Structure;
		AdditionalParameters.Insert("WriteParameters", WriteParameters);
		ReusablePackageClient.OfferToPickUpMultiTurnContainer(
			ThisObject,
			"UsedMaterials",
			"Products,Characteristic,Count,Warehouse,DateOfReceipt",
			New CallbackDescription("BeforeRecordingOfferToPickUpMultiTurnContainer", ThisObject, AdditionalParameters));
			
	EndIf;
	
	TMCommonUseClient.RecordObjectIfNecessary(ThisObject, WriteParameters, Cancel);
	
EndProcedure

&AtClient
Procedure BeforeRecordingOfferToPickUpMultiTurnContainer(Result, AdditionalParameters) Export
	
	If Not Object.NotShipInInstallments Then
		
		Cancel = False;
		
		PaymentStepsClient.AskQuestionAboutResettingScheduleONChangesInShippingDate(
			ThisObject,
			New CallbackDescription(
				"BeforeRecordingAskQuestionAboutResettingScheduleONChangesInShipmentDateEnd", 
				ThisObject, 
				AdditionalParameters),
			Cancel);
		
		If Cancel Then
			Return;
		EndIf;
		
	EndIf;
	
	BeforeWritingToClientOnServer();
	CalculateOrderTotals(ThisObject);
	
	TMCommonUseClient.RecordObjectIfNecessary(ThisObject, AdditionalParameters.WriteParameters,,True);
	
EndProcedure

&AtClient
Procedure BeforeRecordingAskQuestionAboutResettingScheduleONChangesInShipmentDateEnd(Result, AdditionalParameters) Export
	
	If Result = DialogReturnCode.Yes Then
		Object.PaymentScheduleSteps.Clear();
	EndIf;
	ARAPAccountingClient.QuestionAboutResettingScheduleONChangesInShippingDatesHasBeenAsked(ThisObject);
	
	BeforeWritingToClientOnServer();
	CalculateOrderTotals(ThisForm);
	
	TMCommonUseClient.RecordObjectIfNecessary(ThisObject, AdditionalParameters.WriteParameters,,True);
	
EndProcedure

&AtServer
Procedure BeforeWritingToClientOnServer()
	
	ARAPAccountingServerCall.FormBeforeRecordingOnClientServer(ThisObject);
	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	// Handler of the "Properties" mechanism
	PropertyManager.BeforeWriteAtServer(ThisObject, CurrentObject);
	
	ARAPAccountingServer.BeforeWriteAtServer(ThisForm, CurrentObject);
	ConfigurationModificationOverridable.BeforeWriteAtServer(ThisObject, Cancel, CurrentObject, WriteParameters);

	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.BeforeWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	// End IntegrationWith1CDocumentManagementSubsystem
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)

	// StandardSubsystems.AccessManagement
	AccessManagement.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	// End StandardSubsystems.AccessManagement
	
	// Filling in service details (not visible to the user)
	FillInServiceDetails();
	FillInDependentServiceAttributes();
	FillInServiceDetailsOfTableParts();
	
	ProvisionInDocumentsServer.AfterWriteAtServer(ThisObject);
	SetSoftwareVisibility();
	
	TMCommonUse.FillInDuplicateDependentPropsInCollection(
		Object.ManufacturedProduct, DependentDetails("ManufacturedProduct"));
		
	TMCommonUse.FillInDuplicateDependentPropsInCollection(
		Object.UsedMaterials, DependentDetails("UsedMaterials"));
	
	FillInServiceDetailsOfSupply();
	
	DocumentsStates.AfterWriteAtServer(
		ThisObject,
		WriteParameters,,,
		AccessRight("Read", Metadata.AccumulationRegisters.CustomersARAPAccounting));
	
	If DocumentsStates.TaskCheckForReflectingStateOfOrdersIsNotRunning(ThisObject) Then
		RefreshStatusServer();
	EndIf;
	
	UpdateDestinationPresentation();
	UpdateTextDocumentsBasedOn();
	
	ConfigureDependentFormElements(ThisObject);
	ConfigureDependentFormElementsOnServer();
	
	// ItemsAndDimensionsSelectionParameters
	IncomeAndExpensesServer.AfterWriteAtServer(ThisObject);
	// End ItemsAndDimensionsSelectionParameters
	
	// ARAPAccounting
	ARAPAccountingFormWork.FormAfterRecordingOnServer(ThisObject, CurrentObject.AdditionalProperties);
	// End ARAPAccounting
	
	ConfigurationModificationOverridable.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);

EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	
	FormModified = Undefined;
	Attachable_WhenChangingModifiabilityOfForm();
	
	WriteParameters.Insert("SalesOpportunity", Object.SalesOpportunity);
	WriteParameters.Insert("NotificationDocumentKeys", OperationsWithDocumentJournalsClient.GetKeyParametersForDocument(
		Object.Ref, Object.Date, Object.BusinessOperation));
	Notify("Write_MaterialProviderOrder2_5", WriteParameters, Object.Ref);
	
	ARAPAccountingClient.FormAfterRecording(ThisObject);
	ProvisionInDocumentsClient.AfterWrite(ThisObject, "Attachable_CheckCompletionOfInventoryAllocationTask");
	
	TMCommonUseClient.PerformActionsAfterRecording(ThisObject, Object, WriteParameters);
	
	// StandardSubsystems.AttachableCommands
	If CommonClient.SubsystemExists("StandardSubsystems.AttachableCommands") Then
		ModuleAttachableCommandsClient = CommonClient.CommonModule("AttachableCommandsClient");
		ModuleAttachableCommandsClient.AfterWrite(ThisObject, Object, WriteParameters);
	EndIf;
	// End StandardSubsystems.AttachableCommands
	
	DocumentsStatesClient.AfterWrite(ThisObject, "Attachable_CheckTasksToReflectStateOfOrders");
	
	ConfigurationModificationClientOverridable.AfterWrite(ThisObject, WriteParameters);
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	// Handler of the "Properties" mechanism
	If PropertyManagerClient.ProcessNotifications(ThisObject, EventName, Parameter) Then
		UpdateAdditionalAttributesItems();
		PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
	EndIf;
	
	// Peripherals
	If IsInputAvailable()
		And Source = "Peripherals" Then
		
		If EventName = "ScanData"
			And EquipmentManagerTMClient.ThereIsRawEvent() Then
			
			BarcodeData_5 = EquipmentManagerTMClient.ConvertDataFromScannerToArray(Parameter);
			
			If Items.GroupPages.CurrentPage = Items.PageMaterials Then
				ProcessBarcodes(BarcodeData_5, "UsedMaterials", Items.UsedMaterials);
			Else
				ProcessBarcodes(BarcodeData_5, "ManufacturedProduct", Items.ManufacturedProduct);
			EndIf;
			
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
		
		ProcessBarcodes(BarcodeData_5, Parameter.TSName, Items[Parameter.TSName]);
		
	EndIf;
	
	If EventName = "PaymentCredited" And Parameter = Object.Ref
	 Or SalesClient.ChangedPaymentDocumentsForCustomers(EventName) Then
		PaymentCreditedServer(EventName, Parameter, Source);
	EndIf;
	
	If EventName = "CopyingLinesToClipboard" Then
		SetAvailabilityOfClipboardCommandsOnClient();
	EndIf;
	
	If EventName = "AddingPartnerToSegment" Or EventName = "RemovingPartnerFromSegment" Then
		SetVisibilityOfShipmentBanToPartner();
	EndIf;
	
	If EventName = "SBPStatusHasBeenChanged" Then
		AddSBPPaymentStatusUpdateCommand();
		CashClientLocalization.CheckSBPPayment(ThisObject, Object.Ref, Object.Counterparty);
	EndIf;
	
	If EventName = "Recording_NotificationOfSpecialTaxRegimes" Then
		
		UpdateTextDocumentsBasedOn();
		
	EndIf;
	
	// StandardSubsystems.FilesOperations
	FilesOperationsClient.NotificationProcessing(ThisObject, EventName);
	// End StandardSubsystems.FilesOperations

EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	UpdateCachedValuesToAccountForBatchesOfFINISHEDProductBeingRepaired();

	AttachIdleHandler("Attachable_WhenChangingModifiabilityOfForm", 1);
	
	// StandardSubsystems.Properties
	PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
	// End StandardSubsystems.Properties
	
	EquipmentManagerClient.StartConnectingDevicesWhenYouOpenForm(Undefined, ThisObject, "BarcodeScanner");
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	// StandardSubsystems.FilesOperations
	FilesOperationsClient.OnOpen(ThisObject, Cancel);
	// End StandardSubsystems.FilesOperations
	
	CashClientLocalization.AttachablePaymentVerificationViaServices(ThisObject, Object.Ref, Object.Counterparty);

EndProcedure

&AtServer
Procedure BeforeLoadDataFromSettingsAtServer(Settings)
	
	HideCanceledProductLines = Settings.Get("HideCanceledProductLines");
	
	If HideCanceledProductLines Then
		Items.ManufacturedProduct.RowFilter = New FixedStructure("Canceled", False);
	Else
		Items.ManufacturedProduct.RowFilter = Undefined;
	EndIf;
	
	UpdateSelectionOfRowsByCanceled(Items, "ManufacturedProduct", HideCanceledProductLines, True);
	UpdateSelectionOfRowsByCanceled(Items, "UsedMaterials", HideCanceledLinesMaterials, True);
	
	If Not Object.Ref.IsEmpty() Then
		Settings.Delete("Object.NotShipInInstallments");
		Settings.Delete("Object.OneDateReceipt");
	EndIf;
	
EndProcedure

&AtServer
Procedure OnLoadDataFromSettingsAtServer(Settings)
	
	SetVisibilityOfShippingDateFormElements();
	SetVisibilityOfReceiptDateFormElements();
	
EndProcedure

&AtClient
Procedure ChoiceProcessing(ValueSelected, ChoiceSource)
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.TimeMeasurement(
		"Document.MaterialProviderOrder2_5.Form.DocumentForm.Event.ChoiceProcessing");
	
	If ChoiceSource.FormName = "DataProcessor.OrderSupplyForecast.Form.Form" Then
		
		AddressOfTheMovementTable = FillInCollateralFromCollateralStateForm(
			ValueSelected.ActionCode,
			ValueSelected.AddressAnalyst,
			ValueSelected.FillParameters);
			
		// Returning the control to the form of processing the security status.
		RunCallback(ValueSelected.Callback, AddressOfTheMovementTable);
		
	ElsIf ChoiceSource.FormName = "Document.MaterialProviderOrder2_5.Form.PrintDetails" Then
		
		If ValueSelected <> Undefined Then
			FillPropertyValues(Object, ValueSelected);
		EndIf;
		
	ElsIf ChoiceSource.FormName = "DataProcessor.SelectReusablePackage.Form.Form" Then
		
		FillMultiTurnContainersFromStorageServer(ValueSelected.AddressOfReusableContainerInStorage);
		ReusablePackageClient.NotifyUserAboutFillingMultiTurnContainers();
		
	ElsIf ChoiceSource.FormName = "Document.MaterialProviderOrder2_5.Form.SelectionFormByBOMs" Then
		
		If ValueSelected <> Undefined Then
			SelectionOfMaterialsAccordingToSpecifications(ValueSelected);
		EndIf;
		
	ElsIf ProductsClient.ThisIsIndicationOfSeries(ChoiceSource) Then
		
		ProductsClient.ProcessSeriesIndication(
			ThisObject, SeriesSpecificationParameters[ValueSelected.TSName], ValueSelected);
		
	ElsIf ChoiceSource.FormName = "DataProcessor.SelectGoodsToSalesDocument.Form.Form" 
		  Or ChoiceSource.FormName = "DataProcessor.SelectGoodsToPurchaseDocument.Form.Form" Then
		
		TSName = ?(Items.GroupPages.CurrentPage = Items.ProductsPage, "ManufacturedProduct", "UsedMaterials");
		HandlingSelectionSelectionOnClient(ValueSelected, TSName);
		
	ElsIf ChoiceSource.FormName = "DataProcessor.OrderClosureWizard.Form.ClosureForm" Then
		
		AdjustOrderLines(ValueSelected);
		
	EndIf;
	
	ProvisionInDocumentsClientServer.FillInServiceDetails(
		Object.ManufacturedProduct,
		DateOfShipmentRequired_,
		WarehouseIsRequired);
	
	If Window <> Undefined Then
		Window.Activate();
	EndIf;
	
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)
	
	ForceCloseTheForm = True;
	
EndProcedure

&AtClient
Procedure OnClose(Exit)
	
	If Not Exit Then
		EquipmentManagerClient.StartDisablingHardwareWhenClosingForm(Undefined, ThisObject);
	EndIf;
	
	If Not Exit 
		And ValueIsFilled(Object.Ref)
		And NotifyAboutCreationOfCalculationObject Then
		ARAPAccountingClient.FormWhenClosing(ThisObject);
	EndIf;
	
	CashClientLocalization.DisablePaymentVerificationViaServices(ThisObject);
	
EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	
	// StandardSubsystems.Properties
	PropertyManager.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes);
	// End StandardSubsystems.Properties
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

#Region CommonElements

&AtClient
Procedure WarehouseOnChange(Item)
	
	WhenChangingWarehouseServer("ManufacturedProduct");
	
EndProcedure

&AtClient
Procedure WarehouseForReceiptOnChange(Item)
	
	WhenChangingWarehouseServer("UsedMaterials");
	
EndProcedure

&AtClient
Procedure PartnerOnChange(Item)
	
	If Not ValueIsFilled(Object.Partner) Then
		GoodsDeliveryClientServer.ClearDeliveryDetails(Items, Object);
		SetVisibilityOfShipmentBanToPartner();
		Return;
	EndIf;
	
	WhenChangingPartnerServer();
	
EndProcedure

&AtClient
Procedure ContactPersonOnChange(Item)
	
	If Object.ContactPerson.IsEmpty() Or Not Object.Partner.IsEmpty() Then
		Return;
	EndIf;
	
	PartnerChanged_ = False;
	ContactPersonOnChangeServer(PartnerChanged_);
	
	If PartnerChanged_ And Not ValueIsFilled(Object.Partner) Then
		GoodsDeliveryClientServer.ClearDeliveryDetails(Items, Object);
	EndIf;
	
EndProcedure

&AtClient
Procedure CounterpartyOnChange(Item)
	
	WhenChangingCounterpartyServer();
	
EndProcedure

&AtClient
Procedure ContractOnChange(Item)
	
	WhenChangingAgreementServer(True);
	
EndProcedure

&AtClient
Procedure UnderRepairProductOnChange(Item)
	
	FinishedProductToBeRepairedItemOnChangeATServer(CachedValues);
	UpdateCachedValuesToAccountForBatchesOfFINISHEDProductBeingRepaired();
	
	CheckFillInBillOfMaterialsInManufacturingProductLines(Undefined);
	
EndProcedure

&AtClient
Procedure UnderRepairVariantOnChange(Item)
	
	DataStructureOfFinishedProductBeingRepaired = ProductionManagementClientServer.DataOfFinishedProductBeingRepairedByStructure(Object);
	
	If ProductsClient.YouNeedToUpdateStatusOfSeriesInHeader(DataStructureOfFinishedProductBeingRepaired, CachedValues, SeriesSpecificationParameters.FinishedProductBeingRepaired) Then
		FillInBatchIndicationStatusesONChangesOfFinishedProductBeingRepaired(CachedValues, DataStructureOfFinishedProductBeingRepaired);
		UpdateCachedValuesToAccountForBatchesOfFINISHEDProductBeingRepaired(DataStructureOfFinishedProductBeingRepaired);
	EndIf;
	
	CheckFillInBillOfMaterialsInManufacturingProductLines(Undefined);
	
EndProcedure

&AtClient
Procedure UnderRepairBatchOnChange(Item)
	
	ValueSelected = ProductsClientServer.SelectedSeries();
	ValueSelected.Value = Object.UnderRepairBatch;
	
	ProcessIndicationOfBatchOfFINISHEDProductBeingRepaired(ValueSelected);
	
EndProcedure

&AtClient
Procedure VATRateOnChange(Item)
	
	WhenChangingVATRateServer(CachedValues);
	
EndProcedure

&AtClient
Procedure StatusOnChange(Item)
	
	WhenStatusChangesServer();
	
EndProcedure

&AtClient
Procedure VATTaxationOnChange(Item)
	
	WhenChangingVATTaxationServer(CachedValues);
	
EndProcedure

&AtClient
Procedure PriceIncludesVATOnChange(Item)
	
	OnChangePriceIncludesVATServer(CachedValues);
	
EndProcedure

&AtClient
Procedure CurrencyOnChange(Item)
	
	RecalculateAmounts = ValueIsFilled(Object.Currency)
					   And (PriceManagementSystemClient.CurrencyConversionRequired(Object, DocumentCurrency, "ManufacturedProduct")
						  Or PriceManagementSystemClient.CurrencyConversionRequired(Object, DocumentCurrency, "UsedMaterials"));
	
	WhenChangingCurrencyServer(Object.Currency, RecalculateAmounts, CachedValues);
	
	If RecalculateAmounts Then
		PriceManagementSystemClient.NotifyAboutEndOfConversionOfAmountsIntoCurrency(DocumentCurrency, Object.Currency);
	EndIf;
	
EndProcedure

&AtClient
Procedure IncomingDocumentNumberTextEditEnd(Item, Text, ChoiceData, StandardProcessing)
	
	CheckAvailabilityOfOrdersAccordingToGiver(Text);
	
EndProcedure

&AtClient
Procedure BusinessOperationOnChange(Item)
	
	If Not Object.BusinessOperation = BusinessTransactionBeforeTheChange Then
		
		If Not Object.ManufacturedProduct.Count() = 0 Then
			
			ShowQueryBox(
				New CallbackDescription("BusinessOperationOnChangeCompletion", ThisObject),
				NStr("vi = 'Khi thay đổi sẽ thực hiện xác minh sự tương ứng giữa mặt hàng được chỉ định trong chứng từ, giao dịch đã chọn và xóa dòng không tương ứng. Tiếp tục?';
					|ru = 'При изменении будет выполнена проверка соответствия указанной в документе номенклатуры, выбранной операции и удаление несоответствующих строк. Продолжить?';
					|en = 'Upon the change, the compliance of the item specified in the document, the selected operation, and the deletion of nonconforming lines will be checked. Continue?'; fa = 'Upon the change, the compliance of the item specified in the document, the selected operation, and the deletion of nonconforming lines will be checked. Continue?';
					|it = 'Upon the change, the compliance of the item specified in the document, the selected operation, and the deletion of nonconforming lines will be checked. Continue?';
					|pl = 'Upon the change, the compliance of the item specified in the document, the selected operation, and the deletion of nonconforming lines will be checked. Continue?';
					|tr = 'Değişiklik yapıldığında, belgede belirtilen öğenin seçili işlemle eşleştiğinden emin olmak için kontrol yapılacak ve tutarsız satırlar silinecektir. Devam edilsin mi?'"),
				QuestionDialogMode.YesNo);
				
		Else
			BusinessOperationOnChangeCompletion(DialogReturnCode.Yes, Undefined)
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure OrganizationOnChange(Item)
	
	WhenOrganizationChangesServer(CachedValues);
	
EndProcedure

&AtClient
Procedure LabelPaymentStagesClick(Item, StandardProcessing)
	
	Notification = New CallbackDescription("LabelPaymentStagesClickCompletion", ThisObject);
	PlacePaymentStepsInTemporaryStorage(Item.Name);
	ARAPAccountingClient.LabelPaymentStagesClick(ThisObject, Item, StandardProcessing, Notification);
	
EndProcedure

&AtClient
Procedure DateOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	
	WhenChangingDateServer();
	
EndProcedure

&AtClient
Procedure TextDocumentsBasedOnURLProcessing(Item, Var_URL, StandardProcessing)
	
	ClearMessages();
	StandardProcessing = False;
	DPPSelectionParameters = New Structure();
	DPPSelectionParameters.Insert("Organization", Object.Organization);
	DPPSelectionParameters.Insert("Basis",   Object.Ref);
	DPPSelectionParameters.Insert("Date",        Object.Date);
	
	VATAccountingERPClient.ProcessingOfNavigationLinkDOPP(ThisObject, DPPSelectionParameters, Var_URL, StandardProcessing);
	
EndProcedure

&AtClient
Procedure DateOfShipmentOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	
	DateOfShipmentOnChangeServer();
	
EndProcedure

&AtClient
Procedure NotShipInInstallmentsOnChange(Item)
	
	WhenChangingDoNotShipServerInParts();
	
EndProcedure

&AtClient
Procedure OneDateReceiptOnChange(Item)
	
	IfYouChangeReceiptOneDateServer();
	
EndProcedure

&AtClient
Procedure DateOfReceiptOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	
	DateOfReceiptOnChangeATServer();
	
EndProcedure

&AtClient
Procedure ManagerOnChange(Item)
	
	FillInSubordinatePropertiesForStatistics("Manager");
	
EndProcedure

&AtClient
Procedure StateClick(Item, StandardProcessing)
	
	SalesClient.StatusInFormOfDocumentClick(StandardProcessing, ThisObject);
	
EndProcedure

&AtClient
Procedure ContentStartChoice(Item, ChoiceData, StandardProcessing)
	
	CommonClient.ShowCommentEditingForm(
		Item.EditText,
		ThisObject,
		"Object.ProcessingService",
		NStr("vi = 'Nội dung dịch vụ gia công';
			|ru = 'Содержание услуги по переработке';
			|en = 'Subcontracting service content'; fa = 'Subcontracting service content';
			|it = 'Il contenuto del servizio di trasformazione';
			|pl = 'Opis usług przetwarzania';
			|tr = 'İşleme hizmetlerinin içeriği'"));
	
EndProcedure

&AtClient
Procedure LineOfBusinessOnChange(Item)
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.TimeMeasurement(
		"Document.MaterialProviderOrder2_5.Form.DocumentForm.Item.LineOfBusiness.OnChange");
	
	LineOfBusinessOnChangeServer();
	
EndProcedure

&AtClient
Procedure ProductionProcessTypeOnChange(Item)
	
	If Object.ProductionProcessType <> TypeOfProductionProcessBeforeTheChange Then
		
		TableName = "ManufacturedProduct";
		NameOfLinkedTable = "UsedMaterials";	
		FieldNameSpecification = "BillOfMaterials";
		
		NameOfNotificationProcedure = "ProductionProcessTypeOnChangeCompletion";
		QueryText = StrTemplate(
			NStr("vi = 'Sẽ bổ sung lại bảng kê chi tiết các nguồn lực sản xuất trong phần bảng ""%1"", sẽ xóa thành phần của các nguyên vật liệu theo bảng kê chi tiết các nguồn lực sản xuất được thay đổi. Tiếp tục?';
				|ru = 'Спецификации в табличной части ""%1"" будут перезаполнены, состав материалов по измененным спецификациям будет очищен. Продолжить?';
				|en = 'Bills of materials in table ""%1"" will be refilled, and materials under the changed bills of materials will be cleared. Continue?'; fa = 'Bills of materials in table ""%1"" will be refilled, and materials under the changed bills of materials will be cleared. Continue?';
				|it = 'Le specifiche nella parte tabulare ""%1"" saranno ricompilate, la composizione dei materiali secondo le specifiche modificate sarà cancellata. Continuare?';
				|pl = 'Specyfikacje w części tabelarycznej ""%1"" będą wypełnione ponownie, skład materiałów według zmienionych specyfikacji będzie oczyszczony. Kontynuować?';
				|tr = '""%1"" tablosundaki özellikler yeniden doldurulacak, değiştirilen özelliklerin malzeme bileşimi temizlenecektir. Devam edilsin mi?'"),
			TableName);
			
		LinkedAttributes = New Structure("TypeOfProductionProcessBeforeTheChange", "ProductionProcessType");
		
		ModifiedRows = GetBasicStringSpecifications(TableName, FieldNameSpecification,, True);
		
		FillInSpecificationInTablePart(
			TableName, 
			NameOfLinkedTable, 
			FieldNameSpecification, 
			ModifiedRows, 
			NameOfNotificationProcedure, 
			QueryText, 
			LinkedAttributes);
		
	EndIf;

EndProcedure

&AtClient
Procedure ProductionProcessTypeOnChangeCompletion(QuestionResult, AdditionalParameters) Export
	
	If QuestionResult <> DialogReturnCode.Yes Then
		Object.ProductionProcessType = TypeOfProductionProcessBeforeTheChange;
		Return;
	EndIf;
	
	FillInMainSpecificationEnd(AdditionalParameters);
	
EndProcedure

&AtClient
Procedure GroupPagesOnCurrentPageChange(Item, CurrentPage)
	
	// StandardSubsystems.Properties
	If CurrentPage.Name = "AdditionalPage"
	   And Not ThisObject.PropertiesParameters.DeferredInitializationExecuted Then
		
		PropertiesExecuteDeferredInitialization();
		PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
		
	EndIf;
	// End StandardSubsystems.Properties
	
	ARAPAccountingClient.UpdateHyperlinkTextPaymentSteps(ThisObject);
	
EndProcedure

&AtClient
Procedure PriceTypeMaterialsOnChange(Item)

	If Object.PriceTypeMaterials = PriceTypeMaterialsBeforeChanges Then
		Return;
	EndIf;
	
	ShowQueryBox(
		New CallbackDescription("PriceTypeMaterialsOnChangeCompletion", ThisObject),
		NStr("vi = 'Sẽ điền lại đơn giá trong danh sách ""Nguyên vật liệu để sản xuất"". Tiếp tục?';
			|ru = 'Цены в списке ""Сырье и материалы для производства"" будут перезаполнены. Продолжить?';
			|en = 'Prices in the ""Raw and consumable materials for production"" list will be refilled. Continue?'; fa = 'Prices in the ""Raw and consumable materials for production"" list will be refilled. Continue?';
			|it = 'I prezzi nell''elenco ""Materie prime e materiali per la produzione"" saranno ricompilati. Continuare?';
			|pl = 'Ceny na liście ""Materiały do produkcji"" zostaną wypełnione ponownie. Kontynuować?';
			|tr = '''Üretim için hammadde ve malzemeler'' listesindeki fiyatlar yeniden doldurulacaktır. Devam edilsin mi?'"),
		QuestionDialogMode.YesNo,
		45,
		DialogReturnCode.Yes,
		NStr("vi = 'Chọn dạng đơn giá của nguyên vật liệu';
			|ru = 'Выбор вида цены материалов';
			|en = 'Select material price type'; fa = 'Select material price type';
			|it = 'Selezione del tipo di prezzo dei materiali';
			|pl = 'Wybór rodzaju ceny materiałów';
			|tr = 'Malzeme fiyatı türünün seçilmesi'"),
		DialogReturnCode.No);

EndProcedure

&AtClient
Procedure PriceTypeMaterialsOnChangeCompletion(QuestionResult, AdditionalParameters) Export

	If QuestionResult <> DialogReturnCode.Yes Then
		Object.PriceTypeMaterials = PriceTypeMaterialsBeforeChanges;
		Return;
	EndIf;
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.TimeMeasurement(
		"Document.MaterialProviderOrder2_5.Form.DocumentForm.Item.PriceTypeMaterials.OnChange");
	
	FillInPricesByTypeOfMaterialPricesServer(False);
	
	PricesCalculated =
		Object.UsedMaterials.FindRows(New Structure("Price", 0)).Count() <> Object.UsedMaterials.Count();
	PartnerPricesFillingClient.NotifyAboutEndOfFillingInPricesByTypeOfSupplierSPrice(PricesCalculated, Object.PriceTypeMaterials);
	
	CalculateOrderTotals(ThisObject);
	
	PriceTypeMaterialsBeforeChanges = Object.PriceTypeMaterials;
		
EndProcedure

&AtClient
Procedure ApprovalDateOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	
	DateOfApprovalWhenServerWasChanged();
	
EndProcedure

#EndRegion

#Region Delivery

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
		Object[NamesOfDetailsOfDeliveryAddresses.AttributeNameOfDeliveryAddressFieldValues]);
	
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
Procedure SpecialTransportationConditionsOnChange(Item)
	
	SpecialTransportationConditionsOnChangeServer();
	
EndProcedure

#EndRegion

#EndRegion

#Region FormTableItemsEventHandlersManufacturedProduct

&AtClient
Procedure ManufacturedProductAfterDeleteRow(Item)
	
	ProvisionInDocumentsClientServer.FillInServiceDetails(Object.ManufacturedProduct, DateOfShipmentRequired_, WarehouseIsRequired);
	UpdateSpecificationSelectionList(Items, Object.ManufacturedProduct);
	CalculateOrderTotals(ThisObject);
	
	WarehousesClient.UpdateWarehouseTable(
		WarehouseTable,
		Undefined,
		ProcessingOfTabularFormsClientServer.LineCache(Items.ManufacturedProduct, ThisObject),
		WarehouseGroup_);
	
	TotalWarehouses_ = WarehouseTable.Count();
	WarehousesClientServer.UpdateWarehouseGroupImage(SeveralWarehousesText, Items.PictureMultipleWarehouses, TotalWarehouses_);
	
	ThereIsChangeInShippingDates = ARAPAccountingClient.ThereIsChangeInShippingDates(ThisObject);
	ManufacturedProductsAfterRemovalATServer(ThereIsChangeInShippingDates);
	
EndProcedure

&AtClient
Procedure ManufacturedProductBeforeDeleteRow(Item, Cancel)
	
	ProcessingOfTabularFormsClient.CacheCurLine(Items.ManufacturedProduct, ThisObject);
	IDOfRowsToDelete = Items.ManufacturedProduct.SelectedRows;
	SpecificationsForRemoval = SpecificationsForRemoval(IDOfRowsToDelete);
	ARAPAccountingClient.SaveShipmentDatesInParameters(ThisObject);
	
	If Not SpecificationsForRemoval.Count() = 0 Then
		
		Cancel = True;
		AdditionalParameters = New Structure;
		AdditionalParameters.Insert("IDOfRowsToDelete", IDOfRowsToDelete);
		AdditionalParameters.Insert("SpecificationsForRemoval", SpecificationsForRemoval);
		
		CallbackDescription = New CallbackDescription(
										"ManufacturedProductBeforeDeleteRowCompletion", ThisObject, AdditionalParameters);
		
		ShowQueryBox(CallbackDescription, 
			NStr("vi = 'Trong phần bảng ""Nguyên vật liệu để sản xuất"" sẽ còn lại các dòng 
				|theo bảng kê chi tiết còn lại trong phần bảng ""Thành phẩm"". Tiếp tục?';
				|ru = 'В табличной части ""Сырье и материалы для производства"" будут оставлены строки 
				|по оставшимся спецификациям в табличной части ""Выпускаемая продукция"". Продолжить?';
				|en = 'In table ""Raw and consumable materials for production"", rows 
				|containing BOMs that remain in the ""Released products"" table will not be deleted. Continue?'; fa = 'In table ""Raw and consumable materials for production"", rows 
				|containing BOMs that remain in the ""Released products"" table will not be deleted. Continue?';
				|it = 'Nella parte tabulare ""Materie prime e materiali per la produzione"" saranno mantenute le righe 
				| per le specifiche restanti nella parte tabulare ""Prodotti in fabbricazione"". Continuare?';
				|pl = 'W sekcji tabelarycznej ""Surowce i materiały dla produkcji"" pozostaną wiersze 
				|według pozostałych specyfikacji w sekcji tabelarycznej ""Wypuszczane wiersze pozycji"". Kontynuować?';
				|tr = '""Üretim için hammaddeler ve malzemeler"" sekmesinde kalan şartnamelere ilişkin satırlar
				| ""İmal edilen ürünler"" sekmesinde korunacaktır. Devam edilsin mi?'"),
			QuestionDialogMode.YesNo);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ManufacturedProductOnStartEdit(Item, NewRow, Copy)
	
	ProcessingOfTabularFormsClient.CacheCurLine(Items.ManufacturedProduct, ThisObject);
	CurrentData = Items.ManufacturedProduct.CurrentData;
	
	StructureOfActions = New Structure;
	
	If NewRow And Not Copy Then
		
		If Not VATRateIsIndicatedInTablePart(Object.BusinessOperation) Then
			CurrentData.VATRate = Object.VATRate;
		Else
			AddActionToStructureFillInVATRate(Object, StructureOfActions);
		EndIf;
		
		IncomeAndExpensesClientServer.InsertActionInitializeArticleAndAnalyticsAfterAddingLine(
			StructureOfActions, ThisObject, "Object.ManufacturedProduct");
		
		StructureOfActions.Insert("FillInPriceView", New Structure("PriceKind", DefaultPriceType));
		
	EndIf;
	
	If NewRow Then
		CurrentData.RowCode = 0;
	EndIf;
	
	If Copy Then
		
		AddCollateralActionsOnClient(StructureOfActions, "SupplyOption,Available,WarehouseIsRequired,DateOfShipmentRequired_");
		
		StructureOfActions.Insert(
			"CheckSeriesCalculateStatus",
			New Structure("Warehouse, SeriesSpecificationParameters", CurrentData.Warehouse, SeriesSpecificationParameters.ManufacturedProduct));
		
	EndIf;
	
	If ValueIsFilled(StructureOfActions) Then
		BatchProcessingOfTablePartClient.ProcessTSString(CurrentData, StructureOfActions, CachedValues);
	EndIf;
	
	If Copy Then
		ProvisionInDocumentsClientServer.FillInServiceDetails(Object.ManufacturedProduct, DateOfShipmentRequired_, WarehouseIsRequired);
	EndIf;
	
	ARAPAccountingClient.SaveShipmentDatesInParameters(ThisObject);
	
EndProcedure

&AtClient
Procedure ManufacturedProductSelection(Item, RowSelected, Field, StandardProcessing)
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.TimeMeasurement(
		"Document.MaterialProviderOrder2_5.Form.DocumentForm.Items.ManufacturedProduct.Selection");
	
	If Item.CurrentItem = Items.ManufacturedProductAvailable And Not ReadOnly Then
	
		StandardProcessing = False;
		
		FormParameters = ParametersOfQuantityAndSeriesRequestForm(Undefined);
		
		If FormParameters <> Undefined Then
			OpenForm("DataProcessor.QuantityAndBatchRequest.Form", FormParameters, ThisObject);
		EndIf;
		
	ElsIf Field = Items.ManufacturedProductPrice Then
		
		If ReadPriceTypeRight Then
			
			CurrentData = Items.ManufacturedProduct.CurrentData;
			
			If ValueIsFilled(CurrentData.PriceKind) Then
				
				ClearMessages();
				
				CommonClient.MessageToUser(
					NStr("vi = 'Để soạn đơn giá, hãy xóa dạng giá';
						|ru = 'Для редактирования цены очистите вид цены';
						|en = 'To edit the price, clear the price type'; fa = 'To edit the price, clear the price type';
						|it = 'Для редактирования цены очистите вид цены';
						|pl = 'To edit the price, clear the price type';
						|tr = 'Fiyatı düzenlemek için fiyat türünü temizleyin'"),
					Object.Ref,
					CommonClientServer.PathToTabularSection(
						"Object.ManufacturedProduct", CurrentData.LineNumber, "PriceKind"),);
					
			EndIf;
			
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ManufacturedProductBeforeEditEnd(Item, NewRow, CancelEdit, Cancel)
	
	If NewRow
		And CancelEdit Then
		Return;
	EndIf;
	
	CurrentData = Items.ManufacturedProduct.CurrentData;
	
	// Check the shipment date
	If CurrentData <> Undefined And Object.NotShipInInstallments Then
		CurrentData.DateOfShipment = Object.DateOfShipment;
	EndIf;
	
	// Let's check the line code
	If NewRow And Not CancelEdit Then
		SetKeysInProductLines(Items, Object, CurrentData);
	EndIf;
	
	LineCache =
		?(NewRow, Undefined, ProcessingOfTabularFormsClientServer.LineCache(Items.ManufacturedProduct, ThisObject));
	
	If Not NewRow Then
		
		If Not LineCache = Undefined
			And Not CurrentData = Undefined
			And Not CurrentData.BillOfMaterials = LineCache.BillOfMaterials Then
			
			SpecificationsForRemoval = SpecificationsForRemoval(Item.SelectedRows, LineCache.BillOfMaterials);
			If SpecificationsForRemoval.Count() Then
				
				AdditionalParameters = New Structure;
				AdditionalParameters.Insert("SpecificationsForRemoval", SpecificationsForRemoval);
				AdditionalParameters.Insert("CurrentData",         CurrentData);
				AdditionalParameters.Insert("LineCache",             LineCache);
				
				CallbackDescription = New CallbackDescription(
					"ManufacturedProductBeforeEditEndCompletion", ThisObject, AdditionalParameters);
				
				QueryText = NStr(
					"vi = 'Đã thay đổi bảng kê chi tiết chính. Trong phần bảng ""Nguyên vật liệu để sản xuất"" sẽ xóa các dòng
					|theo bảng kê chi tiết %1. Tiếp tục?';
					|ru = 'Изменилась основная спецификация. В табличной части ""Сырье и материалы для производства"" будут удалены строки 
					|по спецификации %1. Продолжить?';
					|en = 'Main BOM is changed. Rows corresponding to the %1 BOM will be deleted 
					|from table ""Raw and consumable materials for production"". Continue?'; fa = 'Main BOM is changed. Rows corresponding to the %1 BOM will be deleted 
					|from table ""Raw and consumable materials for production"". Continue?';
					|it = 'La specifica di base è stata modificata. Nella parte tabulare ""Materie prime e materiali per la produzione"" verranno cancellate le righe 
					| per la specifica %1. Continuare?';
					|pl = 'Zmieniono specyfikację podstawową. W części tabelarycznej ""Сырье и материалы для производства"" będą usunięte wiersze 
					|według specyfikcji %1. Kontynuować?';
					|tr = 'Ana şartname değişti. ""Üretim için hammaddeler"" sekmesindeki satırlar 
					|şartnameden silinecektir.%1 Devam edilsin mi?'");
				
				ShowQueryBox(
					CallbackDescription, 
					StringFunctionsClientServer.SubstituteParametersToString(QueryText, SpecificationsForRemoval[0]),
					QuestionDialogMode.YesNo);
				
			EndIf;
			
		EndIf;
		
	EndIf;
	
	If Not CancelEdit Then
		
		LineCache =
			?(NewRow, Undefined, ProcessingOfTabularFormsClientServer.LineCache(Items.ManufacturedProduct, ThisObject));
		
		WarehousesClient.UpdateWarehouseTable(WarehouseTable, CurrentData, LineCache, WarehouseGroup_);
		TotalWarehouses_ = WarehouseTable.Count();
		WarehousesClientServer.UpdateWarehouseGroupImage(
			SeveralWarehousesText, Items.PictureMultipleWarehouses, TotalWarehouses_);
		
	EndIf;
	
	CalculateOrderTotals(ThisObject);
	
EndProcedure

&AtClient
Procedure ManufacturedProductSeriesStartChoice(Item, ChoiceData, StandardProcessing)
	StandardProcessing = False;
	OpenSelectionOfSeries("ManufacturedProduct",, Item.EditText);
EndProcedure

&AtClient
Procedure ManufacturedProductSeriesOnChange(Item)
	
	ValueSelected = ProductsClientServer.SelectedSeries();
	
	ValueSelected.Value            		 = Items.ManufacturedProduct.CurrentData.Series;
	ValueSelected.CurrentRowID = Items.ManufacturedProduct.CurrentData.GetID();
	
	ProductsClient.ProcessSeriesIndication(ThisObject, SeriesSpecificationParameters.ManufacturedProduct, ValueSelected);

EndProcedure

&AtClient
Procedure ManufacturedProductProductsOnChange(Item)
	
	ManufacturedProductProductsOnChangeServer(CachedValues);
	UpdateSpecificationSelectionList(Items, Object.ManufacturedProduct);
	
	ProvisionInDocumentsClientServer.FillInServiceDetails(Object.ManufacturedProduct, DateOfShipmentRequired_, WarehouseIsRequired);
	CalculateOrderTotals(ThisObject);
	
EndProcedure

&AtClient
Procedure ManufacturedProductCharacteristicOnChange(Item)
	
	CurrentRow = Items.ManufacturedProduct.CurrentData;
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert(
		"FillInSalePrice",
		BatchProcessingOfTablePartClientServer.ParametersForFillingInPriceInTSLine(Object));
	StructureOfActions.Insert("RecalculateAmount");
	StructureOfActions.Insert("RecalculateVATAmount",  StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("FillInDuplicateDependentDetails", DependentDetails("ManufacturedProduct"));
	StructureOfActions.Insert(
		"FillInContent",
		BatchProcessingOfTablePartClientServer.GetStructureOfFillingInServiceContentInTSLine(Object, False));
	
	AddCollateralActionsOnClient(
		StructureOfActions,
		"SupplyOption,AvailableInOtherLines,WarehouseIsRequired,DateOfShipmentRequired_");
	
	StructureOfSpecificationFilling = 
		ProductDataManagementClientServer.ActionParametersCheckFillSpecification(
			Object, CurrentRow, BOMSelectionParameters);
	StructureOfActions.Insert("CheckFillSpecification", StructureOfSpecificationFilling);
	
	AddActionsClearFillArticleAnalytics(StructureOfActions, ThisObject);
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
	If ProvisionInDocumentsClient.YouNeedToUpdateAvailableColumn(StructureOfActions) Then
		UpdateColumnAvailableServer();
	EndIf;
	
	ProvisionInDocumentsClientServer.FillInServiceDetails(Object.ManufacturedProduct, DateOfShipmentRequired_, WarehouseIsRequired);
	
	CalculateOrderTotals(ThisObject);
	
	UpdateSpecificationSelectionList(Items, Object.ManufacturedProduct);
	
EndProcedure

&AtClient
Procedure ManufacturedProductPackageOnChange(Item)
	
	CurrentRow = Items.ManufacturedProduct.CurrentData;
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	
	StructureOfActions = New Structure;
	
	If CurrentRow.Count > 0 Then
		
		StructureOfActions.Insert("RecalculatePricePerPackage", CurrentRow.Count);
		
	ElsIf ValueIsFilled(CurrentRow.PriceKind) Then
		
		StructureOfActions.Insert(
			"FillInSalePrice", BatchProcessingOfTablePartClientServer.ParametersForFillingInPriceInTSLine(Object));
			
	EndIf;
	
	StructureOfActions.Insert(
		"RecalculateNumberOfUnits", ProductionClientServer.ParametersForRecalculatingNumberOfUnits());
	StructureOfActions.Insert("RecalculateAmount");
	StructureOfActions.Insert("RecalculateVATAmount",  StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("FillInDuplicateDependentDetails", DependentDetails("ManufacturedProduct"));
	
	AddCollateralActionsOnClient(StructureOfActions, "AvailableInOtherLines");
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
	If ProvisionInDocumentsClient.YouNeedToUpdateAvailableColumn(StructureOfActions) Then
		UpdateColumnAvailableServer();
	EndIf;
	
	CalculateOrderTotals(ThisObject);
	
EndProcedure

&AtClient
Procedure ManufacturedProductNumberOfPackagesOnChange(Item)
	
	CurrentRow = Items.ManufacturedProduct.CurrentData;
	
	StructureOfActions = New Structure;
	AddActionsToStructureWhenChangingNumberOfProductPackages(StructureOfActions, Object);
	AddCollateralActionsOnClient(StructureOfActions, "AvailableInOtherLines");
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
	If ProvisionInDocumentsClient.YouNeedToUpdateAvailableColumn(StructureOfActions) Then
		UpdateColumnAvailableServer();
	EndIf;
	
	CalculateOrderTotals(ThisObject);
	
EndProcedure

&AtClient
Procedure ManufacturedProductPriceKindOnChange(Item)
	
	CurrentRow = Items.ManufacturedProduct.CurrentData;
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert(
		"FillInSalePrice", BatchProcessingOfTablePartClientServer.ParametersForFillingInPriceInTSLine(Object));
	StructureOfActions.Insert("RecalculateAmount");
	StructureOfActions.Insert("RecalculateVATAmount",  StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("FillInDuplicateDependentDetails", DependentDetails("ManufacturedProduct"));
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
	CalculateOrderTotals(ThisObject);
	
EndProcedure

&AtClient
Procedure ManufacturedProductPriceOnChange(Item)
	
	CurrentRow = Items.ManufacturedProduct.CurrentData;
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateAmount");
	StructureOfActions.Insert("RecalculateVATAmount",  StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("FillInDuplicateDependentDetails", DependentDetails("ManufacturedProduct"));
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
	CalculateOrderTotals(ThisObject);
	
EndProcedure

&AtClient
Procedure ManufacturedProductSumOnChange(Item)
	
	CurrentRow = Items.ManufacturedProduct.CurrentData;
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculatePriceByAmount");
	StructureOfActions.Insert("RecalculateVATAmount",  StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("FillInDuplicateDependentDetails", DependentDetails("ManufacturedProduct"));
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
	CalculateOrderTotals(ThisObject);
	
EndProcedure

&AtClient
Procedure ManufacturedProductVATRateStartChoice(Item, ChoiceData, ChoiceByAdding, StandardProcessing)
	
	DateOfShipment = Object.Date;
	
	If Object.NotShipInInstallments Then
		If ValueIsFilled(Object.DateOfShipment) Then
			DateOfShipment = Object.DateOfShipment;
		EndIf;
	Else
		CurrentData = Items.ManufacturedProduct.CurrentData;
		If ValueIsFilled(CurrentData.DateOfShipment) Then
			DateOfShipment = CurrentData.DateOfShipment;
		EndIf;
	EndIf;
	
	DateSelectionParameter = New ChoiceParameter("Date", DateOfShipment);
	VATRateSelectionParameters = New Array;
	VATRateSelectionParameters.Add(DateSelectionParameter);
	Item.ChoiceParameters = New FixedArray(VATRateSelectionParameters);
	
EndProcedure

&AtClient
Procedure ManufacturedProductVATRateOnChange(Item)
	
	CurrentRow = Items.ManufacturedProduct.CurrentData;
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateVATAmount",  StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("FillInDuplicateDependentDetails", DependentDetails("ManufacturedProduct"));
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
	CalculateOrderTotals(ThisObject);
	
EndProcedure

&AtClient
Procedure ManufacturedProductVATAmountOnChange(Item)
	
	CurrentRow = Items.ManufacturedProduct.CurrentData;
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("FillInDuplicateDependentDetails", DependentDetails("ManufacturedProduct"));
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
	CalculateOrderTotals(ThisObject);
	
EndProcedure

&AtClient
Procedure ManufacturedProductCanceledOnChange(Item)
	
	CurrentRow = Items.ManufacturedProduct.CurrentData;
	
	If Not CurrentRow.Canceled Then
		CurrentRow.CancellationReason = PredefinedValue("Catalog.ReasonsForSaleOrderCancellation.EmptyRef");
	EndIf;
	
	StructureOfActions = New Structure;
	
	StructureOfActions.Insert("FillInDuplicateDependentDetails", DependentDetails("ManufacturedProduct"));
	StructureOfActions.Insert(
		"CheckSeriesCalculateStatus",
		New Structure("Warehouse, SeriesSpecificationParameters", CurrentRow.Warehouse, SeriesSpecificationParameters.ManufacturedProduct));
	
	AddCollateralActionsOnClient(
		StructureOfActions,
		"AvailableInOtherLines,WarehouseIsRequired,DateOfShipmentRequired_");
	
	If Not CurrentRow.Canceled Then
		
		StructureOfSpecificationFilling =
			ProductDataManagementClientServer.ActionParametersCheckFillSpecification(
					Object, CurrentRow, BOMSelectionParameters);
		
		StructureOfActions.Insert("CheckFillSpecification", StructureOfSpecificationFilling);
		
	EndIf;
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
	If ProvisionInDocumentsClient.YouNeedToUpdateAvailableColumn(StructureOfActions) Then
		UpdateColumnAvailableServer();
	EndIf;
	
	ProvisionInDocumentsClientServer.FillInServiceDetails(Object.ManufacturedProduct, DateOfShipmentRequired_, WarehouseIsRequired);
	
	If CurrentRow.Canceled Then
		
		MaterialCommunicationKeys = New Map;
		MaterialCommunicationKeys.Insert(CurrentRow.BillOfMaterials, CurrentRow.CancellationReason);
		
		CancelRelatedContent(MaterialCommunicationKeys);
		
	EndIf;
	
	CalculateOrderTotals(ThisObject);
	
	UpdateSelectionOfRowsByCanceled(Items, "ManufacturedProduct", HideCanceledProductLines, False);
	
	If ARAPAccountingClient.ThereIsChangeInShippingDates(ThisObject) Then
		ManufacturedProductsCancelledOnChangeAtServer();
	EndIf;
	
EndProcedure

&AtClient
Procedure ManufacturedProductWarehouseOnChange(Item)
	
	ManufacturedProductWarehouseOnChangeServer(Items.ManufacturedProduct.CurrentRow);
	
EndProcedure

&AtClient
Procedure ManufacturedProductDepartmentOnChange(Item)
	
	UpdateColumnAvailableServer();
	
EndProcedure

&AtClient
Procedure ManufacturedProductDateOfShipmentOnChange(Item)
	
	CurrentRow = Items.ManufacturedProduct.CurrentData;
	
	StructureOfActions = New Structure;
	If VATRateIsIndicatedInTablePart(Object.BusinessOperation) Then
		AddActionToStructureFillInVATRate(Object, StructureOfActions);
	EndIf;
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	StructureOfActions.Insert("RecalculateVATAmount",                   StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT",                  StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("FillInDuplicateDependentDetails", DependentDetails("ManufacturedProduct"));
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
	CalculateOrderTotals(ThisObject);
	
EndProcedure

&AtClient
Procedure ManufacturedProductBillOfMaterialsOnChange(Item)
	
	UpdateSpecificationSelectionList(Items, Object.ManufacturedProduct);
	
EndProcedure

&AtClient
Procedure ManufacturedProductSupplyOptionChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	ProvisionInDocumentsClient.SupplyOptionChoiceProcessing(
		ThisObject,
		Items.ManufacturedProduct.CurrentData,
		ValueSelected);
	
EndProcedure

&AtClient
Procedure ManufacturedProductSupplyOptionOnChange(Item)
	
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
		"ProductionCollateralOptionWhenChangedAfterIssue");
	
EndProcedure

&AtClient
Procedure ManufacturedProductSupplyOptionClearing(Item, StandardProcessing)
	
	StandardProcessing = False;
	
EndProcedure

&AtClient
Procedure ManufacturedProductWarehouseStartChoice(Item, ChoiceData, StandardProcessing)
	
	FormParameters = ParametersOfQuantityAndSeriesRequestForm(ProvisionInDocumentsClientServer.WarehouseSelectionMode());
	
	If TypeOf(FormParameters) = Type("Structure") Then
		
		StandardProcessing = False;
		OpenForm(
			"DataProcessor.QuantityAndBatchRequest.Form",
			FormParameters,
			ThisObject,,,,
			New CallbackDescription("ProcessWarehouseAndBatchSelection", ThisObject, FormParameters));
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ManufacturedProductToExpenseAsOnChange(Item)
	
	CurrentData = Items.ManufacturedProduct.CurrentData;
	
	IncomeAndExpensesClientServer.WhenChangingArticleAvailabilityDetailsInLine(
		ThisObject, CurrentData, "Object.ManufacturedProduct");
	
	GLAccountSettingsClientServer.WhenChangingAccountAvailabilityDetailsInLine(
		ThisObject, CurrentData, "Object.ManufacturedProduct");
	
EndProcedure

&AtClient
Procedure ManufacturedProductExpenseItemStartChoice(Item, ChoiceData, StandardProcessing)
	
	IncomeAndExpensesClient.StartArticleSelection(ThisObject, Item, StandardProcessing);
	
EndProcedure

&AtClient
Procedure ManufacturedProductExpenseItemOnChange(Item)
	
	IncomeAndExpensesClientServer.AssetRefOnChange(ThisObject, Item);
	
EndProcedure

&AtClient
Procedure ManufacturedProductDimensionOfExpensesAutoComplete(Item, Text, ChoiceData, DataGetParameters, Waiting, StandardProcessing)
	
	IncomeAndExpensesClient.AutoSelectionOfExpenseAnalytics(
		ThisObject, Item, Text, ChoiceData, DataGetParameters, StandardProcessing);
	
EndProcedure

&AtClient
Procedure ManufacturedProductDimensionOfExpensesTextEditEnd(Item, Text, ChoiceData, DataGetParameters, StandardProcessing)
	
	IncomeAndExpensesClient.EndOfCostAnalyticsTextEntry(
		ThisObject, Item, Text, ChoiceData, DataGetParameters, StandardProcessing);
	
EndProcedure

&AtClient
Procedure ManufacturedProductDimensionOfExpensesStartChoice(Item, ChoiceData, StandardProcessing)
	
	IncomeAndExpensesClient.StartSelectingExpenseAnalytics(ThisObject, Item, StandardProcessing);
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersUsedMaterials

&AtClient
Procedure UsedMaterialsSelection(Item, RowSelected, Field, StandardProcessing)
	
	PartnersProductsClient.WhenSelectingPartnerProducts(
		Object, Field, "UsedMaterialsPartnerProducts", NStr("vi = 'Người đặt gia công';
															|ru = 'Давалец';
															|en = 'Material provider'; fa = 'تأمین‌کننده مواد';
															|it = 'Fornitore';
															|pl = 'Material provider';
															|tr = 'Malzeme tedarikçisi'"));
	
EndProcedure

&AtClient
Procedure UsedMaterialsBeforeDeleteRow(Item, Cancel)
	
	ProcessingOfTabularFormsClient.CacheCurLine(Items.UsedMaterials, ThisObject);
	
EndProcedure

&AtClient
Procedure UsedMaterialsAfterDeleteRow(Item)
	
	WarehousesClient.UpdateWarehouseTable(
		ReceivingWarehousesTable,
		Undefined,
		ProcessingOfTabularFormsClientServer.LineCache(Items.UsedMaterials, ThisObject),
		ReceivingWarehouseGroup);
		
	TotalWarehouses_ = ReceivingWarehousesTable.Count();
	WarehousesClientServer.UpdateWarehouseGroupImage(
		LabelMultipleWarehousesReceipts, Items.ThePictureOfTheWarehouseReceipt, TotalWarehouses_);
	
	ReusablePackageClient.UpdateFillingStateOfMultiTurnContainer(
		Object.ReusablePackageFillingStatus);
	
	CalculateOrderTotals(ThisObject);
	
EndProcedure

&AtClient
Procedure UsedMaterialsOnStartEdit(Item, NewRow, Copy)
	
	ProcessingOfTabularFormsClient.CacheCurLine(Items.UsedMaterials, ThisObject);
	
	CurrentData = Items.UsedMaterials.CurrentData;
	
	If NewRow Then
		
		CurrentData.RowCode = 0;
		If Object.OneDateReceipt Then
			CurrentData.DateOfReceipt = Object.DateOfReceipt;
		EndIf;
		
		StructureOfActions = New Structure;
		StructureOfActions.Insert("CheckFillAssignment", Object.AssignmentMaterials);
		StructureOfActions.Insert("FillInActionForRecyclableMaterials");
		
		BatchProcessingOfTablePartClient.ProcessTSString(CurrentData, StructureOfActions, CachedValues);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure UsedMaterialsBeforeEditEnd(Item, NewRow, CancelEdit, Cancel)
	
	If NewRow
		And CancelEdit Then
		Return;
	EndIf;
	
	CurrentData = Items.UsedMaterials.CurrentData;
	
	If CurrentData <> Undefined And Object.OneDateReceipt Then
		CurrentData.DateOfReceipt = Object.DateOfReceipt;
	EndIf;
	
	If Not CancelEdit Then
		
		LineCache =
			?(NewRow, Undefined, ProcessingOfTabularFormsClientServer.LineCache(Items.UsedMaterials, ThisObject));
			
		WarehousesClient.UpdateWarehouseTable(ReceivingWarehousesTable, CurrentData, LineCache, ReceivingWarehouseGroup);
		
		TotalWarehouses_ = ReceivingWarehousesTable.Count();
		WarehousesClientServer.UpdateWarehouseGroupImage(LabelMultipleWarehousesReceipts,
			Items.ThePictureOfTheWarehouseReceipt, TotalWarehouses_);
			
	EndIf;
	
	ReusablePackageClient.UpdateFillingStateOfMultiTurnContainer(
		Object.ReusablePackageFillingStatus);
	
	CalculateOrderTotals(ThisObject);
	
EndProcedure

&AtClient
Procedure UsedMaterialsOnActivateCell(Item)
	
	If Item.CurrentItem = Undefined Then
		Return
	ElsIf Item.CurrentItem.Name = "UsedMaterialsPartnerProducts" Then
		PartnersProductsClient.FillInPartnerProductSelectionList(
			Object.Partner, Items.UsedMaterials.CurrentData, Items.UsedMaterialsPartnerProducts.ChoiceList);
	EndIf;
	
EndProcedure

&AtClient
Procedure MaterialsPartnerSItemListOnChange(Item)
	
	CurrentRow = Items.UsedMaterials.CurrentData;
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("CheckCharacteristicsByOwner", CurrentRow.Characteristic);
	StructureOfActions.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));
	StructureOfActions.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
	StructureOfActions.Insert("CheckFillPackageByOwner", CurrentRow.Package);
	StructureOfActions.Insert("FillInTheItemByThePartnerSItem");
	
	StructureOfActions.Insert("CheckFillWarehouse", ParametersForFillingWarehouseInLine("UsedMaterials"));
	
	StructureOfActions.Insert(
		"CheckSeriesCalculateStatus",
		New Structure("Warehouse, SeriesSpecificationParameters", CurrentRow.Warehouse, SeriesSpecificationParameters.UsedMaterials));
	
	StructureOfActions.Insert(
		"FillInPurchasePrice",
		BatchProcessingOfTablePartClientServer.GetStructureForFillingInPurchasePriceInTSLine(
			Object, "PriceTypeMaterials"));
	
	StructureOfActions.Insert(
		"ProductsOnChangeOverridable",
		New Structure("FormName, TabularSectionName", FormName, "UsedMaterials"));
	
	StructureOfActions.Insert(
		"RecalculateNumberOfUnits", ProductionClientServer.ParametersForRecalculatingNumberOfUnits());
	StructureOfActions.Insert("RecalculateAmount");
	
	StructureOfActions.Insert("FillInDuplicateDependentDetails", DependentDetails("UsedMaterials"));
		
	ProductListMaterialsWhenChanged(CurrentRow.GetID(), StructureOfActions, CachedValues);
	
	CalculateOrderTotals(ThisObject);
	
EndProcedure

&AtClient
Procedure UsedMaterialsProductsOnChange(Item)
	
	CurrentRow = Items.UsedMaterials.CurrentData;
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert(
		"RecalculateNumberOfUnits", ProductionClientServer.ParametersForRecalculatingNumberOfUnits());
	StructureOfActions.Insert("CheckFillWarehouse", 				ParametersForFillingWarehouseInLine("UsedMaterials"));
	StructureOfActions.Insert("FillInArticleAttribute", 				New Structure("Products", "SKU"));
	StructureOfActions.Insert("FillInProductTypeAttribute_", 		New Structure("Products", "ItemsType"));
	StructureOfActions.Insert("CheckFillPackageByOwner", CurrentRow.Package);
	StructureOfActions.Insert("CheckCharacteristicsByOwner", 	CurrentRow.Characteristic);
	StructureOfActions.Insert("FillInProductNameOfProductPartner", Object.Partner);
	StructureOfActions.Insert("RecalculateAmount");
	StructureOfActions.Insert("CheckFillAssignment", Object.AssignmentMaterials);
	AddQualityControlActionsToStructure(StructureOfActions, CacheQualityControl);
	
	StructureOfActions.Insert(
		"CheckSeriesCalculateStatus",
		New Structure("Warehouse, SeriesSpecificationParameters", CurrentRow.Warehouse, SeriesSpecificationParameters.UsedMaterials));
	
	StructureOfActions.Insert(
		"FillInPurchasePrice",
		BatchProcessingOfTablePartClientServer.GetStructureForFillingInPurchasePriceInTSLine(
			Object, "PriceTypeMaterials"));
	
	StructureOfActions.Insert(
		"ProductsOnChangeOverridable",
		New Structure("FormName, TabularSectionName", FormName, "UsedMaterials"));
		
	StructureOfActions.Insert("FillInShopPantryAttribute");
	
	StructureOfActions.Insert("FillInDuplicateDependentDetails", DependentDetails("UsedMaterials"));
	
	ProductListMaterialsWhenChanged(CurrentRow.GetID(), StructureOfActions, CachedValues);
	
	CalculateOrderTotals(ThisObject);

EndProcedure

&AtClient
Procedure UsedMaterialsCharacteristicOnChange(Item)
	
	CurrentRow = Items.UsedMaterials.CurrentData;
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateAmount");
	StructureOfActions.Insert(
		"CharacteristicOnChangeOverridable",
		New Structure("FormName, TabularSectionName", FormName, "UsedMaterials"));
	StructureOfActions.Insert("FillInProductNameOfProductPartner", Object.Partner);
	
	StructureOfActions.Insert(
		"FillInPurchasePrice",
		BatchProcessingOfTablePartClientServer.GetStructureForFillingInPurchasePriceInTSLine(
			Object, "PriceTypeMaterials"));
		
	StructureOfActions.Insert("FillInDuplicateDependentDetails", DependentDetails("UsedMaterials"));
		
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
	CalculateOrderTotals(ThisObject);
	
EndProcedure

&AtClient
Procedure UsedMaterialsPackageOnChange(Item)
	
	CurrentRow = Items.UsedMaterials.CurrentData;
	
	StructureOfActions = New Structure;
	
	If CurrentRow.Count > 0 Then
		
		StructureOfActions.Insert("RecalculatePricePerPackage", CurrentRow.Count);
		
	Else
		
		StructureOfActions.Insert(
			"FillInPurchasePrice",
			BatchProcessingOfTablePartClientServer.GetStructureForFillingInPurchasePriceInTSLine(
				Object, "PriceTypeMaterials"));
		
	EndIf;
	
	StructureOfActions.Insert(
		"RecalculateNumberOfUnits", ProductionClientServer.ParametersForRecalculatingNumberOfUnits());
	StructureOfActions.Insert("RecalculateAmount");
	
	StructureOfActions.Insert("FillInProductNameOfProductPartner", Object.Partner);
	
	StructureOfActions.Insert("FillInDuplicateDependentDetails", DependentDetails("UsedMaterials"));
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
	CalculateOrderTotals(ThisObject);
	
EndProcedure

&AtClient
Procedure UsedMaterialsWarehouseOnChange(Item)

	CurrentRow = Items.UsedMaterials.CurrentData;

	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInShopPantryAttribute");
	StructureOfActions.Insert(
		"RecalculateNumberOfUnits", ProductionClientServer.ParametersForRecalculatingNumberOfUnits());
	AddQualityControlActionsToStructure(StructureOfActions, CacheQualityControl);
	
	ValuesInCache = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, ValuesInCache);
	
EndProcedure

&AtClient
Procedure UsedMaterialsNumberOfPackagesOnChange(Item)
	
	CurrentRow = Items.UsedMaterials.CurrentData;
	
	StructureOfActions = New Structure;
	AddActionsToStructureWhenChangingNumberOfPackagesOfMaterials(StructureOfActions);
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
	CalculateOrderTotals(ThisObject);
	
EndProcedure

&AtClient
Procedure UsedMaterialsPriceOnChange(Item)
	
	CurrentRow = Items.UsedMaterials.CurrentData;
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateAmount");
	StructureOfActions.Insert("FillInDuplicateDependentDetails", DependentDetails("UsedMaterials"));
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
	CalculateOrderTotals(ThisObject);
	
EndProcedure

&AtClient
Procedure UsedMaterialsSumOnChange(Item)
	
	CurrentRow = Items.UsedMaterials.CurrentData;
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculatePriceByAmount", "NumberOfPackages");
	StructureOfActions.Insert("FillInDuplicateDependentDetails", DependentDetails("UsedMaterials"));
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
	CalculateOrderTotals(ThisObject);
	
EndProcedure

&AtClient
Procedure UsedMaterialsPurposeClearing(Item, StandardProcessing)
	
	StandardProcessing = False;
	
EndProcedure

&AtClient
Procedure UsedMaterialsPurposeTextEditEnd(Item, Text, ChoiceData, DataGetParameters, StandardProcessing)
	
	If Text = "" Then
		StandardProcessing = False;
	EndIf;
	
EndProcedure

&AtClient
Procedure UsedMaterialsSeriesStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	OpenSelectionOfSeries("UsedMaterials",, Item.EditText);
	
EndProcedure

&AtClient
Procedure MaterialsActionOnChange(Item)
	
	CurrentRow = Items.UsedMaterials.CurrentData;
	
	MaterialsWhenChangingActionInLine(ThisObject, CurrentRow);
	
	StructureOfActions = New Structure;
	AddActionsToStructureWhenYouChangeActionInContentLine(ThisObject, CurrentRow, StructureOfActions);
	AddQualityControlActionsToStructure(StructureOfActions, CacheQualityControl);
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
EndProcedure

&AtClient
Procedure UsedMaterialsDateOfReceiptOnChange(Item)
	
	CurrentRow = Items.UsedMaterials.CurrentData;

	StructureOfActions = New Structure;
	AddQualityControlActionsToStructure(StructureOfActions, CacheQualityControl);
	
	ValuesInCache = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, ValuesInCache);
	
EndProcedure

&AtClient
Procedure UsedMaterialsCanceledOnChange(Item)
	
	CurrentRow = Items.UsedMaterials.CurrentData;
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInDuplicateDependentDetails", DependentDetails("UsedMaterials"));
	StructureOfActions.Insert(
		"CheckSeriesCalculateStatus",
		New Structure("Warehouse, SeriesSpecificationParameters", CurrentRow.Warehouse, SeriesSpecificationParameters.UsedMaterials));
	AddQualityControlActionsToStructure(StructureOfActions, CacheQualityControl);
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
	CalculateOrderTotals(ThisObject);
	
	UpdateSelectionOfRowsByCanceled(Items, "UsedMaterials", HideCanceledLinesMaterials, False);
	
EndProcedure

&AtClient
Procedure UsedMaterialsToControlQualityOnChange(Item)
	
	CurrentData = Items.UsedMaterials.CurrentData;
	If Not CurrentData.ToControlQuality Then
		CurrentData.QualityConfirmationDate = '00010101';
	EndIf;
	
EndProcedure

&AtClient
Procedure UsedMaterialsQualityConfirmationDateOnChange(Item)
	
	CurrentData = Items.UsedMaterials.CurrentData;
	If Not CurrentData.ToControlQuality Then
		CurrentData.QualityConfirmationDate = '00010101';
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure WriteDocument(Command)
	
	TMCommonUseClient.Write(ThisObject, True);
	
EndProcedure

&AtClient
Procedure SetDeletionMarkForADocument(Command)
	
	TMCommonUseClient.SetDeletionMarkForADocument(ThisObject);
	
EndProcedure

&AtClient
Procedure PostDocument(Command)
	
	TMCommonUseClient.Post(ThisObject, True);
	
EndProcedure

&AtClient
Procedure PostAndClose(Command)
	
	TMCommonUseClient.PostAndClose(ThisObject, True);
	
EndProcedure

#Region Header

&AtClient
Procedure CloseOrder(Command)
	
	If Modified Or Not Object.Posted Then
		
		ShowQueryBox(
			New CallbackDescription("CloseOrderCompletion", ThisObject),
			NStr("vi = 'Cần kết chuyển chứng từ để thực hiện giao dịch. Kết chuyển chứng từ?';
				|ru = 'Необходимо провести документ для выполнения операции. Провести документ?';
				|en = 'To proceed, you need to post the document. Do you want to post the document?'; fa = 'To proceed, you need to post the document. Do you want to post the document?';
				|it = 'È necessario pubblicare il documento per eseguire operazione. pubblicare documento?';
				|pl = 'Należy zaksięgować dokument aby wykonać operację. Zaksięgować dokument?';
				|tr = 'Bir işlemin gerçekleştirilmesi için belgenin düzenlenmesi gerekir. Belge düzenlensin mi?'"),
			QuestionDialogMode.YesNo);
		
		Return;
		
	EndIf;
	
	CloseOrderFragment();
	
EndProcedure

&AtClient
Procedure PaymentSettlement(Command)
	ARAPAccountingClient.PaymentSettlement(ThisObject, Items.CreditPaymentForm);
EndProcedure

&AtClient
Procedure PrintDetails(Command)
	
	ParametersStructure = New Structure();
	ParametersStructure.Insert("DeliveryAddress",                  Object.DeliveryAddress);
	ParametersStructure.Insert("ShipperBankAccount", Object.ShipperBankAccount);
	ParametersStructure.Insert("GoodsRecipientBankAccount",  Object.GoodsRecipientBankAccount);
	ParametersStructure.Insert("CounterpartyBankAccount",      Object.CounterpartyBankAccount);
	ParametersStructure.Insert("Shipper",               Object.Shipper);
	ParametersStructure.Insert("GoodsRecipient",                Object.GoodsRecipient);
	ParametersStructure.Insert("Partner",                        Object.Partner);
	ParametersStructure.Insert("AdditionalInformation",       Object.AdditionalInformation);
	ParametersStructure.Insert("BusinessOperation",          Object.BusinessOperation);
	ParametersStructure.Insert("Counterparty",                     Object.Counterparty);
	ParametersStructure.Insert("Organization",                    Object.Organization);
	ParametersStructure.Insert("BankAccount",                 Object.BankAccount);
	ParametersStructure.Insert("Date",                           Object.Date);
	ParametersStructure.Insert("Director",                   Object.Director);
	ParametersStructure.Insert("ChiefAccountant",               Object.ChiefAccountant);
	ParametersStructure.Insert("PaymentPurposes",              Object.PaymentPurposes);
	ParametersStructure.Insert("OrderNumber",                    ObjectsPrefixesClientServer.NumberForPrinting(Object.Number));
	ParametersStructure.Insert("OrderDate",                     Format(Object.Date, "DLF=D"));
	ParametersStructure.Insert("AttributeSelectionParameters",      AttributeSelectionParameters);
	
	OpenForm(
		"Document.MaterialProviderOrder2_5.Form.PrintDetails",
		ParametersStructure, ThisObject,,,,
		Undefined,
		FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure TextShippingToAPartnerIsProhibitedClick(Item)
	
	OpenForm("Catalog.Partners.Form.FormOfSegmentsOfShipmentProhibition", New Structure("Partner", Object.Partner));
	
EndProcedure

&AtClient
Procedure TextAllowedCreditBalanceClick(Item, StandardProcessing)
	
	ARAPAccountingClient.DebtLimitsClick(ThisObject, Item, StandardProcessing);
	
EndProcedure

&AtClient
Procedure SupplementDeliveryInformationWithContacts(Command)
	
	SupplementDeliveryInformationWithContactsServer();
	
EndProcedure

#EndRegion

#Region ManufacturedProduct

&AtClient
Procedure ProductsFillInTheShipmentDate(Command)
	
	If Items.ManufacturedProduct.SelectedRows.Count() > 0 Then
		FillInShipmentDate(Items.ManufacturedProduct.SelectedRows);
	EndIf;
	
EndProcedure

&AtClient
Procedure ManufacturedProductFillInTheWarehouse(Command)
	
	SelectedRows = Items.ManufacturedProduct.SelectedRows;
	RequiredFilling_ = WarehousesClient.CheckPossibilityOfFillingWarehousesInTablePart(
		Object,
		Object.ManufacturedProduct,
		NStr("vi = 'Thành phẩm';
			|ru = 'Выпускаемая продукция';
			|en = 'Released products'; fa = 'محصولات تولیدشده';
			|it = 'Prodotti in fabbricazione';
			|pl = 'Wypuszczana produkcja';
			|tr = 'İmal edilen ürünler'"),
		SelectedRows);
	
	If RequiredFilling_ Then
		
		FilterArray = New Array();
		FilterArray.Add(PredefinedValue("Enum.SelectWarehouseGroup.AllowInOrders"));
		FilterArray.Add(PredefinedValue("Enum.SelectWarehouseGroup.AllowInOrdersAndInvoices"));
		
		FilterStructure1     = New Structure("SelectGroup, IsFolder", FilterArray, False);
		ParametersStructure = New Structure("Filter,GroupOfWarehouses", FilterStructure1, Object.Warehouse);
		
		OpenForm(
			"Catalog.Warehouses.ChoiceForm",
			 ParametersStructure,
			 ThisObject,,,,
			 New CallbackDescription(
			 	"ManufacturedProductFillInTheWarehouseCompletion", ThisObject, New Structure("SelectedRows", SelectedRows)),
			 FormWindowOpeningMode.LockOwnerWindow);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ProductsFillDivision(Command)
	
	WarehousesClient.FillInDivisionInTablePart(
		Object,
		ThisObject,
		Object.ManufacturedProduct,
		"ManufacturedProduct",
		Items.ManufacturedProduct.SelectedRows,
		New CallbackDescription("ProductsFillDivisionCompletion", ThisObject));
	
EndProcedure

&AtClient
Procedure ManufacturedProductFillInRecipient(Command)
	
	SelectedRows = Items.ManufacturedProduct.SelectedRows;
	
	If SelectedRows.Count() = 0 Then
		ShowMessageBox(, NStr("vi = 'Trong danh sách ""Sản phẩm xuất xưởng"" chưa nhập bất kỳ dòng nào.';
								|ru = 'В список ""Выпущенная продукция"" не введено ни одной строки.';
								|en = 'No lines are entered in the ""Released products"" list.'; fa = 'No lines are entered in the ""Released products"" list.';
								|it = 'Nell''elenco ""Prodotti emessi"" non è inserita alcuna stringa.';
								|pl = 'Do listy ""Wyprodukowana produkcja"" nie wprowadzono ani jednego wiersza.';
								|tr = '""Piyasaya sürülen imal edilen ürünler"" listesine hiçbir satır girilmemiştir.'"), 45);
		Return;
	EndIf;
	
	TSStrings = New Array;
	For Each RowID In SelectedRows Do
		
		CurrentRow = Object.ManufacturedProduct.FindByID(RowID);
		If Not CurrentRow.ToExpenseAs Then
			Continue;
		EndIf;
		
		TSStrings.Add(CurrentRow);
		
	EndDo;
	
	If TSStrings.Count() = 0 Then
		ShowMessageBox(
			,
			NStr("vi = 'Tại các dòng đã chọn trong danh sách ""Sản phẩm xuất xưởng"" không cần điền bộ phận-nơi nhận.';
				|ru = 'В выделенных строках списка ""Выпущенная продукция"" заполнение получателя не требуется.';
				|en = 'You do not need to fill the recipient in the selected lines of the ""Released products"" list.'; fa = 'You do not need to fill the recipient in the selected lines of the ""Released products"" list.';
				|it = 'Nelle stringhe selezionate dell''elenco ""Prodotti emessi"" non è richiesta la compilazione del destinatario.';
				|pl = 'W zaznaczonych wierszach listy ""Wyprodukowana produkcja"" wypełnienie działów-odbiorców nie jest wymagane.';
				|tr = '""Piyasaya sürülen imal edilen ürünler"" listesinin seçili satırlarında alıcı birimin doldurulmasına gerek yoktur.'"),
			45);
		Return;
	EndIf;
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("TSStrings", TSStrings);
	
	OpenForm(
		"Catalog.BusinessStructure.ChoiceForm",,
		ThisObject,,,,
		New CallbackDescription("ManufacturedProductFillInRecipientCompletion", ThisObject, AdditionalParameters),
		FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure ManufacturedProductFillInPricesByPriceKind(Command)
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.TimeMeasurement(
		"Document.MaterialProviderOrder2_5.DocumentForm.Command.ProductsFillInFillInPricesByPriceType");
	
	If Items.ManufacturedProduct.SelectedRows.Count() = 0 Then
		
		ClearMessages();
		
		CommonClient.MessageToUser(
			NStr("vi = 'Không có dòng được chọn trong bảng. Chọn dòng để điền giá';
				|ru = 'В таблице отсутствуют выделенные строки. Выделите строки для заполнения цен';
				|en = 'No selected rows in the table. Select rows to fill in the prices'; fa = 'No selected rows in the table. Select rows to fill in the prices';
				|it = 'Non ci sono righe selezionate nella tabella. Selezionare le righe per compilare i prezzi';
				|pl = 'Brak wydzielonych wierszy w tabeli. Zaznacz wiersze do wypełnienia cen';
				|tr = 'Tabloda seçili satırlar mevcut değil. Fiyatları doldurmak için satırları seçin.'"),
			Object.Ref,
			"Object.ManufacturedProduct");
		
		Return;
		
	EndIf;
	
	If EnterprisePricesFillingClient.ItIsNecessaryToFillInPricesByTypeOfPrices(Object, "ManufacturedProduct", NStr("vi = 'Thành phẩm';
																													|ru = 'Выпускаемая продукция';
																													|en = 'Released products'; fa = 'محصولات تولیدشده';
																													|it = 'Prodotti in fabbricazione';
																													|pl = 'Wypuszczane wiersze pozycji';
																													|tr = 'İmal edilen ürünler'")) Then
		
		PriceSelectionOptions = EnterprisePricesFillingClient.NewFillOptionsSelectPriceType();
		PriceSelectionOptions.CallbackDescription = 
			New CallbackDescription("ManufacturedProductFillInPricesByPriceKindCompletion", ThisObject);
		PriceSelectionOptions.PriceIncludesVAT = Object.PriceIncludesVAT;
		PriceSelectionOptions.UseWhileTransferringProductsToMaterialProvider = True;
		EnterprisePricesFillingClient.ChooseTypeOfPrices(PriceSelectionOptions);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ManufacturedProductInsertRows(Command)
	
	NumberOfProductsBeforeInsertion = Object.ManufacturedProduct.Count();
	
	GetLinesFromClipboard("ManufacturedProduct");
	ProvisionInDocumentsClientServer.FillInServiceDetails(Object.ManufacturedProduct, DateOfShipmentRequired_, WarehouseIsRequired);
	
	NumberOfInserted = Object.ManufacturedProduct.Count() - NumberOfProductsBeforeInsertion;
	ProcessingOfTabularFormsClient.NotifyUserAboutInsertingRows(NumberOfInserted);
	
	SetKeysInProductLines(Items, Object);
	
EndProcedure

&AtClient
Procedure ManufacturedProductCopyRows(Command)
	
	If ProcessingOfTabularFormsClient.SelectedLineToExecuteCommand(Items.ManufacturedProduct) Then
		CopyLinesOnServer("ManufacturedProduct");
		ProcessingOfTabularFormsClient.NotifyUserAboutCopyingStrings(Items.ManufacturedProduct.SelectedRows.Count());
	EndIf;
	
EndProcedure

&AtClient
Procedure ManufacturedProductImportDataFromPDT(Command)
	
	ClearMessages();
	
	EquipmentManagerClient.StartDownloadingDataFromTSD(
		New CallbackDescription("ProductsDownloadFromTSDCompletion", ThisObject),
		UUID);
	
EndProcedure

&AtClient
Procedure ManufacturedProductSelectGoods(Command)
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.TimeMeasurement(
		"Document.MaterialProviderOrder2_5.DocumentForm.Command.ProductsCommonToPickUpTheGoods_3");
	
	PickUpProduct("ManufacturedProduct");
	
	SetKeysInProductLines(Items, Object);
	
EndProcedure

&AtClient
Procedure ManufacturedProductSearchByBarcode(Command)
	
	ClearMessages();
	Notification = New CallbackDescription("SearchByBarcodeCompletion", ThisObject);
	BarcodingOfItemsClient.ShowBarcodeInput(Notification);
	
EndProcedure

&AtClient
Procedure ManufacturedProductSplitRow(Command)
	
	FormTable  = Items.ManufacturedProduct;
	TableData = Object.ManufacturedProduct;
	
	Notification = New CallbackDescription("ManufacturedProductSplitRowCompletion", ThisObject);
	ProcessingOfTabularFormsClient.SplitRow(TableData, FormTable, Notification);
	
EndProcedure

&AtClient
Procedure ProductsCancelSelectedLines(Command)
	
	CancelSelectedLines("ManufacturedProduct", NStr("vi = 'Sản phẩm xuất xưởng';
													|ru = 'Выпускаемая продукция';
													|en = 'Released products'; fa = 'محصولات تولیدشده';
													|it = 'Prodotti in fabbricazione';
													|pl = 'Wypuszczane wiersze pozycji';
													|tr = 'İmal edilen ürünler'"));
	
EndProcedure

&AtClient
Procedure ProductsHideCanceledLines(Command)
	
	HideCanceledProductLines = Not HideCanceledProductLines;
	
	UpdateSelectionOfRowsByCanceled(Items, "ManufacturedProduct", HideCanceledProductLines);
	
EndProcedure

&AtClient
Procedure ProductsFillInTheMainSpecification_3(Command)
	
	CheckFillInBillOfMaterialsInManufacturingProductLines(Items.ManufacturedProduct.SelectedRows);
	
EndProcedure

#EndRegion

#Region UsedMaterials

&AtClient
Procedure MaterialsFillInTheDateOfReceipt(Command)
	
	If Items.UsedMaterials.SelectedRows.Count() > 0 Then
		FillInDateOfReceipt(Items.UsedMaterials.SelectedRows);
	Else
		WarningText =
			NStr("vi = 'Trong chứng từ chưa chọn dòng để điền. Ngày tiếp nhận sẽ không được điền.';
				|ru = 'В документе не выбраны строки для заполнения. Дата поступления не будет заполнена.';
				|en = 'No lines to fill are selected in the document. The date of receipt will not be filled.'; fa = 'No lines to fill are selected in the document. The date of receipt will not be filled.';
				|it = 'Nel documento non sono selezionate le righe per la compilazione. La data dell''arrivo non verrà compilata.';
				|pl = 'W dokumencie nie wybrano wiersza do wypełnienia. Data wpłaty nie będzie wypełniona.';
				|tr = 'Belgede doldurulacak herhangi bir satır seçilmemiştir. Teslim alım tarihi doldurulmayacaktır.'");
		ShowMessageBox(Undefined, WarningText);
	EndIf;
	
EndProcedure

&AtClient
Procedure MaterialsFillTheWarehouse(Command)
	
	SelectedRows = Items.UsedMaterials.SelectedRows;
	RequiredFilling_ = WarehousesClient.CheckPossibilityOfFillingWarehousesInTablePart(
		Object, Object.UsedMaterials, NStr("vi = 'Nguyên vật liệu để sản xuất';
											|ru = 'Сырье и материалы для производства';
											|en = 'Raw and consumable materials for production'; fa = 'مواد اولیه و مصرفی برای تولید';
											|it = 'Materie prime e materiali per la produzione';
											|pl = 'Materiały do produkcji';
											|tr = 'Üretim için hammaddeler ve malzemeler'"), SelectedRows);
	
	If RequiredFilling_ Then
		
		FilterArray = New Array();
		FilterArray.Add(PredefinedValue("Enum.SelectWarehouseGroup.AllowInOrders"));
		FilterArray.Add(PredefinedValue("Enum.SelectWarehouseGroup.AllowInOrdersAndInvoices"));
		
		FilterStructure1     = New Structure("SelectGroup, IsFolder", FilterArray, False);
		ParametersStructure = New Structure("Filter, GroupOfWarehouses", FilterStructure1, Object.WarehouseForReceipt);
		
		OpenForm(
			"Catalog.Warehouses.ChoiceForm",
			ParametersStructure,
			ThisObject,,,,
			New CallbackDescription(
				"MaterialsFillTheWarehouseCompletion", ThisObject, New Structure("SelectedRows", SelectedRows)),
			FormWindowOpeningMode.LockOwnerWindow);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure FillInPricesByTypeOfMaterialPrices(Command)
	
	FillInPricesByTypeOfMaterialPricesServer(True);
	
	PricesCalculated =
		Object.UsedMaterials.FindRows(New Structure("Price", 0)).Count() <> Object.UsedMaterials.Count();
	PartnerPricesFillingClient.NotifyAboutEndOfFillingInPricesByTypeOfSupplierSPrice(PricesCalculated, Object.PriceTypeMaterials);
	
	CalculateOrderTotals(ThisObject);
	
EndProcedure

&AtClient
Procedure MaterialsSelectionAccordingToSpecifications(Command)
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.TimeMeasurement(
		"Document.MaterialProviderOrder2_5.DocumentForm.Command.MaterialsFillInTheSelectionAccordingToSpecifications");
	
	Filter = New Structure;
	Filter.Insert("BillOfMaterials", PredefinedValue("Catalog.BillsOfMaterials.EmptyRef"));
	
	If Object.ManufacturedProduct.FindRows(Filter).Count() = Object.ManufacturedProduct.Count() Then
		
		If Object.ManufacturedProduct.Count() = 0 Then
			MessageText = NStr("vi = 'Phần bảng ""Thành phẩm"" không được điền.';
								|ru = 'Табличная часть ""Выпускаемая продукция"" не заполнена.';
								|en = 'Table ""Released products"" is not filled in.'; fa = 'Table ""Released products"" is not filled in.';
								|it = 'La parte tabulare ""Prodotti in fabbricazione"" non è compilata.';
								|pl = 'Nie wypełniono sekcji tabelarycznej ""Wypuszczane wiersze pozycji"".';
								|tr = '""İmal edilen ürünler"" tablo bölümü eksiktir.'");
		Else
			MessageText = NStr("vi = 'Trường ""Bảng kê chi tiết các nguồn lực sản xuất"" không được điền vào bất kỳ dòng nào của phần bảng ""Thành phẩm"".';
								|ru = 'Поле ""Спецификация"" не заполнено ни в одной из строк табличной части ""Выпускаемая продукция"".';
								|en = 'No lines with ""Bill of materials"" in table ""Released products"" are filled in.'; fa = 'No lines with ""Bill of materials"" in table ""Released products"" are filled in.';
								|it = 'Il campo ""Specifica"" non è compilato in nessuna delle righe della parte tabulare ""Prodotti in fabbricazione"".';
								|pl = 'Nie wypełniono pola ""Specyfikacja"" ani w jednym z wierszy sekcji tabelarycznej ""Wypuszczane wiersze pozycji"".';
								|tr = '""İmal edilen ürünler"" tablo bölümünün hiçbir satırında ""Ürün reçetesi"" alanı doldurulmamıştır.'");
		EndIf;
		
		ClearMessages();
		
		CommonClient.MessageToUser(MessageText, Object.Ref, "Object.ManufacturedProduct");
		
		Return; // There are no specifications to get a list of materials
		
	EndIf;
	
	FormParameters = New Structure();
	FormParameters.Insert("BOMList",        Items.UsedMaterialsBillOfMaterials.ChoiceList.UnloadValues());
	FormParameters.Insert("Department",             Object.Department);
	FormParameters.Insert("OrderDate",                Object.Date);
	FormParameters.Insert("LineOfBusiness",   Object.LineOfBusiness);
	FormParameters.Insert("AddressInTempStorage", PlaceProductsAndMaterialsInTemporaryStorageOnServer());
	
	OpenForm(
		"Document.MaterialProviderOrder2_5.Form.SelectionFormByBOMs",
		FormParameters,
		ThisObject,
		New UUID);
	
EndProcedure

&AtClient
Procedure FillInTheMaterialsAccordingToTheSpecifications(Command)
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.TimeMeasurement(
		"Document.MaterialProviderOrder2_5.DocumentForm.Command.MaterialsFillInFillInAccordingToSpecifications");
	
	ClearMessages();
	
	If Object.ManufacturedProduct.Count() = 0 Then
		
		MessageText = NStr("vi = 'Phần bảng ""Hàng hóa"" không được điền.';
							|ru = 'Табличная часть ""Выпускаемая продукция"" не заполнена.';
							|en = 'Table ""Released products"" is not filled in.'; fa = 'Table ""Released products"" is not filled in.';
							|it = 'La parte tabulare ""Prodotti in fabbricazione"" non è compilata.';
							|pl = 'Nie wypełniono sekcji tabelarycznej ""Wypuszczane wiersze pozycji"".';
							|tr = '""İmal edilen ürünler"" tablo bölümü eksiktir.'");
		CommonClient.MessageToUser(MessageText,, "Object.ManufacturedProduct");
		
		Return;
		
	EndIf;
	
	Filter = New Structure;
	Filter.Insert("BillOfMaterials", PredefinedValue("Catalog.BillsOfMaterials.EmptyRef"));
	If Object.ManufacturedProduct.FindRows(Filter).Count() = Object.ManufacturedProduct.Count() Then
		
		If Object.ManufacturedProduct.Count() = 1 Then
			MessageText = NStr("vi = 'Trường ''''Bảng kê chi tiết các nguồn lực sản xuất'''' trống.';
								|ru = 'Поле ""Спецификация"" не заполнено.';
								|en = '""Bill of materials"" is not filled in.'; fa = '""Bill of materials"" is not filled in.';
								|it = 'Il campo ""Specifica"" non è compilato.';
								|pl = 'Nie wypełniono pola ""Спецификация"".';
								|tr = '""Şartname"" alanı doldurulmamış.'");
			Field = CommonClientServer.PathToTabularSection("ManufacturedProduct", 1, "BillOfMaterials");
			CommonClient.MessageToUser(MessageText,, Field, "Object");
		Else
			MessageText = NStr("vi = 'Trường ""Bảng kê chi tiết các nguồn lực sản xuất"" không được điền vào bất kỳ dòng nào của phần bảng ""Sản phẩm xuất xưởng"".';
								|ru = 'Поле ""Спецификация"" не заполнено ни в одной из строк табличной части ""Выпускаемая продукция"".';
								|en = 'No lines with ""Bill of materials"" in table ""Released products"" are filled in.'; fa = 'No lines with ""Bill of materials"" in table ""Released products"" are filled in.';
								|it = 'Il campo ""Specifica"" non è compilato in nessuna delle righe della parte tabulare ""Prodotti in fabbricazione"".';
								|pl = 'Nie wypełniono pola ""Specyfikacja"" ani w jednym z wierszy sekcji tabelarycznej ""Wypuszczane wiersze pozycji"".';
								|tr = '""İmal edilen ürünler"" tablo bölümünün hiçbir satırında ""Ürün reçetesi"" alanı doldurulmamıştır.'");
			CommonClient.MessageToUser(MessageText,, "Object.ManufacturedProduct");
		EndIf; 
		
		Return;
		
	EndIf;
	
	FillInMaterials_ = True;
	
	If Object.UsedMaterials.Count() <> 0 Then
		
		ShowQueryBox(
			New CallbackDescription("FillInTheMaterialsAccordingToTheSpecificationsCompletion", ThisObject),
			NStr("vi = 'Sẽ điền lại phần bảng ""Nguyên vật liệu để sản xuất"". Tiếp tục?';
				|ru = 'Табличная часть ""Сырье и материалы для производства"" будет перезаполнена. Продолжить?';
				|en = 'Table ""Raw and consumable materials for production"" will be refilled. Continue?'; fa = 'Table ""Raw and consumable materials for production"" will be refilled. Continue?';
				|it = 'La parte tabulare ""Materie prime e materiali per la produzione"" sarà ricompilata. Continuare?';
				|pl = 'Część tabelaryczna ""Сырье и материалы для производства"" będzie ponownie wypełniona. Kontynuować?';
				|tr = '""Hammaddeler ve malzemeler"" tablo bölümü yeniden doldurulacak. Devam edilsin mi?'"),
			QuestionDialogMode.YesNo);
		
		Return;
		
	EndIf;
	
	MaterialsFillInSpecificationsFragment(FillInMaterials_);
	
EndProcedure

&AtClient
Procedure MaterialsInsertLines(Command)
	
	NumberOfProductsBeforeInsertion = Object.UsedMaterials.Count();
	
	GetLinesFromClipboard("UsedMaterials");
	
	NumberOfInserted = Object.UsedMaterials.Count() - NumberOfProductsBeforeInsertion;
	ProcessingOfTabularFormsClient.NotifyUserAboutInsertingRows(NumberOfInserted);
	
EndProcedure

&AtClient
Procedure MaterialsCopyLines(Command)
	
	If ProcessingOfTabularFormsClient.SelectedLineToExecuteCommand(Items.UsedMaterials) Then
		CopyLinesOnServer("UsedMaterials");
		ProcessingOfTabularFormsClient.NotifyUserAboutCopyingStrings(Items.UsedMaterials.SelectedRows.Count());
	EndIf;
	
EndProcedure

&AtClient
Procedure UsedMaterialsImportDataFromPDT(Command)
	
	ClearMessages();
	
	EquipmentManagerClient.StartDownloadingDataFromTSD(
		New CallbackDescription("DownloadMaterialsFromTSDEnd", ThisObject),
		UUID);
	
EndProcedure

&AtClient
Procedure MaterialsPickUpProducts(Command)
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.TimeMeasurement(
		"Document.MaterialProviderOrder2_5.DocumentForm.Command.MaterialsGeneralPickUpProducts_3");
	
	PickUpProduct("UsedMaterials");
	
EndProcedure

&AtClient
Procedure MaterialsBarcodeSearch(Command)
	
	ClearMessages();
	
	Notification = New CallbackDescription("MaterialsBarcodeSearchCompletion", ThisObject);
	BarcodingOfItemsClient.ShowBarcodeInput(Notification);
	
EndProcedure

&AtClient
Procedure MaterialsSplitLine(Command)
	
	FormTable  = Items.UsedMaterials;
	TableData = Object.UsedMaterials;
	
	Notification = New CallbackDescription("MaterialsSplitLineCompletion", ThisObject);
	ProcessingOfTabularFormsClient.SplitRow(TableData, FormTable, Notification);
	
EndProcedure

&AtClient
Procedure MaterialsCancelSelectedLines(Command)
	
	CancelSelectedLines("UsedMaterials", NStr("vi = 'Nguyên vật liệu để sản xuất';
												|ru = 'Сырье и материалы для производства';
												|en = 'Raw and consumable materials for production'; fa = 'مواد اولیه و مصرفی برای تولید';
												|it = 'Materie prime e materiali per la produzione';
												|pl = 'Materiały do produkcji';
												|tr = 'Üretim için hammaddeler ve malzemeler'"));
	
EndProcedure

&AtClient
Procedure MaterialsHideCanceledLines(Command)
	
	HideCanceledLinesMaterials = Not HideCanceledLinesMaterials;
	
	UpdateSelectionOfRowsByCanceled(Items, "UsedMaterials", HideCanceledLinesMaterials);
	
EndProcedure

&AtClient
Procedure MaterialsActionToTakeForStorage(Command)
	
	MaterialsSetActionInLinesOnServer(
		PredefinedValue("Enum.ActionsOnMaterialsToSubcontract.AcceptVMI"),
		Items.UsedMaterials.SelectedRows,
		CachedValues);
	
EndProcedure

&AtClient
Procedure MaterialsActionUseAvailable(Command)
	
	MaterialsSetActionInLinesOnServer(
		PredefinedValue("Enum.ActionsOnMaterialsToSubcontract.UseAvailable"),
		Items.UsedMaterials.SelectedRows,
		CachedValues);
	
EndProcedure

&AtClient
Procedure AddReusablePackage(Command)
	
	ReusablePackageClient.SelectReusablePackage(
		ThisObject,
		"UsedMaterials",
		"Products,Characteristic,Count,Warehouse,DateOfReceipt");
	
EndProcedure

#EndRegion

#Region PlugIns

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
Procedure Attachable_PropertiesExecuteCommand(ItemOrCommand, Var_URL = Undefined, StandardProcessing = Undefined)
	PropertyManagerClient.ExecuteCommand(ThisObject, ItemOrCommand, StandardProcessing);
EndProcedure

// IntegrationWith1CDocumentManagementSubsystem
&AtClient
Procedure Attachable_ExecuteIntegrationCommand(Command)
	
	IntegrationWith1CDocumentManagementCoreClient.ExecutePlugInIntegrationCommand(Command, ThisObject, Object);
	
EndProcedure
// End IntegrationWith1CDocumentManagementSubsystem

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisObject, Command);
	
EndProcedure

&AtClient
Procedure Attachable_OnChangeAdditionalAttribute(Item)
	PropertyManagerClient.UpdateAdditionalAttributesDependencies(ThisObject);
EndProcedure

&AtClient
Procedure Attachable_CloseForm()
	
	Close();
	
EndProcedure

&AtClient
Procedure Attachable_WhenChangingModifiabilityOfForm()
	
	If FormModified <> Modified Then
		
		FormModified = Modified;
		ProvisionInDocumentsClient.ConfigureHyperlinkedSoftwareState(ThisObject);
		
	EndIf;
	
EndProcedure

#Region Print

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
Procedure Attachable_ProcessObjectEntry()
	
	TMCommonUseClient.ProcessObjectEntryInForm(ThisObject, ParametersForRecording);
	
EndProcedure

#EndRegion

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

&AtClient
Procedure Attachable_UpdateSBPPaymentStatus(Command)

	ClearMessages();
	CashClientLocalization.UpdateStatusOfSBPPaymentByDocument(ThisObject, Object.Ref);

EndProcedure

#EndRegion

#EndRegion

#Region Private

#Region FormSettingsItem

&AtServer
Procedure SetConditionalAppearance()

	ConditionalAppearance.Items.Clear();
	
	DraftStatuses = New ValueList;
	DraftStatuses.Add(Enums.StatusesOfMaterialProviderOrders.NotApproved);
	DraftStatuses.Add(Enums.StatusesOfMaterialProviderOrders.Approved);
	
	#Region Header
	
	//
	TMCommonUse.SetConditionalAppearanceOfPriority(ThisObject);
	
	TMCommonUse.SetUncheckBlank(
		ConditionalAppearance, "Warehouse", "Object.Warehouse", "WarehouseIsRequired");
	
	ProvisionInDocumentsServer.SetUncheckBlankByStatus(
		ConditionalAppearance, "Warehouse", "Warehouse", "", DraftStatuses);
	
	ProvisionInDocumentsServer.SetUncheckBlankByStatus(
		ConditionalAppearance, "Department", "Department", "", DraftStatuses);
	
	TMCommonUse.SetUncheckBlank(
		ConditionalAppearance, "DateOfShipment", "Object.DateOfShipment", "DateOfShipmentRequired_");
	
	ProvisionInDocumentsServer.SetUncheckBlankByStatus(
		ConditionalAppearance, "DateOfReceipt", "DateOfReceipt", "", DraftStatuses);
	
	//
	WarehousesServer.SetConditionalAppearanceOfWarehouseInHeader(ThisObject);
	
	//
	LinesOfBusinessServer.EstablishConditionalAppearanceOfDirectionOfActivity(ThisObject);
	
	//
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.State.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("StateOverdue");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.OverdueDocument);
	
	//
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.State.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("State");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.SalesOrderStates.Closed;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.ClosedDocument);
	
	#EndRegion
	
	#Region ManufacturedProduct
	
	//
	ProductsServer.EstablishConditionalAppearanceOfProductCharacteristics(
		ThisObject, "ManufacturedProductCharacteristic", "Object.ManufacturedProduct.ItemVariantsAreUsed");
		
	//
	ConditionalDesignParameters = ProductsServer.NewParametersForConditionalDesignOfUnitsOfMeasurement();
	ConditionalDesignParameters.NameOfUnitField = "ManufacturedProductProductsUnitOfMeasure";
	ConditionalDesignParameters.PathToPackagingUnitField = "Object.ManufacturedProduct.Package";
	ProductsServer.SetConditionalAppearanceOfUnitsOfMeasurement(ThisObject, ConditionalDesignParameters);
	
	//
	OrdersServer.SetAppearanceOfCanceledLine(
		ConditionalAppearance,
		Items.ManufacturedProduct,
		Items.ManufacturedProductCanceled.Name,
		Items.ManufacturedProductCancellationReason.Name,
		Items.ManufacturedProductPrice.Name,
		Items.ManufacturedProductSum.Name);
	
	//
	TMCommonUse.SetUncheckBlank(
		ConditionalAppearance, "ManufacturedProductDateOfShipment", "Object.ManufacturedProduct.DateOfShipment", "Object.ManufacturedProduct.DateOfShipmentRequired_");
		
	//
	TMCommonUse.SetUncheckBlank(
		ConditionalAppearance, "ManufacturedProductWarehouse", "Object.ManufacturedProduct.Warehouse", "Object.ManufacturedProduct.WarehouseIsRequired");
	
	//
	WarehousesServer.SetConditionalAppearanceOfVTCHWarehouse(ThisObject, "ManufacturedProductWarehouse");
	
	//
	WarehousesServer.EstablishConditionalAppearanceOfVTCHDivision(ThisObject, "ManufacturedProduct");
	
	//
	EnterprisePricesFillingServer.EstablishConditionalAppearanceOfPriceTypes(
		ThisObject, "ManufacturedProductPriceKind", "Object.ManufacturedProduct.PriceKind");
	
	//
	EnterprisePricesFillingServer.SetConditionalAppearancePriceIncludesVAT(ThisObject, "ManufacturedProductAmountIncludingVAT");
	
	// VAT rate
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ManufacturedProductVATRate.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue  = New DataCompositionField("ManufacturedProductsProduced");
	ItemFilter.ComparisonType   = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	Item.Appearance.SetParameterValue("Visible", False);
	
	//
	VATAccountingERP.EstablishConditionalAppearanceOfVATAmountsForSalesTaxation(
		ThisObject, "ManufacturedProductVATRate", "ManufacturedProductVATAmount", "ManufacturedProductAmountIncludingVAT");
	
	//
	ProductsServer.EstablishConditionalAppearanceOfProductSeries(
		ThisObject,
		"SeriesAlwaysWHGoods",
		"ManufacturedProductSeries",
		"Object.ManufacturedProduct.BatchesIndicationStatus",
		"Object.ManufacturedProduct.ItemsType");
	
	//
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ManufacturedProductRecipient.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue  = New DataCompositionField("Object.ManufacturedProduct.ToExpenseAs");
	ItemFilter.ComparisonType   = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.ManufacturedProduct.Recipient");
	ItemFilter.ComparisonType  = DataCompositionComparisonType.NotFilled;
	
	Item.Appearance.SetParameterValue("MarkIncomplete", True);
	
	//
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ManufacturedProductRecipient.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue  = New DataCompositionField("Object.ManufacturedProduct.ToExpenseAs");
	ItemFilter.ComparisonType   = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	Item.Appearance.SetParameterValue("ReadOnly", True);
	Item.Appearance.SetParameterValue("Text",          NStr("vi = '<khi ghi giảm vào chi phí>';
															|ru = '<при списании на расходы>';
															|en = '<when writing off as expenses>'; fa = '<when writing off as expenses>';
															|it = '<durante lo storno sulle spese>';
															|pl = '<przy wyksięgowaniu na rozchody>';
															|tr = '<gider yazılması>'"));
	Item.Appearance.SetParameterValue("TextColor",     StyleColors.InaccessibleCellTextColor);
	
	//
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ManufacturedProductPrice.Name);
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ManufacturedProductSum.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.ManufacturedProduct.PriceKind");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	Item.Appearance.SetParameterValue("ReadOnly", True);
	
	#EndRegion
	
	#Region UsedMaterials
	
	//
	ProductsServer.EstablishConditionalAppearanceOfProductCharacteristics(
		ThisObject, "UsedMaterialsCharacteristic", "Object.UsedMaterials.ItemVariantsAreUsed");
	
	//
	ConditionalDesignParameters = ProductsServer.NewParametersForConditionalDesignOfUnitsOfMeasurement();
	ConditionalDesignParameters.NameOfUnitField = "UsedMaterialsProductsUnitOfMeasure";
	ConditionalDesignParameters.PathToPackagingUnitField = "Object.UsedMaterials.Package";
	ProductsServer.SetConditionalAppearanceOfUnitsOfMeasurement(ThisObject, ConditionalDesignParameters);
	
	//
	OrdersServer.SetAppearanceOfCanceledLine(
		ConditionalAppearance,
		Items.UsedMaterials,
		Items.UsedMaterialsCanceled.Name,,
		Items.UsedMaterialsPrice.Name,
		Items.UsedMaterialsSum.Name);
	
	//
	ProvisionInDocumentsServer.SetUncheckBlankByStatus(
		ConditionalAppearance, "UsedMaterialsDateOfReceipt", "DateOfReceipt", "UsedMaterials", DraftStatuses);
	
	//
	ProvisionInDocumentsServer.SetUncheckBlankByStatus(
		ConditionalAppearance, "UsedMaterialsWarehouse", "Warehouse", "UsedMaterials", DraftStatuses);
	
	//
	ProvisionInDocumentsServer.AvailableLeftoversAddColumnLayoutAvailable(ThisObject);
	
	//
	ProductsServer.EstablishConditionalAppearanceOfProductSeries(
		ThisObject,
		"SeriesAlwaysWHGoods",
		"UsedMaterialsSeries",
		"Object.UsedMaterials.BatchesIndicationStatus",
		"Object.UsedMaterials.ItemsType");
	
	//
	ConditionalAppearancePurposeRawMaterialsAndMaterialsForProduction();
	
	//
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.UsedMaterialsDateOfReceipt.Name);
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.UsedMaterialsWarehouse.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.UsedMaterials.Canceled");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	
	//
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.UsedMaterialsWarehouse.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ReceivingWarehouseGroup");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	Item.Appearance.SetParameterValue("Visible", False);
	
	//
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.UsedMaterialsWarehouse.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.UsedMaterials.Warehouse");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.UsedMaterials.Canceled");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	Item.Appearance.SetParameterValue("MarkIncomplete", True);
	
	//
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.UsedMaterialsWarehouse.Name);
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.UsedMaterialsDateOfReceipt.Name);
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.UsedMaterialsPrice.Name);
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.UsedMaterialsSum.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue  = New DataCompositionField("Object.UsedMaterials.Action");
	ItemFilter.ComparisonType   = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.ActionsOnMaterialsToSubcontract.UseAvailable;
	
	Item.Appearance.SetParameterValue("Text",                 NStr("vi = '<Không bắt buộc>';
																	|ru = '<не требуется>';
																	|en = '<not required>'; fa = '<الزامی نیست>';
																	|it = '<non richiesto>';
																	|pl = '<nie jest wymagane>';
																	|tr = '<gerekli değil>'"));
	Item.Appearance.SetParameterValue("TextColor" ,           StyleColors.InaccessibleCellTextColor);
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	Item.Appearance.SetParameterValue("ReadOnly",        True);
	
	//
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.UsedMaterialsPartnerProducts.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Partner");
	ItemFilter.ComparisonType  = DataCompositionComparisonType.NotFilled;
	
	Item.Appearance.SetParameterValue("TextColor",     StyleColors.EmptyTableField);
	Item.Appearance.SetParameterValue("Text",          NStr("vi = '<hãy chọn nhà cung cấp>';
															|ru = '<выберите поставщика>';
															|en = '<select vendor>'; fa = '<select vendor>';
															|it = '<selezionare il fornitore>';
															|pl = '<wybierz dostawcę>';
															|tr = '<tedarikçi seçin>'"));
	Item.Appearance.SetParameterValue("ReadOnly", True);
	
	//
	InstallationParameters = ReusablePackageServer.ParametersForSettingConditionalAppearanceForLinesWithMultiTurnContainers();
	
	InstallationParameters.Form                 = ThisObject;
	InstallationParameters.ThisIsAdmission        = True;
	InstallationParameters.NameOfVATRateField = "";
	InstallationParameters.NameOfPriceInputField      = "UsedMaterialsPrice";
	InstallationParameters.NameOfAmountInputField     = "UsedMaterialsSum";
	InstallationParameters.KTCHSelectionPath         = "Object.UsedMaterials";
	
	ReusablePackageServer.SetConditionalAppearanceForLinesWithMultiTurnContainers(InstallationParameters);
	
	//
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.UsedMaterialsPrice.Name);
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.UsedMaterialsSum.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.UsedMaterials.ItemsType");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotInList;
	ValueList = New ValueList;
	ValueList.Add(Enums.ItemsTypes.ReusablePackage);
	ItemFilter.RightValue = ValueList;
	
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	
	// Conditional appearance of quality control Attributes.
	Fields = QualityControl.Fields(
		Items.UsedMaterialsToControlQuality,
		Items.UsedMaterialsQualityConfirmationDate);
	FlagDisabled = New Array();
	DateIsOptional = New Array();
	Statuses = Enums.StatusesOfMaterialProviderOrders;
	QualityControl.AddFilter(FlagDisabled, "Object.UsedMaterials.Canceled", True);
	QualityControl.AddFilter(FlagDisabled, "Object.UsedMaterials.Action", Enums.ActionsOnMaterialsToSubcontract.UseAvailable);
	QualityControl.AddFilter(DateIsOptional, "Object.Status", Statuses.NotApproved);
	QualityControl.AddFilter(DateIsOptional, "Object.Status", Statuses.Approved);
	QualityControl.SetupAppearance(ConditionalAppearance, Fields, FlagDisabled, DateIsOptional);
	
	#EndRegion
	
EndProcedure

&AtServer
Procedure ConditionalAppearancePurposeRawMaterialsAndMaterialsForProduction()
	
	// Conditional design of the destination in the list of materials that matches the destination in the header.
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.UsedMaterialsPurpose.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.UsedMaterials.Purpose");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	Item.Appearance.SetParameterValue("Text", New DataCompositionField("PurposePresentation"));
	
	// Conditional registration of the appointment in the list of materials when the giver is not specified
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.UsedMaterialsPurpose.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Partner");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<chưa chỉ ra người đặt gia công>';
													|ru = '<не указан давалец>';
													|en = '<material provider is not specified>'; fa = '<material provider is not specified>';
													|it = '<il committente non è indicato>';
													|pl = '<nie wskazano właściciela surowców>';
													|tr = '<malzeme tedarikçisi belirtilmemiş>'"));
	Item.Appearance.SetParameterValue("ReadOnly", True);
	Item.Appearance.SetParameterValue("TextColor", StyleColors.EmptyTableField);
	
	// Standard registration of the receipt assignment.
	ProductsServer.SetConditionalAppearanceOfProductAssignment(
		ThisObject, Items.UsedMaterialsPurpose.Name, "Object.UsedMaterials.ItemsType");
	
EndProcedure

&AtServer
Procedure CustomizeFormElements()
	
	BusinessOperationSelectionList = Items.BusinessOperation.ChoiceList;
	BusinessOperationSelectionList.Clear();
	
	If Object.BusinessOperation = Enums.BusinessTransactions.TollManufacturing2_5 Then
		BusinessOperationSelectionList.Add(Enums.BusinessTransactions.TollManufacturing2_5, NStr("vi = 'Gia công (chung)';
																								|ru = 'Переработка (общее)';
																								|en = 'Subcontracting (general)'; fa = 'Subcontracting (general)';
																								|it = 'Subcontracting (general)';
																								|pl = 'Subcontracting (general)';
																								|tr = 'Geri dönüşüm (genel)'"));
	Else
		BusinessOperationSelectionList.Add(Enums.BusinessTransactions.Subcontracting2_5, NStr("vi = 'Gia công thành phẩm';
																								|ru = 'Переработка продукции';
																								|en = 'Product subcontracting'; fa = 'Product subcontracting';
																								|it = 'Product subcontracting';
																								|pl = 'Product subcontracting';
																								|tr = 'Ürün geri dönüşüm'"));
		BusinessOperationSelectionList.Add(Enums.BusinessTransactions.PerformWorksUsingProvidedMaterials2_5, NStr("vi = 'Thực hiện công việc';
																													|ru = 'Выполнение работ';
																													|en = 'Work performance'; fa = 'Work performance';
																													|it = 'Work performance';
																													|pl = 'Work performance';
																													|tr = 'İş yapma'"));
		
		SubsystemSettingsProduction = ProductionServerCached.SubsystemSettingsProduction();
		
		If SubsystemSettingsProduction.DynamicStructureOfProductionOrders Then
			BusinessOperationSelectionList.Add(Enums.BusinessTransactions.PerformRMUsingProvidedMaterials2_5, NStr("vi = 'Sửa chữa';
																													|ru = 'Ремонт';
																													|en = 'R&M'; fa = 'تعمیر و نگهداری';
																													|it = 'R&M';
																													|pl = 'R&M';
																													|tr = 'Bakım-onarım'"));
		EndIf;
		
		If Not SubsystemSettingsProduction.DynamicStructureOfProductionOrders
			Or Object.BusinessOperation = Enums.BusinessTransactions.RepairProductsFromProvidedMaterials2_5 Then
			BusinessOperationSelectionList.Add(Enums.BusinessTransactions.RepairProductsFromProvidedMaterials2_5, NStr("vi = 'Sửa chữa thành phẩm';
																														|ru = 'Ремонт продукции';
																														|en = 'Product R&M'; fa = 'تعمیر و نگهداری محصول';
																														|it = 'Product R&M';
																														|pl = 'Product R&M';
																														|tr = 'Ürün bakım-onarım'"));
		EndIf;
		
	EndIf;
	
	Items.BusinessOperation.Visible = Not BusinessOperationSelectionList.Count() = 1;
	
EndProcedure

// Parameters:
// 	Form - ClientApplicationForm
// 	AttributesList - String
&AtClientAtServerNoContext
Procedure ConfigureDependentFormElements(Form, AttributesList = "")
	
	Items = Form.Items;
	Object = Form.Object;
	
	AttributesList = New Structure(AttributesList);
	Initialize = Not ValueIsFilled(AttributesList);
	
	If Initialize
		Or AttributesList.Property("KeepManufacturedProductsForSubcontracting") Then
		
		TitleCommand   = NStr("vi = 'Ngày giao hàng';
								|ru = 'Дату отгрузки';
								|en = 'Shipment date'; fa = 'تاریخ ارسال';
								|it = 'La data di spedizione';
								|pl = 'Datę wysyłki';
								|tr = 'Sevkiyat tarihi'");
		TitleDate      = NStr("vi = 'Ngày giao hàng';
								|ru = 'Дата отгрузки';
								|en = 'Shipment date'; fa = 'تاریخ ارسال';
								|it = 'Data di spedizione';
								|pl = 'Data wysyłki';
								|tr = 'Sevkiyat tarihi'");
		TitleFlag      = NStr("vi = 'Giao hàng trong một ngày';
								|ru = 'Отгружать одной датой';
								|en = 'One-day shipping'; fa = 'ارسال یک‌روزه';
								|it = 'Spedire entro la stessa data';
								|pl = 'Wysyłaj w jednym dniu';
								|tr = 'Aynı tarihte sevk...'");
		ToolTipFlag      = NStr("vi = 'Ngày giao hàng mong muốn của đơn đặt hàng';
								|ru = 'Желаемая дата отгрузки заказа';
								|en = 'Desired order shipment date'; fa = 'تاریخ مطلوب ارسال سفارش';
								|it = 'Data preferibile di invio dell''ordine';
								|pl = 'Planowana data wysyłki zamówienia';
								|tr = 'İstenen sipariş sevkiyat tarihi'");
		DateHint      = NStr("vi = 'Dấu hiệu xác nhận khả năng giao hàng từng phần vào các ngày khác nhau.';
							|ru = 'Признак, определяющий возможность отгрузки по частям в разные даты.';
							|en = 'Shows whether shipment in installments in different dates is permitted.'; fa = 'نشان می‌دهد که آیا ارسال اقساطی در تاریخ‌های مختلف مجاز است.';
							|it = 'L''indicazione che determina la possibilità della spedizione in parti nelle date diverse.';
							|pl = 'Oznaka wskazująca na możliwość wysyłki w częściach w różnych dniach.';
							|tr = 'Farklı tarihlerde parçalar halinde sevkiyat olasılığını belirleyen bayrak.'");
		TitleShip = NStr("vi = 'Giao hàng';
						|ru = 'Отгрузить';
						|en = 'Ship'; fa = 'ارسال';
						|it = 'Da spedire';
						|pl = 'Wyślij';
						|tr = 'Sevk et'");
		
		If Object.KeepManufacturedProductsForSubcontracting Then
			TitleCommand   = NStr("vi = 'Ngày sản xuất';
									|ru = 'Дату производства';
									|en = 'Production date'; fa = 'تاریخ تولید';
									|it = 'Data di produzione';
									|pl = 'Datę produkcji';
									|tr = 'Üretim tarihi'");
			TitleShip = NStr("vi = 'Tiếp nhận';
							|ru = 'Принять';
							|en = 'Receive'; fa = 'دریافت';
							|it = 'Accettare';
							|pl = 'Zastosuj';
							|tr = 'Kabul et'");
			TitleDate      = NStr("vi = 'Ngày sản xuất';
									|ru = 'Дата производства';
									|en = 'Production date'; fa = 'تاریخ تولید';
									|it = 'Data di produzione';
									|pl = 'Data produkcji';
									|tr = 'Üretim tarihi'");
			TitleFlag      = NStr("vi = 'Sản xuất trong một ngày';
									|ru = 'Производить одной датой';
									|en = 'Produce in one day'; fa = 'Produce in one day';
									|it = 'Produrre in una data';
									|pl = 'Produkuj w jednym dniu';
									|tr = 'Aynı tarihte üretim'");
			ToolTipFlag      = NStr("vi = 'Dấu hiệu xác nhận khả năng giao hàng từng phần vào các ngày khác nhau.';
									|ru = 'Признак, определяющий возможность производства по частям в разные даты.';
									|en = 'Indicates whether it is possible to produce on different dates.'; fa = 'Indicates whether it is possible to produce on different dates.';
									|it = 'Contrassegno che definisce la possibilità di produzione per parti in date diverse.';
									|pl = 'Oznaka wskazująca na możliwość produkcji w częściach w różnych dniach.';
									|tr = 'Farklı tarihlerde parçalar halinde üretim olasılığını belirleyen bayrak.'");
			DateHint      = NStr("vi = 'Ngày sản xuất theo dự kiến';
								|ru = 'Желаемая дата производства';
								|en = 'Requested production date'; fa = 'Requested production date';
								|it = 'Data di produzione auspicabile';
								|pl = 'Pożądana data produkcji';
								|tr = 'İstenen üretim tarihi'");
		EndIf;
		
		Items.ProductsFillInTheShipmentDate.Title    = TitleCommand;
		Items.ProductsToShip.Title                = TitleShip;
		Items.ProductsContextMenuShip.Title = TitleShip;
		Items.ManufacturedProductDateOfShipment.Title             = TitleDate;
		Items.NotShipInInstallments.Title                = TitleFlag;
		Items.NotShipInInstallments.ToolTip                = ToolTipFlag;
		Items.DateOfShipment.ToolTip                      = DateHint;
		
	EndIf;
	
	If Initialize
		Or AttributesList.Property("ItemVariantsAreUsed") Then
		
		CharacteristicField = Items.UnderRepairVariant;
		
		If Form.ItemVariantsAreUsed Then
			CharacteristicField.InputHint = "";
			CharacteristicField.Enabled = True;
			CharacteristicField.AutoMarkIncomplete = True;
		Else
			CharacteristicField.InputHint = NStr("vi = '<không sử dụng đặc tính>';
												|ru = '<характеристики не используются>';
												|en = '<variants are not used>'; fa = '<گونه‌ها استفاده نمی‌شوند>';
												|it = '<le caratteristiche non vengono usate>';
												|pl = '<charakterystyki nie dotyczą>';
												|tr = '<varyantlar kullanılmamaktadır>'");
			CharacteristicField.Enabled = False;
			CharacteristicField.AutoMarkIncomplete = False;
		EndIf;
		
	EndIf;
	
	If Initialize
		Or AttributesList.Property("BusinessOperation") Then
		
		// Hint "Business of operation"
		Items.BusinessOperation.ToolTip    = Object.BusinessOperation;
		
		// Production of manufactured products
		Items.Content.Visible               = Form.ManufacturedProductsProduced;
		Items.VATRate.Visible                = Form.ManufacturedProductsProduced;
		
		Items.Warehouse.Visible                    = Form.ManufacturedProductsProduced And Form.UseSeveralWarehouses;
		Items.PictureMultipleWarehouses.Visible = Form.ManufacturedProductsProduced And Form.UseSeveralWarehouses;
		Items.SeveralWarehousesText.Visible  = Form.ManufacturedProductsProduced And Form.UseSeveralWarehouses;
		Items.ManufacturedProductFillInTheWarehouse.Visible  = Form.ManufacturedProductsProduced And Form.UseSeveralWarehouses;
		
		Items.ProductsFillDivision.Visible = Form.WorksAreBeingCarriedOut;
		
		// Visibility Of Delivery
		Items.DeliveryPage.Visible = Form.VisibilityOfDeliveryPage And Form.ManufacturedProductsProduced;
		
		// Headings of the "Manufactured Products" page
		TitleManufacturingProducts = NStr("vi = 'Thành phẩm xuất xưởng';
											|ru = 'Выпускаемая продукция';
											|en = 'Released products'; fa = 'محصولات تولیدشده';
											|it = 'Prodotti in fabbricazione';
											|pl = 'Wypuszczana produkcja';
											|tr = 'İmal edilen ürünler'");
		HintManufacturedProducts = NStr("vi = 'Thành phẩm do bên nhận gia công chịu trách nhiệm sản xuất';
										|ru = 'Продукция, обязательства по выпуску которой берет на себя переработчик';
										|en = 'Products which will be released by the subcontractor'; fa = 'محصولاتی که توسط پیمانکار فرعی تولید خواهند شد';
										|it = 'Prodotti per la fabbricazione dei quali si impegna l''addetto alla lavorazione';
										|pl = 'Wiersze pozycji, zobowiązania w ramach wypuszczenia których bierze na siebie przetwórca';
										|tr = 'Fason üreticinin üretmekle yükümlü olduğu imal edilen ürünler'");
		
		If Not Form.ManufacturedProductsProduced
			And Form.WorksAreBeingCarriedOut Then
			TitleManufacturingProducts = NStr("vi = 'Công việc được thực hiện';
												|ru = 'Выполняемые работы';
												|en = 'Works to perform'; fa = 'کارهای قابل انجام';
												|it = 'Works to perform';
												|pl = 'Works to perform';
												|tr = 'Yapılan işler'");
			HintManufacturedProducts = NStr("vi = 'Thực hiện công việc có sử dụng nguyên liệu gia công';
											|ru = 'Работы, выполняемые с использованием давальческого сырья';
											|en = 'Works performed using provided materials'; fa = 'Works performed using provided materials';
											|it = 'Works performed using provided materials';
											|pl = 'Works performed using provided materials';
											|tr = 'Sağlayıcı hammaddeleri kullanarak yapılan çalışmalar'");
		EndIf;
		
		Items.ProductsPage.Title = TitleManufacturingProducts;
		Items.ProductsPage.ToolTip = HintManufacturedProducts;
		
		// Title "Pick up products"
		TitleOpenSelection = NStr("vi = 'Chọn mặt hàng';
									|ru = 'Подобрать товары';
									|en = 'Pick goods'; fa = 'انتخاب کالاها';
									|it = 'Selezionare la merce';
									|pl = 'Dobierz wiersze pozycji';
									|tr = 'Ürünleri seç'");
		If Not Form.ManufacturedProductsProduced
			And Form.WorksAreBeingCarriedOut Then
			TitleOpenSelection = NStr("vi = 'Chọn công việc';
										|ru = 'Подобрать работы';
										|en = 'Pick works'; fa = 'Pick works';
										|it = 'Pick works';
										|pl = 'Pick works';
										|tr = 'İşleri seç'");
		EndIf;
		Items.ProductsOfOpenRecruitment.Title = TitleOpenSelection;
		
		// Item of Manufactured products
		ParametersForSelectingManufacturedProducts = New Array;
		
		ItemsTypes = New Array;
		If Form.ManufacturedProductsProduced Then
			ItemsTypes.Add(PredefinedValue("Enum.ItemsTypes.OwnGoods"));
			ItemsTypes.Add(PredefinedValue("Enum.ItemsTypes.ReusablePackage"));
		EndIf;
		If Form.WorksAreBeingCarriedOut Then
			ItemsTypes.Add(PredefinedValue("Enum.ItemsTypes.Work_5"));
		EndIf;
		
		NewChoiceParameter = New ChoiceParameter("Filter.ItemsType", New FixedArray(ItemsTypes));
		
		ParametersForSelectingManufacturedProducts.Add(NewChoiceParameter);
		
		Items.ManufacturedProductProducts.ChoiceParameters = New FixedArray(ParametersForSelectingManufacturedProducts);
		
	EndIf;
	
EndProcedure

// Parameters:
// 	AttributesList - String
&AtServer
Procedure ConfigureDependentFormElementsOnServer(AttributesList = "")
	
	AttributesList = New Structure(AttributesList);
	Initialize = Not ValueIsFilled(AttributesList);
	
	If Initialize
		Or AttributesList.Property("BusinessOperation") Then
		
		// type of production process
		DescriptionOfManufacturingProcessTypeIsAvailable =
			ProductDataManagement.DescriptionOfManufacturingProcessTypeIsAvailable();
		
		Items.ProductionProcessType.Visible =
			DescriptionOfManufacturingProcessTypeIsAvailable;
		
		Items.ProductionProcessType.ReadOnly =
			Not Object.BusinessOperation = Enums.BusinessTransactions.TollManufacturing2_5;
		
		If DescriptionOfManufacturingProcessTypeIsAvailable Then
			
			If Object.BusinessOperation = Enums.BusinessTransactions.TollManufacturing2_5 Then
				TypesToExclude = New Array;
				TypesToExclude.Add(Enums.ProductionProcessTypes.WithoutBillsOfMaterials);
				TypesToExclude.Add(Enums.ProductionProcessTypes.Disassembly);
				TypesToExclude.Add(Enums.ProductionProcessTypes.PerformRM);
			EndIf;
			
			ProductionServer.FillInListOfProductionProcessTypes(Items.ProductionProcessType, TypesToExclude);
			
		EndIf;
		
		// The Finished Product being Repaired
		VisibilityOfFinishedProductBeingRepaired =
			Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.PerformRMUsingProvidedMaterials2_5");
		
		Items.UnderRepairProduct.Visible = VisibilityOfFinishedProductBeingRepaired;
		Items.UnderRepairVariant.Visible = VisibilityOfFinishedProductBeingRepaired;
		
		EstablishAvailabilityOfBatchesOfRepairedFinishedProduct();
		
	EndIf;
	
EndProcedure

&AtServer
Procedure PrepareFillSetSeriesVisibility(TSName)
	
	SeriesSpecificationParameters = New FixedStructure(
		ProductsServer.SeriesSpecificationParameters(Object, Documents.MaterialProviderOrder2_5));
		
	ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters[TSName]);
	
	Items[TSName + "Series"].Visible = SeriesSpecificationParameters[TSName].UseItemsBatch;
	
EndProcedure

&AtServer
Procedure SetSoftwareVisibility()
	
	HasRight = ProvisionInDocumentsServer.HaveRightToViewStateHyperlink();
	Items.PagesHyperlinkSoftwareStatus.Visible = HasRight;
	
	ProvisionInDocumentsServer.ConfigureHyperlinkedSoftwareState(ThisObject);
	Items.DateOfShipment.ToolTip = ProvisionInDocumentsServer.HintShipmentDate();
	
EndProcedure

&AtServer
Procedure SetVisibilityOfElementsByFO()
	
	VisibilityOfElements = New Map;
	
	ItemArray = New Array;
	ItemArray.Add("WarehouseForReceipt");
	ItemArray.Add("ThePictureOfTheWarehouseReceipt");
	ItemArray.Add("LabelMultipleWarehousesReceipts");
	
	VisibilityOfElements.Insert(
		ItemArray, GetFunctionalOption("UseSeveralWarehouses"));
	
	ItemArray = New Array;
	ItemArray.Add("TitleOrganization");
	
	VisibilityOfElements.Insert(
		ItemArray, GetFunctionalOption("UseMultipleCompanies"));
	
	ItemArray = New Array;
	ItemArray.Add("CharacteristicNotUsed");
	
	VisibilityOfElements.Insert(
		ItemArray, GetFunctionalOption("UseItemVariants"));
	
	ItemArray = New Array;
	ItemArray.Add("ProductsGroupCanceled");
	
	VisibilityOfElements.Insert(
		ItemArray, GetFunctionalOption("UseReasonsForSalesOrderCancellations"));
	
	ItemArray = New Array;
	ItemArray.Add("ProductsCancelledReasonsForCancellationAreNotUsed");
	
	VisibilityOfElements.Insert(
		ItemArray, Not GetFunctionalOption("UseReasonsForSalesOrderCancellations"));
	
	For Each MapItem In VisibilityOfElements Do
		
		TMCommonUseClientServer.SetPropertyOfFormElements(
			Items, MapItem.Key, "Visible", MapItem.Value);
		
	EndDo;
	
EndProcedure

&AtServer
Procedure SetVisibilityOfReceiptDateFormElements()
	
	// PM button and props
	Items.MaterialsFillInTheDateOfReceipt.Visible = Not Object.OneDateReceipt;
	Items.UsedMaterialsDateOfReceipt.Visible = Not Object.OneDateReceipt;
	
	// General form details
	Items.DateOfReceipt.Visible = Object.OneDateReceipt;
	
EndProcedure

&AtServer
Procedure SetVisibilityOfShippingDateFormElements()
	
	// General form details
	Items.DateOfShipment.Visible = Object.NotShipInInstallments;
	
	// PM button and props
	Items.ManufacturedProductDateOfShipment.Visible = Not Object.NotShipInInstallments;
	Items.ProductsFillInTheShipmentDate.Visible = Not Object.NotShipInInstallments;
	
EndProcedure

&AtServer
Procedure SetVisibilityOfElementsByTaxationServer()
	
	Items.PriceIncludesVAT.Visible =
		Object.VATTaxation = Enums.VATTaxationTypes.SaleIsSubjectToVAT;
	
EndProcedure

&AtServer
Procedure SetVisibilityOfShipmentBanToPartner()
	
	SegmentsServer.SetVisibilityOfShipmentBanToPartner(Object.Partner, Items);
	
EndProcedure

&AtServer
Procedure SetParametersForSelectingProductsWarehouse(TSName)
	
	If TSName = "ManufacturedProduct" Then
		
		Items.ManufacturedProductWarehouse.ChoiceParameters = New FixedArray(New Array);
		TMCommonUseClientServer.AddSelectionParameter(
			Items.ManufacturedProductWarehouse, "Ref", WarehouseSelectionData(Object.Warehouse));
			
	ElsIf TSName = "UsedMaterials" Then
		
		Items.UsedMaterialsWarehouse.ChoiceParameters = New FixedArray(New Array);
		TMCommonUseClientServer.AddSelectionParameter(
			Items.UsedMaterialsWarehouse, "Ref", WarehouseSelectionData(Object.WarehouseForReceipt));
			
	EndIf;

EndProcedure

&AtServer
Procedure FillInSpecificationSelectionParameters()

	BOMSelectionParameters = ProductDataManagement.BOMSelectionParameters(Object, Documents.MaterialProviderOrder2_5);
	ProductDataManagement.SetSpecificationSelectionParameters(Items.ManufacturedProductBillOfMaterials, BOMSelectionParameters);
	
EndProcedure

#Region WorkingWithClipboard

&AtServer
Procedure SetAvailabilityOfClipboardCommands()
	
	ItemArray = New Array();
	ItemArray.Add("MaterialsInsertLines");
	ItemArray.Add("TheMaterialsContextMenuToInsertRows");
	ItemArray.Add("ManufacturedProductInsertRows");
	ItemArray.Add("ManufacturedProductContextMenuInsertRows");
	
	TMCommonUseClientServer.SetPropertyOfFormElements(
		Items, ItemArray, "Enabled", ProcessingOfTabularForms.ThereAreLinesInClipboard());
	
EndProcedure

&AtClient
Procedure SetAvailabilityOfClipboardCommandsOnClient()
	
	ItemArray = New Array();
	ItemArray.Add("MaterialsInsertLines");
	ItemArray.Add("TheMaterialsContextMenuToInsertRows");
	ItemArray.Add("ManufacturedProductInsertRows");
	ItemArray.Add("ManufacturedProductContextMenuInsertRows");
	
	TMCommonUseClientServer.SetPropertyOfFormElements(Items, ItemArray, "Enabled", True);
	
EndProcedure

#EndRegion

#EndRegion

#Region OnChangeAttributes

#Region Header

&AtServer
Procedure WhenStatusChangesServer()
	
	If Object.Status = PredefinedValue("Enum.StatusesOfMaterialProviderOrders.ToProduce")
		Or Object.Status = PredefinedValue("Enum.StatusesOfMaterialProviderOrders.ToShip")
		Or Object.Status = PredefinedValue("Enum.StatusesOfMaterialProviderOrders.Closed") Then
		
		RowsToProcess = New Array;
		For Each CurrentData In Object.UsedMaterials Do
			If ValueIsFilled(CurrentData.DateOfReceipt)
				And CurrentData.ToControlQuality
				And Not ValueIsFilled(CurrentData.QualityConfirmationDate) Then
				RowsToProcess.Add(CurrentData);
			EndIf;
		EndDo;
		
		If ValueIsFilled(RowsToProcess) Then
			StructureOfActions = New Structure;
			AddQualityControlActionsToStructure(StructureOfActions, CacheQualityControl);
			BatchProcessingOfTablePartServer.ProcessTSStrings(RowsToProcess, StructureOfActions, Object.UsedMaterials);
		EndIf;
		
	EndIf;
	
	FillInServiceDetailsOfSupply();
	
EndProcedure

&AtServer
Procedure OnChangePriceIncludesVATServer(CachedValues)
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForRecalculatingNDSWTCHAmount(Object);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateVATAmount",  StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	
	BatchProcessingOfTablePartServer.TreatTS(Object.ManufacturedProduct, StructureOfActions, CachedValues);
	
	CalculateOrderTotals(ThisObject);
	
	PriceTypeSelectionParameters = SettingsValueCached.ParametersForSelectingDefaultPriceType();
	PriceTypeSelectionParameters.PriceIncludesVAT                          = Object.PriceIncludesVAT;
	PriceTypeSelectionParameters.UseWhileTransferringProductsToMaterialProvider = True;
	PriceTypeSelectionParameters.Status                                   = Enums.StatusesOfPriceTypeValidity.Valid;
	
	DefaultPriceType = SettingsValueCached.DefaultPriceType(PriceTypeSelectionParameters);
	
EndProcedure

&AtServer
Procedure WhenChangingPartnerServer()
	
	DocumentCurrency = Object.Currency;
	
	PartnersAndCounterparties.FillInPartnerSDefaultCounterparty(Object.Partner, Object.Counterparty);
	
	If ValueIsFilled(Object.Counterparty) Then
		FillInDefaultContract();
	EndIf;
	
	ArrayOfChangedProps = New Array;
	ArrayOfChangedProps.Add("Partner");
	ArrayOfChangedProps.Add("Contract");
	ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisObject, ArrayOfChangedProps);
	
	SalesServer.PartnerOnChange(Object);
	
	If UseLinesOfBusiness Then
		LinesOfBusinessServer.FillInDefaultDirection(Object.LineOfBusiness,, Object.Contract);
	EndIf;
	
	SelectingTypeOfPrices = New Structure("Owner, AvailableForPurchase", Object.Partner, True);
	Object.PriceTypeMaterials = Catalogs.VendorPriceTypes.DefaultPriceType(Object.PriceTypeMaterials, SelectingTypeOfPrices);
	If ValueIsFilled(Object.PriceTypeMaterials) Then
		FillInPricesByTypeOfMaterialPricesServer(False);
	EndIf;
	
	WhenChangingWarehouseServer("ManufacturedProduct");
	WhenChangingWarehouseServer("UsedMaterials");
	
	ProvisionInDocumentsServer.WhenChangingDocumentDetails(ThisObject);
	
	FillInServiceDetailsOfSupply();
	
	TMCommonUse.FillInDuplicateDependentPropsInCollection(
		Object.ManufacturedProduct, DependentDetails("ManufacturedProduct"));
	
	PartnersProductsServer.FillInPartnerProductsByProductsInTable(Object.UsedMaterials, Object.Partner);
	
	CalculateOrderTotals(ThisObject);
	FillInAndSetDeliveryAttributesServer("Partner");
	SetVisibilityOfElementsByTaxationServer();
	
	ResponsiblePersonsServer.FillInManager_(Object);
	
	FillInSubordinatePropertiesForStatistics("Counterparty");
	
	ResponsiblePersonsServer.WhenChangingRelatedDocumentDetails(Object);
	
	SetVisibilityOfShipmentBanToPartner();
	
	UpdateAppointments();
	
EndProcedure

&AtServer
Procedure ContactPersonOnChangeServer(PartnerChanged_)
	
	OwnerOfContactPerson = Common.ObjectAttributeValue(Object.ContactPerson, "Owner");
	If OwnerOfContactPerson <> Object.Partner Then
		Object.Partner = OwnerOfContactPerson;
		WhenChangingPartnerServer();
		PartnerChanged_ = True;
	EndIf;
	
EndProcedure

&AtServer
Procedure WhenChangingAgreementServer(DirectModificationOfContractField = False)
	
	ForeignCurrencyTransaction = Object.ForeignCurrencyTransaction;
	
	If ValueIsFilled(Object.Contract) Then
		
		ContractDetails_ = "FinancialAccountingGroup, Department";
		ContractDetails_ = New Structure(ContractDetails_);
		ContractDetails_.Insert("Currency", "ARAPCurrency");
		
		ContractDetails_ = Common.ObjectAttributesValues(Object.Contract, ContractDetails_);
		For Each CurrentAttribute In ContractDetails_ Do
			If ValueIsFilled(CurrentAttribute.Value) Then
				Object[CurrentAttribute.Key] = CurrentAttribute.Value;
			EndIf;
		EndDo;
		
		If Not DocumentCurrency = Object.Currency Then
			ConvertDocumentAmountsToCurrency();
			DocumentCurrency = Object.Currency;
		EndIf;
		
	EndIf;
	
	UpdateVATTaxation_();
	
	ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisObject, "Contract, DocumentCurrency");
	
	If UseLinesOfBusiness Then
		LinesOfBusinessServer.FillInDefaultDirection(Object.LineOfBusiness,, Object.Contract);
	EndIf;
	
	If ForeignCurrencyTransaction <> Object.ForeignCurrencyTransaction Then
		Object.BankAccount = Catalogs.CompaniesBankAccounts.EmptyRef();
	EndIf;
	
	PurchasesServerCall.FillInBankAccountsUnderAgreement(Object.Contract, Object.BankAccount,
		Object.CounterpartyBankAccount);
	
	If Not ValueIsFilled(Object.BankAccount) Then
		ParametersOfAccount = CashServer.ParametersForFillingOutOrganizationSBankAccount(Object.Organization);
		ParametersOfAccount.LineOfBusiness = Object.LineOfBusiness;
		ParametersOfAccount.ExcludeCurrencyAccounts = Object.ForeignCurrencyTransaction;
		ParametersOfAccount.Currency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Object.Organization);
		Object.BankAccount = CashServer.GetOrganizationSDefaultBankAccount(
			ParametersOfAccount);
	EndIf;
	
	WhenYouChangeDestinationTemplateInDocument();
	UpdateAppointments();
	
	If QualityControl.UpdateActionParameters(
			Documents.MaterialProviderOrder2_5,
			Object,
			CacheQualityControl,
			DirectModificationOfContractField) Then
		StructureOfActions = New Structure;
		AddQualityControlActionsToStructure(StructureOfActions, CacheQualityControl);
		BatchProcessingOfTablePartServer.TreatTS(Object.UsedMaterials, StructureOfActions);
	EndIf;
	
	ResponsiblePersonsServer.FillInManager_(Object);
	
	FillInSubordinatePropertiesForStatistics("Contract");
	
EndProcedure

&AtServer
Procedure FinishedProductToBeRepairedItemOnChangeATServer(CachedValues)
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("CheckCharacteristicsByOwner", Object.UnderRepairVariant);
	StructureOfActions.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
	StructureOfActions.Insert("FillInFeatureAttribute", New Structure("Products", "ItemVariantsAreUsed"));
	StructureOfActions.Insert("ProductsOnChangeOverridable", New Structure("FormName, TabularSectionName", FormName, "Object"));

	DataStructureOfFinishedProductBeingRepaired = ProductionManagementClientServer.DataOfFinishedProductBeingRepairedByStructure(Object);
	
	BatchProcessingOfTablePartServer.ProcessTSString(
		DataStructureOfFinishedProductBeingRepaired,
		StructureOfActions,
		BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues());
	
	Object.UnderRepairVariant = DataStructureOfFinishedProductBeingRepaired.Characteristic;
	ItemsType                           = DataStructureOfFinishedProductBeingRepaired.ItemsType;
	ItemVariantsAreUsed                = DataStructureOfFinishedProductBeingRepaired.ItemVariantsAreUsed;
	
	If SeriesSpecificationParameters.FinishedProductBeingRepaired.UseItemsBatch Then
		FillInBatchIndicationStatusesONChangesOfFinishedProductBeingRepaired(CachedValues, DataStructureOfFinishedProductBeingRepaired);
	EndIf;
	
	ConfigureDependentFormElements(ThisObject, "ItemVariantsAreUsed");
	
EndProcedure

&AtServer
Procedure WhenChangingVATRateServer(CachedValues)
	
	If CachedValues = Undefined Then
		CachedValuesBatchProcessing =
			BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	Else
		CachedValuesBatchProcessing = Common.CopyRecursive(CachedValues);
	EndIf;
	
	For Each CurrentData In Object.ManufacturedProduct Do
		CurrentData.VATRate = Object.VATRate;
	EndDo;
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateVATAmount",  StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("FillInDuplicateDependentDetails", DependentDetails("ManufacturedProduct"));
	
	BatchProcessingOfTablePartServer.TreatTS(
		Object.ManufacturedProduct, StructureOfActions, CachedValuesBatchProcessing);
	
	SetVisibilityOfElementsByTaxationServer();
	CalculateOrderTotals(ThisObject);
	
EndProcedure

&AtServer
Procedure WhenChangingCurrencyServer(NewCurrency, RecalculateAmounts, CachedValues)
	
	FillInDefaultContract();
	
	If RecalculateAmounts Then
		ConvertDocumentAmountsToCurrency();
	EndIf;
	
	FillInSubordinatePropertiesForStatistics("Currency");
	
	ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisObject, "DocumentCurrency");
	
	DocumentCurrency = Object.Currency;
	
	UpdateAppointments();
	
EndProcedure

&AtServer
Procedure ConvertDocumentAmountsToCurrency()
	
	OldCurrency  = DocumentCurrency;
	NewCurrency   = Object.Currency;
	DocumentDate = ?(ValueIsFilled(Object.Date), Object.Date, CurrentSessionDate());
	LocalAccountingCurrency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Object.Organization);
	
	CourseStructures = ARAPAccountingServer.ExchangeRatesForTranslation(ThisObject, OldCurrency, NewCurrency, LocalAccountingCurrency, DocumentDate);
	StructureOfOldCurrencyRates = CourseStructures.StructureOfOldCurrencyRates;
	StructureOfNewCurrencyRates  = CourseStructures.StructureOfNewCurrencyRates;
	
	// Recalculation of amounts in products
	
	RecalculationParameters =
		PriceManagementSystem.ParametersForConvertingTableAmountsToCurrency(
			Object.PriceIncludesVAT,
			OldCurrency,
			NewCurrency,
			DocumentDate,
			LocalAccountingCurrency);
	
	PriceManagementSystem.ConvertTableAmountsToCurrency(Object.ManufacturedProduct, RecalculationParameters);
	
	TMCommonUse.FillInDuplicateDependentPropsInCollection(
		Object.ManufacturedProduct, DependentDetails("ManufacturedProduct"));
	
	// Recalculation of amounts in materials
	ConvertTabularAmountsToCurrency(
		Object.UsedMaterials, StructureOfOldCurrencyRates, StructureOfNewCurrencyRates);
	
	TMCommonUse.FillInDuplicateDependentPropsInCollection(
		Object.UsedMaterials, DependentDetails("UsedMaterials"));
	
	CalculateOrderTotals(ThisObject);
	
EndProcedure

&AtServer
Procedure ConvertTabularAmountsToCurrency(
			Table, Val StructureOfOldCurrencyRates, Val StructureOfNewCurrencyRates)
	
	AmountForAllocation = ProcessingOfExchangeRatesTM.ConvertAtRate(
							Table.Total("Sum"), StructureOfOldCurrencyRates, StructureOfNewCurrencyRates);
	
	ArrayOfAmounts = New Array;
	
	For X = 0 To Table.Count() - 1 Do
		
		CurRow = Table[X];
		
		CurRow.Price = ProcessingOfExchangeRatesTM.ConvertAtRate(
							CurRow.Price, StructureOfOldCurrencyRates, StructureOfNewCurrencyRates);
		
		AmountInNewCurrency = ProcessingOfExchangeRatesTM.ConvertAtRate(
							CurRow.Sum, StructureOfOldCurrencyRates, StructureOfNewCurrencyRates);
		
		ArrayOfAmounts.Add(AmountInNewCurrency);
		
	EndDo;
	
	ArrayOfAmounts = Common.DistributeAmountInProportionToCoefficients(AmountForAllocation, ArrayOfAmounts);
	
	If ArrayOfAmounts <> Undefined Then
		
		For X = 0 To Table.Count() - 1 Do
			
			CurRow = Table[X];
			CurRow.Sum = ArrayOfAmounts[X];
			
		EndDo;
		
	EndIf;
	
EndProcedure

&AtServer
Procedure WhenChangingVATTaxationServer(CachedValues)
	
	FillInVATRateOnServer(Undefined);
	
	SetVisibilityOfElementsByTaxationServer();
	
EndProcedure

&AtServer
Procedure WhenChangingWarehouseServer(TSName)
	
	StructureOfActions = New Structure;
	
	If TSName = "ManufacturedProduct" Then
		
		WarehouseGroup_ = Catalogs.Warehouses.ThisGroupAndWarehousesAreUsedByWHForSales(Object.Warehouse);
		Items.ManufacturedProductFillInTheWarehouse.Enabled = WarehouseGroup_;
		
		WarehousesServer.FillInWarehousesInTablePart(Object.Warehouse, WarehouseGroup_, Object.ManufacturedProduct, False);
		
		ProvisionInDocumentsServer.WhenChangingDocumentDetails(ThisObject);
		
		If Not WarehouseGroup_ Then
			Items.ProductsSenderGroup.Title = NStr("vi = 'Bộ phận-người gửi';
													|ru = 'Подразделение-отправитель';
													|en = 'Shipping business unit'; fa = 'واحد تجاری ارسال‌کننده';
													|it = 'Reparto-mittente';
													|pl = 'Shipping business unit';
													|tr = 'Gönderen departman'");
		Else
			Items.ProductsSenderGroup.Title = NStr("vi = 'Người gửi';
													|ru = 'Отправитель';
													|en = 'Shipper'; fa = 'فرستنده';
													|it = 'Mittente';
													|pl = 'Shipper';
													|tr = 'Gönderen'");
		EndIf;
		
	ElsIf TSName = "UsedMaterials" Then
		
		If QualityControl.UpdateActionParameters(Documents.MaterialProviderOrder2_5, Object, CacheQualityControl) Then
			AddQualityControlActionsToStructure(StructureOfActions, CacheQualityControl);
		EndIf;
		
		ReceivingWarehouseGroup =
			Catalogs.Warehouses.ThisGroupAndWarehousesAreUsedByWTCProcurementDocuments(Object.WarehouseForReceipt);
		Items.MaterialsFillTheWarehouse.Enabled = ReceivingWarehouseGroup;
		
		WarehousesServer.FillInWarehousesInTablePart(
			Object.WarehouseForReceipt, ReceivingWarehouseGroup, Object.UsedMaterials, False);
		
	EndIf;
	
	StructureOfActions.Insert("FillInShopPantryAttribute");
	StructureOfActions.Insert(
		"RecalculateNumberOfUnits", ProductionClientServer.ParametersForRecalculatingNumberOfUnits());
	
	ValuesInCache = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	
	BatchProcessingOfTablePartServer.TreatTS(Object[TSName], StructureOfActions, ValuesInCache);
	
	SetParametersForSelectingProductsWarehouse(TSName);
	
	WhenChangingWarehouseInTablePartServer(TSName);
	PrepareFillSetSeriesVisibility(TSName);
	
	UpdateVATTaxation_();
	
EndProcedure

&AtServer
Procedure WhenChangingCounterpartyServer()
	
	If ValueIsFilled(Object.Counterparty) Then
		
		FillInDefaultContract();
		SalesServer.PartnerOnChange(Object);
		
	EndIf;
	
	ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisObject, "Counterparty");
	
	If UseLinesOfBusiness Then
		LinesOfBusinessServer.FillInDefaultDirection(Object.LineOfBusiness,, Object.Contract);
	EndIf;
	FillInSubordinatePropertiesForStatistics("Counterparty");
	
	UpdateVATTaxation_();
	UpdateAppointments();
	
EndProcedure

&AtServer
Procedure BusinessOperationWhenChangingOnServer()
	
	// Clearing fields that are insignificant of operation
	Object.ProcessingService = Undefined;
	Object.VATRate           = Undefined;
	
	FillInDependentServiceAttributes("BusinessOperation");
	
	// We will delete the lines of manufactured products that do not match the type of item.
	If ManufacturedProductsProduced
			And Not WorksAreBeingCarriedOut
		Or Not ManufacturedProductsProduced
			And WorksAreBeingCarriedOut Then
		
		If Not Object.ManufacturedProduct.Count() = 0 Then
			
			ItemsTypes =
				Common.ObjectsAttributeValue(
					Object.ManufacturedProduct.Unload(, "Products").UnloadColumn("Products"),
					"ItemsType");
			
			BillOfMaterialsForProcessing = New Array;
			LinesToDelete = New Array;
			For Each CurrentData In Object.ManufacturedProduct Do
				If ManufacturedProductsProduced
						And ItemsTypes[CurrentData.Products] = Enums.ItemsTypes.Work_5
					Or WorksAreBeingCarriedOut
						And Not ItemsTypes[CurrentData.Products] = Enums.ItemsTypes.Work_5 Then
					LinesToDelete.Add(CurrentData);
					BillOfMaterialsForProcessing.Add(CurrentData.BillOfMaterials);
				EndIf;
			EndDo;
			
			For Each CurrentData In LinesToDelete Do
				Object.ManufacturedProduct.Delete(CurrentData);
			EndDo;
			
			// Delete the corresponding lines of materials
			If Not BillOfMaterialsForProcessing.Count() = 0 Then
				
				BillOfMaterialsForProcessing = CommonClientServer.CollapseArray(BillOfMaterialsForProcessing);
				For Each CurrentSpecification In BillOfMaterialsForProcessing Do
					
					FilterStructure1 = New Structure("BillOfMaterials", CurrentSpecification);
					If Object.ManufacturedProduct.FindRows(FilterStructure1).Count() = 0 Then
						For Each CurrentData In Object.UsedMaterials.FindRows(FilterStructure1) Do
							Object.UsedMaterials.Delete(CurrentData);
						EndDo;
					EndIf;
					
				EndDo;
				
			EndIf;
			
		EndIf;
		
		Object.Warehouse = Undefined;
		WhenChangingWarehouseServer("ManufacturedProduct");
		
	EndIf;
	
	// Update the type of production process
	Object.ProductionProcessType =
		TollingScheme.TypeOfProductionProcessOfOperation(Object.BusinessOperation);
	
	If Not Object.ProductionProcessType = TypeOfProductionProcessBeforeTheChange Then
		FillInSpecificationSelectionParameters();
	EndIf;
	
	FillInVATRateOnServer(Undefined);
	
	// Let's process the dependencies.
	ConfigureDependentFormElements(ThisObject, "BusinessOperation");
	ConfigureDependentFormElementsOnServer("BusinessOperation");
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

&AtServer
Procedure WhenOrganizationChangesServer(CachedValues)
	
	If ValueIsFilled(Object.Counterparty) Then
		
		FillInDefaultContract();
		
		If UseLinesOfBusiness Then
			
			LinesOfBusinessServer.FillInDefaultDirection(
				Object.LineOfBusiness,, Object.Contract);
			
		EndIf;
		
		UpdateAppointments();
		
	EndIf;
	
	CashServer.CheckFillInOrganizationSBankAccountByOwner(
		Object.Organization, Object.BankAccount, , Object.LineOfBusiness, Object.ForeignCurrencyTransaction);
		
	CashServer.CheckOrganizationSSalesRegisterByOwner(
		Object.Organization, Object.CashAccount, Object.PaymentMethod, Object.LineOfBusiness);
	
	FillInSubordinatePropertiesForStatistics("Organization");
	
	ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisObject, "Organization");
	
	UpdateVATTaxation_(True, CachedValues);
	
	ResponsiblePersonsServer.WhenChangingRelatedDocumentDetails(Object);
	
EndProcedure

&AtServer
Procedure WhenChangingDoNotShipServerInParts(ConsiderStateOfSoftware = False)
	
	// Calculate the maximum date of receipt and bring PM to it
	If Object.NotShipInInstallments Then
		
		Object.DateOfShipment = MaximumShipmentDate();
		
		FillInShippingDates(ThisObject, Object.DateOfShipment, Undefined);
		
		FillInVATRateOnServer(Undefined);
		
	EndIf;
	
	ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisObject, "ManufacturedProduct.DateOfShipment");
	
	SetVisibilityOfShippingDateFormElements();
	
EndProcedure

&AtServer
Procedure IfYouChangeReceiptOneDateServer()
	
	// Calculate the maximum date of receipt and bring PM to it
	If Object.OneDateReceipt Then
		
		Object.DateOfReceipt = MaximumReceiptDate();
		FillIn_ReceiptDates(Object.DateOfReceipt, Undefined);
		
	EndIf;
	
	If QualityControl.UpdateActionParameters(Documents.MaterialProviderOrder2_5, Object, CacheQualityControl) Then
		StructureOfActions = New Structure();
		AddQualityControlActionsToStructure(StructureOfActions, CacheQualityControl);
		BatchProcessingOfTablePartServer.TreatTS(Object.UsedMaterials, StructureOfActions);
	EndIf;
	
	SetVisibilityOfReceiptDateFormElements();
	
EndProcedure

&AtServer
Procedure DateOfReceiptOnChangeATServer()
	
	FillIn_ReceiptDates(Object.DateOfReceipt, Undefined);
	
	If QualityControl.UpdateActionParameters(Documents.MaterialProviderOrder2_5, Object, CacheQualityControl) Then
		StructureOfActions = New Structure();
		AddQualityControlActionsToStructure(StructureOfActions, CacheQualityControl);
		BatchProcessingOfTablePartServer.TreatTS(Object.UsedMaterials, StructureOfActions);
	EndIf;
	
EndProcedure

&AtServer
Procedure WhenChangingDateServer()
	
	UpdateVATTaxation_();
	FillInVATRateOnServer(Undefined);
	
	ResponsiblePersonsServer.WhenChangingRelatedDocumentDetails(Object);
	
	ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisObject, "Date");
	
EndProcedure

&AtServer
Procedure WhenChangingWarehouseInTablePartServer(TabSectionName = "", UpdateColumnAvailable = True)
	
	If Not TabSectionName = "ManufacturedProduct" Then
		
		WarehousesServer.WhenChangingWarehouseInTablePart(
			Object.UsedMaterials, ReceivingWarehousesTable, ReceivingWarehouseGroup);
		
		TotalWarehouses_ = ReceivingWarehousesTable.Count();
		WarehousesClientServer.UpdateWarehouseGroupImage(
			LabelMultipleWarehousesReceipts, Items.ThePictureOfTheWarehouseReceipt, TotalWarehouses_);
		
		If UpdateColumnAvailable Then
			UpdateColumnAvailableServer();
		EndIf;
		
	EndIf;
	
	If Not TabSectionName = "UsedMaterials" Then
		
		WarehousesServer.WhenChangingWarehouseInTablePart(Object.ManufacturedProduct, WarehouseTable, WarehouseGroup_);
		
		TotalWarehouses_ = WarehouseTable.Count();
		WarehousesClientServer.UpdateWarehouseGroupImage(
			SeveralWarehousesText, Items.PictureMultipleWarehouses, TotalWarehouses_);
		
	EndIf;
	
EndProcedure

&AtServer
Procedure LineOfBusinessOnChangeServer()
	
	UpdateVATTaxation_();
	UpdateAppointments();
	
	ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisObject, "LineOfBusiness");
	
EndProcedure

&AtServer
Procedure DateOfApprovalWhenServerWasChanged()
	
	ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisObject, "ApprovalDate");
	
EndProcedure

&AtServer
Procedure DateOfShipmentOnChangeServer()
	
	FillInShippingDates(ThisObject, Object.DateOfShipment, Undefined);
	
	FillInVATRateOnServer(Undefined);
	
	ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisObject, "ManufacturedProduct.DateOfShipment");
	
EndProcedure

&AtClient
Procedure CheckAvailabilityOfOrdersAccordingToGiver(NumberAccordingToPartnerData)
	
	OrderList = GiverSOrdersWithSameIncomingNumber(Object.Ref, Object.Counterparty, NumberAccordingToPartnerData);
	
	If OrderList.Count() > 0 Then
		
		ButtonsList = New ValueList;
		
		If OrderList.Count() = 1 Then
			QueryText = NStr(
				"vi = 'Trong cơ sở thông tin đã tồn tại đơn hàng có cùng số thứ tự như vậy theo dữ liệu của người đặt gia công. Tiếp tục?';
				|ru = 'В информационной базе уже существует заказ с таким же номером по данным давальца. Продолжить?';
				|en = 'Order with such number by data of the material provider already exists. Continue?'; fa = 'Order with such number by data of the material provider already exists. Continue?';
				|it = 'Nel database informatico esiste già un ordine con stesso numero in base ai dati del committente. Continuare?';
				|pl = 'W bazie informacyjnej już istnieje zamówienie o takim samym numerze według danych właściciela surowców. Kontynuować?';
				|tr = 'Aynı sağlayıcı numarasına sahip bir sipariş veritabanında zaten mevcut. Devam edilsin mi?'");
			ButtonsList.Add("OpenOrderList", NStr("vi = 'Mở đơn hàng';
													|ru = 'Открыть заказ';
													|en = 'Open order'; fa = 'Open order';
													|it = 'Aprire ordine';
													|pl = 'Otwórz zamówienie';
													|tr = 'Sipariş aç'"));
		Else
			QueryText = NStr(
				"vi = 'Trong cơ sở thông tin đã tồn tại đơn hàng có cùng số thứ tự như vậy theo dữ liệu của người đặt gia công. Tiếp tục?';
				|ru = 'В информационной базе уже существуют заказы с таким же номером по данным давальца. Продолжить?';
				|en = 'Orders with such number by data of the material provider already exist. Continue?'; fa = 'Orders with such number by data of the material provider already exist. Continue?';
				|it = 'Nel database informatico esistono già gli ordini con stesso numero in base ai dati del committente. Continuare?';
				|pl = 'W bazie informacyjnej już istnieją zamówienia o takim samym numerze według danych właściciela surowców. Kontynuować?';
				|tr = 'Aynı sağlayıcı numarasına sahip bir siparişler veritabanında zaten mevcut. Devam edilsin mi?'");
			ButtonsList.Add("OpenOrderList", NStr("vi = 'Mở danh sách đơn hàng';
													|ru = 'Открыть список заказов';
													|en = 'Open order list'; fa = 'باز کردن فهرست سفارش‌ها';
													|it = 'Aprire elenco ordini';
													|pl = 'Otwórz listę zamówień';
													|tr = 'Sipariş listesini aç'"));
		EndIf;
		
		ButtonsList.Add("Continue", NStr("vi = 'Tiếp tục';
										|ru = 'Продолжить';
										|en = 'Continue'; fa = 'ادامه';
										|it = 'Continuare';
										|pl = 'Continue';
										|tr = 'Devam'"));
		
		ShowQueryBox(
			New CallbackDescription(
					"CheckAvailabilityOfOrdersAccordingToGiverCompletion",
					ThisObject,
					New Structure("OrderList", OrderList)),
			QueryText,
			ButtonsList);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure CheckAvailabilityOfOrdersAccordingToGiverCompletion(QuestionResult, AdditionalParameters) Export
	
	OrderList = AdditionalParameters.OrderList;
	
	UserAnswer = QuestionResult;
	
	If UserAnswer = "OpenOrderList" Then
	
		If OrderList.Count() > 1 Then
	
			FormParameters = New Structure;
			FormParameters.Insert("DocumentsList", OrderList);
			FormParameters.Insert("Title", NStr("vi = 'Đơn hàng của bên đặt gia công (%DocumentsCount%)';
												|ru = 'Заказы давальцев (%DocumentsCount%)';
												|en = 'Subcontracting sales orders (%DocumentsCount%)'; fa = 'Subcontracting sales orders (%DocumentsCount%)';
												|it = 'Ordini dei prestatori (%DocumentsCount%)';
												|pl = 'Zamówienia właścicieli surowca (%DocumentsCount%)';
												|tr = 'Sağlayıcı siparişleri (%DocumentsCount%)'"));
	
			OpenForm("CommonForm.ViewingListOfDocuments", FormParameters);
	
		Else
	
			FormParameters = New Structure("Key", OrderList.Get(0).Value);
			OpenForm("Document.MaterialProviderOrder2_5.ObjectForm", FormParameters);
	
		EndIf;
	
	EndIf;
	
EndProcedure

#EndRegion

#Region ManufacturedProduct

&AtServer
Procedure SoftwareProductsWhenModifiedOnServer(FillParameters)
	
	Changes = ProvisionInDocumentsServer.SupplyOptionOnChange(
		ThisObject,
		Items.ManufacturedProduct.CurrentRow);
		
	Mode = ProvisionInDocumentsClientServer.ModeSelectActionDirectly();
	AfterFillingOutCollateral(Changes, Mode, FillParameters);
	
EndProcedure

&AtClient
Procedure ProductionCollateralOptionWhenChangedAfterIssue(Response, AdditionalParameters) Export
	
	FillParameters = ProvisionInDocumentsClient.ParametersForProcessingShipmentDatesAfterFillingInCollateral(Response);
	SoftwareProductsWhenModifiedOnServer(FillParameters);
	
EndProcedure

&AtServer
Procedure ManufacturedProductBeforeEditEndServer(CacheLines, CachedValues)
	
	CurrentRow = Object.ManufacturedProduct.FindByID(Items.ManufacturedProduct.CurrentRow);
	FillPropertyValues(CurrentRow, CacheLines, "Products, Characteristic, BillOfMaterials");
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateNumberOfUnits");
	StructureOfActions.Insert("CheckCharacteristicsByOwner", 	CurrentRow.Characteristic);
	StructureOfActions.Insert("CheckFillPackageByOwner", CurrentRow.Package);
	StructureOfActions.Insert("FillInSalePrice", 					BatchProcessingOfTablePartClientServer.ParametersForFillingInPriceInTSLine(Object));
	StructureOfActions.Insert("RecalculateVATAmount", 					StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", 					StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmount", 						"NumberOfPackages");
	StructureOfActions.Insert("FillInDuplicateDependentDetails", DependentDetails("ManufacturedProduct"));
	StructureOfActions.Insert("FillInArticleAttribute", 				New Structure("Products", "SKU"));
	StructureOfActions.Insert("FillInProductTypeAttribute_", 		New Structure("Products", "ItemsType"));
	StructureOfActions.Insert("CheckSeriesCalculateStatus",
		New Structure("Warehouse, SeriesSpecificationParameters", CurrentRow.Warehouse, SeriesSpecificationParameters.ManufacturedProduct));
	AddCollateralActionsOnServer(StructureOfActions, "SupplyOption,WarehouseIsRequired,DateOfShipmentRequired_");
	
	StructureOfSpecificationFilling = ProductDataManagementClientServer.ActionParametersCheckFillSpecification(
		Object, CurrentRow, BOMSelectionParameters);
	StructureOfActions.Insert("CheckFillSpecification", StructureOfSpecificationFilling);
	
	BatchProcessingOfTablePartServer.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
EndProcedure

&AtServer
Procedure ManufacturedProductWarehouseOnChangeServer(RowID)
	
	CurrentRow = Object.ManufacturedProduct.FindByID(RowID);
	StructureOfActions = New Structure;
	StructureOfActions.Insert("CheckSeriesCalculateStatus",
		New Structure("Warehouse, SeriesSpecificationParameters", CurrentRow.Warehouse, SeriesSpecificationParameters.ManufacturedProduct));
	StructureOfActions.Insert("FillInShopPantryAttribute");
	StructureOfActions.Insert(
		"RecalculateNumberOfUnits", ProductionClientServer.ParametersForRecalculatingNumberOfUnits());
	BatchProcessingOfTablePartServer.ProcessTSString(CurrentRow, StructureOfActions, Undefined);
	
	WhenChangingWarehouseInTablePartServer("ManufacturedProduct");
	
	UpdateColumnAvailableServer();
	
EndProcedure

#EndRegion

#EndRegion

#Region ServiceEventHandlersOfForm

&AtServer
Procedure OnReadCreateAtServer()
	
	UseSimplifiedPaymentScheme   = GetFunctionalOption("UseSimplifiedPaymentSchemeInSales");
	UsePaymentSchedules           = GetFunctionalOption("UsePaymentSchedules");
	
	UseLinesOfBusiness = GetFunctionalOption("UseIncomeAccountingByLinesOfBusiness");
	UseSeveralWarehouses        = GetFunctionalOption("UseSeveralWarehouses");
	
	SecurityOptionAndFlagSeparately =
		ProvisionInDocumentsClientServer.ProvisionOptionAndFlagAreSeparateByDefault(True);
	
	UseStatuses = GetFunctionalOption("UseStatusesOfMaterialProviderOrders2_5");
	
	UseReasonsForSalesOrderCancellations = GetFunctionalOption("UseReasonsForSalesOrderCancellations");
	
	ReadPriceTypeRight =
		AccessRight("View", Metadata.Documents.MaterialProviderOrder2_5.TabularSections.ManufacturedProduct.Attributes.PriceKind);
	
	AttributeSelectionParameters =
		PaymentStepsServer.ParametersForSelectingPaymentDetails(Metadata.Documents.MaterialProviderOrder2_5);
	
	CacheQualityControl = QualityControl.DataCacheOfMechanism(Object);
	
	Items.StatusGroup.Visible      = UseStatuses;
	Items.Basis.Visible = ValueIsFilled(Object.Basis);
	Items.CloseOrder.Enabled    = AccessRight("Update", Metadata.Documents.MaterialProviderOrder2_5);
	
	Items.ProductsGroupCanceled.Visible                      = UseReasonsForSalesOrderCancellations;
	Items.ProductsCancelledReasonsForCancellationAreNotUsed.Visible = Not UseReasonsForSalesOrderCancellations;
	
	DocumentCurrency = Object.Currency;
	
	PriceTypeMaterialsBeforeChanges = Object.PriceTypeMaterials;
	
	WarehouseGroup_ = Catalogs.Warehouses.ThisGroupAndWarehousesAreUsedByWHForSales(Object.Warehouse);
	Items.ManufacturedProductFillInTheWarehouse.Enabled = WarehouseGroup_;
	SetParametersForSelectingProductsWarehouse("ManufacturedProduct");
	
	ReceivingWarehouseGroup =
		Catalogs.Warehouses.ThisGroupAndWarehousesAreUsedByWTCProcurementDocuments(Object.WarehouseForReceipt);
	Items.MaterialsFillTheWarehouse.Enabled = ReceivingWarehouseGroup;
	
	If Not GetFunctionalOption("UseBusinessUnits") Then
		Items.ManufacturedProductDepartment.Visible = False;
	ElsIf Not WarehouseGroup_ Then
		Items.ManufacturedProductDepartment.Title = NStr("vi = 'Bộ phận-người gửi';
														|ru = 'Подразделение-отправитель';
														|en = 'Shipping business unit'; fa = 'واحد تجاری ارسال‌کننده';
														|it = 'Reparto-mittente';
														|pl = 'Shipping business unit';
														|tr = 'Gönderen departman'");
	EndIf;
	
	PriceTypeSelectionParameters = SettingsValueCached.ParametersForSelectingDefaultPriceType();
	PriceTypeSelectionParameters.PriceIncludesVAT                          = Object.PriceIncludesVAT;
	PriceTypeSelectionParameters.UseWhileTransferringProductsToMaterialProvider = True;
	PriceTypeSelectionParameters.Status                                   = Enums.StatusesOfPriceTypeValidity.Valid;
	
	DefaultPriceType = SettingsValueCached.DefaultPriceType(PriceTypeSelectionParameters);
	
	SetParametersForSelectingProductsWarehouse("UsedMaterials");
	
	TMCommonUse.FillInDuplicateDependentPropsInCollection(
		Object.ManufacturedProduct, DependentDetails("ManufacturedProduct"));
		
	TMCommonUse.FillInDuplicateDependentPropsInCollection(
		Object.UsedMaterials , DependentDetails("UsedMaterials"));
	
	RefreshStatusServer();
	UpdateTextDocumentsBasedOn();
	
	CalculateOrderTotals(ThisObject);
	SeriesSpecificationParameters =
		New FixedStructure(ProductsServer.SeriesSpecificationParameters(Object, Documents.MaterialProviderOrder2_5));
	
	Items.ManufacturedProductSeries.Visible = SeriesSpecificationParameters.ManufacturedProduct.UseItemsBatch;
	Items.UsedMaterialsSeries.Visible = SeriesSpecificationParameters.UsedMaterials.UseItemsBatch;
	EstablishAvailabilityOfBatchesOfRepairedFinishedProduct();
	
	SetVisibilityOfShippingDateFormElements();
	SetVisibilityOfReceiptDateFormElements();
	
	GoodsDelivery.WhenReadingCreatingOrdersOnServer(Items, Object);
	VisibilityOfDeliveryPage = Items.DeliveryPage.Visible;
	
	FillInSpecificationSelectionParameters();
	
	FillInServiceDetails();
	FillInDependentServiceAttributes();
	FillInServiceDetailsOfTableParts();
	WhenChangingWarehouseInTablePartServer(, False);
	
	UpdateVATTaxation_(False);
	
	SetVisibilityOfShipmentBanToPartner();
	
	ProcessingOfTabularForms.InitializeRowCache(Items.ManufacturedProduct);
	ProcessingOfTabularForms.InitializeRowCache(Items.UsedMaterials);
	
	FillInServiceDetailsOfSupply();
	CustomizeFormElements();
	ConfigureDependentFormElements(ThisObject);
	ConfigureDependentFormElementsOnServer();
	
	SetSoftwareVisibility();
	
EndProcedure

// StandardSubsystems.Properties

&AtServer
Procedure PropertiesExecuteDeferredInitialization()
	PropertyManager.FillAdditionalAttributesInForm(ThisObject);
EndProcedure

&AtClient
Procedure UpdateAdditionalAttributesDependencies()
	PropertyManagerClient.UpdateAdditionalAttributesDependencies(ThisObject);
EndProcedure

// End StandardSubsystems.Properties

&AtServer
Procedure UpdateAdditionalAttributesItems()
	
	PropertyManager.UpdateAdditionalAttributesItems(ThisObject);
	
EndProcedure

#EndRegion

#Region ServiceEventHandlersForFormHeaderElements

&AtClient
Procedure LabelPaymentStagesClickCompletion(Result, AdditionalParameters) Export
	If Result <> Undefined Then
		ChangedBankingDetails = Result.OldValuesOfChangedProps;
		ReflectChangesToPaymentRules(ChangedBankingDetails);
	EndIf;
EndProcedure

&AtClient
Procedure BusinessOperationOnChangeCompletion(QuestionResult, AdditionalParameters) Export
	
	If Not QuestionResult = DialogReturnCode.Yes Then
		Object.BusinessOperation = BusinessTransactionBeforeTheChange;
		Return;
	EndIf;
	
	BusinessOperationWhenChangingOnServer();
	
	If Not Object.ProductionProcessType = TypeOfProductionProcessBeforeTheChange Then
		CheckFillInBillOfMaterialsInManufacturingProductLines(Undefined);
	EndIf;
	
	TypeOfProductionProcessBeforeTheChange = Object.ProductionProcessType;
	
	BusinessTransactionBeforeTheChange = Object.BusinessOperation;
	
EndProcedure

#Region ManufacturedProduct

#Region Supply

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

&AtClient
Procedure HyperlinkStateOfProvisionClickGeneral()
	
	FormParameters = ProvisionInDocumentsClient.SecurityStatusHyperlinkClick(ThisObject);
	
	If Object.Status = PredefinedValue("Enum.StatusesOfMaterialProviderOrders.NotApproved") Then
		
		FormParameters.AcceptableSecurityOptions = ProvisionInDocumentsClient.AllValidSecurityOptions();
		FormParameters.AcceptableSecurityOptions.Delete(
			PredefinedValue("Enum.SupplyOptions.FromWarehouse"));
		
	EndIf;
	
	If FormParameters.ContextOfUse = "TABLE" Then
		
		FormParameters.AddressOfTheMovementTable = AddressOfMovementTableInRepository();
		
	EndIf;
	
	OpenForm("DataProcessor.OrderSupplyForecast.Form", FormParameters, ThisObject, UUID,,,,
		FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

#EndRegion

#EndRegion

#EndRegion

#Region ServiceEventHandlersForTableElementsOfProductsForm

&AtClient
Procedure ManufacturedProductBeforeEditEndCompletion(Result, AdditionalParameters) Export
	
	If Result = DialogReturnCode.No Then
		
		ManufacturedProductBeforeEditEndServer(AdditionalParameters.LineCache, CachedValues);
		
		ProvisionInDocumentsClientServer.FillInServiceDetails(Object.ManufacturedProduct, DateOfShipmentRequired_, WarehouseIsRequired);
		
		Return;
		
	EndIf;
	
	CleanMaterialsAccordingToSpecifications(Object.UsedMaterials, AdditionalParameters.SpecificationsForRemoval);
	UpdateSpecificationSelectionList(Items, Object.ManufacturedProduct);
	CalculateOrderTotals(ThisObject);
	
EndProcedure

&AtClient
Procedure ManufacturedProductBeforeDeleteRowCompletion(Result, Var_Parameters) Export
	
	If Result = DialogReturnCode.No Then
		Return;
	EndIf;
	
	For Each IDOfRowToDelete In Var_Parameters.IDOfRowsToDelete Do
		Object.ManufacturedProduct.Delete(Object.ManufacturedProduct.FindByID(IDOfRowToDelete));
	EndDo;
	
	UpdateSpecificationSelectionList(Items, Object.ManufacturedProduct);
	
	CleanMaterialsAccordingToSpecifications(Object.UsedMaterials, Var_Parameters.SpecificationsForRemoval);
	
EndProcedure

&AtServer
Procedure ManufacturedProductProductsOnChangeServer(CachedValues)
	
	CurrentRow = Object.ManufacturedProduct.FindByID(Items.ManufacturedProduct.CurrentRow);
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateNumberOfUnits", 			ProductionClientServer.ParametersForRecalculatingNumberOfUnits());
	StructureOfActions.Insert("CheckCharacteristicsByOwner", 	CurrentRow.Characteristic);
	StructureOfActions.Insert("CheckFillWarehouse", 				ParametersForFillingWarehouseInLine("ManufacturedProduct"));
	StructureOfActions.Insert("CheckFillPackageByOwner", CurrentRow.Package);
	StructureOfActions.Insert("FillInSalePrice", 					BatchProcessingOfTablePartClientServer.ParametersForFillingInPriceInTSLine(Object));
	StructureOfActions.Insert("RecalculateVATAmount", 					StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", 					StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmount", 						"NumberOfPackages");
	StructureOfActions.Insert("FillInDuplicateDependentDetails", DependentDetails("ManufacturedProduct"));
	StructureOfActions.Insert("FillInArticleAttribute", 				New Structure("Products", "SKU"));
	StructureOfActions.Insert("FillInProductTypeAttribute_", 		New Structure("Products", "ItemsType"));
	StructureOfActions.Insert("CheckSeriesCalculateStatus",
		New Structure("Warehouse, SeriesSpecificationParameters", CurrentRow.Warehouse, SeriesSpecificationParameters.ManufacturedProduct));
	
	AddCollateralActionsOnServer(StructureOfActions, "SupplyOption,WarehouseIsRequired,DateOfShipmentRequired_");
	
	StructureOfActions.Insert("FillInShopPantryAttribute");	
	
	StructureOfSpecificationFilling = ProductDataManagementClientServer.ActionParametersCheckFillSpecification(
		Object, CurrentRow, BOMSelectionParameters);
	StructureOfActions.Insert("CheckFillSpecification", StructureOfSpecificationFilling);
	
	AddActionsClearFillArticleAnalytics(StructureOfActions, ThisObject);
	
	If VATRateIsIndicatedInTablePart(Object.BusinessOperation) Then
		AddActionToStructureFillInVATRate(Object, StructureOfActions);
	EndIf;
	
	BatchProcessingOfTablePartServer.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
	UpdateColumnAvailableServer();
	
EndProcedure

&AtServer
Procedure ManufacturedProductsAfterRemovalATServer(ThereIsChangeInShippingDates)
	
	UpdateColumnAvailableServer();
	If ThereIsChangeInShippingDates Then
		ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisObject, "ManufacturedProduct.DateOfShipment");
	EndIf;
	
EndProcedure

&AtServer
Procedure ManufacturedProductsCancelledOnChangeAtServer()
	
	ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisObject, "ManufacturedProduct.DateOfShipment");
	
EndProcedure

#EndRegion

#Region ServiceEventHandlersForTableElementsFormsMaterials

&AtServer
Procedure ProductListMaterialsWhenChanged(RowID, StructureOfActions, CachedValues)

	CurrentRow = Object.UsedMaterials.FindByID(RowID);
	BatchProcessingOfTablePartServer.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
EndProcedure

&AtServer
Procedure MaterialsSetActionInLinesOnServer(Action, Val RowsIDs, CachedValues)
	
	If CachedValues = Undefined Then
		CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	EndIf;
	
	RowsToProcess = New Array;
	For Each RowID In RowsIDs Do
		
		CurrentData = Object.UsedMaterials.FindByID(RowID);
		
		// DisplayFilters
		
		CurrentData.Action = Action;
		MaterialsWhenChangingActionInLine(ThisObject, CurrentData);
		
		RowsToProcess.Add(CurrentData);
		
	EndDo;
	
	StructureOfActions = New Structure;
	
	StructureOfActions.Insert(
		"CheckSeriesCalculateStatus",
		New Structure("Warehouse, SeriesSpecificationParameters, TableOfGoods",
			Object.WarehouseForReceipt, SeriesSpecificationParameters.UsedMaterials, RowsToProcess));
	
	If Action = PredefinedValue("Enum.ActionsOnMaterialsToSubcontract.AcceptVMI") Then
		
		StructureOfActions.Insert(
			"FillInPurchasePrice",
			BatchProcessingOfTablePartClientServer.GetStructureForFillingInPurchasePriceInTSLine(Object, "PriceTypeMaterials"));
		StructureOfActions.Insert("RecalculateAmount");
		
	EndIf;
	
	AddActionsToStructureWhenYouChangeActionInContentLine(ThisObject, Undefined, StructureOfActions);
	AddQualityControlActionsToStructure(StructureOfActions, CacheQualityControl);
	
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		RowsToProcess,
		StructureOfActions,
		Object.UsedMaterials,
		CachedValues);
	
EndProcedure

&AtClientAtServerNoContext
Procedure MaterialsWhenChangingActionInLine(Form, RowData)
	
	If RowData.Action = PredefinedValue("Enum.ActionsOnMaterialsToSubcontract.UseAvailable") Then
		RowData.DateOfReceipt = Date(1, 1, 1);
		RowData.Price            = 0;
		RowData.Sum           = 0;
	Else
		If Form.Object.OneDateReceipt Then
			RowData.DateOfReceipt = Form.Object.DateOfReceipt;
		EndIf;
	EndIf;
	
EndProcedure

#EndRegion

#Region ServiceHandlersForFormCommands

#Region Header

&AtClient
Procedure CloseOrderFragment(Result = Undefined, AdditionalParameters = Undefined) Export
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.TimeMeasurement(
		"Document.MaterialProviderOrder2_5.DocumentForm.Command.CloseOrderFragment");
	
	ListOfOrdersToClose = New ValueList;
	ListOfOrdersToClose.Add(Object.Ref);
	
	ClosureStructure = New Structure;
	ClosureStructure.Insert("Orders",                       ListOfOrdersToClose);
	ClosureStructure.Insert("DocumentInitiator",            Object.Ref);
	ClosureStructure.Insert("CancelUnprocessedLines", True);
	ClosureStructure.Insert("CloseOrders",              True);
	
	OpenForm(
		"DataProcessor.OrderClosureWizard.Form.ClosureForm",
		ClosureStructure,
		ThisObject,,,,,
		FormWindowOpeningMode.LockOwnerWindow);
	
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

&AtServer
Procedure PaymentCreditedServer(EventName, Parameter, Source)
	
	RefreshStatusServer();
	
	// ARAPAccounting
	ARAPAccountingFormWork.NotificationProcessing(ThisObject, EventName, Parameter);
	// End ARAPAccounting
	
EndProcedure

#EndRegion

#Region ManufacturedProduct

&AtClient
Procedure ManufacturedProductFillInTheWarehouseCompletion(Result, AdditionalParameters) Export
	
	SelectedRows = AdditionalParameters.SelectedRows;
	
	SelectedWarehouse = Result;
	
	If ValueIsFilled(SelectedWarehouse) Then
	
		FilledWithRows = FillWarehouseInSelectedLinesOnServer(SelectedRows, SelectedWarehouse, "ManufacturedProduct");
	
		WarehousesClient.ShowNotificationAboutFillingOfWarehouseInTablePart(
			SelectedWarehouse, FilledWithRows, SelectedRows.Count());
	
	EndIf;
	
	WhenChangingWarehouseInTablePartServer("ManufacturedProduct");

EndProcedure

&AtClient
Procedure ProductsFillDivisionCompletion(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	SalesClient.ProcessingUnitSelection(Object.ManufacturedProduct, Items.ManufacturedProduct.SelectedRows, Result);
	
EndProcedure

&AtClient
Procedure ManufacturedProductFillInRecipientCompletion(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	TSStrings = AdditionalParameters.TSStrings;
	For Each TableRow In TSStrings Do
		TableRow.Recipient = Result;
	EndDo;
	
	ShowUserNotification(
		NStr("vi = 'Đã điền người nhận';
			|ru = 'Получатель заполнен';
			|en = 'Recipient is filled in'; fa = 'Recipient is filled in';
			|it = 'Il destinatario è compilato';
			|pl = 'Odbiorca wypełniony';
			|tr = 'Alıcı girildi'"),,
		NStr("vi = 'Đối với các dòng được chọn đã điền người nhận';
			|ru = 'Для выделенных строк выполнено заполнение получателя';
			|en = 'Recipients are filled in for the selected lines'; fa = 'Recipients are filled in for the selected lines';
			|it = 'Per le righe selezionata è stata eseguita la compilazione del destinatario';
			|pl = 'Dla wybranych wierszy wykonano wypełnienie odbiorcy';
			|tr = 'Seçili satırlar için alıcı dolduruldu'"),
		PictureLib.Information32);
	
EndProcedure

&AtClient
Procedure ManufacturedProductFillInPricesByPriceKindCompletion(PricesKind, AdditionalParameters) Export
	
	If ValueIsFilled(PricesKind) Then
		
		PricesCalculated = FillInPricesByPriceKindServer(PricesKind, True, CachedValues);
		SalesClient.NotifyAboutEndOfFillingInPricesByTypeOfPrices(PricesCalculated, PricesKind);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ProductsDownloadFromTSDCompletion(Result, Var_Parameters) Export
	
	If Result.Result Then
		TSName = ?(Items.GroupPages.CurrentPage = Items.UsedMaterials, "UsedMaterials", "ManufacturedProduct");
		ProcessBarcodes(Result.TableOfGoods, TSName, Items[TSName]);
	Else
		EquipmentManagerTMClient.ReportError(Result);
	EndIf;
	
EndProcedure

&AtClient
Procedure SearchByBarcodeCompletion(BarcodeData_2, AdditionalParameters) Export
	
	ProcessBarcodes(BarcodeData_2, "ManufacturedProduct", Items.ManufacturedProduct);
	
EndProcedure

&AtClient
Procedure ManufacturedProductSplitRowCompletion(NewRow, AdditionalParameters) Export 
	
	CurrentRow = Items.ManufacturedProduct.CurrentData;
	
	If NewRow <> Undefined Then
		
		NewRow.RowCode = 0;
		
		StructureOfActions = New Structure;
		AddActionsToStructureWhenChangingNumberOfProductPackages(StructureOfActions, Object);
		
		BatchProcessingOfTablePartClient.ProcessTSString(
			CurrentRow, StructureOfActions, CachedValues);
			
		AddCollateralActionsOnClient(StructureOfActions, "UpdateProductCache_");
		
		BatchProcessingOfTablePartClient.ProcessTSString(
			NewRow, StructureOfActions, CachedValues);
			
		SetKeysInProductLines(Items, Object, NewRow);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ProductsFillInTheMainSpecification_3Completion(Result, AdditionalParameters) Export
	
	If Result = DialogReturnCode.No Then
		Return;
	EndIf;
	
	FillInMainSpecificationEnd(AdditionalParameters);
	
EndProcedure

#Region Supply

&AtClient
Procedure ProductsToProvide(Command)
	
	ProvidingSetActionWithQuestion("ACTION_COOPERATION");
	
EndProcedure

&AtClient
Procedure ProductsDoNotProvide(Command)
	
	ProvidingSetActionWithQuestion("ACTION_NOTABLE");
	
EndProcedure

&AtClient
Procedure ProductsToShip(Command)
	
	ProvidingSetActionWithQuestion("ACTION_LOAD");
	
EndProcedure

&AtClient
Procedure ProductsToReserve(Command)
	
	ProvidingSetActionWithQuestion("ACTION_RESERVE");
	
EndProcedure

&AtClient
Procedure ReserveProductsAsTheyArrive(Command)
	
	ProvidingSetAction("ACTION_RESERVATION_REFERENCES");
	
EndProcedure

&AtClient
Procedure CreateAnAssignmentAdjustmentCompletion(QuestionResult, AdditionalParameters) Export
	
	Response = QuestionResult;
	If Response = DialogReturnCode.No Then
		Return;
	Else
		Write(New Structure("WriteMode", DocumentWriteMode.Posting));
	EndIf;
	
	ThereAreGoodsToSeparateProvision = ThereAreGoodsToSeparateProvision();
	
	If ThereAreGoodsToSeparateProvision And Object.Posted And Not Modified Then
		
		// If the document is recorded for the first time, there is an empty link in the Base object, you need to update it.
		ObjectsOfBases = New Array();
		ObjectsOfBases.Add(Object.Ref);
		
		AdditionalParameters.CommandDetails.Insert("ObjectsOfBases", ObjectsOfBases);
		
		If AdditionalParameters.Reservation Then
			GenerationByReferenceTMClient.OpenBackupWizard(AdditionalParameters.CommandDetails);
		Else
			GenerationByReferenceTMClient.OpenReserveWithdrawalWizard(AdditionalParameters.CommandDetails);
		EndIf;
		
	ElsIf Not ThereAreGoodsToSeparateProvision And Object.Posted  Then
		ErrorText = NStr("vi = 'Không có hàng hóa cần phải được cung cấp';
						|ru = 'Нет ни одного товара который требуется обеспечить';
						|en = 'There is no item to provide'; fa = 'There is no item to provide';
						|it = 'Non ci sono prodotti da approvvigionare';
						|pl = 'Nie ma ani jednego towaru który należy zapewnić';
						|tr = 'Teminat altına alınması gereken tek bir öğe yoktur'");
		ShowMessageBox(, ErrorText);
	EndIf;
	
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
Procedure ProvidingSetActionWithQuestion(ActionCode, SelectedRows = Undefined)
	
	Result = ProvidingSetAction(ActionCode, SelectedRows);
	
	QuestionAsked = ProvisionInDocumentsClient.ShowIssueOfFillingSoftwareWithWholePackages(
		ThisObject,
		Object.ManufacturedProduct,
		Result,
		"AfterQuestionOfFillingPackageWithWholePackages");
		
	If Not QuestionAsked Then
		
		ProvisionInDocumentsClient.ShowQuestionUncheckShipByOneDate(
			ThisObject,
			Object.ManufacturedProduct,
			Result,
			"AfterQuestionRemoveFlagShipByOneDate");
			
	EndIf;
	
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
Function ProvidingSetAction(ActionCode, SelectedRows = Undefined)
	
	Result = ProvisionInDocumentsServer.ProvidingSetActionResultStructure();
	
	Changes = ProvisionInDocumentsServer.SetAction(
		ActionCode,
		ThisObject,
		?(ValueIsFilled(SelectedRows), SelectedRows, Items.ManufacturedProduct.SelectedRows));
		
		FillPropertyValues(Result, Changes);
		
		If Changes.ChangesTable <> Undefined Then
			AfterFillingOutCollateral(
				Changes.ChangesTable,
				ProvisionInDocumentsClientServer.ActionSelectionMode(),
				Result);
		EndIf;
		
	Return Result;
	
EndFunction

&AtServer
Function ProcessWarehouseAndBatchSelectionOnServer(ValueSelected, FormParameters, FillParameters)
	
	Modified = True;
	Changes = ProvisionInDocumentsServer.WhenChoosingWarehouse(
		ValueSelected,
		ThisObject,
		Items.ManufacturedProduct.CurrentRow,
		FormParameters.FieldsToFillIn);
		
	AfterFillingOutCollateral(Changes, FormParameters.Mode, FillParameters);
	TextProcessedLines = ProvisionInDocumentsServer.TextProcessedLines(Changes.Count());
	Return TextProcessedLines;
	
EndFunction

#EndRegion

#EndRegion

#Region UsedMaterials

&AtClient
Procedure MaterialsFillTheWarehouseCompletion(Result, AdditionalParameters) Export
	
	SelectedRows = AdditionalParameters.SelectedRows;
	
	SelectedWarehouse = Result;
	
	If ValueIsFilled(SelectedWarehouse) Then
	
		FilledWithRows = FillWarehouseInSelectedLinesOnServer(SelectedRows, SelectedWarehouse, "UsedMaterials");
	
		WarehousesClient.ShowNotificationAboutFillingOfWarehouseInTablePart(
			SelectedWarehouse, FilledWithRows, SelectedRows.Count());
	
	EndIf;
	
	WhenChangingWarehouseInTablePartServer("UsedMaterials");
	
EndProcedure

&AtClient
Procedure FillInTheMaterialsAccordingToTheSpecificationsCompletion(QuestionResult, AdditionalParameters) Export
	
	MaterialsFillInSpecificationsFragment(QuestionResult = DialogReturnCode.Yes);
	
EndProcedure

&AtClient
Procedure MaterialsFillInSpecificationsFragment(Val FillInMaterials_)
	
	If FillInMaterials_ Then
		MaterialsFillInSpecificationsOnServer();
	EndIf;
	
EndProcedure

&AtClient
Procedure DownloadMaterialsFromTSDEnd(Result, Var_Parameters) Export
	
	If Result.Result Then
		TSName = ?(Items.GroupPages.CurrentPage = Items.PageMaterials,  "UsedMaterials", "ManufacturedProduct");
		ProcessBarcodes(Result.TableOfGoods, TSName, Items[TSName]);
	Else
		EquipmentManagerTMClient.ReportError(Result);
	EndIf;
	
EndProcedure

&AtClient
Procedure MaterialsBarcodeSearchCompletion(BarcodeData_2, AdditionalParameters) Export
	
	ProcessBarcodes(BarcodeData_2, "UsedMaterials", Items.UsedMaterials);
	
EndProcedure

&AtClient
Procedure MaterialsSplitLineCompletion(NewRow, AdditionalParameters) Export 
	
	CurrentRow = Items.UsedMaterials.CurrentData;
	
	If NewRow <> Undefined Then
		
		NewRow.RowCode = 0;
		
		StructureOfActions = New Structure;
		
		AddActionsToStructureWhenChangingNumberOfPackagesOfMaterials(StructureOfActions);
		BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
		BatchProcessingOfTablePartClient.ProcessTSString(NewRow, StructureOfActions, CachedValues);
		
		CalculateOrderTotals(ThisObject);
		
	EndIf;
	
EndProcedure

&AtServer
Procedure MaterialsFillInSpecificationsOnServer()
	
	// &PerformanceMeasurement
	Measurement = PerformanceMonitor.StartTimeConsumingOperationMeasurement(
			"Document.MaterialProviderOrder2_5.Form.DocumentForm.Command.MaterialsFillInFillInAccordingToSpecifications");
	
	ItemList = Catalogs.BillsOfMaterials.ItemList();
	
	For Each RowTS In Object.ManufacturedProduct Do
		
		If RowTS.Canceled Then
			Continue;
		EndIf;
		
		NewRow = ItemList.Add();
		FillPropertyValues(NewRow, RowTS, "Products, Characteristic, Count, BillOfMaterials");
		NewRow.ProductionStart      = Object.Date;
		NewRow.LineOfBusiness = Object.LineOfBusiness;
		
	EndDo;
	
	Object.UsedMaterials.Clear();
	
	TableOfGoods = Object.UsedMaterials.Unload(, "Products, Characteristic, Package, NumberOfPackages, BillOfMaterials, Count");
	TableOfGoods.Columns.Add("ItemsType", New TypeDescription("EnumRef.ItemsTypes"));
	
	SpecificationParameters = New Structure;
	SpecificationParameters.Insert("ListOfData",     "MaterialsAndServices, IncomingProducts");
	SpecificationParameters.Insert("ItemList", ItemList);
	SpecificationParameters.Insert("Department",	     Object.Department);
	
	Documents.MaterialProviderOrder2_5.MaterialsAccordingToSpecifications(SpecificationParameters, TableOfGoods);
	
	TableOfGoods.Sort("Products, Characteristic, BillOfMaterials");
	
	RowsToProcess = New Array();
	
	For Each RowOfProduct In TableOfGoods Do
		
		If RowOfProduct.ItemsType = Enums.ItemsTypes.Work_5 Then
			
			MessageText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Bảng kê chi tiết các nguồn lực sản xuất có kiểu ''''Công việc'''' (%1). Thêm công việc vào đơn đặt hàng là không được phép.';
					|ru = 'Спецификация содержит материал с типом ""Работа"" (%1). Добавление работ в заказ давальцу не допускается.';
					|en = 'Bill of materials contains material with type ""Work"" (%1). Adding activities to material provider order is not allowed.'; fa = 'Bill of materials contains material with type ""Work"" (%1). Adding activities to material provider order is not allowed.';
					|it = 'La specifica contiene materiale con tipo ""Lavoro"" (%1). Non è consentito aggiungere i lavori all''ordine al committente.';
					|pl = 'Specyfikacja materiałowa zawiera materiał o typie ""Работа"" (%1). Dodawanie prac do zamówienia do właściciela surowców jest nie dopuszczalne.';
					|tr = 'Şartname ""İş"" (%1) türünde malzeme içerir. Siparişi verene iş eklenmesine izin verilmez.'"),
				RowOfProduct.Products);
			Common.MessageToUser(MessageText);
			
			Continue;
			
		EndIf;
		
		CurrentRow = Object.UsedMaterials.Add();
		FillPropertyValues(CurrentRow, RowOfProduct);
		
		If Object.OneDateReceipt Then
			CurrentRow.DateOfReceipt = Object.DateOfReceipt;
		EndIf;
		
		RowsToProcess.Add(CurrentRow);
		
	EndDo;
	
	CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	StructureOfActions = New Structure("CheckFillWarehouse", ParametersForFillingWarehouseInLine("UsedMaterials"));
	
	AddToStructureActionsToUpdateVspAttributesOfLine(StructureOfActions);
	AddActionsToStructureWhenChangingNumberOfPackagesOfMaterials(StructureOfActions);
	AddQualityControlActionsToStructure(StructureOfActions, CacheQualityControl);
	StructureOfActions.Insert("CheckFillAssignment", Object.AssignmentMaterials);
	StructureOfActions.Insert("FillInShopPantryAttribute");
	StructureOfActions.Insert("FillInActionForRecyclableMaterials");

	StructureOfActions.Insert(
		"ProductsOnChangeOverridable",
		New Structure("FormName, TabularSectionName", FormName, "UsedMaterials"));
	
	StructureOfActions.Insert("FillInProductNameOfProductPartner", Object.Partner);
	
	StructureOfActions.Insert(
		"FillInPurchasePrice",
		BatchProcessingOfTablePartClientServer.GetStructureForFillingInPurchasePriceInTSLine(
			Object,
			"PriceTypeMaterials"));
	
	StructureOfActions.Insert(
		"CheckSeriesCalculateStatus",
		New Structure(
				"Warehouse, SeriesSpecificationParameters, TableOfGoods",
				Object.WarehouseForReceipt, SeriesSpecificationParameters.UsedMaterials, RowsToProcess));
	
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		RowsToProcess,
		StructureOfActions,
		Object.UsedMaterials,
		CachedValues);
	
	WhenChangingWarehouseInTablePartServer("UsedMaterials");
	CalculateOrderTotals(ThisObject);
	
	ReusablePackageServer.UpdateFillingStateOfMultiTurnContainer(
		Object.ReusablePackageFillingStatus);
	
	// &PerformanceMeasurement
	PerformanceMonitor.EndTimeConsumingOperationMeasurement(Measurement, Object.UsedMaterials.Count());
	
EndProcedure

#EndRegion

#Region BarcodesAndTradeEquipment

&AtClient
Procedure ProcessBarcodes(BarcodeData_5, TabularSectionName, FormTable)
	
	ClearMessages();
	
	If Not BarcodingOfItemsClient.BarcodesAreValid(BarcodeData_5) Then
		Return;
	EndIf;
	
	StructureOfActionsWithAddedStrings = New Structure;
	StructureOfActionsWithModifiedStrings  = New Structure;
	
	StructureOfActionsWithAddedStrings.Insert(
		"CheckFillWarehouse", ParametersForFillingWarehouseInLine(TabularSectionName));
	StructureOfActionsWithAddedStrings.Insert("FillInShopPantryAttribute");
	
	AddToStructureActionsToUpdateVspAttributesOfLine(StructureOfActionsWithAddedStrings);
	
	If TabularSectionName = "UsedMaterials" Then
		
		StructureOfActionsWithAddedStrings.Insert("FillInProductNameOfProductPartner", Object.Partner);
		
		StructureOfActionsWithAddedStrings.Insert(
			"FillInPurchasePrice",
			BatchProcessingOfTablePartClientServer.GetStructureForFillingInPurchasePriceInTSLine(
				Object, "PriceTypeMaterials"));
		
		StructureOfActionsWithAddedStrings.Insert("FillInActionForRecyclableMaterials");
		
		AddQualityControlActionsToStructure(StructureOfActionsWithAddedStrings, CacheQualityControl);
		
		AddActionsToStructureWhenChangingNumberOfPackagesOfMaterials(StructureOfActionsWithAddedStrings);
		AddActionsToStructureWhenChangingNumberOfPackagesOfMaterials(StructureOfActionsWithModifiedStrings);
		
		StructureOfActionsWithAddedStrings.Insert("CheckFillAssignment", Object.AssignmentMaterials);
		
	Else // ManufacturedProduct
		
		StructureOfActionsWithAddedStrings.Insert(
			"FillInPriceView", New Structure("PriceKind", DefaultPriceType));
		StructureOfActionsWithAddedStrings.Insert(
			"FillInSalePrice", BatchProcessingOfTablePartClientServer.ParametersForFillingInPriceInTSLine(Object));
		
		AddActionsClearFillArticleAnalytics(StructureOfActionsWithAddedStrings, ThisObject);
		
		AddActionsToStructureWhenChangingNumberOfProductPackages(
			StructureOfActionsWithAddedStrings, Object);
		
		If VATRateIsIndicatedInTablePart(Object.BusinessOperation) Then
			AddActionToStructureFillInVATRate(Object, StructureOfActionsWithAddedStrings);
		EndIf;
		
		AddActionsToStructureWhenChangingNumberOfProductPackages(
			StructureOfActionsWithModifiedStrings, Object);
		
	EndIf;
	
	StructureOfActions = BarcodingOfItemsClient.BarcodeProcessingParameters();
	StructureOfActions.Barcodes									= BarcodeData_5;
	StructureOfActions.StructureOfActionsWithAddedStrings	= StructureOfActionsWithAddedStrings;
	StructureOfActions.StructureOfActionsWithModifiedStrings		= StructureOfActionsWithModifiedStrings;
	StructureOfActions.SeriesSpecificationParameters					= SeriesSpecificationParameters[TabularSectionName];
	StructureOfActions.TSName										= TabularSectionName;
	StructureOfActions.GoodsOnly								= TabularSectionName = "UsedMaterials" Or ManufacturedProductsProduced And Not WorksAreBeingCarriedOut;
	StructureOfActions.OnlyWorks								= Not TabularSectionName = "UsedMaterials" And Not ManufacturedProductsProduced And WorksAreBeingCarriedOut;
	StructureOfActions.OnlyGoodsAndWork						= Not TabularSectionName = "UsedMaterials" And ManufacturedProductsProduced And WorksAreBeingCarriedOut;
	StructureOfActions.AddContainers							= TabularSectionName = "UsedMaterials";
	
	ProcessBarcodesServer(StructureOfActions, CachedValues);
	
	BarcodingOfItemsClient.ProcessUnknownBarcodes(
		StructureOfActions, CachedValues, ThisObject);
	
	If BarcodingOfItemsClient.YouNeedToOpenFormForSpecifyingSeriesAfterProcessingBarcodes(StructureOfActions) Then
		CurDataId = StructureOfActions.ArrayOfRowsWithSeries_[0];
		NameOfCurTablePart   = TabularSectionName;
		
		AttachIdleHandler("OpenSeriesSelectionWhenScanningProductBarCode",0.1,True);
	EndIf;
	
	ProvisionInDocumentsClientServer.FillInServiceDetails(Object.ManufacturedProduct, DateOfShipmentRequired_, WarehouseIsRequired);
	CalculateOrderTotals(ThisObject);
	
	If StructureOfActions.CurrentRow <> Undefined Then
		FormTable.CurrentRow = StructureOfActions.CurrentRow;
	EndIf;
	
	If TabularSectionName = "ManufacturedProduct" Then
		SetKeysInProductLines(Items, Object);
	EndIf;
	
EndProcedure

&AtServer
Procedure ProcessBarcodesServer(StructureOfActionParameters, CachedValues)
	
	TSName = StructureOfActionParameters.TSName;
	
	If TSName = "ManufacturedProduct" Then
		AddCollateralActionsOnServer(
			StructureOfActionParameters.StructureOfActionsWithAddedStrings,
			"SupplyOption,WarehouseIsRequired,DateOfShipmentRequired_");
	EndIf;
	
	RowsCount = Object[TSName].Count();
	
	BarcodingOfItemsServer.ProcessBarcodes(
		ThisObject, Object, StructureOfActionParameters, CachedValues);
	
	If TSName = "UsedMaterials" Then
		ElementNameFlagTotalDate = "OneDateReceipt";
		ItemNameDate          = "DateOfReceipt";
	ElsIf TSName = "ManufacturedProduct" Then
		
		ElementNameFlagTotalDate = "NotShipInInstallments";
		ItemNameDate          = "DateOfShipment";
	
		UpdateColumnAvailableServer();
		ProvisionInDocumentsClientServer.RemoveCollateralActions(StructureOfActionParameters.StructureOfActionsWithAddedStrings);
		
	EndIf;
	
	If Object[ElementNameFlagTotalDate]
		And RowsCount < Object[TSName].Count() Then
		For CurrentIndex = RowsCount To Object[TSName].Count() - 1 Do
			Object[TSName][CurrentIndex][ItemNameDate] = Object[ItemNameDate];
		EndDo;
	EndIf;
	
	If StructureOfActionParameters.CurrentRow <> Undefined Then
		
		CurrentRow = Object[TSName].FindByID(StructureOfActionParameters.CurrentRow); // FormDataCollectionItem
		
		If TSName = "ManufacturedProduct" Then
			
			NewRowArray = New Array;
			ArrayOfDataOnProducts = New Array;
			
			NewRowArray.Add(CurrentRow);
			ArrayOfDataOnProducts.Add(Documents.MaterialProviderOrder2_5.ItemData_3(Object, CurrentRow));
			
			ProductDataManagement.FillInSpecificationInLines(
				NewRowArray, ArrayOfDataOnProducts, BOMSelectionParameters);
			
		EndIf;
		
	EndIf;
	
	WhenChangingWarehouseInTablePartServer(TSName);
	
EndProcedure

#EndRegion

#Region PriceManagementSystem

&AtServer
Function FillInPricesByPriceKindServer(PricesKind, BySelectedLines, CachedValues)
	
	FillParameters = EnterprisePricesFillingServer.NewFillOptionsFillPrices();
	FillParameters.Date           = Object.Date;
	FillParameters.Currency         = Object.Currency;
	FillParameters.Organization    = Object.Organization;
	FillParameters.PriceKind        = PricesKind;
	FillParameters.PopulationFields = "Price, PriceKind";
	
	RowsArray = Undefined;
	
	If BySelectedLines Then
		
		RowsArray = New Array;
		For Each String In Items.ManufacturedProduct.SelectedRows Do
			RowsArray.Add(Object.ManufacturedProduct.FindByID(String));
		EndDo;
		
	EndIf;
	
	PricesCalculated = EnterprisePricesFillingServer.FillInPrices(Object.ManufacturedProduct, RowsArray, FillParameters);
	If PricesCalculated Then
		
		StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
		
		StructureOfActions = New Structure;
		StructureOfActions.Insert("RecalculateAmount");
		StructureOfActions.Insert("RecalculateVATAmount",  StructureOfRecalculationOfAmount);
		StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
		StructureOfActions.Insert("FillInDuplicateDependentDetails", DependentDetails("ManufacturedProduct"));
		
		RowsCollection = ?(BySelectedLines, RowsArray, Object.ManufacturedProduct);
		BatchProcessingOfTablePartServer.ProcessTSStrings(
			RowsCollection,
			StructureOfActions,
			Object.ManufacturedProduct,
			CachedValues);
		
		CalculateOrderTotals(ThisObject);
		
	EndIf;
	
	Return PricesCalculated;
	
EndFunction

&AtServer
Procedure FillInPricesByTypeOfMaterialPricesServer(BySelectedLines)
	
	If BySelectedLines Then
		RowsToProcess = New Array;
		For Each CurrentRow In Items.UsedMaterials.SelectedRows Do
			RowsToProcess.Add(Object.UsedMaterials.FindByID(CurrentRow));
		EndDo;
	Else
		RowsToProcess = Object.UsedMaterials;
	EndIf;
	
	StructureOfActions = New Structure;
	
	StructureOfActions.Insert(
		"FillInPurchasePrice",
		BatchProcessingOfTablePartClientServer.GetStructureForFillingInPurchasePriceInTSLine(
			Object, "PriceTypeMaterials"));
			
	StructureOfActions.Insert("RecalculateAmount");
	StructureOfActions.Insert("FillInDuplicateDependentDetails", DependentDetails("UsedMaterials"));
	
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		RowsToProcess,
		StructureOfActions,
		Object.UsedMaterials);
	
	Modified = True;
	
EndProcedure

#EndRegion

#EndRegion

#Region StructureOfActions

&AtClientAtServerNoContext
Procedure AddToStructureActionsToUpdateVspAttributesOfLine(StructureOfActions)
	
	StructureCharacteristics  = New Structure("Products", "ItemVariantsAreUsed");
	StructureTypeOfProduct = New Structure("Products", "ItemsType");
	StructureArticle         = New Structure("Products", "SKU");
	
	StructureOfActions.Insert("FillInFeatureAttribute", StructureCharacteristics);
	StructureOfActions.Insert("FillInProductTypeAttribute_", StructureTypeOfProduct);
	StructureOfActions.Insert("FillInArticleAttribute", StructureArticle);
	
EndProcedure

&AtClientAtServerNoContext
Procedure AddActionsToStructureWhenChangingNumberOfProductPackages(StructureOfActions, Object)
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	
	StructureOfActions.Insert(
		"RecalculateNumberOfUnits", ProductionClientServer.ParametersForRecalculatingNumberOfUnits());
	StructureOfActions.Insert("RecalculateAmount");
	StructureOfActions.Insert("RecalculateVATAmount",  StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("FillInDuplicateDependentDetails", DependentDetails("ManufacturedProduct"));
	
EndProcedure

&AtClientAtServerNoContext
Procedure AddActionsToStructureWhenChangingNumberOfPackagesOfMaterials(StructureOfActions)
	
	StructureOfActions.Insert(
		"RecalculateNumberOfUnits", ProductionClientServer.ParametersForRecalculatingNumberOfUnits());
	StructureOfActions.Insert("RecalculateAmount");
	
EndProcedure

&AtClientAtServerNoContext
Procedure AddActionsToStructureWhenYouChangeActionInContentLine(Form, RowData, StructureOfActions)
		
	StructureOfActions.Insert("FillInShopPantryAttribute");
	StructureOfActions.Insert(
		"RecalculateNumberOfUnits",
		ProductionClientServer.ParametersForRecalculatingNumberOfUnits());
	
	If Not RowData = Undefined Then
		
		StructureOfActions.Insert(
			"CheckSeriesCalculateStatus",
			New Structure("Warehouse, SeriesSpecificationParameters", RowData.Warehouse, Form.SeriesSpecificationParameters.UsedMaterials));
		
		If RowData.Action =
				PredefinedValue("Enum.ActionsOnMaterialsToSubcontract.AcceptVMI") Then
			
			StructureOfActions.Insert(
				"FillInPurchasePrice",
				BatchProcessingOfTablePartClientServer.GetStructureForFillingInPurchasePriceInTSLine(
					Form.Object,
					"PriceTypeMaterials"));
			
			StructureOfActions.Insert("RecalculateAmount");
			
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Procedure AddActionsClearFillArticleAnalytics(StructureOfActions, Form)
	
	IncomeAndExpensesClientServer.InsertActionClearItemAndExpenseAnalytics(
		StructureOfActions, Form, "Object.ManufacturedProduct");
	
	IncomeAndExpensesClientServer.InsertActionFillInItemCostAnalysisOfProducts(
		StructureOfActions,
		Form,
		PredefinedValue("Enum.BusinessTransactions.GoodsConsumptionOnDemand"),
		Form.Object.Organization,
		Form.Object.Department,
		"Object.ManufacturedProduct");
	
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

&AtClientAtServerNoContext
Procedure AddActionToStructureFillInVATRate(Object, StructureOfActions)
	
	StructureOfActions.Insert("FillInVATRate", BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRate(Object, True));
	
EndProcedure

&AtClientAtServerNoContext
Procedure AddQualityControlActionsToStructure(StructureOfActions, CacheQualityControl)
	
	StructureOfActions.Insert("FillInCheckQualityDateOfQualityConfirmation", CacheQualityControl);
	
EndProcedure

#EndRegion

#Region Pickup

&AtClient
Procedure PickUpProduct(TSName)
	
	Cancel = False;
	
	If Not ValueIsFilled(Object.Currency) Then
		ClearMessages();
		ReportErrorsWhenOpeningSelection(Cancel);
	EndIf;
	
	If Cancel Then
		Return;
	EndIf;
	
	HeaderParameter_ = NStr("vi = 'Lựa chọn hàng hóa vào %Document%';
							|ru = 'Подбор товаров в %Document%';
							|en = 'Pick goods in %Document%'; fa = 'Pick goods in %Document%';
							|it = 'Selezione merci in %Document%';
							|pl = 'Wybór towarów w %Document%';
							|tr = '%Document% içindeki ürünlerin seçimi'");
	If ValueIsFilled(Object.Ref) Then
		HeaderParameter_ = StrReplace(HeaderParameter_, "%Document%", Object.Ref);
	Else
		HeaderParameter_ = StrReplace(HeaderParameter_, "%Document%", NStr("vi = 'đơn hàng của người đặt gia công';
																			|ru = 'заказ давальца';
																			|en = 'subcontracting sales order'; fa = 'subcontracting sales order';
																			|it = 'ordine del committente';
																			|pl = 'zamówienie dostawcy';
																			|tr = 'sağlayıcı siparişi'"));
	EndIf;
	
	FormParameters = New Structure;
	FormParameters.Insert("Document",        Object.Ref);
	FormParameters.Insert("Partner",         Object.Partner);
	FormParameters.Insert("PriceIncludesVAT", Object.PriceIncludesVAT);
	FormParameters.Insert("Currency",          Object.Currency);
	FormParameters.Insert("Date",            Object.Date);
	FormParameters.Insert("Title",       HeaderParameter_);
	FormParameters.Insert("Department",   Object.Department);
	
	If TSName = "ManufacturedProduct" Then
		
		FormParameters.Insert("Organization",        Object.Organization);
		FormParameters.Insert("VATTaxation", Object.VATTaxation);
		FormParameters.Insert("Purpose",         Object.Purpose);
		
		If ManufacturedProductsProduced
			And WorksAreBeingCarriedOut Then
			FormParameters.Insert("SelectionModeUseWarehousesInTabularSection", True);
			FormParameters.Insert("Warehouse", Object.Warehouse);
			FormParameters.Insert("FilterByProductType", ProductsClientServer.SelectionByProductReusablePackagingWork(False));
		ElsIf ManufacturedProductsProduced
			And Not WorksAreBeingCarriedOut Then
			FormParameters.Insert("SelectionModeUseWarehousesInTabularSection", True);
			FormParameters.Insert("Warehouse", Object.Warehouse);
			FormParameters.Insert("FilterByProductType", ProductsClientServer.SelectionByProductMultiTurnContainer(False));
		Else
			FormParameters.Insert("FilterByProductType", ProductsClientServer.JobSelection(False));
		EndIf;
		
		FormParameters.Insert("UseShipmentDates",         True);
		FormParameters.Insert("SelectSupplyOptions",       True);
		FormParameters.Insert("SeriesSpecificationParameters",           SeriesSpecificationParameters[TSName]);
		FormParameters.Insert("AcceptableSeparateActions",   ProvisionInDocumentsClientServer.AllActions());
		FormParameters.Insert("AllowedNonIsolatedActions", New ValueList());
		FormParameters.Insert("OnlySeparately",                True);
		FormParameters.Insert("UseAdvancedFeaturesOfSalesOrder", True);
		
		FormParameters.Insert(
			"AvailableRemainingDocumentParameters",
			ProvisionInDocumentsClient.AvailableRemainingDocumentParameters(ThisObject));

		SelectionParametersPriceType = New Array;
		SelectionParametersPriceType.Add(New ChoiceParameter("Filter.UseWhileTransferringProductsToMaterialProvider", True));
		FormParameters.Insert("SelectionParametersPriceType", SelectionParametersPriceType);

		ProductSelectionForm = "DataProcessor.SelectGoodsToSalesDocument.Form";
		
	Else
		
		FormParameters.Insert("FilterByProductType",           ProductsClientServer.SelectionByProductMultiTurnContainer(False));
		FormParameters.Insert("HideManualDiscounts",              True);
		FormParameters.Insert("SelectionModeWithoutAmountParameters", True);
		FormParameters.Insert("HideTheViewPriceColumn",            True);
		FormParameters.Insert("HideTheItemPricesCommand",   True);
		FormParameters.Insert("SelectionModeUseWarehousesInTabularSection", True);
		FormParameters.Insert("Warehouse",                             Object.WarehouseForReceipt);
		
		ProductSelectionForm = "DataProcessor.SelectGoodsToPurchaseDocument.Form";
		
	EndIf;
	
	OpenForm(ProductSelectionForm, FormParameters, ThisObject, UUID);
	
EndProcedure

&AtClient
Procedure ReportErrorsWhenOpeningSelection(Cancel)
	
	If Not ValueIsFilled(Object.Currency) Then
		
		CommonClient.MessageToUser(
			NStr("vi = 'Chưa điền trường ""Tiền tệ""';
				|ru = 'Поле ""Валюта"" не заполнено';
				|en = '""Currency"" is required'; fa = '""Currency"" is required';
				|it = 'Il campo ""Valuta"" non è compilato';
				|pl = 'Pole ""Waluta"" nie jest wypełnione';
				|tr = '""Para Birimi"" alanı doldurulmadı'"), Object.Ref, "Object.Currency",, Cancel);
		
	EndIf;
	
EndProcedure

&AtServer
Procedure ProcessingSelectionOfSelectionOnServer(ValueSelected, TSName)
	
	TableOfGoods   = GetFromTempStorage(ValueSelected.GoodsAddressInStorage); // ValueTable
	DocumentTable = Object[TSName]; // FormDataCollection
	
	ListOfProperties = "Products, Characteristic, Package, Warehouse, Price, NumberOfPackages";
	If TSName = "ManufacturedProduct" Then
		ListOfProperties = ListOfProperties + ", Series, PriceKind, SupplyOption, WithAssignment, DateOfShipment";
	Else
		ListOfProperties = ListOfProperties + ", PartnerProducts";
	EndIf;
	
	BegOfDay = BegOfDay(CurrentSessionDate());
	CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	
	StructureOfActions = New Structure;
	AddToStructureActionsToUpdateVspAttributesOfLine(StructureOfActions);
	
	If TSName = "ManufacturedProduct" Then
		
		StructureOfActions.Insert("FillInPriceView", New Structure("PriceKind", DefaultPriceType));
		StructureOfActions.Insert(
			"FillInSalePrice", BatchProcessingOfTablePartClientServer.ParametersForFillingInPriceInTSLine(Object));
		StructureOfActions.Insert("RecalculateAmount");
		StructureOfActions.Insert("RecalculateVATAmount",  StructureOfRecalculationOfAmount);
		StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
		
		AddCollateralActionsOnServer(StructureOfActions, "WarehouseIsRequired,DateOfShipmentRequired_");
		
		ItIsRequiredToFillOutSecurityOption =
			TableOfGoods.FindRows(New Structure("SupplyOption", 
				PredefinedValue("Enum.SupplyOptions.EmptyRef"))).Count();
		
		If ItIsRequiredToFillOutSecurityOption Then
			AddCollateralActionsOnServer(StructureOfActions, "SupplyOption");
		EndIf;
		
		AddActionsToStructureWhenChangingNumberOfProductPackages(StructureOfActions, Object);
		
		AddActionsClearFillArticleAnalytics(StructureOfActions, ThisObject);
		
		If VATRateIsIndicatedInTablePart(Object.BusinessOperation) Then
			AddActionToStructureFillInVATRate(Object, StructureOfActions);
		EndIf;
		
	ElsIf TSName = "UsedMaterials" Then // Shipment
		
		StructureOfActions.Insert("FillInActionForRecyclableMaterials");
		
		AddActionsToStructureWhenChangingNumberOfPackagesOfMaterials(StructureOfActions);
		AddQualityControlActionsToStructure(StructureOfActions, CacheQualityControl);
		StructureOfActions.Insert("CheckFillAssignment", Object.AssignmentMaterials);
		
		StructureOfActions.Insert(
			"FillInPurchasePrice",
			BatchProcessingOfTablePartClientServer.GetStructureForFillingInPurchasePriceInTSLine(
				Object,
				"PriceTypeMaterials"));
		
		StructureOfActions.Insert(
			"ProductsOnChangeOverridable",
			New Structure("FormName, TabularSectionName", FormName, TSName));
	
		StructureOfActions.Insert("FillInProductNameOfProductPartner", Object.Partner);
		
	EndIf;
	
	StructureOfActions.Insert("FillInShopPantryAttribute");
	StructureOfActions.Insert(
		"RecalculateNumberOfUnits", ProductionClientServer.ParametersForRecalculatingNumberOfUnits());
	
	ProductData_2 = New Array;
	RowsToProcess = New Array;
	For Each RowOfProduct In TableOfGoods Do
		
		CurrentRow = DocumentTable.Add();
		FillPropertyValues(CurrentRow, RowOfProduct, ListOfProperties);
		
		If TSName = "ManufacturedProduct" Then
			
			If Not VATRateIsIndicatedInTablePart(Object.BusinessOperation) Then
				CurrentRow.VATRate = Object.VATRate;
			EndIf;
			
			If Object.NotShipInInstallments Then
				CurrentRow.DateOfShipment = Object.DateOfShipment;
			EndIf;
			
			ProductData_2.Add(
				ProductDataManagementClientServer.CollectProductDataForSpecificationSelection(
					Object, CurrentRow, BOMSelectionParameters, ThisObject));
			
		ElsIf TSName = "UsedMaterials" Then // Shipment
			
			If Object.OneDateReceipt Then
				CurrentRow.DateOfReceipt = Object.DateOfReceipt;
			EndIf;
			
		EndIf;
		
		RowsToProcess.Add(CurrentRow);
		
	EndDo;
	
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		RowsToProcess,
		StructureOfActions,
		DocumentTable,
		CachedValues);
	
	If TSName = "ManufacturedProduct" Then
		
		ProductDataManagement.FillInSpecificationInLines(
			RowsToProcess, ProductData_2, BOMSelectionParameters);
		
		For Each RowOfProduct In RowsToProcess Do
			
			CurrentRow.DateOfShipment =
				ProvisionInDocumentsServer.ShipmentDateProcessingSelectionSelection(
					RowOfProduct.DateOfShipment,
					CurrentRow.SupplyOption,
					BegOfDay);
			
		EndDo;
	
		ProvisionInDocumentsServer.UpdateShipmentDateWithSingleDate(
			Object.NotShipInInstallments,
			Object.DateOfShipment,
			Object.ManufacturedProduct,
			"DateOfShipment");
		
	EndIf;
	
	ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters[TSName]);
	
	If TSName = "ManufacturedProduct" Then
		UpdateColumnAvailableServer();
	Else
		ReusablePackageServer.UpdateFillingStateOfMultiTurnContainer(Object.ReusablePackageFillingStatus);
	EndIf;
	
	SetKeysInProductLines(Items, Object);
	
	CalculateOrderTotals(ThisObject);
	WhenChangingWarehouseInTablePartServer(TSName);
	
EndProcedure

&AtServer
Procedure SelectionOfMaterialsAccordingToSpecifications(ValueSelected)
	
	TableOfGoods = GetFromTempStorage(ValueSelected.GoodsAddressInStorage);
	ListOfProperties  = "Products, Characteristic, RowCode, BillOfMaterials, Package, NumberOfPackages";
	
	LinesToDelete = New Array;
	For Each MaterialString In Object.UsedMaterials Do
		If ValueIsFilled(MaterialString.BillOfMaterials) Then
			LinesToDelete.Add(MaterialString);
		EndIf;
	EndDo;
	
	For Each RowToDelete In LinesToDelete Do
		Object.UsedMaterials.Delete(RowToDelete);
	EndDo;
	
	StructureOfActions = New Structure("CheckFillWarehouse", ParametersForFillingWarehouseInLine("UsedMaterials"));
	StructureOfActions.Insert("CheckFillAssignment", Object.AssignmentMaterials);
	StructureOfActions.Insert("FillInShopPantryAttribute");
	StructureOfActions.Insert("FillInActionForRecyclableMaterials");
	
	AddToStructureActionsToUpdateVspAttributesOfLine(StructureOfActions);
	AddActionsToStructureWhenChangingNumberOfPackagesOfMaterials(StructureOfActions);
	AddQualityControlActionsToStructure(StructureOfActions, CacheQualityControl);
	
	StructureOfActions.Insert(
		"ProductsOnChangeOverridable",
		New Structure("FormName, TabularSectionName", FormName, "UsedMaterials"));
	
	StructureOfActions.Insert("FillInProductNameOfProductPartner", Object.Partner);
	
	StructureOfActions.Insert(
		"FillInPurchasePrice",
		BatchProcessingOfTablePartClientServer.GetStructureForFillingInPurchasePriceInTSLine(
			Object,
			"PriceTypeMaterials"));
			
	RowsToProcess = New Array;
	
	For Each RowOfProduct In TableOfGoods Do
		
		If RowOfProduct.NumberOfPackages = 0 Then
			Continue;
		EndIf;
		
		CurrentRow = Object.UsedMaterials.Add();
		FillPropertyValues(CurrentRow, RowOfProduct, ListOfProperties);
		
		If Object.OneDateReceipt Then
			CurrentRow.DateOfReceipt = Object.DateOfReceipt;
		EndIf;
		
		RowsToProcess.Add(CurrentRow);
		
	EndDo;
	
	StructureOfActions.Insert(
		"CheckSeriesCalculateStatus",
		New Structure("Warehouse, SeriesSpecificationParameters, TableOfGoods",
			Object.WarehouseForReceipt, SeriesSpecificationParameters.UsedMaterials, RowsToProcess));
		
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		RowsToProcess,
		StructureOfActions,
		Object.UsedMaterials);
		
	CalculateOrderTotals(ThisObject);
	WhenChangingWarehouseInTablePartServer("UsedMaterials");
	
	ReusablePackageServer.UpdateFillingStateOfMultiTurnContainer(
		Object.ReusablePackageFillingStatus);
	
EndProcedure

&AtClient
Procedure HandlingSelectionSelectionOnClient(ValueSelected, TSName)
	
	If Not ValueIsFilled(ValueSelected) Then
		Return;
	EndIf;
	
	If TSName = "ManufacturedProduct" Then
		ProvisionInDocumentsClient.ShowQuestionUncheckShipOneDateAfterSelection(
		ThisObject,
		ValueSelected,
		"ProcessingSelectionIsDoneOnClientAfterQuestion");
	Else
		ProcessingSelectionOfSelectionOnServer(ValueSelected, TSName);
	EndIf;
	
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
	
	ProcessingSelectionOfSelectionOnServer(AdditionalParameters, "ManufacturedProduct");
	
EndProcedure

#EndRegion

#Region Assignments

&AtServer
Procedure WhenYouChangeDestinationTemplateInDocument()
	
	DestinationPattern = Documents.MaterialProviderOrder2_5.DestinationPattern(Object);
	If DestinationPattern.OrderDocument = Undefined Then
		Object.Purpose = Catalogs.Assignments.FindByTemplate(DestinationPattern);
		ProvisionInDocumentsServer.WhenChangingDocumentDetails(ThisObject);
	EndIf;
	
EndProcedure

#EndRegion

#Region SetOfSeries

&AtServer
Procedure FillInStatusesForSpecifyingSeries(TSName)
	
	ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters[TSName]);
	
EndProcedure

&AtClient
Procedure OpenSeriesSelectionWhenScanningProductBarCode()

	If CurDataId = Undefined Then
		Return;
	EndIf;
	
	CurrentData = Object[NameOfCurTablePart].FindByID(CurDataId);
	OpenSelectionOfSeries(NameOfCurTablePart, CurrentData);

EndProcedure

&AtClient
Procedure OpenSelectionOfSeries(TSName, CurrentData = Undefined, Text = "")
	
	If ProductsClient.YouNeedServerCallToSpecifySeries(ThisObject, SeriesSpecificationParameters[TSName], Text, CurrentData)Then
		ExceptionText = NStr("vi = 'Lỗi khi thử chỉ ra sê-ri - trong chứng từ này để chỉ ra sê-ri không cần gọi ra máy chủ.';
							|ru = 'Ошибка при попытке указать серии - в этом документе для указания серий не нужен серверный вызов.';
							|en = 'An error occurred when attempting to specify batch. No server call is required to specify batch in this document.'; fa = 'An error occurred when attempting to specify batch. No server call is required to specify batch in this document.';
							|it = 'Si è verificato un errore durante il tentativo di indicare le serie - in questo documento non è necessaria la chiamata al server per indicare le serie.';
							|pl = 'Błąd podczas próby określenia serii - w tym dokumencie nie jest wymagane wywołanie serwera, aby wskazać serię.';
							|tr = 'Bir parti belirtmeye çalışırken hata oluştu - bu belgede bir parti belirtmek için sunucu çağrısı gerekmez.'");
		Raise ExceptionText;
	EndIf;
	
EndProcedure

&AtServer
Procedure FillInBatchIndicationStatusesONChangesOfFinishedProductBeingRepaired(CachedValues, DataStructureOfFinishedProductBeingRepaired = Undefined)

	StatusOfSpecifyingSeriesBeforeChange = Object.UnderRepairBatchSpecificationStatus;

	If DataStructureOfFinishedProductBeingRepaired = Undefined Then
		DataStructureOfFinishedProductBeingRepaired = ProductionManagementClientServer.DataOfFinishedProductBeingRepairedByStructure(Object);
	EndIf;
	
	ProductsServer.FillInStatusesOfSpecifyingSeriesWhenChangingProductInHeader(
		DataStructureOfFinishedProductBeingRepaired, SeriesSpecificationParameters.FinishedProductBeingRepaired, CachedValues);
	
	Object.UnderRepairBatch = DataStructureOfFinishedProductBeingRepaired.Series;
	Object.UnderRepairBatchSpecificationStatus = DataStructureOfFinishedProductBeingRepaired.BatchesIndicationStatus;

	If StatusOfSpecifyingSeriesBeforeChange <> Object.UnderRepairBatchSpecificationStatus Then
	
		EstablishAvailabilityOfBatchesOfRepairedFinishedProduct();
		
	EndIf;

EndProcedure

&AtServer
Procedure EstablishAvailabilityOfBatchesOfRepairedFinishedProduct()

	VisibilityOfBatchesOfRepairedFinishedProduct =
		Object.BusinessOperation = Enums.BusinessTransactions.PerformRMUsingProvidedMaterials2_5
		And SeriesSpecificationParameters.FinishedProductBeingRepaired.UseItemsBatch;

	Items.UnderRepairBatchSpecificationStatus.Visible = VisibilityOfBatchesOfRepairedFinishedProduct;
	Items.UnderRepairBatch.Visible               = VisibilityOfBatchesOfRepairedFinishedProduct;
	
	If VisibilityOfBatchesOfRepairedFinishedProduct Then
		
		If Not Object.UnderRepairBatchSpecificationStatus = 0 Then
			Items.UnderRepairBatch.Enabled = True;
			Items.UnderRepairBatch.InputHint = "";
		Else
			Items.UnderRepairBatch.Enabled = False;
			Items.UnderRepairBatch.InputHint = NStr("vi = '<chưa chỉ ra sê-ri>';
													|ru = '<серия не указывается>';
													|en = '<batch is not specified>'; fa = '<بچ مشخص نشده است>';
													|it = '<serie non è indicata>';
													|pl = '<seria nie jest określana>';
													|tr = '<parti belirtilmemektedir>'");
		EndIf;
		
		Items.UnderRepairBatch.AutoMarkIncomplete = False; // the series can be omitted
		
	EndIf;

EndProcedure

&AtClient
Procedure UpdateCachedValuesToAccountForBatchesOfFINISHEDProductBeingRepaired(DataStructureOfFinishedProductBeingRepaired = Undefined)
	
	If DataStructureOfFinishedProductBeingRepaired = Undefined Then
		DataStructureOfFinishedProductBeingRepaired = ProductionManagementClientServer.DataOfFinishedProductBeingRepairedByStructure(Object);
	EndIf;
	
	ProductsClient.UpdateCachedHeaderValuesToAccountForSeries(
		DataStructureOfFinishedProductBeingRepaired, CachedValues, SeriesSpecificationParameters.FinishedProductBeingRepaired);
	
EndProcedure

&AtClient
Procedure ProcessIndicationOfBatchOfFINISHEDProductBeingRepaired(ValueSelected);
	
	DataStructureOfFinishedProductBeingRepaired = ProductionManagementClientServer.DataOfFinishedProductBeingRepairedByStructure(Object);
	
	FormEmulation = New Structure();
	FormEmulation.Insert("Object", DataStructureOfFinishedProductBeingRepaired);
	ProductsClient.ProcessSeriesIndication(FormEmulation, SeriesSpecificationParameters.FinishedProductBeingRepaired, ValueSelected);
	
	Object.UnderRepairBatch = DataStructureOfFinishedProductBeingRepaired.Series;
	Object.UnderRepairBatchSpecificationStatus = DataStructureOfFinishedProductBeingRepaired.BatchesIndicationStatus;
	
	UpdateCachedValuesToAccountForBatchesOfFINISHEDProductBeingRepaired(DataStructureOfFinishedProductBeingRepaired);
	
EndProcedure

#EndRegion

#Region BillOfMaterials

&AtClient
Procedure FillInSpecificationInTablePart(
			TableName, 
			NameOfLinkedTable, 
			FieldNameSpecification, 
			ModifiedRows, 
			ProcedureName, 
			QueryText, 
			LinkedAttributes = Undefined)
	
	If ModifiedRows.Count() = 0 Then
		Return;
	EndIf;
	
	RelatedSpecifications = 
		SelectRelatedSpecifications(Object, TableName, NameOfLinkedTable, FieldNameSpecification, ModifiedRows);
	
	If RelatedSpecifications.Count() > 0 Then
		
		AdditionalParameters = New Structure;
		AdditionalParameters.Insert("TableName", TableName);
		AdditionalParameters.Insert("NameOfLinkedTable", NameOfLinkedTable);
		AdditionalParameters.Insert("FieldNameSpecification", FieldNameSpecification);
		AdditionalParameters.Insert("RowsData", ModifiedRows);
		AdditionalParameters.Insert("RelatedSpecifications", RelatedSpecifications);
		AdditionalParameters.Insert("LinkedAttributes", LinkedAttributes);
		
		CallbackDescription = New CallbackDescription(ProcedureName, ThisObject, AdditionalParameters);
		
		ShowQueryBox(CallbackDescription, QueryText, QuestionDialogMode.YesNo);
		
	Else
		
		FillInLineSpecifications(
			ThisObject, Object, TableName, FieldNameSpecification, ModifiedRows, LinkedAttributes);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure FillInMainSpecificationEnd(FillingData)
	
	CleanMaterialsAccordingToSpecifications(
		Object[FillingData.NameOfLinkedTable], FillingData.RelatedSpecifications);
	
	FillInLineSpecifications(
		ThisObject,
		Object,
		FillingData.TableName,
		FillingData.FieldNameSpecification,
		FillingData.RowsData);
		
	CalculateOrderTotals(ThisObject);
	
EndProcedure

&AtServer
Function GetBasicStringSpecifications(
			TableName, FieldNameSpecification, RowsIDs = Undefined, FillParameters_ = False)
	
	ModifiedRows = New Map;
	
	If RowsIDs <> Undefined And RowsIDs.Count() = 0 Then
		Return ModifiedRows;
	EndIf;
	
	RowsData = New ValueTable;
	RowsData.Columns.Add("Id");
	RowsData.Columns.Add(FieldNameSpecification);
	
	ProductData_1 = New Array;
	
	SelectedRows = RowsIDs <> Undefined;
	StringSource_ = ?(SelectedRows, RowsIDs, Object[TableName]);
	
	For Each LinePointer In StringSource_ Do
		
		TableRow = ?(SelectedRows, Object[TableName].FindByID(LinePointer), LinePointer);
		
		DataString1 = RowsData.Add();
		DataString1.Id = ?(SelectedRows, LinePointer, LinePointer.GetID());
		DataString1[FieldNameSpecification] = TableRow[FieldNameSpecification];
		
		ProductData_1.Add(Documents.MaterialProviderOrder2_5.ItemData_3(Object, TableRow));
		
	EndDo;
	
	If FillParameters_ Then
		FillInSpecificationSelectionParameters();
	EndIf;
	
	ProductDataManagement.FillInSpecificationInLines(
		RowsData, ProductData_1, BOMSelectionParameters, FieldNameSpecification);
		
	For Each DataString1 In RowsData Do
		
		TableRow = Object[TableName].FindByID(DataString1.Id);
		
		If TableRow[FieldNameSpecification] <> DataString1[FieldNameSpecification] Then
			
			ModifiedRows.Insert(DataString1.Id, DataString1[FieldNameSpecification]);
			
		EndIf;
		
	EndDo;
	
	Return ModifiedRows;
	
EndFunction

&AtClientAtServerNoContext
Procedure FillInLineSpecifications(
			Form, Object, TableName, FieldNameSpecification, RowsData, LinkedAttributes = Undefined)
	
	For Each DataString1 In RowsData Do
		TableRow = Object[TableName].FindByID(DataString1.Key);
		TableRow[FieldNameSpecification] = DataString1.Value;
	EndDo;
	
	If LinkedAttributes <> Undefined Then
		For Each AttributesLinkElement In LinkedAttributes Do
			Form[AttributesLinkElement.Key] = Object[AttributesLinkElement.Value];
		EndDo;
	EndIf;
	
	UpdateSpecificationSelectionList(Form.Items, Object[TableName]);
	CalculateOrderTotals(Form);
	
EndProcedure

&AtClientAtServerNoContext
Function SelectRelatedSpecifications(Object, TableName, NameOfLinkedTable, FieldNameSpecification, RowsData)
	
	RelatedSpecifications = New Array;
	
	For Each DataString1 In RowsData Do
		
		TableRow = Object[TableName].FindByID(DataString1.Key);
		
		If Not ValueIsFilled(TableRow[FieldNameSpecification]) Then
			Continue;
		EndIf;
		
		FilterStructure1 = New Structure(FieldNameSpecification, TableRow[FieldNameSpecification]);
		
		FoundRows = Object[NameOfLinkedTable].FindRows(FilterStructure1);
		If FoundRows.Count() > 0 Then
			RelatedSpecifications.Add(TableRow[FieldNameSpecification]);
		EndIf;
		
	EndDo;
	
	If RelatedSpecifications.Count() > 0 Then
		RelatedSpecifications = CommonClientServer.CollapseArray(RelatedSpecifications);
	EndIf;
	
	Return RelatedSpecifications;
	
EndFunction

&AtClientAtServerNoContext
Procedure UpdateSpecificationSelectionList(Items, ManufacturedProduct)
	
	Specifications = Items.UsedMaterialsBillOfMaterials.ChoiceList;
	Specifications.Clear();
	
	// Definition of the selection list.
	For Each ProductionLine In ManufacturedProduct Do
		
		If Not Specifications.FindByValue(ProductionLine.BillOfMaterials) = Undefined Then
			Continue;
		EndIf;
		
		Specifications.Add(
			ProductionLine.BillOfMaterials,
			?(Not ValueIsFilled(ProductionLine.BillOfMaterials), NStr("vi = '<Không điền>';
																		|ru = '<Не заполнена>';
																		|en = '<Not filled in>'; fa = '<Not filled in>';
																		|it = '<Non è compilata>';
																		|pl = '<nie wypełniona>';
																		|tr = '<Boş>'"), ""));
		
	EndDo;
	
EndProcedure

&AtClient
Procedure CheckFillInBillOfMaterialsInManufacturingProductLines(Val RowsIDs)
	
	TableName = "ManufacturedProduct";
	NameOfLinkedTable = "UsedMaterials";
	FieldNameSpecification = "BillOfMaterials";
	
	NameOfNotificationProcedure = "ProductsFillInTheMainSpecification_3Completion";
	QueryText = StrTemplate(
		NStr("vi = 'Trong phần bảng ""%1"" có các dòng theo bảng kê chi tiết các nguồn lực sản xuất đã thay đổi. Các dòng sẽ bị xóa. Tiếp tục?';
			|ru = 'В табличной части ""%1"" присутствуют строки по измененным спецификациям. Они будут удалены. Продолжить?';
			|en = 'Some rows in table ""%1"" mention the modified BOMs. These rows will be deleted. Continue?'; fa = 'Some rows in table ""%1"" mention the modified BOMs. These rows will be deleted. Continue?';
			|it = 'Nella parte tabulare ""%1""  ci sono le righe in base alle specifiche modificate. Esse verranno cancellate. Continuare?';
			|pl = 'W części tabelarycznej ""%1"" są wiersze według zmienionych specyfikacji. Zostaną one usunięte. Kontynuować?';
			|tr = '""%1"" tablo bölümü değiştirilen şartnamelerle ilgili satırları içerir. Bunlar silinecektir. Devam edilsin mi?'"),
		NameOfLinkedTable);
	
	ModifiedRows = GetBasicStringSpecifications(TableName, FieldNameSpecification, RowsIDs);
	
	FillInSpecificationInTablePart(
		TableName, NameOfLinkedTable, FieldNameSpecification, ModifiedRows, NameOfNotificationProcedure, QueryText);
	
EndProcedure

#EndRegion

#Region Other

&AtServer
Procedure FillInSubordinatePropertiesForStatistics(ParentPropsName)
	ObjectsFillingByStatistics.FillInSubordinateDetailsOfObject(Object, ParentPropsName);
EndProcedure

&AtServer
Procedure AdjustOrderLines(StructureOfAdditionalParameters)
	
	DocumentObject = FormAttributeToValue("Object");
	
	StructureOfAdditionalParameters.CheckBalance =
		Not DocumentObject.Status = Enums.StatusesOfMaterialProviderOrders.NotApproved;
	
	ResultStructure1 = DocumentObject.AdjustOrderLines(StructureOfAdditionalParameters);
	If ResultStructure1.RowsCount > 0 Then
		PaymentStepsServer.CheckAndFillInPaymentScheduleStages(DocumentObject);
	EndIf;
	
	If StructureOfAdditionalParameters.CloseOrders Then
		DocumentObject.Status = Enums.StatusesOfMaterialProviderOrders.Closed;
	EndIf;
	
	ValueToFormAttribute(DocumentObject, "Object");
	FillInServiceDetails();
	FillInDependentServiceAttributes();
	FillInServiceDetailsOfSupply();
	
	FillInServiceDetailsOfTableParts();
	
	TMCommonUse.FillInDuplicateDependentPropsInCollection(
		Object.ManufacturedProduct, DependentDetails("ManufacturedProduct"));
		
	CalculateOrderTotals(ThisObject);
	UpdateColumnAvailableServer();
	
	Modified = True;
	
EndProcedure

&AtClientAtServerNoContext
Procedure SetKeysInProductLines(Items, Object, StringWithoutKey = Undefined)
	
	If Not StringWithoutKey = Undefined Then
		
		// A specific string is passed to the procedure
		If StringWithoutKey.RowCode = 0 Then
			
			StringWithoutKey.RowCode = Object.ProductsMaximumRowCode + 1;
			Object.ProductsMaximumRowCode = StringWithoutKey.RowCode;
			
		EndIf;
		
	Else
		
		// It is necessary to check the installation of the line code for all lines
		StringsWithoutKey = Object.ManufacturedProduct.FindRows(New Structure("RowCode", 0));
		
		If StringsWithoutKey.Count() > 0 Then
			
			CurrentCode = Object.ProductsMaximumRowCode;
			
			For Each StringWithoutKey In StringsWithoutKey Do
				
				CurrentCode = CurrentCode + 1;
				StringWithoutKey.RowCode = CurrentCode;
				
			EndDo;
			
			Object.ProductsMaximumRowCode = CurrentCode;
			
		EndIf;
		
	EndIf;
		
EndProcedure

&AtClientAtServerNoContext
Function ObjectParameters(Object, AttributesNames = "")
	
	If IsBlankString(AttributesNames) Then
		AttributesNames = "Partner, Contract, Counterparty, Organization";
	EndIf;
	
	ObjectParameters = New Structure(AttributesNames);
	FillPropertyValues(ObjectParameters, Object);
	
	Return ObjectParameters;
	
EndFunction

&AtServerNoContext
Function GiverSOrdersWithSameIncomingNumber(CurrentOrder, Counterparty, IncomingDocumentNumber)
	
	OrderDetails = Common.ObjectAttributeValue(CurrentOrder, "Date");
	IncomingDocumentDate = ?(ValueIsFilled(OrderDetails), OrderDetails, CurrentSessionDate());
	
	Query = New Query;
	Query.Text = 
	"SELECT ALLOWED
	|	MaterialProviderOrder2_5.Ref AS Ref
	|FROM
	|	Document.MaterialProviderOrder2_5 AS MaterialProviderOrder2_5
	|WHERE
	|	MaterialProviderOrder2_5.Ref <> &CurrentOrder
	|	AND MaterialProviderOrder2_5.Date BETWEEN &StartDate AND &EndDate
	|	AND MaterialProviderOrder2_5.NumberAccordingToPartnerData = &NumberAccordingToPartnerData
	|	AND MaterialProviderOrder2_5.Counterparty = &Counterparty
	|	AND NOT MaterialProviderOrder2_5.DeletionMark";
	
	Query.SetParameter("StartDate",			   AddMonth(IncomingDocumentDate, -3));
	Query.SetParameter("EndDate",		   AddMonth(IncomingDocumentDate, 3));
	Query.SetParameter("Counterparty",			   Counterparty);
	Query.SetParameter("CurrentOrder",		   CurrentOrder);
	Query.SetParameter("NumberAccordingToPartnerData", IncomingDocumentNumber);
	
	OrderList = New ValueList;
	OrderList.LoadValues(Query.Execute().Unload().UnloadColumn("Ref"));
	
	Return OrderList;
	
EndFunction

// Generates a list of specifications from the passed lines, deleting which will lead to changes in PM Materials.
// Parameters:
//	RowsIDs - Array - contains the row IDs of the products.
//	BillOfMaterials - CatalogRef.BillsOfMaterials - specific specification that needs to be checked.
//
&AtClient
Function SpecificationsForRemoval(RowsIDs, BillOfMaterials = Undefined)
	
	SpecificationsAfterRemoval = New Array;
	SpecificationsForRemoval = New Array;
	
	For Each ProductionLine In Object.ManufacturedProduct Do
		
		If Not RowsIDs.Find(ProductionLine.GetID()) = Undefined
			And (SpecificationsForRemoval.Find(ProductionLine.BillOfMaterials) = Undefined
				Or (Not BillOfMaterials = Undefined And SpecificationsForRemoval.Find(BillOfMaterials) = Undefined)) Then
				
			If Not BillOfMaterials = Undefined Then
				SpecificationsForRemoval.Add(BillOfMaterials);
			Else
				SpecificationsForRemoval.Add(ProductionLine.BillOfMaterials);
			EndIf;
			
			Continue;
			
		EndIf;
		
		If SpecificationsAfterRemoval.Find(ProductionLine.BillOfMaterials) = Undefined Then
			SpecificationsAfterRemoval.Add(ProductionLine.BillOfMaterials);
		EndIf;
		
	EndDo;
	
	TheStructureOfTheSearch = New Structure;
	TheStructureOfTheSearch.Insert("BillOfMaterials");
	
	Counter = SpecificationsForRemoval.Count() - 1;
	While Counter >= 0 Do
		
		ItemSpecification = SpecificationsForRemoval[Counter];
		TheStructureOfTheSearch.BillOfMaterials = ItemSpecification;
		
		ElementIndex = SpecificationsAfterRemoval.Find(ItemSpecification);
		If Not ElementIndex = Undefined 
			Or Object.UsedMaterials.FindRows(TheStructureOfTheSearch).Count() = 0 Then
			SpecificationsForRemoval.Delete(Counter);
		EndIf;
		
		Counter = Counter - 1;
		
	EndDo;
	
	Return SpecificationsForRemoval;
	
EndFunction

// Clears the rows in the PM Materials specifications.
// Parameters:
//  TabularSection - FormDataCollection -
//	Specifications - Array of CatalogRef.BillsOfMaterials - contains a list of specifications.
//
&AtClientAtServerNoContext
Procedure CleanMaterialsAccordingToSpecifications(TabularSection, Specifications)
	
	TheStructureOfTheSearch = New Structure("BillOfMaterials");
	For Each BillOfMaterials In Specifications Do
		
		TheStructureOfTheSearch.BillOfMaterials = BillOfMaterials;
		FoundRows = TabularSection.FindRows(TheStructureOfTheSearch);
		
		For Each String In FoundRows Do
			TabularSection.Delete(String);
		EndDo;
		
	EndDo;

EndProcedure

&AtServer
Procedure FillInServiceDetails()
	
	BusinessTransactionBeforeTheChange = Object.BusinessOperation;
	TypeOfProductionProcessBeforeTheChange = Object.ProductionProcessType;
	
EndProcedure

&AtServer
Procedure FillInDependentServiceAttributes(AttributesList = "")
	
	AttributesList = New Structure(AttributesList);
	Initialize = Not ValueIsFilled(AttributesList);
	
	// Production of manufactured products
	If Initialize
		Or AttributesList.Property("BusinessOperation") Then
		
		ManufacturedProductsProduced =
			Object.BusinessOperation = Enums.BusinessTransactions.TollManufacturing2_5
			Or Object.BusinessOperation = Enums.BusinessTransactions.Subcontracting2_5
			Or Object.BusinessOperation = Enums.BusinessTransactions.RepairProductsFromProvidedMaterials2_5;
		
		WorksAreBeingCarriedOut =
			Object.BusinessOperation = Enums.BusinessTransactions.TollManufacturing2_5
			Or Object.BusinessOperation = Enums.BusinessTransactions.PerformWorksUsingProvidedMaterials2_5
			Or Object.BusinessOperation = Enums.BusinessTransactions.PerformRMUsingProvidedMaterials2_5;
		
	EndIf;
	
	// Description of the finishedproduct being repaired
	If Object.BusinessOperation = Enums.BusinessTransactions.PerformRMUsingProvidedMaterials2_5
		And (Initialize
			Or AttributesList.Property("BusinessOperation")) Then
		
		ProductAttributes      = Common.ObjectAttributesValues(Object.UnderRepairProduct, "ItemsType, UseVariants");
		ItemsType            = ProductAttributes.ItemsType;
		UseVariants = ProductAttributes.UseVariants;
		
		OptionsArray = New Array;
		OptionsArray.Add(Enums.ItemVariantsUsageOptions.CommonForItemKind);
		OptionsArray.Add(Enums.ItemVariantsUsageOptions.CommonWithOtherItemKind);
		OptionsArray.Add(Enums.ItemVariantsUsageOptions.SpecialForItems);
		
		ItemVariantsAreUsed = Not (OptionsArray.Find(UseVariants) = Undefined);
		
	EndIf;
	
EndProcedure

&AtServer
Procedure FillInServiceDetailsOfTableParts()
	
	StructureOfActions = New Structure;
	AddToStructureActionsToUpdateVspAttributesOfLine(StructureOfActions);
	ProductsServer.FillInServiceDetailsForProductInCollection(Object.ManufacturedProduct, StructureOfActions);
	ProductsServer.FillInServiceDetailsForProductInCollection(Object.UsedMaterials, StructureOfActions);
	
	ProductionServer.FillInShopPantryAttributeInTable(Object.ManufacturedProduct);
	ProductionServer.FillInShopPantryAttributeInTable(Object.UsedMaterials);
	
EndProcedure

&AtServer
Function ParametersForFillingWarehouseInLine(TSName)
	
	If TSName = "ManufacturedProduct" Then
		
		Return BatchProcessingOfTablePartClientServer.GetWarehouseFillStructureInTSLine(Object, WarehouseGroup_);
		
	ElsIf TSName = "UsedMaterials" Then
		
		Return BatchProcessingOfTablePartClientServer.GetWarehouseFillStructureInTSLine(
																Object, ReceivingWarehouseGroup, "WarehouseForReceipt");
		
	EndIf;
	
EndFunction

&AtClientAtServerNoContext
Function DependentDetails(TSName)
	
	Result = New Structure;
	
	If TSName = "ManufacturedProduct" Then
		
		Result.Insert("Canceled", "Sum, VATAmount, AmountIncludingVAT");
		
	ElsIf TSName = "UsedMaterials" Then
		
		Result.Insert("Canceled", "Sum");
		
	EndIf;
	
	Return Result;
	
EndFunction

&AtClientAtServerNoContext
Function DependentDetailsAreRepresentedByLine()
	
	Return "SumCanceled, VATAmountCanceled, AmountIncludingVATCanceled";
	
EndFunction

&AtClientAtServerNoContext
Procedure CalculateOrderTotals(Form)
	
	UsedMaterials = Form.Object.UsedMaterials;
	ManufacturedProduct = Form.Object.ManufacturedProduct;
	
	Form.AmountOrdered    = ManufacturedProduct.Total("AmountIncludingVAT") - ManufacturedProduct.Total("AmountIncludingVATCanceled");
	Form.AmountNDSOrdered = ManufacturedProduct.Total("VATAmount") - ManufacturedProduct.Total("VATAmountCanceled");
	Form.SumCanceled    = ManufacturedProduct.Total("AmountIncludingVATCanceled");
	
	Form.MaterialsAmount = UsedMaterials.Total("Sum");
	
	DisplayTotalAmountOfVAT =
		VATAccountingERPClientServer.DisplayNDSInResultsOfSalesDocument(Form.Object.VATTaxation);
	
	If DisplayTotalAmountOfVAT Then
		Form.Items.GroupPagesTotalProducts.CurrentPage = Form.Items.PageTotalSndsproduction;
		Form.Items.VATPageGroup.CurrentPage = Form.Items.PageVAT;
	Else
		Form.Items.GroupPagesTotalProducts.CurrentPage = Form.Items.PageTotalWithoutNdsproduction;
		Form.Items.VATPageGroup.CurrentPage = Form.Items.PageExcludingVAT;
	EndIf;
	
EndProcedure

&AtServer
Procedure FillInDefaultContract()
	
	If Object.ARAPObjectSettings = Enums.ARAPObjectSettings.ByCounterpartyContracts 
	   And UseLinesOfBusiness Then
	
		Contract = SalesServer.GetDefaultContract(
						ObjectParameters(Object),
						Enums.BusinessTransactions.TollManufacturing2_5,
						Object.Currency,
						Object.LineOfBusiness);
	
	Else
	
		Contract = SalesServer.GetDefaultContract(
						ObjectParameters(Object),
						Enums.BusinessTransactions.TollManufacturing2_5,
						Object.Currency);
	
	EndIf;
	
	If Contract <> Object.Contract Then
		Object.Contract = Contract;
		WhenChangingAgreementServer();
	EndIf;
	
EndProcedure

&AtServer
Function FillWarehouseInSelectedLinesOnServer(Val ArrayOfSelectedRows, Warehouse, TSName)
	
	FilledWithRows = WarehousesServer.FillInWarehousesInSelectedLines(Object[TSName], ArrayOfSelectedRows, Warehouse);
	
	If FilledWithRows > 0 Then
		
		ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters[TSName]);
		WhenChangingWarehouseInTablePartServer(TSName);
		
		ObjectTable = Object[TSName];
		
		StructureOfActions = New Structure;
		StructureOfActions.Insert("FillInShopPantryAttribute");
		StructureOfActions.Insert(
			"RecalculateNumberOfUnits", ProductionClientServer.ParametersForRecalculatingNumberOfUnits());
		AddQualityControlActionsToStructure(StructureOfActions, CacheQualityControl);
		
		ValuesInCache = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
		RowsToProcess = New Array();
		For Each RowID In ArrayOfSelectedRows Do
			
			CurrentRow = ObjectTable.FindByID(RowID);	
			RowsToProcess.Add(CurrentRow);
			
		EndDo;
		
		BatchProcessingOfTablePartServer.ProcessTSStrings(
			RowsToProcess,
			StructureOfActions,
			ObjectTable,
			ValuesInCache);
			
	EndIf;
	
	Return FilledWithRows;
	
EndFunction

&AtServer
Procedure RefreshStatusServer()
	
	Documents.MaterialProviderOrder2_5.CalculateStatus(Object.Ref, Object.Contract, ThisObject);
	Items.State.Hyperlink = AccessRight("View", Metadata.Reports.DocumentFulfillmentStatus);
	If State = Enums.SalesOrderStates.ReadyForSupply Then
		State = NStr("vi = 'Sẵn sàng cho sản xuất';
					|ru = 'Готов к производству';
					|en = 'Ready for production'; fa = 'Ready for production';
					|it = 'Pronto alla produzione';
					|pl = 'Gotowy do produkcji';
					|tr = 'Üretime hazır'");
	EndIf;
	
EndProcedure

&AtClient
Procedure RefreshStatusClient(CheckTasksToReflectStateOfOrders = False, OrderState = Undefined)
	
	OrderState = SalesClient.StructureOfStateOfOrder();
	
	If CheckTasksToReflectStateOfOrders Then
		DocumentsStatesClient.CompleteStructureOfOrderState(OrderState);
	EndIf;
	
	FillPropertyValues(OrderState, ThisObject);
	
	CalculateStateOfOrder(
		Object.Ref,
		Object.Contract,
		OrderState,
		Items.State.Hyperlink,
		CheckTasksToReflectStateOfOrders);
	
	FillPropertyValues(ThisObject, OrderState);
	
	If State = PredefinedValue("Enum.SalesOrderStates.ReadyForSupply") Then
		State = NStr("vi = 'Sẵn sàng cho sản xuất';
					|ru = 'Готов к производству';
					|en = 'Ready for production'; fa = 'Ready for production';
					|it = 'Pronto alla produzione';
					|pl = 'Gotowy do produkcji';
					|tr = 'Üretime hazır'");
	EndIf;
	
EndProcedure

&AtServerNoContext
Procedure CalculateStateOfOrder(
			Ref,
			Contract,
			OrderState,
			Hyperlink,
			CheckTasksToReflectStateOfOrders = False)
	
	Documents.MaterialProviderOrder2_5.CalculateStatus(
		Ref,
		Contract,
		OrderState,
		CheckTasksToReflectStateOfOrders);
	
	Hyperlink = AccessRight("View", Metadata.Reports.DocumentFulfillmentStatus);
	
EndProcedure

&AtServer
Function PlaceProductsAndMaterialsInTemporaryStorageOnServer()
	
	Address = New Structure;
	Address.Insert(
		"ManufacturedProduct", PutToTempStorage(Object.ManufacturedProduct.Unload(New Structure("Canceled", False))));
	Address.Insert(
		"UsedMaterials", PutToTempStorage(Object.UsedMaterials.Unload(New Structure("Canceled", False))));
	
	Return Address;
	
EndFunction

&AtServerNoContext
Function WarehouseSelectionData(Warehouse)

	Query = New Query(
	"SELECT ALLOWED
	|	Warehouses.Ref AS Ref
	|FROM
	|	Catalog.Warehouses AS Warehouses
	|WHERE
	|	Warehouses.Ref IN HIERARCHY(&GroupOfWarehouses)
	|	AND Warehouses.IsFolder = FALSE
	|	AND Warehouses.SelectGroup <> VALUE(Enum.SelectWarehouseGroup.Disable)");

	Query.SetParameter("GroupOfWarehouses", Warehouse);
	WarehouseArray = Query.Execute().Unload().UnloadColumn("Ref");
	Return WarehouseArray;

EndFunction

&AtServer
Procedure UpdateVATTaxation_(Fill = True, CachedValues = Undefined)
	
	FillParameters = Documents.MaterialProviderOrder2_5.ParametersForFillingInVATTaxation_(Object);
	
	If Fill Then
		VATAccountingERP.FillInSalesVATTaxation(
			Object.VATTaxation, FillParameters, VATAccountingCachedParameterValues);
	EndIf;
	
	VATAccountingERP.FillInSalesVATTaxSelectionList(
		Items.VATTaxation,
		Object.VATTaxation,
		FillParameters,
		VATAccountingCachedParameterValues);
	
EndProcedure

&AtServer
Procedure FillMultiTurnContainersFromStorageServer(AddressOfContainerInStorage)
	
	StructureOfActionsWithModifiedStrings  = New Structure;
	StructureOfActionsWithModifiedStrings.Insert("RecalculateNumberOfPackages");
	StructureOfActionsWithModifiedStrings.Insert("RecalculateAmount");
	
	StructureOfActionsWithAddedStrings = Common.CopyRecursive(StructureOfActionsWithModifiedStrings);
	StructureOfActionsWithAddedStrings.Insert("CheckFillWarehouse", ParametersForFillingWarehouseInLine("UsedMaterials"));
	StructureOfActionsWithAddedStrings.Insert("FillInShopPantryAttribute");
	StructureOfActionsWithAddedStrings.Insert("CheckFillAssignment", Object.AssignmentMaterials);
	StructureOfActionsWithAddedStrings.Insert("FillInActionForRecyclableMaterials");
	
	StructureOfActionsWithAddedStrings.Insert("FillInProductNameOfProductPartner", Object.Partner);
	StructureOfActionsWithAddedStrings.Insert(
		"FillInPurchasePrice",
		BatchProcessingOfTablePartClientServer.GetStructureForFillingInPurchasePriceInTSLine(
			Object, "PriceTypeMaterials"));
	
	AddToStructureActionsToUpdateVspAttributesOfLine(StructureOfActionsWithAddedStrings);
	AddQualityControlActionsToStructure(StructureOfActionsWithAddedStrings, CacheQualityControl);
	
	ReusablePackageServer.FillMultiTurnContainersFromStorage(
		Object,
		AddressOfContainerInStorage,
		"UsedMaterials",
		"Products,Characteristic,Warehouse,DateOfReceipt",
		StructureOfActionsWithModifiedStrings,
		StructureOfActionsWithAddedStrings);
	
	WhenChangingWarehouseInTablePartServer("UsedMaterials");
	CalculateOrderTotals(ThisObject);
	
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

&AtClientAtServerNoContext
Function VATRateIsIndicatedInTablePart(BusinessOperation)
	
	Return
		BusinessOperation =
				PredefinedValue("Enum.BusinessTransactions.PerformWorksUsingProvidedMaterials2_5")
		Or BusinessOperation =
				PredefinedValue("Enum.BusinessTransactions.PerformRMUsingProvidedMaterials2_5");
	
EndFunction

&AtServer
Procedure FillInVATRateOnServer(ArrayOfSelectedRows)
	
	CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	
	RowsToProcess = New Array;
	If ArrayOfSelectedRows = Undefined Then
		For Each CurrentData In Object.ManufacturedProduct Do
			RowsToProcess.Add(CurrentData);
		EndDo;
	Else
		For Each CurrentID In ArrayOfSelectedRows Do
			RowsToProcess.Add(Object.ManufacturedProduct.FindByID(CurrentID));
		EndDo;
	EndIf;
	
	StructureOfActions = New Structure;
	AddActionToStructureFillInVATRate(Object, StructureOfActions);
	
	If Not VATRateIsIndicatedInTablePart(Object.BusinessOperation) Then
		
		BatchProcessingOfTablePartServer.ProcessTSString(Object, StructureOfActions, CachedValues);
		StructureOfActions.Clear();
		
		For Each CurrentData In RowsToProcess Do
			CurrentData.VATRate = Object.VATRate;
		EndDo;
		
	EndIf;
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	
	StructureOfActions.Insert("RecalculateVATAmount",  StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("FillInDuplicateDependentDetails", DependentDetails("ManufacturedProduct"));
	
	BatchProcessingOfTablePartServer.ProcessTSStrings(RowsToProcess, StructureOfActions, Object.ManufacturedProduct, CachedValues);
	
	CalculateOrderTotals(ThisObject);
	
EndProcedure

&AtServer
Procedure AddSBPPaymentStatusUpdateCommand()

	CommandParameters = CashServerLocalization.NewParametersOfSBPPaymentStatusUpdateCommand();
	CommandParameters.Parent = Items.MutualSettlementsGroup;
	CashServerLocalization.AddSBPPaymentStatusUpdateCommand(ThisObject, CommandParameters);

EndProcedure

&AtClient
Procedure Attachable_SBPPaymentVerification()

	CashClientLocalization.CheckSBPPayment(ThisObject, Object.Ref, Object.Counterparty);

EndProcedure

&AtServer
Procedure UpdateTextDocumentsBasedOn()
	
	If ValueIsFilled(Object.Ref) Then
		TextDocumentsBasedOn = VATAccountingLocalization.EventDocumentsOnPreliminaryDeliveries(Object, AmountOrdered);
		If ValueIsFilled(TextDocumentsBasedOn) Then
			Items.GroupDocumentsAboutUpcomingDelivery.Visible = True;
		Else
			Items.GroupDocumentsAboutUpcomingDelivery.Visible = False;
		EndIf;
	Else
		Items.GroupDocumentsAboutUpcomingDelivery.Visible = False;
	EndIf;
	
EndProcedure

#EndRegion

#Region DatesOfShipmentReceipt

&AtClient
Procedure FillInShipmentDate(ArrayOfSelectedRows = Undefined)
	
	DateOfShipment = Object.DateOfShipment;
	
	Notification = New CallbackDescription(
		"FillInShipmentDateCompletion", ThisObject, New Structure("ArrayOfSelectedRows", ArrayOfSelectedRows));
	
	TMCommonUseClient.EnterDateWithControlOfEmptyValue(
		DateOfShipment, NStr("vi = 'Hãy nhập ngày giao hàng';
							|ru = 'Введите дату отгрузки';
							|en = 'Enter shipment date'; fa = 'Enter shipment date';
							|it = 'Inserire la data di spedizione';
							|pl = 'Wprowadź datę wysyłki';
							|tr = 'Sevkiyat tarihini girin'"), DateFractions.Date, Notification);
	
EndProcedure

&AtClient
Procedure FillInShipmentDateCompletion(SelectedDate, AdditionalParameters) Export
	
	If SelectedDate <> Undefined And ValueIsFilled(SelectedDate) Then
		
		FillInShipmentEndDateATServer(SelectedDate, AdditionalParameters);
		SalesClient.NotifyEndOfFillingInShipmentDates(SelectedDate, (AdditionalParameters.ArrayOfSelectedRows <> Undefined));
		
	EndIf;
	
EndProcedure

&AtServer
Procedure FillInShipmentEndDateATServer(SelectedDate, AdditionalParameters)
	
	ArrayOfSelectedRows = AdditionalParameters.ArrayOfSelectedRows;
	
	FillInShippingDates(ThisObject, SelectedDate, ArrayOfSelectedRows);
	
	FillInVATRateOnServer(ArrayOfSelectedRows);
	
EndProcedure

&AtClient
Procedure FillInDateOfReceipt(ArrayOfSelectedRows = Undefined)
	
	If Object.UsedMaterials.Count() > 0 Then
		
		Notification = New CallbackDescription("FillInDateOfReceiptCompletion",
											  ThisObject,
											  New Structure("ArrayOfSelectedRows", ArrayOfSelectedRows));
		
		TMCommonUseClient.EnterDateWithControlOfEmptyValue(
			Object.Date, NStr("vi = 'Hãy nhập ngày tiếp nhận';
								|ru = 'Введите дату поступления';
								|en = 'Enter date of receipt'; fa = 'Enter date of receipt';
								|it = 'Inserire la data di arrivo';
								|pl = 'Wprowadź datę wpłaty';
								|tr = 'Teslim alma tarihini girin'"), DateFractions.Date, Notification);
		
	Else
		WarningText = NStr("vi = 'Trong chứng từ không có dòng để điền. Sẽ điền ngày tiếp nhận.';
							|ru = 'В документе нет строк для заполнения. Дата поступления не будет заполнена.';
							|en = 'There are no lines to fill in the document. The date of receipt will not be filled.'; fa = 'There are no lines to fill in the document. The date of receipt will not be filled.';
							|it = 'Nel documento non ci sono le righe per la compilazione. La data dell''arrivo non verrà compilata.';
							|pl = 'Brak wierszy do wypełnienia w dokumencie. Data wpłaty nie będzie wypełniona.';
							|tr = 'Belgede doldurulması gereken satır bulunmamaktadır. Teslim alım tarihi doldurulmayacaktır.'");
		ShowMessageBox(Undefined, WarningText);
	EndIf;
	
EndProcedure

&AtClient
Procedure FillInDateOfReceiptCompletion(SelectedDate, AdditionalParameters) Export
	
	If SelectedDate <> Undefined And ValueIsFilled(SelectedDate) Then
		
		DateOfReceipt = SelectedDate;
		ArrayOfSelectedRows = AdditionalParameters.ArrayOfSelectedRows;
		
		FillInDateOfReceiptOfEndATServer(SelectedDate, AdditionalParameters);
		PurchasesClient.NotifyAboutEndOfFillingInReceiptDates(DateOfReceipt, ArrayOfSelectedRows <> Undefined);
	
	EndIf;
	
EndProcedure

&AtServer
Procedure FillInDateOfReceiptOfEndATServer(SelectedDate, AdditionalParameters)
	
	DateOfReceipt = SelectedDate;
	ArrayOfSelectedRows = AdditionalParameters.ArrayOfSelectedRows;
	
	FillIn_ReceiptDates(DateOfReceipt, ArrayOfSelectedRows);
	
	If ArrayOfSelectedRows = Undefined Then
		ArrayOfSelectedRows = Object.UsedMaterials;
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Procedure FillInShippingDates(Form, DateOfShipment, Val ArrayOfSelectedRows)
	
	Object = Form.Object;
	
	If ArrayOfSelectedRows = Undefined Then
		
		For Each TSRow In Object.ManufacturedProduct Do
			TSRow.DateOfShipment = DateOfShipment;
		EndDo;
		
	Else
		
		For Each RowID In ArrayOfSelectedRows Do
			TSRow = Object.ManufacturedProduct.FindByID(RowID);
			TSRow.DateOfShipment = DateOfShipment;
		EndDo;
		
	EndIf;
	
EndProcedure

&AtServer
Function MaximumReceiptDate()
	
	MaximumReceiptDate = Date(1, 1, 1);
	For Each OwnGoods In Object.UsedMaterials Do 
		MaximumReceiptDate = Max(MaximumReceiptDate, OwnGoods.DateOfReceipt);
	EndDo;
	
	Return MaximumReceiptDate
	
EndFunction

&AtServer
Function MaximumShipmentDate()
	
	MaximumShipmentDate = Date(1, 1, 1);
	For Each OwnGoods In Object.ManufacturedProduct Do 
		MaximumShipmentDate = Max(MaximumShipmentDate, OwnGoods.DateOfShipment);
	EndDo;
	
	Return MaximumShipmentDate
	
EndFunction

&AtServer
Procedure FillIn_ReceiptDates(DateOfReceipt, Val ArrayOfSelectedRows)
	
	If Not ValueIsFilled(DateOfReceipt) Then
		DateOfReceipt = Undefined;
	EndIf;
	
	If ArrayOfSelectedRows = Undefined Then
		ArrayOfSelectedRows = Object.UsedMaterials;
	EndIf;
	
	RowsToProcess = New Array;
	For Each TSRow In ArrayOfSelectedRows Do
		
		If TypeOf(TSRow) = Type("Number") Then
			TSRow = Object.UsedMaterials.FindByID(TSRow);
		EndIf;
		
		If TSRow.Action = PredefinedValue("Enum.ActionsOnMaterialsToSubcontract.AcceptVMI") Then
			TSRow.DateOfReceipt = DateOfReceipt;
		EndIf;
		
		RowsToProcess.Add(TSRow);
		
	EndDo;
	
	If ValueIsFilled(RowsToProcess) Then
		StructureOfActions = New Structure;
		AddQualityControlActionsToStructure(StructureOfActions, CacheQualityControl);
		BatchProcessingOfTablePartServer.ProcessTSStrings(RowsToProcess, StructureOfActions, Object.UsedMaterials);
	EndIf;
	
EndProcedure

#EndRegion

#Region Delivery

&AtServer
Procedure FillInAndSetDeliveryAttributesServer(FormItemName);
	
	GoodsDelivery.FillInDeliveryDetails(Items, FormItemName, Object);
	
EndProcedure

&AtServer
Procedure SpecialTransportationConditionsOnChangeServer()
	
	GoodsDelivery.SpecialTransportationConditionsOnChange(Items, Object);
	
EndProcedure

&AtServer
Procedure SupplementDeliveryInformationWithContactsServer()
	
	GoodsDelivery.SupplementDeliveryInformationWithContacts(Object);
	
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

#Region WorkingWithClipboard

&AtServer
Procedure CopyLinesOnServer(TSName)
	
	ProcessingOfTabularForms.CopyRowsToClipboard(Object[TSName], Items[TSName].SelectedRows);
	
EndProcedure

&AtServer
Procedure GetLinesFromClipboard(TSName)
	
	If TSName = "ManufacturedProduct"
		And ManufacturedProductsProduced
		And Not WorksAreBeingCarriedOut Then
		ItemsTypes = ProductsClientServer.SelectionByProductMultiTurnContainer(False);
	ElsIf TSName = "ManufacturedProduct"
		And Not ManufacturedProductsProduced
		And WorksAreBeingCarriedOut Then
		ItemsTypes = ProductsClientServer.JobSelection(False);
	ElsIf TSName = "ManufacturedProduct" Then
		ItemsTypes = ProductsClientServer.SelectionByProductReusablePackagingWork(False);
	Else
		ItemsTypes = ProductsClientServer.SelectionByProductMultiTurnContainer(False);
	EndIf;
	
	FilterParameters = New Map;
	FilterParameters.Insert("Products.ItemsType", ItemsTypes);
	
	Columns =
		"PartnerProducts, Products, Characteristic, Action, Package, NumberOfPackages,
		|Price, DateOfReceipt, DateOfShipment, BillOfMaterials, Warehouse";
	
	TableOfGoods = ProcessingOfTabularForms.RowsFromClipboard(FilterParameters, Columns);
	
	If Not ValueIsFilled(TableOfGoods) Then
		Return;
	EndIf;
	
	VATRateIsIndicatedInTablePart = VATRateIsIndicatedInTablePart(Object.BusinessOperation);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
	StructureOfActions.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));
	StructureOfActions.Insert("CheckFillWarehouse", ParametersForFillingWarehouseInLine(TSName));
	StructureOfActions.Insert("FillInShopPantryAttribute");
	StructureOfActions.Insert(
		"RecalculateNumberOfUnits", ProductionClientServer.ParametersForRecalculatingNumberOfUnits());
	
	If TSName = "ManufacturedProduct" Then
		
		AddCollateralActionsOnServer(StructureOfActions, "SupplyOption,WarehouseIsRequired,DateOfShipmentRequired_");
		AddActionsToStructureWhenChangingNumberOfProductPackages(StructureOfActions, Object);
		
		If VATRateIsIndicatedInTablePart Then
			AddActionToStructureFillInVATRate(Object, StructureOfActions);
		EndIf;
		
	ElsIf TSName = "UsedMaterials" Then
		
		StructureOfActions.Insert("FillInActionForRecyclableMaterials");
		AddActionsToStructureWhenChangingNumberOfPackagesOfMaterials(StructureOfActions);
		AddQualityControlActionsToStructure(StructureOfActions, CacheQualityControl);
		StructureOfActions.Insert("CheckFillAssignment", Object.AssignmentMaterials);
		StructureOfActions.Insert("FillInProductNameOfProductPartner", Object.Partner);
		
	EndIf;
	
	CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	
	NewRowArray = New Array;
	ArrayOfDataOnProducts = New Array;
	
	RowsToProcess = New Array();
	
	For Each RowOfProduct In TableOfGoods Do
		
		If TSName = "ManufacturedProduct" Then
			
			CurrentRow = Object.ManufacturedProduct.Add();
			If Not VATRateIsIndicatedInTablePart Then
				CurrentRow.VATRate = Object.VATRate;
			EndIf;
			TabularSection = Object.ManufacturedProduct;
			
		ElsIf TSName = "UsedMaterials" Then
			
			CurrentRow = Object.UsedMaterials.Add();
			TabularSection = Object.UsedMaterials;
			
		EndIf;
		
		FillPropertyValues(CurrentRow, RowOfProduct);
		
		If TSName = "UsedMaterials" And Object.OneDateReceipt Then
			
			CurrentRow.DateOfReceipt = Object.DateOfReceipt;
			
		ElsIf TSName = "ManufacturedProduct" And Object.NotShipInInstallments Then
			
			CurrentRow.DateOfShipment = Object.DateOfShipment;
			
		EndIf;
		
		RowsToProcess.Add(CurrentRow);
		
	EndDo;
		
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		RowsToProcess,
		StructureOfActions,
		TabularSection,
		CachedValues);
	
	If TSName = "ManufacturedProduct" Then
		For Each RowOfProduct In TableOfGoods Do
			NewRowArray.Add(CurrentRow);
			ArrayOfDataOnProducts.Add(Documents.MaterialProviderOrder2_5.ItemData_3(Object, CurrentRow));
		EndDo;
	EndIf;
	
	CharacteristicsParameters = New Structure("Products", "ItemVariantsAreUsed");
	StructureOfActions = New Structure("FillInFeatureAttribute", CharacteristicsParameters);
	
	ProductsServer.FillInServiceDetailsForProductInCollection(Object[TSName], StructureOfActions);
	ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters[TSName]);
	
	If TSName = "ManufacturedProduct" Then
		ProductDataManagement.FillInSpecificationInLines(
			NewRowArray, ArrayOfDataOnProducts, BOMSelectionParameters);
		UpdateColumnAvailableServer();
	Else
		ReusablePackageServer.UpdateFillingStateOfMultiTurnContainer(
			Object.ReusablePackageFillingStatus);
	EndIf;
	
	WhenChangingWarehouseInTablePartServer(TSName);
	
	CalculateOrderTotals(ThisObject);
	
EndProcedure

#EndRegion

#Region ARAPAccounting

&AtServer
Procedure PlacePaymentStepsInTemporaryStorage(TagName)
	PaymentStepsServer.PlacePaymentStepsInTemporaryStorage(ThisObject, TagName);
EndProcedure

&AtServer
Procedure ReflectChangesToPaymentRules(ChangedBankingDetails)
	
	PaymentStepsServer.LoadPaymentStagesFromTemporaryStorage(ThisObject);
	ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisObject, ChangedBankingDetails, True);
	
	AddSBPPaymentStatusUpdateCommand();
	
EndProcedure

&AtClient
Procedure DecorationSettlementStateClick(Item, StandardProcessing)
	
	ARAPAccountingClient.CalculationsClick(ThisForm, Item, StandardProcessing);
	
EndProcedure

#EndRegion

#Region CancelLines

&AtClient
Procedure CancelSelectedLines(TSName, PresentationOfTS)
	
	If Object[TSName].Count() = 0 Then
		ShowMessageBox(Undefined, StrTemplate(NStr("vi = 'Chưa điền bảng ""%1"".';
													|ru = 'Таблица ""%1"" не заполнен.';
													|en = 'The ""%1"" table is not filled.'; fa = 'The ""%1"" table is not filled.';
													|it = 'Tabella ""%1"" non compilata.';
													|pl = 'Nie wypełniono tabeli ""%1"".';
													|tr = '""%1"" tablosu doldurulmamış.'"), PresentationOfTS));
		Return;
	ElsIf Items[TSName].SelectedRows.Count() = 0 Then
		ShowMessageBox(
			Undefined, StrTemplate(NStr("vi = 'Trong bảng ""%1"" không có dòng được chọn.';
										|ru = 'В таблице ""%1"" отсутствуют выделенные строки.';
										|en = 'There are no selected rows in the ""%1"" table.'; fa = 'There are no selected rows in the ""%1"" table.';
										|it = 'Nella tabella ""%1"" mancano le stringhe selezionate.';
										|pl = 'Brak wybranych wierszy w tabeli ""%1"".';
										|tr = '""%1"" tablosunda seçili satır yoktur.'"), PresentationOfTS));
		Return;
	EndIf;
	
	CancellationReason = Undefined;
	
	If TSName = "ManufacturedProduct" Then
		
		CancellationReason = PredefinedValue("Catalog.ReasonsForSaleOrderCancellation.EmptyRef");
		
		If UseReasonsForSalesOrderCancellations Then
			
			AdditionalParameters = New Structure;
			AdditionalParameters.Insert("TSName", TSName);
			
			OpenForm(
				"Catalog.ReasonsForSaleOrderCancellation.ChoiceForm",,,,,,
				New CallbackDescription("CancelSelectedLinesCompletion", ThisObject, AdditionalParameters),
				FormWindowOpeningMode.LockOwnerWindow);
			
			Return;
			
		EndIf;
		
	EndIf;
	
	UndoSelectedLineSnippet(TSName, CancellationReason);
	
EndProcedure

&AtClient
Procedure CancelSelectedLinesCompletion(Result, AdditionalParameters) Export
	
	CancellationReason = Result;
	If CancellationReason = Undefined Then
		Return;
	EndIf;
	
	UndoSelectedLineSnippet(AdditionalParameters.TSName, CancellationReason);
	
EndProcedure

&AtClient
Procedure UndoSelectedLineSnippet(TSName, Val CancellationReason)
	
	StructureOfActions = New Structure();
	StructureOfActions.Insert("FillInDuplicateDependentDetails", DependentDetails(TSName));
	
	If TSName = "ManufacturedProduct" Then
		MaterialCommunicationKeys = New Map;
	ElsIf TSName = "UsedMaterials" Then
		AddQualityControlActionsToStructure(StructureOfActions, CacheQualityControl);
	EndIf;
	
	ThereAreCanceledLines = False;
	
	For Each CurRow In Items[TSName].SelectedRows Do
		
		TableRow = Object[TSName].FindByID(CurRow);
		
		If TableRow <> Undefined Then
			
			If TSName = "ManufacturedProduct" Then
				TableRow.CancellationReason = CancellationReason;
			EndIf;
			
			If Not TableRow.Canceled Then
				
				TableRow.Canceled = True;
				ThereAreCanceledLines   = True;
				
				If TSName = "ManufacturedProduct" Then
					MaterialCommunicationKeys.Insert(TableRow.BillOfMaterials);
				EndIf;
				
			EndIf;
			
			If TSName = "ManufacturedProduct" Then
				AddCollateralActionsOnClient(StructureOfActions, "WarehouseIsRequired,DateOfShipmentRequired_");
			EndIf;
			
			BatchProcessingOfTablePartClient.ProcessTSString(TableRow, StructureOfActions, CachedValues);
			
		EndIf;
		
	EndDo;
	
	If TSName = "ManufacturedProduct" Then
		
		ProvisionInDocumentsClientServer.FillInServiceDetails(
			Object.ManufacturedProduct, DateOfShipmentRequired_, WarehouseIsRequired);
		
		CancelRelatedContent(MaterialCommunicationKeys);
		
	EndIf;
	
	CalculateOrderTotals(ThisObject);
	
	If ThereAreCanceledLines Then
		
		ShowUserNotification(
			NStr("vi = 'Các dòng đã chọn bị hủy bỏ';
				|ru = 'Выделенные строки отменены';
				|en = 'Selected lines are canceled'; fa = 'Selected lines are canceled';
				|it = 'Righe selezionate annullate';
				|pl = 'Zaznaczone wiersze anulowano';
				|tr = 'Seçili satırlar iptal edildi'"),,
			NStr("vi = 'Dòng được chọn trong đơn hàng bị hủy bỏ';
				|ru = 'Выделенные строки заказа отменены.';
				|en = 'Selected items are canceled from the order.'; fa = 'Selected items are canceled from the order.';
				|it = 'Righe selezionate dell''ordine sono annullate.';
				|pl = 'Wydzielone wiersze zamówienia zamówienia są anulowane.';
				|tr = 'Seçili sipariş satırları iptal edildi.'"),
			PictureLib.Information32);
		
		CancelSelectedLinesServer(TSName);
		
	Else
		ShowMessageBox(Undefined, NStr("vi = 'Các dòng đã chọn bị hủy bỏ.';
										|ru = 'Выделенные строки уже отменены.';
										|en = 'Selected lines are already canceled.'; fa = 'Selected lines are already canceled.';
										|it = 'Righe selezionate sono già state annullate.';
										|pl = 'Wybrane wiersze już są anulowane.';
										|tr = 'Seçili satırlar zaten iptal edildi.'"));
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Procedure UpdateSelectionOfRowsByCanceled(
			Items, TSName, HideCancelledRows, SetMarkHideCanceledLines = True)
	
	Items[TSName].RowFilter = 
		?(HideCancelledRows, New FixedStructure("Canceled", False), Undefined);
	
	If SetMarkHideCanceledLines Then
		
		If TSName = "ManufacturedProduct" Then
			
			Items.ProductsHideCanceledLines.Check = HideCancelledRows;
			
		ElsIf TSName = "UsedMaterials" Then
			
			Items.MaterialsHideCanceledLines.Check = HideCancelledRows;
			
		EndIf;
		
	EndIf;
	
EndProcedure	

// Cancels materials related to the canceled product.
// 
// Parameters:
//  MaterialCommunicationKeys - Map - Product and material communication keys.
//
&AtClient
Procedure CancelRelatedContent(MaterialCommunicationKeys)
	
	If MaterialCommunicationKeys.Count() = 0 Then
		Return;
	EndIf;
	
	FilterNotCancelledRows = New Structure;
	FilterNotCancelledRows.Insert("BillOfMaterials");
	FilterNotCancelledRows.Insert("Canceled", False);
	
	For Each ConnectionKey In MaterialCommunicationKeys Do
		
		FilterNotCancelledRows.BillOfMaterials = ConnectionKey.Key;
		
		ThereAreNonCanceledRows = Object.ManufacturedProduct.FindRows(FilterNotCancelledRows).Count() > 0;
		ThereAreUndoneLinesOfMaterials = Object.UsedMaterials.FindRows(FilterNotCancelledRows).Count() > 0;
		
		If Not ThereAreNonCanceledRows And ThereAreUndoneLinesOfMaterials Then
			Continue;
		EndIf;
		
		MaterialCommunicationKeys.Delete(ConnectionKey.Key);
		
	EndDo;
	
	If MaterialCommunicationKeys.Count() > 0 Then
		
		CancelRelatedContentServer(MaterialCommunicationKeys);
		
		UpdateSelectionOfRowsByCanceled(Items, "UsedMaterials", HideCanceledLinesMaterials, False);
		
	EndIf;
	
EndProcedure

// Cancels materials related to the canceled product.
// 
// Parameters:
//  MaterialCommunicationKeys - Map - Product and material communication keys.
//
&AtServer
Procedure CancelRelatedContentServer(MaterialCommunicationKeys)
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	SourceMaterials.LineNumber  AS LineNumber,
	|	SourceMaterials.RowCode    AS RowCode,
	|	SourceMaterials.Products AS Products,
	|	SourceMaterials.Package     AS Package,
	|	SourceMaterials.Count   AS Count,
	|	SourceMaterials.BillOfMaterials AS BillOfMaterials
	|INTO SourceMaterials
	|FROM
	|	&SourceMaterials AS SourceMaterials
	|
	|INDEX BY
	|	BillOfMaterials
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	UsedMaterials.LineNumber  AS LineNumber,
	|	UsedMaterials.RowCode    AS RowCode,
	|	UsedMaterials.Products AS Products,
	|	UsedMaterials.Package     AS Package,
	|	UsedMaterials.Count   AS Count
	|INTO UsedMaterials
	|FROM
	|	SourceMaterials AS UsedMaterials
	|WHERE
	|	UsedMaterials.BillOfMaterials IN (&Specifications)
	|
	|INDEX BY
	|	RowCode
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	PurchaseOrdersTurnovers.RowCode      AS RowCode,
	|	PurchaseOrdersTurnovers.OrderedExpense AS QuantityReceived_
	|INTO RevenueTable_
	|FROM
	|	AccumulationRegister.PurchaseOrders.Turnovers(
	|						,,,
	|						PurchaseOrder = &OrderDocument
	|						AND RowCode IN
	|								(SELECT
	|									UsedMaterials.RowCode AS RowCode
	|								FROM
	|									UsedMaterials AS UsedMaterials
	|								WHERE
	|									UsedMaterials.RowCode > 0)) AS PurchaseOrdersTurnovers
	|WHERE
	|	PurchaseOrdersTurnovers.OrderedExpense > 0
	|
	|INDEX BY
	|	RowCode
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	UsedMaterials.LineNumber                                                      AS LineNumber,
	|	UsedMaterials.RowCode                                                        AS RowCode,
	|	UsedMaterials.Count                                                       AS Count,
	|	UsedMaterials.Count - ISNULL(RevenueTable_.QuantityReceived_, 0) AS NumberOfCancellations,
	|	CASE
	|		WHEN UsedMaterials.Package = VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
	|			THEN 1
	|		ELSE &QueryTextPackagingFactor
	|	END                                                                      AS ZoomRatio
	|FROM
	|	UsedMaterials AS UsedMaterials
	|		LEFT JOIN RevenueTable_ AS RevenueTable_
	|		ON UsedMaterials.RowCode = RevenueTable_.RowCode
	|WHERE
	|	UsedMaterials.Count > ISNULL(RevenueTable_.QuantityReceived_, 0)";
	
	Query.Text = StrReplace(
						Query.Text,
						"&QueryTextPackagingFactor",
						Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
							"UsedMaterials.Package", "UsedMaterials.Products"));
	
	Query.SetParameter("OrderDocument", Object.Ref);
	
	Query.SetParameter(
				"SourceMaterials",
				Object.UsedMaterials.Unload(
					New Structure("Canceled", False),
					"LineNumber, RowCode, Products, Package, BillOfMaterials, Count"));
		
	Query.SetParameter(
				"Specifications",
				TMCommonUseClientServer.ConvertMatchOrStructureToArray(MaterialCommunicationKeys));
	
	RowsToProcess = New Array;
	ProcessedSplitLines = New Array;
	ProcessedNewLines = New Array;
	
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		
		LineTSMaterials = Object.UsedMaterials[Selection.LineNumber - 1];
		
		If Selection.Count = Selection.NumberOfCancellations Then
			
			LineTSMaterials.Canceled = True;
			
			RowsToProcess.Add(LineTSMaterials);
			
		Else
			
			NumberOfPackages = LineTSMaterials.NumberOfPackages;
			
			LineTSMaterials.Count         = Selection.Count - Selection.NumberOfCancellations;
			LineTSMaterials.NumberOfPackages = LineTSMaterials.Count / Selection.ZoomRatio;
			
			ProcessedSplitLines.Add(LineTSMaterials);
			
			// New line
			UndoString = Object.UsedMaterials.Add();
			FillPropertyValues(UndoString, LineTSMaterials,, "RowCode");
			UndoString.Count         = Selection.NumberOfCancellations;
			UndoString.NumberOfPackages = NumberOfPackages - LineTSMaterials.NumberOfPackages;
			UndoString.Canceled           = True;
			
			ProcessedNewLines.Add(UndoString);
			
		EndIf;
		
	EndDo;
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInDuplicateDependentDetails", DependentDetails("UsedMaterials"));
	StructureOfActions.Insert(
		"CheckSeriesCalculateStatus",
		New Structure("Warehouse, SeriesSpecificationParameters, TableOfGoods",
			Object.WarehouseForReceipt, SeriesSpecificationParameters.UsedMaterials, RowsToProcess));
	
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		RowsToProcess,
		StructureOfActions,
		Object.UsedMaterials);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateAmount");
	
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		ProcessedSplitLines,
		StructureOfActions,
		Object.UsedMaterials);
	
	StructureOfActions.Insert("FillInDuplicateDependentDetails", DependentDetails("UsedMaterials"));
	StructureOfActions.Insert(
		"CheckSeriesCalculateStatus",
		New Structure("Warehouse, SeriesSpecificationParameters, TableOfGoods",
			Object.WarehouseForReceipt, SeriesSpecificationParameters.UsedMaterials, RowsToProcess));
	
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		ProcessedNewLines,
		StructureOfActions,
		Object.UsedMaterials);
	
EndProcedure

#EndRegion

#Region Supply

&AtServer
Procedure UpdateColumnAvailableAfterInventoryAllocation()
	ProvisionInDocumentsServer.UpdateAvailabilityAfterRecording(ThisObject);
	RefreshStatusServer();
EndProcedure

&AtServer
Function ThereAreGoodsToSeparateProvision()
	
	DocumentAssignment = Documents.InventoryAssignmentAdjustment.OrderAssignment(Object.Ref);
	Return Documents.InventoryAssignmentAdjustment.ThereAreGoodsToSeparateProvision(DocumentAssignment);
	
EndFunction

&AtServer
Procedure UpdateAppointments()
	
	EmptyAssignment     = Catalogs.Assignments.EmptyRef();
	ProductTypeGoodsItem = Enums.ItemsTypes.OwnGoods;
	
	DestinationTemplateMaterials = Documents.MaterialProviderOrder2_5.DestinationTemplateMaterials(Object);
	Object.AssignmentMaterials = Catalogs.Assignments.FindByTemplate(DestinationTemplateMaterials);
	
	UpdateDestinationPresentation(DestinationTemplateMaterials);
	
	DestinationTemplateMaterials.AssignmentType = Undefined;
	
	References = Object.UsedMaterials.Unload(, "Purpose").UnloadColumn("Purpose");
	Templates = Catalogs.Assignments.TemplatesFromLinks(References);
	
	For Each String In Object.UsedMaterials Do
		
		Template = Templates.Get(String.Purpose);
		If Template = Undefined
		 Or Not (TMCommonUseClientServer.StructuresAreEqual(Template, DestinationTemplateMaterials, "LineOfBusiness,Contract,Partner")
				 And Catalogs.Assignments.TemplateIsSpecialCaseOfTemplate(Template, DestinationTemplateMaterials)) Then
			
			String.Purpose =
				?(String.ItemsType = ProductTypeGoodsItem, Object.AssignmentMaterials, EmptyAssignment);
			
		EndIf;
		
	EndDo;
	
EndProcedure

&AtServer
Procedure UpdateDestinationPresentation(DestinationTemplateMaterials = Undefined)
	
	If DestinationTemplateMaterials = Undefined Then
		DestinationTemplateMaterials = Documents.MaterialProviderOrder2_5.DestinationTemplateMaterials(Object);
	EndIf;
	
	DocumentAttributes = New Structure("Number, Date, Recipient", Object.Number, Object.Date, Object.Partner);
	PurposePresentation = Catalogs.Assignments.PresentationOfDestinationByTemplate(
		DestinationTemplateMaterials,
		DocumentAttributes);
	
EndProcedure

&AtServer
Function AddressOfMovementTableInRepository()
	
	Return ProvisionInDocumentsServer.AddressOfMovementTableInRepository(ThisObject);
	
EndFunction

&AtClientAtServerNoContext
Function DocumentParametersForSoftwareActions(Form, SecurityOptionAndFlagSeparately)
	
	DocumentParameters = New Structure();
	DocumentParameters.Insert("Form",                              Form);
	DocumentParameters.Insert("Collection",                          Form.Object.ManufacturedProduct);
	DocumentParameters.Insert("SecurityOptionAndFlagSeparately", SecurityOptionAndFlagSeparately);
	
	Return DocumentParameters;
	
EndFunction

&AtServer
Procedure FillInServiceDetailsOfSupply()
	
	DocumentParameters = DocumentParametersForSoftwareActions(ThisObject, SecurityOptionAndFlagSeparately);
	ProvisionInDocumentsServer.FillInServiceDetailsOfDocumentForm(DocumentParameters);
	
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
					Var_Parameters.ValueSelected, Var_Parameters.FormParameters, FillParameters);
	
	NotificationText1 = ProvisionInDocumentsClient.TextProcessingAlertsWarehouseAndBatchSelection(
						Var_Parameters.FormParameters.Mode);
	
	ShowUserNotification(NotificationText1,, Notification);
	
EndProcedure

&AtServer
Procedure CancelSelectedLinesServer(TSName)
	
	If SeriesSpecificationParameters[TSName].UseItemsBatch Then
		FillInStatusesForSpecifyingSeries(TSName);
	EndIf;
	
	UpdateColumnAvailableServer();
	
EndProcedure

&AtClient
Procedure AfterQuestionOfFillingPackageWithWholePackages(Response, Result) Export
	
	QuestionAsked = ProvisionInDocumentsClient.ShowQuestionUncheckShipOneDateAfterQuestion(
		ThisObject,
		Object.ManufacturedProduct,
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
	
	ThereAreChangesInDateOfShipment = False;
	Documents.MaterialProviderOrder2_5.AfterFillingOutCollateral(Object, Changes, Mode, FillParameters, ThereAreChangesInDateOfShipment);
	If ThereAreChangesInDateOfShipment Then
		ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisObject, "ManufacturedProduct.DateOfShipment");
	EndIf;
	SetVisibilityOfShippingDateFormElements();
	
	OrdersServer.RecalculateDependentPropsAfterSplittingRows(Changes, DependentDetailsAreRepresentedByLine());
	
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
		
	ProvisionInDocumentsClientServer.FillInServiceDetails(Object.ManufacturedProduct, DateOfShipmentRequired_, WarehouseIsRequired);
	
	WhenChangingWarehouseInTablePartServer("ManufacturedProduct");
	CalculateOrderTotals(ThisObject);
	
	UpdateColumnAvailableServer();
	
EndProcedure

&AtServer
Function SoftwareSelectionParameters(Mode)
	
	FormParameters = ProvisionInDocumentsServer.SoftwareSelectionParameters(
		ThisObject,
		Items.ManufacturedProduct.CurrentRow,
		Mode);
		
	Return FormParameters;
	
EndFunction

&AtClient
Function ParametersOfQuantityAndSeriesRequestForm(Mode)
	
	CheckParameters = SupplyClientServer.InitializeFillVerificationParameters("ManufacturedProduct",
		NStr("vi = 'Sản phẩm';
			|ru = 'Продукция';
			|en = 'Manufactured products'; fa = 'محصولات تولیدی';
			|it = 'Prodotti';
			|pl = 'Produkcja';
			|tr = 'İmal edilen ürünler'"));
	
	If Not SupplyClient.CheckFilling(
				Object,
				Object.ManufacturedProduct,
				Items.ManufacturedProduct.CurrentRow,
				CheckParameters,
				Object.Warehouse,
				Mode) Then
		Return Undefined;
	EndIf;
	
	FormParameters = SoftwareSelectionParameters(Mode);
	FormParameters.SeriesSpecificationParameters = SeriesSpecificationParameters.ManufacturedProduct;
	
	If Items.ManufacturedProduct.CurrentData.ItemsType = PredefinedValue("Enum.ItemsTypes.OwnGoods") Then
		FormParameters.AllowedNonIsolatedActions.Clear();
	EndIf;
	
	Return FormParameters;
	
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
	ElsIf Item.Name = "sh_ShamsiInput_DateOfShipment" Then
		DateOfShipmentOnChange(Items.DateOfShipment);
	ElsIf Item.Name = "sh_ShamsiInput_DateOfReceipt" Then
		DateOfReceiptOnChange(Items.DateOfReceipt);
	ElsIf Item.Name = "sh_ShamsiInput_ApprovalDate" Then
		ApprovalDateOnChange(Items.ApprovalDate);
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
