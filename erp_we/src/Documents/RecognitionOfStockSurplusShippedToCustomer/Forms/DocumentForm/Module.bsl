
#Region Variables

&AtClient
Var PreviousRowDetails; //used to unlink the receipt line from the order line

&AtClient
Var CachedValues; //It is used by the mechanism for processing changes in PM details.

&AtClient
Var CurDataId; //Used to pass the current line to the waiting handler.

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
	PropertyManager.OnCreateAtServer(ThisObject,        AdditionalParameters);
	
	// Handler of the "Versioning of objects" mechanism
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	
	// Handler of the "Destination" mechanism
	Catalogs.Assignments.DocumentFormWhenCreatedOnServer(ThisObject);
	
	If Not ValueIsFilled(Object.Ref) Then
		AutoTitle = False;
		
		GenerateHeaderFromTypeOfBusinessTransaction();
		OnReadCreateAtServer();
		
		ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);
	EndIf;
	
	SetAvailabilityOfClipboardCommands();
	
	AccountingForTraceableGoodsLocalization.EstablishVisibilityOfRNPTQuantity(ThisObject, Object.Date);
	
	// Selection of articles and analytics.
	ItemsAndDimensionsSelectionParameters = Documents.RecognitionOfStockSurplusShippedToCustomer.ItemsAndDimensionsSelectionParameters();
	IncomeAndExpensesServer.OnCreateAtServer(ThisObject, ItemsAndDimensionsSelectionParameters);
	
	// Setting up accounting accounts.
	SetupParameters = Documents.RecognitionOfStockSurplusShippedToCustomer.AccountingAccountSettings_();
	GLAccountSettingsServer.OnCreateAtServer(ThisObject, SetupParameters);
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	FormEvents.OnCreateAtServer(ThisObject, Cancel, StandardProcessing);
	
	// StandardSubsystems.FilesOperations
	HyperlinkParameters = FilesOperations.FilesHyperlink();
	HyperlinkParameters.Location = "CommandBar";
	FilesOperations.OnCreateAtServer(ThisObject, HyperlinkParameters);
	// End StandardSubsystems.FilesOperations
	
	AccountingForTraceableGoodsLocalization.SetTitleNumberOfCCD(Items, "GoodsCCDNumber");
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject);
	// End IntegrationWith1CDocumentManagementSubsystem
	
	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	AttributesNames =
		"Products,
		|Characteristic,
		|Purpose,
		|Count,
		|ItemsType,
		|ItemVariantsAreUsed";
	
	PreviousRowDetails = New Structure(AttributesNames);
	
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
	
	If ChoiceSource.FormName = "CommonForm.AddItemsFromSalesOrderGoodsIssue" Then
		
		ProcessingProductSelectionFromOrder(ValueSelected.AddressInStorage);
		
	ElsIf ChoiceSource.FormName = "DataProcessor.SelectGoodsTransferredToCustody.Form.Form" Then
		
		SelectionProcessingSelectionOfTransferredGoods(ValueSelected);
		
	ElsIf ChoiceSource.FormName = "Catalog.InventoryKinds.Form.InventoryOwnerAttributesForm" Then
		
		GetStockTypesFromStorage(ValueSelected);
		
	ElsIf ProductsClient.ThisIsIndicationOfSeries(ChoiceSource) Then
		
		ProductsClient.ProcessSeriesIndication(ThisObject, SeriesSpecificationParameters, ValueSelected);
		
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
	If PropertyManagerClient.ProcessNotifications(ThisObject, EventName, Parameter) Then
		UpdateAdditionalAttributesItems();
		PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
	EndIf;
	
	If EventName = "CopyingLinesToClipboard" Then
		SetAvailabilityOfClipboardCommandsOnClient();
	EndIf;
	
	
	FormEventsClient.NotificationProcessing(ThisObject, EventName, Parameter, Source);
	
	// StandardSubsystems.FilesOperations
	FilesOperationsClient.NotificationProcessing(ThisObject, EventName);
	// End StandardSubsystems.FilesOperations
	
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
Procedure OnReadAtServer(CurrentObject)
	
	// StandardSubsystems.AccessManagement
	AccessManagement.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.AccessManagement
	
	// Handler of the "Date-change" mechanism
	PeriodClosingDates.ObjectOnReadAtServer(ThisObject, CurrentObject);
	
	// Handler of the "Properties" subsystem
	PropertyManager.OnReadAtServer(ThisObject, CurrentObject);
	
	OnReadCreateAtServer();
	
	// Selection of articles and analytics.
	ItemsAndDimensionsSelectionParameters = Documents.RecognitionOfStockSurplusShippedToCustomer.ItemsAndDimensionsSelectionParameters();
	IncomeAndExpensesServer.OnReadAtServer(ThisObject, ItemsAndDimensionsSelectionParameters);

	// Setting up accounting accounts.
	SetupParameters = Documents.RecognitionOfStockSurplusShippedToCustomer.AccountingAccountSettings_();
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
	PropertyManager.BeforeWriteAtServer(ThisObject, CurrentObject);
	
	
	// Setting up accounting accounts.
	GLAccountSettingsServer.BeforeWriteAtServer(ThisObject, CurrentObject);
	ConfigurationModificationOverridable.BeforeWriteAtServer(ThisObject, Cancel, CurrentObject, WriteParameters);
	
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
	
	FillInServiceDetailsForProductRange();
	PurchasesServer.FillInServiceAttributesOfCCDNumber(Object.Goods);
	
	// Selection of articles and analytics.
	IncomeAndExpensesServer.AfterWriteAtServer(ThisObject);

	// Setting up accounting accounts.
	GLAccountSettingsServer.AfterWriteAtServer(ThisObject);
	
	ConfigurationModificationOverridable.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	
	FormEvents.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	
	Title = "";
	AutoTitle = True;
	
	WriteParameters.Insert("NotificationDocumentKeys", OperationsWithDocumentJournalsClient.GetKeyParametersForDocument(
		Object.Ref, Object.Date, Object.BusinessOperation));
	Notify("Write_RecognitionOfStockSurplusShippedToCustomer", WriteParameters, Object.Ref);
	
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
	If CurrentPage.Name = "AdditionalPage"
		And Not ThisObject.PropertiesParameters.DeferredInitializationExecuted Then
		
		PropertiesExecuteDeferredInitialization();
		PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
		
	EndIf;
	// End StandardSubsystems.Properties
	
EndProcedure

&AtClient
Procedure DateOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	
	DateOnChangeServer();
	
	
EndProcedure

&AtClient
Procedure PartnerOnChange(Item)
	
	PartnerOnChangeServer();
	AskQuestionWhenChangingPriceType();
	
	
EndProcedure

&AtClient
Procedure CounterpartyOnChange(Item)
	
	CounterpartyOnChangeServer();
	AskQuestionWhenChangingPriceType();
	
	
EndProcedure

&AtClient
Procedure TermsOnChange(Item)
	
	If Not ValueIsFilled(Object.Terms) Then
		Return;
	EndIf;
	
	TermsOnChangeServer();
	AskQuestionWhenChangingPriceType();
	
EndProcedure

&AtClient
Procedure TermsStartChoice(Item, ChoiceData, StandardProcessing)
	
	AgreementSelectionParameters = SalesClient.ParametersForStartingSelectionOfAgreementWithClient();
	AgreementSelectionParameters.Item               = Item;
	AgreementSelectionParameters.Partner               = Object.Partner;
	AgreementSelectionParameters.Document              = Object.Terms;
	AgreementSelectionParameters.DocumentDate         = Object.Date;
	AgreementSelectionParameters.FormDataStructure  = Object;
	AgreementSelectionParameters.BusinessOperation = ContractBusinessTransaction;
	AgreementSelectionParameters.ConsignmentSales25 = ?(ConsignmentSales25, True, Undefined);
	AgreementSelectionParameters.ShipmentWithDeferredTransferOfTitle25 = ?(ShipmentWithDeferredTransferOfTitle25,
																			True,
																			Undefined);
	AgreementSelectionParameters.ContractsAreUsed = ?(ShipmentWithDeferredTransferOfTitle25,
																	True,
																	Undefined);
	
	SalesClient.StartSelectingAgreementWithClient(AgreementSelectionParameters, StandardProcessing);
	
EndProcedure

&AtClient
Procedure IncomeItemOnChange(Item)
	
	// Selection of articles and analytics.
	IncomeAndExpensesClientServer.AssetRefOnChange(ThisObject, Item);
	
EndProcedure

&AtClient
Procedure IncomeItemStartChoice(Item, ChoiceData, StandardProcessing)
	
	// Selection of articles and analytics.
	IncomeAndExpensesClient.StartArticleSelection(ThisObject, Item, StandardProcessing);
	
EndProcedure

&AtClient
Procedure TransactionRecordingPresentationClick(Item, StandardProcessing)
	GLAccountSettingsClient.OnClick(ThisObject, Item, StandardProcessing);
	Return; // empty handler
	
EndProcedure

&AtClient
Procedure OrganizationOnChange(Item)
	
	OrganizationOnChangeServer();
	AskQuestionWhenChangingPriceType();
	
EndProcedure

