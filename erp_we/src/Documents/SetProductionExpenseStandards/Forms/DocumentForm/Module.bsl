
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	SetConditionalAppearance();
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(Object, ThisObject);

	If Not ValueIsFilled(Object.Ref) Then
		
		OnCreatReadAtServer();
		
	EndIf;
	
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	
	// StandardSubsystems.Properties
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("ItemForPlacementName", "GroupAdditionalAttributes");
	AdditionalParameters.Insert("DeferredInitialization", True);
	PropertyManager.OnCreateAtServer(ThisObject, AdditionalParameters);
	// End StandardSubsystems.Properties

	AttachableCommands.OnCreateAtServer(ThisObject);

	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject);
	// End IntegrationWith1CDocumentManagementSubsystem
	
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	
	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)

	// StandardSubsystems.AccessManagement
	AccessManagement.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.AccessManagement
	
	OnCreatReadAtServer();

	// StandardSubsystems.AttachableCommands
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	// End StandardSubsystems.AttachableCommands
	
	// StandardSubsystems.Properties
	PropertyManager.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.Properties
	
	ConfigurationModificationOverridable.OnReadAtServer(ThisForm, CurrentObject);

EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	// StandardSubsystems.Properties
	PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
	// End StandardSubsystems.Properties
	
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)

	ConfigurationModificationClientOverridable.AfterWrite(ThisForm, WriteParameters);

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
	
	FillInDependentDetails();
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	// StandardSubsystems.Properties 
	If PropertyManagerClient.ProcessNotifications(ThisObject, EventName, Parameter) Then
		UpdateAdditionalAttributesItems();
		PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
	EndIf;
	// End StandardSubsystems.Properties

EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	
	// StandardSubsystems.Properties
	PropertyManager.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes);
	// End StandardSubsystems.Properties

EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	// StandardSubsystems.Properties
	PropertyManager.BeforeWriteAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.Properties

	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.BeforeWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	// End IntegrationWith1CDocumentManagementSubsystem
	
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

&AtClient
Procedure ProductionExpenseStandards(Command)
	
	EndOfPeriod = Object.ValidityEndDate;
	If Not ValueIsFilled(EndOfPeriod) Then
		EndOfPeriod = EndOfYear(Object.ValidityStartDate);
	EndIf;
	
	Filter = New Structure;
	Filter.Insert("StandardPeriod", New StandardPeriod(Object.ValidityStartDate, EndOfPeriod));
	Filter.Insert("Organization", Object.Organization);
	Filter.Insert("Department", Object.Department);
	
	FormParameters = New Structure("VariantKey, PurposeUseKey, Filter, GenerateOnOpen, ReportOptionsCommandsVisibility");
	FormParameters.Insert("PurposeUseKey",		Undefined);
	FormParameters.Insert("Filter",							Filter);
	FormParameters.Insert("GenerateOnOpen",			True);
	FormParameters.Insert("ReportOptionsCommandsVisibility",	False);
	
	OpenForm("Report.PlannedAndActualProductionExpenseStandards.Form", FormParameters);
	
EndProcedure

&AtClient
Procedure SetDateInterval(Command)
	
	Dialog = New StandardPeriodEditDialog();
	
	Dialog.Period.StartDate    = BegOfMonth(Object.ValidityStartDate);
	If ValueIsFilled(Object.ValidityEndDate) Then
		Dialog.Period.EndDate = EndOfMonth(Object.ValidityEndDate);
	EndIf;
	
	Dialog.Show(New CallbackDescription("SetDateIntervalCompletion", ThisObject, New Structure("Dialog", Dialog)));
	
EndProcedure

&AtClient
Procedure FillInWithExpensesOfThePreviousMonth(Command)
	
	AskUserQuestion("All");
	
EndProcedure

&AtClient
Procedure FillInWithExpensesOfThePreviousMonths(Command)
	
	AskUserQuestion("All", True);
	
EndProcedure

&AtClient
Procedure FillInVariableExpensesOfThePreviousMonth(Command)
	
	AskUserQuestion("VariableCosts");
	
EndProcedure

&AtClient
Procedure FillInVariableExpensesOfThePreviousMonths(Command)
	
	AskUserQuestion("VariableCosts", True);
	
EndProcedure

&AtClient
Procedure FillInFixedExpensesOfThePreviousMonth(Command)
	
	AskUserQuestion("FixedCosts");
	
EndProcedure

&AtClient
Procedure FillInFixedExpensesOfThePreviousMonths(Command)
	
	AskUserQuestion("FixedCosts", True);
	
EndProcedure

#EndRegion

#Region HeaderEventHandlers

&AtClient
Procedure ValidityStartDateOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	
	Object.ValidityStartDate = BegOfMonth(Object.ValidityStartDate);
	
EndProcedure

&AtClient
Procedure ValidityEndDateOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	
	If Not ValueIsFilled(Object.ValidityEndDate) Then
		Return;
	EndIf;
	
	Object.ValidityEndDate = EndOfMonth(Object.ValidityEndDate);
	
EndProcedure

#EndRegion

#Region EventHandlersVariableCosts

&AtClient
Procedure VariableCostRatesOnStartEdit(Item, NewRow, Copy)
	
	If NewRow Then
		
		CurrentData = Items.VariableCostRates.CurrentData;
		CalculateStandardAndMultiplicity(CurrentData);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure VariableCostRatesExpenseItemOnChange(Item)
	
	WhenExpenseItemChangesServer("VariableCostRates");
	
EndProcedure

&AtClient
Procedure VariableCostRatesSumOnChange(Item)
	
	CurrentData = Items.VariableCostRates.CurrentData;
	CalculateStandardAndMultiplicity(CurrentData);
	
EndProcedure

&AtClient
Procedure VariableCostRatesValue_OnChange(Item)
	
	SetBaseValue("VariableCostRates");
	
EndProcedure

&AtClient
Procedure VariableCostRatesRepetitionOnChange(Item)

	CurrentData = Items.VariableCostRates.CurrentData;
	FillInMultiplicityPresentation(CurrentData);
	
EndProcedure

#EndRegion

#Region EventHandlersAreFixedCosts

&AtClient
Procedure FixedCostRatesOnStartEdit(Item, NewRow, Copy)
	
	If NewRow Then
		
		CurrentData = Items.FixedCostRates.CurrentData;
		CalculateStandardAndMultiplicity(CurrentData);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure FixedCostRatesExpenseItemOnChange(Item)
	
	WhenExpenseItemChangesServer("FixedCostRates");
	
EndProcedure

&AtClient
Procedure FixedCostRatesSumOnChange(Item)
	
	CurrentData = Items.FixedCostRates.CurrentData;
	CalculateStandardAndMultiplicity(CurrentData);
	
EndProcedure

&AtClient
Procedure FixedCostRatesBaseOnChange(Item)
	
	SetBaseValue("FixedCostRates");
	
EndProcedure

&AtClient
Procedure FixedCostRatesRepetitionOnChange(Item)
	
	CurrentData = Items.FixedCostRates.CurrentData;
	FillInMultiplicityPresentation(CurrentData);
	
EndProcedure

#EndRegion

#Region EventHandlersForDistributionBases

