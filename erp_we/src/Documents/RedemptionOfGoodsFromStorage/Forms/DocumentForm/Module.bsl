
#Region Variables

&AtClient
Var CachedValues; //used by the mechanism for processing changes in PM details

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
	
	DocumentCorrection.OnCreateAtServer(ThisObject, Items.LineCorrection);
	
	If ClientApplication.CurrentInterfaceVariant() = ClientApplicationInterfaceVariant.Version8_2 Then
		Items.GroupInTotal.BackColor = New Color();
	EndIf;
	
	// Handler of the "Properties" subsystem
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("Object", Object);
	AdditionalParameters.Insert("ItemForPlacementName", "GroupAdditionalAttributes");
	AdditionalParameters.Insert("DeferredInitialization", True);
	PropertyManager.OnCreateAtServer(ThisObject, AdditionalParameters);
	
	// Handler of the "Versioning of objects" mechanism
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	
	// Handler of the "Destination" mechanism
	Catalogs.Assignments.DocumentFormWhenCreatedOnServer(ThisObject);
	
	TMCommonUse.CustomizePeripherals(ThisObject);
	
	If Not ValueIsFilled(Object.Ref) Then
		OnReadCreateAtServer();
		ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);
	EndIf;
	
	SetAvailabilityOfClipboardCommands();
	
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject);
	// End IntegrationWith1CDocumentManagementSubsystem
	
	FormEvents.OnCreateAtServer(ThisObject, Cancel, StandardProcessing);
	
	// StandardSubsystems.FilesOperations
	HyperlinkParameters = FilesOperations.FilesHyperlink();
	HyperlinkParameters.Location = "CommandBar";
	FilesOperations.OnCreateAtServer(ThisObject, HyperlinkParameters);
	// End StandardSubsystems.FilesOperations
	
	ARAPAccountingFormWork.FormWhenCreatedOnServer(ThisObject);
	
	// Standard subsystems.Accounting of the originals of the first documents
	SourceDocumentsOriginalsRecording.OnCreateAtServerDocumentForm(ThisObject);
	// The end of the standard subsystem.Accounting of the originals of the first documents 

	VATAccountingERP.SetVisibilityOfCommandAndFillInVATRate(ThisObject);

	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
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
	
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)
	
	ForceCloseTheForm = True;
	
EndProcedure

&AtClient
Procedure OnClose()
	
	EquipmentManagerClient.StartDisablingHardwareWhenClosingForm(Undefined, ThisObject);
	
EndProcedure

&AtClient
Procedure ChoiceProcessing(SelectionResult, ChoiceSource)
	
	If ChoiceSource.FormName = "DataProcessor.SelectGoodsToPurchaseDocument.Form.Form" Then
		
		ProcessingSelectionOfSelectionOnServer(SelectionResult);
		
	ElsIf ChoiceSource.FormName = "DataProcessor.SelectGoodsReceivedForCustody.Form.Form" Then
		
		PricesCalculated = False;
		
		ProcessingOfSelectionSelectionOfServerAcceptedForResponsibleStorage(SelectionResult, PricesCalculated);
		PurchasesClient.NotifyAboutEndOfFillingInPricesUnderAgreement(PricesCalculated);
		
	ElsIf VATAccountingERPClient.FinishedEditingInvoiceReceived(SelectionResult, ChoiceSource) Then
		
		CustomizeInvoicePresentation();
		
	ElsIf ChoiceSource.FormName = "Catalog.InventoryKinds.Form.InventoryOwnerAttributesForm" Then
		
		GetStockTypesFromStorage(SelectionResult);
		
	ElsIf ProductsClient.ThisIsIndicationOfSeries(ChoiceSource) Then
		
		ProductsClient.ProcessSeriesIndication(ThisObject, SeriesSpecificationParameters, SelectionResult);
		
	EndIf;
	
	If Window <> Undefined Then
		Window.Activate();
	EndIf;
	
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
	
	If EventName = "Write_TermsOfPurchaseFromVendors" Then
		SetVisibilityOfAgreements(Items, Object);
	EndIf;
	
	If EventName = "CopyingLinesToClipboard" Then
		SetAvailabilityOfClipboardCommandsOnClient();
	EndIf;
	
	If ARAPAccountingClient.NeedAlertProcessingCall(ThisObject, EventName, Parameter) Then
		ChangedPaymentServer(EventName, Parameter, Source);	
	EndIf;
	
	
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
Procedure URLProcessing(FormattedStringURL, StandardProcessing)
	
	FormEventsClient.URLProcessing(ThisObject, FormattedStringURL, StandardProcessing);
	
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)

	// StandardSubsystems.AccessManagement
	AccessManagement.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.AccessManagement
	
	// Handler of the "Date-change" mechanism
	PeriodClosingDates.ObjectOnReadAtServer(ThisObject, CurrentObject);
	
	// Handler of the "Properties" subsystem
	PropertyManager.OnReadAtServer(ThisObject, CurrentObject);
	
	DocumentCorrection.OnReadAtServer(ThisObject, Items.LineCorrection);
	
	OnReadCreateAtServer();
	
	FormEvents.OnReadAtServer(ThisObject, CurrentObject);
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	// End StandardSubsystems.AttachableCommands
	
	ARAPAccountingFormWork.FormWhenReadingOnServer(ThisObject);
	
EndProcedure

&AtClient
Procedure BeforeWrite(Cancel, WriteParameters)
	
	If NotExecuteCheck1BeforeWrite Then
		NotExecuteCheck1BeforeWrite = False;
		
		Return;
	EndIf;
	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	// Handler of the "Properties" subsystem
	PropertyManager.BeforeWriteAtServer(ThisObject, CurrentObject);
	
	
	ARAPAccountingServer.BeforeWriteAtServer(ThisObject, CurrentObject);
	ConfigurationModificationOverridable.BeforeWriteAtServer(ThisObject, Cancel, CurrentObject, WriteParameters);
	
	CheckStorageLocationsOfVETISLocalization(Cancel);
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.BeforeWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	// End IntegrationWith1CDocumentManagementSubsystem
	
EndProcedure

&AtServer
Procedure OnWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)

	// StandardSubsystems.AccessManagement
	AccessManagement.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	// End StandardSubsystems.AccessManagement
		
	CustomizeForm();
		
	FillInServiceDetailsForProductRange();
	FillInStorageLocationPresentation();
	
	CustomizeInvoicePresentation();
	CalculateTotals_(ThisObject);
	
	
	ARAPAccountingFormWork.FormAfterRecordingOnServer(ThisObject, CurrentObject.AdditionalProperties);
	FormEvents.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	
	WriteParameters.Insert("NotificationDocumentKeys", OperationsWithDocumentJournalsClient.GetKeyParametersForDocument(
		Object.Ref, Object.Date, Object.BusinessOperation));
		
	Notify("Write_RedemptionOfGoodsFromStorage", WriteParameters, Object.Ref);
	ARAPAccountingClient.FormAfterRecording(ThisObject);
	
	ConfigurationModificationClientOverridable.AfterWrite(ThisObject, WriteParameters);
	
	TMCommonUseClient.PerformActionsAfterRecording(ThisObject, Object, WriteParameters);
	
	// StandardSubsystems.AttachableCommands
	If CommonClient.SubsystemExists("StandardSubsystems.AttachableCommands") Then
		ModuleAttachableCommandsClient = CommonClient.CommonModule("AttachableCommandsClient");
		ModuleAttachableCommandsClient.AfterWrite(ThisObject, Object, WriteParameters);
	EndIf;
	// End StandardSubsystems.AttachableCommands
	
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
Procedure GroupPagesOnCurrentPageChange(Item, CurrentPage)
	
	// StandardSubsystems.Properties
	If CurrentPage.Name = "AdvancedGroup"
		And Not ThisObject.PropertiesParameters.DeferredInitializationExecuted Then
		
		PropertiesExecuteDeferredInitialization();
		PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
		
	EndIf;
	// End StandardSubsystems.Properties
	
EndProcedure

&AtClient
Procedure DateOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	
	Notification = New CallbackDescription("DateOnChangeCompletion", ThisObject);
	EnterprisePricesFillingClient.AskQuestionAboutRecalculatingPriceWhenDateChanges(Object, Notification);
	
	FillInVATTaxationPurchases();
	VATTaxationOnChangeServer();
	
EndProcedure

&AtClient
Procedure DateOnChangeCompletion(QuestionResult, AdditionalParameters) Export 
	
	Var PricesCalculated;
	
	If Not QuestionResult = DialogReturnCode.Cancel Then
		DateOnChangeServer(QuestionResult, PricesCalculated);
	EndIf;
	
	DocumentDateBeforeChange = Object.Date;
	
	If QuestionResult = True Then
		SalesClient.NotifyAboutEndOfFillingInPricesUnderAgreement(PricesCalculated);
	EndIf;
	
	
EndProcedure

// The constructor function of additional parameters processing is complete
// Returns:
// 	Structure - advanced setting:
// * Item - FormGroup, FormTable, FormField, FormButton - Form element
&AtClient
Function AdditionalCompletionProcessingParameters()
	
	Result = New Structure;
	Result.Insert("Item");
	Return Result;
	
EndFunction

&AtClient
Procedure PartnerOnChange(Item)
	
	If Not ValueIsFilled(Object.Partner) Then
		Object.Terms = PredefinedValue("Catalog.TermsOfPurchaseFromVendors.EmptyRef");
		
		Return;
	EndIf;
	
	WhenChangingPartnerServer();
	
	AdditionalParameters = AdditionalCompletionProcessingParameters();
	AdditionalParameters.Item = Item;
	
	CallbackDescription = New CallbackDescription("PartnerWhenChangingQuestionEnds", ThisObject,
		AdditionalParameters);
	
	QuestionUserBeforeFillingInPricesByAgreement(CallbackDescription);
	
EndProcedure

// Parameters:
// 	UserAnswer - Boolean - 
// 	AdditionalParameters - See AdditionalCompletionProcessingParameters
&AtClient
Procedure PartnerWhenChangingQuestionEnds(UserAnswer, AdditionalParameters) Export
	
	If ValueIsFilled(Object.Terms) Then
		If UserAnswer Then
			ErrorText = "";
			PricesCalculated = FillThePricesByTermsOfSalesServer(True, ErrorText);
			
			PurchasesClient.NotifyAboutEndOfFillingInPricesUnderAgreement(PricesCalculated, ErrorText);
		Else
			PurchasesClient.NotifyEndOfFillingInDefaultPurchaseConditions();
		EndIf;
	EndIf;
	
	
EndProcedure

&AtClient
Procedure CounterpartyOnChange(Item)
	
	CounterpartyOnChangeServer();
	
	
EndProcedure

&AtClient
Procedure TermsOnChange(Item)
	
	CallbackDescription = New CallbackDescription("AgreementWhenChangingQuestionCompletion", ThisObject);
	
	QuestionUserBeforeFillingInPricesByAgreement(CallbackDescription);
	
EndProcedure

&AtClient
Procedure AgreementWhenChangingQuestionCompletion(UserAnswer, AdditionalParameters) Export
	
	Var PricesCalculated;
	
	RecalculatePrices_2 = ValueIsFilled(Object.Terms)
		And Object.Goods.Count() > 0
		And UserAnswer;
	
	WhenChangingAgreementAtServer(RecalculatePrices_2, PricesCalculated);
	
	If ValueIsFilled(Object.Terms) Then
		PurchasesClient.NotifyEndOfFillingInTermsOfPurchase();
	EndIf;
	
EndProcedure

&AtClient
Procedure TermsStartChoice(Item, ChoiceData, StandardProcessing)
	
	AdditionalSelection = New Structure("BusinessOperation",
		PredefinedValue("Enum.BusinessTransactions.ReceivingForStorageWithRightOfSale"));
	
	PurchasesClient.StartSelectingSupplierAgreement(Item, StandardProcessing, Object.Partner, Object.Terms,
		Object.Date, AdditionalSelection);
	
EndProcedure

&AtClient
Procedure LabelCurrenciesClick(Item, StandardProcessing)
	
	Notification = New CallbackDescription("LabelCurrenciesClickCompletion", ThisObject);
	
	ARAPAccountingClient.CurrencyAndExchangeRateOfDocument(ThisObject, Item, StandardProcessing, Notification);
	
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

&AtClient
Procedure LabelPaymentStagesClick(Item, StandardProcessing)
	
	 ARAPAccountingClient.LabelPaymentStagesClick(ThisObject, Item, StandardProcessing);
	 
EndProcedure

&AtClient
Procedure OrganizationOnChange(Item)
	
	OrganizationOnChangeServer();
	
EndProcedure

&AtClient
Procedure ContractOnChange(Item)
	
	ContractOnChangeServer();
	
EndProcedure

