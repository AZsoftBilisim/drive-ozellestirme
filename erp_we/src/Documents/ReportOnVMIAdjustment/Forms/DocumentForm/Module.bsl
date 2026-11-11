#Region Variables

&AtClient
Var CachedValues; //It is used by the mechanism for processing changes in PM details.

&AtClient
Var CurDataId; //Used to pass the current line to the waiting handler.

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
	
	// Refund upon receipt of the form for analysis.
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(Object, ThisObject);
	
	If ClientApplication.CurrentInterfaceVariant() = ClientApplicationInterfaceVariant.Version8_2 Then
		Items.GroupInTotal.BackColor = New Color();
	EndIf;
	
	// Handler of the "Properties" subsystem
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("Object",                   Object);
	AdditionalParameters.Insert("ItemForPlacementName", "GroupAdditionalAttributes");
	AdditionalParameters.Insert("DeferredInitialization",  True);
	PropertyManager.OnCreateAtServer(ThisForm, AdditionalParameters);
	
	// Handler of the subsystem "Versioning of objects"
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	
	TMCommonUse.CustomizePeripherals(ThisForm);
	
	// Handler of the "Destination" mechanism
	Catalogs.Assignments.DocumentFormWhenCreatedOnServer(ThisForm);
	
	If Not ValueIsFilled(Object.Ref) Then
		OnReadCreateAtServer();
	EndIf;
	
	SetAvailabilityOfClipboardCommands();
	
	// Selection of articles and analytics.
	ItemsAndDimensionsSelectionParameters =
		Documents.ReportOnVMIAdjustment.ItemsAndDimensionsSelectionParameters(Object.BusinessOperation);
	IncomeAndExpensesServer.OnCreateAtServer(ThisObject, ItemsAndDimensionsSelectionParameters);
	
	// Setting up accounting accounts.
	SetupParameters = Documents.ReportOnVMIAdjustment.AccountingAccountSettings_(
							Object.BusinessOperation);
	GLAccountSettingsServer.OnCreateAtServer(ThisObject, SetupParameters);
	
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
	
	ARAPAccountingFormWork.FormWhenCreatedOnServer(ThisForm);
	
	If Object.Patch Then
		Items.GoodsSelectItemsToBeDebitedFromStorage.Visible = False;
	EndIf;
	
	DocumentCorrection.OnCreateAtServer(ThisForm, Items.LineCorrection);
	
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
Procedure OnClose(Exit)
	
	EquipmentManagerClient.StartDisablingHardwareWhenClosingForm(Undefined, ThisForm);
	
EndProcedure

&AtClient
Procedure ChoiceProcessing(ValueSelected, ChoiceSource)
	
	If ChoiceSource.FormName = "DataProcessor.SelectGoodsReceivedForCustody.Form.Form" Then
		
		PricesCalculated = False;
		
		ProcessingOfSelectionSelectionOfServerAcceptedForResponsibleStorage(ValueSelected, PricesCalculated);
		
		If RecalculatePrices_2 Then
			PurchasesClient.NotifyAboutEndOfFillingInPricesUnderAgreement(PricesCalculated);
		EndIf;
		
	ElsIf ChoiceSource.FormName = "Catalog.Assignments.Form.ChoiceForm" Then
		
		Items.Goods.CurrentData.Purpose = ValueSelected;
		
	ElsIf ProductsClient.ThisIsIndicationOfSeries(ChoiceSource) Then
		
		ProductsClient.ProcessSeriesIndication(ThisForm, SeriesSpecificationParameters, ValueSelected);
		
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
		SetVisibilityOfAgreements();
	EndIf;
	
	If EventName = "CopyingLinesToClipboard" Then
		SetAvailabilityOfClipboardCommandsOnClient();
	EndIf;
	
	If ARAPAccountingClient.NeedAlertProcessingCall(ThisObject, EventName, Parameter) Then
		ChangedPaymentServer(EventName, Parameter, Source);
	EndIf;
	
	
	FormEventsClient.NotificationProcessing(ThisObject, EventName, Parameter, Source);
	
	// StandardSubsystems.FilesOperations
	FilesOperationsClient.NotificationProcessing(ThisObject, EventName);
	// End StandardSubsystems.FilesOperations
	
	DocumentCorrectionClient.NotificationProcessing(ThisObject, EventName, Parameter, Source);
	
	If EventName = "WhenChangingAgreement"
		And Source = ThisObject Then
		Modified = True;
		ContractOnChange(Items[Parameter]);
	EndIf;
	
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)

	// StandardSubsystems.AccessManagement
	AccessManagement.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.AccessManagement
	
	// Handler of the "Date-change" mechanism
	PeriodClosingDates.ObjectOnReadAtServer(ThisForm, CurrentObject);
	
	// Handler of the "Properties" subsystem
	PropertyManager.OnReadAtServer(ThisForm, CurrentObject);
	
	OnReadCreateAtServer();
	
	// Selection of articles and analytics.
	ItemsAndDimensionsSelectionParameters =
		Documents.ReportOnVMIAdjustment.ItemsAndDimensionsSelectionParameters(Object.BusinessOperation);
	IncomeAndExpensesServer.OnReadAtServer(ThisObject, ItemsAndDimensionsSelectionParameters);
	
	// Setting up accounting accounts.
	SetupParameters = Documents.ReportOnVMIAdjustment.AccountingAccountSettings_(
							Object.BusinessOperation);
	GLAccountSettingsServer.OnReadAtServer(ThisObject, SetupParameters);
	FormEvents.OnReadAtServer(ThisObject, CurrentObject);
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	// End StandardSubsystems.AttachableCommands
	
	ARAPAccountingFormWork.FormWhenReadingOnServer(ThisForm);
	
	DocumentCorrection.OnReadAtServer(ThisForm, Items.LineCorrection);
	
EndProcedure

&AtClient
Procedure BeforeWrite(Cancel, WriteParameters)
	
	FormEventsClient.BeforeWrite(ThisObject, Cancel, WriteParameters);
	
	If NotExecuteCheck1BeforeWrite Then
		NotExecuteCheck1BeforeWrite = False;
		
		Return;
	EndIf;
	
EndProcedure

&AtClient
Procedure Attachable_ProcessObjectEntry()
	
	TMCommonUseClient.ProcessObjectEntryInForm(ThisObject, ParametersForRecording);
	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	// Handler of the "Properties" subsystem
	PropertyManager.BeforeWriteAtServer(ThisForm, CurrentObject);
	
	// Setting up accounting accounts.
	GLAccountSettingsServer.BeforeWriteAtServer(ThisObject, CurrentObject);
	
	ARAPAccountingServer.BeforeWriteAtServer(ThisForm, CurrentObject);
	ConfigurationModificationOverridable.BeforeWriteAtServer(ThisForm, Cancel, CurrentObject, WriteParameters);
	
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
	
	FillInServiceDetailsForProductRange();
	FillInStorageLocationPresentation();
	
	
	// Selection of articles and analytics.
	IncomeAndExpensesServer.AfterWriteAtServer(ThisObject);
	
	// Setting up accounting accounts.
	GLAccountSettingsServer.AfterWriteAtServer(ThisObject);
	ConfigurationModificationOverridable.AfterWriteAtServer(ThisForm, CurrentObject, WriteParameters);
	
	ARAPAccountingFormWork.FormAfterRecordingOnServer(ThisForm, CurrentObject.AdditionalProperties);
	CustomizeForm();
	FormEvents.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	
	WriteParameters.Insert("NotificationDocumentKeys", OperationsWithDocumentJournalsClient.GetKeyParametersForDocument(
		Object.Ref, Object.Date, Object.BusinessOperation));
		
	Notify("Write_ReportOnVMIAdjustment", WriteParameters, Object.Ref);
	ARAPAccountingClient.FormAfterRecording(ThisForm);
	
	ConfigurationModificationClientOverridable.AfterWrite(ThisForm, WriteParameters);
	
	TMCommonUseClient.PerformActionsAfterRecording(ThisForm, Object, WriteParameters);
	
	// StandardSubsystems.AttachableCommands
	If CommonClient.SubsystemExists("StandardSubsystems.AttachableCommands") Then
		ModuleAttachableCommandsClient = CommonClient.CommonModule("AttachableCommandsClient");
		ModuleAttachableCommandsClient.AfterWrite(ThisObject, Object, WriteParameters);
	EndIf;
	// End StandardSubsystems.AttachableCommands
	
	DocumentCorrectionClient.AfterWrite(Object);
	
EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	
	// StandardSubsystems.Properties
	PropertyManager.FillCheckProcessing(ThisForm, Cancel, CheckedAttributes);
	// End StandardSubsystems.Properties
	
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)
	
	ForceCloseTheForm = True;
	
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
Procedure DateOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	
	Notification = New CallbackDescription("DateOnChangeCompletion", ThisObject);
	
	If RecalculatePrices_2 Then
		EnterprisePricesFillingClient.AskQuestionAboutRecalculatingPriceWhenDateChanges(Object, Notification);
	Else
		RunCallback(Notification, False);
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

