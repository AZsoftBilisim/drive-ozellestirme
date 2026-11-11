#Region Variables

// used by the mechanism for processing changes in PM details
&AtClient
Var CachedValues;

//used to pass the current line to the wait handler
&AtClient
Var CurDataId;

&AtClient
Var CounterpartyVerificationWaitHandlerParameters Export;

&AtClient
Var TimeConsumingOperationForm Export;

#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	SetConditionalAppearance();
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	Items.ReflectionInAccounting_.TitleTextColor = Metadata.StyleItems.HyperlinkColor.Value;

	InfobaseUpdate.CheckObjectProcessed(Object, ThisObject);

	TMCommonUse.CustomizePeripherals(ThisForm);
	
	ObjectsVersioning.OnCreateAtServer(ThisObject); // Handler of the subsystem "Versioning of objects" // Handler of the subsystem "External processing"
	
	If Not ValueIsFilled(Object.Ref) Then
		OnReadCreateAtServer(Object);
		ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);
	EndIf;
	
	If ClientApplication.CurrentInterfaceVariant() = ClientApplicationInterfaceVariant.Version8_2 Then
		Items.GroupInTotal.BackColor = New Color();
	EndIf;
	
	ARAPAccountingFormWork.FormWhenCreatedOnServer(ThisForm);
	
	AccountingForTraceableGoodsLocalization.EstablishVisibilityOfRNPTQuantity(ThisForm, Object.Date);
		
	Items.GoodsPriceKind.QuickChoice = Not GetFunctionalOption("UseSeveralPriceTypes");

	
	
	Items.DecorationEDOState.Visible = GetFunctionalOption("UseElectronicDocumentExchangeWithCounterparties");
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands

	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject);
	// End IntegrationWith1CDocumentManagementSubsystem
	
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	
	DocumentCorrection.OnCreateAtServer(ThisForm, Items.LineCorrection);
	
	// Handler of the "Destination" mechanism
	Catalogs.Assignments.DocumentFormWhenCreatedOnServer(ThisForm);

	// StandardSubsystems.FilesOperations
	HyperlinkParameters = FilesOperations.FilesHyperlink();
	HyperlinkParameters.Location = "CommandBar";
	FilesOperations.OnCreateAtServer(ThisObject, HyperlinkParameters);
	// End StandardSubsystems.FilesOperations

	// Standard subsystems.Accounting of the originals of the first documents
	SourceDocumentsOriginalsRecording.OnCreateAtServerDocumentForm(ThisObject);
	// The end of the standard subsystem.Accounting of the originals of the first documents 
	
	AccountingForTraceableGoodsLocalization.SetTitleNumberOfCCD(Items, "GoodsCCDNumber");
	
	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)

	// StandardSubsystems.AccessManagement
	AccessManagement.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.AccessManagement

	// Handler of the "Date-change" mechanism
	PeriodClosingDates.ObjectOnReadAtServer(ThisForm, CurrentObject);
	
	DocumentCorrection.OnReadAtServer(ThisForm, Items.LineCorrection);
	
	OnReadCreateAtServer(CurrentObject);
	
	ARAPAccountingFormWork.FormWhenReadingOnServer(ThisForm);

	FormEvents.OnReadAtServer(ThisObject, CurrentObject);
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	// End StandardSubsystems.AttachableCommands
	
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	
	EquipmentManagerClient.StartConnectingDevicesWhenYouOpenForm(Undefined, ThisForm, "BarcodeScanner");
	
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// The end of the standard subsystem.Pluggable commands
	// Standard subsystems.Worksfiles
	FilesOperationsClient.OnOpen(ThisObject, Cancel);
	// End StandardSubsystems.FilesOperations

EndProcedure

&AtClient
Procedure ChoiceProcessing(ValueSelected, ChoiceSource)
	
	If ChoiceSource.FormName = "CommonForm.SelectGoodsIntercompany" Then
		GetProductsFromStorage(ValueSelected);
	ElsIf ChoiceSource.FormName = "Catalog.InventoryKinds.Form.InventoryOwnerAttributesForm" Then	
		GetStockTypesFromStorage(ValueSelected);
	ElsIf VATAccountingERPClient.FinishedEditingInvoiceIssued(ValueSelected, ChoiceSource) Then
		UpdateInvoiceText();
	ElsIf VATAccountingERPClient.FinishedEditingInvoiceReceived(ValueSelected, ChoiceSource) Then
		UpdateInvoiceText();
	ElsIf ChoiceSource.FormName = "CommonForm.PrintingDetailsOfSales" Then
		If ValueSelected <> Undefined Then
			Modified = True;
			FillPropertyValues(Object, ValueSelected);
		EndIf;
	ElsIf ProductsClient.ThisIsIndicationOfSeries(ChoiceSource) Then
		ProductsClient.ProcessSeriesIndication(ThisForm, SeriesSpecificationParameters, ValueSelected);
	ElsIf PurchasesClient.ThisIsSelectionOfCCDNumber(ChoiceSource) Then
		ProcessSelectionOfCCDNumber(ValueSelected);
	ElsIf ChoiceSource.FormName = "CommonForm.SelectGoodsBySalesAndTransfers" Then
		SelectionProcessingSelectionByTransfersServer(ValueSelected.GoodsAddressInStorage);
	EndIf;
	
	If Window <> Undefined Then
		Window.Activate();
	EndIf;
	
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
	
	If EventName = "Write_InvoiceIssued"
		And ((Parameter.Property("OwnerForm") And Parameter.OwnerForm = UUID)
			Or Parameter.Property("ListOfGrounds") And Parameter.ListOfGrounds.FindByValue(Object.Ref) <> Undefined) Then
		UpdateInvoiceText();
	EndIf;
	
	
	
	DocumentCorrectionClient.NotificationProcessing(ThisObject, EventName, Parameter, Source);
	
	FormEventsClient.NotificationProcessing(ThisObject, EventName, Parameter, Source);
	
	// StandardSubsystems.FilesOperations
	FilesOperationsClient.NotificationProcessing(ThisObject, EventName);
	// End StandardSubsystems.FilesOperations
	
	If ARAPAccountingClient.NeedAlertProcessingCall(ThisObject, EventName, Parameter) Then
		ProcessingNotificationOnServer(EventName, Parameter);
	EndIf;
	
	// StandardSubsystems.SourceDocumentsOriginalsRecording	
	SourceDocumentsOriginalsRecordingClient.NotificationHandlerDocumentForm(EventName,ThisObject);
	// End StandardSubsystems.SourceDocumentsOriginalsRecording
	
EndProcedure

&AtServer
Procedure ProcessingNotificationOnServer(EventName, Parameter)
	
	ARAPAccountingFormWork.NotificationProcessing(ThisForm, EventName, Parameter);
	
EndProcedure

&AtClient
Procedure NewWriteProcessing(NewObject, Source, StandardProcessing)
	
	If PurchasesClient.ThisIsIndicationOfCCDNumber(Source) Then
		Actions = New Structure;
		
		AccountingForTraceableGoodsClientServerLocalization.AddDescriptionOfSettingsForRecalculatingDetailsOfTablePart(
			Object,
			Actions);
		
		PurchasesClient.ProcessIndicationOfCCDNumber(ThisObject, NewObject, , , Actions);
	EndIf;
	
EndProcedure

&AtClient
Procedure URLProcessing(FormattedStringURL, StandardProcessing)
	
	FormEventsClient.URLProcessing(ThisObject, FormattedStringURL, StandardProcessing);
	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
		
	
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
	
	FillInOtherFormDetails();
	FillInAdditionalProductAttributes();
	UpdateInformationOnTransfers();
	
	UpdateInvoiceText();
	EstablishCostPresentation();
	
	ARAPAccountingFormWork.FormAfterRecordingOnServer(ThisForm, CurrentObject.AdditionalProperties);
	
	
	PurchasesServer.FillInServiceAttributesOfCCDNumber(Object.Goods);
	
	
	FormEvents.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	
	ExcisableGoodsAccounting.UpdateElementsOfAccountingForExcisableItems(ThisObject, False);
	
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	
	WriteParameters.Insert("NotificationDocumentKeys", OperationsWithDocumentJournalsClient.GetKeyParametersForDocument(
		Object.Ref, Object.Date, Object.BusinessOperation));
	Notify("Write_IntercompanyGoodsReturn",WriteParameters,Object.Ref);
	ARAPAccountingClient.FormAfterRecording(ThisForm);
	
	
	ConfigurationModificationClientOverridable.AfterWrite(ThisForm, WriteParameters);
	
	// StandardSubsystems.AttachableCommands
	If CommonClient.SubsystemExists("StandardSubsystems.AttachableCommands") Then
		ModuleAttachableCommandsClient = CommonClient.CommonModule("AttachableCommandsClient");
		ModuleAttachableCommandsClient.AfterWrite(ThisObject, Object, WriteParameters);
	EndIf;
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

&AtClient
Procedure OnClose(Exit)

	EquipmentManagerClient.StartDisablingHardwareWhenClosingForm(Undefined, ThisForm);

EndProcedure

&AtServer
Procedure OnWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	
EndProcedure

&AtClient
Procedure BeforeWrite(Cancel, WriteParameters)
	
	FormEventsClient.BeforeWrite(ThisObject, Cancel, WriteParameters);

EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure CompanyRecipientOnChange(Item)
	If ValueIsFilled(Object.CompanyRecipient) Then
		CompanyRecipientOnChangeServer();
	Else
		Object.DeliveryAddress = "";
	EndIf;
	SetContractSelectionParameters();
	FinancesClientServer.RecalculateAmountsInPaymentDecryptionLine(Object, Object.Goods.Total("AmountIncludingVAT"));
	UpdateInformationOnTransfers();
EndProcedure

&AtClient
Procedure OrganizationOnChange(Item)
	If ValueIsFilled(Object.Organization) Then
		OrganizationOnChangeServer();
	EndIf;
	UpdateInformationOnTransfers();
EndProcedure

&AtClient
Procedure CurrencyOnChange(Item)
	If ValueIsFilled(Object.Currency) And DocumentCurrency<>Object.Currency And Object.Goods.Count()>0 Then
		CurrencyOnChangeServer(Object.Currency);
		PriceManagementSystemClient.NotifyAboutEndOfConversionOfAmountsIntoCurrency(DocumentCurrency,Object.Currency);
	EndIf;
	DocumentCurrency = Object.Currency;
	SetContractSelectionParameters();
EndProcedure

