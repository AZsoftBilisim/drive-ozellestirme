
#Region Variables

&AtClient
Var CachedValues; //It is used by the mechanism for processing changes in PM details.

&AtClient
Var EditingRegistrationSeries; //used to determine that the series selection form is called for the series specified in the header

&AtClient
Var CounterpartyVerificationWaitHandlerParameters Export;

&AtClient
Var TimeConsumingOperationForm Export;

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
	
	// Handler of the "Properties" subsystem
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("Object",                   Object);
	AdditionalParameters.Insert("ItemForPlacementName", "GroupAdditionalAttributes");
	AdditionalParameters.Insert("DeferredInitialization",  True);
	
	PropertyManager.OnCreateAtServer(ThisForm, AdditionalParameters);
	
	// Handler of the "Versioning of objects" mechanism
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	
	// Handler of the "Destination" mechanism
	Catalogs.Assignments.DocumentFormWhenCreatedOnServer(ThisForm);
	
	FillInAccordingToDataInRepository();
	
	Items.GoodsProducts.ReadOnly                = Parameters.ProhibitChangingProducts;
	Items.GoodsCharacteristic.ReadOnly              = Parameters.ProhibitChangingProducts;
	Items.GoodsProductsRecordingAsReceived.ReadOnly   = Parameters.ProhibitChangingProducts;
	Items.GoodsCharacteristicRecordingAsReceived.ReadOnly = Parameters.ProhibitChangingProducts;
	Items.GoodsCount.ReadOnly                  = Parameters.ProhibitChangingProducts;
	Items.Contract.ReadOnly                           = Parameters.ProhibitChangingProducts;
	Items.Organization.ReadOnly                       = Parameters.ProhibitChangingProducts;
	Items.Goods.ChangeRowSet                       = Not Parameters.ProhibitChangingProducts;
	
	If Not ValueIsFilled(Object.Ref) Then
		OnReadCreateAtServer();
		ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);
	EndIf;
	
	SetAvailabilityOfClipboardCommands();
	
	AccountingForTraceableGoodsLocalization.EstablishVisibilityOfRNPTQuantity(ThisForm, Object.Date);
	
	// Selection of articles and analytics.
	ItemsAndDimensionsSelectionParameters = Documents.MisgradingOfGoodsAtCustodian.ItemsAndDimensionsSelectionParameters(Object.ReceiveGoodsAtCostTheyWereIssuedFromWarehouse);
	IncomeAndExpensesServer.OnCreateAtServer(ThisObject, ItemsAndDimensionsSelectionParameters);
	
	DocumentCorrection.OnCreateAtServer(ThisObject, Items.LineCorrection);
	
	// Setting up accounting accounts.
	SetupParameters = Documents.MisgradingOfGoodsAtCustodian.AccountingAccountSettings_();
	GLAccountSettingsServer.OnCreateAtServer(ThisObject, SetupParameters);
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	// StandardSubsystems.SourceDocumentsOriginalsRecording
	SourceDocumentsOriginalsRecording.OnCreateAtServerDocumentForm(ThisObject);
	// End StandardSubsystems.SourceDocumentsOriginalsRecording
	
	// StandardSubsystems.FilesOperations
	HyperlinkParameters = FilesOperations.FilesHyperlink();
	HyperlinkParameters.Location = "CommandBar";
	FilesOperations.OnCreateAtServer(ThisObject, HyperlinkParameters);
	// End StandardSubsystems.FilesOperations
	
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	
	AccountingForTraceableGoodsLocalization.SetTitleNumberOfCCD(Items, "GoodsCCDNumber");
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject);
	// End IntegrationWith1CDocumentManagementSubsystem
	
	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	// StandardSubsystems.Properties
	PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
	// End StandardSubsystems.Properties
	
	
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
Procedure ChoiceProcessing(ValueSelected, ChoiceSource)
	
	If ChoiceSource.FormName = "DataProcessor.SelectGoodsToSalesDocument.Form.Form" Then
		
		ProcessingSelectionOfSelectionOnServer(ValueSelected);
		
	ElsIf ChoiceSource.FormName = "DataProcessor.SelectGoodsTransferredToCustody.Form.Form" Then
		
		ProcessingOfSelectionSelectionOfTransferredGoodsOnServer(ValueSelected);
		
	ElsIf ChoiceSource.FormName = "Catalog.InventoryKinds.Form.InventoryOwnerAttributesForm" Then
		
		GetStockTypesFromStorage(ValueSelected);
		
	ElsIf ProductsClient.ThisIsIndicationOfSeries(ChoiceSource) Then
		
		Suffix = ?(EditingRegistrationSeries, "RecordingAsReceived", "");
		
		AttributesNames = New Array;
		AttributesNames.Add("Series");
		AttributesNames.Add("BatchesIndicationStatus");
		
		CurrentData = Items.Goods.RowData(ValueSelected.CurrentRowID);
		
		CurrentRow = New Structure;
		
		For Each AttributeName In AttributesNames Do
			CurrentRow.Insert(AttributeName, CurrentData[AttributeName + Suffix]);
		EndDo;
		
		ProductsClient.ProcessSeriesIndication(ThisForm, SeriesSpecificationParameters, ValueSelected, CurrentRow);
		
		For Each AttributeName In AttributesNames Do
			CurrentData[AttributeName + Suffix] = CurrentRow[AttributeName];
		EndDo;
		
	ElsIf PurchasesClient.ThisIsSelectionOfCCDNumber(ChoiceSource) Then
		
		ProcessSelectionOfCCDNumber(ValueSelected);
		
	EndIf;
	
	If Window <> Undefined Then
		Window.Activate();
	EndIf;
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	// Subsystem "Properties"
	If PropertyManagerClient.ProcessNotifications(ThisForm, EventName, Parameter) Then
		UpdateAdditionalAttributesItems();
		PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
	EndIf;
	
	If EventName = "CopyingLinesToClipboard" Then
		SetAvailabilityOfClipboardCommandsOnClient();
	EndIf;
	
	DocumentCorrectionClient.NotificationProcessing(ThisObject, EventName, Parameter, Source);
	
	
	// StandardSubsystems.FilesOperations
	FilesOperationsClient.NotificationProcessing(ThisObject, EventName);
	// End StandardSubsystems.FilesOperations
	
	// StandardSubsystems.SourceDocumentsOriginalsRecording	
	SourceDocumentsOriginalsRecordingClient.NotificationHandlerDocumentForm(EventName, ThisObject);
	// End StandardSubsystems.SourceDocumentsOriginalsRecording
	
	FormEventsClient.NotificationProcessing(ThisObject, EventName, Parameter, Source);
	
	If EventName = "WhenChangingAgreement"
		And Source = ThisObject Then
		Modified = True;
		ContractOnChange(Items[Parameter]);
	EndIf;
	
EndProcedure

&AtClient
Procedure NewWriteProcessing(NewObject, Source, StandardProcessing)
	
	If PurchasesClient.ThisIsIndicationOfCCDNumber(Source) Then
		
		CurrentData = Items.Goods.CurrentData;
		
		If CurrentData <> Undefined Then
			
			CurrentRow = DescriptionOfTablePartRow(CurrentData);
			CurrentRow.Products = CurrentData.ProductsRecordingAsReceived;
			CurrentRow.Characteristic = CurrentData.CharacteristicRecordingAsReceived;
			
			Actions = New Structure;
			
			AccountingForTraceableGoodsClientServerLocalization.AddDescriptionOfSettingsForRecalculatingDetailsOfTablePart(
				Object,
				Actions,
				"Contract");
			
			PurchasesClient.ProcessIndicationOfCCDNumber(ThisObject, NewObject, , CurrentRow, Actions);
			
			CurrentData.QuantityByGBRN		= CurrentRow.QuantityByGBRN;
			CurrentData.CCDNumberType			= CurrentRow.CCDNumberType;
			CurrentData.OriginCountry	= CurrentRow.OriginCountry;
			
		EndIf;
		
	EndIf;
	
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)
	
	DocumentCorrection.OnReadAtServer(ThisObject, Items.LineCorrection);
	
	// StandardSubsystems.AccessManagement
	AccessManagement.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.AccessManagement
	
	// Handler of the "Date-change" mechanism
	PeriodClosingDates.ObjectOnReadAtServer(ThisForm, CurrentObject);
	
	// Handler of the "Properties" subsystem
	PropertyManager.OnReadAtServer(ThisForm, CurrentObject);
	
	OnReadCreateAtServer();
	
	// Selection of articles and analytics.
	ItemsAndDimensionsSelectionParameters = Documents.MisgradingOfGoodsAtCustodian.ItemsAndDimensionsSelectionParameters(Object.ReceiveGoodsAtCostTheyWereIssuedFromWarehouse);
	IncomeAndExpensesServer.OnReadAtServer(ThisObject, ItemsAndDimensionsSelectionParameters);

	// Setting up accounting accounts.
	SetupParameters = Documents.MisgradingOfGoodsAtCustodian.AccountingAccountSettings_();
	GLAccountSettingsServer.OnReadAtServer(ThisObject, SetupParameters);
	FormEvents.OnReadAtServer(ThisObject, CurrentObject);
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

