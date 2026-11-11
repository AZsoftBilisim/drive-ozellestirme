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
	
	ThisIsCA = GetFunctionalOption("ComplexAutomation");
	If ThisIsCA Then
		Items.ProductionLotsStage.Visible = False;
	EndIf;
	
	If Parameters.Property("LimitInProcessing") Then
		LimitInProcessing = Parameters.LimitInProcessing;
	EndIf;
	
	If Parameters.Property("Accounting_0Balance") Then
		AccountingBalance = Parameters.Accounting_0Balance;
	EndIf;
	
	ForAllocationMax = AccountingBalance - Object.CountReal;
	ForAllocationMin = AccountingBalance - LimitInProcessing - Object.CountReal;
	TargetCostPriceType = Catalogs.TypesOfPrices.TypeOfPricePlannedCostOfInventory();
	BatchAccountingIsEnabled = CalculationOfCostCached.BatchAccountingIsEnabled(BegOfMonth(Object.Date));
	AnalyticalAccountingByProductsGroups = GetFunctionalOption("AnalyticalAccountingByProductsGroups");
	ItemsType = Common.ObjectAttributeValue(Object.Products, "ItemsType");
	
	IncomeAndExpensesServer.OnCreateAtServer(ThisObject, 
		Documents.ProductionCostAllocation.ItemsAndDimensionsSelectionParameters());
		
	GLAccountSettingsServer.OnCreateAtServer(ThisObject, 
		Documents.ProductionCostAllocation.AccountingAccountSettings_());
	
	FillSelectionLists();
	SetTextOfLabelDistributionBase();
	SetTextAndVisibilityOfSelectionOfDistributionBase();
	SetVisibilityOnSelectionByProductGroups();
	SetTextOfSelectionLabelByProductGroups();
	If Not ValueIsFilled(Object.Ref) Then
		OnReadCreateAtServer();
		ProductsServer.FillInStatusesForSpecifyingSeries(Object,SeriesSpecificationParameters);
		SetSeriesAvailabilityInHeader();
	EndIf;
	
	// new production
	
	If Parameters.Property("IncomingBalance") Then
		Parameters.Property("IncomingBalance",  IncomingBalance);
		Parameters.Property("OpeningBalance", OpeningBalance);
		Parameters.Property("Received",        Received);
		Parameters.Property("Passed",         Passed);
	ElsIf ValueIsFilled(Object.Ref) Then 
		InitializeProductMovementData();
	EndIf;
	
	If Not ValueIsFilled(Object.Ref) Then
		Existence = 0;
		Object.Allocate = IncomingBalance - Object.Count;
	Else
		Existence = IncomingBalance - Object.Allocate - Object.Count;
	EndIf;
	
	Items.LabelIncomingBalance.Title = ProductionClientServer.DecryptingIncomingBalance(ThisForm);
	
	// end new production

	If ClientApplication.CurrentInterfaceVariant() = ClientApplicationInterfaceVariant.Version8_2 Then
		Items.Totals1Group.BackColor = New Color();
	EndIf;
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject);
	// End IntegrationWith1CDocumentManagementSubsystem
	
	// StandardSubsystems.Properties
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("ItemForPlacementName", "GroupAdditionalAttributes");
	PropertyManager.OnCreateAtServer(ThisObject, AdditionalParameters);
	// End StandardSubsystems.Properties
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	
	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)
	
	PeriodClosingDates.ObjectOnReadAtServer(ThisForm, CurrentObject);
	OnReadCreateAtServer();
	FormEvents.OnReadAtServer(ThisObject, CurrentObject);
	
	// StandardSubsystems.Properties
	PropertyManager.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.Properties
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

&AtClient
Procedure ChoiceProcessing(ValueSelected, ChoiceSource)
	
	If ChoiceSource.FormName = "DataProcessor.SelectBatchToDocuments.Form.PickForm" Then
		
		ProductsClient.ProcessSeriesIndication(ThisForm, SeriesSpecificationParameters, ValueSelected);
		ProductsClient.UpdateCachedHeaderValuesToAccountForSeries(Object,CachedValues,SeriesSpecificationParameters);	
		
	ElsIf ProductsClient.ThisIsIndicationOfSeries(ChoiceSource) Then
		
		ProductsClient.ProcessSeriesIndication(ThisForm, SeriesSpecificationParameters, ValueSelected);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	FormEventsClient.NotificationProcessing(ThisObject, EventName, Parameter, Source);
	
	// StandardSubsystems.Properties 
	If PropertyManagerClient.ProcessNotifications(ThisObject, EventName, Parameter) Then
		UpdateAdditionalAttributesItems();
		PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
	EndIf;
	// End StandardSubsystems.Properties
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)
	
	FillInServiceDetailsOfForm();
	
	IncomeAndExpensesServer.AfterWriteAtServer(ThisObject);
	GLAccountSettingsServer.AfterWriteAtServer(ThisObject);
	
	ProvisionInDocumentsServer.CheckToRunBackgroundInventoryAllocationJob();
	
	ConfigurationModificationOverridable.AfterWriteAtServer(ThisForm, CurrentObject, WriteParameters);
	
	FormEvents.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	If WriteParameters.WriteMode = DocumentWriteMode.Posting Then
		CheckDuplicateDocumentOfCurPeriod(Cancel, CurrentObject);
	EndIf;
	
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
	
	// StandardSubsystems.Properties
	PropertyManager.BeforeWriteAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.Properties
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.BeforeWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	// End IntegrationWith1CDocumentManagementSubsystem
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	UpdateTotals(False);
	UpdateCaptionPeriod();
	SetVisibilityOfDistributionRuleSettings();
	ProductsClient.UpdateCachedHeaderValuesToAccountForSeries(Object,CachedValues,SeriesSpecificationParameters);
	
	// StandardSubsystems.Properties
	PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
	// End StandardSubsystems.Properties
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands
EndProcedure