&AtClient
Procedure VendorPriceKindOnChange(Item)
	
	If Not ValueIsFilled(Object.VendorPriceKind) Then
		Return;
	EndIf;
	
	QueryText       = NStr("vi = 'Điền lại giá theo dạng giá?';
							|ru = 'Перезаполнить цены по виду цены?';
							|en = 'Refill prices by the price type?'; fa = 'Refill prices by the price type?';
							|it = 'Ricompilare i prezzi per tipo di prezzo?';
							|pl = 'Wypełnić ponownie wg rodzaju cen?';
							|tr = 'Fiyat türüne göre fiyatlar yeniden doldurulsun mu?'");
	CallbackDescription = New CallbackDescription("SupplierSPriceViewWhenQuestionChanges", ThisObject);
	
	AnswersOptions = New ValueList;
	AnswersOptions.Add(True, NStr("vi = 'Điền lại';
									|ru = 'Перезаполнить';
									|en = 'Refill'; fa = 'پرکردن مجدد';
									|it = 'Ricompilare';
									|pl = 'Refill';
									|tr = 'Yeniden doldur'"));
	AnswersOptions.Add(False,   NStr("vi = 'Không điền lại';
									|ru = 'Не перезаполнять';
									|en = 'Do not refill'; fa = 'Do not refill';
									|it = 'Non ricompilare';
									|pl = 'Nie wypełniaj ponownie';
									|tr = 'Yeniden doldurma'"));
	
	ShowQueryBox(CallbackDescription, QueryText, AnswersOptions);
	
EndProcedure

&AtClient
Procedure SupplierSPriceViewWhenQuestionChanges(UserAnswer, AdditionalParameters) Export
	
	If UserAnswer <> Undefined
		And UserAnswer Then
		
		FillInPricesBySupplierPriceType();
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ManagerOnChange(Item)
	
	FillInSubordinatePropertiesForStatistics("Manager");
	
EndProcedure

&AtClient
Procedure LineOfBusinessOnChange(Item)
	
	LineOfBusinessOnChangeServer();
	
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
Procedure TextInvoiceURLProcessing(Item, Var_URL, StandardProcessing)
	
	RegistrationParameters = VATAccountingERPClientServer.ParametersForRegisteringInvoicesReceived();
	FillPropertyValues(RegistrationParameters, Object, "Ref, Date, Organization, Counterparty, VATTaxation");
	
	VATAccountingERPClient.ProcessingNavigationLinkInvoicesReceived(ThisObject, Var_URL, StandardProcessing,
		RegistrationParameters);
	
EndProcedure

&AtClient
Procedure RedemptionForActivityClearing(Item, StandardProcessing)
	StandardProcessing = False;
EndProcedure

&AtClient
Procedure DepartmentOnChange(Item)
	
	UpdateBuyoutsForActivities();
	
EndProcedure

&AtClient
Procedure BusinessOperationOnChange(Item)
	
	If Object.BusinessOperation = BusinessTransactionBeforeTheChange Then
		Return;
	EndIf;
	
	ContractBusinessTransaction = ContractBusinessTransaction(Object.BusinessOperation);
	Object.Partner           = PredefinedValue("Catalog.Partners.EmptyRef");
	Object.Counterparty        = PredefinedValue("Catalog.Counterparties.EmptyRef");
	Object.Contract           = PredefinedValue("Catalog.CounterpartyContracts.EmptyRef");
	Object.VendorPriceKind = PredefinedValue("Catalog.VendorPriceTypes.EmptyRef");
	PartnerOnChange(Items.Partner);
	CounterpartyOnChange(Items.Counterparty);
	ContractOnChange(Items.Contract);
	VendorPriceKindOnChange(Items.VendorPriceKind);
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands

	WhenBusinessTransactionChangesServer();
	
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

#EndRegion

#Region FormTableItemsEventHandlersGoods

&AtClient
Procedure GoodsSelection(Item, RowSelected, Field, StandardProcessing)
	
	If Items.Goods.CurrentData <> Undefined Then
		PartnersProductsClient.WhenSelectingPartnerProducts(
			Object, Field, "GoodsPartnerProducts", Items.Partner.Title);
	EndIf;
	
EndProcedure

&AtClient
Procedure GoodsOnActivateCell(Item)
	
	If Item.CurrentItem = Undefined Then
		Return;
	ElsIf Item.CurrentItem.Name = "GoodsPartnerProducts" Then
		
		CurrentData = Items.Goods.CurrentData;
		
		PartnersProductsClient.FillInPartnerProductSelectionList(
			Object.Partner, CurrentData, Items.GoodsPartnerProducts.ChoiceList);
			
		PartnersProductsClient.SetPackageSelectionParameters(
			Items.GoodsPartnerProducts.ChoiceParameters, CurrentData);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure GoodsBeforeDeleteRow(Item, Cancel)
	
	ProductsClient.UpdateCachedValuesToAccountForSeries(Item, CachedValues, SeriesSpecificationParameters);
	
EndProcedure

&AtClient
Procedure GoodsOnStartEdit(Item, NewRow, Copy)
	
	ProductsClient.UpdateCachedValuesToAccountForSeries(Item, CachedValues, SeriesSpecificationParameters,
		Copy);
	
EndProcedure

&AtClient
Procedure GoodsOnEditEnd(Item, NewRow, CancelEdit)
	
	CurrentData = Items.Goods.CurrentData;
	
	If ProductsClient.SeriesStatusesNeedToBeUpdated(Item, CachedValues, SeriesSpecificationParameters) Then
		IDCurrentRow = CurrentData.GetID();
		
		FillInStatusesOfSpecifyingSeriesWhenEditingLineTS(IDCurrentRow, CachedValues);
		ProductsClient.UpdateCachedValuesToAccountForSeries(Item,CachedValues,SeriesSpecificationParameters);
	EndIf;
	
	CalculateTotals_(ThisObject);
		
EndProcedure

&AtClient
Procedure GoodsAfterDeleteRow(Item)
	
	If ProductsClient.SeriesStatusesNeedToBeUpdated(Item, CachedValues, SeriesSpecificationParameters, True) Then
		
		FillInStatusesOfSpecifyingSeriesWhenEditingLineTS(Undefined, CachedValues);
		ProductsClient.UpdateCachedValuesToAccountForSeries(Item, CachedValues, SeriesSpecificationParameters);
		
	EndIf;
	
	CalculateTotals_(ThisObject);
	
EndProcedure

&AtClient
Procedure GoodsPartnerProductsOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;
	ItemBeforePartnerItemChanges = CurrentRow.Products;
	
	PartnersProductsClient.SetPackageSelectionParameters(Item.ChoiceParameters, CurrentRow);
	
	FillInArticleAttribute         = New Structure("Products", "SKU");
	FillInProductTypeAttribute_ = New Structure("Products", "ItemsType");
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInTheItemByThePartnerSItem");
	StructureOfActions.Insert("FillInArticleAttribute",               FillInArticleAttribute);
	StructureOfActions.Insert("FillInProductTypeAttribute_",       FillInProductTypeAttribute_);
	StructureOfActions.Insert("CheckCharacteristicsByOwner",    CurrentRow.Characteristic);
	StructureOfActions.Insert("CheckFillPackageByOwner", CurrentRow.Package);
	StructureOfActions.Insert("FillInVATRate", BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRate(Object));
	
	AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions, ThisObject);
	FillInActionStructureWhenAddingRow(ThisObject, StructureOfActions);
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
	If CurrentRow.Products <> ItemBeforePartnerItemChanges Then
		StructureOfActions = New Structure;
		
		LinesOfBusinessClientServer.StructureOfInsertActionsWhenAddingRow(ThisObject, StructureOfActions);
		BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	EndIf;
	
	CalculateTotals_(ThisObject);
	
EndProcedure

&AtClient
Procedure GoodsProductsOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;
	
	FillInArticleAttribute                  = New Structure("Products", "SKU");
	FillInProductTypeAttribute_          = New Structure("Products", "ItemsType");
	CheckSeriesCalculateStatus           = New Structure("Warehouse, SeriesSpecificationParameters",
																Undefined, SeriesSpecificationParameters);
	ProductsOnChangeOverridable = New Structure("FormName, TabularSectionName",
																FormName, "Goods");
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInProductNameOfProductPartner", Object.Partner);
	
	StructureOfActions.Insert("FillInArticleAttribute",               FillInArticleAttribute);
	StructureOfActions.Insert("FillInProductTypeAttribute_",       FillInProductTypeAttribute_);
	StructureOfActions.Insert("CheckCharacteristicsByOwner",    CurrentRow.Characteristic);
	StructureOfActions.Insert("CheckFillPackageByOwner", CurrentRow.Package);
	StructureOfActions.Insert("CheckSeriesCalculateStatus",        CheckSeriesCalculateStatus);
	StructureOfActions.Insert("FillInVATRate", BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRate(Object));
	
	StructureOfActions.Insert("ProductsOnChangeOverridable", ProductsOnChangeOverridable);
	
	AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions, ThisObject);
	LinesOfBusinessClientServer.StructureOfInsertActionsWhenAddingRow(ThisObject, StructureOfActions);
	FillInActionStructureWhenAddingRow(ThisObject, StructureOfActions);
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
	CalculateTotals_(ThisObject);
	
EndProcedure

&AtClient
Procedure GoodsCharacteristicOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;
	
	CharacteristicOnChangeOverridable = New Structure("FormName, TabularSectionName",
																FormName, "Goods");
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInProductNameOfProductPartner", Object.Partner);
	StructureOfActions.Insert("CharacteristicOnChangeOverridable", CharacteristicOnChangeOverridable);
	
	LinesOfBusinessClientServer.StructureOfInsertActionsWhenAddingRow(ThisObject, StructureOfActions);
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
EndProcedure

&AtClient
Procedure GoodsSeriesOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;
	
	ValueSelected = ProductsClientServer.SelectedSeries();
	ValueSelected.Value                   = CurrentRow.Series;
	ValueSelected.CurrentRowID = CurrentRow.GetID();
	
	ProductsClient.ProcessSeriesIndication(ThisObject, SeriesSpecificationParameters, ValueSelected)
	
EndProcedure

&AtClient
Procedure GoodsSeriesStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	
	OpenSelectionOfSeries(Item.EditText);
	
EndProcedure

&AtClient
Procedure GoodsPackageOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInProductNameOfProductPartner", Object.Partner);
	
	StructureOfActions.Insert("RecalculatePricePerPackage", CurrentRow.Count);
	
	AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions, ThisObject);
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
	CalculateTotals_(ThisObject);
	
EndProcedure

&AtClient
Procedure GoodsNumberOfPackagesOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;
	
	StructureOfActions = New Structure;
	AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions, ThisObject);
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
	CalculateTotals_(ThisObject);
	
EndProcedure

&AtClient
Procedure GoodsPriceOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;
	
	StructureOfRecalculationOfAmount = ParametersForConvertingAmountOfNDSVToTS(ThisObject);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateAmount");
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("ClearAmountOfSettlements");
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
	CalculateTotals_(ThisObject);
	
EndProcedure

&AtClient
Procedure GoodsSumOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;
	
	StructureOfRecalculationOfAmount = ParametersForConvertingAmountOfNDSVToTS(ThisObject);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculatePriceByAmount");
	
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("ClearAmountOfSettlements");
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
	CalculateTotals_(ThisObject);
	
EndProcedure

&AtClient
Procedure GoodsAmountARAPOnChange(Item)
	CurrentData = Items.Goods.CurrentData;
	If CurrentData <> Undefined Then
		CurrentData.AmountVATARAP = 0;
	EndIf;
EndProcedure

&AtClient
Procedure GoodsVATAmountOnChange(Item)
	CurrentRow = Items.Goods.CurrentData;
	
	StructureOfRecalculationOfAmount = ParametersForConvertingAmountOfNDSVToTS(ThisObject);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("ClearAmountOfSettlements");
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
	CalculateTotals_(ThisObject);

EndProcedure

&AtClient
Procedure GoodsVATRateOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;
	
	StructureOfRecalculationOfAmount = ParametersForConvertingAmountOfNDSVToTS(ThisObject);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateVATAmount",  StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("ClearAmountOfSettlements");
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
	CalculateTotals_(ThisObject);
	
EndProcedure

&AtClient
Procedure GoodsStorageTypeOnChange(Item)
	
	StorageLocations_ = StorageLocations_();
	CurrentData = Items.Goods.CurrentData;
	
	If (CurrentData.StorageType = StorageLocations_.Warehouse
			And Not ValueIsFilled(CurrentData.Warehouse))
		Or (CurrentData.StorageType = StorageLocations_.Department
			And Not ValueIsFilled(CurrentData.Department))
		Or (CurrentData.StorageType = StorageLocations_.CounterpartyContract
			And Not ValueIsFilled(CurrentData.Contract))
		Or Not ValueIsFilled(CurrentData.StorageType) Then
		
		DefaultValues = New Structure("Warehouse, Department, Contract, Custodian, Counterparty, 
												|StorageLocationRepresentation");
		FillPropertyValues(CurrentData, DefaultValues);
		
	EndIf;
	
	FillInStatusesForSpecifyingSeriesServer();
	
EndProcedure

&AtClient
Procedure GoodsStorageLocationRepresentationOnChange(Item)
	
	CheckSeriesCalculateStatus = New Structure("Warehouse, SeriesSpecificationParameters",
													Undefined, SeriesSpecificationParameters);
	
	CurrentRow     = Items.Goods.CurrentData;
	StructureOfActions = New Structure("CheckSeriesCalculateStatus", CheckSeriesCalculateStatus);
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
EndProcedure

&AtClient
Procedure GoodsStorageLocationRepresentationStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	
	StorageLocations_ = StorageLocations_();
	CurrentData = Items.Goods.CurrentData;
	
	If CurrentData.StorageType = StorageLocations_.Warehouse Then
		NameOfOpeningForm = "Catalog.Warehouses.Form.ChoiceForm";
		FormParameters   = WarehouseSelectionParameters();
	ElsIf CurrentData.StorageType = StorageLocations_.Department Then
		NameOfOpeningForm = "Catalog.BusinessStructure.Form.ChoiceForm";
		FormParameters   = UnitSelectionParameters();
	ElsIf CurrentData.StorageType = StorageLocations_.CounterpartyContract Then
		NameOfOpeningForm = "Catalog.CounterpartyContracts.Form.ChoiceForm";
		FormParameters   = ContractSelectionParameters_(
								CurrentData.Custodian, CurrentData.Counterparty, Object.BusinessOperation, UseImportOfGoodsFromCustomsUnion);
	EndIf;
	
	OpenStorageLocationSelectionForm(NameOfOpeningForm, FormParameters, CurrentData);
	
EndProcedure

&AtClient
Procedure GoodsStorageLocationRepresentationOpening(Item, StandardProcessing)
	
	StandardProcessing = False;
	
	StorageLocations_ = StorageLocations_();
	CurrentData = Items.Goods.CurrentData;
	
	If CurrentData.StorageType = StorageLocations_.Warehouse Then
		StorageLocation = CurrentData.Warehouse;
	ElsIf CurrentData.StorageType = StorageLocations_.Department Then
		StorageLocation = CurrentData.Department;
	ElsIf CurrentData.StorageType = StorageLocations_.CounterpartyContract Then
		StorageLocation = CurrentData.Contract;
	EndIf;
	
	ShowValue(, StorageLocation);
	
EndProcedure

&AtClient
Procedure GoodsStorageLocationRepresentationChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	StandardProcessing = False;
	
	CurrentData = Items.Goods.CurrentData;
	
	FillStorageLocation(ValueSelected, CurrentData);
	
EndProcedure

&AtClient
Procedure GoodsStorageLocationRepresentationAutoComplete(Item, Text, ChoiceData, DataGetParameters, Waiting, StandardProcessing)
	
	StandardProcessing = False;
	
	StorageLocations_ = StorageLocations_();
	CurrentData = Items.Goods.CurrentData;
	
	If CurrentData.StorageType = StorageLocations_.Warehouse Then
		SelectionDataType       = Type("CatalogRef.Warehouses");
		DataSelectionOptions = WarehouseSelectionParameters(False);
	ElsIf CurrentData.StorageType = StorageLocations_.Department Then
		SelectionDataType       = Type("CatalogRef.BusinessStructure");
		DataSelectionOptions = UnitSelectionParameters();
	ElsIf CurrentData.StorageType = StorageLocations_.CounterpartyContract Then
		SelectionDataType       = Type("CatalogRef.CounterpartyContracts");
		DataSelectionOptions = ContractSelectionParameters_(
									CurrentData.Custodian, CurrentData.Counterparty, Object.BusinessOperation, UseImportOfGoodsFromCustomsUnion);
	Else
		Return;
	EndIf;
	
	DataSelectionOptions.Insert("SearchString", Text);
	DataSelectionOptions.Insert("ChoiceFoldersAndItems",
									PredefinedValue("FoldersAndItemsUse.Items"));
	
	ChoiceData = GetChoiceData(SelectionDataType, DataSelectionOptions);
	
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

&AtClient
Procedure PostAndClose(Command)
	
	TMCommonUseClient.PostAndClose(ThisObject, True);
	
EndProcedure

&AtClient
Procedure WriteDocument(Command)
	
	TMCommonUseClient.Write(ThisObject, True);
	
EndProcedure

&AtClient
Procedure PostDocument(Command)
	
	TMCommonUseClient.Post(ThisObject, True);
	
EndProcedure

// StandardSubsystems.AttachableCommands
&AtClient
Procedure Attachable_ExecuteCommand(Command)
	AttachableCommandsClient.StartCommandExecution(ThisObject, Command, Object);
EndProcedure
// End StandardSubsystems.AttachableCommands

// StandardSubsystems.AttachableCommands
&AtClient
Procedure Attachable_UpdateCommands()
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
EndProcedure
// End StandardSubsystems.AttachableCommands

// StandardSubsystems.Properties
&AtClient
Procedure Attachable_PropertiesExecuteCommand(ItemOrCommand, Var_URL = Undefined, StandardProcessing = Undefined)
	PropertyManagerClient.ExecuteCommand(ThisObject, ItemOrCommand, StandardProcessing);
EndProcedure
// End StandardSubsystems.Properties

// IntegrationWith1CDocumentManagementSubsystem
&AtClient
Procedure Attachable_ExecuteIntegrationCommand(Command)
	
	IntegrationWith1CDocumentManagementCoreClient.ExecutePlugInIntegrationCommand(Command, ThisObject, Object);
	
EndProcedure
// End IntegrationWith1CDocumentManagementSubsystem

&AtClient
Procedure CheckCounterparties(Command)
	
	
EndProcedure

&AtClient
Procedure OpenInventoryKinds(Command)
	
	OptionsForEditingInventoryTypes = PutGoodsAndStockTypesInStorage();
	
	FinancesClient.OpenInventoryKinds(ThisObject, OptionsForEditingInventoryTypes);
	
EndProcedure

&AtClient
Procedure PaymentSettlement(Command)
	
	PlacePaymentDecryptionInTemporaryStorage();
	ARAPAccountingClient.PaymentSettlement(ThisObject, Items.CreditPaymentForm);
	
EndProcedure

&AtClient
Procedure DecorationSettlementStateClick(Item, StandardProcessing)
	
	ARAPAccountingClient.CalculationsClick(ThisObject, Item, StandardProcessing);
	
EndProcedure

#Region FormTableCommandHandlersGoods

&AtClient
Procedure CopyRows(Command)
	
	If ProcessingOfTabularFormsClient.SelectedLineToExecuteCommand(Items.Goods) Then
		CopyLinesOnServer();
		ProcessingOfTabularFormsClient.NotifyUserAboutCopyingStrings(Items.Goods.SelectedRows.Count());
	EndIf;
	
EndProcedure

&AtClient
Procedure InsertRows(Command)
	
	NumberOfProductsBeforeInsertion = Object.Goods.Count();
	
	GetLinesFromClipboard();
	
	NumberOfInserted = Object.Goods.Count() - NumberOfProductsBeforeInsertion;
	
	ProcessingOfTabularFormsClient.NotifyUserAboutInsertingRows(NumberOfInserted);
	
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
		
		StructureOfActions = New Structure;
		AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions, ThisObject);
		
		BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
		BatchProcessingOfTablePartClient.ProcessTSString(NewRow, StructureOfActions, CachedValues);
		
		CalculateTotals_(ThisObject);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ShowSupplierProducts(Command)
	
	PartnersProductsClient.ShowThePartnerSNomenclature(
		Object.Partner, Object.Ref, Items.Goods.CurrentData, Items.Partner.Title);
	
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
Procedure ImportDataFromPDT(Command)
	
	Notification = New CallbackDescription("DownloadFromTSDCompletion", ThisObject);
	
	EquipmentManagerClient.StartDownloadingDataFromTSD(Notification, UUID);
	
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
Procedure GetWeight(Command)
	
	CurrentRow = EquipmentManagerTMClient.CurrentRow(ThisObject);
	
	If CurrentRow = Undefined Then
		Return;
	EndIf;
	
	Notification = New CallbackDescription("GetWeightCompletion", ThisObject, CurrentRow);
	
	EquipmentManagerClient.StartGettingWeightWithElectronicScales(Notification, UUID);
	
EndProcedure

&AtClient
Procedure GetWeightCompletion(ExecutionResult, CurrentRow) Export
	
	If ExecutionResult.Result Then
		StructureOfActions = New Structure;
		AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions, ThisObject);
		
		CurrentRow.NumberOfPackages = ExecutionResult.Weight;
		
		AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions, ThisObject);
		
		BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
		
		CalculateTotals_(ThisObject);
	Else
		
		EquipmentManagerTMClient.ReportError(ExecutionResult);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure CheckQuantityInTheDocument(Command)
	
	OpeningParameters = New Structure;
	OpeningParameters.Insert("Ref",                               Object.Ref);
	OpeningParameters.Insert("TabularSectionName",                    "Goods");
	OpeningParameters.Insert("SeriesSpecificationParameters",               SeriesSpecificationParameters);
	OpeningParameters.Insert("GoodsQuantityExcessIsAllowed", True);
	OpeningParameters.Insert("AddressInTempStorage",
		PutTablePartOfGoodsInTemporaryStorageToCheckQuantity());
	
	CallbackDescription = New CallbackDescription("CheckQuantityInTheDocumentCompletion", ThisObject);
	
	OpenForm("CommonForm.CheckDocumentPopulation", OpeningParameters, , , , , CallbackDescription,
		FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure CheckQuantityInTheDocumentCompletion(Result, AdditionalParameters) Export
	
	ReturnParameters = Result;
	
	If ReturnParameters <> Undefined Then
		
		Modified   = True;
		CachedValues = ?(CachedValues = Undefined,
								BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues(),
								CachedValues);
		
		ChangeTablePartBasedOnResultsOfCheck(ReturnParameters, CachedValues);
		
		CalculateTotals_(ThisObject);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure SpecifySeries(Command)
	
	OpenSelectionOfSeries();
	
EndProcedure

&AtClient
Procedure SelectGoods(Command)
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.StartTimeMeasurement(True,
		"Document.RedemptionOfGoodsFromStorage.Form.DocumentForm.SelectGoods");
	
	FilterByProductType = New FixedArray(ProductsClientServer.SelectionByProductMultiTurnContainer(False));
	
	FormParameters = New Structure;
	FormParameters.Insert("Document",                                     Object.Ref);
	FormParameters.Insert("Partner",                                      Object.Partner);
	FormParameters.Insert("Terms",                                   Object.Terms);
	FormParameters.Insert("PriceIncludesVAT",                              Object.PriceIncludesVAT);
	FormParameters.Insert("Currency",                                       Object.Currency);
	FormParameters.Insert("Date",                                         Object.Date);
	FormParameters.Insert("FilterByProductType",                      FilterByProductType);
	FormParameters.Insert("SelectionModeExcludeGroupsAvailableInOrders", True);
	FormParameters.Insert("HideManualDiscounts",                         True);
	
	OpenForm("DataProcessor.SelectGoodsToPurchaseDocument.Form", FormParameters, ThisObject, UUID);
	
EndProcedure

&AtClient
Procedure PickUpTheGoodsAcceptedForSafeStorage(Command)
	
	SelectionOfGoodsAcceptedForResponsibleStorage();
	
EndProcedure

&AtClient
Procedure FillInTheItemByThePartnerSItem(Command)
	
	If Not TMCommonUseClient.CheckForRowsInList(Object.Goods, "Goods") Then
		Return;
	EndIf;
	
	FilterItemsType = New Array;
	FilterItemsType.Add(PredefinedValue("Enum.ItemsTypes.OwnGoods"));
	FilterItemsType.Add(PredefinedValue("Enum.ItemsTypes.ReusablePackage"));
	
	Notification = New CallbackDescription("FillInTheItemByThePartnerSItemCompletion", ThisObject);
	
	PurchasesClient.OpenSupplierProductListForm(Notification, PlaceGoodsInTemporaryStorageServer(),
		ThisObject, FilterItemsType);
	
EndProcedure

&AtClient
Procedure FillInTheItemByThePartnerSItemCompletion(Result, AdditionalParameters) Export
	
	If Result <> Undefined Then
		FillInItemsFromTemporaryStorageServer(Result);
	EndIf;
	
EndProcedure

&AtClient
Procedure ImportFromExternalFile(Command)
	
	ImportParameters = ProcessingOfTabularFormsClient.ProductLoadingParameters();
	ImportParameters.Organization = Object.Organization;
	ImportParameters.FillInThePartnerSNomenclature = Object.Partner;
	ImportParameters.ImportPrices  = True;
	ImportParameters.ImportAmounts = True;
	ImportParameters.PriceIncludesVAT    = Object.PriceIncludesVAT;
	ImportParameters.VATTaxation = Object.VATTaxation;
	ImportParameters.FillingDate     = Object.Date;
	ImportParameters.FilterParameters.Insert("ItemsType",
		ProductsClientServer.SelectionByProductMultiTurnContainer(False));
	
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
Procedure FillThePricesByTermsOfSales(Command)
	
	If PartnerPricesFillingClient.ItIsNecessaryToFillInPricesByAgreement(Object, "Goods", NStr("vi = 'Hàng hóa';
																								|ru = 'Товары';
																								|en = 'Goods'; fa = 'کالاها';
																								|it = 'Merci';
																								|pl = 'Towary';
																								|tr = 'Ürünler'")) Then
		ErrorText = "";
		PricesCalculated = FillThePricesByTermsOfSalesServer(, ErrorText);
		
		PurchasesClient.NotifyAboutEndOfFillingInPricesUnderAgreement(PricesCalculated, ErrorText);
	EndIf;
	
EndProcedure

&AtClient
Procedure FillInThePricesOfTheSelectedLinesByTheTypeOfSupplierPrices(Command)
	
	FillInPricesBySupplierPriceType(True);
	
EndProcedure

&AtClient
Procedure FillInVATRate(Command)

	If Object.Goods.Count() = 0 Then
		WarningText = NStr("vi = 'Trong danh sách ""Hàng hóa"" chưa điền dòng nào.';
							|ru = 'В список ""Товары"" не введено ни одной строки.';
							|en = 'No lines entered in the Item list.'; fa = 'No lines entered in the Item list.';
							|it = 'В список ""Товары"" не введено ни одной строки.';
							|pl = 'Do listy ""Wiersze pozycji"" nie wprowadzono żadnego wiersza.';
							|tr = '""Ürünler"" listesine hiçbir satır girilmemiştir'");
		ShowMessageBox(, WarningText);
		Return;
	EndIf;

	ClosingNotification1 = New CallbackDescription("FillInVATRateCompletion", ThisObject);
	FormParameters = New Structure();
	FormParameters.Insert("VATTaxationType", Object.VATTaxation);
	OpenForm("Catalog.VATRates.ChoiceForm", FormParameters,,,,, ClosingNotification1);

EndProcedure

#EndRegion

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisObject, Command);
	
EndProcedure

#EndRegion

#Region Private

#Region OnChangeAttributes

&AtServer
Procedure DateOnChangeServer(RecalculatePrices_2, PricesCalculated)
	
	If RecalculatePrices_2 Then
		PricesCalculated = FillThePricesByTermsOfSalesServer(True);
	Else
		PricesCalculated = False;
	EndIf;
	
	ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisObject,"Date");
	
	PaymentDate = PurchasesServer.GetLatestDateOnSchedule(Object.Date, Object.Terms);
	
	If Not ValueIsFilled(PaymentDate) Then
		If Not ValueIsFilled(DocumentDateBeforeChange) Then
			DocumentDateBeforeChange = Object.Date;
		EndIf;
		
		DateShift = (BegOfDay(Object.Date) - BegOfDay(DocumentDateBeforeChange)) / 86400;
		
		If DateShift > 0 Then
			Object.PaymentDate = Object.Date + DateShift * 86400;
		Else
			Object.PaymentDate = Object.Date;
		EndIf;
	Else
		Object.PaymentDate = PaymentDate;
	EndIf;
	
	PrepareFillSetSeriesVisibility();
	
	UpdateBuyoutsForActivities(True);
	
	ResponsiblePersonsServer.WhenChangingRelatedDocumentDetails(Object);
	
EndProcedure

&AtServer
Procedure WhenChangingPartnerServer()
	
	OldCurrency                  = DocumentCurrency;
	DocumentPurchases               = FormAttributeToValue("Object");
	DirectionsOfActivity = Object.LineOfBusiness;
	
	DocumentPurchases.FillInDefaultPurchaseConditions(False);
	ValueToFormAttribute(DocumentPurchases, "Object");
	
	If ValueIsFilled(Object.Terms) Then
		DocumentCurrency = Object.Currency;
	EndIf;
	
	If Contract <> Object.Contract Then
		Contract = Object.Contract;
		ClearDestinationInProductsTable();
		FillInDefaultAssignment();
	EndIf;

	AttributesArray = New Array;
	AttributesArray.Add("Currency");
	AttributesArray.Add("ARAPCurrency");
	AttributesArray.Add("Partner");
	AttributesArray.Add("LineOfBusiness");
	AttributesArray.Add("Organization");
	AttributesArray.Add("Terms");
	ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisObject, AttributesArray);

	ResponsiblePersonsServer.FillInManager_(Object);
	FillInSubordinatePropertiesForStatistics("Counterparty");
	SetVisibilityOfAgreements(Items, Object);
	
	ExecuteRecalculateDocumentAmountsServer(OldCurrency, DocumentCurrency);
	
	CalculateTotals_(ThisObject);
	
	CustomizeInvoicePresentation();
	
	ResponsiblePersonsServer.WhenChangingRelatedDocumentDetails(Object);
	
	PartnersProductsServer.FillInPartnerProductListByProductNameWhenPartnerChanges(Object.Goods, Object.Partner);
	FillInServiceDetailsForProductRange();
	
	If DirectionsOfActivity <> Object.LineOfBusiness Then
		LinesOfBusinessServer.WhenChangingDirectionOfActivity(ThisObject);
		ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);
	EndIf;
	
