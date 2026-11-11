#Region Variables

&AtClient
Var CachedValues; //used by the mechanism for processing changes in PM details

&AtClient
Var ParametersForRecording Export;

#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	SetConditionalAppearance();
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;

	InfobaseUpdate.CheckObjectProcessed(Object, ThisObject);
	
	TMCommonUse.CustomizePeripherals(ThisForm);
	
	// Handler of the "Versioning of objects" mechanism
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	
	
	// Handler of the "Properties" mechanism
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("Object", Object);
	AdditionalParameters.Insert("ItemForPlacementName", "GroupAdditionalAttributes");
	AdditionalParameters.Insert("DeferredInitialization", True);
	PropertyManager.OnCreateAtServer(ThisForm, AdditionalParameters);
	
	// Handler of the "Destination" mechanism
	Catalogs.Assignments.DocumentFormWhenCreatedOnServer(ThisForm);
	
	UseDiscountAdjustmentsInPurchases           = GetFunctionalOption("UseDiscountAdjustmentsInPurchases");
	UseReasonsForPurchaseOrderCancellations = GetFunctionalOption("UseReasonsForPurchaseOrderCancellations");
	UseTermsOfPurchases         = GetFunctionalOption("UseTermsOfPurchases");
	
	FillOperationSelectionList();
	
	If Not ValueIsFilled(Object.Ref) Then
		OnReadCreateAtServer();
	EndIf;
	
	UseStatuses = GetFunctionalOption("UsePurchaseOrderStatuses");
	
	PurchasesServer.SetModeForSelectingGroupsOfWarehouseItems(Items.Warehouse);
	TMCommonUseClientServer.SetFormItemProperty(Items, "BaseGroup_", "Visible", ValueIsFilled(Object.DocumentBasis));
	
	Items.Warehouse.Visible       = GetFunctionalOption("UseSeveralWarehouses");
	
	Items.GoodsGroupCanceled.Visible                      = GetFunctionalOption("UseReasonsForPurchaseOrderCancellations");
	Items.ProductsCanceledCancellationReasonsAreNotUsed.Visible = Not GetFunctionalOption("UseReasonsForPurchaseOrderCancellations");
	
	If Not GetFunctionalOption("UseWarehousesInTabularSectionsOfPurchaseDocuments") And Not GetFunctionalOption("UseBusinessUnits") Then
		Items.ProductsGroupRecipient.Visible = False;
	ElsIf Not WarehouseGroup_ Then
		Items.ProductsGroupRecipient.Title = NStr("vi = 'Bộ phận-nơi nhận';
													|ru = 'Подразделение-получатель';
													|en = 'Receiving business unit'; fa = 'واحد تجاری دریافت‌کننده';
													|it = 'Reparto-destinatario';
													|pl = 'Receiving business unit';
													|tr = 'Alıcı departman'");
	EndIf;
	
	If ClientApplication.CurrentInterfaceVariant() = ClientApplicationInterfaceVariant.Version8_2 Then
		Items.GroupInTotal.BackColor = New Color();
	EndIf;
	
	Items.CloseOrder.Enabled = AccessRight("Update",Metadata.Documents.PurchaseOrder);
	
	ARAPAccountingFormWork.FormWhenCreatedOnServer(ThisForm);
	NotifyAboutCreationOfCalculationObject = Parameters.NotifyAboutCreationOfCalculationObject;
	RightToReadSubstitutes = GetFunctionalOption("UseAlternativeMaterials")
						  And AccessRight("Read", Metadata.InformationRegisters.AlternativeMaterials);
	
	Items.GoodsSelectSubstitutes.Visible = RightToReadSubstitutes;
	SetAvailabilityOfClipboardCommands();
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject);
	// End IntegrationWith1CDocumentManagementSubsystem


	Items.DecorationEDOState.Visible = GetFunctionalOption("UseElectronicDocumentExchangeWithCounterparties");
	
	
	
		
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	
	ItemsAndDimensionsSelectionParameters = Documents.PurchaseOrder.ItemsAndDimensionsSelectionParameters(Object.BusinessOperation);
	IncomeAndExpensesServer.OnCreateAtServer(ThisObject, ItemsAndDimensionsSelectionParameters);
	

	// StandardSubsystems.FilesOperations
	HyperlinkParameters = FilesOperations.FilesHyperlink();
	HyperlinkParameters.Location = "CommandBar";
	FilesOperations.OnCreateAtServer(ThisObject, HyperlinkParameters);
	// End StandardSubsystems.FilesOperations
	
	OptionOfExecutionOfContractOfPurchases = PurchasesServer.GetVariantOfProcurementContract(Object.Contract);
	OptionOfProcessingDocumentsForServices = PurchasesServer.GetVariantOfRegistrationOfDocumentsForAdmissionToServices(Object.Contract);
	EnterpriseCalendar = Constants.MainEnterpriseCalendar.Get();

	VATAccountingERP.SetVisibilityOfCommandAndFillInVATRate(ThisObject);

	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)

	// StandardSubsystems.AccessManagement
	AccessManagement.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.AccessManagement
	
	OnReadCreateAtServer();
	PropertyManager.OnReadAtServer(ThisForm, CurrentObject);

	ARAPAccountingFormWork.FormWhenReadingOnServer(ThisForm);
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	// End StandardSubsystems.AttachableCommands

	
	ArticleSelectionOptions = Documents.PurchaseOrder.ItemsAndDimensionsSelectionParameters(Object.BusinessOperation);
	IncomeAndExpensesServer.OnReadAtServer(ThisForm, ArticleSelectionOptions);
	
	FormEvents.OnReadAtServer(ThisForm, CurrentObject);
	
EndProcedure

&AtClient
Procedure BeforeWrite(Cancel, WriteParameters)
	
	If NotExecuteCheck1BeforeWrite Then
		NotExecuteCheck1BeforeWrite = False;
		Return;
	EndIf;
	
	// If the document is being carried out, we will offer to fill in the data if they are incorrect
	If WriteParameters.WriteMode = DocumentWriteMode.Posting Then
		
		Cancel = True;
		AdditionalParameters = New Structure;
		AdditionalParameters.Insert("WriteParameters", WriteParameters);
		ReusablePackageClient.OfferToPickUpMultiTurnContainer(
			ThisObject,
			"Goods",
			"Products,Characteristic,Count,Warehouse,DateOfShipment,DateOfReceipt",
			New CallbackDescription("BeforeRecordingOfferToPickUpMultiTurnContainer", ThisObject, AdditionalParameters));
		Return;
		
	EndIf;
	
	TMCommonUseClient.RecordObjectIfNecessary(ThisObject, WriteParameters, Cancel);
	
EndProcedure

&AtClient
Procedure BeforeRecordingOfferToPickUpMultiTurnContainer(Result, AdditionalParameters) Export
	
	BeforeRecordingOfferToPickUpMultiTurnContainerCompletionOnServer();
	
	If Not Object.OneDateReceipt Then
		
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
	
	CalculateOrderTotals(ThisForm);
	
	If ValueIsFilled(Object.RequestedDeliveryDate) Then
		
		MaxAdvanceDate = SalesClient.MaximumAdvancePaymentDate(Object.PaymentScheduleSteps);
		If ValueIsFilled(MaxAdvanceDate) And MaxAdvanceDate > Object.RequestedDeliveryDate Then
			Object.RequestedDeliveryDate = MaxAdvanceDate;
		EndIf;
		
	EndIf;
	
	TMCommonUseClient.RecordObjectIfNecessary(ThisObject, AdditionalParameters.WriteParameters,,True);
	
EndProcedure

&AtClient
Procedure BeforeRecordingAskQuestionAboutResettingScheduleONChangesInShipmentDateEnd(Result, AdditionalParameters) Export
	
	If Result = DialogReturnCode.Yes Then
		Object.PaymentScheduleSteps.Clear();
	EndIf;
	ARAPAccountingClient.QuestionAboutResettingScheduleONChangesInShippingDatesHasBeenAsked(ThisObject);
	
	CalculateOrderTotals(ThisForm);
	
	If ValueIsFilled(Object.RequestedDeliveryDate) Then
		
		MaxAdvanceDate = SalesClient.MaximumAdvancePaymentDate(Object.PaymentScheduleSteps);
		If ValueIsFilled(MaxAdvanceDate) And MaxAdvanceDate > Object.RequestedDeliveryDate Then
			Object.RequestedDeliveryDate = MaxAdvanceDate;
		EndIf;
		
	EndIf;
	
	TMCommonUseClient.RecordObjectIfNecessary(ThisObject, AdditionalParameters.WriteParameters,,True);
	
EndProcedure

&AtServer
Procedure BeforeRecordingOfferToPickUpMultiTurnContainerCompletionOnServer()
	
	FillIn_BlankReceiptDatesServer();
	
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
	StructureOfActions.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));
	AccountingForTraceableGoodsClientServerLocalization.CompleteDescriptionOfSettingsForFillingInServiceDetailsOfTablePart(StructureOfActions);
	
	ProductsServer.FillInServiceDetailsForProductInCollection(Object.Goods, StructureOfActions);
	
	UpdateVHFWarehouseObligation();
	FillInServiceDetailsForPurposeOfVTCH();
	
	UpdateDuplicateDependentDetails();
	ARAPAccountingFormWork.FormAfterRecordingOnServer(ThisForm, CurrentObject.AdditionalProperties);
	
	UpdateTextDocumentsBasedOn();
	
	
	
	DocumentsStates.AfterWriteAtServer(
		ThisObject,
		WriteParameters,,,
		AccessRight("Read", Metadata.AccumulationRegisters.VendorsARAPAccounting));
	
	If DocumentsStates.TaskCheckForReflectingStateOfOrdersIsNotRunning(ThisObject) Then
		RefreshStatusServer();
	EndIf;
	
	IncomeAndExpensesServer.AfterWriteAtServer(ThisObject);
	
	UnlockFormDataForEdit();
	
	FormEvents.AfterWriteAtServer(ThisForm, CurrentObject, WriteParameters);
	
	ProvisionInDocumentsServer.CheckToRunBackgroundInventoryAllocationJob();
	
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
	
	// Handler of the "Properties" mechanism
	If PropertyManagerClient.ProcessNotifications(ThisObject, EventName, Parameter) Then
		UpdateAdditionalAttributesItems();
		PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
	EndIf;
	
	
	
	If ARAPAccountingClient.NeedAlertProcessingCall(ThisObject, EventName, Parameter) Then
		PaymentCreditedServer(EventName, Parameter, Source);
	EndIf;
	
	If EventName = "UpdateInformationSecurityDocumentAfterFillingItOut"  And Parameter.Find(Object.Ref) <> Undefined Then
		Read();
	ElsIf EventName = "UpdateIBDocumentAfterFillingItOutFromFile"  And Parameter.Find(Object.Ref) <> Undefined Then
		OnReadCreateAtServer();
	EndIf;
	
	If EventName = "ChangedStatusDependentBankingDetails"
		And Parameter.UUID = UUID Then
		If Object.Approved Then
			Object.Approved = False;
		EndIf;
		AttachIdleHandler("Attachable_WhenChangingDetailsDependingOnStatus", 0.1, True);
	EndIf;
	
	If EventName = "Write_TermsOfPurchaseFromVendors" Then
		
		SetAvailabilityAgreements();
		UpdateShippingSummary();
		
	EndIf;
	
	If EventName = "CopyingLinesToClipboard" Then
		
		SetAvailabilityOfClipboardCommandsOnClient();
		
	EndIf;
	
	If EventName = "Recording_NotificationOfSpecialTaxRegimes" Then
		
		UpdateTextDocumentsBasedOn();
		
	EndIf;
	
	FormEventsClient.NotificationProcessing(ThisObject, EventName, Parameter, Source);
	
	// StandardSubsystems.FilesOperations
	FilesOperationsClient.NotificationProcessing(ThisObject, EventName);
	// End StandardSubsystems.FilesOperations
	
	If EventName = "WhenChangingAgreement"
		And Source = ThisObject Then
		Modified = True;
		If ValueIsFilled(Object.Ref) Then
			Attachable_WhenChanging_SetAvailabilityOfItemsByStatusServer(Items[Parameter]);
		Else
			ContractOnChange(Items[Parameter]);
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure URLProcessing(FormattedStringURL, StandardProcessing)
	
	FormEventsClient.URLProcessing(ThisObject, FormattedStringURL, StandardProcessing);
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
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

	EnableWaitingHandlerReceivingCarriers();
	
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
	
EndProcedure

&AtServer
Procedure BeforeLoadDataFromSettingsAtServer(Settings)
	
	HideCanceledLines =  Settings.Get("HideCanceledLines");
	
	HowToUpdateRowSelectionForCanceledRows(ThisForm, HideCanceledLines, True);
	
	If Not Object.Ref.IsEmpty() Then
		Settings.Delete("Object.OneDateReceipt");
	EndIf;
	
EndProcedure

&AtServer
Procedure OnLoadDataFromSettingsAtServer(Settings)
	
	CacheQualityControl = QualityControl.DataCacheOfMechanism(Object);
	SetVisibilityOfReceiptDateFormElements();
	
EndProcedure

&AtClient
Procedure ChoiceProcessing(ValueSelected, ChoiceSource)
	
	If ChoiceSource.FormName = "DataProcessor.SelectGoodsToPurchaseDocument.Form.Form" Then
		
		ProcessingSelectionOfSelectionOnServer(ValueSelected);
		
	ElsIf ChoiceSource.FormName = "DataProcessor.SelectReusablePackage.Form.Form" Then
		
		FillMultiTurnContainersFromStorageServer(ValueSelected.AddressOfReusableContainerInStorage);
		ReusablePackageClient.NotifyUserAboutFillingMultiTurnContainers();
		
	ElsIf ChoiceSource.FormName = "Catalog.BusinessStructure.Form.ChoiceForm" Then
		
		SelectedRows = Items.Goods.SelectedRows;
		
		For Each String In SelectedRows Do
			
			RowData = Object.Goods.FindByID(String);
			
			If (RowData.ItemsType = PredefinedValue("Enum.ItemsTypes.OwnGoods") Or
				RowData.ItemsType = PredefinedValue("Enum.ItemsTypes.ReusablePackage"))
				And (Not RowData.ToExpenseAs Or ValueIsFilled(RowData.Purpose)) Then
				Continue;
			EndIf;
			
			RowData.Department = ValueSelected;
			
		EndDo;
		
	ElsIf ChoiceSource.FormName = "DataProcessor.OrderClosureWizard.Form.ClosureForm" Then
		
		AdjustOrderLines(ValueSelected);
	ElsIf ChoiceSource.FormName = "Document.EngineeringChangeOrder.Form.SubstitutionOfMaterialsWithAlternativeMaterials" Then
		
		Replace_With_Analogues(ValueSelected.AddressInStorage);
	EndIf;
	
	SetWhetherWarehouseIsFull();
	
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	
	Notify("Write_PurchaseOrder", WriteParameters, Object.Ref);
		
	
	ConfigurationModificationClientOverridable.AfterWrite(ThisForm, WriteParameters);
	
	TMCommonUseClient.PerformActionsAfterRecording(ThisForm, Object, WriteParameters);
	
	ARAPAccountingClient.FormAfterRecording(ThisForm);
	
	// StandardSubsystems.AttachableCommands
	If CommonClient.SubsystemExists("StandardSubsystems.AttachableCommands") Then
		ModuleAttachableCommandsClient = CommonClient.CommonModule("AttachableCommandsClient");
		ModuleAttachableCommandsClient.AfterWrite(ThisObject, Object, WriteParameters);
	EndIf;
	// End StandardSubsystems.AttachableCommands
	
	DocumentsStatesClient.AfterWrite(ThisObject, "Attachable_CheckTasksToReflectStateOfOrders");
	
EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	
	// StandardSubsystems.Properties
	PropertyManager.FillCheckProcessing(ThisForm, Cancel, CheckedAttributes);
	// End StandardSubsystems.Properties
	
EndProcedure

&AtServer
Procedure OnWriteAtServer(Cancel, CurrentObject, WriteParameters)
	

EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

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
	
	StructureOfAdditionalSelection = New Structure();
	If EconomicOperationsOfSeparatePurchase().Find(Object.BusinessOperation) <> Undefined Then
		StructureOfAdditionalSelection.Insert("ContractsAreUsed", True);
	EndIf;
	
	PurchasesClient.StartSelectingSupplierAgreement(
		Item,
		StandardProcessing,
		Object.Partner,
		Object.Terms,
		Object.Date,
		StructureOfAdditionalSelection);

EndProcedure

&AtClient
Procedure TermsAutoComplete(Item, Text, ChoiceData, DataGetParameters, Waiting, StandardProcessing)
	
	If EconomicOperationsOfSeparatePurchase().Find(Object.BusinessOperation) <> Undefined Then
		DataGetParameters.Filter.Insert("ContractsAreUsed", True);
	EndIf;
	
EndProcedure

&AtClient
Procedure PartnerOnChange(Item)
	
	If Not ValueIsFilled(Object.Partner) Then
		PartnerClearingServer();
		Object.Terms = PredefinedValue("Catalog.TermsOfPurchaseFromVendors.EmptyRef");
		GoodsDeliveryClientServer.ClearDeliveryDetails(Items,Object);
		Return;
	EndIf;
	
	PartnerOnChangeServer();
	

	If ValueIsFilled(Object.Terms) And Object.Goods.Total("Price")<>0 Then
		EnterprisePricesFillingClient.AskQuestionAboutRecalculatingPriceWhenDateChanges(Object,
			New CallbackDescription("PartnerWhenChangingQuestionEnds", ThisObject));
	EndIf;
	
EndProcedure

&AtClient
Procedure PartnerWhenChangingQuestionEnds(UserAnswer, AdditionalParameters) Export
	
	If ValueIsFilled(Object.Terms) Then
		If Not UserAnswer = DialogReturnCode.Cancel And UserAnswer Then
			ErrorText = "";
			PricesCalculated = FillThePricesByTermsOfSalesServer(True, ErrorText);
			PurchasesClient.NotifyAboutEndOfFillingInPricesUnderAgreement(PricesCalculated, ErrorText);
		EndIf;
		PurchasesClient.NotifyEndOfFillingInDefaultPurchaseConditions();
	EndIf;
	
	
EndProcedure

&AtClient
Procedure TermsOnChange(Item)
	
	ClearMessages();
	
	If Not ValueIsFilled(Object.Terms) Then
		TermsClearingServer();
	Else
		EnterprisePricesFillingClient.AskQuestionAboutRecalculatingPriceWhenDateChanges(Object,
			New CallbackDescription("AgreementWhenChangingQuestionCompletion", ThisObject));
	EndIf;
	
EndProcedure

&AtClient
Procedure AgreementWhenChangingQuestionCompletion(UserAnswer, AdditionalParameters) Export
	
	TermsOnChangeServer(
		ValueIsFilled(Object.Terms)
		And Object.Goods.Count() > 0
		And Not UserAnswer = DialogReturnCode.Cancel
		And UserAnswer);

	If ValueIsFilled(Object.Terms) Then
		PurchasesClient.NotifyEndOfFillingInTermsOfPurchase();
	EndIf;
	
EndProcedure

&AtClient
Procedure StatusOnChange(Item)

	If Object.Approved And
		Object.Status <> PredefinedValue("Enum.PurchaseOrderStatuses.Approved")
		And Object.Status <> PredefinedValue("Enum.PurchaseOrderStatuses.Confirmed_")
		And Object.Status <> PredefinedValue("Enum.PurchaseOrderStatuses.Closed") Then
		
		Object.Approved = False;
		
	EndIf;
	
	StatusOnChangeServer();
	
EndProcedure

&AtClient
Procedure VATTaxationOnChange(Item)
	
	VATTaxationOnChangeServer(CachedValues);
	
EndProcedure

&AtClient
Procedure PriceIncludesVATOnChange(Item)
	
	PriceIncludesVATOnChangeServer(CachedValues);
	
EndProcedure

&AtClient
Procedure CurrencyOnChange(Item)
	
	If ValueIsFilled(Object.Currency) Then
		
		RecalculateAmounts = PriceManagementSystemClient.CurrencyConversionRequired(Object,DocumentCurrency);
		
		CurrencyOnChangeServer(
			Object.Currency,
			RecalculateAmounts);
		If RecalculateAmounts Then
			PriceManagementSystemClient.NotifyAboutEndOfConversionOfAmountsIntoCurrency(DocumentCurrency, Object.Currency);
		EndIf;
	
	EndIf;
	
	DocumentCurrency = Object.Currency;
	
EndProcedure

&AtClient
Procedure CounterpartyOnChange(Item)
	
	CounterpartyOnChangeServer();
	
	
	
EndProcedure

&AtClient
Procedure OrganizationOnChange(Item)
	
	OrganizationOnChangeServer();
	
	
EndProcedure

&AtClient
Procedure ContractCreating(Item, StandardProcessing)
	
	PurchasesClient.OpenContractCreationForm(ThisObject, Item, "Object.Contract", Object.Partner, StandardProcessing);
	
EndProcedure

&AtClient
Procedure ContractOnChange(Item)
	
	ContractOnChangeServer(True);
	
EndProcedure

&AtClient
Procedure BusinessOperationOnChange(Item)
	
	BusinessOperationOnChangeServer();
	
EndProcedure

&AtClient
Procedure WarehouseOnChange(Item)
	
	WarehouseOnChangeServer(True);
	
EndProcedure

&AtClient
Procedure DateOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	
	Notification = New CallbackDescription("DateOnChangeCompletion", ThisObject);
	EnterprisePricesFillingClient.AskQuestionAboutRecalculatingPriceWhenDateChanges(Object, Notification);
	
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
Procedure DateOnChangeCompletion(QuestionResult, AdditionalParameters) Export 
	
	If Not QuestionResult = DialogReturnCode.Cancel And QuestionResult Then
	
		RecalculatePrices_2 = True;
		PricesCalculated = DateOnChangeServer(RecalculatePrices_2);
	
		If RecalculatePrices_2 Then
			PurchasesClient.NotifyAboutEndOfFillingInPricesUnderAgreement(PricesCalculated);
		EndIf;
		
	Else
		
		DateOnChangeServer(False);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure OperationWithSelfEmployedPersonOnChange(Item)

	OperationWithSelfEmployedWhenChangingOnServer();

EndProcedure

&AtClient
Procedure ApprovalDateOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	ApprovalDateForChangesOnServer();
EndProcedure

&AtClient
Procedure DateOfShipmentOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	
	ShipmentDateWhenChangedOnServer();
	
EndProcedure

&AtClient
Procedure OneDateReceiptOnChange(Item)
	
	OneDateReceiptOnChangeServer();
	
EndProcedure

&AtClient
Procedure DateOfReceiptOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	
	DateOfReceiptOnChangeServer();
	
EndProcedure

&AtClient
Procedure DeliveryDurationOnChange(Item)
	
	DeliveryDurationOnChangeServer();
	
EndProcedure

&AtClient
Procedure IncomingDocumentNumberTextEditEnd(Item, Text, ChoiceData, StandardProcessing)
	
	CheckAvailabilityOfOrdersAccordingToSupplierData(Text);
	
EndProcedure

&AtClient
Procedure PackageDepositIsRequiredOnChange(Item)
	
	CalculateOrderTotals(ThisForm);
	
EndProcedure

&AtClient
Procedure ManagerOnChange(Item)
	FillInSubordinatePropertiesForStatistics("Manager");
EndProcedure

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
Procedure DeliveryAddressForVendorStartChoice(Item, ChoiceData, StandardProcessing)
	
	OpenContactInformationSelectionForm(Item, ChoiceData, StandardProcessing);
	
EndProcedure

&AtClient
Procedure DeliveryAddressForVendor2StartChoice(Item, ChoiceData, StandardProcessing)
	
	OpenContactInformationSelectionForm(Item, ChoiceData, StandardProcessing);
	
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
Procedure LineOfBusinessOnChange(Item)
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.StartTimeMeasurement(
		True, "Document.PurchaseOrder.Form.DocumentForm.Item.LineOfBusiness.OnChange");

	LineOfBusinessOnChangeServer();

EndProcedure

&AtClient
Procedure Decorationedonage(Item, StandardProcessing)
	
	
EndProcedure

&AtClient
Procedure StateClick(Item, StandardProcessing)
	
	SalesClient.StatusInFormOfDocumentClick(StandardProcessing, ThisObject);
	
EndProcedure

&AtClient
Procedure PurchaseForActivityClearing(Item, StandardProcessing)
	StandardProcessing = False;
EndProcedure

&AtClient
Procedure DepartmentOnChange(Item)
	
	FillInTypeOfActivityVAT();
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersGoods

&AtClient
Procedure GoodsBeforeDeleteRow(Item, Cancel)
	
	ProcessingOfTabularFormsClient.CacheCurLine(Items.Goods, ThisObject);
	ARAPAccountingClient.SaveShipmentDatesInParameters(ThisObject);
	
EndProcedure

&AtClient
Procedure GoodsOnStartEdit(Item, NewRow, Copy)
	
	ProcessingOfTabularFormsClient.CacheCurLine(Items.Goods, ThisObject);
	CurrentData = Items.Goods.CurrentData;
	
	If NewRow Then
		CurrentData.RowCode = 0;
		If Object.OneDateReceipt Then
			CurrentData.DateOfShipment = Object.DateOfShipment;
		EndIf;
	EndIf;
	
	If NewRow And Not Copy Then
		CurrentData.Department = Object.Department;
	EndIf;
		
	IncomeAndExpensesClientServer.WhenAddingRowToTable(ThisObject, CurrentData, "Object.Goods");
	
	ARAPAccountingClient.SaveShipmentDatesInParameters(ThisObject);
	
EndProcedure

&AtClient
Procedure GoodsOnEditEnd(Item, NewRow, CancelEdit)
	
	CalculateOrderTotals(ThisForm);
	
	CurrentData = Items.Goods.CurrentData;
	
	If CurrentData <> Undefined And Object.OneDateReceipt Then
		CurrentData.DateOfReceipt = Object.DateOfReceipt;
	EndIf;
	
	ReusablePackageClient.UpdateFillingStateOfMultiTurnContainer(Object.ReusablePackageFillingStatus);
	If Not CancelEdit Then
		LineCache = ?(NewRow, Undefined, ProcessingOfTabularFormsClientServer.LineCache(Items.Goods, ThisObject));
		WarehousesClient.UpdateWarehouseTable(WarehouseTable, CurrentData, LineCache, WarehouseGroup_);
		TotalWarehouses_ = WarehouseTable.Count();
		WarehousesClientServer.UpdateWarehouseGroupImage(SeveralWarehousesText, Items.PictureMultipleWarehouses, TotalWarehouses_);
	EndIf;
	
	SetWhetherWarehouseIsFull();
	
EndProcedure

&AtClient
Procedure GoodsAfterDeleteRow(Item)
	
	ThereIsChangeInShippingDates = ARAPAccountingClient.ThereIsChangeInShippingDates(ThisObject);
	ProductsAfterDeletionOnServer(ThereIsChangeInShippingDates);
	ReusablePackageClient.UpdateFillingStateOfMultiTurnContainer(Object.ReusablePackageFillingStatus);
	SetWhetherWarehouseIsFull();
	
EndProcedure

&AtClient
Procedure GoodsSelection(Item, RowSelected, Field, StandardProcessing)
	
	PartnersProductsClient.WhenSelectingPartnerProducts(Object, Field, "GoodsPartnerProducts", NStr("vi = 'Nhà cung cấp';
																									|ru = 'Поставщик';
																									|en = 'Vendor'; fa = 'تأمین‌کننده';
																									|it = 'Fornitore';
																									|pl = 'Vendor';
																									|tr = 'Tedarikçi'"));
	
EndProcedure

&AtClient
Procedure GoodsPartnerProductsOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;
	
	PartnersProductsClient.SetPackageSelectionParameters(Item.ChoiceParameters, CurrentRow);
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("CheckCharacteristicsByOwner", CurrentRow.Characteristic);
	StructureOfActions.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));
	StructureOfActions.Insert("CheckFillPackageByOwner", CurrentRow.Package);
	StructureOfActions.Insert("FillInTheItemByThePartnerSItem");
	StructureOfActions.Insert(
		"CheckFillWarehouse",
		BatchProcessingOfTablePartClientServer.GetWarehouseFillStructureInTSLine(
			Object,
			WarehouseGroup_,,,"ToExpenseAs"));
	StructureOfActions.Insert("RecalculateNumberOfUnits");
	
	If UseTermsOfPurchases And ValueIsFilled(Object.Terms) Then
		StructureOfActions.Insert("FillInTermsOfPurchase", BatchProcessingOfTablePartClientServer.GetStructureForFillingInPurchasePriceInTSLine(Object));
	Else
		StructureOfActions.Insert("FillInPurchasePrice", BatchProcessingOfTablePartClientServer.GetStructureForFillingInPurchasePriceInTSLine(Object));
	EndIf;
	
	ParametersForFillingInVATRate = BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRate(Object, True);
	ParametersForFillingInVATRate.SpecifiedVATRate = SpecifiedVATRate;
	StructureOfActions.Insert("FillInVATRate", ParametersForFillingInVATRate);
	StructureOfActions.Insert("FillInVATRateForReturnableContainers", Object.ToReturnReusablePackage);
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmount");
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountManualDiscount", New Structure("Clear", False));
	StructureOfActions.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
	StructureOfActions.Insert("FillInNoReturnContainerAttribute", Object.ToReturnReusablePackage);
	StructureOfActions.Insert("FillInCanceledWithoutReturnableContainerAttribute", Object.ToReturnReusablePackage);
	StructureOfActions.Insert("FillInDuplicateDependentDetails", DependentDetails());
	StructureOfActions.Insert("WhenChangingProductType",
		New Structure("ThereAreWorks, ThereIsWriteOffForExpenses", True, True));
	StructureOfActions.Insert("FillInCheckQualityDateOfQualityConfirmation", CacheQualityControl);
	StructureOfActions.Insert("FillInWriteOFFAttributeForExpensesAndDivision");
	IncomeAndExpensesClientServer.InsertActionClearItemAndExpenseAnalytics(StructureOfActions, ThisObject);
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
	IncomeAndExpensesClientServer.WhenChangingArticleAvailabilityDetailsInLine(ThisObject, CurrentRow, "Object.Goods");
	
	CalculateOrderTotals(ThisForm);
	
	SetWhetherWarehouseIsFull();

EndProcedure

