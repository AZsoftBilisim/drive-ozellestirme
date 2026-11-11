#Region Variables

&AtClient
Var CachedValues; // used by the mechanism for processing changes in PM details

&AtClient
Var CurDataId; //used to pass the current line to the wait handler

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

	SetConditionalAppearance();
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;

	InfobaseUpdate.CheckObjectProcessed(Object, ThisObject);
	
	DocumentCorrection.OnCreateAtServer(ThisForm, Items.LineCorrection);
	
	TMCommonUse.CustomizePeripherals(ThisForm);
	
	// Handler of the subsystem "Versioning of objects"
	ObjectsVersioning.OnCreateAtServer(ThisObject);

	// StandardSubsystems.Properties
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("ItemForPlacementName", "GroupAdditionalAttributes");
	AdditionalParameters.Insert("DeferredInitialization", True);
	PropertyManager.OnCreateAtServer(ThisObject, AdditionalParameters);
	// End StandardSubsystems.Properties
	
	
	// Handler of the "Destination" mechanism
	Catalogs.Assignments.DocumentFormWhenCreatedOnServer(ThisForm);
	
	RestrictGoodsReceiptWithoutCCDNumbers = GetFunctionalOption("RestrictGoodsReceiptWithoutCCDNumbers");
	
	If Not ValueIsFilled(Object.Ref) Then
		OnReadCreateAtServer();
		ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);
	EndIf;
	
	If ClientApplication.CurrentInterfaceVariant() = ClientApplicationInterfaceVariant.Version8_2 Then
		Items.GroupInTotal.BackColor = New Color();
	EndIf;
	SetTitleOfPrintDetails();
	HideDisplayIntermediaryData();
	
	NewOnlineARAPAccounting = GetFunctionalOption("NewOnlineARAPAccounting");
	
	Items.GroupCalculations.Visible = (Object.BusinessOperation = Enums.BusinessTransactions.GoodsSaleToAnotherCompany);
	
	EstablishVisibilityOfRNPTQuantity();
	
	// Selection of articles and analytics.
	ItemsAndDimensionsSelectionParameters = Documents.CustomerInvoiceIntercompany.ItemsAndDimensionsSelectionParameters(
										Object.BusinessOperation);
	IncomeAndExpensesServer.OnCreateAtServer(ThisObject, ItemsAndDimensionsSelectionParameters);
	
	ARAPAccountingFormWork.FormWhenCreatedOnServer(ThisForm);
	
	Items.ProductsPartnerPriceType.QuickChoice = Not GetFunctionalOption("UseSeveralPriceTypes");

	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands

	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject);
	// End IntegrationWith1CDocumentManagementSubsystem

	Items.DecorationEDOState.Visible = GetFunctionalOption("UseElectronicDocumentExchangeWithCounterparties");
	
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	
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
	
	OnReadCreateAtServer();
	
	// Selection of articles and analytics.
	ItemsAndDimensionsSelectionParameters = Documents.CustomerInvoiceIntercompany.ItemsAndDimensionsSelectionParameters(
										Object.BusinessOperation);
	IncomeAndExpensesServer.OnReadAtServer(ThisObject, ItemsAndDimensionsSelectionParameters);
	
	FormEvents.OnReadAtServer(ThisObject, CurrentObject);
	
	ARAPAccountingFormWork.FormWhenReadingOnServer(ThisForm);
	
	// StandardSubsystems.Properties	
	PropertyManager.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.Properties
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	// End StandardSubsystems.AttachableCommands

	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
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
Procedure BeforeClose(Cancel, StandardProcessing)
	
	ForceCloseTheForm = True;
	
EndProcedure

&AtClient
Procedure ChoiceProcessing(ValueSelected, ChoiceSource)

	If ChoiceSource.FormName = "CommonForm.SelectGoodsIntercompany" Then
		GetProductsFromStorage(ValueSelected);
	ElsIf VATAccountingERPClient.FinishedEditingInvoiceIssued(ValueSelected, ChoiceSource) Then
		UpdateInvoiceText();
	ElsIf VATAccountingERPClient.FinishedEditingInvoiceReceived(ValueSelected, ChoiceSource) Then
		ConfigureIntermediaryInvoicePresentation();
	ElsIf ChoiceSource.FormName = "CommonForm.PrintingDetailsOfSales" Then
		If ValueSelected <> Undefined Then
			Modified = True;
			FillPropertyValues(Object, ValueSelected);
		EndIf;
	ElsIf ChoiceSource.FormName = "Catalog.InventoryKinds.Form.InventoryOwnerAttributesForm" Then	
		GetStockTypesFromStorage(ValueSelected);
	ElsIf ProductsClient.ThisIsIndicationOfSeries(ChoiceSource) Then
		ProductsClient.ProcessSeriesIndication(ThisForm, SeriesSpecificationParameters, ValueSelected);
		ProductsSeriesRecalculatePrices();
	ElsIf PurchasesClient.ThisIsSelectionOfCCDNumber(ChoiceSource) Then
		ProcessSelectionOfCCDNumber(ValueSelected);
	EndIf;
	
	If Window <> Undefined Then
		Window.Activate();
	EndIf;
	
EndProcedure

&AtClient
Procedure URLProcessing(FormattedStringURL, StandardProcessing)
	
	FormEventsClient.URLProcessing(ThisObject, FormattedStringURL, StandardProcessing);
	
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
	
	If ARAPAccountingClient.NeedAlertProcessingCall(ThisObject, EventName, Parameter) Then
		ChangedPaymentServer(EventName, Parameter);
	EndIf;
	
	// StandardSubsystems.Properties
	If PropertyManagerClient.ProcessNotifications(ThisObject, EventName, Parameter) Then
		UpdateAdditionalAttributesItems();
		PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
	EndIf;
	// End StandardSubsystems.Properties
	
	
	
	DocumentCorrectionClient.NotificationProcessing(ThisObject, EventName, Parameter, Source);
	
	FormEventsClient.NotificationProcessing(ThisObject, EventName, Parameter, Source);
	
	// StandardSubsystems.FilesOperations
	FilesOperationsClient.NotificationProcessing(ThisObject, EventName);
	// End StandardSubsystems.FilesOperations

	// StandardSubsystems.SourceDocumentsOriginalsRecording	
	SourceDocumentsOriginalsRecordingClient.NotificationHandlerDocumentForm(EventName,ThisObject);
	// End StandardSubsystems.SourceDocumentsOriginalsRecording
	
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
Procedure BeforeWrite(Cancel, WriteParameters)
	
	FormEventsClient.BeforeWrite(ThisObject, Cancel, WriteParameters);
	
	If NotExecuteCheck1BeforeWrite Then
		NotExecuteCheck1BeforeWrite = False;
		Return;
	EndIf;
	
	TMCommonUseClient.RecordObjectIfNecessary(ThisObject, WriteParameters, Cancel);
	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	
	// StandardSubsystems.Properties
	PropertyManager.BeforeWriteAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.Properties
	
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
	
	FillInServiceDetailsForProductRange();
	
	UpdateInvoiceText();
	ConfigureIntermediaryInvoicePresentation();
	
	PurchasesServer.FillInServiceAttributesOfCCDNumber(Object.Goods);
	
	// Selection of articles and analytics.
	IncomeAndExpensesServer.AfterWriteAtServer(ThisObject);
	
	

	ARAPAccountingFormWork.FormAfterRecordingOnServer(ThisForm, CurrentObject.AdditionalProperties);

	FormEvents.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	
	ProvisionInDocumentsServer.CheckToRunBackgroundInventoryAllocationJob();
	
	ConfigurationModificationOverridable.AfterWriteAtServer(ThisForm, CurrentObject, WriteParameters);

EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	
	WriteParameters.Insert("NotificationDocumentKeys", OperationsWithDocumentJournalsClient.GetKeyParametersForDocument(
		Object.Ref, Object.Date, Object.BusinessOperation));
	Notify("Write_CustomerInvoiceIntercompany", WriteParameters, Object.Ref);
	ARAPAccountingClient.FormAfterRecording(ThisForm);
	
	FormEventsClient.AfterWrite(ThisObject, WriteParameters);
		

	TMCommonUseClient.PerformActionsAfterRecording(ThisForm, Object, WriteParameters);
	
	// StandardSubsystems.AttachableCommands
	If CommonClient.SubsystemExists("StandardSubsystems.AttachableCommands") Then
		ModuleAttachableCommandsClient = CommonClient.CommonModule("AttachableCommandsClient");
		ModuleAttachableCommandsClient.AfterWrite(ThisObject, Object, WriteParameters);
	EndIf;
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

&AtClient
Procedure OnClose(Exit)

	If Exit Then
		Return;
	EndIf;

	EquipmentManagerClient.StartDisablingHardwareWhenClosingForm(Undefined, ThisForm);

EndProcedure

&AtServer
Procedure OnWriteAtServer(Cancel, CurrentObject, WriteParameters)
	

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
Procedure OrganizationOnChange(Item)
	
	OrganizationOnChangeServer();
	
EndProcedure

&AtClient
Procedure CompanyRecipientOnChange(Item)
	
	CompanyRecipientOnChangeServer();
	
EndProcedure

&AtClient
Procedure BusinessOperationOnChange(Item)

	BusinessOperationOnChangeServer();
	
EndProcedure

&AtClient
Procedure CounterpartyOnChange(Item)
	
	CounterpartyOnChangeServer();
	
	
EndProcedure

&AtClient
Procedure WarehouseOnChange(Item)
	
	WarehouseOnChangeServer();
	
EndProcedure

&AtClient
Procedure ContractOnChange(Item)
	ContractOnChangeServer();
EndProcedure

&AtClient
Procedure VATTaxationOnChange(Item)
	
	VATTaxationOnChangeServer();
	
EndProcedure

&AtClient
Procedure PriceIncludesVATOnChange(Item)
	
	PriceIncludesVATOnChangeServer(CachedValues);
	
EndProcedure

