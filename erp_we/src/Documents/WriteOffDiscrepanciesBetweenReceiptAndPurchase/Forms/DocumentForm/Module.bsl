#Region Variables

&AtClient
Var PreviousRowDetails; //used to unlink the receipt line from the order line

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
	
	// Handler of the "Properties" subsystem
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("Object", Object);
	AdditionalParameters.Insert("ItemForPlacementName", "GroupAdditionalAttributes");
	AdditionalParameters.Insert("DeferredInitialization", True);
	PropertyManager.OnCreateAtServer(ThisObject, AdditionalParameters);

	TMCommonUse.CustomizePeripherals(ThisObject);
	
	// Handler of the "Destination" mechanism
	Catalogs.Assignments.DocumentFormWhenCreatedOnServer(ThisObject);
	
	// Handler of the "Versioning of objects" mechanism
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	
	UsePartnersAsCounterparties = GetFunctionalOption("UsePartnersAsCounterparties");
	
	If Not ValueIsFilled(Object.Ref) Then
		OnReadCreateAtServer();
		
		ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);
	EndIf;
	
	// Selection of articles and analytics.
	ArticleAvailabilityParameters = New Structure("ThereAreOverpayments, ThereAreShortDeliveries", ThereisOverdelivery, ThereIsUnderdelivery);
	ItemsAndDimensionsSelectionParameters = Documents.WriteOffDiscrepanciesBetweenReceiptAndPurchase.ItemsAndDimensionsSelectionParameters(ArticleAvailabilityParameters);
	IncomeAndExpensesServer.OnCreateAtServer(ThisObject, ItemsAndDimensionsSelectionParameters);
	
	
	SetAvailabilityOfClipboardCommands();
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject);
	// End IntegrationWith1CDocumentManagementSubsystem
	
	DocumentCorrection.OnCreateAtServer(ThisObject, Items.LineCorrection);
	
	FormEvents.OnCreateAtServer(ThisObject, Cancel, StandardProcessing);
	
	// StandardSubsystems.FilesOperations
	HyperlinkParameters = FilesOperations.FilesHyperlink();
	HyperlinkParameters.Location = "CommandBar";
	FilesOperations.OnCreateAtServer(ThisObject, HyperlinkParameters);
	// End StandardSubsystems.FilesOperations
	SetupParameters = Documents.WriteOffDiscrepanciesBetweenReceiptAndPurchase.AccountingAccountSettings_();
	GLAccountSettingsServer.OnCreateAtServer(ThisObject, SetupParameters);	
	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)
	
	// StandardSubsystems.AccessManagement
	AccessManagement.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.AccessManagement
	
	// Handler of the "Date-change" mechanism
	PeriodClosingDates.ObjectOnReadAtServer(ThisObject, CurrentObject);
	
	OnReadCreateAtServer();
	
	PropertyManager.OnReadAtServer(ThisObject, CurrentObject);
	
	DocumentCorrection.OnReadAtServer(ThisObject, Items.LineCorrection);
	
	FormEvents.OnReadAtServer(ThisObject, CurrentObject);

	// Selection of articles and analytics.
	FillInSignsOfOverDeliveryUnderDelivery();
	ArticleAvailabilityParameters = New Structure("ThereAreOverpayments, ThereAreShortDeliveries", ThereisOverdelivery, ThereIsUnderdelivery);
	ItemsAndDimensionsSelectionParameters = Documents.WriteOffDiscrepanciesBetweenReceiptAndPurchase.ItemsAndDimensionsSelectionParameters(ArticleAvailabilityParameters);
	IncomeAndExpensesServer.OnReadAtServer(ThisObject, ItemsAndDimensionsSelectionParameters);
	SetupParameters = Documents.WriteOffDiscrepanciesBetweenReceiptAndPurchase.AccountingAccountSettings_();
	GLAccountSettingsServer.OnReadAtServer(ThisObject, SetupParameters);
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	// End StandardSubsystems.AttachableCommands
	
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
	
	DocumentCorrectionClient.NotificationProcessing(ThisObject, EventName, Parameter, Source);
	
	FormEventsClient.NotificationProcessing(ThisObject, EventName, Parameter, Source);
	
	// StandardSubsystems.FilesOperations
	FilesOperationsClient.NotificationProcessing(ThisObject, EventName);
	// End StandardSubsystems.FilesOperations
	
	
EndProcedure

&AtClient
Procedure ChoiceProcessing(SelectionResult, ChoiceSource)
	
	If ChoiceSource.FormName = "DataProcessor.SelectGoodsToPurchaseDocument.Form.Form" Then
		
		ProcessingSelectionOfSelectionOnServer(SelectionResult);
	ElsIf ProductsClient.ThisIsIndicationOfSeries(ChoiceSource) Then
		
		ProductsClient.ProcessSeriesIndication(ThisObject, SeriesSpecificationParameters, SelectionResult);
		
	ElsIf PurchasesClient.ThisIsIndicationOfCCDNumber(ChoiceSource) Then
		
		PurchasesClient.ProcessIndicationOfCCDNumber(ThisObject, SelectionResult);
	ElsIf ChoiceSource.FormName = "Catalog.Assignments.Form.ChoiceForm" Then
		
		Items.Discrepancies.CurrentData.Purpose = SelectionResult;
	EndIf;
	
	If Window <> Undefined Then
		Window.Activate();
	EndIf;
	
EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	
	// StandardSubsystems.Properties
	PropertyManager.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes);
	// End StandardSubsystems.Properties
	
EndProcedure

&AtClient
Procedure BeforeWrite(Cancel, WriteParameters)
	
	FormEventsClient.BeforeWrite(ThisObject, Cancel, WriteParameters);
	
	If NotExecuteCheck1BeforeWrite Then
		NotExecuteCheck1BeforeWrite = False;
		Return;
	EndIf;
	
	If WriteParameters.WriteMode = DocumentWriteMode.Posting Then
		
		Cancel = True;
		TMCommonUseClient.RecordObjectIfNecessary(ThisObject, WriteParameters,,True);
		Return;
		
	EndIf;
	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	// Handler of the "Properties" subsystem
	PropertyManager.BeforeWriteAtServer(ThisObject, CurrentObject);
	

	GLAccountSettingsServer.BeforeWriteAtServer(ThisObject, CurrentObject);
	ConfigurationModificationOverridable.BeforeWriteAtServer(ThisObject, Cancel, CurrentObject, WriteParameters);

	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.BeforeWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	// End IntegrationWith1CDocumentManagementSubsystem
	
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	
	Notify("Record_WriteOffOfDiscrepancies", WriteParameters, Object.Ref);
	
	DocumentCorrectionClient.AfterWrite(Object);
	
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
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)

	// StandardSubsystems.AccessManagement
	AccessManagement.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	// End StandardSubsystems.AccessManagement
	
	SetAvailabilityOfItemsByStatusServer();
	
	StructureOfNamesOfTableParts = New Structure("Discrepancies");
	FillInServiceDetailsForProductRange(StructureOfNamesOfTableParts);

	UpdateVHFWarehouseObligation();
	
	
	ProvisionInDocumentsServer.CheckToRunBackgroundInventoryAllocationJob();
	
	ConfigurationModificationOverridable.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	
	FormEvents.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	
	// Selection of articles and analytics.
	IncomeAndExpensesServer.AfterWriteAtServer(ThisObject);
	GLAccountSettingsServer.AfterWriteAtServer(ThisObject);
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	PreviousRowDetails = New Structure("Products");
	
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
Procedure BeforeClose(Cancel, StandardProcessing)
	
	ForceCloseTheForm = True;
	
EndProcedure