&AtClient
Procedure GoodsProductsOnChange(Item)
	
	ClearMessages();
	
	CurrentRow = Items.Goods.CurrentData;
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("CheckCharacteristicsByOwner", CurrentRow.Characteristic);
	StructureOfActions.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));
	StructureOfActions.Insert("CheckFillPackageByOwner", CurrentRow.Package);
	StructureOfActions.Insert("FillInProductNameOfProductPartner", Object.Partner);
	StructureOfActions.Insert(
		"CheckFillWarehouse",
		BatchProcessingOfTablePartClientServer.GetWarehouseFillStructureInTSLine(
			Object,
			WarehouseGroup_,,,"ToExpenseAs"));
	StructureOfActions.Insert("RecalculateNumberOfUnits");
	
	If UseTermsOfPurchases And ValueIsFilled(Object.Terms) Then
		StructureOfActions.Insert("FillInTermsOfPurchase", BatchProcessingOfTablePartClientServer.GetStructureForFillingInPurchasePriceInTSLine(Object));
	Else
		StructureOfActions.Insert("FillInPurchasePrice", BatchProcessingOfTablePartClientServer.GetStructureForFillingInPurchasePriceInTSLine(Object));
	EndIf;
	
	ParametersForFillingInVATRate = BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRate(Object, True);
	ParametersForFillingInVATRate.SpecifiedVATRate = SpecifiedVATRate;
	StructureOfActions.Insert("FillInVATRate", ParametersForFillingInVATRate);
	StructureOfActions.Insert("FillInVATRateForReturnableContainers", Object.ToReturnReusablePackage);
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmount");
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountManualDiscount", New Structure("Clear", True));
	StructureOfActions.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
	StructureOfActions.Insert("FillInNoReturnContainerAttribute", Object.ToReturnReusablePackage);
	StructureOfActions.Insert("FillInCanceledWithoutReturnableContainerAttribute", Object.ToReturnReusablePackage);
	StructureOfActions.Insert("FillInDuplicateDependentDetails", DependentDetails());
	StructureOfActions.Insert("WhenChangingProductType",
		New Structure("ThereAreWorks, ThereIsWriteOffForExpenses", True, True));
	
	//
	If ControlProductRange Then
		AssortmentInspectionStructure = ProductRangeClientServer.AssortmentVerificationParameters();
		AssortmentInspectionStructure.Ref = Object.Ref;
		AssortmentInspectionStructure.Warehouse = Object.Warehouse;
		AssortmentInspectionStructure.Date = ?(ValueIsFilled(Object.RequestedDeliveryDate), Object.RequestedDeliveryDate, Object.Date);
		AssortmentInspectionStructure.MessageText = NStr("vi = 'Hàng hóa %1 không thuộc phân loại của cửa hàng. Không nên đặt mặt hàng này.';
														|ru = 'Товар %1 не включен в ассортимент магазина. Заказывать его не рекомендуется.';
														|en = 'Item ""%1"" is not in this selling point''s product range. Please reconsider adding it to the order.'; fa = 'Item ""%1"" is not in this selling point''s product range. Please reconsider adding it to the order.';
														|it = 'Il prodotto %1 non è incluso nell''assortimento del negozio. Ordinarlo non è consigliabile.';
														|pl = 'Towar %1 nie jest włączony do asortymentu sklepu. Nie zaleca się zamawiać go.';
														|tr = 'Ürün%1 mağazanın ürün yelpazesine dahil değildir. Sipariş edilmesi tavsiye edilmez.'");
		AssortmentInspectionStructure.NameOfAssortmentResource = "PurchasesAreAllowed";
		AssortmentInspectionStructure.CheckedYouCanAdd = True;
		AssortmentInspectionStructure.AllowAdding = True;
		//
		StructureOfActions.Insert("CheckRowAssortment", AssortmentInspectionStructure);
	EndIf;
	LinesOfBusinessClientServer.StructureOfInsertActionsWhenAddingRow(ThisForm, StructureOfActions);
	StructureOfActions.Insert("FillInCheckQualityDateOfQualityConfirmation", CacheQualityControl);
	StructureOfActions.Insert("ProductsOnChangeOverridable", New Structure("FormName, TabularSectionName",
		ThisForm.FormName, "Goods"));
	StructureOfActions.Insert("FillInWriteOFFAttributeForExpensesAndDivision");

	IncomeAndExpensesClientServer.InsertActionClearItemAndExpenseAnalytics(StructureOfActions, ThisObject);
	
	AccountingForTraceableGoodsClientServerLocalization.CompleteDescriptionOfSettingsForFillingInServiceDetailsOfTablePart(StructureOfActions);
	
	WarehouseFillingParameters = BatchProcessingOfTablePartClientServer.GetWarehouseFillStructureInTSLine(
		Object, WarehouseGroup_, , ,"ToExpenseAs");
	StructureOfActions.Insert("CheckFillWarehouse", WarehouseFillingParameters);
	StructureOfActions.Insert("FillInCheckQualityDateOfQualityConfirmation", CacheQualityControl);
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
	IncomeAndExpensesClientServer.WhenChangingArticleAvailabilityDetailsInLine(ThisObject, CurrentRow, "Object.Goods");
	
	CalculateOrderTotals(ThisForm);
	
	SetWhetherWarehouseIsFull();
	
EndProcedure

&AtClient
Procedure GoodsCharacteristicOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInProductNameOfProductPartner", Object.Partner);
		
	If UseTermsOfPurchases And ValueIsFilled(Object.Terms) Then
		StructureOfActions.Insert("FillInTermsOfPurchase", BatchProcessingOfTablePartClientServer.GetStructureForFillingInPurchasePriceInTSLine(Object));
	Else
		StructureOfActions.Insert("FillInPurchasePrice", BatchProcessingOfTablePartClientServer.GetStructureForFillingInPurchasePriceInTSLine(Object));
	EndIf;
	
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmount");
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountManualDiscount", New Structure("Clear", True));
	StructureOfActions.Insert("FillInDuplicateDependentDetails", DependentDetails());
	LinesOfBusinessClientServer.StructureOfInsertActionsWhenAddingRow(ThisForm, StructureOfActions);

	StructureOfActions.Insert("CharacteristicOnChangeOverridable", New Structure("FormName, TabularSectionName",
		ThisForm.FormName, "Goods"));

	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);

	CalculateOrderTotals(ThisForm);
	
EndProcedure

&AtClient
Procedure GoodsPackageOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInProductNameOfProductPartner", Object.Partner);
	StructureOfActions.Insert("RecalculateNumberOfUnits");
	
	If CurrentRow.Count > 0 Then
		StructureOfActions.Insert("RecalculatePricePerPackage", CurrentRow.Count);
	Else
		StructureOfActions.Insert("FillInPurchasePrice", BatchProcessingOfTablePartClientServer.GetStructureForFillingInPurchasePriceInTSLine(Object));
	EndIf;
	
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmount");
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountManualDiscount", New Structure("Clear", False));
	StructureOfActions.Insert("FillInDuplicateDependentDetails", DependentDetails());
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
	CalculateOrderTotals(ThisForm);
	
EndProcedure

&AtClient
Procedure NumberOfPackagesOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;
	StructureOfActions = New Structure;	
	AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions, ThisForm);
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
	CalculateOrderTotals(ThisForm);
	
EndProcedure

&AtClient
Procedure GoodsPriceOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmount");
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountManualDiscount", New Structure("Clear", False));
	StructureOfActions.Insert("FillInDuplicateDependentDetails", DependentDetails());
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
	CalculateOrderTotals(ThisForm);
	
EndProcedure

&AtClient
Procedure GoodsVATRateOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmount");
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountManualDiscount", New Structure("Clear", False));
	StructureOfActions.Insert("FillInDuplicateDependentDetails", DependentDetails());
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
	CalculateOrderTotals(ThisForm);

	SpecifiedVATRate = CurrentRow.VATRate;

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
	
	CurrentRow = Items.Goods.CurrentData;
	
	StructureOfActions = New Structure();
	StructureOfActions.Insert("FillInCheckQualityDateOfQualityConfirmation", CacheQualityControl);
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
EndProcedure

&AtClient
Procedure GoodsVendorPriceKindOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInPurchasePrice", BatchProcessingOfTablePartClientServer.GetStructureForFillingInPurchasePriceInTSLine(Object));
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmount");
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountManualDiscount", New Structure("Clear", False));
	StructureOfActions.Insert("FillInDuplicateDependentDetails", DependentDetails());
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
	CalculateOrderTotals(ThisForm);
	
EndProcedure

&AtClient
Procedure GoodsPercentRateOfManualDiscountOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateAmountOfManualDiscount");
	StructureOfActions.Insert("RecalculateAmount");
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountManualDiscount", New Structure("RecalculateAmountOfManualDiscount_", False));
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("FillInDuplicateDependentDetails", DependentDetails());
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
	CalculateOrderTotals(ThisForm);
	
EndProcedure

&AtClient
Procedure GoodsManualDiscountOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculatePercentageOfManualDiscount");
	StructureOfActions.Insert("RecalculateAmount");
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountManualDiscount", New Structure("RecalculateAmountOfManualDiscount_", False));
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("FillInDuplicateDependentDetails", DependentDetails());
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
	CalculateOrderTotals(ThisForm);
	
EndProcedure

&AtClient
Procedure GoodsSumOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculatePriceDiscountForAmountInPurchases", BatchProcessingOfTablePartClientServer.GetStructureForRecalculatingDiscountPriceInVHFPurchases(Object, Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.ConsignmentProcurement")));
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("FillInDuplicateDependentDetails", DependentDetails());
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
	CalculateOrderTotals(ThisForm);
	
EndProcedure

&AtClient
Procedure GoodsExpenseItemOnChange(Item)
	
	IncomeAndExpensesClientServer.AssetRefOnChange(ThisObject, Item);
	
EndProcedure

&AtClient
Procedure GoodsCanceledOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInNoReturnContainerAttribute", Object.ToReturnReusablePackage);
	StructureOfActions.Insert("FillInCanceledWithoutReturnableContainerAttribute", Object.ToReturnReusablePackage);
	StructureOfActions.Insert("FillInDuplicateDependentDetails", DependentDetails());
	StructureOfActions.Insert("WhenChangingProductType",
		New Structure("ThereAreWorks, ThereIsWriteOffForExpenses", True, True));
	StructureOfActions.Insert("FillInCheckQualityDateOfQualityConfirmation", CacheQualityControl);
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
	If Not CurrentRow.Canceled Then
		CurrentRow.CancellationReason = PredefinedValue("Catalog.ReasonsForPurchaseOrderCancellation.EmptyRef");
	EndIf;
	
	CalculateOrderTotals(ThisForm);
	
	HowToUpdateRowSelectionForCanceledRows(ThisForm, HideCanceledLines, False);
	
	SetWhetherWarehouseIsFull();
	
	If ARAPAccountingClient.ThereIsChangeInShippingDates(ThisObject) Then
		GoodsCanceledOnChangeATServer();
	EndIf;
	
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

&AtClient
Procedure GoodsDateOfShipmentOnChange(Item)
	CurrentData = Items.Goods.CurrentData;
	If CurrentData <> Undefined Then
		If ValueIsFilled(CurrentData.DateOfShipment) Then
			CurrentData.DateOfReceipt = DateAccordingToCompanyCalendar(CurrentData.DateOfShipment, Object.DeliveryDuration);
		Else
			CurrentData.DateOfReceipt = Date(1,1,1);
		EndIf;
		StructureOfActions = New Structure();
		StructureOfActions.Insert("FillInCheckQualityDateOfQualityConfirmation", CacheQualityControl);
		BatchProcessingOfTablePartClient.ProcessTSString(CurrentData, StructureOfActions, CachedValues);
	EndIf;
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	StructureOfActions = New Structure;
	StructureOfActions.Insert("AdjustVATRate", BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRate(Object, True));
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("FillInDuplicateDependentDetails", DependentDetails());
	StructureOfActions.Insert("FillInVATRateForReturnableContainers", Object.ToReturnReusablePackage);
	StructureOfActions.Insert("FillInNoReturnContainerAttribute", Object.ToReturnReusablePackage);
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentData, StructureOfActions, CachedValues);
	
	CalculateOrderTotals(ThisObject);
	
EndProcedure

&AtClient
Procedure GoodsToExpenseAsOnChange(Item)
	
	CurrentData = Items.Goods.CurrentData;
	IncomeAndExpensesClientServer.WhenChangingArticleAvailabilityDetailsInLine(ThisObject, CurrentData, "Object.Goods");
	
	If Not CurrentData.ToExpenseAs
		And (CurrentData.ItemsType = PredefinedValue("Enum.ItemsTypes.OwnGoods")
		 Or CurrentData.ItemsType = PredefinedValue("Enum.ItemsTypes.ReusablePackage")) Then
		CurrentData.Department = PredefinedValue("Catalog.BusinessStructure.EmptyRef");
		If Not WarehouseGroup_ Then
			CurrentData.Warehouse = Object.Warehouse;
		EndIf;
	ElsIf Not ValueIsFilled(CurrentData.Department) Then
		CurrentData.Department = Object.Department;
		CurrentData.Warehouse = PredefinedValue("Catalog.Warehouses.EmptyRef");
	EndIf;
	StructureOfActions = New Structure();
	StructureOfActions.Insert("FillInCheckQualityDateOfQualityConfirmation", CacheQualityControl);
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentData, StructureOfActions, Undefined);
	
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
// End StandardSubsystems.FilesOperations

