
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	InfobaseUpdate.CheckObjectProcessed(Object, ThisObject);

	#Region StandardSubsystems

	// StandardSubsystems.ObjectsVersioning
	ObjectsVersioning.OnCreateAtServer(ThisForm);
	// End StandardSubsystems.ObjectsVersioning

	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject);
	// End IntegrationWith1CDocumentManagementSubsystem

	// StandardSubsystems.Properties
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("ItemForPlacementName", "GroupAdditionalAttributes");
	AdditionalParameters.Insert("DeferredInitialization", True);
	PropertyManager.OnCreateAtServer(ThisObject, AdditionalParameters);
	// End StandardSubsystems.Properties
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);

	#EndRegion

	ItemsAndDimensionsSelectionParameters = Documents.RDExpenseRecognition.ItemsAndDimensionsSelectionParameters(Object.BusinessOperation);
	IncomeAndExpensesServer.OnCreateAtServer(ThisObject, ItemsAndDimensionsSelectionParameters);

	DecryptionSwitch = ?(Object.Allocation.Count() = 1, 0, 1);

	ConfigureBusinessOperations();

	FillInListsForSelectingTypesOfExpenseRecognition();
	
	SetConditionalAppearance();
	
	ManagingFormElementsOnServer();
	
	ChangeHeadersForBusinessTransactions();
	
	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)
	
	// StandardSubsystems.AccessManagement
	AccessManagement.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.AccessManagement

	// StandardSubsystems.AccessManagement
	AccessManagement.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.AccessManagement

	PeriodClosingDates.ObjectOnReadAtServer(ThisForm, CurrentObject);

	FormEvents.OnReadAtServer(ThisObject, CurrentObject);

	// StandardSubsystems.AttachableCommands
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	// End StandardSubsystems.AttachableCommands

	// StandardSubsystems.Properties
	PropertyManager.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.Properties
	
	ItemsAndDimensionsSelectionParameters = Documents.RDExpenseRecognition.ItemsAndDimensionsSelectionParameters(Object.BusinessOperation);
	IncomeAndExpensesServer.OnReadAtServer(ThisObject, ItemsAndDimensionsSelectionParameters);

EndProcedure

&AtClient
Procedure OnOpen(Cancel)

	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands

	// StandardSubsystems.Properties
	PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
	// End StandardSubsystems.Properties
	
	ManagingFormElementsOnClient();

EndProcedure

&AtClient
Procedure BeforeWrite(Cancel, WriteParameters)

	FormEventsClient.BeforeWrite(ThisObject, Cancel, WriteParameters);

EndProcedure

&AtClient
Procedure ChoiceProcessing(ValueSelected, ChoiceSource)

	If ChoiceSource.FormName = "Catalog.RDTopicsStages.Form.ChoiceForm" Then
		If ValueSelected.Count() > 0 Then
			For Each ArrayElement In ValueSelected Do
				Object.RDTopicsStages.Add().TopicStage = ArrayElement;
			EndDo;
		EndIf;
	EndIf;

EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)

// StandardSubsystems.Properties 
	If PropertyManagerClient.ProcessNotifications(ThisObject, EventName, Parameter) Then
		UpdateAdditionalAttributesItems();
		PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
	EndIf;
	// End StandardSubsystems.Properties
	FormEventsClient.NotificationProcessing(ThisObject, EventName, Parameter, Source);

EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	
	// StandardSubsystems.Properties
	PropertyManager.FillCheckProcessing(ThisForm, Cancel, CheckedAttributes);
	// End StandardSubsystems.Properties
	
	If Not DecryptionSwitch Then
		
		DocumentObject = FormAttributeToValue("Object");
		DocumentObject.AdditionalProperties.Insert("DistributionWithoutPartitioning", True);
		
		If Not DocumentObject.CheckFilling() Then
			Cancel = True;
		EndIf;
		
		CheckedAttributes.Clear();
	EndIf;

EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)

// StandardSubsystems.Properties
	PropertyManager.BeforeWriteAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.Properties
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.BeforeWriteAtServer(
		ThisObject,
		CurrentObject,
		WriteParameters);
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

&AtClient
Procedure AfterWrite(WriteParameters)
	
	WriteParameters.Insert("NotificationDocumentKeys", OperationsWithDocumentJournalsClient.GetKeyParametersForDocument(
		Object.Ref, Object.Date, Object.BusinessOperation));
	Notify("Write_RDExpenseRecognition", WriteParameters, Object.Ref);
	TMCommonUseClient.NotifyAboutEntryOfDocumentInJournal();
	NonCurrentAssetsClient.NotifyAboutEntryOfDocumentInJournalOfIA();

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
	
	IncomeAndExpensesServer.AfterWriteAtServer(ThisObject);
	
	ChangeHeadersForBusinessTransactions();
	
	FormEvents.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	
EndProcedure

#EndRegion

#Region EventHandlersForFormElements

&AtClient
Procedure BusinessOperationOnChange(Item)

	BusinessOperationWhenChangingOnServer();
		
	ManagingFormElementsOnClient();

EndProcedure

&AtServer
Procedure BusinessOperationWhenChangingOnServer()
	
	Object.Allocation.Clear();
	
	FillInListsForSelectingTypesOfExpenseRecognition();
	
	ManagingFormElementsOnServer();
	
	ChangeHeadersForBusinessTransactions();
	
EndProcedure

&AtClient
Procedure DecryptionSwitchOnChange(Item)

	ManagingFormElementsOnClient();

EndProcedure

&AtClient
Procedure RDTopicsStagesTopicStageAutoComplete(Item, Text, ChoiceData, DataGetParameters, Waiting, StandardProcessing)
	
	If Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.RecognitionOfResearchExpenses") Then
		DataGetParameters.Filter.Insert("Development", False);
	EndIf;
	
EndProcedure

&AtClient
Procedure TypeOfRecognitionOfExpensesAfterCompletionOfTheStageOnChange(Item)

	CheckTypeOfCostAllocationTa();
	
	ClearExpenseItem("ItemOfExpenditureForTheCompletionOfTheStage", "StageCompletionDistribution");

EndProcedure

&AtClient
Procedure TypeOfExpenseRecognitionAfterCompletionOfTheStageOnChange(Item)
	
	ClearExpenseItem("ItemOfExpenditureNuseachievementOfTheStage", "StageCompletionDistribution");
	
EndProcedure

