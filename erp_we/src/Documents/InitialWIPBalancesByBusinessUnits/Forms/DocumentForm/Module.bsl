#Region Variables

&AtClient
Var CachedValues; //used by the mechanism for processing changes in PM details

#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetConditionalAppearance(); 
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	ItemsAndDimensionsSelectionParameters = Documents.InitialWIPBalancesByBusinessUnits.ItemsAndDimensionsSelectionParameters();
	IncomeAndExpensesServer.OnCreateAtServer(ThisObject, ItemsAndDimensionsSelectionParameters);
	
	If Not ValueIsFilled(Object.Ref) Then
		OnReadCreateAtServer();
	EndIf;
	
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	
	// StandardSubsystems.Properties
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("Object", Object);
	AdditionalParameters.Insert("ItemForPlacementName", "GroupAdditionalAttributes");
	AdditionalParameters.Insert("DeferredInitialization", True);
	PropertyManager.OnCreateAtServer(ThisForm, AdditionalParameters);
	// End StandardSubsystems.Properties
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	// StandardSubsystems.ObjectsVersioning
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.ObjectsVersioning
	
	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)
	
	ItemsAndDimensionsSelectionParameters = Documents.InitialWIPBalancesByBusinessUnits.ItemsAndDimensionsSelectionParameters();
	IncomeAndExpensesServer.OnReadAtServer(ThisObject, ItemsAndDimensionsSelectionParameters);
	
	OnReadCreateAtServer();
	
	FormEvents.OnReadAtServer(ThisObject, CurrentObject);
	
	// StandardSubsystems.PeriodClosingDates
	PeriodClosingDates.ObjectOnReadAtServer(ThisForm, CurrentObject);
	// End StandardSubsystems.PeriodClosingDates
	
	// StandardSubsystems.Properties
	PropertyManager.OnReadAtServer(ThisForm, CurrentObject);
	// End StandardSubsystems.Properties
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	// End StandardSubsystems.AttachableCommands
	
	// StandardSubsystems.AccessManagement
	AccessManagement.OnReadAtServer(ThisForm, CurrentObject);
	// End StandardSubsystems.AccessManagement
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	// StandardSubsystems.Properties
	PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
	// End StandardSubsystems.Properties
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	
	// StandardSubsystems.Properties
	PropertyManager.FillCheckProcessing(ThisForm, Cancel, CheckedAttributes);
	// End StandardSubsystems.Properties
	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	// StandardSubsystems.Properties
	PropertyManager.BeforeWriteAtServer(ThisForm, CurrentObject);
	// End StandardSubsystems.Properties
	
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.AfterWrite(ThisForm, Object, WriteParameters);
	// End StandardSubsystems.AttachableCommands
	
	// Standard subsystems.Modificationconfiguration
	ConfigurationModificationClientOverridable.AfterWrite(ThisForm, WriteParameters);
	// The end of the standard subsystem.Modificationconfiguration
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)

	// StandardSubsystems.AccessManagement
	AccessManagement.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	// End StandardSubsystems.AccessManagement
	
	IncomeAndExpensesServer.AfterWriteAtServer(ThisObject);
	FillInServiceDetailsOfForm();
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	// StandardSubsystems.Properties
	If PropertyManagerClient.ProcessNotifications(ThisForm, EventName, Parameter) Then
		UpdateAdditionalAttributesItems();
		PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
	EndIf;
	// End StandardSubsystems.Properties
	
	FormEventsClient.NotificationProcessing(ThisObject, EventName, Parameter, Source);
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure DateOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	
	SetVisibility1();
	
EndProcedure

&AtClient
Procedure OrganizationOnChange(Item)
	
	OrganizationWhenChangedOnServer();
	
EndProcedure

&AtServer
Procedure OrganizationWhenChangedOnServer()
	
	FillInLocalAccountingCurrency();
	
	SetVisibility1();
	SetHeaders();
	
EndProcedure

&AtClient
Procedure GroupPagesOnCurrentPageChange(Item, CurrentPage)
	
	// StandardSubsystems.Properties
	If CurrentPage.Name = "GroupPageMore"
		And Not ThisObject.PropertiesParameters.DeferredInitializationExecuted Then
		
		PropertiesExecuteDeferredInitialization();
		PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
	EndIf;
	// End StandardSubsystems.Properties
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersCosts

&AtClient
Procedure CostsOnStartEdit(Item, NewRow, Copy)
	
	CurrentData = Items.Costs.CurrentData;
	
	IncomeAndExpensesClientServer.WhenAddingRowToTable(ThisObject, CurrentData, "Object.Costs");
	
	If NewRow And Not Copy Then
		
		CurrentData.AcceptedByTheKNU = True;
		CurrentData.RuleOfCostAllocatingToProductionLotsMan =
			PredefinedValue("Enum.RulesOfCostAllocationToProductCost.ByMaterialAndLaborCosts");
		CurrentData.RuleOfCostAllocatingToProductionLotsLocal =
			PredefinedValue("Enum.RulesOfCostAllocationToProductCost.ByMaterialAndLaborCosts");
		
	EndIf;
	
	ProcessingOfTabularFormsClient.CacheCurLine(Items.Costs, ThisObject);
	
EndProcedure

&AtClient
Procedure CostsExpenseTypeOnChange(Item)
	
	RowsIDs = New Array;
	RowsIDs.Add(Items.Costs.CurrentRow);
	CostsExpenseTypeOnChangeServer(RowsIDs, CachedValues);
	
EndProcedure