&AtClient
Procedure ContractOnChange(Item)
	
	If Not ValueIsFilled(Object.Contract) Then
		Return;
	EndIf;
	
	OriginalPriceView = Object.PriceKind;
	
	ContractOnChangeServer();
	AskQuestionWhenChangingPriceType();
	
EndProcedure

&AtClient
Procedure CurrencyOnChange(Item)
	
	If DocumentCurrency = Object.Currency Then
		Return;
	EndIf;
	
	If Not ValueIsFilled(Object.Currency) Then
		Object.Currency = DocumentCurrency;
	Else
		DocumentCurrency	= Object.Currency;
		Object.PriceKind	= PredefinedValue("Catalog.TypesOfPrices.EmptyRef");
		
		FillInDefaultContract();
		FillInPriceTypes();
	EndIf;
	
	AskQuestionWhenChangingPriceType();
	
EndProcedure

&AtClient
Procedure LineOfBusinessOnChange(Item)
	
	LineOfBusinessOnChangeServer();
	
EndProcedure

// StandardSubsystems.Properties
&AtClient
Procedure Attachable_OnChangeAdditionalAttribute(Item)
	
	PropertyManagerClient.UpdateAdditionalAttributesDependencies(ThisObject);
	
EndProcedure
// End StandardSubsystems.Properties

&AtClient
Procedure BusinessOperationOnChange(Item)
	
	BusinessOperationWhenChangingOnServer();
	AskQuestionWhenChangingPriceType();
	
EndProcedure

&AtClient
Procedure PriceKindStartChoice(Item, ChoiceData, StandardProcessing)
	
	OriginalPriceView = Object.PriceKind;
	
EndProcedure

&AtClient
Procedure PriceKindOnChange(Item)
	
	NewKindOfPrice = Object.PriceKind;
	
	AskQuestionWhenChangingPriceType();
	
EndProcedure

&AtClient
Procedure ReferenceOrderPresentationURLProcessing(Item, FormattedStringURL, StandardProcessing)
	
	StandardProcessing = False;
	
	If FormattedStringURL = "Open_Order" Then
		ShowValue(, Object.ReferenceOrder)
	Else
		
		// &PerformanceMeasurement
		PerformanceMonitorClient.TimeMeasurement(
			"Document.RecognitionOfStockSurplusShippedToCustomer.Form.ReferenceChoiceForm");

		CallbackDescription = New CallbackDescription("CustomerSChoice", ThisObject);
		OpenOrderSelection(CallbackDescription);

	EndIf;
	
EndProcedure