&AtServer
Procedure OnWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure GroupPagesOnCurrentPageChange(Item, CurrentPage)
	
	// StandardSubsystems.Properties
	If CurrentPage.Name = Items.AdvancedGroup.Name
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
Procedure TermsStartChoice(Item, ChoiceData, StandardProcessing)
	
	PurchasesClient.StartSelectingSupplierAgreement(
		Item,
		StandardProcessing,
		Object.Partner,
		Object.Terms,
		Object.Date);

EndProcedure

&AtClient
Procedure PartnerOnChange(Item)
	
	If Not ValueIsFilled(Object.Partner) Then
		Object.Terms = PredefinedValue("Catalog.TermsOfPurchaseFromVendors.EmptyRef");
		Return;
	EndIf;
	
	WhenChangingPartnerServer();
	
	AdditionalParameters = AdditionalCompletionProcessingParameters();
	AdditionalParameters.Item = Item;
	
	QuestionUserBeforeFillingInAgreement(
		New CallbackDescription("PartnerWhenChangingQuestionEnds", ThisObject, AdditionalParameters));
	
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
Procedure TermsOnChange(Item)
	
	QuestionUserBeforeFillingInAgreement(
		New CallbackDescription("AgreementWhenChangingQuestionCompletion", ThisObject));
	
EndProcedure

&AtClient
Procedure ContractOnChange(Item)
	
	WhenChangingAgreementServer(True);
	
EndProcedure

&AtClient
Procedure LineOfBusinessOnChange(Item)
	
	LineOfBusinessOnChangeServer();
	
EndProcedure

&AtClient
Procedure ReferenceOrderPresentationURLProcessing(Item,
																FormattedStringURL,
																StandardProcessing)
	
	StandardProcessing = False;
	
	If FormattedStringURL = "Open_Order" Then
		ShowValue(, Object.ReferenceOrder)
	Else
		
		// &PerformanceMeasurement
		PerformanceMonitorClient.TimeMeasurement("Document.WriteOffDiscrepanciesBetweenReceiptAndPurchase.Form.SelectReference");
		
		OrderSelectionFormParameters = New Structure;
		OrderSelectionFormParameters.Insert("Partner",				Object.Partner);
		OrderSelectionFormParameters.Insert("Counterparty",				Object.Counterparty);
		OrderSelectionFormParameters.Insert("Terms",				Object.Terms);
		OrderSelectionFormParameters.Insert("Organization",			Object.Organization);
		OrderSelectionFormParameters.Insert("Contract",				Object.Contract);
		OrderSelectionFormParameters.Insert("Warehouse",					Object.Warehouse);
		
		CallbackDescription = New CallbackDescription("CustomerSChoice", ThisObject);
		
		OpenForm("Document.WriteOffDiscrepanciesBetweenReceiptAndPurchase.Form.SelectReference",
					OrderSelectionFormParameters,
					ThisObject,
					,
					,
					,
					CallbackDescription,
					FormWindowOpeningMode.LockOwnerWindow);
	EndIf;
	
EndProcedure

&AtClient
Procedure StructuralUnitOnChange(Item)
	
	UpdateTypeOfVATActivity();
	
EndProcedure

&AtClient
Procedure ExpenseItemOnChange(Item)
	
	IncomeAndExpensesClientServer.AssetRefOnChange(ThisObject, Item);
	FillInSignsOfOverDeliveryUnderDelivery();
	
EndProcedure

&AtClient
Procedure ExpenseItemStartChoice(Item, ChoiceData, StandardProcessing)
	
	IncomeAndExpensesClient.StartArticleSelection(ThisObject, Item, StandardProcessing);	
	
EndProcedure

&AtClient
Procedure DimensionOfExpensesStartChoice(Item, ChoiceData, StandardProcessing)
	
	IncomeAndExpensesClient.StartSelectingExpenseAnalytics(ThisObject, Item, StandardProcessing);	
	
EndProcedure

&AtClient
Procedure DimensionOfExpensesAutoComplete(Item, Text, ChoiceData, Var_Parameters, Waiting, StandardProcessing)
	
	IncomeAndExpensesClient.AutoSelectionOfExpenseAnalytics(ThisObject, Item, Text, ChoiceData, Var_Parameters, StandardProcessing);	
	
EndProcedure

&AtClient
Procedure DimensionOfExpensesTextEditEnd(Item, Text, ChoiceData, Var_Parameters, StandardProcessing)
	
	IncomeAndExpensesClient.EndOfCostAnalyticsTextEntry(ThisObject, Item, Text, ChoiceData, Var_Parameters, StandardProcessing);	
	
EndProcedure

&AtClient
Procedure IncomeItemOnChange(Item)
	
	// Selection of articles and analytics.
	IncomeAndExpensesClientServer.AssetRefOnChange(ThisObject, Item);
	FillInSignsOfOverDeliveryUnderDelivery();       
	
EndProcedure

&AtClient
Procedure IncomeItemStartChoice(Item, ChoiceData, StandardProcessing)
	
	// Selection of articles and analytics.
	IncomeAndExpensesClient.StartArticleSelection(ThisObject, Item, StandardProcessing);
	
EndProcedure

&AtClient
Procedure WarehouseOnChange(Item)
	
	If Warehouse <> Object.Warehouse Then
		WhenChangingWarehouseServer();
	EndIf;
	
EndProcedure

&AtClient
Procedure TextSetUpRecordOfAssetsInComplAccountingClick(Item, StandardProcessing)
	GLAccountSettingsClient.OnClick(ThisObject, Item, StandardProcessing);
	Return;
EndProcedure

&AtClient
Procedure TextSetUpRecordOfLiabilitiesInComplAccountingClick(Item, StandardProcessing)
	GLAccountSettingsClient.OnClick(ThisObject, Item, StandardProcessing);
	Return;
EndProcedure

&AtClient
Procedure LineCorrectionURLProcessing(Item, FormattedStringURL, StandardProcessing)
	DocumentCorrectionClient.StringFixHandlingNavigationLinks(
		ThisObject, FormattedStringURL, StandardProcessing);
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersDiscrepancies

&AtClient
Procedure DiscrepanciesBeforeRowChange(Item, Cancel)
	
	FillPropertyValues(PreviousRowDetails, Items.Discrepancies.CurrentData);
	
EndProcedure

&AtClient
Procedure DiscrepanciesBeforeDeleteRow(Item, Cancel)
	
	ProductsClient.UpdateCachedValuesToAccountForSeries(Item, CachedValues, SeriesSpecificationParameters);
	
EndProcedure

&AtClient
Procedure DiscrepanciesOnChange(Item)
	
	FillInSignsOfOverDeliveryUnderDelivery();
	UpdateVHFWarehouseObligation();
	
EndProcedure

&AtClient
Procedure DiscrepanciesProductsOnChange(Item)
	
	CurrentRow = Items.Discrepancies.CurrentData;
	
	CheckSeriesCalculateStatus = New Structure;
	CheckSeriesCalculateStatus.Insert("Warehouse",                  Object.Warehouse);
	CheckSeriesCalculateStatus.Insert("SeriesSpecificationParameters", SeriesSpecificationParameters);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("CheckCharacteristicsByOwner", CurrentRow.Characteristic);
	StructureOfActions.Insert("CheckFillPackageByOwner"      , CurrentRow.Package);
	StructureOfActions.Insert("RecalculateNumberOfUnits");
	
	StructureOfActions.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
	StructureOfActions.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));
	StructureOfActions.Insert("CheckSeriesCalculateStatus", CheckSeriesCalculateStatus);
	StructureOfActions.Insert("WhenChangingProductType", New Structure("ThereAreWorks, IsCanceled", True, False));
	
	LinesOfBusinessClientServer.StructureOfInsertActionsWhenAddingRow(ThisObject, StructureOfActions);
	
	StructureOfActions.Insert("ProductsOnChangeOverridable",
								New Structure("FormName, TabularSectionName",FormName, "Discrepancies"));
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
	FillPropertyValues(PreviousRowDetails, CurrentRow);
	