&AtClient
Procedure PriceKindOnChange(Item)
	
	If ValueIsFilled(Object.PriceKind)
	 And Object.Goods.Count() > 0 Then
	 
		ShowQueryBox(New CallbackDescription("PriceKindOnChangeCompletion", ThisObject), NStr("vi = 'Điền lại giá trong phần bảng chứng từ?';
																								|ru = 'Перезаполнить цены в табличной части документа?';
																								|en = 'Refill prices in the table of the document?'; fa = 'Refill prices in the table of the document?';
																								|it = 'Ricompilare i prezzi nella parte tabulare del documento?';
																								|pl = 'Wypełnić ponowie ceny w części tabelarycznej dokumentu?';
																								|tr = 'Belgenin tablo bölümündeki fiyatları yeniden doldur?'"), QuestionDialogMode.YesNo);
	 
	EndIf;
	
EndProcedure

&AtClient
Procedure PriceKindOnChangeCompletion(QuestionResult, AdditionalParameters) Export
    
    ResponseCode = QuestionResult;
    If ResponseCode = DialogReturnCode.Yes Then
        FillInPricesByPriceKindServer(Object.PriceKind);
    EndIf;

EndProcedure

&AtClient
Procedure TextInvoiceURLProcessing(Item, Var_URL, StandardProcessing)
	
	RegistrationParameters = VATAccountingERPClientServer.ParametersForRegisteringInvoicesIssued();
	FillPropertyValues(RegistrationParameters, Object, "Ref, Date, Organization");
	
	RegistrationParameters.Counterparty = ?(Object.ARAPAccountingViaSeparateCounterparty,
										Object.Counterparty,
										Object.CompanyRecipient);
	
	VATAccountingERPClient.ProcessingNavigationLinkInvoicesIssued(ThisForm, Var_URL, StandardProcessing,
		RegistrationParameters);
	
EndProcedure

&AtClient
Procedure TextIntermediaryInvoiceURLProcessing(Item, Var_URL, StandardProcessing)
	
	RegistrationParameters = VATAccountingERPClientServer.ParametersForRegisteringInvoicesReceived();
	FillPropertyValues(RegistrationParameters, Object, "Ref, Date, VATTaxation");
	
	RegistrationParameters.Organization = Object.CompanyRecipient;
	RegistrationParameters.Counterparty  = ?(Object.ARAPAccountingViaSeparateCounterparty,
										Object.Counterparty,
										Object.Organization);
	
	PurchaseOfGoods = Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.GoodsSaleToAnotherCompany");
	
	RegistrationParameters.PurchaseOfGoodsWorksServices = PurchaseOfGoods
															And Object.ARAPAccountingViaSeparateCounterparty;
	RegistrationParameters.ConsignmentProcurement               = Not PurchaseOfGoods
															And Object.ARAPAccountingViaSeparateCounterparty;
	
	VATAccountingERPClient.ProcessingNavigationLinkInvoicesReceived(ThisForm, Var_URL, StandardProcessing,
		RegistrationParameters);
	
EndProcedure

&AtClient
Procedure ARAPAccountingViaSeparateCounterpartyOnChange(Item)
	
	ARAPAccountingViaSeparateCounterpartyOnChangeServer();
	
EndProcedure

&AtClient
Procedure PartnerOnChange(Item)
	
	PartnerOnChangeServer();
	
	
EndProcedure

&AtClient
Procedure SpecifyCCDNumbersOnChange(Item)
	
	Items.GoodsCCDNumber.Visible = Object.SpecifyCCDNumbers;
	Items.GoodsCCDNumberOriginCountry.Visible = Object.SpecifyCCDNumbers;
	Items.GoodsFillInCCDNumbers.Visible = Object.SpecifyCCDNumbers;
	
	SpecifyCCDNumbersOnChangeServer();
	
EndProcedure

&AtClient
Procedure DateOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	
	DateOnChangeServer();
	UpdateTransferForActivity();
	
	
EndProcedure

&AtClient
Procedure SaleRegistrationOptionOnChange(Item)
	ChangeHeadingsForSalesLayoutOption();
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
			
		EndIf;
		
	EndIf;
	
EndProcedure

&AtServer
Procedure LabelCurrenciesClickCompletionServer(ClosingResult)
	
	ChangedBankingDetails = ClosingResult.OldValuesOfChangedProps;
	
	If ClosingResult.RecalculateDocumentAmounts Then
		DocumentAmountOnChangeServer(ClosingResult.DocumentAmount);
		CalculateFinalIndicatorsOfTransferOfGoodsBetweenOrganizations(ThisForm);
	EndIf;
	If ChangedBankingDetails.Property("Currency") Then
		DocumentCurrency = Object.Currency;
		FillInSubordinatePropertiesForStatistics("Currency");
	EndIf;
	
	If ChangedBankingDetails.Property("ARAPCurrency") Then
		FillInDefaultContract();
		FillInDefaultContractData();
		FillInBankAccountsByDefaultServer();
	EndIf;
	
	ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisForm, ChangedBankingDetails, True);
	
EndProcedure

&AtClient
Procedure Decorationedonage(Item, StandardProcessing)
	
	
EndProcedure

&AtClient
Procedure LabelPaymentStagesClick(Item, StandardProcessing)
	
	Notification = New CallbackDescription("LabelPaymentStagesClickCompletion", ThisObject);
	ARAPAccountingClient.LabelPaymentStagesClick(ThisForm, Item, StandardProcessing, Notification);
	
EndProcedure

&AtClient
Procedure LabelPaymentStagesClickCompletion(Result, AdditionalParameters) Export
	
	If Result <> Undefined Then
		ChangedBankingDetails = Result.OldValuesOfChangedProps;
		ReflectChangesToPaymentRules(ChangedBankingDetails);
	EndIf;
	
	CalculateFinalIndicatorsOfTransferOfGoodsBetweenOrganizations(ThisForm);
	
EndProcedure

&AtClient
Procedure SalesContractOnChange(Item)
	
	SalesContractOnChangeServer();
	
EndProcedure

&AtClient
Procedure PurchasingContractOnChange(Item)
	
	PurchasingContractOnChangeServer()
	
EndProcedure

&AtClient
Procedure PagesOnCurrentPageChange(Item, CurrentPage)
	
	// StandardSubsystems.Properties
	If ThisObject.PropertiesParameters.Property(CurrentPage.Name)
			And Not ThisObject.PropertiesParameters.DeferredInitializationExecuted Then
		
		PropertiesExecuteDeferredInitialization();
		PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
	EndIf;
	// End StandardSubsystems.Properties
	
EndProcedure


&AtClient
Procedure TransferForActivity_Clearing(Item, StandardProcessing)
	StandardProcessing = False;
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

#EndRegion

#Region FormTableItemsEventHandlersGoods

&AtClient
Procedure GoodsSelection(Item, RowSelected, Field, StandardProcessing)
	
	CurrentData = Items.Goods.CurrentData;
	
	If Field = Items.GoodsPrice
		And ValueIsFilled(CurrentData.PriceKind) Then
		
		ClearMessages();
		
		CommonClient.MessageToUser(
			NStr("vi = 'Để soạn đơn giá, hãy xóa dạng giá';
				|ru = 'Для редактирования цены очистите вид цены';
				|en = 'To edit the price, clear the price type'; fa = 'To edit the price, clear the price type';
				|it = 'Для редактирования цены очистите вид цены';
				|pl = 'To edit the price, clear the price type';
				|tr = 'Fiyatı düzenlemek için fiyat türünü temizleyin'"),
			Object.Ref,
			CommonClientServer.PathToTabularSection("Object.Goods", CurrentData.LineNumber, "PriceKind"));
		
	ElsIf Field = Items.GoodsSum
		And ValueIsFilled(CurrentData.PriceKind) Then
		
		ClearMessages();
		
		CommonClient.MessageToUser(
			NStr("vi = 'Để soạn số tiền, hãy xóa dạng giá';
				|ru = 'Для редактирования суммы очистите вид цены';
				|en = 'To edit the amount, clear the price type'; fa = 'To edit the amount, clear the price type';
				|it = 'Для редактирования суммы очистите вид цены';
				|pl = 'To edit the amount, clear the price type';
				|tr = 'Tutarı düzenlemek için fiyat türünü temizle'"),
			Object.Ref,
			CommonClientServer.PathToTabularSection("Object.Goods", CurrentData.LineNumber, "PriceKind"));
		
	EndIf;
	
EndProcedure

&AtClient
Procedure GoodsOnStartEdit(Item, NewRow, Copy)
	
	ProcessingOfTabularFormsClient.CacheCurLine(Items.Goods, ThisObject);
	CurrentData = Items.Goods.CurrentData;
	
	If NewRow
		And Not Copy Then
		
		CurrentData.PriceKind = Object.PriceKind;
		
	EndIf;
	
	// Selection of articles and analytics.
	IncomeAndExpensesClientServer.WhenAddingRowToTable(ThisForm, CurrentData, "Object.Goods");
	
EndProcedure

&AtClient
Procedure GoodsOnEditEnd(Item, NewRow, CancelEdit)
	
	AdditionalParameters = New Structure;
	FormEventsClient.WhenChangingElement(ThisObject, Items.Goods, AdditionalParameters);
	If AdditionalParameters.Property("ServerCallRequired__") Then
		AttachIdleHandler("GoodsAtEndOfEditingForServerCall", 0.5, True);
	EndIf;
	
EndProcedure

&AtClient
Procedure GoodsBeforeDeleteRow(Item, Cancel)
	ProcessingOfTabularFormsClient.CacheCurLine(Items.Goods, ThisObject);
EndProcedure

&AtClient
Procedure GoodsAfterDeleteRow(Item)
	
	CalculateFinalIndicatorsOfTransferOfGoodsBetweenOrganizations(ThisForm);
	ProductsAfterDeletionOnServer();
	
EndProcedure

&AtClient
Procedure GoodsOnChange(Item)
	
	CalculateFinalIndicatorsOfTransferOfGoodsBetweenOrganizations(ThisForm);
	
EndProcedure

&AtClient
Procedure GoodsProductsOnChange(Item)

	CurrentRow = Items.Goods.CurrentData;

	StructureOfActions = New Structure;
	StructureOfActions.Insert("CheckCharacteristicsByOwner", CurrentRow.Characteristic);
	StructureOfActions.Insert("CheckFillPackageByOwner", CurrentRow.Package);
	StructureOfActions.Insert("RecalculateNumberOfUnits");
	StructureOfActions.Insert("FillInSalePrice", BatchProcessingOfTablePartClientServer.ParametersForFillingInPriceInTSLine(Object));
	StructureOfActions.Insert("FillInVATRate", BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRate(Object));
	StructureOfActions.Insert("FillInVATRateByPriceType", BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRateByPriceType(Object));
	StructureOfActions.Insert("RecalculateVATAmount",  BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object));
	StructureOfActions.Insert("RecalculateAmountWithVAT", New Structure("PriceIncludesVAT", Object.PriceIncludesVAT));
	StructureOfActions.Insert("RecalculateAmount");
	StructureOfActions.Insert("FillInCCDTrackingAttribute", New Structure("Products", "TheRecordsAreKeptByCCD"));
	StructureOfActions.Insert("FillInCountryOfOriginOfProduct",
								BatchProcessingOfTablePartClientServer.CountryOfOriginFillingParameters());
	StructureOfActions.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
	StructureOfActions.Insert("CheckSeriesCalculateStatus", New Structure("Warehouse, SeriesSpecificationParameters", Object.Warehouse, SeriesSpecificationParameters));
	StructureOfActions.Insert("ProductsOnChangeOverridable", New Structure("FormName, TabularSectionName",
		ThisForm.FormName, "Goods"));
	StructureOfActions.Insert("ClearAmountOfSettlements");
	BatchProcessingOfTablePartClientServerLocalization.CompleteActionStructureWhenChangingElement(
		ThisObject, "Products", StructureOfActions);
	AccountingForTraceableGoodsClientServerLocalization.CompleteDescriptionOfSettingsForFillingInServiceDetailsOfTablePart(StructureOfActions);
	AccountingForTraceableGoodsClientServerLocalization.AddDescriptionOfSettingsForRecalculatingDetailsOfTablePart(
		Object,
		StructureOfActions);
	
	// Selection of articles and analytics.
	IncomeAndExpensesClientServer.InsertActionClearItemAndExpenseAnalytics(StructureOfActions, ThisObject);
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
	If CurrentRow.ItemsType = PredefinedValue("Enum.ItemsTypes.OwnGoods")
		Or CurrentRow.ItemsType = PredefinedValue("Enum.ItemsTypes.ReusablePackage")
		Or CurrentRow.ItemsType = PredefinedValue("Enum.ItemsTypes.Set") Then
		
		CurrentRow.ToExpenseAs = False;
		CurrentRow.Department    = PredefinedValue("Catalog.BusinessStructure.EmptyRef");
		
	ElsIf CurrentRow.ItemsType = PredefinedValue("Enum.ItemsTypes.OperationService") Then
		CurrentRow.ToExpenseAs = True;
	EndIf;
	
	// Selection of articles and analytics.
	IncomeAndExpensesClientServer.WhenChangingArticleAvailabilityDetailsInLine(ThisObject, CurrentRow, "Object.Goods");
	
	CalculateFinalIndicatorsOfTransferOfGoodsBetweenOrganizations(ThisForm);
	
EndProcedure

&AtClient
Procedure GoodsCharacteristicOnChange(Item)

	CurrentRow = Items.Goods.CurrentData;

	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInVATRateByPriceType", BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRateByPriceType(Object));
	StructureOfActions.Insert("FillInSalePrice", BatchProcessingOfTablePartClientServer.ParametersForFillingInPriceInTSLine(Object));
	StructureOfActions.Insert("RecalculateVATAmount",  BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object));
	StructureOfActions.Insert("RecalculateAmountWithVAT", New Structure("PriceIncludesVAT", Object.PriceIncludesVAT));
	StructureOfActions.Insert("RecalculateAmount");
	StructureOfActions.Insert("ClearAmountOfSettlements");

	StructureOfActions.Insert("CharacteristicOnChangeOverridable", New Structure("FormName, TabularSectionName",
		ThisForm.FormName, "Goods"));

	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
	CalculateFinalIndicatorsOfTransferOfGoodsBetweenOrganizations(ThisForm);
	
EndProcedure

&AtClient
Procedure GoodsPackageOnChange(Item)

	ClearMessages();
	
	CurrentRow = Items.Goods.CurrentData;

	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);

	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateNumberOfUnits");
	StructureOfActions.Insert("FillInVATRateByPriceType", BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRateByPriceType(Object));

	If CurrentRow.Count > 0 And Not ValueIsFilled(CurrentRow.PriceKind) Then
		StructureOfActions.Insert("RecalculatePricePerPackage", CurrentRow.Count);
	ElsIf ValueIsFilled(CurrentRow.PriceKind) Then
		StructureOfActions.Insert("FillInSalePrice", BatchProcessingOfTablePartClientServer.ParametersForFillingInPriceInTSLine(Object));
	EndIf;
	
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmount");
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("ClearAmountOfSettlements");
	AccountingForTraceableGoodsClientServerLocalization.AddDescriptionOfSettingsForRecalculatingDetailsOfTablePart(
		Object,
		StructureOfActions);

	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	CalculateFinalIndicatorsOfTransferOfGoodsBetweenOrganizations(ThisForm);

EndProcedure

&AtClient
Procedure GoodsNumberOfPackagesOnChange(Item)

	CurrentRow = Items.Goods.CurrentData;

	StructureOfActions = New Structure;
 	AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions, Object);
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	CalculateFinalIndicatorsOfTransferOfGoodsBetweenOrganizations(ThisForm);

EndProcedure

&AtClient
Procedure GoodsPriceKindOnChange(Item)
	
	ClearMessages();

	CurrentRow = Items.Goods.CurrentData;

	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInSalePrice", BatchProcessingOfTablePartClientServer.ParametersForFillingInPriceInTSLine(Object));
	StructureOfActions.Insert("RecalculateVATAmount", BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object));
	StructureOfActions.Insert("RecalculateAmount");
	StructureOfActions.Insert("RecalculateAmountWithVAT", New Structure("PriceIncludesVAT", Object.PriceIncludesVAT));
	StructureOfActions.Insert("ClearAmountOfSettlements");
	StructureOfActions.Insert("FillInVATRateByPriceType", BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRateByPriceType(Object));

	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);	
	CalculateFinalIndicatorsOfTransferOfGoodsBetweenOrganizations(ThisForm);