&AtClient
Procedure BeforeWrite(Cancel, WriteParameters)
	
	If WriteParameters.WriteMode = DocumentWriteMode.Posting And Object.Allocate <> 0 Then
		QueryText = 
			NStr("vi = 'Sự hiện diện được khai báo %1 không trùng với giá trị tính toán %2.
			|Chỉnh sửa?';
			|ru = 'Заявленное наличие %1 не совпадает с расчетным значением %2.
			|Исправить?';
			|en = 'Declared %1 availability does not match the %2 target value.
			|Correct?'; fa = 'Declared %1 availability does not match the %2 target value.
			|Correct?';
			|it = 'Заявленное наличие %1 не совпадает с расчетным значением %2.
			|Исправить?';
			|pl = 'Declared %1 availability does not match the %2 target value.
			|Correct?';
			|tr = 'Beyan edilen %1 mevcudiyeti hesaplanan %2 değeriyle eşleşmemektedir.
			|Düzeltilsin mi?'");
		CallbackDescription = New CallbackDescription("QuestionOfCalculatingAvailability", ThisObject);
		ShowQueryBox(CallbackDescription, StrTemplate(QueryText, Existence, IncomingBalance - Object.Count), QuestionDialogMode.YesNoCancel, , DialogReturnCode.Yes);
		Cancel = True;
		Return;
	EndIf;
	
	FormEventsClient.BeforeWrite(ThisObject, Cancel, WriteParameters);
	If WriteParameters.WriteMode = DocumentWriteMode.Write Then
		If FormOwner <> Undefined And FormOwner.Name = "Costs" Then
			WriteParameters.WriteMode = DocumentWriteMode.Posting
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	
	TransferParameters = New Structure;
	TransferParameters.Insert("Ref", Object.Ref);
	TransferParameters.Insert("Document", Object.Ref);
	
	If WriteParameters.WriteMode = DocumentWriteMode.Posting Then
		
		TransferParameters.Insert("RealBalance", Object.CountReal);
		TransferParameters.Insert("AllocatedToProduction",
										Object.ProductionIssueWithoutReferences.Total("Count")
										+ Object.ProductionScheduleStages.Total("Count")
										+ Object.QuantityToAllocateAccordingToRule);
		TransferParameters.Insert("WrittenOffAsExpenses",            Object.OtherExpenses.Total("Count"));
		
		TransferParameters.Insert("Existence", Existence);
		TransferParameters.Insert("Allocate", Object.Allocate);
		TransferParameters.Insert("Allocated", Object.Count);
		
	Else
		TransferParameters.Insert("RealBalance",                      0);
		TransferParameters.Insert("AllocatedToProduction",       0);
		TransferParameters.Insert("WrittenOffAsExpenses",                 0);
		
		TransferParameters.Insert("Existence", IncomingBalance);
		If ItemsType = PredefinedValue("Enum.ItemsTypes.Work_5") Then
			TransferParameters.Insert("Allocate", IncomingBalance);
		Else
			TransferParameters.Insert("Allocate", 0);
		EndIf;
		
		TransferParameters.Insert("Allocated", 0);
		
	EndIf;
	
	Notify("Write_ProductionCostAllocation", TransferParameters);
	
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
	
	CheckFillingOfTabularPartOfIssueWithoutOrdering(Cancel);
	
	
	DataKey = TMCommonUse.DataKeyForMessageToUser(ThisObject);
	
	If Not Object.NewProduction And Not Cancel And Object.QuantityToAllocateAccordingToRule = 0 And Object.ProductionScheduleStages.Count() = 0
		And Object.ProductionIssueWithoutReferences.Count() = 0 And Object.OtherExpenses.Count() = 0
		And Object.CountReal = 0 Then
		
		MessageText = NStr("vi = 'Chưa cài đặt phân bổ chi phí nguyên vật liệu và nhân công.';
							|ru = 'Не настроено распределение материалов и работ.';
							|en = 'Material and labor allocation is not set.'; fa = 'Material and labor allocation is not set.';
							|it = 'La distribuzione di materiali e lavori non è impostata.';
							|pl = 'Nie ustawiono przydziału materiałów i prac';
							|tr = 'Malzeme ve işçilik tahsisatı ayarlanmadı.'");
		CommonClientServer.MessageToUser(MessageText, DataKey,,"Object", Cancel);
		
	EndIf;
	
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
	
	// StandardSubsystems.Properties
	PropertyManager.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes);
	// End StandardSubsystems.Properties
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure DateOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	
	UpdateCaptionPeriod();
	
EndProcedure

&AtClient
Procedure CountRealOnChange(Item)
	
	UpdateTotals();
	
EndProcedure

&AtClient
Procedure BatchesIndicationStatusClick(Item, StandardProcessing)

	ParametersOfSeriesIndicationForm = ParametersOfSeriesIndicationForm();
	OpenForm(ParametersOfSeriesIndicationForm.FormName,ParametersOfSeriesIndicationForm,ThisForm,,,,
		New CallbackDescription("BatchesIndicationStatusClickCompletion",
			ThisObject,
			New Structure("ParametersOfSeriesIndicationForm",
				ParametersOfSeriesIndicationForm)),
		FormWindowOpeningMode.LockWholeInterface);

EndProcedure

&AtClient
Procedure BatchesIndicationStatusClickCompletion(Result, AdditionalParameters) Export
	
	ParametersOfSeriesIndicationForm = AdditionalParameters.ParametersOfSeriesIndicationForm;
	
	
	ReturnValue_1 = Result;
	
	If ReturnValue_1 <> Undefined Then
		ProcessSeriesIndication_Server(ParametersOfSeriesIndicationForm);
	EndIf;

EndProcedure

&AtClient
Procedure ExistenceOnChange(Item)
	
	If Existence > IncomingBalance Then
		Existence = IncomingBalance;
	EndIf;
	
	Object.Allocate = IncomingBalance - Object.Count - Existence;
	
EndProcedure

#EndRegion

#Region EventHandlersForFormBookmarkElementsByRule

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
Procedure LabelAllocationBaseFilterClick(Item)
	
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

&AtClient
Procedure LabelFilterByProductGroupsClick(Item)
	
	FilterParameters = New Structure();
	FilterParameters.Insert("ArrayOfProductGroups", FilterByProductsGroups.UnloadValues());

	OpenForm("Catalog.CostAllocationRules.Form.FilterForm",
			FilterParameters,
			ThisForm,,,, 
			New CallbackDescription("LabelSelectionClickFinish", ThisObject, "FilterByProductsGroups"), 
			FormWindowOpeningMode.LockOwnerWindow);
			
EndProcedure

&AtClient
Procedure QuantityToAllocateAccordingToRuleOnChange(Item)
	If Object.NewProduction Then
		If Object.QuantityToAllocateAccordingToRule < 0 Then
			Object.QuantityToAllocateAccordingToRule = 0;
		EndIf;
		UpdateDocumentResults();
	Else
		UpdateTotals();
	EndIf;
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersProductionScheduleStages

&AtClient
Procedure StagesBeforeAddRow(Item, Cancel, Copy, Parent, Var_Group)
	Cancel = True;
	OpenSelectionByStagesForm();
	Return; // In KA, the handler is empty
	
EndProcedure

&AtClient
Procedure StagesWhenChanging(Item)
	UpdateTotals();
	Return; // In KA, the handler is empty
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersProductionLots

&AtClient
Procedure ProductionLotsOnChange(Item)
	If Object.NewProduction Then
		UpdateDocumentResults();
	Else
		UpdateTotals();
	EndIf;
EndProcedure

&AtClient
Procedure ProductionLotsBeforeAddRow(Item, Cancel, Copy, Parent, Var_Group, Parameter)
	
	Cancel = True;
	OpenSelectionByStagesForm();
	
EndProcedure

#EndRegion

#Region EventHandlersForTableElementsOfFormOutputWithoutOrder

&AtClient
Procedure ProductionIssueWithoutReferencesOnChange(Item)
	
	MaterialQuantityInclReleasesWithoutReferences = ProductionIssueWithoutReferences.Total("Count");
	Modified = True;
	UpdateTotals();
	
EndProcedure

&AtClient
Procedure ProductionIssueWithoutReferencesBeforeAddRow(Item, Cancel, Copy, Parent, Var_Group, Parameter)
	
	Cancel = True;
	
EndProcedure

&AtClient
Procedure ProductionIssueWithoutReferencesChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	ProcessingSelectionOfOutputProducts(ValueSelected);
	
EndProcedure

&AtClient
Procedure ProductionIssueWithoutReferencesSelection(Item, RowSelected, Field, StandardProcessing)
	
	CurrentData = Items.ProductionIssueWithoutReferences.CurrentData;
	
	If Field.Name = "ProductionIssueWithoutReferencesDocumentOfProductionIssue" Then
		StandardProcessing = False;
		ShowValue(, CurrentData.DocumentOfProductionIssue);
	EndIf;
	
EndProcedure

&AtClient
Procedure ProductionIssueWithoutReferencesBeforeDeleteRow(Item, Cancel)
	
	CurrentData = Items.ProductionIssueWithoutReferences.CurrentData;
	
	If Not ExpandReleasesWithoutReferences Then
		FilterStructure1 = New Structure("Products, Characteristic, Series, BillOfMaterials, ProductCostElement");
	Else
		FilterStructure1 = New Structure("DocumentOfProductionIssue, RowCode");
	EndIf;
	
	FillPropertyValues(FilterStructure1, CurrentData);
	FoundRows = Object.ProductionIssueWithoutReferences.FindRows(FilterStructure1);
	
	For Each String In FoundRows Do
		Object.ProductionIssueWithoutReferences.Delete(String);
	EndDo;
	
EndProcedure

&AtClient
Procedure ProductionIssueWithoutReferencesOnStartEdit(Item, NewRow, Copy)
	SaveRowData(Items.ProductionIssueWithoutReferences.CurrentData);
EndProcedure

&AtClient
Procedure ProductionIssueWithoutReferencesOnEditEnd(Item, NewRow, CancelEdit)
	
	If Not CancelEdit Then
	UpdateTotals();
	EndIf;

EndProcedure

&AtClient
Procedure ProductionIssueWithoutReferencesAfterDeleteRow(Item)
	
	UpdateTotals();
	
EndProcedure

&AtClient
Procedure ProductionIssueWithoutReferencesProductCostElementOnChange(Item)
	
	CurrentData = Items.ProductionIssueWithoutReferences.CurrentData;
	
	If ExpandReleasesWithoutReferences Then
		UpdateObjectTable("ProductionIssueWithoutReferences", CurrentData.GetID());
	Else
		SetCalculationArticleByLine(CurrentData.GetID());
	EndIf;
	
EndProcedure

&AtClient
Procedure ProductionIssueWithoutReferencesCountOnChange(Item)
	
	CurrentData = Items.ProductionIssueWithoutReferences.CurrentData;
	
	If ExpandReleasesWithoutReferences Then
		UpdateObjectTable("ProductionIssueWithoutReferences", CurrentData.GetID());
	Else
		DistributeAmountOfMaterials(CurrentData.GetID());
	EndIf;
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersOtherExpenses

&AtClient
Procedure OtherExpensesSelection(Item, RowSelected, Field, StandardProcessing)
	
	GLAccountSettingsClient.OnClick(ThisObject, Field, StandardProcessing);
	
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
Procedure OtherExpensesExpenseItemStartChoice(Item, ChoiceData, StandardProcessing)
	
	IncomeAndExpensesClient.StartArticleSelection(ThisObject, Item, StandardProcessing);	
	
EndProcedure

&AtClient
Procedure OtherExpensesOnChange(Item)
	If Object.NewProduction Then
		UpdateDocumentResults();
	Else
		UpdateTotals();
	EndIf;
EndProcedure

&AtClient
Procedure OtherExpensesExpenseItemOnChange(Item)
	
	IncomeAndExpensesClientServer.AssetRefOnChange(ThisObject, Item);
	
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

#Region EventHandlers

&AtClient
Procedure FillInCostingItems(Command)
	
	If Items.Pages.CurrentPage = Items.PageIssuesWithoutOrders Then
		FillInCalculationArticlesInTabularPart(ProductionIssueWithoutReferences, 
																Items.ProductionIssueWithoutReferences.SelectedRows);
	ElsIf Items.Pages.CurrentPage = Items.ProductionBatchPage Then
		FillInCalculationArticlesInTabularPart(Object.ProductionLots, 
																Items.ProductionLots.SelectedRows);
	ElsIf Items.Pages.CurrentPage = Items.PageStages Then
		FillInCalculationArticlesInTabularPart(Object.ProductionScheduleStages, 
																Items.ProductionScheduleStages.SelectedRows);
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

&AtClient
Procedure SpecifySeriesInHeader(Command)

	OpenSelectionOfSeries();

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
Procedure SetDeletionMarkForADocument(Command)
	
	TMCommonUseClient.SetDeletionMarkForADocument(ThisObject);
	
EndProcedure

&AtClient
Procedure ExpandByReleaseDocuments(Command)
	
	ExpandReleasesWithoutReferences = Not ExpandReleasesWithoutReferences;
	Items.IssuesWithoutAnOrderExpandByIssueDocumentsButton.Check = ExpandReleasesWithoutReferences;
	CollapseExpandTS(ExpandReleasesWithoutReferences);
	
EndProcedure

&AtClient
Procedure MoveSettingsToARule(Command)
	
	MoveSettingsToARuleServer();
	
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

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()

	ConditionalAppearance.Items.Clear();
		
	//
	
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.State.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("AccountingBalance");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Less;
	ItemFilter.RightValue = 0;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.SpecialTextColor);

	//

	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ProductionIssueWithoutReferencesDocumentOfProductionIssue.Name);
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ProductionIssueWithoutReferencesRowCode.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ExpandReleasesWithoutReferences");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;

	Item.Appearance.SetParameterValue("Visible", False);
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ProductionIssueWithoutReferencesSubmissionOfIssueDocuments.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ExpandReleasesWithoutReferences");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	Item.Appearance.SetParameterValue("Visible", False);
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ProductionIssueWithoutReferencesSubmissionOfIssueDocuments.Name);
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.NoteText);

	//
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ProductionIssueWithoutReferencesDocumentOfProductionIssue.Name);
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ProductionIssueWithoutReferencesRowCode.Name);

	Item.Appearance.SetParameterValue("TextColor", StyleColors.HyperlinkColor);
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ProductionIssueWithoutReferencesBillOfMaterials.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ProductionIssueWithoutReferences.BillOfMaterials");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	Item.Appearance.SetParameterValue("TextColor", StyleColors.InaccessibleCellTextColor);
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<không có bảng kê chi tiết các nguồn lực sản xuất>';
													|ru = '<без спецификации>';
													|en = '<without bill of materials>'; fa = '<without bill of materials>';
													|it = '<senza specifica>';
													|pl = '<bez specyfikacji>';
													|tr = '<ürün reçetesiz>'"));
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.AllocatedAccordingToRule.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.QuantityToAllocateAccordingToRule");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = 0;

	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ProductCostElement.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.QuantityToAllocateAccordingToRule");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = 0;

	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	
	// the distribution is highlighted in red
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.Allocate.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Allocate");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotEqual;
	ItemFilter.RightValue = 0;

	Item.Appearance.SetParameterValue("TextColor", StyleColors.NegativeTextColor);

	// negative presence is highlighted in red
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.Existence.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Existence");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Less;
	ItemFilter.RightValue = 0;

	Item.Appearance.SetParameterValue("TextColor", StyleColors.NegativeTextColor);
	
	SetConditionalRegistrationOfRecipientDivision();
	