&AtClient
Procedure BeforeWrite(Cancel, WriteParameters)
	
	FormEventsClient.BeforeWrite(ThisObject, Cancel, WriteParameters);
	
	If NotExecuteCheck1BeforeWrite Then
		NotExecuteCheck1BeforeWrite = False;
		
		Return;
	EndIf;
	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	// Handler of the "Properties" subsystem
	PropertyManager.BeforeWriteAtServer(ThisForm, CurrentObject);
	
	
	// Setting up accounting accounts.
	GLAccountSettingsServer.BeforeWriteAtServer(ThisObject, CurrentObject);
	ConfigurationModificationOverridable.BeforeWriteAtServer(ThisForm, Cancel, CurrentObject, WriteParameters);
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.BeforeWriteAtServer(
		ThisObject,
		CurrentObject,
		WriteParameters);
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
	
	Handler = Documents.MisgradingOfGoodsAtCustodian.ActionHandler(Object.BusinessOperation);
	Handler.CustomizeForm(ThisObject, Object.Number, Object.Date);
	
	FillInServiceDetailsForProductRange();
	AssignmentsServer.FillInDestinationTypeInTable(Object.Goods);
	// Selection of articles and analytics.
	IncomeAndExpensesServer.AfterWriteAtServer(ThisObject);

	// Setting up accounting accounts.
	GLAccountSettingsServer.AfterWriteAtServer(ThisObject);
	
	ConfigurationModificationOverridable.AfterWriteAtServer(ThisForm, CurrentObject, WriteParameters);
	
	FormEvents.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	
	WriteParameters.Insert("NotificationDocumentKeys", OperationsWithDocumentJournalsClient.GetKeyParametersForDocument(
		Object.Ref, Object.Date, Object.BusinessOperation));
	Notify("Write_MisgradingOfGoodsAtCustodian", WriteParameters, Object.Ref);
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.AfterWrite(ThisForm, Object, WriteParameters);
	// End StandardSubsystems.AttachableCommands
	
	DocumentCorrectionClient.AfterWrite(Object);
	
	ConfigurationModificationClientOverridable.AfterWrite(ThisForm, WriteParameters);
	
	TMCommonUseClient.PerformActionsAfterRecording(ThisForm, Object, WriteParameters)
	
EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	
	// StandardSubsystems.Properties
	PropertyManager.FillCheckProcessing(ThisForm, Cancel, CheckedAttributes);
	// End StandardSubsystems.Properties
	
EndProcedure

&AtClient
Procedure URLProcessing(FormattedStringURL, StandardProcessing)
	
	FormEventsClient.URLProcessing(ThisObject, FormattedStringURL, StandardProcessing);
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure GroupPagesOnCurrentPageChange(Item, CurrentPage)
	
	// StandardSubsystems.Properties
	If CurrentPage.Name = "AdditionalPage"
		And Not ThisObject.PropertiesParameters.DeferredInitializationExecuted Then
		
		PropertiesExecuteDeferredInitialization();
		PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
		
	EndIf;
	// End StandardSubsystems.Properties
	
EndProcedure

&AtClient
Procedure BusinessOperationOnChange(Item)
	
	If BusinessTransactionBeforeTheChange = Object.BusinessOperation Then
		Return;
	EndIf;
	
	BusinessOperationOnChangeServer();
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands

EndProcedure

&AtClient
Procedure DateOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	
	DateOnChangeServer();
	
	
EndProcedure

&AtClient
Procedure PartnerOnChange(Item)
	
	PartnerOnChangeServer();
	
	
EndProcedure

&AtClient
Procedure CounterpartyOnChange(Item)
	
	CounterpartyOnChangeServer();
	
	
EndProcedure

&AtClient
Procedure TermsOnChange(Item)
	
	If Not ValueIsFilled(Object.Terms) Then
		Return;
	EndIf;
	
	TermsOnChangeServer();
	
EndProcedure

&AtClient
Procedure TermsStartChoice(Item, ChoiceData, StandardProcessing)
	
	AgreementSelectionParameters = SalesClient.ParametersForStartingSelectionOfAgreementWithClient();
	AgreementSelectionParameters.Item               = Item;
	AgreementSelectionParameters.Partner               = Object.Partner;
	AgreementSelectionParameters.Document              = Object.Terms;
	AgreementSelectionParameters.DocumentDate         = Object.Date;
	AgreementSelectionParameters.FormDataStructure  = Object;
	AgreementSelectionParameters.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.TransferToStorageWithRightOfSale");
	
	SalesClient.StartSelectingAgreementWithClient(AgreementSelectionParameters, StandardProcessing);
	
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
Procedure DimensionOfExpensesAutoComplete(Item, Text, ChoiceData, Var_Parameters, Waiting, StandardProcessing)
	
	// Selection of articles and analytics.
	IncomeAndExpensesClient.AutoSelectionOfExpenseAnalytics(ThisObject, Item, Text, ChoiceData, Var_Parameters,
		StandardProcessing);
	
EndProcedure

&AtClient
Procedure DimensionOfExpensesTextEditEnd(Item, Text, ChoiceData, Var_Parameters, StandardProcessing)
	
	// Selection of articles and analytics.
	IncomeAndExpensesClient.EndOfCostAnalyticsTextEntry(ThisObject, Item, Text, ChoiceData, Var_Parameters,
		StandardProcessing);
	
EndProcedure

&AtClient
Procedure IncomeItemStartChoice(Item, ChoiceData, StandardProcessing)
	
	IncomeAndExpensesClient.StartArticleSelection(ThisObject, Item, StandardProcessing);
	
EndProcedure

&AtClient
Procedure IncomeItemOnChange(Item)
	
	IncomeAndExpensesClientServer.AssetRefOnChange(ThisObject, Item);
	
EndProcedure

&AtClient
Procedure DimensionOfRevenueOnChange(Item)
	
	IncomeAndExpensesClientServer.DimensionOfRevenueOnChange(ThisObject, Item);
	
EndProcedure

&AtClient
Procedure TransactionRecordingPresentationClick(Item, StandardProcessing)
	GLAccountSettingsClient.OnClick(ThisObject, Item, StandardProcessing);
	Return; // empty handler
	
EndProcedure

&AtClient
Procedure OrganizationOnChange(Item)
	
	OrganizationOnChangeServer();
	
EndProcedure

&AtClient
Procedure ContractCreating(Item, StandardProcessing)
	
	SalesClient.OpenContractCreationForm(ThisObject, Item, "Object.Contract", Object.Partner, StandardProcessing);
	
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
Procedure CurrencyOnChange(Item)
	
	If PriceManagementSystemClient.CurrencyConversionRequired(Object, DocumentCurrency) Then
		CurrencyOnChangeServer();
		PriceManagementSystemClient.NotifyAboutEndOfConversionOfAmountsIntoCurrency(DocumentCurrency, Object.Currency);
	EndIf;
	
	DocumentCurrency = Object.Currency;
	
EndProcedure

&AtClient
Procedure ReceiveGoodsAtCostTheyWereIssuedFromWarehouseOnChange(Item)
	
	If Object.ReceiveGoodsAtCostTheyWereIssuedFromWarehouse Then
		Object.PriceKind = Undefined;
		ClearPrices(ThisObject);
	EndIf;
	
	SetAvailabilityViewPrices(ThisObject);
	SetSettingsForFormattingArticleFields(ThisObject);
	
EndProcedure

// StandardSubsystems.Properties
&AtClient
Procedure Attachable_OnChangeAdditionalAttribute(Item)
	
	PropertyManagerClient.UpdateAdditionalAttributesDependencies(ThisObject);
	
EndProcedure
// End StandardSubsystems.Properties

&AtClient
Procedure LineCorrectionURLProcessing(Item, FormattedStringURL, StandardProcessing)
	
	DocumentCorrectionClient.StringFixHandlingNavigationLinks(
		ThisObject,
		FormattedStringURL,
		StandardProcessing);
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersGoods

&AtClient
Procedure GoodsOnActivateCell(Item)
	
	If Item.CurrentItem = Undefined Then
		Return;
	ElsIf Item.CurrentItem.Name = "GoodsCCDNumber" Then
		PurchasesClient.FillInListOfCCDNumberSelection(
			Items.Goods.CurrentData, Items.GoodsCCDNumber.ChoiceList);
	EndIf;
	
EndProcedure

&AtClient
Procedure GoodsBeforeDeleteRow(Item, Cancel)
	
	ProductsClient.UpdateCachedValuesToAccountForSeries(Item, CachedValues, SeriesSpecificationParameters);
	
EndProcedure

&AtClient
Procedure GoodsOnStartEdit(Item, NewRow, Copy)
	
	ProductsClient.UpdateCachedValuesToAccountForSeries(
		Item, CachedValues, SeriesSpecificationParameters, Copy);
	
EndProcedure

&AtClient
Procedure GoodsOnEditEnd(Item, NewRow, CancelEdit)
	
	If ProductsClient.SeriesStatusesNeedToBeUpdated(Item, CachedValues, SeriesSpecificationParameters) Then
	
		IDCurrentRow = Items.Goods.CurrentData.GetID();
		
		FillInStatusesOfSpecifyingSeriesWhenEditingLineTS(
			IDCurrentRow, CachedValues);
			
		ProductsClient.UpdateCachedValuesToAccountForSeries(
			Item, CachedValues, SeriesSpecificationParameters);
	
	EndIf;
	
EndProcedure

&AtClient
Procedure GoodsAfterDeleteRow(Item)
	
	UpdateSeriesStatuses = ProductsClient.SeriesStatusesNeedToBeUpdated(
							Item, CachedValues, SeriesSpecificationParameters, True);
	
	GoodsAfterDeleteRowServer(UpdateSeriesStatuses, CachedValues);
	
	If UpdateSeriesStatuses Then
		
		ProductsClient.UpdateCachedValuesToAccountForSeries(
			Item, CachedValues, SeriesSpecificationParameters);
			
	EndIf;
	
EndProcedure

&AtClient
Procedure GoodsProductsOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;
	
	FillInArticleAttribute = New Structure;
	FillInArticleAttribute.Insert("Products", "SKU");
	
	FillInProductTypeAttribute_ = New Structure;
	FillInProductTypeAttribute_.Insert("Products", "ItemsType");
	
	CheckSeriesCalculateStatus = New Structure;
	CheckSeriesCalculateStatus.Insert("Warehouse",                  Undefined);
	CheckSeriesCalculateStatus.Insert("SeriesSpecificationParameters", SeriesSpecificationParameters);
		
	ProductsOnChangeOverridable = New Structure;
	ProductsOnChangeOverridable.Insert("FormName",          FormName);
	ProductsOnChangeOverridable.Insert("TabularSectionName", "Goods");
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInArticleAttribute",                  FillInArticleAttribute);
	StructureOfActions.Insert("FillInProductTypeAttribute_",          FillInProductTypeAttribute_);
	StructureOfActions.Insert("CheckCharacteristicsByOwner",       CurrentRow.Characteristic);
	StructureOfActions.Insert("CheckSeriesCalculateStatus",           CheckSeriesCalculateStatus);
	StructureOfActions.Insert("ProductsOnChangeOverridable", ProductsOnChangeOverridable);
	StructureOfActions.Insert("FillInDestinationType",                   FillingParametersByDestinationType());
	LinesOfBusinessClientServer.StructureOfInsertActionsWhenAddingRow(ThisForm, StructureOfActions);
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
EndProcedure