&AtClient
Procedure TypeOfExpenseRecognitionForStageCompletionOnChange(Item)
	
	ClearExpenseItem("ItemOfExpenditureAtTheEndOfTheStage", "StageCompletionDistribution");
	
EndProcedure

&AtClient
Procedure TypeOfExpenseRecognitionAfterCompletionOfTheStageStartChoice(Item, ChoiceData, StandardProcessing)

	GenerateListOfTypesOfRecognitionTa(Item.Name, Items.StageCompletionDistribution.CurrentData.ExpenseRecognitionTypeAC);

EndProcedure

&AtClient
Procedure ItemOfExpenditureForTheCompletionOfTheStageStartChoice(Item, ChoiceData, StandardProcessing)

	UpdateParametersForSelectingExpenseItem(Item, Items.StageCompletionDistribution.CurrentData.ExpenseRecognitionTypeAC);
	
EndProcedure

&AtClient
Procedure ItemOfExpenditureForTheCompletionOfTheStageOnChange(Item)

	IncomeAndExpensesClientServer.AssetRefOnChange(ThisObject, Item);

EndProcedure

&AtClient
Procedure ItemOfExpenditureAtTheEndOfTheStageOnChange(Item)

	IncomeAndExpensesClientServer.AssetRefOnChange(ThisObject, Item);

	ConfigureDisplayOfFormElementSuggestions();

EndProcedure

&AtClient
Procedure DistributionOfTheItemOfExpensesOfTheUUPoToResearchInCaseOfChange(Item)

	IncomeAndExpensesClientServer.AssetRefOnChange(ThisObject, Item);

	ConfigureDisplayOfFormElementSuggestions();

EndProcedure

&AtClient
Procedure ItemOfExpenditureAtTheEndOfTheStageStartChoice(Item, ChoiceData, StandardProcessing)

	UpdateParametersForSelectingExpenseItem(Item, Items.StageCompletionDistribution.CurrentData.ExpenseRecognitionTypeMA);

EndProcedure

&AtClient
Procedure TheDistributionOfIntelligenceSpendingBUPAResearchTheBeginningOfTheSelection(Item,
		ChoiceData, StandardProcessing)

	IncomeAndExpensesClient.StartSelectingExpenseAnalytics(ThisObject, Item, StandardProcessing);

EndProcedure

&AtClient
Procedure DistributionOfTheBupoResearchExpenseAnalystWhenChangesAreMade(Item)

	IncomeAndExpensesClientServer.DimensionOfExpensesOnChange(ThisObject, Item);

EndProcedure

&AtClient
Procedure DistributionOfTheUupoCostAnalystToResearchWhenChangesAreMade(Item)

	IncomeAndExpensesClientServer.DimensionOfExpensesOnChange(ThisObject, Item);

EndProcedure

&AtClient
Procedure TheDistributionOfIntelligenceSpendingBUPAResearchAutoSelection(Item,
		Text, ChoiceData, DataGetParameters, Waiting,
		StandardProcessing)

	IncomeAndExpensesClient.AutoSelectionOfExpenseAnalytics(ThisObject, Item, Text, ChoiceData, DataGetParameters, StandardProcessing);

EndProcedure

&AtClient
Procedure DistributionAnalysisOfExpensesUupoResearchAutoSelection(Item,
		Text, ChoiceData, DataGetParameters, Waiting,
		StandardProcessing)

	IncomeAndExpensesClient.AutoSelectionOfExpenseAnalytics(ThisObject, Item, Text, ChoiceData, DataGetParameters, StandardProcessing);

EndProcedure

&AtClient
Procedure DistributionOfExpensesAnalystBupoResearchEndOfTextEntry(Item,
		Text, ChoiceData, DataGetParameters, StandardProcessing)

	IncomeAndExpensesClient.EndOfCostAnalyticsTextEntry(ThisObject, Item, Text, ChoiceData, DataGetParameters, StandardProcessing);

EndProcedure

&AtClient
Procedure DistributionOfUupoResearchExpensesAnalystEndOfTextEntry(Item,
		Text, ChoiceData, DataGetParameters, StandardProcessing)

	IncomeAndExpensesClient.EndOfCostAnalyticsTextEntry(ThisObject, Item, Text, ChoiceData, DataGetParameters, StandardProcessing);

EndProcedure

&AtClient
Procedure CostAnalysisOfTheBuzaperformanceStageStartChoice(Item,
		ChoiceData, StandardProcessing)

	IncomeAndExpensesClient.StartSelectingExpenseAnalytics(ThisObject, Item, StandardProcessing);

EndProcedure

&AtClient
Procedure TheDistributionOfIntelligenceSpendingUupoResearchTheBeginningOfTheSelection(Item,
		ChoiceData, StandardProcessing)

	IncomeAndExpensesClient.StartSelectingExpenseAnalytics(ThisObject, Item, StandardProcessing);

EndProcedure

&AtClient
Procedure CostAnalysisAtTheEndOfTheStageStartChoice(Item,
		ChoiceData, StandardProcessing)

	IncomeAndExpensesClient.StartSelectingExpenseAnalytics(ThisObject, Item, StandardProcessing);

EndProcedure

&AtClient
Procedure CostAnalysisOfTheBuzaperformanceStageAutoComplete(Item, Text,
		ChoiceData, DataGetParameters, Waiting, StandardProcessing)

	IncomeAndExpensesClient.AutoSelectionOfExpenseAnalytics(ThisObject, Item, Text, ChoiceData, DataGetParameters, StandardProcessing);

EndProcedure

&AtClient
Procedure CostAnalysisAtTheEndOfTheStageAutoComplete(Item, Text,
		ChoiceData, DataGetParameters, Waiting, StandardProcessing)

	IncomeAndExpensesClient.AutoSelectionOfExpenseAnalytics(ThisObject, Item, Text, ChoiceData, DataGetParameters, StandardProcessing);

EndProcedure

&AtClient
Procedure CostAnalysisOfTheBuzaperformanceStageTextEditEnd(Item,
		Text, ChoiceData, DataGetParameters, StandardProcessing)

	IncomeAndExpensesClient.EndOfCostAnalyticsTextEntry(ThisObject, Item, Text, ChoiceData, DataGetParameters, StandardProcessing);

EndProcedure