&AtClient
Procedure CounterpartyOnChange(Item)
	
	CounterpartyOnChangeServer();
	
	
EndProcedure

&AtClient
Procedure TermsOnChange(Item)
	
	QuestionUserBeforeFillingInPricesByAgreement(
		New CallbackDescription("AgreementWhenChangingQuestionCompletion", ThisObject));
	
EndProcedure

&AtClient
Procedure TermsStartChoice(Item, ChoiceData, StandardProcessing)
	
	AdditionalSelection = New Structure("BusinessOperation",
		PredefinedValue("Enum.BusinessTransactions.ReceivingForStorageWithRightOfSale"));
	
	PurchasesClient.StartSelectingSupplierAgreement(Item, StandardProcessing, Object.Partner, Object.Terms,
		Object.Date, AdditionalSelection);
	
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
	
	ContractOnChangeServer();
	
EndProcedure

&AtClient
Procedure LineOfBusinessOnChange(Item)
	
	LineOfBusinessOnChangeServer();
	
EndProcedure

&AtClient
Procedure BusinessOperationOnChange(Item)
	Operations = New Array;
	Operations.Add(Object.BusinessOperation);
	Operations.Add(BusinessTransactionBeforeTheChange);
		
	If Object.BusinessOperation <> BusinessTransactionBeforeTheChange
		And (Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.ProviderGoodsWriteOffAtTheExpenseOfProvider")
				And Not BusinessTransactionBeforeTheChange = PredefinedValue("Enum.BusinessTransactions.ProviderGoodsWriteOffAsExpenses")
			Or Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.ProviderGoodsWriteOffAsExpenses")
				And Not BusinessTransactionBeforeTheChange = PredefinedValue("Enum.BusinessTransactions.ProviderGoodsWriteOffAtTheExpenseOfProvider")) Then
		
		Object.Partner    = PredefinedValue("Catalog.Partners.EmptyRef");
		Object.Counterparty = PredefinedValue("Catalog.Counterparties.EmptyRef");
		Object.Contract    = PredefinedValue("Catalog.CounterpartyContracts.EmptyRef");
		PartnerOnChange(Items.Partner);
		CounterpartyOnChange(Items.Counterparty);
		ContractOnChange(Items.Contract);
		
	EndIf;
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands

	BusinessOperationOnChangeServer();
	AttachableCommandsClientServer.UpdateCommands(ThisForm, Object);
	
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

// Parameters:
// 	UserAnswer - Boolean - 
// 	AdditionalParameters - See AdditionalCompletionProcessingParameters
&AtClient
Procedure PartnerWhenChangingQuestionEnds(UserAnswer, AdditionalParameters) Export
	
	If ValueIsFilled(Object.Terms) Then
		If UserAnswer Then
			PricesCalculated = FillThePricesByTermsOfSalesServer(True);
			
			PurchasesClient.NotifyAboutEndOfFillingInPricesUnderAgreement(PricesCalculated);
		Else
			PurchasesClient.NotifyEndOfFillingInDefaultPurchaseConditions();
		EndIf;
	EndIf;
	
	
EndProcedure

&AtClient
Procedure AgreementWhenChangingQuestionCompletion(UserAnswer, AdditionalParameters) Export
	
	Var PricesCalculated;
	
	RecalculatePrices = ValueIsFilled(Object.Terms)
							And Object.Goods.Count() > 0
							And UserAnswer;
	
	WhenChangingAgreementAtServer(RecalculatePrices, PricesCalculated);
	
	If ValueIsFilled(Object.Terms) Then
		PurchasesClient.NotifyEndOfFillingInTermsOfPurchase();
	EndIf;
	
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

&AtClient
Procedure ExpenseItemOnChange(Item)
	
	// Selection of articles and analytics.
	IncomeAndExpensesClientServer.AssetRefOnChange(ThisObject, Item);
	
EndProcedure

&AtClient
Procedure ExpenseItemStartChoice(Item, ChoiceData, StandardProcessing)
	
	// Selection of articles and analytics.
	IncomeAndExpensesClient.StartArticleSelection(ThisObject, Item, StandardProcessing);
	
EndProcedure

&AtClient
Procedure DimensionOfExpensesStartChoice(Item, ChoiceData, StandardProcessing)
	
	// Selection of articles and analytics.
	IncomeAndExpensesClient.StartSelectingExpenseAnalytics(ThisObject, Item, StandardProcessing);
	
EndProcedure

&AtClient
Procedure DimensionOfExpensesAutoComplete(Item, Text, ChoiceData, DataGetParameters, Waiting, StandardProcessing)
	
	// Selection of articles and analytics.
	IncomeAndExpensesClient.AutoSelectionOfExpenseAnalytics(ThisObject, Item, Text, ChoiceData, Parameters,
		StandardProcessing);
	
EndProcedure

&AtClient
Procedure DimensionOfExpensesTextEditEnd(Item, Text, ChoiceData, DataGetParameters, StandardProcessing)
	
	// Selection of articles and analytics.
	IncomeAndExpensesClient.EndOfCostAnalyticsTextEntry(ThisObject, Item, Text, ChoiceData, Parameters,
		StandardProcessing);
	
EndProcedure

&AtClient
Procedure TransactionRecordingPresentationClick(Item, StandardProcessing)
	GLAccountSettingsClient.OnClick(ThisObject, Item, StandardProcessing);
	Return; // The TM is not required
	
EndProcedure

// StandardSubsystems.Properties
&AtClient
Procedure Attachable_OnChangeAdditionalAttribute(Item)
	
	PropertyManagerClient.UpdateAdditionalAttributesDependencies(ThisObject);
	
EndProcedure
// End StandardSubsystems.Properties

&AtClient
Procedure LabelPaymentStagesClick(Item, StandardProcessing)
	
	ARAPAccountingClient.LabelPaymentStagesClick(ThisForm, Item, StandardProcessing);
	
EndProcedure

&AtClient
Procedure DecorationSettlementStateClick(Item, StandardProcessing)
	
	ARAPAccountingClient.CalculationsClick(ThisForm, Item, False);
	
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
		PartnersProductsClient.WhenSelectingPartnerProducts(Object, Field, "GoodsPartnerProducts",
			Items.Partner.Title);
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
		ProductsClient.UpdateCachedValuesToAccountForSeries(Item, CachedValues, SeriesSpecificationParameters);
	EndIf;
	
EndProcedure

&AtClient
Procedure GoodsAfterDeleteRow(Item)
	
	If ProductsClient.SeriesStatusesNeedToBeUpdated(Item, CachedValues, SeriesSpecificationParameters, True) Then
		
		FillInStatusesOfSpecifyingSeriesWhenEditingLineTS(Undefined, CachedValues);
		ProductsClient.UpdateCachedValuesToAccountForSeries(Item, CachedValues, SeriesSpecificationParameters);
		
	EndIf;
		
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
	
	AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions, RecalculatePrices_2);
	FillInActionStructureWhenAddingRow(ThisObject, StructureOfActions);
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
	If CurrentRow.Products <> ItemBeforePartnerItemChanges Then
		StructureOfActions = New Structure;
		
		LinesOfBusinessClientServer.StructureOfInsertActionsWhenAddingRow(ThisObject, StructureOfActions);
		BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	EndIf;
	
EndProcedure

&AtClient
Procedure GoodsProductsOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;
	
	FillInArticleAttribute                  = New Structure("Products", "SKU");
	FillInProductTypeAttribute_          = New Structure("Products", "ItemsType");
	CheckSeriesCalculateStatus           = New Structure("Warehouse, SeriesSpecificationParameters",
																Undefined, SeriesSpecificationParameters);
	ProductsOnChangeOverridable = New Structure("FormName, TabularSectionName",
																ThisForm.FormName, "Goods");
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInProductNameOfProductPartner", Object.Partner);
	StructureOfActions.Insert("FillInArticleAttribute",               FillInArticleAttribute);
	StructureOfActions.Insert("FillInProductTypeAttribute_",       FillInProductTypeAttribute_);
	StructureOfActions.Insert("CheckCharacteristicsByOwner",    CurrentRow.Characteristic);
	StructureOfActions.Insert("CheckFillPackageByOwner", CurrentRow.Package);
	StructureOfActions.Insert("CheckSeriesCalculateStatus",        CheckSeriesCalculateStatus);
	
	StructureOfActions.Insert("ProductsOnChangeOverridable", ProductsOnChangeOverridable);
	
	AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions, RecalculatePrices_2);
	LinesOfBusinessClientServer.StructureOfInsertActionsWhenAddingRow(ThisObject, StructureOfActions);
	FillInActionStructureWhenAddingRow(ThisObject, StructureOfActions);
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
EndProcedure