EndProcedure

&AtClient
Procedure DiscrepanciesCharacteristicOnChange(Item)
	
	CurrentRow = Items.Discrepancies.CurrentData;
	
	AdditionalParameters = AdditionalCompletionProcessingParameters();
	AdditionalParameters.CurrentRow = CurrentRow;

	RunCallback(
		New CallbackDescription(
			"DiscrepanciesCharacteristicWhenChangingQuestionToUserEnd", ThisObject, AdditionalParameters), 
		True);
EndProcedure

&AtClient
Procedure DiscrepanciesNumberOfPackagesOnChange(Item)
	
	CurrentRow = Items.Discrepancies.CurrentData;
	
	StructureOfActions = New Structure;
	AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions, ThisObject);
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
EndProcedure

&AtClient
Procedure DiscrepanciesPackageOnChange(Item)
	CurrentRow = Items.Discrepancies.CurrentData;
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateNumberOfUnits");
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
EndProcedure

&AtClient
Procedure DiscrepanciesSeriesStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	OpenSelectionOfSeries(Item.EditText);
	
EndProcedure

&AtClient
Procedure DiscrepanciesSeriesOnChange(Item)
	
	CurrentRow = Items.Discrepancies.CurrentData;
	
	ValueSelected = ProductsClientServer.SelectedSeries();
	ValueSelected.Value						= CurrentRow.Series;
	ValueSelected.CurrentRowID	= CurrentRow.GetID();
	
	ProductsClient.ProcessSeriesIndication(ThisObject, SeriesSpecificationParameters, ValueSelected);
	
EndProcedure

&AtClient
Procedure DiscrepanciesAreTypeOfDiscrepanciesOnChange(Item)
	
	CurrentRow = Items.Discrepancies.CurrentData;
	
	CheckSeriesCalculateStatus = New Structure;
	CheckSeriesCalculateStatus.Insert("Warehouse",                  Object.Warehouse);
	CheckSeriesCalculateStatus.Insert("SeriesSpecificationParameters", SeriesSpecificationParameters);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("CheckSeriesCalculateStatus", CheckSeriesCalculateStatus);
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

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
&AtServer
Procedure ExecuteCommandAtServer(ExecutionParameters)
	AttachableCommands.ExecuteCommand(ThisObject, ExecutionParameters, Object);
EndProcedure

&AtClient
Procedure Attachable_ContinueCommandExecutionAtServer(ExecutionParameters, AdditionalParameters) Export
	ExecuteCommandAtServer(ExecutionParameters);
EndProcedure

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
Procedure Attachable_PropertiesExecuteCommand(ItemOrCommand, Var_URL = Undefined, StandardProcessing = Undefined)
	PropertyManagerClient.ExecuteCommand(ThisObject, ItemOrCommand, StandardProcessing);
EndProcedure

// IntegrationWith1CDocumentManagementSubsystem
&AtClient
Procedure Attachable_ExecuteIntegrationCommand(Command)
	
	IntegrationWith1CDocumentManagementCoreClient.ExecutePlugInIntegrationCommand(Command, ThisObject, Object);
	
EndProcedure
// End IntegrationWith1CDocumentManagementSubsystem

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisObject, Command);
	
EndProcedure

&AtClient
Procedure SelectGoods(Command)
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.TimeMeasurement(
		"Document.WriteOffDiscrepanciesBetweenReceiptAndPurchase.DocumentForm.Command.SelectGoods");
	
	Cancel = False;
	
	If Cancel Then
		Return;
	EndIf;
	
	FilterByProductType = New FixedArray(ProductsClientServer.SelectionByProductReusablePackagingServiceWork(False));
	OperationWithoutPrices = True;
	
	FormParameters = New Structure;
	FormParameters.Insert("Document",                Object.Ref);
	FormParameters.Insert("Date",                    Object.Date);
	FormParameters.Insert("Partner",                 Object.Partner);
	FormParameters.Insert("Terms",              Object.Terms);
	FormParameters.Insert("FilterByProductType", FilterByProductType);
	FormParameters.Insert("HideTheViewPriceColumn",  OperationWithoutPrices);
	FormParameters.Insert("HideTheItemPricesCommand",   OperationWithoutPrices);
	FormParameters.Insert("SelectionModeWithoutAmountParameters", OperationWithoutPrices);
	FormParameters.Insert("SelectionModeUseWarehousesInTabularSection", False);
	
	OpenForm("DataProcessor.SelectGoodsToPurchaseDocument.Form", FormParameters, ThisObject, UUID);
	
EndProcedure

&AtClient
Procedure InsertRows(Command)
	
	NumberOfProductsBeforeInsertion = Object.Discrepancies.Count();
	
	GetLinesFromClipboard();
	
	NumberOfInserted = Object.Discrepancies.Count() - NumberOfProductsBeforeInsertion;
	ProcessingOfTabularFormsClient.NotifyUserAboutInsertingRows(NumberOfInserted);
	
EndProcedure

&AtClient
Procedure CopyRows(Command)
	
	If ProcessingOfTabularFormsClient.SelectedLineToExecuteCommand(Items.Discrepancies) Then
		CopyLinesOnServer("Discrepancies");
		ProcessingOfTabularFormsClient.NotifyUserAboutCopyingStrings(Items.Discrepancies.SelectedRows.Count());
	EndIf;
	
EndProcedure

&AtClient
Procedure PostAndClose(Command)
	
	TMCommonUseClient.PostAndClose(ThisObject, True);
	
EndProcedure

&AtClient
Procedure SetDeletionMarkForADocument(Command)
	
	TMCommonUseClient.SetDeletionMarkForADocument(ThisObject);
	
EndProcedure

&AtClient
Procedure WriteDocument(Command)
	
	TMCommonUseClient.Write(ThisObject);
	
EndProcedure

&AtClient
Procedure PostDocument(Command)
	
	TMCommonUseClient.Post(ThisObject);
	
EndProcedure

&AtClient
Procedure FillInByDiscrepancies(Command)
	
	ClearMessages();
	
	Cancel = False;
	
	If Not ValueIsFilled(Object.ReferenceOrder) Then
		MessageText = NStr("vi = 'Chưa điền trường ""Lệnh""';
							|ru = 'Поле ""Распоряжение"" не заполнено';
							|en = 'The Reference field is required'; fa = 'The Reference field is required';
							|it = 'Il campo ""Disposizione"" non è compilato';
							|pl = 'Pole ""Zamówienie"" nie jest wypełnione';
							|tr = '""Sipariş"" alanı doldurulmadı'");
		
		CommonClient.MessageToUser(MessageText, Object.ReferenceOrder, "Object.ReferenceOrder", , Cancel);
	EndIf;
	
	If Cancel Then
		Return;
	EndIf;
	
	HasChanges = FillInByDiscrepanciesOnServer();
	
	If HasChanges Then
		Modified = True;
	EndIf;
	
EndProcedure

&AtClient
Procedure SpecifySeries(Command)
	
	OpenSelectionOfSeries();
	
EndProcedure

&AtServer
Function FillInByDiscrepanciesOnServer()
	
	StructureOfActionsWithAddedStrings = New Structure;
	StructureOfActionsWithAddedStrings.Insert("FillInFeatureAttribute",
													New Structure("Products", "ItemVariantsAreUsed"));
	StructureOfActionsWithAddedStrings.Insert("FillInProductTypeAttribute_",
													New Structure("Products", "ItemsType"));
	StructureOfActionsWithAddedStrings.Insert("FillInArticleAttribute",
													New Structure("Products", "SKU"));
	StructureOfActionsWithAddedStrings.Insert("ProductsOnChangeOverridable",
													New Structure("FormName, TabularSectionName",
																	FormName, "Discrepancies"));
	StructureOfActionsWithAddedStrings.Insert("WhenChangingProductType",
													New Structure("ThereAreWorks, IsCanceled", True, False));
	ReferenceArray = New Array();
	ReferenceArray.Add(Object.ReferenceOrder);
	
	FillParameters = PurchasesServer.FillingParametersForActualAcceptance();
	FillParameters.CurrentDocument                        = Object.Ref;
	FillParameters.StructureOfActionsWithAddedStrings = StructureOfActionsWithAddedStrings;
	FillParameters.Warehouse                                  = Object.Warehouse;
	FillParameters.ReferenceArray                     = ReferenceArray;
	FillParameters.Terms                             = Object.Terms;
	FillParameters.Contract                                = Object.Contract;
	
	HasChanges = Documents.WriteOffDiscrepanciesBetweenReceiptAndPurchase.FillInDiscrepanciesBetweenAdmissionAndPurchase(Object.Discrepancies, FillParameters);
	ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);
	
	FillInSignsOfOverDeliveryUnderDelivery();
	
	Return HasChanges;