EndProcedure

&AtServer
Procedure CounterpartyOnChangeServer()
	
	DirectionsOfActivity = Object.LineOfBusiness;
	
	ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisObject, "Counterparty");
	
	If ValueIsFilled(Object.Counterparty) Then
		
		If Not Catalogs.CounterpartyBankAccounts.VerifyBankAccountHolder(
			Object.CounterpartyBankAccount, Object.Counterparty) Then
			ParametersOfAccount = CashServer.ParametersForFillingInCounterpartySBankAccount(Object.Counterparty);
			Object.CounterpartyBankAccount = CashServer.GetDefaultCounterpartyBankAccount(
				ParametersOfAccount);
		EndIf;
		
		FillInDefaultContract();
	EndIf;
	
	FillInSubordinatePropertiesForStatistics("Counterparty");
	
	If DirectionsOfActivity <> Object.LineOfBusiness Then
		LinesOfBusinessServer.WhenChangingDirectionOfActivity(ThisObject);
		ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);
	EndIf;
	
	UpdateBuyoutsForActivities(True);
	FillInVATTaxationPurchases();
	
EndProcedure

&AtServer
Procedure WhenChangingAgreementAtServer(RecalculatePrices_2 = True, PricesCalculated = False)
	
	If Not ValueIsFilled(Object.Terms) Then
		Return;
	EndIf;
	
	OldCurrency                  = DocumentCurrency;
	PriceIncludesVAT               = Object.PriceIncludesVAT;
	DocumentPurchases               = FormAttributeToValue("Object");
	DirectionsOfActivity = Object.LineOfBusiness;
	PurchaseConditions                = PurchasesServer.GetPurchaseTermsAndConditions(DocumentPurchases.Terms);
	
	DocumentPurchases.FillInTermsOfPurchase(PurchaseConditions);
	ValueToFormAttribute(DocumentPurchases, "Object");
	
	DocumentCurrency = Object.Currency;

	AttributesArray = New Array;
	AttributesArray.Add("Currency");
	AttributesArray.Add("ARAPCurrency");
	AttributesArray.Add("Partner");
	AttributesArray.Add("LineOfBusiness");
	AttributesArray.Add("Organization");
	AttributesArray.Add("Terms");
	ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisObject, AttributesArray);	
	
	StructureOfActions = New Structure;
	
	If RecalculatePrices_2 Then
		
		StructureOfRecalculationOfAmount = ParametersForConvertingAmountOfNDSVToTS(ThisObject);
		
		FillParameters = PartnerPricesFillingServer.NewFillOptionsFillPrices();
		FillParameters.Insert("PopulationFields",    "Price, VATRate");
		FillParameters.Insert("Date",               Object.Date);
		FillParameters.Insert("Organization",        Object.Organization);
		FillParameters.Insert("Currency",             Object.Currency);
		FillParameters.Insert("Terms",         Object.Terms);
		FillParameters.Insert("VATTaxation", Object.VATTaxation);
		
		StructureOfActions.Insert("RecalculateAmount");
		StructureOfActions.Insert("RecalculateVATAmount",  StructureOfRecalculationOfAmount);
		StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
		StructureOfActions.Insert("ClearAmountOfSettlements");
		
		PricesCalculated = PartnerPricesFillingServer.FillInPrices(Object.Goods, Undefined, FillParameters, StructureOfActions);
		
	ElsIf PriceIncludesVAT <> Object.PriceIncludesVAT Then
		
		StructureOfRecalculationOfAmount = ParametersForRecalculatingNDSWTCHAmount(ThisObject);
		
		StructureOfActions.Insert("RecalculateVATAmount",  StructureOfRecalculationOfAmount);
		StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
		
	EndIf;
	
	If Contract <> Object.Contract Then
		Contract = Object.Contract;
	EndIf;
	
	BatchProcessingOfTablePartServer.TreatTS(Object.Goods, StructureOfActions, Undefined);
	ExecuteRecalculateDocumentAmountsServer(OldCurrency, DocumentCurrency);
	FillInServiceDetailsForProductRange();
	
	ResponsiblePersonsServer.WhenChangingRelatedDocumentDetails(Object);
	
	CalculateTotals_(ThisObject);
	CustomizeInvoicePresentation();
	
	If DirectionsOfActivity <> Object.LineOfBusiness Then
		LinesOfBusinessServer.WhenChangingDirectionOfActivity(ThisObject);
		ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);
	EndIf;
	
	ResponsiblePersonsServer.FillInManager_(Object);
	