&AtClient
Procedure GoodsCharacteristicOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;
	
	CharacteristicOnChangeOverridable = New Structure;
	CharacteristicOnChangeOverridable.Insert("FormName",          FormName);
	CharacteristicOnChangeOverridable.Insert("TabularSectionName", "Goods");
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("CharacteristicOnChangeOverridable", CharacteristicOnChangeOverridable);
	StructureOfActions.Insert("FillInDestinationType",                     FillingParametersByDestinationType());
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
	OpenSelectionOfSeries(False, Item.EditText);
	
EndProcedure

&AtClient
Procedure GoodsProductsRecordingAsReceivedOnChange(Item)
	
	CurrentData = Items.Goods.CurrentData;
	
	CurrentRow = DescriptionOfTablePartRow(CurrentData);
	CurrentRow.Insert("Products",               CurrentData.ProductsRecordingAsReceived);
	CurrentRow.Insert("Characteristic",             CurrentData.CharacteristicRecordingAsReceived);
	CurrentRow.Insert("ItemVariantsAreUsed", CurrentData.ItemVariantsAreUsedRecordingAsReceived);
	CurrentRow.Insert("PriceKind",                    Object.PriceKind);
	CurrentRow.Insert("Package",                   PredefinedValue("Catalog.PackagesAndUnitsOfMeasure.EmptyRef"));
	CurrentRow.Insert("Series",                      CurrentData.BatchReceipt);
	CurrentRow.Insert("BatchesIndicationStatus",        CurrentData.BatchesIndicationStatusReceipt);
	CurrentRow.Insert("ItemsType",            CurrentData.ItemTypePosting);
	
	FillInArticleAttribute = New Structure;
	FillInArticleAttribute.Insert("ProductsRecordingAsReceived", "SKURegistration");
	
	FillInProductTypeAttribute_ = New Structure;
	FillInProductTypeAttribute_.Insert("ProductsRecordingAsReceived", "ItemTypePosting");
	
	CheckSeriesCalculateStatus = New Structure;
	CheckSeriesCalculateStatus.Insert("Warehouse",                  Undefined);
	CheckSeriesCalculateStatus.Insert("SeriesSpecificationParameters", SeriesSpecificationParameters);
	
	FillInCCDTrackingAttribute = New Structure;
	FillInCCDTrackingAttribute.Insert("ProductsRecordingAsReceived", "TheRecordsAreKeptByCCD");
	
	CountryOfOriginFillingParameters = BatchProcessingOfTablePartClientServer.CountryOfOriginFillingParameters();
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInArticleAttribute",            FillInArticleAttribute);
	StructureOfActions.Insert("FillInProductTypeAttribute_",    FillInProductTypeAttribute_);
	StructureOfActions.Insert("CheckCharacteristicsByOwner", CurrentData.CharacteristicRecordingAsReceived);
	StructureOfActions.Insert("CheckSeriesCalculateStatus",     CheckSeriesCalculateStatus);
	StructureOfActions.Insert("FillInCCDTrackingAttribute",   FillInCCDTrackingAttribute);
	StructureOfActions.Insert("FillInCountryOfOriginOfProduct", CountryOfOriginFillingParameters);
	
	If Not Object.ReceiveGoodsAtCostTheyWereIssuedFromWarehouse Then
		FillInSalePrice = New Structure;
		FillInSalePrice.Insert("Date",   Object.Date);
		FillInSalePrice.Insert("Currency", Object.Currency);
		
		StructureOfActions.Insert("FillInSalePrice", FillInSalePrice);
	EndIf;
	
	AccountingForTraceableGoodsClientServerLocalization.CompleteDescriptionOfSettingsForFillingInServiceDetailsOfTablePart(StructureOfActions);
	AccountingForTraceableGoodsClientServerLocalization.AddDescriptionOfSettingsForRecalculatingDetailsOfTablePart(
		Object,
		StructureOfActions,
		"Contract");
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
	CurrentData.SKURegistration                    = CurrentRow.SKURegistration;
	CurrentData.CharacteristicRecordingAsReceived             = CurrentRow.Characteristic;
	CurrentData.ItemVariantsAreUsedRecordingAsReceived = CurrentRow.ItemVariantsAreUsed;
	CurrentData.Price                                    = CurrentRow.Price;
	CurrentData.TheRecordsAreKeptByCCD                        = CurrentRow.TheRecordsAreKeptByCCD;
	CurrentData.AccountingForTheRNPTIsMaintained                       = CurrentRow.AccountingForTheRNPTIsMaintained;
	CurrentData.BatchReceipt                      = CurrentRow.Series;
	CurrentData.BatchesIndicationStatusReceipt        = CurrentRow.BatchesIndicationStatus;
	CurrentData.ItemTypePosting            = CurrentRow.ItemTypePosting;
	CurrentData.OriginCountry                     = CurrentRow.OriginCountry;
	CurrentData.QuantityByGBRN                        = CurrentRow.QuantityByGBRN;
	
	If Not CurrentData.TheRecordsAreKeptByCCD Then
		CurrentData.CCDNumber = Undefined;
		CurrentData.CCDNumberType = Undefined;
		CurrentData.OriginCountry = Undefined;
	EndIf;
	
EndProcedure

&AtClient
Procedure GoodsCharacteristicRecordingAsReceivedOnChange(Item)
	
	If Not ValueIsFilled(Object.PriceKind)
		Or Object.ReceiveGoodsAtCostTheyWereIssuedFromWarehouse Then
		
		Return;
		
	EndIf;
	
	CurrentData = Items.Goods.CurrentData;
	
	CurrentData = Items.Goods.CurrentData;
	
	CurrentRow = DescriptionOfTablePartRow(CurrentData);
	CurrentRow.Insert("Products",               CurrentData.ProductsRecordingAsReceived);
	CurrentRow.Insert("Characteristic",             CurrentData.CharacteristicRecordingAsReceived);
	CurrentRow.Insert("ItemVariantsAreUsed", CurrentData.ItemVariantsAreUsedRecordingAsReceived);
	CurrentRow.Insert("PriceKind",                    Object.PriceKind);
	CurrentRow.Insert("Package",                   PredefinedValue("Catalog.PackagesAndUnitsOfMeasure.EmptyRef"));
	
	If Not Object.ReceiveGoodsAtCostTheyWereIssuedFromWarehouse Then
		FillInSalePrice = New Structure;
		FillInSalePrice.Insert("Date",   Object.Date);
		FillInSalePrice.Insert("Currency", Object.Currency);
		
		StructureOfActions = New Structure;
		StructureOfActions.Insert("FillInSalePrice", FillInSalePrice);
	EndIf;
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
	CurrentData.Price = CurrentRow.Price;
	
EndProcedure

&AtClient
Procedure GoodsBatchReceiptOnChange(Item)
	
	CurrentData = Items.Goods.CurrentData;
	
	CurrentRow = New Structure;
	CurrentRow.Insert("Series",               CurrentData.BatchReceipt);
	CurrentRow.Insert("BatchesIndicationStatus", CurrentData.BatchesIndicationStatusReceipt);
	CurrentRow.Insert("Count",          CurrentData.Count);
	
	ValueSelected = ProductsClientServer.SelectedSeries();
	ValueSelected.Value            		 = CurrentData.BatchReceipt;
	ValueSelected.CurrentRowID = CurrentData.GetID();
	
	ProductsClient.ProcessSeriesIndication(ThisForm, SeriesSpecificationParameters, ValueSelected, CurrentRow);
	
	CurrentData.BatchReceipt               = CurrentRow.Series;
	CurrentData.BatchesIndicationStatusReceipt = CurrentRow.BatchesIndicationStatus;
	
EndProcedure

&AtClient
Procedure GoodsBatchReceiptStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	OpenSelectionOfSeries(True, Item.EditText);
	
EndProcedure

&AtClient
Procedure GoodsCCDNumberOnChange(Item)
	
	CurrentData = Items.Goods.CurrentData;
	
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	CurrentRow = DescriptionOfTablePartRow(CurrentData);
	CurrentRow.Products = CurrentData.ProductsRecordingAsReceived;
	CurrentRow.Characteristic = CurrentData.CharacteristicRecordingAsReceived;
	
	FillParameters = New Structure("CCDNumber", CurrentData.CCDNumber);
	
	Actions = New Structure;
	Actions.Insert("FillInCCDNumberType", FillParameters);
	Actions.Insert("FillInCountryOfOriginForCCDNumber", FillParameters);
	
	AccountingForTraceableGoodsClientServerLocalization.AddDescriptionOfSettingsForRecalculatingDetailsOfTablePart(
		Object,
		Actions,
		"Contract");
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, Actions, Undefined);
	
	CurrentData.QuantityByGBRN		= CurrentRow.QuantityByGBRN;
	CurrentData.CCDNumberType			= CurrentRow.CCDNumberType;
	CurrentData.OriginCountry	= CurrentRow.OriginCountry;
	
EndProcedure

&AtClient
Procedure GoodsCCDNumberCreating(Item, StandardProcessing)
	
	StandardProcessing = False;
	
	CurrentData = Items.Goods.CurrentData;
	
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	CurrentRow = DescriptionOfTablePartRow(CurrentData);
	CurrentRow.Products = CurrentData.ProductsRecordingAsReceived;
	CurrentRow.Characteristic = CurrentData.CharacteristicRecordingAsReceived;
	
	AdditionalParameters = PurchasesClient.AdditionalParametersForCreatingCCDNumber();
	FillPropertyValues(AdditionalParameters, ThisObject);
	
	AdditionalParameters.FieldNameQuantity	= "Count";
	AdditionalParameters.NameOfAmountField		= "Price";
	
	CreationParameters = PurchasesClient.ParametersForCreatingCCDNumber(CurrentRow,
																Item.EditText,
																AdditionalParameters);
	
	PurchasesClient.OpenFormForCreatingGTDNumber(ThisObject, CreationParameters);
	
EndProcedure