&AtClient
Procedure CostAnalysisAtTheEndOfTheStageTextEditEnd(Item,
		Text, ChoiceData, DataGetParameters, StandardProcessing)

	IncomeAndExpensesClient.EndOfCostAnalyticsTextEntry(ThisObject, Item, Text, ChoiceData, DataGetParameters, StandardProcessing);

EndProcedure

&AtClient
Procedure CostAnalysisOfTheBuzaperformanceStageOnChange(Item)

	IncomeAndExpensesClientServer.DimensionOfExpensesOnChange(ThisObject, Item);

EndProcedure

&AtClient
Procedure CostAnalysisAtTheEndOfTheStageOnChange(Item)

	IncomeAndExpensesClientServer.DimensionOfExpensesOnChange(ThisObject, Item);

EndProcedure

&AtClient
Procedure CostAnalysisNuseachievementOfTheStageOnChange(Item)

	IncomeAndExpensesClientServer.DimensionOfExpensesOnChange(ThisObject, Item);

EndProcedure

&AtClient
Procedure CostAnalysisNuseachievementOfTheStageAutoComplete(Item, Text,
		ChoiceData, DataGetParameters, Waiting, StandardProcessing)

	IncomeAndExpensesClient.AutoSelectionOfExpenseAnalytics(ThisObject, Item, Text, ChoiceData, DataGetParameters, StandardProcessing);

EndProcedure

&AtClient
Procedure CostAnalysisNuseachievementOfTheStageTextEditEnd(Item,
		Text, ChoiceData, DataGetParameters, StandardProcessing)

	IncomeAndExpensesClient.EndOfCostAnalyticsTextEntry(ThisObject, Item, Text, ChoiceData, DataGetParameters, StandardProcessing);

EndProcedure

&AtClient
Procedure CostAnalysisNuseachievementOfTheStageStartChoice(Item,
		ChoiceData, StandardProcessing)

	IncomeAndExpensesClient.StartSelectingExpenseAnalytics(ThisObject, Item, StandardProcessing);

EndProcedure

&AtClient
Procedure ItemOfExpenditureNuseachievementOfTheStageOnChange(Item)

	IncomeAndExpensesClientServer.AssetRefOnChange(ThisObject, Item);

	ConfigureDisplayOfFormElementSuggestions();

EndProcedure

&AtClient
Procedure ItemOfExpenditureNuseachievementOfTheStageStartChoice(Item, ChoiceData, StandardProcessing)

	UpdateParametersForSelectingExpenseItem(Item, Items.StageCompletionDistribution.CurrentData.ExpenseRecognitionTypeTA);

EndProcedure

&AtClient
Procedure OrganizationOnChange(Item)
	
	OrganizationWhenChangedOnServer();
	
	For Each String In Object.Allocation Do
		FillDefaultAttributes(String);
	EndDo;	
	
	ManagingFormElementsOnClient();
	
EndProcedure

&AtServer
Procedure OrganizationWhenChangedOnServer()
	
	ConfigureBusinessOperations();
	
	FillInListsForSelectingTypesOfExpenseRecognition();
	
	ManagingFormElementsOnServer();
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersAllocation

&AtClient
Procedure TheDistributionOfIntelligenceSpendingBoitoSelection(Item, Text,
		ChoiceData, DataGetParameters, Waiting, StandardProcessing)

	IncomeAndExpensesClient.AutoSelectionOfExpenseAnalytics(ThisObject, Item, Text, ChoiceData, DataGetParameters, StandardProcessing);

EndProcedure

&AtClient
Procedure TheDistributionOfIntelligenceSpendingWwwtoSelection(Item, Text,
		ChoiceData, DataGetParameters, Waiting, StandardProcessing)

	IncomeAndExpensesClient.AutoSelectionOfExpenseAnalytics(ThisObject, Item, Text, ChoiceData, DataGetParameters, StandardProcessing);

EndProcedure

&AtClient
Procedure DistributionCostAnalyticsEndOfTextEntry(Item, Text,
		ChoiceData, DataGetParameters, StandardProcessing)

	IncomeAndExpensesClient.EndOfCostAnalyticsTextEntry(ThisObject, Item, Text, ChoiceData, DataGetParameters, StandardProcessing);

EndProcedure

&AtClient
Procedure DistributionOfCostAnalyticsUuEndOfTextEntry(Item, Text,
		ChoiceData, DataGetParameters, StandardProcessing)

	IncomeAndExpensesClient.EndOfCostAnalyticsTextEntry(ThisObject, Item, Text, ChoiceData, DataGetParameters, StandardProcessing);

EndProcedure

&AtClient
Procedure TheDistributionOfSpendAnalyticsBonachelaChoice(Item, ChoiceData,
		StandardProcessing)

	IncomeAndExpensesClient.StartSelectingExpenseAnalytics(ThisObject, Item, StandardProcessing);

EndProcedure

&AtClient
Procedure DistributionOfTheExpenseAnalystAtTheBeginningOfTheSelection(Item, ChoiceData,
		StandardProcessing)

	IncomeAndExpensesClient.StartSelectingExpenseAnalytics(ThisObject, Item, StandardProcessing);

EndProcedure

&AtClient
Procedure TheDistributionOfIntelligenceSpendingNoautoSelection(Item, Text,
		ChoiceData, DataGetParameters, Waiting, StandardProcessing)

	IncomeAndExpensesClient.AutoSelectionOfExpenseAnalytics(ThisObject, Item, Text, ChoiceData, DataGetParameters, StandardProcessing);

EndProcedure

&AtClient
Procedure DistributionOfExpensesAnalyticsEndOfTextEntry(Item, Text,
		ChoiceData, DataGetParameters, StandardProcessing)

	IncomeAndExpensesClient.EndOfCostAnalyticsTextEntry(ThisObject, Item, Text, ChoiceData, DataGetParameters, StandardProcessing);

EndProcedure

&AtClient
Procedure DistributionOfTheCostAnalystAtTheBeginningOfTheSelection(Item, ChoiceData,
		StandardProcessing)

	IncomeAndExpensesClient.StartSelectingExpenseAnalytics(ThisObject, Item, StandardProcessing);

EndProcedure

&AtClient
Procedure DistributionOfTheCostItemOfTheBUPoToResearchInCaseOfChange(Item)

	IncomeAndExpensesClientServer.AssetRefOnChange(ThisObject, Item);

EndProcedure