&AtServer
Procedure CostsExpenseTypeOnChangeServer(RowsIDs, CachedValues)
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculatePDAmount", FactorOfConversionFromManCurrencyToRegulCurrency);
	StructureOfActions.Insert("RecalculateAmountTa");
	StructureOfActions.Insert("RecalculateAmountOfTD");
	
	RowsToProcess = New Array();
	
	For Each Id In RowsIDs Do
		
		CurrentData = Object.Costs.FindByID(Id);
		If CurrentData = Undefined Then
			Continue;
		EndIf;
		
		IncomeAndExpensesClientServer.WhenChangingArticleAvailabilityDetailsInLine(
			ThisObject, CurrentData, "Object.Costs");
		
		If Not CurrentData.ExpenseType = PredefinedValue("Enum.CostTypes.Depreciation")
			And Not CurrentData.ExpenseType = PredefinedValue("Enum.CostTypes.Other") Then
			
			CurrentData.ProductCostElement					= Undefined;
			CurrentData.RuleOfCostAllocatingToProductionLotsMan		= Undefined;
			CurrentData.RuleOfCostAllocatingToProductionLotsLocal		= Undefined;
			CurrentData.CostAllocationOptionManag	= Undefined;
			CurrentData.CostAllocationOptionLocal	= Undefined;
			CurrentData.DimensionOfExpensesRequired_		= False;
			CurrentData.DimensionOfExpensesOrderImplementation	= False;
			CurrentData.ArticleType							= 1;
			CurrentData.AcceptedByTheKNU					= True;
			
			RowsToProcess.Add(CurrentData);
			
		EndIf;
		
	EndDo;
	
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		RowsToProcess,
		StructureOfActions,
		Object.Costs,
		CachedValues);
	
EndProcedure

&AtClient
Procedure CostsExpenseItemStartChoice(Item, ChoiceData, StandardProcessing)
	IncomeAndExpensesClient.StartArticleSelection(ThisObject, Item, StandardProcessing);
EndProcedure

&AtClient
Procedure CostsExpenseItemOnChange(Item)
	
	CurrentData = Items.Costs.CurrentData;
	If ValueIsFilled(CurrentData.ExpenseItem) Then
		CostsExpenseItemOnChangeServer(CurrentData.GetID(), CachedValues);
	Else
		
		CurrentData.DimensionOfExpenses = Undefined;
		CurrentData.DimensionOfExpensesRequired_ = False;
		CurrentData.AcceptedByTheKNU = True;
		CurrentData.CostAllocationOptionManag = Undefined;
		CurrentData.CostAllocationOptionLocal = Undefined;
		CurrentData.RuleOfCostAllocatingToProductionLotsMan = Undefined;
		CurrentData.RuleOfCostAllocatingToProductionLotsLocal = Undefined;
		
		StructureOfActions = New Structure;
		StructureOfActions.Insert("RecalculatePDAmount", FactorOfConversionFromManCurrencyToRegulCurrency);
		StructureOfActions.Insert("RecalculateAmountTa");
		StructureOfActions.Insert("RecalculateAmountOfTD");
		BatchProcessingOfTablePartClient.ProcessTSString(CurrentData, StructureOfActions, CachedValues);
		
	EndIf;
	
EndProcedure

&AtServer
Procedure CostsExpenseItemOnChangeServer(CurrentID, CachedValues)
	
	IncomeAndExpensesClientServer.AssetRefOnChange(ThisObject, Items.CostsExpenseItem);
	
	CurrentData = Object.Costs.FindByID(CurrentID);
	
	FillInOptionsForDistributionOfItemsOfExpenditure(CurrentData);
	
	ArticleDetails_1 = New Structure;
	ArticleDetails_1.Insert("ProductCostElement");
	ArticleDetails_1.Insert("BasisOfDistributionByPartyMen", "CostAllocationRuleManag.BaseOfAllocationByLots");
	ArticleDetails_1.Insert("LocalPartyDistributionBase", "CostAllocationRuleLocal.BaseOfAllocationByLots");
	ArticleDetails_1 = Common.ObjectAttributesValues(CurrentData.ExpenseItem, ArticleDetails_1);
	
	RulesOfCostAllocationToProductCost = RulesOfCostAllocationToProductCost();
	
	CurrentData.ProductCostElement		= ArticleDetails_1.ProductCostElement;
	CurrentData.RuleOfCostAllocatingToProductionLotsMan	= RulesOfCostAllocationToProductCost[ArticleDetails_1.BasisOfDistributionByPartyMen];
	CurrentData.RuleOfCostAllocatingToProductionLotsLocal	= RulesOfCostAllocationToProductCost[ArticleDetails_1.LocalPartyDistributionBase];
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInAttributeAcceptedByCNU");
	BatchProcessingOfTablePartServer.ProcessTSString(CurrentData, StructureOfActions, CachedValues);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculatePDAmount", FactorOfConversionFromManCurrencyToRegulCurrency);
	StructureOfActions.Insert("RecalculateAmountTa");
	StructureOfActions.Insert("RecalculateAmountOfTD");
	BatchProcessingOfTablePartServer.ProcessTSString(CurrentData, StructureOfActions, CachedValues);
	
EndProcedure

&AtClient
Procedure CostsDimensionOfExpensesStartChoice(Item, ChoiceData, StandardProcessing)
	
	IncomeAndExpensesClient.StartSelectingExpenseAnalytics(ThisObject, Item, StandardProcessing);
	
EndProcedure

&AtClient
Procedure CostsDimensionOfExpensesAutoComplete(Item, Text, ChoiceData, DataGetParameters, Waiting, StandardProcessing)
	
	IncomeAndExpensesClient.AutoSelectionOfExpenseAnalytics(ThisObject, Item, Text, ChoiceData, DataGetParameters, StandardProcessing);
	
EndProcedure

&AtClient
Procedure CostsDimensionOfExpensesTextEditEnd(Item, Text, ChoiceData, DataGetParameters, StandardProcessing)
	
	IncomeAndExpensesClient.EndOfCostAnalyticsTextEntry(ThisObject, Item, Text, ChoiceData, DataGetParameters, StandardProcessing);
	
EndProcedure

&AtClient
Procedure CostsSumOnChange(Item)
	
	CurrentData = Items.Costs.CurrentData;
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateAmountWithoutVAT");
	StructureOfActions.Insert("RecalculateLocalAmount",	FactorOfConversionFromManCurrencyToRegulCurrency);
	StructureOfActions.Insert("RecalculatePDAmount",	FactorOfConversionFromManCurrencyToRegulCurrency);
	StructureOfActions.Insert("RecalculateAmountTa");
	StructureOfActions.Insert("RecalculateAmountOfTD");
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentData, StructureOfActions, CachedValues);
	