&AtClient
Procedure GoodsCharacteristicOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;
	
	CharacteristicOnChangeOverridable    = New Structure("FormName, TabularSectionName", ThisForm.FormName,
		"Goods");

	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInProductNameOfProductPartner", Object.Partner);
	StructureOfActions.Insert("CharacteristicOnChangeOverridable", CharacteristicOnChangeOverridable);
	
	LinesOfBusinessClientServer.StructureOfInsertActionsWhenAddingRow(ThisForm, StructureOfActions);
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
EndProcedure

&AtClient
Procedure GoodsSeriesOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;
	
	ValueSelected = ProductsClientServer.SelectedSeries();
	ValueSelected.Value                   = CurrentRow.Series;
	ValueSelected.CurrentRowID = CurrentRow.GetID();
	
	ProductsClient.ProcessSeriesIndication(ThisForm, SeriesSpecificationParameters, ValueSelected);
	
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
	
	If RecalculatePrices_2 Then
		StructureOfActions.Insert("RecalculatePricePerPackage", CurrentRow.Count);
	EndIf;
	
	AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions, RecalculatePrices_2);
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
EndProcedure

&AtClient
Procedure GoodsNumberOfPackagesOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;
	
	StructureOfActions = New Structure;
	
	AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions, RecalculatePrices_2);
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
EndProcedure

&AtClient
Procedure GoodsPriceOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateAmount");
	StructureOfActions.Insert("ClearAmountOfSettlements");
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
EndProcedure

&AtClient
Procedure GoodsSumOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculatePriceByAmount");
	StructureOfActions.Insert("ClearAmountOfSettlements");
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
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
	
	If WriteOffOfThePrincipalSGoods Then
		CurrentData.StorageType = StorageLocations_.Warehouse;
	EndIf;
	
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
	CurrentRow = Items.Goods.CurrentRow;
	
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

&AtClient
Procedure Attachable_PreviewFieldCheckDragging(Item, DragParameters, StandardProcessing)
	 FilesOperationsClient.PreviewFieldCheckDragging(ThisObject, Item, DragParameters, StandardProcessing);
EndProcedure

&AtClient
Procedure Attachable_PreviewFieldDrag(Item, DragParameters, StandardProcessing)
	 FilesOperationsClient.PreviewFieldDrag(ThisObject, Item, DragParameters, StandardProcessing);
EndProcedure

&AtClient
Procedure Attachable_PreviewFieldClick(Item, StandardProcessing)
	 FilesOperationsClient.PreviewFieldClick(ThisObject, Item, StandardProcessing);
EndProcedure
// End StandardSubsystems.FilesOperations

&AtClient
Procedure PostAndClose(Command)
	
	TMCommonUseClient.PostAndClose(ThisForm, True);
	
EndProcedure

&AtClient
Procedure WriteDocument(Command)
	
	TMCommonUseClient.Write(ThisForm, True);
	
EndProcedure

// StandardSubsystems.Properties
&AtClient
Procedure Attachable_PropertiesExecuteCommand(ItemOrCommand, Var_URL = Undefined, StandardProcessing = Undefined)
	
	PropertyManagerClient.ExecuteCommand(ThisObject, ItemOrCommand, StandardProcessing);
	
EndProcedure

&AtClient
Procedure PostDocument(Command)
	
	TMCommonUseClient.Post(ThisForm, True);
	
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

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure
// End StandardSubsystems.AttachableCommands

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
Procedure PaymentSettlement(Command)
	
	PlacePaymentDecryptionInTemporaryStorage();
	ARAPAccountingClient.PaymentSettlement(ThisForm, Items.CreditPaymentForm);
	
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
		AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions, RecalculatePrices_2);
		
		BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
		BatchProcessingOfTablePartClient.ProcessTSString(NewRow, StructureOfActions, CachedValues);
		
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
Procedure DownloadFromTSDCompletion(ExecutionResult, Var_Parameters) Export
	
	If ExecutionResult.Result Then
		ProcessBarcodes(ExecutionResult.TableOfGoods);
	Else
		EquipmentManagerTMClient.ReportError(ExecutionResult);
	EndIf;
	
EndProcedure

&AtClient
Procedure GetWeight(Command)
	
	CurrentRow = EquipmentManagerTMClient.CurrentRow(ThisForm);
	
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
		AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions, RecalculatePrices_2);
		
		CurrentRow.NumberOfPackages = ExecutionResult.Weight;
		
		BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
		
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
	
	ReturnParameters = Undefined;
	CallbackDescription    = New CallbackDescription("CheckQuantityInTheDocumentCompletion", ThisObject);
	
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
		
	EndIf;
	
EndProcedure

&AtClient
Procedure SelectItemsToBeDebitedFromStorage(Command)
	
	SelectionOfGoodsToBeWrittenOffFromStorage();
	
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
		ThisForm, FilterItemsType);
	
EndProcedure

&AtClient
Procedure FillInTheItemByThePartnerSItemCompletion(Result, AdditionalParameters) Export
	
	If Result <> Undefined Then
		FillInItemsFromTemporaryStorageServer(Result);
	EndIf;
	
EndProcedure

&AtClient
Procedure FillThePricesByTermsOfSales(Command)
	
	If PartnerPricesFillingClient.ItIsNecessaryToFillInPricesByAgreement(Object, "Goods", NStr("vi = 'Hàng hóa';
																								|ru = 'Товары';
																								|en = 'Goods'; fa = 'کالاها';
																								|it = 'Merci';
																								|pl = 'Wiersze pozycji';
																								|tr = 'Ürünler'")) Then
		PricesCalculated = FillThePricesByTermsOfSalesServer();
		
		PurchasesClient.NotifyAboutEndOfFillingInPricesUnderAgreement(PricesCalculated);
	EndIf;
	
EndProcedure

&AtClient
Procedure FillInThePricesOfTheSelectedLinesByTheTypeOfSupplierPrices(Command)
	
	If PartnerPricesFillingClient.ItIsNecessaryToFillInPricesAccordingToSupplierSPriceType(Object, "Goods", NStr("vi = 'Hàng hóa';
																												|ru = 'Товары';
																												|en = 'Goods'; fa = 'کالاها';
																												|it = 'Merci';
																												|pl = 'Wiersze pozycji';
																												|tr = 'Ürünler'")) Then
		CallbackDescription = New CallbackDescription("FillInPricesOfSelectedRowsSelectionVendorPriceViewCompletion",
			ThisObject);
		
		PartnerPricesFillingClient.SelectVendorsPriceType(CallbackDescription,Object.Partner);
	EndIf;
	
EndProcedure

&AtClient
Procedure FillInPricesOfSelectedRowsSelectionVendorPriceViewCompletion(VendorPriceKind, AdditionalParameters) Export
	
	If ValueIsFilled(VendorPriceKind) Then
		PricesCalculated = FillInThePricesOfTheSelectedLinesByTheTypeOfSupplierPricesServer(VendorPriceKind);
		
		PartnerPricesFillingClient.NotifyAboutEndOfFillingInPricesByTypeOfSupplierSPrice(PricesCalculated, VendorPriceKind);
	EndIf;
	
EndProcedure

#EndRegion

#EndRegion

#Region Private

#Region OnChangeAttributes

&AtServer
Procedure DateOnChangeServer(RecalculatePrices, PricesCalculated)
	
	If RecalculatePrices Then
		PricesCalculated = FillThePricesByTermsOfSalesServer(True);
	Else
		PricesCalculated = False;
	EndIf;
	
	ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisForm, "Date");
		
	FillInParametersSetSeriesVisibility();
	
	ResponsiblePersonsServer.WhenChangingRelatedDocumentDetails(Object);
	
EndProcedure

&AtServer
Procedure WhenChangingPartnerServer()
	
	DocumentPurchases               = FormAttributeToValue("Object");
	DirectionsOfActivity = Object.LineOfBusiness;
	
	DocumentPurchases.FillInDefaultPurchaseConditions(RecalculatePrices_2);
	ResponsiblePersonsServer.FillInManager_(DocumentPurchases);
	ValueToFormAttribute(DocumentPurchases, "Object");
	
	If ValueIsFilled(Object.Terms) Then
		DocumentCurrency = Object.Currency;
	EndIf;
	
	AttributesArray = New Array;
	AttributesArray.Add("Currency");
	AttributesArray.Add("ARAPCurrency");
	AttributesArray.Add("Partner");
	AttributesArray.Add("LineOfBusiness");
	AttributesArray.Add("Organization");
	AttributesArray.Add("Terms");
	ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisForm, AttributesArray);
	
	If Contract <> Object.Contract Then
		Contract = Object.Contract;
	EndIf;
	
	FillInSubordinatePropertiesForStatistics("Counterparty");
	SetVisibilityOfAgreements();
	
	PartnersProductsServer.FillInPartnerProductListByProductNameWhenPartnerChanges(Object.Goods, Object.Partner);
	FillInServiceDetailsForProductRange();
	
	ResponsiblePersonsServer.WhenChangingRelatedDocumentDetails(Object);
	
	If DirectionsOfActivity <> Object.LineOfBusiness Then
		LinesOfBusinessServer.WhenChangingDirectionOfActivity(ThisObject);
		ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);
	EndIf;
	
EndProcedure

&AtServer
Procedure CounterpartyOnChangeServer()
	
	DirectionsOfActivity = Object.LineOfBusiness;
	
	If ValueIsFilled(Object.Counterparty) Then
		FillInDefaultContract();
		
		If RecalculatePrices_2
			And Not ValueIsFilled(Object.CounterpartyBankAccount) Then
			Object.CounterpartyBankAccount = GetDefaultCounterpartyBankAccountServer(Object.Counterparty);
		EndIf;
	EndIf;
	
	FillInSubordinatePropertiesForStatistics("Counterparty");
	
	If DirectionsOfActivity <> Object.LineOfBusiness Then
		LinesOfBusinessServer.WhenChangingDirectionOfActivity(ThisObject);
		ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);
	EndIf;
	
	ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisForm, "Counterparty");
	
