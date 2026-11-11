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

	EmbeddingParameters = Documents.RequestForReturnOfGoodsFromCustomer.AvailableRemainingEmbeddingOptions();
	ProvisionInDocumentsServer.AvailableBalancesWhenCreatedOnServer(ThisObject, EmbeddingParameters);
	
	SetConditionalAppearance();
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;

	InfobaseUpdate.CheckObjectProcessed(Object, ThisObject);

	// Handler of the "Versioning of objects" mechanism
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	
	// Handler of the "Destination" mechanism
	Catalogs.Assignments.DocumentFormWhenCreatedOnServer(ThisObject);
	
	// Handler of the "Properties" mechanism
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("Object", Object);
	AdditionalParameters.Insert("ItemForPlacementName", "GroupAdditionalAttributes");
	AdditionalParameters.Insert("DeferredInitialization", True);
	PropertyManager.OnCreateAtServer(ThisForm, AdditionalParameters);
	
	UseBusinessUnits                  = GetFunctionalOption("UseBusinessUnits");
	UseDiscountAdjustmentsInSales          = GetFunctionalOption("UseDiscountAdjustmentsInSales");
	UseDiscountsMarkupsInSales  = GetFunctionalOption("UseDiscountsMarkupsInSales");
	UseRestrictionsOfManualDiscounts        = GetFunctionalOption("UseLimitsForDiscountAdjustmentsInSalesByUsers")
		Or GetFunctionalOption("UseLimitsForDiscountAdjustmentsInSalesByTermsOfSales");
	UseReasonsForSalesOrderCancellations   = GetFunctionalOption("UseReasonsForSalesOrderCancellations");
	UsePartnersAsCounterparties       = GetFunctionalOption("UsePartnersAsCounterparties");
	UsePriceManagementSystem25              = PriceManagementSystemServerCall.UsePriceManagementSystem25();
	ToUseTermsOfSales           = GetFunctionalOption("ToUseTermsOfSales");
	UseCustomerContracts             = GetFunctionalOption("UseCustomerContracts");
	SelectConsignmentSalesVersion           = GetFunctionalOption("SelectConsignmentSalesVersion");
	OnlyConsignmentSales25                = UseCustomerContracts And (GetFunctionalOption("OnlyConsignmentSales25")
		Or Not ToUseTermsOfSales Or Not SelectConsignmentSalesVersion);
	
	UseLoyaltyCards  = GetFunctionalOption("UseLoyaltyCards");
	UseLoyaltyPrograms = UseLoyaltyPrograms(Object.LoyaltyCard);
	SetVisibilityOfElementsOfLoyaltyBonusProgram();

	TMCommonUse.CustomizePeripherals(ThisForm, "ReturnedGoods,SubstituteGoods");
	
	ContractIsObligatory = ?(Object.BusinessOperation = Enums.BusinessTransactions.ReturnFromCommissionAgent
		And Not ToUseTermsOfSales, True, False);
		
	SalesServer.SetModeForSelectingGroupsOfWarehouseItems(Items.Warehouse);
		
	SalesServer.SetBlankContractMark(Items, "Contract", ContractIsObligatory);
	
	SetCommissionSaleAttribute();
	FillOperationSelectionList();
	
	SetVisibilityOfFillCommands();
	
	If Not ValueIsFilled(Object.Ref) Then
		
		UpdateCompensationMethod();
		OnReadCreateAtServer();
		ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters.Substitutes_);
		ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters.Returned_);
		
		AutoTitle = False;
		GenerateHeadersThatDependOnBusinessTransaction();
		FillIn_BlankReceiptDates();
		
	EndIf;
	
	If Not UseBusinessUnits Then
		Items.SubstituteGoodsDepartment.Visible = False;
	Else
		Items.SubstituteGoodsDepartment.Title = NStr("vi = 'Bộ phận gửi';
													|ru = 'Подразделение-отправитель';
													|en = 'Shipping business unit'; fa = 'واحد تجاری ارسال‌کننده';
													|it = 'Unità-mittente';
													|pl = 'Shipping business unit';
													|tr = 'Gönderen departman'");
	EndIf;
	
	If ClientApplication.CurrentInterfaceVariant() = ClientApplicationInterfaceVariant.Version8_2 Then
		Items.GroupInTotal.BackColor = New Color();
	EndIf;
	
	DiscountsMarkupsFillingServer.ConfigureShowMessagesCommand(Object, Items.ShowMessages, Not Object.FillInPricesOfSubstituteGoodsByReturned);
	
	Enums.StatusesOfRequestsForReturnOfGoodsFromCustomers.FillChoiceList(Items.Status.ChoiceList, Object.Status);
	
	Items.CloseRequest.Enabled = AccessRight("Update",Metadata.Documents.RequestForReturnOfGoodsFromCustomer);
	
	Items.SubstituteGoodsCancelUndeliveredLines.Visible = Not Object.ThisIsOrderAsInvoice;
	
	SetAvailabilityOfClipboardCommands();
	
	ElementsToFillIn = New Array;
	ElementsToFillIn.Add(Items.DeliveryTimeFrom);
	ElementsToFillIn.Add(Items.DeliveryTimeTo);
	ElementsToFillIn.Add(Items.DeliveryTimeFrom1);
	ElementsToFillIn.Add(Items.DeliveryTimeTo1);
	GoodsDeliveryClientServer.FillTimeFieldSelectionList(ElementsToFillIn);

	ARAPAccountingFormWork.FormWhenCreatedOnServer(ThisForm);
	NotifyAboutCreationOfCalculationObject = Parameters.NotifyAboutCreationOfCalculationObject;

	Items.SubstituteGoodsPriceKind.QuickChoice = Not GetFunctionalOption("UseSeveralPriceTypes");

	SetVisibilityOfCommandAndFillInVATRate();

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

	SetBanOnSelectingWarehouseGroup(Items.Warehouse);
	UpdateSalesTagForTobaccoProductsOnlyByMRCLocalization(ThisObject);
	
	AddSBPPaymentStatusUpdateCommand();

	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)

	// StandardSubsystems.AccessManagement
	AccessManagement.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.AccessManagement
	
	EmbeddingParameters = Documents.RequestForReturnOfGoodsFromCustomer.AvailableRemainingEmbeddingOptions();
	ProvisionInDocumentsServer.AvailableBalancesWhenReadingOnServer(ThisObject, EmbeddingParameters);
	
	OnReadCreateAtServer();
	PropertyManager.OnReadAtServer(ThisObject, CurrentObject);

	ARAPAccountingFormWork.FormWhenReadingOnServer(ThisObject);
	
	ConfigurationModificationOverridable.OnReadAtServer(ThisObject, CurrentObject);
	
	UpdateSalesTagForTobaccoProductsOnlyByMRCLocalization(ThisObject);
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	// End StandardSubsystems.AttachableCommands
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
	
	// If the document is carried out, we will fill in the empty dates of receipt in pm returned goods
	// and empty dates of shipment in pm replacing goods, calculate discounts, fill out the payment schedule.
	If WriteParameters.WriteMode = DocumentWriteMode.Posting Then
		Cancel = True;
		
		AdditionalParameters = New Structure;
		AdditionalParameters.Insert("WriteParameters", WriteParameters);
		ReusablePackageClient.OfferToPickUpMultiTurnContainer(
			ThisForm,
			"ReturnedGoods",
			"Products,Characteristic,Count,,DateOfReceipt",
			New CallbackDescription("BeforeRecordingOfferToPickUpMultiTurnContainer", ThisObject, AdditionalParameters));
		Return;
		
	EndIf;
	
	TMCommonUseClient.RecordObjectIfNecessary(ThisObject, WriteParameters, Cancel);
	
EndProcedure

&AtClient
Procedure BeforeRecordingOfferToPickUpMultiTurnContainer(Result, AdditionalParameters) Export
	
	Cancel = False;
	
	ItIsNecessaryToReplaceGoods =
		Object.CompensationMethod = PredefinedValue("Enum.CompensationMethodsForReturnsOfGoods.ToSubstituteGoods");
	
	If UseDiscountsMarkupsInSales
		And Object.BusinessOperation <> PredefinedValue("Enum.BusinessTransactions.ReturnFromCommissionAgent")
		And Object.BusinessOperation <> PredefinedValue("Enum.BusinessTransactions.ReturnFromCustodian")
		And ItIsNecessaryToReplaceGoods 
		And Object.SubstituteGoods.Count() > 0 Then
		
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
	
	CalculateTotalsOfRefundRequest(ThisForm);
	
	If Not Cancel Then
		TMCommonUseClient.RecordObjectIfNecessary(ThisObject, AdditionalParameters.WriteParameters,,True);
	EndIf;
	
EndProcedure

&AtClient
Procedure BeforeRecordingAskQuestionAboutResettingScheduleONChangesInShipmentDateEnd(Result, AdditionalParameters) Export
	
	Cancel = False;
	
	If Result = DialogReturnCode.Yes Then
		Object.PaymentScheduleSteps.Clear();
	EndIf;
	ARAPAccountingClient.QuestionAboutResettingScheduleONChangesInShippingDatesHasBeenAsked(ThisObject);
	
	BeforeWriteAtClientServer();
	
	CalculateTotalsOfRefundRequest(ThisForm);
	
	If Not Cancel Then
		TMCommonUseClient.RecordObjectIfNecessary(ThisObject, AdditionalParameters.WriteParameters,,True);
	EndIf;
	
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
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInFeatureAttribute", New Structure("Products", "ItemVariantsAreUsed"));
	StructureOfActions.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
	StructureOfActions.Insert("FillInSalesOptionAttribute", New Structure("Products", "SaleRegistrationOption"));
	StructureOfActions.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));
		
	ProductsServer.FillInServiceDetailsForProductInCollection(Object.SubstituteGoods, StructureOfActions);
	
	StructureOfActions.FillInFeatureAttribute.Insert("ProductsRecordingAsReceived", "ItemVariantsAreUsedRecordingAsReceived");
	StructureOfActions.Delete("FillInSalesOptionAttribute");
	StructureOfActions.Delete("FillInArticleAttribute");
	StructureOfActions.Insert("FillInArticleAttribute", New Structure("Products, ProductsRecordingAsReceived", "SKU", "SKURegistration"));
	ProductsServer.FillInServiceDetailsForProductInCollection(Object.ReturnedGoods, StructureOfActions);
	
	SetsServer.FillInServiceDetails(ThisForm, "ReturnedGoods");
	SetsServer.FillInServiceDetails(ThisForm, "SubstituteGoods");
	
	UpdateDuplicateDependentDetails();
	ProvisionInDocumentsServer.AfterWriteAtServer(ThisObject);
	SetSoftwareVisibility();
	FillInServiceDetailsOfDocumentForm();
	
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
	
	CustomizeFormElements();
	UpdateTextDocumentsBasedOn();
	
	ARAPAccountingFormWork.FormAfterRecordingOnServer(ThisForm, CurrentObject.AdditionalProperties);
	
	ConfigurationModificationOverridable.AfterWriteAtServer(ThisForm, CurrentObject, WriteParameters);
	
EndProcedure

&AtServer
Procedure BeforeLoadDataFromSettingsAtServer(Settings)
	
	HideCanceledLines = Settings.Get("HideCanceledLines");
	
	If HideCanceledLines Then
		Items.SubstituteGoods.RowFilter = New FixedStructure("Canceled", False);
	Else
		Items.SubstituteGoods.RowFilter = Undefined;
	EndIf;
	
	HideCanceledLinesReturnedItems = Settings.Get("HideCanceledLinesReturnedItems");
	
	If HideCanceledLinesReturnedItems Then
		Items.ReturnedGoods.RowFilter = New FixedStructure("Canceled", False);
	Else
		Items.ReturnedGoods.RowFilter = Undefined;
	EndIf;
	
	Items.ReturnedGoodsHideCanceledLines.Check = HideCanceledLinesReturnedItems;
	
	If Not Object.Ref.IsEmpty() Or Not UseShipmentByRowsInSalesOrder Then
		Settings.Delete("Object.NotShipInInstallments");
		If Not Object.Ref.IsEmpty() Then
			Settings.Delete("Object.OneDateReceipt");
		EndIf;
	EndIf;
	
EndProcedure

&AtServer
Procedure OnLoadDataFromSettingsAtServer(Settings)
	
	CacheQualityControl = QualityControl.DataCacheOfMechanism(Object);
	CustomizeFormElements();
	
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
			
			If Items.GroupPages.CurrentPage = Items.ReplacementProductsGroup Then
				ProcessBarcodes(BarcodeData_5, "SubstituteGoods");
			Else
				ProcessBarcodes(BarcodeData_5, "ReturnedGoods");
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
		
		If Items.GroupPages.CurrentPage = Items.ReplacementProductsGroup Then
			ProcessBarcodes(BarcodeData_5, "SubstituteGoods");
		Else
			ProcessBarcodes(BarcodeData_5, "ReturnedGoods");
		EndIf;
		
	EndIf;
	
	If ARAPAccountingClient.NeedAlertProcessingCall(ThisObject, EventName, Parameter)
		Or EventName = "Write_ReturnOfGoodsFromCustomer" Then
		PaymentCreditedServer(EventName, Parameter, Source);
	EndIf;
	
	If EventName = "LoyaltyCardIsRead"
		And Parameter.OwnerForm = UUID Then
		LoyaltyCardIsRead(New CallbackDescription("NotificationProcessingCompletion", ThisObject, New Structure("EventName, Parameter", EventName, Parameter)), Parameter.LoyaltyCard);
		
		Return;
	EndIf;
	
	If EventName = "SBPStatusHasBeenChanged" Then
		AddSBPPaymentStatusUpdateCommand();
		CashClientLocalization.CheckSBPPayment(ThisObject, Object.Ref, Object.Counterparty);
	EndIf;
	
	If EventName = "Recording_NotificationOfSpecialTaxRegimes" Then
		
		UpdateTextDocumentsBasedOn();
		
	EndIf;
	
	HandlingFragmentAlerts(EventName, Parameter);
	// StandardSubsystems.FilesOperations
	FilesOperationsClient.NotificationProcessing(ThisObject, EventName);
	// End StandardSubsystems.FilesOperations

EndProcedure

&AtClient
Procedure NotificationProcessingCompletion(Result, AdditionalParameters) Export
    
    EventName = AdditionalParameters.EventName;
    Parameter = AdditionalParameters.Parameter;
    
    
    HandlingFragmentAlerts(EventName, Parameter);

EndProcedure

&AtClient
Procedure HandlingFragmentAlerts(Val EventName, Val Parameter)
    
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
       ProvisionInDocumentsClientServer.FillInServiceDetails(Object.SubstituteGoods,
              DateOfShipmentRequired_, WarehouseIsRequired);
    EndIf;
    
    If EventName = "EditSet"
        And Parameter.OwnerForm = UUID Then
        
        KitParameters = New Structure;
        KitParameters.Insert("ProductsInSet", Parameter.ProductsInSet);
        KitParameters.Insert("ItemVariantOfSet", Parameter.ItemVariantOfSet);
        
        If Parameter.TSName = "ReturnedGoods" Then
			KitParameters.Insert("DocumentSalesOfGoodsAndServices", Parameter.DocumentSalesOfGoodsAndServices);
			KitParameters.Insert("DialColumns", SetColumnsReturnItems(ThisForm));
        Else
            KitParameters.Insert("DialColumns", SetColumnsReplacingProducts(ThisForm));
        EndIf;
        
        SetAddressInTemporaryStorage = SetAddressInTemporaryStorage(KitParameters, Parameter.TSName);
        
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
        OpeningParameters.Insert("TSName", Parameter.TSName);
        OpeningParameters.Insert("Ref", Object.Ref);
        If Parameter.TSName = "ReturnedGoods" Then
			OpeningParameters.Insert("DocumentSalesOfGoodsAndServices", Parameter.DocumentSalesOfGoodsAndServices);
			OpeningParameters.Insert("FilterByProductType", ProductsClientServer.SelectionByProductMultiTurnContainer());
        EndIf;
        If Parameter.TSName = "SubstituteGoods" Then
			If Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.ReturnFromCommissionAgent")
				Or Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.ReturnFromCustodian") Then
                OpeningParameters.Insert("FilterByProductType", ProductsClientServer.SelectionByProductMultiTurnContainer());
            EndIf;
        EndIf;
        OpeningParameters.Insert("Warehouse", Object.Warehouse);
        OpeningParameters.Insert("HideCommandRemainingQuantityInWarehouses", False);
		If ValueIsFilled(Object.CashRegisterReceipt) Then
			OpeningParameters.Insert("PriceKind", ThisForm.CashReceiptPriceType);
			OpeningParameters.Insert("ProhibitPriceEditing", True);
		EndIf;	
        OpeningParameters.Insert("Organization", Object.Organization);
        
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
	// End StandardSubsystems.AttachableCommands
	
	ReplacementProductsAutoMarkBlank();

	// StandardSubsystems.FilesOperations
	FilesOperationsClient.OnOpen(ThisObject, Cancel);
	// End StandardSubsystems.FilesOperations
	
	EnableWaitingHandlerReceivingCarriers();
	
	CashClientLocalization.AttachablePaymentVerificationViaServices(ThisObject, Object.Ref, Object.Counterparty);
	
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

&AtClient
Procedure AfterWrite(WriteParameters)
	
	Title = "";
	AutoTitle = True;
	FormModified = Undefined;
	Attachable_WhenChangingModifiabilityOfForm();
	ARAPAccountingClient.FormAfterRecording(ThisForm);
	
	WriteParameters.Insert("NotificationDocumentKeys", OperationsWithDocumentJournalsClient.GetKeyParametersForDocument(
		Object.Ref, Object.Date, Object.BusinessOperation));
	Notify("Write_RequestForReturnOfGoodsFromCustomer", WriteParameters, Object.Ref);
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

&AtClient
Procedure ChoiceProcessing(ValueSelected, ChoiceSource)
	
	ClearMessages();
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.StartTimeMeasurement(True,
		"Document.RequestForReturnOfGoodsFromCustomer.Form.DocumentForm.Event.ChoiceProcessing");

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
			FillPropertyValues(Object, ValueSelected);
		EndIf;
		
	ElsIf ChoiceSource.FormName = "DataProcessor.PrintApplicationForReturnOfGoodsFromCustomer.Form.AttributesForReturnApplicationPrinting" Then
		
		If ValueSelected <> Undefined Then
			Modified = True;
			FillPropertyValues(Object, ValueSelected);
		EndIf;
		
	ElsIf ChoiceSource.FormName = "CommonForm.SelectGoodsBySalesAndTransfers" Then
		
		ProcessingSelectionSelectionByImplementationServer(ValueSelected);
		
	ElsIf ChoiceSource.FormName = "DataProcessor.SelectGoodsTransferredToCustody.Form.Form" Then
		
		SelectionProcessingSelectionOfTransferredGoods(ValueSelected);
		
	ElsIf ChoiceSource.FormName = "DataProcessor.SelectGoodsToSalesDocument.Form.Form" Then
		
		HandlingSelectionSelectionOnClient(ValueSelected);
		
	ElsIf ChoiceSource.FormName = "DataProcessor.SelectReusablePackage.Form.Form" Then
		
		FillMultiTurnContainersFromStorageServer(ValueSelected.AddressOfReusableContainerInStorage);
		ReusablePackageClient.NotifyUserAboutFillingMultiTurnContainers();
		
	ElsIf ProductsClient.ThisIsIndicationOfSeries(ChoiceSource) Then
		
		ProductsClient.ProcessSeriesIndication(ThisForm, ChoiceSource.SeriesSpecificationParameters, ValueSelected);
		
	ElsIf ChoiceSource.FormName = "Catalog.BusinessStructure.Form.ChoiceForm" Then
		
		SalesClient.ProcessingUnitSelection(Object.SubstituteGoods, Items.SubstituteGoods.SelectedRows, ValueSelected);
	
	ElsIf ChoiceSource.FormName = "DataProcessor.OrderClosureWizard.Form.ClosureForm" Then
		
		AdjustOrderLines(ValueSelected);
		
	EndIf;
	
	ProvisionInDocumentsClientServer.FillInServiceDetails(Object.SubstituteGoods, DateOfShipmentRequired_, WarehouseIsRequired);
	If Window <> Undefined Then
		Window.Activate();
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

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

&AtClient
Procedure GroupPagesOnCurrentPageChange(Item, CurrentPage)
	
	// StandardSubsystems.Properties
	If CurrentPage.Name = "AdvancedGroup"
		And Not ThisObject.PropertiesParameters.DeferredInitializationExecuted Then
		
		PropertiesExecuteDeferredInitialization();
		PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
	EndIf;
	// End StandardSubsystems.Properties
	
	ARAPAccountingClient.UpdateHyperlinkTextPaymentSteps(ThisForm);
	
EndProcedure

&AtClient
Procedure TermsStartChoice(Item, ChoiceData, StandardProcessing)
	
	AgreementSelectionParameters = SalesClient.ParametersForStartingSelectionOfAgreementWithClient();
	
	AgreementSelectionParameters.Item               = Item;
	AgreementSelectionParameters.Partner               = Object.Partner;
	AgreementSelectionParameters.Document              = Object.Terms;
	AgreementSelectionParameters.DocumentDate         = Object.Date;
	AgreementSelectionParameters.FormDataStructure  = Object;
	AgreementSelectionParameters.BusinessOperation = BusinessTransactionFromAgreement;
	
	SalesClient.StartSelectingAgreementWithClient(AgreementSelectionParameters, StandardProcessing);
	
EndProcedure

&AtClient
Procedure WarehouseOnChange(Item)
	
	ClearMessages();
	WarehouseOnChangeServer(True);
	
EndProcedure

&AtClient
Procedure PartnerOnChange(Item)
	
	If Not ValueIsFilled (Object.Partner) Then
		GoodsDeliveryClientServer.ClearDeliveryDetails(Items,Object);
		PartnerClearingServer();
		Return;
	EndIf;
	
	PartnerOnChangeServer();
	
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
Procedure ContractOnChange(Item)
	
	ClearMessages();
	ContractOnChangeServer(True);
	
EndProcedure

&AtClient
Procedure TermsOnChange(Item)
	
	ClearMessages();
	If Not ValueIsFilled (Object.Terms) Then
		TermsClearingServer();
		Return;
	EndIf;
	
	SetCommissionSaleAttribute();
	
	If Object.CompensationMethod = PredefinedValue("Enum.CompensationMethodsForReturnsOfGoods.ToSubstituteGoods") 
		And Object.ReturnedGoods.Count() > 0 Then
		QueryText = NStr("vi = 'Khi thay đổi thỏa thuận, sẽ tính lại đơn giá hàng hóa trả lại.
			|Điền lại hàng hóa thay thế cho hàng hóa bị trả lại?';
			|ru = 'При изменении соглашения будут пересчитаны цены возвращаемых товаров.
			|Перезаполнить заменяющие товары по возвращаемым?';
			|en = 'Prices of goods pending return will be recalculated on changing the agreement.
			|Populate exchange goods with the ones pending return?'; fa = 'Prices of goods pending return will be recalculated on changing the agreement.
			|Populate exchange goods with the ones pending return?';
			|it = 'Durante la modifica dell''accordo, i prezzi delle merci in corso di resa verranno ricalcolati.
			|Ricompilare le merci sostitutive per quelle in corso di resa?';
			|pl = 'Podczas zmiany umowy będą przeliczone ceny zwracanych towarów.
			|Ponownie wypełnić zastępujące wiersze pozycji według zwracanych?';
			|tr = 'Anlaşma değiştirildiğinde, iade edilen ürünlerin fiyatları yeniden hesaplanacaktır.
			| İade edilen ürünlerin üzerine ikame ürünler yeniden doldurulsun mu?'");
		ShowQueryBox(New CallbackDescription("TermsOnChangeCompletion", ThisObject),
				QueryText, QuestionDialogMode.YesNo);
	Else
		TermsOnChangeServer();
		SalesClient.NotifyEndOfFillingInTermsOfSale();
	EndIf;
	
EndProcedure

&AtClient
Procedure TermsOnChangeCompletion(QuestionResult, AdditionalParameters) Export
	
	TermsOnChangeServer(QuestionResult=DialogReturnCode.Yes);
	SalesClient.NotifyEndOfFillingInTermsOfSale();
	
EndProcedure

&AtClient
Procedure StatusOnChange(Item)
	
	If Object.Approved
		And Object.Status = PredefinedValue("Enum.StatusesOfRequestsForReturnOfGoodsFromCustomers.NotAgreedUpon")
		And Object.Status = PredefinedValue("Enum.StatusesOfRequestsForReturnOfGoodsFromCustomers.IsRejected") Then
		
		Object.Approved = False;
		
	EndIf;
	
	If Object.ReturnedGoods.Count() > 0 Then
		
		If Object.Status = PredefinedValue("Enum.StatusesOfRequestsForReturnOfGoodsFromCustomers.ForReturn") Or
			Object.Status = PredefinedValue("Enum.StatusesOfRequestsForReturnOfGoodsFromCustomers.ToSupply") Or
			Object.Status = PredefinedValue("Enum.StatusesOfRequestsForReturnOfGoodsFromCustomers.ToShip") Or
			Object.Status = PredefinedValue("Enum.StatusesOfRequestsForReturnOfGoodsFromCustomers.Executed") Then
			
			FillIn_BlankReceiptDates();
			
		EndIf;
		
	EndIf;
	
	StatusOnChangeServer();
	
EndProcedure

&AtClient
Procedure VATTaxationOnChange(Item)
	
	ClearMessages();
	VATTaxationOnChangeServer();
	
EndProcedure

&AtClient
Procedure PriceIncludesVATOnChange(Item)
	
	ClearMessages();
	PriceIncludesVATOnChangeServer(CachedValues);
	
EndProcedure

&AtClient
Procedure CurrencyOnChange(Item)
	
	If ValueIsFilled(Object.Currency) Then
		
		RecalculateAmounts = PriceManagementSystemClient.CurrencyConversionRequired(Object, DocumentCurrency,"ReturnedGoods") Or PriceManagementSystemClient.CurrencyConversionRequired(Object, DocumentCurrency,"SubstituteGoods");
		CurrencyOnChangeServer(Object.Currency, RecalculateAmounts);
		
		If RecalculateAmounts Then
			PriceManagementSystemClient.NotifyAboutEndOfConversionOfAmountsIntoCurrency(DocumentCurrency, Object.Currency);
		EndIf;
		
	EndIf;
	
	DocumentCurrency = Object.Currency;
	
EndProcedure

&AtClient
Procedure BusinessOperationOnChange(Item)
	
	ClearMessages();
	
	BusinessOperationOnChangeServer();
	ClearImplementationDocuments(); 	
	ReplacementProductsAutoMarkBlank();

EndProcedure

&AtClient
Procedure OrganizationOnChange(Item)
	
	ClearMessages();
	OrganizationOnChangeServer();
	DiscountsMarkupsFillingClient.ResetDiscountsCalculatedFlag(ThisForm);
	
EndProcedure

&AtClient
Procedure CashRegisterReceiptOnChange(Item)
	
	If ValueIsFilled(Object.CashRegisterReceipt) Then
		
		AnswersOptions = New ValueList;
		AnswersOptions.Add(DialogReturnCode.Yes, NStr("vi = 'Điền lại';
														|ru = 'Перезаполнить';
														|en = 'Refill'; fa = 'پرکردن مجدد';
														|it = 'Ricompilare';
														|pl = 'Refill';
														|tr = 'Yeniden doldur'"));
		AnswersOptions.Add(DialogReturnCode.No, NStr("vi = 'Không điền lại';
													|ru = 'Не перезаполнять';
													|en = 'Do not refill'; fa = 'Do not refill';
													|it = 'Non ricompilare';
													|pl = 'Nie wypełniaj ponownie';
													|tr = 'Yeniden doldurma'"));
		
		ShowQueryBox(New CallbackDescription("CashRegisterReceiptOnChangeCompletion", ThisObject), NStr("vi = 'Điền lại hàng hóa ';
																										|ru = 'Перезаполнить возвращаемые товары по выбранному чеку ККМ?';
																										|en = 'Refill goods pending return by the selected receipt?'; fa = 'Refill goods pending return by the selected receipt?';
																										|it = 'Ricompilare i prodotti in reso per scontrino selezionato KKM (Macchinari di Registrazione e Controllo)?';
																										|pl = 'Ponownie wypełnić zwracane wiersze pozycji według wybranego paragonu kasy?';
																										|tr = 'İade edilen ürünler seçilen kasa fişine yeniden doldurulsun mu?'"), AnswersOptions);
	Else
		TMCommonUseClientServer.SetFormItemProperty(Items, "Partner", "ReadOnly", False);
	EndIf;
	
EndProcedure

&AtClient
Procedure CashRegisterReceiptOnChangeCompletion(QuestionResult, AdditionalParameters) Export
    
    UserAnswer = QuestionResult;
    
    ReFillProducts = (UserAnswer = DialogReturnCode.Yes);
    CashRegisterReceiptOnChangeServer(ReFillProducts);

EndProcedure

&AtClient
Procedure DocumentSalesOfGoodsAndServicesOnChange(Item)
	
	If Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.ReturnFromRetailCustomer") Then
		
		If ValueIsFilled(Object.CashRegisterReceipt) Then
			
			If GetReportOnRetailSalesByCashRegisterReceipt(Object.CashRegisterReceipt) <> Object.DocumentSalesOfGoodsAndServices Then
				Object.CashRegisterReceipt = Undefined;
			EndIf;
			
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ManagerOnChange(Item)
	
	FillInSubordinatePropertiesForStatistics("Manager");
	
	DiscountsMarkupsFillingClient.ResetDiscountsCalculatedFlag(ThisForm);
	
EndProcedure

&AtClient
Procedure DateOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	
	RefillPrices = False;
	
	If ToUseTermsOfSales
		And ValueIsFilled(Object.Terms)
		And ValueIsFilled(Object.Currency)
		And Object.ReturnedGoods.Count() <> 0
		And Object.SubstituteGoods.Count() <> 0 Then
		
		Notification = New CallbackDescription("DateOnChangeCompletion", ThisObject);
		EnterprisePricesFillingClient.AskQuestionAboutRecalculatingPriceWhenDateChanges(Object, Notification,"SubstituteGoods");
		
		Return;
		
	EndIf;
		
	DateWhenFragmentWasChanged(RefillPrices);
	
	RetailSalesClientServer.SetAvailabilityOfBonusPointsPaymentTeams(Items, Object.Date);
	
EndProcedure

&AtClient
Procedure DateOnChangeCompletion(QuestionResult, AdditionalParameters) Export
	
	ClearMessages();
	
	If QuestionResult = True Then
		RefillPrices = True;
	Else
		RefillPrices = False;
	EndIf;
	
	DateWhenFragmentWasChanged(RefillPrices);
	
EndProcedure

&AtClient
Procedure DateWhenFragmentWasChanged(Val RefillPrices)
	
	Var PricesCalculated;
	
	PricesCalculated = DateOnChangeServer(RefillPrices);
	
	If RefillPrices Then
		SalesClient.NotifyAboutEndOfFillingInPricesUnderAgreement(PricesCalculated);
	EndIf;

EndProcedure

&AtClient
Procedure ApprovalDateOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	ApprovalDateForChangesOnServer()
EndProcedure

&AtClient
Procedure LoyaltyCardStartChoice(Item, ChoiceData, StandardProcessing)
	
	LoyaltyCardsClient.StartSelectingLoyaltyCard(Item, StandardProcessing, Object.Partner, Object.Date);
	
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
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	
	FillInShipmentDateServer(Object.DateOfShipment, Undefined);
	
EndProcedure

&AtClient
Procedure NotShipInInstallmentsOnChange(Item)
	
	NotShipInInstallmentsOnChangeServer();
	
EndProcedure

&AtClient
Procedure OneDateReceiptOnChange(Item)
	
	OneDateReceiptOnChangeServer();
	
EndProcedure

&AtClient
Procedure DateOfReceiptOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	
	FillIn_ReceiptDatesServer(Object.DateOfReceipt);
	
EndProcedure

&AtClient
Procedure TheInscriptionTheTitleOfTheImplementationClick(Item, StandardProcessing)
	StandardProcessing = False;
	
	OpenForm(
		"CommonForm.ViewingListOfDocuments",
		New Structure("DocumentsList, Title",
			SalesList,
			NStr("vi = 'Bán hàng cho khách hàng (%DocumentsCount%)';
				|ru = 'Продажи клиентам (%DocumentsCount%)';
				|en = 'Sales to customers (%DocumentsCount%)'; fa = 'Sales to customers (%DocumentsCount%)';
				|it = 'Vendite ai clienti (%DocumentsCount%)';
				|pl = 'Sprzedaż klientom (%DocumentsCount%)';
				|tr = 'Müşterilere satışlar (%DocumentsCount%)'")
		),
		ThisForm,,,, Undefined, FormWindowOpeningMode.LockOwnerWindow);

EndProcedure

&AtClient
Procedure TextAllowedCreditBalanceClick(Item, StandardProcessing)
	
	ARAPAccountingClient.DebtLimitsClick(ThisForm, Item, StandardProcessing);
	
EndProcedure

&AtClient
Procedure ToReturnReusablePackageOnChange(Item)
	
	ToReturnReusablePackageOnChangeServer();
	DiscountsMarkupsFillingClient.ResetDiscountsCalculatedFlag(ThisForm);
	
EndProcedure

&AtClient
Procedure ReusablePackageReturnOnChange(Item)
	
	ToReturnReusablePackageOnChangeServer();
	
EndProcedure

&AtClient
Procedure TextShippingToAPartnerIsProhibitedClick(Item)
	OpenForm("Catalog.Partners.Form.FormOfSegmentsOfShipmentProhibition", New Structure("Partner", Object.Partner));
EndProcedure

&AtClient
Procedure LabelPaymentStagesClick(Item, StandardProcessing)
       
       Notification = New CallbackDescription("LabelPaymentStagesClickCompletion", ThisObject);
       PlacePaymentStepsInTemporaryStorage(Item.Name);
       ARAPAccountingClient.LabelPaymentStagesClick(ThisForm, Item, StandardProcessing, Notification );
       
EndProcedure

&AtServer
Procedure PlacePaymentStepsInTemporaryStorage(TagName)
       PaymentStepsServer.PlacePaymentStepsInTemporaryStorage(ThisForm, TagName);
EndProcedure
 
&AtServer
Procedure ReflectChangesToPaymentRules(ChangedBankingDetails)

	PaymentStepsServer.LoadPaymentStagesFromTemporaryStorage(ThisForm);
	ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisForm, ChangedBankingDetails, True);
	
	SetAvailabilityOfItemsByStatusServer();
	AddSBPPaymentStatusUpdateCommand();
	
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
	
	CalculateTotalsOfRefundRequest(ThisForm);
	
EndProcedure

&AtClient
Procedure CompensationMethodOnChange(Item)
	
	If Not Object.CompensationMethod=PredefinedValue("Enum.CompensationMethodsForReturnsOfGoods.ToSubstituteGoods")	
		And Object.SubstituteGoods.Count() <> 0 Then
		
		QueryText = NStr("vi = 'Phần bảng của hàng hóa thay thế sẽ bị xóa, tiếp tục?';
						|ru = 'Табличная часть заменяющих товары будет очищена, продолжить?';
						|en = 'The Substitute items table will be cleared. Do you want to continue?'; fa = 'The Substitute items table will be cleared. Do you want to continue?';
						|it = 'La parte tabulare delle merci sostitutive verrà cancellata, continuare?';
						|pl = 'Część tabelaryczna zastępujących towarów będzie oczyszczona, kontynuować?';
						|tr = 'İkame ürünlerin tablo kısmı temizlenecek, devam edilsin mi?'");
		ShowQueryBox(New CallbackDescription("CompensationMethodOnChangeCompletion", ThisObject),
					   QueryText, QuestionDialogMode.YesNo);
        Return;		
	EndIf;
		
	CompensationMethodOnChangeServer();
	
EndProcedure

&AtClient
Procedure CompensationMethodOnChangeCompletion(QuestionResult, AdditionalParameters) Export
	
	If QuestionResult=DialogReturnCode.Yes Then
		ClearReplacementGoods();
		CompensationMethodOnChangeServer();
	Else
		Object.CompensationMethod=PredefinedValue("Enum.CompensationMethodsForReturnsOfGoods.ToSubstituteGoods");
	EndIf;
	
EndProcedure

&AtClient
Procedure PackageDepositIsRequiredOnChange(Item)
	
	CalculateTotalsOfRefundRequest(ThisForm);
	
EndProcedure

&AtClient
Procedure StateClick(Item, StandardProcessing)
	
	SalesClient.StatusInFormOfDocumentClick(StandardProcessing, ThisObject);
	
EndProcedure

&AtClient
Procedure FillInThePricesOfReplacementProductsUnderTheAgreementWhenChanging(Item)
	
	QueryText = NStr("vi = 'Phần bảng của các hàng hóa thay thế sẽ được bổ sung, tiếp tục?';
					|ru = 'Табличная часть заменяющих товары будет перезаполнена, продолжить?';
					|en = 'Table of the substitute goods will be refilled. Continue?'; fa = 'Table of the substitute goods will be refilled. Continue?';
					|it = 'La parte tabulare delle merci sostitutive verrà ricompilata, continuare?';
					|pl = 'Część tabelaryczna zastępujących towarów będzie ponownie wypełniona, kontynuować?';
					|tr = 'İkame ürünlerin tablo kısmı yeniden doldurulacak, devam edilsin mi?'");
	ShowQueryBox(New CallbackDescription("FillInThePricesOfReplacementProductsUnderTheAgreementWhenChangingCompletion", ThisObject),
		QueryText,
		QuestionDialogMode.YesNo);
	
EndProcedure

&AtClient
Procedure FillInThePricesOfReplacementProductsUnderTheAgreementWhenChangingCompletion(QuestionResult, AdditionalParameters) Export
	
	If QuestionResult=DialogReturnCode.Yes Then
		FillInSubstituteGoodsByReturnedOnesServer();
	ElsIf QuestionResult=DialogReturnCode.No Then
		SetVisibilityOfAutomaticDiscounts();
		CalculateTotalsOfRefundRequest(ThisForm);
	EndIf;
	
EndProcedure

&AtClient
Procedure LineOfBusinessOnChange(Item)
	
	ClearMessages();
	LineOfBusinessOnChangeServer();
	
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
Procedure DepartmentOnChange(Item)
	
	FillInSalesVATTaxation();
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersReturnedGoods

&AtClient
Procedure ReturnedGoodsOnChange(Item)
	FillIn_BlankReceiptDates();
EndProcedure

&AtClient
Procedure ReturnedGoodsSelection(Item, RowSelected, Field, StandardProcessing)
	
	If Field = Items.ReturnedGoodsPrice Then
		
		CurrentData = Items.ReturnedGoods.CurrentData;
		If ValueIsFilled(CurrentData.PriceKind) And Not Object.Approved Then
			ClearMessages();
			CommonClientServer.MessageToUser(
			NStr("vi = 'Để soạn đơn giá, hãy xóa dạng giá';
				|ru = 'Для редактирования цены очистите вид цены';
				|en = 'To edit the price, clear the price type'; fa = 'To edit the price, clear the price type';
				|it = 'Для редактирования цены очистите вид цены';
				|pl = 'To edit the price, clear the price type';
				|tr = 'Fiyatı düzenlemek için fiyat türünü temizleyin'"),
			Object.Ref,
			CommonClientServer.PathToTabularSection("Object.ReturnedGoods", CurrentData.LineNumber, "PriceKind"),);
		EndIf;
		
	ElsIf SetsClient.ItemToLock(Field) Then
		
		CurrentRow = Object.ReturnedGoods.FindByID(RowSelected);
		If ValueIsFilled(CurrentRow.ProductsInSet) Then
			
			NotificationParameter1 = New Structure;
			NotificationParameter1.Insert("ProductsInSet",   CurrentRow.ProductsInSet);
			NotificationParameter1.Insert("ItemVariantOfSet", CurrentRow.ItemVariantOfSet);
			NotificationParameter1.Insert("DocumentSalesOfGoodsAndServices",   CurrentRow.DocumentSalesOfGoodsAndServices);
			NotificationParameter1.Insert("TSName", "ReturnedGoods");
			NotificationParameter1.Insert("OwnerForm", UUID);
			
			Notify("EditSet", NotificationParameter1, ThisForm);
			
		EndIf;
		
	ElsIf Field = Items.ReturnedGoodsProductsInSet Then
		
		ShowValue(Undefined, Items.ReturnedGoods.CurrentData.ProductsInSet);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ReturnedGoodsAfterDeleteRow(Item)
	
	CalculateTotalsOfRefundRequest(ThisForm);
	
	If ProductsClient.SeriesStatusesNeedToBeUpdated(
		Item,CachedValues,SeriesSpecificationParameters.Returned_,True) Then
		
		FillInStatusesOfSpecifyingSeriesWhenEditingLineTS(Undefined, CachedValues,"Returned_");
		ProductsClient.UpdateCachedValuesToAccountForSeries(
		Item,CachedValues,SeriesSpecificationParameters.Returned_);
		
	EndIf;
	UpdateInformationOnImplementations();
	ReusablePackageClient.UpdateFillingStateOfMultiTurnContainer(Object.ReusablePackageFillingStatus);
	OnChangingWarehouseInTablePartOfReturnedGoodsServer(); 

EndProcedure

&AtClient
Procedure ReturnedGoodsOnStartEdit(Item, NewRow, Copy)
	
	ProcessingOfTabularFormsClient.CacheCurLine(Items.ReturnedGoods, ThisObject);

	CurrentRow = Items.ReturnedGoods.CurrentData;
	
	SalesClient.ProductItemLineAtBeginningOfEditing(ThisForm, "ReturnedGoods", CurrentRow, NewRow, Copy);
	
	If NewRow Then
		CurrentRow.RowCode = 0;
	EndIf;
	
	ProductsClient.UpdateCachedValuesToAccountForSeries(
	Item,CachedValues,SeriesSpecificationParameters.Returned_, Copy);
	
EndProcedure

&AtClient
Procedure ReturnedGoodsOnEditEnd(Item, NewRow, CancelEdit)
	
	CalculateTotalsOfRefundRequest(ThisForm);
	
	CurrentData = Items.ReturnedGoods.CurrentData;
	
	If ProductsClient.SeriesStatusesNeedToBeUpdated(
		Item,CachedValues,SeriesSpecificationParameters.Returned_) Then
		
		IDCurrentRow = CurrentData.GetID();
		
		FillInStatusesOfSpecifyingSeriesWhenEditingLineTS(IDCurrentRow, CachedValues,"Returned_");	
		ProductsClient.UpdateCachedValuesToAccountForSeries(Item,CachedValues,SeriesSpecificationParameters.Returned_);
		
	EndIf;
	
	If Not CancelEdit Then
		LineCache = ?(NewRow, Undefined, ProcessingOfTabularFormsClientServer.LineCache(Items.ReturnedGoods, ThisObject));
		WarehousesClient.UpdateWarehouseTable(TableOfWarehousesReturnedGoods, CurrentData, LineCache, WarehouseGroup_);
		TotalWarehouses_ = TableOfWarehousesReturnedGoods.Count();
		WarehousesClientServer.UpdateWarehouseGroupImage(InscriptionSeveralWarehousesReturnGoods, Items.PictureMultipleWarehousesReturningGoods, TotalWarehouses_);
	EndIf;
	
	If CurrentData <> Undefined Then
		
		If Object.OneDateReceipt Then
			CurrentData.DateOfReceipt = Object.DateOfReceipt;
		EndIf;
		
		If ValueIsFilled(Object.CashRegisterReceipt) Then
			If Not ValueIsFilled(CurrentData.DocumentSalesOfGoodsAndServices) Then
				CurrentData.DocumentSalesOfGoodsAndServices = GetReportOnRetailSalesByCashRegisterReceipt(Object.CashRegisterReceipt);
			EndIf;
		EndIf;
		
	EndIf;
	
	ReusablePackageClient.UpdateFillingStateOfMultiTurnContainer(Object.ReusablePackageFillingStatus);
	
EndProcedure

&AtClient
Procedure ReturnedGoodsBeforeDeleteRow(Item, Cancel)
	
	ProcessingOfTabularFormsClient.CacheCurLine(Items.ReturnedGoods, ThisObject);
	
	ProductsClient.UpdateCachedValuesToAccountForSeries(
	Item,CachedValues,SeriesSpecificationParameters.Returned_);
	
	SetsClient.BeforeDeletingRowOfTablePart(ThisForm, "ReturnedGoods", Cancel);
	
EndProcedure

&AtClient
Procedure ReturnedGoodsProductsRecordingAsReceivedStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	
	CurrentData = Items.ReturnedGoods.CurrentData;
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("CheckCharacteristicsByOwner", CurrentData.Characteristic);
	If ValueIsFilled(CurrentData.Characteristic) Then
		StructureOfActions.Insert("FillInDescriptionOfPoorQualityProduct", CurrentData.Characteristic);
	EndIf;
	StructureOfActions.Insert("FillInArticleAttribute", New Structure("Products, ProductsOfOriginalQuality", "SKU", "SKURegistration"));
	StructureOfActions.Insert("FillInCheckQualityDateOfQualityConfirmation", CacheQualityControl);
	
	WarehousesClient.ChangeQuality(CurrentData, StructureOfActions, CachedValues);
	
EndProcedure

&AtClient
Procedure ReturnedGoodsProductsOnChange(Item)
	
	ClearMessages();
	
	CurrentRow = Items.ReturnedGoods.CurrentData;
	
	If CurrentRow.Damage
		And ValueIsFilled(CurrentRow.ProductsRecordingAsReceived) Then
		ThereIsGradation = CheckForGradationServer(CurrentRow.Products, CurrentRow.ProductsRecordingAsReceived);
		If Not ThereIsGradation Then
			CurrentRow.ProductsRecordingAsReceived = PredefinedValue("Catalog.Products.EmptyRef");
			CurrentRow.CharacteristicRecordingAsReceived = PredefinedValue("Catalog.ItemsCharacteristics.EmptyRef");
			CurrentRow.ItemVariantsAreUsedRecordingAsReceived = False;
		EndIf;
	EndIf;
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("CheckCharacteristicsByOwner", CurrentRow.Characteristic);
	StructureOfActions.Insert("FillInArticleAttribute", New Structure("Products, ProductsRecordingAsReceived", "SKU", "SKURegistration"));
	StructureOfActions.Insert("CheckFillPackageByOwner", CurrentRow.Package);
	StructureOfActions.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
	StructureOfActions.Insert("FillInNoReturnContainerAttribute", Object.ToReturnReusablePackage);
	StructureOfActions.Insert("FillInCanceledWithoutReturnableContainerAttribute", Object.ToReturnReusablePackage);
	StructureOfActions.Insert("CheckFillWarehouse",
		BatchProcessingOfTablePartClientServer.GetWarehouseFillStructureInTSLine(Object, WarehouseGroup_));
	
	StructureOfActions.Insert("RecalculateNumberOfUnits");
	If (ToUseTermsOfSales And ValueIsFilled(Object.Terms)) 
		Or (Not ToUseTermsOfSales And UsePriceManagementSystem25) Then
		StructureOfActions.Insert("FillIn_TermsOfSales", BatchProcessingOfTablePartClientServer.GetStructureForFillingInSalesConditionsInTSLine(Object));
	Else
		StructureOfActions.Insert("FillInSalePrice", BatchProcessingOfTablePartClientServer.ParametersForFillingInPriceInTSLine(Object));
	EndIf;

	ParametersForFillingInVATRate = BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRate(Object);
	If ValueIsFilled(Object.DocumentSalesOfGoodsAndServices) Then
		SaleDate = GeneralPurposeTMServerCall.ObjectAttributeValue(Object.DocumentSalesOfGoodsAndServices, "Date");
		ParametersForFillingInVATRate.Date = SaleDate;
	EndIf;
	
	StructureOfActions.Insert("FillInVATRate", ParametersForFillingInVATRate);
	StructureOfActions.Insert("FillInVATRateByPriceType", BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRateByPriceType(Object));
	StructureOfActions.Insert("FillInVATRateForReturnableContainers", Object.ToReturnReusablePackage);
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmount");
	StructureOfActions.Insert("FillInDuplicateDependentDetails", DependentDetailsReturnedGoods());
	StructureOfActions.Insert("CheckSeriesCalculateStatus",
		New Structure("Warehouse, SeriesSpecificationParameters", CurrentRow.Warehouse, SeriesSpecificationParameters.Returned_));
	StructureOfActions.Insert("FillInCheckQualityDateOfQualityConfirmation", CacheQualityControl);

	StructureOfActions.Insert("ProductsOnChangeOverridable", New Structure("FormName, TabularSectionName",
		ThisForm.FormName, "ReturnedGoods"));

	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	CalculateTotalsOfRefundRequest(ThisForm);
	
EndProcedure

&AtClient
Procedure ReturnedGoodsWarehouseOnChange(Item)
	
	CurrentRow = Items.ReturnedGoods.CurrentData;

	StructureOfActions = New Structure;
	StructureOfActions.Insert("CheckSeriesCalculateStatus",
		New Structure("Warehouse, SeriesSpecificationParameters", CurrentRow.Warehouse, SeriesSpecificationParameters.Returned_));
	StructureOfActions.Insert("FillInCheckQualityDateOfQualityConfirmation", CacheQualityControl);
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	CalculateTotalsOfRefundRequest(ThisForm);
	
EndProcedure

&AtClient
Procedure ReturnedGoodsCharacteristicOnChange(Item)
	
	ClearMessages();
	
	CurrentRow = Items.ReturnedGoods.CurrentData;
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	
	StructureOfActions = New Structure;
	If (ToUseTermsOfSales And ValueIsFilled(Object.Terms)) 
		Or (Not ToUseTermsOfSales And UsePriceManagementSystem25) Then
		StructureOfActions.Insert("FillIn_TermsOfSales", BatchProcessingOfTablePartClientServer.GetStructureForFillingInSalesConditionsInTSLine(Object));
	Else
		StructureOfActions.Insert("FillInSalePrice", BatchProcessingOfTablePartClientServer.ParametersForFillingInPriceInTSLine(Object));
	EndIf;
	
	StructureOfActions.Insert("FillInVATRateByPriceType", BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRateByPriceType(Object));
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmount");
	StructureOfActions.Insert("FillInDuplicateDependentDetails", DependentDetailsReturnedGoods());
	
	StructureOfActions.Insert("CharacteristicOnChangeOverridable", New Structure("FormName, TabularSectionName",
		ThisForm.FormName, "ReturnedGoods"));

	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	CalculateTotalsOfRefundRequest(ThisForm);
	
EndProcedure

&AtClient
Procedure ReturnedGoodsPackageOnChange(Item)
	
	ClearMessages();
	
	CurrentRow = Items.ReturnedGoods.CurrentData;
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	
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
	
	StructureOfActions.Insert("FillInVATRateByPriceType", BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRateByPriceType(Object));
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmount");
	StructureOfActions.Insert("FillInDuplicateDependentDetails", DependentDetailsReturnedGoods());
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	CalculateTotalsOfRefundRequest(ThisForm);
	
EndProcedure

&AtClient
Procedure ReturnedGoodsDamageOnChange(Item)
	
	CurrentRow = Items.ReturnedGoods.CurrentData;
	
	If Not CurrentRow.Damage Then
		CurrentRow.ProductsRecordingAsReceived = PredefinedValue("Catalog.Products.EmptyRef");
		CurrentRow.CharacteristicRecordingAsReceived = PredefinedValue("Catalog.ItemsCharacteristics.EmptyRef");
		CurrentRow.ItemVariantsAreUsedRecordingAsReceived = False;
	EndIf;
	StructureOfActions = New Structure();
	StructureOfActions.Insert("FillInCheckQualityDateOfQualityConfirmation", CacheQualityControl);
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, Undefined);
	
EndProcedure

&AtClient
Procedure ReturnedGoodsNumberOfPackagesOnChange(Item)
	
	CurrentRow = Items.ReturnedGoods.CurrentData;
	
	StructureOfActions = New Structure;
	AddToActionStructureWhenChangingNumberOfPackagesReturnItems(StructureOfActions, Object);	
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	CalculateTotalsOfRefundRequest(ThisForm);
	
EndProcedure

&AtClient
Procedure ReturnedGoodsPriceKindOnChange(Item)
	
	ClearMessages();
	
	CurrentRow = Items.ReturnedGoods.CurrentData;
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInVATRateByPriceType", BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRateByPriceType(Object));
	StructureOfActions.Insert("FillInSalePrice", BatchProcessingOfTablePartClientServer.ParametersForFillingInPriceInTSLine(Object));
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmount");
	StructureOfActions.Insert("FillInDuplicateDependentDetails", DependentDetailsReturnedGoods());
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	CalculateTotalsOfRefundRequest(ThisForm);
	
EndProcedure

&AtClient
Procedure ReturnedGoodsPriceOnChange(Item)
	
	CurrentRow = Items.ReturnedGoods.CurrentData;
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmount");
	StructureOfActions.Insert("FillInDuplicateDependentDetails", DependentDetailsReturnedGoods());
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	CalculateTotalsOfRefundRequest(ThisForm);
	
EndProcedure

&AtClient
Procedure ReturnedGoodsVATRateOnChange(Item)
	
	CurrentRow = Items.ReturnedGoods.CurrentData;
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmount");
	StructureOfActions.Insert("FillInDuplicateDependentDetails", DependentDetailsReturnedGoods());
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	CalculateTotalsOfRefundRequest(ThisForm);
	
EndProcedure

&AtClient
Procedure ReturnedGoodsSumOnChange(Item)
	
	CurrentRow = Items.ReturnedGoods.CurrentData;
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculatePriceDiscountByAmountInSales");
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("FillInDuplicateDependentDetails", DependentDetailsReturnedGoods());
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	CalculateTotalsOfRefundRequest(ThisForm);
	
EndProcedure

&AtClient
Procedure ReturnedGoodsProductsRecordingAsReceivedOnChange(Item)
	
	CurrentData = Items.ReturnedGoods.CurrentData;
	
	CurrentRow = New Structure;
	CurrentRow.Insert("Products", CurrentData.ProductsRecordingAsReceived);
	CurrentRow.Insert("ItemVariantsAreUsed");
	CurrentRow.Insert("Characteristic", CurrentData.CharacteristicRecordingAsReceived);
	CurrentRow.Insert("SKU", CurrentData.SKURegistration);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("CheckCharacteristicsByOwner", CurrentData.CharacteristicRecordingAsReceived);
	StructureOfActions.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, Undefined);
	
	CurrentData.ItemVariantsAreUsedRecordingAsReceived   = CurrentRow.ItemVariantsAreUsed;
	CurrentRow.Property("Characteristic", CurrentData.CharacteristicRecordingAsReceived);
	CurrentData.SKURegistration = CurrentRow.SKU;
	
	StructureOfActions = New Structure();
	StructureOfActions.Insert("FillInCheckQualityDateOfQualityConfirmation", CacheQualityControl);
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentData, StructureOfActions, Undefined);
	
EndProcedure

&AtClient
Procedure ReturnedGoodsDateOfReceiptOnChange(Item)
	
	CurrentRow = Items.ReturnedGoods.CurrentData;
	StructureOfActions = New Structure();
	StructureOfActions.Insert("FillInCheckQualityDateOfQualityConfirmation", CacheQualityControl);
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
EndProcedure

&AtClient
Procedure ReturnedGoodsCanceledOnChange(Item)
	
	CurrentRow = Items.ReturnedGoods.CurrentData;
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInCanceledWithoutReturnableContainerAttribute", Object.ToReturnReusablePackage);
	StructureOfActions.Insert("FillInDuplicateDependentDetails", DependentDetailsReturnedGoods());
	StructureOfActions.Insert("FillInCheckQualityDateOfQualityConfirmation", CacheQualityControl);
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
	CalculateTotalsOfRefundRequest(ThisForm);
	
EndProcedure

&AtClient
Procedure ReturnedGoodsDocumentSalesOfGoodsAndServicesStartChoice(Item)
	
	If ConsignmentSales25
		And Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.ReturnFromCommissionAgent") Then
		 
		NewArray = New Array();
		NewArray.Add(New ChoiceParameter("Filter.Contract", Object.Contract));
		NewArray.Add(New ChoiceParameter("DocumentBusinessTransaction", Object.BusinessOperation));
		Items.ReturnedGoodsDocumentSalesOfGoodsAndServices.ChoiceParameters = New FixedArray(NewArray);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ReturnedGoodsDocumentSalesOfGoodsAndServicesOnChange(Item)
	
	UpdateInformationOnImplementations();
	
EndProcedure

&AtClient
Procedure ReturnedGoodsSeriesStartChoice(Item, ChoiceData, StandardProcessing)
	StandardProcessing = False;
	OpenSelectionOfSeries("Returned_", Item.EditText);
EndProcedure

&AtClient
Procedure ReturnedGoodsSeriesOnChange(Item)
	ValueSelected = ProductsClientServer.SelectedSeries();
	
	ValueSelected.Value            		 = Items.ReturnedGoods.CurrentData.Series;
	ValueSelected.CurrentRowID = Items.ReturnedGoods.CurrentData.GetID();
	
	ProductsClient.ProcessSeriesIndication(ThisForm, SeriesSpecificationParameters.Returned_, ValueSelected);
EndProcedure

&AtClient
Procedure ReturnedGoodsToControlQualityOnChange(Item)
	
	CurrentData = Items.ReturnedGoods.CurrentData;
	If Not CurrentData.ToControlQuality Then
		CurrentData.QualityConfirmationDate = '00010101';
	EndIf;
	
EndProcedure

&AtClient
Procedure ReturnedGoodsQualityConfirmationDateOnChange(Item)
	
	CurrentData = Items.ReturnedGoods.CurrentData;
	If Not CurrentData.ToControlQuality Then
		CurrentData.QualityConfirmationDate = '00010101';
	EndIf;
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersSubstituteGoods

&AtClient
Procedure SubstituteGoodsAfterDeleteRow(Item)
	
	ProvisionInDocumentsClientServer.FillInServiceDetails(Object.SubstituteGoods,
		DateOfShipmentRequired_, WarehouseIsRequired);
	
	CalculateTotalsOfRefundRequest(ThisForm);
	DiscountsMarkupsFillingClient.ResetDiscountsCalculatedFlag(ThisForm);
	ReusablePackageClient.UpdateFillingStateOfMultiTurnContainer(Object.ReusablePackageFillingStatus);
	
	ThereIsChangeInShippingDates = ARAPAccountingClient.ThereIsChangeInShippingDates(ThisObject);
	ReplacementGoodsAfterDeletionAtServer(ThereIsChangeInShippingDates);
	
EndProcedure

&AtClient
Procedure SubstituteGoodsOnEditEnd(Item, NewRow, CancelEdit)
	
	CalculateTotalsOfRefundRequest(ThisForm);
	
	CurrentData = Items.SubstituteGoods.CurrentData;
	
	If Not CancelEdit Then
		LineCache = ?(NewRow, Undefined, ProcessingOfTabularFormsClientServer.LineCache(Items.SubstituteGoods, ThisObject));
		WarehousesClient.UpdateWarehouseTable(TableOfWarehousesReplacingGoods, CurrentData, LineCache, WarehouseGroup_, False);
		TotalWarehouses_ = TableOfWarehousesReplacingGoods.Count();
		WarehousesClientServer.UpdateWarehouseGroupImage(InscriptionSeveralWarehousesReplacingGoods, Items.PictureSeveralWarehousesReplacingGoods, TotalWarehouses_);
	EndIf;
	
	If CurrentData <> Undefined And Object.NotShipInInstallments Then
		CurrentData.DateOfShipment = Object.DateOfShipment;
	EndIf;
	
	ReusablePackageClient.UpdateFillingStateOfMultiTurnContainer(Object.ReusablePackageFillingStatus);
	
EndProcedure

&AtClient
Procedure SubstituteGoodsOnStartEdit(Item, NewRow, Copy)
	
	ProcessingOfTabularFormsClient.CacheCurLine(Items.SubstituteGoods, ThisObject);
	CurrentRow = Items.SubstituteGoods.CurrentData;
	
	If NewRow And Not Copy Then
		CurrentRow.Department = Object.Department;
	EndIf;
	
	SalesClient.ProductItemLineAtBeginningOfEditing(ThisForm, "SubstituteGoods", CurrentRow, NewRow, Copy);
	
	If NewRow Then
		CurrentRow.RowCode = 0;
	EndIf;
	
	If Copy Then
		StructureOfActions = New Structure;
		
		AddCollateralActionsOnClient(StructureOfActions,
			"SupplyOption,Available,WarehouseIsRequired,DateOfShipmentRequired_");
		BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
		ProvisionInDocumentsClientServer.FillInServiceDetails(Object.SubstituteGoods,
			DateOfShipmentRequired_, WarehouseIsRequired);
	EndIf;
	
	ARAPAccountingClient.SaveShipmentDatesInParameters(ThisObject);
	
EndProcedure

&AtClient
Procedure SubstituteGoodsSelection(Item, RowSelected, Field, StandardProcessing)
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.StartTimeMeasurement(
		True, "Document.RequestForReturnOfGoodsFromCustomer.Form.DocumentForm.Items.SubstituteGoods.Selection");

	If Item.CurrentItem = Items.SubstituteGoodsAvailable And Not ReadOnly Then
		
		StandardProcessing = False;
		
		FormParameters = ParametersOfQuantityAndSeriesRequestForm(Undefined);
		
		If FormParameters <> Undefined Then
			OpenForm("DataProcessor.QuantityAndBatchRequest.Form", FormParameters, ThisObject);
		EndIf;
		
	ElsIf Item.CurrentItem = Items.SubstituteGoodsPercentRateOfAutomaticDiscountMarkup
		Or Item.CurrentItem = Items.SubstituteGoodsDiscountMarkupAmount Then
		
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
		
		CurrentData = Items.SubstituteGoods.CurrentData;
		DiscountsMarkupsFillingClient.OpenAppliedDiscountsForm(CurrentData, Object, ThisForm);
		
	ElsIf Field = Items.SubstituteGoodsPrice Then
		
		CurrentData = Items.SubstituteGoods.CurrentData;
		If ValueIsFilled(CurrentData.PriceKind) And Not Object.Approved Then
			ClearMessages();
			CommonClientServer.MessageToUser(
			NStr("vi = 'Để soạn đơn giá, hãy xóa dạng giá';
				|ru = 'Для редактирования цены очистите вид цены';
				|en = 'To edit the price, clear the price type'; fa = 'To edit the price, clear the price type';
				|it = 'Для редактирования цены очистите вид цены';
				|pl = 'To edit the price, clear the price type';
				|tr = 'Fiyatı düzenlemek için fiyat türünü temizleyin'"),
			Object.Ref,
			CommonClientServer.PathToTabularSection("Object.SubstituteGoods", CurrentData.LineNumber, "PriceKind"),);
		EndIf;
		
	ElsIf SetsClient.ItemToLock(Field) Then
		
		CurrentRow = Object.SubstituteGoods.FindByID(RowSelected);
		If ValueIsFilled(CurrentRow.ProductsInSet) Then
			
			NotificationParameter1 = New Structure;
			NotificationParameter1.Insert("ProductsInSet",   CurrentRow.ProductsInSet);
			NotificationParameter1.Insert("ItemVariantOfSet", CurrentRow.ItemVariantOfSet);
			NotificationParameter1.Insert("TSName", "SubstituteGoods");
			NotificationParameter1.Insert("OwnerForm", UUID);
			
			Notify("EditSet", NotificationParameter1, ThisForm);
			
		EndIf;
		
	ElsIf Field = Items.SubstituteGoodsProductsInSet Then
		
		ShowValue(Undefined, Items.SubstituteGoods.CurrentData.ProductsInSet);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure SubstituteGoodsBeforeDeleteRow(Item, Cancel)
	
	ProcessingOfTabularFormsClient.CacheCurLine(Items.SubstituteGoods, ThisObject);
	SetsClient.BeforeDeletingRowOfTablePart(ThisForm, "SubstituteGoods", Cancel);
	ARAPAccountingClient.SaveShipmentDatesInParameters(ThisObject);
	
EndProcedure

&AtClient
Procedure SubstituteGoodsChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	HandlingSelectionSelectionOnClient(ValueSelected);
	
	If Window <> Undefined Then
		Window.Activate();
	EndIf;
	
EndProcedure

&AtClient
Procedure SubstituteGoodsContentStartChoice(Item, ChoiceData, StandardProcessing)
	
	CommonClient.ShowCommentEditingForm(
		Item.EditText,
		ThisObject,
		"Items.SubstituteGoods.CurrentData.Content",
		NStr("vi = 'Nội dung dịch vụ';
			|ru = 'Содержание услуги';
			|en = 'Service content'; fa = 'Service content';
			|it = 'Contenuto del servizio';
			|pl = 'Opis usługi';
			|tr = 'Hizmet içeriği'"));
	
EndProcedure

&AtClient
Procedure SubstituteGoodsProductsOnChange(Item)
	
	ClearMessages();
	
	CurrentRow = Items.SubstituteGoods.CurrentData;
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("CheckCharacteristicsByOwner", CurrentRow.Characteristic);
	StructureOfActions.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));
	StructureOfActions.Insert("CheckFillPackageByOwner", CurrentRow.Package);
	StructureOfActions.Insert("CheckFillWarehouse",
		BatchProcessingOfTablePartClientServer.GetWarehouseFillStructureInTSLine(Object, WarehouseGroup_));
		
	StructureOfActions.Insert("RecalculateNumberOfUnits");
	If (ToUseTermsOfSales And ValueIsFilled(Object.Terms)) 
		Or (Not ToUseTermsOfSales And UsePriceManagementSystem25) Then
		StructureOfActions.Insert("FillIn_TermsOfSales", BatchProcessingOfTablePartClientServer.GetStructureForFillingInSalesConditionsInTSLine(Object));
	Else
		StructureOfActions.Insert("FillInSalePrice", BatchProcessingOfTablePartClientServer.ParametersForFillingInPriceInTSLine(Object));
	EndIf;

	ParametersForFillingInVATRate = BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRate(Object, True);
	If Object.NotShipInInstallments And ValueIsFilled(Object.DateOfShipment) Then
		ParametersForFillingInVATRate.Date = Object.DateOfShipment;
	EndIf;
	
	StructureOfActions.Insert("FillInVATRate", ParametersForFillingInVATRate);
	StructureOfActions.Insert("FillInVATRateByPriceType", BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRateByPriceType(Object));
	StructureOfActions.Insert("FillInVATRateForReturnableContainers", Object.ToReturnReusablePackage);
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmount");
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountManualDiscount", New Structure("Clear", True));
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountAutomaticDiscount", New Structure("Clear", True));
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountDiscountWithBonusPoints");
	StructureOfActions.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
	StructureOfActions.Insert("FillInSalesOptionAttribute", New Structure("Products", "SaleRegistrationOption"));
	StructureOfActions.Insert("FillInContent", BatchProcessingOfTablePartClientServer.GetStructureOfFillingInServiceContentInTSLine(Object, False));
	StructureOfActions.Insert("FillInDuplicateDependentDetails", DependentDetailsReplacingGoods());
	StructureOfActions.Insert("FillInNoReturnContainerAttribute", Object.ToReturnReusablePackage);
	StructureOfActions.Insert("FillInCanceledWithoutReturnableContainerAttribute", Object.ToReturnReusablePackage);
	StructureOfActions.Insert("CheckSeriesCalculateStatus",
		New Structure("Warehouse, SeriesSpecificationParameters", CurrentRow.Warehouse, SeriesSpecificationParameters.Substitutes_));
	
	AddCollateralActionsOnClient(StructureOfActions,
		"SupplyOption,AvailableInOtherLines,WarehouseIsRequired,DateOfShipmentRequired_");
	
	StructureOfActions.Insert("ProductsOnChangeOverridable", New Structure("FormName, TabularSectionName",
		FormName, "SubstituteGoods"));

	StructureOfActions.Insert("FillInSubdivisionInTSLine", New Structure("Department", Object.Department));
	
	BatchProcessingOfTablePartClientServerLocalization.CompleteActionStructureWhenChangingElement(ThisObject, "Products", StructureOfActions);
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
	TypesList = SalesClient.TypesOfNomenclatureWithUnitAnalytics();
	If TypesList.FindByValue(CurrentRow.ItemsType) = Undefined Then
		CurrentRow.Department = PredefinedValue("Catalog.BusinessStructure.EmptyRef");
	EndIf;
	
	If ProvisionInDocumentsClient.YouNeedToUpdateAvailableColumn(StructureOfActions) Then
		UpdateColumnAvailableServer();
	EndIf;
	ProvisionInDocumentsClientServer.FillInServiceDetails(Object.SubstituteGoods,
		DateOfShipmentRequired_, WarehouseIsRequired);
	
	CalculateTotalsOfRefundRequest(ThisObject);
	
	DiscountsMarkupsFillingClient.ResetDiscountsCalculatedFlag(ThisObject);
	
EndProcedure

&AtClient
Procedure SubstituteGoodsDateOfShipmentOnChange(Item)
	
	CurrentRow = Items.SubstituteGoods.CurrentData;
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	
	StructureOfActions = New Structure;
	ParametersForFillingInVATRate = BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRate(Object, True);
	StructureOfActions.Insert("FillInVATRate", ParametersForFillingInVATRate);
		BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	StructureOfActions.Insert("FillInVATRateForReturnableContainers", Object.ToReturnReusablePackage);
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmount");
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountManualDiscount", New Structure("Clear", True));
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountAutomaticDiscount", New Structure("Clear", True));
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountDiscountWithBonusPoints");
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
	CalculateTotalsOfRefundRequest(ThisObject);
	
	DiscountsMarkupsFillingClient.ResetDiscountsCalculatedFlag(ThisObject);
	
EndProcedure

&AtClient
Procedure SubstituteGoodsWarehouseOnChange(Item)
	
	CurrentRow = Items.SubstituteGoods.CurrentData;
	
	StructureOfActions = New Structure;
	
	StructureOfActions.Insert("CheckSeriesCalculateStatus",
		New Structure("Warehouse, SeriesSpecificationParameters", CurrentRow.Warehouse, SeriesSpecificationParameters.Substitutes_));
		
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
		
EndProcedure

&AtClient
Procedure SubstituteGoodsCharacteristicOnChange(Item)
	
	ClearMessages();
	
	CurrentRow = Items.SubstituteGoods.CurrentData;
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	
	StructureOfActions = New Structure;
	If (ToUseTermsOfSales And ValueIsFilled(Object.Terms)) 
		Or (Not ToUseTermsOfSales And UsePriceManagementSystem25) Then
		StructureOfActions.Insert("FillIn_TermsOfSales", BatchProcessingOfTablePartClientServer.GetStructureForFillingInSalesConditionsInTSLine(Object));
	Else
		StructureOfActions.Insert("FillInSalePrice", BatchProcessingOfTablePartClientServer.ParametersForFillingInPriceInTSLine(Object));
	EndIf;
	
	StructureOfActions.Insert("FillInVATRateByPriceType", BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRateByPriceType(Object));
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmount");
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountManualDiscount", New Structure("Clear", True));
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountAutomaticDiscount", New Structure("Clear", True));
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountDiscountWithBonusPoints");
	StructureOfActions.Insert("FillInContent", BatchProcessingOfTablePartClientServer.GetStructureOfFillingInServiceContentInTSLine(Object, False));
	StructureOfActions.Insert("FillInDuplicateDependentDetails", DependentDetailsReplacingGoods());
	
	AddCollateralActionsOnClient(StructureOfActions,
		"SupplyOption,AvailableInOtherLines,WarehouseIsRequired,DateOfShipmentRequired_");
	
	StructureOfActions.Insert("CharacteristicOnChangeOverridable", New Structure("FormName, TabularSectionName",
		ThisForm.FormName, "SubstituteGoods"));

	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	If ProvisionInDocumentsClient.YouNeedToUpdateAvailableColumn(StructureOfActions) Then
		UpdateColumnAvailableServer();
	EndIf;
	
	ProvisionInDocumentsClientServer.FillInServiceDetails(Object.SubstituteGoods,
		DateOfShipmentRequired_, WarehouseIsRequired);

	CalculateTotalsOfRefundRequest(ThisForm);
	DiscountsMarkupsFillingClient.ResetDiscountsCalculatedFlag(ThisForm);
	
EndProcedure

&AtClient
Procedure SubstituteGoodsPackageOnChange(Item)
	
	CurrentRow = Items.SubstituteGoods.CurrentData;
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	
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
	
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmount");
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountManualDiscount", New Structure("Clear", False));
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountAutomaticDiscount", New Structure("Clear", True));
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountDiscountWithBonusPoints");
	StructureOfActions.Insert("FillInDuplicateDependentDetails", DependentDetailsReplacingGoods());
	AddCollateralActionsOnClient(StructureOfActions, "AvailableInOtherLines");
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
	If ProvisionInDocumentsClient.YouNeedToUpdateAvailableColumn(StructureOfActions) Then
		UpdateColumnAvailableServer();
	EndIf;
	
	CalculateTotalsOfRefundRequest( ThisForm);
	DiscountsMarkupsFillingClient.ResetDiscountsCalculatedFlag(ThisForm);
	
EndProcedure

&AtClient
Procedure SubstituteGoodsNumberOfPackagesOnChange(Item)
	
	CurrentRow = Items.SubstituteGoods.CurrentData;
	
	StructureOfActions = New Structure;
	AddReplacementProductsToActionStructureWhenChangingNumberOfPackages(StructureOfActions, Object);
	AddCollateralActionsOnClient(StructureOfActions, "AvailableInOtherLines");
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
	If ProvisionInDocumentsClient.YouNeedToUpdateAvailableColumn(StructureOfActions) Then
		UpdateColumnAvailableServer();
	EndIf;
	
	CalculateTotalsOfRefundRequest(ThisForm);
	DiscountsMarkupsFillingClient.ResetDiscountsCalculatedFlag(ThisForm);
	
EndProcedure

&AtClient
Procedure SubstituteGoodsPriceKindOnChange(Item)
	
	ClearMessages();
	
	CurrentRow = Items.SubstituteGoods.CurrentData;
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInVATRateByPriceType", BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRateByPriceType(Object));
	StructureOfActions.Insert("FillInSalePrice", BatchProcessingOfTablePartClientServer.ParametersForFillingInPriceInTSLine(Object));
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmount");
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountManualDiscount", New Structure("Clear", False));
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountAutomaticDiscount", New Structure("Clear", True));
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountDiscountWithBonusPoints");
	StructureOfActions.Insert("FillInDuplicateDependentDetails", DependentDetailsReplacingGoods());
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
	CalculateTotalsOfRefundRequest(ThisForm);
	DiscountsMarkupsFillingClient.ResetDiscountsCalculatedFlag(ThisForm);
	
EndProcedure

&AtClient
Procedure SubstituteGoodsPriceOnChange(Item)
	
	CurrentRow = Items.SubstituteGoods.CurrentData;
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmount");
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountManualDiscount", New Structure("Clear", False));
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountAutomaticDiscount", New Structure("Clear", True));
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountDiscountWithBonusPoints");
	StructureOfActions.Insert("FillInDuplicateDependentDetails", DependentDetailsReplacingGoods());
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
	CalculateTotalsOfRefundRequest(ThisForm);
	DiscountsMarkupsFillingClient.ResetDiscountsCalculatedFlag(ThisForm);
	
EndProcedure

&AtClient
Procedure SubstituteGoodsVATRateOnChange(Item)
	
	CurrentRow = Items.SubstituteGoods.CurrentData;
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmount");
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountManualDiscount", New Structure("Clear", False));
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountAutomaticDiscount", New Structure("Clear", True));
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountDiscountWithBonusPoints");
	StructureOfActions.Insert("FillInDuplicateDependentDetails", DependentDetailsReplacingGoods());
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
	CalculateTotalsOfRefundRequest(ThisForm);
	DiscountsMarkupsFillingClient.ResetDiscountsCalculatedFlag(ThisForm);
	
EndProcedure

&AtClient
Procedure SubstituteGoodsCanceledOnChange(Item)
	
	CurrentRow = Items.SubstituteGoods.CurrentData;
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInCanceledWithoutReturnableContainerAttribute", Object.ToReturnReusablePackage);
	StructureOfActions.Insert("FillInDuplicateDependentDetails", DependentDetailsReplacingGoods());
	AddCollateralActionsOnClient(StructureOfActions, "AvailableInOtherLines,WarehouseIsRequired,DateOfShipmentRequired_");
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
	If ProvisionInDocumentsClient.YouNeedToUpdateAvailableColumn(StructureOfActions) Then
		UpdateColumnAvailableServer();
	EndIf;
	
	If Not CurrentRow.Canceled Then
		CurrentRow.CancellationReason = PredefinedValue("Catalog.ReasonsForSaleOrderCancellation.EmptyRef");
		Object.Approved = False;
	EndIf;
	
	ProvisionInDocumentsClientServer.FillInServiceDetails(Object.SubstituteGoods,
		DateOfShipmentRequired_, WarehouseIsRequired);
		
	OnChangingWarehouseInTablePartReplacingGoodsServer();		
	
	CalculateTotalsOfRefundRequest(ThisForm);
	
	If ARAPAccountingClient.ThereIsChangeInShippingDates(ThisObject) Then
		ReplacementGoodsCancelledOnChangeATServer();
	EndIf;
	
EndProcedure

&AtClient
Procedure SubstituteGoodsDepartmentOnChange(Item)
	UpdateColumnAvailableServer();
EndProcedure

&AtClient
Procedure SubstituteGoodsPercentRateOfManualDiscountOnChange(Item)
	
	CurrentRow = Items.SubstituteGoods.CurrentData;
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateAmountOfManualDiscount");
	StructureOfActions.Insert("RecalculateAmount");
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountManualDiscount", New Structure("Clear", False));
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountAutomaticDiscount", New Structure("Clear", False));
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountDiscountWithBonusPoints");
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("FillInDuplicateDependentDetails", DependentDetailsReplacingGoods());
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
	CalculateTotalsOfRefundRequest(ThisObject);
	
EndProcedure

&AtClient
Procedure SubstituteGoodsManualDiscountOnChange(Item)
	
	CurrentRow = Items.SubstituteGoods.CurrentData;
	
	StructureOfRecalculationOfAmount =BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculatePercentageOfManualDiscount");
	StructureOfActions.Insert("RecalculateAmount");
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountManualDiscount", New Structure("Clear, RecalculateAmountOfManualDiscount_", False, False));
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountAutomaticDiscount", New Structure("Clear", False));
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountDiscountWithBonusPoints");
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("FillInDuplicateDependentDetails", DependentDetailsReplacingGoods());
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
	CalculateTotalsOfRefundRequest(ThisForm);
	
EndProcedure

&AtClient
Procedure SubstituteGoodsSumOnChange(Item)
	
	CurrentRow = Items.SubstituteGoods.CurrentData;
	
	ThisIsTransferToCommission = Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.ReturnFromCommissionAgent")
		Or Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.ReturnFromCustodian");
	
	StructureOfPriceConversion  = BatchProcessingOfTablePartClientServer.GetStructureForRecalculatingDiscountPriceInWHSales(Object,
		ThisIsTransferToCommission);
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculatePriceDiscountByAmountInSales", StructureOfPriceConversion);
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("FillInDuplicateDependentDetails", DependentDetailsReplacingGoods());
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
	CalculateTotalsOfRefundRequest(ThisForm);
	
	DiscountsMarkupsFillingClient.ResetDiscountsCalculatedFlag(ThisForm);
	
EndProcedure

&AtClient
Procedure SubstituteGoodsVATAmountOnChange(Item)
	
	CurrentRow = Items.SubstituteGoods.CurrentData;
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("FillInDuplicateDependentDetails", DependentDetailsReplacingGoods());
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
	CalculateTotalsOfRefundRequest(ThisForm);
	
EndProcedure

&AtClient
Procedure SubstituteGoodsSeriesStartChoice(Item, ChoiceData, StandardProcessing)
	StandardProcessing = False;
	OpenSelectionOfSeries("Substitutes_", Item.EditText);
EndProcedure

&AtClient
Procedure SubstituteGoodsSeriesOnChange(Item)
	ValueSelected = ProductsClientServer.SelectedSeries();
	
	ValueSelected.Value            		 = Items.SubstituteGoods.CurrentData.Series;
	ValueSelected.CurrentRowID = Items.SubstituteGoods.CurrentData.GetID();
	
	ProductsClient.ProcessSeriesIndication(ThisForm, SeriesSpecificationParameters.Substitutes_, ValueSelected);
EndProcedure

&AtClient
Procedure ReplacementProductsAutoMarkBlank()
	If Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.ReturnFromCommissionAgent") Then
		Items.SubstituteGoods.AutoMarkIncomplete = False;	
	Else 
		Items.SubstituteGoods.AutoMarkIncomplete = True;
	EndIf;  		
EndProcedure

&AtClient
Procedure SubstituteGoodsSupplyOptionChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	ProvisionInDocumentsClient.SupplyOptionChoiceProcessing(
		ThisObject,
		Items.SubstituteGoods.CurrentData,
		ValueSelected);
	
EndProcedure

&AtClient
Procedure SubstituteGoodsSupplyOptionOnChange(Item)
	
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
		"SubstituteGoodsCollateralOptionWhenChangedAfterIssue");
	
EndProcedure

&AtClient
Procedure SubstituteGoodsSupplyOptionClearing(Item, StandardProcessing)
	
	StandardProcessing = False;
	
EndProcedure

&AtClient
Procedure SubstituteGoodsWithAssignmentOnChange(Item)
	
	TableRow = Items.SubstituteGoods.CurrentData;
	ProvisionInDocumentsClient.WithAssignmentOnChange(TableRow);
	StructureOfActions = New Structure();
	AddCollateralActionsOnClient(StructureOfActions, "AvailableInOtherLines");
	BatchProcessingOfTablePartClient.ProcessTSString(TableRow, StructureOfActions, Undefined);
	If ProvisionInDocumentsClient.YouNeedToUpdateAvailableColumn(StructureOfActions) Then
		UpdateColumnAvailableServer();
	EndIf;
	
EndProcedure

&AtClient
Procedure SubstituteGoodsBeforeRowChange(Item, Cancel)
	
	SubstituteGoodsBeforeRowChangeLocalization(Item, Cancel);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

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
Procedure ReturnOfSpoiledGoods(Command)
	
	If Object.ReturnOfSpoiledGoods Then
		
		ThereAreLinesWithCorruption = CheckDisableConfigureFormForCorruption();
		
		If ThereAreLinesWithCorruption Then
			ShowQueryBox(New CallbackDescription("ReturnOfSpoiledGoodsCompletion", ThisObject), NStr("vi = 'Trong quá trình vận hành, thông tin về chất lượng của hàng trả lại sẽ bị xóa. Tiếp tục?';
																									|ru = 'При выполнении операции будет очищена информация о качестве возвращаемых товаров. Продолжить?';
																									|en = 'Item quality will be cleared. Do you want to continue?'; fa = 'Item quality will be cleared. Do you want to continue?';
																									|it = 'Quando si esegue l''operazione, le informazioni sulla qualità delle merci in reso verranno cancellate. Continuare?';
																									|pl = 'Podczas wykonania operacji będzie oczyszczona informacja o jakości zwracanych towarów. Kontynuować?';
																									|tr = 'İşlem, iade edilen malların kalitesi hakkındaki bilgileri temizleyecektir. Devam edilsin mi?'"),QuestionDialogMode.YesNo,,DialogReturnCode.Yes);
		EndIf;
		
	Else
		Object.ReturnOfSpoiledGoods = True;
		CustomizeFormElements();
	EndIf;
	
EndProcedure

&AtClient
Procedure ReturnOfSpoiledGoodsCompletion(QuestionResult, AdditionalParameters) Export
    
    Response = QuestionResult;
    If Response <> DialogReturnCode.Yes Then
        Return;
    Else
        ClearDisableConfigureFormForCorruption();
    EndIf;

EndProcedure

&AtClient
Procedure ReturnedGoodsFillInPricesByAgreement()
	
	ClearMessages();
	
	If ConsignmentSales25 Then
		
		TypeOfContractPrice = AccountingTypeOfContractPrice();
		
		If EnterprisePricesFillingClient.YouNeedToFillInPricesByType(Object, TypeOfContractPrice) Then
			
			ErrorText = "";
			PricesCalculated = ReturnedGoodsFillInPricesByAgreementServer(, ErrorText);
			SalesClient.NotifyAboutEndOfFillingInPricesUnderAgreement(PricesCalculated, ErrorText);
			
		EndIf;
		
	ElsIf EnterprisePricesFillingClient.ItIsNecessaryToFillInPricesByAgreement(Object, "ReturnedGoods", NStr("vi = 'Hàng hóa bị trả lại';
																											|ru = 'Возвращаемые товары';
																											|en = 'Goods pending return'; fa = 'کالای در انتظار برگشت';
																											|it = 'Merci da rendere';
																											|pl = 'Zwracane wiersze pozycji';
																											|tr = 'İade edilen ürünler'")) Then
		
		ErrorText = "";
		PricesCalculated = ReturnedGoodsFillInPricesByAgreementServer(, ErrorText);
		SalesClient.NotifyAboutEndOfFillingInPricesUnderAgreement(PricesCalculated, ErrorText);
		
	EndIf;
	
EndProcedure
 
&AtServer
Function AccountingTypeOfContractPrice()
	
	ParametersStructure = EnterprisePricesFillingServer.NewParametersForCheckingTypeOfContractPrices();
	ParametersStructure.FieldPriceType = "PriceTypeAccountingPriceType";
	ParametersStructure.TabularSectionName = "ReturnedGoods";
	
	If ValueIsFilled(Object.Contract) Then
		PriceKind = Common.ObjectAttributeValue(Object.Contract, ParametersStructure.FieldPriceType);
		If ValueIsFilled(PriceKind) Then
			ParametersStructure.PriceKind = PriceKind;
		EndIf;
	EndIf;
	
	Return ParametersStructure;
	
EndFunction

 &AtClient
Procedure ReturnedItemsFillInPricesOfSelectedRowsByPriceType(Command)
	
	If EnterprisePricesFillingClient.ItIsNecessaryToFillInPricesByTypeOfPrices(Object, "ReturnedGoods", NStr("vi = 'Hàng hóa trả lại';
																											|ru = 'Возвращаемые товары';
																											|en = 'Goods pending return'; fa = 'کالای در انتظار برگشت';
																											|it = 'Merci da rendere';
																											|pl = 'Zwracane wiersze pozycji';
																											|tr = 'İade edilen ürünler'")) Then
		
		PriceSelectionOptions = EnterprisePricesFillingClient.NewFillOptionsSelectPriceType();
		PriceSelectionOptions.CallbackDescription = 
			New CallbackDescription("ReturnedItemsFillInPricesOfSelectedRowsByPriceTypeCompletion", ThisObject);
		If Object.BusinessOperation <> PredefinedValue("Enum.BusinessTransactions.ReturnFromCustodian")
			And Not ConsignmentSales25 Then
			PriceSelectionOptions.PriceIncludesVAT = Object.PriceIncludesVAT;
		EndIf;
		PriceSelectionOptions.UseWhileSellingToCustomers = True;
		PriceSelectionOptions.OwnerOfAnIndividualPriceType = ?(ToUseTermsOfSales,Object.Terms,Object.Partner);
		
		EnterprisePricesFillingClient.ChooseTypeOfPrices(PriceSelectionOptions);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ReturnedItemsFillInPricesOfSelectedRowsByPriceTypeCompletion(PricesKind, AdditionalParameters) Export
	
	ClearMessages();
	
	If ValueIsFilled(PricesKind) Then
		
		PricesCalculated = ReturnedItemsFillInPricesOfSelectedRowsByPriceTypeServer(PricesKind);
		SalesClient.NotifyAboutEndOfFillingInPricesByTypeOfPrices(PricesCalculated, PricesKind);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ReturnedGoodsFillInReceiptDateForSelectedLines(Command)
	
	If Items.ReturnedGoods.SelectedRows.Count() > 0 Then
		FillInDateOfReceipt(Items.ReturnedGoods.SelectedRows);
	EndIf;
	
EndProcedure

&AtClient
Procedure ReturnedProductsBarcodeSearchExecute(Command)
	
	ClearMessages();
	Notification = New CallbackDescription("ReturnedProductsBarcodeSearchCompletion", ThisObject);
	BarcodingOfItemsClient.ShowBarcodeInput(Notification);
	
EndProcedure

&AtClient
Procedure ReturnedProductsBarcodeSearchCompletion(BarcodeData_2, AdditionalParameters) Export
	
	ProcessBarcodes(BarcodeData_2, "ReturnedGoods");
	
EndProcedure

&AtClient
Procedure ToPickUpTheGoodsInImplementations(Command)
	
	Cancel = False;
	ClearMessages();
	ReturnFromRetailCustomer = False;
	
	If Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.ReturnFromRetailCustomer") Then
		ReturnFromRetailCustomer = True;
	EndIf;
	
	If Not ValueIsFilled(Object.Currency) Then
		CommonClient.MessageToUser(
		NStr("vi = 'Chưa điền trường ""Tiền tệ""';
			|ru = 'Поле ""Валюта"" не заполнено';
			|en = '""Currency"" is required'; fa = '""Currency"" is required';
			|it = 'Il campo ""Valuta"" non è compilato';
			|pl = 'Pole ""Waluta"" nie jest wypełnione';
			|tr = '""Para Birimi"" alanı doldurulmadı'"),
		Object.Ref, "Object.Currency",
		,
		Cancel);
	EndIf;
	
	If Not Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.ReturnFromCommissionAgent")
		And Not ValueIsFilled(Object.VATTaxation) Then
		CommonClient.MessageToUser(
		NStr("vi = 'Chưa điền trường ""Tính thuế GTGT""';
			|ru = 'Поле ""Налогообложение НДС"" не заполнено';
			|en = '""VAT taxation"" is not filled in'; fa = '""VAT taxation"" is not filled in';
			|it = 'Il campo ""Tassazione IVA"" non è compilato';
			|pl = 'Pole ""Opodatkowanie VAT"" nie jest wypełnione';
			|tr = '""KDV vergilendirmesi"" alanı doldurulmamış'"),
		Object.Ref, "Object.VATTaxation",
		,
		Cancel);
	EndIf;
	
	If Not ValueIsFilled(Object.Organization) Then
		CommonClient.MessageToUser(
			NStr("vi = 'Chưa điền trường ""Doanh nghiệp""';
				|ru = 'Поле ""Организация"" не заполнено';
				|en = '""Company"" is required'; fa = '""Company"" is required';
				|it = 'Il campo ""Società"" non è compilato';
				|pl = 'Nie wypełniono pola ""Firma""';
				|tr = '""İş yeri"" alanı doldurulmadı'"),
			Object.Ref, "Object.Organization",
			,
			Cancel);
	EndIf;
	
	If Not ValueIsFilled(Object.Partner) Then
		CommonClient.MessageToUser(
			NStr("vi = 'Chưa điền trường ""Khách hàng""';
				|ru = 'Поле ""Клиент"" не заполнено';
				|en = '""Customer"" is required'; fa = '""Customer"" is required';
				|it = 'Il campo ""Cliente"" non è compilato';
				|pl = 'Nie wypełniono pole ""Клиент""';
				|tr = '""Müşteri"" alanı doldurulmadı'"),
			Object.Ref, "Object.Partner",
			,
			Cancel);
	EndIf;
	
	If Not ValueIsFilled(Object.Counterparty) And Not UsePartnersAsCounterparties Then
		CommonClient.MessageToUser(
			NStr("vi = 'Trường ""Đối tác"" chưa điền';
				|ru = 'Поле ""Контрагент"" не заполнено';
				|en = '""Counterparty"" is not filled in'; fa = '""Counterparty"" is not filled in';
				|it = 'Il campo ""Contraente"" non è compilato';
				|pl = 'Pole ""Kontrahent"" nie jest wypełnione';
				|tr = '""Cari hesap"" alanı doldurulmadı'"),
			Object.Ref, "Object.Counterparty",
			,
			Cancel);
	EndIf;
	
	If Not Cancel Then
		
		PickingParameters = New Structure;
		PickingParameters.Insert("DocumentReturnPolicy", Object.Ref);
		PickingParameters.Insert("Partner", Object.Partner);
		PickingParameters.Insert("Document", Object.Ref);
		PickingParameters.Insert("Currency", Object.Currency);
		PickingParameters.Insert("Date", ?(ValueIsFilled(Object.Date), Object.Date, CommonClient.SessionDate()));
		PickingParameters.Insert("VATTaxation", Object.VATTaxation);
		PickingParameters.Insert("PriceIncludesVAT", Object.PriceIncludesVAT);
		PickingParameters.Insert("Terms", Object.Terms);
		PickingParameters.Insert("Contract", Object.Contract);
		PickingParameters.Insert("Organization", Object.Organization);
		PickingParameters.Insert("Counterparty", Object.Counterparty);
		PickingParameters.Insert("ReturnFromRetailCustomer", ReturnFromRetailCustomer);
		PickingParameters.Insert("CashRegisterReceipt", Object.CashRegisterReceipt);
		PickingParameters.Insert("ShowProducts_", True);
		PickingParameters.Insert("ShowContainers", Not ReturnFromRetailCustomer And Object.ToReturnReusablePackage);
		PickingParameters.Insert("LineOfBusiness", Object.LineOfBusiness);
		PickingParameters.Insert("ReturnFromCustodian", 
			Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.ReturnFromCustodian"));
		
		OpenForm(
			"CommonForm.SelectGoodsBySalesAndTransfers",
			PickingParameters,
			ThisObject);
		
	EndIf;
	
	UpdateInformationOnImplementations();
	
EndProcedure

&AtClient
Procedure SelectTransferredGoods(Command)
	
	Cancel = False;
	
	ClearMessages();
	
	If Not ValueIsFilled(Object.Partner) Then
		ErrorText = NStr("vi = 'Chưa điền trường ""Bạn hàng""';
						|ru = 'Поле ""Партнер"" не заполнено';
						|en = '""Partner"" is required'; fa = '""Partner"" is required';
						|it = 'Il campo ""Partner"" non è compilato';
						|pl = 'Pole ""Partner"" nie jest wypełnione';
						|tr = '""İş Ortağı"" alanı doldurulmamış'");
		
		CommonClientServer.MessageToUser(ErrorText, Object.Ref, "Object.Partner", "", Cancel);
	EndIf;
	
	If Not ValueIsFilled(Object.Organization) Then
		ErrorText = NStr("vi = 'Chưa điền trường ""Doanh nghiệp""';
						|ru = 'Поле ""Организация"" не заполнено';
						|en = '""Company"" is required'; fa = '""Company"" is required';
						|it = 'Il campo ""Società"" non è compilato';
						|pl = 'Nie wypełniono pola ""Firma""';
						|tr = '""İş yeri"" alanı doldurulmadı'");
		
		CommonClientServer.MessageToUser(ErrorText, Object.Ref, "Object.Organization", "", Cancel);
	EndIf;
	
	If Not ValueIsFilled(Object.Contract) Then
		ErrorText = NStr("vi = 'Trường ""Hợp đồng"" chưa điền';
						|ru = 'Поле ""Договор"" не заполнено';
						|en = '""Contract"" is not filled in.'; fa = '""Contract"" is not filled in.';
						|it = 'Il campo ""Accordo"" non è compilato';
						|pl = 'Pole ""Umowa"" nie jest wypełnione';
						|tr = '""Sözleşme"" alanı doldurulmamış'");
		
		CommonClientServer.MessageToUser(ErrorText, Object.Ref, "Object.Contract", "", Cancel);
	EndIf;
	
	If Cancel Then
		Return;
	EndIf;
	
	PerformanceMonitorClient.TimeMeasurement(True,
		"Document.RequestForReturnOfGoodsFromCustomer.DocumentForm.Command.SelectTransferredGoods");
	
	AddressOfGoods = PlaceGoodsInStorageForSelectionOfTransferredGoods();
	
	FormParameters = New Structure;
	FormParameters.Insert("Ref", Object.Ref);
	FormParameters.Insert("Owner", Object.Partner);
	FormParameters.Insert("Organization", Object.Organization);
	FormParameters.Insert("Contract", Object.Contract);
	FormParameters.Insert("BusinessOperation", Object.BusinessOperation);
	FormParameters.Insert("ObjectManager", "Document.ReceiptOfGoodsFromCustodian");
	FormParameters.Insert("AddressOfGoodsInvoiceInVault", AddressOfGoods);
	FormParameters.Insert("CollapseGTDNumbers", True);
	
	OpenForm("DataProcessor.SelectGoodsTransferredToCustody.Form.Form", FormParameters, ThisObject,
		UUID);
		
EndProcedure

&AtClient
Procedure SubstituteGoodsFillInPricesByAgreement()
	
	ClearMessages();
	
	If EnterprisePricesFillingClient.ItIsNecessaryToFillInPricesByAgreement(Object,"SubstituteGoods", NStr("vi = 'Hàng hóa thay thế';
																											|ru = 'Заменяющие товары';
																											|en = 'Exchange goods'; fa = 'کالای تعویضی';
																											|it = 'Merci sostitutive';
																											|pl = 'wiersze pozycji zastępcze';
																											|tr = 'İkame ürünler'")) Then
		
		ErrorText = "";
		PricesCalculated = SubstituteGoodsFillInPricesByAgreementServer(, ErrorText);
		SalesClient.NotifyAboutEndOfFillingInPricesUnderAgreement(PricesCalculated, ErrorText);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure SubstituteProductsFillInPricesOfSelectedRowsByTypeOfPrices(Command)
	
	If EnterprisePricesFillingClient.ItIsNecessaryToFillInPricesByTypeOfPrices(Object, "SubstituteGoods", NStr("vi = 'Hàng hóa thay thế';
																												|ru = 'Заменяющие товары';
																												|en = 'Exchange goods'; fa = 'کالای تعویضی';
																												|it = 'Merci sostitutive';
																												|pl = 'wiersze pozycji zastępcze';
																												|tr = 'İkame ürünler'")) Then
		
		PriceSelectionOptions = EnterprisePricesFillingClient.NewFillOptionsSelectPriceType();
		PriceSelectionOptions.CallbackDescription = 
			New CallbackDescription("SubstituteProductsFillInPricesOfSelectedRowsByTypeOfPricesCompletion", ThisObject);
		PriceSelectionOptions.PriceIncludesVAT = Object.PriceIncludesVAT;
		PriceSelectionOptions.UseWhileSellingToCustomers = True;
		EnterprisePricesFillingClient.ChooseTypeOfPrices(PriceSelectionOptions);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure SubstituteProductsFillInPricesOfSelectedRowsByTypeOfPricesCompletion(PricesKind, AdditionalParameters) Export
	
	ClearMessages();
	
	If ValueIsFilled(PricesKind) Then
		
		PricesCalculated = SubstituteProductsFillInPricesOfSelectedRowsByTypeOfPricesServer(PricesKind);
		SalesClient.NotifyAboutEndOfFillingInPricesByTypeOfPrices(PricesCalculated, PricesKind);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure SubstituteGoodsCancelSelectedLines(Command)
	
	If Not SalesClient.YouMustFillInReasonsForCancelingSelectedLines(Object.SubstituteGoods, NStr("vi = 'Hàng hóa thay thế';
																									|ru = 'Заменяющие товары';
																									|en = 'Exchange goods'; fa = 'کالای تعویضی';
																									|it = 'Merci sostitutive';
																									|pl = 'wiersze pozycji zastępcze';
																									|tr = 'İkame ürünler'"), Items.SubstituteGoods.SelectedRows) Then
		Return;
	EndIf;
	
	CancellationReason = PredefinedValue("Catalog.ReasonsForSaleOrderCancellation.EmptyRef");
	If UseReasonsForSalesOrderCancellations Then
		OpenForm("Catalog.ReasonsForSaleOrderCancellation.ChoiceForm",,,,,, New CallbackDescription("SubstituteGoodsCancelSelectedLinesCompletion", ThisObject), FormWindowOpeningMode.LockOwnerWindow);
        Return;
	EndIf;
	
	ReplacingItemsUndoSelectedLineSnippet(CancellationReason);
EndProcedure

&AtClient
Procedure SubstituteGoodsCancelSelectedLinesCompletion(Result, AdditionalParameters) Export
    
    CancellationReason = Result;
    If Not ValueIsFilled(CancellationReason) Then
        Return;
    EndIf;
    
    ReplacingItemsUndoSelectedLineSnippet(CancellationReason);

EndProcedure

&AtClient
Procedure ReplacingItemsUndoSelectedLineSnippet(Val CancellationReason)

	Var SelectedRows, StructureOfActions;

	StructureOfActions = New Structure();
	StructureOfActions.Insert("FillInDuplicateDependentDetails", DependentDetailsReplacingGoods());
	StructureOfActions.Insert("FillInCanceledWithoutReturnableContainerAttribute", Object.ToReturnReusablePackage);

	SelectedRows = AddToFullSet("SubstituteGoods");

	SalesClient.CancelSelectedLines(
		Object.SubstituteGoods,
		SelectedRows,
		CancellationReason,
		StructureOfActions);

	SalesClient.NotifyAboutCancellationOfSelectedLines(CancellationReason);

	SubstituteGoodsCancelSelectedLinesServer(SelectedRows);

EndProcedure

&AtClient
Procedure ReturnedGoodsCancelSelectedLines(Command)
	
	If Object.ReturnedGoods.Count() = 0 Then
		ShowMessageBox(Undefined, NStr("vi = 'Chưa điền bảng hàng hóa trả lại';
										|ru = 'Таблица возвращаемых товаров не заполнена.';
										|en = 'Goods pending return table is not filled in.'; fa = 'Goods pending return table is not filled in.';
										|it = 'La tabella delle merci in corso di resa non è compilata.';
										|pl = 'Nie wypełniono tabeli zwracanych towarów.';
										|tr = 'İade edilen mallar tablosu eksik.'"));
		Return;
	ElsIf Items.ReturnedGoods.SelectedRows.Count() = 0 Then
		ShowMessageBox(Undefined, NStr("vi = 'Trong bảng hàng hóa không có dòng đã chọn';
										|ru = 'В таблице товаров отсутствуют выделенные строки.';
										|en = 'No selected rows in the goods table.'; fa = 'No selected rows in the goods table.';
										|it = 'Nella tabella delle merci non ci sono righe selezionate.';
										|pl = 'Brak wybranych wierszy w tabeli towarów.';
										|tr = 'Mallar tablosunda seçili satır yoktur.'"));
		Return;
	EndIf;
	
	ThereAreCanceledLines = ReturnedItemsUndoSelectedLinesFragment();
	
	If ThereAreCanceledLines Then
		ShowUserNotification(
			NStr("vi = 'Các dòng đã chọn bị hủy bỏ';
				|ru = 'Выделенные строки отменены';
				|en = 'Selected lines are canceled'; fa = 'Selected lines are canceled';
				|it = 'Righe selezionate annullate';
				|pl = 'Zaznaczone wiersze anulowano';
				|tr = 'Seçili satırlar iptal edildi'"),
			,
			NStr("vi = 'Dòng đã chọn trong giấy đề nghị bị hủy bỏ.';
				|ru = 'Выделенные строки заявки отменены.';
				|en = 'The selected request lines are canceled.'; fa = 'The selected request lines are canceled.';
				|it = 'Righe selezionate della domanda sono annullate.';
				|pl = 'Anulowano wybrane wiersze wniosku.';
				|tr = 'Seçili talep satırları iptal edildi.'"),
			PictureLib.Information32);
	Else
		ShowMessageBox(Undefined, NStr("vi = 'Các dòng đã chọn bị hủy bỏ';
										|ru = 'Выделенные строки уже отменены.';
										|en = 'Selected lines are already canceled.'; fa = 'Selected lines are already canceled.';
										|it = 'Righe selezionate sono già state annullate.';
										|pl = 'Wybrane wiersze już są anulowane.';
										|tr = 'Seçili satırlar zaten iptal edildi.'"));
	EndIf;
	
EndProcedure

&AtServer
Function ReturnedItemsUndoSelectedLinesFragment()
	
	RowsToProcess = New Array;
	
	StructureOfActions = New Structure();
	StructureOfActions.Insert("FillInDuplicateDependentDetails", DependentDetailsReturnedGoods());
	StructureOfActions.Insert("FillInCanceledWithoutReturnableContainerAttribute", Object.ToReturnReusablePackage);
	StructureOfActions.Insert("FillInCheckQualityDateOfQualityConfirmation", CacheQualityControl);
	
	ThereAreCanceledLines = False;
	
	SelectedRows = AddToFullSet("ReturnedGoods");
	
	For Each CurRow In SelectedRows Do
		
		TableRow = Object.ReturnedGoods.FindByID(CurRow);
		
		If TableRow <> Undefined Then
			
			If Not TableRow.Canceled Then
				TableRow.Canceled = True;
				ThereAreCanceledLines = True;
			EndIf;
			
			RowsToProcess.Add(TableRow);
			
		EndIf;
		
	EndDo;
	
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		RowsToProcess,
		StructureOfActions,
		Object.ReturnedGoods,
		Undefined);
	
	CalculateTotalsOfRefundRequest(ThisObject);
	
	If SeriesSpecificationParameters.Returned_.UseItemsBatch Then
		FillInStatusesForSpecifyingSeriesServer("Returned_");
	EndIf;
	
	OnChangingWarehouseInTablePartOfReturnedGoodsServer();	
	
	Return ThereAreCanceledLines
	
EndFunction

&AtClient
Procedure ReturnedGoodsCancelUnreturnedLines(Command)
	
	If Object.ReturnedGoods.Count() = 0 Then
		ShowMessageBox(Undefined, NStr("vi = 'Chưa điền bảng hàng hóa trả lại';
										|ru = 'Таблица возвращаемых товаров не заполнена.';
										|en = 'Goods pending return table is not filled in.'; fa = 'Goods pending return table is not filled in.';
										|it = 'La tabella delle merci in corso di resa non è compilata.';
										|pl = 'Nie wypełniono tabeli zwracanych towarów.';
										|tr = 'İade edilen mallar tablosu eksik.'"));
		Return;
	EndIf;
	
	ThereAreNonCanceledLines = False;
	For Each CurRow In Object.ReturnedGoods Do
		If Not CurRow.Canceled Then
			ThereAreNonCanceledLines = True;
		EndIf;
	EndDo;
	
	If Not ThereAreNonCanceledLines Then
		ShowMessageBox(Undefined, NStr("vi = 'Đã hủy tất cả các dòng.';
										|ru = 'Все строки уже отменены.';
										|en = 'All lines are already canceled.'; fa = 'All lines are already canceled.';
										|it = 'Tutte le righe sono già annullate.';
										|pl = 'Wszystkie wiersze są już anulowane.';
										|tr = 'Tüm satırlar zaten iptal edildi.'"));
		Return;
	EndIf;
	
	CheckBalance = True;
	
	If Not Object.Posted Then
		CheckBalance = False;
	ElsIf Object.Status = PredefinedValue("Enum.StatusesOfRequestsForReturnOfGoodsFromCustomers.NotAgreedUpon")
		Or Object.Status = PredefinedValue("Enum.StatusesOfRequestsForReturnOfGoodsFromCustomers.IsRejected") Then
		CheckBalance = True;
	EndIf;
	
	RowsCountCanceled = CancelNonReturnedServerRows(CheckBalance);
	
	If RowsCountCanceled = 0 Then
		
		ShowUserNotification(
			NStr("vi = 'Chưa hủy bỏ dòng';
				|ru = 'Строки не отменены';
				|en = 'Lines were not canceled'; fa = 'Lines were not canceled';
				|it = 'Righe non annullate';
				|pl = 'Wiersze nie są anulowane';
				|tr = 'Satırlar iptal edilmedi'"),
			,
			NStr("vi = 'Theo tất cả các dòng của đơn hàng đã lập chứng từ trả lại. Không thể hủy các dòng.';
				|ru = 'По всем строкам заказа оформлен возврат. Строки не могут быть отменены.';
				|en = 'Return is registered by all order lines. Lines cannot be canceled.'; fa = 'Return is registered by all order lines. Lines cannot be canceled.';
				|it = 'Per tutte le righe dell''ordine è stato formalizzato il reso. Le righe non possono essere annullate.';
				|pl = 'Według wszystkich wierszy zamówienia jest sporządzony zwrot. Nie można anulować wierszy.';
				|tr = 'Tüm sipariş satırları için bir iade düzenlenmiştir. Satırlar iptal edilemez.'"),
			PictureLib.Information32);
			
	Else
		
		CalculateTotalsOfRefundRequest(ThisForm);
		
		If CheckBalance Then

			ShowUserNotification(
				NStr("vi = 'Hủy bỏ dòng';
					|ru = 'Строки отменены';
					|en = 'Lines were canceled'; fa = 'Lines were canceled';
					|it = 'Righe annullate';
					|pl = 'Wiersze są anulowane';
					|tr = 'Satırlar iptal edildi'"),
				,
				NStr("vi = 'Đã hủy tất cả các dòng chưa trả lại trong giấy đề nghị.';
					|ru = 'Все невозвращенные строки заявки отменены.';
					|en = 'All request lines that are not returned are canceled.'; fa = 'All request lines that are not returned are canceled.';
					|it = 'Tutte le righe dell''ordine mancate al reso sono annullate.';
					|pl = 'Wszystkie niezwrócone wiersze wniosku są anulowane.';
					|tr = 'İade edilmeyen tüm talep satırları iptal edildi.'"),
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
				NStr("vi = 'Đã hủy tất cả các dòng trả lại của giấy đề nghị.';
					|ru = 'Все возвращаемые строки заявки отменены.';
					|en = 'All the returned request lines are canceled.'; fa = 'All the returned request lines are canceled.';
					|it = 'Tutte le righe dell''ordine in corso di resa sono annullate.';
					|pl = 'Wszystkie zwracane wiersze zamówienia są anulowane.';
					|tr = 'İade edilen tüm talep satırları iptal edildi.'"),
				PictureLib.Information32);
			
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure WriteDocument(Command)
	
	TMCommonUseClient.Write(ThisForm, True);
	
EndProcedure

&AtClient
Procedure FillInSubstituteGoodsByReturnedOnes(Command)
	
	If Object.ReturnedGoods.Count() = 0 Then
		ShowMessageBox(Undefined, NStr("vi = 'Chưa điền bảng hàng hóa trả lại. Không thể điền';
										|ru = 'Таблица возвращаемых товаров не заполнена. Заполнение невозможно.';
										|en = 'Goods pending return table is not filled in.'; fa = 'Goods pending return table is not filled in.';
										|it = 'La tabella delle merci in corso di resa non è compilata. La compilazione è impossibile.';
										|pl = 'Tabela zwracanych towarów nie jest wypełniona. Wypełnienie jest niemożliwe.';
										|tr = 'İade edilen mallar tablosu eksik. Doldurulması mümkün değildir.'"));
		Return;
	EndIf;
	
	ButtonsList = New ValueList;
	ButtonsList.Add("ByAgreement", NStr("vi = 'Theo điều kiện bán hàng';
										|ru = 'По условиям продаж';
										|en = 'By sales terms and conditions'; fa = 'بر اساس شرایط و ضوابط فروش';
										|it = 'Secondo le condizioni delle vendite';
										|pl = 'Wg warunków sprzedaży';
										|tr = 'Satış şartlarına göre'"));
	ButtonsList.Add("ByGoods", NStr("vi = 'Đối với hàng trả lại';
									|ru = 'По возвращаемым товарам';
									|en = 'By goods pending return'; fa = 'By goods pending return';
									|it = 'Per le merci in corso di resa';
									|pl = 'Według zwracanych towarów';
									|tr = 'İade edilen mallara göre'"));
	ButtonsList.Add("Cancel", NStr("vi = 'Hủy bỏ';
									|ru = 'Отмена';
									|en = 'Cancel'; fa = 'انصراف';
									|it = 'Annulla';
									|pl = 'Cancel';
									|tr = 'İptal'"));
	QueryText = NStr("vi = 'Phần bảng các hàng hóa thay thế sẽ được điền lại. 
		|Điền đơn giá theo điều kiện bán hàng hoặc theo hàng hóa trả lại?';
		|ru = 'Табличная часть заменяющих товаров будет перезаполнена. 
		|Заполнить цены по условиям продаж или по возвращаемым товарам?';
		|en = 'Table of the substitute goods will be refilled.
		|Fill in the prices by sales terms and conditions or goods pending return?'; fa = 'Table of the substitute goods will be refilled.
		|Fill in the prices by sales terms and conditions or goods pending return?';
		|it = 'La parte tabulare delle merci sostitutive verrà ricompilata. 
		|Compilare i prezzi in conformità alle condizioni di vendita o per le merci in corso di resa?';
		|pl = 'Część tabelaryczna towarów zastępczych będzie ponownie wypełniona. 
		|Wypełnić ceny według warunków sprzedaży lub według zwracanych towarów?';
		|tr = 'İkame malların tablo kısmının üzerine yazılacaktır.
		| Fiyatlar satış durumuna göre mi yoksa iade edilen mallara göre mi doldurulsun?'");
	ShowQueryBox(New CallbackDescription("FillInSubstituteGoodsByReturnedOnesCompletion", ThisObject),
		QueryText, ButtonsList);
		
EndProcedure

&AtClient
Procedure FillInSubstituteGoodsByReturnedOnesCompletion(QuestionResult, AdditionalParameters) Export
	
	If QuestionResult<>"Cancel" Then
		Object.FillInPricesOfSubstituteGoodsByReturned = QuestionResult="ByGoods";
		FillInSubstituteGoodsByReturnedOnesServer();
	EndIf;
	
EndProcedure

&AtClient
Procedure SubstituteGoodsCancelUndeliveredLines(Command)
	
	If Not SalesClient.YouMustFillInReasonForCancelingUndeliveredLines(Object.SubstituteGoods, NStr("vi = 'Hàng hóa thay thế';
																									|ru = 'Заменяющие товары';
																									|en = 'Exchange goods'; fa = 'کالای تعویضی';
																									|it = 'Merci sostitutive';
																									|pl = 'wiersze pozycji zastępcze';
																									|tr = 'İkame ürünler'")) Then
		Return;
	EndIf;
	
	CheckBalance = True;
	
	If Not Object.Posted Then
		
		CheckBalance = False;
		
	ElsIf Object.Status = PredefinedValue("Enum.StatusesOfRequestsForReturnOfGoodsFromCustomers.NotAgreedUpon")
		Or Object.Status = PredefinedValue("Enum.StatusesOfRequestsForReturnOfGoodsFromCustomers.ForReturn")
		Or Object.Status = PredefinedValue("Enum.StatusesOfRequestsForReturnOfGoodsFromCustomers.IsRejected")
		Or Object.Status = PredefinedValue("Enum.StatusesOfRequestsForReturnOfGoodsFromCustomers.ToSupply") Then
		
		CheckBalance = True;
		
	EndIf;
	
	CancellationReason = PredefinedValue("Catalog.ReasonsForSaleOrderCancellation.EmptyRef");
	If UseReasonsForSalesOrderCancellations Then
		OpenForm("Catalog.ReasonsForSaleOrderCancellation.ChoiceForm",,,,,, New CallbackDescription("SubstituteGoodsCancelUndeliveredLinesCompletion", ThisObject, New Structure("CheckBalance", CheckBalance)), FormWindowOpeningMode.LockOwnerWindow);
        Return;
	EndIf;
	
	ReplacingGoodsUndoUndeliveredStringFragment(CancellationReason, CheckBalance);
EndProcedure

&AtClient
Procedure SubstituteGoodsCancelUndeliveredLinesCompletion(Result, AdditionalParameters) Export
    
    CheckBalance = AdditionalParameters.CheckBalance;
    
    
    CancellationReason = Result;
    If Not ValueIsFilled(CancellationReason) Then
        Return;
    EndIf;
    
    ReplacingGoodsUndoUndeliveredStringFragment(CancellationReason, CheckBalance);

EndProcedure

&AtClient
Procedure ReplacingGoodsUndoUndeliveredStringFragment(Val CancellationReason, Val CheckBalance)
    
    Var RowsCountCanceled;
    
    RowsCountCanceled = SubstituteGoodsCancelUndeliveredLinesServer(CancellationReason, CheckBalance);
    
    If RowsCountCanceled = 0 Then
        
        SalesClient.NotifyAboutCancellationOfUndeliveredLines(CancellationReason, RowsCountCanceled, CheckBalance);
        
    Else
        
        CalculateTotalsOfRefundRequest(ThisForm);
        SalesClient.NotifyAboutCancellationOfUndeliveredLines(CancellationReason, RowsCountCanceled, CheckBalance);
        
    EndIf;
    ProvisionInDocumentsClientServer.FillInServiceDetails(Object.SubstituteGoods,
          DateOfShipmentRequired_, WarehouseIsRequired);

EndProcedure

&AtClient
Procedure SubstituteGoodsHideUndeliveredLines(Command)
	
	HideCanceledLines = Not HideCanceledLines;
	
	If HideCanceledLines Then
		Items.SubstituteGoods.RowFilter = New FixedStructure("Canceled", False);
	Else
		Items.SubstituteGoods.RowFilter = Undefined;
	EndIf;
	
	Items.SubstituteGoodsHideUndeliveredLines.Check = HideCanceledLines;
	
EndProcedure

&AtClient
Procedure ReturnedGoodsHideCanceledLines(Command)
	
	HideCanceledLinesReturnedItems = Not HideCanceledLinesReturnedItems;
	
	If HideCanceledLinesReturnedItems Then
		Items.ReturnedGoods.RowFilter = New FixedStructure("Canceled", False);
	Else
		Items.ReturnedGoods.RowFilter = Undefined;
	EndIf;
	
	Items.ReturnedGoodsHideCanceledLines.Check = HideCanceledLinesReturnedItems;
	
EndProcedure

&AtClient
Procedure CalculateDiscountsMarkups(Command)
	
	CalculateDiscountsMarkupsClient();
	
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
	
	CurrentData = Items.SubstituteGoods.CurrentData;
	DiscountsMarkupsFillingClient.OpenAppliedDiscountsForm(CurrentData, Object, ThisForm);
	
EndProcedure

&AtClient
Procedure AssignAManualDiscount(Command)
	
	If Not DiscountsMarkupsFillingClient.ItIsPossibleToAssignManualDiscountMarkUp(Object, "SubstituteGoods", NStr("vi = 'Hàng hóa thay thế';
																													|ru = 'Заменяющие товары';
																													|en = 'Exchange goods'; fa = 'کالای تعویضی';
																													|it = 'Merci sostitutive';
																													|pl = 'wiersze pozycji zastępcze';
																													|tr = 'İkame ürünler'")) Then
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
		
		CalculateTotalsOfRefundRequest(ThisForm);
		
	EndIf;

EndProcedure

&AtClient
Procedure AssignAManualDiscountForSelectedLines(Command)
	
	If Not DiscountsMarkupsFillingClient.ItIsPossibleToAssignManualDiscountMarkUp(Object, "SubstituteGoods", NStr("vi = 'Hàng hóa thay thế';
																													|ru = 'Заменяющие товары';
																													|en = 'Exchange goods'; fa = 'کالای تعویضی';
																													|it = 'Merci sostitutive';
																													|pl = 'wiersze pozycji zastępcze';
																													|tr = 'İkame ürünler'")) Then
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
		
		AssignManualDiscountOnServer(AmountOfManualDiscountMarkUp, Items.SubstituteGoods.SelectedRows, AddressInTempStorage);
		DiscountsMarkupsFillingClient.NotifyAboutEndOfAssignmentOfManualDiscountsMargins(AmountOfManualDiscountMarkUp, Object.Currency);
		
		CalculateTotalsOfRefundRequest(ThisForm);
		
	EndIf;

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
		
		If Not Object.FillInPricesOfSubstituteGoodsByReturned Then
			ShowUserNotification(
				NStr("vi = 'Chiết khấu (phụ thu)';
					|ru = 'Скидки (наценки)';
					|en = 'Discounts (markups)'; fa = 'تخفیف‌ها (افزایش قیمت‌ها)';
					|it = 'Sconti (sovrapprezzo)';
					|pl = 'Rabaty (marże)';
					|tr = 'İndirimler (zamlar)'"),
				,
				NStr("vi = 'Đã tính chiết khấu (phụ thu)';
					|ru = 'Скидки (наценки) рассчитаны';
					|en = 'Discounts (markups) are calculated'; fa = 'Discounts (markups) are calculated';
					|it = 'Sconti (sovrapprezzi) sono calcolati';
					|pl = 'Rabaty (marże) są obliczone';
					|tr = 'İndirim (marj) uygulandı'"),
				PictureLib.Information32);
		EndIf;
	EndIf;

EndProcedure

&AtClient
Procedure CancelManualDiscounts(Command)
	
	If Not DiscountsMarkupsFillingClient.ItIsPossibleToCancelManualDiscountsMarkups(Object, "SubstituteGoods", NStr("vi = 'Hàng hóa thay thế';
																													|ru = 'Заменяющие товары';
																													|en = 'Exchange goods'; fa = 'کالای تعویضی';
																													|it = 'Merci sostitutive';
																													|pl = 'wiersze pozycji zastępcze';
																													|tr = 'İkame ürünler'")) Then
		Return;
	EndIf;
	
	CancelManualDiscountsOnServer();
	DiscountsMarkupsFillingClient.NotifyAboutEndOfAssignmentOfManualDiscountsMargins();
	
	CalculateTotalsOfRefundRequest(ThisForm);
	
EndProcedure

&AtClient
Procedure Attachable_PropertiesExecuteCommand(ItemOrCommand, Var_URL = Undefined, StandardProcessing = Undefined)
	PropertyManagerClient.ExecuteCommand(ThisObject, ItemOrCommand, StandardProcessing);
EndProcedure

&AtClient
Procedure ReplacementProductsBarcodeSearchExecute(Command)
	
	ClearMessages();
	Notification = New CallbackDescription("ReplacementProductsBarcodeSearchCompletion", ThisObject);
	BarcodingOfItemsClient.ShowBarcodeInput(Notification);
	
EndProcedure

&AtClient
Procedure ReplacementProductsBarcodeSearchCompletion(BarcodeData_2, AdditionalParameters) Export
	
	ProcessBarcodes(BarcodeData_2, "SubstituteGoods");
	
EndProcedure

&AtClient
Procedure ReplacementProductsOpenSelection(Command)
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.StartTimeMeasurement(True,
		"Document.RequestForReturnOfGoodsFromCustomer.DocumentForm.Command.ReplacementProductsOpenSelection");
	
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
		HeaderParameter_ = StrReplace(HeaderParameter_, "%Document%", NStr("vi = 'giấy đề nghị trả hàng từ người mua';
																			|ru = 'заявку на возврат товаров от клиента';
																			|en = 'sales return request'; fa = 'sales return request';
																			|it = 'domanda di reso delle merci dal cliente';
																			|pl = 'zlecenie na zwrot towarów od klienta';
																			|tr = 'müşteriden satış iadesi talebi'"));
	EndIf;
	
	FormParameters = New Structure;
	FormParameters.Insert("Partner",              Object.Partner);
	FormParameters.Insert("Terms",           Object.Terms);
	FormParameters.Insert("Organization",          Object.Organization);
	If Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.ReturnFromCommissionAgent")
		Or Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.ReturnFromCustodian") Then
		FormParameters.Insert("FilterByProductType", New FixedArray(ProductsClientServer.SelectionByProductMultiTurnContainer()));
		FormParameters.Insert("HideManualDiscounts", True);	
	EndIf;
	FormParameters.Insert("PriceIncludesVAT",      Object.PriceIncludesVAT);
	FormParameters.Insert("VATTaxation",   Object.VATTaxation);
	FormParameters.Insert("HideExcisableGoods",               Object.VATTaxation = PredefinedValue("Enum.VATTaxationTypes.SaleIsSubjectToUTII"));
	FormParameters.Insert("DisplayTheHideExcisableGoodsFlag", Object.VATTaxation = PredefinedValue("Enum.VATTaxationTypes.SaleIsSubjectToUTII"));
	FormParameters.Insert("UseShipmentDates", True);
	FormParameters.Insert("Warehouse",                Object.Warehouse);
	FormParameters.Insert("Currency",               Object.Currency);
	FormParameters.Insert("Title",            HeaderParameter_);
	FormParameters.Insert("Date",                 Object.Date);
	FormParameters.Insert("SelectionModeUseWarehousesInTabularSection", True);
	FormParameters.Insert("Document",             Object.Ref);
	FormParameters.Insert("SeriesSpecificationParameters", SeriesSpecificationParameters.Substitutes_);
	FormParameters.Insert("Purpose",             Object.Purpose);
	FormParameters.Insert("Department",          Object.Department);
	FormParameters.Insert("SelectSupplyOptions", UseShipmentByRowsInSalesOrder);
	FormParameters.Insert("ReturnReusablePackage", Object.ToReturnReusablePackage);
	FormParameters.Insert("SecurityOptionAndFlagSeparately", SecurityOptionAndFlagSeparately);
	FormParameters.Insert("LimitSupplyOptions",    Not UseShipmentByRowsInSalesOrder);
	FormParameters.Insert("AvailableRemainingDocumentParameters",
		ProvisionInDocumentsClient.AvailableRemainingDocumentParameters(ThisObject));
	
	FormParameters.Insert("SecurityOptionAndFlagSeparately", SecurityOptionAndFlagSeparately);
	
	ReplacementGoodsAddFormParametersSelectionLocalization(FormParameters);
	
	OpenForm("DataProcessor.SelectGoodsToSalesDocument.Form", FormParameters, ThisObject, UUID);
		
EndProcedure

&AtClient
Procedure SplitRow(Command)
	
	FormTable  = Items.SubstituteGoods;
	TableData = Object.SubstituteGoods;
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.StructureOfRecalculationOfAmount(
		"Count, Sum, VATAmount, AmountIncludingVAT, ManualDiscount, DiscountMarkupAmount, "
		+ DependentDetailsThatReplaceProductsWithLine(), "NumberOfPackages");
	If Not FormTable.CurrentData = Undefined Then
		BatchProcessingOfTablePartClientServer.FillInStructureForRecalculatingAmount(StructureOfRecalculationOfAmount, FormTable.CurrentData);
	EndIf;
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("StructureOfRecalculationOfAmount", StructureOfRecalculationOfAmount);
	
	ProcessingOfTabularFormsClient.SplitRow(TableData, FormTable,
		New CallbackDescription("SplitRowCompletion", ThisObject, AdditionalParameters));
	
EndProcedure

&AtClient
Procedure SplitRowCompletion(NewRow, AdditionalParameters) Export 
	
	CurrentRow = Items.SubstituteGoods.CurrentData;
	
	If NewRow <> Undefined Then
		
		NewRow.RowCode = 0;
		
		BatchProcessingOfTablePartClientServer.AddLineToRecalculateAmount(AdditionalParameters.StructureOfRecalculationOfAmount, CurrentRow);
		BatchProcessingOfTablePartClientServer.AddLineToRecalculateAmount(AdditionalParameters.StructureOfRecalculationOfAmount, NewRow);
		BatchProcessingOfTablePartClientServer.RecalculateAmounts(AdditionalParameters.StructureOfRecalculationOfAmount);
		
		StructureOfActions = New Structure();
		AddCollateralActionsOnClient(StructureOfActions, "UpdateProductCache_");
		BatchProcessingOfTablePartClient.ProcessTSString(NewRow, StructureOfActions, CachedValues);
		
		OnChangingWarehouseInTablePartReplacingGoodsServer();
		CalculateTotalsOfRefundRequest(ThisForm);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure SplitTheStringReturned(Command)
	
	FormTable  = Items.ReturnedGoods;
	TableData = Object.ReturnedGoods;
	
	Notification = New CallbackDescription("SplitTheStringReturnedCompletion", ThisObject);
	ProcessingOfTabularFormsClient.SplitRow(TableData, FormTable, Notification);
	
EndProcedure

&AtClient
Procedure SplitTheStringReturnedCompletion(NewRow, AdditionalParameters) Export 
	
	CurrentRow = Items.ReturnedGoods.CurrentData;
	
	If NewRow <> Undefined Then
		
		NewRow.RowCode = 0;
		
		StructureOfActions = New Structure;
		AddToActionStructureWhenChangingNumberOfPackagesReturnItems(StructureOfActions, Object);
		
		BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
		BatchProcessingOfTablePartClient.ProcessTSString(NewRow, StructureOfActions, CachedValues);
		
		OnChangingWarehouseInTablePartOfReturnedGoodsServer();
		CalculateTotalsOfRefundRequest(ThisForm);
		DiscountsMarkupsFillingClient.ResetDiscountsCalculatedFlag(ThisForm);
		
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
		If Items.GroupPages.CurrentPage = Items.SubstituteGoods Then
			ProcessBarcodes(Result.TableOfGoods, "SubstituteGoods");
		Else
			ProcessBarcodes(Result.TableOfGoods, "ReturnedGoods");
		EndIf;
	Else
		EquipmentManagerTMClient.ReportError(Result);
	EndIf;
	
EndProcedure

&AtClient
Procedure SpecifyReturnedSeries(Command)
	
	OpenSelectionOfSeries("Returned_");
	
EndProcedure

&AtClient
Procedure ShowMessages(Command)
	
	DiscountsMarkupsFillingClient.OpenMessageForm(TheStructureOfTheMessages(), ThisForm);
	
EndProcedure

&AtClient
Procedure ToReadLoyaltyCard(Command)
	
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
	ParametersStructure.Insert("ShipperBankAccount", Object.ShipperBankAccount);
	ParametersStructure.Insert("GoodsRecipientBankAccount",  Object.GoodsRecipientBankAccount);
	ParametersStructure.Insert("CounterpartyBankAccount",      Object.CounterpartyBankAccount);
	ParametersStructure.Insert("BankAccount",                 Object.BankAccount);
	ParametersStructure.Insert("Shipper",               Object.Shipper);
	ParametersStructure.Insert("GoodsRecipient",                Object.GoodsRecipient);
	ParametersStructure.Insert("Partner",                        Object.Partner);
	ParametersStructure.Insert("BusinessOperation",          Object.BusinessOperation);
	ParametersStructure.Insert("Counterparty",                     Object.Counterparty);
	ParametersStructure.Insert("Organization",                    Object.Organization);
	ParametersStructure.Insert("Date",                           Object.Date);
	ParametersStructure.Insert("Director",                   Object.Director);
	ParametersStructure.Insert("ChiefAccountant",               Object.ChiefAccountant);
	ParametersStructure.Insert("Ref",                         Object.Ref);
	ParametersStructure.Insert("DeliveryOrderData",   DeliveryOrderData);
	
	OpenForm("Document.SalesOrder.Form.PrintDetails", ParametersStructure, ThisForm,,,, Undefined, FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure AttributesForReturnApplicationPrinting(Command)
	
	Try
		LockFormDataForEdit();
	Except
		ShowMessageBox(Undefined, BriefErrorDescription(ErrorInfo()));
		Return;
	EndTry;
	
	ParametersStructure = New Structure();
	ParametersStructure.Insert("ReadOnly",                      ReadOnly);
	ParametersStructure.Insert("Counterparty",                          Object.Counterparty);
	ParametersStructure.Insert("Customer",                          Object.Customer);
	ParametersStructure.Insert("CustomerSDateOfBirth",              Object.CustomerSDateOfBirth);
	ParametersStructure.Insert("ReasonForReturn",                     Object.ReasonForReturn);
	ParametersStructure.Insert("CustomerDocumentKind",              Object.CustomerDocumentKind);
	ParametersStructure.Insert("CustomerDocumentSeries",            Object.CustomerDocumentSeries);
	ParametersStructure.Insert("CustomerDocumentNumber",            Object.CustomerDocumentNumber);
	ParametersStructure.Insert("DateOfCustomerDocumentIssue",       Object.DateOfCustomerDocumentIssue);
	ParametersStructure.Insert("CustomerDocumentValidityPeriod",     Object.CustomerDocumentValidityPeriod);
	ParametersStructure.Insert("IssuingAuthorityOfCustomerDocument",          Object.IssuingAuthorityOfCustomerDocument);
	ParametersStructure.Insert("CustomerDocumentBusinessUnitCode", Object.CustomerDocumentBusinessUnitCode);
	ParametersStructure.Insert("Organization",                         Object.Organization);
	ParametersStructure.Insert("DocumentDate",                       Object.Date);
	
	OpenForm("DataProcessor.PrintApplicationForReturnOfGoodsFromCustomer.Form.AttributesForReturnApplicationPrinting", ParametersStructure, ThisForm,,,, Undefined, FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure FillInSalesAndPrices(Command)
	
	If Object["ReturnedGoods"].Count() = 0 Then
		
		WarningText = NStr("vi = 'Chứng từ không điền vào danh sách Hàng trả lại. Chứng từ bán hàng và giá cả không thể được điền vào.';
							|ru = 'В документе не заполнен список Возвращаемые товары.  Документы продажи и цены не могут быть заполнены.';
							|en = 'The ""Goods pending return"" list in the document is not filled in. Cannot fill in sales documents and prices.'; fa = 'The ""Goods pending return"" list in the document is not filled in. Cannot fill in sales documents and prices.';
							|it = 'Nel documento non è compilato l''elenco Merci in corso di resa. I documenti di vendita e i prezzi non possono essere compilati.';
							|pl = 'W dokumencie nie wypełniono listy Zwracane wiersze pozycji. Dokumenty sprzedaży i ceny nie mogą być wypełnione.';
							|tr = 'Belgedeki iade edilen ürünler listesi eksiktir. Satış belgeleri ve fiyatlar tamamlanamamıştır.'");
		ShowMessageBox(, WarningText);
		Return;
		
	EndIf;
	
	FillInSalesAndPricesServer();
	
EndProcedure

&AtClient
Procedure InsertSubstituteLines(Command)
	
	NumberOfProductsBeforeInsertion = Object.SubstituteGoods.Count();
	
	GetReplacementLinesFromClipboard();
	ProvisionInDocumentsClientServer.FillInServiceDetails(Object.SubstituteGoods,
		DateOfShipmentRequired_, WarehouseIsRequired);
	DiscountsMarkupsFillingClient.ResetDiscountsCalculatedFlag(ThisForm);
	
	NumberOfInserted = Object.SubstituteGoods.Count()-NumberOfProductsBeforeInsertion;
	ProcessingOfTabularFormsClient.NotifyUserAboutInsertingRows(NumberOfInserted);
EndProcedure

&AtClient
Procedure ToInsertTheReturnedString(Command)
	
	NumberOfProductsBeforeInsertion = Object.ReturnedGoods.Count();
	
	GetReturnedLinesFromClipboard();
	
	NumberOfInserted = Object.ReturnedGoods.Count()-NumberOfProductsBeforeInsertion;
	ProcessingOfTabularFormsClient.NotifyUserAboutInsertingRows(NumberOfInserted);
	
EndProcedure

&AtClient
Procedure CopySubstituteLines(Command)
	
	If ProcessingOfTabularFormsClient.SelectedLineToExecuteCommand(Items.SubstituteGoods) Then
		CopyLinesOnServer("SubstituteGoods");
		ProcessingOfTabularFormsClient.NotifyUserAboutCopyingStrings(Items.SubstituteGoods.SelectedRows.Count());
	EndIf;
	
EndProcedure

&AtClient
Procedure CopyTheReturnedRows(Command)
	
	If ProcessingOfTabularFormsClient.SelectedLineToExecuteCommand(Items.ReturnedGoods) Then
		CopyLinesOnServer("ReturnedGoods");
		ProcessingOfTabularFormsClient.NotifyUserAboutCopyingStrings(Items.ReturnedGoods.SelectedRows.Count());
	EndIf;
	
EndProcedure

&AtClient
Procedure ReturnedGoodsAddReusablePackage(Command)

	ReusablePackageClient.SelectReusablePackage(
		ThisForm,
		"ReturnedGoods",
		"Products,Characteristic,Count,Warehouse,DateOfReceipt");
	
EndProcedure

&AtClient
Procedure SubstituteGoodsAddReusablePackage(Command)

	ReusablePackageClient.SelectReusablePackage(
		ThisForm,
		"SubstituteGoods",
		"Products,Characteristic,Count,Warehouse,DateOfShipment");
	
EndProcedure

&AtClient
Procedure ImportFromExternalFile(Command)
	
	ImportParameters = ProcessingOfTabularFormsClient.ProductLoadingParameters();
	ImportParameters.Organization = Object.Organization;
	ImportParameters.ImportPrices = True;
	ImportParameters.PriceIncludesVAT    = Object.PriceIncludesVAT;
	ImportParameters.VATTaxation = Object.VATTaxation;
	ImportParameters.FillingDate     = Object.Date;
	ImportParameters.ThisIsReusablePackage  = Object.ToReturnReusablePackage;
	ImportParameters.ComponentsPriceParameters.Date       = Object.Date;
	ImportParameters.ComponentsPriceParameters.Currency     = Object.Currency;
	ImportParameters.ComponentsPriceParameters.Terms = Object.Terms;
	
	If Command.Name = "ImportReturnedGoodsFromExternalFile" Then
		TSName = "ReturnedGoods";
		ImportParameters.FilterParameters.Insert("ItemsType",
			ProductsClientServer.SelectionByProductMultiTurnContainer());
	Else
		TSName = "SubstituteGoods";
		If Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.ReturnFromCommissionAgent")
			Or Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.ReturnFromCustodian") Then
			ImportParameters.FilterParameters.Insert("ItemsType",
				ProductsClientServer.SelectionByProductMultiTurnContainer());
		EndIf;
	EndIf;
	
	Notification = New CallbackDescription("ImportFromExternalFileCompletion", ThisObject, TSName);
	ProcessingOfTabularFormsClient.ShowProductUploadForm(ImportParameters, Notification);
	
EndProcedure

&AtClient
Procedure ImportFromExternalFileCompletion(ImportedDataAddress, AdditionalParameters) Export
	
	ClearMessages();
	
	If ValueIsFilled(ImportedDataAddress) Then
		GetUploadedProductsFromStorage(ImportedDataAddress, AdditionalParameters);
	EndIf;
	
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

&AtClient
Procedure CloseRequest(Command)
	
	If Modified Or Not Object.Posted Then
		ShowQueryBox(New CallbackDescription("CloseRequestCompletion", ThisObject),
			NStr("vi = 'Cần kết chuyển chứng thừ để thực hiện giao dịch. Kết chuyển chứng từ?';
				|ru = 'Необходимо провести документ для выполнения операции. Провести документ?';
				|en = 'To proceed, you need to post the document. Do you want to post the document?'; fa = 'To proceed, you need to post the document. Do you want to post the document?';
				|it = 'È necessario pubblicare il documento per eseguire operazione. pubblicare documento?';
				|pl = 'Należy zaksięgować dokument aby wykonać operację. Zaksięgować dokument?';
				|tr = 'Bir işlemin gerçekleştirilmesi için belgenin düzenlenmesi gerekir. Belge düzenlensin mi?'"), QuestionDialogMode.YesNo);
		Return;
	EndIf;
	
	CloseRequestFragment();

EndProcedure

&AtClient
Procedure CloseRequestFragment(Result = Undefined,AdditionalParameters = Undefined) Export
	
	ListOfOrdersToClose = New ValueList;
	ListOfOrdersToClose.Add(Object.Ref);
	
	ClosureStructure = New Structure;
	ClosureStructure.Insert("Orders",                       ListOfOrdersToClose);
	ClosureStructure.Insert("DocumentInitiator",            Object.Ref);
	ClosureStructure.Insert("CancelUnprocessedLines", True);
	ClosureStructure.Insert("CloseOrders",              True);
	
	ClosureStructure.Insert("TableOfGoodsReceipt",         PutItInTemporaryStorageOnServer("ReturnedGoods", New UUID));
	ClosureStructure.Insert("TableOfGoodsExpense",         PutItInTemporaryStorageOnServer("SubstituteGoods", New UUID));
	
	OpenForm("DataProcessor.OrderClosureWizard.Form.ClosureForm", ClosureStructure,
					ThisForm,,,, Undefined, FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure CloseRequestCompletion(QuestionResult, AdditionalParameters) Export
	
	Response = QuestionResult;
	
	CallbackDescription = New CallbackDescription("CloseRequestFragment", ThisObject);
	WriteParameters = New Structure;
	WriteParameters.Insert("ActionAfterRecording",CallbackDescription);
	WriteParameters.Insert("WriteMode", DocumentWriteMode.Posting);
	
	If Response = DialogReturnCode.No Then
		Return;
	Else
		ClearMessages();
		If Not Write(WriteParameters) Then
			Return;
		EndIf;
	EndIf;
	
	CloseRequestFragment();
	
EndProcedure

&AtClient
Procedure PaymentSettlement(Command)
	ARAPAccountingClient.PaymentSettlement(ThisForm, Items.CreditPaymentForm);
EndProcedure

&AtClient
Procedure CancelPaymentWithBonusPoints(Command)
	
	ApplyPaymentWithBonusPoints(Undefined);
	
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
		CalculateTotalsOfRefundRequest(ThisForm);
		Return;
	EndIf;
	
	ApplyPaymentWithBonusPoints(Result.AddressInTempStorage);
	
EndProcedure

&AtClient
Procedure ReturnedGoodsFillInVATRATE(Command)

	If Object.ReturnedGoods.Count() = 0 Then
		WarningText = NStr("vi = 'Trong danh sách ""Hàng trả lại"" chưa điền dòng nào.';
							|ru = 'В список ""Возвращаемые товары"" не введено ни одной строки.';
							|en = 'No lines are entered in the ""Goods pending return"" list.'; fa = 'No lines are entered in the ""Goods pending return"" list.';
							|it = 'No lines are entered in the ""Goods pending return"" list.';
							|pl = 'No lines are entered in the ""Goods pending return"" list.';
							|tr = '""İade edilen ürünler"" listesine hiçbir satır girilmemiştir.'");
		ShowMessageBox(, WarningText);
		Return;
	EndIf;

	AdditionalParameters = New Structure("TabularSectionName", "ReturnedGoods");
	ClosingNotification1 = New CallbackDescription("FillInVATRateCompletion", ThisObject, AdditionalParameters);
	FormParameters = New Structure();
	FormParameters.Insert("VATTaxationType", Object.VATTaxation);
	OpenForm("Catalog.VATRates.ChoiceForm", FormParameters,,,,, ClosingNotification1);

EndProcedure

&AtClient
Procedure ReplacementGoodsFillInVATRate(Command)

	If Object.SubstituteGoods.Count() = 0 Then
		WarningText = NStr("vi = 'Trong danh sách ""Hàng thay thế"" chưa điền dòng nào.';
							|ru = 'В список ""Заменяющие товары"" не введено ни одной строки.';
							|en = 'No lines are entered in the ""Exchange goods"" list.'; fa = 'No lines are entered in the ""Exchange goods"" list.';
							|it = 'No lines are entered in the ""Exchange goods"" list.';
							|pl = 'No lines are entered in the ""Exchange goods"" list.';
							|tr = '""İkame ürünler"" listesine hiçbir satır girilmemiştir.'");
		ShowMessageBox(, WarningText);
		Return;
	EndIf;

	AdditionalParameters = New Structure("TabularSectionName", "SubstituteGoods");
	ClosingNotification1 = New CallbackDescription("FillInVATRateCompletion", ThisObject, AdditionalParameters);
	FormParameters = New Structure();
	FormParameters.Insert("VATTaxationType", Object.VATTaxation);
	OpenForm("Catalog.VATRates.ChoiceForm", FormParameters,,,,, ClosingNotification1);

EndProcedure

&AtClient
Procedure FillInVATRateCompletion(VATRate, AdditionalParameters) Export

	If VATRate = Undefined Then
		Return;
	EndIf;

	FillInVATRateOnServer(VATRate, CachedValues, AdditionalParameters.TabularSectionName);
	If AdditionalParameters.TabularSectionName = "SubstituteGoods" Then
		DiscountsMarkupsFillingClient.ResetDiscountsCalculatedFlag(ThisObject);
	EndIf;

EndProcedure

&AtServer
Procedure FillInVATRateOnServer(VATRate, CachedValues, TabularSectionName)

	Var SelectedRows;

	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);

	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmount");
	If TabularSectionName = "ReturnedGoods" Then
		StructureOfActions.Insert("FillInDuplicateDependentDetails", DependentDetailsReturnedGoods());
		SelectedRows = ProcessingOfTabularFormsClientServer.CollectionItems(Object.ReturnedGoods, Items.ReturnedGoods.SelectedRows);
	ElsIf TabularSectionName = "SubstituteGoods" Then
		StructureOfActions.Insert("RecalculateAmountTakingIntoAccountManualDiscount", New Structure("Clear", False));
		StructureOfActions.Insert("RecalculateAmountTakingIntoAccountAutomaticDiscount", New Structure("Clear", True));
		StructureOfActions.Insert("RecalculateAmountTakingIntoAccountDiscountWithBonusPoints");
		StructureOfActions.Insert("FillInDuplicateDependentDetails", DependentDetailsReplacingGoods());
		SelectedRows = ProcessingOfTabularFormsClientServer.CollectionItems(Object.SubstituteGoods, Items.SubstituteGoods.SelectedRows);
	EndIf;

	If Not ValueIsFilled(SelectedRows) Then
		Return;
	EndIf;
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
		Object[TabularSectionName],
		CachedValues);

	CalculateTotalsOfRefundRequest(ThisObject);

EndProcedure

&AtClient
Procedure Attachable_UpdateSBPPaymentStatus(Command)

	ClearMessages();
	CashClientLocalization.UpdateStatusOfSBPPaymentByDocument(ThisObject, Object.Ref);

EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetBanOnSelectingWarehouseGroup(WarehouseItem)

	If Not GetFunctionalOption("UseWarehousesInTabularSectionsOfSalesDocuments") Then
		Return;
	EndIf;	

	If ConsignmentSales25
			Or Object.BusinessOperation = Enums.BusinessTransactions.ReturnFromCustodian Then

		If WarehouseItem.ChoiceFoldersAndItems = FoldersAndItems.FoldersAndItems Then
				WarehouseItem.ChoiceFoldersAndItems = FoldersAndItems.Items;
		EndIf;	
		
		If ValueIsFilled(Object.Warehouse)
			And Common.ObjectAttributeValue(Object.Warehouse, "IsFolder") Then
			Object.Warehouse = Catalogs.Warehouses.EmptyRef();
		EndIf;
		
	Else 
		WarehouseItem.ChoiceFoldersAndItems = FoldersAndItems.FoldersAndItems;
		
	EndIf;	
	
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

&AtServer
Procedure SetParametersForSelectingProductsWarehouse()
	
	Items.ReturnedGoodsWarehouse.ChoiceParameters = New FixedArray(New Array); 
	Items.SubstituteGoodsWarehouse.ChoiceParameters = New FixedArray(New Array); 
	WarehousesList = WarehouseSelectionData(Object.Warehouse);
	TMCommonUseClientServer.AddSelectionParameter(Items.ReturnedGoodsWarehouse, "Ref", WarehousesList);
	TMCommonUseClientServer.AddSelectionParameter(Items.SubstituteGoodsWarehouse, "Ref", WarehousesList);

EndProcedure

&AtServer
Procedure SetVisibilityOfItemsAcrossMultipleWarehouses()

	Items.GroupCaptionAndPictureSeveralWarehousesReturnedGoods.Visible = WarehouseGroup_;
	Items.GroupCaptionAndPictureSeveralWarehousesThatReplaceGoods.Visible 	= WarehouseGroup_;
	
EndProcedure

&AtServerNoContext
Function ItIsGroupOfWarehousesAndWarehousesUsedByWHForSale(Warehouse)
	
	Return Catalogs.Warehouses.ThisGroupAndWarehousesAreUsedByWHForSales(Warehouse);
	
EndFunction 

&AtServer
Procedure OnChangingWarehouseInTablePartOfReturnedGoodsServer()
	
	WarehousesServer.WhenChangingWarehouseInTablePart(Object.ReturnedGoods, TableOfWarehousesReturnedGoods, WarehouseGroup_);
	ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters.Returned_);
	
	TotalWarehouses_ = TableOfWarehousesReturnedGoods.Count();
	WarehousesClientServer.UpdateWarehouseGroupImage(InscriptionSeveralWarehousesReturnGoods, Items.PictureMultipleWarehousesReturningGoods, TotalWarehouses_);
	
EndProcedure

&AtServer
Procedure OnChangingWarehouseInTablePartReplacingGoodsServer()
	
	WarehousesServer.WhenChangingWarehouseInTablePart(Object.SubstituteGoods, TableOfWarehousesReplacingGoods, WarehouseGroup_);
	ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters.Substitutes_);
	
	TotalWarehouses_ = TableOfWarehousesReplacingGoods.Count();
	WarehousesClientServer.UpdateWarehouseGroupImage(InscriptionSeveralWarehousesReplacingGoods, Items.PictureSeveralWarehousesReplacingGoods, TotalWarehouses_);
	
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

&AtClient
Procedure Attachable_OnChangeAdditionalAttribute(Item)
	PropertyManagerClient.UpdateAdditionalAttributesDependencies(ThisObject);
EndProcedure

// End StandardSubsystems.Properties

&AtServer
Procedure FillInSubordinatePropertiesForStatistics(ParentPropsName)
	ObjectsFillingByStatistics.FillInSubordinateDetailsOfObject(Object, ParentPropsName);
EndProcedure

&AtServer
Procedure SetConditionalAppearance()

	ConditionalAppearance.Items.Clear();

	WarehousesServer.SetConditionalAppearanceOfVTCHWarehouse(ThisObject, "ReturnedGoodsWarehouse");
	WarehousesServer.SetConditionalAppearanceOfVTCHWarehouse(ThisObject, "SubstituteGoodsWarehouse");

	// returnabletovarysklad - mark of the blank

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ReturnedGoodsWarehouse.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.ReturnedGoods.ItemsType");
	ItemFilter.ComparisonType = DataCompositionComparisonType.InList;
	ValueList = New ValueList;
	ValueList.Add(Enums.ItemsTypes.OwnGoods);
	ValueList.Add(Enums.ItemsTypes.ReusablePackage);
	ItemFilter.RightValue = ValueList;

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.ReturnedGoods.Warehouse");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	Item.Appearance.SetParameterValue("MarkIncomplete", True);
	
	// substitutionetovarysklad - mark of an empty

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.SubstituteGoodsWarehouse.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.SubstituteGoods.ItemsType");
	ItemFilter.ComparisonType = DataCompositionComparisonType.InList;
	ValueList = New ValueList;
	ValueList.Add(Enums.ItemsTypes.OwnGoods);
	ValueList.Add(Enums.ItemsTypes.ReusablePackage);
	ItemFilter.RightValue = ValueList;

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.SubstituteGoods.Warehouse");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	Item.Appearance.SetParameterValue("MarkIncomplete", True);

	// Conditional registration of collateral.
	ProvisionInDocumentsServer.SetConditionalAppearanceApart(
		ConditionalAppearance,
		Items.SubstituteGoodsWithAssignment,
		"Object.SubstituteGoods.SupplyOption",
		"Object.SubstituteGoods.ItemsType");
	
	TMCommonUse.SetUncheckBlank(
		ConditionalAppearance, "DateOfShipment", "Object.DateOfShipment", "DateOfShipmentRequired_");
		
	TMCommonUse.SetUncheckBlank(
								ConditionalAppearance, "Warehouse", "Object.Warehouse", "WarehouseIsRequired");

	TMCommonUse.SetUncheckBlank(
		ConditionalAppearance, "SubstituteGoodsDateOfShipment", "Object.SubstituteGoods.DateOfShipment", "Object.SubstituteGoods.DateOfShipmentRequired_");
		
	ProvisionInDocumentsServer.AvailableLeftoversAddColumnLayoutAvailable(ThisObject);
	
	// Setting the mark.
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField("Warehouse");
	
	Filter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	Filter.LeftValue = New DataCompositionField("Object.Status");
	Filter.ComparisonType = DataCompositionComparisonType.NotEqual;
	Filter.RightValue = Enums.StatusesOfRequestsForReturnOfGoodsFromCustomers.NotAgreedUpon;
	
	Filter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	Filter.LeftValue = New DataCompositionField("Object.Warehouse");
	Filter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	Item.Appearance.SetParameterValue("MarkIncomplete", True);
	
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
	ItemFilter.RightValue = Enums.StatesOfRequestsForReturnOfGoodsFromCustomers.Executed;

	Item.Appearance.SetParameterValue("TextColor", StyleColors.ClosedDocument);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ReturnedGoodsDateOfReceipt.Name);

	FilterGroup1 = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup1.GroupType = DataCompositionFilterItemsGroupType.OrGroup;

	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Status");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotInList;
	ValueList = New ValueList;
	ValueList.Add(Enums.StatusesOfRequestsForReturnOfGoodsFromCustomers.ForReturn);
	ValueList.Add(Enums.StatusesOfRequestsForReturnOfGoodsFromCustomers.ToSupply);
	ValueList.Add(Enums.StatusesOfRequestsForReturnOfGoodsFromCustomers.ToShip);
	ValueList.Add(Enums.StatusesOfRequestsForReturnOfGoodsFromCustomers.Executed);
	ItemFilter.RightValue = ValueList;

	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.ReturnedGoods.DateOfReceipt");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;

	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.ReturnedGoods.Canceled");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	Item.Appearance.SetParameterValue("MarkIncomplete", False);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.State.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("State");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.StatesOfRequestsForReturnOfGoodsFromCustomers.IsRejected;

	Item.Appearance.SetParameterValue("TextColor", StyleColors.ClosedDocument);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.SubstituteGoodsPercentRateOfAutomaticDiscountMarkup.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.SubstituteGoodsPercentRateOfManualDiscount.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.SubstituteGoodsDiscountMarkupAmount.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.SubstituteGoodsManualDiscount.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.SubstituteGoods.Canceled");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;

	Item.Appearance.SetParameterValue("MarkNegatives", True);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.SubstituteGoodsPrice.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.SubstituteGoods.PriceKind");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	Item.Appearance.SetParameterValue("ReadOnly", True);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.SubstituteGoodsSum.Name);

	FilterGroup1 = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup1.GroupType = DataCompositionFilterItemsGroupType.OrGroup;

	FilterGroup2 = FilterGroup1.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup2.GroupType = DataCompositionFilterItemsGroupType.AndGroup;

	ItemFilter = FilterGroup2.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.SubstituteGoods.PriceKind");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;

	ItemFilter = FilterGroup2.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("UseDiscountAdjustmentsInSales");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;

	Item.Appearance.SetParameterValue("ReadOnly", True);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ReturnedGoodsPrice.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.ReturnedGoods.PriceKind");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	Item.Appearance.SetParameterValue("ReadOnly", True);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ReturnedGoodsSum.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.ReturnedGoods.PriceKind");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	Item.Appearance.SetParameterValue("ReadOnly", True);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.SubstituteGoodsPercentRateOfManualDiscount.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.SubstituteGoodsManualDiscount.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.SubstituteGoodsPercentRateOfAutomaticDiscountMarkup.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.SubstituteGoodsDiscountMarkupAmount.Name);

	RefundOperationsWithoutDiscounts = New ValueList();
	RefundOperationsWithoutDiscounts.Add(Enums.BusinessTransactions.ReturnFromCommissionAgent);
	RefundOperationsWithoutDiscounts.Add(Enums.BusinessTransactions.ReturnFromCustodian);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.BusinessOperation");
	ItemFilter.ComparisonType = DataCompositionComparisonType.InList;
	ItemFilter.RightValue = RefundOperationsWithoutDiscounts;

	Item.Appearance.SetParameterValue("Visible", False);

	//
	
	VATAccountingERP.EstablishConditionalAppearanceOfVATAmountsForSalesTaxation(ThisObject,
		"ReturnedGoodsVATRate",
		"ReturnedGoodsVATAmount",
		"ReturnedGoodsAmountIncludingVAT");

	VATAccountingERP.EstablishConditionalAppearanceOfVATAmountsForSalesTaxation(ThisObject,
		"SubstituteGoodsVATRate",
		"SubstituteGoodsVATAmount",
		"SubstituteGoodsAmountIncludingVAT");

	//
	
	EnterprisePricesFillingServer.SetConditionalAppearancePriceIncludesVAT(ThisObject, "ReturnedGoodsAmountIncludingVAT");
	EnterprisePricesFillingServer.SetConditionalAppearancePriceIncludesVAT(ThisObject, "SubstituteGoodsAmountIncludingVAT");
	
	// Setting the Conditional appearance of the returned item of a different quality.
	ConditionalDesignParameters = ProductsServer.ParametersOfConditionalAppearanceOfDifferentQualityItem();
	ConditionalDesignParameters.NameOfProductsField = Items.ReturnedGoodsProductsRecordingAsReceived.Name;
	ConditionalDesignParameters.PathToSourceQualityItemField = "Object.ReturnedGoods.Products";
	ConditionalDesignParameters.StockQualityChangeAttributeIsUsed = True;
	ConditionalDesignParameters.PathToStockQualityChangeField = "Object.ReturnedGoods.Damage";
	
	ProductsServer.SetConditionalAppearanceOfDifferentQualityItem(ThisObject, ConditionalDesignParameters);
	
	//
	
	ConditionalDesignParameters = ProductsServer.NewParametersForConditionalDesignOfUnitsOfMeasurement();
	ConditionalDesignParameters.NameOfUnitField = "ReturnedGoodsProductsUnitOfMeasure";
	ConditionalDesignParameters.PathToPackagingUnitField = "Object.ReturnedGoods.Package";
	ProductsServer.SetConditionalAppearanceOfUnitsOfMeasurement(ThisObject, ConditionalDesignParameters);
	
	//

	ConditionalDesignParameters = ProductsServer.NewParametersForConditionalDesignOfUnitsOfMeasurement();
	ConditionalDesignParameters.NameOfUnitField = "SubstituteGoodsProductsUnitOfMeasure";
	ConditionalDesignParameters.PathToPackagingUnitField = "Object.SubstituteGoods.Package";
	ProductsServer.SetConditionalAppearanceOfUnitsOfMeasurement(ThisObject, ConditionalDesignParameters);
	
	//

	TMCommonUse.SetConditionalAppearanceOfPriority(ThisObject);

	//

	ProductsServer.EstablishConditionalAppearanceOfProductCharacteristics(ThisObject, 
																			 "SubstituteGoodsCharacteristic",
																		     "Object.SubstituteGoods.ItemVariantsAreUsed");

	//

	ProductsServer.EstablishConditionalAppearanceOfProductCharacteristics(ThisObject, 
																			 "ReturnedGoodsCharacteristic",
																		     "Object.ReturnedGoods.ItemVariantsAreUsed");

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ReturnedGoodsCharacteristicRecordingAsReceived.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.ReturnedGoods.ItemVariantsAreUsedRecordingAsReceived");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.ReturnedGoods.Damage");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

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

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ReturnedGoodsCharacteristicRecordingAsReceived.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.ReturnedGoods.ItemVariantsAreUsedRecordingAsReceived");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.ReturnedGoods.Damage");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;

	Item.Appearance.SetParameterValue("TextColor", StyleColors.TextColorOfCanceledRowOfDocument);
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	Item.Appearance.SetParameterValue("ReadOnly", True);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ReturnedGoodsProductsRecordingAsReceived.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ReturnedGoodsCharacteristicRecordingAsReceived.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.ReturnedGoods.Damage");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;

	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	Item.Appearance.SetParameterValue("ReadOnly", True);

	//
	
	AdditionalParametersSetConditionalAppearanceOfContent = ProductsServer.AdditionalParametersSetConditionalAppearanceOfContent();
	AdditionalParametersSetConditionalAppearanceOfContent.NameOfContentInputField            = "SubstituteGoodsContent";
	AdditionalParametersSetConditionalAppearanceOfContent.NameOfPackageInputField              = "SubstituteGoodsPackage";
	AdditionalParametersSetConditionalAppearanceOfContent.PathToDesignOptionSelectionField = "Object.SubstituteGoods.SaleRegistrationOption";
	AdditionalParametersSetConditionalAppearanceOfContent.PathToContentSelectionField         = "Object.SubstituteGoods.Content";
	
	ProductsServer.EstablishConditionalAppearanceOfContent(ThisObject, AdditionalParametersSetConditionalAppearanceOfContent);

	//

	EnterprisePricesFillingServer.EstablishConditionalAppearanceOfPriceTypes(ThisObject, 
									                     "ReturnedGoodsPriceKind", 
                                                         "Object.ReturnedGoods.PriceKind");

	//

	EnterprisePricesFillingServer.EstablishConditionalAppearanceOfPriceTypes(ThisObject, 
									                     "SubstituteGoodsPriceKind", 
                                                         "Object.SubstituteGoods.PriceKind");

	//

	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.DateOfReceipt.Name);
	
	FilterGroup1 = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup1.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	
	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Status");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotInList;
	ValueList = New ValueList;
	ValueList.Add(Enums.StatusesOfRequestsForReturnOfGoodsFromCustomers.ForReturn);
	ValueList.Add(Enums.StatusesOfRequestsForReturnOfGoodsFromCustomers.ToSupply);
	ValueList.Add(Enums.StatusesOfRequestsForReturnOfGoodsFromCustomers.ToShip);
	ValueList.Add(Enums.StatusesOfRequestsForReturnOfGoodsFromCustomers.Executed);
	ItemFilter.RightValue = ValueList;
	
	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.DateOfReceipt");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	
	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("AllReturnLinesAreCanceled");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.DateOfReceipt.Name);
	
	FilterGroup1 = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup1.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
	
	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Status");
	ItemFilter.ComparisonType = DataCompositionComparisonType.InList;
	ValueList = New ValueList;
	ValueList.Add(Enums.StatusesOfRequestsForReturnOfGoodsFromCustomers.ForReturn);
	ValueList.Add(Enums.StatusesOfRequestsForReturnOfGoodsFromCustomers.ToSupply);
	ValueList.Add(Enums.StatusesOfRequestsForReturnOfGoodsFromCustomers.ToShip);
	ValueList.Add(Enums.StatusesOfRequestsForReturnOfGoodsFromCustomers.Executed);
	ItemFilter.RightValue = ValueList;
	
	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.DateOfReceipt");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.OneDateReceipt");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("AllReturnLinesAreCanceled");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	Item.Appearance.SetParameterValue("MarkIncomplete", True);
	
	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ReturnedGoodsDocumentSalesOfGoodsAndServices.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.CashRegisterReceipt");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	Item.Appearance.SetParameterValue("Visible", False);

	//
	
	InstallationParameters = ReusablePackageServer.ParametersForSettingConditionalAppearanceForLinesWithMultiTurnContainers();
	
	InstallationParameters.Form                 = ThisObject;
	InstallationParameters.ThisIsAdmission        = True;
	InstallationParameters.ThisIsTransfer           = ?(Object.BusinessOperation = Enums.BusinessTransactions.ReturnFromCustodian
		Or Object.BusinessOperation = Enums.BusinessTransactions.ReturnFromCommissionAgent, True, False);
	InstallationParameters.NameOfVATRateField = "ReturnedGoodsVATRate";
	InstallationParameters.NameOfPriceInputField      = "ReturnedGoodsPrice";
	InstallationParameters.NameOfAmountInputField     = "ReturnedGoodsSum";
	InstallationParameters.KTCHSelectionPath         = "Object.ReturnedGoods";
	
	ReusablePackageServer.SetConditionalAppearanceForLinesWithMultiTurnContainers(InstallationParameters);
	
	//
	
	InstallationParameters = ReusablePackageServer.ParametersForSettingConditionalAppearanceForLinesWithMultiTurnContainers();
	
	InstallationParameters.Form                 = ThisObject;
	InstallationParameters.ThisIsAdmission        = True;
	InstallationParameters.NameOfVATRateField = "SubstituteGoodsVATRate";
	InstallationParameters.NameOfPriceInputField      = "SubstituteGoodsPrice";
	InstallationParameters.NameOfAmountInputField     = "SubstituteGoodsSum";
	InstallationParameters.KTCHSelectionPath         = "Object.SubstituteGoods";
	
	ReusablePackageServer.SetConditionalAppearanceForLinesWithMultiTurnContainers(InstallationParameters);

	//

	ProductsServer.EstablishConditionalAppearanceOfProductSeries(ThisObject, False, 
																     "ReturnedGoodsSeries", 
																     "Object.ReturnedGoods.BatchesIndicationStatus",
																	 "Object.ReturnedGoods.ItemsType");

	//

	ProductsServer.EstablishConditionalAppearanceOfProductSeries(ThisObject, "SeriesAlwaysWHGoods", 
																     "SubstituteGoodsSeries", 
																     "Object.SubstituteGoods.BatchesIndicationStatus", 
																     "Object.SubstituteGoods.ItemsType");

	//

	ProductsServer.SetConditionalAppearanceOfStatusIndicationSeries(ThisObject, False, 
																		 "ReturnedGoodsBatchesIndicationStatus",
                                                                         "Object.ReturnedGoods.BatchesIndicationStatus");

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.Warehouse.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Warehouse");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;

	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	
	//
	
	SetsServer.SetConditionalAppearance(ThisObject, "SubstituteGoods");
	
	SetsServer.SetConditionalAppearance(ThisObject, "ReturnedGoods");
	
	//

	WarehousesServer.EstablishConditionalAppearanceOfVTCHDivision(ThisObject, "SubstituteGoods", False);

	//
	
	OrdersServer.SetAppearanceOfCanceledLine(ConditionalAppearance,
		Items.SubstituteGoods,
		Items.SubstituteGoodsCanceled.Name,
		Items.SubstituteGoodsCancellationReason.Name,
		Items.SubstituteGoodsPrice.Name,
		Items.SubstituteGoodsSum.Name);
	
	//
	
	OrdersServer.SetAppearanceOfCanceledLine(ConditionalAppearance,
		Items.ReturnedGoods,
		Items.ReturnedGoodsCanceled.Name);
		
	LinesOfBusinessServer.EstablishConditionalAppearanceOfDirectionOfActivity(ThisObject);
	
	//
	
	RetailSalesLocalization.SetConditionalAppearance(ThisObject);
	
	// Conditional appearance of quality control Attributes.
	Fields = QualityControl.Fields(
		Items.ReturnedGoodsToControlQuality,
		Items.ReturnedGoodsQualityConfirmationDate);
	FlagDisabled = New Array();
	DateIsOptional = New Array();
	Statuses = Enums.StatusesOfRequestsForReturnOfGoodsFromCustomers;
	ItemsTypes = Enums.ItemsTypes;
	QualityControl.AddFilter(FlagDisabled, "Object.ReturnedGoods.Canceled", True);
	QualityControl.AddFilter(FlagDisabled, "Object.ReturnedGoods.ItemsType", ItemsTypes.Work_5);
	QualityControl.AddFilter(FlagDisabled, "Object.ReturnedGoods.ItemsType", ItemsTypes.OperationService);
	QualityControl.AddFilter(DateIsOptional, "Object.Status", Statuses.NotAgreedUpon);
	QualityControl.AddFilter(DateIsOptional, "Object.Status", Statuses.IsRejected);
	QualityControl.SetupAppearance(ConditionalAppearance, Fields, FlagDisabled, DateIsOptional);
	
EndProcedure

&AtServer
Procedure SetVisibilityOfCommandAndFillInVATRate()

	VATRateFillingCommands = New Array;
	VATRateFillingCommands.Add("ReturnedGoodsFillInVATRATE");
	VATRateFillingCommands.Add("ReplacementGoodsFillInVATRate");
	TMCommonUseClientServer.SetPropertyOfFormElements(
		Items,
		VATRateFillingCommands,
		"Visible",
		ValueIsFilled(Object.VATTaxation)
			And Object.VATTaxation <> Enums.VATTaxationTypes.SaleIsNotSubjectToVAT);

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
Function SoftwareSelectionParameters(Mode)
	
	FormParameters = ProvisionInDocumentsServer.SoftwareSelectionParameters(
		ThisObject,
		Items.SubstituteGoods.CurrentRow,
		Mode);
		
	Return FormParameters;
	
EndFunction

&AtClient
Function ParametersOfQuantityAndSeriesRequestForm(Mode)
	
	CheckParameters = SupplyClientServer.InitializeFillVerificationParameters("SubstituteGoods",
		NStr("vi = 'Hàng hóa thay thế';
			|ru = 'Заменяющие товары';
			|en = 'Exchange goods'; fa = 'کالای تعویضی';
			|it = 'Merci sostitutive';
			|pl = 'wiersze pozycji zastępcze';
			|tr = 'İkame ürünler'"));
	
	If Not SupplyClient.CheckFilling(
				Object,
				Object.SubstituteGoods,
				Items.SubstituteGoods.CurrentRow,
				CheckParameters,
				Object.Warehouse,
				Mode) Then
		Return Undefined;
	EndIf;
	
	FormParameters = SoftwareSelectionParameters(Mode);
	FormParameters.SeriesSpecificationParameters = SeriesSpecificationParameters.Substitutes_;
	
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
Procedure SetSoftwareVisibility()
	
	HasRight = ProvisionInDocumentsServer.HaveRightToViewStateHyperlink();
	ItIsNecessaryToReplaceGoods = Object.CompensationMethod = Enums.CompensationMethodsForReturnsOfGoods.ToSubstituteGoods;
	Items.PagesHyperlinkSoftwareStatus.Visible = HasRight And UseShipmentByRowsInSalesOrder
		And ItIsNecessaryToReplaceGoods;
	
	If Not AccessRight("Insert", Metadata.Documents.InventoryAssignmentAdjustment)
		Or Not GetFunctionalOption("UseOrderSupplyWithAssignment")
		Or Object.ThisIsOrderAsInvoice 
		Or Not UseShipmentByRowsInSalesOrder Then
		Items.CreateAssignmentAdjustmentRemoveFromReserve.Visible = False;
		Items.CreateAnAssignmentAdjustmentReservation.Visible = False;
	EndIf;
	ProvisionInDocumentsServer.ConfigureHyperlinkedSoftwareState(ThisObject);
	Items.DateOfShipment.ToolTip = ProvisionInDocumentsServer.HintShipmentDate();
	
	YouCanRemoveFlagSeparately = Object.BusinessOperation <> PredefinedValue("Enum.BusinessTransactions.DeliveryForPrincipal");
	FlagManagement = UseShipmentByRowsInSalesOrder And YouCanRemoveFlagSeparately;
	FlagVisibility = UseShipmentByRowsInSalesOrder;
	CommonClientServer.SetFormItemProperty(
		Items,
		"SubstituteGoodsIncludeStandAloneCollateral",
		"Visible",
		FlagManagement);
	CommonClientServer.SetFormItemProperty(
		Items,
		"SubstituteGoodsTurnOffStandAloneCollateral",
		"Visible",
		FlagManagement);
	CommonClientServer.SetFormItemProperty(
		Items,
		"SubstituteGoodsWithAssignment",
		"Visible",
		FlagVisibility);
	CommonClientServer.SetFormItemProperty(
		Items,
		"SubstituteGoodsWithAssignment",
		"Enabled",
		FlagManagement);
	
	SecurityVisibility = UseShipmentByRowsInSalesOrder And Not Object.ThisIsOrderAsInvoice;
	CommonClientServer.SetFormItemProperty(
		Items,
		"SubstituteGoodsSupplyOption",
		"Visible",
		SecurityVisibility);
	CommonClientServer.SetFormItemProperty(
		Items,
		"SubstituteGoodsAvailable",
		"Visible",
		SecurityVisibility);
	
	CommonClientServer.SetFormItemProperty(
		Items,
		"SubstituteGoodsForCollateral",
		"Visible",
		SecurityVisibility);
	CommonClientServer.SetFormItemProperty(
		Items,
		"ReplacementProductsContextMenuToEnsure",
		"Visible",
		SecurityVisibility);
		
	CommonClientServer.SetFormItemProperty(
		Items,
		"ReplacementGoodsDoNotProvide",
		"Visible",
		SecurityVisibility);
	CommonClientServer.SetFormItemProperty(
		Items,
		"ReplacementProductsDoNotProvideContextMenu",
		"Visible",
		SecurityVisibility);
		
	CommonClientServer.SetFormItemProperty(
		Items,
		"ShipReplacementGoods",
		"Visible",
		SecurityVisibility);
	CommonClientServer.SetFormItemProperty(
		Items,
		"ReplacementProductsContextMenuShip",
		"Visible",
		SecurityVisibility);
		
	CommonClientServer.SetFormItemProperty(
		Items,
		"ReserveReplacementGoods",
		"Visible",
		SecurityVisibility);
	CommonClientServer.SetFormItemProperty(
		Items,
		"ReplacementProductsContextMenuReserve",
		"Visible",
		SecurityVisibility);
	
	CommonClientServer.SetFormItemProperty(
		Items,
		"ReserveReplacementItemsAsTheyArrive",
		"Visible",
		SecurityVisibility);
	CommonClientServer.SetFormItemProperty(
		Items,
		"ReserveReplacementProductsContextMenuAsTheyArrive",
		"Visible",
		SecurityVisibility);
		
EndProcedure

&AtServer
Procedure SetCommissionSaleAttribute()
	
	IndicatesCommissionSaleBeforeUpdate = ConsignmentSales25;
	
	If Object.BusinessOperation = Enums.BusinessTransactions.ReturnFromCommissionAgent Then
		If OnlyConsignmentSales25 Then
			ConsignmentSales25 = True;
		ElsIf ValueIsFilled(Object.Terms) Then
			ConsignmentSales25 = Common.ObjectAttributeValue(Object.Terms, "ConsignmentSales25");
		ElsIf ValueIsFilled(Object.Contract) Then
			ConsignmentSales25 = Common.ObjectAttributeValue(Object.Contract, "ConsignmentSales25");
		EndIf;
	Else
		ConsignmentSales25 = False;
	EndIf;
	
	If Not IndicatesCommissionSaleBeforeUpdate = ConsignmentSales25 Then
		UpdateCompensationMethod();
		SetPropertiesOfOutdatedCommissionUsageComment();
	EndIf;
	
EndProcedure

&AtServer
Procedure UpdateTextDocumentsBasedOn()
	
	If ValueIsFilled(Object.Ref) Then
		TextDocumentsBasedOn = VATAccountingLocalization.EventDocumentsOnPreliminaryDeliveries(Object, AmountOfReturnedItems);
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

#Region OnChangeAttributes

&AtServer
Procedure PartnerOnChangeServer()
	
	FillIn_TermsOfSales();
	
	PartnersAndCounterparties.FillInPartnerSDefaultCounterparty(Object.Partner, Object.Counterparty);
	UseCustomerContracts = GetFunctionalOption("UseCustomerContracts");
	If UseCustomerContracts Then
		FillInDefaultContract();
	EndIf;
	
	TMCommonUseClientServer.SetFormItemProperty(Items, "Partner", "ReadOnly", ValueIsFilled(Object.CashRegisterReceipt));
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInFeatureAttribute", New Structure("Products", "ItemVariantsAreUsed"));
	StructureOfActions.Insert("FillInSalesOptionAttribute", New Structure("Products", "SaleRegistrationOption"));
	StructureOfActions.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));
	StructureOfActions.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
	ProductsServer.FillInServiceDetailsForProductInCollection(Object.SubstituteGoods, StructureOfActions);
	StructureOfActions.FillInFeatureAttribute.Insert("ProductsRecordingAsReceived", "ItemVariantsAreUsedRecordingAsReceived");
	StructureOfActions.Delete("FillInSalesOptionAttribute");
	ProductsServer.FillInServiceDetailsForProductInCollection(Object.ReturnedGoods, StructureOfActions);
	
	SetsServer.FillInServiceDetails(ThisForm, "ReturnedGoods");
	SetsServer.FillInServiceDetails(ThisForm, "SubstituteGoods");
	
	UpdateDuplicateDependentDetails();

	WarehouseOnChangeServer();
	
	FillInServiceDetailsOfDocumentForm();
	CalculateTotalsOfRefundRequest(ThisForm);
	
	ArrayOfChangedProps = New Array;
	ArrayOfChangedProps.Add("Terms");
	ArrayOfChangedProps.Add("Partner");
	ArrayOfChangedProps.Add("Contract");
	ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisForm, ArrayOfChangedProps);
	
	CustomizeFormElements();
	SetContractVisibility();
	RefreshStatusServer();
	
	FillInAndSetDeliveryAttributesServer("Partner");
	
	UpdateInformationOnImplementations();
	SetVisibilityOfShipmentBanToPartner();
	SetVisibilityOfFillCommands();
	SalesServer.PartnerOnChange(Object);
	ResponsiblePersonsServer.FillInManagerSelectionList_(Items.Manager, Object);
	ResponsiblePersonsServer.InstallManager(
		Object, SalesServer.DocumentBasis(Object, "DocumentSalesOfGoodsAndServices, ReturnedGoods.DocumentSalesOfGoodsAndServices"));
	FillInSubordinatePropertiesForStatistics("Counterparty");
	
	ResponsiblePersonsServer.WhenChangingRelatedDocumentDetails(Object);
	
	If UseLinesOfBusiness Then
		LinesOfBusinessServer.FillInDefaultDirection(Object.LineOfBusiness, Object.Terms, Object.Contract);
	EndIf;
	LinesOfBusinessServer.WhenChangingDirectionOfActivity(ThisObject);
	ProvisionInDocumentsServer.WhenChangingDocumentDetails(ThisObject);
	
	If QualityControl.UpdateActionParameters(
			Documents.RequestForReturnOfGoodsFromCustomer,
			Object,
			CacheQualityControl) Then
			
		StructureOfActions = New Structure();
		StructureOfActions.Insert("FillInCheckQualityDateOfQualityConfirmation", CacheQualityControl);
		BatchProcessingOfTablePartServer.TreatTS(Object.ReturnedGoods, StructureOfActions);
		
	EndIf;
	
EndProcedure

&AtServer
Procedure PartnerClearingServer()
	
	SetVisibilityOfShipmentBanToPartner();
	ResponsiblePersonsServer.FillInManagerSelectionList_(Items.Manager, Object);
	ResponsiblePersonsServer.InstallManager(
		Object, SalesServer.DocumentBasis(Object, "DocumentSalesOfGoodsAndServices, ReturnedGoods.DocumentSalesOfGoodsAndServices"));
	
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
Procedure TermsOnChangeServer(RefillReplacementItems = False)
	
	DocumentSales = FormAttributeToValue("Object");
	DocumentSales.FillInTermsOfSalesUnderAgreement(Not Object.FillInPricesOfSubstituteGoodsByReturned);
	
	DocumentBasis =
		SalesServer.DocumentBasis(DocumentSales, "DocumentSalesOfGoodsAndServices, ReturnedGoods.DocumentSalesOfGoodsAndServices");
	ResponsiblePersonsServer.FillInManagerSelectionList_(Items.Manager, DocumentSales);
	ResponsiblePersonsServer.InstallManager(DocumentSales, DocumentBasis);
	
	ValueToFormAttribute(DocumentSales, "Object");
	
	DocumentCurrency = Object.Currency;
	ConfigureElementsByOperationServer();
	
	ContractBusinessTransaction = SelfServiceClientServer.ContractBusinessTransaction(Object.BusinessOperation);
	
	WarehouseGroup_ = ItIsGroupOfWarehousesAndWarehousesUsedByWHForSale(Object.Warehouse);
	WarehouseOnChangeServer();
	
	If (Object.BusinessOperation = Enums.BusinessTransactions.ReturnFromCommissionAgent
			Or Object.BusinessOperation = Enums.BusinessTransactions.ReturnFromCustodian)
		And (UseDiscountAdjustmentsInSales Or UseDiscountsMarkupsInSales)Then
		DiscountsMarkupsFillingServer.CancelDiscounts(Object, "SubstituteGoods", True);
		DiscountsMarkupsFillingServer.ConfigureShowMessagesCommand(Object, Items.ShowMessages, False);
		UpdateDuplicateDependentDetails(True);
	EndIf;
	
	SetCommissionSaleAttribute();
	UpdateCompensationMethod();
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInFeatureAttribute", New Structure("Products", "ItemVariantsAreUsed"));
	StructureOfActions.Insert("FillInSalesOptionAttribute", New Structure("Products", "SaleRegistrationOption"));
	StructureOfActions.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));
	StructureOfActions.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
	ProductsServer.FillInServiceDetailsForProductInCollection(Object.SubstituteGoods, StructureOfActions);
	StructureOfActions.FillInFeatureAttribute.Insert("ProductsRecordingAsReceived", "ItemVariantsAreUsedRecordingAsReceived");
	StructureOfActions.Delete("FillInSalesOptionAttribute");
	ProductsServer.FillInServiceDetailsForProductInCollection(Object.ReturnedGoods, StructureOfActions);
	
	SetsServer.FillInServiceDetails(ThisForm, "ReturnedGoods");
	SetsServer.FillInServiceDetails(ThisForm, "SubstituteGoods");
	
	UpdateDuplicateDependentDetails();
	
	Object.CounterpartyBankAccount = GetDefaultCounterpartyBankAccountServer(Object.Counterparty);
	CashServer.CheckFillInOrganizationSBankAccountByOwner(Object.Organization,
		Object.BankAccount, , Object.LineOfBusiness, Object.ForeignCurrencyTransaction);
	CashServer.CheckOrganizationSSalesRegisterByOwner(Object.Organization, Object.CashAccount, Object.PaymentMethod, Object.LineOfBusiness);
	
	FillInServiceDetailsOfDocumentForm();
	
	If RefillReplacementItems And Object.CompensationMethod = Enums.CompensationMethodsForReturnsOfGoods.ToSubstituteGoods Then
		FillInSubstituteGoodsByReturnedOnesServer();
	EndIf;
	
	CalculateTotalsOfRefundRequest(ThisForm);
	UpdateInformationOnImplementations();
	
	AttributesArray = New Array;
	AttributesArray.Add("Contract");
	AttributesArray.Add("Terms");
	ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisForm, AttributesArray);
	
	CustomizeFormElements();
	SetContractVisibility();
	RefreshStatusServer();
	UpdateCompensationMethod();
	SetVisibilityOfFillCommands();
	
	FillInSubordinatePropertiesForStatistics("Contract");
	
	ResponsiblePersonsServer.WhenChangingRelatedDocumentDetails(Object);
	
	SecurityOptionAndFlagSeparately = SalesServer.ProvisionOptionAndFlagAreSeparateByDefault(Object.Terms, Object.Status, , Not Object.ThisIsOrderAsInvoice);
	
	If UseLinesOfBusiness Then
		LinesOfBusinessServer.FillInDefaultDirection(Object.LineOfBusiness, Object.Terms, Object.Contract);
	EndIf;
	LinesOfBusinessServer.WhenChangingDirectionOfActivity(ThisObject);
	ProvisionInDocumentsServer.WhenChangingDocumentDetails(ThisObject);

	SetBanOnSelectingWarehouseGroup(Items.Warehouse);
	If QualityControl.UpdateActionParameters(
			Documents.RequestForReturnOfGoodsFromCustomer,
			Object,
			CacheQualityControl) Then
			
		StructureOfActions = New Structure();
		StructureOfActions.Insert("FillInCheckQualityDateOfQualityConfirmation", CacheQualityControl);
		BatchProcessingOfTablePartServer.TreatTS(Object.ReturnedGoods, StructureOfActions);
		
	EndIf;

EndProcedure

&AtServer
Procedure TermsClearingServer()
	
	ResponsiblePersonsServer.FillInManagerSelectionList_(Items.Manager, Object);
	ResponsiblePersonsServer.InstallManager(
		Object, SalesServer.DocumentBasis(Object, "DocumentSalesOfGoodsAndServices, ReturnedGoods.DocumentSalesOfGoodsAndServices"));
	
EndProcedure

&AtServer
Procedure ContractOnChangeServer(DirectModificationOfContractField = False)
	
	ForeignCurrencyTransaction = Object.ForeignCurrencyTransaction;
	ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisForm, "Contract");
	
	If ValueIsFilled(Object.Contract) Then
		Object.ForeignCurrencyTransaction = Common.ObjectAttributeValue(Object.Contract,"ForeignCurrencyTransaction");
	EndIf;
	
	If ForeignCurrencyTransaction <> Object.ForeignCurrencyTransaction Then
		Object.BankAccount = Catalogs.CompaniesBankAccounts.EmptyRef();
	EndIf;
	
	SalesServer.FillInBankAccountsUnderAgreement(Object.Contract, Object.BankAccount,
		Object.CounterpartyBankAccount);
	
	SetCommissionSaleAttribute();
	
	If ConsignmentSales25 Then
		// Recalculation of the Contract price for commission 2.5.
		StructureOfActions = New Structure;
		StructureOfActions.Insert("FillIn_TermsOfSales", BatchProcessingOfTablePartClientServer.GetStructureForFillingInSalesConditionsInTSLine(Object));
		
		StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
		StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
		StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
		StructureOfActions.Insert("RecalculateAmount");
		StructureOfActions.Insert("FillInDuplicateDependentDetails", DependentDetailsReturnedGoods());
		
		BatchProcessingOfTablePartServer.TreatTS(Object.ReturnedGoods, StructureOfActions);
	EndIf;
		
	FillInSalesVATTaxation();
	VATTaxationOnChangeServer();
	
	If UseLinesOfBusiness Then
		LinesOfBusinessServer.FillInDefaultDirection(Object.LineOfBusiness, Object.Terms, Object.Contract);
	EndIf;
	
	Object.BankAccount = GetOrganizationSDefaultBankAccountServer();
	
	ResponsiblePersonsServer.FillInManagerSelectionList_(Items.Manager, Object);
	ResponsiblePersonsServer.InstallManager(
		Object, SalesServer.DocumentBasis(Object, "DocumentSalesOfGoodsAndServices, ReturnedGoods.DocumentSalesOfGoodsAndServices"));
	FillInSubordinatePropertiesForStatistics("Contract");
	
	UpdateCompensationMethod();
	CustomizeFormElements();
	RefreshStatusServer();
	LinesOfBusinessServer.WhenChangingDirectionOfActivity(ThisObject);
	ProvisionInDocumentsServer.WhenChangingDocumentDetails(ThisObject);
	If QualityControl.UpdateActionParameters(
			Documents.RequestForReturnOfGoodsFromCustomer,
			Object,
			CacheQualityControl,
			DirectModificationOfContractField) Then
			
		StructureOfActions = New Structure();
		StructureOfActions.Insert("FillInCheckQualityDateOfQualityConfirmation", CacheQualityControl);
		BatchProcessingOfTablePartServer.TreatTS(Object.ReturnedGoods, StructureOfActions);
		
	EndIf;
	
EndProcedure

&AtServer
Procedure CurrencyOnChangeServer(NewCurrency, RecalculateAmounts)
	
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
			Object.ReturnedGoods,
			Object.PriceIncludesVAT,
			OldCurrency,
			NewCurrency,
			StructureOfOldCurrencyRates,
			StructureOfNewCurrencyRates);
		
		PriceManagementSystem.ConvertTabularAmountsToCurrency(
			Object.SubstituteGoods,
			Object.PriceIncludesVAT,
			OldCurrency,
			NewCurrency,
			StructureOfOldCurrencyRates,
			StructureOfNewCurrencyRates,
			True,
			True);
		
		UpdateDuplicateDependentDetails();
		CalculateTotalsOfRefundRequest(ThisForm);
		PriceManagementSystem.DistributeAmountByPaymentStages(Object, AmountOfReplacementProducts, PackageDepositValue);
	EndIf;
	
	FillInSubordinatePropertiesForStatistics("Currency");
	
	ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisForm, "Currency");
	If QualityControl.UpdateActionParameters(
			Documents.RequestForReturnOfGoodsFromCustomer,
			Object,
			CacheQualityControl) Then
			
		StructureOfActions = New Structure();
		StructureOfActions.Insert("FillInCheckQualityDateOfQualityConfirmation", CacheQualityControl);
		BatchProcessingOfTablePartServer.TreatTS(Object.ReturnedGoods, StructureOfActions);
		
	EndIf;
	
EndProcedure

&AtServer
Procedure BusinessOperationOnChangeServer()
	
	ContractBusinessTransaction = SelfServiceClientServer.ContractBusinessTransaction(Object.BusinessOperation);
	NewEconomicOperationOfAgreement = SelfServiceClientServer.BusinessTransactionFromAgreement(Object.BusinessOperation);
	
	If ToUseTermsOfSales And NewEconomicOperationOfAgreement <> BusinessTransactionFromAgreement Then
		BusinessTransactionFromAgreement = NewEconomicOperationOfAgreement;
		Object.Terms = Undefined;
	EndIf;
	
	SetCommissionSaleAttribute();
	FillInDefaultContract();
	
	Object.CashRegisterReceipt = Undefined;
	
	If (Object.BusinessOperation = Enums.BusinessTransactions.ReturnFromCommissionAgent
			Or Object.BusinessOperation = Enums.BusinessTransactions.ReturnFromCustodian) Then
		
		If (UseDiscountAdjustmentsInSales Or UseDiscountsMarkupsInSales)Then
			
			DiscountsMarkupsFillingServer.CancelDiscounts(Object, "SubstituteGoods", True);
			DiscountsMarkupsFillingServer.ConfigureShowMessagesCommand(Object, Items.ShowMessages, False);
			UpdateDuplicateDependentDetails(True);
			CalculateTotalsOfRefundRequest(ThisForm);
			
		EndIf;
		
		Object.PaymentScheduleSteps.Clear();
		
		If Object.BusinessOperation = Enums.BusinessTransactions.ReturnFromCommissionAgent Then
				Object.CompensationMethod = Enums.CompensationMethodsForReturnsOfGoods.EmptyRef();
		ElsIf Object.BusinessOperation = Enums.BusinessTransactions.ReturnFromCustodian Then
			Object.CompensationMethod = Enums.CompensationMethodsForReturnsOfGoods.EmptyRef();
			If ToUseTermsOfSales And ValueIsFilled(Object.Terms) Then
		 		SalesTermsAndConditions = SalesServer.GetTermsAndConditionsOfSale(Object.Terms, True);
				If SalesServer.GetRefundTransactionForSale(SalesTermsAndConditions.BusinessOperation) <> Object.BusinessOperation Then
					Object.Terms = Undefined;
				EndIf;
			EndIf;
		EndIf;
		
		If ((Object.BusinessOperation = Enums.BusinessTransactions.ReturnFromCommissionAgent
			 And ConsignmentSales25) Or Object.BusinessOperation = Enums.BusinessTransactions.ReturnFromCustodian)
			 And Object.ToReturnReusablePackage Then
			Object.ToReturnReusablePackage = False;
			ToReturnReusablePackageOnChangeServer();
		EndIf;
		
	ElsIf Object.BusinessOperation = Enums.BusinessTransactions.ReturnFromRetailCustomer Then
		
		PartnerChanged = False;
			
		If Object.Partner <> Catalogs.Partners.RetailCustomer Then
			Object.Partner = Catalogs.Partners.RetailCustomer;
			PartnerChanged = True;
		EndIf;
		
		If PartnerChanged Then
			
			If ValueIsFilled(Object.Counterparty) Then
				Object.Counterparty = Catalogs.Counterparties.EmptyRef();
			EndIf;
			PartnerOnChangeServer();
		EndIf;
		
		Object.ToReturnReusablePackage = False;
		ToReturnReusablePackageOnChangeServer();
		
	ElsIf Object.BusinessOperation = Enums.BusinessTransactions.ReturnOfGoodsFromCustomer Then
		
		If Not ValueIsFilled(Object.CompensationMethod) Then
			Object.CompensationMethod = Enums.CompensationMethodsForReturnsOfGoods.ToSubstituteGoods;
		EndIf;
		
	EndIf;
	
	FillInSalesVATTaxation();
	VATTaxationOnChangeServer();
	
	ProvisionInDocumentsServer.WhenChangingDocumentDetails(ThisObject);
	FillInServiceDetailsOfDocumentForm();
	TMCommonUseClientServer.SetFormItemProperty(Items, "Partner", "ReadOnly", ValueIsFilled(Object.CashRegisterReceipt));
	
	ConfigureElementsByOperationServer();
	CustomizeFormElements();
	EstablishVisibilityOfCompensationMethods();
	SetContractVisibility();
	SetVisibilityOfFillCommands();
	
	ARAPAccountingFormWork.WhenChangingParametersOfMechanism(ThisForm);
	
	SetBanOnSelectingWarehouseGroup(Items.Warehouse);
	If QualityControl.UpdateActionParameters(
			Documents.RequestForReturnOfGoodsFromCustomer,
			Object,
			CacheQualityControl) Then
			
		StructureOfActions = New Structure();
		StructureOfActions.Insert("FillInCheckQualityDateOfQualityConfirmation", CacheQualityControl);
		BatchProcessingOfTablePartServer.TreatTS(Object.ReturnedGoods, StructureOfActions);
		
	EndIf;
	
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	
EndProcedure

&AtServer
Procedure CounterpartyOnChangeServer()
	
	If ValueIsFilled(Object.Counterparty) Then
		
		FillInDefaultContract();
		SalesServer.PartnerOnChange(Object);
		
		If Not ValueIsFilled(Object.CounterpartyBankAccount) Then
			Object.CounterpartyBankAccount = GetDefaultCounterpartyBankAccountServer(Object.Counterparty);
		EndIf;
		
	EndIf;
	
	UpdateInformationOnImplementations();
	
	If UseLinesOfBusiness Then
		LinesOfBusinessServer.FillInDefaultDirection(Object.LineOfBusiness, Object.Terms, Object.Contract);
	EndIf;

	ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisObject, "Counterparty");
	
	FillInAndSetDeliveryAttributesServer("Partner");
	
	FillInSubordinatePropertiesForStatistics("Counterparty");
	
	CustomizeFormElements();
	LinesOfBusinessServer.WhenChangingDirectionOfActivity(ThisObject);
	ProvisionInDocumentsServer.WhenChangingDocumentDetails(ThisObject);
	If QualityControl.UpdateActionParameters(
			Documents.RequestForReturnOfGoodsFromCustomer,
			Object,
			CacheQualityControl) Then
			
		StructureOfActions = New Structure();
		StructureOfActions.Insert("FillInCheckQualityDateOfQualityConfirmation", CacheQualityControl);
		BatchProcessingOfTablePartServer.TreatTS(Object.ReturnedGoods, StructureOfActions);
		
	EndIf;
	
	WhenChangingElementLocalization(ThisObject, "Counterparty");
	CheckCorrectAvailabilityOfDiscountsPaymentsWithBonusPointsLocalization();
	
EndProcedure

&AtServer
Procedure OrganizationOnChangeServer()
		
	If ValueIsFilled(Object.Organization) Then
		
		FillInDefaultContract();
		
		If UseLinesOfBusiness Then
			LinesOfBusinessServer.FillInDefaultDirection(Object.LineOfBusiness, Object.Terms, Object.Contract);
		EndIf;
		
		FillInSalesVATTaxation();
		VATTaxationOnChangeServer();
		
	EndIf;
	
	UpdateInformationOnImplementations();
	
	CashServer.CheckFillInOrganizationSBankAccountByOwner(Object.Organization,
		Object.BankAccount, , Object.LineOfBusiness, Object.ForeignCurrencyTransaction);
	CashServer.CheckOrganizationSSalesRegisterByOwner(Object.Organization, Object.CashAccount, Object.PaymentMethod, Object.LineOfBusiness);
	
	FillInSubordinatePropertiesForStatistics("Organization");
	ResponsiblePersonsServer.InstallManager(
		Object, SalesServer.DocumentBasis(Object, "DocumentSalesOfGoodsAndServices, ReturnedGoods.DocumentSalesOfGoodsAndServices"));
	
	ResponsiblePersonsServer.WhenChangingRelatedDocumentDetails(Object);
	
	ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisForm, "Organization");
	
	CustomizeFormElements();
	SetContractVisibility();
	LinesOfBusinessServer.WhenChangingDirectionOfActivity(ThisObject);
	ProvisionInDocumentsServer.WhenChangingDocumentDetails(ThisObject);
	If QualityControl.UpdateActionParameters(
			Documents.RequestForReturnOfGoodsFromCustomer,
			Object,
			CacheQualityControl) Then
			
		StructureOfActions = New Structure();
		StructureOfActions.Insert("FillInCheckQualityDateOfQualityConfirmation", CacheQualityControl);
		BatchProcessingOfTablePartServer.TreatTS(Object.ReturnedGoods, StructureOfActions);
		
	EndIf;
	
EndProcedure

&AtServer
Procedure WarehouseOnChangeServer(DirectModificationOfWarehouseField = False)
	
	WarehouseGroup_ = ItIsGroupOfWarehousesAndWarehousesUsedByWHForSale(Object.Warehouse);
	Warehouse = Object.Warehouse;
	
	SetParametersForSelectingProductsWarehouse();
	
	PrepareFillSetSeriesVisibility();
	
	FillInSalesVATTaxation();
	VATTaxationOnChangeServer();
	
	ProvisionInDocumentsServer.WhenChangingDocumentDetails(ThisObject);
	
	WarehousesServer.FillInWarehousesInTablePart(Object.Warehouse, WarehouseGroup_, Object.ReturnedGoods, True);
	WarehousesServer.FillInWarehousesInTablePart(Object.Warehouse, WarehouseGroup_, Object.SubstituteGoods, True);
	
	SetVisibilityOfItemsAcrossMultipleWarehouses();	
	
	OnChangingWarehouseInTablePartOfReturnedGoodsServer();
	OnChangingWarehouseInTablePartReplacingGoodsServer();
	
	If QualityControl.UpdateActionParameters(
			Documents.RequestForReturnOfGoodsFromCustomer,
			Object,
			CacheQualityControl,
			DirectModificationOfWarehouseField) Then
			
		StructureOfActions = New Structure();
		StructureOfActions.Insert("FillInCheckQualityDateOfQualityConfirmation", CacheQualityControl);
		BatchProcessingOfTablePartServer.TreatTS(Object.ReturnedGoods, StructureOfActions);
		
	EndIf;
	
EndProcedure

&AtServer
Procedure CashRegisterReceiptOnChangeServer(ReFillProducts)
	
	DocumentSalesOfGoodsAndServices = GetReportOnRetailSalesByCashRegisterReceipt(Object.CashRegisterReceipt);
	
	For Each LineProducts_ In Object.ReturnedGoods Do
		LineProducts_.DocumentSalesOfGoodsAndServices = DocumentSalesOfGoodsAndServices;
	EndDo;
	Object.Partner = Common.ObjectAttributeValue(Object.CashRegisterReceipt, "Partner");
	
	If ToUseTermsOfSales And ValueIsFilled(Object.Terms) Then
		
		DocumentCurrency = Object.Currency;
		
		If (Object.BusinessOperation = Enums.BusinessTransactions.ReturnFromCommissionAgent
				Or Object.BusinessOperation = Enums.BusinessTransactions.ReturnFromCustodian)
			And (UseDiscountAdjustmentsInSales Or UseDiscountsMarkupsInSales)Then
			DiscountsMarkupsFillingServer.CancelDiscounts(Object, "SubstituteGoods", True);
			DiscountsMarkupsFillingServer.ConfigureShowMessagesCommand(Object, Items.ShowMessages, False);
		EndIf;
		
		ConfigureElementsByOperationServer();
		
	EndIf;
	
	Counterparty = Object.Counterparty;
	PartnersAndCounterparties.FillInPartnerSDefaultCounterparty(Object.Partner, Object.Counterparty, True);
	
	TMCommonUseClientServer.SetFormItemProperty(Items, "Partner", "ReadOnly", ValueIsFilled(Object.CashRegisterReceipt));
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInFeatureAttribute", New Structure("Products", "ItemVariantsAreUsed"));
	StructureOfActions.Insert("FillInSalesOptionAttribute", New Structure("Products", "SaleRegistrationOption"));
	StructureOfActions.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));
	StructureOfActions.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
	ProductsServer.FillInServiceDetailsForProductInCollection(Object.SubstituteGoods, StructureOfActions);
	StructureOfActions.FillInFeatureAttribute.Insert("ProductsRecordingAsReceived", "ItemVariantsAreUsedRecordingAsReceived");
	StructureOfActions.Delete("FillInSalesOptionAttribute");
	ProductsServer.FillInServiceDetailsForProductInCollection(Object.ReturnedGoods, StructureOfActions);
	
	SetsServer.FillInServiceDetails(ThisForm, "ReturnedGoods");
	SetsServer.FillInServiceDetails(ThisForm, "SubstituteGoods");
	FillInFormDetailsFromCashRegisterReceipt(Object.CashRegisterReceipt, New Structure("CashReceiptPriceType", "PriceKind"));
	
	UpdateDuplicateDependentDetails();
	If Counterparty <> Object.Counterparty Then
		Object.CounterpartyBankAccount = GetDefaultCounterpartyBankAccountServer(Object.Counterparty);
	EndIf;
	
	If ReFillProducts Then
		FillInReturnedItemsByReceipt();
	EndIf;
	
	CalculateTotalsOfRefundRequest(ThisForm);

	ArrayOfChangedProps = New Array;
	ArrayOfChangedProps.Add("Terms");
	ArrayOfChangedProps.Add("Partner");
	ArrayOfChangedProps.Add("Contract");
	ArrayOfChangedProps.Add("Currency");
	ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisForm, ArrayOfChangedProps);

	CustomizeFormElements();
	SetContractVisibility();
	
EndProcedure

&AtServer
Procedure PriceIncludesVATOnChangeServer(CachedValues)
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForRecalculatingNDSWTCHAmount(Object);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("FillInVATRateByPriceType", BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRateByPriceType(Object));
	
	BatchProcessingOfTablePartServer.TreatTS(Object.ReturnedGoods, StructureOfActions, CachedValues);
	BatchProcessingOfTablePartServer.TreatTS(Object.SubstituteGoods, StructureOfActions, CachedValues);
	
	UpdateDuplicateDependentDetails();
	CalculateTotalsOfRefundRequest(ThisForm);
	
	If Not ToUseTermsOfSales Then
		PriceTypeSelectionParameters = SettingsValueCached.ParametersForSelectingDefaultPriceType();
	
		PriceTypeSelectionParameters.PriceIncludesVAT        = Object.PriceIncludesVAT;
		PriceTypeSelectionParameters.UseWhileSellingToCustomers = True;
		PriceTypeSelectionParameters.Status                 = Enums.StatusesOfPriceTypeValidity.Valid;
		
		DefaultPriceType = SettingsValueCached.DefaultPriceType(PriceTypeSelectionParameters);
	EndIf;
	
EndProcedure

&AtServer
Procedure VATTaxationOnChangeServer(OnlyReplacementGoods = False)
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("AdjustVATRate",
			BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRate(Object, False, Object.ToReturnReusablePackage));
			
	If Not ValueIsFilled(Object.DocumentSalesOfGoodsAndServices) And Not OnlyReplacementGoods Then
		CachedValuesReturnedProducts = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
		BatchProcessingOfTablePartServer.TreatTS(Object.ReturnedGoods, StructureOfActions, CachedValuesReturnedProducts);
	EndIf;
	
	CachedValuesThatReplaceProducts = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	
	If Object.NotShipInInstallments And ValueIsFilled(Object.DateOfShipment) Then
		StructureOfActions.AdjustVATRate.Date = Object.DateOfShipment;
	EndIf;
	
	StructureOfActions.AdjustVATRate.ByShipmentDate = True;
	
	BatchProcessingOfTablePartServer.TreatTS(Object.SubstituteGoods, StructureOfActions, CachedValuesThatReplaceProducts);
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForRecalculatingNDSWTCHAmount(Object);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("FillInVATRateByPriceType", BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRateByPriceType(Object));
	
	If Not ValueIsFilled(Object.DocumentSalesOfGoodsAndServices) And Not OnlyReplacementGoods Then
		BatchProcessingOfTablePartServer.ProcessTSStrings(
			CachedValuesReturnedProducts.ProcessedRows,
			StructureOfActions,
			Object.ReturnedGoods,
			Undefined);
	EndIf;
		
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		CachedValuesThatReplaceProducts.ProcessedRows,
		StructureOfActions,
		Object.SubstituteGoods,
		Undefined);
	
	UpdateDuplicateDependentDetails();
	CalculateTotalsOfRefundRequest(ThisForm);

	SetVisibilityOfCommandAndFillInVATRate();

EndProcedure

&AtServer 
Procedure OneDateReceiptOnChangeServer()
	
	// Calculate the maximum date of receipt and bring PM to it
	If Object.OneDateReceipt Then
		
		Object.DateOfReceipt = MaximumReceiptDate();
		
		FillIn_ReceiptDatesServer(Object.DateOfReceipt);
		
	Else
		
		QualityControl.UpdateActionParameters(
			Documents.RequestForReturnOfGoodsFromCustomer,
			Object,
			CacheQualityControl);
		
	EndIf;
	
	CustomizeFormElements();
	
EndProcedure

&AtServer
Function DateOnChangeServer(RecalculatePrices_2)
	
	If RecalculatePrices_2 Then
		PricesCalculated = FillThePricesByTermsOfSalesServer();
	Else
		PricesCalculated = False;
	EndIf;

	ResponsiblePersonsServer.WhenChangingRelatedDocumentDetails(Object);
	PrepareFillSetSeriesVisibility();
	
	FillInSalesVATTaxation();
	VATTaxationOnChangeServer();
	
	ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisObject,"Date");
	FormEvents.WhenChangingElement(ThisObject, "Date");
	WhenChangingElementLocalization(ThisObject, "Date");
	
	CheckCorrectAvailabilityOfDiscountsPaymentsWithBonusPointsLocalization();
	
	Return PricesCalculated;
	
EndFunction

&AtServer
Procedure ApprovalDateForChangesOnServer()
	ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisForm, "ApprovalDate");
EndProcedure

&AtServer
Procedure CompensationMethodOnChangeServer()
		
	If Not UseShipmentByRowsInSalesOrder
		And Object.CompensationMethod = Enums.CompensationMethodsForReturnsOfGoods.ToSubstituteGoods Then
		
		StructureOfActions = New Structure();
		AddCollateralActionsOnServer(StructureOfActions,
			"SupplyOption,WarehouseIsRequired,DateOfShipmentRequired_");
		BatchProcessingOfTablePartServer.TreatTS(Object.SubstituteGoods, StructureOfActions, Undefined);
		FillInServiceDetailsOfDocumentForm();
		ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters.Substitutes_);
		UpdateColumnAvailableServer();
		
	EndIf;
	
	ARAPAccountingFormWork.WhenChangingParametersOfMechanism(ThisForm);
	
	CustomizeFormElements();
	
EndProcedure

&AtServer
Procedure StatusOnChangeServer()
	
	SecurityOptionAndFlagSeparately = SalesServer.ProvisionOptionAndFlagAreSeparateByDefault(Object.Terms, Object.Status, , Not Object.ThisIsOrderAsInvoice);
	
	If Not UseShipmentByRowsInSalesOrder
		And Object.CompensationMethod = Enums.CompensationMethodsForReturnsOfGoods.ToSubstituteGoods Then
		
		StructureOfActions = New Structure();
		AddCollateralActionsOnServer(StructureOfActions, "SupplyOption");
		BatchProcessingOfTablePartServer.TreatTS(Object.SubstituteGoods, StructureOfActions, Undefined);
		
		PrepareFillSetSeriesVisibility();
		
	EndIf;
	
	FillInServiceDetailsOfDocumentForm();
	SetAvailabilityOfItemsByStatusServer();
	
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	
EndProcedure

&AtServer
Procedure LineOfBusinessOnChangeServer()
	
	If Object.ARAPObjectSettings = Enums.ARAPObjectSettings.ByCounterpartyContracts Then
		FillInDefaultContract();
	EndIf;
	
	FillInSalesVATTaxation();
	VATTaxationOnChangeServer();
	LinesOfBusinessServer.WhenChangingDirectionOfActivity(ThisObject);
	
	ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisForm, "LineOfBusiness");
	ProvisionInDocumentsServer.WhenChangingDocumentDetails(ThisObject);
	If QualityControl.UpdateActionParameters(
			Documents.RequestForReturnOfGoodsFromCustomer,
			Object,
			CacheQualityControl) Then
			
		StructureOfActions = New Structure();
		StructureOfActions.Insert("FillInCheckQualityDateOfQualityConfirmation", CacheQualityControl);
		BatchProcessingOfTablePartServer.TreatTS(Object.ReturnedGoods, StructureOfActions);
		
	EndIf;
	
EndProcedure

&AtServer
Procedure AdjustOrderLines(StructureOfAdditionalParameters)
	
	OrderLineAdjustmentStructure = OrdersServer.OrderLineAdjustmentStructure();
	FillPropertyValues(OrderLineAdjustmentStructure, StructureOfAdditionalParameters);
	
	OrderObject = FormAttributeToValue("Object");
	
	OrderLineAdjustmentStructure.DocumentObject   = OrderObject;
	OrderLineAdjustmentStructure.CheckBalance = True;
	
	// Returned goods
	OrderLineAdjustmentStructure.TabularSectionName = "ReturnedGoods";
	ResultStructure1 = OrderObject.AdjustOrderLines(OrderLineAdjustmentStructure);
	
	// Replacement products
	OrderLineAdjustmentStructure.TabularSectionName = "SubstituteGoods";
	ResultStructure1 = SalesServer.AdjustOrderLines(OrderLineAdjustmentStructure);
	
	If ResultStructure1.RowsCount > 0 Or ResultStructure1.AdjustmentSum > 0 Then
		PaymentStepsServer.CheckAndFillInPaymentScheduleStages(OrderObject);
	EndIf;
	
	If OrderLineAdjustmentStructure.CloseOrders Then
		OrderObject.Status = Enums.StatusesOfRequestsForReturnOfGoodsFromCustomers.Executed;
	EndIf;
	
	ValueToFormAttribute(OrderObject, "Object");
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInFeatureAttribute", New Structure("Products", "ItemVariantsAreUsed"));
	StructureOfActions.Insert("FillInSalesOptionAttribute", New Structure("Products", "SaleRegistrationOption"));
	StructureOfActions.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
	StructureOfActions.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));
	
	ProductsServer.FillInServiceDetailsForProductInCollection(Object.SubstituteGoods, StructureOfActions);
	StructureOfActions.FillInFeatureAttribute.Insert("ProductsRecordingAsReceived", "ItemVariantsAreUsedRecordingAsReceived");
	StructureOfActions.Delete("FillInSalesOptionAttribute");
	StructureOfActions.Delete("FillInArticleAttribute");
	SeriesSpecificationParameters = New FixedStructure(ProductsServer.SeriesSpecificationParameters(Object, Documents.RequestForReturnOfGoodsFromCustomer));
	SetVisibilityOfSeriesElements();
	StructureOfActions.Insert("FillInArticleAttribute", New Structure("Products, ProductsRecordingAsReceived", "SKU", "SKURegistration"));
	ProductsServer.FillInServiceDetailsForProductInCollection(Object.ReturnedGoods, StructureOfActions);
	
	SetsServer.FillInServiceDetails(ThisObject, "ReturnedGoods");
	SetsServer.FillInServiceDetails(ThisObject, "SubstituteGoods");
	FillInFormDetailsFromCashRegisterReceipt(Object.CashRegisterReceipt, New Structure("CashReceiptPriceType", "PriceKind"));
	
	UpdateDuplicateDependentDetails();
	FillInServiceDetailsOfDocumentForm();
	CalculateTotalsOfRefundRequest(ThisForm);
	
	StructureOfActions = New Structure();
	StructureOfActions.Insert("FillInCheckQualityDateOfQualityConfirmation", CacheQualityControl);
	BatchProcessingOfTablePartServer.TreatTS(Object.ReturnedGoods, StructureOfActions);
	
	Modified = True;
	
EndProcedure

&AtServer
Procedure ReplacementGoodsCancelledOnChangeATServer()
	
	ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisObject, "SubstituteGoods.DateOfShipment");
	
EndProcedure

&AtServer
Procedure ReplacementGoodsAfterDeletionAtServer(ThereIsChangeInShippingDates)
	
	UpdateColumnAvailableServer();
	OnChangingWarehouseInTablePartReplacingGoodsServer();
	If ThereIsChangeInShippingDates Then
		ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisObject, "SubstituteGoods.DateOfShipment");
	EndIf;
	
EndProcedure
#EndRegion

#Region PricingAndDiscounts

&AtServer
Function FillThePricesByTermsOfSalesServer()
	
	PricesCalculated = SubstituteGoodsFillInPricesByAgreementServer(True);
	PricesCalculated = PricesCalculated Or ReturnedGoodsFillInPricesByAgreementServer(True);
	
	Return PricesCalculated;
	
EndFunction

&AtServer
Function TheStructureOfTheMessages()
	
	Return DiscountsMarkupsFillingServer.TheStructureOfTheMessages(Object);
	
EndFunction

&AtServer
Procedure MessagesReceived(Messages)
	
	DiscountsMarkupsFillingServer.SaveSpentMessages(Object, Messages);
	DiscountsMarkupsFillingServer.ConfigureShowMessagesCommand(Object, Items.ShowMessages);
	
EndProcedure

&AtServer
Procedure CalculateDiscountsWithoutApplyingToObject()
	
	ParametersStructure1 = DiscountsMarkupsFillingServer.NewParametersCalculate();
	ParametersStructure1.ApplyToObject = False;
	ParametersStructure1.OnlyPreliminaryCalculation = False;
	ParametersStructure1.RestoreManagedDiscounts = True;
	ParametersStructure1.ManagedDiscounts = ManagedDiscounts;
	
	AppliedDiscounts = DiscountsMarkupsFillingServer.Calculate(Object, ParametersStructure1);
	
	AddressOfAppliedDiscountsInTheTemporaryStorage = PutToTempStorage(AppliedDiscounts, UUID);
	
EndProcedure

&AtServer
Function CalculateDiscountsMarginsOnServer(ParametersStructure1, TakeFromTemporaryStorage = False)
	
	If Object.FillInPricesOfSubstituteGoodsByReturned Then
		
		TheStructureOfTheMessages = DiscountsMarkupsFillingServer.TheStructureOfTheMessages(Object);
		Return TheStructureOfTheMessages;
		
	EndIf;
		
	If TakeFromTemporaryStorage Then
		AppliedDiscounts = GetFromTempStorage(AddressOfAppliedDiscountsInTheTemporaryStorage);
		DiscountsMarkupsFillingServer.ApplyCalculationResult(Object, AppliedDiscounts);
	Else
		AppliedDiscounts = DiscountsMarkupsFillingServer.Calculate(Object, ParametersStructure1);
		AddressOfAppliedDiscountsInTheTemporaryStorage = PutToTempStorage(AppliedDiscounts, UUID);
	EndIf;
	
	Object.DiscountsAreCalculated = True;
	
	UpdateDuplicateDependentDetails(True);
	CalculateTotalsOfRefundRequest(ThisForm);
	
	TheStructureOfTheMessages = DiscountsMarkupsFillingServer.TheStructureOfTheMessages(Object);
	DiscountsMarkupsFillingServer.ConfigureShowMessagesCommand(Object, Items.ShowMessages);
	
	Return TheStructureOfTheMessages;
	
EndFunction

&AtServer
Function PerformPreliminaryCalculationOfDiscountsOnServer()
	
	ParametersStructure1 = DiscountsMarkupsFillingServer.NewParametersCalculate();
	ParametersStructure1.ApplyToObject				 = False;
	ParametersStructure1.OnlyPreliminaryCalculation		 = True;
	ParametersStructure1.RestoreManagedDiscounts	 = True;
	ParametersStructure1.ManagedDiscounts				 = ManagedDiscounts;
	
	Return PutToTempStorage(
			DiscountsMarkupsFillingServer.Calculate(Object, ParametersStructure1), UUID);
	
EndFunction

&AtServer
Procedure CancelManualDiscountsOnServer()
	
	DiscountsMarkupsFillingServer.CancelManualDiscounts(Object, "SubstituteGoods", True, True);
	UpdateDuplicateDependentDetails(True);
	
EndProcedure

&AtServer
Procedure AssignManualDiscountOnServer(AmountOfDiscountMarkUp, Val SelectedRows, AddressInTempStorage)
	
	DiscountParameters = DiscountsMarkupsFillingServer.NewOptionsAssignManualDiscount();
	DiscountParameters.AutomaticDiscountsAreUsed = True;
	DiscountParameters.CalculateAmountWithVAT			 = True;
	DiscountParameters.SelectedRows				 = SelectedRows;
	DiscountParameters.AddressInTempStorage		 = AddressInTempStorage;
	
	AddDiscountParametersLocalization(DiscountParameters);
	
	DiscountsMarkupsFillingServer.AssignAManualDiscount(Object, "SubstituteGoods", AmountOfDiscountMarkUp, DiscountParameters);
	UpdateDuplicateDependentDetails(True);
	
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
	
	If Not Object.FillInPricesOfSubstituteGoodsByReturned Then
		ShowUserNotification(
			NStr("vi = 'Chiết khấu (phụ thu)';
				|ru = 'Скидки (наценки)';
				|en = 'Discounts (markups)'; fa = 'تخفیف‌ها (افزایش قیمت‌ها)';
				|it = 'Sconti (sovrapprezzo)';
				|pl = 'Rabaty (marże)';
				|tr = 'İndirimler (zamlar)'"),
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
Procedure ApplyDiscountMarkUpChangesOnCustomer(Cancel)
	
	TheStructureOfTheMessages = CalculateDiscountsMarginsOnServer(Undefined, True);
	If TheStructureOfTheMessages.Messages.Count() > 0 And TheStructureOfTheMessages.AutomaticallyOpen Then
		OpenForm("CommonForm.MessagesOfDiscountsMarkups", TheStructureOfTheMessages, ThisForm, UUID);
		Cancel = True;
	EndIf;
	
	If Not Object.FillInPricesOfSubstituteGoodsByReturned Then
		ShowUserNotification(
			NStr("vi = 'Chiết khấu (phụ thu)';
				|ru = 'Скидки (наценки)';
				|en = 'Discounts (markups)'; fa = 'تخفیف‌ها (افزایش قیمت‌ها)';
				|it = 'Sconti (sovrapprezzo)';
				|pl = 'Rabaty (marże)';
				|tr = 'İndirimler (zamlar)'"),
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

&AtServer
Function ReturnedGoodsFillInPricesByAgreementServer(OnAllLines = False, ErrorText = "")
	If OnAllLines Then
		RowsArray = Undefined;
	Else
		RowsArray = New Array;
		For Each String In Items.ReturnedGoods.SelectedRows Do
			RowsArray.Add(Object.ReturnedGoods.FindByID(String));
		EndDo;
	EndIf;
	
	SetsServerCall.AddToFullSet(Object.ReturnedGoods, RowsArray);
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	
	FillParameters = New Structure;
	FillParameters.Insert("Date", Object.Date);
	FillParameters.Insert("Currency", Object.Currency);
	FillParameters.Insert("Partner", Object.Partner);
	FillParameters.Insert("VATTaxation", Object.VATTaxation);
	FillParameters.Insert("ReturnReusablePackage", Object.ToReturnReusablePackage);
	FillParameters.Insert("Organization", Object.Organization);
	FillParameters.Insert("CalculateSets", True);
	FillParameters.Insert("PopulationFields", "Price, PriceKind");
	If ConsignmentSales25 Then
		FillParameters.Insert("PriceKind", Common.ObjectAttributeValue(Object.Contract,"PriceTypeAccountingPriceType"));
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
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateAmount", "NumberOfPackages");
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("FillInVATRateByPriceType", BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRateByPriceType(Object));
	
	PricesCalculated = EnterprisePricesFillingServer.FillInPrices(
		Object.ReturnedGoods,
			RowsArray, // Array of rows or selection structure
			FillParameters,
			StructureOfActions);
	
	TMCommonUse.FillInDuplicateDependentPropsInCollection(Object.ReturnedGoods, DependentDetailsReturnedGoods());
	CalculateTotalsOfRefundRequest(ThisForm);
	
	Return PricesCalculated;
	
EndFunction

&AtServer
Function ReturnedItemsFillInPricesOfSelectedRowsByPriceTypeServer(PricesKind)
	
	RowsArray = New Array;
	For Each String In Items.ReturnedGoods.SelectedRows Do
		RowsArray.Add(Object.ReturnedGoods.FindByID(String));
	EndDo;
	
	SetsServerCall.AddToFullSet(Object.ReturnedGoods, RowsArray);
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	
	FillParameters = New Structure;
	FillParameters.Insert("Date", Object.Date);
	FillParameters.Insert("Organization", Object.Organization);
	FillParameters.Insert("Currency", Object.Currency);
	FillParameters.Insert("PriceKind", PricesKind);
	FillParameters.Insert("CalculateSets", True);
	FillParameters.Insert("PopulationFields", "Price, PriceKind");
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateAmount", "NumberOfPackages");
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("FillInVATRateByPriceType", BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRateByPriceType(Object));
	
	PricesCalculated = EnterprisePricesFillingServer.FillInPrices(
		Object.ReturnedGoods,
		RowsArray, // Array of rows or selection structure
		FillParameters,
		StructureOfActions);
	
	TMCommonUse.FillInDuplicateDependentPropsInCollection(Object.ReturnedGoods, DependentDetailsReturnedGoods());
	CalculateTotalsOfRefundRequest(ThisForm);
	
	Return PricesCalculated;
	
EndFunction

&AtServer
Function SubstituteGoodsFillInPricesByAgreementServer(OnAllLines = False, ErrorText = "")

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

	If OnAllLines Then
		RowsArray = Undefined;
	Else
		RowsArray = New Array;
		For Each String In Items.SubstituteGoods.SelectedRows Do
			RowsArray.Add(Object.SubstituteGoods.FindByID(String));
		EndDo;
	EndIf;
	
	SetsServerCall.AddToFullSet(Object.SubstituteGoods, RowsArray);
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	
	FillParameters = New Structure;
	FillParameters.Insert("Date", Object.Date);
	FillParameters.Insert("Currency", Object.Currency);
	FillParameters.Insert("Partner", Object.Partner);
	FillParameters.Insert("Terms", Object.Terms);
	If ConsignmentSales25 Then
		FillParameters.Insert("PriceKind", Common.ObjectAttributeValue(Object.Contract, "PriceTypeAccountingPriceType"));
	EndIf;
	FillParameters.Insert("VATTaxation", Object.VATTaxation);
	FillParameters.Insert("ReturnReusablePackage", Object.ToReturnReusablePackage);
	FillParameters.Insert("Organization", Object.Organization);
	FillParameters.Insert("CalculateSets", True);
	FillParameters.Insert("PopulationFields", "Price,  PriceKind, DeliveryPeriodDays");
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateAmount", "NumberOfPackages");
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountOfManualDiscount", "NumberOfPackages");
	StructureOfActions.Insert("ClearAutomaticDiscount", Undefined);
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountManualDiscount", New Structure("Clear", False));
	StructureOfActions.Insert("FillInVATRateByPriceType", BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRateByPriceType(Object));
	
	PricesCalculated = EnterprisePricesFillingServer.FillInPrices(
		Object.SubstituteGoods,
		RowsArray, // Array of rows or selection structure
		FillParameters,
		StructureOfActions);
	
	TMCommonUse.FillInDuplicateDependentPropsInCollection(Object.SubstituteGoods, DependentDetailsReplacingGoods());
	CalculateTotalsOfRefundRequest(ThisForm);
	
	Return PricesCalculated;
	
EndFunction

&AtServer
Function SubstituteProductsFillInPricesOfSelectedRowsByTypeOfPricesServer(PricesKind)
	
	RowsArray = New Array;
	For Each String In Items.SubstituteGoods.SelectedRows Do
		RowsArray.Add(Object.SubstituteGoods.FindByID(String));
	EndDo;
	
	SetsServerCall.AddToFullSet(Object.SubstituteGoods, RowsArray);
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	
	FillParameters = New Structure;
	FillParameters.Insert("Date", Object.Date);
	FillParameters.Insert("Organization", Object.Organization);
	FillParameters.Insert("Currency", Object.Currency);
	FillParameters.Insert("PriceKind", PricesKind);
	FillParameters.Insert("CalculateSets", True);
	FillParameters.Insert("PopulationFields", "Price, PriceKind");
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateAmount", "NumberOfPackages");
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountOfManualDiscount", "NumberOfPackages");
	StructureOfActions.Insert("ClearAutomaticDiscount", Undefined);
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountManualDiscount", New Structure("Clear", False));
	StructureOfActions.Insert("FillInVATRateByPriceType", BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRateByPriceType(Object));
	
	PricesCalculated = EnterprisePricesFillingServer.FillInPrices(
		Object.SubstituteGoods,
		RowsArray, // Array of rows or selection structure
		FillParameters,
		StructureOfActions);
	
	TMCommonUse.FillInDuplicateDependentPropsInCollection(Object.SubstituteGoods, DependentDetailsReplacingGoods());
	CalculateTotalsOfRefundRequest(ThisForm);
	
	Return PricesCalculated;
	
EndFunction

&AtServer
Function DiscountsHaveChanged()
	
	DiscountsHaveChanged = DiscountsMarkupsFillingServer.DiscountsMustBeRecalculated(
		Object, 
		ManagedDiscounts, 
		UUID, 
		AddressOfAppliedDiscountsInTheTemporaryStorage);
		
	If Object.SubstituteGoods.Total("DiscountMarkupAmountWithoutReusablePackages") <> Object.DiscountsMarkups.Total("Sum") Then
		DiscountsHaveChanged = True;
	EndIf;
	
	Return DiscountsHaveChanged;
	
EndFunction

&AtServer
Procedure ApplyPaymentWithBonusPoints(AddressInTempStorage)
	
	DeletingPayment = False;
	If AddressInTempStorage <> Undefined Then
		TableOfGoods = GetFromTempStorage(AddressInTempStorage);
	Else
		TableOfGoods = Object.SubstituteGoods;
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
	StructureOfActions.Insert("FillInDuplicateDependentDetails", DependentDetailsReplacingGoods());
	
	RowsToProcess = New Array;
	
	For Each TableRow In TableOfGoods Do
		
		If DeletingPayment Then
			TSRow = TableRow;
			TSRow.AmountOfBonusPointsToDeduction        = 0;
			TSRow.AmountOfBonusPointsToDeductionInCurrency = 0;
		Else
			TSRow = Object.SubstituteGoods.FindRows(New Structure("ConnectionKey", TableRow.ConnectionKey))[0];
			TSRow.AmountOfBonusPointsToDeduction        = TableRow.AmountOfBonusPointsToDeduction;
			TSRow.AmountOfBonusPointsToDeductionInCurrency = TableRow.AmountOfBonusPointsToDeductionInCurrency;
		EndIf;
		
		RowsToProcess.Add(TSRow);
		
	EndDo;
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		RowsToProcess,
		StructureOfActions,
		Object.SubstituteGoods);
	
	CalculateTotalsOfRefundRequest(ThisForm);
	
EndProcedure

#EndRegion

#Region SelectionAndProcessingOfQuantityVerification

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
	
EndProcedure

&AtServer
Procedure ProcessingSelectionOfSelectionOnServer(ValueSelected)
	
	TableOfGoods = GetFromTempStorage(ValueSelected.GoodsAddressInStorage);
	CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	
	ListOfProperties = "ProductsInSet,ItemVariantOfSet,Products,Characteristic,Package,DateOfShipment,PriceKind,Price,
			|NumberOfPackages, Count, Sum, ManualDiscount,PercentRateOfManualDiscount,DeliveryPeriodDays,SupplyOption,WithAssignment,Series";
	
	If ValueIsFilled(Object.Warehouse) Then
		ListOfProperties = ListOfProperties + ", Warehouse";
	EndIf;
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));

	ParametersForFillingInVATRate = BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRate(Object, True);
	If Object.NotShipInInstallments And ValueIsFilled(Object.DateOfShipment) Then
		ParametersForFillingInVATRate.Date = Object.DateOfShipment;
	EndIf;

	StructureOfActions.Insert("FillInVATRate", ParametersForFillingInVATRate);
	StructureOfActions.Insert("FillInVATRateByPriceType", BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRateByPriceType(Object));
	StructureOfActions.Insert("FillInVATRateForReturnableContainers", Object.ToReturnReusablePackage);
	StructureOfActions.Insert("FillInContent", BatchProcessingOfTablePartClientServer.GetStructureOfFillingInServiceContentInTSLine(Object, False));
	StructureOfActions.Insert("FillInNoReturnContainerAttribute", Object.ToReturnReusablePackage);
	StructureOfActions.Insert("FillInCanceledWithoutReturnableContainerAttribute", Object.ToReturnReusablePackage);
	StructureOfActions.Insert("FillInSubdivisionInTSLine", New Structure("Department", Object.Department));
	AddCollateralActionsOnServer(StructureOfActions, "WarehouseIsRequired,DateOfShipmentRequired_");
	
	AddReplacementProductsToActionStructureWhenChangingNumberOfPackages(StructureOfActions, Object);
	
	RowsToProcess = New Array;
	ShippingDates = New Map;
	BegOfDay = BegOfDay(CurrentSessionDate());
		
	For Each RowOfProduct In TableOfGoods Do
		
		CurrentRow = Object.SubstituteGoods.Add();
		FillPropertyValues(CurrentRow, RowOfProduct, ListOfProperties);
		CurrentRow.SetIndex = ?(ValueIsFilled(CurrentRow.ProductsInSet), 1, 0);
		ShippingDates.Insert(CurrentRow, RowOfProduct.DateOfShipment);
		RowsToProcess.Add(CurrentRow);
	
	EndDo;
		
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		RowsToProcess,
		StructureOfActions,
		Object.SubstituteGoods,
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
		Object.SubstituteGoods,
		"DateOfShipment");
	
	CalculateTotalsOfRefundRequest(ThisForm);
	
	OnChangingWarehouseInTablePartReplacingGoodsServer();
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInFeatureAttribute", New Structure("Products", "ItemVariantsAreUsed"));
	StructureOfActions.Insert("FillInSalesOptionAttribute", New Structure("Products", "SaleRegistrationOption"));
	StructureOfActions.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));
	
	ProductsServer.FillInServiceDetailsForProductInCollection(Object.SubstituteGoods,StructureOfActions);
	SetsServer.FillInServiceDetails(ThisForm, "SubstituteGoods");
	
	ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters.Substitutes_);
	ReusablePackageServer.UpdateFillingStateOfMultiTurnContainer(Object.ReusablePackageFillingStatus);
	UpdateColumnAvailableServer();
	
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
	
	ProcessingSelectionOfSelectionOnServer(AdditionalParameters);
	
EndProcedure

&AtServer
Procedure ProcessingSelectionSelectionByImplementationServer(ValueSelected)
	
	CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	
	ReturnValueStructure = GetFromTempStorage(ValueSelected.GoodsAddressInStorage);
	TableOfGoods = ReturnValueStructure.Goods;
	HeaderStructure_ = ReturnValueStructure.HeaderStructure_;
	
	ReturnFromRetailCustomer = (Object.BusinessOperation = Enums.BusinessTransactions.ReturnFromRetailCustomer);
	ReturnFromCommissionAgent = (Object.BusinessOperation = Enums.BusinessTransactions.ReturnFromCommissionAgent);
	QuantityOfGoodsInitially = Object.ReturnedGoods.Count();
	
	For Each RowOfProduct In TableOfGoods Do
		
		CurrentRow = Object.ReturnedGoods.Add();
		FillPropertyValues(CurrentRow, RowOfProduct);
		CurrentRow.Price = CurrentRow.Sum / CurrentRow.NumberOfPackages;
		CurrentRow.SetIndex = ?(ValueIsFilled(CurrentRow.ProductsInSet), 1, 0);
		
		If ReturnFromCommissionAgent Then
			CurrentRow.VATRate = Catalogs.VATRates.EmptyRef();
		EndIf;
		If Object.OneDateReceipt Then
			CurrentRow.DateOfReceipt = Object.DateOfReceipt;
		EndIf;
		If ReturnFromRetailCustomer Then
			CurrentRow.DocumentSalesOfGoodsAndServices = GetReportOnRetailSalesByCashRegisterReceipt(RowOfProduct.SaleTransferDocument);
		Else
			CurrentRow.DocumentSalesOfGoodsAndServices = RowOfProduct.SaleTransferDocument;
		EndIf;
		
		If ValueIsFilled(Object.Warehouse)
			And Not (ValueIsFilled(RowOfProduct.Warehouse) And WarehouseGroup_) Then
			CurrentRow.Warehouse = Object.Warehouse;
		EndIf;
		
	EndDo;
	
	Object.Partner = HeaderStructure_.Partner;
	If ValueIsFilled(HeaderStructure_.CashRegisterReceipt) Then
		If Not ValueIsFilled(Object.CashRegisterReceipt) And QuantityOfGoodsInitially=0 Then
			Object.CashRegisterReceipt = HeaderStructure_.CashRegisterReceipt;
			Object.Partner = Common.ObjectAttributeValue(Object.CashRegisterReceipt, "Partner");
			PartnerOnChangeServer();
		EndIf;
	EndIf;
	
	FillingInContactDetailsAfterFillingInSelectionForm(CachedValues);
	
	StructureOfActions = New Structure();
	StructureOfActions.Insert("FillInCheckQualityDateOfQualityConfirmation", CacheQualityControl);
	BatchProcessingOfTablePartServer.TreatTS(Object.ReturnedGoods, StructureOfActions);
	
	OnChangingWarehouseInTablePartOfReturnedGoodsServer();
	
EndProcedure

&AtServer
Procedure SelectionProcessingSelectionOfTransferredGoods(ValueSelected)
	
	RowsArray = New Array;
	
	TableOfGoods = GetFromTempStorage(ValueSelected.GoodsAddressInStorage);
	CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	
	PriceFillingParameters = New Structure();
	PriceFillingParameters.Insert("PopulationFields", "Price");
	PriceFillingParameters.Insert("Date",           Object.Date);
	PriceFillingParameters.Insert("Currency",         Object.Currency);
	PriceFillingParameters.Insert("Organization", Object.Organization);
	If Object.BusinessOperation = Enums.BusinessTransactions.ReturnFromCommissionAgent Then
		PriceFillingParameters.Insert("PriceKind", Common.ObjectAttributeValue(Object.Contract,"PriceTypeAccountingPriceType"));
		PriceFillingParameters.Insert("PopulationFields", "PriceKind, Price");
	Else
		PriceFillingParameters.Insert("Terms", Object.Terms);
	EndIf;
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateNumberOfPackages");

	ParametersForFillingInVATRate = BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRate(Object, True);
	If ValueIsFilled(Object.DocumentSalesOfGoodsAndServices) Then
		SaleDate = Common.ObjectAttributeValue(Object.DocumentSalesOfGoodsAndServices, "Date");
		ParametersForFillingInVATRate.Date = SaleDate;
	EndIf;

	StructureOfActions.Insert("FillInVATRate", ParametersForFillingInVATRate);
	StructureOfActions.Insert("FillInVATRateByPriceType", BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRateByPriceType(Object));
	StructureOfActions.Insert("FillInCheckQualityDateOfQualityConfirmation", CacheQualityControl);
	
	For Each RowOfProduct In TableOfGoods Do
		
		ProductsSearch = New Structure();
		ProductsSearch.Insert("Products", RowOfProduct.Products);
		ProductsSearch.Insert("Characteristic", RowOfProduct.Characteristic);
		ProductsSearch.Insert("Purpose", RowOfProduct.Purpose);
		If Not RowOfProduct.DifferentSeriesAccounting Then
			ProductsSearch.Insert("Series", RowOfProduct.Series);
		EndIf;
		ProductsSearch.Insert("Canceled", False);
		ProductLines_2 = Object.ReturnedGoods.FindRows(ProductsSearch);
		
		If ProductLines_2.Count() = 0 Then
			CurrentRow = Object.ReturnedGoods.Add();
			FillPropertyValues(CurrentRow, RowOfProduct);
			CurrentRow.Warehouse = Object.Warehouse;
		ElsIf ProductLines_2.Count() = 1 Then
			CurrentRow = ProductLines_2[0];
		ElsIf ProductLines_2.Count() > 1 Then
			For Each RowToDelete In ProductLines_2 Do
				Object.ReturnedGoods.Delete(RowToDelete);
			EndDo;
			CurrentRow = Object.ReturnedGoods.Add();
			FillPropertyValues(CurrentRow, RowOfProduct);
			CurrentRow.Warehouse = Object.Warehouse;
		EndIf;
		
		CurrentRow.Count = RowOfProduct.QuantityIsSelected;
		RowsArray.Add(CurrentRow);
		
	EndDo;
	
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		RowsArray,
		StructureOfActions,
		Object.ReturnedGoods);
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	
	StructureOfPriceCalculationActions = New Structure;
	StructureOfPriceCalculationActions.Insert("RecalculateAmount");
	StructureOfPriceCalculationActions.Insert("RecalculateVATAmount",  StructureOfRecalculationOfAmount);
	StructureOfPriceCalculationActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	
	EnterprisePricesFillingServer.FillInPrices(Object.ReturnedGoods,
												RowsArray,
												PriceFillingParameters,
												StructureOfPriceCalculationActions);
	
	FillingInContactDetailsAfterFillingInSelectionForm(CachedValues);
	
EndProcedure

&AtServer
Function PlaceGoodsInStorageForSelectionOfTransferredGoods()
	
	FilterParameters = New Structure("Canceled", False);
	
	Columns = "LineNumber, Products, Characteristic, Purpose, Series, BatchesIndicationStatus, Count";
	Address = PutToTempStorage(Object.ReturnedGoods.Unload(FilterParameters, Columns), UUID);
	
	Return Address;
	
EndFunction

&AtServer
Procedure FillingInContactDetailsAfterFillingInSelectionForm(CachedValues)
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInFeatureAttribute", New Structure("Products", "ItemVariantsAreUsed"));
	StructureOfActions.Insert("FillInSalesOptionAttribute", New Structure("Products", "SaleRegistrationOption"));
	StructureOfActions.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));
	StructureOfActions.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
	
	ProductsServer.FillInServiceDetailsForProductInCollection(Object.SubstituteGoods, StructureOfActions);
	StructureOfActions.FillInFeatureAttribute.Insert("ProductsRecordingAsReceived", "ItemVariantsAreUsedRecordingAsReceived");
	StructureOfActions.Delete("FillInSalesOptionAttribute");
	ProductsServer.FillInServiceDetailsForProductInCollection(Object.ReturnedGoods, StructureOfActions);
	
	SetsServer.FillInServiceDetails(ThisForm, "ReturnedGoods");
	SetsServer.FillInServiceDetails(ThisForm, "SubstituteGoods");
	
	UpdateDuplicateDependentDetails();
	ProductsServer.FillInStatusesForSpecifyingSeries(Object,SeriesSpecificationParameters.Returned_);
	
	CalculateTotalsOfRefundRequest(ThisForm);
	UpdateInformationOnImplementations();
	ReusablePackageServer.UpdateFillingStateOfMultiTurnContainer(Object.ReusablePackageFillingStatus);
	
	StructureOfActions = New Structure();
	AddCollateralActionsOnServer(StructureOfActions,
		"SupplyOption,WarehouseIsRequired,DateOfShipmentRequired_");
	BatchProcessingOfTablePartServer.TreatTS(Object.SubstituteGoods, StructureOfActions, CachedValues);
	UpdateColumnAvailableServer();

EndProcedure

#EndRegion

#Region BarcodesAndTradeEquipment

&AtClient
Procedure ProcessBarcodes(BarcodeData_5, TabularSectionName = "")
	
	ClearMessages();
	
	If Not BarcodingOfItemsClient.BarcodesAreValid(BarcodeData_5) Then
		Return;
	EndIf;
	
	StructureOfActionsWithAddedStrings = New Structure;
	StructureOfActionsWithAddedStrings.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
	StructureOfActionsWithAddedStrings.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));
	StructureOfActionsWithAddedStrings.Insert("FillInVATRateByPriceType", BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRateByPriceType(Object));
	StructureOfActionsWithAddedStrings.Insert("FillInVATRateForReturnableContainers", Object.ToReturnReusablePackage);
	StructureOfActionsWithAddedStrings.Insert("FillInNoReturnContainerAttribute", Object.ToReturnReusablePackage);
	StructureOfActionsWithAddedStrings.Insert("FillInCanceledWithoutReturnableContainerAttribute", Object.ToReturnReusablePackage);
	StructureOfActionsWithAddedStrings.Insert("CheckFillWarehouse",
		BatchProcessingOfTablePartClientServer.GetWarehouseFillStructureInTSLine(Object, WarehouseGroup_));
	
	If (ToUseTermsOfSales
			And ValueIsFilled(Object.Terms))
		Or (TabularSectionName = "SubstituteGoods"
			And Not ToUseTermsOfSales
			And UsePriceManagementSystem25) Then
		
		StructureOfActionsWithAddedStrings.Insert("FillIn_TermsOfSales",
			BatchProcessingOfTablePartClientServer.GetStructureForFillingInSalesConditionsInTSLine(Object));
		
	Else
		StructureOfActionsWithAddedStrings.Insert("FillInSalePrice",
			BatchProcessingOfTablePartClientServer.ParametersForFillingInPriceInTSLine(Object));
	EndIf;
	
	StructureOfActionsWithModifiedStrings = New Structure;
	
	If TabularSectionName = "SubstituteGoods" Then
		StructureOfActionsWithAddedStrings.Insert("FillInSubdivisionInTSLine",
			New Structure("Department", Object.Department));
		StructureOfActionsWithAddedStrings.Insert("FillInContent",
			BatchProcessingOfTablePartClientServer.GetStructureOfFillingInServiceContentInTSLine(Object, False));
		StructureOfActionsWithAddedStrings.Insert("FillInSalesOptionAttribute",
			New Structure("Products", "SaleRegistrationOption"));
		
		ParametersOfIndicationForProcessing	= SeriesSpecificationParameters.Substitutes_;
		CheckSeriesCalculateStatus	= New Structure("Warehouse, SeriesSpecificationParameters",
															Object.Warehouse, ParametersOfIndicationForProcessing);
		
		AddReplacementProductsToActionStructureWhenChangingNumberOfPackages(StructureOfActionsWithAddedStrings, Object);
		AddReplacementProductsToActionStructureWhenChangingNumberOfPackages(StructureOfActionsWithModifiedStrings, Object);
		
		ParametersForFillingInVATRate = BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRate(Object, True);
		
		If Object.NotShipInInstallments
			And ValueIsFilled(Object.DateOfShipment) Then
			
			ParametersForFillingInVATRate.Date = Object.DateOfShipment;
			
		EndIf;
	Else
		ParametersOfIndicationForProcessing	= SeriesSpecificationParameters.Returned_;
		CheckSeriesCalculateStatus	= New Structure("Warehouse, SeriesSpecificationParameters",
															Object.Warehouse, ParametersOfIndicationForProcessing);
		
		AddToActionStructureWhenChangingNumberOfPackagesReturnItems(StructureOfActionsWithAddedStrings, Object);
		AddToActionStructureWhenChangingNumberOfPackagesReturnItems(StructureOfActionsWithModifiedStrings, Object);
		
		ParametersForFillingInVATRate = BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRate(Object);
		StructureOfActionsWithAddedStrings.Insert("FillInCheckQualityDateOfQualityConfirmation",
			CacheQualityControl);
		
	EndIf;
	
	StructureOfActionsWithAddedStrings.Insert("FillInVATRate", ParametersForFillingInVATRate);
	StructureOfActionsWithAddedStrings.Insert("CheckSeriesCalculateStatus", CheckSeriesCalculateStatus);
	
	StructureOfActions = BarcodingOfItemsClient.BarcodeProcessingParameters();
	StructureOfActions.Barcodes                              = BarcodeData_5;
	StructureOfActions.StructureOfActionsWithAddedStrings = StructureOfActionsWithAddedStrings;
	StructureOfActions.StructureOfActionsWithModifiedStrings  = StructureOfActionsWithModifiedStrings;
	StructureOfActions.TSName                                  = TabularSectionName;
	StructureOfActions.SeriesSpecificationParameters                 = ParametersOfIndicationForProcessing;
	StructureOfActions.CalculateSets                     = True;
	
	If TabularSectionName = "SubstituteGoods" Then
		If Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.ReturnFromCommissionAgent")
			Or Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.ReturnFromCustodian") Then
			
			StructureOfActions.GoodsOnly = True;
			
		EndIf;
	Else
		StructureOfActions.GoodsOnly = True;
	EndIf;
	
	ProcessBarcodesServer(StructureOfActions, CachedValues, TabularSectionName);
	
	If TabularSectionName = "SubstituteGoods" Then
		ProvisionInDocumentsClientServer.FillInServiceDetails(Object.SubstituteGoods,
			DateOfShipmentRequired_, WarehouseIsRequired);
	EndIf;
	
	BarcodingOfItemsClient.ProcessUnknownBarcodes(StructureOfActions, CachedValues, ThisObject);
	
	CalculateTotalsOfRefundRequest(ThisObject);
	DiscountsMarkupsFillingClient.ResetDiscountsCalculatedFlag(ThisObject);
	
	If BarcodingOfItemsClient.YouNeedToOpenFormForSpecifyingSeriesAfterProcessingBarcodes(StructureOfActions) Then
		CurDataId = StructureOfActions.ArrayOfRowsWithSeries_[0];
		
		If TabularSectionName = "SubstituteGoods" Then
			AttachIdleHandler("OpenSelectionOfSeriesWhenScanningBarcodeReplacementProducts", 0.1, True);
		Else
			AttachIdleHandler("OpenSelectionOfSeriesWhenScanningBarcodeOfProductReturned", 0.1, True);
		EndIf;
	EndIf;
	
	If StructureOfActions.CurrentRow <> Undefined Then
		FormTable = Items[TabularSectionName]; // FormTable
		
		FormTable.CurrentRow = StructureOfActions.CurrentRow;
	EndIf;
	
EndProcedure

&AtServer
Procedure ProcessBarcodesServer(StructureOfActionParameters, CachedValues, TabularSectionName)
	
	If TabularSectionName = "SubstituteGoods" Then
		AddCollateralActionsOnServer(
			StructureOfActionParameters.StructureOfActionsWithAddedStrings,
			"SupplyOption,WarehouseIsRequired,DateOfShipmentRequired_");
	EndIf;
	
	BarcodingOfItemsServer.ProcessBarcodes(ThisObject, Object, StructureOfActionParameters,CachedValues);
	
	If TabularSectionName = "SubstituteGoods" Then
		ProvisionInDocumentsClientServer.RemoveCollateralActions(StructureOfActionParameters.StructureOfActionsWithAddedStrings);
		UpdateColumnAvailableServer();
	EndIf;
	
EndProcedure

#EndRegion

#Region SetOfSeries

&AtServer
Function ParametersOfSeriesIndicationForm(CurDataId,TSName)
	
	Return ProductsServer.ParametersOfSeriesIndicationForm(Object, SeriesSpecificationParameters[TSName], CurDataId, ThisForm);
	
EndFunction

&AtClient
Procedure OpenSelectionOfSeriesWhenScanningBarcodeOfProductReturned()
	
	If CurDataId = Undefined Then
		Return;
	EndIf;
	
	CurrentData = Object.ReturnedGoods.FindByID(CurDataId);
	OpenSelectionOfSeries("Returned_",,CurrentData);
	
EndProcedure

&AtClient
Procedure OpenSelectionOfSeriesWhenScanningBarcodeReplacementProducts()
	If CurDataId = Undefined Then
		Return;
	EndIf;
	
	CurrentData = Object.SubstituteGoods.FindByID(CurDataId);
	OpenSelectionOfSeries("Substitutes_",,CurrentData);
EndProcedure

&AtClient
Procedure OpenSelectionOfSeries(TSName, Text = "", CurrentData = Undefined)
	
	If TSName = "Substitutes_" Then
		FormItemName = "SubstituteGoods";
	Else
		FormItemName = "ReturnedGoods";
	EndIf;
	
	If FormItemName = "SubstituteGoods" Then
		
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
		
		Return;
		
	EndIf;
	
	If ProductsClient.YouNeedServerCallToSpecifySeries(ThisForm,SeriesSpecificationParameters[TSName],Text, CurrentData) Then
		
		If CurrentData = Undefined Then
			CurDataId = Items[FormItemName].CurrentData.GetID();
		Else
			CurDataId = CurrentData.GetID();
		EndIf;	
		
		ParametersOfSeriesIndicationForm = ParametersOfSeriesIndicationForm(CurDataId, TSName);
		
		OpenForm(ParametersOfSeriesIndicationForm.FormName,ParametersOfSeriesIndicationForm,ThisForm,,,, New CallbackDescription("OpenSelectionOfSeriesCompletion", ThisObject, New Structure("TSName, ParametersOfSeriesIndicationForm", TSName, ParametersOfSeriesIndicationForm)), FormWindowOpeningMode.LockOwnerWindow);
		
	EndIf;
EndProcedure

&AtClient
Procedure OpenSelectionOfSeriesCompletion(Result, AdditionalParameters) Export
    
    TSName = AdditionalParameters.TSName;
    ParametersOfSeriesIndicationForm = AdditionalParameters.ParametersOfSeriesIndicationForm;
    
    
    ReturnValue_1 = Result;
    
    If ReturnValue_1 <> Undefined Then
        ProcessSeriesIndication_Server(ParametersOfSeriesIndicationForm,TSName);
    EndIf;

EndProcedure

&AtServer
Procedure SetVisibilityOfSeriesElements()
	
	Items.ReturnedGoodsBatchesIndicationStatus.Visible = SeriesSpecificationParameters.Returned_.UseItemsBatch;
	Items.ReturnItemsSpecifyTheSeries.Visible        = SeriesSpecificationParameters.Returned_.UseItemsBatch;
	
	Items.SubstituteGoodsSeries.Visible = SeriesSpecificationParameters.Substitutes_.UseItemsBatch;
	
EndProcedure

&AtServer
Procedure ProcessSeriesIndication_Server(ParametersOfSeriesIndicationForm, TSName)
	
	StructureOfActions = New Structure;
	If TSName = "Returned_" Then
		StructureOfActions.Insert("UpdateNumberOfProductsWhenRegistering", True);
		AddToActionStructureWhenChangingNumberOfPackagesReturnItems(StructureOfActions, Object);
		StructureOfActions.Insert("FillInCheckQualityDateOfQualityConfirmation", CacheQualityControl);
	EndIf;
	
	ProductsServer.ProcessSeriesIndication_(Object,SeriesSpecificationParameters[TSName],ParametersOfSeriesIndicationForm,StructureOfActions);
	
EndProcedure

&AtServer
Procedure FillInStatusesForSpecifyingSeriesServer(TSName)
	
	ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters[TSName]);
	
EndProcedure

&AtServer
Procedure FillInStatusesOfSpecifyingSeriesWhenEditingLineTS(IDCurrentRow, CachedValues, TSName)
	
	ProductsServer.FillInStatusesOfSpecifyingSeriesWhenEditingLineTS(Object,
		SeriesSpecificationParameters[TSName], IDCurrentRow, CachedValues);
	
EndProcedure

#EndRegion

#Region WorkingWithClipboard

&AtServer
Procedure CopyLinesOnServer(TSName)
	
	ProcessingOfTabularForms.CopyRowsToClipboard(Object[TSName], Items[TSName].SelectedRows);
	
EndProcedure

&AtServer
Procedure GetReplacementLinesFromClipboard()
	
	If Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.ReturnFromCommissionAgent")
		Or Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.ReturnFromCustodian") Then
		FilterParameters = New Map;
		FilterParameters.Insert("Products.ItemsType", ProductsClientServer.SelectionByProductMultiTurnContainer());
	Else
		FilterParameters = Undefined;
	EndIf;
	
	Columns = "Products,Characteristic,Package,NumberOfPackages,Price,DateOfShipment,
		|ProductsInSet,ItemVariantOfSet,PercentRateOfManualDiscount,ManualDiscount,Warehouse";
	
	TableOfGoods = ProcessingOfTabularForms.RowsFromClipboard(FilterParameters, Columns);
	
	If Not ValueIsFilled(TableOfGoods) Then
		Return;
	EndIf;
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
	StructureOfActions.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));
	StructureOfActions.Insert("FillInNoReturnContainerAttribute", Object.ToReturnReusablePackage);
	StructureOfActions.Insert("FillInCanceledWithoutReturnableContainerAttribute", Object.ToReturnReusablePackage);
	
	ParametersForFillingInVATRate = BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRate(Object, True);
	If Object.NotShipInInstallments And ValueIsFilled(Object.DateOfShipment) Then
		ParametersForFillingInVATRate.Date = Object.DateOfShipment;
	EndIf;
	
	StructureOfActions.Insert("FillInVATRate", ParametersForFillingInVATRate);
	StructureOfActions.Insert("FillInVATRateForReturnableContainers", Object.ToReturnReusablePackage);
	StructureOfActions.Insert("FillInContent", BatchProcessingOfTablePartClientServer.GetStructureOfFillingInServiceContentInTSLine(Object, False));
	StructureOfActions.Insert("CheckFillWarehouse",
		BatchProcessingOfTablePartClientServer.GetWarehouseFillStructureInTSLine(Object, WarehouseGroup_));
	
	AddCollateralActionsOnServer(StructureOfActions,
		"SupplyOption,WarehouseIsRequired,DateOfShipmentRequired_");
	AddReplacementProductsToActionStructureWhenChangingNumberOfPackages(StructureOfActions, Object);
	If TableOfGoods.Columns.Find("ManualDiscount") <> Undefined Then
		StructureOfActions.RecalculateAmountTakingIntoAccountManualDiscount.Insert("RecalculateAmountOfManualDiscount_", False);
	EndIf;
	
	RowsToProcess = New Array;
		
	For Each RowOfProduct In TableOfGoods Do
		
		CurrentRow = Object.SubstituteGoods.Add();
		FillPropertyValues(CurrentRow, RowOfProduct);
		
		If Object.NotShipInInstallments Then
			CurrentRow.DateOfShipment = Object.DateOfShipment;
		EndIf;
		
		RowsToProcess.Add(CurrentRow);
		
	EndDo;
	
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		RowsToProcess,
		StructureOfActions,
		Object.SubstituteGoods);
	
	CalculateTotalsOfRefundRequest(ThisForm);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInFeatureAttribute",	New Structure("Products", "ItemVariantsAreUsed"));
	StructureOfActions.Insert("FillInSalesOptionAttribute",	New Structure("Products", "SaleRegistrationOption"));

	ProductsServer.FillInServiceDetailsForProductInCollection(Object.SubstituteGoods, StructureOfActions);
	
	SetsServer.FillInServiceDetails(ThisForm, "SubstituteGoods");
	
	ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters.Substitutes_);
	ReusablePackageServer.UpdateFillingStateOfMultiTurnContainer(Object.ReusablePackageFillingStatus);
	
	OnChangingWarehouseInTablePartReplacingGoodsServer();
	
	UpdateColumnAvailableServer();
	
EndProcedure

&AtServer
Procedure GetReturnedLinesFromClipboard()
	
	FilterParameters = New Map;
	FilterParameters.Insert("Products.ItemsType", ProductsClientServer.SelectionByProductMultiTurnContainer());
	
	Columns = "Products,Characteristic,Package,NumberOfPackages,Price,DateOfReceipt,DocumentSalesOfGoodsAndServices,Damage,
		|ProductsInSet,ItemVariantOfSet,ProductsRecordingAsReceived,CharacteristicRecordingAsReceived,Warehouse";
	
	TableOfGoods = ProcessingOfTabularForms.RowsFromClipboard(FilterParameters, Columns);
	
	If Not ValueIsFilled(TableOfGoods) Then
		Return;
	EndIf;
	
	SetsServer.DeleteRowsOfSetsAccordingToSelection(TableOfGoods, FilterParameters["Products.ItemsType"]);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
	StructureOfActions.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));
	StructureOfActions.Insert("FillInCanceledWithoutReturnableContainerAttribute", Object.ToReturnReusablePackage);
	
	ParametersForFillingInVATRate = BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRate(Object, True);
	If ValueIsFilled(Object.DocumentSalesOfGoodsAndServices) Then
		SaleDate = Common.ObjectAttributeValue(Object.DocumentSalesOfGoodsAndServices, "Date");
		ParametersForFillingInVATRate.Date = SaleDate;
	EndIf;
	
	StructureOfActions.Insert("FillInVATRate", ParametersForFillingInVATRate);
	StructureOfActions.Insert("FillInVATRateForReturnableContainers", Object.ToReturnReusablePackage);
	StructureOfActions.Insert("FillInNoReturnContainerAttribute", Object.ToReturnReusablePackage);
	StructureOfActions.Insert("CheckFillWarehouse",
		BatchProcessingOfTablePartClientServer.GetWarehouseFillStructureInTSLine(Object, WarehouseGroup_));
	AddToActionStructureWhenChangingNumberOfPackagesReturnItems(StructureOfActions,Object);
	StructureOfActions.Insert("FillInCheckQualityDateOfQualityConfirmation", CacheQualityControl);
	
	RowsToProcess = New Array;
		
	For Each RowOfProduct In TableOfGoods Do
		
		CurrentRow = Object.ReturnedGoods.Add();
		FillPropertyValues(CurrentRow, RowOfProduct);
		
		If Object.OneDateReceipt Then
			CurrentRow.DateOfReceipt = Object.DateOfReceipt;
		EndIf;
		
		RowsToProcess.Add(CurrentRow);
		
	EndDo;
	
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		RowsToProcess,
		StructureOfActions,
		Object.ReturnedGoods);
	
	StructureCharacteristicsOfProducts = New Structure;
	StructureCharacteristicsOfProducts.Insert("FillInFeatureAttribute",	New Structure("Products", "ItemVariantsAreUsed"));
	
	ProductsServer.FillInServiceDetailsForProductInCollection(Object.ReturnedGoods, StructureCharacteristicsOfProducts);
	
	SetsServer.FillInServiceDetails(ThisForm, "ReturnedGoods");
	
	ProductsServer.FillInStatusesForSpecifyingSeries(Object,SeriesSpecificationParameters.Returned_);
	ReusablePackageServer.UpdateFillingStateOfMultiTurnContainer(Object.ReusablePackageFillingStatus);
	
	OnChangingWarehouseInTablePartOfReturnedGoodsServer();
	
	CalculateTotalsOfRefundRequest(ThisForm);
	
EndProcedure

&AtServer
Procedure SetAvailabilityOfClipboardCommands()
	
	ItemArray = New Array();
	ItemArray.Add("InsertSubstituteLines");
	ItemArray.Add("ContextMenuInsertReplacementLines");
	ItemArray.Add("ToInsertTheReturnedString");
	ItemArray.Add("ContextMenuInsertReturnedRows");
	
	TMCommonUseClientServer.SetPropertyOfFormElements(Items, ItemArray, "Enabled",
		ProcessingOfTabularForms.ThereAreLinesInClipboard());
	
EndProcedure

&AtClient
Procedure SetAvailabilityOfClipboardCommandsOnClient()
	
	ItemArray = New Array();
	ItemArray.Add("InsertSubstituteLines");
	ItemArray.Add("ContextMenuInsertReplacementLines");
	ItemArray.Add("ToInsertTheReturnedString");
	ItemArray.Add("ContextMenuInsertReturnedRows");
	
	TMCommonUseClientServer.SetPropertyOfFormElements(Items, ItemArray, "Enabled", True);
	
EndProcedure

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

&AtClient
Procedure Attachable_CloseForm()
	
	If IsOpen() Then
		Close();
	EndIf;
	
EndProcedure

&AtServer
Procedure OnReadCreateAtServer()
	
	DocumentCurrency = Object.Currency;
	ContractBusinessTransaction = SelfServiceClientServer.ContractBusinessTransaction(Object.BusinessOperation);
	BusinessTransactionFromAgreement = SelfServiceClientServer.BusinessTransactionFromAgreement(Object.BusinessOperation);
	
	ToUseTermsOfSales  = GetFunctionalOption("ToUseTermsOfSales");
	UseSimplifiedPaymentScheme = GetFunctionalOption("UseSimplifiedPaymentSchemeInSales");
	UsePaymentSchedules         = GetFunctionalOption("UsePaymentSchedules");
	UseLinesOfBusiness = GetFunctionalOption("UseIncomeAccountingByLinesOfBusiness");
	UseShipmentByRowsInSalesOrder = GetFunctionalOption("UseShipmentByRowsInSalesOrder")
		And Not Object.ThisIsOrderAsInvoice;
	
	SetAvailabilityOfItemsByStatusServer();
	ConfigureElementsByOperationServer();
	
	ResponsiblePersonsServer.FillInManagerSelectionList_(Items.Manager, Object);
	
	If Not ToUseTermsOfSales Then
		PriceTypeSelectionParameters = SettingsValueCached.ParametersForSelectingDefaultPriceType();
	
		PriceTypeSelectionParameters.PriceIncludesVAT        = Object.PriceIncludesVAT;
		PriceTypeSelectionParameters.UseWhileSellingToCustomers = True;
		PriceTypeSelectionParameters.Status                 = Enums.StatusesOfPriceTypeValidity.Valid;
		
		DefaultPriceType = SettingsValueCached.DefaultPriceType(PriceTypeSelectionParameters);
	EndIf;
	
	WarehouseGroup_ = ItIsGroupOfWarehousesAndWarehousesUsedByWHForSale(Object.Warehouse);
	Warehouse = Object.Warehouse;
	
	SetParametersForSelectingProductsWarehouse();
	
	SetVisibilityOfItemsAcrossMultipleWarehouses();
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInFeatureAttribute", New Structure("Products", "ItemVariantsAreUsed"));
	StructureOfActions.Insert("FillInSalesOptionAttribute", New Structure("Products", "SaleRegistrationOption"));
	StructureOfActions.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
	StructureOfActions.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));
	
	ProductsServer.FillInServiceDetailsForProductInCollection(Object.SubstituteGoods, StructureOfActions);
	StructureOfActions.FillInFeatureAttribute.Insert("ProductsRecordingAsReceived", "ItemVariantsAreUsedRecordingAsReceived");
	StructureOfActions.Delete("FillInSalesOptionAttribute");
	StructureOfActions.Delete("FillInArticleAttribute");
	SeriesSpecificationParameters = New FixedStructure(ProductsServer.SeriesSpecificationParameters(Object, Documents.RequestForReturnOfGoodsFromCustomer));
	SetVisibilityOfSeriesElements();
	StructureOfActions.Insert("FillInArticleAttribute", New Structure("Products, ProductsRecordingAsReceived", "SKU", "SKURegistration"));
	ProductsServer.FillInServiceDetailsForProductInCollection(Object.ReturnedGoods, StructureOfActions);
	
	SetsServer.FillInServiceDetails(ThisForm, "ReturnedGoods");
	SetsServer.FillInServiceDetails(ThisForm, "SubstituteGoods");
	FillInFormDetailsFromCashRegisterReceipt(Object.CashRegisterReceipt, New Structure("CashReceiptPriceType", "PriceKind"));
	
	UpdateDuplicateDependentDetails();
	
	BackgroundTaskData = GoodsDelivery.WhenReadingCreatingOrdersOnServer(Items, Object,,,,True);
	
	CalculateTotalsOfRefundRequest(ThisForm);
	RefreshStatusServer();
	CustomizeFormElements();
	SetContractVisibility();
	UpdateInformationOnImplementations();
	FillInShippingDateSelectionList();
	FillInSalesVATTaxation();
	UpdateTextDocumentsBasedOn();
	
	EstablishVisibilityOfCompensationMethods();
	SetVisibilityOfShipmentBanToPartner();
	SetSoftwareVisibility();
	SetVisibilityOfFillCommands();
	
	SetPrivilegedMode(True);
	SecurityOptionAndFlagSeparately = SalesServer.ProvisionOptionAndFlagAreSeparateByDefault(Object.Terms, Object.Status, , Not Object.ThisIsOrderAsInvoice);
	
	ProcessingOfTabularForms.InitializeRowCache(Items.SubstituteGoods);
	ProcessingOfTabularForms.InitializeRowCache(Items.ReturnedGoods);
	LinesOfBusinessServer.OnReadCreateAtServer(ThisObject);
	
	OnChangingWarehouseInTablePartOfReturnedGoodsServer();
	OnChangingWarehouseInTablePartReplacingGoodsServer();
	
	FillInServiceDetailsOfDocumentForm();
	CacheQualityControl = QualityControl.DataCacheOfMechanism(Object);
	
EndProcedure

&AtClientAtServerNoContext
Procedure CalculateTotalsOfRefundRequest(Form)
	
	CollectionOfReturnedProducts = Form.Object.ReturnedGoods;
	
	Form.AmountOfNonRefundableGoods = ?(Form.Object.PackageDepositIsRequired,
		CollectionOfReturnedProducts.Total("VATAmount"),
		CollectionOfReturnedProducts.Total("VATAmountWithoutReusablePackages") - CollectionOfReturnedProducts.Total("VATAmountCanceledWithoutReusablePackages"));
	Form.AmountOfReturnedItems = ?(Form.Object.PackageDepositIsRequired,
		CollectionOfReturnedProducts.Total("AmountIncludingVAT"),
		CollectionOfReturnedProducts.Total("AmountIncludingVATWithoutReusablePackages") - CollectionOfReturnedProducts.Total("AmountIncludingVATCanceledWithoutReusablePackages"));
	Form.TheAmountOfTheCancelledGoodsReturned = CollectionOfReturnedProducts.Total("AmountIncludingVATCanceledWithoutReusablePackages");
	
	If Form.Object.CompensationMethod = PredefinedValue("Enum.CompensationMethodsForReturnsOfGoods.ToSubstituteGoods") Then
		
		CollectionOfReplacementProducts = Form.Object.SubstituteGoods;
		
		Form.AmountOfNDSOfSubstituteGoods = ?(Form.Object.PackageDepositIsRequired,
			CollectionOfReplacementProducts.Total("VATAmount") - CollectionOfReplacementProducts.Total("VATAmountCanceled"),
			CollectionOfReplacementProducts.Total("VATAmountWithoutReusablePackages") - CollectionOfReplacementProducts.Total("VATAmountCanceledWithoutReusablePackages"));
		Form.AmountOfReplacementProducts = ?(Form.Object.PackageDepositIsRequired,
					CollectionOfReplacementProducts.Total("AmountIncludingVAT") - CollectionOfReplacementProducts.Total("AmountIncludingVATCanceled"),
					CollectionOfReplacementProducts.Total("AmountIncludingVATWithoutReusablePackages") - CollectionOfReplacementProducts.Total("AmountIncludingVATCanceledWithoutReusablePackages"));
		Form.PackageDepositValue = ?(Form.Object.PackageDepositIsRequired,(CollectionOfReplacementProducts.Total("AmountIncludingVAT") - CollectionOfReplacementProducts.Total("AmountIncludingVATCanceled"))
			- (CollectionOfReplacementProducts.Total("AmountIncludingVATWithoutReusablePackages") - CollectionOfReplacementProducts.Total("AmountIncludingVATCanceledWithoutReusablePackages")),0);
		Form.TheAmountOfTheCancelledSubstituteGoods = ?(Form.Object.PackageDepositIsRequired,
			CollectionOfReplacementProducts.Total("AmountIncludingVATCanceled"),
			CollectionOfReplacementProducts.Total("AmountIncludingVATCanceledWithoutReusablePackages"));
		AutoDiscountAmount = ?(Form.Object.PackageDepositIsRequired,
			CollectionOfReplacementProducts.Total("DiscountMarkupAmount") - CollectionOfReplacementProducts.Total("DiscountMarkupAmountCanceled"),
			CollectionOfReplacementProducts.Total("DiscountMarkupAmountWithoutReusablePackages") - CollectionOfReplacementProducts.Total("DiscountMarkupAmountCanceledWithoutReusablePackages"));
		ManualDiscount = ?(Form.Object.PackageDepositIsRequired,
			CollectionOfReplacementProducts.Total("ManualDiscount") - CollectionOfReplacementProducts.Total("ManualDiscountCanceled"),
			CollectionOfReplacementProducts.Total("ManualDiscountWithoutReusablePackages") - CollectionOfReplacementProducts.Total("ManualDiscountCanceledWithoutReusablePackages"));
		AmountAmountOfBonusPointsToBeDebitedInCurrency = ?(Form.Object.PackageDepositIsRequired,
			CollectionOfReplacementProducts.Total("AmountOfBonusPointsToDeductionInCurrency") - CollectionOfReplacementProducts.Total("AmountOfBonusPointsToDeductionInCurrencyCanceled"),
			CollectionOfReplacementProducts.Total("AmountOfBonusPointsToDeductionInCurrencyWithoutReusablePackages") - CollectionOfReplacementProducts.Total("AmountOfBonusPointsToDeductionInCurrencyCanceledWithoutReusablePackages"));
		Form.DiscountAmount = AutoDiscountAmount + ManualDiscount + AmountAmountOfBonusPointsToBeDebitedInCurrency;
		
		AmountOrdered = ?(Form.Object.PackageDepositIsRequired,
			CollectionOfReplacementProducts.Total("Sum") - CollectionOfReplacementProducts.Total("SumCanceled"),
			CollectionOfReplacementProducts.Total("SumWithoutReusablePackages") - CollectionOfReplacementProducts.Total("SumCanceledWithoutReusablePackages"));
				
		If CollectionOfReplacementProducts.Count() > 0 And AmountOrdered = 0 Then
			Form.AllLinesAreCanceled = True;
		Else
			Form.AllLinesAreCanceled = False;
		EndIf;
		
	EndIf;
	
	If CollectionOfReturnedProducts.Total("AmountIncludingVATCanceledWithoutReusablePackages") = CollectionOfReturnedProducts.Total("AmountIncludingVAT") Then
		Form.AllReturnLinesAreCanceled = True;
	Else
		Form.AllReturnLinesAreCanceled = False;
	EndIf;
	
	DisplayTotalAmountOfVAT = VATAccountingERPClientServer.DisplayNDSInResultsOfSalesDocument(Form.Object.VATTaxation);

	If DisplayTotalAmountOfVAT Then
		Form.Items.PageGroupTotalReturnedItems.CurrentPage = Form.Items.PageTotalChasozvonyaProducts;
		Form.Items.TheGroupPageIsJustTheReplacementItems.CurrentPage   = Form.Items.PageTotalShstatexeProducts;
	Else
		Form.Items.PageGroupTotalReturnedItems.CurrentPage = Form.Items.PageWithoutNasosnayaProducts;
		Form.Items.TheGroupPageIsJustTheReplacementItems.CurrentPage   = Form.Items.PageTotalNonNDSSubstituteProducts;
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Function DependentDetailsReplacingGoods()
	
	Return New Structure(
		"WithoutReusablePackages,CanceledWithoutReusablePackages,Canceled",
		"Sum,VATAmount,AmountIncludingVAT,DiscountMarkupAmount,ManualDiscount,AmountOfBonusPointsToDeductionInCurrency",
		"Sum,VATAmount,AmountIncludingVAT,DiscountMarkupAmount,ManualDiscount,AmountOfBonusPointsToDeductionInCurrency",
		"Sum,VATAmount,AmountIncludingVAT,DiscountMarkupAmount,ManualDiscount,AmountOfBonusPointsToDeductionInCurrency");
	
EndFunction

&AtClientAtServerNoContext
Function DependentDetailsThatReplaceProductsWithLine()
	
	Return "SumWithoutReusablePackages, VATAmountWithoutReusablePackages, AmountIncludingVATWithoutReusablePackages,
		|DiscountMarkupAmountWithoutReusablePackages, ManualDiscountWithoutReusablePackages,
		|AmountOfBonusPointsToDeductionInCurrencyWithoutReusablePackages,
		|SumCanceledWithoutReusablePackages, VATAmountCanceledWithoutReusablePackages, AmountIncludingVATCanceledWithoutReusablePackages,
		|DiscountMarkupAmountCanceledWithoutReusablePackages, ManualDiscountCanceledWithoutReusablePackages,
		|AmountOfBonusPointsToDeductionInCurrencyCanceledWithoutReusablePackages,
		|SumCanceled, VATAmountCanceled, AmountIncludingVATCanceled,
		|DiscountMarkupAmountCanceled, ManualDiscountCanceled,
		|AmountOfBonusPointsToDeductionInCurrencyCanceled";
	
EndFunction

&AtClientAtServerNoContext
Function DependentDetailsReturnedGoods()
	
	Return New Structure(
		"WithoutReusablePackages,CanceledWithoutReusablePackages",
		"Sum,VATAmount,AmountIncludingVAT",
		"Sum,VATAmount,AmountIncludingVAT");
	
EndFunction

&AtClientAtServerNoContext
Procedure AddToActionStructureWhenChangingNumberOfPackagesReturnItems(StructureOfActions, Object)
	
	SelfServiceClientServer.AddReturnItemsToActionStructureWhenChangingNumberOfPackagesMain(StructureOfActions, Object);
	StructureOfActions.Insert("FillInDuplicateDependentDetails", DependentDetailsReturnedGoods());
	
EndProcedure

&AtClientAtServerNoContext
Procedure AddReplacementProductsToActionStructureWhenChangingNumberOfPackages(StructureOfActions, Object)
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	StructureOfActions.Insert("RecalculateNumberOfUnits");
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmount");
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountManualDiscount", New Structure("Clear", False));
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountAutomaticDiscount", New Structure("Clear", True));
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountDiscountWithBonusPoints");
	StructureOfActions.Insert("FillInDuplicateDependentDetails", DependentDetailsReplacingGoods());
	
EndProcedure

&AtServer
Procedure SetVisibilityOfAutomaticDiscounts()
	
	ThisIsRefundFromCommissionAgent = Object.BusinessOperation = Enums.BusinessTransactions.ReturnFromCommissionAgent;
	ThisIsReturnFromKeeper = Object.BusinessOperation = Enums.BusinessTransactions.ReturnFromCustodian;
	ThisIsRefundFromCommissionAgentOrCustodian = ThisIsRefundFromCommissionAgent Or ThisIsReturnFromKeeper;
	
	ItemVisibility = Not ThisIsRefundFromCommissionAgentOrCustodian And Not Object.FillInPricesOfSubstituteGoodsByReturned;
	FillInByAgreement = Not Object.FillInPricesOfSubstituteGoodsByReturned;
	
	Items.SubstituteProductsCalculateDiscountMarkups.Visible = ItemVisibility;
	Items.ReplacementProductsOpenInformationAboutDiscounts.Visible = ItemVisibility;
	Items.SubstituteGoodsAssignAutomaticDiscounts.Visible = ItemVisibility;
	Items.SubstituteGoodsPercentRateOfAutomaticDiscountMarkup.Visible = ItemVisibility;
	Items.SubstituteGoodsDiscountMarkupAmount.Visible = ItemVisibility;
	Items.SubstituteGoodsPercentRateOfManualDiscount.Visible = ItemVisibility;
	Items.SubstituteGoodsManualDiscount.Visible = ItemVisibility;
	Items.ReplacementProductsCancelManualDiscounts.Visible = ItemVisibility;
	Items.SubstituteProductsAssignAManualDiscount.Visible = ItemVisibility;
	Items.SubstituteGoodsSubstituteItemsAssignAManualDiscountToSelectedLines.Visible = ItemVisibility;
	Items.ContextMenuReplacementProductsOpenInformationAboutDiscounts.Visible = ItemVisibility;
	Items.ToReadLoyaltyCard.Visible = ItemVisibility;
	Items.LoyaltyCard.Visible = ItemVisibility;
	Items.SubstituteProductsFillInPricesOfSelectedRowsByTypeOfPrices.Visible = FillInByAgreement;
	Items.SubstituteGoodsFillInPricesByAgreement.Visible = FillInByAgreement;
	
	Items.DiscountAmount.Visible =
		ItemVisibility And Object.CompensationMethod = Enums.CompensationMethodsForReturnsOfGoods.ToSubstituteGoods;
	
	SetVisibilityOfPartnerField();
	
	If Object.FillInPricesOfSubstituteGoodsByReturned Then
		DiscountsMarkupsFillingServer.CancelDiscounts(Object, "SubstituteGoods", True, , True);
		UpdateDuplicateDependentDetails(True);
	EndIf;
	
EndProcedure

&AtServer
Procedure FillInDefaultContract()
	
	If Object.BusinessOperation <> Enums.BusinessTransactions.ReturnFromRetailCustomer Then
		
		If Object.ARAPObjectSettings = Enums.ARAPObjectSettings.ByCounterpartyContracts 
			And UseLinesOfBusiness Then
	
			Contract = SalesServer.GetDefaultContract(Object, 
																ContractBusinessTransaction, 
																Object.Currency, 
																Object.LineOfBusiness,
																ConsignmentSales25);
		Else
															
			Contract = SalesServer.GetDefaultContract(Object, 
																ContractBusinessTransaction, 
																Object.Currency,
																,
																ConsignmentSales25);
		EndIf;
		
		If Contract <> Object.Contract Then
			Object.Contract = Contract;
			ForeignCurrencyTransaction = Object.ForeignCurrencyTransaction;
			ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisObject, "Contract");
			If ForeignCurrencyTransaction <> Object.ForeignCurrencyTransaction Then
				Object.BankAccount = Catalogs.CompaniesBankAccounts.EmptyRef();
			EndIf;
			SalesServer.FillInBankAccountsUnderAgreement(Object.Contract, Object.BankAccount, Object.CounterpartyBankAccount);
		EndIf;
		
		UpdateCompensationMethod();
		CustomizeFormElements();
		RefreshStatusServer();
		
	EndIf;
	
EndProcedure

&AtServer
Procedure FillOperationSelectionList()
	
	If Not GetFormFunctionalOption("UseSalesCommission") Then
		
		ListItem = Items.BusinessOperation.ChoiceList.FindByValue(Enums.BusinessTransactions.ReturnFromCommissionAgent);
		If ListItem <> Undefined Then
			Items.BusinessOperation.ChoiceList.Delete(ListItem);
		EndIf;
		
	EndIf;
	
	If Not GetFormFunctionalOption("UseRetailSales") Then
		
		ListItem = Items.BusinessOperation.ChoiceList.FindByValue(Enums.BusinessTransactions.ReturnFromRetailCustomer);
		If ListItem <> Undefined Then
			Items.BusinessOperation.ChoiceList.Delete(ListItem);
		EndIf;
		
	EndIf;
	
	OnlyOperation = Items.BusinessOperation.ChoiceList.Count() = 1;
	TMCommonUseClientServer.SetFormItemProperty(
		Items,
		"BusinessOperation",
		"ReadOnly",
		OnlyOperation And ValueIsFilled(Object.BusinessOperation));
	
EndProcedure

&AtServer
Procedure SetVisibilityOfFillCommands()
	
	Items.ReturnedGoodsToPickUpTheGoodsInImplementations.Visible = False;
	Items.ReturnedGoodsFillInSalesAndPrices.Visible = False;
	Items.ReturnedGoodsFillInSalesAndPrices.Visible = False;
	
	If Object.BusinessOperation = Enums.BusinessTransactions.ReturnFromCustodian
		Or (Object.BusinessOperation = Enums.BusinessTransactions.ReturnFromCommissionAgent
			And ConsignmentSales25) Then
		
		Items.ReturnedGoodsToPickUpTheGoodsInImplementations.Visible = False;
		Items.ReturnedGoodsFillInSalesAndPrices.Visible = False;
		Items.ReturnedGoodsSelectTransferredGoods.Visible = True;
		
		If Not AccessRight("Read", Metadata.AccumulationRegisters.CompanyGoods) Then
			
			Items.ReturnedGoodsSelectTransferredGoods.Visible = False;
			
		EndIf;
	Else
		
		Items.ReturnedGoodsToPickUpTheGoodsInImplementations.Visible = True;
		Items.ReturnedGoodsFillInSalesAndPrices.Visible = True;
		Items.ReturnedGoodsSelectTransferredGoods.Visible = False;
		
		If Not AccessRight("Read", Metadata.Documents.CustomerInvoice) Or 
			Not AccessRight("Read", Metadata.Documents.CashRegisterReceipt) Or
			Not AccessRight("Read", Metadata.Documents.CashRegisterReceiptReturn) Or
			Not AccessRight("Read", Metadata.Documents.SaleAdjustment) Or
			Not AccessRight("Read", Metadata.Documents.ReturnOfGoodsFromCustomer) Then
			
			Items.ReturnedGoodsToPickUpTheGoodsInImplementations.Visible = False;
			Items.ReturnedGoodsFillInSalesAndPrices.Visible = False;
			
		EndIf;
	EndIf;

EndProcedure

&AtServer
Procedure SetAvailabilityOfItemsByStatusServer()
	
	ItemArray = New Array;
	
	// Header Controls
	ItemArray.Add("Date");
	ItemArray.Add("Terms");
	ItemArray.Add("Contract");
	ItemArray.Add("Currency");
	ItemArray.Add("PriceIncludesVAT");
	ItemArray.Add("VATTaxation");
	ItemArray.Add("Organization");
	ItemArray.Add("Partner");
	ItemArray.Add("Counterparty");
	ItemArray.Add("Warehouse");
	ItemArray.Add("RequestedDeliveryDate");
	ItemArray.Add("ApprovalDate");
	ItemArray.Add("NotShipInInstallments");
	ItemArray.Add("DateOfShipment");
	ItemArray.Add("BusinessOperation");
	ItemArray.Add("DocumentSalesOfGoodsAndServices");
	ItemArray.Add("LoyaltyCard");
	ItemArray.Add("OneDateReceipt");
	ItemArray.Add("DateOfReceipt");
	ItemArray.Add("CashRegisterReceipt");
	ItemArray.Add("ToReturnReusablePackage");
	ItemArray.Add("ReusablePackageReturnCycleLength");
	ItemArray.Add("PackageDepositIsRequired");
	ItemArray.Add("DepositForPackageIsRequired");
	ItemArray.Add("ReusablePackageReturn");
	ItemArray.Add("Department");
	ItemArray.Add("CompensationMethod");
	
	// Controls associated with the Returned Items table
	ItemArray.Add("ReturnedGoodsProducts");
	ItemArray.Add("ReturnedGoodsDamage");
	ItemArray.Add("ReturnedGoodsProductsRecordingAsReceived");
	ItemArray.Add("ReturnedGoodsCharacteristic");
	ItemArray.Add("ReturnedGoodsCharacteristicRecordingAsReceived");
	ItemArray.Add("ReturnedGoodsNumberOfPackages");
	ItemArray.Add("ReturnedGoodsPackage");
	ItemArray.Add("ReturnedGoodsPriceKind");
	ItemArray.Add("ReturnedGoodsPrice");
	ItemArray.Add("ReturnedGoodsVATRate");
	ItemArray.Add("ReturnedGoodsSum");
	
	// Controls associated with the Replacement Products table
	ItemArray.Add("SubstituteGoodsProducts");
	ItemArray.Add("SubstituteGoodsCharacteristic");
	ItemArray.Add("SubstituteGoodsNumberOfPackages");
	ItemArray.Add("SubstituteGoodsPackage");
	ItemArray.Add("SubstituteGoodsPriceKind");
	ItemArray.Add("SubstituteGoodsPrice");
	ItemArray.Add("SubstituteGoodsVATRate");
	ItemArray.Add("SubstituteGoodsPercentRateOfManualDiscount");
	ItemArray.Add("SubstituteGoodsManualDiscount");
	ItemArray.Add("SubstituteGoodsSum");
	ItemArray.Add("SubstituteGoodsVATAmount");
	ItemArray.Add("SubstituteGoodsContent");
	
	ItemArray.Add("ReturnedGoods;BeforeAddRow,BeforeDeleteRow;ReturnedGoodsCanceled");
	ItemArray.Add("SubstituteGoods;BeforeAddRow,BeforeDeleteRow;SubstituteGoodsSupplyOption,SubstituteGoodsCanceled,ReplacementProductsCanceledCancellationReasonsAreNotUsed");
	
	// Controls associated with the Returned Items table
	ItemArray.Add("ReturnItemsContextMenuAdd");
	ItemArray.Add("ReturnItemsContextMenuCopy");
	ItemArray.Add("ReturnItemsContextMenuDelete");
	
	ItemArray.Add("ReturnItemsAdd");
	ItemArray.Add("ReturnItemsChange");
	ItemArray.Add("ReturnedItemsCopy");
	ItemArray.Add("ReturnItemsDelete");
	
	ItemArray.Add("ToInsertTheReturnedString");
	ItemArray.Add("ReturnedGoodsSplitTheStringReturned");
	ItemArray.Add("SetContentReturnedGoods");
	
	ItemArray.Add("ReturnedGoodsFillInPricesByAgreement");
	ItemArray.Add("ReturnedItemsFillInPricesOfSelectedRowsByPriceType");
	ItemArray.Add("ReturnedProductsBarcodeSearch");
	ItemArray.Add("ReturnedGoodsImportDataFromPDT");
	ItemArray.Add("ReturnedGoodsToPickUpTheGoodsInImplementations");
	ItemArray.Add("ReturnedGoodsFillInSalesAndPrices");
	ItemArray.Add("ReturnOfSpoiledGoods");
	ItemArray.Add("ReturnedGoodsImportReturnedGoodsFromExternalFile");
	ItemArray.Add("ReturnedGoodsSelectTransferredGoods");
	ItemArray.Add("ReturnedGoodsReturnedGoodsAddReusablePackage");
	ItemArray.Add("ReturnedGoodsFillInVATRATE");
	
	// Controls associated with the Replacement Products table
	ItemArray.Add("ReplacementProductsContextMenuAdd");
	ItemArray.Add("ReplacementProductsContextMenuCopy");
	ItemArray.Add("ReplacementProductsContextMenuDelete");
	
	ItemArray.Add("SubstituteProductsAdd");
	ItemArray.Add("SubstituteGoodsEdit");
	ItemArray.Add("SubstituteGoodsCopy");
	ItemArray.Add("RemoveReplacementProducts");
	
	ItemArray.Add("InsertSubstituteLines");
	ItemArray.Add("SubstituteGoodsSplitRow");
	ItemArray.Add("SubstituteGoodsSetContentSubstituteGoods");
	
	ItemArray.Add("SubstituteProductsCalculateDiscountMarkups");
	ItemArray.Add("ReplacementProductsCancelManualDiscounts");
	ItemArray.Add("SubstituteProductsAssignAManualDiscount");
	ItemArray.Add("SubstituteItemsAssignAManualDiscountToSelectedLines");
	ItemArray.Add("SubstituteGoodsAssignAutomaticDiscounts");
	ItemArray.Add("SubstituteGoodsAddPaymentWithBonusPoints");
	ItemArray.Add("SubstituteGoodsCancelPaymentWithBonusPoints");
	ItemArray.Add("ToReadLoyaltyCard");
	ItemArray.Add("LoyaltyCard");
	
	ItemArray.Add("SubstituteGoodsFillInPricesByAgreement");
	ItemArray.Add("SubstituteProductsFillInPricesOfSelectedRowsByTypeOfPrices");
	ItemArray.Add("SubstituteGoodsReplacementProductsOpenSelection");
	ItemArray.Add("SubstituteGoodsUploadReplacementProductsFromAnExternalFile");
	ItemArray.Add("SubstituteGoodsSubstituteGoodsAddReusablePackage");
	ItemArray.Add("SubstituteGoodsFillInTheDepartment");
	ItemArray.Add("ReplacementGoodsFillInVATRate");
	
	ItemArray.Add("ReplacementProductsBarcodeSearch");
	ItemArray.Add("SubstituteGoodsImportDataFromPDT");
	
	ItemArray.Add("SubstituteGoodsFillInSubstituteGoodsByReturnedOnes");
	
	TMCommonUse.SetSubscriptionForFormElementChangeEvents(ThisObject, ItemArray);
	
	TMCommonUseClientServer.SetFormItemProperty(Items, "Partner", "ReadOnly", ValueIsFilled(Object.CashRegisterReceipt)); 
	
EndProcedure

&AtServer
Procedure UpdateAdditionalAttributesItems()
	
	PropertyManager.UpdateAdditionalAttributesItems(ThisForm);
	
EndProcedure

&AtServer
Procedure EditServerDocument()
	
	SetAvailabilityOfItemsByStatusServer();
	ConfigureElementsByOperationServer();
	CustomizeFormElements();
	
EndProcedure

&AtServer
Function CheckForGradationServer(ProductOfOriginalQuality, NonconformingProducts)
	
	Return InformationRegisters.AnotherQualityGoods.CheckForGradation(ProductOfOriginalQuality, NonconformingProducts);
	
EndFunction

&AtServer
Function SubstituteGoodsCancelUndeliveredLinesServer(CancellationReason, Val CheckBalance = False)
	
	AdjustmentStructure = OrdersServer.OrderLineAdjustmentStructure();
	AdjustmentStructure.DocumentObject               = Object;
	AdjustmentStructure.CancellationReason                = CancellationReason;
	AdjustmentStructure.CheckBalance             = CheckBalance;
	AdjustmentStructure.TabularSectionName            = "SubstituteGoods";
	AdjustmentStructure.CancelUnprocessedLines = True;
	
	ResultStructure1 = SalesServer.AdjustOrderLines(AdjustmentStructure);
	NumberOfCanceledLines = ResultStructure1.RowsCount;
	
	UpdateDuplicateDependentDetails(True);
	
	If NumberOfCanceledLines > 0 Then
		ProductsServer.FillInStatusesForSpecifyingSeries(Object,SeriesSpecificationParameters.Substitutes_);
		FillInServiceDetailsOfDocumentForm();
		UpdateColumnAvailableServer();
	EndIf;    
	
	OnChangingWarehouseInTablePartReplacingGoodsServer();
	
	Return NumberOfCanceledLines;
	
EndFunction

&AtServer
Procedure FillInSubstituteGoodsByReturnedOnesServer()
	
	CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	
	Object.SubstituteGoods.Load(
		Object.ReturnedGoods.Unload(
			New Structure("Canceled", False),
			"ProductsInSet,
			|ItemVariantOfSet,
			|Products,
			|Characteristic,
			|Package,
			|NumberOfPackages,
			|Count,PriceKind,
			|Price,
			|Warehouse,
			|Sum,
			|AmountIncludingVAT,
			|VATRate,
			|VATAmount"));
			
			
	If Not Object.FillInPricesOfSubstituteGoodsByReturned Then
		FillThePricesByTermsOfSalesServer();
	EndIf;
	
	If Object.NotShipInInstallments And ValueIsFilled(Object.DateOfShipment) Then
		For Each TSRow In Object.SubstituteGoods Do
			TSRow.DateOfShipment = Object.DateOfShipment;
		EndDo; 
	EndIf;
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInFeatureAttribute", New Structure("Products", "ItemVariantsAreUsed"));
	StructureOfActions.Insert("FillInSalesOptionAttribute", New Structure("Products", "SaleRegistrationOption"));
	StructureOfActions.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
	StructureOfActions.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));
	
	ProductsServer.FillInServiceDetailsForProductInCollection(Object.SubstituteGoods,StructureOfActions);
	SetsServer.FillInServiceDetails(ThisForm, "SubstituteGoods");
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInNoReturnContainerAttribute", Object.ToReturnReusablePackage);
	StructureOfActions.Insert("FillInCanceledWithoutReturnableContainerAttribute", Object.ToReturnReusablePackage);
	AddCollateralActionsOnServer(StructureOfActions,
		"SupplyOption,WarehouseIsRequired,DateOfShipmentRequired_");
	BatchProcessingOfTablePartServer.TreatTS(Object.SubstituteGoods, StructureOfActions, CachedValues);
	
	ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters.Substitutes_);
	UpdateDuplicateDependentDetails(True);
	SetVisibilityOfAutomaticDiscounts();
	CalculateTotalsOfRefundRequest(ThisForm);
	UpdateColumnAvailableServer();
	
	OnChangingWarehouseInTablePartReplacingGoodsServer();
	
EndProcedure

&AtServer
Procedure RefreshStatusServer()
	
	Documents.RequestForReturnOfGoodsFromCustomer.CalculateStatus(Object.Ref, Object.Contract, ThisObject);
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
	
	Documents.RequestForReturnOfGoodsFromCustomer.CalculateStatus(
		Ref,
		Contract,
		OrderState,
		CheckTasksToReflectStateOfOrders);
	
	Hyperlink = AccessRight("View", Metadata.Reports.DocumentFulfillmentStatus);
	
EndProcedure


&AtServer
Procedure UpdateCompensationMethod()
	
	If Object.BusinessOperation = Enums.BusinessTransactions.ReturnFromCustodian
		Or Object.BusinessOperation = Enums.BusinessTransactions.ReturnFromCommissionAgent Then
		Object.CompensationMethod = Enums.CompensationMethodsForReturnsOfGoods.EmptyRef();
	EndIf;
	
EndProcedure

&AtServerNoContext
Function GetDefaultCounterpartyBankAccountServer(Counterparty)
	
	ParametersOfAccount = CashServer.ParametersForFillingInCounterpartySBankAccount(Counterparty);
	
	Return CashServer.GetDefaultCounterpartyBankAccount(ParametersOfAccount);
	
EndFunction

&AtServer
Procedure FillIn_BlankReceiptDates()
	
	If Object.ReturnedGoods.Count() > 0 Then
		
		If Object.Status = PredefinedValue("Enum.StatusesOfRequestsForReturnOfGoodsFromCustomers.ForReturn") Or
			Object.Status = PredefinedValue("Enum.StatusesOfRequestsForReturnOfGoodsFromCustomers.ToSupply") Or
			Object.Status = PredefinedValue("Enum.StatusesOfRequestsForReturnOfGoodsFromCustomers.ToShip") Or
			Object.Status = PredefinedValue("Enum.StatusesOfRequestsForReturnOfGoodsFromCustomers.Executed") Then
	
			Documents.RequestForReturnOfGoodsFromCustomer.FillIn_BlankReceiptDates(Object);
			QualityControl.UpdateActionParameters(
				Documents.RequestForReturnOfGoodsFromCustomer,
				Object,
				CacheQualityControl);
	
		EndIf;
		
	EndIf;
		
EndProcedure

&AtClient
Procedure FillInDateOfReceipt(ArrayOfSelectedRows = Undefined)
	
	DateOfReceipt = Object.RequestedDeliveryDate;
	
	Notification = New CallbackDescription("FillInDateOfReceiptCompletion", ThisObject, New Structure("ArrayOfSelectedRows", ArrayOfSelectedRows));
	
	TMCommonUseClient.EnterDateWithControlOfEmptyValue(DateOfReceipt, NStr("vi = 'Hãy nhập ngày tiếp nhận';
																			|ru = 'Введите дату поступления';
																			|en = 'Enter date of receipt'; fa = 'Enter date of receipt';
																			|it = 'Inserire la data di arrivo';
																			|pl = 'Wprowadź datę wpłaty';
																			|tr = 'Giriş tarihini girin'"), DateFractions.Date, Notification);
	
EndProcedure

&AtClient
Procedure FillInDateOfReceiptCompletion(SelectedDate, AdditionalParameters) Export
	
	If SelectedDate <> Undefined And ValueIsFilled(SelectedDate) Then
		
		DateOfReceipt = SelectedDate;
		ArrayOfSelectedRows = AdditionalParameters.ArrayOfSelectedRows;
		
		If ArrayOfSelectedRows = Undefined Then
			
			For Each TSRow In Object.ReturnedGoods Do
				TSRow.DateOfReceipt = DateOfReceipt;
			EndDo;
			
		Else
			
			For Each RowID In ArrayOfSelectedRows Do
				
				TSRow = Object.ReturnedGoods.FindByID(RowID);
				TSRow.DateOfReceipt = DateOfReceipt;
				
			EndDo;
			
		EndIf;
		
		PurchasesClient.NotifyAboutEndOfFillingInReceiptDates(DateOfReceipt, (ArrayOfSelectedRows <> Undefined));
	
	EndIf; 
	
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
		TermsOnChangeServer();
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
																					|tr = 'Sadakat kartı ""%1"" adlı iş ortağına aittir. Belgedeki iş ortağı değiştirilsin mi?'"), LoyaltyCardDetails.Partner),
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
		ApplyPaymentWithBonusPoints(Undefined);
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
	ParametersStructure.TableName = "SubstituteGoods";
	ParametersStructure.OnlyForSelectedLines = SelectedLinesOnly;
	Return DiscountsMarkupsFillingServer.AddressOfDataForCalculatingManualDiscountsInTemporaryStorage(
		ThisForm, UUID, ParametersStructure);
	
EndFunction

&AtServer
Function PutItInTemporaryStorageOnServer(TSName, Id = "")
	
	Return PutToTempStorage(Object[TSName].Unload(), Id);
	
EndFunction

&AtServer 
Procedure FillIn_ReceiptDatesServer(DateOfReceipt)

	For Each OwnGoods In Object.ReturnedGoods Do
		OwnGoods.DateOfReceipt = DateOfReceipt;
		
	EndDo;
	If QualityControl.UpdateActionParameters(
			Documents.RequestForReturnOfGoodsFromCustomer,
			Object,
			CacheQualityControl) Then
		
		StructureOfActions = New Structure();
		StructureOfActions.Insert("FillInCheckQualityDateOfQualityConfirmation", CacheQualityControl);
		BatchProcessingOfTablePartServer.TreatTS(Object.ReturnedGoods, StructureOfActions);
		
	EndIf;
	
EndProcedure

&AtServer 
Function MaximumReceiptDate()
	
	MaximumReceiptDate = Date(1,1,1);
	For Each OwnGoods In Object.ReturnedGoods Do 
		MaximumReceiptDate = Max(MaximumReceiptDate, OwnGoods.DateOfReceipt);
		
	EndDo;
	
	Return MaximumReceiptDate
	
EndFunction

&AtServer
Function CancelNonReturnedServerRows(CheckBalance = False)
	
	DocumentObject = FormAttributeToValue("Object");
	
	RowAdjustmentStructure = OrdersServer.OrderLineAdjustmentStructure();
	RowAdjustmentStructure.CancelUnprocessedLines = True;
	RowAdjustmentStructure.TabularSectionName            = "ReturnedGoods";
	RowAdjustmentStructure.CheckBalance             = True;
	
	NumberOfCanceledLines = DocumentObject.AdjustOrderLines(RowAdjustmentStructure);
	ValueToFormAttribute(DocumentObject, "Object");
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInFeatureAttribute", New Structure("Products,ProductsRecordingAsReceived", "ItemVariantsAreUsed", "ItemVariantsAreUsedRecordingAsReceived"));
	StructureOfActions.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));
	StructureOfActions.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
	
	ProductsServer.FillInServiceDetailsForProductInCollection(
		Object.ReturnedGoods,
		StructureOfActions);
	SetsServer.FillInServiceDetails(ThisForm, "ReturnedGoods");
	
	UpdateDuplicateDependentDetails();
	UpdateColumnAvailableServer();
	FillInServiceDetailsOfDocumentForm();
	OnChangingWarehouseInTablePartOfReturnedGoodsServer();
	
	StructureOfActions = New Structure();
	StructureOfActions.Insert("FillInCheckQualityDateOfQualityConfirmation", CacheQualityControl);
	BatchProcessingOfTablePartServer.TreatTS(Object.ReturnedGoods, StructureOfActions);
	
	Return NumberOfCanceledLines;
	
EndFunction

&AtServer
Procedure FillInSalesAndPricesOnServer()
	
	SalesServer.FillInSalesAndPrices(Object, "ReturnedGoods");
	TMCommonUse.FillInDuplicateDependentPropsInCollection(Object.ReturnedGoods, DependentDetailsReturnedGoods());
	CalculateTotalsOfRefundRequest(ThisForm);
	
EndProcedure

&AtServer
Procedure UpdateInformationOnImplementations()
	
	If Not ValueIsFilled(Object.CashRegisterReceipt) Then
		SalesServer.UpdateInformationOnImplementationsInForm(
			SalesList,
			Object.DocumentSalesOfGoodsAndServices,
			TheInscriptionTheTitleOfTheImplementation,
			Items,
			Items.ReturnedGoodsDocumentSalesOfGoodsAndServices,
			Object.ReturnedGoods,
			"DocumentSalesOfGoodsAndServices");
	Else
		Object.DocumentSalesOfGoodsAndServices = GetReportOnRetailSalesByCashRegisterReceipt(Object.CashRegisterReceipt);
		Items.SalePages.CurrentPage = Items.PageSales;
	EndIf;
	
EndProcedure

&AtServer
Procedure ClearImplementationDocuments()
	
	Object.DocumentSalesOfGoodsAndServices = Undefined;
	
	For Each LineProducts_ In Object.ReturnedGoods Do
		LineProducts_.DocumentSalesOfGoodsAndServices = Undefined;
	EndDo;
	
	TheInscriptionTheTitleOfTheImplementation = Undefined;

EndProcedure

&AtServer
Procedure FillInReturnedItemsByReceipt()
	
	Object.ReturnedGoods.Clear();
	SalesServer.FillInReturnedItemsByReceipt(Object, "ReturnedGoods");
	StructureOfActions = New Structure();
	StructureOfActions.Insert("FillInCheckQualityDateOfQualityConfirmation", CacheQualityControl);
	BatchProcessingOfTablePartServer.TreatTS(Object.ReturnedGoods, StructureOfActions);
	ReusablePackageServer.UpdateNoReturnableContainerAttribute(Object.ReturnedGoods, Object.ToReturnReusablePackage);
	TMCommonUse.FillInDuplicateDependentPropsInCollection(Object.ReturnedGoods, DependentDetailsReturnedGoods());
	UpdateInformationOnImplementations();
	
EndProcedure

&AtServer
Procedure FillIn_TermsOfSales()
	
	DocumentSales = FormAttributeToValue("Object");
	DocumentSales.FillInDefaultSalesConditions();
	ValueToFormAttribute(DocumentSales, "Object");
	
	FillInDefaultContract();

	ContractBusinessTransaction = SelfServiceClientServer.ContractBusinessTransaction(Object.BusinessOperation);
	NewEconomicOperationOfAgreement = SelfServiceClientServer.BusinessTransactionFromAgreement(Object.BusinessOperation);
	
	If ToUseTermsOfSales And NewEconomicOperationOfAgreement <> BusinessTransactionFromAgreement Then
		BusinessTransactionFromAgreement = NewEconomicOperationOfAgreement;
		Object.Terms = Undefined;
	EndIf;
	
	SetCommissionSaleAttribute();
	
	If ToUseTermsOfSales And ValueIsFilled(Object.Terms) Then
		
		DocumentCurrency = Object.Currency;
		
		If (Object.BusinessOperation = Enums.BusinessTransactions.ReturnFromCommissionAgent
				Or Object.BusinessOperation = Enums.BusinessTransactions.ReturnFromCustodian)
			And (UseDiscountAdjustmentsInSales Or UseDiscountsMarkupsInSales)Then
			DiscountsMarkupsFillingServer.CancelDiscounts(Object, "SubstituteGoods", True);
			DiscountsMarkupsFillingServer.ConfigureShowMessagesCommand(Object, Items.ShowMessages, False);
		EndIf;
		
		ConfigureElementsByOperationServer();
		
	EndIf;
	
	SetBanOnSelectingWarehouseGroup(Items.Warehouse);
	
	CustomizeFormElements();
	
EndProcedure

&AtServer
Procedure SetVisibilityOfShipmentBanToPartner()
	
	SegmentsServer.SetVisibilityOfShipmentBanToPartner(Object.Partner, Items);
	
EndProcedure

&AtServerNoContext
Function GetReportOnRetailSalesByCashRegisterReceipt(CashRegisterReceipt)
	Return RetailSales.GetReportOnRetailSalesByCashRegisterReceipt(CashRegisterReceipt);
EndFunction

&AtServer
Procedure FillMultiTurnContainersFromStorageServer(AddressOfContainerInStorage)
	
	CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	
	If Items.GroupPages.CurrentPage = Items.GroupOfReturnedProducts Then
	
		ActionStructureModifiedStrings = New Structure;
		StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
		ActionStructureModifiedStrings.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
		ActionStructureModifiedStrings.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));
		ActionStructureModifiedStrings.Insert("FillInNoReturnContainerAttribute", Object.ToReturnReusablePackage);
		ActionStructureModifiedStrings.Insert("FillInCanceledWithoutReturnableContainerAttribute", Object.ToReturnReusablePackage);
		ActionStructureModifiedStrings.Insert("RecalculateNumberOfPackages");
		ActionStructureModifiedStrings.Insert("FillInVATRate", BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRate(Object));
		ActionStructureModifiedStrings.Insert("FillInVATRateForReturnableContainers", Object.ToReturnReusablePackage);
		ActionStructureModifiedStrings.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
		ActionStructureModifiedStrings.Insert("RecalculateAmount");
		ActionStructureModifiedStrings.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
		ActionStructureModifiedStrings.Insert("FillInDuplicateDependentDetails", DependentDetailsReturnedGoods());
		ActionStructureModifiedStrings.Insert("CheckFillWarehouse", 
			BatchProcessingOfTablePartClientServer.GetWarehouseFillStructureInTSLine(Object, WarehouseGroup_));
		
		StructureOfActionsAddedLines =  CommonClientServer.CopyStructure(ActionStructureModifiedStrings);;
		If (ToUseTermsOfSales And ValueIsFilled(Object.Terms)) 
			Or (Not ToUseTermsOfSales And UsePriceManagementSystem25) Then
			StructureOfActionsAddedLines.Insert("FillIn_TermsOfSales", BatchProcessingOfTablePartClientServer.GetStructureForFillingInSalesConditionsInTSLine(Object));
		EndIf;
		
		ReusablePackageServer.FillMultiTurnContainersFromStorage(
			Object,
			AddressOfContainerInStorage,
			"ReturnedGoods",
			"Products,Characteristic,,DateOfReceipt",
			ActionStructureModifiedStrings,
			StructureOfActionsAddedLines);
			
		StructureCharacteristicsOfProducts = New Structure;
		StructureCharacteristicsOfProducts.Insert("FillInFeatureAttribute",	New Structure("Products", "ItemVariantsAreUsed"));
			
		ProductsServer.FillInServiceDetailsForProductInCollection(Object.ReturnedGoods, StructureCharacteristicsOfProducts);
		StructureOfActions = New Structure();
		StructureOfActions.Insert("FillInCheckQualityDateOfQualityConfirmation", CacheQualityControl);
		BatchProcessingOfTablePartServer.TreatTS(Object.ReturnedGoods, StructureOfActions);
		
		SetsServer.FillInServiceDetails(ThisForm, "ReturnedGoods");
		
		ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters.Returned_);
		
	ElsIf Items.GroupPages.CurrentPage = Items.ReplacementProductsGroup Then

		ActionStructureModifiedStrings = New Structure;
		StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
		ActionStructureModifiedStrings.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
		ActionStructureModifiedStrings.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));
		ActionStructureModifiedStrings.Insert("FillInNoReturnContainerAttribute", Object.ToReturnReusablePackage);
		ActionStructureModifiedStrings.Insert("FillInCanceledWithoutReturnableContainerAttribute", Object.ToReturnReusablePackage);
		ActionStructureModifiedStrings.Insert("RecalculateNumberOfPackages");
		ActionStructureModifiedStrings.Insert("FillInVATRate", BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRate(Object, True));
		ActionStructureModifiedStrings.Insert("FillInVATRateForReturnableContainers", Object.ToReturnReusablePackage);
		ActionStructureModifiedStrings.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
		ActionStructureModifiedStrings.Insert("RecalculateAmount");
		ActionStructureModifiedStrings.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
		ActionStructureModifiedStrings.Insert("RecalculateAmountTakingIntoAccountManualDiscount", New Structure("Clear", True));
		ActionStructureModifiedStrings.Insert("RecalculateAmountTakingIntoAccountAutomaticDiscount", New Structure("Clear", True));
		ActionStructureModifiedStrings.Insert("RecalculateAmountTakingIntoAccountDiscountWithBonusPoints");
		ActionStructureModifiedStrings.Insert("FillInSubdivisionInTSLine", New Structure("Department", Object.Department));
		ActionStructureModifiedStrings.Insert("CheckFillWarehouse", 
			BatchProcessingOfTablePartClientServer.GetWarehouseFillStructureInTSLine(Object, WarehouseGroup_));
		
		ActionStructureModifiedStrings.Insert("FillInDuplicateDependentDetails", DependentDetailsReplacingGoods());
		
		AddCollateralActionsOnServer(ActionStructureModifiedStrings,
			"SupplyOption,WarehouseIsRequired,DateOfShipmentRequired_");
		
		StructureOfActionsAddedLines = Common.CopyRecursive(ActionStructureModifiedStrings);;
		
		If (ToUseTermsOfSales And ValueIsFilled(Object.Terms)) 
			Or (Not ToUseTermsOfSales And UsePriceManagementSystem25) Then
			StructureOfActionsAddedLines.Insert("FillIn_TermsOfSales", BatchProcessingOfTablePartClientServer.GetStructureForFillingInSalesConditionsInTSLine(Object));
		Else
			StructureOfActionsAddedLines.Insert("FillInSalePrice", BatchProcessingOfTablePartClientServer.ParametersForFillingInPriceInTSLine(Object));
		EndIf;
		
		ReusablePackageServer.FillMultiTurnContainersFromStorage(
			Object,
			AddressOfContainerInStorage,
			"SubstituteGoods",
			"Products,Characteristic,,DateOfShipment",
			ActionStructureModifiedStrings,
			StructureOfActionsAddedLines,
			CachedValues);
		
		ItemVariantsAreUsed = New Structure("Products", "ItemVariantsAreUsed");
		FillInSalesOptionAttribute = New Structure("Products", "SaleRegistrationOption");
		FillInProductTypeAttribute_ = New Structure("Products", "ItemsType");
		StructureOfActions = New Structure(
			"FillInFeatureAttribute, FillInSalesOptionAttribute, FillInProductTypeAttribute_",
			ItemVariantsAreUsed,
			FillInSalesOptionAttribute,
			FillInProductTypeAttribute_);
		
		ProductsServer.FillInServiceDetailsForProductInCollection(Object.SubstituteGoods,StructureOfActions);
		SetsServer.FillInServiceDetails(ThisForm, "SubstituteGoods");
		
		ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters.Substitutes_);
		UpdateColumnAvailableServer();
	
	EndIf;
	
	CalculateTotalsOfRefundRequest(ThisForm);
	UpdateInformationOnImplementations();
	
EndProcedure

&AtServer
Procedure ToReturnReusablePackageOnChangeServer()
	
	If Not Object.ToReturnReusablePackage Then
		Object.PackageDepositIsRequired = False;
	EndIf;
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
	StructureOfActions.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));
	StructureOfActions.Insert("FillInNoReturnContainerAttribute", Object.ToReturnReusablePackage);
	StructureOfActions.Insert("FillInCanceledWithoutReturnableContainerAttribute", Object.ToReturnReusablePackage);
	StructureOfActions.Insert("FillInVATRateForReturnableContainers", Object.ToReturnReusablePackage);
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForRecalculatingNDSWTCHAmount(Object);
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	BatchProcessingOfTablePartServer.TreatTS(Object.ReturnedGoods, StructureOfActions, Undefined);
	
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountManualDiscount", New Structure("Clear", True));
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountAutomaticDiscount", New Structure("Clear", True));
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountDiscountWithBonusPoints");
	BatchProcessingOfTablePartServer.TreatTS(Object.SubstituteGoods, StructureOfActions, Undefined);
	
	UpdateDuplicateDependentDetails();
	
	CustomizeFormElements();
	CalculateTotalsOfRefundRequest(ThisForm);
	
EndProcedure

&AtServer
Procedure UpdateDuplicateDependentDetails(OnlySubstitutes = False)
	StructureOfAdditionalActions = New Structure;
	StructureOfAdditionalActions.Insert("FillInCanceledWithoutReturnableContainerAttribute", Object.ToReturnReusablePackage);
	If Not OnlySubstitutes Then
		ReusablePackageServer.UpdateNoReturnableContainerAttribute(Object.ReturnedGoods, Object.ToReturnReusablePackage, StructureOfAdditionalActions);
		TMCommonUse.FillInDuplicateDependentPropsInCollection(Object.ReturnedGoods, DependentDetailsReturnedGoods());
	EndIf;
	ReusablePackageServer.UpdateNoReturnableContainerAttribute(Object.SubstituteGoods, Object.ToReturnReusablePackage, StructureOfAdditionalActions);
	TMCommonUse.FillInDuplicateDependentPropsInCollection(Object.SubstituteGoods, DependentDetailsReplacingGoods());
EndProcedure

&AtServer
Procedure PaymentCreditedServer(EventName, Parameter, Source)
	
	CustomizeFormElements();
	RefreshStatusServer();
	
	ARAPAccountingFormWork.NotificationProcessing(ThisForm, EventName, Parameter);
	
EndProcedure

&AtServer
Procedure GetUploadedProductsFromStorage(GoodsAddressInStorage, TSName)
	
	ItemsFromStorage = GetFromTempStorage(GoodsAddressInStorage);
	
	StructureOfActions = New Structure;
	If TSName = "SubstituteGoods" Then
		StructureOfActions.Insert("FillInContent", BatchProcessingOfTablePartClientServer.GetStructureOfFillingInServiceContentInTSLine(Object, False));
		
		AddCollateralActionsOnServer(StructureOfActions,
			"SupplyOption,WarehouseIsRequired,DateOfShipmentRequired_");
		StructureOfActions.Insert("FillInSubdivisionInTSLine", New Structure("Department", Object.Department));
		AddReplacementProductsToActionStructureWhenChangingNumberOfPackages(StructureOfActions, Object);
	ElsIf TSName = "ReturnedGoods" Then
		AddToActionStructureWhenChangingNumberOfPackagesReturnItems(StructureOfActions, Object);
		StructureOfActions.Insert("FillInCheckQualityDateOfQualityConfirmation", CacheQualityControl);
	EndIf;
	
	StructureOfActions.Insert("FillInNoReturnContainerAttribute", Object.ToReturnReusablePackage);
	StructureOfActions.Insert("FillInCanceledWithoutReturnableContainerAttribute", Object.ToReturnReusablePackage);

	If TSName = "SubstituteGoods" Then
		ParametersForFillingInVATRate = BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRate(Object, True);
		If Object.NotShipInInstallments And ValueIsFilled(Object.DateOfShipment) Then
			ParametersForFillingInVATRate.Date = Object.DateOfShipment;
		EndIf;
	Else
		ParametersForFillingInVATRate = BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRate(Object, True);
		If ValueIsFilled(Object.DocumentSalesOfGoodsAndServices) Then
			SaleDate = Common.ObjectAttributeValue(Object.DocumentSalesOfGoodsAndServices, "Date");
			ParametersForFillingInVATRate.Date = SaleDate;
		EndIf;
	EndIf;
	
	StructureOfActions.Insert("FillInVATRate", ParametersForFillingInVATRate);
	StructureOfActions.Insert("FillInVATRateByPriceType", BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRateByPriceType(Object));
	StructureOfActions.Insert("FillInVATRateForReturnableContainers", Object.ToReturnReusablePackage);
	StructureOfActions.Insert("CheckFillWarehouse", 
		BatchProcessingOfTablePartClientServer.GetWarehouseFillStructureInTSLine(Object, WarehouseGroup_));
	
	RowsToProcess = New Array;

	For Each RowOfGoods In ItemsFromStorage Do
		ObjectTablePart = Object[TSName]; // DocumentTabularSection.RequestForReturnOfGoodsFromCustomer.ReturnedGoods, DocumentTabularSection.RequestForReturnOfGoodsFromCustomer.SubstituteGoods - 
		StringTSGoods = ObjectTablePart.Add();
		FillPropertyValues(StringTSGoods, RowOfGoods, , "RowCode");
		
		If TSName = "SubstituteGoods" And Object.NotShipInInstallments Then
			StringTSGoods.DateOfShipment = Object.DateOfShipment;
		ElsIf TSName = "ReturnedGoods" And Object.OneDateReceipt Then
			StringTSGoods.DateOfReceipt = Object.DateOfReceipt;
		EndIf;
		
		RowsToProcess.Add(StringTSGoods);
		
	EndDo;

	BatchProcessingOfTablePartServer.ProcessTSStrings(
		RowsToProcess,
		StructureOfActions,
		Object[TSName]);
	
	If TSName = "ReturnedGoods" Then
		ProductsServer.FillInStatusesForSpecifyingSeries(Object,SeriesSpecificationParameters.Returned_);
	ElsIf TSName = "SubstituteGoods" Then
		ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters.Substitutes_);
		UpdateColumnAvailableServer();
	EndIf;
	
	ReusablePackageServer.UpdateFillingStateOfMultiTurnContainer(Object.ReusablePackageFillingStatus);
	CalculateTotalsOfRefundRequest(ThisForm);
	
	OnChangingWarehouseInTablePartOfReturnedGoodsServer();
	OnChangingWarehouseInTablePartReplacingGoodsServer();
	
EndProcedure

&AtServer
Procedure ConfigureElementsByOperationServer()
	
	TypesArray = New Array();
	If Object.BusinessOperation = Enums.BusinessTransactions.ReturnFromRetailCustomer Then
		TypesArray.Add(Type("DocumentRef.RetailSalesReport"));
	ElsIf Object.BusinessOperation = Enums.BusinessTransactions.ReturnFromCustodian
		Or (ConsignmentSales25
			And Object.BusinessOperation = Enums.BusinessTransactions.ReturnFromCommissionAgent) Then
		TypesArray.Add(Type("DocumentRef.TransferOfGoodsToBailee"));
	Else
		TypesArray.Add(Type("DocumentRef.CustomerInvoice"));
	EndIf;
	Items.ReturnedGoodsDocumentSalesOfGoodsAndServices.TypeRestriction = New TypeDescription(TypesArray);
	
	SetPropertiesOfOutdatedCommissionUsageComment();
	
EndProcedure

&AtServer
Procedure CustomizeFormElements()
	
	UsePaymentSchedules = GetFunctionalOption("UsePaymentSchedules");
	UseStatuses = Not Object.ThisIsOrderAsInvoice;
	UseReasonsForSalesOrderCancellations = GetFunctionalOption("UseReasonsForSalesOrderCancellations");
	
	ThisIsReturnOfSpoilage = Object.ReturnOfSpoiledGoods;
	ShipInOneDay = Object.NotShipInInstallments;
	OneDateReceipt = Object.OneDateReceipt;
	ToReturnReusablePackage = Object.ToReturnReusablePackage;
	ItIsNecessaryToReplaceGoods = Object.CompensationMethod = Enums.CompensationMethodsForReturnsOfGoods.ToSubstituteGoods;
	WeNeedToReturnMoney =
		Object.CompensationMethod = Enums.CompensationMethodsForReturnsOfGoods.ReturnCash;
	
	ThisIsRefundFromCommissionAgent = Object.BusinessOperation = Enums.BusinessTransactions.ReturnFromCommissionAgent;
	ThisIsReturnFromKeeper = Object.BusinessOperation = Enums.BusinessTransactions.ReturnFromCustodian;
	ThisIsRefundFromCommissionAgentOrCustodian = ThisIsRefundFromCommissionAgent Or ThisIsReturnFromKeeper;

	ThisIsReturnFromRetailBuyer =
		Object.BusinessOperation = Enums.BusinessTransactions.ReturnFromRetailCustomer;
	
	Items.Status.Visible = UseStatuses;
	Items.CloseRequest.Visible = UseStatuses;
	
	SetSvzyaziTypesOfPrices(ThisIsRefundFromCommissionAgentOrCustodian);
	Items.PriceIncludesVAT.Visible = Not ThisIsRefundFromCommissionAgentOrCustodian;
	
	Items.SubstituteGoodsCanceled.Visible = UseReasonsForSalesOrderCancellations;
	Items.SubstituteGoodsCancellationReason.Visible = UseReasonsForSalesOrderCancellations;
	Items.ReplacementProductsCanceledCancellationReasonsAreNotUsed.Visible = Not UseReasonsForSalesOrderCancellations;
	
	Items.ReturnedGoodsProductsItemsType1.Visible = ThisIsReturnOfSpoilage;
	Items.ReturnedGoodsProductsRecordingAsReceivedCode.Visible = ThisIsReturnOfSpoilage;
	Items.ReturnedGoodsNomenclatureRegistrationArticle.Visible = ThisIsReturnOfSpoilage;
	Items.ReturnedGoodsProductsRecordingAsReceivedItemsType.Visible = ThisIsReturnOfSpoilage;
	Items.ReturnedGoodsDamage.Visible = ThisIsReturnOfSpoilage;
	Items.ReturnedGoodsProductsRecordingAsReceived.Visible = ThisIsReturnOfSpoilage;
	Items.ReturnedGoodsCharacteristicRecordingAsReceived.Visible = ThisIsReturnOfSpoilage;
	
	Items.DeliveryPage.Visible =
		(ItIsNecessaryToReplaceGoods
			And GoodsDeliveryClientServer.UsedDelivery20());
	
	Items.ReplacementProductsGroup.Visible = ItIsNecessaryToReplaceGoods;
	Items.NotShipInInstallments.Visible = ItIsNecessaryToReplaceGoods 
		And UseShipmentByRowsInSalesOrder And Not Object.ThisIsOrderAsInvoice;
	Items.PagesHyperlinkSoftwareStatus.Visible = ItIsNecessaryToReplaceGoods
		And UseShipmentByRowsInSalesOrder;
	Items.SumOfTotalSndsOfSubstituteProducts.Visible = ItIsNecessaryToReplaceGoods;
	Items.TotalAmountWithoutNDSOfSubstituteProducts.Visible = ItIsNecessaryToReplaceGoods;
	Items.FillInPricesOfSubstituteGoodsByReturned.Visible = ItIsNecessaryToReplaceGoods;
	
	If ItIsNecessaryToReplaceGoods Then
		Items.TaraPages.CurrentPage = Items.PagePackageDuringReplacement;
	Else
		Items.TaraPages.CurrentPage = Items.PagePackageWithoutReplacement;
	EndIf;
	
	ItemVisibility = Not ThisIsRefundFromCommissionAgentOrCustodian;
	ApplyTermsOfSale = Not Object.FillInPricesOfSubstituteGoodsByReturned;
	
	Items.Department.Visible = ItemVisibility;
	Items.SubstituteGoodsPercentRateOfManualDiscount.Visible = ItemVisibility And ApplyTermsOfSale;
	Items.SubstituteGoodsManualDiscount.Visible = ItemVisibility And ApplyTermsOfSale;
	Items.SubstituteGoodsPercentRateOfAutomaticDiscountMarkup.Visible = ItemVisibility And ApplyTermsOfSale;
	Items.SubstituteGoodsDiscountMarkupAmount.Visible = ItemVisibility And ApplyTermsOfSale;
	Items.SubstituteProductsCalculateDiscountMarkups.Visible = ItemVisibility And ApplyTermsOfSale;
	Items.ReplacementProductsCancelManualDiscounts.Visible = ItemVisibility And ApplyTermsOfSale;
	Items.SubstituteProductsAssignAManualDiscount.Visible = ItemVisibility And ApplyTermsOfSale;
	Items.SubstituteGoodsSubstituteItemsAssignAManualDiscountToSelectedLines.Visible = ItemVisibility And ApplyTermsOfSale;
	Items.ReplacementProductsOpenInformationAboutDiscounts.Visible = ItemVisibility And ApplyTermsOfSale;
	Items.ContextMenuReplacementProductsOpenInformationAboutDiscounts.Visible = ItemVisibility And ApplyTermsOfSale;
	Items.SubstituteGoodsAssignAutomaticDiscounts.Visible = ItemVisibility And ApplyTermsOfSale;
	Items.ToReadLoyaltyCard.Visible = ItemVisibility And ApplyTermsOfSale;
	Items.LoyaltyCard.Visible = ItemVisibility And ApplyTermsOfSale;
	Items.CompensationMethod.Visible = ItemVisibility;
	
	Items.SubstituteProductsFillInPricesOfSelectedRowsByTypeOfPrices.Visible = ApplyTermsOfSale;
	Items.SubstituteGoodsFillInPricesByAgreement.Visible = ApplyTermsOfSale;
	
	Items.CashRegisterReceipt.Visible = ThisIsReturnFromRetailBuyer;
	
	ItemVisibility = Not ThisIsRefundFromCommissionAgentOrCustodian And Not ThisIsReturnFromRetailBuyer;
	Items.ToReturnReusablePackage.Visible = (Not ThisIsReturnFromRetailBuyer
		And Not (ThisIsRefundFromCommissionAgent And ConsignmentSales25) And Not ThisIsReturnFromKeeper) Or Object.ToReturnReusablePackage;
	Items.ReusablePackageReturnCycleLength.Visible = (Not ThisIsReturnFromRetailBuyer
		And Not (ThisIsRefundFromCommissionAgent And ConsignmentSales25) And Not ThisIsReturnFromKeeper) Or Object.ToReturnReusablePackage;
	Items.PackageDepositIsRequired.Visible = ItemVisibility;
	Items.DepositForPackageIsRequired.Visible = ItemVisibility;
	Items.ReusablePackageReturn.Visible = (Not ThisIsReturnFromRetailBuyer
		And Not (ThisIsRefundFromCommissionAgent And ConsignmentSales25) And Not ThisIsReturnFromKeeper) Or Object.ToReturnReusablePackage;
	
	ItemVisibility = Not ThisIsRefundFromCommissionAgentOrCustodian And ItIsNecessaryToReplaceGoods And ApplyTermsOfSale;
	Items.DiscountAmount.Visible = ItemVisibility;
	
	ItemVisibility = Not ThisIsRefundFromCommissionAgentOrCustodian And ItIsNecessaryToReplaceGoods;

	ItemVisibility = Not ShipInOneDay;
	Items.SubstituteGoodsFillInShipmentDate.Visible = ItemVisibility;
	Items.SubstituteGoodsDateOfShipment.Visible = ItemVisibility 
		And UseShipmentByRowsInSalesOrder And Not Object.ThisIsOrderAsInvoice;
	
	ItemVisibility = ShipInOneDay And ItIsNecessaryToReplaceGoods;
	Items.DateOfShipment.Visible = ItemVisibility;
	
	Items.DateOfReceipt.Visible = OneDateReceipt;
	Items.ReturnedGoodsFillInReceiptDateForSelectedLines.Visible = Not OneDateReceipt;
	Items.ReturnedGoodsDateOfReceipt.Visible = Not OneDateReceipt;
	
	Items.RefundDate.Visible = WeNeedToReturnMoney;
	
	Items.ReusablePackageReturnCycleLength.Enabled = ToReturnReusablePackage;
	Items.PackageDepositIsRequired.Enabled = ToReturnReusablePackage;
	Items.DepositForPackageIsRequired.Enabled = ToReturnReusablePackage;
	
	Items.ReturnOfSpoiledGoods.Check                                           = Object.ReturnOfSpoiledGoods;
	Items.ReturnedItemsGroupPreviouslyShippedItems.ShowInHeader = Object.ReturnOfSpoiledGoods;
	
	Items.StateGroup.Visible = UseStatuses;
	
	Items.DecorationTitlePayment.Visible = Items.DecorationPaymentSteps.Visible Or Items.DecorationSettlementState.Visible Or Items.CreditPaymentForm.Visible;
	
	SetVisibilityOfPartnerField();
	SetContractVisibility();
	If Object.SubstituteGoods.Count() > 0 And Not ItIsNecessaryToReplaceGoods Then
		ClearReplacementGoods();
	EndIf;
	
	DocumentDate = ?(Parameters.Key.IsEmpty(), CurrentSessionDate(), Object.Date);
	RetailSalesClientServer.SetAvailabilityOfBonusPointsPaymentTeams(Items, DocumentDate);
	
EndProcedure

&AtServer
Procedure SetSvzyaziTypesOfPrices(ThisIsRefundFromCommissionAgentOrCustodian)
	
	ArrayOfSelectParameterRelationships = New Array;
	
	ArrayOfSelectParameterRelationships.Add(
		New ChoiceParameterLink("ToUseTermsOfSales", "ToUseTermsOfSales", LinkedValueChangeMode.Clear));
	
	ArrayOfSelectParameterRelationships.Add(
		New ChoiceParameterLink("Terms", "Object.Terms", LinkedValueChangeMode.DontChange));
		
	ArrayOfSelectParameterRelationships.Add(
		New ChoiceParameterLink("Partner", "Object.Partner", LinkedValueChangeMode.DontChange));
		
	If Not ThisIsRefundFromCommissionAgentOrCustodian Then
		ArrayOfSelectParameterRelationships.Add(
			New ChoiceParameterLink("Filter.PriceIncludesVAT", "Object.PriceIncludesVAT", LinkedValueChangeMode.Clear));
	EndIf;
	
	Items.ReturnedGoodsPriceKind.ChoiceParameterLinks = New FixedArray(ArrayOfSelectParameterRelationships);
	
EndProcedure

&AtServer
Procedure SetContractVisibility()
	
	Var ArrayOfAllProps;
	Var ArrayOfOperationDetails;
	
	Documents.RequestForReturnOfGoodsFromCustomer.FillInNamesOfBusinessTransactionDetails(
		Object.BusinessOperation,
		ArrayOfAllProps, 
		ArrayOfOperationDetails);
	
	VisibilityOfTransactionAgreement = ArrayOfOperationDetails.Find("Contract") <> Undefined;
	
	ContractVisibility = False;
	SalesServer.SetContractAvailability(Object, Items.Contract.Enabled, ContractVisibility, Object.Contract);
	Items.ContractGroup.Visible = (ContractVisibility And VisibilityOfTransactionAgreement) Or ConsignmentSales25;
	Items.Contract.Visible = (ContractVisibility And VisibilityOfTransactionAgreement) Or ConsignmentSales25;
	
EndProcedure

&AtServer
Procedure EstablishVisibilityOfCompensationMethods()
	
	LeaveAsPrepayment = Items.CompensationMethod.ChoiceList.FindByValue(
		Enums.CompensationMethodsForReturnsOfGoods.LeaveAsPrepayment);
	
	If Object.BusinessOperation = Enums.BusinessTransactions.ReturnFromRetailCustomer Then
		If LeaveAsPrepayment <> Undefined Then
			Items.CompensationMethod.ChoiceList.Delete(LeaveAsPrepayment);
		EndIf;
	ElsIf LeaveAsPrepayment = Undefined Then
		Items.CompensationMethod.ChoiceList.Add(Enums.CompensationMethodsForReturnsOfGoods.LeaveAsPrepayment);
	EndIf;
	
EndProcedure

&AtServer
Procedure ClearReplacementGoods()
 	Object.SubstituteGoods.Clear();
EndProcedure

&AtServer
Procedure FillInFormDetailsFromCashRegisterReceipt(CashRegisterReceipt, Attributes)
	If ValueIsFilled(CashRegisterReceipt) Then
		CashRegisterReceiptDetailsValues = Common.ObjectAttributesValues(CashRegisterReceipt, Attributes);
		For Each AttributeValue In CashRegisterReceiptDetailsValues Do
			ThisForm[AttributeValue.Key] = AttributeValue.Value;
		EndDo;	
	EndIf;
EndProcedure

&AtClient
Procedure FillInTheDepartment(Command)
	
	WarehousesClient.FillInDivisionInTablePart(Object, ThisForm, Object.SubstituteGoods, "Substitutes_ goods", 
			Items.SubstituteGoods.SelectedRows);
	
EndProcedure

&AtClient
Procedure EnableWaitingHandlerReceivingCarriers()
	
	If BackgroundTaskData.Property("JobID") Then
		IdleParameters = TimeConsumingOperationsClient.IdleParameters(ThisObject);
		IdleParameters.OutputIdleWindow = False;
		CallbackOnCompletion = New CallbackDescription("UpdateListOfCarriersNotification", ThisObject);
		
		TimeConsumingOperationsClient.WaitCompletion(
			BackgroundTaskData, CallbackOnCompletion, IdleParameters);
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
		BackgroundTaskData = New Structure;
	EndIf;
	
EndProcedure

&AtServer
Function AddressOfTheTablePartProducts()
	
	RowsArray = New Array();
	For Each String In Object.SubstituteGoods Do
		If String.Canceled Then
			Continue;
		EndIf;
		
		RowsArray.Add(String);
	EndDo;
	
	Return PutToTempStorage(Object.SubstituteGoods.Unload(RowsArray), UUID);
	
EndFunction

&AtServer
Procedure GenerateHeadersThatDependOnBusinessTransaction()
	
	If Object.BusinessOperation = Enums.BusinessTransactions.ReturnFromCommissionAgent Then
		Title = NStr("vi = 'Giấy đề nghị trả hàng từ người nhận ký gửi (tạo mới)';
					|ru = 'Заявка на возврат товаров от комиссионера (создание)';
					|en = 'Consignment pick-up request (create)'; fa = 'Consignment pick-up request (create)';
					|it = 'Dichiarazione di reso articoli dal commissionario (creazione)';
					|pl = 'Wniosek o zwrot towarów od komisanta (tworzenie)';
					|tr = 'Konsinyeden mal iadesi talebi (oluştur)'");
	ElsIf Object.BusinessOperation = Enums.BusinessTransactions.ReturnFromCustodian Then
		Title = NStr("vi = 'Giấy đề nghị trả hàng từ người cất giữ (tạo mới)';
					|ru = 'Заявка на возврат товаров от хранителя (создание)';
					|en = 'VMI pick-up request (create)'; fa = 'VMI pick-up request (create)';
					|it = 'Dichiarazione di reso articoli presso il magazzino (creazione)';
					|pl = 'Wniosek o zwrot towarów od depozytariusza (tworzenie)';
					|tr = 'VMI teslimi talebi (oluştur)'");
	Else
		Title = NStr("vi = 'Giấy đề nghị trả hàng từ người mua (tạo mới)';
					|ru = 'Заявка на возврат товаров от клиента (создание)';
					|en = 'Sales return request (create)'; fa = 'Sales return request (create)';
					|it = 'Dichiarazione di reso articoli dal cliente (creazione)';
					|pl = 'Wniosek o zwrot towarów od nabywca (tworzenie)';
					|tr = 'Müşteriden mal iade talebi (oluştur)'");
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
Procedure AddSBPPaymentStatusUpdateCommand()

	CommandParameters = CashServerLocalization.NewParametersOfSBPPaymentStatusUpdateCommand();
	CommandParameters.Parent = Items.PaymentGroup_2;
	CashServerLocalization.AddSBPPaymentStatusUpdateCommand(ThisObject, CommandParameters);

EndProcedure

&AtClient
Procedure Attachable_SBPPaymentVerification()

	CashClientLocalization.CheckSBPPayment(ThisObject, Object.Ref, Object.Counterparty);

EndProcedure

&AtServer
Function GetOrganizationSDefaultBankAccountServer()
	
	ParametersOfAccount = CashServer.ParametersForFillingOutOrganizationSBankAccount(Object.Organization);
	ParametersOfAccount.LineOfBusiness = Object.LineOfBusiness;
	ParametersOfAccount.ExcludeCurrencyAccounts = Object.ForeignCurrencyTransaction;
	ParametersOfAccount.Currency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Object.Organization);
	
	Return CashServer.GetOrganizationSDefaultBankAccount(ParametersOfAccount, Object.BankAccount);
	
EndFunction

#EndRegion

#Region Supply

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
			Items.SubstituteGoods.SelectedRows);
			
		UpdateColumnAvailableServer();
		
	Else
		
		Changes = ProvisionInDocumentsServer.SetAction(
			ActionCode,
			ThisObject,
			Items.SubstituteGoods.SelectedRows);
		
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
		Items.SubstituteGoods.CurrentRow,
		FormParameters.FieldsToFillIn);
		
	AfterFillingOutCollateral(Changes, FormParameters.Mode, FillParameters);
	TextProcessedLines = ProvisionInDocumentsServer.TextProcessedLines(Changes.Count());
	Return TextProcessedLines;
	
EndFunction

&AtClientAtServerNoContext
Function DocumentParametersForSoftwareActions(Form, SecurityOptionAndFlagSeparately, DateOfShipment)
	
	DocumentParameters = New Structure();
	DocumentParameters.Insert("Form",                              Form);
	DocumentParameters.Insert("Collection",                          Form.Object.SubstituteGoods);
	DocumentParameters.Insert("SecurityOptionAndFlagSeparately", SecurityOptionAndFlagSeparately);
	
	Return DocumentParameters;
	
EndFunction

&AtClient
Procedure HyperlinkStateOfProvisionClickGeneral()
	
	FormParameters = ProvisionInDocumentsClient.SecurityStatusHyperlinkClick(ThisObject);
	
	If Object.Status = PredefinedValue("Enum.StatusesOfRequestsForReturnOfGoodsFromCustomers.NotAgreedUpon")
			Or Object.Status = PredefinedValue("Enum.StatusesOfRequestsForReturnOfGoodsFromCustomers.ForReturn") Then
		
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

&AtClient
Procedure AddCollateralActionsOnClient(StructureOfActions, StringFields_)
	
	DocumentParameters = DocumentParametersForSoftwareActions(ThisObject, SecurityOptionAndFlagSeparately, Undefined);
	ProvisionInDocumentsClientServer.AddCollateralActions(StructureOfActions, StringFields_, DocumentParameters);
	
EndProcedure

&AtServer
Procedure AddCollateralActionsOnServer(StructureOfActions, StringFields_, DateOfShipment = Undefined)
	
	DocumentParameters = DocumentParametersForSoftwareActions(ThisObject, SecurityOptionAndFlagSeparately, DateOfShipment);
	ProvisionInDocumentsClientServer.AddCollateralActions(StructureOfActions, StringFields_, DocumentParameters);
	
EndProcedure

&AtServer
Procedure ReplacementProductsSoftwareOptionWhenModifiedOnServer(FillParameters)
	
	Changes = ProvisionInDocumentsServer.SupplyOptionOnChange(
		ThisObject,
		Items.SubstituteGoods.CurrentRow);
		
	Mode = ProvisionInDocumentsClientServer.ModeSelectActionDirectly();
	AfterFillingOutCollateral(Changes, Mode, FillParameters);
	
EndProcedure

&AtClient
Procedure SubstituteGoodsCollateralOptionWhenChangedAfterIssue(Response, AdditionalParameters) Export
	
	FillParameters = ProvisionInDocumentsClient.ParametersForProcessingShipmentDatesAfterFillingInCollateral(Response);
	ReplacementProductsSoftwareOptionWhenModifiedOnServer(FillParameters);
	
EndProcedure

&AtServer
Procedure SubstituteGoodsCancelSelectedLinesServer(SelectedRows)
	
	StructureOfActions = New Structure();
	AddCollateralActionsOnServer(StructureOfActions, "WarehouseIsRequired, DateOfShipmentRequired_");
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		ProcessingOfTabularFormsClientServer.CollectionItems(Object.SubstituteGoods, SelectedRows),
		StructureOfActions,
		Object.SubstituteGoods);

	ProvisionInDocumentsClientServer.FillInServiceDetails(Object.SubstituteGoods,
		DateOfShipmentRequired_, WarehouseIsRequired);
	CalculateTotalsOfRefundRequest(ThisObject);

	If SeriesSpecificationParameters.Substitutes_.UseItemsBatch Then
		FillInStatusesForSpecifyingSeriesServer("Substitutes_");
	EndIf;
	UpdateColumnAvailableServer();
	
	OnChangingWarehouseInTablePartReplacingGoodsServer();
	
EndProcedure

&AtServer
Procedure FillInServiceDetailsOfDocumentForm()
	
	DocumentParameters = DocumentParametersForSoftwareActions(ThisObject, SecurityOptionAndFlagSeparately, Undefined);
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
		Object.SubstituteGoods,
		Result,
		"AfterQuestionOfFillingPackageWithWholePackages");
	
	If Not QuestionAsked Then
		
		ProvisionInDocumentsClient.ShowQuestionUncheckShipByOneDate(
			ThisObject,
			Object.SubstituteGoods,
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
		Object.SubstituteGoods,
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
	
	Documents.RequestForReturnOfGoodsFromCustomer.AfterFillingOutCollateral(Object, Changes, Mode, FillParameters);
	SetVisibilityOfShippingDateFormElements();
	
	OrdersServer.RecalculateDependentPropsAfterSplittingRows(
		Changes, DependentDetailsThatReplaceProductsWithLine());
	
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
	
	ProvisionInDocumentsClientServer.FillInServiceDetails(
		Object.SubstituteGoods,
		DateOfShipmentRequired_,
		WarehouseIsRequired);
		
	OnChangingWarehouseInTablePartReplacingGoodsServer();
		
	CalculateTotalsOfRefundRequest(ThisObject);
	
EndProcedure

&AtClient
Procedure SubstituteGoodsFillInShipmentDate(Command)
	
	ArrayOfSelectedRows = Items.SubstituteGoods.SelectedRows;
	If ArrayOfSelectedRows.Count() > 0 Then
		DateOfShipment = Object.DateOfShipment;
		
		Notification = New CallbackDescription("SubstituteGoodsFillInShipmentDateCompletion", ThisObject, New Structure("ArrayOfSelectedRows", ArrayOfSelectedRows));
		
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
Procedure SubstituteGoodsFillInShipmentDateCompletion(SelectedDate, AdditionalParameters) Export
	
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
	
	If Object.Status = PredefinedValue("Enum.StatusesOfRequestsForReturnOfGoodsFromCustomers.NotAgreedUpon")
		Or Object.Status = PredefinedValue("Enum.StatusesOfRequestsForReturnOfGoodsFromCustomers.ForReturn") Then
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
	
	If Object.Status = PredefinedValue("Enum.StatusesOfRequestsForReturnOfGoodsFromCustomers.NotAgreedUpon")
		Or Object.Status = PredefinedValue("Enum.StatusesOfRequestsForReturnOfGoodsFromCustomers.ForReturn") Then
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

&AtClient
Procedure SubstituteGoodsIncludeStandAloneCollateral(Command)
	
	ProvidingSetAction("FLAG_UNITED");
	
EndProcedure

&AtClient
Procedure SubstituteGoodsTurnOffStandAloneCollateral(Command)
	
	ProvidingSetAction("FLAG_NOTABLE");
	
EndProcedure

&AtClient
Procedure SubstituteGoodsForCollateral(Command)
	
	ProvidingSetActionWithQuestion("ACTION_COOPERATION");
	
EndProcedure

&AtClient
Procedure ReserveReplacementItemsAsTheyArrive(Command)
	
	ProvidingSetAction("ACTION_RESERVATION_REFERENCES");
	
EndProcedure

&AtClient
Procedure ReplacementGoodsDoNotProvide(Command)
	
	ProvidingSetActionWithQuestion("ACTION_NOTABLE");
	
EndProcedure

&AtClient
Procedure ShipReplacementGoods(Command)
	
	ProvidingSetActionWithQuestion("ACTION_LOAD");
	
EndProcedure

&AtClient
Procedure ReserveReplacementGoods(Command)
	
	ProvidingSetActionWithQuestion("ACTION_RESERVE");
	
EndProcedure

#EndRegion

#Region ShippingDates

&AtServer
Procedure SetVisibilityOfShippingDateFormElements()

	Items.SubstituteGoodsDateOfShipment.Visible = Not Object.NotShipInInstallments
		And UseShipmentByRowsInSalesOrder
		And Not Object.ThisIsOrderAsInvoice;
	Items.DateOfShipment.Visible = Object.NotShipInInstallments;
	Items.SubstituteGoodsFillInShipmentDate.Visible = Not Object.NotShipInInstallments;

EndProcedure

&AtServer
Procedure FillInShipmentDateServer(DateOfShipment, ArrayOfSelectedRows)

	ProvisionInDocumentsServer.FillInDetailsInCollection(Object.SubstituteGoods, "DateOfShipment", DateOfShipment, ArrayOfSelectedRows);
	ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisForm, "Goods.DateOfShipment");
	VATTaxationOnChangeServer(True);
	
EndProcedure

&AtServer
Procedure NotShipInInstallmentsOnChangeServer()

	If Object.NotShipInInstallments Then
		Object.DateOfShipment = ProvisionInDocumentsServer.MaximumValueInCollection(Object.SubstituteGoods, "DateOfShipment", '00010101');
		ProvisionInDocumentsServer.FillInDetailsInCollection(Object.SubstituteGoods, "DateOfShipment", Object.DateOfShipment);
	EndIf;

	SetVisibilityOfShippingDateFormElements();

EndProcedure

#EndRegion

#Region ControlOfInconsistentChanges

// Parameters:
//	Item - FormGroup, FormTable, FormField, FormButton - FormItem
&AtClient
Procedure ControlOfNonConsistentChangesHandleEventOnChange(Item)
	If Item.Name = "Date" Then
		DateOnChange(Item);
	ElsIf Item.Name = "Terms" Then
		TermsOnChange(Item);
	ElsIf Item.Name = "Contract" Then
		ContractOnChange(Item);
	ElsIf Item.Name = "Currency" Then
		CurrencyOnChange(Item);
	ElsIf Item.Name = "PriceIncludesVAT" Then
		PriceIncludesVATOnChange(Item);
	ElsIf Item.Name = "VATTaxation" Then
		VATTaxationOnChange(Item);
	ElsIf Item.Name = "Organization" Then
		OrganizationOnChange(Item);
	ElsIf Item.Name = "Partner" Then
		PartnerOnChange(Item);
	ElsIf Item.Name = "Counterparty" Then
		CounterpartyOnChange(Item);
	ElsIf Item.Name = "Warehouse" Then
		WarehouseOnChange(Item);
	ElsIf Item.Name = "NotShipInInstallments" Then
		NotShipInInstallmentsOnChange(Item);
	ElsIf Item.Name = "DateOfShipment" Then
		DateOfShipmentOnChange(Item);
	ElsIf Item.Name = "BusinessOperation" Then
		BusinessOperationOnChange(Item);
	ElsIf Item.Name = "DocumentSalesOfGoodsAndServices" Then
		DocumentSalesOfGoodsAndServicesOnChange(Item);
	ElsIf Item.Name = "OneDateReceipt" Then
		OneDateReceiptOnChange(Item);
	ElsIf Item.Name = "DateOfReceipt" Then
		DateOfReceiptOnChange(Item);
	ElsIf Item.Name = "ApprovalDate" Then 
		ApprovalDateOnChange(Item);
	ElsIf Item.Name = "CashRegisterReceipt" Then
		CashRegisterReceiptOnChange(Item);
	ElsIf Item.Name = "ToReturnReusablePackage" Then
		ToReturnReusablePackageOnChange(Item);
	ElsIf Item.Name = "PackageDepositIsRequired" Then
		PackageDepositIsRequiredOnChange(Item);
	ElsIf Item.Name = "Department" Then
		DepartmentOnChange(Item);
	ElsIf Item.Name = "CompensationMethod" Then
		CompensationMethodOnChange(Item);
	ElsIf Item.Name = "ReusablePackageReturn" Then
		ReusablePackageReturnOnChange(Item);
	ElsIf Item.Name = "ReturnedGoodsProducts" Then
		ReturnedGoodsProductsOnChange(Item);
	ElsIf Item.Name = "ReturnedGoodsDamage" Then
		ReturnedGoodsDamageOnChange(Item);
	ElsIf Item.Name = "ReturnedGoodsProductsRecordingAsReceived" Then
		ReturnedGoodsProductsRecordingAsReceivedOnChange(Item);
	ElsIf Item.Name = "ReturnedGoodsCharacteristic" Then
		ReturnedGoodsCharacteristicOnChange(Item);
	ElsIf Item.Name = "ReturnedGoodsNumberOfPackages" Then
		ReturnedGoodsNumberOfPackagesOnChange(Item);
	ElsIf Item.Name = "ReturnedGoodsPackage" Then
		ReturnedGoodsPackageOnChange(Item);
	ElsIf Item.Name = "ReturnedGoodsPriceKind" Then
		ReturnedGoodsPriceKindOnChange(Item);
	ElsIf Item.Name = "ReturnedGoodsPrice" Then
		ReturnedGoodsPriceOnChange(Item);
	ElsIf Item.Name = "ReturnedGoodsVATRate" Then
		ReturnedGoodsVATRateOnChange(Item);
	ElsIf Item.Name = "ReturnedGoodsSum" Then
		ReturnedGoodsSumOnChange(Item);
	ElsIf Item.Name = "ReturnedGoodsDateOfReceipt" Then
		ReturnedGoodsDateOfReceiptOnChange(Item);
	ElsIf Item.Name = "ReturnedGoodsWarehouse" Then
		ReturnedGoodsWarehouseOnChange(Item);
	ElsIf Item.Name = "ReturnedGoodsSeries" Then
		ReturnedGoodsSeriesOnChange(Item);
	ElsIf Item.Name = "ReturnedGoodsDocumentSalesOfGoodsAndServices" Then
		ReturnedGoodsDocumentSalesOfGoodsAndServicesOnChange(Item);
	ElsIf Item.Name = "ReturnedGoodsToControlQuality" Then
		ReturnedGoodsToControlQualityOnChange(Item);
	ElsIf Item.Name = "ReturnedGoodsQualityConfirmationDate" Then
		ReturnedGoodsQualityConfirmationDateOnChange(Item);
	ElsIf Item.Name = "SubstituteGoodsProducts" Then
		SubstituteGoodsProductsOnChange(Item);
	ElsIf Item.Name = "SubstituteGoodsCharacteristic" Then
		SubstituteGoodsCharacteristicOnChange(Item);
	ElsIf Item.Name = "SubstituteGoodsNumberOfPackages" Then
		SubstituteGoodsNumberOfPackagesOnChange(Item);
	ElsIf Item.Name = "SubstituteGoodsPackage" Then
		SubstituteGoodsPackageOnChange(Item);
	ElsIf Item.Name = "SubstituteGoodsWithAssignment" Then
		SubstituteGoodsWithAssignmentOnChange(Item);
	ElsIf Item.Name = "SubstituteGoodsWarehouse" Then
		SubstituteGoodsWarehouseOnChange(Item);
	ElsIf Item.Name = "SubstituteGoodsSeries" Then
		SubstituteGoodsSeriesOnChange(Item);
	ElsIf Item.Name = "SubstituteGoodsPriceKind" Then
		SubstituteGoodsPriceKindOnChange(Item);
	ElsIf Item.Name = "SubstituteGoodsPrice" Then
		SubstituteGoodsPriceOnChange(Item);
	ElsIf Item.Name = "SubstituteGoodsDepartment" Then
		SubstituteGoodsDepartmentOnChange(Item);
	ElsIf Item.Name = "SubstituteGoodsVATRate" Then
		SubstituteGoodsVATRateOnChange(Item);
	ElsIf Item.Name = "SubstituteGoodsPercentRateOfManualDiscount" Then
		SubstituteGoodsPercentRateOfManualDiscountOnChange(Item);
	ElsIf Item.Name = "SubstituteGoodsManualDiscount" Then
		SubstituteGoodsManualDiscountOnChange(Item);
	ElsIf Item.Name = "SubstituteGoodsSum" Then
		SubstituteGoodsSumOnChange(Item);
	ElsIf Item.Name = "SubstituteGoodsVATAmount" Then
		SubstituteGoodsVATAmountOnChange(Item);
	Else
		TMCommonUseClient.MonitoringNonConsistentChangesCauseException(ThisForm, Item);
	EndIf;
EndProcedure

// Parameters:
//	Command - FormCommand - 
&AtClient
Procedure ControlOfNonConsistentChangesHandleCommandEvent(Command)
	If Command.Name = Commands.ToInsertTheReturnedString.Name Then
		ToInsertTheReturnedString(Command);
	ElsIf Command.Name = Commands.SplitTheStringReturned.Name Then
		SplitTheStringReturned(Command);
	ElsIf Command.Name = Commands.SetContentReturnedGoods.Name Then
		SetContentReturnedGoods(Command);
	ElsIf Command.Name = Commands.SelectTransferredGoods.Name Then
		SelectTransferredGoods(Command);
	ElsIf Command.Name = Commands.ReturnedGoodsAddReusablePackage.Name Then
		ReturnedGoodsAddReusablePackage(Command);
	ElsIf Command.Name = Commands.ReturnedGoodsFillInVATRATE.Name Then
		ReturnedGoodsFillInVATRATE(Command);
	ElsIf Command.Name = Commands.InsertSubstituteLines.Name Then
		InsertSubstituteLines(Command);
	ElsIf Command.Name = Commands.SplitRow.Name Then
		SplitRow(Command);
	ElsIf Command.Name = Commands.SetContentSubstituteGoods.Name Then
		SetContentSubstituteGoods(Command);
	ElsIf Command.Name = Commands.AddPaymentWithBonusPoints.Name Then
		AddPaymentWithBonusPoints(Command);
	ElsIf Command.Name = Commands.CancelPaymentWithBonusPoints.Name Then
		CancelPaymentWithBonusPoints(Command);
	ElsIf Command.Name = Commands.SubstituteGoodsAddReusablePackage.Name Then
		SubstituteGoodsAddReusablePackage(Command);
	ElsIf Command.Name = Commands.FillInTheDepartment.Name Then
		FillInTheDepartment(Command);
	ElsIf Command.Name = Commands.ReplacementGoodsFillInVATRate.Name Then
		ReplacementGoodsFillInVATRate(Command);
	ElsIf Command.Name = Commands.ReturnedGoodsFillInPricesByAgreement.Name Then
		ReturnedGoodsFillInPricesByAgreement();
	ElsIf Command.Name = Commands.ReturnedItemsFillInPricesOfSelectedRowsByPriceType.Name Then
		ReturnedItemsFillInPricesOfSelectedRowsByPriceType(Command);
	ElsIf Command.Name = Commands.ReturnedProductsBarcodeSearch.Name Then
		ReturnedProductsBarcodeSearchExecute(Command);
	ElsIf Command.Name = Commands.ImportDataFromPDT.Name Then
		ImportDataFromPDT(Command);
	ElsIf Command.Name = Commands.ToPickUpTheGoodsInImplementations.Name Then
		ToPickUpTheGoodsInImplementations(Command);
	ElsIf Command.Name = Commands.FillInSalesAndPrices.Name Then
		FillInSalesAndPrices(Command);
	ElsIf Command.Name = Commands.ReturnOfSpoiledGoods.Name Then
		ReturnOfSpoiledGoods(Command);
	ElsIf Command.Name = Commands.ImportReturnedGoodsFromExternalFile.Name Then
		ImportFromExternalFile(Command);
	ElsIf Command.Name = Commands.SubstituteProductsCalculateDiscountMarkups.Name Then
		CalculateDiscountsMarkups(Command);
	ElsIf Command.Name = Commands.ReplacementProductsCancelManualDiscounts.Name Then
		CancelManualDiscounts(Command);
	ElsIf Command.Name = Commands.SubstituteProductsAssignAManualDiscount.Name Then
		AssignAManualDiscount(Command);
	ElsIf Command.Name = Commands.SubstituteItemsAssignAManualDiscountToSelectedLines.Name Then
		AssignAManualDiscountForSelectedLines(Command);
	ElsIf Command.Name = Commands.SubstituteGoodsAssignAutomaticDiscounts.Name Then
		AssignAutomaticDiscounts(Command);
	ElsIf Command.Name = Commands.ToReadLoyaltyCard.Name Then
		ToReadLoyaltyCard(Command);
	ElsIf Command.Name = Commands.SubstituteGoodsFillInPricesByAgreement.Name Then
		SubstituteGoodsFillInPricesByAgreement();
	ElsIf Command.Name = Commands.SubstituteProductsFillInPricesOfSelectedRowsByTypeOfPrices.Name Then
		SubstituteProductsFillInPricesOfSelectedRowsByTypeOfPrices(Command);
	ElsIf Command.Name = Commands.ReplacementProductsOpenSelection.Name Then
		ReplacementProductsOpenSelection(Command);
	ElsIf Command.Name = Commands.UploadReplacementProductsFromAnExternalFile.Name Then
		ImportFromExternalFile(Command);
	ElsIf Command.Name = Commands.SubstituteGoodsAddReusablePackage.Name Then
		SubstituteGoodsAddReusablePackage(Command);
	ElsIf Command.Name = Commands.ReplacementProductsBarcodeSearch.Name Then
		ReplacementProductsBarcodeSearchExecute(Command);
	ElsIf Command.Name = Commands.ImportDataFromPDT.Name Then
		ImportDataFromPDT(Command);
	ElsIf Command.Name = Commands.FillInSubstituteGoodsByReturnedOnes.Name Then
		FillInSubstituteGoodsByReturnedOnes(Command);
	Else
		TMCommonUseClient.MonitoringNonConsistentChangesCauseException(ThisForm, Command);
	EndIf;
EndProcedure

// Parameters:
//	Item - FormGroup, FormTable, FormField, FormButton - FormItem
&AtClient
Procedure ControlOfNonConsistentChangesHandlePushEvent(Item)
	TMCommonUseClient.MonitoringNonConsistentChangesCauseException(ThisForm, Item);
EndProcedure

// Parameters:
//	Item - FormGroup, FormTable, FormField, FormButton - FormItem
&AtClient
Procedure ControlOfNonConsistentChangesHandleEventBeforeStartingChange(Item, Cancel)
	TMCommonUseClient.MonitoringNonConsistentChangesCauseException(ThisForm, Item);
EndProcedure

// Parameters:
//	Item - FormGroup, FormTable, FormField, FormButton - FormItem
&AtClient
Procedure ControlOfNonConsistentChangesHandleEventBeforeDeletion(Item, Cancel)
	If Item.Name = "ReturnedGoods" Then
		ReturnedGoodsBeforeDeleteRow(Item, Cancel);
	ElsIf Item.Name = "SubstituteGoods" Then
		SubstituteGoodsBeforeDeleteRow(Item, Cancel);
	Else
		TMCommonUseClient.MonitoringNonConsistentChangesCauseException(ThisForm, Item);
	EndIf;
EndProcedure

// Parameters:
//	Item - FormGroup, FormTable, FormField, FormButton - FormItem
&AtClient
Procedure ControlOfNonConsistentChangesHandleEventBeforeStartingAdding(Item, Cancel, Copy, Parent, Var_Group, Parameter)
	If Item.Name = "ReturnedGoods" Then
		ReturnedGoodsBeforeAddRow(Item, Cancel, Copy, Parent, Var_Group, Parameter);
	ElsIf Item.Name = "SubstituteGoods" Then
		SubstituteGoodsBeforeAddRow(Item, Cancel, Copy, Parent, Var_Group, Parameter);
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
		ControlOfNonConsistentChangesHandleEventBeforeStartingAdding(Item, Cancel, Copy, Parent, Var_Group, Undefined);
	EndIf;

EndProcedure

&AtClient
Procedure Attachable_WhenChangingDetailsDependingOnStatus()
	
	EditServerDocument();
	TMCommonUseClient.AfterChangingPropsDependentOnStatus(ThisForm);
	
EndProcedure

&AtServer
Procedure PrepareFillSetSeriesVisibility()
	
	SeriesSpecificationParameters = New FixedStructure(ProductsServer.SeriesSpecificationParameters(Object, Documents.RequestForReturnOfGoodsFromCustomer));
	
	ProductsServer.FillInStatusesForSpecifyingSeries(Object,SeriesSpecificationParameters.Substitutes_);
	ProductsServer.FillInStatusesForSpecifyingSeries(Object,SeriesSpecificationParameters.Returned_);
	
	SetVisibilityOfSeriesElements();
	
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

#EndRegion

#Region Damage

&AtServer
Function CheckDisableConfigureFormForCorruption()
	
	ThereAreLinesWithCorruption = Object.ReturnedGoods.FindRows(New Structure("Damage", True)).Count() > 0;
	If Not ThereAreLinesWithCorruption Then
		
		Object.ReturnOfSpoiledGoods = False;
		CustomizeFormElements();
		
	EndIf;
	
	Return ThereAreLinesWithCorruption;
	
EndFunction

&AtServer
Procedure ClearDisableConfigureFormForCorruption()
	
	Object.ReturnOfSpoiledGoods = False;
	
	RowsToProcess = New Array();
	
	For Each RowOfTables In Object.ReturnedGoods Do
		If RowOfTables.Damage Then
			RowsToProcess.Add(RowOfTables);
		EndIf;
		RowOfTables.Damage                     = False;
		RowOfTables.ProductsRecordingAsReceived = Catalogs.Products.EmptyRef();
		RowOfTables.CharacteristicRecordingAsReceived = Catalogs.ItemsCharacteristics.EmptyRef();
	EndDo;
	
	StructureOfActions = New Structure();
	StructureOfActions.Insert("FillInCheckQualityDateOfQualityConfirmation", CacheQualityControl);
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		RowsToProcess,
		StructureOfActions,
		Object.ReturnedGoods);
	
	If SeriesSpecificationParameters.Returned_.UseItemsBatch Then
		For Each RowOfTables In Object.ReturnedBatch Do
			RowOfTables.ProductsRecordingAsReceived   = Catalogs.Products.EmptyRef();
			RowOfTables.CharacteristicRecordingAsReceived = Catalogs.ItemsCharacteristics.EmptyRef();
		EndDo;
	EndIf;
	
	CustomizeFormElements();
	
EndProcedure

&AtClient
Procedure ReturnedGoodsBeforeAddRow(Item, Cancel, Copy, Parent, Var_Group, Parameter)
	
	If Copy Then
		SetsClient.BeforeDeletingRowOfTablePart(ThisForm, "ReturnedGoods", Cancel, True);
	EndIf;
	
EndProcedure

&AtClient
Procedure SubstituteGoodsBeforeAddRow(Item, Cancel, Copy, Parent, Var_Group, Parameter)
	
	If Copy Then
		SetsClient.BeforeDeletingRowOfTablePart(ThisForm, "SubstituteGoods", Cancel, True);
	EndIf;
	
	DiscountsMarkupsFillingClient.ResetDiscountsCalculatedFlag(ThisForm);
	
EndProcedure

&AtClient
Procedure SetContentReturnedGoods(Command)
	
	RowSelected = Items.ReturnedGoods.CurrentRow;
	
	If RowSelected = Undefined Then
		Return;
	EndIf;
	
	CurrentRow = Object.ReturnedGoods.FindByID(RowSelected);
	
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
	KitParameters.Insert("DocumentSalesOfGoodsAndServices", CurrentRow.DocumentSalesOfGoodsAndServices);
	KitParameters.Insert("DialColumns", SetColumnsReturnItems(ThisForm));
	
	SetAddressInTemporaryStorage = SetAddressInTemporaryStorage(KitParameters, "ReturnedGoods");
	
	OpeningParameters = New Structure;
	OpeningParameters.Insert("AddressInTempStorage", SetAddressInTemporaryStorage);
	OpeningParameters.Insert("ProductsInSet", CurrentRow.ProductsInSet);
	OpeningParameters.Insert("ItemVariantOfSet", CurrentRow.ItemVariantOfSet);
	OpeningParameters.Insert("DocumentSalesOfGoodsAndServices", CurrentRow.DocumentSalesOfGoodsAndServices);
	OpeningParameters.Insert("PriceIncludesVAT", Object.PriceIncludesVAT);
	OpeningParameters.Insert("VATTaxation", Object.VATTaxation);
	OpeningParameters.Insert("Currency", Object.Currency);
	OpeningParameters.Insert("Partner", Object.Partner);
	OpeningParameters.Insert("Terms", Object.Terms);
	OpeningParameters.Insert("Date", Object.Date);
	OpeningParameters.Insert("Ref", Object.Ref);
	OpeningParameters.Insert("FilterByProductType", ProductsClientServer.SelectionByProductMultiTurnContainer());
	OpeningParameters.Insert("Warehouse", Object.Warehouse);
	OpeningParameters.Insert("HideCommandRemainingQuantityInWarehouses", False);
	If ValueIsFilled(Object.CashRegisterReceipt) Then
		OpeningParameters.Insert("PriceKind", ThisForm.CashReceiptPriceType);
		OpeningParameters.Insert("ProhibitPriceEditing", True);
	EndIf;	
	OpeningParameters.Insert("Organization", Object.Organization);
	
	OpenForm("DataProcessor.EditSet.Form.Form", OpeningParameters, ThisForm, UUID);
	
EndProcedure

&AtClient
Procedure SetContentSubstituteGoods(Command)
	
	RowSelected = Items.SubstituteGoods.CurrentRow;
	
	If RowSelected = Undefined Then
		Return;
	EndIf;
	
	CurrentRow = Object.SubstituteGoods.FindByID(RowSelected);
	
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
	KitParameters.Insert("DialColumns", SetColumnsReplacingProducts(ThisForm));
	
	SetAddressInTemporaryStorage = SetAddressInTemporaryStorage(KitParameters, "SubstituteGoods");
	
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
	OpeningParameters.Insert("TSName", "SubstituteGoods");
	OpeningParameters.Insert("Warehouse", Object.Warehouse);
	OpeningParameters.Insert("HideCommandRemainingQuantityInWarehouses", False);
	If Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.ReturnFromCommissionAgent")
		Or Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.ReturnFromCustodian") Then
		OpeningParameters.Insert("FilterByProductType", ProductsClientServer.SelectionByProductMultiTurnContainer());
	EndIf;
	If ValueIsFilled(Object.CashRegisterReceipt) Then
		OpeningParameters.Insert("PriceKind", ThisForm.CashReceiptPriceType);
		OpeningParameters.Insert("ProhibitPriceEditing", True);
	EndIf;	
	OpeningParameters.Insert("Organization", Object.Organization);
	
	OpenForm("DataProcessor.EditSet.Form.Form", OpeningParameters, ThisForm, UUID);
	
EndProcedure

&AtServer
Procedure FillInSalesVATTaxation()
	
	FillParameters = Documents.RequestForReturnOfGoodsFromCustomer.ParametersForFillingInSalesVATTaxation(Object);
	VATAccountingERP.FillInSalesVATTaxation(Object.VATTaxation, FillParameters, VATAccountingCachedParameterValues);
	VATAccountingERP.FillInSalesVATTaxSelectionList(Items.VATTaxation, Object.VATTaxation, FillParameters, VATAccountingCachedParameterValues); 
	
EndProcedure

#EndRegion

#Region Sets

&AtServer
Function AddToFullSet(TSName)
	
	TabularSection = Object[TSName];
	SelectedRows = Items[TSName].SelectedRows;
	
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
Function SetColumnsReturnItems(Form)
	
	Columns = New Array;
	Columns.Add("Products");
	Columns.Add("Characteristic");
	
	Columns.Add("Price");
	Columns.Add("PriceKind");
	Columns.Add("Package");
	Columns.Add("Count");
	Columns.Add("NumberOfPackages");
	
	Columns.Add("Canceled");
	
	Columns.Add("VATRate");
	Columns.Add("VATAmount");
	Columns.Add("AmountIncludingVAT");
	Columns.Add("Sum");
	
	Columns.Add("DocumentSalesOfGoodsAndServices");
	
	Return Columns;
	
EndFunction

&AtClientAtServerNoContext
Function SetColumnsReplacingProducts(Form)
	
	Columns = New Array;
	Columns.Add("Products");
	Columns.Add("Characteristic");
	
	Columns.Add("Price");
	Columns.Add("PriceKind");
	Columns.Add("Package");
	Columns.Add("Count");
	Columns.Add("NumberOfPackages");
	
	If Form.Object.BusinessOperation <> PredefinedValue("Enum.BusinessTransactions.TransferToCommissionAgent") Then
		If Form.UseDiscountAdjustmentsInSales Then
			Columns.Add("PercentRateOfManualDiscount");
			Columns.Add("ManualDiscount");
		EndIf;
		If Form.UseDiscountsMarkupsInSales Then
			Columns.Add("PercentRateOfAutomaticDiscountMarkup");
			Columns.Add("DiscountMarkupAmount");
		EndIf;
	EndIf;
	
	Columns.Add("Canceled");
	
	If Form.UseReasonsForSalesOrderCancellations Then
		Columns.Add("CancellationReason");
	EndIf;
	
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
		SetsClient.WhenRemovingComponents(ThisForm, AdditionalParameter.TSName, AdditionalParameter);
	ElsIf SetsClient.DeleteEntireSetAction(Action) Then
		WhenRemovingComponentsOnServer(AdditionalParameter.TSName, AdditionalParameter);
	EndIf;
	
	CalculateTotalsOfRefundRequest(ThisForm);
	
EndProcedure

&AtServer
Procedure WhenRemovingComponentsOnServer(TSName, AdditionalParameter)
	SetsServer.WhenRemovingComponents(ThisForm, TSName, AdditionalParameter);
EndProcedure

&AtServer
Function SetAddressInTemporaryStorage(Var_Parameters, TSName)
	
	Return SetsServer.SetAddressInTemporaryStorage(ThisForm, Var_Parameters, TSName);
	
EndFunction

&AtServer
Procedure AtEndOfEditingSet(AddressInTempStorage)
	
	CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	
	Data = GetFromTempStorage(AddressInTempStorage);
	
	DataParameters = New Structure;
	DataParameters.Insert("Data", Data);
	
	If Data.TSName = "SubstituteGoods" Then
		
		StructureOfActionsWithAddedStrings = New Structure;
		StructureOfActionsWithAddedStrings.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
		StructureOfActionsWithAddedStrings.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));
		StructureOfActionsWithAddedStrings.Insert("FillInNoReturnContainerAttribute", Object.ToReturnReusablePackage);
		StructureOfActionsWithAddedStrings.Insert("FillInCanceledWithoutReturnableContainerAttribute", Object.ToReturnReusablePackage);
		StructureOfActionsWithAddedStrings.Insert("FillInDuplicateDependentDetails", DependentDetailsReplacingGoods());
		StructureOfActionsWithAddedStrings.Insert("CheckFillWarehouse",
			BatchProcessingOfTablePartClientServer.GetWarehouseFillStructureInTSLine(Object, WarehouseGroup_));
		
		AddCollateralActionsOnServer(StructureOfActionsWithAddedStrings,
			"SupplyOption,WarehouseIsRequired,DateOfShipmentRequired_");
		
		StructureOfActionsWithModifiedStrings = New Structure;
		StructureOfActionsWithModifiedStrings.Insert("FillInDuplicateDependentDetails", DependentDetailsReplacingGoods());
		
		DataParameters.Insert("StructureOfActionsWithModifiedStrings", StructureOfActionsWithModifiedStrings);
		DataParameters.Insert("StructureOfActionsWithAddedStrings", StructureOfActionsWithAddedStrings);
		
		DataParameters.Insert("DialColumns", SetColumnsReplacingProducts(ThisForm));
		SetsServer.AtEndOfEditingSet(ThisForm, "SubstituteGoods", DataParameters);
		UpdateColumnAvailableServer();
	
	Else
		
		StructureOfActionsWithAddedStrings = New Structure;
		StructureOfActionsWithAddedStrings.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
		StructureOfActionsWithAddedStrings.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));
		StructureOfActionsWithAddedStrings.Insert("FillInNoReturnContainerAttribute", Object.ToReturnReusablePackage);
		StructureOfActionsWithAddedStrings.Insert("FillInCanceledWithoutReturnableContainerAttribute", Object.ToReturnReusablePackage);
		StructureOfActionsWithAddedStrings.Insert("FillInDuplicateDependentDetails", DependentDetailsReturnedGoods());
		StructureOfActionsWithAddedStrings.Insert("FillInCheckQualityDateOfQualityConfirmation",
			CacheQualityControl);
		StructureOfActionsWithAddedStrings.Insert("CheckFillWarehouse",
			BatchProcessingOfTablePartClientServer.GetWarehouseFillStructureInTSLine(Object, WarehouseGroup_));
		
		StructureOfActionsWithModifiedStrings = New Structure;
		StructureOfActionsWithModifiedStrings.Insert("FillInDuplicateDependentDetails", DependentDetailsReturnedGoods());
		StructureOfActionsWithModifiedStrings.Insert("FillInCheckQualityDateOfQualityConfirmation",
			CacheQualityControl);
		
		DataParameters.Insert("StructureOfActionsWithModifiedStrings", StructureOfActionsWithModifiedStrings);
		DataParameters.Insert("StructureOfActionsWithAddedStrings", StructureOfActionsWithAddedStrings);
		
		DataParameters.Insert("DialColumns", SetColumnsReturnItems(ThisForm));
		SetsServer.AtEndOfEditingSet(ThisForm, "ReturnedGoods", DataParameters);
		
	EndIf;
	
	CalculateTotalsOfRefundRequest(ThisForm);
	
EndProcedure

&AtClient
Procedure CalculationsClick(Item, StandardProcessing)
	
	ARAPAccountingClient.CalculationsClick(ThisForm, Item, StandardProcessing);
	
EndProcedure

#EndRegion

#Region Localization

&AtServer
Procedure CheckCorrectAvailabilityOfDiscountsPaymentsWithBonusPointsLocalization()
	
	
EndProcedure

&AtClient
Procedure AddPriceControlParameterForIDCLocalizationToForm(Form, FormParameters)
	
	
EndProcedure

&AtClient
Procedure SubstituteGoodsBeforeRowChangeLocalization(Item, Cancel)
	
	
EndProcedure

&AtClient
Procedure ReplacementGoodsAddFormParametersSelectionLocalization(FormParameters)
	
	
EndProcedure

&AtServer
Procedure AddDiscountParametersLocalization(DiscountParameters)
	
	
EndProcedure

&AtServer
Procedure UpdateSalesTagForTobaccoProductsOnlyByMRCLocalization(Form)
	
	
EndProcedure

#EndRegion

&AtServer
Procedure SetVisibilityOfPartnerField()
	
	CLVisibility = Items.ToReadLoyaltyCardClient.Visible;
	If CLVisibility Then
		CLVisibility = GetFunctionalOption("UseLoyaltyCards");
	EndIf;
	
	Items.PartnerWithoutCL.Visible = Not CLVisibility;
	Items.Partner.Visible      = CLVisibility;
	
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
Procedure FillInSalesAndPricesServer()
	
	FillInSalesAndPricesOnServer();
	CalculateTotalsOfRefundRequest(ThisForm);
	UpdateInformationOnImplementations();
	
EndProcedure

&AtClient
Procedure Attachable_ProcessObjectEntry()
	
	TMCommonUseClient.ProcessObjectEntryInForm(ThisObject, ParametersForRecording);
	
EndProcedure

&AtServer
Procedure SetVisibilityOfElementsOfLoyaltyBonusProgram()
	
	Items.GroupProductsBonusPoints.Visible = UseLoyaltyPrograms;
	Items.SubstituteGoodsAmountOfBonusPointsToDeductionInCurrency.Visible = UseLoyaltyPrograms;
	Items.SubstituteGoodsAmountOfEarnedBonusPointsInCurrency.Visible = UseLoyaltyPrograms;
	
EndProcedure

&AtServer
Procedure SetPropertiesOfOutdatedCommissionUsageComment()
	
	Items.CommentUsingOutdatedCommission.Title = ConsignmentSalesServer.CommentUsingOutdatedCommission();
	Items.GroupCommentUsingOutdatedCommission.Visible = Not ConsignmentSales25
		And Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.ReturnFromCommissionAgent")
		And (ValueIsFilled(Object.Terms) Or ValueIsFilled(Object.Contract));
	
EndProcedure
	
&AtServer
Procedure WhenChangingElementLocalization(Form, Item);
	
	
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
	ElsIf Item.Name = "sh_ShamsiInput_DateOfReceipt" Then
		DateOfReceiptOnChange(Items.DateOfReceipt);
	ElsIf Item.Name = "sh_ShamsiInput_DateOfShipment" Then
		DateOfShipmentOnChange(Items.DateOfShipment);
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
