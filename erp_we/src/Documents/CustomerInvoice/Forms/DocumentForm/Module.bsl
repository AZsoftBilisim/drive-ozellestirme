#Region Variables

&AtClient
Var CachedValues; //used by the mechanism for processing changes in PM details

&AtClient
Var PreviousRowDetails; //used to unlink the receipt line from the order line

&AtClient
Var CurDataId; //used to pass the current line to the wait handler


&AtClient
Var ParametersForRecording Export;

#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If PrintFormOpeningIsRequired Then
		Return;
	EndIf;
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;

	InfobaseUpdate.CheckObjectProcessed(Object, ThisObject);
	
	DocumentCorrection.OnCreateAtServer(ThisForm, Items.LineCorrection);
	
	// Handler of the "Properties" subsystem
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("Object", Object);
	AdditionalParameters.Insert("ItemForPlacementName", "GroupAdditionalAttributes");
	AdditionalParameters.Insert("DeferredInitialization", True);
	PropertyManager.OnCreateAtServer(ThisForm, AdditionalParameters);
	
	TMCommonUse.CustomizePeripherals(ThisForm);
	UseDiscountAdjustmentsInSales         = GetFunctionalOption("UseDiscountAdjustmentsInSales");
	UseDiscountsMarkupsInSales = GetFunctionalOption("UseDiscountsMarkupsInSales");
	UsePartnersAsCounterparties      = GetFunctionalOption("UsePartnersAsCounterparties");
	UseCreditNotes       = GetFunctionalOption("UseCreditNotes");
	UseSimplifiedPaymentSchemeInSales= GetFunctionalOption("UseSimplifiedPaymentSchemeInSales");
	SaleIsNotSubjectToVAT                    = Enums.VATTaxationTypes.SaleIsNotSubjectToVAT;
	UseRestrictionsOfManualDiscounts       = GetFunctionalOption("UseLimitsForDiscountAdjustmentsInSalesByUsers")
	                                                Or GetFunctionalOption("UseLimitsForDiscountAdjustmentsInSalesByTermsOfSales");
	VarianceFromSalesTermsAndConditions                 = UserRightsCached.VarianceFromSalesTermsAndConditions();
	UsePriceManagementSystem25             = PriceManagementSystemServerCall.UsePriceManagementSystem25();
	
	// Handler of the "Versioning of objects" mechanism
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	
	If Not ValueIsFilled(Object.Ref) Then
		
		OnReadCreateAtServer();
		ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);
		
		
		CalculateDateOfTransferOfOwnership();
		
	ElsIf Parameters.FillingValues.Property("FillByWarehouseDocument") Then
		
		RefillByNotes(Parameters.FillingValues.AnArrayOfOrders);
		Modified = True;
		
	EndIf;
	SetConditionalAppearance();
	
	SetTitleOfPrintDetails();
	SalesServer.SetModeForSelectingGroupsOfWarehouseItems(Items.Warehouse);
	TermsOfAgreement = Object.ARAPObjectSettings = Enums.ARAPObjectSettings.ByCounterpartyContracts;
	SalesServer.SetBlankContractMark(Items, "Contract", TermsOfAgreement);
	
	SetHeadingProductsSenderGroup();
	
	If ClientApplication.CurrentInterfaceVariant() = ClientApplicationInterfaceVariant.Version8_2 Then
		Items.GroupInTotal.BackColor = New Color();
	EndIf;
	
	Items.GoodsPriceKind.QuickChoice = Not GetFunctionalOption("UseSeveralPriceTypes");

	ReadPriceTypeRight = AccessRight("View", Metadata.Documents.CustomerInvoice.TabularSections.Goods.Attributes.PriceKind);
	
	DiscountsMarkupsFillingServer.ConfigureShowMessagesCommand(Object, Items.ShowMessages);
	
	Items.CloseOrder.Enabled = AccessRight("Update",Metadata.Documents.SalesOrder);
	
	// It makes no sense to show the user information about the calculation of discounts to which there is no access.
	Items.GroupProductsInformationAboutDiscounts.Enabled      = AccessRight("View", Metadata.Catalogs.DiscountsMarkups);
	Items.GoodsAssignAutomaticDiscounts.Enabled = AccessRight("View", Metadata.Catalogs.DiscountsMarkups);
	
	SetAvailabilityOfClipboardCommands();
	
	ElementsToFillIn = New Array;
	ElementsToFillIn.Add(Items.DeliveryTimeFrom);
	ElementsToFillIn.Add(Items.DeliveryTimeTo);
	ElementsToFillIn.Add(Items.DeliveryTimeFrom1);
	ElementsToFillIn.Add(Items.DeliveryTimeTo1);
	GoodsDeliveryClientServer.FillTimeFieldSelectionList(ElementsToFillIn);
	
	SetAvailabilityVisibilityOfBuildAndDeliveryItems();
	
	UpdateFlagThereAreAdjustments();
	
	ARAPAccountingFormWork.FormWhenCreatedOnServer(ThisForm);
	
	GeneratingFiscalChecksServer.FormWhenCreatedOnServer(ThisObject);
	
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject);
	// End IntegrationWith1CDocumentManagementSubsystem

	
	Items.DecorationEDOState.Visible = GetFunctionalOption("UseElectronicDocumentExchangeWithCounterparties");
	Items.EPDStateGroup.Visible = GetFunctionalOption("UseElectronicDocumentExchangeWithCounterparties");
	
	
	
	
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
		
	// StandardSubsystems.FilesOperations
	HyperlinkParameters = FilesOperations.FilesHyperlink();
	HyperlinkParameters.Location = "CommandBar";
	FilesOperations.OnCreateAtServer(ThisObject, HyperlinkParameters);
	// End StandardSubsystems.FilesOperations
	
	// StandardSubsystems.SourceDocumentsOriginalsRecording
	SourceDocumentsOriginalsRecording.OnCreateAtServerDocumentForm(ThisObject);
	// End StandardSubsystems.SourceDocumentsOriginalsRecording 

	VATAccountingERP.SetVisibilityOfCommandAndFillInVATRate(ThisObject);
	VATAccountingERP.EstablishVisibilityOfCountryOfImplementation(ThisObject);
	
	AddSBPPaymentStatusUpdateCommand();
	UpdateSalesTagForTobaccoProductsOnlyByMRCLocalization(ThisObject);

	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	If PrintFormOpeningIsRequired Then
		
		Cancel = True;
		SelfServiceClient.PrintingSaleOfGoodsServices(Object.Ref);
		Return;
		
	EndIf;
	
	// StandardSubsystems.Properties
	PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
	// End StandardSubsystems.Properties
	
	PreviousRowDetails = New Structure(
		"Products,
		|Characteristic,
		|Package,
		|Count,
		|NumberOfPackages,
		|Warehouse,
		|ItemsType,
		|ItemVariantsAreUsed,
		|SKU,
		|SalesOrder,
		|RowCode");
	
	EquipmentManagerClient.StartConnectingDevicesWhenYouOpenForm(
		Undefined,
		ThisObject,
		"BarcodeScanner,FiscalCashRegisters");
	
	If Object.OrderSales And Not SalesInExcessOfOrder Then
		
		ItemArray = New Array();
		ItemArray.Add("GoodsCopy");
		ItemArray.Add("ProductItemsContextMenuCopy");
		TMCommonUseClientServer.SetPropertyOfFormElements(Items, ItemArray, "Enabled", False);
		
	EndIf;
	
	If Object.OrderSales And Not SalesInExcessOfOrder 
		And Not ValueIsFilled(Object.Ref)
		And Not ValueIsFilled(Object.Warehouse) Then
		
		If Object.BusinessOperation =
			PredefinedValue("Enum.BusinessTransactions.TransferOfTitleToGoods") Then
			
			If UseSaleByMultipleOrders Then
				MessageText = NStr("vi = 'Hãy điền hàng hóa thông qua lệnh ""Điền theo lệnh""';
									|ru = 'Заполните товары с помощью команды ""Заполнить по распоряжениям""';
									|en = 'Fill in the items by clicking ""Fill in by references""'; fa = 'Fill in the items by clicking ""Fill in by references""';
									|it = 'Fill in the items by clicking ""Fill in by references""';
									|pl = 'Fill in the items by clicking ""Fill in by references""';
									|tr = '""Siparişlere göre doldur"" komutu ile ürünleri doldur'");
			Else
				MessageText = NStr("vi = 'Hãy điền hàng hóa thông qua lệnh ""Điền theo lệnh""';
									|ru = 'Заполните товары с помощью команды ""Заполнить по распоряжению""';
									|en = 'Fill in the items by clicking ""Fill in by reference""'; fa = 'Fill in the items by clicking ""Fill in by reference""';
									|it = 'Fill in the items by clicking ""Fill in by reference""';
									|pl = 'Fill in the items by clicking ""Fill in by reference""';
									|tr = '""Siparişe göre doldur"" komutu ile ürünleri doldur'");
			EndIf;
			
		Else
			
			If UseSaleByMultipleOrders Then
				MessageText = NStr("vi = 'Hãy làm rõ kho giao hàng và điền hàng hóa bằng lệnh ""Điền theo đơn hàng""';
									|ru = 'Уточните склад реализации и заполните товары с помощью команды ""Заполнить по заказам""';
									|en = 'Specify a sale warehouse and fill in goods using command ""Fill in from orders""'; fa = 'Specify a sale warehouse and fill in goods using command ""Fill in from orders""';
									|it = 'Specificare il magazzino di vendita e compilare le merci con l''aiuto del comando ""Compilare in base agli ordini""';
									|pl = 'Określ magazyn realizacji i wypełnij wiersze pozycji za pomocą polecenia ""Wypełnij według zamówienia""';
									|tr = 'Satış deposunu belirleyin ve ""Siparişe ilişkin doldur"" komutunu kullanarak ürünleri tamamlayın'");
			Else
				MessageText = NStr("vi = 'Hãy làm rõ kho giao hàng và điền hàng hóa bằng lệnh ""Điền theo đơn hàng""';
									|ru = 'Уточните склад реализации и заполните товары с помощью команды ""Заполнить по заказу""';
									|en = 'Specify a sale warehouse and fill in goods using command ""Fill in from order""'; fa = 'Specify a sale warehouse and fill in goods using command ""Fill in from order""';
									|it = 'Specificare il magazzino di vendita e compilare le merci con l''aiuto del comando ""Compilare in base all''ordine""';
									|pl = 'Określ magazyn realizacji i wypełnij produkty za pomocą polecenia ""Wypełnij według zamówienia""';
									|tr = 'Satış deposunu belirleyin ve ""Siparişe göre doldur"" komutunu kullanarak ürünleri tamamlayın'");
			EndIf;
			
		EndIf;
		
		CommonClient.MessageToUser(
			MessageText,
			Object.Ref,
			"Object.Warehouse",);
	EndIf;
	
	
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// The end of the standard subsystem.Pluggable commands
	// Standard subsystems.Worksfiles
	FilesOperationsClient.OnOpen(ThisObject, Cancel);
	// End StandardSubsystems.FilesOperations
	
	EnableWaitingHandlerReceivingCarriers();
	
	CashClientLocalization.AttachablePaymentVerificationViaServices(ThisObject, Object.Ref, Object.Counterparty);
	
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)
	
	If TMCommonUseClientServer.AnExternalUserIsAuthorized() Then
		PrintFormOpeningIsRequired = True;
		Return;
	EndIf;
	
	// StandardSubsystems.AccessManagement
	AccessManagement.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.AccessManagement
	
	// Handler of the "Date-change" mechanism
	PeriodClosingDates.ObjectOnReadAtServer(ThisForm, CurrentObject);
	
	DocumentCorrection.OnReadAtServer(ThisForm, Items.LineCorrection);
	
	OnReadCreateAtServer();
	
	PropertyManager.OnReadAtServer(ThisForm, CurrentObject);
	
	GeneratingFiscalChecksServer.FormWhenReadingOnServer(ThisObject);
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	// End StandardSubsystems.AttachableCommands

	
	FormEvents.OnReadAtServer(ThisObject, CurrentObject);
	UpdateSalesTagForTobaccoProductsOnlyByMRCLocalization(ThisObject);
	
EndProcedure

&AtClient
Procedure URLProcessing(FormattedStringURL, StandardProcessing)

	FormEventsClient.URLProcessing(ThisObject, FormattedStringURL, StandardProcessing);

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
	
	UpdateOrderDeviations();
	FillInServiceDetailsForProductRange();
	ChangeHeadingsForSalesLayoutOption();
	ReusablePackageServer.UpdateNoReturnableContainerAttribute(Object.Goods, Object.ToReturnReusablePackage);
	TMCommonUse.FillInDuplicateDependentPropsInCollection(Object.Goods, DependentDetails());
	UpdateTextDocumentsBasedOn();
	ARAPAccountingFormWork.FormAfterRecordingOnServer(ThisForm, CurrentObject.AdditionalProperties);

	CalculateTotals_(ThisObject);
	UpdateVHFWarehouseObligation();
	SetAvailabilityOfItemsByStatusServer();
	


	CurrentDeliveryMethod = CurrentObject.DeliveryMethod;
	
	
	FormEvents.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	
	GeneratingFiscalChecksServer.FormWhenChangingBankingDetails(ThisObject);
	LinesOfBusinessServer.AfterWriteAtServer(ThisObject);
	
	ProvisionInDocumentsServer.CheckToRunBackgroundInventoryAllocationJob();
	
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)
	
	ForceCloseTheForm = True;
	
	If Exit Then
		Return;
	EndIf;
	
	CloseKmVerificationSessionOnCCT(Cancel);
	
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
		PerformChecksAndAskQuestionsBeforeRecording(Cancel, WriteParameters);
	EndIf;
	
	FillInIndicatorsOfPaymentStagesClient();
	TMCommonUseClient.RecordObjectIfNecessary(ThisObject, WriteParameters, Cancel);
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	// Subsystem "Properties"
	If PropertyManagerClient.ProcessNotifications(ThisObject, EventName, Parameter) Then
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
	
	If EventName = "LoyaltyCardIsRead"
		And Parameter.OwnerForm = UUID Then
		LoyaltyCardIsRead(Parameter.LoyaltyCard);
	EndIf;
	
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
		
		SetParameters = New Structure;
		SetParameters.Insert("ProductsInSet", Parameter.ProductsInSet);
		SetParameters.Insert("ItemVariantOfSet", Parameter.ItemVariantOfSet);
		If Parameter.Property("SalesOrder") Then
			SetParameters.Insert("SalesOrder", Parameter.SalesOrder);
		EndIf;
		SetParameters.Insert("ExceedingOrder", True);
		SetParameters.Insert("DialColumns", DialColumns(ThisObject));
		
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
		OpeningParameters.Insert("Warehouse", Object.Warehouse);
		OpeningParameters.Insert("HideCommandRemainingQuantityInWarehouses", False);
		OpeningParameters.Insert("Organization", Object.Organization);
		
		OpenForm("DataProcessor.EditSet.Form.Form", OpeningParameters, ThisObject, UUID);
		
	EndIf;
	
	If EventName = "Write_SaleAdjustment"
		And TypeOf(Parameter) = Type("Structure")
		And Parameter.Property("DocumentBasis")
		And Parameter.DocumentBasis = Object.Ref Then
		Recording_AdjustingImplementationOnServer();
	EndIf;
	
	If EventName = "Write_GoodsIssueNote" Then
		ThereIsSpendingOrderForShippingOrders(Object.Ref, ShipmentStarted);
	EndIf;
	
	If EventName = "Write_InvoiceIssued"
		And (Parameter.Property("OwnerForm") And Parameter.OwnerForm = UUID
			Or Parameter.Property("ListOfGrounds") And Parameter.ListOfGrounds.FindByValue(Object.Ref) <> Undefined) Then
		UpdateTextDocumentsBasedOn();
	EndIf;
	If EventName = "Write_ApplicationForImportOfGoodsReceived"
		And TypeOf(Parameter) = Type("Structure")
		And Parameter.Basis1.Find(Object.Ref) <> Undefined Then
		UpdateTextDocumentsBasedOn();
	EndIf;
	

	DocumentCorrectionClient.NotificationProcessing(ThisObject, EventName, Parameter, Source);
	
	FormEventsClient.NotificationProcessing(ThisObject, EventName, Parameter, Source);
	
	// StandardSubsystems.FilesOperations
	FilesOperationsClient.NotificationProcessing(ThisObject, EventName);
	// End StandardSubsystems.FilesOperations

	NotificationProcessingLocalization(EventName, Parameter, Source);
	
	// StandardSubsystems.SourceDocumentsOriginalsRecording	
	SourceDocumentsOriginalsRecordingClient.NotificationHandlerDocumentForm(EventName,ThisObject);
	// End StandardSubsystems.SourceDocumentsOriginalsRecording
	
	If EventName = "WhenChangingAgreement"
		And Source = ThisObject Then
		Modified = True;
		If ValueIsFilled(Object.Ref) Then
			Attachable_WhenChanging_SetAvailabilityOfItemsByStatusServer(Items[Parameter]);
		Else
			ContractOnChange(Items[Parameter]);
		EndIf;
	EndIf;
	
	If EventName = "WhenChangingClientSContract"
		And Source = ThisObject Then
		Modified = True;
		CustomerContractOnChange(Items[Parameter]);
	EndIf;
	
EndProcedure

&AtClient
Procedure ChoiceProcessing(ValueSelected, ChoiceSource)
	
	If ChoiceSource.FormName = "Document.CustomerInvoice.Form.SelectionOfGoodsFromOrderForm" Then
		
		ProcessingProductSelectionFromOrder(ValueSelected.GoodsAddressInStorage);
		
	ElsIf ChoiceSource.FormName = "DataProcessor.SelectGoodsToSalesDocument.Form.Form" Then
		
		ClearMessages();
		HandlingSelectionSelectionOnClient(ValueSelected);
		
	ElsIf ChoiceSource.FormName = "DataProcessor.SelectGoodsTransferredToCustody.Form.Form" Then
		
		ClearMessages();
		PricesCalculated = False;
		
		SelectionProcessingSelectionOfTransferredGoods(ValueSelected, PricesCalculated);
		SalesClient.NotifyAboutEndOfFillingInPricesUnderAgreement(PricesCalculated);
		
	ElsIf ChoiceSource.FormName = "CommonForm.PrintingDetailsOfSales" Then
		
		If ValueSelected <> Undefined Then
			
			Modified = True;
			
			If GoodsDeliveryClientServer.UsedDelivery25() Then
				
				If CommonClientServer.HasAttributeOrObjectProperty(ValueSelected, "DeliveryZone") Then
					FillPropertyValues(Object, ValueSelected,, "DeliveryZone");
				EndIf;
				
				FillInAndSetDeliveryAttributes = False;
				If Not Object.DeliveryIsRequired Then
					FillInAndSetDeliveryAttributes = (Object.GoodsRecipient <> ValueSelected.GoodsRecipient);
				EndIf;
				
			Else
				
				FillInAndSetDeliveryAttributes = (Object.GoodsRecipient <> ValueSelected.GoodsRecipient);
				FillPropertyValues(Object, ValueSelected);
				
			EndIf;
			
			WhenChangingAttributesOfImplementationSPrintServer(FillInAndSetDeliveryAttributes);
		EndIf;
		
	ElsIf VATAccountingERPClient.FinishedEditingInvoiceIssued(ValueSelected, ChoiceSource) Then
		
		UpdateTextDocumentsBasedOn();
		
	ElsIf ChoiceSource.FormName = "DataProcessor.SelectReusablePackage.Form.Form" Then
		
		FillMultiTurnContainersFromStorageServer(ValueSelected.AddressOfReusableContainerInStorage);
		ReusablePackageClient.NotifyUserAboutFillingMultiTurnContainers();
		DiscountsMarkupsFillingClient.ResetDiscountsCalculatedFlag(ThisForm);
	
	ElsIf ChoiceSource.FormName = "Catalog.BusinessStructure.Form.ChoiceForm" Then
	
		SalesClient.ProcessingUnitSelection(Object.Goods, Items.Goods.SelectedRows, ValueSelected);
	
	ElsIf ChoiceSource.FormName = "Catalog.InventoryKinds.Form.InventoryOwnerAttributesForm" Then	
		
		GetStockTypesFromStorage(ValueSelected);
		
	ElsIf ProductsClient.ThisIsIndicationOfSeries(ChoiceSource) Then
		
		ProductsClient.ProcessSeriesIndication(ThisForm, SeriesSpecificationParameters, ValueSelected);

		ProductsSeriesRecalculatePrices();
		
	ElsIf ChoiceSource.FormName = "Catalog.Persons.Form.ListForm" Then
		
		Object[CurrentItem.Name] = ValueSelected;
		
	EndIf;
	
	If Window <> Undefined Then
		Window.Activate();
	EndIf;
	
	SetWhetherWarehouseIsFull();
	
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	
	WriteParameters.Insert("NotificationDocumentKeys",
		OperationsWithDocumentJournalsClient.GetKeyParametersForDocument(Object.Ref, Object.Date,
		Object.BusinessOperation));
		
	Notify("Write_CustomerInvoice", WriteParameters, Object.Ref);
	ARAPAccountingClient.FormAfterRecording(ThisForm);
		

	ConfigurationModificationClientOverridable.AfterWrite(ThisForm, WriteParameters);
	
	TMCommonUseClient.PerformActionsAfterRecording(ThisForm, Object, WriteParameters);
	
	// StandardSubsystems.AttachableCommands
	If CommonClient.SubsystemExists("StandardSubsystems.AttachableCommands") Then
		ModuleAttachableCommandsClient = CommonClient.CommonModule("AttachableCommandsClient");
		ModuleAttachableCommandsClient.AfterWrite(ThisObject, Object, WriteParameters);
	EndIf;
	// End StandardSubsystems.AttachableCommands
	
	FormEventsClient.AfterWrite(ThisObject, WriteParameters);
	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	// Handler of the "Properties" mechanism
	PropertyManager.BeforeWriteAtServer(ThisForm, CurrentObject);
	

	ConfigurationModificationOverridable.BeforeWriteAtServer(ThisForm, Cancel, CurrentObject, WriteParameters);

	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.BeforeWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	// End IntegrationWith1CDocumentManagementSubsystem
	
	ARAPAccountingServer.BeforeWriteAtServer(ThisForm, CurrentObject);

	
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
	
	If CurrentPage.Name = "MainGroup3" Then
		ARAPAccountingClient.UpdateHyperlinkTextPaymentSteps(ThisForm);
		ARAPAccountingClientServer.UpdateHyperlinkText(ThisForm);
	EndIf;
	
EndProcedure

&AtClient
Procedure LabelHeaderSalesOrdersClick(Item, StandardProcessing)
	
	StandardProcessing = False;
	
	If Object.BusinessOperation =
		PredefinedValue("Enum.BusinessTransactions.TransferOfTitleToGoods") Then
		TitleOfDocumentListForm = NStr("vi = 'Lệnh (%DocumentsCount%)';
										|ru = 'Распоряжения (%DocumentsCount%)';
										|en = 'References (%DocumentsCount%)'; fa = 'References (%DocumentsCount%)';
										|it = 'Disposizioni (%DocumentsCount%)';
										|pl = 'Zamówienia (%DocumentsCount%)';
										|tr = 'Talimatlar (%DocumentsCount%)'")
	Else
		TitleOfDocumentListForm = NStr("vi = 'Đơn hàng của khách (%DocumentsCount%)';
										|ru = 'Заказы клиентов (%DocumentsCount%)';
										|en = 'Sales orders (%DocumentsCount%)'; fa = 'Sales orders (%DocumentsCount%)';
										|it = 'Ordini dei clienti (%DocumentsCount%)';
										|pl = 'Zamówienia klientów (%DocumentsCount%)';
										|tr = 'Satış siparişleri (%DocumentsCount%)'");
	EndIf;
	
	OpenForm(
		"CommonForm.ViewingListOfDocuments",
		New Structure("DocumentsList, Title",
			OrderList,
			TitleOfDocumentListForm
		),
		ThisForm,,,, Undefined, FormWindowOpeningMode.LockOwnerWindow);
	
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
Procedure StatusOnChange(Item)
	
	StatusOnChangeServer();
	
EndProcedure

&AtClient
Procedure PartnerOnChange(Item)
	
	If Not ValueIsFilled (Object.Partner) Then
		GoodsDeliveryClientServer.ClearDeliveryDetails(Items,Object);
		SetVisibilityOfShipmentBanToPartner();
		
		UpdateDeliveryPlanningView(ThisObject);
		
		Return;
	EndIf;
	
	ContractBeforeModifications = Object.Contract;
	
	WhenChangingPartnerServer();
	
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
Procedure ContractCreating(Item, StandardProcessing)
	
	SalesClient.OpenContractCreationForm(ThisObject, Item, "Object.Contract", Object.Partner, StandardProcessing);
	
EndProcedure

&AtClient
Procedure ContractOnChange(Item)
	
	BasisChanged = BasisChanged And ValueIsFilled(Object.Basis);
	
	If Object.OrderSales And Contract <> Object.Contract And Not OrdersAreUsedAsInvoices() Then
				
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
			
	ElsIf SalesViaCommissionAgent And ValueIsFilled(TypeOfContractPrice(Object.Contract).PriceKind) Then
	
		Notification = New CallbackDescription("ContractOnChangeCompletion", ThisObject);
		EnterprisePricesFillingClient.AskQuestionAboutRecalculatingPriceWhenChangingAgreement(Object, Notification);
	
	Else
		
		ContractOnChangeServer();
	
	EndIf;
	

	
EndProcedure

&AtClient
Procedure ContractOnChangeCompletion(QuestionResult, AdditionalParameters) Export 
	
	ClearMessages();
	
	FlagFillThePricesByTermsOfSales = False;
	
	If QuestionResult = "Cancel" Then
		
		Object.Contract = Contract;
		
	ElsIf QuestionResult = "UnlinkFromOrder" Then
		
		Object.OrderSales = False;
		OrderSalesOnChangeServer();
		
	EndIf;

	If Not QuestionResult = DialogReturnCode.Cancel And QuestionResult = True Then
		TypeOfContractPrice = TypeOfContractPrice(Object.Contract);
		If EnterprisePricesFillingClient.YouNeedToFillInPricesByType(Object, TypeOfContractPrice) Then
			FlagFillThePricesByTermsOfSales = True;
		EndIf;
	EndIf;
		
	PricesCalculated = False;
	ErrorText = "";
	ContractOnChangeCompletionServer(FlagFillThePricesByTermsOfSales, PricesCalculated, ErrorText);

	If FlagFillThePricesByTermsOfSales Then
		SalesClient.NotifyAboutEndOfFillingInPricesUnderContract(PricesCalculated, ErrorText);
	EndIf;
		
EndProcedure

&AtClient
Procedure TermsOnChange(Item)
		
	Terms = Object.Terms;
	
	If Not ValueIsFilled(Object.Terms) Then
		TermsClearingServer();
		Return;
	EndIf;
		
	ClearMessages();
	
	ContractBeforeModifications = Object.Contract;
	DiscountsMarkupsFillingClient.ResetDiscountsCalculatedFlag(ThisForm);
	TermsOnChangeServer();
	SalesClient.NotifyEndOfFillingInTermsOfSale();
	FillOperationSelectionList();
	
	If SalesViaCommissionAgent And Not ContractBeforeModifications = Object.Contract And ValueIsFilled(Object.Contract)
		And ValueIsFilled(PriceTypeUnderContract) Then
			Notification = New CallbackDescription("ContractOnChangeCompletion", ThisObject);
			EnterprisePricesFillingClient.AskQuestionAboutRecalculatingPriceWhenChangingAgreement(Object, Notification);


	EndIf;
	
EndProcedure

&AtClient
Procedure BusinessOperationOnChange(Item)
	
	ClearMessages();
	
	ContractBeforeModifications = Object.Contract;
	BusinessOperationOnChangeServer();
	
	If SalesViaCommissionAgent And Not ContractBeforeModifications = Object.Contract
		And ValueIsFilled(Object.Contract)
		And ValueIsFilled(PriceTypeUnderContract) Then
		Notification = New CallbackDescription("ContractOnChangeCompletion", ThisObject);
		EnterprisePricesFillingClient.AskQuestionAboutRecalculatingPriceWhenChangingAgreement(Object, Notification);


	EndIf;
	
EndProcedure

&AtClient
Procedure VATTaxationOnChange(Item)
	
	ClearMessages();
	VATTaxationOnChangeServer();
	DiscountsMarkupsFillingClient.ResetDiscountsCalculatedFlag(ThisForm);
	
EndProcedure

&AtClient
Procedure PriceIncludesVATOnChange(Item)
	
	PriceIncludesVATOnChangeServer(CachedValues);	
	DiscountsMarkupsFillingClient.ResetDiscountsCalculatedFlag(ThisForm);
	
EndProcedure

&AtServerNoContext
Function ParametersForRegisteringInvoicesIssuedServer(Val Object)
	
	Return Documents.CustomerInvoice.ParametersForRegisteringInvoicesIssued(Object);
	
EndFunction	


&AtClient
Procedure TextDocumentsBasedOnURLProcessing(Item, FormattedStringURL, StandardProcessing)
	
	ClearMessages();
	
	RegistrationParameters = ParametersForRegisteringInvoicesIssuedServer(Object);
	VATAccountingERPClient.ProcessingNavigationLinkInvoicesIssued(ThisForm, FormattedStringURL, StandardProcessing, RegistrationParameters);
	
	FiscalOperationNavigationLinkProcessing(Item, FormattedStringURL, StandardProcessing);
	
	TextDocumentsBasedOnURLProcessingLocalization(Item, FormattedStringURL, StandardProcessing);
	
EndProcedure

&AtClient
Procedure DateOnChange(Item)
	
	Var PricesCalculated;
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	
	ClearMessages();
	
	DiscountsMarkupsFillingClient.ResetDiscountsCalculatedFlag(ThisObject);
	
	If Not Object.OrderSales
		Or SalesInExcessOfOrder
			And Object.Goods.Total("OrderDiscrepancy_3") > 0 Then
		
		ArrayOfBusinessOperations25 = New Array;
		ArrayOfBusinessOperations25.Add(PredefinedValue("Enum.BusinessTransactions.SalesViaCommissionAgent"));
		ArrayOfBusinessOperations25.Add(PredefinedValue("Enum.BusinessTransactions.SalesViaCommissionAgentGoodsInTransit"));
		
		If ArrayOfBusinessOperations25.Find(Object.BusinessOperation) <> Undefined Then
		
			If ValueIsFilled(Object.Contract) Then
				
				Notification = New CallbackDescription("ContractOnChangeCompletion", ThisObject);
				EnterprisePricesFillingClient.AskQuestionAboutRecalculatingPriceWhenChangingAgreement(Object, Notification);
				Return;
				
			EndIf;
			
		Else
			
			Notification = New CallbackDescription("DateOnChangeCompletion", ThisObject);
			EnterprisePricesFillingClient.AskQuestionAboutRecalculatingPriceWhenDateChanges(Object, Notification);
			Return;
			
		EndIf;
		
	EndIf;
	
	RecalculatePrices_ = False;
	DateOnChangeServer(RecalculatePrices_, PricesCalculated);
	
	DocumentDateBeforeChange = Object.Date;
	
	If RecalculatePrices_ Then
		SalesClient.NotifyAboutEndOfFillingInPricesUnderAgreement(PricesCalculated);
	EndIf;
	
	
EndProcedure

&AtClient
Procedure DateOnChangeCompletion(QuestionResult, AdditionalParameters) Export 
	
	Var PricesCalculated;
	
	If Not QuestionResult = DialogReturnCode.Cancel Then
		DateOnChangeServer(QuestionResult, PricesCalculated, QuestionResult);
	EndIf;
	
	DocumentDateBeforeChange = Object.Date;
	
	If QuestionResult = True Then
		SalesClient.NotifyAboutEndOfFillingInPricesUnderAgreement(PricesCalculated);
	EndIf;
	
EndProcedure

&AtClient
Procedure OrganizationOnChange(Item)
	
	ClearMessages();
	
	PerformanceMonitorClient.TimeMeasurement(True,
		"Document.CustomerInvoice.DocumentForm.OrganizationOnChange");
	
	ContractBeforeModifications = Object.Contract;
	OrganizationOnChangeServer();
	
	If SalesViaCommissionAgent And Not ContractBeforeModifications = Object.Contract
		And ValueIsFilled(Object.Contract)
		And ValueIsFilled(PriceTypeUnderContract) Then
		Notification = New CallbackDescription("ContractOnChangeCompletion", ThisObject);
		EnterprisePricesFillingClient.AskQuestionAboutRecalculatingPriceWhenChangingAgreement(Object, Notification);
	EndIf;
	
	DiscountsMarkupsFillingClient.ResetDiscountsCalculatedFlag(ThisForm);
	

	
EndProcedure

&AtClient
Procedure WarehouseOnChange(Item)
	
	ClearMessages();
	
	PerformanceMonitorClient.TimeMeasurement(True,
		"Document.CustomerInvoice.DocumentForm.WarehouseOnChange");
	
	ClearLines_ = False;
	UntieAllLinesFromOrder = False;
	
	OrdersAreUsedAsInvoices = OrdersAreUsedAsInvoices();
	
	If OrdersAreUsedAsInvoices Then
		
		WarehouseWhenFragmentChanges(False, False);
		
	ElsIf Warehouse <> Object.Warehouse
		And (ValueIsFilled(Warehouse)
			Or Not OrdersAreUsedAsInvoices) Then
				
		If Object.OrderSales
			And Object.Goods.Count() > 0 Then
			
			If Not ItIsGroupOfWarehousesAndWarehousesUsedByWHForSale(Object.Warehouse) Then
				
				ButtonsList = New ValueList;
				
				If SalesInExcessOfOrder
					And Not OrdersAreUsedAsInvoices Then
					
					ButtonsList.Add("Continue", NStr("vi = 'Xóa hàng hóa';
													|ru = 'Очистить товары';
													|en = 'Clear goods'; fa = 'Clear goods';
													|it = 'Cancellare le merci';
													|pl = 'Oczyść wiersze pozycji';
													|tr = 'Ürünleri temizle'"));
					ButtonsList.Add("Unlink", NStr("vi = 'Bỏ khỏi đơn hàng';
													|ru = 'Отвязать от заказа';
													|en = 'Unlink from order'; fa = 'جدا کردن از سفارش';
													|it = 'Scollegare dall''ordine';
													|pl = 'Odłącz od zamówienia';
													|tr = 'Siparişten ayır'"));
					QueryText = NStr("vi = 'Khi thay đổi kho, cần xóa danh sách ""Hàng hóa"" hoặc bỏ liên kết dòng với đơn hàng. Tiếp tục?';
									|ru = 'При изменении склада список ""Товары"" необходимо очистить, либо отвязать строки от заказа. Продолжить?';
									|en = 'It is required to clear the Item list or unlink lines from the order while changing the warehouse. Continue?'; fa = 'It is required to clear the Item list or unlink lines from the order while changing the warehouse. Continue?';
									|it = 'Al cambio del magazzino, l''elenco ""Merci"" deve essere cancellato o le righe devono essere scollegate dall''ordine. Continuare?';
									|pl = 'Po zmianie magazynu lista ""Wiersze pozycji"" musi zostać wyczyszczona lub należy odłączyć wiersze od zamówienia. Kontynuować?';
									|tr = 'Stok değiştiğinde, ""Ürünler"" listesinin temizlenmesi veya satırların siparişten ayrılması gerekir. Devam edilsin mi?'");
					
				Else
					
					ButtonsList.Add("Continue", NStr("vi = 'Tiếp tục';
													|ru = 'Продолжить';
													|en = 'Continue'; fa = 'ادامه';
													|it = 'Continuare';
													|pl = 'Continue';
													|tr = 'Devam'"));
					QueryText = NStr("vi = 'Danh sách ""Hàng hóa"" sẽ bị xóa. Tiếp tục?';
									|ru = 'Список ""Товары"" будет очищен. Продолжить?';
									|en = 'The Item list will be cleared. Continue?'; fa = 'The Item list will be cleared. Continue?';
									|it = 'L''elenco ""Merci"" verrà cancellato. Continuare?';
									|pl = 'Lista ""Towaty"" zostanie wyczyszczona. Kontynuować?';
									|tr = '""Ürünler"" listesi temizlenecek. Devam edilsin mi?'")
					
				EndIf;
				
				ButtonsList.Add("Cancel", NStr("vi = 'Hủy bỏ';
												|ru = 'Отмена';
												|en = 'Cancel'; fa = 'انصراف';
												|it = 'Annulla';
												|pl = 'Cancel';
												|tr = 'İptal'"));
				
				ShowQueryBox(
					New CallbackDescription("WarehouseOnChangeCompletion",
						ThisObject,
						New Structure("UntieAllLinesFromOrder", UntieAllLinesFromOrder)),
					QueryText,
					ButtonsList);
					
				Return;
				
			EndIf;
			
		EndIf;
		
		WarehouseWhenFragmentChanges(UntieAllLinesFromOrder, ClearLines_);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure WarehouseOnChangeCompletion(QuestionResult, AdditionalParameters) Export
    
	UntieAllLinesFromOrder = AdditionalParameters.UntieAllLinesFromOrder;
	Response = QuestionResult;
    If Response = "Cancel" Then
        
        Object.Warehouse = Warehouse;
        Return;
    ElsIf Response = "Unlink" Then
        UntieAllLinesFromOrder = True;
        ClearLines_ = False;
    Else
        ClearLines_ = True;
    EndIf;
    
    WarehouseWhenFragmentChanges(UntieAllLinesFromOrder, ClearLines_);

EndProcedure

&AtClient
Procedure WarehouseWhenFragmentChanges(Val UntieAllLinesFromOrder, Val ClearLines_)
	
	WarehouseOnChangeServer(ClearLines_, UntieAllLinesFromOrder);
	DiscountsMarkupsFillingClient.ResetDiscountsCalculatedFlag(ThisForm);
	
EndProcedure

&AtClient
Procedure ManagerOnChange(Item)
	
	FillInSubordinatePropertiesForStatistics("Manager");
	
	DiscountsMarkupsFillingClient.ResetDiscountsCalculatedFlag(ThisForm);
	
EndProcedure

&AtClient
Procedure OrderSalesOnChange(Item)
	
	SalesOrder = Undefined;
	SetAvailabilityOfClipboardCommandsOnClient();
	ClearMessages();
	If Object.OrderSales And ShipmentStarted Then
		
		ShowMessageBox(Undefined, NStr("vi = 'Chứng từ này đã bắt đầu giao hàng. Không được phép thay đổi dấu hiệu 
			|""Giao hàng theo lệnh"" sau khi bắt đầu giao hàng.';
			|ru = 'По данному документу уже начата отгрузка. Менять признак 
			|""Реализация по заказу"" после начала отгрузки не допускается.';
			|en = 'Shipment has already started by this document. Cannot change
			|check box ""Order sale"" after start of shipment.'; fa = 'Shipment has already started by this document. Cannot change
			|check box ""Order sale"" after start of shipment.';
			|it = 'La spedizione per il documento è già iniziata. La modifica dell''indicazione 
			| ""Vendita in base ordine"" dopo l''inizio della spedizione non è consentita.';
			|pl = 'Na podstawie tego dokumentu już rozpoczęto wysyłka. Po rozpoczęciu wysyłki nie można zmienić właściwości 
			| ""Sprzedaż wg zamówienia"".';
			|tr = 'Bu belge üzerinde sevkiyat zaten başlamıştır. Sevkiyat başladıktan sonra ""Siparişe ilişkin transfer"" işaretinin değiştirilmesine
			| izin verilmez.'"));
		Object.OrderSales = False;
		
		Return
	EndIf;
	
	If Object.OrderSales Then
		
		If UseSaleByMultipleOrders Then
		
			If Object.BusinessOperation =
				PredefinedValue("Enum.BusinessTransactions.TransferOfTitleToGoods") Then
				
				If Object.Goods.Count() = 0 Then
					QueryText = NStr("vi = 'Sẽ điền lại danh sách Hàng hóa bởi số dư hàng hóa chưa lập chứng từ theo lệnh. Tiếp tục?';
									|ru = 'Список Товары будет перезаполнен остатками неоформленных товаров по распоряжениям. Продолжить?';
									|en = 'The ""Goods"" list will be refilled with remaining unregistered reference goods. Continue?'; fa = 'The ""Goods"" list will be refilled with remaining unregistered reference goods. Continue?';
									|it = 'The ""Goods"" list will be refilled with remaining unregistered reference goods. Continue?';
									|pl = 'The ""Goods"" list will be refilled with remaining unregistered reference goods. Continue?';
									|tr = 'Ürünler listesi siparişe ilişkin işlenmemiş ürünlerin bakiyeleri ile yeniden doldurulacaktır. Devam edilsin mi?'");
				Else
					QueryText = NStr("vi = 'Các dòng trong danh sách Hàng hóa sẽ được gắn với các dòng trong lệnh. Tiếp tục?';
									|ru = 'Строки в списке Товары будут привязаны к строкам распоряжений. Продолжить?';
									|en = 'The ""Goods"" list lines will be linked to the reference lines. Continue?'; fa = 'The ""Goods"" list lines will be linked to the reference lines. Continue?';
									|it = 'The ""Goods"" list lines will be linked to the reference lines. Continue?';
									|pl = 'The ""Goods"" list lines will be linked to the reference lines. Continue?';
									|tr = 'Ürünler listesindeki satırlar sipariş satırlarına bağlanacaktır. Devam edilsin mi?'");
				EndIf;
				
			Else
				
				If Object.Goods.Count() = 0 Then
					QueryText = NStr("vi = 'Danh sách Hàng hóa sẽ được điền lại bằng số dư hàng hóa chưa lập theo đơn hàng. Tiếp tục?';
									|ru = 'Список Товары будет перезаполнен остатками неоформленных товаров по заказам. Продолжить?';
									|en = 'The Item list will be refilled by remaining unregistered goods against orders. Continue?'; fa = 'The Item list will be refilled by remaining unregistered goods against orders. Continue?';
									|it = 'L''elenco Merci sarà ricompilato con giacenze delle merci non formalizzate per ordini. Continuare?';
									|pl = 'Lista Wiersze pozycji zostanie ponownie wypełniona przez resztki nieodebranych towarów z zamówień. Kontynuować?';
									|tr = 'Ürünler listesi siparişe ilişkin işlenmemiş ürünlerin bakiyeleri ile yeniden doldurulacaktır. Devam edilsin mi?'");
				Else
					QueryText = NStr("vi = 'Dòng trong danh sách Hàng hóa sẽ được gắn với dòng của đơn hàng. Tiếp tục?';
									|ru = 'Строки в списке Товары будут привязаны к строкам заказов. Продолжить?';
									|en = 'The Item list lines will be linked with the order lines. Continue?'; fa = 'The Item list lines will be linked with the order lines. Continue?';
									|it = 'Le righe nell''elenco ""Merci"" saranno associate alle righe degli ordini. Continuare?';
									|pl = 'Wiersze na liście Wiersze pozycji będą powiązane z wierszami zamówień. Kontynuować?';
									|tr = 'Ürünler listesindeki satırlar sipariş satırlarına bağlanacaktır. Devam edilsin mi?'");
				EndIf;
				
			EndIf;
		
		Else
			
			FilterParameters = New Structure();
			FilterParameters.Insert("Currency",                     Object.Currency);
			FilterParameters.Insert("Counterparty",                 Object.Counterparty);
			FilterParameters.Insert("Contract",                    Object.Contract);
			FilterParameters.Insert("VATTaxation",         Object.VATTaxation);
			FilterParameters.Insert("Organization",                Object.Organization);
			FilterParameters.Insert("Partner",                    Object.Partner);
			FilterParameters.Insert("SalesOpportunity",                     Object.SalesOpportunity);
			FilterParameters.Insert("Terms",                 Object.Terms);
			FilterParameters.Insert("PriceIncludesVAT",            Object.PriceIncludesVAT);
			FilterParameters.Insert("BusinessOperation",      Object.BusinessOperation);
			FilterParameters.Insert("ToReturnReusablePackage",  Object.ToReturnReusablePackage);
			FilterParameters.Insert("LineOfBusiness",    Object.LineOfBusiness);
			FilterParameters.Insert("ToReturnReusablePackage",  Object.ToReturnReusablePackage);
			FilterParameters.Insert("PackageDepositIsRequired",       Object.PackageDepositIsRequired);
			FilterParameters.Insert("UseAdvancedFeaturesOfSalesOrder", UseAdvancedFeaturesOfSalesOrder);
			
			OpenForm(
				"Document.CustomerInvoice.Form.ReferenceChoiceForm",
				New Structure("Filter,Warehouse,Recorder", FilterParameters, Object.Warehouse, Object.Ref),,,,, New CallbackDescription("ImplementationByOrdersWhenChangedAfterSelection", ThisObject), FormWindowOpeningMode.LockOwnerWindow);
			Return;
			
		EndIf;
			
	Else
		
		If Object.Goods.Count() > 0 Then
			
			If Object.BusinessOperation =
				PredefinedValue("Enum.BusinessTransactions.TransferOfTitleToGoods") Then
				
				If UseSaleByMultipleOrders Then
					QueryText = NStr("vi = 'Các dòng trong danh sách Hàng hóa sẽ không còn liên kết với các dòng trong lệnh. Tiếp tục?';
									|ru = 'Строки в списке Товары перестанут быть связанными со строками распоряжения. Продолжить?';
									|en = 'The ""Goods"" list lines will be unlinked from the reference lines. Continue?'; fa = 'The ""Goods"" list lines will be unlinked from the reference lines. Continue?';
									|it = 'The ""Goods"" list lines will be unlinked from the reference lines. Continue?';
									|pl = 'The ""Goods"" list lines will be unlinked from the reference lines. Continue?';
									|tr = 'Ürünler listesindeki satırlar artık sipariş satırlarına ilişkilendirilmeyecektir. Devam edilsin mi?'");
				Else
					QueryText = NStr("vi = 'Các dòng trong danh sách Hàng hóa sẽ không còn liên kết với các dòng trong lệnh. Tiếp tục?';
									|ru = 'Строки в списке Товары перестанут быть связанными со строками распоряжения. Продолжить?';
									|en = 'The ""Goods"" list lines will be unlinked from the reference lines. Continue?'; fa = 'The ""Goods"" list lines will be unlinked from the reference lines. Continue?';
									|it = 'The ""Goods"" list lines will be unlinked from the reference lines. Continue?';
									|pl = 'The ""Goods"" list lines will be unlinked from the reference lines. Continue?';
									|tr = 'Ürünler listesindeki satırlar artık sipariş satırlarına ilişkilendirilmeyecektir. Devam edilsin mi?'");
				EndIf;
			Else
				If UseSaleByMultipleOrders Then
					QueryText = NStr("vi = 'Dòng trong danh sách Hàng hóa không còn liên kết với dòng trong đơn hàng. Tiếp tục?';
									|ru = 'Строки в списке Товары перестанут быть связанными со строками заказов. Продолжить?';
									|en = 'The Item list lines will be unlinked from the lines in the orders. Continue?'; fa = 'The Item list lines will be unlinked from the lines in the orders. Continue?';
									|it = 'Le righe nell''elenco Merci non saranno più associate alle righe degli ordini. Continuare?';
									|pl = 'Wiersze na liście Wiersze pozycji nie będą więcej powiązane z wierszami zamówień. Kontynuować?';
									|tr = 'Ürünler listesindeki satırlar artık sipariş satırlarına ilişkilendirilmeyecektir. Devam edilsin mi?'");
				Else
					QueryText = NStr("vi = 'Dòng trong danh sách Hàng hóa không còn liên kết với dòng trong đơn hàng. Tiếp tục?';
									|ru = 'Строки в списке Товары перестанут быть связанными со строками заказа. Продолжить?';
									|en = 'The Item list lines will be unlinked from the order lines. Continue?'; fa = 'The Item list lines will be unlinked from the order lines. Continue?';
									|it = 'Le righe nell''elenco Merci non saranno più associate alle righe dell''ordine. Continuare?';
									|pl = 'Wiersze na liście Wiersze pozycji nie będą więcej powiązane z wierszami zamówienia. Kontynuować?';
									|tr = 'Ürünler listesindeki satırlar artık sipariş satırlarına ilişkilendirilmeyecektir. Devam edilsin mi?'");
				EndIf;
			EndIf;
			
		Else
			
			OrderSalesOnChangeServer();
			Return;
			
		EndIf;
	EndIf;
	
	ImplementationByOrdersWhenFragmentChanges(SalesOrder, QueryText);
	
EndProcedure

&AtClient
Procedure ImplementationByOrdersWhenFragmentChanges(Val SalesOrder, Val QueryText)
	
	Var UserAnswer;
	
	UserAnswer = Undefined;
	
	ShowQueryBox(New CallbackDescription("OrderSalesOnChangeCompletion", ThisObject, New Structure("SalesOrder", SalesOrder)), QueryText, QuestionDialogMode.YesNo);
	
EndProcedure

&AtClient
Procedure OrderSalesOnChangeCompletion(QuestionResult, AdditionalParameters) Export
	
	SalesOrder = AdditionalParameters.SalesOrder;
	
	UserAnswer = QuestionResult;
	If UserAnswer = DialogReturnCode.No Then
		Object.OrderSales = Not Object.OrderSales;
		Return;
	EndIf;
	
	If ValueIsFilled(SalesOrder) Then
		Object.SalesOrder = SalesOrder;
	EndIf;
	
	ItemArray = New Array;
	ItemArray.Add("GoodsUnlinkFromOrder");
	ItemArray.Add("GoodsContextMenuUnlinkFromOrder");
	ItemArray.Add("GoodsGroupSalesOrder");
	
	TMCommonUseClientServer.SetPropertyOfFormElements(Items, ItemArray, "Visible", Object.OrderSales);
	
	WhenChangingImplementationForMultipleOrders();
	
EndProcedure

&AtClient
Procedure LoyaltyCardStartChoice(Item, ChoiceData, StandardProcessing)
	
	LoyaltyCardsClient.StartSelectingLoyaltyCard(Item, StandardProcessing, Object.Partner, Object.Date);
	
EndProcedure

&AtClient
Procedure LoyaltyCardChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	StandardProcessing = False;
	LoyaltyCardIsRead(ValueSelected);
	
EndProcedure

&AtClient
Procedure LoyaltyCardClearing(Item, StandardProcessing)
	LoyaltyCardIsRead(Undefined);
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
Procedure TextShippingToAPartnerIsProhibitedClick(Item)
	OpenForm("Catalog.Partners.Form.FormOfSegmentsOfShipmentProhibition", New Structure("Partner", Object.Partner));
EndProcedure

&AtClient
Procedure PackageDepositIsRequiredOnChange(Item)
	PackagingDepositIsRequiredWhenChangeIsMadeOnServer();
	CalculateTotals_(ThisObject);
EndProcedure

&AtClient
Procedure DateOfTransferOfTitleToGoodsOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	
	If ToUseTermsOfSales And ValueIsFilled(Object.Terms) Then
		DateOfTransferOfTitleToGoodsOnChangeServer();
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
	PaymentStepsServer.PlacePaymentStepsInTemporaryStorage(ThisForm, TagName);
	ARAPAccountingFormWork.PlacePaymentDecryptionInTemporaryStorage(ThisForm, TagName);
EndProcedure

&AtClient
Procedure LabelPaymentStagesClickCompletion(Result, AdditionalParameters) Export
	
	If Result <> Undefined Then
		
		ChangedBankingDetails = Result.OldValuesOfChangedProps;
		ReflectChangesToPaymentRules(ChangedBankingDetails);
		
		If ChangedBankingDetails.Count() > 0 Then
			
			Object.Approved                = False;
			If ChangedBankingDetails.Property("PaymentMethod") Then
				DiscountsMarkupsFillingClient.ResetDiscountsCalculatedFlag(ThisForm);
			EndIf;
			
		
		EndIf;
		
		AddSBPPaymentStatusUpdateCommand();
		
	EndIf;
	
	CalculateTotals_(ThisObject);
	
EndProcedure

&AtClient
Procedure SaleRegistrationOptionOnChange(Item)
	ChangeHeadingsForSalesLayoutOption();
EndProcedure

&AtClient
Procedure LineOfBusinessOnChange(Item)
	
	ClearMessages();
	LineOfBusinessOnChangeServer();
	
EndProcedure

&AtClient
Procedure LabelCurrenciesClick(Item, StandardProcessing)
	
	Notification = New CallbackDescription("LabelCurrenciesClickCompletion", ThisObject);
	ARAPAccountingClient.CurrencyAndExchangeRateOfDocument(ThisForm, Item, StandardProcessing, Notification);
	
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
				DiscountsMarkupsFillingClient.ResetDiscountsCalculatedFlag(ThisForm);
			EndIf;
			
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure Decorationedonage(Item, StandardProcessing)
	
	If Object.BusinessOperation =
		PredefinedValue("Enum.BusinessTransactions.TransferOfTitleToGoods") Then
		
		ShowMessageBox(, NStr("vi = 'Đối với chứng từ có giao dịch ""Chuyển giao quyền sở hữu"", không hỗ trợ gửi/nhận theo HTQLVBĐT.';
								|ru = 'Для документа с операцией ""Переход права собственности"" отправка/получение по ЭДО не предусмотрено.';
								|en = 'Documents with the ""Transfer of title to goods"" transaction do not support sending/receiving by EDI.'; fa = 'Documents with the ""Transfer of title to goods"" transaction do not support sending/receiving by EDI.';
								|it = 'Documents with the ""Transfer of title to goods"" transaction do not support sending/receiving by EDI.';
								|pl = 'Documents with the ""Transfer of title to goods"" transaction do not support sending/receiving by EDI.';
								|tr = '""Mülkiyet hakkının devri"" işlemini içeren belgeler için EBY aracılığıyla sevkiyat/alım öngörülmemiştir.'"));
		Return;
	EndIf;
	
	
EndProcedure

&AtClient
Procedure DecorationOfEPDClick(Item)
	
	
EndProcedure

&AtClient
Procedure DecorationToIssueEPDClick(Item, StandardProcessing)
	
	
EndProcedure

&AtServer
Procedure ReflectChangesToPaymentRules(ChangedBankingDetails)
	
	PaymentStepsServer.LoadPaymentStagesFromTemporaryStorage(ThisForm);
	ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisForm, ChangedBankingDetails, True);
	SetAvailabilityOfItemsByStatusServer()
	
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
		FillInDefaultContract();
		FillInDefaultEndClientContract();
		Object.CompanyBankAccount = GetOrganizationSDefaultBankAccountServer();
	EndIf;
	
	ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisForm, ChangedBankingDetails, True);
	
EndProcedure

&AtClient
Procedure LineCorrectionURLProcessing(Item, FormattedStringURL, StandardProcessing)
	
	DocumentCorrectionClient.StringFixHandlingNavigationLinks(
		ThisObject, FormattedStringURL, StandardProcessing);
	
EndProcedure

&AtClient
Procedure Attachable_OriginalStateDecorationClick()

	// StandardSubsystems.SourceDocumentsOriginalsRecording
	SourceDocumentsOriginalsRecordingClient.OpenStateSelectionMenu(ThisObject,Items.OriginalStateDecoration);
	//End StandardSubsystems.SourceDocumentsOriginalsRecording

EndProcedure

&AtClient
Procedure CourierOnChange(Item)
	
	CourierForChangesOnServer();
	
EndProcedure

&AtClient
Procedure CustomerPartnerOnChange(Item)
	
	ClientPartnerWhenChangesAreMadeOnServer();
	FillInDefaultEndClientContract();
	
EndProcedure

&AtClient
Procedure CustomerCounterpartyOnChange(Item)
	
	ClientCounterpartyWhenChangingOnServer();
	FillInDefaultEndClientContract();
	
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

&AtClient
Procedure DepartmentOnChange(Item)
	
	FillInVATTaxationATServer();
	
EndProcedure

&AtClient
Procedure CustomerContractCreating(Item, StandardProcessing)
	
	SalesClient.OpenContractCreationForm(ThisObject, Item, "Object.CustomerContract", Object.CustomerPartner,
		StandardProcessing, "WhenChangingClientSContract");
	
EndProcedure

&AtClient
Procedure CustomerContractOnChange(Item)
	
	ClientAgreesOnChangeOnServer();
	
EndProcedure

#Region Delivery

&AtClient
Procedure DeliveryIsRequiredOnChange(Item)
	
	If Object.DeliveryIsRequired Then
		
		DeliverySettings = GoodsDeliveryClientServer.DefaultDeliverySettings();
		Object.DeliveryMethod25 = DeliverySettings.DeliveryMethod;
		UpdateDeliveryPlanningView(ThisObject, True);
		
	Else
		
		Object.DeliveryToCarrier = False;
		
	EndIf;
	
	SetAvailabilityVisibilityOfDeliveryItems(ThisObject);
	
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	
EndProcedure

#EndRegion

#EndRegion

#Region FormTableItemsEventHandlersGoods

&AtClient
Procedure GoodsOnStartEdit(Item, NewRow, Copy)
	
	ProcessingOfTabularFormsClient.CacheCurLine(Items.Goods, ThisObject);
	CurrentRow = Items.Goods.CurrentData;
	
	If NewRow And Not Copy Then
		CurrentRow.Department = Object.Department;
		
		If SalesViaCommissionAgent And Not ValueIsFilled(CurrentRow.PriceKind) Then
			CurrentRow.PriceKind = PriceTypeUnderContract;
		EndIf;
		
	EndIf;
	
	SalesClient.ProductItemLineAtBeginningOfEditing(ThisForm, "Goods", CurrentRow, NewRow, Copy);
	
	If Copy Then
		
		CurrentRow.DeliveryLineCode = 0;
		CurrentRow.DiscountMarkupAmount = 0;
		CurrentRow.PercentRateOfAutomaticDiscountMarkup = 0;
		CurrentRow.AmountOfBonusPointsToDeduction = 0;
		CurrentRow.AmountOfBonusPointsToDeductionInCurrency = 0;
		
		If Object.OrderSales Then 
			
			CurrentRow.RowCode = 0;
			CurrentRow.SalesOrder = Undefined;
			
			StructureOfActions = New Structure;
			OrdersClientServer.AddActionFillInDiscrepancyOrderAttribute(StructureOfActions, True);
			BatchProcessingOfTablePartClient.ProcessTSString(
				CurrentRow,
				StructureOfActions,
				CachedValues);
			
		EndIf;
		
	EndIf;
	
	DiscountsMarkupsFillingClient.ResetDiscountsCalculatedFlag(ThisForm);
	ProductsClient.UpdateCachedValuesToAccountForSeries(Item, CachedValues, SeriesSpecificationParameters, Copy);
	
EndProcedure

&AtClient
Procedure GoodsBeforeDeleteRow(Item, Cancel)
	
	ProcessingOfTabularFormsClient.CacheCurLine(Items.Goods, ThisObject);
	ProductsClient.UpdateCachedValuesToAccountForSeries(Item, CachedValues, SeriesSpecificationParameters);
	
	SetsClient.BeforeDeletingRowOfTablePart(ThisForm, "Goods", Cancel);
	
EndProcedure

&AtClient
Procedure GoodsAfterDeleteRow(Item)
	
	SeriesStatusesNeedToBeUpdated = ProductsClient.SeriesStatusesNeedToBeUpdated(
		Item, CachedValues, SeriesSpecificationParameters, True);
	
	GoodsAfterDeleteRowServer(SeriesStatusesNeedToBeUpdated, CachedValues);
	
	If SeriesStatusesNeedToBeUpdated Then
		ProductsClient.UpdateCachedValuesToAccountForSeries(Item, CachedValues, SeriesSpecificationParameters);
	EndIf;

	SetWhetherWarehouseIsFull();

	CalculateTotals_(ThisObject);
	DiscountsMarkupsFillingClient.ResetDiscountsCalculatedFlag(ThisForm);
	
EndProcedure

&AtClient
Procedure GoodsBeforeRowChange(Item, Cancel)
	FillPropertyValues(PreviousRowDetails, Items.Goods.CurrentData);
	ControlOfSalesOfTobaccoProductsOnlyByMRCLocalization(Item, Cancel);
EndProcedure

&AtClient
Procedure GoodsOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData; 
	
	If CurrentRow = Undefined Then
		Return;
	EndIf;
	
	StructureOfActions = New Structure;
	OrdersClientServer.AddActionFillInDiscrepancyOrderAttribute(StructureOfActions, Object.OrderSales);
	BatchProcessingOfTablePartClient.ProcessTSString(
		CurrentRow,
		StructureOfActions,
		Undefined);
	
	UpdateDependentDetailsOfOrderForm_(ThisObject, DiscrepancyOrderText);
	
EndProcedure

&AtClient
Procedure GoodsOnEditEnd(Item, NewRow, CancelEdit)
	
	If NewRow Then
		CalculateTotals_(ThisObject);
	EndIf;
	
	CurrentData = Items.Goods.CurrentData;
	
	If ProductsClient.SeriesStatusesNeedToBeUpdated(
		Item,CachedValues,SeriesSpecificationParameters) Then
		
		IDCurrentRow = CurrentData.GetID();
		
		FillInStatusesOfSpecifyingSeriesWhenEditingLineTS(IDCurrentRow, CachedValues);
		ProductsClient.UpdateCachedValuesToAccountForSeries(Item, CachedValues, SeriesSpecificationParameters);
		
	EndIf;
	
	ReusablePackageClient.UpdateFillingStateOfMultiTurnContainer(Object.ReusablePackageFillingStatus);
	
	UpdateDependentDetailsOfOrderForm_(ThisObject, DiscrepancyOrderText);
	
	If Not CancelEdit Then
		LineCache = ?(NewRow, Undefined, ProcessingOfTabularFormsClientServer.LineCache(Items.Goods, ThisObject));
		WarehousesClient.UpdateWarehouseTable(WarehouseTable, CurrentData, LineCache, WarehouseGroup_, False);
		TotalWarehouses_ = WarehouseTable.Count();
		WarehousesClientServer.UpdateWarehouseGroupImage(SeveralWarehousesText, Items.PictureMultipleWarehouses, TotalWarehouses_);
	EndIf;
	
	AdditionalParameters = New Structure;
	FormEventsClient.WhenChangingElement(ThisObject, Items.Goods, AdditionalParameters);
	If AdditionalParameters.Property("ServerCallRequired__") Then
		AttachIdleHandler("GoodsAtEndOfEditingForServerCall", 0.5, True);
	EndIf;

EndProcedure

&AtClient
Procedure GoodsAtEndOfEditingForServerCall()
	
	GoodsAtEndOfEditingOnServer();
	
EndProcedure

&AtServer
Procedure GoodsAtEndOfEditingOnServer()
	
	FormEvents.WhenChangingElement(ThisObject, "Goods");
	
EndProcedure

&AtClient
Procedure GoodsBeforeAddRow(Item, Cancel, Copy, Parent, Var_Group)
	
	If Object.OrderSales And Not SalesInExcessOfOrder Then
		Cancel = True;
		PickUpFromOrder()
	EndIf;
	
	If Copy Then
		SetsClient.BeforeDeletingRowOfTablePart(ThisForm, "Goods", Cancel, True);
	EndIf;
	
EndProcedure

&AtClient
Procedure GoodsSelection(Item, RowSelected, Field, StandardProcessing)
	
	If Field = Items.GoodsPercentRateOfAutomaticDiscountMarkup
		Or Field = Items.GoodsDiscountMarkupAmount Then
		
		StandardProcessing = False;
		CurrentData = Items.Goods.CurrentData;
		
		If Not Object.OrderSales Or SalesInExcessOfOrder And CurrentData.RowCode = 0 Then
			
			If Not Object.DiscountsAreCalculated Then
				ShowQueryBox(New CallbackDescription("GoodsSelectionCompletion", ThisObject, 
					New Structure("RowSelected, Field, CurrentData", RowSelected, Field, CurrentData)), 
					NStr("vi = 'Chưa tính chiết khấu (phụ thu), tính chiết khấu (phụ thu)?';
						|ru = 'Скидки (наценки) не рассчитаны, рассчитать?';
						|en = 'Discounts (markups) are not calculated, calculate?'; fa = 'Discounts (markups) are not calculated, calculate?';
						|it = 'Gli sconti (sovrapprezzi) non sono stati calcolati, calcolare?';
						|pl = 'Rabaty (marże) nie są obliczane, obliczyć?';
						|tr = 'İndirimler uygulanmadı. Uygulamak istiyor musunuz?'"), QuestionDialogMode.YesNo);
                Return;
			EndIf;
			
			ProductsSelectionFragment(CurrentData);
			
		EndIf;
				
	ElsIf Field = Items.GoodsSalesOrder Then
		
		If ValueIsFilled(Items.Goods.CurrentData.SalesOrder) Then
			ShowValue(Undefined, Items.Goods.CurrentData.SalesOrder);
		ElsIf ValueIsFilled(Object.SalesOrder) Then
			ShowValue(Undefined, Object.SalesOrder);
		EndIf;
		
	ElsIf Field = Items.GoodsPrice Then
		
		CurrentData = Items.Goods.CurrentData;
		If ReadPriceTypeRight Then
			If ValueIsFilled(CurrentData.PriceKind) And Not Object.Approved Then
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
		
	EndIf;
	
EndProcedure

&AtClient
Procedure GoodsSelectionCompletion(QuestionResult, AdditionalParameters) Export
    
    RowSelected = AdditionalParameters.RowSelected;
    Field = AdditionalParameters.Field;
    CurrentData = AdditionalParameters.CurrentData;
    
    Result = QuestionResult;
    If Result = DialogReturnCode.No Then
        Return;
    Else
        
        ParametersStructure1 = New Structure;
        ParametersStructure1.Insert("ApplyToObject",                True);
        ParametersStructure1.Insert("OnlyPreliminaryCalculation",      False);
        ParametersStructure1.Insert("RestoreManagedDiscounts", True);
        ParametersStructure1.Insert("ManagedDiscounts", ManagedDiscounts);
        ParametersStructure1.Insert("SalesInExcessOfOrder", SalesInExcessOfOrder And Object.OrderSales);
        
        TheStructureOfTheMessages = CalculateDiscountsMarginsOnServer(ParametersStructure1);
        If TheStructureOfTheMessages.Messages.Count() > 0 And TheStructureOfTheMessages.AutomaticallyOpen Then
            OpenForm("CommonForm.MessagesOfDiscountsMarkups", TheStructureOfTheMessages, ThisForm, UUID);
        EndIf;
        
    EndIf;
    
    ProductsSelectionFragment(CurrentData);

EndProcedure

&AtClient
Procedure ProductsSelectionFragment(CurrentData)
    
    If Not ValueIsFilled(AddressOfAppliedDiscountsInTheTemporaryStorage) Then
        CalculateDiscountsWithoutApplyingToObject();
    EndIf;
    
    CurrentData = Items.Goods.CurrentData;
    DiscountsMarkupsFillingClient.OpenAppliedDiscountsForm(CurrentData, Object, ThisForm);

EndProcedure


// The constructor function of additional parameters processing is complete
// 
// Returns:
// 	Structure - advanced setting:
// * CurrentRow - FormDataCollectionItem, FormDataStructure, FormDataTreeItem - 
// * CallbackDescription - CallbackDescription -
// * LineDetachedFromOrder - Boolean - 
&AtClient
Function AdditionalCompletionProcessingParameters() 
	
	Result = New Structure;
	Result.Insert("CurrentRow", Undefined);
	Result.Insert("CallbackDescription", Undefined);
	Result.Insert("LineDetachedFromOrder", False);
	Return Result;
	
EndFunction

&AtClient
Procedure GoodsWarehouseOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;
	
	AdditionalParameters = AdditionalCompletionProcessingParameters();
	AdditionalParameters. CurrentRow = CurrentRow;
	QuestionUserWhenChangingRowDetails(
		New CallbackDescription("GoodsWarehouseWhenChangingQuestionToUserCompletion", ThisObject, AdditionalParameters),
		CurrentRow);
	
EndProcedure

// Parameters:
// 	Result - Boolean - 
// 	AdditionalParameters - See AdditionalCompletionProcessingParameters
&AtClient
Procedure GoodsWarehouseWhenChangingQuestionToUserCompletion(Result, AdditionalParameters) Export
	
	If SalesInExcessOfOrder And Not Result Then
		
		WhenChangingWarehouseInTablePartServer();
		Return;
		
	EndIf;
	
	CurrentRow = AdditionalParameters.CurrentRow;
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("CheckSeriesCalculateStatus", New Structure("Warehouse, SeriesSpecificationParameters", CurrentRow.Warehouse, SeriesSpecificationParameters));
	OrdersClientServer.AddActionFillInDiscrepancyOrderAttribute(StructureOfActions, Object.OrderSales);
	If AdditionalParameters.LineDetachedFromOrder	Then
		LinesOfBusinessClientServer.StructureOfInsertActionsWhenAddingRow(ThisObject, StructureOfActions);
	EndIf;
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
	ThisIsTransferOfOwnership =
		(Object.BusinessOperation =
			PredefinedValue("Enum.BusinessTransactions.TransferOfTitleToGoods"));
	
	UpdateDependentDetailsOfOrderForm_(ThisObject, DiscrepancyOrderText);
	
EndProcedure

&AtClient
Procedure GoodsProductsOnChange(Item)
	
	ClearMessages();
	
	CurrentRow = Items.Goods.CurrentData;
	
	AdditionalParameters = AdditionalCompletionProcessingParameters();
	AdditionalParameters. CurrentRow = CurrentRow;
	QuestionUserWhenChangingRowDetails(
		New CallbackDescription("GoodsNomenclatureWhenChangingQuestionToUserCompletion", ThisObject, AdditionalParameters),
		CurrentRow);
	
EndProcedure

&AtClient
Procedure GoodsPartnerProductsOnChange(Item)
	
	ClearMessages();
	
	CurrentRow = Items.Goods.CurrentData;
	
	AdditionalParameters = AdditionalCompletionProcessingParameters();
	AdditionalParameters. CurrentRow = CurrentRow;
	QuestionUserWhenChangingRowDetails(
		New CallbackDescription("ProductsPartnerSNomenclatureWhenChangingQuestionToUserCompletion", ThisObject, AdditionalParameters),
		CurrentRow);
	
EndProcedure

// Parameters:
// 	Result - Boolean - 
// 	AdditionalParameters - See AdditionalCompletionProcessingParameters
&AtClient
Procedure ProductsPartnerSNomenclatureWhenChangingQuestionToUserCompletion(Result, AdditionalParameters) Export
	
	If SalesInExcessOfOrder And Not Result Then
		Return;
	EndIf;
	
	CurrentRow = AdditionalParameters.CurrentRow;
	
	ParametersForFillingInVATAmountLocalManSManSManSManSManSManSManSManS = BatchProcessingOfTablePartClientServer.ParametersForFillingInVATAmountLocalManSManSManSManSManSManSManSManS(
		Object.Currency,
		LocalAccountingCurrency,
		ManagementAccountingCurrency);
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	
	ParametersONChangingTypeOfItem = New Structure;
	ParametersONChangingTypeOfItem.Insert("ThereAreWorks", True);
	ParametersONChangingTypeOfItem.Insert("IsCanceled", False);
	ParametersONChangingTypeOfItem.Insert("ThisIsTransferOfOwnership",
		Object.BusinessOperation =
			PredefinedValue("Enum.BusinessTransactions.TransferOfTitleToGoods"));
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("CheckCharacteristicsByOwner", CurrentRow.Characteristic);
	StructureOfActions.Insert("CheckFillPackageByOwner", CurrentRow.Package);
	StructureOfActions.Insert("RecalculateNumberOfUnits");
	StructureOfActions.Insert("FillInTheItemByThePartnerSItem");
	StructureOfActions.Insert("CheckFillWarehouse", BatchProcessingOfTablePartClientServer.GetWarehouseFillStructureInTSLine(Object, WarehouseGroup_));
	
	If (ToUseTermsOfSales And ValueIsFilled(Object.Terms)) 
		Or (Not ToUseTermsOfSales And UsePriceManagementSystem25) Then
		StructureOfActions.Insert("FillIn_TermsOfSales", BatchProcessingOfTablePartClientServer.GetStructureForFillingInSalesConditionsInTSLine(Object));
	Else
		StructureOfActions.Insert("FillInSalePrice", BatchProcessingOfTablePartClientServer.ParametersForFillingInPriceInTSLine(Object));
	EndIf;
	StructureOfActions.Insert("FillInVATRate", BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRate(Object));
	StructureOfActions.Insert("FillInVATRateByPriceType", BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRateByPriceType(Object));
	StructureOfActions.Insert("FillInHSCode", Object.VATTaxation);
	StructureOfActions.Insert("FillInVATRateForReturnableContainers", Object.ToReturnReusablePackage);
	StructureOfActions.Insert("FillInNoReturnContainerAttribute", Object.ToReturnReusablePackage);
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmount");
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountManualDiscount", New Structure("Clear", True));
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountAutomaticDiscount", New Structure("Clear", True));
	StructureOfActions.Insert("ClearAmountOfSettlements");
	StructureOfActions.Insert("SetVATAmountLocalMans", ParametersForFillingInVATAmountLocalManSManSManSManSManSManSManSManS);
	StructureOfActions.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
	StructureOfActions.Insert("FillInDuplicateDependentDetails", DependentDetails());
	StructureOfActions.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));
	StructureOfActions.Insert("CheckSeriesCalculateStatus", New Structure("Warehouse, SeriesSpecificationParameters", CurrentRow.Warehouse, SeriesSpecificationParameters));
	StructureOfActions.Insert("WhenChangingProductType", ParametersONChangingTypeOfItem);
	LinesOfBusinessClientServer.StructureOfInsertActionsWhenAddingRow(ThisForm, StructureOfActions);
	
	StructureOfActions.Insert("FillInSubdivisionInTSLine", New Structure("Department", Object.Department));
	OrdersClientServer.AddActionFillInDiscrepancyOrderAttribute(StructureOfActions, Object.OrderSales);
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
	CalculateTotals_(ThisObject);
	DiscountsMarkupsFillingClient.ResetDiscountsCalculatedFlag(ThisForm);
	SetWhetherWarehouseIsFull();
	
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

// Parameters:
// 	Result - Boolean - 
// 	AdditionalParameters - See AdditionalCompletionProcessingParameters
&AtClient
Procedure GoodsNomenclatureWhenChangingQuestionToUserCompletion(Result, AdditionalParameters) Export
	
	If SalesInExcessOfOrder And Not Result Then
		Return;
	EndIf;
	
	CurrentRow = AdditionalParameters.CurrentRow;
	
	StructureOfFillingBonusPoints = Undefined;
	VerificationOfPaymentWithBonusPoints(CurrentRow, StructureOfFillingBonusPoints);

	ParametersForFillingInVATAmountLocalManSManSManSManSManSManSManSManS = BatchProcessingOfTablePartClientServer.ParametersForFillingInVATAmountLocalManSManSManSManSManSManSManSManS(
		Object.Currency,
		LocalAccountingCurrency,
		ManagementAccountingCurrency);
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	
	ParametersONChangingTypeOfItem = New Structure;
	ParametersONChangingTypeOfItem.Insert("ThereAreWorks", True);
	ParametersONChangingTypeOfItem.Insert("IsCanceled", False);
	ParametersONChangingTypeOfItem.Insert("ThisIsTransferOfOwnership",
		Object.BusinessOperation =
			PredefinedValue("Enum.BusinessTransactions.TransferOfTitleToGoods"));
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("CheckCharacteristicsByOwner", CurrentRow.Characteristic);
	StructureOfActions.Insert("CheckFillPackageByOwner", CurrentRow.Package);
	StructureOfActions.Insert("RecalculateNumberOfUnits");
	StructureOfActions.Insert("CheckFillWarehouse", BatchProcessingOfTablePartClientServer.GetWarehouseFillStructureInTSLine(Object, WarehouseGroup_));
	
	If Not SalesViaCommissionAgent
		And ((ToUseTermsOfSales And ValueIsFilled(Object.Terms)) 
			Or (Not ToUseTermsOfSales And UsePriceManagementSystem25)) Then
		StructureOfActions.Insert("FillIn_TermsOfSales", BatchProcessingOfTablePartClientServer.GetStructureForFillingInSalesConditionsInTSLine(Object));
	Else
		StructureOfActions.Insert("FillInSalePrice", BatchProcessingOfTablePartClientServer.ParametersForFillingInPriceInTSLine(Object));
	EndIf;
	
	StructureOfActions.Insert("FillInVATRate", BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRate(Object));
	StructureOfActions.Insert("FillInVATRateByPriceType", BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRateByPriceType(Object));
	StructureOfActions.Insert("FillInHSCode", Object.VATTaxation);
	StructureOfActions.Insert("FillInVATRateForReturnableContainers", Object.ToReturnReusablePackage);
	StructureOfActions.Insert("FillInNoReturnContainerAttribute", Object.ToReturnReusablePackage);
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmount");
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountManualDiscount", New Structure("Clear", True));
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountAutomaticDiscount", New Structure("Clear", True));
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountDiscountWithBonusPoints", StructureOfFillingBonusPoints);
	StructureOfActions.Insert("ClearAmountOfSettlements");
	StructureOfActions.Insert("SetVATAmountLocalMans", ParametersForFillingInVATAmountLocalManSManSManSManSManSManSManSManS);
	StructureOfActions.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
	StructureOfActions.Insert("FillInDuplicateDependentDetails", DependentDetails());
	StructureOfActions.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));
	StructureOfActions.Insert("CheckSeriesCalculateStatus", New Structure("Warehouse, SeriesSpecificationParameters", CurrentRow.Warehouse, SeriesSpecificationParameters));
	StructureOfActions.Insert("WhenChangingProductType", ParametersONChangingTypeOfItem);
	LinesOfBusinessClientServer.StructureOfInsertActionsWhenAddingRow(ThisForm, StructureOfActions);
	
	BatchProcessingOfTablePartClientServerLocalization.CompleteActionStructureWhenChangingElement(ThisObject, "Products", StructureOfActions);
	AccountingForTraceableGoodsClientServerLocalization.CompleteDescriptionOfSettingsForFillingInServiceDetailsOfTablePart(StructureOfActions);
	
	StructureOfActions.Insert("ProductsOnChangeOverridable", New Structure("FormName, TabularSectionName",
		ThisForm.FormName, "Goods"));
		
	StructureOfActions.Insert("FillInSubdivisionInTSLine", New Structure("Department", Object.Department));
	OrdersClientServer.AddActionFillInDiscrepancyOrderAttribute(StructureOfActions, Object.OrderSales);
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
	CalculateTotals_(ThisObject);
	DiscountsMarkupsFillingClient.ResetDiscountsCalculatedFlag(ThisForm);
	SetWhetherWarehouseIsFull();
	
EndProcedure

&AtClient
Procedure GoodsCharacteristicOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;
	
	AdditionalParameters = AdditionalCompletionProcessingParameters();
	AdditionalParameters. CurrentRow = CurrentRow;
	QuestionUserWhenChangingRowDetails(
		New CallbackDescription("GoodsCharacteristicWhenChangingQuestionToUserCompletion", ThisObject, AdditionalParameters),
		CurrentRow);
	
EndProcedure

// Parameters:
// 	Result - Boolean - 
// 	AdditionalParameters - See AdditionalCompletionProcessingParameters
&AtClient
Procedure GoodsCharacteristicWhenChangingQuestionToUserCompletion(Result, AdditionalParameters) Export
	
	If SalesInExcessOfOrder And Not Result Then
		Return;
	EndIf;
	
	ClearMessages();
	
	CurrentRow = AdditionalParameters.CurrentRow;
	
	StructureOfFillingBonusPoints = Undefined;
	VerificationOfPaymentWithBonusPoints(CurrentRow, StructureOfFillingBonusPoints);

	ParametersForFillingInVATAmountLocalManSManSManSManSManSManSManSManS = BatchProcessingOfTablePartClientServer.ParametersForFillingInVATAmountLocalManSManSManSManSManSManSManSManS(
		Object.Currency,
		LocalAccountingCurrency,
		ManagementAccountingCurrency);
	
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
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountDiscountWithBonusPoints", StructureOfFillingBonusPoints);
	StructureOfActions.Insert("ClearAmountOfSettlements");
	StructureOfActions.Insert("SetVATAmountLocalMans", ParametersForFillingInVATAmountLocalManSManSManSManSManSManSManSManS);
	StructureOfActions.Insert("FillInDuplicateDependentDetails", DependentDetails());
	
	If AdditionalParameters.LineDetachedFromOrder	Then
		LinesOfBusinessClientServer.StructureOfInsertActionsWhenAddingRow(ThisObject, StructureOfActions);
	EndIf;
	
	StructureOfActions.Insert("CharacteristicOnChangeOverridable", New Structure("FormName, TabularSectionName",
		ThisForm.FormName, "Goods"));
	OrdersClientServer.AddActionFillInDiscrepancyOrderAttribute(StructureOfActions, Object.OrderSales);
		
	BatchProcessingOfTablePartClientServerLocalization.CompleteActionStructureWhenChangingElement(ThisObject, "Characteristic", StructureOfActions);
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
	CalculateTotals_(ThisObject);
	DiscountsMarkupsFillingClient.ResetDiscountsCalculatedFlag(ThisForm);
	
EndProcedure

&AtClient
Procedure GoodsWithAssignmentOnChange(Item)

	LinesOfBusinessClient.GoodsWithAssignmentOnChange(ThisObject, Items.Goods.CurrentData);	

EndProcedure

&AtClient
Procedure GoodsPackageOnChange(Item)
	
	ClearMessages();
	
	CurrentRow = Items.Goods.CurrentData;
	
	StructureOfFillingBonusPoints = Undefined;
	VerificationOfPaymentWithBonusPoints(CurrentRow, StructureOfFillingBonusPoints);

	ParametersForFillingInVATAmountLocalManSManSManSManSManSManSManSManS = BatchProcessingOfTablePartClientServer.ParametersForFillingInVATAmountLocalManSManSManSManSManSManSManSManS(
		Object.Currency,
		LocalAccountingCurrency,
		ManagementAccountingCurrency);
	
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
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountManualDiscount", New Structure("Clear", False));
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountAutomaticDiscount", New Structure("Clear", True));
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountDiscountWithBonusPoints", StructureOfFillingBonusPoints);
	StructureOfActions.Insert("ClearAmountOfSettlements");
	StructureOfActions.Insert("SetVATAmountLocalMans", ParametersForFillingInVATAmountLocalManSManSManSManSManSManSManSManS);
	StructureOfActions.Insert("FillInDuplicateDependentDetails", DependentDetails());
		
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
	CalculateTotals_(ThisObject);
	DiscountsMarkupsFillingClient.ResetDiscountsCalculatedFlag(ThisForm);
	
EndProcedure

&AtClient
Procedure GoodsNumberOfPackagesOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;
	
	StructureOfFillingBonusPoints = Undefined;
	VerificationOfPaymentWithBonusPoints(CurrentRow, StructureOfFillingBonusPoints);
	
	StructureOfActions = New Structure;
	AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions, Object, StructureOfFillingBonusPoints);
	
	ParametersForFillingInVATAmountLocalManSManSManSManSManSManSManSManS = BatchProcessingOfTablePartClientServer.ParametersForFillingInVATAmountLocalManSManSManSManSManSManSManSManS(
		Object.Currency,
		LocalAccountingCurrency,
		ManagementAccountingCurrency);
	
	StructureOfActions.Insert("SetVATAmountLocalMans", ParametersForFillingInVATAmountLocalManSManSManSManSManSManSManSManS);
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	CalculateTotals_(ThisObject);
	DiscountsMarkupsFillingClient.ResetDiscountsCalculatedFlag(ThisForm);
	
EndProcedure

&AtClient
Procedure GoodsPriceKindOnChange(Item)
	
	ClearMessages();
	
	CurrentRow = Items.Goods.CurrentData;
	
	StructureOfFillingBonusPoints = Undefined;
	VerificationOfPaymentWithBonusPoints(CurrentRow, StructureOfFillingBonusPoints);

	ParametersForFillingInVATAmountLocalManSManSManSManSManSManSManSManS = BatchProcessingOfTablePartClientServer.ParametersForFillingInVATAmountLocalManSManSManSManSManSManSManSManS(
		Object.Currency,
		LocalAccountingCurrency,
		ManagementAccountingCurrency);
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInVATRateByPriceType", BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRateByPriceType(Object));
	StructureOfActions.Insert("FillInSalePrice", BatchProcessingOfTablePartClientServer.ParametersForFillingInPriceInTSLine(Object));
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmount");
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountManualDiscount", New Structure("Clear", False));
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountAutomaticDiscount", New Structure("Clear", True));
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountDiscountWithBonusPoints", StructureOfFillingBonusPoints);
	StructureOfActions.Insert("ClearAmountOfSettlements");
	StructureOfActions.Insert("SetVATAmountLocalMans", ParametersForFillingInVATAmountLocalManSManSManSManSManSManSManSManS);
	StructureOfActions.Insert("FillInDuplicateDependentDetails", DependentDetails());
		
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
	CalculateTotals_(ThisObject);
	DiscountsMarkupsFillingClient.ResetDiscountsCalculatedFlag(ThisForm);
	
EndProcedure

&AtClient
Procedure GoodsPriceOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;
	
	StructureOfFillingBonusPoints = Undefined;
	VerificationOfPaymentWithBonusPoints(CurrentRow, StructureOfFillingBonusPoints);

	ParametersForFillingInVATAmountLocalManSManSManSManSManSManSManSManS = BatchProcessingOfTablePartClientServer.ParametersForFillingInVATAmountLocalManSManSManSManSManSManSManSManS(
		Object.Currency,
		LocalAccountingCurrency,
		ManagementAccountingCurrency);
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmount");
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountManualDiscount", New Structure("Clear", False));
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountAutomaticDiscount", New Structure("Clear", True));
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountDiscountWithBonusPoints", StructureOfFillingBonusPoints);
	StructureOfActions.Insert("FillInDuplicateDependentDetails", DependentDetails());
	StructureOfActions.Insert("ClearAmountOfSettlements");
	StructureOfActions.Insert("SetVATAmountLocalMans", ParametersForFillingInVATAmountLocalManSManSManSManSManSManSManSManS);
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
	CalculateTotals_(ThisObject);
	DiscountsMarkupsFillingClient.ResetDiscountsCalculatedFlag(ThisForm);
	
EndProcedure

&AtClient
Procedure GoodsVATRateOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;
	
	StructureOfFillingBonusPoints = Undefined;
	VerificationOfPaymentWithBonusPoints(CurrentRow, StructureOfFillingBonusPoints);

	ParametersForFillingInVATAmountLocalManSManSManSManSManSManSManSManS = BatchProcessingOfTablePartClientServer.ParametersForFillingInVATAmountLocalManSManSManSManSManSManSManSManS(
		Object.Currency,
		LocalAccountingCurrency,
		ManagementAccountingCurrency);
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmount");
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountManualDiscount", New Structure("Clear", False));
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountAutomaticDiscount", New Structure("Clear", True));
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountDiscountWithBonusPoints", StructureOfFillingBonusPoints);
	StructureOfActions.Insert("ClearAmountOfSettlements");
	StructureOfActions.Insert("SetVATAmountLocalMans", ParametersForFillingInVATAmountLocalManSManSManSManSManSManSManSManS);
	StructureOfActions.Insert("FillInDuplicateDependentDetails", DependentDetails());
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
	CalculateTotals_(ThisObject);
	DiscountsMarkupsFillingClient.ResetDiscountsCalculatedFlag(ThisForm);
	
EndProcedure

&AtClient
Procedure GoodsPercentRateOfManualDiscountOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;
	
	StructureOfFillingBonusPoints = Undefined;
	VerificationOfPaymentWithBonusPoints(CurrentRow, StructureOfFillingBonusPoints);

	ParametersForFillingInVATAmountLocalManSManSManSManSManSManSManSManS = BatchProcessingOfTablePartClientServer.ParametersForFillingInVATAmountLocalManSManSManSManSManSManSManSManS(
		Object.Currency,
		LocalAccountingCurrency,
		ManagementAccountingCurrency);
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateAmountOfManualDiscount");
	StructureOfActions.Insert("RecalculateAmount");
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountManualDiscount", New Structure("Clear", False));
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountAutomaticDiscount", New Structure("Clear", False));
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountDiscountWithBonusPoints", StructureOfFillingBonusPoints);
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("ClearAmountOfSettlements");
	StructureOfActions.Insert("SetVATAmountLocalMans", ParametersForFillingInVATAmountLocalManSManSManSManSManSManSManSManS);
	StructureOfActions.Insert("FillInDuplicateDependentDetails", DependentDetails());
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	CalculateTotals_(ThisObject);
	
EndProcedure

&AtClient
Procedure GoodsManualDiscountOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;
	
	ParametersForFillingInVATAmountLocalManSManSManSManSManSManSManSManS = BatchProcessingOfTablePartClientServer.ParametersForFillingInVATAmountLocalManSManSManSManSManSManSManSManS(
		Object.Currency,
		LocalAccountingCurrency,
		ManagementAccountingCurrency);
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculatePercentageOfManualDiscount");
	StructureOfActions.Insert("RecalculateAmount");
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountManualDiscount", New Structure("Clear, RecalculateAmountOfManualDiscount_", False, False));
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountAutomaticDiscount", New Structure("Clear", False));
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountDiscountWithBonusPoints");
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("ClearAmountOfSettlements");
	StructureOfActions.Insert("SetVATAmountLocalMans", ParametersForFillingInVATAmountLocalManSManSManSManSManSManSManSManS);
	StructureOfActions.Insert("FillInDuplicateDependentDetails", DependentDetails());
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	CalculateTotals_(ThisObject);
	
EndProcedure

&AtClient
Procedure GoodsSumOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;
	
	DiscountsAreNotUsed = 
		(Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.TransferToCommissionAgent")
		Or Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.SalesViaCommissionAgent")
		Or Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.SalesViaCommissionAgentGoodsInTransit"));
	
	StructureOfPriceConversion  = BatchProcessingOfTablePartClientServer.GetStructureForRecalculatingDiscountPriceInWHSales(Object,
		DiscountsAreNotUsed);
	
	ParametersForFillingInVATAmountLocalManSManSManSManSManSManSManSManS = BatchProcessingOfTablePartClientServer.ParametersForFillingInVATAmountLocalManSManSManSManSManSManSManSManS(
		Object.Currency,
		LocalAccountingCurrency,
		ManagementAccountingCurrency);
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculatePriceDiscountByAmountInSales", StructureOfPriceConversion);
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("ClearAmountOfSettlements");
	StructureOfActions.Insert("SetVATAmountLocalMans", ParametersForFillingInVATAmountLocalManSManSManSManSManSManSManSManS);
	StructureOfActions.Insert("FillInDuplicateDependentDetails", DependentDetails());
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
	CalculateTotals_(ThisObject);
	DiscountsMarkupsFillingClient.ResetDiscountsCalculatedFlag(ThisForm);
	
EndProcedure

&AtClient
Procedure GoodsVATAmountOnChange(Item)
	CurrentRow = Items.Goods.CurrentData;
	
	ParametersForFillingInVATAmountLocalManSManSManSManSManSManSManSManS = BatchProcessingOfTablePartClientServer.ParametersForFillingInVATAmountLocalManSManSManSManSManSManSManSManS(
		Object.Currency,
		LocalAccountingCurrency,
		ManagementAccountingCurrency);
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("ClearAmountOfSettlements");
	StructureOfActions.Insert("SetVATAmountLocalMans", ParametersForFillingInVATAmountLocalManSManSManSManSManSManSManSManS);
	StructureOfActions.Insert("FillInDuplicateDependentDetails", DependentDetails());
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
	CalculateTotals_(ThisObject);
EndProcedure

&AtClient
Procedure GoodsSalesOrderStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	CurrentData = Items.Goods.CurrentData;
	
	If CurrentData <> Undefined Then
	
		FilterParameters = New Structure();
		FilterParameters.Insert("Currency",                    Object.Currency);
		FilterParameters.Insert("Counterparty",                Object.Counterparty);
		FilterParameters.Insert("Contract",                   Object.Contract);
		FilterParameters.Insert("VATTaxation",        Object.VATTaxation);
		FilterParameters.Insert("Organization",               Object.Organization);
		FilterParameters.Insert("Partner",                   Object.Partner);
		FilterParameters.Insert("Terms",                Object.Terms);
		FilterParameters.Insert("BusinessOperation",     Object.BusinessOperation);
		FilterParameters.Insert("PriceIncludesVAT",           Object.PriceIncludesVAT);
		FilterParameters.Insert("ARAPObjectSettings",           Object.ARAPObjectSettings);
		FilterParameters.Insert("ToReturnReusablePackage", Object.ToReturnReusablePackage);
		FilterParameters.Insert("PackageDepositIsRequired",      Object.PackageDepositIsRequired);
		FilterParameters.Insert("SalesOpportunity",                    Object.SalesOpportunity);
		FilterParameters.Insert("LineOfBusiness",   Object.LineOfBusiness);
		FilterParameters.Insert("UseAdvancedFeaturesOfSalesOrder", UseAdvancedFeaturesOfSalesOrder);
		
		SalesOrder = Undefined;
		
		OpenForm(
			"Document.CustomerInvoice.Form.ReferenceChoiceForm",
			New Structure("Filter,Warehouse,Recorder", FilterParameters, Object.Warehouse, Object.Ref),,,,, New CallbackDescription("GoodsSalesOrderStartChoiceCompletion", ThisObject), FormWindowOpeningMode.LockOwnerWindow);
        Return;
		
	EndIf;
	
	ProductsCustomerOrderStartSelectionFragment();
EndProcedure

&AtClient
Procedure GoodsSalesOrderStartChoiceCompletion(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	ThisIsShipmentToCustomer = TypeOf(Result.SalesOrder) = Type("DocumentRef.GoodsShipmentToCustomer");
	ThisIsPrimaryDocument = TypeOf(Result.SalesOrder) = Type("DocumentRef.SourceDocument");
	
	If Result.ARAPObjectSettings <> Object.ARAPObjectSettings
		And Not ThisIsShipmentToCustomer
		And Not ThisIsPrimaryDocument Then
		
		ThereAreSpecifiedOrders = False;
		
		For Each RowOfProduct In Object.Goods Do
			 
			If ValueIsFilled(RowOfProduct.SalesOrder)
				And RowOfProduct.GetID() <> Items.Goods.CurrentData.GetID() Then
				ThereAreSpecifiedOrders = True;
			EndIf;
			
		EndDo;
		
		If ThereAreSpecifiedOrders Then
			
			ClearMessages();
			
			If Object.BusinessOperation =
				PredefinedValue("Enum.BusinessTransactions.TransferOfTitleToGoods") Then
				MessageText = NStr("vi = 'Trong chứng từ đã chọn, trình tự hạch toán %1 khác với trình tự hạch toán của chứng từ %2.';
									|ru = 'У выбранного распоряжения порядок расчетов %1 отличается от порядка расчетов документа %2.';
									|en = 'The ""%1"" payment terms of the selected reference differ from the ""%2"" payment terms of the document.'; fa = 'The ""%1"" payment terms of the selected reference differ from the ""%2"" payment terms of the document.';
									|it = 'The ""%1"" payment terms of the selected reference differ from the ""%2"" payment terms of the document.';
									|pl = 'The ""%1"" payment terms of the selected reference differ from the ""%2"" payment terms of the document.';
									|tr = 'Seçilen sipariş için %1 alacak/borç muhasebesi prosedürü, %2 belgesinin alacak/borç muhasebesi prosedüründen farklıdır.'");
			Else
				MessageText = NStr("vi = 'Trong chứng từ đã chọn, trình tự hạch toán %1 khác với trình tự hạch toán của chứng từ %2.';
									|ru = 'У выбранного заказа порядок расчетов %1 отличается от порядка расчетов документа %2.';
									|en = 'The %1 payment terms of the selected order differ from the %2 payment terms of the document.'; fa = 'The %1 payment terms of the selected order differ from the %2 payment terms of the document.';
									|it = 'У выбранного заказа порядок расчетов %1 отличается от порядка расчетов документа %2.';
									|pl = 'The %1 payment terms of the selected order differ from the %2 payment terms of the document.';
									|tr = 'Seçilen emir için %1 alacak/borç muhasebesi prosedürü %2 belgesinin alacak/borç muhasebesi prosedüründen farklıdır.'");
			EndIf;
			
			MessageText = StrTemplate(MessageText, Result.ARAPObjectSettings, Object.ARAPObjectSettings);
			RowIndex = Object.Goods.FindByID(Items.Goods.CurrentData.GetID()).LineNumber - 1;
			CommonClient.MessageToUser(MessageText,,"Object.Goods[" + RowIndex + "].SalesOrder");
			Return;
			
		Else
			Object.ARAPObjectSettings = Result.ARAPObjectSettings;
		EndIf;
		
	EndIf;
	
	SalesOrder = Result.SalesOrder;
	
	Items.Goods.CurrentData.SalesOrder = SalesOrder;
	
	ProductsCustomerOrderStartSelectionFragment();
	
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
	ValueSelected.Value                   = CurrentRow.Series;
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
		
		AdditionalParameters = AdditionalCompletionProcessingParameters();
		AdditionalParameters.CurrentRow = CurrentRow;
		ProductsSeriesRecalculatePricesCompletion(AdditionalParameters);
		
	EndIf;
	
EndProcedure

// Parameters:
// 	AdditionalParameters - See AdditionalCompletionProcessingParameters
&AtClient
Procedure ProductsSeriesRecalculatePricesCompletion(AdditionalParameters) Export
	
	CurrentRow = AdditionalParameters.CurrentRow;
	
	ParametersForFillingInVATAmountLocalManSManSManSManSManSManSManSManS = BatchProcessingOfTablePartClientServer.ParametersForFillingInVATAmountLocalManSManSManSManSManSManSManSManS(
		Object.Currency,
		LocalAccountingCurrency,
		ManagementAccountingCurrency);
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	
	StructureOfActions = New Structure;
	If (ToUseTermsOfSales And ValueIsFilled(Object.Terms)) 
		Or (Not ToUseTermsOfSales And UsePriceManagementSystem25) Then
		StructureOfActions.Insert("FillIn_TermsOfSales", BatchProcessingOfTablePartClientServer.GetStructureForFillingInSalesConditionsInTSLine(Object));
	Else
		StructureOfActions.Insert("FillInSalePrice", BatchProcessingOfTablePartClientServer.ParametersForFillingInPriceInTSLine(Object));
	EndIf;
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmount");
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountManualDiscount", New Structure("Clear", True));
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountAutomaticDiscount", New Structure("Clear", True));
	StructureOfActions.Insert("ClearAmountOfSettlements");
	StructureOfActions.Insert("SetVATAmountLocalMans", ParametersForFillingInVATAmountLocalManSManSManSManSManSManSManSManS);
	StructureOfActions.Insert("FillInDuplicateDependentDetails", DependentDetails());
	
	If AdditionalParameters.LineDetachedFromOrder Then
		LinesOfBusinessClientServer.StructureOfInsertActionsWhenAddingRow(ThisObject, StructureOfActions);
	EndIf;
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
	CalculateTotals_(ThisObject);
	DiscountsMarkupsFillingClient.ResetDiscountsCalculatedFlag(ThisForm);
	
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
Procedure CheckQuantityInTheDocument(Command)
	
	CheckQuantityInTheDocumentClient();
	
EndProcedure

&AtClient
Procedure CheckQuantityInTheDocumentCompletion(Result, AdditionalParameters) Export
	
	ReturnParameters = Result;
	If ReturnParameters <> Undefined Then

		ClearMessages();
		CheckQuantityInTheDocumentCompletionServer(
			ReturnParameters, 
			?(CachedValues = Undefined, BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues(), CachedValues));

		Modified = True;
		
		BaseText = NStr("vi = 'đã nhập trên cơ sở lệnh hoặc không sử dụng được vai trò ""Bán hàng vượt quá đơn hàng"".';
						|ru = 'введенного на основании распоряжения или недоступна роль ""Реализация сверх заказа"".';
						|en = 'entered based on the reference, or the ""Sales in excess of order"" role is unavailable.'; fa = 'entered based on the reference, or the ""Sales in excess of order"" role is unavailable.';
						|it = 'введенного на основании распоряжения или недоступна роль ""Реализация сверх заказа"".';
						|pl = 'entered based on the reference, or the ""Sales in excess of order"" role is unavailable.';
						|tr = 'введенного на основании распоряжения или недоступна роль ""Реализация сверх заказа"".'");
		TMCommonUseClient.DisplayMessageExceedingNumber(ReturnParameters, BaseText);
		
		SetWhetherWarehouseIsFull();
		
	EndIf;

EndProcedure

&AtClient
Procedure FillThePricesByTermsOfSales(Command)
	
	If EnterprisePricesFillingClient.ItIsNecessaryToFillInPricesByAgreement(Object, "Goods", NStr("vi = 'Hàng hóa';
																									|ru = 'Товары';
																									|en = 'Goods'; fa = 'کالاها';
																									|it = 'Merci';
																									|pl = 'Towary';
																									|tr = 'Ürünler'")) Then
		If SalesInExcessOfOrder And Not VarianceFromSalesTermsAndConditions Then
			If Object.OrderSales And Object.Goods.Total("OrderDiscrepancy_3") = 0 Then
				
				If Object.BusinessOperation =
					PredefinedValue("Enum.BusinessTransactions.TransferOfTitleToGoods") Then
				
					WarningText = NStr("vi = 'Không thể gán đơn giá vào các dòng theo lệnh.';
										|ru = 'Цена не может быть назначена в строках по распоряжению.';
										|en = 'Price cannot be assigned in the reference lines.'; fa = 'Price cannot be assigned in the reference lines.';
										|it = 'Price cannot be assigned in the reference lines.';
										|pl = 'Price cannot be assigned in the reference lines.';
										|tr = 'Fiyat, sipariş satırlarına atanamıyor.'");
				Else
					WarningText = NStr("vi = 'Giá không thể gán cho các dòng theo đơn hàng.';
										|ru = 'Цена не может быть назначена в строках по заказу.';
										|en = 'Price cannot be assigned in the order lines.'; fa = 'Price cannot be assigned in the order lines.';
										|it = 'Il prezzo non può essere impostato nelle righe per ordine.';
										|pl = 'Cena nie może być wyznaczona w wierszach wg zamówienia.';
										|tr = 'Fiyat, sipariş satırlarına girilemiyor.'");
				EndIf;
				
				ShowMessageBox(Undefined, WarningText);
				Return
			EndIf;
		EndIf;

		ClearMessages();

		ErrorText = "";
		PricesCalculated = FillInPricesByAgreementOnServer(,,ErrorText);
		SalesClient.NotifyAboutEndOfFillingInPricesUnderAgreement(PricesCalculated, ErrorText);
		
	EndIf;
	
	DiscountsMarkupsFillingClient.ResetDiscountsCalculatedFlag(ThisObject);
	
EndProcedure

&AtClient
Procedure FillInPricesUnderAgreement(Command)
	
	TypeOfContractPrice = TypeOfContractPrice(Object.Contract);
	
	If EnterprisePricesFillingClient.YouNeedToFillInPricesByType(Object, TypeOfContractPrice) Then
		
		ClearMessages();

		ErrorText = "";
		PricesCalculated = FillInContractPricesOnServer(ErrorText);
		DiscountsMarkupsFillingClient.ResetDiscountsCalculatedFlag(ThisObject);
		SalesClient.NotifyAboutEndOfFillingInPricesUnderAgreement(PricesCalculated, ErrorText);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure FillInPricesOfSelectedRowsByPriceType(Command)

	If EnterprisePricesFillingClient.ItIsNecessaryToFillInPricesByTypeOfPrices(Object, "Goods", NStr("vi = 'Hàng hóa';
																									|ru = 'Товары';
																									|en = 'Goods'; fa = 'کالاها';
																									|it = 'Merci';
																									|pl = 'Towary';
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
Procedure FillInPricesOfSelectedRowsByPriceTypeCompletion(PricesKind, AdditionalParameters) Export
	
	If ValueIsFilled(PricesKind) Then
		
		RowsArray = New Array;
		
		For Each CurRow In Items.Goods.SelectedRows Do
			FoundRow = Object.Goods.FindByID(CurRow);
			If ?(SalesInExcessOfOrder, FoundRow.RowCode = 0, True) Then
				RowsArray.Add(FoundRow);
			EndIf;
		EndDo;
			
		If RowsArray.Count() = 0
			And SalesInExcessOfOrder And Not VarianceFromSalesTermsAndConditions 
			And Object.OrderSales Then
			
			If Object.BusinessOperation =
				PredefinedValue("Enum.BusinessTransactions.TransferOfTitleToGoods") Then
			
				WarningText = NStr("vi = 'Không thể gán đơn giá vào các dòng theo lệnh.';
									|ru = 'Цена не может быть назначена в строках по распоряжению.';
									|en = 'Price cannot be assigned in the reference lines.'; fa = 'Price cannot be assigned in the reference lines.';
									|it = 'Price cannot be assigned in the reference lines.';
									|pl = 'Price cannot be assigned in the reference lines.';
									|tr = 'Fiyat, sipariş satırlarına atanamıyor.'");
			Else
				WarningText = NStr("vi = 'Giá không thể gán cho các dòng theo đơn hàng.';
									|ru = 'Цена не может быть назначена в строках по заказу.';
									|en = 'Price cannot be assigned in the order lines.'; fa = 'Price cannot be assigned in the order lines.';
									|it = 'Il prezzo non può essere impostato nelle righe per ordine.';
									|pl = 'Cena nie może być wyznaczona w wierszach wg zamówienia.';
									|tr = 'Fiyat, sipariş satırlarına girilemiyor.'");
			EndIf;
			
			ShowMessageBox(Undefined, WarningText);
			Return
		EndIf;
		
		ClearMessages();
		ApplyPaymentWithBonusPointsClient(, True);

		PricesCalculated = FillInPricesOfSelectedRowsByPriceTypeServer(PricesKind);
		SalesClient.NotifyAboutEndOfFillingInPricesByTypeOfPrices(PricesCalculated, PricesKind);
		
		DiscountsMarkupsFillingClient.ResetDiscountsCalculatedFlag(ThisForm);
		
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
	
	DiscountsMarkupsFillingClient.ResetDiscountsCalculatedFlag(ThisForm);
	
EndProcedure

&AtClient
Procedure ImportDataFromPDT(Command)
	
	ClearMessages();
	
	EquipmentManagerClient.StartDownloadingDataFromTSD(
		New CallbackDescription("DownloadFromTSDCompletion", ThisObject),
		UUID);
	
EndProcedure

&AtClient
Procedure DownloadFromTSDCompletion(ExecutionResult, Var_Parameters) Export
	
	If ExecutionResult.Result Then
		ProcessBarcodes(ExecutionResult.TableOfGoods);
	Else
		EquipmentManagerTMClient.ReportError(ExecutionResult);
	EndIf;
	
EndProcedure

&AtClient
Procedure OpenInventoryKinds(Command)
	
	OptionsForEditingInventoryTypes = PutGoodsAndStockTypesInStorage();
	
	FinancesClient.OpenInventoryKinds(ThisObject, OptionsForEditingInventoryTypes);
	
EndProcedure

&AtClient
Procedure Attachable_PropertiesExecuteCommand(ItemOrCommand, Var_URL = Undefined, StandardProcessing = Undefined)
	PropertyManagerClient.ExecuteCommand(ThisObject, ItemOrCommand, StandardProcessing);
EndProcedure

&AtClient
Procedure ReportErrorsWhenOpeningSelection(Cancel)
	
	If ToUseTermsOfSales And Not ValueIsFilled(Object.Terms) Then
		CommonClient.MessageToUser(NStr("vi = 'Chưa điền trường ""Thỏa thuận""';
										|ru = 'Поле ""Соглашение"" не заполнено';
										|en = '""Terms of sales"" are not filled'; fa = '""Terms of sales"" are not filled';
										|it = 'Il campo ""Accordo"" non è compilato';
										|pl = 'Pole ""Porozumienie"" nie jest wypełnione';
										|tr = '""Anlaşma"" alanı doldurulmamış'"), Object.Ref, "Object.Terms",,Cancel);
	EndIf;
	
	If Not ValueIsFilled(Object.Currency) Then
		CommonClient.MessageToUser(NStr("vi = 'Chưa điền trường ""Tiền tệ""';
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
		"Document.CustomerInvoice.DocumentForm.Command.OpenSelection");
	
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
		HeaderParameter_ = StrReplace(HeaderParameter_, "%Document%", NStr("vi = 'giao hàng và cung cấp dịch vụ';
																			|ru = 'реализацию товаров и услуг';
																			|en = 'customer invoice'; fa = 'customer invoice';
																			|it = 'vendita di merci e servizi';
																			|pl = 'sprzedaż towarów i usług';
																			|tr = 'mal ve hizmet satışı'"));
	EndIf;
	
	FormParameters = New Structure;
	FormParameters.Insert("Partner", Object.Partner);
	FormParameters.Insert("Terms", Object.Terms);
	FormParameters.Insert("Organization", Object.Organization);
	FormParameters.Insert("PriceIncludesVAT", Object.PriceIncludesVAT);
	FormParameters.Insert("VATTaxation", Object.VATTaxation);
	FormParameters.Insert("ReturnReusablePackage", Object.ToReturnReusablePackage);
	FormParameters.Insert("Warehouse", Object.Warehouse);
	FormParameters.Insert("Currency", Object.Currency);
	FormParameters.Insert("Title", HeaderParameter_);
	FormParameters.Insert("Date", Object.Date);
	FormParameters.Insert("SelectionModeUseWarehousesInTabularSection", True);
	FormParameters.Insert("SelectionModeExcludeGroupsAvailableInOrders", True);
	FormParameters.Insert("LineOfBusiness", Object.LineOfBusiness);
	
	If Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.TransferToCommissionAgent") Then
		FormParameters.Insert("FilterByProductType", New FixedArray(ProductsClientServer.SelectionByProductMultiTurnContainer()));
		FormParameters.Insert("HideManualDiscounts", True);
	ElsIf SalesViaCommissionAgent Then
		FormParameters.Insert("HideManualDiscounts",True);
		FormParameters.Insert("SelectionModeWithoutAgreementsWithCustomers", True);
		FormParameters.Insert("PriceKind", PriceTypeUnderContract);
	ElsIf Object.BusinessOperation =
			PredefinedValue("Enum.BusinessTransactions.TransferOfTitleToGoods") Then
		
		FilterByProductType = New Array;
		FilterByProductType.Add(PredefinedValue("Enum.ItemsTypes.OwnGoods"));
		FilterByProductType.Add(PredefinedValue("Enum.ItemsTypes.Set"));
		
		FormParameters.Insert("FilterByProductType", New FixedArray(FilterByProductType));
			
	EndIf;
	
	FormParameters.Insert("Document", Object.Ref);
	FormParameters.Insert("SeriesSpecificationParameters", SeriesSpecificationParameters);
	FormParameters.Insert("UseAdvancedFeaturesOfSalesOrder", UseAdvancedFeaturesOfSalesOrder);
	
	AddLocalizationFormParameters(FormParameters);
	
	OpenForm("DataProcessor.SelectGoodsToSalesDocument.Form", FormParameters, ThisForm, UUID);
	
EndProcedure

&AtClient
Procedure CalculateDiscountsMarkups(Command)
	
	CalculateDiscountsMarkupsClient();
	
EndProcedure

&AtClient
Procedure OpenInformationAboutDiscounts(Command)
	
	CurrentData = Items.Goods.CurrentData;
	
	If CurrentData <> Undefined And ValueIsFilled(CurrentData.RowCode) Then
		
		If Object.BusinessOperation =
			PredefinedValue("Enum.BusinessTransactions.TransferOfTitleToGoods") Then
			
			WarningText = NStr("vi = 'Chỉ có thể xem thông tin về chiết khấu (phụ thu) tại các dòng vượt quá lệnh.';
								|ru = 'Просмотр информации о скидках (наценках) возможен только в строках сверх распоряжения.';
								|en = 'You can view information about discounts (markups) only in lines in excess of the reference.'; fa = 'You can view information about discounts (markups) only in lines in excess of the reference.';
								|it = 'You can view information about discounts (markups) only in lines in excess of the reference.';
								|pl = 'You can view information about discounts (markups) only in lines in excess of the reference.';
								|tr = 'İndirimlerle (zamlarla) ilgili bilgiler yalnızca siparişin üzerindeki satırlarda görüntülenebilir.'");
		Else
			WarningText = NStr("vi = 'Chỉ có thể xem thông tin về chiết khấu (phụ thu) tại các dòng khác với đơn hàng.';
								|ru = 'Просмотр информации о скидках (наценках) возможен только в строках сверх заказа.';
								|en = 'You can view information about discounts (markups) only in lines in excess of order.'; fa = 'You can view information about discounts (markups) only in lines in excess of order.';
								|it = 'Visualizzazione dell''informazione sugli sconti (maggiorazioni) è possibile solo nelle righe oltre l''ordine.';
								|pl = 'Wyświetlanie informacji o rabatach (marżach) jest możliwe tylko w wierszach przewyższających zamówienie.';
								|tr = 'İndirimlerle (zamlarla) ilgili bilgiler yalnızca siparişin üzerindeki satırlarda görüntülenebilir.'");
		EndIf;
		
		ShowMessageBox(Undefined, WarningText);		
		Return;
	EndIf;
	
	If Not Object.DiscountsAreCalculated Then
		
		ShowQueryBox(New CallbackDescription("OpenInformationAboutDiscountsCompletion", ThisObject, 
			New Structure("CurrentData", CurrentData)), NStr("vi = 'Chưa tính chiết khấu (phụ thu), tính chiết khấu (phụ thu)?';
															|ru = 'Скидки (наценки) не рассчитаны, рассчитать?';
															|en = 'Discounts (markups) are not calculated, calculate?'; fa = 'Discounts (markups) are not calculated, calculate?';
															|it = 'Gli sconti (sovrapprezzi) non sono stati calcolati, calcolare?';
															|pl = 'Rabaty (marże) nie są obliczane, obliczyć?';
															|tr = 'İndirimler uygulanmadı. Uygulamak istiyor musunuz?'"), 
			QuestionDialogMode.YesNo);
        Return;
		
	EndIf;
	
	OpenDiscountInformationFragment(CurrentData);
EndProcedure

&AtClient
Procedure OpenInformationAboutDiscountsCompletion(QuestionResult, AdditionalParameters) Export
	
	CurrentData = AdditionalParameters.CurrentData;
	
	Result = QuestionResult;
	If Result = DialogReturnCode.No Then
		Return;
	Else
		
		ParametersStructure1 = New Structure;
		ParametersStructure1.Insert("ApplyToObject",                True);
		ParametersStructure1.Insert("OnlyPreliminaryCalculation",      False);
		ParametersStructure1.Insert("RestoreManagedDiscounts", True);
		ParametersStructure1.Insert("ManagedDiscounts", ManagedDiscounts);
		ParametersStructure1.Insert("SalesInExcessOfOrder", SalesInExcessOfOrder And Object.OrderSales);
		
		TheStructureOfTheMessages = CalculateDiscountsMarginsOnServer(ParametersStructure1);
		If TheStructureOfTheMessages.Messages.Count() > 0 And TheStructureOfTheMessages.AutomaticallyOpen Then
			OpenForm("CommonForm.MessagesOfDiscountsMarkups", TheStructureOfTheMessages, ThisForm, UUID);
		EndIf;
		
	EndIf;
	
	OpenDiscountInformationFragment(CurrentData);

EndProcedure

&AtClient
Procedure OpenDiscountInformationFragment(Val CurrentData)
    
    If Not ValueIsFilled(AddressOfAppliedDiscountsInTheTemporaryStorage) Then
        CalculateDiscountsWithoutApplyingToObject();
    EndIf;
    
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
		ParametersStructure1.Insert("SalesInExcessOfOrder", SalesInExcessOfOrder And Object.OrderSales);
		
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
	ImplementationInExcessOfOrderByOrder = SalesInExcessOfOrder And Object.OrderSales;
	If Not ItIsPossibleToAssignManualDiscountMarkUp() Then
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
		
		CalculateTotals_(ThisObject)
		
	EndIf;

EndProcedure

&AtClient
Procedure AssignAManualDiscountForSelectedLines(Command)
	ImplementationInExcessOfOrderByOrder = SalesInExcessOfOrder And Object.OrderSales;
	If Not ItIsPossibleToAssignManualDiscountMarkUp() Then
		Return;
	EndIf;
	
	If Items.Goods.SelectedRows <> Undefined And ImplementationInExcessOfOrderByOrder Then
		TabularSectionRows = New Array();
		For Each CurRow In Items.Goods.SelectedRows Do
			FoundRow = Object.Goods.FindByID(CurRow);
			If FoundRow.RowCode = 0 Then
				TabularSectionRows.Add(FoundRow);
			EndIf;
		EndDo;
		
		If TabularSectionRows.Count() = 0 Then
			
			If Object.BusinessOperation =
				PredefinedValue("Enum.BusinessTransactions.TransferOfTitleToGoods") Then
			
				WarningText = NStr("vi = 'Chiết khấu (phụ thu) thủ công không thể được ấn định tại các dòng theo lệnh.';
									|ru = 'Ручная скидка (наценка) не может быть назначена в строках по распоряжению.';
									|en = 'Discount/markup adjustment cannot be assigned in the reference lines.'; fa = 'Discount/markup adjustment cannot be assigned in the reference lines.';
									|it = 'Discount/markup adjustment cannot be assigned in the reference lines.';
									|pl = 'Discount/markup adjustment cannot be assigned in the reference lines.';
									|tr = 'İndirim (zam) düzeltmesi, sipariş satırlarına girilemez.'");
			Else
				WarningText = NStr("vi = 'Chiết khấu (phụ thu) thủ công không thể được ấn định tại các dòng theo đơn hàng.';
									|ru = 'Ручная скидка (наценка) не может быть назначена в строках по заказу.';
									|en = 'Discount/markup adjustment cannot be assigned in the order lines.'; fa = 'Discount/markup adjustment cannot be assigned in the order lines.';
									|it = 'Sconto (maggiorazione) manuale non può essere impostata nelle righe per ordine.';
									|pl = 'Rabat ręczny (marże) nie może być wyznaczona w wierszach wg zamówienia.';
									|tr = 'İndirim (zam) düzeltmesi, sipariş satırlarına girilemez.'");
			EndIf;
			
			ShowMessageBox(Undefined, WarningText);
			Return;
		EndIf;
		
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
		
		CalculateTotals_(ThisObject);
		
	EndIf;

EndProcedure

&AtClient
Procedure CancelManualDiscounts(Command)
	ImplementationInExcessOfOrderByOrder = SalesInExcessOfOrder And Object.OrderSales;
	If Not ItIsPossibleToCancelManualDiscountsMarkups() Then
		Return;
	EndIf;
	
	CancelManualDiscountsOnServer();
	DiscountsMarkupsFillingClient.NotifyAboutEndOfAssignmentOfManualDiscountsMargins();
	
	CalculateTotals_(ThisObject);
	
EndProcedure

&AtClient
Procedure CalculateDiscountsMarkupsClient()
	
	ParametersStructure1 = New Structure;
	ParametersStructure1.Insert("ApplyToObject",                True);
	ParametersStructure1.Insert("OnlyPreliminaryCalculation",      False);
	ParametersStructure1.Insert("RestoreManagedDiscounts", True);
	ParametersStructure1.Insert("ManagedDiscounts", ManagedDiscounts);
	ParametersStructure1.Insert("SalesInExcessOfOrder", SalesInExcessOfOrder And Object.OrderSales);
	
	If Not Object.OrderSales Then
		
		TheStructureOfTheMessages = CalculateDiscountsMarginsOnServer(ParametersStructure1);
		If TheStructureOfTheMessages.Messages.Count() > 0 And TheStructureOfTheMessages.AutomaticallyOpen Then
			OpenForm("CommonForm.MessagesOfDiscountsMarkups", TheStructureOfTheMessages, ThisForm, UUID);
		EndIf;
		
	Else
		CalculateForSaleOfGoodsServicesByOrder();
		If SalesInExcessOfOrder Then
			TheStructureOfTheMessages = CalculateDiscountsMarginsOnServer(ParametersStructure1);
			If TheStructureOfTheMessages.Messages.Count() > 0 And TheStructureOfTheMessages.AutomaticallyOpen Then
				OpenForm("CommonForm.MessagesOfDiscountsMarkups", TheStructureOfTheMessages, ThisForm, UUID);
			EndIf;
		EndIf;
		
		CalculateTotals_(ThisObject);
		
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

// Parameters:
//	FillInImplementationByOrder - Boolean
&AtServer
Procedure CalculateForSaleOfGoodsServicesByOrder(Val FillInImplementationByOrder = True)
	
	CalculationParameters = DiscountsMarkupsFillingServer.NewParametersCalculate();
	CalculationParameters.FillInImplementationByOrder = FillInImplementationByOrder;
	DiscountsMarkupsFillingServer.Calculate(Object, CalculationParameters);
	FillInDataForCalculatingPaymentWithBonusPoints();
	
EndProcedure

&AtClient
Procedure ApplyDiscountMarkUpChangesOnCustomer(Cancel)
	
	If Not Object.OrderSales Then
		TheStructureOfTheMessages = CalculateDiscountsMarginsOnServer(Undefined, True);
		If TheStructureOfTheMessages.Messages.Count() > 0 And TheStructureOfTheMessages.AutomaticallyOpen Then
			OpenForm("CommonForm.MessagesOfDiscountsMarkups", TheStructureOfTheMessages, ThisForm, UUID);
			Cancel = True;
		EndIf;
	Else
		CalculateForSaleOfGoodsServicesByOrder();
		If SalesInExcessOfOrder Then
			TheStructureOfTheMessages = CalculateDiscountsMarginsOnServer(Undefined, True);
			If TheStructureOfTheMessages.Messages.Count() > 0 And TheStructureOfTheMessages.AutomaticallyOpen Then
				OpenForm("CommonForm.MessagesOfDiscountsMarkups", TheStructureOfTheMessages, ThisForm, UUID);
				Cancel = True;
			EndIf;
		EndIf;
		
		CalculateTotals_(ThisObject);
		
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
Procedure SelectGoodsByOrdersNotes(Command)
	
	PickUpFromOrder();
	
EndProcedure

&AtServer
Procedure PlacePaymentDecryptionInTemporaryStorage()
	ARAPAccountingFormWork.PlacePaymentDecryptionInTemporaryStorage(ThisForm, "PaymentSettlement");
EndProcedure

&AtClient
Procedure GetWeight(Command)
	
	CurrentRow = EquipmentManagerTMClient.CurrentRow(ThisForm);
	If CurrentRow = Undefined Then
		Return;
	EndIf;
	
	EquipmentManagerClient.StartGettingWeightWithElectronicScales(
		New CallbackDescription("GetWeightCompletion", ThisObject, CurrentRow),
		UUID);
	
EndProcedure

&AtClient
Procedure GetWeightCompletion(ExecutionResult, CurrentRow) Export
	
	If ExecutionResult.Result Then
		CurrentRow.NumberOfPackages = ExecutionResult.Weight;
		
		StructureOfFillingBonusPoints = Undefined;
		VerificationOfPaymentWithBonusPoints(CurrentRow, StructureOfFillingBonusPoints);

		StructureOfActions = New Structure;
		AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions, Object, StructureOfFillingBonusPoints);
		
		ParametersForFillingInVATAmountLocalManSManSManSManSManSManSManSManS = BatchProcessingOfTablePartClientServer.ParametersForFillingInVATAmountLocalManSManSManSManSManSManSManSManS(
			Object.Currency,
			LocalAccountingCurrency,
			ManagementAccountingCurrency);
		
		StructureOfActions.Insert("SetVATAmountLocalMans", ParametersForFillingInVATAmountLocalManSManSManSManSManSManSManSManS);
		
		BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
		
		CalculateTotals_(ThisObject);
		DiscountsMarkupsFillingClient.ResetDiscountsCalculatedFlag(ThisForm);
	Else
		EquipmentManagerTMClient.ReportError(ExecutionResult);
	EndIf;
	
EndProcedure

&AtClient
Procedure FillInTheWarehouseInSelectedLines(Command)
	
	SelectedRows = Items.Goods.SelectedRows;
	If WarehousesClient.CheckPossibilityOfFillingWarehousesInTablePart(Object, Object.Goods, NStr("vi = 'Hàng hóa';
																									|ru = 'Товары';
																									|en = 'Goods'; fa = 'کالاها';
																									|it = 'Merci';
																									|pl = 'Towary';
																									|tr = 'Ürünler'"), SelectedRows) Then
		
		FilterStructure1 = New Structure("SelectGroup,IsFolder", PredefinedValue("Enum.SelectWarehouseGroup.AllowInOrdersAndInvoices"), False);
		ParametersStructure = New Structure("Filter,GroupOfWarehouses,TableRepresentation", 
				FilterStructure1, Object.Warehouse,  TableRepresentation.List);
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
Procedure SplitRow(Command)
	
	FormTable  = Items.Goods;
	TableData = Object.Goods;
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.StructureOfRecalculationOfAmount(
		"Count, Sum, VATAmount, AmountIncludingVAT, ManualDiscount, DiscountMarkupAmount,
		| AmountOfBonusPointsToDeduction, AmountOfBonusPointsToDeductionInCurrency, "
		+ DependentPropsByString(), "NumberOfPackages");
		
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
		
		NewRow.DeliveryLineCode = 0;
		
		BatchProcessingOfTablePartClientServer.AddLineToRecalculateAmount(AdditionalParameters.StructureOfRecalculationOfAmount, CurrentRow);
		BatchProcessingOfTablePartClientServer.AddLineToRecalculateAmount(AdditionalParameters.StructureOfRecalculationOfAmount, NewRow);
		BatchProcessingOfTablePartClientServer.RecalculateAmounts(AdditionalParameters.StructureOfRecalculationOfAmount);
		
		ParametersForFillingInVATAmountLocalManSManSManSManSManSManSManSManS = BatchProcessingOfTablePartClientServer.ParametersForFillingInVATAmountLocalManSManSManSManSManSManSManSManS(
			Object.Currency,
			LocalAccountingCurrency,
			ManagementAccountingCurrency);
		
		StructureOfActions = New Structure;
		StructureOfActions.Insert("ClearAmountOfSettlements");
		StructureOfActions.Insert("SetVATAmountLocalMans", ParametersForFillingInVATAmountLocalManSManSManSManSManSManSManSManS);
		
		AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions, Object);
		
		BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
		BatchProcessingOfTablePartClient.ProcessTSString(NewRow, StructureOfActions, CachedValues);
		
		WhenChangingWarehouseInTablePartServer();
		CalculateTotals_(ThisObject);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure SpecifySeries(Command)
	
	OpenSelectionOfSeries();
	
EndProcedure

&AtClient
Procedure FillInSeriesByFEFO(Command)
	
	ClearMessages();
	
	TableData = Object.Goods;
	If ThereAreFilledSeriesByFEFO(TableData) Then
		
		ProductsClient.AskQuestionAboutReFillingSeriesByFEFO(
			New CallbackDescription("CompleteSeriesOnFEFOCompletion", ThisObject));
		Return;
		
	EndIf;
	
	If Not FillInSeriesByFEFOServer() Then
		ProductsClient.WarnAboutAbsenceOfLinesFilledByFEFO();
	EndIf;
	
EndProcedure

&AtClient
Procedure CompleteSeriesOnFEFOCompletion(Result, AdditionalParameters) Export 
	
	If Not Result Then
		Return;
	EndIf;
	
	If Not FillInSeriesByFEFOServer() Then
		ProductsClient.WarnAboutAbsenceOfLinesFilledByFEFO();
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
Procedure PrintDetails(Item)
	
	OpenPrintDetails();
	
EndProcedure

&AtClient
Procedure InsertRows(Command)
	
	NumberOfProductsBeforeInsertion = Object.Goods.Count();
	
	ClearMessages();
	ApplyPaymentWithBonusPointsClient(, True);

	GetLinesFromClipboard();
	DiscountsMarkupsFillingClient.ResetDiscountsCalculatedFlag(ThisForm);
	
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
		ThisForm,
		"Goods",
		"Products,Characteristic,Count,Warehouse");
	
EndProcedure

&AtClient
Procedure UnlinkFromOrder(Command)
	
	SelectedRows = Items.Goods.SelectedRows;
	If SelectedRows.Count()>0 Then
		
		UnlinkFromOrderServer(False);
		NotifyAboutEndOfUnbindingLines(SelectedRows.Count());
		
	Else
		
		If Object.BusinessOperation =
			PredefinedValue("Enum.BusinessTransactions.TransferOfTitleToGoods") Then
		
			WarningText = NStr("vi = 'Hãy chọn dòng cần bỏ liên kết với lệnh.';
								|ru = 'Выберите строки, которые необходимо отвязать от распоряжения.';
								|en = 'Select lines which should be unlinked from the reference.'; fa = 'Select lines which should be unlinked from the reference.';
								|it = 'Select lines which should be unlinked from the reference.';
								|pl = 'Select lines which should be unlinked from the reference.';
								|tr = 'Siparişlerden çıkarılması gereken satırları seçin.'");
		Else
			WarningText = NStr("vi = 'Hãy chọn dòng cần hủy liên kết với đơn hàng.';
								|ru = 'Выберите строки, которые необходимо отвязать от заказа.';
								|en = 'Select lines to remove from the order.'; fa = 'Select lines to remove from the order.';
								|it = 'Selezionare le righe da dissociare dall''ordine.';
								|pl = 'Wybierz wierze, które należy odłączyć od zamówienia.';
								|tr = 'Siparişten çıkarılacak satırları seçin.'");
		EndIf;
		
		ShowMessageBox(Undefined, WarningText);
	EndIf; 
EndProcedure

&AtClient
Procedure ImportFromExternalFile(Command)
	
	ImportParameters = ProcessingOfTabularFormsClient.ProductLoadingParameters();
	ImportParameters.ImportPrices = True;
	ImportParameters.Organization = Object.Organization;
	ImportParameters.PriceIncludesVAT    = Object.PriceIncludesVAT;
	ImportParameters.VATTaxation = Object.VATTaxation;
	ImportParameters.FillingDate     = Object.Date;
	ImportParameters.ThisIsReusablePackage  = Object.ToReturnReusablePackage;
	ImportParameters.ComponentsPriceParameters.Date       = Object.Date;
	ImportParameters.ComponentsPriceParameters.Currency     = Object.Currency;
	ImportParameters.ComponentsPriceParameters.Terms = Object.Terms;
	
	If Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.TransferToCommissionAgent") Then
		ImportParameters.FilterParameters.Insert("ItemsType",
			ProductsClientServer.SelectionByProductMultiTurnContainer());
	ElsIf Object.BusinessOperation =
		PredefinedValue("Enum.BusinessTransactions.TransferOfTitleToGoods") Then
		
		ItemsTypes = New Array;
		ItemsTypes.Add(PredefinedValue("Enum.ItemsTypes.OwnGoods"));
		ItemsTypes.Add(PredefinedValue("Enum.ItemsTypes.Set"));
		ImportParameters.FilterParameters.Insert("ItemsType", ItemsTypes);
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

#EndRegion

#Region FormCommandsEventHandlers

&AtServer
Procedure ExecuteCommandAtServer(ExecutionParameters)
	AttachableCommands.ExecuteCommand(ThisObject, ExecutionParameters, Object);
EndProcedure


&AtClient
Procedure Attachable_ContinueCommandExecutionAtServer(ExecutionParameters, AdditionalParameters) Export
	ExecuteCommandAtServer(ExecutionParameters);
EndProcedure


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
	KitParameters.Insert("SalesOrder", CurrentRow.SalesOrder);
	KitParameters.Insert("ExceedingOrder",          True);
	KitParameters.Insert("DialColumns",        DialColumns(ThisForm));
	
	SetAddressInTemporaryStorage = SetAddressInTemporaryStorage(KitParameters);
	
	OpeningParameters = New Structure;
	OpeningParameters.Insert("AddressInTempStorage", SetAddressInTemporaryStorage);
	OpeningParameters.Insert("ProductsInSet", CurrentRow.ProductsInSet);
	OpeningParameters.Insert("ItemVariantOfSet", CurrentRow.ItemVariantOfSet);
	OpeningParameters.Insert("SalesOrder", CurrentRow.SalesOrder);
	OpeningParameters.Insert("PriceIncludesVAT", Object.PriceIncludesVAT);
	OpeningParameters.Insert("VATTaxation", Object.VATTaxation);
	OpeningParameters.Insert("Currency", Object.Currency);
 	OpeningParameters.Insert("Partner", Object.Partner);
 	OpeningParameters.Insert("Terms", Object.Terms);
	OpeningParameters.Insert("Ref", Object.Ref);
	OpeningParameters.Insert("Date", Object.Date);
	OpeningParameters.Insert("Warehouse", Object.Warehouse);
	OpeningParameters.Insert("HideCommandRemainingQuantityInWarehouses", False);
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
Procedure WriteDocument(Command)
	
	TMCommonUseClient.Write(ThisForm, True);
	
EndProcedure

&AtClient
Procedure SetDeletionMarkForADocument(Command)
	
	TMCommonUseClient.SetDeletionMarkForADocument(ThisForm);
	
EndProcedure

&AtClient
Procedure CloseOrder(Command)
	
	If Modified Or Not Object.Posted Then
		Response = Undefined;
		ShowQueryBox(New CallbackDescription("CloseOrderCompletion", ThisObject),
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
Procedure CloseOrderFragment()
	
	ListOfOrdersToClose = New ValueList;
	
	If ValueIsFilled(Object.SalesOrder) Then
		BasisDocuments = CommonClientServer.ValueInArray(Object.SalesOrder);
	Else
		BasisDocuments = OrderList.UnloadValues();
	EndIf;
	
	For Each ReferenceOrder In BasisDocuments Do
		
		If TypeOf(ReferenceOrder) = Type("DocumentRef.SalesOrder")
			Or TypeOf(ReferenceOrder) = Type("DocumentRef.RequestForReturnOfGoodsFromCustomer") Then
			ListOfOrdersToClose.Add(ReferenceOrder);
		EndIf;
		
	EndDo;
	
	ClosureStructure = New Structure;
	ClosureStructure.Insert("Orders",                       ListOfOrdersToClose);
	ClosureStructure.Insert("DocumentInitiator",            Object.Ref);
	ClosureStructure.Insert("CancelUnprocessedLines", True);
	ClosureStructure.Insert("CloseOrders",              True);
	
	OpenForm("DataProcessor.OrderClosureWizard.Form.ClosureForm",
		ClosureStructure,,,,,,
		FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure PaymentSettlement(Command)
	
	PlacePaymentDecryptionInTemporaryStorage();
	ARAPAccountingClient.PaymentSettlement(ThisForm, Items.PaymentSettlement);
	
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
	
	DiscountsMarkupsFillingClient.ResetDiscountsCalculatedFlag(ThisForm);
	
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
		CalculateTotals_(ThisObject);
		Return;
	EndIf;
	
	ApplyPaymentWithBonusPointsClient(Result.AddressInTempStorage);
	
	DiscountsMarkupsFillingClient.ResetDiscountsCalculatedFlag(ThisForm);
	
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
Procedure Attachable_UpdateSBPPaymentStatus(Command)

	ClearMessages();
	CashClientLocalization.UpdateStatusOfSBPPaymentByDocument(ThisObject, Object.Ref);

EndProcedure

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
Procedure ContractOnChangeCompletionServer(Val FlagFillThePricesByTermsOfSales, PricesCalculated, ErrorText) 
	
	If FlagFillThePricesByTermsOfSales Then

		PricesCalculated = FillInPricesByAgreementOnServer(True, False, ErrorText);
			
	EndIf;
		
	ContractOnChangeServer();
		
EndProcedure

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

	InventoriesServer.EstablishConditionalAppearanceOfDivisionForTypesOfStocks(ThisForm);
	
	//

	VATAccountingERP.EstablishConditionalAppearanceOfHSCodeForTaxationOfSales(ThisForm);

	//
	
	VATAccountingERP.EstablishConditionalAppearanceOfVATAmountsForSalesTaxation(ThisForm);
	VATAccountingERP.EstablishConditionalAppearanceOfVATAmountsForSalesTaxation(ThisObject,,
		"GoodsVATAmountMan");
	VATAccountingERP.EstablishConditionalAppearanceOfVATAmountsForSalesTaxation(ThisObject,,
		"GoodsVATAmountCompl");

	//

	EnterprisePricesFillingServer.SetConditionalAppearancePriceIncludesVAT(ThisForm);

	//

	ProductsServer.SetConditionalAppearanceOfUnitsOfMeasurement(ThisForm);

	//

	LinesOfBusinessServer.SetConditionalAppearanceOfFlagSeparately(ThisObject);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsPrice.Name);

	FilterGroup1 = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup1.GroupType = DataCompositionFilterItemsGroupType.OrGroup;

	FilterGroup2 = FilterGroup1.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup2.GroupType = DataCompositionFilterItemsGroupType.AndGroup;

	ItemFilter = FilterGroup2.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.RowCode");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;

	ItemFilter = FilterGroup2.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("VarianceFromSalesTermsAndConditions");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;

	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.PriceKind");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;

	Item.Appearance.SetParameterValue("ReadOnly", True);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsSum.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsVATAmount.Name);

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

	ItemFilter = FilterGroup2.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("SalesInExcessOfOrder");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;

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
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.BusinessTransactions.TransferToCommissionAgent;

	FilterGroup2 = FilterGroup1.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup2.GroupType = DataCompositionFilterItemsGroupType.AndGroup;

	ItemFilter = FilterGroup2.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("VarianceFromSalesTermsAndConditions");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;

	ItemFilter = FilterGroup2.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.SalesOrder");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;

	ItemFilter = FilterGroup2.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("SalesInExcessOfOrder");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	ItemFilter = FilterGroup2.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.RowCode");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	Item.Appearance.SetParameterValue("ReadOnly", True);
	
	//

	ProductsServer.EstablishConditionalAppearanceOfProductCharacteristics(ThisForm);

	//

	WarehousesServer.SetConditionalAppearanceOfVTCHWarehouse(ThisForm);

	//
	
	ConditionalDesignParameters = WarehousesServer.ParametersOfConditionalAppearanceOfVHFWarehouseByItemType();
	ConditionalDesignParameters.Form = ThisObject;
	WarehousesServer.SetConditionalAppearanceOfVHFWarehouseByTypeOfItem(ConditionalDesignParameters);
	
	//
	
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.Warehouse.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsWarehouse.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.BusinessOperation");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue =
		PredefinedValue("Enum.BusinessTransactions.TransferOfTitleToGoods");
	
	Item.Appearance.SetParameterValue("Visible", False);
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsVATAmountCompl.Name);
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsVATAmountMan.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.BusinessOperation");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotEqual;
	ItemFilter.RightValue =
		PredefinedValue("Enum.BusinessTransactions.TransferOfTitleToGoods");
	
	Item.Appearance.SetParameterValue("Visible", False);
	
	//
	
	WarehousesServer.EstablishConditionalAppearanceOfVTCHDivision(ThisForm);
	
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
	ItemField.Field = New DataCompositionField(Items.GoodsRowCode.Name);

	FilterGroup1 = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup1.GroupType = DataCompositionFilterItemsGroupType.OrGroup;

	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.SalesOrder");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;

	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.RowCode");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	Item.Appearance.SetParameterValue("MarkIncomplete", False);

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsSalesOrder.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.SalesOrder");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	Item.Appearance.SetParameterValue("TextColor", StyleColors.HyperlinkColor);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsSalesOrder.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("UseSaleByMultipleOrders");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;

	Item.Appearance.SetParameterValue("Visible", False);

	//

	EnterprisePricesFillingServer.EstablishConditionalAppearanceOfPriceTypes(ThisForm);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsSalesOrder.Name);

	FilterGroup1 = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup1.GroupType = DataCompositionFilterItemsGroupType.OrGroup;

	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.SalesOrder");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;

	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.OrderSales");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;

	Item.Appearance.SetParameterValue("Visible", False);

	//
	
	TMCommonUse.SetUncheckBlank(
		ConditionalAppearance, "GoodsWarehouse", "Object.Goods.Warehouse", "Object.Goods.WarehouseIsRequired");
	
	TMCommonUse.SetUncheckBlank(
		ConditionalAppearance, "Warehouse", "Object.Warehouse", "WarehouseIsRequired");

	//

	WarehousesServer.SetConditionalAppearanceOfWarehouseInHeader(ThisForm);

	////

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsPriceKind.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsPercentRateOfManualDiscount.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsManualDiscount.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsPackage.Name);
	
	FilterGroup1 = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup1.GroupType = DataCompositionFilterItemsGroupType.OrGroup;

	FilterGroup2 = FilterGroup1.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup2.GroupType = DataCompositionFilterItemsGroupType.AndGroup;

	ItemFilter = FilterGroup2.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("SalesInExcessOfOrder");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	ItemFilter = FilterGroup2.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.RowCode");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;

	ItemFilter = FilterGroup2.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("VarianceFromSalesTermsAndConditions");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;

	FilterGroup3 = FilterGroup1.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup3.GroupType = DataCompositionFilterItemsGroupType.AndGroup;

	ItemFilter = FilterGroup3.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("SalesInExcessOfOrder");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;

	ItemFilter = FilterGroup3.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("VarianceFromSalesTermsAndConditions");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;

	Item.Appearance.SetParameterValue("ReadOnly", True);
	
	//
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsVATRate.Name);
	
	FilterGroup1 = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup1.GroupType = DataCompositionFilterItemsGroupType.OrGroup;

	FilterGroup2 = FilterGroup1.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup2.GroupType = DataCompositionFilterItemsGroupType.AndGroup;

	ItemFilter = FilterGroup2.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("SalesInExcessOfOrder");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	ItemFilter = FilterGroup2.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.RowCode");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;

	ItemFilter = FilterGroup2.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("VarianceFromSalesTermsAndConditions");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;

	FilterGroup3 = FilterGroup1.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup3.GroupType = DataCompositionFilterItemsGroupType.AndGroup;

	ItemFilter = FilterGroup3.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("SalesInExcessOfOrder");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;

	ItemFilter = FilterGroup3.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("VarianceFromSalesTermsAndConditions");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	Item.Appearance.SetParameterValue("ReadOnly", True);
	
	////

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsPriceKind.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsPercentRateOfManualDiscount.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsManualDiscount.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsPackage.Name);
	
	FilterGroup1 = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup1.GroupType = DataCompositionFilterItemsGroupType.OrGroup;

	FilterGroup2 = FilterGroup1.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup2.GroupType = DataCompositionFilterItemsGroupType.AndGroup;

	ItemFilter =FilterGroup2.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("SalesInExcessOfOrder");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	ItemFilter = FilterGroup2.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.RowCode");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;

	ItemFilter =FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("VarianceFromSalesTermsAndConditions");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	Item.Appearance.SetParameterValue("ReadOnly", False);

	

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsVATRate.Name);
	
	FilterGroup0 = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup0.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
	
	FilterGroup1 = FilterGroup0.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup1.GroupType = DataCompositionFilterItemsGroupType.OrGroup;

	FilterGroup2 = FilterGroup1.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup2.GroupType = DataCompositionFilterItemsGroupType.AndGroup;

	ItemFilter = FilterGroup2.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("SalesInExcessOfOrder");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	ItemFilter = FilterGroup2.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.RowCode");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;

	ItemFilter =FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("VarianceFromSalesTermsAndConditions");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	ItemFilter = FilterGroup0.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.VATTaxation");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotEqual;
	ItemFilter.RightValue = Enums.VATTaxationTypes.ExportSale;
	
	Item.Appearance.SetParameterValue("ReadOnly", False);
	
	
	InstallationParameters = ReusablePackageServer.ParametersForSettingConditionalAppearanceForLinesWithMultiTurnContainers();
	
	InstallationParameters.Form                 = ThisForm;
	InstallationParameters.ThisIsAdmission        = False;
	
	ReusablePackageServer.SetConditionalAppearanceForLinesWithMultiTurnContainers(InstallationParameters);
	
	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsSalesOrder.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.RowCode");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.SalesOrder");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.SalesOrder");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.BusinessOperation");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotEqual;
	ItemFilter.RightValue = Enums.BusinessTransactions.TransferOfTitleToGoods;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.ErrorNoteText);
	Item.Appearance.SetParameterValue("Text", NStr("vi = 'Vượt quá trên đơn hàng, chưa chọn đơn hàng';
													|ru = 'Сверх заказа, заказ не выбран';
													|en = 'In excess of the order, the order is not selected'; fa = 'In excess of the order, the order is not selected';
													|it = 'Oltre all''ordine, l''ordine non è selezionato';
													|pl = 'Przewyższa zamówienie, zamówienie nie wybrane';
													|tr = 'Sipariş fazlası, sipariş seçilmedi'"));

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsSalesOrder.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.RowCode");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.SalesOrder");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.SalesOrder");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.BusinessOperation");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.BusinessTransactions.TransferOfTitleToGoods;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.ErrorNoteText);
	Item.Appearance.SetParameterValue("Text", NStr("vi = 'Vượt quá lệnh, chưa chọn lệnh';
													|ru = 'Сверх распоряжения, распоряжение не выбрано';
													|en = 'In excess of reference. Reference is not selected'; fa = 'In excess of reference. Reference is not selected';
													|it = 'In excess of reference. Reference is not selected';
													|pl = 'In excess of reference. Reference is not selected';
													|tr = 'Sipariş iptal edildi, hiçbir sipariş seçilmedi'"));

	//

	ProductsServer.EstablishConditionalAppearanceOfProductSeries(ThisForm, "SeriesWhenPlanningShipmentWHGoodsAreIndicated");

	//

	ProductsServer.SetConditionalAppearanceOfStatusIndicationSeries(ThisForm, False);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsSalesOrder.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.RowCode");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.SalesOrder");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	
	Item.Appearance.SetParameterValue("ReadOnly", True);
	
	//
	
	SetsServer.SetConditionalAppearance(ThisForm, "Goods");
	
	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.DateOfTransferOfTitleToGoods.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Status");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.StatusesOfCustomerInvoices.Shipped;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.DateOfTransferOfTitleToGoods");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;

	Item.Appearance.SetParameterValue("MarkIncomplete", True);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.DateOfTransferOfTitleToGoods.Name);
	
	FilterGroup1 = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup1.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	
	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Status");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotEqual;
	ItemFilter.RightValue = Enums.StatusesOfCustomerInvoices.Shipped;

	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.DateOfTransferOfTitleToGoods");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;

	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	
	LinesOfBusinessServer.EstablishConditionalAppearanceOfDirectionOfActivity(ThisForm);
	
	RetailSalesLocalization.SetConditionalAppearance(ThisObject);
	
EndProcedure

&AtServer
Procedure FillInVATTaxationATServer()
	
	FillInSalesVATTaxation();
	VATTaxationOnChangeServer();
	
EndProcedure

// Calculates the date of transfer of ownership based on the date of the document and the parameters of the agreement.
//
&AtServer
Procedure CalculateDateOfTransferOfOwnership()
	
	If Object.BusinessOperation = Enums.BusinessTransactions.SaleWithDeferredTransferOfTitle Then
		
		If ValueIsFilled(Object.Terms) Then
			
			If ValueIsFilled(Object.Date) Then
				DateOfShipment = Object.Date;
			Else
				DateOfShipment = CurrentSessionDate();
			EndIf;
			
			DetailsOfAgreement = Common.ObjectAttributesValues(
				Object.Terms,
				"SaleWithDeferredTransferOfTitleIsAllowed,
				|DeadlineOfTransferOfTitleToGoods");
			
			If DetailsOfAgreement.SaleWithDeferredTransferOfTitleIsAllowed
				And ValueIsFilled(DetailsOfAgreement.DeadlineOfTransferOfTitleToGoods) Then
				
				EstimatedDateOfTransferOfOwnership = BegOfDay(DateOfShipment)
					+ DetailsOfAgreement.DeadlineOfTransferOfTitleToGoods * 86400;
				
				If Object.DateOfTransferOfTitleToGoods <> EstimatedDateOfTransferOfOwnership Then
					Object.DateOfTransferOfTitleToGoods = EstimatedDateOfTransferOfOwnership;
				EndIf;
				
			EndIf;
			
		EndIf;
		
	ElsIf ValueIsFilled(Object.DateOfTransferOfTitleToGoods) Then
		Object.DateOfTransferOfTitleToGoods = Date(1, 1, 1);
	EndIf;
	
EndProcedure

#Region OnChangeAttributes

&AtServer
Procedure ProductsCustomerOrderStartSelectionFragment()
	
	UpdateOrderInformation();
	ARAPAccountingFormWork.WhenChangingParametersOfMechanism(ThisObject);
	
EndProcedure

&AtServer
Procedure DateOfTransferOfTitleToGoodsOnChangeServer()
	
	If ValueIsFilled(Object.DateOfTransferOfTitleToGoods) Then
		
		If ToUseTermsOfSales Then
			SalesTermsAndConditions = SalesServer.GetTermsAndConditionsOfSale(Object.Terms, True, True);
		Else
			SalesTermsAndConditions = SalesServer.GetDefaultSalesTerms(
				Object.Partner,
				New Structure("ExcludeWarehouseGroupsAvailableInOrders, SelectedAgreement, BusinessTransactions", 
					True, 
					Object.Terms, 
					PredefinedValue("Enum.BusinessTransactions.SaleToCustomer")));

		EndIf;
		
		Object.ReusablePackagesReturnDate = ReusablePackageServer.CalculateReturnDateOfMultiTurnContainer(
			FormAttributeToValue("Object", Type("DocumentObject.CustomerInvoice")),
			SalesTermsAndConditions.ReusablePackageReturnCycleLength,
			SalesTermsAndConditions.CalculatePackageReturnDateAccordingToCalendar,
			SalesTermsAndConditions.ScheduleOfPackageReturn);
			
	EndIf;
	
	ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisForm,"Date");
	
EndProcedure

&AtServer
Procedure WhenChangingImplementationForMultipleOrders()
	
	If Object.OrderSales Then
		
		If Object.Status = Enums.StatusesOfCustomerInvoices.ForPrepayment Then
			Object.Status = Enums.StatusesOfCustomerInvoices.Shipped;
		EndIf;
		
		If Object.Goods.Count() = 0 Then
			FillInFromOrderServer();
		Else
			BindImplementationStringsToCustomerOrders(Not UseSaleByMultipleOrders);
		EndIf;
		
	Else
		
		UnlinkFromOrderServer(True, False);
		Object.SalesOrder = Documents.SalesOrder.EmptyRef();
		OrderList.Clear();
		
		ReusablePackageServer.UpdateFillingStateOfMultiTurnContainer(Object.ReusablePackageFillingStatus);
		
	EndIf;
	
	UpdateDeliveryPlanningView(ThisObject);
	SetAvailabilityOfItemsByStatusServer();
	UpdateOrderInformation();
	
	SetVisibilityOfElementsByOperationServer();
	SetAvailabilityOfClipboardCommands();
	CalculateTotals_(ThisObject);
	UpdateOrderDeviations();
	UpdateDependentDetailsOfServerByOrderForm();
	EstablishVisibilityOfStatusAndDateOfTransferOfOwnership();
	
	GoodsDelivery.WhenChangingFlagForOrders(Items, Object, Object.OrderSales Or SalesViaCommissionAgent);
	SetAvailabilityVisibilityOfDeliveryItems(ThisObject);
	SetVisibilityOfCommandsByOrder();
	ResponsiblePersonsServer.InstallManager(
		Object, SalesServer.DocumentBasis(Object, "OrderSales, SalesOrder, Goods.SalesOrder"));
	
	ARAPAccountingFormWork.WhenChangingParametersOfMechanism(ThisObject);
	
	AttributesArray = New Array;
	AttributesArray.Add("OrderSales");
	AttributesArray.Add("ARAPObjectSettings");
	ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisObject, AttributesArray);
	LinesOfBusinessServer.SetVisibilityOfElementsSeparately(ThisObject);
	
	StructureBase = Documents.CustomerInvoice.StructureOfBaseForPrinting(Object);
	FillPropertyValues(Object, StructureBase);
	
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	
EndProcedure

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
	
	ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisObject,"Date");
	
	ResponsiblePersonsServer.WhenChangingRelatedDocumentDetails(Object);

	SetOrderSchemeForShipment();
	
	FillSetVisibilityAndReFillAvailabilityByShipment();
	
	SetAvailabilityVisibilityOfBuildAndDeliveryItems();
	
	RetailSalesClientServer.SetAvailabilityOfBonusPointsPaymentTeams(Items, Object.Date);
	
	FormEvents.WhenChangingElement(ThisObject, "Goods");
	WhenChangingElementLocalization(ThisObject, "Date");
	
	If RecalculatePrices_ Then
		CheckCorrectAvailabilityOfDiscountsPaymentsWithBonusPointsLocalization();
	EndIf;
	
	CalculateDateOfTransferOfOwnership();
	
EndProcedure

&AtServer
Procedure WhenChangingPartnerServer()
	
	AttributesArray = New Array;
	
	If ToUseTermsOfSales Then
		FillIn_TermsOfSales();
		AttributesArray.Add("Currency");
		AttributesArray.Add("ARAPCurrency");
		AttributesArray.Add("Contract");
		AttributesArray.Add("LineOfBusiness");
		AttributesArray.Add("Counterparty");
		AttributesArray.Add("Organization");
		AttributesArray.Add("Terms");
	Else
		PartnersAndCounterparties.FillInPartnerSDefaultCounterparty(Object.Partner, Object.Counterparty);
		UseCustomerContracts = GetFunctionalOption("UseCustomerContracts");
		If UseCustomerContracts Then
			FillInDefaultContract();
		EndIf;
	EndIf;
	
	PartnersProductsServer.FillInPartnerProductListByProductNameWhenPartnerChanges(Object.Goods, Object.Partner);
	
	AttributesArray.Add("Partner");
	ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisForm, AttributesArray);
	
	SetAvailabilityOfItemsByStatusServer();
	
	WarehouseGroup_ = ItIsGroupOfWarehousesAndWarehousesUsedByWHForSale(Object.Warehouse);
	WarehouseOnChangeServer();
	FillInServiceDetailsForProductRange();
	
	SalesServer.SetContractAvailability(Object, Items.Contract.Enabled, Items.ContractGroup.Visible, Object.Contract);
	Items.GroupLabelContract.Visible = Items.ContractGroup.Visible;
	
	UpdateTextDocumentsBasedOn();
	
	FillBaseForPrinting();
	If ValueIsFilled(Object.Counterparty)
		And Not Catalogs.CounterpartyBankAccounts.VerifyBankAccountHolder(
			Object.CounterpartyBankAccount, Object.Counterparty) Then
		Object.CounterpartyBankAccount = GetDefaultCounterpartyBankAccountServer(Object.Counterparty,
			Object.CompanyBankAccount);
	EndIf;
	UpdateAvailabilityOfReturnContainerItems(ThisForm);
	
	ResponsiblePersonsServer.WhenChangingRelatedDocumentDetails(Object);
	SalesServer.PartnerOnChange(Object);
	GoodsDelivery.FillInDeliveryDetails(Items, "Partner", Object);
	ResponsiblePersonsServer.FillInManagerSelectionList_(Items.Manager, Object);
	ResponsiblePersonsServer.InstallManager(
		Object, SalesServer.DocumentBasis(Object, "OrderSales, SalesOrder, Goods.SalesOrder"));
	FillInSubordinatePropertiesForStatistics("Counterparty");
	
	ReusablePackageServer.UpdateNoReturnableContainerAttribute(Object.Goods, Object.ToReturnReusablePackage);
	TMCommonUse.FillInDuplicateDependentPropsInCollection(Object.Goods, DependentDetails());
	CalculateTotals_(ThisObject);
	
	SetVisibilityOfShipmentBanToPartner();
	
	If UseLinesOfBusiness Then
		LinesOfBusinessServer.FillInDefaultDirection(Object.LineOfBusiness, Object.Terms, Object.Contract);
	EndIf;
	LinesOfBusinessServer.WhenChangingDirectionOfActivity(ThisObject);
	CustomerInvoiceLocalization.PartnerOnChange(ThisObject);
	GeneratingFiscalChecksServer.FormWhenChangingBankingDetails(ThisObject);
	FormEvents.WhenChangingElement(ThisObject, "Partner");
	WhenChangingElementLocalization(ThisObject,"Counterparty");
	CheckCorrectAvailabilityOfDiscountsPaymentsWithBonusPointsLocalization();
	
	UpdateDeliveryPlanningView(ThisObject);
	
	
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
Procedure OnReadCreateAtServer()
	
	UsePartnersAsCounterparties              = GetFunctionalOption("UsePartnersAsCounterparties");
	UseSalesOrders                        = GetFunctionalOption("UseSalesOrders")
		Or GetFunctionalOption("UseRequestsForReturnOfGoodsFromCustomers");
	SalesInExcessOfOrder                             = UserRightsCached.SalesInExcessOfOrder();
	UseSaleByMultipleOrders         = GetFunctionalOption("UseSaleByMultipleOrders");
	UseStatusesOfGoodsServicesSales         = GetFunctionalOption("UseStatusesOfGoodsServicesSales");
	
	UseShipmentWithDeferredTransferOfTitle2_0 =
		GetFunctionalOption("UseShipmentWithDeferredTransferOfTitle2_0");
	
	UseShipmentWithDeferredTransferOfTitle2_5 =
		GetFunctionalOption("UseShipmentWithDeferredTransferOfTitle2_5");
	
	ToUseTermsOfSales                  = GetFunctionalOption("ToUseTermsOfSales");
	UsePaymentSchedules                         = GetFunctionalOption("UsePaymentSchedules");
	UseMultipleCompanies                  = GetFunctionalOption("UseMultipleCompanies");
	UseSeveralWarehouses                      = GetFunctionalOption("UseSeveralWarehouses");
	UseLinesOfBusiness               = GetFunctionalOption("UseIncomeAccountingByLinesOfBusiness");
	UseBusinessUnits                         = GetFunctionalOption("UseBusinessUnits");
	UseWarehousesInTabularSectionsOfSalesDocuments = GetFunctionalOption("UseWarehousesInTabularSectionsOfSalesDocuments");
	SalesViaCommissionAgent                       = ConsignmentSalesServer.SalesViaCommissionAgent(Object.BusinessOperation);
	UseEDO                                   = GetFunctionalOption("UseElectronicDocumentExchangeWithCounterparties");

	UseLoyaltyPrograms = UseLoyaltyPrograms(Object.LoyaltyCard);
	SetVisibilityOfElementsOfLoyaltyBonusProgram();
	
	UseLinesOfBusiness = UseLinesOfBusiness And Not SalesViaCommissionAgent;
	
	ThereIsSpendingOrderForShippingOrders(Object.Ref, ShipmentStarted);
	
	FillOperationSelectionList(False);
	ContractBusinessTransaction = GetBusinessTransaction(Object.BusinessOperation);
	
	ResponsiblePersonsServer.FillInManagerSelectionList_(Items.Manager, Object);
	
	DocumentCurrency = Object.Currency;
	LocalAccountingCurrency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Object.Organization);
	ManagementAccountingCurrency = Constants.ManagementAccountingCurrency.Get();
	
	WarehouseGroup_ = ItIsGroupOfWarehousesAndWarehousesUsedByWHForSale(Object.Warehouse);
	Warehouse = Object.Warehouse;
	
	Contract = Object.Contract;
	
	SetParametersForSelectingProductsWarehouse();
	
	EstablishRelationshipsBetweenContractSelectionParameters();
	EstablishLinksBetweenParametersForSelectingTypeOfPrice();
	
	Terms = Object.Terms;
	
	Items.GoodsFillInTheWarehouseInSelectedLines.Enabled = WarehouseGroup_;
	Items.GroupDiscrepancyOnOrder.Visible = False;
	Items.GroupDiscrepancyOnOrders.Visible = False;
	Items.GroupLabelAndPictureSeveralWarehouses.Visible = WarehouseGroup_;
	
	SeriesSpecificationParameters = New FixedStructure(ProductsServer.SeriesSpecificationParameters(Object, Documents.CustomerInvoice));
	SetVisibilityOfSeriesElements();
	
	If Not ToUseTermsOfSales Then
		PriceTypeSelectionParameters = SettingsValueCached.ParametersForSelectingDefaultPriceType();
	
		PriceTypeSelectionParameters.PriceIncludesVAT        = Object.PriceIncludesVAT;
		PriceTypeSelectionParameters.UseWhileSellingToCustomers = True;
		PriceTypeSelectionParameters.Status                 = Enums.StatusesOfPriceTypeValidity.Valid;
		
		DefaultPriceType = SettingsValueCached.DefaultPriceType(PriceTypeSelectionParameters);
	EndIf;
	
	SetVisibilityOfElementsByOperationServer();
	
	FillInPriceTypeUnderAgreement();
	FillInServiceDetailsForProductRange();
	UpdateOrderInformation();
	UpdateOrderDeviations();

	Items.CloseOrder.Visible = UseAdvancedFeaturesOfSalesOrder;

	LinesOfBusinessServer.OnReadCreateAtServer(ThisObject);
	
	WhenChangingWarehouseInTablePartServer();
	SetHeadingsForBusinessOfOperation();
	SetAvailabilityOfItemsByStatusServer();
	EstablishVisibilityOfStatusAndDateOfTransferOfOwnership();

	SalesServer.SetContractAvailability(Object, Items.Contract.Enabled, Items.ContractGroup.Visible);
	Items.GroupLabelContract.Visible = Items.ContractGroup.Visible;
	
	Items.CompanyGroup.Visible = UseMultipleCompanies;
	Items.WarehouseGroup_.Visible = UseSeveralWarehouses;
	Items.CounterpartyGroup.Visible = Not UsePartnersAsCounterparties;
	Items.GroupEndCustomerCounterparty.Visible = Not UsePartnersAsCounterparties;
	
	UpdateTextDocumentsBasedOn();
	
	BasisChanged = False;
	
	RightToChangeInvoice = AccessRight("Update", Metadata.Documents.CustomerInvoice);
	Items.GoodsSelectGoodsByOrdersNotes.Enabled = RightToChangeInvoice;
	
	If RightToChangeInvoice Then
		PrintBasisTable.Load(Documents.CustomerInvoice.PrintBasisTable(Object));
		If ValueIsFilled(Object.Basis) Then
			BaseStructure = Documents.CustomerInvoice.StructureOfBaseForPrinting(Object);
			BasisChanged = (TrimAll(Object.Basis) <> BaseStructure.Basis) 
				Or (TrimAll(Object.BaseDocumentNumber) <> BaseStructure.BaseDocumentNumber)
				Or (Object.ReferenceDocumentDateForPrintForms <> BaseStructure.ReferenceDocumentDateForPrintForms);
		EndIf;
	EndIf;
	
	ReusablePackageServer.UpdateNoReturnableContainerAttribute(Object.Goods, Object.ToReturnReusablePackage);
	
	Items.TareGroup.Visible = Not UseShipmentWithDeferredTransferOfTitle2_5;
	Items.GroupRequiresADepositForPackaging.Visible = Not UseShipmentWithDeferredTransferOfTitle2_5;
	
	TMCommonUse.FillInDuplicateDependentPropsInCollection(Object.Goods, DependentDetails());
	CalculateTotals_(ThisObject);
	
	ARAPAccountingFormWork.FormWhenReadingOnServer(ThisForm);
	
	UpdateAvailabilityOfReturnContainerItems(ThisForm);
	
	If Not UseSalesOrders Then
		Items.GroupDiscrepancyOnOrder.Visible = False;
		Items.GroupDiscrepancyOnOrders.Visible = False;
	EndIf;
	
	TMCommonUseClientServer.SetFormItemProperty(Items, "GoodsGroupSalesOrder", "Visible", Object.OrderSales);
	SetVisibilityOfShipmentBanToPartner();
	
	CurrentDeliveryMethod = Object.DeliveryMethod;
	
	DocumentDateBeforeChange = Object.Date;
	
	ChangeHeadingsForSalesLayoutOption();
	ProcessingOfTabularForms.InitializeRowCache(Items.Goods);
	SetVisibilityOfCommandsByOrder();

	UseLabeling = GetFOMarkingValues();	
	If (Not UseEDO) Or (Not UseLabeling) Then 
		Items.GroupOptionForDisposalOfMarkedProducts.Visible = False;
	EndIf;
	
	FillParameters = Documents.CustomerInvoice.ParametersForFillingInSalesVATTaxation(Object);
	VATAccountingERP.FillInSalesVATTaxSelectionList(Items.VATTaxation, Object.VATTaxation, FillParameters, VATAccountingCachedParameterValues);
	UpdateVHFWarehouseObligation();
	
	If Object.OrderSales Then
		FillInDataForCalculatingPaymentWithBonusPoints();
	Else
		PaymentWithBonusPoints = Object.Goods.Total("AmountOfBonusPointsToDeduction") <> 0 
							Or Object.Goods.Total("AmountOfBonusPointsToDeductionInCurrency") <> 0;
	EndIf;
	
	DocumentDate = ?(Parameters.Key.IsEmpty(), CurrentSessionDate(), Object.Date);
	RetailSalesClientServer.SetAvailabilityOfBonusPointsPaymentTeams(Items, DocumentDate);
	
	PurchasesServer.FillInSelectionListNameOfIncomingDocument(ThisObject, Object.Counterparty, "ConsigneeDocumentName");
	
EndProcedure

&AtServer
Procedure StatusOnChangeServer()
	
	SeriesSpecificationParameters = New FixedStructure(ProductsServer.SeriesSpecificationParameters(Object, Documents.CustomerInvoice));
	SetVisibilityOfSeriesElements();
	ProductsServer.FillInStatusesForSpecifyingSeries(Object,SeriesSpecificationParameters);
	If (Object.BusinessOperation = Enums.BusinessTransactions.SaleWithDeferredTransferOfTitle 
			Or Object.BusinessOperation = Enums.BusinessTransactions.SalesViaCommissionAgentGoodsInTransit)
		And Object.Status = Enums.StatusesOfCustomerInvoices.ForPrepayment Then
		Object.DateOfTransferOfTitleToGoods = Date('00010101');
	EndIf;
	
	EstablishVisibilityOfStatusAndDateOfTransferOfOwnership();
	UpdateTextDocumentsBasedOn();
	
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	
EndProcedure

&AtServer
Procedure TermsOnChangeServer()
	
	BusinessTransaction = Object.BusinessOperation;
	
	DocumentSales = FormAttributeToValue("Object");
	DocumentSales.FillInTermsOfSalesUnderAgreement();
	ResponsiblePersonsServer.FillInManagerSelectionList_(Items.Manager, Object);
	ResponsiblePersonsServer.InstallManager(DocumentSales,
		SalesServer.DocumentBasis(DocumentSales, "OrderSales, SalesOrder, Goods.SalesOrder"));
	ValueToFormAttribute(DocumentSales, "Object");
	
	FillOperationSelectionList();
	DocumentCurrency = Object.Currency;
	
	If BusinessTransaction = Enums.BusinessTransactions.SaleToCustomerLocalAccounting Then
		Object.BusinessOperation = BusinessTransaction;
	EndIf;
	
	WarehouseGroup_ = ItIsGroupOfWarehousesAndWarehousesUsedByWHForSale(Object.Warehouse);
	
	WarehouseOnChangeServer();
	BusinessOperationOnChangeServer();
	SetAvailabilityOfItemsByStatusServer();
	
	UpdateTextDocumentsBasedOn();
	
	FillInServiceDetailsForProductRange();
	
	SalesServer.SetContractAvailability(Object, Items.Contract.Enabled, Items.ContractGroup.Visible, Object.Contract);
	Items.GroupLabelContract.Visible = Items.ContractGroup.Visible;
	
	If Object.OrderSales Then
		UpdateOrderDeviations();
	EndIf;
	
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
	
	If ValueIsFilled(Object.Counterparty)
		And Not Catalogs.CounterpartyBankAccounts.VerifyBankAccountHolder(
			Object.CounterpartyBankAccount, Object.Counterparty) Then
		Object.CounterpartyBankAccount = GetDefaultCounterpartyBankAccountServer(Object.Counterparty,
			Object.CompanyBankAccount);
	EndIf;
	UpdateAvailabilityOfReturnContainerItems(ThisForm);
	ResponsiblePersonsServer.WhenChangingRelatedDocumentDetails(Object);
	
	FillInSubordinatePropertiesForStatistics("Contract");
	
	ReusablePackageServer.UpdateNoReturnableContainerAttribute(Object.Goods, Object.ToReturnReusablePackage);
	TMCommonUse.FillInDuplicateDependentPropsInCollection(Object.Goods, DependentDetails());
	CalculateTotals_(ThisObject);
	
	
	CheckCorrectAvailabilityOfDiscountsPaymentsWithBonusPointsLocalization();
	
	If UseLinesOfBusiness Then
		LinesOfBusinessServer.FillInDefaultDirection(Object.LineOfBusiness, Object.Terms, Object.Contract);
	EndIf;
	LinesOfBusinessServer.WhenChangingDirectionOfActivity(ThisObject);
	
	SetAvailabilityVisibilityOfBuildAndDeliveryItems();
	
	FillBaseForPrinting();
	
	UpdateDeliveryPlanningView(ThisObject);
	
EndProcedure

&AtServer
Procedure TermsClearingServer()
	
	ResponsiblePersonsServer.FillInManagerSelectionList_(Items.Manager, Object);
	ResponsiblePersonsServer.InstallManager(
		Object, SalesServer.DocumentBasis(Object, "OrderSales, SalesOrder, Goods.SalesOrder"));
	
	UpdateDeliveryPlanningView(ThisObject);
	
EndProcedure

&AtServer
Procedure DocumentAmountOnChangeServer(DocumentAmount)
	
	RecalculationParameters = PriceManagementSystem.ParametersForRecalculationOfTableAmountsONChangeOfExchangeRate(Object.PriceIncludesVAT, DocumentAmount);
	RecalculationParameters.RecalculateAutomaticDiscounts = True;
	RecalculationParameters.RecalculateManualDiscounts         = True;
	
	PriceManagementSystem.RecalculateTableAmountsONChangeOfExchangeRate(
		Object.Goods,
		RecalculationParameters);
	
	If Object.BusinessOperation = Enums.BusinessTransactions.SaleToCustomerLocalAccounting Then
		ARAPAccountingARAPDetailsFillingIn.ConvertAmountsToCurrencyPaymentDecryption(
			Object,
			?(Object.PackageDepositIsRequired,
				Object.Goods.Total("AmountIncludingVAT"),
				Object.Goods.Total("AmountIncludingVATWithoutReusablePackages")));
	EndIf;
	
	If Not Object.OrderSales And Not ValueIsFilled(Object.Terms) Then
		Object.ARAPCurrency = Object.Currency;
	EndIf;
	
	ParametersForFillingInVATAmountLocalManSManSManSManSManSManSManSManS = BatchProcessingOfTablePartClientServer.ParametersForFillingInVATAmountLocalManSManSManSManSManSManSManSManS(
		Object.Currency,
		LocalAccountingCurrency,
		ManagementAccountingCurrency);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("ClearAmountOfSettlements");
	StructureOfActions.Insert("SetVATAmountLocalMans", ParametersForFillingInVATAmountLocalManSManSManSManSManSManSManSManS);
	BatchProcessingOfTablePartServer.TreatTS(Object.Goods, StructureOfActions, Undefined);
	
	TMCommonUse.FillInDuplicateDependentPropsInCollection(Object.Goods, DependentDetails());
	CalculateTotals_(ThisObject);
	
EndProcedure

&AtServer
Procedure BusinessOperationOnChangeServer()
	
	SalesViaCommissionAgent = ConsignmentSalesServer.SalesViaCommissionAgent(Object.BusinessOperation);
	UseLinesOfBusiness = UseLinesOfBusiness And Not SalesViaCommissionAgent;
	
	EstablishRelationshipsBetweenContractSelectionParameters();
	EstablishLinksBetweenParametersForSelectingTypeOfPrice();
	
	ContractBusinessTransaction = GetBusinessTransaction(Object.BusinessOperation);
	
	FillInDefaultContract();
	FillInDefaultEndClientContract();
	
	SetHeadingsForBusinessOfOperation();
	
	If Object.BusinessOperation <> Enums.BusinessTransactions.TransferOfTitleToGoods Then
		
		If TypeOf(Object.SalesOrder) = Type("DocumentRef.SourceDocument")
			Or TypeOf(Object.SalesOrder) = Type("DocumentRef.GoodsShipmentToCustomer") Then
			Object.SalesOrder = Undefined;
			Object.OrderSales = False;
		EndIf;
		
		ClearedOrderInAllLines = True;
		For Each TSRow In Object.Goods Do
			
			If TypeOf(TSRow.SalesOrder) = Type("DocumentRef.SourceDocument")
				Or TypeOf(TSRow.SalesOrder) = Type("DocumentRef.GoodsShipmentToCustomer") Then
				TSRow.SalesOrder = Undefined;
			Else
				ClearedOrderInAllLines = False;
			EndIf;
			
		EndDo;
		
		If ClearedOrderInAllLines And Object.Goods.Count() > 0 Then
			Object.OrderSales = False;
		EndIf;
		
	EndIf;
	
	AttributesArray = New Array;
	
	If Object.BusinessOperation = Enums.BusinessTransactions.TransferToCommissionAgent Then
		
		DiscountsMarkupsFillingServer.CancelDiscounts(Object, "Goods", True, True);
		DiscountsMarkupsFillingServer.ConfigureShowMessagesCommand(Object, Items.ShowMessages, False);
		
		If Object.Status = Enums.StatusesOfCustomerInvoices.ForPrepayment
			Or Object.Status = Enums.StatusesOfCustomerInvoices.InTransit Then
			Object.Status = Enums.StatusesOfCustomerInvoices.Shipped;
		EndIf;
		
		If Object.PackageDepositIsRequired Then
			Object.PackageDepositIsRequired = False;
		EndIf;
		
		Object.ARAPCurrency = Object.Currency;
		
		Object.DateOfTransferOfTitleToGoods = Date('00010101');
		
		AttributesArray.Add("ARAPCurrency");
		
	ElsIf Object.BusinessOperation = Enums.BusinessTransactions.SaleToCustomerLocalAccounting Then
		
		Object.ToReturnReusablePackage = False;
		ToReturnReusablePackageOnChangeServer();
		Object.DateOfTransferOfTitleToGoods = Date('00010101');
		
		Object.OrderSales = False;
		WhenChangingImplementationForMultipleOrders();
		LinesOfBusinessServer.WhenChangingDirectionOfActivity(ThisObject);
		
	ElsIf Object.BusinessOperation = Enums.BusinessTransactions.SaleToCustomer Then
		
		If Object.Status = Enums.StatusesOfCustomerInvoices.InTransit Then
			Object.Status = Enums.StatusesOfCustomerInvoices.Shipped;
		EndIf;
		
		Object.DateOfTransferOfTitleToGoods = Date('00010101');
		
	ElsIf Object.BusinessOperation = Enums.BusinessTransactions.SaleWithDeferredTransferOfTitle Then
		
		If Object.Status = Enums.StatusesOfCustomerInvoices.Shipped Then
			Object.Status = Enums.StatusesOfCustomerInvoices.InTransit;
		EndIf;
		
	ElsIf Object.BusinessOperation = Enums.BusinessTransactions.SalesViaCommissionAgent Then
		
		DiscountsMarkupsFillingServer.CancelDiscounts(Object, "Goods", True, True);
		DiscountsMarkupsFillingServer.ConfigureShowMessagesCommand(Object, Items.ShowMessages, False);
		
		Object.Status = Enums.StatusesOfCustomerInvoices.Shipped;
		
		If Object.PackageDepositIsRequired Then
			Object.PackageDepositIsRequired = False;
		EndIf;
		
		Object.ARAPCurrency = Object.Currency;
		
		Object.DateOfTransferOfTitleToGoods = Date('00010101');
		
		Object.Warehouse = Catalogs.Warehouses.EmptyRef();
		
	ElsIf Object.BusinessOperation = Enums.BusinessTransactions.SalesViaCommissionAgentGoodsInTransit Then
		
		DiscountsMarkupsFillingServer.CancelDiscounts(Object, "Goods", True, True);
		DiscountsMarkupsFillingServer.ConfigureShowMessagesCommand(Object, Items.ShowMessages, False);
		
		If Object.Status = Enums.StatusesOfCustomerInvoices.Shipped 
			Or Object.Status = Enums.StatusesOfCustomerInvoices.ForPrepayment Then
			Object.Status = Enums.StatusesOfCustomerInvoices.InTransit;
		EndIf;
		
		If Object.PackageDepositIsRequired Then
			Object.PackageDepositIsRequired = False;
		EndIf;
		
		Object.ARAPCurrency = Object.Currency;
		
		Object.Warehouse = Catalogs.Warehouses.EmptyRef();
	
	ElsIf Object.BusinessOperation =
		Enums.BusinessTransactions.TransferOfTitleToGoods Then 
		
		Object.ARAPCurrency = Object.Currency;
		Object.Status = Enums.StatusesOfCustomerInvoices.Shipped;
		Object.Warehouse = Catalogs.Warehouses.EmptyRef();
		Object.DateOfTransferOfTitleToGoods = Date('00010101');
		
	EndIf;
	
	CalculateDateOfTransferOfOwnership();
	
	FillInSalesVATTaxation();
	VATTaxationOnChangeServer();
	
	SetOrderSchemeForShipment();
	ReusablePackageServer.UpdateNoReturnableContainerAttribute(Object.Goods, Object.ToReturnReusablePackage);
	TMCommonUse.FillInDuplicateDependentPropsInCollection(Object.Goods, DependentDetails());
	CalculateTotals_(ThisObject);
	SetVisibilityOfElementsByOperationServer();
	EstablishVisibilityOfStatusAndDateOfTransferOfOwnership();
	
	SeriesSpecificationParameters = New FixedStructure(ProductsServer.SeriesSpecificationParameters(Object, Documents.CustomerInvoice));
	SetVisibilityOfSeriesElements();
	ProductsServer.FillInStatusesForSpecifyingSeries(Object,SeriesSpecificationParameters);
	
	UpdateTextDocumentsBasedOn();
	
	TMCommonUseClientServer.SetFormItemProperty(
		Items,
		"ToReturnReusablePackage",
		"ReadOnly",
		Object.BusinessOperation = Enums.BusinessTransactions.SaleToCustomerLocalAccounting);
		
	UpdateAvailabilityOfReturnContainerItems(ThisForm);
	FillSetVisibilityAndReFillAvailabilityByShipment();
	
	ARAPAccountingFormWork.WhenChangingParametersOfMechanism(ThisForm);
	
	GeneratingFiscalChecksServer.FormWhenChangingBankingDetails(ThisObject);
	
	FormEvents.WhenChangingElement(ThisObject, "BusinessOperation");
	
	DeliveryIsApplicable = GoodsDeliveryClientServer.BusinessTransactionIsInvolvedInDelivery(Object.BusinessOperation);
	If Not DeliveryIsApplicable
		Or Object.Organization = Catalogs.Companies.ManagementCompany Then
		Object.DeliveryIsRequired = False;
	EndIf;
	SetAvailabilityVisibilityOfDeliveryItems(ThisObject);
	
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	
EndProcedure

&AtServer
Procedure VATTaxationOnChangeServer()
	
	If Object.OrderSales
		And Object.BusinessOperation = Enums.BusinessTransactions.TransferOfTitleToGoods Then
		Return;
	EndIf;
	
	CachedValuesInternal = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInVATRateByPriceType", BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRateByPriceType(Object));
	StructureOfActions.Insert("AdjustVATRate", 
			BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRate(Object, False, Object.ToReturnReusablePackage));
	
	BatchProcessingOfTablePartServer.TreatTS(Object.Goods, StructureOfActions, CachedValuesInternal);
	
	ParametersForFillingInVATAmountLocalManSManSManSManSManSManSManSManS = BatchProcessingOfTablePartClientServer.ParametersForFillingInVATAmountLocalManSManSManSManSManSManSManSManS(
		Object.Currency,
		LocalAccountingCurrency,
		ManagementAccountingCurrency);
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForRecalculatingNDSWTCHAmount(Object);
	
	StructureOfActions = New Structure;
	
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("ClearAmountOfSettlements");
	StructureOfActions.Insert("SetVATAmountLocalMans", ParametersForFillingInVATAmountLocalManSManSManSManSManSManSManSManS);
	
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		CachedValuesInternal.ProcessedRows,
		StructureOfActions,
		Object.Goods,
		Undefined);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInHSCode", Object.VATTaxation);
	BatchProcessingOfTablePartServer.TreatTS(Object.Goods, StructureOfActions, Undefined);
	
	TMCommonUse.FillInDuplicateDependentPropsInCollection(Object.Goods, DependentDetails());
	
	CalculateTotals_(ThisObject);

	VATAccountingERP.SetVisibilityOfCommandAndFillInVATRate(ThisObject);
	VATAccountingERP.EstablishVisibilityOfCountryOfImplementation(ThisObject);

EndProcedure

&AtServer
Procedure PriceIncludesVATOnChangeServer(CachedValues)
	
	ParametersForFillingInVATAmountLocalManSManSManSManSManSManSManSManS = BatchProcessingOfTablePartClientServer.ParametersForFillingInVATAmountLocalManSManSManSManSManSManSManSManS(
		Object.Currency,
		LocalAccountingCurrency,
		ManagementAccountingCurrency);
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForRecalculatingNDSWTCHAmount(Object);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("ClearAmountOfSettlements");
	StructureOfActions.Insert("SetVATAmountLocalMans", ParametersForFillingInVATAmountLocalManSManSManSManSManSManSManSManS);
	BatchProcessingOfTablePartServer.TreatTS(Object.Goods, StructureOfActions, CachedValues);
	
	TMCommonUse.FillInDuplicateDependentPropsInCollection(Object.Goods, DependentDetails());
	CalculateTotals_(ThisObject);
	
	If Not ToUseTermsOfSales Then
		PriceTypeSelectionParameters = SettingsValueCached.ParametersForSelectingDefaultPriceType();
	
		PriceTypeSelectionParameters.PriceIncludesVAT        = Object.PriceIncludesVAT;
		PriceTypeSelectionParameters.UseWhileSellingToCustomers = True;
		PriceTypeSelectionParameters.Status                 = Enums.StatusesOfPriceTypeValidity.Valid;
		
		DefaultPriceType = SettingsValueCached.DefaultPriceType(PriceTypeSelectionParameters);
	EndIf;
	
EndProcedure

&AtServer
Procedure WarehouseOnChangeServer(ClearLines_ = True, UntieAllLinesFromOrder = False)
	
	WarehouseGroup_ = ItIsGroupOfWarehousesAndWarehousesUsedByWHForSale(Object.Warehouse);
	Warehouse = Object.Warehouse;
	
	SetParametersForSelectingProductsWarehouse();
	
	StructureOfResponsible = SalesServer.GetWarehouseManager(Object.Warehouse);
	If StructureOfResponsible <> Undefined Then
		Object.IssuiedBy = StructureOfResponsible.EmployeeResponsible;
		Object.IssuiedByJobTitle = StructureOfResponsible.ResponsiblePosition;
	EndIf;
	
	If Object.OrderSales And Not WarehouseGroup_ And Object.Goods.Count() > 0 And ClearLines_ Then
		Object.Goods.Clear();
	EndIf;
	
	If UntieAllLinesFromOrder Then
		UnlinkFromOrderServer();
	EndIf;
	
	Items.GoodsFillInTheWarehouseInSelectedLines.Enabled = WarehouseGroup_;
	WarehousesServer.FillInWarehousesInTablePart(Object.Warehouse, WarehouseGroup_, Object.Goods, True);
	
	WhenChangingWarehouseInTablePartServer();

	UpdateOrderInformation();
	CalculateTotals_(ThisObject);
	ARAPAccountingClientServer.UpdateHyperlinkText(ThisObject);

	FillSetVisibilityAndReFillAvailabilityByShipment();
	
	FillInSalesVATTaxation();
	VATTaxationOnChangeServer();

	SetHeadingProductsSenderGroup();

	SetTitleFillInByOrdersOrders();
	Items.GroupLabelAndPictureSeveralWarehouses.Visible = WarehouseGroup_;
	
	SetAvailabilityVisibilityOfBuildAndDeliveryItems();
	
EndProcedure

&AtServer
Procedure OrganizationOnChangeServer()
	
	SalesServer.SetContractAvailability(Object, Items.Contract.Enabled, Items.ContractGroup.Visible, Object.Contract);
	Items.GroupLabelContract.Visible = Items.ContractGroup.Visible;
	
	LocalAccountingCurrency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Object.Organization);
	
	If ValueIsFilled(Object.Organization) Then
		
		FillInDefaultContract();
		FillInDefaultEndClientContract();
		
		If UseLinesOfBusiness Then
			LinesOfBusinessServer.FillInDefaultDirection(Object.LineOfBusiness, Object.Terms, Object.Contract);
		EndIf;
	
		UpdateTextDocumentsBasedOn();
		
		FillInSalesVATTaxation();
		VATTaxationOnChangeServer();
		
	EndIf;
	
	CashServer.CheckFillInOrganizationSBankAccountByOwner(Object.Organization,
		Object.CompanyBankAccount, , Object.LineOfBusiness, Object.ForeignCurrencyTransaction);
	CashServer.CheckOrganizationSSalesRegisterByOwner(Object.Organization, Object.CashAccount, Object.PaymentMethod, Object.LineOfBusiness);
	
	FillInSubordinatePropertiesForStatistics("Organization");
	ResponsiblePersonsServer.InstallManager(
		Object, SalesServer.DocumentBasis(Object, "OrderSales, SalesOrder, Goods.SalesOrder"));
	
	ResponsiblePersonsServer.WhenChangingRelatedDocumentDetails(Object);
	LinesOfBusinessServer.WhenChangingDirectionOfActivity(ThisObject);
	ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisForm, "Organization");
	
	WhenChangingKeyDetailsStatusOfEDO();
	
	If Object.Organization = Catalogs.Companies.ManagementCompany Then
		Object.DeliveryIsRequired = False;
	EndIf;
	SetAvailabilityVisibilityOfDeliveryItems(ThisObject);
	

	
EndProcedure

&AtServer
Procedure CounterpartyOnChangeServer()
	
	SalesServer.SetContractAvailability(Object, Items.Contract.Enabled, Items.ContractGroup.Visible, Object.Contract);
	Items.GroupLabelContract.Visible = Items.ContractGroup.Visible;
	
	If ValueIsFilled(Object.Counterparty) Then
		FillInDefaultContract();
		SalesServer.PartnerOnChange(Object);
	EndIf;
	
	If UseLinesOfBusiness Then
		LinesOfBusinessServer.FillInDefaultDirection(Object.LineOfBusiness, Object.Terms, Object.Contract);
	EndIf;
	
	FillInSubordinatePropertiesForStatistics("Counterparty");
	LinesOfBusinessServer.WhenChangingDirectionOfActivity(ThisObject);
	ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisObject, "Counterparty");
	
	GoodsDelivery.FillInDeliveryDetails(Items, "Partner", Object);
	
	WhenChangingKeyDetailsStatusOfEDO();
	
	UpdateTextDocumentsBasedOn();
	CustomerInvoiceLocalization.CounterpartyOnChange(ThisObject);
	FormEvents.WhenChangingElement(ThisObject, "Counterparty");
	WhenChangingElementLocalization(ThisObject, "Counterparty");
	
	CheckCorrectAvailabilityOfDiscountsPaymentsWithBonusPointsLocalization();
	GeneratingFiscalChecksServer.FormWhenChangingBankingDetails(ThisObject);
	
	PurchasesServer.FillInSelectionListNameOfIncomingDocument(ThisObject, Object.Counterparty, "ConsigneeDocumentName");
	
	
EndProcedure

&AtServer
Procedure ContractOnChangeServer()
	
	Contract = Object.Contract;
	
	ForeignCurrencyTransaction = Object.ForeignCurrencyTransaction;
	ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisObject, "Contract");
	ResponsiblePersonsServer.FillInManagerSelectionList_(Items.Manager, Object);
	ResponsiblePersonsServer.InstallManager(
		Object, SalesServer.DocumentBasis(Object, "OrderSales, SalesOrder, Goods.SalesOrder"));
	
	If Object.ForeignCurrencyTransaction <> ForeignCurrencyTransaction Then
		Object.CompanyBankAccount = Catalogs.CompaniesBankAccounts.EmptyRef();
	EndIf;
	
	SalesServer.FillInBankAccountsUnderAgreement(Object.Contract, Object.CompanyBankAccount,
		Object.CounterpartyBankAccount);
	
	Object.CompanyBankAccount = GetOrganizationSDefaultBankAccountServer();
	
	FillInSubordinatePropertiesForStatistics("Contract");
	
	If UseLinesOfBusiness Then
		LinesOfBusinessServer.FillInDefaultDirection(Object.LineOfBusiness, Object.Terms, Object.Contract);
	EndIf;
	LinesOfBusinessServer.WhenChangingDirectionOfActivity(ThisObject);
	
	FillInDefaultEndClientContract();
	
	FillInSalesVATTaxation();
	VATTaxationOnChangeServer();
	FillBaseForPrinting();
	FillInPriceTypeUnderAgreement();
	Object.MarkedProductOutflowOption = Common.ObjectAttributeValue(Object.Contract, "MarkedProductOutflowOption");
	
	SetAvailabilityVisibilityOfBuildAndDeliveryItems();
	
	SetVisibilityOfCommandToFillInContractPriceView();
	CheckCorrectAvailabilityOfDiscountsPaymentsWithBonusPointsLocalization();
	
	ARAPAccountingFormWork.WhenChangingParametersOfMechanism(ThisObject);

	
	WhenChangingKeyDetailsStatusOfEDO();
	
EndProcedure


&AtServer
Procedure GoodsAfterDeleteRowServer(SeriesStatusesNeedToBeUpdated, CachedValues)
	
	If SeriesStatusesNeedToBeUpdated Then
		FillInStatusesOfSpecifyingSeriesWhenEditingLineTS(Undefined, CachedValues);
	EndIf;

	If Object.ReusablePackageFillingStatus = Enums.ReusablePackageFillingStates.FilledIn Then
		Object.ReusablePackageFillingStatus = Enums.ReusablePackageFillingStates.OfferToFillIn;
	EndIf;
	
	UpdateOrderInformation();
	
	ARAPAccountingFormWork.WhenChangingParametersOfMechanism(ThisObject);
	
	WhenChangingWarehouseInTablePartServer();
	
	FormEvents.WhenChangingElement(ThisObject, "Goods");
	
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
	BatchProcessingOfTablePartClientServerLocalization.CompleteActionStructureWhenChangingElement(ThisObject, "Products", ParametersForFillingInBankingDetails);
	AccountingForTraceableGoodsClientServerLocalization.CompleteDescriptionOfSettingsForFillingInServiceDetailsOfTablePart(ParametersForFillingInBankingDetails);

	ProductsServer.FillInServiceDetailsForProductInCollection(Object.Goods,ParametersForFillingInBankingDetails);
	
	SetsServer.FillInServiceDetails(ThisForm);
	
EndProcedure

&AtServerNoContext
Procedure ThereIsSpendingOrderForShippingOrders(Ref, ShipmentStarted)
	
	ShipmentStarted = InvoicesServer.ThereIsSpendingOrderForShippingOrders(Ref);
	
EndProcedure

&AtServer
Procedure LineOfBusinessOnChangeServer()
	
	If Object.ARAPObjectSettings = Enums.ARAPObjectSettings.ByCounterpartyContracts
		And Not ValueIsFilled(Object.Contract) Then
		FillInDefaultContract();
	EndIf;
	
	FillInSalesVATTaxation();
	VATTaxationOnChangeServer();
	
	LinesOfBusinessServer.WhenChangingDirectionOfActivity(ThisObject);
	ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);
	ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisForm, "LineOfBusiness");
	
EndProcedure

&AtServer
Procedure OrderSalesOnChangeServer()
	
	WhenChangingImplementationForMultipleOrders();
	LinesOfBusinessServer.WhenChangingDirectionOfActivity(ThisObject);
	
EndProcedure

&AtServer
Procedure UpdateTextDocumentsBasedOn()
	
	TextsFieldsDocumentsBasedOn.Clear();
	
	UpdateTextOfInvoiceIssued();
	UpdateTextDocumentsBasedOnLocalization();
	TMCommonUseClientServer.UpdateTextDocumentsBasedOn(ThisObject);
	
EndProcedure

&AtServer
Procedure CourierForChangesOnServer()
	
	CashServer.CheckOrganizationSSalesRegisterByOwner(Object.Organization, Object.CashAccount, Object.PaymentMethod, Object.LineOfBusiness, Object.Courier);
	
EndProcedure

&AtServer
Procedure ClientPartnerWhenChangesAreMadeOnServer();
	
	PartnersAndCounterparties.FillInPartnerSDefaultCounterparty(Object.CustomerPartner, Object.CustomerCounterparty);
	
EndProcedure

&AtServer
Procedure ClientCounterpartyWhenChangingOnServer()
	
	FillInDefaultEndClientContract();
	
EndProcedure

&AtServer
Procedure ClientAgreesOnChangeOnServer()
	
	If ValueIsFilled(Object.CustomerContract) Then
		Object.ARAPCurrency = Common.ObjectAttributeValue(Object.CustomerContract, "ARAPCurrency");
	EndIf;
	ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisForm, "CustomerContract, ARAPCurrency");
	
EndProcedure

&AtServer
Procedure CheckQuantityInTheDocumentCompletionServer(ReturnParameters, Val ReCachedValues)
	
	ApplyPaymentWithBonusPoints(, True);
	ChangeTablePartBasedOnResultsOfCheck(ReturnParameters, ReCachedValues);
	CalculateTotals_(ThisObject);
	
EndProcedure

&AtServer
Function FillInPricesByAgreementOnServer(OnAllLines = False, ConsiderLinesOverAndAboveOrder = True, ErrorText = "")

	ApplyPaymentWithBonusPoints(, True);
	Return FillThePricesByTermsOfSalesServer(OnAllLines, ConsiderLinesOverAndAboveOrder, ErrorText);
	
EndFunction

&AtServer
Function FillInContractPricesOnServer(ErrorText = "")
	ApplyPaymentWithBonusPoints(, True);
	Return FillThePricesByTermsOfSalesServer(,, ErrorText);
EndFunction
	
#EndRegion

#Region FillingByOrderByOrder

&AtServer
Procedure RefillByNotes(AnArrayOfOrders)
	
	FillingStructure = SalesServerCall.ReFillInvoiceForOrders(Object);
	
	If FillingStructure.HasChanges Then
		
		CustomerInvoiceLocalization.FillInCacheOfBarcodesOfPackages(ThisObject);
		
		Modified = True;
		CalculateTotals_(ThisObject);
		Object.DiscountsAreCalculated = False;
		
	EndIf;
	
EndProcedure

#EndRegion

#Region PricingAndDiscounts

&AtServer
Function FillThePricesByTermsOfSalesServer(OnAllLines = False, ConsiderLinesOverAndAboveOrder = True, ErrorText = "")
	
	If OnAllLines Then
		If SalesInExcessOfOrder And ConsiderLinesOverAndAboveOrder Then
			RowsArray = Object.Goods.FindRows(New Structure("RowCode", 0));
		Else
			RowsArray = Undefined;
		EndIf;
	Else
		RowsArray = New Array;
		For Each String In Items.Goods.SelectedRows Do
			FoundRow = Object.Goods.FindByID(String);
			If (SalesInExcessOfOrder And FoundRow.RowCode = 0) 
				Or VarianceFromSalesTermsAndConditions Then
				RowsArray.Add(FoundRow);
			EndIf;
		EndDo;
	EndIf;
	
	SetsServerCall.AddToFullSet(Object.Goods, RowsArray, True);
	
	ParametersForFillingInVATAmountLocalManSManSManSManSManSManSManSManS = BatchProcessingOfTablePartClientServer.ParametersForFillingInVATAmountLocalManSManSManSManSManSManSManSManS(
		Object.Currency,
		LocalAccountingCurrency,
		ManagementAccountingCurrency);
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateAmount");
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountManualDiscount", New Structure("Clear, RecalculateAmountOfManualDiscount_", False, True));
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountDiscountWithBonusPoints");
	StructureOfActions.Insert("ClearAutomaticDiscount", Undefined);
	StructureOfActions.Insert("ClearAmountOfSettlements", Undefined);
	StructureOfActions.Insert("SetVATAmountLocalMans", ParametersForFillingInVATAmountLocalManSManSManSManSManSManSManSManS);
	StructureOfActions.Insert("FillInVATRateByPriceType", BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRateByPriceType(Object));
		
	FillParameters = New Structure();
	FillParameters.Insert("Date", Object.Date);
	FillParameters.Insert("Currency", Object.Currency);
	FillParameters.Insert("Partner", Object.Partner);
	FillParameters.Insert("Organization", Object.Organization);
	FillParameters.Insert("VATTaxation",  Object.VATTaxation);
	FillParameters.Insert("ReturnReusablePackage",  Object.ToReturnReusablePackage);
	FillParameters.Insert("CalculateSets", True);
	FillParameters.Insert("PopulationFields", "Price, PriceKind, DeliveryPeriodDays");
	If SalesViaCommissionAgent Then
		FillParameters.Insert("PriceKind", Common.ObjectAttributeValue(Object.Contract, "SalesPriceType"));
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
	
	PricesCalculated = EnterprisePricesFillingServer.FillInPrices(
		Object.Goods, // Table part
		RowsArray, // Array of rows or selection structure
		FillParameters,
		StructureOfActions);
	
	TMCommonUse.FillInDuplicateDependentPropsInCollection(Object.Goods, DependentDetails());
	CalculateTotals_(ThisObject);
	ARAPAccountingClientServer.UpdateHyperlinkText(ThisForm);
	
	Return PricesCalculated;
	
EndFunction

&AtServer
Function FillInPricesOfSelectedRowsByPriceTypeServer(PricesKind)
	
	RowsArray = New Array;
	
	For Each CurRow In Items.Goods.SelectedRows Do
		FoundRow = Object.Goods.FindByID(CurRow);
		If (SalesInExcessOfOrder And FoundRow.RowCode = 0) 
			Or VarianceFromSalesTermsAndConditions Then
			RowsArray.Add(FoundRow);
		EndIf;
	EndDo;
	
	SetsServerCall.AddToFullSet(Object.Goods, RowsArray, True);
	
	ParametersForFillingInVATAmountLocalManSManSManSManSManSManSManSManS = BatchProcessingOfTablePartClientServer.ParametersForFillingInVATAmountLocalManSManSManSManSManSManSManSManS(
		Object.Currency,
		LocalAccountingCurrency,
		ManagementAccountingCurrency);
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateAmount");
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountManualDiscount", New Structure("Clear, RecalculateAmountOfManualDiscount_", False, True));
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountDiscountWithBonusPoints");
	StructureOfActions.Insert("ClearAutomaticDiscount", Undefined);
	StructureOfActions.Insert("ClearAmountOfSettlements", Undefined);
	StructureOfActions.Insert("SetVATAmountLocalMans", ParametersForFillingInVATAmountLocalManSManSManSManSManSManSManSManS);
	StructureOfActions.Insert("FillInVATRateByPriceType", BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRateByPriceType(Object));
		
	FillParameters = New Structure();
	FillParameters.Insert("Date", Object.Date);
	FillParameters.Insert("Currency", Object.Currency);
	FillParameters.Insert("Organization", Object.Organization);
	FillParameters.Insert("PriceKind", PricesKind);
	FillParameters.Insert("CalculateSets", True);
	FillParameters.Insert("PriceIncludesVAT", Object.PriceIncludesVAT);
	FillParameters.Insert("PopulationFields", "Price, PriceKind");
	
	PricesCalculated = EnterprisePricesFillingServer.FillInPrices(
		Object.Goods, // Table part
		RowsArray, // Array of rows or selection structure
		FillParameters,
		StructureOfActions);
	
	TMCommonUse.FillInDuplicateDependentPropsInCollection(Object.Goods, DependentDetails());
	CalculateTotals_(ThisObject);
	
	Return PricesCalculated;
	
EndFunction 

&AtServer
Procedure MessagesReceived(Messages)
	
	DiscountsMarkupsFillingServer.SaveSpentMessages(Object, Messages);
	DiscountsMarkupsFillingServer.ConfigureShowMessagesCommand(Object, Items.ShowMessages);
	
EndProcedure

&AtServer
Procedure CalculateDiscountsWithoutApplyingToObject()
	
	ParametersStructure1 = DiscountsMarkupsFillingServer.NewParametersCalculate();
	ParametersStructure1.ApplyToObject				 = False;
	ParametersStructure1.OnlyPreliminaryCalculation		 = False;
	ParametersStructure1.RestoreManagedDiscounts	 = True;
	ParametersStructure1.ManagedDiscounts				 = ManagedDiscounts;
	ParametersStructure1.SalesInExcessOfOrder			 = SalesInExcessOfOrder And Object.OrderSales;
	
	AppliedDiscounts = DiscountsMarkupsFillingServer.Calculate(Object, ParametersStructure1);
	AddressOfAppliedDiscountsInTheTemporaryStorage = 
			PutToTempStorage(AppliedDiscounts, UUID);
	
EndProcedure 

&AtServer
Function CalculateDiscountsMarginsOnServer(ParametersStructure1, TakeFromTemporaryStorage = False)
	
	If TakeFromTemporaryStorage Then
		AppliedDiscounts = GetFromTempStorage(AddressOfAppliedDiscountsInTheTemporaryStorage);
		DiscountsMarkupsFillingServer.ApplyCalculationResult(
			Object, AppliedDiscounts, Object.OrderSales And SalesInExcessOfOrder);
	Else
		AppliedDiscounts = DiscountsMarkupsFillingServer.Calculate(Object, ParametersStructure1);
		AddressOfAppliedDiscountsInTheTemporaryStorage = 
			PutToTempStorage(AppliedDiscounts, UUID);
	EndIf;
	
	Object.DiscountsAreCalculated = True;
	
	StructureOfAdditionalActions = New Structure;
	StructureOfAdditionalActions.Insert("FillInNoReturnContainerAttribute", Object.ToReturnReusablePackage);
	ReusablePackageServer.UpdateNoReturnableContainerAttribute(
		Object.Goods, Object.ToReturnReusablePackage, StructureOfAdditionalActions);
	
	TMCommonUse.FillInDuplicateDependentPropsInCollection(Object.Goods, DependentDetails());
	CalculateTotals_(ThisObject);
	
	TheStructureOfTheMessages = DiscountsMarkupsFillingServer.TheStructureOfTheMessages(Object);
	DiscountsMarkupsFillingServer.ConfigureShowMessagesCommand(Object, Items.ShowMessages);
	
	Return TheStructureOfTheMessages;
	
EndFunction

&AtServer
Procedure AssignManualDiscountOnServer(AmountOfDiscountMarkUp, Val SelectedRows, AddressInTempStorage)
	
	ImplementationInExcessOfOrderByOrder = SalesInExcessOfOrder And Object.OrderSales;
	
	DiscountParameters = DiscountsMarkupsFillingServer.NewOptionsAssignManualDiscount();
	DiscountParameters.AutomaticDiscountsAreUsed = True;
	DiscountParameters.OnlyForActiveRows			 = False;
	DiscountParameters.CalculateAmountWithVAT			 = True;
	DiscountParameters.CalculateAmountOfSettlements_1	 = True;
	DiscountParameters.SelectedRows				 = SelectedRows;
	DiscountParameters.AddressInTempStorage		 = AddressInTempStorage;
	DiscountParameters.SalesInExcessOfOrder			 = ImplementationInExcessOfOrderByOrder;
	
	DiscountsMarkupsFillingServer.AssignAManualDiscount(Object, "Goods", AmountOfDiscountMarkUp, DiscountParameters);
	
	StructureOfAdditionalActions = New Structure;
	StructureOfAdditionalActions.Insert("FillInNoReturnContainerAttribute", Object.ToReturnReusablePackage);
	ReusablePackageServer.UpdateNoReturnableContainerAttribute(Object.Goods, Object.ToReturnReusablePackage, StructureOfAdditionalActions);
	
	TMCommonUse.FillInDuplicateDependentPropsInCollection(Object.Goods, DependentDetails());

EndProcedure 

&AtServer
Function PreCalculatedDiscountsMarginsOnOrder(ChangedDiscounts)
	
	DiscountsMarkups = Object.DiscountsMarkups.Unload();
	DiscountsMarkups.Clear();
	
	TheseDiscountsMarginsOnOrder = DiscountsMarkupsFillingServer.DiscountsMarginsOnOrder(Object);
	For Each OrderProductLine In TheseDiscountsMarginsOnOrder.TableOfGoods Do
		
		FoundRows = Object.Goods.FindRows(
			New Structure("SalesOrder,RowCode", OrderProductLine.SalesOrder, OrderProductLine.RowCode));
		If FoundRows.Count() = 0 Then
			Continue;
		EndIf;
		
		TableRow = FoundRows[0];
		If OrderProductLine.DiscountMarkupAmount = Null Then
			If Object.BusinessOperation = Enums.BusinessTransactions.TransferOfTitleToGoods Then
				ErrorText = NStr("vi = 'Đã xảy ra sự cố khi chuyển chiết khấu từ lệnh. Có thể là, chưa đặt tỷ giá đối với loại tiền ""%Currency%""';
								|ru = 'Возникла проблемная ситуация при переносе скидок из распоряжения. Возможно не задан курс для валюты ""%Currency%""';
								|en = 'An issue occurred while moving discounts from the reference. Exchange rate for the ""%Currency%"" currency may not be specified.'; fa = 'An issue occurred while moving discounts from the reference. Exchange rate for the ""%Currency%"" currency may not be specified.';
								|it = 'An issue occurred while moving discounts from the reference. Exchange rate for the ""%Currency%"" currency may not be specified.';
								|pl = 'An issue occurred while moving discounts from the reference. Exchange rate for the ""%Currency%"" currency may not be specified.';
								|tr = 'Siparişten indirim aktarırken bir sorun oluştu. ""%Currency%"" para birimi için döviz kuru ayarlanmamış olabilir'");
			Else
				ErrorText = NStr("vi = 'Có một vấn đề khi chuyển giảm giá từ đơn đặt hàng. Có lẽ không đặt tỷ giá cho loại tiền ""%Currency%""';
								|ru = 'Возникла проблемная ситуация при переносе скидок из заказа. Возможно не задан курс для валюты ""%Currency%""';
								|en = 'An issue occurred while moving discounts from the order. Exchange rate for the ""%Currency%"" currency may not be specified.'; fa = 'An issue occurred while moving discounts from the order. Exchange rate for the ""%Currency%"" currency may not be specified.';
								|it = 'Si è verificato un problema durante il trasferimento degli sconti dall''ordine. Probabilmente non è stato impostato il tasso di cambio per la valuta ""%Currency%""';
								|pl = 'Podczas przesyłania rabatów z zamówienia wystąpił problem. Być może nie ustawiono stawki dla waluty ""%Currency%""';
								|tr = 'Bir siparişten indirim aktarırken bir sorun oluştu. ""%Currency%"" para birimi için döviz kuru ayarlanmamış olabilir'");
			EndIf;
			ErrorText = StrReplace(ErrorText, "%Currency%", Object.ARAPCurrency);
			Raise ErrorText;
		EndIf;
		
		AmountForAllocation = Round(
				OrderProductLine.OrderAmountOfAutomaticDiscount
				* (OrderProductLine.ImplementationQuantity / OrderProductLine.OrderQuantity)
				* OrderProductLine.CurrencyConversionRate,
			 2);
		CurAmountOfBonusPointsToBeDebitedInCurrency = Round(
				OrderProductLine.OrderIsAmountOfBonusPointsToBeDebitedInCurrency 
				* (OrderProductLine.ImplementationQuantity / OrderProductLine.OrderQuantity) 
				* OrderProductLine.CurrencyConversionRate, 
			2);
		CurAmountOfBonusPointsToBeDebited = Round(
				OrderProductLine.OrderAmountOfBonusPointsToBeDebited 
				* (OrderProductLine.ImplementationQuantity / OrderProductLine.OrderQuantity), 
			2);
		
		If OrderProductLine.PercentRateOfManualDiscount <> TableRow.PercentRateOfManualDiscount
			Or CurAmountOfBonusPointsToBeDebitedInCurrency <> TableRow.AmountOfBonusPointsToDeductionInCurrency
			Or CurAmountOfBonusPointsToBeDebited <> TableRow.AmountOfBonusPointsToDeduction Then
				
			ChangedDiscounts = True;
			Return DiscountsMarkups;
			
		EndIf;
		
		If TableRow.ConnectionKey <> 0 Then
		
			FoundRows = TheseDiscountsMarginsOnOrder.DiscountsOrderMargins.FindRows(
				New Structure("SalesOrder, ConnectionKey", TableRow.SalesOrder, OrderProductLine.ConnectionKey));
			If FoundRows.Count() <> 0 Then
				For Each OrderDiscountsRow In FoundRows Do
					
					DiscountsRow = DiscountsMarkups.Add();
					FillPropertyValues(DiscountsRow, OrderDiscountsRow);
					DiscountsRow.ConnectionKey	= TableRow.ConnectionKey;
					DiscountsRow.Sum = OrderProductLine.ZoomRatio * DiscountsRow.Sum;
					
					AmountForAllocation = AmountForAllocation - DiscountsRow.Sum;
				EndDo;
				If AmountForAllocation <> 0 Then
					DiscountsRow.Sum = DiscountsRow.Sum + AmountForAllocation;
				EndIf;
			EndIf;
			
		EndIf;
		
	EndDo;
	
	Return DiscountsMarkups;
	
EndFunction

&AtServer
Procedure CancelManualDiscountsOnServer()
	
	ImplementationInExcessOfOrderByOrder = SalesInExcessOfOrder And Object.OrderSales;
	
	DiscountsMarkupsFillingServer.CancelManualDiscounts(Object, "Goods", True, True, True, ImplementationInExcessOfOrderByOrder);
	
	StructureOfAdditionalActions = New Structure;
	StructureOfAdditionalActions.Insert("FillInNoReturnContainerAttribute", Object.ToReturnReusablePackage);
	ReusablePackageServer.UpdateNoReturnableContainerAttribute(Object.Goods, Object.ToReturnReusablePackage, StructureOfAdditionalActions);
	
	TMCommonUse.FillInDuplicateDependentPropsInCollection(Object.Goods, DependentDetails());

EndProcedure

&AtServer
Function PerformPreliminaryCalculationOfDiscountsOnServer()
	
	ParametersStructure1 = DiscountsMarkupsFillingServer.NewParametersCalculate();
	ParametersStructure1.ApplyToObject				 = False;
	ParametersStructure1.OnlyPreliminaryCalculation		 = True;
	ParametersStructure1.RestoreManagedDiscounts	 = True;
	ParametersStructure1.ManagedDiscounts				 = ManagedDiscounts;
	ParametersStructure1.SalesInExcessOfOrder			 = SalesInExcessOfOrder And Object.OrderSales;
	
	Return PutToTempStorage(
		DiscountsMarkupsFillingServer.Calculate(Object, ParametersStructure1), UUID);
	
EndFunction

&AtServer
Procedure LoyaltyCardReadOnServer(LoyaltyCardDetails)
	
	If ValueIsFilled(LoyaltyCardDetails.Partner) And LoyaltyCardDetails.Partner <> Object.Partner Then
		Object.Partner    = LoyaltyCardDetails.Partner;
		Object.Counterparty = Catalogs.Counterparties.EmptyRef();
		Object.Terms = Catalogs.TermsOfSale.EmptyRef();
		WhenChangingPartnerServer();
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
Procedure LoyaltyCardIsRead(LoyaltyCard)
	
	LoyaltyCardDetails = LoyaltyCardServerCall.GetLoyaltyCardDetails(LoyaltyCard);
	If ValueIsFilled(LoyaltyCardDetails.Ref) Then
		
		If Not LoyaltyCardDetails.PartnerAvailable Then
			ShowMessageBox(,NStr("vi = 'Không có quyền truy cập vào đối tác giữ thẻ khách hàng thân thiết.';
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
			Modified     = True;
			Object.LoyaltyCard = LoyaltyCard;
			
			Return;
			
		ElsIf Object.Partner <> LoyaltyCardDetails.Partner Then // The partner in the map is different from the partner in the document.
			
			If ValueIsFilled(Object.Partner) Then
				AdditionalParameters = New Structure;
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
		Modified     = True;
		Object.LoyaltyCard = LoyaltyCard;
		LoyaltyCardReadOnServer(LoyaltyCardDetails);
		
	Else
		
		UseLoyaltyPrograms = UseLoyaltyPrograms(Undefined);
		ApplyPaymentWithBonusPointsClient();
		SetVisibilityOfElementsOfLoyaltyBonusProgram();
		
	EndIf;
	
EndProcedure

&AtClient
Procedure LoyaltyCardReadQuestionCompletion(Response, AdditionalParameters) Export
	
	If Response = DialogReturnCode.Yes Then
		
		DiscountsMarkupsFillingClient.ResetDiscountsCalculatedFlag(ThisForm);
		Modified = True;
		Object.LoyaltyCard   = AdditionalParameters.LoyaltyCard;
		LoyaltyCardReadOnServer(AdditionalParameters.LoyaltyCardDetails);
		
	Else
		
		UseLoyaltyPrograms = UseLoyaltyPrograms(Object.LoyaltyCard);
		SetVisibilityOfElementsOfLoyaltyBonusProgram();

	EndIf;
	
EndProcedure

&AtServer
Function DiscountsHaveChanged()
	
	ParametersStructure1 = DiscountsMarkupsFillingServer.NewParametersCalculate();
	ParametersStructure1.ApplyToObject				 = False;
	ParametersStructure1.OnlyPreliminaryCalculation		 = False;
	ParametersStructure1.RestoreManagedDiscounts	 = True;
	ParametersStructure1.ManagedDiscounts				 = ManagedDiscounts;
	ParametersStructure1.SalesInExcessOfOrder			 = SalesInExcessOfOrder And Object.OrderSales;
	
	DiscountsHaveChanged = False;
	
	If Not Object.OrderSales Then
		AppliedDiscounts = DiscountsMarkupsFillingServer.Calculate(Object, ParametersStructure1);
		TableDiscountsMarkups = AppliedDiscounts.TableDiscountsMarkups.Copy();
	ElsIf ParametersStructure1.SalesInExcessOfOrder Then
		AppliedDiscounts = DiscountsMarkupsFillingServer.Calculate(Object, ParametersStructure1);
		TableDiscountsMarkups = PreCalculatedDiscountsMarginsOnOrder(DiscountsHaveChanged);
		
		For Each LineDiscountsMarginsSource In AppliedDiscounts.TableDiscountsMarkups Do
			DiscountMarkUpLineReceiver = TableDiscountsMarkups.Add();
			FillPropertyValues(DiscountMarkUpLineReceiver, LineDiscountsMarginsSource);
		EndDo;
	Else
		TableDiscountsMarkups = PreCalculatedDiscountsMarginsOnOrder(DiscountsHaveChanged);
	EndIf;
	
	If Not DiscountsHaveChanged Then
		ChangedDiscounts(TableDiscountsMarkups, DiscountsHaveChanged);
	EndIf;
	
	If DiscountsHaveChanged And (Not Object.OrderSales Or ParametersStructure1.SalesInExcessOfOrder) Then
		AddressOfAppliedDiscountsInTheTemporaryStorage = PutToTempStorage(AppliedDiscounts, UUID);
	EndIf;
	
	Return DiscountsHaveChanged;
	
EndFunction

&AtServer 
Procedure ChangedDiscounts(TableDiscountsMarkups, DiscountsHaveChanged)
	
	RowsCount = TableDiscountsMarkups.Count();
	If RowsCount <> Object.DiscountsMarkups.Count() Then
		DiscountsHaveChanged = True;
	Else
		
		If Object.Goods.Total("DiscountMarkupAmount") <> Object.DiscountsMarkups.Total("Sum") Then
			DiscountsHaveChanged = True;
		EndIf;
		
		For LineNumber = 1 To RowsCount Do
			If Object.DiscountsMarkups[LineNumber-1].Sum <> TableDiscountsMarkups[LineNumber-1].Sum
				Or Object.DiscountsMarkups[LineNumber-1].ConnectionKey <> TableDiscountsMarkups[LineNumber-1].ConnectionKey
				Or Object.DiscountsMarkups[LineNumber-1].DiscountMarkup <> TableDiscountsMarkups[LineNumber-1].DiscountMarkup
				Or Object.DiscountsMarkups[LineNumber-1].RemindLater <> TableDiscountsMarkups[LineNumber-1].RemindLater Then
				DiscountsHaveChanged = True;
				Break;
			EndIf;
		EndDo;
		
	EndIf;
	
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
	StructureOfActions.Insert("ClearAmountOfSettlements");
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("FillInDuplicateDependentDetails", DependentDetails());
	
	RowsToProcess = New Array;
	
	AdjustmentIsCompleted = False;
	For Each TableRow In TableOfGoods Do
		
		If DeletingPayment Then
			If TableRow.RowCode <> 0
				Or (TableRow.AmountOfBonusPointsToDeduction = 0 
				And TableRow.AmountOfBonusPointsToDeductionInCurrency = 0) Then
				Continue;
			EndIf;
			TSRow = TableRow;
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
		Object.DiscountsAreCalculated = False;

		CalculateTotals_(ThisObject);
		
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

&AtClient
Procedure VerificationOfPaymentWithBonusPoints(CurrentRow, StructureOfFillingBonusPoints)
	
	If Not UseLoyaltyPrograms
		Or Not PaymentWithBonusPoints
		Or SalesInExcessOfOrder And CurrentRow.RowCode <> 0 Then
		
		If UseLoyaltyPrograms And SalesInExcessOfOrder And CurrentRow.RowCode <> 0 Then
			RowFilter = New Structure("SalesOrder, RowCode", CurrentRow.SalesOrder, CurrentRow.RowCode);
			StructureOfFillingBonusPoints = VerificationOfPaymentWithBonusPointsServer(RowFilter);
		EndIf;
		
		Return;
		
	EndIf;
	
	ClearMessages();
	ApplyPaymentWithBonusPointsClient(, True);
	
EndProcedure

&AtServer
Function VerificationOfPaymentWithBonusPointsServer(RowFilter)
	
	If Not ValueIsFilled(AddressOfPaymentBonusPointsInTemporaryStorage) Then
		Return Undefined;
	EndIf;
	
	CachedValuesBonusPoints = GetFromTempStorage(AddressOfPaymentBonusPointsInTemporaryStorage);
	
	FoundRows = CachedValuesBonusPoints.FindRows(RowFilter);

	TableRow = FoundRows[0];

	If (TableRow.AmountOfBonusPointsToDeduction <> 0 
		Or TableRow.AmountOfBonusPointsToDeductionInCurrency <> 0) Then
		
		DataToRecalculate = New Structure("Count, 
											|NumberOfPackages, 
											|AmountOfBonusPointsToDeductionInCurrency");
		FillPropertyValues(DataToRecalculate, TableRow);
															
		StructureOfFillingBonusPoints = New Structure();
		StructureOfFillingBonusPoints.Insert("RecalculateAmount_", DataToRecalculate);
		
	EndIf;
	
	Return StructureOfFillingBonusPoints;
	
EndFunction

&AtServer
Procedure FillInDataForCalculatingPaymentWithBonusPoints()
	
	If Not Object.OrderSales Or Not UseLoyaltyPrograms Then
		Return;
	EndIf;
	
	CachedValuesBonusPoints = Object.Goods.Unload(, 
															"SalesOrder, 
															|RowCode, 
															|Count, 
															|NumberOfPackages, 
															|AmountOfBonusPointsToDeduction, 
															|AmountOfBonusPointsToDeductionInCurrency");
															
	RowsToDelete = CachedValuesBonusPoints.FindRows(New Structure("RowCode", 0));
	
	PaymentWithBonusPoints = False;
	For Each String In RowsToDelete Do
		
		PaymentWithBonusPoints = PaymentWithBonusPoints 
									Or String.AmountOfBonusPointsToDeduction <> 0 
									Or String.AmountOfBonusPointsToDeductionInCurrency <> 0;
		
		CachedValuesBonusPoints.Delete(String);
	EndDo;
	
	CachedValuesBonusPoints.Indexes.Add("SalesOrder, RowCode");
	
	AddressOfPaymentBonusPointsInTemporaryStorage = PutToTempStorage(CachedValuesBonusPoints, UUID);
	
EndProcedure

#EndRegion

#Region SelectionAndProcessingOfQuantityVerification

&AtClient
Procedure CheckQuantityInTheDocumentClient()
	
	OnlyNonLabeledProductsHaveBeenUnloaded = False;
	
	OpeningParameters = New Structure;
	OpeningParameters.Insert("AddressInTempStorage",             PutTablePartOfGoodsInTemporaryStorageToCheckQuantity(OnlyNonLabeledProductsHaveBeenUnloaded));
	OpeningParameters.Insert("TabularSectionName",                     "Goods");
	OpeningParameters.Insert("Ref",                                Object.Ref);
	OpeningParameters.Insert("GoodsQuantityExcessIsAllowed",  Not Object.OrderSales Or SalesInExcessOfOrder);
	OpeningParameters.Insert("SeriesSpecificationParameters",                SeriesSpecificationParameters);
	OpeningParameters.Insert("CalculateSets",                    True);
	OpeningParameters.Insert("OnlyNonLabeledProductsHaveBeenUnloaded", OnlyNonLabeledProductsHaveBeenUnloaded);
	
	OpenForm("CommonForm.CheckDocumentPopulation", OpeningParameters,,,,, New CallbackDescription("CheckQuantityInTheDocumentCompletion", ThisObject), FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtServer
Procedure ProcessingSelectionOfSelectionOnServer(ValueSelected)
	
	ApplyPaymentWithBonusPoints(, True);
	
	TableOfGoods = GetFromTempStorage(ValueSelected.GoodsAddressInStorage);
	
	ListOfProperties = "ProductsInSet, ItemVariantOfSet, Products, Characteristic, Package, PriceKind, 
			|Price, NumberOfPackages, Count, Sum, ManualDiscount, PercentRateOfManualDiscount, 
			|DeliveryPeriodDays, Series, WithAssignment";
	SearchFields = "ProductsInSet, ItemVariantOfSet, Products, Characteristic, Package, PriceKind,
			|WithAssignment, Series, Price";
	If ValueIsFilled(Object.Warehouse) Then
		ListOfProperties = ListOfProperties + ", Warehouse";
		SearchFields = SearchFields + ", Warehouse";
	EndIf;
	
	ParametersONChangingTypeOfItem = New Structure;
	ParametersONChangingTypeOfItem.Insert("ThereAreWorks", True);
	ParametersONChangingTypeOfItem.Insert("IsCanceled", False);
	ParametersONChangingTypeOfItem.Insert("ThisIsTransferOfOwnership",
		Object.BusinessOperation =
			PredefinedValue("Enum.BusinessTransactions.TransferOfTitleToGoods"));
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
	StructureOfActions.Insert("FillInVATRate", BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRate(Object));
	StructureOfActions.Insert("FillInVATRateByPriceType", BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRateByPriceType(Object));
	StructureOfActions.Insert("FillInHSCode", Object.VATTaxation);
	StructureOfActions.Insert("FillInVATRateForReturnableContainers", Object.ToReturnReusablePackage);
	StructureOfActions.Insert("FillInNoReturnContainerAttribute", Object.ToReturnReusablePackage);
	StructureOfActions.Insert("WhenChangingProductType", ParametersONChangingTypeOfItem);
	StructureOfActions.Insert("FillInSubdivisionInTSLine", New Structure("Department", Object.Department));
	AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions, Object);
	
	ParametersForFillingInVATAmountLocalManSManSManSManSManSManSManSManS = BatchProcessingOfTablePartClientServer.ParametersForFillingInVATAmountLocalManSManSManSManSManSManSManSManS(
		Object.Currency,
		LocalAccountingCurrency,
		ManagementAccountingCurrency);
	
	StructureOfActions.Insert("SetVATAmountLocalMans", ParametersForFillingInVATAmountLocalManSManSManSManSManSManSManSManS);
	BatchProcessingOfTablePartClientServerLocalization.CompleteActionStructureWhenChangingElement(
		ThisObject, "Products", StructureOfActions);
	OrdersClientServer.AddActionFillInDiscrepancyOrderAttribute(StructureOfActions, Object.OrderSales);
	
	RowsToProcess = New Array;
	
	FilterParameters = New Structure(SearchFields);
	
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
				FillPropertyValues(CurrentRow, RowOfProduct, ListOfProperties);
			EndIf;
		Else
			// For non-sets, you should always add a new line, regardless of the availability of such an item in the TS.
			
			CurrentRow = Object.Goods.Add();
			FillPropertyValues(CurrentRow, RowOfProduct, ListOfProperties);
		EndIf;
		
		LinesOfBusinessClientServer.FillAssignmentByFlagSeparately(ThisObject, CurrentRow);
		
		RowsToProcess.Add(CurrentRow);
		
	EndDo;
	If RecalculationOfPackagesIsRequired Then
		StructureOfActions.Insert("RecalculateNumberOfPackages");
	EndIf;
	
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		RowsToProcess,
		StructureOfActions,
		Object.Goods);

	FillInServiceDetailsForProductRange();
	WhenChangingWarehouseInTablePartServer();
	ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);
	ReusablePackageServer.UpdateFillingStateOfMultiTurnContainer(Object.ReusablePackageFillingStatus);
	CalculateTotals_(ThisObject);
	
	FormEvents.WhenChangingElement(ThisObject, "Goods");
	
EndProcedure

&AtClient
Procedure HandlingSelectionSelectionOnClient(ValueSelected)
	
	ClearMessages();
	ProcessingSelectionOfSelectionOnServer(ValueSelected);
	DiscountsMarkupsFillingClient.ResetDiscountsCalculatedFlag(ThisForm);
	
EndProcedure

&AtClient
Procedure PickUpFromOrder()
	
	QuestionIsRequired = False;
	If Object.Ref.IsEmpty() Then
		QuestionIsRequired = True;
		
		If Object.BusinessOperation =
			PredefinedValue("Enum.BusinessTransactions.TransferOfTitleToGoods") Then
			QueryText = NStr("vi = 'Chỉ có thể chọn hàng hóa theo lệnh trong chứng từ đã ghi lại. Ghi lại?';
							|ru = 'Подбор товаров по распоряжениям возможно только в записанном документе. Записать?';
							|en = 'You can pick goods by references only in a saved document. Save?'; fa = 'You can pick goods by references only in a saved document. Save?';
							|it = 'You can pick goods by references only in a saved document. Save?';
							|pl = 'You can pick goods by references only in a saved document. Save?';
							|tr = 'Siparişlere göre ürün seçimi, yalnızca kaydedilmiş belgede yapılabilir. Kaydedilsin mi?'");
		Else
			QueryText = NStr("vi = 'Chỉ có thể chọn hàng hóa theo đơn hàng / hóa đơn trong chứng từ đã ghi lại. Ghi lại?';
							|ru = 'Подбор товаров по заказам / ордерам возможен только в записанном документе. Записать?';
							|en = 'Picking of goods by orders / goods issues is possible only in a saved document. Save?'; fa = 'Picking of goods by orders / goods issues is possible only in a saved document. Save?';
							|it = 'Picking of goods by orders / goods issues is possible only in a saved document. Save?';
							|pl = 'Picking of goods by orders / goods issues is possible only in a saved document. Save?';
							|tr = 'Siparişe / emre ilişkin mal seçimi sadece yazılı bir belgede mümkündür. Kaydedilsin mi?'");
		EndIf;
		
	ElsIf Modified Then
		QuestionIsRequired = True;
		SpendRecord = ?(Object.Posted, NStr("vi = 'Kết chuyển';
											|ru = 'Провести';
											|en = 'Post'; fa = 'ثبت';
											|it = 'Pubblicare';
											|pl = 'Zaksięguj';
											|tr = 'Kaydet'"), NStr("vi = 'Ghi lại';
																|ru = 'Записать';
																|en = 'Save'; fa = 'ذخیره';
																|it = 'Registrare';
																|pl = 'Zapisz';
																|tr = 'Kaydet'"));
		QueryText     = StrTemplate(NStr("vi = 'Đã thay đổi chứng từ. %1?';
										|ru = 'Документ был изменен. %1?';
										|en = 'The document was changed. %1?'; fa = 'The document was changed. %1?';
										|it = 'Documento modificato. %1?';
										|pl = 'Dokument został zmieniony. %1?';
										|tr = 'Belge değiştirildi. %1?'"), SpendRecord);
	EndIf;

	If QuestionIsRequired Then
		ShowQueryBox(New CallbackDescription("PickUpFromOrderEnd", ThisObject),
			QueryText, QuestionDialogMode.YesNo);
		Return;
	EndIf;
	
	AddItemsFromSalesOrderGoodsIssue();
	
EndProcedure

&AtClient
Procedure PickUpFromOrderEnd(QuestionResult, AdditionalParameters) Export
	
	Response = QuestionResult;
	If Response = DialogReturnCode.No Then
		Return;
	EndIf;

	RecordingResult = False;
	If Object.Posted Then
		If CheckFilling() Then
			RecordingResult = Write(New Structure("WriteMode", DocumentWriteMode.Posting));
		EndIf;
	Else
		RecordingResult = Write(New Structure("WriteMode", DocumentWriteMode.Write));
	EndIf;

	If Not RecordingResult Then
		Return;
	EndIf;
	
	AddItemsFromSalesOrderGoodsIssue();
	
EndProcedure

&AtClient
Procedure AddItemsFromSalesOrderGoodsIssue()
	
	Try
		LockFormDataForEdit();
		Modified = True;
	Except
		ShowMessageBox(,BriefErrorDescription(ErrorInfo()));
		Return;
	EndTry;
	
	ArrayOfStringCodes = New Array;
	AddressOfGoods = "";
	AddressOfBarcodesOfPackages = "";

	BeforeSelectingProductsFromOrder(ArrayOfStringCodes, AddressOfGoods);
	PrepareDataOnBarcodesOfPackages(AddressOfBarcodesOfPackages);
	
	PickingParameters = New Structure(
		"SalesOrder,
		|Date,
		|Warehouse,
		|Partner,
		|SalesOpportunity,
		|Counterparty,
		|Contract,
		|Organization,
		|BusinessOperation,
		|Terms,
		|OrderSales,
		|ARAPCurrency,
		|VATTaxation,
		|PriceIncludesVAT,
		|ARAPObjectSettings,
		|ToReturnReusablePackage,
		|PackageDepositIsRequired,
		|Status,
		|LineOfBusiness");
		
	FillPropertyValues(PickingParameters, Object);
	PickingParameters.Insert("Document", Object.Ref);
	PickingParameters.Insert("DocumentCurrency", Object.Currency);
	PickingParameters.Insert("ArrayOfStringCodes", ArrayOfStringCodes);
	PickingParameters.Insert("GoodsAddressInTemporaryStorage", AddressOfGoods);
	PickingParameters.Insert("AddressOfBarcodesOfImplementationPackagesInTemporaryStorage", AddressOfBarcodesOfPackages);
	PickingParameters.Insert("AdvancedWarehousingOnShipment", AdvancedWarehousingOnShipment);
	PickingParameters.Insert("CourseNumerator", Object.CourseNumerator);
	PickingParameters.Insert("CourseDenominator", Object.CourseDenominator);
	PickingParameters.Insert("UseAdvancedFeaturesOfSalesOrder", UseAdvancedFeaturesOfSalesOrder);
	
	OpenForm("Document.CustomerInvoice.Form.SelectionOfGoodsFromOrderForm",PickingParameters,ThisForm,,,, Undefined, FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtServer
Procedure ProcessingProductSelectionFromOrder(GoodsAddressInStorage)
	
	TableStructure = GetFromTempStorage(GoodsAddressInStorage);
	StructureOfProductsTables = TableStructure.Goods; // ValueTable
	
	SearchStructureForOrderItems = New Structure("RowCode,SalesOrder");
	StructureOfSearchForGoodsWaybill = New Structure("LineNumber");
	
	OrdersAreUsedAsInvoices = OrdersAreUsedAsInvoices();
	
	For Each RowOfGoods In StructureOfProductsTables Do
		
		// PM goods processing.
		If RowOfGoods.RowCode<>0 And ValueIsFilled(RowOfGoods.SalesOrder) Then
			SearchStructureForOrderItems.RowCode = RowOfGoods.RowCode;
			SearchStructureForOrderItems.SalesOrder = RowOfGoods.SalesOrder;
			ArrayOfTSRows = Object.Goods.FindRows(SearchStructureForOrderItems);
		Else
			StructureOfSearchForGoodsWaybill.LineNumber = RowOfGoods.LineNumber;
			ArrayOfTSRows = Object.Goods.FindRows(StructureOfSearchForGoodsWaybill);
		EndIf;
		
		If ArrayOfTSRows.Count() = 0 Then
			
			StringTSGoods = Object.Goods.Add();
			
		ElsIf ArrayOfTSRows.Count() = 1 Then
			
			StringTSGoods = ArrayOfTSRows[0];
			
			// Removing subordinate lines from PM discounts.
			DeleteTSDiscountMarkUpLines(StringTSGoods);
			
		ElsIf ArrayOfTSRows.Count() > 1 Then
			
			For Each RowToDelete In ArrayOfTSRows Do
				
				// Removing subordinate lines from PM discounts.
				DeleteTSDiscountMarkUpLines(RowToDelete);
				
				Object.Goods.Delete(RowToDelete);
				
			EndDo;
			
			StringTSGoods = Object.Goods.Add();
			
		EndIf;
		
		FillPropertyValues(StringTSGoods, RowOfGoods);
		If Not UseSaleByMultipleOrders 
			And ValueIsFilled(StringTSGoods.SalesOrder) 
			And Object.SalesOrder <> StringTSGoods.SalesOrder Then
			
			Object.SalesOrder = StringTSGoods.SalesOrder;
			
		EndIf;
		StringTSGoods.SetIndex = ?(ValueIsFilled(StringTSGoods.ProductsInSet), 1, 0);
		
		If Not ValueIsFilled(StringTSGoods.Warehouse)
			And ValueIsFilled(StringTSGoods.SalesOrder)
			And OrdersAreUsedAsInvoices
			And ValueIsFilled(Object.Warehouse)
			And Not Catalogs.Warehouses.IsFolder(Object.Warehouse) Then
			
			StringTSGoods.Warehouse = Object.Warehouse;
			
		EndIf;
		
	EndDo;
	
	Object.DiscountsAreCalculated = False;
	
	CalculateForSaleOfGoodsServicesByOrder(False);
	
	SeriesSpecificationParameters = New FixedStructure(ProductsServer.SeriesSpecificationParameters(Object, Documents.CustomerInvoice));
	SetVisibilityOfSeriesElements();
	ProductsServer.FillInStatusesForSpecifyingSeries(Object,SeriesSpecificationParameters);
	FillInServiceDetailsForProductRange();
	
	ParametersONChangingTypeOfItem = New Structure;
	ParametersONChangingTypeOfItem.Insert("ThereAreWorks", True);
	ParametersONChangingTypeOfItem.Insert("IsCanceled", False);
	ParametersONChangingTypeOfItem.Insert("ThisIsTransferOfOwnership",
		Object.BusinessOperation =
			PredefinedValue("Enum.BusinessTransactions.TransferOfTitleToGoods"));
	
	ParametersForFillingInVATAmountLocalManSManSManSManSManSManSManSManS = BatchProcessingOfTablePartClientServer.ParametersForFillingInVATAmountLocalManSManSManSManSManSManSManSManS(
		Object.Currency,
		LocalAccountingCurrency,
		ManagementAccountingCurrency);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("ClearAmountOfSettlements");
	StructureOfActions.Insert("SetVATAmountLocalMans", ParametersForFillingInVATAmountLocalManSManSManSManSManSManSManSManS);
	StructureOfActions.Insert("WhenChangingProductType", ParametersONChangingTypeOfItem);
	StructureOfActions.Insert("FillInProductNameOfProductPartner", Object.Partner);
	BatchProcessingOfTablePartServer.TreatTS(Object.Goods, StructureOfActions, Undefined);
	
	UpdateOrderInformation();
	Object.OrderSales = ValueIsFilled(Object.SalesOrder) Or OrderList.Count() > 0;
	UpdateDeliveryPlanningView(ThisObject);
	UpdateOrderDeviations();
	
	If Object.OrderSales Then
		If Object.Status = Enums.StatusesOfCustomerInvoices.ForPrepayment Then
			Object.Status = Enums.StatusesOfCustomerInvoices.Shipped;
		EndIf;
	EndIf;
	
	ItemArray = New Array;
    ItemArray.Add("GoodsUnlinkFromOrder");
    ItemArray.Add("GoodsContextMenuUnlinkFromOrder");
    ItemArray.Add("GoodsGroupSalesOrder");
    TMCommonUseClientServer.SetPropertyOfFormElements(Items, ItemArray, "Visible", Object.OrderSales);
	
	ReusablePackageServer.UpdateNoReturnableContainerAttribute(Object.Goods, Object.ToReturnReusablePackage);
	TMCommonUse.FillInDuplicateDependentPropsInCollection(Object.Goods, DependentDetails());
	CalculateTotals_(ThisObject);
	WhenChangingWarehouseInTablePartServer();
	
	FillInDataForCalculatingPaymentWithBonusPoints();
	
	SalesServerLocalization.TransferBarcodesOfPackages(ThisObject, TableStructure.PackageBarcodes);
	FormEvents.WhenChangingElement(ThisObject, "Goods");
	
	ARAPAccountingFormWork.WhenChangingParametersOfMechanism(ThisObject);
	ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisObject, "OrderSales");
	
	BackgroundTaskData = GoodsDelivery.WhenReadingCreatingOrdersOnServer(
		Items,
		Object,
		Object.OrderSales Or SalesViaCommissionAgent,,,
		True);
	
	ResponsiblePersonsServer.InstallManager(
		Object, SalesServer.DocumentBasis(Object, "OrderSales, SalesOrder, Goods.SalesOrder"));
	
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
		
		CommonClient.MessageToUser(ErrorText, Object.Ref, "Object.Partner", "", Cancel);
	EndIf;
	
	If Not ValueIsFilled(Object.Organization) Then
		ErrorText = NStr("vi = 'Chưa điền trường ""Doanh nghiệp""';
						|ru = 'Поле ""Организация"" не заполнено';
						|en = '""Company"" is required'; fa = '""Company"" is required';
						|it = 'Il campo ""Società"" non è compilato';
						|pl = 'Nie wypełniono pola ""Firma""';
						|tr = '""İş yeri"" alanı doldurulmadı'");
		
		CommonClient.MessageToUser(ErrorText, Object.Ref, "Object.Organization", "", Cancel);
	EndIf;
	
	If Not ValueIsFilled(Object.Contract) Then
		ErrorText = NStr("vi = 'Chưa điền trường ""Hợp đồng""';
						|ru = 'Поле ""Договор"" не заполнено';
						|en = '""Contract"" is not filled in.'; fa = '""Contract"" is not filled in.';
						|it = 'Il campo ""Accordo"" non è compilato';
						|pl = 'Pole ""Umowa"" nie jest wypełnione';
						|tr = '""Sözleşme"" alanı doldurulmamış'");
		
		CommonClient.MessageToUser(ErrorText, Object.Ref, "Object.Contract", "", Cancel);
	EndIf;
	
	If Cancel Then
		Return;
	EndIf;
	
	PerformanceMonitorClient.TimeMeasurement(True,
		"Document.CustomerInvoice.DocumentForm.Command.SelectTransferredGoods");
	
	AddressOfGoods = PlaceGoodsInStorageForSelectionOfTransferredGoods();
	
	FormParameters = New Structure;
	FormParameters.Insert("Ref",      Object.Ref);
	FormParameters.Insert("Owner",    Object.Partner);
	FormParameters.Insert("Organization", Object.Organization);
	FormParameters.Insert("Contract",     Object.Contract);
	FormParameters.Insert("BusinessOperation", Object.BusinessOperation);
	FormParameters.Insert("ObjectManager", "Document.CustomerInvoice");
	FormParameters.Insert("AddressOfGoodsInvoiceInVault", AddressOfGoods);
	FormParameters.Insert("CollapseGTDNumbers", True);
	
	OpenForm("DataProcessor.SelectGoodsTransferredToCustody.Form.Form", FormParameters, ThisForm,
		UUID);
	
EndProcedure

&AtServer
Procedure SelectionProcessingSelectionOfTransferredGoods(ValueSelected, PricesCalculated)
	
	RowsArray = New Array;
	
	TableOfGoods = GetFromTempStorage(ValueSelected.GoodsAddressInStorage);
	
	ParametersForFillingInVATAmountLocalManSManSManSManSManSManSManSManS = BatchProcessingOfTablePartClientServer.ParametersForFillingInVATAmountLocalManSManSManSManSManSManSManSManS(
		Object.Currency,
		LocalAccountingCurrency,
		ManagementAccountingCurrency);
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	
	StructureOfActions = New Structure("RecalculateNumberOfPackages");
	StructureOfActions.Insert("FillInVATRate", BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRate(Object));
	StructureOfActions.Insert("FillInVATRateByPriceType", BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRateByPriceType(Object));
	StructureOfActions.Insert("FillInHSCode", Object.VATTaxation);
	StructureOfActions.Insert("FillInVATRateForReturnableContainers", Object.ToReturnReusablePackage);
	StructureOfActions.Insert("FillInNoReturnContainerAttribute", Object.ToReturnReusablePackage);
	StructureOfActions.Insert("RecalculateAmount");
	StructureOfActions.Insert("RecalculateVATAmount",  StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("ClearAmountOfSettlements");
	StructureOfActions.Insert("SetVATAmountLocalMans", ParametersForFillingInVATAmountLocalManSManSManSManSManSManSManSManS);
	
	For Each RowOfProduct In TableOfGoods Do
		
		ProductsSearch = New Structure();
		ProductsSearch.Insert("Products", RowOfProduct.Products);
		ProductsSearch.Insert("Characteristic", RowOfProduct.Characteristic);
		ProductsSearch.Insert("Purpose", RowOfProduct.Purpose);
		If Not RowOfProduct.DifferentSeriesAccounting Then
			ProductsSearch.Insert("Series", RowOfProduct.Series);
		EndIf;
		ProductLines_2 = Object.Goods.FindRows(ProductsSearch);
		
		If ProductLines_2.Count() = 0 Then
			CurrentRow = Object.Goods.Add();
			FillPropertyValues(CurrentRow, RowOfProduct);
		ElsIf ProductLines_2.Count() = 1 Then
			CurrentRow = ProductLines_2[0];
		ElsIf ProductLines_2.Count() > 1 Then
			For Each RowToDelete In ProductLines_2 Do
				Object.Goods.Delete(RowToDelete);
			EndDo;
			CurrentRow = Object.Goods.Add();
			FillPropertyValues(CurrentRow, RowOfProduct);
		EndIf;
		
		CurrentRow.Count = RowOfProduct.QuantityIsSelected;
		RowsArray.Add(CurrentRow);
		
	EndDo;
	
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		RowsArray,
		StructureOfActions,
		Object.Goods);
	
	FillInServiceDetailsForProductRange();
	ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);
	
	FillParameters = New Structure();
	FillParameters.Insert("PopulationFields",               "PriceKind, Price");
	FillParameters.Insert("Date",                         Object.Date);
	FillParameters.Insert("Currency",                       Object.Currency);
	FillParameters.Insert("Organization",                  Object.Organization);
	FillParameters.Insert("ReturnReusablePackage", Object.ToReturnReusablePackage);
	FillParameters.Insert("CalculateSets",           True);
	FillParameters.Insert("VATTaxation",           Object.VATTaxation);
	
	TypeOfContractPrice = TypeOfContractPrice(Object.Contract);
	If Object.PriceIncludesVAT = TypeOfContractPrice.PriceIncludesVAT Then
		FillParameters.Insert("PriceKind", TypeOfContractPrice.PriceKind);
	EndIf;
	
	PricesCalculated = EnterprisePricesFillingServer.FillInPrices(Object.Goods,
			RowsArray,
			FillParameters,
			StructureOfActions);
	
	TMCommonUse.FillInDuplicateDependentPropsInCollection(Object.Goods, DependentDetails());
	CalculateTotals_(ThisObject);
	
	FormEvents.WhenChangingElement(ThisObject, "Goods");
	
EndProcedure

&AtServer
Function PlaceGoodsInStorageForSelectionOfTransferredGoods()
	
	Columns =
		"LineNumber,
		|Products,
		|Characteristic,
		|Purpose,
		|Series,
		|BatchesIndicationStatus,
		|Count";
	
	Address = PutToTempStorage(Object.Goods.Unload(, Columns), UUID);
	
	Return Address;
	
EndFunction

&AtServer
Function PutTablePartOfGoodsInTemporaryStorageToCheckQuantity(OnlyNonLabeledProductsHaveBeenUnloaded = False)
	
	TabularPartProducts = Object.Goods.Unload();
	If TabularPartProducts.Columns.Find("MarkedProducts") <> Undefined Then
		CurrentRowNumber = TabularPartProducts.Count()-1;
		While CurrentRowNumber >= 0 Do
			If TabularPartProducts[CurrentRowNumber].MarkedProducts Then
				TabularPartProducts.Delete(CurrentRowNumber);
				OnlyNonLabeledProductsHaveBeenUnloaded = True;
			EndIf;
			CurrentRowNumber = CurrentRowNumber - 1;
		EndDo;
	EndIf;
	TabularPartProducts.GroupBy("RowCode, SalesOrder, ProductsInSet, ItemVariantOfSet, Products, Characteristic, Series, BatchesIndicationStatus, Warehouse, ItemsType, ItemVariantsAreUsed, Package", "NumberOfPackages");
	AddressInTempStorage = PutToTempStorage(TabularPartProducts, UUID);
	Return AddressInTempStorage;
	
EndFunction

&AtServer
Procedure ChangeTablePartBasedOnResultsOfCheck(ReturnParameters, CachedValues)
	
	GoodsTable = GetFromTempStorage(ReturnParameters.Goods);
	
	LinesToDelete = New Array;
	RowsToProcess = New Array;
	AddedRows = New Array;
	
	For Each SourceRow In GoodsTable Do
		
		Filter = New Structure(
			"RowCode,
			|SalesOrder,
			|ProductsInSet,
			|ItemVariantOfSet,
			|Products,
			|Characteristic,
			|Series,
			|ItemVariantsAreUsed,
			|Warehouse,
			|Package");
		
		FillPropertyValues(Filter, SourceRow);
		FoundRows = Object.Goods.FindRows(Filter);
		For Each TSRow In FoundRows Do
			
			If SourceRow.NumberOfPackages = 0 Then
				Break;
			EndIf;
			
			If SourceRow.NumberOfPackages >= 0 Then
				
				TSRow.NumberOfPackages = TSRow.NumberOfPackages + SourceRow.NumberOfPackages;
				SourceRow.NumberOfPackages = 0;
				
			Else
				
				QuantityToWriteOff = -SourceRow.NumberOfPackages;
				QuantityPerLine   = TSRow.NumberOfPackages;
				
				If QuantityToWriteOff > QuantityPerLine Then
					SourceRow.NumberOfPackages = QuantityPerLine - QuantityToWriteOff;
					TSRow.NumberOfPackages       = 0;
				Else
					SourceRow.NumberOfPackages = 0;
					TSRow.NumberOfPackages       = QuantityPerLine - QuantityToWriteOff;
				EndIf;
				
			EndIf;
			
			If TSRow.NumberOfPackages = 0 Then
				LinesToDelete.Add(TSRow);
			Else
				RowsToProcess.Add(TSRow);
			EndIf;
			
		EndDo;
		If FoundRows.Count() = 0 Then
			
			TSRow = Object.Goods.Add();
			FillPropertyValues(TSRow, SourceRow);
			AddedRows.Add(TSRow);
			
		EndIf;
		
	EndDo;
	
	// processing existing rows
	StructureOfActions = New Structure;
	AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions, Object);
	
	ParametersForFillingInVATAmountLocalManSManSManSManSManSManSManSManS = BatchProcessingOfTablePartClientServer.ParametersForFillingInVATAmountLocalManSManSManSManSManSManSManSManS(
		Object.Currency,
		LocalAccountingCurrency,
		ManagementAccountingCurrency);
	
	StructureOfActions.Insert("SetVATAmountLocalMans", ParametersForFillingInVATAmountLocalManSManSManSManSManSManSManSManS);
	
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		RowsToProcess,
		StructureOfActions,
		Object.Goods,
		CachedValues);
	
	// processing of added rows
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
	StructureOfActions.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));
	StructureOfActions.Insert("FillIn_TermsOfSales",
		BatchProcessingOfTablePartClientServer.GetStructureForFillingInSalesConditionsInTSLine(Object));
		
	StructureOfActions.Insert("FillInVATRate",
		BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRate(Object));
		
	StructureOfActions.Insert("FillInHSCode", Object.VATTaxation);
	StructureOfActions.Insert("FillInVATRateForReturnableContainers", Object.ToReturnReusablePackage);
	StructureOfActions.Insert("FillInNoReturnContainerAttribute", Object.ToReturnReusablePackage);
	StructureOfActions.Insert("CheckFillWarehouse",
		BatchProcessingOfTablePartClientServer.GetWarehouseFillStructureInTSLine(Object, WarehouseGroup_));
		
	StructureOfActions.Insert("WhenChangingProductType",
		New Structure("ThereAreWorks, IsCanceled", True, False));
		
	StructureOfActions.Insert("FillInSubdivisionInTSLine",
		New Structure("Department", Object.Department));
	
	OrdersClientServer.AddActionFillInDiscrepancyOrderAttribute(StructureOfActions, Object.OrderSales);
	
	AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions, Object);
	
	ParametersForFillingInVATAmountLocalManSManSManSManSManSManSManSManS = BatchProcessingOfTablePartClientServer.ParametersForFillingInVATAmountLocalManSManSManSManSManSManSManSManS(
		Object.Currency,
		LocalAccountingCurrency,
		ManagementAccountingCurrency);
	
	StructureOfActions.Insert("SetVATAmountLocalMans", ParametersForFillingInVATAmountLocalManSManSManSManSManSManSManSManS);
	
	LinesOfBusinessClientServer.StructureOfInsertActionsWhenAddingRow(ThisObject, StructureOfActions);
	BatchProcessingOfTablePartClientServerLocalization.CompleteActionStructureWhenChangingElement(
		ThisObject, "Products", StructureOfActions);

	BatchProcessingOfTablePartServer.ProcessTSStrings(
		AddedRows,
		StructureOfActions,
		Object.Goods,
		CachedValues);
	
	For Each TSRow In LinesToDelete Do
		Object.Goods.Delete(TSRow);
	EndDo;
	
	ProductsServer.FillInStatusesForSpecifyingSeries(Object,SeriesSpecificationParameters);
	WhenChangingWarehouseInTablePartServer();
	
	FormEvents.WhenChangingElement(ThisObject, "Goods");
	
EndProcedure

#EndRegion

#Region BarcodesAndTradeEquipment

&AtClient
Procedure ProcessBarcodes(BarcodeData_5)
	
	ClearMessages();
	
	If Not BarcodingOfItemsClient.BarcodesAreValid(BarcodeData_5) Then
		Return;
	EndIf;
	
	ParametersONChangingTypeOfItem = New Structure;
	ParametersONChangingTypeOfItem.Insert("ThereAreWorks", True);
	ParametersONChangingTypeOfItem.Insert("IsCanceled", False);
	ParametersONChangingTypeOfItem.Insert("ThisIsTransferOfOwnership",
		Object.BusinessOperation =
			PredefinedValue("Enum.BusinessTransactions.TransferOfTitleToGoods"));
	
	StructureOfActionsWithAddedStrings = New Structure;
	StructureOfActionsWithAddedStrings.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
	StructureOfActionsWithAddedStrings.Insert("FillInFeatureAttribute", New Structure("Products", "ItemVariantsAreUsed"));
	StructureOfActionsWithAddedStrings.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));
	StructureOfActionsWithAddedStrings.Insert("CheckFillWarehouse", BatchProcessingOfTablePartClientServer.GetWarehouseFillStructureInTSLine(Object, WarehouseGroup_));
	StructureOfActionsWithAddedStrings.Insert("FillInVATRate", BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRate(Object));
	StructureOfActionsWithAddedStrings.Insert("FillInVATRateByPriceType", BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRateByPriceType(Object));
	StructureOfActionsWithAddedStrings.Insert("FillInHSCode", Object.VATTaxation);
	StructureOfActionsWithAddedStrings.Insert("FillInVATRateForReturnableContainers", Object.ToReturnReusablePackage);
	StructureOfActionsWithAddedStrings.Insert("FillInNoReturnContainerAttribute", Object.ToReturnReusablePackage);
	StructureOfActionsWithAddedStrings.Insert("WhenChangingProductType", ParametersONChangingTypeOfItem);
	If (ToUseTermsOfSales And ValueIsFilled(Object.Terms)) 
		Or (Not ToUseTermsOfSales And UsePriceManagementSystem25) Then
		StructureOfActionsWithAddedStrings.Insert("FillIn_TermsOfSales", BatchProcessingOfTablePartClientServer.GetStructureForFillingInSalesConditionsInTSLine(Object));
	Else
		StructureOfActionsWithAddedStrings.Insert("FillInSalePrice", BatchProcessingOfTablePartClientServer.ParametersForFillingInPriceInTSLine(Object));
	EndIf;
	StructureOfActionsWithAddedStrings.Insert("FillInSubdivisionInTSLine", New Structure("Department", Object.Department));
	BatchProcessingOfTablePartClientServerLocalization.CompleteActionStructureWhenChangingElement(ThisObject, "Products", StructureOfActionsWithAddedStrings);
	AddActionsToStructureWhenChangingPackagesNumber(StructureOfActionsWithAddedStrings, Object);
	
	ParametersForFillingInVATAmountLocalManSManSManSManSManSManSManSManS = BatchProcessingOfTablePartClientServer.ParametersForFillingInVATAmountLocalManSManSManSManSManSManSManSManS(
		Object.Currency,
		LocalAccountingCurrency,
		ManagementAccountingCurrency);
	
	StructureOfActionsWithAddedStrings.Insert("SetVATAmountLocalMans", ParametersForFillingInVATAmountLocalManSManSManSManSManSManSManSManS);
	
	StructureOfActionsWithModifiedStrings = New Structure;
	AddActionsToStructureWhenChangingPackagesNumber(StructureOfActionsWithModifiedStrings, Object);
	
	StructureOfActionsWithModifiedStrings.Insert("SetVATAmountLocalMans", ParametersForFillingInVATAmountLocalManSManSManSManSManSManSManSManS);
	
	LinesOfBusinessClientServer.StructureOfInsertActionsWhenAddingRow(ThisObject, StructureOfActionsWithAddedStrings);
	
	GoodsOnly =
		Object.BusinessOperation =
			PredefinedValue("Enum.BusinessTransactions.TransferToCommissionAgent")
		Or Object.BusinessOperation =
			PredefinedValue("Enum.BusinessTransactions.TransferOfTitleToGoods");
	
	StructureOfActions = BarcodingOfItemsClient.BarcodeProcessingParameters();
	StructureOfActions.Barcodes                              = BarcodeData_5;
	StructureOfActions.StructureOfActionsWithAddedStrings = StructureOfActionsWithAddedStrings;
	StructureOfActions.StructureOfActionsWithModifiedStrings  = StructureOfActionsWithModifiedStrings;
	StructureOfActions.SeriesSpecificationParameters                 = SeriesSpecificationParameters;
	StructureOfActions.CalculateSets                     = True;
	StructureOfActions.AddOnlyProductsOverAndAboveOrder        = True;
	StructureOfActions.GoodsOnly                           = GoodsOnly;
	
	ProcessBarcodesServer(StructureOfActions, CachedValues);
	
	BarcodingOfItemsClient.ProcessUnknownBarcodes(StructureOfActions, CachedValues, ThisObject);
	
	If BarcodingOfItemsClient.YouNeedToOpenFormForSpecifyingSeriesAfterProcessingBarcodes(StructureOfActions) Then
		CurDataId = StructureOfActions.ArrayOfRowsWithSeries_[0];
		
		AttachIdleHandler("OpenSeriesSelectionWhenScanningProductBarCode", 0.1, True);
	EndIf;
	
	If StructureOfActions.CurrentRow <> Undefined Then
		Items.Goods.CurrentRow = StructureOfActions.CurrentRow;
	EndIf;
	
	SetWhetherWarehouseIsFull();
	
EndProcedure

&AtServer
Procedure ProcessBarcodesServer(StructureOfActionParameters, CachedValues)
	
	ApplyPaymentWithBonusPoints(, True);
	
	BarcodingOfItemsServer.ProcessBarcodes(ThisObject, Object, StructureOfActionParameters, CachedValues);
	FormEvents.WhenChangingElement(ThisObject, "Goods");
	UpdateOrderDeviations();
	UpdateDependentDetailsOfServerByOrderForm();
	
	CalculateTotals_(ThisObject);
	
EndProcedure

#EndRegion

#Region SetOfSeries

&AtServer
Function FillInSeriesByFEFOServer()
	
	If ProductsServer.ThereAreLinesWithFEFOFilledSeries_(Object.Goods) Then
		ProductsServer.FillInSeriesByFEFO(Object,SeriesSpecificationParameters);
		FormEvents.WhenChangingElement(ThisObject, "Goods");
		Return True;
	Else
		Return False;
	EndIf;
	
EndFunction

&AtServer
Procedure SetVisibilityOfSeriesElements()
	
	Items.GoodsBatchesIndicationStatus.Visible  = SeriesSpecificationParameters.UseItemsBatch;
	Items.GoodsSpecifySeries.Visible         = SeriesSpecificationParameters.UseItemsBatch;
	Items.GoodsFillInSeriesByFEFO.Visible = SeriesSpecificationParameters.UseItemsBatch;
	Items.GoodsSeries.Visible                = SeriesSpecificationParameters.UseItemsBatch;
	
EndProcedure

&AtServer
Procedure ProcessSeriesIndication_Server(ParametersOfSeriesIndicationForm)
	
	ProductsServer.ProcessSeriesIndication_(Object, SeriesSpecificationParameters, ParametersOfSeriesIndicationForm);

EndProcedure

&AtServer
Procedure FillInStatusesOfSpecifyingSeriesWhenEditingLineTS(IDCurrentRow, CachedValues)
	
	ProductsServer.FillInStatusesOfSpecifyingSeriesWhenEditingLineTS(Object,
				SeriesSpecificationParameters, IDCurrentRow, CachedValues);
	
EndProcedure

&AtServer
Procedure FillInStatusesForSpecifyingSeriesServer()
	
	ProductsServer.FillInStatusesForSpecifyingSeries(Object,SeriesSpecificationParameters);
	
EndProcedure

&AtServerNoContext
Function ThereAreFilledSeriesByFEFO(Goods)
	
	Return ProductsServer.ThereAreLinesWithFEFOFilledSeries(Goods);
	
EndFunction

&AtClient
Procedure OpenSeriesSelectionWhenScanningProductBarCode()
	
	If CurDataId = Undefined Then
		Return;
	EndIf;
	
	CurrentData = Object.Goods.FindByID(CurDataId);
	OpenSelectionOfSeries(,CurrentData);
	
EndProcedure

&AtServer
Function ParametersOfSeriesIndicationForm(CurDataId)
	
	Return ProductsServer.ParametersOfSeriesIndicationForm(Object, SeriesSpecificationParameters, CurDataId, ThisForm);
	
EndFunction

&AtClient
Procedure OpenSelectionOfSeries(Text = "", CurrentData = Undefined)
	If ProductsClient.YouNeedServerCallToSpecifySeries(ThisForm,SeriesSpecificationParameters,Text, CurrentData)Then
		If CurrentData = Undefined Then
			CurDataId = Items.Goods.CurrentData.GetID();
		Else
			CurDataId = CurrentData.GetID();
		EndIf;

		ParametersOfSeriesIndicationForm = ParametersOfSeriesIndicationForm(CurDataId);
		
		ReturnValue_1 = Undefined;
		
		OpenForm(ParametersOfSeriesIndicationForm.FormName,ParametersOfSeriesIndicationForm,ThisForm,,,, New CallbackDescription("OpenSelectionOfSeriesCompletion", ThisObject, New Structure("ParametersOfSeriesIndicationForm", ParametersOfSeriesIndicationForm)), FormWindowOpeningMode.LockOwnerWindow);
	EndIf;
EndProcedure

&AtClient
Procedure OpenSelectionOfSeriesCompletion(Result, AdditionalParameters) Export

	ParametersOfSeriesIndicationForm = AdditionalParameters.ParametersOfSeriesIndicationForm;
	ReturnValue_1 = Result;

	If ReturnValue_1 <> Undefined Then
		ProcessSeriesIndication_Server(ParametersOfSeriesIndicationForm);
	EndIf;

	ProductsSeriesRecalculatePrices();
	
EndProcedure

#EndRegion

#Region WorkingWithClipboard

&AtServer
Procedure CopyLinesOnServer()
	
	ProcessingOfTabularForms.CopyRowsToClipboard(Object.Goods, Items.Goods.SelectedRows);
	
EndProcedure

&AtServer
Procedure GetLinesFromClipboard()
	
	If Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.TransferToCommissionAgent") Then
		FilterParameters = New Map;
		FilterParameters.Insert("Products.ItemsType", ProductsClientServer.SelectionByProductMultiTurnContainer());
	Else
		FilterParameters = Undefined;
	EndIf;
	
	Columns = "Products,Characteristic,Package,NumberOfPackages,PriceKind,Price,
		|PercentRateOfManualDiscount,ManualDiscount,Warehouse,Department,ProductsInSet,ItemVariantOfSet";

	TableOfGoods = ProcessingOfTabularForms.RowsFromClipboard(FilterParameters, Columns);

	If Not ValueIsFilled(TableOfGoods) Then
		Return;
	EndIf;

	ParametersONChangingTypeOfItem = New Structure;
	ParametersONChangingTypeOfItem.Insert("ThereAreWorks", True);
	ParametersONChangingTypeOfItem.Insert("IsCanceled", False);
	ParametersONChangingTypeOfItem.Insert("ThisIsTransferOfOwnership",
		Object.BusinessOperation =
			PredefinedValue("Enum.BusinessTransactions.TransferOfTitleToGoods"));

	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
	StructureOfActions.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));
	StructureOfActions.Insert("CheckFillWarehouse",
		BatchProcessingOfTablePartClientServer.GetWarehouseFillStructureInTSLine(Object, WarehouseGroup_));
		
	StructureOfActions.Insert("FillInVATRate", BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRate(Object));
	StructureOfActions.Insert("FillInVATRateByPriceType", BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRateByPriceType(Object));
	StructureOfActions.Insert("FillInHSCode", Object.VATTaxation);
	StructureOfActions.Insert("FillInNoReturnContainerAttribute", Object.ToReturnReusablePackage);
	StructureOfActions.Insert("FillInVATRateForReturnableContainers", Object.ToReturnReusablePackage);
	StructureOfActions.Insert("FillInNoReturnContainerAttribute", Object.ToReturnReusablePackage);
	StructureOfActions.Insert("WhenChangingProductType", ParametersONChangingTypeOfItem);
	LinesOfBusinessClientServer.StructureOfInsertActionsWhenAddingRow(ThisObject, StructureOfActions);
	AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions, Object);
	
	ParametersForFillingInVATAmountLocalManSManSManSManSManSManSManSManS = BatchProcessingOfTablePartClientServer.ParametersForFillingInVATAmountLocalManSManSManSManSManSManSManSManS(
		Object.Currency,
		LocalAccountingCurrency,
		ManagementAccountingCurrency);
	
	StructureOfActions.Insert("SetVATAmountLocalMans", ParametersForFillingInVATAmountLocalManSManSManSManSManSManSManSManS);
	
	BatchProcessingOfTablePartClientServerLocalization.CompleteActionStructureWhenChangingElement(
		ThisObject, "Products", StructureOfActions);
	
	ParametersForFillingInPriceType = BatchProcessingOfTablePartClientServer.ParametersForFillingInPriceTypeInTSLine("PriceKind");
	ParametersForFillingInPriceType.FilterParameters.PriceIncludesVAT = Object.PriceIncludesVAT;
	ParametersForFillingInPriceType.FilterParameters.UseWhileSellingToCustomers = True;
	StructureOfActions.Insert("CheckFillInPriceView", ParametersForFillingInPriceType);
	OrdersClientServer.AddActionFillInDiscrepancyOrderAttribute(StructureOfActions, Object.OrderSales);
	
	StructureOfActions.Insert("FillInSalePrice",
		BatchProcessingOfTablePartClientServer.ParametersForFillingInPriceInTSLine(Object));
		
	RowsToProcess = New Array;
		
	For Each RowOfProduct In TableOfGoods Do
		
		CurrentRow = Object.Goods.Add();
		FillPropertyValues(CurrentRow, RowOfProduct);
		If Not UseDiscountAdjustmentsInSales Then
			CurrentRow.PercentRateOfManualDiscount = 0;
			CurrentRow.ManualDiscount = 0;
		EndIf;
		RowsToProcess.Add(CurrentRow);
		
	EndDo;
	
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		RowsToProcess,
		StructureOfActions,
		Object.Goods);
	
	CalculateTotals_(ThisObject);
	FillInServiceDetailsForProductRange();
	WhenChangingWarehouseInTablePartServer();
	ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);
	
	ReusablePackageServer.UpdateFillingStateOfMultiTurnContainer(Object.ReusablePackageFillingStatus);
	
EndProcedure

&AtServer
Procedure SetAvailabilityOfClipboardCommands()
	
	ItemArray = New Array();
	ItemArray.Add("GoodsInsertRows");
	ItemArray.Add("GoodsContextMenuInsertRows");
	
	TMCommonUseClientServer.SetPropertyOfFormElements(Items, ItemArray, "Enabled",
		ProcessingOfTabularForms.ThereAreLinesInClipboard() And (Not Object.OrderSales Or SalesInExcessOfOrder));

EndProcedure

&AtClient
Procedure SetAvailabilityOfClipboardCommandsOnClient()
	
	ItemArray = New Array();
	ItemArray.Add("GoodsInsertRows");
	ItemArray.Add("GoodsContextMenuInsertRows");
	
	TMCommonUseClientServer.SetPropertyOfFormElements(Items, ItemArray, "Enabled",
		Not Object.OrderSales Or SalesInExcessOfOrder);
	
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
	Columns.Add("Package");
	Columns.Add("Count");
	Columns.Add("NumberOfPackages");
	
	If Form.Object.BusinessOperation <> PredefinedValue("Enum.BusinessTransactions.TransferToCommissionAgent")
		And Not Form.SalesViaCommissionAgent Then
		If Form.UseDiscountAdjustmentsInSales Then
			Columns.Add("PercentRateOfManualDiscount");
			Columns.Add("ManualDiscount");
		EndIf;
		If Form.UseDiscountsMarkupsInSales Then
			Columns.Add("PercentRateOfAutomaticDiscountMarkup");
			Columns.Add("DiscountMarkupAmount");
		EndIf;
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
		SetsClient.WhenRemovingComponents(ThisForm, "Goods", AdditionalParameter);
	ElsIf SetsClient.DeleteEntireSetAction(Action) Then
		WhenRemovingComponentsOnServer("Goods", AdditionalParameter);
	EndIf;
	
	UpdateDependentDetailsOfOrderForm_(ThisObject, DiscrepancyOrderText);
	
	CalculateTotals_(ThisObject)
	
EndProcedure

&AtServer
Procedure WhenRemovingComponentsOnServer(TSName, AdditionalParameter)
	
	SetsServer.WhenRemovingComponents(ThisForm, TSName, AdditionalParameter);
	
	UpdateOrderInformation();
	
	StructureOfActions = New Structure;
	OrdersClientServer.AddActionFillInDiscrepancyOrderAttribute(StructureOfActions, Object.OrderSales);
	BatchProcessingOfTablePartServer.TreatTS(
		Object[TSName],
		StructureOfActions);
	
EndProcedure

&AtServer
Function SetAddressInTemporaryStorage(Var_Parameters)
	
	Return SetsServer.SetAddressInTemporaryStorage(ThisForm, Var_Parameters, "Goods");
	
EndFunction

&AtServer
Procedure AtEndOfEditingSet(AddressInTempStorage)
	
	ParametersONChangingTypeOfItem = New Structure;
	ParametersONChangingTypeOfItem.Insert("ThereAreWorks", True);
	ParametersONChangingTypeOfItem.Insert("IsCanceled", False);
	ParametersONChangingTypeOfItem.Insert("ThisIsTransferOfOwnership",
		Object.BusinessOperation =
			PredefinedValue("Enum.BusinessTransactions.TransferOfTitleToGoods"));
	
	ParametersForFillingInVATAmountLocalManSManSManSManSManSManSManSManS = BatchProcessingOfTablePartClientServer.ParametersForFillingInVATAmountLocalManSManSManSManSManSManSManSManS(
		Object.Currency,
		LocalAccountingCurrency,
		ManagementAccountingCurrency);
	
	StructureOfActionsWithModifiedStrings = New Structure;
	StructureOfActionsWithModifiedStrings.Insert("FillInDuplicateDependentDetails", DependentDetails());
	StructureOfActionsWithModifiedStrings.Insert("ClearAmountOfSettlements");
	StructureOfActionsWithModifiedStrings.Insert("SetVATAmountLocalMans", ParametersForFillingInVATAmountLocalManSManSManSManSManSManSManSManS);
	
	StructureOfActionsWithAddedStrings = New Structure;
	StructureOfActionsWithAddedStrings.Insert("CheckFillWarehouse", BatchProcessingOfTablePartClientServer.GetWarehouseFillStructureInTSLine(Object, WarehouseGroup_));
	StructureOfActionsWithAddedStrings.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
	StructureOfActionsWithAddedStrings.Insert("FillInFeatureAttribute", New Structure("Products", "ItemVariantsAreUsed"));
	StructureOfActionsWithAddedStrings.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));
	StructureOfActionsWithAddedStrings.Insert("CheckFillWarehouse", BatchProcessingOfTablePartClientServer.GetWarehouseFillStructureInTSLine(Object, WarehouseGroup_));
	StructureOfActionsWithAddedStrings.Insert("FillInNoReturnContainerAttribute", Object.ToReturnReusablePackage);
	StructureOfActionsWithAddedStrings.Insert("FillInDuplicateDependentDetails", DependentDetails());
	StructureOfActionsWithAddedStrings.Insert("ClearAmountOfSettlements");
	StructureOfActionsWithAddedStrings.Insert("SetVATAmountLocalMans", ParametersForFillingInVATAmountLocalManSManSManSManSManSManSManSManS);
	StructureOfActionsWithAddedStrings.Insert("WhenChangingProductType", ParametersONChangingTypeOfItem);
	StructureOfActionsWithAddedStrings.Insert("FillInSubdivisionInTSLine", New Structure("Department", Object.Department));
	BatchProcessingOfTablePartClientServerLocalization.CompleteActionStructureWhenChangingElement(
		ThisObject, "Products", StructureOfActionsWithAddedStrings);
	
	DataParameters = New Structure;
	DataParameters.Insert("Data", GetFromTempStorage(AddressInTempStorage));
	DataParameters.Insert("StructureOfActionsWithModifiedStrings", StructureOfActionsWithModifiedStrings);
	DataParameters.Insert("StructureOfActionsWithAddedStrings", StructureOfActionsWithAddedStrings);
	DataParameters.Insert("DialColumns", DialColumns(ThisForm));
	DataParameters.Insert("ExceedingOrder", True);
	
	SetsServer.AtEndOfEditingSet(ThisForm, "Goods", DataParameters);
	
	UpdateOrderDeviations();
	
	FormEvents.WhenChangingElement(ThisObject, "Goods");
	
	CalculateTotals_(ThisObject)
	
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
Procedure SetUncheckSeparately(Set)
	LinesOfBusinessServer.SetUncheckSeparately(ThisObject, Set);
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
	ParametersOfAccount.Currency = LocalAccountingCurrency;
	
	Return CashServer.GetOrganizationSDefaultBankAccount(ParametersOfAccount,
		Object.CompanyBankAccount);
	
EndFunction

&AtClientAtServerNoContext
Function GetBusinessTransaction(BusinessOperation)
	
	ContractBusinessTransaction = BusinessOperation;
	
	If BusinessOperation = PredefinedValue("Enum.BusinessTransactions.SaleToCustomerLocalAccounting") 
		Or BusinessOperation = PredefinedValue("Enum.BusinessTransactions.SaleWithDeferredTransferOfTitle")
		Or BusinessOperation = PredefinedValue("Enum.BusinessTransactions.TransferOfTitleToGoods") Then
		ContractBusinessTransaction = PredefinedValue("Enum.BusinessTransactions.SaleToCustomer");
	ElsIf BusinessOperation = PredefinedValue("Enum.BusinessTransactions.SalesViaCommissionAgent") 
		Or BusinessOperation = PredefinedValue("Enum.BusinessTransactions.SalesViaCommissionAgentGoodsInTransit") Then
		ContractBusinessTransaction = PredefinedValue("Enum.BusinessTransactions.TransferToCommissionAgent");
	EndIf;
	
	Return ContractBusinessTransaction;
	
EndFunction

&AtClientAtServerNoContext
Procedure AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions, Object, StructureOfFillingBonusPoints = Undefined)
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	
	StructureOfActions.Insert("RecalculateNumberOfUnits");
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmount");
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountManualDiscount", New Structure("Clear", False));
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountAutomaticDiscount", New Structure("Clear", True));
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountDiscountWithBonusPoints", StructureOfFillingBonusPoints);
	StructureOfActions.Insert("FillInDuplicateDependentDetails", DependentDetails());
	StructureOfActions.Insert("ClearAmountOfSettlements");
	
EndProcedure

&AtServer
Procedure UpdateOrderInformation()
	
	ParametersOfUpdate = OrdersServer.ParametersForUpdatingOrderInformationInForm();
	
	ParametersOfUpdate.PropsNameOrderList         = "OrderList";
	ParametersOfUpdate.OrderPathInHeader                  = "Object.SalesOrder";
	ParametersOfUpdate.TitleLabelName               = "HeaderOrdersText";
	ParametersOfUpdate.NameOfColumnGroupInTableSection   = "GoodsGroupSalesOrder";
	ParametersOfUpdate.OrderNameInTablePart          = "SalesOrder";
	ParametersOfUpdate.UseOrdersInTabularSection = UseSaleByMultipleOrders;
	
	OrdersServer.UpdateOrderInformationInForm(ThisForm, Object.Goods, ParametersOfUpdate);
	
	UseAdvancedFeaturesOfSalesOrder = UseAdvancedFeaturesOfSalesOrder();
	
	SetVisibilityOfCommandsByOrder();
	
EndProcedure

&AtServer
Procedure FillInDefaultContract()
	
	SettlementCurrencyForContract = ?(SalesViaCommissionAgent, Undefined, Object.ARAPCurrency);
	
	If Object.ARAPObjectSettings = Enums.ARAPObjectSettings.ByCounterpartyContracts Then
	
		Contract = SalesServer.GetDefaultContract(Object, 
															ContractBusinessTransaction, 
															SettlementCurrencyForContract, 
															Object.LineOfBusiness,
															SalesViaCommissionAgent);
	Else
															
		Contract = SalesServer.GetDefaultContract(Object, 
															ContractBusinessTransaction, 
															SettlementCurrencyForContract,
															,
															SalesViaCommissionAgent);
	EndIf;
	
	If Contract <> Object.Contract Then
		
		Object.Contract = Contract;
		ForeignCurrencyTransaction = Object.ForeignCurrencyTransaction;
		FillBaseForPrinting();
		ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisObject, "Contract");
		If ForeignCurrencyTransaction <> Object.ForeignCurrencyTransaction Then
			Object.CompanyBankAccount = Catalogs.CompaniesBankAccounts.EmptyRef();
		EndIf;
		SalesServer.FillInBankAccountsUnderAgreement(
			Object.Contract, Object.CompanyBankAccount, Object.CounterpartyBankAccount);
		Object.MarkedProductOutflowOption = Common.ObjectAttributeValue(Object.Contract, "MarkedProductOutflowOption");
		
	EndIf;
	
	FillInPriceTypeUnderAgreement();
	
EndProcedure

&AtServer
Procedure FillInDefaultEndClientContract()
	
	If SalesViaCommissionAgent Then
		Object.CustomerContract = ConsignmentSalesServer.GetDefaultContract(Object, 
															Enums.BusinessTransactions.SalesViaCommissionAgent);
		ClientAgreesOnChangeOnServer();
	EndIf;
	
EndProcedure

&AtServer
Procedure FillInFromOrderServer()
	
	Object.Goods.Clear();
	
	If UseSaleByMultipleOrders Then
		AnArrayOfOrders = Undefined;
	Else
		AnArrayOfOrders = New Array();
		AnArrayOfOrders.Add(Object.SalesOrder);
	EndIf;
	FillParameters = New Structure;
	FillParameters.Insert("DisplayMessage_1", False);
	FillParameters.Insert("UseAdvancedFeaturesOfSalesOrder", UseAdvancedFeaturesOfSalesOrder);
	
	Documents.CustomerInvoice.FillByOrderBalances(
		Object,
		Object.Goods,
		Object.DiscountsMarkups,
		Object.BonusPointAccrual,
		Warehouse,
		AnArrayOfOrders,
		FillParameters,
		Object.PackageBarcodes);
	
	UpdateOrderInformation();
	
	ARAPAccountingFormWork.WhenChangingParametersOfMechanism(ThisObject);
	
	CustomerInvoiceLocalization.FillInCacheOfBarcodesOfPackages(ThisObject);
	FillInServiceDetailsForProductRange();
	
	ReusablePackageServer.UpdateNoReturnableContainerAttribute(Object.Goods, Object.ToReturnReusablePackage);
	TMCommonUse.FillInDuplicateDependentPropsInCollection(Object.Goods, DependentDetails());
	WhenChangingWarehouseInTablePartServer();
	CalculateTotals_(ThisObject);
	
	SeriesSpecificationParameters = New FixedStructure(ProductsServer.SeriesSpecificationParameters(Object, Documents.CustomerInvoice));
	ProductsServer.FillInStatusesForSpecifyingSeries(Object,SeriesSpecificationParameters);
	
	FillBaseForPrinting();
	Object.DiscountsAreCalculated = True;
	
EndProcedure

&AtServer
Function BindImplementationStringsToCustomerOrders(SelectByOrder_)
	
	If (Not GetFunctionalOption("UseSalesOrders")
		And Not GetFunctionalOption("UseRequestsForReturnOfGoodsFromCustomers")) Or
		(Not GetFunctionalOption("UseSaleByMultipleOrders")
		And Not ValueIsFilled(Object.SalesOrder)) Then
		
		Return False;
		
	EndIf;

	Query = New Query("
		|SELECT
		|	Goods.Products   AS Products,
		|	Goods.Characteristic AS Characteristic
		|INTO Goods
		|FROM
		|	&Goods AS Goods
		|;
		|
		|//////////////////////////////////////////////////////////////////////////////// 1
		|SELECT
		|	CASE
		|		WHEN OrdersTable.SalesOrder REFS Document.SalesOrder
		|			THEN CAST(OrdersTable.SalesOrder AS Document.SalesOrder).SalesOpportunity
		|		WHEN OrdersTable.SalesOrder REFS Document.RequestForReturnOfGoodsFromCustomer
		|			THEN CAST(OrdersTable.SalesOrder AS Document.RequestForReturnOfGoodsFromCustomer).SalesOpportunity
		|		WHEN OrdersTable.SalesOrder REFS Document.GoodsShipmentToCustomer
		|			THEN CAST(OrdersTable.SalesOrder AS Document.GoodsShipmentToCustomer).SalesOpportunity
		|		ELSE
		|			VALUE(Catalog.SalesOpportunitiesToCustomer.EmptyRef)
		|	END                                      AS SalesOpportunity,
		|	OrdersTable.SalesOrder                 AS SalesOrder,
		|	OrdersTable.ARAPObjectSettings              AS ARAPObjectSettings,
		|	OrdersTable.Products                 AS Products,
		|	OrdersTable.Characteristic               AS Characteristic,
		|	OrdersTable.RowCode                    AS RowCode,
		|	OrdersTable.Warehouse                        AS Warehouse,
		|	OrdersTable.Series                        AS Series,
		|	SUM(OrdersTable.ForRegistrationQuantity) AS ForRegistrationQuantity,
		|	SUM(OrdersTable.AmountToBeProcessed)      AS AmountToBeProcessed
		|INTO SalesOrders
		|FROM
		|	(SELECT
		|		VALUE(Document.GoodsShipmentToCustomer.EmptyRef) AS SalesOrder,
		|		VALUE(Enum.ARAPObjectSettings.EmptyRef) AS ARAPObjectSettings,
		|		VALUE(Catalog.Products.EmptyRef) AS Products,
		|		VALUE(Catalog.ItemsCharacteristics.EmptyRef) AS Characteristic,
		|		0 AS RowCode,
		|		VALUE(Catalog.Warehouses.EmptyRef) AS Warehouse,
		|		VALUE(Catalog.ItemsBatches.EmptyRef) AS Series,
		|		0 AS ForRegistrationQuantity,
		|		0 AS AmountToBeProcessed,
		|		0 AS VATAmountCompl,
		|		0 AS VATAmountMan
		|	FROM
		|		Document.GoodsShipmentToCustomer.Goods AS GoodsTable
		|	WHERE
		|		FALSE
		|
		|	UNION ALL
		|
		// 1. We take the Balance for registration by order, if BT <> Transfer of ownership
		|	SELECT
		|		TurnoversByOrders.ReferenceOrder AS SalesOrder,
		|		CASE
		|			WHEN TurnoversByOrders.ReferenceOrder REFS Document.SalesOrder
		|				THEN CAST(TurnoversByOrders.ReferenceOrder AS Document.SalesOrder).ARAPObjectSettings
		|			WHEN TurnoversByOrders.ReferenceOrder REFS Document.RequestForReturnOfGoodsFromCustomer
		|				THEN CAST(TurnoversByOrders.ReferenceOrder AS Document.RequestForReturnOfGoodsFromCustomer).ARAPObjectSettings
		|			WHEN TurnoversByOrders.ReferenceOrder REFS Document.SourceDocument
		|				THEN CAST(TurnoversByOrders.ReferenceOrder AS Document.SourceDocument).ARAPObjectSettings
		|			ELSE
		|				VALUE(Enum.ARAPObjectSettings.EmptyRef)
		|		END AS ARAPObjectSettings,
		|		TurnoversByOrders.Products AS Products,
		|		TurnoversByOrders.Characteristic AS Characteristic,
		|		TurnoversByOrders.RowCode AS RowCode,
		|		MAX(TurnoversByOrders.Warehouse) AS Warehouse,
		|		MAX(TurnoversByOrders.Series) AS Series,
		|		SUM(TurnoversByOrders.QuantityToBeShipped
		|			- TurnoversByOrders.ShippedQuantity) AS ForRegistrationQuantity,
		|		SUM(TurnoversByOrders.AmountToBeShipped
		|			- TurnoversByOrders.ShippedAmount) AS AmountToBeProcessed,
		|		SUM(TurnoversByOrders.IssuedInvoicesVATAmountLocal
		|			- TurnoversByOrders.IssuedVATAmountLocal) AS VATAmountCompl,
		|		SUM(TurnoversByOrders.IssuedInvoicesVATAmountMan
		|			- TurnoversByOrders.IssuedVATAmountMan) AS VATAmountMan
		|	FROM
		|		(
		|			SELECT
		|				TableRevolutions.ReferenceOrder AS ReferenceOrder,
		|				TableRevolutions.Products AS Products,
		|				TableRevolutions.Characteristic AS Characteristic,
		|				TableRevolutions.RowCode AS RowCode,
		|				TableRevolutions.Warehouse AS Warehouse,
		|				TableRevolutions.Series AS Series,
		|				CASE
		|					WHEN TableRevolutions.Factor = VALUE(Enum.IndicatorsOfShipmentAndReturnReferences.ToShip)
		|						THEN TableRevolutions.CountTurnover
		|					ELSE
		|						0
		|				END AS QuantityToBeShipped,
		|				CASE
		|					WHEN TableRevolutions.Factor = VALUE(Enum.IndicatorsOfShipmentAndReturnReferences.ToShip)
		|						THEN TableRevolutions.SumTurnover
		|					ELSE
		|						0
		|				END AS AmountToBeShipped,
		|				CASE
		|					WHEN TableRevolutions.Factor = VALUE(Enum.IndicatorsOfShipmentAndReturnReferences.Shipped)
		|						THEN TableRevolutions.CountTurnover
		|					ELSE
		|						0
		|				END AS ShippedQuantity,
		|				CASE
		|					WHEN TableRevolutions.Factor = VALUE(Enum.IndicatorsOfShipmentAndReturnReferences.Shipped)
		|						THEN TableRevolutions.SumTurnover
		|					ELSE
		|						0
		|				END AS ShippedAmount,
		|				CASE
		|					WHEN TableRevolutions.Factor = VALUE(Enum.IndicatorsOfShipmentAndReturnReferences.Issued_1)
		|						THEN TableRevolutions.VATAmountManTurnover
		|					ELSE
		|						0
		|				END AS IssuedVATAmountMan,
		|				CASE
		|					WHEN TableRevolutions.Factor = VALUE(Enum.IndicatorsOfShipmentAndReturnReferences.Issued_1)
		|						THEN TableRevolutions.VATAmountComplTurnover
		|					ELSE
		|						0
		|				END AS IssuedVATAmountLocal,
		|				CASE
		|					WHEN TableRevolutions.Factor = VALUE(Enum.IndicatorsOfShipmentAndReturnReferences.TaxInvoicesRegistered)
		|						THEN TableRevolutions.VATAmountManTurnover
		|					ELSE
		|						0
		|				END AS IssuedInvoicesVATAmountMan,
		|				CASE
		|					WHEN TableRevolutions.Factor = VALUE(Enum.IndicatorsOfShipmentAndReturnReferences.TaxInvoicesRegistered)
		|						THEN TableRevolutions.VATAmountComplTurnover
		|					ELSE
		|						0
		|				END AS IssuedInvoicesVATAmountLocal
		|				FROM
		|					AccumulationRegister.ShipmentAndReturnReferences.Turnovers(
		|						,
		|						,
		|						,
		|						CASE
		|							WHEN &SelectByOrder_
		|								THEN ReferenceOrder = &SalesOrder
		|							WHEN ReferenceOrder REFS Document.SalesOrder
		|								THEN
		|									CAST(ReferenceOrder AS Document.SalesOrder).Partner = &Partner
		|									AND CAST(ReferenceOrder AS Document.SalesOrder).Counterparty = &Counterparty
		|									AND CAST(ReferenceOrder AS Document.SalesOrder).Contract = &Contract
		|									AND CAST(ReferenceOrder AS Document.SalesOrder).Organization = &Organization
		|									AND CAST(ReferenceOrder AS Document.SalesOrder).BusinessOperation IN (&EconomicOperationsOfOrders)
		|									AND (NOT &ToUseTermsOfSales
		|										OR CAST(ReferenceOrder AS Document.SalesOrder).Terms = &Terms)
		|									AND CAST(ReferenceOrder AS Document.SalesOrder).SalesOpportunity = &SalesOpportunity
		|									AND (CAST(ReferenceOrder AS Document.SalesOrder).Currency = &ARAPCurrency
		|										OR &BusinessOperation = VALUE(Enum.BusinessTransactions.TransferToCommissionAgent))
		|									AND CASE
		|										WHEN CAST(ReferenceOrder AS Document.SalesOrder).VATTaxation IN (
		|														VALUE(Enum.VATTaxationTypes.ExportOfCommoditiesServicesWorks),
		|														VALUE(Enum.VATTaxationTypes.ExportOfNonResourceGoods)
		|														)
		|											THEN VALUE(Enum.VATTaxationTypes.ExportSale)
		|										ELSE
		|											CAST(ReferenceOrder AS Document.SalesOrder).VATTaxation
		|										END = &VATTaxation
		|									AND CAST(ReferenceOrder AS Document.SalesOrder).PriceIncludesVAT = &PriceIncludesVAT
		|									AND CAST(ReferenceOrder AS Document.SalesOrder).PackageDepositIsRequired = &PackageDepositIsRequired
		|									AND (NOT &UseLinesOfBusiness
		|										OR CAST(ReferenceOrder AS Document.SalesOrder).LineOfBusiness = &LineOfBusiness)
		|							WHEN ReferenceOrder REFS Document.RequestForReturnOfGoodsFromCustomer
		|								THEN
		|									CAST(ReferenceOrder AS Document.RequestForReturnOfGoodsFromCustomer).Partner = &Partner
		|									AND CAST(ReferenceOrder AS Document.RequestForReturnOfGoodsFromCustomer).Counterparty = &Counterparty
		|									AND CAST(ReferenceOrder AS Document.RequestForReturnOfGoodsFromCustomer).Contract = &Contract
		|									AND CAST(ReferenceOrder AS Document.RequestForReturnOfGoodsFromCustomer).Organization = &Organization
		|									AND CAST(ReferenceOrder AS Document.RequestForReturnOfGoodsFromCustomer).BusinessOperation IN (&EconomicOperationsOfOrders)
		|									AND (NOT &ToUseTermsOfSales
		|										OR CAST(ReferenceOrder AS Document.RequestForReturnOfGoodsFromCustomer).Terms = &Terms)
		|									AND CAST(ReferenceOrder AS Document.RequestForReturnOfGoodsFromCustomer).SalesOpportunity = &SalesOpportunity
		|									AND (CAST(ReferenceOrder AS Document.RequestForReturnOfGoodsFromCustomer).Currency = &ARAPCurrency
		|										OR &BusinessOperation = VALUE(Enum.BusinessTransactions.TransferToCommissionAgent))
		|									AND CASE
		|										WHEN CAST(ReferenceOrder AS Document.RequestForReturnOfGoodsFromCustomer).VATTaxation IN (
		|														VALUE(Enum.VATTaxationTypes.ExportOfCommoditiesServicesWorks),
		|														VALUE(Enum.VATTaxationTypes.ExportOfNonResourceGoods)
		|														)
		|											THEN VALUE(Enum.VATTaxationTypes.ExportSale)
		|										ELSE
		|											CAST(ReferenceOrder AS Document.RequestForReturnOfGoodsFromCustomer).VATTaxation
		|										END = &VATTaxation
		|									AND CAST(ReferenceOrder AS Document.RequestForReturnOfGoodsFromCustomer).PriceIncludesVAT = &PriceIncludesVAT
		|									AND CAST(ReferenceOrder AS Document.RequestForReturnOfGoodsFromCustomer).PackageDepositIsRequired = &PackageDepositIsRequired
		|									AND (NOT &UseLinesOfBusiness
		|										OR CAST(ReferenceOrder AS Document.RequestForReturnOfGoodsFromCustomer).LineOfBusiness = &LineOfBusiness)
		|						END
		|						AND CASE
		|							WHEN CAST(&Warehouse AS Catalog.Warehouses).IsFolder
		|								THEN Warehouse IN HIERARCHY (&Warehouse)
		|									OR Warehouse = VALUE(Catalog.Warehouses.EmptyRef)
		|							ELSE
		|								Warehouse IN (
		|									VALUE(Catalog.Warehouses.EmptyRef),
		|									&Warehouse
		|									)
		|						END
		|						AND Products.SaleRegistrationOption IN (
		|									VALUE(Enum.SalesRegistrationOptions.CustomerInvoice),
		|									VALUE(Enum.SalesRegistrationOptions.DeedOfTransfer)
		|									)
		|						AND (Products, Characteristic) IN
		|							(SELECT
		|								Goods.Products AS Products,
		|								Goods.Characteristic AS Characteristic
		|							FROM
		|								Goods AS Goods
		|							)
		|						AND Factor IN (
		|								VALUE(Enum.IndicatorsOfShipmentAndReturnReferences.ToShip),
		|								VALUE(Enum.IndicatorsOfShipmentAndReturnReferences.Shipped),
		|								VALUE(Enum.IndicatorsOfShipmentAndReturnReferences.Issued_1),
		|								VALUE(Enum.IndicatorsOfShipmentAndReturnReferences.TaxInvoicesRegistered)
		|								)
		|			) AS TableRevolutions
		|		) AS TurnoversByOrders
		|	WHERE
		|		&BusinessOperation <> VALUE(Enum.BusinessTransactions.TransferOfTitleToGoods)
		|
		|	GROUP BY
		|		TurnoversByOrders.ReferenceOrder,
		|		CASE
		|			WHEN TurnoversByOrders.ReferenceOrder REFS Document.SalesOrder
		|				THEN CAST(TurnoversByOrders.ReferenceOrder AS Document.SalesOrder).ARAPObjectSettings
		|			WHEN TurnoversByOrders.ReferenceOrder REFS Document.RequestForReturnOfGoodsFromCustomer
		|				THEN CAST(TurnoversByOrders.ReferenceOrder AS Document.RequestForReturnOfGoodsFromCustomer).ARAPObjectSettings
		|			ELSE
		|				VALUE(Enum.ARAPObjectSettings.EmptyRef)
		|		END,
		|		TurnoversByOrders.Products,
		|		TurnoversByOrders.Characteristic,
		|		TurnoversByOrders.RowCode
		|
		|	HAVING
		|		SUM(TurnoversByOrders.QuantityToBeShipped
		|			- TurnoversByOrders.ShippedQuantity) <> 0
		|			OR SUM(TurnoversByOrders.AmountToBeShipped
		|				- TurnoversByOrders.ShippedAmount) <> 0
		|			OR SUM(TurnoversByOrders.IssuedInvoicesVATAmountLocal
		|				- TurnoversByOrders.IssuedVATAmountLocal) <> 0
		|			OR SUM(TurnoversByOrders.IssuedInvoicesVATAmountMan
		|				- TurnoversByOrders.IssuedVATAmountMan) <> 0
		|
		|UNION ALL
		|
		// 2. We take the Balance for registration by order, if BT = Transfer of ownership
		|	SELECT
		|		TurnoversByOrders.ReferenceOrder AS SalesOrder,
		|		CASE
		|			WHEN TurnoversByOrders.ReferenceOrder REFS Document.SalesOrder
		|				THEN CAST(TurnoversByOrders.ReferenceOrder AS Document.SalesOrder).ARAPObjectSettings
		|			WHEN TurnoversByOrders.ReferenceOrder REFS Document.RequestForReturnOfGoodsFromCustomer
		|				THEN CAST(TurnoversByOrders.ReferenceOrder AS Document.RequestForReturnOfGoodsFromCustomer).ARAPObjectSettings
		|			WHEN TurnoversByOrders.ReferenceOrder REFS Document.SourceDocument
		|				THEN CAST(TurnoversByOrders.ReferenceOrder AS Document.SourceDocument).ARAPObjectSettings
		|			ELSE
		|				VALUE(Enum.ARAPObjectSettings.EmptyRef)
		|		END AS ARAPObjectSettings,
		|		TurnoversByOrders.Products AS Products,
		|		TurnoversByOrders.Characteristic AS Characteristic,
		|		TurnoversByOrders.RowCode AS RowCode,
		|		VALUE(Catalog.Warehouses.EmptyRef) AS Warehouse,
		|		MAX(TurnoversByOrders.Series) AS Series,
		|		SUM(TurnoversByOrders.ShippedQuantity
		|			+ TurnoversByOrders.RegisteredUpToPPPQuantity
		|			- TurnoversByOrders.DeductedToPPPQuantity
		|			- TurnoversByOrders.QuantityAccepted_
		|			- TurnoversByOrders.IssuedQuantity) AS ForRegistrationQuantity,
		|		SUM(TurnoversByOrders.ShippedAmount
		|			+ TurnoversByOrders.RegisteredUpToPPPAmount
		|			- TurnoversByOrders.DebitedToPPPAmount
		|			- TurnoversByOrders.AcceptedAmount
		|			- TurnoversByOrders.IssuedAmount) AS AmountToBeProcessed,
		|		SUM(TurnoversByOrders.IssuedInvoicesVATAmountLocal
		|			- TurnoversByOrders.IssuedVATAmountLocal) AS VATAmountCompl,
		|		SUM(TurnoversByOrders.IssuedInvoicesVATAmountMan
		|			- TurnoversByOrders.IssuedVATAmountMan) AS VATAmountMan
		|	FROM
		|		(
		|			SELECT
		|				TableRevolutions.ReferenceOrder AS ReferenceOrder,
		|				TableRevolutions.Products AS Products,
		|				TableRevolutions.Characteristic AS Characteristic,
		|				TableRevolutions.RowCode AS RowCode,
		|				TableRevolutions.Series AS Series,
		|				CASE
		|					WHEN TableRevolutions.Factor = VALUE(Enum.IndicatorsOfShipmentAndReturnReferences.Shipped)
		|						THEN TableRevolutions.CountTurnover
		|					ELSE
		|						0
		|				END AS ShippedQuantity,
		|				CASE
		|					WHEN TableRevolutions.Factor = VALUE(Enum.IndicatorsOfShipmentAndReturnReferences.Shipped)
		|						THEN TableRevolutions.SumTurnover
		|					ELSE
		|						0
		|				END AS ShippedAmount,
		|				CASE
		|					WHEN TableRevolutions.Factor = VALUE(Enum.IndicatorsOfShipmentAndReturnReferences.ReceivedBeforeTransferOfTitleToGoods)
		|						THEN TableRevolutions.CountTurnover
		|					ELSE
		|						0
		|				END AS RegisteredUpToPPPQuantity,
		|				CASE
		|					WHEN TableRevolutions.Factor = VALUE(Enum.IndicatorsOfShipmentAndReturnReferences.ReceivedBeforeTransferOfTitleToGoods)
		|						THEN TableRevolutions.SumTurnover
		|					ELSE
		|						0
		|				END AS RegisteredUpToPPPAmount,
		|				CASE
		|					WHEN TableRevolutions.Factor = VALUE(Enum.IndicatorsOfShipmentAndReturnReferences.WrittenOffBeforeTransferOfTitleToGoods)
		|						THEN TableRevolutions.CountTurnover
		|					ELSE
		|						0
		|				END AS DeductedToPPPQuantity,
		|				CASE
		|					WHEN TableRevolutions.Factor = VALUE(Enum.IndicatorsOfShipmentAndReturnReferences.WrittenOffBeforeTransferOfTitleToGoods)
		|						THEN TableRevolutions.SumTurnover
		|					ELSE
		|						0
		|				END AS DebitedToPPPAmount,
		|				CASE
		|					WHEN TableRevolutions.Factor = VALUE(Enum.IndicatorsOfShipmentAndReturnReferences.ForReceiving)
		|						THEN TableRevolutions.CountTurnover
		|					ELSE
		|						0
		|				END AS QuantityReadyForAcceptance,
		|				CASE
		|					WHEN TableRevolutions.Factor = VALUE(Enum.IndicatorsOfShipmentAndReturnReferences.ForReceiving)
		|						THEN TableRevolutions.SumTurnover
		|					ELSE
		|						0
		|				END AS AmountToBeAccepted,
		|				CASE
		|					WHEN TableRevolutions.Factor = VALUE(Enum.IndicatorsOfShipmentAndReturnReferences.Accepted)
		|						THEN TableRevolutions.CountTurnover
		|					ELSE
		|						0
		|				END AS QuantityAccepted_,
		|				CASE
		|					WHEN TableRevolutions.Factor = VALUE(Enum.IndicatorsOfShipmentAndReturnReferences.Accepted)
		|						THEN TableRevolutions.SumTurnover
		|					ELSE
		|						0
		|				END AS AcceptedAmount,
		|				CASE
		|					WHEN TableRevolutions.Factor = VALUE(Enum.IndicatorsOfShipmentAndReturnReferences.Issued_1)
		|						THEN TableRevolutions.CountTurnover
		|					ELSE
		|						0
		|				END AS IssuedQuantity,
		|				CASE
		|					WHEN TableRevolutions.Factor = VALUE(Enum.IndicatorsOfShipmentAndReturnReferences.Issued_1)
		|						THEN TableRevolutions.SumTurnover
		|					ELSE
		|						0
		|				END AS IssuedAmount,
		|				CASE
		|					WHEN TableRevolutions.Factor = VALUE(Enum.IndicatorsOfShipmentAndReturnReferences.Issued_1)
		|						THEN TableRevolutions.VATAmountManTurnover
		|					ELSE
		|						0
		|				END AS IssuedVATAmountMan,
		|				CASE
		|					WHEN TableRevolutions.Factor = VALUE(Enum.IndicatorsOfShipmentAndReturnReferences.Issued_1)
		|						THEN TableRevolutions.VATAmountComplTurnover
		|					ELSE
		|						0
		|				END AS IssuedVATAmountLocal,
		|				CASE
		|					WHEN TableRevolutions.Factor = VALUE(Enum.IndicatorsOfShipmentAndReturnReferences.TaxInvoicesRegistered)
		|						THEN TableRevolutions.VATAmountManTurnover
		|					ELSE
		|						0
		|				END AS IssuedInvoicesVATAmountMan,
		|				CASE
		|					WHEN TableRevolutions.Factor = VALUE(Enum.IndicatorsOfShipmentAndReturnReferences.TaxInvoicesRegistered)
		|						THEN TableRevolutions.VATAmountComplTurnover
		|					ELSE
		|						0
		|				END AS IssuedInvoicesVATAmountLocal
		|				FROM
		|					AccumulationRegister.ShipmentAndReturnReferences.Turnovers(
		|						,
		|						,
		|						,
		|						CASE
		|							WHEN &SelectByOrder_
		|								THEN ReferenceOrder = &SalesOrder
		|							WHEN ReferenceOrder REFS Document.SalesOrder
		|								THEN
		|									CAST(ReferenceOrder AS Document.SalesOrder).Partner = &Partner
		|									AND CAST(ReferenceOrder AS Document.SalesOrder).Counterparty = &Counterparty
		|									AND CAST(ReferenceOrder AS Document.SalesOrder).Contract = &Contract
		|									AND CAST(ReferenceOrder AS Document.SalesOrder).Organization = &Organization
		|									AND CAST(ReferenceOrder AS Document.SalesOrder).BusinessOperation IN (&EconomicOperationsOfOrders)
		|									AND (NOT &ToUseTermsOfSales
		|										OR CAST(ReferenceOrder AS Document.SalesOrder).Terms = &Terms)
		|									AND CAST(ReferenceOrder AS Document.SalesOrder).SalesOpportunity = &SalesOpportunity
		|									AND CAST(ReferenceOrder AS Document.SalesOrder).Currency = &ARAPCurrency
		|									AND CASE
		|										WHEN CAST(ReferenceOrder AS Document.SalesOrder).VATTaxation IN (
		|														VALUE(Enum.VATTaxationTypes.ExportOfCommoditiesServicesWorks),
		|														VALUE(Enum.VATTaxationTypes.ExportOfNonResourceGoods)
		|														)
		|											THEN VALUE(Enum.VATTaxationTypes.ExportSale)
		|										ELSE
		|											CAST(ReferenceOrder AS Document.SalesOrder).VATTaxation
		|										END = &VATTaxation
		|									AND CAST(ReferenceOrder AS Document.SalesOrder).PriceIncludesVAT = &PriceIncludesVAT
		|									AND CAST(ReferenceOrder AS Document.SalesOrder).ToReturnReusablePackage = &ToReturnReusablePackage
		|									AND CAST(ReferenceOrder AS Document.SalesOrder).PackageDepositIsRequired = &PackageDepositIsRequired
		|									AND (NOT &UseLinesOfBusiness
		|										OR CAST(ReferenceOrder AS Document.SalesOrder).LineOfBusiness = &LineOfBusiness)
		|							WHEN ReferenceOrder REFS Document.RequestForReturnOfGoodsFromCustomer
		|								THEN
		|									CAST(ReferenceOrder AS Document.RequestForReturnOfGoodsFromCustomer).Partner = &Partner
		|									AND CAST(ReferenceOrder AS Document.RequestForReturnOfGoodsFromCustomer).Counterparty = &Counterparty
		|									AND CAST(ReferenceOrder AS Document.RequestForReturnOfGoodsFromCustomer).Contract = &Contract
		|									AND CAST(ReferenceOrder AS Document.RequestForReturnOfGoodsFromCustomer).Organization = &Organization
		|									AND CAST(ReferenceOrder AS Document.RequestForReturnOfGoodsFromCustomer).BusinessOperation IN (&EconomicOperationsOfOrders)
		|									AND (NOT &ToUseTermsOfSales
		|										OR CAST(ReferenceOrder AS Document.RequestForReturnOfGoodsFromCustomer).Terms = &Terms)
		|									AND CAST(ReferenceOrder AS Document.RequestForReturnOfGoodsFromCustomer).SalesOpportunity = &SalesOpportunity
		|									AND CAST(ReferenceOrder AS Document.RequestForReturnOfGoodsFromCustomer).Currency = &ARAPCurrency
		|									AND CASE
		|										WHEN CAST(ReferenceOrder AS Document.RequestForReturnOfGoodsFromCustomer).VATTaxation IN (
		|														VALUE(Enum.VATTaxationTypes.ExportOfCommoditiesServicesWorks),
		|														VALUE(Enum.VATTaxationTypes.ExportOfNonResourceGoods)
		|														)
		|											THEN VALUE(Enum.VATTaxationTypes.ExportSale)
		|										ELSE
		|											CAST(ReferenceOrder AS Document.RequestForReturnOfGoodsFromCustomer).VATTaxation
		|										END = &VATTaxation
		|									AND CAST(ReferenceOrder AS Document.RequestForReturnOfGoodsFromCustomer).PriceIncludesVAT = &PriceIncludesVAT
		|									AND CAST(ReferenceOrder AS Document.RequestForReturnOfGoodsFromCustomer).ToReturnReusablePackage = &ToReturnReusablePackage
		|									AND CAST(ReferenceOrder AS Document.RequestForReturnOfGoodsFromCustomer).PackageDepositIsRequired = &PackageDepositIsRequired
		|									AND (NOT &UseLinesOfBusiness
		|										OR CAST(ReferenceOrder AS Document.RequestForReturnOfGoodsFromCustomer).LineOfBusiness = &LineOfBusiness)
		|							WHEN ReferenceOrder REFS Document.GoodsShipmentToCustomer
		|								THEN
		|									CAST(ReferenceOrder AS Document.GoodsShipmentToCustomer).Partner = &Partner
		|									AND CAST(ReferenceOrder AS Document.GoodsShipmentToCustomer).Counterparty = &Counterparty
		|									AND CAST(ReferenceOrder AS Document.GoodsShipmentToCustomer).Contract = &Contract
		|									AND CAST(ReferenceOrder AS Document.GoodsShipmentToCustomer).Organization = &Organization
		|									AND CAST(ReferenceOrder AS Document.GoodsShipmentToCustomer).BusinessOperation IN (&EconomicOperationsOfOrders)
		|									AND (NOT &ToUseTermsOfSales
		|										OR CAST(ReferenceOrder AS Document.GoodsShipmentToCustomer).Terms = &Terms)
		|									AND CAST(ReferenceOrder AS Document.GoodsShipmentToCustomer).SalesOpportunity = &SalesOpportunity
		|									AND CAST(ReferenceOrder AS Document.GoodsShipmentToCustomer).Currency = &ARAPCurrency
		|									AND CASE
		|										WHEN CAST(ReferenceOrder AS Document.GoodsShipmentToCustomer).VATTaxation IN (
		|														VALUE(Enum.VATTaxationTypes.ExportOfCommoditiesServicesWorks),
		|														VALUE(Enum.VATTaxationTypes.ExportOfNonResourceGoods)
		|														)
		|											THEN VALUE(Enum.VATTaxationTypes.ExportSale)
		|										ELSE
		|											CAST(ReferenceOrder AS Document.GoodsShipmentToCustomer).VATTaxation
		|										END = &VATTaxation
		|									AND &PriceIncludesVAT = TRUE
		|									AND (NOT &UseLinesOfBusiness
		|										OR CAST(ReferenceOrder AS Document.GoodsShipmentToCustomer).LineOfBusiness = &LineOfBusiness)
		|							WHEN ReferenceOrder REFS Document.SourceDocument
		|								THEN
		|									CAST(ReferenceOrder AS Document.SourceDocument).Partner = &Partner
		|									AND CAST(ReferenceOrder AS Document.SourceDocument).Counterparty = &Counterparty
		|									AND CAST(ReferenceOrder AS Document.SourceDocument).Contract = &Contract
		|									AND CAST(ReferenceOrder AS Document.SourceDocument).Organization = &Organization
		|									AND CAST(ReferenceOrder AS Document.SourceDocument).Currency = &ARAPCurrency
		|									AND CASE
		|										WHEN CAST(ReferenceOrder AS Document.SourceDocument).VATTaxation IN (
		|														VALUE(Enum.VATTaxationTypes.ExportOfCommoditiesServicesWorks),
		|														VALUE(Enum.VATTaxationTypes.ExportOfNonResourceGoods)
		|														)
		|											THEN VALUE(Enum.VATTaxationTypes.ExportSale)
		|										ELSE
		|											CAST(ReferenceOrder AS Document.SourceDocument).VATTaxation
		|										END = &VATTaxation
		|									AND (NOT &UseLinesOfBusiness
		|										OR CAST(ReferenceOrder AS Document.SourceDocument).LineOfBusiness = &LineOfBusiness)
		|						END
		|						AND Products.SaleRegistrationOption IN (
		|									VALUE(Enum.SalesRegistrationOptions.CustomerInvoice),
		|									VALUE(Enum.SalesRegistrationOptions.DeedOfTransfer)
		|									)
		|						AND (Products, Characteristic) IN
		|							(SELECT
		|								Goods.Products AS Products,
		|								Goods.Characteristic AS Characteristic
		|							FROM
		|								Goods AS Goods
		|							)
		|							AND Factor IN (
		|									VALUE(Enum.IndicatorsOfShipmentAndReturnReferences.Shipped),
		|									VALUE(Enum.IndicatorsOfShipmentAndReturnReferences.ReceivedBeforeTransferOfTitleToGoods),
		|									VALUE(Enum.IndicatorsOfShipmentAndReturnReferences.WrittenOffBeforeTransferOfTitleToGoods),
		|									VALUE(Enum.IndicatorsOfShipmentAndReturnReferences.ForReceiving),
		|									VALUE(Enum.IndicatorsOfShipmentAndReturnReferences.Accepted),
		|									VALUE(Enum.IndicatorsOfShipmentAndReturnReferences.Issued_1),
		|									VALUE(Enum.IndicatorsOfShipmentAndReturnReferences.TaxInvoicesRegistered)
		|									)
		|			) AS TableRevolutions
		|		) AS TurnoversByOrders
		|	WHERE
		|		&BusinessOperation = VALUE(Enum.BusinessTransactions.TransferOfTitleToGoods)
		|
		|	GROUP BY
		|		TurnoversByOrders.ReferenceOrder,
		|		CASE
		|			WHEN TurnoversByOrders.ReferenceOrder REFS Document.SalesOrder
		|				THEN CAST(TurnoversByOrders.ReferenceOrder AS Document.SalesOrder).ARAPObjectSettings
		|			WHEN TurnoversByOrders.ReferenceOrder REFS Document.RequestForReturnOfGoodsFromCustomer
		|				THEN CAST(TurnoversByOrders.ReferenceOrder AS Document.RequestForReturnOfGoodsFromCustomer).ARAPObjectSettings
		|			WHEN TurnoversByOrders.ReferenceOrder REFS Document.SourceDocument
		|				THEN CAST(TurnoversByOrders.ReferenceOrder AS Document.SourceDocument).ARAPObjectSettings
		|			ELSE
		|				VALUE(Enum.ARAPObjectSettings.EmptyRef)
		|		END,
		|		TurnoversByOrders.Products,
		|		TurnoversByOrders.Characteristic,
		|		TurnoversByOrders.RowCode
		|
		|	HAVING
		|		SUM(TurnoversByOrders.ShippedQuantity
		|			+ TurnoversByOrders.RegisteredUpToPPPQuantity
		|			- TurnoversByOrders.DeductedToPPPQuantity
		|			- TurnoversByOrders.QuantityAccepted_
		|			- TurnoversByOrders.IssuedQuantity) <> 0
		|		OR SUM(TurnoversByOrders.ShippedAmount
		|			+ TurnoversByOrders.RegisteredUpToPPPAmount
		|			- TurnoversByOrders.DebitedToPPPAmount
		|			- TurnoversByOrders.AcceptedAmount
		|			- TurnoversByOrders.IssuedAmount) <> 0
		|		OR SUM(TurnoversByOrders.IssuedInvoicesVATAmountLocal
		|			- TurnoversByOrders.IssuedVATAmountLocal) <> 0
		|		OR SUM(TurnoversByOrders.IssuedInvoicesVATAmountMan
		|			- TurnoversByOrders.IssuedVATAmountMan) <> 0
		|
		|	UNION ALL
		|
		// 3. We add the Registered Records of this document so that the current TS data is not cleared for the implementation
		|	SELECT
		|		Orders_Table.ReferenceOrder          AS SalesOrder,
		|		CASE
		|			WHEN Orders_Table.ReferenceOrder REFS Document.SalesOrder
		|				THEN CAST(Orders_Table.ReferenceOrder AS Document.SalesOrder).ARAPObjectSettings
		|			WHEN Orders_Table.ReferenceOrder REFS Document.RequestForReturnOfGoodsFromCustomer
		|				THEN CAST(Orders_Table.ReferenceOrder AS Document.RequestForReturnOfGoodsFromCustomer).ARAPObjectSettings
		|			WHEN Orders_Table.ReferenceOrder REFS Document.SourceDocument
		|				THEN CAST(Orders_Table.ReferenceOrder AS Document.SourceDocument).ARAPObjectSettings
		|			ELSE
		|				VALUE(Enum.ARAPObjectSettings.EmptyRef)
		|		END                                     AS ARAPObjectSettings,
		|		Orders_Table.Products          AS Products,
		|		Orders_Table.Characteristic        AS Characteristic,
		|		Orders_Table.RowCode             AS RowCode,
		|		Orders_Table.Warehouse                 AS Warehouse,
		|		Orders_Table.Series                 AS Series,
		|		Orders_Table.IssuedQuantity   AS ForRegistrationQuantity,
		|		Orders_Table.IssuedAmount        AS AmountToBeProcessed,
		|		Orders_Table.IssuedVATAmountLocal AS VATAmountCompl,
		|		Orders_Table.IssuedVATAmountMan  AS VATAmountMan
		|	FROM
		|		#ShipmentOrdersExpanded AS Orders_Table
		|
		|	UNION ALL
		|
		// 4. Add customer order data that is like an invoice
		|	SELECT
		|		CustomerOrderGoods.Ref                 AS SalesOrder,
		|		CustomerOrderGoods.Ref.ARAPObjectSettings AS ARAPObjectSettings,
		|		CustomerOrderGoods.Products           AS Products,
		|		CustomerOrderGoods.Characteristic         AS Characteristic,
		|		CustomerOrderGoods.RowCode              AS RowCode,
		|		CustomerOrderGoods.Warehouse                  AS Warehouse,
		|		CustomerOrderGoods.Series                  AS Series,
		|		CustomerOrderGoods.Count             AS ForRegistrationQuantity,
		|		CustomerOrderGoods.Sum                  AS AmountToBeProcessed,
		|		0                                         AS VATAmountCompl,
		|		0                                         AS VATAmountMan
		|	FROM
		|		Document.SalesOrder.Goods AS CustomerOrderGoods
		|	WHERE
		|		CustomerOrderGoods.Ref.Posted
		|		AND CustomerOrderGoods.Ref.ThisIsOrderAsInvoice
		|		AND NOT CustomerOrderGoods.Canceled
		|		AND CASE
		|			WHEN &SelectByOrder_
		|				THEN CustomerOrderGoods.Ref = &SalesOrder
		|			ELSE CustomerOrderGoods.Ref.Partner = &Partner
		|				AND CustomerOrderGoods.Ref.Counterparty = &Counterparty
		|				AND CustomerOrderGoods.Ref.Contract = &Contract
		|				AND CustomerOrderGoods.Ref.Organization = &Organization
		|				AND CustomerOrderGoods.Ref.BusinessOperation IN (&EconomicOperationsOfOrders)
		|				AND CustomerOrderGoods.Ref.Terms = &Terms
		|				AND CustomerOrderGoods.Ref.SalesOpportunity = &SalesOpportunity
		|				AND (CustomerOrderGoods.Ref.Currency = &ARAPCurrency
		|					OR &BusinessOperation = VALUE(Enum.BusinessTransactions.TransferToCommissionAgent))
		|				AND CASE
		|						WHEN CustomerOrderGoods.Ref.VATTaxation IN (VALUE(Enum.VATTaxationTypes.ExportOfCommoditiesServicesWorks), VALUE(Enum.VATTaxationTypes.ExportOfNonResourceGoods))
		|							THEN VALUE(Enum.VATTaxationTypes.ExportSale)
		|						ELSE CustomerOrderGoods.Ref.VATTaxation
		|					END = &VATTaxation
		|				AND CustomerOrderGoods.Ref.PriceIncludesVAT = &PriceIncludesVAT
		|				AND CustomerOrderGoods.Ref.ToReturnReusablePackage = &ToReturnReusablePackage
		|				AND CustomerOrderGoods.Ref.PackageDepositIsRequired = &PackageDepositIsRequired
		|				AND CASE
		|						WHEN NOT &UseLinesOfBusiness
		|							THEN TRUE
		|						ELSE CustomerOrderGoods.Ref.LineOfBusiness = &LineOfBusiness
		|				END
		|			END
		|		AND CustomerOrderGoods.Products.SaleRegistrationOption IN
		|			(VALUE(Enum.SalesRegistrationOptions.CustomerInvoice),
		|			VALUE(Enum.SalesRegistrationOptions.DeedOfTransfer))
		|		AND (Products, Characteristic) IN
		|			(SELECT
		|					Goods.Products AS Products,
		|					Goods.Characteristic AS Characteristic
		|				FROM
		|					Goods AS Goods)
		|	
		|	UNION ALL
		|
		// 5. Add the data of return requests, which are as an invoice
		|	SELECT
		|		RequestForReturnOfGoods_.Ref                 AS SalesOrder,
		|		RequestForReturnOfGoods_.Ref.ARAPObjectSettings AS ARAPObjectSettings,
		|		RequestForReturnOfGoods_.Products           AS Products,
		|		RequestForReturnOfGoods_.Characteristic         AS Characteristic,
		|		RequestForReturnOfGoods_.RowCode              AS RowCode,
		|		RequestForReturnOfGoods_.Warehouse                  AS Warehouse,
		|		RequestForReturnOfGoods_.Series                  AS Series,
		|		RequestForReturnOfGoods_.Count             AS ForRegistrationQuantity,
		|		RequestForReturnOfGoods_.Sum                  AS AmountToBeProcessed,
		|		0                                            AS VATAmountCompl,
		|		0                                            AS VATAmountMan
		|	FROM
		|		Document.RequestForReturnOfGoodsFromCustomer.SubstituteGoods AS RequestForReturnOfGoods_
		|	WHERE
		|		RequestForReturnOfGoods_.Ref.Posted
		|		AND RequestForReturnOfGoods_.Ref.ThisIsOrderAsInvoice
		|		AND NOT RequestForReturnOfGoods_.Canceled
		|		AND CASE
		|			WHEN &SelectByOrder_
		|				THEN RequestForReturnOfGoods_.Ref = &SalesOrder
		|			ELSE RequestForReturnOfGoods_.Ref.Partner = &Partner
		|				AND RequestForReturnOfGoods_.Ref.Counterparty = &Counterparty
		|				AND RequestForReturnOfGoods_.Ref.Contract = &Contract
		|				AND RequestForReturnOfGoods_.Ref.Organization = &Organization
		|				AND RequestForReturnOfGoods_.Ref.BusinessOperation IN (&EconomicOperationsOfOrders)
		|				AND RequestForReturnOfGoods_.Ref.Terms = &Terms
		|				AND RequestForReturnOfGoods_.Ref.SalesOpportunity = &SalesOpportunity
		|				AND (RequestForReturnOfGoods_.Ref.Currency = &ARAPCurrency
		|					OR &BusinessOperation = VALUE(Enum.BusinessTransactions.TransferToCommissionAgent))
		|				AND CASE
		|						WHEN RequestForReturnOfGoods_.Ref.VATTaxation IN (VALUE(Enum.VATTaxationTypes.ExportOfCommoditiesServicesWorks), VALUE(Enum.VATTaxationTypes.ExportOfNonResourceGoods))
		|							THEN VALUE(Enum.VATTaxationTypes.ExportSale)
		|						ELSE RequestForReturnOfGoods_.Ref.VATTaxation
		|					END = &VATTaxation
		|				AND RequestForReturnOfGoods_.Ref.PriceIncludesVAT = &PriceIncludesVAT
		|				AND RequestForReturnOfGoods_.Ref.ToReturnReusablePackage = &ToReturnReusablePackage
		|				AND RequestForReturnOfGoods_.Ref.PackageDepositIsRequired = &PackageDepositIsRequired
		|				AND CASE
		|						WHEN NOT &UseLinesOfBusiness
		|							THEN TRUE
		|						ELSE RequestForReturnOfGoods_.Ref.LineOfBusiness = &LineOfBusiness
		|				END
		|			END
		|		AND RequestForReturnOfGoods_.Products.SaleRegistrationOption IN
		|			(VALUE(Enum.SalesRegistrationOptions.CustomerInvoice),
		|			VALUE(Enum.SalesRegistrationOptions.DeedOfTransfer))
		|		AND (Products, Characteristic) IN
		|			(SELECT
		|					Goods.Products AS Products,
		|					Goods.Characteristic AS Characteristic
		|				FROM
		|					Goods AS Goods)
		|	) AS OrdersTable
		|
		|GROUP BY
		|	CASE
		|		WHEN OrdersTable.SalesOrder REFS Document.SalesOrder
		|			THEN CAST(OrdersTable.SalesOrder AS Document.SalesOrder).SalesOpportunity
		|		WHEN OrdersTable.SalesOrder REFS Document.RequestForReturnOfGoodsFromCustomer
		|			THEN CAST(OrdersTable.SalesOrder AS Document.RequestForReturnOfGoodsFromCustomer).SalesOpportunity
		|		WHEN OrdersTable.SalesOrder REFS Document.GoodsShipmentToCustomer
		|			THEN CAST(OrdersTable.SalesOrder AS Document.GoodsShipmentToCustomer).SalesOpportunity
		|		ELSE
		|			VALUE(Catalog.SalesOpportunitiesToCustomer.EmptyRef)
		|	END,
		|	OrdersTable.SalesOrder,
		|	OrdersTable.ARAPObjectSettings,
		|	OrdersTable.Products,
		|	OrdersTable.Characteristic,
		|	OrdersTable.RowCode,
		|	OrdersTable.Warehouse,
		|	OrdersTable.Series
		|
		|HAVING
		|	SUM(OrdersTable.ForRegistrationQuantity) > 0
		|;
		|
		|//////////////////////////////////////////////////////////////////////////////// 2
		|SELECT
		|	COUNT(*)                 AS DuplicateCount,
		|	SalesOrders.Products   AS Products,
		|	SalesOrders.Characteristic AS Characteristic,
		|	SalesOrders.Series          AS Series,
		|	SalesOrders.Warehouse          AS Warehouse
		|INTO DuplicatesOfProducts
		|FROM
		|	SalesOrders AS SalesOrders
		|
		|GROUP BY
		|	SalesOrders.Products,
		|	SalesOrders.Characteristic,
		|	SalesOrders.Series,
		|	SalesOrders.Warehouse
		|;
		|
		|//////////////////////////////////////////////////////////////////////////////// 3
		|SELECT
		|	ProductsVATRates.Products AS Products,
		|	ProductsVATRates.VATRate AS VATRate
		|INTO ProductsVATRates
		|FROM
		|	InformationRegister.ProductsVATRates.SliceLast(
		|		&Date,
		|		(Country = &RegistrationCountry
		|			OR Country = VALUE(Catalog.WorldCountries.EmptyRef))
		|		AND Products IN (SELECT 
		|								Products 
		|							FROM 
		|								Goods)
		|	) AS ProductsVATRates
		|;
		|
		|//////////////////////////////////////////////////////////////////////////////// 4
		|SELECT
		|	BasicVATRates.VATRate AS VATRate
		|INTO BasicVATRates
		|FROM
		|	InformationRegister.BasicVATRates.SliceLast(
		|		&Date,
		|		Country = &RegistrationCountry
		|	) AS BasicVATRates
		|;
		|
		|//////////////////////////////////////////////////////////////////////////////// 5
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
		|	SalesOrders.Warehouse                   AS Warehouse,
		|	SalesOrders.Series                   AS Series,
		|	SalesOrders.ForRegistrationQuantity   AS ForRegistrationQuantity,
		|	CustomerOrderGoods.DeliveryPeriodDays        AS DeliveryPeriodDays,
		|	CustomerOrderGoods.PriceKind             AS PriceKind,
		|	CustomerOrderGoods.Price                AS Price,
		|	CustomerOrderGoods.PercentRateOfManualDiscount AS PercentRateOfManualDiscount,
		|	CustomerOrderGoods.VATRate           AS VATRate,
		|	0                                      AS Allocated,
		|	DuplicatesOfProducts.DuplicateCount          AS DuplicateCount
		|FROM
		|	SalesOrders AS SalesOrders
		|	INNER JOIN Document.SalesOrder.Goods AS CustomerOrderGoods
		|		ON CustomerOrderGoods.Ref = SalesOrders.SalesOrder
		|			AND CustomerOrderGoods.RowCode = SalesOrders.RowCode
		|	LEFT JOIN DuplicatesOfProducts AS DuplicatesOfProducts
		|		ON SalesOrders.Products = DuplicatesOfProducts.Products
		|			AND SalesOrders.Characteristic = DuplicatesOfProducts.Characteristic
		|			AND SalesOrders.Warehouse = DuplicatesOfProducts.Warehouse
		|			AND SalesOrders.Series = DuplicatesOfProducts.Series
		|
		|UNION ALL
		|
		|SELECT
		|	SalesOrders.SalesOrder               AS SalesOrder,
		|	SalesOrders.ARAPObjectSettings            AS ARAPObjectSettings,
		|	SalesOrders.Products               AS Products,
		|	SalesOrders.Characteristic             AS Characteristic,
		|	SalesOrders.RowCode                  AS RowCode,
		|	CASE
		|		WHEN RequestForReturnOfGoods_.WithAssignment
		|			THEN SalesOrders.SalesOrder.Purpose
		|		ELSE VALUE(Catalog.Assignments.EmptyRef)
		|	END                                     AS Purpose,
		|	SalesOrders.Warehouse                      AS Warehouse,
		|	SalesOrders.Series                      AS Series,
		|	SalesOrders.ForRegistrationQuantity      AS ForRegistrationQuantity,
		|	RequestForReturnOfGoods_.DeliveryPeriodDays        AS DeliveryPeriodDays,
		|	RequestForReturnOfGoods_.PriceKind             AS PriceKind,
		|	RequestForReturnOfGoods_.Price                AS Price,
		|	RequestForReturnOfGoods_.PercentRateOfManualDiscount AS PercentRateOfManualDiscount,
		|	RequestForReturnOfGoods_.VATRate           AS VATRate,
		|	0                                         AS Allocated,
		|	DuplicatesOfProducts.DuplicateCount             AS DuplicateCount
		|FROM
		|	SalesOrders AS SalesOrders
		|	INNER JOIN Document.RequestForReturnOfGoodsFromCustomer.SubstituteGoods AS RequestForReturnOfGoods_
		|		ON RequestForReturnOfGoods_.Ref = SalesOrders.SalesOrder
		|			AND RequestForReturnOfGoods_.RowCode = SalesOrders.RowCode
		|	LEFT JOIN DuplicatesOfProducts AS DuplicatesOfProducts
		|		ON SalesOrders.Products = DuplicatesOfProducts.Products
		|			AND SalesOrders.Characteristic = DuplicatesOfProducts.Characteristic
		|			AND SalesOrders.Warehouse = DuplicatesOfProducts.Warehouse
		|			AND SalesOrders.Series = DuplicatesOfProducts.Series
		|
		|UNION ALL
		|
		|SELECT
		|	SalesOrders.SalesOrder              AS SalesOrder,
		|	SalesOrders.ARAPObjectSettings           AS ARAPObjectSettings,
		|	SalesOrders.Products              AS Products,
		|	SalesOrders.Characteristic            AS Characteristic,
		|	SalesOrders.RowCode                 AS RowCode,
		|	ShipmentOfItemsToCustomer.Purpose         AS Purpose,
		|	SalesOrders.Warehouse                     AS Warehouse,
		|	SalesOrders.Series                     AS Series,
		|	SalesOrders.ForRegistrationQuantity     AS ForRegistrationQuantity,
		|	ShipmentOfItemsToCustomer.DeliveryPeriodDays       AS DeliveryPeriodDays,
		|	ShipmentOfItemsToCustomer.PriceKind            AS PriceKind,
		|	ShipmentOfItemsToCustomer.Price               AS Price,
		|	0                                        AS PercentRateOfManualDiscount,
		|	&VATRateShipmentOfGoodsWithoutOrder AS VATRate,
		|	0                                        AS Allocated,
		|	DuplicatesOfProducts.DuplicateCount            AS DuplicateCount
		|FROM
		|	SalesOrders AS SalesOrders
		|	INNER JOIN Document.GoodsShipmentToCustomer.Goods AS ShipmentOfItemsToCustomer
		|		ON ShipmentOfItemsToCustomer.Ref = SalesOrders.SalesOrder
		|			AND ShipmentOfItemsToCustomer.RowCode = SalesOrders.RowCode
		|	LEFT JOIN DuplicatesOfProducts AS DuplicatesOfProducts
		|		ON SalesOrders.Products = DuplicatesOfProducts.Products
		|			AND SalesOrders.Characteristic = DuplicatesOfProducts.Characteristic
		|			AND SalesOrders.Warehouse = DuplicatesOfProducts.Warehouse
		|			AND SalesOrders.Series = DuplicatesOfProducts.Series
		|	LEFT JOIN ProductsVATRates AS ProductsVATRates
		|		ON ProductsVATRates.Products = SalesOrders.Products
		|	LEFT JOIN BasicVATRates AS BasicVATRates
		|		ON TRUE
		|
		|UNION ALL
		|
		// For lines over the order
		|SELECT
		|	SalesOrders.SalesOrder              AS SalesOrder,
		|	SalesOrders.ARAPObjectSettings           AS ARAPObjectSettings,
		|	SalesOrders.Products              AS Products,
		|	SalesOrders.Characteristic            AS Characteristic,
		|	SalesOrders.RowCode                 AS RowCode,
		|	ISNULL(ShipmentOfItemsToCustomer.Purpose, VALUE(Catalog.Assignments.EmptyRef)) AS Purpose,
		|	SalesOrders.Warehouse                     AS Warehouse,
		|	SalesOrders.Series                     AS Series,
		|	SalesOrders.ForRegistrationQuantity     AS ForRegistrationQuantity,
		|	ISNULL(ShipmentOfItemsToCustomer.DeliveryPeriodDays, 0) AS DeliveryPeriodDays,
		|	ISNULL(ShipmentOfItemsToCustomer.PriceKind, VALUE(Catalog.TypesOfPrices.EmptyRef)) AS PriceKind,
		|	ISNULL(ShipmentOfItemsToCustomer.Price, 0)  AS Price,
		|	0                                        AS PercentRateOfManualDiscount,
		|	CASE
		|		WHEN ShipmentOfItemsToCustomer.Ref IS NULL
		|			THEN VALUE(Catalog.VATRates.EmptyRef)
		|		ELSE
		|			&VATRateShipmentOfGoodsWithoutOrder
		|	END                                    AS VATRate,
		|	0                                        AS Allocated,
		|	DuplicatesOfProducts.DuplicateCount            AS DuplicateCount
		|FROM
		|	SalesOrders AS SalesOrders
		|	LEFT JOIN Document.GoodsShipmentToCustomer.Goods AS ShipmentOfItemsToCustomer
		|		ON SalesOrders.SalesOrder = ShipmentOfItemsToCustomer.SalesOrder
		|			AND SalesOrders.RowCode = ShipmentOfItemsToCustomer.RowCode
		|			AND ShipmentOfItemsToCustomer.RowCode = 0
		|			AND ShipmentOfItemsToCustomer.Ref.Posted
		|	LEFT JOIN DuplicatesOfProducts AS DuplicatesOfProducts
		|		ON SalesOrders.Products = DuplicatesOfProducts.Products
		|			AND SalesOrders.Characteristic = DuplicatesOfProducts.Characteristic
		|			AND SalesOrders.Warehouse = DuplicatesOfProducts.Warehouse
		|			AND SalesOrders.Series = DuplicatesOfProducts.Series
		|	LEFT JOIN ProductsVATRates AS ProductsVATRates
		|		ON ProductsVATRates.Products = SalesOrders.Products
		|	LEFT JOIN BasicVATRates AS BasicVATRates
		|		ON TRUE
		|WHERE
		|	SalesOrders.RowCode = 0
		|
		|UNION ALL
		|
		|SELECT
		|	SalesOrders.SalesOrder               AS SalesOrder,
		|	SalesOrders.ARAPObjectSettings            AS ARAPObjectSettings,
		|	SalesOrders.Products               AS Products,
		|	SalesOrders.Characteristic             AS Characteristic,
		|	SalesOrders.RowCode                  AS RowCode,
		|	EnteringProductBalances.Purpose             AS Purpose,
		|	SalesOrders.Warehouse                      AS Warehouse,
		|	SalesOrders.Series                      AS Series,
		|	SalesOrders.ForRegistrationQuantity      AS ForRegistrationQuantity,
		|	0                                         AS DeliveryPeriodDays,
		|	VALUE(Catalog.TypesOfPrices.EmptyRef) AS PriceKind,
		|	EnteringProductBalances.Price                   AS Price,
		|	0                                         AS PercentRateOfManualDiscount,
		|	&VATRateEnteringBalances                    AS VATRate,
		|	0                                         AS Allocated,
		|	DuplicatesOfProducts.DuplicateCount             AS DuplicateCount
		|FROM
		|	SalesOrders AS SalesOrders
		|	INNER JOIN Document.OBEntryGoods.Goods AS EnteringProductBalances
		|		ON EnteringProductBalances.Ref.Lot = SalesOrders.SalesOrder
		|			AND EnteringProductBalances.RowCode = SalesOrders.RowCode
		|			AND EnteringProductBalances.Ref.Posted
		|	LEFT JOIN DuplicatesOfProducts AS DuplicatesOfProducts
		|		ON SalesOrders.Products = DuplicatesOfProducts.Products
		|			AND SalesOrders.Characteristic = DuplicatesOfProducts.Characteristic
		|			AND SalesOrders.Warehouse = DuplicatesOfProducts.Warehouse
		|			AND SalesOrders.Series = DuplicatesOfProducts.Series
		|	LEFT JOIN ProductsVATRates AS ProductsVATRates
		|		ON ProductsVATRates.Products = SalesOrders.Products
		|	LEFT JOIN BasicVATRates AS BasicVATRates
		|		ON TRUE
		|	LEFT JOIN InformationRegister.DocumentsRegistry AS DocumentsRegistry
		|		ON EnteringProductBalances.Ref = DocumentsRegistry.ReversedDocument
		|			AND DocumentsRegistry.Posted
		|			AND NOT DocumentsRegistry.AdditionalRecord
		|WHERE
		|	DocumentsRegistry.Ref IS NULL
		|
		|ORDER BY
		|	Products,
		|	Characteristic,
		|	Warehouse,
		|	Series,
		|	SalesOrder
		|");
	
	// Logger Movements
	TableFormationParameters = AccumulationRegisters.ShipmentAndReturnReferences.NewParametersForCreatingExpandedTable();
	TableFormationParameters.ConditionText =
		"Recorder = &Recorder
		|	AND Active
		|	AND Products.SaleRegistrationOption IN (
		|		VALUE(Enum.SalesRegistrationOptions.CustomerInvoice),
		|		VALUE(Enum.SalesRegistrationOptions.DeedOfTransfer)
		|		)
		|	AND (Products, Characteristic) IN
		|		(SELECT
		|			Goods.Products AS Products,
		|			Goods.Characteristic AS Characteristic
		|		FROM
		|			Goods AS Goods)";
	TableFormationParameters.PhysicalTable = True;
	TableFormationParameters.Indicators = "Issued_1, TaxInvoicesRegistered";
	TableFormationParameters.Resources = "Count, Sum, VATAmountCompl, VATAmountMan";
	
	ShipmentOrdersTurnoverExpanded =
		AccumulationRegisters.ShipmentAndReturnReferences.QueryTextExpandedTable(
			TableFormationParameters);
	
	Query.Text = StrReplace(Query.Text,
		"#ShipmentOrdersExpanded",
		ShipmentOrdersTurnoverExpanded);
	
	// Query Text for VAT rate if the order is Shipment of goods to the customer
	Query.Text = StrReplace(Query.Text,
		"&VATRateShipmentOfGoodsWithoutOrder",
		VATAccountingERP.QueryTextVATRate(
			"ShipmentOfItemsToCustomer.Ref.VATTaxation",
			"ShipmentOfItemsToCustomer.Products",
			"&ToReturnReusablePackage"));
	
	Query.Text = StrReplace(Query.Text,
		"&VATRateEnteringBalances",
		VATAccountingERP.QueryTextVATRate(
			"EnteringProductBalances.Ref.VATTaxation",
			"EnteringProductBalances.Products",
			"&ToReturnReusablePackage"));
	
	VATAccountingERP.SetParametersForVATRateRequest(
		Query.Parameters, 
		Object.Organization,
		Object.Date);
			
	Query.SetParameter("RegistrationCountry",
		SettingsValueClientServerCached.CountryOfOrganizationRegistration(Object.Organization));
	
	// Executing the request
	Query.SetParameter("SalesOrder",              Object.SalesOrder);
	Query.SetParameter("Partner",                   Object.Partner);
	Query.SetParameter("Counterparty",                Object.Counterparty);
	Query.SetParameter("Contract",                   Object.Contract);
	Query.SetParameter("Organization",               Object.Organization);
	Query.SetParameter("SalesOpportunity",                    Object.SalesOpportunity);
	Query.SetParameter("Terms",                Object.Terms);
	Query.SetParameter("ARAPCurrency",      Object.ARAPCurrency);
	Query.SetParameter("VATTaxation",        Object.VATTaxation);
	Query.SetParameter("PriceIncludesVAT",           Object.PriceIncludesVAT);
	Query.SetParameter("ToReturnReusablePackage", Object.ToReturnReusablePackage);
	Query.SetParameter("PackageDepositIsRequired",      Object.PackageDepositIsRequired);
	Query.SetParameter("Warehouse",                     Object.Warehouse);
	Query.SetParameter("Recorder",               Object.Ref);
	Query.SetParameter("SelectByOrder_",          SelectByOrder_);
	Query.SetParameter("BusinessOperation",     Object.BusinessOperation);
	Query.SetParameter("LineOfBusiness",   Object.LineOfBusiness);
	Query.SetParameter("UseLinesOfBusiness",
		GetFunctionalOption("UseIncomeAccountingByLinesOfBusiness"));
	Query.SetParameter("ToUseTermsOfSales",
		GetFunctionalOption("ToUseTermsOfSales"));
		
	EconomicOperationsOfOrders = New Array();
	
	If Object.BusinessOperation = Enums.BusinessTransactions.SaleToCustomer
		Or Object.BusinessOperation = Enums.BusinessTransactions.SaleToCustomerLocalAccounting
		Or Object.BusinessOperation = Enums.BusinessTransactions.SaleWithDeferredTransferOfTitle
		Or Object.BusinessOperation = Enums.BusinessTransactions.TransferOfTitleToGoods
		Then
		
		EconomicOperationsOfOrders.Add(Enums.BusinessTransactions.SaleToCustomer);
		EconomicOperationsOfOrders.Add(Enums.BusinessTransactions.ReturnOfGoodsFromCustomer);
		EconomicOperationsOfOrders.Add(Enums.BusinessTransactions.ReturnFromRetailCustomer);
		EconomicOperationsOfOrders.Add(Enums.BusinessTransactions.SaleWithDeferredTransferOfTitle);
		EconomicOperationsOfOrders.Add(Enums.BusinessTransactions.GoodsShipmentToCustomer);
		EconomicOperationsOfOrders.Add(
			Enums.BusinessTransactions.OBEntryShippedGoods);
		
	ElsIf Object.BusinessOperation = Enums.BusinessTransactions.TransferToCommissionAgent  Then
		
		EconomicOperationsOfOrders.Add(Enums.BusinessTransactions.TransferToCommissionAgent);
		EconomicOperationsOfOrders.Add(Enums.BusinessTransactions.ReturnFromCommissionAgent);

	ElsIf Object.BusinessOperation = Enums.BusinessTransactions.SaleWithDeferredTransferOfTitle  Then
		
		EconomicOperationsOfOrders.Add(Enums.BusinessTransactions.SaleWithDeferredTransferOfTitle);
	
	ElsIf Object.BusinessOperation = Enums.BusinessTransactions.SalesViaCommissionAgent Then
	
		EconomicOperationsOfOrders.Add(Enums.BusinessTransactions.SalesViaCommissionAgent);
	
	ElsIf Object.BusinessOperation = Enums.BusinessTransactions.SalesViaCommissionAgentGoodsInTransit Then
		
		EconomicOperationsOfOrders.Add(Enums.BusinessTransactions.SalesViaCommissionAgentGoodsInTransit);
		
	EndIf;
	
	Query.SetParameter("EconomicOperationsOfOrders", EconomicOperationsOfOrders);
	
	Query.SetParameter("Goods",  Object.Goods.Unload(,"RowCode,Products,Characteristic,SalesOrder"));
	SetPrivilegedMode(True);
	QueryResult = Query.ExecuteBatch();
	If QueryResult[1].IsEmpty() Then
		Return False;
	EndIf;
	
	Selection = QueryResult[QueryResult.UBound()].Select();
	
	ArrayOfARAPObjectsSettings = New Array();
	While Selection.Next() Do
		If ValueIsFilled(Selection.ARAPObjectSettings)
			And ArrayOfARAPObjectsSettings.Find(Selection.ARAPObjectSettings) = Undefined Then
			ArrayOfARAPObjectsSettings.Add(Selection.ARAPObjectSettings);
		EndIf;
	EndDo;
	
	If ArrayOfARAPObjectsSettings.Count() > 1 Then
		
		If Object.BusinessOperation = Enums.BusinessTransactions.TransferOfTitleToGoods Then
			Common.MessageToUser(NStr("vi = 'Trong các lệnh đã tìm thấy, trường ""Trình tự hạch toán"" là khác nhau';
										|ru = 'У найденных распоряжений отличается поле ""Порядок расчетов""';
										|en = 'The ""Payment terms"" field data is different for the found references'; fa = 'The ""Payment terms"" field data is different for the found references';
										|it = 'The ""Payment terms"" field data is different for the found references';
										|pl = 'The ""Payment terms"" field data is different for the found references';
										|tr = 'Bulunan siparişlerin farklı bir ""Alacak/Borç muhasebesi prosedürü"" alanı mevcut'"));
		Else
			Common.MessageToUser(NStr("vi = 'Trong các đơn hàng đã tìm thấy, khác trường ""Trình tự hạch toán""';
										|ru = 'У найденных заказов отличается поле ""Порядок расчетов""';
										|en = 'The ""Payment terms"" field data is different for the found orders'; fa = 'The ""Payment terms"" field data is different for the found orders';
										|it = 'У найденных заказов отличается поле ""Порядок расчетов""';
										|pl = 'The ""Payment terms"" field data is different for the found orders';
										|tr = 'Bulunan siparişlerin farklı bir ""Alacak/Borç muhasebesi prosedürü"" alanı mevcut'"));
		EndIf;
		
		Return False;
	EndIf;
	
	Selection.Reset();
	
	TableOfUnallocatedGoods = New ValueTable();
	TableOfUnallocatedGoods.Columns.Add("Products");
	TableOfUnallocatedGoods.Columns.Add("Characteristic");
	TableOfUnallocatedGoods.Columns.Add("Warehouse");
	TableOfUnallocatedGoods.Columns.Add("Series");
	TableOfUnallocatedGoods.Columns.Add("SalesOrder");
	TableOfUnallocatedGoods.Columns.Add("RowCode");
	TableOfUnallocatedGoods.Columns.Add("Count");
	TableOfUnallocatedGoods.Columns.Add("DeliveryPeriodDays");
	TableOfUnallocatedGoods.Columns.Add("PriceKind");
	TableOfUnallocatedGoods.Columns.Add("Price");
	TableOfUnallocatedGoods.Columns.Add("PercentRateOfManualDiscount");
	TableOfUnallocatedGoods.Columns.Add("VATRate");
	TableOfUnallocatedGoods.Columns.Add("Purpose");
	
	While Selection.Next() Do
		
		TheStructureOfTheSearch = New Structure();
		TheStructureOfTheSearch.Insert("Products",        Selection.Products);
		TheStructureOfTheSearch.Insert("Characteristic",      Selection.Characteristic);
		TheStructureOfTheSearch.Insert("Warehouse",               Selection.Warehouse);
		TheStructureOfTheSearch.Insert("Series",               Selection.Series);
		TheStructureOfTheSearch.Insert("PriceKind",             Selection.PriceKind);
		TheStructureOfTheSearch.Insert("Price",                Selection.Price);
		TheStructureOfTheSearch.Insert("PercentRateOfManualDiscount", Selection.PercentRateOfManualDiscount);
		TheStructureOfTheSearch.Insert("VATRate",           Selection.VATRate);
		TheStructureOfTheSearch.Insert("RowCode", 0);
		
		FoundRows = Object.Goods.FindRows(TheStructureOfTheSearch);
		RetainedQuantity = Selection.ForRegistrationQuantity;
		
		// If there are no duplicates, we distribute the order line to the invoice lines
		If Selection.DuplicateCount < 2 Then
		
			For Each CurRow In FoundRows Do
			
				FillPropertyValues(CurRow, Selection, "RowCode,SalesOrder,Purpose,DeliveryPeriodDays");
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
				
				If CurRow.Count = Selection.ForRegistrationQuantity Then
					
					MatchingStringFound = True;
					FillPropertyValues(CurRow, Selection, "RowCode,SalesOrder,Purpose,DeliveryPeriodDays");
					
					Break;
					
				EndIf;
				
			EndDo;
			
			If Not MatchingStringFound Then
				
				NewRow = TableOfUnallocatedGoods.Add();
				FillPropertyValues(NewRow, Selection);
				NewRow.Count = RetainedQuantity;
				
			EndIf;
			
		EndIf;
		
	EndDo;
	
	// We will distribute duplicates of goods that were not distributed on the first pass
	If TableOfUnallocatedGoods.Count() > 0 Then
		
		ParametersForFillingInVATAmountLocalManSManSManSManSManSManSManSManS = BatchProcessingOfTablePartClientServer.ParametersForFillingInVATAmountLocalManSManSManSManSManSManSManSManS(
			Object.Currency,
			LocalAccountingCurrency,
			ManagementAccountingCurrency);
		
		StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
		
		RowsToProcess = New Array;
		StructureOfActions = New Structure;
		StructureOfActions.Insert("RecalculateNumberOfPackages");
		StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
		StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
		StructureOfActions.Insert("RecalculateAmount");
		StructureOfActions.Insert("RecalculateAmountTakingIntoAccountManualDiscount", New Structure("Clear", False));
		StructureOfActions.Insert("RecalculateAmountTakingIntoAccountAutomaticDiscount", New Structure("Clear", True));
		StructureOfActions.Insert("RecalculateAmountTakingIntoAccountDiscountWithBonusPoints");
		StructureOfActions.Insert("FillInDuplicateDependentDetails", DependentDetails());
		StructureOfActions.Insert("ClearAmountOfSettlements");
		StructureOfActions.Insert("SetVATAmountLocalMans", ParametersForFillingInVATAmountLocalManSManSManSManSManSManSManSManS);
		
		For Each UnallocatedRow In TableOfUnallocatedGoods Do
			
			TheStructureOfTheSearch = New Structure();
			TheStructureOfTheSearch.Insert("RowCode",           0);
			TheStructureOfTheSearch.Insert("SalesOrder",        Undefined);
			TheStructureOfTheSearch.Insert("Products",        UnallocatedRow.Products);
			TheStructureOfTheSearch.Insert("Characteristic",      UnallocatedRow.Characteristic);
			TheStructureOfTheSearch.Insert("Warehouse",               UnallocatedRow.Warehouse);
			TheStructureOfTheSearch.Insert("PriceKind",             UnallocatedRow.PriceKind);
			TheStructureOfTheSearch.Insert("Price",                UnallocatedRow.Price);
			TheStructureOfTheSearch.Insert("PercentRateOfManualDiscount", UnallocatedRow.PercentRateOfManualDiscount);
			TheStructureOfTheSearch.Insert("VATRate",           UnallocatedRow.VATRate);
			TheStructureOfTheSearch.Insert("Series",               UnallocatedRow.Series);
			
			ProductLines_3 = Object.Goods.FindRows(TheStructureOfTheSearch);
			
			For Each LineProducts_ In ProductLines_3 Do
				
				If LineProducts_.Count = UnallocatedRow.Count Then
					FillPropertyValues(LineProducts_, UnallocatedRow, "RowCode,SalesOrder,Purpose,DeliveryPeriodDays");
					UnallocatedRow.Count = 0;
				ElsIf LineProducts_.Count > UnallocatedRow.Count Then
					Difference = LineProducts_.Count - UnallocatedRow.Count;
					
					NewLineProducts = Object.Goods.Add();
					FillPropertyValues(NewLineProducts, LineProducts_);
					NewLineProducts.Count = Difference;
					ProductLines_3.Add(NewLineProducts);
					
					FillPropertyValues(LineProducts_, UnallocatedRow, "RowCode,SalesOrder,Purpose,DeliveryPeriodDays,Count");
					
					UnallocatedRow.Count = 0;
					
					RowsToProcess.Add(NewLineProducts);
					RowsToProcess.Add(LineProducts_);
					
				ElsIf LineProducts_.Count < UnallocatedRow.Count Then
					Difference = UnallocatedRow.Count - LineProducts_.Count;
					FillPropertyValues(LineProducts_, UnallocatedRow, "RowCode,SalesOrder,Purpose,DeliveryPeriodDays");
					UnallocatedRow.Count = Difference;
					
				EndIf;
				
				If UnallocatedRow.Count = 0 Then
					Break;
				EndIf;
				
			EndDo;
			
		EndDo;
		
		BatchProcessingOfTablePartServer.ProcessTSStrings(
			RowsToProcess,
			StructureOfActions,
			Object.Goods,
			Undefined);
		
		UpdateOrderDeviations();
	EndIf;
	
	For Each CurRow In Object.Goods Do
		If Not ValueIsFilled(CurRow.RowCode) Then
			CurRow.Purpose = Catalogs.Assignments.EmptyRef();
		EndIf;
	EndDo;
	
	FillInStatusesForSpecifyingSeriesServer();
	
	Return True;
	
EndFunction

&AtServer
Function FillWarehouseInSelectedLinesOnServer(Val ArrayOfSelectedRows, Warehouse)
	
	FilledWithRows = WarehousesServer.FillInWarehousesInSelectedLines(Object.Goods, ArrayOfSelectedRows, Warehouse);
	
	If FilledWithRows > 0 Then
		ProductsServer.FillInStatusesForSpecifyingSeries(Object,SeriesSpecificationParameters);
		WhenChangingWarehouseInTablePartServer();
	EndIf;
	
	Return FilledWithRows;
	
EndFunction

&AtServer
Procedure SetAvailabilityOfItemsByStatusServer()
	
	ItemArray = New Array;
	
	// Header Controls
	If Not Object.OrderSales Then
		ItemArray.Add("Date");
	EndIf;
	
	ItemArray.Add("Partner");
	ItemArray.Add("Terms");
	ItemArray.Add("Contract");
	
	ItemArray.Add("PriceIncludesVAT");
	ItemArray.Add("Organization");
	ItemArray.Add("Counterparty");
	ItemArray.Add("VATTaxation");
	ItemArray.Add("OrderSales");
	ItemArray.Add("CustomImplementation");
	ItemArray.Add("ToReturnReusablePackage");
	ItemArray.Add("ReusablePackagesReturnDate");
	ItemArray.Add("PackageDepositIsRequired");
	ItemArray.Add("Department");
	
	ItemArray.Add("Goods;BeforeAddRow,BeforeDeleteRow,BeforeRowChange");
	
	ItemArray.Add("GoodsAdd");
	ItemArray.Add("GoodsCopy");
	ItemArray.Add("ProductsContextMenuAdd");
	ItemArray.Add("ProductItemsContextMenuCopy");
	
	ItemArray.Add("GoodsSearchByBarcode");
	ItemArray.Add("GoodsImportDataFromPDT");
	ItemArray.Add("GoodsSplitRow");
	ItemArray.Add("GoodsContextMenuSplitRow");
	ItemArray.Add("GoodsOpenSelection");
	ItemArray.Add("GoodsAddReusablePackage");
	
	ItemArray.Add("GoodsAssignAutomaticDiscounts");
	ItemArray.Add("GoodsFillThePricesByTermsOfSales");
	ItemArray.Add("GoodsFillInPricesOfSelectedRowsByPriceType");
	
	ItemArray.Add("GoodsCancelManualDiscounts");
	ItemArray.Add("GoodsAssignAManualDiscount");
	ItemArray.Add("GoodsAssignAManualDiscountToSelectedRows");
	
	ItemArray.Add("GoodsSelectGoodsByOrdersNotes");
	ItemArray.Add("GoodsCalculateDiscountsMarkups");
	ItemArray.Add("GoodsImportFromExternalFile");
	ItemArray.Add("GoodsSetComposition");
	
	ItemArray.Add("ToReadLoyaltyCard");
	ItemArray.Add("ToReadLoyaltyCardClient");
	ItemArray.Add("LoyaltyCard");
	
	ItemArray.Add("GoodsGetWeight");
	ItemArray.Add("GoodsCheckQuantityInTheDocument");
	ItemArray.Add("GoodsFillInTheWarehouseInSelectedLines");
	ItemArray.Add("Warehouse");
	ItemArray.Add("BusinessOperation");
	
	ItemArray.Add("GoodsUnlinkFromOrder");
	ItemArray.Add("GoodsContextMenuUnlinkFromOrder");
	
	ItemArray.Add("GoodsInsertRows");
	
	ItemArray.Add("Status");
	
	ItemArray.Add("SaleRegistrationOption");
	ItemArray.Add("CustomerContract");
	ItemArray.Add("CustomerCounterparty");
	ItemArray.Add("CustomerPartner");
	
	ItemArray.Add("GoodsFillInPricesUnderAgreement");
	ItemArray.Add("GoodsAddPaymentWithBonusPoints");
	ItemArray.Add("GoodsCancelPaymentWithBonusPoints");
	ItemArray.Add("GoodsSelectTransferredGoods");
	ItemArray.Add("GoodsFillInTheDepartment");
	ItemArray.Add("GoodsFillInVATRate");
	
	TMCommonUse.SetSubscriptionForFormElementChangeEvents(ThisObject, ItemArray);
	
	TMCommonUseClientServer.SetFormItemProperty(Items, "GoodsOpenSelection",                "Enabled", 
		Not Object.OrderSales Or (Object.OrderSales And SalesInExcessOfOrder));
	TMCommonUseClientServer.SetFormItemProperty(Items, "GoodsSelectGoodsByOrdersNotes",                "Enabled", 
		Not Object.OrderSales Or (Object.OrderSales And SalesInExcessOfOrder));
	TMCommonUseClientServer.SetFormItemProperty(Items, "GoodsAddReusablePackage", "Enabled", Not Object.OrderSales);
	
	TMCommonUseClientServer.SetFormItemProperty(Items, "ServicesOpenInformationAboutDiscounts",                "Enabled", Not Object.OrderSales);
	TMCommonUseClientServer.SetFormItemProperty(Items, "ContextMenuServicesOpenInformationAboutDiscounts", "Enabled", Not Object.OrderSales);
	
	TMCommonUseClientServer.SetFormItemProperty(Items, "GoodsUnlinkFromOrder",                "Visible", Object.OrderSales And SalesInExcessOfOrder);
	TMCommonUseClientServer.SetFormItemProperty(Items, "GoodsContextMenuUnlinkFromOrder", "Visible", Object.OrderSales And SalesInExcessOfOrder);
	TMCommonUseClientServer.SetFormItemProperty(Items, "GoodsImportFromExternalFile",                "Enabled", 
		Not Object.OrderSales Or (Object.OrderSales And SalesInExcessOfOrder));

	TMCommonUseClientServer.SetFormItemProperty(Items, "GoodsFillInTheWarehouseInSelectedLines", 
																			"Visible", Not Object.OrderSales);

	If Not Object.OrderSales Then
		TMCommonUseClientServer.SetFormItemProperty(Items, "GoodsFillInTheWarehouseInSelectedLines",
																							 "Enabled", WarehouseGroup_);
	EndIf;
	
	AvailabilityOfItemsIfImplementedByOrder = (Not Object.OrderSales);
	
	ItemArray = New Array;
	
	ItemArray.Add("GoodsImportDataFromPDT");
	
	ItemArray.Add("ToReadLoyaltyCard");
	ItemArray.Add("ToReadLoyaltyCardClient");
	ItemArray.Add("LoyaltyCard");
	
	If Not SalesInExcessOfOrder Then
		ItemArray.Add("GoodsCopy");
		ItemArray.Add("ProductItemsContextMenuCopy");
		ItemArray.Add("GoodsSplitRow");
		ItemArray.Add("GoodsContextMenuSplitRow");
		ItemArray.Add("GoodsSearchByBarcode");
		
		ItemArray.Add("GoodsCancelManualDiscounts");
		ItemArray.Add("GoodsAssignAManualDiscount");
		ItemArray.Add("GoodsAssignAManualDiscountToSelectedRows");
		ItemArray.Add("GoodsAssignAutomaticDiscounts");
	EndIf;
		
	TMCommonUseClientServer.SetPropertyOfFormElements(Items, ItemArray, "Enabled", AvailabilityOfItemsIfImplementedByOrder);
	
	If Object.OrderSales And Not UserRightsCached.VarianceFromSalesTermsAndConditions()
		And (ValueIsFilled(Object.SalesOrder) Or OrderList.Count() > 0) Then
		
		ItemArray = New Array;
		
		// Header Controls
		ItemArray.Add("Partner");
		ItemArray.Add("Terms");
		ItemArray.Add("Contract");
		ItemArray.Add("PriceIncludesVAT");
		ItemArray.Add("Organization");
		ItemArray.Add("Counterparty");
		
		ItemArray.Add("VATTaxation");
		ItemArray.Add("Department");
		ItemArray.Add("OrderSales");
		ItemArray.Add("CustomImplementation");
		ItemArray.Add("LoyaltyCard");
		
		If Not SalesInExcessOfOrder Then
			ItemArray.Add("GoodsProducts");
			ItemArray.Add("GoodsRowCode");
			ItemArray.Add("GoodsCharacteristic");
			ItemArray.Add("GoodsPackage");
			ItemArray.Add("GoodsPriceKind");

			ItemArray.Add("GoodsPercentRateOfManualDiscount");
			ItemArray.Add("GoodsManualDiscount");
			ItemArray.Add("GoodsVATRate");
			
		EndIf;
		
		ItemArray.Add("Warehouse");
		ItemArray.Add("BusinessOperation");
		ItemArray.Add("ToReturnReusablePackage");
		ItemArray.Add("PackageDepositIsRequired");
		ItemArray.Add("ReusablePackagesReturnDate");
		
		TMCommonUseClientServer.SetPropertyOfFormElements(Items, ItemArray, "ReadOnly", True);
		
		ItemArray = New Array;
		ItemArray.Add("GoodsFillThePricesByTermsOfSales");
		ItemArray.Add("GoodsFillInPricesOfSelectedRowsByPriceType");
		ItemArray.Add("GoodsCancelManualDiscounts");
		ItemArray.Add("GoodsAssignAManualDiscount");
		ItemArray.Add("GoodsAssignAManualDiscountToSelectedRows");
		ItemArray.Add("GoodsFillInVATRate");
		
		TMCommonUseClientServer.SetPropertyOfFormElements(Items, ItemArray, "Enabled", SalesInExcessOfOrder);
		
	EndIf;
	
EndProcedure

&AtServer
Procedure SetVisibilityOfElementsByOperationServer()
	
	Var ArrayOfAllProps;
	Var ArrayOfOperationDetails;
	
	Documents.CustomerInvoice.FillInNamesOfBusinessTransactionDetails(
		Object.BusinessOperation, 
		ArrayOfAllProps, 
		ArrayOfOperationDetails);
		
	CashServer.SetVisibilityOfElementsByArray(
		Items,
		ArrayOfAllProps,
		ArrayOfOperationDetails);
	
	ProductsServer.SetProductSelectionParameters(Object.BusinessOperation, Items.GoodsProducts);
	
	// Transfer to a commission, Sale through a commission agent
	// and Transfer of ownership
	
	ThisIsTransferToCommission =
		(Object.BusinessOperation = Enums.BusinessTransactions.TransferToCommissionAgent);
	ThisIsTransferOfOwnership =
		(Object.BusinessOperation = Enums.BusinessTransactions.TransferOfTitleToGoods);
	
	ItemArray = New Array();
	ItemArray.Add("GoodsCalculateDiscountsMarkups");
	ItemArray.Add("GoodsCancelManualDiscounts");
	ItemArray.Add("GoodsAssignAManualDiscount");
	ItemArray.Add("GoodsAssignAManualDiscountToSelectedRows");
	ItemArray.Add("GoodsAssignAutomaticDiscounts");
	ItemArray.Add("GoodsOpenInformationAboutDiscounts");
	ItemArray.Add("TheProductsContextMenuOpensInformationAboutDiscounts");
	ItemArray.Add("DiscountAmount");
	
	ItemArray.Add("ToReadLoyaltyCard");
	ItemArray.Add("ToReadLoyaltyCardClient");
	ItemArray.Add("LoyaltyCard");
	
	TMCommonUseClientServer.SetPropertyOfFormElements(Items, ItemArray, "Visible", Not ThisIsTransferToCommission And Not SalesViaCommissionAgent);
	
	// Transmission to the Commission
	
	ItemArray = New Array();
	ItemArray.Add("PaymentHeader");
	TMCommonUseClientServer.SetPropertyOfFormElements(Items, ItemArray, "Visible", Not ThisIsTransferToCommission);
	
	// Sale through a commission agent, Transfer of ownership
	
	ItemArray = New Array();
	ItemArray.Add("SaleRegistrationOption");
	ItemArray.Add("Warehouse");
	
	TMCommonUseClientServer.SetPropertyOfFormElements(Items,
		ItemArray,
		"Visible",
		Not (SalesViaCommissionAgent Or ThisIsTransferOfOwnership));
	
	ItemArray = New Array();
	ItemArray.Add("SalesByOrderGroup");
	
	TMCommonUseClientServer.SetPropertyOfFormElements(Items,
		ItemArray,
		"Visible",
		Not SalesViaCommissionAgent);
	
	Items.GroupClientData.Visible = SalesViaCommissionAgent;
	BackgroundTaskData = GoodsDelivery.WhenReadingCreatingOrdersOnServer(Items,
		Object,
		Object.OrderSales Or SalesViaCommissionAgent,,,
		True);
	
	Items.Partner.Title = 		?(SalesViaCommissionAgent, NStr("vi = 'Người nhận ký gửi';
																	|ru = 'Комиссионер';
																	|en = 'Consignee'; fa = 'امانت‌دار';
																	|it = 'Commissionario';
																	|pl = 'Consignee';
																	|tr = 'Konsinye'"), "");
	Items.Counterparty.Title = 	?(SalesViaCommissionAgent, NStr("vi = 'Đối tác của người nhận ký gửi';
																	|ru = 'Контрагент комиссионера';
																	|en = 'Consignee''s counterparty'; fa = 'طرف حساب امانت‌دار';
																	|it = 'Controparte commissionario';
																	|pl = 'Kontrahent komisanta';
																	|tr = 'Konsinye cari hesap'"), "");
	
	SetHeadingProductsSenderGroup();
	
	Items.GoodsSelectGoodsByOrdersNotes.Visible 	= Not SalesViaCommissionAgent;
	Items.GoodsSelectTransferredGoods.Visible			= SalesViaCommissionAgent;
	
	Items.DecorationIndentDepositRequiredForPackaging.Visible = Items.PackageDepositIsRequired.Visible;
	
	SetParametersForSelectingPriceType();
	
	Items.CustomImplementation.Enabled = Not Object.BusinessOperation = Enums.BusinessTransactions.SaleToCustomerLocalAccounting;
	Items.OrderSales.Enabled = Not Object.BusinessOperation = Enums.BusinessTransactions.SaleToCustomerLocalAccounting;
	
	SetVisibilityOfCommandToFillInContractPriceView();
	
	SetPropertiesOfOutdatedCommissionUsageComment();
	
	Items.GroupPricesDiscounts.Title = ?(ThisIsTransferToCommission Or SalesViaCommissionAgent, NStr("vi = 'Đơn giá';
																									|ru = 'Цены';
																									|en = 'Prices'; fa = 'قیمت‌ها';
																									|it = 'Prezzi';
																									|pl = 'Prices';
																									|tr = 'Fiyatlar'"), NStr("vi = 'Đơn giá và chiết khấu';
																															|ru = 'Цены и скидки';
																															|en = 'Prices and discounts'; fa = 'قیمت‌ها و تخفیف‌ها';
																															|it = 'Prezzi e sconti';
																															|pl = 'Ceny i rabaty';
																															|tr = 'Fiyatlar ve indirimler'"));
	
EndProcedure

&AtServer
Procedure FillOperationSelectionList(SetOperation = True)
	
	UseCustomerContracts = GetFunctionalOption("UseCustomerContracts");
	
	If Not ToUseTermsOfSales Then
		
		SaleWithDeferredTransferOfTitleIsAllowed =
			UseShipmentWithDeferredTransferOfTitle2_0
				Or UseShipmentWithDeferredTransferOfTitle2_5;
		
	ElsIf Not ValueIsFilled(Object.Terms) Then
		
		SaleWithDeferredTransferOfTitleIsAllowed =
			UseShipmentWithDeferredTransferOfTitle2_0
				Or UseShipmentWithDeferredTransferOfTitle2_5;
		
	Else
			
		TheseAgreements = Common.ObjectAttributesValues(
			Object.Terms,
			"SaleWithDeferredTransferOfTitleIsAllowed, ContractsAreUsed");
			
		UseCustomerContracts = TheseAgreements.ContractsAreUsed;
			
		SaleWithDeferredTransferOfTitleIsAllowed =
			TheseAgreements.SaleWithDeferredTransferOfTitleIsAllowed
				And (UseShipmentWithDeferredTransferOfTitle2_0
					Or UseShipmentWithDeferredTransferOfTitle2_5);
			
	EndIf;
	
	If Items.Find("BusinessOperation") <> Undefined Then
		
		TransferToCommissionElement = 
			Items.BusinessOperation.ChoiceList.FindByValue(Enums.BusinessTransactions.TransferToCommissionAgent);
		ItemSalesThroughCommissionAgent = 
			Items.BusinessOperation.ChoiceList.FindByValue(Enums.BusinessTransactions.SalesViaCommissionAgent);
		ItemSaleThroughCommissionAgentWithoutTransferOfOwnership = 
			Items.BusinessOperation.ChoiceList.FindByValue(Enums.BusinessTransactions.SalesViaCommissionAgentGoodsInTransit);
		ElementImplementationWithoutTransferOfOwnership = 
			Items.BusinessOperation.ChoiceList.FindByValue(Enums.BusinessTransactions.SaleWithDeferredTransferOfTitle);
		ElementTransferOfOwnership = 
			Items.BusinessOperation.ChoiceList.FindByValue(Enums.BusinessTransactions.TransferOfTitleToGoods);
		
		If Not GetFormFunctionalOption("UseManagementCompany") Then
			ListItem = Items.BusinessOperation.ChoiceList.FindByValue(Enums.BusinessTransactions.SaleToCustomerLocalAccounting);
			If ListItem <> Undefined Then
				Items.BusinessOperation.ChoiceList.Delete(ListItem);
			EndIf;
		EndIf;
		
		If Not UseShipmentWithDeferredTransferOfTitle2_0
			And ElementImplementationWithoutTransferOfOwnership <> Undefined Then
			Items.BusinessOperation.ChoiceList.Delete(ElementImplementationWithoutTransferOfOwnership);
		EndIf;
		
		If (Not UseShipmentWithDeferredTransferOfTitle2_5
			Or Not UseCustomerContracts)
			And ElementTransferOfOwnership <> Undefined Then
			Items.BusinessOperation.ChoiceList.Delete(ElementTransferOfOwnership);
		EndIf;
		
		If SaleWithDeferredTransferOfTitleIsAllowed Then
			
			If UseShipmentWithDeferredTransferOfTitle2_0
				And ElementImplementationWithoutTransferOfOwnership = Undefined Then
				
				Items.BusinessOperation.ChoiceList.Add(
					Enums.BusinessTransactions.SaleWithDeferredTransferOfTitle);
				
			EndIf;
			
			If UseShipmentWithDeferredTransferOfTitle2_5
				And UseCustomerContracts
				And ElementTransferOfOwnership = Undefined Then
				
				Items.BusinessOperation.ChoiceList.Add(
					Enums.BusinessTransactions.TransferOfTitleToGoods);
				
			EndIf;
			
		EndIf;
		
		If GetFormFunctionalOption("UseSalesCommission") Then
			
			Template = NStr("vi = '%1 (%2)';
							|ru = '%1 (%2)';
							|en = '%1 (%2)'; fa = '%1 (%2)';
							|it = '%1 (%2)';
							|pl = '%1 (%2)';
							|tr = '%1 (%2)'");
			
			If GetFormFunctionalOption("OnlyConsignmentSales25")
				Or Not GetFormFunctionalOption("ToUseTermsOfSales") Then
				If TransferToCommissionElement <> Undefined Then
					Items.BusinessOperation.ChoiceList.Delete(TransferToCommissionElement);
					TransferToCommissionElement = Undefined;
				EndIf;
			Else
				If TransferToCommissionElement <> Undefined Then
					TransferToCommissionElement.Presentation = StrTemplate(Template, 
						Enums.BusinessTransactions.TransferToCommissionAgent, ConsignmentSalesServer.PostfixCommissionSchemes());
				EndIf;
				If ItemSalesThroughCommissionAgent <> Undefined Then
					ItemSalesThroughCommissionAgent.Presentation = StrTemplate(Template,
						Enums.BusinessTransactions.SalesViaCommissionAgent, 
						ConsignmentSalesServer.PostfixCommissionSchemes25());
				EndIf;
			EndIf;
			
			If Not GetFunctionalOption("SelectConsignmentSalesVersion") 
				And Object.BusinessOperation <> Enums.BusinessTransactions.TransferToCommissionAgent Then
				If TransferToCommissionElement <> Undefined Then
					Items.BusinessOperation.ChoiceList.Delete(TransferToCommissionElement);
				EndIf;
			EndIf;
			
			If Not UseShipmentWithDeferredTransferOfTitle2_0
				And ItemSaleThroughCommissionAgentWithoutTransferOfOwnership <> Undefined Then
				Items.BusinessOperation.ChoiceList.Delete(ItemSaleThroughCommissionAgentWithoutTransferOfOwnership);
			EndIf;
			
			If SaleWithDeferredTransferOfTitleIsAllowed
				And UseShipmentWithDeferredTransferOfTitle2_0 Then
				
				If ItemSaleThroughCommissionAgentWithoutTransferOfOwnership = Undefined Then
					Items.BusinessOperation.ChoiceList.Add(
						Enums.BusinessTransactions.SalesViaCommissionAgentGoodsInTransit);
				ElsIf Not GetFormFunctionalOption("OnlyConsignmentSales25") Then
					ItemSaleThroughCommissionAgentWithoutTransferOfOwnership.Presentation = StrTemplate(Template, 
						Enums.BusinessTransactions.SalesViaCommissionAgentGoodsInTransit,
						ConsignmentSalesServer.PostfixCommissionSchemes25());
				EndIf;
				
			EndIf;
			
		Else
			
			If TransferToCommissionElement <> Undefined Then
				Items.BusinessOperation.ChoiceList.Delete(TransferToCommissionElement);
			EndIf;
			If ItemSalesThroughCommissionAgent <> Undefined Then
				Items.BusinessOperation.ChoiceList.Delete(ItemSalesThroughCommissionAgent);
			EndIf;
			If ItemSaleThroughCommissionAgentWithoutTransferOfOwnership <> Undefined Then
				Items.BusinessOperation.ChoiceList.Delete(ItemSaleThroughCommissionAgentWithoutTransferOfOwnership);
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
Procedure UpdateAdditionalAttributesItems()
	
	PropertyManager.UpdateAdditionalAttributesItems(ThisForm);
	
EndProcedure

&AtServer
Function PutGoodsAndStockTypesInStorage()
	
	OptionsForEditingInventoryTypes = InventoriesServer.OptionsForEditingInventoryTypes();
	
	If SalesViaCommissionAgent Then
		OptionsForEditingInventoryTypes.Warehouse = Object.Contract;
	EndIf;
	If Documents.CustomerInvoice.ExcisableGoodsAreUsed(Object) Then
		OptionsForEditingInventoryTypes.DisplayExciseTaxAmount = True;
		OptionsForEditingInventoryTypes.UseExcisableGoods = True;
	EndIf;
	Return InventoriesServer.PutGoodsAndStockTypesInStorage(ThisObject, OptionsForEditingInventoryTypes);
	
EndFunction

&AtServer
Procedure GetStockTypesFromStorage(ValueSelected)
	
	InventoriesServer.ProcessInputOfInventoryTypesManually(ValueSelected, ThisForm);
	
EndProcedure

&AtServer
Procedure DeleteTSDiscountMarkUpLines(StringTSGoods)
	
	If ValueIsFilled(StringTSGoods.ConnectionKey) Then
		
		For Each RowToDelete In Object.DiscountsMarkups.FindRows(New Structure("ConnectionKey", StringTSGoods.ConnectionKey)) Do
			
			Object.DiscountsMarkups.Delete(RowToDelete);
			
		EndDo;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure AutoTestFillInPricesByAgreement(Command) Export
	
	FillThePricesByTermsOfSales(Command);
	
EndProcedure 

&AtServer
Procedure SetOrderSchemeForShipment()
	
	If GetFunctionalOption("UseWarehouseManagementSystem") 
		And Object.BusinessOperation <> Enums.BusinessTransactions.TransferOfTitleToGoods Then
		WarehousesOfTablePart = Object.Goods.Unload(, "Warehouse");
		WarehousesOfTablePart.GroupBy("Warehouse");
		UniqueWarehouses = WarehousesOfTablePart.UnloadColumn("Warehouse");
		Value = WarehousesServer.ThereIsOrderWarehouseForShipment(UniqueWarehouses, Object.Date, Object.Warehouse);
	Else
		Value = False;
	EndIf;

	AdvancedWarehousingOnShipment = Value;

EndProcedure

&AtServer
Procedure WhenChangingWarehouseInTablePartServer()
	
	WarehousesServer.WhenChangingWarehouseInTablePart(Object.Goods, WarehouseTable, WarehouseGroup_, False);
	TotalWarehouses_ = WarehouseTable.Count();
	WarehousesClientServer.UpdateWarehouseGroupImage(SeveralWarehousesText, Items.PictureMultipleWarehouses, TotalWarehouses_);
	
	UpdateDependentDetailsOfServerByOrderForm();
	SetOrderSchemeForShipment();

EndProcedure

&AtServer
Function AddressOfDataForCalculatingManualDiscountsInTemporaryStorage(SelectedLinesOnly)
	
	ParametersStructure = DiscountsMarkupsFillingServer.NewParametersAddressDataForCalculatingManualDiscounts();
	ParametersStructure.TableName				 = "Goods";
	ParametersStructure.OnlyForSelectedLines = SelectedLinesOnly;
	ParametersStructure.SalesInExcessOfOrder	 = SalesInExcessOfOrder And Object.OrderSales;
	Return DiscountsMarkupsFillingServer.AddressOfDataForCalculatingManualDiscountsInTemporaryStorage(
		ThisForm, UUID, ParametersStructure);
	
EndFunction

&AtServerNoContext
Procedure CheckForAdjustments(Ref, ThereAreAdjustingEntries)
	
	SalesServer.CheckForAdjustments(Ref, Ref, ThereAreAdjustingEntries)
	
EndProcedure

&AtServerNoContext
Function HaveRightToAddAdjustments()
	
	Return AccessRight("Insert", Metadata.Documents.SaleAdjustment);
	
EndFunction

&AtClient
Procedure OpenPrintDetails()
		
	Try
		LockFormDataForEdit();
	Except
		ShowMessageBox(Undefined, BriefErrorDescription(ErrorInfo()));
		Return;
	EndTry;
	
	PerformanceMonitorClient.TimeMeasurement(True,
		"Document.CustomerInvoice.DocumentForm.Command.OpenPrintDetails");
	
	DeliveryOrderData = GoodsDeliveryClientServer.OrderParameters();
	FillPropertyValues(DeliveryOrderData, Object);
	
	ParametersStructure = New Structure();
	ParametersStructure.Insert("DeliveryAddress",                   Object.DeliveryAddress);
	ParametersStructure.Insert("DeliveryAddressValue",           Object.DeliveryAddressValue);
	ParametersStructure.Insert("DeliveryAddressFieldValues",      Object.DeliveryAddressFieldValues);
	ParametersStructure.Insert("DeliveryZone",                    Object.DeliveryZone);
	ParametersStructure.Insert("DeliveryTimeFrom",                  Object.DeliveryTimeFrom);
	ParametersStructure.Insert("DeliveryTimeTo",                 Object.DeliveryTimeTo);
	ParametersStructure.Insert("AdditionalDeliveryInformation", Object.AdditionalDeliveryInformation);
	ParametersStructure.Insert("DeliveryOrderData",    DeliveryOrderData);
	ParametersStructure.Insert("Ref",                          Object.Ref);
	ParametersStructure.Insert("ShipperBankAccount",  Object.ShipperBankAccount);
	ParametersStructure.Insert("GoodsRecipientBankAccount",   Object.GoodsRecipientBankAccount);
	ParametersStructure.Insert("CounterpartyBankAccount",       Object.CounterpartyBankAccount);
	ParametersStructure.Insert("Shipper",                Object.Shipper);
	ParametersStructure.Insert("GoodsRecipient",                 Object.GoodsRecipient);
	ParametersStructure.Insert("LetterOfAuthorityIssuedBy",              Object.LetterOfAuthorityIssuedBy);
	ParametersStructure.Insert("PowerOfAttorneyDate",                Object.PowerOfAttorneyDate);
	ParametersStructure.Insert("PowerOfAttorneyPerson",                Object.PowerOfAttorneyPerson);
	ParametersStructure.Insert("PowerOfAttorneyNumber",               Object.PowerOfAttorneyNumber);
	ParametersStructure.Insert("Contract",                         Object.Contract);
	ParametersStructure.Insert("Basis",                       Object.Basis);
	ParametersStructure.Insert("ReferenceDocumentDateForPrintForms",                   Object.ReferenceDocumentDateForPrintForms);
	ParametersStructure.Insert("BaseDocumentNumber",                  Object.BaseDocumentNumber);
	ParametersStructure.Insert("IssuiedBy",                        Object.IssuiedBy);
	ParametersStructure.Insert("IssuiedByJobTitle",               Object.IssuiedByJobTitle);
	ParametersStructure.Insert("Partner",                         Object.Partner);
	ParametersStructure.Insert("BusinessOperation",           Object.BusinessOperation);
	ParametersStructure.Insert("Counterparty",                      Object.Counterparty);
	ParametersStructure.Insert("ReadOnly",                  ReadOnly);
	ParametersStructure.Insert("ObjectType",                     "CustomerInvoice");
	ParametersStructure.Insert("OrderSales",             Object.OrderSales);
	ParametersStructure.Insert("CompanyBankAccount",       Object.CompanyBankAccount);
	ParametersStructure.Insert("Organization",                     Object.Organization);
	ParametersStructure.Insert("Date",                            Object.Date);
	ParametersStructure.Insert("Director",                    Object.Director);
	ParametersStructure.Insert("ChiefAccountant",                Object.ChiefAccountant);
	ParametersStructure.Insert("PrintBasisTable",       PrintBasisTable);
	ParametersStructure.Insert("InformationOnTransportationAndCargo",  Object.InformationOnTransportationAndCargo);
	ParametersStructure.Insert("SupportingDocuments",       Object.SupportingDocuments);
	ParametersStructure.Insert("SalesViaCommissionAgent",     SalesViaCommissionAgent);
	ParametersStructure.Insert("DeliveryIsRequired", Object.DeliveryIsRequired);
	ParametersStructure.Insert("DeliverySpecificationMethod", PredefinedValue("Enum.DeliverySpecificationMethods.ForWholeDocument"));
	
	OpenForm("CommonForm.PrintingDetailsOfSales", ParametersStructure, ThisObject,,,, Undefined, FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtServerNoContext
Function ItIsGroupOfWarehousesAndWarehousesUsedByWHForSale(Warehouse)
	
	Return Catalogs.Warehouses.ThisGroupAndWarehousesAreUsedByWHForSales(Warehouse);
	
EndFunction 

&AtServer
Procedure FillIn_TermsOfSales()
	
	BusinessTransaction = Object.BusinessOperation;
	Contract = Object.Contract;
	
	DocumentSales = FormAttributeToValue("Object");
	DocumentSales.FillInDefaultSalesConditions();
	ValueToFormAttribute(DocumentSales, "Object");
	
	Terms = Object.Terms;	
	
	DocumentCurrency = Object.Currency;
	FillOperationSelectionList();
	If BusinessTransaction = Enums.BusinessTransactions.SaleToCustomerLocalAccounting Then
		Object.BusinessOperation = BusinessTransaction;
	EndIf;
	
	Counterparty = Object.Counterparty;
	PartnersAndCounterparties.FillInPartnerSDefaultCounterparty(Object.Partner, Object.Counterparty);
	If Counterparty <> Object.Counterparty Then
		Object.CounterpartyBankAccount =
			GetDefaultCounterpartyBankAccountServer(Object.Counterparty, Object.CompanyBankAccount);
	EndIf;
	BusinessOperationOnChangeServer();
	If Contract <> Object.Contract Then
		ContractOnChangeServer();
	EndIf;
	
	SalesServer.SetContractAvailability(Object, Items.Contract.Enabled, Items.ContractGroup.Visible, Object.Contract);
	Items.GroupLabelContract.Visible = Items.ContractGroup.Visible;
	
EndProcedure

&AtServerNoContext
Procedure UpdateAvailabilityOfReturnContainerItems(Form)
	
	ItemArray = New Array();
	ItemArray.Add("ReusablePackagesReturnDate");
	ItemArray.Add("PackageDepositIsRequired");
	
	SalesNotThroughCommissionAgent = Not Form.SalesViaCommissionAgent;
	
	Form.Items.TareGroup.Visible                 = SalesNotThroughCommissionAgent;
	Form.Items.GroupRequiresADepositForPackaging.Visible = SalesNotThroughCommissionAgent;
	
	TMCommonUseClientServer.SetPropertyOfFormElements(
		Form.Items,
		ItemArray,
		"Enabled",
		Form.Object.ToReturnReusablePackage);
	
	TMCommonUseClientServer.SetFormItemProperty(
		Form.Items,
		"ToReturnReusablePackage",
		"Enabled",
		Form.Object.BusinessOperation <> Enums.BusinessTransactions.SaleToCustomerLocalAccounting
			And SalesNotThroughCommissionAgent);
	
EndProcedure

&AtServer
Procedure FillMultiTurnContainersFromStorageServer(AddressOfContainerInStorage)
	
	ParametersONChangingTypeOfItem = New Structure;
	ParametersONChangingTypeOfItem.Insert("ThereAreWorks", True);
	ParametersONChangingTypeOfItem.Insert("IsCanceled", False);
	ParametersONChangingTypeOfItem.Insert("ThisIsTransferOfOwnership",
		Object.BusinessOperation =
			PredefinedValue("Enum.BusinessTransactions.TransferOfTitleToGoods"));
	
	ParametersForFillingInVATAmountLocalManSManSManSManSManSManSManSManS = BatchProcessingOfTablePartClientServer.ParametersForFillingInVATAmountLocalManSManSManSManSManSManSManSManS(
		Object.Currency,
		LocalAccountingCurrency,
		ManagementAccountingCurrency);
	
	ActionStructureModifiedStrings = New Structure;
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	ActionStructureModifiedStrings.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
	ActionStructureModifiedStrings.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));
	ActionStructureModifiedStrings.Insert("RecalculateNumberOfPackages");
	ActionStructureModifiedStrings.Insert("FillInVATRate", BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRate(Object));
	ActionStructureModifiedStrings.Insert("FillInHSCode", Object.VATTaxation);
	ActionStructureModifiedStrings.Insert("FillInVATRateForReturnableContainers", Object.ToReturnReusablePackage);
	ActionStructureModifiedStrings.Insert("FillInNoReturnContainerAttribute", Object.ToReturnReusablePackage);
	ActionStructureModifiedStrings.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	ActionStructureModifiedStrings.Insert("RecalculateAmount");
	ActionStructureModifiedStrings.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	ActionStructureModifiedStrings.Insert("RecalculateAmountTakingIntoAccountManualDiscount", New Structure("Clear", True));
	ActionStructureModifiedStrings.Insert("RecalculateAmountTakingIntoAccountAutomaticDiscount", New Structure("Clear", True));
	ActionStructureModifiedStrings.Insert("RecalculateAmountTakingIntoAccountDiscountWithBonusPoints");
	ActionStructureModifiedStrings.Insert("ClearAmountOfSettlements");
	ActionStructureModifiedStrings.Insert("SetVATAmountLocalMans", ParametersForFillingInVATAmountLocalManSManSManSManSManSManSManSManS);
	ActionStructureModifiedStrings.Insert("FillInDuplicateDependentDetails", DependentDetails());
	ActionStructureModifiedStrings.Insert("WhenChangingProductType", ParametersONChangingTypeOfItem);
	
	StructureOfActionsAddedLines =  CommonClientServer.CopyStructure(ActionStructureModifiedStrings);
	StructureOfActionsAddedLines.Insert("CheckFillWarehouse", BatchProcessingOfTablePartClientServer.GetWarehouseFillStructureInTSLine(Object, WarehouseGroup_));
	LinesOfBusinessClientServer.StructureOfInsertActionsWhenAddingRow(ThisForm, StructureOfActionsAddedLines);
	If (ToUseTermsOfSales And ValueIsFilled(Object.Terms)) 
		Or (Not ToUseTermsOfSales And UsePriceManagementSystem25) Then
		StructureOfActionsAddedLines.Insert("FillIn_TermsOfSales", BatchProcessingOfTablePartClientServer.GetStructureForFillingInSalesConditionsInTSLine(Object));
	Else
		StructureOfActionsAddedLines.Insert("FillInSalePrice", BatchProcessingOfTablePartClientServer.ParametersForFillingInPriceInTSLine(Object));
	EndIf;
	StructureOfActionsAddedLines.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
	StructureOfActionsAddedLines.Insert("WhenChangingProductType", ParametersONChangingTypeOfItem);
	StructureOfActionsAddedLines.Insert("FillInSubdivisionInTSLine", New Structure("Department", Object.Department));
	
	ReusablePackageServer.FillMultiTurnContainersFromStorage(
		Object,
		AddressOfContainerInStorage,
		"Goods",
		"Products,Characteristic,Warehouse",
		ActionStructureModifiedStrings,
		StructureOfActionsAddedLines);
		
	FillInServiceDetailsForProductRange();
	
	CalculateTotals_(ThisObject);
	WhenChangingWarehouseInTablePartServer();
	FillInStatusesForSpecifyingSeriesServer();
	
EndProcedure

&AtClientAtServerNoContext
Function DependentDetails()
	
	Return New Structure(
		"WithoutReusablePackages",
		"Sum,VATAmount,AmountIncludingVAT,DiscountMarkupAmount,ManualDiscount,AmountOfBonusPointsToDeductionInCurrency");
	
EndFunction

&AtClientAtServerNoContext
Function DependentPropsByString()
	
	Return "SumWithoutReusablePackages,VATAmountWithoutReusablePackages,AmountIncludingVATWithoutReusablePackages,
			|DiscountMarkupAmountWithoutReusablePackages,ManualDiscountWithoutReusablePackages,
			|AmountOfBonusPointsToDeductionInCurrencyWithoutReusablePackages";
	
EndFunction

&AtServer
Procedure EstablishVisibilityOfStatusAndDateOfTransferOfOwnership()
	
	Items.DateOfTransferOfTitleToGoods.Visible = 
		(Object.BusinessOperation = Enums.BusinessTransactions.SaleWithDeferredTransferOfTitle
			Or Object.BusinessOperation = Enums.BusinessTransactions.SalesViaCommissionAgentGoodsInTransit)
		And Object.Status <> Enums.StatusesOfCustomerInvoices.ForPrepayment;
		
	Items.Status.Visible = 
		(Not Object.OrderSales
			Or Object.BusinessOperation = Enums.BusinessTransactions.SaleWithDeferredTransferOfTitle
			Or Object.BusinessOperation = Enums.BusinessTransactions.SalesViaCommissionAgentGoodsInTransit)
		And Object.BusinessOperation <> Enums.BusinessTransactions.SaleToCustomerLocalAccounting
		And Object.BusinessOperation <> Enums.BusinessTransactions.TransferToCommissionAgent
		And Object.BusinessOperation <> Enums.BusinessTransactions.SalesViaCommissionAgent
		And Object.BusinessOperation <> Enums.BusinessTransactions.TransferOfTitleToGoods;
		
EndProcedure

&AtServer
Procedure ToReturnReusablePackageOnChangeServer()
	
	If Not Object.ToReturnReusablePackage Then
		Object.PackageDepositIsRequired = False;
	EndIf;
	
	ParametersForFillingInVATAmountLocalManSManSManSManSManSManSManSManS = BatchProcessingOfTablePartClientServer.ParametersForFillingInVATAmountLocalManSManSManSManSManSManSManSManS(
		Object.Currency,
		LocalAccountingCurrency,
		ManagementAccountingCurrency);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
	StructureOfActions.Insert("FillInNoReturnContainerAttribute", Object.ToReturnReusablePackage);
	StructureOfActions.Insert("FillInVATRateForReturnableContainers", Object.ToReturnReusablePackage);
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForRecalculatingNDSWTCHAmount(Object);
	StructureOfActions.Insert("ClearAmountOfSettlements");
	StructureOfActions.Insert("SetVATAmountLocalMans", ParametersForFillingInVATAmountLocalManSManSManSManSManSManSManSManS);
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));
	BatchProcessingOfTablePartServer.TreatTS(Object.Goods, StructureOfActions, Undefined);
	
	TMCommonUse.FillInDuplicateDependentPropsInCollection(Object.Goods, DependentDetails());
	UpdateAvailabilityOfReturnContainerItems(ThisForm);
	
	CalculateTotals_(ThisObject);
	
EndProcedure

&AtServer
Procedure PackagingDepositIsRequiredWhenChangeIsMadeOnServer()
	
	ParametersForFillingInVATAmountLocalManSManSManSManSManSManSManSManS = BatchProcessingOfTablePartClientServer.ParametersForFillingInVATAmountLocalManSManSManSManSManSManSManSManS(
		Object.Currency,
		LocalAccountingCurrency,
		ManagementAccountingCurrency);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("ClearAmountOfSettlements");
	StructureOfActions.Insert("SetVATAmountLocalMans", ParametersForFillingInVATAmountLocalManSManSManSManSManSManSManSManS);
	BatchProcessingOfTablePartServer.TreatTS(Object.Goods, StructureOfActions, Undefined);
	
EndProcedure

&AtServer
Procedure SetParametersForSelectingPriceType()
	
	ParametersArray = New Array();
	ParametersArray.Add(New ChoiceParameter("OutputAnArbitraryTypeOfPrices", True));
	ParametersArray.Add(New ChoiceParameter("Filter.UseWhileSellingToCustomers", True));
	ParametersArray.Add(New ChoiceParameter("Filter.Status", Enums.StatusesOfPriceTypeValidity.Valid));
	
	Items.GoodsPriceKind.ChoiceParameters = New FixedArray(ParametersArray);
	
EndProcedure

&AtServer
Procedure UpdateDependentDetailsOfServerByOrderForm()
	
	If Object.Goods.Count() = 0 Or Not Object.OrderSales Or Not UseSalesOrders Then
		Items.GroupDiscrepancyOnOrder.Visible = False;
		Items.GroupDiscrepancyOnOrders.Visible = False;
		DiscrepancyOrderText = "";
		
		If Object.Goods.Count()>0 Then
			For Each LineProducts_ In Object.Goods Do
				
				LineProducts_.OrderDiscrepancy_3 = 0;
				
			EndDo;
		EndIf;
		
		SetAvailabilityVisibilityOfDeliveryItems(ThisObject);
		Return;
	EndIf;
	
	UpdateDependentDetailsOfOrderForm_(ThisObject, DiscrepancyOrderText);
	
EndProcedure

&AtClientAtServerNoContext
Procedure UpdateDependentDetailsOfOrderForm_(Form, DiscrepancyOrderText)
	
	Object = Form.Object;
	Goods = Object.Goods;
	FormItems = Form.Items;
	
	ThisIsTransferOfOwnership = (Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.TransferOfTitleToGoods"));
	NumberOfDiscrepancies = Goods.Total("OrderDiscrepancy_3");
	
	FormItems.GroupDiscrepancyOnOrder.Visible = NumberOfDiscrepancies > 0;
	FormItems.GroupDiscrepancyOnOrders.Visible = NumberOfDiscrepancies > 0;
	
	If NumberOfDiscrepancies > 0 Then
		If ThisIsTransferOfOwnership Then
			DiscrepancyOrderText = StrReplace(NStr("vi = 'Các dòng vượt quá lệnh';
													|ru = 'Строк сверх распоряжения';
													|en = 'Lines in excess of reference'; fa = 'Lines in excess of reference';
													|it = 'Lines in excess of reference';
													|pl = 'Lines in excess of reference';
													|tr = 'Sipariş fazlası satırı'") + NStr("vi = ': %NumberOfDiscrepancies%';
																								|ru = ': %NumberOfDiscrepancies%';
																								|en = ': %NumberOfDiscrepancies%'; fa = ': %NumberOfDiscrepancies%';
																								|it = ': %NumberOfDiscrepancies%';
																								|pl = ': %NumberOfDiscrepancies%';
																								|tr = ': %NumberOfDiscrepancies%'"), "%NumberOfDiscrepancies%", NumberOfDiscrepancies);
		Else
			DiscrepancyOrderText = StrReplace(NStr("vi = 'Dòng khác với đơn hàng';
													|ru = 'Строк сверх заказа';
													|en = 'Lines exceeding the order'; fa = 'Lines exceeding the order';
													|it = 'Righe oltre ordine';
													|pl = 'Wierzy przewyższających zamówienie';
													|tr = 'Sipariş fazlası satırı'") + NStr("vi = ': %NumberOfDiscrepancies%';
																								|ru = ': %NumberOfDiscrepancies%';
																								|en = ': %NumberOfDiscrepancies%'; fa = ': %NumberOfDiscrepancies%';
																								|it = ': %NumberOfDiscrepancies%';
																								|pl = ': %NumberOfDiscrepancies%';
																								|tr = ': %NumberOfDiscrepancies%'"), "%NumberOfDiscrepancies%", NumberOfDiscrepancies);
		EndIf;
	Else
		DiscrepancyOrderText = "";
	EndIf;
	
	SetAvailabilityVisibilityOfDeliveryItems(Form);
	
EndProcedure

&AtClient
Procedure NotifyAboutEndOfUnbindingLines(NumberOfLinesWorked, LinesWereUnlinked = True)

	If LinesWereUnlinked Then
		
		If Object.BusinessOperation =
			PredefinedValue("Enum.BusinessTransactions.TransferOfTitleToGoods") Then
			NotificationText1 = NStr("vi = 'Trong chứng từ, các dòng được bỏ liên kết từ các lệnh (%%Count%%).';
									|ru = 'В документе от распоряжений отвязано строк (%%Count%%).';
									|en = 'In the document, the lines (%%Count%%) are detached from the references.'; fa = 'In the document, the lines (%%Count%%) are detached from the references.';
									|it = 'Righe non associate (%%Count%%) alle disposizioni del documento.';
									|pl = 'W dokumencie od zamówień odwiązano wierszy (%%Count%%).';
									|tr = 'Belgedeki talimatlardan satırlar çıkarıldı (%%Count%%).'");
		Else
			NotificationText1 = NStr("vi = 'Trong chứng từ đã bỏ các dòng (%%Count%%) khỏi đơn hàng.';
									|ru = 'В документе от заказов отвязано строк (%%Count%%).';
									|en = 'In the document, the lines (%%Count%%) are detached from the orders.'; fa = 'In the document, the lines (%%Count%%) are detached from the orders.';
									|it = 'Righe dissociate (%%Count%%) dagli ordini nel documento.';
									|pl = 'W dokumencie odłączyć od zamówienia (%%Count%%) wierszy.';
									|tr = 'Belgede siparişlerden ayrılmış satırlar (%Count%) vardır.'");
		EndIf;
		
		NotificationText1 = StrReplace(NotificationText1, "%%Count%%", NumberOfLinesWorked);
		ShowUserNotification(
			NStr("vi = 'Các dòng liên quan';
				|ru = 'Строки отвязаны';
				|en = 'Lines were unlinked'; fa = 'Lines were unlinked';
				|it = 'Righe dissociate';
				|pl = 'Wierze odłączone';
				|tr = 'Ayrılmış satırlar'"),
			,
			NotificationText1,
			PictureLib.Information32);
	Else
		ShowUserNotification(
			NStr("vi = 'Các dòng không liên quan';
				|ru = 'Строки не отвязаны';
				|en = 'Lines were not unlinked'; fa = 'Lines were not unlinked';
				|it = 'Righe non dissociate';
				|pl = 'Wierze nie odłączone';
				|tr = 'Birleşik satırlar'"),
			,
			NStr("vi = 'Không có dòng nào liên quan.';
				|ru = 'Ни одна строка не была отвязана.';
				|en = 'No line was unlinked.'; fa = 'No line was unlinked.';
				|it = 'Nessuna riga è stata dissociata.';
				|pl = 'Nie odłączono ani jednego wiersza.';
				|tr = 'Hiçbir satır ayrılmamış'"),
			PictureLib.Information32);
	EndIf;
	
EndProcedure

&AtServer
Procedure UpdateOrderDeviations()
	
	StructureOfActions = New Structure;
	OrdersClientServer.AddActionFillInDiscrepancyOrderAttribute(StructureOfActions, Object.OrderSales);
	
	BatchProcessingOfTablePartServer.TreatTS(
		Object.Goods,
		StructureOfActions,
		Undefined);
	
EndProcedure

&AtClient
Procedure QuestionUserWhenChangingRowDetails(CallbackDescription, CurrentRow)
	
	// If the current line is not related to the order
	If CurrentRow.RowCode = 0 Then
		RunCallback(CallbackDescription, True);
		Return;
	EndIf;
	
	// If none of the key details have changed
	If CurrentRow.Products = PreviousRowDetails.Products
		And CurrentRow.Characteristic = PreviousRowDetails.Characteristic
		And (CurrentRow.Warehouse = PreviousRowDetails.Warehouse
			Or Not ValueIsFilled(PreviousRowDetails.Warehouse)
				And OrdersAreUsedAsInvoices()) Then
		RunCallback(CallbackDescription, True);
		Return;
	EndIf;
	
	AdditionalParameters = AdditionalCompletionProcessingParameters();
	AdditionalParameters.CurrentRow = CurrentRow;
	AdditionalParameters.CallbackDescription = CallbackDescription;
	
	If Object.BusinessOperation =
		PredefinedValue("Enum.BusinessTransactions.TransferOfTitleToGoods") Then
		QueryText = NStr("vi = 'Dòng đang chỉnh sửa sẽ không còn liên kết với dòng trong lệnh. Tiếp tục?';
						|ru = 'Редактируемая строка перестанет быть связанной со строкой распоряжения. Продолжить?';
						|en = 'The edited line will be unlinked from the reference line. Continue?'; fa = 'The edited line will be unlinked from the reference line. Continue?';
						|it = 'The edited line will be unlinked from the reference line. Continue?';
						|pl = 'The edited line will be unlinked from the reference line. Continue?';
						|tr = 'Düzenlenecek satır artık sipariş satırına bağlı olmayacaktır. Devam edilsin mi?'");
	Else
		QueryText = NStr("vi = 'Dòng được soạn sẽ sẽ không liên quan đến dòng của đơn hàng. Tiếp tục?';
						|ru = 'Редактируемая строка перестанет быть связанной со строкой заказа. Продолжить?';
						|en = 'The edited line will be unlinked from the order line. Continue?'; fa = 'The edited line will be unlinked from the order line. Continue?';
						|it = 'La riga da modificare non sarà più associata alla riga dell''ordine. Continuare?';
						|pl = 'Edytowany wiersz nie będzie powiązany z wierszem zamówienia. Kontynuować?';
						|tr = 'Düzenlenecek satır artık sipariş satırına bağlı olmayacaktır. Devam edilsin mi?'");
	EndIf;
	
	ShowQueryBox(
		New CallbackDescription("QuestionToUserWhenChangingDetailsOfLineQuestionCompletion", ThisObject, AdditionalParameters),
		QueryText,
		QuestionDialogMode.YesNo);
	
EndProcedure

// Parameters:
// 	Response - DialogReturnCode - 
// 	AdditionalParameters - See AdditionalCompletionProcessingParameters
&AtClient
Procedure QuestionToUserWhenChangingDetailsOfLineQuestionCompletion(Response, AdditionalParameters) Export
	
	// If the user has confirmed the change of the key Attribute value
	If Response = DialogReturnCode.Yes Then
		
		AdditionalParameters.CurrentRow.RowCode = 0;
		AdditionalParameters.LineDetachedFromOrder = True;
		RunCallback(AdditionalParameters.CallbackDescription, True);
		
	Else
		
		// If the user refused to change the linked string, we return the old values
		FillPropertyValues(AdditionalParameters.CurrentRow, PreviousRowDetails);
		RunCallback(AdditionalParameters.CallbackDescription, False);
		
	EndIf;
	
EndProcedure

&AtClient
Function ItIsPossibleToAssignManualDiscountMarkUp()
	
	ItIsPossibleToAssignManualDiscountMarkUp = DiscountsMarkupsFillingClient.ItIsPossibleToAssignManualDiscountMarkUp(Object, "Goods", NStr("vi = 'Hàng hóa';
																																			|ru = 'Товары';
																																			|en = 'Goods'; fa = 'کالاها';
																																			|it = 'Merci';
																																			|pl = 'Wiersze pozycji';
																																			|tr = 'Ürünler'"));
	
	If ItIsPossibleToAssignManualDiscountMarkUp And SalesInExcessOfOrder And Object.OrderSales And Object.Goods.Total("OrderDiscrepancy_3") = 0 Then
		
		If Object.BusinessOperation =
			PredefinedValue("Enum.BusinessTransactions.TransferOfTitleToGoods") Then
			WarningText = NStr("vi = 'Chiết khấu (phụ thu) thủ công không thể được ấn định tại các dòng theo đơn hàng.';
								|ru = 'Ручная скидка (наценка) не может быть назначена на строки по распоряжению.';
								|en = 'Discount/markup adjustment cannot be assigned in the reference lines.'; fa = 'Discount/markup adjustment cannot be assigned in the reference lines.';
								|it = 'Discount/markup adjustment cannot be assigned in the reference lines.';
								|pl = 'Discount/markup adjustment cannot be assigned in the reference lines.';
								|tr = 'İndirim (zam) düzeltmesi, sipariş satırlarına girilemez.'");
		Else
			WarningText = NStr("vi = 'Chiết khấu (phụ thu) thủ công không thể được ấn định tại các dòng theo đơn hàng.';
								|ru = 'Ручная скидка (наценка) не может быть назначена на строки по заказу.';
								|en = 'Discount/markup adjustment cannot be assigned for the order lines.'; fa = 'Discount/markup adjustment cannot be assigned for the order lines.';
								|it = 'Sconto (maggiorazione) manuale non può essere impostato/a per le righe dell''ordine.';
								|pl = 'Rabat ręczny (marże) nie może być wyznaczona w wierszach wg zamówienia.';
								|tr = 'İndirim (zam) düzeltmesi, sipariş satırlarına girilemez.'");
		EndIf;
		
		ShowMessageBox(,WarningText);
		Return False;
	Else
		Return ItIsPossibleToAssignManualDiscountMarkUp
	EndIf;
	
EndFunction

&AtClient
Function ItIsPossibleToCancelManualDiscountsMarkups()
	
	ItIsPossibleToCancelManualDiscountsMarkups = DiscountsMarkupsFillingClient.ItIsPossibleToCancelManualDiscountsMarkups(Object, "Goods", NStr("vi = 'Hàng hóa';
																																				|ru = 'Товары';
																																				|en = 'Goods'; fa = 'کالاها';
																																				|it = 'Merci';
																																				|pl = 'Wiersze pozycji';
																																				|tr = 'Ürünler'"));
	
	If ItIsPossibleToCancelManualDiscountsMarkups And SalesInExcessOfOrder And Object.OrderSales And Object.Goods.Total("OrderDiscrepancy_3") = 0 Then
		
		If Object.BusinessOperation =
			PredefinedValue("Enum.BusinessTransactions.TransferOfTitleToGoods") Then
			WarningText = NStr("vi = 'Không thể hủy bỏ chiết khấu (phụ thu) thủ công tại các dòng theo lệnh.';
								|ru = 'Ручная скидка (наценка) не может быть отменена в строках по распоряжению.';
								|en = 'Discount/markup adjustment cannot be canceled in the reference lines.'; fa = 'Discount/markup adjustment cannot be canceled in the reference lines.';
								|it = 'Discount/markup adjustment cannot be canceled in the reference lines.';
								|pl = 'Discount/markup adjustment cannot be canceled in the reference lines.';
								|tr = 'İndirim (zam) düzeltmesi, sipariş satırlarından iptal edilemez.'");
		Else
			WarningText = NStr("vi = 'Không thể hủy bỏ chiết khấu (phụ thu) thủ công tại các dòng theo đơn hàng.';
								|ru = 'Ручная скидка (наценка) не может быть отменена в строках по заказу.';
								|en = 'Discount/markup adjustment cannot be canceled in the order lines.'; fa = 'Discount/markup adjustment cannot be canceled in the order lines.';
								|it = 'Sconto (maggiorazione) manuale non può essere annullato/a nelle righe per ordine.';
								|pl = 'Rabat ręczny (marże) nie może być owdołany w wierszach wg zamówienia.';
								|tr = 'İndirim (zam) düzeltmesi, sipariş satırlarından iptal edilemez.'");
		EndIf;
		
		ShowMessageBox(,WarningText);
		Return False;
	Else
		Return ItIsPossibleToCancelManualDiscountsMarkups
	EndIf;
	
EndFunction

&AtServer
Procedure UnlinkFromOrderServer(AllRows = True, UntieOnlyStrings = True)
	
	Var CachedValues;
	
	If AllRows Then
		RowsCollection = Object.Goods;
	Else
		RowsCollection = Items.Goods.SelectedRows;
	EndIf;
	
	For Each CurRow In RowsCollection Do
		
		If AllRows Then
			TableRow = CurRow;
			CurRow = TableRow.GetID();
		Else
			TableRow = Object.Goods.FindByID(CurRow);
		EndIf;
		ProductsClientServer.UpdateCachedValuesToAccountForSeries(TableRow,CachedValues,SeriesSpecificationParameters);
		
		TableRow.RowCode = 0;
		TableRow.Purpose = Undefined;
		TableRow.WithAssignment = False;

		If UntieOnlyStrings Then
			TableRow.OrderDiscrepancy_3 = 1;
		Else
			TableRow.SalesOrder = Undefined;
		EndIf;
		
		// Reassign the series lines
		ProductsServer.FillInStatusesOfSpecifyingSeriesWhenEditingLineTS(Object,SeriesSpecificationParameters,CurRow,CachedValues);
		
	EndDo;
	
	FillInDataForCalculatingPaymentWithBonusPoints();
	ApplyPaymentWithBonusPoints();

	UpdateDependentDetailsOfServerByOrderForm();
	
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
	AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions, Object);
	OrdersClientServer.AddActionFillInDiscrepancyOrderAttribute(StructureOfActions, Object.OrderSales);
	
	ParametersForFillingInVATAmountLocalManSManSManSManSManSManSManSManS = BatchProcessingOfTablePartClientServer.ParametersForFillingInVATAmountLocalManSManSManSManSManSManSManSManS(
		Object.Currency,
		LocalAccountingCurrency,
		ManagementAccountingCurrency);
	
	StructureOfActions.Insert("SetVATAmountLocalMans", ParametersForFillingInVATAmountLocalManSManSManSManSManSManSManSManS);
	
	LinesOfBusinessClientServer.StructureOfInsertActionsWhenAddingRow(ThisObject, StructureOfActions);
	BatchProcessingOfTablePartClientServerLocalization.CompleteActionStructureWhenChangingElement(ThisObject, "Products", StructureOfActions);

	ItemsFromStorage = GetFromTempStorage(GoodsAddressInStorage);
	RowsToProcess = New Array;
	
	For Each RowOfGoods In ItemsFromStorage Do
		StringTSGoods = Object.Goods.Add();
		FillPropertyValues(StringTSGoods, RowOfGoods, , "RowCode");
		RowsToProcess.Add(StringTSGoods);
	EndDo;
	
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		RowsToProcess,
		StructureOfActions,
		Object.Goods);
	
	CalculateTotals_(ThisObject);
	WhenChangingWarehouseInTablePartServer();
	ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);
	UpdateVHFWarehouseObligation();
	ReusablePackageServer.UpdateFillingStateOfMultiTurnContainer(Object.ReusablePackageFillingStatus);
	
	FormEvents.WhenChangingElement(ThisObject, "Goods");
	
EndProcedure

&AtServer
Procedure FillBaseForPrinting()
	
	If Not BasisChanged Then
		BaseStructure = Documents.CustomerInvoice.StructureOfBaseForPrinting(Object);
		FillPropertyValues(Object, BaseStructure);
	EndIf;
	PrintBasisTable.Load(Documents.CustomerInvoice.PrintBasisTable(Object));
	
EndProcedure

&AtServer
Procedure ChangeHeadingsForSalesLayoutOption()
	
	If Object.SaleRegistrationOption = Enums.SalesRegistrationOptions.DeedOfTransfer Then
		AutoTitle = False;
		If ValueIsFilled(Object.Ref) Then
			Template = NStr("vi = '%1 %2 ngày %3';
							|ru = '%1 %2 от %3';
							|en = '%1 %2 dated %3'; fa = '%1 %2 dated %3';
							|it = '%1 %2 del %3';
							|pl = '%1 %2 z dnia %3';
							|tr = '%3 tarihli %1 %2'");
		Else
			Template = NStr("vi = '%1 (tạo mới)';
							|ru = '%1 (создание)';
							|en = '%1 (Create)'; fa = '%1 (Create)';
							|it = '%1 (creazione)';
							|pl = '%1 (utworzenie)';
							|tr = '%1 (oluştur)'");
		EndIf;
		TextHeader = NStr("vi = 'Biên bản chuyển giao quyền sở hữu';
							|ru = 'Акт на передачу прав';
							|en = 'Deed of transfer'; fa = 'صورتجلسه تحویل';
							|it = 'Atto di trasferimento dei diritti';
							|pl = 'Protokół przekazania praw';
							|tr = 'Yetki devir senedi'");
		Title = StringFunctionsClientServer.SubstituteParametersToString(Template, TextHeader, Object.Number, Object.Date);
	Else
		AutoTitle = True;
		Title = "";
	EndIf;
	
EndProcedure

&AtServer
Procedure SetHeadingsForBusinessOfOperation()
	
	If Object.BusinessOperation = Enums.BusinessTransactions.TransferOfTitleToGoods Then
		
		Items.CustomImplementation.Title = NStr("vi = 'Giao hàng theo lệnh';
												|ru = 'Реализация по распоряжению';
												|en = 'Sale by reference'; fa = 'Sale by reference';
												|it = 'Sale by reference';
												|pl = 'Sale by reference';
												|tr = 'Siparişe göre gerçekleştirme'");
		Items.CustomImplementation.ToolTip = NStr("vi = 'Lệnh là cơ sở để lập chứng từ giao hàng';
													|ru = 'Распоряжение, по которому оформляется реализация';
													|en = 'Reference by which the sale is registered'; fa = 'Reference by which the sale is registered';
													|it = 'Reference by which the sale is registered';
													|pl = 'Reference by which the sale is registered';
													|tr = 'Satışın düzenlendiği sipariş'");
		Items.OrderSales.Title = NStr("vi = 'Giao hàng theo lệnh';
										|ru = 'Реализация по распоряжениям';
										|en = 'Sale by references'; fa = 'فروش بر اساس مراجع';
										|it = 'Sale by references';
										|pl = 'Sale by references';
										|tr = 'Siparişlere göre gerçekleştirme'");
		Items.OrderSales.ToolTip = NStr("vi = 'Lệnh là cơ sở để lập chứng từ giao hàng';
										|ru = 'Распоряжения, по которым оформляется реализация';
										|en = 'References by which the sale is registered'; fa = 'References by which the sale is registered';
										|it = 'References by which the sale is registered';
										|pl = 'References by which the sale is registered';
										|tr = 'Satışın düzenlendiği siparişler'");
		
		Items.SalesOrder.ToolTip = NStr("vi = 'Lệnh là cơ sở để lập chứng từ giao hàng';
										|ru = 'Распоряжение, по которому оформляется реализация';
										|en = 'Reference by which the sale is registered'; fa = 'Reference by which the sale is registered';
										|it = 'Reference by which the sale is registered';
										|pl = 'Reference by which the sale is registered';
										|tr = 'Satışın düzenlendiği siparişler'");
		
		If OrderList.Count() > 1 Then 
			
			HeaderOrdersText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Tổng số lệnh: %1';
					|ru = 'Всего распоряжений: %1';
					|en = 'Total references: %1'; fa = 'Total references: %1';
					|it = 'Total references: %1';
					|pl = 'Total references: %1';
					|tr = 'Tüm siparişler: %1'"),
				OrderList.Count());
				
			Items.LabelHeaderSalesOrders.Width = 20;
			
		EndIf;
		
		Items.PictureDiscrepancyOrder.ToolTip = NStr("vi = 'Số lượng dòng không gắn với lệnh';
													|ru = 'Количество строк, не привязанных к распоряжению';
													|en = 'Number of lines not linked to the reference'; fa = 'تعداد سطرهای غیرمرتبط با مرجع';
													|it = 'Number of lines not linked to the reference';
													|pl = 'Number of lines not linked to the reference';
													|tr = 'Bir siparişe bağlı olmayan satır sayısı'");
		Items.PictureDiscrepancyOrders.ToolTip = NStr("vi = 'Số lượng dòng không gắn với lệnh';
														|ru = 'Количество строк, не привязанных к распоряжениям';
														|en = 'Number of lines not linked to references'; fa = 'Number of lines not linked to references';
														|it = 'Number of lines not linked to references';
														|pl = 'Number of lines not linked to references';
														|tr = 'Siparişlerin bağlandığı satırların sayısı'");
		
		Items.GoodsSalesOrder.Title = NStr("vi = 'Lệnh';
											|ru = 'Распоряжение';
											|en = 'Reference'; fa = 'مرجع';
											|it = 'Reference';
											|pl = 'Reference';
											|tr = 'Sipariş'");
		Items.GoodsSalesOrder.ToolTip = NStr("vi = 'Lệnh là cơ sở để tạo dòng giao hàng';
											|ru = 'Распоряжение, по которому оформляется строка реализации';
											|en = 'Reference using which the sales line is created'; fa = 'مرجعی که سطر فروش با استفاده از آن ایجاد می‌شود';
											|it = 'Reference using which the sales line is created';
											|pl = 'Reference using which the sales line is created';
											|tr = 'Gerçekleştirme işleminin düzenlendiği emir'");
		
	Else
		
		Items.CustomImplementation.Title = NStr("vi = 'Giao hàng theo đơn hàng';
												|ru = 'Реализация по заказу';
												|en = 'Order sales'; fa = 'فروش سفارش';
												|it = 'Vendite per ordine';
												|pl = 'Sprzedaż według zamówienia';
												|tr = 'Siparişlere göre satış'");
		Items.CustomImplementation.ToolTip = NStr("vi = 'Đơn hàng, theo đó lập chứng từ giao hàng';
													|ru = 'Заказ, по которому оформляется реализация';
													|en = 'The order by which the sale is registered'; fa = 'سفارشی که فروش بر اساس آن ثبت می‌شود';
													|it = 'L''ordine sulla base del quale si effettua la vendita';
													|pl = 'Umowa, na podstawie której realizacja jest dokonywana';
													|tr = 'Satışın düzenlenmesinde esas alınan sipariş'");
		Items.OrderSales.Title = NStr("vi = 'Giao hàng theo đơn hàng';
										|ru = 'Реализация по заказам';
										|en = 'Order sales'; fa = 'فروش سفارش';
										|it = 'Vendite per ordini';
										|pl = 'Sprzedaż wg zamówień';
										|tr = 'Siparişlere ilişkin satışlar'");
		Items.OrderSales.ToolTip = NStr("vi = 'Lệnh là cơ sở để lập chứng từ giao hàng';
										|ru = 'Заказы, по которым оформляется реализация';
										|en = 'Orders for which the sale is registered'; fa = 'Orders for which the sale is registered';
										|it = 'Orders for which the sale is registered';
										|pl = 'Orders for which the sale is registered';
										|tr = 'Satış için oluşturulan siparişler'");
		
		Items.SalesOrder.ToolTip = NStr("vi = 'Đơn hàng của khách là cơ sở để lập chứng từ giao hàng';
										|ru = 'Заказ клиента, по которому оформляется реализация';
										|en = 'Sales order for which the sale is registered'; fa = 'Sales order for which the sale is registered';
										|it = 'Sales order for which the sale is registered';
										|pl = 'Sales order for which the sale is registered';
										|tr = 'Satış için oluşturulan müşteri siparişi'");
		
		If OrderList.Count() > 1 Then 
			
			HeaderOrdersText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Tổng số đơn hàng: %1';
					|ru = 'Всего заказов: %1';
					|en = 'Total orders: %1'; fa = 'Total orders: %1';
					|it = 'Totale ordini: %1';
					|pl = 'Łącznie zamówień: %1';
					|tr = 'Toplam siparişler: %1'"),
				OrderList.Count());
				
			Items.LabelHeaderSalesOrders.Width = 15;
			
		EndIf;
		
		Items.PictureDiscrepancyOrder.ToolTip = NStr("vi = 'Số lượng dòng không liên quan đến đơn hàng';
													|ru = 'Количество строк, не привязанных к заказу';
													|en = 'Number of lines not related to the order'; fa = 'تعداد سطرهای غیرمرتبط با سفارش';
													|it = 'Numero di righe non associate all''ordine';
													|pl = 'Ilość wierszy niezwiązanych z zamówieniem';
													|tr = 'Bir siparişe bağlı olmayan satır miktarı'");
		Items.PictureDiscrepancyOrders.ToolTip = NStr("vi = 'Số lượng dòng không liên quan đến đơn hàng';
														|ru = 'Количество строк, не привязанных к заказам';
														|en = 'Number of lines not linked to orders'; fa = 'Number of lines not linked to orders';
														|it = 'Number of lines not linked to orders';
														|pl = 'Number of lines not linked to orders';
														|tr = 'Siparişlere bağlanmayan satır sayısı'");
		
		Items.GoodsSalesOrder.Title = NStr("vi = 'Đơn hàng của khách';
											|ru = 'Заказ клиента';
											|en = 'Sales order'; fa = 'سفارش فروش';
											|it = 'Ordine del cliente';
											|pl = 'Zamówienie klienta';
											|tr = 'Satış siparişi'");
		Items.GoodsSalesOrder.ToolTip = NStr("vi = 'Đơn hàng của khách theo đó có tạo ra dòng giao hàng';
											|ru = 'Заказ клиента, по которому оформляется строка реализации';
											|en = 'Sales order for which sale line is recorded'; fa = 'سفارش فروشی که سطر فروش برای آن ثبت می‌شود';
											|it = 'L''ordine di vendita per il quale viene emessa la riga di vendita';
											|pl = 'Zlecenie klienta, którego dotyczy wiersz realizacji';
											|tr = 'Satış satırının oluşturulmasında esas alınan müşteri siparişi'");
		
	EndIf;
	
	SetTitleFillInByOrdersOrders();
	
EndProcedure

&AtServer
Procedure UpdateTextOfInvoiceIssued()
	
	RegistrationParameters = Documents.CustomerInvoice.ParametersForRegisteringInvoicesIssued(Object);
	InvoicesIssuedOnBasisOf = VATAccountingERP.InvoicesIssuedOnBasisOf(RegistrationParameters);
		
	TextOfTheInvoiceIssued =
		SalesServer.CreatePresentationOfInvoiceGenerationCommandsBasedOn(
			Object.Ref, InvoicesIssuedOnBasisOf);
		
	GeneratingFiscalChecksServer.UpdateFiscalCheckBreakdownHyperlink(Object.Ref,
		ThisObject, TextOfTheInvoiceIssued);
	
	TextsFieldsDocumentsBasedOn.Add(TextOfTheInvoiceIssued);
	
EndProcedure

&AtServer
Procedure SetTitleOfPrintDetails()
	
	If GetFunctionalOption("UseDeedsOfTransfer") 
		And Not SalesViaCommissionAgent Then
		Items.PrintDetails.Title = 
			NStr("vi = 'Chi tiết in / chứng nhận chuyển nhượng quyền';
				|ru = 'Реквизиты печати / Акта на передачу прав';
				|en = 'Print details / Deed of transfer'; fa = 'Print details / Deed of transfer';
				|it = 'Requisiti di stampa / Atto sul trasferimento di diritti';
				|pl = 'Atrybuty wydruku / Protokołu przeniesienia praw';
				|tr = 'Yazdırma öznitelikleri / Transfer hakkı raporu'");
	EndIf;
	
EndProcedure

&AtServer
Procedure SetTitleFillInByOrdersOrders()
	
	If Object.BusinessOperation = Enums.BusinessTransactions.TransferOfTitleToGoods
		And Not UseSaleByMultipleOrders Then
		TitleFillIn = NStr("vi = 'Chọn hàng hóa từ lệnh';
							|ru = 'Подобрать товары из распоряжения';
							|en = 'Pick goods from reference'; fa = 'Pick goods from reference';
							|it = 'Pick goods from reference';
							|pl = 'Pick goods from reference';
							|tr = 'Siparişten ürünler seç'");
	ElsIf Object.BusinessOperation = Enums.BusinessTransactions.TransferOfTitleToGoods
		And UseSaleByMultipleOrders Then
		TitleFillIn = NStr("vi = 'Nhận hàng theo lệnh';
							|ru = 'Подобрать товары по распоряжениям';
							|en = 'Pick goods by references'; fa = 'Pick goods by references';
							|it = 'Selezionare le merci in base alle disposizioni';
							|pl = 'Wybierz wiersze pozycji wg zamówień';
							|tr = 'Talimatlara göre ürünleri seç'");
	ElsIf Not AdvancedWarehousingOnShipment And Not UseSaleByMultipleOrders And UseSalesOrders Then
		TitleFillIn = NStr("vi = 'Chọn hàng hóa từ đơn hàng';
							|ru = 'Подобрать товары из заказа';
							|en = 'Pick goods from order'; fa = 'انتخاب کالاها از سفارش';
							|it = 'Selezionare le merci dall''ordine';
							|pl = 'Dobierz wiersze pozycji i zamówienia';
							|tr = 'Siparişten mal seçme'");
	ElsIf Not AdvancedWarehousingOnShipment And UseSaleByMultipleOrders And UseSalesOrders Then
		TitleFillIn = NStr("vi = 'Chọn hàng hóa từ đơn hàng';
							|ru = 'Подобрать товары из заказов';
							|en = 'Pick goods from orders'; fa = 'Pick goods from orders';
							|it = 'Selezionare le merci dagli ordini';
							|pl = 'Dobierz wiersze pozycji z zamówienia';
							|tr = 'Siparişlerden mal seçme'");
	ElsIf AdvancedWarehousingOnShipment And Not UseSalesOrders Then
		TitleFillIn = NStr("vi = 'Chọn hàng hóa theo lệnh';
							|ru = 'Подобрать товары по ордерам';
							|en = 'Pick goods by notes'; fa = 'انتخاب کالا بر اساس حواله‌ها';
							|it = 'Selezionare le merci in base ai mandati';
							|pl = 'Wybierz wiersze pozycji wg zleceń';
							|tr = 'Emirlere göre mal seçme'");
	Else
		TitleFillIn = NStr("vi = 'Nhận hàng theo đơn đặt hàng / đơn hàng';
							|ru = 'Подобрать товары по заказам/ордерам';
							|en = 'Pick by Order/Goods issue'; fa = 'انتخاب بر اساس سفارش/صدور کالا';
							|it = 'Seleziona le merci in base agli ordini/mandati';
							|pl = 'Wybierz wiersze pozycji wg zamówień/zleceń';
							|tr = 'Siparişe/emre ilişkin ürünlerin seçimi'");
	EndIf;
	Items.GoodsSelectGoodsByOrdersNotes.Title = TitleFillIn;
	
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
	|	AND Warehouses.SelectGroup = VALUE(Enum.SelectWarehouseGroup.AllowInOrdersAndInvoices)");

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
Procedure SetHeadingProductsSenderGroup()
	
	Items.ProductsGroupSender.Visible = 
		(UseWarehousesInTabularSectionsOfSalesDocuments Or UseBusinessUnits);
		
	Items.ProductsGroupSender.Title = ?(WarehouseGroup_,
													NStr("vi = 'Nơi gửi';
														|ru = 'Отправитель';
														|en = 'Sender'; fa = 'فرستنده';
														|it = 'Mittente';
														|pl = 'Sender';
														|tr = 'Gönderen'"),
													NStr("vi = 'Bộ phận gửi';
														|ru = 'Подразделение-отправитель';
														|en = 'Shipping business unit'; fa = 'واحد تجاری ارسال‌کننده';
														|it = 'Unità-mittente';
														|pl = 'Shipping business unit';
														|tr = 'Gönderen departman'"));
	
EndProcedure

&AtServer
Procedure FillInSalesVATTaxation()
	
	If Object.OrderSales
		And Object.BusinessOperation = Enums.BusinessTransactions.TransferOfTitleToGoods Then
		Return;
	EndIf;
	
	FillParameters = Documents.CustomerInvoice.ParametersForFillingInSalesVATTaxation(Object);
	VATAccountingERP.FillInSalesVATTaxation(Object.VATTaxation, FillParameters, VATAccountingCachedParameterValues);
	VATAccountingERP.FillInSalesVATTaxSelectionList(Items.VATTaxation, Object.VATTaxation, FillParameters, VATAccountingCachedParameterValues); 
	
EndProcedure

&AtServer
Procedure PaymentCreditedServer(EventName, Parameter, Source)
	
	ARAPAccountingFormWork.NotificationProcessing(ThisForm, EventName, Parameter);
	
EndProcedure

&AtServer
Procedure Recording_AdjustingImplementationOnServer()
	UpdateTextOfInvoiceIssued();
	UpdateFlagThereAreAdjustments();
	ARAPAccountingFormWork.WhenChangingParametersOfMechanism(ThisForm);
EndProcedure

&AtServer
Procedure UpdateFlagThereAreAdjustments();
	CheckForAdjustments(Object.Ref, ThereAreAdjustingEntries);
EndProcedure

&AtClient
Procedure SetWhetherWarehouseIsFull()
	
	WarehouseIsRequired = ?(Object.Goods.Total("WarehouseIsRequired") = 0, 0, 1);
	
EndProcedure

&AtServer
Procedure UpdateVHFWarehouseObligation()
	
	ParametersONChangingTypeOfItem = New Structure;
	ParametersONChangingTypeOfItem.Insert("ThereAreWorks", True);
	ParametersONChangingTypeOfItem.Insert("IsCanceled", False);
	ParametersONChangingTypeOfItem.Insert("ThisIsTransferOfOwnership",
		Object.BusinessOperation =
			PredefinedValue("Enum.BusinessTransactions.TransferOfTitleToGoods"));
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("WhenChangingProductType", ParametersONChangingTypeOfItem);
	BatchProcessingOfTablePartServer.TreatTS(Object.Goods, StructureOfActions, Undefined);
	
	WarehouseIsRequired = ?(Object.Goods.Total("WarehouseIsRequired") = 0, 0, 1);
	
EndProcedure

&AtClient
Procedure FillInTheDepartment(Command)
	
	WarehousesClient.FillInDivisionInTablePart(Object, ThisForm, Object.Goods, "Goods", 
			Items.Goods.SelectedRows);
	
EndProcedure

&AtClient
Procedure FillInVATRateCompletion(VATRate, AdditionalParameters) Export

	If VATRate = Undefined Then
		Return;
	EndIf;

	FillInVATRateOnServer(VATRate, CachedValues);
	DiscountsMarkupsFillingClient.ResetDiscountsCalculatedFlag(ThisObject);

EndProcedure

&AtServer
Procedure FillInVATRateOnServer(VATRate, CachedValues)

	ParametersForFillingInVATAmountLocalManSManSManSManSManSManSManSManS = BatchProcessingOfTablePartClientServer.ParametersForFillingInVATAmountLocalManSManSManSManSManSManSManSManS(
		Object.Currency,
		LocalAccountingCurrency,
		ManagementAccountingCurrency);
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("ClearAmountOfSettlements");
	StructureOfActions.Insert("SetVATAmountLocalMans", ParametersForFillingInVATAmountLocalManSManSManSManSManSManSManSManS);
	StructureOfActions.Insert("FillInDuplicateDependentDetails", DependentDetails());

	SelectedRows = ProcessingOfTabularFormsClientServer.CollectionItems(
		Object.Goods, Items.Goods.SelectedRows);

	RowsToDelete = New Array;
	For Each LineOfATabularSection In SelectedRows Do
		If (SalesInExcessOfOrder
			And LineOfATabularSection.RowCode <> 0
			And Not VarianceFromSalesTermsAndConditions)
			Or (Not SalesInExcessOfOrder And Not VarianceFromSalesTermsAndConditions)
			Or (LineOfATabularSection.ItemsType = Enums.ItemsTypes.ReusablePackage And Object.ToReturnReusablePackage) Then
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

	CalculateTotals_(ThisObject);

EndProcedure

&AtClient
Procedure EnableWaitingHandlerReceivingCarriers()
	
	If Not GoodsDeliveryClientServer.UsedDelivery20() Then
		Return;
	EndIf;
	
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
Procedure SetVisibilityOfElementsOfLoyaltyBonusProgram()
	
	Items.GroupProductsBonusPoints.Visible = UseLoyaltyPrograms;
	Items.GoodsAmountOfBonusPointsToDeductionInCurrency.Visible = UseLoyaltyPrograms;
	Items.GoodsAmountOfEarnedBonusPointsInCurrency.Visible = UseLoyaltyPrograms;
	
EndProcedure

&AtServer
Function AddressOfTheTablePartProducts()
	
	If UseAdvancedFeaturesOfSalesOrder Then
		RowsArray = New Array();
		For Each String In Object.Goods Do
			If Not String.RowCode = 0 Then
				Continue;
			EndIf;
			
			RowsArray.Add(String);
		EndDo;
		GoodsToBeUnloaded = Object.Goods.Unload(RowsArray);
	Else
		GoodsToBeUnloaded = Object.Goods.Unload();
	EndIf;
	
	Return PutToTempStorage(GoodsToBeUnloaded, UUID);
	
EndFunction

&AtServer
Procedure SetVisibilityOfCommandToFillInContractPriceView()
	
	Items.GoodsFillInPricesUnderAgreement.Visible = SalesViaCommissionAgent;
	Items.GoodsFillThePricesByTermsOfSales.Visible = Not SalesViaCommissionAgent And ToUseTermsOfSales;
	
EndProcedure

&AtServerNoContext
Function TypeOfContractPrice(Contract)

	ParametersStructure = EnterprisePricesFillingServer.NewParametersForCheckingTypeOfContractPrices();
	ParametersStructure.FieldPriceType = "SalesPriceType";

	If Not ValueIsFilled(Contract) Then
		Return ParametersStructure;
	EndIf;

	DetailsOfPriceType = New Structure();
	DetailsOfPriceType.Insert(ParametersStructure.FieldPriceType);
	DetailsOfPriceType.Insert("PriceIncludesVAT", ParametersStructure.FieldPriceType + ".PriceIncludesVAT");
	AttributesValues = Common.ObjectAttributesValues(Contract, DetailsOfPriceType);
	ParametersStructure.PriceKind = AttributesValues[ParametersStructure.FieldPriceType];
	If ValueIsFilled(ParametersStructure.PriceKind) Then
		ParametersStructure.PriceIncludesVAT = AttributesValues.PriceIncludesVAT;
	EndIf;
	
	Return ParametersStructure;

EndFunction

&AtServer
Procedure EstablishRelationshipsBetweenContractSelectionParameters()
	
	RelationshipsOfContractParameters = New Array;
	
	RelationshipsOfContractParameters.Add(New ChoiceParameterLink("Filter.Counterparty",				"Object.Counterparty"));
	RelationshipsOfContractParameters.Add(New ChoiceParameterLink("Filter.Organization",			"Object.Organization"));
	RelationshipsOfContractParameters.Add(New ChoiceParameterLink("Filter.ConsignmentSales25",	"SalesViaCommissionAgent"));
	RelationshipsOfContractParameters.Add(New ChoiceParameterLink("Filter.BusinessOperation",	"ContractBusinessTransaction"));
	RelationshipsOfContractParameters.Add(New ChoiceParameterLink("Partner",						"Object.Partner"));
	RelationshipsOfContractParameters.Add(New ChoiceParameterLink("Terms",					"Object.Terms",
			LinkedValueChangeMode.DontChange));
	
	If Not SalesViaCommissionAgent Then
		RelationshipsOfContractParameters.Add(New ChoiceParameterLink("Filter.ARAPCurrency", "Object.ARAPCurrency"));
	EndIf;
	
	Items.Contract.ChoiceParameterLinks = New FixedArray(RelationshipsOfContractParameters);
	
	
	ParameterLinks = New Array;
	
	ParameterLinks.Add(New ChoiceParameterLink("Filter.ContractWithCommissionAgent",	"Object.Contract"));
	ParameterLinks.Add(New ChoiceParameterLink("Filter.Counterparty",				"Object.CustomerCounterparty"));
	ParameterLinks.Add(New ChoiceParameterLink("Filter.Partner",				"Object.CustomerPartner"));
	ParameterLinks.Add(New ChoiceParameterLink("Filter.CounterpartyCommissionAgent",	"Object.Counterparty"));
	ParameterLinks.Add(New ChoiceParameterLink("Filter.CommissionAgentPartner",		"Object.Partner"));
	ParameterLinks.Add(New ChoiceParameterLink("Filter.Organization",			"Object.Organization",
			LinkedValueChangeMode.DontChange));
	
	If Not SalesViaCommissionAgent Then
		ParameterLinks.Add(New ChoiceParameterLink("Filter.ARAPCurrency", "Object.ARAPCurrency"));
	EndIf;
	
	Items.CustomerContract.ChoiceParameterLinks = New FixedArray(ParameterLinks);
	
	
EndProcedure

&AtServer
Procedure EstablishLinksBetweenParametersForSelectingTypeOfPrice()
	
	RelationshipsOfPriceTypeParameters = New Array;
	
	RelationshipsOfPriceTypeParameters.Add(New ChoiceParameterLink("ToUseTermsOfSales", "ToUseTermsOfSales"));
	RelationshipsOfPriceTypeParameters.Add(New ChoiceParameterLink("UsePriceManagementSystem25", "UsePriceManagementSystem25"));
	RelationshipsOfPriceTypeParameters.Add(New ChoiceParameterLink("Filter.PriceIncludesVAT", "Object.PriceIncludesVAT"));
	
	RelationshipsOfPriceTypeParameters.Add(
		New ChoiceParameterLink(
			"Partner",
			"Object.Partner",
			LinkedValueChangeMode.DontChange));
	
	If Not SalesViaCommissionAgent Then
		
		RelationshipsOfPriceTypeParameters.Add(
			New ChoiceParameterLink(
				"Terms",
				"Object.Terms",
				LinkedValueChangeMode.DontChange));
		
	EndIf;
	
	Items.GoodsPriceKind.ChoiceParameterLinks = New FixedArray(RelationshipsOfPriceTypeParameters);
	
EndProcedure

&AtServer
Procedure FillInPriceTypeUnderAgreement()
	
	PriceTypeUnderContract = ?(SalesViaCommissionAgent And ValueIsFilled(Object.Contract),
		TypeOfContractPrice(Object.Contract).PriceKind,
		Undefined);
	
EndProcedure

&AtServer
Procedure SetPropertiesOfOutdatedCommissionUsageComment()
	
	Items.CommentUsingOutdatedCommission.Title = ConsignmentSalesServer.CommentUsingOutdatedCommission();
	Items.GroupCommentUsingOutdatedCommission.Visible = 
		Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.TransferToCommissionAgent");
	
EndProcedure
	
#EndRegion

#Region ControlOfInconsistentChanges

// Parameters:
//	Item - FormGroup, FormTable, FormField, FormButton - FormItem
&AtClient
Procedure ControlOfNonConsistentChangesHandleEventOnChange(Item)
	If Item.Name = "Partner" Then
		PartnerOnChange(Item);
	ElsIf Item.Name = "Date" Then
		DateOnChange(Item);
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
	ElsIf Item.Name = "OrderSales" Then
		OrderSalesOnChange(Item);
	ElsIf Item.Name = "CustomImplementation" Then
		OrderSalesOnChange(Item);
	ElsIf Item.Name = "ToReturnReusablePackage" Then
		ToReturnReusablePackageOnChange(Item);
	ElsIf Item.Name = "PackageDepositIsRequired" Then
		PackageDepositIsRequiredOnChange(Item);
	ElsIf Item.Name = "GoodsProducts" Then
		GoodsProductsOnChange(Item);
	ElsIf Item.Name = "GoodsCharacteristic" Then
		GoodsCharacteristicOnChange(Item);
	ElsIf Item.Name = "GoodsWithAssignment" Then
		GoodsWithAssignmentOnChange(Item);
	ElsIf Item.Name = "GoodsSeries" Then
		GoodsSeriesOnChange(Item);
	ElsIf Item.Name = "GoodsNumberOfPackages" Then
		GoodsNumberOfPackagesOnChange(Item);
	ElsIf Item.Name = "GoodsPackage" Then
		GoodsPackageOnChange(Item);
	ElsIf Item.Name = "GoodsPriceKind" Then
		GoodsPriceKindOnChange(Item);
	ElsIf Item.Name = "GoodsPrice" Then
		GoodsPriceOnChange(Item);
	ElsIf Item.Name = "GoodsPercentRateOfManualDiscount" Then
		GoodsPercentRateOfManualDiscountOnChange(Item);
	ElsIf Item.Name = "GoodsManualDiscount" Then
		GoodsManualDiscountOnChange(Item);
	ElsIf Item.Name = "GoodsSum" Then
		GoodsSumOnChange(Item);
	ElsIf Item.Name = "GoodsVATAmount" Then
		GoodsVATAmountOnChange(Item);
	ElsIf Item.Name = "GoodsVATRate" Then
		GoodsVATRateOnChange(Item);
	ElsIf Item.Name = "GoodsWarehouse" Then
		GoodsWarehouseOnChange(Item);
	ElsIf Item.Name = "Warehouse" Then
		WarehouseOnChange(Item);
	ElsIf Item.Name = "BusinessOperation" Then
		BusinessOperationOnChange(Item);
	ElsIf Item.Name = "Status" Then
		StatusOnChange(Item);
	ElsIf Item.Name = "GoodsPartnerProducts" Then
		GoodsPartnerProductsOnChange(Item);
	ElsIf Item.Name = "Department" Then
		DepartmentOnChange(Item);
	ElsIf Item.Name = "SaleRegistrationOption" Then
		SaleRegistrationOptionOnChange(Item);
	ElsIf Item.Name = "CustomerContract" Then
		CustomerContractOnChange(Item);
	ElsIf Item.Name = "CustomerCounterparty" Then
		CustomerCounterpartyOnChange(Item);
	ElsIf Item.Name = "CustomerPartner" Then
		CustomerPartnerOnChange(Item);
	Else
		TMCommonUseClient.MonitoringNonConsistentChangesCauseException(ThisForm, Item);
	EndIf;
EndProcedure

// Parameters:
//	Command - FormCommand - 
&AtClient
Procedure ControlOfNonConsistentChangesHandleCommandEvent(Command)
	If Command.Name = "SearchByBarcode" Then
		SearchByBarcodeExecute(Command);
	ElsIf Command.Name = "ImportDataFromPDT" Then
		ImportDataFromPDT(Command);
	ElsIf Command.Name = "SplitRow" Then
		SplitRow(Command);
	ElsIf Command.Name = "OpenSelection" Then
		OpenSelection(Command);
	ElsIf Command.Name = "AddReusablePackage" Then
		AddReusablePackage(Command);
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
	ElsIf Command.Name = "SelectGoodsByOrdersNotes" Then
		SelectGoodsByOrdersNotes(Command);
	ElsIf Command.Name = "CalculateDiscountsMarkups" Then
		CalculateDiscountsMarkups(Command);
	ElsIf Command.Name = "ImportFromExternalFile" Then
		ImportFromExternalFile(Command);
	ElsIf Command.Name = "ToReadLoyaltyCard" Then
		ToReadLoyaltyCard(Command);
	ElsIf Command.Name = "GetWeight" Then
		GetWeight(Command);
	ElsIf Command.Name = "CheckQuantityInTheDocument" Then
		CheckQuantityInTheDocument(Command);
	ElsIf Command.Name = "FillInTheWarehouseInSelectedLines" Then
		FillInTheWarehouseInSelectedLines(Command);
	ElsIf Command.Name = "UnlinkFromOrder" Then
		UnlinkFromOrder(Command);
	ElsIf Command.Name = "InsertRows" Then
		InsertRows(Command);
	ElsIf Command.Name = "SetComposition" Then
		SetComposition(Command);
	ElsIf Command.Name = "SetTheMarkApart" Then
		SetTheMarkApart(Command);
	ElsIf Command.Name = "UncheckTheSeparateBox" Then
		UncheckTheSeparateBox(Command);
	ElsIf Command.Name = Commands.SelectTransferredGoods.Name Then
		SelectTransferredGoods(Command);
	ElsIf Command.Name = Commands.FillInTheDepartment.Name Then
		FillInTheDepartment(Command);
	ElsIf Command.Name = Commands.FillInVATRate.Name Then
		FillInVATRate(Command);
	ElsIf Command.Name = Commands.FillInPricesUnderAgreement.Name Then
		FillInPricesUnderAgreement(Command);
	ElsIf Command.Name = Commands.AddPaymentWithBonusPoints.Name Then
		AddPaymentWithBonusPoints(Command);
	ElsIf Command.Name = Commands.CancelPaymentWithBonusPoints.Name Then
		CancelPaymentWithBonusPoints(Command);
	Else
		TMCommonUseClient.MonitoringNonConsistentChangesCauseException(ThisForm, Command);
	EndIf;
EndProcedure

&AtClient
Procedure ControlOfNonConsistentChangesHandlePushEvent(Item)
	TMCommonUseClient.MonitoringNonConsistentChangesCauseException(ThisForm, Item);
EndProcedure

// Parameters:
//	Item - FormGroup, FormTable, FormField, FormButton - FormItem
&AtClient
Procedure ControlOfNonConsistentChangesHandleEventBeforeStartingChange(Item, Cancel)
	If Item.Name = "Goods" Then
		GoodsBeforeRowChange(Item, Cancel);
	Else
		TMCommonUseClient.MonitoringNonConsistentChangesCauseException(ThisForm, Item);
	EndIf;
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
	
	If ThereAreAdjustingEntries And UseCreditNotes
		And Not HaveRightToAddAdjustments() Then
		
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
			|tr = 'Temel belgeye bir satış düzeltmesi girilmiştir. 
			|Bir satış düzeltmesi oluşturmak için yeterli hak verilmemiştir.'");
		
		CommonClient.MessageToUser(MessageText);
		
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

&AtServer
Procedure FillSetVisibilityAndReFillAvailabilityByShipment()
	
	SeriesSpecificationParameters = New FixedStructure(ProductsServer.SeriesSpecificationParameters(Object, Documents.CustomerInvoice));
	FillInStatusesForSpecifyingSeriesServer();
	SetVisibilityOfSeriesElements();
	
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

// Parameters:
//	Item - FormGroup, FormTable, FormField, FormButton - FormItem
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

#EndRegion

#Region WorkingWithCounterparties
&AtClient
Procedure CheckCounterparties(Command)
	
	
EndProcedure

#EndRegion

#Region FiscalTransaction

&AtClient
Procedure FiscalOperationNavigationLinkProcessing(Item, Var_URL, StandardProcessing)
	
	If Var_URL = "IssueCashReceipt" Then
		
		StandardProcessing = False;
		
		If Not BarcodesOfPackagesAreFilled() Then
			Return;
		EndIf;
		
		If Object.Status = PredefinedValue("Enum.StatusesOfCustomerInvoices.Shipped") Then
			
			GeneratingFiscalChecksClient.DisplayReceipt(
				ThisObject,
				New CallbackDescription("FiscalTransactionCompletion", ThisObject));
			
		Else
			
			StrTemplate = StrTemplate(
				NStr("vi = 'Chỉ có thể lập phiếu đối với các chứng từ ở trạng thái ""%1""';
					|ru = 'Пробитие чека возможно только для документов в статусе ""%1""';
					|en = 'Cash receipt issue is possible only for documents with the ""%1"" status'; fa = 'Cash receipt issue is possible only for documents with the ""%1"" status';
					|it = 'Emissione dello scontrino possibile sono per i documenti conlo stato ""%1""';
					|pl = 'Drukowanie paragonu jest możliwe tylko dla dokumentu ze statusem ""%1""';
					|tr = 'Fiş kesilmesi sadece ""%1"" statüsündeki belgeler için düzenlenebilir'"),
				PredefinedValue("Enum.StatusesOfCustomerInvoices.Shipped"));
			
			CommonClient.MessageToUser(StrTemplate,, "Status", "Object");
		EndIf;

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
	
	UpdateTextDocumentsBasedOn();
	
EndProcedure

#EndRegion

&AtServer
Procedure BeforeSelectingProductsFromOrder(ArrayOfStringCodes, AddressOfGoods)
	
	For Each TSRow In Object.Goods Do
		
		If TSRow.RowCode <> 0 And ValueIsFilled(TSRow.SalesOrder) Then
			ArrayOfStringCodes.Add(New Structure("RowCode,SalesOrder", TSRow.RowCode, TSRow.SalesOrder));
		EndIf;
		
	EndDo;
	
	AddressOfGoods = PutToTempStorage(Object.Goods.Unload(), UUID);
	
EndProcedure

&AtServer
Procedure PrepareDataOnBarcodesOfPackages(AddressOfBarcodesOfPackages)
	
	AddressOfBarcodesOfPackages = PutToTempStorage(Object.PackageBarcodes.Unload(), UUID);
	
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
Procedure ImplementationByOrdersWhenChangedAfterSelection(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		Object.OrderSales = False;
		Return;
	EndIf;
	
	SalesOrder = Result.SalesOrder;
	Object.ARAPObjectSettings = Result.ARAPObjectSettings;
	
	If Object.Goods.Count() = 0 Then
		QueryText = StrReplace(NStr("vi = 'Danh sách Hàng hóa sẽ được điền bằng số dư hàng hóa chưa lập theo chứng từ %SalesOrder%. Tiếp tục?';
									|ru = 'Список Товары будет заполнен остатками неоформленных товаров по документу %SalesOrder%. Продолжить?';
									|en = 'The Item list will be filled in with non-generated goods under the %SalesOrder% document. Continue?'; fa = 'The Item list will be filled in with non-generated goods under the %SalesOrder% document. Continue?';
									|it = 'Elenco Merci sarà compilato con le giacenze delle merci non formalizzate nel documento %SalesOrder%. Continuare?';
									|pl = 'Lista Wiersze pozycji zostanie wypełniona przez resztki niesporządzonych towarów według dokumentu %SalesOrder%. Kontynuować?';
									|tr = 'Ürünler listesi %SalesOrder%belgesinden kalan ürünlerle doldurulacaktır. Devam edilsin mi?'"), "%SalesOrder%", SalesOrder);
	ElsIf Object.BusinessOperation =
			PredefinedValue("Enum.BusinessTransactions.TransferOfTitleToGoods") Then
		QueryText = StrReplace(NStr("vi = 'Các dòng trong danh sách Hàng hóa sẽ được liên kết với các dòng của chứng từ %SalesOrder%. Các dòng mà không được liên kết với các dòng trong lệnh sẽ bị xóa. Tiếp tục?';
									|ru = 'Строки в списке Товары будут привязаны к строкам документа %SalesOrder%. Строки, которые невозможно привязать к строкам распоряжения, будут удалены.  Продолжить?';
									|en = 'Lines in the ""Goods"" list will be linked to lines of the ""%SalesOrder%"" document. Lines that cannot be linked will be deleted. Continue?'; fa = 'Lines in the ""Goods"" list will be linked to lines of the ""%SalesOrder%"" document. Lines that cannot be linked will be deleted. Continue?';
									|it = 'Lines in the ""Goods"" list will be linked to lines of the ""%SalesOrder%"" document. Lines that cannot be linked will be deleted. Continue?';
									|pl = 'Lines in the ""Goods"" list will be linked to lines of the ""%SalesOrder%"" document. Lines that cannot be linked will be deleted. Continue?';
									|tr = 'Ürünler listesindeki satırlar, %SalesOrder% belge satırlarına bağlanacaktır. Sipariş satırlarına bağlanamayan satırlar silinecektir. Devam edilsin mi?'"), "%SalesOrder%", SalesOrder);
	Else
		QueryText = StrReplace(NStr("vi = 'Dòng trong danh sách Hàng hóa sẽ gắn với các dòng của chứng từ %SalesOrder%. Các dòng không thể gắn với dòng của đơn hàng sẽ bị xóa bỏ. Tiếp tục?';
									|ru = 'Строки в списке Товары будут привязаны к строкам документа %SalesOrder%. Строки, которые невозможно привязать к строкам заказа, будут удалены.  Продолжить?';
									|en = 'Lines in the Item list will be linked to lines of the %SalesOrder% document. Lines that cannot be linked will be deleted. Continue?'; fa = 'Lines in the Item list will be linked to lines of the %SalesOrder% document. Lines that cannot be linked will be deleted. Continue?';
									|it = 'Le righe nell''elenco Merci saranno associate alle righe del documento %SalesOrder%. Le righe che non potranno essere associate alle righe dell''ordine saranno eliminate. Continuare?';
									|pl = 'Wiersze na liście Wiersze pozycji zostaną związane z wierszami dokumentu %SalesOrder%. Wiersze, ktorych nie mozna związać z wierszami zamówienia, zostaną usuniete. Kontynuować?';
									|tr = 'Ürünler listesindeki satırlar %SalesOrder% belgesinin satırlarına bağlanacaktır. Sipariş satırlarına bağlanamayan satırlar silinecektir.  Devam edilsin mi?'"), "%SalesOrder%", SalesOrder);
	EndIf;
	
	ImplementationByOrdersWhenFragmentChanges(SalesOrder, QueryText);
	
EndProcedure

&AtServer
Procedure SetVisibilityOfCommandsByOrder()
	
	BasisDocuments = Object.Goods.Unload(, "SalesOrder").UnloadColumn("SalesOrder");
	
	DocumentsByType = SalesServer.DocumentsBasedOnAvailabilityOfSettlementObjects(BasisDocuments);
	ThereAreDocumentsWithCalculationObjects = DocumentsByType.DocumentsWithCalculationObjects.Count() > 0;
	
	VisibilityOfOrderClosingCommands = UseAdvancedFeaturesOfSalesOrder
		And Object.OrderSales
		And ThereAreDocumentsWithCalculationObjects;
	
	Items.CloseOrder.Visible = VisibilityOfOrderClosingCommands;
	Items.CloseOrders_2.Visible = VisibilityOfOrderClosingCommands;
	
EndProcedure

&AtClientAtServerNoContext
Procedure CalculateTotals_(Form)
	
	// Filling in the totals according to the "Products" table
	CollectionProducts = Form.Object.Goods;
	
	Form.AmountTotal = ?(Form.Object.PackageDepositIsRequired,
		CollectionProducts.Total("AmountIncludingVAT"),
		CollectionProducts.Total("AmountIncludingVATWithoutReusablePackages"));
	Form.VATAmount = ?(Form.Object.PackageDepositIsRequired,
		CollectionProducts.Total("VATAmount"),
		CollectionProducts.Total("VATAmountWithoutReusablePackages"));
	
	AutoDiscountAmount = ?(Form.Object.PackageDepositIsRequired,
		CollectionProducts.Total("DiscountMarkupAmount"),
		CollectionProducts.Total("DiscountMarkupAmountWithoutReusablePackages"));
	ManualDiscount = ?(Form.Object.PackageDepositIsRequired,
		CollectionProducts.Total("ManualDiscount"),
		CollectionProducts.Total("ManualDiscountWithoutReusablePackages"));
	AmountAmountOfBonusPointsToBeDebitedInCurrency = ?(Form.Object.PackageDepositIsRequired,
		CollectionProducts.Total("AmountOfBonusPointsToDeductionInCurrency"),
		CollectionProducts.Total("AmountOfBonusPointsToDeductionInCurrencyWithoutReusablePackages"));
	Form.DiscountAmount = AutoDiscountAmount + ManualDiscount + AmountAmountOfBonusPointsToBeDebitedInCurrency;
	
	Form.PackageDepositValue = ?(Form.Object.PackageDepositIsRequired, CollectionProducts.Total("AmountIncludingVAT")
			-CollectionProducts.Total("AmountIncludingVATWithoutReusablePackages"),0);
	
	If VATAccountingERPClientServer.DisplayNDSInResultsOfSalesDocument(Form.Object.VATTaxation) Then
		Form.Items.PagesTotalGroup.CurrentPage = Form.Items.TotalSNDSPage;
		Form.Items.VATPageGroup.CurrentPage = Form.Items.PageVAT;
	Else
		Form.Items.PagesTotalGroup.CurrentPage = Form.Items.PageTotalWithoutVAT;
		Form.Items.VATPageGroup.CurrentPage = Form.Items.PageExcludingVAT;
	EndIf;
	
EndProcedure

&AtServer
Function OrdersAreUsedAsInvoices()
	
	AnArrayOfOrders = Object.Goods.Unload(, "SalesOrder").UnloadColumn("SalesOrder");
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
Procedure AddSBPPaymentStatusUpdateCommand()

	CommandParameters = CashServerLocalization.NewParametersOfSBPPaymentStatusUpdateCommand();
	CommandParameters.Parent = Items.PaymentGroup_2;
	CashServerLocalization.AddSBPPaymentStatusUpdateCommand(ThisObject, CommandParameters);

EndProcedure

&AtClient
Procedure Attachable_SBPPaymentVerification()

	CashClientLocalization.CheckSBPPayment(ThisObject, Object.Ref, Object.Counterparty);

EndProcedure

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
	
	MethodPlaceOfDeliveryCarrierIfChangedServer(Item.Name);
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
Procedure SpecialTransportationConditionsOnChange(Item)
	
	SpecialTransportationConditionsOnChangeServer();
	
EndProcedure

&AtServer
Procedure SpecialTransportationConditionsOnChangeServer()
	
	GoodsDelivery.SpecialTransportationConditionsOnChange(Items, Object);
	
EndProcedure

&AtClient
Procedure Attachable_ProcessObjectEntry()
	
	TMCommonUseClient.ProcessObjectEntryInForm(ThisObject, ParametersForRecording);
	
EndProcedure

&AtClient
Procedure PerformChecksAndAskQuestionsBeforeRecording(Cancel, WriteParameters)
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("WriteParameters", WriteParameters);
	AdditionalParameters.Insert("ThisObject", ThisObject);
	
	If Not Object.OrderSales Then
		
		If Object.Goods.Count() > 0
			And (Object.ReusablePackageFillingStatus = PredefinedValue("Enum.ReusablePackageFillingStates.OfferToFillIn")
				Or Not ValueIsFilled(Object.ReusablePackageFillingStatus)) Then
			
			TableName = "Goods";
			ColumnsNames = "Products,Characteristic,Count,Warehouse";
			
			AskAQuestion = ReusablePackageServerCall.AskQuestionAboutFillingMultiTurnContainers(
				Object,
				TableName,
				ColumnsNames);
			
			If AskAQuestion Then
				
				Cancel = True;
				CallbackDescription = New CallbackDescription(
					"BeforeRecordingOfferToPickUpMultiTurnContainer",
					ThisObject,
					AdditionalParameters);
				
				ReusablePackageClient.OfferToPickUpMultiTurnContainer(
					ThisObject,
					TableName,
					ColumnsNames,
					CallbackDescription,
					AskAQuestion);
				
			Else
				
				CalculateDiscountsBeforeWrite(Cancel);
				
			EndIf;
			
		Else
			
			CalculateDiscountsBeforeWrite(Cancel);
			
		EndIf;
		
	Else
		
		CalculateDiscountsBeforeWrite(Cancel);
		
	EndIf;
	
	If Not Cancel Then
		BeforeWriteAtClientServer();
		FillInIndicatorsOfPaymentStagesClient();
	EndIf;
	
EndProcedure

&AtClient
Procedure CalculateDiscountsBeforeWrite(Cancel)
	
	If UseDiscountsMarkupsInSales
		And Object.BusinessOperation <> PredefinedValue("Enum.BusinessTransactions.TransferToCommissionAgent")
		And Not SalesViaCommissionAgent Then
		
		If Not Object.DiscountsAreCalculated And DiscountsHaveChanged() Then
			
			ApplyDiscountMarkUpChangesOnCustomer(Cancel);
			CalculateTotals_(ThisObject);
			
		Else
			Object.DiscountsAreCalculated = True;
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure BeforeRecordingOfferToPickUpMultiTurnContainer(Result, AdditionalParameters) Export
	
	Cancel = False;
	CalculateDiscountsBeforeWrite(Cancel);
	
	If Not Cancel Then
		
		BeforeWriteAtClientServer();
		FillInIndicatorsOfPaymentStagesClient();
		TMCommonUseClient.RecordObjectIfNecessary(ThisObject, AdditionalParameters.WriteParameters,,True);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure FillInIndicatorsOfPaymentStagesClient()
	
	If Object.BusinessOperation <> PredefinedValue("Enum.BusinessTransactions.TransferToCommissionAgent") Then
		
		If Object.OrderSales And ValueIsFilled(Object.SalesOrder) Then
			For Each CurRow In Object.Goods Do
				If Not ValueIsFilled(CurRow.SalesOrder) Then
					CurRow.SalesOrder = Object.SalesOrder;
				EndIf;
			EndDo;
		EndIf;
		
	EndIf;
	
EndProcedure

&AtServer
Procedure BeforeWriteAtClientServer()
	ARAPAccountingServerCall.FormBeforeRecordingOnClientServer(ThisForm);
EndProcedure

&AtServer
Procedure MethodPlaceOfDeliveryCarrierIfChangedServer(ItemName)
	
	UpdateTextDocumentsBasedOn();
	GoodsDelivery.FillInDeliveryDetails(Items, ItemName, Object);

EndProcedure

&AtServer
Function BarcodesOfPackagesAreFilled()
	
	BarcodesOfPackagesAreFilled = GeneratingFiscalChecksServer.BarcodesOfPackagesAreFilled(Object);
	CheckResult = CheckCorrectnessOfSalesPriceOfIMRCTobaccoProductsLocalization(True);
	
	Return BarcodesOfPackagesAreFilled And CheckResult;
	
EndFunction

&AtServer
Procedure WhenChangingAttributesOfImplementationSPrintServer(FillInAndSetDeliveryAttributes)
	
	If FillInAndSetDeliveryAttributes Then
		GoodsDelivery.FillInDeliveryDetails(Items, "GoodsRecipient", Object);
	EndIf;
	
	UpdateTextDocumentsBasedOn();
	
EndProcedure

#EndRegion

#Region Delivery

&AtClientAtServerNoContext
Procedure UpdateDeliveryPlanningView(Form, DeliveryFlagHasBeenChanged = False)
	
	Object = Form.Object;
	
	If Object.DeliveryIsRequired Then
		
		If Object.OrderSales Then
			
			Object.DeliveryPlanning = PredefinedValue("Enum.DeliveryPlanningKinds.ByCurrentDocument");
			
		Else
			
			TypeOfPlanning = TypeOfDeliveryPlanningByPartnerAgreement(
				Object.Partner,
				Object.Terms,
				Object.OrderSales,
				DeliveryFlagHasBeenChanged);
			
			If TypeOfPlanning <> Undefined Then
				
				Object.DeliveryPlanning = TypeOfPlanning;
				
			EndIf;
		
		EndIf;
		
	EndIf;
	
EndProcedure

&AtServerNoContext
Function TypeOfDeliveryPlanningByPartnerAgreement(Val Partner, Val Terms, Val OrderSales, Val DeliveryFlagHasBeenChanged)
	
	AdvancedOrderOptions = GetFunctionalOption("UseAdvancedFeaturesOfSalesOrder");
	DeliveryPlanning = Undefined;
	
	If Not AdvancedOrderOptions
	 Or Not OrderSales Then
		
		DeliveryPlanning = GoodsDelivery.TypeOfDeliveryPlanningByPartnerAgreement(Partner, Terms);
		
	ElsIf DeliveryFlagHasBeenChanged Then
		
		DeliveryPlanning = Enums.DeliveryPlanningKinds.ByCurrentDocument;
		
	EndIf;
	
	Return DeliveryPlanning;
	
EndFunction

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
		Object.Warehouse, Object.Date);
	
	ThereIsSupportForDeliveryByYourOwnCouriers =
		(ThereIsSupportForDeliveryByYourOwnCouriers
		 And (Object.ARAPObjectSettings <> Enums.ARAPObjectSettings.ByCounterpartyContracts));
	
	ShippingMethodsUsed = New Array; // Array of EnumRef.TransportMethods25
	ShippingMethodsUsed.Add(Enums.TransportMethods25.SelfPickup);
	ShippingMethodsUsed.Add(Enums.TransportMethods25.OwnDelivery); 
	ShippingMethodsUsed.Add(Enums.TransportMethods25.ByCarrier);
	ShippingMethodsUsed.Add(Enums.TransportMethods25.DefinedByDeliveryService);
	If ThereIsSupportForDeliveryByYourOwnCouriers Then
		ShippingMethodsUsed.Add(Enums.TransportMethods25.OurCourier);
	EndIf;
	
	DeliverySettings = GoodsDeliveryClientServer.NewDeliverySettings();
	DeliverySettings.DeliverySpecificationMethod = Enums.DeliverySpecificationMethods.ForWholeDocument;
	DeliverySettings.AllowChangingDeliveryIndicationMethod = False;
	DeliverySettings.DeliveryPlanning = Object.DeliveryPlanning;
	DeliverySettings.AllowChangingTypeOfDeliveryPlanning = Not Object.OrderSales;
	DeliverySettings.DeliveryMethod = Object.DeliveryMethod25;
	DeliverySettings.ShippingMethodsUsed = ShippingMethodsUsed;
	
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
	
	GoodsFieldNames = "Warehouse";
	SearchParameters = New Structure;
	SearchParameters.Insert("ItemsType", Enums.ItemsTypes.OwnGoods);
	GoodsReadyForUnloading = Object.Goods.FindRows(SearchParameters);
	TableOfGoods = Object.Goods.Unload(GoodsReadyForUnloading, GoodsFieldNames);
	WarehouseInformationTable = Object.WarehousesDeliveryInformation.Unload();
	
	Query = New Query;
	QueryText =
	"SELECT
	|	TableOfGoods.Warehouse AS Warehouse
	|INTO TTTableOfGoods
	|FROM
	|	&TableOfGoods AS TableOfGoods
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
	|	TableOfGoods.Warehouse AS Warehouse,
	|	CASE
	|		WHEN TableWarehousesDeliveryDetails.WarehousePoint IS NULL
	|			THEN ISNULL(DeliveryPoints.Ref, VALUE(Catalog.DeliveryPoints.EmptyRef))
	|		ELSE TableWarehousesDeliveryDetails.WarehousePoint
	|	END AS WarehousePoint,
	|	CASE
	|		WHEN TableWarehousesDeliveryDetails.AreaOfWarehouse IS NULL
	|			THEN ISNULL(DeliveryPoints.DeliveryZone, VALUE(Catalog.DeliveryZones.EmptyRef))
	|		ELSE TableWarehousesDeliveryDetails.AreaOfWarehouse
	|	END AS AreaOfWarehouse
	|FROM
	|	TTTableOfGoods AS TableOfGoods
	|		LEFT JOIN Catalog.DeliveryPoints AS DeliveryPoints
	|		ON TableOfGoods.Warehouse = DeliveryPoints.Owner
	|		AND DeliveryPoints.MainPoint
	|		LEFT JOIN TTWarehouseInformationTable AS TableWarehousesDeliveryDetails
	|		ON TableOfGoods.Warehouse = TableWarehousesDeliveryDetails.Warehouse";
	
	Query.Text = QueryText;
	Query.SetParameter("TableOfGoods", TableOfGoods);
	Query.SetParameter("WarehouseInformationTable", WarehouseInformationTable);
	
	CacheOfWarehouses = New Map();
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		
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
	
	Object.WarehousesDeliveryInformation.Clear();
	For Each WarehouseLine_ In Settings.Warehouses Do
	
		NewRow = Object.WarehousesDeliveryInformation.Add();
		FillPropertyValues(NewRow, WarehouseLine_);
		
	EndDo;
	Object.WarehousesDeliveryInformation.Sort("Warehouse");
	
	FieldNamesOfDeliveryPointAddresses = "Address, AddressValue, FieldValueAddress";
	DeliveryPointAddressFields = Common.ObjectAttributesValues(Object.DeliveryPoint, FieldNamesOfDeliveryPointAddresses);
	
	Object.DeliveryAddress = DeliveryPointAddressFields.Address;
	Object.DeliveryAddressFieldValues = DeliveryPointAddressFields.AddressValue;
	Object.DeliveryAddressValue = DeliveryPointAddressFields.FieldValueAddress;
	
EndProcedure

// Parameters:
//  Form - See Document.CustomerInvoice.Form.DocumentForm
//
&AtClientAtServerNoContext
Procedure SetAvailabilityVisibilityOfDeliveryItems(Form)
	
	Object = Form.Object;
	Items = Form.Items;
	UseAdvancedFeaturesOfSalesOrder = Form.UseAdvancedFeaturesOfSalesOrder;
	
	ItemsNames = New Array; // Array of String
	ItemsNames.Add("DeliveryIsRequired");
	ItemsNames.Add("EditDeliveryParametersHeader");
	
	DeliveryIsApplicable = GoodsDeliveryClientServer.BusinessTransactionIsInvolvedInDelivery(Object.BusinessOperation);
	
	If Not GoodsDeliveryClientServer.UsedDelivery25()
		Or Object.Organization = PredefinedValue("Catalog.Companies.ManagementCompany")
		Or Not DeliveryIsApplicable Then
		
		ItemsNames.Add("DecorationDeliveryAction");
		
		TMCommonUseClientServer.SetPropertyOfFormElements(
			Items,
			ItemsNames,
			"Visible",
			False);
		
	Else
		
		// Delivery is used for operations when there can only be orders in the TS,
		// so other types of fields are not checked
		
		NumberOfDiscrepancies = 0;
		
		If Object.OrderSales Then
			
			NumberOfDiscrepancies = Object.Goods.Total("OrderDiscrepancy_3");
			
		EndIf;
		
		If Object.OrderSales Then
			
			If Not UseAdvancedFeaturesOfSalesOrder Then
				
				Items.DecorationDeliveryAction.Visible = False;
				Items.DecorationDeliveryAction.Title = "";
				
				TMCommonUseClientServer.SetPropertyOfFormElements(
					Items,
					ItemsNames,
					"Visible",
					True);
				
			ElsIf UseAdvancedFeaturesOfSalesOrder
				And NumberOfDiscrepancies > 0 Then
				
				Items.DecorationDeliveryAction.Visible = Object.DeliveryIsRequired;
				Items.DecorationDeliveryAction.Title = NStr("ru = '(действуют только на строки сверх заказов)';
															|vi = '(valid only for lines in excess of orders)';
															|en = '(valid only for lines in excess of orders)'; fa = '(valid only for lines in excess of orders)';
															|it = '(valid only for lines in excess of orders)';
															|pl = '(valid only for lines in excess of orders)';
															|tr = '(sadece sipariş fazlası satırlar için geçerlidir)'");
				
				TMCommonUseClientServer.SetPropertyOfFormElements(
					Items,
					ItemsNames,
					"Visible",
					True);
				
			Else
				
				ItemsNames.Add("DecorationDeliveryAction");
				Items.DecorationDeliveryAction.Title = "";
				
				TMCommonUseClientServer.SetPropertyOfFormElements(
					Items,
					ItemsNames,
					"Visible",
					False);
				
			EndIf; 
			
		Else
			
			Items.DecorationDeliveryAction.Visible = False;
			
			TMCommonUseClientServer.SetPropertyOfFormElements(
				Items,
				ItemsNames,
				"Visible",
				True);
			
		EndIf;
		
		CommonClientServer.SetFormItemProperty(
			Items,
			"EditDeliveryParametersHeader",
			"Enabled",
			Object.DeliveryIsRequired);
		
	EndIf;
	
EndProcedure

#EndRegion

#Region Delivery20

&AtServer
Procedure SupplementDeliveryInformationWithContactsServer()
	
	GoodsDelivery.SupplementDeliveryInformationWithContacts(Object);
	
EndProcedure

#EndRegion

#EndRegion

#Region Localization

&AtClient
Procedure AddLocalizationFormParameters(FormParameters)
	
	
EndProcedure

&AtClient
Procedure NotificationProcessingLocalization(EventName, Parameter, Source)
	
	
	Return;
	
EndProcedure


&AtServer
Procedure UpdateTextDocumentsBasedOnLocalization()
	
	
	Return;
	
EndProcedure

&AtClient
Procedure TextDocumentsBasedOnURLProcessingLocalization(Item, FormattedStringURL, StandardProcessing)
	

	Return;
	
EndProcedure

&AtServer
Procedure SetAvailabilityVisibilityOfBuildAndDeliveryItems()
	
	DateWarehouseSettingsWereCalculated = Object.Date;
	
	WarehouseSettings = WarehousesServer.WarehouseSettingsForAssemblyAndDelivery(Object.Warehouse, DateWarehouseSettingsWereCalculated);
	
	ThereIsSupportForDeliveryByYourOwnCouriers = False;
	ThereIsSupportForBuildingOrders = False;
	
	If WarehouseSettings <> Undefined Then
		ThereIsSupportForDeliveryByYourOwnCouriers = WarehouseSettings.StoreSupportsDeliveryByOwnCouriers;
		ThereIsSupportForBuildingOrders = WarehouseSettings.StoreSupportsOrderAssembly;
	EndIf;
	
	ThereIsSupportForDeliveryByYourOwnCouriers = ThereIsSupportForDeliveryByYourOwnCouriers
		And (Object.ARAPObjectSettings <> Enums.ARAPObjectSettings.ByCounterpartyContracts);
		
	If GoodsDeliveryClientServer.UsedDelivery20()
		And Not ThereIsSupportForDeliveryByYourOwnCouriers
		And Object.DeliveryMethod = Enums.TransportMethods.ToCustomerByCourier Then
		
		Object.DeliveryMethod = Enums.TransportMethods.SelfPickup;
		MethodPlaceOfDeliveryCarrierIfChangedServer(Items.DeliveryMethod.Name);
		
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
	
	GoodsDelivery.UpdateShippingMethodSelectionListForShippingWarehouse(Items.DeliveryMethod, ThereIsSupportForDeliveryByYourOwnCouriers);
	Items.Picker.Visible = ThereIsSupportForBuildingOrders;
	
EndProcedure

&AtClient
Procedure CloseKmVerificationSessionOnCCT(Val Cancel)
	
	
	Return;
	
EndProcedure

&AtServer
Function CheckCorrectnessOfSalesPriceOfIMRCTobaccoProductsLocalization(CurrentDateControl)
	
	CheckResult = True;
	
	
	Return CheckResult;
	
EndFunction

&AtServer
Procedure CheckCorrectAvailabilityOfDiscountsPaymentsWithBonusPointsLocalization()
	
	
EndProcedure

&AtClient
Procedure AddPriceControlParameterForIDCLocalizationToForm(Form, FormParameters)
	
	
EndProcedure


&AtServer
Function GetFOMarkingValues()
	
	UseLabeling = False;
	
	Return UseLabeling;
	
EndFunction

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
Procedure ControlOfSalesOfTobaccoProductsOnlyByMRCLocalization(Item, Cancel)
	
	
EndProcedure

&AtServer
Procedure UpdateSalesTagForTobaccoProductsOnlyByMRCLocalization(Form)
	
	
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
	If Item.Name = "sh_ShamsiInput_DateOfTransferOfTitleToGoods" Then
		DateOfTransferOfTitleToGoodsOnChange(Items.DateOfTransferOfTitleToGoods);
	ElsIf Item.Name = "sh_ShamsiInput_Date" Then
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