EndFunction

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

// Constructor function for additional End processing parameters.
//
// Returns:
//	Structure - advanced setting:
//		* CurrentRow - FormDataCollectionItem - 
//		* Item - FormGroup, FormTable, FormField, FormButton - form element - 
//
&AtClient
Function AdditionalCompletionProcessingParameters()
	
	Result = New Structure;
	Result.Insert("CurrentRow");
	Result.Insert("Item");
	
	Return Result;
	
EndFunction

// Parameters:
//	Result - Boolean - 
//	AdditionalParameters - See AdditionalCompletionProcessingParameters
//
&AtClient
Procedure DiscrepanciesCharacteristicWhenChangingQuestionToUserEnd(Result, AdditionalParameters) Export
	
	If Not Result Then
		Return;
	EndIf;
	
	CurrentRow = AdditionalParameters.CurrentRow;
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("CharacteristicOnChangeOverridable",
								New Structure("FormName, TabularSectionName",FormName, "Discrepancies"));
	
	LinesOfBusinessClientServer.StructureOfInsertActionsWhenAddingRow(ThisObject, StructureOfActions);
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
EndProcedure

&AtServer
Procedure FirstChoiceServer(ValueSelected)
	
	PropertiesToExclude = "";
	
	If TypeOf(ValueSelected.ReferenceOrder) = Type("CatalogRef.CounterpartyContracts") Then
		PropertiesToExclude = "Warehouse";
	EndIf;

	FillPropertyValues(Object, ValueSelected,,PropertiesToExclude);

	DisposalWarehouses = DisposalWarehouses(True);
	
	If ValueSelected.ThisIsWarehouseGroup
		And ValueIsFilled(Object.Warehouse)
		And DisposalWarehouses.Find(Object.Warehouse) = Undefined Then
		
		Object.Warehouse = Catalogs.Warehouses.EmptyRef();
		
	EndIf;
	
	WhenChangingAgreementServer(False);
	ShowOrderPresentation();
	SetParametersForSelectingWarehouseProps(DisposalWarehouses);
	
	If TypeOf(Object.ReferenceOrder) <> Type("CatalogRef.TermsOfPurchaseFromVendors") Then
		PurchasesServer.SetContractAvailability(Object,
													Items.Contract.Enabled,
													Items.Contract.Visible,
													Object.Contract);                                 
	EndIf;
	StructureOfNamesOfTableParts = New Structure("Discrepancies");
	FillInServiceDetailsForProductRange(StructureOfNamesOfTableParts);
	
EndProcedure

&AtServer
Procedure CounterpartyOnChangeServer()
	
	If ValueIsFilled(Object.Counterparty) Then
		FillInDefaultContract();
	EndIf;
	
	If UseLinesOfBusiness Then
		LinesOfBusinessServer.FillInDefaultDirection(Object.LineOfBusiness, Object.Terms, Object.Contract);
	EndIf;
	
	LinesOfBusinessServer.WhenChangingDirectionOfActivity(ThisObject);
	
	PurchasesServer.SetContractAvailability(
		Object,
		Items.Contract.Enabled,
		Items.Contract.Visible,
		Object.Contract);
	
	UpdateTypeOfVATActivity();
	ClearOrder();
	
EndProcedure

&AtServer
Procedure OrganizationOnChangeServer()
	
	If ValueIsFilled(Object.Organization) Then
		FillInDefaultContract();
		
		If UseLinesOfBusiness Then
			LinesOfBusinessServer.FillInDefaultDirection(Object.LineOfBusiness, Object.Terms, Object.Contract);
		EndIf;
	EndIf;
	
	PurchasesServer.SetContractAvailability(
		Object,
		Items.Contract.Enabled,
		Items.Contract.Visible,
		Object.Contract);
	
	FillInSubordinatePropertiesForStatistics("Organization");
	
	ResponsiblePersonsServer.WhenChangingRelatedDocumentDetails(Object);
	LinesOfBusinessServer.WhenChangingDirectionOfActivity(ThisObject);
	
	UpdateTypeOfVATActivity();
	ClearOrder();
	
EndProcedure

&AtClient
Procedure AgreementWhenChangingQuestionCompletion(UserAnswer, AdditionalParameters) Export
	
	RecalculatePrices_2 = ValueIsFilled(Object.Terms)
						And Object.Discrepancies.Count() > 0
						And UserAnswer;
	
	WhenChangingAgreementAtServer(RecalculatePrices_2);
	
	If ValueIsFilled(Object.Terms) Then
		PurchasesClient.NotifyEndOfFillingInTermsOfPurchase();
	EndIf;
	
EndProcedure

&AtClient
Procedure CustomerSChoice(ValueSelected, Var_Parameters) Export
	
	If ValueSelected <> Undefined Then
		Modified = True;
		
		FirstChoiceClientCallServer(ValueSelected);
	EndIf;
	
EndProcedure

&AtClient
Procedure FirstChoiceClientCallServer(ValueSelected)
	
	FirstChoiceServer(ValueSelected);
	
	If TypeOf(Object.ReferenceOrder) = Type("CatalogRef.TermsOfPurchaseFromVendors") Then
		CallbackDescription = New CallbackDescription("AgreementWhenChangingQuestionCompletion", ThisObject);
		
		QuestionUserBeforeFillingInAgreement(CallbackDescription);
	EndIf;
	
EndProcedure

// Parameters:
//	UserAnswer - Boolean - 
//	AdditionalParameters - See AdditionalCompletionProcessingParameters.
//
&AtClient
Procedure PartnerWhenChangingQuestionEnds(UserAnswer, AdditionalParameters) Export
	
	If ValueIsFilled(Object.Terms) Then
		PurchasesClient.NotifyEndOfFillingInDefaultPurchaseConditions();
	EndIf;
	
	
EndProcedure

&AtClient
Procedure Attachable_ProcessObjectEntry()
	
	TMCommonUseClient.ProcessObjectEntryInForm(ThisObject, ParametersForRecording);
	
EndProcedure

&AtServer
Procedure FillInSubordinatePropertiesForStatistics(ParentPropsName)
	ObjectsFillingByStatistics.FillInSubordinateDetailsOfObject(Object, ParentPropsName);
EndProcedure