EndProcedure

&AtClient
Procedure GoodsPriceOnChange(Item)

	CurrentRow = Items.Goods.CurrentData;

	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateVATAmount", BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object));
	StructureOfActions.Insert("RecalculateAmount");
	StructureOfActions.Insert("RecalculateAmountWithVAT", New Structure("PriceIncludesVAT", Object.PriceIncludesVAT));
	StructureOfActions.Insert("ClearAmountOfSettlements");

	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
	If ValueIsFilled(CurrentRow.PriceKind)
	 And CurrentRow.Price <> 0 Then
		CurrentRow.PriceKind = Undefined;
	EndIf;
	CalculateFinalIndicatorsOfTransferOfGoodsBetweenOrganizations(ThisForm);

EndProcedure

&AtClient
Procedure GoodsVATRateOnChange(Item)

	CurrentRow = Items.Goods.CurrentData;

	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateVATAmount", BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object));
	StructureOfActions.Insert("RecalculateAmount");
	StructureOfActions.Insert("RecalculateAmountWithVAT", New Structure("PriceIncludesVAT", Object.PriceIncludesVAT));
	StructureOfActions.Insert("ClearAmountOfSettlements");

	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	CalculateFinalIndicatorsOfTransferOfGoodsBetweenOrganizations(ThisForm);

EndProcedure

&AtClient
Procedure GoodsVATAmountOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateAmountWithVAT", BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object));
	StructureOfActions.Insert("ClearAmountOfSettlements");
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
	CalculateFinalIndicatorsOfTransferOfGoodsBetweenOrganizations(ThisForm);
	
EndProcedure

&AtClient
Procedure GoodsSumOnChange(Item)

	CurrentRow = Items.Goods.CurrentData;

	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculatePriceDiscountByAmountInSales");
	StructureOfActions.Insert("RecalculateVATAmount",  BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object));
	StructureOfActions.Insert("RecalculateAmountWithVAT", New Structure("PriceIncludesVAT", Object.PriceIncludesVAT));
	StructureOfActions.Insert("ClearAmountOfSettlements");

	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	CalculateFinalIndicatorsOfTransferOfGoodsBetweenOrganizations(ThisForm);

EndProcedure

&AtClient
Procedure GoodsAmountARAPOnChange(Item)
	CurrentData = Items.Goods.CurrentData;
	If CurrentData <> Undefined Then
		CurrentData.AmountVATARAP = 0;
	EndIf;
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

&AtClient
Procedure CalculationsClickSender(Item, StandardProcessing)
	
	StandardProcessing = False;
	
	If Object.ARAPAccountingViaSeparateCounterparty Then	
		
		ArraySuppliers = New Array();
		ArraySuppliers.Add(Object.Organization);
		
		FilterValues = New Structure("Counterparty,Organization,ARAPDocument", Object.Counterparty, ArraySuppliers, Object.Ref);
		FormParameters = New Structure;
		FormParameters.Insert("VariantKey", "CustomersARAPAccounting");
		FormParameters.Insert("PurposeUseKey");
		FormParameters.Insert("Filter", FilterValues);
		FormParameters.Insert("GenerateOnOpen", True);
		
		If NewOnlineARAPAccounting Then
			OpenForm("Report.CustomersARAPStatement.Form", FormParameters)
		Else
			OpenForm("Report.CustomersARAPAccounting.Form", FormParameters);
		EndIf;
		
	Else
		
		StandardProcessing = False;	
		ArrayBuyers = New Array();
		ArrayBuyers.Add(Object.CompanyRecipient);
		ArraySuppliers = New Array();
		ArraySuppliers.Add(Object.Organization);
		
		FilterValues = New Structure("Customer,Seller", ArrayBuyers, ArraySuppliers);
		FormParameters = New Structure;
		FormParameters.Insert("VariantKey", "SalesPayments");
		FormParameters.Insert("PurposeUseKey");
		FormParameters.Insert("Filter", FilterValues);
		FormParameters.Insert("GenerateOnOpen", True);
		
		If NewOnlineARAPAccounting Then
			FormParameters.Filter.Insert("ARAPObject", Object.ARAPObject);
			OpenForm("Report.AccountsPayablesAndReceivablesByIntercompany.Form", FormParameters);
		Else
			FormParameters.Filter.Insert("DocumentOfARAPAccounting", Object.ARAPObject);
			OpenForm("Report.IntercompanyARAP.Form", FormParameters);
		EndIf;
				
	EndIf;
	
EndProcedure

&AtClient
Procedure CalculationsClickRecipient(Item, StandardProcessing)
	
	StandardProcessing = False;
	
	StandardProcessing = False;	
	
	If Object.ARAPAccountingViaSeparateCounterparty Then	
		
		ArraySuppliers = New Array();
		ArraySuppliers.Add(Object.CompanyRecipient);
		
		FilterValues = New Structure("Counterparty,Organization,ARAPDocument",Object.Counterparty, ArraySuppliers, Object.Ref);
		FormParameters = New Structure;
		FormParameters.Insert("VariantKey", "VendorsARAPAccounting");
		FormParameters.Insert("PurposeUseKey");
		FormParameters.Insert("Filter", FilterValues);
		FormParameters.Insert("GenerateOnOpen", True);
		
		If NewOnlineARAPAccounting Then
			OpenForm("Report.VendorsARAPStatement.Form", FormParameters);
		Else
			OpenForm("Report.VendorsARAPAccounting.Form", FormParameters);
		EndIf;
		
	Else
		
		ArrayBuyers = New Array();
		ArrayBuyers.Add(Object.CompanyRecipient);
		ArraySuppliers = New Array();
		ArraySuppliers.Add(Object.Organization);
		
		FilterValues = New Structure("Customer,Seller", ArrayBuyers, ArraySuppliers);
		FormParameters = New Structure;
		FormParameters.Insert("VariantKey", "ProcurementPayments");
		FormParameters.Insert("PurposeUseKey");
		FormParameters.Insert("Filter", FilterValues);
		FormParameters.Insert("GenerateOnOpen", True);
		
		If NewOnlineARAPAccounting Then
			FormParameters.Filter.Insert("ARAPObject", Object.ARAPObjectOfRecipient);
			OpenForm("Report.AccountsPayablesAndReceivablesByIntercompany.Form", FormParameters);
		Else
			FormParameters.Filter.Insert("DocumentOfARAPAccounting", Object.ARAPObjectOfRecipient);
			OpenForm("Report.IntercompanyARAP.Form", FormParameters);
		EndIf;
		
	EndIf;
	
EndProcedure

&AtServer
Procedure ReflectChangesToPaymentRules(ChangedBankingDetails)
	
	ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisForm, ChangedBankingDetails, True);
	
	If ChangedBankingDetails.Property("ARAPObjectSettings") Then	
		RefreshStatusServer();
	EndIf;
	
	If ChangedBankingDetails.Property("ForeignCurrencyTransaction") Then
		
		FinancialAccountingGroups = GetFinancialAccountingGroups(Object.Organization, Object.ARAPCurrency, Object.BusinessOperation);
		Object.FinancialAccountingGroup = FinancialAccountingGroups.FinancialAccountingGroup;
		Object.FinancialAccountingGroupOfRecipient = FinancialAccountingGroups.FinancialAccountingGroupOfRecipient;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure GoodsExpenseItemOnChange(Item)
	
	// Selection of articles and analytics.
	IncomeAndExpensesClientServer.AssetRefOnChange(ThisObject, Item);
	
EndProcedure

&AtClient
Procedure GoodsExpenseItemStartChoice(Item, ChoiceData, StandardProcessing)
	
	// Selection of articles and analytics.
	IncomeAndExpensesClient.StartArticleSelection(ThisObject, Item, StandardProcessing);
	
EndProcedure

&AtClient
Procedure GoodsDimensionOfExpensesStartChoice(Item, ChoiceData, StandardProcessing)
	
	// Selection of articles and analytics.
	IncomeAndExpensesClient.StartSelectingExpenseAnalytics(ThisObject, Item, StandardProcessing);
	
EndProcedure

&AtClient
Procedure GoodsDimensionOfExpensesAutoComplete(Item, Text, ChoiceData, Var_Parameters, Waiting, StandardProcessing)
	
	// Selection of articles and analytics.
	IncomeAndExpensesClient.AutoSelectionOfExpenseAnalytics(ThisObject, Item, Text, ChoiceData, Var_Parameters,
		StandardProcessing);
	
EndProcedure

&AtClient
Procedure GoodsDimensionOfExpensesTextEditEnd(Item, Text, ChoiceData, Var_Parameters, StandardProcessing)
	
	// Selection of articles and analytics.
	IncomeAndExpensesClient.EndOfCostAnalyticsTextEntry(ThisObject, Item, Text, ChoiceData, Var_Parameters,
		StandardProcessing);
	
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

	ProductsClient.ProcessSeriesIndication(ThisObject, SeriesSpecificationParameters, ValueSelected);

	ProductsSeriesRecalculatePrices(CurrentRow);

EndProcedure

&AtClient
Procedure GoodsToExpenseAsOnChange(Item)
	
	CurrentData = Items.Goods.CurrentData;
	
	// Selection of articles and analytics.
	IncomeAndExpensesClientServer.WhenChangingArticleAvailabilityDetailsInLine(ThisObject, CurrentData, "Object.Goods");
EndProcedure

&AtClient
Procedure GoodsOnActivateRow(Item)
	If Item.CurrentItem = Undefined Then
		Return
	ElsIf Item.CurrentItem.Name = "GoodsCCDNumber" Then
		PurchasesClient.FillInListOfCCDNumberSelection(
			Items.Goods.CurrentData, 
			Items.GoodsCCDNumber.ChoiceList);
	EndIf;
EndProcedure

&AtClient
Procedure GoodsOnActivateCell(Item)
	If Item.CurrentItem = Undefined Then
		Return
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

&AtClient
Procedure OpenInventoryKinds(Command)
	
	OptionsForEditingInventoryTypes = PutGoodsAndStockTypesInStorage();
	
	FinancesClient.OpenInventoryKinds(ThisObject, OptionsForEditingInventoryTypes);
	
EndProcedure