&AtClient
Procedure DistributionCostItemOfBUPoResearchStartOfSelection(Item,
		ChoiceData, StandardProcessing)

	UpdateParametersForSelectingExpenseItem(Item);

EndProcedure

&AtClient
Procedure DistributionOfTheCostItemOfTheUUPoResearchTheBeginningOfTheChoice(Item,
		ChoiceData, StandardProcessing)

	UpdateParametersForSelectingExpenseItem(Item);

EndProcedure

&AtClient
Procedure DistributionTypeOfExpenseRecognitionAtTheBeginningOfTheSelection(Item,
		ChoiceData, StandardProcessing)

	GenerateListOfTypesOfRecognitionTa(Item.Name, Items.StageCompletionDistribution.CurrentData.ExpenseRecognitionTypeAC);

EndProcedure

&AtClient
Procedure TheDistributionOfTheSpeciesOfRecognitionOfExpensesBupreChange(Item)

	CheckTypeOfCostAllocationTa();
	
	ClearExpenseItem("DistributionOfTheCompletionOfTheStageCostItemOfTheBU", "StageCompletionDistribution");
	
EndProcedure

&AtClient
Procedure TheDistributionPhaseIsCompleteViewOfTheRecognitionOfExpensesWELLOnChange(Item)
	
	ClearExpenseItem("DistributionOfStageCompletionItemOfExpenditureNU", "StageCompletionDistribution");
	
EndProcedure

&AtClient
Procedure TheDistributionPhaseIsCompleteViewOfTheRecognitionOfExpensesUUOnChange(Item)
	
	ClearExpenseItem("DistributionOfTheCompletionOfTheStageItemOfExpenditureOfTheUU", "StageCompletionDistribution");
	
EndProcedure

&AtClient
Procedure DistributionExpensesBupreChange(Item)

	IncomeAndExpensesClientServer.AssetRefOnChange(ThisObject, Item);

EndProcedure

&AtClient
Procedure DistributionExpensesRupriChange(Item)

	IncomeAndExpensesClientServer.AssetRefOnChange(ThisObject, Item);

EndProcedure

&AtClient
Procedure DistributionExpensesBonachelaChoice(Item, ChoiceData, StandardProcessing)

	UpdateParametersForSelectingExpenseItem(Item, Items.StageCompletionDistribution.CurrentData.ExpenseRecognitionTypeAC);

EndProcedure

&AtClient
Procedure DistributionExpensesWonchalaChoice(Item, ChoiceData, StandardProcessing)

	UpdateParametersForSelectingExpenseItem(Item, Items.StageCompletionDistribution.CurrentData.ExpenseRecognitionTypeMA);

EndProcedure

&AtClient
Procedure DistributionItemOfExpenditureNupriChange(Item)

	IncomeAndExpensesClientServer.AssetRefOnChange(ThisObject, Item);

EndProcedure

&AtClient
Procedure DistributionItemOfExpenditureNunFirstChoice(Item, ChoiceData, StandardProcessing)

	UpdateParametersForSelectingExpenseItem(Item, Items.StageCompletionDistribution.CurrentData.ExpenseRecognitionTypeTA);

EndProcedure

&AtClient
Procedure DistributionAtTheBeginningOfEditing(Item, NewRow, Copy)

	IncomeAndExpensesClientServer.WhenAddingRowToTable(ThisObject, Item.CurrentData, "Object.Allocation");

EndProcedure

&AtClient
Procedure AllocationByResearchOnStartEdit(Item, NewRow, Copy)
	
	IncomeAndExpensesClientServer.WhenAddingRowToTable(ThisObject, Item.CurrentData, "Object.Allocation");
	
EndProcedure

&AtClient
Procedure DistributionByResearchItemOfExpenditureWhenChanging(Item)

	IncomeAndExpensesClientServer.AssetRefOnChange(ThisObject, Item);

EndProcedure

&AtClient
Procedure DistributionByResearchItemOfExpenditureOfTheUUOnChange(Item)

	IncomeAndExpensesClientServer.AssetRefOnChange(ThisObject, Item);

EndProcedure

&AtClient
Procedure TheDistributionOfResearchExpenditureAndTheBeginningOfTheSelection(Item, ChoiceData, StandardProcessing)

	UpdateParametersForSelectingExpenseItem(Item);

EndProcedure

&AtClient
Procedure DistributionByResearchItemOfExpenditureOfTheUUStartChoice(Item, ChoiceData, StandardProcessing)

	UpdateParametersForSelectingExpenseItem(Item);

EndProcedure

&AtClient
Procedure DistributionByResearchByResearchCostAnalysisAutoSelection(Item,
		Text, ChoiceData, DataGetParameters, Waiting,
		StandardProcessing)

	IncomeAndExpensesClient.AutoSelectionOfExpenseAnalytics(ThisObject, Item, Text, ChoiceData, DataGetParameters, StandardProcessing);

EndProcedure

&AtClient
Procedure DistributionByResearchUUCostAnalysisAutoComplete(Item,
		Text, ChoiceData, DataGetParameters, Waiting,
		StandardProcessing)

	IncomeAndExpensesClient.AutoSelectionOfExpenseAnalytics(ThisObject, Item, Text, ChoiceData, DataGetParameters, StandardProcessing);

EndProcedure

&AtClient
Procedure DistributionByResearchByResearchCostAnalysisEndOfTextEntry(Item,
		Text, ChoiceData, DataGetParameters, StandardProcessing)

	IncomeAndExpensesClient.EndOfCostAnalyticsTextEntry(
		ThisObject, Item, Text, ChoiceData, DataGetParameters, StandardProcessing);

EndProcedure

&AtClient
Procedure DistributionByResearchUUCostAnalysisTextEditEnd(Item,
		Text, ChoiceData, DataGetParameters, StandardProcessing)

	IncomeAndExpensesClient.EndOfCostAnalyticsTextEntry(
		ThisObject, Item, Text, ChoiceData, DataGetParameters, StandardProcessing);

EndProcedure

&AtClient
Procedure DistributionByResearchByResearchCostAnalysisStartOfSelection(Item,
		ChoiceData, StandardProcessing)

	IncomeAndExpensesClient.StartSelectingExpenseAnalytics(ThisObject, Item, StandardProcessing);

EndProcedure

&AtClient
Procedure DistributionByResearchUUCostAnalysisStartChoice(Item,
		ChoiceData, StandardProcessing)

	IncomeAndExpensesClient.StartSelectingExpenseAnalytics(ThisObject, Item, StandardProcessing);