&AtServer
Procedure SetConditionalAppearance()

	ConditionalAppearance.Items.Clear();
	
	//

	Item = ConditionalAppearance.Items.Add();

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Partner");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	Item.Appearance.SetParameterValue("ReadOnly", True);

	//

	ConditionalDesignParameters = ProductsServer.NewParametersForConditionalDesignOfUnitsOfMeasurement();
	ConditionalDesignParameters.NameOfUnitField = "DiscrepanciesProductsUnitOfMeasure";
	ConditionalDesignParameters.PathToPackagingUnitField = "Object.Discrepancies.Package";
	ProductsServer.SetConditionalAppearanceOfUnitsOfMeasurement(ThisObject, ConditionalDesignParameters);
	
	ProductsServer.EstablishConditionalAppearanceOfProductCharacteristics(ThisObject, "DiscrepanciesCharacteristic","Object.Discrepancies.ItemVariantsAreUsed");

	//

	ProductsServer.SetConditionalAppearanceOfProductAssignment(ThisObject, "DiscrepanciesPurpose", "Object.Discrepancies.Products.ItemsType",True);

	//
	WarehousesServer.SetConditionalAppearanceOfWarehouseInHeader(ThisObject);

	//General purpose.setrespondentnotesfilled(
	//	Conditional form, "Warehouse", "Object.Warehouse", "Warehouse is mandatory");
	//
	

	ProductsServer.SetConditionalAppearanceOfStatusIndicationSeries(ThisObject,
																		False,
																		"DiscrepanciesBatchesIndicationStatus",
																		"Object.Discrepancies.BatchesIndicationStatus");
	
	ProductsServer.EstablishConditionalAppearanceOfProductSeries(ThisObject,
									False, 
									"DiscrepanciesSeries",
									"Object.Discrepancies.BatchesIndicationStatus",
									"Object.Discrepancies.ItemsType");

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ReferenceOrderPresentation.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.ReferenceOrder");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	Item.Appearance.SetParameterValue("TextColor", StyleColors.ResultIssueColor);

	//
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.DiscrepanciesPurpose.Name);
	
	FilterGroup = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup.GroupType = DataCompositionFilterItemsGroupType.OrGroup;

	ItemFilter = FilterGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Discrepancies.ItemsType");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.ItemsTypes.OperationService;

	ItemFilter = FilterGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Discrepancies.ItemsType");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.ItemsTypes.EmptyRef();
	
	Text = NStr("vi = '<dành cho hàng hóa và công việc>';
				|ru = '<для товаров и работ>';
				|en = '<for goods and works>'; fa = '<for goods and works>';
				|it = '<per beni e opere>';
				|pl = '<dla towarów i robót>';
				|tr = '<ürünler ve işler için>'");
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.EmptyTableField);
	Item.Appearance.SetParameterValue("Text", Text);
	Item.Appearance.SetParameterValue("ReadOnly", True);
	//
	
	LinesOfBusinessServer.EstablishConditionalAppearanceOfDirectionOfActivity(ThisObject);
	
	//
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.IncomeItem.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ThereisOverdelivery");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.IncomeItem");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;

	Item.Appearance.SetParameterValue("MarkIncomplete", True);
	//
	
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.IncomeItem.Name);

	FilterGroup1 = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup1.GroupType = DataCompositionFilterItemsGroupType.OrGroup;

	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ThereisOverdelivery");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;

	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.IncomeItem");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;

	Item.Appearance.SetParameterValue("MarkIncomplete", False);

	//
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ExpenseItem.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ThereIsUnderdelivery");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.ExpenseItem");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;

	Item.Appearance.SetParameterValue("MarkIncomplete", True);
	//
	
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ExpenseItem.Name);

	FilterGroup1 = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup1.GroupType = DataCompositionFilterItemsGroupType.OrGroup;

	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ThereIsUnderdelivery");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;

	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.ExpenseItem");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;

	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	
EndProcedure

&AtServer
Procedure UpdateVHFWarehouseObligation()
	
	For Each CurrentRow In Object.Discrepancies Do	
		If CurrentRow.ItemsType = Enums.ItemsTypes.Work_5 
			Or CurrentRow.ItemsType = Enums.ItemsTypes.OperationService Then
				CurrentRow.WarehouseIsRequired = 0;
		Else
			CurrentRow.WarehouseIsRequired = 1;
		EndIf;
	EndDo;
	WarehouseIsRequired  = ?(Object.Discrepancies.Total("WarehouseIsRequired") = 0, 0, 1);
	
EndProcedure

#Region OnChangeAttributes

&AtServer
Procedure DateOnChangeServer()
	
	HowToSetSeriesVisibility();
	
EndProcedure

&AtServer
Procedure WhenChangingPartnerServer()
	
	DocumentPurchases = FormAttributeToValue("Object");
	DocumentPurchases.FillInDefaultPurchaseConditions();
	ValueToFormAttribute(DocumentPurchases, "Object");
	
	StructureOfNamesOfTableParts = New Structure("Discrepancies");
	FillInServiceDetailsForProductRange(StructureOfNamesOfTableParts);
	
	ResponsiblePersonsServer.WhenChangingRelatedDocumentDetails(Object);
	
	If UseLinesOfBusiness Then
		LinesOfBusinessServer.FillInDefaultDirection(Object.LineOfBusiness, Object.Terms, Object.Contract);
	EndIf;

	LinesOfBusinessServer.WhenChangingDirectionOfActivity(ThisObject);
	
	PurchasesServer.SetContractAvailability(
		Object,
		Items.Contract.Enabled,
		Items.Contract.Visible,
		Object.Contract);
	
	ClearOrder();
	
	If Contract <> Object.Contract Then
		Contract = Object.Contract;
	EndIf;
	
EndProcedure

&AtServer
Procedure ClearOrder()
	
	If Not ValueIsFilled(Object.ReferenceOrder) Then
		Return;
	EndIf;
	
	AttributesNames = "Partner, Counterparty, BusinessOperation, Organization";
	
	If TypeOf(Object.ReferenceOrder) <> Type("CatalogRef.TermsOfPurchaseFromVendors")
		And TypeOf(Object.ReferenceOrder) <> Type("CatalogRef.CounterpartyContracts") Then
		
		AttributesNames = AttributesNames + ", Terms, Contract";
	
	EndIf;
	
	If TypeOf(Object.ReferenceOrder) <> Type("CatalogRef.CounterpartyContracts") Then
		AttributesNames = AttributesNames + ", Warehouse";
	EndIf;
	
	DetailsOfOrder = Common.ObjectAttributesValues(Object.ReferenceOrder, AttributesNames);
	
	If Object.Partner <> DetailsOfOrder.Partner
			And ValueIsFilled(Object.Partner)
		
		Or Object.Counterparty <> DetailsOfOrder.Counterparty
			And ValueIsFilled(DetailsOfOrder.Counterparty)
			And ValueIsFilled(Object.Counterparty)
		
		Or Object.Organization <> DetailsOfOrder.Organization
			And ValueIsFilled(DetailsOfOrder.Organization)
			And ValueIsFilled(Object.Organization) Then
		
		Object.ReferenceOrder = Undefined;
		
	EndIf;
	
	If ValueIsFilled(Object.ReferenceOrder) Then
		
		If TypeOf(Object.ReferenceOrder) = Type("CatalogRef.TermsOfPurchaseFromVendors") Then
			
			BasicDisposalOperation = PurchasesServer.MainEconomicOperationOfSeparatePurchase(
												DetailsOfOrder.BusinessOperation);
			
			If (Object.BusinessOperation = Enums.BusinessTransactions.ImportFromEAEUUninvoicedDelivery
						Or Object.BusinessOperation = Enums.BusinessTransactions.ImportFromEAEUReceiptFromGoodsInTransit)
					And BasicDisposalOperation <> Enums.BusinessTransactions.ImportFromEAEU
					
				Or (Object.BusinessOperation = Enums.BusinessTransactions.PurchaseFromVendorUninvoicedDelivery
						Or Object.BusinessOperation = Enums.BusinessTransactions.PurchaseFromVendorReceiptFromGoodsInTransit)
					And BasicDisposalOperation <> Enums.BusinessTransactions.PurchaseFromSupplier
				
				Or Object.BusinessOperation = Enums.BusinessTransactions.ImportReceiptFromGoodsInTransit
					And BasicDisposalOperation <> Enums.BusinessTransactions.PurchaseByImport Then
				
				Object.ReferenceOrder = Undefined;
				
			EndIf;
			
			If Object.Terms <> Object.ReferenceOrder Then
				Object.ReferenceOrder = Undefined;
			EndIf;
			
		ElsIf TypeOf(Object.ReferenceOrder) = Type("CatalogRef.CounterpartyContracts") Then
			
			If Object.Contract <> Object.ReferenceOrder Then
				Object.ReferenceOrder = Undefined;
			EndIf;
			
		Else
			
			If Object.Contract <> DetailsOfOrder.Contract
				And ValueIsFilled(Object.Contract)
				
				Or Object.Terms <> DetailsOfOrder.Terms
				And ValueIsFilled(DetailsOfOrder.Terms) Then
				
				Object.ReferenceOrder = Undefined;
				
			EndIf;
			
		EndIf;
		
	EndIf;
	
	ShowOrderPresentation();
	
