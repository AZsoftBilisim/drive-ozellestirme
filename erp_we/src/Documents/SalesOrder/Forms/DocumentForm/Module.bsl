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

	EmbeddingParameters = Documents.SalesOrder.AvailableRemainingEmbeddingOptions();
	ProvisionInDocumentsServer.AvailableBalancesWhenCreatedOnServer(ThisObject, EmbeddingParameters);
	
	SetConditionalAppearance();
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;

	InfobaseUpdate.CheckObjectProcessed(Object, ThisObject);

	// Handler of the "Versioning of objects" mechanism
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	
	// Handler of the "Properties" mechanism
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("Object", Object);
	AdditionalParameters.Insert("ItemForPlacementName", "GroupAdditionalAttributes");
	AdditionalParameters.Insert("DeferredInitialization", True);
	PropertyManager.OnCreateAtServer(ThisForm, AdditionalParameters);
	
	UseCustomerContracts = GetFunctionalOption("UseCustomerContracts");
	UseBusinessUnits = GetFunctionalOption("UseBusinessUnits");
	UseDiscountAdjustmentsInSales         = GetFunctionalOption("UseDiscountAdjustmentsInSales");
	UseDiscountsMarkupsInSales = GetFunctionalOption("UseDiscountsMarkupsInSales");
	TMCommonUse.CustomizePeripherals(ThisForm);
	
	UseRestrictionsOfManualDiscounts = GetFunctionalOption("UseLimitsForDiscountAdjustmentsInSalesByUsers")
	                                      Or GetFunctionalOption("UseLimitsForDiscountAdjustmentsInSalesByTermsOfSales");
	UseReasonsForSalesOrderCancellations = GetFunctionalOption("UseReasonsForSalesOrderCancellations");
	UseSimplifiedPaymentSchemeInSales = GetFunctionalOption("UseSimplifiedPaymentSchemeInSales");
	UseWarehousesInTabularSectionsOfSalesDocuments = GetFunctionalOption("UseWarehousesInTabularSectionsOfSalesDocuments");

	UseLoyaltyCards  = GetFunctionalOption("UseLoyaltyCards");
	UseLoyaltyPrograms = UseLoyaltyPrograms(Object.LoyaltyCard);
	SetVisibilityOfElementsOfLoyaltyBonusProgram();
	
	UsePriceManagementSystem25 = PriceManagementSystemServerCall.UsePriceManagementSystem25();
	
	AttributeSelectionParameters = PaymentStepsServer.ParametersForSelectingPaymentDetails(Metadata.Documents.SalesOrder);
	
	If Not ValueIsFilled(Object.Ref) Then
		
		OnReadCreateAtServer();
		ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);
		If ValueIsFilled(Object.Partner) Then
			FillInAndSetDeliveryAttributesServer("Partner");
		EndIf;
	EndIf;
	
	If Not UseWarehousesInTabularSectionsOfSalesDocuments And Not UseBusinessUnits Then
		Items.ProductsGroupSender.Visible = False;
	ElsIf Not WarehouseGroup_ Then
		Items.ProductsGroupSender.Title = NStr("vi = 'Bộ phận gửi';
												|ru = 'Подразделение-отправитель';
												|en = 'Shipping business unit'; fa = 'واحد تجاری ارسال‌کننده';
												|it = 'Unità-mittente';
												|pl = 'Shipping business unit';
												|tr = 'Gönderen departman'");
	EndIf;
	
	If ClientApplication.CurrentInterfaceVariant() = ClientApplicationInterfaceVariant.Version8_2 Then
		Items.GroupInTotal.BackColor = New Color();
	EndIf;
	
	TMCommonUseClientServer.SetFormItemProperty(Items, "DocumentBasis", "Visible", ValueIsFilled(Object.DocumentBasis));
	
	UseContracts =
		Object.BusinessOperation = Enums.BusinessTransactions.TransferToStorageWithRightOfSale
		Or Object.BusinessOperation = Enums.BusinessTransactions.DeliveryForPrincipal
		Or (ConsignmentSales25 And Object.BusinessOperation = Enums.BusinessTransactions.TransferToCommissionAgent);
	SalesServer.SetBlankContractMark(Items, "Contract", UseContracts);
	
	SalesServer.SetModeForSelectingGroupsOfWarehouseItems(Items.Warehouse);
	ReadPriceTypeRight = AccessRight("View", Metadata.Documents.SalesOrder.TabularSections.Goods.Attributes.PriceKind);

	Items.GoodsPriceKind.QuickChoice = Not GetFunctionalOption("UseSeveralPriceTypes");
	
	DiscountsMarkupsFillingServer.ConfigureShowMessagesCommand(Object, Items.ShowMessages);
	
	Items.DecorationShipmentDate.Visible = Not UseShipmentByRowsInSalesOrder And Object.NotShipInInstallments;
	
	Items.GoodsGroupCancel.Visible                        = GetFunctionalOption("UseReasonsForSalesOrderCancellations");
	Items.ProductsCanceledCancellationReasonsAreNotUsed.Visible = Not GetFunctionalOption("UseReasonsForSalesOrderCancellations");
	
	Enums.SalesOrderStatuses.FillChoiceList(Items.Status.ChoiceList, Object.Status);
	
	Items.CloseOrder.Enabled = AccessRight("Update",Metadata.Documents.SalesOrder);
	
	// It makes no sense to show the user information about the calculation of discounts to which there is no access.
	Items.GroupProductsInformationAboutDiscounts.Enabled      = AccessRight("View", Metadata.Catalogs.DiscountsMarkups);
	Items.GoodsAssignAutomaticDiscounts.Enabled = AccessRight("View", Metadata.Catalogs.DiscountsMarkups);
	
	Items.GoodsCancelUndeliveredLines.Visible    = Not Object.ThisIsOrderAsInvoice;
	
	SetAvailabilityOfClipboardCommands();
	
	If GoodsDeliveryClientServer.UsedDelivery20() Then
		
		ElementsToFillIn = New Array;
		ElementsToFillIn.Add(Items.DeliveryTimeFrom);
		ElementsToFillIn.Add(Items.DeliveryTimeTo);
		ElementsToFillIn.Add(Items.DeliveryTimeFrom1);
		ElementsToFillIn.Add(Items.DeliveryTimeTo1);
		GoodsDeliveryClientServer.FillTimeFieldSelectionList(ElementsToFillIn);
		
	EndIf;
	
	PrepareAndSetVisibilityForAssemblyAndDelivery();
	
	ARAPAccountingFormWork.FormWhenCreatedOnServer(ThisForm);
	NotifyAboutCreationOfCalculationObject = Parameters.NotifyAboutCreationOfCalculationObject;
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject);
	// End IntegrationWith1CDocumentManagementSubsystem

	Items.DecorationEDOState.Visible = GetFunctionalOption("UseElectronicDocumentExchangeWithCounterparties");
	

	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	UpdateSalesTagForTobaccoProductsOnlyByMRCLocalization(ThisObject);
	
	// StandardSubsystems.FilesOperations
	HyperlinkParameters = FilesOperations.FilesHyperlink();
	HyperlinkParameters.Location = "CommandBar";
	FilesOperations.OnCreateAtServer(ThisObject, HyperlinkParameters);
	// End StandardSubsystems.FilesOperations
	
	

	VATAccountingERP.SetVisibilityOfCommandAndFillInVATRate(ThisObject);
	
	AddSBPPaymentStatusUpdateCommand();

EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)

	// StandardSubsystems.AccessManagement
	AccessManagement.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.AccessManagement
	
	EmbeddingParameters = Documents.SalesOrder.AvailableRemainingEmbeddingOptions();
	ProvisionInDocumentsServer.AvailableBalancesWhenReadingOnServer(ThisObject, EmbeddingParameters);
	
	OnReadCreateAtServer();
	PropertyManager.OnReadAtServer(ThisForm, CurrentObject);
	
	ARAPAccountingFormWork.FormWhenReadingOnServer(ThisForm);
	
	ConfigurationModificationOverridable.OnReadAtServer(ThisForm, CurrentObject);
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	// End StandardSubsystems.AttachableCommands

	
	UpdateSalesTagForTobaccoProductsOnlyByMRCLocalization(ThisObject);
	
EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	
	// StandardSubsystems.Properties
	PropertyManager.FillCheckProcessing(ThisForm, Cancel, CheckedAttributes);
	// End StandardSubsystems.Properties
	
EndProcedure

&AtClient
Procedure BeforeWrite(Cancel, WriteParameters)
	
	If NotExecuteCheck1BeforeWrite Then
		NotExecuteCheck1BeforeWrite = False;
		Return;
	EndIf;
	
	// If the document is carried out, we will check the calculation of discounts and the correctness of the payment schedule for the order.
	If WriteParameters.WriteMode = DocumentWriteMode.Posting Then
		
		Cancel = True;
		AdditionalParameters = New Structure;
		AdditionalParameters.Insert("WriteParameters", WriteParameters);
		ReusablePackageClient.OfferToPickUpMultiTurnContainer(
			ThisForm,
			"Goods",
			"Products,Characteristic,Count,Warehouse,DateOfShipment",
			New CallbackDescription("BeforeRecordingOfferToPickUpMultiTurnContainer", ThisObject, AdditionalParameters));
		
	EndIf;
		
	TMCommonUseClient.RecordObjectIfNecessary(ThisObject, WriteParameters, Cancel);
		
EndProcedure

&AtClient
Procedure BeforeRecordingOfferToPickUpMultiTurnContainer(Result, AdditionalParameters) Export
	
	Cancel = False;
	
	TransferOperations_ = GoodsTransferOperations();
	
	If UseDiscountsMarkupsInSales
		And TransferOperations_.Find(Object.BusinessOperation) = Undefined Then
		
		If Not Object.DiscountsAreCalculated And DiscountsHaveChanged() Then
			ApplyDiscountMarkUpChangesOnCustomer(Cancel);
		Else
			Object.DiscountsAreCalculated = True;
		EndIf;
		
	EndIf;
	
	If Not Object.NotShipInInstallments Then
		
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
	
	BeforeWriteAtClientServer();
	
	CalculateOrderTotals(ThisForm);
	
	If Not Cancel Then
		TMCommonUseClient.RecordObjectIfNecessary(ThisObject, AdditionalParameters.WriteParameters,,True);
	EndIf;
	
EndProcedure

&AtClient
Procedure BeforeRecordingAskQuestionAboutResettingScheduleONChangesInShipmentDateEnd(Result, AdditionalParameters) Export
	
	If Result = DialogReturnCode.Yes Then
		Object.PaymentScheduleSteps.Clear();
	EndIf;
	ARAPAccountingClient.QuestionAboutResettingScheduleONChangesInShippingDatesHasBeenAsked(ThisObject);
	
	BeforeWriteAtClientServer();
	CalculateOrderTotals(ThisForm);
	
	TMCommonUseClient.RecordObjectIfNecessary(ThisObject, AdditionalParameters.WriteParameters,,True);
	
EndProcedure

&AtServer
Procedure BeforeWriteAtClientServer()
	ARAPAccountingServerCall.FormBeforeRecordingOnClientServer(ThisForm);
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
		
	// Handler of the "Properties" mechanism
	PropertyManager.BeforeWriteAtServer(ThisForm, CurrentObject);

	ARAPAccountingServer.BeforeWriteAtServer(ThisForm, CurrentObject);
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
	
	SetAvailabilityOfItemsByStatusServer();
	
	FillInServiceDetailsForProductRange();
	
	UpdateDuplicateDependentDetails();
	FillInServiceDetailsOfDocumentForm();
	ProvisionInDocumentsServer.AfterWriteAtServer(ThisObject);
	SetSoftwareVisibility();
	ARAPAccountingFormWork.FormAfterRecordingOnServer(ThisForm, CurrentObject.AdditionalProperties);
	
	
	InitiateReceiptOfDocumentsBasedOn();
	
	
	AdditionalVerificationCondition = GetFunctionalOption("UseAdvancedFeaturesOfSalesOrder")
									And AccessRight("Read", Metadata.AccumulationRegisters.CustomersARAPAccounting)
									And Not Object.ThisIsOrderAsInvoice;
	
	DocumentsStates.AfterWriteAtServer(
		ThisObject,
		WriteParameters,,,
		AdditionalVerificationCondition);
	
	If DocumentsStates.TaskCheckForReflectingStateOfOrdersIsNotRunning(ThisObject) Then
		RefreshStatusServer();
	EndIf;
	
	UnlockFormDataForEdit();
	
	FormEventsLocalization.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	
	ConfigurationModificationOverridable.AfterWriteAtServer(ThisForm, CurrentObject, WriteParameters);
	
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	
	FormModified = Undefined;
	Attachable_WhenChangingModifiabilityOfForm();
	
	WriteParameters.Insert("SalesOpportunity", Object.SalesOpportunity);
	Notify("Write_SalesOrder", WriteParameters, Object.Ref);
	
	ARAPAccountingClient.FormAfterRecording(ThisForm);
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
	
	EnableWaitingHandlerForDocumentDataBasedOn();
	
	DocumentsStatesClient.AfterWrite(ThisObject, "Attachable_CheckTasksToReflectStateOfOrders");
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	// Handler of the "Properties" mechanism
	If PropertyManagerClient.ProcessNotifications(ThisForm, EventName, Parameter) Then
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
	
	If ARAPAccountingClient.NeedAlertProcessingCall(ThisObject, EventName, Parameter) Then
		PaymentCreditedServer(EventName, Parameter, Source);
	EndIf;
	
	If EventName = "UpdateInformationSecurityDocumentAfterFillingItOut"  And Parameter.Find(Object.Ref) <> Undefined Then
		Read();
	ElsIf EventName = "UpdateIBDocumentAfterFillingItOutFromFile"  And Parameter.Find(Object.Ref) <> Undefined Then
		OnReadCreateAtServer();
	EndIf;
	
	If EventName = "LoyaltyCardIsRead"
		And Parameter.OwnerForm = UUID Then
		LoyaltyCardIsRead(New CallbackDescription("NotificationProcessingCompletion", ThisObject, New Structure("EventName, Parameter", EventName, Parameter)), Parameter.LoyaltyCard);
        Return;
	EndIf;
	
	
	
	HandlingFragmentAlerts(EventName, Parameter);
	
	// StandardSubsystems.FilesOperations
	FilesOperationsClient.NotificationProcessing(ThisObject, EventName);
	// End StandardSubsystems.FilesOperations

	If EventName = "Write_CustomerInvoiceServices"
		Or EventName = "Write_CashAccountReceiptNote"
		Or EventName = "Write_CustomerInvoice"
		Or EventName = "Write_TransferOfGoodsToBailee" Then
		
		InitiateReceiptOfDocumentsBasedOn();
		EnableWaitingHandlerForDocumentDataBasedOn();
		
	EndIf;
	
	If EventName = "WhenChangingAgreement"
		And Source = ThisObject Then
		Modified = True;
		If ValueIsFilled(Object.Ref) Then
			Attachable_WhenChanging_SetAvailabilityOfItemsByStatusServer(Items[Parameter]);
		Else
			ContractOnChange(Items[Parameter]);
		EndIf;
	EndIf;
	
	If EventName = "SBPStatusHasBeenChanged" Then
		AddSBPPaymentStatusUpdateCommand();
		CashClientLocalization.CheckSBPPayment(ThisObject, Object.Ref, Object.Counterparty);
	EndIf;
	
	If EventName = "StatusOfOnlineOrderHasBeenChanged" Then
		CashClientLocalization.CheckOnlineOrderPayment(ThisObject, Object.Ref);
	EndIf;
	
EndProcedure

&AtClient
Procedure NotificationProcessingCompletion(Result, AdditionalParameters) Export
    
    EventName = AdditionalParameters.EventName;
    Parameter = AdditionalParameters.Parameter;
    
    
    HandlingFragmentAlerts(EventName, Parameter);

EndProcedure

&AtClient
Procedure HandlingFragmentAlerts(Val EventName, Val Parameter)
    
    Var SetAddressInTemporaryStorage, SetParameters, OpeningParameters;
    
    If EventName = "MessagesReceived"
        And Parameter.OwnerForm = UUID Then
        MessagesReceived(Parameter.Messages);
    EndIf;
    
    If EventName = "ChangedStatusDependentBankingDetails"
        And Parameter.UUID = UUID Then
        If Object.Approved Then
            Object.Approved = False;
        EndIf;
        AttachIdleHandler("Attachable_WhenChangingDetailsDependingOnStatus", 0.1, True);
    EndIf;
    
    If EventName = "CopyingLinesToClipboard" Then
        
        SetAvailabilityOfClipboardCommandsOnClient();
        
    EndIf;
    
    If EventName = "AddingPartnerToSegment"
        Or EventName = "RemovingPartnerFromSegment" Then
        
        SetVisibilityOfShipmentBanToPartner();
    EndIf;
    
    If EventName = "Closing_EditingSet"
        And Parameter.OwnerForm = UUID Then
        AtEndOfEditingSet(Parameter.AddressInTempStorage);
        DiscountsMarkupsFillingClient.ResetDiscountsCalculatedFlag(ThisForm);
        ProvisionInDocumentsClientServer.FillInServiceDetails(Object.Goods, DateOfShipmentRequired_, WarehouseIsRequired);
   EndIf;
    
    If EventName = "EditSet" 
        And Parameter.OwnerForm = UUID Then
        
        SetParameters = New Structure;
        SetParameters.Insert("ProductsInSet", Parameter.ProductsInSet);
        SetParameters.Insert("ItemVariantOfSet", Parameter.ItemVariantOfSet);
        SetParameters.Insert("DialColumns", DialColumns(ThisForm));
        
        SetAddressInTemporaryStorage = SetAddressInTemporaryStorage(SetParameters);
        
        OpeningParameters = New Structure;
        OpeningParameters.Insert("AddressInTempStorage", SetAddressInTemporaryStorage);
        OpeningParameters.Insert("ProductsInSet",   Parameter.ProductsInSet);
        OpeningParameters.Insert("ItemVariantOfSet", Parameter.ItemVariantOfSet);
        OpeningParameters.Insert("PriceIncludesVAT", Object.PriceIncludesVAT);
        OpeningParameters.Insert("VATTaxation", Object.VATTaxation);
        OpeningParameters.Insert("Currency", Object.Currency);
		OpeningParameters.Insert("Partner", Object.Partner);
        OpeningParameters.Insert("Terms", Object.Terms);
        OpeningParameters.Insert("Date", Object.Date);
        OpeningParameters.Insert("Ref", Object.Ref);
        OpeningParameters.Insert("Warehouse", Object.Warehouse);
        OpeningParameters.Insert("Organization", Object.Organization);
        OpeningParameters.Insert("HideCommandRemainingQuantityInWarehouses", False);
		
        OpenForm("DataProcessor.EditSet.Form.Form", OpeningParameters, ThisForm, UUID);
        
    EndIf;

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
	
	EnableWaitingHandlerReceivingCarriers();
	EnableWaitingHandlerForDocumentDataBasedOn();
	
	CashClientLocalization.AttachablePaymentVerificationViaServices(ThisObject, Object.Ref, Object.Counterparty);
	
EndProcedure

&AtServer
Procedure BeforeLoadDataFromSettingsAtServer(Settings)
	
	HideCanceledLines =  Settings.Get("HideCanceledLines");
	
	If HideCanceledLines Then
		Items.Goods.RowFilter = New FixedStructure("Canceled", False);
	Else
		Items.Goods.RowFilter = Undefined;
	EndIf;
	
	Items.GoodsHideCanceledLines.Check = HideCanceledLines;
	If Not Object.Ref.IsEmpty() Or Not UseShipmentByRowsInSalesOrder Then
		Settings.Delete("Object.NotShipInInstallments");
	EndIf;
	
EndProcedure

&AtServer
Procedure OnLoadDataFromSettingsAtServer(Settings)
	
	SetVisibilityOfShippingDateFormElements();
	
EndProcedure

&AtClient
Procedure ChoiceProcessing(ValueSelected, ChoiceSource)
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.StartTimeMeasurement(
		True, "Document.SalesOrder.Form.DocumentForm.Event.ChoiceProcessing");

	If ChoiceSource.FormName = "DataProcessor.OrderSupplyForecast.Form.Form" Then
		
		AddressOfTheMovementTable = FillInCollateralFromCollateralStateForm(
			ValueSelected.ActionCode,
			ValueSelected.AddressAnalyst,
			ValueSelected.FillParameters);
			
		// Returning the control to the form of processing the security status.
		RunCallback(ValueSelected.Callback, AddressOfTheMovementTable);
		
	ElsIf ChoiceSource.FormName = "Document.SalesOrder.Form.PrintDetails" Then
		
		If ValueSelected <> Undefined Then
			
			Modified = True;
			
			If GoodsDeliveryClientServer.UsedDelivery25() Then
				
				If CommonClientServer.HasAttributeOrObjectProperty(ValueSelected, "DeliveryZone") Then
					FillPropertyValues(Object, ValueSelected,, "DeliveryZone");
				EndIf;
				
				FillInAndSetDeliveryAttributes = False;
				If Not Object.DeliveryIsRequired
					Or (Object.DeliverySpecificationMethod = PredefinedValue("Enum.DeliverySpecificationMethods.ByRows")
							And Object.DeliveryIsRequired) Then
					
					FillInAndSetDeliveryAttributes = (Object.GoodsRecipient <> ValueSelected.GoodsRecipient);
					
				EndIf;
				
			Else
				
				FillInAndSetDeliveryAttributes = (Object.GoodsRecipient <> ValueSelected.GoodsRecipient);
				FillPropertyValues(Object, ValueSelected);
				
			EndIf;
			
			If FillInAndSetDeliveryAttributes Then
				FillInAndSetDeliveryAttributesServer("GoodsRecipient");
			EndIf;
			
		EndIf;
		
	ElsIf ChoiceSource.FormName = "DataProcessor.SelectGoodsToSalesDocument.Form.Form" Then
		
		HandlingSelectionSelectionOnClient(ValueSelected);
		
	ElsIf ChoiceSource.FormName = "DataProcessor.SelectReusablePackage.Form.Form" Then
				
			FillMultiTurnContainersFromStorageServer(ValueSelected.AddressOfReusableContainerInStorage);
			ReusablePackageClient.NotifyUserAboutFillingMultiTurnContainers();
			DiscountsMarkupsFillingClient.ResetDiscountsCalculatedFlag(ThisForm);
		
	ElsIf ChoiceSource.FormName = "Catalog.BusinessStructure.Form.ChoiceForm" Then
		
		SalesClient.ProcessingUnitSelection(Object.Goods, Items.Goods.SelectedRows, ValueSelected);
	
	ElsIf ProductsClient.ThisIsIndicationOfSeries(ChoiceSource) Then
		
		ProductsClient.ProcessSeriesIndication(ThisForm, SeriesSpecificationParameters, ValueSelected);
		
		ProductsSeriesRecalculatePrices();
		
	ElsIf ChoiceSource.FormName = "DataProcessor.OrderClosureWizard.Form.ClosureForm" Then
		
		AdjustOrderLines(ValueSelected);
		
	ElsIf ChoiceSource.FormName = "Catalog.Persons.Form.ListForm" Then
		
		Object[CurrentItem.Name] = ValueSelected;
		
	EndIf;
	ProvisionInDocumentsClientServer.FillInServiceDetails(Object.Goods, DateOfShipmentRequired_, WarehouseIsRequired);

EndProcedure

&AtClient
Procedure BeforeClose(Cancel, StandardProcessing)
	
	ForceCloseTheForm = True;
	
EndProcedure

&AtClient
Procedure OnClose(Exit)

	EquipmentManagerClient.StartDisablingHardwareWhenClosingForm(Undefined, ThisForm);

	If Not Exit 
		And ValueIsFilled(Object.Ref)
		And NotifyAboutCreationOfCalculationObject Then
		ARAPAccountingClient.FormWhenClosing(ThisObject);
	EndIf;
	
	CashClientLocalization.DisablePaymentVerificationViaServices(ThisObject);
	
EndProcedure

&AtServer
Procedure OnWriteAtServer(Cancel, CurrentObject, WriteParameters)
	

EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure GroupPagesOnCurrentPageChange(Item, CurrentPage)
	
	// StandardSubsystems.Properties
	If CurrentPage.Name = "AdvancedGroup" Then 
		If Not ThisObject.PropertiesParameters.DeferredInitializationExecuted Then 
			PropertiesExecuteDeferredInitialization();
			PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
		EndIf;
		FillInSalesVATTaxSelectionList();
	EndIf;
	// End StandardSubsystems.Properties
	
	ARAPAccountingClient.UpdateHyperlinkTextPaymentSteps(ThisForm);
	
EndProcedure

&AtClient
Procedure TermsStartChoice(Item, ChoiceData, StandardProcessing)
	
	AgreementSelectionParameters = SalesClient.ParametersForStartingSelectionOfAgreementWithClient();
	
	AgreementSelectionParameters.Item                     = Item;
	AgreementSelectionParameters.Partner                     = Object.Partner;
	AgreementSelectionParameters.Document                    = Object.Terms;
	AgreementSelectionParameters.DocumentDate               = Object.Date;
	AgreementSelectionParameters.FormDataStructure        = Object;

	SalesClient.StartSelectingAgreementWithClient(AgreementSelectionParameters, StandardProcessing);

EndProcedure

&AtClient
Procedure ContractCreating(Item, StandardProcessing)
	
	SalesClient.OpenContractCreationForm(ThisObject, Item, "Object.Contract", Object.Partner, StandardProcessing);
	
EndProcedure

&AtClient
Procedure ContractOnChange(Item)
	
	ContractParameters = ContractParameters(Object.Contract, Object.BusinessOperation);
	If ContractParameters.ByNewCommission And ValueIsFilled(ContractParameters.AccountingPriceType) Then
		Notification = New CallbackDescription("ContractOnChangeCompletion", ThisObject);
		EnterprisePricesFillingClient.AskQuestionAboutRecalculatingPriceWhenChangingAgreement(Object, Notification);
	Else
		ContractOnChangeServer();
		
	
	EndIf;
	
EndProcedure

&AtClient
Procedure ContractOnChangeCompletion(QuestionResult, AdditionalParameters) Export 
	
	ClearMessages();
	
	If Not QuestionResult = DialogReturnCode.Cancel And QuestionResult Then
	
		TypeOfContractPrice = AccountingTypeOfContractPrice(Object.Contract);
		
		If EnterprisePricesFillingClient.YouNeedToFillInPricesByType(Object, TypeOfContractPrice) Then
			
			ErrorText = "";
			PricesCalculated = FillThePricesByTermsOfSalesServer(True,ErrorText);
			DiscountsMarkupsFillingClient.ResetDiscountsCalculatedFlag(ThisForm);
			SalesClient.NotifyAboutEndOfFillingInPricesUnderAgreement(PricesCalculated, ErrorText);
			
		EndIf;
		
	EndIf;
		
	ContractOnChangeServer();
		
EndProcedure

&AtServer
Procedure ContractOnChangeServer()
	
	ForeignCurrencyTransaction = Object.ForeignCurrencyTransaction;
	
	FillInParametersOfPriceTypeConnectionAndPriceIncludesVATAttribute();
	
	FillInFinancialAccountingGroup();
	
	ChangedBankingDetails = ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisObject, "Contract");
	
	If UseLinesOfBusiness Then
		LinesOfBusinessServer.FillInDefaultDirection(Object.LineOfBusiness, Object.Terms, Object.Contract);
	EndIf;
	LinesOfBusinessServer.WhenChangingDirectionOfActivity(ThisObject);
	
	If ForeignCurrencyTransaction <> Object.ForeignCurrencyTransaction Then
		Object.BankAccount = Catalogs.CompaniesBankAccounts.EmptyRef();
	EndIf;
	
	SalesServer.FillInBankAccountsUnderAgreement(Object.Contract, Object.BankAccount, Object.CounterpartyBankAccount);
	Object.BankAccount = GetOrganizationSDefaultBankAccountServer();
	
	FillInSalesVATTaxation();
	VATTaxationOnChangeServer(Undefined);
	
	ResponsiblePersonsServer.FillInManagerSelectionList_(Items.Manager, Object);
	ResponsiblePersonsServer.InstallManager(Object, Object.DocumentBasis);
	
	FillInSubordinatePropertiesForStatistics("Contract");
	
	WhenChangingKeyDetailsStatusOfEDO();
	ProvisionInDocumentsServer.WhenChangingDocumentDetails(ThisObject);
	
	PrepareAndSetVisibilityForAssemblyAndDelivery();
	
	SetVisibilityOfCommandToFillInContractPriceView();
	FillInParametersOfPriceTypeConnectionAndPriceIncludesVATAttribute();
	
	
EndProcedure



&AtClient
Procedure PartnerOnChange(Item)

	If Not ValueIsFilled (Object.Partner) Then
		GoodsDeliveryClientServer.ClearDeliveryDetails(Items,Object);
		SetVisibilityOfShipmentBanToPartner();
		
		If Object.DeliveryIsRequired Then
			
			UpdateDeliveryPlanningView();
			
		EndIf;
		
		Return;
	EndIf;

	PartnerOnChangeServer();
	
	
	DiscountsMarkupsFillingClient.ResetDiscountsCalculatedFlag(ThisForm);
	
	If ToUseTermsOfSales And ValueIsFilled(Object.Terms) Then
		SalesClient.NotifyEndOfFillingInDefaultSalesConditions();
	EndIf;
	
	
	
EndProcedure

&AtClient
Procedure ContactPersonOnChange(Item)
	
	If Object.ContactPerson.IsEmpty() Then
		Return;
	ElsIf Not Object.Partner.IsEmpty() Then
		Return;
	EndIf;
	
	PartnerChanged_ = False;
	ContactPersonOnChangeServer(PartnerChanged_);
	
	If Not PartnerChanged_ Then
		Return;
	EndIf;
	
	If Not ValueIsFilled (Object.Partner) Then
		
		GoodsDeliveryClientServer.ClearDeliveryDetails(Items,Object);
		
	Else
		
		DiscountsMarkupsFillingClient.ResetDiscountsCalculatedFlag(ThisForm);
		
		If ToUseTermsOfSales And ValueIsFilled(Object.Terms) Then
			SalesClient.NotifyEndOfFillingInDefaultSalesConditions();
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure CounterpartyOnChange(Item)
	
	CounterpartyOnChangeServer();
	
	
	
	
EndProcedure

&AtClient
Procedure TermsOnChange(Item)

	If Not ValueIsFilled (Object.Terms) Then
		TermsClearingServer();
		Return;
	EndIf;
	
	DiscountsMarkupsFillingClient.ResetDiscountsCalculatedFlag(ThisForm);
	
	If SalesServerCall.ThisIsAgreementOnNewCommission(Object.Terms) Then
		ContractBeforeModifications = Object.Contract;
		TermsOnChangeServer(False);
		SalesClient.NotifyEndOfFillingInTermsOfSale();
		If Not ContractBeforeModifications = Object.Contract And ValueIsFilled(Object.Contract) And ConsignmentSales25
			And ValueIsFilled(AccountingTypeOfContractPrice(Object.Contract).PriceKind) Then
			Notification = New CallbackDescription("ContractOnChangeCompletion", ThisObject);
			EnterprisePricesFillingClient.AskQuestionAboutRecalculatingPriceWhenChangingAgreement(Object, Notification);
		EndIf;
	Else
		
		PricesCalculated = TermsOnChangeServer(True);
		SalesClient.NotifyEndOfFillingInTermsOfSale();
		SalesClient.NotifyAboutEndOfFillingInPricesUnderAgreement(PricesCalculated);

		
	EndIf;
	
EndProcedure

&AtClient
Procedure StatusOnChange(Item)

	If Object.Approved
		And Object.Status = PredefinedValue("Enum.SalesOrderStatuses.NotApproved") Then
		
		Object.Approved = False;
		
	EndIf;

	StatusOnChangeServer();

EndProcedure

&AtClient
Procedure VATTaxationOnChange(Item)
	
	ClearMessages();
	
	VATTaxationOnChangeServer(CachedValues);
	DiscountsMarkupsFillingClient.ResetDiscountsCalculatedFlag(ThisForm);
	
EndProcedure

&AtClient
Procedure VATTaxationStartChoice(Item, ChoiceData, ChoiceByAdding, StandardProcessing)
		
	If UpdateTaxList Then 
		FillInSalesVATTaxSelectionList(); 
		UpdateTaxList = False;
	EndIf;
	
EndProcedure

&AtClient
Procedure PriceIncludesVATOnChange(Item)
	
	PriceIncludesVATOnChangeServer(CachedValues);
	DiscountsMarkupsFillingClient.ResetDiscountsCalculatedFlag(ThisForm);
	
EndProcedure

&AtClient
Procedure CurrencyOnChange(Item)
	
	If ValueIsFilled(Object.Currency) Then
		
		CurrencyOnChangeServer(
			Object.Currency,
			PriceManagementSystemClient.CurrencyConversionRequired(Object,DocumentCurrency));
		PriceManagementSystemClient.NotifyAboutEndOfConversionOfAmountsIntoCurrency(DocumentCurrency, Object.Currency);
		
	EndIf;
	
	DiscountsMarkupsFillingClient.ResetDiscountsCalculatedFlag(ThisForm);
	
	DocumentCurrency = Object.Currency;
	
EndProcedure

&AtClient
Procedure DateOnChange(Item)
	
	DiscountsMarkupsFillingClient.ResetDiscountsCalculatedFlag(ThisForm);
	FillInVATTaxationATServer();
	
	Notification = New CallbackDescription("DateOnChangeCompletion", ThisObject);
	EnterprisePricesFillingClient.AskQuestionAboutRecalculatingPriceWhenDateChanges(Object, Notification);
	
EndProcedure

&AtClient
Procedure DateOnChangeCompletion(QuestionResult, AdditionalParameters) Export 
	
	If Not QuestionResult = DialogReturnCode.Cancel And QuestionResult Then
	
		RecalculatePrices_2 = True;
		PricesCalculated = DateOnChangeServer(RecalculatePrices_2);
	
		If RecalculatePrices_2 Then
			SalesClient.NotifyAboutEndOfFillingInPricesUnderAgreement(PricesCalculated);
		EndIf;
		
	Else
		
		DateOnChangeServer(False);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure OrganizationOnChange(Item)
	
	ClearMessages();
	
	ContractBeforeModifications = Object.Contract;
	OrganizationOnChangeServer();
	
	DocumentCurrency = Object.Currency;
	
	If Not ContractBeforeModifications  = Object.Contract
		And ValueIsFilled(Object.Contract) And NewCommissionAgreement
		And ValueIsFilled(AccountingTypeOfContractPrice(Object.Contract).PriceKind) Then
		Notification = New CallbackDescription("ContractOnChangeCompletion", ThisObject);
		EnterprisePricesFillingClient.AskQuestionAboutRecalculatingPriceWhenChangingAgreement(Object, Notification);
	EndIf;
	
	DiscountsMarkupsFillingClient.ResetDiscountsCalculatedFlag(ThisForm);
	
	
	
EndProcedure

&AtClient
Procedure WarehouseOnChange(Item)
	
	ClearMessages();
	
	DiscountsMarkupsFillingClient.ResetDiscountsCalculatedFlag(ThisForm);
	WarehouseOnChangeServer();
	
EndProcedure

&AtClient
Procedure BusinessOperationOnChange(Item)
	
	ClearMessages();
	
	ContractBeforeModifications = Object.Contract;
	BusinessOperationOnChangeServer();
	
	If Not ContractBeforeModifications = Object.Contract
		And ValueIsFilled(Object.Contract) And NewCommissionAgreement
		And ValueIsFilled(AccountingTypeOfContractPrice(Object.Contract).PriceKind) Then
		Notification = New CallbackDescription("ContractOnChangeCompletion", ThisObject);
		EnterprisePricesFillingClient.AskQuestionAboutRecalculatingPriceWhenChangingAgreement(Object, Notification);
	EndIf;

EndProcedure

&AtClient
Procedure ManagerOnChange(Item)
	
	FillInSubordinatePropertiesForStatistics("Manager");
	
	DiscountsMarkupsFillingClient.ResetDiscountsCalculatedFlag(ThisForm);
	
EndProcedure

&AtClient
Procedure LoyaltyCardStartChoice(Item, ChoiceData, StandardProcessing)
	
	AdditionalParameters = Undefined;
	
	LoyaltyCardsClient.StartSelectingLoyaltyCard(Item, StandardProcessing, Object.Partner, Object.Date,, AdditionalParameters);
	
EndProcedure

&AtClient
Procedure LoyaltyCardChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	StandardProcessing = False;
	LoyaltyCardIsRead(Undefined, ValueSelected);
	
EndProcedure

&AtClient
Procedure LoyaltyCardClearing(Item, StandardProcessing)
	LoyaltyCardIsRead(Undefined, Undefined);
EndProcedure

&AtClient
Procedure DateOfShipmentOnChange(Item)
	
	DateOfShipmentOnChangeServer();
	UpdateTaxList = True;
	
EndProcedure

&AtClient
Procedure ApprovalDateOnChange(Item)
	ApprovalDateForChangesOnServer();
EndProcedure

&AtClient
Procedure NotShipInInstallmentsOnChange(Item)
	
	NotShipInInstallmentsOnChangeServer();
	UpdateTaxList = True;
	
EndProcedure

&AtClient
Procedure TextAllowedCreditBalanceClick(Item, StandardProcessing)
	
	ARAPAccountingClient.DebtLimitsClick(ThisForm, Item, StandardProcessing);
	