&AtClient
Procedure CaptionOrderTitleClick(Item, StandardProcessing)
	
	StandardProcessing = False;
	
	TitleText    = NStr("vi = 'Lệnh (%DocumentsCount%)';
						|ru = 'Распоряжения (%DocumentsCount%)';
						|en = 'References (%DocumentsCount%)'; fa = 'References (%DocumentsCount%)';
						|it = 'Disposizioni (%DocumentsCount%)';
						|pl = 'Zamówienia (%DocumentsCount%)';
						|tr = 'Talimatlar (%DocumentsCount%)'");
	OpeningParameters = New Structure("DocumentsList, Title", ListOfOrders_, TitleText);
	
	OpenForm("CommonForm.ViewingListOfDocuments",
	    OpeningParameters,
	    ThisObject,
	    ,
	    ,
	    ,
	    Undefined,
	    FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersGoods

&AtClient
Procedure GoodsOnActivateCell(Item)
	
	If Item.CurrentItem = Undefined Then
		Return;
	ElsIf Item.CurrentItem.Name = "GoodsCCDNumber" Then
		PurchasesClient.FillInListOfCCDNumberSelection(Items.Goods.CurrentData, Items.GoodsCCDNumber.ChoiceList);
	EndIf;
	
EndProcedure

&AtClient
Procedure GoodsSelection(Item, RowSelected, Field, StandardProcessing)
	
	If Field = Items.GoodsReferenceOrder Then
		
		CurrentData = Items.Goods.CurrentData;
		
		If ValueIsFilled(CurrentData.ReferenceOrder) Then
			ShowValue(Undefined, CurrentData.ReferenceOrder);
		ElsIf ValueIsFilled(Object.ReferenceOrder) Then
			ShowValue(Undefined, Object.ReferenceOrder);
		EndIf;
	
	EndIf;
	
EndProcedure

&AtClient
Procedure GoodsBeforeRowChange(Item, Cancel)
	
	FillPropertyValues(PreviousRowDetails, Items.Goods.CurrentData);
	
EndProcedure

&AtClient
Procedure GoodsBeforeDeleteRow(Item, Cancel)
	
	ProductsClient.UpdateCachedValuesToAccountForSeries(Item, CachedValues, SeriesSpecificationParameters);
	
EndProcedure

&AtClient
Procedure GoodsOnStartEdit(Item, NewRow, Copy)

	CurrentRow = Items.Goods.CurrentData;
	
	If Copy Then
		CurrentRow.ReferenceOrder = Undefined;
		CurrentRow.Purpose = Undefined;
	EndIf;
	
	ProductsClient.UpdateCachedValuesToAccountForSeries(Item,
		CachedValues,
		SeriesSpecificationParameters,
		Copy);

EndProcedure

&AtClient
Procedure GoodsOnEditEnd(Item, NewRow, CancelEdit)
	
	CurrentData        = Items.Goods.CurrentData;
	UpdateSeriesStatuses = ProductsClient.SeriesStatusesNeedToBeUpdated(Item,
																			CachedValues,
																			SeriesSpecificationParameters);
	
	If UpdateSeriesStatuses Then
		
		IDCurrentRow = CurrentData.GetID();
		
		FillInStatusesOfSpecifyingSeriesWhenEditingLineTS(IDCurrentRow, CachedValues);
		ProductsClient.UpdateCachedValuesToAccountForSeries(Item, CachedValues, SeriesSpecificationParameters);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure GoodsAfterDeleteRow(Item)
	
	UpdateSeriesStatuses = ProductsClient.SeriesStatusesNeedToBeUpdated(Item,
																			CachedValues,
																			SeriesSpecificationParameters,
																			True);
	
	GoodsAfterDeleteRowServer(UpdateSeriesStatuses, CachedValues);
	
	If UpdateSeriesStatuses Then
		ProductsClient.UpdateCachedValuesToAccountForSeries(Item, CachedValues, SeriesSpecificationParameters);
	EndIf;
	
EndProcedure

&AtClient
Procedure GoodsProductsOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;
	
	If CurrentRow = Undefined Then
		Return;
	EndIf;
	
	FillInArticleAttribute                  = New Structure("Products", "SKU");
	FillInProductTypeAttribute_          = New Structure("Products", "ItemsType");
	FillInCCDTrackingAttribute         = New Structure("Products", "TheRecordsAreKeptByCCD");
	CheckSeriesCalculateStatus           = New Structure("Warehouse, SeriesSpecificationParameters",
																Undefined, SeriesSpecificationParameters);
	ProductsOnChangeOverridable = New Structure("FormName, TabularSectionName", FormName, "Goods");
	
	StructureOfActions = New Structure;

	StructureOfActions.Insert("FillInArticleAttribute",            FillInArticleAttribute);
	StructureOfActions.Insert("FillInProductTypeAttribute_",    FillInProductTypeAttribute_);
	StructureOfActions.Insert("CheckCharacteristicsByOwner", CurrentRow.Characteristic);
	StructureOfActions.Insert("CheckSeriesCalculateStatus",     CheckSeriesCalculateStatus);
	StructureOfActions.Insert("FillInCCDTrackingAttribute",   FillInCCDTrackingAttribute);
	StructureOfActions.Insert("FillInCountryOfOriginOfProduct",
								BatchProcessingOfTablePartClientServer.CountryOfOriginFillingParameters());
	
	StructureOfActions.Insert("ProductsOnChangeOverridable", ProductsOnChangeOverridable);
	
	LinesOfBusinessClientServer.StructureOfInsertActionsWhenAddingRow(ThisObject, StructureOfActions);
	
	AccountingForTraceableGoodsClientServerLocalization.CompleteDescriptionOfSettingsForFillingInServiceDetailsOfTablePart(StructureOfActions);
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
	If Not CurrentRow.TheRecordsAreKeptByCCD Then
		CurrentRow.CCDNumber = Undefined;
		CurrentRow.CCDNumberType = Undefined;
		CurrentRow.OriginCountry = Undefined;
	EndIf;
	
	PricesCalculated = FillInPricesByPriceKindServer(CurrentRow.GetID());
	SalesClient.NotifyAboutEndOfFillingInPricesByTypeOfPrices(PricesCalculated, Object.PriceKind);
	
	FillPropertyValues(PreviousRowDetails, CurrentRow);
	
EndProcedure

&AtClient
Procedure GoodsCharacteristicOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;
	
	CharacteristicOnChangeOverridable = New Structure("FormName, TabularSectionName", FormName, "Goods");
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("CharacteristicOnChangeOverridable", CharacteristicOnChangeOverridable);
	
	LinesOfBusinessClientServer.StructureOfInsertActionsWhenAddingRow(ThisObject, StructureOfActions);
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
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
	
	ProductsClient.ProcessSeriesIndication(ThisObject, SeriesSpecificationParameters, ValueSelected);
	
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
	
	AdditionalParameters.FieldNameQuantity = "Count";
	
	CreationParameters = PurchasesClient.ParametersForCreatingCCDNumber(CurrentData,
																Item.EditText,
																AdditionalParameters);
	
	PurchasesClient.OpenFormForCreatingGTDNumber(ThisObject, CreationParameters);
	
EndProcedure

&AtClient
Procedure GoodsPriceOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;
	CurrentRow.Sum = CurrentRow.Price * CurrentRow.Count;
	
EndProcedure

&AtClient
Procedure GoodsSumOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculatePriceByAmount", "Count");
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
EndProcedure

&AtClient
Procedure GoodsCountOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;
	
	StructureOfActions = New Structure;
	AddActionsToStructureWhenQuantityChanges(StructureOfActions, Object);
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
EndProcedure

&AtClient
Procedure GoodsReferenceOrderOnChange(Item)
	UpdateInformationOnOrders();
EndProcedure

&AtClient
Procedure GoodsReferenceOrderStartChoice(Item, ChoiceData, ChoiceByAdding, StandardProcessing)
	
	StandardProcessing = False;

	If Items.Goods.CurrentData <> Undefined Then
		
		CallbackDescription = New CallbackDescription("SelectReferenceCompletion", ThisObject);
		OpenOrderSelection(CallbackDescription);
		Return;
		
	EndIf;
	
	UpdateInformationOnOrders();

EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

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
	
	FormEventsClient.ExecuteOverridableCommand(ThisObject, Command);
	
EndProcedure

&AtClient
Procedure PostAndClose(Command)
	
	TMCommonUseClient.PostAndClose(ThisObject);
	
EndProcedure

&AtClient
Procedure WriteDocument(Command)
	
	TMCommonUseClient.Write(ThisObject);
	
EndProcedure

&AtClient
Procedure PostDocument(Command)
	
	TMCommonUseClient.Post(ThisObject);
	
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
	
	AdditionalParameters = AccountingForTraceableGoodsClientServerLocalization.CompleteDescriptionOfParametersForSplittingRowInTablePart(FormTable.CurrentData);
	Notification = New CallbackDescription("SplitRowCompletion", ThisObject, AdditionalParameters);
	ProcessingOfTabularFormsClient.SplitRow(TableData, FormTable, Notification, PartitioningParameters);
	
EndProcedure

&AtClient
Procedure SplitRowCompletion(NewRow, AdditionalParameters) Export 
	
	CurrentRow = Items.Goods.CurrentData;
	
	If NewRow <> Undefined Then
		
		StructureOfActions = New Structure;
		AddActionsToStructureWhenQuantityChanges(StructureOfActions, Object);
		
		BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
		BatchProcessingOfTablePartClient.ProcessTSString(NewRow, StructureOfActions, CachedValues);
		
	EndIf;
	
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
	
	OpenForm("CommonForm.CheckDocumentPopulation", OpeningParameters, ThisObject, , , , CallbackDescription,
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
Procedure SpecifySeries(Command)
	
	OpenSelectionOfSeries();
	
EndProcedure

&AtClient
Procedure PickUpItemsByOrder(Command)
	OpenSelectionByOrders();
EndProcedure

&AtClient
Procedure SelectTransferredGoods(Command)
	
	Cancel = False;
	
	ClearMessages();
	
	If Not ValueIsFilled(Object.Partner) Then
		ErrorText = CommonClientServer.FillingErrorText( , , Items.Partner.Title);
		
		CommonClient.MessageToUser(ErrorText, Object.Ref, "Object.Partner", "", Cancel);
	EndIf;
	
	If Not ValueIsFilled(Object.Organization) Then
		ErrorText = NStr("vi = 'Chưa điền trường ""Doanh nghiệp""';
						|ru = 'Поле ""Организация"" не заполнено';
						|en = 'The ""Company"" field is required'; fa = 'The ""Company"" field is required';
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
		"Document.RecognizeInventorySurplusAtBaileeCommissionAgent.DocumentForm.Command.SelectTransferredGoods");
	
	AddressOfGoods = PlaceGoodsInStorageForSelectionOfTransferredGoods();
	FormCaption = ?(ShipmentWithDeferredTransferOfTitle25,
						NStr("vi = 'Chọn hàng hóa đã giao cho khách';
							|ru = 'Подбор товаров, отгруженных клиенту';
							|en = 'Pick goods shipped to customer'; fa = 'Pick goods shipped to customer';
							|it = 'Pick goods shipped to customer';
							|pl = 'Pick goods shipped to customer';
							|tr = 'Müşteriye sevk edilen ürünlerin seçimi'"),
						"");
	
	FormParameters = New Structure;
	FormParameters.Insert("Ref",      Object.Ref);
	FormParameters.Insert("Owner",    Object.Partner);
	FormParameters.Insert("Organization", Object.Organization);
	FormParameters.Insert("Contract",     Object.Contract);
	FormParameters.Insert("BusinessOperation", Object.BusinessOperation);
	FormParameters.Insert("AddressOfGoodsInvoiceInVault", AddressOfGoods);
	FormParameters.Insert("Title",   FormCaption);
	
	OpenForm("DataProcessor.SelectGoodsTransferredToCustody.Form.Form", FormParameters, ThisObject,
		UUID);
	
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

#EndRegion

#EndRegion

#Region Private

#Region OnChangeAttributes

&AtServer
Procedure DateOnChangeServer()
	
	UseTraceableImportedGoodsAccounting = AccountingForTraceableGoodsLocalization.UseTraceableImportedGoodsAccounting(
														Object.Date);
	
	AccountingForTraceableGoodsLocalization.EstablishVisibilityOfRNPTQuantity(ThisObject, Object.Date);
	
	If Not Items.ProductsGroupQuantityByRNPT.Visible Then
		RecalculateNumberOfRNPT();
	EndIf;
	
EndProcedure

&AtServer
Procedure PartnerOnChangeServer()
	
	DirectionsOfActivity = Object.LineOfBusiness;
	
	DocumentSales = FormAttributeToValue("Object");
	DocumentSales.FillInDefaultSalesConditions();
	ValueToFormAttribute(DocumentSales, "Object");
	
	If ValueIsFilled(Object.Currency) Then
		If DocumentCurrency <> Object.Currency Then
			DocumentCurrency = Object.Currency;
			
			FillInPriceTypes();
		EndIf;
	EndIf;
	
	FillInNewPriceView();
	
	SalesServer.SetContractAvailability(Object, Items.Contract.Enabled, Items.Contract.Visible,
		Object.Contract);
	
	FillInServiceDetailsForProductRange();
	PurchasesServer.FillInServiceAttributesOfCCDNumber(Object.Goods);
	
	If UseLinesOfBusiness Then
		LinesOfBusinessServer.FillInDefaultDirection(Object.LineOfBusiness, Object.Terms, Object.Contract);
		SetLBEditingOption();
	EndIf;
	
	If DirectionsOfActivity <> Object.LineOfBusiness Then
		LinesOfBusinessServer.WhenChangingDirectionOfActivity(ThisObject);
		ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);
	EndIf;
	
	ResponsiblePersonsServer.WhenChangingRelatedDocumentDetails(Object);
	
EndProcedure

&AtServer
Procedure CounterpartyOnChangeServer()
	
	DirectionsOfActivity = Object.LineOfBusiness;
	
	If ValueIsFilled(Object.Counterparty) Then
		FillInDefaultContract();
	EndIf;
	
	SalesServer.SetContractAvailability(Object, Items.Contract.Enabled, Items.Contract.Visible,
		Object.Contract);
	
	If UseLinesOfBusiness Then
		SetLBEditingOption();
	EndIf;
	
	If DirectionsOfActivity <> Object.LineOfBusiness Then
		LinesOfBusinessServer.WhenChangingDirectionOfActivity(ThisObject);
		ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);
	EndIf;
	
EndProcedure

&AtServer
Procedure TermsOnChangeServer()
	
	DirectionsOfActivity = Object.LineOfBusiness;
	
	DocumentSales = FormAttributeToValue("Object");
	DocumentSales.FillInTermsOfSalesUnderAgreement();
	ValueToFormAttribute(DocumentSales, "Object");
	
	SalesServer.SetContractAvailability(Object, Items.Contract.Enabled, Items.Contract.Visible,
		Object.Contract);
	
	If UseLinesOfBusiness Then
		SetLBEditingOption();
	EndIf;
	
	FillInServiceDetailsForProductRange();
	PurchasesServer.FillInServiceAttributesOfCCDNumber(Object.Goods);
	
	If DirectionsOfActivity <> Object.LineOfBusiness Then
		LinesOfBusinessServer.WhenChangingDirectionOfActivity(ThisObject);
		ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);
	EndIf;
	
	ResponsiblePersonsServer.WhenChangingRelatedDocumentDetails(Object);
	
	If DocumentCurrency <> Object.Currency Then
		DocumentCurrency = Object.Currency;
		
		FillInPriceTypes();
	EndIf;
	
	FillInNewPriceView();
	
EndProcedure

&AtServer
Procedure BusinessOperationWhenChangingOnServer()
	
	OriginalPriceView = Object.PriceKind;
	
	ConsignmentSales25 = ThisIsRegistrationWithCommissionAgent();
	ShipmentWithDeferredTransferOfTitle25 = ThisIsRegistrationOfShippedItems(Object.BusinessOperation);
	
	DocumentSales = FormAttributeToValue("Object");
	DocumentSales.FillInDefaultSalesConditions();
	ValueToFormAttribute(DocumentSales, "Object");
	
	If DocumentCurrency <> Object.Currency Then
		DocumentCurrency = Object.Currency;
		
		FillInPriceTypes();
	EndIf;
	
	FillInNewPriceView();
	
	If Not ValueIsFilled(Object.Ref) Then
		AutoTitle = False;
		
		GenerateHeaderFromTypeOfBusinessTransaction();
	Else
		AutoTitle = True;
	EndIf;
	
	UpdateInformationOnOrders();
	
	CustomizeForm();
	FillInServiceDetailsForProductRange();
	
	If ToUseTermsOfSales
		And ValueIsFilled(Object.Terms)
		And Not ContractBusinessTransaction = Common.ObjectAttributeValue(Object.Terms, "BusinessOperation") Then
		
		Object.Terms = Undefined;
		
	EndIf;
		
	If ValueIsFilled(Object.Contract)
		And Not ContractBusinessTransaction = Common.ObjectAttributeValue(Object.Contract, "BusinessOperation") Then
		
		Object.Contract = Undefined;
		
	EndIf;
	
	If UseLinesOfBusiness Then
		SetLBEditingOption();
	EndIf;
	
	SeriesSpecificationParameters = SeriesSpecificationParameters();
	
	ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);
	PurchasesServer.FillInServiceAttributesOfCCDNumber(Object.Goods);
	
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
	
	SalesServer.SetContractAvailability(Object, Items.Contract.Enabled, Items.Contract.Visible,
		Object.Contract);
	
	If UseLinesOfBusiness Then
		SetLBEditingOption();
	EndIf;
	
	FillInSubordinatePropertiesForStatistics("Organization");
	
	If DirectionsOfActivity <> Object.LineOfBusiness Then
		LinesOfBusinessServer.WhenChangingDirectionOfActivity(ThisObject);
		ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);
	EndIf;
	
	ResponsiblePersonsServer.WhenChangingRelatedDocumentDetails(Object);
	
	FillInNewPriceView();
	RecalculateNumberOfRNPT();
	