EndProcedure

&AtServer
Procedure WhenChangingWarehouseServer()
	
	Warehouse = Object.Warehouse;
	
	HowToSetSeriesVisibility();
	UpdateTypeOfVATActivity();
	
EndProcedure

&AtServer
Procedure ClearWarehouseFieldSelectionParameters()
	
	If ValueIsFilled(Object.ReferenceOrder) Then
		Return;
	EndIf;
	
	Items.Warehouse.ChoiceParameters = New FixedArray(New Array);
	
EndProcedure

&AtServer
Procedure WhenChangingAgreementAtServer(RecalculatePrices_2 = True)
	
	If ValueIsFilled(Object.Terms) Then
		PurchaseConditions = PurchasesServer.GetPurchaseTermsAndConditions(Object.Terms, True, True);
		
		DocumentPurchases = FormAttributeToValue("Object");
		DocumentPurchases.FillInTermsOfPurchase(PurchaseConditions);
		
		ValueToFormAttribute(DocumentPurchases, "Object");
		
		StructureOfNamesOfTableParts = New Structure("Discrepancies");
		FillInServiceDetailsForProductRange(StructureOfNamesOfTableParts);
	EndIf;
	
	PurchasesServer.SetContractAvailability(Object, Items.Contract.Enabled, Items.Contract.Visible, Object.Contract);
	
	If UseLinesOfBusiness Then
		LinesOfBusinessServer.FillInDefaultDirection(Object.LineOfBusiness, Object.Terms, Object.Contract);
	EndIf;

	ResponsiblePersonsServer.WhenChangingRelatedDocumentDetails(Object);
	LinesOfBusinessServer.WhenChangingDirectionOfActivity(ThisObject);
	
	ClearOrder();
	
	If Contract <> Object.Contract Then
		Contract = Object.Contract;
	EndIf;
	
EndProcedure

&AtServer
Procedure WhenChangingAgreementServer(ClearingOrder)
	
	DirectionsOfActivity = Object.LineOfBusiness;
	
	If UseLinesOfBusiness Then
		LinesOfBusinessServer.FillInDefaultDirection(Object.LineOfBusiness, 
			Object.Terms, Object.Contract);
		EndIf;
		
	LinesOfBusinessServer.WhenChangingDirectionOfActivity(ThisObject);
	If DirectionsOfActivity <> Object.LineOfBusiness Then
		ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);
	EndIf;
	
	If ClearingOrder Then
		ClearOrder();
		ClearWarehouseFieldSelectionParameters();
	EndIf;
	
	StructureOfNamesOfTableParts = New Structure("Discrepancies");
	FillInServiceDetailsForProductRange(StructureOfNamesOfTableParts);
	
EndProcedure

&AtServer
Procedure LineOfBusinessOnChangeServer()
	
	LinesOfBusinessServer.WhenChangingDirectionOfActivity(ThisObject);
	
EndProcedure

#EndRegion

#Region SetOfSeries

&AtServer
Function SeriesSpecificationParameters()
	
	ObjectManager = Documents.WriteOffDiscrepanciesBetweenReceiptAndPurchase;
	
	Return New FixedStructure(ProductsServer.SeriesSpecificationParameters(Object, ObjectManager));
	
EndFunction

&AtServer
Procedure SetVisibilityOfSeriesElements()
	
	Items.DiscrepanciesBatchesIndicationStatus.Visible = SeriesSpecificationParameters.UseItemsBatch;
	Items.DiscrepanciesSpecifySeries.Visible        = SeriesSpecificationParameters.UseItemsBatch;
	Items.DiscrepanciesSeries.Visible               = SeriesSpecificationParameters.UseItemsBatch;
	
EndProcedure

&AtServer
Procedure FillInStatusesForSpecifyingSeriesServer()
	
	ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);
	
EndProcedure

&AtServer
Procedure HowToSetSeriesVisibility()
	
	SeriesSpecificationParameters = SeriesSpecificationParameters();
	
	ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);
	SetVisibilityOfSeriesElements();
	
EndProcedure

&AtClient
Procedure OpenSelectionOfSeries(Text = "", CurrentData = Undefined)
	
	NeedServerCall = ProductsClient.YouNeedServerCallToSpecifySeries(ThisObject,
																				SeriesSpecificationParameters,
																				Text,
																				CurrentData);
	
	If NeedServerCall Then
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

#Region ControlOfInconsistentChanges

// Parameters:
//	Item - FormGroup, FormTable, FormField, FormButton - FormItem
//
&AtClient
Procedure ControlOfNonConsistentChangesHandleEventOnChange(Item)
	If Item.Name = Items.Partner.Name Then
		PartnerOnChange(Item);
	ElsIf Item.Name = Items.Terms.Name Then
		TermsOnChange(Item);
	ElsIf Item.Name = Items.Contract.Name Then
		ContractOnChange(Item);
	ElsIf Item.Name = Items.Organization.Name Then
		OrganizationOnChange(Item);
	ElsIf Item.Name = Items.Counterparty.Name Then
		CounterpartyOnChange(Item);
	ElsIf Item.Name = Items.Warehouse.Name Then
		WarehouseOnChange(Item);
	Else
		TMCommonUseClient.MonitoringNonConsistentChangesCauseException(ThisObject, Item);
	EndIf;
EndProcedure

// Parameters:
//	Command - FormCommand - 
//
&AtClient
Procedure ControlOfNonConsistentChangesHandleCommandEvent(Command)
	
	If Command.Name = Commands.SelectGoods.Name Then
		SelectGoods(Command);
	Else
		TMCommonUseClient.MonitoringNonConsistentChangesCauseException(ThisObject, Command);
	EndIf;
	
EndProcedure

// Parameters:
//	Item - FormGroup, FormTable, FormField, FormButton - FormItem
//
&AtClient
Procedure ControlOfNonConsistentChangesHandlePushEvent(Item)
	TMCommonUseClient.MonitoringNonConsistentChangesCauseException(ThisObject, Item);
EndProcedure

// Parameters:
//	Item - FormGroup, FormTable, FormField, FormButton - FormItem
//	Cancel - Boolean -
//
&AtClient
Procedure ControlOfNonConsistentChangesHandleEventBeforeStartingChange(Item, Cancel)
	TMCommonUseClient.MonitoringNonConsistentChangesCauseException(ThisObject, Item);
EndProcedure

// Parameters:
//	Item - FormGroup, FormTable, FormField, FormButton - FormItem
//	Cancel - Boolean -
//
&AtClient
Procedure ControlOfNonConsistentChangesHandleEventBeforeDeletion(Item, Cancel)
	If Not Item.Name = Items.Discrepancies.Name Then
		TMCommonUseClient.MonitoringNonConsistentChangesCauseException(ThisObject, Item);
	EndIf;
EndProcedure