&AtClient
Procedure PriceKindOnChange(Item)
	If ValueIsFilled(Object.PriceKind) And Object.Goods.Count()>0 Then
		DialogResponse = Undefined;

		ShowQueryBox(New CallbackDescription("PriceKindOnChangeCompletion", ThisObject), NStr("vi = 'Điền lại giá trong phần bảng chứng từ?';
																								|ru = 'Перезаполнить цены в табличной части документа?';
																								|en = 'Refill prices in the table of the document?'; fa = 'Refill prices in the table of the document?';
																								|it = 'Ricompilare i prezzi nella parte tabulare del documento?';
																								|pl = 'Wypełnić ponowie ceny w części tabelarycznej dokumentu?';
																								|tr = 'Belgenin tablo bölümündeki fiyatları yeniden doldur?'"),QuestionDialogMode.YesNo);
	EndIf;
EndProcedure

&AtClient
Procedure PriceKindOnChangeCompletion(QuestionResult, AdditionalParameters) Export
    
    DialogResponse = QuestionResult;
    If DialogResponse = DialogReturnCode.Yes Then
        PricesCalculated = FillInPricesByPriceKindServer(Object.PriceKind);
        SalesClient.NotifyAboutEndOfFillingInPricesByTypeOfPrices(PricesCalculated, Object.PriceKind);
    EndIf;

EndProcedure

&AtClient
Procedure CounterpartyOnChange(Item)
	
	CounterpartyOnChangeServer();
	
	
EndProcedure

&AtClient
Procedure PartnerOnChange(Item)
	PartnerOnChangeServer();
	
	
EndProcedure

&AtClient
Procedure TextInvoiceURLProcessing(Item, Var_URL, StandardProcessing)
	
	RegistrationParameters = ParametersForRegisteringInvoicesIssuedServer(Object);
	
	VATAccountingERPClient.ProcessingNavigationLinkInvoicesIssued(ThisForm, Var_URL, StandardProcessing,
		RegistrationParameters);
	
EndProcedure

&AtClient
Procedure TextIntermediaryInvoiceURLProcessing(Item, Var_URL, StandardProcessing)
	
	RegistrationParameters = ParametersForRegisteringInvoicesReceivedServer(Object);
	
	VATAccountingERPClient.ProcessingNavigationLinkInvoicesReceived(ThisForm, Var_URL, StandardProcessing,
		RegistrationParameters);
	
EndProcedure

&AtClient
Procedure ARAPAccountingViaSeparateCounterpartyOnChange(Item)
	
	ARAPAccountingViaSeparateCounterpartyOnChangeServer();
	
EndProcedure

&AtServer
Procedure ARAPAccountingViaSeparateCounterpartyOnChangeServer()

	ConfigureIntermediaryElements();
	SetContractSelectionParameters();
	UpdateInvoiceText();

	ARAPAccountingFormWork.WhenChangingParametersOfMechanism(ThisForm);
	ContractOnChangeServer();

EndProcedure

&AtClient
Procedure BusinessOperationOnChange(Item)
	Object.InventoryOwnerAttributesAreSpecifiedManually = Object.InventoryOwnerAttributesAreSpecifiedManually;
	BusinessOperationOnChangeServer();
EndProcedure

&AtClient
Procedure CustomerVATExemptOnChange(Item)
	
	UpdateInvoiceText();
	
EndProcedure

&AtClient
Procedure PriceIncludesVATOnChange(Item)
	PriceIncludesVATOnChangeServer(CachedValues);
	FinancesClientServer.RecalculateAmountsInPaymentDecryptionLine(Object, Object.Goods.Total("AmountIncludingVAT"));
EndProcedure

&AtClient
Procedure VATTaxationOnChange(Item)
	
	ClearMessages();
	
	VATTaxationOnChangeServer();
	FinancesClientServer.RecalculateAmountsInPaymentDecryptionLine(Object, Object.Goods.Total("AmountIncludingVAT"));
	
EndProcedure

&AtClient
Procedure Decorationedonage(Item, StandardProcessing)
	
	
EndProcedure

&AtClient
Procedure DateOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	
	DateOnChangeServer();
	
	
EndProcedure

&AtClient
Procedure LineOfBusinessOnChange(Item)
	
	 LineOfBusinessOnChangeServer();
	
EndProcedure

&AtClient
Procedure ContractOnChange(Item)
	ContractOnChangeServer();
EndProcedure

&AtClient
Procedure SalesContractOnChange(Item)
	SalesContractOnChangeServer();
EndProcedure

&AtClient
Procedure PurchasingContractOnChange(Item)
	PurchasingContractOnChangeServer();
EndProcedure

&AtClient
Procedure TransferHeaderLabelClick(Item, StandardProcessing)
	StandardProcessing = False;
	OpenForm(
		"CommonForm.ViewingListOfDocuments",
		New Structure("DocumentsList, Title",
			TransferList,
			NStr("vi = 'Chuyển giao hàng hóa giữa các doanh nghiệp (%DocumentsCount%)';
				|ru = 'Передачи товаров между организациями (%DocumentsCount%)';
				|en = 'Customer invoices — Intercompany (%DocumentsCount%)'; fa = 'Customer invoices — Intercompany (%DocumentsCount%)';
				|it = 'Trasferimento dei prodotti interaziendale (%DocumentsCount%)';
				|pl = 'Transfer towarów między firmami (%DocumentsCount%)';
				|tr = 'İş yerleri arası müşteri faturaları (%DocumentsCount%)'")),
		ThisForm,,,, Undefined, FormWindowOpeningMode.LockOwnerWindow);	
EndProcedure

&AtClient
Procedure Attachable_OriginalStateDecorationClick()

	// StandardSubsystems.SourceDocumentsOriginalsRecording
	SourceDocumentsOriginalsRecordingClient.OpenStateSelectionMenu(ThisObject,Items.OriginalStateDecoration);
	//End StandardSubsystems.SourceDocumentsOriginalsRecording

EndProcedure

&AtClient
Procedure LineCorrectionURLProcessing(Item, FormattedStringURL, StandardProcessing)
	
	DocumentCorrectionClient.StringFixHandlingNavigationLinks(
		ThisObject, FormattedStringURL, StandardProcessing);
	
EndProcedure

&AtClient
Procedure FeaturesOfReflectionONChange(Item)

	UpdateAttributesOfAccountingDocument();
	Items.ReflectionInAccounting_.Title = TitleOfReflectionInAccounting(Object.RecordInProfitLossOfPreviousYears);

EndProcedure

&AtClient
Procedure SubjectToExciseOnChange(Item)
	ExcisableGoodsAccountingClientServer.ConfigureProductionDivisionField(ThisObject);
	Return; // Not used in TM
EndProcedure

&AtClient
Procedure PagesOnCurrentPageChange(Item, CurrentPage)
	If CurrentPage.Name = "AdditionalPage" And ItIsRequiredToUpdateTitleIsSubjectToExciseDuty Then
		CalculateNumberOfExcisableItemsDeferred();
		ExcisableGoodsAccountingClient.AfterCalculatingNumberOfExcisableItems(ThisObject);
	EndIf;
	Return; // Not used in TM
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersGoods

&AtClient
Procedure GoodsSelection(Item, RowSelected, Field, StandardProcessing)
	
	CurrentData = Item.CurrentData;
	
	If Field = Items.GoodsPrice
	 And ValueIsFilled(CurrentData.PriceKind) Then
		
		ClearMessages();
		CommonClientServer.MessageToUser(
			NStr("vi = 'Để soạn đơn giá, hãy xóa dạng giá';
				|ru = 'Для редактирования цены очистите вид цены';
				|en = 'To edit the price, clear the price type'; fa = 'To edit the price, clear the price type';
				|it = 'Для редактирования цены очистите вид цены';
				|pl = 'To edit the price, clear the price type';
				|tr = 'Fiyatı düzenlemek için fiyat türünü temizleyin'"),
			Object.Ref,
			CommonClientServer.PathToTabularSection("Object.Goods", CurrentData.LineNumber, "PriceKind"),);
	ElsIf Field = Items.GoodsSum
	 And ValueIsFilled(CurrentData.PriceKind) Then
	 
		ClearMessages();
		CommonClientServer.MessageToUser(
			NStr("vi = 'Để soạn số tiền, hãy xóa dạng giá';
				|ru = 'Для редактирования суммы очистите вид цены';
				|en = 'To edit the amount, clear the price type'; fa = 'To edit the amount, clear the price type';
				|it = 'Для редактирования суммы очистите вид цены';
				|pl = 'To edit the amount, clear the price type';
				|tr = 'Tutarı düzenlemek için fiyat türünü temizle'"),
			Object.Ref,
			CommonClientServer.PathToTabularSection("Object.Goods", CurrentData.LineNumber, "PriceKind"),);
	ElsIf Field = Items.GoodsMethodForDeterminingTheCostOfALine Then
		FormParameters = New Structure;
		FormParameters.Insert("Organization", Object.CompanyRecipient);
		FormParameters.Insert("Date", Object.Date);
		FormParameters.Insert("CompanyRecipient", Object.Organization);
		FormParameters.Insert("Contract", Object.Contract);
		FormParameters.Insert("CostDefiningMethod", CurrentData.CostDefiningMethod);
		FormParameters.Insert("CostPriceKind", PredefinedValue("Catalog.TypesOfPrices.EmptyRef"));
		FormParameters.Insert("DateOfCostFillingByPriceType", Object.Date);
		FormParameters.Insert("NumberOfPackages", CurrentData.NumberOfPackages);
		FormParameters.Insert("DocumentTransfers_", CurrentData.DocumentTransfers_);
		FormParameters.Insert("Package", CurrentData.Package);
		FormParameters.Insert("TaxationType", Object.VATTaxation);
		FormParameters.Insert("DocumentTransfers_", CurrentData.DocumentTransfers_);
		FormParameters.Insert("Products", CurrentData.Products);
		FormParameters.Insert("Characteristic", CurrentData.Characteristic);
		FormParameters.Insert("VATRate", CurrentData.VATRate);
		FormParameters.Insert("DocumentCurrency", Object.Currency);
		FormParameters.Insert("Cost_", CurrentData.Cost_);
		FormParameters.Insert("CostExcludingVAT_", CurrentData.CostExcludingVAT_);
		FormParameters.Insert("CostLocal", CurrentData.CostLocal);
		FormParameters.Insert("CDCost", CurrentData.CDCost);
		FormParameters.Insert("TDCost", CurrentData.TDCost);
		OpenForm("Document.IntercompanyGoodsReturn.Form.SelectionFormOfCostDefiningMethod",
				FormParameters,
				Item,,,,
				New CallbackDescription("ChoosingMethodForDeterminingCostOfProduction", ThisObject),
				FormWindowOpeningMode.LockOwnerWindow);
	EndIf;
	
EndProcedure

&AtClient
Procedure GoodsOnStartEdit(Item, NewRow, Copy)
	
	ProcessingOfTabularFormsClient.CacheCurLine(Items.Goods, ThisObject);
	If NewRow And Not Copy Then
		Items.Goods.CurrentData.PriceKind = Object.PriceKind;
	EndIf;
	CurrentRow = Items.Goods.CurrentData;
	If NewRow Then
		CurrentRow.CostDefiningMethod = PredefinedValue("Enum.WaysToCalculateReturnCost.FromCurrentDocument");
		SetCostPresentationInLine(CurrentRow);
	EndIf;
EndProcedure

&AtClient
Procedure GoodsOnEditEnd(Item, NewRow, CancelEdit)
	
	FinancesClientServer.RecalculateAmountsInPaymentDecryptionLine(Object,Object.Goods.Total("AmountIncludingVAT"));
	
	AdditionalParameters = New Structure;
	FormEventsClient.WhenChangingElement(ThisObject, Items.Goods, AdditionalParameters);
	GoodsAtEndOfEditingOnServer(AdditionalParameters.Property("ServerCallRequired__"));
	
	SetVisibilityOfElementsInTransferDocuments();
	OrderOfReflection = OrderOfReflection(Object.RecordInProfitLossOfPreviousYears);
	Items.ReflectionInAccounting_.Title = TitleOfReflectionInAccounting(Object.RecordInProfitLossOfPreviousYears);
	
EndProcedure

&AtClient
Procedure GoodsBeforeDeleteRow(Item, Cancel)
	ProcessingOfTabularFormsClient.CacheCurLine(Items.Goods, ThisObject);
EndProcedure

&AtClient
Procedure GoodsAfterDeleteRow(Item)
	FinancesClientServer.RecalculateAmountsInPaymentDecryptionLine(Object,Object.Goods.Total("AmountIncludingVAT"));
	ProductsAfterDeletionOnServer();
EndProcedure

&AtClient
Procedure GoodsProductsOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;
	
	PriceActions = BatchProcessingOfTablePartClientServer.ParametersForFillingInPriceInTSLine(Object);
	ActionsVATRecalculation = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	Actions = New Structure;
	
	ActionFillInVATRate = BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRate(Object);
	ActionFillInVATRate.Organization = Object.CompanyRecipient;
	If ValueIsFilled(CurrentRow.DocumentTransfers_) Then
		ActionFillInVATRate.ByCorrectionDate = True;
		ActionFillInVATRate.CorrectedDocument = CurrentRow.DocumentTransfers_;
	ElsIf  ValueIsFilled(Object.DocumentTransfers_) Then
		ActionFillInVATRate.ByCorrectionDate = True;
		ActionFillInVATRate.CorrectedDocument = Object.DocumentTransfers_;
	EndIf;
	Actions.Insert("CheckCharacteristicsByOwner",CurrentRow.Characteristic);
	Actions.Insert("CheckFillPackageByOwner",CurrentRow.Package);
	Actions.Insert("FillInVATRate", ActionFillInVATRate);
	Actions.Insert("FillInVATRateByPriceType", BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRateByPriceType(Object));
	Actions.Insert("RecalculateNumberOfUnits");
	Actions.Insert("FillInSalePrice",PriceActions);
	Actions.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));
	Actions.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
	Actions.Insert("RecalculateAmount");
	Actions.Insert("RecalculateVATAmount",ActionsVATRecalculation);
	Actions.Insert("RecalculateAmountWithVAT",ActionsVATRecalculation);
	Actions.Insert("CheckSeriesCalculateStatus", New Structure("Warehouse, SeriesSpecificationParameters", Object.Warehouse, SeriesSpecificationParameters));
	Actions.Insert("FillInCCDTrackingAttribute", New Structure("Products", "TheRecordsAreKeptByCCD"));
	Actions.Insert("FillInCountryOfOriginOfProduct",
						BatchProcessingOfTablePartClientServer.CountryOfOriginFillingParameters());
	
	Actions.Insert("ProductsOnChangeOverridable", New Structure("FormName, TabularSectionName",
		FormName, "Goods"));
	
	BatchProcessingOfTablePartClientServerLocalization.CompleteActionStructureWhenChangingElement(
		ThisObject, "Products", Actions);
	AccountingForTraceableGoodsClientServerLocalization.AddDescriptionOfSettingsForRecalculatingDetailsOfTablePart(
		Object,
		Actions);
	AccountingForTraceableGoodsClientServerLocalization.CompleteDescriptionOfSettingsForFillingInServiceDetailsOfTablePart(Actions);
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, Actions, CachedValues);
	
	If Not CurrentRow.TheRecordsAreKeptByCCD Then
		CurrentRow.CCDNumber = Undefined;
		CurrentRow.CCDNumberType = Undefined;
		CurrentRow.OriginCountry = Undefined;
	EndIf;
	ItIsRequiredToUpdateTitleIsSubjectToExciseDuty = UseExcisableGoods;
EndProcedure

&AtClient
Procedure GoodsCharacteristicOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;
	
	PriceActions = BatchProcessingOfTablePartClientServer.ParametersForFillingInPriceInTSLine(Object);
	ActionsVATRecalculation = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	
	Actions = New Structure;
	Actions.Insert("FillInVATRateByPriceType", BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRateByPriceType(Object));
	Actions.Insert("FillInSalePrice",PriceActions);
	Actions.Insert("RecalculateAmount");
	Actions.Insert("RecalculateVATAmount",ActionsVATRecalculation);
	Actions.Insert("RecalculateAmountWithVAT",ActionsVATRecalculation);
	Actions.Insert("CharacteristicOnChangeOverridable", New Structure("FormName, TabularSectionName",
		ThisForm.FormName, "Goods"));

	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, Actions, CachedValues);
	
EndProcedure

&AtClient
Procedure GoodsNumberOfPackagesOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;
	
	StructureOfActions = New Structure;
	AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions,Object);
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
EndProcedure

&AtClient
Procedure GoodsPackageOnChange(Item)
	
	ClearMessages();
	
    PriceActions = BatchProcessingOfTablePartClientServer.ParametersForFillingInPriceInTSLine(Object);
	ActionsVATRecalculation = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	Actions = New Structure;
    CurrentRow = Items.Goods.CurrentData;
    
    Actions.Insert("RecalculateNumberOfUnits");
    If CurrentRow.Count > 0 Then
        Actions.Insert("RecalculatePricePerPackage",CurrentRow.Count);
    ElsIf ValueIsFilled(CurrentRow.PriceKind) Then
        Actions.Insert("FillInSalePrice",PriceActions);
    EndIf;

	Actions.Insert("FillInVATRateByPriceType", BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRateByPriceType(Object));
	Actions.Insert("RecalculateAmount");
	Actions.Insert("RecalculateVATAmount",ActionsVATRecalculation);
	Actions.Insert("RecalculateAmountWithVAT",ActionsVATRecalculation);
	AccountingForTraceableGoodsClientServerLocalization.AddDescriptionOfSettingsForRecalculatingDetailsOfTablePart(
		Object,
		Actions);
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, Actions, CachedValues);
EndProcedure