&AtClient
Procedure SelectionOfTheSenderSRemainingGoods(Command)
	
	CheckParameters = ProcessingOfTabularFormsClient.FillVerificationParameters();
	CheckParameters.CheckedAttributes.Insert("Organization", NStr("vi = 'Người gửi';
																	|ru = 'Отправитель';
																	|en = 'Sender'; fa = 'فرستنده';
																	|it = 'Mittente';
																	|pl = 'Nadawca';
																	|tr = 'Gönderen'"));
	CheckParameters.CheckedAttributes.Insert("Warehouse",       NStr("vi = 'Kho bãi';
																	|ru = 'Склад';
																	|en = 'Warehouse'; fa = 'Warehouse';
																	|it = 'Magazzino';
																	|pl = 'Magazyn';
																	|tr = 'Ambar'"));
	Notification = New CallbackDescription("SelectionOfTheSenderSRemainingGoodsCompletion", ThisObject);
	ProcessingOfTabularFormsClient.CheckIfItCanBeFilledIn(ThisForm, Notification, CheckParameters);
	
EndProcedure

&AtClient
Procedure SelectByNegativeInventory(Command)
	
	CheckParameters = ProcessingOfTabularFormsClient.FillVerificationParameters();
	CheckParameters.CheckedAttributes.Insert("Organization",           NStr("vi = 'Người gửi';
																			|ru = 'Отправитель';
																			|en = 'Sender'; fa = 'فرستنده';
																			|it = 'Mittente';
																			|pl = 'Nadawca';
																			|tr = 'Gönderen'"));
	CheckParameters.CheckedAttributes.Insert("CompanyRecipient", NStr("vi = 'Người nhận';
																		|ru = 'Получатель';
																		|en = 'Customer'; fa = 'مشتری';
																		|it = 'Destinatario';
																		|pl = 'Odbiorca';
																		|tr = 'Alıcı'"));
	CheckParameters.CheckedAttributes.Insert("Warehouse",                 NStr("vi = 'Kho bãi';
																				|ru = 'Склад';
																				|en = 'Warehouse'; fa = 'Warehouse';
																				|it = 'Magazzino';
																				|pl = 'Magazyn';
																				|tr = 'Ambar'"));
	Notification = New CallbackDescription("SelectByNegativeInventoryCompletion", ThisObject);
	ProcessingOfTabularFormsClient.CheckIfItCanBeFilledIn(ThisForm, Notification, CheckParameters);
	
EndProcedure

&AtClient
Procedure FillInPricesByPriceKind(Command)

	If EnterprisePricesFillingClient.ItIsNecessaryToFillInPricesByTypeOfPrices(Object, "Goods", NStr("vi = 'Hàng hóa';
																									|ru = 'Товары';
																									|en = 'Goods'; fa = 'کالاها';
																									|it = 'Merci';
																									|pl = 'Towary';
																									|tr = 'Ürünler'")) Then
		
		PriceSelectionOptions = EnterprisePricesFillingClient.NewFillOptionsSelectPriceType();
		PriceSelectionOptions.CallbackDescription = 
			New CallbackDescription("FillInPricesByPriceKindCompletion", ThisObject);
		PriceSelectionOptions.PriceIncludesVAT = Object.PriceIncludesVAT;
		PriceSelectionOptions.UseForIntercompanySales = True;
		EnterprisePricesFillingClient.ChooseTypeOfPrices(PriceSelectionOptions);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure SearchByBarcode(Command)
	
	ClearMessages();
	Notification = New CallbackDescription("SearchByBarcodeCompletion", ThisObject);
	BarcodingOfItemsClient.ShowBarcodeInput(Notification);
	
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
		PriceSelectionOptions.UseForIntercompanySales = True;
		EnterprisePricesFillingClient.ChooseTypeOfPrices(PriceSelectionOptions);
			
	EndIf;
	
EndProcedure

&AtClient
Procedure WriteDocument(Command)
	
	TMCommonUseClient.Write(ThisForm, True);
	
EndProcedure

&AtClient
Procedure FillInCCDNumbers(Command)
	
	NotificationParameters	= New Structure("CCDNumbersFilledIn", Undefined);
	CallbackDescription	= New CallbackDescription("FillInCCDNumbersCompletion", ThisObject, NotificationParameters);
	
	OpenForm("Catalog.CCDNumbers.ChoiceForm",
				,
				ThisObject,
				UUID,
				,
				,
				CallbackDescription,
				FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure FillInCCDNumbersCompletion(Result, AdditionalParameters) Export
	
	CCDNumber = Result;
	CCDNumbersFilledIn = AdditionalParameters.CCDNumbersFilledIn;
	
	If ValueIsFilled(CCDNumber) Then
		FillInCCDNumbersOnServer(CCDNumber, CCDNumbersFilledIn);
	EndIf;
	
	PurchasesClient.NotifyAboutFillingInGTNumbersInTabularPart(CCDNumbersFilledIn, CCDNumber);
	
EndProcedure

&AtClient
Procedure FillInVATRate(Command)

	If Object.Goods.Count() = 0 Then
		WarningText = NStr("vi = 'Trong danh sách ""Hàng hóa"" chưa điền dòng nào.';
							|ru = 'В список ""Товары"" не введено ни одной строки.';
							|en = 'No lines entered in the Item list.'; fa = 'No lines entered in the Item list.';
							|it = 'В список ""Товары"" не введено ни одной строки.';
							|pl = 'Do listy ""Wiersze pozycji"" nie wprowadzono żadnego wiersza.';
							|tr = '""Mallar"" listesine hiçbir satır girilmemiştir.'");
		ShowMessageBox(, WarningText);
		Return;
	EndIf;

	ClosingNotification1 = New CallbackDescription("FillInVATRateCompletion", ThisObject);
	FormParameters = New Structure();
	FormParameters.Insert("VATTaxationType", Object.VATTaxation);
	OpenForm("Catalog.VATRates.ChoiceForm", FormParameters,,,,, ClosingNotification1);

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

&AtClient
Procedure PostDocument(Command)
	
	TMCommonUseClient.Post(ThisForm, True);
	
EndProcedure

&AtClient
Procedure PostAndClose(Command)
	
	TMCommonUseClient.PostAndClose(ThisForm, True);
	
EndProcedure

&AtClient
Procedure PaymentOffsetSender(Command)
	
	PlacePaymentDecryptionInTemporaryStorage();
	ARAPAccountingClient.PaymentSettlement(ThisForm, Items.PaymentOffsetSenderForm);
	
EndProcedure

&AtClient
Procedure PaymentOffsetRecipient(Command)
	
	PlacePaymentDecryptionInTemporaryStorage();
	ARAPAccountingClient.PaymentSettlement(ThisForm, Items.PaymentOffsetRecipientForm);
	
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

// StandardSubsystems.Properties
&AtClient
Procedure Attachable_PropertiesExecuteCommand(ItemOrCommand, Var_URL = Undefined, StandardProcessing = Undefined)
	PropertyManagerClient.ExecuteCommand(ThisObject, ItemOrCommand, StandardProcessing);
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
Procedure Attachable_CloseForm()
	
	If IsOpen() Then
		Close();
	EndIf;
	
EndProcedure


#EndRegion

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
	
	//

	ProductsServer.SetConditionalAppearanceOfUnitsOfMeasurement(ThisObject);

	//

	VATAccountingERP.EstablishConditionalAppearanceOfVATAmountsForSalesTaxation(ThisObject);
	
	//
	
	EnterprisePricesFillingServer.SetConditionalAppearancePriceIncludesVAT(ThisObject);

	//

	ProductsServer.EstablishConditionalAppearanceOfProductCharacteristics(ThisObject);

	//
	ConditionalDesignParameters = ProductsServer.ParametersForSettingConditionalAppearanceOfCCDNumber();
	ConditionalDesignParameters.NameOfFieldForEnteringCCDNumber = "GoodsCCDNumberOriginCountry";
	
	ProductsServer.SetConditionalAppearanceOfCCDNumber(ThisObject);
	ProductsServer.SetConditionalAppearanceOfCCDNumber(ThisObject, ConditionalDesignParameters);
	
	ConditionalDesignParameters = AccountingForTraceableGoodsLocalization.ParametersForSettingConditionalAppearanceOfCCDNumber();
	ConditionalDesignParameters.NameOfInputFieldCountryOfOrigin = "GoodsCCDNumberOriginCountry";
	AccountingForTraceableGoodsLocalization.SetConditionalAppearanceOfCCDNumber(ThisObject, ConditionalDesignParameters);
	
	//
	
	AccountingForTraceableGoodsLocalization.SetConditionalAppearanceOfQuantityAccordingToRNPT(ThisObject);

	//

	EnterprisePricesFillingServer.EstablishConditionalAppearanceOfPriceTypes(ThisObject, "ProductsPartnerPriceType");

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsCCDNumber.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsInventoryOwnerAttribute.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.ItemsType");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.ItemsTypes.OperationService;

	Item.Appearance.SetParameterValue("TextColor", StyleColors.TextColorOfCanceledRowOfDocument);
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<cho hàng hóa>';
													|ru = '<для товаров>';
													|en = '<for goods>'; fa = '<for goods>';
													|it = '<per le merci>';
													|pl = '<dla towarów>';
													|tr = '<ürünler için>'"));
	Item.Appearance.SetParameterValue("ReadOnly", True);

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

	// design of items and cost analytics

	// view only if the service

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsToExpenseAs.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.ItemsType");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.ItemsTypes.OperationService;

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

	Item.Appearance.SetParameterValue("Text", NStr("vi = '<khi ghi giảm vào chi phí>';
													|ru = '<при списании на расходы>';
													|en = '<when writing off as expenses>'; fa = '<when writing off as expenses>';
													|it = '<durante lo storno sulle spese>';
													|pl = '<przy wyksięgowaniu na rozchody>';
													|tr = '<gider yazılması>'"));
	Item.Appearance.SetParameterValue("TextColor", StyleColors.InaccessibleCellTextColor);

	// the mark of an unfilled division, if the Product

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

	Item.Appearance.SetParameterValue("MarkIncomplete", False);

	// the text of the expense analysis, if the item is not selected
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsDimensionOfExpenses.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.ExpenseItem");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.ToExpenseAs");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.EmptyTableField);
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<hãy chọn dạng chi phí>';
													|ru = '<выберите статью расходов>';
													|en = '<select an expense item>'; fa = '<select an expense item>';
													|it = '<selezionare la voce delle spese>';
													|pl = '<wybierz pozycję wydatków>';
													|tr = '<maliyet kalemini seçin>'"));

	ProductsServer.SetConditionalAppearanceOfProductAssignment(ThisObject);
	ProductsServer.EstablishConditionalAppearanceOfProductSeries(ThisObject, "SeriesAlwaysWHGoods");

	LinesOfBusinessServer.EstablishConditionalAppearanceOfDirectionOfActivity(ThisObject);
	
	// Filling the warehouse is mandatory if the tabular part contains goods or multi-turn containers that are not deductible for expenses.
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.Warehouse.Name);

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
	ItemFilter.LeftValue = New DataCompositionField("Object.Warehouse");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	Item.Appearance.SetParameterValue("MarkIncomplete", True);
	
	// otherwise, the Warehouse field is not required to be filled in.
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.Warehouse.Name);

	SelectionGroupOr = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	SelectionGroupOr.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
		
		ItemFilter = SelectionGroupOr.Items.Add(Type("DataCompositionFilterItem"));
		ItemFilter.LeftValue = New DataCompositionField("Object.Goods.ItemsType");
		ItemFilter.ComparisonType = DataCompositionComparisonType.NotInList;
		ValueList = New ValueList;
		ValueList.Add(Enums.ItemsTypes.OwnGoods);
		ValueList.Add(Enums.ItemsTypes.ReusablePackage);
		ItemFilter.RightValue = ValueList;
		
		ItemFilter = SelectionGroupOr.Items.Add(Type("DataCompositionFilterItem"));
		ItemFilter.LeftValue = New DataCompositionField("Object.Goods.ToExpenseAs");
		ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
		ItemFilter.RightValue = True;
		
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Warehouse");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	
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
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsAmountARAP.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Currency");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = New DataCompositionField("Object.ARAPCurrency");
	
	Item.Appearance.SetParameterValue("Visible", False)
	
EndProcedure

#Region OnChangeAttributes

&AtServer
Procedure OrganizationOnChangeServer()
	
	LocalAccountingCurrency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Object.Organization);
	
	SetParametersForSelectingRecipientOrganization();
	CheckAndClearRecipientOrganization();
	
	If ValueIsFilled(Object.Organization) Then
		
		If Object.ARAPAccountingViaSeparateCounterparty Then
			FillInDefaultSalesContract();
		Else
			FillInDefaultContract();
			
			If UseLinesOfBusiness Then
				LinesOfBusinessServer.FillInDefaultDirection(Object.LineOfBusiness,
																				Undefined,
																				Object.Contract);
			EndIf;
		EndIf;
		
		CompleteVATTaxation();
		
		UpdateInvoiceText();
		ConfigureIntermediaryInvoicePresentation();
		
	EndIf;
	
	CashServer.CheckFillInOrganizationSBankAccountByOwner(Object.Organization,
																					Object.CompanyBankAccount,
																					Undefined,
																					Object.LineOfBusiness,
																					Object.ForeignCurrencyTransaction);
	
	CashServer.CheckOrganizationSSalesRegisterByOwner(Object.Organization,
																		Object.CashAccount,
																		Undefined,
																		Object.LineOfBusiness);
	
	FillInSubordinatePropertiesForStatistics("Organization");
	
	FillInDefaultContractData();
	
	SetContractAvailability();
	SetAvailabilityOfSalesAgreement();
	
	ResponsiblePersonsServer.WhenChangingRelatedDocumentDetails(Object);
	
	RecalculateNumberOfRNPT();
	ClearPaymentDecryption();
	
	ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisForm, "Organization");
	
EndProcedure

&AtServer
Procedure CompanyRecipientOnChangeServer()
	
	If ValueIsFilled(Object.CompanyRecipient) Then
		
		If Object.ARAPAccountingViaSeparateCounterparty Then
			FillInDefaultPurchaseAgreement();
		Else
			FillInDefaultContract();
			
			If UseLinesOfBusiness Then
				LinesOfBusinessServer.FillInDefaultDirection(Object.LineOfBusiness,
																				Undefined,
																				Object.Contract);
			EndIf;
		EndIf;
		
		UpdateTransferForActivity();
		ConfigureIntermediaryInvoicePresentation();
		
		Object.DeliveryAddress = PrintFormGeneration.GetAddressFromContactInformation(
								Object.CompanyRecipient,
								"Actual",
								CurrentSessionDate());
		
	Else
		Object.DeliveryAddress = "";
	EndIf;
	
	FillInDefaultContractData();
	
	SetContractAvailability();
	SetAvailabilityOfPurchaseAgreement();
	
	CashServer.CheckFillInOrganizationSBankAccountByOwner(Object.CompanyRecipient,
																					Object.RecipientCompanyBankAccount,
																					Undefined,
																					Object.LineOfBusiness,
																					Object.ForeignCurrencyTransaction);
	
	CashServer.CheckOrganizationSSalesRegisterByOwner(Object.CompanyRecipient,
																			Object.CashAccountRecipient,
																			Undefined,
																			Object.LineOfBusiness);
	
	FillInSubordinatePropertiesForStatistics("CompanyRecipient");
	
	ClearPaymentDecryption();
	
EndProcedure

&AtServer
Procedure BusinessOperationOnChangeServer()
	
	FillInContractOperations();
	
	ThisIsImplementation = Object.BusinessOperation = Enums.BusinessTransactions.GoodsSaleToAnotherCompany;
	
	If Not ThisIsImplementation Then
		Object.SpecifyCCDNumbers = False;
	EndIf;
	
	If Not ValueIsFilled(Object.ARAPCurrency) Then
		Object.ARAPCurrency = Object.Currency;
	EndIf;
	
	If Object.BusinessOperation = Enums.BusinessTransactions.TransferOfGoodsToCommissionAgentInAnotherCompany Then
		Object.VATTaxation = Enums.VATTaxationTypes.EmptyRef();
	EndIf;
	
	CompleteVATTaxation();
	FormItemsManagement();
	SetStockTypeSelectionParameters();
	EstablishVisibilityOfRNPTQuantity();
	FillInArticleSelectionParameters();
	
	If Not Items.ProductsGroupQuantityByRNPT.Visible Then
		RecalculateNumberOfRNPT();
	EndIf;
	
	UpdateInvoiceText();
	ConfigureIntermediaryInvoicePresentation();
	
	If Object.BusinessOperation = Enums.BusinessTransactions.TransferOfGoodsToCommissionAgentInAnotherCompany Then
		Object.ARAPCurrency = Object.Currency;
	EndIf;
	
	UpdateTransferForActivity();
	
	FillInPaymentInDefaultCurrency();
	
	If Object.ARAPAccountingViaSeparateCounterparty Then
		FillInDefaultSalesContract();
		FillInDefaultPurchaseAgreement();
	Else
		FillInDefaultContract();
	EndIf;
	
	FillInDefaultContractData();
	
	Items.GroupCalculations.Visible = ThisIsImplementation;
	
	ClearPaymentDecryption();
	
	ARAPAccountingFormWork.WhenChangingParametersOfMechanism(ThisObject);
	
	
EndProcedure

&AtServer
Procedure ARAPAccountingViaSeparateCounterpartyOnChangeServer()
	
	UpdateInvoiceText();
	ConfigureIntermediaryInvoicePresentation();
	HideDisplayIntermediaryData();
	
	If Object.ARAPAccountingViaSeparateCounterparty Then
		FillInDefaultSalesContract();
		FillInDefaultPurchaseAgreement();
	Else
		FillInDefaultContract();
	EndIf;
	
	FillInDefaultContractData();
	
	ARAPAccountingFormWork.WhenChangingParametersOfMechanism(ThisForm);
	ContractOnChangeServer();
	
EndProcedure

&AtServer
Procedure PartnerOnChangeServer()
	
	PartnersAndCounterparties.FillInPartnerSDefaultCounterparty(Object.Partner, Object.Counterparty);
	
	CounterpartyOnChangeServer();
	
	ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisForm, "Partner");
	
EndProcedure

&AtServer
Procedure CounterpartyOnChangeServer()
	
	If ValueIsFilled(Object.Counterparty) Then
		FillInDefaultSalesContract();
		FillInDefaultPurchaseAgreement();
		
		SalesServer.PartnerOnChange(Object);
	EndIf;
	
	FillInDefaultContractData();
	
	SetAvailabilityOfSalesAgreement();
	SetAvailabilityOfPurchaseAgreement();
	
	ClearPaymentDecryption();
	
	ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisForm, "Counterparty");
	PurchasesServer.FillInSelectionListNameOfIncomingDocument(ThisObject, Object.Counterparty);
	
EndProcedure

&AtServer
Procedure ContractOnChangeServer()
	
	Contract = Object.Contract;
	ForeignCurrencyTransaction = Object.ForeignCurrencyTransaction;
	
	AttributesToFillIn_ = 
	"ARAPObjectSettings,
	|NameForPrinting,
	|Number,
	|Date,
	|LineOfBusiness,
	|Department,
	|ForeignCurrencyTransaction,
	|FinancialAccountingGroup,
	|FinancialAccountingGroupOfRecipient";
	
	AttributesToExclude	= "Number, Date";
	ContractDetails_		= Common.ObjectAttributesValues(Object.Contract, AttributesToFillIn_);
	
	FillPropertyValues(Object, ContractDetails_, , AttributesToExclude);
	
	Object.Basis		= ContractDetails_.NameForPrinting;
	Object.BaseDocumentNumber	= ContractDetails_.Number;
	Object.ReferenceDocumentDateForPrintForms	= ContractDetails_.Date;
	
	CompleteVATTaxation();
	UpdateTransferForActivity();
	
	If Object.ForeignCurrencyTransaction <> ForeignCurrencyTransaction Then
		Object.CompanyBankAccount = Catalogs.ExpenseReportAttachedFiles.EmptyRef();
		Object.RecipientCompanyBankAccount = Catalogs.CompaniesBankAccounts.EmptyRef();
	EndIf;
	
	SalesServer.FillInBankAccountsUnderAgreement(Object.Contract,
													Object.CompanyBankAccount,
													Object.RecipientCompanyBankAccount);
	
	If UseLinesOfBusiness Then
		LinesOfBusinessServer.FillInDefaultDirection(Object.LineOfBusiness,
																		Undefined,
																		Object.Contract);
	EndIf;
	
	FillInBankAccountsByDefaultServer();
	
	ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisForm, "Contract");
	
	FillInSubordinatePropertiesForStatistics("Contract");
	ClearPaymentDecryption();
	
	ResponsiblePersonsServer.FillInManager_(Object);
	
EndProcedure

&AtServer
Procedure SalesContractOnChangeServer(CompleteVATTaxation = True)
	
	SalesContract = Object.SalesContract;
	
	If CompleteVATTaxation Then
		CompleteVATTaxation();
	EndIf;
	
	SalesServer.FillInBankAccountsUnderAgreement(Object.SalesContract,
													Object.CompanyBankAccount);
	
	ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisForm, "SalesContract");
	ARAPAccountingFormWork.WhenChangingParametersOfMechanism(ThisForm);
	
	SalesServer.EstablishProcedureForSettlementsBetweenOrganizations(Object);
	
EndProcedure

&AtServer
Procedure PurchasingContractOnChangeServer(UpdateTransferForActivity = True)
	
	PurchasingContract = Object.PurchasingContract;
	
	If UpdateTransferForActivity Then
		UpdateTransferForActivity();
	EndIf;
	
	PurchasesServerCall.FillInBankAccountsUnderAgreement(Object.PurchasingContract,
															Object.RecipientCompanyBankAccount);
	
	ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisForm, "PurchasingContract");
	ARAPAccountingFormWork.WhenChangingParametersOfMechanism(ThisForm);
	
	SalesServer.EstablishProcedureForSettlementsBetweenOrganizations(Object);
	
EndProcedure

&AtServer
Procedure FillInSubordinatePropertiesForStatistics(ParentPropsName)
	
	ObjectsFillingByStatistics.FillInSubordinateDetailsOfObject(Object, ParentPropsName);
	
EndProcedure

&AtServer
Procedure PriceIncludesVATOnChangeServer(CachedValues)
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForRecalculatingNDSWTCHAmount(Object);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("ClearAmountOfSettlements");
	BatchProcessingOfTablePartServer.TreatTS(Object.Goods, StructureOfActions, CachedValues);

	CalculateFinalIndicatorsOfTransferOfGoodsBetweenOrganizations(ThisForm);
	
EndProcedure

&AtServer
Procedure WarehouseOnChangeServer()
	
	SetFormFunctionalOptionParameters(New Structure("Warehouse", Object.Warehouse));
	SeriesSpecificationParameters = New FixedStructure(ProductsServer.SeriesSpecificationParameters(Object,
																									Documents.CustomerInvoiceIntercompany));
	
	ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);
	
	CompleteVATTaxation();
	UpdateTransferForActivity();
	
	StructureOfResponsible = SalesServer.GetWarehouseManager(Object.Warehouse);
	If StructureOfResponsible <> Undefined Then
		Object.IssuiedBy = StructureOfResponsible.EmployeeResponsible;
		Object.IssuiedByJobTitle = StructureOfResponsible.ResponsiblePosition;
	EndIf;
	
	RecalculateNumberOfRNPT();
	
EndProcedure

&AtServer
Procedure VATTaxationOnChangeServer()
	
	CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInVATRateByPriceType", BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRateByPriceType(Object));
	StructureOfActions.Insert("AdjustVATRate",  BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRate(Object));
	BatchProcessingOfTablePartServer.TreatTS(Object.Goods, StructureOfActions, CachedValues);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateVATAmount",  BatchProcessingOfTablePartClientServer.ParametersForRecalculatingNDSWTCHAmount(Object));
	StructureOfActions.Insert("RecalculateAmountWithVAT", New Structure("PriceIncludesVAT", Object.PriceIncludesVAT));
	
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		CachedValues.ProcessedRows,
		StructureOfActions,
		Object.Goods,
		Undefined);
	
	ConfigureIntermediaryInvoicePresentation();
	CalculateFinalIndicatorsOfTransferOfGoodsBetweenOrganizations(ThisForm);
	FormItemsManagement();
	
EndProcedure

&AtClientAtServerNoContext
Procedure AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions, Object)
	
	StructureOfActions.Insert("RecalculateNumberOfUnits");
	StructureOfActions.Insert("RecalculateVATAmount", BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object));
	StructureOfActions.Insert("RecalculateAmount");
	StructureOfActions.Insert("RecalculateAmountWithVAT", New Structure("PriceIncludesVAT", Object.PriceIncludesVAT));
	StructureOfActions.Insert("ClearAmountOfSettlements");
	
	AccountingForTraceableGoodsClientServerLocalization.AddDescriptionOfSettingsForRecalculatingDetailsOfTablePart(
		Object,
		StructureOfActions);
	
EndProcedure

&AtServer
Procedure DateOnChangeServer()
	
	UseTraceableImportedGoodsAccounting = AccountingForTraceableGoodsLocalization.UseTraceableImportedGoodsAccounting(
														Object.Date);
	
	CompleteVATTaxation();
	EstablishVisibilityOfRNPTQuantity();
	
	If Not Items.ProductsGroupQuantityByRNPT.Visible Then
		RecalculateNumberOfRNPT();
	EndIf;
	
	ResponsiblePersonsServer.WhenChangingRelatedDocumentDetails(Object);
	
	ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisForm, "Date");
	