EndProcedure

&AtClient
Procedure Attachable_ProcessingTheFormSNavigationLink(Item, FormattedStringURL, StandardProcessing)
	
	StandardProcessing = False;
	
	ProductionCostAllocationClientLocalization.ProcessingTheFormSNavigationLink(
		Item,
		FormattedStringURL,
		StandardProcessing,
		ThisForm);
		
EndProcedure

#Region OnChangeAttributes

&AtClient
Procedure UpdateTotals(UpdateQuantityDistributed = True)
	
	ForAllocationMax = AccountingBalance - Object.CountReal;
	ForAllocationMin = AccountingBalance - LimitInProcessing - Object.CountReal;
	
	If LimitInProcessing = 0 Then
		State = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Số dư kế toán %1 %2. Không có giới hạn xử lý đã được thiết lập. Để phân bổ %3 %4.';
					|ru = 'Учетный остаток %1 %2. Лимит в обработке не установлен. К распределению %3 %4.';
					|en = 'Accounting balance %1 %2. Limit in processing is not set. For allocation from %3 %4.'; fa = 'Accounting balance %1 %2. Limit in processing is not set. For allocation from %3 %4.';
					|it = 'Giacenza contabilizzata %1 %2. Limite di elaborazione non impostato. Da distribuire %3 %4.';
					|pl = 'Pozostałości ewidencyjne %1 %2. Limit przetwarzania nie ustalony. Do  przydziału %3 %4.';
					|tr = 'Hesap bakiyesi %1 %2. İşleme limiti yapılandırılmadı. Dağıtılacak %3 %4.'"),
				AccountingBalance,
				UnitOfMeasure,
				ForAllocationMax,
				UnitOfMeasure);
	Else
		State = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Số dư kế toán %1 %2. Giới hạn xử lý %3 %4. Để phân bổ từ %5 đến %6 %7.';
					|ru = 'Учетный остаток %1 %2. Лимит в обработке %3 %4. К распределению от %5 до %6 %7.';
					|en = 'Accounting balance %1 %2. Limit in processing %3 %4. For allocation from %5 to %6 %7.'; fa = 'Accounting balance %1 %2. Limit in processing %3 %4. For allocation from %5 to %6 %7.';
					|it = 'Giacenza contabilizzata %1 %2. Limite di elaborazione %3 %4. Da distribuire da %5 a %6 %7.';
					|pl = 'Pozostałości ewidencyjne %1 %2. Limit przetwarzania %3 %4. Do  przydziału od %5 do %6 %7.';
					|tr = 'Hesap bakiyesi %1 %2. İşleme limiti %3 %4. Dağıtılacak %5 üzerinden %6 %7 boyunca.'"),
				AccountingBalance,
				UnitOfMeasure,
				LimitInProcessing,
				UnitOfMeasure,
				ForAllocationMin,
				ForAllocationMax,
				UnitOfMeasure);
	EndIf;
	TotalDividedIntoStages = Object.ProductionScheduleStages.Total("Count");
	TotalDistributedToIssuesWithoutOrders = ProductionIssueWithoutReferences.Total("Count");
	TotalDeductedForExpenses = Object.OtherExpenses.Total("Count");
	
	If UpdateQuantityDistributed Then
		
		Count = Object.QuantityToAllocateAccordingToRule
						+ TotalDividedIntoStages
						+ TotalDistributedToIssuesWithoutOrders 
						+ TotalDeductedForExpenses;
						
		Object.Count = ?(Count < 0, -Count, Count);
		
		If ProductsClient.YouNeedToUpdateStatusOfSeriesInHeader(Object,CachedValues,SeriesSpecificationParameters) Then
			FillInStatusesOfSpecifyingSeriesWhenChangingProductInHeader(CachedValues);
			ProductsClient.UpdateCachedHeaderValuesToAccountForSeries(Object,CachedValues,SeriesSpecificationParameters);
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure UpdateDocumentResults()
	
	Object.Count = Object.ProductionLots.Total("Count") + Object.OtherExpenses.Total("Count") + Object.QuantityToAllocateAccordingToRule;
	Object.Allocate = IncomingBalance - Object.Count - Existence;
	
	If ProductsClient.YouNeedToUpdateStatusOfSeriesInHeader(Object,CachedValues,SeriesSpecificationParameters) Then
		FillInStatusesOfSpecifyingSeriesWhenChangingProductInHeader(CachedValues);
		ProductsClient.UpdateCachedHeaderValuesToAccountForSeries(Object,CachedValues,SeriesSpecificationParameters);
	EndIf;
	