&AtClient
Procedure AutoTestFillInPricesByAgreement(Command) Export

	If PartnerPricesFillingClient.ItIsNecessaryToFillInPricesByAgreement(Object, "Goods", NStr("vi = 'Hàng hóa';
																								|ru = 'Товары';
																								|en = 'Items'; fa = 'اقلام';
																								|it = 'Merci';
																								|pl = 'Wiersze pozycji';
																								|tr = 'Ürünler'")) Then
		
		ErrorText = "";
		PricesCalculated = FillThePricesByTermsOfSalesServer(, ErrorText);
		PurchasesClient.NotifyAboutEndOfFillingInPricesUnderAgreement(PricesCalculated, ErrorText);
		
	EndIf;

EndProcedure

&AtClient
Procedure FillInThePricesOfTheSelectedLinesByTheTypeOfSupplierSPrice(Command)

	If PartnerPricesFillingClient.ItIsNecessaryToFillInPricesAccordingToSupplierSPriceType(Object, "Goods", NStr("vi = 'Hàng hóa';
																												|ru = 'Товары';
																												|en = 'Items'; fa = 'اقلام';
																												|it = 'Merci';
																												|pl = 'Wiersze pozycji';
																												|tr = 'Ürünler'")) Then
		
		PartnerPricesFillingClient.SelectVendorsPriceType(
			New CallbackDescription("FillInPricesOfSelectedRowsSelectionVendorPriceViewCompletion", ThisObject),
			Object.Partner,
			Object.PriceIncludesVAT);
		
	EndIf;

EndProcedure

&AtClient
Procedure FillInPricesOfSelectedRowsSelectionVendorPriceViewCompletion(VendorPriceKind, AdditionalParameters) Export
	
	If ValueIsFilled(VendorPriceKind) Then
		
		PricesCalculated = FillInThePricesOfTheSelectedLinesByTheTypeOfSupplierSPriceServer(VendorPriceKind);
		PartnerPricesFillingClient.NotifyAboutEndOfFillingInPricesByTypeOfSupplierSPrice(PricesCalculated, VendorPriceKind);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure AssignAManualDiscountForSelectedLines(Command)
	
	If Not DiscountsMarkupsFillingClient.ItIsPossibleToAssignManualDiscountMarkUp(Object, "Goods", NStr("vi = 'Hàng hóa';
																										|ru = 'Товары';
																										|en = 'Items'; fa = 'اقلام';
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
		Notification,
		True);
	
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
																											|en = 'Items'; fa = 'اقلام';
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
Procedure CancelSelectedLines(Command)
	
	If Object.Goods.Count() = 0 Then
		ShowMessageBox(Undefined, NStr("vi = 'Chưa điền bảng hàng hóa.';
										|ru = 'Таблица товаров не заполнена.';
										|en = 'Add items to the order.'; fa = 'Add items to the order.';
										|it = 'La tabella delle merci non è compilata.';
										|pl = 'Nie wypełniono tabeli towarów.';
										|tr = 'Mal tablosu eksiktir.'"));
		Return;
	ElsIf Items.Goods.SelectedRows.Count() = 0 Then
		ShowMessageBox(Undefined, NStr("vi = 'Trong bảng hàng hóa không có dòng đã chọn';
										|ru = 'В таблице товаров отсутствуют выделенные строки.';
										|en = 'Select at least one item.'; fa = 'Select at least one item.';
										|it = 'Nella tabella delle merci non ci sono righe selezionate.';
										|pl = 'Brak wybranych wierszy w tabeli towarów.';
										|tr = 'Mallar tablosunda seçili satır yoktur.'"));
		Return;
	EndIf;
	
	CancellationReason = PredefinedValue("Catalog.ReasonsForPurchaseOrderCancellation.EmptyRef");
	If UseReasonsForPurchaseOrderCancellations Then
		OpenForm("Catalog.ReasonsForPurchaseOrderCancellation.ChoiceForm",,,,,, New CallbackDescription("CancelSelectedLinesCompletion", ThisObject), FormWindowOpeningMode.LockOwnerWindow);
        Return;
	EndIf;
	
	UndoSelectedLineSnippet(CancellationReason);
EndProcedure

&AtClient
Procedure CancelSelectedLinesCompletion(Result, AdditionalParameters) Export
    
    CancellationReason = Result;
    If CancellationReason = Undefined Then
        Return;
    EndIf;
    
    UndoSelectedLineSnippet(CancellationReason);

EndProcedure

&AtClient
Procedure UndoSelectedLineSnippet(Val CancellationReason)
    
    StructureOfActions = New Structure;
    StructureOfActions.Insert("FillInNoReturnContainerAttribute", Object.ToReturnReusablePackage);
    StructureOfActions.Insert("FillInCanceledWithoutReturnableContainerAttribute", Object.ToReturnReusablePackage);
    StructureOfActions.Insert("FillInDuplicateDependentDetails", DependentDetails());
   	StructureOfActions.Insert("WhenChangingProductType",
        New Structure("ThereAreWorks, ThereIsWriteOffForExpenses", True, True));
	StructureOfActions.Insert("FillInCheckQualityDateOfQualityConfirmation", CacheQualityControl);
   
    For Each CurRow In Items.Goods.SelectedRows Do
        
        TableRow = Object.Goods.FindByID(CurRow);
        
        If TableRow <> Undefined Then
            
            TableRow.CancellationReason = CancellationReason;
            
            If Not TableRow.Canceled Then
                TableRow.Canceled = True;
            EndIf;
            
            BatchProcessingOfTablePartClient.ProcessTSString(TableRow, StructureOfActions, CachedValues);
            
        EndIf;
        
    EndDo;
    
    WhenChangingWarehouseInTablePartServer();// server call
    CalculateOrderTotals(ThisForm);
   	SetWhetherWarehouseIsFull();

    ShowUserNotification(
    NStr("vi = 'Các dòng đã chọn bị hủy bỏ';
		|ru = 'Выделенные строки отменены';
		|en = 'Selected lines are canceled'; fa = 'Selected lines are canceled';
		|it = 'Righe selezionate annullate';
		|pl = 'Zaznaczone wiersze anulowano';
		|tr = 'Seçili satırlar iptal edildi'"),
    ,
    NStr("vi = 'Dòng được chọn trong đơn hàng bị hủy bỏ';
		|ru = 'Выделенные строки заказа отменены.';
		|en = 'Selected items are canceled from the order.'; fa = 'Selected items are canceled from the order.';
		|it = 'Righe selezionate dell''ordine sono annullate.';
		|pl = 'Wydzielone wiersze zamówienia zamówienia są anulowane.';
		|tr = 'Seçili sipariş satırları iptal edildi.'"),
    PictureLib.Information32);
	
EndProcedure

&AtClient
Procedure CancelUndeliveredLines(Command)

	If Object.Goods.Count() = 0 Then
		ShowMessageBox(Undefined, NStr("vi = 'Chưa điền bảng hàng hóa.';
										|ru = 'Таблица товаров не заполнена.';
										|en = 'Add items to the order.'; fa = 'Add items to the order.';
										|it = 'La tabella delle merci non è compilata.';
										|pl = 'Nie wypełniono tabeli towarów.';
										|tr = 'Mal tablosu eksiktir.'"));
		Return;
	EndIf;
	
	ThereAreNonCanceledLines = False;
	For Each CurRow In Object.Goods Do
		If Not CurRow.Canceled Then
			ThereAreNonCanceledLines = True;
		EndIf;
	EndDo;
	
	If Not ThereAreNonCanceledLines Then
		ShowMessageBox(Undefined, NStr("vi = 'Tất cả dòng đều bị hủy bỏ';
										|ru = 'Все строки отменены.';
										|en = 'All lines are canceled.'; fa = 'All lines are canceled.';
										|it = 'Tutte le righe sono annullate.';
										|pl = 'Wszystkie wiersze anulowano.';
										|tr = 'Tüm satırlar iptal edildi.'"));
		Return;
	EndIf;
	
	CheckBalance = True;
	
	If Not Object.Posted Then
		CheckBalance = False;
	ElsIf Object.Status = PredefinedValue("Enum.PurchaseOrderStatuses.NotApproved")
		Or Object.Status = PredefinedValue("Enum.PurchaseOrderStatuses.Approved")
		Or Object.Status = PredefinedValue("Enum.PurchaseOrderStatuses.Confirmed_") Then
		CheckBalance = True;
	EndIf;
	
	CancellationReason = PredefinedValue("Catalog.ReasonsForPurchaseOrderCancellation.EmptyRef");
	If UseReasonsForPurchaseOrderCancellations Then
		OpenForm("Catalog.ReasonsForPurchaseOrderCancellation.ChoiceForm",,,,,, New CallbackDescription("CancelUndeliveredLinesCompletion", ThisObject, New Structure("CheckBalance", CheckBalance)), FormWindowOpeningMode.LockOwnerWindow);
        Return;
	EndIf;

	UndoUndeliveredStringFragment(CancellationReason, CheckBalance);
EndProcedure

&AtClient
Procedure CancelUndeliveredLinesCompletion(Result, AdditionalParameters) Export
    
    CheckBalance = AdditionalParameters.CheckBalance;
    
    
    CancellationReason = Result;
    If CancellationReason = Undefined Then
        Return;
    EndIf;
    
    UndoUndeliveredStringFragment(CancellationReason, CheckBalance);

EndProcedure

&AtClient
Procedure UndoUndeliveredStringFragment(Val CancellationReason, Val CheckBalance)
    
    Var RowsCountCanceled;
    
    RowsCountCanceled = CancelUndeliveredLinesServer(CancellationReason, CheckBalance);
    
    If RowsCountCanceled = 0 Then
        
        ShowUserNotification(
        NStr("vi = 'Chưa hủy bỏ dòng';
			|ru = 'Строки не отменены';
			|en = 'Lines were not canceled'; fa = 'Lines were not canceled';
			|it = 'Righe non annullate';
			|pl = 'Wiersze nie są anulowane';
			|tr = 'Satırlar iptal edilmedi'"),
        ,
        NStr("vi = 'Theo toàn bộ dòng trong đơn hàng lập chứng từ tiếp nhận. Dòng không thể hủy bỏ';
			|ru = 'По всем строкам заказа оформлено поступление. Строки не могут быть отменены.';
			|en = 'Cannot cancel the items. The order has been delivered.'; fa = 'Cannot cancel the items. The order has been delivered.';
			|it = 'Per tutte le righe è stato formalizzato l''arrivo. Le righe non possono essere annullate.';
			|pl = 'Według wszystkich wierszy zamówienia sporządzono wpływ. Wiersze nie mogą być anulowane.';
			|tr = 'Tüm sipariş satırları için bir makbuz düzenlenmiştir. Satırlar iptal edilemez.'"),
        PictureLib.Information32);
        
    Else
        
        CalculateOrderTotals(ThisForm);
        
        If CheckBalance Then
            
            ShowUserNotification(
            NStr("vi = 'Hủy bỏ dòng';
				|ru = 'Строки отменены';
				|en = 'Lines were canceled'; fa = 'Lines were canceled';
				|it = 'Righe annullate';
				|pl = 'Wiersze są anulowane';
				|tr = 'Satırlar iptal edildi'"),
            ,
            NStr("vi = 'Tất cả dòng chưa giao hàng trong đơn hàng đều bị hủy bỏ';
				|ru = 'Все непоставленные строки заказа отменены.';
				|en = 'All undelivered items are canceled.'; fa = 'All undelivered items are canceled.';
				|it = 'Tutte le righe dell''ordine non consegnate sono annullate.';
				|pl = 'Wszystkie nieporównane wiersze zamówienia są anulowane.';
				|tr = 'Bekleyen tüm sipariş satırları iptal edildi.'"),
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
            NStr("vi = 'Tất cả dòng trong đơn hàng đều bị hủy bỏ';
				|ru = 'Все строки заказа отменены.';
				|en = 'All items are canceled.'; fa = 'All items are canceled.';
				|it = 'Tutte le righe dell''ordine sono annullate.';
				|pl = 'Wszystkie wiersze zamówienia są anulowane';
				|tr = 'Tüm sipariş satırları iptal edildi.'"),
            PictureLib.Information32);
            
        EndIf;
        
    EndIf;

EndProcedure

&AtClient
Procedure WriteDocument(Command)
	
	TMCommonUseClient.Write(ThisForm, True);
	
EndProcedure

&AtClient
Procedure FillInShipmentDateForSelectedLines(Command)

	If Items.Goods.SelectedRows.Count() > 0 Then
		FillInShipmentDate(Items.Goods.SelectedRows);
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
Procedure HideCanceledLines(Command)
	
	HideCanceledLines = Not HideCanceledLines;
	
	HowToUpdateRowSelectionForCanceledRows(ThisForm, HideCanceledLines, True);
	
EndProcedure

&AtClientAtServerNoContext
Procedure HowToUpdateRowSelectionForCanceledRows(Form, HideCancelledRows, SetGoodsMarkToHideCanceledRows = True)
	
	If HideCancelledRows Then
		Form.Items.Goods.RowFilter = New FixedStructure("Canceled", False);
	Else
		Form.Items.Goods.RowFilter = Undefined;
	EndIf;
	
	If SetGoodsMarkToHideCanceledRows Then
		Form.Items.GoodsHideCanceledLines.Check = HideCancelledRows;	
	EndIf;
	
EndProcedure	

&AtClient
Procedure SelectGoods(Command)
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.StartTimeMeasurement(True,
		"Document.PurchaseOrder.DocumentForm.Command.SelectGoods");
	
	Cancel = False;
	If Not ValueIsFilled(Object.Currency) Then
		ClearMessages();
		ReportErrorsWhenOpeningSelection(Cancel);
	EndIf;
	If Cancel Then
		Return;
	EndIf;
	
	FormParameters = New Structure;
	FormParameters.Insert("Document",        Object.Ref);
	FormParameters.Insert("Partner",         Object.Partner);
	FormParameters.Insert("Terms",      Object.Terms);
	FormParameters.Insert("PriceIncludesVAT", Object.PriceIncludesVAT);
	FormParameters.Insert("Warehouse",       Object.Warehouse);
	FormParameters.Insert("Currency",      Object.Currency);
	FormParameters.Insert("SelectionModeUseWarehousesInTabularSection", True);
	If Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.ConsignmentProcurement") Then
		
		FormParameters.Insert("FilterByProductType", New FixedArray(ProductsClientServer.SelectionByProductMultiTurnContainer(False)));
		FormParameters.Insert("HideManualDiscounts", True);
		
	ElsIf Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.ReceivingForStorageWithRightOfSale") Then
		
		FormParameters.Insert("FilterByProductType", New FixedArray(ProductsClientServer.SelectionByProductMultiTurnContainer(False)));
		
	ElsIf Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.PurchaseFromVendorGoodsInTransit")
		Or Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.ImportFromEAEUGoodsInTransit")
		Or Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.ImportGoodsInTransit") Then
		FormParameters.Insert("FilterByProductType", New FixedArray(ProductsClientServer.SelectionByProductReusablePackagingService(False)));
	Else
		FormParameters.Insert("FilterByProductType", New FixedArray(ProductsClientServer.SelectionByProductReusablePackagingServiceWork(False)));
	EndIf;
	FormParameters.Insert("Date", Object.Date);
	
	OpenForm("DataProcessor.SelectGoodsToPurchaseDocument.Form", FormParameters, ThisForm, UUID);
	
EndProcedure

&AtClient
Procedure Attachable_PropertiesExecuteCommand(ItemOrCommand, Var_URL = Undefined, StandardProcessing = Undefined)
	PropertyManagerClient.ExecuteCommand(ThisObject, ItemOrCommand, StandardProcessing);
EndProcedure

&AtClient
Procedure ShowSupplierProducts(Command)
	
	PartnersProductsClient.ShowThePartnerSNomenclature(Object.Partner, Object.Ref, Items.Goods.CurrentData, NStr("vi = 'Nhà cung cấp';
																												|ru = 'Поставщик';
																												|en = 'Vendor'; fa = 'تأمین‌کننده';
																												|it = 'Fornitore';
																												|pl = 'Dostawca';
																												|tr = 'Tedarikçi'"));
	
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
		AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions, ThisForm);
		
		BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
		BatchProcessingOfTablePartClient.ProcessTSString(NewRow, StructureOfActions, CachedValues);
		
		WhenChangingWarehouseInTablePartServer();
		
		CalculateOrderTotals(ThisForm);
		
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
Procedure FillInTheWarehouseInSelectedLines(Command)
	
	SelectedRows = Items.Goods.SelectedRows;
	If WarehousesClient.CheckPossibilityOfFillingWarehousesInTablePart(Object, Object.Goods, NStr("vi = 'Hàng hóa';
																									|ru = 'Товары';
																									|en = 'Items'; fa = 'اقلام';
																									|it = 'Merci';
																									|pl = 'Wiersze pozycji';
																									|tr = 'Ürünler'"), SelectedRows) Then
		FilterArray = New Array();
		FilterArray.Add(PredefinedValue("Enum.SelectWarehouseGroup.AllowInOrders"));
		FilterArray.Add(PredefinedValue("Enum.SelectWarehouseGroup.AllowInOrdersAndInvoices"));
		FilterStructure1 = New Structure("SelectGroup, IsFolder", FilterArray, False);
		ParametersStructure = New Structure("Filter,GroupOfWarehouses", FilterStructure1, Object.Warehouse);
		SelectedWarehouse = Undefined;

		OpenForm("Catalog.Warehouses.ChoiceForm", ParametersStructure, ThisForm,,,, New CallbackDescription("FillInTheWarehouseInSelectedLinesCompletion", ThisObject, New Structure("SelectedRows", SelectedRows)), FormWindowOpeningMode.LockOwnerWindow);
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
Procedure FillInTheItemByThePartnerSItem(Command)
	
	If Not TMCommonUseClient.CheckForRowsInList(Object.Goods, "Goods") Then
		Return;
	EndIf;
	
	GoodsAddressInStorage = PlaceGoodsInTemporaryStorageServer();
	PurchasesClient.OpenSupplierProductListForm(
		New CallbackDescription("FillInTheItemByThePartnerSItemCompletion", ThisObject),
		GoodsAddressInStorage,
		ThisForm);
	
EndProcedure

&AtClient
Procedure FillInTheItemByThePartnerSItemCompletion(Result, AdditionalParameters) Export
	
	If Result <> Undefined Then
		
		FillInItemsFromTemporaryStorageServer(Result);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure AdjustPricesForGoodsReceipts(Command)
	
	If ValueIsFilled(Object.Ref) Then
		AdjustPricesForGoodsReceiptsServer();
	EndIf;
	
EndProcedure

&AtClient
Procedure InsertRows(Command)
	
	NumberOfProductsBeforeInsertion = Object.Goods.Count();
	
	GetLinesFromClipboard();
	
	NumberOfInserted = Object.Goods.Count()-NumberOfProductsBeforeInsertion;
	ProcessingOfTabularFormsClient.NotifyUserAboutInsertingRows(NumberOfInserted);
	
	SetWhetherWarehouseIsFull();
	
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
		ThisObject,
		"Goods",
		"Products,Characteristic,Count,Warehouse,DateOfShipment,DateOfReceipt");
	
EndProcedure

&AtClient
Procedure SelectSubstitutes(Command)
	PerformanceMonitorClient.StartTimeMeasurement(True,
		"Document.PurchaseOrder.Form.DocumentForm.Command.SelectSubstitutes");
	
	ClearMessages();
	OpenSelectionOfAnalogues();
	 Return; // in UT and KA the handler is empty
	
EndProcedure

&AtClient
Procedure ImportFromExternalFile(Command)
	
	ImportParameters = ProcessingOfTabularFormsClient.ProductLoadingParameters();
	ImportParameters.Organization = Object.Organization;
	ImportParameters.FillInThePartnerSNomenclature = Object.Partner;
	ImportParameters.ImportPrices   = True;
	ImportParameters.ImportAmounts  = True;
	ImportParameters.ImportDiscounts =
		Object.BusinessOperation <> PredefinedValue("Enum.BusinessTransactions.ConsignmentProcurement");
	ImportParameters.PriceIncludesVAT    = Object.PriceIncludesVAT;
	ImportParameters.VATTaxation = Object.VATTaxation;
	ImportParameters.FillingDate     = Object.Date;
	ImportParameters.ThisIsReusablePackage  = Object.ToReturnReusablePackage;
	
	If Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.ConsignmentProcurement")
		Or Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.ReceivingForStorageWithRightOfSale") Then
		
		ImportParameters.FilterParameters.Insert("ItemsType",
			ProductsClientServer.SelectionByProductMultiTurnContainer(False));
			
	ElsIf Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.PurchaseFromVendorGoodsInTransit")
		Or Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.ImportFromEAEUGoodsInTransit")
		Or Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.ImportGoodsInTransit") Then
		
		ImportParameters.FilterParameters.Insert("ItemsType",
			ProductsClientServer.SelectionByProductReusablePackagingService(False));
	Else
		ImportParameters.FilterParameters.Insert("ItemsType",
			ProductsClientServer.SelectionByProductReusablePackagingServiceWork(False));
		
	EndIf;
	
	Notification = New CallbackDescription("ImportFromExternalFileCompletion", ThisObject);
	ProcessingOfTabularFormsClient.ShowProductUploadForm(ImportParameters, Notification);
	
EndProcedure

&AtClient
Procedure ImportFromExternalFileCompletion(ImportedDataAddress, AdditionalParameters) Export
	
	If ValueIsFilled(ImportedDataAddress) Then
		GetUploadedProductsFromStorage(ImportedDataAddress);
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
Procedure PaymentSettlement(Command)
	ARAPAccountingClient.PaymentSettlement(ThisForm, Items.CreditPaymentForm);
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
Procedure CalculationsClick(Item, StandardProcessing)
	
	ARAPAccountingClient.CalculationsClick(ThisForm, Item, StandardProcessing);
	
EndProcedure

&AtClient
Procedure DecorationSparkriskieIndexesURLProcessing(Item, FormattedStringURL, StandardProcessing)


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
Function FillInSubordinatePropertiesForStatistics(ParentPropsName)
	Return ObjectsFillingByStatistics.FillInSubordinateDetailsOfObject(Object, ParentPropsName);
EndFunction

&AtServer
Procedure SetConditionalAppearanceForArticlesAndAnalytics()
	
	InvoicingOperations = New ValueList;
	InvoicingOperations.Add(Enums.BusinessTransactions.ImportFromEAEUInvoicedDelivery);
	InvoicingOperations.Add(Enums.BusinessTransactions.PurchaseFromVendorCreatingInvoicesOnGoodsReceipt);
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsToExpenseAs.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsExpenseItem.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsDimensionOfExpenses.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.BusinessOperation");
	ItemFilter.ComparisonType = DataCompositionComparisonType.InList;
	ItemFilter.RightValue = InvoicingOperations;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("OptionOfExecutionOfContractOfPurchases");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.PurchaseRegistrationOptions.UninvoicedDeliveriesOfGoodsAndServices;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.ItemsType");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = PredefinedValue("Enum.ItemsTypes.Work_5");
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.AccountingForTheRNPTIsMaintained");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	Item.Appearance.SetParameterValue("ReadOnly", True);
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsExpenseItem.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsDimensionOfExpenses.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.BusinessOperation");
	ItemFilter.ComparisonType = DataCompositionComparisonType.InList;
	ItemFilter.RightValue = InvoicingOperations;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("OptionOfExecutionOfContractOfPurchases");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.PurchaseRegistrationOptions.UninvoicedDeliveriesOfGoodsAndServices;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.ItemsType");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = PredefinedValue("Enum.ItemsTypes.Work_5");
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.AccountingForTheRNPTIsMaintained");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<đối với công việc không được truy xuất>';
													|ru = '<для непрослеживаемых работ>';
													|en = '<for untraceable works>'; fa = '<for untraceable works>';
													|it = '<для непрослеживаемых работ>';
													|pl = '<for untraceable works>';
													|tr = '<izlenemeyen işler için>'"));
	Item.Appearance.SetParameterValue("TextColor", StyleColors.InaccessibleCellTextColor);
	
	// only view if the product or container or service or work and the appointment is filled
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsToExpenseAs.Name);

	SelectionGroupOr = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	SelectionGroupOr.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	
		SelectionGroupAnd1 = SelectionGroupOr.Items.Add(Type("DataCompositionFilterItemGroup"));
		SelectionGroupAnd1.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
		
			ItemFilter = SelectionGroupAnd1.Items.Add(Type("DataCompositionFilterItem"));
			ItemFilter.LeftValue = New DataCompositionField("Object.Goods.ItemsType");
			ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
			ItemFilter.RightValue = Enums.ItemsTypes.OperationService;
			
		SelectionGroupAnd2 = SelectionGroupOr.Items.Add(Type("DataCompositionFilterItemGroup"));
		SelectionGroupAnd2.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
		
			ItemFilter = SelectionGroupAnd2.Items.Add(Type("DataCompositionFilterItem"));
			ItemFilter.LeftValue = New DataCompositionField("Object.Goods.ItemsType");
			ItemFilter.ComparisonType = DataCompositionComparisonType.InList;
			ValueList = New ValueList;
			ValueList.Add(PredefinedValue("Enum.ItemsTypes.OwnGoods"));
			ValueList.Add(PredefinedValue("Enum.ItemsTypes.ReusablePackage"));
			ValueList.Add(PredefinedValue("Enum.ItemsTypes.Work_5"));
			ItemFilter.RightValue = ValueList;
			
			ItemFilter = SelectionGroupAnd2.Items.Add(Type("DataCompositionFilterItem"));
			ItemFilter.LeftValue = New DataCompositionField("Object.Goods.Purpose");
			ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
			
		SelectionGroupAnd3 = SelectionGroupOr.Items.Add(Type("DataCompositionFilterItemGroup"));
		SelectionGroupAnd3.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
		
			ItemFilter = SelectionGroupAnd3.Items.Add(Type("DataCompositionFilterItem"));
			ItemFilter.LeftValue = New DataCompositionField("Object.Goods.ToExpenseAs");
			ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
			ItemFilter.RightValue = False;
			
			ItemFilter = SelectionGroupAnd3.Items.Add(Type("DataCompositionFilterItem"));
			ItemFilter.LeftValue = New DataCompositionField("Object.Goods.ItemsType");
			ItemFilter.ComparisonType = DataCompositionComparisonType.InList;
			ValueList = New ValueList;
			ValueList.Add(PredefinedValue("Enum.ItemsTypes.OwnGoods"));
			ValueList.Add(PredefinedValue("Enum.ItemsTypes.ReusablePackage"));
			ItemFilter.RightValue = ValueList;
			
			ItemFilter = SelectionGroupAnd3.Items.Add(Type("DataCompositionFilterItem"));
			ItemFilter.LeftValue = New DataCompositionField("Object.BusinessOperation");
			ItemFilter.ComparisonType = DataCompositionComparisonType.InList;
			ValueList = New ValueList;
			ValueList.Add(Enums.BusinessTransactions.ImportFromEAEUGoodsInTransit);
			ValueList.Add(Enums.BusinessTransactions.ImportGoodsInTransit);
			ValueList.Add(Enums.BusinessTransactions.PurchaseFromVendorGoodsInTransit);
			ValueList.Add(Enums.BusinessTransactions.ImportFromEAEUInvoicedDelivery);
			ValueList.Add(Enums.BusinessTransactions.PurchaseFromVendorCreatingInvoicesOnGoodsReceipt);
			ItemFilter.RightValue = ValueList;
			
	Item.Appearance.SetParameterValue("ReadOnly", True);
	
	// explanatory inscription, if the job is completed and the assignment is completed

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsExpenseItem.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsDimensionOfExpenses.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.ItemsType");
	ItemFilter.ComparisonType = DataCompositionComparisonType.InList;
	ValueList = New ValueList;
	ValueList.Add(PredefinedValue("Enum.ItemsTypes.OwnGoods"));
	ValueList.Add(PredefinedValue("Enum.ItemsTypes.ReusablePackage"));
	ValueList.Add(PredefinedValue("Enum.ItemsTypes.Work_5"));
	ItemFilter.RightValue = ValueList;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.Purpose");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;

	Item.Appearance.SetParameterValue("Text", NStr("vi = '<đối với hàng hóa/dịch vụ và công việc không có mục đích>';
													|ru = '<для товаров/услуг и работ без назначения>';
													|en = '<for goods/services and works without assignment>'; fa = '<for goods/services and works without assignment>';
													|it = '<per articoli/servizi e lavori senza assegnazione>';
													|pl = '<dla towarów/usług i prac bez przeznaczenia>';
													|tr = '< varış yeri olmayan mallar/hizmetler ve işler için'"));
	Item.Appearance.SetParameterValue("TextColor", StyleColors.InaccessibleCellTextColor);

	// the text of the expense analysis, if the item is not selected
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsDimensionOfExpenses.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.ExpenseItem");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.DimensionOfExpenses");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.ToExpenseAs");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.EmptyTableField);
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<hãy chọn dạng chi phí>';
													|ru = '<выберите статью расходов>';
													|en = '<Select expense item>'; fa = '<Select expense item>';
													|it = '<selezionare la voce delle spese>';
													|pl = '<wybierz pozycję wydatków>';
													|tr = '<maliyet kalemini seçin>.'"));
	Item.Appearance.SetParameterValue("ReadOnly", True);
	
	// explanatory inscription, if we do not write off work and expenses

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsDimensionOfExpenses.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.ItemsType");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.ItemsTypes.Work_5;

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.ToExpenseAs");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.Purpose");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;

	Item.Appearance.SetParameterValue("ReadOnly", True);
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<khi ghi giảm vào chi phí>';
													|ru = '<при списании на расходы>';
													|en = '<when writing off as expenses>'; fa = '<when writing off as expenses>';
													|it = '<durante lo storno sulle spese>';
													|pl = '<przy wyksięgowaniu na rozchody>';
													|tr = '<gider yazılması>'"));
	Item.Appearance.SetParameterValue("TextColor", StyleColors.InaccessibleCellTextColor);
	
EndProcedure	

&AtServer
Procedure SetConditionalAppearance()
	
	UseGoodsInTransitFromVendors  = GetFunctionalOption("UseGoodsInTransitFromVendors");
	UseUninvoicedDeliveries = GetFunctionalOption("UseUninvoicedDeliveries");
	
	EconomicOperationsOfSeparatePurchase = EconomicOperationsOfSeparatePurchase(UseGoodsInTransitFromVendors, UseUninvoicedDeliveries);
	ListOfOperationsRequiringContract = New ValueList();
	ListOfOperationsRequiringContract.LoadValues(EconomicOperationsOfSeparatePurchase);
	ListOfOperationsRequiringContract.Add(Enums.BusinessTransactions.ReceivingForStorageWithRightOfSale);
	ListOfOperationsRequiringContract.Add(Enums.BusinessTransactions.DeliveryForPrincipal);
	ConditionalAppearance.Items.Clear();
	
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
	ItemFilter.RightValue = Enums.PurchaseOrderStates.Closed;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.ClosedDocument);
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsManualDiscount.Name);
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsPercentRateOfManualDiscount.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.Canceled");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	Item.Appearance.SetParameterValue("MarkNegatives", True);
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsPartnerProducts.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Partner");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	Item.Appearance.SetParameterValue("ReadOnly", True);
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsPartnerProducts.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Partner");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	Item.Appearance.SetParameterValue("TextColor", StyleColors.EmptyTableField);
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<hãy chọn nhà cung cấp>';
													|ru = '<выберите поставщика>';
													|en = '<Select vendor>'; fa = '<Select vendor>';
													|it = '<selezionare il fornitore>';
													|pl = '<wybierz dostawcę>';
													|tr = '<tedarikçi seçin>'"));
	Item.Appearance.SetParameterValue("ReadOnly", True);
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsDateOfReceipt.Name);
	
	FilterGroup1 = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup1.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	
	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.DateOfReceipt");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	
	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Status");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotInList;
	ValueList = New ValueList;
	ValueList.Add(Enums.PurchaseOrderStatuses.Confirmed_);
	ValueList.Add(Enums.PurchaseOrderStatuses.Closed);
	ItemFilter.RightValue = ValueList;
	
	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.Canceled");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsDateOfShipment.Name);
	
	FilterGroup1 = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup1.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	
	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.DateOfShipment");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	
	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Status");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotInList;
	ValueList = New ValueList;
	ValueList.Add(Enums.PurchaseOrderStatuses.Confirmed_);
	ValueList.Add(Enums.PurchaseOrderStatuses.Closed);
	ItemFilter.RightValue = ValueList;
	
	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.Canceled");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	
	//
	
	VATAccountingERP.EstablishConditionalAppearanceOfVATAmountsForTaxationOfPurchases(ThisForm);
	
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
	
	ConditionalDesignParameters = WarehousesServer.ParametersOfConditionalAppearanceOfVHFWarehouseByItemType();
	ConditionalDesignParameters.Form = ThisObject;
	ConditionalDesignParameters.ToCheckWhetherWarehouseIsFull = True;
	WarehousesServer.SetConditionalAppearanceOfVHFWarehouseByTypeOfItem(ConditionalDesignParameters);
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsWarehouse.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.ItemsType");
	ItemFilter.ComparisonType = DataCompositionComparisonType.InList;
	ValueList = New ValueList;
	ValueList.Add(Enums.ItemsTypes.OwnGoods);
	ValueList.Add(Enums.ItemsTypes.ReusablePackage);
	ItemFilter.RightValue = ValueList;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.Warehouse");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	Item.Appearance.SetParameterValue("MarkIncomplete", True);
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.Contract.Name);
	
	FilterGroup1 = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup1.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	
	FilterGroup2 = FilterGroup1.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup2.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
	
	ItemFilter = FilterGroup2.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Terms");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	ItemFilter = FilterGroup2.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.BusinessOperation");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotInList;
	ItemFilter.RightValue = ListOfOperationsRequiringContract;
	
	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Contract");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.Contract.Name);
	
	FilterGroup1 = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup1.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	
	FilterGroup2 = FilterGroup1.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup2.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
	
	ItemFilter = FilterGroup2.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Terms");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	
	ItemFilter = FilterGroup2.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Contract");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	FilterGroup3 = FilterGroup1.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup3.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
	
	ItemFilter = FilterGroup3.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.BusinessOperation");
	ItemFilter.ComparisonType = DataCompositionComparisonType.InList;
	ItemFilter.RightValue = ListOfOperationsRequiringContract;
	
	ItemFilter = FilterGroup3.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Contract");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	Item.Appearance.SetParameterValue("MarkIncomplete", True);
	
	//
		
	TMCommonUse.SetUncheckBlank(
		ConditionalAppearance, "GoodsWarehouse", "Object.Goods.Warehouse", "Object.Goods.WarehouseIsRequired");
	
	TMCommonUse.SetUncheckBlank(
		ConditionalAppearance, "Warehouse", "Object.Warehouse", "WarehouseIsRequired");
	
	// Access data, set a mark
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.DateOfReceipt.Name);
	
	FilterGroup1 = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup1.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
	
	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.DateOfReceipt");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Status");
	ItemFilter.ComparisonType = DataCompositionComparisonType.InList;
	ValueList = New ValueList;
	ValueList.Add(Enums.PurchaseOrderStatuses.Confirmed_);
	ValueList.Add(Enums.PurchaseOrderStatuses.Closed);
	ItemFilter.RightValue = ValueList;
	
	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("AllLinesAreCanceled");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	Item.Appearance.SetParameterValue("MarkIncomplete", True);
		
	// Upload date, set a mark
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.DateOfShipment.Name);
	
	FilterGroup1 = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup1.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
	
	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.DateOfShipment");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Status");
	ItemFilter.ComparisonType = DataCompositionComparisonType.InList;
	ValueList = New ValueList;
	ValueList.Add(Enums.PurchaseOrderStatuses.Confirmed_);
	ValueList.Add(Enums.PurchaseOrderStatuses.Closed);
	ItemFilter.RightValue = ValueList;
	
	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("AllLinesAreCanceled");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	Item.Appearance.SetParameterValue("MarkIncomplete", True);
		
	// Date of access, uncheck
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.DateOfReceipt.Name);
	
	FilterGroup1 = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup1.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	
	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.DateOfReceipt");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	
	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Status");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotInList;
	ValueList = New ValueList;
	ValueList.Add(Enums.PurchaseOrderStatuses.Confirmed_);
	ValueList.Add(Enums.PurchaseOrderStatuses.Closed);
	ItemFilter.RightValue = ValueList;
	
	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("AllLinesAreCanceled");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	
	// Upload date, uncheck
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.DateOfShipment.Name);
	
	FilterGroup1 = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup1.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	
	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.DateOfShipment");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	
	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Status");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotInList;
	ValueList = New ValueList;
	ValueList.Add(Enums.PurchaseOrderStatuses.Confirmed_);
	ValueList.Add(Enums.PurchaseOrderStatuses.Closed);
	ItemFilter.RightValue = ValueList;
	
	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("AllLinesAreCanceled");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	
	//
	
	ProductsServer.SetConditionalAppearanceOfProductAssignment(ThisForm);
	
	//
	InstallationParameters = ReusablePackageServer.ParametersForSettingConditionalAppearanceForLinesWithMultiTurnContainers();
	
	InstallationParameters.Form                 = ThisForm;
	InstallationParameters.ThisIsAdmission        = True;
	
	ReusablePackageServer.SetConditionalAppearanceForLinesWithMultiTurnContainers(InstallationParameters);
	
	SetConditionalAppearanceForArticlesAndAnalytics();
	
	// Warehouse and division clearance
	// disabling the visibility of the warehouse if the work or service or product is written off for expenses.
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsWarehouse.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.BusinessOperation");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotInList;
	ItemFilter.RightValue = ProductsServer.ListOfBusinessOperationsExcludingServicesAndWorks();
	
	FilterGroup2 = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup2.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	
	ItemFilter = FilterGroup2.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.ItemsType");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	ItemFilter = FilterGroup2.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.ItemsType");
	ItemFilter.ComparisonType = DataCompositionComparisonType.InList;
	ValueList = New ValueList;
	ValueList.Add(Enums.ItemsTypes.Work_5);
	ValueList.Add(Enums.ItemsTypes.OperationService);
	ItemFilter.RightValue = ValueList;
	
	ItemFilter = FilterGroup2.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.ToExpenseAs");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	Item.Appearance.SetParameterValue("Visible", False);
	
	// disabling the visibility of the division if the goods or containers or commission operation, and the goods are not charged for expenses.

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsDepartment.Name);

	FilterGroup1 = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup1.GroupType = DataCompositionFilterItemsGroupType.OrGroup;

	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.BusinessOperation");
	ItemFilter.ComparisonType = DataCompositionComparisonType.InList;
	ItemFilter.RightValue = ProductsServer.ListOfBusinessOperationsExcludingServicesAndWorks();

	FilterGroup2 = FilterGroup1.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup2.GroupType = DataCompositionFilterItemsGroupType.AndGroup;

		ItemFilter = FilterGroup2.Items.Add(Type("DataCompositionFilterItem"));
		ItemFilter.LeftValue = New DataCompositionField("Object.Goods.ItemsType");
		ItemFilter.ComparisonType = DataCompositionComparisonType.InList;
		ValueList = New ValueList;
		ValueList.Add(Enums.ItemsTypes.OwnGoods);
		ValueList.Add(Enums.ItemsTypes.ReusablePackage);
		ItemFilter.RightValue = ValueList;
		
		ItemFilter = FilterGroup2.Items.Add(Type("DataCompositionFilterItem"));
		ItemFilter.LeftValue = New DataCompositionField("WarehouseGroup_");
		ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
		ItemFilter.RightValue = True;
		
		ItemFilter = FilterGroup2.Items.Add(Type("DataCompositionFilterItem"));
		ItemFilter.LeftValue = New DataCompositionField("Object.Goods.ToExpenseAs");
		ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
		ItemFilter.RightValue = False;

	Item.Appearance.SetParameterValue("Visible", False);
	
	// explanatory inscription for the division, if the warehouses are not in the tabular part

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsDepartment.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.ItemsType");
	ItemFilter.ComparisonType = DataCompositionComparisonType.InList;
	ValueList = New ValueList;
	ValueList.Add(Enums.ItemsTypes.OwnGoods);
	ValueList.Add(Enums.ItemsTypes.ReusablePackage);
	ItemFilter.RightValue = ValueList;

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.ToExpenseAs");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("WarehouseGroup_");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;

	Item.Appearance.SetParameterValue("ReadOnly", True);
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<khi ghi giảm vào chi phí>';
													|ru = '<при списании на расходы>';
													|en = '<when writing off as expenses>'; fa = '<when writing off as expenses>';
													|it = '<durante lo storno sulle spese>';
													|pl = '<przy wyksięgowaniu na rozchody>';
													|tr = '<gider yazılması>'"));
	Item.Appearance.SetParameterValue("TextColor", StyleColors.InaccessibleCellTextColor);
	
	// we do not fill out the Division if the position is purchased under the principal
	
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsDepartment.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.AssignmentType");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = PredefinedValue("Enum.AssignmentTypes.DeliveryForPrincipal");

	Item.Appearance.SetParameterValue("ReadOnly", True);
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<đối với mua hàng không theo chi nhánh>';
													|ru = '<для закупки не под принципала>';
													|en = '<for purchasing not for principal>'; fa = '<for purchasing not for principal>';
													|it = '<для закупки не под принципала>';
													|pl = '<for purchasing not for principal>';
													|tr = '<müvekkil kapsamında olmayan satın almalar için>'"));
	Item.Appearance.SetParameterValue("TextColor", StyleColors.InaccessibleCellTextColor);

	// Removing the mark of an unfilled division, if the Goods are not deductible for expenses, or Work on agency procurement

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsDepartment.Name);

	FilterGroup1 = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup1.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	
		ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
		ItemFilter.LeftValue = New DataCompositionField("Object.Goods.Department");
		ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
		
		FilterGroup3 = FilterGroup1.Items.Add(Type("DataCompositionFilterItemGroup"));
		FilterGroup3.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
		
			ItemFilter = FilterGroup3.Items.Add(Type("DataCompositionFilterItem"));
			ItemFilter.LeftValue = New DataCompositionField("Object.Goods.ItemsType");
			ItemFilter.ComparisonType = DataCompositionComparisonType.InList;
			ValueList = New ValueList;
			ValueList.Add(Enums.ItemsTypes.OwnGoods);
			ValueList.Add(Enums.ItemsTypes.ReusablePackage);
			ItemFilter.RightValue = ValueList;
			
			ItemFilter = FilterGroup3.Items.Add(Type("DataCompositionFilterItem"));
			ItemFilter.LeftValue = New DataCompositionField("Object.Goods.ToExpenseAs");
			ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
			ItemFilter.RightValue = False;
		
		FilterGroup2 = FilterGroup1.Items.Add(Type("DataCompositionFilterItemGroup"));
		FilterGroup2.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
		
		ItemFilter = FilterGroup2.Items.Add(Type("DataCompositionFilterItem"));
		ItemFilter.LeftValue = New DataCompositionField("Object.Goods.ItemsType");
		ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
		ItemFilter.RightValue = Enums.ItemsTypes.Work_5;
		
		ItemFilter = FilterGroup2.Items.Add(Type("DataCompositionFilterItem"));
		
		ItemFilter.LeftValue = New DataCompositionField("Object.Goods.AssignmentType");
		ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
		ItemFilter.RightValue = Enums.AssignmentTypes.DeliveryForPrincipal;
	
	Item.Appearance.SetParameterValue("MarkIncomplete", False);

	
	// setting the mark of an unfilled division, if the Product

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsDepartment.Name);

	FilterGroup0 = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup0.GroupType = DataCompositionFilterItemsGroupType.NotGroup;
	
		FilterGroup1 = FilterGroup0.Items.Add(Type("DataCompositionFilterItemGroup"));
		FilterGroup1.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
		
			ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
			ItemFilter.LeftValue = New DataCompositionField("Object.Goods.Department");
			ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
			
			FilterGroup3 = FilterGroup1.Items.Add(Type("DataCompositionFilterItemGroup"));
			FilterGroup3.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
			
				ItemFilter = FilterGroup3.Items.Add(Type("DataCompositionFilterItem"));
				ItemFilter.LeftValue = New DataCompositionField("Object.Goods.ItemsType");
				ItemFilter.ComparisonType = DataCompositionComparisonType.InList;
				ValueList = New ValueList;
				ValueList.Add(Enums.ItemsTypes.OwnGoods);
				ValueList.Add(Enums.ItemsTypes.ReusablePackage);
				ItemFilter.RightValue = ValueList;
				
				ItemFilter = FilterGroup3.Items.Add(Type("DataCompositionFilterItem"));
				ItemFilter.LeftValue = New DataCompositionField("Object.Goods.ToExpenseAs");
				ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
				ItemFilter.RightValue = False;

			FilterGroup2 = FilterGroup1.Items.Add(Type("DataCompositionFilterItemGroup"));
			FilterGroup2.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
			
				ItemFilter = FilterGroup2.Items.Add(Type("DataCompositionFilterItem"));
				ItemFilter.LeftValue = New DataCompositionField("Object.Goods.ItemsType");
				ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
				ItemFilter.RightValue = Enums.ItemsTypes.Work_5;
				
				ItemFilter = FilterGroup2.Items.Add(Type("DataCompositionFilterItem"));
				ItemFilter.LeftValue = New DataCompositionField("Object.Goods.AssignmentType");
				ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
				ItemFilter.RightValue = Enums.AssignmentTypes.DeliveryForPrincipal;
		
	Item.Appearance.SetParameterValue("MarkIncomplete", True);
	
	//
	
	OrdersServer.SetAppearanceOfCanceledLine(ConditionalAppearance,
		Items.Goods,
		Items.GoodsCanceled.Name,
		Items.GoodsCancellationReason.Name,
		Items.GoodsPrice.Name,
		Items.GoodsSum.Name);
	
	//
	
	LinesOfBusinessServer.EstablishConditionalAppearanceOfDirectionOfActivity(ThisForm);
	
	// Conditional appearance of quality control Attributes.
	Fields = QualityControl.Fields(
		Items.GoodsToControlQuality,
		Items.GoodsQualityConfirmationDate);
	FlagDisabled = New Array();
	DateIsOptional = New Array();
	Statuses = Enums.PurchaseOrderStatuses;
	ItemsTypes = Enums.ItemsTypes;
	QualityControl.AddFilter(FlagDisabled, "Object.Goods.Canceled", True);
	QualityControl.AddFilter(FlagDisabled, "Object.Goods.ToExpenseAs", True);
	QualityControl.AddFilter(FlagDisabled, "Object.Goods.ItemsType", ItemsTypes.Work_5);
	QualityControl.AddFilter(FlagDisabled, "Object.Goods.ItemsType", ItemsTypes.OperationService);
	QualityControl.AddFilter(DateIsOptional, "Object.Status", Statuses.NotApproved);
	QualityControl.AddFilter(DateIsOptional, "Object.Status", Statuses.Approved);
	QualityControl.SetupAppearance(ConditionalAppearance, Fields, FlagDisabled, DateIsOptional);
	
EndProcedure

&AtClient
Procedure SetWhetherWarehouseIsFull()
	
	WarehouseIsRequired  = ?(Object.Goods.Total("WarehouseIsRequired") = 0, 0, 1);
	
EndProcedure

&AtServer
Procedure UpdateVHFWarehouseObligation()
	
	FillParameters = New Structure("ThereAreWorks, ThereIsWriteOffForExpenses", True, True);
	StructureOfActions = New Structure;
 	StructureOfActions.Insert("WhenChangingProductType", FillParameters);
 	BatchProcessingOfTablePartServer.TreatTS(Object.Goods, StructureOfActions, Undefined);
	
	WarehouseIsRequired  = ?(Object.Goods.Total("WarehouseIsRequired") = 0, 0, 1);
	
EndProcedure

#Region OnChangeAttributes

&AtServer
Procedure PartnerOnChangeServer()
	
	DocumentPurchases = FormAttributeToValue("Object");
	DocumentPurchases.FillInDefaultPurchaseConditions(False);
	ResponsiblePersonsServer.FillInManagerSelectionList_(Items.Manager, DocumentPurchases);
	ResponsiblePersonsServer.InstallManager(DocumentPurchases);
	ValueToFormAttribute(DocumentPurchases, "Object");
	
	SetAvailabilityAgreements();
	
	DocumentCurrency = Object.Currency;
	
	CounterpartyLegEntInd = Common.ObjectAttributeValue(Object.Counterparty, "LegalEntityIndividual");

	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInFeatureAttribute", New Structure("Products", "ItemVariantsAreUsed"));
	StructureOfActions.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
	StructureOfActions.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));
	ProductsServer.FillInServiceDetailsForProductInCollection(Object.Goods, StructureOfActions);
	
	If Contract <> Object.Contract Then
		Contract = Object.Contract;
		
		Object.GoodsReceiptOption = PurchasesServer.GetProductAcceptanceOption(Undefined, Object.Contract);
		Object.ServiceReceiptOption = PurchasesServer.GetServiceAcceptanceOption(Object.Contract);
	EndIf;
	
	BusinessOperationOnChangeServer(False);
	
	ArrayOfChangedProps = New Array;
	ArrayOfChangedProps.Add("Terms");
	ArrayOfChangedProps.Add("Partner");
	ArrayOfChangedProps.Add("Contract");
	ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisForm, ArrayOfChangedProps);
	
	ToReturnReusablePackageOnChangeServer();
	
	PartnersProductsServer.FillInPartnerProductListByProductNameWhenPartnerChanges(Object.Goods, Object.Partner);
	
	If UseLinesOfBusiness Then
		LinesOfBusinessServer.FillInDefaultDirection(Object.LineOfBusiness, Object.Terms, Object.Contract);
	EndIf;
	
	FillInSubordinatePropertiesForStatistics("Partner");
	FillInTypeOfActivityVAT();
	FillInServiceDetailsForPurposeOfVTCH();
	FillInAndSetDeliveryAttributesServer("Partner");
	WarehouseOnChangeServer();
	WhenChangingDirectionOfActivityServer();
	GoodsDelivery.WhenReadingCreatingOrdersOnServer(Items, Object,,,SummaryDeliveryInformation);
	SetAvailabilityVisibilityOfContract();
	SetVisibilityOfReceiptDateFormElements();
	
	If QualityControl.UpdateActionParameters(
			Documents.PurchaseOrder,
			Object,
			CacheQualityControl) Then
		
		StructureOfActions = New Structure();
		StructureOfActions.Insert("FillInCheckQualityDateOfQualityConfirmation", CacheQualityControl);
		BatchProcessingOfTablePartServer.TreatTS(Object.Goods, StructureOfActions);
		
	EndIf;
	
	CashServerLocalization.ConfigureElementsOfOperationsWithSelfEmployed(ThisObject, False);
	
EndProcedure

&AtServer
Procedure PartnerClearingServer()
	
	ResponsiblePersonsServer.FillInManagerSelectionList_(Items.Manager, Object);
	ResponsiblePersonsServer.InstallManager(Object);
	
EndProcedure

&AtServer
Procedure TermsClearingServer()
	
	TermsOnChangeServer(False);
	FillInDefaultContract();
	
EndProcedure

&AtServer
Procedure TermsOnChangeServer(RecalculatePrices_ = True)
	
	PriceIncludesVAT = Object.PriceIncludesVAT;
	
	OldWarehouse = Object.Warehouse;
	ReFillBankAccount = False;
	
	If ValueIsFilled(Object.Terms) Then
		
		DocumentPurchases = FormAttributeToValue("Object");
		DocumentPurchases.FillInTermsOfPurchaseUnderAgreement(RecalculatePrices_);
		ValueToFormAttribute(DocumentPurchases, "Object");
		
		If Not RecalculatePrices_ And PriceIncludesVAT <> Object.PriceIncludesVAT Then
			
			StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForRecalculatingNDSWTCHAmount(Object);
			
			StructureOfActions = New Structure;
			StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
			StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
			
			BatchProcessingOfTablePartServer.TreatTS(Object.Goods, StructureOfActions, Undefined);
			
		EndIf;
		
		DocumentCurrency = Object.Currency;
		BusinessOperationOnChangeServer(False);
		ToReturnReusablePackageOnChangeServer();
		UpdateAvailabilityOfReturnContainerItems(ThisForm);
		
		If Contract <> Object.Contract Then
			Contract = Object.Contract;
			ReFillBankAccount = True;
			Object.GoodsReceiptOption = PurchasesServer.GetProductAcceptanceOption(Undefined, Object.Contract);
			Object.ServiceReceiptOption = PurchasesServer.GetServiceAcceptanceOption(Object.Contract);
		EndIf;
		
		If UseLinesOfBusiness Then
			LinesOfBusinessServer.FillInDefaultDirection(Object.LineOfBusiness, Object.Terms, Object.Contract);
		EndIf;
	
		If ValueIsFilled(Object.Organization) And ValueIsFilled(Object.PaymentMethod) Then

			If Not ValueIsFilled(Object.BankAccount) Then	
				ReFillBankAccount = True;
			EndIf;
			
			ParametersStructure = CashServer.DefaultParametersForFillingInCheckout();
			ParametersStructure.Organization    			= Object.Organization;
			ParametersStructure.PaymentMethod 			= Object.PaymentMethod;
			ParametersStructure.LineOfBusiness = Object.LineOfBusiness;
			ParametersStructure.CashAccount 					= Object.CashAccount;

			Object.CashAccount = SettingsValueCached.GetOrganizationSDefaultSalesRegister(ParametersStructure);
			
		EndIf;
		
		WarehouseOnChangeServer();
		
		StructureOfActions = New Structure;
		StructureOfActions.Insert("FillInFeatureAttribute", New Structure("Products", "ItemVariantsAreUsed"));
		StructureOfActions.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
		StructureOfActions.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));
		ProductsServer.FillInServiceDetailsForProductInCollection(Object.Goods, StructureOfActions);
		
		UpdateDuplicateDependentDetails();
		CalculateOrderTotals(ThisForm);
		
	EndIf;
	
	ChangedBankingDetails = ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisForm, "Terms, Contract");
	If ChangedBankingDetails.Property("ARAPObjectSettings") Then
		If UseLinesOfBusiness Then
			LinesOfBusinessServer.FillInDefaultDirection(Object.LineOfBusiness, Object.Terms, Object.Contract);
		EndIf;
	EndIf;
	If ChangedBankingDetails.Property("ForeignCurrencyTransaction") Then
		ReFillBankAccount = True;
	EndIf;
	
	If ReFillBankAccount Then
		Object.BankAccount = Catalogs.CompaniesBankAccounts.EmptyRef();
		PurchasesServerCall.FillInBankAccountsUnderAgreement(Object.Contract, Object.BankAccount);
		Object.BankAccount = GetOrganizationSDefaultBankAccountServer();
	EndIf;
	
	FillInFinancialAccountingGroup();
	SetAvailabilityVisibilityOfContract();
	
	ChangedBankingDetails = FillInSubordinatePropertiesForStatistics("Terms");
	For Each ChangedProps In ChangedBankingDetails Do
		If ChangedProps.Key = "Organization" Then
			OrganizationOnChangeServer();
		ElsIf ChangedProps.Key = "Warehouse" Then
			WarehouseOnChangeServer();
		EndIf;
	EndDo;
	ResponsiblePersonsServer.FillInManager_(Object);
	FillInSubordinatePropertiesForStatistics("Contract");
	ResponsiblePersonsServer.FillInManagerSelectionList_(Items.Manager, Object);
	ResponsiblePersonsServer.InstallManager(Object);
	
	WhenChangingDirectionOfActivityServer();
	
	GoodsDelivery.WhenReadingCreatingOrdersOnServer(Items, Object,,,SummaryDeliveryInformation);
	
	SetVisibilityOfReceiptDateFormElements();
	If OldWarehouse <> Object.Warehouse
		Or QualityControl.UpdateActionParameters(
			Documents.PurchaseOrder,
			Object,
			CacheQualityControl) Then
			
		StructureOfActions = New Structure();
		StructureOfActions.Insert("FillInCheckQualityDateOfQualityConfirmation", CacheQualityControl);
		BatchProcessingOfTablePartServer.TreatTS(Object.Goods, StructureOfActions);
		
	EndIf;
	