EndProcedure

&AtServer
Procedure LineOfBusinessOnChangeServer()
	
	If ValueIsFilled(Object.LineOfBusiness) Then
		AttributesStructure1 = Common.ObjectAttributesValues(Object.LineOfBusiness, "IncomeAccounting, CostAccounting");
		If Not (AttributesStructure1.IncomeAccounting Or AttributesStructure1.CostAccounting) Then
			Object.LineOfBusiness = Catalogs.LinesOfBusiness.EmptyRef();
		EndIf;
	EndIf;
	
	CompleteVATTaxation();
	ClearPaymentDecryption();
	
EndProcedure

&AtServer
Procedure SpecifyCCDNumbersOnChangeServer()
	
	EstablishVisibilityOfRNPTQuantity();
	
	If Not Items.ProductsGroupQuantityByRNPT.Visible Then
		RecalculateNumberOfRNPT();
	EndIf;
	
EndProcedure

&AtServer
Procedure DocumentAmountOnChangeServer(DocumentAmount)
	
	RecalculationParameters = PriceManagementSystem.ParametersForRecalculationOfTableAmountsONChangeOfExchangeRate(Object.PriceIncludesVAT, DocumentAmount);
	
	PriceManagementSystem.RecalculateTableAmountsONChangeOfExchangeRate(
		Object.Goods,
		RecalculationParameters);
	
EndProcedure

#EndRegion

#Region SelectionAndProcessingOfQuantityVerification

&AtServer
Function PutProductsInStorage(Val Goods, Var_UUID)

	AddressInStorage = PutToTempStorage(
		Goods.Unload(,"Products, Characteristic, Series, Purpose, Count"),
		Var_UUID);
		
	Return AddressInStorage;
	
EndFunction