EndProcedure

&AtClient
Procedure UpdateCaptionPeriod()

	LabelPeriod = PeriodPresentation(BegOfMonth(Object.Date), EndOfMonth(Object.Date), "DLF=D");
	
EndProcedure

#EndRegion

#Region AutoFill

&AtServer
Procedure FillInSelection(AddressInStorage, TSName)
	
	CalculationResult1	= GetFromTempStorage(AddressInStorage);
	Modified	= True;
	ObjectTable = Object[TSName]; // FormDataCollection
	
	For Each SelectedString_ In CalculationResult1 Do
		
		LineOfATabularSection = ObjectTable.Add();
		FillPropertyValues(LineOfATabularSection, SelectedString_);
		
		If ValueIsFilled(Object.ProductCostElement) Then
			LineOfATabularSection.ProductCostElement = Object.ProductCostElement;
		EndIf;
		
	EndDo;
	
EndProcedure

&AtServer
Procedure FillInDefaultCostingArticle()
	
	If Not ValueIsFilled(Object.Products) Then
		ProductCostElement = Catalogs.ProductCostElements.EmptyRef();
		Return
	EndIf;
	Query = New Query;
	Query.Text =
	"SELECT TOP 1
	|	Stages.ProductCostElement AS ProductCostElement,
	|	Stages.Ref.Date AS Date
	|FROM
	|	Document.ProductionCostAllocation.ProductionScheduleStages AS Stages
	|WHERE
	|	Stages.Ref.Products = &Products
	|	AND Stages.Ref.Posted
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