EndProcedure

&AtServer
Procedure CurrencyOnChangeServer(NewCurrency, RecalculateAmounts)
	
	FillInDefaultContract();
	Object.BankAccount = GetOrganizationSDefaultBankAccountServer();
	
	If RecalculateAmounts Then
		OldCurrency = DocumentCurrency;
		LocalAccountingCurrency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Object.Organization);
		CourseStructures = ARAPAccountingServer.ExchangeRatesForTranslation(ThisForm, OldCurrency, NewCurrency, LocalAccountingCurrency, Object.Date);
		StructureOfOldCurrencyRates = CourseStructures.StructureOfOldCurrencyRates;
		StructureOfNewCurrencyRates  = CourseStructures.StructureOfNewCurrencyRates;
		
		PriceManagementSystem.ConvertTabularAmountsToCurrency(
			Object.Goods,
			Object.PriceIncludesVAT,
			OldCurrency,
			NewCurrency,
			StructureOfOldCurrencyRates,
			StructureOfNewCurrencyRates,
			False,
			True);
		TMCommonUse.FillInDuplicateDependentPropsInCollection(Object.Goods, DependentDetails());
		CalculateOrderTotals(ThisForm);
		PriceManagementSystem.DistributeAmountByPaymentStages(Object, AmountOrdered, PackageDepositValue);
	EndIf;
	
	FillInSubordinatePropertiesForStatistics("Currency");
	
	ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisForm, "Currency");
	If QualityControl.UpdateActionParameters(
			Documents.PurchaseOrder,
			Object,
			CacheQualityControl) Then
			
		StructureOfActions = New Structure();
		StructureOfActions.Insert("FillInCheckQualityDateOfQualityConfirmation", CacheQualityControl);
		BatchProcessingOfTablePartServer.TreatTS(Object.Goods, StructureOfActions);
		
	EndIf;
	
EndProcedure

&AtServer
Procedure CounterpartyOnChangeServer()
	
	SetAvailabilityVisibilityOfContract();
	
	If ValueIsFilled(Object.Counterparty) Then
		FillInDefaultContract();
	EndIf;
	
	If UseLinesOfBusiness Then
		LinesOfBusinessServer.FillInDefaultDirection(Object.LineOfBusiness, Object.Terms, Object.Contract);
		FillInVATTaxationPurchases();
		VATTaxationOnChangeServer(Undefined);
	EndIf;
	
	WhenChangingDirectionOfActivityServer();
	ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisForm, "Counterparty");
	
	WhenChangingKeyDetailsStatusOfEDO();
	
	OriginalViewOfCounterparty = CounterpartyLegEntInd;
	CounterpartyLegEntInd = Common.ObjectAttributeValue(Object.Counterparty, "LegalEntityIndividual");
	
	If OriginalViewOfCounterparty <> CounterpartyLegEntInd Then
		
		CashServerLocalization.FillInAttributeForPurchasingFromSelfEmployedPerson(ThisObject);
		OperationWithSelfEmployedWhenChangingOnServer();
		
	EndIf;
	
	CashServerLocalization.ConfigureElementsOfOperationsWithSelfEmployed(ThisObject, False);
	If QualityControl.UpdateActionParameters(
			Documents.PurchaseOrder,
			Object,
			CacheQualityControl) Then
			
		StructureOfActions = New Structure();
		StructureOfActions.Insert("FillInCheckQualityDateOfQualityConfirmation", CacheQualityControl);
		BatchProcessingOfTablePartServer.TreatTS(Object.Goods, StructureOfActions);
		
	EndIf;
	
EndProcedure

&AtServer
Procedure OrganizationOnChangeServer()
	
	SetAvailabilityVisibilityOfContract();
	
	If ValueIsFilled(Object.Organization) Then
		
		FillInDefaultContract();
		
		If UseLinesOfBusiness Then
			LinesOfBusinessServer.FillInDefaultDirection(Object.LineOfBusiness, Object.Terms, Object.Contract);
		EndIf;
		
		FillInTypeOfActivityVAT();
		FillInVATTaxationPurchases();
		VATTaxationOnChangeServer(Undefined);
		
	EndIf;
	
	CashServer.CheckFillInOrganizationSBankAccountByOwner(Object.Organization,
		Object.BankAccount, , Object.LineOfBusiness, Object.ForeignCurrencyTransaction);
	CashServer.CheckOrganizationSSalesRegisterByOwner(Object.Organization, Object.CashAccount, Object.PaymentMethod, Object.LineOfBusiness);
	
	FillInSubordinatePropertiesForStatistics("Organization");
	ResponsiblePersonsServer.InstallManager(Object);
	
	WhenChangingDirectionOfActivityServer();
	ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisForm, "Organization");
	WhenChangingKeyDetailsStatusOfEDO();
	DocumentCurrency = Object.Currency;
	
	CashServerLocalization.ConfigureElementsOfOperationsWithSelfEmployed(ThisObject, False);
	If QualityControl.UpdateActionParameters(
			Documents.PurchaseOrder,
			Object,
			CacheQualityControl) Then
			
		StructureOfActions = New Structure();
		StructureOfActions.Insert("FillInCheckQualityDateOfQualityConfirmation", CacheQualityControl);
		BatchProcessingOfTablePartServer.TreatTS(Object.Goods, StructureOfActions);
		
	EndIf;
	
EndProcedure

&AtServer
Procedure StatusOnChangeServer()
	
	SetAvailabilityOfItemsByStatusServer();
	
	If Object.Goods.Count() > 0 Then
		
		// In the status "Confirmed" - we will put all the undone lines in the expected receipt
		// And we will offer the user to fill in the receipt date in the lines in which this date is not filled in.
		If Object.Status = PredefinedValue("Enum.PurchaseOrderStatuses.Confirmed_") Or
			Object.Status = PredefinedValue("Enum.PurchaseOrderStatuses.Closed") Then
			
			FillIn_BlankReceiptDatesServer();
			
		EndIf;
		
	EndIf;
	
EndProcedure

&AtServer
Procedure BusinessOperationOnChangeServer(ChallengeByCommand = True)
	
	If ChallengeByCommand Then
		FillInDefaultContract();
		
		If ValueIsFilled(Object.Terms)
			And ValueIsFilled(Object.BusinessOperation) Then
			
			ThisIsTwoWay = EconomicOperationsOfSeparatePurchase(True, True).Find(Object.BusinessOperation) <> Undefined;
			
			AgreementOperation	= Common.ObjectAttributeValue(Object.Terms, "BusinessOperation");
			
			If ThisIsTwoWay Then
				BasicDocumentOperation = PurchasesServer.MainEconomicOperationOfSeparatePurchase(Object.BusinessOperation);
			Else
				BasicDocumentOperation = Object.BusinessOperation;
			EndIf;
			
			ContractsAreUsed = Common.ObjectAttributeValue(Object.Terms, "ContractsAreUsed");
			
			Object.Terms = ?(BasicDocumentOperation = AgreementOperation,
									Object.Terms,
									Catalogs.TermsOfPurchaseFromVendors.EmptyRef());
									
			Object.Terms = ?(ThisIsTwoWay And Not ContractsAreUsed,
									Catalogs.TermsOfPurchaseFromVendors.EmptyRef(),
									Object.Terms);
			
		EndIf;
	EndIf;
	
	If Object.BusinessOperation = Enums.BusinessTransactions.ConsignmentProcurement Then
		
		If UseDiscountAdjustmentsInPurchases Then
			PurchasesServer.CancelManualDiscounts(Object, "Goods");
			TMCommonUse.FillInDuplicateDependentPropsInCollection(Object.Goods, DependentDetails());
		EndIf;
		
		Object.ToReturnReusablePackage = False;
		Object.PackageDepositIsRequired = False;
		ToReturnReusablePackageOnChangeServer();
		
	ElsIf Object.BusinessOperation = Enums.BusinessTransactions.PurchaseByImport
				Or Object.BusinessOperation = Enums.BusinessTransactions.ImportGoodsInTransit
				Or Object.BusinessOperation = Enums.BusinessTransactions.ImportFromEAEU
				Or Object.BusinessOperation = Enums.BusinessTransactions.ImportFromEAEUGoodsInTransit
				Or Object.BusinessOperation = Enums.BusinessTransactions.ImportFromEAEUInvoicedDelivery Then
		
		Object.ToReturnReusablePackage = False;
		Object.PackageDepositIsRequired = False;
		ToReturnReusablePackageOnChangeServer();
		
	ElsIf Object.BusinessOperation = Enums.BusinessTransactions.ReceivingForStorageWithRightOfSale Then
		
		Object.VATTaxation = Enums.VATTaxationTypes.SaleIsNotSubjectToVAT;
		Object.PriceIncludesVAT = False;
		
	EndIf;
	
	UpdateDuplicateDependentDetails();
	CalculateOrderTotals(ThisForm);
	SetVisibilityOfElementsByOperationServer();
	AdjustItemSelectionSettings();
	UpdateAvailabilityOfReturnContainerItems(ThisForm);
	UpdateTextDocumentsBasedOn();
	
	FillInVATTaxationPurchases();
	VATTaxationOnChangeServer(Undefined);
	SetUpWriteOffColumnsForExpensesTSProducts();
	FillInTypeOfActivityVAT();
	
	ArticleSelectionOptions = Documents.PurchaseOrder.ItemsAndDimensionsSelectionParameters(Object.BusinessOperation);
	IncomeAndExpensesServer.WhenChangingArticleSelectionParameters(ThisForm, ArticleSelectionOptions);
	
	ARAPAccountingFormWork.WhenChangingParametersOfMechanism(ThisForm);
	
	CashServerLocalization.FillInAttributeForPurchasingFromSelfEmployedPerson(ThisObject);
	OperationWithSelfEmployedWhenChangingOnServer();
	CashServerLocalization.ConfigureElementsOfOperationsWithSelfEmployed(ThisObject, False);
	If QualityControl.UpdateActionParameters(
			Documents.PurchaseOrder,
			Object,
			CacheQualityControl) Then
			
		StructureOfActions = New Structure();
		StructureOfActions.Insert("FillInCheckQualityDateOfQualityConfirmation", CacheQualityControl);
		BatchProcessingOfTablePartServer.TreatTS(Object.Goods, StructureOfActions);
		
	EndIf;
	
EndProcedure

&AtServer
Procedure PriceIncludesVATOnChangeServer(CachedValues)
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForRecalculatingNDSWTCHAmount(Object);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	BatchProcessingOfTablePartServer.TreatTS(Object.Goods, StructureOfActions, CachedValues);
	
	TMCommonUse.FillInDuplicateDependentPropsInCollection(Object.Goods, DependentDetails());
	CalculateOrderTotals(ThisForm);
	
EndProcedure

&AtServer
Procedure VATTaxationOnChangeServer(CachedValues)
	
	CachedValuesAreServiceValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues(); 
	StructureOfActions = New Structure;
	StructureOfActions.Insert("AdjustVATRate",
		BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRate(Object, True, Object.ToReturnReusablePackage));
	
	BatchProcessingOfTablePartServer.TreatTS(Object.Goods, StructureOfActions, CachedValuesAreServiceValues);
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForRecalculatingNDSWTCHAmount(Object);
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		CachedValuesAreServiceValues.ProcessedRows,
		StructureOfActions,
		Object.Goods,
		CachedValues);
	
	TMCommonUse.FillInDuplicateDependentPropsInCollection(Object.Goods, DependentDetails());
	CalculateOrderTotals(ThisForm);

	VATAccountingERP.SetVisibilityOfCommandAndFillInVATRate(ThisObject);

EndProcedure

&AtServer
Procedure WarehouseOnChangeServer(DirectModificationOfWarehouseField = False)
	
	WarehouseGroup_ = Catalogs.Warehouses.ThisGroupAndWarehousesAreUsedByWTCProcurementDocuments(Object.Warehouse);
	Items.GoodsFillInTheWarehouseInSelectedLines.Enabled = WarehouseGroup_;
	
	WarehousesServer.FillInWarehousesInTablePart(Object.Warehouse, WarehouseGroup_, Object.Goods, False, "ToExpenseAs");
	
	WhenChangingWarehouseInTablePartServer();
	
	SetParametersForSelectingProductsWarehouse();
	
	FillInListOfDeliveryAddressesForSupplier(True);
	
	FillInTypeOfActivityVAT();
	
	ControlProductRange = ProductRangeServerCached.ControlProductRange(Object.Warehouse, Object.Date);
	
	If ControlProductRange Then
		ProductRangeServer.CheckAssortmentOfTableOfSelectedProducts(Object, "Warehouse");
	EndIf;
	
	If Not WarehouseGroup_ Then
		Items.ProductsGroupRecipient.Title = NStr("vi = 'Bộ phận-nơi nhận';
													|ru = 'Подразделение-получатель';
													|en = 'Receiving business unit'; fa = 'واحد تجاری دریافت‌کننده';
													|it = 'Reparto-destinatario';
													|pl = 'Dział-odbiorca';
													|tr = 'Alıcı departman'");
	Else
		Items.ProductsGroupRecipient.Title = NStr("vi = 'Người nhận';
													|ru = 'Получатель';
													|en = 'Recipient'; fa = 'گیرنده';
													|it = 'Destinatario';
													|pl = 'Odbiorca';
													|tr = 'Alıcı'");
	EndIf;
	If QualityControl.UpdateActionParameters(
			Documents.PurchaseOrder,
			Object,
			CacheQualityControl,
			 DirectModificationOfWarehouseField) Then
			
		StructureOfActions = New Structure();
		StructureOfActions.Insert("FillInCheckQualityDateOfQualityConfirmation", CacheQualityControl);
		BatchProcessingOfTablePartServer.TreatTS(Object.Goods, StructureOfActions);
		
	EndIf;
	
EndProcedure

&AtServer
Procedure ContractOnChangeServer(DirectModificationOfContractField = False)
	
	ForeignCurrencyTransaction = Object.ForeignCurrencyTransaction;
	
	ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisObject, "Contract");
	
	If Object.ForeignCurrencyTransaction <> ForeignCurrencyTransaction Then
		Object.BankAccount = Catalogs.CompaniesBankAccounts.EmptyRef();
	EndIf;
	
	PurchasesServerCall.FillInBankAccountsUnderAgreement(Object.Contract, Object.BankAccount);
	Object.BankAccount = GetOrganizationSDefaultBankAccountServer();
	
	FillInFinancialAccountingGroup();

	If UseLinesOfBusiness Then
		LinesOfBusinessServer.FillInDefaultDirection(Object.LineOfBusiness, Object.Terms, Object.Contract);
	EndIf;
	
	OptionOfExecutionOfContractOfPurchases = PurchasesServer.GetVariantOfProcurementContract(Object.Contract);
	OptionOfProcessingDocumentsForServices = PurchasesServer.GetVariantOfRegistrationOfDocumentsForAdmissionToServices(Object.Contract);
	
	FillInVATTaxationPurchases();
	VATTaxationOnChangeServer(Undefined);
	
	FillInTypeOfActivityVAT();
	ResponsiblePersonsServer.FillInManagerSelectionList_(Items.Manager, Object);
	ResponsiblePersonsServer.InstallManager(Object);
	FillInSubordinatePropertiesForStatistics("Contract");
	WhenChangingDirectionOfActivityServer();
	
	If Contract <> Object.Contract Then
		Contract = Object.Contract;
		
		Object.GoodsReceiptOption = PurchasesServer.GetProductAcceptanceOption(Undefined, Object.Contract);
		Object.ServiceReceiptOption = PurchasesServer.GetServiceAcceptanceOption(Object.Contract);
	EndIf;
	
	GoodsDelivery.WhenReadingCreatingOrdersOnServer(Items, Object,,,SummaryDeliveryInformation);
	
	WhenChangingKeyDetailsStatusOfEDO();
	SetUpWriteOffColumnsForExpensesTSProducts();
	
	CashServerLocalization.ConfigureElementsOfOperationsWithSelfEmployed(ThisObject, False);
	If QualityControl.UpdateActionParameters(
			Documents.PurchaseOrder,
			Object,
			CacheQualityControl,
			DirectModificationOfContractField) Then
			
		StructureOfActions = New Structure();
		StructureOfActions.Insert("FillInCheckQualityDateOfQualityConfirmation", CacheQualityControl);
		BatchProcessingOfTablePartServer.TreatTS(Object.Goods, StructureOfActions);
		
	EndIf;
	
EndProcedure

&AtServer
Function DateOnChangeServer(RecalculatePrices_2)
	
	If RecalculatePrices_2 Then
		PricesCalculated = FillThePricesByTermsOfSalesServer(True);
	Else
		PricesCalculated = False;
	EndIf;
	
	FillInTypeOfActivityVAT();
	
	CachedValuesAreServiceValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues(); 
	StructureOfActions = New Structure;
	StructureOfActions.Insert("AdjustVATRate",
		BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRate(Object, True, Object.ToReturnReusablePackage));
	
	BatchProcessingOfTablePartServer.TreatTS(Object.Goods, StructureOfActions, CachedValuesAreServiceValues);
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForRecalculatingNDSWTCHAmount(Object);
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		CachedValuesAreServiceValues.ProcessedRows,
		StructureOfActions,
		Object.Goods);
	
	TMCommonUse.FillInDuplicateDependentPropsInCollection(Object.Goods, DependentDetails());
	CalculateOrderTotals(ThisObject);
	ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisObject, "Date");
	
	Return PricesCalculated;
	
EndFunction

&AtServer
Procedure OperationWithSelfEmployedWhenChangingOnServer()

	FillInDefaultContract();
	CashServerLocalization.OperationWithSelfEmployedPersonOnChange(ThisObject, False);
	VATTaxationOnChangeServer(Undefined);

EndProcedure

&AtServer
Procedure ApprovalDateForChangesOnServer()
	ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisForm, "ApprovalDate");
EndProcedure

&AtServer
Procedure ShipmentDateWhenChangedOnServer()
	
	If Not ValueIsFilled(Object.DateOfShipment) Then
		Object.DeliveryDuration = 0;
		Object.DateOfReceipt = Date(1,1,1);
	Else
		Object.DateOfReceipt = DateAccordingToCompanyCalendar(Object.DateOfShipment, Object.DeliveryDuration);
	EndIf;
	
	FillIn_ReceiptDatesServer(Object.DateOfReceipt);
	
	ProvisionInDocumentsServer.FillInDetailsInCollection(Object.Goods, "DateOfShipment", Object.DateOfShipment);
	ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisObject, "Goods.DateOfShipment");
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForRecalculatingNDSWTCHAmount(Object);
		
	StructureOfActions = New Structure;

	StructureOfActions.Insert("AdjustVATRate", BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRate(Object, True));
	StructureOfActions.Insert("FillInVATRateForReturnableContainers", Object.ToReturnReusablePackage);
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	BatchProcessingOfTablePartServer.TreatTS(Object.Goods, StructureOfActions, Undefined);
	UpdateDuplicateDependentDetails();
		
	CalculateOrderTotals(ThisObject);
	
EndProcedure

&AtServer
Procedure DateOfReceiptOnChangeServer()
	
	If ValueIsFilled(Object.DateOfShipment) Then
		Object.DeliveryDuration = DeliveryTimeByCalendar(
			Object.DateOfShipment, Object.DateOfReceipt, EnterpriseCalendar);
	Else
		Object.DateOfShipment = DateAccordingToCompanyCalendar(Object.DateOfReceipt, -Object.DeliveryDuration);
		If Object.DateOfShipment < Object.Date Then
			Object.DateOfShipment = Min(Object.DateOfReceipt, DateOfShipmentByCalendar(
				Object.Date, Object.DateOfReceipt, Object.DeliveryDuration, EnterpriseCalendar));
			Object.DeliveryDuration = DeliveryTimeByCalendar(
				Object.DateOfShipment, Object.DateOfReceipt, EnterpriseCalendar);
		EndIf; 
		ProvisionInDocumentsServer.FillInDetailsInCollection(Object.Goods, "DateOfShipment", Object.DateOfShipment);
	EndIf;
	
	FillIn_ReceiptDatesServer(Object.DateOfReceipt);
	
	ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisObject, StrSplit("Goods.DateOfReceipt,Goods.DateOfShipment",","));
	
EndProcedure

&AtServer
Procedure OneDateReceiptOnChangeServer()
	
	If Object.OneDateReceipt Then
		
		Object.DateOfShipment = MaximumShipmentDate();
		FillInShippingDatesServer(Object.DateOfShipment);
		ShipmentDateWhenChangedOnServer();
		ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisObject, "Goods.DateOfShipment");
		
	Else
		If QualityControl.UpdateActionParameters(
				Documents.PurchaseOrder,
				Object,
				CacheQualityControl) Then
			
			StructureOfActions = New Structure();
			StructureOfActions.Insert("FillInCheckQualityDateOfQualityConfirmation", CacheQualityControl);
			BatchProcessingOfTablePartServer.TreatTS(Object.Goods, StructureOfActions);
			
		EndIf;
	EndIf;
	
	SetVisibilityOfReceiptDateFormElements();
	
EndProcedure

&AtClient
Procedure ToReturnReusablePackageOnChange(Item)
	
	ToReturnReusablePackageOnChangeServer();
	
EndProcedure

&AtServer
Procedure ProductsAfterDeletionOnServer(ThereIsChangeInShippingDates)
	
	CalculateOrderTotals(ThisForm);
	WhenChangingWarehouseInTablePartServer();
	If ThereIsChangeInShippingDates Then
		ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisObject, "Goods.DateOfShipment");
	EndIf;
	
EndProcedure

&AtServer
Procedure GoodsCanceledOnChangeATServer()
	
	ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisObject, "Goods.DateOfShipment");
	
EndProcedure

&AtServer
Procedure WhenChangingWarehouseInTablePartServer()
	
	WarehousesServer.WhenChangingWarehouseInTablePart(Object.Goods, WarehouseTable, WarehouseGroup_);
	TotalWarehouses_ = WarehouseTable.Count();
	WarehousesClientServer.UpdateWarehouseGroupImage(SeveralWarehousesText, Items.PictureMultipleWarehouses, TotalWarehouses_);
	
EndProcedure

&AtServer
Procedure LineOfBusinessOnChangeServer()
	
	If Object.ARAPObjectSettings = Enums.ARAPObjectSettings.ByCounterpartyContracts Then
		FillInDefaultContract();
	EndIf;
	
	WhenChangingDirectionOfActivityServer();
	ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisForm, "LineOfBusiness");
	If QualityControl.UpdateActionParameters(
			Documents.PurchaseOrder,
			Object,
			CacheQualityControl) Then
			
		StructureOfActions = New Structure();
		StructureOfActions.Insert("FillInCheckQualityDateOfQualityConfirmation", CacheQualityControl);
		BatchProcessingOfTablePartServer.TreatTS(Object.Goods, StructureOfActions);
		
	EndIf;
	
EndProcedure

&AtServer
Procedure WhenChangingDirectionOfActivityServer()
	
	ModifiedRows = LinesOfBusinessServer.WhenChangingDirectionOfActivity(ThisObject);
	PurchasesServer.ClearDetailsOfChargeForExpensesWhenSettingDestinationInTablePart(ModifiedRows);
	
EndProcedure

&AtClient
Procedure RequestedDeliveryDateOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	RequestedDeliveryDateOnChangeServer();
EndProcedure

&AtServer
Procedure RequestedDeliveryDateOnChangeServer()
	ARAPAccountingFormWork.WhenChangingParametersOfMechanism(ThisForm);
EndProcedure

#EndRegion

#Region PricingAndDiscounts