&AtClient
Procedure AllocationBaseValuesRulePresentationChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	Modified = True;
	StandardProcessing = False;
	
	If ValueSelected = "AllocatedAccordingToRule" Then
		Return;
	EndIf;
	
	If ValueSelected = "OtherRules" Then
		
		FilterForms = New Structure("AssignRule, Obsolete_", 
			PredefinedValue("Enum.AssignmentOfCostAllocationRules.ExpenseAllocationOnManufacturingCostsByLots"), False);
			
		FormParameters = New Structure;
		FormParameters.Insert("OnlyWithTheSpecifiedSelection", True);
		FormParameters.Insert("Filter", FilterForms);

		OpenForm("Catalog.CostAllocationRules.ChoiceForm", FormParameters, Item);
		
		Return;
		
	EndIf;
		
	CurrentData = Items.AllocationBaseValues.CurrentData;
	
	If TypeOf(ValueSelected) = Type("String") Then
		
		InfobaseType = "Enum.TypesOfCostAllocatingBase." + ValueSelected;
		CurrentData.AllocatedAccordingToRule = PredefinedValue(InfobaseType);
		
	Else	
		CurrentData.AllocatedAccordingToRule = ValueSelected;
	EndIf;
	
	InsertNewItemInSelectionList(CurrentData.AllocatedAccordingToRule, RuleDescription(CurrentData.AllocatedAccordingToRule));
	FillInDependentDetailsOfDistributionBasesInLine(Items.AllocationBaseValues.CurrentRow);
	
EndProcedure

&AtClient
Procedure AllocationBaseValuesRulePresentationOnChange(Item)
	
	CurrentData = Items.AllocationBaseValues.CurrentData;
	If Not ValueIsFilled(CurrentData.RulePresentation) Then
		
		CurrentData.RuleDescription = "";
		CurrentData.AllocatedAccordingToRule = Undefined;
		CurrentData.UnitOfMeasure = "";
		
	EndIf;
	
	Modified = True;
	
EndProcedure

&AtClient
Procedure AllocationBaseValuesRulePresentationOpening(Item, StandardProcessing)
	
	StandardProcessing = False;
	CurrentData = Items.AllocationBaseValues.CurrentData;
	If Not ValueIsFilled(CurrentData.AllocatedAccordingToRule)
		Or TypeOf(CurrentData.AllocatedAccordingToRule) = Type("EnumRef.TypesOfCostAllocatingBase") Then
		Return;
	EndIf;
	
	ShowValue(, CurrentData.AllocatedAccordingToRule);
	
EndProcedure

&AtClient
Procedure AllocationBaseValuesValue_OnChange(Item)
	
	CurrentData = Items.AllocationBaseValues.CurrentData;
	FillInValuePresentation(CurrentData);
	RecalculateExpenses("FixedCostRates", CurrentData.AllocatedAccordingToRule, CurrentData.Value_);
	RecalculateExpenses("VariableCostRates", CurrentData.AllocatedAccordingToRule, CurrentData.Value_);
	
EndProcedure

&AtClient
Procedure AllocationBaseValuesOnStartEdit(Item, NewRow, Copy)
	
	ProcessingOfTabularFormsClient.CacheCurLine(Items.AllocationBaseValues, ThisObject);
	
	CurrentData = Items.AllocationBaseValues.CurrentData;
	InsertNewItemInSelectionList(CurrentData.AllocatedAccordingToRule, CurrentData.RuleDescription);
	
EndProcedure