&AtServer
Function PutGoodsAndStockTypesInStorage()
	
	OptionsForEditingInventoryTypes = InventoriesServer.OptionsForEditingInventoryTypes();
	If Documents.CustomerInvoiceIntercompany.ExcisableGoodsAreUsed(Object) Then
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
Procedure GetProductsFromStorage(AddressInStorage)
	
	TableOfGoods = GetFromTempStorage(AddressInStorage);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInVATRate", BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRate(Object));
	
	RowsToProcess = New Array;
	
	For Each RowOfProduct In TableOfGoods Do
		CurrentRow = Object.Goods.Add();
		FillPropertyValues(CurrentRow, RowOfProduct);
		
		// Selection of articles and analytics.
		IncomeAndExpensesClientServer.WhenAddingRowToTable(ThisObject, CurrentRow, "Object.Goods");
		
		RowsToProcess.Add(CurrentRow);
		
	EndDo;
	
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		RowsToProcess,
		StructureOfActions,
		Object.Goods);
		
	FillInServiceDetailsForProductRange();
	
	StructureOfActions = New Structure;
	
	AccountingForTraceableGoodsClientServerLocalization.AddDescriptionOfSettingsForRecalculatingDetailsOfTablePart(
		Object,
		StructureOfActions);
	
	BatchProcessingOfTablePartServer.TreatTS(Object.Goods, StructureOfActions, Undefined);
	
	FillParameters = New Structure;
	FillParameters.Insert("Date",           Object.Date);
	FillParameters.Insert("Organization",    Object.Organization);
	FillParameters.Insert("Currency",         Object.Currency);
	FillParameters.Insert("PriceKind",        Object.PriceKind);
	FillParameters.Insert("PopulationFields", "Price, PriceKind");
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateAmount",     "NumberOfPackages");
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateVATAmount",  StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("FillInVATRateByPriceType", BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRateByPriceType(Object));
	
	EnterprisePricesFillingServer.FillInPrices(Object.Goods, Undefined, FillParameters, StructureOfActions);
	
	ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);
	PurchasesServer.FillInServiceAttributesOfCCDNumber(Object.Goods);

	CalculateFinalIndicatorsOfTransferOfGoodsBetweenOrganizations(ThisObject);
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
	
	StructureOfActionsWithAddedStrings = New Structure;
	StructureOfActionsWithAddedStrings.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
	StructureOfActionsWithAddedStrings.Insert("FillInFeatureAttribute", New Structure("Products", "ItemVariantsAreUsed"));
	StructureOfActionsWithAddedStrings.Insert("FillInCCDTrackingAttribute", New Structure("Products", "TheRecordsAreKeptByCCD"));
	StructureOfActionsWithAddedStrings.Insert("FillInPriceView", New Structure("PriceKind", Object.PriceKind));
	StructureOfActionsWithAddedStrings.Insert("FillInSalePrice", BatchProcessingOfTablePartClientServer.ParametersForFillingInPriceInTSLine(Object));
	StructureOfActionsWithAddedStrings.Insert("FillInVATRate", BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRate(Object));
	StructureOfActionsWithAddedStrings.Insert("FillInVATRateByPriceType", BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRateByPriceType(Object));
	StructureOfActionsWithAddedStrings.Insert("CheckSeriesCalculateStatus", New Structure("Warehouse, SeriesSpecificationParameters", Object.Warehouse, SeriesSpecificationParameters));
	BatchProcessingOfTablePartClientServerLocalization.CompleteActionStructureWhenChangingElement(
		ThisObject, "Products", StructureOfActionsWithAddedStrings);
	AccountingForTraceableGoodsClientServerLocalization.CompleteDescriptionOfSettingsForFillingInServiceDetailsOfTablePart(StructureOfActionsWithAddedStrings);
	AddActionsToStructureWhenChangingPackagesNumber(StructureOfActionsWithAddedStrings, Object);
	
	StructureOfActionsWithModifiedStrings = New Structure;
	AddActionsToStructureWhenChangingPackagesNumber(StructureOfActionsWithModifiedStrings, Object);
	
	StructureOfActions = BarcodingOfItemsClient.BarcodeProcessingParameters();
	StructureOfActions.Barcodes                              = BarcodeData_5;
	StructureOfActions.StructureOfActionsWithAddedStrings = StructureOfActionsWithAddedStrings;
	StructureOfActions.StructureOfActionsWithModifiedStrings  = StructureOfActionsWithModifiedStrings;
	StructureOfActions.SeriesSpecificationParameters                 = SeriesSpecificationParameters;
	
	ProcessBarcodesServer(StructureOfActions, CachedValues);
	
	BarcodingOfItemsClient.ProcessUnknownBarcodes(StructureOfActions, CachedValues, ThisObject);
	
	CalculateFinalIndicatorsOfTransferOfGoodsBetweenOrganizations(ThisObject);
	
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

&AtClient
Procedure ProductsSeriesRecalculatePrices(CurrentRow = Undefined)

	If CurrentRow = Undefined Then
		CurrentRow = Items.Goods.CurrentData;
	EndIf;

	If PriceManagementSystemClient.ItIsNecessaryToRecalculatePriceWhenChanging(CurrentRow.Products, "Series", Object.Date) Then

		StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);

		StructureOfActions = New Structure;
		StructureOfActions.Insert("FillInSalePrice",
			BatchProcessingOfTablePartClientServer.ParametersForFillingInPriceInTSLine(Object));
		StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
		StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
		StructureOfActions.Insert("RecalculateAmount");
		StructureOfActions.Insert("ClearAmountOfSettlements");

		BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);

		CalculateFinalIndicatorsOfTransferOfGoodsBetweenOrganizations(ThisObject);

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
		AddActionsToStructureWhenChangingPackagesNumber(ProcessingActions, Object);
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
	
	CalculateFinalIndicatorsOfTransferOfGoodsBetweenOrganizations(ThisObject);
	
EndProcedure

&AtServer
Procedure FillInCCDNumbersOnServer(Val CCDNumber, CCDNumbersFilledIn)
	
	PurchasesServer.FillInGTNumbersInTabularPart(
		Object.Goods,
		CCDNumber,
		Items.Goods.SelectedRows,
		CCDNumbersFilledIn);
	
EndProcedure

#EndRegion

#Region Goods

&AtClient
Procedure GoodsAtEndOfEditingForServerCall()
	
	GoodsAtEndOfEditingOnServer();
	
EndProcedure

&AtServer
Procedure GoodsAtEndOfEditingOnServer()
	
	FormEvents.WhenChangingElement(ThisObject, "Goods");
	
EndProcedure

&AtServer
Procedure ProductsAfterDeletionOnServer()
	
	FormEvents.WhenChangingElement(ThisObject, "Goods");
	
EndProcedure

#EndRegion

#Region Other

&AtServer
Procedure OnReadCreateAtServer()
	
	UsePartnersAsCounterparties	= GetFunctionalOption("UsePartnersAsCounterparties");
	UseLinesOfBusiness		= GetFunctionalOption("UseIncomeAccountingByLinesOfBusiness")
												Or GetFunctionalOption("UseCostAccountingByLinesOfBusiness");
	UseBranchOfficesWithSeparateBalanceSheets = GetFunctionalOption("UseBranchOfficesWithSeparateBalanceSheets");
	UseTraceableImportedGoodsAccounting = AccountingForTraceableGoodsLocalization.UseTraceableImportedGoodsAccounting(
														Object.Date);
	
	DocumentCurrency = Object.Currency;
	LocalAccountingCurrency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Object.Organization);
	
	Contract			= Object.Contract;
	SalesContract	= Object.SalesContract;
	PurchasingContract	= Object.PurchasingContract;
	
	FillInContractOperations();
	SetStockTypeSelectionParameters();
	CheckAndClearRecipientOrganization();
	FillInServiceDetailsForProductRange();
	
	SetContractAvailability();
	SetAvailabilityOfSalesAgreement();
	SetAvailabilityOfPurchaseAgreement();
	
	FormItemsManagement();
	CalculateFinalIndicatorsOfTransferOfGoodsBetweenOrganizations(ThisObject);
	
	UpdateInvoiceText();
	ConfigureIntermediaryInvoicePresentation();
	
	UpdateTransferForActivity(False);
	SetFormFunctionalOptionParameters(New Structure("Warehouse", Object.Warehouse));
	
	SeriesSpecificationParameters = New FixedStructure(ProductsServer.SeriesSpecificationParameters(Object,
																									Documents.CustomerInvoiceIntercompany));
	PurchasesServer.FillInServiceAttributesOfCCDNumber(Object.Goods);
	
	ChangedPaymentServer(Undefined, Undefined);
	
	FillParameters = Documents.CustomerInvoiceIntercompany.ParametersForFillingInVATTaxation_(Object);
	VATAccountingERP.FillInSalesVATTaxSelectionList(Items.VATTaxation,
															Object.VATTaxation,
															FillParameters,
															VATAccountingCachedParameterValues);
	PurchasesServer.FillInSelectionListNameOfIncomingDocument(ThisObject, Object.Counterparty);
	ProcessingOfTabularForms.InitializeRowCache(Items.Goods);
	
EndProcedure

&AtServer
Procedure FillInServiceDetailsForProductRange()
	
	ParametersForFillingInBankingDetails = New Structure;
	ParametersForFillingInBankingDetails.Insert("FillInFeatureAttribute",
											New Structure("Products", "ItemVariantsAreUsed"));
	ParametersForFillingInBankingDetails.Insert("FillInProductTypeAttribute_",
											New Structure("Products", "ItemsType"));
	ParametersForFillingInBankingDetails.Insert("FillInCCDTrackingAttribute",
											New Structure("Products", "TheRecordsAreKeptByCCD"));
	BatchProcessingOfTablePartClientServerLocalization.CompleteActionStructureWhenChangingElement(
		ThisObject, "Products", ParametersForFillingInBankingDetails);
	AccountingForTraceableGoodsClientServerLocalization.CompleteDescriptionOfSettingsForFillingInServiceDetailsOfTablePart(ParametersForFillingInBankingDetails);
	
	ProductsServer.FillInServiceDetailsForProductInCollection(Object.Goods,ParametersForFillingInBankingDetails);
	
EndProcedure

&AtServer
Procedure FormItemsManagement()
	
	Var AllAttributes;
	Var TransactionDetails;
	
	SetParametersForSelectingRecipientOrganization();
	
	Documents.CustomerInvoiceIntercompany.FillInNamesOfBusinessTransactionDetails(
		Object.BusinessOperation,
		AllAttributes,
		TransactionDetails,
		False);
	
	CashServer.SetVisibilityOfElementsByArray(
		Items,
		AllAttributes,
		TransactionDetails);
	
	ThisIsImplementation = Object.BusinessOperation = Enums.BusinessTransactions.GoodsSaleToAnotherCompany;
	
	ItemsTypes = ?(ThisIsImplementation,
						New FixedArray(ProductsClientServer.SelectionByProductReusablePackagingServiceWork(False)),
						New FixedArray(ProductsClientServer.SelectionByProductMultiTurnContainer(False)));
	
	ProductSelectionParameters = New Array;
	ProductSelectionParameters.Add(New ChoiceParameter("Filter.ItemsType", ItemsTypes));
	
	Items.GoodsProducts.ChoiceParameters = New FixedArray(ProductSelectionParameters);
	
	Items.GoodsSelectByNegativeInventory.Visible = ThisIsImplementation;
	
	// The availability of elements depends on the "Specify GTD numbers" checkbox.
	Items.GoodsCCDNumber.Visible = Object.SpecifyCCDNumbers;
	Items.GoodsCCDNumberOriginCountry.Visible = Object.SpecifyCCDNumbers;
	Items.GoodsFillInCCDNumbers.Visible = Object.SpecifyCCDNumbers;
	
	// The availability of elements depends on the checkbox "Settlements through a separate counterparty".
	Items.IncomingDocumentGroup.Visible = Object.ARAPAccountingViaSeparateCounterparty;

	VATAccountingERP.SetVisibilityOfCommandAndFillInVATRate(ThisObject);

EndProcedure

&AtServer
Procedure FillInArticleSelectionParameters()
	
	// Selection of articles and analytics.
	ItemsAndDimensionsSelectionParameters = Documents.CustomerInvoiceIntercompany.ItemsAndDimensionsSelectionParameters(
										Object.BusinessOperation);
	IncomeAndExpensesServer.WhenChangingArticleSelectionParameters(ThisObject, ItemsAndDimensionsSelectionParameters);
	
EndProcedure

&AtClientAtServerNoContext
Procedure CalculateFinalIndicatorsOfTransferOfGoodsBetweenOrganizations(Form)
	
	Form.AmountTotal = Form.Object.Goods.Total("Sum");
		
	If Not Form.Object.PriceIncludesVAT Then
		Form.AmountTotal = Form.AmountTotal + Form.Object.Goods.Total("VATAmount");
	EndIf;
	
	If Not VATAccountingERPClientServer.DisplayNDSInResultsOfSalesDocument(Form.Object.VATTaxation) Then
		Form.Items.VATPageGroup.CurrentPage   = Form.Items.PageExcludingVAT;
		Form.Items.PagesTotalGroup.CurrentPage = Form.Items.PageTotalWithoutVAT;
	Else
		Form.Items.VATPageGroup.CurrentPage   = Form.Items.PageVAT;
		Form.Items.PagesTotalGroup.CurrentPage = Form.Items.TotalSNDSPage;
	EndIf;
	
EndProcedure

&AtServer
Function FillInPricesByPriceKindServer(PricesKind)
	
	FillParameters = New Structure();
	FillParameters.Insert("Date", Object.Date);
	FillParameters.Insert("Organization", Object.Organization);
	FillParameters.Insert("Currency", Object.Currency);
	FillParameters.Insert("PriceKind", PricesKind);
	FillParameters.Insert("PopulationFields", "Price, PriceKind");
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	
	StructureOfActions = New Structure();
	StructureOfActions.Insert("RecalculateAmount", "NumberOfPackages");
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("ClearAmountOfSettlements");
	StructureOfActions.Insert("FillInVATRateByPriceType", BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRateByPriceType(Object));
	
	PricesCalculated = EnterprisePricesFillingServer.FillInPrices(Object.Goods, , FillParameters, StructureOfActions);
	
	CalculateFinalIndicatorsOfTransferOfGoodsBetweenOrganizations(ThisObject);
	
	Return PricesCalculated;
	
EndFunction