// Parameters:
//	Item - FormGroup, FormTable, FormField, FormButton - FormItem
//	Cancel - Boolean -
//	Copy - Boolean -
//	Parent - Undefined, CatalogRef -
//	Var_Group - Boolean -
//
&AtClient
Procedure ControlOfNonConsistentChangesHandleEventBeforeStartingAdding(Item, Cancel, Copy, Parent, Var_Group)
	TMCommonUseClient.MonitoringNonConsistentChangesCauseException(ThisObject, Item);
EndProcedure

#EndRegion

// Parameters:
//	Item - FormGroup, FormTable, FormField, FormButton - FormItem
//
&AtClient
Procedure Attachable_WhenChanging_SetAvailabilityOfItemsByStatusServer(Item)
	
	TMCommonUseClient.SaveAttributeValue(ThisObject, Item);
	
	If TMCommonUseClient.WhenActingOnStatusDependentElement(ThisObject) Then
		Return;
	EndIf;
	
	If StructureOfActionsControlOfNonAgreedChanges.OnChange.Property(Item.Name) Then
		ControlOfNonConsistentChangesHandleEventOnChange(Item);
	EndIf;
	
EndProcedure

// Parameters:
//	Item - FormGroup, FormTable, FormField, FormButton - FormItem
//
&AtClient
Procedure Attachable_Clicking_SetAvailabilityOfItemsByStatusServer(Item)
	
	If TMCommonUseClient.WhenActingOnStatusDependentElement(ThisObject) Then
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
	
	If TMCommonUseClient.WhenActingOnStatusDependentElement(ThisObject) Then
		Return;
	EndIf;
	
	If StructureOfActionsControlOfNonAgreedChanges.Commands.Property(Command.Name) Then
		ControlOfNonConsistentChangesHandleCommandEvent(Command);
	EndIf;
	
EndProcedure

// Parameters:
//	Item - FormGroup, FormTable, FormField, FormButton - FormItem
//	Cancel - Boolean -
//
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
//	Cancel - Boolean -
//
&AtClient
Procedure Attachable_BeforeDeleting_SetAvailabilityOfItemsByStatusServer(Item, Cancel)
	
	If TMCommonUseClient.WhenActingOnStatusDependentElement(ThisObject) Then
		Return;
	EndIf;
	
	Name = Item.Name;
	If StructureOfActionsControlOfNonAgreedChanges.BeforeDeleteRow.Property(Name) Then
		ControlOfNonConsistentChangesHandleEventBeforeDeletion(Item, Cancel);
	EndIf;

EndProcedure

// Parameters:
//	Item - FormGroup, FormTable, FormField, FormButton - FormItem
//	Cancel - Boolean -
//	Copy - Boolean -
//	Parent - Undefined, CatalogRef -
//	Var_Group - Boolean -
//
&AtClient
Procedure Attachable_BeforeYouStartAdding_SetAvailabilityOfItemsByStatusServer(Item, Cancel, Copy, Parent, Var_Group)
	
	If TMCommonUseClient.WhenActingOnStatusDependentElement(ThisObject) Then
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
	TMCommonUseClient.AfterChangingPropsDependentOnStatus(ThisObject);
	
EndProcedure

#Region WorkingWithClipboard

&AtServer
Procedure CopyLinesOnServer(TSName)
	
	ProcessingOfTabularForms.CopyRowsToClipboard(Object[TSName], Items[TSName].SelectedRows);
	
EndProcedure

&AtServer
Procedure GetLinesFromClipboard()
	
	FilterParameters = New Map;
	FilterParameters.Insert("Products.ItemsType", ProductsClientServer.SelectionByProductReusablePackagingServiceWork(False));
	
	Columns = "Products,Characteristic,NumberOfPackages,Count,DiscrepanciesKind,Series";
	
	TableOfGoods = ProcessingOfTabularForms.RowsFromClipboard(FilterParameters, Columns);
	
	If Not ValueIsFilled(TableOfGoods) Then
		Return;
	EndIf;
	
	CheckSeriesCalculateStatus = New Structure;
	CheckSeriesCalculateStatus.Insert("Warehouse",                  Object.Warehouse);
	CheckSeriesCalculateStatus.Insert("SeriesSpecificationParameters", SeriesSpecificationParameters);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
	StructureOfActions.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));
	StructureOfActions.Insert("RecalculateNumberOfUnits");
	StructureOfActions.Insert("CheckSeriesCalculateStatus", CheckSeriesCalculateStatus);
	StructureOfActions.Insert("WhenChangingProductType",
								New Structure("ThereAreWorks, IsCanceled, WarehouseIsRequired", True, False, True));
	
	LinesOfBusinessClientServer.StructureOfInsertActionsWhenAddingRow(ThisObject, StructureOfActions);
	
	StructureOfActions.Insert("ProductsOnChangeOverridable",
								New Structure("FormName, TabularSectionName", FormName, "Discrepancies"));
	
	RowsToProcess = New Array;
	
	For Each RowOfProduct In TableOfGoods Do
		CurrentRow = Object.Discrepancies.Add();
		FillPropertyValues(CurrentRow, RowOfProduct);
		
		RowsToProcess.Add(CurrentRow);
	EndDo;
	
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		RowsToProcess,
		StructureOfActions,
		Object.Discrepancies);
	
	StructureOfNamesOfTableParts = New Structure("Discrepancies");
	FillInServiceDetailsForProductRange(StructureOfNamesOfTableParts);
	
EndProcedure

&AtServer
Procedure SetAvailabilityOfClipboardCommands()
	
	ItemArray = New Array();
	ItemArray.Add("DiscrepanciesInsertRows");
	ItemArray.Add("DiscrepanciesContextMenuInsertLines");
	
	TMCommonUseClientServer.SetPropertyOfFormElements(Items, ItemArray, "Enabled",
		ProcessingOfTabularForms.ThereAreLinesInClipboard());
	
EndProcedure

&AtClient
Procedure SetAvailabilityOfClipboardCommandsOnClient()
	
	ItemArray = New Array();
	ItemArray.Add("DiscrepanciesInsertRows");
	ItemArray.Add("DiscrepanciesContextMenuInsertLines");
	
	TMCommonUseClientServer.SetPropertyOfFormElements(Items, ItemArray, "Enabled", True);
	
EndProcedure

&AtClientAtServerNoContext
Procedure AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions, Form)
	
	StructureOfActions.Insert("RecalculateNumberOfUnits");
	
EndProcedure

#EndRegion

&AtServer
Procedure FillInServiceDetailsForProductRange(StructureOfNamesOfTableParts)
	
	ParametersForFillingInBankingDetails = New Structure;
	ParametersForFillingInBankingDetails.Insert("FillInFeatureAttribute",
											New Structure("Products", "ItemVariantsAreUsed"));
	ParametersForFillingInBankingDetails.Insert("FillInProductTypeAttribute_",
											New Structure("Products", "ItemsType"));
	ParametersForFillingInBankingDetails.Insert("FillInArticleAttribute",
											New Structure("Products", "SKU"));
	
	If StructureOfNamesOfTableParts.Property("Discrepancies") Then
		ProductsServer.FillInServiceDetailsForProductInCollection(Object.Discrepancies, ParametersForFillingInBankingDetails);
	EndIf;	
	
EndProcedure