EndProcedure

&AtClient
Procedure CostsSumComplOnChange(Item)
	
	CurrentData = Items.Costs.CurrentData;
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculatePDAmount", FactorOfConversionFromManCurrencyToRegulCurrency);
	StructureOfActions.Insert("RecalculateAmountTa");
	StructureOfActions.Insert("RecalculateAmountOfTD");
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentData, StructureOfActions, CachedValues);
	
EndProcedure

&AtClient
Procedure CostsAmountFAOnChange(Item)
	
	CurrentData = Items.Costs.CurrentData;
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateAmountOfTD");
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentData, StructureOfActions, CachedValues);
	
EndProcedure

&AtClient
Procedure CostsAmountPermanentDifferencesOnChange(Item)
	
	CurrentData = Items.Costs.CurrentData;
	StructureOfActions = New Structure;
	If CurrentData.AcceptedByTheKNU Then
		StructureOfActions.Insert("RecalculateAmountTa");
	EndIf;
	StructureOfActions.Insert("RecalculateAmountOfTD");
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentData, StructureOfActions, CachedValues);
	
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


#Region ObjectCommands_

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

#EndRegion

#Region TSCommands

&AtClient
Procedure FillInTheCostType(Command)
	
	SelectedRows = Items.Costs.SelectedRows;
	
	If SelectedRows.Count() = 0 Then
		WarningText = NStr("vi = 'Cần chọn các dòng để điền kiểu chi phí.';
							|ru = 'Необходимо выбрать строки, для которых необходимо заполнить тип затрат.';
							|en = 'Select lines for which a cost type should be populated.'; fa = 'Select lines for which a cost type should be populated.';
							|it = 'È necessario selezionare le righe per le quali è necessario compilare la regola di allocazione.';
							|pl = 'Konieczne jest wybranie wierszy, dla których konieczne jest wypełnienie typu strat.';
							|tr = 'Gider türünün doldurulması gereken satırlar seçilmeli.'");
		CommonClient.MessageToUser(WarningText);
		Return;
	EndIf;
	
	FormParameters = New Structure;
	FormParameters.Insert("MultipleChoice", False);
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("SelectedRows", SelectedRows);
	
	CallbackDescription = New CallbackDescription("FillInTheCostTypeCompletion", ThisObject, AdditionalParameters);
	
	OpenForm(
		"Enum.CostTypes.ChoiceForm",
		FormParameters,,,,,
		CallbackDescription);
	
	
EndProcedure

&AtClient
Procedure FillInTheCostTypeCompletion(Result, AdditionalParameters) Export
	
	// StandardSubsystems.PerformanceMeasurement
	PerformanceMonitorClient.TimeMeasurement(
		"Document.InitialWIPBalancesByBusinessUnits.Form.DocumentForm.FillInTheCostTypeCompletion");
	// End StandardSubsystems.PerformanceMeasurement
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	FillInTheCostTypeCompletionServer(Result, AdditionalParameters, CachedValues);
	
EndProcedure

&AtServer
Procedure FillInTheCostTypeCompletionServer(Result, AdditionalParameters, CachedValues)

	If Result = Undefined Then
		Return;
	EndIf;
	
	FillInDetailsOfTSServer("ExpenseType", Result, AdditionalParameters);
	CostsExpenseTypeOnChangeServer(AdditionalParameters.SelectedRows, CachedValues);
	
EndProcedure

&AtClient
Procedure FillInTheCostingItem(Command)
	
	SelectedRows = Items.Costs.SelectedRows;
	
	LinesToFillIn_ = New Array;
	For Each RowID In SelectedRows Do
		CurRow = Object.Costs.FindByID(RowID);
		If CurRow.ExpenseType = PredefinedValue("Enum.CostTypes.Depreciation")
			Or CurRow.ExpenseType = PredefinedValue("Enum.CostTypes.Other") Then
			LinesToFillIn_.Add(RowID);
		EndIf;
	EndDo;
	
	If LinesToFillIn_.Count() = 0 Then
		WarningText = NStr("vi = 'Cần chọn các dòng để điền dạng tính giá thành.';
							|ru = 'Необходимо выбрать строки, для которых необходимо заполнить статью калькуляции.';
							|en = 'Select the lines for which it is required to populate the product cost element.'; fa = 'Select the lines for which it is required to populate the product cost element.';
							|it = 'È necessario selezionare le righe per le quali si deve compilare la voce di calcolo.';
							|pl = 'Należy wybrać wiersze, dla których trzeba wypełnić pozycję kalkulacji.';
							|tr = 'Ürün maliyet kalemini doldurmanız gereken satırları seçmeniz gerekmektedir.'");
		CommonClient.MessageToUser(WarningText);
		Return;
	EndIf;
	
	FormParameters = New Structure;
	FormParameters.Insert("MultipleChoice", False);
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("SelectedRows", LinesToFillIn_);
	
	CallbackDescription = New CallbackDescription("FillInTheCostingItemCompletion", ThisObject, AdditionalParameters);
	
	OpenForm(
		"Catalog.ProductCostElements.ChoiceForm",
		FormParameters,,,,,
		CallbackDescription);
	
EndProcedure

&AtClient
Procedure FillInTheCostingItemCompletion(Result, AdditionalParameters) Export
	
	// StandardSubsystems.PerformanceMeasurement
	PerformanceMonitorClient.TimeMeasurement(
		"Document.InitialWIPBalancesByBusinessUnits.Form.DocumentForm.FillInTheCostingItemCompletion");
	// End StandardSubsystems.PerformanceMeasurement
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	FillInDetailsOfTSServer("ProductCostElement", Result, AdditionalParameters);
	
EndProcedure

&AtClient
Procedure FillInTheRuleForAssigningToTheIssueOfUPR(Command)
	
	FillInIssueAssignmentRule("Man");
	
EndProcedure

&AtClient
Procedure FillInTheReglIssueAssignmentRule(Command)
	
	FillInIssueAssignmentRule("Compl");
	
EndProcedure

&AtClient
Procedure FillInIssueAssignmentRule(AccountingKind)
	
	SelectedRows = Items.Costs.SelectedRows;
	
	AvailableOptionsForAssignmentToIssue = New Array;
	AvailableOptionsForAssignmentToIssue.Add(
		PredefinedValue("Enum.CostAllocationOptions.ToProductionCosts"));
	AvailableOptionsForAssignmentToIssue.Add(
		PredefinedValue("Enum.CostAllocationOptions.DoNotAllocate"));
	
	If AccountingKind = "Man" Then
		PropsNameCostAllocationOption = "CostAllocationOptionManag";
		AttributeName = "RuleOfCostAllocatingToProductionLotsMan";
	Else
		PropsNameCostAllocationOption = "CostAllocationOptionLocal";
		AttributeName = "RuleOfCostAllocatingToProductionLotsLocal";
	EndIf;
	
	LinesToFillIn_ = New Array;
	For Each RowID In SelectedRows Do
		
		CurRow = Object.Costs.FindByID(RowID);
		If (CurRow.ExpenseType = PredefinedValue("Enum.CostTypes.Depreciation")
			Or CurRow.ExpenseType = PredefinedValue("Enum.CostTypes.Other"))
			And Not AvailableOptionsForAssignmentToIssue.Find(CurRow[PropsNameCostAllocationOption]) = Undefined Then
			LinesToFillIn_.Add(RowID);
		EndIf;
	EndDo;
	
	If LinesToFillIn_.Count() = 0 Then
		WarningText = NStr("vi = 'Cần chọn các dòng để điền quy tắc phân bổ xuất xưởng.';
							|ru = 'Необходимо выбрать строки, для которых необходимо заполнить правило отнесения на выпуск.';
							|en = 'Select the lines for which it is required to populate the rule of allocating to release.'; fa = 'Select the lines for which it is required to populate the rule of allocating to release.';
							|it = 'È necessario selezionare le linee per le quali è necessario compilare la regola di allocazione.';
							|pl = 'Konieczne jest wybranie wierszy, dla których konieczne jest wypełnienie reguły alokacji do zakończenia produkcji.';
							|tr = 'Üretim için ilişkilendirme kuralının doldurulması gereken satırları seçilmeli.'");
		CommonClient.MessageToUser(WarningText);
		Return;
	EndIf;
	
	FormParameters = New Structure;
	
	RulesArray = New Array;
	RulesArray.Add(PredefinedValue("Enum.RulesOfCostAllocationToProductCost.ByMaterialCosts"));
	RulesArray.Add(PredefinedValue("Enum.RulesOfCostAllocationToProductCost.ByMaterialAndLaborCosts"));
	RulesArray.Add(PredefinedValue("Enum.RulesOfCostAllocationToProductCost.ByLaborCosts"));
	
	FilterStructure1 = New Structure;
	FilterStructure1.Insert("Ref", New FixedArray(RulesArray));
	
	FormParameters.Insert("Filter",				FilterStructure1);
	FormParameters.Insert("MultipleChoice",	False);
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("AttributeName",     AttributeName);
	AdditionalParameters.Insert("SelectedRows", LinesToFillIn_);
	
	CallbackDescription = New CallbackDescription("FillInIssueAssignmentRuleCompletion", ThisObject, AdditionalParameters);
	
	OpenForm(
		"Enum.RulesOfCostAllocationToProductCost.ChoiceForm",
		FormParameters,,,,,
		CallbackDescription);

EndProcedure
	
&AtClient
Procedure FillInIssueAssignmentRuleCompletion(Result, AdditionalParameters) Export
	
	// StandardSubsystems.PerformanceMeasurement
	PerformanceMonitorClient.TimeMeasurement(
		"Document.InitialWIPBalancesByBusinessUnits.Form.DocumentForm.FillInIssueAssignmentRuleCompletion");
	// End StandardSubsystems.PerformanceMeasurement
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	FillInDetailsOfTSServer(AdditionalParameters.AttributeName, Result, AdditionalParameters);
	
EndProcedure

#EndRegion

#Region StandardSubsystems

// StandardSubsystems.Properties
&AtClient
Procedure Attachable_PropertiesExecuteCommand(ItemOrCommand,
												Var_URL = Undefined,
												StandardProcessing = Undefined)
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

&AtClient
Procedure DistributeRemainingWIPCompletion(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	FillingValues	= New Structure("ResultAddress", Result.ResultAddress);
	OpeningParameters	= New Structure("FillingValues", FillingValues);
	
	OpenForm(
		"Document.InitialWIPBalancesByBusinessUnits.ObjectForm",
		OpeningParameters,
		ThisForm);
	
EndProcedure

// End StandardSubsystems.AttachableCommands

#Region ImportDataFromFile

&AtClient
Procedure LoadFromFile(Command)
	
	If Not Object.Costs.Count() = 0 Then
		
		QueryText = NStr("vi = 'Bảng chi phí sẽ được bổ sung. Tiếp tục?';
						|ru = 'Таблица затрат будет перезаполнена. Продолжить?';
						|en = 'The Costs table will be refilled. Continue?'; fa = 'The Costs table will be refilled. Continue?';
						|it = 'La tabella delle spese verrà precompilata.Continuare?';
						|pl = 'Tabela kosztów strat zostanie uzupełniona ponownie. Kontynuować?';
						|tr = 'Gider tablosu yeniden doldurulacaktır. Devam et?'");
		Notification = New CallbackDescription("LoadFromFileCompletion", ThisForm);
		ShowQueryBox(Notification, QueryText, QuestionDialogMode.YesNo);
		
	Else
		ShowUploadFormFromFile();
	EndIf;
	
EndProcedure

&AtClient
Procedure LoadFromFileCompletion(Result, AdditionalParameters) Export
	
	If Not Result = DialogReturnCode.Yes Then
		Return;
	EndIf;
	
	ShowUploadFormFromFile();
	
EndProcedure

#EndRegion

#EndRegion

#EndRegion

#Region Private

#Region FormEvents

&AtServer
Procedure OnReadCreateAtServer()
	
	FillInServiceDetailsOfForm();
		
	SetVisibility1();
	SetHeaders();
	SetArticleSelectionParameters();
	SetParametersForSelectingAssignmentRuleForIssue();
	
EndProcedure

#EndRegion

#Region FormSettings

&AtServer
Procedure SetConditionalAppearance()
	
	ConditionalAppearance.Items.Clear();
	
	#Region DetailsOfOtherExpenses
	
	AvailableOptionsForAssignmentToIssue = New ValueList;
	AvailableOptionsForAssignmentToIssue.Add(Enums.CostAllocationOptions.ToProductionCosts);
	AvailableOptionsForAssignmentToIssue.Add(Enums.CostAllocationOptions.ToProductionCostDirect);
	AvailableOptionsForAssignmentToIssue.Add(Enums.CostAllocationOptions.DoNotAllocate);
		
	// Only view by cost type
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.CostsProductCostElement.Name);
	
	TypesOfOtherExpenses = New ValueList;
	TypesOfOtherExpenses.Add(Enums.CostTypes.Depreciation);
	TypesOfOtherExpenses.Add(Enums.CostTypes.Other);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Costs.ExpenseType");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotInList;
	ItemFilter.RightValue = TypesOfOtherExpenses;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.EmptyTableField);
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<không được chỉ định>';
													|ru = '<не указывается>';
													|en = '<not specified>'; fa = '<مشخص نشده>';
													|it = '<non vengono indicati>';
													|pl = '<nie jest wskazywane>';
													|tr = '<belirtilmiyor>'"));
	Item.Appearance.SetParameterValue("ReadOnly", True);
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	
	#Region RulesOfCostAllocationToProductCost
	// Availability of the rules for attribution to output by distribution options and cost type.
	// Upr.
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.CostsRuleOfCostAllocatingToProductionLotsMan.Name);
	
	OrGroup = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	OrGroup.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	
	ItemFilter = OrGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Costs.ExpenseType");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotInList;
	ItemFilter.RightValue = TypesOfOtherExpenses;
	
	ItemFilter = OrGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Costs.CostAllocationOptionManag");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotInList;
	ItemFilter.RightValue = AvailableOptionsForAssignmentToIssue;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.EmptyTableField);
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<không được chỉ định>';
													|ru = '<не указывается>';
													|en = '<not specified>'; fa = '<مشخص نشده>';
													|it = '<non vengono indicati>';
													|pl = '<nie jest wskazywane>';
													|tr = '<belirtilmiyor>'"));
	Item.Appearance.SetParameterValue("ReadOnly", True);
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	
	// Regl.
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.CostsRuleOfCostAllocatingToProductionLotsLocal.Name);
	
	OrGroup = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	OrGroup.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	
	ItemFilter = OrGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Costs.ExpenseType");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotInList;
	ItemFilter.RightValue = TypesOfOtherExpenses;
	
	ItemFilter = OrGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Costs.CostAllocationOptionLocal");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotInList;
	ItemFilter.RightValue = AvailableOptionsForAssignmentToIssue;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.EmptyTableField);
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<không được chỉ định>';
													|ru = '<не указывается>';
													|en = '<not specified>'; fa = '<مشخص نشده>';
													|it = '<non vengono indicati>';
													|pl = '<nie jest wskazywane>';
													|tr = '<belirtilmiyor>'"));
	Item.Appearance.SetParameterValue("ReadOnly", True);
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
		
	#EndRegion
	
	// The amount of upr.
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.CostsSum.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Costs.ExpenseType");
	ItemFilter.ComparisonType = DataCompositionComparisonType.InList;
	ItemFilter.RightValue = TypesOfOtherExpenses;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Costs.CostAllocationOptionManag");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotInList;
	ItemFilter.RightValue = AvailableOptionsForAssignmentToIssue;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.EmptyTableField);
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<không được chỉ định>';
													|ru = '<не указывается>';
													|en = '<not specified>'; fa = '<مشخص نشده>';
													|it = '<non vengono indicati>';
													|pl = '<nie jest wskazywane>';
													|tr = '<belirtilmiyor>'"));
	Item.Appearance.SetParameterValue("ReadOnly", True);
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	
	// Amounts regl.
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.CostsSumCompl.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.CostsAmountFA.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.CostsAmountPermanentDifferences.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.CostsAmountTemporaryDifferences.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Costs.ExpenseType");
	ItemFilter.ComparisonType = DataCompositionComparisonType.InList;
	ItemFilter.RightValue = TypesOfOtherExpenses;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Costs.CostAllocationOptionLocal");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotInList;
	ItemFilter.RightValue = AvailableOptionsForAssignmentToIssue;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.EmptyTableField);
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<không được chỉ định>';
													|ru = '<не указывается>';
													|en = '<not specified>'; fa = '<مشخص نشده>';
													|it = '<non vengono indicati>';
													|pl = '<nie jest wskazywane>';
													|tr = '<belirtilmiyor>'"));
	Item.Appearance.SetParameterValue("ReadOnly", True);
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	
	#EndRegion
	