&AtClient
Procedure GoodsPriceKindOnChange(Item)
	
	ClearMessages();
	
	CurrentRow = Items.Goods.CurrentData;
	
	PriceActions = BatchProcessingOfTablePartClientServer.ParametersForFillingInPriceInTSLine(Object);
	ActionsVATRecalculation = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	
	Actions = New Structure;
	Actions.Insert("FillInSalePrice",PriceActions);
	Actions.Insert("RecalculateAmount");
	Actions.Insert("RecalculateVATAmount",ActionsVATRecalculation);
	Actions.Insert("RecalculateAmountWithVAT",ActionsVATRecalculation);
	Actions.Insert("FillInVATRateByPriceType", BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRateByPriceType(Object));
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, Actions, CachedValues);

EndProcedure

&AtClient
Procedure GoodsPriceOnChange(Item)
	ActionsVATRecalculation = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	Actions = New Structure;
    CurrentRow = Items.Goods.CurrentData;
    
	If ValueIsFilled(CurrentRow.PriceKind) And CurrentRow.Price<>0 Then
		CurrentRow.PriceKind = Undefined;
	EndIf;
    
	Actions.Insert("RecalculateAmount");
	Actions.Insert("RecalculateVATAmount",ActionsVATRecalculation);
	Actions.Insert("RecalculateAmountWithVAT",ActionsVATRecalculation);
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, Actions, CachedValues);
EndProcedure

&AtClient
Procedure GoodsVATRateOnChange(Item)
	ActionsVATRecalculation = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	Actions = New Structure;
    CurrentRow = Items.Goods.CurrentData;
    
	Actions.Insert("RecalculateAmount");
	Actions.Insert("RecalculateVATAmount",ActionsVATRecalculation);
	Actions.Insert("RecalculateAmountWithVAT",ActionsVATRecalculation);
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, Actions, CachedValues);
EndProcedure

&AtClient
Procedure GoodsSumOnChange(Item)
	ActionsVATRecalculation = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	Actions = New Structure;
    CurrentRow = Items.Goods.CurrentData;

	Actions.Insert("RecalculatePriceDiscountByAmountInSales");

	Actions.Insert("RecalculateVATAmount",ActionsVATRecalculation);
	Actions.Insert("RecalculateAmountWithVAT",ActionsVATRecalculation);
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, Actions, CachedValues);
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
Procedure GoodsDocumentTransfers_OnChange(Item)
	
	UpdateInformationOnTransfers();
	
EndProcedure

&AtClient
Procedure GoodsMethodForDeterminingTheCostOfALineOnChange(Item)
	UpdateInformationOnTransfers();
EndProcedure

&AtClient
Procedure GoodsCCDNumberOnChange(Item)
	
	CurrentData = Items.Goods.CurrentData;
	
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	FillParameters = New Structure("CCDNumber", CurrentData.CCDNumber);
	
	Actions = New Structure;
	Actions.Insert("FillInCCDNumberType", FillParameters);
	Actions.Insert("FillInCountryOfOriginForCCDNumber", FillParameters);
	
	AccountingForTraceableGoodsClientServerLocalization.AddDescriptionOfSettingsForRecalculatingDetailsOfTablePart(
		Object,
		Actions);
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentData, Actions, Undefined);
	
EndProcedure

&AtClient
Procedure GoodsCCDNumberCreating(Item, StandardProcessing)
	
	StandardProcessing = False;
	
	CurrentData = Items.Goods.CurrentData;
	
	AdditionalParameters = PurchasesClient.AdditionalParametersForCreatingCCDNumber();
	FillPropertyValues(AdditionalParameters, Object);
	FillPropertyValues(AdditionalParameters, ThisObject);
	
	CreationParameters = PurchasesClient.ParametersForCreatingCCDNumber(CurrentData,
																Item.EditText,
																AdditionalParameters);
	
	PurchasesClient.OpenFormForCreatingGTDNumber(ThisObject, CreationParameters);
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersARAPDetails

&AtClient
Procedure ARAPDetailsOnStartEdit(Item, NewRow, Copy)
	TableRow = Items.ARAPDetails.CurrentData;
	If NewRow And Not Copy Then
		TableRow.Sum = Object.Goods.Total("AmountIncludingVAT")-Object.ARAPDetails.Total("Sum");
	EndIf;
EndProcedure

&AtClient
Procedure ARAPDetailsARAPObjectStartChoice(Item, ChoiceData, StandardProcessing)
	
	ARAPObject = PredefinedValue("Catalog.ARAPObjects.EmptyRef");
	CurrentData = Items.ARAPDetails.CurrentData;
	If CurrentData <> Undefined Then
		ARAPObject = CurrentData.ARAPObject;
	EndIf;
	
	ARAPAccountingClient.ARAPObjectStartChoice(ThisForm, Item, StandardProcessing,, ARAPObject);
	
EndProcedure

&AtClient
Procedure ARAPDetailsARAPObjectChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	StandardProcessing = False;
	
	TableRow = Items.ARAPDetails.CurrentData;	
	If TypeOf(ValueSelected) = Type("Structure") Then
		FillPropertyValues(TableRow, ValueSelected);
		Modified = True;
	EndIf; 
	
EndProcedure // Decryption of the payment of the object of the account of the processing of the selection()

&AtClient
Procedure ARAPDetailsSumOnChange(Item)
	Items.ARAPDetails.CurrentData.AmountARAP = 0;
EndProcedure

&AtClient
Procedure ARAPDetailsARAPCurrencyOnChange(Item)
	Items.ARAPDetails.CurrentData.AmountARAP = 0;
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
Procedure OpenInventoryKinds(Command)
	
	OptionsForEditingInventoryTypes = PutGoodsAndStockTypesInStorage();
	
	FinancesClient.OpenInventoryKinds(ThisObject, OptionsForEditingInventoryTypes);
	
EndProcedure

&AtClient
Procedure WriteDocument(Command)
	
	TMCommonUseClient.Write(ThisForm);
	
EndProcedure