EndProcedure

&AtServer
Procedure OrganizationOnChangeServer()
	
	DirectionsOfActivity = Object.LineOfBusiness;
	LocalAccountingCurrency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Object.Organization);
	
	If ValueIsFilled(Object.Organization) Then
		FillInDefaultContract();
		
		If DirectionsOfActivity <> Object.LineOfBusiness Then
			LinesOfBusinessServer.WhenChangingDirectionOfActivity(ThisObject);
		EndIf;
		
		UpdateBuyoutsForActivities(True);
		
		FillInVATTaxationPurchases();
		VATTaxationOnChangeServer();
		
		CustomizeInvoicePresentation();
		
		CashServer.CheckFillInOrganizationSBankAccountByOwner(Object.Organization,
			Object.CompanyBankAccount, , Object.LineOfBusiness, Object.ForeignCurrencyTransaction);
	EndIf;
	
	FillInSubordinatePropertiesForStatistics("Organization");
	ResponsiblePersonsServer.WhenChangingRelatedDocumentDetails(Object);
	
	ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisObject, "Organization");
	
	If DirectionsOfActivity <> Object.LineOfBusiness Then
		ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);
	EndIf;
	
EndProcedure

&AtServer
Procedure ContractOnChangeServer()
	
	Contract                 = Object.Contract;
	ForeignCurrencyTransaction           = Object.ForeignCurrencyTransaction;
	ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisObject, "Contract");
	
	If UseLinesOfBusiness Then
		LinesOfBusinessServer.FillInDefaultDirection(Object.LineOfBusiness, Object.Terms,
			Object.Contract);
		ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);
	EndIf;
	If Object.BusinessOperation = Enums.BusinessTransactions.RedemptionOfProviderGoods Then
		
		If ValueIsFilled(Object.Contract) Then
			FillPropertyValues(
				Object,
				Common.ObjectAttributesValues(Object.Contract, "Department"));
		EndIf;
	
	EndIf;
	
	ClearDestinationInProductsTable();
	FillInDefaultAssignment();
	UpdateBuyoutsForActivities(True);
	FillInVATTaxationPurchases();
	
	If ForeignCurrencyTransaction <> Object.ForeignCurrencyTransaction Then
		Object.CompanyBankAccount = Catalogs.CompaniesBankAccounts.EmptyRef();
	EndIf;
	
	PurchasesServerCall.FillInBankAccountsUnderAgreement(Object.Contract, Object.CompanyBankAccount,
		Object.CounterpartyBankAccount);
	
	If Not ValueIsFilled(Object.CompanyBankAccount) Then
		ParametersOfAccount = CashServer.ParametersForFillingOutOrganizationSBankAccount(Object.Organization);
		ParametersOfAccount.LineOfBusiness = Object.LineOfBusiness;
		ParametersOfAccount.ExcludeCurrencyAccounts = Object.ForeignCurrencyTransaction;
		ParametersOfAccount.Currency = LocalAccountingCurrency;
		Object.CompanyBankAccount = CashServer.GetOrganizationSDefaultBankAccount(
			ParametersOfAccount);
	EndIf;
	
	ARAPAccountingFormWork.WhenChangingParametersOfMechanism(ThisObject);
	ResponsiblePersonsServer.FillInManager_(Object);
	
EndProcedure

&AtServer
Procedure LabelCurrenciesClickCompletionServer(ClosingResult)
	
	ChangedBankingDetails = ClosingResult.OldValuesOfChangedProps;
	
	If ClosingResult.RecalculateDocumentAmounts Then
		DocumentAmountOnChangeServer(ClosingResult.DocumentAmount);
	EndIf;
	If ChangedBankingDetails.Property("Currency") Then
		DocumentCurrency = Object.Currency;
	EndIf;
	
	If ChangedBankingDetails.Property("ARAPCurrency") Then
		FillInDefaultContract();
	EndIf;
	
	ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisObject, ChangedBankingDetails, True);
	
EndProcedure

&AtServer
Procedure DocumentAmountOnChangeServer(DocumentAmount)
	
	RecalculationParameters = PriceManagementSystem.ParametersForRecalculationOfTableAmountsONChangeOfExchangeRate(Object.PriceIncludesVAT, DocumentAmount);
	
	PriceManagementSystem.RecalculateTableAmountsONChangeOfExchangeRate(Object.Goods, RecalculationParameters);
	
	CalculateTotals_(ThisObject);
	
EndProcedure

&AtServer
Procedure LineOfBusinessOnChangeServer()
	
	LinesOfBusinessServer.WhenChangingDirectionOfActivity(ThisObject);
	ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);
	
	UpdateBuyoutsForActivities();
	ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisObject, "LineOfBusiness");
	
EndProcedure

&AtServer
Procedure VATTaxationOnChangeServer()
	
	CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	StructureOfActions = New Structure;
	StructureOfActions.Insert("AdjustVATRate", BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRate(Object));
	BatchProcessingOfTablePartServer.TreatTS(Object.Goods, StructureOfActions, CachedValues);
	
	StructureOfRecalculationOfAmount = ParametersForRecalculatingNDSWTCHAmount(ThisObject);
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateVATAmount",  StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("ClearAmountOfSettlements");
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		CachedValues.ProcessedRows,
		StructureOfActions,
		Object.Goods,
		Undefined);
	
	CustomizeInvoicePresentation();
	CalculateTotals_(ThisObject);

	VATAccountingERP.SetVisibilityOfCommandAndFillInVATRate(ThisObject);

EndProcedure

&AtServer
Procedure PriceIncludesVATOnChangeServer(CachedValues)
	
	StructureOfRecalculationOfAmount = ParametersForRecalculatingNDSWTCHAmount(ThisObject);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	
	BatchProcessingOfTablePartServer.TreatTS(Object.Goods, StructureOfActions, CachedValues);
	
	CalculateTotals_(ThisObject);
	
EndProcedure

&AtServer
Procedure WhenBusinessTransactionChangesServer()
	Operations = New  Array;
	Operations.Add(BusinessTransactionBeforeTheChange);
	Operations.Add(Object.BusinessOperation);
	
	If Operations.Find(Enums.BusinessTransactions.RedemptionOfProviderGoods) <> Undefined
	   And Object.Goods.Count() > 0 Then
		Object.Goods.Clear();
	EndIf;
	FillInDefaultContract();
	
	FillInSelectionListProductsStorageLocationType();
	
	CustomizeForm();
	
	BusinessTransactionBeforeTheChange = Object.BusinessOperation;
	
EndProcedure

#EndRegion

#Region WorkingWithCounterparties
#EndRegion

#Region InventoryKinds

&AtServer
Procedure GetStockTypesFromStorage(ValueSelected)
	
	InventoriesServer.ProcessInputOfInventoryTypesManually(ValueSelected, ThisObject);
	
EndProcedure

&AtServer
Function PutGoodsAndStockTypesInStorage()
	
	Return InventoriesServer.PutGoodsAndStockTypesInStorage(ThisObject);
	
EndFunction

#EndRegion

#Region WorkingWithClipboard

&AtClient
Procedure SetAvailabilityOfClipboardCommandsOnClient()
	
	ItemArray = New Array();
	ItemArray.Add("GoodsInsertRows");
	ItemArray.Add("GoodsContextMenuInsertRows");
	
	TMCommonUseClientServer.SetPropertyOfFormElements(Items, ItemArray, "Enabled", True);
	
EndProcedure

&AtServer
Procedure SetAvailabilityOfClipboardCommands()
	
	ItemArray = New Array();
	ItemArray.Add("GoodsInsertRows");
	ItemArray.Add("GoodsContextMenuInsertRows");
	
	TMCommonUseClientServer.SetPropertyOfFormElements(Items, ItemArray, "Enabled",
		ProcessingOfTabularForms.ThereAreLinesInClipboard());
	
EndProcedure

&AtServer
Procedure CopyLinesOnServer()
	
	ProcessingOfTabularForms.CopyRowsToClipboard(Object.Goods, Items.Goods.SelectedRows);
	
EndProcedure

&AtServer
Procedure GetLinesFromClipboard()
	
	FilterParameters = New Map;
	FilterParameters.Insert("Products.ItemsType", ProductsClientServer.SelectionByProductMultiTurnContainer(False));
	
	Columns = "Products,Characteristic,Package,NumberOfPackages,Price";
	
	TableOfGoods = ProcessingOfTabularForms.RowsFromClipboard(FilterParameters, Columns);
	
	If Not ValueIsFilled(TableOfGoods) Then
		Return;
	EndIf;
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInVATRate", BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRate(Object));
	
	AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions, ThisObject);
	LinesOfBusinessClientServer.StructureOfInsertActionsWhenAddingRow(ThisObject, StructureOfActions);
	AddStorageLocationInitializationToActionStructure(StructureOfActions);
	
	CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	RowsToProcess = New Array();
	
	For Each RowOfProduct In TableOfGoods Do
		
		CurrentRow = Object.Goods.Add();
		FillPropertyValues(CurrentRow, RowOfProduct);
		RowsToProcess.Add(CurrentRow);
		
	EndDo;
	
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		RowsToProcess,
		StructureOfActions,
		Object.Goods,
		CachedValues);
	
	FillInServiceDetailsForProductRange();
	FillInStorageLocationPresentation();
	ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);
	
	CalculateTotals_(ThisObject);
	
EndProcedure

&AtServer
Procedure ChangedPaymentServer(EventName, Parameter, Source)
	
	ARAPAccountingFormWork.NotificationProcessing(ThisObject, EventName, Parameter);
	
EndProcedure

#EndRegion

#Region BarcodesAndTradeEquipment

&AtClient
Procedure ProcessBarcodes(BarcodeData_5)
	
	ClearMessages();
	
	If Not BarcodingOfItemsClient.BarcodesAreValid(BarcodeData_5) Then
		Return;
	EndIf;
	
	FillInArticleAttribute         = New Structure("Products", "SKU");
	FillInProductTypeAttribute_ = New Structure("Products", "ItemsType");
	
	StructureOfActionsWithAddedStrings = New Structure;
	StructureOfActionsWithAddedStrings.Insert("FillInArticleAttribute",         FillInArticleAttribute);
	StructureOfActionsWithAddedStrings.Insert("FillInProductTypeAttribute_", FillInProductTypeAttribute_);
	StructureOfActionsWithAddedStrings.Insert("FillInVATRate", BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRate(Object));
	StructureOfActionsWithAddedStrings.Insert("FillInProductNameOfProductPartner", Object.Partner);
	
	LinesOfBusinessClientServer.StructureOfInsertActionsWhenAddingRow(ThisObject,
		StructureOfActionsWithAddedStrings);
	AddActionsToStructureWhenChangingPackagesNumber(StructureOfActionsWithAddedStrings, ThisObject);
	AddStorageLocationInitializationToActionStructure(StructureOfActionsWithAddedStrings);
	
	If Not Items.GoodsStorageType.Visible Then
		CheckSeriesCalculateStatus = New Structure("SeriesSpecificationParameters, Warehouse",
														SeriesSpecificationParameters, Undefined);
		
		StructureOfActionsWithAddedStrings.Insert("CheckSeriesCalculateStatus",  CheckSeriesCalculateStatus);
	EndIf;
	
	StructureOfActionsWithModifiedStrings = New Structure;
	AddActionsToStructureWhenChangingPackagesNumber(StructureOfActionsWithModifiedStrings, ThisObject);
	
	StructureOfActions = BarcodingOfItemsClient.BarcodeProcessingParameters();
	StructureOfActions.Barcodes                              = BarcodeData_5;
	StructureOfActions.StructureOfActionsWithAddedStrings = StructureOfActionsWithAddedStrings;
	StructureOfActions.StructureOfActionsWithModifiedStrings  = StructureOfActionsWithModifiedStrings;
	StructureOfActions.SeriesSpecificationParameters                 = SeriesSpecificationParameters;
	StructureOfActions.GoodsOnly                           = True;
	
	ProcessBarcodesServer(StructureOfActions, CachedValues);
	
	BarcodingOfItemsClient.ProcessUnknownBarcodes(StructureOfActions, CachedValues, ThisObject);
	
	If BarcodingOfItemsClient.YouNeedToOpenFormForSpecifyingSeriesAfterProcessingBarcodes(StructureOfActions) Then
		CurDataId = StructureOfActions.ArrayOfRowsWithSeries_[0];
		
		AttachIdleHandler("OpenSeriesSelectionWhenScanningProductBarCode", 0.1, True);
	EndIf;
	
	If StructureOfActions.CurrentRow <> Undefined Then
		Items.Goods.CurrentRow = StructureOfActions.CurrentRow;
	EndIf;
	
	CalculateTotals_(ThisObject);
	
EndProcedure

&AtServer
Procedure ProcessBarcodesServer(StructureOfActionParameters, CachedValues)
	
	BarcodingOfItemsServer.ProcessBarcodes(ThisObject, Object, StructureOfActionParameters,
		CachedValues);
	
EndProcedure

#EndRegion

#Region SelectionAndProcessingOfQuantityVerification

&AtServer
Procedure ProcessingSelectionOfSelectionOnServer(ValueSelected)
	
	TableOfGoods       = GetFromTempStorage(ValueSelected.GoodsAddressInStorage);
	CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	RowsToProcess = New Array();
	
	ListOfProperties = "PartnerProducts, Products, Characteristic, ItemVariantsAreUsed, Package, Price,
					|NumberOfPackages";
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInVATRate", BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRate(Object));
	
	LinesOfBusinessClientServer.StructureOfInsertActionsWhenAddingRow(ThisObject, StructureOfActions);
	AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions, ThisObject);
	AddStorageLocationInitializationToActionStructure(StructureOfActions);
	
	For Each RowOfProduct In TableOfGoods Do
		CurrentRow = Object.Goods.Add();
		FillPropertyValues(CurrentRow, RowOfProduct, ListOfProperties);
		RowsToProcess.Add(CurrentRow);
	EndDo;
	
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		RowsToProcess,
		StructureOfActions,
		Object.Goods,
		CachedValues);
	
	FillInServiceDetailsForProductRange();
	ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);
	
	CalculateTotals_(ThisObject);
	
EndProcedure