&AtServer
Function FillThePricesByTermsOfSalesServer(OnAllLines = False, ErrorText = "")

	If Object.BusinessOperation <> Enums.BusinessTransactions.ReceivingForStorageWithRightOfSale
		And Common.ObjectAttributeValue(Object.Terms, "PriceIncludesVAT") <> Object.PriceIncludesVAT Then
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
		For Each String In Items.Goods.SelectedRows Do
			RowsArray.Add(Object.Goods.FindByID(String));
		EndDo;
	EndIf;
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateAmount");
	StructureOfActions.Insert("RecalculateAmountWithVAT",StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateVATAmount",StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountOfManualDiscount");
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountManualDiscount", New Structure("RecalculateAmountOfManualDiscount_", False));
	
	FillParameters = PartnerPricesFillingServer.NewFillOptionsFillPrices();
	FillParameters.Insert("PopulationFields", "Price, VendorPriceKind");
	FillParameters.Insert("Date", Object.Date);
	FillParameters.Insert("Organization", Object.Organization);
	FillParameters.Insert("Currency", Object.Currency);
	FillParameters.Insert("Terms", Object.Terms);
	FillParameters.Insert("VATTaxation", Object.VATTaxation);
	
	PricesCalculated = PartnerPricesFillingServer.FillInPrices(
		Object.Goods,
		RowsArray, // Array of strings
		FillParameters,
		StructureOfActions);
	TMCommonUse.FillInDuplicateDependentPropsInCollection(Object.Goods, DependentDetails());
	CalculateOrderTotals(ThisForm);
	
	Return PricesCalculated;
	
EndFunction

&AtServer
Procedure AssignManualDiscountOnServer(AmountOfDiscountMarkUp, Val SelectedRows, AddressInTempStorage)
	
	DiscountParameters = DiscountsMarkupsFillingServer.NewOptionsAssignManualDiscount();
	DiscountParameters.AutomaticDiscountsAreUsed = False;
	DiscountParameters.CalculateAmountWithVAT			 = True;
	DiscountParameters.SelectedRows				 = SelectedRows;
	DiscountParameters.AddressInTempStorage		 = AddressInTempStorage;
	
	DiscountsMarkupsFillingServer.AssignAManualDiscount(Object, "Goods", AmountOfDiscountMarkUp, DiscountParameters);
	TMCommonUse.FillInDuplicateDependentPropsInCollection(Object.Goods, DependentDetails());
	
EndProcedure

&AtServer
Procedure CancelManualDiscountsOnServer()
	
	DiscountsMarkupsFillingServer.CancelManualDiscounts(Object, "Goods", False, True);
	TMCommonUse.FillInDuplicateDependentPropsInCollection(Object.Goods, DependentDetails());
	
EndProcedure

&AtServer
Function FillInThePricesOfTheSelectedLinesByTheTypeOfSupplierSPriceServer(VendorPriceKind)
	
	RowsArray = New Array;
	For Each String In Items.Goods.SelectedRows Do
		RowsArray.Add(Object.Goods.FindByID(String));
		
	EndDo;
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateAmount");
	StructureOfActions.Insert("RecalculateAmountWithVAT",StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateVATAmount",StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountOfManualDiscount");
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountManualDiscount", New Structure("RecalculateAmountOfManualDiscount_", False));
	
	FillParameters = PartnerPricesFillingServer.NewFillOptionsFillPrices();
	FillParameters.Insert("PopulationFields", "Price, VendorPriceKind");
	FillParameters.Insert("Date", Object.Date);
	FillParameters.Insert("Organization", Object.Organization);
	FillParameters.Insert("Currency", Object.Currency);
	FillParameters.Insert("VendorPriceKind", VendorPriceKind);
	PricesCalculated = PartnerPricesFillingServer.FillInPrices(
		Object.Goods,
		RowsArray,
		FillParameters,
		StructureOfActions);
	
	TMCommonUse.FillInDuplicateDependentPropsInCollection(Object.Goods, DependentDetails());
	CalculateOrderTotals(ThisForm);
	
	Return PricesCalculated;
	
EndFunction

&AtServer
Function AdjustPricesForGoodsReceiptsServer()
	
	PricesAdjusted = False;
	
	Query = New Query("SELECT
	|	GoodsFromOrder.RowCode                                                  AS RowCode,
	|	GoodsFromOrder.Price                                                       AS Price,
	|	CAST(GoodsFromOrder.Package AS Catalog.PackagesAndUnitsOfMeasure) AS Package,
	|	CAST(GoodsFromOrder.Products AS Catalog.Products)         AS Products,
	|	GoodsFromOrder.Count                                                 AS Count,
	|	GoodsFromOrder.ManualDiscount                                          AS ManualDiscount
	|INTO OrderTime
	|FROM
	|	&GoodsFromOrder AS GoodsFromOrder
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	GoodsFromOrder.RowCode                                                  AS RowCode,
	|	GoodsFromOrder.Price                                                       AS Price,
	|	GoodsFromOrder.Package                                                   AS Package,
	|	GoodsFromOrder.Products                                               AS Products,
	|	GoodsFromOrder.Count                                                 AS Count,
	|	GoodsFromOrder.ManualDiscount                                          AS ManualDiscount,
	|	ISNULL(&QueryTextPackagingFactor1, 1)                          AS ConversionFactorOfPackaging
	|
	|INTO GoodsFromOrder
	|FROM
	|	OrderTime AS GoodsFromOrder
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	PurchaseOrders.Recorder                                          AS DocumentInflow
	|INTO ReceiptDocuments
	|FROM
	|	AccumulationRegister.PurchaseOrders AS PurchaseOrders
	|	WHERE
	|		PurchaseOrders.PurchaseOrder = &PurchaseOrder
	|		AND PurchaseOrders.Recorder REFS Document.VendorInvoice
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	GoodsReceipts.RowCode                                            AS RowCode,
	|	GoodsReceipts.Count                                           AS Count,
	|	ReceiptDocuments.DocumentInflow.Currency                        AS Currency,
	|	ReceiptDocuments.DocumentInflow.ARAPCurrency          AS ARAPCurrency,
	|	ReceiptDocuments.DocumentInflow.CourseDenominator               AS CourseDenominator,
	|	ReceiptDocuments.DocumentInflow.CourseNumerator                 AS CourseNumerator,
	|	BEGINOFPERIOD(ReceiptDocuments.DocumentInflow.Date, DAY)     AS Date,
	|	GoodsReceipts.Price                                                 AS Price,
	|	GoodsReceipts.Sum                                                AS Sum,
	|	GoodsReceipts.ManualDiscount                                    AS ManualDiscount,
	|	ISNULL(&QueryTextPackagingFactor2, 1)                         AS ConversionFactorOfPackaging
	|INTO GoodsReceipts
	|FROM
	|	ReceiptDocuments AS ReceiptDocuments
	|	LEFT JOIN Document.VendorInvoice.Goods AS GoodsReceipts
	|		ON ReceiptDocuments.DocumentInflow = GoodsReceipts.Ref
	|WHERE
	|	GoodsReceipts.RowCode > 0
	|	AND GoodsReceipts.PurchaseOrder = &PurchaseOrder
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	GoodsReceipts.Currency                                               AS Currency,
	|	GoodsReceipts.Date                                                 AS Date
	|INTO DatesOfExchangeRatesOfReceipts
	|FROM
	|	GoodsReceipts AS GoodsReceipts
	|	WHERE
	|		NOT GoodsReceipts.Currency = &DocumentCurrency
	|		AND NOT GoodsReceipts.ARAPCurrency = &DocumentCurrency 
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|
	|SELECT DISTINCT
	|	DatesOfExchangeRatesOfReceipts.Currency                                      AS Currency,
	|	DatesOfExchangeRatesOfReceipts.Date                                        AS Date
	|INTO CurrencyExchangeRateDates
	|FROM
	|	DatesOfExchangeRatesOfReceipts AS DatesOfExchangeRatesOfReceipts
	|
	|UNION ALL
	|
	|SELECT
	|	CAST(&DocumentCurrency AS Catalog.Currencies)                       AS Currency,
	|	DatesOfExchangeRatesOfReceipts.Date                                        AS Date
	|
	|FROM
	|	DatesOfExchangeRatesOfReceipts AS DatesOfExchangeRatesOfReceipts
	|
	|INDEX BY
	|	Currency,
	|	Date
	|	
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT 
	|	NestedQuery.Date                                                   AS Date,
	|	NestedQuery.Currency                                                 AS Currency,
	|	ExchangeRates.CourseNumerator                                               AS CourseNumerator,
	|	ExchangeRates.CourseDenominator                                             AS CourseDenominator
	|INTO ExchangeRatesForTranslation
	|FROM
	|	(SELECT
	|		CurrencyExchangeRateDates.Date AS Date,
	|		ExchangeRates.Currency AS Currency,
	|		MAX(ExchangeRates.Period) AS Period
	|	FROM
	|		CurrencyExchangeRateDates AS CurrencyExchangeRateDates
	|			INNER JOIN InformationRegister.RelativeExchangeRates AS ExchangeRates
	|			ON CurrencyExchangeRateDates.Currency = ExchangeRates.Currency
	|				AND CurrencyExchangeRateDates.Date >= ExchangeRates.Period
	|				AND ExchangeRates.BaseCurrency = &ComplAccountingCurrency
	|	
	|	GROUP BY
	|		CurrencyExchangeRateDates.Date,
	|		ExchangeRates.Currency) AS NestedQuery
	|	INNER JOIN InformationRegister.RelativeExchangeRates AS ExchangeRates
	|	ON NestedQuery.Currency = ExchangeRates.Currency
	|		AND NestedQuery.Period = ExchangeRates.Period
	|		AND ExchangeRates.BaseCurrency = &ComplAccountingCurrency
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	DatesOfExchangeRatesOfReceipts.Date                                        AS Date,
	|	DatesOfExchangeRatesOfReceipts.Currency                                      AS Currency,
	|	AcquisitionExchangeRates.CourseNumerator * OrderExchangeRates.CourseDenominator /
	|		(OrderExchangeRates.CourseNumerator * AcquisitionExchangeRates.CourseDenominator)         AS ConversionFactor_
	|INTO ExchangeRates
	|FROM
	|	DatesOfExchangeRatesOfReceipts AS DatesOfExchangeRatesOfReceipts
	|	LEFT JOIN ExchangeRatesForTranslation AS AcquisitionExchangeRates
	|	ON 
	|		DatesOfExchangeRatesOfReceipts.Date = AcquisitionExchangeRates.Date
	|		AND DatesOfExchangeRatesOfReceipts.Currency = AcquisitionExchangeRates.Currency
	|		
	|	LEFT JOIN ExchangeRatesForTranslation AS OrderExchangeRates
	|	ON DatesOfExchangeRatesOfReceipts.Date = OrderExchangeRates.Date
	|	AND OrderExchangeRates.Currency = &DocumentCurrency
	|
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	GoodsFromOrder.RowCode                                                 AS RowCode,
	|	GoodsFromOrder.ConversionFactorOfPackaging                              AS ConversionFactorOfOrderPackaging,
	|	SUM(GoodsReceipts.Count)                                    AS NumberOfReceipts_1,
	|	SUM(CAST(CASE
	|		WHEN &DocumentCurrency <> GoodsReceipts.Currency THEN
	|			CASE
	|				WHEN &DocumentCurrency = GoodsReceipts.ARAPCurrency THEN
	|					CASE
	|						WHEN GoodsReceipts.Currency = &ComplAccountingCurrency THEN
	|							GoodsReceipts.Price / GoodsReceipts.CourseNumerator * GoodsReceipts.CourseDenominator
	|						ELSE GoodsReceipts.Price * GoodsReceipts.CourseNumerator / GoodsReceipts.CourseDenominator
	|					END
	|				ELSE GoodsReceipts.Price * ISNULL(ExchangeRates.ConversionFactor_, 1)
	|			END
	|		ELSE GoodsReceipts.Price
	|	END * GoodsReceipts.Count / GoodsReceipts.ConversionFactorOfPackaging AS NUMBER(31, 2))) AS SumOfReceiptPrices,
	|	SUM(CAST(CASE
	|		WHEN &DocumentCurrency <> GoodsReceipts.Currency THEN
	|			CASE
	|				WHEN &DocumentCurrency = GoodsReceipts.ARAPCurrency THEN
	|					CASE
	|						WHEN GoodsReceipts.Currency = &ComplAccountingCurrency THEN
	|							GoodsReceipts.ManualDiscount / GoodsReceipts.CourseNumerator * GoodsReceipts.CourseDenominator
	|						ELSE GoodsReceipts.ManualDiscount * GoodsReceipts.CourseNumerator / GoodsReceipts.CourseDenominator
	|					END
	|				ELSE GoodsReceipts.ManualDiscount * ISNULL(ExchangeRates.ConversionFactor_, 1)
	|			END
	|		ELSE GoodsReceipts.ManualDiscount
	|	END AS NUMBER(31, 2)))                                               AS ManualDiscountAmountGoodsReceipt,
	|	SUM(CAST(CASE
	|		WHEN &DocumentCurrency <> GoodsReceipts.Currency THEN
	|			CASE
	|				WHEN &DocumentCurrency = GoodsReceipts.ARAPCurrency THEN
	|					CASE
	|						WHEN GoodsReceipts.Currency = &ComplAccountingCurrency THEN
	|							GoodsReceipts.Sum / GoodsReceipts.CourseNumerator * GoodsReceipts.CourseDenominator
	|						ELSE GoodsReceipts.Sum * GoodsReceipts.CourseNumerator / GoodsReceipts.CourseDenominator
	|					END
	|				ELSE GoodsReceipts.Sum * ISNULL(ExchangeRates.ConversionFactor_, 1)
	|			END
	|		ELSE GoodsReceipts.Sum
	|	END AS NUMBER(31, 2)))                         AS OrderReceiptAmount
	|INTO PricesByRevenue
	|FROM
	|	GoodsFromOrder AS GoodsFromOrder
	|		LEFT JOIN GoodsReceipts AS GoodsReceipts
	|		ON GoodsFromOrder.RowCode = GoodsReceipts.RowCode
	|		LEFT JOIN ExchangeRates AS ExchangeRates
	|		ON GoodsReceipts.Currency = ExchangeRates.Currency
	|			AND GoodsReceipts.Date = ExchangeRates.Date
	|GROUP BY
	|	GoodsFromOrder.RowCode,
	|	GoodsFromOrder.ConversionFactorOfPackaging
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	PricesByRevenue.RowCode AS RowCode,
	|	AVG(PricesByRevenue.SumOfReceiptPrices / PricesByRevenue.NumberOfReceipts_1 * PricesByRevenue.ConversionFactorOfOrderPackaging) AS ReceiptPrice,
	|	SUM(PricesByRevenue.ManualDiscountAmountGoodsReceipt) AS ManualDiscountAmountGoodsReceipt,
	|	SUM(PricesByRevenue.OrderReceiptAmount)             AS OrderReceiptAmount
	|INTO AveragePricesForReceipts
	|FROM PricesByRevenue AS PricesByRevenue
	|GROUP BY
	|	PricesByRevenue.RowCode
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	GoodsFromOrder.RowCode                                                 AS RowCode,
	|	AveragePricesForReceipts.ReceiptPrice                              AS ReceiptPrice,
	|	AveragePricesForReceipts.ManualDiscountAmountGoodsReceipt                 AS ManualDiscountAmountGoodsReceipt,
	|	AveragePricesForReceipts.OrderReceiptAmount                             AS OrderReceiptAmount
	|FROM
	|	GoodsFromOrder AS GoodsFromOrder
	|		INNER JOIN AveragePricesForReceipts AS AveragePricesForReceipts
	|		ON GoodsFromOrder.RowCode = AveragePricesForReceipts.RowCode
	|			AND (GoodsFromOrder.Price <> AveragePricesForReceipts.ReceiptPrice
	|				OR GoodsFromOrder.ManualDiscount <> AveragePricesForReceipts.ManualDiscountAmountGoodsReceipt)");
	
	Query.SetParameter("GoodsFromOrder", Object.Goods.Unload(, "RowCode,Price,Products,Package,Count,ManualDiscount"));
	Query.SetParameter("PurchaseOrder", Object.Ref);
	Query.SetParameter("DocumentCurrency", Object.Currency);
	Query.SetParameter("ComplAccountingCurrency", SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Object.Organization));
	
	Query.Text = StrReplace(Query.Text,
		"&QueryTextPackagingFactor1",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
		"GoodsFromOrder.Package",
		"GoodsFromOrder.Products"));
		
	Query.Text = StrReplace(Query.Text,
		"&QueryTextPackagingFactor2",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
		"GoodsReceipts.Package",
		"GoodsReceipts.Products"));

	
	SetPrivilegedMode(True);
	QueryResult = Query.Execute();
	Selection = QueryResult.Select();

	RowsToProcess = New Array;
	ProcessedRowsWithoutRecalculatingAmount = New Array;

	While Selection.Next() Do
		
		FoundRows = Object.Goods.FindRows(New Structure("RowCode", Selection.RowCode));
		
		If FoundRows.Count() > 0 Then
			
			FoundRows[0].Price = Selection.ReceiptPrice;
			If Selection.ManualDiscountAmountGoodsReceipt <> FoundRows[0].ManualDiscount Then
				ProcessedRowsWithoutRecalculatingAmount.Add(FoundRows[0]);
				FoundRows[0].PercentRateOfManualDiscount = -(Selection.OrderReceiptAmount * 100
					/ (FoundRows[0].NumberOfPackages*FoundRows[0].Price)-100);
				FoundRows[0].ManualDiscount = Selection.ManualDiscountAmountGoodsReceipt;
				FoundRows[0].Sum = Selection.OrderReceiptAmount;
			Else
				RowsToProcess.Add(FoundRows[0]);
			EndIf;
			PricesAdjusted = True;
			
		EndIf;
		
	EndDo;

	CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();

	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);

	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);

	BatchProcessingOfTablePartServer.ProcessTSStrings(
		ProcessedRowsWithoutRecalculatingAmount,
		StructureOfActions,
		Object.Goods,
		CachedValues);

	StructureOfActions.Insert("RecalculateAmountOfManualDiscount");
	StructureOfActions.Insert("RecalculateAmount");

	BatchProcessingOfTablePartServer.ProcessTSStrings(
		RowsToProcess,
		StructureOfActions,
		Object.Goods,
		CachedValues);

	TMCommonUse.FillInDuplicateDependentPropsInCollection(Object.Goods, DependentDetails());
	CalculateOrderTotals(ThisForm);

	Return PricesAdjusted;

EndFunction

#EndRegion

#Region SelectionAndProcessingOfQuantityVerification

&AtClient
Procedure ReportErrorsWhenOpeningSelection(Cancel)
	
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
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
	StructureOfActions.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));

	ParametersForFillingInVATRate = BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRate(Object, True);
	ParametersForFillingInVATRate.SpecifiedVATRate = SpecifiedVATRate;
	If Object.OneDateReceipt And ValueIsFilled(Object.DateOfShipment) Then
		ParametersForFillingInVATRate.Date = Object.DateOfShipment;
	EndIf;
	StructureOfActions.Insert("FillInVATRate", ParametersForFillingInVATRate);
	StructureOfActions.Insert("FillInVATRateForReturnableContainers", Object.ToReturnReusablePackage);
	StructureOfActions.Insert("FillInNoReturnContainerAttribute", Object.ToReturnReusablePackage);
	StructureOfActions.Insert("FillInCanceledWithoutReturnableContainerAttribute", Object.ToReturnReusablePackage);
	StructureOfActions.Insert("WhenChangingProductType",
	New Structure("ThereAreWorks, ThereIsWriteOffForExpenses", True, True));
	
	LinesOfBusinessClientServer.StructureOfInsertActionsWhenAddingRow(ThisObject, StructureOfActions);
	StructureOfActions.Insert("FillInCheckQualityDateOfQualityConfirmation", CacheQualityControl);
	AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions, ThisObject);
	
	RowsToProcess = New Array();
	
	For Each RowOfProduct In TableOfGoods Do
		
		CurrentRow = Object.Goods.Add();
		FillPropertyValues(CurrentRow, RowOfProduct, 
			"PartnerProducts, Products, Characteristic, Package, Warehouse, 
			|VendorPriceKind, Price, NumberOfPackages, Count, Sum, ManualDiscount, PercentRateOfManualDiscount");
		
		If Object.OneDateReceipt Then
			CurrentRow.DateOfReceipt = Object.DateOfReceipt;
		EndIf;
		
		RowsToProcess.Add(CurrentRow);
		
	EndDo;
	
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		RowsToProcess,
		StructureOfActions,
		Object.Goods);
		
	For Each CurrentRow In RowsToProcess Do
		IncomeAndExpensesClientServer.WhenAddingRowToTable(ThisObject, CurrentRow, "Object.Goods");
	EndDo;
	
	If ControlProductRange Then
		ProductRangeServer.CheckAssortmentOfTableOfSelectedProducts(Object, "Warehouse", TableOfGoods);
	EndIf;
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInFeatureAttribute", New Structure("Products", "ItemVariantsAreUsed"));
	AccountingForTraceableGoodsClientServerLocalization.CompleteDescriptionOfSettingsForFillingInServiceDetailsOfTablePart(StructureOfActions);
	
	ProductsServer.FillInServiceDetailsForProductInCollection(Object.Goods, StructureOfActions);
	
	FillInAttributeForDebitingExpensesForServices();
	CalculateOrderTotals(ThisForm);
	WhenChangingWarehouseInTablePartServer();
	FillInServiceDetailsForPurposeOfVTCH();
	ReusablePackageServer.UpdateFillingStateOfMultiTurnContainer(Object.ReusablePackageFillingStatus);

EndProcedure

#EndRegion

#Region BarcodesAndTradeEquipment

&AtServer
Procedure ProcessBarcodesServer(StructureOfActionParameters, CachedValues)
	
	BarcodingOfItemsServer.ProcessBarcodes(ThisObject, Object, StructureOfActionParameters, CachedValues);
	
EndProcedure

&AtClient
Procedure ProcessBarcodes(BarcodeData_5)
	
	ClearMessages();
	
	If Not BarcodingOfItemsClient.BarcodesAreValid(BarcodeData_5) Then
		Return;
	EndIf;
	
	StructureOfActionsWithAddedStrings = New Structure;
	StructureOfActionsWithAddedStrings.Insert("FillInProductNameOfProductPartner", Object.Partner);
	If UseTermsOfPurchases And ValueIsFilled(Object.Terms) Then
		StructureOfActionsWithAddedStrings.Insert("FillInTermsOfPurchase", BatchProcessingOfTablePartClientServer.GetStructureForFillingInPurchasePriceInTSLine(Object));
	Else
		StructureOfActionsWithAddedStrings.Insert("FillInPurchasePrice", BatchProcessingOfTablePartClientServer.GetStructureForFillingInPurchasePriceInTSLine(Object));
	EndIf;
	StructureOfActionsWithAddedStrings.Insert("CheckFillWarehouse", BatchProcessingOfTablePartClientServer.GetWarehouseFillStructureInTSLine(Object, WarehouseGroup_,,,"ToExpenseAs"));
	ParametersForFillingInVATRate = BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRate(Object, True);
	ParametersForFillingInVATRate.SpecifiedVATRate = SpecifiedVATRate;
	If Object.OneDateReceipt And ValueIsFilled(Object.DateOfShipment) Then
		ParametersForFillingInVATRate.Date = Object.DateOfShipment;
	EndIf;
	StructureOfActionsWithAddedStrings.Insert("FillInVATRate", ParametersForFillingInVATRate);
	StructureOfActionsWithAddedStrings.Insert("FillInVATRateForReturnableContainers", Object.ToReturnReusablePackage);
	StructureOfActionsWithAddedStrings.Insert("FillInFeatureAttribute", New Structure("Products", "ItemVariantsAreUsed"));
	StructureOfActionsWithAddedStrings.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
	StructureOfActionsWithAddedStrings.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));
	StructureOfActionsWithAddedStrings.Insert("FillInNoReturnContainerAttribute", Object.ToReturnReusablePackage);
	StructureOfActionsWithAddedStrings.Insert("FillInCanceledWithoutReturnableContainerAttribute", Object.ToReturnReusablePackage);
	StructureOfActionsWithAddedStrings.Insert("WhenChangingProductType",
		New Structure("ThereAreWorks, ThereIsWriteOffForExpenses", True, True));
	StructureOfActionsWithAddedStrings.Insert("FillInWriteOFFAttributeForExpensesAndDivision");
	LinesOfBusinessClientServer.StructureOfInsertActionsWhenAddingRow(ThisObject, StructureOfActionsWithAddedStrings);
	StructureOfActionsWithAddedStrings.Insert("FillInCheckQualityDateOfQualityConfirmation", CacheQualityControl);
	IncomeAndExpensesClientServer.InsertActionClearItemAndExpenseAnalytics(StructureOfActionsWithAddedStrings, ThisObject);
	
	AddActionsToStructureWhenChangingPackagesNumber(StructureOfActionsWithAddedStrings, ThisObject);
	
	StructureOfActionsWithModifiedStrings = New Structure;
	AddActionsToStructureWhenChangingPackagesNumber(StructureOfActionsWithModifiedStrings, ThisObject);
	
	StructureOfActions = BarcodingOfItemsClient.BarcodeProcessingParameters();
	StructureOfActions.Barcodes                              = BarcodeData_5;
	StructureOfActions.StructureOfActionsWithAddedStrings = StructureOfActionsWithAddedStrings;
	StructureOfActions.StructureOfActionsWithModifiedStrings  = StructureOfActionsWithModifiedStrings;
	
	If ControlProductRange Then
		AssortmentInspectionStructure = ProductRangeClientServer.AssortmentVerificationParameters();
		AssortmentInspectionStructure.Ref = Object.Ref;
		AssortmentInspectionStructure.Warehouse = Object.Warehouse;
		AssortmentInspectionStructure.Date = ?(ValueIsFilled(Object.RequestedDeliveryDate), Object.RequestedDeliveryDate, Object.Date);
		AssortmentInspectionStructure.MessageText = NStr("vi = 'Hàng hóa %1 không thuộc phân loại của cửa hàng. Không nên đặt mặt hàng này.';
														|ru = 'Товар %1 не включен в ассортимент магазина. Заказывать его не рекомендуется.';
														|en = 'Item ""%1"" is not in this selling point''s product range. Please reconsider adding it to the order.'; fa = 'Item ""%1"" is not in this selling point''s product range. Please reconsider adding it to the order.';
														|it = 'Il prodotto %1 non è incluso nell''assortimento del negozio. Ordinarlo non è consigliabile.';
														|pl = 'Towar %1 nie jest włączony do asortymentu sklepu. Nie zaleca się zamawiać go.';
														|tr = 'Ürün%1 mağazanın ürün yelpazesine dahil değildir. Sipariş edilmesi tavsiye edilmez.'");
		AssortmentInspectionStructure.NameOfAssortmentResource = "PurchasesAreAllowed";
		AssortmentInspectionStructure.CheckedYouCanAdd = True;
		AssortmentInspectionStructure.AllowAdding = True;
		//
		StructureOfActions.AssortmentVerificationParameters = AssortmentInspectionStructure;
	EndIf;
	
	SetParametersForStructureOfActionsWhenSearchingByBarcode(StructureOfActions, Object.BusinessOperation);
	
	ProcessBarcodesServer(StructureOfActions, CachedValues);
	
	BarcodingOfItemsClient.ProcessUnknownBarcodes(StructureOfActions, CachedValues, ThisObject);
	
	CalculateOrderTotals(ThisObject);
	
	If StructureOfActions.CurrentRow <> Undefined Then
		Items.Goods.CurrentRow = StructureOfActions.CurrentRow;
		CurrentRow = Items.Goods.CurrentData;
		
		IncomeAndExpensesClientServer.WhenChangingArticleAvailabilityDetailsInLine(ThisObject, CurrentRow, "Object.Goods");
	EndIf;
	
	SetWhetherWarehouseIsFull();
	
EndProcedure

&AtServerNoContext
Procedure SetParametersForStructureOfActionsWhenSearchingByBarcode(StructureOfActions, BusinessOperation)
	
	If Not ProductsServer.ListOfBusinessOperationsExcludingServicesAndWorks().FindByValue(BusinessOperation) = Undefined Then
		StructureOfActions.GoodsOnly = True;
	ElsIf Not ProductsServer.ListOfBusinessOperationsExcludingWork().FindByValue(BusinessOperation) = Undefined Then
		StructureOfActions.OnlyGoodsAndServices = True;
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
	
	If Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.ConsignmentProcurement")
		Or Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.ReceivingForStorageWithRightOfSale") Then
		
		FilterParameters.Insert("Products.ItemsType", ProductsClientServer.SelectionByProductMultiTurnContainer(False));
		
	ElsIf Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.PurchaseFromVendorGoodsInTransit")
		Or Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.ImportFromEAEUGoodsInTransit")
		Or Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.ImportGoodsInTransit") Then
		
		FilterParameters.Insert("Products.ItemsType", ProductsClientServer.SelectionByProductReusablePackagingService(False));
		
	Else
		FilterParameters.Insert("Products.ItemsType", ProductsClientServer.SelectionByProductReusablePackagingServiceWork(False));
	EndIf;
	
	Columns = "Products,Characteristic,Package,NumberOfPackages,Price,DateOfReceipt,
		|PercentRateOfManualDiscount,ManualDiscount,Warehouse,Department";
	
	TableOfGoods = ProcessingOfTabularForms.RowsFromClipboard(FilterParameters, Columns);
	
	If Not ValueIsFilled(TableOfGoods) Then
		Return;
	EndIf;
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
	StructureOfActions.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));
	StructureOfActions.Insert("CheckFillWarehouse", BatchProcessingOfTablePartClientServer.GetWarehouseFillStructureInTSLine(Object, WarehouseGroup_,,,"ToExpenseAs"));
	ParametersForFillingInVATRate = BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRate(Object, True);
	ParametersForFillingInVATRate.SpecifiedVATRate = SpecifiedVATRate;
	StructureOfActions.Insert("FillInVATRate", ParametersForFillingInVATRate);
	StructureOfActions.Insert("FillInVATRateForReturnableContainers", Object.ToReturnReusablePackage);
	StructureOfActions.Insert("FillInNoReturnContainerAttribute", Object.ToReturnReusablePackage);
	StructureOfActions.Insert("FillInCanceledWithoutReturnableContainerAttribute", Object.ToReturnReusablePackage);
	StructureOfActions.Insert("WhenChangingProductType",
			New Structure("ThereAreWorks, ThereIsWriteOffForExpenses", True, True));
	StructureOfActions.Insert("FillInWriteOFFAttributeForExpensesAndDivision");
	AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions, ThisObject);
	StructureOfActions.Insert("FillInCheckQualityDateOfQualityConfirmation", CacheQualityControl);
	If TableOfGoods.Columns.Find("ManualDiscount") <> Undefined Then
		StructureOfActions.RecalculateAmountTakingIntoAccountManualDiscount.Insert("RecalculateAmountOfManualDiscount_", False);
	EndIf;
	LinesOfBusinessClientServer.StructureOfInsertActionsWhenAddingRow(ThisObject, StructureOfActions);
	
	RowsToProcess = New Array;
	
	For Each RowOfProduct In TableOfGoods Do
		
		CurrentRow = Object.Goods.Add();
		FillPropertyValues(CurrentRow, RowOfProduct);
		If Not UseDiscountAdjustmentsInPurchases Then
			CurrentRow.PercentRateOfManualDiscount = 0;
			CurrentRow.ManualDiscount = 0;
		EndIf;
		If Object.OneDateReceipt Then
			CurrentRow.DateOfReceipt = Object.DateOfReceipt;
			CurrentRow.DateOfShipment = Object.DateOfShipment;
		EndIf;
		
		RowsToProcess.Add(CurrentRow);
		
	EndDo;
	
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		RowsToProcess,
		StructureOfActions,
		Object.Goods);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInFeatureAttribute", New Structure("Products", "ItemVariantsAreUsed"));
	AccountingForTraceableGoodsClientServerLocalization.CompleteDescriptionOfSettingsForFillingInServiceDetailsOfTablePart(StructureOfActions);
	
	ProductsServer.FillInServiceDetailsForProductInCollection(Object.Goods, StructureOfActions);
	
	CalculateOrderTotals(ThisForm);
	WhenChangingWarehouseInTablePartServer();
	FillInServiceDetailsForPurposeOfVTCH();
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

