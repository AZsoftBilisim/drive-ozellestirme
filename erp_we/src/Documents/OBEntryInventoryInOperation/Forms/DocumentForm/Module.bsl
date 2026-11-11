
#Region Variables

&AtClient
Var CachedValues; //used by the mechanism for processing changes in PM details

#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetConditionalAppearance();
	
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	UseLocal = GetFunctionalOption("UseLocal");
	Items.GroupEnterBalanceBy.Visible = UseLocal;
	
	TradeManagement = GetFunctionalOption("TradeManagement");
	UseTrackingOfTraceableItems = GetFunctionalOption("UseTraceableImportedGoodsAccounting");
	Items.InventoryInOperationCCDNumber.Visible = UseTrackingOfTraceableItems And Not TradeManagement;
	Items.InventoryInOperationQuantityByGBRN.Visible = UseTrackingOfTraceableItems And Not TradeManagement;
	
	AccountingForTraceableGoodsLocalization.SetTitleNumberOfCCD(Items, 
		Items.InventoryInOperationCCDNumber.Name);
	
	If Not ValueIsFilled(Object.Ref) Then
		OnReadCreateAtServer();
		ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);
	EndIf;
	
	ItemsAndDimensionsSelectionParameters = Documents.OBEntryInventoryInOperation.ItemsAndDimensionsSelectionParameters(Object.Date);
	IncomeAndExpensesServer.OnCreateAtServer(ThisObject, ItemsAndDimensionsSelectionParameters);
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	DocumentCorrection.OnCreateAtServer(ThisObject, Items.LineCorrection);
	
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	
	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)

	// StandardSubsystems.AccessManagement
	AccessManagement.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.AccessManagement
	
	// Handler of the "Date-change" mechanism
	PeriodClosingDates.ObjectOnReadAtServer(ThisObject, CurrentObject);
	
	ItemsAndDimensionsSelectionParameters = Documents.OBEntryInventoryInOperation.ItemsAndDimensionsSelectionParameters(Object.Date);
	IncomeAndExpensesServer.OnReadAtServer(ThisObject, ItemsAndDimensionsSelectionParameters);
	
	OnReadCreateAtServer();
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	// End StandardSubsystems.AttachableCommands
	
	DocumentCorrection.OnReadAtServer(ThisObject, Items.LineCorrection);
	
EndProcedure

&AtClient
Procedure BeforeWrite(Cancel, WriteParameters)
	
	FormEventsClient.BeforeWrite(ThisObject, Cancel, WriteParameters);
	
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	
	WriteParameters.Insert("BusinessOperation", Object.BusinessOperation);
	Notify("Write_OBEntry", WriteParameters, Object.Ref);
	TMCommonUseClient.NotifyAboutEntryOfDocumentInJournal();
	DocumentCorrectionClient.AfterWrite(Object);
	
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
	If Common.SubsystemExists("StandardSubsystems.AccessManagement") Then
		ModuleAccessManagement = Common.CommonModule("AccessManagement");
		ModuleAccessManagement.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	EndIf;
	// End StandardSubsystems.AccessManagement
	
	IncomeAndExpensesServer.AfterWriteAtServer(ThisObject);
	
	FillInServiceDetailsOfTS();
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	DocumentCorrectionClient.NotificationProcessing(ThisObject, EventName, Parameter, Source);
	
EndProcedure

&AtClient
Procedure ChoiceProcessing(ValueSelected, ChoiceSource)
	
	If ProductsClient.ThisIsIndicationOfSeries(ChoiceSource) Then
		ProductsClient.ProcessSeriesIndication(ThisObject, SeriesSpecificationParameters, ValueSelected);
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure DateOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	
	DateOfChangeOnServer();

EndProcedure

&AtClient
Procedure OrganizationOnChange(Item)
	
	CostDebited = CostDebited(Object.Organization, Object.Date);
	
	ConfigureDependentFormElementsOnClientOnServer(ThisObject, Item.Name);

EndProcedure

&AtClient
Procedure CommentStartChoice(Item, ChoiceData, StandardProcessing)
	
	CommonClient.ShowCommentEditingForm(
		Item.EditText, 
		ThisObject, 
		"Object.Comment");
	
EndProcedure

&AtClient
Procedure LineCorrectionURLProcessing(Item, FormattedStringURL, StandardProcessing)
	
	DocumentCorrectionClient.StringFixHandlingNavigationLinks(
		ThisObject, FormattedStringURL, StandardProcessing);
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersInventoryInOperation

&AtClient
Procedure InventoryInOperationOnStartEdit(Item, NewRow, Copy)
	
	CurrentData = Items.InventoryInOperation.CurrentData;

	If NewRow Then

		CurrentData.AssetID = "";
			
	EndIf;
	
	IncomeAndExpensesClientServer.WhenAddingRowToTable(ThisObject, CurrentData, "Object.InventoryInOperation");
	
EndProcedure

&AtClient
Procedure InventoryInOperationProductsOnChange(Item)
	
	CurrentRow = Items.InventoryInOperation.CurrentData;
	
	StructureOfActions = New Structure;
	AddActionsWhenChangingProducts(StructureOfActions, ThisObject, CurrentRow);
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
EndProcedure

&AtClient
Procedure InventoryInOperationOperationCategoryOnChange(Item)
	
	CurrentRow = Items.InventoryInOperation.CurrentData;

	WhenChangingCategoryOfOperation(CurrentRow);
	
	InventoryInOperationClient.ProcessLineWhenChangingCategoryOfOperation(
		CurrentRow, Object.InventoryInOperation,, "Count");
	
EndProcedure

&AtClient
Procedure InventoryInOperationExpenseItemOnChange(Item)
	
	IncomeAndExpensesClientServer.AssetRefOnChange(ThisObject, Item);
	
EndProcedure

&AtClient
Procedure InventoryInOperationExpenseItemStartChoice(Item, ChoiceData, StandardProcessing)
	IncomeAndExpensesClient.StartArticleSelection(ThisObject, Item, StandardProcessing);
EndProcedure

&AtClient
Procedure InventoryInOperationDimensionOfExpensesStartChoice(Item, ChoiceData, StandardProcessing)
	IncomeAndExpensesClient.StartSelectingExpenseAnalytics(ThisObject, Item, StandardProcessing);
EndProcedure

&AtClient
Procedure InventoryInOperationDimensionOfExpensesAutoComplete(Item, Text, ChoiceData, DataGetParameters, Waiting, StandardProcessing)
	IncomeAndExpensesClient.AutoSelectionOfExpenseAnalytics(ThisObject, Item, Text, ChoiceData, DataGetParameters, StandardProcessing);
EndProcedure

&AtClient
Procedure InventoryInOperationDimensionOfExpensesOnChange(Item)
	IncomeAndExpensesClientServer.DimensionOfExpensesOnChange(ThisObject, Item);
EndProcedure

&AtClient
Procedure InventoryInOperationDimensionOfExpensesTextEditEnd(Item, Text, ChoiceData, DataGetParameters, StandardProcessing)
	IncomeAndExpensesClient.EndOfCostAnalyticsTextEntry(ThisObject, Item, Text, ChoiceData, DataGetParameters, StandardProcessing);
EndProcedure

&AtClient
Procedure InventoryInOperationSeriesOnChange(Item)
	
	CurrentRow = Items.InventoryInOperation.CurrentData;
	
	ValueSelected = ProductsClientServer.SelectedSeries();
	
	ValueSelected.Value = CurrentRow.Series;
	ValueSelected.CurrentRowID = CurrentRow.GetID();
	
	ProductsClient.ProcessSeriesIndication(ThisObject, SeriesSpecificationParameters, ValueSelected);

EndProcedure

&AtClient
Procedure InventoryInOperationSeriesStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	OpenSelectionOfSeries(Item.EditText);

EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure SpecifySeries(Command)
	
	OpenSelectionOfSeries();

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

#EndRegion

#Region Private

#Region OnChangeAttributes

&AtServer
Procedure DateOfChangeOnServer()
	
	CostDebited = CostDebited(Object.Organization, Object.Date);

	ItemsAndDimensionsSelectionParameters = Documents.OBEntryInventoryInOperation.ItemsAndDimensionsSelectionParameters(Object.Date);
	IncomeAndExpensesServer.WhenChangingArticleSelectionParameters(ThisObject, ItemsAndDimensionsSelectionParameters);

	ConfigureDependentFormElementsOnClientOnServer(ThisObject, "Date");
	
EndProcedure

&AtClient
Procedure WhenChangingCategoryOfOperation(CurrentRow)
	
	StructureOfActions = New Structure;
	
	FillParameters = InventoryInOperationClientServer.ParametersForFillingInOperationCategoryAttributes();
	StructureOfActions.Insert("FillInCategoryAttributes", FillParameters);
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
	If Not CurrentRow.AccountingForIndividuals Then
		CurrentRow.Individual = PredefinedValue("Catalog.Persons.EmptyRef");
	EndIf;
	
