#Region Variables

&AtClient
Var CachedValues;

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
	
	// Handler of the "Destination" mechanism
	Catalogs.Assignments.DocumentFormWhenCreatedOnServer(ThisObject);

	IncomeAndExpensesServer.OnCreateAtServer(ThisObject, 
		Documents.RecyclableWasteAllocation.ItemsAndDimensionsSelectionParameters());
		
	GLAccountSettingsServer.OnCreateAtServer(ThisObject, 
		Documents.RecyclableWasteAllocation.AccountingAccountSettings_());
		
	FillSelectionLists();
	
	SetTextAndVisibilityOfSelectionOfDistributionBase();
	SetVisibilityOnSelectionByProductGroups();
	SetTextOfSelectionLabelByProductGroups();
	
	If Not ValueIsFilled(Object.Ref) Then
		
		OnReadCreateAtServer();
		
		ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);
		SetSeriesAvailabilityInHeader();
		
	EndIf;
	
	If ClientApplication.CurrentInterfaceVariant() = ClientApplicationInterfaceVariant.Version8_2 Then
		Items.Totals1Group.BackColor = New Color();
	EndIf;
	
	If Parameters.Property("HasErrors") And Parameters.HasErrors Then
		For Each CurError In Parameters.ErrorsArray Do
			CommonClientServer.MessageToUser(CurError.Text, CurError.DataKey, CurError.Field, CurError.DataPath);
		EndDo;
	EndIf;
	
	// StandardSubsystems.Properties
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("Object", Object);
	AdditionalParameters.Insert("ItemForPlacementName", "GroupAdditionalAttributes");
	AdditionalParameters.Insert("DeferredInitialization", True);
	PropertyManager.OnCreateAtServer(ThisForm, AdditionalParameters);
	// End StandardSubsystems.Properties
	
	// StandardSubsystems.ObjectsVersioning
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.ObjectsVersioning
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	
	// StandardSubsystems.FilesOperations
	HyperlinkParameters = FilesOperations.FilesHyperlink();
	HyperlinkParameters.Location = "CommandBar";
	FilesOperations.OnCreateAtServer(ThisObject, HyperlinkParameters);
	// End StandardSubsystems.FilesOperations

	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject);
	// End IntegrationWith1CDocumentManagementSubsystem
	
	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)

	// StandardSubsystems.AccessManagement
	AccessManagement.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.AccessManagement
	
	// StandardSubsystems.PeriodClosingDates
	PeriodClosingDates.ObjectOnReadAtServer(ThisForm, CurrentObject);
	// End StandardSubsystems.PeriodClosingDates
	
	// StandardSubsystems.Properties
	PropertyManager.OnReadAtServer(ThisForm, CurrentObject);
	// End StandardSubsystems.Properties
	
	OnReadCreateAtServer();
	
	DocumentCorrection.OnReadAtServer(ThisForm, Items.LineCorrection);
	
	FormEvents.OnReadAtServer(ThisObject, CurrentObject);
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	// End StandardSubsystems.AttachableCommands
EndProcedure

&AtClient
Procedure ChoiceProcessing(ValueSelected, ChoiceSource)
	
	If ProductsClient.ThisIsIndicationOfSeries(ChoiceSource) Then
		
		ProductsClient.ProcessSeriesIndication(ThisForm, SeriesSpecificationParameters, ValueSelected);
		
		If PriceManagementSystemClient.ItIsNecessaryToRecalculatePriceWhenChanging(Object.Products, "Series", Object.Date) Then
	
			StructureOfActions = New Structure;
			StructureOfActions.Insert("FillInSalePrice", BatchProcessingOfTablePartClientServer.ParametersForFillingInPriceInTSLine(Object));
			StructureOfActions.Insert("RecalculateAmount", "Count");
			
			If Not StructureOfActions.Count() = 0 Then
				BatchProcessingOfTablePartClient.ProcessTSString(Object, StructureOfActions, CachedValues);
			EndIf;
		EndIf;
		
		UpdateCachedHeaderValuesToAccountForSeries();
		
		UpdateTotals();
		
	EndIf;
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	// StandardSubsystems.Properties
	If PropertyManagerClient.ProcessNotifications(ThisForm, EventName, Parameter) Then
		UpdateAdditionalAttributesItems();
		PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
	EndIf;
	// End StandardSubsystems.Properties
	
	DocumentCorrectionClient.NotificationProcessing(ThisForm, EventName, Parameter, Source);
	
	FormEventsClient.NotificationProcessing(ThisObject, EventName, Parameter, Source);
	
	// StandardSubsystems.FilesOperations
	FilesOperationsClient.NotificationProcessing(ThisObject, EventName);
	// End StandardSubsystems.FilesOperations

EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)

	// StandardSubsystems.AccessManagement
	AccessManagement.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	// End StandardSubsystems.AccessManagement
	
	IncomeAndExpensesServer.AfterWriteAtServer(ThisObject);
	GLAccountSettingsServer.AfterWriteAtServer(ThisObject);
	
	FillInServiceDetailsOfForm();
	CostsServer.FillInCharacteristicsOfProductsByBatchOfProduction(Object.ProductionLots);
	
	ProvisionInDocumentsServer.CheckToRunBackgroundInventoryAllocationJob();
	
	ConfigurationModificationOverridable.AfterWriteAtServer(ThisForm, CurrentObject, WriteParameters);
	
	FormEvents.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	// StandardSubsystems.Properties
	PropertyManager.BeforeWriteAtServer(ThisForm, CurrentObject);
	// End StandardSubsystems.Properties
	
	GLAccountSettingsServer.BeforeWriteAtServer(ThisObject, CurrentObject);
	
	If Not Cancel Then
		CurrentObject.FilterByProductsGroups.Clear();
		If UseProductGroupSelection Then
			For Each Item In FilterByProductsGroups Do 
				NewRow = CurrentObject.FilterByProductsGroups.Add();
				NewRow.ProductsGroup = Item.Value;
			EndDo;
		EndIf;
		CurrentObject.FilterByMaterials.Clear();
		If Object.AllocationBase = Enums.TypesOfCostAllocatingBase.QuantityOfSpecifiedMaterials
			Or Object.AllocationBase = Enums.TypesOfCostAllocatingBase.WeightOfSpecifiedMaterials
			Or Object.AllocationBase = Enums.TypesOfCostAllocatingBase.VolumeOfSpecifiedMaterials Then
			For Each Item In FilterByMaterials Do 
				NewRow = CurrentObject.FilterByMaterials.Add();
				NewRow.Material = Item.Value;
			EndDo;
		EndIf;
		CurrentObject.FilterByActivityKind.Clear();
		If Object.AllocationBase = Enums.TypesOfCostAllocatingBase.NumberOfWorksOfSpecifiedKinds Then
			For Each Item In FilterByActivityKind Do 
				NewRow = CurrentObject.FilterByActivityKind.Add();
				NewRow.WorkKind = Item.Value;
			EndDo;
		EndIf;
	EndIf;

	ConfigurationModificationOverridable.BeforeWriteAtServer(ThisForm, Cancel, CurrentObject, WriteParameters);

	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.BeforeWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	// End IntegrationWith1CDocumentManagementSubsystem
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	If UpdateOnOpening Then
		OnReadCreateAtServer();
	EndIf;
	
	// StandardSubsystems.Properties
	PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
	// End StandardSubsystems.Properties
	
	SetVisibilityOfDistributionRuleSettings();
	
	RestrictionOfRecipientType();
	SetDesignCharacteristics();
	SetDestinationClearance();
	
	UpdateCachedHeaderValuesToAccountForSeries();
	
	UpdateTotals();
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// The end of the standard subsystem.Pluggable commands
	// Standard subsystems.Worksfiles
	FilesOperationsClient.OnOpen(ThisObject, Cancel);
	// End StandardSubsystems.FilesOperations