&AtServer
Procedure OnReadCreateAtServer()
	
	UseTermsOfPurchases		= GetFunctionalOption("UseTermsOfPurchases");
	UseLinesOfBusiness		= GetFunctionalOption("UseCostAccountingByLinesOfBusiness");
	UsePartnersAsCounterparties 	= GetFunctionalOption("UsePartnersAsCounterparties");
	
	Contract	= Object.Contract;
	Warehouse	= Object.Warehouse;
	
	SeriesSpecificationParameters = SeriesSpecificationParameters();
	SetVisibilityOfSeriesElements();
	
	ShowOrderPresentation();

	StructureOfNamesOfTableParts = New Structure("Discrepancies");
	
	FillInServiceDetailsForProductRange(StructureOfNamesOfTableParts);
	UpdateVHFWarehouseObligation();
	
	DocumentDateBeforeChange = Object.Date;
	
	LinesOfBusinessServer.OnReadCreateAtServer(ThisObject);
	
	Items.CounterpartyGroup.Visible	= Not UsePartnersAsCounterparties;
	Items.Dummy.Visible			= Not UsePartnersAsCounterparties;
	
	PurchasesServer.SetContractAvailability(Object, Items.Contract.Enabled, Items.Contract.Visible, Object.Contract);
	
	UpdateTypeOfVATActivity(False);
	FillInSignsOfOverDeliveryUnderDelivery();
	
EndProcedure

&AtServer
Procedure ShowOrderPresentation()
	
	If ValueIsFilled(Object.ReferenceOrder) Then
		ReferenceOrderPresentation = StringFunctions.FormattedString("<a href='Open_Order'>%1</a>  <a href='SelectReference'>Change</a>",String(Object.ReferenceOrder));
	Else
		ReferenceOrderPresentation = StringFunctions.FormattedString("‹%1›  <a href='SelectReference'>%2</a>",NStr("vi = 'chưa chọn';
																													|ru = 'не выбрано';
																													|en = 'not selected'; fa = 'not selected';
																													|it = 'не выбрано';
																													|pl = 'not selected';
																													|tr = 'seçilmedi'"),NStr("vi = 'Chọn';
																																				|ru = 'Выбрать';
																																				|en = 'Select'; fa = 'انتخاب';
																																				|it = 'Выбрать';
																																				|pl = 'Select';
																																				|tr = 'Seç'")); 
	EndIf;
	
EndProcedure

&AtServer
Procedure FillInDefaultContract()
	
	AddlParameters = PurchasesServer.AdditionalContractSelectionParameters();
	
	Object.Contract = PurchasesServer.GetDefaultContract(Object, ContractBusinessTransaction, AddlParameters);
	
EndProcedure

&AtServer
Procedure SetParametersForSelectingWarehouseProps(DisposalWarehouses)
	
	FormField = Items.Warehouse;
	FieldSelectionParameters = New Array;
	
	For Each ChoiceParameter In FormField.ChoiceParameters Do
		If Not ChoiceParameter.Name = "Filter.Ref" Then
			FieldSelectionParameters.Add(ChoiceParameter);
		EndIf;
	EndDo;
	
	If ValueIsFilled(DisposalWarehouses) Then
		SelectionParameterToAdd = New ChoiceParameter("Filter.Ref", DisposalWarehouses);
		
		FieldSelectionParameters.Add(SelectionParameterToAdd);
	EndIf;
	
	FormField.ChoiceParameters = New FixedArray(FieldSelectionParameters);
	
EndProcedure

&AtServer
Procedure UpdateAdditionalAttributesItems()
	
	PropertyManager.UpdateAdditionalAttributesItems(ThisObject);
	
EndProcedure

&AtClient
Procedure QuestionUserBeforeFillingInAgreement(CallbackDescription)
	
	If Object.Discrepancies.Count() = 0
		Or Not ValueIsFilled(Object.Terms) Then
		
		RunCallback(CallbackDescription, False);
		
		Return;
		
	EndIf;
	
EndProcedure

&AtServer
Procedure FillInSignsOfOverDeliveryUnderDelivery()
	
	Underdelivery = Object.Discrepancies.FindRows(New Structure("DiscrepanciesKind", Enums.DiscrepanciesKindOfReceiptsPurchases.Underdelivery));
	Overdelivery = Object.Discrepancies.FindRows(New Structure("DiscrepanciesKind", Enums.DiscrepanciesKindOfReceiptsPurchases.Overdelivery));
	ThereIsUnderdelivery = Underdelivery.Count() > 0;
	ThereisOverdelivery = Overdelivery.Count() > 0;
	
EndProcedure

&AtServer
Function DisposalWarehouses(ClearWarehouse = False)
	
	DisposalWarehouses = New Array;
	
	If TypeOf(Object.ReferenceOrder) = Type("DocumentRef.PurchaseOrder")
		Or TypeOf(Object.ReferenceOrder) = Type("DocumentRef.VendorInvoice") Then
		
		Query = New Query;
		Query.Text =
		"SELECT DISTINCT
		|	GoodsToReceive.Warehouse AS Warehouse
		|FROM
		|	AccumulationRegister.GoodsToReceive AS GoodsToReceive
		|WHERE
		|	GoodsToReceive.DocumentInflow = &ReferenceOrder";
		
		Query.SetParameter("ReferenceOrder", Object.ReferenceOrder);
		
		SetPrivilegedMode(True);
		Selection = Query.Execute().Select();
		SetPrivilegedMode(False);
		
		While Selection.Next() Do
			DisposalWarehouses.Add(Selection.Warehouse);
		EndDo;
		
		If ClearWarehouse
			And ValueIsFilled(Object.Warehouse)
			And DisposalWarehouses.Find(Object.Warehouse) = Undefined Then
			
			Object.Warehouse = Undefined;
			
		EndIf;
		
	EndIf;
	
	Return DisposalWarehouses;
	
EndFunction

#Region SelectionAndProcessingOfQuantityVerification

&AtServer
Procedure ProcessingSelectionOfSelectionOnServer(ValueSelected)
	
	TableOfGoods = GetFromTempStorage(ValueSelected.GoodsAddressInStorage);
	
	For Each RowOfProduct In TableOfGoods Do
		CurrentRow = Object.Discrepancies.Add();
		FillPropertyValues(CurrentRow, RowOfProduct, "Products, Characteristic, NumberOfPackages, Count");
	EndDo;
	
	StructureOfNamesOfTableParts = New Structure("Discrepancies");
	FillInServiceDetailsForProductRange(StructureOfNamesOfTableParts);
	
	FillInStatusesForSpecifyingSeriesServer();
	
EndProcedure

#EndRegion

#Region WorkingWithCounterparties





#EndRegion

#Region Other

&AtClient
Procedure Attachable_CloseForm()
	
	Close();
	
EndProcedure

&AtServer
Procedure SetAvailabilityOfItemsByStatusServer()
	
	If Not UserRightsCached.VarianceFromPurchaseConditions() Then
		
		ItemArray = New Array;
		
		// Header Controls
		ItemArray.Add("Partner");
		ItemArray.Add("Terms");
		ItemArray.Add("Contract");
		ItemArray.Add("PriceIncludesVAT");
		ItemArray.Add("VATTaxation");
		ItemArray.Add("VATActivityType");
		ItemArray.Add("Organization");
		ItemArray.Add("Counterparty");
		ItemArray.Add("BusinessOperation");
		ItemArray.Add("Manager");
		ItemArray.Add("SalesOpportunity");
		ItemArray.Add("Department");
		
		TMCommonUseClientServer.SetPropertyOfFormElements(Items, ItemArray, "ReadOnly", True);
		
	EndIf;
	
EndProcedure

&AtServer
Procedure UpdateTypeOfVATActivity(FillInTypeOfActivity = True)
	
	FillParameters = Documents.WriteOffDiscrepanciesBetweenReceiptAndPurchase.ParametersForFillingInVATActivityType(Object);
	
	If FillInTypeOfActivity Then
		VATAccountingERP.FillInTypeOfActivityVAT(Object.VATActivityType, FillParameters,
			VATAccountingCachedParameterValues);
	EndIf;
	
	VATAccountingERP.FillInActivitySelectionList(Items.VATActivityType,
														Object.VATActivityType,
														FillParameters,
														VATAccountingCachedParameterValues);
	
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