&AtServer
Procedure ProcessingOfSelectionSelectionOfServerAcceptedForResponsibleStorage(ValueSelected, PricesCalculated)
	
	RowsArray = New Array;
	
	TableOfGoods = GetFromTempStorage(ValueSelected.GoodsAddressInStorage);
	CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	
	PriceFillingParameters = PartnerPricesFillingServer.NewFillOptionsFillPrices();
	PriceFillingParameters.Insert("PopulationFields",		"Price, VATRate");
	PriceFillingParameters.Insert("Date",					Object.Date);
	PriceFillingParameters.Insert("Organization", 			Object.Organization);
	PriceFillingParameters.Insert("Currency",				Object.Currency);
	PriceFillingParameters.Insert("Terms",			Object.Terms);
	PriceFillingParameters.Insert("VendorPriceKind",	Object.VendorPriceKind);
	PriceFillingParameters.Insert("VATTaxation",	Object.VATTaxation);
	
	StructureOfRecalculationOfAmount = ParametersForConvertingAmountOfNDSVToTS(ThisObject);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateNumberOfPackages");
	StructureOfActions.Insert("FillInVATRate", BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRate(Object));
	
	StorageLocations_ = StorageLocations_();
	StorageLocations_.Insert("Contract", PredefinedValue("Enum.StorageLocationTypes.CounterpartyContract"));
	
	For Each RowOfProduct In TableOfGoods Do
		
		If TypeOf(RowOfProduct.StorageLocation) = Type("CatalogRef.Warehouses") Then
			StorageLocationName = "Warehouse";
		ElsIf TypeOf(RowOfProduct.StorageLocation) = Type("CatalogRef.BusinessStructure") Then
			StorageLocationName = "Department";
		ElsIf TypeOf(RowOfProduct.StorageLocation) = Type("CatalogRef.CounterpartyContracts") Then
			StorageLocationName = "Contract";
		EndIf;
		
		ProductsSearch = New Structure();
		ProductsSearch.Insert("Products", RowOfProduct.Products);
		ProductsSearch.Insert("Characteristic", RowOfProduct.Characteristic);
		ProductsSearch.Insert("Purpose", RowOfProduct.Purpose);
		If Not RowOfProduct.DifferentSeriesAccounting Then
			ProductsSearch.Insert("Series", RowOfProduct.Series);
		EndIf;
		ProductsSearch.Insert(StorageLocationName, RowOfProduct.StorageLocation);
		ProductsSearch.Insert("Custodian", RowOfProduct.Custodian);
		ProductLines_2 = Object.Goods.FindRows(ProductsSearch);
		
		If ProductLines_2.Count() = 0 Then
			
			CurrentRow = Object.Goods.Add();
			FillPropertyValues(CurrentRow, RowOfProduct);
			CurrentRow.StorageType = StorageLocations_[StorageLocationName];
			CurrentRow[StorageLocationName] = RowOfProduct.StorageLocation;
			
		ElsIf ProductLines_2.Count() = 1 Then
			
			CurrentRow = ProductLines_2[0];
			
		ElsIf ProductLines_2.Count() > 1 Then
			
			For Each RowToDelete In ProductLines_2 Do
				Object.Goods.Delete(RowToDelete);
			EndDo;
			
			CurrentRow = Object.Goods.Add();
			FillPropertyValues(CurrentRow, RowOfProduct);
			CurrentRow.StorageType = StorageLocations_[StorageLocationName];
			CurrentRow[StorageLocationName] = RowOfProduct.StorageLocation;
			
		EndIf;
		
		CurrentRow.Count = RowOfProduct.QuantityIsSelected;
		RowsArray.Add(CurrentRow);
		
	EndDo;
	
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		RowsArray,
		StructureOfActions,
		Object.Goods,
		CachedValues);
	
	FillInServiceDetailsForProductRange();
	FillInStorageLocationPresentation(True);
	ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);
	
	StructureOfPriceCalculationActions = New Structure;
	StructureOfPriceCalculationActions.Insert("RecalculateAmount");
	StructureOfPriceCalculationActions.Insert("RecalculateVATAmount",  StructureOfRecalculationOfAmount);
	StructureOfPriceCalculationActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfPriceCalculationActions.Insert("ClearAmountOfSettlements");
	
	PricesCalculated = PartnerPricesFillingServer.FillInPrices(Object.Goods,
																RowsArray,
																PriceFillingParameters,
																StructureOfPriceCalculationActions);
	
	CalculateTotals_(ThisObject);
	
EndProcedure

&AtServer
Function PutTablePartOfGoodsInTemporaryStorageToCheckQuantity()
	
	TabularPartProducts = Object.Goods.Unload(,"Products, Characteristic, ItemVariantsAreUsed, Package,
		|NumberOfPackages, Series, BatchesIndicationStatus, ItemsType, Warehouse");
	TabularPartProducts.GroupBy("Products, Characteristic, ItemVariantsAreUsed, Package, Series,
		|BatchesIndicationStatus, ItemsType, Warehouse", "NumberOfPackages");
	
	AddressInTempStorage = PutToTempStorage(TabularPartProducts, UUID);
	
	Return AddressInTempStorage;
	
EndFunction

&AtServer
Procedure ChangeTablePartBasedOnResultsOfCheck(ReturnParameters, CachedValues)
	
	GoodsTable = GetFromTempStorage(ReturnParameters.Goods);
	
	LinesToDelete = New Array;
	RowsToProcess = New Array;
	ProcessedLinesAreNew = New Array;
	
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
			
			If SourceRow.NumberOfPackages > 0 Then
				
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

	StructureOfActions = New Structure;
	AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions, ThisObject);
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		RowsToProcess,
		StructureOfActions,
		Object.Goods,
		CachedValues);

	StructureOfActions.Insert("FillInVATRate", BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRate(Object));
	StructureOfActions.Insert("FillInProductNameOfProductPartner", Object.Partner);
	AddStorageLocationInitializationToActionStructure(StructureOfActions);
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
	
	FillInServiceDetailsForProductRange();
	ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);
	
	CalculateTotals_(ThisObject);
	
EndProcedure

#EndRegion

#Region SetOfSeries

&AtServer
Procedure PrepareFillSetSeriesVisibility()
	
	StructureOfSeriesIndicationParameters = ProductsServer.SeriesSpecificationParameters(Object,
																				Documents.RedemptionOfGoodsFromStorage);
	
	SeriesSpecificationParameters = New FixedStructure(StructureOfSeriesIndicationParameters);
	ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);
	
	SetVisibilityOfSeriesElements();
	
EndProcedure

&AtServer
Procedure SetVisibilityOfSeriesElements()
	
	Items.GoodsBatchesIndicationStatus.Visible = SeriesSpecificationParameters.UseItemsBatch;
	Items.GoodsSpecifySeries.Visible        = SeriesSpecificationParameters.UseItemsBatch;
	Items.GoodsSeries.Visible               = SeriesSpecificationParameters.UseCostAccountingByBatches;
	
EndProcedure

&AtClient
Procedure OpenSeriesSelectionWhenScanningProductBarCode()
	
	If CurDataId = Undefined Then
		Return;
	EndIf;
	
	CurrentData = Object.Goods.FindByID(CurDataId);
	
	OpenSelectionOfSeries(, CurrentData);
	
EndProcedure

&AtClient
Procedure OpenSelectionOfSeries(Text = "", CurrentData = Undefined)
	
	NeedServerCall = ProductsClient.YouNeedServerCallToSpecifySeries(ThisObject,
																				SeriesSpecificationParameters,
																				Text,
																				CurrentData);
	
	If NeedServerCall Then
		If CurrentData = Undefined Then
			CurDataId = Items.Goods.CurrentData.GetID();
		Else
			CurDataId = CurrentData.GetID();
		EndIf;
		
		ParametersOfSeriesIndicationForm = ParametersOfSeriesIndicationForm(CurDataId);
		AdditionalParameters     = New Structure("ParametersOfSeriesIndicationForm", ParametersOfSeriesIndicationForm);
		CallbackDescription          = New CallbackDescription("OpenSelectionOfSeriesCompletion", ThisObject,
			AdditionalParameters);
		
		OpenForm(ParametersOfSeriesIndicationForm.FormName, ParametersOfSeriesIndicationForm, ThisObject, , , , CallbackDescription,
			FormWindowOpeningMode.LockOwnerWindow);
	EndIf;
	
EndProcedure

&AtClient
Procedure OpenSelectionOfSeriesCompletion(Result, AdditionalParameters) Export
	
	If Result <> Undefined Then
		ProcessSeriesIndication_Server(AdditionalParameters.ParametersOfSeriesIndicationForm);
	EndIf;
	
EndProcedure

&AtServer
Procedure ProcessSeriesIndication_Server(ParametersOfSeriesIndicationForm)
	
	ProductsServer.ProcessSeriesIndication_(Object, SeriesSpecificationParameters, ParametersOfSeriesIndicationForm);
	
EndProcedure

&AtServer
Function ParametersOfSeriesIndicationForm(CurDataId)
	
	Return ProductsServer.ParametersOfSeriesIndicationForm(Object, SeriesSpecificationParameters, CurDataId,
		ThisObject);
	
EndFunction

&AtServer
Procedure FillInStatusesOfSpecifyingSeriesWhenEditingLineTS(IDCurrentRow, CachedValues)
	
	ProductsServer.FillInStatusesOfSpecifyingSeriesWhenEditingLineTS(Object, SeriesSpecificationParameters,
		IDCurrentRow, CachedValues);
	
EndProcedure