&AtServer
Function FillInPricesOfSelectedRowsByPriceTypeServer(PricesKind)
	
	RowsArray = New Array;
	For Each String In Items.Goods.SelectedRows Do
		RowsArray.Add(Object.Goods.FindByID(String));
	EndDo;
	
	FillParameters = New Structure();
	FillParameters.Insert("Date", Object.Date);
	FillParameters.Insert("Organization", Object.Organization);
	FillParameters.Insert("Currency", Object.Currency);
	FillParameters.Insert("PriceKind", PricesKind);
	FillParameters.Insert("PopulationFields", "Price, PriceKind");
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	
	StructureOfActions = New Structure();
	StructureOfActions.Insert("RecalculateAmount", "NumberOfPackages");
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("ClearAmountOfSettlements");
	StructureOfActions.Insert("FillInVATRateByPriceType", BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRateByPriceType(Object));
	
	PricesCalculated = EnterprisePricesFillingServer.FillInPrices(Object.Goods, RowsArray, FillParameters, StructureOfActions);
	
	CalculateFinalIndicatorsOfTransferOfGoodsBetweenOrganizations(ThisObject);
	
	Return PricesCalculated;
	
EndFunction

&AtServer
Procedure ConfigureIntermediaryInvoicePresentation()
	
	RegistrationParameters = Documents.CustomerInvoiceIntercompany.ParametersForRegisteringInvoicesReceived(Object);
	InvoicesReceivedOnBasisOf = VATAccountingERP.InvoicesReceivedOnBasisOf(RegistrationParameters);
	
	TextIntermediaryInvoice = InvoicesReceivedOnBasisOf.Presentation;
	
	Items.IntermediarySInvoiceGroup.Visible = Not InvoicesReceivedOnBasisOf.Invoices_.Count() = 0
														Or Not Object.ARAPAccountingViaSeparateCounterparty
															And Object.VATTaxation = Enums.VATTaxationTypes.SubjectToVATAtCustomer;
	
EndProcedure

&AtServer
Procedure SetParametersForSelectingRecipientOrganization()
	
	RecipientSelectionParameters = New Array;
	
	If ValueIsFilled(Object.Organization) Then
		CurrencySelectionParameterAccountingReg = New ChoiceParameter("Filter.LocalAccountingCurrency",
															LocalAccountingCurrency);
		CountryOfRegistrationSelectionParameter = New ChoiceParameter("Filter.RegistrationCountry",
				Common.ObjectAttributeValue(Object.Organization, "RegistrationCountry"));
		
		RecipientSelectionParameters.Add(CurrencySelectionParameterAccountingReg);
		RecipientSelectionParameters.Add(CountryOfRegistrationSelectionParameter);
		
		If UseBranchOfficesWithSeparateBalanceSheets Then
			OrganizationChoiceParameter = New ChoiceParameter("ModeForSelectingRelatedOrganizations",
															"JustNotInterconnected");
			
			RecipientSelectionParameters.Add(OrganizationChoiceParameter);
		EndIf;
	EndIf;
	
	Items.CompanyRecipient.ChoiceParameters = New FixedArray(RecipientSelectionParameters);
	
EndProcedure

&AtServer
Procedure CheckAndClearRecipientOrganization()
	
	If ValueIsFilled(Object.Organization)
		And ValueIsFilled(Object.CompanyRecipient) Then
			
			CheckStructure = Catalogs.Companies.CountriesOfRegistrationAndCurrenciesOfRegulatedAccountingCoincide(Object.Organization, Object.CompanyRecipient);
			If (UseBranchOfficesWithSeparateBalanceSheets
				And Catalogs.Companies.OrganizationsAreInterconnectedByOrganizationalStructure(Object.Organization, Object.CompanyRecipient))
				Or (Not CheckStructure.CurrenciesDoNotMatch Or Not CheckStructure.CountriesMatch) Then
					Object.CompanyRecipient = Undefined;
			EndIf;
			
	EndIf
	
EndProcedure

&AtServer
Function AddressOfObjectInTemporaryStorage()
	
	ObjectStructure = New Structure;
	
	For Each Attribute In Metadata.Documents.CustomerInvoiceIntercompany.Attributes Do
		
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
	ParametersStructure.Insert("DeliveryAddress",                  Object.DeliveryAddress);
	ParametersStructure.Insert("ShipperBankAccount", Object.ShipperBankAccount);
	ParametersStructure.Insert("GoodsRecipientBankAccount",  Object.GoodsRecipientBankAccount);
	ParametersStructure.Insert("CounterpartyBankAccount",      Object.CounterpartyBankAccount);
	ParametersStructure.Insert("Shipper",               Object.Shipper);
	ParametersStructure.Insert("GoodsRecipient",                Object.GoodsRecipient);
	ParametersStructure.Insert("LetterOfAuthorityIssuedBy",             Object.LetterOfAuthorityIssuedBy);
	ParametersStructure.Insert("PowerOfAttorneyDate",               Object.PowerOfAttorneyDate);
	ParametersStructure.Insert("PowerOfAttorneyPerson",               Object.PowerOfAttorneyPerson);
	ParametersStructure.Insert("PowerOfAttorneyNumber",              Object.PowerOfAttorneyNumber);
	ParametersStructure.Insert("Partner",                        Object.Partner);
	ParametersStructure.Insert("BusinessOperation",          Object.BusinessOperation);
	ParametersStructure.Insert("Counterparty",                     Object.Counterparty);
	ParametersStructure.Insert("CompanyRecipient",          Object.CompanyRecipient);
	ParametersStructure.Insert("RecipientCompanyBankAccount", Object.RecipientCompanyBankAccount);
	ParametersStructure.Insert("ReadOnly",                 ReadOnly);
	ParametersStructure.Insert("ShowTTNDetails",         ShowTTNDetails);
	ParametersStructure.Insert("ObjectType",                     "CustomerInvoiceIntercompany");
	ParametersStructure.Insert("AddressOfObjectInTemporaryStorage", AddressOfObjectInTemporaryStorage());
	ParametersStructure.Insert("PaymentsThroughTheOrganization",          Not Object.ARAPAccountingViaSeparateCounterparty);
	ParametersStructure.Insert("Organization",                    Object.Organization);
	ParametersStructure.Insert("Date",                           Object.Date);
	ParametersStructure.Insert("Director",                   Object.Director);
	ParametersStructure.Insert("ChiefAccountant",               Object.ChiefAccountant);
	ParametersStructure.Insert("CompanyBankAccount",      Object.CompanyBankAccount);
	ParametersStructure.Insert("Basis",                      Object.Basis);
	ParametersStructure.Insert("ReferenceDocumentDateForPrintForms",                  Object.ReferenceDocumentDateForPrintForms);
	ParametersStructure.Insert("BaseDocumentNumber",                 Object.BaseDocumentNumber);
	
	AttributesArray = New Array;
	AttributesArray.Add("IssuiedBy");
	AttributesArray.Add("IssuiedByJobTitle");
	ParametersStructure.Insert("DoNotShowBankDetails", AttributesArray);
	
	OpenForm("CommonForm.PrintingDetailsOfSales", ParametersStructure, ThisForm,,,, Undefined, FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtServer
Procedure UpdateTransferForActivity(Fill = True)
	
	FillParameters = Documents.CustomerInvoiceIntercompany.ParametersForFillingInVATActivityType(Object);
	
	If Fill Then
		VATAccountingERP.FillInTypeOfActivityVAT(Object.TransferForActivity_,
												FillParameters,
												VATAccountingCachedParameterValues);
	EndIf;
	
	VATAccountingERP.FillInActivitySelectionList(Items.TransferForActivity_,
														Object.TransferForActivity_,
														FillParameters,
														VATAccountingCachedParameterValues);
	
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
							|tr = '%1 (oluşturma)'");
		EndIf;
		TextHeader = NStr("vi = 'Biên bản chuyển giao quyền giữa các doanh nghiệp';
							|ru = 'Акт на передачу прав между организациями';
							|en = 'Deed of transfer between companies'; fa = 'Deed of transfer between companies';
							|it = 'Atto di trasferimento dei diritti tra società';
							|pl = 'Protokół o przeniesieniu praw między firmami';
							|tr = 'İş yerleri arasında devir senedi'");
		Title = StringFunctionsClientServer.SubstituteParametersToString(Template, TextHeader, Object.Number, Object.Date);
	Else
		AutoTitle = True;
		Title = "";
	EndIf;
	
EndProcedure

&AtServer
Procedure SetTitleOfPrintDetails()
	
	If GetFunctionalOption("UseDeedsOfTransfer") Then
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
Procedure UpdateInvoiceText()
	
	RegistrationParameters = Documents.CustomerInvoiceIntercompany.ParametersForRegisteringInvoicesIssued(Object);
	InvoicesIssuedOnBasisOf = VATAccountingERP.InvoicesIssuedOnBasisOf(RegistrationParameters);
	
	TextInvoice = InvoicesIssuedOnBasisOf.Presentation;
	
	Items.GroupIssuedTaxInvoice.Visible = Not Object.ARAPAccountingViaSeparateCounterparty
													Or InvoicesIssuedOnBasisOf.Invoices_.Count() > 0;
	
EndProcedure

&AtServer
Procedure ClearPaymentDecryption()
	
	Object.ARAPDetailsWithCustomer.Clear();
	Object.ARAPDetailsWithVendor.Clear();
	
EndProcedure

&AtServerNoContext
Function GetFinancialAccountingGroups(Organization, ARAPCurrency, BusinessOperation)
	
	Result = New Structure;
	
	Result.Insert("FinancialAccountingGroup", Catalogs.FinancialAccountingGroupsOfARAP.GetDefaultFinancialAccountingGroup(Organization, ARAPCurrency, BusinessOperation));
	Result.Insert("FinancialAccountingGroupOfRecipient", Catalogs.FinancialAccountingGroupsOfARAP.GetDefaultFinancialAccountingGroup(Organization, ARAPCurrency, BusinessOperation, True));
	
	Return Result;
	
EndFunction

&AtServer
Procedure FillInPaymentInDefaultCurrency()
	
	FinancialAccountingGroups = GetFinancialAccountingGroups(Object.Organization, Object.ARAPCurrency, Object.BusinessOperation);
	Object.FinancialAccountingGroup = FinancialAccountingGroups.FinancialAccountingGroup;
	Object.FinancialAccountingGroupOfRecipient = FinancialAccountingGroups.FinancialAccountingGroupOfRecipient;
	
EndProcedure

#EndRegion

#Region WorkingWithCounterparties



&AtClient
Procedure CheckCounterparties(Command)
	
	
EndProcedure

#EndRegion

&AtServer
Procedure HideDisplayIntermediaryData()
	
	Items.Partner.Visible = Object.ARAPAccountingViaSeparateCounterparty;
	Items.Counterparty.Visible = Object.ARAPAccountingViaSeparateCounterparty;
	
	Items.Contract.Visible = Not Object.ARAPAccountingViaSeparateCounterparty;
	Items.SalesContract.Visible = Object.ARAPAccountingViaSeparateCounterparty;
	Items.PurchasingContract.Visible = Object.ARAPAccountingViaSeparateCounterparty;
	
	Items.IncomingDocumentGroup.Visible = Object.ARAPAccountingViaSeparateCounterparty;
	
	If Object.ARAPAccountingViaSeparateCounterparty Then
		Object.Contract = Undefined;
	Else
		Object.SalesContract = Undefined;
		Object.PurchasingContract = Undefined;
	EndIf;
	
EndProcedure

&AtServer
Procedure FillInContractOperations()
	
	ContractType = ?(Object.BusinessOperation = Enums.BusinessTransactions.GoodsSaleToAnotherCompany,
					Enums.TypesOfIntercompanyContracts.PurchaseAndSale,
					Enums.TypesOfIntercompanyContracts.Consignment);
	
	EconomicOperationOfSaleAgreement = ?(Object.BusinessOperation = Enums.BusinessTransactions.GoodsSaleToAnotherCompany,
											Enums.BusinessTransactions.SaleToCustomer,
											Enums.BusinessTransactions.TransferToCommissionAgent);
	
	BusinessTransactionOfPurchaseAgreement = ?(Object.BusinessOperation = Enums.BusinessTransactions.GoodsSaleToAnotherCompany,
											Enums.BusinessTransactions.PurchaseFromSupplier,
											Enums.BusinessTransactions.ConsignmentProcurement);
	
EndProcedure

&AtServer
Procedure SetStockTypeSelectionParameters()
	
	AttributeChoiceParameterLinks = New Array;
	AttributeChoiceParameterLinks.Add(New ChoiceParameterLink("Filter.Organization",
																		"Object.CompanyRecipient"));
	AttributeChoiceParameterLinks.Add(New ChoiceParameterLink("Filter.BusinessOperation",
																		"Object.BusinessOperation"));
	AttributeChoiceParameterLinks.Add(New ChoiceParameterLink("Filter.Products",
																		"Items.Goods.CurrentData.Products"));
	AttributeChoiceParameterLinks.Add(New ChoiceParameterLink("Filter.VATTaxation",
																		"Object.TransferForActivity_"));
	
	If Object.BusinessOperation = Enums.BusinessTransactions.TransferOfGoodsToCommissionAgentInAnotherCompany Then
		AttributeChoiceParameterLinks.Add(New ChoiceParameterLink("Filter.Contract",
																			"Object.Contract"));
	EndIf;
	
	Items.GoodsInventoryOwnerAttribute.ChoiceParameterLinks = New FixedArray(AttributeChoiceParameterLinks);
	
EndProcedure

&AtServer
Procedure FillInDefaultContractData()
	
	Object.ARAPObjectSettings = ARAPAccountingServer.DefaultCalculationOrder(Object);
	
	AttributesToFillIn_	= "NameForPrinting, Number, Date,";
	ContractDetails_		= Common.ObjectAttributesValues(Object.Contract, AttributesToFillIn_);
	
	Object.Basis		= ContractDetails_.NameForPrinting;
	Object.BaseDocumentNumber	= ContractDetails_.Number;
	Object.ReferenceDocumentDateForPrintForms	= ContractDetails_.Date;
	
EndProcedure

&AtServer
Procedure FillInDefaultContract()
	
	If Object.ARAPObjectSettings = Enums.ARAPObjectSettings.ByCounterpartyContracts Then
		DefaultContract = SalesServer.GetDefaultAgreementBetweenOrganizations(Object,
																						ContractType,
																						Object.ARAPCurrency,
																						Object.LineOfBusiness);
	Else
		DefaultContract = SalesServer.GetDefaultAgreementBetweenOrganizations(Object,
																						ContractType,
																						Object.ARAPCurrency);
	EndIf;
	
	If Contract <> DefaultContract
		Or Not ValueIsFilled(Object.Contract) Then
		
		Object.Contract = DefaultContract;
		ForeignCurrencyTransaction = Object.ForeignCurrencyTransaction;
		ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisObject, "Contract");
		If ForeignCurrencyTransaction <> Object.ForeignCurrencyTransaction Then
			Object.CompanyBankAccount = Catalogs.CompaniesBankAccounts.EmptyRef();
			Object.RecipientCompanyBankAccount = Catalogs.CompaniesBankAccounts.EmptyRef();
		EndIf;
		SalesServer.FillInBankAccountsUnderAgreement(Object.Contract,
														Object.CompanyBankAccount,
														Object.RecipientCompanyBankAccount);
		
	EndIf;
	
	Contract = Object.Contract;
	
EndProcedure

&AtServer
Procedure FillInDefaultSalesContract()
	
	If Object.ARAPObjectSettings = Enums.ARAPObjectSettings.ByCounterpartyContracts Then
		DefaultContract = SalesServer.GetDefaultContract(Object,
																		EconomicOperationOfSaleAgreement,
																		Object.ARAPCurrency,
																		Object.LineOfBusiness);
	Else
		DefaultContract = SalesServer.GetDefaultContract(Object,
																		EconomicOperationOfSaleAgreement,
																		Object.ARAPCurrency);
	EndIf;
	
	If SalesContract <> DefaultContract
		Or Not ValueIsFilled(Object.SalesContract) Then
		
		Object.SalesContract = DefaultContract;
		
		SalesContractOnChangeServer(False);
		
	EndIf;
	
	SalesContract = Object.SalesContract;
	
EndProcedure

&AtServer
Procedure FillInDefaultPurchaseAgreement()
	
	AttributesNames		= "Organization, Partner, Counterparty, Contract";
	DocumentAttributes	= New Structure(AttributesNames);
	
	FillPropertyValues(DocumentAttributes, Object);
	
	DocumentAttributes.Organization	= Object.CompanyRecipient;
	DocumentAttributes.Contract		= Object.PurchasingContract;
	
	ContractParameters = PurchasesServer.AdditionalContractSelectionParameters();
	ContractParameters.ARAPCurrency = Object.ARAPCurrency;
	
	If Object.ARAPObjectSettings = Enums.ARAPObjectSettings.ByCounterpartyContracts Then
		ContractParameters.LineOfBusiness = Object.LineOfBusiness;
	EndIf;
	
	DefaultContract = PurchasesServer.GetDefaultContract(DocumentAttributes,
																	BusinessTransactionOfPurchaseAgreement,
																	ContractParameters);
	
	If PurchasingContract <> DefaultContract
		Or Not ValueIsFilled(Object.PurchasingContract) Then
		
		Object.PurchasingContract = DefaultContract;
		
		PurchasingContractOnChangeServer(False);
		
	EndIf;
	
	PurchasingContract = Object.PurchasingContract;
	
EndProcedure

&AtServer
Procedure SetContractAvailability()
	
	InfluenceFieldsFilledIn = ValueIsFilled(Object.Organization)
							And ValueIsFilled(Object.CompanyRecipient);
	
	Items.Contract.Enabled = InfluenceFieldsFilledIn;
	
	If Not InfluenceFieldsFilledIn
		And ValueIsFilled(Object.Contract) Then
		
		Object.Contract = Undefined;
		
	EndIf;
	
EndProcedure

&AtServer
Procedure SetAvailabilityOfSalesAgreement()
	
	InfluenceFieldsFilledIn = ValueIsFilled(Object.Partner)
							And (ValueIsFilled(Object.Counterparty)
								Or UsePartnersAsCounterparties)
							And ValueIsFilled(Object.Organization);
	
	Items.SalesContract.Enabled = InfluenceFieldsFilledIn;
	
	If Not InfluenceFieldsFilledIn
		And ValueIsFilled(Object.SalesContract) Then
		
		Object.Contract = Undefined;
		
	EndIf;
	
EndProcedure

&AtServer
Procedure SetAvailabilityOfPurchaseAgreement()
	
	InfluenceFieldsFilledIn = ValueIsFilled(Object.Partner)
							And (ValueIsFilled(Object.Counterparty)
								Or UsePartnersAsCounterparties)
							And ValueIsFilled(Object.CompanyRecipient);
	
	Items.PurchasingContract.Enabled = InfluenceFieldsFilledIn;
	
	If Not InfluenceFieldsFilledIn
		And ValueIsFilled(Object.PurchasingContract) Then
		
		Object.PurchasingContract = Undefined;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure FillInPricesByPriceKindCompletion(PricesKind, AdditionalParameters) Export
	
	If ValueIsFilled(PricesKind) Then
		
		PricesCalculated = FillInPricesByPriceKindServer(PricesKind);
		SalesClient.NotifyAboutEndOfFillingInPricesByTypeOfPrices(PricesCalculated, PricesKind);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure FillInPricesOfSelectedRowsByPriceTypeCompletion(PricesKind, AdditionalParameters) Export
	
	If ValueIsFilled(PricesKind) Then
		
		PricesCalculated = FillInPricesOfSelectedRowsByPriceTypeServer(PricesKind);
		SalesClient.NotifyAboutEndOfFillingInPricesByTypeOfPrices(PricesCalculated, PricesKind);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure SelectionOfTheSenderSRemainingGoodsCompletion(Result, AdditionalParameters) Export
	
	AddressInStorage = PutProductsInStorage(Object.Goods, UUID);
	
	PickingParameters = New Structure();
	PickingParameters.Insert("AddressInStorage", AddressInStorage);
	PickingParameters.Insert("Organization", Object.Organization);
	PickingParameters.Insert("Warehouse", Object.Warehouse);
	PickingParameters.Insert("Date", Object.EndOfPeriod);
	PickingParameters.Insert("HideExcisableGoods", Object.TransferForActivity_ = PredefinedValue("Enum.VATTaxationTypes.SaleIsSubjectToUTII"));
	PickingParameters.Insert("DisplayTheHideExcisableGoodsFlag", Object.TransferForActivity_ = PredefinedValue("Enum.VATTaxationTypes.SaleIsSubjectToUTII"));
	PickingParameters.Insert("UseItemsBatch", SeriesSpecificationParameters.UseItemsBatch);
	
	OpenForm("CommonForm.SelectGoodsIntercompany", PickingParameters, ThisForm);
	
EndProcedure

&AtClient
Procedure SelectByNegativeInventoryCompletion(Result, AdditionalParameters) Export
	
	AddressInStorage = PutProductsInStorage(Object.Goods, UUID);
	
	PickingParameters = New Structure;
	PickingParameters.Insert("AddressInStorage",				AddressInStorage);
	PickingParameters.Insert("Organization",					Object.Organization);
	PickingParameters.Insert("CompanyRecipient",			Object.CompanyRecipient);
	PickingParameters.Insert("Warehouse",							Object.Warehouse);
	PickingParameters.Insert("Date",							Object.Date);
	PickingParameters.Insert("Negative_Balance",			True);
	PickingParameters.Insert("UseItemsBatch",	SeriesSpecificationParameters.UseItemsBatch);
	
	OpenForm("CommonForm.SelectGoodsIntercompany", PickingParameters, ThisForm);
	
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
		AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions, Object);
		
		BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
		BatchProcessingOfTablePartClient.ProcessTSString(NewRow, StructureOfActions, CachedValues);
		
		CalculateFinalIndicatorsOfTransferOfGoodsBetweenOrganizations(ThisForm);
		
	EndIf;
	
	AccountingForTraceableGoodsClientServerLocalization.SplitRowCompletion(NewRow, AdditionalParameters);
	