EndProcedure

&AtServer
Procedure WhenChangingAgreementAtServer(RecalculatePrices, PricesCalculated = False)
	
	If Not ValueIsFilled(Object.Terms) Then
		Return;
	EndIf;
	
	DocumentPurchases               = FormAttributeToValue("Object");
	DirectionsOfActivity = Object.LineOfBusiness;
	ResponsiblePersonsServer.FillInManager_(DocumentPurchases);
	DocumentPurchases.FillInTermsOfPurchaseUnderAgreement();
	ValueToFormAttribute(DocumentPurchases, "Object");
	
	FillInSubordinatePropertiesForStatistics("Contract");
	
	DocumentCurrency = Object.Currency;
	
	StructureOfActions = New Structure;

	AttributesArray = New Array;
	AttributesArray.Add("Currency");
	AttributesArray.Add("ARAPCurrency");
	AttributesArray.Add("Partner");
	AttributesArray.Add("LineOfBusiness");
	AttributesArray.Add("Organization");
	AttributesArray.Add("Terms");
	ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisForm, AttributesArray);
		
	If RecalculatePrices Then
		
		FillParameters = PartnerPricesFillingServer.NewFillOptionsFillPrices();
		FillParameters.Insert("PopulationFields", "Price");
		FillParameters.Insert("Date",           Object.Date);
		FillParameters.Insert("Currency",         Object.Currency);
		FillParameters.Insert("Terms",     Object.Terms);
		FillParameters.Insert("Organization",    Object.Organization);
		
		StructureOfActions.Insert("RecalculateAmount");
		StructureOfActions.Insert("ClearAmountOfSettlements");
		
		PricesCalculated = PartnerPricesFillingServer.FillInPrices(Object.Goods, Undefined, FillParameters, StructureOfActions);
		
	EndIf;
	
	If Contract <> Object.Contract Then
		Contract = Object.Contract;
	EndIf;
	
	FillInServiceDetailsForProductRange();
	
	ResponsiblePersonsServer.WhenChangingRelatedDocumentDetails(Object);
	
	If DirectionsOfActivity <> Object.LineOfBusiness Then
		LinesOfBusinessServer.WhenChangingDirectionOfActivity(ThisObject);
		ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);
	EndIf;
	
EndProcedure

&AtServer
Procedure ContractOnChangeServer()
	
	Contract = Object.Contract;
	ForeignCurrencyTransaction = Object.ForeignCurrencyTransaction;
	
	ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisObject, "Contract");
	
	If ForeignCurrencyTransaction <> Object.ForeignCurrencyTransaction Then
		Object.CompanyBankAccount = Catalogs.CompaniesBankAccounts.EmptyRef();
	EndIf;
	
	If RecalculatePrices_2 Then
		PurchasesServerCall.FillInBankAccountsUnderAgreement(Object.Contract, Object.CompanyBankAccount,
			Object.CounterpartyBankAccount);
		
		ParametersOfAccount = CashServer.ParametersForFillingOutOrganizationSBankAccount(Object.Organization);
		ParametersOfAccount.LineOfBusiness = Object.LineOfBusiness;
		ParametersOfAccount.ExcludeCurrencyAccounts = Object.ForeignCurrencyTransaction;
		ParametersOfAccount.Currency = LocalAccountingCurrency;
		Object.CompanyBankAccount = CashServer.GetOrganizationSDefaultBankAccount(
			ParametersOfAccount, Object.CompanyBankAccount, Object.PaymentMethod);
		
	EndIf;
	
	FillInSubordinatePropertiesForStatistics("Contract");
	
	FillInTermsOfSettlementsUnderAgreement();
	
	ARAPAccountingFormWork.WhenChangingParametersOfMechanism(ThisForm);
	If Object.BusinessOperation = Enums.BusinessTransactions.ProviderGoodsWriteOffAtTheExpenseOfProvider
		Or Object.BusinessOperation = Enums.BusinessTransactions.ProviderGoodsWriteOffAsExpenses Then
		
		If ValueIsFilled(Object.Contract) Then
			Object.Department = Common.ObjectAttributeValue(Object.Contract, "Department");
		EndIf;
		
		EmptyAssignment = Catalogs.Assignments.EmptyRef();
		FoundRows = Object.Goods.FindRows(New Structure("Purpose", EmptyAssignment));
		If Object.Goods.Count() > FoundRows.Count() Then
			
			For Each StringTSGoods In Object.Goods Do
				
				If Not ValueIsFilled(StringTSGoods.Purpose) Then
					Continue;
				EndIf;
				
				StringTSGoods.Purpose = EmptyAssignment;
				
			EndDo;
			
		EndIf;
	
	EndIf;
	SetByContractType();
	SetVisibilityOfAgreements();
	ResponsiblePersonsServer.FillInManager_(Object);
	
EndProcedure

&AtServer
Procedure OrganizationOnChangeServer()
	
	DirectionsOfActivity = Object.LineOfBusiness;
	LocalAccountingCurrency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Object.Organization);
	
	If ValueIsFilled(Object.Organization) Then
		FillInDefaultContract();
		If RecalculatePrices_2 Then
			CashServer.CheckFillInOrganizationSBankAccountByOwner(Object.Organization,
				Object.CompanyBankAccount, Object.PaymentMethod, Object.LineOfBusiness, Object.ForeignCurrencyTransaction);
		EndIf;
	EndIf;
	
	FillInSubordinatePropertiesForStatistics("Organization");
	
	ResponsiblePersonsServer.WhenChangingRelatedDocumentDetails(Object);
	
	If DirectionsOfActivity <> Object.LineOfBusiness Then
		LinesOfBusinessServer.WhenChangingDirectionOfActivity(ThisObject);
		ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);
	EndIf;
	
	ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisForm, "Organization");
	
EndProcedure

&AtServer
Procedure BusinessOperationOnChangeServer()
	If Object.Goods.Count() > 0
		And (Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.ProviderGoodsWriteOffAtTheExpenseOfProvider")
				And Not BusinessTransactionBeforeTheChange = PredefinedValue("Enum.BusinessTransactions.ProviderGoodsWriteOffAsExpenses")
			Or Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.ProviderGoodsWriteOffAsExpenses")
				And Not BusinessTransactionBeforeTheChange = PredefinedValue("Enum.BusinessTransactions.ProviderGoodsWriteOffAtTheExpenseOfProvider")) Then
		Object.Goods.Clear();
	EndIf;
	RecalculatePrices_2 =
		Object.BusinessOperation = Enums.BusinessTransactions.ConsumptionOfGoodsReceivedAsExpenses
		Or Object.BusinessOperation = Enums.BusinessTransactions.ProviderGoodsWriteOffAsExpenses
		Or False;
	
	ARAPAccountingFormWork.WhenChangingParametersOfMechanism(ThisForm);
	
	If Not RecalculatePrices_2 Then
		TMCommonUseClientServer.FillInCollectionPropertyValues(
			Object.Goods, 0, "Price, Sum, AmountARAP");
	EndIf;
	
	SetVisibilityOfElementsByOperation();
	EstablishRelationshipsBetweenContractSelectionParameters();
	FillInArticleSelectionParameters();
	FillInAccountSettings();
	FillInTermsOfPurchaseForOperation();
	SetByContractType();
	SetVisibilityOfAgreements();
	
	FillInSelectionListProductsStorageLocationType();
	
	CustomizeForm();
	
	BusinessTransactionBeforeTheChange = Object.BusinessOperation;
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
	
	ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisForm, ChangedBankingDetails, True);
	
EndProcedure

&AtServer
Procedure DocumentAmountOnChangeServer(DocumentAmount)
	
	RecalculationParameters = PriceManagementSystem.ParametersForRecalculationOfTableAmountsONChangeOfExchangeRate(False, DocumentAmount,, False);
	
	PriceManagementSystem.RecalculateTableAmountsONChangeOfExchangeRate(Object.Goods, RecalculationParameters);
	
	StructureOfActions = New Structure("RecalculateAmount");
	
	BatchProcessingOfTablePartServer.TreatTS(Object.Goods, StructureOfActions, Undefined);
	