EndProcedure

#EndRegion

#Region Other

&AtServer
Procedure SetConditionalAppearance()
	
	ConditionalAppearance.Items.Clear();
	
	ProductsServer.EstablishConditionalAppearanceOfProductCharacteristics(
		ThisObject,
		"InventoryInOperationCharacteristic",
		"Object.InventoryInOperation.ItemVariantsAreUsed");
	
	ProductsServer.EstablishConditionalAppearanceOfProductSeries(
		ThisObject, 
		"SeriesAlwaysWHGoods",
		"InventoryInOperationSeries",
		"Object.InventoryInOperation.BatchesIndicationStatus",
		"Object.InventoryInOperation.ItemsType");
		
	ProductsServer.SetConditionalAppearanceOfStatusIndicationSeries(
		ThisObject, 
		True,
		"InventoryInOperationBatchesIndicationStatus",
		"Object.InventoryInOperation.BatchesIndicationStatus");
	
	InventoryInOperationServer.SetConditionalRegistrationOfInventoryNumber(
		ThisObject,
		Items.InventoryInOperationAssetID.Name,
		"Object.InventoryInOperation.StocktakingRecord",
		"Object.InventoryInOperation.OperationCategory");
		
	InventoryInOperationServer.EstablishConditionalRegistrationOfIndividual(
		ThisObject,
		Items.InventoryInOperationIndividual.Name,
		"Object.InventoryInOperation.AccountingForIndividuals",
		"Object.InventoryInOperation.OperationCategory");
	
	#Region InventoryInOperationFixedAsset
	
	ConditionalAppearanceItem = ConditionalAppearance.Items.Add();
	
	DataCompositionClientServer.AddFieldToCreate(
		ConditionalAppearanceItem.Fields, Items.InventoryInOperationFixedAsset.Name);
	
	DataCompositionClientServer.AddFilter(
		ConditionalAppearanceItem.Filter, 
		"Object.InventoryInOperation.AccountAsGroupFA", 
		False);
	
	ConditionalAppearanceItem.Appearance.SetParameterValue("TextColor", StyleColors.InaccessibleCellTextColor);
	ConditionalAppearanceItem.Appearance.SetParameterValue("MarkIncomplete", False);
	ConditionalAppearanceItem.Appearance.SetParameterValue("Text", NStr("vi = '<không sử dụng>';
																		|ru = '<не используется>';
																		|en = '<not used>'; fa = '<استفاده نمی‌شود>';
																		|it = '<non viene utilizzato>';
																		|pl = '<nie używa się>';
																		|tr = '<kullanılmayan>'"));
	ConditionalAppearanceItem.Appearance.SetParameterValue("ReadOnly", True);	
	
	#EndRegion
	
	#Region Amount_AmountTemporaryDifferences_AmountPermanentDifferences_BeforeFSB5
	
	ConditionalAppearanceItem = ConditionalAppearance.Items.Add();
	
	DataCompositionClientServer.AddFieldToCreate(ConditionalAppearanceItem.Fields, Items.InventoryInOperationSum.Name);
	DataCompositionClientServer.AddFieldToCreate(ConditionalAppearanceItem.Fields, Items.InventoryInOperationAmountPermanentDifferences.Name);
	DataCompositionClientServer.AddFieldToCreate(ConditionalAppearanceItem.Fields, Items.InventoryInOperationAmountTemporaryDifferences.Name);
	
	FilterGroup = DataCompositionClientServer.AddSelectionGroup(ConditionalAppearanceItem.Filter.Items, DataCompositionFilterItemsGroupType.AndGroup);
	DataCompositionClientServer.AddFilter(FilterGroup, "Object.InventoryInOperation.MethodOfRepaymentOfCostOfAC", Enums.WaysToRepayCostOfInventory.OnCommissioning);
	DataCompositionClientServer.AddFilter(
		FilterGroup, 
		"Object.InventoryInOperation.StartDateOfOperation", 
		New DataCompositionField("BeginningOfApplicationOfFSBU5"),
		DataCompositionComparisonType.Less);
	
	ConditionalAppearanceItem.Appearance.SetParameterValue("TextColor", StyleColors.InaccessibleCellTextColor);
	ConditionalAppearanceItem.Appearance.SetParameterValue("MarkIncomplete", False);
	ConditionalAppearanceItem.Appearance.SetParameterValue("Text", NStr("vi = '<không sử dụng>';
																		|ru = '<не используется>';
																		|en = '<not used>'; fa = '<استفاده نمی‌شود>';
																		|it = '<non viene utilizzato>';
																		|pl = '<nie używa się>';
																		|tr = '<kullanılmayan>'"));
	ConditionalAppearanceItem.Appearance.SetParameterValue("ReadOnly", True);	
	
	#EndRegion
	
	#Region Amount_AmountTemporaryDifferences_AmountPermanentDifferences_AfterFSB5
	
	ConditionalAppearanceItem = ConditionalAppearance.Items.Add();
	
	DataCompositionClientServer.AddFieldToCreate(ConditionalAppearanceItem.Fields, Items.InventoryInOperationSum.Name);
	DataCompositionClientServer.AddFieldToCreate(ConditionalAppearanceItem.Fields, Items.InventoryInOperationAmountPermanentDifferences.Name);
	DataCompositionClientServer.AddFieldToCreate(ConditionalAppearanceItem.Fields, Items.InventoryInOperationAmountTemporaryDifferences.Name);
	DataCompositionClientServer.AddFieldToCreate(ConditionalAppearanceItem.Fields, Items.InventoryInOperationExpenseItem.Name);
	DataCompositionClientServer.AddFieldToCreate(ConditionalAppearanceItem.Fields, Items.InventoryInOperationDimensionOfExpenses.Name);
	
	FilterGroup = DataCompositionClientServer.AddSelectionGroup(ConditionalAppearanceItem.Filter.Items, DataCompositionFilterItemsGroupType.AndGroup);
	DataCompositionClientServer.AddFilter(
		FilterGroup, 
		"Object.InventoryInOperation.StartDateOfOperation", 
		New DataCompositionField("BeginningOfApplicationOfFSBU5"),
		DataCompositionComparisonType.GreaterOrEqual);
	
	ConditionalAppearanceItem.Appearance.SetParameterValue("TextColor", StyleColors.InaccessibleCellTextColor);
	ConditionalAppearanceItem.Appearance.SetParameterValue("MarkIncomplete", False);
	ConditionalAppearanceItem.Appearance.SetParameterValue("Text", NStr("vi = '<không sử dụng>';
																		|ru = '<не используется>';
																		|en = '<not used>'; fa = '<استفاده نمی‌شود>';
																		|it = '<non viene utilizzato>';
																		|pl = '<nie używa się>';
																		|tr = '<kullanılmayan>'"));
	ConditionalAppearanceItem.Appearance.SetParameterValue("ReadOnly", True);	
	
	#EndRegion
		
	#Region Count
	
	Item = ConditionalAppearance.Items.Add();
	
	DataCompositionClientServer.AddFieldToCreate(Item.Fields, Items.InventoryInOperationCount.Name);
	
	DataCompositionClientServer.AddFilter(Item.Filter, "Object.InventoryInOperation.StocktakingRecord", True);
		
	Item.Appearance.SetParameterValue("Text", NStr("vi = '1.000';
													|ru = '1.000';
													|en = '1.000'; fa = '1.000';
													|it = '1.000';
													|pl = '1.000';
													|tr = '1.000'"));
	Item.Appearance.SetParameterValue("ReadOnly", True);
	Item.Appearance.SetParameterValue("TextColor", StyleColors.InaccessibleCellTextColor);
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	
	#EndRegion
	
	#Region AccountingSectionIsRegulated
	// Removing the blank mark in the "Regulated" accounting section
	
	Item = ConditionalAppearance.Items.Add();
	
	DataCompositionClientServer.AddFieldToCreate(Item.Fields, Items.InventoryInOperationAssetID.Name);
	DataCompositionClientServer.AddFieldToCreate(Item.Fields, Items.InventoryInOperationStartDateOfOperation.Name);
	DataCompositionClientServer.AddFieldToCreate(Item.Fields, Items.InventoryInOperationExpenseItem.Name);
	DataCompositionClientServer.AddFieldToCreate(Item.Fields, Items.InventoryInOperationDimensionOfExpenses.Name);
	
	DataCompositionClientServer.AddFilter(Item.Filter, "Object.RecordInOperationalAccounting", False);
	
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	#EndRegion
	
EndProcedure

&AtServer
Procedure OnReadCreateAtServer()
	
	CurrentSessionDate = CurrentSessionDate();
	BeginningOfApplicationOfFSBU5 = LocalAccntingClientServer.BeginningOfApplicationFSBU5_2019();
	CostDebited = CostDebited(Object.Organization, Object.Date);
	
	SeriesSpecificationParameters = New FixedStructure(ProductsServer.SeriesSpecificationParameters(Object, Documents.OBEntryInventoryInOperation));

	SetVisibilityOfSeriesElements();
	FillInServiceDetailsOfTS();
	
	ConfigureDependentFormElementsOnClientOnServer(ThisObject);
	
EndProcedure

&AtClientAtServerNoContext
Procedure ConfigureDependentFormElementsOnClientOnServer(Form, ChangedBankingDetails = "")
	
	Object = Form.Object;

	StructureOfChangedProps = New Structure(ChangedBankingDetails);
	UpdateAll = StructureOfChangedProps.Count() = 0;

	AddlParameters = New Structure;
	AddlParameters.Insert("CostDebited", Form.CostDebited);
	ItemDetailsParameters = InventoryInOperationClientServer.ValuesOfPropertiesOfDependentDetails_InputOfRemainingInventoryItemsInOperation(
									Object, AddlParameters, ChangedBankingDetails);
									
	TMCommonUseClientServer.ConfigureDependentFormElements(Form, ItemDetailsParameters);
	
	If Not UpdateAll Then
		TMCommonUseClientServer.ClearUnusedProps(Object, ItemDetailsParameters, "InventoryInOperation");
	EndIf;
		
EndProcedure

&AtServer
Procedure FillInServiceDetailsOfTS()

	ParametersForFillingInBankingDetails = New Structure;
	ParametersForFillingInBankingDetails.Insert("FillInFeatureAttribute", New Structure("Products", "ItemVariantsAreUsed"));
	ParametersForFillingInBankingDetails.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
	ProductsServer.FillInServiceDetailsForProductInCollection(Object.InventoryInOperation, ParametersForFillingInBankingDetails);
	Catalogs.OperationCategories.FillInCategoryAttributes(Object.InventoryInOperation);
EndProcedure

&AtClient
Procedure OpenSelectionOfSeries(Text = "", CurrentData = Undefined)

	If Not ProductsClient.YouNeedServerCallToSpecifySeries(ThisObject, SeriesSpecificationParameters, Text, CurrentData) Then
		Return;
	EndIf;
		
	If CurrentData = Undefined Then
		CurDataId = Items.InventoryInOperation.CurrentData.GetID();
	Else
		CurDataId = CurrentData.GetID();
	EndIf;

	ParametersOfSeriesIndicationForm = ParametersOfSeriesIndicationForm(CurDataId);
	
	AddlParameters = New Structure("ParametersOfSeriesIndicationForm", ParametersOfSeriesIndicationForm);
	CallbackDescription = New CallbackDescription("OpenSelectionOfSeriesCompletion", ThisObject, AddlParameters);
	
	OpenForm(
		ParametersOfSeriesIndicationForm.FormName,
		ParametersOfSeriesIndicationForm,
		ThisObject,,,, 
		CallbackDescription, 
		FormWindowOpeningMode.LockOwnerWindow);

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

&AtClientAtServerNoContext
Procedure AddActionsWhenChangingProducts(StructureOfActions, Form, CurrentRow)
	
	StructureOfActions.Insert("CheckCharacteristicsByOwner", CurrentRow.Characteristic);
	StructureOfActions.Insert("FillInFeatureAttribute", New Structure("Products", "ItemVariantsAreUsed"));
	StructureOfActions.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
	
	CheckSeriesCalculateStatus = New Structure("SeriesSpecificationParameters, Warehouse", Form.SeriesSpecificationParameters, Undefined);
	StructureOfActions.Insert("CheckSeriesCalculateStatus", CheckSeriesCalculateStatus);
	
EndProcedure

&AtServer
Function ParametersOfSeriesIndicationForm(CurDataId)
	
	Return ProductsServer.ParametersOfSeriesIndicationForm(Object, SeriesSpecificationParameters, CurDataId, ThisObject);
	
EndFunction

&AtServer
Procedure SetVisibilityOfSeriesElements()
	
	Items.InventoryInOperationBatchesIndicationStatus.Visible = SeriesSpecificationParameters.UseItemsBatch;
	Items.InventoryInOperationSpecifySeries.Visible = SeriesSpecificationParameters.UseItemsBatch;
	Items.InventoryInOperationSeries.Visible = SeriesSpecificationParameters.UseItemsBatch;
	
EndProcedure

&AtServerNoContext
Function CostDebited(Organization, Date)
	
	CostDebited = True;
	

	Return CostDebited;
	
EndFunction

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