&AtClient
Procedure GoodsCountOnChange(Item)
	
	CurrentData = Items.Goods.CurrentData;
	
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	CurrentRow = DescriptionOfTablePartRow(CurrentData);
	CurrentRow.Insert("Products",		CurrentData.ProductsRecordingAsReceived);
	CurrentRow.Insert("Characteristic",	CurrentData.CharacteristicRecordingAsReceived);
	
	StructureOfActions = New Structure;
	AccountingForTraceableGoodsClientServerLocalization.AddDescriptionOfSettingsForRecalculatingDetailsOfTablePart(
		Object,
		StructureOfActions,
		"Contract");
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
	CurrentData.QuantityByGBRN = CurrentRow.QuantityByGBRN;
	
EndProcedure

&AtClient
Procedure GoodsPurposeOnChange(Item)
	CurrentRow = Items.Goods.CurrentData;
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInDestinationType", FillingParametersByDestinationType());
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, Undefined);
	Return; //The TMAR handler is empty
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

#Region StandardCommands

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

// StandardSubsystems.Properties
&AtClient
Procedure Attachable_PropertiesExecuteCommand(ItemOrCommand,
												Var_URL = Undefined,
												StandardProcessing = Undefined)
	
	PropertyManagerClient.ExecuteCommand(ThisObject, ItemOrCommand, StandardProcessing);
	
EndProcedure
// End StandardSubsystems.Properties

// IntegrationWith1CDocumentManagementSubsystem
&AtClient
Procedure Attachable_ExecuteIntegrationCommand(Command)
	
	IntegrationWith1CDocumentManagementCoreClient.ExecutePlugInIntegrationCommand(
		Command,
		ThisObject,
		Object);
	
EndProcedure
// End IntegrationWith1CDocumentManagementSubsystem

&AtClient
Procedure CheckCounterparties(Command)
	
	
EndProcedure

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

// StandardSubsystems.SourceDocumentsOriginalsRecording

&AtClient
Procedure Attachable_OriginalStateDecorationClick()
	SourceDocumentsOriginalsRecordingClient.OpenStateSelectionMenu(ThisObject, Items.OriginalStateDecoration);
EndProcedure

//End StandardSubsystems.SourceDocumentsOriginalsRecording

#EndRegion

&AtClient
Procedure PostAndClose(Command)
	
	TMCommonUseClient.PostAndClose(ThisForm);
	
EndProcedure

&AtClient
Procedure WriteDocument(Command)
	
	TMCommonUseClient.Write(ThisForm);
	
EndProcedure

&AtClient
Procedure PostDocument(Command)
	
	TMCommonUseClient.Post(ThisForm);
	
EndProcedure

&AtClient
Procedure OpenInventoryKinds(Command)
	
	OptionsForEditingInventoryTypes = PutGoodsAndStockTypesInStorage();
	
	FinancesClient.OpenInventoryKinds(ThisObject, OptionsForEditingInventoryTypes);
	
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
	
	TableData = Object.Goods;
	FormTable  = Items.Goods;
	
	PartitioningParameters = ProcessingOfTabularFormsClient.StringSplittingParameters();
	PartitioningParameters.FieldNameQuantity = "Count";
	
	AdditionalParameters = AccountingForTraceableGoodsClientServerLocalization.CompleteDescriptionOfParametersForSplittingRowInTablePart(
		FormTable.CurrentData);
	
	Notification = New CallbackDescription("SplitRowCompletion", ThisObject, AdditionalParameters);
	ProcessingOfTabularFormsClient.SplitRow(TableData, FormTable, Notification, PartitioningParameters);
	
EndProcedure

&AtClient
Procedure SplitRowCompletion(NewRow, AdditionalParameters) Export
	
	AccountingForTraceableGoodsClientServerLocalization.SplitRowCompletion(NewRow, AdditionalParameters);
	
EndProcedure