&AtClient
Procedure AllocationBaseValuesBeforeEditEnd(Item, NewRow, CancelEdit, Cancel)
	
	If Not NewRow Or NewRow And Not CancelEdit Then
		
		CurrentData = Items.AllocationBaseValues.CurrentData;
		
		DuplicatesFilter = New Structure("AllocatedAccordingToRule");
		FillPropertyValues(DuplicatesFilter, CurrentData);
		
		Duplicates = Object.AllocationBaseValues.FindRows(DuplicatesFilter);
		If Duplicates.Count() > 1 Then
			
			ErrorText = NStr("vi = 'Một danh sách đã tồn tại trong danh sách với quy tắc phân bổ %1';
							|ru = 'В списке уже существует строка с правилом распределения %1';
							|en = 'Line with the %1 allocation rule already exists in the list'; fa = 'Line with the %1 allocation rule already exists in the list';
							|it = 'Nell''elenco vi è una riga con la legge di distribuzione %1';
							|pl = 'Na liście już istnieje wiersz z regułą przydziału %1';
							|tr = 'Listede zaten %1 dağıtım kuralına sahip satır mevcut'");
			CommonClientServer.MessageToUser(
				StringFunctionsClientServer.SubstituteParametersToString(ErrorText, Duplicates[0].RuleDescription));
			Cancel = True;
			
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure AllocationBaseValuesOnEditEnd(Item, NewRow, CancelEdit)
	
	CurrentData = Items.AllocationBaseValues.CurrentData;
	
	LineCache = ?(NewRow, Undefined, ProcessingOfTabularFormsClientServer.LineCache(Items.AllocationBaseValues, ThisObject));
	If Not NewRow And Not LineCache = Undefined 
		And Not CurrentData.AllocatedAccordingToRule = LineCache.AllocatedAccordingToRule Then
		
		SelectedRule = CurrentData.AllocatedAccordingToRule;
		CurrentData.AllocatedAccordingToRule = LineCache.AllocatedAccordingToRule;
		DeletionParameters = ParametersForDeletingNorms(Items.AllocationBaseValues.SelectedRows);
		
		If DeletionParameters.ThereAreLinesToDelete Then
			
			AdditionalParameters = New Structure;
			AdditionalParameters.Insert("DeletionParameters", DeletionParameters);
			AdditionalParameters.Insert("CurrentData", CurrentData);
			AdditionalParameters.Insert("RuleToDelete", LineCache.AllocatedAccordingToRule);
			
			CallbackDescription = New CallbackDescription("AllocationBaseValuesOnEditEndCompletion", 
				ThisObject, 
				AdditionalParameters);
			
			NotificationText1 = NStr("vi = 'Chi phí với quy tắc Phân bổ %1 sẽ bị xóa. Tiếp tục?';
									|ru = 'Расходы с правилом распределения %1 будут удалены. Продолжить?';
									|en = 'Expenses with the %1 allocation rule will be deleted. Continue?'; fa = 'Expenses with the %1 allocation rule will be deleted. Continue?';
									|it = 'Le spese con la legge di distribuzione%1 verranno eliminate. Continuare?';
									|pl = 'Koszty z regułą przydziału %1 zostaną usunięte. Kontynuować?';
									|tr = '%1 dağıtım kuralına sahip giderler silinecektir. Devam edilsin mi?'");
			ShowQueryBox(CallbackDescription, 
				StringFunctionsClientServer.SubstituteParametersToString(NotificationText1, LineCache.RuleDescription),
				QuestionDialogMode.YesNo, , DialogReturnCode.No);
			
		Else
			CurrentData.AllocatedAccordingToRule = SelectedRule;
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure AllocationBaseValuesBeforeDeleteRow(Item, Cancel)
	
	DeletionParameters = ParametersForDeletingNorms(Items.AllocationBaseValues.SelectedRows);
	
	If DeletionParameters.ThereAreLinesToDelete Then
		
		Cancel = True;
		AdditionalParameters = New Structure;
		AdditionalParameters.Insert("DeletionParameters", DeletionParameters);
		AdditionalParameters.Insert("IDOfValueRows", Items.AllocationBaseValues.SelectedRows);
		
		CallbackDescription = New CallbackDescription("AllocationBaseValuesBeforeDeleteRowCompletion", 
			ThisObject, 
			AdditionalParameters);
		
		NotificationText1 = NStr("vi = 'Tỷ lệ chi phí với quy tắc Phân bổ cho các hàng bị xóa sẽ bị xóa. Tiếp tục?';
								|ru = 'Нормы расходов с правилами распределения удаляемых строк будут удалены. Продолжить?';
								|en = 'Expense standards with allocation rules of removed lines will be deleted. Continue?'; fa = 'Expense standards with allocation rules of removed lines will be deleted. Continue?';
								|it = 'Le tariffe con le regole di distribuzione delle righe eliminate verranno eliminate. Continuare?';
								|pl = 'Normy kosztów wraz z regułami przydziału usuwanych wierszy zostaną usunięte. Kontynuować?';
								|tr = 'Silinen satırlar için dağıtım kurallarına sahip gider oranları silinecektir. Devam edilsin mi?'");
		ShowQueryBox(CallbackDescription, NotificationText1, QuestionDialogMode.YesNo);
		
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
	
#Region RulePresentation

	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.AllocationBaseValuesRulePresentation.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.AllocationBaseValues.RuleDescription");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	
	Item.Appearance.SetParameterValue("Text", New DataCompositionField("Object.AllocationBaseValues.RuleDescription"));
	
	#Region VariableCosts
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.VariableCostRatesRuleDescription.Name);
	
	FilterGroup = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
	
	ItemFilter = FilterGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.VariableCostRates.AllocatedAccordingToRule");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	ItemFilter = FilterGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.VariableCostRates.ExpenseItem");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	
	Item.Appearance.SetParameterValue("Text", NStr("vi = 'Không được hỗ trợ';
													|ru = 'Не поддерживается';
													|en = 'Not supported'; fa = 'Not supported';
													|it = 'Non supportato';
													|pl = 'Nieobsługiwane';
													|tr = 'Desteklenmemektedir'"));
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.VariableCostRatesSum.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.VariableCostRatesValue_.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.VariableCostRatesNormativeStandard.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.VariableCostRatesRepetition.Name);
	
	FilterGroup = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
	
	ItemFilter = FilterGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.VariableCostRates.AllocatedAccordingToRule");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	ItemFilter = FilterGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.VariableCostRates.ExpenseItem");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	
	Item.Appearance.SetParameterValue("ReadOnly", True);
	
	#EndRegion
	
	#Region FixedCosts
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.FixedCostRatesRuleDescription.Name);
	
	FilterGroup = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
	
	ItemFilter = FilterGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.FixedCostRates.AllocatedAccordingToRule");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	ItemFilter = FilterGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.FixedCostRates.ExpenseItem");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	
	Item.Appearance.SetParameterValue("Text", NStr("vi = 'Không được hỗ trợ';
													|ru = 'Не поддерживается';
													|en = 'Not supported'; fa = 'Not supported';
													|it = 'Non supportato';
													|pl = 'Nieobsługiwane';
													|tr = 'Desteklenmemektedir'"));
	
	// Blocking editing if the allocation rule is unsupported.
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.FixedCostRatesRuleDescription.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.FixedCostRatesBase.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.FixedCostRatesRepetition.Name);

	FilterGroup = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
	
	ItemFilter = FilterGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.FixedCostRates.AllocatedAccordingToRule");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	ItemFilter = FilterGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.FixedCostRates.ExpenseItem");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	
	Item.Appearance.SetParameterValue("ReadOnly", True);
	
	#EndRegion
	
#EndRegion

#Region PresentationOfMultiplier

	// Fixed costs.
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.FixedCostRatesRepetition.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.FixedCostRates.Value_");
	ItemFilter.ComparisonType = DataCompositionComparisonType.GreaterOrEqual;
	ItemFilter.RightValue = 0;
	
	Item.Appearance.SetParameterValue("Text", New DataCompositionField("Object.FixedCostRates.PresentationOfMultiplier"));
	
	// Variable costs.
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.VariableCostRatesRepetition.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.VariableCostRates.Value_");
	ItemFilter.ComparisonType = DataCompositionComparisonType.GreaterOrEqual;
	ItemFilter.RightValue = 0;
	
	Item.Appearance.SetParameterValue("Text", New DataCompositionField("Object.VariableCostRates.PresentationOfMultiplier"));
	
#EndRegion