&AtClient
Procedure FillInPricesOfSelectedRowsByPriceType(Command)
	
	ClearMessages();
	
	If EnterprisePricesFillingClient.ItIsNecessaryToFillInPricesByTypeOfPrices(Object, "Goods", NStr("vi = 'Hàng hóa';
																									|ru = 'Товары';
																									|en = 'Goods'; fa = 'کالاها';
																									|it = 'Merci';
																									|pl = 'Goods';
																									|tr = 'Ürünler'")) Then
		
		PriceSelectionOptions = EnterprisePricesFillingClient.NewFillOptionsSelectPriceType();
		PriceSelectionOptions.CallbackDescription = 
			New CallbackDescription("FillInPricesOfSelectedRowsByPriceTypeCompletion", ThisObject);
		PriceSelectionOptions.PriceIncludesVAT = Object.PriceIncludesVAT;
		PriceSelectionOptions.UseForIntercompanySales = True;
		EnterprisePricesFillingClient.ChooseTypeOfPrices(PriceSelectionOptions);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure FillInTheCostPrice(Command)
	
	If Items.Goods.CurrentData = Undefined Then
		MessageText = NStr("vi = 'Để thực hiện lệnh, bạn cần chọn các hàng của phần bảng.';
							|ru = 'Для выполнения команды требуется выбрать строки табличной части.';
							|en = 'Select rows in the table to execute the command.'; fa = 'Select rows in the table to execute the command.';
							|it = 'Per eseguire il comando, è necessario selezionare le righe della parte tabulare.';
							|pl = 'W celu wykonania polecenia należy wybrać wiersze części tabelarycznej.';
							|tr = 'Komutun yürütülmesi için, tablo bölümü satırlarının seçilmesi gerekir.'");
		ShowMessageBox(,MessageText);
		Return;
	EndIf;
	
	CurrentData = Items.Goods.CurrentData;
	
	FormParameters = New Structure;
	FormParameters.Insert("Organization", Object.CompanyRecipient);
	FormParameters.Insert("Date", Object.Date);
	FormParameters.Insert("CompanyRecipient", Object.Organization);
	FormParameters.Insert("Contract", Object.Contract);
	FormParameters.Insert("CostDefiningMethod", CurrentData.CostDefiningMethod);
	FormParameters.Insert("CostPriceKind", PredefinedValue("Catalog.TypesOfPrices.EmptyRef"));
	FormParameters.Insert("DateOfCostFillingByPriceType", Object.Date);
	FormParameters.Insert("NumberOfPackages", CurrentData.NumberOfPackages);
	FormParameters.Insert("DocumentTransfers_", CurrentData.DocumentTransfers_);
	FormParameters.Insert("Package", CurrentData.Package);
	FormParameters.Insert("TaxationType", Object.VATTaxation);
	FormParameters.Insert("DocumentTransfers_", CurrentData.DocumentTransfers_);
	FormParameters.Insert("Products", CurrentData.Products);
	FormParameters.Insert("Characteristic", CurrentData.Characteristic);
	FormParameters.Insert("VATRate", CurrentData.VATRate);
	FormParameters.Insert("DocumentCurrency", Object.Currency);
	FormParameters.Insert("Cost_", CurrentData.Cost_);
	FormParameters.Insert("CostExcludingVAT_", CurrentData.CostExcludingVAT_);
	FormParameters.Insert("CostLocal", CurrentData.CostLocal);
	FormParameters.Insert("CDCost", CurrentData.CDCost);
	FormParameters.Insert("TDCost", CurrentData.TDCost);
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("SelectedRows", Items.Goods.SelectedRows);
	OpenForm("Document.IntercompanyGoodsReturn.Form.SelectionFormOfCostDefiningMethod",
		FormParameters,
		ThisForm,,,,
		New CallbackDescription("ChoosingMethodForDeterminingCostOfProduction",
				ThisObject,
				AdditionalParameters),
		FormWindowOpeningMode.LockOwnerWindow);

EndProcedure

&AtClient
Procedure SelectionBasedOnTheBalanceOfMutualSettlements(Command)
	
	CheckParameters = ProcessingOfTabularFormsClient.FillVerificationParameters();
	CheckParameters.CheckedAttributes.Insert("Organization",           NStr("vi = 'Người gửi';
																			|ru = 'Отправитель';
																			|en = 'Sender'; fa = 'فرستنده';
																			|it = 'Mittente';
																			|pl = 'Sender';
																			|tr = 'Gönderen'"));
	CheckParameters.CheckedAttributes.Insert("Currency",                NStr("vi = 'Tiền tệ';
																			|ru = 'Валюта';
																			|en = 'Currency'; fa = 'ارز';
																			|it = 'Valuta';
																			|pl = 'Waluta';
																			|tr = 'Para birimi'"));
	CheckParameters.CheckedAttributes.Insert("BusinessOperation", NStr("vi = 'Giao dịch';
																		|ru = 'Операция';
																		|en = 'Transaction'; fa = 'تراکنش';
																		|it = 'Operazione';
																		|pl = 'Operacja';
																		|tr = 'İşlem'"));
	If Object.ARAPAccountingViaSeparateCounterparty Then
		CheckParameters.CheckedAttributes.Insert("Partner",    NStr("vi = 'Bạn hàng';
																	|ru = 'Партнер';
																	|en = 'Partner'; fa = 'شریک تجاری';
																	|it = 'Partner';
																	|pl = 'Partner';
																	|tr = 'İş ortağı'"));
		CheckParameters.CheckedAttributes.Insert("Counterparty", NStr("vi = 'Đối tác';
																		|ru = 'Контрагент';
																		|en = 'Counterparty'; fa = 'طرف حساب';
																		|it = 'Controparte';
																		|pl = 'Kontrahent';
																		|tr = 'Cari hesap'"));
	Else
		CheckParameters.CheckedAttributes.Insert("CompanyRecipient", NStr("vi = 'Người nhận';
																			|ru = 'Получатель';
																			|en = 'Recipient'; fa = 'گیرنده';
																			|it = 'Destinatario';
																			|pl = 'Recipient';
																			|tr = 'Alıcı'"));
	EndIf;
	Notification = New CallbackDescription("SelectionBasedOnTheBalanceOfMutualSettlementsCompletion", ThisObject);
	ProcessingOfTabularFormsClient.CheckIfItCanBeFilledIn(ThisForm, Notification, CheckParameters);
	
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
		
		StructureOfActions = New Structure;
		AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions, Object);
		
		BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
		
		FinancesClientServer.RecalculateAmountsInPaymentDecryptionLine(Object, Object.Goods.Total("AmountIncludingVAT"));
	Else
		EquipmentManagerTMClient.ReportError(ExecutionResult);
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
Procedure CheckQuantityInTheDocument(Command)
	
	OpeningParameters = New Structure;
	OpeningParameters.Insert("AddressInTempStorage",            PutTablePartOfGoodsInTemporaryStorageToCheckQuantity());
	OpeningParameters.Insert("TabularSectionName",                    "Goods");
	OpeningParameters.Insert("Ref",                               Object.Ref);
	OpeningParameters.Insert("GoodsQuantityExcessIsAllowed", True);
	OpeningParameters.Insert("SeriesSpecificationParameters",               SeriesSpecificationParameters);
	OpeningParameters.Insert("Warehouse",                                Object.Warehouse);
	
	ReturnParameters = Undefined;
	
	OpenForm("CommonForm.CheckDocumentPopulation",
				OpeningParameters,
				,
				,
				,
				,
				New CallbackDescription("CheckQuantityInTheDocumentCompletion", ThisObject),
				FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure CheckQuantityInTheDocumentCompletion(Result, AdditionalParameters) Export
	
	ReturnParameters = Result;
	
	If ReturnParameters <> Undefined Then
		Modified = True;
		
		ChangeTablePartBasedOnResultsOfCheck(ReturnParameters,
													?(CachedValues = Undefined,
														BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues(),
														CachedValues));
		
		FinancesClientServer.RecalculateAmountsInPaymentDecryptionLine(Object, Object.Goods.Total("AmountIncludingVAT"));
	EndIf;
	
EndProcedure

&AtClient
Procedure SearchByBarcode(Command)
	
	ClearMessages();
	Notification = New CallbackDescription("SearchByBarcodeCompletion", ThisObject);
	BarcodingOfItemsClient.ShowBarcodeInput(Notification);
	
EndProcedure

&AtClient
Procedure PostDocument(Command)
	
	TMCommonUseClient.Post(ThisForm);
	
EndProcedure

&AtClient
Procedure PostAndClose(Command)
	
	TMCommonUseClient.PostAndClose(ThisForm);
	
EndProcedure

&AtClient
Procedure SplitRow(Command)
	
	FormTable  = Items.Goods;
	TableData = Object.Goods;
	
	AdditionalParameters = AccountingForTraceableGoodsClientServerLocalization.CompleteDescriptionOfParametersForSplittingRowInTablePart(FormTable.CurrentData);
	
	Notification = New CallbackDescription("SplitRowCompletion", ThisObject, AdditionalParameters);
	ProcessingOfTabularFormsClient.SplitRow(TableData, FormTable, Notification);
	
EndProcedure

&AtClient
Procedure PrintDetails(Item)
	
	OpenPrintDetails(False);
	
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
Procedure AddGoodsFromTransferDocuments(Command)
	
	FormOpenParameters = New Structure;
	FormOpenParameters.Insert("DocumentReturnPolicy", Object.Ref);
	FormOpenParameters.Insert("Currency", Object.Currency);
	FormOpenParameters.Insert("Date", Object.Date);
	FormOpenParameters.Insert("PriceIncludesVAT", Object.PriceIncludesVAT);
	FormOpenParameters.Insert("Partner", Object.Organization);
	FormOpenParameters.Insert("Warehouse", Object.Warehouse);
	FormOpenParameters.Insert("Contract", Object.Contract);
	FormOpenParameters.Insert("Organization", Object.CompanyRecipient);
	FormOpenParameters.Insert("Counterparty", Undefined);
	FormOpenParameters.Insert("VATTaxation", Object.VATTaxation);
	FormOpenParameters.Insert("ReturnFromRetailCustomer", False);
	FormOpenParameters.Insert("ReturnFromCustodian", False);
	FormOpenParameters.Insert("ReturnBetweenCompanies", True);
	FormOpenParameters.Insert("CashRegisterReceipt", Undefined);
	FormOpenParameters.Insert("LineOfBusiness", Object.LineOfBusiness);
	FormOpenParameters.Insert("DepositForPackageIsRequired", False);
	FormOpenParameters.Insert("ShowContainers", False);
	FormOpenParameters.Insert("ShowProducts_", True);
	If Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.IntercompanyGoodsReturn") Then
		FormOpenParameters.Insert("BusinessOperation", PredefinedValue("Enum.BusinessTransactions.GoodsSaleToAnotherCompany"));
	Else
		FormOpenParameters.Insert("BusinessOperation", PredefinedValue("Enum.BusinessTransactions.TransferOfGoodsToCommissionAgentInAnotherCompany"));
	EndIf; 
	
	OpenForm("CommonForm.SelectGoodsBySalesAndTransfers", FormOpenParameters, ThisForm);
	
EndProcedure

&AtClient
Procedure FillInTheGTDPoNumbersForTheTransferDocuments(Command)
	
	ThereAreFilledInCCDNumbers = False;
	
	For Each Page1 In Object.Goods Do
		If ValueIsFilled(Page1.CCDNumber) Then
			ThereAreFilledInCCDNumbers = True;
			Break;
			
		EndIf;
	EndDo;
	
	If ThereAreFilledInCCDNumbers Then
		CallbackDescription = New CallbackDescription("ProcessAnswerToQuestionAboutFillingInCCDNumbers", ThisObject);
		QueryText = NStr("vi = 'Số TKHQ sẽ được xóa và điền lại. Tiếp tục?';
						|ru = 'Будут очищены и перезаполнены номера ГТД. Продолжить?';
						|en = 'CCD numbers will be cleared and refilled. Continue?'; fa = 'CCD numbers will be cleared and refilled. Continue?';
						|it = 'I numeri delle polizze doganali di carico verranno eliminati e reinseriti. Continuare?';
						|pl = 'Numery LP zostaną wyczyszczone i uzupełnione. Kontynuować?';
						|tr = 'GKB numarası silinecek ve yeniden doldurulacaktır. Devam edilsin mi?'");
		
		ShowQueryBox(CallbackDescription, QueryText, QuestionDialogMode.YesNo);
	Else
		FillInCCDNumbersAccordingToTransferDocumentsOnServer();
	EndIf;
	
EndProcedure

&AtClient
Procedure ProcessAnswerToQuestionAboutFillingInCCDNumbers(QuestionResult, AdditionalParameters) Export
	
	If QuestionResult = DialogReturnCode.Yes Then
		FillInCCDNumbersAccordingToTransferDocumentsOnServer();
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()
	
	ConditionalAppearance.Items.Clear();
	
	//
	VATAccountingERP.EstablishConditionalAppearanceOfVATAmountsForSalesTaxation(ThisObject);
	
	//
	EnterprisePricesFillingServer.SetConditionalAppearancePriceIncludesVAT(ThisObject);
	
	//
	ProductsServer.EstablishConditionalAppearanceOfProductCharacteristics(ThisObject);
	
	//
	ProductsServer.SetConditionalAppearanceOfUnitsOfMeasurement(ThisObject);
	
	//
	EnterprisePricesFillingServer.EstablishConditionalAppearanceOfPriceTypes(ThisObject);
	
	//
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsPrice.Name);
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsSum.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.PriceKind");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	Item.Appearance.SetParameterValue("ReadOnly", True);
	
	//
	ProductsServer.EstablishConditionalAppearanceOfProductSeries(ThisObject, "SeriesAlwaysWHGoods");
	LinesOfBusinessServer.EstablishConditionalAppearanceOfDirectionOfActivity(ThisObject);
	
	//
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsPrice.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.Price");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.ItemsType");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotEqual;
	ItemFilter.RightValue = Enums.ItemsTypes.ReusablePackage;
	
	Item.Appearance.SetParameterValue("MarkIncomplete", True);
	
	//
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsSum.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.Price");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.ItemsType");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotEqual;
	ItemFilter.RightValue = Enums.ItemsTypes.ReusablePackage;
	
	Item.Appearance.SetParameterValue("MarkIncomplete", True);
	
	//
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsAmountIncludingVAT.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.Price");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.ItemsType");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotEqual;
	ItemFilter.RightValue = Enums.ItemsTypes.ReusablePackage;
	
	Item.Appearance.SetParameterValue("MarkIncomplete", True);
	
	//
	ConditionalDesignParameters = ProductsServer.ParametersForSettingConditionalAppearanceOfCCDNumber();
	ConditionalDesignParameters.NameOfFieldForEnteringCCDNumber = "GoodsCCDNumberOriginCountry";
	
	ProductsServer.SetConditionalAppearanceOfCCDNumber(ThisObject);
	ProductsServer.SetConditionalAppearanceOfCCDNumber(ThisObject, ConditionalDesignParameters);
	
	AccountingForTraceableGoodsLocalization.SetConditionalAppearanceOfCCDNumber(ThisObject);
	
	//
	AccountingForTraceableGoodsLocalization.SetConditionalAppearanceOfQuantityAccordingToRNPT(ThisObject);
	
	//
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsDocumentTransfers_.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.CostDefiningMethod");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotEqual;
	ItemFilter.RightValue = Enums.WaysToCalculateReturnCost.FromTransferDocument;
	
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	Item.Appearance.SetParameterValue("TextColor", StyleColors.InaccessibleCellTextColor);
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<không cần điền>';
													|ru = '<заполнение не требуется>';
													|en = '<filling is not required>'; fa = '<filling is not required>';
													|it = '<non da compilare>';
													|pl = '<wypełnienie nie jest wymagane>';
													|tr = '<doldurma gerekli değil>'"));
	Item.Appearance.SetParameterValue("ReadOnly", True);
	
EndProcedure

#Region OnChangeAttributes

&AtServer
Procedure DateOnChangeServer()
	
	UseTraceableImportedGoodsAccounting = AccountingForTraceableGoodsLocalization.UseTraceableImportedGoodsAccounting(
														Object.Date);
	
	CompleteVATTaxation();
	ConfigureIntermediaryElements();
	UpdateInvoiceText();
	AccountingForTraceableGoodsLocalization.EstablishVisibilityOfRNPTQuantity(ThisForm, Object.Date);
	
	If Not Items.ProductsGroupQuantityByRNPT.Visible Then
		RecalculateNumberOfRNPT();
	EndIf;
	
	ResponsiblePersonsServer.WhenChangingRelatedDocumentDetails(Object);
	
	ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisForm, "Date");
	ExcisableGoodsAccounting.UpdateElementsOfAccountingForExcisableItems(ThisObject);
	
EndProcedure

&AtServer
Procedure CounterpartyOnChangeServer()
	SalesServer.PartnerOnChange(Object);
	ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisForm, "Counterparty");
	PurchasesServer.FillInSelectionListNameOfIncomingDocument(ThisObject, Object.Counterparty);
EndProcedure

&AtServer
Procedure CompanyRecipientOnChangeServer()
	
	CompleteVATTaxation();
	
	ParametersStructure = CashServer.ParametersForFillingOutOrganizationSBankAccount();
	ParametersStructure.Organization    = Object.CompanyRecipient;
	ParametersStructure.LineOfBusiness = Object.LineOfBusiness;
	
	Object.RecipientCompanyBankAccount =
		CashServer.GetOrganizationSDefaultBankAccount(ParametersStructure);
	
	FillInSubordinatePropertiesForStatistics("CompanyRecipient");
	
	Object.DeliveryAddress = PrintFormGeneration.GetAddressFromContactInformation(Object.CompanyRecipient,
		"Actual", CurrentSessionDate());
	
	ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisForm, "CompanyRecipient");
	
	ExcisableGoodsAccounting.UpdateElementsOfAccountingForExcisableItems(ThisObject);
	
EndProcedure

&AtServer
Procedure OrganizationOnChangeServer()
	
	LocalAccountingCurrency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Object.Organization);
	
	ParametersStructure = CashServer.ParametersForFillingOutOrganizationSBankAccount();
	ParametersStructure.Organization    			= Object.Organization;
	ParametersStructure.LineOfBusiness = Object.LineOfBusiness;
	
	Object.CompanyBankAccount =
		CashServer.GetOrganizationSDefaultBankAccount(ParametersStructure);
	
	FillInSubordinatePropertiesForStatistics("Organization");
	
	CompleteVATTaxation();
	
	UpdateInvoiceText();
	
	SetParametersForSelectingRecipientOrganization();
	CheckAndClearRecipientOrganization();
	SetContractSelectionParameters();
	
	ResponsiblePersonsServer.WhenChangingRelatedDocumentDetails(Object);
	EstablishCostPresentation();
	
	RecalculateNumberOfRNPT();
	
	ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisForm, "Organization");
	
EndProcedure

&AtServer
Procedure CurrencyOnChangeServer(CurrencyNew)
	
	CourseStructures = ARAPAccountingServer.ExchangeRatesForTranslation(ThisForm, DocumentCurrency, CurrencyNew, LocalAccountingCurrency, Object.Date);
	CoursesAreOld = CourseStructures.StructureOfOldCurrencyRates;
	CoursesAreNew  = CourseStructures.StructureOfNewCurrencyRates;
	
	PriceManagementSystem.ConvertTabularAmountsToCurrency(Object.Goods,Object.PriceIncludesVAT,DocumentCurrency,CurrencyNew,CoursesAreOld,CoursesAreNew);
	ARAPAccountingARAPDetailsFillingIn.ConvertAmountsToCurrencyPaymentDecryption(Object,Object.Goods.Total("AmountIncludingVAT"));
	CashServer.SetPaymentAmountHeader(Object.Currency,Items);
	
	FillInSubordinatePropertiesForStatistics("Currency");
	
	ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisForm, "Currency");
	
EndProcedure

&AtServer
Procedure VATTaxationOnChangeServer()
	
	ActionFillInVATRate = BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRate(Object);
	ActionFillInVATRate.Organization = Object.CompanyRecipient;
	If ValueIsFilled(Object.DocumentTransfers_) Then
		ActionFillInVATRate.Date = Common.ObjectAttributeValue(Object.DocumentTransfers_, "Date");
	EndIf;
	CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInVATRateByPriceType", BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRateByPriceType(Object));
	StructureOfActions.Insert("AdjustVATRate", ActionFillInVATRate);
	StructureOfActions.Insert("FillInMethodForDeterminingCost", Enums.WaysToCalculateReturnCost.FromCurrentDocument);
	StructureOfActions.Insert("FillInCostDeterminationMethodWithLine", CostDeterminationParameters(ThisObject));
	BatchProcessingOfTablePartServer.TreatTS(Object.Goods, StructureOfActions, CachedValues);
	
	ActionsVATRecalculation = BatchProcessingOfTablePartClientServer.ParametersForRecalculatingNDSWTCHAmount(Object);
	StructureOfActions = New Structure();
	StructureOfActions.Insert("RecalculateVATAmount", ActionsVATRecalculation);
	StructureOfActions.Insert("RecalculateAmountWithVAT", ActionsVATRecalculation);
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		CachedValues.ProcessedRows,
		StructureOfActions,
		Object.Goods,
		Undefined);
	
	UpdateInvoiceText();
	ConfigureFormTotals(ThisObject);
	
EndProcedure

&AtServer
Procedure PriceIncludesVATOnChangeServer(CachedValues)
	ActionsVATRecalculation = BatchProcessingOfTablePartClientServer.ParametersForRecalculatingNDSWTCHAmount(Object);
	Actions = New Structure;
	Actions.Insert("RecalculateVATAmount", ActionsVATRecalculation);
	Actions.Insert("RecalculateAmountWithVAT", ActionsVATRecalculation);
	BatchProcessingOfTablePartServer.TreatTS(Object.Goods, Actions, CachedValues);
EndProcedure

&AtServer
Procedure PartnerOnChangeServer()
	
	PartnersAndCounterparties.FillInPartnerSDefaultCounterparty(Object.Partner,Object.Counterparty);
	
	SalesServer.PartnerOnChange(Object);
	
	ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisForm, "Partner");
	
EndProcedure

&AtServer
Procedure BusinessOperationOnChangeServer()
	
	UpdateInvoiceText();
	
	FillInOtherFormDetails();
	ConfigureSettlementElements();
	SetContractSelectionParameters();
	ClearTransferDocuments();
	CompleteVATTaxation();
	
	ARAPAccountingFormWork.WhenChangingParametersOfMechanism(ThisForm);
	
EndProcedure

&AtServer
Procedure ClearTransferDocuments()
	
	Object.DocumentTransfers_ = Undefined;
	
	For Each LineProducts_ In Object.Goods Do
		LineProducts_.DocumentTransfers_ = Undefined;
	EndDo;
	
	TransferHeaderLabel = Undefined;
	
	SetVisibilityOfElementsInTransferDocuments();
	OrderOfReflection = OrderOfReflection(Object.RecordInProfitLossOfPreviousYears);
	Items.ReflectionInAccounting_.Title = TitleOfReflectionInAccounting(Object.RecordInProfitLossOfPreviousYears);
	
EndProcedure

&AtClientAtServerNoContext
Procedure AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions, Object)
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	
	StructureOfActions.Insert("RecalculateNumberOfUnits");
	StructureOfActions.Insert("RecalculateAmount");
	StructureOfActions.Insert("RecalculateVATAmount",	StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT",	StructureOfRecalculationOfAmount);
	
	AccountingForTraceableGoodsClientServerLocalization.AddDescriptionOfSettingsForRecalculatingDetailsOfTablePart(
		Object,
		StructureOfActions);
	
EndProcedure

&AtClient
Procedure WarehouseOnChange(Item)
	
	WhenChangingWarehouseServer();
	
EndProcedure

&AtServer
Procedure LineOfBusinessOnChangeServer()
	
	If ValueIsFilled(Object.LineOfBusiness) Then
		AttributesStructure1 = Common.ObjectAttributesValues(Object.LineOfBusiness, "IncomeAccounting, CostAccounting");
		If Not AttributesStructure1.IncomeAccounting Or Not AttributesStructure1.CostAccounting Then
			Object.LineOfBusiness = Catalogs.LinesOfBusiness.EmptyRef();
		EndIf;
	EndIf;
	
	CompleteVATTaxation();
	
EndProcedure

&AtClient
Procedure DecryptionOfThePaymentLineClick(Item, StandardProcessing)
	
	Notification = New CallbackDescription("DecryptionOfThePaymentLineClickCompletion", ThisObject);
	PlacePaymentDecryptionInTemporaryStorage();
	ARAPAccountingClient.ARAPAccountingOnReturnOfGoods(ThisForm, Items.DecryptionOfThePaymentLine, Notification);
	
EndProcedure

&AtServer
Procedure PlacePaymentDecryptionInTemporaryStorage()
	ARAPAccountingFormWork.PlacePaymentDecryptionInTemporaryStorage(ThisForm, "ARAPDetails");
EndProcedure

&AtClient
Procedure DecryptionOfThePaymentLineClickCompletion(Result, AdditionalParameters) Export
	
	If Result <> Undefined Then
		Modified = True;
		GetPaymentDecryptionFromVault(Result);
	EndIf;
	
EndProcedure

&AtServer
Procedure GetPaymentDecryptionFromVault(AddressOfPaymentsInTheStorage)
	Object.ARAPDetails.Load(GetFromTempStorage(AddressOfPaymentsInTheStorage));
EndProcedure

#EndRegion

#Region SelectionAndProcessingOfQuantityVerification

&AtServer
Function PutGoodsAndStockTypesInStorage()
	
	OptionsForEditingInventoryTypes = InventoriesServer.OptionsForEditingInventoryTypes();
	If Documents.IntercompanyGoodsReturn.ExcisableGoodsAreUsed(Object) Then
		OptionsForEditingInventoryTypes.DisplayExciseTaxAmount = True;
		OptionsForEditingInventoryTypes.UseExcisableGoods = True;
	EndIf;
	OptionsForEditingInventoryTypes.Insert("CompanyRecipient", Object.CompanyRecipient);
	OptionsForEditingInventoryTypes.Insert("DisplayInventoryOwnerAttributeOfRecipient", True);
	
	Return InventoriesServer.PutGoodsAndStockTypesInStorage(ThisObject, OptionsForEditingInventoryTypes);
	
EndFunction 

&AtServer
Procedure GetProductsFromStorage(AddressInStorage)
	
	Object.Goods.Load(GetFromTempStorage(AddressInStorage));
	
	SetVisibilityOfElementsInTransferDocuments();
	OrderOfReflection = OrderOfReflection(Object.RecordInProfitLossOfPreviousYears);
	Items.ReflectionInAccounting_.Title = TitleOfReflectionInAccounting(Object.RecordInProfitLossOfPreviousYears);
	
	ActionFillInVATRate = BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRate(Object);
	ActionFillInVATRate.Organization = Object.CompanyRecipient;
	If ValueIsFilled(Object.DocumentTransfers_) Then
		ActionFillInVATRate.Date = Common.ObjectAttributeValue(Object.DocumentTransfers_, "Date");
	EndIf;
	CachedValues = Undefined;
	Actions = New Structure("FillInVATRate", ActionFillInVATRate);
	Actions.Insert("FillInVATRateByPriceType", BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRateByPriceType(Object));
	
	BatchProcessingOfTablePartServer.TreatTS(Object.Goods, Actions, CachedValues);
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	
	FillParameters = New Structure();
	FillParameters.Insert("Date", Object.Date);
	FillParameters.Insert("Organization", Object.Organization);
	FillParameters.Insert("Currency", Object.Currency);
	FillParameters.Insert("PriceKind", Object.PriceKind);
	FillParameters.Insert("PopulationFields", "Price, PriceKind");
	
	StructureOfActions = New Structure();
	StructureOfActions.Insert("RecalculateAmount", "NumberOfPackages");
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	
	EnterprisePricesFillingServer.FillInPrices(Object.Goods, , FillParameters, StructureOfActions);
	
	StructureOfActions = New Structure();
	StructureOfActions.Insert("FillInMethodForDeterminingCost", Enums.WaysToCalculateReturnCost.FromCurrentDocument);
	StructureOfActions.Insert("FillInCostDeterminationMethodWithLine", CostDeterminationParameters(ThisObject));
	
	BatchProcessingOfTablePartServer.TreatTS(Object.Goods, StructureOfActions, CachedValues);
	
	FillInAdditionalProductAttributes();
	ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);
	PurchasesServer.FillInServiceAttributesOfCCDNumber(Object.Goods);
	ItIsRequiredToUpdateTitleIsSubjectToExciseDuty = UseExcisableGoods;
EndProcedure // Get Storage items()

&AtServer
Procedure GetStockTypesFromStorage(ValueSelected)
	
	InventoriesServer.ProcessInputOfInventoryTypesManually(ValueSelected, ThisForm);
	
EndProcedure

&AtServer
Function PutTablePartOfGoodsInTemporaryStorageToCheckQuantity()
	
	TabularPartProducts = Object.Goods.Unload(,"Products, Characteristic, Series, BatchesIndicationStatus, ItemsType, ItemVariantsAreUsed, Package, NumberOfPackages");
	TabularPartProducts.GroupBy("Products, Characteristic, Series, BatchesIndicationStatus, ItemsType, ItemVariantsAreUsed, Package", "NumberOfPackages");
	AddressInTempStorage = PutToTempStorage(TabularPartProducts, UUID);
	Return AddressInTempStorage;
	
EndFunction

&AtServer
Procedure ChangeTablePartBasedOnResultsOfCheck(ReturnParameters, CachedValues)
	
	GoodsTable = GetFromTempStorage(ReturnParameters.Goods);

	RowsToProcess = New Array;
	ProcessedLinesAreNew = New Array;	
	LinesToDelete = New Array;
	For Each SourceRow In GoodsTable Do
		
		Filter = New Structure("Products, Characteristic, Series, BatchesIndicationStatus, Package");
		FillPropertyValues(Filter, SourceRow);
		FoundRows = Object.Goods.FindRows(Filter);
		
		For Each TSRow In FoundRows Do
			
			If SourceRow.NumberOfPackages = 0 Then
				Break;
			EndIf;
			
			If TSRow.NumberOfPackages = 0
				And SourceRow.NumberOfPackages < 0 Then
				
				Continue;
				
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
			
			If TSRow.NumberOfPackages > 0 Then
				RowsToProcess.Add(TSRow);
			EndIf;
			
		EndDo;
		
		If FoundRows.Count() = 0 Then
			
			TSRow = Object.Goods.Add();
			FillPropertyValues(TSRow, SourceRow);
			
			ProcessedLinesAreNew.Add(TSRow);
			
		EndIf;
		
	EndDo;
	
	ActionFillInVATRate = BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRate(Object);
	ActionFillInVATRate.Organization = Object.CompanyRecipient;
	If ValueIsFilled(Object.DocumentTransfers_) Then
		ActionFillInVATRate.Date = Common.ObjectAttributeValue(Object.DocumentTransfers_, "Date");
	EndIf;
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));
	StructureOfActions.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
	AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions, Object);
	
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		RowsToProcess,
		StructureOfActions,
		Object.Goods,
		CachedValues);

	ActionFillInVATRate = BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRate(Object); 
	If ValueIsFilled(Object.DocumentTransfers_) Then
		ActionFillInVATRate.Date = Common.ObjectAttributeValue(Object.DocumentTransfers_, "Date");
	EndIf;
	StructureOfActions.Insert("FillInVATRate", ActionFillInVATRate);
	StructureOfActions.Insert("FillInVATRateByPriceType", BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRateByPriceType(Object));
	StructureOfActions.Insert("FillInSalePrice", BatchProcessingOfTablePartClientServer.ParametersForFillingInPriceInTSLine(Object));
	StructureOfActions.Insert("FillInFeatureAttribute", New Structure("Products", "ItemVariantsAreUsed"));
	StructureOfActions.Insert("FillInCCDTrackingAttribute", New Structure("Products", "TheRecordsAreKeptByCCD"));
	BatchProcessingOfTablePartClientServerLocalization.CompleteActionStructureWhenChangingElement(
		ThisObject, "Products", StructureOfActions);
	AccountingForTraceableGoodsClientServerLocalization.CompleteDescriptionOfSettingsForFillingInServiceDetailsOfTablePart(StructureOfActions);

	BatchProcessingOfTablePartServer.ProcessTSStrings(
		ProcessedLinesAreNew,
		StructureOfActions,
		Object.Goods,
		CachedValues);

	FilterCriterion = New Structure("NumberOfPackages", 0);
	FoundRows = Object.Goods.FindRows(FilterCriterion);
	
	For Each TSRow In FoundRows Do
		LinesToDelete.Add(TSRow);
	EndDo;
	
	For Each TSRow In LinesToDelete Do
		Object.Goods.Delete(TSRow);
	EndDo;
	
	ProductsServer.FillInStatusesForSpecifyingSeries(Object,SeriesSpecificationParameters);
	PurchasesServer.FillInServiceAttributesOfCCDNumber(Object.Goods);
	FormEvents.WhenChangingElement(ThisObject, "Goods");
	ItIsRequiredToUpdateTitleIsSubjectToExciseDuty = UseExcisableGoods;