EndProcedure

&AtClient
Procedure AllocationByResearchOnEditEnd(Item, NewRow, CancelEdit)
	If NewRow Then
		FillDefaultAttributes(Item.CurrentData);
	EndIf;
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure WriteDocument(Command)

	TMCommonUseClient.Write(ThisForm, True);

EndProcedure

&AtClient
Procedure PostDocument(Command)

	TMCommonUseClient.Post(ThisForm, True);

EndProcedure

&AtClient
Procedure PostAndClose(Command)

	TMCommonUseClient.PostAndClose(ThisForm, False);

EndProcedure

&AtClient
Procedure Pickup(Command)

	ChooseTheme(ThisForm, True);

EndProcedure

&AtClient
Procedure RDTopicsStagesTopicStageStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	
	ChooseTheme(Item, False);

EndProcedure

#Region StandardSubsystems

// StandardSubsystems.Properties
&AtClient
Procedure Attachable_PropertiesExecuteCommand(ItemOrCommand,
		Var_URL = Undefined, StandardProcessing = Undefined)

	PropertyManagerClient.ExecuteCommand(ThisObject, ItemOrCommand, StandardProcessing);

EndProcedure

// End StandardSubsystems.Properties
&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)

	FormEventsClient.ExecuteOverridableCommand(ThisObject, Command);

EndProcedure

// StandardSubsystems.AttachableCommands
&AtClient
Procedure Attachable_ExecuteCommand(Command)
	AttachableCommandsClient.ExecuteCommand(ThisObject, Command, Object);
EndProcedure

&AtServer
Procedure Attachable_ExecuteCommandAtServer(Context, Result) Export
	AttachableCommands.ExecuteCommand(ThisObject, Context, Object, Result);
EndProcedure

&AtClient
Procedure Attachable_UpdateCommands()
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
EndProcedure

// End StandardSubsystems.AttachableCommands

&AtClient
Procedure Attachable_ExecuteIntegrationCommand(Command)
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCoreClient.ExecutePlugInIntegrationCommand(Command, ThisObject, Object);
	// End IntegrationWith1CDocumentManagementSubsystem
	
EndProcedure

#EndRegion

#EndRegion

#Region Private

&AtClient
Procedure ManagingFormElementsOnClient()

	WhenChangingSplitDecryptionSwitch(DecryptionSwitch);

	ConfigureDisplayOfFormElementSuggestions();
	ConfigureDisplayOfExpenseAllocation(ThisObject);

EndProcedure

&AtServer
Procedure ManagingFormElementsOnServer()

	If Object.BusinessOperation = Enums.BusinessTransactions.RecognitionOfResearchExpenses Then
		If ResearchRecognitionSettings.FindRows(New Structure("AccountingPolicy", "Accounting")).Count() > 0 Then
			Items.DistributionByResearchItemOfExpenditureOfTheBU.Visible = True;
			Items.DistributionByResearchCostAnalysisBU.Visible = True;
			Items.ItemOfExpenditureOfTheBUPoResearch.Visible = True;
			Items.BUPoResearchCostAnalysis.Visible = True;
		Else
			Items.DistributionByResearchItemOfExpenditureOfTheBU.Visible = False;
			Items.DistributionByResearchCostAnalysisBU.Visible = False;
			Items.ItemOfExpenditureOfTheBUPoResearch.Visible = False;
			Items.BUPoResearchCostAnalysis.Visible = False;
		EndIf;
		If ResearchRecognitionSettings.FindRows(New Structure("AccountingPolicy", "FinAccounting")).Count() > 0 Then
			Items.DistributionByResearchItemOfExpenditureOfTheUU.Visible = True;
			Items.DistributionByResearchUUCostAnalysis.Visible = True;
			Items.ItemOfExpenditureOfTheUUPoForResearch.Visible = True;
			Items.UUPoResearchCostAnalysis.Visible = True;
		Else
			Items.DistributionByResearchItemOfExpenditureOfTheUU.Visible = False;
			Items.DistributionByResearchUUCostAnalysis.Visible = False;
			Items.ItemOfExpenditureOfTheUUPoForResearch.Visible = False;
			Items.UUPoResearchCostAnalysis.Visible = False;
		EndIf;
	Else
		Items.DistributionByResearchItemOfExpenditureOfTheUU.Visible = True;
		Items.DistributionByResearchUUCostAnalysis.Visible = True;
		Items.ItemOfExpenditureOfTheUUPoForResearch.Visible = True;
		Items.UUPoResearchCostAnalysis.Visible = True;
		Items.DistributionByResearchItemOfExpenditureOfTheBU.Visible = True;
		Items.DistributionByResearchCostAnalysisBU.Visible = True;
		Items.ItemOfExpenditureOfTheBUPoResearch.Visible = True;
		Items.BUPoResearchCostAnalysis.Visible = True;
	EndIf;

EndProcedure

&AtClient
Procedure FillDefaultAttributes(String)
	
	If Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.RecognitionOfResearchExpenses") Then
		If ResearchRecognitionSettings.FindRows(New Structure("AccountingPolicy", "Accounting")).Count() = 0 Then
			String.ExpenseRecognitionTypeAC
				= PredefinedValue("Enum.RDExpenseRecognitionTypes.DoNotRecognizeExpenses")
		Else
			String.ExpenseRecognitionTypeAC
				= PredefinedValue("Enum.RDExpenseRecognitionTypes.RecognitionAsCurrentExpenses");
		EndIf;
		If ResearchRecognitionSettings.FindRows(New Structure("AccountingPolicy", "FinAccounting")).Count() = 0 Then
			String.ExpenseRecognitionTypeMA
				= PredefinedValue("Enum.RDExpenseRecognitionTypes.DoNotRecognizeExpenses")
		Else
			String.ExpenseRecognitionTypeMA
				= PredefinedValue("Enum.RDExpenseRecognitionTypes.RecognitionAsCurrentExpenses");
		EndIf;
		
		String.ExpenseRecognitionTypeTA
			= PredefinedValue("Enum.RDExpenseRecognitionTypes.DoNotRecognizeExpenses")
	EndIf;
	
EndProcedure