#Region CostAssignmentText

	// Fixed costs.
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.FixedCostRatesReferStandard.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.FixedCostRates.Value_");
	ItemFilter.ComparisonType = DataCompositionComparisonType.GreaterOrEqual;
	ItemFilter.RightValue = 0;
	
	Item.Appearance.SetParameterValue("Text", NStr("vi = 'sang';
													|ru = 'на';
													|en = 'for'; fa = 'برای';
													|it = 'на';
													|pl = 'for';
													|tr = 'ilişkin'"));
	
	// Variable costs.
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.VariableCostRatesReferStandard.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.VariableCostRates.Value_");
	ItemFilter.ComparisonType = DataCompositionComparisonType.GreaterOrEqual;
	ItemFilter.RightValue = 0;
	
	Item.Appearance.SetParameterValue("Text", NStr("vi = 'sang';
													|ru = 'на';
													|en = 'for'; fa = 'برای';
													|it = 'на';
													|pl = 'for';
													|tr = 'ilişkin'"));
	
#EndRegion

#Region ValueRepresentation_3

	// Fixed costs.
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.FixedCostRatesBase.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.FixedCostRates.Value_");
	ItemFilter.ComparisonType = DataCompositionComparisonType.GreaterOrEqual;
	ItemFilter.RightValue = 0;
	
	Item.Appearance.SetParameterValue("Text", New DataCompositionField("Object.FixedCostRates.ValueRepresentation_3"));
	
	// Variable costs.
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.VariableCostRatesValue_.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.VariableCostRates.Value_");
	ItemFilter.ComparisonType = DataCompositionComparisonType.GreaterOrEqual;
	ItemFilter.RightValue = 0;
	
	Item.Appearance.SetParameterValue("Text", New DataCompositionField("Object.VariableCostRates.ValueRepresentation_3"));
	
	// The values of the distribution bases.
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.AllocationBaseValuesValue_.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.AllocationBaseValues.Value_");
	ItemFilter.ComparisonType = DataCompositionComparisonType.GreaterOrEqual;
	ItemFilter.RightValue = 0;
	
	Item.Appearance.SetParameterValue("Text", New DataCompositionField("Object.AllocationBaseValues.ValueRepresentation_3"));
	
#EndRegion

EndProcedure

&AtServer
Procedure OnCreatReadAtServer()
	
	NumberOfMonths = 0;
	If Parameters.Property("FillingValues")
	 And TypeOf(Parameters.FillingValues) = Type("Structure") 
	 And Parameters.FillingValues.Property("NumberOfMonths", NumberOfMonths) Then
		FillAtServer("All", NumberOfMonths);
	EndIf;
	
	FillRuleSelectionList();
	SetHeaders();
	FillInDependentDetails();
	ProcessingOfTabularForms.InitializeRowCache(Items.AllocationBaseValues);
	
EndProcedure

&AtServer
Procedure FillInDependentDetails()
	
	DatabasePresentations = PresentationsOfSimpleDatabases();
	
	For Each ValueString In Object.AllocationBaseValues Do
		FillInDependentDetailsOfDistributionBasesInLine(ValueString, DatabasePresentations);
	EndDo;
	
	For Each ConstantConsumption In Object.FixedCostRates Do
		
		FillInAccordingToDistributionDatabase(ConstantConsumption, "FixedCostRates");
		FillInMultiplicityPresentation(ConstantConsumption);
		
	EndDo;
	
	For Each MutableExpense In Object.VariableCostRates Do
		
		FillInAccordingToDistributionDatabase(MutableExpense, "VariableCostRates");
		FillInMultiplicityPresentation(MutableExpense);
		
	EndDo;
	
EndProcedure

&AtServer
Procedure SetHeaders()
	
	AmountHeaderText = NStr("vi = 'Số tiền (%1)';
							|ru = 'Сумма (%1)';
							|en = 'Amount (%1)'; fa = 'Amount (%1)';
							|it = 'Totale (%1)';
							|pl = 'Wartość (%1)';
							|tr = 'Tutar (%1)'");
	StandardHeaderText = NStr("vi = 'Tiêu chuẩn (%1)';
								|ru = 'Норматив (%1)';
								|en = 'Standard (%1)'; fa = 'Standard (%1)';
								|it = 'Specifica (%1)';
								|pl = 'Normatyw (%1)';
								|tr = 'Standart (%1)'");
	Currency = Constants.ManagementAccountingCurrency.Get();
	
	Items.FixedCostRatesSum.Title = StringFunctionsClientServer.SubstituteParametersToString(
		AmountHeaderText, Currency);
	Items.VariableCostRatesSum.Title = StringFunctionsClientServer.SubstituteParametersToString(
		AmountHeaderText, Currency);
	Items.FixedCostRatesStandardGroup.Title = StringFunctionsClientServer.SubstituteParametersToString(
		StandardHeaderText, Currency);
	Items.VariableCostRatesGroupStandard.Title = StringFunctionsClientServer.SubstituteParametersToString(
		StandardHeaderText, Currency);

EndProcedure

&AtServer
Procedure FillRuleSelectionList()
	
	ChoiceList = Items.AllocationBaseValuesRulePresentation.ChoiceList;
	ChoiceList.Clear();
	
	SimpleRules = SimpleDistributionRules();
	For Each Rule In SimpleRules Do
		ChoiceList.Add(Rule.Value, Rule.Presentation);
	EndDo;
	
	ChoiceList.Add("OtherRules", 
		New FormattedString(NStr("vi = 'Các quy tắc khác ...';
								|ru = 'Другие правила...';
								|en = 'Other rules...'; fa = 'Other rules...';
								|it = 'Altre regole...';
								|pl = 'Inne zasady...';
								|tr = 'Diğer kurallar...'"),,,, "stub"));
	
EndProcedure

&AtClientAtServerNoContext
Function SimpleDistributionRules()
	
	RulesList = New ValueList;
	RulesList.Add("TotalPayrollExpenses", NStr("vi = 'Số lượng chi phí lao động';
												|ru = 'Сумма расходов на оплату труда';
												|en = 'Total payroll expenses'; fa = 'کل هزینه‌های حقوق و دستمزد';
												|it = 'L''importo di spese dei costi di manodopera';
												|pl = 'Wydatki na pensje';
												|tr = 'İşçilik ücretlerine ilişkin giderler tutarı'"));
	RulesList.Add("MaterialCostsAmount", NStr("vi = 'Số lượng chi phí vật liệu';
												|ru = 'Сумма материальных затрат';
												|en = 'Material cost amount'; fa = 'Material cost amount';
												|it = 'Costo delle spese materiali';
												|pl = 'Wartość nakładów materiałowych';
												|tr = 'Malzeme giderlerinin tutarı'"));
	RulesList.Add("AmountOfMaterialAndLaborCosts", NStr("vi = 'Số tiền nguyên vật liệu và chi phí nhân công';
														|ru = 'Сумма материальных и трудозатрат';
														|en = 'Amount of material and labor costs'; fa = 'مبلغ هزینه‌های مواد و دستمزد';
														|it = 'La quantità di materiale e costi di manodopera';
														|pl = 'Wartość materiałów i koszty pracy';
														|tr = 'Malzeme ve iş gücü maliyetlerinin tutarı'"));
	RulesList.Add("TargetProductCost", NStr("vi = 'Chi phí sản xuất theo kế hoạch';
											|ru = 'Плановая стоимость продукции';
											|en = 'Standard product cost'; fa = 'بهای استاندارد محصول';
											|it = 'Costo pianificato dei prodotti';
											|pl = 'Wartość zaplanowana produkcji';
											|tr = 'İmal edilen ürünlerin standart maliyeti'"));
	RulesList.Add("StandardRemunerationLevel", NStr("vi = 'Chi phí lao động theo quy định';
													|ru = 'Нормативные расходы на оплату труда';
													|en = 'Standard payroll expenses'; fa = 'Standard payroll expenses';
													|it = 'Costi regolatori del lavoro';
													|pl = 'Wydatki normatywne na pensje';
													|tr = 'İşçilik ücretlerine ilişkin standart giderler'"));
	
	RulesList.Add("NumberOfWorksOfSpecifiedKinds", NStr("vi = 'Số lượng công trình';
														|ru = 'Количество работ';
														|en = 'Number of works'; fa = 'تعداد کارها';
														|it = 'Numero lavori';
														|pl = 'Ilość prac';
														|tr = 'İş miktarı'"));
	RulesList.Add("QuantityOfSpecifiedMaterials", NStr("vi = 'Số lượng nguyên vật liệu';
														|ru = 'Количество материалов';
														|en = 'Quantity of materials'; fa = 'مقدار مواد';
														|it = 'Quantità di materiali';
														|pl = 'Ilość materiałów';
														|tr = 'Malzeme miktarı'"));
	RulesList.Add("WeightOfSpecifiedMaterials", NStr("vi = 'Trọng lượng nguyên vật liệu';
													|ru = 'Вес материалов';
													|en = 'Weight of materials'; fa = 'وزن مواد';
													|it = 'Peso dei materiali';
													|pl = 'Waga materiałów';
													|tr = 'Malzeme ağırlığı'"));
	RulesList.Add("VolumeOfSpecifiedMaterials", NStr("vi = 'Khối lượng nguyên vật liệu';
													|ru = 'Объем материалов';
													|en = 'Material volume'; fa = 'حجم مواد';
													|it = 'Volume dei materiali';
													|pl = 'Wielkość materiałów';
													|tr = 'Malzeme hacmi'"));
	
	RulesList.Add("ProductsQuantity", NStr("vi = 'Số lượng sản phẩm';
											|ru = 'Количество продукции';
											|en = 'Product quantity'; fa = 'مقدار محصول';
											|it = 'Numero dei prodotti';
											|pl = 'Ilość produkcji';
											|tr = 'İmal edilen ürün miktarı'"));
	RulesList.Add("ProductsWeight", NStr("vi = 'Trọng lượng sản phẩm';
										|ru = 'Вес продукции';
										|en = 'Product weight'; fa = 'وزن محصول';
										|it = 'Peso dei prodotti';
										|pl = 'Waga produkcji';
										|tr = 'İmal edilen ürün ağırlığı'"));
	RulesList.Add("ProductsVolume", NStr("vi = 'Khối lương sản phẩm';
										|ru = 'Объем продукции';
										|en = 'Product volume'; fa = 'حجم محصول';
										|it = 'Volume dei prodotti';
										|pl = 'Objętość produkcji';
										|tr = 'İmal edilen ürün hacmi'"));
	
	Return RulesList;
	
EndFunction

&AtServer
Procedure WhenExpenseItemChangesServer(Source)
	
	If Source = "VariableCostRates" Then
		FormItem = Items.VariableCostRates;
	Else
		FormItem = Items.FixedCostRates;
	EndIf;
			
	CurrentRow = Object[Source].FindByID(FormItem.CurrentRow);
	FillInAccordingToDistributionDatabase(CurrentRow, Source);
	CalculateStandardAndMultiplicity(CurrentRow);
	
	CurrentRow.ProductCostElement = Common.ObjectAttributeValue(
		CurrentRow.ExpenseItem, "ProductCostElement");
	
EndProcedure

&AtServer
Procedure FillInAccordingToDistributionDatabase(FillString, Source)
	
	If TypeOf(FillString) = Type("Number") Then
		ExpenseLine = Object[Source].FindByID(FillString);
	Else
		ExpenseLine = FillString;
	EndIf;
	
	DatabaseData = New Structure;
	DatabaseData.Insert("AllocatedAccordingToRule", Undefined);
	DatabaseData.Insert("Value_", 0);
	DatabaseData.Insert("RulePresentation", "");
	DatabaseData.Insert("RuleDescription", "");
	DatabaseData.Insert("UnitOfMeasure", "");
	DatabaseData.Insert("ValueRepresentation_3", "");
	
	If Not ValueIsFilled(ExpenseLine.ExpenseItem) Then
		
		FillPropertyValues(ExpenseLine, DatabaseData);
		Return;
		
	EndIf;
	
	AllocatedAccordingToRule = RuleForAllocationOfExpenditureItems(
		Object.Organization, Object.Department, ExpenseLine.ExpenseItem, Object.Date);
	
	If Not ValueIsFilled(AllocatedAccordingToRule) Then
		
		FillPropertyValues(ExpenseLine, DatabaseData);
		Return;
		
	EndIf;
	
	RowsWithBase = Object.AllocationBaseValues.FindRows(
		New Structure("AllocatedAccordingToRule", AllocatedAccordingToRule));
	
	If RowsWithBase.Count() = 0 Then
		
		If Source = "FixedCostRates" Then
			DatabaseData = Object.AllocationBaseValues.Add();
		EndIf;
		
		DatabaseData.AllocatedAccordingToRule = AllocatedAccordingToRule;
		FillInDependentDetailsOfDistributionBasesInLine(DatabaseData);
		
	Else
		DatabaseData = RowsWithBase[0];
	EndIf;
	
	FillPropertyValues(ExpenseLine, DatabaseData);
	
EndProcedure

&AtServer
Procedure FillInDependentDetailsOfDistributionBasesInLine(FillString, DatabasePresentations = Undefined)
	
	If TypeOf(FillString) = Type("Number") Then
		// The row ID was passed.
		StringWithBase = Object.AllocationBaseValues.FindByID(FillString);
	Else
		StringWithBase = FillString;
	EndIf;
	
	If TypeOf(StringWithBase.AllocatedAccordingToRule) = Type("EnumRef.TypesOfCostAllocatingBase") Then
		
		AllocationBaseType = StringWithBase.AllocatedAccordingToRule;
		
		If DatabasePresentations = Undefined Then
			RulePresentation = PresentationsOfSimpleDatabases()[StringWithBase.AllocatedAccordingToRule];
		Else
			RulePresentation = DatabasePresentations[StringWithBase.AllocatedAccordingToRule];
		EndIf;
		
		StringWithBase.RuleDescription = RulePresentation.Presentation;
		StringWithBase.RulePresentation = RulePresentation.Value;
		
	Else
		
		AllocationBaseType = Common.ObjectAttributeValue(StringWithBase.AllocatedAccordingToRule, "BaseOfAllocationByLots");
		
		StringWithBase.RuleDescription = RuleDescription(StringWithBase.AllocatedAccordingToRule);
		StringWithBase.RulePresentation = "AllocatedAccordingToRule";
		
	EndIf;
	
	StringWithBase.UnitOfMeasure = UnitOfMeasurementRules(AllocationBaseType);
	
	FillInValuePresentation(StringWithBase);
		
EndProcedure

&AtClient
Procedure RecalculateExpenses(TableOfCalculation, AllocatedAccordingToRule, NewBase)
	
	FilterByRule = New Structure;
	FilterByRule.Insert("AllocatedAccordingToRule", AllocatedAccordingToRule);
	
	Expenses = Object[TableOfCalculation].FindRows(FilterByRule);
	
	For Each Expense In Expenses Do
		
		Expense.Value_ = NewBase;
		
		FillInValuePresentation(Expense);
		CalculateStandardAndMultiplicity(Expense);
		
	EndDo;
	
EndProcedure

&AtClientAtServerNoContext
Procedure FillInValuePresentation(FillString)
	
	If TypeOf(FillString.UnitOfMeasure) = Type("String") 
		Or TypeOf(FillString.UnitOfMeasure) = Type("CatalogRef.Currencies") Then
		FillString.ValueRepresentation_3 = Format(FillString.Value_, "NFD=2; NZ=") + " " + FillString.UnitOfMeasure;
	Else
		FillString.ValueRepresentation_3 = Format(FillString.Value_, "NFD=3; NZ=") + " " + FillString.UnitOfMeasure;
	EndIf;	
	
EndProcedure

&AtClientAtServerNoContext
Procedure CalculateStandardAndMultiplicity(FillString)
	
	If FillString.Value_ = 0 Or FillString.Sum = 0 Then
		
		FillString.Repetition = 1;
		FillInMultiplicityPresentation(FillString);
		
		Return;
		
	EndIf;
	
	NormativeStandard = Round(FillString.Sum / FillString.Value_, 6);
	Repetition = 1;
	
	While Not (Round(NormativeStandard, 2) - NormativeStandard) = 0 And Int(NormativeStandard) < 1 Do
		
		NormativeStandard = NormativeStandard * 10;
		Repetition = Repetition * 10;
		
	EndDo;
	
	FillString.NormativeStandard = NormativeStandard;
	FillString.Repetition = Repetition;
	
	FillInMultiplicityPresentation(FillString);
	
EndProcedure

&AtClientAtServerNoContext
Procedure FillInMultiplicityPresentation(FillString)
	
	FillString.PresentationOfMultiplier = Format(FillString.Repetition) + " " + FillString.UnitOfMeasure;
	
EndProcedure

&AtClient
Procedure SetBaseValue(Source)
	
	CurrentData = Items[Source].CurrentData;
	
	RowsWithBase = Object.AllocationBaseValues.FindRows(
		New Structure("AllocatedAccordingToRule", CurrentData.AllocatedAccordingToRule));
		
	If RowsWithBase.Count() > 0 Then
		
		RowsWithBase[0].Value_ = CurrentData.Value_;
		FillInValuePresentation(RowsWithBase[0]);
		
	Else
		
		// For variable expenses, the base is not automatically added.
		If CurrentData.Value_ = 0 Then
			Return;
		EndIf;
		
		// The database is specified forcibly.
		DatabaseData = Object.AllocationBaseValues.Add();
		DatabaseData.AllocatedAccordingToRule = CurrentData.AllocatedAccordingToRule;
		DatabaseData.Value_ = CurrentData.Value_;
		FillInDependentDetailsOfDistributionBasesInLine(DatabaseData.GetID());
		
	EndIf;
	
	RecalculateExpenses("VariableCostRates", CurrentData.AllocatedAccordingToRule, CurrentData.Value_);
	RecalculateExpenses("FixedCostRates", CurrentData.AllocatedAccordingToRule, CurrentData.Value_);
	
EndProcedure

&AtServerNoContext
Function RuleForAllocationOfExpenditureItems(Organization, Department, ExpenseItem, Period)
	
	BasesWithFutureReleasesInMind = New Map;
	BasesWithFutureReleasesInMind.Insert(Enums.TypesOfCostAllocatingBase.ProductsQuantityConsideringFutureReleases,
		Enums.TypesOfCostAllocatingBase.ProductsQuantity);
	BasesWithFutureReleasesInMind.Insert(Enums.TypesOfCostAllocatingBase.ProductsWeightConsideringFutureReleases,
		Enums.TypesOfCostAllocatingBase.ProductsWeight);
	BasesWithFutureReleasesInMind.Insert(Enums.TypesOfCostAllocatingBase.ProductsVolumeConsideringFutureReleases,
		Enums.TypesOfCostAllocatingBase.ProductsVolume);
	BasesWithFutureReleasesInMind.Insert(Enums.TypesOfCostAllocatingBase.TargetProductCostConsideringFutureReleases,
		Enums.TypesOfCostAllocatingBase.TargetProductCost);
		
	FlowDescription = New Structure;
	FlowDescription.Insert("Organization", Organization);
	FlowDescription.Insert("Department", Department);
	FlowDescription.Insert("ExpenseItem", ExpenseItem);
	
	ListOfExpenses = New Array;
	ListOfExpenses.Add(FlowDescription);
	
	If Not ValueIsFilled(Period) Then
		Period = EndOfMonth(CurrentSessionDate());
	EndIf;
	
	DistributionSettings = Documents.AllocationOfOtherCosts.GetCostItemAllocationSettings(ListOfExpenses, Organization, EndOfMonth(Period));
	If Not DistributionSettings.Count() Then
		Return Enums.TypesOfCostAllocatingBase.EmptyRef();
	EndIf;
	AllocatedAccordingToRule = DistributionSettings[0].ManDistributionRule;
	
	If Not ValueIsFilled(AllocatedAccordingToRule) Then
		Return AllocatedAccordingToRule;
	EndIf;
	
	RuleDetails = Common.ObjectAttributesValues(AllocatedAccordingToRule,
		"BaseOfAllocationByLots, SettingsOfBaseOfAllocationByLotsChanged");
	
	If Not RuleDetails.SettingsOfBaseOfAllocationByLotsChanged Then
		If Not BasesWithFutureReleasesInMind.Get(RuleDetails.BaseOfAllocationByLots) = Undefined Then
			AllocatedAccordingToRule = BasesWithFutureReleasesInMind.Get(RuleDetails.BaseOfAllocationByLots);
		Else
			AllocatedAccordingToRule = RuleDetails.BaseOfAllocationByLots;
		EndIf;
	EndIf;	
	
	Return AllocatedAccordingToRule;
	
EndFunction

&AtServerNoContext
Function RuleDescription(Rule)
	
	If Not TypeOf(Rule) = Type("CatalogRef.CostAllocationRules") Then
		Return "";
	EndIf;
	
	Return TrimAll(Common.ObjectAttributeValue(Rule, "RulePresentation"));

EndFunction

&AtServerNoContext
Function UnitOfMeasurementRules(AllocationBaseType)
	
	UnitOfMeasure = "";
	If AllocationBaseType = Enums.TypesOfCostAllocatingBase.NumberOfWorksOfSpecifiedKinds
		Or AllocationBaseType = Enums.TypesOfCostAllocatingBase.QuantityOfSpecifiedMaterials 
		Or AllocationBaseType = Enums.TypesOfCostAllocatingBase.ProductsQuantity Then
		UnitOfMeasure = Constants.UnitOfMeasureOfQuantity.Get();
	ElsIf AllocationBaseType = Enums.TypesOfCostAllocatingBase.WeightOfSpecifiedMaterials Then
		UnitOfMeasure = Constants.UnitOfMeasureForWeight.Get();
	ElsIf AllocationBaseType = Enums.TypesOfCostAllocatingBase.ProductsWeight Then
		UnitOfMeasure = Constants.UnitOfMeasureForWeight.Get();
		
	ElsIf AllocationBaseType = Enums.TypesOfCostAllocatingBase.VolumeOfSpecifiedMaterials Then
		UnitOfMeasure = Constants.UnitOfMeasureForVolume.Get();
	ElsIf AllocationBaseType = Enums.TypesOfCostAllocatingBase.ProductsVolume Then
		UnitOfMeasure = Constants.UnitOfMeasureForVolume.Get();
	ElsIf AllocationBaseType = Enums.TypesOfCostAllocatingBase.StandardRemunerationLevel
		Or AllocationBaseType = Enums.TypesOfCostAllocatingBase.TargetProductCost
		Or AllocationBaseType = Enums.TypesOfCostAllocatingBase.TotalPayrollExpenses
		Or AllocationBaseType = Enums.TypesOfCostAllocatingBase.MaterialCostsAmount
		Or AllocationBaseType = Enums.TypesOfCostAllocatingBase.AmountOfMaterialAndLaborCosts Then
		UnitOfMeasure = Constants.ManagementAccountingCurrency.Get();
	EndIf;
	
	Return UnitOfMeasure;
	
EndFunction

&AtClientAtServerNoContext
Function PresentationsOfSimpleDatabases()
	
	DatabasePresentations = New Map;
	SimpleRules = SimpleDistributionRules();
	For Each Rule In SimpleRules Do
		
		InfobaseType = "Enum.TypesOfCostAllocatingBase." + Rule.Value;
		DatabasePresentations.Insert(PredefinedValue(InfobaseType), Rule);
		
	EndDo;	
	
	Return DatabasePresentations;
	
EndFunction

&AtClient
Procedure SetDateIntervalCompletion(Period, AdditionalParameters) Export
	
	Dialog = AdditionalParameters.Dialog; // StandardPeriodEditDialog
	
	If Period <> Undefined Then
		
		Object.ValidityStartDate    = Dialog.Period.StartDate;
		Object.ValidityEndDate = Dialog.Period.EndDate;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure InsertNewItemInSelectionList(AllocatedAccordingToRule, RuleDescription)
	
	ChoiceList = Items.AllocationBaseValuesRulePresentation.ChoiceList;
	ItemToAdd = ChoiceList.FindByValue("AllocatedAccordingToRule");
	
	If Not ItemToAdd = Undefined Then
		ChoiceList.Delete(ItemToAdd);
	EndIf;
	
	If TypeOf(AllocatedAccordingToRule) = Type("CatalogRef.CostAllocationRules")
		And ValueIsFilled(AllocatedAccordingToRule) Then
		ChoiceList.Insert(12, "AllocatedAccordingToRule", RuleDescription);
	EndIf;
	
EndProcedure

&AtClient
Function ParametersForDeletingNorms(RowsIDs)

	AllocationRulesForDeletion = New Array;
	For Each LineID In RowsIDs Do
		AllocationRulesForDeletion.Add(Object.AllocationBaseValues.FindByID(LineID).AllocatedAccordingToRule);
	EndDo;
	
	ParametersForDeletingArticles = New Structure;
	ParametersForDeletingArticles.Insert("Constant", New Array);
	ParametersForDeletingArticles.Insert("ThereAreLinesToDelete", False);
	
	For Each ConstantConsumption In Object.FixedCostRates Do
		
		If AllocationRulesForDeletion.Find(ConstantConsumption.AllocatedAccordingToRule) = Undefined Then
			Continue;
		EndIf;
		
		ParametersForDeletingArticles.Constant.Add(ConstantConsumption.GetID());
		
	EndDo;
	
	ParametersForDeletingArticles.ThereAreLinesToDelete = ParametersForDeletingArticles.Constant.Count() > 0;
	
	Return ParametersForDeletingArticles;
	
EndFunction

&AtClient
Procedure DeleteRowsWithRule(DeletionParameters)
	
	For Each LineID In DeletionParameters.Constant Do
		Object.FixedCostRates.Delete(Object.FixedCostRates.FindByID(LineID));
	EndDo;
	
EndProcedure

&AtClient
Procedure AllocationBaseValuesOnEditEndCompletion(Result, AdditionalParameters) Export
	
	If Not Result = DialogReturnCode.Yes Then
		
		AdditionalParameters.CurrentData.AllocatedAccordingToRule = AdditionalParameters.RuleToDelete;
		FillInDependentDetailsOfDistributionBasesInLine(AdditionalParameters.CurrentData.GetID());
		
		Return;
		
	EndIf;
	
	DeleteRowsWithRule(AdditionalParameters.DeletionParameters);
	
EndProcedure

&AtClient
Procedure AllocationBaseValuesBeforeDeleteRowCompletion(Result, AdditionalParameters) Export
	
	If Not Result = DialogReturnCode.Yes Then
		Return;
	EndIf;
	
	DeleteRowsWithRule(AdditionalParameters.DeletionParameters);
	For Each LineID In AdditionalParameters.IDOfValueRows Do
		Object.AllocationBaseValues.Delete(Object.AllocationBaseValues.FindByID(LineID));
	EndDo;
	
	Modified = True;
	
EndProcedure

&AtClient
Procedure AskUserQuestion(ObjectToFillIn_, SpecifyNumberOfMonths = False)
	
	NotificationText1 = "";
	If ObjectToFillIn_ = "FixedCosts" And Object.FixedCostRates.Count() > 0 Then
		NotificationText1 = NStr("vi = 'Phần bảng ""Chi phí cố định"" sẽ bị xóa. Tiếp tục?';
								|ru = 'Табличная часть ""Постоянные расходы"" будет очищена. Продолжить?';
								|en = 'The Fixed costs table will be cleared. Do you want to continue?'; fa = 'The Fixed costs table will be cleared. Do you want to continue?';
								|it = 'La parte tabulare di ""Costi fissi"" verrà eliminata. Continuare?';
								|pl = 'Część tabelaryczna ""Koszty stałe"" zostanie wyczyszczona. Kontynuować?';
								|tr = '""Sabit Giderler"" tablo bölümü temizlenecektir. Devam edilsin mi?'");
	ElsIf ObjectToFillIn_ = "VariableCosts" And Object.VariableCostRates.Count() > 0 Then
		NotificationText1 = NStr("vi = 'Bảng chi phí biến đổi sẽ bị xóa. Tiếp tục?';
								|ru = 'Табличная часть ""Переменные расходы"" будет очищена. Продолжить?';
								|en = 'The Variable costs table will be cleared. Do you want to continue?'; fa = 'The Variable costs table will be cleared. Do you want to continue?';
								|it = 'La parte tabulare di ""Costi variabili"" verrà eliminata. Continuare?';
								|pl = 'Część tabelaryczna ""Koszty zmienne"" zostanie wyczyszczona. Kontynuować?';
								|tr = '""Değişken Giderler"" tablo bölümü temizlenecektir. Devam edilsin mi?'");
	ElsIf Object.FixedCostRates.Count() > 0 Or Object.VariableCostRates.Count() > 0 Then
			NotificationText1 = NStr("vi = 'Các phần của bảng Chi phí biến đổi và chi phí cố định sẽ bị xóa. Tiếp tục?';
									|ru = 'Табличные части ""Переменные расходы"" и ""Постоянные расходы"" будут очищены. Продолжить?';
									|en = 'Tables ""Variable costs"" and ""Fixed costs"" will be cleared. Continue?'; fa = 'Tables ""Variable costs"" and ""Fixed costs"" will be cleared. Continue?';
									|it = 'Le parti tabulari ""Costi variabili"" e ""Costi fissi"" verranno eliminate. Continuare?';
									|pl = 'Części tabelaryczne ""Koszty zmienne"" i ""Koszty stałe"" zostaną wyczyszczone.';
									|tr = '""Değişken Giderler"" ve ""Sabit Giderler"" tablo bölümleri temizlenecektir. Devam edilsin mi?'");
	EndIf;
	
	If Not IsBlankString(NotificationText1) Then
		
		AdditionalParameters = New Structure;
		AdditionalParameters.Insert("ObjectToFillIn_", ObjectToFillIn_);
		AdditionalParameters.Insert("SpecifyNumberOfMonths", SpecifyNumberOfMonths);
		
		CallbackDescription = New CallbackDescription("AskUserQuestionCompletion", 
			ThisObject, 
			AdditionalParameters);
		
		ShowQueryBox(CallbackDescription, NotificationText1, QuestionDialogMode.YesNo, , DialogReturnCode.No);
		
		Return;
		
	EndIf;
	
	DefineFillParameters(ObjectToFillIn_, SpecifyNumberOfMonths);
	
EndProcedure

&AtClient
Procedure AskUserQuestionCompletion(Result, AdditionalParameters) Export
	
	If Not Result = DialogReturnCode.Yes Then
		Return;
	EndIf;
	
	If AdditionalParameters.ObjectToFillIn_ = "All" Then
		
		Object.VariableCostRates.Clear();
		Object.FixedCostRates.Clear();
		
	ElsIf AdditionalParameters.ObjectToFillIn_ = "VariableCosts" Then
		Object.VariableCostRates.Clear();
	Else
		Object.FixedCostRates.Clear();
	EndIf;
	
	DefineFillParameters(AdditionalParameters.ObjectToFillIn_, AdditionalParameters.SpecifyNumberOfMonths);
	
EndProcedure

&AtClient
Procedure DefineFillParameters(ObjectToFillIn_, SpecifyNumberOfMonths)
	
	If SpecifyNumberOfMonths Then
		
		AdditionalParameters = New Structure;
		AdditionalParameters.Insert("ObjectToFillIn_", ObjectToFillIn_);
		
		CallbackDescription = New CallbackDescription("DefineFillParametersBestiality", ThisObject, AdditionalParameters);
		OpenForm("Document.SetProductionExpenseStandards.Form.SettingsFormOfPeriod",,,,,, 
			CallbackDescription, FormWindowOpeningMode.LockOwnerWindow);
			
		Return;
		
	EndIf;
	
	FillAtServer(ObjectToFillIn_, 1);
	
EndProcedure

&AtClient
Procedure DefineFillParametersBestiality(ClosingResult, AdditionalParameters) Export
	
	If Not ValueIsFilled(ClosingResult) Then
		
		ErrorText = NStr("vi = 'Số tháng phải nhận chi phí không được chỉ định. Điền là không thể.';
						|ru = 'Не указано количество месяцев за которое необходимо получить расходы. Заполнение невозможно.';
						|en = 'Specify the number of months to receive expenses for.'; fa = 'Specify the number of months to receive expenses for.';
						|it = 'Non è indicato il numero di mesi per i quali è necessario ricevere le spese. Non è possibile compilare tali campi.';
						|pl = 'Nie określono liczby miesięcy, za które należy uzyskać koszty. Wypełnianie nie jest możliwe.';
						|tr = 'Giderlerin alınması gereken ay sayısı belirtilmedi. Doldurulması mümkün değildir.'");
		CommonClientServer.MessageToUser(ErrorText);
		
		Return;
		
	EndIf;
	
	FillAtServer(AdditionalParameters.ObjectToFillIn_, ClosingResult);
	
EndProcedure

&AtServer
Procedure FillAtServer(FillInObjects, NumberOfMonths)
	
	Query = New Query;
	Query.Text = 
		"SELECT
		|	OtherExpensesTurnover.ExpenseItem AS ExpenseItem,
		|	OtherExpensesTurnover.CostReceipt AS SumReceipt,
		|	OtherExpensesTurnover.ExpenseItem.ProductCostElement AS ProductCostElement,
		|	OtherExpensesTurnover.Period AS Period
		|INTO OtherExpensesByPeriod
		|FROM
		|	AccumulationRegister.OtherWorkInProgressExpenses.Turnovers(
		|			&BeginOfPeriod,
		|			&PeriodEnding,
		|			Month,
		|			Organization = &Organization
		|				AND Department = &Department
		|				AND (ExpenseItem.CostAllocationOptionManag = VALUE(Enum.CostAllocationOptions.ToProductionCosts)
		|					OR ExpenseItem.CostAllocationOptionLocal = VALUE(Enum.CostAllocationOptions.ToProductionCosts))
		|				AND &ArticleSelectionCondition) AS OtherExpensesTurnover
		|
		|INDEX BY
		|	Period,
		|	ExpenseItem
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	MAX(OtherExpensesByPeriod.Period) AS Period,
		|	OtherExpensesByPeriod.ExpenseItem AS ExpenseItem
		|INTO MaximumPeriodsOfOccurrenceOfExpenses
		|FROM
		|	OtherExpensesByPeriod AS OtherExpensesByPeriod
		|
		|GROUP BY
		|	OtherExpensesByPeriod.ExpenseItem
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	OtherExpensesByPeriod.ExpenseItem AS ExpenseItem,
		|	OtherExpensesByPeriod.SumReceipt AS Sum,
		|	OtherExpensesByPeriod.ProductCostElement AS ProductCostElement,
		|	OtherExpensesByPeriod.ExpenseItem.ProductionCostType AS NatureCosts
		|FROM
		|	MaximumPeriodsOfOccurrenceOfExpenses AS MaximumPeriodsOfOccurrenceOfExpenses
		|		INNER JOIN OtherExpensesByPeriod AS OtherExpensesByPeriod
		|		ON MaximumPeriodsOfOccurrenceOfExpenses.Period = OtherExpensesByPeriod.Period
		|			AND MaximumPeriodsOfOccurrenceOfExpenses.ExpenseItem = OtherExpensesByPeriod.ExpenseItem
		|TOTALS BY
		|	NatureCosts";
	
	Query.SetParameter("BeginOfPeriod", AddMonth(Object.ValidityStartDate, -NumberOfMonths));
	Query.SetParameter("PeriodEnding", EndOfMonth(Object.ValidityStartDate));
	Query.SetParameter("Organization", Object.Organization);
	Query.SetParameter("Department", Object.Department);
	
	If FillInObjects = "FixedCosts" Then
		Query.Text = StrReplace(Query.Text, 
			"&ArticleSelectionCondition", 
			"ExpenseItem.ProductionCostType = VALUE(Enum.ProductionCostType.Constant)");
	ElsIf FillInObjects = "VariableCosts" Then
		Query.Text = StrReplace(Query.Text, 
			"&ArticleSelectionCondition", 
			"ExpenseItem.ProductionCostType = VALUE(Enum.ProductionCostType.Variables1)");
	Else
		Query.Text = StrReplace(Query.Text, 
			"&ArticleSelectionCondition", 
			"TRUE");
	EndIf;
	
	Result = Query.Execute();
	SamplingByNatureCosts = Result.Select(QueryResultIteration.ByGroups);
	
	While SamplingByNatureCosts.Next() Do
		
		If SamplingByNatureCosts.NatureCosts = Enums.ProductionCostType.Constant Then
			TableName = "FixedCostRates";
		Else
			TableName = "VariableCostRates";			
		EndIf;
		
		DetailedSampling = SamplingByNatureCosts.Select();
		While DetailedSampling.Next() Do
			
			NewExpense = Object[TableName].Add();
			FillPropertyValues(NewExpense, DetailedSampling);
			FillInAccordingToDistributionDatabase(NewExpense, TableName);
			
			If Not ValueIsFilled(NewExpense.AllocatedAccordingToRule) Then
				
				Object[TableName].Delete(NewExpense);
				Continue;
				
			EndIf;
			
			CalculateStandardAndMultiplicity(NewExpense);
			
		EndDo;
	
	EndDo;
	
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
	If Item.Name = "sh_ShamsiInput_ValidityStartDate" Then
		ValidityStartDateOnChange(Items.ValidityStartDate);
	ElsIf Item.Name = "sh_ShamsiInput_ValidityEndDate" Then
		ValidityEndDateOnChange(Items.ValidityEndDate);
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