EndProcedure

#EndRegion

#Region BarcodesAndTradeEquipment

&AtClient
Procedure ProcessBarcodes(BarcodeData_5)
	
	ClearMessages();
	
	If Not BarcodingOfItemsClient.BarcodesAreValid(BarcodeData_5) Then
		Return;
	EndIf;
	
	ActionFillInVATRate = BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRate(Object);
	ActionFillInVATRate.Organization = Object.CompanyRecipient;
	If ValueIsFilled(Object.DocumentTransfers_) Then
		ActionFillInVATRate.ByCorrectionDate = True;
		ActionFillInVATRate.CorrectedDocument = Object.DocumentTransfers_;
	EndIf;
	StructureOfActionsWithAddedStrings = New Structure;
	StructureOfActionsWithAddedStrings.Insert("FillInVATRate",   ActionFillInVATRate);
	StructureOfActionsWithAddedStrings.Insert("FillInVATRateByPriceType", BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRateByPriceType(Object));
	StructureOfActionsWithAddedStrings.Insert("FillInSalePrice", BatchProcessingOfTablePartClientServer.ParametersForFillingInPriceInTSLine(Object));
	StructureOfActionsWithAddedStrings.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));
	StructureOfActionsWithAddedStrings.Insert("FillInCCDTrackingAttribute", New Structure("Products", "TheRecordsAreKeptByCCD"));
	StructureOfActionsWithAddedStrings.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
	StructureOfActionsWithAddedStrings.Insert("CheckSeriesCalculateStatus", New Structure("Warehouse, SeriesSpecificationParameters", Object.Warehouse, SeriesSpecificationParameters));
	AddActionsToStructureWhenChangingPackagesNumber(StructureOfActionsWithAddedStrings,Object);	
	StructureOfActionsWithAddedStrings.Insert("FillInMethodForDeterminingCost", 
		PredefinedValue("Enum.WaysToCalculateReturnCost.FromCurrentDocument"));
	BatchProcessingOfTablePartClientServerLocalization.CompleteActionStructureWhenChangingElement(
		ThisObject, "Products", StructureOfActionsWithAddedStrings);
	StructureOfActionsWithAddedStrings.Insert("FillInCostDeterminationMethodWithLine", CostDeterminationParameters(ThisObject));

	StructureOfActionsWithModifiedStrings = New Structure;
	AddActionsToStructureWhenChangingPackagesNumber(StructureOfActionsWithModifiedStrings,Object);	
	AccountingForTraceableGoodsClientServerLocalization.CompleteDescriptionOfSettingsForFillingInServiceDetailsOfTablePart(StructureOfActionsWithAddedStrings);	
	
	StructureOfActions = BarcodingOfItemsClient.BarcodeProcessingParameters();
	StructureOfActions.Barcodes                              = BarcodeData_5;
	StructureOfActions.StructureOfActionsWithAddedStrings = StructureOfActionsWithAddedStrings;
	StructureOfActions.StructureOfActionsWithModifiedStrings  = StructureOfActionsWithModifiedStrings;
	StructureOfActions.SeriesSpecificationParameters                 = SeriesSpecificationParameters;
	StructureOfActions.GoodsOnly                           = True;
	
	ProcessBarcodesServer(StructureOfActions, CachedValues);
	
	BarcodingOfItemsClient.ProcessUnknownBarcodes(StructureOfActions, CachedValues, ThisObject);
	
	FinancesClientServer.RecalculateAmountsInPaymentDecryptionLine(Object, Object.Goods.Total("AmountIncludingVAT"));
	
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
	
	BarcodingOfItemsServer.ProcessBarcodes(ThisObject, Object, StructureOfActionParameters, CachedValues);
	PurchasesServer.FillInServiceAttributesOfCCDNumber(Object.Goods);
	FormEvents.WhenChangingElement(ThisObject, "Goods");
	ItIsRequiredToUpdateTitleIsSubjectToExciseDuty = UseExcisableGoods;
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
	If ProductsClient.YouNeedServerCallToSpecifySeries(ThisForm,SeriesSpecificationParameters,Text, CurrentData)Then
		ExceptionText = NStr("vi = 'Lỗi khi thử chỉ ra sê-ri - để chỉ ra sê-ri trong chứng từ này, không cần gọi ra Server.';
							|ru = 'Ошибка при попытке указать серии - в этом документе для указания серий не нужен серверный вызов.';
							|en = 'An error occurred when attempting to specify batch. No server call is required to specify batch in this document.'; fa = 'An error occurred when attempting to specify batch. No server call is required to specify batch in this document.';
							|it = 'Si è verificato un errore durante il tentativo di indicare le serie - in questo documento non è necessaria la chiamata al server per indicare le serie.';
							|pl = 'Błąd podczas próby określenia serii - w tym dokumencie nie jest wymagane wywołanie serwera, aby wskazać serię.';
							|tr = 'Bir parti belirtmeye çalışırken hata oluştu - bu belgede bir parti belirtmek için sunucu çağrısı gerekmez.'");
		Raise ExceptionText;
	EndIf;
EndProcedure

#EndRegion

#Region CCDNumbers

&AtClient
Procedure ProcessSelectionOfCCDNumber(CalculationResult1)
	
	CurrentData = Items.Goods.CurrentData;
	
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	RowID = CurrentData.GetID();
	
	If RowID = Undefined Then
		Return;
	EndIf;
	
	CCDNumbersFilledIn = False;
	CCDNumber = Undefined;
	
	ProcessIndicationOfCCDNumberServer(RowID, CalculationResult1, CCDNumbersFilledIn, CCDNumber);
	
	PurchasesClient.NotifyAboutFillingInGTNumbersInTabularPart(CCDNumbersFilledIn, CCDNumber);
	
EndProcedure

&AtServer
Procedure ProcessIndicationOfCCDNumberServer(RowID,
											CalculationResult1,
											CCDNumbersFilledIn,
											CCDNumber)
	
	SelectionData_1	= GetFromTempStorage(CalculationResult1.AddressInTempStorage);
	CCDNumber		= ?(SelectionData_1.ResidualNumberOfCCD <> Undefined,
						CCDNumber,
						SelectionData_1.MainNumberOfCCD);
	
	ProcessingActions = New Structure;
	
	If SelectionData_1.ResidualNumberOfCCD <> Undefined Then
		AddActionsToStructureWhenChangingPackagesNumber(ProcessingActions, ThisObject);
	Else
		AccountingForTraceableGoodsClientServerLocalization.AddDescriptionOfSettingsForRecalculatingDetailsOfTablePart(
			Object,
			ProcessingActions);
	EndIf;
	
	PurchasesServer.ProcessIndicationOfCCDNumber(ThisObject,
												RowID,
												SelectionData_1,
												CCDNumbersFilledIn,
												Undefined,
												ProcessingActions);
	
EndProcedure

&AtServer
Procedure FillInCCDNumbersAccordingToTransferDocumentsOnServer()
	
	FillParameters = PurchasesServer.ParametersForFillingInCCDNumbersBasedOnCredentials();
	QueryOptions = FillParameters.QueryOptions;
	QueryOptions.Ref = Object.Ref;
	
	ParametersForRecalculatingAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	
	ActionsWithString = New Structure;
	ActionsWithString.Insert("RecalculateAmount");
	ActionsWithString.Insert("RecalculateVATAmount",  ParametersForRecalculatingAmount);
	ActionsWithString.Insert("RecalculateAmountWithVAT", ParametersForRecalculatingAmount);
	
	AccountingForTraceableGoodsClientServerLocalization.AddDescriptionOfSettingsForRecalculatingDetailsOfTablePart(
		Object,
		ActionsWithString);
	
	FillParameters.ActionsWithString	= ActionsWithString;
	FillParameters.NameOfOrderField	= "DocumentTransfers_";
	
	PurchasesServer.FillInCCDNumbersAccordingToCredentials(Object.Goods, "ByReferences", FillParameters);
	
EndProcedure

#EndRegion

#Region WorkingWithCounterparties
&AtClient
Procedure CheckCounterparties(Command)
	
	
EndProcedure

#EndRegion

#Region Goods

&AtServer
Procedure GoodsAtEndOfEditingOnServer(UpdateGoods)
	
	UpdateInformationOnTransfers();
	If UpdateGoods Then
		FormEvents.WhenChangingElement(ThisObject, "Goods");
	EndIf;
	
EndProcedure

&AtServer
Procedure ProductsAfterDeletionOnServer()
	
	FormEvents.WhenChangingElement(ThisObject, "Goods");
	ItIsRequiredToUpdateTitleIsSubjectToExciseDuty = UseExcisableGoods;
	SetVisibilityOfElementsInTransferDocuments();
	OrderOfReflection = OrderOfReflection(Object.RecordInProfitLossOfPreviousYears);
	Items.ReflectionInAccounting_.Title = TitleOfReflectionInAccounting(Object.RecordInProfitLossOfPreviousYears);
	
EndProcedure

#EndRegion

#Region Other

&AtServer
Procedure OnReadCreateAtServer(CurrentObject)
	
	UsePartnersAsCounterparties = GetFunctionalOption("UsePartnersAsCounterparties");
	ManagementAccountingCurrency = Constants.ManagementAccountingCurrency.Get();
	LocalAccountingCurrency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Object.Organization);
	UseLocal = GetFunctionalOption("UseLocal");
	UseTraceableImportedGoodsAccounting = AccountingForTraceableGoodsLocalization.UseTraceableImportedGoodsAccounting(
														Object.Date);
	
	DocumentCurrency = Object.Currency;
	FillInOtherFormDetails();
	FillInAdditionalProductAttributes();
	ConfigureIntermediaryElements();
	ConfigureSettlementElements();
	SetParametersForSelectingRecipientOrganization();
	SetContractSelectionParameters();
	EstablishCostPresentation();
	
	UseLinesOfBusiness = GetFunctionalOption("UseIncomeAccountingByLinesOfBusiness")
											Or GetFunctionalOption("UseCostAccountingByLinesOfBusiness");
	
	RestrictGoodsReceiptWithoutCCDNumbers = GetFunctionalOption("RestrictGoodsReceiptWithoutCCDNumbers");
	
	CheckAndClearRecipientOrganization();
	UpdateInvoiceText();
	ConfigureFormTotals(ThisObject);
	SetFormFunctionalOptionParameters(New Structure("Warehouse", Object.Warehouse));
	
	SetVisibilityOfElementsInTransferDocuments();
	OrderOfReflection = OrderOfReflection(Object.RecordInProfitLossOfPreviousYears);
	Items.ReflectionInAccounting_.Title = TitleOfReflectionInAccounting(Object.RecordInProfitLossOfPreviousYears);
	
	SeriesSpecificationParameters = New FixedStructure(ProductsServer.SeriesSpecificationParameters(Object,
																									Documents.IntercompanyGoodsReturn));
	
	FillParameters = Documents.IntercompanyGoodsReturn.ParametersForFillingInVATTaxation_(Object);
	VATAccountingERP.FillInSalesVATTaxSelectionList(Items.VATTaxation,
															Object.VATTaxation,
															FillParameters,
															VATAccountingCachedParameterValues);
	
	PurchasesServer.FillInServiceAttributesOfCCDNumber(Object.Goods);
	ProductsServer.FillInStatusesForSpecifyingSeries(Object,SeriesSpecificationParameters);
	ToUpdateData = Not ValueIsFilled(Object.Ref);
	UpdateInformationOnTransfers(ToUpdateData);
	PurchasesServer.FillInSelectionListNameOfIncomingDocument(ThisObject, Object.Counterparty);
	ProcessingOfTabularForms.InitializeRowCache(Items.Goods);
	