EndProcedure

&AtClient
Procedure FillInVATRateCompletion(VATRate, AdditionalParameters) Export

	If VATRate = Undefined Then
		Return;
	EndIf;

	FillInVATRateOnServer(VATRate, CachedValues);

EndProcedure

&AtServer
Procedure FillInVATRateOnServer(VATRate, CachedValues)

	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("ClearAmountOfSettlements");

	SelectedRows = ProcessingOfTabularFormsClientServer.CollectionItems(
		Object.Goods, Items.Goods.SelectedRows);
	
	For Each LineOfATabularSection In SelectedRows Do
		LineOfATabularSection.VATRate = VATRate;
	EndDo;
	
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		SelectedRows,
		StructureOfActions,
		Object.Goods,
		CachedValues);

	ConfigureIntermediaryInvoicePresentation();
	CalculateFinalIndicatorsOfTransferOfGoodsBetweenOrganizations(ThisObject);
	FormItemsManagement();

EndProcedure

&AtServer
Procedure RefreshStatusServer()
		
	Documents.CustomerInvoiceIntercompany.CalculateRecipientState(
		Object.Ref,
		Object.Contract,
		ThisForm);
		
	Documents.CustomerInvoiceIntercompany.CalculateSenderState(
		Object.Ref,
		Object.Contract,
		ThisForm);

EndProcedure

&AtServer
Procedure ChangedPaymentServer(EventName, Parameter)
	
	RefreshStatusServer();
	ARAPAccountingFormWork.NotificationProcessing(ThisForm, EventName, Parameter);
	
EndProcedure

&AtServer
Procedure CompleteVATTaxation()
	
	FillParameters = Documents.CustomerInvoiceIntercompany.ParametersForFillingInVATTaxation_(Object);
	
	VATAccountingERP.FillInSalesVATTaxation(Object.VATTaxation,
												FillParameters,
												VATAccountingCachedParameterValues);
	VATAccountingERP.FillInSalesVATTaxSelectionList(Items.VATTaxation,
															Object.VATTaxation,
															FillParameters,
															VATAccountingCachedParameterValues);
	
	VATTaxationOnChangeServer();
	
EndProcedure

&AtServer
Procedure EstablishVisibilityOfRNPTQuantity()
	
	AccountingForTraceableGoodsLocalization.EstablishVisibilityOfRNPTQuantity(ThisForm, Object.Date);
	
	Items.ProductsGroupQuantityByRNPT.Visible = Items.ProductsGroupQuantityByRNPT.Visible
														And Object.SpecifyCCDNumbers;
	
EndProcedure

&AtServer
Procedure RecalculateNumberOfRNPT()
	
	If Object.SpecifyCCDNumbers
		And ValueIsFilled(Object.Warehouse)
		And ValueIsFilled(Object.Organization) Then
		
		ParametersForObtainingRnptCoefficient = AccountingForTraceableGoodsClientServerLocalization.ParametersForObtainingRnptCoefficient(
												Object);
		AccountingForTraceableGoodsLocalization.FillInQuantityByRNPTVOfTablePart(ParametersForObtainingRnptCoefficient,
																						Object.Goods);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure Attachable_ProcessObjectEntry()
	
	TMCommonUseClient.ProcessObjectEntryInForm(ThisObject, ParametersForRecording);
	
EndProcedure

&AtServer
Procedure PlacePaymentDecryptionInTemporaryStorage()
	ARAPAccountingFormWork.PlacePaymentDecryptionInTemporaryStorage(ThisForm);
EndProcedure

&AtServer
Procedure FillInBankAccountsByDefaultServer()
	
	ParametersOfAccount = CashServer.ParametersForFillingOutOrganizationSBankAccount(Object.Organization);
	ParametersOfAccount.LineOfBusiness = Object.LineOfBusiness;
	ParametersOfAccount.ExcludeCurrencyAccounts = Object.ForeignCurrencyTransaction;
	ParametersOfAccount.Currency = LocalAccountingCurrency;
	Object.CompanyBankAccount = CashServer.GetOrganizationSDefaultBankAccount(
		ParametersOfAccount, Object.CompanyBankAccount);
	
	ParametersOfAccount = CashServer.ParametersForFillingOutOrganizationSBankAccount(Object.CompanyRecipient);
	ParametersOfAccount.LineOfBusiness = Object.LineOfBusiness;
	ParametersOfAccount.ExcludeCurrencyAccounts = Object.ForeignCurrencyTransaction;
	ParametersOfAccount.Currency = LocalAccountingCurrency;
	Object.RecipientCompanyBankAccount = CashServer.GetOrganizationSDefaultBankAccount(
		ParametersOfAccount, Object.RecipientCompanyBankAccount);
	
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