&AtServer
Procedure FillInStatusesForSpecifyingSeriesServer()
	
	ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);
	
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
		
		For Each String In Items.Goods.SelectedRows Do
			RowsArray.Add(Object.Goods.FindByID(String));
		EndDo;
	EndIf;
	
	StructureOfRecalculationOfAmount = ParametersForConvertingAmountOfNDSVToTS(ThisObject);
	
	FillParameters = PartnerPricesFillingServer.NewFillOptionsFillPrices();
	FillParameters.Insert("PopulationFields", "Price");
	FillParameters.Insert("Date",           Object.Date);
	FillParameters.Insert("Organization",    Object.Organization);
	FillParameters.Insert("Currency",         Object.Currency);
	FillParameters.Insert("Terms",     Object.Terms);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateAmount");
	StructureOfActions.Insert("RecalculateVATAmount",  StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("ClearAmountOfSettlements");
	
	PricesCalculated = PartnerPricesFillingServer.FillInPrices(Object.Goods, RowsArray, FillParameters,
		StructureOfActions);
	
	CalculateTotals_(ThisObject);
	
	Return PricesCalculated;
	
EndFunction

&AtClient
Procedure FillInPricesBySupplierPriceType(FillSelectedLines = False)
	
	TabularSectionName           = "Goods";
	TabularSectionPresentation = NStr("vi = 'Hàng hóa';
										|ru = 'Товары';
										|en = 'Goods'; fa = 'کالاها';
										|it = 'Merci';
										|pl = 'Wiersze pozycji';
										|tr = 'Ürünler'");
	
	FillInPrices = PartnerPricesFillingClient.ItIsNecessaryToFillInPricesAccordingToSupplierSPriceType(Object, TabularSectionName,
		TabularSectionPresentation);
	
	If FillInPrices Then
		
		If Not ValueIsFilled(Object.VendorPriceKind) Then
			WarningText = NStr("vi = 'Chứng từ không chỉ ra dạng giá của nhà cung cấp. Không thể điền được giá.';
								|ru = 'В документе не указан вид цены поставщика. Цены не могут быть заполнены';
								|en = 'Vendor price type is not specified in the document. Prices cannot be filled in'; fa = 'Vendor price type is not specified in the document. Prices cannot be filled in';
								|it = 'Il documento non indica il tipo di prezzo del fornitore. I prezzi non possono essere compilati';
								|pl = 'W dokumencie nie podano rodzaj ceny dostawcy. Ceny nie mogą zostać wypełnione';
								|tr = 'Belgede tedarikçi fiyat türü belirtilmemiştir. Fiyatlar doldurulamaz'");
			
			ShowMessageBox(, WarningText);
		Else
			PricesCalculated = FillInThePricesOfTheSelectedLinesByTheTypeOfSupplierSPriceServer(FillSelectedLines);
			
			PartnerPricesFillingClient.NotifyAboutEndOfFillingInPricesByTypeOfSupplierSPrice(PricesCalculated, Object.VendorPriceKind);
		EndIf;
		
	EndIf;
	
EndProcedure

&AtServer
Function FillInThePricesOfTheSelectedLinesByTheTypeOfSupplierSPriceServer(FillSelectedLines)
	
	RowsArray = New Array;
	
	For Each String In Items.Goods.SelectedRows Do
		TableRow = Object.Goods.FindByID(String);
		
		RowsArray.Add(TableRow);
	EndDo;
	
	StructureOfRecalculationOfAmount = ParametersForConvertingAmountOfNDSVToTS(ThisObject);
	
	FillParameters = PartnerPricesFillingServer.NewFillOptionsFillPrices();
	FillParameters.Insert("PopulationFields",    "Price, VATRate");
	FillParameters.Insert("Date",              Object.Date);
	FillParameters.Insert("Currency",            Object.Currency);
	FillParameters.Insert("VendorPriceKind", Object.VendorPriceKind);
	FillParameters.Insert("Organization", Object.Organization);
	FillParameters.Insert("VATTaxation", Object.VATTaxation);
	
	ActionsWithStrings = New Structure;
	ActionsWithStrings.Insert("RecalculateAmount",     "NumberOfPackages");
	ActionsWithStrings.Insert("RecalculateVATAmount",  StructureOfRecalculationOfAmount);
	ActionsWithStrings.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	ActionsWithStrings.Insert("ClearAmountOfSettlements");
	
	PricesCalculated = PartnerPricesFillingServer.FillInPrices(Object.Goods, RowsArray, FillParameters, ActionsWithStrings);
	
	CalculateTotals_(ThisObject);
	
	Return PricesCalculated;
	
EndFunction

#EndRegion

#Region BusinessTransactions

&AtServer
Procedure CustomizeForm()
	
	ItemArray = New Array;
	ItemArray.Add("GoodsFillInTheItemByThePartnerSItem");
	ItemArray.Add("GroupProductsPrices");
	ItemArray.Add("GoodsStorageType");
	
	VisibilityOfElements = True;
	
	Items.Partner.Title = PartnersAndCounterparties.HeaderOfPartnerDetailsDependingOnBusinessOperation(
		Object.BusinessOperation, True);
	
	If Object.BusinessOperation = Enums.BusinessTransactions.RedemptionOfGoodsFromStorage Then
		
		AutoTitle = True;
		Title     = "";
		
		Items.GoodsPickUpTheGoodsAcceptedForSafeStorage.Title =
			NStr("vi = 'Chọn hàng hóa, để bảo quản';
				|ru = 'Подобрать товары, принятые на ответственное хранение';
				|en = 'Select available VMI'; fa = 'انتخاب VMI موجود';
				|it = 'Seleziona le merci accettate per la custodia di sicurezza';
				|pl = 'Wybierz wiersze pozycji przyjęte do depozytowania';
				|tr = 'Sorumlu olunan depoya alınacak ürünleri seçin'");
		Items.GoodsFillThePricesByTermsOfSales.Visible = True;
		Items.LineOfBusiness.ReadOnly    = False;
		VisibilityOfElements = True;
		
	ElsIf Object.BusinessOperation = Enums.BusinessTransactions.DeliveryForPrincipal Then
		
		AutoTitle = True;
		Title     = "";
		
		Items.GoodsPickUpTheGoodsAcceptedForSafeStorage.Title =
			NStr("vi = 'Chọn hàng hóa, để bảo quản';
				|ru = 'Подобрать товары, принятые на ответственное хранение';
				|en = 'Select available VMI'; fa = 'انتخاب VMI موجود';
				|it = 'Seleziona le merci accettate per la custodia di sicurezza';
				|pl = 'Wybierz wiersze pozycji przyjęte do depozytowania';
				|tr = 'Sorumlu olunan depoya alınacak ürünleri seçin'");
		Items.GoodsFillThePricesByTermsOfSales.Visible = True;
		Items.LineOfBusiness.ReadOnly    = False;
		VisibilityOfElements = False;
	ElsIf Object.BusinessOperation = Enums.BusinessTransactions.RedemptionOfProviderGoods Then
		
		AutoTitle = False;
		
		ObjectPresentation = TollingSchemeClientServer.SynonymForDocumentRedemptionOfGoodsAcceptedForStorage();
		
		If ValueIsFilled(Parameters.Key) Then
			Title = StrTemplate(NStr("vi = '%1%2 ngày %3';
									|ru = '%1 %2 от %3';
									|en = '%1 %2 dated %3'; fa = '%1 %2 dated %3';
									|it = '%1 %2 del %3';
									|pl = '%1 %2 z dnia %3';
									|tr = '%3 tarihli %1 %2'"), ObjectPresentation, Object.Number, Object.Date);
		Else
			Title = StrTemplate(NStr("vi = '%1 (tạo mới)';
									|ru = '%1 (создание)';
									|en = '%1 (create)'; fa = '%1 (create)';
									|it = '%1 (creazione)';
									|pl = '%1 (tworzenie)';
									|tr = '%1 (oluştur)'"), ObjectPresentation);
		EndIf;
		
		Items.GoodsPickUpTheGoodsAcceptedForSafeStorage.Title =
			NStr("vi = 'Chọn hàng hóa của bên đặt gia công';
				|ru = 'Подобрать товары давальца';
				|en = 'Pick provider goods'; fa = 'Pick provider goods';
				|it = 'Selezionare merci del fornitore';
				|pl = 'Wybierz towary właściciela surowców';
				|tr = 'Sağlayıcının ürünlerini seçin'");
		
		Items.GoodsFillThePricesByTermsOfSales.Visible = False;
		Items.LineOfBusiness.ReadOnly    = True;
		
		VisibilityOfElements = True;
	EndIf;
	
	TMCommonUseClientServer.SetPropertyOfFormElements(
		Items, ItemArray, "Visible", VisibilityOfElements);
	
	SetVisibilityOfAgreements(Items, Object);
	
	AdjustItemSelectionSettings();
	
EndProcedure

&AtServer
Procedure AdjustItemSelectionSettings()
	
	// Partner
	PartnerSelectionParameters       = New Array;
	
	// Fin group. accounting of calculations
	HFCSelectionParameters           = New Array;
	
	//Contract
	ContractSelectionParameters       = New Array;
	ContractSelectionParameters.Add(New ChoiceParameter("Filter.DeletionMark", False));
	ContractSelectionParameters.Add(New ChoiceParameter("Filter.BusinessOperation", ContractBusinessTransaction));
	
	ContractSelectionParameters.Add(
		New ChoiceParameter("Filter.Status", Enums.CounterpartyContractStatuses.Valid));
	
	RelationsOfContractSelectionParameters = New Array;
	RelationsOfContractSelectionParameters.Add(
		New ChoiceParameterLink(
				"Filter.ARAPCurrency", "Object.ARAPCurrency", LinkedValueChangeMode.Clear));
		
	RelationsOfContractSelectionParameters.Add(
		New ChoiceParameterLink(
				"Filter.Counterparty", "Object.Counterparty", LinkedValueChangeMode.Clear));
		
	RelationsOfContractSelectionParameters.Add(
		New ChoiceParameterLink(
				"Filter.Organization", "Object.Organization", LinkedValueChangeMode.Clear));
		
	RelationsOfContractSelectionParameters.Add(
		New ChoiceParameterLink(
				"Partner", "Object.Partner", LinkedValueChangeMode.Clear));
	
	If Object.BusinessOperation = Enums.BusinessTransactions.RedemptionOfGoodsFromStorage Then
	
		// Partner
		PartnerSelectionParameters.Add(New ChoiceParameter("Filter.Vendor", True));
		
		// Fin group. accounting of calculations
		HFCSelectionParameters.Add(New ChoiceParameter("Filter.VendorsARAPAccounting", True));
		
		//Contract
		ContractSelectionParameters.Add(
			New ChoiceParameter("Filter.ContractType", Enums.ContractTypes.ReceivingForCustody));
		
		RelationsOfContractSelectionParameters.Add(
			New ChoiceParameterLink(
					"Terms", "Object.Terms", LinkedValueChangeMode.DontChange));
	
	ElsIf Object.BusinessOperation = Enums.BusinessTransactions.DeliveryForPrincipal Then
	
		// Partner
		PartnerSelectionParameters.Add(New ChoiceParameter("Filter.Client", True));
		
		// Fin group. accounting of calculations
		HFCSelectionParameters.Add(New ChoiceParameter("Filter.VendorsARAPAccounting", True));
		
		//Contract
		ContractSelectionParameters.Add(
			New ChoiceParameter("Filter.ContractType", Enums.ContractTypes.CustomerInvoiceOutsourcedSale));
		
		RelationsOfContractSelectionParameters.Add(
			New ChoiceParameterLink(
					"Terms", "Object.Terms", LinkedValueChangeMode.DontChange));
	ElsIf Object.BusinessOperation = Enums.BusinessTransactions.RedemptionOfProviderGoods Then
	
		// Partner
		PartnerSelectionParameters.Add(New ChoiceParameter("Filter.Client", True));
		PartnerSelectionParameters.Add(New ChoiceParameter("Filter.Vendor", True));
		
		// Fin group. accounting of calculations
		HFCSelectionParameters.Add(New ChoiceParameter("Filter.ProvidersARAP", True));
		
		//Contract
		ContractSelectionParameters.Add(
			New ChoiceParameter("Filter.ContractType", Enums.ContractTypes.ReceiptForTolling2_5));
	EndIf;
	
	Items.Partner.ChoiceParameters                = New FixedArray(PartnerSelectionParameters);
	
	Items.Contract.ChoiceParameters                = New FixedArray(ContractSelectionParameters);
	Items.Contract.ChoiceParameterLinks          = New FixedArray(RelationsOfContractSelectionParameters);
	
	Items.FinancialAccountingGroup.ChoiceParameters = New FixedArray(HFCSelectionParameters);
	
EndProcedure

&AtClientAtServerNoContext
Function ContractBusinessTransaction(DocumentBusinessTransaction)
	
	BusinessTransaction = PredefinedValue("Enum.BusinessTransactions.EmptyRef");
	
	If DocumentBusinessTransaction =
					PredefinedValue("Enum.BusinessTransactions.RedemptionOfGoodsFromStorage") Then
		
		BusinessTransaction = PredefinedValue("Enum.BusinessTransactions.ReceivingForStorageWithRightOfSale");
		
	ElsIf DocumentBusinessTransaction =
						PredefinedValue("Enum.BusinessTransactions.DeliveryForPrincipal") Then
		
		BusinessTransaction = DocumentBusinessTransaction;
	ElsIf DocumentBusinessTransaction =
						PredefinedValue("Enum.BusinessTransactions.RedemptionOfProviderGoods") Then
		
		BusinessTransaction = TollingSchemeClientServer.ContractBusinessTransaction();
	EndIf;
	
	Return BusinessTransaction;
	
EndFunction

#EndRegion
#Region Assignments

&AtServer
Procedure FillInDefaultAssignment()
	
	If Object.BusinessOperation = Enums.BusinessTransactions.RedemptionOfProviderGoods Then
		
		DefaultAssignment = Common.ObjectAttributeValue(Object.Contract, "Purpose");
		
	ElsIf ValueIsFilled(DefaultAssignment) Then
		
		DefaultAssignment = Catalogs.Assignments.EmptyRef();
		
	EndIf;
	
EndProcedure

&AtServer
Procedure ClearDestinationInProductsTable()
	
	FoundRows = Object.Goods.FindRows(New Structure("Purpose", Catalogs.Assignments.EmptyRef()));
	If Object.Goods.Count() > FoundRows.Count() Then
		
		For Each TableRow In Object.Goods Do
			
			If Not ValueIsFilled(TableRow.Purpose) Then
				Continue;
			EndIf;
			
			TableRow.Purpose = Undefined;
			
		EndDo;
		
	EndIf;
	
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
Procedure SetConditionalAppearance()
	
	ConditionalAppearance.Items.Clear();
	
	// Setting the conditional design for the 'Partner Nomenclature' element of the 'Products' tabular part
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsPartnerProducts.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Partner");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.EmptyTableField);
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<hãy chọn nhà cung cấp>';
													|ru = '<выберите поставщика>';
													|en = '<select vendor>'; fa = '<select vendor>';
													|it = '<selezionare il fornitore>';
													|pl = '<wybierz dostawcę>';
													|tr = '<tedarikçi seçin>'"));
	Item.Appearance.SetParameterValue("ReadOnly", True);
	
	// Setting the conditional design for the items of the nomenclature of the tabular part 'Goods'
	ProductsServer.EstablishConditionalAppearanceOfProductCharacteristics(ThisObject);
	ProductsServer.SetConditionalAppearanceOfProductAssignment(ThisObject);
	ProductsServer.EstablishConditionalAppearanceOfProductSeries(ThisObject, False);
	ProductsServer.SetConditionalAppearanceOfStatusIndicationSeries(ThisObject, True);
	ProductsServer.SetConditionalAppearanceOfUnitsOfMeasurement(ThisObject);
	
	// Setting the conditional design for the 'Price' element of the 'Products' tabular part
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsPrice.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.Price");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	Item.Appearance.SetParameterValue("MarkIncomplete", True);
	
	// Setting the conditional design for the 'Amount' element of the 'Products' tabular part
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsSum.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.Sum");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	Item.Appearance.SetParameterValue("MarkIncomplete", True);
	
	// Setting the conditional design for the 'Storage View' element of the 'Products' tabular part
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsStorageLocationRepresentation.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.StorageType");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.EmptyTableField);
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<chọn giao dịch>';
													|ru = '<выберите операцию>';
													|en = '<select operation>'; fa = '<select operation>';
													|it = '<selezionare l''operazione>';
													|pl = '<wybierz operację>';
													|tr = '<uygulama seçin>'"));
	Item.Appearance.SetParameterValue("ReadOnly", True);
	
	// Setting the conditional design for the 'Storage View' element of the 'Products' tabular part
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsStorageLocationRepresentation.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.StorageType");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.StorageLocationRepresentation");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	Item.Appearance.SetParameterValue("MarkIncomplete", True);
	
	// Setting the conditional design for the 'Storage View' element of the 'Products' tabular part
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsStorageType.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.StorageType");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.StorageLocationTypes.Warehouse;
	
	Item.Appearance.SetParameterValue("Text", NStr("vi = 'Mua lại hàng trong kho';
													|ru = 'Выкуп товаров, хранящихся на складе';
													|en = 'Purchase invoice — VMI-in-stock'; fa = 'فاکتور خرید — VMI در انبار';
													|it = 'Acquisto di merci depositati in magazzino';
													|pl = 'Wykup towarów, przechowywanych w magazynie';
													|tr = 'Depolanan malların itfası'"));
	
	// Setting the conditional design for the 'Storage View' element of the 'Products' tabular part
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsStorageType.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.StorageType");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.StorageLocationTypes.Department;
	
	Item.Appearance.SetParameterValue("Text", NStr("vi = 'Mua lại hàng hóa chuyển sang sản xuất';
													|ru = 'Выкуп товаров, переданных в производство';
													|en = 'Purchase invoice — VMI-in-WIP'; fa = 'فاکتور خرید — VMI در جریان ساخت';
													|it = 'Acquisto di merci consegnate alla produzione';
													|pl = 'Wykup towarów, przekazanych do produkcji';
													|tr = 'Üretime aktarılan malların itfası'"));
	
	// Setting the conditional design for the 'Storage View' element of the 'Products' tabular part
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsStorageType.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.StorageType");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.StorageLocationTypes.CounterpartyContract;
	
	Item.Appearance.SetParameterValue("Text", NStr("vi = 'Mua lại hàng hóa được chuyển để bảo quản';
													|ru = 'Выкуп товаров, переданных на хранение';
													|en = 'Purchase invoice — VMI-in-chain'; fa = 'فاکتور خرید — VMI در زنجیره';
													|it = 'Acquisto di merci consegnate in deposito';
													|pl = 'Wykup towarów przekazanych na przechowywanie';
													|tr = 'Depodaki malların itfası'"));
		
	// Setting the conditional design for the VAT accounting elements of the "Goods" tabular part
	VATAccountingERP.EstablishConditionalAppearanceOfVATAmountsForTaxationOfPurchases(ThisObject);
	EnterprisePricesFillingServer.SetConditionalAppearancePriceIncludesVAT(ThisObject);
	
	// Setting the conditional design for the 'Division' element
	InventoriesServer.EstablishConditionalAppearanceOfDivisionForTypesOfStocks(ThisObject);
	
	// Setting the conditional design for the 'Activity Direction' element
	LinesOfBusinessServer.EstablishConditionalAppearanceOfDirectionOfActivity(ThisObject);
	
	// Setting the conditional design for the 'Product Nomenclature Partner' element of the 'Products' tabular part
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsPartnerProducts.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.BusinessOperation");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.BusinessTransactions.DeliveryForPrincipal;
	
	Item.Appearance.SetParameterValue("Visible", False);
	
	// Setting a conditional layout for the 'Product assignment' element of the 'Products' tabular part
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsPurpose.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue  = New DataCompositionField("Object.Goods.Purpose");
	ItemFilter.ComparisonType   = DataCompositionComparisonType.NotFilled;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue  = New DataCompositionField("Object.BusinessOperation");
	ItemFilter.ComparisonType   = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.BusinessTransactions.RedemptionOfProviderGoods;
	
	Item.Appearance.SetParameterValue("Text", New DataCompositionField("DefaultAssignment"));
EndProcedure

&AtServer
Procedure OnReadCreateAtServer()
	
	UseProduction             = GetFunctionalOption("UseProduction");
	UseSeveralWarehouses         = GetFunctionalOption("UseSeveralWarehouses");
	UseImportOfGoodsFromCustomsUnion = GetFunctionalOption("UseImportOfGoodsFromCustomsUnion");
	UseLinesOfBusiness       = GetFunctionalOption("UseIncomeAccountingByLinesOfBusiness");
	
	DocumentCurrency                = Object.Currency;
	Contract                        = Object.Contract;
	DocumentDateBeforeChange       = Object.Date;
	LocalAccountingCurrency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Object.Organization);
	DefaultWarehouse               = TMCommonUse.GetCheckWarehouseByDefault();
	DefaultDepartment       = SettingsValueCached.GetDefaultManagerDivision(
										Undefined,
										Object.Manager);
	
	BusinessOperationSelectionList = Items.BusinessOperation.ChoiceList;
	BusinessOperationSelectionList.Clear();
	If GetFunctionalOption("UseCustodyDuringPurchase") Then
		BusinessOperationSelectionList.Add(Enums.BusinessTransactions.RedemptionOfGoodsFromStorage);
	EndIf;
	
	If GetFunctionalOption("UseTollManufacturing2_5") Then
		BusinessOperationSelectionList.Add(Enums.BusinessTransactions.RedemptionOfProviderGoods);
	EndIf;
	If GetFunctionalOption("ProvideAgentServicesOnPurchaseToPrincipals") Then
		BusinessOperationSelectionList.Add(Enums.BusinessTransactions.DeliveryForPrincipal, NStr("vi = 'Mua lại hàng từ người đặt đại lý';
																								|ru = 'Выкуп товаров принципала';
																								|en = 'Redemption of principal''s goods'; fa = 'Redemption of principal''s goods';
																								|it = 'Riscatto delle merci del mandante';
																								|pl = 'Wykup towarów zleceniodawcy';
																								|tr = 'İş veren mallarının itfası'"));
	EndIf;
	
	Items.BusinessOperation.Visible = BusinessOperationSelectionList.Count() > 1;
	
	If Not ValueIsFilled(Object.BusinessOperation)
	   And Items.BusinessOperation.ChoiceList.Count() = 1 Then
		Object.BusinessOperation = BusinessOperationSelectionList[0].Value;
	EndIf;
	
	ContractBusinessTransaction = ContractBusinessTransaction(Object.BusinessOperation);
	FillInDefaultAssignment();
	CustomizeForm();
	
	BusinessTransactionBeforeTheChange = Object.BusinessOperation;
	
	PrepareFillSetSeriesVisibility();
	
	FillInServiceDetailsForProductRange();
	FillInSelectionListProductsStorageLocationType();
	FillInStorageLocationPresentation();
	
	FillParameters = Documents.RedemptionOfGoodsFromStorage.ParametersForFillingInVATTaxation_(Object);
	VATAccountingERP.FillInListOfVATTaxChoices(Items.VATTaxation,
															Object.VATTaxation,
															FillParameters,
															VATAccountingCachedParameterValues);
	
	UpdateBuyoutsForActivities(False);
	
	CustomizeInvoicePresentation();
	
	CalculateTotals_(ThisObject);
	
	LinesOfBusinessServer.OnReadCreateAtServer(ThisObject);
	PurchasesServer.FillInSelectionListNameOfIncomingDocument(ThisObject, Object.Counterparty);
EndProcedure

&AtClientAtServerNoContext
Procedure SetVisibilityOfAgreements(Items, Object)
	
	VisibilityAgreement = Items.Terms.Visible;
	
	If ValueIsFilled(Object.Partner) Then
		
		NumberOfSupplierAgreements = 0;
		
		If Object.BusinessOperation =
				PredefinedValue("Enum.BusinessTransactions.RedemptionOfGoodsFromStorage") Then
		
			NumberOfSupplierAgreements = PurchasesServerCall.GetNumberOfAgreementsWithSupplier(
												Object.Partner,
												New Structure("BusinessOperation", Object.BusinessOperation));
			
		EndIf;
		
		If VisibilityAgreement <> (NumberOfSupplierAgreements > 0) Then
		
			TMCommonUseClientServer.SetFormItemProperty(
				Items, "Terms", "Visible", Not VisibilityAgreement);
		
		EndIf;
			
	ElsIf VisibilityAgreement Then
		
		Items.Terms.Visible = Not VisibilityAgreement;
		
	EndIf;
	
EndProcedure

&AtServer
Procedure FillInServiceDetailsForProductRange()
	
	FillInArticleAttribute                    = New Structure("Products", "SKU");
	FillInProductTypeAttribute_            = New Structure("Products", "ItemsType");
	FillInFeatureAttribute = New Structure("Products", "ItemVariantsAreUsed");
	
	ParametersForFillingInBankingDetails = New Structure;
	ParametersForFillingInBankingDetails.Insert("FillInArticleAttribute",         FillInArticleAttribute);
	ParametersForFillingInBankingDetails.Insert("FillInProductTypeAttribute_", FillInProductTypeAttribute_);
	ParametersForFillingInBankingDetails.Insert("FillInFeatureAttribute",
		FillInFeatureAttribute);
	
	ProductsServer.FillInServiceDetailsForProductInCollection(Object.Goods, ParametersForFillingInBankingDetails);
	
EndProcedure

&AtServer
Procedure FillInSelectionListProductsStorageLocationType()
	
	ProductsTypeOfStoragePlaceSelectionList = Items.GoodsStorageType.ChoiceList;
	ProductsTypeOfStoragePlaceSelectionList.Clear();
	
	ProductsTypeOfStoragePlaceSelectionList.Add(
		Enums.StorageLocationTypes.Warehouse, NStr("vi = 'Mua lại hàng trong kho';
													|ru = 'Выкуп товаров, хранящихся на складе';
													|en = 'Purchase invoice — VMI-in-stock'; fa = 'فاکتور خرید — VMI در انبار';
													|it = 'Acquisto di merci depositati in magazzino';
													|pl = 'Wykup towarów, przechowywanych w magazynie';
													|tr = 'Depolanan malların itfası'"));
	
	If Object.BusinessOperation = Enums.BusinessTransactions.RedemptionOfGoodsFromStorage Then
		
		If GetFunctionalOption("UseProduction") Then
			
			ProductsTypeOfStoragePlaceSelectionList.Add(
				Enums.StorageLocationTypes.Department, NStr("vi = 'Mua lại hàng hóa chuyển sang sản xuất';
															|ru = 'Выкуп товаров, переданных в производство';
															|en = 'Purchase invoice — VMI-in-WIP'; fa = 'فاکتور خرید — VMI در جریان ساخت';
															|it = 'Acquisto di merci consegnate alla produzione';
															|pl = 'Wykup towarów, przekazanych do produkcji';
															|tr = 'Üretime aktarılan malların itfası'"));
			
		EndIf;
		
		If GetFunctionalOption("UseTransferToCustodyWithRightOfSale") Then
			
			ProductsTypeOfStoragePlaceSelectionList.Add(
				Enums.StorageLocationTypes.CounterpartyContract, NStr("vi = 'Mua lại hàng hóa được chuyển để lưu trữ';
																		|ru = 'Выкуп товаров, переданных на хранение';
																		|en = 'Purchase invoice — VMI-in-chain'; fa = 'فاکتور خرید — VMI در زنجیره';
																		|it = 'Acquisto di merci consegnate in deposito';
																		|pl = 'Wykup towarów przekazanych na przechowywanie';
																		|tr = 'Depodaki malların itfası'"));
			
		EndIf;
	ElsIf Object.BusinessOperation = Enums.BusinessTransactions.RedemptionOfProviderGoods Then
		
		ProductsTypeOfStoragePlaceSelectionList.Add(
			Enums.StorageLocationTypes.Department, NStr("vi = 'Mua lại hàng hóa chuyển sang sản xuất';
														|ru = 'Выкуп товаров, переданных в производство';
														|en = 'Purchase invoice — VMI-in-WIP'; fa = 'فاکتور خرید — VMI در جریان ساخت';
														|it = 'Acquisto di merci consegnate alla produzione';
														|pl = 'Wykup towarów, przekazanych do produkcji';
														|tr = 'Üretime aktarılan malların itfası'"));
		
		ProductsTypeOfStoragePlaceSelectionList.Add(
			Enums.StorageLocationTypes.CounterpartyContract, NStr("vi = 'Mua lại hàng hóa được chuyển để lưu trữ';
																	|ru = 'Выкуп товаров, переданных на хранение';
																	|en = 'Purchase invoice — VMI-in-chain'; fa = 'فاکتور خرید — VMI در زنجیره';
																	|it = 'Acquisto di merci consegnate in deposito';
																	|pl = 'Wykup towarów przekazanych na przechowywanie';
																	|tr = 'Depodaki malların itfası'"));
	EndIf;
	
EndProcedure

&AtServer
Procedure FillInStorageLocationPresentation(FillInContractDetails = False)
	
	Goods = Object.Goods;
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	Goods.LineNumber AS LineNumber,
	|	CASE
	|		WHEN Goods.StorageType = VALUE(Enum.StorageLocationTypes.Warehouse)
	|			THEN Goods.Warehouse
	|		WHEN Goods.StorageType = VALUE(Enum.StorageLocationTypes.Department)
	|			THEN Goods.Department
	|		WHEN Goods.StorageType = VALUE(Enum.StorageLocationTypes.CounterpartyContract)
	|			THEN Goods.Contract
	|		ELSE UNDEFINED
	|	END              AS StorageLocation,
	|	CASE
	|		WHEN Goods.StorageType = VALUE(Enum.StorageLocationTypes.CounterpartyContract)
	|			THEN Goods.Custodian
	|		ELSE """"
	|	END              AS PrefixStorageLocation,
	|	CASE
	|		WHEN Goods.StorageType = VALUE(Enum.StorageLocationTypes.CounterpartyContract)
	|			THEN TRUE
	|		ELSE FALSE
	|	END              AS StorageLocationContract
	|INTO ProductsToRequest
	|FROM
	|	&DocumentGoods AS Goods
	|
	|;
	|/////////////////////////////////////////////////////////////////// 1
	|SELECT
	|	Goods.LineNumber   AS LineNumber,
	|	Goods.StorageLocation AS StorageLocation,
	|	PRESENTATION(Goods.StorageLocation)        AS StorageLocationRepresentation,
	|	PRESENTATION(Goods.PrefixStorageLocation) AS PresentationPrefixStorageLocation,
	|	ISNULL(Contracts.Partner, VALUE(Catalog.Partners.EmptyRef))       AS Custodian,
	|	ISNULL(Contracts.Counterparty, VALUE(Catalog.Counterparties.EmptyRef)) AS Counterparty
	|FROM
	|	ProductsToRequest AS Goods
	|		LEFT JOIN Catalog.CounterpartyContracts AS Contracts
	|		ON Goods.StorageLocationContract
	|			AND Goods.StorageLocation = Contracts.Ref
	|
	|ORDER BY
	|	LineNumber";
	
	Query.SetParameter("DocumentGoods", Goods.Unload());
	
	Selection = Query.Execute().Select();
	
	For LineNumber = 0 To Goods.Count() - 1 Do
		Selection.Next();
		
		If FillInContractDetails Then
			Goods[LineNumber].Custodian  = Selection.Custodian;
			Goods[LineNumber].Counterparty = Selection.Counterparty;
		EndIf;
		
		Goods[LineNumber].StorageLocationRepresentation = StorageLocationRepresentation(Selection.StorageLocationRepresentation,
																					Selection.PresentationPrefixStorageLocation);
	EndDo;
	
EndProcedure

&AtClientAtServerNoContext
Function StorageLocationRepresentation(Presentation, PresentationPrefix_)
	
	ExtendedPresentationTemplate = NStr("vi = '%1, %2';
										|ru = '%1, %2';
										|en = '%1, %2'; fa = '%1, %2';
										|it = '%1, %2';
										|pl = '%1, %2';
										|tr = '%1, %2'");
	
	ExtendedPresentation   = StringFunctionsClientServer.SubstituteParametersToString(ExtendedPresentationTemplate,
																						PresentationPrefix_,
																						Presentation);
	StorageLocationRepresentation = ?(IsBlankString(PresentationPrefix_),
									Presentation,
									ExtendedPresentation);
	
	Return StorageLocationRepresentation;
	
EndFunction

&AtClientAtServerNoContext
Function ParametersForRecalculatingNDSWTCHAmount(Form)
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForRecalculatingNDSWTCHAmount(Form.Object);
	
	Return StructureOfRecalculationOfAmount;
	
EndFunction

&AtServer
Procedure UpdateBuyoutsForActivities(Fill = True)
	
	FillParameters = Documents.RedemptionOfGoodsFromStorage.ParametersForFillingInVATActivityType(Object);
	
	If Fill Then
		VATAccountingERP.FillInTypeOfActivityVAT(Object.RedemptionForActivity, FillParameters,
			VATAccountingCachedParameterValues);
	EndIf;
	
	VATAccountingERP.FillInActivitySelectionList(Items.RedemptionForActivity,
														Object.RedemptionForActivity,
														FillParameters,
														VATAccountingCachedParameterValues);
	
EndProcedure

&AtServer
Procedure FillInVATTaxationPurchases()
	
	FillParameters = Documents.RedemptionOfGoodsFromStorage.ParametersForFillingInVATTaxation_(Object);
	
	VATAccountingERP.FillInVATTaxationPurchases(Object.VATTaxation,
												FillParameters,
												VATAccountingCachedParameterValues);
	VATAccountingERP.FillInListOfVATTaxChoices(Items.VATTaxation,
															Object.VATTaxation,
															FillParameters,
															VATAccountingCachedParameterValues);
	
	VATTaxationOnChangeServer();
	
EndProcedure

&AtServer
Procedure CustomizeInvoicePresentation()
	
	RegistrationParameters = Documents.RedemptionOfGoodsFromStorage.ParametersForRegisteringInvoicesReceived(Object);
	InvoicesReceivedOnBasisOf = VATAccountingERP.InvoicesReceivedOnBasisOf(RegistrationParameters);
	
	TextInvoice = InvoicesReceivedOnBasisOf.Presentation;
	
EndProcedure

&AtClientAtServerNoContext
Procedure CalculateTotals_(Form)
	
	If Form.Object.VATTaxation = PredefinedValue("Enum.VATTaxationTypes.SaleIsNotSubjectToVAT") Then
		Form.Items.VATPageGroup.CurrentPage   = Form.Items.PageExcludingVAT;
		Form.Items.PagesTotalGroup.CurrentPage = Form.Items.PageTotalWithoutVAT;
	Else
		Form.Items.VATPageGroup.CurrentPage   = Form.Items.PageVAT;
		Form.Items.PagesTotalGroup.CurrentPage = Form.Items.TotalSNDSPage;
	EndIf;
	
EndProcedure

&AtClient
Procedure FillInActionStructureWhenAddingRow(Form, StructureOfActions)
	
	CurrentRow = Form.Items.Goods.CurrentData;
	FormField     = Form.Items.GoodsStorageType;
	
	If CurrentRow <> Undefined Then
		If Not FormField.Visible
			And Not ValueIsFilled(CurrentRow.StorageType) Then
			
			FillInDefaultStorageLocationType = New Structure("StorageType", "Enum.StorageLocationTypes.Warehouse");
			
			StructureOfActions.Insert("FillInDefaultStorageLocationType", FillInDefaultStorageLocationType);
			
		EndIf;
	EndIf;
	
EndProcedure

&AtServer
Procedure AddStorageLocationInitializationToActionStructure(StructureOfActions)
	
	If Not Items.GoodsStorageType.Visible Then
		FillInDefaultStorageLocationType = New Structure("StorageType", "Enum.StorageLocationTypes.Warehouse");
		
		StructureOfActions.Insert("FillInDefaultStorageLocationType", FillInDefaultStorageLocationType);
	EndIf;
	
EndProcedure

&AtServer
Procedure GetUploadedProductsFromStorage(GoodsAddressInStorage)
	
	ItemsFromStorage    = GetFromTempStorage(GoodsAddressInStorage);
	CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	RowsToProcess = New Array();
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInProductNameOfProductPartner", Object.Partner);
	
	AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions, ThisObject);
	LinesOfBusinessClientServer.StructureOfInsertActionsWhenAddingRow(ThisObject, StructureOfActions);
	AddStorageLocationInitializationToActionStructure(StructureOfActions);
	
	For Each RowOfGoods In ItemsFromStorage Do
		StringTSGoods = Object.Goods.Add();
		FillPropertyValues(StringTSGoods, RowOfGoods);
		RowsToProcess.Add(StringTSGoods);
	EndDo;
	
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		RowsToProcess,
		StructureOfActions,
		Object.Goods,
		CachedValues);
	
	FillInServiceDetailsForProductRange();
	ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);
	
	CalculateTotals_(ThisObject);
	
EndProcedure

&AtClientAtServerNoContext
Procedure AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions, Form)
	
	StructureOfRecalculationOfAmount = ParametersForConvertingAmountOfNDSVToTS(Form);
	
	StructureOfActions.Insert("RecalculateNumberOfUnits");
	
	StructureOfActions.Insert("RecalculateAmount");
	StructureOfActions.Insert("RecalculateVATAmount",  StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("ClearAmountOfSettlements");
	
EndProcedure

&AtClientAtServerNoContext
Function ParametersForConvertingAmountOfNDSVToTS(Form)
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(
		Form.Object);
	
	Return StructureOfRecalculationOfAmount;
	
EndFunction

&AtServer
Procedure ExecuteRecalculateDocumentAmountsServer(OldCurrency, NewCurrency)
	
	If OldCurrency <> NewCurrency Then
		DocumentDate               = ?(ValueIsFilled(Object.Date), Object.Date, CurrentSessionDate());
		CourseStructures = ARAPAccountingServer.ExchangeRatesForTranslation(ThisObject, OldCurrency, NewCurrency, LocalAccountingCurrency, DocumentDate);
		StructureOfOldCurrencyRates = CourseStructures.StructureOfOldCurrencyRates;
		StructureOfNewCurrencyRates  = CourseStructures.StructureOfNewCurrencyRates;
		
		RecalculationParameters = PriceManagementSystem.ParametersForConvertingTableAmountsToCurrency(Object.PriceIncludesVAT, OldCurrency, NewCurrency);
		RecalculationParameters.StructureOfOldCurrencyRates = StructureOfOldCurrencyRates;
		RecalculationParameters.StructureOfNewCurrencyRates  = StructureOfNewCurrencyRates;
		
		PriceManagementSystem.ConvertTableAmountsToCurrency(Object.Goods, RecalculationParameters);
		
	EndIf;
	
EndProcedure

&AtServer
Procedure FillInSubordinatePropertiesForStatistics(ParentPropsName)
	
	ObjectsFillingByStatistics.FillInSubordinateDetailsOfObject(Object, ParentPropsName);
	
EndProcedure

&AtClient
Procedure QuestionUserBeforeFillingInPricesByAgreement(CallbackDescription)
	
	If Object.Goods.Count() = 0
		Or Not ValueIsFilled(Object.Terms) Then
		
		RunCallback(CallbackDescription, False);
		
		Return;
		
	EndIf;
	
	QueryText = NStr("vi = 'Điền lại giá theo thỏa thuận?';
					|ru = 'Перезаполнить цены по соглашению?';
					|en = 'Refill prices by terms of sales?'; fa = 'Refill prices by terms of sales?';
					|it = 'Ricompilare i prezzi in base all''accordo?';
					|pl = 'Wypełnić ceny ponownie wg porozumienia?';
					|tr = 'Fiyatlar anlaşmaya göre yeniden doldurulsun mu?'");
	
	AnswersOptions = New ValueList;
	AnswersOptions.Add(True, NStr("vi = 'Điền lại';
									|ru = 'Перезаполнить';
									|en = 'Refill'; fa = 'پرکردن مجدد';
									|it = 'Ricompilare';
									|pl = 'Refill';
									|tr = 'Yeniden doldur'"));
	AnswersOptions.Add(False,   NStr("vi = 'Không điền lại';
									|ru = 'Не перезаполнять';
									|en = 'Do not refill'; fa = 'Do not refill';
									|it = 'Non ricompilare';
									|pl = 'Nie wypełniaj ponownie';
									|tr = 'Yeniden doldurma'"));
	
	ShowQueryBox(CallbackDescription, QueryText, AnswersOptions);
	
EndProcedure

&AtServer
Procedure FillInDefaultContract()
	
	AddlParameters = PurchasesServer.AdditionalContractSelectionParameters();
	AddlParameters.ARAPCurrency = Object.ARAPCurrency;
	AddlParameters.Taxation      = Object.VATTaxation;
	
	If UseLinesOfBusiness Then
		AddlParameters.LineOfBusiness = Object.LineOfBusiness;
	EndIf;
	
	DefaultContract = PurchasesServer.GetDefaultContract(Object, ContractBusinessTransaction, AddlParameters);
	
	If DefaultContract <> Contract Then
		
		Object.Contract = DefaultContract;
		ContractOnChangeServer();
		
	EndIf;
	
EndProcedure

&AtClient
Procedure SelectionOfGoodsAcceptedForResponsibleStorage()
	Cancel = False;
	
	ClearMessages();
	
	If Not ValueIsFilled(Object.Partner) Then
		ErrorText = CommonClientServer.FillingErrorText( , , Items.Partner.Title);
		CommonClient.MessageToUser(ErrorText, Object.Ref, "Object.Partner", "", Cancel);
	EndIf;
	
	If Not ValueIsFilled(Object.Organization) Then
		CommonClient.MessageToUser(NStr("vi = 'Chưa điền trường ""Doanh nghiệp""';
										|ru = 'Поле ""Организация"" не заполнено';
										|en = '""Company"" is required'; fa = '""Company"" is required';
										|it = 'Il campo ""Società"" non è compilato';
										|pl = 'Nie wypełniono pola ""Firma""';
										|tr = '""İş yeri"" alanı doldurulmadı'"), Object.Ref,
			"Object.Organization", "", Cancel);
	EndIf;
	
	If Not ValueIsFilled(Object.Contract) Then
		CommonClient.MessageToUser(NStr("vi = 'Trường ""Hợp đồng"" chưa điền';
										|ru = 'Поле ""Договор"" не заполнено';
										|en = '""Contract"" is not filled in.'; fa = '""Contract"" is not filled in.';
										|it = 'Il campo ""Accordo"" non è compilato';
										|pl = 'Pole ""Umowa"" nie jest wypełnione';
										|tr = '""Sözleşme"" alanı doldurulmamış'"), Object.Ref,
			"Object.Contract", "", Cancel);
	EndIf;
	
	If Not Cancel Then
		
		AddressOfGoods = PlaceGoodsInStorageForSelectionOfAcceptedGoods();
		
		FormParameters = New Structure;
		FormParameters.Insert("Ref",                Object.Ref);
		FormParameters.Insert("Owner",              Object.Partner);
		FormParameters.Insert("Organization",           Object.Organization);
		FormParameters.Insert("BusinessOperation", Object.BusinessOperation);
		FormParameters.Insert("Contract",               Object.Contract);
		FormParameters.Insert("AddressOfGoodsInvoiceInVault", AddressOfGoods);
		If Object.BusinessOperation =
				PredefinedValue("Enum.BusinessTransactions.RedemptionOfProviderGoods") Then
			
			InventoryTypes = New ValueList;
			InventoryTypes.Add(PredefinedValue("Enum.InventoryTypes.MaterialOfMaterialProvider"));
			InventoryTypes.Add(PredefinedValue("Enum.InventoryTypes.SemiFinishedProductOfMaterialProvider"));
			InventoryTypes.Add(PredefinedValue("Enum.InventoryTypes.ProductsOfMaterialProvider"));
			
			FormParameters.Insert("InventoryType", InventoryTypes);
			FormParameters.Insert("Title",  NStr("vi = 'Chọn hàng hóa của bên đặt gia công';
												|ru = 'Подбор товаров давальца';
												|en = 'Pick provider goods'; fa = 'Pick provider goods';
												|it = 'Selezione merci del fornitore';
												|pl = 'Wybór towarów właściciela surowców';
												|tr = 'Verenin ürünlerinin seçilmesi'"));
			
		EndIf;
		OpenForm("DataProcessor.SelectGoodsReceivedForCustody.Form.Form", FormParameters, ThisObject,
			UUID);
		
	EndIf;
	
EndProcedure

&AtServer
Function PlaceGoodsInStorageForSelectionOfAcceptedGoods()
	
	Result = Object.Goods.Unload(,
		"LineNumber, Products, Characteristic, Purpose, Series, BatchesIndicationStatus,
		|StorageType, Warehouse, Department, Contract,
		|Custodian, Count");
		
	TypesArray = New Array;
	TypesArray.Add(Type("CatalogRef.Warehouses"));
	TypesArray.Add(Type("CatalogRef.BusinessStructure"));
	TypesArray.Add(Type("CatalogRef.CounterpartyContracts"));
	TypeDescription = New TypeDescription(TypesArray);
	
	Result.Columns.Add("StorageLocation", TypeDescription);
	
	StorageLocations_ = StorageLocations_();
	
	For Each String In Result Do
		If String.StorageType = StorageLocations_.Warehouse Then
			String.StorageLocation = String.Warehouse;
		ElsIf String.StorageType = StorageLocations_.Department Then
			String.StorageLocation = String.Department;
		ElsIf String.StorageType = StorageLocations_.CounterpartyContract Then
			String.StorageLocation = String.Contract;
		EndIf;
	EndDo;
	
	Result.GroupBy("Products, Characteristic, Purpose, Series, BatchesIndicationStatus, StorageLocation, Custodian", "Count");
	TMCommonUse.NumberValueTable(Result, "LineNumber");
	
	Address = PutToTempStorage(Result, UUID);
	
	Return Address;
	
EndFunction

&AtServer
Function PlaceGoodsInTemporaryStorageServer()
	
	Return PurchasesServer.PlaceGoodsInTemporaryStorage(Object.Goods);
	
EndFunction

&AtServer
Procedure FillInItemsFromTemporaryStorageServer(AddressInTempStorage)
	
	FillInArticleAttribute                    = New Structure("Products", "SKU");
	FillInProductTypeAttribute_            = New Structure("Products", "ItemsType");
	FillInFeatureAttribute = New Structure("Products", "ItemVariantsAreUsed");
	
	StructureOfRecalculationOfAmount = ParametersForConvertingAmountOfNDSVToTS(ThisObject);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInArticleAttribute",                    FillInArticleAttribute);
	StructureOfActions.Insert("FillInProductTypeAttribute_",            FillInProductTypeAttribute_);
	StructureOfActions.Insert("FillInFeatureAttribute",
		FillInFeatureAttribute);
		
	StructureOfActions.Insert("RecalculateAmount");
	StructureOfActions.Insert("FillInVATRate",
		BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRate(Object));
		
	StructureOfActions.Insert("RecalculateVATAmount",  StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("ClearAmountOfSettlements");
	
	CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	RowsToProcess = New Array();
	
	TableOfGoods = GetFromTempStorage(AddressInTempStorage); // DocumentTabularSection.RedemptionOfGoodsFromStorage.Goods
	
	For Each CurRow In TableOfGoods Do
		
		Filter                = New Structure("LineNumber", CurRow.LineNumber);
		ArrayOfCollectionRows = Object.Goods.FindRows(Filter);
		
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
	
	ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);
	
	CalculateTotals_(ThisObject);
	
EndProcedure

&AtClientAtServerNoContext
Function StorageLocations_()
	
	StorageLocations_ = New Structure;
	
	StorageLocations_.Insert("Warehouse",         PredefinedValue("Enum.StorageLocationTypes.Warehouse"));
	StorageLocations_.Insert("Department", PredefinedValue("Enum.StorageLocationTypes.Department"));
	StorageLocations_.Insert("CounterpartyContract",
							PredefinedValue("Enum.StorageLocationTypes.CounterpartyContract"));
	
	Return StorageLocations_;
	
EndFunction

&AtClientAtServerNoContext
Function WarehouseSelectionParameters(OpeningSelectionForm = True)
	
	Filter = New Structure("IsFolder", False);
	DataSelectionOptions = New Structure("Filter", Filter);
	
	If OpeningSelectionForm Then
		DataSelectionOptions.Insert("SelectWarehouseGroup", FoldersAndItemsUse.Items);
	EndIf;
	
	Return DataSelectionOptions;
	
EndFunction

&AtClientAtServerNoContext
Function UnitSelectionParameters()
	
	Filter = New Structure("ProductionBusinessUnit", True);
	DataSelectionOptions = New Structure("Filter", Filter);
	
	Return DataSelectionOptions;
	
EndFunction

&AtClientAtServerNoContext
Function ContractSelectionParameters_(Partner, Counterparty, BusinessOperation, UseImportOfGoodsFromCustomsUnion = False)
	
	Filter = New Structure;
	
	BsnsTransactions = New Array;
	BsnsTransactions.Add(PredefinedValue("Enum.BusinessTransactions.TransferToStorageWithRightOfSale"));
	BsnsTransactions.Add(PredefinedValue("Enum.BusinessTransactions.ProductionByToller2_5"));
	If UseImportOfGoodsFromCustomsUnion Then
		BsnsTransactions.Add(PredefinedValue("Enum.BusinessTransactions.ProductionAtProcessorInEAEUCountries2_5"));
	EndIf;
	Filter.Insert("BusinessOperation", BsnsTransactions);
	Filter.Insert("Status", PredefinedValue("Enum.CounterpartyContractStatuses.Valid"));
	Filter.Insert("DeletionMark", False);
	
	DataSelectionOptions = New Structure;
	DataSelectionOptions.Insert("Filter", Filter);
	DataSelectionOptions.Insert("AllowPartnerSelection");
	
	If ValueIsFilled(Partner) Then
		DataSelectionOptions.Insert("Partner", Partner);
	EndIf;
	If ValueIsFilled(Counterparty) Then
		DataSelectionOptions.Insert("Counterparty", Counterparty);
	EndIf;
	
	Return DataSelectionOptions;
	
EndFunction

&AtClient
Procedure OpenStorageLocationSelectionForm(NameOfOpeningForm, FormParameters, CurrentData)
	
	NotificationParameters = New Structure("CurrentData", CurrentData);
	CallbackDescription  = New CallbackDescription("ChoosingStorageLocationEnding",
													ThisObject,
													NotificationParameters);
	
	OpenForm(NameOfOpeningForm, FormParameters, , , , , CallbackDescription,
		FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure ChoosingStorageLocationEnding(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	FillStorageLocation(Result, AdditionalParameters.CurrentData);
	
EndProcedure

&AtClient
Procedure FillStorageLocation(StorageLocation, CurrentData)
	
	StorageLocations_ = StorageLocations_();
	StorageLocationRepresentation = String(StorageLocation);
	
	DefaultValues = New Structure("Warehouse, Department, Contract, Custodian, Counterparty");
	FillPropertyValues(CurrentData, DefaultValues);
	
	If CurrentData.StorageType = StorageLocations_.Warehouse Then;
		CurrentData.Warehouse = StorageLocation;
	ElsIf CurrentData.StorageType = StorageLocations_.Department Then
		CurrentData.Department = StorageLocation;
	ElsIf CurrentData.StorageType = StorageLocations_.CounterpartyContract Then
		CurrentData.Contract = StorageLocation;
		
		ContractDetails_ = ContractDetails_(StorageLocation);
		CurrentData.Custodian  = ContractDetails_.Partner;
		CurrentData.Counterparty = ContractDetails_.Counterparty;
	EndIf;
	
	CurrentData.StorageLocationRepresentation = StorageLocationRepresentation(StorageLocationRepresentation,
																			String(CurrentData.Custodian));
	
	FillInStatusesForSpecifyingSeriesServer();
	
EndProcedure

&AtServer
Function ContractDetails_(Contract)
	
	ContractDetails_ = Common.ObjectAttributesValues(Contract, "Partner, Counterparty");
	
	Return ContractDetails_;
	
EndFunction

&AtClient
Procedure FillInVATRateCompletion(VATRate, AdditionalParameters) Export

	If VATRate = Undefined Then
		Return;
	EndIf;

	FillInVATRateOnServer(VATRate, CachedValues);

EndProcedure

&AtServer
Procedure FillInVATRateOnServer(VATRate, CachedValues)

	StructureOfRecalculationOfAmount = ParametersForConvertingAmountOfNDSVToTS(ThisObject);

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

	CalculateTotals_(ThisObject);

EndProcedure

&AtServer
Procedure CheckStorageLocationsOfVETISLocalization(Cancel)
	
	
EndProcedure

#EndRegion

// StandardSubsystems.Properties
&AtServer
Procedure UpdateAdditionalAttributesItems()
	
	PropertyManager.UpdateAdditionalAttributesItems(ThisObject);
	
EndProcedure

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

&AtClient
Procedure Attachable_ProcessObjectEntry()
	
	TMCommonUseClient.ProcessObjectEntryInForm(ThisObject, ParametersForRecording);
	
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
Procedure PlacePaymentDecryptionInTemporaryStorage()
	ARAPAccountingFormWork.PlacePaymentDecryptionInTemporaryStorage(ThisObject);
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