EndProcedure

&AtServer
Procedure ConfigureIntermediaryElements()
	
	Items.Partner.Visible = Object.ARAPAccountingViaSeparateCounterparty;
	Items.Counterparty.Visible = Object.ARAPAccountingViaSeparateCounterparty;
	Items.SalesContract.Visible = Object.ARAPAccountingViaSeparateCounterparty;
	Items.PurchasingContract.Visible = Object.ARAPAccountingViaSeparateCounterparty;
	Items.Contract.Visible = Not Object.ARAPAccountingViaSeparateCounterparty;
	Items.IncomingDocumentNumber.Visible = Object.ARAPAccountingViaSeparateCounterparty;
	Items.IncomingDocumentDate.Visible = Object.ARAPAccountingViaSeparateCounterparty;
	Items.DocumentsGroup.Visible = Object.ARAPAccountingViaSeparateCounterparty;
	
	If Object.ARAPAccountingViaSeparateCounterparty Then
		Object.Contract = Undefined;
	Else
		Object.SalesContract = Undefined;
		Object.PurchasingContract = Undefined;
	EndIf;
	
	Items.MutualPaymentsPage.Visible = Not Object.ARAPAccountingViaSeparateCounterparty;
	
EndProcedure

&AtServer
Procedure ConfigureSettlementElements()
	Items.ARAPDetails.ReadOnly = Not ThisIsSale And ThisIsACommission;
	Items.ARAPDetailsSelectionByStock.Enabled = ThisIsSale And Not ThisIsACommission;
	Items.MutualPaymentsPage.Visible = ThisIsSale And Not ThisIsACommission;
EndProcedure

&AtClientAtServerNoContext
Procedure ConfigureFormTotals(Form)
	
	If Not VATAccountingERPClientServer.DisplayNDSInResultsOfSalesDocument(Form.Object.VATTaxation) Then
		Form.Items.VATPageGroup.CurrentPage   = Form.Items.PageExcludingVAT;
		Form.Items.PagesTotalGroup.CurrentPage = Form.Items.PageTotalWithoutVAT;
	Else
		Form.Items.VATPageGroup.CurrentPage   = Form.Items.PageVAT;
		Form.Items.PagesTotalGroup.CurrentPage = Form.Items.TotalSNDSPage;
	EndIf;
	
EndProcedure

&AtServer
Procedure FillInOtherFormDetails()
	ThisIsACommission = (Object.BusinessOperation = Enums.BusinessTransactions.IntercompanyCommissionReturn);
	ThisIsSale = (Object.BusinessOperation = Enums.BusinessTransactions.IntercompanyGoodsReturn);
EndProcedure

&AtServer
Procedure FillInAdditionalProductAttributes()
	
	ParametersForFillingInBankingDetails = New Structure;
	ParametersForFillingInBankingDetails.Insert("FillInFeatureAttribute", New Structure("Products", "ItemVariantsAreUsed"));
	ParametersForFillingInBankingDetails.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
	ParametersForFillingInBankingDetails.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));
	ParametersForFillingInBankingDetails.Insert("FillInCCDTrackingAttribute", New Structure("Products", "TheRecordsAreKeptByCCD"));
	
	BatchProcessingOfTablePartClientServerLocalization.CompleteActionStructureWhenChangingElement(
		ThisObject, "Products", ParametersForFillingInBankingDetails);
	AccountingForTraceableGoodsClientServerLocalization.CompleteDescriptionOfSettingsForFillingInServiceDetailsOfTablePart(ParametersForFillingInBankingDetails);
	
	ProductsServer.FillInServiceDetailsForProductInCollection(Object.Goods, ParametersForFillingInBankingDetails);
	