&AtServer
Procedure OnReadCreateAtServer()
	
	FillOutOrder();
	
	UseLinesOfBusiness = GetFunctionalOption("UseCostAccountingByLinesOfBusiness");
	UseAccountingOfOtherIncomeExpenses = GetFunctionalOption("UseAccountingOfOtherIncomeExpenses");
	
	SetAvailabilityAgreements();
	
	Contract = Object.Contract;
	DocumentCurrency = Object.Currency;
	WarehouseGroup_ = Catalogs.Warehouses.ThisGroupAndWarehousesAreUsedByWTCProcurementDocuments(Object.Warehouse);
	Items.GoodsFillInTheWarehouseInSelectedLines.Enabled = WarehouseGroup_;
	SetParametersForSelectingProductsWarehouse();
	
	CounterpartyLegEntInd = Common.ObjectAttributeValue(Object.Counterparty, "LegalEntityIndividual");
	
	WhenChangingWarehouseInTablePartServer();
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInFeatureAttribute", New Structure("Products", "ItemVariantsAreUsed"));
	StructureOfActions.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
	StructureOfActions.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));
	AccountingForTraceableGoodsClientServerLocalization.CompleteDescriptionOfSettingsForFillingInServiceDetailsOfTablePart(StructureOfActions);
	ProductsServer.FillInServiceDetailsForProductInCollection(Object.Goods, StructureOfActions);
	
	UpdateDuplicateDependentDetails();
	CalculateOrderTotals(ThisForm);
	
	SetVisibilityOfElementsByOperationServer();
	AdjustItemSelectionSettings();
	RefreshStatusServer();
	UpdateTextDocumentsBasedOn();
	SetAvailabilityOfItemsByStatusServer();
	SetVisibilityOfReceiptDateFormElements();
	UpdateAvailabilityOfReturnContainerItems(ThisForm);
	FillInSelectionListDesiredReceiptDate();
	FillInServiceDetailsForPurposeOfVTCH();
	UpdateVHFWarehouseObligation();
	
	ControlProductRange = ProductRangeServerCached.ControlProductRange(Object.Warehouse, Object.Date);
	
	BackgroundTaskData = GoodsDelivery.WhenReadingCreatingOrdersOnServer(Items, Object,,,SummaryDeliveryInformation,True);
	
	If GoodsDeliveryClientServer.UsedDelivery20() Then
		Items.DeliveryAddressForVendor2.Visible = False;
	EndIf;
	
	FillInListOfDeliveryAddressesForSupplier();
	
	ResponsiblePersonsServer.FillInManagerSelectionList_(Items.Manager, Object);
	
	ProcessingOfTabularForms.InitializeRowCache(Items.Goods);
	
	LinesOfBusinessServer.OnReadCreateAtServer(ThisObject);
	
	FillParameters = Documents.PurchaseOrder.ParametersForFillingInVATTaxationPurchases(Object);
	VATAccountingERP.FillInListOfVATTaxChoices(Items.VATTaxation, Object.VATTaxation, FillParameters, VATAccountingCachedParameterValues);
	
	FillParameters = Documents.PurchaseOrder.ParametersForFillingInVATActivityType(Object);
	VATAccountingERP.FillInActivitySelectionList(Items.PurchaseForActivity, Object.PurchaseForActivity, FillParameters, VATAccountingCachedParameterValues);
	
	CashServerLocalization.ConfigureElementsOfOperationsWithSelfEmployed(ThisObject, False);
	CacheQualityControl = QualityControl.DataCacheOfMechanism(Object);
	
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

&AtClientAtServerNoContext
Procedure CalculateOrderTotals(Form)
	
	// Filling in the totals according to the "Products" table
	
	CollectionProducts = Form.Object.Goods;
	Form.SumCanceled     = ?(Form.Object.PackageDepositIsRequired,
		CollectionProducts.Total("AmountIncludingVATCanceled"),
		CollectionProducts.Total("AmountIncludingVATCanceledWithoutReusablePackages"));
	Form.AmountOrderedWithADepositContainer = ?(Form.Object.PackageDepositIsRequired,
		CollectionProducts.Total("AmountIncludingVAT") - CollectionProducts.Total("AmountIncludingVATCanceled"),
		CollectionProducts.Total("AmountIncludingVATWithoutReusablePackages") - CollectionProducts.Total("AmountIncludingVATCanceledWithoutReusablePackages"));
	Form.AmountOrdered = CollectionProducts.Total("AmountIncludingVATWithoutReusablePackages") - CollectionProducts.Total("AmountIncludingVATCanceledWithoutReusablePackages");
	Form.PackageDepositValue = ?(Form.Object.PackageDepositIsRequired,(CollectionProducts.Total("AmountIncludingVAT") - CollectionProducts.Total("AmountIncludingVATCanceled"))
			- (CollectionProducts.Total("AmountIncludingVATWithoutReusablePackages") - CollectionProducts.Total("AmountIncludingVATCanceledWithoutReusablePackages")),0);
	Form.AmountNDSOrdered = ?(Form.Object.PackageDepositIsRequired,
		CollectionProducts.Total("VATAmount") - CollectionProducts.Total("VATAmountCanceled"),
		CollectionProducts.Total("VATAmountWithoutReusablePackages") - CollectionProducts.Total("VATAmountCanceledWithoutReusablePackages"));
	Form.ManualDiscount = ?(Form.Object.PackageDepositIsRequired,
		CollectionProducts.Total("ManualDiscount") - CollectionProducts.Total("ManualDiscountCanceled"),
		CollectionProducts.Total("ManualDiscountWithoutReusablePackages") - CollectionProducts.Total("ManualDiscountCanceledWithoutReusablePackages"));
	
	If CollectionProducts.Total("AmountIncludingVATCanceled") = CollectionProducts.Total("AmountIncludingVAT") Then
		Form.AllLinesAreCanceled = True;
	Else
		Form.AllLinesAreCanceled = False;
	EndIf;
	
	AmountOrdered = ?(Form.Object.PackageDepositIsRequired,
		CollectionProducts.Total("Sum") - CollectionProducts.Total("SumCanceled"),
		CollectionProducts.Total("SumWithoutReusablePackages") - CollectionProducts.Total("SumCanceledWithoutReusablePackages"));
		
	// Filling in the totals according to the payment stages table
	
	Form.AmountAdvanceBeforeConfirmation     = 0;
	Form.PrepaymentAmountBeforeReceipt   = 0;
	Form.LoanAmountAfterReceipt   = 0;
	
	MatchingPaymentOptions = New Map;
	MatchingPaymentOptions.Insert(PredefinedValue("Enum.OptionsForControllingPaymentToSupplier.PrepaymentBeforeConfirmation"),
		New Structure("Sum", "AmountAdvanceBeforeConfirmation"));
	MatchingPaymentOptions.Insert(PredefinedValue("Enum.OptionsForControllingPaymentToSupplier.PrepaymentBeforeReceipt"),
		New Structure("Sum", "PrepaymentAmountBeforeReceipt"));
	MatchingPaymentOptions.Insert(PredefinedValue("Enum.OptionsForControllingPaymentToSupplier.CreditAfterShipment"),
		New Structure("Sum", "LoanAmountAfterReceipt"));
	
	For Each CurRow In Form.Object.PaymentScheduleSteps Do
		ItemsNames = MatchingPaymentOptions[CurRow.PaymentOption];
		If ItemsNames <> Undefined Then
			Form[ItemsNames.Sum] = Form[ItemsNames.Sum] + CurRow.PaymentAmount
				+ ?(Form.Object.PackageDepositIsRequired, CurRow.PackageDepositValue, 0);
		EndIf;
	EndDo;
	
	// Selecting the VAT display page
	
	PurchaseIsSubjectToVAT = VATAccountingERPClientServer.DisplayNDSInResultsOfProcurementDocument(Form.Object.VATTaxation);
	
	If PurchaseIsSubjectToVAT Then
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
		"Sum,VATAmount,AmountIncludingVAT,ManualDiscount",
		"Sum,VATAmount,AmountIncludingVAT,ManualDiscount",
		"Sum,VATAmount,AmountIncludingVAT,ManualDiscount");
	
EndFunction

&AtClientAtServerNoContext
Procedure AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions, Form)
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Form.Object);
	StructureOfActions.Insert("RecalculateNumberOfUnits");
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmount");
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountManualDiscount", New Structure("Clear", False));
	StructureOfActions.Insert("FillInDuplicateDependentDetails", DependentDetails());
	
EndProcedure

&AtServer
Procedure FillInDefaultContract()
	
	EconomicOperationOfSelection = PurchasesServer.BusinessOperationsOnMain(Object.BusinessOperation);
	
	FillContract = True;
	
	If ValueIsFilled(Object.Terms) Then
		FillContract =
			GetFunctionalOption("UseContractsWithVendors")
			And Common.ObjectAttributeValue(Object.Terms, "ContractsAreUsed");
	EndIf;
	
	If FillContract Then
		If Object.ARAPObjectSettings = Enums.ARAPObjectSettings.ByCounterpartyContracts 
			And UseLinesOfBusiness Then
			
			AddlParameters = PurchasesServer.AdditionalContractSelectionParameters();
			AddlParameters.ARAPCurrency = Object.Currency;
			AddlParameters.LineOfBusiness = Object.LineOfBusiness;
			AddlParameters.ContractWithSelfEmployedPerson = Object.OperationWithSelfEmployedPerson;
			DefaultContract = PurchasesServer.GetDefaultContract(Object,
																			EconomicOperationOfSelection,
																			AddlParameters);
		Else
			
			AddlParameters = PurchasesServer.AdditionalContractSelectionParameters();
			AddlParameters.ARAPCurrency = Object.Currency;
			AddlParameters.ContractWithSelfEmployedPerson = Object.OperationWithSelfEmployedPerson;
			DefaultContract = PurchasesServer.GetDefaultContract(Object,
																			EconomicOperationOfSelection,
																			AddlParameters);
		EndIf;
	Else
		DefaultContract = Catalogs.CounterpartyContracts.EmptyRef();
	EndIf;
	
	If Contract <> DefaultContract
		Or Not ValueIsFilled(Object.Contract) Then
		
		Contract = DefaultContract;
		Object.Contract = DefaultContract;
		OptionOfExecutionOfContractOfPurchases = PurchasesServer.GetVariantOfProcurementContract(Object.Contract);
		OptionOfProcessingDocumentsForServices = PurchasesServer.GetVariantOfRegistrationOfDocumentsForAdmissionToServices(Object.Contract);
		
		If ValueIsFilled(Object.Contract) Then
			
			FillInTypeOfActivityVAT();
			FillInVATTaxationPurchases();
			VATTaxationOnChangeServer(Undefined);
			
		EndIf;
		
		ForeignCurrencyTransaction = Object.ForeignCurrencyTransaction;
		ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisObject, "Contract");
		If ForeignCurrencyTransaction <> Object.ForeignCurrencyTransaction Then
			Object.BankAccount = Catalogs.CompaniesBankAccounts.EmptyRef();
		EndIf;
		PurchasesServerCall.FillInBankAccountsUnderAgreement(Object.Contract, Object.BankAccount);
		FillInFinancialAccountingGroup();
		
		Object.GoodsReceiptOption = PurchasesServer.GetProductAcceptanceOption(Undefined, Object.Contract);
		Object.ServiceReceiptOption = PurchasesServer.GetServiceAcceptanceOption(Object.Contract);
	EndIf;
	
	If QualityControl.UpdateActionParameters(
			Documents.PurchaseOrder,
			Object,
			CacheQualityControl) Then
			
		StructureOfActions = New Structure();
		StructureOfActions.Insert("FillInCheckQualityDateOfQualityConfirmation", CacheQualityControl);
		BatchProcessingOfTablePartServer.TreatTS(Object.Goods, StructureOfActions);
		
	EndIf;

	GoodsDelivery.WhenReadingCreatingOrdersOnServer(Items, Object,,,SummaryDeliveryInformation);
	
EndProcedure

&AtServer
Function FillWarehouseInSelectedLinesOnServer(Val ArrayOfSelectedRows, Warehouse)
	
	FilledWithRows = WarehousesServer.FillInWarehousesInSelectedLines(Object.Goods, ArrayOfSelectedRows, Warehouse,, "ToExpenseAs");
	
	If FilledWithRows > 0 Then
		RowsToProcess = New Array();
		For Each Id In ArrayOfSelectedRows Do
			RowsToProcess.Add(Object.Goods.FindByID(Id));
		EndDo;
		StructureOfActions = New Structure();
		StructureOfActions.Insert("FillInCheckQualityDateOfQualityConfirmation", CacheQualityControl);
		BatchProcessingOfTablePartServer.ProcessTSStrings(RowsToProcess, StructureOfActions, Object.Goods);
		WhenChangingWarehouseInTablePartServer();
	EndIf;
	
	Return FilledWithRows
	
EndFunction

&AtServer
Procedure SetAvailabilityOfItemsByStatusServer()
	
	ItemArray = New Array;
	
	// Header Controls
	ItemArray.Add("Date");
	ItemArray.Add("Partner");
	ItemArray.Add("Terms");
	ItemArray.Add("Contract");
	ItemArray.Add("Currency");
	ItemArray.Add("PriceIncludesVAT");
	ItemArray.Add("VATTaxation");
	ItemArray.Add("Organization");
	ItemArray.Add("Counterparty");
	ItemArray.Add("Warehouse");
	ItemArray.Add("RequestedDeliveryDate");
	ItemArray.Add("ApprovalDate");
	ItemArray.Add("BusinessOperation");
	ItemArray.Add("OneDateReceipt");
	ItemArray.Add("DateOfReceipt");
	ItemArray.Add("ToReturnReusablePackage");
	ItemArray.Add("ReusablePackageReturnCycleLength");
	ItemArray.Add("PackageDepositIsRequired");
	ItemArray.Add("Department");
	
	ItemArray.Add("Goods;BeforeAddRow,BeforeDeleteRow");
	
	// Product-related controls
	ItemArray.Add("GoodsProducts");
	ItemArray.Add("GoodsCharacteristic");
	ItemArray.Add("GoodsNumberOfPackages");
	ItemArray.Add("GoodsPackage");
	ItemArray.Add("GoodsVendorPriceKind");
	ItemArray.Add("GoodsPrice");
	ItemArray.Add("GoodsVATRate");
	ItemArray.Add("GoodsVATAmount");
	ItemArray.Add("GoodsPercentRateOfManualDiscount");
	ItemArray.Add("GoodsManualDiscount");
	ItemArray.Add("GoodsSum");
	
	// Product-related controls
	ItemArray.Add("ProductsContextMenuAdd");
	ItemArray.Add("ProductItemsContextMenuCopy");
	ItemArray.Add("GoodsContextMenuDelete");
	
	ItemArray.Add("GoodsAdd");
	ItemArray.Add("GoodsChange");
	ItemArray.Add("GoodsCopy");
	ItemArray.Add("GoodsDelete");
	
	ItemArray.Add("GoodsInsertRows");
	ItemArray.Add("GoodsSplitRow");
	
	ItemArray.Add("ProductsPickUpTheNomenclature");
	ItemArray.Add("GoodsAddReusablePackage");
	ItemArray.Add("GoodsImportFromExternalFile");
	
	ItemArray.Add("GoodsSearchByBarcode");
	ItemArray.Add("GoodsImportDataFromPDT");
	ItemArray.Add("GoodsFillInTheWarehouseInSelectedLines");
	ItemArray.Add("GoodsFillInTheItemByThePartnerSItem");
	ItemArray.Add("GoodsFillInTheDepartment");
	ItemArray.Add("GoodsFillInVATRate");
	ItemArray.Add("GoodsSelectSubstitutes");
	
	ItemArray.Add("GoodsFillThePricesByTermsOfSales");
	ItemArray.Add("GoodsFillInThePricesOfTheSelectedLinesByTheTypeOfSupplierSPrice");
	ItemArray.Add("GoodsAdjustPricesForGoodsReceipts");
	
	ItemArray.Add("GoodsCancelManualDiscounts");
	ItemArray.Add("GoodsAssignAManualDiscountToSelectedRows");
	
	ItemArray.Add("FillInPaymentScheduleSteps");
	ItemArray.Add("FillInTheScheduleStepsByPreviousOrders");
	
	TMCommonUse.SetSubscriptionForFormElementChangeEvents(ThisObject, ItemArray);
	
	If Object.Status = Enums.PurchaseOrderStatuses.Closed Then
		TMCommonUseClientServer.SetFormItemProperty(Items, "CalculateDocumentStatus", "Enabled", False);
	Else
		TMCommonUseClientServer.SetFormItemProperty(Items, "CalculateDocumentStatus", "Enabled", True);
	EndIf;
	
EndProcedure

&AtServer
Procedure SetVisibilityOfElementsByOperationServer()
	
	Var ArrayOfAllProps;
	Var ArrayOfOperationDetails;
	
	SetAvailabilityVisibilityOfContract();
	
	Documents.PurchaseOrder.FillInNamesOfBusinessTransactionDetails(Object.BusinessOperation,
																				ArrayOfAllProps,
																				ArrayOfOperationDetails);
	
	CashServer.SetVisibilityOfElementsByArray(Items,
																ArrayOfAllProps,
																ArrayOfOperationDetails);
	
	VisibilityOfElements = (Object.BusinessOperation <> Enums.BusinessTransactions.ConsignmentProcurement)
							And (Object.BusinessOperation <> Enums.BusinessTransactions.ReceivingForStorageWithRightOfSale);
	
	ItemArray = New Array;
	ItemArray.Add("PaymentHeader");
	ItemArray.Add("DiscountAmount");
	ItemArray.Add("GoodsCancelManualDiscounts");
	ItemArray.Add("GoodsAssignAManualDiscountToSelectedRows");
	
	TMCommonUseClientServer.SetPropertyOfFormElements(Items,
																	ItemArray,
																	"Visible",
																	VisibilityOfElements);
	
	ProductsServer.SetProductSelectionParameters(Object.BusinessOperation, Items.GoodsProducts);
	ProductsServer.SetProductSelectionParameters(Object.BusinessOperation,
															Items.GoodsPartnerProducts);
	
	VisibilityOnAcceptanceForStorage = Object.BusinessOperation <> Enums.BusinessTransactions.ReceivingForStorageWithRightOfSale;
	
	ItemArray = New Array;
	ItemArray.Add("PriceIncludesVAT");
	
	TMCommonUseClientServer.SetPropertyOfFormElements(Items,
																	ItemArray,
																	"Visible",
																	VisibilityOnAcceptanceForStorage);
	
EndProcedure

&AtServer
Procedure SetAvailabilityVisibilityOfContract()
	
	If Object.BusinessOperation = Enums.BusinessTransactions.ReceivingForStorageWithRightOfSale Then
		
		Items.Contract.Visible = True;
		Items.Contract.Enabled = ValueIsFilled(Object.Partner)
										And (ValueIsFilled(Object.Counterparty)
											Or GetFunctionalOption("UsePartnersAsCounterparties"))
										And ValueIsFilled(Object.Organization);
		
	Else
		PurchasesServer.SetContractAvailability(Object, Items.Contract.Enabled, Items.Contract.Visible);
	EndIf;
	
EndProcedure

&AtServer
Procedure FillOperationSelectionList()
	
	BusinessTransactions = Documents.PurchaseOrder.BusinessOperationsOfDocument(True);
	Items.BusinessOperation.ChoiceList.LoadValues(BusinessTransactions);

	PurchaseFromVendorCreatingInvoicesOnGoodsReceipt = Items.BusinessOperation.ChoiceList.FindByValue(
		Enums.BusinessTransactions.PurchaseFromVendorCreatingInvoicesOnGoodsReceipt);
	If PurchaseFromVendorCreatingInvoicesOnGoodsReceipt <> Undefined Then
		PurchaseFromVendorCreatingInvoicesOnGoodsReceipt.Presentation = NStr("vi = 'Mua hàng từ một nhà cung cấp (Giao hàng chưa có hóa đơn)';
																			|ru = 'Закупка у поставщика (неотфактурованная поставка)';
																			|en = 'Purchase from vendor (GRNI)'; fa = 'خرید از تأمین‌کننده (کالای دریافت‌شده بدون فاکتور)';
																			|it = 'Acquisto dal fornitore (consegna non fatturata)';
																			|pl = 'Zakup u dostawcy (niefakturowana dostawa)';
																			|tr = 'Tedarikçiden satın alma (teslim edilmemiş teslimat)'");
	EndIf;
	
	ImportFromEAEUInvoicedDelivery = Items.BusinessOperation.ChoiceList.FindByValue(
		Enums.BusinessTransactions.ImportFromEAEUInvoicedDelivery);
	If ImportFromEAEUInvoicedDelivery <> Undefined Then
		ImportFromEAEUInvoicedDelivery.Presentation = NStr("vi = 'Nhập khẩu từ liên minh kinh tế Á-Âu (cung cấp không có hóa đơn)';
															|ru = 'Ввоз из ЕАЭС (неотфактурованная поставка)';
															|en = 'Import from EAEU (GRNI)'; fa = 'واردات از EAEU (کالای دریافت‌شده بدون فاکتور)';
															|it = 'Importazione dall''UEE (consegna non fatturata)';
															|pl = 'Wwóz z EWG (niefakturowana dostawa)';
															|tr = 'AEB''DEN ithalat (teslim edilmemiş teslimat)'");
	EndIf;
	
	OnlyOperation = Items.BusinessOperation.ChoiceList.Count() = 1;
	TMCommonUseClientServer.SetFormItemProperty(
		Items,
		"BusinessOperation",
		"ReadOnly",
		OnlyOperation And ValueIsFilled(Object.BusinessOperation));
	
EndProcedure

&AtClientAtServerNoContext
Function EconomicOperationsOfSeparatePurchase(UseGoodsInTransit = True,
		UseUninvoicedDeliveries = True)
	
	EconomicOperationsOfSeparatePurchase = New Array;
	
	If UseGoodsInTransit Then
		EconomicOperationsOfSeparatePurchase.Add(
			PredefinedValue("Enum.BusinessTransactions.PurchaseFromVendorGoodsInTransit"));
		EconomicOperationsOfSeparatePurchase.Add(
			PredefinedValue("Enum.BusinessTransactions.ImportGoodsInTransit"));
		EconomicOperationsOfSeparatePurchase.Add(
			PredefinedValue("Enum.BusinessTransactions.ImportFromEAEUGoodsInTransit"));
	EndIf;
	
	If UseUninvoicedDeliveries Then
		EconomicOperationsOfSeparatePurchase.Add(
			PredefinedValue("Enum.BusinessTransactions.PurchaseFromVendorCreatingInvoicesOnGoodsReceipt"));
		EconomicOperationsOfSeparatePurchase.Add(
			PredefinedValue("Enum.BusinessTransactions.ImportFromEAEUInvoicedDelivery"));
	EndIf;
	
	Return EconomicOperationsOfSeparatePurchase;
	
EndFunction

&AtServer
Function CancelUndeliveredLinesServer(CancellationReason, Val CheckBalance = False)
	
	DocumentPurchases = FormAttributeToValue("Object");
	
	OrderLineAdjustmentStructure = OrdersServer.OrderLineAdjustmentStructure();
	OrderLineAdjustmentStructure.DocumentObject               = DocumentPurchases;
	OrderLineAdjustmentStructure.CancellationReason                = CancellationReason;
	OrderLineAdjustmentStructure.CheckBalance             = True;
	OrderLineAdjustmentStructure.CancelUnprocessedLines = True;

	ResultStructure1 = DocumentPurchases.AdjustOrderLines(OrderLineAdjustmentStructure);
	NumberOfCanceledLines = ResultStructure1.RowsCount;
	
	ValueToFormAttribute(DocumentPurchases, "Object");
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInFeatureAttribute", New Structure("Products", "ItemVariantsAreUsed"));
	StructureOfActions.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
	StructureOfActions.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));
	ProductsServer.FillInServiceDetailsForProductInCollection(Object.Goods, StructureOfActions);

	StructureOfActions = New Structure();
	StructureOfActions.Insert("FillInCheckQualityDateOfQualityConfirmation", CacheQualityControl);
	BatchProcessingOfTablePartServer.TreatTS(Object.Goods, StructureOfActions);

	UpdateDuplicateDependentDetails();
	WhenChangingWarehouseInTablePartServer();
	FillInServiceDetailsForPurposeOfVTCH();
	
	Return NumberOfCanceledLines;
	
EndFunction

&AtServer
Procedure UpdateAdditionalAttributesItems()
	
	PropertyManager.UpdateAdditionalAttributesItems(ThisForm);
	
EndProcedure

&AtServer
Procedure RefreshStatusServer()
	
	Documents.PurchaseOrder.CalculateStatus(
		Object.Ref,
		Object.Contract,
		ThisForm);
	Items.State.Hyperlink = AccessRight("View", Metadata.Reports.DocumentFulfillmentStatus);
EndProcedure

&AtServerNoContext
Procedure CalculateStateOfOrder(Ref, Contract, OrderState, Hyperlink)
	
	Documents.PurchaseOrder.CalculateStatus(Ref, Contract, OrderState, True);
	
	Hyperlink = AccessRight("View", Metadata.Reports.DocumentFulfillmentStatus);
	
EndProcedure


&AtServer
Function PlaceGoodsInTemporaryStorageServer()
	
	Return PurchasesServer.PlaceGoodsInTemporaryStorage(Object.Goods);
	
EndFunction

&AtServer
Procedure FillInItemsFromTemporaryStorageServer(AddressInTempStorage)
	
	TableOfGoods = GetFromTempStorage(AddressInTempStorage);// DocumentTabularSection.PurchaseOrder.Goods
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
	StructureOfActions.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));
	
	If UseTermsOfPurchases And ValueIsFilled(Object.Terms) Then
		StructureOfActions.Insert("FillInTermsOfPurchase",
			BatchProcessingOfTablePartClientServer.GetStructureForFillingInPurchasePriceInTSLine(Object));
	Else
		StructureOfActions.Insert("FillInPurchasePrice",
			BatchProcessingOfTablePartClientServer.GetStructureForFillingInPurchasePriceInTSLine(Object));
	EndIf;
	
	ParametersForFillingInVATRate = BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRate(Object, True);
	ParametersForFillingInVATRate.SpecifiedVATRate = SpecifiedVATRate;
	StructureOfActions.Insert("FillInVATRate", ParametersForFillingInVATRate);
	StructureOfActions.Insert("FillInVATRateForReturnableContainers", Object.ToReturnReusablePackage);
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmount");
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountManualDiscount", New Structure("Clear", True));
	StructureOfActions.Insert(
		"CheckFillWarehouse",
		BatchProcessingOfTablePartClientServer.GetWarehouseFillStructureInTSLine(
			Object,
			WarehouseGroup_,,,"ToExpenseAs"));
	
	IncomeAndExpensesClientServer.InsertActionClearItemAndExpenseAnalytics(StructureOfActions, ThisObject);
	
	LinesOfBusinessClientServer.StructureOfInsertActionsWhenAddingRow(ThisObject, StructureOfActions);
	StructureOfActions.Insert("FillInCheckQualityDateOfQualityConfirmation", CacheQualityControl);
	
	CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	RowsToProcess = New Array();
	
	For Each CurRow In TableOfGoods Do
		
		ArrayOfCollectionRows = Object.Goods.FindRows(New Structure("LineNumber", CurRow.LineNumber));
		If ArrayOfCollectionRows.Count() <> 1 Then
			Continue;
		Else
			CollectionRow = ArrayOfCollectionRows[0];
		EndIf;
		
		FillPropertyValues(CollectionRow, CurRow, "Products, Characteristic, Package");
		RowsToProcess.Add(CollectionRow);
		
	EndDo;
	
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		RowsToProcess,
		StructureOfActions,
		Object.Goods,
		CachedValues);
		
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInFeatureAttribute", New Structure("Products", "ItemVariantsAreUsed"));
	AccountingForTraceableGoodsClientServerLocalization.CompleteDescriptionOfSettingsForFillingInServiceDetailsOfTablePart(StructureOfActions);
	
	ProductsServer.FillInServiceDetailsForProductInCollection(Object.Goods, StructureOfActions);
	
	WhenChangingWarehouseInTablePartServer();
	FillInServiceDetailsForPurposeOfVTCH();
	CalculateOrderTotals(ThisForm);
	
EndProcedure

&AtServer
Procedure FillIn_BlankReceiptDatesServer()
	
	If Object.Goods.Count() = 0 Then
		Return;
	EndIf;
	
	If Object.OneDateReceipt Then
		If Not ValueIsFilled(Object.DateOfReceipt) Then
			If Not ValueIsFilled(Object.DateOfShipment) Then
				Object.DateOfShipment = DateOfShipmentByCalendar(
					Object.Date, Object.RequestedDeliveryDate, Object.DeliveryDuration, EnterpriseCalendar);
			EndIf;
			Object.DateOfReceipt = DateAccordingToCompanyCalendar(Object.DateOfShipment, Object.DeliveryDuration);
		EndIf;
		DateOfShipment = Object.DateOfShipment;
	Else
		DateOfShipment = ?(ValueIsFilled(Object.DateOfShipment), Object.DateOfShipment, DateOfShipmentByCalendar(
			Object.Date, Object.RequestedDeliveryDate, Object.DeliveryDuration, EnterpriseCalendar));
	EndIf;
	
	DateOfReceipt = DateAccordingToCompanyCalendar(DateOfShipment, Object.DeliveryDuration);
	
	ControlledStringLotReferences = New Array();
	For Each TSRow In Object.Goods Do
		If Not ValueIsFilled(TSRow.DateOfShipment) Then
			TSRow.DateOfShipment = DateOfShipment;
		EndIf;
		
		If Not ValueIsFilled(TSRow.DateOfReceipt) Then
			TSRow.DateOfReceipt = DateOfReceipt;
			ControlledStringLotReferences.Add(TSRow);
		EndIf;
	EndDo;
		
	QualityControl.UpdateActionParameters(Documents.PurchaseOrder, Object, CacheQualityControl);
	
	StructureOfActions = New Structure();
	StructureOfActions.Insert("FillInCheckQualityDateOfQualityConfirmation", CacheQualityControl);
	BatchProcessingOfTablePartServer.ProcessTSStrings(ControlledStringLotReferences, StructureOfActions, Object.Goods);
	