EndProcedure

&AtClient
Procedure DecorationSparkriskieIndexesURLProcessing(Item, FormattedStringURL, StandardProcessing)


EndProcedure


&AtClient
Procedure ToReturnReusablePackageOnChange(Item)
	
	ToReturnReusablePackageOnChangeServer();
	DiscountsMarkupsFillingClient.ResetDiscountsCalculatedFlag(ThisForm);
	
EndProcedure

&AtClient
Procedure TextShippingToAPartnerIsProhibitedClick(Item)
	OpenForm("Catalog.Partners.Form.FormOfSegmentsOfShipmentProhibition", New Structure("Partner", Object.Partner));
EndProcedure

&AtClient
Procedure PackageDepositIsRequiredOnChange(Item)
	
	CalculateOrderTotals(ThisForm);
	
EndProcedure

&AtClient
Procedure StateClick(Item, StandardProcessing)
	
	SalesClient.StatusInFormOfDocumentClick(StandardProcessing, ThisObject);
	
EndProcedure

&AtClient
Procedure Decorationedonage(Item, StandardProcessing)
	
	
EndProcedure

&AtClient
Procedure DepartmentOnChange(Item)
	
	FillInVATTaxationATServer();
EndProcedure

&AtClient
Procedure TextDocumentsBasedOnURLProcessing(Item, FormattedStringURL, StandardProcessing)
	
	ClearMessages();
	
	SalesClient.HandlingNavigationLinkOfSubordinateDocuments(ThisObject, 
		FormattedStringURL,
		StandardProcessing);
	
	InitiateReceiptOfDocumentsBasedOn();
	EnableWaitingHandlerForDocumentDataBasedOn();
	
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

#Region Delivery

&AtClient
Procedure DeliveryIsRequiredOnChange(Item)
	
	If Object.DeliveryIsRequired Then
		
		DeliverySettings = GoodsDeliveryClientServer.DefaultDeliverySettings();
		Object.DeliverySpecificationMethod = DeliverySettings.DeliverySpecificationMethod;
		Object.DeliveryMethod25 = DeliverySettings.DeliveryMethod;
		UpdateDeliveryPlanningView();
		
	Else
		
		Object.DeliveryToCarrier = False;
		Object.DeliveryPlanning = PredefinedValue("Enum.DeliveryPlanningKinds.EmptyRef");
		
	EndIf;
	
	SetAvailabilityVisibilityOfDeliveryItems(ThisObject);
	
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	
EndProcedure

#EndRegion

#EndRegion

#Region EventHandlers

&AtClient
Procedure DecorationDeliveryServiceCreateClick(Item)
	
	
EndProcedure

&AtClient
Procedure DecorationDeliveryServiceOrderListClick(Item)
	
	
EndProcedure

&AtClient
Procedure DecorationDeliveryServiceAddToDeliveryOrderClick(Item)
	
	
EndProcedure


&AtClient
Procedure MethodPlaceOfDeliveryCarrierIfChanged(Item)
	
	FillInAndSetDeliveryAttributesServer(Item.Name);
	DiscountsMarkupsFillingClient.ResetDiscountsCalculatedFlag(ThisForm);
	
EndProcedure

&AtClient
Procedure CourierStartChoice(Item, ChoiceData, StandardProcessing)
	
	WarehousesClient.OpenStoreEmployeeSelectionForm(ThisForm, Item.Name, StandardProcessing);
	
EndProcedure

&AtClient
Procedure PickerStartChoice(Item, ChoiceData, StandardProcessing)
	
	WarehousesClient.OpenStoreEmployeeSelectionForm(ThisForm, Item.Name, StandardProcessing);
	
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

&AtClient
Procedure LineOfBusinessOnChange(Item)
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.StartTimeMeasurement(
		True, "Document.SalesOrder.Form.DocumentForm.Item.LineOfBusiness.OnChange");
	
	LineOfBusinessOnChangeServer();
	
EndProcedure
 
&AtClient
Procedure UISStateContractStepStartChoice(Item, ChoiceData, StandardProcessing)
	
	
	Return;
	
EndProcedure

&AtClient
Procedure UISStateContractStepClearing(Item, StandardProcessing)

	Object.UISStateContractStep = "";

EndProcedure


&AtClient
Procedure DecorationEISFilesClick(Item, StandardProcessing)
	
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersGoods

&AtClient
Procedure GoodsSelection(Item, RowSelected, Field, StandardProcessing)
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.StartTimeMeasurement(
		True, "Document.SalesOrder.Form.DocumentForm.Items.Goods.Selection");
	
	If Item.CurrentItem = Items.GoodsAvailable And Not ReadOnly Then
		
		StandardProcessing = False;
		
		FormParameters = ParametersOfQuantityAndSeriesRequestForm(Undefined);
		
		If FormParameters <> Undefined Then
			OpenForm("DataProcessor.QuantityAndBatchRequest.Form", FormParameters, ThisObject);
		EndIf;
		
	ElsIf Item.CurrentItem = Items.GoodsPercentRateOfAutomaticDiscountMarkup
		Or Item.CurrentItem = Items.GoodsDiscountMarkupAmount
		Then
		
		StandardProcessing = False;
		
		If Not Object.DiscountsAreCalculated Then
			ParametersStructure1 = New Structure;
			ParametersStructure1.Insert("ApplyToObject",                True);
			ParametersStructure1.Insert("OnlyPreliminaryCalculation",      False);
			ParametersStructure1.Insert("RestoreManagedDiscounts", True);
			ParametersStructure1.Insert("ManagedDiscounts", ManagedDiscounts);
			
			TheStructureOfTheMessages = CalculateDiscountsMarginsOnServer(ParametersStructure1);
			If TheStructureOfTheMessages.Messages.Count() > 0 And TheStructureOfTheMessages.AutomaticallyOpen Then
				OpenForm("CommonForm.MessagesOfDiscountsMarkups", TheStructureOfTheMessages, ThisForm, UUID);
			EndIf;
		EndIf;
		
		If Not ValueIsFilled(AddressOfAppliedDiscountsInTheTemporaryStorage) Then
			CalculateDiscountsWithoutApplyingToObject();
		EndIf;
		
		CurrentData = Items.Goods.CurrentData;
		DiscountsMarkupsFillingClient.OpenAppliedDiscountsForm(CurrentData, Object, ThisForm);
	
	ElsIf Field = Items.GoodsPrice Then
		
		CurrentData = Items.Goods.CurrentData;
		If ReadPriceTypeRight Then
			If ValueIsFilled(CurrentData.PriceKind) 
				And Not Object.Approved
				Then
				ClearMessages();
				CommonClient.MessageToUser(
					NStr("vi = 'Để soạn đơn giá, hãy xóa dạng giá';
						|ru = 'Для редактирования цены очистите вид цены';
						|en = 'To edit the price, clear the price type'; fa = 'To edit the price, clear the price type';
						|it = 'Для редактирования цены очистите вид цены';
						|pl = 'To edit the price, clear the price type';
						|tr = 'Fiyatı düzenlemek için fiyat türünü temizleyin'"),
					Object.Ref,
					CommonClientServer.PathToTabularSection("Object.Goods", CurrentData.LineNumber, "PriceKind"),);
			EndIf;
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
		
	ElsIf Field = Items.GoodsPartnerProducts Then
		
		PartnersProductsClient.WhenSelectingPartnerProducts(Object, Field, "GoodsPartnerProducts", NStr("vi = 'Khách hàng';
																										|ru = 'Клиент';
																										|en = 'Customer'; fa = 'مشتری';
																										|it = 'Cliente';
																										|pl = 'Customer';
																										|tr = 'Müşteri'"));
		
	EndIf;
	
EndProcedure

&AtClient
Procedure GoodsOnStartEdit(Item, NewRow, Copy)
	
	ProcessingOfTabularFormsClient.CacheCurLine(Items.Goods, ThisObject);
	CurrentData = Items.Goods.CurrentData;
	
	SalesClient.ProductItemLineAtBeginningOfEditing(ThisForm, "Goods", CurrentData, NewRow, Copy);
	
	If NewRow And Not Copy
		And Object.BusinessOperation <> PredefinedValue("Enum.BusinessTransactions.DeliveryForPrincipal") Then
		CurrentData.Department = Object.Department;
	EndIf;
	
	If NewRow Then
		CurrentData.RowCode = 0;
		If Copy Then
			CurrentData.AmountOfBonusPointsToDeduction = 0;
			CurrentData.AmountOfBonusPointsToDeductionInCurrency = 0;
		EndIf;
		If Object.NotShipInInstallments Then
			CurrentData.DateOfShipment = Object.DateOfShipment;
		EndIf;
	EndIf;
	
	If Copy Then
		StructureOfActions = New Structure;
		AddCollateralActionsOnClient(StructureOfActions,
			"SupplyOption,Available,WarehouseIsRequired,DateOfShipmentRequired_");
		StructureOfActions.Insert("CheckSeriesCalculateStatus",
			New Structure("Warehouse, SeriesSpecificationParameters", CurrentData.Warehouse, SeriesSpecificationParameters));
		BatchProcessingOfTablePartClient.ProcessTSString(CurrentData, StructureOfActions, CachedValues);
		ProvisionInDocumentsClientServer.FillInServiceDetails(Object.Goods, DateOfShipmentRequired_, WarehouseIsRequired);
	EndIf;
	
	ARAPAccountingClient.SaveShipmentDatesInParameters(ThisObject);
	
EndProcedure

&AtClient
Procedure GoodsOnEditEnd(Item, NewRow, CancelEdit)
	
	CurrentData = Items.Goods.CurrentData;
	
	If Not CancelEdit Then
		LineCache = ?(NewRow, Undefined, ProcessingOfTabularFormsClientServer.LineCache(Items.Goods, ThisObject));
		WarehousesClient.UpdateWarehouseTable(WarehouseTable, CurrentData, LineCache, WarehouseGroup_);
		TotalWarehouses_ = WarehouseTable.Count();
		WarehousesClientServer.UpdateWarehouseGroupImage(SeveralWarehousesText, Items.PictureMultipleWarehouses, TotalWarehouses_);
	EndIf;
	
	If CurrentData <> Undefined And Object.NotShipInInstallments Then
		CurrentData.DateOfShipment = Object.DateOfShipment;
	EndIf;
	
	ReusablePackageClient.UpdateFillingStateOfMultiTurnContainer(Object.ReusablePackageFillingStatus);
	CalculateOrderTotals(ThisForm);
	
EndProcedure

&AtClient
Procedure GoodsBeforeRowChange(Item, Cancel)
	
	GoodsBeforeRowChangeLocalization(Item, Cancel);
	
EndProcedure

&AtClient
Procedure GoodsBeforeDeleteRow(Item, Cancel)
	
	ProcessingOfTabularFormsClient.CacheCurLine(Items.Goods, ThisObject);
	SetsClient.BeforeDeletingRowOfTablePart(ThisForm, "Goods", Cancel);
	ARAPAccountingClient.SaveShipmentDatesInParameters(ThisObject);
	
EndProcedure

&AtClient
Procedure GoodsAfterDeleteRow(Item)
	
	ThereIsChangeInShippingDates = ARAPAccountingClient.ThereIsChangeInShippingDates(ThisObject);
	GoodsAfterDeleteRowServer(ThereIsChangeInShippingDates);
	
	CalculateOrderTotals(ThisForm);
	DiscountsMarkupsFillingClient.ResetDiscountsCalculatedFlag(ThisForm);
	ReusablePackageClient.UpdateFillingStateOfMultiTurnContainer(Object.ReusablePackageFillingStatus);
	ProvisionInDocumentsClientServer.FillInServiceDetails(Object.Goods, DateOfShipmentRequired_, WarehouseIsRequired);
	
EndProcedure

&AtClient
Procedure GoodsContentStartChoice(Item, ChoiceData, StandardProcessing)
	
	CommonClient.ShowCommentEditingForm(
		Item.EditText,
		ThisObject,
		"Items.Goods.CurrentData.Content",
		NStr("vi = 'Nội dung dịch vụ';
			|ru = 'Содержание услуги';
			|en = 'Service content'; fa = 'Service content';
			|it = 'Contenuto del servizio';
			|pl = 'Opis usługi';
			|tr = 'Hizmet içeriği'"));
	
EndProcedure

&AtClient
Procedure GoodsProductsOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	
	ClearMessages();
	ApplyPaymentWithBonusPointsClient(, True);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("CheckCharacteristicsByOwner", CurrentRow.Characteristic);
	StructureOfActions.Insert("CheckFillPackageByOwner", CurrentRow.Package);
	StructureOfActions.Insert("RecalculateNumberOfUnits");
	StructureOfActions.Insert("CheckFillWarehouse", BatchProcessingOfTablePartClientServer.GetWarehouseFillStructureInTSLine(Object, WarehouseGroup_));
	StructureOfActions.Insert("FillInVATRate", BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRate(Object, True));
	StructureOfActions.Insert("FillInVATRateByPriceType", BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRateByPriceType(Object, True));
	StructureOfActions.Insert("FillInVATRateForReturnableContainers", Object.ToReturnReusablePackage);
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmount");
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountManualDiscount", New Structure("Clear", True));
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountAutomaticDiscount", New Structure("Clear", True));
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountDiscountWithBonusPoints");
	StructureOfActions.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
	StructureOfActions.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));
	StructureOfActions.Insert("FillInSalesOptionAttribute", New Structure("Products", "SaleRegistrationOption"));
	StructureOfActions.Insert("FillInContent", BatchProcessingOfTablePartClientServer.GetStructureOfFillingInServiceContentInTSLine(Object, False));
	StructureOfActions.Insert("FillInDuplicateDependentDetails", DependentDetails());
	StructureOfActions.Insert("FillInNoReturnContainerAttribute", Object.ToReturnReusablePackage);
	StructureOfActions.Insert("FillInCanceledWithoutReturnableContainerAttribute", Object.ToReturnReusablePackage);
	StructureOfActions.Insert("CheckSeriesCalculateStatus", New Structure("Warehouse, SeriesSpecificationParameters", CurrentRow.Warehouse, SeriesSpecificationParameters));
	AddCollateralActionsOnClient(StructureOfActions,
		"SupplyOption,AvailableInOtherLines,WarehouseIsRequired,DateOfShipmentRequired_");
	AddPriceFillingAction(StructureOfActions);
	
	StructureOfActions.Insert("ProductsOnChangeOverridable", New Structure("FormName, TabularSectionName",
		ThisForm.FormName, "Goods"));
	If Object.BusinessOperation <> PredefinedValue("Enum.BusinessTransactions.DeliveryForPrincipal") Then
		StructureOfActions.Insert("FillInSubdivisionInTSLine", New Structure("Department", Object.Department));
	EndIf;
	
	BatchProcessingOfTablePartClientServerLocalization.CompleteActionStructureWhenChangingElement(ThisObject, "Products", StructureOfActions);
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
	If ProvisionInDocumentsClient.YouNeedToUpdateAvailableColumn(StructureOfActions) Then
		UpdateColumnAvailableServer();
	EndIf;
	
	ProvisionInDocumentsClientServer.FillInServiceDetails(Object.Goods, DateOfShipmentRequired_, WarehouseIsRequired);
	
	CalculateOrderTotals(ThisForm);
	
	DiscountsMarkupsFillingClient.ResetDiscountsCalculatedFlag(ThisForm);
	
EndProcedure

&AtClient
Procedure GoodsCharacteristicOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	
	ClearMessages();
	ApplyPaymentWithBonusPointsClient(, True);

	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInVATRateByPriceType", BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRateByPriceType(Object, True));
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmount");
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountManualDiscount", New Structure("Clear", True));
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountAutomaticDiscount", New Structure("Clear", True));
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountDiscountWithBonusPoints");
	StructureOfActions.Insert("FillInDuplicateDependentDetails", DependentDetails());
	StructureOfActions.Insert("FillInContent", BatchProcessingOfTablePartClientServer.GetStructureOfFillingInServiceContentInTSLine(Object, False));
	AddCollateralActionsOnClient(StructureOfActions,
		"SupplyOption,AvailableInOtherLines,WarehouseIsRequired,DateOfShipmentRequired_");
	AddPriceFillingAction(StructureOfActions);
	
	StructureOfActions.Insert("CharacteristicOnChangeOverridable", New Structure("FormName, TabularSectionName",
		ThisForm.FormName, "Goods"));

	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
	If ProvisionInDocumentsClient.YouNeedToUpdateAvailableColumn(StructureOfActions) Then
		UpdateColumnAvailableServer();
	EndIf;
	
	ProvisionInDocumentsClientServer.FillInServiceDetails(Object.Goods, DateOfShipmentRequired_, WarehouseIsRequired);
	
	CalculateOrderTotals(ThisForm);

	DiscountsMarkupsFillingClient.ResetDiscountsCalculatedFlag(ThisForm);

EndProcedure

&AtClient
Procedure GoodsPackageOnChange(Item)
	
	ClearMessages();
	
	CurrentRow = Items.Goods.CurrentData;
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	
	ClearMessages();
	ApplyPaymentWithBonusPointsClient(, True);

	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateNumberOfUnits");
	
	If CurrentRow.Count > 0 And Not ValueIsFilled(CurrentRow.PriceKind) Then
		StructureOfActions.Insert("RecalculatePricePerPackage", CurrentRow.Count);
	ElsIf CurrentRow.Count > 0 And ValueIsFilled(CurrentRow.PriceKind) Then
		StructureOfActions.Insert("FillInSalePrice", BatchProcessingOfTablePartClientServer.ParametersForFillingInPriceInTSLine(Object));
	ElsIf (ToUseTermsOfSales And ValueIsFilled(Object.Terms)) 
		Or (Not ToUseTermsOfSales And UsePriceManagementSystem25) Then
		StructureOfActions.Insert("FillIn_TermsOfSales", BatchProcessingOfTablePartClientServer.GetStructureForFillingInSalesConditionsInTSLine(Object));
	EndIf;
	
	StructureOfActions.Insert("FillInVATRateByPriceType", BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRateByPriceType(Object, True));
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmount");
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountManualDiscount", New Structure("Clear", False));
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountAutomaticDiscount", New Structure("Clear", True));
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountDiscountWithBonusPoints");
	StructureOfActions.Insert("FillInDuplicateDependentDetails", DependentDetails());
	AddCollateralActionsOnClient(StructureOfActions, "AvailableInOtherLines");
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	If ProvisionInDocumentsClient.YouNeedToUpdateAvailableColumn(StructureOfActions) Then
		UpdateColumnAvailableServer();
	EndIf;
	
	CalculateOrderTotals(ThisForm);
	
	DiscountsMarkupsFillingClient.ResetDiscountsCalculatedFlag(ThisForm);
	
EndProcedure

&AtClient
Procedure GoodsNumberOfPackagesOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;
	
	VerificationOfPaymentWithBonusPoints(CurrentRow);
	
	StructureOfActions = New Structure;
	AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions,Object);
	AddCollateralActionsOnClient(StructureOfActions, "AvailableInOtherLines");
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	If ProvisionInDocumentsClient.YouNeedToUpdateAvailableColumn(StructureOfActions) Then
		UpdateColumnAvailableServer();
	EndIf;
	
	CalculateOrderTotals(ThisForm);
	
	DiscountsMarkupsFillingClient.ResetDiscountsCalculatedFlag(ThisForm);
	
EndProcedure

&AtClient
Procedure GoodsPriceKindOnChange(Item)
	
	ClearMessages();
	
	CurrentRow = Items.Goods.CurrentData;
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	
	ClearMessages();
	ApplyPaymentWithBonusPointsClient(, True);

	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInVATRateByPriceType", BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRateByPriceType(Object, True));
	StructureOfActions.Insert("FillInSalePrice", BatchProcessingOfTablePartClientServer.ParametersForFillingInPriceInTSLine(Object));
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmount");
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountManualDiscount", New Structure("Clear", False));
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountAutomaticDiscount", New Structure("Clear", True));
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountDiscountWithBonusPoints");
	StructureOfActions.Insert("FillInDuplicateDependentDetails", DependentDetails());
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
	CalculateOrderTotals(ThisForm);
	
	DiscountsMarkupsFillingClient.ResetDiscountsCalculatedFlag(ThisForm);
	
EndProcedure

&AtClient
Procedure GoodsPriceOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	
	ClearMessages();
	ApplyPaymentWithBonusPointsClient(, True);

	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmount");
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountManualDiscount", New Structure("Clear", False));
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountAutomaticDiscount", New Structure("Clear", True));
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountDiscountWithBonusPoints");
	StructureOfActions.Insert("FillInDuplicateDependentDetails", DependentDetails());
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
	CalculateOrderTotals(ThisForm);
	
	DiscountsMarkupsFillingClient.ResetDiscountsCalculatedFlag(ThisForm);
	
EndProcedure

&AtClient
Procedure GoodsVATRateStartChoice(Item, ChoiceData, ChoiceByAdding, StandardProcessing)

	DateOfShipment = Object.Date;

	If Object.NotShipInInstallments Then
		If ValueIsFilled(Object.DateOfShipment) Then
			DateOfShipment = Object.DateOfShipment;
		EndIf;
	Else
		CurrentData = Items.Goods.CurrentData;
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
Procedure GoodsVATRateOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	
	ClearMessages();
	ApplyPaymentWithBonusPointsClient(, True);

	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmount");
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountManualDiscount", New Structure("Clear", False));
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountAutomaticDiscount", New Structure("Clear", True));
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountDiscountWithBonusPoints");
	StructureOfActions.Insert("FillInDuplicateDependentDetails", DependentDetails());
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
	CalculateOrderTotals(ThisForm);
	
	DiscountsMarkupsFillingClient.ResetDiscountsCalculatedFlag(ThisForm);
	
EndProcedure

&AtClient
Procedure GoodsCanceledOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;
	
	If Not CurrentRow.Canceled Then
		CurrentRow.CancellationReason = PredefinedValue("Catalog.ReasonsForSaleOrderCancellation.EmptyRef");
	EndIf;
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInCanceledWithoutReturnableContainerAttribute", Object.ToReturnReusablePackage);
	StructureOfActions.Insert("FillInDuplicateDependentDetails", DependentDetails());
	StructureOfActions.Insert("CheckSeriesCalculateStatus", New Structure("Warehouse, SeriesSpecificationParameters", CurrentRow.Warehouse, SeriesSpecificationParameters));
	AddCollateralActionsOnClient(StructureOfActions, "AvailableInOtherLines,WarehouseIsRequired,DateOfShipmentRequired_");

	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
	If ProvisionInDocumentsClient.YouNeedToUpdateAvailableColumn(StructureOfActions) Then
		UpdateColumnAvailableServer();
	EndIf;
	
	ProvisionInDocumentsClientServer.FillInServiceDetails(Object.Goods, DateOfShipmentRequired_, WarehouseIsRequired);
	
	CalculateOrderTotals(ThisForm);
	
	If ARAPAccountingClient.ThereIsChangeInShippingDates(ThisObject) Then
		GoodsCanceledOnChangeATServer();
	EndIf;
	
EndProcedure

&AtClient
Procedure GoodsPercentRateOfManualDiscountOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	
	ClearMessages();
	ApplyPaymentWithBonusPointsClient(, True);

	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateAmountOfManualDiscount");
	StructureOfActions.Insert("RecalculateAmount");
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountManualDiscount", New Structure("Clear", False));
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountAutomaticDiscount", New Structure("Clear", False));
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountDiscountWithBonusPoints");
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("FillInDuplicateDependentDetails", DependentDetails());
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
	CalculateOrderTotals(ThisObject);
	
EndProcedure

&AtClient
Procedure GoodsManualDiscountOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	
	ClearMessages();
	ApplyPaymentWithBonusPointsClient(, True);

	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculatePercentageOfManualDiscount");
	StructureOfActions.Insert("RecalculateAmount");
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountManualDiscount", New Structure("Clear, RecalculateAmountOfManualDiscount_", False, False));
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountAutomaticDiscount", New Structure("Clear", False));
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountDiscountWithBonusPoints");
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("FillInDuplicateDependentDetails", DependentDetails());
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
	CalculateOrderTotals(ThisForm);
	
EndProcedure

&AtClient
Procedure GoodsSumOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;
	
	TransferOperations_ = GoodsTransferOperations();
	DiscountsAreNotUsed = TransferOperations_.Find(Object.BusinessOperation) <> Undefined;
	
	StructureOfPriceConversion  = BatchProcessingOfTablePartClientServer.GetStructureForRecalculatingDiscountPriceInWHSales(Object,
		DiscountsAreNotUsed);
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculatePriceDiscountByAmountInSales", StructureOfPriceConversion);
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("FillInDuplicateDependentDetails", DependentDetails());
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
	CalculateOrderTotals(ThisForm);
	
	DiscountsMarkupsFillingClient.ResetDiscountsCalculatedFlag(ThisForm);
	
EndProcedure

&AtClient
Procedure GoodsVATAmountOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("FillInDuplicateDependentDetails", DependentDetails());
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
	CalculateOrderTotals(ThisForm);
	
EndProcedure

&AtClient
Procedure GoodsWarehouseOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentRow;
	GoodsWarehouseOnChangeServer(CurrentRow);
	
EndProcedure

&AtClient
Procedure GoodsDepartmentOnChange(Item)
	UpdateColumnAvailableServer();
EndProcedure

&AtClient
Procedure GoodsDateOfShipmentOnChange(Item)
	
	ClearMessages();
	
	CurrentRow = Items.Goods.CurrentData;
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInVATRate", BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRate(Object, True));
	StructureOfActions.Insert("FillInVATRateByPriceType", BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRateByPriceType(Object, True));
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("FillInDuplicateDependentDetails", DependentDetails());
	StructureOfActions.Insert("FillInVATRateForReturnableContainers", Object.ToReturnReusablePackage);
	StructureOfActions.Insert("FillInNoReturnContainerAttribute", Object.ToReturnReusablePackage);
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
	CalculateOrderTotals(ThisForm);
	
	UpdateTaxList = True;
	
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
Procedure GoodsSupplyOptionClearing(Item, StandardProcessing)
	
	StandardProcessing = False;
	
EndProcedure

&AtClient
Procedure GoodsWarehouseStartChoice(Item, ChoiceData, StandardProcessing)
	
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
Procedure CourierOnChange(Item)
	
	CourierForChangesOnServer();
	
EndProcedure

&AtClient
Procedure GoodsPartnerProductsOnChange(Item)

	CurrentRow = Items.Goods.CurrentData;
	
	PartnersProductsClient.SetPackageSelectionParameters(Item.ChoiceParameters, CurrentRow);
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	
	ClearMessages();
	ApplyPaymentWithBonusPointsClient(, True);

	StructureOfActions = New Structure;
	StructureOfActions.Insert("CheckCharacteristicsByOwner", CurrentRow.Characteristic);
	StructureOfActions.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));
	StructureOfActions.Insert("CheckFillPackageByOwner", CurrentRow.Package);
	StructureOfActions.Insert("FillInTheItemByThePartnerSItem");
	StructureOfActions.Insert("CheckFillWarehouse", BatchProcessingOfTablePartClientServer.GetWarehouseFillStructureInTSLine(Object, WarehouseGroup_));
	StructureOfActions.Insert("RecalculateNumberOfUnits");
	
	If ToUseTermsOfSales And ValueIsFilled(Object.Terms) Then
		StructureOfActions.Insert("FillIn_TermsOfSales", BatchProcessingOfTablePartClientServer.GetStructureForFillingInSalesConditionsInTSLine(Object));
	Else
		StructureOfActions.Insert("FillInSalePrice", BatchProcessingOfTablePartClientServer.ParametersForFillingInPriceInTSLine(Object));
	EndIf;
	
	StructureOfActions.Insert("FillInVATRate", BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRate(Object, True));
	StructureOfActions.Insert("FillInVATRateByPriceType", BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRateByPriceType(Object, True));
	StructureOfActions.Insert("FillInVATRateForReturnableContainers", Object.ToReturnReusablePackage);
	StructureOfActions.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
	StructureOfActions.Insert("FillInNoReturnContainerAttribute", Object.ToReturnReusablePackage);
	StructureOfActions.Insert("FillInCanceledWithoutReturnableContainerAttribute", Object.ToReturnReusablePackage);
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmount");
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountManualDiscount", New Structure("Clear", True));
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountAutomaticDiscount", New Structure("Clear", True));
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountDiscountWithBonusPoints");
	StructureOfActions.Insert("FillInDuplicateDependentDetails", DependentDetails());
	StructureOfActions.Insert("FillInSalesOptionAttribute", New Structure("Products", "SaleRegistrationOption"));
	StructureOfActions.Insert("FillInContent", BatchProcessingOfTablePartClientServer.GetStructureOfFillingInServiceContentInTSLine(Object, False));
	StructureOfActions.Insert("CheckSeriesCalculateStatus", New Structure("Warehouse, SeriesSpecificationParameters", CurrentRow.Warehouse, SeriesSpecificationParameters));
	
	AddCollateralActionsOnClient(StructureOfActions,
		"SupplyOption,AvailableInOtherLines,WarehouseIsRequired,DateOfShipmentRequired_");
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
	CalculateOrderTotals(ThisForm);
	DiscountsMarkupsFillingClient.ResetDiscountsCalculatedFlag(ThisForm);
	
EndProcedure

&AtClient
Procedure GoodsOnActivateCell(Item)
	
	If Item.CurrentItem = Undefined Then
		Return
	ElsIf Item.CurrentItem.Name = "GoodsPartnerProducts" Then
		
		CurrentData = Items.Goods.CurrentData;
		
		PartnersProductsClient.FillInPartnerProductSelectionList(
			Object.Partner, CurrentData, Items.GoodsPartnerProducts.ChoiceList);
			
		PartnersProductsClient.SetPackageSelectionParameters(
			Items.GoodsPartnerProducts.ChoiceParameters, CurrentData);
		
	EndIf;

EndProcedure

&AtClient
Procedure GoodsPartnerProductsStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	
	CurrentRow = Items.Goods.CurrentData;
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("FormItem" , Item);
	AdditionalParameters.Insert("CurrentRow", CurrentRow);
	
	ClosingNotification = New CallbackDescription("ProcessResultOfSelectingPartnerProductName", ThisObject, AdditionalParameters);

	PartnersProductsClient.OpenPartnerProductSelectionForm(ThisObject, Object.Partner, CurrentRow, Item.Title, ClosingNotification);

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
Procedure ReserveAsReceived(Command)
	
	ProvidingSetAction("ACTION_RESERVATION_REFERENCES");
	
EndProcedure

&AtClient
Procedure ToSupply(Command)
	
	ProvidingSetActionWithQuestion("ACTION_COOPERATION");
	
EndProcedure

&AtClient
Procedure NotProvide(Command)
	
	ProvidingSetActionWithQuestion("ACTION_NOTABLE");
	
EndProcedure

&AtClient
Procedure ToReserve_(Command)
	
	ProvidingSetActionWithQuestion("ACTION_RESERVE");
	
EndProcedure

&AtClient
Procedure Ship(Command)
	
	ProvidingSetActionWithQuestion("ACTION_LOAD");
	
EndProcedure