EndProcedure

&AtServer
Procedure ContractOnChangeServer()
	
	Contract = Object.Contract;
	Object.Currency = Common.ObjectAttributeValue(Contract, "ARAPCurrency");
	
	If DocumentCurrency <> Object.Currency Then
		OriginalPriceView = Catalogs.TypesOfPrices.EmptyRef();
		DocumentCurrency = Object.Currency;
		
		FillInPriceTypes();
	EndIf;
		
	If ThisIsRegistrationWithCommissionAgent() Then
		NewKindOfPrice = ConsignmentSalesServer.TypeOfContractPrice(Contract, True)
	EndIf;
	
	If UseLinesOfBusiness Then
		LinesOfBusinessServer.FillInDefaultDirection(Object.LineOfBusiness, Object.Terms, Contract);
		SetLBEditingOption();
		ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);
	EndIf;
	
EndProcedure

&AtClient
Procedure AskQuestionWhenChangingPriceType()
	
	If ValueIsFilled(NewKindOfPrice)
		And Not OriginalPriceView = NewKindOfPrice Then
		
		If Object.Goods.Count() > 0 Then
			CallbackDescription = New CallbackDescription("PriceKindOnChangeCompletion", ThisObject);
			
			QueryText = NStr("vi = 'Điền đơn giá theo dạng giá ""%PriceKind%""?';
							|ru = 'Заполнить цены по виду цен ""%PriceKind%""?';
							|en = 'Fill in prices by price type ""%PriceKind%""?'; fa = 'Fill in prices by price type ""%PriceKind%""?';
							|it = 'Compilare i prezzi per il tipo di prezzi ""%PriceKind%""?';
							|pl = 'Podaj ceny według rodzaju ceny ""%PriceKind%""?';
							|tr = 'Fiyatlar, ""%PriceKind%"" fiyat türüne göre doldurulsun mu?'");
			QueryText = StrReplace(QueryText, "%PriceKind%", NewKindOfPrice);
			
			ShowQueryBox(CallbackDescription, QueryText, QuestionDialogMode.YesNo, , DialogReturnCode.Yes);
		Else
			Object.PriceKind = NewKindOfPrice;
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure PriceKindOnChangeCompletion(QuestionResult, AdditionalParameters) Export
	
	If QuestionResult = DialogReturnCode.Yes Then
		Object.PriceKind = NewKindOfPrice;
		PricesCalculated = FillInPricesByPriceKindServer();
		
		SalesClient.NotifyAboutEndOfFillingInPricesByTypeOfPrices(PricesCalculated, NewKindOfPrice);
	ElsIf Not Object.PriceKind = OriginalPriceView Then
		Object.PriceKind = OriginalPriceView;
	EndIf;
	
EndProcedure

&AtServer
Procedure LineOfBusinessOnChangeServer()
	
	LinesOfBusinessServer.WhenChangingDirectionOfActivity(ThisObject);
	ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);
	
EndProcedure

#EndRegion

#Region WorkingWithCounterparties





#EndRegion

#Region Filling_By_Order