&AtClient
Procedure CheckQuantityInTheDocument(Command)
	
	AddressOfTheGoodsInTheTemporaryStorage = PutTablePartOfGoodsInTemporaryStorageToCheckQuantity();
	
	OpeningParameters = New Structure;
	OpeningParameters.Insert("Ref",            Object.Ref);
	OpeningParameters.Insert("TabularSectionName", "Goods");
	
	OpeningParameters.Insert("NotUsePackages", True);
	OpeningParameters.Insert("SeriesSpecificationParameters", SeriesSpecificationParameters);
	
	OpeningParameters.Insert("AddressInTempStorage", AddressOfTheGoodsInTheTemporaryStorage);
	OpeningParameters.Insert("GoodsQuantityExcessIsAllowed", True);
	
	CallbackDescription = New CallbackDescription("CheckQuantityInTheDocumentCompletion", ThisObject);
	
	OpenForm("CommonForm.CheckDocumentPopulation", OpeningParameters, ThisForm, , , , CallbackDescription,
		FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure CheckQuantityInTheDocumentCompletion(Result, AdditionalParameters) Export
	
	If Result <> Undefined Then
		Modified   = True;
		CachedValues = ?(CachedValues = Undefined,
								BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues(),
								CachedValues);
		
		ChangeTablePartBasedOnResultsOfCheck(Result, CachedValues);
	EndIf;
	
EndProcedure

&AtClient
Procedure OpenSelection(Command)
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.TimeMeasurement(
		"Document.MisgradingOfGoodsAtCustodian.DocumentForm.Command.OpenSelection");
	
	If Not ValueIsFilled(Object.Currency) Then
		
		ClearMessages();
		
		MessageText = NStr("vi = 'Chưa điền trường ""Tiền tệ""';
							|ru = 'Поле ""Валюта"" не заполнено';
							|en = '""Currency"" is required'; fa = '""Currency"" is required';
							|it = 'Il campo ""Valuta"" non è compilato';
							|pl = 'Pole ""Waluta"" nie jest wypełnione';
							|tr = '""Para Birimi"" alanı doldurulmadı'");
		CommonClient.MessageToUser(MessageText, Object.Ref, "Object.Currency");
		
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
		HeaderParameter_ = StrReplace(HeaderParameter_, "%Document%", NStr("vi = 'chuyển tồn hàng hóa tại nơi cất giữ';
																			|ru = 'пересортицу товаров у хранителя';
																			|en = 'stock reclass at custodian'; fa = 'stock reclass at custodian';
																			|it = 'riclassificazione articoli presso il magazzino';
																			|pl = 'przeklasyfikowanie towarów u opiekuna';
																			|tr = 'VMI stoku yeniden sınıflandırma'"));
	EndIf;
	
	FilterByProductType = New FixedArray(ProductsClientServer.SelectionByProductMultiTurnContainer());
	
	FormParameters = New Structure;
	FormParameters.Insert("Document",    Object.Ref);
	FormParameters.Insert("Title",   HeaderParameter_);
	FormParameters.Insert("Date",        Object.Date);
	FormParameters.Insert("Organization", Object.Organization);
	FormParameters.Insert("Currency",      Object.Currency);
	
	FormParameters.Insert("FilterByProductType", FilterByProductType);
	FormParameters.Insert("SeriesSpecificationParameters",  SeriesSpecificationParameters);
	
	FormParameters.Insert("HideManualDiscounts",    True);
	
	FormParameters.Insert("LineOfBusiness", Object.LineOfBusiness);
	FormParameters.Insert("PriceIncludesVAT",         False);
	If Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.MisgradingOfGoodsAtToller") Then
		FormParameters.Insert("UseAdvancedFeaturesOfSalesOrder", True);
	EndIf;
	OpenForm("DataProcessor.SelectGoodsToSalesDocument.Form", FormParameters, ThisForm, UUID);
	
EndProcedure

&AtClient
Procedure SelectTransferredGoods(Command)
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.TimeMeasurement(
		"Document.MisgradingOfGoodsAtCustodian.DocumentForm.Command.SelectTransferredGoods");
	
	Cancel = False;
	
	ClearMessages();
	
	If Not ValueIsFilled(Object.Partner) Then
		ErrorText = StrTemplate(NStr("vi = 'Chưa điền trường ""%1""';
									|ru = 'Поле ""%1"" не заполнено';
									|en = 'Field %1 is required'; fa = 'Field %1 is required';
									|it = 'Il campo ""%1"" non è compilato';
									|pl = 'Pole ""%1"" nie jest wypełnione';
									|tr = '""%1"" alanı doldurulmamış'"), Items.Partner.Title);
		
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
		ErrorText = NStr("vi = 'Trường ""Hợp đồng"" chưa điền';
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
		"Document.MisgradingOfGoodsAtCustodian.DocumentForm.Command.SelectTransferredGoods");
	
	HeaderOfSubmittedProductSelectionForm = NStr("vi = 'Chọn hàng hóa vào %Document%';
												|ru = 'Подбор товаров в %Document%';
												|en = 'Pick goods in %Document%'; fa = 'Pick goods in %Document%';
												|it = 'Selezione merci in %Document%';
												|pl = 'Wybór towarów w %Document%';
												|tr = '%Document% içindeki ürünlerin seçimi'");
	
	If ValueIsFilled(Object.Ref) Then
		HeaderOfSubmittedProductSelectionForm =
			StrReplace(HeaderOfSubmittedProductSelectionForm, "%Document%", Object.Ref);
	Else
		HeaderOfSubmittedProductSelectionForm =
			StrReplace(HeaderOfSubmittedProductSelectionForm, "%Document%", NStr("vi = 'chuyển tồn hàng hóa tại nơi cất giữ';
																				|ru = 'пересортицу товаров у хранителя';
																				|en = 'stock reclass at custodian'; fa = 'stock reclass at custodian';
																				|it = 'riclassificazione articoli presso il magazzino';
																				|pl = 'przeklasyfikowanie towarów u opiekuna';
																				|tr = 'VMI stoku yeniden sınıflandırma'"));
	EndIf;
	
	AddressOfGoods = PlaceGoodsInStorageForSelectionOfTransferredGoods();
	
	FormParameters = New Structure;
	FormParameters.Insert("Ref",                Object.Ref);
	FormParameters.Insert("Owner",              Object.Partner);
	FormParameters.Insert("Organization",           Object.Organization);
	FormParameters.Insert("Contract",               Object.Contract);
	FormParameters.Insert("BusinessOperation", Object.BusinessOperation);
	FormParameters.Insert("Title",             HeaderOfSubmittedProductSelectionForm);
	FormParameters.Insert("AddressOfGoodsInvoiceInVault", AddressOfGoods);
	FormParameters.Insert("CollapseGTDNumbers",     True);
	
	OpenForm("DataProcessor.SelectGoodsTransferredToCustody.Form.Form", FormParameters, ThisObject,
		UUID);
	
EndProcedure

&AtClient
Procedure FillInPricesByPriceKind(Command)
	
 	ClearMessages();
 	
	If Object.Goods.Count() = 0 Then
		MessageText = NStr("vi = 'Trong chứng từ chưa điền bảng ""Hàng hóa"". Không thể điền đơn giá';
							|ru = 'В документе не заполнена таблица ""Товары"". Цены не могут быть заполнены';
							|en = 'The ""Goods"" table in the document is not filled in. Cannot fill in the prices'; fa = 'The ""Goods"" table in the document is not filled in. Cannot fill in the prices';
							|it = 'Nel documento non è compilata la tabella ""Merci"". I prezzi non possono essere compilati';
							|pl = 'W dokumencie nie jest wypełniona tabela ""Wiersze pozycji"". Ceny nie mogą być wypełnione.';
							|tr = 'Belgedeki ""Ürünler"" tablosu doldurulmamıştır. Fiyatlar doldurulamıyor'");
		CommonClient.MessageToUser(MessageText,,"Goods", "Object");		
		Return;
	EndIf;
	
	If ValueIsFilled(Object.PriceKind) Then
		PricesCalculated = FillInPricesByPriceKindServer();
		SalesClient.NotifyAboutEndOfFillingInPricesByTypeOfPrices(PricesCalculated, Object.PriceKind);
	Else
		MessageText = NStr("vi = 'Chưa chỉ ra dạng giá';
							|ru = 'Не указан вид цены';
							|en = 'Price type is not specified'; fa = 'Price type is not specified';
							|it = 'Il tipo di prezzo non è indicato';
							|pl = 'Nie podano rodzaju ceny';
							|tr = 'Fiyat türü belirtilmedi'");
		CommonClient.MessageToUser(MessageText,,"PriceKind", "Object");		
	EndIf;
	
EndProcedure

&AtClient
Procedure FillInPricesByCosts(Command)
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.TimeMeasurement(
		"Document.MisgradingOfGoodsAtCustodian.Form.DocumentForm.Command.FillInPricesByCosts");
	
	ClearMessages();
	
	If Object.Goods.Count() = 0 Then
		MessageText = NStr("vi = 'Trong chứng từ chưa điền bảng ""Hàng hóa"". Không thể điền đơn giá';
							|ru = 'В документе не заполнена таблица ""Товары"". Цены не могут быть заполнены';
							|en = 'The ""Goods"" table in the document is not filled in. Cannot fill in the prices'; fa = 'The ""Goods"" table in the document is not filled in. Cannot fill in the prices';
							|it = 'Nel documento non è compilata la tabella ""Merci"". I prezzi non possono essere compilati';
							|pl = 'W dokumencie nie jest wypełniona tabela ""Wiersze pozycji"". Ceny nie mogą być wypełnione.';
							|tr = 'Belgedeki ""Ürünler"" tablosu doldurulmamıştır. Fiyatlar doldurulamıyor'");
		CommonClient.MessageToUser(MessageText, , "Goods", "Object");		
		Return;
	EndIf;
	
	FillInPricesByCostsServer();
	
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

#EndRegion

#EndRegion

#Region Private

#Region OnChangeAttributes

&AtServer
Procedure DateOnChangeServer()
	
	UseTraceableImportedGoodsAccounting = AccountingForTraceableGoodsLocalization.UseTraceableImportedGoodsAccounting(
														Object.Date);
	
	AccountingForTraceableGoodsLocalization.EstablishVisibilityOfRNPTQuantity(ThisForm, Object.Date);
	
	If Not Items.ProductsGroupQuantityByRNPT.Visible Then
		RecalculateNumberOfRNPT();
	EndIf;
	
EndProcedure

&AtServer
Procedure BusinessOperationOnChangeServer()
	
	Object.Partner    = PredefinedValue("Catalog.Partners.EmptyRef");
	Object.Counterparty = PredefinedValue("Catalog.Counterparties.EmptyRef");
	Object.Terms = PredefinedValue("Catalog.TermsOfSale.EmptyRef");
	
	PartnerOnChangeServer();
	CounterpartyOnChangeServer();
	ContractOnChangeServer();
	
	Handler = Documents.MisgradingOfGoodsAtCustodian.ActionHandler(Object.BusinessOperation);
	
	Handler.AdjustItemSelectionSettings(ThisObject, Object);
	Handler.CustomizeForm(ThisObject, Object.Number, Object.Date);
	
	SeriesSpecificationParameters = SeriesSpecificationParameters();
	ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);
	
	BusinessTransactionBeforeTheChange = Object.BusinessOperation;
	
EndProcedure

&AtServer
Procedure PartnerOnChangeServer()
	
	DirectionsOfActivity = Object.LineOfBusiness;
	
	DocumentSales = FormAttributeToValue("Object");
	DocumentSales.FillInDefaultSalesConditions();
	ValueToFormAttribute(DocumentSales, "Object");
	
	Handler = Documents.MisgradingOfGoodsAtCustodian.ActionHandler(Object.BusinessOperation);
	
	Handler.SetContractAvailability(ThisObject, Object, Object.Contract);
	
	FillInServiceDetailsForProductRange();
	
	If UseLinesOfBusiness Then
		LinesOfBusinessServer.FillInDefaultDirection(Object.LineOfBusiness, Object.Terms,
			Object.Contract);
		SetLBEditingOption();
	EndIf;
	
	If DirectionsOfActivity <> Object.LineOfBusiness Then
		LinesOfBusinessServer.WhenChangingDirectionOfActivity(ThisObject);
		ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);
		AssignmentsServer.FillInDestinationTypeInTable(Object.Goods,, FillingParametersByDestinationType());
	EndIf;
	
	ResponsiblePersonsServer.WhenChangingRelatedDocumentDetails(Object);
	
EndProcedure

&AtServer
Procedure CounterpartyOnChangeServer()
	
	DirectionsOfActivity = Object.LineOfBusiness;
	
	If ValueIsFilled(Object.Counterparty) Then
		FillInDefaultContract();
	EndIf;
	
	Handler = Documents.MisgradingOfGoodsAtCustodian.ActionHandler(Object.BusinessOperation);
	
	Handler.SetContractAvailability(ThisObject, Object, Object.Contract);
	
	If UseLinesOfBusiness Then
		SetLBEditingOption();
	EndIf;
	
	If DirectionsOfActivity <> Object.LineOfBusiness Then
		LinesOfBusinessServer.WhenChangingDirectionOfActivity(ThisObject);
		ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);
		AssignmentsServer.FillInDestinationTypeInTable(Object.Goods,, FillingParametersByDestinationType());
	EndIf;
	
EndProcedure

&AtServer
Procedure TermsOnChangeServer()
	
	DirectionsOfActivity = Object.LineOfBusiness;
	
	DocumentSales = FormAttributeToValue("Object");
	DocumentSales.FillInTermsOfSalesUnderAgreement();
	ValueToFormAttribute(DocumentSales, "Object");
	
	Handler = Documents.MisgradingOfGoodsAtCustodian.ActionHandler(Object.BusinessOperation);
	
	Handler.SetContractAvailability(ThisObject, Object, Object.Contract);
	
	If Contract <> Object.Contract Then
		Contract = Object.Contract;
	EndIf;
	
	FillInServiceDetailsForProductRange();
	
	If UseLinesOfBusiness Then
		SetLBEditingOption();
	EndIf;
	
	If DirectionsOfActivity <> Object.LineOfBusiness Then
		LinesOfBusinessServer.WhenChangingDirectionOfActivity(ThisObject);
		ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);
		AssignmentsServer.FillInDestinationTypeInTable(Object.Goods,, FillingParametersByDestinationType());
	EndIf;
	
	ResponsiblePersonsServer.WhenChangingRelatedDocumentDetails(Object);
	
EndProcedure

&AtServer
Procedure OrganizationOnChangeServer()
	
	DirectionsOfActivity = Object.LineOfBusiness;
	
	If ValueIsFilled(Object.Organization) Then
		FillInDefaultContract();
		
		If UseLinesOfBusiness Then
			LinesOfBusinessServer.FillInDefaultDirection(Object.LineOfBusiness, Object.Terms,
				Object.Contract);
		EndIf;
	EndIf;
	
	Handler = Documents.MisgradingOfGoodsAtCustodian.ActionHandler(Object.BusinessOperation);
	
	Handler.SetContractAvailability(ThisObject, Object, Object.Contract);
	
	FillInSubordinatePropertiesForStatistics("Organization");
	
	If UseLinesOfBusiness Then
		SetLBEditingOption();
	EndIf;
	
	If DirectionsOfActivity <> Object.LineOfBusiness Then
		LinesOfBusinessServer.WhenChangingDirectionOfActivity(ThisObject);
		ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);
		AssignmentsServer.FillInDestinationTypeInTable(Object.Goods,, FillingParametersByDestinationType());
	EndIf;
	
	RecalculateNumberOfRNPT();
	
	ResponsiblePersonsServer.WhenChangingRelatedDocumentDetails(Object);
	
EndProcedure

&AtServer
Procedure ContractOnChangeServer()
	
	Contract = Object.Contract;
	
	ContractDetails_ = New Structure("Currency, LineOfBusiness, Department", "ARAPCurrency");
	Catalogs.CounterpartyContracts.FillInDocumentDetails(Object, Object.Contract, ContractDetails_);
	
	If UseLinesOfBusiness Then
		LinesOfBusinessServer.FillInDefaultDirection(Object.LineOfBusiness, Object.Terms,
			Object.Contract);
		SetLBEditingOption();
		ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);
	EndIf;
	
	RecalculateNumberOfRNPT();
	
EndProcedure

&AtServer
Procedure LineOfBusinessOnChangeServer()
	
	LinesOfBusinessServer.WhenChangingDirectionOfActivity(ThisObject);
	ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);
	AssignmentsServer.FillInDestinationTypeInTable(Object.Goods,, FillingParametersByDestinationType());
EndProcedure

&AtServer
Procedure CurrencyOnChangeServer()
	
	DocumentDate = ?(ValueIsFilled(Object.Date), Object.Date, CurrentSessionDate());
	
	BaseCurrency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Object.Organization);
	StructureOfOldCurrencyRates = ProcessingOfExchangeRatesTM.GetCurrencyRate(DocumentCurrency, DocumentDate, BaseCurrency);
	StructureOfNewCurrencyRates  = ProcessingOfExchangeRatesTM.GetCurrencyRate(Object.Currency,   DocumentDate, BaseCurrency);
	
	PriceManagementSystem.ConvertAmountsToCurrencyProducts(
		Object, DocumentCurrency, Object.Currency, StructureOfOldCurrencyRates, StructureOfNewCurrencyRates, False);
	
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
Procedure Attachable_CloseForm()

	If IsOpen() Then
		Close();
	EndIf;
	
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
	
	Columns = "Products,Characteristic,Count";
	
	TableOfGoods = ProcessingOfTabularForms.RowsFromClipboard(FilterParameters, Columns);
	
	If Not ValueIsFilled(TableOfGoods) Then
		Return;
	EndIf;
	
	StructureOfActions    = New Structure;
	LinesOfBusinessClientServer.StructureOfInsertActionsWhenAddingRow(ThisObject, StructureOfActions);
	StructureOfActions.Insert("FillInDestinationType", FillingParametersByDestinationType());
	RowsToProcess = New Array;
	
	For Each RowOfProduct In TableOfGoods Do
		CurrentRow = Object.Goods.Add();
		FillPropertyValues(CurrentRow, RowOfProduct);
		RowsToProcess.Add(CurrentRow);
	EndDo;
	
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		RowsToProcess,
		StructureOfActions,
		Object.Goods);
			
	FillInServiceDetailsForProductRange();
	ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);
	
EndProcedure

#EndRegion

#Region InventoryKinds

&AtServer
Procedure GetStockTypesFromStorage(ValueSelected)
	
	InventoriesServer.ProcessInputOfInventoryTypesManually(ValueSelected, ThisForm);
	
EndProcedure

&AtServer
Function PutGoodsAndStockTypesInStorage()
	
	Return InventoriesServer.PutGoodsAndStockTypesInStorage(ThisObject);
	
EndFunction

#EndRegion

#Region SelectionAndProcessingOfQuantityVerification

&AtServer
Procedure ProcessingSelectionOfSelectionOnServer(ValueSelected)
	
	TableOfGoods = GetFromTempStorage(ValueSelected.GoodsAddressInStorage);
	
	For Each RowOfProduct In TableOfGoods Do
		CurrentRow = Object.Goods.Add();
		FillPropertyValues(CurrentRow, RowOfProduct);
	EndDo;
	
	FillInServiceDetailsForProductRange();
	
EndProcedure

&AtServer
Procedure ProcessingOfSelectionSelectionOfTransferredGoodsOnServer(ValueSelected)
	
	TableOfGoods = GetFromTempStorage(ValueSelected.GoodsAddressInStorage);
	NewLines = New Array;
	For Each RowOfProduct In TableOfGoods Do
		
		ProductsSearch = New Structure();
		ProductsSearch.Insert("Products", RowOfProduct.Products);
		ProductsSearch.Insert("Characteristic", RowOfProduct.Characteristic);
		ProductsSearch.Insert("Purpose", RowOfProduct.Purpose);
		ProductsSearch.Insert("Series", RowOfProduct.Series);
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
		
	EndDo;
	
	FillInServiceDetailsForProductRange();
	ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);
	AssignmentsServer.FillInDestinationTypeInTable(Object.Goods, NewLines, FillingParametersByDestinationType());
EndProcedure

&AtServer
Function PlaceGoodsInStorageForSelectionOfTransferredGoods()
	
	Address = PutToTempStorage(
		Object.Goods.Unload(,"LineNumber, Products, Characteristic, Purpose, Series, Count"),
		UUID);
	
	Return Address;
	
EndFunction

&AtServer
Function PutTablePartOfGoodsInTemporaryStorageToCheckQuantity()
	
	GroupColumns = "Products, ItemsType, Characteristic, ItemVariantsAreUsed, Series, 
						|BatchesIndicationStatus";
	
	UnloadedColumns = GroupColumns + ", Count";
	
	TabularPartProducts = Object.Goods.Unload(, UnloadedColumns);
	TabularPartProducts.GroupBy(GroupColumns, "Count");
	TabularPartProducts.Columns.Add("NumberOfPackages");
	
	For Each TSRow In TabularPartProducts Do
		TSRow.NumberOfPackages = TSRow.Count;
	EndDo;
	
	AddressInTempStorage = PutToTempStorage(TabularPartProducts, UUID);
	
	Return AddressInTempStorage;
	
EndFunction

&AtServer
Procedure ChangeTablePartBasedOnResultsOfCheck(ReturnParameters, CachedValues)
	
	GoodsTable		= GetFromTempStorage(ReturnParameters.Goods);
	LinesToDelete		= New Array;
	ReadyForProcessing_	= New Array;
	
	SelectionColumns = "Products, Characteristic, Series, BatchesIndicationStatus";
	
	For Each SourceRow In GoodsTable Do
		
		Filter = New Structure(SelectionColumns);
		FillPropertyValues(Filter, SourceRow);
		
		FoundRows = Object.Goods.FindRows(Filter);
		
		For Each TSRow In FoundRows Do
			
			If SourceRow.NumberOfPackages = 0 Then
				Break;
			EndIf;
			
			If TSRow.Count = 0
				And SourceRow.NumberOfPackages < 0 Then
				
				Continue;
				
			EndIf;
			
			If SourceRow.NumberOfPackages >= 0 Then
				
				TSRow.Count       = TSRow.Count + SourceRow.NumberOfPackages;
				SourceRow.NumberOfPackages = 0;
				
			Else
				
				QuantityToWriteOff = -SourceRow.NumberOfPackages;
				QuantityPerLine   = TSRow.Count;
				
				If QuantityToWriteOff > QuantityPerLine Then
					SourceRow.NumberOfPackages = QuantityPerLine - QuantityToWriteOff;
					TSRow.Count               = 0;
				Else
					SourceRow.NumberOfPackages = 0;
					TSRow.Count               = QuantityPerLine - QuantityToWriteOff;
				EndIf;
				
			EndIf;
			
			If TSRow.Count = 0 Then
				LinesToDelete.Add(TSRow);
			Else
				ReadyForProcessing_.Add(TSRow);
			EndIf;
			
		EndDo;
		
		If FoundRows.Count() = 0 Then
			TSRow = Object.Goods.Add();
			FillPropertyValues(TSRow, SourceRow);
			
			TSRow.Count = SourceRow.NumberOfPackages;
			
			ReadyForProcessing_.Add(TSRow);
		EndIf;
		
	EndDo;
	
	For Each TSRow In LinesToDelete Do
		Object.Goods.Delete(TSRow);
	EndDo;
	
	FillInServiceDetailsForProductRange();
	RecalculateNumberOfRNPT(ReadyForProcessing_);
	
EndProcedure

#EndRegion

#Region PriceManagementSystem

&AtServer
Function FillInPricesByPriceKindServer()
	
	ColumnsByValue = New Structure;
	ColumnsByValue.Insert("Package", Catalogs.PackagesAndUnitsOfMeasure.EmptyRef());
	
	OtherColumnNames = New Structure;
	OtherColumnNames.Insert("ProductsRecordingAsReceived",   "Products");
	OtherColumnNames.Insert("CharacteristicRecordingAsReceived", "Characteristic");
	
	FillParameters = New Structure;
	FillParameters.Insert("Date",               Object.Date);
	FillParameters.Insert("Organization",        Object.Organization);
	FillParameters.Insert("Currency",             Object.Currency);
	FillParameters.Insert("PriceKind",            Object.PriceKind);
	FillParameters.Insert("ColumnsByValue",  ColumnsByValue);
	FillParameters.Insert("OtherColumnNames", OtherColumnNames);
	
	Return EnterprisePricesFillingServer.FillInPrices(Object.Goods,, FillParameters);
	
EndFunction

&AtServer
Function FillInPricesByCostsServer()
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	InventoryCostCalculation.PreliminaryCalculation AS PreliminaryCalculation
	|FROM
	|	Document.InventoryCostCalculation AS InventoryCostCalculation
	|		LEFT JOIN Document.InventoryCostCalculation.Companies AS InventoryCostCalculationCompanies
	|		ON InventoryCostCalculation.Ref = InventoryCostCalculationCompanies.Ref
	|WHERE
	|	InventoryCostCalculation.Posted
	|	AND InventoryCostCalculation.Date BETWEEN BEGINOFPERIOD(&Date, MONTH) AND ENDOFPERIOD(&Date, MONTH)
	|	AND InventoryCostCalculation.EntryType = VALUE(Enum.LotRecordTypes.EmptyRef)
	|	AND InventoryCostCalculationCompanies.Organization = &Organization";
	
	Query.SetParameter("Date",        Object.Date);
	Query.SetParameter("Organization", Object.Organization);
	
	Selection = Query.Execute().Select();
	If Selection.Next() Then
		PreliminaryCalculation = Selection.PreliminaryCalculation;
	Else 
		MessageText = StrTemplate(NStr("vi = 'Không thể điền đơn giá theo giá vốn trong chứng từ %1: trong %2 chưa tính giá vốn.';
										|ru = 'Не удалось заполнить цены по себестоимости в документе %1: на %2 не произведен расчет себестоимости.';
										|en = 'Cannot fill in prices by cost in document %1: cost is not calculated for %2.'; fa = 'Cannot fill in prices by cost in document %1: cost is not calculated for %2.';
										|it = 'Impossibile compilare i prezzi al costo di produzione per il documento %1: al %2 non è stato calcolato il costo di produzione.';
										|pl = 'Nie udało się wypełnić cen według kosztu własnego w dokumencie %1: na %2 nie wykonano obliczenia kosztu własnego.';
										|tr = '%1 belgesinde maliyet fiyatları doldurulamadı: %2''da maliyet hesaplaması yapılmadı.'"), Object.Ref, Format(BegOfMonth(Object.Date),"DLF=DD"));
		Common.MessageToUser(MessageText);
		Return False;
	EndIf;
	
	OtherColumnNames = New Structure;
	OtherColumnNames.Insert("ProductsRecordingAsReceived",   "Products");
	OtherColumnNames.Insert("CharacteristicRecordingAsReceived", "Characteristic");
	
	FillParameters = New Structure;
	FillParameters.Insert("Date",                  Object.Date);
	FillParameters.Insert("Organization",           Object.Organization);
	FillParameters.Insert("Currency",                Object.Currency);
	FillParameters.Insert("Warehouse",                 Object.Contract);
	FillParameters.Insert("PreliminaryCalculation", PreliminaryCalculation);
	FillParameters.Insert("OtherColumnNames",    OtherColumnNames);
	FillParameters.Insert("PopulationFields",        "Price, PriceOffBalance");
	
	Return SalesServer.FillInPricesByCosts(Object.Goods, Undefined, FillParameters);
	
EndFunction

&AtClientAtServerNoContext
Procedure ClearPrices(Form)
	
	Goods = Form.Object.Goods;
	
	For Each TableRow In Goods Do
		TableRow.Price         = 0;
		TableRow.PriceOffBalance = 0;
	EndDo;
	
EndProcedure

#EndRegion

#Region SetOfSeries

&AtServer
Function SeriesSpecificationParameters()
	
	ObjectManager = Documents.MisgradingOfGoodsAtCustodian;
	
	Return New FixedStructure(ProductsServer.SeriesSpecificationParameters(Object, ObjectManager));
	
EndFunction

&AtClient
Procedure OpenSelectionOfSeries(ThisIsSeriesOfLogging, Text = "")
	
	EditingRegistrationSeries = ThisIsSeriesOfLogging;
	
	Suffix = ?(ThisIsSeriesOfLogging, "RecordingAsReceived", "");
	
	AttributesNames = New Array;
	AttributesNames.Add("Products");
	AttributesNames.Add("Characteristic");
	AttributesNames.Add("ItemVariantsAreUsed");
	AttributesNames.Add("Series");
	AttributesNames.Add("BatchesIndicationStatus");
	
	CurrentData = Items.Goods.CurrentData;
	
	CurrentRow = New Structure;
	CurrentRow.Insert("Count",                 CurrentData.Count);
	CurrentRow.Insert("CurrentRowID", CurrentData.GetID());
	
	For Each AttributeName In AttributesNames Do
		CurrentRow.Insert(AttributeName, CurrentData[AttributeName + Suffix]);
	EndDo;
	
	If ProductsClient.YouNeedServerCallToSpecifySeries(ThisForm, SeriesSpecificationParameters, Text, CurrentRow)Then
		ExceptionText = NStr("vi = 'Lỗi khi thử chỉ ra sê-ri - để chỉ ra sê-ri trong chứng từ này, không cần gọi ra Server.';
							|ru = 'Ошибка при попытке указать серии - в этом документе для указания серий не нужен серверный вызов.';
							|en = 'An error occurred when attempting to specify batch. No server call is required to specify batch in this document.'; fa = 'An error occurred when attempting to specify batch. No server call is required to specify batch in this document.';
							|it = 'Si è verificato un errore durante il tentativo di indicare le serie - in questo documento non è necessaria la chiamata al server per indicare le serie.';
							|pl = 'Błąd podczas próby określenia serii - w tym dokumencie nie jest wymagane wywołanie serwera, aby wskazać serię.';
							|tr = 'Bir parti belirtmeye çalışırken hata oluştu - bu belgede bir parti belirtmek için sunucu çağrısı gerekmez.'");
		Raise ExceptionText;
	EndIf;
	
EndProcedure

&AtServer
Procedure FillInStatusesOfSpecifyingSeriesWhenEditingLineTS(IDCurrentRow, CachedValues)
	
	ProductsServer.FillInStatusesOfSpecifyingSeriesWhenEditingLineTS(
		Object, SeriesSpecificationParameters, IDCurrentRow, CachedValues);
	
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
	
	Goods = Object.Goods;
	
	CurrentRow = Goods.FindByID(RowID);
	
	If CurrentRow = Undefined Then
		Return;
	EndIf;
	
	CCDNumbersFilledIn = True;
	
	CurrentRow.CCDNumber = SelectionData_1.MainNumberOfCCD;
	
	AttributesNames = "CCDNumberType, OriginCountry";
	AttributesOfCCD	= Common.ObjectAttributesValues(CurrentRow.CCDNumber, AttributesNames);
	
	FillPropertyValues(CurrentRow, AttributesOfCCD);
	
	FillParameters = PurchasesServer.ParametersForFillingInGTDVNumberOfTabularPart();
	FillParameters.FieldNameNumberOfPackages = "Count";
	
	Actions = New Structure;
	AccountingForTraceableGoodsClientServerLocalization.AddDescriptionOfSettingsForRecalculatingDetailsOfTablePart(
		Object,
		Actions,
		"Contract");
	
	If SelectionData_1.ResidualNumberOfCCD <> Undefined Then
		NewRow = Goods.Insert(Goods.IndexOf(CurrentRow) + 1);
		FillPropertyValues(NewRow, CurrentRow);
		
		NewRow.CCDNumber = SelectionData_1.ResidualNumberOfCCD;
		
		BatchProcessingOfTablePartClientServer.RecalculateNumberOfPackagesWhenSelectingCCDNumber(
			CurrentRow,
			NewRow,
			FillParameters.FieldNameNumberOfPackages);
		
		CurrentData = DescriptionOfTablePartRow(NewRow);
		CurrentData.Products = NewRow.ProductsRecordingAsReceived;
		CurrentData.Characteristic = NewRow.CharacteristicRecordingAsReceived;
		
		BatchProcessingOfTablePartServer.ProcessTSString(CurrentData, Actions, Undefined);
		
		NewRow.QuantityByGBRN = CurrentData.QuantityByGBRN;
		
		Items.Goods.CurrentRow = NewRow.GetID();
	EndIf;
	
	CurrentData = DescriptionOfTablePartRow(CurrentRow);
	CurrentData.Products = CurrentRow.ProductsRecordingAsReceived;
	CurrentData.Characteristic = CurrentRow.CharacteristicRecordingAsReceived;
	
	BatchProcessingOfTablePartServer.ProcessTSString(CurrentData, Actions, Undefined);
	
	CurrentRow.QuantityByGBRN = CurrentData.QuantityByGBRN;
	
EndProcedure

&AtServer
Procedure FillInCCDNumbersOnServer(Val CCDNumber, CCDNumbersFilledIn)
	
	FillParameters = PurchasesServer.ParametersForFillingInGTDVNumberOfTabularPart();
	FillParameters.NameOfProductsField = "ProductsRecordingAsReceived";
	FillParameters.FieldNameNumberOfPackages = "Count";
	
	PurchasesServer.FillInGTNumbersInTabularPart(
		Object.Goods,
		CCDNumber,
		Items.Goods.SelectedRows,
		CCDNumbersFilledIn,
		FillParameters);
	
EndProcedure

#EndRegion

#Region Other

&AtServer
Procedure SetConditionalAppearance()
	
	ConditionalAppearance.Items.Clear();
	
	//
	ProductsServer.EstablishConditionalAppearanceOfProductCharacteristics(ThisForm);
	ProductsServer.EstablishConditionalAppearanceOfProductCharacteristics(
		ThisForm, "GoodsCharacteristicRecordingAsReceived", "Object.Goods.ItemVariantsAreUsedRecordingAsReceived");
	
	//
	ProductsServer.SetConditionalAppearanceOfProductAssignment(ThisForm);
	ProductsServer.SetConditionalAppearanceOfProductAssignment(
		ThisForm, "GoodsAssignmentGoodsReceipt", "Object.Goods.ItemTypePosting");
	
	//
	ProductsServer.EstablishConditionalAppearanceOfProductSeries(ThisForm, "SeriesAlwaysWHGoods");
	ProductsServer.EstablishConditionalAppearanceOfProductSeries(
		ThisForm,
		"SeriesAlwaysWHGoods",
		"GoodsBatchReceipt",
		"Object.Goods.BatchesIndicationStatusReceipt",
		"Object.Goods.ItemTypePosting");
	
	//
	ProductsServer.SetConditionalAppearanceOfStatusIndicationSeries(ThisForm, True);
	ProductsServer.SetConditionalAppearanceOfStatusIndicationSeries(
		ThisForm, True, "GoodsBatchesIndicationStatusReceipt", "Object.Goods.BatchesIndicationStatusReceipt");
	
	// Setting the conditional design for the 'Price' element
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ProductsPriceRegistration.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ProductsPriceRegistrationOffBalance.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.ReceiveGoodsAtCostTheyWereIssuedFromWarehouse");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	Item.Appearance.SetParameterValue("TextColor", StyleColors.TextColorOfCanceledRowOfDocument);
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<ghi tăng theo giá vốn>';
													|ru = '<приходуется по себестоимости>';
													|en = '<recorded as received at cost>'; fa = '<recorded as received at cost>';
													|it = '<viene registrato in contabilità al costo di produzione>';
													|pl = '<przyjęcie według kosztu własnego>';
													|tr = '<maliyet üzerinden tüketilir>'"));
	Item.Appearance.SetParameterValue("ReadOnly", True);
	
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
	
	// Setting the conditional design for the 'Division' element
	InventoriesServer.EstablishConditionalAppearanceOfDivisionForTypesOfStocks(ThisForm);
	
	// Setting the conditional design for the 'Activity Direction' element
	LinesOfBusinessServer.EstablishConditionalAppearanceOfDirectionOfActivity(ThisForm);
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsAssignmentGoodsReceipt.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue  = New DataCompositionField("Object.Goods.AssignmentType");
	ItemFilter.ComparisonType   = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.AssignmentTypes.Giveaway2_5;

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue  = New DataCompositionField("Object.Goods.AssignmentGoodsReceipt");
	ItemFilter.ComparisonType   = DataCompositionComparisonType.NotFilled;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue  = New DataCompositionField("Object.Goods.ProductsRecordingAsReceived");
	ItemFilter.ComparisonType   = DataCompositionComparisonType.Filled;
	
	Item.Appearance.SetParameterValue("MarkIncomplete", True);
EndProcedure

&AtServer
Procedure SetLBEditingOption()
	
	LBAvailabilityParameters = LinesOfBusinessServer.ParametersLBEditingCapability();
	
	LBAvailabilityParameters.Contract           = Object.Contract;
	LBAvailabilityParameters.ARAPObjectSettings   = Common.ObjectAttributeValue(Object.Contract, "ARAPObjectSettings");
	
	LinesOfBusinessServer.SetLBEditingOption(ThisObject, LBAvailabilityParameters);
	
EndProcedure

&AtServer
Procedure OnReadCreateAtServer()
	
	Documents.MisgradingOfGoodsAtCustodian.ConfigureBusinessTransactionDetails(ThisObject, Object);
	
	RestrictGoodsReceiptWithoutCCDNumbers = GetFunctionalOption("RestrictGoodsReceiptWithoutCCDNumbers");
	UseLinesOfBusiness      = GetFunctionalOption("UseIncomeAccountingByLinesOfBusiness");
	UseTraceableImportedGoodsAccounting = AccountingForTraceableGoodsLocalization.UseTraceableImportedGoodsAccounting(
														Object.Date);
	
	Handler = Documents.MisgradingOfGoodsAtCustodian.ActionHandler(Object.BusinessOperation);
	
	Handler.SetContractAvailability(ThisObject, Object);
	
	Handler.AdjustItemSelectionSettings(ThisObject, Object);	
	Handler.CustomizeForm(ThisObject, Object.Number, Object.Date);
	
	Items.CounterpartyGroup.Visible = Not GetFunctionalOption("UsePartnersAsCounterparties");
	
	SeriesSpecificationParameters = SeriesSpecificationParameters();
	
	DocumentCurrency                  = Object.Currency;
	BusinessTransactionBeforeTheChange = Object.BusinessOperation;
	
	FillInServiceDetailsForProductRange();
	AssignmentsServer.FillInDestinationTypeInTable(Object.Goods);
	SetAvailabilityViewPrices(ThisObject);
	SetSettingsForFormattingArticleFields(ThisObject);
	If UseLinesOfBusiness Then
		SetLBEditingOption();
	EndIf;
	
	LinesOfBusinessServer.OnReadCreateAtServer(ThisObject);
	
EndProcedure

&AtServer
Procedure FillInAccordingToDataInRepository()
	
	If Not IsTempStorageURL(Parameters.AddressOfTheDataInTheStorage) Then
		Return;
	EndIf;
	
	StructureOfData = GetFromTempStorage(Parameters.AddressOfTheDataInTheStorage);
	
	Object.Date = StructureOfData.Header.Date;
	
	DocumentObject = FormAttributeToValue("Object");
	DocumentObject.Fill(Undefined);
	ValueToFormAttribute(DocumentObject, "Object");
	
	FillPropertyValues(Object, StructureOfData.Header);
	
	For Each RowOfTables In StructureOfData.GoodsTable Do
		NewRow = Object.Goods.Add();
		FillPropertyValues(NewRow, RowOfTables);
	EndDo;
	
	If ValueIsFilled(Object.Ref) Then
		FillInServiceDetailsForProductRange();
		ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);
	EndIf;
	
	RecalculateNumberOfRNPT();
	
EndProcedure

&AtServer
Procedure FillInServiceDetailsForProductRange()
	
	FillInArticleAttribute = New Structure;
	FillInArticleAttribute.Insert("Products",              "SKU");
	FillInArticleAttribute.Insert("ProductsRecordingAsReceived", "SKURegistration");
	
	FillInProductTypeAttribute_ = New Structure;
	FillInProductTypeAttribute_.Insert("Products",              "ItemsType");
	FillInProductTypeAttribute_.Insert("ProductsRecordingAsReceived", "ItemTypePosting");
	
	FillInFeatureAttribute = New Structure;
	FillInFeatureAttribute.Insert("Products",              "ItemVariantsAreUsed");
	FillInFeatureAttribute.Insert("ProductsRecordingAsReceived", "ItemVariantsAreUsedRecordingAsReceived");
	
	FillInCCDTrackingAttribute = New Structure;
	FillInCCDTrackingAttribute.Insert("ProductsRecordingAsReceived", "TheRecordsAreKeptByCCD");
	
	ParametersForFillingInBankingDetails = New Structure;
	ParametersForFillingInBankingDetails.Insert("FillInArticleAttribute",         FillInArticleAttribute);
	ParametersForFillingInBankingDetails.Insert("FillInProductTypeAttribute_", FillInProductTypeAttribute_);
	ParametersForFillingInBankingDetails.Insert(
		"FillInFeatureAttribute", FillInFeatureAttribute);
	ParametersForFillingInBankingDetails.Insert("FillInCCDTrackingAttribute", FillInCCDTrackingAttribute);
	
	AccountingForTraceableGoodsClientServerLocalization.CompleteDescriptionOfSettingsForFillingInServiceDetailsOfTablePart(
		ParametersForFillingInBankingDetails, New Structure("ProductsRecordingAsReceived", "AccountingForTheRNPTIsMaintained"));
	
	ProductsServer.FillInServiceDetailsForProductInCollection(Object.Goods, ParametersForFillingInBankingDetails);
	
	FillParameters = PurchasesServer.ParametersForFillingInServiceAttributesOfCCDNumber();
	FillParameters.NameOfProductsField = "ProductsRecordingAsReceived";
	
	PurchasesServer.FillInServiceAttributesOfCCDNumber(Object.Goods, FillParameters);
	
EndProcedure

&AtServer
Procedure FillInSubordinatePropertiesForStatistics(ParentPropsName)
	
	ObjectsFillingByStatistics.FillInSubordinateDetailsOfObject(Object, ParentPropsName);
	
EndProcedure

&AtServer
Procedure FillInDefaultContract()
	
	Contract = Object.Contract;
	
	Handler = Documents.MisgradingOfGoodsAtCustodian.ActionHandler(Object.BusinessOperation);
	DefaultContract = Handler.GetDefaultContract(Object);
	
	If Contract <> DefaultContract Then
		Contract        = DefaultContract;
		Object.Contract = DefaultContract;
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Procedure SetAvailabilityViewPrices(Form)
	
	Object   = Form.Object;
	Items = Form.Items;
	
	Items.FillInPrices.Enabled = Not Object.ReceiveGoodsAtCostTheyWereIssuedFromWarehouse;
	Items.PriceKind.Enabled       = Not Object.ReceiveGoodsAtCostTheyWereIssuedFromWarehouse;
	
EndProcedure

&AtClientAtServerNoContext
Procedure SetSettingsForFormattingArticleFields(Form)
	
	Object   = Form.Object;
	Items = Form.Items;
	
	Items.ExpenseItem.AutoMarkIncomplete	= Not Object.ReceiveGoodsAtCostTheyWereIssuedFromWarehouse;
	Items.ExpenseItem.MarkIncomplete		= Not Object.ReceiveGoodsAtCostTheyWereIssuedFromWarehouse;
	
	Items.IncomeItem.AutoMarkIncomplete	= Not Object.ReceiveGoodsAtCostTheyWereIssuedFromWarehouse;
	Items.IncomeItem.MarkIncomplete		= Not Object.ReceiveGoodsAtCostTheyWereIssuedFromWarehouse;
	
EndProcedure

&AtServer
Procedure GoodsAfterDeleteRowServer(SeriesStatusesNeedToBeUpdated, CachedValues)
	
	If SeriesStatusesNeedToBeUpdated Then
		FillInStatusesOfSpecifyingSeriesWhenEditingLineTS(Undefined, CachedValues);
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Function DescriptionOfTablePartRow(CurrentRow = Undefined)
	
	Keys = "Products, Characteristic, Purpose, Series, BatchesIndicationStatus, ProductsRecordingAsReceived, 
		|CharacteristicRecordingAsReceived, AssignmentGoodsReceipt, BatchReceipt, BatchesIndicationStatusReceipt, 
		|CCDNumber, Price, Count, QuantityByGBRN, InventoryOwnerAttribute, ItemsLocationAttributes, 
		|ItemsLocationAttributesReceipt, ItemVariantsAreUsed, 
		|ItemVariantsAreUsedRecordingAsReceived, TheRecordsAreKeptByCCD, SKU, SKURegistration, 
		|ItemsType, CCDNumberType, ItemTypePosting, OriginCountry, AccountingForTheRNPTIsMaintained";
	
	ReturnedDescription = New Structure(Keys);
	
	If CurrentRow <> Undefined Then
		FillPropertyValues(ReturnedDescription, CurrentRow);
	EndIf;
	
	Return ReturnedDescription;
	
EndFunction
&AtClientAtServerNoContext
Function FillingParametersByDestinationType()
	
	Parameters = AssignmentsClientServer.FillParameters();
	Parameters.NameOfFieldToFillIn = "AssignmentGoodsReceipt";
	Parameters.TSFieldName           = "Purpose";
	Parameters.AssignmentType       = PredefinedValue("Enum.AssignmentTypes.Giveaway2_5");
	
	Return Parameters;
	
EndFunction
&AtServer
Procedure RecalculateNumberOfRNPT(ReadyForProcessing_ = Undefined)
	
	If (ValueIsFilled(Object.Contract)
			And ValueIsFilled(Object.Organization))
		Or ValueIsFilled(ReadyForProcessing_) Then
		
		RecalculationParameters = AccountingForTraceableGoodsClientServerLocalization.ParametersForObtainingRnptCoefficient(
								Object,
								"Contract");
		
		FieldNamesWithSuffix = RecalculationParameters.FieldNamesWithSuffix;
		FieldNamesWithSuffix.Insert("Products",	"ProductsRecordingAsReceived");
		FieldNamesWithSuffix.Insert("Characteristic",	"CharacteristicRecordingAsReceived");
		
		AccountingForTraceableGoodsLocalization.FillInQuantityByRNPTVOfTablePart(RecalculationParameters,
																						Object.Goods,
																						ReadyForProcessing_);
		
	EndIf;
	
EndProcedure

#Region StandardSubsystems_Properties

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

#EndRegion

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