&AtClient
Procedure FillInShipmentDate(Command)

	ArrayOfSelectedRows = Items.Goods.SelectedRows;
	If ArrayOfSelectedRows.Count() > 0 Then
		DateOfShipment = Object.DateOfShipment;
		
		Notification = New CallbackDescription("FillInShipmentDateCompletion", ThisObject, New Structure("ArrayOfSelectedRows", ArrayOfSelectedRows));
		
		TMCommonUseClient.EnterDateWithControlOfEmptyValue(DateOfShipment, NStr("vi = 'Nhập ngày giao hàng';
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
Procedure FillInTheDepartment(Command)
	
	WarehousesClient.FillInDivisionInTablePart(Object, ThisForm, Object.Goods, "Goods", 
			Items.Goods.SelectedRows);
	
EndProcedure

&AtClient
Procedure FillInVATRate(Command)

	If Object.Goods.Count() = 0 Then
		WarningText = NStr("vi = 'Trong danh sách ""Hàng hóa"" chưa điền dòng nào.';
							|ru = 'В список ""Товары"" не введено ни одной строки.';
							|en = 'No lines entered in the Item list.'; fa = 'No lines entered in the Item list.';
							|it = 'В список ""Товары"" не введено ни одной строки.';
							|pl = 'Do listy ""Wiersze pozycji"" nie wprowadzono żadnego wiersza.';
							|tr = '""Ürünler"" listesine hiçbir satır girilmemiştir.'");
		ShowMessageBox(, WarningText);
		Return;
	EndIf;

	ClosingNotification1 = New CallbackDescription("FillInVATRateCompletion", ThisObject);
	FormParameters = New Structure();
	FormParameters.Insert("VATTaxationType", Object.VATTaxation);
	OpenForm("Catalog.VATRates.ChoiceForm", FormParameters,,,,, ClosingNotification1);

EndProcedure

&AtClient
Procedure CreateAnAssignmentAdjustmentReservation(Command)
	
	ObjectsOfBases = New Array();
	ObjectsOfBases.Add(Object.Ref);
	
	CommandDetails = New Structure();
	CommandDetails.Insert("ObjectsOfBases", ObjectsOfBases);
	
	If Object.Status = PredefinedValue("Enum.SalesOrderStatuses.NotApproved") Then
		MinimumStatus = NStr("vi = 'Cần thực hiện';
							|ru = 'К выполнению';
							|en = 'Ready for fulfillment'; fa = 'آماده اجرا';
							|it = 'Da eseguire';
							|pl = 'Do wykonania';
							|tr = 'Karşılanmaya hazır'");
		SupplyClient.ReportRequiredMinimumDocumentStatus(True, MinimumStatus);
	ElsIf Not Object.Posted Or Modified Then
		AdditionalParameters = New Structure();
		AdditionalParameters.Insert("Reservation", True);
		AdditionalParameters.Insert("CommandDetails", CommandDetails);
		
		QueryText = NStr("vi = 'Để lập dự phòng theo chỉ định trước tiên cần kết chuyển chứng từ. Kết chuyển và tiếp tục?';
						|ru = 'Для резервирования под назначение необходимо предварительно провести документ. Выполнить проведение документа и продолжить?';
						|en = 'To reserve for assignment, it is required to post the document first. Post the document and continue?'; fa = 'To reserve for assignment, it is required to post the document first. Post the document and continue?';
						|it = 'Per prenotare per assegnazione, è necessario innanzitutto pubblicare il documento. Eseguire la registrazione del documento e continuare?';
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
	
	If Object.Status = PredefinedValue("Enum.SalesOrderStatuses.NotApproved") Then
		MinimumStatus = NStr("vi = 'Cần thực hiện';
							|ru = 'К выполнению';
							|en = 'Ready for fulfillment'; fa = 'آماده اجرا';
							|it = 'Da eseguire';
							|pl = 'Do wykonania';
							|tr = 'Karşılanmaya hazır'");
		SupplyClient.ReportRequiredMinimumDocumentStatus(False, MinimumStatus);
	ElsIf Not Object.Posted Or Modified Then
		AdditionalParameters = New Structure();
		AdditionalParameters.Insert("Reservation", False);
		AdditionalParameters.Insert("CommandDetails", CommandDetails);
		
		QueryText = NStr("vi = 'Để loại bỏ dự phòng cho Chỉ định, trước tiên bạn phải giữ một chứng từ. Hoàn thành chứng từ và tiếp tục?';
						|ru = 'Для снятия резерва под назначение необходимо предварительно провести документ. Выполнить проведение документа и продолжить?';
						|en = 'To remove the reserve for assignment, post the document first. Post the document and continue?'; fa = 'To remove the reserve for assignment, post the document first. Post the document and continue?';
						|it = 'Per rimuove la prenotazione per assegnazione, è necessario innanzitutto pubblicare il documento. Eseguire la registrazione del documento e continuare?';
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

#EndRegion

#Region Delivery

&AtClient
Procedure EditDeliveryParameters(Command)
	
	If Object.Partner.IsEmpty() Then
		
		ErrorText = CommonClientServer.FillingErrorText(
			"Field",
			"FillType",
			"Partner");
		
		CommonClient.MessageToUser(
			ErrorText,
			,
			"Object.Partner");
		
		Return;
		
	EndIf;
	
	OpenDeliverySettings();
	
EndProcedure

#EndRegion

#Region Delivery20

&AtClient
Procedure SupplementDeliveryInformationWithContacts(Command)
	SupplementDeliveryInformationWithContactsServer();
EndProcedure

#EndRegion

&AtClient
Procedure AutoTestFillInPricesByAgreement(Command) Export
	
	If EnterprisePricesFillingClient.ItIsNecessaryToFillInPricesByAgreement(Object, "Goods", NStr("vi = 'Hàng hóa';
																									|ru = 'Товары';
																									|en = 'Goods'; fa = 'کالاها';
																									|it = 'Merci';
																									|pl = 'Wiersze pozycji';
																									|tr = 'Ürünler'")) Then
		
		ErrorText = "";
		PricesCalculated = FillThePricesByTermsOfSalesServer(,ErrorText);
		DiscountsMarkupsFillingClient.ResetDiscountsCalculatedFlag(ThisForm);
		SalesClient.NotifyAboutEndOfFillingInPricesUnderAgreement(PricesCalculated, ErrorText);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure FillInPricesOfSelectedRowsByPriceType(Command)

	If EnterprisePricesFillingClient.ItIsNecessaryToFillInPricesByTypeOfPrices(Object, "Goods", NStr("vi = 'Hàng hóa';
																									|ru = 'Товары';
																									|en = 'Goods'; fa = 'کالاها';
																									|it = 'Merci';
																									|pl = 'Wiersze pozycji';
																									|tr = 'Ürünler'")) Then
		
		PriceSelectionOptions = EnterprisePricesFillingClient.NewFillOptionsSelectPriceType();
		PriceSelectionOptions.CallbackDescription = 
			New CallbackDescription("FillInPricesOfSelectedRowsByPriceTypeCompletion", ThisObject);
		PriceSelectionOptions.PriceIncludesVAT = Object.PriceIncludesVAT;
		PriceSelectionOptions.UseWhileSellingToCustomers = True;
		PriceSelectionOptions.OwnerOfAnIndividualPriceType = ?(ToUseTermsOfSales,Object.Terms,Object.Partner);
		
		EnterprisePricesFillingClient.ChooseTypeOfPrices(PriceSelectionOptions);
		
	EndIf;

EndProcedure

&AtClient
Procedure FillInPricesUnderAgreement(Command)
	
	TypeOfContractPrice = AccountingTypeOfContractPrice(Object.Contract);
	
	If EnterprisePricesFillingClient.YouNeedToFillInPricesByType(Object, TypeOfContractPrice) Then
		
		ErrorText = "";
		PricesCalculated = FillThePricesByTermsOfSalesServer(,ErrorText);
		DiscountsMarkupsFillingClient.ResetDiscountsCalculatedFlag(ThisForm);
		SalesClient.NotifyAboutEndOfFillingInPricesUnderAgreement(PricesCalculated,ErrorText);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure FillInPricesOfSelectedRowsByPriceTypeCompletion(PricesKind, AdditionalParameters) Export
	
	If ValueIsFilled(PricesKind) Then
		
		PricesCalculated = FillInPricesOfSelectedRowsByPriceTypeServer(PricesKind);
		DiscountsMarkupsFillingClient.ResetDiscountsCalculatedFlag(ThisForm);
		SalesClient.NotifyAboutEndOfFillingInPricesByTypeOfPrices(PricesCalculated, PricesKind);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure CancelSelectedLines(Command)
	
	If Not SalesClient.YouMustFillInReasonsForCancelingSelectedLines(Object.Goods, NStr("vi = 'Hàng hóa';
																						|ru = 'Товары';
																						|en = 'Goods'; fa = 'کالاها';
																						|it = 'Merci';
																						|pl = 'Wiersze pozycji';
																						|tr = 'Ürünler'"), Items.Goods.SelectedRows) Then
		Return;
	EndIf;

	CancellationReason = PredefinedValue("Catalog.ReasonsForSaleOrderCancellation.EmptyRef");
	If UseReasonsForSalesOrderCancellations Then
		OpenForm("Catalog.ReasonsForSaleOrderCancellation.ChoiceForm",,,,,, New CallbackDescription("CancelSelectedLinesCompletion", ThisObject), FormWindowOpeningMode.LockOwnerWindow);
        Return;
	EndIf;
	
	UndoSelectedLineSnippet(CancellationReason);
EndProcedure

&AtClient
Procedure CancelSelectedLinesCompletion(Result, AdditionalParameters) Export
    
    CancellationReason = Result;
    If Not ValueIsFilled(CancellationReason) Then
        Return;
    EndIf;
    
    UndoSelectedLineSnippet(CancellationReason);

EndProcedure

&AtClient
Procedure UndoSelectedLineSnippet(Val CancellationReason)
    
    Var SelectedRows, StructureOfActions;
    
    StructureOfActions = New Structure();
    StructureOfActions.Insert("FillInDuplicateDependentDetails", DependentDetails());
    StructureOfActions.Insert("FillInCanceledWithoutReturnableContainerAttribute", Object.ToReturnReusablePackage);
    
    SelectedRows = AddToFullSet();
    
    SalesClient.CancelSelectedLines(
    Object.Goods,
    SelectedRows,
    CancellationReason,
    StructureOfActions);
	
	CancelSelectedLinesOfActionOfProvidingServer(SelectedRows);
	
	SalesClient.NotifyAboutCancellationOfSelectedLines(CancellationReason);
	
EndProcedure

&AtServer
Procedure CancelSelectedLinesOfActionOfProvidingServer(Val SelectedRows)
	
	RowsToProcess = New Array;
	StructureOfActions = New Structure();
	AddCollateralActionsOnServer(StructureOfActions, "WarehouseIsRequired,DateOfShipmentRequired_");
	
	For Each CurRow In SelectedRows Do
		TableRow = Object.Goods.FindByID(CurRow);
		RowsToProcess.Add(TableRow);
	EndDo;
	
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		RowsToProcess,
		StructureOfActions,
		Object.Goods,
		Undefined);
	
	ProvisionInDocumentsClientServer.FillInServiceDetails(Object.Goods, DateOfShipmentRequired_, WarehouseIsRequired);
	CalculateOrderTotals(ThisObject);
	UndoSelectedRowsOnServer();
	WhenChangingWarehouseInTablePartServer();
	
EndProcedure

&AtClient
Procedure CancelUndeliveredLines(Command)

	If Not SalesClient.YouMustFillInReasonsForCancelingSelectedLines(Object.Goods, NStr("vi = 'Hàng hóa';
																						|ru = 'Товары';
																						|en = 'Goods'; fa = 'کالاها';
																						|it = 'Merci';
																						|pl = 'Wiersze pozycji';
																						|tr = 'Ürünler'"), Items.Goods.SelectedRows) Then
		Return;
	EndIf;
	
	CheckBalance = True;
	
	If Not Object.Posted Then
		CheckBalance = False;
	ElsIf Object.Status = PredefinedValue("Enum.SalesOrderStatuses.NotApproved")
		Or Object.Status = PredefinedValue("Enum.SalesOrderStatuses.ToSupply") Then
		
		CheckBalance = True;
	EndIf;
	
	CancellationReason = PredefinedValue("Catalog.ReasonsForSaleOrderCancellation.EmptyRef");
	If UseReasonsForSalesOrderCancellations Then
		OpenForm("Catalog.ReasonsForSaleOrderCancellation.ChoiceForm",,,,,, New CallbackDescription("CancelUndeliveredLinesCompletion", ThisObject, New Structure("CheckBalance", CheckBalance)), FormWindowOpeningMode.LockOwnerWindow);
        Return;
	EndIf;
	
	UndoUndeliveredStringFragment(CancellationReason, CheckBalance);
EndProcedure

&AtClient
Procedure CancelUndeliveredLinesCompletion(Result, AdditionalParameters) Export
    
    CheckBalance = AdditionalParameters.CheckBalance;
    
    
    CancellationReason = Result;
    If Not ValueIsFilled(CancellationReason) Then
        Return;
    EndIf;
    
    UndoUndeliveredStringFragment(CancellationReason, CheckBalance);

EndProcedure

&AtClient
Procedure UndoUndeliveredStringFragment(Val CancellationReason, Val CheckBalance)
    
    Var RowsCountCanceled;
    
    RowsCountCanceled = CancelUndeliveredLinesServer(CancellationReason, CheckBalance);
    
    If RowsCountCanceled = 0 Then
        
        SalesClient.NotifyAboutCancellationOfUndeliveredLines(CancellationReason, RowsCountCanceled, CheckBalance);
        
    Else
        
        CalculateOrderTotals(ThisForm);
        SalesClient.NotifyAboutCancellationOfUndeliveredLines(CancellationReason, RowsCountCanceled, CheckBalance);
        
    EndIf;

EndProcedure

&AtClient
Procedure HideCanceledLines(Command)
	
	HideCanceledLines = Not HideCanceledLines;
	
	If HideCanceledLines Then
		Items.Goods.RowFilter = New FixedStructure("Canceled", False);
	Else
		Items.Goods.RowFilter = Undefined;
	EndIf;
	
	Items.GoodsHideCanceledLines.Check = HideCanceledLines;
	
EndProcedure

&AtClient
Procedure CalculateDiscountsMarkups(Command)
	
	CalculateDiscountsMarkupsClient();
	
EndProcedure

&AtClient
Procedure OpenSelection(Command)
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.StartTimeMeasurement(True,
		"Document.SalesOrder.DocumentForm.Command.OpenSelection");
	
	Cancel = False;
	If (ToUseTermsOfSales And Not ValueIsFilled(Object.Terms))
		Or Not ValueIsFilled(Object.Currency) Then
		ClearMessages();
		ReportErrorsWhenOpeningSelection(Cancel);
	EndIf;
	If Cancel Then
		Return;
	EndIf;
	
	HeaderParameter_ = NStr("vi = 'Chọn hàng hóa vào %Document%';
							|ru = 'Подбор товаров в %Document%';
							|en = 'Pick goods in %Document%'; fa = 'Pick goods in %Document%';
							|it = 'Selezione merci in %Document%';
							|pl = 'Wybór towarów w %Document%';
							|tr = '%Document% içindeki ürünlerin seçimi'");
	If ValueIsFilled(Object.Ref) Then
		HeaderParameter_ = StrReplace(HeaderParameter_, "%Document%", Object.Ref);
	Else
		HeaderParameter_ = StrReplace(HeaderParameter_, "%Document%", NStr("vi = 'đơn hàng của khách';
																			|ru = 'заказ клиента';
																			|en = 'sales order'; fa = 'sales order';
																			|it = 'ordine del cliente';
																			|pl = 'zamówienie klienta';
																			|tr = 'müşteri siparişi'"));
	EndIf;
	
	TransferOperations_ = GoodsTransferOperations();
	
	FormParameters = New Structure;
	FormParameters.Insert("Partner",                  Object.Partner);
	FormParameters.Insert("Terms",               Object.Terms);
	FormParameters.Insert("Organization",              Object.Organization);
	FormParameters.Insert("PriceIncludesVAT",          Object.PriceIncludesVAT);
	FormParameters.Insert("VATTaxation",       Object.VATTaxation);
	FormParameters.Insert("ReturnReusablePackage", Object.ToReturnReusablePackage);
	If TransferOperations_.Find(Object.BusinessOperation) <> Undefined Then
		If Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.DeliveryForPrincipal") Then
			FormParameters.Insert("FilterByProductType", New FixedArray(ProductsClientServer.SelectionByProductReusablePackagingWork()));
		Else
			FormParameters.Insert("FilterByProductType", New FixedArray(ProductsClientServer.SelectionByProductMultiTurnContainer()));
		EndIf;
		FormParameters.Insert("HideManualDiscounts", True);
	EndIf;
	FormParameters.Insert("SelectionModeUseWarehousesInTabularSection", True);
	FormParameters.Insert("UseShipmentDates",                UseShipmentByRowsInSalesOrder);
	FormParameters.Insert("Warehouse",                                   Object.Warehouse);
	FormParameters.Insert("Currency",                                  Object.Currency);
	FormParameters.Insert("Title",                               HeaderParameter_);
	FormParameters.Insert("Date",                                    Object.Date);
	FormParameters.Insert("Document",                                Object.Ref);
	FormParameters.Insert("SeriesSpecificationParameters",                  SeriesSpecificationParameters);
	FormParameters.Insert("Purpose",                              Object.Purpose);
	FormParameters.Insert("Department",                           Object.Department);
	FormParameters.Insert("SelectSupplyOptions",              UseShipmentByRowsInSalesOrder);
	FormParameters.Insert("SecurityOptionAndFlagSeparately",      SecurityOptionAndFlagSeparately);
	FormParameters.Insert("LimitSupplyOptions",         Not UseShipmentByRowsInSalesOrder);
	
	FormParameters.Insert("AvailableRemainingDocumentParameters",
		ProvisionInDocumentsClient.AvailableRemainingDocumentParameters(ThisObject));
	
	AddLocalizationFormParameters(FormParameters);
	
	OpenForm("DataProcessor.SelectGoodsToSalesDocument.Form", FormParameters, ThisForm, UUID);
	
EndProcedure

&AtClient
Procedure OpenInformationAboutDiscounts(Command)
	
	If Not Object.DiscountsAreCalculated Then
		ParametersStructure1 = New Structure;
		ParametersStructure1.Insert("ApplyToObject",                True);
		ParametersStructure1.Insert("OnlyPreliminaryCalculation",      False);
		ParametersStructure1.Insert("RestoreManagedDiscounts", True);
		ParametersStructure1.Insert("ManagedDiscounts", ManagedDiscounts);
		
		TheStructureOfTheMessages = CalculateDiscountsMarginsOnServer(ParametersStructure1);
		If TheStructureOfTheMessages.Messages.Count() > 0 And TheStructureOfTheMessages.AutomaticallyOpen Then
			OpenForm("CommonForm.MessagesOfDiscountsMarkups", TheStructureOfTheMessages, ThisForm, UUID);
		EndIf;
	EndIf;
	
	If Not ValueIsFilled(AddressOfAppliedDiscountsInTheTemporaryStorage) Then
		CalculateDiscountsWithoutApplyingToObject();
	EndIf;
	
	CurrentData = Items.Goods.CurrentData;
	DiscountsMarkupsFillingClient.OpenAppliedDiscountsForm(CurrentData, Object, ThisForm);
	
EndProcedure

&AtClient
Procedure AssignAutomaticDiscounts(Command)
	
	AddressInStorage = PerformPreliminaryCalculationOfDiscountsOnServer();
	Notification = New CallbackDescription("AssignAutomaticDiscountsCompletion", ThisObject);
	DiscountsMarkupsFillingClient.OpenManagedDiscountMarkUpAssignmentForm(AddressInStorage, Notification);
	
EndProcedure

&AtClient
Procedure AssignAutomaticDiscountsCompletion(ReturnedValue, AdditionalParameters) Export 
	
	If ReturnedValue <> Undefined Then

		ClearMessages();
		ApplyPaymentWithBonusPointsClient(, True);
		
		ManagedDiscounts = ReturnedValue;
		
		ParametersStructure1 = New Structure;
		ParametersStructure1.Insert("ApplyToObject",                True);
		ParametersStructure1.Insert("OnlyPreliminaryCalculation",      False);
		ParametersStructure1.Insert("RestoreManagedDiscounts", False);
		ParametersStructure1.Insert("ManagedDiscounts", ManagedDiscounts);
		
		TheStructureOfTheMessages = CalculateDiscountsMarginsOnServer(ParametersStructure1);
		If TheStructureOfTheMessages.Messages.Count() > 0 And TheStructureOfTheMessages.AutomaticallyOpen Then
			OpenForm("CommonForm.MessagesOfDiscountsMarkups", TheStructureOfTheMessages, ThisForm, UUID);
		EndIf;
		
		ShowUserNotification(
			NStr("vi = 'Chiết khấu (phụ thu)';
				|ru = 'Скидки (наценки)';
				|en = 'Discounts (markups)'; fa = 'تخفیف‌ها (افزایش قیمت‌ها)';
				|it = 'Sconti (sovrapprezzo)';
				|pl = 'Rabaty (marże)';
				|tr = 'İndirim (marj)'"),
			,
			NStr("vi = 'Đã tính chiết khấu (phụ thu)';
				|ru = 'Скидки (наценки) рассчитаны';
				|en = 'Discounts (markups) are calculated'; fa = 'Discounts (markups) are calculated';
				|it = 'Sconti (sovrapprezzi) sono calcolati';
				|pl = 'Rabaty (marże) są obliczone';
				|tr = 'İndirim (marj) uygulandı'"),
			PictureLib.Information32);
		
	EndIf;

EndProcedure

&AtClient
Procedure AssignAManualDiscount(Command)
	
	If Not DiscountsMarkupsFillingClient.ItIsPossibleToAssignManualDiscountMarkUp(Object, "Goods", NStr("vi = 'Hàng hóa';
																										|ru = 'Товары';
																										|en = 'Goods'; fa = 'کالاها';
																										|it = 'Merci';
																										|pl = 'Wiersze pozycji';
																										|tr = 'Ürünler'")) Then
		Return;
	EndIf;
	
	AddressInTempStorage = AddressOfDataForCalculatingManualDiscountsInTemporaryStorage(False);
	
	Notification = New CallbackDescription(
		"AssignAManualDiscountCompletion", 
		ThisObject, 
		New Structure("AddressInTempStorage", AddressInTempStorage));
	
	DiscountsMarkupsFillingClient.OpenFormForAssigningManualDiscounts(
		AddressInTempStorage,
		Object.Currency,
		Notification);
	
EndProcedure

&AtClient
Procedure AssignAManualDiscountCompletion(AmountOfManualDiscountMarkUp, AdditionalParameters) Export 
	
	AddressInTempStorage = AdditionalParameters.AddressInTempStorage;
	
	If AmountOfManualDiscountMarkUp <> Undefined Then
		
		AssignManualDiscountOnServer(AmountOfManualDiscountMarkUp, Undefined, AddressInTempStorage);
		DiscountsMarkupsFillingClient.NotifyAboutEndOfAssignmentOfManualDiscountsMargins(AmountOfManualDiscountMarkUp, Object.Currency);
		
		CalculateOrderTotals(ThisForm);
		
	EndIf;

EndProcedure

&AtClient
Procedure AssignAManualDiscountForSelectedLines(Command)
	
	If Not DiscountsMarkupsFillingClient.ItIsPossibleToAssignManualDiscountMarkUp(Object, "Goods", NStr("vi = 'Hàng hóa';
																										|ru = 'Товары';
																										|en = 'Goods'; fa = 'کالاها';
																										|it = 'Merci';
																										|pl = 'Wiersze pozycji';
																										|tr = 'Ürünler'")) Then
		Return;
	EndIf;
	
	AddressInTempStorage = AddressOfDataForCalculatingManualDiscountsInTemporaryStorage(True);
	
	Notification = New CallbackDescription(
		"AssignAManualDiscountForSelectedLinesCompletion", 
		ThisObject, 
		New Structure("AddressInTempStorage", AddressInTempStorage));
	
	DiscountsMarkupsFillingClient.OpenFormForAssigningManualDiscounts(
		AddressInTempStorage,
		Object.Currency,
		Notification);
	
EndProcedure

&AtClient
Procedure AssignAManualDiscountForSelectedLinesCompletion(AmountOfManualDiscountMarkUp, AdditionalParameters) Export 
	
	AddressInTempStorage = AdditionalParameters.AddressInTempStorage;
	
	If AmountOfManualDiscountMarkUp <> Undefined Then
		
		AssignManualDiscountOnServer(AmountOfManualDiscountMarkUp, Items.Goods.SelectedRows, AddressInTempStorage);
		DiscountsMarkupsFillingClient.NotifyAboutEndOfAssignmentOfManualDiscountsMargins(AmountOfManualDiscountMarkUp, Object.Currency);
		
		CalculateOrderTotals(ThisForm);
		
	EndIf;

EndProcedure

&AtClient
Procedure CancelManualDiscounts(Command)
	
	If Not DiscountsMarkupsFillingClient.ItIsPossibleToCancelManualDiscountsMarkups(Object, "Goods", NStr("vi = 'Hàng hóa';
																											|ru = 'Товары';
																											|en = 'Goods'; fa = 'کالاها';
																											|it = 'Merci';
																											|pl = 'Wiersze pozycji';
																											|tr = 'Ürünler'")) Then
		Return;
	EndIf;
	
	CancelManualDiscountsOnServer();
	DiscountsMarkupsFillingClient.NotifyAboutEndOfAssignmentOfManualDiscountsMargins();
	
	CalculateOrderTotals(ThisForm);
	
EndProcedure

&AtClient
Procedure Attachable_PropertiesExecuteCommand(ItemOrCommand, Var_URL = Undefined, StandardProcessing = Undefined)
	PropertyManagerClient.ExecuteCommand(ThisObject, ItemOrCommand, StandardProcessing);
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
Procedure FillInTheWarehouseInSelectedLines(Command)
	
	SelectedRows = Items.Goods.SelectedRows;
	If WarehousesClient.CheckPossibilityOfFillingWarehousesInTablePart(Object, Object.Goods, NStr("vi = 'Hàng hóa';
																									|ru = 'Товары';
																									|en = 'Goods'; fa = 'کالاها';
																									|it = 'Merci';
																									|pl = 'Wiersze pozycji';
																									|tr = 'Ürünler'"), SelectedRows) Then
		FilterArray = New Array();
		FilterArray.Add(PredefinedValue("Enum.SelectWarehouseGroup.AllowInOrders"));
		FilterArray.Add(PredefinedValue("Enum.SelectWarehouseGroup.AllowInOrdersAndInvoices"));
		FilterStructure1 = New Structure("SelectGroup, IsFolder", FilterArray, False);
		ParametersStructure = New Structure("Filter,GroupOfWarehouses,TableRepresentation", 
				FilterStructure1, Object.Warehouse, TableRepresentation.List);
		SelectedWarehouse = Undefined;
		
		
		OpenForm(
			"Catalog.Warehouses.ChoiceForm",
			ParametersStructure,
			ThisForm,
			,
			,
			,
			New CallbackDescription("FillInTheWarehouseInSelectedLinesCompletion",
			ThisObject,
			New Structure("SelectedRows", SelectedRows)),
			FormWindowOpeningMode.LockOwnerWindow);
			
	EndIf;
	
EndProcedure

&AtClient
Procedure FillInTheWarehouseInSelectedLinesCompletion(Result, AdditionalParameters) Export
    
    SelectedRows = AdditionalParameters.SelectedRows;
    
    
    SelectedWarehouse = Result;
    If ValueIsFilled(SelectedWarehouse) Then
        FilledWithRows = FillWarehouseInSelectedLinesOnServer(SelectedRows, SelectedWarehouse);
        WarehousesClient.ShowNotificationAboutFillingOfWarehouseInTablePart(SelectedWarehouse, FilledWithRows, SelectedRows.Count());
    EndIf;

EndProcedure

&AtClient
Procedure SplitRow(Command)
	
	FormTable  = Items.Goods;
	TableData = Object.Goods;
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.StructureOfRecalculationOfAmount(
		"Count, Sum, VATAmount, AmountIncludingVAT, ManualDiscount, DiscountMarkupAmount,
		|AmountOfBonusPointsToDeduction, AmountOfBonusPointsToDeductionInCurrency, " + DependentPropsByString(),
		"NumberOfPackages");
		
	If FormTable.CurrentData <> Undefined Then
		BatchProcessingOfTablePartClientServer.FillInStructureForRecalculatingAmount(StructureOfRecalculationOfAmount, FormTable.CurrentData);
	EndIf;
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("StructureOfRecalculationOfAmount", StructureOfRecalculationOfAmount);
	
	ProcessingOfTabularFormsClient.SplitRow(TableData, FormTable,
		New CallbackDescription("SplitRowCompletion", ThisObject, AdditionalParameters));
	
EndProcedure

&AtClient
Procedure SplitRowCompletion(NewRow, AdditionalParameters) Export 
	
	CurrentRow = Items.Goods.CurrentData;
	
	If NewRow <> Undefined Then
		
		NewRow.RowCode = 0;
		
		StructureOfActions = New Structure;
		AddCollateralActionsOnClient(StructureOfActions,"UpdateProductCache_");
		AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions, Object);
		
		BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
		BatchProcessingOfTablePartClient.ProcessTSString(NewRow, StructureOfActions, CachedValues);
		
		BatchProcessingOfTablePartClientServer.AddLineToRecalculateAmount(AdditionalParameters.StructureOfRecalculationOfAmount, CurrentRow);
		BatchProcessingOfTablePartClientServer.AddLineToRecalculateAmount(AdditionalParameters.StructureOfRecalculationOfAmount, NewRow);
		BatchProcessingOfTablePartClientServer.RecalculateAmounts(AdditionalParameters.StructureOfRecalculationOfAmount);
		
		WhenChangingWarehouseInTablePartServer();
		CalculateOrderTotals(ThisObject);
		
		DiscountsMarkupsFillingClient.ResetDiscountsCalculatedFlag(ThisObject);
		
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
Procedure DownloadFromTSDCompletion(Result, Var_Parameters) Export
	
	If Result.Result Then
		ProcessBarcodes(Result.TableOfGoods);
	Else
		EquipmentManagerTMClient.ReportError(Result);
	EndIf;
	
EndProcedure

&AtServer
Function TheStructureOfTheMessages()
	
	Return DiscountsMarkupsFillingServer.TheStructureOfTheMessages(Object);
	
EndFunction

&AtClient
Procedure ShowMessages(Command)
	
	DiscountsMarkupsFillingClient.OpenMessageForm(TheStructureOfTheMessages(), ThisForm);
	
EndProcedure

&AtClient
Procedure ToReadLoyaltyCard(Command)
	
	If Object.Approved Then
		Return;
	EndIf;
	
	OpeningParameters = New Structure;
	OpeningParameters.Insert("Partner", Object.Partner);
	OpeningParameters.Insert("Organization", Object.Organization);
	
	OpenForm(
		"Catalog.LoyaltyCards.Form.ReadLoyaltyCard",
		OpeningParameters,
		ThisForm,
		ThisForm.UUID);
	
EndProcedure

&AtClient
Procedure PrintDetails(Command)
	
	Try
		LockFormDataForEdit();
	Except
		ShowMessageBox(Undefined, BriefErrorDescription(ErrorInfo()));
		Return;
	EndTry;
	
	DeliveryOrderData = GoodsDeliveryClientServer.OrderParameters();
	FillPropertyValues(DeliveryOrderData, Object);
	
	ParametersStructure = New Structure();
	ParametersStructure.Insert("ReadOnly",                      ReadOnly);
	ParametersStructure.Insert("DeliveryAddress",                  Object.DeliveryAddress);
	ParametersStructure.Insert("DeliveryAddressValue",          Object.DeliveryAddressValue);
	ParametersStructure.Insert("DeliveryAddressFieldValues",     Object.DeliveryAddressFieldValues);
	ParametersStructure.Insert("DeliveryZone",                   Object.DeliveryZone);
	ParametersStructure.Insert("DeliveryTimeFrom",                 Object.DeliveryTimeFrom);
	ParametersStructure.Insert("DeliveryTimeTo",                Object.DeliveryTimeTo);
	ParametersStructure.Insert("AdditionalDeliveryInformation", Object.AdditionalDeliveryInformation);
	ParametersStructure.Insert("ShipperBankAccount", Object.ShipperBankAccount);
	ParametersStructure.Insert("GoodsRecipientBankAccount",  Object.GoodsRecipientBankAccount);
	ParametersStructure.Insert("CounterpartyBankAccount",      Object.CounterpartyBankAccount);
	ParametersStructure.Insert("Shipper",               Object.Shipper);
	ParametersStructure.Insert("GoodsRecipient",                Object.GoodsRecipient);
	ParametersStructure.Insert("Partner",                        Object.Partner);
	ParametersStructure.Insert("BusinessOperation",          Object.BusinessOperation);
	ParametersStructure.Insert("Counterparty",                     Object.Counterparty);
	ParametersStructure.Insert("BankAccount",                 Object.BankAccount);
	ParametersStructure.Insert("Organization",                    Object.Organization);
	ParametersStructure.Insert("Date",                           Object.Date);
	ParametersStructure.Insert("Director",                   Object.Director);
	ParametersStructure.Insert("ChiefAccountant",               Object.ChiefAccountant);
	ParametersStructure.Insert("PaymentPurposes",              Object.PaymentPurposes);
	ParametersStructure.Insert("OrderNumber", ObjectsPrefixesClientServer.NumberForPrinting(Object.Number));
	ParametersStructure.Insert("OrderDate",                     Format(Object.Date, "DLF = D"));
	ParametersStructure.Insert("AttributeSelectionParameters",      AttributeSelectionParameters);
	ParametersStructure.Insert("Ref",                         Object.Ref);
	ParametersStructure.Insert("DeliveryOrderData",   DeliveryOrderData);
	ParametersStructure.Insert("DeliveryIsRequired", Object.DeliveryIsRequired);
	ParametersStructure.Insert("DeliverySpecificationMethod", Object.DeliverySpecificationMethod);
	
	OpenForm("Document.SalesOrder.Form.PrintDetails", ParametersStructure, ThisForm,,,, Undefined, FormWindowOpeningMode.LockOwnerWindow);

EndProcedure

&AtClient
Procedure InsertRows(Command)
	
	NumberOfProductsBeforeInsertion = Object.Goods.Count();
	
	ClearMessages();
	ApplyPaymentWithBonusPointsClient(, True);

	GetLinesFromClipboard();
	ProvisionInDocumentsClientServer.FillInServiceDetails(Object.Goods, DateOfShipmentRequired_, WarehouseIsRequired);
	DiscountsMarkupsFillingClient.ResetDiscountsCalculatedFlag(ThisForm);
	
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
		"Products,Characteristic,Count,Warehouse,DateOfShipment");
	
EndProcedure

&AtClient
Procedure ImportFromExternalFile(Command)
	
	ImportParameters = ProcessingOfTabularFormsClient.ProductLoadingParameters();
	ImportParameters.Organization = Object.Organization;
	ImportParameters.ImportPrices = True;
	ImportParameters.PriceIncludesVAT    = Object.PriceIncludesVAT;
	ImportParameters.VATTaxation = Object.VATTaxation;
	
	If Object.NotShipInInstallments And ValueIsFilled(Object.DateOfShipment) Then
		ImportParameters.FillingDate   = Object.DateOfShipment;
	Else
		ImportParameters.FillingDate   = Object.Date;
	EndIf;
		
	ImportParameters.ThisIsReusablePackage  = Object.ToReturnReusablePackage;
	ImportParameters.ComponentsPriceParameters.Date       = Object.Date;
	ImportParameters.ComponentsPriceParameters.Currency     = Object.Currency;
	ImportParameters.ComponentsPriceParameters.Terms = Object.Terms;
	
	TransferOperations_ = GoodsTransferOperations();
	If TransferOperations_.Find(Object.BusinessOperation) <> Undefined Then
		If Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.DeliveryForPrincipal") Then
			ImportParameters.FilterParameters.Insert("ItemsType", ProductsClientServer.SelectionByProductReusablePackagingWork());
		Else
			ImportParameters.FilterParameters.Insert("ItemsType", ProductsClientServer.SelectionByProductMultiTurnContainer());
		EndIf;
	EndIf;
	
	Notification = New CallbackDescription("ImportFromExternalFileCompletion", ThisObject);
	ProcessingOfTabularFormsClient.ShowProductUploadForm(ImportParameters, Notification);
	
EndProcedure

&AtClient
Procedure ImportFromExternalFileCompletion(ImportedDataAddress, AdditionalParameters) Export
	
	If ValueIsFilled(ImportedDataAddress) Then
		ClearMessages();
		GetUploadedProductsFromStorage(ImportedDataAddress);
	EndIf;
	
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
Procedure ShowThePartnerSNomenclature(Command)
	
	PartnersProductsClient.ShowThePartnerSNomenclature(Object.Partner, Object.Ref, Items.Goods.CurrentData, NStr("vi = 'Khách hàng';
																												|ru = 'Клиент';
																												|en = 'Customer'; fa = 'مشتری';
																												|it = 'Cliente';
																												|pl = 'Customer';
																												|tr = 'Müşteri'"));

EndProcedure

&AtClient
Procedure CloseOrder(Command)
	
	If Modified Or Not Object.Posted Then
		AdditionalParameters = New Structure;
		Response = Undefined;
		ShowQueryBox(New CallbackDescription("CloseOrderCompletion", ThisObject, AdditionalParameters),
			NStr("vi = 'Cần kết chuyển chứng thừ để thực hiện giao dịch. Kết chuyển chứng từ?';
				|ru = 'Необходимо провести документ для выполнения операции. Провести документ?';
				|en = 'To proceed, you need to post the document. Do you want to post the document?'; fa = 'To proceed, you need to post the document. Do you want to post the document?';
				|it = 'È necessario pubblicare il documento per eseguire operazione. pubblicare documento?';
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
	
	ClosureStructure.Insert("TableOfGoodsExpense",         PutItInTemporaryStorageOnServer("Goods", New UUID));
	
	OpenForm("DataProcessor.OrderClosureWizard.Form.ClosureForm",
	             ClosureStructure, ThisForm,,,, Undefined, FormWindowOpeningMode.LockOwnerWindow);
	
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
		ClearMessages();
		Write(WriteParameters);
	EndIf;
	
EndProcedure

&AtClient
Procedure WriteDocument(Command)
	
	TMCommonUseClient.Write(ThisForm, True);
	
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
Procedure ReReadDocument(Command)
	
	ThisForm.Read();
	EnableWaitingHandlerReceivingCarriers();
	EnableWaitingHandlerForDocumentDataBasedOn();
	
EndProcedure

&AtClient
Procedure PaymentSettlement(Command)
	ARAPAccountingClient.PaymentSettlement(ThisForm, Items.CreditPaymentForm);
EndProcedure

&AtClient
Procedure CancelPaymentWithBonusPoints(Command)
	
	ApplyPaymentWithBonusPointsClient();
	
	DiscountsMarkupsFillingClient.ResetDiscountsCalculatedFlag(ThisForm);
	
EndProcedure

&AtClient
Procedure AddPaymentWithBonusPoints(Command) Export
	
	If RetailSalesClient.CheckPossibilityOfAddingPaymentWithBonusPoints(ThisObject, False) Then
		NotificationDetailsCompletion = New CallbackDescription("AddPaymentWithBonusPointsContinued", ThisObject);
		If Object.Posted Then
			RetailSalesClient.DisplayQuestionAboutNeedForUnverifiedDocument(ThisObject, NotificationDetailsCompletion);
		Else
			RunCallback(NotificationDetailsCompletion, True);
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure AddPaymentWithBonusPointsContinued(Result, AdditionalParameters) Export

	If Result = True Then
		
		Cancel  = False;
		
		If Not Object.DiscountsAreCalculated And DiscountsHaveChanged() Then
			ApplyDiscountMarkUpChangesOnCustomer(Cancel);
		EndIf;
		
		If Cancel Then
			Return;
		EndIf;
		
		FormOpenParameters = New Structure;
		FormOpenParameters.Insert("Partner",                   Object.Partner);
		FormOpenParameters.Insert("LoyaltyCard",           Object.LoyaltyCard);
		FormOpenParameters.Insert("AddressOfTheTablePartProducts", AddressOfTheTablePartProducts());
		FormOpenParameters.Insert("Currency",                    Object.Currency);
		AddPriceControlParameterForIDCLocalizationToForm(ThisObject, FormOpenParameters);
		
		OpenForm(
			"Catalog.LoyaltyPrograms.Form.PaymentWithBonusPoints",
			FormOpenParameters,
			ThisObject,,,,
			New CallbackDescription("AddPaymentWithBonusPointsCompletion", ThisObject));
			
	EndIf;
	
EndProcedure

&AtClient
Procedure AddPaymentWithBonusPointsCompletion(Result, AdditionalParameters) Export
	
	If Not ValueIsFilled(Result) Then
		CalculateOrderTotals(ThisForm);
		Return;
	EndIf;
	
	ApplyPaymentWithBonusPointsClient(Result.AddressInTempStorage);
	
	DiscountsMarkupsFillingClient.ResetDiscountsCalculatedFlag(ThisForm);
	
EndProcedure

&AtClient
Procedure Attachable_UpdateSBPPaymentStatus(Command)

	ClearMessages();
	CashClientLocalization.UpdateStatusOfSBPPaymentByDocument(ThisObject, Object.Ref);

EndProcedure

#EndRegion

#Region Private

// StandardSubsystems.Properties

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

&AtServer
Procedure WhenChangingKeyDetailsStatusOfEDO()
	
	
EndProcedure

&AtServer
Procedure FillInSubordinatePropertiesForStatistics(ParentPropsName)
	ObjectsFillingByStatistics.FillInSubordinateDetailsOfObject(Object, ParentPropsName);
EndProcedure

&AtServer
Procedure SetConditionalAppearance()

	ConditionalAppearance.Items.Clear();

	TransferOperations_ = SalesServer.GoodsTransferOperations();

	// Conditional registration of collateral.
	TMCommonUse.SetUncheckBlank(
		ConditionalAppearance, "DateOfShipment", "Object.DateOfShipment", "DateOfShipmentRequired_");
	
	TMCommonUse.SetUncheckBlank(
		ConditionalAppearance, "GoodsDateOfShipment", "Object.Goods.DateOfShipment", "Object.Goods.DateOfShipmentRequired_");
	
	TMCommonUse.SetUncheckBlank(
		ConditionalAppearance, "Warehouse", "Object.Warehouse", "WarehouseIsRequired");
	
	TMCommonUse.SetUncheckBlank(
		ConditionalAppearance, "GoodsWarehouse", "Object.Goods.Warehouse", "Object.Goods.WarehouseIsRequired");
		
	ProvisionInDocumentsServer.SetConditionalAppearanceApart(
		ConditionalAppearance,
		Items.GoodsWithAssignment,
		"Object.Goods.SupplyOption",
		"Object.Goods.ItemsType");
		
	ProvisionInDocumentsServer.AvailableLeftoversAddColumnLayoutAvailable(ThisObject);
	
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
	
	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsPercentRateOfAutomaticDiscountMarkup.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsDiscountMarkupAmount.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsPercentRateOfManualDiscount.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsManualDiscount.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.Canceled");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;

	Item.Appearance.SetParameterValue("MarkNegatives", True);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsPrice.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.PriceKind");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	Item.Appearance.SetParameterValue("ReadOnly", True);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsSum.Name);

	FilterGroup1 = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup1.GroupType = DataCompositionFilterItemsGroupType.OrGroup;

	FilterGroup2 = FilterGroup1.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup2.GroupType = DataCompositionFilterItemsGroupType.AndGroup;

	ItemFilter = FilterGroup2.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.PriceKind");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;

	FilterGroup3 = FilterGroup2.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup3.GroupType = DataCompositionFilterItemsGroupType.OrGroup;

	ItemFilter = FilterGroup3.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("UseDiscountAdjustmentsInSales");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;

	ItemFilter = FilterGroup3.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.BusinessOperation");
	ItemFilter.ComparisonType = DataCompositionComparisonType.InList;
	ItemFilter.RightValue = TransferOperations_;

	Item.Appearance.SetParameterValue("ReadOnly", True);

	//
	
	VATAccountingERP.EstablishConditionalAppearanceOfVATAmountsForSalesTaxation(ThisForm);

	//

	EnterprisePricesFillingServer.SetConditionalAppearancePriceIncludesVAT(ThisForm);

	//

	ProductsServer.SetConditionalAppearanceOfUnitsOfMeasurement(ThisForm);

	//

	TMCommonUse.SetConditionalAppearanceOfPriority(ThisForm);

	//

	ProductsServer.EstablishConditionalAppearanceOfProductCharacteristics(ThisForm);

	//

	WarehousesServer.SetConditionalAppearanceOfVTCHWarehouse(ThisForm);

	//
	
	WarehousesServer.EstablishConditionalAppearanceOfVTCHDivision(ThisForm);
	
	//
	
	ConditionalDesignParameters = WarehousesServer.ParametersOfConditionalAppearanceOfVHFWarehouseByItemType();
	ConditionalDesignParameters.Form = ThisObject;
	WarehousesServer.SetConditionalAppearanceOfVHFWarehouseByTypeOfItem(ConditionalDesignParameters);
	
	//

	ConditionalDesignParameters = WarehousesServer.ParametersOfConditionalAppearanceOfVHFWarehouseByItemType();
	ConditionalDesignParameters.Form = ThisObject;
	WarehousesServer.SetConditionalAppearanceOfVHFWarehouseByTypeOfItem(ConditionalDesignParameters);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsFillInTheWarehouseInSelectedLines.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("WarehouseGroup_");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;

	Item.Appearance.SetParameterValue("Enabled", False);

	//

	EnterprisePricesFillingServer.EstablishConditionalAppearanceOfPriceTypes(ThisForm);

	//
	
	ProductsServer.EstablishConditionalAppearanceOfContent(ThisForm);

	//
	
	InstallationParameters = ReusablePackageServer.ParametersForSettingConditionalAppearanceForLinesWithMultiTurnContainers();
	
	InstallationParameters.Form                 = ThisForm;
	InstallationParameters.ThisIsAdmission        = True;
	
	ReusablePackageServer.SetConditionalAppearanceForLinesWithMultiTurnContainers(InstallationParameters);

	//

	ProductsServer.EstablishConditionalAppearanceOfProductSeries(ThisForm, "SeriesAlwaysWHGoods");

	//

	Query = New Query(
	"SELECT
	|	Priorities.Ref AS Priority,
	|	Priorities.Color   AS Color
	|FROM
	|	Catalog.Priorities AS Priorities");
	
	QueryResult = Query.Execute();
	
	If Not QueryResult.IsEmpty() Then
		
		Selection = QueryResult.Select();
		
		While Selection.Next() Do
			
			Item = ConditionalAppearance.Items.Add();

			ItemField = Item.Fields.Items.Add();
			ItemField.Field = New DataCompositionField(Items.Priority.Name);

			ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
			ItemFilter.LeftValue = New DataCompositionField("Object.Priority");
			ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
			ItemFilter.RightValue = Selection.Priority;
			
			SamplingColor = Selection.Color; // ValueStorage
			Item.Appearance.SetParameterValue("TextColor", SamplingColor.Get());
			
		EndDo;
		
	EndIf;

	//

	SetsServer.SetConditionalAppearance(ThisForm, "Goods");
	
	//
	OrdersServer.SetAppearanceOfCanceledLine(ConditionalAppearance,
		Items.Goods,
		Items.GoodsCanceled.Name,
		Items.GoodsCancellationReason.Name);
	
	ListOfTransferOperations = New ValueList();
	ListOfTransferOperations.Add(PredefinedValue("Enum.BusinessTransactions.TransferToCommissionAgent"));
	ListOfTransferOperations.Add(PredefinedValue("Enum.BusinessTransactions.TransferToStorageWithRightOfSale"));
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsPrice.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsSum.Name);
	
	FilterGroup1 = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup1.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	
	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.Canceled");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.BusinessOperation");
	ItemFilter.ComparisonType = DataCompositionComparisonType.InList;
	ItemFilter.RightValue = ListOfTransferOperations;
	
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	
	//
	
	LinesOfBusinessServer.EstablishConditionalAppearanceOfDirectionOfActivity(ThisForm);

	//
	
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsDepartment.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.BusinessOperation");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = PredefinedValue("Enum.BusinessTransactions.DeliveryForPrincipal");

	Item.Appearance.SetParameterValue("Visible", False);
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	
	RetailSalesLocalization.SetConditionalAppearance(ThisObject);
	
EndProcedure

&AtServer
Procedure FillInVATTaxationATServer()
	
	FillInSalesVATTaxation();
	VATTaxationOnChangeServer();
	
EndProcedure

#Region Supply

&AtClient
Procedure FillInShipmentDateCompletion(SelectedDate, AdditionalParameters) Export
	
	ClearMessages();
	
	If SelectedDate <> Undefined And ValueIsFilled(SelectedDate) Then
		
		DateOfShipment = SelectedDate;
		ArrayOfSelectedRows = AdditionalParameters.ArrayOfSelectedRows;
		
		FillInShipmentDateServer(DateOfShipment, ArrayOfSelectedRows);
		SalesClient.NotifyEndOfFillingInShipmentDates(DateOfShipment, True);
	
	EndIf; 
	
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
Function DocumentParametersForSoftwareActions(Form, SecurityOptionAndFlagSeparately, DateOfShipment)
	
	DocumentParameters = New Structure();
	DocumentParameters.Insert("Form",                                 Form);
	DocumentParameters.Insert("Collection",                             Form.Object.Goods);
	DocumentParameters.Insert("SecurityOptionAndFlagSeparately",    SecurityOptionAndFlagSeparately);
	
	Return DocumentParameters;
	
EndFunction

&AtClient
Procedure AddCollateralActionsOnClient(StructureOfActions, StringFields_)
	
	DocumentParameters = DocumentParametersForSoftwareActions(
		ThisObject,
		SecurityOptionAndFlagSeparately,
		Undefined);
		
	ProvisionInDocumentsClientServer.AddCollateralActions(
		StructureOfActions,
		StringFields_,
		DocumentParameters);
	
EndProcedure

&AtServer
Procedure AddCollateralActionsOnServer(StructureOfActions, StringFields_, DateOfShipment = Undefined)
	
	DocumentParameters = DocumentParametersForSoftwareActions(
		ThisObject,
		SecurityOptionAndFlagSeparately,
		DateOfShipment);
		
	ProvisionInDocumentsClientServer.AddCollateralActions(
		StructureOfActions,
		StringFields_,
		DocumentParameters);
	
EndProcedure

&AtClient
Procedure HyperlinkStateOfProvisionClickGeneral()
	
	FormParameters = ProvisionInDocumentsClient.SecurityStatusHyperlinkClick(ThisObject);
	
	If Object.Status = PredefinedValue("Enum.SalesOrderStatuses.NotApproved") Then
		
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

&AtServer
Procedure FillInServiceDetailsOfDocumentForm()
	
	DocumentParameters = DocumentParametersForSoftwareActions(
		ThisObject,
		SecurityOptionAndFlagSeparately,
		Undefined);
		
	ProvisionInDocumentsServer.FillInServiceDetailsOfDocumentForm(DocumentParameters);
	
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
	DiscountsMarkupsFillingClient.ResetDiscountsCalculatedFlag(ThisObject);
	
	If Var_Parameters.FormParameters.Mode = ProvisionInDocumentsClientServer.SeriesSelectionMode() Then
		ProductsSeriesRecalculatePrices();
	EndIf;
	
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
	
	ThereAreChangesInDateOfShipment = False;
	Documents.SalesOrder.AfterFillingOutCollateral(Object, Changes, Mode, FillParameters, ThereAreChangesInDateOfShipment);
	If ThereAreChangesInDateOfShipment Then
		ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisObject, "Goods.DateOfShipment");
		AdjustVATRates();
	EndIf;
	SetVisibilityOfShippingDateFormElements();
	
	OrdersServer.RecalculateDependentPropsAfterSplittingRows(Changes, DependentPropsByString());
	
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
	
	CalculateOrderTotals(ThisObject);
	
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
Procedure GoodsWarehouseOnChangeServer(CurrentRow)
	
	CurrentData = Object.Goods.FindByID(CurrentRow);
	StructureOfActions = New Structure;
	StructureOfActions.Insert("CheckSeriesCalculateStatus",
		New Structure("Warehouse, SeriesSpecificationParameters", CurrentData.Warehouse, SeriesSpecificationParameters));
	
	BatchProcessingOfTablePartServer.ProcessTSString(CurrentData, StructureOfActions, Undefined);
	
	UpdateColumnAvailableServer();
	
EndProcedure

&AtServer
Function SoftwareSelectionParameters(Mode)
	
	FormParameters = ProvisionInDocumentsServer.SoftwareSelectionParameters(
		ThisObject,
		Items.Goods.CurrentRow,
		Mode);
		
	If Object.BusinessOperation
			= PredefinedValue("Enum.BusinessTransactions.DeliveryForPrincipal") Then
		FormParameters.AllowedNonIsolatedActions.Clear();
	EndIf;
	
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

#Region ShippingDates

&AtServer
Procedure SetVisibilityOfShippingDateFormElements()

	Items.GoodsDateOfShipment.Visible = Not Object.NotShipInInstallments
		And UseShipmentByRowsInSalesOrder 
		And Not Object.ThisIsOrderAsInvoice;
	Items.DateOfShipment.Visible = Object.NotShipInInstallments;
	Items.FillInShipmentDate.Visible = Not Object.NotShipInInstallments;

EndProcedure

&AtServer
Procedure DateOfShipmentOnChangeServer()
	
	PrepareAndSetVisibilityForAssemblyAndDelivery();
	FillInShipmentDateServer(Object.DateOfShipment, Undefined);
	ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisObject, "Goods.DateOfShipment");
	
EndProcedure

&AtServer
Procedure FillInShipmentDateServer(DateOfShipment, ArrayOfSelectedRows)

	ProvisionInDocumentsServer.FillInDetailsInCollection(Object.Goods, "DateOfShipment", DateOfShipment, ArrayOfSelectedRows);
	
	AdjustVATRates(ArrayOfSelectedRows);
	
	UpdateDuplicateDependentDetails();
		
	CalculateOrderTotals(ThisObject);
		
EndProcedure

&AtServer
Procedure NotShipInInstallmentsOnChangeServer()

	If Object.NotShipInInstallments Then
		Object.DateOfShipment = ProvisionInDocumentsServer.MaximumValueInCollection(Object.Goods, "DateOfShipment", '00010101');
		ProvisionInDocumentsServer.FillInDetailsInCollection(Object.Goods, "DateOfShipment", Object.DateOfShipment);
	EndIf; 
	
	ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisObject, "Goods.DateOfShipment, NotShipInInstallments");
	
	SetVisibilityOfShippingDateFormElements();

EndProcedure

#EndRegion

#Region OnChangeAttributes

&AtServer
Procedure PartnerOnChangeServer()
	
	If ToUseTermsOfSales Then
		FillIn_TermsOfSales();
	Else
		PartnersAndCounterparties.FillInPartnerSDefaultCounterparty(Object.Partner, Object.Counterparty);
		UseCustomerContracts = GetFunctionalOption("UseCustomerContracts");
		If UseCustomerContracts Then
			FillInDefaultContract();
		EndIf;
	EndIf;
	
	PartnersProductsServer.FillInPartnerProductListByProductNameWhenPartnerChanges(Object.Goods, Object.Partner);
	
	WarehouseOnChangeServer();
	
	FillInServiceDetailsForProductRange();
	FillInServiceDetailsOfDocumentForm();
	
	UpdateDuplicateDependentDetails();
	Object.CounterpartyBankAccount = GetDefaultCounterpartyBankAccountServer(Object.Counterparty, Object.BankAccount);
	
	CalculateOrderTotals(ThisForm);
	
	SalesServer.SetContractAvailability(Object, Items.Contract.Enabled, Items.Contract.Visible, Object.Contract);
	
	UpdateAvailabilityOfReturnContainerItems(ThisForm);
	
	FillInAndSetDeliveryAttributesServer("Partner");
	
	ArrayOfChangedProps = New Array;
	ArrayOfChangedProps.Add("Terms");
	ArrayOfChangedProps.Add("Partner");
	ArrayOfChangedProps.Add("Contract");
	ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisObject, ArrayOfChangedProps);
	
	SetVisibilityOfShipmentBanToPartner();
	SalesServer.PartnerOnChange(Object);
	
	ResponsiblePersonsServer.FillInManagerSelectionList_(Items.Manager, Object);
	ResponsiblePersonsServer.InstallManager(Object, Object.DocumentBasis);
	FillInSubordinatePropertiesForStatistics("Counterparty");
	
	ResponsiblePersonsServer.WhenChangingRelatedDocumentDetails(Object);
	
	MailoutsAndNotificationsToCustomers.SetVisibilityOfSubscribingToAlertsInObject(
		Items.GroupSubscribeToAlerts,
		Object.Partner,
		PredefinedValue("Enum.NotificationEventTypes.OrderStatusChange"));
		
	If UseLinesOfBusiness Then
		LinesOfBusinessServer.FillInDefaultDirection(Object.LineOfBusiness, Object.Terms, Object.Contract);
	EndIf;
	LinesOfBusinessServer.WhenChangingDirectionOfActivity(ThisObject);
	ProvisionInDocumentsServer.WhenChangingDocumentDetails(ThisObject);
	
	PrepareAndSetVisibilityForAssemblyAndDelivery();
	
	UpdateDeliveryPlanningView();
	
	
EndProcedure

&AtServer
Procedure ContactPersonOnChangeServer(PartnerChanged_)
	
	OwnerOfContactPerson = Common.ObjectAttributeValue(Object.ContactPerson, "Owner");
	If OwnerOfContactPerson <> Object.Partner Then
		Object.Partner = OwnerOfContactPerson;
		PartnerOnChangeServer();
		PartnerChanged_ = True;
	EndIf;
	
EndProcedure

&AtServer
Procedure CounterpartyOnChangeServer()
	
	SalesServer.SetContractAvailability(Object, Items.Contract.Enabled, Items.Contract.Visible, Object.Contract);
	
	If ValueIsFilled(Object.Counterparty) Then
		
		FillInDefaultContract();
		SalesServer.PartnerOnChange(Object);
		
	EndIf;
	
	If UseLinesOfBusiness Then
		LinesOfBusinessServer.FillInDefaultDirection(Object.LineOfBusiness, Object.Terms, Object.Contract);
	EndIf;
	LinesOfBusinessServer.WhenChangingDirectionOfActivity(ThisObject);
	ChangedBankingDetails = ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisObject, "Counterparty");
	
	FillInSubordinatePropertiesForStatistics("Counterparty");
	
	WhenChangingKeyDetailsStatusOfEDO();
	ProvisionInDocumentsServer.WhenChangingDocumentDetails(ThisObject);
	
	FillInAndSetDeliveryAttributesServer("Partner");
	
	
	WhenChangingElementLocalization(ThisObject, "Counterparty");
	CheckCorrectAvailabilityOfDiscountsPaymentsWithBonusPointsLocalization();
	
EndProcedure

&AtServer
Function TermsOnChangeServer(RecalculatePrices_2)
	
	ConsignmentSales25 = SalesServer.ThisIsAgreementOnNewCommission(Object.Terms);
	
	FillInParametersOfPriceTypeConnectionAndPriceIncludesVATAttribute();
	
	DocumentSales = FormAttributeToValue("Object");
	PricesCalculated_ = DocumentSales.FillInTermsOfSalesUnderAgreement(RecalculatePrices_2);
	ValueToFormAttribute(DocumentSales, "Object");
	
	ContractParameters = ContractParameters(Object.Contract, Object.BusinessOperation);
	If ContractParameters.ByNewCommission Then
		Object.PriceIncludesVAT = ContractParameters.PriceIncludesVAT;
	EndIf;
		
	DocumentCurrency = Object.Currency;
	
	BusinessOperationOnChangeServer(False);
	WarehouseOnChangeServer();
	
	FillInServiceDetailsForProductRange();
	FillInServiceDetailsOfDocumentForm();
	
	UpdateDuplicateDependentDetails();
	Object.CounterpartyBankAccount = GetDefaultCounterpartyBankAccountServer(Object.Counterparty, Object.BankAccount);
	CashServer.CheckFillInOrganizationSBankAccountByOwner(Object.Organization,
		Object.BankAccount, , Object.LineOfBusiness, Object.ForeignCurrencyTransaction);
	CashServer.CheckOrganizationSSalesRegisterByOwner(Object.Organization, Object.CashAccount, Object.PaymentMethod, Object.LineOfBusiness, Object.Courier);
	
	CalculateOrderTotals(ThisForm);
	
	FillOperationSelectionList(False);
	FillInFinancialAccountingGroup();
	UpdateAvailabilityOfReturnContainerItems(ThisForm);

	AttributesArray = New Array;
	AttributesArray.Add("Contract");
	AttributesArray.Add("Terms");
	ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisObject, AttributesArray);
	
	ResponsiblePersonsServer.FillInManagerSelectionList_(Items.Manager, Object);
	ResponsiblePersonsServer.InstallManager(Object, Object.DocumentBasis);
	
	If Object.BusinessOperation = Enums.BusinessTransactions.TransferToCommissionAgent Then
		FillInDefaultContract();
	Else
		FillInSubordinatePropertiesForStatistics("Contract");
	EndIf;
	
	ResponsiblePersonsServer.WhenChangingRelatedDocumentDetails(Object);
	
	DefaultSecurityOption = DefaultSecurityOption();
	SecurityOptionAndFlagSeparately = SalesServer.ProvisionOptionAndFlagAreSeparateByDefault(
		Object.Terms,
		Object.Status,
		DefaultSecurityOption,
		Not Object.ThisIsOrderAsInvoice);
	
	If UseLinesOfBusiness Then
		LinesOfBusinessServer.FillInDefaultDirection(Object.LineOfBusiness, Object.Terms, Object.Contract);
	EndIf;
	LinesOfBusinessServer.WhenChangingDirectionOfActivity(ThisObject);
	
	PrepareAndSetVisibilityForAssemblyAndDelivery();
	ProvisionInDocumentsServer.WhenChangingDocumentDetails(ThisObject);
	
	UpdateDeliveryPlanningView();
	

	Return PricesCalculated_;
	
EndFunction

&AtServer
Procedure TermsClearingServer()
	
	ResponsiblePersonsServer.FillInManagerSelectionList_(Items.Manager, Object);
	ResponsiblePersonsServer.InstallManager(Object, Object.DocumentBasis);
	UpdateDeliveryPlanningView();
	
EndProcedure

&AtServer
Procedure CurrencyOnChangeServer(NewCurrency, RecalculateAmounts = True)
	
	FillInDefaultContract();
	Object.BankAccount = GetOrganizationSDefaultBankAccountServer();
	
	If RecalculateAmounts Then
		OldCurrency                = DocumentCurrency;
		DocumentDate               = ?(ValueIsFilled(Object.Date), Object.Date, CurrentSessionDate());
		LocalAccountingCurrency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Object.Organization);
		CourseStructures = ARAPAccountingServer.ExchangeRatesForTranslation(ThisForm, OldCurrency, NewCurrency, LocalAccountingCurrency, DocumentDate);
		StructureOfOldCurrencyRates = CourseStructures.StructureOfOldCurrencyRates;
		StructureOfNewCurrencyRates  = CourseStructures.StructureOfNewCurrencyRates;
		
		PriceManagementSystem.ConvertTabularAmountsToCurrency(
			Object.Goods,
			Object.PriceIncludesVAT,
			OldCurrency,
			NewCurrency,
			StructureOfOldCurrencyRates,
			StructureOfNewCurrencyRates,
			True,
			True);
		
		TMCommonUse.FillInDuplicateDependentPropsInCollection(Object.Goods, DependentDetails());
		
		CalculateOrderTotals(ThisForm);
		
		PriceManagementSystem.DistributeAmountByPaymentStages(Object, AmountOrdered, PackageDepositValue);
	EndIf;
	
	FillInSubordinatePropertiesForStatistics("Currency");
	
	ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisObject, "Currency");
	
EndProcedure

&AtServer
Procedure VATTaxationOnChangeServer(CachedValues = Undefined)
	
	AdjustVATRates();
	
	UpdateDuplicateDependentDetails();
	
	CalculateOrderTotals(ThisForm);

	VATAccountingERP.SetVisibilityOfCommandAndFillInVATRate(ThisObject);

EndProcedure

&AtServer
Procedure PriceIncludesVATOnChangeServer(CachedValues)
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForRecalculatingNDSWTCHAmount(Object);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	BatchProcessingOfTablePartServer.TreatTS(Object.Goods, StructureOfActions, CachedValues);
	UpdateDuplicateDependentDetails();
	
	CalculateOrderTotals(ThisForm);
	
	If Not ToUseTermsOfSales Then
		PriceTypeSelectionParameters = SettingsValueCached.ParametersForSelectingDefaultPriceType();
	
		PriceTypeSelectionParameters.PriceIncludesVAT        = Object.PriceIncludesVAT;
		PriceTypeSelectionParameters.UseWhileSellingToCustomers = True;
		PriceTypeSelectionParameters.Status                 = Enums.StatusesOfPriceTypeValidity.Valid;
		
		DefaultPriceType = SettingsValueCached.DefaultPriceType(PriceTypeSelectionParameters);
	EndIf;
	
EndProcedure

&AtServer
Procedure OrganizationOnChangeServer()
	
	SalesServer.SetContractAvailability(Object, Items.Contract.Enabled, Items.Contract.Visible, Object.Contract);
	
	If ValueIsFilled(Object.Organization) Then
		
		If Not ValueIsFilled(Object.Currency) Then
			Object.Currency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Object.Organization);
		EndIf;
		
		FillInDefaultContract();
		
		If UseLinesOfBusiness Then
			LinesOfBusinessServer.FillInDefaultDirection(Object.LineOfBusiness, Object.Terms, Object.Contract);
		EndIf;
		
		FillInSalesVATTaxation();
		VATTaxationOnChangeServer();
		
	EndIf;
	
	CashServer.CheckFillInOrganizationSBankAccountByOwner(Object.Organization,
		Object.BankAccount, , Object.LineOfBusiness, Object.ForeignCurrencyTransaction);
	CashServer.CheckOrganizationSSalesRegisterByOwner(Object.Organization, Object.CashAccount, Object.PaymentMethod, Object.LineOfBusiness, Object.Courier);
	
	FillInSubordinatePropertiesForStatistics("Organization");
	ResponsiblePersonsServer.InstallManager(Object, Object.DocumentBasis);
	
	ResponsiblePersonsServer.WhenChangingRelatedDocumentDetails(Object);
	LinesOfBusinessServer.WhenChangingDirectionOfActivity(ThisObject);
	ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisObject, "Organization");
	
	WhenChangingKeyDetailsStatusOfEDO();
	ProvisionInDocumentsServer.WhenChangingDocumentDetails(ThisObject);
	
	If Object.Organization = Catalogs.Companies.ManagementCompany Then
		Object.DeliveryIsRequired = False;
	EndIf;
	SetAvailabilityVisibilityOfDeliveryItems(ThisObject);
	
	
EndProcedure

&AtServer
Procedure WarehouseOnChangeServer()
	
	WarehouseGroup_ = Catalogs.Warehouses.ThisGroupAndWarehousesAreUsedByWHForSales(Object.Warehouse);
	WarehousesServer.FillInWarehousesInTablePart(Object.Warehouse, WarehouseGroup_, Object.Goods, False);
	
	SetParametersForSelectingProductsWarehouse();
	
	Items.GoodsFillInTheWarehouseInSelectedLines.Enabled = WarehouseGroup_;
	
	PrepareFillSetSeriesVisibility();
	
	PrepareAndSetVisibilityForAssemblyAndDelivery();
	
	FillInSalesVATTaxation();
	VATTaxationOnChangeServer();
	
	If Not WarehouseGroup_ Then
		Items.ProductsGroupSender.Title = NStr("vi = 'Bộ phận gửi';
												|ru = 'Подразделение-отправитель';
												|en = 'Shipping business unit'; fa = 'واحد تجاری ارسال‌کننده';
												|it = 'Unità-mittente';
												|pl = 'Shipping business unit';
												|tr = 'Gönderen departman'");
	Else
		Items.ProductsGroupSender.Title = NStr("vi = 'Người gửi';
												|ru = 'Отправитель';
												|en = 'Sender'; fa = 'فرستنده';
												|it = 'Mittente';
												|pl = 'Sender';
												|tr = 'Gönderen'");
	EndIf;
	
	WhenChangingWarehouseInTablePartServer();
	ProvisionInDocumentsServer.WhenChangingDocumentDetails(ThisObject);
	
EndProcedure

&AtServer
Procedure WhenChangingWarehouseInTablePartServer()
	
	WarehousesServer.WhenChangingWarehouseInTablePart(Object.Goods, WarehouseTable, WarehouseGroup_);
	TotalWarehouses_ = WarehouseTable.Count();
	WarehousesClientServer.UpdateWarehouseGroupImage(
		SeveralWarehousesText, 
		Items.PictureMultipleWarehouses, 
		TotalWarehouses_);
	
EndProcedure

&AtServer
Procedure StatusOnChangeServer()
	
	DefaultSecurityOption = DefaultSecurityOption();
	SecurityOptionAndFlagSeparately = SalesServer.ProvisionOptionAndFlagAreSeparateByDefault(
		Object.Terms,
		Object.Status,
		DefaultSecurityOption,
		Not Object.ThisIsOrderAsInvoice);
		
	If Not UseShipmentByRowsInSalesOrder Then
		
		StructureOfActions = New Structure();
		AddCollateralActionsOnServer(StructureOfActions, "SupplyOption");
		
		BatchProcessingOfTablePartServer.TreatTS(Object.Goods, StructureOfActions, Undefined);
		
		ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);
		
	EndIf;
	
	FillInServiceDetailsOfDocumentForm();
	SetAvailabilityOfItemsByStatusServer();
	
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	
EndProcedure

&AtServer
Procedure BusinessOperationOnChangeServer(ChallengeByCommand=True)
	
	ContractBusinessTransaction = GetBusinessTransaction(Object.BusinessOperation);
	If ChallengeByCommand Then
		FillInDefaultContract();
	EndIf;
	
	TransferOperations_ = SalesServer.GoodsTransferOperations();
	
	DefaultSecurityOption = DefaultSecurityOption();
	SecurityOptionAndFlagSeparately = SalesServer.ProvisionOptionAndFlagAreSeparateByDefault(
		Object.Terms,
		Object.Status,
		DefaultSecurityOption,
		Not Object.ThisIsOrderAsInvoice);
	
	AttachableCommandsClientServer.UpdateCommands(ThisForm, Object);
	
	If TransferOperations_.Find(Object.BusinessOperation) <> Undefined Then
		
		If (UseDiscountAdjustmentsInSales Or UseDiscountsMarkupsInSales)Then
			
			For Each TSRow In Object.Goods Do
				TSRow.AmountOfBonusPointsToDeduction = 0;
				TSRow.AmountOfBonusPointsToDeductionInCurrency = 0;
			EndDo;
		
			DiscountsMarkupsFillingServer.CancelDiscounts(Object, "Goods", True);
			DiscountsMarkupsFillingServer.ConfigureShowMessagesCommand(Object, Items.ShowMessages, False);
			
		EndIf;
		
		If Object.BusinessOperation = Enums.BusinessTransactions.TransferToStorageWithRightOfSale Then
			Object.VATTaxation = Enums.VATTaxationTypes.SaleIsNotSubjectToVAT;
			Object.PriceIncludesVAT = False;
		EndIf;
		
		If Object.PackageDepositIsRequired Then
			Object.PackageDepositIsRequired = False;
		EndIf;
		
		If ToUseTermsOfSales
			And (Object.BusinessOperation = Enums.BusinessTransactions.TransferToStorageWithRightOfSale
			Or Object.BusinessOperation = Enums.BusinessTransactions.DeliveryForPrincipal
			Or Object.BusinessOperation = Enums.BusinessTransactions.TransferToCommissionAgent)
			And ValueIsFilled(Object.Terms) Then
				SalesTermsAndConditions = SalesServer.GetTermsAndConditionsOfSale(Object.Terms, True);
				If SalesTermsAndConditions.BusinessOperation <> Object.BusinessOperation Then
					Object.Terms = Undefined;
				EndIf;
		EndIf;
		
		If Object.BusinessOperation = Enums.BusinessTransactions.DeliveryForPrincipal Then
			For Each RowGoods In Object.Goods Do
				RowGoods.WithAssignment = True;
				RowGoods.Department = Catalogs.BusinessStructure.EmptyRef();
			EndDo;
		EndIf;
		
	EndIf;
	
	ConsignmentSales25 = Object.BusinessOperation = Enums.BusinessTransactions.TransferToCommissionAgent
		And (Not ToUseTermsOfSales Or SalesServer.ThisIsAgreementOnNewCommission(Object.Terms));
	
	UseContracts =
		Object.BusinessOperation = Enums.BusinessTransactions.TransferToStorageWithRightOfSale
		Or Object.BusinessOperation = Enums.BusinessTransactions.DeliveryForPrincipal
		Or (ConsignmentSales25 And Object.BusinessOperation = Enums.BusinessTransactions.TransferToCommissionAgent);
	SalesServer.SetBlankContractMark(Items, "Contract", UseContracts);
	
	If ((Object.BusinessOperation = Enums.BusinessTransactions.TransferToCommissionAgent
		And ConsignmentSales25)
		Or Object.BusinessOperation = Enums.BusinessTransactions.TransferToStorageWithRightOfSale)
		And Object.ToReturnReusablePackage Then
		
		Object.ToReturnReusablePackage = False;
		Object.PackageDepositIsRequired = False;
		
		UpdateAvailabilityOfReturnContainerItems(ThisForm);
		
	EndIf;
	
	If ChallengeByCommand Then
		FillInSalesVATTaxation();
		VATTaxationOnChangeServer();
	EndIf;
	
	FillInServiceDetailsForProductRange();
	
	FillInServiceDetailsOfDocumentForm();
	ProvisionInDocumentsServer.WhenChangingDocumentDetails(ThisObject);
	
	UpdateDuplicateDependentDetails();
	CalculateOrderTotals(ThisForm);
	SetVisibilityOfElementsByOperationServer();
	
	ARAPAccountingFormWork.WhenChangingParametersOfMechanism(ThisForm);
	
	SetSoftwareVisibility();
	
	DeliveryIsApplicable = GoodsDeliveryClientServer.BusinessTransactionIsInvolvedInDelivery(Object.BusinessOperation);
	If Not DeliveryIsApplicable
		Or Object.Organization = Catalogs.Companies.ManagementCompany Then
		
		Object.DeliveryIsRequired = False;
		
	EndIf;
	SetAvailabilityVisibilityOfDeliveryItems(ThisObject);
	
EndProcedure

&AtServer
Function DateOnChangeServer(RecalculatePrices_2)
	
	If RecalculatePrices_2 Then
		PricesCalculated = FillThePricesByTermsOfSalesServer(True);
	Else
		PricesCalculated = False;
	EndIf;

	ResponsiblePersonsServer.WhenChangingRelatedDocumentDetails(Object);
	
	FillInSalesVATTaxation();
	
	PrepareAndSetVisibilityForAssemblyAndDelivery();
	ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisObject, "Date");
	FormEvents.WhenChangingElement(ThisObject, "Date");
	WhenChangingElementLocalization(ThisObject, "Date");
	
	RetailSalesClientServer.SetAvailabilityOfBonusPointsPaymentTeams(Items, Object.Date);
	
	CheckCorrectAvailabilityOfDiscountsPaymentsWithBonusPointsLocalization();
	
	Return PricesCalculated;
	
EndFunction

&AtServer
Procedure LineOfBusinessOnChangeServer()
	
	If Object.ARAPObjectSettings = Enums.ARAPObjectSettings.ByCounterpartyContracts Then
		
		FillInDefaultContract();
		
	EndIf;
	
	FillInSalesVATTaxation();
	VATTaxationOnChangeServer();
	
	LinesOfBusinessServer.WhenChangingDirectionOfActivity(ThisObject);
	ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisObject, "LineOfBusiness");
	ProvisionInDocumentsServer.WhenChangingDocumentDetails(ThisObject);
	
EndProcedure

&AtServer
Procedure CourierForChangesOnServer()
	
	CashServer.CheckOrganizationSSalesRegisterByOwner(Object.Organization, Object.CashAccount, Object.PaymentMethod, Object.LineOfBusiness, Object.Courier);
	
EndProcedure

&AtServer
Procedure ApprovalDateForChangesOnServer()
	ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisObject, "ApprovalDate");
EndProcedure

#EndRegion

#Region PricingAndDiscounts

&AtServer
Function FillThePricesByTermsOfSalesServer(OnAllLines = False, ErrorText = "")
	
	If OnAllLines Then
		RowsArray = Undefined;
	Else
		RowsArray = New Array;
		For Each String In Items.Goods.SelectedRows Do
			RowsArray.Add(Object.Goods.FindByID(String));
		EndDo;
	EndIf;
	
	SetsServerCall.AddToFullSet(Object.Goods, RowsArray);
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateAmount");
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountOfManualDiscount");
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountManualDiscount", New Structure("Clear", False));
	StructureOfActions.Insert("ClearAutomaticDiscount");
	StructureOfActions.Insert("FillInVATRateByPriceType", BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRateByPriceType(Object, True));
	
	FillParameters = New Structure();
	FillParameters.Insert("Date", Object.Date);
	FillParameters.Insert("Currency", Object.Currency);
	FillParameters.Insert("Partner", Object.Partner);
	If ThisIsContractForNewCommission(Object.Contract, Object.BusinessOperation) Then
			AccountingTypeOfContractPrice = ConsignmentSalesServer.TypeOfContractPrice(Object.Contract, True);
			FillParameters.Insert("PriceKind", AccountingTypeOfContractPrice);
	Else
		FillParameters.Insert("Terms", Object.Terms);
		If Common.ObjectAttributeValue(Object.Terms, "PriceIncludesVAT") <> Object.PriceIncludesVAT Then
			ErrorText = 
			NStr("vi = 'Các giá trị đã đặt cho trường ""Đơn giá gồm thuế GTGT"" trong chứng từ và thỏa thuận là khác nhau.';
				|ru = 'Установленные значения полей ""Цена включает НДС"" в документе и соглашении разные.';
				|en = 'Set values of the ""Price includes VAT"" fields in the document and agreement are different.'; fa = 'Set values of the ""Price includes VAT"" fields in the document and agreement are different.';
				|it = 'I valori impostati dei campi ""Prezzo IVA inclusa"" nel documento e nell''accordo differiscono.';
				|pl = 'Ustawione wartości pól ""Cena brutto"" w dokumencie i umową są różne.';
				|tr = 'Belgedeki ve sözleşmedeki ""KDV dahildir"" alanlarının hesaplanan değerleri farklıdır.'");
			Return False;
		EndIf;
	EndIf;
	FillParameters.Insert("Organization", Object.Organization);
	FillParameters.Insert("CalculateSets", True);
	FillParameters.Insert("VATTaxation", Object.VATTaxation);
	FillParameters.Insert("ReturnReusablePackage", Object.ToReturnReusablePackage);
	FillParameters.Insert("PopulationFields", "Price, PriceKind, DeliveryPeriodDays");
	
	PricesCalculated = EnterprisePricesFillingServer.FillInPrices(
		Object.Goods,
		RowsArray, // Array of rows or selection structure
		FillParameters,
		StructureOfActions);
		
	TMCommonUse.FillInDuplicateDependentPropsInCollection(Object.Goods, DependentDetails());
	CalculateOrderTotals(ThisForm);
	
	Return PricesCalculated;
	
EndFunction

&AtServer
Function FillInPricesOfSelectedRowsByPriceTypeServer(PricesKind)
	
	RowsArray = New Array;
	For Each String In Items.Goods.SelectedRows Do
		RowsArray.Add(Object.Goods.FindByID(String));
	EndDo;
	
	SetsServerCall.AddToFullSet(Object.Goods, RowsArray);
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateAmount");
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountOfManualDiscount");
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountManualDiscount", New Structure("Clear", False));
	StructureOfActions.Insert("ClearAutomaticDiscount");
	StructureOfActions.Insert("FillInVATRateByPriceType", BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRateByPriceType(Object, True));
	
	FillParameters = New Structure();
	FillParameters.Insert("Date", Object.Date);
	FillParameters.Insert("Organization", Object.Organization);
	FillParameters.Insert("Currency", Object.Currency);
	FillParameters.Insert("PriceKind", PricesKind);
	FillParameters.Insert("CalculateSets", True);
	FillParameters.Insert("PopulationFields", "Price, PriceKind");
	
	PricesCalculated = EnterprisePricesFillingServer.FillInPrices(
		Object.Goods,
		RowsArray, // Array of rows or selection structure
		FillParameters,
		StructureOfActions);
	
	TMCommonUse.FillInDuplicateDependentPropsInCollection(Object.Goods, DependentDetails());
	
	CalculateOrderTotals(ThisForm);
	
	Return PricesCalculated;
	
EndFunction

&AtServer
Procedure CalculateDiscountsWithoutApplyingToObject()
	
	ParametersStructure1 = DiscountsMarkupsFillingServer.NewParametersCalculate();
	ParametersStructure1.ApplyToObject				 = False;
	ParametersStructure1.OnlyPreliminaryCalculation		 = False;
	ParametersStructure1.RestoreManagedDiscounts	 = True;
	ParametersStructure1.ManagedDiscounts				 = ManagedDiscounts;
	
	AppliedDiscounts = DiscountsMarkupsFillingServer.Calculate(Object, ParametersStructure1);
	AddressOfAppliedDiscountsInTheTemporaryStorage = PutToTempStorage(AppliedDiscounts, UUID);
	
EndProcedure

&AtServer
Function CalculateDiscountsMarginsOnServer(ParametersStructure1, TakeFromTemporaryStorage = False)
	
	If TakeFromTemporaryStorage Then
		AppliedDiscounts = GetFromTempStorage(AddressOfAppliedDiscountsInTheTemporaryStorage);
		DiscountsMarkupsFillingServer.ApplyCalculationResult(Object, AppliedDiscounts);
	Else
		AppliedDiscounts = DiscountsMarkupsFillingServer.Calculate(Object, ParametersStructure1);
		AddressOfAppliedDiscountsInTheTemporaryStorage = PutToTempStorage(AppliedDiscounts, UUID);
	EndIf;

	Object.DiscountsAreCalculated = True;
	UpdateDuplicateDependentDetails();
	
	CalculateOrderTotals(ThisForm);
	
	TheStructureOfTheMessages = DiscountsMarkupsFillingServer.TheStructureOfTheMessages(Object);
	DiscountsMarkupsFillingServer.ConfigureShowMessagesCommand(Object, Items.ShowMessages);
	
	Return TheStructureOfTheMessages;
	
EndFunction

&AtServer
Procedure AssignManualDiscountOnServer(AmountOfDiscountMarkUp, Val SelectedRows, AddressInTempStorage)
	
	DiscountParameters = DiscountsMarkupsFillingServer.NewOptionsAssignManualDiscount();
	DiscountParameters.AutomaticDiscountsAreUsed = True;
	DiscountParameters.OnlyForActiveRows			 = False;
	DiscountParameters.CalculateAmountWithVAT			 = True;
	DiscountParameters.SelectedRows				 = SelectedRows;
	DiscountParameters.AddressInTempStorage		 = AddressInTempStorage;
	
	AddDiscountParametersLocalization(DiscountParameters);
	
	DiscountsMarkupsFillingServer.AssignAManualDiscount(Object, "Goods", AmountOfDiscountMarkUp, DiscountParameters);
	UpdateDuplicateDependentDetails();
	
EndProcedure

&AtServer
Function PerformPreliminaryCalculationOfDiscountsOnServer()
	
	ParametersStructure1 = DiscountsMarkupsFillingServer.NewParametersCalculate();
	ParametersStructure1.ApplyToObject = False;
	ParametersStructure1.OnlyPreliminaryCalculation = True;
	ParametersStructure1.RestoreManagedDiscounts = True;
	ParametersStructure1.ManagedDiscounts = ManagedDiscounts;
	
	Return PutToTempStorage(
			DiscountsMarkupsFillingServer.Calculate(Object, ParametersStructure1), UUID);
	
EndFunction

&AtServer
Procedure CancelManualDiscountsOnServer()
	
	DiscountsMarkupsFillingServer.CancelManualDiscounts(Object, "Goods", True, True);
	UpdateDuplicateDependentDetails();
	
EndProcedure

&AtClient
Procedure CalculateDiscountsMarkupsClient()
	
	ParametersStructure1 = New Structure;
	ParametersStructure1.Insert("ApplyToObject",                True);
	ParametersStructure1.Insert("OnlyPreliminaryCalculation",      False);
	ParametersStructure1.Insert("RestoreManagedDiscounts", True);
	ParametersStructure1.Insert("ManagedDiscounts", ManagedDiscounts);
	
	TheStructureOfTheMessages = CalculateDiscountsMarginsOnServer(ParametersStructure1);
	If TheStructureOfTheMessages.Messages.Count() > 0 And TheStructureOfTheMessages.AutomaticallyOpen Then
		OpenForm("CommonForm.MessagesOfDiscountsMarkups", TheStructureOfTheMessages, ThisForm, UUID);
	EndIf;
	
	ShowUserNotification(
		NStr("vi = 'Chiết khấu (phụ thu)';
			|ru = 'Скидки (наценки)';
			|en = 'Discounts (markups)'; fa = 'تخفیف‌ها (افزایش قیمت‌ها)';
			|it = 'Sconti (sovrapprezzo)';
			|pl = 'Rabaty (marże)';
			|tr = 'İndirim (marj)'"),
		,
		NStr("vi = 'Đã tính chiết khấu (phụ thu)';
			|ru = 'Скидки (наценки) рассчитаны';
			|en = 'Discounts (markups) are calculated'; fa = 'Discounts (markups) are calculated';
			|it = 'Sconti (sovrapprezzi) sono calcolati';
			|pl = 'Rabaty (marże) są obliczone';
			|tr = 'İndirim (marj) uygulandı'"),
		PictureLib.Information32);
	
EndProcedure

&AtClient
Procedure ApplyDiscountMarkUpChangesOnCustomer(Cancel)
	
	TheStructureOfTheMessages = CalculateDiscountsMarginsOnServer(Undefined, True);
	If TheStructureOfTheMessages.Messages.Count() > 0 And TheStructureOfTheMessages.AutomaticallyOpen Then
		OpenForm("CommonForm.MessagesOfDiscountsMarkups", TheStructureOfTheMessages, ThisForm, UUID);
		Cancel = True;
	EndIf;
	
	ShowUserNotification(
		NStr("vi = 'Chiết khấu (phụ thu)';
			|ru = 'Скидки (наценки)';
			|en = 'Discounts (markups)'; fa = 'تخفیف‌ها (افزایش قیمت‌ها)';
			|it = 'Sconti (sovrapprezzo)';
			|pl = 'Rabaty (marże)';
			|tr = 'İndirim (marj)'"),
		,
		NStr("vi = 'Đã tính chiết khấu (phụ thu)';
			|ru = 'Скидки (наценки) рассчитаны';
			|en = 'Discounts (markups) are calculated'; fa = 'Discounts (markups) are calculated';
			|it = 'Sconti (sovrapprezzi) sono calcolati';
			|pl = 'Rabaty (marże) są obliczone';
			|tr = 'İndirim (marj) uygulandı'"),
		PictureLib.Information32);
	
EndProcedure

&AtServer
Procedure MessagesReceived(Messages)
	
	DiscountsMarkupsFillingServer.SaveSpentMessages(Object, Messages);
	DiscountsMarkupsFillingServer.ConfigureShowMessagesCommand(Object, Items.ShowMessages);
	
EndProcedure

&AtServer
Function DiscountsHaveChanged()
	
	DiscountsHaveChanged = DiscountsMarkupsFillingServer.DiscountsMustBeRecalculated(
		Object, 
		ManagedDiscounts, 
		UUID, 
		AddressOfAppliedDiscountsInTheTemporaryStorage);
		
	If Object.Goods.Total("DiscountMarkupAmountWithoutReusablePackages") <> Object.DiscountsMarkups.Total("Sum") Then
		DiscountsHaveChanged = True;
	EndIf;

	Return DiscountsHaveChanged;
	
EndFunction

&AtClient
Procedure VerificationOfPaymentWithBonusPoints(CurrentRow)
	
	If (CurrentRow.AmountOfBonusPointsToDeduction = 0 
		And CurrentRow.AmountOfBonusPointsToDeductionInCurrency = 0) Then
	
		Return;
		
	EndIf;
	
	ClearMessages();
	ApplyPaymentWithBonusPointsClient(, True);
	
EndProcedure

&AtClient
Procedure ApplyPaymentWithBonusPointsClient(AddressInTempStorage = Undefined, DisplayMessage_ = False)
	
	If AddressInTempStorage = Undefined And (Not PaymentWithBonusPoints Or Not Object.Goods.Count()) Then
		Return;
	EndIf;
	
	ApplyPaymentWithBonusPoints(AddressInTempStorage, DisplayMessage_);
	
EndProcedure

&AtServer
Procedure ApplyPaymentWithBonusPoints(AddressInTempStorage = Undefined, DisplayMessage_ = False)
	
	DeletingPayment = False;
	If AddressInTempStorage <> Undefined Then
		TableOfGoods = GetFromTempStorage(AddressInTempStorage);
	Else
		If Not PaymentWithBonusPoints Then
			Return;
		EndIf;
		TableOfGoods = Object.Goods;
		DeletingPayment = True;
	EndIf;
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateAmount");
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountAutomaticDiscount", New Structure("Clear", False));
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountManualDiscount", New Structure("Clear, RecalculateAmountOfManualDiscount_", False, False));
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountDiscountWithBonusPoints");
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("FillInDuplicateDependentDetails", DependentDetails());
	
	AdjustmentIsCompleted = False;
	RowsToProcess = New Array;
	
	For Each TableRow In TableOfGoods Do
		
		If DeletingPayment Then
			TSRow = TableRow;
			If TableRow.AmountOfBonusPointsToDeduction = 0 
				And TableRow.AmountOfBonusPointsToDeductionInCurrency = 0 Then
				Continue;
			EndIf;
			TSRow.AmountOfBonusPointsToDeduction        = 0;
			TSRow.AmountOfBonusPointsToDeductionInCurrency = 0;
		Else
			TSRow = Object.Goods.FindRows(New Structure("ConnectionKey", TableRow.ConnectionKey))[0];
			TSRow.AmountOfBonusPointsToDeduction        = TableRow.AmountOfBonusPointsToDeduction;
			TSRow.AmountOfBonusPointsToDeductionInCurrency = TableRow.AmountOfBonusPointsToDeductionInCurrency;
		EndIf;
		
		RowsToProcess.Add(TSRow);
		
		AdjustmentIsCompleted = True;

	EndDo;

	BatchProcessingOfTablePartServer.ProcessTSStrings(
		RowsToProcess,
		StructureOfActions,
		Object.Goods);
	
	If AdjustmentIsCompleted Then
		
		PaymentWithBonusPoints = Not DeletingPayment;
		
		CalculateOrderTotals(ThisForm);
		
		If DisplayMessage_ Then
			If DeletingPayment Then
				MessageText = NStr("vi = 'Việc thanh toán bằng điểm thưởng bị hủy bỏ. Nếu cần, có thể ấn định lại việc thanh toán bằng điểm thưởng (""Đơn giá và chiết khấu / Thêm thanh toán bằng điểm thưởng"").';
									|ru = 'Оплата бонусными баллами отменена. При необходимости, оплату бонусными баллами можно назначить заново (""Цены и скидки / Добавить оплату бонусными баллами"").';
									|en = 'The payment with bonus points is canceled. If necessary, you can add the payment with bonus points again. To do it, go to ""Prices and discounts"" and select ""Add bonus point payment"".'; fa = 'The payment with bonus points is canceled. If necessary, you can add the payment with bonus points again. To do it, go to ""Prices and discounts"" and select ""Add bonus point payment"".';
									|it = 'The payment with bonus points is canceled. If necessary, you can add the payment with bonus points again. To do it, go to ""Prices and discounts"" and select ""Add bonus point payment"".';
									|pl = 'The payment with bonus points is canceled. If necessary, you can add the payment with bonus points again. To do it, go to ""Prices and discounts"" and select ""Add bonus point payment"".';
									|tr = 'Bonus puanlarla ödeme iptal edildi. Gerektiği takdirde, bonus puan ödemesi yeniden atanabilir (""Fiyatlar ve indirimler / Bonus puan ödemesi ekleyin"").'");
			Else
				MessageText = NStr("vi = 'Đã phân bổ thanh toán bằng điểm thưởng.';
									|ru = 'Оплата бонусными баллами распределена.';
									|en = 'Payment with bonus points is allocated.'; fa = 'Payment with bonus points is allocated.';
									|it = 'Оплата бонусными баллами распределена.';
									|pl = 'Payment with bonus points is allocated.';
									|tr = 'Bonus puanlarla ödeme tahsis edildi. '");
			EndIf;
			Common.MessageToUser(MessageText, Object.Ref);
		EndIf;
		
	EndIf;
	
EndProcedure

#EndRegion

#Region SelectionAndProcessingOfQuantityVerification

&AtServer
Procedure ProcessingSelectionOfSelectionOnServer(ValueSelected)
	
	TableOfGoods = GetFromTempStorage(ValueSelected.GoodsAddressInStorage);
	CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();

	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
	StructureOfActions.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));
	
	ParametersForFillingInVATRate = BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRate(Object, True);
	If Object.NotShipInInstallments And ValueIsFilled(Object.DateOfShipment) Then
		ParametersForFillingInVATRate.Date = Object.DateOfShipment;
	EndIf;
	
	StructureOfActions.Insert("FillInVATRate", ParametersForFillingInVATRate);
	StructureOfActions.Insert("FillInVATRateByPriceType", BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRateByPriceType(Object, True));
	StructureOfActions.Insert("FillInVATRateForReturnableContainers", Object.ToReturnReusablePackage);
	StructureOfActions.Insert("FillInNoReturnContainerAttribute", Object.ToReturnReusablePackage);
	StructureOfActions.Insert("FillInCanceledWithoutReturnableContainerAttribute", Object.ToReturnReusablePackage);
	StructureOfActions.Insert("FillInContent", BatchProcessingOfTablePartClientServer.GetStructureOfFillingInServiceContentInTSLine(Object, False));
	If Object.BusinessOperation <> Enums.BusinessTransactions.DeliveryForPrincipal Then
		StructureOfActions.Insert("FillInSubdivisionInTSLine", New Structure("Department", Object.Department));
	EndIf;
	
	AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions,Object);
	
	AddCollateralActionsOnServer(StructureOfActions, "WarehouseIsRequired,DateOfShipmentRequired_");
	
	BegOfDay = BegOfDay(CurrentSessionDate());
	
	FieldsForFillIn = "ProductsInSet, ItemVariantOfSet, Products, Characteristic, Package, Warehouse, DateOfShipment, 
		|PriceKind, Price, NumberOfPackages, Count, Sum, VATAmount, AmountIncludingVAT, ManualDiscount, PercentRateOfManualDiscount, 
		|DeliveryPeriodDays, SupplyOption, WithAssignment, Series";
	SearchFields = "ProductsInSet, ItemVariantOfSet, Products, Characteristic, Package, Warehouse, 
		|PriceKind, SupplyOption, WithAssignment, Series, Price";
	If Not Object.NotShipInInstallments Then
		SearchFields = SearchFields + ", DateOfShipment";
	EndIf;
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
		RowsToProcess.Add(CurrentRow);
		ShippingDates.Insert(CurrentRow, RowOfProduct.DateOfShipment);
		
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
	UpdateColumnAvailableServer();
	
	FillInServiceDetailsForProductRange();
	ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);
	
	WarehousesServer.WhenChangingWarehouseInTablePart(Object.Goods, WarehouseTable, WarehouseGroup_);
	TotalWarehouses_ = WarehouseTable.Count();
	WarehousesClientServer.UpdateWarehouseGroupImage(SeveralWarehousesText, Items.PictureMultipleWarehouses, TotalWarehouses_);
	
	CalculateOrderTotals(ThisForm);
	ReusablePackageServer.UpdateFillingStateOfMultiTurnContainer(Object.ReusablePackageFillingStatus);

EndProcedure

&AtClient
Procedure ReportErrorsWhenOpeningSelection(Cancel)
	
	If ToUseTermsOfSales And Not ValueIsFilled(Object.Terms) Then
		CommonClientServer.MessageToUser(NStr("vi = 'Chưa điền trường ""Thỏa thuận""';
												|ru = 'Поле ""Соглашение"" не заполнено';
												|en = '""Terms of sales"" are not filled'; fa = '""Terms of sales"" are not filled';
												|it = 'Il campo ""Accordo"" non è compilato';
												|pl = 'Pole ""Porozumienie"" nie jest wypełnione';
												|tr = '""Anlaşma"" alanı doldurulmamış'"), Object.Ref, "Object.Terms",,Cancel);
	EndIf;
	If Not ValueIsFilled(Object.Currency) Then
		CommonClientServer.MessageToUser(NStr("vi = 'Chưa điền trường ""Tiền tệ""';
												|ru = 'Поле ""Валюта"" не заполнено';
												|en = '""Currency"" is required'; fa = '""Currency"" is required';
												|it = 'Il campo ""Valuta"" non è compilato';
												|pl = 'Pole ""Waluta"" nie jest wypełnione';
												|tr = '""Para Birimi"" alanı doldurulmadı'"), Object.Ref, "Object.Currency",,Cancel);
	EndIf;
	If Not ValueIsFilled(Object.Warehouse) Then
		CommonClientServer.MessageToUser(NStr("vi = 'Chưa điền trường ""Kho bãi""';
												|ru = 'Поле ""Склад"" не заполнено';
												|en = '""Warehouse"" is required'; fa = '""Warehouse"" is required';
												|it = 'Il campo ""Magazzino"" non è compilato';
												|pl = 'Nie wypełniono pola ""Magazyn""';
												|tr = '""Ambar"" alanı doldurulmamış'"), Object.Ref, "Object.Warehouse",,Cancel);
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
	StructureOfActionsWithAddedStrings.Insert("CheckFillWarehouse", BatchProcessingOfTablePartClientServer.GetWarehouseFillStructureInTSLine(Object, WarehouseGroup_));
	
	ParametersForFillingInVATRate = BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRate(Object, True);
	If Object.NotShipInInstallments And ValueIsFilled(Object.DateOfShipment) Then
		ParametersForFillingInVATRate.Date = Object.DateOfShipment;
	EndIf;
	
	StructureOfActionsWithAddedStrings.Insert("FillInVATRate", ParametersForFillingInVATRate);
	StructureOfActionsWithAddedStrings.Insert("FillInVATRateByPriceType", BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRateByPriceType(Object, True));
	StructureOfActionsWithAddedStrings.Insert("FillInVATRateForReturnableContainers", Object.ToReturnReusablePackage);
	StructureOfActionsWithAddedStrings.Insert("FillInNoReturnContainerAttribute", Object.ToReturnReusablePackage);
	StructureOfActionsWithAddedStrings.Insert("FillInCanceledWithoutReturnableContainerAttribute", Object.ToReturnReusablePackage);
	StructureOfActionsWithAddedStrings.Insert("FillInFeatureAttribute", New Structure("Products", "ItemVariantsAreUsed"));
	StructureOfActionsWithAddedStrings.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
	StructureOfActionsWithAddedStrings.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));
	StructureOfActionsWithAddedStrings.Insert("FillInSalesOptionAttribute", New Structure("Products", "SaleRegistrationOption"));
	StructureOfActionsWithAddedStrings.Insert("FillInContent", BatchProcessingOfTablePartClientServer.GetStructureOfFillingInServiceContentInTSLine(Object, False));
	StructureOfActionsWithAddedStrings.Insert("CheckSeriesCalculateStatus", New Structure("Warehouse, SeriesSpecificationParameters", Object.Warehouse, SeriesSpecificationParameters));
	AddPriceFillingAction(StructureOfActionsWithAddedStrings);
	If Object.BusinessOperation <> PredefinedValue("Enum.BusinessTransactions.DeliveryForPrincipal") Then
		StructureOfActionsWithAddedStrings.Insert("FillInSubdivisionInTSLine", New Structure("Department", Object.Department));
	EndIf;
	AddActionsToStructureWhenChangingPackagesNumber(StructureOfActionsWithAddedStrings,Object);
	
	StructureOfActionsWithModifiedStrings = New Structure;
	
	AddActionsToStructureWhenChangingPackagesNumber(StructureOfActionsWithModifiedStrings,Object);
	
	If Not ToUseTermsOfSales Then
		StructureOfActionsWithAddedStrings.Insert("FillInPriceView", New Structure("PriceKind", DefaultPriceType));
	EndIf;
	
	StructureOfActions = BarcodingOfItemsClient.BarcodeProcessingParameters();
	StructureOfActions.Barcodes                              = BarcodeData_5;
	StructureOfActions.StructureOfActionsWithAddedStrings = StructureOfActionsWithAddedStrings;
	StructureOfActions.StructureOfActionsWithModifiedStrings  = StructureOfActionsWithModifiedStrings;
	StructureOfActions.SeriesSpecificationParameters                 = SeriesSpecificationParameters;
	StructureOfActions.CalculateSets                     = True;
	If Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.TransferToCommissionAgent") Then
		StructureOfActions.GoodsOnly                       = True;
	EndIf;
	
	ProcessBarcodesServer(StructureOfActions, CachedValues);
	
	BarcodingOfItemsClient.ProcessUnknownBarcodes(StructureOfActions, CachedValues, ThisObject);
	
	If BarcodingOfItemsClient.YouNeedToOpenFormForSpecifyingSeriesAfterProcessingBarcodes(StructureOfActions) Then
		CurDataId = StructureOfActions.ArrayOfRowsWithSeries_[0];
		
		AttachIdleHandler("OpenSeriesSelectionWhenScanningProductBarCode", 0.1, True);
	EndIf;

	CalculateOrderTotals(ThisObject);
	DiscountsMarkupsFillingClient.ResetDiscountsCalculatedFlag(ThisObject);
	
	If StructureOfActions.CurrentRow <> Undefined Then
		Items.Goods.CurrentRow = StructureOfActions.CurrentRow;
	EndIf;
	
EndProcedure

&AtServer
Procedure ProcessBarcodesServer(StructureOfActionParameters, CachedValues)
	
	ApplyPaymentWithBonusPoints(, True);
	
	AddCollateralActionsOnServer(
		StructureOfActionParameters.StructureOfActionsWithAddedStrings,
		"SupplyOption,WarehouseIsRequired,DateOfShipmentRequired_");
	
	BarcodingOfItemsServer.ProcessBarcodes(ThisObject, Object, StructureOfActionParameters, CachedValues);
	WarehousesServer.WhenChangingWarehouseInTablePart(Object.Goods, WarehouseTable, WarehouseGroup_);
	TotalWarehouses_ = WarehouseTable.Count();
	WarehousesClientServer.UpdateWarehouseGroupImage(SeveralWarehousesText, Items.PictureMultipleWarehouses, TotalWarehouses_);
	ProvisionInDocumentsClientServer.RemoveCollateralActions(StructureOfActionParameters.StructureOfActionsWithAddedStrings);
	UpdateColumnAvailableServer();
	
	ProvisionInDocumentsClientServer.FillInServiceDetails(Object.Goods, DateOfShipmentRequired_, WarehouseIsRequired);
	
EndProcedure

#EndRegion

#Region SetOfSeries

&AtServer
Procedure FillInStatusesForSpecifyingSeries()
	
	ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);
	
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

#Region WorkingWithClipboard

&AtServer
Procedure CopyLinesOnServer()
	
	ProcessingOfTabularForms.CopyRowsToClipboard(Object.Goods, Items.Goods.SelectedRows);
	
EndProcedure

&AtServer
Procedure GetLinesFromClipboard()
	
	If SalesServer.GoodsTransferOperations().Find(Object.BusinessOperation) <> Undefined Then
		FilterParameters = New Map;
		If Object.BusinessOperation = Enums.BusinessTransactions.DeliveryForPrincipal Then
			FilterParameters.Insert("Products.ItemsType", ProductsClientServer.SelectionByProductReusablePackagingWork());
		Else
			FilterParameters.Insert("Products.ItemsType", ProductsClientServer.SelectionByProductMultiTurnContainer());
		EndIf;
	Else
		FilterParameters = Undefined;
	EndIf;
	
	Columns = "Products,Characteristic,Package,NumberOfPackages,PriceKind,Price,
		|PercentRateOfManualDiscount,ManualDiscount,Warehouse,DateOfShipment,Department,ProductsInSet,ItemVariantOfSet";
	
	TableOfGoods = ProcessingOfTabularForms.RowsFromClipboard(FilterParameters, Columns);
	
	If Not ValueIsFilled(TableOfGoods) Then
		Return;
	EndIf;
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
	StructureOfActions.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));
	StructureOfActions.Insert("CheckFillWarehouse",
		BatchProcessingOfTablePartClientServer.GetWarehouseFillStructureInTSLine(Object, WarehouseGroup_));
		
	StructureOfActions.Insert("FillInVATRate", BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRate(Object, True));
	StructureOfActions.Insert("FillInVATRateByPriceType", BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRateByPriceType(Object, True));
	StructureOfActions.Insert("FillInVATRateForReturnableContainers", Object.ToReturnReusablePackage);
	StructureOfActions.Insert("FillInNoReturnContainerAttribute", Object.ToReturnReusablePackage);
	StructureOfActions.Insert("FillInCanceledWithoutReturnableContainerAttribute", Object.ToReturnReusablePackage);
	StructureOfActions.Insert("FillInContent",
		BatchProcessingOfTablePartClientServer.GetStructureOfFillingInServiceContentInTSLine(Object, False));
		
	AddCollateralActionsOnServer(StructureOfActions,
		"SupplyOption,WarehouseIsRequired,DateOfShipmentRequired_");
	AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions,Object);
	
	If TableOfGoods.Columns.Find("ManualDiscount") <> Undefined Then
		StructureOfActions.RecalculateAmountTakingIntoAccountManualDiscount.Insert("RecalculateAmountOfManualDiscount_", False);
	EndIf;
	
	ParametersForFillingInPriceType = BatchProcessingOfTablePartClientServer.ParametersForFillingInPriceTypeInTSLine("PriceKind");
	ParametersForFillingInPriceType.FilterParameters.PriceIncludesVAT = Object.PriceIncludesVAT;
	ParametersForFillingInPriceType.FilterParameters.UseWhileSellingToCustomers = True;
	StructureOfActions.Insert("CheckFillInPriceView", ParametersForFillingInPriceType);
	
	StructureOfActions.Insert("FillInSalePrice",
		BatchProcessingOfTablePartClientServer.ParametersForFillingInPriceInTSLine(Object));
	
	RowsToProcess = New Array;
	
	For Each RowOfProduct In TableOfGoods Do
		
		CurrentRow = Object.Goods.Add();
		FillPropertyValues(CurrentRow, RowOfProduct);
		CurrentRow.SetIndex = ?(ValueIsFilled(CurrentRow.ProductsInSet), 1, 0);
		If Not UseDiscountAdjustmentsInSales Then
			CurrentRow.PercentRateOfManualDiscount = 0;
			CurrentRow.ManualDiscount = 0;
		EndIf;
		
		If Object.NotShipInInstallments Then
			CurrentRow.DateOfShipment = Object.DateOfShipment;
		EndIf;
		
		If Object.BusinessOperation = Enums.BusinessTransactions.DeliveryForPrincipal Then
			CurrentRow.Department = Catalogs.BusinessStructure.EmptyRef();
		EndIf;
		
		RowsToProcess.Add(CurrentRow);
			
	EndDo;
	
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		RowsToProcess,
		StructureOfActions,
		Object.Goods);
	
	FillInServiceDetailsForProductRange();
	
	ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);
	
	WarehousesServer.WhenChangingWarehouseInTablePart(Object.Goods, WarehouseTable, WarehouseGroup_);
	TotalWarehouses_ = WarehouseTable.Count();
	WarehousesClientServer.UpdateWarehouseGroupImage(SeveralWarehousesText, Items.PictureMultipleWarehouses, TotalWarehouses_);
	
	CalculateOrderTotals(ThisForm);
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

#Region Delivery

&AtClient
Procedure OpenDeliverySettings()
	
	LockFormDataForEdit();
	
	DeliverySettings = GenerateDeliveryParameterSettings();
	
	FormParameters = New Structure;
	FormParameters.Insert("DeliverySettings", DeliverySettings);
	FormParameters.Insert("ReadOnly", ReadOnly);
	
	CompletionDetails = New CallbackDescription("ProcessDeliveryParameterSettings", ThisObject);
	GoodsDeliveryClient.OpenDeliverySettingsForm(FormParameters, CompletionDetails);
	
EndProcedure

&AtServer
Function GenerateDeliveryParameterSettings()
	
	ThereIsSupportForDeliveryByYourOwnCouriers = WarehousesServer.ThereIsSupportForDeliveryByYourOwnCouriers(
		Object.Warehouse, Object.DateOfShipment);
	
	ShippingMethodsUsed = New Array; // Array of EnumRef.TransportMethods25
	ShippingMethodsUsed.Add(Enums.TransportMethods25.SelfPickup);
	ShippingMethodsUsed.Add(Enums.TransportMethods25.OwnDelivery);
	ShippingMethodsUsed.Add(Enums.TransportMethods25.ByCarrier);
	ShippingMethodsUsed.Add(Enums.TransportMethods25.DefinedByDeliveryService);
	If ThereIsSupportForDeliveryByYourOwnCouriers Then
		ShippingMethodsUsed.Add(Enums.TransportMethods25.OurCourier);
	EndIf;
	
	OrdersServer.SetKeyInRowsOfTablePart(Object, "Goods");
	
	DeliverySettings = GoodsDeliveryClientServer.NewDeliverySettings();
	DeliverySettings.DeliveryPlanning = Object.DeliveryPlanning;
	DeliverySettings.DeliverySpecificationMethod = Object.DeliverySpecificationMethod;
	DeliverySettings.DeliveryMethod = Object.DeliveryMethod25;
	DeliverySettings.ShippingMethodsUsed = ShippingMethodsUsed;
	DeliverySettings.SingleShipmentDateIsUsed = Object.NotShipInInstallments;
	
	DeliverySettings.Partner = Object.Partner;
	DeliverySettings.DeliveryPoint = Object.DeliveryPoint;
	DeliverySettings.DeliveryZone = Object.DeliveryZone;
	
	DeliverySettings.Courier = Object.Courier;
	
	DeliverySettings.DeliveryToCarrier = Object.DeliveryToCarrier;
	DeliverySettings.Carrier = Object.CarrierPartner;
	DeliverySettings.CarrierDeliveryPoint = Object.CarrierDeliveryPoint;
	DeliverySettings.CarrierSDeliveryArea = Object.CarrierSDeliveryArea;
	
	DeliverySettings.DeliveryTimeFrom = Object.DeliveryTimeFrom;
	DeliverySettings.DeliveryTimeTo = Object.DeliveryTimeTo;
	
	DeliverySettings.AdditionalDeliveryInformation = Object.AdditionalDeliveryInformation;
	DeliverySettings.SpecialTransportationConditions = Object.SpecialTransportationConditions;
	DeliverySettings.SpecialTransportationConditionsDescription = Object.SpecialTransportationConditionsDescription;
	
	GoodsFieldNames = "LineNumber, RowCode, Products, Characteristic, ItemVariantsAreUsed, Series, BatchesIndicationStatus, NumberOfPackages, Package, Warehouse, DateOfShipment";
	SearchParameters = New Structure;
	SearchParameters.Insert("Canceled", False);
	SearchParameters.Insert("ItemsType", Enums.ItemsTypes.OwnGoods);
	TableOfGoods = Object.Goods.Unload(SearchParameters, GoodsFieldNames);
	DeliveryTable = Object.GoodsToDeliver.Unload();
	WarehouseInformationTable = Object.WarehousesDeliveryInformation.Unload();
	
	Query = New Query;
	#Region QueryText
	QueryText =
	"SELECT
	|	TableOfGoods.LineNumber AS LineNumber,
	|	TableOfGoods.RowCode AS RowCode,
	|	TableOfGoods.Products AS Products,
	|	TableOfGoods.Characteristic AS Characteristic,
	|	TableOfGoods.ItemVariantsAreUsed AS ItemVariantsAreUsed,
	|	TableOfGoods.Series AS Series,
	|	TableOfGoods.BatchesIndicationStatus AS BatchesIndicationStatus,
	|	TableOfGoods.NumberOfPackages AS NumberOfPackages,
	|	TableOfGoods.Package AS Package,
	|	TableOfGoods.Warehouse AS Warehouse,
	|	TableOfGoods.DateOfShipment AS DateOfShipment
	|INTO TTTableOfGoods
	|FROM
	|	&TableOfGoods AS TableOfGoods
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	DeliveryTable.RowCode AS RowCode,
	|	DeliveryTable.DeliveryMethod AS DeliveryMethod,
	|	DeliveryTable.DeliveryPoint AS DeliveryPoint,
	|	DeliveryTable.DeliveryZone AS DeliveryZone,
	|	DeliveryTable.DeliveryToCarrier AS DeliveryToCarrier,
	|	DeliveryTable.Carrier AS Carrier,
	|	DeliveryTable.CarrierDeliveryPoint AS CarrierDeliveryPoint,
	|	DeliveryTable.CarrierSDeliveryArea AS CarrierSDeliveryArea,
	|	DeliveryTable.DeliveryTimeFrom AS DeliveryTimeFrom,
	|	DeliveryTable.DeliveryTimeTo AS DeliveryTimeTo,
	|	DeliveryTable.AdditionalDeliveryInformation AS AdditionalDeliveryInformation,
	|	DeliveryTable.SpecialTransportationConditions AS SpecialTransportationConditions,
	|	DeliveryTable.SpecialTransportationConditionsDescription AS SpecialTransportationConditionsDescription
	|INTO TTDeliveryTable
	|FROM
	|	&DeliveryTable AS DeliveryTable
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	WarehouseInformationTable.Warehouse AS Warehouse,
	|	WarehouseInformationTable.WarehousePoint AS WarehousePoint,
	|	WarehouseInformationTable.AreaOfWarehouse AS AreaOfWarehouse
	|INTO TTWarehouseInformationTable
	|FROM
	|	&WarehouseInformationTable AS WarehouseInformationTable
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TableOfGoods.LineNumber AS LineNumber,
	|	TableOfGoods.RowCode AS RowCode,
	|	TableOfGoods.Products AS Products,
	|	TableOfGoods.Characteristic AS Characteristic,
	|	TableOfGoods.ItemVariantsAreUsed AS ItemVariantsAreUsed,
	|	TableOfGoods.Series AS Series,
	|	TableOfGoods.BatchesIndicationStatus AS BatchesIndicationStatus,
	|	TableOfGoods.NumberOfPackages AS NumberOfPackages,
	|	TableOfGoods.Package AS Package,
	|	TableOfGoods.Warehouse AS Warehouse,
	|	TableOfGoods.DateOfShipment AS DateOfShipment,
	|	CASE
	|		WHEN TableWarehousesDeliveryDetails.WarehousePoint IS NULL
	|			THEN ISNULL(DeliveryPoints.Ref, VALUE(Catalog.DeliveryPoints.EmptyRef))
	|		ELSE TableWarehousesDeliveryDetails.WarehousePoint
	|	END AS WarehousePoint,
	|	CASE
	|		WHEN TableWarehousesDeliveryDetails.AreaOfWarehouse IS NULL
	|			THEN ISNULL(DeliveryPoints.DeliveryZone, VALUE(Catalog.DeliveryZones.EmptyRef))
	|		ELSE TableWarehousesDeliveryDetails.AreaOfWarehouse
	|	END AS AreaOfWarehouse,
	|	ISNULL(DeliveryTable.DeliveryMethod, VALUE(Enum.TransportMethods25.OwnDelivery)) AS DeliveryMethod,
	|	ISNULL(DeliveryTable.DeliveryPoint, VALUE(Catalog.DeliveryPoints.EmptyRef)) AS DeliveryPoint,
	|	ISNULL(DeliveryTable.DeliveryZone, VALUE(Catalog.DeliveryZones.EmptyRef)) AS DeliveryZone,
	|	ISNULL(DeliveryTable.DeliveryToCarrier, FALSE) AS DeliveryToCarrier,
	|	ISNULL(DeliveryTable.Carrier, VALUE(Catalog.Partners.EmptyRef)) AS Carrier,
	|	ISNULL(DeliveryTable.CarrierDeliveryPoint, VALUE(Catalog.DeliveryPoints.EmptyRef)) AS CarrierDeliveryPoint,
	|	ISNULL(DeliveryTable.CarrierSDeliveryArea, VALUE(Catalog.DeliveryZones.EmptyRef)) AS CarrierSDeliveryArea,
	|	ISNULL(DeliveryTable.DeliveryTimeFrom, DATETIME(1, 1, 1)) AS DeliveryTimeFrom,
	|	ISNULL(DeliveryTable.DeliveryTimeTo, DATETIME(1, 1, 1)) AS DeliveryTimeTo,
	|	ISNULL(DeliveryTable.AdditionalDeliveryInformation, """") AS AdditionalDeliveryInformation,
	|	ISNULL(DeliveryTable.SpecialTransportationConditions, FALSE) AS SpecialTransportationConditions,
	|	ISNULL(DeliveryTable.SpecialTransportationConditionsDescription, """") AS SpecialTransportationConditionsDescription
	|FROM
	|	TTTableOfGoods AS TableOfGoods
	|		LEFT JOIN TTDeliveryTable AS DeliveryTable
	|		ON TableOfGoods.RowCode = DeliveryTable.RowCode
	|		LEFT JOIN Catalog.DeliveryPoints AS DeliveryPoints
	|		ON TableOfGoods.Warehouse = DeliveryPoints.Owner
	|		AND DeliveryPoints.MainPoint
	|		LEFT JOIN TTWarehouseInformationTable AS TableWarehousesDeliveryDetails
	|		ON TableOfGoods.Warehouse = TableWarehousesDeliveryDetails.Warehouse";
	#EndRegion
	
	Query.Text = QueryText;
	Query.SetParameter("TableOfGoods", TableOfGoods);
	Query.SetParameter("DeliveryTable", DeliveryTable);
	Query.SetParameter("WarehouseInformationTable", WarehouseInformationTable);
	
	CacheOfWarehouses = New Map();
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		
		DeliveryLine = GoodsDeliveryClientServer.NewDeliveryLineData();
		DeliveryLine.DocumentRowNumber = Selection.LineNumber;
		DeliveryLine.RowCode = Selection.RowCode;
		DeliveryLine.Products = Selection.Products;
		DeliveryLine.Characteristic = Selection.Characteristic;
		DeliveryLine.ItemVariantsAreUsed = Selection.ItemVariantsAreUsed;
		DeliveryLine.Series = Selection.Series;
		DeliveryLine.BatchesIndicationStatus = Selection.BatchesIndicationStatus;
		DeliveryLine.NumberOfPackages = Selection.NumberOfPackages;
		DeliveryLine.Package = Selection.Package;
		DeliveryLine.DeliveryMethod = Selection.DeliveryMethod;
		DeliveryLine.DeliveryPoint = Selection.DeliveryPoint;
		DeliveryLine.DeliveryZone = Selection.DeliveryZone;
		DeliveryLine.DeliveryToCarrier = Selection.DeliveryToCarrier;
		DeliveryLine.Carrier = Selection.Carrier;
		DeliveryLine.CarrierDeliveryPoint = Selection.CarrierDeliveryPoint;
		DeliveryLine.CarrierSDeliveryArea = Selection.CarrierSDeliveryArea;
		DeliveryLine.DeliveryTimeFrom = Selection.DeliveryTimeFrom;
		DeliveryLine.DeliveryTimeTo = Selection.DeliveryTimeTo;
		DeliveryLine.AdditionalDeliveryInformation = Selection.AdditionalDeliveryInformation;
		DeliveryLine.SpecialTransportationConditions = Selection.SpecialTransportationConditions;
		DeliveryLine.SpecialTransportationConditionsDescription = Selection.SpecialTransportationConditionsDescription;
		DeliveryLine.DateOfShipment = Selection.DateOfShipment;
		
		DeliverySettings.Goods.Add(DeliveryLine);
		
		If ValueIsFilled(Selection.Warehouse)
		   And CacheOfWarehouses[Selection.Warehouse] = Undefined Then
			
			CacheOfWarehouses[Selection.Warehouse] = True; // We remember that the line was added earlier
			
			WarehouseLine_ = GoodsDeliveryClientServer.NewDeliveryWarehouseRowData();
			WarehouseLine_.Warehouse = Selection.Warehouse;
			WarehouseLine_.WarehousePoint = Selection.WarehousePoint;
			WarehouseLine_.AreaOfWarehouse = Selection.AreaOfWarehouse;
			DeliverySettings.Warehouses.Add(WarehouseLine_);
			
		EndIf;
		
	EndDo;
	
	If Not Object.Warehouse.IsEmpty()
		And CacheOfWarehouses[Object.Warehouse] = Undefined Then
		
		IsFolder = Common.ObjectAttributeValue(Object.Warehouse, "IsFolder");
		If Not IsFolder Then
			
			PointData_ = Catalogs.DeliveryPoints.DeliveryPointInformationMain(Object.Warehouse);
			WarehouseLine_ = GoodsDeliveryClientServer.NewDeliveryWarehouseRowData();
			WarehouseLine_.Warehouse = Object.Warehouse;
			WarehouseLine_.WarehousePoint = PointData_.DeliveryPoint;
			WarehouseLine_.AreaOfWarehouse = PointData_.DeliveryZone;
			DeliverySettings.Warehouses.Add(WarehouseLine_);
			
			CacheOfWarehouses[Object.Warehouse] = True;
			
		EndIf;
		
	EndIf;
	
	Return DeliverySettings;
	
EndFunction

// Parameters:
//  Settings - Undefined -
//            - See GoodsDeliveryClientServer.DefaultDeliverySettings
//  AdditionalParameters - Structure
//
&AtClient
Procedure ProcessDeliveryParameterSettings(Settings, AdditionalParameters) Export
	
	If Settings = Undefined Then
		Return;
	EndIf;
	
	ProcessDeliveryParameterSettingsServer(Settings);
	
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	Modified = True;
	
EndProcedure

&AtServer
Procedure ProcessDeliveryParameterSettingsServer(Val Settings)
	
	Object.DeliveryPlanning = Settings.DeliveryPlanning;
	Object.DeliverySpecificationMethod = Settings.DeliverySpecificationMethod;
	Object.DeliveryMethod25 = Settings.DeliveryMethod;
	
	Object.DeliveryPoint = Settings.DeliveryPoint;
	Object.DeliveryZone = Settings.DeliveryZone;
	
	Object.DeliveryToCarrier = Settings.DeliveryToCarrier;
	Object.CarrierPartner = Settings.Carrier;
	Object.CarrierDeliveryPoint = Settings.CarrierDeliveryPoint;
	Object.CarrierSDeliveryArea = Settings.CarrierSDeliveryArea;
	
	Object.DeliveryTimeFrom = Settings.DeliveryTimeFrom;
	Object.DeliveryTimeTo = Settings.DeliveryTimeTo;
	
	Object.AdditionalDeliveryInformation = Settings.AdditionalDeliveryInformation;
	Object.SpecialTransportationConditions = Settings.SpecialTransportationConditions;
	Object.SpecialTransportationConditionsDescription = Settings.SpecialTransportationConditionsDescription;
	
	Object.Courier = Settings.Courier;
	
	Object.GoodsToDeliver.Clear();
	For Each RowOfGoods In Settings.Goods Do
	
		NewRow = Object.GoodsToDeliver.Add();
		FillPropertyValues(NewRow, RowOfGoods);
		
	EndDo;
	Object.GoodsToDeliver.Sort("RowCode");
	
	Object.WarehousesDeliveryInformation.Clear();
	For Each WarehouseLine_ In Settings.Warehouses Do
	
		NewRow = Object.WarehousesDeliveryInformation.Add();
		FillPropertyValues(NewRow, WarehouseLine_);
		
	EndDo;
	Object.WarehousesDeliveryInformation.Sort("Warehouse");
	
	If Object.DeliverySpecificationMethod = Enums.DeliverySpecificationMethods.ForWholeDocument Then
		
		FieldNamesOfDeliveryPointAddresses = "Address, AddressValue, FieldValueAddress";
		DeliveryPointAddressFields = Common.ObjectAttributesValues(Object.DeliveryPoint, FieldNamesOfDeliveryPointAddresses);
		
		Object.DeliveryAddress = DeliveryPointAddressFields.Address;
		Object.DeliveryAddressFieldValues = DeliveryPointAddressFields.AddressValue;
		Object.DeliveryAddressValue = DeliveryPointAddressFields.FieldValueAddress;
		
	EndIf;
	
EndProcedure

// Parameters:
//  Form - See Document.SalesOrder.Form.DocumentForm
//
&AtClientAtServerNoContext
Procedure SetAvailabilityVisibilityOfDeliveryItems(Form)
	
	Object = Form.Object;
	Items = Form.Items;
	
	DeliveryIsApplicable = GoodsDeliveryClientServer.BusinessTransactionIsInvolvedInDelivery(Object.BusinessOperation);
	
	ItemsNames = New Array; // Array of String
	ItemsNames.Add("DeliveryIsRequired");
	ItemsNames.Add("EditDeliveryParametersHeader");
		
	If Not GoodsDeliveryClientServer.UsedDelivery25()
		Or Object.ThisIsOrderAsInvoice
		Or Object.Organization = PredefinedValue("Catalog.Companies.ManagementCompany")
		Or Not DeliveryIsApplicable Then
		
		ItemsNames.Add("EditDeliveryParametersForItems");
		
		TMCommonUseClientServer.SetPropertyOfFormElements(
			Items,
			ItemsNames,
			"Visible",
			False);
		
	Else
		
		CommonClientServer.SetFormItemProperty(
			Items,
			"EditDeliveryParametersHeader",
			"Enabled",
			Object.DeliveryIsRequired);
		
		CommonClientServer.SetFormItemProperty(
			Items,
			"EditDeliveryParametersForItems",
			"Visible",
			Object.DeliveryIsRequired);
		
		TMCommonUseClientServer.SetPropertyOfFormElements(
			Items,
			ItemsNames,
			"Visible",
			True);
		
	EndIf;
	
EndProcedure

&AtServer
Procedure UpdateDeliveryPlanningView()
	
	If Not Object.DeliveryIsRequired Then
		Return;
	EndIf;
	
	Object.DeliveryPlanning = GoodsDelivery.TypeOfDeliveryPlanningByPartnerAgreement(
		Object.Partner,
		Object.Terms);
	
EndProcedure

#EndRegion

#Region Delivery20

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

#Region ControlOfInconsistentChanges

// Parameters:
//	Item - FormGroup, FormTable, FormField, FormButton - FormItem
&AtClient
Procedure ControlOfNonConsistentChangesHandleEventOnChange(Item)
	If Item.Name = "Date" Then
		DateOnChange(Item);
	ElsIf Item.Name = "Partner" Then
		PartnerOnChange(Item);
	ElsIf Item.Name = "Terms" Then
		TermsOnChange(Item);
	ElsIf Item.Name = "Currency" Then
		CurrencyOnChange(Item);
	ElsIf Item.Name = "PriceIncludesVAT" Then
		PriceIncludesVATOnChange(Item);
	ElsIf Item.Name = "VATTaxation" Then
		VATTaxationOnChange(Item);
	ElsIf Item.Name = "Organization" Then
		OrganizationOnChange(Item);
	ElsIf Item.Name = "Counterparty" Then
		CounterpartyOnChange(Item);
	ElsIf Item.Name = "Contract" Then
		ContractOnChange(Item);
	ElsIf Item.Name = "Warehouse" Then
		WarehouseOnChange(Item);
	ElsIf Item.Name = "NotShipInInstallments" Then
		NotShipInInstallmentsOnChange(Item);
	ElsIf Item.Name = "DateOfShipment" Then
		DateOfShipmentOnChange(Item);
	ElsIf Item.Name = "BusinessOperation" Then
		BusinessOperationOnChange(Item);
	ElsIf Item.Name = "ToReturnReusablePackage" Then
		ToReturnReusablePackageOnChange(Item);
	ElsIf Item.Name = "PackageDepositIsRequired" Then
		PackageDepositIsRequiredOnChange(Item);
	ElsIf Item.Name = "ApprovalDate" Then
		ApprovalDateOnChange(Item);
	ElsIf Item.Name = "GoodsProducts" Then
		GoodsProductsOnChange(Item);
	ElsIf Item.Name = "GoodsCharacteristic" Then
		GoodsCharacteristicOnChange(Item);
	ElsIf Item.Name = "GoodsNumberOfPackages" Then
		GoodsNumberOfPackagesOnChange(Item);
	ElsIf Item.Name = "GoodsPackage" Then
		GoodsPackageOnChange(Item);
	ElsIf Item.Name = "GoodsWithAssignment" Then
		GoodsWithAssignmentOnChange(Item);
	ElsIf Item.Name = "GoodsPriceKind" Then
		GoodsPriceKindOnChange(Item);
	ElsIf Item.Name = "GoodsPrice" Then
		GoodsPriceOnChange(Item);
	ElsIf Item.Name = "GoodsVATRate" Then
		GoodsVATRateOnChange(Item);
	ElsIf Item.Name = "GoodsPercentRateOfManualDiscount" Then
		GoodsPercentRateOfManualDiscountOnChange(Item);
	ElsIf Item.Name = "GoodsManualDiscount" Then
		GoodsManualDiscountOnChange(Item);
	ElsIf Item.Name = "GoodsSum" Then
		GoodsSumOnChange(Item);
	ElsIf Item.Name = "GoodsVATAmount" Then
		GoodsVATAmountOnChange(Item);
	ElsIf Item.Name = "GoodsSeries" Then
		GoodsSeriesOnChange(Item);
	ElsIf Item.Name = "GoodsWarehouse" Then
		GoodsWarehouseOnChange(Item);
	ElsIf Item.Name = "GoodsDepartment" Then
		GoodsDepartmentOnChange(Item);
	ElsIf Item.Name = "ProductsCanceledCancellationReasonsAreNotUsed" Then
		GoodsCanceledOnChange(Item);
	ElsIf Item.Name = "GoodsCanceled" Then
		GoodsCanceledOnChange(Item);
	ElsIf Item.Name = "GoodsPartnerProducts" Then
		GoodsPartnerProductsOnChange(Item);
	ElsIf Item.Name = "Department" Then
		DepartmentOnChange(Item);
	Else
		TMCommonUseClient.MonitoringNonConsistentChangesCauseException(ThisForm, Item);
	EndIf;
EndProcedure

&AtClient
Procedure ControlOfNonConsistentChangesHandleCommandEvent(Command)
	If Command.Name = "OpenSelection" Then
		OpenSelection(Command);
	ElsIf Command.Name = "AddReusablePackage" Then
		AddReusablePackage(Command);
	ElsIf Command.Name = "SearchByBarcode" Then
		SearchByBarcodeExecute(Command);
	ElsIf Command.Name = "ImportDataFromPDT" Then
		ImportDataFromPDT(Command);
	ElsIf Command.Name = "FillInTheWarehouseInSelectedLines" Then
		FillInTheWarehouseInSelectedLines(Command);
	ElsIf Command.Name = "ImportFromExternalFile" Then
		ImportFromExternalFile(Command);
	ElsIf Command.Name = "FillThePricesByTermsOfSales" Then
		AutoTestFillInPricesByAgreement(Command);
	ElsIf Command.Name = "FillInPricesOfSelectedRowsByPriceType" Then
		FillInPricesOfSelectedRowsByPriceType(Command);
	ElsIf Command.Name = "ToReadLoyaltyCard" Then
		ToReadLoyaltyCard(Command);
	ElsIf Command.Name = "CalculateDiscountsMarkups" Then
		CalculateDiscountsMarkups(Command);
	ElsIf Command.Name = "CancelManualDiscounts" Then
		CancelManualDiscounts(Command);
	ElsIf Command.Name = "AssignAManualDiscount" Then
		AssignAManualDiscount(Command);
	ElsIf Command.Name = "AssignAManualDiscountToSelectedRows" Then
		AssignAManualDiscountForSelectedLines(Command);
	ElsIf Command.Name = "AssignAutomaticDiscounts" Then
		AssignAutomaticDiscounts(Command);
	ElsIf Command.Name = "SetComposition" Then
		SetComposition(Command);
	ElsIf Command.Name = "InsertRows" Then
		InsertRows(Command);
	ElsIf Command.Name = "SplitRow" Then
		SplitRow(Command);
	ElsIf Command.Name = "FillInPricesUnderAgreement" Then
		FillInPricesUnderAgreement(Command);
	ElsIf Command.Name = "FillInTheDepartment" Then
		FillInTheDepartment(Command);
	ElsIf Command.Name = "FillInVATRate" Then
		FillInVATRate(Command);
	ElsIf Command.Name = "AddPaymentWithBonusPoints" Then
		AddPaymentWithBonusPoints(Command);
	ElsIf Command.Name = "CancelPaymentWithBonusPoints" Then
		CancelPaymentWithBonusPoints(Command);
	Else
		TMCommonUseClient.MonitoringNonConsistentChangesCauseException(ThisForm, Command);
	EndIf;
EndProcedure

&AtClient
Procedure ControlOfNonConsistentChangesHandlePushEvent(Item)
	TMCommonUseClient.MonitoringNonConsistentChangesCauseException(ThisForm, Item);
EndProcedure

&AtClient
Procedure ControlOfNonConsistentChangesHandleEventBeforeStartingChange(Item, Cancel)
	TMCommonUseClient.MonitoringNonConsistentChangesCauseException(ThisForm, Item);
EndProcedure

// Parameters:
//	Item - FormGroup, FormTable, FormField, FormButton - FormItem
//	Cancel - Boolean - Cancel
&AtClient
Procedure ControlOfNonConsistentChangesHandleEventBeforeDeletion(Item, Cancel)
	If Item.Name = "Goods" Then
		GoodsBeforeDeleteRow(Item, Cancel);
	Else
		TMCommonUseClient.MonitoringNonConsistentChangesCauseException(ThisForm, Item);
	EndIf;
EndProcedure

// Parameters:
//	Item - FormGroup, FormTable, FormField, FormButton - FormItem
&AtClient
Procedure ControlOfNonConsistentChangesHandleEventBeforeStartingAdding(Item, Cancel, Copy, Parent, Var_Group)
	If Item.Name = "Goods" Then
		GoodsBeforeAddRow(Item, Cancel, Copy, Parent, Var_Group);
	Else
		TMCommonUseClient.MonitoringNonConsistentChangesCauseException(ThisForm, Item);
	EndIf;
EndProcedure

// Parameters:
//	Item - FormGroup, FormTable, FormField, FormButton - FormItem
&AtClient
Procedure Attachable_WhenChanging_SetAvailabilityOfItemsByStatusServer(Item)
	
	If TMCommonUseClient.WhenActingOnStatusDependentElement(ThisForm) Then
		Return;
	EndIf;
	
	If StructureOfActionsControlOfNonAgreedChanges.OnChange.Property(Item.Name) Then
		ControlOfNonConsistentChangesHandleEventOnChange(Item);
	EndIf;
	
EndProcedure

// Parameters:
//	Item - FormGroup, FormTable, FormField, FormButton - FormItem
&AtClient
Procedure Attachable_Clicking_SetAvailabilityOfItemsByStatusServer(Item)
	
	If TMCommonUseClient.WhenActingOnStatusDependentElement(ThisForm) Then
		Return;
	EndIf;
	
	If StructureOfActionsControlOfNonAgreedChanges.Click.Property(Item.Name) Then
		ControlOfNonConsistentChangesHandlePushEvent(Item);
	EndIf;
	
EndProcedure

// Parameters:
//	Command - FormCommand - 
&AtClient
Procedure Attachable_Command_SetAvailabilityOfItemsByStatusServer(Command)
	
	If TMCommonUseClient.WhenActingOnStatusDependentElement(ThisForm) Then
		Return;
	EndIf;
	
	If StructureOfActionsControlOfNonAgreedChanges.Commands.Property(Command.Name) Then
		ControlOfNonConsistentChangesHandleCommandEvent(Command);
	EndIf;

EndProcedure

// Parameters:
//	Item - FormGroup, FormTable, FormField, FormButton - FormItem
&AtClient
Procedure Attachable_BeforeStartingChange_SetAvailabilityOfItemsByStatusServer(Item, Cancel)
	
	If TMCommonUseClient.WhenActingOnStatusDependentElement(ThisForm) Then
		Return;
	EndIf;
	
	If StructureOfActionsControlOfNonAgreedChanges.BeforeRowChange.Property(Item.Name) Then
		ControlOfNonConsistentChangesHandleEventBeforeStartingChange(Item, Cancel);
	EndIf;

EndProcedure

// Parameters:
//	Item - FormGroup, FormTable, FormField, FormButton - FormItem
&AtClient
Procedure Attachable_BeforeDeleting_SetAvailabilityOfItemsByStatusServer(Item, Cancel)
	
	If TMCommonUseClient.WhenActingOnStatusDependentElement(ThisForm) Then
		Return;
	EndIf;
	
	Name = Item.Name;
	If StructureOfActionsControlOfNonAgreedChanges.BeforeDeleteRow.Property(Name) Then
		ControlOfNonConsistentChangesHandleEventBeforeDeletion(Item, Cancel);
	EndIf;

EndProcedure

// Parameters:
//	Item - FormGroup, FormTable, FormField, FormButton - FormItem
&AtClient
Procedure Attachable_BeforeYouStartAdding_SetAvailabilityOfItemsByStatusServer(Item, Cancel, Copy, Parent, Var_Group)
	
	If TMCommonUseClient.WhenActingOnStatusDependentElement(ThisForm) Then
		Return;
	EndIf;
	
	Name = Item.Name;
	If StructureOfActionsControlOfNonAgreedChanges.BeforeAddRow.Property(Name) Then
		ControlOfNonConsistentChangesHandleEventBeforeStartingAdding(Item, Cancel, Copy, Parent, Var_Group);
	EndIf;

EndProcedure

&AtClient
Procedure Attachable_WhenChangingDetailsDependingOnStatus()
	
	SetAvailabilityOfItemsByStatusServer();
	TMCommonUseClient.AfterChangingPropsDependentOnStatus(ThisForm);
	
EndProcedure

&AtServer
Procedure ToReturnReusablePackageOnChangeServer()
	
	If Not Object.ToReturnReusablePackage Then
		Object.PackageDepositIsRequired = False;
	EndIf;
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
	StructureOfActions.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));
	StructureOfActions.Insert("FillInVATRateForReturnableContainers", Object.ToReturnReusablePackage);
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForRecalculatingNDSWTCHAmount(Object);
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	BatchProcessingOfTablePartServer.TreatTS(Object.Goods, StructureOfActions, Undefined);
	
	UpdateDuplicateDependentDetails();
	
	FillInServiceDetailsOfDocumentForm();
	
	UpdateAvailabilityOfReturnContainerItems(ThisForm);
	CalculateOrderTotals(ThisForm);
	
EndProcedure

&AtServer
Procedure PrepareFillSetSeriesVisibility()
	
	SeriesSpecificationParameters = New FixedStructure(ProductsServer.SeriesSpecificationParameters(Object, Documents.SalesOrder));
	ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);
	Items.GoodsSeries.Visible = SeriesSpecificationParameters.UseItemsBatch;;
	
EndProcedure

&AtClient
Procedure GoodsSeriesStartChoice(Item, ChoiceData, StandardProcessing)
	StandardProcessing = False;
	OpenSelectionOfSeries(Item.EditText);
EndProcedure

&AtClient
Procedure GoodsSeriesOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;
	
	ValueSelected = ProductsClientServer.SelectedSeries();
	
	ValueSelected.Value = CurrentRow.Series;
	ValueSelected.CurrentRowID = CurrentRow.GetID();
	
	ProductsClient.ProcessSeriesIndication(ThisForm, SeriesSpecificationParameters, ValueSelected);

	ProductsSeriesRecalculatePrices(CurrentRow);
	
EndProcedure

&AtClient
Procedure ProductsSeriesRecalculatePrices(CurrentRow = Undefined)
	
	If CurrentRow = Undefined Then
		CurrentRow = Items.Goods.CurrentData;
	EndIf;
	
	If PriceManagementSystemClient.ItIsNecessaryToRecalculatePriceWhenChanging(CurrentRow.Products, "Series", Object.Date) Then
		
		StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
		
		StructureOfActions = New Structure;
		StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
		StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
		StructureOfActions.Insert("RecalculateAmount");
		StructureOfActions.Insert("RecalculateAmountTakingIntoAccountManualDiscount", New Structure("Clear", True));
		StructureOfActions.Insert("RecalculateAmountTakingIntoAccountAutomaticDiscount", New Structure("Clear", True));
		StructureOfActions.Insert("ClearAmountOfSettlements");
		StructureOfActions.Insert("FillInDuplicateDependentDetails", DependentDetails());
		AddPriceFillingAction(StructureOfActions);
		
		BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
		
		CalculateOrderTotals(ThisForm);
	
		DiscountsMarkupsFillingClient.ResetDiscountsCalculatedFlag(ThisForm);
		
	EndIf;
	
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
											
	ParametersForFillingInBankingDetails.Insert("FillInSalesOptionAttribute",
											New Structure("Products", "SaleRegistrationOption"));
	
	ProductsServer.FillInServiceDetailsForProductInCollection(Object.Goods,ParametersForFillingInBankingDetails);
	
	SetsServer.FillInServiceDetails(ThisForm);
	
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
Procedure FillInShippingDateSelectionList()

	MaxAdvanceDate = SalesServer.MaximumAdvancePaymentDate(Object.PaymentScheduleSteps);
	ShipmentDateSelectionList = Items.DateOfShipment.ChoiceList;
	
	If ValueIsFilled(MaxAdvanceDate) Then
		
		PresentationMaxAdvanceDate = "%MaxAdvanceDate%";
		PresentationMaxAdvanceDate = StrReplace(PresentationMaxAdvanceDate, "%MaxAdvanceDate%", Format(MaxAdvanceDate,"DLF=D"));
		
		ShipmentDateSelectionList.Clear();
		ShipmentDateSelectionList.Add(MaxAdvanceDate, PresentationMaxAdvanceDate);
		
	EndIf;

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

#EndRegion

#Region Other

&AtServer
Procedure GoodsAfterDeleteRowServer(ThereIsChangeInShippingDates)
	
	WhenChangingWarehouseInTablePartServer();
	UpdateColumnAvailableServer();
	If ThereIsChangeInShippingDates Then
		ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisObject, "Goods.DateOfShipment");
	EndIf;
	
EndProcedure

&AtServer
Procedure GoodsCanceledOnChangeATServer()
	
	ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisObject, "Goods.DateOfShipment");
	
EndProcedure

&AtClient
Procedure Attachable_CloseForm()
	
	If IsOpen() Then
		Close();
	EndIf;
	
EndProcedure

&AtServer
Procedure OnReadCreateAtServer()
	
	UseStatuses = Not Object.ThisIsOrderAsInvoice;
	Items.Status.Visible = UseStatuses;
	Items.CloseOrder.Visible = UseStatuses;
	
	DocumentCurrency = Object.Currency;
	WarehouseGroup_ = Catalogs.Warehouses.ThisGroupAndWarehousesAreUsedByWHForSales(Object.Warehouse);
	Items.GoodsFillInTheWarehouseInSelectedLines.Enabled = WarehouseGroup_;
	
	SetParametersForSelectingProductsWarehouse();
	
	ToUseTermsOfSales                  = GetFunctionalOption("ToUseTermsOfSales");
	UseShipmentWithDeferredTransferOfTitle = GetFunctionalOption("UseShipmentWithDeferredTransferOfTitle2_0");
	UsePaymentSchedules                         = GetFunctionalOption("UsePaymentSchedules");
	UseMultipleCompanies                  = GetFunctionalOption("UseMultipleCompanies");
	UseLinesOfBusiness               = GetFunctionalOption("UseIncomeAccountingByLinesOfBusiness");
	ToUseTheTransferOfGoodsToStorage             = GetFunctionalOption("UseTransferToCustodyWithRightOfSale");
	ProvideAgentServicesOnPurchaseToPrincipals      = GetFunctionalOption("ProvideAgentServicesOnPurchaseToPrincipals");
	UseShipmentByRowsInSalesOrder      = GetFunctionalOption("UseShipmentByRowsInSalesOrder");
	
	If Object.ThisIsOrderAsInvoice Then
		
		UseShipmentByRowsInSalesOrder = False;
		UseLinesOfBusiness = False;
		
	EndIf;
	
	PaymentWithBonusPoints = Object.Goods.Total("AmountOfBonusPointsToDeduction") <> 0 
		Or Object.Goods.Total("AmountOfBonusPointsToDeductionInCurrency") <> 0;
	
	DocumentDate = ?(Parameters.Key.IsEmpty(), CurrentSessionDate(), Object.Date);
	RetailSalesClientServer.SetAvailabilityOfBonusPointsPaymentTeams(Items, DocumentDate);	
	
	FillInListOfSelectedBusinessOperations(ProvideAgentServicesOnPurchaseToPrincipals);
	
	If Not ToUseTermsOfSales Then
		
		PriceTypeSelectionParameters = SettingsValueCached.ParametersForSelectingDefaultPriceType();
		PriceTypeSelectionParameters.PriceIncludesVAT = Object.PriceIncludesVAT;
		PriceTypeSelectionParameters.UseWhileSellingToCustomers = True;
		PriceTypeSelectionParameters.Status = Enums.StatusesOfPriceTypeValidity.Valid;
		
		DefaultPriceType = SettingsValueCached.DefaultPriceType(PriceTypeSelectionParameters);
		
	EndIf;
	
	ContractBusinessTransaction = GetBusinessTransaction(Object.BusinessOperation);
	EstablishRelationshipsBetweenContractSelectionParameters();
	
	ConsignmentSales25 = Object.BusinessOperation = Enums.BusinessTransactions.TransferToCommissionAgent
		And (Not ToUseTermsOfSales Or SalesServer.ThisIsAgreementOnNewCommission(Object.Terms));
	
	FillOperationSelectionList(False);
	ResponsiblePersonsServer.FillInManagerSelectionList_(Items.Manager, Object);
	SetAvailabilityOfItemsByStatusServer();
	
	FillInServiceDetailsForProductRange();
	
	UpdateDuplicateDependentDetails();
	RefreshStatusServer();
	
	SetVisibilityOfElementsByOperationServer();
	
	CalculateOrderTotals(ThisForm);
	SeriesSpecificationParameters = New FixedStructure(ProductsServer.SeriesSpecificationParameters(Object, Documents.SalesOrder));
	Items.GoodsSeries.Visible = SeriesSpecificationParameters.UseItemsBatch;
	FillInShippingDateSelectionList();
	
	Items.Organization.Visible = UseMultipleCompanies;
	
	SetVisibilityOfShippingDateFormElements();
	UpdateAvailabilityOfReturnContainerItems(ThisForm);
	
	BackgroundJobDataGettingCarriers = GoodsDelivery.WhenReadingCreatingOrdersOnServer(Items, Object,,,, True);
	
	SetVisibilityOfShipmentBanToPartner();
	SetSoftwareVisibility();

	MailoutsAndNotificationsToCustomers.SetVisibilityOfSubscribingToAlertsInObject(
		Items.GroupSubscribeToAlerts,
		Object.Partner,
		PredefinedValue("Enum.NotificationEventTypes.OrderStatusChange")
	);
		
	TMCommonUseClientServer.SetFormItemProperty(Items, "GroupEDIState", "Visible", UseStatuses, True);
	
	InitiateReceiptOfDocumentsBasedOn();
	
	SetPrivilegedMode(True);
	
	DefaultSecurityOption = DefaultSecurityOption();
	SecurityOptionAndFlagSeparately = SalesServer.ProvisionOptionAndFlagAreSeparateByDefault(
		Object.Terms,
		Object.Status,
		DefaultSecurityOption,
		Not Object.ThisIsOrderAsInvoice
	);
		
	WarehousesServer.WhenChangingWarehouseInTablePart(Object.Goods, WarehouseTable, WarehouseGroup_);
	TotalWarehouses_ = WarehouseTable.Count();
	WarehousesClientServer.UpdateWarehouseGroupImage(SeveralWarehousesText, Items.PictureMultipleWarehouses, TotalWarehouses_);
	
	ProcessingOfTabularForms.InitializeRowCache(Items.Goods);
	
	LinesOfBusinessServer.OnReadCreateAtServer(ThisObject);
	
	FillParameters = Documents.SalesOrder.ParametersForFillingInSalesVATTaxation(Object);
	VATAccountingERP.FillInSalesVATTaxSelectionList(Items.VATTaxation, Object.VATTaxation, FillParameters, VATAccountingCachedParameterValues);
	FillInServiceDetailsOfDocumentForm();
	
	SetAvailabilityVisibilityOfDeliveryItems(ThisObject);
	
EndProcedure
	

&AtServerNoContext
Function GetBusinessTransaction(BusinessOperation)
	
	ContractBusinessTransaction = BusinessOperation;
	
	If BusinessOperation = PredefinedValue("Enum.BusinessTransactions.SaleToCustomerLocalAccounting") 
		Or BusinessOperation = PredefinedValue("Enum.BusinessTransactions.SaleWithDeferredTransferOfTitle") Then
		ContractBusinessTransaction = PredefinedValue("Enum.BusinessTransactions.SaleToCustomer");
	ElsIf BusinessOperation = PredefinedValue("Enum.BusinessTransactions.SalesViaCommissionAgent") 
		Or BusinessOperation = PredefinedValue("Enum.BusinessTransactions.SalesViaCommissionAgentGoodsInTransit") Then
		ContractBusinessTransaction = PredefinedValue("Enum.BusinessTransactions.TransferToCommissionAgent");
	EndIf;
	
	Return ContractBusinessTransaction;
	
EndFunction

&AtClient
Procedure EnableWaitingHandlerForDocumentDataBasedOn()
	
	If ValueIsFilled(BackgroundJobDataGettingDocumentsBasedOn) Then
		IdleParameters = TimeConsumingOperationsClient.IdleParameters(ThisObject);
		IdleParameters.OutputIdleWindow = False;
		CallbackOnCompletion = New CallbackDescription("UpdateTextDocumentsBasedOn", ThisObject);
	
		TimeConsumingOperationsClient.WaitCompletion(
			BackgroundJobDataGettingDocumentsBasedOn, CallbackOnCompletion, IdleParameters);
	EndIf;

EndProcedure

&AtClient
Procedure EnableWaitingHandlerReceivingCarriers()
	
	If Not GoodsDeliveryClientServer.UsedDelivery20() Then
		Return;
	EndIf;
	
	If BackgroundJobDataGettingCarriers.Property("JobID") Then
		IdleParameters = TimeConsumingOperationsClient.IdleParameters(ThisObject);
		IdleParameters.OutputIdleWindow = False;
		CallbackOnCompletion = New CallbackDescription("UpdateListOfCarriersNotification", ThisObject);

		TimeConsumingOperationsClient.WaitCompletion(
			BackgroundJobDataGettingCarriers, CallbackOnCompletion, IdleParameters);
	EndIf;

EndProcedure

&AtClient
Procedure UpdateListOfCarriersNotification(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	If Result.Status = "Completed2" Then
		GoodsDeliveryClient.UpdateListOfCarriers(Items.CarrierPartner.ChoiceList, Result);
		RefreshDataRepresentation(Items.CarrierPartner);
		BackgroundJobDataGettingCarriers = New Structure;
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Procedure CalculateOrderTotals(Form)
	
	// Filling in the totals according to the "Products" table
	
	CollectionProducts = Form.Object.Goods;

	Form.AmountOrderedWithADepositContainer = ?(Form.Object.PackageDepositIsRequired,
		CollectionProducts.Total("AmountIncludingVAT") - CollectionProducts.Total("AmountIncludingVATCanceled"),
		CollectionProducts.Total("AmountIncludingVATWithoutReusablePackages") - CollectionProducts.Total("AmountIncludingVATCanceledWithoutReusablePackages"));
	Form.AmountOrdered     = CollectionProducts.Total("AmountIncludingVATWithoutReusablePackages") - CollectionProducts.Total("AmountIncludingVATCanceledWithoutReusablePackages");
	Form.PackageDepositValue = ?(Form.Object.PackageDepositIsRequired,(CollectionProducts.Total("AmountIncludingVAT") - CollectionProducts.Total("AmountIncludingVATCanceled"))
			- (CollectionProducts.Total("AmountIncludingVATWithoutReusablePackages") - CollectionProducts.Total("AmountIncludingVATCanceledWithoutReusablePackages")),0);
	Form.AmountNDSOrdered  = ?(Form.Object.PackageDepositIsRequired,
		CollectionProducts.Total("VATAmount") - CollectionProducts.Total("VATAmountCanceled"),
		CollectionProducts.Total("VATAmountWithoutReusablePackages") - CollectionProducts.Total("VATAmountCanceledWithoutReusablePackages"));
		
	AutoDiscountAmount   = ?(Form.Object.PackageDepositIsRequired,
		CollectionProducts.Total("DiscountMarkupAmount") - CollectionProducts.Total("DiscountMarkupAmountCanceled"),
		CollectionProducts.Total("DiscountMarkupAmountWithoutReusablePackages") - CollectionProducts.Total("DiscountMarkupAmountCanceledWithoutReusablePackages"));
	ManualDiscount = ?(Form.Object.PackageDepositIsRequired,
		CollectionProducts.Total("ManualDiscount") - CollectionProducts.Total("ManualDiscountCanceled"),
		CollectionProducts.Total("ManualDiscountWithoutReusablePackages") - CollectionProducts.Total("ManualDiscountCanceledWithoutReusablePackages"));
	AmountAmountOfBonusPointsToBeDebitedInCurrency = ?(Form.Object.PackageDepositIsRequired,
		CollectionProducts.Total("AmountOfBonusPointsToDeductionInCurrency") - CollectionProducts.Total("AmountOfBonusPointsToDeductionInCurrencyCanceled"),
		CollectionProducts.Total("AmountOfBonusPointsToDeductionInCurrencyWithoutReusablePackages") - CollectionProducts.Total("AmountOfBonusPointsToDeductionInCurrencyCanceledWithoutReusablePackages"));
	Form.DiscountAmount       = AutoDiscountAmount + ManualDiscount + AmountAmountOfBonusPointsToBeDebitedInCurrency;
	
	If CollectionProducts.Total("AmountIncludingVATCanceled") = CollectionProducts.Total("AmountIncludingVAT") Then
		Form.AllLinesAreCanceled = True;
	Else
		Form.AllLinesAreCanceled = False;
	EndIf;
	
	// Selecting the VAT display page
	DisplayTotalAmountOfVAT = VATAccountingERPClientServer.DisplayNDSInResultsOfSalesDocument(Form.Object.VATTaxation);
	
	If DisplayTotalAmountOfVAT Then
		
		Form.Items.PagesTotalGroup.CurrentPage = Form.Items.TotalSNDSPage;
		Form.Items.VATPageGroup.CurrentPage   = Form.Items.PageVAT;
		
	Else
		
		Form.Items.PagesTotalGroup.CurrentPage = Form.Items.PageTotalWithoutVAT;
		Form.Items.VATPageGroup.CurrentPage   = Form.Items.PageExcludingVAT;
		
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Function DependentDetails()
	
	Return New Structure(
		"WithoutReusablePackages,CanceledWithoutReusablePackages,Canceled",
		"Sum,VATAmount,AmountIncludingVAT,ManualDiscount,DiscountMarkupAmount,AmountOfBonusPointsToDeductionInCurrency",
		"Sum,VATAmount,AmountIncludingVAT,ManualDiscount,DiscountMarkupAmount,AmountOfBonusPointsToDeductionInCurrency",
		"Sum,VATAmount,AmountIncludingVAT,ManualDiscount,DiscountMarkupAmount,AmountOfBonusPointsToDeductionInCurrency");
	
EndFunction

&AtClientAtServerNoContext
Function DependentPropsByString()
	
	Return "SumWithoutReusablePackages, VATAmountWithoutReusablePackages, AmountIncludingVATWithoutReusablePackages,
		|ManualDiscountWithoutReusablePackages, DiscountMarkupAmountWithoutReusablePackages,
		|AmountOfBonusPointsToDeductionInCurrencyWithoutReusablePackages,
		|SumCanceledWithoutReusablePackages, VATAmountCanceledWithoutReusablePackages, AmountIncludingVATCanceledWithoutReusablePackages,
		|ManualDiscountCanceledWithoutReusablePackages, DiscountMarkupAmountCanceledWithoutReusablePackages,
		|AmountOfBonusPointsToDeductionInCurrencyCanceledWithoutReusablePackages,
		|SumCanceled, VATAmountCanceled, AmountIncludingVATCanceled,
		|ManualDiscountCanceled, DiscountMarkupAmountCanceled,
		|AmountOfBonusPointsToDeductionInCurrencyCanceled";
	
EndFunction

&AtClientAtServerNoContext
Procedure AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions, Object)
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	StructureOfActions.Insert("RecalculateNumberOfUnits");
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmount");
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountManualDiscount", New Structure("Clear", False));
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountAutomaticDiscount", New Structure("Clear", True));
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountDiscountWithBonusPoints");
	StructureOfActions.Insert("FillInDuplicateDependentDetails", DependentDetails());
	
EndProcedure

&AtServer
Procedure AdjustVATRates(ArrayOfSelectedRows = Undefined)
	
	CachedValuesInternal = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInVATRateByPriceType", BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRateByPriceType(Object, True));
	StructureOfActions.Insert("AdjustVATRate",
			BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRate(Object, True, Object.ToReturnReusablePackage));
	StructureOfActions.Insert("FillInVATRateForReturnableContainers", Object.ToReturnReusablePackage);
	
	If ArrayOfSelectedRows = Undefined Then
		BatchProcessingOfTablePartServer.TreatTS(Object.Goods, StructureOfActions, CachedValuesInternal);
	Else
		SelectedRows = ProcessingOfTabularFormsClientServer.CollectionItems(Object.Goods, Items.Goods.SelectedRows);
		BatchProcessingOfTablePartServer.ProcessTSStrings(
			SelectedRows,
			StructureOfActions,
			Object.Goods,
			CachedValuesInternal);
	EndIf;
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForRecalculatingNDSWTCHAmount(Object);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmount");
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountManualDiscount", New Structure("Clear", False));
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountAutomaticDiscount", New Structure("Clear", False));
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountDiscountWithBonusPoints");
	StructureOfActions.Insert("FillInDuplicateDependentDetails", DependentDetails());
	
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		CachedValuesInternal.ProcessedRows,
		StructureOfActions,
		Object.Goods);
	
EndProcedure

&AtServer
Procedure UndoSelectedRowsOnServer()

	If SeriesSpecificationParameters.UseItemsBatch Then
		FillInStatusesForSpecifyingSeries();
	EndIf;
	UpdateColumnAvailableServer();

EndProcedure

&AtServer
Procedure FillInDefaultContract()
	
	ConsignmentSales25 = Object.BusinessOperation = Enums.BusinessTransactions.TransferToCommissionAgent
		And (Not ToUseTermsOfSales Or SalesServer.ThisIsAgreementOnNewCommission(Object.Terms));
	
	If Object.ARAPObjectSettings = Enums.ARAPObjectSettings.ByCounterpartyContracts 
		And UseLinesOfBusiness Then
		
		Contract = SalesServer.GetDefaultContract(Object,
			ContractBusinessTransaction,
			Object.Currency,
			Object.LineOfBusiness,
			ConsignmentSales25
		);
		
	Else
		
		Contract = SalesServer.GetDefaultContract(Object,
			ContractBusinessTransaction,
			Object.Currency,,
			ConsignmentSales25
		);
		
	EndIf;
	
	If Contract <> Object.Contract Then
		
		Object.Contract = Contract;
		ForeignCurrencyTransaction = Object.ForeignCurrencyTransaction;
		FillInFinancialAccountingGroup();
		ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisObject, "Contract");
		If ForeignCurrencyTransaction <> Object.ForeignCurrencyTransaction Then
			Object.BankAccount = Catalogs.CompaniesBankAccounts.EmptyRef();
		EndIf;
		SalesServer.FillInBankAccountsUnderAgreement(Object.Contract, Object.BankAccount, Object.CounterpartyBankAccount);
		PrepareAndSetVisibilityForAssemblyAndDelivery();
		SetVisibilityOfCommandToFillInContractPriceView();
		FillInParametersOfPriceTypeConnectionAndPriceIncludesVATAttribute();
		NewCommissionAgreement = ThisIsContractForNewCommission(Object.Contract, Object.BusinessOperation);
		
	EndIf;
	
EndProcedure

&AtServer
Procedure SetAvailabilityOfItemsByStatusServer()
	
	ItemArray = New Array;
	
	// Header Controls
	ItemArray.Add("Date");
	ItemArray.Add("Partner");
	ItemArray.Add("Terms");
	ItemArray.Add("Currency");
	ItemArray.Add("PriceIncludesVAT");
	ItemArray.Add("VATTaxation");
	ItemArray.Add("Organization");
	ItemArray.Add("Counterparty");
	ItemArray.Add("Contract");
	ItemArray.Add("Warehouse");
	ItemArray.Add("NotShipInInstallments");
	ItemArray.Add("DateOfShipment");
	ItemArray.Add("ApprovalDate");
	ItemArray.Add("BusinessOperation");
	ItemArray.Add("LoyaltyCard");
	ItemArray.Add("ToReturnReusablePackage");
	ItemArray.Add("ReusablePackageReturnCycleLength");
	ItemArray.Add("PackageDepositIsRequired");
	ItemArray.Add("Department");
	
	// Controls related to the Products table
	ItemArray.Add("GoodsProducts");
	ItemArray.Add("GoodsCharacteristic");
	ItemArray.Add("GoodsNumberOfPackages");
	ItemArray.Add("GoodsPackage");
	ItemArray.Add("GoodsPriceKind");
	ItemArray.Add("GoodsPrice");
	ItemArray.Add("GoodsVATRate");
	ItemArray.Add("GoodsPercentRateOfManualDiscount");
	ItemArray.Add("GoodsManualDiscount");
	ItemArray.Add("GoodsSum");
	ItemArray.Add("GoodsVATAmount");
	ItemArray.Add("GoodsContent");
	
	// Header Controls
	ItemArray.Add("Goods;BeforeAddRow,BeforeDeleteRow;GoodsDateOfShipment,GoodsSupplyOption");
	
	ItemArray.Add("ProductsContextMenuAdd");
	ItemArray.Add("ProductItemsContextMenuCopy");
	ItemArray.Add("GoodsContextMenuDelete");
	
	ItemArray.Add("GoodsAdd");
	ItemArray.Add("GoodsChange");
	ItemArray.Add("GoodsCopy");
	ItemArray.Add("GoodsDelete");
	
	ItemArray.Add("GoodsInsertRows");
	ItemArray.Add("GoodsSplitRow");
	
	ItemArray.Add("GoodsOpenSelection");
	ItemArray.Add("GoodsAddReusablePackage");
	ItemArray.Add("GoodsSearchByBarcode");
	ItemArray.Add("GoodsImportDataFromPDT");
	ItemArray.Add("GoodsFillInTheWarehouseInSelectedLines");
	ItemArray.Add("GoodsImportFromExternalFile");
	ItemArray.Add("GoodsSetComposition");
	ItemArray.Add("GoodsFillInTheDepartment");
	ItemArray.Add("GoodsFillInVATRate");
	
	ItemArray.Add("GoodsFillThePricesByTermsOfSales");
	ItemArray.Add("GoodsFillInPricesOfSelectedRowsByPriceType");
	ItemArray.Add("GoodsFillInPricesUnderAgreement");
	
	ItemArray.Add("ToReadLoyaltyCard");
	ItemArray.Add("ToReadLoyaltyCardClient");
	ItemArray.Add("LoyaltyCard");
	ItemArray.Add("GoodsCalculateDiscountsMarkups");
	ItemArray.Add("GoodsCancelManualDiscounts");
	ItemArray.Add("GoodsAssignAManualDiscount");
	ItemArray.Add("GoodsAssignAManualDiscountToSelectedRows");
	ItemArray.Add("GoodsAssignAutomaticDiscounts");
	ItemArray.Add("GoodsAddPaymentWithBonusPoints");
	ItemArray.Add("GoodsCancelPaymentWithBonusPoints");
	
	TMCommonUse.SetSubscriptionForFormElementChangeEvents(ThisObject, ItemArray);
	
EndProcedure

&AtServer
Procedure SetVisibilityOfElementsByOperationServer()
	
	Var ArrayOfAllProps;
	Var ArrayOfOperationDetails;
	
	Documents.SalesOrder.FillInNamesOfBusinessTransactionDetails(
		Object.BusinessOperation,
		ArrayOfAllProps,
		ArrayOfOperationDetails);
	
	CashServer.SetVisibilityOfElementsByArray(
		Items,
		ArrayOfAllProps,
		ArrayOfOperationDetails);
	
	ThisIsTransferOfGoods = (Object.BusinessOperation = Enums.BusinessTransactions.TransferToCommissionAgent
							Or Object.BusinessOperation = Enums.BusinessTransactions.TransferToStorageWithRightOfSale);
							
	ThisIsSubPrincipalDelivery = Object.BusinessOperation = Enums.BusinessTransactions.DeliveryForPrincipal;
	
	ItemArray = New Array();
	
	ItemArray.Add("DecorationPaymentSteps");
	ItemArray.Add("Calculations");
	ItemArray.Add("DecorationTitlePayment");
	
	TMCommonUseClientServer.SetPropertyOfFormElements(Items, ItemArray, "Visible", Not ThisIsTransferOfGoods);
	
	ItemArray = New Array();
	
	ItemArray.Add("GoodsCalculateDiscountsMarkups");
	ItemArray.Add("GoodsCancelManualDiscounts");
	ItemArray.Add("GoodsAssignAManualDiscount");
	ItemArray.Add("GoodsAssignAManualDiscountToSelectedRows");
	ItemArray.Add("GoodsAssignAutomaticDiscounts");
	ItemArray.Add("GoodsOpenInformationAboutDiscounts");
	ItemArray.Add("TheProductsContextMenuOpensInformationAboutDiscounts");
	ItemArray.Add("ToReadLoyaltyCard");
	ItemArray.Add("ToReadLoyaltyCardClient");
	ItemArray.Add("LoyaltyCard");
	ItemArray.Add("DiscountAmount");
	ItemArray.Add("DecorationIndentDepositRequiredForPackaging");
	TMCommonUseClientServer.SetPropertyOfFormElements(Items, ItemArray, "Visible", Not (ThisIsTransferOfGoods Or ThisIsSubPrincipalDelivery));

	Items.CreditPaymentForm.Visible = Not ThisIsTransferOfGoods And Items.CreditPaymentForm.Visible;
	Items.GoodsFillInTheDepartment.Visible = Not ThisIsSubPrincipalDelivery;
	
	ProductsServer.SetProductSelectionParameters(Object.BusinessOperation, Items.GoodsProducts);
	
	SetVisibilityOfPartnerField();
	
	SalesServer.SetContractAvailability(Object, Items.Contract.Enabled, Items.Contract.Visible,
		Object.Contract);
		
	Items.ToReturnReusablePackage.Enabled = (Not Object.BusinessOperation = Enums.BusinessTransactions.DeliveryForPrincipal);
	Items.TareGroup.Visible                  = Not ((Object.BusinessOperation = Enums.BusinessTransactions.TransferToCommissionAgent And ConsignmentSales25)
														Or (Object.BusinessOperation = Enums.BusinessTransactions.TransferToStorageWithRightOfSale
															And Not Object.ToReturnReusablePackage));
	Items.GroupRequiresADepositForPackaging.Visible  = Not ((Object.BusinessOperation = Enums.BusinessTransactions.TransferToCommissionAgent And ConsignmentSales25)
														Or (Object.BusinessOperation = Enums.BusinessTransactions.TransferToStorageWithRightOfSale
															And Not Object.ToReturnReusablePackage));
	
	SetVisibilityOfCommandToFillInContractPriceView();
	FillInParametersOfPriceTypeConnectionAndPriceIncludesVATAttribute();
	
	SetPropertiesOfOutdatedCommissionUsageComment();
	
EndProcedure

&AtServer
Function FillWarehouseInSelectedLinesOnServer(Val ArrayOfSelectedRows, Warehouse)
	
	FilledWithRows = WarehousesServer.FillInWarehousesInSelectedLines(Object.Goods, ArrayOfSelectedRows, Warehouse);
	
	If FilledWithRows > 0 Then
		
		ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);
	
		WarehousesServer.WhenChangingWarehouseInTablePart(Object.Goods, WarehouseTable, WarehouseGroup_);
		TotalWarehouses_ = WarehouseTable.Count();
		WarehousesClientServer.UpdateWarehouseGroupImage(SeveralWarehousesText, Items.PictureMultipleWarehouses, TotalWarehouses_);
		UpdateColumnAvailableServer();
		
	EndIf;
	
	Return FilledWithRows;
	
EndFunction

&AtServer
Function CancelUndeliveredLinesServer(CancellationReason, Val CheckBalance = False)
	
	AdjustmentStructure = OrdersServer.OrderLineAdjustmentStructure();
	AdjustmentStructure.DocumentObject               = Object;
	AdjustmentStructure.CancellationReason                = CancellationReason;
	AdjustmentStructure.CheckBalance             = CheckBalance;
	AdjustmentStructure.CancelUnprocessedLines = True;
	
	ResultStructure1 = SalesServer.AdjustOrderLines(AdjustmentStructure);
	NumberOfCanceledLines = ResultStructure1.RowsCount;
	
	FillInServiceDetailsForProductRange();
	
	UpdateDuplicateDependentDetails();
	
	If NumberOfCanceledLines > 0 Then
		ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);
		FillInServiceDetailsOfDocumentForm();
		UpdateColumnAvailableServer();
		WhenChangingWarehouseInTablePartServer();
	EndIf;
	
	Return NumberOfCanceledLines;
	
EndFunction

&AtServer
Procedure UpdateAdditionalAttributesItems()
	
	PropertyManager.UpdateAdditionalAttributesItems(ThisForm);
	
EndProcedure

&AtServer
Procedure RefreshStatusServer()
	
	Documents.SalesOrder.CalculateStatus(Object.Ref, Object.Contract, ThisObject);
	Items.State.Hyperlink = AccessRight("View", Metadata.Reports.DocumentFulfillmentStatus);
	
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
	
EndProcedure

&AtServerNoContext
Procedure CalculateStateOfOrder(
			Ref,
			Contract,
			OrderState,
			Hyperlink,
			CheckTasksToReflectStateOfOrders = False)
	
	Documents.SalesOrder.CalculateStatus(
		Ref,
		Contract,
		OrderState,
		CheckTasksToReflectStateOfOrders);
	
	Hyperlink = AccessRight("View", Metadata.Reports.DocumentFulfillmentStatus);
	
EndProcedure

&AtServerNoContext
Function GetDefaultCounterpartyBankAccountServer(Counterparty, OffsettingAccount)
	
	ParametersOfAccount = CashServer.ParametersForFillingInCounterpartySBankAccount(Counterparty);
	ParametersOfAccount.OffsettingAccount = OffsettingAccount;
	
	Return CashServer.GetDefaultCounterpartyBankAccount(ParametersOfAccount);
	
EndFunction

&AtServer
Function GetOrganizationSDefaultBankAccountServer()
	
	ParametersOfAccount = CashServer.ParametersForFillingOutOrganizationSBankAccount(Object.Organization);
	ParametersOfAccount.LineOfBusiness = Object.LineOfBusiness;
	ParametersOfAccount.ExcludeCurrencyAccounts = Object.ForeignCurrencyTransaction;
	ParametersOfAccount.Currency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Object.Organization);
	
	Return CashServer.GetOrganizationSDefaultBankAccount(ParametersOfAccount, Object.BankAccount);
	
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
	
	DiscountsMarkupsFillingClient.ResetDiscountsCalculatedFlag(ThisForm);
	
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
	
	ClearMessages();
	ApplyPaymentWithBonusPointsClient(, True);
	
	ProcessingSelectionOfSelectionOnServer(AdditionalParameters);
	
EndProcedure

&AtServer
Procedure LoyaltyCardReadOnServer(LoyaltyCardDetails)
	
	If ValueIsFilled(LoyaltyCardDetails.Partner) And LoyaltyCardDetails.Partner <> Object.Partner Then
		Object.Partner = LoyaltyCardDetails.Partner;
		Object.Counterparty = Catalogs.Counterparties.EmptyRef();
		Object.Terms = Catalogs.TermsOfSale.EmptyRef();
		PartnerOnChangeServer();
	EndIf;
	If ValueIsFilled(LoyaltyCardDetails.Terms)
		And LoyaltyCardDetails.Terms <> Object.Terms
		And LoyaltyCardDetails.AgreementAvailable Then
		Object.Terms = LoyaltyCardDetails.Terms;
		TermsOnChangeServer(True);
	EndIf;
	If ValueIsFilled(LoyaltyCardDetails.Counterparty)
		And LoyaltyCardDetails.Counterparty <> Object.Counterparty
		And LoyaltyCardDetails.CounterpartyAvailable Then
		Object.Counterparty = LoyaltyCardDetails.Counterparty;
		CounterpartyOnChangeServer();
	EndIf;
	
	UseLoyaltyPrograms = UseLoyaltyPrograms(Object.LoyaltyCard);
	SetVisibilityOfElementsOfLoyaltyBonusProgram();
	
EndProcedure

&AtServerNoContext
Function UseLoyaltyPrograms(LoyaltyCard)
	
	If Not ValueIsFilled(LoyaltyCard) Then
		Return False;
	EndIf;
	
	Return DiscountsMarkupsServer.UseLoyaltyPrograms(LoyaltyCard);
	
EndFunction

&AtClient
Procedure LoyaltyCardIsRead(Val Notification, LoyaltyCard)
	
	LoyaltyCardDetails = LoyaltyCardServerCall.GetLoyaltyCardDetails(LoyaltyCard);
	If ValueIsFilled(LoyaltyCardDetails.Ref) Then
		
		If Not LoyaltyCardDetails.PartnerAvailable Then
			ShowMessageBox(New CallbackDescription("LoyaltyCardIsReadCompletion", ThisObject, New Structure("Notification", Notification)), NStr("vi = 'Không có quyền truy cập vào đối tác giữ thẻ khách hàng thân thiết.';
																																				|ru = 'Нет доступа к партнеру-владельцу карты лояльности.';
																																				|en = 'No access to the partner who holds the loyalty card.'; fa = 'No access to the partner who holds the loyalty card.';
																																				|it = 'Nessun accesso al partner-titolare della carta fedeltà.';
																																				|pl = 'Brak dostępu do partnera-posiadacza karty lojalnościowej.';
																																				|tr = 'Sadakat kart sahibi iş ortağına erişim yok.'"));
			Return;
		EndIf;
		
		If Not ValueIsFilled(LoyaltyCardDetails.Partner) Then // Depersonalized card
			
			If Object.LoyaltyCard <> LoyaltyCard Then
				ApplyPaymentWithBonusPoints(Undefined);
			EndIf;
			
			DiscountsMarkupsFillingClient.ResetDiscountsCalculatedFlag(ThisForm);
			Modified = True;
			Object.LoyaltyCard   = LoyaltyCard;
			
			RunCallback(Notification);
			Return;
			
		ElsIf Object.Partner <> LoyaltyCardDetails.Partner Then // The partner in the map is different from the partner in the document.
			
			If ValueIsFilled(Object.Partner) Then
				
				AdditionalParameters = New Structure;
				AdditionalParameters.Insert("Notification", Notification);
				AdditionalParameters.Insert("LoyaltyCard", LoyaltyCard);
				AdditionalParameters.Insert("LoyaltyCardDetails", LoyaltyCardDetails);
				ShowQueryBox(
					New CallbackDescription("LoyaltyCardReadQuestionCompletion", ThisObject, AdditionalParameters),
					StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = 'Thẻ khách hàng thân thiết trực thuộc bạn hàng ""%1"". Thay đổi bạn hàng trong chứng từ?';
																					|ru = 'Карта лояльности принадлежит партнеру ""%1"". Изменить партнера в документе?';
																					|en = 'The loyalty card belongs to partner ""%1"". Change the partner in the document?'; fa = 'The loyalty card belongs to partner ""%1"". Change the partner in the document?';
																					|it = 'La carta fedeltà appartiene al partner ""%1"". Sostituire il partner nel documento?';
																					|pl = 'Karty lojalnościowa należy do partnera ""%1"". Czy zmienic partnera w dokumencie?';
																					|tr = 'Sadakat kartı ""%1"" adlı iş ortağına aittir. Belgedeki ortak değiştirilsin mi?'"), LoyaltyCardDetails.Partner),
					QuestionDialogMode.YesNo);
				Return;
			EndIf;
			
		Else // The partner in the document is equal to the partner in the map.
			
			QuestionOfChangingCounterparty = False;
			If ValueIsFilled(LoyaltyCardDetails.Counterparty)
				And ValueIsFilled(Object.Counterparty) And LoyaltyCardDetails.Counterparty <> Object.Counterparty Then
				
				QuestionOfChangingCounterparty = True;
			EndIf;
			
			QuestionOfChangingAgreement = False;
			If ToUseTermsOfSales And ValueIsFilled(LoyaltyCardDetails.Terms)
				And ValueIsFilled(Object.Terms) And LoyaltyCardDetails.Terms <> Object.Terms Then
				QuestionOfChangingAgreement = True;
			EndIf;
			
			If QuestionOfChangingCounterparty Or QuestionOfChangingAgreement Then
				
				If QuestionOfChangingCounterparty And QuestionOfChangingAgreement Then
					QueryText = NStr("vi = 'Đối với thẻ khách hàng thân thiết đã đặt đối tác ""%1"" và thỏa thuận ""%2"". Áp dụng thẻ khách hàng thân thiết và đặt vào chứng từ đối tác ""%1"" và thỏa thuận ""%2""?';
									|ru = 'Для карты лояльности заданы контрагент ""%1"" и соглашение ""%2"". Применить карту лояльности и подставить в документ контрагента ""%1"" и соглашение ""%2""?';
									|en = 'Counterparty ""%1"" and agreement ""%2"" are specified for the loyalty card. Apply the loyalty card and substitute counterparty ""%1"" and agreement ""%2"" to the document?'; fa = 'Counterparty ""%1"" and agreement ""%2"" are specified for the loyalty card. Apply the loyalty card and substitute counterparty ""%1"" and agreement ""%2"" to the document?';
									|it = 'Per la carta fedeltà sono impostati il contraente ""%1"" e il contratto ""%2"". Applicare la carta fedeltà ed impostare nel documento il contraente ""%1"" e il contratto ""%2""?';
									|pl = 'Dla karty lojalnościowej jest ustawiony kontrahent ""%1"" i porozumienie ""%2"". Zastosować kartę lojalnościową i wstawić do dokumentu kontrahenta ""%1"" i porozumienia ""%2""?';
									|tr = 'Sadakat kartına ""%1"" cari hesabı ve ""%2"" anlaşması atanmıştır. Sadakat kartı uygulansın ve belgede ""%1""cari hesabı ve ""%2"" anlaşması değiştirilsin mi?'");
				ElsIf QuestionOfChangingCounterparty Then
					QueryText = NStr("vi = 'Đối với thẻ khách hàng thân thiết đã chỉ ra đối tác ""%1"". Áp dụng thẻ khách hàng thân thiết và điền vào chứng từ đối tác ""%1""?';
									|ru = 'Для карты лояльности задан контрагент ""%1"". Применить карту лояльности и подставить в документ контрагента ""%1""?';
									|en = 'Counterparty ""%1"" is specified for the loyalty card. Apply the loyalty card and substitute counterparty ""%1"" to the document?'; fa = 'Counterparty ""%1"" is specified for the loyalty card. Apply the loyalty card and substitute counterparty ""%1"" to the document?';
									|it = 'Per la carta fedeltà è impostato il contraente ""%1"". Applicare la carta fedeltà ed impostare nel documento il contraente ""%1""?';
									|pl = 'Dla karty lojalnościowej jest ustawiony kontrahent ""%1"". Zastosować kartę lojalnościową i wstawić do dokumentu kontrahenta ""%1""?';
									|tr = 'Sadakat kartına ""%1"" cari hesabı ayarlanmıştır. Sadakat kartı uygulansın ve belgede ""%1"" cari hesabı değiştirilsin mi?'");
				ElsIf QuestionOfChangingAgreement Then
					QueryText = NStr("vi = 'Đối với thẻ khách hàng thân thiết đã đặt thỏa thuận ""%2"". Áp dụng thẻ khách hàng thân thiết và đặt vào chứng từ thỏa thuận ""%2""?';
									|ru = 'Для карты лояльности задано соглашение ""%2"". Применить карту лояльности и подставить в документ соглашение ""%2""?';
									|en = 'Agreement ""%2"" is specified for the loyalty card. Apply the loyalty card and substitute agreement ""%2"" to the document?'; fa = 'Agreement ""%2"" is specified for the loyalty card. Apply the loyalty card and substitute agreement ""%2"" to the document?';
									|it = 'Per la carta fedeltà è impostato il contratto ""%2"". Applicare la carta fedeltà ed impostare nel documento il contratto ""%2""?';
									|pl = 'Dla karty lojalnościowej jest ustawione pozorumienie ""%2"". Zastosować kartę lojalnościową i wstawić do dokumentu pozorumienie ""%2""?';
									|tr = 'Sadakat kartı ""%2"" anlaşmasına ayarlanmıştır. Sadakat kartı uygulansın ve belgede ""%2"" anlaşması değiştirilsin mi?'");
				EndIf;
				
				AdditionalParameters = New Structure;
				AdditionalParameters.Insert("Notification", Notification);
				AdditionalParameters.Insert("LoyaltyCard", LoyaltyCard);
				AdditionalParameters.Insert("LoyaltyCardDetails", LoyaltyCardDetails);
				ShowQueryBox(
					New CallbackDescription("LoyaltyCardReadQuestionCompletion", ThisObject, AdditionalParameters),
					StringFunctionsClientServer.SubstituteParametersToString(QueryText, LoyaltyCardDetails.Counterparty, LoyaltyCardDetails.Terms),
					QuestionDialogMode.YesNo);
				Return;
				
			EndIf;
			
		EndIf;
		
		DiscountsMarkupsFillingClient.ResetDiscountsCalculatedFlag(ThisForm);
		Modified = True;
		Object.LoyaltyCard   = LoyaltyCard;
		LoyaltyCardReadOnServer(LoyaltyCardDetails);
		
	Else
		
		UseLoyaltyPrograms = UseLoyaltyPrograms(Undefined);
		ClearMessages();
		ApplyPaymentWithBonusPointsClient(, True);
		SetVisibilityOfElementsOfLoyaltyBonusProgram();
		
	EndIf;
	
	RunCallback(Notification);

EndProcedure

&AtClient
Procedure LoyaltyCardReadQuestionCompletion(Response, AdditionalParameters) Export
	
	If Response = DialogReturnCode.No Then
		
		UseLoyaltyPrograms = UseLoyaltyPrograms(Object.LoyaltyCard);
		SetVisibilityOfElementsOfLoyaltyBonusProgram();
		
		RunCallback(AdditionalParameters.Notification);
		
	ElsIf Response = DialogReturnCode.Yes Then
		
		DiscountsMarkupsFillingClient.ResetDiscountsCalculatedFlag(ThisForm);
		Modified = True;
		Object.LoyaltyCard   = AdditionalParameters.LoyaltyCard;
		LoyaltyCardReadOnServer(AdditionalParameters.LoyaltyCardDetails);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure LoyaltyCardIsReadCompletion(AdditionalParameters) Export
    
    Notification = AdditionalParameters.Notification;
    
    
    RunCallback(Notification);

EndProcedure

&AtServer
Function AddressOfDataForCalculatingManualDiscountsInTemporaryStorage(SelectedLinesOnly)
	
	ParametersStructure = DiscountsMarkupsFillingServer.NewParametersAddressDataForCalculatingManualDiscounts();
	ParametersStructure.TableName = "Goods";
	ParametersStructure.OnlyForSelectedLines = SelectedLinesOnly;
	Return DiscountsMarkupsFillingServer.AddressOfDataForCalculatingManualDiscountsInTemporaryStorage(
		ThisForm, UUID, ParametersStructure);
	
EndFunction

&AtClient
Procedure LabelPaymentStagesClick(Item, StandardProcessing)
	
	Notification = New CallbackDescription("LabelPaymentStagesClickCompletion", ThisObject);
	PlacePaymentStepsInTemporaryStorage(Item.Name);
	ARAPAccountingClient.LabelPaymentStagesClick(ThisForm, Item, StandardProcessing, Notification);
	
EndProcedure

&AtServer
Procedure PlacePaymentStepsInTemporaryStorage(TagName)
	PaymentStepsServer.PlacePaymentStepsInTemporaryStorage(ThisForm, TagName);
EndProcedure

&AtClient
Procedure LabelPaymentStagesClickCompletion(Result, AdditionalParameters) Export
	
	If Result <> Undefined Then
		
		ChangedBankingDetails = Result.OldValuesOfChangedProps;
		ReflectChangesToPaymentRules(ChangedBankingDetails);
		
		If ChangedBankingDetails.Count() > 0 Then
			If ChangedBankingDetails.Property("PaymentMethod") Then
				DiscountsMarkupsFillingClient.ResetDiscountsCalculatedFlag(ThisForm);
			EndIf;
		EndIf;
		
	EndIf;
	
	CalculateOrderTotals(ThisForm);
	
EndProcedure

&AtServer
Function PutItInTemporaryStorageOnServer(TSName,Id = "")
	Return PutToTempStorage(Object[TSName].Unload(),Id);
EndFunction

&AtServer
Procedure FillIn_TermsOfSales()
	
	DocumentSales = FormAttributeToValue("Object");
	DocumentSales.FillInDefaultSalesConditions();
	ValueToFormAttribute(DocumentSales, "Object");
	
	If ToUseTermsOfSales And ValueIsFilled(Object.Terms) Then
		
		DocumentCurrency = Object.Currency;
		PartnersAndCounterparties.FillInPartnerSDefaultCounterparty(Object.Partner, Object.Counterparty);
		BusinessOperationOnChangeServer();
		
	EndIf;
	
	FillOperationSelectionList();
	SalesServer.SetContractAvailability(Object, Items.Contract.Enabled, Items.Contract.Visible, Object.Contract);
	
EndProcedure

&AtClientAtServerNoContext
Procedure UpdateAvailabilityOfReturnContainerItems(Form)
	
	ItemArray = New Array();
	ItemArray.Add("ReusablePackageReturnCycleLength");
	ItemArray.Add("PackageDepositIsRequired");
	
	TMCommonUseClientServer.SetPropertyOfFormElements(
		Form.Items,
		ItemArray,
		"Enabled",
		Form.Object.ToReturnReusablePackage);
	
EndProcedure

&AtServer
Procedure FillMultiTurnContainersFromStorageServer(AddressOfContainerInStorage)
	
	CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	
	ActionStructureModifiedStrings = New Structure;
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	ActionStructureModifiedStrings.Insert("RecalculateNumberOfPackages");
	ActionStructureModifiedStrings.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
	ActionStructureModifiedStrings.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));
	ParametersForFillingInVATRate = BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRate(Object, True);
	If Object.NotShipInInstallments And ValueIsFilled(Object.DateOfShipment) Then
		ParametersForFillingInVATRate.Date = Object.DateOfShipment;
	EndIf;
	ActionStructureModifiedStrings.Insert("FillInVATRate", ParametersForFillingInVATRate);
	ActionStructureModifiedStrings.Insert("FillInVATRateByPriceType", BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRateByPriceType(Object, True));
	ActionStructureModifiedStrings.Insert("FillInVATRateForReturnableContainers", Object.ToReturnReusablePackage);
	ActionStructureModifiedStrings.Insert("FillInNoReturnContainerAttribute", Object.ToReturnReusablePackage);
	ActionStructureModifiedStrings.Insert("FillInCanceledWithoutReturnableContainerAttribute", Object.ToReturnReusablePackage);
	ActionStructureModifiedStrings.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	ActionStructureModifiedStrings.Insert("RecalculateAmount");
	ActionStructureModifiedStrings.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	ActionStructureModifiedStrings.Insert("RecalculateAmountTakingIntoAccountManualDiscount", New Structure("Clear", True));
	ActionStructureModifiedStrings.Insert("RecalculateAmountTakingIntoAccountAutomaticDiscount", New Structure("Clear", True));
	ActionStructureModifiedStrings.Insert("FillInDuplicateDependentDetails", DependentDetails());
	
	StructureOfActionsAddedLines =  CommonClientServer.CopyStructure(ActionStructureModifiedStrings);;
	StructureOfActionsAddedLines.Insert("CheckFillWarehouse", BatchProcessingOfTablePartClientServer.GetWarehouseFillStructureInTSLine(Object, WarehouseGroup_));
	StructureOfActionsAddedLines.Insert("FillInSalesOptionAttribute", New Structure("Products", "SaleRegistrationOption"));
	If (ToUseTermsOfSales And ValueIsFilled(Object.Terms)) 
		Or (Not ToUseTermsOfSales And UsePriceManagementSystem25) Then
		StructureOfActionsAddedLines.Insert("FillIn_TermsOfSales", BatchProcessingOfTablePartClientServer.GetStructureForFillingInSalesConditionsInTSLine(Object));
	Else
		StructureOfActionsAddedLines.Insert("FillInSalePrice", BatchProcessingOfTablePartClientServer.ParametersForFillingInPriceInTSLine(Object));
	EndIf;
	StructureOfActionsAddedLines.Insert("FillInContent", BatchProcessingOfTablePartClientServer.GetStructureOfFillingInServiceContentInTSLine(Object, False));
	StructureOfActionsAddedLines.Insert("FillInSubdivisionInTSLine", New Structure("Department", Object.Department));
	AddCollateralActionsOnServer(StructureOfActionsAddedLines,
		"SupplyOption,WarehouseIsRequired,DateOfShipmentRequired_");
	
	ReusablePackageServer.FillMultiTurnContainersFromStorage(
		Object,
		AddressOfContainerInStorage,
		"Goods",
		"Products,Characteristic,Warehouse,DateOfShipment",
		ActionStructureModifiedStrings,
		StructureOfActionsAddedLines,
		CachedValues);
	
	FillInServiceDetailsForProductRange();
	
	WarehousesServer.WhenChangingWarehouseInTablePart(Object.Goods, WarehouseTable, WarehouseGroup_);
	TotalWarehouses_ = WarehouseTable.Count();
	WarehousesClientServer.UpdateWarehouseGroupImage(SeveralWarehousesText, Items.PictureMultipleWarehouses, TotalWarehouses_);
	
	CalculateOrderTotals(ThisForm);
	UpdateColumnAvailableServer();

EndProcedure

&AtServer
Procedure UpdateDuplicateDependentDetails()
	
	StructureOfAdditionalActions = New Structure;
	StructureOfAdditionalActions.Insert("FillInCanceledWithoutReturnableContainerAttribute", Object.ToReturnReusablePackage);
	ReusablePackageServer.UpdateNoReturnableContainerAttribute(Object.Goods, Object.ToReturnReusablePackage, StructureOfAdditionalActions);
	TMCommonUse.FillInDuplicateDependentPropsInCollection(Object.Goods, DependentDetails());
	
EndProcedure

&AtServer
Procedure SetSoftwareVisibility()
	
	HasRight = ProvisionInDocumentsServer.HaveRightToViewStateHyperlink();
	Items.PagesHyperlinkSoftwareStatus.Visible = HasRight And UseShipmentByRowsInSalesOrder;
	ProvisionInDocumentsServer.ConfigureHyperlinkedSoftwareState(ThisObject);
	Items.DateOfShipment.ToolTip = ProvisionInDocumentsServer.HintShipmentDate();
	
	If Not AccessRight("Insert", Metadata.Documents.InventoryAssignmentAdjustment)
		Or Not GetFunctionalOption("UseOrderSupplyWithAssignment") 
		Or Object.ThisIsOrderAsInvoice 
		Or Not UseShipmentByRowsInSalesOrder Then
		Items.GoodsCreateAssignmentAdjustmentRemoveFromReserve.Visible = False;
		Items.GoodsCreateAnAssignmentAdjustmentReservation.Visible = False;
	EndIf;
	
	YouCanRemoveFlagSeparately = Object.BusinessOperation <> PredefinedValue("Enum.BusinessTransactions.DeliveryForPrincipal");
	FlagManagement = UseShipmentByRowsInSalesOrder And YouCanRemoveFlagSeparately;
	FlagVisibility = UseShipmentByRowsInSalesOrder;
	CommonClientServer.SetFormItemProperty(
		Items,
		"GoodsEnableStandAloneSoftware",
		"Visible",
		FlagManagement);
	CommonClientServer.SetFormItemProperty(
		Items,
		"GoodsDisableStandAloneSoftware",
		"Visible",
		FlagManagement);
	CommonClientServer.SetFormItemProperty(
		Items,
		"GoodsWithAssignment",
		"Visible",
		FlagVisibility);
	CommonClientServer.SetFormItemProperty(
		Items,
		"GoodsWithAssignment",
		"Enabled",
		FlagManagement);
		
	SecurityVisibility = UseShipmentByRowsInSalesOrder And Not Object.ThisIsOrderAsInvoice;
	CommonClientServer.SetFormItemProperty(
		Items,
		"NotShipInInstallments",
		"Visible",
		SecurityVisibility);
	CommonClientServer.SetFormItemProperty(
		Items,
		"GoodsSupplyOption",
		"Visible",
		SecurityVisibility);
	CommonClientServer.SetFormItemProperty(
		Items,
		"GoodsAvailable",
		"Visible",
		SecurityVisibility);
	
	CommonClientServer.SetFormItemProperty(
		Items,
		"GoodsToSupply",
		"Visible",
		SecurityVisibility);
	CommonClientServer.SetFormItemProperty(
		Items,
		"GoodsContextMenuToSupply",
		"Visible",
		SecurityVisibility);
		
	CommonClientServer.SetFormItemProperty(
		Items,
		"GoodsNotProvide",
		"Visible",
		SecurityVisibility);
	CommonClientServer.SetFormItemProperty(
		Items,
		"GoodsContextMenuNotProvide",
		"Visible",
		SecurityVisibility);
		
	CommonClientServer.SetFormItemProperty(
		Items,
		"GoodsShip",
		"Visible",
		SecurityVisibility);
	CommonClientServer.SetFormItemProperty(
		Items,
		"GoodsContextMenuShip",
		"Visible",
		SecurityVisibility);
		
	CommonClientServer.SetFormItemProperty(
		Items,
		"GoodsToReserve_",
		"Visible",
		SecurityVisibility);
	CommonClientServer.SetFormItemProperty(
		Items,
		"GoodsContextMenuToReserve_",
		"Visible",
		SecurityVisibility);
	
	CommonClientServer.SetFormItemProperty(
		Items,
		"GoodsReserveAsReceived",
		"Visible",
		SecurityVisibility);
	CommonClientServer.SetFormItemProperty(
		Items,
		"GoodsContextMenuReserveAsReceived",
		"Visible",
		SecurityVisibility);
		
EndProcedure

&AtServer
Procedure SetVisibilityOfShipmentBanToPartner()
	
	SegmentsServer.SetVisibilityOfShipmentBanToPartner(Object.Partner, Items);
	
EndProcedure

&AtServer
Procedure GetUploadedProductsFromStorage(GoodsAddressInStorage)

	ApplyPaymentWithBonusPoints(, True);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("CheckFillWarehouse", BatchProcessingOfTablePartClientServer.GetWarehouseFillStructureInTSLine(Object, WarehouseGroup_));
	StructureOfActions.Insert("FillInVATRateForReturnableContainers", Object.ToReturnReusablePackage);
	StructureOfActions.Insert("FillInNoReturnContainerAttribute", Object.ToReturnReusablePackage);
	StructureOfActions.Insert("FillInCanceledWithoutReturnableContainerAttribute", Object.ToReturnReusablePackage);
	StructureOfActions.Insert("FillInContent", BatchProcessingOfTablePartClientServer.GetStructureOfFillingInServiceContentInTSLine(Object, False));
	StructureOfActions.Insert("FillInSalesOptionAttribute", New Structure("Products", "SaleRegistrationOption"));
	If Object.BusinessOperation <> Enums.BusinessTransactions.DeliveryForPrincipal Then
		StructureOfActions.Insert("FillInSubdivisionInTSLine", New Structure("Department", Object.Department));
	EndIf;
	AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions,Object);
	AddCollateralActionsOnServer(StructureOfActions,
		"SupplyOption,WarehouseIsRequired,DateOfShipmentRequired_");
	
	CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	RowsToProcess = New Array();
	
	ItemsFromStorage = GetFromTempStorage(GoodsAddressInStorage);
	
	For Each RowOfGoods In ItemsFromStorage Do
		StringTSGoods = Object.Goods.Add();
		FillPropertyValues(StringTSGoods, RowOfGoods,,"RowCode");
		If Object.NotShipInInstallments Then
			StringTSGoods.DateOfShipment = Object.DateOfShipment;
		EndIf;
		RowsToProcess.Add(StringTSGoods);
	EndDo;
	
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		RowsToProcess,
		StructureOfActions,
		Object.Goods,
		CachedValues);
	
	ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);
	UpdateColumnAvailableServer();
	
	WarehousesServer.WhenChangingWarehouseInTablePart(Object.Goods, WarehouseTable, WarehouseGroup_);
	TotalWarehouses_ = WarehouseTable.Count();
	WarehousesClientServer.UpdateWarehouseGroupImage(SeveralWarehousesText, Items.PictureMultipleWarehouses, TotalWarehouses_);
	
	CalculateOrderTotals(ThisForm);
	ReusablePackageServer.UpdateFillingStateOfMultiTurnContainer(Object.ReusablePackageFillingStatus);
	
EndProcedure

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

&AtClient
Procedure GoodsBeforeAddRow(Item, Cancel, Copy, Parent, Var_Group)
	
	If Copy Then
		SetsClient.BeforeDeletingRowOfTablePart(ThisForm, "Goods", Cancel, True);
	EndIf;
	
	DiscountsMarkupsFillingClient.ResetDiscountsCalculatedFlag(ThisForm);
	
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
	KitParameters.Insert("ProductsInSet", CurrentRow.ProductsInSet);
	KitParameters.Insert("ItemVariantOfSet", CurrentRow.ItemVariantOfSet);
	KitParameters.Insert("DialColumns", DialColumns(ThisForm));
	
	SetAddressInTemporaryStorage = SetAddressInTemporaryStorage(KitParameters);
	
	OpeningParameters = New Structure;
	OpeningParameters.Insert("AddressInTempStorage", SetAddressInTemporaryStorage);
	OpeningParameters.Insert("ProductsInSet", CurrentRow.ProductsInSet);
	OpeningParameters.Insert("ItemVariantOfSet", CurrentRow.ItemVariantOfSet);
	OpeningParameters.Insert("PriceIncludesVAT", Object.PriceIncludesVAT);
	OpeningParameters.Insert("VATTaxation", Object.VATTaxation);
	OpeningParameters.Insert("Currency", Object.Currency);
	OpeningParameters.Insert("Partner", Object.Partner);
	OpeningParameters.Insert("Terms", Object.Terms);
	OpeningParameters.Insert("Date", Object.Date);
	OpeningParameters.Insert("Ref", Object.Ref);
	OpeningParameters.Insert("Warehouse", Object.Warehouse);
	OpeningParameters.Insert("Organization", Object.Organization);
	OpeningParameters.Insert("HideCommandRemainingQuantityInWarehouses", False);
	
	OpenForm("DataProcessor.EditSet.Form.Form", OpeningParameters, ThisForm, UUID);
	
EndProcedure

&AtClient
Procedure SetupSubscriptionToNotifications(Command)
	
	MailoutsAndNotificationsToCustomersClient.SubscribeToAlertsFromPlace(
		Object.Partner,
		PredefinedValue("Enum.NotificationEventTypes.OrderStatusChange"));
	
EndProcedure

&AtServer
Procedure FillOperationSelectionList(SetOperation = True)
	
	If Not ToUseTermsOfSales Then
		SaleWithDeferredTransferOfTitleIsAllowed = UseShipmentWithDeferredTransferOfTitle;
	ElsIf Not ValueIsFilled(Object.Terms) Then
		SaleWithDeferredTransferOfTitleIsAllowed = False;
	Else
		SetPrivilegedMode(True);
		SaleWithDeferredTransferOfTitleIsAllowed = 
			TMCommonUse.ValueOfBooleanObjectSProps(Object.Terms, "SaleWithDeferredTransferOfTitleIsAllowed");
		SetPrivilegedMode(False);
	EndIf;
	
	If Items.Find("BusinessOperation") <> Undefined  Then
	
		If Not GetFormFunctionalOption("UseSalesCommission") Then
			
			ListItem = Items.BusinessOperation.ChoiceList.FindByValue(Enums.BusinessTransactions.TransferToCommissionAgent);
			
			If ListItem <> Undefined Then
				Items.BusinessOperation.ChoiceList.Delete(ListItem);
			EndIf;
			
		EndIf;
		
		If Not ToUseTheTransferOfGoodsToStorage Then
			ListItem = Items.BusinessOperation.ChoiceList.FindByValue(
				Enums.BusinessTransactions.TransferToStorageWithRightOfSale);
			
			If ListItem <> Undefined Then
				Items.BusinessOperation.ChoiceList.Delete(ListItem);
			EndIf;
		EndIf;
		
		ListItem = Items.BusinessOperation.ChoiceList.FindByValue(
			Enums.BusinessTransactions.SaleWithDeferredTransferOfTitle);

		If Not SaleWithDeferredTransferOfTitleIsAllowed
			Or Not UseShipmentWithDeferredTransferOfTitle Then
			
			If ListItem <> Undefined Then
				Items.BusinessOperation.ChoiceList.Delete(ListItem);
			EndIf;	
								
		Else	
			
			If ListItem = Undefined Then
				Items.BusinessOperation.ChoiceList.Add(
					Enums.BusinessTransactions.SaleWithDeferredTransferOfTitle);
			EndIf;
			
		EndIf;	
		
		If Not ProvideAgentServicesOnPurchaseToPrincipals Then
			ListItem = Items.BusinessOperation.ChoiceList.FindByValue(
				Enums.BusinessTransactions.DeliveryForPrincipal);

			If ListItem <> Undefined Then
				Items.BusinessOperation.ChoiceList.Delete(ListItem);
			EndIf;	
		EndIf;
			
		OnlyOperation = Items.BusinessOperation.ChoiceList.Count() = 1;
		If SetOperation And OnlyOperation And Not ValueIsFilled(Object.BusinessOperation) Then
			Object.BusinessOperation = Items.BusinessOperation.ChoiceList[0].Value;
			BusinessOperationOnChangeServer();
		EndIf;
		
		TMCommonUseClientServer.SetFormItemProperty(
			Items,
			"BusinessOperation",
			"ReadOnly",
			OnlyOperation And ValueIsFilled(Object.BusinessOperation));
		
	EndIf;
	
EndProcedure

&AtServer
Procedure SetParametersForSelectingProductsWarehouse()
	
	Items.GoodsWarehouse.ChoiceParameters = New FixedArray(New Array);
	TMCommonUseClientServer.AddSelectionParameter(Items.GoodsWarehouse, "Ref", WarehouseSelectionData(Object.Warehouse));

EndProcedure

&AtServer
Procedure FillInFinancialAccountingGroup()
	
	If ValueIsFilled(Object.Contract) Then
		Object.FinancialAccountingGroup = Common.ObjectAttributeValue(Object.Contract, "FinancialAccountingGroup");
	EndIf;
	
EndProcedure

&AtServer
Procedure AdjustOrderLines(StructureOfAdditionalParameters)
	
	OrderLineAdjustmentStructure = OrdersServer.OrderLineAdjustmentStructure();
	FillPropertyValues(OrderLineAdjustmentStructure, StructureOfAdditionalParameters);
	
	DocumentSales = FormAttributeToValue("Object");
	
	OrderLineAdjustmentStructure.DocumentObject   = DocumentSales;
	OrderLineAdjustmentStructure.CheckBalance = 
		Not (DocumentSales.Status = Enums.SalesOrderStatuses.NotApproved);
	
	ResultStructure1 = SalesServer.AdjustOrderLines(OrderLineAdjustmentStructure);
	
	If ResultStructure1.RowsCount <> 0 Or ResultStructure1.AdjustmentSum > 0 Then
		
		AmountOrdered       = DocumentSales.GetSumOfOrderedRows();
		PackageDepositValue   = DocumentSales.GetSumOfOrderedRows(True);
		
		PaymentStepsServer.CheckAndFillInPaymentScheduleStages(DocumentSales);
		
		PaymentStepsServer.DistributeAmountOfDeviationByStagesOfPaymentSchedule(
							DocumentSales.PaymentScheduleSteps,
							ResultStructure1.AdjustmentSum);
		
	EndIf;
	
	If StructureOfAdditionalParameters.CloseOrders Then
		DocumentSales.Status = Enums.SalesOrderStatuses.Closed;
	EndIf;
	
	ValueToFormAttribute(DocumentSales, "Object");
	
	FillInServiceDetailsForProductRange();
	FillInServiceDetailsOfDocumentForm();
	UpdateDuplicateDependentDetails();
	
	CalculateOrderTotals(ThisForm);
	Modified = True;
	
EndProcedure

&AtServer
Procedure FillInSalesVATTaxation()
	
	FillParameters = Documents.SalesOrder.ParametersForFillingInSalesVATTaxation(Object);
	VATAccountingERP.FillInSalesVATTaxation(Object.VATTaxation, FillParameters, VATAccountingCachedParameterValues);
	VATAccountingERP.FillInSalesVATTaxSelectionList(Items.VATTaxation, Object.VATTaxation, FillParameters, VATAccountingCachedParameterValues); 
	
EndProcedure

&AtServer
Procedure FillInSalesVATTaxSelectionList()
	
	FillParameters = Documents.SalesOrder.ParametersForFillingInSalesVATTaxation(Object);
	VATAccountingERP.FillInSalesVATTaxSelectionList(Items.VATTaxation, Object.VATTaxation, FillParameters, VATAccountingCachedParameterValues); 
	
EndProcedure

&AtServer
Procedure PaymentCreditedServer(EventName, Parameter, Source)
	
	RefreshStatusServer();
	ARAPAccountingFormWork.NotificationProcessing(ThisForm, EventName, Parameter);
	
EndProcedure

&AtServer
Function DefaultSecurityOption()
	
	OptionAndFlag = Undefined;
	If Object.BusinessOperation = Enums.BusinessTransactions.DeliveryForPrincipal Then
		OptionAndFlag = New Structure("SupplyOption,WithAssignment", Enums.SupplyOptions.ToSupply, True);
	EndIf;
	Return OptionAndFlag;
	
EndFunction

&AtServer
Procedure FillInListOfSelectedBusinessOperations(UsingAgencyProcurementScheme)
	
	Operations = Documents.SalesOrder.BusinessOperationsOfDocument(True);
	If Object.ThisIsOrderAsInvoice Then
		DeliveryForPrincipal = Operations.Find(Enums.BusinessTransactions.DeliveryForPrincipal);
		If ValueIsFilled(DeliveryForPrincipal) Then
			Operations.Delete(DeliveryForPrincipal);
		EndIf;
	EndIf;
	Items.BusinessOperation.ChoiceList.Clear();
	Items.BusinessOperation.ChoiceList.LoadValues(Operations);
	
	OperationSelectionParameter = New ChoiceParameter("Filter.BusinessOperation", New FixedArray(Operations));
	ParametersArray = New Array;
	ParametersArray.Add(OperationSelectionParameter);
	Items.Terms.ChoiceParameters = New FixedArray(ParametersArray);
	
EndProcedure

&AtClient
Procedure FillInVATRateCompletion(VATRate, AdditionalParameters) Export

	If VATRate = Undefined Then
		Return;
	EndIf;

	ClearMessages();
	ApplyPaymentWithBonusPointsClient(, True);

	FillInVATRateOnServer(VATRate, CachedValues);

	CalculateOrderTotals(ThisObject);
	
	DiscountsMarkupsFillingClient.ResetDiscountsCalculatedFlag(ThisObject);

EndProcedure

&AtServer
Procedure FillInVATRateOnServer(VATRate, CachedValues)

	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);

	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmount");
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountManualDiscount", New Structure("Clear", False));
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountAutomaticDiscount", New Structure("Clear", True));
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountDiscountWithBonusPoints");
	StructureOfActions.Insert("FillInDuplicateDependentDetails", DependentDetails());

	SelectedRows = ProcessingOfTabularFormsClientServer.CollectionItems(
		Object.Goods, Items.Goods.SelectedRows);
	RowsToDelete = New Array;
	For Each LineOfATabularSection In SelectedRows Do
		If Object.ToReturnReusablePackage
			And LineOfATabularSection.ItemsType = Enums.ItemsTypes.ReusablePackage Then
			RowsToDelete.Add(LineOfATabularSection);
			Continue;
		EndIf;
		LineOfATabularSection.VATRate = VATRate;
	EndDo;
	For Each LineToDelete In RowsToDelete Do
		SelectedRows.Delete(SelectedRows.Find(LineToDelete));
	EndDo;
	
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		SelectedRows,
		StructureOfActions,
		Object.Goods,
		CachedValues);

EndProcedure

&AtServer
Procedure InitiateReceiptOfDocumentsBasedOn()
	
	BackgroundJobDataGettingDocumentsBasedOn = SalesServer.GettingTextsOfDocumentFieldsBasedOnBackground(ThisObject, Object);
	
EndProcedure

&AtClient
Procedure UpdateTextDocumentsBasedOn(BackgroundJobResult, AdditionalParameters) Export
	
	If BackgroundJobResult = Undefined Then
		Return;
	EndIf;
	
	If BackgroundJobResult.Status = "Completed2" Then
		
		TextsFieldsDocumentsBasedOn.Clear();
		
		If ValueIsFilled(Object.Ref) Then
			
			Result = GetFromTempStorage(BackgroundJobResult.ResultAddress);
			
			If ValueIsFilled(Result) And TypeOf(Result) = Type("Structure") And Result.Property("DocumentsBasedOn")
				And Result.Property("TextsFieldsDocumentsBasedOn") Then
				
				DocumentsBasedOn = Result.DocumentsBasedOn;
				TextsFieldsDocumentsBasedOn = Result.TextsFieldsDocumentsBasedOn;
				TMCommonUseClientServer.UpdateTextDocumentsBasedOn(ThisObject);
				RefreshDataRepresentation(Items.TextDocumentsBasedOn);
				
			EndIf;
			
		EndIf;
		
	EndIf;
	
EndProcedure

// Parameters:
// ValueSelected - CatalogRef.ProductCrossReferences
// AdditionalParameters - Structure
// 
&AtClient
Procedure ProcessResultOfSelectingPartnerProductName(ValueSelected, AdditionalParameters) Export
	
	If ValueSelected = Undefined Then
		Return;
	EndIf;
	
	AdditionalParameters.CurrentRow.PartnerProducts = ValueSelected;
	
	GoodsPartnerProductsOnChange(AdditionalParameters.FormItem);
	
EndProcedure

&AtServer
Function AddressOfTheTablePartProducts()
	
	RowsArray = New Array();
	For Each String In Object.Goods Do
		If String.Canceled Then
			Continue;
		EndIf;
		
		RowsArray.Add(String);
	EndDo;
	
	Return PutToTempStorage(Object.Goods.Unload(RowsArray), UUID);
	
EndFunction

&AtServerNoContext
Function ContractParameters(Contract, BusinessOperation)
	
	Result = New Structure;
	Result.Insert("ByNewCommission", False);
	Result.Insert("AccountingPriceType", Catalogs.TypesOfPrices.EmptyRef());
	Result.Insert("PriceIncludesVAT", False);
	
	If ThisIsContractForNewCommission(Contract, BusinessOperation) Then
		PriceParameters = AccountingTypeOfContractPrice(Contract);
		
		Result.AccountingPriceType = PriceParameters.PriceKind;
		Result.PriceIncludesVAT = PriceParameters.PriceIncludesVAT;
		Result.ByNewCommission = True;
		
	EndIf;
	
	Return Result;
	
EndFunction

&AtServerNoContext
Function ThisIsContractForNewCommission(Contract, BusinessOperation)
	
	Result = BusinessOperation = Enums.BusinessTransactions.TransferToCommissionAgent 
		And SalesServer.ThisIsContractForNewCommission(Contract);
		
	Return Result;
	
EndFunction

&AtServerNoContext
Function AccountingTypeOfContractPrice(Contract)
	
	ParametersStructure = EnterprisePricesFillingServer.NewParametersForCheckingTypeOfContractPrices();
	ParametersStructure.FieldPriceType = "PriceTypeAccountingPriceType";
	
	If ValueIsFilled(Contract) Then
		PriceKind = Common.ObjectAttributeValue(Contract, ParametersStructure.FieldPriceType, True);
		If ValueIsFilled(PriceKind) Then
			ParametersStructure.PriceKind = PriceKind;
			ParametersStructure.PriceIncludesVAT = PriceKind.PriceIncludesVAT;
		EndIf;
	EndIf;
	
	Return ParametersStructure;
	
EndFunction

&AtServer
Procedure SetVisibilityOfCommandToFillInContractPriceView()
	
	NewCommission = ?(ValueIsFilled(Object.Contract),
		ThisIsContractForNewCommission(Object.Contract, Object.BusinessOperation),
		ConsignmentSales25);
	Items.GoodsFillInPricesUnderAgreement.Visible = NewCommission;
	Items.GoodsFillThePricesByTermsOfSales.Visible = Not NewCommission;
	
EndProcedure

&AtServer
Procedure FillInParametersOfPriceTypeConnectionAndPriceIncludesVATAttribute()
	
	NewCommission = ?(ValueIsFilled(Object.Contract),
		ThisIsContractForNewCommission(Object.Contract, Object.BusinessOperation),
		ConsignmentSales25);
	
	If NewCommission Then
		ParametersOfTypeOfPricesUnderContract = AccountingTypeOfContractPrice(Object.Contract);
		If ParametersOfTypeOfPricesUnderContract.PriceIncludesVAT <> Undefined Then
			Object.PriceIncludesVAT = ParametersOfTypeOfPricesUnderContract.PriceIncludesVAT;
		EndIf;
	EndIf;
	
	ArrayOfSelectParameterRelationships = New Array;
	
	ArrayOfSelectParameterRelationships.Add(
		New ChoiceParameterLink("ToUseTermsOfSales", "ToUseTermsOfSales", LinkedValueChangeMode.Clear));
	
	If Not NewCommission Then
		
		ArrayOfSelectParameterRelationships.Add(
			New ChoiceParameterLink("Partner", "Object.Partner", LinkedValueChangeMode.DontChange));
		
		ArrayOfSelectParameterRelationships.Add(
			New ChoiceParameterLink("Terms", "Object.Terms", LinkedValueChangeMode.DontChange));
		
	EndIf;
		
	ArrayOfSelectParameterRelationships.Add(
		New ChoiceParameterLink("Filter.PriceIncludesVAT", "Object.PriceIncludesVAT", LinkedValueChangeMode.Clear));
	
	Items.GoodsPriceKind.ChoiceParameterLinks = New FixedArray(ArrayOfSelectParameterRelationships);
	
EndProcedure

&AtClient
Procedure AddPriceFillingAction(StructureOfActions)
	
	If Not ConsignmentSales25 And (ToUseTermsOfSales And ValueIsFilled(Object.Terms)) 
		Or (Not ToUseTermsOfSales And UsePriceManagementSystem25) Then
		StructureOfActions.Insert("FillIn_TermsOfSales", BatchProcessingOfTablePartClientServer.GetStructureForFillingInSalesConditionsInTSLine(Object));
	Else
		
		ParametersForFillingInPriceInTSLine = BatchProcessingOfTablePartClientServer.ParametersForFillingInPriceInTSLine(Object);
		StructureOfActions.Insert("FillInSalePrice", ParametersForFillingInPriceInTSLine);
		
		ContractParameters = ContractParameters(Object.Contract, Object.BusinessOperation);
		If ContractParameters.ByNewCommission And ValueIsFilled(ContractParameters.AccountingPriceType) Then
			
			ParametersForFillingInPriceType = BatchProcessingOfTablePartClientServer.ParametersForFillingInPriceTypeInTSLine(ContractParameters.AccountingPriceType);
			ParametersForFillingInPriceType.FilterParameters.UseWhileSellingToCustomers = True;
			StructureOfActions.Insert("CheckFillInPriceView", ParametersForFillingInPriceType);
			
		EndIf;
		
	EndIf;
	
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

&AtServer
Procedure EstablishRelationshipsBetweenContractSelectionParameters()
	
	RelationshipsOfContractParameters = New Array;
	RelationshipsOfContractParameters.Add(New ChoiceParameterLink("Filter.Organization",			"Object.Organization"));
	RelationshipsOfContractParameters.Add(New ChoiceParameterLink("Partner",						"Object.Partner"));
	RelationshipsOfContractParameters.Add(New ChoiceParameterLink("Filter.Counterparty",				"Object.Counterparty"));
	RelationshipsOfContractParameters.Add(New ChoiceParameterLink("Filter.ARAPCurrency",	"Object.Currency"));
	RelationshipsOfContractParameters.Add(New ChoiceParameterLink("Filter.BusinessOperation",	"ContractBusinessTransaction"));
	RelationshipsOfContractParameters.Add(New ChoiceParameterLink("Filter.ConsignmentSales25",	"ConsignmentSales25"));
	RelationshipsOfContractParameters.Add(New ChoiceParameterLink("Terms",					"Object.Terms",
			LinkedValueChangeMode.DontChange));

	Items.Contract.ChoiceParameterLinks = New FixedArray(RelationshipsOfContractParameters);
	
EndProcedure


&AtServer
Procedure SetPropertiesOfOutdatedCommissionUsageComment()
	
	Items.CommentUsingOutdatedCommission.Title = ConsignmentSalesServer.CommentUsingOutdatedCommission();
	Items.GroupCommentUsingOutdatedCommission.Visible = Not ConsignmentSales25
		And Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.TransferToCommissionAgent")
		And (ValueIsFilled(Object.Terms) Or ValueIsFilled(Object.Contract));
	
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
	
	Columns.Add("Price");
	Columns.Add("PriceKind");
	Columns.Add("Package");
	Columns.Add("Count");
	Columns.Add("NumberOfPackages");
	
	TransferOperations_ = New Array;
	TransferOperations_.Add(PredefinedValue("Enum.BusinessTransactions.TransferToCommissionAgent"));
	TransferOperations_.Add(PredefinedValue(
		"Enum.BusinessTransactions.TransferToStorageWithRightOfSale"));
	
	If TransferOperations_.Find(Form.Object.BusinessOperation) = Undefined Then
		If Form.UseDiscountAdjustmentsInSales Then
			Columns.Add("PercentRateOfManualDiscount");
			Columns.Add("ManualDiscount");
		EndIf;
		If Form.UseDiscountsMarkupsInSales Then
			Columns.Add("PercentRateOfAutomaticDiscountMarkup");
			Columns.Add("DiscountMarkupAmount");
		EndIf;
	EndIf;
	
	If Form.UseReasonsForSalesOrderCancellations Then
		Columns.Add("CancellationReason");
	EndIf;
	
	Columns.Add("Canceled");
	
	Columns.Add("VATRate");
	Columns.Add("VATAmount");
	Columns.Add("AmountIncludingVAT");
	Columns.Add("Sum");
	
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
	
	CalculateOrderTotals(ThisForm);
	
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
	
	CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	
	StructureOfActionsWithModifiedStrings = New Structure;
	
	StructureOfActionsWithModifiedStrings.Insert("FillInDuplicateDependentDetails", DependentDetails());
	StructureOfActionsWithModifiedStrings.Insert("FillInCanceledWithoutReturnableContainerAttribute", Object.ToReturnReusablePackage);
	// The warehouse will be inserted later
	StructureOfActionsWithModifiedStrings.Insert("CheckSeriesCalculateStatus", New Structure("SeriesSpecificationParameters", SeriesSpecificationParameters));
	
	StructureOfActionsWithAddedStrings = New Structure;
	StructureOfActionsWithAddedStrings.Insert("CheckFillWarehouse", BatchProcessingOfTablePartClientServer.GetWarehouseFillStructureInTSLine(Object, WarehouseGroup_));
	StructureOfActionsWithAddedStrings.Insert("FillInDuplicateDependentDetails", DependentDetails());
	StructureOfActionsWithAddedStrings.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
	StructureOfActionsWithAddedStrings.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));
	StructureOfActionsWithAddedStrings.Insert("FillInNoReturnContainerAttribute", Object.ToReturnReusablePackage);
	StructureOfActionsWithAddedStrings.Insert("FillInCanceledWithoutReturnableContainerAttribute", Object.ToReturnReusablePackage);
	StructureOfActionsWithAddedStrings.Insert("FillInSalesOptionAttribute", New Structure("Products", "SaleRegistrationOption"));
	StructureOfActionsWithAddedStrings.Insert("FillInContent", BatchProcessingOfTablePartClientServer.GetStructureOfFillingInServiceContentInTSLine(Object, False));
	AddCollateralActionsOnServer(StructureOfActionsWithAddedStrings,
		"SupplyOption,WarehouseIsRequired,DateOfShipmentRequired_");
	If Object.BusinessOperation <> Enums.BusinessTransactions.DeliveryForPrincipal Then
		StructureOfActionsWithAddedStrings.Insert("FillInSubdivisionInTSLine", New Structure("Department", Object.Department));
	EndIf;
	DataParameters = New Structure;
	DataParameters.Insert("Data", GetFromTempStorage(AddressInTempStorage));
	DataParameters.Insert("StructureOfActionsWithModifiedStrings", StructureOfActionsWithModifiedStrings);
	DataParameters.Insert("StructureOfActionsWithAddedStrings", StructureOfActionsWithAddedStrings);
	DataParameters.Insert("DialColumns", DialColumns(ThisForm));
	
	SetsServer.AtEndOfEditingSet(ThisForm, "Goods", DataParameters);
	
	WarehousesServer.WhenChangingWarehouseInTablePart(Object.Goods, WarehouseTable, WarehouseGroup_);
	TotalWarehouses_ = WarehouseTable.Count();
	WarehousesClientServer.UpdateWarehouseGroupImage(SeveralWarehousesText, Items.PictureMultipleWarehouses, TotalWarehouses_);
	
	CalculateOrderTotals(ThisForm);
	UpdateColumnAvailableServer();
	
EndProcedure

&AtClient
Procedure CalculationsClick(Item, StandardProcessing)
	
	ARAPAccountingClient.CalculationsClick(ThisForm, Item, StandardProcessing);
	
EndProcedure

#EndRegion

&AtServer
Procedure SetVisibilityOfPartnerField()
	
	CLVisibility = Items.ToReadLoyaltyCardClient.Visible;
	If CLVisibility Then
		CLVisibility = UseLoyaltyCards;
	EndIf;
	
	Items.PartnerWithoutCL.Visible = Not CLVisibility;
	Items.Partner.Visible      = CLVisibility;
	
EndProcedure

&AtClient
Procedure SpecialTransportationConditionsOnChange(Item)
	SpecialTransportationConditionsOnChangeServer();
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
Function GoodsTransferOperations()
	
	TransferOperations_ = New Array;
	TransferOperations_.Add(
		PredefinedValue("Enum.BusinessTransactions.TransferToCommissionAgent"));
	TransferOperations_.Add(
		PredefinedValue("Enum.BusinessTransactions.TransferToStorageWithRightOfSale"));
	TransferOperations_.Add(
		PredefinedValue("Enum.BusinessTransactions.DeliveryForPrincipal"));
	
	Return TransferOperations_;
	
EndFunction

&AtServer
Procedure ReflectChangesToPaymentRules(ChangedBankingDetails)
	
	Object.Approved           = False;
	SetAvailabilityOfItemsByStatusServer();
	
	PaymentStepsServer.LoadPaymentStagesFromTemporaryStorage(ThisForm);
	ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisObject, ChangedBankingDetails, True);
	
	AddSBPPaymentStatusUpdateCommand();
	
EndProcedure

&AtClient
Procedure Attachable_ProcessObjectEntry()
	
	TMCommonUseClient.ProcessObjectEntryInForm(ThisObject, ParametersForRecording);
	
EndProcedure

&AtServer
Procedure PrepareAndSetVisibilityForAssemblyAndDelivery()
	
	DateWarehouseSettingsWereCalculated = Object.DateOfShipment;
	
	ThereIsSupportForDeliveryByYourOwnCouriers = WarehousesServer.ThereIsSupportForDeliveryByYourOwnCouriers(Object.Warehouse, DateWarehouseSettingsWereCalculated);
	ThereIsSupportForBuildingOrders = WarehousesServer.ThereIsSupportForBuildingOrders(Object.Warehouse, DateWarehouseSettingsWereCalculated);
	
	ThereIsSupportForDeliveryByYourOwnCouriers = ThereIsSupportForDeliveryByYourOwnCouriers
		And (Object.ARAPObjectSettings <> Enums.ARAPObjectSettings.ByCounterpartyContracts);
		
	If GoodsDeliveryClientServer.UsedDelivery20()
		And Not ThereIsSupportForDeliveryByYourOwnCouriers
		And Object.DeliveryMethod = Enums.TransportMethods.ToCustomerByCourier Then
		
		Object.DeliveryMethod = Enums.TransportMethods.SelfPickup;
		FillInAndSetDeliveryAttributesServer(Items.DeliveryMethod.Name);
		
	EndIf;
	
	If GoodsDeliveryClientServer.UsedDelivery25()
		And Not ThereIsSupportForDeliveryByYourOwnCouriers
		And Object.DeliveryMethod25 = Enums.TransportMethods25.OurCourier Then
		
		Object.DeliveryIsRequired = False;
		Object.DeliveryMethod25 = Enums.TransportMethods25.EmptyRef();
		Object.Courier = Catalogs.Persons.EmptyRef();
		SetAvailabilityVisibilityOfDeliveryItems(ThisObject);
		
	EndIf;
	
	If Not ThereIsSupportForBuildingOrders Then
		Object.Picker = Undefined;
	EndIf;
	
	If GoodsDeliveryClientServer.UsedDelivery20() Then
		
		GoodsDelivery.UpdateShippingMethodSelectionListForShippingWarehouse(Items.DeliveryMethod, ThereIsSupportForDeliveryByYourOwnCouriers);
		
	EndIf;
	Items.Picker.Visible = ThereIsSupportForBuildingOrders;
	
EndProcedure

&AtServer
Procedure SetVisibilityOfElementsOfLoyaltyBonusProgram()
	
	Items.GroupProductsBonusPoints.Visible = UseLoyaltyPrograms;
	Items.GoodsAmountOfBonusPointsToDeductionInCurrency.Visible = UseLoyaltyPrograms;
	Items.GoodsAmountOfEarnedBonusPointsInCurrency.Visible = UseLoyaltyPrograms;
	
EndProcedure

&AtServer
Procedure AddSBPPaymentStatusUpdateCommand()

	CommandParameters = CashServerLocalization.NewParametersOfSBPPaymentStatusUpdateCommand();
	CommandParameters.Parent = Items.Group1;
	CashServerLocalization.AddSBPPaymentStatusUpdateCommand(ThisObject, CommandParameters);

EndProcedure

&AtClient
Procedure Attachable_OnlineOrderPaymentVerification()

	CashClientLocalization.CheckOnlineOrderPayment(ThisObject, Object.Ref);

EndProcedure

&AtClient
Procedure Attachable_SBPPaymentVerification()

	CashClientLocalization.CheckSBPPayment(ThisObject, Object.Ref, Object.Counterparty);

EndProcedure

#Region Localization

&AtClient
Procedure GoodsBeforeRowChangeLocalization(Item, Cancel)
	
	
EndProcedure

&AtClient
Procedure AddLocalizationFormParameters(FormParameters)
	
	
EndProcedure

&AtServer
Procedure AddDiscountParametersLocalization(DiscountParameters)
	
	
EndProcedure

&AtServer
Procedure CheckCorrectAvailabilityOfDiscountsPaymentsWithBonusPointsLocalization()
	
	
EndProcedure

&AtServer
Procedure UpdateSalesTagForTobaccoProductsOnlyByMRCLocalization(Form)
	
	
EndProcedure

&AtClient
Procedure AddPriceControlParameterForIDCLocalizationToForm(Form, FormParameters)
	
	
EndProcedure

&AtServer
Procedure WhenChangingElementLocalization(Form, Item);
	
	
EndProcedure

#EndRegion

#EndRegion