EndProcedure

&AtClient
Procedure BeforeWrite(Cancel, WriteParameters)
	
	FormEventsClient.BeforeWrite(ThisObject, Cancel, WriteParameters);
	
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)

	Notify("Write_RecyclableWasteAllocation");
	
	SetDesignCharacteristics();
	SetDestinationClearance();
	
	ConfigurationModificationClientOverridable.AfterWrite(ThisForm, WriteParameters);
	
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
	PropertyManager.FillCheckProcessing(ThisForm, Cancel, CheckedAttributes);
	// End StandardSubsystems.Properties
	
	DataKey = TMCommonUse.DataKeyForMessageToUser(ThisObject);
	
	If FilterByMaterials.Count() = 0 And (Object.AllocationBase = Enums.TypesOfCostAllocatingBase.QuantityOfSpecifiedMaterials
		Or Object.AllocationBase = Enums.TypesOfCostAllocatingBase.VolumeOfSpecifiedMaterials
		Or Object.AllocationBase = Enums.TypesOfCostAllocatingBase.WeightOfSpecifiedMaterials) Then
		
		MessageText = NStr("vi = 'Không quy định nguyên vật liệu cho cơ sở phân bổ';
							|ru = 'Не указаны материалы для базы распределения';
							|en = 'Materials for allocation base are not specified'; fa = 'Materials for allocation base are not specified';
							|it = 'Non sono indicati i materiali per la base di distribuzione';
							|pl = 'Nie określono materiałów dla bazy przydziału.';
							|tr = 'Tahsisat tabanı için herhangi bir malzeme belirtilmedi'");
		CommonClientServer.MessageToUser(MessageText,DataKey,,,Cancel);
		
	ElsIf FilterByActivityKind.Count() = 0 And (Object.AllocationBase = Enums.TypesOfCostAllocatingBase.NumberOfWorksOfSpecifiedKinds) Then
		
		MessageText = NStr("vi = 'Không chỉ định loại công việc cho cơ sở phân bổ';
							|ru = 'Не указаны виды работ для базы распределения';
							|en = 'Activity kinds for allocation base are not specified'; fa = 'Activity kinds for allocation base are not specified';
							|it = 'Non sono indicati i tipi di lavori per la base di distribuzione';
							|pl = 'Nie określono rodzaje robót dla bazy przydziału.';
							|tr = 'Tahsisat tabanı için herhangi bir etkinlik türü belirtilmedi'");
		CommonClientServer.MessageToUser(MessageText,DataKey,,,Cancel);
		
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure PagesOnCurrentPageChange(Item, CurrentPage)
	
	// StandardSubsystems.Properties
	If CurrentPage.Name = "AdvancedGroup"
		And Not ThisObject.PropertiesParameters.DeferredInitializationExecuted Then
		
		PropertiesExecuteDeferredInitialization();
		PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
	EndIf;
	// End StandardSubsystems.Properties
	
EndProcedure

&AtClient
Procedure LineCorrectionURLProcessing(Item, FormattedStringURL, StandardProcessing)
	
	DocumentCorrectionClient.StringFixHandlingNavigationLinks(
		ThisObject, FormattedStringURL, StandardProcessing);
		
EndProcedure

#Region EventHandlersForFormHeaderElementsMainTab

&AtClient
Procedure DateOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	
	DateOfChangeOnServer();
	
EndProcedure

&AtServer
Procedure DateOfChangeOnServer()
	
	PrepareFillSetSeriesVisibility();
	UpdateIssueForActivities();
	
EndProcedure

&AtClient
Procedure OrganizationOnChange(Item)
	
	OrganizationWhenChangedOnServer();
	
EndProcedure

&AtServer
Procedure OrganizationWhenChangedOnServer()
	
	UpdateIssueForActivities();
	
EndProcedure

&AtClient
Procedure ProductsOnChange(Item)
	
	CurrentRow = New Structure("Products, Characteristic, Series, BatchesIndicationStatus,
									|ItemVariantsAreUsed, ItemsType, PriceKind, Price");
	
	FillPropertyValues(CurrentRow, Object);
	
	StructureOfActions = New Structure;
											
	AddActionsToStructureWhenChangingProducts(ThisForm, StructureOfActions);
	AddActionsToStructureWhenQuantityChanges(StructureOfActions);
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
	FillPropertyValues(Object, CurrentRow);
	
	ItemsType				= CurrentRow.ItemsType;
	ItemVariantsAreUsed	= CurrentRow.ItemVariantsAreUsed;
	
	SetDesignCharacteristics();
	SetDestinationClearance();
	
	ProductsOnChangeServer(CachedValues);
	
	UpdateCachedHeaderValuesToAccountForSeries();
	
	RestrictionOfRecipientType();
	
	Object.Recipient = Items.Recipient.TypeRestriction.AdjustValue(Object.Recipient);
	
EndProcedure

&AtServer
Procedure ProductsOnChangeServer(CachedValues)
	
	SetRecipientHeader();
	DefaultRecipientIsServer();
	SetRecipientVisibility();
	
	PrepareFillSetSeriesVisibility();
	
	SetQuantityHeader();
	
EndProcedure

&AtClient
Procedure CharacteristicOnChange(Item)
	
	CurrentRow = New Structure("Products, Characteristic, Series, Price");
	
	FillPropertyValues(CurrentRow, Object);

	StructureOfActions = New Structure;
	
	AddActionsToStructureWhenCharacteristicChanges(ThisForm, StructureOfActions);
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
	FillPropertyValues(Object, CurrentRow);
	SetDesignCharacteristics();
	
	If ProductsClient.YouNeedToUpdateStatusOfSeriesInHeader(Object, CachedValues, SeriesSpecificationParameters) Then
		FillInStatusesOfSpecifyingSeriesWhenChangingProductInHeader(CachedValues);
		UpdateCachedHeaderValuesToAccountForSeries();
	EndIf;
	
EndProcedure

&AtClient
Procedure SeriesOnChange(Item)
	
	ValueSelected = ProductsClientServer.SelectedSeries();
	ValueSelected.Value = Object.Series;
	
	ProductsClient.ProcessSeriesIndication(ThisForm, SeriesSpecificationParameters, ValueSelected);
	UpdateCachedHeaderValuesToAccountForSeries();
	
	If PriceManagementSystemClient.ItIsNecessaryToRecalculatePriceWhenChanging(Object.Products, "Series", Object.Date) Then

		StructureOfActions = New Structure;
		StructureOfActions.Insert("FillInSalePrice", BatchProcessingOfTablePartClientServer.ParametersForFillingInPriceInTSLine(Object));
		StructureOfActions.Insert("RecalculateAmount", "Count");
		
		If Not StructureOfActions.Count() = 0 Then
			BatchProcessingOfTablePartClient.ProcessTSString(Object, StructureOfActions, CachedValues);
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure SeriesStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	OpenSelectionOfSeries(Item.EditText);
	
EndProcedure

&AtClient
Procedure CountOnChange(Item)
	
	StructureOfActions = New Structure;
	
	AddActionsToStructureWhenQuantityChanges(StructureOfActions);
	
	BatchProcessingOfTablePartClient.ProcessTSString(Object, StructureOfActions, CachedValues);
	
	If ProductsClient.YouNeedToUpdateStatusOfSeriesInHeader(Object, CachedValues, SeriesSpecificationParameters) Then
		FillInStatusesOfSpecifyingSeriesWhenChangingProductInHeader(CachedValues);
		UpdateCachedHeaderValuesToAccountForSeries();
	EndIf;
	
	UpdateTotals();
	
EndProcedure

&AtClient
Procedure PriceOnChange(Item)
	
	StructureOfActions = New Structure;
	
	StructureOfActions.Insert("RecalculateAmount", "Count");
	
	BatchProcessingOfTablePartClient.ProcessTSString(Object, StructureOfActions, CachedValues);
	
	UpdateTotals();
	
EndProcedure

&AtClient
Procedure CurrencyOnChange(Item)
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.TimeMeasurement(True,
		"Document.RecyclableWasteAllocation.Form.DocumentForm.Item.Currency.OnChange");
		
	If ValueIsFilled(Object.Currency) And ValueIsFilled(DocumentCurrency) And DocumentCurrency <> Object.Currency Then
		CurrencyOnChangeServer(CachedValues);
		UpdateTotals();
	EndIf;
	
	DocumentCurrency = Object.Currency;
	
EndProcedure

&AtServer
Procedure CurrencyOnChangeServer(CachedValues)
	
	DocumentDate				= ?(ValueIsFilled(Object.Date), Object.Date, CurrentSessionDate());
	StructureOfOldCurrencyRates	= ProcessingOfExchangeRatesTM.GetCurrencyRate(DocumentCurrency, DocumentDate);
	StructureOfNewCurrencyRates	= ProcessingOfExchangeRatesTM.GetCurrencyRate(Object.Currency, DocumentDate);
	
	// Recalculate the price
	Object.Price = ProcessingOfExchangeRatesTM.ConvertAtRate(Object.Price,
		StructureOfOldCurrencyRates, StructureOfNewCurrencyRates);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateAmount", "Count");
	BatchProcessingOfTablePartServer.ProcessTSString(Object, StructureOfActions, CachedValues);
	
EndProcedure

&AtClient
Procedure DepartmentOnChange(Item)
	
	If Not DepartmentBeforeChange = Object.Department Then
		DepartmentOnChangeServer();
		UpdateCachedHeaderValuesToAccountForSeries();
	EndIf;
	
EndProcedure

&AtServer
Procedure DepartmentOnChangeServer()
	
	DefaultRecipientIsServer();
	
	PrepareFillSetSeriesVisibility();
	
	Object.Purpose = Undefined;
	DepartmentBeforeChange = Object.Department;
	
EndProcedure

&AtClient
Procedure RecipientOnChange(Item)
	
	RecipientOnChangeServer();
	
	UpdateCachedHeaderValuesToAccountForSeries();
	
EndProcedure

&AtServer
Procedure RecipientOnChangeServer()
	
	PrepareFillSetSeriesVisibility();
	
EndProcedure

&AtClient
Procedure BatchesIndicationStatusClick(Item, StandardProcessing)
	
	ParametersOfSeriesIndicationForm = ParametersOfSeriesIndicationForm();
	
	AdditionalParameters = New Structure("ParametersOfSeriesIndicationForm", ParametersOfSeriesIndicationForm);
	CallbackDescription = New CallbackDescription("BatchesIndicationStatusClickCompletion", ThisObject, AdditionalParameters);
	
	OpenForm(ParametersOfSeriesIndicationForm.FormName, ParametersOfSeriesIndicationForm, ThisForm,,,, CallbackDescription, FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure BatchesIndicationStatusClickCompletion(Result, AdditionalParameters) Export
	
	ParametersOfSeriesIndicationForm = AdditionalParameters.ParametersOfSeriesIndicationForm;
	ReturnValue_1 = Result;
	
	If ReturnValue_1 <> Undefined Then
		ProcessSeriesIndication_Server(ParametersOfSeriesIndicationForm);
	EndIf;
	
	UpdateTotals();
	
EndProcedure

&AtClient
Procedure LineOfBusinessOnChange(Item)
	
	DirectionOfActivityWhenChangingOnServer();
	
EndProcedure

&AtServer
Procedure DirectionOfActivityWhenChangingOnServer()
	
	UpdateIssueForActivities();
	
EndProcedure

#EndRegion

#Region EventHandlersForFormHeaderElementsTabByRule

&AtClient
Procedure QuantityAccordingToRuleOnChange(Item)
	
	UpdateTotals();
	
EndProcedure

&AtClient
Procedure AllocatedAccordingToRuleOnChange(Item)
	
	SetVisibilityOfDistributionRuleSettings();
	FillInDefaultSettingsFromDistributionRule(Object.AllocatedAccordingToRule);
	
EndProcedure

&AtClient
Procedure AllocatedAccordingToRuleClearing(Item, StandardProcessing)
	
	SetVisibilityOfDistributionRuleSettings();
	
EndProcedure

&AtClient
Procedure UseProductGroupSelectionOnChange(Item)
	
	SetVisibilityOnSelectionByProductGroups();
	Modified = True;
	
EndProcedure

&AtClient
Procedure LabelFilterByProductGroupsClick(Item, StandardProcessing)
	
	StandardProcessing = False;
	FilterParameters = New Structure();
	FilterParameters.Insert("ArrayOfProductGroups", FilterByProductsGroups.UnloadValues());

	OpenForm("Catalog.CostAllocationRules.Form.FilterForm",
			FilterParameters,
			ThisForm,,,, 
			New CallbackDescription("LabelSelectionClickFinish", ThisObject, "FilterByProductsGroups"), 
			FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure LabelAllocationBaseFilterClick(Item, StandardProcessing)
	
	StandardProcessing = False;
	FilterParameters = New Structure();
	AdditionalSelectionParameter = "";
	If Object.AllocationBase = PredefinedValue("Enum.TypesOfCostAllocatingBase.QuantityOfSpecifiedMaterials")
		Or Object.AllocationBase = PredefinedValue("Enum.TypesOfCostAllocatingBase.WeightOfSpecifiedMaterials")
		Or Object.AllocationBase = PredefinedValue("Enum.TypesOfCostAllocatingBase.VolumeOfSpecifiedMaterials") Then
		FilterParameters.Insert("ArrayOfMaterials", FilterByMaterials.UnloadValues());
		AdditionalSelectionParameter = "FilterByMaterials";
	ElsIf Object.AllocationBase = PredefinedValue("Enum.TypesOfCostAllocatingBase.NumberOfWorksOfSpecifiedKinds") Then
		FilterParameters.Insert("ArrayOfTypesOfWork", FilterByActivityKind.UnloadValues());
		AdditionalSelectionParameter = "FilterByActivityKind";
	EndIf;

	OpenForm("Catalog.CostAllocationRules.Form.FilterForm",
			FilterParameters,
			ThisForm,,,, 
			New CallbackDescription("LabelSelectionClickFinish", ThisObject, AdditionalSelectionParameter), 
			FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

#EndRegion

#Region EventHandlersForFormHeaderElementsAdvancedTab

&AtClient
Procedure ProductionIssueForActivityOnChange(Item)
	ReleaseUnderActivityWhenChangedOnServer();
EndProcedure

&AtServer
Procedure ReleaseUnderActivityWhenChangedOnServer()
	
	ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);
	
EndProcedure

&AtClient
Procedure PriceKindOnChange(Item)
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInSalePrice", BatchProcessingOfTablePartClientServer.ParametersForFillingInPriceInTSLine(Object));
	StructureOfActions.Insert("RecalculateAmount", "Count");
	
	BatchProcessingOfTablePartClient.ProcessTSString(Object, StructureOfActions, CachedValues);
	
	UpdateTotals();
	
EndProcedure

&AtClient
Procedure ProductionIssueForActivityClearing(Item, StandardProcessing)
	StandardProcessing = False;
EndProcedure

#EndRegion

#EndRegion

#Region FormTableItemsEventHandlersProductionLots

&AtClient
Procedure ProductionLotsOnChange(Item)
	
	UpdateTotals();
	
EndProcedure

&AtClient
Procedure ProductionLotsBeforeAddRow(Item, Cancel, Copy, Parent, Var_Group, Parameter)
	
	Cancel = True;
	OpenBatchSelectionForm();
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersOtherExpenses

&AtClient
Procedure OtherExpensesOnChange(Item)
	UpdateTotals();
EndProcedure

&AtClient
Procedure OtherExpensesOnStartEdit(Item, NewRow, Copy)
	
	CurrentData = Items.OtherExpenses.CurrentData;
	IncomeAndExpensesClientServer.WhenAddingRowToTable(ThisObject, CurrentData, "Object.OtherExpenses");
	
	//Setting up accounting accounts 
	If NewRow And Copy Then
		GLAccountSettingsClient.WhenCopyingString(ThisObject, Item);
	EndIf;
	
EndProcedure

&AtClient
Procedure OtherExpensesSelection(Item, RowSelected, Field, StandardProcessing)
	
	GLAccountSettingsClient.OnClick(ThisObject, Field, StandardProcessing);
	
EndProcedure

&AtClient
Procedure OtherExpensesExpenseItemOnChange(Item)
	
	IncomeAndExpensesClientServer.AssetRefOnChange(ThisObject, Items.OtherExpensesExpenseItem);
	
EndProcedure

&AtClient
Procedure OtherExpensesExpenseItemStartChoice(Item, ChoiceData, StandardProcessing)
	
	IncomeAndExpensesClient.StartArticleSelection(ThisObject, Item, StandardProcessing);
	
EndProcedure

&AtClient
Procedure OtherExpensesDimensionOfExpensesStartChoice(Item, ChoiceData, StandardProcessing)
	
	IncomeAndExpensesClient.StartSelectingExpenseAnalytics(ThisObject, Item, StandardProcessing);
	
EndProcedure

&AtClient
Procedure OtherExpensesDimensionOfExpensesAutoComplete(Item, Text, ChoiceData, DataGetParameters, Waiting, StandardProcessing)
	
	IncomeAndExpensesClient.AutoSelectionOfExpenseAnalytics(ThisObject, Item, Text, ChoiceData, DataGetParameters, StandardProcessing);
	
EndProcedure

&AtClient
Procedure OtherExpensesDimensionOfExpensesTextEditEnd(Item, Text, ChoiceData, DataGetParameters, StandardProcessing)
	
	IncomeAndExpensesClient.EndOfCostAnalyticsTextEntry(ThisObject, Item, Text, ChoiceData, DataGetParameters, StandardProcessing);
	
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

// StandardSubsystems.Properties
&AtClient
Procedure Attachable_PropertiesExecuteCommand(ItemOrCommand, Var_URL = Undefined, StandardProcessing = Undefined)
	PropertyManagerClient.ExecuteCommand(ThisObject, ItemOrCommand, StandardProcessing);
EndProcedure
// End StandardSubsystems.Properties

// StandardSubsystems.AttachableCommands
&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
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
Procedure PostDocument(Command)
	
	TMCommonUseClient.Post(ThisForm);
	
EndProcedure

&AtClient
Procedure PostAndClose(Command)
	
	TMCommonUseClient.PostAndClose(ThisForm);
	
EndProcedure

&AtClient
Procedure SpecifySeriesInHeader(Command)
	OpenSelectionOfSeries();
EndProcedure

&AtClient
Procedure WriteDocument(Command)
	
	TMCommonUseClient.Write(ThisForm);
	
EndProcedure

&AtClient
Procedure SetDeletionMarkForADocument(Command)
	
	TMCommonUseClient.SetDeletionMarkForADocument(ThisObject);
	
EndProcedure

&AtClient
Procedure FillInCostingItems(Command)
	
	FillInCalculationArticlesInTabularPart("ProductionLots");
	
EndProcedure

&AtClient
Procedure MoveSettingsToTheCostGenerationModel(Command)
	
	MoveSettingsToTheCostGenerationModelServer();
	Notify("CostGenerationModel_Update");
	
EndProcedure

#Region FormCommandHandlersTableOtherExpenses

&AtClient
Procedure OtherExpensesFillInDepartment(Command)
	
	If Not ProcessingOfTabularFormsClient.SelectedLineToExecuteCommand(Items.OtherExpenses) Then
		Return;
	EndIf;
	
	SelectedRows = Items.OtherExpenses.SelectedRows;
	
	CallbackDescription = New CallbackDescription("OtherExpensesFillInDepartmentCompletion", ThisObject, New Structure("SelectedRows", SelectedRows));
	
	OpenForm(
		"Catalog.BusinessStructure.ChoiceForm",,
		ThisForm,
		,,,
		CallbackDescription,
		FormWindowOpeningMode.LockOwnerWindow);
		
EndProcedure

&AtClient
Procedure OtherExpensesFillInDepartmentCompletion(Result, AdditionalParameters) Export
	
	SelectedRows = AdditionalParameters.SelectedRows;
	
	If ValueIsFilled(Result) Then
		For Each String In SelectedRows Do
			TableRow = Object.OtherExpenses.FindByID(String);
			If TableRow <> Undefined Then
				TableRow.Department = Result;
			EndIf;
		EndDo;
	EndIf;
	
EndProcedure

&AtClient
Procedure OtherExpensesFillInExpenseItem(Command)
	
	If Not ProcessingOfTabularFormsClient.SelectedLineToExecuteCommand(Items.OtherExpenses) Then
		Return;
	EndIf;
	SelectedRows = Items.OtherExpenses.SelectedRows;
	IncomeAndExpensesClient.FillInArticleAndAnalyticsInSelectedLines(
		ThisObject, Items.OtherExpensesExpenseItem, SelectedRows);

EndProcedure

#EndRegion

// IntegrationWith1CDocumentManagementSubsystem
&AtClient
Procedure Attachable_ExecuteIntegrationCommand(Command)
	
	IntegrationWith1CDocumentManagementCoreClient.ExecutePlugInIntegrationCommand(Command, ThisObject, Object);
	
EndProcedure
// End IntegrationWith1CDocumentManagementSubsystem

#EndRegion

#Region Private

&AtServer
Procedure OnReadCreateAtServer()
	
	GLAccountSettingsServer.OnReadAtServer(ThisObject, 
		Documents.RecyclableWasteAllocation.AccountingAccountSettings_());
		
	IncomeAndExpensesServer.OnReadAtServer(ThisObject, 
		Documents.RecyclableWasteAllocation.ItemsAndDimensionsSelectionParameters());
		
	DepartmentBeforeChange = Object.Department;
	FillInDefaultCostingArticle();
	FillInServiceDetailsOfForm();
	CostsServer.FillInCharacteristicsOfProductsByBatchOfProduction(Object.ProductionLots);
	
	DocumentCurrency = Object.Currency;
	
	Items.GroupSelectionByProductType.Visible = AnalyticalAccountingByProductsGroups;
	
	If GetFunctionalOption("ComplexAutomation") Then
		Items.ProductionLotsStage.Visible = False;
	EndIf;
	
	CostsServer.ConfigureParametersForSelectingDistributionRules(
		Object.Department,
		Undefined,
		Items.AllocatedAccordingToRule,
		Enums.AssignmentOfCostAllocationRules.MaterialsAndWorksCostAllocation);
	
	SeriesSpecificationParameters();
	CustomizeSeriesItems();
	SetRecipientVisibility();
	
	SetQuantityHeader();
	
	UpdateIssueForActivities(False);
	
EndProcedure

&AtClient
Procedure RestrictionOfRecipientType()

	If ItemsType = PredefinedValue("Enum.ItemsTypes.Work_5") Then
		RestrictionOfRecipientType = New TypeDescription("CatalogRef.BusinessStructure");
	Else
		RestrictionOfRecipientType = New TypeDescription("CatalogRef.Warehouses");
	EndIf; 
	
	Items.Recipient.TypeRestriction = RestrictionOfRecipientType;

EndProcedure

&AtClient
Procedure UpdateTotals()
	
	QuantityByBatch		= Object.ProductionLots.Total("Count");
	QuantityByExpenditure	= Object.OtherExpenses.Total("Count");
	QuantityAccordingToRule		= Object.QuantityAccordingToRule;
	
	AmountManuallyByBatch	= Object.Price * QuantityByBatch;
	AmountByRules			= Object.Price * QuantityAccordingToRule;
	TheAmountOfTheCosts			= Object.Price * QuantityByExpenditure;
	AmountTotal				= AmountManuallyByBatch + AmountByRules + TheAmountOfTheCosts;
	
EndProcedure

#Region StandardSubsystems

// StandardSubsystems.Properties
&AtServer
Procedure UpdateAdditionalAttributesItems()
	
	PropertyManager.UpdateAdditionalAttributesItems(ThisForm);
	
EndProcedure
// End StandardSubsystems.Properties

#EndRegion

#Region Appearance

&AtServer
Procedure SetConditionalAppearance()
	
	ConditionalAppearance.Items.Clear();
	
	// Rule distribution, Articulation articles - mark blank
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.AllocatedAccordingToRule.Name);
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ProductCostElement.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.QuantityAccordingToRule");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = 0;

	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	
EndProcedure

&AtClient
Procedure SetDesignCharacteristics()
	
	CharacteristicField = Items.Characteristic;
	
	If ItemVariantsAreUsed Then
		CharacteristicField.InputHint = "";
		CharacteristicField.Enabled = True;
		CharacteristicField.AutoMarkIncomplete = True;
	Else
		CharacteristicField.InputHint = NStr("vi = '<không sử dụng đặc tính>';
											|ru = '<характеристики не используются>';
											|en = '<variants are not used>'; fa = '<گونه‌ها استفاده نمی‌شوند>';
											|it = '<le caratteristiche non vengono usate>';
											|pl = '<charakterystyki nie dotyczą>';
											|tr = '<varyantlar kullanılmamaktadır>'");
		CharacteristicField.Enabled = False;
		CharacteristicField.AutoMarkIncomplete = False;
	EndIf;
	
EndProcedure

&AtClient
Procedure SetDestinationClearance()
	
	DestinationField_ = Items.Purpose;
	
	If ItemsType = PredefinedValue("Enum.ItemsTypes.ReusablePackage")
		Or ItemsType = PredefinedValue("Enum.ItemsTypes.OperationService") Then
		Object.Purpose = Undefined;
		DestinationField_.InputHint = NStr("vi = '<chỉ dành cho hàng hóa và công trình>';
											|ru = '<только для товаров и работ>';
											|en = '<only for goods and labor>'; fa = '<only for goods and labor>';
											|it = '<solo per merci e lavori>';
											|pl = '<tylko dla towarów i robót>';
											|tr = '<sadece ürünler ve işler için>'");
		DestinationField_.Enabled = False;
	Else
		DestinationField_.InputHint = "";
		DestinationField_.Enabled = True;
	EndIf;
	
EndProcedure

&AtServer
Procedure SetQuantityHeader()
	
	UnitOfMeasure = Common.ObjectAttributeValue(Object.Products, "UnitOfMeasure");
	If ValueIsFilled(UnitOfMeasure) Then
		TitleText = NStr("vi = 'Số lượng%1';
						|ru = 'Количество%1';
						|en = 'Quantity%1'; fa = 'Quantity%1';
						|it = 'Quantità%1';
						|pl = 'Ilość%1';
						|tr = 'Miktar%1'");
		StringParameter_ = " (" + Common.ObjectAttributeValue(UnitOfMeasure, "Description") + ")";
		TitleText = StringFunctionsClientServer.SubstituteParametersToString(TitleText, StringParameter_);
		Items.ProductionLotsCount.Title = TitleText;
		Items.OtherExpensesCount.Title = TitleText;
	EndIf;
	
EndProcedure

&AtClient
Procedure SetVisibilityOfDistributionRuleSettings()
	
	If ValueIsFilled(Object.AllocatedAccordingToRule) Then
		Items.MoveSettingsToARule.Visible	= True;
		Items.AllocationBaseGroup.Visible		= True;
		Items.GroupSelectionByProductType.Visible	= AnalyticalAccountingByProductsGroups;
		Items.ProductCostElement.Visible			= True;
	Else
		Items.MoveSettingsToARule.Visible	= False;
		Items.AllocationBaseGroup.Visible		= False;
		Items.GroupSelectionByProductType.Visible	= False;
		Items.ProductCostElement.Visible			= False;
	EndIf;
	SetTextAndVisibilityOfSelectionOfDistributionBase();
	
EndProcedure

&AtServer
Procedure SetVisibilityOnSelectionByProductGroups()
	
	Items.LabelFilterByProductGroups.Visible = UseProductGroupSelection;
	
EndProcedure

&AtServer
Procedure SetRecipientHeader()
	
	If ItemsType = Enums.ItemsTypes.Work_5 Then
		Items.Recipient.Title = NStr("vi = 'Bộ phận-nơi nhận';
									|ru = 'Подразделение-получатель';
									|en = 'Receiving business unit'; fa = 'واحد تجاری دریافت‌کننده';
									|it = 'Reparto-destinatario';
									|pl = 'Receiving business unit';
									|tr = 'Alıcı departman'");
	Else
		Items.Recipient.Title = NStr("vi = 'Kho bãi';
									|ru = 'Склад';
									|en = 'Warehouse'; fa = 'Warehouse';
									|it = 'Magazzino';
									|pl = 'Warehouse';
									|tr = 'Ambar'");
	EndIf;
	
EndProcedure

&AtServer
Procedure SetTextOfSelectionLabelByProductGroups()
	
	LabelText = "";
	For Each Item In FilterByProductsGroups Do 
		LabelText = LabelText + ?(LabelText = "", "", "; ") + TrimAll(Item.Value);
	EndDo;
	If LabelText = "" Then
		LabelText = NStr("vi = 'Cho biết nhóm sản phẩm (loại)';
						|ru = 'Указать группы (виды) продукции';
						|en = 'Specify groups (kinds) of manufactured products'; fa = 'Specify groups (kinds) of manufactured products';
						|it = 'Indicare i gruppi (tipi) di produzione';
						|pl = 'Określ grupy (rodzaje) produkcji';
						|tr = 'İmal edilen ürün grubunu (türünü) belirt'");
	EndIf;
	
	LabelFilterByProductGroups = LabelText;
	
EndProcedure

&AtServer
Procedure SetTextAndVisibilityOfSelectionOfDistributionBase()

	If Object.AllocationBase = Enums.TypesOfCostAllocatingBase.QuantityOfSpecifiedMaterials
		Or Object.AllocationBase = Enums.TypesOfCostAllocatingBase.WeightOfSpecifiedMaterials
		Or Object.AllocationBase = Enums.TypesOfCostAllocatingBase.VolumeOfSpecifiedMaterials Then
		Items.LabelAllocationBaseFilter.Visible = True;
		SetTextOfSelectionLabelBasedOnMaterials();
	ElsIf Object.AllocationBase = Enums.TypesOfCostAllocatingBase.NumberOfWorksOfSpecifiedKinds Then
		Items.LabelAllocationBaseFilter.Visible = True;
		SetTextOfSelectionLabelByTypeOfWork();
	Else
		Items.LabelAllocationBaseFilter.Visible = False;
	EndIf;
	
EndProcedure

&AtServer
Procedure SetTextOfSelectionLabelBasedOnMaterials()
	
	LabelText = "";
	For Each Item In FilterByMaterials Do 
		LabelText = LabelText + ?(LabelText = "", "", "; ") + TrimAll(Item.Value);
	EndDo;
	If LabelText = "" Then
		LabelText = NStr("vi = 'Chỉ định nguyên vật liệu';
						|ru = 'Указать материалы';
						|en = 'Specify materials'; fa = 'تعیین مواد';
						|it = 'Indicare i materiali';
						|pl = 'Określ materiały';
						|tr = 'Malzemeleri belirt'");
	EndIf;
	
	LabelAllocationBaseFilter = LabelText;
	
EndProcedure

&AtServer
Procedure SetTextOfSelectionLabelByTypeOfWork()
	
	LabelText = "";
	For Each Item In FilterByActivityKind Do 
		LabelText = LabelText + ?(LabelText = "", "", "; ") + TrimAll(Item.Value);
	EndDo;
	If LabelText = "" Then
		LabelText = NStr("vi = 'Chỉ định loại công việc';
						|ru = 'Указать виды работ';
						|en = 'Specify activity kinds'; fa = 'تعیین انواع فعالیت';
						|it = 'Indicare i tipi dei lavori';
						|pl = 'Określ rodzaje prac';
						|tr = 'Etkinlik türlerini belirt'");
	EndIf;
	
	LabelAllocationBaseFilter = LabelText;
	
EndProcedure

&AtServer
Procedure SetRecipientVisibility()
	If Not UseSeveralWarehouses
		And (Not ItemsType = Enums.ItemsTypes.Work_5
			Or Object.Products = Catalogs.Products.EmptyRef())Then
		Items.Recipient.Visible = False;
	Else
		Items.Recipient.Visible = True;
	EndIf;
EndProcedure

#EndRegion

#Region FormServiceCommandHandlers

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

&AtClient
Procedure FillInCalculationArticlesInTabularPart(TSName)
	
	CurrentData = Items[TSName].CurrentData;
	
	If CurrentData = Undefined Then
		WarningText = NStr("vi = 'Cần chọn các dòng để điền dạng tính giá thành.';
							|ru = 'Необходимо выбрать строки, для которых необходимо заполнить статью калькуляции.';
							|en = 'Select the lines for which it is required to populate the product cost element.'; fa = 'Select the lines for which it is required to populate the product cost element.';
							|it = 'È necessario selezionare le righe per le quali si deve compilare la voce di calcolo.';
							|pl = 'Należy wybrać wiersze, dla których trzeba wypełnić pozycję kalkulacji.';
							|tr = 'Ürün maliyet kalemini doldurmanız gereken satırları seçmeniz gerekmektedir.'");
		CommonClientServer.MessageToUser(WarningText);
		Return;
	EndIf;
	
	ProductCostElement = Undefined;
	
	FilterParameters = New Structure;
	FilterParameters.Insert("ExpenseType", PredefinedValue("Enum.CostTypes.RecyclableWaste"));
	
	FormParameters = New Structure;
	FormParameters.Insert("Filter", FilterParameters);
	FormParameters.Insert("MultipleChoice", False);
	
	CallbackDescription = New CallbackDescription("FillOutWHCalculationArticlesEnd", ThisObject, TSName);
	
	OpenForm("Catalog.ProductCostElements.ChoiceForm", FormParameters,,,,, CallbackDescription);
	
EndProcedure

&AtClient
Procedure FillOutWHCalculationArticlesEnd(Result, TSName) Export

	If Result = Undefined Then
		Return;
	EndIf;
	
	SelectedRows = Items[TSName].SelectedRows;
	TabularSection = Object[TSName];
	
	For Each RowID In SelectedRows Do
		
		CurrentData = TabularSection.FindByID(RowID);
		CurrentData.ProductCostElement = Result;
		
	EndDo;

EndProcedure

&AtClient
Procedure OpenBatchSelectionForm()
	
	FilterStructure1 = New Structure();
	FilterStructure1.Insert("Organization",		Object.Organization);
	FilterStructure1.Insert("Department",	Object.Department);
	FilterStructure1.Insert("Purpose",		Object.Purpose);
	
	FormParameters = New Structure();
	FormParameters.Insert("BeginOfPeriod",	BegOfMonth(Object.Date));
	FormParameters.Insert("PeriodEnding",	EndOfMonth(Object.Date));
	FormParameters.Insert("FilterStructure1",	FilterStructure1);
	
	Notification = New CallbackDescription("OpenBatchSelectionFormCompletion", ThisForm);
	
	OpenForm("CommonForm.SelectProductionLots",
		FormParameters,
		ThisForm,,,,
		Notification,
		FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure OpenBatchSelectionFormCompletion(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	OpenBatchSelectionFormCompletionServer(Result);
	UpdateTotals();
	
EndProcedure

&AtServer
Procedure OpenBatchSelectionFormCompletionServer(Result)
	
	BatchTable_		= GetFromTempStorage(Result);
	Modified	= True;
	
	For Each String In BatchTable_ Do
		
		NewRow = Object.ProductionLots.Add();
		FillPropertyValues(NewRow, String);
		
		If ValueIsFilled(ProductCostElement) Then
			NewRow.ProductCostElement = ProductCostElement;
		EndIf;
		
	EndDo;
	
EndProcedure

&AtClient
Procedure LabelSelectionClickFinish(Result, AdditionalParameters) Export
	
	SelectionResult_ = Result;
	If TypeOf(SelectionResult_) = Type("Array") Then
		If AdditionalParameters = "FilterByProductsGroups" Then
			FilterByProductsGroups.LoadValues(SelectionResult_);
			SetTextOfSelectionLabelByProductGroups();
			Modified = True;
		ElsIf AdditionalParameters = "FilterByMaterials" Then
			FilterByMaterials.LoadValues(SelectionResult_);
			SetTextOfSelectionLabelBasedOnMaterials();
			Modified = True;
		ElsIf AdditionalParameters = "FilterByActivityKind" Then
			FilterByActivityKind.LoadValues(SelectionResult_);
			SetTextOfSelectionLabelByTypeOfWork();
			Modified = True;
		EndIf;
	EndIf;

EndProcedure

&AtServer
Procedure MoveSettingsToTheCostGenerationModelServer()
	
	Record = InformationRegisters.CostGenerationModels.CreateRecordManager();
	
	FillPropertyValues(Record, Object);
	
	Record.Department = Object.Department;
	Record.CostGenerationModel = Enums.ModelTypesOfCosting.ProductionIssueAtFixedCost;
	Record.AllocatedAccordingToRule = Object.AllocatedAccordingToRule;
	Record.BillOfMaterials = Undefined;
	Record.RecordCostsByADocument = False;
	
	Record.Write(True);
	
EndProcedure

#EndRegion

#Region ProcessingActionStructure

&AtClientAtServerNoContext
Procedure AddActionsToStructureWhenChangingProducts(Form, StructureOfActions)

	Object = Form.Object;
	
	StructureOfActions.Insert("CheckCharacteristicsByOwner", Object.Characteristic);
	
	StructureOfActions.Insert("FillInFeatureAttribute",
											New Structure("Products", "ItemVariantsAreUsed"));
	StructureOfActions.Insert("FillInProductTypeAttribute_",
											New Structure("Products", "ItemsType"));
	
	StructureOfActions.Insert("ProductsOnChangeOverridable", New Structure("FormName, TabularSectionName",
		Form.FormName, "Object"));
		
	StructureOfActions.Insert("FillInSalePrice", BatchProcessingOfTablePartClientServer.ParametersForFillingInPriceInTSLine(Object));
	StructureOfActions.Insert("RecalculateAmount", "Count");
	
EndProcedure

&AtClientAtServerNoContext
Procedure AddActionsToStructureWhenCharacteristicChanges(Form, StructureOfActions)

	Object = Form.Object;
	StructureOfActions.Insert("CharacteristicOnChangeOverridable", New Structure("FormName, TabularSectionName",
		Form.FormName, "Object"));
	
	StructureOfActions.Insert("FillInSalePrice", BatchProcessingOfTablePartClientServer.ParametersForFillingInPriceInTSLine(Object));
	StructureOfActions.Insert("RecalculateAmount", "Count");
	
EndProcedure

&AtClientAtServerNoContext
Procedure AddActionsToStructureWhenQuantityChanges(StructureOfActions)
	
	StructureOfActions.Insert("RecalculateAmount", "Count");
	
EndProcedure

#EndRegion

#Region FillType

&AtServer
Procedure FillInServiceDetailsForProductRange()
	
	ProductAttributes = Common.ObjectAttributesValues(Object.Products, "ItemsType, UseVariants");

	ItemsType 			= ProductAttributes.ItemsType;
	UseVariants	= ProductAttributes.UseVariants;
		
	OptionsArray = New Array;
	OptionsArray.Add(Enums.ItemVariantsUsageOptions.CommonForItemKind);
	OptionsArray.Add(Enums.ItemVariantsUsageOptions.CommonWithOtherItemKind);
	OptionsArray.Add(Enums.ItemVariantsUsageOptions.SpecialForItems);
	
	ItemVariantsAreUsed = Not (OptionsArray.Find(UseVariants) = Undefined);
	
	SetRecipientHeader();
	
EndProcedure

&AtServer
Procedure FillInDefaultCostingArticle()
	
	If Not ValueIsFilled(Object.Products) Then
		ProductCostElement = Catalogs.ProductCostElements.EmptyRef();
		Return;
	EndIf;
	Query = New Query;
	Query.Text =
	"SELECT ALLOWED TOP 1
	|	ProductionLots.ProductCostElement AS ProductCostElement,
	|	ProductionLots.Ref.Date AS Date
	|FROM
	|	Document.RecyclableWasteAllocation.ProductionLots AS ProductionLots
	|WHERE
	|	ProductionLots.Ref.Products = &Products
	|	AND ProductionLots.Ref.Posted
	|
	|ORDER BY
	|	Date DESC";
	
	Query.SetParameter("Products", Object.Products);
	
	Selection = Query.Execute().Select();
	If Selection.Next() Then
		If ValueIsFilled(Selection.ProductCostElement) Then
			ProductCostElement = Selection.ProductCostElement
		Else
			If Selection.Next() Then
				ProductCostElement = Selection.ProductCostElement;
			EndIf;
		EndIf;
	EndIf;
EndProcedure

&AtServer
Procedure FillInDefaultSettingsFromDistributionRule(Rule)
	
	Query = New Query("
	|SELECT
	|	M.Material
	|FROM
	|	Catalog.CostAllocationRules.FilterByMaterials AS M
	|WHERE
	|	M.Ref = &Ref
	|;
	|
	|///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	R.WorkKind
	|FROM
	|	Catalog.CostAllocationRules.FilterByActivityKind AS R
	|WHERE
	|	R.Ref = &Ref
	|;
	|
	|///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	P.ProductsGroup
	|FROM
	|	Catalog.CostAllocationRules.FilterByProductsGroups AS P
	|WHERE
	|	P.Ref = &Ref
	|;
	|
	|///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	From1.ProductCostElement
	|FROM
	|	Catalog.CostAllocationRules AS From1
	|WHERE
	|	From1.Ref = &Ref
	|;
	|
	|///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	From1.AllocationBase
	|FROM
	|	Catalog.CostAllocationRules AS From1
	|WHERE
	|	From1.Ref = &Ref
	|;
	|
	|///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////");
	
	Query.SetParameter("Ref", Rule);
	Result = Query.ExecuteBatch();
	FilterByMaterials.LoadValues(Result[0].Unload().UnloadColumn("Material"));
	FilterByActivityKind.LoadValues(Result[1].Unload().UnloadColumn("WorkKind"));
	FilterByProductsGroups.LoadValues(Result[2].Unload().UnloadColumn("ProductsGroup"));
	
	UseProductGroupSelection = (FilterByProductsGroups.Count() > 0);
	
	Object.ProductCostElement = ?(Not Result[3].IsEmpty(),
										Result[3].Unload()[0].ProductCostElement,
										Catalogs.ProductCostElements.EmptyRef());
	
	Object.AllocationBase = ?(Not Result[4].IsEmpty(),
										Result[4].Unload()[0].AllocationBase,
										Enums.TypesOfCostAllocatingBase.EmptyRef());
	
	SetTextAndVisibilityOfSelectionOfDistributionBase();
	SetVisibilityOnSelectionByProductGroups();
	SetTextOfSelectionLabelByProductGroups();
	
EndProcedure

&AtServer
Procedure FillSelectionLists()
	
	FilterByProductsGroups.LoadValues(Object.FilterByProductsGroups.Unload(, "ProductsGroup").UnloadColumn("ProductsGroup"));
	UseProductGroupSelection = (FilterByProductsGroups.Count() > 0);
	FilterByActivityKind.LoadValues(Object.FilterByActivityKind.Unload(, "WorkKind").UnloadColumn("WorkKind"));
	FilterByMaterials.LoadValues(Object.FilterByMaterials.Unload(, "Material").UnloadColumn("Material"));
	
EndProcedure

&AtServer
Procedure DefaultRecipientIsServer()
	
	If ItemsType = Enums.ItemsTypes.Work_5
		And (Not ValueIsFilled(Object.Recipient)
			Or Not TypeOf(Object.Recipient) = Type("CatalogRef.BusinessStructure")) Then
		Object.Recipient = Object.Department;
	ElsIf Not ItemsType = Enums.ItemsTypes.Work_5 Then
		If UseSeveralWarehouses Then
			Object.Recipient = SettingsValueCached.GetDefaultShopPantry(Object.Department, Object.Recipient);
		Else
			Object.Recipient = DefaultWarehouse;
		EndIf;
	EndIf;
	
EndProcedure

&AtServer
Procedure FillInServiceDetailsOfForm()
	
	UseSeveralWarehouses = GetFunctionalOption("UseSeveralWarehouses");
	TargetCostPriceType = Catalogs.TypesOfPrices.TypeOfPricePlannedCostOfInventory();
	BatchAccountingIsEnabled = CalculationOfCostCached.BatchAccountingIsEnabled(BegOfMonth(Object.Date));
	AnalyticalAccountingByProductsGroups = GetFunctionalOption("AnalyticalAccountingByProductsGroups");
	
	FillDefaultWarehouse();
	FillInServiceDetailsForProductRange();
	
EndProcedure

&AtServer
Procedure FillDefaultWarehouse()
	
	If UseSeveralWarehouses Then
		DefaultWarehouse = Catalogs.Warehouses.EmptyRef();
	Else
		DefaultWarehouse = TMCommonUse.GetCheckWarehouseByDefault();
	EndIf;
	
EndProcedure

&AtServer
Procedure UpdateIssueForActivities(Fill = True)
	
	FillParameters = Documents.RecyclableWasteAllocation.ParametersForFillingInVATActivityType(Object);
	If Fill Then
		VATAccountingERP.FillInTypeOfActivityVAT(
			Object.ProductionIssueForActivity,
			FillParameters,
			VATAccountingCachedParameterValues);
	EndIf;
	
	VATAccountingERP.FillInActivitySelectionList(
		Items.ProductionIssueForActivity,
		Object.ProductionIssueForActivity,
		FillParameters,
		VATAccountingCachedParameterValues);
	
EndProcedure

#EndRegion

#Region SetOfSeries

&AtServer
Function ParametersOfSeriesIndicationForm()
	
	Return ProductsServer.ParametersOfSeriesIndicationForm(Object, SeriesSpecificationParameters, Undefined, ThisForm);
	
EndFunction

&AtServer
Procedure FillInStatusesOfSpecifyingSeriesWhenChangingProductInHeader(CachedValues)

	ProductsServer.FillInStatusesOfSpecifyingSeriesWhenChangingProductInHeader(Object, 
				SeriesSpecificationParameters, CachedValues);
	SetSeriesAvailabilityInHeader();

EndProcedure

&AtServer
Procedure ProcessSeriesIndication_Server(ParametersOfSeriesIndicationForm)
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("UpdateNumberOfProductsWhenRegistering", True);
	AddActionsToStructureWhenQuantityChanges(StructureOfActions);
	
	ProductsServer.ProcessSeriesIndication_(Object, SeriesSpecificationParameters, ParametersOfSeriesIndicationForm, StructureOfActions);
	
EndProcedure

&AtServer
Procedure CustomizeSeriesItems()

	Items.SpecifySeriesInHeader.Visible	= SeriesSpecificationParameters.UseItemsBatch;
	Items.BatchesIndicationStatus.Visible	= SeriesSpecificationParameters.UseItemsBatch;
	Items.Series.Visible				= SeriesSpecificationParameters.UseItemsBatch;

	SetSeriesAvailabilityInHeader();
	
EndProcedure

&AtServer
Procedure SetSeriesAvailabilityInHeader()
	
	If Object.BatchesIndicationStatus = 14
		Or Object.BatchesIndicationStatus = 13 Then
		Items.Series.Enabled = True;
		Items.Series.AutoMarkIncomplete = True;
	Else
		Items.Series.Enabled = False;
		Items.Series.AutoMarkIncomplete = False;
	EndIf;
	
	Items.SpecifySeriesInHeader.Enabled = Object.BatchesIndicationStatus <> 0;
	
EndProcedure

&AtClient
Procedure OpenSelectionOfSeries(Text = "", CurrentData = Undefined)
	
	If ProductsClient.YouNeedServerCallToSpecifySeries(ThisForm, SeriesSpecificationParameters, Text)Then
		
		ParametersOfSeriesIndicationForm = ParametersOfSeriesIndicationForm();
		
		AdditionalParameters = New Structure("ParametersOfSeriesIndicationForm", ParametersOfSeriesIndicationForm);
		CallbackDescription = New CallbackDescription("OpenSelectionOfSeriesCompletion", ThisObject, AdditionalParameters);
		
		OpenForm(ParametersOfSeriesIndicationForm.FormName, ParametersOfSeriesIndicationForm, ThisForm,,,,CallbackDescription, FormWindowOpeningMode.LockOwnerWindow);
		
	EndIf;
EndProcedure

&AtClient
Procedure OpenSelectionOfSeriesCompletion(Result, AdditionalParameters) Export
	
	ParametersOfSeriesIndicationForm = AdditionalParameters.ParametersOfSeriesIndicationForm;
	ReturnValue_1 = Result;
	
	If ReturnValue_1 <> Undefined Then
		
		ProcessSeriesIndication_Server(ParametersOfSeriesIndicationForm);
		
		If PriceManagementSystemClient.ItIsNecessaryToRecalculatePriceWhenChanging(Object.Products, "Series", Object.Date) Then
	
			StructureOfActions = New Structure;
			StructureOfActions.Insert("FillInSalePrice", BatchProcessingOfTablePartClientServer.ParametersForFillingInPriceInTSLine(Object));
			StructureOfActions.Insert("RecalculateAmount", "Count");
			
			If Not StructureOfActions.Count() = 0 Then
				BatchProcessingOfTablePartClient.ProcessTSString(Object, StructureOfActions, CachedValues);
			EndIf;
		EndIf;
		
	EndIf;
	
	UpdateCachedHeaderValuesToAccountForSeries();
	
	UpdateTotals();
	
EndProcedure

&AtClient
Procedure UpdateCachedHeaderValuesToAccountForSeries()
	
	ProductsClient.UpdateCachedHeaderValuesToAccountForSeries(Object,
												CachedValues, SeriesSpecificationParameters);
	
EndProcedure

&AtServer
Procedure PrepareFillSetSeriesVisibility()
	
	SeriesSpecificationParameters();
	ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);
	CustomizeSeriesItems();
	
EndProcedure

&AtServer
Procedure SeriesSpecificationParameters()
	
	SeriesSpecificationParameters = New FixedStructure(ProductsServer.SeriesSpecificationParameters(Object, Documents.RecyclableWasteAllocation));
	
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