&AtClient
Procedure CustomerSChoice(ValueSelected, Var_Parameters) Export
	
	If ValueSelected <> Undefined Then
		Modified  = True;
		
		If Object.Goods.Count() > 0 Then
			NotificationParameters = New Structure("ValueSelected", ValueSelected);
			CallbackDescription  = New CallbackDescription("CustomerSChoiceCompletion",
															ThisObject,
															NotificationParameters);
			
			QueryText = NStr("vi = 'Các dòng trong danh sách Hàng hóa sẽ được điền lại theo lệnh đã chọn. Tiếp tục?';
							|ru = 'Строки в списке Товары будут перезаполнены по выбранному распоряжению. Продолжить?';
							|en = 'This will re-populate rows in the Item list based on the selected references. Continue?'; fa = 'This will re-populate rows in the Item list based on the selected references. Continue?';
							|it = 'Le righe nell''elenco Merci verranno ricompilate in base alla disposizione selezionata. Continuare?';
							|pl = 'Wiersze na liście Wiersze pozycji zostaną wypełnione ponownie zgodnie z wybranym zaówieniem. Kontynuować?';
							|tr = 'Ürünler listesindeki satırlar seçilen sipariş tarafından yeniden doldurulacaktır. Devam edilsin mi?'");
			
			ShowQueryBox(CallbackDescription, QueryText, QuestionDialogMode.YesNo);
		Else
			FillInByOrderServer(ValueSelected);
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure CustomerSChoiceCompletion(QuestionResult, AdditionalParameters) Export
	
	If QuestionResult = DialogReturnCode.No Then
		Return;
	EndIf;
	
	Object.Goods.Clear();
	FillInByOrderServer(AdditionalParameters.ValueSelected);
	
EndProcedure

&AtServer
Procedure PresentationOfOrderServer()
	
	AddChangeOrderCommand = AccessRight("Update", Metadata.Documents.RecognitionOfStockSurplusShippedToCustomer);
	
	LinkOrder = "<a href='Open_Order'>%1</a>";
	InscriptionOrder = "‹%1›";
	LinkToChangeOrder = "<a href='SelectReference'>%2</a>";
	ReferencesArrray = New Array;
	
	If ValueIsFilled(Object.ReferenceOrder) Then
		
		ReferencesArrray.Add(LinkOrder);
		OrderHeader = String(Object.ReferenceOrder);
		
	Else
		
		ReferencesArrray.Add(InscriptionOrder);
		OrderHeader = NStr("ru = 'не выбрано';
							|vi = 'not selected';
							|en = 'not selected'; fa = 'not selected';
							|it = 'не выбрано';
							|pl = 'not selected';
							|tr = 'seçilmedi'");
		
	EndIf;
	
	CommandTitle = Undefined;
	If AddChangeOrderCommand Then
		
		ReferencesArrray.Add(LinkToChangeOrder);
		
		If ValueIsFilled(Object.ReferenceOrder) Then
			CommandTitle = NStr("vi = 'Thay đổi';
								|ru = 'Изменить';
								|en = 'Change'; fa = 'تغییر';
								|it = 'Change';
								|pl = 'Change';
								|tr = 'Değiştir'");
		Else
			CommandTitle = NStr("vi = 'Chọn';
								|ru = 'Выбрать';
								|en = 'Select'; fa = 'انتخاب';
								|it = 'Выбрать';
								|pl = 'Select';
								|tr = 'Seç'");
		EndIf;
		
	EndIf;
	
	ReferenceOrderPresentation = StringFunctions.FormattedString(
		StrConcat(ReferencesArrray, " "),
		OrderHeader,
		CommandTitle);
	
EndProcedure

&AtServer
Procedure FillInByOrderServer(ReferenceOrder)
	
	If Not ValueIsFilled(ReferenceOrder) Then
		Return;
	EndIf;
	
	Object.ReferenceOrder = ReferenceOrder;
	
	InvoiceManager = Documents.RecognitionOfStockSurplusShippedToCustomer;
	
	HeaderAttributes = InvoiceManager.HeaderAttributes();
	FillPropertyValues(HeaderAttributes, Object);
	
	GoodsTable = Object.Goods.Unload();
	
	AnArrayOfOrders = CommonClientServer.ValueInArray(ReferenceOrder);
	
	FillParameters = InvoiceManager.DocumentFillingParameters();
	InvoiceManager.InitializeFillingParameters(FillParameters, HeaderAttributes, AnArrayOfOrders);
	
	InvoiceManager.FillInByOrdersOrders(GoodsTable, Object.Ref, FillParameters);
	
	TableColumn2 = GoodsTable.Columns.Count; // ValueTableColumn
	TableColumn2.Name = "QuantityBeforeChange_";
	
	TableColumn2 = GoodsTable.Columns.QuantityInOrder; // ValueTableColumn
	TableColumn2.Name = "Count";
	
	Object.Goods.Load(GoodsTable);
	
	StructureOfActions = New Structure;
	AccountingForTraceableGoodsClientServerLocalization.CompleteDescriptionOfSettingsForFillingInServiceDetailsOfTablePart(StructureOfActions);
	AccountingForTraceableGoodsClientServerLocalization.AddDescriptionOfSettingsForRecalculatingDetailsOfTablePart(
		Object,
		StructureOfActions,
		"Contract");
	
	BatchProcessingOfTablePartServer.TreatTS(
		Object.Goods,
		StructureOfActions);
	
	FillInServiceDetailsForProductRange();
	ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);
	
	UpdateInformationOnOrders();
	
EndProcedure

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
	If ShipmentWithDeferredTransferOfTitle25 Then 
		ArrayOfProductTypes = CommonClientServer.ValueInArray(Enums.ItemsTypes.OwnGoods);
		FilterParameters.Insert("Products.ItemsType", ArrayOfProductTypes);
	Else
		FilterParameters.Insert("Products.ItemsType", ProductsClientServer.SelectionByProductMultiTurnContainer(False));
	EndIf;
	
	Columns = "Products,Characteristic,Count,QuantityByGBRN,CCDNumber";
	If ShipmentWithDeferredTransferOfTitle25 Then
		Columns = Columns + ",Sum,AmountIncludingVAT";
	EndIf;
	
	TableOfGoods = ProcessingOfTabularForms.RowsFromClipboard(FilterParameters, Columns);
	
	If Not ValueIsFilled(TableOfGoods) Then
		Return;
	EndIf;
	
	If TableOfGoods.Columns.Find("AmountIncludingVAT") <> Undefined Then
		
		If TableOfGoods.Columns.Find("Sum") <> Undefined Then
			TableOfGoods.Columns.Delete("Sum");
		EndIf;
		
		TableColumn2 = TableOfGoods.Columns.AmountIncludingVAT; // ValueTableColumn
		TableColumn2.Name = "Sum";
		
	EndIf;
	
	StructureOfActions    = New Structure;
	LinesOfBusinessClientServer.StructureOfInsertActionsWhenAddingRow(ThisObject, StructureOfActions);
	StructureOfActions.Insert("RecalculatePriceByAmount", "Count");
	
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
	PurchasesServer.FillInServiceAttributesOfCCDNumber(Object.Goods);
	ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);
	
EndProcedure

#EndRegion

#Region InventoryKinds

&AtServer
Procedure GetStockTypesFromStorage(ValueSelected)
	
	InventoriesServer.ProcessInputOfInventoryTypesManually(ValueSelected, ThisObject);
	
EndProcedure

#EndRegion

#Region SelectionAndProcessingOfQuantityVerification

&AtServer
Procedure SelectionProcessingSelectionOfTransferredGoods(ValueSelected)
	
	TableOfGoods = GetFromTempStorage(ValueSelected.GoodsAddressInStorage);
	
	For Each RowOfProduct In TableOfGoods Do
		
		ProductsSearch = New Structure();
		ProductsSearch.Insert("Products", RowOfProduct.Products);
		ProductsSearch.Insert("Characteristic", RowOfProduct.Characteristic);
		ProductsSearch.Insert("Purpose", RowOfProduct.Purpose);
		ProductsSearch.Insert("CCDNumber", RowOfProduct.CCDNumber);
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
		
		If ShipmentWithDeferredTransferOfTitle25 And ValueIsFilled(Object.ReferenceOrder) Then
			CurrentRow.ReferenceOrder = Object.ReferenceOrder;
		EndIf;
		
	EndDo;
	
	FillInPricesByPriceKindServer();
	FillInServiceDetailsForProductRange();
	PurchasesServer.FillInServiceAttributesOfCCDNumber(Object.Goods);
	ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);
	RecalculateNumberOfRNPT();
	
EndProcedure

&AtServer
Function PlaceGoodsInStorageForSelectionOfTransferredGoods()
	
	Address = PutToTempStorage(
		Object.Goods.Unload(,"LineNumber, Products, Characteristic, Purpose, CCDNumber, Series, Count"),
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
	
	StructureOfActions = New Structure;
	AddActionsToStructureWhenQuantityChanges(StructureOfActions, Object);
	
	GoodsTable   = GetFromTempStorage(ReturnParameters.Goods);
	LinesToDelete = New Array;
	RowsToProcess = New Array();
	
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
				RowsToProcess.Add(TSRow);
			EndIf;
			
		EndDo;
		
		If FoundRows.Count() = 0 Then
			TSRow = Object.Goods.Add();
			FillPropertyValues(TSRow, SourceRow);
			
			TSRow.Count = SourceRow.NumberOfPackages;
			RowsToProcess.Add(TSRow);
		EndIf;
		
	EndDo;
	
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		RowsToProcess,
		StructureOfActions,
		Object.Goods,
		CachedValues);
	
	For Each TSRow In LinesToDelete Do
		Object.Goods.Delete(TSRow);
	EndDo;
	
	FillInServiceDetailsForProductRange();
	PurchasesServer.FillInServiceAttributesOfCCDNumber(Object.Goods);
	ProductsServer.FillInStatusesForSpecifyingSeries(Object,SeriesSpecificationParameters);
	
EndProcedure

&AtServer
Function AddressInvoiceGoods()
	
	ColumnDescriptionNumberOfPackages = New TypeDescription("Number",
		New NumberQualifiers(15, 3, AllowedSign.Nonnegative));
	
	Table = Object.Goods.Unload(); // ValueTable -
	Table.Columns.Add("NumberOfPackages", ColumnDescriptionNumberOfPackages);
	
	ColumnValuesQuantity = Table.UnloadColumn("Count");
	Table.LoadColumn(ColumnValuesQuantity, "NumberOfPackages");
	
	AddressInTempStorage = PutToTempStorage(Table, UUID);
	
	Return AddressInTempStorage;
	
EndFunction

&AtServer
Procedure ProcessingProductSelectionFromOrder(AddressInStorage)
	
	FieldsNames = Documents.RecognitionOfStockSurplusShippedToCustomer.KeyFieldsOfGoodsTable();
	
	Table = GetFromTempStorage(AddressInStorage).Goods; // ValueTable -
	Table.Sort(FieldsNames + " Desc");
	
	Table.Columns.Delete("Count");
	Table.Columns["NumberOfPackages"].Name = "Count";
	
	RowsRecalculateAmount = New Array;
	
	// Grouping a table by row keys.
	StringTree = New Array;
		
	For Each TableRow In Table Do
		
		If TableRow.QuantityInOrder <> TableRow.Count Then
			RowsRecalculateAmount.Add(TableRow);
		EndIf;
		
		RowsArray = New Array;
		RowsArray.Add(TableRow);
		
		StringTree.Add(RowsArray);
		
	EndDo;
	
	ActionsToRecalculateAmount = New Structure("RecalculateAmount", "Count");
	BatchProcessingOfTablePartServer.ProcessTSStrings(RowsRecalculateAmount, ActionsToRecalculateAmount, Table);
	
	InvoicesServer.FillInProductsSelectedFromOrder(StringTree, FieldsNames, Object.Goods, New Structure);
	
	StructureOfActions = New Structure;
	AccountingForTraceableGoodsClientServerLocalization.CompleteDescriptionOfSettingsForFillingInServiceDetailsOfTablePart(StructureOfActions);
	
	BatchProcessingOfTablePartServer.TreatTS(
		Object.Goods,
		StructureOfActions);
	
	UpdateInformationOnOrders();
	FillInServiceDetailsForProductRange();
	ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);
	
	LinesOfBusinessServer.SetVisibilityOfElementsSeparately(ThisObject);
	LinesOfBusinessServer.ReFillInServiceDetailsOfTablePart(ThisObject);
	
EndProcedure

#EndRegion

#Region SetOfSeries

&AtServer
Function SeriesSpecificationParameters()
	
	ObjectManager = Documents.RecognitionOfStockSurplusShippedToCustomer;
	
	Return New FixedStructure(ProductsServer.SeriesSpecificationParameters(Object, ObjectManager));
	