EndProcedure

&AtServer
Function FillInPricesByPriceKindServer(TypeOfFillingPrices, Val SelectedRows = Undefined)
	
	RowsArray = Undefined;
	
	If ValueIsFilled(SelectedRows) Then
		
		RowsArray = New Array;
		For Each String In SelectedRows Do
			TSRow = Object.Goods.FindByID(String);
			If TSRow <> Undefined Then
				RowsArray.Add(TSRow);
			EndIf;
		EndDo;
		If RowsArray.Count() = 0 Then
			RowsArray = Undefined;
		EndIf;
		
	EndIf;
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	
	FillParameters = New Structure();
	FillParameters.Insert("Date", Object.Date);
	FillParameters.Insert("Organization", Object.Organization);
	FillParameters.Insert("Currency", Object.Currency);
	FillParameters.Insert("PriceKind", TypeOfFillingPrices);
	FillParameters.Insert("PopulationFields", "Price, PriceKind");
	
	StructureOfActions = New Structure();
	StructureOfActions.Insert("RecalculateAmount", "NumberOfPackages");
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("FillInVATRateByPriceType", BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRateByPriceType(Object));
	
	PricesCalculated = EnterprisePricesFillingServer.FillInPrices(Object.Goods, RowsArray, FillParameters, StructureOfActions);
	
	Return PricesCalculated;
EndFunction

&AtServer
Procedure SetParametersForSelectingRecipientOrganization()
	
	ParametersArray = New Array;
	
	If ValueIsFilled(Object.Organization) Then
	
		ParametersArray.Add(New ChoiceParameter("Filter.LocalAccountingCurrency",
				SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Object.Organization)));
		ParametersArray.Add(New ChoiceParameter("Filter.RegistrationCountry",
				Common.ObjectAttributeValue(Object.Organization, "RegistrationCountry")));
	
		If GetFunctionalOption("UseBranchOfficesWithSeparateBalanceSheets") Then
			ParametersArray.Add(New ChoiceParameter("ModeForSelectingRelatedOrganizations", "JustNotInterconnected"));
		EndIf;
		
	EndIf;
	
	Items.CompanyRecipient.ChoiceParameters = New FixedArray(ParametersArray);
	
EndProcedure

&AtServer
Procedure CheckAndClearRecipientOrganization()
	
	If ValueIsFilled(Object.Organization)
		And ValueIsFilled(Object.CompanyRecipient) Then
			
			CheckStructure = Catalogs.Companies.CountriesOfRegistrationAndCurrenciesOfRegulatedAccountingCoincide(Object.Organization, Object.CompanyRecipient);
			If (GetFunctionalOption("UseBranchOfficesWithSeparateBalanceSheets")
				And Catalogs.Companies.OrganizationsAreInterconnectedByOrganizationalStructure(Object.Organization, Object.CompanyRecipient))
				Or (Not CheckStructure.CurrenciesDoNotMatch Or Not CheckStructure.CountriesMatch) Then
					Object.CompanyRecipient = Undefined;
			EndIf;
	EndIf;
	
EndProcedure

&AtServer
Function AddressOfObjectInTemporaryStorage()
	
	ObjectStructure = New Structure;
	
	For Each Attribute In Metadata.Documents.IntercompanyGoodsReturn.Attributes Do
		
		ObjectStructure.Insert(Attribute.Name);
		
	EndDo;
	FillPropertyValues(ObjectStructure, Object);
	
	Return PutToTempStorage(ObjectStructure, UUID);
	
EndFunction

&AtClient
Procedure OpenPrintDetails(ShowTTNDetails)
	
	Try
		LockFormDataForEdit();
	Except
		ShowMessageBox(Undefined, BriefErrorDescription(ErrorInfo()));
		Return;
	EndTry;
	
	ParametersStructure = New Structure();
	ParametersStructure.Insert("DeliveryAddress",                       Object.DeliveryAddress);
	ParametersStructure.Insert("ShipperBankAccount",      Object.ShipperBankAccount);
	ParametersStructure.Insert("GoodsRecipientBankAccount",       Object.GoodsRecipientBankAccount);
	ParametersStructure.Insert("CounterpartyBankAccount",           Object.CounterpartyBankAccount);
	ParametersStructure.Insert("Shipper",                    Object.Shipper);
	ParametersStructure.Insert("GoodsRecipient",                     Object.GoodsRecipient);
	ParametersStructure.Insert("LetterOfAuthorityIssuedBy",                  Object.LetterOfAuthorityIssuedBy);
	ParametersStructure.Insert("PowerOfAttorneyDate",                    Object.PowerOfAttorneyDate);
	ParametersStructure.Insert("PowerOfAttorneyPerson",                    Object.PowerOfAttorneyPerson);
	ParametersStructure.Insert("PowerOfAttorneyNumber",                   Object.PowerOfAttorneyNumber);
	ParametersStructure.Insert("Partner",                             Object.Partner);
	ParametersStructure.Insert("BusinessOperation",               Object.BusinessOperation);
	ParametersStructure.Insert("CompanyRecipient",               Object.CompanyRecipient);
	ParametersStructure.Insert("RecipientCompanyBankAccount", Object.RecipientCompanyBankAccount);
	ParametersStructure.Insert("Counterparty",                          Object.Counterparty);
	ParametersStructure.Insert("ReadOnly",                      ReadOnly);
	ParametersStructure.Insert("ShowTTNDetails",              ShowTTNDetails);
	ParametersStructure.Insert("ObjectType",                          "IntercompanyGoodsReturn");
	ParametersStructure.Insert("AddressOfObjectInTemporaryStorage",    AddressOfObjectInTemporaryStorage());
	ParametersStructure.Insert("PaymentsThroughTheOrganization",             Not Object.ARAPAccountingViaSeparateCounterparty);
	ParametersStructure.Insert("Organization",                         Object.Organization);
	ParametersStructure.Insert("Date",                                Object.Date);
	ParametersStructure.Insert("Director",                        Object.Director);
	ParametersStructure.Insert("ChiefAccountant",                    Object.ChiefAccountant);
	ParametersStructure.Insert("CompanyBankAccount",           Object.CompanyBankAccount);
	ParametersStructure.Insert("IssuiedBy",                            Object.IssuiedBy);
	ParametersStructure.Insert("IssuiedByJobTitle",                   Object.IssuiedByJobTitle);
	ParametersStructure.Insert("Basis",                           Object.Basis);
	ParametersStructure.Insert("ReferenceDocumentDateForPrintForms",                       Object.ReferenceDocumentDateForPrintForms);
	ParametersStructure.Insert("BaseDocumentNumber",                      Object.BaseDocumentNumber);
	
	OpenForm("CommonForm.PrintingDetailsOfSales", ParametersStructure, ThisForm,,,, Undefined, FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtServer
Procedure WhenChangingWarehouseServer()
	
	CompleteVATTaxation();
	
	StructureOfResponsible = SalesServer.GetWarehouseManager(Object.Warehouse);
	If StructureOfResponsible <> Undefined Then
		Object.IssuiedBy = StructureOfResponsible.EmployeeResponsible;
		Object.IssuiedByJobTitle = StructureOfResponsible.ResponsiblePosition;
	EndIf;
	
	SetFormFunctionalOptionParameters(New Structure("Warehouse", Object.Warehouse));
	SeriesSpecificationParameters = New FixedStructure(ProductsServer.SeriesSpecificationParameters(Object,
																									Documents.IntercompanyGoodsReturn));
	
	ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);
	
	RecalculateNumberOfRNPT();
	
EndProcedure

&AtServerNoContext
Function ParametersForRegisteringInvoicesReceivedServer(Val Object)
	
	Return Documents.IntercompanyGoodsReturn.ParametersForRegisteringInvoicesReceived(Object);
	
EndFunction	

&AtServerNoContext
Function ParametersForRegisteringInvoicesIssuedServer(Val Object)
	
	Return Documents.IntercompanyGoodsReturn.ParametersForRegisteringInvoicesIssued(Object);
	
EndFunction

&AtServer
Procedure UpdateInvoiceText()
	
	RegistrationParameters = ParametersForRegisteringInvoicesIssuedServer(Object);
	InvoicesIssuedOnBasisOf = VATAccountingERP.InvoicesIssuedOnBasisOf(RegistrationParameters);
	RegistrationParameters = ParametersForRegisteringInvoicesReceivedServer(Object);
	InvoicesReceivedOnBasisOf = VATAccountingERP.InvoicesReceivedOnBasisOf(RegistrationParameters);
	
	TextInvoice = InvoicesIssuedOnBasisOf.Presentation;
	TextIntermediaryInvoice = InvoicesReceivedOnBasisOf.Presentation;
	
	Items.GroupIssuedTaxInvoice.Visible =
		Not InvoicesIssuedOnBasisOf.Invoices_.Count() = 0
		Or Not Object.ARAPAccountingViaSeparateCounterparty;
	Items.IntermediaryInvoicePageGroup.Visible =
		Not InvoicesReceivedOnBasisOf.Invoices_.Count() = 0;
	Items.CustomerVATExempt.Visible =
		InvoicesIssuedOnBasisOf.Invoices_.Count() = 0
		And InvoicesReceivedOnBasisOf.Invoices_.Count() = 0
		And Not Object.BusinessOperation = Enums.BusinessTransactions.IntercompanyCommissionReturn
		And Not Object.ARAPAccountingViaSeparateCounterparty;
	
EndProcedure

&AtServer
Procedure SetContractSelectionParameters()
	
	ParametersArray = New Array;
	ParametersArray.Add(New ChoiceParameter("Filter.Organization", Object.Organization));
	ParametersArray.Add(New ChoiceParameter("Filter.CompanyRecipient", Object.CompanyRecipient));
	ParametersArray.Add(New ChoiceParameter("Filter.ARAPCurrency", Object.Currency));
	
	ArrayOfSalesAgreementTypes = New Array;
	ArrayOfPurchaseAgreementTypes = New Array;
		
	If Object.BusinessOperation = Enums.BusinessTransactions.IntercompanyCommissionReturn Then
		ParametersArray.Add(New ChoiceParameter("Filter.ContractType", Enums.TypesOfIntercompanyContracts.Consignment));
		ArrayOfSalesAgreementTypes.Add(New ChoiceParameter("Filter.ContractType", PredefinedValue("Enum.ContractTypes.WithConsignor")));
		ArrayOfPurchaseAgreementTypes.Add(New ChoiceParameter("Filter.ContractType", PredefinedValue("Enum.ContractTypes.WithConsignee")));
	Else
		ParametersArray.Add(New ChoiceParameter("Filter.ContractType", Enums.TypesOfIntercompanyContracts.PurchaseAndSale));
		ArrayOfSalesAgreementTypes.Add(New ChoiceParameter("Filter.ContractType", PredefinedValue("Enum.ContractTypes.WithCustomer")));
		ArrayOfPurchaseAgreementTypes.Add(New ChoiceParameter("Filter.ContractType", PredefinedValue("Enum.ContractTypes.WithVendor")));
	EndIf;
	
	Items.Contract.ChoiceParameters = New FixedArray(ParametersArray);
	Items.SalesContract.ChoiceParameters = New FixedArray(ArrayOfSalesAgreementTypes);
	Items.PurchasingContract.ChoiceParameters = New FixedArray(ArrayOfPurchaseAgreementTypes);
	
EndProcedure

&AtClient
Procedure FillInPricesOfSelectedRowsByPriceTypeCompletion(PricesKind, AdditionalParameters) Export
	
	If ValueIsFilled(PricesKind) Then
		
		PricesCalculated = FillInPricesByPriceKindServer(PricesKind, Items.Goods.SelectedRows);
		SalesClient.NotifyAboutEndOfFillingInPricesByTypeOfPrices(PricesCalculated, PricesKind);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure SelectionBasedOnTheBalanceOfMutualSettlementsCompletion(Result, AdditionalParameters) Export 
	
	Notification = New CallbackDescription("SelectionByStockCompletion", ThisObject);
	PlacePaymentDecryptionInTemporaryStorage();
	ARAPAccountingClient.AddToPaymentDecryption(ThisForm, Items.ARAPDetails.Name, Notification);
	
EndProcedure

&AtClient
Procedure SelectionByStockCompletion(Result, AdditionalParameters) Export
	If Result <> Undefined Then
		SelectionByStockCompletionServer();
	EndIf;
EndProcedure

&AtServer
Procedure SelectionByStockCompletionServer()
	ARAPAccountingFormWork.DownloadPaymentTranscriptFromTemporaryStorage(ThisForm);
EndProcedure

&AtClient
Procedure SearchByBarcodeCompletion(BarcodeData_2, AdditionalParameters) Export
	
	ProcessBarcodes(BarcodeData_2);
	
EndProcedure

&AtClient
Procedure SplitRowCompletion(NewRow, AdditionalParameters) Export 
	
	CurrentRow = Items.Goods.CurrentData;
	
	If NewRow <> Undefined Then
		
		StructureOfActions = New Structure;
		AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions,Object);
		
		BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
		BatchProcessingOfTablePartClient.ProcessTSString(NewRow, StructureOfActions, CachedValues);
		
	EndIf;
	
	AccountingForTraceableGoodsClientServerLocalization.SplitRowCompletion(NewRow, AdditionalParameters);
	
EndProcedure

