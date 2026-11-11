#Region Variables

//used by the mechanism for processing changes in PM details
&AtClient
Var CachedValues;

&AtClient
Var CounterpartyVerificationWaitHandlerParameters Export;

&AtClient
Var TimeConsumingOperationForm Export;

&AtClient
Var ParametersForRecording Export;

#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;

	InfobaseUpdate.CheckObjectProcessed(Object, ThisObject);

	DocumentCorrection.OnCreateAtServer(ThisForm, Items.LineCorrection);

	If PrintFormOpeningIsRequired Then
		Return;
	EndIf;
	
	// Handler of the "Properties" subsystem
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("Object", Object);
	AdditionalParameters.Insert("ItemForPlacementName", "GroupAdditionalAttributes");
	AdditionalParameters.Insert("DeferredInitialization", True);
	PropertyManager.OnCreateAtServer(ThisForm, AdditionalParameters);
	
	TMCommonUse.CustomizePeripherals(ThisForm);
	UseDiscountAdjustmentsInSales               = GetFunctionalOption("UseDiscountAdjustmentsInSales");
	UseDiscountsMarkupsInSales       = GetFunctionalOption("UseDiscountsMarkupsInSales");
	VarianceFromSalesTermsAndConditions                       = UserRightsCached.VarianceFromSalesTermsAndConditions();
	SaleIsNotSubjectToVAT                          = Enums.VATTaxationTypes.SaleIsNotSubjectToVAT;
	UsePartnersAsCounterparties            = GetFunctionalOption("UsePartnersAsCounterparties");
	UseRestrictionsOfManualDiscounts = GetFunctionalOption("UseLimitsForDiscountAdjustmentsInSalesByUsers")
	                                      Or GetFunctionalOption("UseLimitsForDiscountAdjustmentsInSalesByTermsOfSales");
	UseCreditNotes      		= GetFunctionalOption("UseCreditNotes");
	UseSimplifiedPaymentSchemeInSales      = GetFunctionalOption("UseSimplifiedPaymentSchemeInSales");
	UseBusinessUnits                       = GetFunctionalOption("UseBusinessUnits");
	
	UseLoyaltyPrograms = UseLoyaltyPrograms(Object.LoyaltyCard);
	SetVisibilityOfElementsOfLoyaltyBonusProgram();
	
	// Handler of the "Versioning of objects" mechanism
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	
	If Not ValueIsFilled(Object.Ref) Then
		OnReadCreateAtServer();
	EndIf;

	SetConditionalAppearance();
	
	SalesServer.SetBlankContractMark(Items, "Contract");
	
	If UseCustomerInvoicesForSeveralOrders Then
		TMCommonUseClientServer.SetFormItemProperty(Items, "ServicesSelectServicesFromOrder", "Title", NStr("vi = 'Chọn dịch vụ từ đơn hàng';
																											|ru = 'Подобрать услуги из заказов';
																											|en = 'Pick services from orders'; fa = 'Pick services from orders';
																											|it = 'Selezionare servizi dagli ordini';
																											|pl = 'Dobierz usługi z zamówień';
																											|tr = 'Siparişlerden hizmet seçme'"));
		TMCommonUseClientServer.SetFormItemProperty(Items, "ServicesFillInFromOrder", "Title", NStr("vi = 'Điền theo đơn hàng';
																									|ru = 'Заполнить по заказам';
																									|en = 'Fill in from orders'; fa = 'Fill in from orders';
																									|it = 'Compilare per ordini';
																									|pl = 'Wypełniej według zamówień';
																									|tr = 'Siparişlere ilişkin doldur'"));
	EndIf;
	
	If Not UseBusinessUnits Then
		Items.ServicesDepartment.Visible = False;
	Else
		Items.ServicesDepartment.Title = NStr("vi = 'Bộ phận gửi';
												|ru = 'Подразделение-отправитель';
												|en = 'Shipping business unit'; fa = 'واحد تجاری ارسال‌کننده';
												|it = 'Unità-mittente';
												|pl = 'Shipping business unit';
												|tr = 'Gönderen departman'");
	EndIf;
	
	If ClientApplication.CurrentInterfaceVariant() = ClientApplicationInterfaceVariant.Version8_2 Then
		Items.GroupInTotal.BackColor = New Color();
	EndIf;
	
	ReadPriceTypeRight = AccessRight("View", Metadata.Documents.CustomerInvoiceServices.TabularSections.Services.Attributes.PriceKind);

	Items.ServicesPriceKind.QuickChoice = Not GetFunctionalOption("UseSeveralPriceTypes");
	
	DiscountsMarkupsFillingServer.ConfigureShowMessagesCommand(Object, Items.ShowMessages);
	
	SetAvailabilityOfClipboardCommands();
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject);
	// End IntegrationWith1CDocumentManagementSubsystem
	
	
	Items.DecorationEDOState.Visible = GetFunctionalOption("UseElectronicDocumentExchangeWithCounterparties");
	


	
	UpdateFlagThereAreAdjustments();
	
	ARAPAccountingFormWork.FormWhenCreatedOnServer(ThisForm);
	
	GeneratingFiscalChecksServer.FormWhenCreatedOnServer(ThisObject);
	
	
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);

	// StandardSubsystems.FilesOperations
	HyperlinkParameters = FilesOperations.FilesHyperlink();
	HyperlinkParameters.Location = "CommandBar";
	FilesOperations.OnCreateAtServer(ThisObject, HyperlinkParameters);
	// End StandardSubsystems.FilesOperations

	// Standard subsystems.Accounting of the originals of the first documents
	SourceDocumentsOriginalsRecording.OnCreateAtServerDocumentForm(ThisObject);
	// The end of the standard subsystem.Accounting of the originals of the first documents
	
	AddSBPPaymentStatusUpdateCommand();
	
	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	If PrintFormOpeningIsRequired Then
		
		Cancel = True;
		SelfServiceClient.PrintCertificateOfCompletedWorks(Object.Ref);
		Return;
		
	EndIf;
	
	// StandardSubsystems.Properties
	PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
	// End StandardSubsystems.Properties
	
	EquipmentManagerClient.StartConnectingDevicesWhenYouOpenForm(Undefined, ThisForm, "BarcodeScanner");
	
	If Object.InvoiceByOrders Then
		
		ItemArray = New Array();
		ItemArray.Add("CopyServices");
		ItemArray.Add("CopyContextMenuServices");
		TMCommonUseClientServer.SetPropertyOfFormElements(Items, ItemArray, "Enabled", False);
		
	EndIf;
	
	
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// The end of the standard subsystem.Pluggable commands
	// Standard subsystems.Worksfiles
	FilesOperationsClient.OnOpen(ThisObject, Cancel);
	// End StandardSubsystems.FilesOperations
	
	CashClientLocalization.AttachablePaymentVerificationViaServices(ThisObject, Object.Ref, Object.Counterparty);
	
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)

	// StandardSubsystems.AccessManagement
	AccessManagement.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.AccessManagement
	
	If TMCommonUseClientServer.AnExternalUserIsAuthorized() Then
		PrintFormOpeningIsRequired = True;
		Return;
	EndIf;
	
	// Handler of the "Date-change" mechanism
	PeriodClosingDates.ObjectOnReadAtServer(ThisForm, CurrentObject);
	
	OnReadCreateAtServer();
	
	PropertyManager.OnReadAtServer(ThisForm, CurrentObject);

	FormEvents.OnReadAtServer(ThisObject, CurrentObject);
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	// End StandardSubsystems.AttachableCommands

	
	ARAPAccountingFormWork.FormWhenReadingOnServer(ThisForm);
	
	DocumentCorrection.OnReadAtServer(ThisForm, Items.LineCorrection);

	GeneratingFiscalChecksServer.FormWhenReadingOnServer(ThisObject);
	
EndProcedure
 
&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	
	// StandardSubsystems.Properties
	PropertyManager.FillCheckProcessing(ThisForm, Cancel, CheckedAttributes);
	// End StandardSubsystems.Properties
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)
	
	// StandardSubsystems.AccessManagement
	AccessManagement.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	// End StandardSubsystems.AccessManagement
	
	SetAvailabilityOfItemsByStatusServer();
	
	FillInServiceDetailsForProductRange();
	


	
	ARAPAccountingFormWork.FormAfterRecordingOnServer(ThisForm, CurrentObject.AdditionalProperties);

	LinesOfBusinessServer.AfterWriteAtServer(ThisObject);
	
	ProvisionInDocumentsServer.CheckToRunBackgroundInventoryAllocationJob();
	
	ConfigurationModificationOverridable.AfterWriteAtServer(ThisForm, CurrentObject, WriteParameters);
	
	GeneratingFiscalChecksServer.FormWhenChangingBankingDetails(ThisObject);
	
	FormEvents.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, StandardProcessing)
	
	ForceCloseTheForm = True;
	
EndProcedure

&AtClient
Procedure OnClose()
	
	EquipmentManagerClient.StartDisablingHardwareWhenClosingForm(Undefined, ThisForm);
	CashClientLocalization.DisablePaymentVerificationViaServices(ThisObject);
	
EndProcedure

&AtClient
Procedure BeforeWrite(Cancel, WriteParameters)
	
	FormEventsClient.BeforeWrite(ThisObject, Cancel, WriteParameters);
	
	// If the document is carried out, we will calculate discounts
	
	If NotExecuteCheck1BeforeWrite Then
		NotExecuteCheck1BeforeWrite = False;
		Return;
	EndIf;
	
	If WriteParameters.WriteMode = DocumentWriteMode.Posting Then
		
		If UseDiscountsMarkupsInSales Then
			
			If Not Object.DiscountsAreCalculated And DiscountsHaveChanged() Then
				
					Cancel = True;
					
					AdditionalParameters = New Structure;
					AdditionalParameters.Insert("WriteParameters", WriteParameters);
					AdditionalParameters.Insert("ThisObject", ThisObject);
					DiscountsMarkupsFillingClient.SuggestUserToCalculateDiscounts(
						New CallbackDescription(
							"SuggestUserToCalculateDiscountsCompletion", 
							ThisObject,
							AdditionalParameters)
						);
					
			Else
				Object.DiscountsAreCalculated = True;
			EndIf;
			
		EndIf;
		
		If Not Cancel Then
			BeforeWriteAtClientServer();
		EndIf;
		
	EndIf;
	
	TMCommonUseClient.RecordObjectIfNecessary(ThisObject, WriteParameters, Cancel);
	
EndProcedure

&AtServer
Function DiscountsHaveChanged()
	
	DiscountsHaveChanged = DiscountsMarkupsFillingServer.DiscountsMustBeRecalculated(
		Object, 
		ManagedDiscounts, 
		UUID, 
		AddressOfAppliedDiscountsInTheTemporaryStorage);
		
	If Object.Services.Total("DiscountMarkupAmount") <> Object.DiscountsMarkups.Total("Sum") Then
		DiscountsHaveChanged = True;
	EndIf;
	
	Return DiscountsHaveChanged;
	
EndFunction

&AtClient
Procedure Attachable_ProcessObjectEntry()
	
	TMCommonUseClient.ProcessObjectEntryInForm(ThisObject, ParametersForRecording);
	
EndProcedure

&AtClient
Procedure SuggestUserToCalculateDiscountsCompletion(UserAnswer, AdditionalParameters) Export
	
	Cancel = False;
	
	If UserAnswer = DialogReturnCode.OK Then
		Cancel = False;
		ApplyDiscountMarkUpChangesOnCustomer(Cancel);
		CalculateFinalIndicatorsOfActsOfWorkPerformed(ThisObject);
	Else
		Return;
	EndIf;
	
	BeforeWriteAtClientServer();
	
	TMCommonUseClient.RecordObjectIfNecessary(ThisObject, AdditionalParameters.WriteParameters,,True);
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	// Subsystem "Properties"
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
	
	
	
	If EventName = "Write_InvoiceIssued"
		And ((Parameter.Property("OwnerForm") And Parameter.OwnerForm = UUID)
			Or Parameter.Property("ListOfGrounds") And Parameter.ListOfGrounds.FindByValue(Object.Ref) <> Undefined) Then
		UpdateTextOfInvoiceIssued();
	EndIf;
	
	If EventName = "Write_SaleAdjustment"
		And TypeOf(Parameter) = Type("Structure")
		And Parameter.Property("DocumentBasis")
		And Parameter.DocumentBasis = Object.Ref Then
		Recording_AdjustingImplementationOnServer();
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
	
	DocumentCorrectionClient.NotificationProcessing(ThisObject, EventName, Parameter, Source);
	
	HandlingFragmentAlerts(EventName, Parameter);
	
	FormEventsClient.NotificationProcessing(ThisObject, EventName, Parameter, Source);
	
	SetVisibilityOfPartnerField(ThisObject);
	
	// StandardSubsystems.FilesOperations
	FilesOperationsClient.NotificationProcessing(ThisObject, EventName);
	// End StandardSubsystems.FilesOperations

	// StandardSubsystems.SourceDocumentsOriginalsRecording	
	SourceDocumentsOriginalsRecordingClient.NotificationHandlerDocumentForm(EventName,ThisObject);
	// End StandardSubsystems.SourceDocumentsOriginalsRecording
	
EndProcedure

&AtServer
Procedure PaymentCreditedServer(EventName, Parameter, Source)
	
	ARAPAccountingFormWork.NotificationProcessing(ThisForm, EventName, Parameter);
	
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
		DiscountsMarkupsFillingClient.ResetDiscountsCalculatedFlag(ThisObject);
    EndIf;
    
    If EventName = "EditSet"
        And Parameter.OwnerForm = UUID Then
        
        ArrayOfProductTypes = New Array;
        ArrayOfProductTypes.Add(PredefinedValue("Enum.ItemsTypes.OperationService"));
        ArrayOfProductTypes.Add(PredefinedValue("Enum.ItemsTypes.Work_5"));
        ArrayOfProductTypes.Add(PredefinedValue("Enum.ItemsTypes.Set"));
        
        SetParameters = New Structure;
        SetParameters.Insert("ProductsInSet", Parameter.ProductsInSet);
        SetParameters.Insert("ItemVariantOfSet", Parameter.ItemVariantOfSet);
        SetParameters.Insert("ExceedingOrder", True);
        SetParameters.Insert("DialColumns", DialColumns(ThisForm));
        
        SetAddressInTemporaryStorage = SetAddressInTemporaryStorage(SetParameters);
        
        OpeningParameters = New Structure;
        OpeningParameters.Insert("AddressInTempStorage", SetAddressInTemporaryStorage);
        OpeningParameters.Insert("ProductsInSet",   Parameter.ProductsInSet);
        OpeningParameters.Insert("ItemVariantOfSet", Parameter.ItemVariantOfSet);
        OpeningParameters.Insert("PriceIncludesVAT", Object.PriceIncludesVAT);
        OpeningParameters.Insert("VATTaxation", Object.VATTaxation);
        OpeningParameters.Insert("Currency", Object.Currency);
        OpeningParameters.Insert("Terms", Object.Terms);
        OpeningParameters.Insert("Date", Object.Date);
        OpeningParameters.Insert("Ref", Object.Ref);
        OpeningParameters.Insert("FilterByProductType", ArrayOfProductTypes);
        OpeningParameters.Insert("HideCommandRemainingQuantityInWarehouses", True);
        OpeningParameters.Insert("Organization", Object.Organization);
        
        OpenForm("DataProcessor.EditSet.Form.Form", OpeningParameters, ThisForm, UUID);
        
    EndIf;

EndProcedure

&AtClient
Procedure ChoiceProcessing(ValueSelected, ChoiceSource)
	
	If ChoiceSource.FormName = "Document.CustomerInvoiceServices.Form.SelectionFormOfServicesFromOrder" Then
		
		GetServicesFromStorage(ValueSelected.GoodsAddressInStorage);
		
	ElsIf ChoiceSource.FormName = "DataProcessor.SelectGoodsToSalesDocument.Form.Form" Then
		
		HandlingSelectionSelectionOnClient(ValueSelected);
		
	ElsIf VATAccountingERPClient.FinishedEditingInvoiceIssued(ValueSelected, ChoiceSource) Then
		
		UpdateTextOfInvoiceIssued();
		
	
	ElsIf ChoiceSource.FormName = "Catalog.BusinessStructure.Form.ChoiceForm" Then
		
		SalesClient.ProcessingUnitSelection(Object.Services, Items.Services.SelectedRows, ValueSelected);
	
	ElsIf ChoiceSource.FormName = "CommonForm.PrintingDetailsOfSales" Then
		
		If ValueSelected <> Undefined Then
			Modified = True;
			FillPropertyValues(Object, ValueSelected);
		EndIf;
		
	ElsIf ChoiceSource.FormName = "Catalog.InventoryKinds.Form.InventoryOwnerAttributesForm" Then	
		
		GetStockTypesFromStorage(ValueSelected);
		
	EndIf;
	
	If Window <> Undefined Then
		Window.Activate();
	EndIf;
	
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	
	Notify("Write_CustomerInvoiceServices", WriteParameters, Object.Ref);
	ARAPAccountingClient.FormAfterRecording(ThisForm);
	
	
	ConfigurationModificationClientOverridable.AfterWrite(ThisForm, WriteParameters);
	
	TMCommonUseClient.PerformActionsAfterRecording(ThisForm, Object, WriteParameters);
	
	// StandardSubsystems.AttachableCommands
	If CommonClient.SubsystemExists("StandardSubsystems.AttachableCommands") Then
		ModuleAttachableCommandsClient = CommonClient.CommonModule("AttachableCommandsClient");
		ModuleAttachableCommandsClient.AfterWrite(ThisObject, Object, WriteParameters);
	EndIf;
	// End StandardSubsystems.AttachableCommands
	
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
Procedure OnWriteAtServer(Cancel, CurrentObject, WriteParameters)
	

EndProcedure

&AtClient
Procedure TermsStartChoice(Item, ChoiceData, StandardProcessing)
	
	AgreementSelectionParameters = SalesClient.ParametersForStartingSelectionOfAgreementWithClient();
	
	AgreementSelectionParameters.Item                     = Item;
	AgreementSelectionParameters.Partner                     = Object.Partner;
	AgreementSelectionParameters.Document                    = Object.Terms;
	AgreementSelectionParameters.DocumentDate               = Object.Date;
	AgreementSelectionParameters.BusinessOperation       = PredefinedValue("Enum.BusinessTransactions.SaleToCustomer");
	AgreementSelectionParameters.FormDataStructure        = Object;
	
	SalesClient.StartSelectingAgreementWithClient(AgreementSelectionParameters, StandardProcessing);
	
EndProcedure

&AtClient
Procedure PartnerOnChange(Item)
	
	If Not ValueIsFilled (Object.Partner) Then
		SetVisibilityOfShipmentBanToPartner();
		Return;
	EndIf;
	
	PartnerOnChangeServer();
	
	DiscountsMarkupsFillingClient.ResetDiscountsCalculatedFlag(ThisObject);
	
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
	
	DiscountsMarkupsFillingClient.ResetDiscountsCalculatedFlag(ThisObject);
	
	If ToUseTermsOfSales And ValueIsFilled(Object.Terms) Then
		SalesClient.NotifyEndOfFillingInDefaultSalesConditions();
	EndIf;
	
EndProcedure

&AtClient
Procedure TermsOnChange(Item)
	
	ClearMessages();
	
	If Not ValueIsFilled (Object.Terms) Then
		TermsClearingServer();
		Return;
	EndIf;
	
	ContractBeforeModifications = Object.Contract;
	DiscountsMarkupsFillingClient.ResetDiscountsCalculatedFlag(ThisObject);
	
	TermsOnChangeServer();


	
	SalesClient.NotifyEndOfFillingInTermsOfSale();
	
EndProcedure

