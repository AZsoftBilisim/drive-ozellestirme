
#Region Variables

&AtClient
Var CachedValues; //It is used by the mechanism for processing changes in PM details.

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
	
	FillInListOfSpoilageCauses();
	
	Items.GoodsProducts.ReadOnly              = Parameters.ProhibitChangingProducts;
	Items.GoodsCharacteristic.ReadOnly            = Parameters.ProhibitChangingProducts;
	Items.GoodsProductsRecordingAsReceived.ReadOnly = Parameters.ProhibitChangingProducts;
	Items.GoodsCount.ReadOnly                = Parameters.ProhibitChangingProducts;
	Items.Counterparty.ReadOnly                      = Parameters.ProhibitChangingProducts;
	Items.Partner.ReadOnly                         = Parameters.ProhibitChangingProducts;
	Items.Contract.ReadOnly                         = Parameters.ProhibitChangingProducts;
	Items.Terms.ReadOnly                      = Parameters.ProhibitChangingProducts;
	Items.Organization.ReadOnly                     = Parameters.ProhibitChangingProducts;
	Items.Goods.ChangeRowSet                     = Not Parameters.ProhibitChangingProducts;
	
	If Not ValueIsFilled(Object.Ref) Then
		OnReadCreateAtServer();
		ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);
	ElsIf IsTempStorageURL(Parameters.AddressOfTheDataInTheStorage) Then
		ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);
	EndIf;	
	
	SetAvailabilityOfClipboardCommands();
	
	// Selection of articles and analytics.
	ItemsAndDimensionsSelectionParameters =
		Documents.DamageAtCustodian.ItemsAndDimensionsSelectionParameters(Object.ReceiveGoodsAtCostTheyWereIssuedFromWarehouse);
	IncomeAndExpensesServer.OnCreateAtServer(ThisObject, ItemsAndDimensionsSelectionParameters);
	
	// Setting up accounting accounts.
	SetupParameters = Documents.DamageAtCustodian.AccountingAccountSettings_();
	GLAccountSettingsServer.OnCreateAtServer(ThisObject, SetupParameters);
	
	DocumentCorrection.OnCreateAtServer(ThisObject, Items.LineCorrection);
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	// StandardSubsystems.FilesOperations
	HyperlinkParameters = FilesOperations.FilesHyperlink();
	HyperlinkParameters.Location = "CommandBar";
	FilesOperations.OnCreateAtServer(ThisObject, HyperlinkParameters);
	// End StandardSubsystems.FilesOperations
	
	// StandardSubsystems.SourceDocumentsOriginalsRecording
	SourceDocumentsOriginalsRecording.OnCreateAtServerDocumentForm(ThisObject);
	// End StandardSubsystems.SourceDocumentsOriginalsRecording
	
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	
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
	
		ProductsClient.ProcessSeriesIndication(ThisForm, SeriesSpecificationParameters, ValueSelected);
	
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
	
	
	// StandardSubsystems.FilesOperations
	FilesOperationsClient.NotificationProcessing(ThisObject, EventName);
	// End StandardSubsystems.FilesOperations
	
	// StandardSubsystems.SourceDocumentsOriginalsRecording	
	SourceDocumentsOriginalsRecordingClient.NotificationHandlerDocumentForm(EventName, ThisObject);
	// End StandardSubsystems.SourceDocumentsOriginalsRecording
	
	DocumentCorrectionClient.NotificationProcessing(ThisObject, EventName, Parameter, Source);
	
	FormEventsClient.NotificationProcessing(ThisObject, EventName, Parameter, Source);
	
	If EventName = "WhenChangingAgreement"
		And Source = ThisObject Then
		Modified = True;
		ContractOnChange(Items[Parameter]);
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
	ItemsAndDimensionsSelectionParameters =
		Documents.DamageAtCustodian.ItemsAndDimensionsSelectionParameters(Object.ReceiveGoodsAtCostTheyWereIssuedFromWarehouse);
	IncomeAndExpensesServer.OnReadAtServer(ThisObject, ItemsAndDimensionsSelectionParameters);

	// Setting up accounting accounts.
	SetupParameters = Documents.DamageAtCustodian.AccountingAccountSettings_();
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
	
	Handler = Documents.DamageAtCustodian.ActionHandler(Object.BusinessOperation);
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
	Notify("Write_DamageAtCustodian", WriteParameters, Object.Ref);
	
	DocumentCorrectionClient.AfterWrite(Object);
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.AfterWrite(ThisForm, Object, WriteParameters);
	// End StandardSubsystems.AttachableCommands
	
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
	
	ReceiveGoodsAtCostTheyWereIssuedFromWarehouseOnChangeServer();
	