&AtServer
Procedure ContractOnChangeServer()
	
	AttributesToFillIn_ = "
	|ARAPObjectSettings,
	|BankAccount,
	|BankAccountOfBeneficiary,
	|NameForPrinting,
	|Number,
	|Date,
	|LineOfBusiness,
	|FinancialAccountingGroup,
	|FinancialAccountingGroupOfRecipient
	|";
	
	ContractDetails_ = Common.ObjectAttributesValues(Object.Contract, AttributesToFillIn_);
	
	Object.LineOfBusiness = ContractDetails_.LineOfBusiness;
	
	Object.Basis = ContractDetails_.NameForPrinting;
	Object.BaseDocumentNumber = ContractDetails_.Number;
	Object.ReferenceDocumentDateForPrintForms = ContractDetails_.Date;
	
	Object.FinancialAccountingGroup = ContractDetails_.FinancialAccountingGroup;
	Object.FinancialAccountingGroupOfRecipient = ContractDetails_.FinancialAccountingGroupOfRecipient;
	
	Object.CompanyBankAccount = ContractDetails_.BankAccountOfBeneficiary;
	Object.RecipientCompanyBankAccount = ContractDetails_.BankAccount;
	
	If ValueIsFilled(Object.Organization) And Not ValueIsFilled(Object.CompanyBankAccount) Then
		
		ParametersStructure = CashServer.ParametersForFillingOutOrganizationSBankAccount();
		ParametersStructure.Organization = Object.Organization;
		ParametersStructure.LineOfBusiness = Object.LineOfBusiness;
		
		Object.CompanyBankAccount =
			CashServer.GetOrganizationSDefaultBankAccount(ParametersStructure);
		
	EndIf;
	
	If ValueIsFilled(Object.CompanyRecipient)
		And Not ValueIsFilled(Object.RecipientCompanyBankAccount) Then
		
		ParametersStructure = CashServer.ParametersForFillingOutOrganizationSBankAccount();
		ParametersStructure.Organization = Object.CompanyRecipient;
		ParametersStructure.LineOfBusiness = Object.LineOfBusiness;
		
		Object.RecipientCompanyBankAccount =
			CashServer.GetOrganizationSDefaultBankAccount(ParametersStructure);
		
	EndIf;
	
	FillInSubordinatePropertiesForStatistics("Contract");
	
	CompleteVATTaxation();
	UpdateInformationOnTransfers();
	
	ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisForm, "Contract");
	
EndProcedure

&AtServer
Procedure SalesContractOnChangeServer()
	
	CompleteVATTaxation();
	
	ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisForm, "SalesContract");
	ARAPAccountingFormWork.WhenChangingParametersOfMechanism(ThisForm);
	
EndProcedure

&AtServer
Procedure PurchasingContractOnChangeServer()
	
	CompleteVATTaxation();
	
	ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisForm, "PurchasingContract");
	ARAPAccountingFormWork.WhenChangingParametersOfMechanism(ThisForm);
	
EndProcedure

&AtServer
Procedure CompleteVATTaxation()
	
	FillParameters = Documents.IntercompanyGoodsReturn.ParametersForFillingInVATTaxation_(Object);
	
	VATAccountingERP.FillInSalesVATTaxation(Object.VATTaxation,
												FillParameters,
												VATAccountingCachedParameterValues);
	VATAccountingERP.FillInSalesVATTaxSelectionList(Items.VATTaxation,
															Object.VATTaxation,
															FillParameters,
															VATAccountingCachedParameterValues);
	
	VATTaxationOnChangeServer();
	
EndProcedure

&AtClient
Procedure SetCostPresentationInLine(CurrentRow)
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInCostDeterminationMethodWithLine", CostDeterminationParameters(ThisForm));
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
EndProcedure

&AtServer
Procedure EstablishCostPresentation()
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInCostDeterminationMethodWithLine", CostDeterminationParameters(ThisForm));
	BatchProcessingOfTablePartServer.TreatTS(Object.Goods, StructureOfActions, Undefined);
	
EndProcedure

&AtClientAtServerNoContext
Function CostDeterminationParameters(Form)
	
	CostDeterminationParameters = New Structure;
	CostDeterminationParameters.Insert("VATTaxation", Form.Object.VATTaxation);
	CostDeterminationParameters.Insert("ManagementAccountingCurrency", Form.ManagementAccountingCurrency);
	CostDeterminationParameters.Insert("LocalAccountingCurrency", Form.LocalAccountingCurrency);
	CostDeterminationParameters.Insert("UseLocal",  Form.UseLocal);
	Return CostDeterminationParameters;

EndFunction

&AtClient
Procedure ChoosingMethodForDeterminingCostOfProduction(SelectionResult, AdditionalParameters) Export
	
	If TypeOf(AdditionalParameters) = Type("Structure") And AdditionalParameters.Property("SelectedRows")
		And TypeOf(SelectionResult) = Type("Structure") Then
		Rows = AdditionalParameters.SelectedRows;
		For Each String In Rows Do
			TableRow = Object.Goods.FindByID(String);
			If TableRow <> Undefined Then
				FillPropertyValues(TableRow, SelectionResult);
			EndIf;
		EndDo;
		EstablishCostPresentation();
		Modified = True;
	ElsIf TypeOf(SelectionResult) = Type("Structure") Then
		FillPropertyValues(Items.Goods.CurrentData, SelectionResult);
		Modified = True;
		SetCostPresentationInLine(Items.Goods.CurrentData);
		EstablishCostPresentation();
	EndIf;
	
	SetVisibilityOfElementsInTransferDocuments();
	OrderOfReflection = OrderOfReflection(Object.RecordInProfitLossOfPreviousYears);
	Items.ReflectionInAccounting_.Title = TitleOfReflectionInAccounting(Object.RecordInProfitLossOfPreviousYears);
	
EndProcedure

&AtServer
Procedure SelectionProcessingSelectionByTransfersServer(GoodsAddressInStorage)
	
	ReturnValueStructure = GetFromTempStorage(GoodsAddressInStorage);
	TableOfGoods = ReturnValueStructure.Goods;
	
	For Each RowOfProduct In TableOfGoods Do
		CurrentRow = Object.Goods.Add();
		FillPropertyValues(CurrentRow, RowOfProduct);
		
		CurrentRow.DocumentTransfers_ = RowOfProduct.SaleTransferDocument;
		
		If ValueIsFilled(CurrentRow.DocumentTransfers_) Then
			CurrentRow.CostDefiningMethod = Enums.WaysToCalculateReturnCost.FromTransferDocument;
		Else
			CurrentRow.CostDefiningMethod = Enums.WaysToCalculateReturnCost.FromCurrentDocument;
		EndIf;
		
		PriceManagementSystem.RecalculateAmountsInRowWithVAT(CurrentRow, Object.PriceIncludesVAT, False, False, True);
	EndDo;
	
	SetVisibilityOfElementsInTransferDocuments();
	OrderOfReflection = OrderOfReflection(Object.RecordInProfitLossOfPreviousYears);
	Items.ReflectionInAccounting_.Title = TitleOfReflectionInAccounting(Object.RecordInProfitLossOfPreviousYears);
	
	FillInAdditionalProductAttributes();
	ItIsRequiredToUpdateTitleIsSubjectToExciseDuty = UseExcisableGoods;
	PurchasesServer.FillInServiceAttributesOfCCDNumber(Object.Goods);
	RecalculateNumberOfRNPT();
	UpdateInformationOnTransfers();
	
	ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);
	
EndProcedure

&AtServer
Procedure UpdateInformationOnTransfers(ToUpdateData = True)
	
	TransferList.Clear();
	
	For Each Page1 In Object.Goods Do
		If ValueIsFilled(Page1.DocumentTransfers_) And TransferList.FindByValue(Page1.DocumentTransfers_) = Undefined Then
			TransferList.Add(Page1.DocumentTransfers_);
		EndIf;
	EndDo;
	
	If TransferList.Count() = 1 Then
		Object.DocumentTransfers_ = TransferList[0].Value;
	ElsIf TransferList.Count() > 1 Then
		TransferHeaderLabel = StrReplace(
		NStr("vi = 'Tất cả chứng từ: %NumberOfImplementations%';
			|ru = 'Всего документов: %NumberOfImplementations%';
			|en = 'Total documents: %NumberOfImplementations%'; fa = 'Total documents: %NumberOfImplementations%';
			|it = 'Totale documenti: %NumberOfImplementations%';
			|pl = 'Razm dokumentów: %NumberOfImplementations%';
			|tr = 'Toplam belgeler: %NumberOfImplementations%'"), "%NumberOfImplementations%",
		TransferList.Count());
		Object.DocumentTransfers_ = Undefined;
	Else
		Object.DocumentTransfers_ = Undefined;
	EndIf;
	
	Items.TransferPages.CurrentPage = ?(TransferList.Count() > 1, Items.PageOfTransfer, Items.TransferPage);
	
	EstablishCostPresentation();
	
	SetVisibilityOfElementsInTransferDocuments();
	OrderOfReflection = OrderOfReflection(Object.RecordInProfitLossOfPreviousYears);
	Items.ReflectionInAccounting_.Title = TitleOfReflectionInAccounting(Object.RecordInProfitLossOfPreviousYears);
	UseExcisableGoods = ThisIsSale And GetFunctionalOption("UseExcisableGoods");
	ExcisableGoodsAccounting.UpdateElementsOfAccountingForExcisableItems(ThisObject, ToUpdateData);
	
EndProcedure

&AtServer
Procedure RecalculateNumberOfRNPT()
	
	If ValueIsFilled(Object.Warehouse)
		And ValueIsFilled(Object.Organization) Then
		
		ParametersForObtainingRnptCoefficient = AccountingForTraceableGoodsClientServerLocalization.ParametersForObtainingRnptCoefficient(
												Object);
		AccountingForTraceableGoodsLocalization.FillInQuantityByRNPTVOfTablePart(ParametersForObtainingRnptCoefficient,
																						Object.Goods);
		
	EndIf;
	
EndProcedure

&AtServer
Procedure SetVisibilityOfElementsInTransferDocuments()
	
	TransferDocumentHasBeenCompleted = False;
	
	For Each TSRow In Object.Goods Do
		
		If ValueIsFilled(TSRow.DocumentTransfers_)
			And TSRow.CostDefiningMethod =
				Enums.WaysToCalculateReturnCost.FromTransferDocument Then
			TransferDocumentHasBeenCompleted = True;
			Break;
		EndIf;
		
	EndDo;
	
	Items.ReflectionInAccounting_.Visible = Not TransferDocumentHasBeenCompleted;
	
EndProcedure

&AtClient
Procedure UpdateAttributesOfAccountingDocument()
	
	If OrderOfReflection = "Revenue" And Object.RecordInProfitLossOfPreviousYears Then
		Object.RecordInProfitLossOfPreviousYears = False;
	ElsIf OrderOfReflection = "OtherIncome" And Not Object.RecordInProfitLossOfPreviousYears Then
		Object.RecordInProfitLossOfPreviousYears = True;
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Function OrderOfReflection(RecordInProfitLossOfPreviousYears)
	
	If RecordInProfitLossOfPreviousYears Then
		Return "OtherIncome";
	EndIf;
	
	Return "Revenue";
	
EndFunction

&AtClientAtServerNoContext
Function TitleOfReflectionInAccounting(RecordInProfitLossOfPreviousYears)
	
	TitleReflectionInAccounting = NStr("ru = 'Отражение в учете: %1';
										|vi = 'Accounting attributes: %1';
										|en = 'Accounting attributes: %1'; fa = 'Accounting attributes: %1';
										|it = 'Accounting attributes: %1';
										|pl = 'Accounting attributes: %1';
										|tr = 'Muhasebeleştirme: %1'");
	
	If RecordInProfitLossOfPreviousYears Then
		ReflectionOfAC = NStr("ru = 'прочие доходы/расходы';
								|vi = 'other income/expenses';
								|en = 'other income/expenses'; fa = 'other income/expenses';
								|it = 'other income/expenses';
								|pl = 'other income/expenses';
								|tr = 'diğer gelirler/giderler'");
	Else
		ReflectionOfAC = NStr("ru = 'уменьшение выручки и себестоимости продаж';
								|vi = 'decrease in revenue and cost of goods sold';
								|en = 'decrease in revenue and cost of goods sold'; fa = 'decrease in revenue and cost of goods sold';
								|it = 'decrease in revenue and cost of goods sold';
								|pl = 'decrease in revenue and cost of goods sold';
								|tr = 'satış geliri ve satışların maliyetinde azalma'");
	EndIf;
	
	Return StringFunctionsClientServer.SubstituteParametersToString(TitleReflectionInAccounting, ReflectionOfAC);
	
EndFunction
&AtServer
Procedure CalculateNumberOfExcisableItemsDeferred()
	
	CalculationParameters = ExcisableGoodsAccounting.ParametersForCalculatingNumberOfExcisableItems();
	CalculationParameters.CompanyFieldName1 = "CompanyRecipient";
	FilterParameters = New Structure("DocumentTransfers_", Documents.CustomerInvoiceIntercompany.EmptyRef());
	CalculationParameters.FilterParameters = FilterParameters;
	DataForCalculatingNumberOfExcisableGoods =
		ExcisableGoodsAccounting.StartCalculatingNumberOfExcisableItems(Object, CalculationParameters);
	
EndProcedure

&AtClient
Procedure Attachable_UpdateFieldHeaderIsSubjectToExciseDuty()
	
	ExcisableGoodsAccountingClient.AfterCalculatingNumberOfExcisableItems(ThisObject);
	
EndProcedure
&AtServer
Procedure FillInSubordinatePropertiesForStatistics(ParentPropsName)
	ObjectsFillingByStatistics.FillInSubordinateDetailsOfObject(Object, ParentPropsName);
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