&AtClient
Procedure ContractOnChange(Item)
	
	ClearMessages();
	
	If Object.InvoiceByOrders And Contract <> Object.Contract And Not OrdersAreUsedAsInvoices() Then
		
		UnlinkFromOrder = False;
		AnswersOptions = New ValueList;
		
		AnswersOptions.Add("UnlinkFromOrder", NStr("ru = 'Отвязать от заказа';
													|vi = 'Unlink from order';
													|en = 'Unlink from order'; fa = 'جدا کردن از سفارش';
													|it = 'Scollegare dall''ordine';
													|pl = 'Odłącz od zamówienia';
													|tr = 'Siparişten ayır'"));
		AnswersOptions.Add("Cancel", NStr("ru = 'Отмена';
											|vi = 'Cancel';
											|en = 'Cancel'; fa = 'انصراف';
											|it = 'Cancel';
											|pl = 'Cancel';
											|tr = 'İptal'"));
		QueryText = NStr("ru = 'При изменении договора документ будет отвязан от заказа. Продолжить?';
						|vi = 'If you change the contract, the document will be unlinked from the order. Continue?';
						|en = 'If you change the contract, the document will be unlinked from the order. Continue?'; fa = 'If you change the contract, the document will be unlinked from the order. Continue?';
						|it = 'If you change the contract, the document will be unlinked from the order. Continue?';
						|pl = 'If you change the contract, the document will be unlinked from the order. Continue?';
						|tr = 'Sözleşme değiştirildiğinde belge siparişten ayrılacaktır. Devam edilsin mi?'");
			
		ShowQueryBox(
			New CallbackDescription("ContractOnChangeCompletion",
				ThisObject,
				New Structure("UnlinkFromOrder", UnlinkFromOrder)),
			QueryText,
			AnswersOptions);
		
	Else
	
		ContractOnChangeServer();
		
		If ValueIsFilled(Object.Contract) Then
			
		
		EndIf;
	
	EndIf;
	
EndProcedure

&AtClient
Procedure ContractOnChangeCompletion(QuestionResult, AdditionalParameters) Export 
	
	If QuestionResult = "Cancel" Then
		
		Object.Contract = Contract;
		
	ElsIf QuestionResult = "UnlinkFromOrder" Then
		
		Object.InvoiceByOrders = False;
		WhenChangingCertificatesOfCompletedWorksForSeveralOrders();
		
	EndIf;

	ContractOnChangeServer();

	
EndProcedure

&AtClient
Procedure VATTaxationOnChange(Item)
	
	ClearMessages();
	
	VATTaxationOnChangeServer();
	DiscountsMarkupsFillingClient.ResetDiscountsCalculatedFlag(ThisObject);
	
EndProcedure

&AtClient
Procedure PriceIncludesVATOnChange(Item)
	
	PriceIncludesVATOnChangeServer(CachedValues);	
	DiscountsMarkupsFillingClient.ResetDiscountsCalculatedFlag(ThisObject);
	
EndProcedure

&AtServerNoContext
Function ParametersForRegisteringInvoicesIssuedServer(Val Object)
	
	Return Documents.CustomerInvoiceServices.ParametersForRegisteringInvoicesIssued(Object);
	
EndFunction	

&AtClient
Procedure TextOfTheInvoiceIssuedURLProcessing(Item, Var_URL, StandardProcessing)
	
	RegistrationParameters = ParametersForRegisteringInvoicesIssuedServer(Object);
	VATAccountingERPClient.ProcessingNavigationLinkInvoicesIssued(ThisForm, Var_URL,  StandardProcessing, RegistrationParameters);
	
	FiscalOperationNavigationLinkProcessing(Item, Var_URL, StandardProcessing);
	
EndProcedure

&AtClient
Procedure DateOnChange(Item)
	
	Var PricesCalculated;
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	
	ClearMessages();
	
	DiscountsMarkupsFillingClient.ResetDiscountsCalculatedFlag(ThisObject);
	
	If Not Object.InvoiceByOrders Then
		Notification = New CallbackDescription("DateOnChangeCompletion", ThisObject);
		EnterprisePricesFillingClient.AskQuestionAboutRecalculatingPriceWhenDateChanges(Object, Notification, "Services");
		Return;
 	EndIf; 
	
 	RecalculatePrices_ = False;
 	DateOnChangeServer(RecalculatePrices_, PricesCalculated);
	
 	If RecalculatePrices_ Then
		PurchasesClient.NotifyAboutEndOfFillingInPricesUnderAgreement(PricesCalculated);
	EndIf;
	
	
EndProcedure

&AtClient
Procedure DateOnChangeCompletion(QuestionResult, AdditionalParameters) Export 
	
	Var PricesCalculated;
	
	If Not QuestionResult = DialogReturnCode.Cancel Then
		DateOnChangeServer(QuestionResult, PricesCalculated, QuestionResult);
	EndIf;
	
	If QuestionResult = True Then
		PurchasesClient.NotifyAboutEndOfFillingInPricesUnderAgreement(PricesCalculated);
	EndIf;
	
EndProcedure

&AtClient
Procedure OrganizationOnChange(Item)
	
	ClearMessages();
	
	OrganizationOnChangeServer();
	DiscountsMarkupsFillingClient.ResetDiscountsCalculatedFlag(ThisObject);
	
	
EndProcedure

&AtClient
Procedure CounterpartyOnChange(Item)
	
	CounterpartyOnChangeServer();
	
	


	
EndProcedure

&AtClient
Procedure ManagerOnChange(Item)
	
	FillInSubordinatePropertiesForStatistics("Manager");
	
	DiscountsMarkupsFillingClient.ResetDiscountsCalculatedFlag(ThisObject);
	
EndProcedure

&AtClient
Procedure AcceptanceNoteForOrdersOnChange(Item)
	
	SalesOrder = Undefined;
	ClearMessages();
	If Object.InvoiceByOrders Then
		
		If UseCustomerInvoicesForSeveralOrders Then
		
			If Object.Services.Count() = 0 Then
				QueryText = NStr("vi = 'Danh sách Dịch vụ sẽ được bổ sung bằng hàng tồn dịch vụ chưa được cung cấp theo đơn hàng. Tiếp tục?';
								|ru = 'Список Услуги будет перезаполнен остатками неоказанных услуг по заказам. Продолжить?';
								|en = 'List Services will be refilled with non-provided services by orders. Continue?'; fa = 'List Services will be refilled with non-provided services by orders. Continue?';
								|it = 'L''elenco Servizi sarà ricompilato con residui di servizi non erogati per gli ordini. Continuare?';
								|pl = 'Lista Usługi będzie wypełniona ponownie ostatkami nie udzielonych usług według zamówień. Kontynuować?';
								|tr = 'Hizmetler listesi siparişlere ilişkin sunulmayan hizmet bakiyeleri ile yeniden doldurulacaktır. Devam edilsin mi?'");
			Else
				QueryText = NStr("vi = 'Dòng trong danh sách Dịch vụ có rằng buộc với dòng trong đơn hàng. Dòng mà không thể rằng buộc với dòng trong đơn hàng sẽ bị xóa bỏ.  Tiếp tục?';
								|ru = 'Строки в списке Услуги будут привязаны к строкам заказов. Строки, которые невозможно привязать к строкам заказа, будут удалены. Продолжить?';
								|en = 'Lines in the Services list will be linked to order lines. Lines that cannot be linked to order lines will be deleted. Continue?'; fa = 'Lines in the Services list will be linked to order lines. Lines that cannot be linked to order lines will be deleted. Continue?';
								|it = 'Le righe nell''elenco Servizi verranno associate alle righe dell''ordine. Le righe che non possono essere associate alle righe dell''ordine verranno eliminate. Continuare?';
								|pl = 'Wiersze na liście Usługi zostaną przywiązane do wierszy zamówień. Wiersze, które jest niemożliwe przywiązać do wierszy zamówienia, zostaną usunięte. Kontynuować?';
								|tr = 'Hizmetler listesindeki satırlar sipariş satırlarıyla eşleştirilecektir. Sipariş satırlarına bağlanamayan satırlar silinecektir. Devam edilsin mi?'");
			EndIf;
			
		Else
			
			FilterParameters = New Structure();
			FilterParameters.Insert("Currency",                Object.Currency);
			FilterParameters.Insert("Counterparty",            Object.Counterparty);
			FilterParameters.Insert("Contract",               Object.Contract);
			FilterParameters.Insert("VATTaxation",    Object.VATTaxation);
			FilterParameters.Insert("Organization",           Object.Organization);
			FilterParameters.Insert("Partner",               Object.Partner);
			FilterParameters.Insert("Terms",            Object.Terms);
			FilterParameters.Insert("PriceIncludesVAT",       Object.PriceIncludesVAT);
			FilterParameters.Insert("SalesOpportunity",                Object.SalesOpportunity);
			FilterParameters.Insert("LineOfBusiness", Object.LineOfBusiness);
			
			OpenForm(
				"Document.CustomerInvoiceServices.Form.ReferenceChoiceForm",
				New Structure("Filter,Recorder", FilterParameters, Object.Ref),,,,, New CallbackDescription("ReportOfCompletedWorkOnOrdersWhenChangingAfterSelection", ThisObject), FormWindowOpeningMode.LockOwnerWindow);
            Return;
			
		EndIf;
	Else
		
		If Object.Services.Count() > 0 Then
			
			If UseCustomerInvoicesForSeveralOrders Then
				QueryText = NStr("vi = 'Dòng trong danh sách Dịch vụ không còn liên kết với dòng trong đơn hàng. Tiếp tục?';
								|ru = 'Строки в списке Услуги перестанут быть связанными со строками заказов. Продолжить?';
								|en = 'Lines in the Services list will not be associated with lines in the orders. Continue?'; fa = 'Lines in the Services list will not be associated with lines in the orders. Continue?';
								|it = 'Le righe nell''elenco Servizi non saranno più associate alle righe degli ordini. Continuare?';
								|pl = 'Wiersze na liście Usługi nie będą więcej powiązane z wierszami zamówień. Kontynuować?';
								|tr = 'Hizmetler listesindeki satırlar artık sipariş satırlarıyla ilişkilendirilmeyecektir. Devam edilsin mi?'");
			Else
				QueryText = NStr("vi = 'Dòng trong danh sách Dịch vụ không còn liên kết với dòng trong đơn hàng. Tiếp tục?';
								|ru = 'Строки в списке Услуги перестанут быть связанными со строками заказа. Продолжить?';
								|en = 'Lines in the Services list will not be associated with order lines. Continue?'; fa = 'Lines in the Services list will not be associated with order lines. Continue?';
								|it = 'Le righe nell''elenco Servizi non saranno più associate alle righe dell''ordine. Continuare?';
								|pl = 'Wiersze na liście Usługi nie będą więcej powiązane z wierszami zamówienia. Kontynuować?';
								|tr = 'Hizmetler listesindeki satırlar artık sipariş satırlarıyla ilişkilendirilmeyecektir. Devam edilsin mi?'");
			EndIf;
			
		Else
			
			WhenChangingCertificatesOfCompletedWorksForSeveralOrders();
			Return;
			
		EndIf;
		
	EndIf;
	
	ReportOfCompletedWorkOnOrdersWhenChangingFragment(SalesOrder, QueryText);
EndProcedure

&AtClient
Procedure ReportOfCompletedWorkOnOrdersWhenChangingAfterSelection(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		Object.InvoiceByOrders = False;
		Return;
	EndIf;
	
	SalesOrder = Result.SalesOrder;
	
	If Object.Services.Count() = 0 Then
		QueryText = StrReplace(NStr(
			"vi = 'Danh sách Dịch vụ sẽ được bổ sung bằng hàng tồn dịch vụ chưa được thực hiện theo chứng từ %SalesOrder%. Tiếp tục?';
			|ru = 'Список Услуги будет перезаполнен остатками неоформленных услуг по документу %SalesOrder%. Продолжить?';
			|en = 'List Services will be refilled with non-generated services by document %SalesOrder%. Continue?'; fa = 'List Services will be refilled with non-generated services by document %SalesOrder%. Continue?';
			|it = 'L''elenco Servizi sarà ricompilato con residui di servizi non erogati per il documento %SalesOrder%. Continuare?';
			|pl = 'Lista Usługi będzie wypełniona ponownie ostatkami niesporządzonych towarów według dokumentu %SalesOrder%. Kontynuować?';
			|tr = 'Hizmetler listesi %SalesOrder% belgesine göre işlenmemiş hizmetlerin bakiyeleri ile yeniden doldurulacaktır. Devam edilsin mi?'"),
			"%SalesOrder%", SalesOrder);
	Else
		QueryText = StrReplace(NStr(
			"vi = 'Dòng trong danh sách Dịch vụ có rằng buộc với dòng trong chứng từ %SalesOrder%. Dòng mà không thể rằng buộc với dòng trong đơn hàng sẽ bị xóa bỏ.  Tiếp tục?';
			|ru = 'Строки в списке Услуги будут привязаны к строкам документа %SalesOrder%. Строки, которые невозможно привязать к строкам заказа, будут удалены.  Продолжить?';
			|en = 'Lines in list Services will be linked to lines of document %SalesOrder%. Lines that cannot be linked will be deleted. Continue?'; fa = 'Lines in list Services will be linked to lines of document %SalesOrder%. Lines that cannot be linked will be deleted. Continue?';
			|it = 'Le righe nell''elenco Servizi verranno associate alle righe dell''ordine %SalesOrder%. Le righe che non possono essere associate alle righe dell''ordine verranno eliminate. Continuare?';
			|pl = 'Wiersze na liście Usługi zostaną związane z wierszami dokumentu %SalesOrder%. Wiersze, których nie można związać z wierszami zamówienia, zostaną usunięte. Kontynuować?';
			|tr = 'Hizmetler listesindeki satırlar %SalesOrder% belgesinin satırlarına bağlanacaktır. Sipariş satırlarına bağlanamayan satırlar silinecektir.  Devam edilsin mi?'"),
			"%SalesOrder%", SalesOrder);
	EndIf;
	ReportOfCompletedWorkOnOrdersWhenChangingFragment(Result, QueryText);
	
EndProcedure

&AtClient
Procedure ReportOfCompletedWorkOnOrdersWhenChangingFragment(Val Result, Val QueryText)
	
	If TypeOf(Result) <> Type("Structure") Then
		Result = New Structure("SalesOrder", Result);
	EndIf;
	
	ShowQueryBox(New CallbackDescription("AcceptanceNoteForOrdersOnChangeCompletion", ThisObject, Result), QueryText, QuestionDialogMode.YesNo);
	
EndProcedure

&AtClient
Procedure AcceptanceNoteForOrdersOnChangeCompletion(QuestionResult, AdditionalParameters) Export
	
	SalesOrder = AdditionalParameters.SalesOrder;
	UserAnswer = QuestionResult;
	If UserAnswer = DialogReturnCode.No Then
		Object.InvoiceByOrders = Not Object.InvoiceByOrders;
		Return;
	EndIf;
	
	If ValueIsFilled(SalesOrder) Then
		Object.SalesOrder = SalesOrder;
		If AdditionalParameters.Property("ARAPObjectSettings") Then
			Object.ARAPObjectSettings = AdditionalParameters.ARAPObjectSettings;
		EndIf;
	EndIf;
	
	WhenChangingCertificatesOfCompletedWorksForSeveralOrders();
	SetAvailabilityOfClipboardCommandsOnClient();
	
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
			
			DiscountsMarkupsFillingClient.ResetDiscountsCalculatedFlag(ThisObject);
			Modified = True;
			
			If Object.LoyaltyCard <> LoyaltyCard Then
				ApplyPaymentWithBonusPoints(Undefined);
			EndIf;
			
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
		
		DiscountsMarkupsFillingClient.ResetDiscountsCalculatedFlag(ThisObject);
		Modified = True;
		Object.LoyaltyCard   = LoyaltyCard;
		LoyaltyCardReadOnServer(LoyaltyCardDetails);
		
	Else
		
		UseLoyaltyPrograms = UseLoyaltyPrograms(Undefined);
		ApplyPaymentWithBonusPointsClient();
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
		
		DiscountsMarkupsFillingClient.ResetDiscountsCalculatedFlag(ThisObject);
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
Procedure TextAllowedCreditBalanceClick(Item, StandardProcessing)
	
	ARAPAccountingClient.DebtLimitsClick(ThisForm, Item, StandardProcessing);
	
EndProcedure

&AtClient
Procedure TextShippingToAPartnerIsProhibitedClick(Item)
	OpenForm("Catalog.Partners.Form.FormOfSegmentsOfShipmentProhibition", New Structure("Partner", Object.Partner));
EndProcedure

&AtClient
Procedure LabelPaymentStagesClick(Item, StandardProcessing)

	Notification = New CallbackDescription("LabelPaymentStagesClickCompletion", ThisObject);
	PlacePaymentStepsInTemporaryStorage(Item.Name);
	ARAPAccountingClient.LabelPaymentStagesClick(ThisForm, Item, StandardProcessing, Notification);
	
EndProcedure

&AtServer
Procedure PlacePaymentStepsInTemporaryStorage(TagName)
	PaymentStepsServer.PlacePaymentStepsInTemporaryStorage(ThisForm, TagName);
	ARAPAccountingFormWork.PlacePaymentDecryptionInTemporaryStorage(ThisForm, TagName);
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
			
			Object.Approved                = False;
			If ChangedBankingDetails.Property("PaymentMethod") Then
				DiscountsMarkupsFillingClient.ResetDiscountsCalculatedFlag(ThisObject);
			EndIf;
		
		EndIf;
		
	EndIf;
	
	CalculateFinalIndicatorsOfActsOfWorkPerformed(ThisObject);
	
EndProcedure

&AtClient
Procedure LineOfBusinessOnChange(Item)
	
	LineOfBusinessOnChangeServer();
	
EndProcedure

&AtClient
Procedure LabelCurrenciesClick(Item, StandardProcessing)
	
	Notification = New CallbackDescription("LabelCurrenciesClickCompletion", ThisObject);
	ARAPAccountingClient.CurrencyAndExchangeRateOfDocument(ThisForm, Item, StandardProcessing, Notification);
	
EndProcedure

&AtClient
Procedure Attachable_OriginalStateDecorationClick()

	// StandardSubsystems.SourceDocumentsOriginalsRecording
	SourceDocumentsOriginalsRecordingClient.OpenStateSelectionMenu(ThisForm,Items.OriginalStateDecoration);
	//End StandardSubsystems.SourceDocumentsOriginalsRecording

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
	
	If CurrentPage.Name = "MainGroup3" Then
		ARAPAccountingClient.UpdateHyperlinkTextPaymentSteps(ThisForm);
		ARAPAccountingClientServer.UpdateHyperlinkText(ThisForm);
	EndIf;
	
EndProcedure

&AtClient
Procedure Decorationedonage(Item, StandardProcessing)
	
	
EndProcedure

&AtClient
Procedure LabelCurrenciesClickCompletion(ClosingResult, AdditionalParameters) Export
	
	If ClosingResult = Undefined Then 
		Return;
	EndIf;
	
	If TypeOf(ClosingResult) = Type("Structure") Then
		
		ChangedBankingDetails = ClosingResult.OldValuesOfChangedProps;
		
		If ChangedBankingDetails.Count() > 0 Then
			
			LabelCurrenciesClickCompletionServer(ClosingResult);
			
			If ClosingResult.RecalculateDocumentAmounts Then
				PriceManagementSystemClient.NotifyAboutEndOfConversionOfAmountsIntoCurrency(DocumentCurrency, Object.Currency);
			EndIf;
			
			If ChangedBankingDetails.Property("ARAPCurrency") Then
				DiscountsMarkupsFillingClient.ResetDiscountsCalculatedFlag(ThisObject);
			EndIf;
			
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure LineCorrectionURLProcessing(Item, FormattedStringURL, StandardProcessing)
	
	DocumentCorrectionClient.StringFixHandlingNavigationLinks(
		ThisObject, FormattedStringURL, StandardProcessing);
	
EndProcedure

&AtServer
Procedure LabelCurrenciesClickCompletionServer(ClosingResult)
	
	ChangedBankingDetails = ClosingResult.OldValuesOfChangedProps;
	
	If ClosingResult.RecalculateDocumentAmounts Then
		DocumentAmountOnChangeServer(ClosingResult.DocumentAmount);
	EndIf;
	If ChangedBankingDetails.Property("Currency") Then
		DocumentCurrency = Object.Currency;
		FillInSubordinatePropertiesForStatistics("Currency");
	EndIf;
	
	If ChangedBankingDetails.Property("ARAPCurrency") Then
		ARAPCurrency = Object.ARAPCurrency;
		FillInDefaultContract();
		Object.CompanyBankAccount = GetOrganizationSDefaultBankAccountServer();
	EndIf;
	
	ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisForm, ChangedBankingDetails, True);
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersServices

&AtClient
Procedure ServicesAfterDeleteRow(Item)
	
	CalculateFinalIndicatorsOfActsOfWorkPerformed(ThisObject);
	DiscountsMarkupsFillingClient.ResetDiscountsCalculatedFlag(ThisObject);
	
	If UseCustomerInvoicesForSeveralOrders Then
		ServicesAfterDeleteRowServer();
	Else
		UpdateOrderInformation();
	EndIf;

EndProcedure

&AtClient
Procedure ServicesOnEditEnd(Item, NewRow, CancelEdit)
	
	CalculateFinalIndicatorsOfActsOfWorkPerformed(ThisObject);
	
EndProcedure

&AtClient
Procedure ServicesBeforeAddRow(Item, Cancel, Copy, Parent, Var_Group)
	
	If Object.InvoiceByOrders Then
		Cancel = True;
		SelectionOfServicesFromOrder();
	EndIf;
	
	If Copy Then
		SetsClient.BeforeDeletingRowOfTablePart(ThisForm, "Services", Cancel, True);
	EndIf;
	
	DiscountsMarkupsFillingClient.ResetDiscountsCalculatedFlag(ThisObject);
	
EndProcedure

&AtClient
Procedure ServicesSelection(Item, RowSelected, Field, StandardProcessing)
	
	If Item.CurrentItem = Items.ServicesPercentRateOfAutomaticDiscountMarkup
		Or Item.CurrentItem = Items.ServicesDiscountMarkupAmount Then
		
		StandardProcessing = False;
		
		If Not Object.InvoiceByOrders Then
			
			If Not Object.DiscountsAreCalculated Then
				ShowQueryBox(New CallbackDescription("ServicesSelectionCompletion", ThisObject, 
					New Structure("RowSelected, Field", RowSelected, Field)), 
					NStr("vi = 'Chưa tính chiết khấu (phụ thu), tính chiết khấu (phụ thu)?';
						|ru = 'Скидки (наценки) не рассчитаны, рассчитать?';
						|en = 'Discounts (markups) are not calculated, calculate?'; fa = 'Discounts (markups) are not calculated, calculate?';
						|it = 'Gli sconti (sovrapprezzi) non sono stati calcolati, calcolare?';
						|pl = 'Rabaty (marże) nie są obliczane, obliczyć?';
						|tr = 'İndirimler uygulanmadı. Uygulamak istiyor musunuz?'"), QuestionDialogMode.YesNo);
                Return;
			EndIf;
			
			ServicesSelectionFragment();

			
		EndIf;
		
	ElsIf Field = Items.ServicesPrice Then
		
		CurrentData = Items.Services.CurrentData;
		If ReadPriceTypeRight Then
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
					CommonClientServer.PathToTabularSection("Object.Services", CurrentData.LineNumber, "PriceKind"),);
			EndIf;
		EndIf;
		
	ElsIf SetsClient.ItemToLock(Field) Then
		
		CurrentRow = Object.Services.FindByID(RowSelected);
		If ValueIsFilled(CurrentRow.ProductsInSet) Then
			
			NotificationParameter1 = New Structure;
			NotificationParameter1.Insert("ProductsInSet",   CurrentRow.ProductsInSet);
			NotificationParameter1.Insert("ItemVariantOfSet", CurrentRow.ItemVariantOfSet);
			NotificationParameter1.Insert("OwnerForm",        UUID);
			
			Notify("EditSet", NotificationParameter1, ThisForm);
			
		EndIf;
		
	ElsIf Field = Items.ServicesProductsInSet Then
		
		ShowValue(Undefined, Items.Services.CurrentData.ProductsInSet);
		
	ElsIf Field.Name = "ServicesSalesOrder" Then
		If ValueIsFilled(Items.Services.CurrentData.SalesOrder) Then
			ShowValue(Undefined, Items.Services.CurrentData.SalesOrder);
		ElsIf ValueIsFilled(Object.SalesOrder) Then
			ShowValue(Undefined, Object.SalesOrder);
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure ServicesSelectionCompletion(QuestionResult, AdditionalParameters) Export
    
    RowSelected = AdditionalParameters.RowSelected;
    Field = AdditionalParameters.Field;
    
    
    Result = QuestionResult;
    If Result = DialogReturnCode.No Then
        Return;
    Else
        
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
    
    ServicesSelectionFragment();

EndProcedure

&AtClient
Procedure ServicesSelectionFragment()
    
    Var CurrentData;
    
    If Not ValueIsFilled(AddressOfAppliedDiscountsInTheTemporaryStorage) Then
        CalculateDiscountsWithoutApplyingToObject();
    EndIf;
    
    CurrentData = Items.Services.CurrentData;
    DiscountsMarkupsFillingClient.OpenAppliedDiscountsForm(CurrentData, Object, ThisForm);

EndProcedure

&AtClient
Procedure LabelHeaderSalesOrdersClick(Item, StandardProcessing)
	
	StandardProcessing = False;
	OpenForm(
		"CommonForm.ViewingListOfDocuments",
		New Structure("DocumentsList, Title",
			OrderList,
			NStr("vi = 'Đơn hàng của khách (%DocumentsCount%)';
				|ru = 'Заказы клиентов (%DocumentsCount%)';
				|en = 'Sales orders (%DocumentsCount%)'; fa = 'Sales orders (%DocumentsCount%)';
				|it = 'Ordini dei clienti (%DocumentsCount%)';
				|pl = 'Zamówienia klientów (%DocumentsCount%)';
				|tr = 'Satış siparişleri (%DocumentsCount%)'")
		),
		ThisForm,,,, Undefined, FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure ServicesContentStartChoice(Item, ChoiceData, StandardProcessing)
	
	CommonClient.ShowCommentEditingForm(
		Item.EditText,
		ThisObject,
		"Items.Services.CurrentData.Content",
		NStr("vi = 'Nội dung dịch vụ';
			|ru = 'Содержание услуги';
			|en = 'Service scope'; fa = 'دامنه خدمات';
			|it = 'Contenuto del servizio';
			|pl = 'Opis usługi';
			|tr = 'Hizmet içeriği'"));
	
EndProcedure

&AtClient
Procedure ServicesProductsOnChange(Item)
	
	ClearMessages();
	
	CurrentRow = Items.Services.CurrentData;
	
	VerificationOfPaymentWithBonusPoints();
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	ParametersFillInVATRate = BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRate(Object);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
	StructureOfActions.Insert("CheckCharacteristicsByOwner", CurrentRow.Characteristic);
	StructureOfActions.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));
	If ToUseTermsOfSales And ValueIsFilled(Object.Terms) Then
		StructureOfActions.Insert("FillInTermsOfServiceSales", BatchProcessingOfTablePartClientServer.GetStructureForFillingInSalesConditionsInTSLine(Object));
	Else
		StructureOfActions.Insert("FillInSalePrice", BatchProcessingOfTablePartClientServer.ParametersForFillingInPriceInTSLine(Object));
	EndIf;
	StructureOfActions.Insert("FillInVATRate", ParametersFillInVATRate);
	StructureOfActions.Insert("FillInVATRateByPriceType", BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRateByPriceType(Object));
	StructureOfActions.Insert("FillInContent", BatchProcessingOfTablePartClientServer.GetStructureOfFillingInServiceContentInTSLine(Object, True));
	
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmount","Count");
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountManualDiscount", New Structure("Clear, QuantityName", True, "Count"));
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountAutomaticDiscount", New Structure("Clear", True));
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountDiscountWithBonusPoints");
	StructureOfActions.Insert("ClearAmountOfSettlements");
	LinesOfBusinessClientServer.StructureOfInsertActionsWhenAddingRow(ThisForm, StructureOfActions);

	StructureOfActions.Insert("ProductsOnChangeOverridable", New Structure("FormName, TabularSectionName",
		ThisForm.FormName, "Services"));

	StructureOfActions.Insert("FillInSubdivisionInTSLine", New Structure("Department", Object.Department));

	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
	FillInServiceDetailsForProductRange();
	
	CalculateFinalIndicatorsOfActsOfWorkPerformed(ThisObject);
		
	DiscountsMarkupsFillingClient.ResetDiscountsCalculatedFlag(ThisObject);

EndProcedure

&AtClient
Procedure ServicesPartnerProductsOnChange(Item)
	
	ClearMessages();
	
	CurrentRow = Items.Services.CurrentData;
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	ParametersFillInVATRate = BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRate(Object);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("CheckCharacteristicsByOwner", CurrentRow.Characteristic);
	StructureOfActions.Insert("FillInTheItemByThePartnerSItem");
	If ToUseTermsOfSales And ValueIsFilled(Object.Terms) Then
		StructureOfActions.Insert("FillInTermsOfServiceSales", BatchProcessingOfTablePartClientServer.GetStructureForFillingInSalesConditionsInTSLine(Object));
	Else
		StructureOfActions.Insert("FillInSalePrice", BatchProcessingOfTablePartClientServer.ParametersForFillingInPriceInTSLine(Object));
	EndIf;
	StructureOfActions.Insert("FillInVATRate", ParametersFillInVATRate);
	StructureOfActions.Insert("FillInVATRateByPriceType", BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRateByPriceType(Object));
	StructureOfActions.Insert("FillInContent", BatchProcessingOfTablePartClientServer.GetStructureOfFillingInServiceContentInTSLine(Object, True));
	
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmount","Count");
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountManualDiscount", New Structure("Clear, QuantityName", True, "Count"));
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountAutomaticDiscount", New Structure("Clear", True));
	StructureOfActions.Insert("ClearAmountOfSettlements");
	LinesOfBusinessClientServer.StructureOfInsertActionsWhenAddingRow(ThisForm, StructureOfActions);

	StructureOfActions.Insert("ProductsOnChangeOverridable", New Structure("FormName, TabularSectionName",
		ThisForm.FormName, "Services"));

	StructureOfActions.Insert("FillInSubdivisionInTSLine", New Structure("Department", Object.Department));

	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
	FillInServiceDetailsForProductRange();
	
	CalculateFinalIndicatorsOfActsOfWorkPerformed(ThisObject);
		
	DiscountsMarkupsFillingClient.ResetDiscountsCalculatedFlag(ThisObject);

EndProcedure

&AtClient
Procedure ServicesPartnerProductsStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	
	CurrentRow = Items.Services.CurrentData;
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("FormItem" , Item);
	AdditionalParameters.Insert("CurrentRow", CurrentRow);
	
	ClosingNotification = New CallbackDescription("ProcessResultOfSelectingPartnerProductName", ThisObject, AdditionalParameters);

	PartnersProductsClient.OpenPartnerProductSelectionForm(ThisObject, Object.Partner, CurrentRow, Item.Title, ClosingNotification, True);

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
	
	ServicesPartnerProductsOnChange(AdditionalParameters.FormItem);
	
EndProcedure

&AtClient
Procedure ServicesCharacteristicOnChange(Item)
	
	ClearMessages();
	
	CurrentRow = Items.Services.CurrentData;
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	
	StructureOfActions = New Structure;
	If ToUseTermsOfSales And ValueIsFilled(Object.Terms) Then
		StructureOfActions.Insert("FillInTermsOfServiceSales", BatchProcessingOfTablePartClientServer.GetStructureForFillingInSalesConditionsInTSLine(Object));
	Else
		StructureOfActions.Insert("FillInSalePrice", BatchProcessingOfTablePartClientServer.ParametersForFillingInPriceInTSLine(Object));
	EndIf;
	
	StructureOfActions.Insert("FillInVATRateByPriceType", BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRateByPriceType(Object));
	StructureOfActions.Insert("FillInContent", BatchProcessingOfTablePartClientServer.GetStructureOfFillingInServiceContentInTSLine(Object, True));
	StructureOfActions.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
	StructureOfActions.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmount","Count");
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountManualDiscount", New Structure("Clear, QuantityName", True, "Count"));
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountAutomaticDiscount", New Structure("Clear", True));
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountDiscountWithBonusPoints");
	StructureOfActions.Insert("ClearAmountOfSettlements");
	LinesOfBusinessClientServer.StructureOfInsertActionsWhenAddingRow(ThisForm, StructureOfActions);
	
	StructureOfActions.Insert("CharacteristicOnChangeOverridable", New Structure("FormName, TabularSectionName",
		ThisForm.FormName, "Services"));

	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
	CalculateFinalIndicatorsOfActsOfWorkPerformed(ThisObject);
	
	DiscountsMarkupsFillingClient.ResetDiscountsCalculatedFlag(ThisObject);
	
EndProcedure

&AtClient
Procedure ServicesWithAssignmentOnChange(Item)
	
	LinesOfBusinessClient.GoodsWithAssignmentOnChange(ThisObject, Items.Services.CurrentData);	
	
EndProcedure

&AtClient
Procedure ServicesPriceKindOnChange(Item)
	
	ClearMessages();
	
	CurrentRow = Items.Services.CurrentData;
	
	VerificationOfPaymentWithBonusPoints();
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInVATRateByPriceType", BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRateByPriceType(Object));
	StructureOfActions.Insert("FillInSalePrice", BatchProcessingOfTablePartClientServer.ParametersForFillingInPriceInTSLine(Object));
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmount","Count");
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountManualDiscount", New Structure("Clear, QuantityName", False,"Count"));
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountAutomaticDiscount", New Structure("Clear", True));
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountDiscountWithBonusPoints");
	StructureOfActions.Insert("ClearAmountOfSettlements");
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);

	CalculateFinalIndicatorsOfActsOfWorkPerformed(ThisObject);
	
	DiscountsMarkupsFillingClient.ResetDiscountsCalculatedFlag(ThisObject);
	
EndProcedure

&AtClient
Procedure ServicesPriceOnChange(Item)
	
	CurrentRow = Items.Services.CurrentData;
	
	VerificationOfPaymentWithBonusPoints();
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	
	StructureOfActions = New Structure;
	
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmount","Count");
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountManualDiscount", New Structure("Clear, QuantityName", False, "Count"));
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountAutomaticDiscount", New Structure("Clear", True));
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountDiscountWithBonusPoints");
	StructureOfActions.Insert("ClearAmountOfSettlements");
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);

	CalculateFinalIndicatorsOfActsOfWorkPerformed(ThisObject);
	
	DiscountsMarkupsFillingClient.ResetDiscountsCalculatedFlag(ThisObject);
	
EndProcedure

&AtClient
Procedure ServicesVATRateOnChange(Item)
	
	CurrentRow = Items.Services.CurrentData;
	
	VerificationOfPaymentWithBonusPoints();
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	
	StructureOfActions = New Structure;
	
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmount","Count");
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountManualDiscount", New Structure("Clear, QuantityName", False, "Count"));
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountAutomaticDiscount", New Structure("Clear", True));
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountDiscountWithBonusPoints");
	StructureOfActions.Insert("ClearAmountOfSettlements");
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);

	CalculateFinalIndicatorsOfActsOfWorkPerformed(ThisObject);
	
	DiscountsMarkupsFillingClient.ResetDiscountsCalculatedFlag(ThisObject);
	
EndProcedure

&AtClient
Procedure ServicesPercentRateOfManualDiscountOnChange(Item)
	
	CurrentRow = Items.Services.CurrentData;
	
	VerificationOfPaymentWithBonusPoints();
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateAmountOfManualDiscount","Count");
	
	StructureOfActions.Insert("RecalculateAmount","Count");
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountManualDiscount", New Structure("Clear, QuantityName", False, "Count"));
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountAutomaticDiscount", New Structure("Clear", False));
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountDiscountWithBonusPoints");
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("ClearAmountOfSettlements");
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
	CalculateFinalIndicatorsOfActsOfWorkPerformed(ThisObject);
	
EndProcedure

&AtClient
Procedure ServicesManualDiscountOnChange(Item)
	
	CurrentRow = Items.Services.CurrentData;
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculatePercentageOfManualDiscount", "Count");
	
	StructureOfActions.Insert("RecalculateAmount","Count");
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountManualDiscount", New Structure("Clear, RecalculateAmountOfManualDiscount_, QuantityName", False, False, "Count"));
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountAutomaticDiscount", New Structure("Clear", False));
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountDiscountWithBonusPoints");
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("ClearAmountOfSettlements");
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
	CalculateFinalIndicatorsOfActsOfWorkPerformed(ThisObject);
	
EndProcedure

&AtClient
Procedure ServicesSumOnChange(Item)
	
	CurrentRow = Items.Services.CurrentData;
	
	StructureOfPriceConversion  = BatchProcessingOfTablePartClientServer.GetStructureForRecalculatingDiscountPriceInWHSales(Object, False, "Count");
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculatePriceDiscountByAmountInSales", StructureOfPriceConversion);
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("ClearAmountOfSettlements");
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
	CalculateFinalIndicatorsOfActsOfWorkPerformed(ThisObject);
	
	DiscountsMarkupsFillingClient.ResetDiscountsCalculatedFlag(ThisObject);
	
EndProcedure

&AtClient
Procedure ServicesCountOnChange(Item)
	
	CurrentRow = Items.Services.CurrentData;
	
	StructureOfActions = New Structure;
	AddActionsToStructureWhenQuantityChanges(StructureOfActions, Object);
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
	CalculateFinalIndicatorsOfActsOfWorkPerformed(ThisObject);
	
	DiscountsMarkupsFillingClient.ResetDiscountsCalculatedFlag(ThisObject);
	
EndProcedure

&AtClient
Procedure ServicesBeforeDeleteRow(Item, Cancel)
	
	SetsClient.BeforeDeletingRowOfTablePart(ThisForm, "Services", Cancel);
	
EndProcedure

&AtClient
Procedure ServicesOnStartEdit(Item, NewRow, Copy)
	
	CurrentRow = Items.Services.CurrentData;
	
	If NewRow And Not Copy Then
		CurrentRow.Department = Object.Department;
	EndIf;
	
	SalesClient.ProductItemLineAtBeginningOfEditing(ThisForm, "Services", CurrentRow, NewRow, Copy);
	
	If Copy Then
		CurrentRow.RowCode = 0;
		CurrentRow.SalesOrder = Undefined;
		CurrentRow.AmountOfBonusPointsToDeduction = 0;
		CurrentRow.AmountOfBonusPointsToDeductionInCurrency = 0;
	EndIf;
	
EndProcedure

&AtClient
Procedure ServicesVATAmountOnChange(Item)
	
	CurrentRow = Items.Services.CurrentData;
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("ClearAmountOfSettlements");
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
	CalculateFinalIndicatorsOfActsOfWorkPerformed(ThisObject);
	
EndProcedure

&AtClient
Procedure DepartmentOnChange(Item)
	
	FillInSalesVATTaxation();
	
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
Procedure FillThePricesByTermsOfSales(Command)
	
	ClearMessages();
	
	If EnterprisePricesFillingClient.ItIsNecessaryToFillInPricesByAgreement(Object, "Services", NStr("vi = 'Dịch vụ';
																									|ru = 'Услуги';
																									|en = 'Services'; fa = 'خدمات';
																									|it = 'Servizi';
																									|pl = 'Services';
																									|tr = 'Hizmetler'")) Then
		
		ErrorText = "";
		PricesCalculated = FillThePricesByTermsOfSalesServer(, ErrorText);
		SalesClient.NotifyAboutEndOfFillingInPricesUnderAgreement(PricesCalculated, ErrorText);
		
	EndIf;
	
	DiscountsMarkupsFillingClient.ResetDiscountsCalculatedFlag(ThisObject);
	
EndProcedure

&AtClient
Procedure AutoTestFillInPricesByAgreement(Command) Export
	
	FillThePricesByTermsOfSales(Command);
	
EndProcedure

&AtClient
Procedure FillInPricesOfSelectedRowsByPriceType(Command)

	If EnterprisePricesFillingClient.ItIsNecessaryToFillInPricesByTypeOfPrices(Object, "Services", NStr("vi = 'Dịch vụ';
																										|ru = 'Услуги';
																										|en = 'Services'; fa = 'خدمات';
																										|it = 'Servizi';
																										|pl = 'Services';
																										|tr = 'Hizmetler'")) Then
		
		PriceSelectionOptions = EnterprisePricesFillingClient.NewFillOptionsSelectPriceType();
		PriceSelectionOptions.CallbackDescription = 
			New CallbackDescription("FillInPricesOfSelectedRowsByPriceTypeCompletion", ThisObject);
		PriceSelectionOptions.PriceIncludesVAT = Object.PriceIncludesVAT;
		PriceSelectionOptions.OwnerOfAnIndividualPriceType = ?(ToUseTermsOfSales,Object.Terms,Object.Partner);
		PriceSelectionOptions.UseWhileSellingToCustomers = True;
		
		EnterprisePricesFillingClient.ChooseTypeOfPrices(PriceSelectionOptions);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure FillInPricesOfSelectedRowsByPriceTypeCompletion(PricesKind, AdditionalParameters) Export
	
	ClearMessages();
	
	If ValueIsFilled(PricesKind) Then
		
		PricesCalculated = FillInPricesOfSelectedRowsByPriceTypeServer(PricesKind);
		SalesClient.NotifyAboutEndOfFillingInPricesByTypeOfPrices(PricesCalculated, PricesKind);
		DiscountsMarkupsFillingClient.ResetDiscountsCalculatedFlag(ThisObject);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure SearchByBarcodeExecute(Command)
	
	ClearMessages();
	Notification = New CallbackDescription("SearchByBarcodeCompletion", ThisObject);
	BarcodingOfItemsClient.ShowBarcodeInput(Notification);
	
	DiscountsMarkupsFillingClient.ResetDiscountsCalculatedFlag(ThisObject);
	
EndProcedure

&AtClient
Procedure SearchByBarcodeCompletion(BarcodeData_2, AdditionalParameters) Export
	
	ProcessBarcodes(BarcodeData_2);
	
EndProcedure

&AtClient
Procedure Attachable_PropertiesExecuteCommand(ItemOrCommand, Var_URL = Undefined, StandardProcessing = Undefined)
	PropertyManagerClient.ExecuteCommand(ThisObject, ItemOrCommand, StandardProcessing);
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
	
EndProcedure

&AtClient
Procedure OpenSelection(Command)
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.StartTimeMeasurement(True,
		"Document.CustomerInvoiceServices.DocumentForm.Command.OpenSelection");
	
	Cancel = False;
	If (ToUseTermsOfSales And Not ValueIsFilled(Object.Terms))
		Or Not ValueIsFilled(Object.Currency) Then
		ClearMessages();
		ReportErrorsWhenOpeningSelection(Cancel);
	EndIf;
	If Cancel Then
		Return;
	EndIf;
	
	HeaderParameter_ = NStr("vi = 'Chọn dịch vụ trong %Document%';
							|ru = 'Подбор услуг в %Document%';
							|en = 'Pick services in %Document%'; fa = 'Pick services in %Document%';
							|it = 'Selezione servizi in %Document%';
							|pl = 'Dobór usług w %Document%';
							|tr = '%Document% içindeki hizmetlerin seçimi'");
	If ValueIsFilled(Object.Ref) Then
		HeaderParameter_ = StrReplace(HeaderParameter_, "%Document%", Object.Ref);
	Else
		HeaderParameter_ = StrReplace(HeaderParameter_, "%Document%", NStr("vi = 'Biên bản nghiệm thu công việc';
																			|ru = 'Акт выполненных работ';
																			|en = 'Customer invoice — Services'; fa = 'فاکتور مشتری — خدمات';
																			|it = 'Verbale di consegna dei lavori effettuati';
																			|pl = 'Protokół wykonanych prac';
																			|tr = 'Müşteri faturası - Hizmetler'"));
	EndIf;
	
	ArrayOfProductTypes = New Array;
	ArrayOfProductTypes.Add(PredefinedValue("Enum.ItemsTypes.OperationService"));
	ArrayOfProductTypes.Add(PredefinedValue("Enum.ItemsTypes.Work_5"));
	ArrayOfProductTypes.Add(PredefinedValue("Enum.ItemsTypes.Set"));
	
	FormParameters = New Structure;
	FormParameters.Insert("Partner", Object.Partner);
	FormParameters.Insert("Terms", Object.Terms);
	FormParameters.Insert("Organization", Object.Organization);
	FormParameters.Insert("PriceIncludesVAT", Object.PriceIncludesVAT);
	FormParameters.Insert("VATTaxation", Object.VATTaxation);
	FormParameters.Insert("LineOfBusiness", Object.LineOfBusiness);
	FormParameters.Insert("Currency", Object.Currency);
	FormParameters.Insert("Title", HeaderParameter_);
	FormParameters.Insert("Date", Object.Date);
	FormParameters.Insert("SelectionModeExcludeGroupsAvailableInOrders", True);
	FormParameters.Insert("Document", Object.Ref);
	FormParameters.Insert("FilterByProductType", ArrayOfProductTypes);
	FormParameters.Insert("HideCommandRemainingQuantityInWarehouses", True);
	
	OpenForm("DataProcessor.SelectGoodsToSalesDocument.Form", FormParameters, ThisForm, UUID);
	
EndProcedure

&AtClient
Procedure CalculateDiscountsMarkups(Command)
	
	CalculateDiscountsMarkupsClient();
	
EndProcedure

&AtClient
Procedure OpenInformationAboutDiscounts(Command)
	
	If Not Object.DiscountsAreCalculated Then
		ShowQueryBox(New CallbackDescription("OpenInformationAboutDiscountsCompletion", ThisObject), 
			NStr("vi = 'Chưa tính chiết khấu (phụ thu), tính chiết khấu (phụ thu)?';
				|ru = 'Скидки (наценки) не рассчитаны, рассчитать?';
				|en = 'Discounts (markups) are not calculated, calculate?'; fa = 'Discounts (markups) are not calculated, calculate?';
				|it = 'Gli sconti (sovrapprezzi) non sono stati calcolati, calcolare?';
				|pl = 'Rabaty (marże) nie są obliczane, obliczyć?';
				|tr = 'İndirimler uygulanmadı. Uygulamak istiyor musunuz?'"), QuestionDialogMode.YesNo);
        Return;
		
	EndIf;
	
	OpenDiscountInformationFragment();
EndProcedure

&AtClient
Procedure OpenInformationAboutDiscountsCompletion(QuestionResult, AdditionalParameters) Export
    
    Result = QuestionResult;
    If Result = DialogReturnCode.No Then
        Return;
    Else
        
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
    
    
    OpenDiscountInformationFragment();

EndProcedure

&AtClient
Procedure OpenDiscountInformationFragment()
    
    Var CurrentData;
    
    If Not ValueIsFilled(AddressOfAppliedDiscountsInTheTemporaryStorage) Then
        CalculateDiscountsWithoutApplyingToObject();
    EndIf;
    
    CurrentData = Items.Services.CurrentData;
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
	
	If Not DiscountsMarkupsFillingClient.ItIsPossibleToAssignManualDiscountMarkUp(Object, "Services", NStr("vi = 'Dịch vụ';
																											|ru = 'Услуги';
																											|en = 'Services'; fa = 'خدمات';
																											|it = 'Servizi';
																											|pl = 'Services';
																											|tr = 'Hizmetler'")) Then
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
		
		CalculateFinalIndicatorsOfActsOfWorkPerformed(ThisObject);
		
	EndIf;

EndProcedure

&AtClient
Procedure AssignAManualDiscountForSelectedLines(Command)
	
	If Not DiscountsMarkupsFillingClient.ItIsPossibleToAssignManualDiscountMarkUp(Object, "Services", NStr("vi = 'Dịch vụ';
																											|ru = 'Услуги';
																											|en = 'Services'; fa = 'خدمات';
																											|it = 'Servizi';
																											|pl = 'Services';
																											|tr = 'Hizmetler'")) Then
		Return;
	EndIf;
	
	AddressInTempStorage = AddressOfDataForCalculatingManualDiscountsInTemporaryStorage(False);
	
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
		
		AssignManualDiscountOnServer(AmountOfManualDiscountMarkUp, Items.Services.SelectedRows,AddressInTempStorage);
		DiscountsMarkupsFillingClient.NotifyAboutEndOfAssignmentOfManualDiscountsMargins(AmountOfManualDiscountMarkUp, Object.Currency);
		
		CalculateFinalIndicatorsOfActsOfWorkPerformed(ThisObject);
		
	EndIf;

EndProcedure

&AtClient
Procedure CancelManualDiscounts(Command)
	
	If Not DiscountsMarkupsFillingClient.ItIsPossibleToCancelManualDiscountsMarkups(Object, "Services", NStr("vi = 'Dịch vụ';
																											|ru = 'Услуги';
																											|en = 'Services'; fa = 'خدمات';
																											|it = 'Servizi';
																											|pl = 'Services';
																											|tr = 'Hizmetler'")) Then
		Return;
	EndIf;
	
	CancelManualDiscountsOnServer();
	DiscountsMarkupsFillingClient.NotifyAboutEndOfAssignmentOfManualDiscountsMargins();
	
	CalculateFinalIndicatorsOfActsOfWorkPerformed(ThisObject);
	
EndProcedure

&AtClient
Procedure CalculateDiscountsMarkupsClient()
	
	ParametersStructure1 = New Structure;
	ParametersStructure1.Insert("ApplyToObject",                True);
	ParametersStructure1.Insert("OnlyPreliminaryCalculation",      False);
	ParametersStructure1.Insert("RestoreManagedDiscounts", True);
	ParametersStructure1.Insert("ManagedDiscounts", ManagedDiscounts);
	
	If Not Object.InvoiceByOrders Then
		
		TheStructureOfTheMessages = CalculateDiscountsMarginsOnServer(ParametersStructure1);
		If TheStructureOfTheMessages.Messages.Count() > 0 And TheStructureOfTheMessages.AutomaticallyOpen Then
			OpenForm("CommonForm.MessagesOfDiscountsMarkups", TheStructureOfTheMessages, ThisForm, UUID);
		EndIf;
		
	Else
		CalculateDiscountsMarginsOnOrderOnServer();
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
	
	If Not Object.InvoiceByOrders Then
		
		TheStructureOfTheMessages = CalculateDiscountsMarginsOnServer(Undefined, True);
		If TheStructureOfTheMessages.Messages.Count() > 0 And TheStructureOfTheMessages.AutomaticallyOpen Then
			OpenForm("CommonForm.MessagesOfDiscountsMarkups", TheStructureOfTheMessages, ThisForm, UUID);
			Cancel = True;
		EndIf;
		
	Else
		CalculateDiscountsMarginsOnOrderOnServer();
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
Procedure SelectServicesFromOrder(Command)
	
	SelectionOfServicesFromOrder();
	
EndProcedure

&AtClient
Procedure WriteDocument(Command)
	
	TMCommonUseClient.Write(ThisForm, True);
	
EndProcedure

&AtClient
Procedure FillInFromOrder(Command)
	
	If Object.Services.Count() > 0 Then
		
		UserAnswer = Undefined;

		
		ShowQueryBox(New CallbackDescription("FillInFromOrderCompletion", ThisObject), NStr("vi = 'Bảng ""Dịch vụ"" sẽ được điền lại. Tiếp tục?';
																							|ru = 'Таблица ""Услуги"" будет перезаполнена. Продолжить?';
																							|en = 'The ""Services"" table will be refilled. Continue?'; fa = 'The ""Services"" table will be refilled. Continue?';
																							|it = 'La tabella ""Servizi"" verrà ricompilata. Continuare?';
																							|pl = 'Tabela ""Услуги"" będzie wypełniona ponownie. Kontynuować?';
																							|tr = '""Hizmetler"" tablosu yeniden doldurulacak. Devam edilsin mi?'"), QuestionDialogMode.YesNo);
        Return;
		
	EndIf;
	
	FillInFragmentByRequest();
EndProcedure

&AtClient
Procedure FillInFromOrderCompletion(QuestionResult, AdditionalParameters) Export
    
    UserAnswer = QuestionResult;
    
    If UserAnswer = DialogReturnCode.No Then
        Return;
    EndIf;
    
    
    FillInFragmentByRequest();

EndProcedure

&AtClient
Procedure FillInFragmentByRequest()

	FillInFromOrderServer();

EndProcedure

&AtClient
Procedure SplitRow(Command)
	
	FormTable  = Items.Services;
	TableData = Object.Services;
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.StructureOfRecalculationOfAmount(
		"Sum, VATAmount, AmountIncludingVAT, ManualDiscount, DiscountMarkupAmount, 
		|AmountOfBonusPointsToDeduction, AmountOfBonusPointsToDeductionInCurrency, ");
	
	If FormTable.CurrentData <> Undefined Then
		BatchProcessingOfTablePartClientServer.FillInStructureForRecalculatingAmount(StructureOfRecalculationOfAmount, FormTable.CurrentData);
	EndIf;
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("StructureOfRecalculationOfAmount", StructureOfRecalculationOfAmount);
	
	StringSplittingParameters = ProcessingOfTabularFormsClient.StringSplittingParameters();
	StringSplittingParameters.FieldNameQuantity = "Count";
	
	Notification = New CallbackDescription("SplitRowCompletion", ThisObject, AdditionalParameters);
	ProcessingOfTabularFormsClient.SplitRow(TableData, FormTable, Notification, StringSplittingParameters);
	
EndProcedure

&AtClient
Procedure SplitRowCompletion(NewRow, AdditionalParameters) Export 
	
	CurrentRow = Items.Services.CurrentData;
	
	If NewRow <> Undefined Then
		
		NewRow.RowCode = 0;
		
		BatchProcessingOfTablePartClientServer.AddLineToRecalculateAmount(AdditionalParameters.StructureOfRecalculationOfAmount, CurrentRow);
		BatchProcessingOfTablePartClientServer.AddLineToRecalculateAmount(AdditionalParameters.StructureOfRecalculationOfAmount, NewRow);
		BatchProcessingOfTablePartClientServer.RecalculateAmounts(AdditionalParameters.StructureOfRecalculationOfAmount);
		
		StructureOfActions = New Structure;
		StructureOfActions.Insert("ClearAmountOfSettlements");
		
		BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
		BatchProcessingOfTablePartClient.ProcessTSString(NewRow, StructureOfActions, CachedValues);
		
		CalculateFinalIndicatorsOfActsOfWorkPerformed(ThisObject);
		
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
Procedure InsertRows(Command)
	
	ClearMessages();
	
	NumberOfProductsBeforeInsertion = Object.Services.Count();
	
	GetLinesFromClipboard();
	DiscountsMarkupsFillingClient.ResetDiscountsCalculatedFlag(ThisObject);
	
	NumberOfInserted = Object.Services.Count()-NumberOfProductsBeforeInsertion;
	ProcessingOfTabularFormsClient.NotifyUserAboutInsertingRows(NumberOfInserted);
	
EndProcedure

&AtClient
Procedure CopyRows(Command)
	
	If ProcessingOfTabularFormsClient.SelectedLineToExecuteCommand(Items.Services) Then
		CopyLinesOnServer();
		ProcessingOfTabularFormsClient.NotifyUserAboutCopyingStrings(Items.Services.SelectedRows.Count());
	EndIf;
	
EndProcedure

&AtClient
Procedure ImportFromExternalFile(Command)
	
	ImportParameters = ProcessingOfTabularFormsClient.ProductLoadingParameters();
	ImportParameters.Organization = Object.Organization;
	ImportParameters.ImportPrices = True;
	ImportParameters.PriceIncludesVAT    = Object.PriceIncludesVAT;
	ImportParameters.VATTaxation = Object.VATTaxation;
	ImportParameters.FillingDate     = Object.Date;
	ImportParameters.ComponentsPriceParameters.Date       = Object.Date;
	ImportParameters.ComponentsPriceParameters.Currency     = Object.Currency;
	ImportParameters.ComponentsPriceParameters.Terms = Object.Terms;
	
	ArrayOfProductTypes = New Array;
	ArrayOfProductTypes.Add(PredefinedValue("Enum.ItemsTypes.OperationService"));
	ArrayOfProductTypes.Add(PredefinedValue("Enum.ItemsTypes.Work_5"));
	ArrayOfProductTypes.Add(PredefinedValue("Enum.ItemsTypes.Set"));
	ImportParameters.FilterParameters.Insert("ItemsType", ArrayOfProductTypes);
	
	Notification = New CallbackDescription("ImportFromExternalFileCompletion", ThisObject);
	ProcessingOfTabularFormsClient.ShowProductUploadForm(ImportParameters, Notification);
	
EndProcedure

&AtClient
Procedure ImportFromExternalFileCompletion(ImportedDataAddress, AdditionalParameters) Export
	
	If ValueIsFilled(ImportedDataAddress) Then
		GetUploadedProductsFromStorage(ImportedDataAddress);
	EndIf;
	
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
Procedure SetComposition(Command)
	
	RowSelected = Items.Services.CurrentRow;
	
	If RowSelected = Undefined Then
		Return;
	EndIf;
	
	CurrentRow = Object.Services.FindByID(RowSelected);
	
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
	OpeningParameters.Insert("Terms", Object.Terms);
	OpeningParameters.Insert("Date", Object.Date);
	OpeningParameters.Insert("Ref", Object.Ref);
	OpeningParameters.Insert("HideCommandRemainingQuantityInWarehouses", True);
	OpeningParameters.Insert("Organization", Object.Organization);
	
	OpenForm("DataProcessor.EditSet.Form.Form", OpeningParameters, ThisForm, UUID);
	
EndProcedure

&AtClient
Procedure PostDocument(Command)
	
	TMCommonUseClient.Post(ThisForm, True);
	
EndProcedure

&AtClient
Procedure PostAndClose(Command)
	
	TMCommonUseClient.PostAndClose(ThisForm, True);
	
EndProcedure

&AtClient
Procedure CalculationsClick(Item, StandardProcessing)
	ARAPAccountingClient.CalculationsClick(ThisForm, Item, StandardProcessing);
EndProcedure

&AtClient
Procedure PrintDetails(Command)
	OpenPrintDetails();
EndProcedure

&AtClient
Procedure PaymentSettlement(Command)
	
	PlacePaymentDecryptionInTemporaryStorage();
	ARAPAccountingClient.PaymentSettlement(ThisForm, Items.CreditPaymentForm);
	
EndProcedure

&AtClient
Procedure SetTheMarkApart(Command)
	
	SetUncheckSeparately(True);
	
EndProcedure

&AtClient
Procedure UncheckTheSeparateBox(Command)
	
	SetUncheckSeparately(False);
	
EndProcedure

&AtClient
Procedure CancelPaymentWithBonusPoints(Command)
	
	ApplyPaymentWithBonusPointsClient();
	
	DiscountsMarkupsFillingClient.ResetDiscountsCalculatedFlag(ThisObject);
	
EndProcedure

&AtClient
Procedure AddPaymentWithBonusPoints(Command) Export
	
	NotificationDetailsCompletion = New CallbackDescription("AddPaymentWithBonusPointsContinued", ThisObject);
	
	If Object.Posted Then
		RetailSalesClient.DisplayQuestionAboutNeedForUnverifiedDocument(ThisObject, NotificationDetailsCompletion);
	Else
		RunCallback(NotificationDetailsCompletion, True);
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
		FormOpenParameters.Insert("AddressOfTheTablePartProducts", AddressOfTabularPartOfService());
		FormOpenParameters.Insert("Currency",                    Object.Currency);
		
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
		CalculateFinalIndicatorsOfActsOfWorkPerformed(ThisObject);
		Return;
	EndIf;
	
	ApplyPaymentWithBonusPointsClient(Result.AddressInTempStorage);
	
	DiscountsMarkupsFillingClient.ResetDiscountsCalculatedFlag(ThisObject);
	
EndProcedure

&AtClient
Procedure OpenInventoryKinds(Command)
	
	OptionsForEditingInventoryTypes = PutGoodsAndStockTypesInStorage();
	FinancesClient.OpenInventoryKinds(ThisObject, OptionsForEditingInventoryTypes);
	
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

	//
	
	VATAccountingERP.EstablishConditionalAppearanceOfVATAmountsForSalesTaxation(ThisForm, 
													"ServicesVATRate", 
													"ServicesVATAmount", 
													"ServicesAmountIncludingVAT");

	//

	EnterprisePricesFillingServer.SetConditionalAppearancePriceIncludesVAT(ThisForm, "ServicesAmountIncludingVAT");

	//

	LinesOfBusinessServer.SetConditionalAppearanceOfFlagSeparately(ThisObject);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ServicesPrice.Name);

	FilterGroup1 = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup1.GroupType = DataCompositionFilterItemsGroupType.OrGroup;

	FilterGroup2 = FilterGroup1.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup2.GroupType = DataCompositionFilterItemsGroupType.AndGroup;

	ItemFilter = FilterGroup2.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.SalesOrder");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;

	ItemFilter = FilterGroup2.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("VarianceFromSalesTermsAndConditions");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;

	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Services.PriceKind");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	Item.Appearance.SetParameterValue("ReadOnly", True);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ServicesSum.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ServicesVATAmount.Name);
	
	FilterGroup1 = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup1.GroupType = DataCompositionFilterItemsGroupType.OrGroup;

	FilterGroup2 = FilterGroup1.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup2.GroupType = DataCompositionFilterItemsGroupType.AndGroup;

	ItemFilter = FilterGroup2.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("VarianceFromSalesTermsAndConditions");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;

	ItemFilter = FilterGroup2.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.SalesOrder");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;

	FilterGroup2 = FilterGroup1.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup2.GroupType = DataCompositionFilterItemsGroupType.AndGroup;

	ItemFilter = FilterGroup2.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Services.PriceKind");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;

	FilterGroup3 = FilterGroup2.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup3.GroupType = DataCompositionFilterItemsGroupType.OrGroup;

	ItemFilter = FilterGroup3.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("UseDiscountAdjustmentsInSales");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;

	Item.Appearance.SetParameterValue("ReadOnly", True);

	//

	ProductsServer.EstablishConditionalAppearanceOfProductCharacteristics(ThisForm, 
																			 "ServicesCharacteristic",
																		     "Object.Services.ItemVariantsAreUsed");

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ServicesRowCode.Name);

	FilterGroup1 = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup1.GroupType = DataCompositionFilterItemsGroupType.OrGroup;

	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.SalesOrder");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;

	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Services.RowCode");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	Item.Appearance.SetParameterValue("MarkIncomplete", False);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ServicesAmountARAP.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Currency");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = New DataCompositionField("Object.ARAPCurrency");

	Item.Appearance.SetParameterValue("Visible", False);

	//

	EnterprisePricesFillingServer.EstablishConditionalAppearanceOfPriceTypes(ThisForm, 
									                     "ServicesPriceKind", 
                                                         "Object.Services.PriceKind");

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ServicesSalesOrder.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Services.SalesOrder");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	Item.Appearance.SetParameterValue("TextColor", StyleColors.HyperlinkColor);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ServicesSalesOrder.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("UseCustomerInvoicesForSeveralOrders");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;

	Item.Appearance.SetParameterValue("Visible", False);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ServicesSalesOrder.Name);

	FilterGroup1 = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup1.GroupType = DataCompositionFilterItemsGroupType.OrGroup;

	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.SalesOrder");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;

	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.InvoiceByOrders");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;

	Item.Appearance.SetParameterValue("Visible", False);

	//
	WarehousesServer.EstablishConditionalAppearanceOfVTCHDivision(ThisForm, "Services", False);
	
	//
	
	SetsServer.SetConditionalAppearance(ThisForm, "Services");
	
	LinesOfBusinessServer.EstablishConditionalAppearanceOfDirectionOfActivity(ThisForm);
	
EndProcedure

#Region OnChangeAttributes

&AtServer
Procedure DateOnChangeServer(RecalculatePrices_, PricesCalculated, ApplyPaymentWithBonusPoints = False)
	
	If ApplyPaymentWithBonusPoints = True Then
		ApplyPaymentWithBonusPoints(, True);
	EndIf;
	
	If RecalculatePrices_ Then
		PricesCalculated = FillThePricesByTermsOfSalesServer(True);
	EndIf;
	
	FillInSalesVATTaxation();
	VATTaxationOnChangeServer();
	
	ResponsiblePersonsServer.WhenChangingRelatedDocumentDetails(Object);
	ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisForm,"Date");
	
	RetailSalesClientServer.SetAvailabilityOfBonusPointsPaymentTeams(Items, Object.Date);
	
EndProcedure

&AtServer
Procedure PartnerOnChangeServer()
	
	AttributesArray = New Array;
	
	If ToUseTermsOfSales Then
		FillIn_TermsOfSales(AttributesArray);
		AttributesArray.Add("Currency");
		AttributesArray.Add("ARAPCurrency");
		AttributesArray.Add("Contract");
		AttributesArray.Add("LineOfBusiness");
		AttributesArray.Add("Counterparty");
		AttributesArray.Add("Organization");
		AttributesArray.Add("Terms");
	Else
		Counterparty = Object.Counterparty;
		PartnersAndCounterparties.FillInPartnerSDefaultCounterparty(Object.Partner, Object.Counterparty);
		If Counterparty <> Object.Counterparty Then
			Object.CounterpartyBankAccount = GetDefaultCounterpartyBankAccountServer(Object.Counterparty);
		EndIf;
		UseCustomerContracts = GetFunctionalOption("UseCustomerContracts");
		If UseCustomerContracts Then
			FillInDefaultContract();
		EndIf;
	EndIf;
	
	PartnersProductsServer.FillInPartnerProductListByProductNameWhenPartnerChanges(Object.Services, Object.Partner);
	
	AttributesArray.Add("Partner");
	ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisForm, AttributesArray);
	
	GeneratingFiscalChecksServer.FormWhenChangingBankingDetails(ThisObject);
	
	SetAvailabilityOfItemsByStatusServer();
	
	FillInServiceDetailsForProductRange();
	
	SalesServer.SetContractAvailability(Object, Items.Contract.Enabled, Items.Contract.Visible, Object.Contract);
	
	UpdateTextOfInvoiceIssued();
	FillBaseForPrinting();
	
	FillInSubordinatePropertiesForStatistics("Counterparty");
	
	ResponsiblePersonsServer.WhenChangingRelatedDocumentDetails(Object);
	
	SetVisibilityOfShipmentBanToPartner();
	
	If UseLinesOfBusiness Then
		LinesOfBusinessServer.FillInDefaultDirection(Object.LineOfBusiness, Object.Terms, Object.Contract);
		LinesOfBusinessServer.WhenChangingDirectionOfActivity(ThisObject);
	EndIf;
	
	ResponsiblePersonsServer.FillInManagerSelectionList_(Items.Manager, Object);
	ResponsiblePersonsServer.InstallManager(
		Object, SalesServer.DocumentBasis(Object, "InvoiceByOrders, SalesOrder, Services.SalesOrder"));

	
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
Procedure TermsOnChangeServer()
	
	DocumentSales = FormAttributeToValue("Object");
	DocumentSales.FillInTermsOfSalesUnderAgreement();
	ResponsiblePersonsServer.FillInManagerSelectionList_(Items.Manager, DocumentSales);
	ResponsiblePersonsServer.InstallManager(
		DocumentSales, SalesServer.DocumentBasis(DocumentSales, "InvoiceByOrders, SalesOrder, Services.SalesOrder"));
	ValueToFormAttribute(DocumentSales, "Object");
	
	DocumentCurrency = Object.Currency;
	ARAPCurrency = Object.ARAPCurrency;
	
	CalculateFinalIndicatorsOfActsOfWorkPerformed(ThisObject);
	
	FillInServiceDetailsForProductRange();
	SalesServer.SetContractAvailability(Object, Items.Contract.Enabled, Items.Contract.Visible, Object.Contract);
	
	UpdateTextOfInvoiceIssued();
	
	AttributesArray = New Array;
	AttributesArray.Add("Currency");
	AttributesArray.Add("ARAPCurrency");
	AttributesArray.Add("Partner");
	AttributesArray.Add("Contract");
	AttributesArray.Add("LineOfBusiness");
	AttributesArray.Add("Counterparty");
	AttributesArray.Add("Organization");
	AttributesArray.Add("Terms");
	ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisForm, AttributesArray);
		
	FillInSubordinatePropertiesForStatistics("Contract");
	
	ResponsiblePersonsServer.WhenChangingRelatedDocumentDetails(Object);
		
	If UseLinesOfBusiness Then
		LinesOfBusinessServer.FillInDefaultDirection(Object.LineOfBusiness, Object.Terms, Object.Contract);
		LinesOfBusinessServer.WhenChangingDirectionOfActivity(ThisObject);
	EndIf;
	
	If ValueIsFilled(Object.Contract) Then
		ContractOnChangeServer();
	EndIf;
	
EndProcedure

&AtServer
Procedure TermsClearingServer()
	
	ResponsiblePersonsServer.FillInManagerSelectionList_(Items.Manager, Object);
	ResponsiblePersonsServer.InstallManager(
		Object, SalesServer.DocumentBasis(Object, "InvoiceByOrders, SalesOrder, Services.SalesOrder"));
	
EndProcedure

&AtServer
Procedure DocumentAmountOnChangeServer(DocumentAmount)
	
	RecalculationParameters = PriceManagementSystem.ParametersForRecalculationOfTableAmountsONChangeOfExchangeRate(Object.PriceIncludesVAT, DocumentAmount, "Count");
	RecalculationParameters.RecalculateAutomaticDiscounts = True;
	RecalculationParameters.RecalculateManualDiscounts         = True;
	
	PriceManagementSystem.RecalculateTableAmountsONChangeOfExchangeRate(
		Object.Services,
		RecalculationParameters);
	
	CalculateFinalIndicatorsOfActsOfWorkPerformed(ThisObject);
		
	If Not Object.InvoiceByOrders And Not ValueIsFilled(Object.Terms) Then
		Object.ARAPCurrency = Object.Currency;
	EndIf;
	
EndProcedure

&AtServer
Procedure CounterpartyOnChangeServer()
	
	SalesServer.SetContractAvailability(Object, Items.Contract.Enabled, Items.Contract.Visible, Object.Contract);
	FillInDefaultContract();
	
	If ValueIsFilled(Object.Counterparty)
		And Not Catalogs.CounterpartyBankAccounts.VerifyBankAccountHolder(
			Object.CounterpartyBankAccount, Object.Counterparty) Then
		Object.CounterpartyBankAccount = GetDefaultCounterpartyBankAccountServer(Object.Counterparty);
	EndIf;
	
	If UseLinesOfBusiness Then
		LinesOfBusinessServer.FillInDefaultDirection(Object.LineOfBusiness, Object.Terms, Object.Contract);
		LinesOfBusinessServer.WhenChangingDirectionOfActivity(ThisObject);
	EndIf;
	
	FillInSubordinatePropertiesForStatistics("Counterparty");
	
	ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisForm, "Counterparty");
	
	GeneratingFiscalChecksServer.FormWhenChangingBankingDetails(ThisObject);
	
	WhenChangingKeyDetailsStatusOfEDO();
	
	
EndProcedure

&AtServer
Procedure ContractOnChangeServer()
	
	Contract = Object.Contract;
	
	If UseLinesOfBusiness Then
		LinesOfBusinessServer.FillInDefaultDirection(Object.LineOfBusiness, Object.Terms, Object.Contract);
		LinesOfBusinessServer.WhenChangingDirectionOfActivity(ThisObject);
	EndIf;
	
	ContractData = Common.ObjectAttributesValues(Object.Contract, "ForeignCurrencyTransaction, BankAccount");
	If ContractData.ForeignCurrencyTransaction <> Object.ForeignCurrencyTransaction Then
		Object.CompanyBankAccount = Catalogs.CompaniesBankAccounts.EmptyRef();
	EndIf;
	Object.ForeignCurrencyTransaction = ContractData.ForeignCurrencyTransaction;
	
	SalesServer.FillInBankAccountsUnderAgreement(Object.Contract, Object.CompanyBankAccount,
		Object.CounterpartyBankAccount);
	
	Object.CompanyBankAccount = GetOrganizationSDefaultBankAccountServer();
	
	FillInSalesVATTaxation();
	VATTaxationOnChangeServer();
	ResponsiblePersonsServer.FillInManagerSelectionList_(Items.Manager, Object);
	ResponsiblePersonsServer.InstallManager(
		Object, SalesServer.DocumentBasis(Object, "InvoiceByOrders, SalesOrder, Services.SalesOrder"));
	FillInSubordinatePropertiesForStatistics("Contract");
	ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisForm, "Contract");
	FillBaseForPrinting();
	

	WhenChangingKeyDetailsStatusOfEDO();
	
EndProcedure


&AtServer
Procedure OrganizationOnChangeServer()
	
	LocalAccountingCurrency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Object.Organization);
	
	SalesServer.SetContractAvailability(Object, Items.Contract.Enabled, Items.Contract.Visible, Object.Contract);
		
	If ValueIsFilled(Object.Organization) Then
		
		FillInDefaultContract();
		
		If UseLinesOfBusiness Then
			LinesOfBusinessServer.FillInDefaultDirection(Object.LineOfBusiness, Object.Terms, Object.Contract);
		EndIf;
		
		UpdateTextOfInvoiceIssued();
		
		FillInSalesVATTaxation();
		VATTaxationOnChangeServer();
		
	EndIf;
	
	CashServer.CheckOrganizationSSalesRegisterByOwner(Object.Organization, Object.CashAccount, Object.PaymentMethod, Object.LineOfBusiness);
	CashServer.CheckFillInOrganizationSBankAccountByOwner(Object.Organization,
		Object.CompanyBankAccount, Object.PaymentMethod, Object.LineOfBusiness, Object.ForeignCurrencyTransaction);
	
	FillInSubordinatePropertiesForStatistics("Organization");
	ResponsiblePersonsServer.InstallManager(
		Object, SalesServer.DocumentBasis(Object, "InvoiceByOrders, SalesOrder, Services.SalesOrder"));
	
	ResponsiblePersonsServer.WhenChangingRelatedDocumentDetails(Object);	
	LinesOfBusinessServer.WhenChangingDirectionOfActivity(ThisObject);
	ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisForm, "Organization");
	
	WhenChangingKeyDetailsStatusOfEDO();
	


	
EndProcedure

&AtServer
Procedure WhenChangingCertificatesOfCompletedWorksForSeveralOrders()
	
	If Object.InvoiceByOrders Then
		
		If Object.Services.Count() = 0 Then
			FillInFromOrderServer();
		Else
			LinkLinesOfCompletedWorkReportsToCustomerOrders(Not UseCustomerInvoicesForSeveralOrders);
		EndIf;
		
	Else
		
		UnbindRowsFromCustomerOrders();
		Object.SalesOrder = Documents.SalesOrder.EmptyRef();
		OrderList.Clear();
		
	EndIf;
		
	SetAvailabilityOfItemsByStatusServer();
	UpdateOrderInformation();
	SetAvailabilityOfClipboardCommands();
	
	ResponsiblePersonsServer.InstallManager(
		Object, SalesServer.DocumentBasis(Object, "InvoiceByOrders, SalesOrder, Services.SalesOrder"));

	ARAPAccountingFormWork.WhenChangingParametersOfMechanism(ThisForm);
	ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisForm, "InvoiceByOrders");
	LinesOfBusinessServer.SetVisibilityOfElementsSeparately(ThisObject);
	
EndProcedure

&AtServer
Procedure VATTaxationOnChangeServer()
	
	CachedValuesInternal = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInVATRateByPriceType", BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRateByPriceType(Object));
	StructureOfActions.Insert("AdjustVATRate",  BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRate(Object));
	BatchProcessingOfTablePartServer.TreatTS(Object.Services, StructureOfActions, CachedValuesInternal);
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForRecalculatingNDSWTCHAmount(Object);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmount","Count");
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountManualDiscount", New Structure("Clear, QuantityName", False, "Count"));
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountAutomaticDiscount", New Structure("Clear", True));
	StructureOfActions.Insert("ClearAmountOfSettlements");
	
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		CachedValuesInternal.ProcessedRows,
		StructureOfActions,
		Object.Services,
		Undefined);
	
	CalculateFinalIndicatorsOfActsOfWorkPerformed(ThisObject);
	
EndProcedure

&AtServer
Procedure PriceIncludesVATOnChangeServer(CachedValues)
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForRecalculatingNDSWTCHAmount(Object);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("ClearAmountOfSettlements");
	
	BatchProcessingOfTablePartServer.TreatTS(Object.Services, StructureOfActions, CachedValues);
	
	CalculateFinalIndicatorsOfActsOfWorkPerformed(ThisObject);
	
	If Not ToUseTermsOfSales Then
		
		PriceTypeSelectionParameters = SettingsValueCached.ParametersForSelectingDefaultPriceType();
	
		PriceTypeSelectionParameters.PriceIncludesVAT                           = Object.PriceIncludesVAT;
		PriceTypeSelectionParameters.UseWhileSellingToCustomers                    = True;
		PriceTypeSelectionParameters.Status                 = Enums.StatusesOfPriceTypeValidity.Valid;
	
		DefaultPriceType = SettingsValueCached.DefaultPriceType(PriceTypeSelectionParameters);
	EndIf;
	
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
	
EndProcedure

#EndRegion

#Region PricingAndDiscounts

&AtServer
Function FillThePricesByTermsOfSalesServer(OnAllLines = False, ErrorText = "")
	
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
		For Each String In Items.Services.SelectedRows Do
			RowsArray.Add(Object.Services.FindByID(String));
		EndDo;
	EndIf;
	
	SetsServerCall.AddToFullSet(Object.Services, RowsArray, True);
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateAmount","Count");
	StructureOfActions.Insert("RecalculateAmountWithVAT",StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateVATAmount",StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountOfManualDiscount","Count");
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountManualDiscount", New Structure("Clear, QuantityName", True, "Count"));
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountDiscountWithBonusPoints");
	StructureOfActions.Insert("ClearAutomaticDiscount");
	StructureOfActions.Insert("ClearAmountOfSettlements");
	StructureOfActions.Insert("FillInVATRateByPriceType", BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRateByPriceType(Object));
	
	FillParameters = New Structure;
	FillParameters.Insert("Date", Object.Date);
	FillParameters.Insert("Currency", Object.Currency);
	FillParameters.Insert("Terms", Object.Terms);
	FillParameters.Insert("Organization", Object.Organization);
	FillParameters.Insert("CalculateSets", True);
	FillParameters.Insert("VATTaxation", Object.VATTaxation);
	FillParameters.Insert("PopulationFields", "Price, PriceKind");
	FillParameters.Insert("ColumnsByValue", New Structure("Package", Catalogs.PackagesAndUnitsOfMeasure.EmptyRef()));
	
	PricesCalculated = EnterprisePricesFillingServer.FillInPrices(
		Object.Services,
		RowsArray, // Array of rows or selection structure
		FillParameters,
		StructureOfActions);
	
	CalculateFinalIndicatorsOfActsOfWorkPerformed(ThisObject);
	ARAPAccountingClientServer.UpdateHyperlinkText(ThisObject);
	
	Return PricesCalculated;
	
EndFunction

&AtServer
Function FillInPricesOfSelectedRowsByPriceTypeServer(PricesKind)
	
	RowsArray = New Array;
	For Each String In Items.Services.SelectedRows Do
		RowsArray.Add(Object.Services.FindByID(String));
	EndDo;
	
	SetsServerCall.AddToFullSet(Object.Services, RowsArray, True);
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateAmount","Count");
	StructureOfActions.Insert("RecalculateAmountWithVAT",StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateVATAmount",StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountOfManualDiscount","Count");
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountManualDiscount", New Structure("Clear, QuantityName", True, "Count"));
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountDiscountWithBonusPoints");
	StructureOfActions.Insert("ClearAutomaticDiscount");
	StructureOfActions.Insert("ClearAmountOfSettlements");
	StructureOfActions.Insert("FillInVATRateByPriceType", BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRateByPriceType(Object));
	
	FillParameters = New Structure;
	FillParameters.Insert("Date", Object.Date);
	FillParameters.Insert("Currency", Object.Currency);
	FillParameters.Insert("Organization", Object.Organization);
	FillParameters.Insert("PriceKind", PricesKind);
	FillParameters.Insert("CalculateSets", True);
	FillParameters.Insert("PopulationFields", "Price, PriceKind");
	FillParameters.Insert("ColumnsByValue", New Structure("Package", Catalogs.PackagesAndUnitsOfMeasure.EmptyRef()));
	
	PricesCalculated = EnterprisePricesFillingServer.FillInPrices(
		Object.Services,
		RowsArray, // Array of rows or selection structure
		FillParameters,
		StructureOfActions);
	
	CalculateFinalIndicatorsOfActsOfWorkPerformed(ThisObject);
	
	Return PricesCalculated;
	
EndFunction

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
	
	If TakeFromTemporaryStorage Then
		AppliedDiscounts = GetFromTempStorage(AddressOfAppliedDiscountsInTheTemporaryStorage);
		DiscountsMarkupsFillingServer.ApplyCalculationResult(Object, AppliedDiscounts);
	Else
		AppliedDiscounts = DiscountsMarkupsFillingServer.Calculate(Object, ParametersStructure1);
		AddressOfAppliedDiscountsInTheTemporaryStorage = PutToTempStorage(AppliedDiscounts, UUID);
	EndIf;
	
	Object.DiscountsAreCalculated = True;
	
	CalculateFinalIndicatorsOfActsOfWorkPerformed(ThisObject);
	
	TheStructureOfTheMessages = DiscountsMarkupsFillingServer.TheStructureOfTheMessages(Object);
	DiscountsMarkupsFillingServer.ConfigureShowMessagesCommand(Object, Items.ShowMessages);
	
	Return TheStructureOfTheMessages;
	
EndFunction

&AtServer
Procedure AssignManualDiscountOnServer(AmountOfDiscountMarkUp, Val SelectedRows, AddressInTempStorage)
	
	If AmountOfDiscountMarkUp <> 0 Then
		
		DiscountParameters = DiscountsMarkupsFillingServer.NewOptionsAssignManualDiscount();
		DiscountParameters.AutomaticDiscountsAreUsed = True;
		DiscountParameters.OnlyForActiveRows			 = False;
		DiscountParameters.CalculateAmountWithVAT			 = True;
		DiscountParameters.CalculateAmountOfSettlements_1	 = True;
		DiscountParameters.SelectedRows				 = SelectedRows;
		DiscountParameters.AddressInTempStorage		 = AddressInTempStorage;
		
		DiscountsMarkupsFillingServer.AssignAManualDiscount(Object, "Services", AmountOfDiscountMarkUp, DiscountParameters);
		
	Else
		DiscountsMarkupsFillingServer.CancelManualDiscounts(Object, "Services", True, True, True);
	EndIf;
	
EndProcedure

&AtServer
Procedure CalculateDiscountsMarginsOnOrderOnServer()
	
	Object.DiscountsMarkups.Clear();
	Object.BonusPointAccrual.Clear();
	
	Query = New Query(
	"SELECT
	|	MutualSettlementsExchangeRate.CourseNumerator * CurrencyExchangeRate.CourseDenominator / (CurrencyExchangeRate.CourseNumerator * MutualSettlementsExchangeRate.CourseDenominator) AS ConversionFactor_
	|INTO OrderCurrencyToDocumentCurrency
	|FROM
	|	InformationRegister.RelativeExchangeRates.SliceLast(&Date, Currency = &Currency AND BaseCurrency = &BaseCurrency) AS CurrencyExchangeRate
	|		LEFT JOIN InformationRegister.RelativeExchangeRates.SliceLast(
	|					&Date,
	|					Currency = &ARAPCurrency AND BaseCurrency = &BaseCurrency) AS MutualSettlementsExchangeRate
	|		ON (TRUE)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Services.SalesOrder AS SalesOrder,
	|	CAST(Services.Products AS Catalog.Products) AS Products,
	|	CAST(Services.Characteristic AS Catalog.ItemsCharacteristics) AS Characteristic,
	|	CAST(Services.RowCode AS NUMBER) AS RowCode,
	|	CAST(Services.ConnectionKey AS NUMBER) AS ConnectionKey,
	|	CAST(Services.Count AS NUMBER) AS Count
	|INTO DocumentServices
	|FROM
	|	&ServicesTable AS Services
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	GoodsFromOrder.Ref AS SalesOrder,
	|	GoodsFromOrder.RowCode AS RowCode,
	|	GoodsFromOrder.ConnectionKey AS ConnectionKey,
	|	ServicesOfCertificatesOfCompletedWorks.Count / GoodsFromOrder.Count AS ZoomRatio,
	|	GoodsFromOrder.PercentRateOfAutomaticDiscountMarkup AS PercentRateOfAutomaticDiscountMarkup,
	|	GoodsFromOrder.PercentRateOfManualDiscount AS PercentRateOfManualDiscount,
	|	GoodsFromOrder.DiscountMarkupAmount * (ServicesOfCertificatesOfCompletedWorks.Count / GoodsFromOrder.Count) * OrderCurrencyToDocumentCurrency.ConversionFactor_ AS DiscountMarkupAmount,
	|	GoodsFromOrder.ManualDiscount * (ServicesOfCertificatesOfCompletedWorks.Count / GoodsFromOrder.Count) * OrderCurrencyToDocumentCurrency.ConversionFactor_ AS ManualDiscount,
	|	GoodsFromOrder.AmountOfBonusPointsToDeduction * (ServicesOfCertificatesOfCompletedWorks.Count / GoodsFromOrder.Count) AS AmountOfBonusPointsToDeduction,
	|	GoodsFromOrder.AmountOfBonusPointsToDeductionInCurrency * (ServicesOfCertificatesOfCompletedWorks.Count / GoodsFromOrder.Count) * OrderCurrencyToDocumentCurrency.ConversionFactor_ AS AmountOfBonusPointsToDeductionInCurrency,
	|	GoodsFromOrder.AmountOfEarnedBonusPointsInCurrency * (ServicesOfCertificatesOfCompletedWorks.Count / GoodsFromOrder.Count) * OrderCurrencyToDocumentCurrency.ConversionFactor_ AS AmountOfEarnedBonusPointsInCurrency
	|FROM
	|	DocumentServices AS ServicesOfCertificatesOfCompletedWorks
	|		LEFT JOIN Document.SalesOrder.Goods AS GoodsFromOrder
	|		ON ServicesOfCertificatesOfCompletedWorks.RowCode = GoodsFromOrder.RowCode
	|			AND ServicesOfCertificatesOfCompletedWorks.Products = GoodsFromOrder.Products
	|			AND ServicesOfCertificatesOfCompletedWorks.Characteristic = GoodsFromOrder.Characteristic
	|			AND ServicesOfCertificatesOfCompletedWorks.SalesOrder = GoodsFromOrder.Ref
	|		LEFT JOIN OrderCurrencyToDocumentCurrency AS OrderCurrencyToDocumentCurrency
	|		ON (TRUE)
	|
	|UNION ALL
	|
	|SELECT
	|	GoodsFromOrder.Ref,
	|	GoodsFromOrder.RowCode,
	|	GoodsFromOrder.ConnectionKey,
	|	ServicesOfCertificatesOfCompletedWorks.Count / GoodsFromOrder.Count,
	|	GoodsFromOrder.PercentRateOfAutomaticDiscountMarkup,
	|	GoodsFromOrder.PercentRateOfManualDiscount,
	|	GoodsFromOrder.DiscountMarkupAmount * (ServicesOfCertificatesOfCompletedWorks.Count / GoodsFromOrder.Count) * OrderCurrencyToDocumentCurrency.ConversionFactor_,
	|	GoodsFromOrder.ManualDiscount * (ServicesOfCertificatesOfCompletedWorks.Count / GoodsFromOrder.Count) * OrderCurrencyToDocumentCurrency.ConversionFactor_,
	|	GoodsFromOrder.AmountOfBonusPointsToDeduction * (ServicesOfCertificatesOfCompletedWorks.Count / GoodsFromOrder.Count),
	|	GoodsFromOrder.AmountOfBonusPointsToDeductionInCurrency * (ServicesOfCertificatesOfCompletedWorks.Count / GoodsFromOrder.Count) * OrderCurrencyToDocumentCurrency.ConversionFactor_,
	|	GoodsFromOrder.AmountOfEarnedBonusPointsInCurrency * (ServicesOfCertificatesOfCompletedWorks.Count / GoodsFromOrder.Count) * OrderCurrencyToDocumentCurrency.ConversionFactor_
	|FROM
	|	DocumentServices AS ServicesOfCertificatesOfCompletedWorks
	|		LEFT JOIN Document.RequestForReturnOfGoodsFromCustomer.SubstituteGoods AS GoodsFromOrder
	|		ON ServicesOfCertificatesOfCompletedWorks.RowCode = GoodsFromOrder.RowCode
	|			AND ServicesOfCertificatesOfCompletedWorks.Products = GoodsFromOrder.Products
	|			AND ServicesOfCertificatesOfCompletedWorks.Characteristic = GoodsFromOrder.Characteristic
	|			AND ServicesOfCertificatesOfCompletedWorks.SalesOrder = GoodsFromOrder.Ref
	|		LEFT JOIN OrderCurrencyToDocumentCurrency AS OrderCurrencyToDocumentCurrency
	|		ON (TRUE)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	DiscountsMarkups.Ref AS SalesOrder,
	|	DiscountsMarkups.ConnectionKey AS ConnectionKey,
	|	DiscountsMarkups.DiscountMarkup AS DiscountMarkup,
	|	DiscountsMarkups.Sum * OrderCurrencyToDocumentCurrency.ConversionFactor_ AS Sum
	|FROM
	|	Document.SalesOrder.DiscountsMarkups AS DiscountsMarkups
	|		LEFT JOIN OrderCurrencyToDocumentCurrency AS OrderCurrencyToDocumentCurrency
	|		ON (TRUE)
	|WHERE
	|	(DiscountsMarkups.Ref, DiscountsMarkups.ConnectionKey) IN
	|			(SELECT
	|				DocumentServices.SalesOrder,
	|				DocumentServices.ConnectionKey
	|			FROM
	|				DocumentServices AS DocumentServices)
	|
	|UNION ALL
	|
	|SELECT
	|	DiscountsMarkups.Ref,
	|	DiscountsMarkups.ConnectionKey,
	|	DiscountsMarkups.DiscountMarkup,
	|	DiscountsMarkups.Sum * OrderCurrencyToDocumentCurrency.ConversionFactor_
	|FROM
	|	Document.RequestForReturnOfGoodsFromCustomer.DiscountsMarkups AS DiscountsMarkups
	|		LEFT JOIN OrderCurrencyToDocumentCurrency AS OrderCurrencyToDocumentCurrency
	|		ON (TRUE)
	|WHERE
	|	(DiscountsMarkups.Ref, DiscountsMarkups.ConnectionKey) IN
	|			(SELECT
	|				DocumentServices.SalesOrder,
	|				DocumentServices.ConnectionKey
	|			FROM
	|				DocumentServices AS DocumentServices)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TabularSection.Ref AS SalesOrder,
	|	TabularSection.ConnectionKey AS ConnectionKey,
	|	TabularSection.LoyaltyProgram AS LoyaltyProgram,
	|	TabularSection.LoyaltyProgram.BonusConversionCurrency AS BonusConversionCurrency,
	|	TabularSection.LoyaltyProgram.ConversionRateOfBonusesIntoCurrency AS ConversionRateOfBonusesIntoCurrency,
	|	DATEADD(TabularSection.AccrualDate, DAY,
	|		DATEDIFF(
	|			BEGINOFPERIOD(TabularSection.Ref.Date, DAY),
	|			BEGINOFPERIOD(&Date, DAY),
	|			DAY)
	|	) AS AccrualDate,
	|	CASE
	|		WHEN TabularSection.DateOfDeduction = DATETIME(1, 1, 1)
	|			THEN TabularSection.DateOfDeduction
	|		ELSE
	|			DATEADD(
	|				TabularSection.DateOfDeduction,
	|				DAY,
	|				DATEDIFF(
	|					BEGINOFPERIOD(TabularSection.Ref.Date, DAY),
	|					BEGINOFPERIOD(&Date, DAY),
	|					DAY))
	|	END AS DateOfDeduction,
	|	TabularSection.AmountOfBonusPoints AS AmountOfBonusPoints
	|FROM
	|	Document.SalesOrder.BonusPointAccrual AS TabularSection
	|WHERE
	|	(TabularSection.Ref, TabularSection.ConnectionKey) IN
	|			(SELECT
	|				DocumentServices.SalesOrder,
	|				DocumentServices.ConnectionKey
	|			FROM
	|				DocumentServices AS DocumentServices)
	| 
	|UNION ALL
	|
	|SELECT
	|	TabularSection.Ref,
	|	TabularSection.ConnectionKey,
	|	TabularSection.LoyaltyProgram,
	|	TabularSection.LoyaltyProgram.BonusConversionCurrency,
	|	TabularSection.LoyaltyProgram.ConversionRateOfBonusesIntoCurrency,
	|	TabularSection.AccrualDate,
	|	TabularSection.DateOfDeduction,
	|	TabularSection.AmountOfBonusPoints
	|FROM
	|	Document.RequestForReturnOfGoodsFromCustomer.BonusPointAccrual AS TabularSection
	|WHERE
	|	(TabularSection.Ref, TabularSection.ConnectionKey) IN
	|			(SELECT
	|				DocumentServices.SalesOrder,
	|				DocumentServices.ConnectionKey
	|			FROM
	|				DocumentServices AS DocumentServices)
	|");
	
	Query.SetParameter("Date", ?(ValueIsFilled(Object.Date), Object.Date, CurrentSessionDate()));
	Query.SetParameter("Currency", Object.Currency);
	Query.SetParameter("ARAPCurrency", Object.ARAPCurrency);
	Query.SetParameter("ServicesTable", Object.Services.Unload(, "SalesOrder, Products, Characteristic, RowCode, Count, ConnectionKey"));
	Query.SetParameter("BaseCurrency", SettingsValueCached.DefaultBaseCurrency());
	
	QueryBatch = Query.ExecuteBatch();
	
	DiscountsOrderMargins = QueryBatch[3].Unload();
	
	UseLoyaltyPrograms = GetFunctionalOption("UseLoyaltyPrograms");
	If UseLoyaltyPrograms Then
	
		AccrualOfBonusPointsOfOrder = QueryBatch[4].Unload();
	
		LoyaltyProgram = New Structure("LoyaltyProgram, 
			|BonusConversionCurrency, 
			|ConversionRateOfBonusesIntoCurrency,
			|StructureOfCurrencyConversionRates,
			|StructureOfDocumentExchangeRates");
		
		LoyaltyPrograms = AccrualOfBonusPointsOfOrder.Copy();
		
		LoyaltyPrograms.GroupBy("LoyaltyProgram, 
			|BonusConversionCurrency, 
			|ConversionRateOfBonusesIntoCurrency");
		
		If LoyaltyPrograms.Count() > 1 Then
			
			UseLoyaltyPrograms = False;
			
		ElsIf LoyaltyPrograms.Count() = 1 Then
			FillPropertyValues(LoyaltyProgram, LoyaltyPrograms[0]);
			
			If Object.Currency <> LoyaltyProgram.BonusConversionCurrency Then
				
				LoyaltyProgram.StructureOfCurrencyConversionRates = ProcessingOfExchangeRatesTM.GetCurrencyRate(LoyaltyProgram.BonusConversionCurrency, 
					CurrentSessionDate(),
					SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Object.Organization));
				
				LoyaltyProgram.StructureOfDocumentExchangeRates = ProcessingOfExchangeRatesTM.GetCurrencyRate(Object.Currency, 
					CurrentSessionDate(),
					SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Object.Organization));
				
			EndIf;
		EndIf;
		
	EndIf;
	
	RowsToProcess = New Array();
	StructureOfActions = New Structure;
	CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountManualDiscount", New Structure("Clear, QuantityName", False, "Count"));
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountAutomaticDiscount", New Structure("Clear", False));
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountDiscountWithBonusPoints");
	StructureOfActions.Insert("ClearAmountOfSettlements");
	StructureOfActions.Insert("RecalculateAmount", "Count");
	
	ServiceSelection = QueryBatch[2].Select();
	While ServiceSelection.Next() Do
		
		FoundRows = Object.Services.FindRows(New Structure("SalesOrder, RowCode", ServiceSelection.SalesOrder, ServiceSelection.RowCode));
		If FoundRows.Count() = 0 Then
			Continue;
		EndIf;
		
		TableRow = FoundRows[0];
		
		FieldList = "PercentRateOfAutomaticDiscountMarkup, PercentRateOfManualDiscount";
		
		FillPropertyValues(TableRow, ServiceSelection, FieldList);
		
		TableRow.DiscountMarkupAmount = Round(ServiceSelection.DiscountMarkupAmount, 2);
		TableRow.ManualDiscount = Round(ServiceSelection.ManualDiscount , 2);
		TableRow.AmountOfEarnedBonusPointsInCurrency = Round(ServiceSelection.AmountOfEarnedBonusPointsInCurrency, 2);
		TableRow.AmountOfBonusPointsToDeductionInCurrency = Round(ServiceSelection.AmountOfBonusPointsToDeductionInCurrency, 2);
		TableRow.AmountOfBonusPointsToDeduction = Round(ServiceSelection.AmountOfBonusPointsToDeduction, 2);
		
		RowsToProcess.Add(TableRow);
		
		AmountForAllocation = TableRow.DiscountMarkupAmount + TableRow.AmountOfEarnedBonusPointsInCurrency;
		If TableRow.ConnectionKey <> 0 Then
			
			FoundRows = DiscountsOrderMargins.FindRows(New Structure("SalesOrder, ConnectionKey", TableRow.SalesOrder, TableRow.ConnectionKey));
			If FoundRows <> 0 Then
				For Each OrderDiscountsRow In FoundRows Do
					
					DiscountsRow = Object.DiscountsMarkups.Add();
					FillPropertyValues(DiscountsRow, OrderDiscountsRow);
					DiscountsRow.Sum = ServiceSelection.ZoomRatio * DiscountsRow.Sum;
					
					AmountForAllocation = AmountForAllocation - DiscountsRow.Sum;
				EndDo;
				If AmountForAllocation <> 0 Then
					DiscountsRow.Sum = DiscountsRow.Sum + AmountForAllocation;
				EndIf;
			EndIf;
			
		EndIf;
		
		If UseLoyaltyPrograms Then
			AmountForAllocation = TableRow.AmountOfEarnedBonusPointsInCurrency;

			If ValueIsFilled(LoyaltyProgram.BonusConversionCurrency)
				And Object.Currency <> LoyaltyProgram.BonusConversionCurrency Then
				
				AmountForAllocation = ProcessingOfExchangeRatesTM.ConvertAtRate(
					AmountForAllocation,
					LoyaltyProgram.StructureOfDocumentExchangeRates,
					LoyaltyProgram.StructureOfCurrencyConversionRates);
					
			EndIf;
			
			If AmountForAllocation <> 0
				And ValueIsFilled(LoyaltyProgram.ConversionRateOfBonusesIntoCurrency) Then
				
				AmountForAllocation = AmountForAllocation / LoyaltyProgram.ConversionRateOfBonusesIntoCurrency;
			EndIf;
			
			If TableRow.ConnectionKey <> 0 Then
			
				FoundRows = AccrualOfBonusPointsOfOrder.FindRows(New Structure("SalesOrder, ConnectionKey", TableRow.SalesOrder, ServiceSelection.ConnectionKey));
				If FoundRows.Count() <> 0 Then
					
					For Each OrderBonusPointsLine In FoundRows Do
						
						BonusPointsLine = Object.BonusPointAccrual.Add();
						FillPropertyValues(BonusPointsLine, OrderBonusPointsLine);
						BonusPointsLine.AmountOfBonusPoints = ServiceSelection.ZoomRatio * BonusPointsLine.AmountOfBonusPoints;
						
						AmountForAllocation = AmountForAllocation - BonusPointsLine.AmountOfBonusPoints;
						
					EndDo;
					
					If AmountForAllocation <> 0 Then
						DiscountsRow.Sum = DiscountsRow.Sum + AmountForAllocation;
					EndIf;
					
				EndIf;
			EndIf;
		EndIf;
		
	EndDo;
	
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		RowsToProcess,
		StructureOfActions,
		Object.Services,
		CachedValues);
	
	Object.DiscountsAreCalculated = True;
	CalculateFinalIndicatorsOfActsOfWorkPerformed(ThisObject);
	
EndProcedure

&AtServer
Procedure CancelManualDiscountsOnServer()
	
	DiscountsMarkupsFillingServer.CancelManualDiscounts(Object, "Services", True, True, True);
	
EndProcedure

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
Procedure DeleteTSDiscountMarkUpLines(LineTSServices)
	
	If ValueIsFilled(LineTSServices.ConnectionKey) Then
		
		For Each RowToDelete In Object.DiscountsMarkups.FindRows(New Structure("ConnectionKey", LineTSServices.ConnectionKey)) Do
			
			Object.DiscountsMarkups.Delete(RowToDelete);
			
		EndDo;
		
	EndIf;
	
EndProcedure

&AtServer
Procedure MessagesReceived(Messages)
	
	DiscountsMarkupsFillingServer.SaveSpentMessages(Object, Messages);
	DiscountsMarkupsFillingServer.ConfigureShowMessagesCommand(Object, Items.ShowMessages);
	
EndProcedure

&AtClient
Procedure VerificationOfPaymentWithBonusPoints()
	
	If Not UseLoyaltyPrograms
		Or Not PaymentWithBonusPoints Then
		Return;
	EndIf;
	
	ClearMessages();
	ApplyPaymentWithBonusPointsClient(, True);
	
EndProcedure

&AtClient
Procedure ApplyPaymentWithBonusPointsClient(AddressInTempStorage = Undefined, DisplayMessage_ = False)
	
	If AddressInTempStorage = Undefined And (Not PaymentWithBonusPoints Or Not Object.Services.Count()) Then
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
		TableOfGoods = Object.Services;
		DeletingPayment = True;
	EndIf;   
	
	CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateAmount", "Count");
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountAutomaticDiscount", New Structure("Clear", False));
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountManualDiscount", New Structure("Clear, RecalculateAmountOfManualDiscount_, QuantityName", False, False, "Count"));
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountDiscountWithBonusPoints");
	StructureOfActions.Insert("ClearAmountOfSettlements");
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	
	AdjustmentIsCompleted = False; 
	
	RowsToProcess = New Array;
	For Each TableRow In TableOfGoods Do
		
		If DeletingPayment Then
			If ValueIsFilled(TableRow.SalesOrder) Then
				Continue;
			EndIf;
			TSRow = TableRow;
			TSRow.AmountOfBonusPointsToDeduction        = 0;
			TSRow.AmountOfBonusPointsToDeductionInCurrency = 0;
		Else
			TSRow = Object.Services.FindRows(New Structure("ConnectionKey", TableRow.ConnectionKey))[0];
			TSRow.AmountOfBonusPointsToDeduction        = TableRow.AmountOfBonusPointsToDeduction;
			TSRow.AmountOfBonusPointsToDeductionInCurrency = TableRow.AmountOfBonusPointsToDeductionInCurrency;
		EndIf;
		
		RowsToProcess.Add(TSRow);
		
		AdjustmentIsCompleted = True;
		
	EndDo;
	
	ProcessedCollection = ?(DeletingPayment, TableOfGoods, Object.Services);
	
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		RowsToProcess,
		StructureOfActions,
		ProcessedCollection,
		CachedValues);
	
	If AdjustmentIsCompleted Then
		
		PaymentWithBonusPoints = Not DeletingPayment;
		
		CalculateFinalIndicatorsOfActsOfWorkPerformed(ThisObject);
		
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

&AtClient
Procedure HandlingSelectionSelectionOnClient(ValueSelected)
	
	ClearMessages();
	ApplyPaymentWithBonusPointsClient(, True);
	ProcessingSelectionOfSelectionOnServer(ValueSelected);
	DiscountsMarkupsFillingClient.ResetDiscountsCalculatedFlag(ThisObject);
	
EndProcedure

&AtClient
Procedure SelectionOfServicesFromOrder()
	
	ArrayOfStringCodes = New Array;
	AnArrayOfOrders = New Array;
	
	If Object.Services.Count() > 0 Then
		For Each TSRow In Object.Services Do
			
			If TSRow.RowCode <> 0 And ValueIsFilled(TSRow.SalesOrder) Then
				ArrayOfStringCodes.Add(New Structure("RowCode,SalesOrder", TSRow.RowCode, TSRow.SalesOrder));
			EndIf;
			If AnArrayOfOrders.Find(TSRow.SalesOrder)=Undefined Then
				AnArrayOfOrders.Add(TSRow.SalesOrder);	
			EndIf;
			
		EndDo;
	Else
		AnArrayOfOrders.Add(Object.SalesOrder);
	EndIf;
	
	PickingParameters = New Structure;
	PickingParameters.Insert("SalesOrder", Object.SalesOrder);
	PickingParameters.Insert("DocumentCurrency", Object.Currency);
	PickingParameters.Insert("Document", Object.Ref);
	PickingParameters.Insert("ArrayOfStringCodes", ArrayOfStringCodes);
	PickingParameters.Insert("AnArrayOfOrders",AnArrayOfOrders);
	PickingParameters.Insert("Partner", Object.Partner);
	PickingParameters.Insert("Counterparty", Object.Counterparty);
	PickingParameters.Insert("Contract", Object.Contract);
	PickingParameters.Insert("Organization", Object.Organization);
	PickingParameters.Insert("Terms", Object.Terms);
	PickingParameters.Insert("SalesOpportunity", Object.SalesOpportunity);
	PickingParameters.Insert("ARAPCurrency", Object.ARAPCurrency);
	PickingParameters.Insert("VATTaxation", Object.VATTaxation);
	PickingParameters.Insert("PriceIncludesVAT", Object.PriceIncludesVAT);
	PickingParameters.Insert("ARAPObjectSettings", Object.ARAPObjectSettings);
	PickingParameters.Insert("Date", Object.Date);
	PickingParameters.Insert("LineOfBusiness", Object.LineOfBusiness);
	PickingParameters.Insert("UseAdvancedFeaturesOfSalesOrder", UseAdvancedFeaturesOfSalesOrder);
	PickingParameters.Insert("Department", Object.Department);
	
	OpenForm(
		"Document.CustomerInvoiceServices.Form.SelectionFormOfServicesFromOrder",
		PickingParameters,
		ThisForm,,,, Undefined, FormWindowOpeningMode.LockOwnerWindow);

EndProcedure

&AtServer
Procedure ProcessingSelectionOfSelectionOnServer(ValueSelected)
	
	ServicesTable = GetFromTempStorage(ValueSelected.GoodsAddressInStorage);
	CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValuesServices();
	ParametersFillInVATRate = BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRate(Object);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
	StructureOfActions.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));
	StructureOfActions.Insert("FillInVATRate", ParametersFillInVATRate);
	StructureOfActions.Insert("FillInVATRateByPriceType", BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRateByPriceType(Object));
	
	StructureOfActions.Insert("FillInContent",
		BatchProcessingOfTablePartClientServer.GetStructureOfFillingInServiceContentInTSLine(
			Object, True));
			
	StructureOfActions.Insert("FillInSubdivisionInTSLine",
		New Structure("Department", Object.Department));
		
	AddActionsToStructureWhenQuantityChanges(StructureOfActions, Object);
	
	RowsToProcess = New Array();
	For Each ServiceLine_1 In ServicesTable Do
		
		CurrentRow = Object.Services.Add();
		FillPropertyValues(CurrentRow, ServiceLine_1, "ProductsInSet, ItemVariantOfSet, Products,
			| Characteristic, PriceKind, Price, Count, Sum, ManualDiscount, PercentRateOfManualDiscount, WithAssignment");
		CurrentRow.SetIndex = ?(ValueIsFilled(CurrentRow.ProductsInSet), 1, 0);
		LinesOfBusinessClientServer.FillAssignmentByFlagSeparately(ThisObject, CurrentRow);
		
		RowsToProcess.Add(CurrentRow);
		
	EndDo;
	
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		RowsToProcess,
		StructureOfActions,
		Object.Services,
		CachedValues);
	
	CalculateFinalIndicatorsOfActsOfWorkPerformed(ThisObject);
	
	StructureCharacteristicsOfProducts = New Structure;
	StructureCharacteristicsOfProducts.Insert("FillInFeatureAttribute",
			New Structure("Products", "ItemVariantsAreUsed"));
			
	ProductsServer.FillInServiceDetailsForProductInCollection(Object.Services, StructureCharacteristicsOfProducts);
	SetsServer.FillInServiceDetails(ThisObject, "Services");
	
EndProcedure

#EndRegion

#Region BarcodesAndTradeEquipment

&AtClient
Procedure ProcessBarcodes(BarcodeData_5)
	
	ClearMessages();
	
	If Not BarcodingOfItemsClient.BarcodesAreValid(BarcodeData_5) Then
		Return;
	EndIf;
	
	ChangeQuantity = Not Object.InvoiceByOrders;
	ParametersFillInVATRate = BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRate(Object);
	
	StructureOfActionsWithAddedStrings = New Structure;
	AddActionsToStructureWhenQuantityChanges(StructureOfActionsWithAddedStrings, Object);
	LinesOfBusinessClientServer.StructureOfInsertActionsWhenAddingRow(ThisObject, StructureOfActionsWithAddedStrings);
	StructureOfActionsWithAddedStrings.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
	StructureOfActionsWithAddedStrings.Insert("FillInContent", BatchProcessingOfTablePartClientServer.GetStructureOfFillingInServiceContentInTSLine(Object, True));
	StructureOfActionsWithAddedStrings.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));
	StructureOfActionsWithAddedStrings.Insert("FillInVATRate", ParametersFillInVATRate);
	StructureOfActionsWithAddedStrings.Insert("FillInVATRateByPriceType", BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRateByPriceType(Object));
	
	StructureOfActionsWithModifiedStrings = New Structure;
	AddActionsToStructureWhenQuantityChanges(StructureOfActionsWithModifiedStrings, Object);

	StructureOfActions = BarcodingOfItemsClient.BarcodeProcessingParameters();
	StructureOfActions.Barcodes                              = BarcodeData_5;
	StructureOfActions.StructureOfActionsWithAddedStrings = StructureOfActionsWithAddedStrings;
	StructureOfActions.StructureOfActionsWithModifiedStrings  = StructureOfActionsWithModifiedStrings;
	StructureOfActions.ColumnNameQuantity                   = "Count";
	StructureOfActions.NotUsePackages                 = True;
	StructureOfActions.TSName                                  = "Services";
	StructureOfActions.ChangeQuantity                     = ChangeQuantity;
	StructureOfActions.ServicesOnly                           = True;
	StructureOfActions.CalculateSets                     = True;
	
	ProcessBarcodesServer(StructureOfActions, CachedValues);
	
	BarcodingOfItemsClient.ProcessUnknownBarcodes(StructureOfActions, CachedValues, ThisObject);
	
	If ChangeQuantity Then
		CalculateFinalIndicatorsOfActsOfWorkPerformed(ThisObject);
	EndIf;
	
	If StructureOfActions.CurrentRow <> Undefined Then
		Items.Services.CurrentRow = StructureOfActions.CurrentRow;
	EndIf;
	
EndProcedure

&AtServer
Procedure ProcessBarcodesServer(StructureOfActionParameters, CachedValues)
	
	BarcodingOfItemsServer.ProcessBarcodes(ThisObject, Object, StructureOfActionParameters, CachedValues);
	
EndProcedure

#EndRegion

#Region WorkingWithClipboard

&AtServer
Procedure CopyLinesOnServer()
	
	ProcessingOfTabularForms.CopyRowsToClipboard(Object.Services, Items.Services.SelectedRows);
	
EndProcedure

&AtServer
Procedure GetLinesFromClipboard()
	
	ArrayOfProductTypes = New Array;
	ArrayOfProductTypes.Add(PredefinedValue("Enum.ItemsTypes.OperationService"));
	ArrayOfProductTypes.Add(PredefinedValue("Enum.ItemsTypes.Work_5"));
	
	FilterParameters = New Map;
	FilterParameters.Insert("Products.ItemsType", ArrayOfProductTypes);
	
	Columns = "Products,Characteristic,Package,Count,PriceKind,Price,
		|PercentRateOfManualDiscount,ManualDiscount,Department,ProductsInSet,ItemVariantOfSet";
	
	ServicesTable = ProcessingOfTabularForms.RowsFromClipboard(FilterParameters, Columns);
	
	If Not ValueIsFilled(ServicesTable) Then
		Return;
	EndIf;
	
	ParametersFillInVATRate = BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRate(Object);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
	StructureOfActions.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));
	StructureOfActions.Insert("FillInVATRate", ParametersFillInVATRate);
	StructureOfActions.Insert("FillInVATRateByPriceType", BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRateByPriceType(Object));
	
	StructureOfActions.Insert("FillInContent", 
		BatchProcessingOfTablePartClientServer.GetStructureOfFillingInServiceContentInTSLine(
			Object, True));
			
	AddActionsToStructureWhenQuantityChanges(StructureOfActions,Object);
	If ServicesTable.Columns.Find("ManualDiscount") <> Undefined Then
		StructureOfActions.RecalculateAmountTakingIntoAccountManualDiscount.Insert("RecalculateAmountOfManualDiscount_", False);
	EndIf;
	LinesOfBusinessClientServer.StructureOfInsertActionsWhenAddingRow(ThisForm, StructureOfActions);
	
	ParametersForFillingInPriceType = BatchProcessingOfTablePartClientServer.ParametersForFillingInPriceTypeInTSLine("PriceKind");
	ParametersForFillingInPriceType.FilterParameters.PriceIncludesVAT = Object.PriceIncludesVAT;
	ParametersForFillingInPriceType.FilterParameters.UseWhileSellingToCustomers = True;
	StructureOfActions.Insert("CheckFillInPriceView", ParametersForFillingInPriceType);
	
	StructureOfActions.Insert("FillInSalePrice",
		BatchProcessingOfTablePartClientServer.ParametersForFillingInPriceInTSLine(Object));
	
	RowsToProcess = New Array;
	
	For Each ServiceLine_1 In ServicesTable Do
		
		CurrentRow = Object.Services.Add();
		FillPropertyValues(CurrentRow, ServiceLine_1);
		CurrentRow.SetIndex = ?(ValueIsFilled(CurrentRow.ProductsInSet), 1, 0);
		If Not UseDiscountAdjustmentsInSales Then
			CurrentRow.PercentRateOfManualDiscount = 0;
			CurrentRow.ManualDiscount = 0;
		EndIf;
		
		RowsToProcess.Add(CurrentRow);
		
	EndDo;
	
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		RowsToProcess,
		StructureOfActions,
		Object.Services);
	
	CalculateFinalIndicatorsOfActsOfWorkPerformed(ThisObject);
	
	StructureCharacteristicsOfProducts = New Structure;
	StructureCharacteristicsOfProducts.Insert("FillInFeatureAttribute",
			New Structure("Products", "ItemVariantsAreUsed"));

	ProductsServer.FillInServiceDetailsForProductInCollection(Object.Services, StructureCharacteristicsOfProducts);
	SetsServer.FillInServiceDetails(ThisObject, "Services");
	
EndProcedure

&AtServer
Procedure SetAvailabilityOfClipboardCommands()
	
	ItemArray = New Array();
	ItemArray.Add("ServicesInsertRows");
	ItemArray.Add("ServicesContextMenuInsertRows");
	
	TMCommonUseClientServer.SetPropertyOfFormElements(Items, ItemArray, "Enabled",
		ProcessingOfTabularForms.ThereAreLinesInClipboard() And Not Object.InvoiceByOrders);
	
EndProcedure

&AtClient
Procedure SetAvailabilityOfClipboardCommandsOnClient()
	
	ItemArray = New Array();
	ItemArray.Add("ServicesInsertRows");
	ItemArray.Add("ServicesContextMenuInsertRows");
	
	TMCommonUseClientServer.SetPropertyOfFormElements(Items, ItemArray, "Enabled", Not Object.InvoiceByOrders);
	
EndProcedure

#EndRegion

#Region Sets

&AtClientAtServerNoContext
Function DialColumns(Form)
	
	Columns = New Array;
	Columns.Add("Products");
	Columns.Add("Characteristic");
	
	Columns.Add("Price");
	Columns.Add("PriceKind");
	Columns.Add("Count");
	
	If Form.UseDiscountAdjustmentsInSales Then
		Columns.Add("PercentRateOfManualDiscount");
		Columns.Add("ManualDiscount");
	EndIf;
	If Form.UseDiscountsMarkupsInSales Then
		Columns.Add("PercentRateOfAutomaticDiscountMarkup");
		Columns.Add("DiscountMarkupAmount");
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
		SetsClient.WhenRemovingComponents(ThisForm, "Services", AdditionalParameter);
	ElsIf SetsClient.DeleteEntireSetAction(Action) Then
		WhenRemovingComponentsOnServer("Services", AdditionalParameter);
	EndIf;
	
	CalculateFinalIndicatorsOfActsOfWorkPerformed(ThisObject);
	
EndProcedure

&AtServer
Procedure WhenRemovingComponentsOnServer(TSName, AdditionalParameter)
	SetsServer.WhenRemovingComponents(ThisForm, TSName, AdditionalParameter);
EndProcedure

&AtServer
Function SetAddressInTemporaryStorage(Var_Parameters)
	
	Return SetsServer.SetAddressInTemporaryStorage(ThisForm, Var_Parameters, "Services");
	
EndFunction

&AtServer
Procedure AtEndOfEditingSet(AddressInTempStorage)
	
	StructureOfActionsWithAddedStrings = New Structure;
	StructureOfActionsWithAddedStrings.Insert("ClearAmountOfSettlements");
	StructureOfActionsWithAddedStrings.Insert("FillInContent", BatchProcessingOfTablePartClientServer.GetStructureOfFillingInServiceContentInTSLine(Object, True));
	StructureOfActionsWithAddedStrings.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));
	StructureOfActionsWithAddedStrings.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
	StructureOfActionsWithModifiedStrings = New Structure;
	StructureOfActionsWithModifiedStrings.Insert("ClearAmountOfSettlements");
	
	DataParameters = New Structure;
	DataParameters.Insert("Data", GetFromTempStorage(AddressInTempStorage));
	DataParameters.Insert("StructureOfActionsWithModifiedStrings", StructureOfActionsWithModifiedStrings);
	DataParameters.Insert("StructureOfActionsWithAddedStrings", StructureOfActionsWithAddedStrings);
	DataParameters.Insert("DialColumns", DialColumns(ThisForm));
	
	SetsServer.AtEndOfEditingSet(ThisForm, "Services", DataParameters);
	
	CalculateFinalIndicatorsOfActsOfWorkPerformed(ThisObject);
	
EndProcedure

#EndRegion

#Region Other

&AtServer
Procedure SetUncheckSeparately(Set)
	LinesOfBusinessServer.SetUncheckSeparately(ThisObject, Set);
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
											
	ProductsServer.FillInServiceDetailsForProductInCollection(Object.Services,ParametersForFillingInBankingDetails);
	
	SetsServer.FillInServiceDetails(ThisForm, "Services");
	
EndProcedure

&AtClient
Procedure Attachable_CloseForm()
	
	If IsOpen() Then
		Close();
	EndIf;
	
EndProcedure

&AtServer
Procedure OnReadCreateAtServer()
	
	UsePaymentSchedules       					= GetFunctionalOption("UsePaymentSchedules");
	UseCustomerInvoicesForSeveralOrders = GetFunctionalOption("UseCustomerInvoicesForSeveralOrders");
	ToUseTermsOfSales                    = GetFunctionalOption("ToUseTermsOfSales");
	DocumentCurrency = Object.Currency;
	ARAPCurrency = Object.ARAPCurrency;
	LocalAccountingCurrency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Object.Organization);
	
	ResponsiblePersonsServer.FillInManagerSelectionList_(Items.Manager, Object);
	
	If Not ToUseTermsOfSales Then
		
		PriceTypeSelectionParameters = SettingsValueCached.ParametersForSelectingDefaultPriceType();
	
		PriceTypeSelectionParameters.PriceIncludesVAT                           = Object.PriceIncludesVAT;
		PriceTypeSelectionParameters.UseWhileSellingToCustomers                    = True;
		PriceTypeSelectionParameters.Status                 = Enums.StatusesOfPriceTypeValidity.Valid;
		
		DefaultPriceType = SettingsValueCached.DefaultPriceType(PriceTypeSelectionParameters);
	EndIf;
	
	UseLinesOfBusiness               = GetFunctionalOption("UseIncomeAccountingByLinesOfBusiness");
	LinesOfBusinessServer.OnReadCreateAtServer(ThisObject);
	
	SetAvailabilityOfItemsByStatusServer();
	UpdateOrderInformation();
	CalculateFinalIndicatorsOfActsOfWorkPerformed(ThisObject);
	SalesServer.SetContractAvailability(Object, Items.Contract.Enabled, Items.Contract.Visible);
	
	Contract = Object.Contract;
	
	FillInServiceDetailsForProductRange();
	SetVisibilityOfPartnerField(ThisForm);
	UpdateTextOfInvoiceIssued();
	
	BasisChanged = False;
	If AccessRight("Update", Metadata.Documents.CustomerInvoiceServices) Then
		PrintBasisTable.Load(Documents.CustomerInvoiceServices.PrintBasisTable(Object));
		If ValueIsFilled(Object.Basis) Then
			BaseStructure = Documents.CustomerInvoiceServices.StructureOfBaseForPrinting(Object);
			BasisChanged = (TrimAll(Object.Basis) <> BaseStructure.Basis) 
				Or (TrimAll(Object.BaseDocumentNumber) <> BaseStructure.BaseDocumentNumber)
				Or (Object.ReferenceDocumentDateForPrintForms <> BaseStructure.ReferenceDocumentDateForPrintForms);
		EndIf;
	EndIf;
	
	SetVisibilityOfShipmentBanToPartner();
		
	FillParameters = Documents.CustomerInvoiceServices.ParametersForFillingInSalesVATTaxation(Object);
	VATAccountingERP.FillInSalesVATTaxSelectionList(Items.VATTaxation, Object.VATTaxation, FillParameters, VATAccountingCachedParameterValues);
	
	If Not Object.InvoiceByOrders Then
		PaymentWithBonusPoints = Object.Services.Total("AmountOfBonusPointsToDeduction") <> 0
							Or Object.Services.Total("AmountOfBonusPointsToDeductionInCurrency") <> 0;
	EndIf;
	
	DocumentDate = ?(Parameters.Key.IsEmpty(), CurrentSessionDate(), Object.Date);
	RetailSalesClientServer.SetAvailabilityOfBonusPointsPaymentTeams(Items, DocumentDate);
	
EndProcedure

&AtClientAtServerNoContext
Procedure CalculateFinalIndicatorsOfActsOfWorkPerformed(Form)
	
	AmountTotal = Form.Object.Services.Total("Sum");
	AutoDiscountAmount   = Form.Object.Services.Total("DiscountMarkupAmount");
	ManualDiscount = Form.Object.Services.Total("ManualDiscount");
	AmountAmountOfBonusPointsToBeDebitedInCurrency = Form.Object.Services.Total("AmountOfBonusPointsToDeductionInCurrency");
	
	Form.DiscountAmount       = AutoDiscountAmount + ManualDiscount + AmountAmountOfBonusPointsToBeDebitedInCurrency;

	Form.AmountTotal = Form.Object.Services.Total("AmountIncludingVAT");
	Form.VATAmount   = Form.Object.Services.Total("VATAmount");
	
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
Function AddActionsToStructureWhenQuantityChanges(StructureOfActions, Object)
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountManualDiscount", New Structure("Clear, QuantityName", False, "Count"));
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountAutomaticDiscount", New Structure("Clear", True));
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountDiscountWithBonusPoints");
	StructureOfActions.Insert("ClearAmountOfSettlements");
	StructureOfActions.Insert("RecalculateAmount", "Count");
	
EndFunction

&AtServer
Procedure FillInDefaultContract()
			
	If Object.ARAPObjectSettings = Enums.ARAPObjectSettings.ByCounterpartyContracts 
		And UseLinesOfBusiness Then
	
		Contract = SalesServer.GetDefaultContract(Object, 
															Enums.BusinessTransactions.SaleToCustomer, 
															Object.ARAPCurrency, 
															Object.LineOfBusiness);
	Else
															
		Contract = SalesServer.GetDefaultContract(Object, 
															Enums.BusinessTransactions.SaleToCustomer, 
															Object.ARAPCurrency);
	EndIf;		
		
	If Contract <> Object.Contract Then
		Object.Contract = Contract;
		ForeignCurrencyTransaction = Object.ForeignCurrencyTransaction;
		ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisObject, "Contract");
		If ForeignCurrencyTransaction <> Object.ForeignCurrencyTransaction Then
			Object.CompanyBankAccount = Catalogs.CompaniesBankAccounts.EmptyRef();
		EndIf;
		FillBaseForPrinting();
		SalesServer.FillInBankAccountsUnderAgreement(Object.Contract, Object.CompanyBankAccount, Object.CounterpartyBankAccount);
	EndIf;
		
EndProcedure

&AtServer
Function FillInFromOrderServer()
	
	Object.Services.Clear();
	
	If UseCustomerInvoicesForSeveralOrders Then
		AnArrayOfOrders = Undefined;
	Else
		AnArrayOfOrders = New Array();
		AnArrayOfOrders.Add(Object.SalesOrder);
	EndIf;
	
	FillParameters = New Structure;
	FillParameters.Insert("UseAdvancedFeaturesOfSalesOrder", UseAdvancedFeaturesOfSalesOrder);
	FillParameters.Insert("DisplayMessage_1", False);
	
	Documents.CustomerInvoiceServices.FillByOrderBalances(
		Object,
		Object.Services,
		Object.DiscountsMarkups,
		Object.BonusPointAccrual,
		AnArrayOfOrders,
		FillParameters);
	
	UpdateOrderInformation();
	
	FillInServiceDetailsForProductRange();
	FillBaseForPrinting();
	
	CalculateFinalIndicatorsOfActsOfWorkPerformed(ThisObject);
	
EndFunction

&AtServer
Procedure UpdateOrderInformation()
	
	ParametersOfUpdate = OrdersServer.ParametersForUpdatingOrderInformationInForm();
	
	ParametersOfUpdate.PropsNameOrderList         = "OrderList";
	ParametersOfUpdate.OrderPathInHeader                  = "Object.SalesOrder";
	ParametersOfUpdate.TitleLabelName               = "LabelHeaderSalesOrders";
	ParametersOfUpdate.NameOfColumnGroupInTableSection   = "ServicesGroupCustomerOrder";
	ParametersOfUpdate.OrderNameInTablePart          = "SalesOrder";
	ParametersOfUpdate.UseOrdersInTabularSection = UseCustomerInvoicesForSeveralOrders;

	OrdersServer.UpdateOrderInformationInForm(ThisForm, Object.Services, ParametersOfUpdate);
	
	UseAdvancedFeaturesOfSalesOrder = UseAdvancedFeaturesOfSalesOrder();
	
EndProcedure

&AtServer
Procedure SetAvailabilityOfItemsByStatusServer()
	
	ItemArray = New Array;
	
	If Not Object.InvoiceByOrders Then
		ItemArray.Add("Date");
	EndIf;
	
	// Header Controls
	ItemArray.Add("Partner");
	ItemArray.Add("Terms");
	ItemArray.Add("Contract");
	
	ItemArray.Add("PriceIncludesVAT");
	ItemArray.Add("Organization");
	ItemArray.Add("Counterparty");
	ItemArray.Add("VATTaxation");
	ItemArray.Add("ActOfCompletedWorkOnTheOrder");
	ItemArray.Add("AcceptanceNoteForOrders");
	
	ItemArray.Add("Services;BeforeAddRow,BeforeDeleteRow,BeforeRowChange");
	
	ItemArray.Add("AddServices");
	ItemArray.Add("CopyServices");
	ItemArray.Add("ServicesContextMenuAdd");
	ItemArray.Add("CopyContextMenuServices");
	
	ItemArray.Add("ServicesProducts");
	ItemArray.Add("ServicesContent");
	ItemArray.Add("ServicesRowCode");
	ItemArray.Add("ServicesCharacteristic");
	ItemArray.Add("ServicesPriceKind");
	ItemArray.Add("ServicesPercentRateOfManualDiscount");
	ItemArray.Add("ServicesManualDiscount");
	ItemArray.Add("ServicesVATRate");
	ItemArray.Add("ServicesSum");
	ItemArray.Add("ServicesVATAmount");
	
	ItemArray.Add("ServicesSetComposition");
	ItemArray.Add("ServicesInsertRows");
	ItemArray.Add("BarcodeSearchServices");
	ItemArray.Add("ServicesImportDataFromPDT");
	ItemArray.Add("ServicesToSplitTheString");
	ItemArray.Add("ServicesContextMenuSplitRow");
	ItemArray.Add("ServicesOpenSelection");
	ItemArray.Add("ServicesImportFromExternalFile");
	ItemArray.Add("GoodsFillInTheDepartment");
	
	ItemArray.Add("ServicesAssignAutomaticDiscounts");
	ItemArray.Add("ServicesFillThePricesByTermsOfSales");
	ItemArray.Add("ServicesFillInPricesOfSelectedRowsByPriceType");
	
	ItemArray.Add("ServicesCancelManualDiscounts");
	ItemArray.Add("ServicesAssignAManualDiscount");
	ItemArray.Add("ServicesAssignAManualDiscountToSelectedRows");
	
	ItemArray.Add("ServicesSelectServicesFromOrder");
	ItemArray.Add("ServicesFillInFromOrder");
	ItemArray.Add("ServicesCalculateDiscountsMarkups");
	
	ItemArray.Add("ToReadLoyaltyCard");
	ItemArray.Add("ToReadLoyaltyCardClient");
	ItemArray.Add("LoyaltyCard");
	
	ItemArray.Add("GoodsAddPaymentWithBonusPoints");
	ItemArray.Add("GoodsCancelPaymentWithBonusPoints");
	
	TMCommonUse.SetSubscriptionForFormElementChangeEvents(ThisObject, ItemArray);
	
	TMCommonUseClientServer.SetFormItemProperty(Items, "ServicesSelectServicesFromOrder",                 "Enabled", Object.InvoiceByOrders);
	TMCommonUseClientServer.SetFormItemProperty(Items, "ServicesFillInFromOrder",                       "Enabled", Object.InvoiceByOrders);
	
	TMCommonUseClientServer.SetFormItemProperty(Items, "ServicesOpenInformationAboutDiscounts",                "Enabled", Not Object.InvoiceByOrders);
	TMCommonUseClientServer.SetFormItemProperty(Items, "ContextMenuServicesOpenInformationAboutDiscounts", "Enabled", Not Object.InvoiceByOrders);
	
	ItemArray = New Array;
	ItemArray.Add("CopyServices");
	ItemArray.Add("CopyContextMenuServices");
	
	ItemArray.Add("BarcodeSearchServices");
	ItemArray.Add("ServicesImportDataFromPDT");
	ItemArray.Add("ServicesToSplitTheString");
	ItemArray.Add("ServicesContextMenuSplitRow");
	ItemArray.Add("ServicesOpenSelection");
	ItemArray.Add("ServicesImportFromExternalFile");
	
	ItemArray.Add("ToReadLoyaltyCard");
	ItemArray.Add("ToReadLoyaltyCardClient");
	ItemArray.Add("LoyaltyCard");
	
	ItemArray.Add("ServicesCancelManualDiscounts");
	ItemArray.Add("ServicesAssignAManualDiscount");
	ItemArray.Add("ServicesAssignAManualDiscountToSelectedRows");
	ItemArray.Add("ServicesAssignAutomaticDiscounts");
	
	TMCommonUseClientServer.SetPropertyOfFormElements(Items, ItemArray, "Enabled", Not Object.InvoiceByOrders);
	
	ItemArray = New Array;
	
	// Header Controls
	ItemArray.Add("Partner");
	ItemArray.Add("Terms");
	ItemArray.Add("Contract");
	ItemArray.Add("Currency");
	ItemArray.Add("PriceIncludesVAT");
	ItemArray.Add("Organization");
	ItemArray.Add("Counterparty");
	
	ItemArray.Add("VATTaxation");
	
	ItemArray.Add("ARAPCurrency");
	ItemArray.Add("ActOfCompletedWorkOnTheOrder");
	ItemArray.Add("AcceptanceNoteForOrders");
	ItemArray.Add("LoyaltyCard");
	
	ItemArray.Add("ServicesProducts");
	ItemArray.Add("ServicesContent");
	ItemArray.Add("ServicesRowCode");
	ItemArray.Add("ServicesCharacteristic");
	ItemArray.Add("ServicesPriceKind");
	
	ItemArray.Add("ServicesPercentRateOfManualDiscount");
	ItemArray.Add("ServicesManualDiscount");
	ItemArray.Add("ServicesVATRate");
	
	OnlyViewItems = Object.InvoiceByOrders And Not UserRightsCached.VarianceFromSalesTermsAndConditions()
		And (ValueIsFilled(Object.SalesOrder) Or OrderList.Count() > 0);
	
	TMCommonUseClientServer.SetPropertyOfFormElements(Items, ItemArray, "ReadOnly", OnlyViewItems);
	
	ItemArray = New Array;
	ItemArray.Add("ServicesFillThePricesByTermsOfSales");
	ItemArray.Add("ServicesFillInPricesOfSelectedRowsByPriceType");
	ItemArray.Add("ServicesCancelManualDiscounts");
	ItemArray.Add("ServicesAssignAManualDiscount");
	ItemArray.Add("ServicesAssignAManualDiscountToSelectedRows");
	
	TMCommonUseClientServer.SetPropertyOfFormElements(Items, ItemArray, "Enabled", Not (OnlyViewItems));

EndProcedure

&AtServer
Procedure UpdateAdditionalAttributesItems()
	
	PropertyManager.UpdateAdditionalAttributesItems(ThisForm);
	
EndProcedure

&AtServer
Procedure GetServicesFromStorage(AddressOfServicesInStorage)
	
	TableStructure = GetFromTempStorage(AddressOfServicesInStorage);
	
	ServiceSearchStructure = New Structure("RowCode,SalesOrder");
	DiscountSearchStructure  = New Structure("ConnectionKey");
	For Each ServiceLine_ In TableStructure.Goods Do
		
		// PM processing services.
		ServiceSearchStructure.RowCode = ServiceLine_.RowCode;
		ServiceSearchStructure.SalesOrder = ServiceLine_.SalesOrder;
		ArrayOfTSServiceStrings = Object.Services.FindRows(ServiceSearchStructure);
		
		If ArrayOfTSServiceStrings.Count() = 0 Then
			
			LineTSServices = Object.Services.Add();
			
		ElsIf ArrayOfTSServiceStrings.Count() = 1 Then
			
			LineTSServices = ArrayOfTSServiceStrings[0];
			
			// Removing subordinate lines from PM discounts.
			DeleteTSDiscountMarkUpLines(LineTSServices);
			
		ElsIf ArrayOfTSServiceStrings.Count() > 1 Then
			
			For Each RowToDelete In ArrayOfTSServiceStrings Do
				
				// Removing subordinate lines from PM discounts.
				DeleteTSDiscountMarkUpLines(RowToDelete);
				
				Object.Services.Delete(RowToDelete);
				
			EndDo;
			
			LineTSServices = Object.Services.Add();
			
		EndIf;
		
		FillPropertyValues(LineTSServices, ServiceLine_);
		
		// PM processing discounts.
		If ValueIsFilled(LineTSServices.ConnectionKey) Then
			DiscountSearchStructure.ConnectionKey = LineTSServices.ConnectionKey;
			For Each DiscountsRow In TableStructure.DiscountsMarkups.FindRows(DiscountSearchStructure) Do
				
				FillPropertyValues(Object.DiscountsMarkups.Add(), DiscountsRow);
				
			EndDo;
		EndIf;
		
	EndDo;
	
	// Platoon of the flag of the need to calculate discounts.
	Object.DiscountsAreCalculated = False;
	
	CalculateFinalIndicatorsOfActsOfWorkPerformed(ThisObject);
	
	FillInServiceDetailsForProductRange();
	
	UpdateOrderInformation();
	
	ARAPAccountingFormWork.WhenChangingParametersOfMechanism(ThisObject);
	ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisObject, "InvoiceByOrders");
	
EndProcedure

&AtServer
Function LinkLinesOfCompletedWorkReportsToCustomerOrders(SelectByOrder_)
	
	If (Not GetFunctionalOption("UseSalesOrders")
		And Not GetFunctionalOption("UseRequestsForReturnOfGoodsFromCustomers")) Or
		(Not GetFunctionalOption("UseCustomerInvoicesForSeveralOrders")
		And Not ValueIsFilled(Object.SalesOrder)) Then
		
		Return False;
		
	EndIf;

	Query = New Query("SELECT
	|	Services.Products AS Products,
	|	Services.Characteristic AS Characteristic
	|INTO Services
	|FROM
	|	&Services AS Services
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	OrdersTable.SalesOrder.SalesOpportunity AS SalesOpportunity,
	|	OrdersTable.SalesOrder AS SalesOrder,
	|	OrdersTable.ARAPObjectSettings AS ARAPObjectSettings,
	|	OrdersTable.Products AS Products,
	|	OrdersTable.Characteristic AS Characteristic,
	|	OrdersTable.RowCode AS RowCode,
	|	SUM(OrdersTable.ToRegister) AS ToRegisterBalance
	|INTO SalesOrders
	|FROM
	|	(SELECT
	|		TurnoversByOrders.ReferenceOrder AS SalesOrder,
	|		TurnoversByOrders.ReferenceOrder.ARAPObjectSettings AS ARAPObjectSettings,
	|		TurnoversByOrders.Products AS Products,
	|		TurnoversByOrders.Characteristic AS Characteristic,
	|		TurnoversByOrders.RowCode AS RowCode,
	|		(TurnoversByOrders.ForRegistrationQuantityTurnover -
	|			TurnoversByOrders.IssuedQuantityTurnover) AS ToRegister
	|	FROM
	|		#ShipmentOrdersTurnoverExpanded AS TurnoversByOrders
	|	WHERE
	|		(TurnoversByOrders.ForRegistrationQuantityTurnover -
	|			TurnoversByOrders.IssuedQuantityTurnover) <> 0
	|
	|	UNION ALL
	|	
	|	SELECT
	|		OrdersRegisterRecords.ReferenceOrder,
	|		OrdersRegisterRecords.ReferenceOrder.ARAPObjectSettings,
	|		OrdersRegisterRecords.Products,
	|		OrdersRegisterRecords.Characteristic,
	|		OrdersRegisterRecords.RowCode,
	|		OrdersRegisterRecords.IssuedQuantity
	|	FROM
	|		#OrdersForShipmentRegisteredRecordsExpanded AS OrdersRegisterRecords) AS OrdersTable
	|GROUP BY
	|	OrdersTable.SalesOrder,
	|	OrdersTable.ARAPObjectSettings,
	|	OrdersTable.Products,
	|	OrdersTable.Characteristic,
	|	OrdersTable.RowCode
	|
	|HAVING
	|	SUM(OrdersTable.ToRegister) > 0
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	COUNT(*) AS DuplicateCount,
	|	SalesOrders.Products AS Products,
	|	SalesOrders.Characteristic AS Characteristic
	|INTO DuplicatesOfServices
	|FROM
	|	SalesOrders AS SalesOrders
	|
	|GROUP BY
	|	SalesOrders.Products,
	|	SalesOrders.Characteristic
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	SalesOrders.SalesOrder            AS SalesOrder,
	|	SalesOrders.ARAPObjectSettings         AS ARAPObjectSettings,
	|	SalesOrders.Products            AS Products,
	|	SalesOrders.Characteristic          AS Characteristic,
	|	SalesOrders.RowCode               AS RowCode,
	|	CASE
	|		WHEN CustomerOrderGoods.WithAssignment
	|			THEN SalesOrders.SalesOrder.Purpose
	|		ELSE VALUE(Catalog.Assignments.EmptyRef)
	|	END                                  AS Purpose,
	|	SalesOrders.ToRegisterBalance      AS ToRegisterBalance,
	|	CustomerOrderGoods.PriceKind             AS PriceKind,
	|	CustomerOrderGoods.Price                AS Price,
	|	CustomerOrderGoods.PercentRateOfManualDiscount AS PercentRateOfManualDiscount,
	|	CustomerOrderGoods.VATRate           AS VATRate,
	|	0 AS Allocated,
	|	DuplicatesOfServices.DuplicateCount AS DuplicateCount
	|FROM
	|	SalesOrders AS SalesOrders
	|		LEFT JOIN DuplicatesOfServices AS DuplicatesOfServices
	|		ON SalesOrders.Products = DuplicatesOfServices.Products
	|			AND SalesOrders.Characteristic = DuplicatesOfServices.Characteristic
	|		LEFT JOIN Document.SalesOrder.Goods AS CustomerOrderGoods
	|		ON (CustomerOrderGoods.Ref = SalesOrders.SalesOrder)
	|			AND (CustomerOrderGoods.RowCode = SalesOrders.RowCode)
	|
	|ORDER BY
	|	CustomerOrderGoods.Products,
	|	CustomerOrderGoods.Characteristic,
	|	CustomerOrderGoods.DateOfShipment,
	|	CustomerOrderGoods.Ref,
	|	CustomerOrderGoods.LineNumber");
	
	TableFormationParameters = AccumulationRegisters.ShipmentAndReturnReferences.NewParametersForCreatingExpandedTable();
	TableFormationParameters.ConditionText =
		"Recorder = &Recorder
		|		AND CASE
		|				WHEN &SelectByOrder_
		|					THEN ReferenceOrder = &SalesOrder
		|				ELSE ReferenceOrder.Partner = &Partner
		|						AND ReferenceOrder.Counterparty = &Counterparty
		|						AND ReferenceOrder.Contract = &Contract
		|						AND ReferenceOrder.Organization = &Organization
		|						AND ReferenceOrder.BusinessOperation IN
		|							(VALUE(Enum.BusinessTransactions.SaleToCustomer),
		|							VALUE(Enum.BusinessTransactions.ReturnFromRetailCustomer),
		|							VALUE(Enum.BusinessTransactions.ReturnOfGoodsFromCustomer))
		|						AND ReferenceOrder.Terms = &Terms
		|						AND ReferenceOrder.SalesOpportunity = &SalesOpportunity
		|						AND ReferenceOrder.Currency = &ARAPCurrency
		|						AND CASE
		|							WHEN ReferenceOrder.VATTaxation IN (VALUE(Enum.VATTaxationTypes.ExportOfCommoditiesServicesWorks), VALUE(Enum.VATTaxationTypes.ExportOfNonResourceGoods))
		|								THEN VALUE(Enum.VATTaxationTypes.ExportSale)
		|							ELSE ReferenceOrder.VATTaxation
		|						END = &VATTaxation
		|						AND ReferenceOrder.PriceIncludesVAT = &PriceIncludesVAT
		|						AND ReferenceOrder.LineOfBusiness = &LineOfBusiness
		|		END
		|		AND Active
		|		AND Products.SaleRegistrationOption = VALUE(Enum.SalesRegistrationOptions.CustomerInvoiceServices)
		|		AND (Products, Characteristic) IN
		|			(SELECT
		|				Services.Products AS Products,
		|				Services.Characteristic AS Characteristic
		|			FROM
		|				Services AS Services)
		|		";
	TableFormationParameters.Group = "ReferenceOrder, Products, Characteristic, RowCode";
	TableFormationParameters.Indicators = "ToRegister, Issued_1";
	TableFormationParameters.Resources = "Count";
	TableFormationParameters.PhysicalTable = True;
	
	OrdersForShipmentRegisteredRecordsExpanded =
		AccumulationRegisters.ShipmentAndReturnReferences.QueryTextExpandedTable(
			TableFormationParameters);
	
	Query.Text = StrReplace(Query.Text,
		"#OrdersForShipmentRegisteredRecordsExpanded",
		OrdersForShipmentRegisteredRecordsExpanded);
	
	TableFormationParameters = AccumulationRegisters.ShipmentAndReturnReferences.NewParametersForCreatingExpandedTable();
	TableFormationParameters.ConditionText =
		"CASE
		|			WHEN &SelectByOrder_
		|				THEN ReferenceOrder = &SalesOrder
		|			ELSE ReferenceOrder.Partner = &Partner
		|				AND ReferenceOrder.Counterparty = &Counterparty
		|				AND ReferenceOrder.Contract = &Contract
		|				AND ReferenceOrder.Organization = &Organization
		|				AND ReferenceOrder.BusinessOperation IN
		|					(VALUE(Enum.BusinessTransactions.SaleToCustomer),
		|					VALUE(Enum.BusinessTransactions.ReturnFromRetailCustomer),
		|					VALUE(Enum.BusinessTransactions.ReturnOfGoodsFromCustomer))
		|				AND ReferenceOrder.Terms = &Terms
		|				AND ReferenceOrder.SalesOpportunity = &SalesOpportunity
		|				AND ReferenceOrder.Currency = &ARAPCurrency
		|				AND CASE
		|						WHEN ReferenceOrder.VATTaxation IN (VALUE(Enum.VATTaxationTypes.ExportOfCommoditiesServicesWorks), VALUE(Enum.VATTaxationTypes.ExportOfNonResourceGoods))
		|							THEN VALUE(Enum.VATTaxationTypes.ExportSale)
		|						ELSE ReferenceOrder.VATTaxation
		|					END = &VATTaxation
		|				AND ReferenceOrder.PriceIncludesVAT = &PriceIncludesVAT
		|				AND ReferenceOrder.LineOfBusiness = &LineOfBusiness
		|			END
		|		AND Products.SaleRegistrationOption = VALUE(Enum.SalesRegistrationOptions.CustomerInvoiceServices)
		|		AND (Products, Characteristic) IN
		|			(SELECT
		|					Services.Products AS Products,
		|					Services.Characteristic AS Characteristic
		|				FROM
		|					Services AS Services)";
	TableFormationParameters.Group = "ReferenceOrder, Products, Characteristic, RowCode";
	TableFormationParameters.Indicators = "ToRegister, Issued_1";
	TableFormationParameters.Resources = "Count";
	
	ShipmentOrdersTurnoverExpanded =
		AccumulationRegisters.ShipmentAndReturnReferences.QueryTextExpandedTable(
			TableFormationParameters);
	
	Query.Text = StrReplace(Query.Text,
		"#ShipmentOrdersTurnoverExpanded",
		ShipmentOrdersTurnoverExpanded);
	
	Query.SetParameter("SalesOrder",          Object.SalesOrder);
	Query.SetParameter("Partner",               Object.Partner);
	Query.SetParameter("Counterparty",            Object.Counterparty);
	Query.SetParameter("Contract",               Object.Contract);
	Query.SetParameter("Organization",           Object.Organization);
	Query.SetParameter("SalesOpportunity",                Object.SalesOpportunity);
	Query.SetParameter("Terms",            Object.Terms);
	Query.SetParameter("ARAPCurrency",  Object.ARAPCurrency);
	Query.SetParameter("VATTaxation",    Object.VATTaxation);
	Query.SetParameter("PriceIncludesVAT",       Object.PriceIncludesVAT);
	Query.SetParameter("Recorder",           Object.Ref);
	Query.SetParameter("SelectByOrder_",      SelectByOrder_);
	Query.SetParameter("LineOfBusiness", Object.LineOfBusiness);
	
	Query.SetParameter("Services",  Object.Services.Unload(,"RowCode,Products,Characteristic,SalesOrder"));
	SetPrivilegedMode(True);
	QueryResult = Query.ExecuteBatch();
	If QueryResult[1].IsEmpty() Then
		Return False;
	EndIf;
	
	Selection = QueryResult[3].Select();
	
	ArrayOfARAPObjectsSettings = New Array();
	While Selection.Next() Do
		If ValueIsFilled(Selection.ARAPObjectSettings)
			And ArrayOfARAPObjectsSettings.Find(Selection.ARAPObjectSettings) = Undefined Then
			ArrayOfARAPObjectsSettings.Add(Selection.ARAPObjectSettings);
		EndIf;
	EndDo;
	
	If ArrayOfARAPObjectsSettings.Count() > 1 Then
		Common.MessageToUser(NStr("vi = 'Trong các đơn hàng đã tìm thấy, khác trường ""Trình tự hạch toán""';
									|ru = 'У найденных заказов отличается поле ""Порядок расчетов""';
									|en = 'The ""Payment terms"" field data is different for the found orders'; fa = 'The ""Payment terms"" field data is different for the found orders';
									|it = 'У найденных заказов отличается поле ""Порядок расчетов""';
									|pl = 'The ""Payment terms"" field data is different for the found orders';
									|tr = 'Bulunan siparişlerin farklı bir ""Alacak/Borç muhasebesi prosedürü"" alanı mevcut'"));
		Return False;
	EndIf;
	
	Selection.Reset();
	
	TableOfUnallocatedServices = New ValueTable();
	TableOfUnallocatedServices.Columns.Add("Products");
	TableOfUnallocatedServices.Columns.Add("Characteristic");
	TableOfUnallocatedServices.Columns.Add("SalesOrder");
	TableOfUnallocatedServices.Columns.Add("RowCode");
	TableOfUnallocatedServices.Columns.Add("Count");
	TableOfUnallocatedServices.Columns.Add("PriceKind");
	TableOfUnallocatedServices.Columns.Add("Price");
	TableOfUnallocatedServices.Columns.Add("PercentRateOfManualDiscount");
	TableOfUnallocatedServices.Columns.Add("VATRate");
	TableOfUnallocatedServices.Columns.Add("Purpose");
	
	While Selection.Next() Do
		
		TheStructureOfTheSearch = New Structure();
		TheStructureOfTheSearch.Insert("Products",        Selection.Products);
		TheStructureOfTheSearch.Insert("Characteristic",      Selection.Characteristic);
		TheStructureOfTheSearch.Insert("PriceKind",             Selection.PriceKind);
		TheStructureOfTheSearch.Insert("Price",                Selection.Price);
		TheStructureOfTheSearch.Insert("PercentRateOfManualDiscount", Selection.PercentRateOfManualDiscount);
		TheStructureOfTheSearch.Insert("VATRate",           Selection.VATRate);
		TheStructureOfTheSearch.Insert("RowCode",           0);
		
		FoundRows = Object.Services.FindRows(TheStructureOfTheSearch);
		RetainedQuantity = Selection.ToRegisterBalance;
		
		// If there are no duplicates, we distribute the order line to the invoice lines
		If Selection.DuplicateCount < 2 Then
		
			For Each CurRow In FoundRows Do
			
				CurRow.RowCode        = Selection.RowCode;
				CurRow.SalesOrder     = Selection.SalesOrder;
				RetainedQuantity = RetainedQuantity - CurRow.Count;
				
				If RetainedQuantity <= 0 Then
					Break;
				EndIf;
			
			EndDo;
			
		// If there are duplicates, we distribute the order lines according to the invoice lines, taking into account the quantity.
		Else
			
			// On the first pass, we will fill in only if the quantity in the order line and the invoice match.
			
			MatchingStringFound = False;
			
			For Each CurRow In FoundRows Do
				
				If CurRow.Count = Selection.ToRegisterBalance Then
					
					MatchingStringFound = True;
					FillPropertyValues(CurRow, Selection, "RowCode,SalesOrder,Purpose");
					
					Break;
					
				EndIf;
				
			EndDo;
			
			If Not MatchingStringFound Then
				
				NewRow = TableOfUnallocatedServices.Add();
				FillPropertyValues(NewRow, Selection);
				NewRow.Count = RetainedQuantity;
				
			EndIf;
			
		EndIf;
		
	EndDo;
	
	// We will distribute duplicates of services unallocated on the first pass
	If TableOfUnallocatedServices.Count() > 0 Then
	
		TheStructureOfTheSearch = New Structure();
		TheStructureOfTheSearch.Insert("RowCode", 0);
		TheStructureOfTheSearch.Insert("SalesOrder", Undefined);
		
		ServiceLines_ = Object.Services.FindRows(TheStructureOfTheSearch);
		
		For Each ServiceLine_1 In ServiceLines_ Do
			
			// We will find the necessary rows in the table of unallocated services
			TheStructureOfTheSearch = New Structure();
			TheStructureOfTheSearch.Insert("Products",        ServiceLine_1.Products);
			TheStructureOfTheSearch.Insert("Characteristic",      ServiceLine_1.Characteristic);
			TheStructureOfTheSearch.Insert("PriceKind",             ServiceLine_1.PriceKind);
			TheStructureOfTheSearch.Insert("Price",                ServiceLine_1.Price);
			TheStructureOfTheSearch.Insert("PercentRateOfManualDiscount", ServiceLine_1.PercentRateOfManualDiscount);
			TheStructureOfTheSearch.Insert("VATRate",           ServiceLine_1.VATRate);
			
			FoundRows = TableOfUnallocatedServices.FindRows(TheStructureOfTheSearch);
			
			For Each CurRow In FoundRows Do
				If CurRow.Products = ServiceLine_1.Products And
					CurRow.Characteristic = ServiceLine_1.Characteristic And
					CurRow.PriceKind = ServiceLine_1.PriceKind And
					CurRow.Price = ServiceLine_1.Price And
					CurRow.PercentRateOfManualDiscount = ServiceLine_1.PercentRateOfManualDiscount And
					CurRow.VATRate = ServiceLine_1.VATRate And
					
					CurRow.Count > 0 Then
					
					FillPropertyValues(ServiceLine_1, CurRow, "RowCode,SalesOrder,Purpose");
					
					// Reduce the unallocated quantity in the table
					CurRow.Count = CurRow.Count - ServiceLine_1.Count;
					
				EndIf;
			EndDo;
			
		EndDo;
		
	EndIf;
	
	// Delete the work execution lines that could not be linked to orders
	ArrayOfRowsToDelete_1 = New Array();
	
	For Each CurRow In Object.Services Do
		
		If Not ValueIsFilled(CurRow.RowCode)
			Or Not ValueIsFilled(CurRow.SalesOrder) Then
			
			ArrayOfRowsToDelete_1.Add(CurRow);
			
		EndIf;
		
	EndDo;
	
	For Each CurItem In ArrayOfRowsToDelete_1 Do
		Object.Services.Delete(CurItem);
	EndDo;
	
	For Each CurRow In Object.Services Do
		If Not ValueIsFilled(CurRow.RowCode) Then
			CurRow.Purpose = Catalogs.Assignments.EmptyRef();
		EndIf;
	EndDo;
	
	Return True;
	
EndFunction

&AtServer
Procedure UnbindRowsFromCustomerOrders()
	
	For Each CurRow In Object.Services Do
		
		CurRow.RowCode = 0;
		CurRow.SalesOrder = Undefined;
		
	EndDo;
	
EndProcedure

&AtServer
Procedure ServicesAfterDeleteRowServer()
	
	UpdateOrderInformation();
	
EndProcedure

&AtServerNoContext
Function GetDefaultCounterpartyBankAccountServer(Counterparty)
	
	ParametersOfAccount = CashServer.ParametersForFillingInCounterpartySBankAccount(Counterparty);
	
	Return CashServer.GetDefaultCounterpartyBankAccount(ParametersOfAccount);
	
EndFunction

&AtServer
Function GetOrganizationSDefaultBankAccountServer()
	
	ParametersOfAccount = CashServer.ParametersForFillingOutOrganizationSBankAccount(Object.Organization);
	ParametersOfAccount.LineOfBusiness = Object.LineOfBusiness;
	ParametersOfAccount.ExcludeCurrencyAccounts = Object.ForeignCurrencyTransaction;
	ParametersOfAccount.Currency = LocalAccountingCurrency;
	
	Return CashServer.GetOrganizationSDefaultBankAccount(ParametersOfAccount,
		Object.CompanyBankAccount);
	
EndFunction

&AtServer
Function AddressOfDataForCalculatingManualDiscountsInTemporaryStorage(SelectedLinesOnly)
	
	ParametersStructure = DiscountsMarkupsFillingServer.NewParametersAddressDataForCalculatingManualDiscounts();
	ParametersStructure.TableName = "Services";
	ParametersStructure.OnlyForSelectedLines = SelectedLinesOnly;
	Return DiscountsMarkupsFillingServer.AddressOfDataForCalculatingManualDiscountsInTemporaryStorage(
		ThisForm, UUID, ParametersStructure);
	
	
EndFunction

&AtServerNoContext
Procedure CheckForAdjustments(Ref, ThereAreAdjustingEntries) Export
	
	SalesServer.CheckForAdjustments(Ref, Ref, ThereAreAdjustingEntries)
	
EndProcedure

&AtServerNoContext
Function HaveRightToAddAdjustments()
	
	Return AccessRight("Insert", Metadata.Documents.SaleAdjustment);
	
EndFunction

&AtServer
Procedure FillIn_TermsOfSales(AttributesArray)
	
	DocumentSales = FormAttributeToValue("Object");
	DocumentSales.FillInDefaultSalesConditions();
	
	If ToUseTermsOfSales And ValueIsFilled(DocumentSales.Terms) Then
		DocumentCurrency = Object.Currency;
		CalculateFinalIndicatorsOfActsOfWorkPerformed(ThisObject);
	EndIf;
	
	ValueToFormAttribute(DocumentSales, "Object");
	
	If DocumentCurrency <> Object.Currency Then
		AttributesArray.Add("Currency");
	EndIf;
	DocumentCurrency = Object.Currency;
	If ARAPCurrency <> Object.ARAPCurrency Then
		AttributesArray.Add("ARAPCurrency");
	EndIf;
	ARAPCurrency = Object.Currency;
	
	FillInDefaultContract();
	
EndProcedure

&AtServer
Procedure SetVisibilityOfShipmentBanToPartner()
	
	SegmentsServer.SetVisibilityOfShipmentBanToPartner(Object.Partner, Items);
	
EndProcedure

&AtServer
Procedure GetUploadedProductsFromStorage(GoodsAddressInStorage)
	
	ServicesFromRepository = GetFromTempStorage(GoodsAddressInStorage);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInContent", BatchProcessingOfTablePartClientServer.GetStructureOfFillingInServiceContentInTSLine(Object, True));
	AddActionsToStructureWhenQuantityChanges(StructureOfActions,Object);
	LinesOfBusinessClientServer.StructureOfInsertActionsWhenAddingRow(ThisForm, StructureOfActions);
	CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValuesServices();
	RowsToProcess = New Array();
	
	For Each LineService In ServicesFromRepository Do
		LineTSServices = Object.Services.Add();
		FillPropertyValues(LineTSServices, LineService,, "RowCode");
		RowsToProcess.Add(LineTSServices);
	EndDo;
	
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		RowsToProcess,
		StructureOfActions,
		Object.Services,
		CachedValues);
		
	CalculateFinalIndicatorsOfActsOfWorkPerformed(ThisObject);
	
EndProcedure

&AtServer
Procedure UpdateTextOfInvoiceIssued()
	
	RegistrationParameters = ParametersForRegisteringInvoicesIssuedServer(Object);
	InvoicesIssuedOnBasisOf = VATAccountingERP.InvoicesIssuedOnBasisOf(RegistrationParameters);
	
	TextOfTheInvoiceIssued = SalesServer.CreatePresentationOfInvoiceGenerationCommandsBasedOn(Object.Ref, InvoicesIssuedOnBasisOf);
	
	GeneratingFiscalChecksServer.UpdateFiscalCheckBreakdownHyperlink(Object.Ref, ThisObject, TextOfTheInvoiceIssued);
	
EndProcedure

&AtServer
Procedure FillInSalesVATTaxation()
	
	FillParameters = Documents.CustomerInvoiceServices.ParametersForFillingInSalesVATTaxation(Object);
	VATAccountingERP.FillInSalesVATTaxation(Object.VATTaxation, FillParameters, VATAccountingCachedParameterValues);
	VATAccountingERP.FillInSalesVATTaxSelectionList(Items.VATTaxation, Object.VATTaxation, FillParameters, VATAccountingCachedParameterValues); 
	
EndProcedure

&AtServer
Procedure UpdateFlagThereAreAdjustments();
	CheckForAdjustments(Object.Ref, ThereAreAdjustingEntries);
EndProcedure

&AtServer
Procedure Recording_AdjustingImplementationOnServer()
	UpdateTextOfInvoiceIssued();
	UpdateFlagThereAreAdjustments();
	ARAPAccountingFormWork.WhenChangingParametersOfMechanism(ThisForm);
EndProcedure

&AtClient
Procedure FillInTheDepartment(Command)
	
	WarehousesClient.FillInDivisionInTablePart(Object, ThisForm, Object.Services, "Services", 
			Items.Services.SelectedRows);
	
EndProcedure

&AtServer
Procedure SetVisibilityOfElementsOfLoyaltyBonusProgram()
	
	Items.GroupProductsBonusPoints.Visible = UseLoyaltyPrograms;
	Items.GoodsAmountOfBonusPointsToDeductionInCurrency.Visible = UseLoyaltyPrograms;
	Items.GoodsAmountOfEarnedBonusPointsInCurrency.Visible = UseLoyaltyPrograms;
	
EndProcedure

&AtServer
Function AddressOfTabularPartOfService()
	
	If UseAdvancedFeaturesOfSalesOrder Then
		RowsArray = New Array();
		For Each String In Object.Services Do
			If Not String.RowCode = 0 Then
				Continue;
			EndIf;
			
			RowsArray.Add(String);
		EndDo;
		TableServices = Object.Services.Unload(RowsArray);
	Else
		TableServices = Object.Services.Unload();
	EndIf;   
	
	TableServices.Columns.Count.Name = "NumberOfPackages";
	
	Return PutToTempStorage(TableServices, UUID);
	
EndFunction

&AtServer
Function PutGoodsAndStockTypesInStorage()
	
	OptionsForEditingInventoryTypes = InventoriesServer.OptionsForEditingInventoryTypes();
	OptionsForEditingInventoryTypes.NameTSGoods = "Services";
	
	Return InventoriesServer.PutGoodsAndStockTypesInStorage(ThisObject, OptionsForEditingInventoryTypes);
	
EndFunction

&AtServer
Procedure GetStockTypesFromStorage(ValueSelected)
	
	InventoriesServer.ProcessInputOfInventoryTypesManually(ValueSelected, ThisObject);
	
EndProcedure

&AtServer
Procedure AddSBPPaymentStatusUpdateCommand()

	CommandParameters = CashServerLocalization.NewParametersOfSBPPaymentStatusUpdateCommand();
	CommandParameters.Parent = Items.PaymentGroup_2;
	CashServerLocalization.AddSBPPaymentStatusUpdateCommand(ThisObject, CommandParameters);

EndProcedure

&AtServer
Function OrdersAreUsedAsInvoices()
	
	AnArrayOfOrders = Object.Services.Unload(, "SalesOrder").UnloadColumn("SalesOrder");
	AnArrayOfOrders.Add(Object.SalesOrder);
	
	Query = New Query;
	Query.SetParameter("AnArrayOfOrders", AnArrayOfOrders);
	Query.Text =
	"SELECT
	|	DocumentsTable.ThisIsOrderAsInvoice AS ThisIsOrderAsInvoice
	|INTO TableOfOrderDetails
	|FROM
	|	Document.SalesOrder AS DocumentsTable
	|WHERE
	|	DocumentsTable.Ref IN (&AnArrayOfOrders)
	|
	|UNION ALL
	|
	|SELECT
	|	DocumentsTable.ThisIsOrderAsInvoice
	|FROM
	|	Document.RequestForReturnOfGoodsFromCustomer AS DocumentsTable
	|WHERE
	|	DocumentsTable.Ref IN (&AnArrayOfOrders)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT TOP 1
	|	TRUE AS ThereAreRecords
	|FROM
	|	TableOfOrderDetails AS TableOfOrderDetails
	|HAVING
	|	COUNT(TableOfOrderDetails.ThisIsOrderAsInvoice) > 0
	|	AND MIN(TableOfOrderDetails.ThisIsOrderAsInvoice) = TRUE";
	
	Return Not Query.Execute().IsEmpty();
	
EndFunction

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
	ElsIf Item.Name = "PriceIncludesVAT" Then
		PriceIncludesVATOnChange(Item);
	ElsIf Item.Name = "Organization" Then
		OrganizationOnChange(Item);
	ElsIf Item.Name = "Counterparty" Then
		CounterpartyOnChange(Item);
	ElsIf Item.Name = "VATTaxation" Then
		VATTaxationOnChange(Item);
	ElsIf Item.Name = "ActOfCompletedWorkOnTheOrder" Then
		AcceptanceNoteForOrdersOnChange(Item);
	ElsIf Item.Name = "AcceptanceNoteForOrders" Then
		AcceptanceNoteForOrdersOnChange(Item);
	ElsIf Item.Name = "ServicesProducts" Then
		ServicesProductsOnChange(Item);
	ElsIf Item.Name = "ServicesCharacteristic" Then
		ServicesCharacteristicOnChange(Item);
	ElsIf Item.Name = "ServicesWithAssignment" Then
		ServicesWithAssignmentOnChange(Item);
	ElsIf Item.Name = "ServicesCount" Then
		ServicesCountOnChange(Item);
	ElsIf Item.Name = "ServicesPriceKind" Then
		ServicesPriceKindOnChange(Item);
	ElsIf Item.Name = "ServicesPrice" Then
		ServicesPriceOnChange(Item);
	ElsIf Item.Name = "ServicesPercentRateOfManualDiscount" Then
		ServicesPercentRateOfManualDiscountOnChange(Item);
	ElsIf Item.Name = "ServicesManualDiscount" Then
		ServicesManualDiscountOnChange(Item);
	ElsIf Item.Name = "ServicesSum" Then
		ServicesSumOnChange(Item);
	ElsIf Item.Name = "ServicesVATRate" Then
		ServicesVATRateOnChange(Item);
	ElsIf Item.Name = "ServicesVATAmount" Then
		ServicesVATAmountOnChange(Item);
	ElsIf Item.Name = "ServicesPartnerProducts" Then
		ServicesPartnerProductsOnChange(Item);
	Else
		TMCommonUseClient.MonitoringNonConsistentChangesCauseException(ThisForm, Item);
	EndIf;
EndProcedure

&AtClient
Procedure ControlOfNonConsistentChangesHandleCommandEvent(Command)
	If Command.Name = "SearchByBarcode" Then
		SearchByBarcodeExecute(Command);
	ElsIf Command.Name = "SplitRow" Then
		SplitRow(Command);
	ElsIf Command.Name = "OpenSelection" Then
		OpenSelection(Command);
	ElsIf Command.Name = "ImportFromExternalFile" Then
		ImportFromExternalFile(Command);
	ElsIf Command.Name = "AssignAutomaticDiscounts" Then
		AssignAutomaticDiscounts(Command);
	ElsIf Command.Name = "FillThePricesByTermsOfSales" Then
		FillThePricesByTermsOfSales(Command);
	ElsIf Command.Name = "FillInPricesOfSelectedRowsByPriceType" Then
		FillInPricesOfSelectedRowsByPriceType(Command);
	ElsIf Command.Name = "CancelManualDiscounts" Then
		CancelManualDiscounts(Command);
	ElsIf Command.Name = "AssignAManualDiscount" Then
		AssignAManualDiscount(Command);
	ElsIf Command.Name = "AssignAManualDiscountToSelectedRows" Then
		AssignAManualDiscountForSelectedLines(Command);
	ElsIf Command.Name = "SelectServicesFromOrder" Then
		SelectServicesFromOrder(Command);
	ElsIf Command.Name = "FillInFromOrder" Then
		FillInFromOrder(Command);
	ElsIf Command.Name = "CalculateDiscountsMarkups" Then
		CalculateDiscountsMarkups(Command);
	ElsIf Command.Name = "ToReadLoyaltyCard" Then
		ToReadLoyaltyCard(Command);
	ElsIf Command.Name = "SetTheMarkApart" Then
		SetTheMarkApart(Command);
	ElsIf Command.Name = "UncheckTheSeparateBox" Then
		UncheckTheSeparateBox(Command);
	ElsIf Command.Name = "SetComposition" Then
		SetComposition(Command);
	ElsIf Command.Name = "InsertRows" Then
		InsertRows(Command);
	ElsIf Command.Name = "FillInTheDepartment" Then
		FillInTheDepartment(Command);
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
&AtClient
Procedure ControlOfNonConsistentChangesHandleEventBeforeDeletion(Item, Cancel)
	If Item.Name = "Services" Then
		ServicesBeforeDeleteRow(Item, Cancel);
	Else
		TMCommonUseClient.MonitoringNonConsistentChangesCauseException(ThisForm, Item);
	EndIf;
EndProcedure

// Parameters:
//	Item - FormGroup, FormTable, FormField, FormButton - FormItem
&AtClient
Procedure ControlOfNonConsistentChangesHandleEventBeforeStartingAdding(Item, Cancel, Copy, Parent, Var_Group)
	If Item.Name = "Services" Then
		ServicesBeforeAddRow(Item, Cancel, Copy, Parent, Var_Group);
	Else
		TMCommonUseClient.MonitoringNonConsistentChangesCauseException(ThisForm, Item);
	EndIf;
EndProcedure

&AtClient
Function PerformChecksBeforeChangingStatus()
	
	PropsCanBeChanged = False;
	
	AdditionalParameters = New Structure;
	Notification = New CallbackDescription(
			"QuestionResultCompletion", ThisObject, AdditionalParameters);
	
	If StructureOfActionsControlOfNonAgreedChanges = Undefined
		Or StructureOfActionsControlOfNonAgreedChanges.AlertIsExpected Then
		
		RunCallback(Notification, "ChangeAttribute");
		PropsCanBeChanged = True;
		
	EndIf;
	
	ClearMessages();
	
	CheckForAdjustments(Object.Ref, ThereAreAdjustingEntries);
	
	If Not HaveRightToAddAdjustments() 
		And ThereAreAdjustingEntries
		And UseCreditNotes Then
		
		MessageText = NStr("vi = 'Trên cơ sở chứng từ đã nhập điều chỉnh giao hàng.
			|Không đủ quyền để tạo điều chỉnh giao hàng.';
			|ru = 'На основании документа введена корректировка реализации.
			|Недостаточно прав для создания корректировки реализации.';
			|en = 'Sales adjustment is generated from base document.
			|Insufficient rights to create the sales adjustment.'; fa = 'Sales adjustment is generated from base document.
			|Insufficient rights to create the sales adjustment.';
			|it = 'Sulla base del documento è stata inserita una rettifica di realizzo.
			|Diritti insufficienti per creare la rettifica di realizzo.';
			|pl = 'Na podstawie dokumentu wprowadzono korektę sprzedaży.
			|Niewystarczające uprawnienia do wykonania korekty sprzedaży.';
			|tr = 'Belge temelinde bir satış düzeltmesi girilmiştir.
			|Bir satış düzeltmesi oluşturmak için yeterli hak verilmemiştir.'");
		
		CommonClientServer.MessageToUser(MessageText);
		
		RunCallback(Notification, "UndoChanges");
		
	ElsIf ThereAreAdjustingEntries And UseCreditNotes Then
		
		ButtonsList = New ValueList;
		ButtonsList.Add("EnterTheAdjustment", NStr("vi = 'Nhập điều chỉnh';
													|ru = 'Ввести корректировку';
													|en = 'Enter the adjustment'; fa = 'Enter the adjustment';
													|it = 'Inserire rettifica';
													|pl = 'Wprowadź korektę';
													|tr = 'Bir düzeltme yapın'"));
		ButtonsList.Add("UndoChanges", NStr("vi = 'Hủy bỏ';
											|ru = 'Отмена';
											|en = 'Cancel'; fa = 'انصراف';
											|it = 'Annulla';
											|pl = 'Cancel';
											|tr = 'İptal'"));
		
		ShowQueryBox(
			Notification,
			NStr("vi = 'Trên cơ sở chứng từ đã nhập điều chỉnh giao hàng.
				|Cấm thay đổi chứng từ gốc.';
				|ru = 'На основании документа введена корректировка реализации.
				|Изменение исходного документа запрещено.';
				|en = 'Sales adjustment is generated from base document.
				|Editing the original document is not allowed.'; fa = 'Sales adjustment is generated from base document.
				|Editing the original document is not allowed.';
				|it = 'In base al documento è stata inserita una rettifica di realizzo.
				|La modifica del documento originale non è consentita.';
				|pl = 'Na podstawie dokumentu wprowadzono korektę sprzedaży.
				|Zmiana dokumentu źródłowego jest zabroniona.';
				|tr = 'Temel belgeye bir satış düzeltmesi girilmiştir.
				| Orijinal belge değiştirilemez.'"),
			ButtonsList,
			,
			"EnterTheAdjustment");
		
	Else
		
		RunCallback(Notification, "ChangeAttribute");
		PropsCanBeChanged = True;
		
	EndIf;
	
	Return PropsCanBeChanged;
	
EndFunction

&AtClient
Procedure QuestionResultCompletion(ResponseCode, AdditionalParameters) Export
	
	If ResponseCode = "EnterTheAdjustment" Then
		OpenForm("Document.SaleAdjustment.ObjectForm", New Structure("Basis", Object.Ref));
	EndIf;
	
EndProcedure

// Parameters:
//	Item - FormGroup, FormTable, FormField, FormButton - FormItem
&AtClient
Procedure Attachable_WhenChanging_SetAvailabilityOfItemsByStatusServer(Item)
	
	If Not PerformChecksBeforeChangingStatus() Then
		TMCommonUseClient.ReturnPreviousPropsValue(ThisForm, Item);
		Return;
	Else
		TMCommonUseClient.SaveAttributeValue(ThisForm, Item);
	EndIf;
	
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
	
	If Not PerformChecksBeforeChangingStatus() Then
		Return;
	EndIf;
	
	If TMCommonUseClient.WhenActingOnStatusDependentElement(ThisForm) Then
		Return;
	EndIf;
	
	If StructureOfActionsControlOfNonAgreedChanges.Commands.Property(Command.Name) Then
		ControlOfNonConsistentChangesHandleCommandEvent(Command);
	EndIf;
	
EndProcedure

&AtClient
Procedure Attachable_BeforeStartingChange_SetAvailabilityOfItemsByStatusServer(Item, Cancel)
	
	If StructureOfActionsControlOfNonAgreedChanges = Undefined Then
		Return;
	EndIf;
	
	FillPropertyValues(StructureOfActionsControlOfNonAgreedChanges.AttributesValues[Item.Name], Item.CurrentData);
	
	If StructureOfActionsControlOfNonAgreedChanges.BeforeRowChange.Property(Item.Name) Then
		ControlOfNonConsistentChangesHandleEventBeforeStartingChange(Item, Cancel);
	EndIf;

EndProcedure

// Parameters:
//	Item - FormGroup, FormTable, FormField, FormButton - FormItem
&AtClient
Procedure Attachable_BeforeDeleting_SetAvailabilityOfItemsByStatusServer(Item, Cancel)
	
	If Not PerformChecksBeforeChangingStatus() Then
		Cancel = True;
		Return;
	EndIf;
	
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
	
	If Not PerformChecksBeforeChangingStatus() Then
		Cancel = True;
		Return;
	EndIf;
	
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

#Region WorkingWithCounterparties
&AtClient
Procedure CheckCounterparties(Command)
	
	
EndProcedure

#EndRegion

#Region FiscalTransaction

&AtClient
Procedure FiscalOperationNavigationLinkProcessing(Item, Var_URL, StandardProcessing)
	
	If "IssueCashReceipt" = Var_URL Then
		
		StandardProcessing = False;
		
		GeneratingFiscalChecksClient.DisplayReceipt(
			ThisObject,
			New CallbackDescription("FiscalTransactionCompletion", ThisObject)
		);
		
	ElsIf "OpenRecordOfFiscalTransaction" = Var_URL Then
		
		StandardProcessing = False;
		
		TMPeripheralsClient.OpenRecordOfFiscalTransaction(ThisObject, Object.Ref);
		
	ElsIf "ConfigureHardware_" = Var_URL Then
		
		StandardProcessing = False;
		
		OpenForm("DataProcessor.PreviewReceipt.Form.ErrorOfCREConnection");
		
	EndIf;
	
EndProcedure

&AtClient
Procedure FiscalTransactionCompletion(Result, AdditionalParameters) Export
	
	UpdateTextOfInvoiceIssued();
	
EndProcedure

#EndRegion

&AtClient
Procedure OpenPrintDetails()
		
	Try
		LockFormDataForEdit();
	Except
		ShowMessageBox(Undefined, BriefErrorDescription(ErrorInfo()));
		Return;
	EndTry;
	
	ParametersStructure = New Structure();
	ParametersStructure.Insert("CounterpartyBankAccount",       Object.CounterpartyBankAccount);
	ParametersStructure.Insert("Contract",                         Object.Contract);
	ParametersStructure.Insert("Basis",                       Object.Basis);
	ParametersStructure.Insert("ReferenceDocumentDateForPrintForms",                   Object.ReferenceDocumentDateForPrintForms);
	ParametersStructure.Insert("BaseDocumentNumber",                  Object.BaseDocumentNumber);
	ParametersStructure.Insert("Partner",                         Object.Partner);
	ParametersStructure.Insert("Counterparty",                      Object.Counterparty);
	ParametersStructure.Insert("ReadOnly",                  ReadOnly);
	ParametersStructure.Insert("ObjectType",                      "CustomerInvoiceServices");
	ParametersStructure.Insert("OrderSales",             Object.InvoiceByOrders);
	ParametersStructure.Insert("CompanyBankAccount",       Object.CompanyBankAccount);
	ParametersStructure.Insert("RecipientCompanyBankAccount",Object.CompanyBankAccount);
	ParametersStructure.Insert("Organization",                     Object.Organization);
	ParametersStructure.Insert("Date",                            Object.Date);
	ParametersStructure.Insert("Director",                    Object.Director);
	ParametersStructure.Insert("ChiefAccountant",                Object.ChiefAccountant);
	ParametersStructure.Insert("PrintBasisTable",       PrintBasisTable);
	
	ParametersStructure.Insert("DeliveryAddress");
	ParametersStructure.Insert("ShipperBankAccount");
	ParametersStructure.Insert("GoodsRecipientBankAccount");
	ParametersStructure.Insert("Shipper");
	ParametersStructure.Insert("GoodsRecipient");
	ParametersStructure.Insert("LetterOfAuthorityIssuedBy");
	ParametersStructure.Insert("PowerOfAttorneyDate");
	ParametersStructure.Insert("PowerOfAttorneyPerson");
	ParametersStructure.Insert("PowerOfAttorneyNumber");
	ParametersStructure.Insert("IssuiedBy");
	ParametersStructure.Insert("IssuiedByJobTitle");
	
	OpenForm("CommonForm.PrintingDetailsOfSales", ParametersStructure, ThisForm,,,, Undefined, FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtServer
Procedure FillBaseForPrinting()
	
	If Not BasisChanged Then
		BaseStructure = Documents.CustomerInvoiceServices.StructureOfBaseForPrinting(Object);
		FillPropertyValues(Object, BaseStructure);
	EndIf;
	PrintBasisTable.Load(Documents.CustomerInvoiceServices.PrintBasisTable(Object));
	
EndProcedure

&AtClientAtServerNoContext
Procedure SetVisibilityOfPartnerField(Form)
	
	CLVisibility = Form.Items.ToReadLoyaltyCardClient.Visible;
	If CLVisibility Then
		CLVisibility = UseLoyaltyCards();
	EndIf;
	
	Form.Items.PartnerWithoutCL.Visible = Not CLVisibility;
	Form.Items.Partner.Visible      = CLVisibility;
	
EndProcedure

&AtServerNoContext
Function UseLoyaltyCards()
	
	Return GetFunctionalOption("UseLoyaltyCards");
	
EndFunction

&AtServer
Procedure PlacePaymentDecryptionInTemporaryStorage()
	ARAPAccountingFormWork.PlacePaymentDecryptionInTemporaryStorage(ThisForm);
EndProcedure

&AtServer
Procedure BeforeWriteAtClientServer()
	ARAPAccountingServerCall.FormBeforeRecordingOnClientServer(ThisForm);
EndProcedure

&AtServer
Function UseAdvancedFeaturesOfSalesOrder()
	
	If OrderList.Count() = 0 Then
		Return GetFunctionalOption("UseAdvancedFeaturesOfSalesOrder");
	EndIf;
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	T.ThisIsOrderAsInvoice AS ThisIsOrderAsInvoice
	|FROM
	|	(SELECT
	|		Document.ThisIsOrderAsInvoice AS ThisIsOrderAsInvoice
	|	FROM
	|		Document.SalesOrder AS Document
	|	WHERE
	|		Document.Ref IN(&Ref)
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		Document.ThisIsOrderAsInvoice
	|	FROM
	|		Document.RequestForReturnOfGoodsFromCustomer AS Document
	|	WHERE
	|		Document.Ref IN(&Ref)) AS T
	|
	|GROUP BY
	|	T.ThisIsOrderAsInvoice";
	
	Query.SetParameter("Ref", OrderList);
	
	Upload0 = Query.Execute().Unload();
	If Upload0.Count() = 1 Then
		Return Not Upload0[0].ThisIsOrderAsInvoice;
	Else
		Return GetFunctionalOption("UseAdvancedFeaturesOfSalesOrder");
	EndIf;
	
EndFunction

&AtClient
Procedure Attachable_SBPPaymentVerification()

	CashClientLocalization.CheckSBPPayment(ThisObject, Object.Ref, Object.Counterparty);

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