EndProcedure

&AtServer
Procedure LineOfBusinessOnChangeServer()
	
	LinesOfBusinessServer.WhenChangingDirectionOfActivity(ThisObject);
	ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);
	
	ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisForm, "LineOfBusiness");
	
EndProcedure

&AtServer
Procedure SetByContractType()
	
	ContractType = GeneralPurposeTMServerCall.ObjectAttributeValue(Object.Contract, "ContractType");
	WriteOffOfThePrincipalSGoods = ?(ContractType = Enums.ContractTypes.CustomerInvoiceOutsourcedSale, True, False);
	
	NewArray = New Array;
	
	If WriteOffOfThePrincipalSGoods Then
			Items.Partner.Title = NStr("vi = 'Bên giao hàng ký gửi';
										|ru = 'Принципал';
										|en = 'Principal'; fa = 'اصل مبلغ';
										|it = 'Mandante';
										|pl = 'Principal';
										|tr = 'Anapara'");
			NewArray.Add(New ChoiceParameter("Filter.Client", True));
	Else
		If Object.BusinessOperation = Enums.BusinessTransactions.ProviderGoodsWriteOffAtTheExpenseOfProvider
			Or Object.BusinessOperation = Enums.BusinessTransactions.ProviderGoodsWriteOffAsExpenses Then
			
			Items.Partner.Title = NStr("vi = 'Bên đặt gia công';
										|ru = 'Давалец';
										|en = 'Material provider'; fa = 'تأمین‌کننده مواد';
										|it = 'Fornitore';
										|pl = 'Material provider';
										|tr = 'Malzeme tedarikçisi'");
			NewArray.Add(New ChoiceParameter("Filter.Client", True));
			NewArray.Add(New ChoiceParameter("Filter.Vendor", True));
			
		Else
			Items.Partner.Title = NStr("vi = 'Nhà cung cấp';
										|ru = 'Поставщик';
										|en = 'Vendor'; fa = 'تأمین‌کننده';
										|it = 'Fornitore';
										|pl = 'Vendor';
										|tr = 'Tedarikçi'");
		EndIf;
	EndIf;
	
	ItemArray = New Array;
	ItemArray.Add("GoodsFillInTheItemByThePartnerSItem");
	ItemArray.Add("GoodsStorageType");
	
	TMCommonUseClientServer.SetPropertyOfFormElements(Items, ItemArray, "Visible",
		Not WriteOffOfThePrincipalSGoods);
	
	Items.GroupProductsPrices.Visible =
		Not WriteOffOfThePrincipalSGoods
			And (Object.BusinessOperation = Enums.BusinessTransactions.ConsumptionOfGoodsReceivedAsExpenses
			Or Object.BusinessOperation = Enums.BusinessTransactions.ProviderGoodsWriteOffAsExpenses
			Or False);
	
	NewParameters = New FixedArray(NewArray);
	Items.Partner.ChoiceParameters = NewParameters;
	
EndProcedure

#EndRegion

#Region WorkingWithCounterparties
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
	
	Columns = "Products,Characteristic,Package,NumberOfPackages"
		+ ?(RecalculatePrices_2, ",Price", "");
	
	TableOfGoods = ProcessingOfTabularForms.RowsFromClipboard(FilterParameters, Columns);
	
	If Not ValueIsFilled(TableOfGoods) Then
		Return;
	EndIf;
	
	StructureOfActions = New Structure;
	AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions, RecalculatePrices_2);
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
	StructureOfActionsWithAddedStrings.Insert("FillInProductNameOfProductPartner", Object.Partner);
	
	LinesOfBusinessClientServer.StructureOfInsertActionsWhenAddingRow(ThisObject,
		StructureOfActionsWithAddedStrings);
	AddActionsToStructureWhenChangingPackagesNumber(StructureOfActionsWithAddedStrings, RecalculatePrices_2);
	AddStorageLocationInitializationToActionStructure(StructureOfActionsWithAddedStrings);
	
	If Not Items.GoodsStorageType.Visible Then
		CheckSeriesCalculateStatus = New Structure("SeriesSpecificationParameters, Warehouse",
														SeriesSpecificationParameters, Undefined);
		
		StructureOfActionsWithAddedStrings.Insert("CheckSeriesCalculateStatus",  CheckSeriesCalculateStatus);
	EndIf;
	
	StructureOfActionsWithModifiedStrings = New Structure;
	AddActionsToStructureWhenChangingPackagesNumber(StructureOfActionsWithModifiedStrings, RecalculatePrices_2);
	
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
	
EndProcedure

&AtServer
Procedure ProcessBarcodesServer(StructureOfActionParameters, CachedValues)
	
	BarcodingOfItemsServer.ProcessBarcodes(ThisObject, Object, StructureOfActionParameters, CachedValues);
	
EndProcedure

#EndRegion

#Region SelectionAndProcessingOfQuantityVerification

&AtServer
Function PutTablePartOfGoodsInTemporaryStorageToCheckQuantity()
	
	TabularPartProducts = Object.Goods.Unload(, "Products, Characteristic, ItemVariantsAreUsed, Package,
		|NumberOfPackages, Series, BatchesIndicationStatus, ItemsType");
	TabularPartProducts.GroupBy("Products, Characteristic, ItemVariantsAreUsed, Package, Series,
		|BatchesIndicationStatus, ItemsType", "NumberOfPackages");
	
	AddressInTempStorage = PutToTempStorage(TabularPartProducts, UUID);
	
	Return AddressInTempStorage;
	
EndFunction

&AtServer
Procedure ChangeTablePartBasedOnResultsOfCheck(ReturnParameters, CachedValues)
	
	RowsToProcess = New Array;
	ProcessedLinesAreNew = New Array;
	LinesToDelete = New Array;
	
	GoodsTable = GetFromTempStorage(ReturnParameters.Goods);
	
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

	StructureOfActions = New Structure;
	AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions, RecalculatePrices_2);
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		ProcessedLinesAreNew,
		StructureOfActions,
		Object.Goods,
		CachedValues);

	AddStorageLocationInitializationToActionStructure(StructureOfActions);
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		RowsToProcess,
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
	
	ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);
	
EndProcedure

&AtServer
Procedure ProcessingOfSelectionSelectionOfServerAcceptedForResponsibleStorage(ValueSelected, PricesCalculated)
	
	RowsArray = New Array;
	
	TableOfGoods = GetFromTempStorage(ValueSelected.GoodsAddressInStorage);
	CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	
	StructureOfActions = New Structure("RecalculateNumberOfPackages");
	
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
	
	If RecalculatePrices_2 Then
		
		StructureOfPriceCalculationActions = New Structure;
		StructureOfPriceCalculationActions.Insert("RecalculateAmount");
		StructureOfPriceCalculationActions.Insert("ClearAmountOfSettlements");
		
		PriceFillingParameters = PartnerPricesFillingServer.NewFillOptionsFillPrices();
		PriceFillingParameters.Insert("PopulationFields", "Price");
		PriceFillingParameters.Insert("Date",           Object.Date);
		PriceFillingParameters.Insert("Currency",         Object.Currency);
		PriceFillingParameters.Insert("Terms",     Object.Terms);
		PriceFillingParameters.Insert("Organization",    Object.Organization);
		
		PricesCalculated = PartnerPricesFillingServer.FillInPrices(Object.Goods,
													RowsArray,
													PriceFillingParameters,
													StructureOfPriceCalculationActions);
		
	EndIf;
	
EndProcedure

&AtServer
Function PlaceGoodsInStorageForSelectionOfAcceptedGoods()
	
	Result = Object.Goods.Unload(,
		"Products, Characteristic, Purpose, Series, BatchesIndicationStatus,
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

#EndRegion

#Region SetOfSeries

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
	
	If ProductsClient.YouNeedServerCallToSpecifySeries(ThisForm, SeriesSpecificationParameters, Text, CurrentData) Then
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
Procedure SetVisibilityOfSeriesElements()
	
	Items.GoodsSeries.Visible = SeriesSpecificationParameters.UseItemsBatch;
	
EndProcedure

&AtServer
Procedure FillInStatusesOfSpecifyingSeriesWhenEditingLineTS(IDCurrentRow, CachedValues)
	
	ProductsServer.FillInStatusesOfSpecifyingSeriesWhenEditingLineTS(Object, SeriesSpecificationParameters,
		IDCurrentRow, CachedValues);
	
EndProcedure

&AtServer
Procedure FillInParametersSetSeriesVisibility()
	
	StructureOfSeriesIndicationParameters = ProductsServer.SeriesSpecificationParameters(Object,
		Documents.ReportOnVMIAdjustment);
	
	SeriesSpecificationParameters = New FixedStructure(StructureOfSeriesIndicationParameters);
	ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);
	
	SetVisibilityOfSeriesElements();
	
EndProcedure

&AtServer
Procedure FillInStatusesForSpecifyingSeriesServer()
	
	ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);
	