EndProcedure

&AtClient
Procedure PriceKindOnChange(Item)
	
	If Object.ReceiveGoodsAtCostTheyWereIssuedFromWarehouse
	 Or Not ValueIsFilled(Object.PriceKind)
	 Or Object.Goods.Count() = 0 Then
		Return;
	EndIf;
	
	Notification   = New CallbackDescription("PriceKindOnChangeCompletion", ThisObject);
	QueryText = StrTemplate(NStr("vi = 'Điền đơn giá theo dạng giá ""%1""?';
								|ru = 'Заполнить цены по виду цен ""%1""?';
								|en = 'Fill in prices by price type ""%1""?'; fa = 'Fill in prices by price type ""%1""?';
								|it = 'Compilare i prezzi per il tipo di prezzi ""%1""?';
								|pl = 'Wypełnić ceny według rodzaju cen ""%1""?';
								|tr = 'Fiyatlar, ""%1"" fiyat türüne göre doldurulsun mu?'"), Object.PriceKind);
	ShowQueryBox(Notification, QueryText, QuestionDialogMode.YesNo,, DialogReturnCode.Yes);
	
EndProcedure

&AtClient
Procedure PriceKindOnChangeCompletion(QuestionResult, AdditionalParameters) Export
	
	If QuestionResult = DialogReturnCode.Yes Then
		PricesCalculated = FillInPricesByPriceKindServer();
		SalesClient.NotifyAboutEndOfFillingInPricesByTypeOfPrices(PricesCalculated, Object.PriceKind);
	EndIf;
	
EndProcedure

&AtClient
Procedure LineCorrectionURLProcessing(Item, FormattedStringURL, StandardProcessing)
	DocumentCorrectionClient.StringFixHandlingNavigationLinks(
		ThisObject, FormattedStringURL, StandardProcessing);
EndProcedure

// StandardSubsystems.Properties
&AtClient
Procedure Attachable_OnChangeAdditionalAttribute(Item)
	
	PropertyManagerClient.UpdateAdditionalAttributesDependencies(ThisObject);
	
EndProcedure
// End StandardSubsystems.Properties

#EndRegion

#Region EventHandlersForTableItems

&AtClient
Procedure GoodsProductsOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;
	
	If ValueIsFilled(CurrentRow.ProductsRecordingAsReceived)
	   And Not ThereIsGradationOfQuality(CurrentRow.Products, CurrentRow.ProductsRecordingAsReceived) Then
		CurrentRow.ProductsRecordingAsReceived               = Undefined;
		CurrentRow.CharacteristicRecordingAsReceived             = Undefined;
		CurrentRow.ItemVariantsAreUsedRecordingAsReceived = False;
	EndIf;
	
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
Procedure GoodsProductsRecordingAsReceivedStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	
	CurrentData = Items.Goods.CurrentData;
	
	If CurrentData = Undefined Then
		ShowMessageBox(Undefined, NStr("vi = 'Hãy chọn dòng cần thay đổi chất lượng';
										|ru = 'Выберите строку, для которой нужно изменить качество';
										|en = 'Select the line for which quality should be changed'; fa = 'Select the line for which quality should be changed';
										|it = 'Selezionare la riga per la quale si desidera modificare la qualità';
										|pl = 'Wybierz wiersz, dla którego należy zmienić jakość';
										|tr = 'Değerini değiştirmek istediğiniz satırı seçin'"));
		Return;
	EndIf;
	
	CurrentRow = New Structure;
	CurrentRow.Insert("Products",               CurrentData.Products);
	CurrentRow.Insert("Characteristic",             CurrentData.Characteristic);
	CurrentRow.Insert("ItemVariantsAreUsed", CurrentData.ItemVariantsAreUsed);
	CurrentRow.Insert("ProductsRecordingAsReceived");
	CurrentRow.Insert("CharacteristicRecordingAsReceived");
	CurrentRow.Insert("ItemVariantsAreUsedRecordingAsReceived");
	CurrentRow.Insert("Price",                       CurrentData.Price);
	CurrentRow.Insert("PriceKind",                    Object.PriceKind);
	CurrentRow.Insert("Package",                   PredefinedValue("Catalog.PackagesAndUnitsOfMeasure.EmptyRef"));
	CurrentRow.Insert("SKU",                    CurrentData.SKU);
	CurrentRow.Insert("SKURegistration",       CurrentData.SKURegistration);
	
	FillInArticleAttribute = New Structure;
	FillInArticleAttribute.Insert("Products",                  "SKU");
	FillInArticleAttribute.Insert("ProductsOfOriginalQuality", "SKURegistration");
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInArticleAttribute",            FillInArticleAttribute);
	StructureOfActions.Insert("CheckCharacteristicsByOwner", CurrentData.Characteristic);
	
	If ValueIsFilled(CurrentData.Characteristic) Then
		StructureOfActions.Insert("FillInDescriptionOfPoorQualityProduct", CurrentData.Characteristic);
	EndIf;
	
	If Not Object.ReceiveGoodsAtCostTheyWereIssuedFromWarehouse Then
		
		FillInSalePrice = New Structure;
		FillInSalePrice.Insert("Date",   Object.Date);
		FillInSalePrice.Insert("Currency", Object.Currency);	
		
		StructureOfActions.Insert("FillInSalePrice", FillInSalePrice);
		
	EndIf;
	
	NotificationParameters_ = New Structure;
	NotificationParameters_.Insert("CurrentData", CurrentData);
	
	Notification = New CallbackDescription("GoodsProductsRecordingAsReceivedStartChoiceCompletion",
										  ThisObject,
										  NotificationParameters_);
	WarehousesClient.ChangeQuality(CurrentRow, StructureOfActions, CachedValues, Notification);

EndProcedure

&AtClient
Procedure GoodsProductsRecordingAsReceivedStartChoiceCompletion(Result, AdditionalParameters) Export 
	
	FillPropertyValues(AdditionalParameters.CurrentData, Result);

EndProcedure

&AtClient
Procedure GoodsProductsRecordingAsReceivedOnChange(Item)
	
	CurrentData = Items.Goods.CurrentData;
	
	CurrentRow = New Structure;
	CurrentRow.Insert("Products",               CurrentData.ProductsRecordingAsReceived);
	CurrentRow.Insert("Characteristic",             CurrentData.CharacteristicRecordingAsReceived);
	CurrentRow.Insert("ItemVariantsAreUsed", CurrentData.ItemVariantsAreUsedRecordingAsReceived);
	CurrentRow.Insert("Price",                       CurrentData.Price);
	CurrentRow.Insert("PriceKind",                    Object.PriceKind);
	CurrentRow.Insert("Package",                   PredefinedValue("Catalog.PackagesAndUnitsOfMeasure.EmptyRef"));
	CurrentRow.Insert("SKU",                    CurrentData.SKU);
	
	FillInArticleAttribute = New Structure;
	FillInArticleAttribute.Insert("Products", "SKU");
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInArticleAttribute",            FillInArticleAttribute);
	StructureOfActions.Insert("CheckCharacteristicsByOwner", CurrentData.CharacteristicRecordingAsReceived);
	
	If Not Object.ReceiveGoodsAtCostTheyWereIssuedFromWarehouse Then
		
		FillInSalePrice = New Structure;
		FillInSalePrice.Insert("Date",   Object.Date);
		FillInSalePrice.Insert("Currency", Object.Currency);
		
		StructureOfActions.Insert("FillInSalePrice", FillInSalePrice);
		
	EndIf;
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
	CurrentData.CharacteristicRecordingAsReceived             = CurrentRow.Characteristic;
	CurrentData.ItemVariantsAreUsedRecordingAsReceived = CurrentRow.ItemVariantsAreUsed;
	CurrentData.SKURegistration                    = CurrentRow.SKU;
	CurrentData.Price                                    = CurrentRow.Price;
	
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
Procedure GoodsCharacteristicRecordingAsReceivedOnChange(Item)
	
	If Object.ReceiveGoodsAtCostTheyWereIssuedFromWarehouse Or Not ValueIsFilled(Object.PriceKind) Then
		Return;
	EndIf;
	
	CurrentData = Items.Goods.CurrentData;
	
	CurrentRow = New Structure;
	CurrentRow.Insert("Products",               CurrentData.ProductsRecordingAsReceived);
	CurrentRow.Insert("Characteristic",             CurrentData.CharacteristicRecordingAsReceived);
	CurrentRow.Insert("ItemVariantsAreUsed", CurrentData.ItemVariantsAreUsedRecordingAsReceived);
	CurrentRow.Insert("Price",                       CurrentData.Price);
	CurrentRow.Insert("PriceKind",                    Object.PriceKind);
	CurrentRow.Insert("Package",                   PredefinedValue("Catalog.PackagesAndUnitsOfMeasure.EmptyRef"));
	
	FillInSalePrice = New Structure;
	FillInSalePrice.Insert("Date",   Object.Date);
	FillInSalePrice.Insert("Currency", Object.Currency);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInSalePrice", FillInSalePrice);
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
	CurrentData.Price = CurrentRow.Price;
	
EndProcedure

&AtClient
Procedure GoodsPurposeOnChange(Item)
	
	CurrentData = Items.Goods.CurrentData;
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInDestinationType", FillingParametersByDestinationType());
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentData, StructureOfActions, Undefined);
	If CurrentData <> Undefined And Not ValueIsFilled(CurrentData.Purpose)Then
		CurrentData.ForAssignment = False;	
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
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

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

// StandardSubsystems.SourceDocumentsOriginalsRecording

&AtClient
Procedure Attachable_OriginalStateDecorationClick()
	SourceDocumentsOriginalsRecordingClient.OpenStateSelectionMenu(ThisObject, Items.OriginalStateDecoration);
EndProcedure

//End StandardSubsystems.SourceDocumentsOriginalsRecording

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
	
	ProcessingOfTabularFormsClient.SplitRow(TableData, FormTable,, PartitioningParameters);
	
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
		"Document.DamageAtCustodian.DocumentForm.Command.OpenSelection");
	
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
		HeaderParameter_ = StrReplace(HeaderParameter_, "%Document%", NStr("vi = 'hàng hóa hỏng bên nơi cất giữ';
																			|ru = 'порчу товаров у хранителя';
																			|en = 'VMI quality change'; fa = 'تغییر کیفیت VMI';
																			|it = 'usura articoli presso il magazzino';
																			|pl = 'uszkodzenie towarów u opiekuna';
																			|tr = 'emanetçi mallarının kalite değişikliğini'"));
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
	If Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.DamageAtToller") Then
		FormParameters.Insert("UseAdvancedFeaturesOfSalesOrder", True);
	EndIf;
	OpenForm("DataProcessor.SelectGoodsToSalesDocument.Form", FormParameters, ThisForm, UUID);
	
EndProcedure

&AtClient
Procedure SelectTransferredGoods(Command)
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.TimeMeasurement(
		"Document.DamageAtCustodian.DocumentForm.Command.SelectTransferredGoods");
	
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
		"Document.DamageAtCustodian.DocumentForm.Command.SelectTransferredGoods");
	
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
			StrReplace(HeaderOfSubmittedProductSelectionForm, "%Document%", NStr("vi = 'hàng hóa hỏng bên nơi cất giữ';
																				|ru = 'порчу товаров у хранителя';
																				|en = 'VMI quality change'; fa = 'تغییر کیفیت VMI';
																				|it = 'usura articoli presso il magazzino';
																				|pl = 'uszkodzenie towarów u opiekuna';
																				|tr = 'emanetçi mallarının kalite değişikliğini'"));
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
	
	PriceKind = ?(ValueIsFilled(Object.PriceKind), Object.PriceKind, PriceManagementSystemServerCall.PriceTypePriceList_());
	
	If ValueIsFilled(PriceKind) Then
		PricesCalculated = FillInPricesByPriceKindServer(PriceKind);
		SalesClient.NotifyAboutEndOfFillingInPricesByTypeOfPrices(PricesCalculated, PriceKind);
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
		"Document.DamageAtCustodian.Form.DocumentForm.Command.FillInPricesByCosts");
	
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

#EndRegion

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

#EndRegion

#Region Private

#Region OnChangeAttributes

&AtServer
Procedure BusinessOperationOnChangeServer()
	
	Object.Partner    = PredefinedValue("Catalog.Partners.EmptyRef");
	Object.Counterparty = PredefinedValue("Catalog.Counterparties.EmptyRef");
	Object.Terms = PredefinedValue("Catalog.TermsOfSale.EmptyRef");
	
	PartnerOnChangeServer();
	CounterpartyOnChangeServer();
	ContractOnChangeServer();
	
	Handler = Documents.DamageAtCustodian.ActionHandler(Object.BusinessOperation);
	
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
	
	Handler = Documents.DamageAtCustodian.ActionHandler(Object.BusinessOperation);
	
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
	
	Handler = Documents.DamageAtCustodian.ActionHandler(Object.BusinessOperation);
	
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
	
	Handler = Documents.DamageAtCustodian.ActionHandler(Object.BusinessOperation);
	
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
	
	Handler = Documents.DamageAtCustodian.ActionHandler(Object.BusinessOperation);
	
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

&AtServer
Procedure ReceiveGoodsAtCostTheyWereIssuedFromWarehouseOnChangeServer()
	
	If Object.ReceiveGoodsAtCostTheyWereIssuedFromWarehouse Then
		ClearPrices(ThisObject);
	EndIf;
	
	FillInArticleSelectionParameters();
	IncomeAndExpensesClientServer.AssetRefOnChange(ThisObject, Items.ExpenseItem);
	
	SetAvailabilityViewPrices();
	
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
	LinesOfBusinessClientServer.StructureOfInsertActionsWhenAddingRow(ThisForm, StructureOfActions);
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
	ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);
	
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
	
	GoodsTable   = GetFromTempStorage(ReturnParameters.Goods);
	LinesToDelete = New Array;
	
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
			EndIf;
			
		EndDo;
		
		If FoundRows.Count() = 0 Then
			TSRow = Object.Goods.Add();
			FillPropertyValues(TSRow, SourceRow);
			
			TSRow.Count = SourceRow.NumberOfPackages;
		EndIf;
		
	EndDo;
	
	For Each TSRow In LinesToDelete Do
		Object.Goods.Delete(TSRow);
	EndDo;
	
	FillInServiceDetailsForProductRange();
	ProductsServer.FillInStatusesForSpecifyingSeries(Object,SeriesSpecificationParameters);
	
EndProcedure

#EndRegion

#Region PriceManagementSystem

&AtServer
Function FillInPricesByPriceKindServer(PriceKind = Undefined)
	
	If PriceKind = Undefined Then
		PriceKind = Object.PriceKind;
	EndIf;
	
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
	|	InventoryCostCalculation.Ref AS Ref
	|FROM
	|	Document.InventoryCostCalculation AS InventoryCostCalculation
	|		LEFT JOIN Document.InventoryCostCalculation.Companies AS InventoryCostCalculationCompanies
	|		ON InventoryCostCalculation.Ref = InventoryCostCalculationCompanies.Ref
	|WHERE
	|	InventoryCostCalculation.Posted
	|	AND InventoryCostCalculation.EntryType = VALUE(Enum.LotRecordTypes.EmptyRef)
	|	AND InventoryCostCalculationCompanies.Organization = &Organization";
	
	Query.SetParameter("Organization", Object.Organization);
	
	Result = Query.Execute();
	If Result.IsEmpty() Then
		
		MessageText =
			StrTemplate(NStr("vi = 'Chưa tính giá vốn hàng hóa theo doanh nghiệp ""%1"".';
							|ru = 'Не было произведено ни одного расчета себестоимости товаров по организации ""%1"".';
							|en = 'No inventory costs were calculated for company ""%1"".'; fa = 'No inventory costs were calculated for company ""%1"".';
							|it = 'Non è stato effettuato un solo calcolo del costo di produzione delle merci per società ""%1"".';
							|pl = 'Nie było przeprowadzono ani jednego rozliczenia kosztów własnych towarów według firmy ""%1"".';
							|tr = '""%1"" iş yeri için herhangi bir mal maliyeti hesaplaması yapılmamıştır.'"),
			Object.Organization);
		Common.MessageToUser(MessageText);
		
		Return False;
		
	EndIf;
	
	OtherColumnNames = New Structure;
	OtherColumnNames.Insert("Products",   "Products");
	OtherColumnNames.Insert("Characteristic", "Characteristic");
	
	FillParameters = New Structure;
	FillParameters.Insert("Date",               Object.Date);
	FillParameters.Insert("Organization",        Object.Organization);
	FillParameters.Insert("Currency",             Object.Currency);
	FillParameters.Insert("Warehouse",              Object.Contract);
	FillParameters.Insert("OtherColumnNames", OtherColumnNames);
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
	
	ObjectManager = Documents.DamageAtCustodian;
	
	Return New FixedStructure(ProductsServer.SeriesSpecificationParameters(Object, ObjectManager));
	
EndFunction

&AtClient
Procedure OpenSelectionOfSeries(Text = "")
	
	If ProductsClient.YouNeedServerCallToSpecifySeries(ThisForm, SeriesSpecificationParameters, Text)Then
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

#Region Other

&AtServer
Procedure SetConditionalAppearance()
	
	ConditionalAppearance.Items.Clear();
	
	// Setting the Conditional appearance of a different quality item.
	ProductsServer.SetConditionalAppearanceOfDifferentQualityItem(ThisObject);
	
	// Setting the conditional design for the items of the nomenclature of the tabular part 'Goods'
	ProductsServer.EstablishConditionalAppearanceOfProductCharacteristics(ThisObject);
	ProductsServer.EstablishConditionalAppearanceOfProductCharacteristics(
		ThisObject, "GoodsCharacteristicRecordingAsReceived", "Object.Goods.ItemVariantsAreUsedRecordingAsReceived");
	
	ProductsServer.SetConditionalAppearanceOfProductAssignment(ThisObject);
		
	ProductsServer.EstablishConditionalAppearanceOfProductSeries(ThisObject, "SeriesAlwaysWHGoods");
	ProductsServer.SetConditionalAppearanceOfStatusIndicationSeries(ThisObject, True);
	
	// Setting the conditional design for the 'Price' element
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsPrice.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsPriceOffBalance.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.ReceiveGoodsAtCostTheyWereIssuedFromWarehouse");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	Item.Appearance.SetParameterValue("TextColor", StyleColors.TextColorOfCanceledRowOfDocument);
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<đưa vào giá vốn>';
													|ru = '<приходуется по себестоимости>';
													|en = '<recorded as received at cost>'; fa = '<recorded as received at cost>';
													|it = '<viene registrato in contabilità al costo di produzione>';
													|pl = '<przyjęcie według kosztu własnego>';
													|tr = '<maliyet üzerinden tüketilir>'"));
	Item.Appearance.SetParameterValue("ReadOnly", True);
	
	// Setting the conditional design for the element "For the purpose"
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsForAssignment.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.Purpose");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;

	Item.Appearance.SetParameterValue("Show", False);
	
	// Setting the conditional design for the 'Division' element
	InventoriesServer.EstablishConditionalAppearanceOfDivisionForTypesOfStocks(ThisObject);
	
	// Setting the conditional design for the 'Activity Direction' element
	LinesOfBusinessServer.EstablishConditionalAppearanceOfDirectionOfActivity(ThisObject);
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsForAssignment.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue  = New DataCompositionField("Object.Goods.AssignmentType");
	ItemFilter.ComparisonType   = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.AssignmentTypes.Giveaway2_5;
	
	Item.Appearance.SetParameterValue("ReadOnly", True);
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
	
	Documents.DamageAtCustodian.ConfigureBusinessTransactionDetails(ThisObject, Object);
	
	UseLinesOfBusiness = GetFunctionalOption("UseIncomeAccountingByLinesOfBusiness");
	
	Handler = Documents.DamageAtCustodian.ActionHandler(Object.BusinessOperation);
	
	Handler.SetContractAvailability(ThisObject, Object);
	
	Handler.AdjustItemSelectionSettings(ThisObject, Object);	
	Handler.CustomizeForm(ThisObject, Object.Number, Object.Date);
	
	If UseLinesOfBusiness Then
		SetLBEditingOption();
	EndIf;
	
	Items.CounterpartyGroup.Visible = Not GetFunctionalOption("UsePartnersAsCounterparties");
	
	SeriesSpecificationParameters = SeriesSpecificationParameters();
	
	DocumentCurrency                  = Object.Currency;
	BusinessTransactionBeforeTheChange = Object.BusinessOperation;
	
	FillInServiceDetailsForProductRange();
	AssignmentsServer.FillInDestinationTypeInTable(Object.Goods);
	SetAvailabilityViewPrices();
	
	LinesOfBusinessServer.OnReadCreateAtServer(ThisObject);
	
EndProcedure

&AtServer
Procedure FillInAccordingToDataInRepository()
	
	If Not IsTempStorageURL(Parameters.AddressOfTheDataInTheStorage) Then
		Return;
	EndIf;
	
	StructureOfData = GetFromTempStorage(Parameters.AddressOfTheDataInTheStorage);
	
	If Not ValueIsFilled(Object.Ref) Then
	
		Object.Date = StructureOfData.Header.Date;
	
		DocumentObject = FormAttributeToValue("Object");
		DocumentObject.Fill(Undefined);
		ValueToFormAttribute(DocumentObject, "Object");
	
		FillPropertyValues(Object, StructureOfData.Header);
	
	EndIf;
	
	For Each RowOfTables In StructureOfData.GoodsTable Do
		NewRow = Object.Goods.Add();
		FillPropertyValues(NewRow,RowOfTables);
	EndDo;
	
	If ValueIsFilled(Object.Ref) Then
		FillInServiceDetailsForProductRange();
		ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);
	EndIf;
	
EndProcedure

&AtServer
Procedure FillInServiceDetailsForProductRange()
	
	FillInArticleAttribute = New Structure;
	FillInArticleAttribute.Insert("Products",              "SKU");
	FillInArticleAttribute.Insert("ProductsRecordingAsReceived", "SKURegistration");
	
	FillInProductTypeAttribute_ = New Structure;
	FillInProductTypeAttribute_.Insert("Products", "ItemsType");
	
	FillInFeatureAttribute = New Structure;
	FillInFeatureAttribute.Insert("Products",              "ItemVariantsAreUsed");
	FillInFeatureAttribute.Insert("ProductsRecordingAsReceived", "ItemVariantsAreUsedRecordingAsReceived");
	
	ParametersForFillingInBankingDetails = New Structure;
	ParametersForFillingInBankingDetails.Insert("FillInArticleAttribute",         FillInArticleAttribute);
	ParametersForFillingInBankingDetails.Insert("FillInProductTypeAttribute_", FillInProductTypeAttribute_);
	ParametersForFillingInBankingDetails.Insert(
		"FillInFeatureAttribute", FillInFeatureAttribute);
	
	ProductsServer.FillInServiceDetailsForProductInCollection(Object.Goods, ParametersForFillingInBankingDetails);
	
EndProcedure

&AtServer
Procedure FillInListOfSpoilageCauses()
	
	Query = New Query;
	Query.Text =
	"SELECT ALLOWED TOP 100
	|	DamageAtCustodian.CauseForDamage AS CauseForDamage,
	|	DamageAtCustodian.Date         AS DocumentDate
	|INTO CausesOfDamageToGoodsFromKeeper
	|FROM
	|	Document.DamageAtCustodian AS DamageAtCustodian
	|WHERE
	|	DamageAtCustodian.Posted
	|	AND DamageAtCustodian.CauseForDamage <> """"
	|ORDER BY
	|	DocumentDate DESC
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT TOP 30
	|	CausesOfDamageToGoodsFromKeeper.CauseForDamage AS CauseForDamage
	|FROM
	|	CausesOfDamageToGoodsFromKeeper AS CausesOfDamageToGoodsFromKeeper";
	 
	Result = Query.Execute().Unload();
	
	Items.CauseForDamage.ChoiceList.LoadValues(Result.UnloadColumn("CauseForDamage"));
	
EndProcedure

&AtServer
Procedure FillInSubordinatePropertiesForStatistics(ParentPropsName)
	
	ObjectsFillingByStatistics.FillInSubordinateDetailsOfObject(Object, ParentPropsName);
	
EndProcedure

&AtServer
Procedure FillInDefaultContract()
	
	Contract = Object.Contract;
	
	Handler = Documents.DamageAtCustodian.ActionHandler(Object.BusinessOperation);
	DefaultContract = Handler.GetDefaultContract(Object);
	
	If Contract <> DefaultContract Then
		Contract        = DefaultContract;
		Object.Contract = DefaultContract;
	EndIf;
	
EndProcedure

&AtServer
Procedure FillInArticleSelectionParameters()
	
	// Selection of articles and analytics.
	ItemsAndDimensionsSelectionParameters = 
		Documents.DamageAtCustodian.ItemsAndDimensionsSelectionParameters(Object.ReceiveGoodsAtCostTheyWereIssuedFromWarehouse);
		
	IncomeAndExpensesServer.WhenChangingArticleSelectionParameters(ThisObject, ItemsAndDimensionsSelectionParameters);
	
EndProcedure

&AtServer
Procedure SetAvailabilityViewPrices()
	
	If Object.ReceiveGoodsAtCostTheyWereIssuedFromWarehouse Then
		Items.PriceKind.Enabled = False;
	Else
		Items.PriceKind.Enabled = True;
	EndIf;
	
	Items.FillInPrices.Enabled = Not Object.ReceiveGoodsAtCostTheyWereIssuedFromWarehouse;
	
EndProcedure

&AtServer
Procedure GoodsAfterDeleteRowServer(SeriesStatusesNeedToBeUpdated, CachedValues)
	
	If SeriesStatusesNeedToBeUpdated Then
		FillInStatusesOfSpecifyingSeriesWhenEditingLineTS(Undefined, CachedValues);
	EndIf;
	
EndProcedure

&AtServer
Function ThereIsGradationOfQuality(ProductOfOriginalQuality, NonconformingProducts)
	
	 Return InformationRegisters.AnotherQualityGoods.CheckForGradation(ProductOfOriginalQuality, NonconformingProducts);
	
EndFunction
&AtClientAtServerNoContext
Function FillingParametersByDestinationType()
	
	Parameters = AssignmentsClientServer.FillParameters();
	Parameters.NameOfFieldToFillIn = "ForAssignment";
	Parameters.Simple        = True;
	Parameters.AssignmentType       = PredefinedValue("Enum.AssignmentTypes.Giveaway2_5");
	
	Return Parameters;
	
EndFunction
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