EndFunction

&AtServer
Procedure SetVisibilityOfSeriesElements()
	
	Items.GoodsSpecifySeries.Visible        = SeriesSpecificationParameters.UseItemsBatch;
	Items.GoodsSeries.Visible               = SeriesSpecificationParameters.UseItemsBatch;
	Items.GoodsBatchesIndicationStatus.Visible = SeriesSpecificationParameters.UseItemsBatch;
	
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
		CallbackDescription          = New CallbackDescription("OpenSelectionOfSeriesCompletion",
																ThisObject,
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
Function ParametersOfSeriesIndicationForm(CurDataId)
	
	Return ProductsServer.ParametersOfSeriesIndicationForm(Object,
															SeriesSpecificationParameters,
															CurDataId,
															ThisObject);
	
EndFunction

&AtServer
Procedure ProcessSeriesIndication_Server(ParametersOfSeriesIndicationForm)
	
	ProductsServer.ProcessSeriesIndication_(Object, SeriesSpecificationParameters, ParametersOfSeriesIndicationForm);
	
EndProcedure

&AtServer
Procedure FillInStatusesOfSpecifyingSeriesWhenEditingLineTS(IDCurrentRow, CachedValues)
	
	ProductsServer.FillInStatusesOfSpecifyingSeriesWhenEditingLineTS(Object,
																						SeriesSpecificationParameters,
																						IDCurrentRow,
																						CachedValues);
	
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
	
	CCDNumberSelectionParameters = PurchasesServer.CCDNumberSelectionParameters();
	CCDNumberSelectionParameters.FieldNameNumberOfPackages = "Count";
	
	ProcessingActions = New Structure;
	
	If SelectionData_1.ResidualNumberOfCCD <> Undefined Then
		AddActionsToStructureWhenQuantityChanges(ProcessingActions, Object);
	Else
		AccountingForTraceableGoodsClientServerLocalization.AddDescriptionOfSettingsForRecalculatingDetailsOfTablePart(
			Object,
			ProcessingActions);
	EndIf;
	
	PurchasesServer.ProcessIndicationOfCCDNumber(ThisObject,
												RowID,
												SelectionData_1,
												CCDNumbersFilledIn,
												CCDNumberSelectionParameters,
												ProcessingActions);
	
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

&AtServer
Procedure FillInCCDNumbersOnServer(Val CCDNumber, CCDNumbersFilledIn)
	
	FillParameters = PurchasesServer.ParametersForFillingInGTDVNumberOfTabularPart();
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
	
	// Setting the conditional design for the items of the nomenclature of the tabular part 'Goods'
	ProductsServer.EstablishConditionalAppearanceOfProductCharacteristics(ThisObject);
	ProductsServer.SetConditionalAppearanceOfProductAssignment(ThisObject);
	ProductsServer.EstablishConditionalAppearanceOfProductSeries(ThisObject, "SeriesAlwaysWHGoods");
	ProductsServer.SetConditionalAppearanceOfStatusIndicationSeries(ThisObject, True);
	
	ConditionalDesignParameters = ProductsServer.ParametersForSettingConditionalAppearanceOfCCDNumber();
	ConditionalDesignParameters.NameOfFieldForEnteringCCDNumber = "GoodsOriginCountry";
	
	ProductsServer.SetConditionalAppearanceOfCCDNumber(ThisObject);
	ProductsServer.SetConditionalAppearanceOfCCDNumber(ThisObject, ConditionalDesignParameters);
	
	// Setting the conditional design for the elements 'NomerGTD' and 'Country of origin' of the tabular part 'Goods'
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsCCDNumber.Name);
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsOriginCountry.Name);
	
	TypesOfGoods = New ValueList;
	TypesOfGoods.Add(Enums.ItemsTypes.OwnGoods);
	TypesOfGoods.Add(Enums.ItemsTypes.ReusablePackage);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.ItemsType");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotInList;
	ItemFilter.RightValue = TypesOfGoods;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.EmptyTableField);
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<cho hàng hóa>';
													|ru = '<для товаров>';
													|en = '<for goods>'; fa = '<for goods>';
													|it = '<per le merci>';
													|pl = '<dla towarów>';
													|tr = '<ürünler için>'"));
	Item.Appearance.SetParameterValue("ReadOnly", True);
	
	// Setting the conditional design of the order submission element
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ReferenceOrderPresentation.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.ReferenceOrder");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.ResultIssueColor);
	
	// Blocking the 'price' column if the price type is specified
	If GetFunctionalOption("UseSeveralPriceTypes") Then
		Item = ConditionalAppearance.Items.Add();
		
		ItemField = Item.Fields.Items.Add();
		ItemField.Field = New DataCompositionField(Items.GoodsPrice.Name);
		
		ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
		ItemFilter.LeftValue = New DataCompositionField("Object.PriceKind");
		ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
		
		Item.Appearance.SetParameterValue("ReadOnly", True);
	EndIf;
	
	// Setting the conditional design for the 'Order' element of the 'Goods' tabular part

	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsReferenceOrder.Name);
	
	FilterGroup1 = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup1.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	
	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.ReferenceOrder");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	
	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("UseShipmentForMultipleOrders");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;

	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ShipmentWithDeferredTransferOfTitle25");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	Item.Appearance.SetParameterValue("Visible", False);
	
	//
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsReferenceOrder.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.ReferenceOrder");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	
	Item.Appearance.SetParameterValue("ReadOnly", True);
	
	//
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsReferenceOrder.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.ReferenceOrder");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.HyperlinkColor);
	
	//
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsReferenceOrder.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.ReferenceOrder");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.ReferenceOrder");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.ErrorNoteText);
	Item.Appearance.SetParameterValue("Text", NStr("vi = 'Vượt quá lệnh, chưa chọn lệnh';
													|ru = 'Сверх распоряжения, распоряжение не выбрано';
													|en = 'In excess of reference. Reference is not selected'; fa = 'In excess of reference. Reference is not selected';
													|it = 'In excess of reference. Reference is not selected';
													|pl = 'In excess of reference. Reference is not selected';
													|tr = 'Sipariş iptal edildi, hiçbir sipariş seçilmedi'"));
	
	// Setting the conditional design for the 'Division' element
	InventoriesServer.EstablishConditionalAppearanceOfDivisionForTypesOfStocks(ThisObject);
	
	// Setting the conditional design for the 'Activity Direction' element
	LinesOfBusinessServer.EstablishConditionalAppearanceOfDirectionOfActivity(ThisObject);
	
	//
	AccountingForTraceableGoodsLocalization.SetConditionalAppearanceOfQuantityAccordingToRNPT(ThisObject);
	
	// Setting the conditional design for the type of prices
	EnterprisePricesFillingServer.EstablishConditionalAppearanceOfPriceTypes(ThisObject, "PriceKind", "Object.PriceKind");
	
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
	
	RestrictGoodsReceiptWithoutCCDNumbers = GetFunctionalOption("RestrictGoodsReceiptWithoutCCDNumbers");
	UseLinesOfBusiness =
		GetFunctionalOption("UseIncomeAccountingByLinesOfBusiness");
	ToUseTermsOfSales         = GetFunctionalOption("ToUseTermsOfSales");
	UsePartnersAsCounterparties     = GetFunctionalOption("UsePartnersAsCounterparties");

	UseTraceableImportedGoodsAccounting =
		AccountingForTraceableGoodsLocalization.UseTraceableImportedGoodsAccounting(Object.Date);
	UseShipmentForMultipleOrders =
		GetFunctionalOption("UseSaleByMultipleOrders");
	
	SeriesSpecificationParameters = SeriesSpecificationParameters();
	ConsignmentSales25  = ThisIsRegistrationWithCommissionAgent();
	DocumentCurrency        = Object.Currency;
	ShipmentWithDeferredTransferOfTitle25 = ThisIsRegistrationOfShippedItems(Object.BusinessOperation);
	
	CustomizeForm();
	FillOperationSelectionList();
	UpdateInformationOnOrders();
	SetVisibilityOfSeriesElements();
	If UseLinesOfBusiness Then
		SetLBEditingOption();
	EndIf;
	FillInServiceDetailsForProductRange();
	FillInPriceTypes();
	PurchasesServer.FillInServiceAttributesOfCCDNumber(Object.Goods);
	SalesServer.SetContractAvailability(Object, Items.Contract.Enabled, Items.Contract.Visible);
	
	LinesOfBusinessServer.OnReadCreateAtServer(ThisObject);
	
EndProcedure

&AtServer
Procedure FillInServiceDetailsForProductRange()
	
	FillInArticleAttribute                    = New Structure("Products", "SKU");
	FillInProductTypeAttribute_            = New Structure("Products", "ItemsType");
	FillInFeatureAttribute = New Structure("Products", "ItemVariantsAreUsed");
	FillInCCDTrackingAttribute           = New Structure("Products", "TheRecordsAreKeptByCCD");
	
	ParametersForFillingInBankingDetails = New Structure;
	ParametersForFillingInBankingDetails.Insert("FillInArticleAttribute",          FillInArticleAttribute);
	ParametersForFillingInBankingDetails.Insert("FillInProductTypeAttribute_",  FillInProductTypeAttribute_);
	ParametersForFillingInBankingDetails.Insert("FillInFeatureAttribute",
											FillInFeatureAttribute);
	ParametersForFillingInBankingDetails.Insert("FillInCCDTrackingAttribute", FillInCCDTrackingAttribute);
	
	AccountingForTraceableGoodsClientServerLocalization.CompleteDescriptionOfSettingsForFillingInServiceDetailsOfTablePart(ParametersForFillingInBankingDetails);
	
	ProductsServer.FillInServiceDetailsForProductInCollection(Object.Goods, ParametersForFillingInBankingDetails);
	
EndProcedure

&AtServer
Procedure FillInSubordinatePropertiesForStatistics(ParentPropsName)
	
	ObjectsFillingByStatistics.FillInSubordinateDetailsOfObject(Object, ParentPropsName);
	
EndProcedure

&AtServer
Procedure FillInDefaultContract()
	
	CommissionSalesSelection25 = ThisIsRegistrationWithCommissionAgent();
	LineOfBusiness = ?(UseLinesOfBusiness, Object.LineOfBusiness, Undefined);
	
	DefaultContract = SalesServer.GetDefaultContract(Object,
																	ContractBusinessTransaction,
																	Object.Currency,
																	LineOfBusiness,
																	CommissionSalesSelection25);
	
	If Object.Contract <> DefaultContract Then
		Object.Contract = DefaultContract;
		
		FillInNewPriceView();
	EndIf;
	
EndProcedure

&AtServer
Procedure GoodsAfterDeleteRowServer(SeriesStatusesNeedToBeUpdated, CachedValues)
	
	If SeriesStatusesNeedToBeUpdated Then
		FillInStatusesOfSpecifyingSeriesWhenEditingLineTS(Undefined, CachedValues);
	EndIf;
	
	UpdateInformationOnOrders();
	
EndProcedure

&AtServer
Procedure GenerateHeaderFromTypeOfBusinessTransaction()
	
	Title = NStr("vi = 'Ghi tăng hàng thừa đang cất giữ và có quyền bán (tạo mới)';
				|ru = 'Оприходование излишков товаров на хранении с правом продажи (создание)';
				|en = 'Recognition of surplus of stored inventory with the right to sale (create)'; fa = 'Recognition of surplus of stored inventory with the right to sale (create)';
				|it = 'Accettazione eccedenze articoli in magazzino con diritto di vendita (creazione)';
				|pl = 'Rejestracja nadwyżek towarów na przechowywaniu z prawem sprzedaży (tworzenie)';
				|tr = 'Depodaki stok fazlası satılabilir malların kabulü (oluştur)'");
	
	If ThisIsRegistrationWithCommissionAgent() Then
		Title = NStr("vi = 'Ghi tăng hàng thừa của người nhận ký gửi (tạo mới)';
					|ru = 'Оприходование излишков товаров у комиссионера (создание)';
					|en = 'Stock surplus recognition at consignee (create)'; fa = 'Stock surplus recognition at consignee (create)';
					|it = 'Accettazione eccedenze articoli presso il commissionario (creazione)';
					|pl = 'Rejestracja nadwyżek towarów u komisanta (tworzenie)';
					|tr = 'Konsinye stok fazlası malları (oluştur)'");
	ElsIf ThisIsRegistrationOfShippedItems(Object.BusinessOperation) Then
		Title = NStr("vi = 'Ghi tăng hàng thừa đã giao cho khách (tạo mới)';
					|ru = 'Оприходование излишков товаров, отгруженных клиенту (создание)';
					|en = 'Recognition of stock surplus shipped to customer (create)'; fa = 'Recognition of stock surplus shipped to customer (create)';
					|it = 'Recognition of stock surplus shipped to customer (create)';
					|pl = 'Recognition of stock surplus shipped to customer (create)';
					|tr = 'Müşteriye sevk edilmiş stok fazlası ürünlerin tahakkuku (oluşturma)'");
	EndIf;
	
EndProcedure

&AtServer
Procedure FillOperationSelectionList()
	
	ChoiceList = Items.BusinessOperation.ChoiceList;
	
	If Items.Find("BusinessOperation") <> Undefined  Then
		
		If Not GetFormFunctionalOption("UseSalesCommission") Then
			ListItem = ChoiceList.FindByValue(Enums.BusinessTransactions.RecognizeInventorySurplusForTheBenefitOfConsignor);
			
			If ListItem <> Undefined Then
				ChoiceList.Delete(ListItem);
			EndIf;
		EndIf;
		
		If Not GetFormFunctionalOption("UseTransferToCustodyWithRightOfSale") Then
			ListItem = ChoiceList.FindByValue(Enums.BusinessTransactions.RecognizeInventorySurplusForTheBenefitOfDepositor);
			
			If ListItem <> Undefined Then
				ChoiceList.Delete(ListItem);
			EndIf;
		EndIf;
		
		If Not GetFormFunctionalOption("UseShipmentWithDeferredTransferOfTitle2_5") Then
			ListItem = ChoiceList.FindByValue(Enums.BusinessTransactions.RecognitionOfStockSurplusShippedToCustomer);
			
			If ListItem <> Undefined Then
				ChoiceList.Delete(ListItem);
			EndIf;
		EndIf;
		
		OnlyOperation = Items.BusinessOperation.ChoiceList.Count() = 1;
		
		If OnlyOperation
			And Not ValueIsFilled(Object.BusinessOperation) Then
			
			Object.BusinessOperation = ChoiceList[0].Value;
			
			BusinessOperationWhenChangingOnServer();
			
		EndIf;
		
		FieldPropertyValue = OnlyOperation
								And ValueIsFilled(Object.BusinessOperation);
		
		TMCommonUseClientServer.SetFormItemProperty(
			Items,
			"BusinessOperation",
			"ReadOnly",
			FieldPropertyValue);
		
	EndIf;
	
EndProcedure

&AtServer
Function FillInPricesByPriceKindServer(RowID = Undefined)
	
	If RowID = Undefined Then
		RowsArray = Undefined;
	Else
		RowsArray = New Array;
		RowsArray.Add(Object.Goods.FindByID(RowID));
	EndIf;
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateAmount", "Count");
	
	ColumnsByValue = New Structure("Package", Catalogs.PackagesAndUnitsOfMeasure.EmptyRef());
	
	FillParameters = New Structure;
	
	FillParameters.Insert("Date", Object.Date);
	FillParameters.Insert("Organization", Object.Organization);
	FillParameters.Insert("Currency", Object.Currency);
	FillParameters.Insert("PriceKind", Object.PriceKind);
	FillParameters.Insert("ColumnsByValue", ColumnsByValue);
	
	Return EnterprisePricesFillingServer.FillInPrices(
		Object.Goods, // Table part
		RowsArray, // Selected lines (fill in all lines)
		FillParameters,
		StructureOfActions);
	
EndFunction

&AtServer
Procedure FillInNewPriceView()
	
	OriginalPriceView = Object.PriceKind;
	
	If ThisIsRegistrationWithCommissionAgent() Then
		NewKindOfPrice = ConsignmentSalesServer.TypeOfContractPrice(Object.Contract, True);
	ElsIf ValueIsFilled(Object.Terms) Then
		NewKindOfPrice = Common.ObjectAttributeValue(Object.Terms, "PricesKind");
	EndIf;
	
EndProcedure

&AtServer
Function ThisIsRegistrationWithCommissionAgent()
	
	Return Object.BusinessOperation = Enums.BusinessTransactions.RecognizeInventorySurplusForTheBenefitOfConsignor;
	
EndFunction

&AtClientAtServerNoContext
Function ThisIsRegistrationOfShippedItems(BusinessOperation)
	
	Return BusinessOperation = PredefinedValue("Enum.BusinessTransactions.RecognitionOfStockSurplusShippedToCustomer");
	
EndFunction

&AtServer
Procedure FillInPriceTypes()
	
	SelectionParametersPriceType = New Array;
	SelectionParametersPriceType.Add(New ChoiceParameter("OutputAnArbitraryTypeOfPrices", True));
	SelectionParametersPriceType.Add(New ChoiceParameter("Filter.Status",               Enums.StatusesOfPriceTypeValidity.Valid));
	SelectionParametersPriceType.Add(New ChoiceParameter("UseWhileSellingToCustomers",     True));
	SelectionParametersPriceType.Add(New ChoiceParameter("Filter.IsFolder",            False));
	SelectionParametersPriceType.Add(New ChoiceParameter("Filter.DeletionMark",      False));
	SelectionParametersPriceType.Add(New ChoiceParameter("Filter.PriceCurrency",           Object.Currency));
	
	Items.PriceKind.ChoiceParameters = New FixedArray(SelectionParametersPriceType);
	
	If Not ReadOnly
		And ValueIsFilled(Object.PriceKind) Then
		
		AttributesValues = Common.ObjectAttributesValues(Object.PriceKind, "UseWhileSellingToCustomers, PriceCurrency");
		
		If Not AttributesValues.UseWhileSellingToCustomers
			Or AttributesValues.PriceCurrency <> Object.Currency Then
			
			Object.PriceKind = Catalogs.TypesOfPrices.EmptyRef();
			NewKindOfPrice   = Catalogs.TypesOfPrices.EmptyRef();
			
		EndIf;
	EndIf;
	
EndProcedure

&AtServer
Procedure RecalculateNumberOfRNPT()
	
	If ValueIsFilled(Object.Contract)
		And ValueIsFilled(Object.Organization) Then
		
		ParametersForObtainingRnptCoefficient = AccountingForTraceableGoodsClientServerLocalization.ParametersForObtainingRnptCoefficient(
												Object,
												"Contract");
		AccountingForTraceableGoodsLocalization.FillInQuantityByRNPTVOfTablePart(ParametersForObtainingRnptCoefficient,
																						Object.Goods);
		
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Procedure AddActionsToStructureWhenQuantityChanges(StructureOfActions, Object)
	
	StructureOfActions.Insert("RecalculateAmount","Count");
	AccountingForTraceableGoodsClientServerLocalization.AddDescriptionOfSettingsForRecalculatingDetailsOfTablePart(
		Object,
		StructureOfActions,
		"Contract");
		
EndProcedure

&AtServer
Procedure CustomizeForm()
	
	If ThisIsRegistrationWithCommissionAgent() Then
		ContractBusinessTransaction = Enums.BusinessTransactions.TransferToCommissionAgent;
	Else
		ContractBusinessTransaction = ?(ShipmentWithDeferredTransferOfTitle25,
			Enums.BusinessTransactions.SaleToCustomer,
			Enums.BusinessTransactions.TransferToStorageWithRightOfSale);
	EndIf;
	
	Items.Pages_Order.Visible = ShipmentWithDeferredTransferOfTitle25;
	Items.GoodsPickUpItemsByOrder.Visible = ShipmentWithDeferredTransferOfTitle25;
	Items.GoodsPurpose.Visible = Not ShipmentWithDeferredTransferOfTitle25;
	
	TitleText = NStr("vi = 'Chọn hàng hóa đã chuyển giao';
					|ru = 'Подобрать переданные товары';
					|en = 'Pick customer stock'; fa = 'انتخاب موجودی مشتری';
					|it = 'Selezionare le merci consegnate';
					|pl = 'Odbierz przeniesione wiersze pozycji';
					|tr = 'Transfer edilen malları seç'");
	
	If ShipmentWithDeferredTransferOfTitle25 Then
		TitleText = NStr("vi = 'Chọn hàng hóa đã giao';
						|ru = 'Подобрать отгруженные товары';
						|en = 'Pick shipped goods'; fa = 'Pick shipped goods';
						|it = 'Pick shipped goods';
						|pl = 'Pick shipped goods';
						|tr = 'Sevk edilen malları seç'");
	EndIf;
	
	Commands.SelectTransferredGoods.Title = TitleText;
	Commands.SelectTransferredGoods.ToolTip = TitleText;
	
	If ShipmentWithDeferredTransferOfTitle25 Then
		ChoiceParameter = New ChoiceParameter("Filter.ItemsType", Enums.ItemsTypes.OwnGoods);
		ChoiceParametersArray = CommonClientServer.ValueInArray(ChoiceParameter);
		Items.GoodsProducts.ChoiceParameters = New FixedArray(ChoiceParametersArray);
	EndIf;
	
	PartnersAndCounterparties.TitleOfPartnerElementDependingOnBusinessOperation(
		ThisObject, "Partner", Object.BusinessOperation);
	
EndProcedure

&AtClient
Procedure Attachable_CloseForm()
	
	If IsOpen() Then
		Close();
	EndIf;
	
EndProcedure

&AtServer
Procedure UpdateInformationOnOrders()
	
	If Not ShipmentWithDeferredTransferOfTitle25 Then
		
		Object.ReferenceOrder = Undefined;
		
		For Each TSRow In Object.Goods Do
			TSRow.ReferenceOrder = Undefined;
		EndDo;
		
		ListOfOrders_.Clear();
		
		Return;
	EndIf;
	
	Items.Pages_Order.Visible = True;
	Items.Pages_Order.Enabled = True;
	
	ListOfOrders_.Clear();
	InAllRowsThereIsOrder = True;
	For Each CurRow In Object.Goods Do
		If ValueIsFilled(CurRow.ReferenceOrder) Then
			If  ListOfOrders_.FindByValue(CurRow.ReferenceOrder) = Undefined Then
				ListOfOrders_.Add(CurRow.ReferenceOrder);
			EndIf;
		Else
			InAllRowsThereIsOrder = False;
		EndIf;
	EndDo;
	
	If ListOfOrders_.Count() = 1 And InAllRowsThereIsOrder Then
		Object.ReferenceOrder = ListOfOrders_[0].Value;
		PresentationOfOrderServer();
	ElsIf ListOfOrders_.Count() > 1 
		Or Not InAllRowsThereIsOrder Then
		Object.ReferenceOrder = Undefined;
	EndIf;
	
	If ListOfOrders_.Count() > 1 Then
		LabelTotalOrders = NStr("vi = 'Tổng số chứng từ';
								|ru = 'Всего документов';
								|en = 'Total documents'; fa = 'Total documents';
								|it = 'Total documents';
								|pl = 'Total documents';
								|tr = 'Belgelerin tümü'");
		InscriptionIsTitleOfOrders = LabelTotalOrders + ": " + ListOfOrders_.Count();
	EndIf;
	
	If ListOfOrders_.Count() <= 1 Then
		Items.Pages_Order.CurrentPage = Items.Page_Order;
		PresentationOfOrderServer();
	Else
		Items.Pages_Order.CurrentPage = Items.PageOfOrder;
		Items.PageOfOrder.Enabled = True;
	EndIf;
	
	If ValueIsFilled(Object.ReferenceOrder) Or Not UseShipmentForMultipleOrders Then
		Items.GoodsGroupReference.Group = ColumnsGroup.Vertical;
	Else
		Items.GoodsGroupReference.Group = ColumnsGroup.InCell;
	EndIf;
	
EndProcedure

&AtClient
Procedure OpenOrderSelection(CallbackDescription)

	NamesOfDocumentDetails =
		"Ref,
		|Partner,
		|Counterparty,
		|Terms,
		|Organization,
		|Contract,
		|SalesOpportunity,
		|Department,
		|LineOfBusiness,
		|Currency
		|";
		
	FormParameters = New Structure(NamesOfDocumentDetails);
	FillPropertyValues(FormParameters, Object);

	OpenForm("Document.RecognitionOfStockSurplusShippedToCustomer.Form.ReferenceChoiceForm",
	    FormParameters,
	    ThisObject,
	    ,
	    ,
	    ,
	    CallbackDescription,
	    FormWindowOpeningMode.LockOwnerWindow);

EndProcedure

&AtClient
Procedure SelectReferenceCompletion(Result, AdditionalParameters) Export
	
	Items.Goods.CurrentData.ReferenceOrder = Result;
	
	UpdateInformationOnOrders();
	
EndProcedure

&AtClient
Procedure OpenSelectionByOrders()
	
	AttributesNames =
		"Currency,
		|Contract,
		|Counterparty,
		|LineOfBusiness,
		|Organization,
		|Partner,
		|Department,
		|SalesOpportunity,
		|Terms,
		|Ref,
		|BusinessOperation
		|";

	HeaderAttributes = New Structure(AttributesNames);
	FillPropertyValues(HeaderAttributes, Object);
	
	FormParameters = New Structure;
	FormParameters.Insert("HeaderAttributes",                           HeaderAttributes);
	FormParameters.Insert("Invoice",                                Object.Ref);
	FormParameters.Insert("OrdersAreUsed",                       True);
	FormParameters.Insert("InvoiceForOrders",                       True);
	FormParameters.Insert("OrderDocument",                                    Object.ReferenceOrder);
	FormParameters.Insert("AdvancedWarehousingOnShipment",                 False);
	FormParameters.Insert("AdvancedWarehousingOnGoodsReceipt",              False);
	FormParameters.Insert("AddressGoods",                              AddressInvoiceGoods());
	FormParameters.Insert("UseInvoicesForSeveralOrders", UseShipmentForMultipleOrders);
	
	OpenForm("CommonForm.AddItemsFromSalesOrderGoodsIssue",
		FormParameters,
		ThisObject,
		UUID,
		,
		,
		,
		FormWindowOpeningMode.LockOwnerWindow);

EndProcedure

#Region StandardSubsystems_PlugInCommands

// StandardSubsystems.AttachableCommands
&AtClient
Procedure Attachable_ExecuteCommand(Command)
	AttachableCommandsClient.StartCommandExecution(ThisObject, Command, Object);
EndProcedure

&AtClient
Procedure Attachable_UpdateCommands()
	
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	
EndProcedure

&AtServer
Procedure ExecuteCommandAtServer(ExecutionParameters)
	AttachableCommands.ExecuteCommand(ThisObject, ExecutionParameters, Object);
EndProcedure
// End StandardSubsystems.AttachableCommands

#EndRegion

#Region StandardSubsystems_Properties

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