EndProcedure

#EndRegion

#Region PriceManagementSystem

&AtServer
Function FillThePricesByTermsOfSalesServer(OnAllLines = False)
	
	If OnAllLines Then
		RowsArray = Undefined;
	Else
		RowsArray = New Array;
		
		For Each String In Items.Goods.SelectedRows Do
			RowsArray.Add(Object.Goods.FindByID(String));
		EndDo;
	EndIf;
	
	FillParameters = PartnerPricesFillingServer.NewFillOptionsFillPrices();
	FillParameters.Insert("PopulationFields", "Price");
	FillParameters.Insert("Date",           Object.Date);
	FillParameters.Insert("Currency",         Object.Currency);
	FillParameters.Insert("Terms",     Object.Terms);
	FillParameters.Insert("Organization",    Object.Organization);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateAmount");
	StructureOfActions.Insert("ClearAmountOfSettlements");
	
	PricesCalculated = PartnerPricesFillingServer.FillInPrices(Object.Goods, RowsArray, FillParameters,
		StructureOfActions);
	
	Return PricesCalculated;
	
EndFunction

&AtServer
Function FillInThePricesOfTheSelectedLinesByTheTypeOfSupplierPricesServer(VendorPriceKind)
	
	RowsArray = New Array;
	
	For Each String In Items.Goods.SelectedRows Do
		TableRow = Object.Goods.FindByID(String);
		
		RowsArray.Add(TableRow);
	EndDo;
	
	FillParameters = PartnerPricesFillingServer.NewFillOptionsFillPrices();
	FillParameters.Insert("PopulationFields",    "Price");
	FillParameters.Insert("Date",              Object.Date);
	FillParameters.Insert("Currency",            Object.Currency);
	FillParameters.Insert("VendorPriceKind", VendorPriceKind);
	FillParameters.Insert("Organization", Object.Organization);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateAmount");
	StructureOfActions.Insert("ClearAmountOfSettlements");
	
	PricesCalculated = PartnerPricesFillingServer.FillInPrices(Object.Goods, RowsArray, FillParameters, StructureOfActions);
	
	Return PricesCalculated;
	
EndFunction

#EndRegion

#Region BusinessTransactions

&AtClientAtServerNoContext
Function ContractBusinessTransaction(BusinessOperation)
	If BusinessOperation =
			PredefinedValue("Enum.BusinessTransactions.ProviderGoodsWriteOffAtTheExpenseOfProvider")
		Or BusinessOperation =
			PredefinedValue("Enum.BusinessTransactions.ProviderGoodsWriteOffAsExpenses") Then
		Return TollingSchemeClientServer.ContractBusinessTransaction();
	EndIf;
	Return PredefinedValue("Enum.BusinessTransactions.ReceivingForStorageWithRightOfSale");
	