EndProcedure

&AtServer
Procedure SetVisibility1()
	
	PBU18IsApplied = False;
	CalculationOfPermanentAndTemporaryDifferencesIsKept = False;
	
	Items.CostsAmountPermanentDifferences.Visible = CalculationOfPermanentAndTemporaryDifferencesIsKept;
	Items.CostsAmountTemporaryDifferences.Visible = CalculationOfPermanentAndTemporaryDifferencesIsKept;
	
EndProcedure

&AtServer
Procedure SetHeaders()
	
	If ManagementAccountingCurrency = LocalAccountingCurrency Then
		Items.CostsSum.Title     = NStr("vi = 'Số tiền';
										|ru = 'Сумма';
										|en = 'Amount'; fa = 'مبلغ';
										|it = 'Importo';
										|pl = 'Wartość';
										|tr = 'Tutar'");
	Else
		TitleText = NStr("vi = 'Số tiền (%1)';
						|ru = 'Сумма (%1)';
						|en = 'Amount (%1)'; fa = 'Amount (%1)';
						|it = 'Totale (%1)';
						|pl = 'Wartość (%1)';
						|tr = 'Tutar (%1)'");
		Items.CostsSum.Title = StrTemplate(TitleText, ManagementAccountingCurrency);
	EndIf;
	
	If ManagementAccountingCurrency = LocalAccountingCurrency
		Or Not ValueIsFilled(LocalAccountingCurrency) Then
		Items.CostsSumCompl.Title = NStr("vi = 'Số tiền tài chính';
										|ru = 'Сумма регл.';
										|en = 'Local amount'; fa = 'مبلغ محلی';
										|it = 'Importo reg.';
										|pl = 'Wartość regl.';
										|tr = 'Tutar (yerel)'");
	Else
		TitleText = NStr("vi = 'Số tiền tài chính (%1)';
						|ru = 'Сумма регл. (%1)';
						|en = 'Local amount (%1)'; fa = 'Local amount (%1)';
						|it = 'Importo regolatorio (%1)';
						|pl = 'Wartość reglam. (%1)';
						|tr = 'Tutar (yerel) (%1)'");
		Items.CostsSumCompl.Title = StrTemplate(TitleText, LocalAccountingCurrency);
	EndIf;
	
	If ManagementAccountingCurrency = LocalAccountingCurrency
		Or Not ValueIsFilled(LocalAccountingCurrency) Then
		Items.CostsAmountFA.Title = NStr("vi = 'KTTh';
										|ru = 'НУ';
										|en = 'TA'; fa = 'مالیاتی';
										|it = 'Contabilità fiscale';
										|pl = 'EP';
										|tr = 'Vergi muhasebesi'");
	Else
		TitleText = NStr("vi = 'KTTh (%1)';
						|ru = 'НУ (%1)';
						|en = 'TA (%1)'; fa = 'TA (%1)';
						|it = 'Contabilità fiscale (%1)';
						|pl = 'EP (%1)';
						|tr = 'VM (%1)'");
		Items.CostsAmountFA.Title = StrTemplate(TitleText, LocalAccountingCurrency);
	EndIf;
	
	If ManagementAccountingCurrency = LocalAccountingCurrency
		Or Not ValueIsFilled(LocalAccountingCurrency) Then
		Items.CostsAmountPermanentDifferences.Title = NStr("vi = 'CLVV';
															|ru = 'ПР';
															|en = 'PD'; fa = 'تفاوت دائم';
															|it = 'PR (Differenze permanenti)';
															|pl = 'RT';
															|tr = 'Sabit Farklar'");
	Else
		TitleText = NStr("vi = 'CLVV (%1)';
						|ru = 'ПР (%1)';
						|en = 'PD (%1)'; fa = 'PD (%1)';
						|it = 'PR (Differenze permanenti) (%1)';
						|pl = 'RT (%1)';
						|tr = 'SF (%1)'");
		Items.CostsAmountPermanentDifferences.Title = StrTemplate(TitleText, LocalAccountingCurrency);
	EndIf;
	
	If ManagementAccountingCurrency = LocalAccountingCurrency
		Or Not ValueIsFilled(LocalAccountingCurrency) Then
		Items.CostsAmountTemporaryDifferences.Title = NStr("vi = 'CLTT';
															|ru = 'ВР';
															|en = 'TD'; fa = 'تفاوت موقت';
															|it = 'VR (Differenze temporanee)';
															|pl = 'RP';
															|tr = 'Geçici Farklar'");
	Else
		TitleText = NStr("vi = 'CLTT (%1)';
						|ru = 'ВР (%1)';
						|en = 'TD (%1)'; fa = 'TD (%1)';
						|it = 'VR (Differenze temporanee) (%1)';
						|pl = 'RP (%1)';
						|tr = 'Geçici Farklar (%1)'");
		Items.CostsAmountTemporaryDifferences.Title = StrTemplate(TitleText, LocalAccountingCurrency);
	EndIf;
	
EndProcedure

&AtServer
Procedure SetArticleSelectionParameters()
	
	ArticleSelectionParameters = New Array;
	ArticleSelectionParameters.Add(New ChoiceParameter("AddExpenseItems", True));
	ArticleSelectionParameters.Add(
		New ChoiceParameter("Filter.BusinessOperation", Enums.BusinessTransactions.OBEntryProductionLotCosts));
	
	OptionsArray = New Array;
	OptionsArray.Add(Enums.CostAllocationOptions.ToProductionCosts);
	OptionsArray.Add(Enums.CostAllocationOptions.ToProductionCostDirect);
	OptionsArray.Add(Enums.CostAllocationOptions.DoNotAllocate);
	
	ArticleSelectionParameters.Add(
		New ChoiceParameter("Filter.CostSharingOptionOr", New FixedArray(OptionsArray)));
	
	Items.CostsExpenseItem.ChoiceParameters = New FixedArray(ArticleSelectionParameters);
	
EndProcedure

&AtServer
Procedure SetParametersForSelectingAssignmentRuleForIssue()
	
	RuleSelectionParameters = New Array;
	
	RulesArray = New Array;
	RulesArray.Add(Enums.RulesOfCostAllocationToProductCost.ByMaterialCosts);
	RulesArray.Add(Enums.RulesOfCostAllocationToProductCost.ByMaterialAndLaborCosts);
	RulesArray.Add(Enums.RulesOfCostAllocationToProductCost.ByLaborCosts);
	RulesArray.Add(Enums.RulesOfCostAllocationToProductCost.ByProductsIncludingFutureReleases);
	
	RuleSelectionParameters.Add(
		New ChoiceParameter("Filter.Ref", New FixedArray(RulesArray)));
	
	Items.CostsRuleOfCostAllocatingToProductionLotsMan.ChoiceParameters = New FixedArray(RuleSelectionParameters);
	Items.CostsRuleOfCostAllocatingToProductionLotsLocal.ChoiceParameters = New FixedArray(RuleSelectionParameters);
	
EndProcedure

#EndRegion

#Region FormServiceCommandHandlers

#Region TSCommands

&AtServer
Procedure FillInDetailsOfTSServer(Attribute, Result, AdditionalParameters)

	TabularSection		= Object.Costs;
	SelectedRows	= AdditionalParameters.SelectedRows;
	Modified	= True;
	
	For Each RowID In SelectedRows Do
		CurrentData = TabularSection.FindByID(RowID);
		CurrentData[Attribute] = Result;
	EndDo;
	
EndProcedure

#EndRegion

#EndRegion

#Region StandardSubsystems

#Region Properties

&AtClient
Procedure Attachable_OnChangeAdditionalAttribute(Item)
	PropertyManagerClient.UpdateAdditionalAttributesDependencies(ThisObject);
EndProcedure

&AtServer
Procedure UpdateAdditionalAttributesItems()
	PropertyManager.UpdateAdditionalAttributesItems(ThisObject);
EndProcedure

&AtClient
Procedure UpdateAdditionalAttributesDependencies()
	PropertyManagerClient.UpdateAdditionalAttributesDependencies(ThisObject);
EndProcedure

&AtServer
Procedure PropertiesExecuteDeferredInitialization()
	
	PropertyManager.FillAdditionalAttributesInForm(ThisObject);
	
EndProcedure

#EndRegion

#Region ImportDataFromFile

&AtClient
Procedure ShowUploadFormFromFile()
	
	ImportParameters = ImportDataFromFileClient.DataImportParameters();
	ImportParameters.FullTabularSectionName = "InitialWIPBalancesByBusinessUnits.Costs";
	ImportParameters.Title = NStr("vi = 'Kết nhập số dư chi phí SXDD từ tệp';
									|ru = 'Загрузка остатков затрат НЗП из файла';
									|en = 'Download WIP cost balances from the file'; fa = 'Download WIP cost balances from the file';
									|it = 'Il download dei saldi della produzione non completata dl file';
									|pl = 'Ładowanie resztek wydatków NZP z pliku';
									|tr = 'Devam eden imalat maliyetlerinin bakiyesini dosyadan içe aktarma'");
	
	Notification = New CallbackDescription("ShowUploadFormFromFileCompletion", ThisObject);
	ImportDataFromFileClient.ShowImportForm(ImportParameters, Notification);
	
EndProcedure

&AtClient
Procedure ShowUploadFormFromFileCompletion(ImportedDataAddress, AdditionalParameters) Export
	
	If ImportedDataAddress = Undefined Then
		Return;
	EndIf;
	
	UploadFromFileOnServer(ImportedDataAddress);
	
EndProcedure

&AtServer
Procedure UploadFromFileOnServer(ImportedDataAddress)
	
	ImportedData = GetFromTempStorage(ImportedDataAddress);
	Object.Costs.Load(ImportedData);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInAttributeAcceptedByCNU");
	BatchProcessingOfTablePartServer.TreatTS(Object.Costs, StructureOfActions, Undefined);
	FillIsAcceptedByKNUByDefault();
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateAmountWithoutVAT");
	StructureOfActions.Insert("RecalculateLocalAmount",	FactorOfConversionFromManCurrencyToRegulCurrency);
	StructureOfActions.Insert("RecalculatePDAmount",	FactorOfConversionFromManCurrencyToRegulCurrency);
	StructureOfActions.Insert("RecalculateAmountTa");
	StructureOfActions.Insert("RecalculateAmountOfTD");
	
	BatchProcessingOfTablePartServer.TreatTS(Object.Costs, StructureOfActions, Undefined);
	
EndProcedure

#EndRegion

#EndRegion

#Region Other

&AtServer
Procedure FillInServiceDetailsOfForm()
	
	ManagementAccountingCurrency = Constants.ManagementAccountingCurrency.Get();
	FillInLocalAccountingCurrency();
	
	FillInOptionsForDistributionOfItemsOfExpenditure();
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInAttributeAcceptedByCNU");
	BatchProcessingOfTablePartServer.TreatTS(Object.Costs, StructureOfActions, Undefined);
	FillIsAcceptedByKNUByDefault();
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateAmountTa");
	BatchProcessingOfTablePartServer.TreatTS(Object.Costs, StructureOfActions, Undefined);
	
	ProcessingOfTabularForms.InitializeRowCache(Items.Costs);
	
EndProcedure

&AtServer
Procedure FillInLocalAccountingCurrency()
	
	LocalAccountingCurrency			= SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Object.Organization);
	FactorOfConversionFromManCurrencyToRegulCurrency	= ConversionFactor_();
	
EndProcedure

&AtServer
Procedure FillInOptionsForDistributionOfItemsOfExpenditure(CurrentData = Undefined)
	
	If CurrentData = Undefined Then
		ExpenseItems = Object.Costs.Unload(, "ExpenseItem").UnloadColumn("ExpenseItem");
	Else
		ExpenseItems = TMCommonUseClientServer.Array(CurrentData.ExpenseItem);
	EndIf;
	
	Query = New Query;
	Query.SetParameter("ExpenseItems", ExpenseItems);
	
	Query.Text = 
		"SELECT
		|	ExpenseItems.Ref AS ExpenseItem,
		|	ExpenseItems.CostAllocationOptionLocal AS CostAllocationOptionLocal,
		|	ExpenseItems.CostAllocationOptionManag AS CostAllocationOptionManag
		|FROM
		|	ChartOfCharacteristicTypes.ExpenseItems AS ExpenseItems
		|WHERE
		|	ExpenseItems.Ref IN(&ExpenseItems)";
	
	Result = Query.Execute();
	Selection = Result.Select();
	
	While Selection.Next() Do
		
		If CurrentData = Undefined Then
			
			LinesByExpenditureItem = Object.Costs.FindRows(New Structure("ExpenseItem", Selection.ExpenseItem));
			For Each CostLine In LinesByExpenditureItem Do
				
				CostLine.CostAllocationOptionManag  = Selection.CostAllocationOptionManag;
				CostLine.CostAllocationOptionLocal = Selection.CostAllocationOptionLocal;
				
			EndDo;
			
		Else
			
			CurrentData.CostAllocationOptionManag  = Selection.CostAllocationOptionManag;
			CurrentData.CostAllocationOptionLocal = Selection.CostAllocationOptionLocal;
			
		EndIf;
		
	EndDo;
	
EndProcedure

&AtServer
Procedure FillIsAcceptedByKNUByDefault()
	
	For Each CurRow In Object.Costs Do
		If Not CurRow.ExpenseType = Enums.CostTypes.Depreciation
			And Not CurRow.ExpenseType = Enums.CostTypes.Other Then
			CurRow.AcceptedByTheKNU = True;
		EndIf;
	EndDo;
	
EndProcedure

&AtServer
Function ConversionFactor_()
	
	Return
		ProcessingOfExchangeRatesTM.GetConversionFactorFromCurrencyToCurrency(
			ManagementAccountingCurrency,
			LocalAccountingCurrency,
			?(Object.Date = Date(1,1,1), CurrentSessionDate(), Object.Date));
	
EndFunction

&AtServer
Function RulesOfCostAllocationToProductCost()
	
	RulesOfCostAllocationToProductCost = New Map;
	
	// The "Material Costs" rule
	RulesOfCostAllocationToProductCost.Insert(
		Enums.TypesOfCostAllocatingBase.MaterialCostsAmount,
		Enums.RulesOfCostAllocationToProductCost.ByMaterialCosts);
	RulesOfCostAllocationToProductCost.Insert(
		Enums.TypesOfCostAllocatingBase.StandardMaterialConsumption,
		Enums.RulesOfCostAllocationToProductCost.ByMaterialCosts);
	RulesOfCostAllocationToProductCost.Insert(
		Enums.TypesOfCostAllocatingBase.QuantityOfSpecifiedMaterials,
		Enums.RulesOfCostAllocationToProductCost.ByMaterialCosts);
	RulesOfCostAllocationToProductCost.Insert(
		Enums.TypesOfCostAllocatingBase.VolumeOfSpecifiedMaterials,
		Enums.RulesOfCostAllocationToProductCost.ByMaterialCosts);
	RulesOfCostAllocationToProductCost.Insert(
		Enums.TypesOfCostAllocatingBase.WeightOfSpecifiedMaterials,
		Enums.RulesOfCostAllocationToProductCost.ByMaterialCosts);
	
	// The "Labor costs" rule
	RulesOfCostAllocationToProductCost.Insert(
		Enums.TypesOfCostAllocatingBase.TotalPayrollExpenses,
		Enums.RulesOfCostAllocationToProductCost.ByLaborCosts);
	RulesOfCostAllocationToProductCost.Insert(
		Enums.TypesOfCostAllocatingBase.NumberOfWorksOfSpecifiedKinds,
		Enums.RulesOfCostAllocationToProductCost.ByLaborCosts);
	RulesOfCostAllocationToProductCost.Insert(
		Enums.TypesOfCostAllocatingBase.StandardRemunerationLevel,
		Enums.RulesOfCostAllocationToProductCost.ByLaborCosts);
	RulesOfCostAllocationToProductCost.Insert(
		Enums.TypesOfCostAllocatingBase.WorkPerformanceDuration,
		Enums.RulesOfCostAllocationToProductCost.ByLaborCosts);
	
	// The rule "On material labor costs"
	RulesOfCostAllocationToProductCost.Insert(
		Enums.TypesOfCostAllocatingBase.AmountOfMaterialAndLaborCosts,
		Enums.RulesOfCostAllocationToProductCost.ByMaterialAndLaborCosts);
	
	// The rule of "Production accounting of future releases"
	RulesOfCostAllocationToProductCost.Insert(
		Enums.TypesOfCostAllocatingBase.ProductsQuantity,
		Enums.RulesOfCostAllocationToProductCost.ByProductsIncludingFutureReleases);
	RulesOfCostAllocationToProductCost.Insert(
		Enums.TypesOfCostAllocatingBase.ProductsWeight,
		Enums.RulesOfCostAllocationToProductCost.ByProductsIncludingFutureReleases);
	RulesOfCostAllocationToProductCost.Insert(
		Enums.TypesOfCostAllocatingBase.ProductsVolume,
		Enums.RulesOfCostAllocationToProductCost.ByProductsIncludingFutureReleases);
	RulesOfCostAllocationToProductCost.Insert(
		Enums.TypesOfCostAllocatingBase.TargetProductCost,
		Enums.RulesOfCostAllocationToProductCost.ByProductsIncludingFutureReleases);
	
	RulesOfCostAllocationToProductCost.Insert(
		Enums.TypesOfCostAllocatingBase.ProductsQuantityConsideringFutureReleases,
		Enums.RulesOfCostAllocationToProductCost.ByProductsIncludingFutureReleases);
	RulesOfCostAllocationToProductCost.Insert(
		Enums.TypesOfCostAllocatingBase.ProductsVolumeConsideringFutureReleases,
		Enums.RulesOfCostAllocationToProductCost.ByProductsIncludingFutureReleases);
	RulesOfCostAllocationToProductCost.Insert(
		Enums.TypesOfCostAllocatingBase.ProductsWeightConsideringFutureReleases,
		Enums.RulesOfCostAllocationToProductCost.ByProductsIncludingFutureReleases);
	RulesOfCostAllocationToProductCost.Insert(
		Enums.TypesOfCostAllocatingBase.TargetProductCostConsideringFutureReleases,
		Enums.RulesOfCostAllocationToProductCost.ByProductsIncludingFutureReleases);
	
	Return RulesOfCostAllocationToProductCost;
	
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