&AtClient
Procedure WhenChangingSplitDecryptionSwitch(SwitchValue)

	If DecryptionSwitch = 0 Then
		If Object.Allocation.Count() = 0 Then
			NewRow = Object.Allocation.Add();
			NewRow.ZoomRatio = 1;
			FillDefaultAttributes(NewRow);
			RowID = NewRow.GetID();
		ElsIf Object.Allocation.Count() = 1 Then
			If Items.StageCompletionDistribution.CurrentRow = Undefined Then
				RowID = Object.Allocation[0].GetID();
			EndIf;
			If Object.Allocation[0].ZoomRatio = 0 Then
				Object.Allocation[0].ZoomRatio = 1;
			EndIf;
		EndIf;
		Items.StageCompletionDistribution.CurrentRow = RowID;
		Items.AllocationByResearch.CurrentRow = RowID;
	EndIf;

	If DecryptionSwitch = 0
			And Object.Allocation.Count() > 1 Then
		MessageText = NStr("vi = 'Chuyển sang chế độ không phân chia là không thể nếu có nhiều hơn một hàng được nhập vào phần bảng.';
							|ru = 'Переключение в режим без разбиения невозможно, если в табличной части введено более одной строки.';
							|en = 'Cannot switch to no-split mode if more than one row is entered in the table.'; fa = 'Cannot switch to no-split mode if more than one row is entered in the table.';
							|it = 'Impossibile passare alla modalità senza la partizione, se nella tabella è stata inserita più di una riga!';
							|pl = 'Przełączenie do trybu bez podziału jest niemożliwe, jeśli w sekcji tabelarycznej wprowadzono więcej niż jeden wiersz.';
							|tr = 'Tablolara birden fazla satır girildiyse bölmesiz moda bağlanılamaz!'");
		CommonClient.MessageToUser(MessageText);
		SwitchValue = 1;
	EndIf;

EndProcedure

&AtClient
Procedure ConfigureDisplayOfFormElementSuggestions()

	If Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.CompletionOfResearchAndDevelopmentStages")
		Or (Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.RecognitionOfResearchExpenses")
			And ResearchRecognitionSettings.FindRows(New Structure("AccountingPolicy", "Accounting")).Count() > 0) Then
		ToolTip = NStr("vi = '<trùng với kế toán doanh nghiệp>';
						|ru = '<совпадает с бухгалтерским учетом>';
						|en = '<matches local accounting>'; fa = '<matches local accounting>';
						|it = '<coincide con la contabilità generale>';
						|pl = '<jest zgodne z ewidencją księgową>';
						|tr = '<muhasebe ile örtüşüyor>'");
	Else
		ToolTip = "";
	EndIf;

	Items.TypeOfExpenseRecognitionForStageCompletion.InputHint = ToolTip;
	If Items.StageCompletionDistribution.CurrentData <> Undefined Then
		If Not ValueIsFilled(Items.StageCompletionDistribution.CurrentData.ExpenseRecognitionTypeMA) Then
			Items.CostAnalysisAtTheEndOfTheStage.InputHint = ToolTip;
			Items.UUPoResearchCostAnalysis.InputHint = ToolTip;
			Items.ItemOfExpenditureAtTheEndOfTheStage.InputHint = ToolTip;
			Items.ItemOfExpenditureOfTheUUPoForResearch.InputHint = ToolTip;
		Else
			Items.CostAnalysisAtTheEndOfTheStage.InputHint = "";
			Items.UUPoResearchCostAnalysis.InputHint = "";
			Items.ItemOfExpenditureAtTheEndOfTheStage.InputHint = "";
			Items.ItemOfExpenditureOfTheUUPoForResearch.InputHint = "";
		EndIf;
	EndIf;

EndProcedure

&AtClient
Procedure ConfigureDisplayOfExpenseAllocation(Form)

	If Form.Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.CompletionOfResearchAndDevelopmentStages") Then
		Form.Items.AllocationPages.CurrentPage = ?(Form.DecryptionSwitch = 0, Form.Items.PageAllocationOfStageCompletionWithoutSplitting, Form.Items.PageAllocationOfStageCompletionAsList);
	Else
		Form.Items.AllocationPages.CurrentPage = ?(Form.DecryptionSwitch = 0, Form.Items.PageResearchExpensesAllocationWithoutSplitting, Form.Items.PageResearchExpensesAllocationAsList);
	EndIf;

EndProcedure

&AtClient
Procedure GenerateListOfTypesOfRecognitionTa(TagName, KindOfRecognitionAC)

	ListOfConfessionsTa = GetKindsOfRecognitionTa(KindOfRecognitionAC);

	Items[TagName].ChoiceList.LoadValues(ListOfConfessionsTa);

EndProcedure

&AtServer
Function GetTypesOfRecognitionBU_UU()
	
	ListOfTypesOfRecognition = New Array();
	
	If Object.BusinessOperation = Enums.BusinessTransactions.CompletionOfResearchAndDevelopmentStages Then
		ListOfTypesOfRecognition.Add(Enums.RDExpenseRecognitionTypes.RecognitionAsIntangibleAssets);
		ListOfTypesOfRecognition.Add(Enums.RDExpenseRecognitionTypes.MoveToAnotherTheme);
		ListOfTypesOfRecognition.Add(Enums.RDExpenseRecognitionTypes.CloseTopic);
		ListOfTypesOfRecognition.Add(Enums.RDExpenseRecognitionTypes.DoNotRecognizeExpenses);
			
	Else
		ListOfTypesOfRecognition.Add(Enums.RDExpenseRecognitionTypes.RecognitionAsCurrentExpenses);
	EndIf;

	Return ListOfTypesOfRecognition;

EndFunction

&AtServerNoContext
Function GetKindsOfRecognitionTa(KindOfRecognitionAC)
	
	ListOfConfessionsTa = New Array();

	If KindOfRecognitionAC = Enums.RDExpenseRecognitionTypes.RecognitionAsIntangibleAssets Then
		ListOfConfessionsTa.Add(Enums.RDExpenseRecognitionTypes.RecognitionAsIntangibleAssets);
		ListOfConfessionsTa.Add(Enums.RDExpenseRecognitionTypes.RecognitionAsDeferredExpenses);
	ElsIf KindOfRecognitionAC = Enums.RDExpenseRecognitionTypes.MoveToAnotherTheme Then
		ListOfConfessionsTa.Add(Enums.RDExpenseRecognitionTypes.MoveToAnotherTheme);
		ListOfConfessionsTa.Add(Enums.RDExpenseRecognitionTypes.RecognitionAsCurrentExpenses);
	ElsIf KindOfRecognitionAC = Enums.RDExpenseRecognitionTypes.CloseTopic
			Or KindOfRecognitionAC = Enums.RDExpenseRecognitionTypes.DoNotRecognizeExpenses Then
		ListOfConfessionsTa.Add(Enums.RDExpenseRecognitionTypes.RecognitionAsCurrentExpenses);
	Else
		ListOfConfessionsTa.Add(Enums.RDExpenseRecognitionTypes.RecognitionAsIntangibleAssets);
		ListOfConfessionsTa.Add(Enums.RDExpenseRecognitionTypes.MoveToAnotherTheme);
		ListOfConfessionsTa.Add(Enums.RDExpenseRecognitionTypes.RecognitionAsCurrentExpenses);
		ListOfConfessionsTa.Add(Enums.RDExpenseRecognitionTypes.RecognitionAsDeferredExpenses);
	EndIf;

	Return ListOfConfessionsTa;

EndFunction

&AtClient
Procedure CheckTypeOfCostAllocationTa()

	ListOfConfessionsTa = GetKindsOfRecognitionTa(Items.StageCompletionDistribution.CurrentData.ExpenseRecognitionTypeAC);

	If Not Items.StageCompletionDistribution.CurrentData.ExpenseRecognitionTypeTA.IsEmpty() Then
		If ListOfConfessionsTa.Find(Items.StageCompletionDistribution.CurrentData.ExpenseRecognitionTypeTA) = Undefined Then
			Items.StageCompletionDistribution.CurrentData.ExpenseRecognitionTypeTA = PredefinedValue("Enum.RDExpenseRecognitionTypes.EmptyRef");
			Items.StageCompletionDistribution.CurrentData.ExpenseItemTaxAccounting = Undefined;
			Items.StageCompletionDistribution.CurrentData.ExpensesDimensionTaxAccounting = Undefined;
		EndIf;
	EndIf;

	If ListOfConfessionsTa.Count() = 1 Then
		Items.StageCompletionDistribution.CurrentData.ExpenseRecognitionTypeTA = ListOfConfessionsTa[0];
	EndIf;

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

&AtServer
Procedure PropertiesExecuteDeferredInitialization()

	PropertyManager.FillAdditionalAttributesInForm(ThisObject);

EndProcedure

// End StandardSubsystems.Properties
&AtServer
Procedure SetConditionalAppearance()

	ConditionalAppearanceItem = ConditionalAppearance.Items.Add();

	ItemField = ConditionalAppearanceItem.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.AllocationByResearchLineOfBusiness.Name);

	ItemFilter = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Allocation.LineOfBusiness");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Catalogs.LinesOfBusiness.EmptyRef();

	ConditionalAppearanceItem.Appearance.SetParameterValue("TextColor", StyleColors.InaccessibleCellTextColor);
	ConditionalAppearanceItem.Appearance.SetParameterValue("Text", NStr("vi = '<mảng hoạt động hiện tại>';
																		|ru = '<текущее направление>';
																		|en = '<current direction>'; fa = '<جهت جاری>';
																		|it = '<destinazione corrente>';
																		|pl = '<aktualny kierunek>';
																		|tr = '<mevcut yön>'"));
	ConditionalAppearanceItem.Appearance.SetParameterValue("MarkIncomplete", False);

	ConditionalAppearanceItem = ConditionalAppearance.Items.Add();

	ItemField = ConditionalAppearanceItem.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.AllocationByResearchDepartment.Name);

	ItemFilter = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Allocation.Department");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Catalogs.BusinessStructure.EmptyRef();

	ConditionalAppearanceItem.Appearance.SetParameterValue("TextColor", StyleColors.InaccessibleCellTextColor);
	ConditionalAppearanceItem.Appearance.SetParameterValue("Text", NStr("vi = '<bộ phận hiện tại>';
																		|ru = '<текущее подразделение>';
																		|en = '<current department>'; fa = '<current department>';
																		|it = '<reparto corrente>';
																		|pl = '<aktualny dział>';
																		|tr = '<mevcut departman>'"));
	ConditionalAppearanceItem.Appearance.SetParameterValue("MarkIncomplete", False);

	If Object.BusinessOperation = Enums.BusinessTransactions.CompletionOfResearchAndDevelopmentStages 
		Or (Object.BusinessOperation = Enums.BusinessTransactions.RecognitionOfResearchExpenses
			And ResearchRecognitionSettings.FindRows(New Structure("AccountingPolicy", "Accounting")).Count() > 0) Then
				
		ConditionalAppearanceItem = ConditionalAppearance.Items.Add();
		
		ItemField = ConditionalAppearanceItem.Fields.Items.Add();
		ItemField.Field = New DataCompositionField(Items.TheDistributionPhaseIsCompleteViewOfTheRecognitionOfExpensesUU.Name);
		ItemField = ConditionalAppearanceItem.Fields.Items.Add();
		ItemField.Field = New DataCompositionField(Items.DistributionOfTheCompletionOfTheStageItemOfExpenditureOfTheUU.Name);
		ItemField = ConditionalAppearanceItem.Fields.Items.Add();
		ItemField.Field = New DataCompositionField(Items.DistributionOfTheCompletionOfTheUUCostAnalysisStage.Name);
		ItemField = ConditionalAppearanceItem.Fields.Items.Add();
		ItemField.Field = New DataCompositionField(Items.DistributionByResearchItemOfExpenditureOfTheUU.Name);
		ItemField = ConditionalAppearanceItem.Fields.Items.Add();
		ItemField.Field = New DataCompositionField(Items.DistributionByResearchUUCostAnalysis.Name);
		
		ItemFilter = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
		ItemFilter.LeftValue = New DataCompositionField("Object.Allocation.ExpenseRecognitionTypeMA");
		ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
		
		ConditionalAppearanceItem.Appearance.SetParameterValue("TextColor", StyleColors.InaccessibleCellTextColor);
		ConditionalAppearanceItem.Appearance.SetParameterValue("Text", NStr("vi = '<trùng với kế toán doanh nghiệp>';
																			|ru = '<совпадает с бухгалтерским учетом>';
																			|en = '<matches local accounting data>'; fa = '<matches local accounting data>';
																			|it = '<coincide con la contabilità generale>';
																			|pl = '<jest zgodne z ewidencją księgową>';
																			|tr = '<muhasebe ile örtüşüyor>'"));
	EndIf;
EndProcedure

&AtServer
Procedure FillInListsForSelectingTypesOfExpenseRecognition()

#Region BU_UU
	ChoiceList = GetTypesOfRecognitionBU_UU();

	Items.TypeOfRecognitionOfExpensesAfterCompletionOfTheStage.ChoiceList.Clear();
	Items.TypeOfRecognitionOfExpensesAfterCompletionOfTheStage.ChoiceList.LoadValues(ChoiceList);

	Items.TheDistributionPhaseIsCompleteTheFormOfRecognitionOfTheCostsOfBU.ChoiceList.Clear();
	Items.TheDistributionPhaseIsCompleteTheFormOfRecognitionOfTheCostsOfBU.ChoiceList.LoadValues(ChoiceList);

	Items.TypeOfExpenseRecognitionForStageCompletion.ChoiceList.Clear();
	Items.TypeOfExpenseRecognitionForStageCompletion.ChoiceList.LoadValues(ChoiceList);

	Items.TheDistributionPhaseIsCompleteViewOfTheRecognitionOfExpensesUU.ChoiceList.Clear();
	Items.TheDistributionPhaseIsCompleteViewOfTheRecognitionOfExpensesUU.ChoiceList.LoadValues(ChoiceList);

#EndRegion

#Region TA

	KindOfRecognitionAC = ?(Object.Allocation.Count() <> 0, Object.Allocation[0].ExpenseRecognitionTypeAC, Undefined);

	ChoiceList = GetKindsOfRecognitionTa(KindOfRecognitionAC);

	Items.TypeOfExpenseRecognitionAfterCompletionOfTheStage.ChoiceList.Clear();
	Items.TypeOfExpenseRecognitionAfterCompletionOfTheStage.ChoiceList.LoadValues(ChoiceList);
	
	Items.TheDistributionPhaseIsCompleteViewOfTheRecognitionOfExpensesWELL.ChoiceList.Clear();
	Items.TheDistributionPhaseIsCompleteViewOfTheRecognitionOfExpensesWELL.ChoiceList.LoadValues(ChoiceList);

#EndRegion

EndProcedure

&AtClient
Procedure UpdateParametersForSelectingExpenseItem(Item, RecognitionType = Undefined)
	
	RDExpensesAccountingClient.SetParametersForSelectingExpenseItem(Item, RecognitionType);
	
EndProcedure

&AtClient
Procedure ClearExpenseItem(TagName, TableName)
	
	If StrFind(TagName, "ACC") Then
		Items[TableName].CurrentData.ExpenseItemAccounting = Undefined;
		Items[TableName].CurrentData.ExpensesDimensionAccounting = Undefined;
	ElsIf StrFind(TagName, "TA") Then
		Items[TableName].CurrentData.ExpenseItemTaxAccounting = Undefined;
		Items[TableName].CurrentData.ExpensesDimensionTaxAccounting = Undefined;
	Else
		Items[TableName].CurrentData.ExpenseItemManagementAccounting = Undefined;
		Items[TableName].CurrentData.ExpensesDimensionManagementAccounting = Undefined;
	EndIf;
	
	IncomeAndExpensesClientServer.AssetRefOnChange(ThisObject, Items[TagName]);
	
	ConfigureDisplayOfFormElementSuggestions();
	
EndProcedure

&AtServer
Procedure ConfigureBusinessOperations()
	
	BusinessTransactions = New Array();
	BusinessTransactions.Add(Enums.BusinessTransactions.CompletionOfResearchAndDevelopmentStages);
	
	If Not Object.Organization.IsEmpty() Then
		
		Companies = New Array();
		Companies.Add(Object.Organization);
		
		ResearchRecognitionSettings.Load(
			RDExpensesAccounting.SettingsForRecognizingCompanyResearchExpenses(Object.Date, Companies));
		
		If ResearchRecognitionSettings.Count()>0 Then
			BusinessTransactions.Add(Enums.BusinessTransactions.RecognitionOfResearchExpenses);
		EndIf;
	Else
		BusinessTransactions.Add(Enums.BusinessTransactions.RecognitionOfResearchExpenses);
		ResearchRecognitionSettings.Clear();
	EndIf;
	
	Items.BusinessOperation.ChoiceList.LoadValues(BusinessTransactions);
	
	If Parameters.Key.IsEmpty() And BusinessTransactions.Find(Object.BusinessOperation) = Undefined Then
		Object.BusinessOperation = BusinessTransactions[0];
	EndIf;
	
	If BusinessTransactions.Count() = 1 Then
		Items.BusinessOperation.Visible = False;
	Else
		Items.BusinessOperation.Visible = True;
	EndIf;
	
EndProcedure

&AtServer
Procedure ChangeHeadersForBusinessTransactions()
	
	AutoTitle = True;
	Title = "";

	If ValueIsFilled(Object.BusinessOperation) Then
		
		AutoTitle = False;
		If ValueIsFilled(Object.Ref) Then
			Template = NStr("vi = '%1 %2 ngày %3';
							|ru = '%1 %2 от %3';
							|en = '%1 %2 dated %3'; fa = '%1 %2 dated %3';
							|it = '%1 %2 del %3';
							|pl = '%1 %2 z dnia %3';
							|tr = '%3 tarihli %1 %2'");
		Else
			Template = NStr("vi = '%1 (tạo mới)';
							|ru = '%1 (создание)';
							|en = '%1 (Create)'; fa = '%1 (Create)';
							|it = '%1 (creazione)';
							|pl = '%1 (utworzenie)';
							|tr = '%1 (oluşturma)'");
		EndIf;
		Title = StringFunctionsClientServer.SubstituteParametersToString(
			Template, Object.BusinessOperation, Object.Number, Object.Date);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ChooseTheme(Item, MultipleChoice)
	
	SelectionParameters_1 = New Structure;
	If Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.RecognitionOfResearchExpenses") Then
		SelectionParameters_1.Insert("Development", False);
	EndIf;

	FormParameters = New Structure;
	FormParameters.Insert("Filter", SelectionParameters_1);
	FormParameters.Insert("MultipleChoice", MultipleChoice);

	OpenForm("Catalog.RDTopicsStages.Form.ChoiceForm", FormParameters, Item, , , , , FormWindowOpeningMode.LockOwnerWindow);
	
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