EndFunction
&AtServer
Procedure CustomizeForm()
	
	If Object.BusinessOperation = Enums.BusinessTransactions.ProviderGoodsWriteOffAtTheExpenseOfProvider
		Or Object.BusinessOperation = Enums.BusinessTransactions.ProviderGoodsWriteOffAsExpenses Then
		
		AutoTitle = False;
		
		ObjectPresentation = TollingSchemeClientServer.SynonymOfDocumentReportOnWriteOffOfGoodsFromStorage();
		
		If ValueIsFilled(Parameters.Key) Then
			Title = StrTemplate(NStr("vi = '%1 %2 ngày %3';
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
		
		Items.GoodsSelectItemsToBeDebitedFromStorage.Title = NStr("vi = 'Lựa chọn hàng hóa được ghi giảm của bên đặt gia công';
																	|ru = 'Подобрать списанные товары давальца';
																	|en = 'Pick adjusted goods of the provider'; fa = 'Pick adjusted goods of the provider';
																	|it = 'Selezionare le merci stornate del fornitore';
																	|pl = 'Wybierz rozchodowane towary właściciela surowców';
																	|tr = 'Satıcı tarafından yazılan ürünleri teslim alın'");
		
	Else
		
		AutoTitle = True;
		Title     = "";
		
		Items.GoodsSelectItemsToBeDebitedFromStorage.Title = NStr("vi = 'Chọn hàng hóa đã nhận cất giữ bảo quản để ghi giảm';
																	|ru = 'Подобрать товары к списанию, принятые на ответственное хранение';
																	|en = 'Select available VMI to adjust'; fa = 'انتخاب VMI موجود برای تعدیل';
																	|it = 'Select available VMI to adjust';
																	|pl = 'Select available VMI to adjust';
																	|tr = 'Sorumlu olunan depoya alınan, gider yazılacak ürünleri seçin'");
		
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
	
	// Setting the conditional design for the 'Partner Nomenclature' element of the 'Products' tabular part.
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
	ProductsServer.EstablishConditionalAppearanceOfProductCharacteristics(ThisForm);
	ProductsServer.SetConditionalAppearanceOfProductAssignment(ThisForm);
	ProductsServer.EstablishConditionalAppearanceOfProductSeries(ThisForm, "SeriesAlwaysWHGoods");
	ProductsServer.SetConditionalAppearanceOfStatusIndicationSeries(ThisForm, True);
	ProductsServer.SetConditionalAppearanceOfUnitsOfMeasurement(ThisForm);
	
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
	
	// Setting the visibility of the cost indicators element in the 'Products' tabular section
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsPrice.Name);
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsSum.Name);
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsAmountARAP.Name);
	
	TransactionList = New ValueList;
	TransactionList.Add(Enums.BusinessTransactions.ConsumptionOfGoodsReceivedAsExpenses);
	TransactionList.Add(Enums.BusinessTransactions.ProviderGoodsWriteOffAsExpenses);
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.BusinessOperation");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotInList;
	ItemFilter.RightValue = TransactionList;
	
	Item.Appearance.SetParameterValue("Visible", False);
	
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
	
	Item.Appearance.SetParameterValue("Text", NStr("vi = 'Ghi giảm hàng hóa đang bảo quản';
													|ru = 'Списание товаров, хранящихся на складе';
													|en = 'Write off goods stored in the warehouse'; fa = 'اسقاط کالای نگهداری‌شده در انبار';
													|it = 'Cancellazione delle merci depositate nel magazzino';
													|pl = 'Spisanie towarów, przechowywanych w magazynie';
													|tr = 'Depolanan malların gider yazılması'"));
	
	// Setting the conditional design for the 'Storage View' element of the 'Products' tabular part
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsStorageType.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.StorageType");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.StorageLocationTypes.Department;
	
	Item.Appearance.SetParameterValue("Text", NStr("vi = 'Ghi giảm hàng hóa chuyển vào sản xuất';
													|ru = 'Списание товаров, переданных в производство';
													|en = 'Write off goods transferred to production'; fa = 'اسقاط کالای منتقل‌شده به تولید';
													|it = 'Cancellazione delle merci consegnate nella produzione';
													|pl = 'Spisanie towarów, przekazanych do produkcji';
													|tr = 'Üretime aktarılan malların gider yazılması'"));
	
	// Setting the conditional design for the 'Storage View' element of the 'Products' tabular part
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsStorageType.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.StorageType");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.StorageLocationTypes.CounterpartyContract;
	
	Item.Appearance.SetParameterValue("Text", NStr("vi = 'Ghi giảm hàng hóa chuyển vào nơi cất giữ';
													|ru = 'Списание товаров, переданных на хранение';
													|en = 'Write-off goods transferred for storage'; fa = 'اسقاط کالای منتقل‌شده برای نگهداری';
													|it = 'Cancellazione delle merci consegnate in deposito';
													|pl = 'Rozchód towarów przekazanych na przechowywanie';
													|tr = 'Depodaki malların gider yazılması'"));
	
	// Setting the conditional design for the 'Activity Direction' element
	LinesOfBusinessServer.EstablishConditionalAppearanceOfDirectionOfActivity(ThisForm);
	
EndProcedure

&AtServer
Procedure OnReadCreateAtServer()
	
	UseLocal                = GetFunctionalOption("UseLocal");
	UseTermsOfPurchases = GetFunctionalOption("UseTermsOfPurchases");
	UseLinesOfBusiness = GetFunctionalOption("UseCostAccountingByLinesOfBusiness");
	
	DocumentDateBeforeChange       = Object.Date;
	DocumentCurrency                = Object.Currency;
	LocalAccountingCurrency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Object.Organization);
	Contract                        = Object.Contract;
	
	RecalculatePrices_2 =
		Object.BusinessOperation = Enums.BusinessTransactions.ConsumptionOfGoodsReceivedAsExpenses
		Or Object.BusinessOperation = Enums.BusinessTransactions.ProviderGoodsWriteOffAsExpenses
		Or False;
	
	BusinessOperationSelectionList = Items.BusinessOperation.ChoiceList;
	BusinessOperationSelectionList.Clear();
	If GetFunctionalOption("UseCustodyDuringPurchase") Then
		BusinessOperationSelectionList.Add(
			Enums.BusinessTransactions.WriteOffOfAcceptedGoodsAtExpenseOfDepositor);
		BusinessOperationSelectionList.Add(
			Enums.BusinessTransactions.ConsumptionOfGoodsReceivedAsExpenses);
	EndIf;
	
	If GetFunctionalOption("UseTollManufacturing2_5") Then
		BusinessOperationSelectionList.Add(Enums.BusinessTransactions.ProviderGoodsWriteOffAtTheExpenseOfProvider);
		BusinessOperationSelectionList.Add(Enums.BusinessTransactions.ProviderGoodsWriteOffAsExpenses);
	EndIf;
	
	Items.BusinessOperation.Visible = BusinessOperationSelectionList.Count() > 1;
	
	If Not ValueIsFilled(Object.BusinessOperation)
		And Items.BusinessOperation.ChoiceList.Count() = 1 Then
		Object.BusinessOperation = BusinessOperationSelectionList[0].Value;
	EndIf;
	SetVisibilityOfAgreements();
	SetVisibilityOfElementsByOperation();
	EstablishRelationshipsBetweenContractSelectionParameters();
	
	FillInServiceDetailsForProductRange();
	FillInSelectionListProductsStorageLocationType();
	FillInStorageLocationPresentation();
	FillInParametersSetSeriesVisibility();
	SetByContractType();
	CustomizeForm();
	BusinessTransactionBeforeTheChange = Object.BusinessOperation;
	LinesOfBusinessServer.OnReadCreateAtServer(ThisObject);
	
EndProcedure

&AtServer
Procedure SetVisibilityOfAgreements()
	
	If ValueIsFilled(Object.Partner) Then
		FilterParameters                  = New Structure("BusinessOperation",
			Enums.BusinessTransactions.ReceivingForStorageWithRightOfSale);
		NumberOfSupplierAgreements = PurchasesServerCall.GetNumberOfAgreementsWithSupplier(Object.Partner,
			FilterParameters);
		ContractDetails_ = Catalogs.CounterpartyContracts.ObjectAttributes(Contract);
		SetPropertyValue       = ?(ContractDetails_.BusinessOperation = Enums.BusinessTransactions.DeliveryForPrincipal, False, NumberOfSupplierAgreements > 0);
		If Object.BusinessOperation = Enums.BusinessTransactions.ProviderGoodsWriteOffAtTheExpenseOfProvider
			Or Object.BusinessOperation = Enums.BusinessTransactions.ProviderGoodsWriteOffAsExpenses Then
			SetPropertyValue = False;
		EndIf;
		TMCommonUseClientServer.SetFormItemProperty(Items, "Terms", "Visible",
			SetPropertyValue);
	EndIf;
	
EndProcedure

&AtServer
Procedure SetVisibilityOfElementsByOperation()
	
	Var ArrayOfAllProps;
	Var ArrayOfOperationDetails;
	
	Documents.ReportOnVMIAdjustment.FillInNamesOfBusinessTransactionDetails(
		Object.BusinessOperation, ArrayOfAllProps, ArrayOfOperationDetails);
	CashServer.SetVisibilityOfElementsByArray(Items, ArrayOfAllProps,
		ArrayOfOperationDetails);
	
	Items.GoodsFillThePricesByTermsOfSales.Visible =
		Object.BusinessOperation = Enums.BusinessTransactions.ConsumptionOfGoodsReceivedAsExpenses;
	
	VisibilityOfElements =
		Object.BusinessOperation = Enums.BusinessTransactions.ConsumptionOfGoodsReceivedAsExpenses
		Or Object.BusinessOperation = Enums.BusinessTransactions.ProviderGoodsWriteOffAsExpenses
		Or False;
	
	ItemArray = New Array;
	ItemArray.Add("GoodsFillInThePricesOfTheSelectedLinesByTheTypeOfSupplierSPrice");
	ItemArray.Add("AmountTotal");
	ItemArray.Add("PaymentGroup_2");
	ItemArray.Add("CurrenciesGroup");
	ItemArray.Add("DocumentCurrency");
	
	TMCommonUseClientServer.SetPropertyOfFormElements(Items, ItemArray, "Visible",
		VisibilityOfElements);
	
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
Procedure EstablishRelationshipsBetweenContractSelectionParameters()
	ContractSelectionParameters = New Array;
	ContractSelectionParameters.Add(New ChoiceParameter("Filter.DeletionMark", False));
	
	ContractSelectionParameters.Add(
		New ChoiceParameter("Filter.Status", Enums.CounterpartyContractStatuses.Valid));
		
	ContractSelectionParameters.Add(
		New ChoiceParameter(
			"Filter.RegistrationOfWriteOffOfInventoryShortageAcceptedForStorage",
			Enums.RegistrationOfWriteOffOfGoodsAcceptedForStorage.RegisterWriteOff));
			
	ContractSelectionParameters.Add(
		New ChoiceParameter(
			"Filter.BusinessOperation", ContractBusinessTransaction(Object.BusinessOperation)));
	RelationsOfContractSelectionParameters = New Array;
	RelationsOfContractSelectionParameters.Add(
		New ChoiceParameterLink(
				"Filter.Counterparty", "Object.Counterparty", LinkedValueChangeMode.Clear));
		
	RelationsOfContractSelectionParameters.Add(
		New ChoiceParameterLink(
				"Filter.Organization", "Object.Organization", LinkedValueChangeMode.Clear));
		
	RelationsOfContractSelectionParameters.Add(
		New ChoiceParameterLink(
				"Partner", "Object.Partner", LinkedValueChangeMode.Clear));
	If Object.BusinessOperation = Enums.BusinessTransactions.ProviderGoodsWriteOffAtTheExpenseOfProvider
		Or Object.BusinessOperation = Enums.BusinessTransactions.ProviderGoodsWriteOffAsExpenses Then
	
		ContractSelectionParameters.Add(
			New ChoiceParameter("Filter.ContractType", Enums.ContractTypes.ReceiptForTolling2_5));
	
	Else
	
		TypesOfContract = New Array;
		TypesOfContract.Add(Enums.ContractTypes.ReceivingForCustody);
		TypesOfContract.Add(Enums.ContractTypes.CustomerInvoiceOutsourcedSale);
		
		ContractSelectionParameters.Add(New ChoiceParameter("Filter.ContractType", TypesOfContract));
		If RecalculatePrices_2 Then
			
			RelationsOfContractSelectionParameters.Add(
				New ChoiceParameterLink(
						"Filter.ARAPCurrency",
						"Object.ARAPCurrency",
						LinkedValueChangeMode.Clear));
			
		EndIf;
		
		RelationsOfContractSelectionParameters.Add(
			New ChoiceParameterLink(
					"Terms", "Object.Terms", LinkedValueChangeMode.DontChange));
	EndIf;
	
	Items.Contract.ChoiceParameters       = New FixedArray(ContractSelectionParameters);
	Items.Contract.ChoiceParameterLinks = New FixedArray(RelationsOfContractSelectionParameters);
	
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
		Enums.StorageLocationTypes.Warehouse, NStr("vi = 'Ghi giảm hàng hóa được lưu tại kho';
													|ru = 'Списание товаров, хранящихся на складе';
													|en = 'Write off goods stored in the warehouse'; fa = 'اسقاط کالای نگهداری‌شده در انبار';
													|it = 'Cancellazione delle merci depositate nel magazzino';
													|pl = 'Spisanie towarów, przechowywanych w magazynie';
													|tr = 'Depolanan malların gider yazılması'"));
	If Object.BusinessOperation = Enums.BusinessTransactions.ProviderGoodsWriteOffAtTheExpenseOfProvider
		Or Object.BusinessOperation = Enums.BusinessTransactions.ProviderGoodsWriteOffAsExpenses Then
		
		ProductsTypeOfStoragePlaceSelectionList.Add(
			Enums.StorageLocationTypes.Department, NStr("vi = 'Ghi giảm hàng hóa chuyển vào sản xuất';
														|ru = 'Списание товаров, переданных в производство';
														|en = 'Write off goods transferred to production'; fa = 'اسقاط کالای منتقل‌شده به تولید';
														|it = 'Cancellazione delle merci consegnate nella produzione';
														|pl = 'Spisanie towarów, przekazanych do produkcji';
														|tr = 'Üretime aktarılan malların gider yazılması'"));
		
		ProductsTypeOfStoragePlaceSelectionList.Add(
			Enums.StorageLocationTypes.CounterpartyContract, NStr("vi = 'Ghi giảm hàng hóa chuyển vào nơi cất giữ';
																	|ru = 'Списание товаров, переданных на хранение';
																	|en = 'Write-off goods transferred for storage'; fa = 'اسقاط کالای منتقل‌شده برای نگهداری';
																	|it = 'Cancellazione delle merci consegnate in deposito';
																	|pl = 'Rozchód towarów przekazanych na przechowywanie';
																	|tr = 'Depodaki malların gider yazılması'"));
		
	Else
		If GetFunctionalOption("UseProduction") Then
			
			ProductsTypeOfStoragePlaceSelectionList.Add(
				Enums.StorageLocationTypes.Department, NStr("vi = 'Ghi giảm hàng hóa chuyển vào sản xuất';
															|ru = 'Списание товаров, переданных в производство';
															|en = 'Write off goods transferred to production'; fa = 'اسقاط کالای منتقل‌شده به تولید';
															|it = 'Cancellazione delle merci consegnate nella produzione';
															|pl = 'Spisanie towarów, przekazanych do produkcji';
															|tr = 'Üretime aktarılan malların gider yazılması'"));
			
		EndIf;
		
		If GetFunctionalOption("UseTransferToCustodyWithRightOfSale") Then
			
			ProductsTypeOfStoragePlaceSelectionList.Add(
				Enums.StorageLocationTypes.CounterpartyContract, NStr("vi = 'Ghi giảm hàng hóa chuyển vào nơi cất giữ';
																		|ru = 'Списание товаров, переданных на хранение';
																		|en = 'Write-off goods transferred for storage'; fa = 'اسقاط کالای منتقل‌شده برای نگهداری';
																		|it = 'Cancellazione delle merci consegnate in deposito';
																		|pl = 'Rozchód towarów przekazanych na przechowywanie';
																		|tr = 'Depodaki malların gider yazılması'"));
			
		EndIf;
	EndIf;
EndProcedure

&AtServer
Procedure FillInStorageLocationPresentation(FillInContractDetails = False)
	
	SetPrivilegedMode(True);
	
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

&AtServer
Procedure ChangedPaymentServer(EventName, Parameter, Source)
	
	ARAPAccountingFormWork.NotificationProcessing(ThisForm, EventName, Parameter);
	
EndProcedure

&AtServer
Procedure FillInSubordinatePropertiesForStatistics(ParentPropsName)
	
	ObjectsFillingByStatistics.FillInSubordinateDetailsOfObject(Object, ParentPropsName);
	
EndProcedure

&AtServerNoContext
Function GetDefaultCounterpartyBankAccountServer(Counterparty)
	
	ParametersOfAccount = CashServer.ParametersForFillingInCounterpartySBankAccount(Counterparty);
	
	Return CashServer.GetDefaultCounterpartyBankAccount(ParametersOfAccount);
	
EndFunction

&AtClient
Procedure QuestionUserBeforeFillingInPricesByAgreement(CallbackDescription)
	
	If Not RecalculatePrices_2
		Or Object.Goods.Count() = 0
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
Procedure FillInTermsOfSettlementsUnderAgreement()
		
	If UseLinesOfBusiness Then
		LinesOfBusinessServer.FillInDefaultDirection(Object.LineOfBusiness, Object.Terms,
			Object.Contract);
		ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);
	EndIf;
	
EndProcedure

&AtServer
Procedure FillInDefaultContract()
	
	AddlParameters = PurchasesServer.AdditionalContractSelectionParameters();
	AddlParameters.ARAPCurrency                                       = Object.ARAPCurrency;
	AddlParameters.RegistrationOfWriteOffOfInventoryShortageAcceptedForStorage =
		Enums.RegistrationOfWriteOffOfGoodsAcceptedForStorage.RegisterWriteOff;
	
	If UseLinesOfBusiness Then
		AddlParameters.LineOfBusiness = Object.LineOfBusiness;
	EndIf;
	
	DefaultContract = PurchasesServer.GetDefaultContract(
							Object, ContractBusinessTransaction(Object.BusinessOperation), AddlParameters);
	
	If Contract <> DefaultContract Then
		Object.Contract = DefaultContract;
		
		ContractOnChangeServer();
	EndIf;
	
EndProcedure

&AtServer
Procedure FillInTermsOfPurchaseForOperation()
	
	DocumentCurrency = Object.Currency;
	
EndProcedure

&AtServer
Procedure FillInArticleSelectionParameters()
	
	// Selection of articles and analytics.
	ItemsAndDimensionsSelectionParameters =
		Documents.ReportOnVMIAdjustment.ItemsAndDimensionsSelectionParameters(Object.BusinessOperation);
	IncomeAndExpensesServer.WhenChangingArticleSelectionParameters(ThisObject, ItemsAndDimensionsSelectionParameters);
	
EndProcedure

&AtServer
Procedure FillInAccountSettings()
	
	// Setting up accounting accounts.
	SetupParameters = Documents.ReportOnVMIAdjustment.AccountingAccountSettings_(
							Object.BusinessOperation);
	GLAccountSettingsServer.WhenChangingSettings(ThisObject, SetupParameters);
	
EndProcedure

&AtClientAtServerNoContext
Procedure AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions, RecalculatePrices_2)
	
	StructureOfActions.Insert("RecalculateNumberOfUnits");
	
	If RecalculatePrices_2 Then
		StructureOfActions.Insert("RecalculateAmount");
		StructureOfActions.Insert("ClearAmountOfSettlements");
	EndIf;
	
EndProcedure

&AtClient
Procedure SelectionOfGoodsToBeWrittenOffFromStorage()
	
	Cancel = False;
	
	ClearMessages();
	
	If Not ValueIsFilled(Object.Partner) Then
		CommonClientServer.MessageToUser(NStr("vi = 'Chưa điền trường ""Nhà cung cấp""';
												|ru = 'Поле ""Поставщик"" не заполнено';
												|en = '""Vendor"" is required'; fa = '""Vendor"" is required';
												|it = 'Il campo ""Fornitore"" non è compilato';
												|pl = 'Nie wypełniono pola ""Dostawca""';
												|tr = '""Tedarikçi"" alanı doldurulmadı'"), Object.Ref,
			"Object.Partner", "", Cancel);
	EndIf;
	
	If Not ValueIsFilled(Object.Organization) Then
		CommonClientServer.MessageToUser(NStr("vi = 'Chưa điền trường ""Doanh nghiệp""';
												|ru = 'Поле ""Организация"" не заполнено';
												|en = 'The ""Company"" field is required'; fa = 'The ""Company"" field is required';
												|it = 'Il campo ""Società"" non è compilato';
												|pl = 'Nie wypełniono pola ""Firma""';
												|tr = '""İş yeri"" alanı doldurulmadı'"), Object.Ref,
			"Object.Organization", "", Cancel);
	EndIf;
	
	If Not ValueIsFilled(Object.Contract) Then
		CommonClientServer.MessageToUser(NStr("vi = 'Trường ""Hợp đồng"" chưa điền';
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
		If Object.BusinessOperation <>
				PredefinedValue("Enum.BusinessTransactions.ProviderGoodsWriteOffAtTheExpenseOfProvider")
			And Object.BusinessOperation <>
				PredefinedValue("Enum.BusinessTransactions.ProviderGoodsWriteOffAsExpenses") Then
			FormParameters.Insert(
				"InventoryType", PredefinedValue("Enum.InventoryTypes.GoodsInStorageWithRightToSell"));
		Else
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
		OpenForm("DataProcessor.SelectGoodsReceivedForCustody.Form.Form", FormParameters, ThisForm,
			UUID);
		
	EndIf;
	
EndProcedure

&AtServer
Function PlaceGoodsInTemporaryStorageServer()
	
	Return PurchasesServer.PlaceGoodsInTemporaryStorage(Object.Goods);
	
EndFunction

&AtServer
Procedure FillInItemsFromTemporaryStorageServer(AddressInTempStorage)
	
	StructureOfActions = New Structure;
	If RecalculatePrices_2 Then
		StructureOfActions.Insert("RecalculateAmount");
		StructureOfActions.Insert("ClearAmountOfSettlements");
	EndIf;
	
	CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	RowsToProcess = New Array();
	
	TableOfGoods = GetFromTempStorage(AddressInTempStorage); // DocumentTabularSection.ReportOnVMIAdjustment.Goods
	
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
	
	FillInServiceDetailsForProductRange();
	ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);
	
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
	BsnsTransactions.Add(PredefinedValue("Enum.BusinessTransactions.ReceivingForStorageWithRightOfSale"));
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
													ThisForm,
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

#EndRegion

// StandardSubsystems.Properties
&AtServer
Procedure UpdateAdditionalAttributesItems()
	
	PropertyManager.UpdateAdditionalAttributesItems(ThisForm);
	
EndProcedure

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
Procedure PlacePaymentDecryptionInTemporaryStorage()
	ARAPAccountingFormWork.PlacePaymentDecryptionInTemporaryStorage(ThisForm);
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