EndProcedure

&AtClientAtServerNoContext
Function MaximumAdvancePaymentDate(PaymentScheduleSteps)
	
	MaxAdvanceDate = '00010101';
	
	For Each CurStage In PaymentScheduleSteps Do
		
		If CurStage.PaymentOption = PredefinedValue("Enum.OptionsForControllingPaymentToSupplier.PrepaymentBeforeReceipt")
			Or CurStage.PaymentOption = PredefinedValue("Enum.OptionsForControllingPaymentToSupplier.PrepaymentBeforeConfirmation") Then
			
			MaxAdvanceDate = Max(MaxAdvanceDate, CurStage.PaymentDate);
			
		EndIf;
		
	EndDo;

	Return MaxAdvanceDate;
	
EndFunction

&AtClient
Procedure FillInShipmentDate(ArrayOfSelectedRows = Undefined)

	DateOfShipment = DateOfShipmentByCalendar(
		Object.Date, Object.RequestedDeliveryDate, Object.DeliveryDuration, EnterpriseCalendar);
	
	If Object.Goods.Count() > 0 Then
		
		Notification = New CallbackDescription("FillInShipmentDateCompletion", ThisObject, New Structure("ArrayOfSelectedRows", ArrayOfSelectedRows));
		
		TMCommonUseClient.EnterDateWithControlOfEmptyValue(DateOfShipment, NStr("vi = 'Hãy nhập ngày giao hàng';
																				|ru = 'Введите дату отгрузки';
																				|en = 'Enter shipment date'; fa = 'Enter shipment date';
																				|it = 'Inserire la data di spedizione';
																				|pl = 'Wprowadź datę wysyłki';
																				|tr = 'Sevkiyat tarihini girin'"), DateFractions.Date, Notification);
		
	Else
		WarningText = NStr("vi = 'Trong chứng từ không có dòng để điền. Sẽ không điền ngày giao hàng.';
							|ru = 'В документе нет строк для заполнения. Дата отгрузки не будет заполнена.';
							|en = 'There are no lines to fill in the document. The shipment date will not be filled in.'; fa = 'There are no lines to fill in the document. The shipment date will not be filled in.';
							|it = 'Nel documento non vi sono righe per la compilazione. La data d spedizione non sarà compilata.';
							|pl = 'Brak wierszy do wypełnienia w dokumencie. Data wysyłki nie będzie wypełniona.';
							|tr = 'Belgede doldurulması gereken satır bulunmamaktadır. Sevkiyat tarihi doldurulmayacaktır.'");
		ShowMessageBox(Undefined, WarningText);
	EndIf;

EndProcedure

&AtClient
Procedure FillInShipmentDateCompletion(SelectedDate, AdditionalParameters) Export
	
	If SelectedDate <> Undefined And ValueIsFilled(SelectedDate) Then
		
		DateOfShipment = SelectedDate;
		DateOfReceipt = DateAccordingToCompanyCalendar(DateOfShipment, Object.DeliveryDuration);
		ArrayOfSelectedRows = AdditionalParameters.ArrayOfSelectedRows;
		
		If ArrayOfSelectedRows = Undefined Then

				For Each TSRow In Object.Goods Do
					TSRow.DateOfShipment = DateOfShipment;
					TSRow.DateOfReceipt = DateOfReceipt;
				EndDo;

		Else

			For Each RowID In ArrayOfSelectedRows Do

					TSRow = Object.Goods.FindByID(RowID);
					TSRow.DateOfShipment = DateOfShipment;
					TSRow.DateOfReceipt = DateOfReceipt;

			EndDo;

		EndIf;
		FillInShipmentDateCompletionServer(ArrayOfSelectedRows);
		SalesClient.NotifyEndOfFillingInShipmentDates(DateOfShipment, (ArrayOfSelectedRows <> Undefined));
	
	EndIf; 
	
EndProcedure

&AtServer
Procedure FillInShipmentDateCompletionServer(SelectedRows)
	
	StructureOfActions = New Structure();
	StructureOfActions.Insert("FillInCheckQualityDateOfQualityConfirmation", CacheQualityControl);
	If SelectedRows = Undefined Then
		BatchProcessingOfTablePartServer.TreatTS(Object.Goods, StructureOfActions);
	Else
		
		Collection = New Array();
		For Each SelectedRow In SelectedRows Do
			Collection.Add(Object.Goods.FindByID(SelectedRow));
		EndDo;
		
		BatchProcessingOfTablePartServer.ProcessTSStrings(Collection, StructureOfActions, Object.Goods);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure LabelPaymentStagesClick(Item, StandardProcessing)
	
	Notification = New CallbackDescription("LabelPaymentStagesClickCompletion", ThisObject);
	PlacePaymentStepsInTemporaryStorage(Item.Name);
	ARAPAccountingClient.LabelPaymentStagesClick(ThisForm, Item, StandardProcessing, Notification );
	
EndProcedure

&AtServer
Procedure PlacePaymentStepsInTemporaryStorage(TagName)
	FillIn_BlankReceiptDatesServer();
	PaymentStepsServer.PlacePaymentStepsInTemporaryStorage(ThisForm, TagName);
EndProcedure

&AtServer
Procedure ReflectChangesToPaymentRules(ChangedBankingDetails)
	PaymentStepsServer.LoadPaymentStagesFromTemporaryStorage(ThisForm);
	ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisForm, ChangedBankingDetails, True);
	FillInSelectionListDesiredReceiptDate();
EndProcedure

&AtClient
Procedure LabelPaymentStagesClickCompletion(Result, AdditionalParameters) Export
	
	If Result <> Undefined Then
		
		ChangedBankingDetails = Result.OldValuesOfChangedProps;
		ReflectChangesToPaymentRules(ChangedBankingDetails);
		
		Object.Approved              = False;
		SetAvailabilityOfItemsByStatusServer();
		
	EndIf;
	
	CalculateOrderTotals(ThisForm);
	
EndProcedure

&AtServer
Function AddressOfDataForCalculatingManualDiscountsInTemporaryStorage(SelectedLinesOnly)
	
	ParametersStructure = DiscountsMarkupsFillingServer.NewParametersAddressDataForCalculatingManualDiscounts();
	ParametersStructure.TableName = "Goods";
	ParametersStructure.OnlyForSelectedLines = SelectedLinesOnly;
	Return DiscountsMarkupsFillingServer.AddressOfDataForCalculatingManualDiscountsInTemporaryPurchaseStorage(
		ThisForm,UUID, ParametersStructure);
	
EndFunction

&AtServer 
Function MaximumShipmentDate()
	
	MaximumShipmentDate = Date(1,1,1);
	For Each OwnGoods In Object.Goods Do 
		MaximumShipmentDate = Max(MaximumShipmentDate, OwnGoods.DateOfShipment);
	EndDo;
	
	Return MaximumShipmentDate
	
EndFunction

&AtServer 
Procedure FillIn_ReceiptDatesServer(DateOfReceipt)
	
	For Each OwnGoods In Object.Goods Do
		OwnGoods.DateOfReceipt = DateOfReceipt;
	EndDo;
	
	If QualityControl.UpdateActionParameters(
			Documents.PurchaseOrder,
			Object,
			CacheQualityControl) Then
		
		StructureOfActions = New Structure();
		StructureOfActions.Insert("FillInCheckQualityDateOfQualityConfirmation", CacheQualityControl);
		BatchProcessingOfTablePartServer.TreatTS(Object.Goods, StructureOfActions);
		
	EndIf;
	
	SetVisibilityOfReceiptDateFormElements();
	
EndProcedure

&AtServer
Procedure DeliveryDurationOnChangeServer()
	If Not Object.OneDateReceipt Then
		DocumentPurchases = FormAttributeToValue("Object");
		DocumentPurchases.RecalculateDatesByCalendar(Object.DeliveryDuration);
		ValueToFormAttribute(DocumentPurchases, "Object");
		
		If QualityControl.UpdateActionParameters(
				Documents.PurchaseOrder,
				Object,
				CacheQualityControl) Then
			StructureOfActions = New Structure();
			StructureOfActions.Insert("FillInCheckQualityDateOfQualityConfirmation", CacheQualityControl);
			BatchProcessingOfTablePartServer.TreatTS(Object.Goods, StructureOfActions);
			
		EndIf;
		
	Else
		If ValueIsFilled(Object.DateOfShipment) Then
			Object.DateOfReceipt = DateAccordingToCompanyCalendar(Object.DateOfShipment, Object.DeliveryDuration);
		EndIf;
		FillIn_ReceiptDatesServer(Object.DateOfReceipt);
	EndIf;
	
	ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisObject, StrSplit("Goods.DateOfReceipt,Goods.DateOfShipment",","));
	
	SetVisibilityOfReceiptDateFormElements();
EndProcedure

&AtServer
Procedure FillInShippingDatesServer(DateOfShipment)
	
	For Each OwnGoods In Object.Goods Do
		OwnGoods.DateOfShipment = DateOfShipment;
	EndDo;
	
EndProcedure

&AtServer 
Procedure SetVisibilityOfReceiptDateFormElements()
	
	Items.GoodsDateOfReceipt.Visible = Not Object.OneDateReceipt And Object.DeliveryDuration > 0;
	Items.GoodsDateOfShipment.Visible = Not Object.OneDateReceipt ;
	Items.DateOfReceipt.Visible = Object.OneDateReceipt And Object.DeliveryDuration > 0;
	Items.DateOfShipment.Visible = Object.OneDateReceipt;
	
EndProcedure

&AtServer
Procedure SetAvailabilityAgreements()
	If ValueIsFilled(Object.Partner) Then
		NumberOfAgreementsWithPostavshik = PurchasesServerCall.GetNumberOfAgreementsWithSupplier(Object.Partner);
		TMCommonUseClientServer.SetFormItemProperty(Items, "Terms", "Visible", NumberOfAgreementsWithPostavshik > 0
			Or ValueIsFilled(Object.Terms));
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
		
	EndIf;
	
	If ValueIsFilled(Object.Terms) Then
		If Object.Goods.Total("Price")<>0 Then
			FillThePricesByTermsOfSalesServer(True);
		EndIf;
		
		PurchasesClient.NotifyEndOfFillingInDefaultPurchaseConditions();
	EndIf;
	
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

&AtClient
Procedure CheckAvailabilityOfOrdersAccordingToSupplierData(VendorReferenceNumber)
	
	OrderList = OrdersBasedOnSupplierData(Object.Ref, Object.Counterparty, VendorReferenceNumber);
	
	If OrderList.Count() > 0 Then
		
		ButtonsList = New ValueList;
		
		If OrderList.Count() = 1 Then
			QueryText = NStr("vi = 'Trong cơ sở thông tin đã có đơn hàng với số như vậy theo dữ liệu của nhà cung cấp. Tiếp tục?';
							|ru = 'В информационной базе уже существует заказ с таким же номером по данным поставщика. Продолжить?';
							|en = 'Purchase order with the same Vendor reference number already exists. Continue?'; fa = 'Purchase order with the same Vendor reference number already exists. Continue?';
							|it = 'Nel database informatico esiste già un ordine con stesso numero in base ai dati del fornitore. Continuare?';
							|pl = 'W bazie informacyjnej już istnieje zamówienie o takim samym numerze według danych dostawcy. Kontynuować?';
							|tr = 'Aynı tedarikçi numarasına sahip bir sipariş veritabanında zaten mevcut. Devam edilsin mi?'");
			ButtonsList.Add("OpenOrderList", NStr("vi = 'Mở đơn hàng';
													|ru = 'Открыть заказ';
													|en = 'Open order'; fa = 'Open order';
													|it = 'Aprire ordine';
													|pl = 'Otwórz zamówienie';
													|tr = 'Sipariş aç'"));
		Else
			QueryText = NStr("vi = 'Trong cơ sở thông tin đã có đơn hàng với số như vậy theo dữ liệu của nhà cung cấp. Tiếp tục?';
							|ru = 'В информационной базе уже существуют заказы с таким же номером по данным поставщика. Продолжить?';
							|en = 'Purchase orders with the same Vendor reference number already exist. Continue?'; fa = 'Purchase orders with the same Vendor reference number already exist. Continue?';
							|it = 'Nel database informatico esistono già gli ordini con stesso numero in base ai dati del fornitore. Continuare?';
							|pl = 'W bazie informacyjnej już istnieją zamówienia o takim samym numerze według danych dostawcy. Kontynuować?';
							|tr = 'Aynı tedarikçi numarasına sahip bir siparişler veritabanında zaten mevcut. Devam edilsin mi?'");
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
		
		UserAnswer = Undefined;

		
		ShowQueryBox(New CallbackDescription("CheckAvailabilityOfOrdersAccordingToSupplierDataCompletion", ThisObject, New Structure("OrderList", OrderList)), QueryText, ButtonsList);
	EndIf;
EndProcedure

&AtClient
Procedure CheckAvailabilityOfOrdersAccordingToSupplierDataCompletion(QuestionResult, AdditionalParameters) Export
    
    OrderList = AdditionalParameters.OrderList;
    
    
    UserAnswer = QuestionResult;
    
    If UserAnswer = "OpenOrderList" Then
        
        If OrderList.Count() > 1 Then
            OpenForm(
            "CommonForm.ViewingListOfDocuments",
            New Structure("DocumentsList, Title",
            OrderList,
            NStr("vi = 'Đơn hàng đặt nhà cung cấp (%DocumentsCount%)';
				|ru = 'Заказы поставщиков (%DocumentsCount%)';
				|en = 'Purchase orders (%DocumentsCount%)'; fa = 'Purchase orders (%DocumentsCount%)';
				|it = 'Ordini dei fornitori (%DocumentsCount%)';
				|pl = 'Zamówienia dostawców (%DocumentsCount%)';
				|tr = 'Satın alma siparişleri (%DocumentsCount%)'")));
        Else
            
            FormParameters = New Structure("Key", OrderList.Get(0).Value);
            OpenForm("Document.PurchaseOrder.ObjectForm", FormParameters);
            
        EndIf;
        
    EndIf;

EndProcedure

&AtServerNoContext
Function OrdersBasedOnSupplierData(CurrentOrder, Counterparty, IncomingDocumentNumber)
	
	DateOfCurrentOrder = Common.ObjectAttributeValue(CurrentOrder, "Date");
	IncomingDocumentDate = ?(ValueIsFilled(DateOfCurrentOrder), DateOfCurrentOrder, CurrentSessionDate());
	
	Query = New Query;
	Query.Text = 
		"SELECT ALLOWED
		|	PurchaseOrder.Ref AS Ref
		|FROM
		|	Document.PurchaseOrder AS PurchaseOrder
		|WHERE
		|	PurchaseOrder.Ref <> &CurrentOrder
		|	AND PurchaseOrder.Date BETWEEN &StartDate AND &EndDate
		|	AND PurchaseOrder.VendorReferenceNumber = &VendorReferenceNumber
		|	AND PurchaseOrder.Counterparty = &Counterparty
		|	AND NOT PurchaseOrder.DeletionMark";

	Query.SetParameter("StartDate", AddMonth(IncomingDocumentDate, -3));
	Query.SetParameter("EndDate", AddMonth(IncomingDocumentDate, 3));
	Query.SetParameter("VendorReferenceNumber", IncomingDocumentNumber);
	Query.SetParameter("Counterparty", Counterparty);
	Query.SetParameter("CurrentOrder", CurrentOrder);
	
	OrderList = New ValueList;
	OrderList.LoadValues(Query.Execute().Unload().UnloadColumn("Ref"));
	
	Return OrderList;
	
EndFunction

&AtServerNoContext
Procedure UpdateAvailabilityOfReturnContainerItems(Form)
	
	ItemArray = New Array();
	ItemArray.Add("ReusablePackageReturnCycleLength");
	ItemArray.Add("PackageDepositIsRequired");
	
	TMCommonUseClientServer.SetPropertyOfFormElements(
		Form.Items,
		ItemArray,
		"Enabled",
		Form.Object.ToReturnReusablePackage);
	
	TMCommonUseClientServer.SetFormItemProperty(
		Form.Items,
		"ToReturnReusablePackage",
		"Enabled",
		Form.Object.BusinessOperation <> Enums.BusinessTransactions.PurchaseFromVendorLocal
		And Form.Object.BusinessOperation <> Enums.BusinessTransactions.PurchaseByImport
		And Form.Object.BusinessOperation <> Enums.BusinessTransactions.ImportGoodsInTransit
		And Form.Object.BusinessOperation <> Enums.BusinessTransactions.ImportFromEAEU
		And Form.Object.BusinessOperation <> Enums.BusinessTransactions.ImportFromEAEUGoodsInTransit
		And Form.Object.BusinessOperation <> Enums.BusinessTransactions.ImportFromEAEUInvoicedDelivery
		And Form.Object.BusinessOperation <> Enums.BusinessTransactions.ConsignmentProcurement
		And Form.Object.BusinessOperation <> Enums.BusinessTransactions.ReceivingForStorageWithRightOfSale);
	
EndProcedure

&AtServer
Procedure FillMultiTurnContainersFromStorageServer(AddressOfContainerInStorage)
	
	ActionStructureModifiedStrings = New Structure;
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	ActionStructureModifiedStrings.Insert("RecalculateNumberOfPackages");
	ActionStructureModifiedStrings.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	ActionStructureModifiedStrings.Insert("RecalculateAmount");
	ActionStructureModifiedStrings.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	ActionStructureModifiedStrings.Insert("RecalculateAmountTakingIntoAccountManualDiscount", New Structure("Clear", True));
	ActionStructureModifiedStrings.Insert("FillInNoReturnContainerAttribute", Object.ToReturnReusablePackage);
	ActionStructureModifiedStrings.Insert("FillInCanceledWithoutReturnableContainerAttribute", Object.ToReturnReusablePackage);
	ActionStructureModifiedStrings.Insert("FillInDuplicateDependentDetails", DependentDetails());
	
	StructureOfActionsAddedLines =  CommonClientServer.CopyStructure(ActionStructureModifiedStrings);;
	StructureOfActionsAddedLines.Insert("CheckFillWarehouse", BatchProcessingOfTablePartClientServer.GetWarehouseFillStructureInTSLine(Object, WarehouseGroup_,,,"ToExpenseAs"));
	StructureOfActionsAddedLines.Insert("FillInProductNameOfProductPartner", Object.Partner);
	
	If UseTermsOfPurchases And ValueIsFilled(Object.Terms) Then
		StructureOfActionsAddedLines.Insert("FillInTermsOfPurchase", BatchProcessingOfTablePartClientServer.GetStructureForFillingInPurchasePriceInTSLine(Object));
	Else
		StructureOfActionsAddedLines.Insert("FillInPurchasePrice", BatchProcessingOfTablePartClientServer.GetStructureForFillingInPurchasePriceInTSLine(Object));
	EndIf;
	
	StructureOfActionsAddedLines.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
	ParametersForFillingInVATRate = BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRate(Object, True);
	ParametersForFillingInVATRate.SpecifiedVATRate = SpecifiedVATRate;
	If Object.OneDateReceipt And ValueIsFilled(Object.DateOfShipment) Then
		ParametersForFillingInVATRate.Date = Object.DateOfShipment;
	EndIf;
	StructureOfActionsAddedLines.Insert("FillInVATRate", ParametersForFillingInVATRate);
	StructureOfActionsAddedLines.Insert("FillInVATRateForReturnableContainers", Object.ToReturnReusablePackage);
	StructureOfActionsAddedLines.Insert("FillInNoReturnContainerAttribute", Object.ToReturnReusablePackage);
	StructureOfActionsAddedLines.Insert("FillInCanceledWithoutReturnableContainerAttribute", Object.ToReturnReusablePackage);
	StructureOfActionsAddedLines.Insert("FillInDuplicateDependentDetails", DependentDetails());
	LinesOfBusinessClientServer.StructureOfInsertActionsWhenAddingRow(ThisForm, StructureOfActionsAddedLines);
	StructureOfActionsAddedLines.Insert("FillInCheckQualityDateOfQualityConfirmation", CacheQualityControl);
	
	ReusablePackageServer.FillMultiTurnContainersFromStorage(
		Object,
		AddressOfContainerInStorage,
		"Goods",
		"Products,Characteristic,Warehouse,DateOfShipment,DateOfReceipt",
		ActionStructureModifiedStrings,
		StructureOfActionsAddedLines);
		
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInFeatureAttribute", New Structure("Products", "ItemVariantsAreUsed"));
	StructureOfActions.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
	StructureOfActions.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));
	AccountingForTraceableGoodsClientServerLocalization.CompleteDescriptionOfSettingsForFillingInServiceDetailsOfTablePart(StructureOfActions);
	ProductsServer.FillInServiceDetailsForProductInCollection(Object.Goods, StructureOfActions);
	CalculateOrderTotals(ThisForm);
	WhenChangingWarehouseInTablePartServer();
	FillInServiceDetailsForPurposeOfVTCH();
	
EndProcedure

&AtServer
Procedure GetUploadedProductsFromStorage(GoodsAddressInStorage)
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("CheckFillWarehouse", BatchProcessingOfTablePartClientServer.GetWarehouseFillStructureInTSLine(Object, WarehouseGroup_,,,"ToExpenseAs"));
	StructureOfActions.Insert("FillInVATRateForReturnableContainers", Object.ToReturnReusablePackage);
	StructureOfActions.Insert("FillInNoReturnContainerAttribute", Object.ToReturnReusablePackage);
	StructureOfActions.Insert("FillInCanceledWithoutReturnableContainerAttribute", Object.ToReturnReusablePackage);
	StructureOfActions.Insert("FillInDuplicateDependentDetails", DependentDetails());
	StructureOfActions.Insert("WhenChangingProductType",
		New Structure("ThereAreWorks, ThereIsWriteOffForExpenses", True, True));
	LinesOfBusinessClientServer.StructureOfInsertActionsWhenAddingRow(ThisObject, StructureOfActions);
	StructureOfActions.Insert("FillInCheckQualityDateOfQualityConfirmation", CacheQualityControl);
	
	RowsToProcess = New Array;	
	ItemsFromStorage = GetFromTempStorage(GoodsAddressInStorage);
	
	DateOfShipment = DateAccordingToCompanyCalendar(Object.DateOfReceipt, -Object.DeliveryDuration);
	For Each RowOfGoods In ItemsFromStorage Do
		StringTSGoods = Object.Goods.Add();
		FillPropertyValues(StringTSGoods, RowOfGoods,,"RowCode");
		If Object.OneDateReceipt Then
			StringTSGoods.DateOfReceipt = Object.DateOfReceipt;
			StringTSGoods.DateOfShipment = DateOfShipment;
		EndIf;
		RowsToProcess.Add(StringTSGoods);
	EndDo;
	
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		RowsToProcess,
		StructureOfActions,
		Object.Goods);
		
	For Each RowOfGoods In RowsToProcess Do
		IncomeAndExpensesClientServer.WhenAddingRowToTable(ThisObject, StringTSGoods, "Object.Goods");
	EndDo;
	
	If Not PurchasesServer.ThisIsUnfacturedDeliveryOfServicesWorks(Object.BusinessOperation, OptionOfProcessingDocumentsForServices) Then
		FillInAttributeForDebitingExpensesForServices();
	EndIf;
	
	CalculateOrderTotals(ThisForm);
	WhenChangingWarehouseInTablePartServer();
	ReusablePackageServer.UpdateFillingStateOfMultiTurnContainer(Object.ReusablePackageFillingStatus);
	UpdateVHFWarehouseObligation();
	FillInServiceDetailsForPurposeOfVTCH();
	
EndProcedure

&AtServer
Procedure FillInFinancialAccountingGroup()
	
	If ValueIsFilled(Object.Contract) Then
		Object.FinancialAccountingGroup = Common.ObjectAttributeValue(Object.Contract, "FinancialAccountingGroup");
	EndIf;
	
EndProcedure

&AtServer
Procedure PaymentCreditedServer(EventName, Parameter, Source)
	
	RefreshStatusServer();
	ARAPAccountingFormWork.NotificationProcessing(ThisForm, EventName, Parameter);
	
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
	ElsIf Item.Name = "Counterparty" Then
		CounterpartyOnChange(Item);
	ElsIf Item.Name = "Warehouse" Then
		WarehouseOnChange(Item);
	ElsIf Item.Name = "BusinessOperation" Then
		BusinessOperationOnChange(Item);
	ElsIf Item.Name = "OneDateReceipt" Then
		OneDateReceiptOnChange(Item);
	ElsIf Item.Name = "DateOfReceipt" Then
		DateOfReceiptOnChange(Item);
	ElsIf Item.Name = "ToReturnReusablePackage" Then
		ToReturnReusablePackageOnChange(Item);
	ElsIf Item.Name = "PackageDepositIsRequired" Then
		PackageDepositIsRequiredOnChange(Item);
	ElsIf Item.Name = "ApprovalDate" Then
		ApprovalDateOnChange(Item);
	ElsIf Item.Name = "DateOfShipment" Then
		DateOfShipmentOnChange(Item);
	ElsIf Item.Name = "GoodsPartnerProducts" Then
		GoodsPartnerProductsOnChange(Item);
	ElsIf Item.Name = "GoodsProducts" Then
		GoodsProductsOnChange(Item);
	ElsIf Item.Name = "GoodsCharacteristic" Then
		GoodsCharacteristicOnChange(Item);
	ElsIf Item.Name = "GoodsPurpose" Then
		GoodsPurposeOnChange(Item);
	ElsIf Item.Name = "GoodsNumberOfPackages" Then
		NumberOfPackagesOnChange(Item);
	ElsIf Item.Name = "GoodsPackage" Then
		GoodsPackageOnChange(Item);
	ElsIf Item.Name = "GoodsVendorPriceKind" Then
		GoodsVendorPriceKindOnChange(Item);
	ElsIf Item.Name = "GoodsWarehouse" Then
		GoodsWarehouseOnChange(Item);
	ElsIf Item.Name = "GoodsPrice" Then
		GoodsPriceOnChange(Item);
	ElsIf Item.Name = "GoodsPercentRateOfManualDiscount" Then
		GoodsPercentRateOfManualDiscountOnChange(Item);
	ElsIf Item.Name = "GoodsManualDiscount" Then
		GoodsManualDiscountOnChange(Item);
	ElsIf Item.Name = "GoodsSum" Then
		GoodsSumOnChange(Item);
	ElsIf Item.Name = "GoodsVATRate" Then
		GoodsVATRateOnChange(Item);
	ElsIf Item.Name = "GoodsVATAmount" Then
		GoodsVATAmountOnChange(Item);
	ElsIf Item.Name = "GoodsToExpenseAs" Then
		GoodsToExpenseAsOnChange(Item);
	ElsIf Item.Name = "GoodsExpenseItem" Then
		GoodsExpenseItemOnChange(Item);
	ElsIf Item.Name = "ProductsCanceledCancellationReasonsAreNotUsed" Then
		GoodsCanceledOnChange(Item);
	ElsIf Item.Name = "GoodsCanceled" Then
		GoodsCanceledOnChange(Item);
	ElsIf Item.Name = "GoodsDateOfShipment" Then
		GoodsDateOfShipmentOnChange(Item);
	ElsIf Item.Name = "GoodsToControlQuality" Then
		GoodsToControlQualityOnChange(Item);
	ElsIf Item.Name = "GoodsQualityConfirmationDate" Then
		GoodsQualityConfirmationDateOnChange(Item);
	ElsIf Item.Name = "RequestedDeliveryDate" Then
		RequestedDeliveryDateOnChange(Item);
	ElsIf Item.Name = "Department" Then
		DepartmentOnChange(Item);
	Else
		TMCommonUseClient.MonitoringNonConsistentChangesCauseException(ThisForm, Item);
	EndIf;
EndProcedure

// Parameters:
//	Command - FormCommand - 
&AtClient
Procedure ControlOfNonConsistentChangesHandleCommandEvent(Command)
	If Command.Name = "SelectGoods" Then
		SelectGoods(Command);
	ElsIf Command.Name = "AddReusablePackage" Then
		AddReusablePackage(Command);
	ElsIf Command.Name = "ImportFromExternalFile" Then
		ImportFromExternalFile(Command);
	ElsIf Command.Name = "SearchByBarcode" Then
		SearchByBarcodeExecute(Command);
	ElsIf Command.Name = "ImportDataFromPDT" Then
		ImportDataFromPDT(Command);
	ElsIf Command.Name = "FillInTheWarehouseInSelectedLines" Then
		FillInTheWarehouseInSelectedLines(Command);
	ElsIf Command.Name = "FillThePricesByTermsOfSales" Then
		AutoTestFillInPricesByAgreement(Command);
	ElsIf Command.Name = "FillInThePricesOfTheSelectedLinesByTheTypeOfSupplierSPrice" Then
		FillInThePricesOfTheSelectedLinesByTheTypeOfSupplierSPrice(Command);
	ElsIf Command.Name = "AdjustPricesForGoodsReceipts" Then
		AdjustPricesForGoodsReceipts(Command);
	ElsIf Command.Name = "CancelManualDiscounts" Then
		CancelManualDiscounts(Command);
	ElsIf Command.Name = "AssignAManualDiscountToSelectedRows" Then
		AssignAManualDiscountForSelectedLines(Command);
	ElsIf Command.Name = "InsertRows" Then
		InsertRows(Command);
	ElsIf Command.Name = "SplitRow" Then
		SplitRow(Command);
	ElsIf Command.Name = "SelectSubstitutes" Then
		SelectSubstitutes(Command);
	ElsIf Command.Name = "FillInTheDepartment" Then
		FillInTheDepartment(Command);
	ElsIf Command.Name = "FillInTheItemByThePartnerSItem" Then
		FillInTheItemByThePartnerSItem(Command);
	ElsIf Command.Name = "FillInVATRate" Then
		FillInVATRate(Command);
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
&AtClient
Procedure ControlOfNonConsistentChangesHandleEventBeforeDeletion(Item, Cancel)
	
	If Item.Name = "Goods" Then
		GoodsBeforeDeleteRow(Item, Cancel);
	Else
		TMCommonUseClient.MonitoringNonConsistentChangesCauseException(ThisForm, Item);
	EndIf;
	
EndProcedure

&AtClient
Procedure ControlOfNonConsistentChangesHandleEventBeforeStartingAdding(Item, Cancel, Copy, Parent, Var_Group)
	TMCommonUseClient.MonitoringNonConsistentChangesCauseException(ThisForm, Item);
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
	StructureOfActions.Insert("FillInVATRateForReturnableContainers", Object.ToReturnReusablePackage);
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForRecalculatingNDSWTCHAmount(Object);
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));
	
	BatchProcessingOfTablePartServer.TreatTS(Object.Goods, StructureOfActions, Undefined);
	
	UpdateDuplicateDependentDetails();
	CalculateOrderTotals(ThisForm);
	UpdateAvailabilityOfReturnContainerItems(ThisForm);
	
EndProcedure

&AtServer
Procedure UpdateDuplicateDependentDetails()
	
	StructureOfAdditionalActions = New Structure;
	StructureOfAdditionalActions.Insert("FillInCanceledWithoutReturnableContainerAttribute", Object.ToReturnReusablePackage);
	ReusablePackageServer.UpdateNoReturnableContainerAttribute(Object.Goods, Object.ToReturnReusablePackage, StructureOfAdditionalActions);
	TMCommonUse.FillInDuplicateDependentPropsInCollection(Object.Goods, DependentDetails());
	
EndProcedure

&AtServer
Procedure FillInSelectionListDesiredReceiptDate()

	MaxAdvanceDate = MaximumAdvancePaymentDate(Object.PaymentScheduleSteps);
	DesiredReceiptDateSelectionList = Items.RequestedDeliveryDate.ChoiceList;
	
	If ValueIsFilled(MaxAdvanceDate) Then
		
		PresentationMaxAdvanceDate = "%MaxAdvanceDate%";
		PresentationMaxAdvanceDate = StrReplace(PresentationMaxAdvanceDate, "%MaxAdvanceDate%", Format(MaxAdvanceDate,"DLF=DD"));
		
		DesiredReceiptDateSelectionList.Clear();
		DesiredReceiptDateSelectionList.Add(MaxAdvanceDate, PresentationMaxAdvanceDate);
		
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

&AtClient
Procedure GoodsPurposeOnChange(Item)
	
	CurrentData = Items.Goods.CurrentData;
	CurrentData.ToExpenseAs = False;
	
	IncomeAndExpensesClientServer.WhenChangingArticleAvailabilityDetailsInLine(ThisObject, CurrentData, "Object.Goods");
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInServiceDetailsForPurpose");
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentData, StructureOfActions, CachedValues);
	If CurrentData.AssignmentType = PredefinedValue("Enum.AssignmentTypes.DeliveryForPrincipal")
		Or ((CurrentData.ItemsType = PredefinedValue("Enum.ItemsTypes.OwnGoods") Or
			CurrentData.ItemsType = PredefinedValue("Enum.ItemsTypes.ReusablePackage"))
			And Not CurrentData.ToExpenseAs) Then
		CurrentData.Department = PredefinedValue("Catalog.BusinessStructure.EmptyRef");
	EndIf;
	
EndProcedure

&AtClient
Procedure FillInTheDepartment(Command)
	
	SelectedRows = Items.Goods.SelectedRows;
	
	If Object.Goods.Count() = 0 Then
		ShowMessageBox( , NStr("vi = 'Trong danh sách ""Hàng hóa"" chưa điền dòng nào.';
								|ru = 'В список ""Товары"" не введено ни одной строки.';
								|en = 'Purchase order contains no items.'; fa = 'Purchase order contains no items.';
								|it = 'Nell''elenco ""Merci"" non è stata immessa alcuna riga.';
								|pl = 'Do listy ""Wiersze pozycji"" nie wprowadzono żadnego wiersza.';
								|tr = '""Ürünler"" listesine hiçbir satır girilmemiştir.'"));
		Return;
	Else
		
		RequiredFilling_ = False;
		
		For Each String In SelectedRows Do
			
			RowData = Object.Goods.FindByID(String);
			
			If (RowData.ItemsType = PredefinedValue("Enum.ItemsTypes.OwnGoods") Or
				RowData.ItemsType = PredefinedValue("Enum.ItemsTypes.ReusablePackage"))
				And (Not RowData.ToExpenseAs Or ValueIsFilled(RowData.Purpose)) Then
				Continue;
			EndIf;
			
			RequiredFilling_ = True;
			Break;
			
		EndDo;
		
		If Not RequiredFilling_ Then
			ShowMessageBox( , NStr("vi = 'Tại các dòng đã chọn trong danh sách ""Hàng hóa"" không cần điền bộ phận nhận.';
									|ru = 'В выделенных строках списка ""Товары"" заполнение подразделения-получателя не требуется.';
									|en = 'No need to specify a Receiving business unit for the selected items.'; fa = 'No need to specify a Receiving business unit for the selected items.';
									|it = 'Nelle righe selezionate dell''elenco ""Merci"" non è richiesta la compilazione del reparto-destinatario.';
									|pl = 'W zaznaczonych wierszach listy ""Wiersze pozycji"" wypełnienie działów-odbiorców nie jest wymagane.';
									|tr = '""Ürünler"" listesinin seçili satırlarında alıcı departmanın doldurulmasına gerek yoktur.'"));
			Return;
		EndIf;
		
	EndIf;
	
	FormParameters = New Structure("Department", Object.Department);
	
	OpenForm("Catalog.BusinessStructure.ChoiceForm", FormParameters, ThisForm);
	
EndProcedure

&AtServer
Procedure FillInAttributeForDebitingExpensesForServices()
	
	// filling in the write-off attribute for expenses
	StructureOfActions = New Structure;
	IncomeAndExpensesClientServer.InsertActionFillInItemCostAnalysisOfProducts(
		StructureOfActions,
		ThisObject,
		Object.BusinessOperation,
		Object.Organization,
		Object.Department);
	
	FilterStructure1 = New Structure("ItemsType", Enums.ItemsTypes.OperationService);
	FoundRows = Object.Goods.FindRows(FilterStructure1);
	For Each String In FoundRows Do
		If UseAccountingOfOtherIncomeExpenses Then
			String.ToExpenseAs = True;
		EndIf;
	EndDo;
		
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		FoundRows,
		StructureOfActions,
		Object.Goods);
		
	For Each String In FoundRows Do
		IncomeAndExpensesClientServer.WhenChangingArticleAvailabilityDetailsInLine(ThisObject, String, "Object.Goods");
	EndDo;
	
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
Procedure FillInVATRateCompletion(VATRate, AdditionalParameters) Export

	If VATRate = Undefined Then
		Return;
	EndIf;

	ClearMessages();

	FillInVATRateOnServer(VATRate, CachedValues);

	CalculateOrderTotals(ThisObject);

EndProcedure

&AtServer
Procedure FillInVATRateOnServer(VATRate, CachedValues)

	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmount");
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountManualDiscount", New Structure("Clear", False));
	StructureOfActions.Insert("FillInDuplicateDependentDetails", DependentDetails());

	For Each LineOfATabularSection In ProcessingOfTabularFormsClientServer.CollectionItems(Object.Goods, Items.Goods.SelectedRows) Do
		LineOfATabularSection.VATRate = VATRate;
		BatchProcessingOfTablePartServer.ProcessTSString(LineOfATabularSection, StructureOfActions, CachedValues);
	EndDo;

	TMCommonUse.FillInDuplicateDependentPropsInCollection(Object.Goods, DependentDetails());
	CalculateOrderTotals(ThisObject);

EndProcedure

#EndRegion
#Region Substitutes

&AtClient
Procedure OpenSelectionOfAnalogues()
	
	TableName = "Goods";
	
	If Items[TableName].SelectedRows.Count() = 0 Then
		ShowMessageBox(, NStr("vi = 'Bạn phải chọn (các) dòng';
								|ru = 'Необходимо выделить строку(и)';
								|en = 'Select items'; fa = 'انتخاب اقلام';
								|it = 'È necessario evidenziare la riga (le righe)';
								|pl = 'Należy zaznaczyć wiersz(e)';
								|tr = 'Satır(lar) vurgulanmalıdır'"));
		Return;
	EndIf;
	
	AlternativeMaterialsClient.OpenSelectionOfAnalogues(AnalogSelectionParameters(TableName, 1), ThisForm);
	
EndProcedure

&AtServer
Procedure Replace_With_Analogues(AddressInStorage = Undefined)
	
	TableName = "Goods";
	AdditionalFields = "VendorPriceKind, Department, Warehouse, Purpose";
	
	Result = AlternativeMaterials.PerformReplacementForAnalogues(
		Object[TableName], AddressInStorage, AdditionalFields, "Action_Substitutes_ToReserve_");
		
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
	
	Modified = True;
	
	StructureOfActions = New Structure;
	CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	
	RowsToProcess = New Array();
	AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions, ThisObject);
	For Each RowIndex In IndexesOfModifiedRows Do
		RowsToProcess.Add(Object[TableName][RowIndex]);
	EndDo;
	
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		RowsToProcess,
		StructureOfActions,
		Object[TableName],
		CachedValues);
	
	StructureOfActions.Clear();
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	
	If UseTermsOfPurchases And ValueIsFilled(Object.Terms) Then
		StructureOfActions.Insert("FillInTermsOfPurchase", BatchProcessingOfTablePartClientServer.GetStructureForFillingInPurchasePriceInTSLine(Object));
	Else
		StructureOfActions.Insert("FillInPurchasePrice", BatchProcessingOfTablePartClientServer.GetStructureForFillingInPurchasePriceInTSLine(Object));
	EndIf;
	
	StructureOfActions.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
	StructureOfActions.Insert("FillInArticleAttribute", New Structure("Products", "SKU")); 
	ParametersForFillingInVATRate =
		BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRate(Object, True);
		ParametersForFillingInVATRate.SpecifiedVATRate = SpecifiedVATRate;
		StructureOfActions.Insert("FillInVATRate", ParametersForFillingInVATRate);
	StructureOfActions.Insert("FillInVATRateForReturnableContainers", Object.ToReturnReusablePackage);
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmount");
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountManualDiscount", New Structure("Clear", True));
	
	StructureOfActions.Insert(
		"CheckFillWarehouse",
		BatchProcessingOfTablePartClientServer.GetWarehouseFillStructureInTSLine(Object, WarehouseGroup_,,,"ToExpenseAs"));
			
	StructureOfActions.Insert("FillInNoReturnContainerAttribute", Object.ToReturnReusablePackage);
	StructureOfActions.Insert("FillInCanceledWithoutReturnableContainerAttribute", Object.ToReturnReusablePackage);
	StructureOfActions.Insert("FillInDuplicateDependentDetails", DependentDetails());
	StructureOfActions.Insert("FillInCheckQualityDateOfQualityConfirmation", CacheQualityControl);
	StructureOfActions.Insert(
		"ProductsOnChangeOverridable", New Structure("FormName, TabularSectionName", FormName, "Goods"));
	StructureOfActions.Insert("FillInWriteOFFAttributeForExpensesAndDivision");

	CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	IncomeAndExpensesClientServer.InsertActionClearItemAndExpenseAnalytics(StructureOfActions, ThisObject);
	
	RowsToProcess = New Array();
	
	For Each RowIndex In IndexesOfNewRows Do
		RowsToProcess.Add(Object[TableName][RowIndex]);
	EndDo;
		
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		RowsToProcess,
		StructureOfActions,
		Object[TableName],
		CachedValues);
	
	For Each TSRow In RowsToProcess Do
		IncomeAndExpensesClientServer.WhenChangingArticleAvailabilityDetailsInLine(ThisObject, TSRow, "Object.Goods");
	EndDo;
	
	If ControlProductRange Then
		ProductRangeServer.CheckAssortmentOfTableOfSelectedProducts(Object, "Warehouse");
	EndIf;
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInFeatureAttribute", New Structure("Products", "ItemVariantsAreUsed"));
	AccountingForTraceableGoodsClientServerLocalization.CompleteDescriptionOfSettingsForFillingInServiceDetailsOfTablePart(StructureOfActions);
	
	ProductsServer.FillInServiceDetailsForProductInCollection(Object.Goods, StructureOfActions);
	
	WhenChangingWarehouseInTablePartServer();
	FillInServiceDetailsForPurposeOfVTCH();
	CalculateOrderTotals(ThisForm);
	
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

	SourceType = New TypeDescription("DocumentRef.PurchaseOrder");
	FormParameters = AlternativeMaterials.AnalogSelectionParameters(SourceType);
	
	// GoodsParameters
	FieldsStructure = AlternativeMaterials.StructureOfTableFieldsToReplaceWithAnalogues();
	FieldsStructure.AdditionalFields.Insert("Ref", New TypeDescription("DocumentRef.PurchaseOrder"));
	FieldsStructure.DefaultValues.Insert("Ref", Object.Ref);
	
	RowFilter = New Structure;
	RowFilter.Insert("Canceled", New Array);
	RowFilter.Canceled.Add(False);
	
	ObjectTable = Object[TableName].Unload();//ValueTable
	ObjectTable.Columns.Add("WithAssignment", New TypeDescription("Boolean"));
	
	ObjectName = "Object";
	
	FormData1 = New Structure;
	FormData1.Insert("Items", Items);
	FormData1.Insert("UUID", UUID);
	FormData1.Insert(ObjectName, New Structure);
	FormData1[ObjectName].Insert(TableName, ObjectTable.CopyColumns());
	
	For Each TableRow In ObjectTable Do
		
		TableRow.WithAssignment = ValueIsFilled(TableRow.Purpose);
		
		RowID = Object[TableName][TableRow.LineNumber - 1].GetID();
		
		If Items[TableName].SelectedRows.Find(RowID) = Undefined Then
			Continue;
		EndIf;
		
		FormTable = FormData1[ObjectName][TableName]; //ValueTable
		FillPropertyValues(FormTable.Add(), TableRow);
		
	EndDo;	
	
	AddlParameters = AlternativeMaterials.AdditionalParameters();
	AddlParameters.RowFilter     = RowFilter;
	AddlParameters.SourceOfResults = ObjectTable;
	
	ProductData_9 = AlternativeMaterials.GetProductData(
		FormData1, ObjectName, TableName, Mode, False, FieldsStructure, AddlParameters);
		
	FillPropertyValues(FormParameters.GoodsParameters, ProductData_9);
	
	// SubstitutesParameters
	ParametersTable = FormParameters.SubstitutesParameters.ParametersTable;
	
	TableRow = ParametersTable.Add();
	TableRow.PermissionValidityDate = BegOfDay(CurrentSessionDate());
	TableRow.Ref = Object.Ref;
	TableRow.LineOfBusiness = Object.LineOfBusiness;
	
	FormParameters.SubstitutesParameters.ParametersTable = 
		PutToTempStorage(ParametersTable, UUID);
		
	FormParameters.SubstitutesParameters.Warehouse = Catalogs.Warehouses.EmptyRef();	
	
	Return FormParameters;
	
EndFunction

#EndRegion
#Region Other

&AtClient
Procedure Attachable_CloseForm()
	
	If IsOpen() Then
		Close();
	EndIf;
	
EndProcedure

&AtClient
Procedure GoodsDimensionOfExpensesStartChoice(Item, ChoiceData, StandardProcessing)
	
	IncomeAndExpensesClient.StartSelectingExpenseAnalytics(ThisForm, Item, StandardProcessing);
	
EndProcedure

&AtClient
Procedure GoodsDimensionOfExpensesAutoComplete(Item, Text, ChoiceData, Var_Parameters, Waiting, StandardProcessing)
	
	IncomeAndExpensesClient.AutoSelectionOfExpenseAnalytics(ThisObject, Item, Text, ChoiceData, Var_Parameters, StandardProcessing);
	
EndProcedure

&AtClient
Procedure GoodsDimensionOfExpensesTextEditEnd(Item, Text, ChoiceData, Var_Parameters, StandardProcessing)

	IncomeAndExpensesClient.EndOfCostAnalyticsTextEntry(ThisObject, Item, Text, ChoiceData, Var_Parameters, StandardProcessing);
	
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
	
	Items.GoodsWarehouse.ChoiceParameters = New FixedArray(New Array);
	TMCommonUseClientServer.AddSelectionParameter(Items.GoodsWarehouse, "Ref", WarehouseSelectionData(Object.Warehouse));

EndProcedure

&AtServer
Procedure FillInAndSetDeliveryAttributesServer(FormItemName);
	
	GoodsDelivery.FillInDeliveryDetails(Items, FormItemName, Object);
	
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
Procedure FillInListOfDeliveryAddressesForSupplier(ReFillIn_DeliveryAddress = False)
	
	If Not Catalogs.Warehouses.IsFolder(Object.Warehouse) Then
		AvailableWarehouses = New Array;
		AvailableWarehouses.Add(Object.Warehouse);
	Else
		AvailableWarehouses = Object.Goods.Unload(,"Warehouse").UnloadColumn("Warehouse");
	EndIf;
	
	AddressSelectionList = Documents.PurchaseOrder.WarehouseAddresses(AvailableWarehouses, Object.Date);
	
	ItemSelectionList = Items.DeliveryAddressForVendor2.ChoiceList;
	
	If GetFunctionalOption("UseDeliveryManagement") Then
		ItemSelectionList = Items.DeliveryAddressForVendor.ChoiceList;
	EndIf;
	
	ItemSelectionList.Clear();
	
	For Each ListItem In AddressSelectionList Do
		ItemSelectionList.Add(ListItem.Value, ListItem.Presentation);
	EndDo;
	
	If ReFillIn_DeliveryAddress Then
		If AddressSelectionList.Count() = 1 Then
			Object.DeliveryAddressForVendor = AddressSelectionList[0].Value;
		Else
			Object.DeliveryAddressForVendor = "";
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure OpenContactInformationSelectionForm(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	
	// Let's open the KI editing dialog
	OpeningParameters = New Structure;
	OpeningParameters.Insert("Presentation",           Item.EditText);
	OpeningParameters.Insert("ContactInformationKind", PredefinedValue("Catalog.ContactInformationKinds.WarehouseAddress"));
	
	Notification = New CallbackDescription("OpenContactInformationSelectionFormCompletion", ThisObject);
	
	ContactsManagerClient.OpenContactInformationForm(OpeningParameters, ThisObject, Notification);
	
EndProcedure

&AtClient
Procedure OpenContactInformationSelectionFormCompletion(Result, AdditionalParameters) Export
	
	If TypeOf(Result) = Type("Structure") Then
		Modified = True;
		
		Object.DeliveryAddressForVendor = Result.Presentation;
	EndIf;
	
EndProcedure

&AtServer
Procedure UpdateShippingSummary()
	
	GoodsDelivery.WhenReadingCreatingOrdersOnServer(Items, Object,,,SummaryDeliveryInformation);
	
EndProcedure

&AtClient
Procedure CloseOrder(Command)
	
	If Modified Or Not Object.Posted Then
		Response = Undefined;
		ShowQueryBox(New CallbackDescription("CloseOrderCompletion", ThisObject),
						NStr("vi = 'Cần kết chuyển chứng từ để thực hiện giao dịch. Kết chuyển chứng từ?';
							|ru = 'Необходимо провести документ для выполнения операции. Провести документ?';
							|en = 'To proceed, you need to post the document. Do you want to post it?'; fa = 'To proceed, you need to post the document. Do you want to post it?';
							|it = 'È necessario registrare il documento per eseguire operazione. Registrare documento?';
							|pl = 'Należy zaksięgować dokument aby wykonać operację. Zaksięgować dokument?';
							|tr = 'Bir işlemin gerçekleştirilmesi için belgenin düzenlenmesi gerekir. Belge düzenlensin mi?'"),QuestionDialogMode.YesNo);
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
	ClosureStructure.Insert("CorrectPrices",          True);
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
		ClearMessages();
		Write(WriteParameters);
	EndIf;
	
EndProcedure

&AtServer
Procedure AdjustOrderLines(StructureOfAdditionalParameters)
	
	// Price adjustment
	If StructureOfAdditionalParameters.CorrectPrices Then
		AdjustPricesForGoodsReceiptsServer();
	EndIf;
	
	DocumentPurchases = FormAttributeToValue("Object");
	
	StructureOfAdditionalParameters.CheckBalance = Not (DocumentPurchases.Status = Enums.PurchaseOrderStatuses.NotApproved);
	
	ResultStructure1 = DocumentPurchases.AdjustOrderLines(StructureOfAdditionalParameters);
	
	If ResultStructure1.RowsCount <> 0 Or ResultStructure1.VarianceAmount > 0 Then
		
		PaymentStepsServer.CheckAndFillInPaymentScheduleStages(DocumentPurchases);
		
	EndIf;
	
	If StructureOfAdditionalParameters.CloseOrders Then
		DocumentPurchases.Status = Enums.PurchaseOrderStatuses.Closed;
	EndIf;
	
	ValueToFormAttribute(DocumentPurchases, "Object");
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInFeatureAttribute", New Structure("Products", "ItemVariantsAreUsed"));
	StructureOfActions.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
	StructureOfActions.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));
	ProductsServer.FillInServiceDetailsForProductInCollection(Object.Goods, StructureOfActions);
	UpdateDuplicateDependentDetails();
	
	CalculateOrderTotals(ThisForm);
	Modified = True;
	
EndProcedure

&AtServer
Procedure FillInVATTaxationPurchases()
	
	FillParameters = Documents.PurchaseOrder.ParametersForFillingInVATTaxationPurchases(Object);
	VATAccountingERP.FillInVATTaxationPurchases(Object.VATTaxation, FillParameters, VATAccountingCachedParameterValues);
	VATAccountingERP.FillInListOfVATTaxChoices(Items.VATTaxation, Object.VATTaxation, FillParameters, VATAccountingCachedParameterValues); 
	
EndProcedure

&AtServer
Procedure FillInTypeOfActivityVAT()
	
	FillParameters = Documents.PurchaseOrder.ParametersForFillingInVATActivityType(Object);
	VATAccountingERP.FillInTypeOfActivityVAT(Object.PurchaseForActivity, FillParameters, VATAccountingCachedParameterValues);
	VATAccountingERP.FillInActivitySelectionList(Items.PurchaseForActivity, Object.PurchaseForActivity, FillParameters, VATAccountingCachedParameterValues);
	
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

&AtClient
Procedure Attachable_CheckTasksToReflectStateOfOrders()
	
	If DocumentsStatesClient.TaskIsBeingCheckedToReflectStateOfOrders(ThisObject) Then
		
		OrderState = ARAPAccountingClientServer.StructureOfStateOfCalculations(False);
		OrderState.Insert("ThereAreDiscrepanciesOfGoodsReceiptNoteAndInvoice", False);
		DocumentsStatesClient.CompleteStructureOfOrderState(OrderState);
		
		FillPropertyValues(OrderState, ThisObject);
		
		CalculateStateOfOrder(Object.Ref, Object.Contract, OrderState, Items.State.Hyperlink);
		
		FillPropertyValues(ThisObject, OrderState);
		
		DocumentsStatesClient.ProcessTaskVerificationResultToReflectStateOfOrders(
			ThisObject,
			OrderState.ThereAreTasksToReflectStateOfOrders,
			"Attachable_CheckTasksToReflectStateOfOrders");
		
	ElsIf DocumentsStatesClient.StartOfTaskVerificationToReflectStateOfOrders(ThisObject) Then
		
		DocumentsStatesClient.SetTaskCheckToReflectStateOfOrdersFlagInProgress(ThisObject);
		
	EndIf;
	
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

&AtServer
Function GetOrganizationSDefaultBankAccountServer()
	
	ParametersOfAccount = CashServer.ParametersForFillingOutOrganizationSBankAccount(Object.Organization);
	ParametersOfAccount.LineOfBusiness = Object.LineOfBusiness;
	ParametersOfAccount.ExcludeCurrencyAccounts = Object.ForeignCurrencyTransaction;
	ParametersOfAccount.Currency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Object.Organization);
	
	Return CashServer.GetOrganizationSDefaultBankAccount(ParametersOfAccount,
		Object.BankAccount, Object.PaymentMethod);
	
EndFunction

&AtServer
Procedure UpdateTextDocumentsBasedOn()
	
	TypesOfOperationsInEAEUCountries = PurchasesServer.BusinessOperationsOnMain(Enums.BusinessTransactions.ImportFromEAEU);
	ThisIsPurchaseOfEAEU = TypesOfOperationsInEAEUCountries.Find(Object.BusinessOperation) <> Undefined;
	
	If ValueIsFilled(Object.Ref) And ThisIsPurchaseOfEAEU Then
		TextDocumentsBasedOn = VATAccountingLocalization.EventDocumentsOnPreliminaryDeliveries(Object, AmountOrderedWithADepositContainer);
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

&AtClient
Procedure OpenAgreement(Item)
	If ValueIsFilled(Object.Terms) Then
		OpenForm("Catalog.TermsOfPurchaseFromVendors.Form.ItemForm", 
		New Structure("Key", Object.Terms));
	EndIf;
EndProcedure

&AtClient
Procedure OpenAContract(Item)
	If ValueIsFilled(Object.Contract) Then
		OpenForm("Catalog.CounterpartyContracts.Form.ItemForm", 
		New Structure("Key", Object.Contract));
	EndIf;
EndProcedure

&AtClient
Procedure Attachable_ProcessObjectEntry()
	
	TMCommonUseClient.ProcessObjectEntryInForm(ThisObject, ParametersForRecording);
	
EndProcedure

&AtClient
Procedure GoodsExpenseItemStartChoice(Item, ChoiceData, StandardProcessing)
	
	IncomeAndExpensesClient.StartArticleSelection(ThisForm, Item, StandardProcessing);
	
EndProcedure

&AtServer
Procedure FillInServiceDetailsForPurposeOfVTCH()
	
	StructureOfActions = New Structure;
 	StructureOfActions.Insert("FillInServiceDetailsForPurpose");
 	BatchProcessingOfTablePartServer.TreatTS(Object.Goods, StructureOfActions, Undefined);
	
EndProcedure

&AtServer
Procedure SetUpWriteOffColumnsForExpensesTSProducts()
	
	TransactionList = New Array;
	TransactionList.Add(Enums.BusinessTransactions.ImportFromEAEUGoodsInTransit);
	TransactionList.Add(Enums.BusinessTransactions.ImportGoodsInTransit);
	TransactionList.Add(Enums.BusinessTransactions.PurchaseFromVendorGoodsInTransit);
	TransactionList.Add(Enums.BusinessTransactions.ImportFromEAEUInvoicedDelivery);
	TransactionList.Add(Enums.BusinessTransactions.PurchaseFromVendorCreatingInvoicesOnGoodsReceipt);
	TransactionList.Add(Enums.BusinessTransactions.ConsignmentProcurement);
	TransactionList.Add(Enums.BusinessTransactions.ReceivingForStorageWithRightOfSale);
	
	ClearExpenseDebitingColumns = TransactionList.Find(Object.BusinessOperation) <> Undefined;
	
	If ClearExpenseDebitingColumns Then
	
		CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
		
		StructureOfActions = New Structure;
		IncomeAndExpensesClientServer.InsertActionClearItemAndExpenseAnalytics(StructureOfActions, ThisObject);
		StructureOfActions.Insert("CheckFillWarehouse", BatchProcessingOfTablePartClientServer.GetWarehouseFillStructureInTSLine(Object, WarehouseGroup_,,,"ToExpenseAs"));
		StructureOfActions.Insert("FillInCheckQualityDateOfQualityConfirmation", CacheQualityControl);
		
		RowsToProcess = New Array();
		
		For Each LineProducts_ In Object.Goods Do
		
			If LineProducts_.ItemsType = PredefinedValue("Enum.ItemsTypes.OwnGoods")
					Or LineProducts_.ItemsType = PredefinedValue("Enum.ItemsTypes.ReusablePackage")
					Or LineProducts_.ItemsType = PredefinedValue("Enum.ItemsTypes.Set")
					Or ValueIsFilled(LineProducts_.Purpose) Then
				LineProducts_.Department = PredefinedValue("Catalog.BusinessStructure.EmptyRef");
				LineProducts_.ToExpenseAs = False;
				RowsToProcess.Add(LineProducts_);
			EndIf;
		
		EndDo;
		
		BatchProcessingOfTablePartServer.ProcessTSStrings(
			RowsToProcess,
			StructureOfActions,
			Object.Goods,
			CachedValues);
			
		For Each LineProducts_ In RowsToProcess Do
			IncomeAndExpensesClientServer.WhenChangingArticleAvailabilityDetailsInLine(
				ThisObject, LineProducts_, "Object.Goods");
		EndDo;
		
	EndIf;
	
EndProcedure

&AtServer
Procedure AdjustItemSelectionSettings()
	
	// Goods.VendorPriceKind
	ChoiceParameterLinks = New Array;
	ChoiceParameterLinks.Add(
			New ChoiceParameterLink(
				"Filter.Owner", "Object.Partner", LinkedValueChangeMode.Clear));
	
	If Object.BusinessOperation <> Enums.BusinessTransactions.ReceivingForStorageWithRightOfSale Then
		
		ChoiceParameterLinks.Add(
			New ChoiceParameterLink(
				"Filter.PriceIncludesVAT", "Object.PriceIncludesVAT", LinkedValueChangeMode.Clear));
		
	EndIf;
	
	Items.GoodsVendorPriceKind.ChoiceParameterLinks = New FixedArray(ChoiceParameterLinks);
	
EndProcedure

&AtServer
// Fills in the Attributes of the "Order" Form for the operation of the links of the parameters for selecting the "Destination" directory."
// See Documents.PurchaseOrder.AssignmentSelectionFormTemplate
Procedure FillOutOrder()
	
	ReferenceOrder = Documents.PurchaseRequest.ApplicationForBasisOfPurchaseOrderToSupplier(Object);
	
EndProcedure

#Region WorkingWithDates

&AtServerNoContext
Function DateAccordingToCompanyCalendar(Val StartDate, Val DaysCount)
	
	Return Documents.PurchaseOrder.DateAccordingToCompanyCalendar(StartDate, DaysCount);
	
EndFunction

&AtServerNoContext
Function DateOfShipmentByCalendar(Val OrderDate, Val DateOfReceipt, Val DeliveryDuration, Val EnterpriseCalendar)
	
	Return Documents.PurchaseOrder.DateOfShipmentByCalendar(OrderDate, DateOfReceipt, DeliveryDuration, EnterpriseCalendar);
	
EndFunction

&AtServerNoContext
Function DeliveryTimeByCalendar(Val StartDate, Val EndDate, Val EnterpriseCalendar)
	
	Return Documents.PurchaseOrder.DeliveryTimeByCalendar(StartDate, EndDate, EnterpriseCalendar);
	
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
	ElsIf Item.Name = "sh_ShamsiInput_RequestedDeliveryDate" Then
		RequestedDeliveryDateOnChange(Items.RequestedDeliveryDate);
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