&AtClient
Procedure FillInCalculationArticlesInTabularPart(TabPart, SelectedRows)
	
	ProductCostElement = Undefined;
	
	FormOpenParameters = New Structure();
	ArrayOfCostTypeNames = New Array();
	ArrayOfCostTypeNames.Add("Payroll");
	ArrayOfCostTypeNames.Add("Depreciation");
	ArrayOfCostTypeNames.Add("Material_");
	ArrayOfCostTypeNames.Add("Other");
	FormOpenParameters.Insert("ArrayOfCostTypeNames", ArrayOfCostTypeNames);

	OpenForm("Catalog.ProductCostElements.ChoiceForm",
		FormOpenParameters,
		ThisObject,
		, , ,
		New CallbackDescription("FillInCalculationArticlesInTabularPartCompletion",
			ThisObject,
			New Structure("SelectedRows, TabPart", SelectedRows, TabPart)),
		FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure FillInCalculationArticlesInTabularPartCompletion(Result, AdditionalParameters) Export

	SelectedRows = AdditionalParameters.SelectedRows;
	TabPart = AdditionalParameters.TabPart;
	ProductCostElement = Result;

	If Not ValueIsFilled(ProductCostElement) Then
		Return;
	EndIf;
	For Each String In SelectedRows Do
		TableRow = TabPart.FindByID(String);
		If TableRow <> Undefined Then
			SaveRowData(TableRow);
			TableRow.ProductCostElement = ProductCostElement;
			If TabPart = ProductionIssueWithoutReferences Then
				SetCalculationArticleByLine(TableRow.GetID());
			EndIf;
		EndIf;
	EndDo;

EndProcedure

#EndRegion

#Region SetOfSeries

&AtClient
Procedure OpenSelectionOfSeries()
	
	CurParametersForSpecifyingSeries = SeriesSpecificationParameters;
	
	If ProductsClient.YouNeedServerCallToSpecifySeries(ThisForm,CurParametersForSpecifyingSeries,"")Then
		
		ParametersOfSeriesIndicationForm = ParametersOfSeriesIndicationForm();
		OpenForm(ParametersOfSeriesIndicationForm.FormName,ParametersOfSeriesIndicationForm,ThisForm,,,,
			New CallbackDescription("OpenSelectionOfSeriesCompletion",
				ThisObject,
				New Structure("ParametersOfSeriesIndicationForm",
					ParametersOfSeriesIndicationForm)),
			FormWindowOpeningMode.LockWholeInterface);
			
	EndIf;
	
EndProcedure

&AtClient
Procedure OpenSelectionOfSeriesCompletion(Result, AdditionalParameters) Export
	
	ParametersOfSeriesIndicationForm = AdditionalParameters.ParametersOfSeriesIndicationForm;
	ReturnValue_1 = Result;
	If ReturnValue_1 <> Undefined Then
		ProcessSeriesIndication_Server(ParametersOfSeriesIndicationForm);
	EndIf;
	ProductsClient.UpdateCachedHeaderValuesToAccountForSeries(Object,CachedValues,SeriesSpecificationParameters);

EndProcedure

&AtServer
Procedure ProcessSeriesIndication_Server(ParametersOfSeriesIndicationForm)
	
	StructureOfActions = New Structure;
	ProductsServer.ProcessSeriesIndication_(Object,SeriesSpecificationParameters,ParametersOfSeriesIndicationForm,StructureOfActions);
	
EndProcedure

&AtServer
Function ParametersOfSeriesIndicationForm()
	
	Return ProductsServer.ParametersOfSeriesIndicationForm(Object, SeriesSpecificationParameters, 0, ThisForm);
	
EndFunction

&AtServer
Procedure CustomizeSeriesItems()

	Items.SpecifySeriesInHeader.Visible = SeriesSpecificationParameters.UseItemsBatch;
	Items.BatchesIndicationStatus.Visible = SeriesSpecificationParameters.UseItemsBatch;
 	Items.Series.Visible = SeriesSpecificationParameters.UseItemsBatch;

	SetSeriesAvailabilityInHeader();
	
EndProcedure

&AtServer
Procedure SetSeriesAvailabilityInHeader()
	
	Items.SpecifySeriesInHeader.Enabled = Object.BatchesIndicationStatus <> 0 And Object.BatchesIndicationStatus <> 14; 
	
EndProcedure

&AtServer
Procedure FillInStatusesOfSpecifyingSeriesWhenChangingProductInHeader(CachedValues)

	ProductsServer.FillInStatusesOfSpecifyingSeriesWhenChangingProductInHeader(Object, 
				SeriesSpecificationParameters, CachedValues);
	SetSeriesAvailabilityInHeader();

EndProcedure

#EndRegion

#Region Other

&AtServer
Procedure OnReadCreateAtServer()

	SeriesSpecificationParameters = New FixedStructure(ProductsServer.SeriesSpecificationParameters(Object, Documents.ProductionCostAllocation));
	
	CustomizeSeriesItems();
	IncomeAndExpensesServer.OnReadAtServer(ThisObject, 
		Documents.ProductionCostAllocation.ItemsAndDimensionsSelectionParameters());
		
	GLAccountSettingsServer.OnReadAtServer(ThisObject, 
		Documents.ProductionCostAllocation.AccountingAccountSettings_());		
	
	FillInDefaultCostingArticle();
	Items.GroupSelectionByProductType.Visible = GetFunctionalOption("AnalyticalAccountingByProductsGroups");
	UnitOfMeasure = Common.ObjectAttributeValue(Object.Products, "UnitOfMeasure");
	Items.DecorationWarningByStandards.Title = NStr("vi = 'Số tiền tiêu chuẩn được tính theo lựa chọn công thức / tự động không được tính đến.';
													|ru = 'Не учитывается нормативное количество, рассчитываемое по формуле/автовыбором.';
													|en = 'Standard amount calculated by the formula / auto selection is not recorded.'; fa = 'Standard amount calculated by the formula / auto selection is not recorded.';
													|it = 'Non viene contabilizzata la quantità calcolata con la formula/in selezione automatica.';
													|pl = 'Nie uwzględnia się normatywną ilość, obliczane według wzoru/automatycznym wyborem.';
													|tr = 'Formüle/otomatik seçime göre hesaplanan standart miktar dikkate alınmamaktadır.'");
	
	If ValueIsFilled(UnitOfMeasure) Then
		Items.StagesCount.Title = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("vi = 'Số lượng (%1)';
						|ru = 'Количество (%1)';
						|en = 'Quantity (%1)'; fa = 'Quantity (%1)';
						|it = 'Quantità (%1)';
						|pl = 'Ilość (%1)';
						|tr = 'Miktar (%1)'"),
					UnitOfMeasure);
		Items.ProductionLotsCount.Title = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("vi = 'Số lượng (%1)';
						|ru = 'Количество (%1)';
						|en = 'Quantity (%1)'; fa = 'Quantity (%1)';
						|it = 'Quantità (%1)';
						|pl = 'Ilość (%1)';
						|tr = 'Miktar (%1)'"),
					UnitOfMeasure);
		Items.ProductionIssueWithoutReferencesCount.Title = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("vi = 'Số lượng (%1)';
						|ru = 'Количество (%1)';
						|en = 'Quantity (%1)'; fa = 'Quantity (%1)';
						|it = 'Quantità (%1)';
						|pl = 'Ilość (%1)';
						|tr = 'Miktar (%1)'"),
					UnitOfMeasure);
		Items.OtherExpensesCount.Title = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("vi = 'Số lượng (%1)';
						|ru = 'Количество (%1)';
						|en = 'Quantity (%1)'; fa = 'Quantity (%1)';
						|it = 'Quantità (%1)';
						|pl = 'Ilość (%1)';
						|tr = 'Miktar (%1)'"),
					UnitOfMeasure);
	EndIf;
	
	ItemVariantsAreUsed = Catalogs.Products.ItemVariantsAreUsed(Object.Products);
	Items.Characteristic.Enabled = ItemVariantsAreUsed Or ValueIsFilled(Object.Characteristic);
	If ValueIsFilled(Object.Purpose) Then
	
		AssignmentType = Common.ObjectAttributeValue(Object.Purpose, "AssignmentType");
	
		Items.OtherExpensesPage.Visible =
			Not (AssignmentType = Enums.AssignmentTypes.Giveaway2_5
				Or AssignmentType = Enums.AssignmentTypes.ProvidedMaterialsForStage22
				)
				// Work can be allocated to expenses regardless of the purpose.
				Or ItemsType = PredefinedValue("Enum.ItemsTypes.Work_5");
		
	EndIf;
	MaterialQuantityInclReleasesWithoutReferences = ProductionIssueWithoutReferences.Total("Count");
	FillInServiceDetailsForProductRange("ProductionIssueWithoutReferences");
	CollapseExpandTS(ExpandReleasesWithoutReferences);
	
	CostsServer.ConfigureParametersForSelectingDistributionRules(
		Object.Department,
		Undefined,
		Items.AllocatedAccordingToRule,
		Enums.AssignmentOfCostAllocationRules.MaterialsAndWorksCostAllocation);
	
	Items.MoveSettingsToARule.Enabled = AccessRight("Update", Metadata.Catalogs.CostAllocationRules);

	HasEditPermission = AccessRight("Update", Metadata.Documents.ProductionCostAllocation);
	Items.Existence.ReadOnly = Not HasEditPermission;
	Items.UseProductGroupSelection.ReadOnly = Not HasEditPermission;
	
	FillInServiceDetailsOfForm();
	
	SetItemsVisibility();
	
EndProcedure

&AtServer
Procedure FillInServiceDetailsOfForm()
	
	If Object.NewProduction Then
		CostsServer.FillInCharacteristicsOfProductsByBatchOfProduction(Object.ProductionLots);
	EndIf;
	
EndProcedure

&AtServer
Procedure SetItemsVisibility()
	
	Var ArrayOfAllProps;
	Var ArrayOfOperationDetails;
	
	DocumentProperties = New Structure;
	DocumentProperties.Insert("NewProduction", Object.NewProduction);
	DocumentProperties.Insert("ItemsType", ItemsType);
	
	Documents.ProductionCostAllocation.FillInNamesOfDetailsByDocumentProperties(
		DocumentProperties,
		ArrayOfAllProps, 
		ArrayOfOperationDetails);
	
	CashServer.SetVisibilityOfElementsByArray(
		Items,
		ArrayOfAllProps,
		ArrayOfOperationDetails);
	
EndProcedure


&AtClient
Procedure OpenSelectionByStagesForm()
	
	If Object.NewProduction Then
		
		FilterStructure1 = New Structure();
		FilterStructure1.Insert("Department",		Object.Department);
		FilterStructure1.Insert("Organization",			Object.Organization);
		FilterStructure1.Insert("LineOfBusiness",	
			GeneralPurposeTMServerCall.ObjectAttributeValue(Object.Purpose, "LineOfBusiness"));
		FilterStructure1.Insert("Document",			Object.Ref);
		
		FormParameters = New Structure();
		FormParameters.Insert("BeginOfPeriod",		BegOfMonth(Object.Date));
		FormParameters.Insert("PeriodEnding",		EndOfMonth(Object.Date));
		FormParameters.Insert("FilterStructure1",		FilterStructure1);
		
		Notification = New CallbackDescription("OpenBatchSelectionFormCompletion", ThisForm);
		
		OpenForm("CommonForm.SelectProductionLots",
			FormParameters,
			ThisForm,,,,
			Notification,
			FormWindowOpeningMode.LockOwnerWindow);
		

	EndIf;
	
EndProcedure

&AtClient
Procedure OpenBatchSelectionFormCompletion(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	FillInSelection(Result, "ProductionLots");
	
EndProcedure

&AtServer
Procedure CheckDuplicateDocumentOfCurPeriod (Cancel, CurrentDocument)
	
	Query = New Query("
	|SELECT
	|	DD.Ref AS Ref
	|FROM
	|	Document.ProductionCostAllocation AS DD
	|WHERE
	|	DD.Posted
	|	AND DD.Organization = &Organization
	|	AND DD.Department = &Department
	|	AND DD.Products = &Products
	|	AND DD.Characteristic = &Characteristic
	|	AND DD.Warehouse = &Warehouse
	|	AND DD.Date BETWEEN &PeriodBeginning AND &PeriodEnd
	|	AND NOT DD.Ref = &CurrentDocument
	|	AND DD.Series = &Series
	|	AND DD.Purpose = &Purpose
	|	AND DD.NewProduction = &NewProduction");
	
	Query.SetParameter("Organization",	CurrentDocument.Organization);
	Query.SetParameter("Department",	CurrentDocument.Department);
	Query.SetParameter("Warehouse",			CurrentDocument.Warehouse);
	Query.SetParameter("PeriodBeginning",	BegOfMonth(CurrentDocument.Date));
	Query.SetParameter("PeriodEnd",EndOfMonth(CurrentDocument.Date));
	Query.SetParameter("CurrentDocument",CurrentDocument.Ref);
	Query.SetParameter("Products",	CurrentDocument.Products);
	Query.SetParameter("Characteristic",	CurrentDocument.Characteristic);
	Query.SetParameter("Series",			CurrentDocument.Series);
	Query.SetParameter("Purpose",		CurrentDocument.Purpose);
	Query.SetParameter("Warehouse",			CurrentDocument.Warehouse);
	Query.SetParameter("NewProduction", CurrentDocument.NewProduction);
	
	If Not Query.Execute().IsEmpty() Then
		
		MessageText = NStr("vi = 'Trong tháng chỉ ra đã có chứng từ tương đương.
			|Chưa thực hiện giao dịch.';
			|ru = 'В указанном месяце уже существует аналогичный документ.
			|Операция не выполнена.';
			|en = 'Similar document already exists in the specified month.
			|Operation failed.'; fa = 'Similar document already exists in the specified month.
			|Operation failed.';
			|it = 'Nel mese indicato esiste già un documento analogo. 
			| Operazione non eseguita.';
			|pl = 'W podanym miesiącu już istnieje analogiczny dokument.
			|Operacja nie powiodła się.';
			|tr = 'Belirtilen ayda benzer bir belge zaten mevcut.
			|İşlem tamamlanmadı'");
		CommonClientServer.MessageToUser(MessageText);
		
		Cancel = True;
	EndIf;
	
EndProcedure

&AtServer
Procedure CollapseExpandTS(Expand = False)
	
	If Not Expand Then
		
		GroupingColumns = "Products, Characteristic, BillOfMaterials, ProductCostElement, Series, Package";
		TotalingColumns = "NumberOfPackages, Count";
		
		ValueTable = Object.ProductionIssueWithoutReferences.Unload(,GroupingColumns + ", " + TotalingColumns); // ValueTable
		ValueTable.GroupBy(GroupingColumns, TotalingColumns);
		
		ProductionIssueWithoutReferences.Load(ValueTable);
		
		FilterStructure1 = New Structure(GroupingColumns);
		TemplateOfPresentation = NStr("vi = 'Tổng số chứng từ xuất xưởng: %1';
										|ru = 'Всего документов выпуска: %1';
										|en = 'Total release documents: %1'; fa = 'Total release documents: %1';
										|it = 'In totale documenti di produzione: %1';
										|pl = 'Razem dokumentów produkcji: %1';
										|tr = 'Toplam ürün çıkış belgeleri: %1'");
		
		For Each String In ProductionIssueWithoutReferences Do
			FillPropertyValues(FilterStructure1, String);
			FoundRows = Object.ProductionIssueWithoutReferences.FindRows(FilterStructure1);
			String.SubmissionOfIssueDocuments = StringFunctionsClientServer.SubstituteParametersToString(
				TemplateOfPresentation,
				FoundRows.Count());
			
		EndDo;
	Else
		ProductionIssueWithoutReferences.Load(Object.ProductionIssueWithoutReferences.Unload());
	EndIf;
	
	FillInServiceDetailsForProductRange("ProductionIssueWithoutReferences");
	MaterialQuantityInclReleasesWithoutReferences = ProductionIssueWithoutReferences.Total("Count");
	
	LineNumber = 1;
	For Each String In ProductionIssueWithoutReferences Do
		String.LineNumber = LineNumber;
		LineNumber = LineNumber + 1;
	EndDo;
	
EndProcedure

&AtServer
Procedure FillInServiceDetailsForProductRange(TSName)
	
	ParametersForFillingInBankingDetails = New Structure;
	ParametersForFillingInBankingDetails.Insert("FillInFeatureAttribute",
		New Structure("Products", "ItemVariantsAreUsed"));
	
	ParametersForFillingInBankingDetails.Insert("FillInProductTypeAttribute_",
		New Structure("Products", "ItemsType"));
	
	If TSName = "ProductionIssueWithoutReferences" Then
		ProductsServer.FillInServiceDetailsForProductInCollection(ThisForm[TSName], ParametersForFillingInBankingDetails);
		ProductsServer.FillInServiceDetailsForProductInCollection(Object[TSName], ParametersForFillingInBankingDetails);
	EndIf;
	
EndProcedure


&AtServer
Procedure ProcessingSelectionOfOutputProducts(ValueSelected)
	
	ExpandReleasesWithoutReferences = ValueSelected.ExpandReleasesWithoutReferences;
	
	StructureOfData = GetFromTempStorage(ValueSelected.AddressInStorage);
	TheStructureOfTheSearch = New Structure("Products, Characteristic, DocumentOfProductionIssue, RowCode");
	
	For Each DataElement In StructureOfData.Goods Do
		
		FillPropertyValues(TheStructureOfTheSearch, DataElement);
		StringsTSGoods = Object.ProductionIssueWithoutReferences.FindRows(TheStructureOfTheSearch);
		If StringsTSGoods.Count() = 0 Then
			
			TSRow = Object.ProductionIssueWithoutReferences.Add();
			
		ElsIf StringsTSGoods.Count() = 1 Then
			
			TSRow = StringsTSGoods[0];
			
		Else
			
			For Each RowOfGoods In StringsTSGoods Do
				Object.ProductionIssueWithoutReferences.Delete(RowOfGoods);
			EndDo;
			
			TSRow = Object.ProductionIssueWithoutReferences.Add();
			
		EndIf;
		
		FillPropertyValues(TSRow, DataElement);
		Modified = True;
		
		If Not DataElement.ExistsInTheDocument
			And Not ExpandReleasesWithoutReferences Then
			ExpandReleasesWithoutReferences = YouNeedToDeployReleasesWithoutOrdering(DataElement);
		EndIf;
		
	EndDo;
	
	Items.IssuesWithoutAnOrderExpandByIssueDocumentsButton.Check = ExpandReleasesWithoutReferences;
	CollapseExpandTS(ExpandReleasesWithoutReferences);
	
EndProcedure

&AtServer
Function YouNeedToDeployReleasesWithoutOrdering(CurrentData)
	
	TheStructureOfTheSearch = New Structure("Products, Characteristic, Series, BillOfMaterials");
	FillPropertyValues(TheStructureOfTheSearch, CurrentData);
	
	FoundRows = ProductionIssueWithoutReferences.FindRows(TheStructureOfTheSearch);
	
	If FoundRows.Count() > 0 Then
		Return True;
	Else
		Return False;
	EndIf;
	
EndFunction

&AtClient
Procedure SaveRowData(RowData)
	
	SavedData = New Structure("Products, Characteristic, Series, BillOfMaterials, ProductCostElement");
	FillPropertyValues(SavedData, RowData);
	
EndProcedure

&AtServer
Procedure UpdateObjectTable(TSName, Id)
	
	CurrentData = ThisForm[TSName].FindByID(Id);
	
	If ExpandReleasesWithoutReferences Then
		FilterStructure1 = New Structure("DocumentOfProductionIssue, RowCode");
		FillPropertyValues(FilterStructure1, CurrentData);
	Else
		If TSName = "ProductionIssueWithoutReferences" Then
			FilterStructure1 = New Structure("Products, Characteristic, Series, BillOfMaterials, ProductCostElement");
		EndIf;
		FillPropertyValues(FilterStructure1, SavedData);
	EndIf;
	
	FoundRows = Object[TSName].FindRows(FilterStructure1);
	
	If FoundRows.Count() > 0 Then
		FillPropertyValues(FoundRows[0], CurrentData, ,"DocumentOfProductionIssue,RowCode");
	EndIf;
	
EndProcedure

&AtServer
Procedure DistributeAmountOfMaterials(Id)
	
	CurrentData = ProductionIssueWithoutReferences.FindByID(Id);
	
	FilterStructure1 = New Structure("Products, Characteristic, Series, BillOfMaterials, ProductCostElement");
	FillPropertyValues(FilterStructure1, CurrentData);
	
	FoundRows = Object.ProductionIssueWithoutReferences.FindRows(FilterStructure1);
	
	Coefficients = New Array;
	For Each String In FoundRows Do
		Coefficients.Add(String.NumberOfPackages);
	EndDo;
	
	AllocationResult = Common.DistributeAmountInProportionToCoefficients(CurrentData.Count, Coefficients, 3);
	
	If AllocationResult = Undefined Then
		Return;
	EndIf;
	
	IndexOf = 0;
	For Each ZoomRatio In AllocationResult Do
		FoundRows[IndexOf].Count = ZoomRatio;
		IndexOf = IndexOf + 1;
	EndDo;
	
EndProcedure

&AtServer
Procedure SetCalculationArticleByLine(Id)
	
	CurrentData = ProductionIssueWithoutReferences.FindByID(Id);
	
	FilterStructure1 = New Structure("Products, Characteristic, Series, BillOfMaterials");
	FillPropertyValues(FilterStructure1, CurrentData);
	FilterStructure1.Insert("ProductCostElement", SavedData.ProductCostElement);
	
	FoundRows = Object.ProductionIssueWithoutReferences.FindRows(FilterStructure1);
	
	For Each String In FoundRows Do
		String.ProductCostElement = CurrentData.ProductCostElement;
	EndDo;
	
EndProcedure

&AtServer
Procedure CheckFillingOfTabularPartOfIssueWithoutOrdering(Cancel)
	
	CheckedAttributes = New ValueList;
	CheckedAttributes.Add("Count", NStr("vi = 'Số lượng nguyên vật liệu, công trình';
										|ru = 'Количество материалов, работ';
										|en = 'Quantity of materials, operations'; fa = 'Quantity of materials, operations';
										|it = 'Numero di materiali, lavori';
										|pl = 'Ilość materiałów, robót';
										|tr = 'Malzemelerin, işlerin miktarı'"));
	CheckedAttributes.Add("ProductCostElement", NStr("vi = 'Dạng tính giá thành';
													|ru = 'Статья калькуляции';
													|en = 'Product cost element'; fa = 'عنصر بهای تمام‌شده محصول';
													|it = 'Voce di calcolo';
													|pl = 'Rodzaj kosztu';
													|tr = 'Ürün maliyet kalemi'"));
	
	MessageTemplate = NStr("vi = 'Chưa điền trường %1 trong dòng %2 của danh sách ""Xuất xưởng không có lệnh""';
							|ru = 'Не заполнено поле %1 в строке %2 списка ""На выпуски без распоряжений""';
							|en = '%1 is required in line %2 of the ""To releases without references"" list'; fa = '%1 is required in line %2 of the ""To releases without references"" list';
							|it = 'Non è stato compilato il campo %1 nella riga %2 dell''elenco ""Per produzioni senza disposizioni""';
							|pl = 'Nie wypełniono pole %1 w wierszu %2 listy ""Do produkcji bez zamówień""';
							|tr = '""Talimatsız Ürün Çıkışı"" listesinin %2 satırındaki %1 alanı doldurulmadı'");
	MessageTemplateWithoutNumber = NStr("vi = 'Chưa điền trường %1 của danh sách ""Xuất xưởng không có lệnh""';
										|ru = 'Не заполнено поле %1 в списке ""На выпуски без распоряжений""';
										|en = '%1 is required in the ""To releases without references"" list'; fa = '%1 is required in the ""To releases without references"" list';
										|it = 'Non è stato compilato il campo %1 nell''elenco ""Per produzioni senza disposizioni""';
										|pl = 'Nie wypełniono pole %1 listy ""Do produkcji bez zamówień""';
										|tr = '""Talimatsız Ürün Çıkışı"" listesinde %1 alanı doldurulmadı'");
	
	For Each String In Object.ProductionIssueWithoutReferences Do
		
		For Each Attribute In CheckedAttributes Do
			
			If Not ValueIsFilled(String[Attribute.Value]) Then
				
				If ThisForm.ExpandReleasesWithoutReferences Then
					FilterStructure1 = New Structure("DocumentOfProductionIssue, RowCode");
				Else
					FilterStructure1 = New Structure("Products, Characteristic, BillOfMaterials, Series");
				EndIf;
				
				FillPropertyValues(FilterStructure1, String);
				FoundRows = ProductionIssueWithoutReferences.FindRows(FilterStructure1);
				
				If FoundRows.Count() > 0 Then
					
					MessageLineNumber = FoundRows[0].LineNumber;
					
					MessageText = StringFunctionsClientServer.SubstituteParametersToString(MessageTemplate,
						Attribute.Presentation,
						MessageLineNumber);
					
					CommonClientServer.MessageToUser(
						MessageText,
						,
						CommonClientServer.PathToTabularSection("ProductionIssueWithoutReferences", MessageLineNumber, Attribute.Value),
						,
						Cancel);
					
				Else
					
					MessageText = StringFunctionsClientServer.SubstituteParametersToString(MessageTemplateWithoutNumber,
						Attribute.Presentation);
						
					CommonClientServer.MessageToUser(
						MessageText,
						,
						"ProductionIssueWithoutReferences",
						,
						Cancel);
					
				EndIf;
				
			EndIf;
			
		EndDo;
		
	EndDo;
	
EndProcedure

&AtClient
Procedure SetVisibilityOfDistributionRuleSettings()
	
	If ValueIsFilled(Object.AllocatedAccordingToRule) Then
		Items.PageGroupByRule.CurrentPage = Items.PageRuleIsSelected;
		Items.MoveSettingsToARule.Visible = True;
	Else
		Items.PageGroupByRule.CurrentPage = Items.PageRuleIsNotSelected;
		Items.MoveSettingsToARule.Visible = False;
	EndIf;
	SetTextAndVisibilityOfSelectionOfDistributionBase();
	
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
	Object.ProductCostElement = ?(Not Result[3].IsEmpty(),
									   Result[3].Unload()[0].ProductCostElement,
									   Catalogs.ProductCostElements.EmptyRef());
	UseProductGroupSelection = (FilterByProductsGroups.Count() > 0);
	Object.AllocationBase = ?(Not Result[4].IsEmpty(),
									   Result[4].Unload()[0].AllocationBase,
									   Enums.TypesOfCostAllocatingBase.EmptyRef());
									   
	SetTextOfLabelDistributionBase();
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
Procedure SetVisibilityOnSelectionByProductGroups()
	
	Items.LabelFilterByProductGroups.Visible = UseProductGroupSelection;
	
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
	Items.LabelFilterByProductGroups.Title = LabelText;
	
EndProcedure

&AtServer
Procedure SetTextOfLabelDistributionBase()
	
	Items.LabelDistributionBase.Title = TrimAll(Object.AllocationBase);
		
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
	
	If Object.AllocationBase = Enums.TypesOfCostAllocatingBase.StandardMaterialConsumption Then
		Items.DecorationWarningByStandards.Visible = True;
	Else
		Items.DecorationWarningByStandards.Visible = False;
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
	Items.LabelAllocationBaseFilter.Title = LabelText;
	
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
	Items.LabelAllocationBaseFilter.Title = LabelText;
	
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
Procedure MoveSettingsToARuleServer()
	
	Rule = Object.AllocatedAccordingToRule.GetObject();
	Rule.ProductCostElement = Object.ProductCostElement;
	UsedMaterials = New ValueTable;
	UsedMaterials.Columns.Add("Material", New TypeDescription("CatalogRef.Products"));
	ActivityKinds = New ValueTable;
	ActivityKinds.Columns.Add("WorkKind", New TypeDescription("CatalogRef.EmployeeWorkKinds"));
	ProductGroups_ = New ValueTable;
	ProductGroups_.Columns.Add("ProductsGroup", New TypeDescription("CatalogRef.AnalyticalInventoryGroups"));
	For Each Item In FilterByMaterials Do
		NewRow = UsedMaterials.Add();
		NewRow.Material = Item.Value;
	EndDo;
	For Each Item In FilterByActivityKind Do
		NewRow = ActivityKinds.Add();
		NewRow.WorkKind = Item.Value;
	EndDo;
	For Each Item In FilterByProductsGroups Do
		NewRow = ProductGroups_.Add();
		NewRow.ProductsGroup = Item.Value;
	EndDo;
	
	Rule.FilterByMaterials.Load(UsedMaterials);
	Rule.FilterByActivityKind.Load(ActivityKinds);
	Rule.FilterByProductsGroups.Load(ProductGroups_);
	Rule.Write();
	
EndProcedure

// StandardSubsystems.Properties 
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

#EndRegion

&AtServer
Procedure SetConditionalRegistrationOfRecipientDivision()
	
	// The recipient division matches the one specified in the header
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.OtherExpensesDepartment.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.OtherExpenses.Department");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<khớp với hiện tại>';
													|ru = '<совпадает с текущим>';
													|en = '<matches the current one>'; fa = '<matches the current one>';
													|it = '<coincide con il corrente>';
													|pl = '<jest zgodny z bieżącym>';
													|tr = '<mevcut olanla aynı>'"));
	Item.Appearance.SetParameterValue("TextColor", StyleColors.InaccessibleCellTextColor);
	
	
EndProcedure

&AtServer
Procedure InitializeProductMovementData()
	
	BorderEndDate = New Boundary(EndOfMonth(Object.Date), BoundaryType.Including);
	Query = New Query(Documents.ProductionCostAllocation.RequestTextForMaterialsAndWorksInStorerooms());
	Query.TempTablesManager = New TempTablesManager;
	
	AvailableCompanies = New Array;
	AvailableCompanies.Add(Object.Organization);
	
	Query.SetParameter("AllRegisteredRecords",                True);
	Query.SetParameter("BeginOfPeriod",              BegOfMonth(Object.Date));
	Query.SetParameter("BorderEndOfPeriod_",    BorderEndDate);
	Query.SetParameter("PeriodEnding",           EndOfMonth(Object.Date));
	Query.SetParameter("AllCompanies",             AvailableCompanies.Count() = 0);
	Query.SetParameter("Companies",                AvailableCompanies);
	Query.SetParameter("AllDepartments",           True);
	Query.SetParameter("Departments",              Undefined);
	Query.SetParameter("AllTypesOfProducts",        True);
	Query.SetParameter("ItemsType",            Undefined);
	Query.SetParameter("AllAnalysts",	            False);
	Query.SetParameter("ItemsLocationAttributes", Object.ItemsLocationAttributes);
	
	SetPrivilegedMode(True);
	
	Selection = Query.Execute().Select();
	
	If Selection.Next() Then
		IncomingBalance = Selection.IncomingBalance;
		OpeningBalance = Selection.OpeningBalance;
		Received = Selection.Received;
		Passed = Selection.Passed;
	EndIf;
	
EndProcedure

&AtClient
Procedure QuestionOfCalculatingAvailability(Result, Var_Parameters) Export

	If Result = DialogReturnCode.Yes Then
		Existence = IncomingBalance - Object.Count;
		Object.Allocate = IncomingBalance - Object.Count - Existence;
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
