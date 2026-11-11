
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetConditionalAppearance();
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(Object, ThisObject);
	
	If Not ValueIsFilled(Object.Ref) Then
		OnReadCreateAtServer();
	EndIf;
	
	ItemsAndDimensionsSelectionParameters = Documents.IntangibleAssetsInitialRecognition2_4.ItemsAndDimensionsSelectionParameters();
	IncomeAndExpensesServer.OnCreateAtServer(ThisObject, ItemsAndDimensionsSelectionParameters);
	
	#Region StandardSubsystems
	
	// StandardSubsystems.ObjectsVersioning
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.ObjectsVersioning
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	// StandardSubsystems.Properties
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("ItemForPlacementName", "GroupAdditionalAttributes");
	AdditionalParameters.Insert("DeferredInitialization", True);
	PropertyManager.OnCreateAtServer(ThisObject, AdditionalParameters);
	// End StandardSubsystems.Properties
	
	// StandardSubsystems.FilesOperations
	FilesHyperlink = FilesOperations.FilesHyperlink();
	FilesHyperlink.Location = "CommandBar";
	FilesOperations.OnCreateAtServer(ThisObject, FilesHyperlink);
	// End StandardSubsystems.FilesOperations

	FormEvents.OnCreateAtServer(ThisObject, Cancel, StandardProcessing);
	
	#EndRegion
	
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
	
	PeriodClosingDates.ObjectOnReadAtServer(ThisObject, CurrentObject);
	
	OnReadCreateAtServer();
	
	ItemsAndDimensionsSelectionParameters = Documents.IntangibleAssetsInitialRecognition2_4.ItemsAndDimensionsSelectionParameters();
	IncomeAndExpensesServer.OnReadAtServer(ThisObject, ItemsAndDimensionsSelectionParameters);
	
	FormEvents.OnReadAtServer(ThisObject, CurrentObject);
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	// End StandardSubsystems.AttachableCommands
	
	// StandardSubsystems.Properties
	PropertyManager.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.Properties
	
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	
	WriteParameters.Insert("NotificationDocumentKeys", OperationsWithDocumentJournalsClient.GetKeyParametersForDocument(
		Object.Ref, Object.Date, Object.BusinessOperation));
	Notify("Write_IntangibleAssetsInitialRecognition2_4", WriteParameters, Object.Ref);
	TMCommonUseClient.NotifyAboutEntryOfDocumentInJournal();
	NonCurrentAssetsClient.NotifyAboutEntryOfDocumentInJournalOfIA();
	
	ConfigurationModificationClientOverridable.AfterWrite(ThisObject, WriteParameters);

	IntangibleAssetsInitialRecognitionClientLocalization.AfterWrite(Object);
	
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
	
	Items.CommentPage.Picture = CommonClientServer.CommentPicture(Object.Comment);
	
	FillInInformationInBasement();
	
	IncomeAndExpensesServer.AfterWriteAtServer(ThisObject);
	
	IntangibleAssetsInitialRecognitionLocalization.AfterWriteAtServer(ThisObject);
	
	ConfigurationModificationOverridable.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	
	FormEvents.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	
EndProcedure

&AtClient
Procedure BeforeWrite(Cancel, WriteParameters)
	
	FormEventsClient.BeforeWrite(ThisObject, Cancel, WriteParameters);
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If EventName = "Write_IntangibleAssetsInitialRecognition2_4" 
		And Source <> Object.Ref Then
		FillInInformationInBasement();
	EndIf;
	
	// StandardSubsystems.Properties 
	If PropertyManagerClient.ProcessNotifications(ThisObject, EventName, Parameter) Then
		UpdateAdditionalAttributesItems();
		PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
	EndIf;
	// End StandardSubsystems.Properties

	FormEventsClient.NotificationProcessing(ThisObject, EventName, Parameter, Source);
	
	// StandardSubsystems.FilesOperations
	FilesOperationsClient.NotificationProcessing(ThisObject, EventName);
	// End StandardSubsystems.FilesOperations

EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	// StandardSubsystems.Properties
	PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
	// End StandardSubsystems.Properties
	
	// StandardSubsystems.FilesOperations
	FilesOperationsClient.OnOpen(ThisObject, Cancel);
	// End StandardSubsystems.FilesOperations

EndProcedure

&AtClient
Procedure URLProcessing(FormattedStringURL, StandardProcessing)
	If FormattedStringURL = "SettingAccountingOrderTa" Then
		Modified = True;
		StandardProcessing = False;
		Object.AccountingProcedureTA = RecommendedTaxAccountingProcedure;
		ConfigureDependentFormElementsOnClientOnServer(ThisObject, "AccountingProcedureTA");
	EndIf;
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

#EndRegion

#Region FormHeaderItemsEventHandlers

#Region PageGeneral

&AtClient
Procedure PostInAccountingOnChange(Item)
	
	If Not Object.PostInAccounting And Not Object.RecordInTA And Not Object.RecordInManAccounting Then
		Object.PostInAccounting = True;
	EndIf;
	
	Object.RecordInLocalAccounting = Object.PostInAccounting Or Object.RecordInTA;

	ConfigureDependentFormElements("RecordInLocalAccounting,PostInAccounting");

EndProcedure

&AtClient
Procedure RecordInTAOnChange(Item)
	
	If Not Object.PostInAccounting And Not Object.RecordInTA And Not Object.RecordInManAccounting Then
		Object.RecordInTA = True;
	EndIf;

	Object.RecordInLocalAccounting = Object.PostInAccounting Or Object.RecordInTA;

	ConfigureDependentFormElements("RecordInLocalAccounting,RecordInTA");

EndProcedure

&AtClient
Procedure RecordInManAccountingOnChange(Item)
	
	If Not Object.PostInAccounting And Not Object.RecordInTA And Not Object.RecordInManAccounting Then
		Object.RecordInManAccounting = True;
	EndIf;

	ConfigureDependentFormElements("RecordInManAccounting");

EndProcedure

&AtClient
Procedure DateOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi

	NonCurrentAssetsClient.SetCurrentTimeForLastDate(Object.Date);
	
	ConfigureDependentFormElementsOnServer(Item.Name);
	
EndProcedure

&AtClient
Procedure BusinessOperationOnChange(Item)
	
	ChangedBankingDetails = "BusinessOperation";
	
	If Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.IntangibleAssetsInitialRecognitionByInventoryCount")
		And Object.KindOfAccountingObject = PredefinedValue("Enum.IntangibleAssetsAccountingItemKinds.RDExpenses") Then
			
		Object.KindOfAccountingObject = PredefinedValue("Enum.IntangibleAssetsAccountingItemKinds.IntangibleAsset");
		Object.FinancialAccountingGroup = Undefined;
		ChangedBankingDetails = ChangedBankingDetails + ",KindOfAccountingObject";
		
	EndIf;
	
	If Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.IntangibleAssetsInitialRecognitionByInventoryCount") Then
		
		If Object.AccountingProcedureAC = PredefinedValue("Enum.FixedAssetValueRegistrationProcedure.DoNotTakeIntoAccountIncludeInExpenses") Then
			Object.AccountingProcedureAC = PredefinedValue("Enum.FixedAssetValueRegistrationProcedure.AccrueDepreciationOrAmortization");
			ChangedBankingDetails = ChangedBankingDetails + ",AccountingProcedureAC";
		EndIf;
		
		If Object.AccountingProcedureTA = PredefinedValue("Enum.FixedAssetValueRegistrationProcedure.DoNotTakeIntoAccountIncludeInExpenses") Then
			Object.AccountingProcedureTA = PredefinedValue("Enum.FixedAssetValueRegistrationProcedure.IncludeInExpensesOnRecognition");
			ChangedBankingDetails = ChangedBankingDetails + ",AccountingProcedureTA";
		EndIf;
		
		If Object.AccountingProcedureMA = PredefinedValue("Enum.FixedAssetValueRegistrationProcedure.DoNotTakeIntoAccountIncludeInExpenses") Then
			Object.AccountingProcedureMA = PredefinedValue("Enum.FixedAssetValueRegistrationProcedure.AccrueDepreciationOrAmortization");
			ChangedBankingDetails = ChangedBankingDetails + ",AccountingProcedureMA";
		EndIf;
		
	EndIf;
	
	ConfigureDependentFormElements(ChangedBankingDetails);
	
EndProcedure

&AtClient
Procedure OrganizationOnChange(Item)
	
	OrganizationWhenChangedOnServer();
	
EndProcedure

&AtClient
Procedure DepartmentOnChange(Item)

	ConfigureDependentFormElements(Item.Name);
	
EndProcedure

&AtClient
Procedure KindOfAccountingObjectOnChange(Item)
	
	ConfigureDependentFormElementsOnServer("KindOfAccountingObject");
	
EndProcedure

&AtClient
Procedure IntangibleAssetOnChange(Item)
	
	FillInPreliminaryCost(False);
	
EndProcedure

&AtClient
Procedure InitialCostLocalAccountingOnChange(Item)
	
	InitialCostOfBUWhenChangingOnServer();
	
EndProcedure

&AtClient
Procedure InitialCostMAOnChange(Item)
	
	InitialCostOfMAWhenChangedOnServer();
	
EndProcedure

&AtClient
Procedure DocumentInformationInAnotherAccountingURLProcessing(Item, FormattedStringURL, StandardProcessing)
	
	If FormattedStringURL = "#CreateDocument" Then
		StandardProcessing = False;
		FormParameters = New Structure;
		FormParameters.Insert("Basis", Object.Ref);
		OpenForm("Document.IntangibleAssetsInitialRecognition2_4.ObjectForm", FormParameters);
	EndIf;
	
EndProcedure

&AtClient
Procedure GeneratedDocumentOnChange(Item)
	
	If Object.GeneratedDocument Then
		
		ListFilter = New Structure;
		ListFilter.Insert("Posted", True);
		
		If ValueIsFilled(Object.Organization) Then
			ListFilter.Insert("Organization", Object.Organization);
		EndIf;
		
		If ValueIsFilled(Object.Department) Then
			ListFilter.Insert("Department", Object.Department);
		EndIf;
		
		CallbackDescription = New CallbackDescription("GeneratedDocumentOnChangeCompletion", ThisObject);
		
		FormParameters = New Structure;
		FormParameters.Insert("Filter", ListFilter);
		OpenForm("Document.IntangibleAssetsPhysicalCount.ChoiceForm", FormParameters,,,,, CallbackDescription);
		
	Else
		Object.DocumentBasis = Undefined;
	EndIf; 
	
EndProcedure

#EndRegion

#Region AccountingParametersPage

&AtClient
Procedure UsefulLifeAccountingOnChange(Item)
	
	WhenChangingPeriodOfUse("UsefulLifeAccounting", True);
	
EndProcedure

&AtClient
Procedure UsefulLifeManagementAccountingOnChange(Item)
	
	WhenChangingPeriodOfUse("UsefulLifeManagementAccounting", True);
	
EndProcedure

&AtClient
Procedure AccountingProcedureACOnChange(Item)
	
	OrderOfAccountingForBUWhenChangingOnServer();
	
EndProcedure

&AtClient
Procedure DepreciationMethodAccountingOnChange(Item)

	ConfigureDependentFormElementsOnClientOnServer(ThisObject, Item.Name);
	
EndProcedure

&AtClient
Procedure AccountingProcedureMAOnChange(Item)
	
	AccountingProcedureForMAWhenChangingOnServer();
	
EndProcedure

&AtClient
Procedure DepreciationAccrualMethodManagementAccountingOnChange(Item)
	
	ConfigureDependentFormElementsOnClientOnServer(ThisObject, Item.Name);
	
EndProcedure

#EndRegion

#Region PageExpenseRecord

&AtClient
Procedure ExpenseItemAccountingOnChange(Item)

	IncomeAndExpensesClientServer.AssetRefOnChange(ThisObject, Item);
	
	If ValueIsFilled(Object.ExpenseRecordMethodAC) Then
		Object.ExpenseRecordMethodAC = PredefinedValue("Catalog.WaysToReflectExpenses.EmptyRef");
	EndIf;
	
	ConfigureDependentFormElements("ExpenseRecordMethodAC,ExpenseItemAccounting");
	
EndProcedure

&AtClient
Procedure ExpenseItemAccountingStartChoice(Item, ChoiceData, StandardProcessing)
	
	IncomeAndExpensesClient.StartArticleSelection(ThisObject, Item, StandardProcessing);

EndProcedure

&AtClient
Procedure ExpensesDimensionAccountingOnChange(Item)
	
	If ValueIsFilled(Object.ExpenseRecordMethodAC) Then
		Object.ExpenseRecordMethodAC = PredefinedValue("Catalog.WaysToReflectExpenses.EmptyRef");
		ConfigureDependentFormElements("ExpenseRecordMethodAC");
	EndIf;
	
EndProcedure

&AtClient
Procedure ExpensesDimensionAccountingAutoComplete(Item, Text, ChoiceData, DataGetParameters, Waiting, StandardProcessing)
	
	IncomeAndExpensesClient.AutoSelectionOfExpenseAnalytics(ThisObject, Item, Text, ChoiceData, DataGetParameters, StandardProcessing);

EndProcedure

&AtClient
Procedure ExpensesDimensionAccountingTextEditEnd(Item, Text, ChoiceData, DataGetParameters, StandardProcessing)
	
	IncomeAndExpensesClient.EndOfCostAnalyticsTextEntry(ThisObject, Item, Text, ChoiceData, DataGetParameters, StandardProcessing);

EndProcedure

&AtClient
Procedure ExpensesDimensionAccountingStartChoice(Item, ChoiceData, StandardProcessing)
	
	IncomeAndExpensesClient.StartSelectingExpenseAnalytics(ThisObject, Item, StandardProcessing);

EndProcedure

&AtClient
Procedure ExpenseItemManagementAccountingOnChange(Item)
	
	IncomeAndExpensesClientServer.AssetRefOnChange(ThisObject, Items.ExpenseItemManagementAccounting);
	
	If ValueIsFilled(Object.MethodForReflectingMaExpenses) Then
		Object.MethodForReflectingMaExpenses = PredefinedValue("Catalog.WaysToReflectExpenses.EmptyRef");
	EndIf;
	
	ConfigureDependentFormElements("MethodForReflectingMaExpenses,ExpenseItemManagementAccounting");
	
EndProcedure

&AtClient
Procedure ExpenseItemManagementAccountingStartChoice(Item, ChoiceData, StandardProcessing)
	
	IncomeAndExpensesClient.StartArticleSelection(ThisObject, Item, StandardProcessing);
	
EndProcedure

&AtClient
Procedure ExpensesDimensionManagementAccountingOnChange(Item)

	If ValueIsFilled(Object.MethodForReflectingMaExpenses) Then
		Object.MethodForReflectingMaExpenses = PredefinedValue("Catalog.WaysToReflectExpenses.EmptyRef");
		ConfigureDependentFormElements("MethodForReflectingMaExpenses");
	EndIf;

EndProcedure

&AtClient
Procedure ExpensesDimensionManagementAccountingStartChoice(Item, ChoiceData, StandardProcessing)
	
	IncomeAndExpensesClient.StartSelectingExpenseAnalytics(ThisObject, Item, StandardProcessing);
	
EndProcedure

&AtClient
Procedure ExpensesDimensionManagementAccountingAutoComplete(Item, Text, ChoiceData, DataGetParameters, Waiting, StandardProcessing)
	
	IncomeAndExpensesClient.AutoSelectionOfExpenseAnalytics(ThisObject, Item, Text, ChoiceData, DataGetParameters, StandardProcessing);
	
EndProcedure

&AtClient
Procedure ExpensesDimensionManagementAccountingTextEditEnd(Item, Text, ChoiceData, DataGetParameters, StandardProcessing)
	
	IncomeAndExpensesClient.EndOfCostAnalyticsTextEntry(ThisObject, Item, Text, ChoiceData, DataGetParameters, StandardProcessing);
	
EndProcedure

&AtClient
Procedure ExpenseRecordMethodACOnChange(Item)
	
	ChangedBankingDetails = "ExpenseRecordMethodAC,ExpenseItemAccounting,BusinessUnitAndLineOfBusinessMatchAccountingDataBookkeeping";
	
	NonCurrentAssetsClientServer.FillInAccordingToMethodOfReflectingExpenses(
		Object.ExpenseRecordMethodAC, 
		Object.ExpenseItemAccounting, 
		Object.ExpensesDimensionAccounting, 
		Object.DepartmentACC, 
		Object.LineOfBusinessBookkeeping, 
		Object.BusinessUnitAndLineOfBusinessMatchAccountingDataBookkeeping);
	
	If ValueIsFilled(Object.ExpenseRecordMethodAC) Then
		IncomeAndExpensesClientServer.AssetRefOnChange(ThisObject, Items.ExpenseItemAccounting);
	EndIf;
	
	ConfigureDependentFormElements(ChangedBankingDetails);
	
EndProcedure

&AtClient
Procedure MethodForReflectingMaExpensesOnChange(Item)

	NonCurrentAssetsClientServer.FillInAccordingToMethodOfReflectingExpenses(
		Object.MethodForReflectingMaExpenses, 
		Object.ExpenseItemManagementAccounting, 
		Object.ExpensesDimensionManagementAccounting, 
		Object.BusinessUnitManagementAccounting, 
		Object.LineOfBusinessManagementAccounting, 
		Object.BusinessUnitAndLineOfBusinessMatchAccountingDataManagementAccounting);
	
	If ValueIsFilled(Object.MethodForReflectingMaExpenses) Then
		IncomeAndExpensesClientServer.AssetRefOnChange(ThisObject, Items.ExpenseItemManagementAccounting);
	EndIf;
	
	ConfigureDependentFormElements("MethodForReflectingMaExpenses,ExpenseItemManagementAccounting,BusinessUnitAndLineOfBusinessMatchAccountingDataManagementAccounting");

EndProcedure

&AtClient
Procedure DepartmentACCOnChange(Item)
	
	If ValueIsFilled(Object.ExpenseRecordMethodAC) Then
		Object.ExpenseRecordMethodAC = PredefinedValue("Catalog.WaysToReflectExpenses.EmptyRef");
	EndIf;
	
	ConfigureDependentFormElements("ExpenseRecordMethodAC,DepartmentACC");
	
EndProcedure

&AtClient
Procedure LineOfBusinessBookkeepingOnChange(Item)
	
	If ValueIsFilled(Object.ExpenseRecordMethodAC) Then
		Object.ExpenseRecordMethodAC = PredefinedValue("Catalog.WaysToReflectExpenses.EmptyRef");
	EndIf;

	ConfigureDependentFormElements("ExpenseRecordMethodAC,LineOfBusinessBookkeeping");

EndProcedure

&AtClient
Procedure BusinessUnitManagementAccountingOnChange(Item)
	
	If ValueIsFilled(Object.MethodForReflectingMaExpenses) Then
		Object.MethodForReflectingMaExpenses = PredefinedValue("Catalog.WaysToReflectExpenses.EmptyRef");
	EndIf;

	ConfigureDependentFormElements("MethodForReflectingMaExpenses,BusinessUnitManagementAccounting");

EndProcedure

&AtClient
Procedure LineOfBusinessManagementAccountingOnChange(Item)
	
	If ValueIsFilled(Object.MethodForReflectingMaExpenses) Then
		Object.MethodForReflectingMaExpenses = PredefinedValue("Catalog.WaysToReflectExpenses.EmptyRef");
	EndIf;

	ConfigureDependentFormElements("MethodForReflectingMaExpenses,LineOfBusinessManagementAccounting");
	
EndProcedure

&AtClient
Procedure BusinessUnitAndLineOfBusinessMatchAccountingDataBookkeepingOnChange(Item)
	
	If ValueIsFilled(Object.ExpenseRecordMethodAC) Then
		Object.ExpenseRecordMethodAC = PredefinedValue("Catalog.WaysToReflectExpenses.EmptyRef");
	EndIf;

	ConfigureDependentFormElements("ExpenseRecordMethodAC,BusinessUnitAndLineOfBusinessMatchAccountingDataBookkeeping");
	
EndProcedure

&AtClient
Procedure BusinessUnitAndLineOfBusinessMatchAccountingDataManagementAccountingOnChange(Item)
	
	If ValueIsFilled(Object.MethodForReflectingMaExpenses) Then
		Object.MethodForReflectingMaExpenses = PredefinedValue("Catalog.WaysToReflectExpenses.EmptyRef");
	EndIf;

	ConfigureDependentFormElements("MethodForReflectingMaExpenses,BusinessUnitAndLineOfBusinessMatchAccountingDataManagementAccounting");

EndProcedure

&AtClient
Procedure TransferExpensesToAnotherCompanyOnChange(Item)

	If Not Object.TransferExpensesToAnotherCompany Then
		Object.CompanyRecipientOfExpenses = PredefinedValue("Catalog.Companies.EmptyRef");
	EndIf;

	ConfigureDependentFormElements(Item.Name);
	
EndProcedure

#EndRegion

#Region Other

&AtClient
Procedure Attachable_OnChangeAttribute(Item)

	IntangibleAssetsInitialRecognitionClientLocalization.OnChangeAttribute(Item, ThisObject);

EndProcedure

&AtClient
Procedure Attachable_StartChoice(Item, ChoiceData, StandardProcessing)
	
	IntangibleAssetsInitialRecognitionClientLocalization.StartChoice(Item, ChoiceData, StandardProcessing, ThisObject);
	
EndProcedure

&AtClient
Procedure Attachable_AutoComplete(Item, Text, ChoiceData, DataGetParameters, Waiting, StandardProcessing)
	
	IntangibleAssetsInitialRecognitionClientLocalization.AutoComplete(Item, Text, ChoiceData, DataGetParameters, Waiting, StandardProcessing, ThisObject);
	
EndProcedure

&AtClient
Procedure Attachable_TextEditEnd(Item, Text, ChoiceData, DataGetParameters, StandardProcessing)
	
	IntangibleAssetsInitialRecognitionClientLocalization.TextEditEnd(Item, Text, ChoiceData, DataGetParameters, StandardProcessing, ThisObject);
	
EndProcedure

// StandardSubsystems.FilesOperations
&AtClient
Procedure Attachable_PreviewFieldClick(Item, StandardProcessing)

	FilesOperationsClient.PreviewFieldClick(ThisObject, Item, StandardProcessing);

EndProcedure

&AtClient
Procedure Attachable_PreviewFieldCheckDragging(Item, DragParameters, StandardProcessing)

	FilesOperationsClient.PreviewFieldCheckDragging(ThisObject, Item,
				DragParameters, StandardProcessing);

EndProcedure

&AtClient
Procedure Attachable_PreviewFieldDrag(Item, DragParameters, StandardProcessing)

	FilesOperationsClient.PreviewFieldDrag(ThisObject, Item,
				DragParameters, StandardProcessing);

EndProcedure
// End StandardSubsystems.FilesOperations

#EndRegion

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure FillInInitialCost(Command)
	
	ClearMessages();
	
	FillInPreliminaryCost(True);
	
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
Procedure PostAndClose(Command)
	
	TMCommonUseClient.PostAndClose(ThisObject);
	
EndProcedure

#Region AttachableCommands

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
Procedure Attachable_ContinueCommandExecutionAtServer(ExecutionParameters, AdditionalParameters) Export
	ExecuteCommandAtServer(ExecutionParameters);
EndProcedure

// StandardSubsystems.Properties

&AtClient
Procedure Attachable_PropertiesExecuteCommand(ItemOrCommand, Var_URL = Undefined, StandardProcessing = Undefined)
	
	PropertyManagerClient.ExecuteCommand(ThisObject, ItemOrCommand, StandardProcessing);
	
EndProcedure

// End StandardSubsystems.Properties

&AtClient
Procedure Attachable_OnExecuteCommand(Command)

	IntangibleAssetsInitialRecognitionClientLocalization.OnExecuteCommand(Command, ThisObject);

EndProcedure

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisObject, Command);
	
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

// StandardSubsystems.FilesOperations
&AtClient
Procedure Attachable_AttachedFilesPanelCommand(Command)

	FilesOperationsClient.AttachmentsControlCommand(ThisObject, Command);

EndProcedure
// End StandardSubsystems.FilesOperations

#EndRegion

#EndRegion

#Region Private

&AtServer
Procedure PropertiesExecuteDeferredInitialization()
	PropertyManager.FillAdditionalAttributesInForm(ThisObject);
EndProcedure

&AtServer
Procedure WhenYouChangeDetailsOfCompletionOnServer(Val TagName, Val AdditionalParameters)

	IntangibleAssetsInitialRecognitionLocalization.OnChangeAttribute(TagName, ThisObject);

	If AdditionalParameters.Property("Execute_ConfigureDependentFormElements") Then
		ConfigureDependentFormElementsOnServer(AdditionalParameters.Execute_ConfigureDependentFormElements);
	EndIf; 
	If AdditionalParameters.Property("Execute_FillInDetailsValuesBeforeChanging") Then
		FillInDetailsValuesBeforeChange(ThisObject);
	EndIf; 
	If AdditionalParameters.Property("Execute_FillInformationInBasement") Then
		FillInInformationInBasement();
	EndIf; 
	
EndProcedure

&AtServer
Procedure WhenExecutingEndCommandOnServer(Val CommandName, Val AdditionalParameters)

	IntangibleAssetsInitialRecognitionLocalization.OnExecuteCommand(CommandName, ThisObject);
	
	If AdditionalParameters.Property("Execute_ConfigureDependentFormElements") Then
		ConfigureDependentFormElementsOnServer(AdditionalParameters.Execute_ConfigureDependentFormElements);
	EndIf; 

EndProcedure
 
&AtClient
Procedure Attachable_CloseForm()
	
	Close();
	
EndProcedure

&AtServer
Procedure SetConditionalAppearance()
	
	ConditionalAppearance.Items.Clear();
	
	NonCurrentAssetsInternal.EstablishConditionalAppearanceOfTargetedFinancing(ConditionalAppearance, Items);
	
EndProcedure

&AtServer
Procedure OnReadCreateAtServer()
	
	InitializeServiceParametersOfForm();
	
	Items.CommentPage.Picture = CommonClientServer.CommentPicture(Object.Comment);
	
	CurrencyMA = Constants.ManagementAccountingCurrency.Get();
	ACCurrency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Object.Organization);
	
	FillInMethodsOfDepreciation(ThisObject);
		
	ConfigureHFCSelectionParameters();
	
	FillInInformationInBasement();
	
	IntangibleAssetsInitialRecognitionLocalization.OnReadCreateAtServer(ThisObject);
	
	ConfigureDependentFormElementsOnServer();
		
EndProcedure

&AtClientAtServerNoContext
Procedure FillInMethodsOfDepreciation(Form)
	
	Items = Form.Items;
	Object = Form.Object;
	
	// DepreciationAccrualMethodManagementAccounting
	ChoiceList = Items.DepreciationAccrualMethodManagementAccounting.ChoiceList;
	ChoiceList.Clear();
	ChoiceList.Add(PredefinedValue("Enum.AccrualMethodOfIntangibleAssetDepreciation.Linear"));
	ChoiceList.Add(PredefinedValue("Enum.AccrualMethodOfIntangibleAssetDepreciation.ByUnitsOfProduction"));
	
	If Object.KindOfAccountingObject = PredefinedValue("Enum.IntangibleAssetsAccountingItemKinds.IntangibleAsset") Then
		ChoiceList.Add(PredefinedValue("Enum.AccrualMethodOfIntangibleAssetDepreciation.ReducedBalance"));
	EndIf;
	
	// DepreciationMethodAccounting
	ChoiceList = Items.DepreciationMethodAccounting.ChoiceList;
	ChoiceList.Clear();
	ChoiceList.Add(PredefinedValue("Enum.AccrualMethodOfIntangibleAssetDepreciation.Linear"));
	ChoiceList.Add(PredefinedValue("Enum.AccrualMethodOfIntangibleAssetDepreciation.ByUnitsOfProduction"));
	
	If Object.KindOfAccountingObject = PredefinedValue("Enum.IntangibleAssetsAccountingItemKinds.IntangibleAsset") Then
		ChoiceList.Add(PredefinedValue("Enum.AccrualMethodOfIntangibleAssetDepreciation.ReducedBalance"));
	EndIf;
	
EndProcedure

&AtClient
Procedure ConfigureDependentFormElements(Val ChangedBankingDetails = "")

	StructureOfChangedProps = New Structure(ChangedBankingDetails);
	
	If RequiresServerCallToConfigureFormElements(StructureOfChangedProps) Then
		ConfigureDependentFormElementsOnServer(ChangedBankingDetails)
	Else
		ConfigureDependentFormElementsOnClientOnServer(ThisObject, ChangedBankingDetails);
	EndIf;

EndProcedure

&AtClientAtServerNoContext
Procedure ConfigureDependentFormElementsOnClientOnServer(Form, Val ChangedBankingDetails = "")
	
	StructureOfChangedProps = New Structure(ChangedBankingDetails);
	UpdateAll = StructureOfChangedProps.Count() = 0;
	
	Items = Form.Items;
	Object = Form.Object;
	FormServiceParameters = Form.FormServiceParameters;
	
	OnChangeAttributes(Form, StructureOfChangedProps);
	
	AuxiliaryAttributes = New Structure;
	AuxiliaryAttributes.Insert("RecordInManAccounting", Object.RecordInManAccounting);
	AuxiliaryAttributes.Insert("RecordInLocalAccounting", Object.RecordInLocalAccounting);
	AuxiliaryAttributes.Insert("PostInAccounting", Object.PostInAccounting);
	AuxiliaryAttributes.Insert("RecordInTA", Object.RecordInTA);
	AuxiliaryAttributes.Insert("BusinessOperation", Object.BusinessOperation);
	AuxiliaryAttributes.Insert("ComplianceCAAccountingIsKept", FormServiceParameters.ComplianceCAAccountingIsKept);
	AuxiliaryAttributes.Insert("CurrenciesDoNotMatch", Form.ACCurrency = Form.CurrencyMA);
	AuxiliaryAttributes.Insert("ThereIsCostAccounting", FormServiceParameters.ThereIsCostAccounting);
	AuxiliaryAttributes.Insert("FALocalAccountingIsConductedIndependently", FormServiceParameters.FALocalAccountingIsConductedIndependently);
	AuxiliaryAttributes.Insert("UseAccountingByAreasOfActivity", FormServiceParameters.UseAccountingByAreasOfActivity);
	AuxiliaryAttributes.Insert("AccountPolicySettings", FormServiceParameters.AccountPolicySettings);
	AuxiliaryAttributes.Insert("ThereAreRelatedCompanies", FormServiceParameters.ThereAreRelatedCompanies);
	IntangibleAssetsInitialRecognitionClientServerLocalization.AddAuxiliaryDetails(Form, AuxiliaryAttributes);
	
	ItemDetailsParameters = NonCurrentAssetsClientServer.PropertyValuesOfDependentProps_AcceptanceForAccountingByIA(
									Object, AuxiliaryAttributes, ChangedBankingDetails);
	
	TMCommonUseClientServer.ConfigureDependentFormElements(Form, ItemDetailsParameters);
	
	If Not UpdateAll Then
		
		ChangedAttributesAfterSettingUp = New Array;
	
		TMCommonUseClientServer.ClearUnusedProps(
			Object, ItemDetailsParameters, "TargetFinancing", ChangedAttributesAfterSettingUp);
		
		FillInDetailsDependingOnProperties(Form, ItemDetailsParameters, ChangedAttributesAfterSettingUp);
		
		If ChangedAttributesAfterSettingUp.Count() <> 0 Then
			
			ChangedAttributesAfterSettingUp = StrConcat(ChangedAttributesAfterSettingUp, ",");

			ItemDetailsParameters = NonCurrentAssetsClientServer.PropertyValuesOfDependentProps_AcceptanceForAccountingByIA(
											Object, AuxiliaryAttributes, ChangedAttributesAfterSettingUp);
		
			TMCommonUseClientServer.ConfigureDependentFormElements(Form, ItemDetailsParameters);
			
		EndIf;
		
	EndIf; 
	
	IAAcceptanceParameters = NonCurrentAssetsClientServer.IAAcceptanceParameters(Object, AuxiliaryAttributes);
	
	#Region IsMain
	
	If StructureOfChangedProps.Property("Organization")
		Or StructureOfChangedProps.Property("Date")
		Or UpdateAll Then

		Items.PostInAccounting.Visible = FormServiceParameters.FALocalAccountingIsConductedIndependently;
		Items.RecordInTA.Visible = FormServiceParameters.ComplianceCAAccountingIsKept;
		Items.RecordInManAccounting.Visible = FormServiceParameters.FALocalAccountingIsConductedIndependently;
		Items.DecorationIsReflectionOption.Visible = Items.PostInAccounting.Visible Or Items.RecordInManAccounting.Visible;
		
		If Not FormServiceParameters.FALocalAccountingIsConductedIndependently 
			And Not UpdateAll Then

			Object.RecordInLocalAccounting = True;
			Object.RecordInManAccounting = True;
			Object.PostInAccounting = True;
			Object.RecordInTA = False;
		EndIf;
		
	EndIf;
	
	If StructureOfChangedProps.Property("Date") 
		Or StructureOfChangedProps.Property("Organization") 
		Or StructureOfChangedProps.Property("RecordInManAccounting") 
		Or StructureOfChangedProps.Property("RecordInLocalAccounting") 
		Or StructureOfChangedProps.Property("AccountingProcedureMA") 
		Or StructureOfChangedProps.Property("AccountingProcedureAC") 
		Or StructureOfChangedProps.Property("BusinessOperation") 
		Or UpdateAll Then
		
		Items.FillInInitialCost.Visible = 
			Not IAAcceptanceParameters.ActualCost
			And FormServiceParameters.ThereIsCostAccounting
			And (Items.InitialCostMA.Visible
				Or Items.InitialCostLocalAccounting.Visible
				Or Items.InitialCostTA.Visible);
		
		//	
		If FormServiceParameters.FALocalAccountingIsConductedIndependently Then
			Items.InitialCostLocalAccounting.Title = NStr("vi = 'Giá trị (KTDN)';
															|ru = 'Стоимость (БУ)';
															|en = 'Cost (LA)'; fa = 'بها (محلی)';
															|it = 'Costo (contabilità)';
															|pl = 'Wartość (EK)';
															|tr = 'Maliyet (LA)'");
			Items.InitialCostMA.Title = NStr("vi = 'Giá trị (KTQT)';
											|ru = 'Стоимость (УУ)';
											|en = 'Cost (MA)'; fa = 'بها (مدیریت)';
											|it = 'Costo contabilità gestionale';
											|pl = 'Wartość (EZ)';
											|tr = 'Maliyet (YM)'");
			Items.ResidualValueMan.Title = NStr("vi = 'Giá trị thanh lý (kế toán quản trị)';
												|ru = 'Ликвидационная стоимость (упр. учет)';
												|en = 'Residual value  (mgmt accounting)'; fa = 'Residual value  (mgmt accounting)';
												|it = 'Residual value  (mgmt accounting)';
												|pl = 'Residual value  (mgmt accounting)';
												|tr = 'Tasfiye değeri (yönetim muhasebesi)'");
			Items.ResidualValueLocal.Title = NStr("vi = 'Giá trị thanh lý (kế toán tài chính)';
													|ru = 'Ликвидационная стоимость (регл. учет)';
													|en = 'Residual value (local accounting)'; fa = 'Residual value (local accounting)';
													|it = 'Residual value (local accounting)';
													|pl = 'Residual value (local accounting)';
													|tr = 'Tasfiye değeri (yerel muhasebe)'");
		Else
			Items.InitialCostLocalAccounting.Title = NStr("vi = 'Giá trị';
															|ru = 'Стоимость';
															|en = 'Cost'; fa = 'بهای تمام‌شده';
															|it = 'Costo';
															|pl = 'Wartość';
															|tr = 'Maliyet'");
			Items.InitialCostMA.Title = NStr("vi = 'Giá trị';
											|ru = 'Стоимость';
											|en = 'Cost'; fa = 'بهای تمام‌شده';
											|it = 'Costo';
											|pl = 'Wartość';
											|tr = 'Maliyet'");
			Items.ResidualValueMan.Title = NStr("vi = 'Giá trị thanh lý';
												|ru = 'Ликвидационная стоимость';
												|en = 'Residual value'; fa = 'ارزش باقی‌مانده';
												|it = 'Prezzo di liquidazione';
												|pl = 'Wartość likwidacyjna';
												|tr = 'Artık değer'");
			Items.ResidualValueLocal.Title = NStr("vi = 'Giá trị thanh lý';
													|ru = 'Ликвидационная стоимость';
													|en = 'Residual value'; fa = 'ارزش باقی‌مانده';
													|it = 'Prezzo di liquidazione';
													|pl = 'Wartość likwidacyjna';
													|tr = 'Artık değer'");
		EndIf;
		
		//
		Items.InitialCostOfTheBUValute.Visible = Items.InitialCostLocalAccounting.Visible;
		Items.InitialCostOfManCurrency.Visible = Items.InitialCostMA.Visible;
		Items.LiquidationValueReglCurrency.Visible = Items.ResidualValueLocal.Visible;
		Items.LiquidationValueCurrency.Visible = Items.ResidualValueMan.Visible;
		
	EndIf;
	
	If StructureOfChangedProps.Property("Date")
		Or StructureOfChangedProps.Property("Organization")
		Or StructureOfChangedProps.Property("BusinessOperation")
		Or StructureOfChangedProps.Property("PostInAccounting")
		Or StructureOfChangedProps.Property("RecordInManAccounting")
		Or StructureOfChangedProps.Property("AccountingProcedureAC")
		Or StructureOfChangedProps.Property("AccountingProcedureMA")
		Or UpdateAll Then
			
		If (IAAcceptanceParameters.CostIsRequiredToCalculateDepreciationOfAC
				Or IAAcceptanceParameters.CostIsRequiredToCalculateDepreciationOfAC)
			And (Items.InitialCostLocalAccounting.Visible
				Or Items.InitialCostMA.Visible) Then
			
			Items.PictureInformation.Visible = True;
			Items.BasementInformationPreliminaryCostText.Visible = True;
			Items.BasementInformationPreliminaryCostText.Title =
				NStr("vi = 'Giá trị được sử dụng để tính khấu hao trong tháng hiện tại.
					 |Số tiền này có thể không khớp với giá trị thực tế, trong trường hợp đó, khấu hao sẽ được điều chỉnh vào tháng sau.';
					 |ru = 'Стоимость используется для расчета амортизации в текущем месяце.
					 |Она может не совпадать с фактической стоимостью, в этом случае амортизация будет скорректирована в следующем месяце.';
					 |en = 'The cost is used to calculate amortization for the current month.
					 |It may not match the actual cost. In this case, the amortization will be adjusted next month.'; fa = 'The cost is used to calculate amortization for the current month.
					 |It may not match the actual cost. In this case, the amortization will be adjusted next month.';
					 |it = 'The cost is used to calculate amortization for the current month.
					 |It may not match the actual cost. In this case, the amortization will be adjusted next month.';
					 |pl = 'The cost is used to calculate amortization for the current month.
					 |It may not match the actual cost. In this case, the amortization will be adjusted next month.';
					 |tr = 'Maliyet, cari ayda amortisman hesaplaması için kullanılır.
					 |Gerçek maliyetle örtüşmeyebilir, bu durumda amortisman bir sonraki ayda düzeltilir.'");
					 
		Else
		
			Items.BasementInformationPreliminaryCostText.Visible = False;
			Items.PictureInformation.Visible = Items.Information.Visible;
			
		EndIf;

	EndIf;

	#EndRegion
	
	#Region AccountingParametersOfBU
	
	If StructureOfChangedProps.Property("UsefulLifeAccounting")
		Or StructureOfChangedProps.Property("AccountingProcedureAC")
		Or StructureOfChangedProps.Property("RecordInLocalAccounting")
		Or UpdateAll Then
		
		Form.ACUsefulLifeExplanation = NonCurrentAssetsClientServer.PresentationOfNumberOfMonthsByString(
			Object.UsefulLifeAccounting);
			
	EndIf;
	
	If StructureOfChangedProps.Property("KindOfAccountingObject") 
		Or UpdateAll Then
		
		If Object.KindOfAccountingObject = PredefinedValue("Enum.IntangibleAssetsAccountingItemKinds.IntangibleAsset") Then
			
			Items.DepreciationMethodAccounting.Title = NStr("vi = 'Phương pháp khấu hao';
															|ru = 'Способ начисления амортизации';
															|en = 'Amortization method'; fa = 'روش استهلاک دارایی نامشهود';
															|it = 'Metodo di maturazione dell''ammortamento';
															|pl = 'Sposób naliczenia amortyzacji';
															|tr = 'Amortisman birikimi yöntemi'");
			Items.AccountingProcedureAC.Title = NStr("vi = 'Thứ tự ghi nhận';
													|ru = 'Порядок учета';
													|en = 'Accounting procedure'; fa = 'رویه حسابداری';
													|it = 'Ordine contabilità';
													|pl = 'Tryb ewidencji';
													|tr = 'Muhasebe prosedürü'");
			Items.UsefulLifeAccounting.Title = NStr("vi = 'Thời hạn sử dụng';
													|ru = 'Срок использования';
													|en = 'Useful life'; fa = 'عمر مفید';
													|it = 'Vita utile';
													|pl = 'Liczba miesięcy amortyzacji';
													|tr = 'Kullanım süresi'");
			
			ProcedureForCalculatingDepreciationIsPresentationOfBU = NStr("vi = 'Trích khấu hao';
																		|ru = 'Начислять амортизацию';
																		|en = 'Accrue amortization '; fa = 'محاسبه استهلاک دارایی نامشهود';
																		|it = 'Calcolare ammortamento';
																		|pl = 'Naliczać amortyzację';
																		|tr = 'Amortismanı tahakkuk ettir'");
			ProcedureForNotAccruingDepreciationIsPresentationOfBU = NStr("vi = 'Không trích khấu hao';
																		|ru = 'Не начислять амортизацию';
																		|en = 'Do not accrue amortization'; fa = 'Do not accrue amortization';
																		|it = 'Non elencare ammortamento';
																		|pl = 'Nie naliczaj amortyzacji';
																		|tr = 'Amortismanı tahakkuk etme'");
			
		Else
			
			Items.DepreciationMethodAccounting.Title = NStr("vi = 'Phương pháp xóa chi phí';
															|ru = 'Способ списания расходов';
															|en = 'Expense write-off method'; fa = 'Expense write-off method';
															|it = 'Modo di cancellazione delle uscite';
															|pl = 'Sposób wyksięgowania wydatków';
															|tr = 'Giderler nasıl yazılır'");
			Items.AccountingProcedureAC.Title = NStr("vi = 'Thủ tục ghi nợ';
													|ru = 'Порядок списания';
													|en = 'Amortization procedure'; fa = 'Amortization procedure';
													|it = 'Ordine Cancellato';
													|pl = 'Tryb wyksięgowania';
													|tr = 'Yazma prosedürü'");
			Items.UsefulLifeAccounting.Title = NStr("vi = 'Thời hạn ghi giảm';
													|ru = 'Срок списания';
													|en = 'Amortization period'; fa = 'Amortization period';
													|it = 'Termine di storno';
													|pl = 'Termin rozchodu';
													|tr = 'Yazılma süresi'");
			
			ProcedureForCalculatingDepreciationIsPresentationOfBU = NStr("vi = 'Ghi giảm chi phí';
																		|ru = 'Списание расходов';
																		|en = 'Expense write-off'; fa = 'اسقاط هزینه';
																		|it = 'Storno delle spese';
																		|pl = 'Wyksięgowanie wydatków';
																		|tr = 'Giderlerin silinmesi'");
			ProcedureForNotAccruingDepreciationIsPresentationOfBU = NStr("vi = 'Không ghi giảm chi phí';
																		|ru = 'Не списывать расходы';
																		|en = 'Do not write off expenses'; fa = 'Do not write off expenses';
																		|it = 'Non stornare le spese';
																		|pl = 'Nie spisuj rozchody';
																		|tr = 'Masrafları yazmayın'");
			
		EndIf;

		NonCurrentAssetsClientServer.SetValuePresentationOfSelectionList(
			Items.AccountingProcedureAC.ChoiceList,
			PredefinedValue("Enum.FixedAssetValueRegistrationProcedure.AccrueDepreciationOrAmortization"),
			ProcedureForCalculatingDepreciationIsPresentationOfBU);
			
		NonCurrentAssetsClientServer.SetValuePresentationOfSelectionList(
			Items.AccountingProcedureAC.ChoiceList,
			PredefinedValue("Enum.FixedAssetValueRegistrationProcedure.NotAccrueDepreciationOrAmortization"),
			ProcedureForNotAccruingDepreciationIsPresentationOfBU);
			
	EndIf;
	
	#EndRegion
	
	#Region UUAccountingParameters
	
	If StructureOfChangedProps.Property("UsefulLifeManagementAccounting")
		Or StructureOfChangedProps.Property("AccountingProcedureMA")
		Or StructureOfChangedProps.Property("RecordInManAccounting")
		Or UpdateAll Then
		
		Form.UsefulLifeMAExplanation = NonCurrentAssetsClientServer.PresentationOfNumberOfMonthsByString(
			Object.UsefulLifeManagementAccounting);
			
	EndIf;

	If StructureOfChangedProps.Property("KindOfAccountingObject") 
		Or UpdateAll Then
		
		If Object.KindOfAccountingObject = PredefinedValue("Enum.IntangibleAssetsAccountingItemKinds.IntangibleAsset") Then
			
			Items.IntangibleAsset.Title = NStr("vi = 'Tài sản vô hình';
												|ru = 'Нематериальный актив';
												|en = 'Intangible asset'; fa = 'دارایی نامشهود';
												|it = 'Bene immateriale';
												|pl = 'Wartości niematerialne';
												|tr = 'Maddi olmayan varlık'");
			
			Items.DepreciationAccrualMethodManagementAccounting.Title = NStr("vi = 'Phương pháp khấu hao';
																			|ru = 'Способ начисления амортизации';
																			|en = 'Amortization method'; fa = 'روش استهلاک دارایی نامشهود';
																			|it = 'Metodo di maturazione dell''ammortamento';
																			|pl = 'Sposób naliczenia amortyzacji';
																			|tr = 'Amortisman birikimi yöntemi'");
			Items.AccountingProcedureMA.Title = NStr("vi = 'Thứ tự ghi nhận';
													|ru = 'Порядок учета';
													|en = 'Accounting procedure'; fa = 'رویه حسابداری';
													|it = 'Ordine contabilità';
													|pl = 'Tryb ewidencji';
													|tr = 'Muhasebe prosedürü'");
			Items.UsefulLifeManagementAccounting.Title = NStr("vi = 'Thời hạn sử dụng';
																|ru = 'Срок использования';
																|en = 'Useful life'; fa = 'عمر مفید';
																|it = 'Vita utile';
																|pl = 'Liczba miesięcy amortyzacji';
																|tr = 'Kullanım süresi'");
			
			ProcedureToAccrueDepreciationPresentation = NStr("vi = 'Trích khấu hao';
															|ru = 'Начислять амортизацию';
															|en = 'Accrue amortization '; fa = 'محاسبه استهلاک دارایی نامشهود';
															|it = 'Calcolare ammortamento';
															|pl = 'Naliczać amortyzację';
															|tr = 'Amortismanı tahakkuk ettir'");
			OrderNotToChargeDepreciationPresentation = NStr("vi = 'Không tính khấu hao';
															|ru = 'Не начислять амортизацию';
															|en = 'Do not accrue amortization'; fa = 'Do not accrue amortization';
															|it = 'Non elencare ammortamento';
															|pl = 'Nie naliczaj amortyzacji';
															|tr = 'Amortismanı tahakkuk etme'");

		Else
			
			Items.IntangibleAsset.Title = NStr("vi = 'Nghiên cứu và phát triển';
												|ru = 'НИОКР';
												|en = 'R&D'; fa = 'تحقیق و توسعه';
												|it = 'Ricerca&Sviluppo';
												|pl = 'R&D';
												|tr = 'Ar-Ge'");
			
			Items.DepreciationAccrualMethodManagementAccounting.Title = NStr("vi = 'Phương pháp xóa chi phí';
																			|ru = 'Способ списания расходов';
																			|en = 'Expense write-off method'; fa = 'Expense write-off method';
																			|it = 'Modo di cancellazione delle uscite';
																			|pl = 'Sposób wyksięgowania wydatków';
																			|tr = 'Giderler nasıl yazılır'");
			Items.AccountingProcedureMA.Title = NStr("vi = 'Thủ tục ghi nợ';
													|ru = 'Порядок списания';
													|en = 'Amortization procedure'; fa = 'Amortization procedure';
													|it = 'Ordine Cancellato';
													|pl = 'Tryb wyksięgowania';
													|tr = 'Yazma prosedürü'");
			Items.UsefulLifeManagementAccounting.Title = NStr("vi = 'Thời hạn ghi giảm';
																|ru = 'Срок списания';
																|en = 'Amortization period'; fa = 'Amortization period';
																|it = 'Termine di storno';
																|pl = 'Termin rozchodu';
																|tr = 'Yazılma süresi'");
			
			ProcedureToAccrueDepreciationPresentation = NStr("vi = 'Ghi giảm chi phí';
															|ru = 'Списание расходов';
															|en = 'Expense write-off'; fa = 'اسقاط هزینه';
															|it = 'Storno delle spese';
															|pl = 'Wyksięgowanie wydatków';
															|tr = 'Giderlerin yazılması'");
			OrderNotToChargeDepreciationPresentation = NStr("vi = 'Không ghi giảm chi phí';
															|ru = 'Не списывать расходы';
															|en = 'Do not write off expenses'; fa = 'Do not write off expenses';
															|it = 'Non stornare le spese';
															|pl = 'Nie spisuj rozchody';
															|tr = 'Masrafları yazmayın'");

		EndIf;

		NonCurrentAssetsClientServer.SetValuePresentationOfSelectionList(
			Items.AccountingProcedureMA.ChoiceList,
			PredefinedValue("Enum.FixedAssetValueRegistrationProcedure.AccrueDepreciationOrAmortization"),
			ProcedureToAccrueDepreciationPresentation);
			
		NonCurrentAssetsClientServer.SetValuePresentationOfSelectionList(
			Items.AccountingProcedureMA.ChoiceList,
			PredefinedValue("Enum.FixedAssetValueRegistrationProcedure.NotAccrueDepreciationOrAmortization"),
			OrderNotToChargeDepreciationPresentation);

	EndIf;
		
	#EndRegion
	
	#Region AccountingParametersOther
	
	If UpdateAll Then
		Items.DecorationSetTAAccountingParameter.Visible = False;
	EndIf;
	
	#EndRegion
	
	#Region ReflectionOfBUExpenses
	
	If StructureOfChangedProps.Property("RecordInManAccounting") 
		Or StructureOfChangedProps.Property("KindOfAccountingObject") 
		Or StructureOfChangedProps.Property("AccountingProcedureAC") 
		Or StructureOfChangedProps.Property("AccountingProcedureTA") 
		Or StructureOfChangedProps.Property("Organization") 
		Or UpdateAll Then
		
		If Object.AccountingProcedureAC = PredefinedValue("Enum.FixedAssetValueRegistrationProcedure.DoNotTakeIntoAccountIncludeInExpenses") Then
			
			Items.ExpensesACGroup.Title = NStr("vi = 'Đưa vào chi phí (kế toán doanh nghiệp)';
												|ru = 'Включение в расходы (бухгалтерский учет)';
												|en = 'Add to expenses (local accounting)'; fa = 'Add to expenses (local accounting)';
												|it = 'Inclusione nelle spese (contabilità)';
												|pl = 'Uwzględnienie w rozchodach (ewidencja księgowa)';
												|tr = 'Giderlere dahil etme (muhasebe)'");
			Items.ExpenseItemAccounting.ToolTip = NStr("vi = 'Dạng chi phí được ghi giảm chi phí khi được chấp nhận cho kế toán';
														|ru = 'Статья расходов, на которую списываются расходы при принятии к учету';
														|en = 'Expense item to which the expenses are charged to on initial recognition'; fa = 'Expense item to which the expenses are charged to on initial recognition';
														|it = 'Voce di spesa a cui vengono stornate le spese all''accettazione in contabilità';
														|pl = 'Rodzaj kosztu, na który wyksięgowuje się rozchody przy przyjęciu do ewidencji';
														|tr = 'Dikkate alındığında giderlerin mahsup edildiği harcama kalemi'");
					
		Else
			
			If Object.KindOfAccountingObject = PredefinedValue("Enum.IntangibleAssetsAccountingItemKinds.IntangibleAsset") Then
				
				Items.ExpensesACGroup.Title = NStr("vi = 'Khấu hao (kế toán doanh nghiệp)';
													|ru = 'Амортизация (бухгалтерский учет)';
													|en = 'Amortization (local accounting)'; fa = 'استهلاک دارایی نامشهود (حسابداری محلی)';
													|it = 'Ammortamento (contabilità ordinaria)';
													|pl = 'Amortyzacja (ewidencja księgowa)';
													|tr = 'Amortisman (genel muhasebe)'");
				Items.ExpenseItemAccounting.ToolTip = NStr("vi = 'Dạng chi phí mà chi phí khấu hao được phản ánh';
															|ru = 'Статья расходов, по которой отражаются амортизационные расходы';
															|en = 'Expense item recording amortization expenses'; fa = 'قلم هزینه ثبت هزینه‌های استهلاک دارایی نامشهود';
															|it = 'Voce di uscita per la quale vengono rilevate le spese di ammortamento';
															|pl = 'Rodzaj kosztu, według którego odzwierciedlane są rozchody amortyzacyjne';
															|tr = 'Amortisman giderinin yansıtıldığı gider kalemi'");
															
			Else
	
				Items.ExpensesACGroup.Title = NStr("vi = 'Ghi giảm chi phí (kế toán doanh nghiệp)';
													|ru = 'Списание расходов (бухгалтерский учет)';
													|en = 'Expense write-off (local accounting)'; fa = 'Expense write-off (local accounting)';
													|it = 'Storno spese (contabilità)';
													|pl = 'Spisanie rozchodów (ewidencja księgowa)';
													|tr = 'Giderlerin mahsuplaşması (muhasebe)'");
				Items.ExpenseItemAccounting.ToolTip = NStr("vi = 'Dạng chi phí, phản ánh việc xóa bỏ chi phí';
															|ru = 'Статья расходов, по которой отражается списание расходов';
															|en = 'Expense item on which the expenses write-off is recognized'; fa = 'Expense item on which the expenses write-off is recognized';
															|it = 'Voce di spesa, che rispecchia lo storno delle spese';
															|pl = 'Rodzaj kosztu, dla którego odzwierciedla się wyksięgowanie rozchodów';
															|tr = 'Mahsuplaşmaların kaydedildiği harcama kalemi'");
															
			EndIf;
			
		EndIf;
		
	EndIf;
	
	#EndRegion
	
	#Region ReflectionOfExpensesOfUU
	
	If StructureOfChangedProps.Property("RecordInLocalAccounting") 
		Or StructureOfChangedProps.Property("RecordInManAccounting") 
		Or StructureOfChangedProps.Property("ExpenseItemManagementAccounting") 
		Or StructureOfChangedProps.Property("ExpensesDimensionManagementAccounting") 
		Or StructureOfChangedProps.Property("AccountingProcedureAC") 
		Or StructureOfChangedProps.Property("AccountingProcedureTA") 
		Or StructureOfChangedProps.Property("AccountingProcedureMA") 
		Or StructureOfChangedProps.Property("ExpenseRecordMethodAC") 
		Or StructureOfChangedProps.Property("MethodForReflectingMaExpenses") 
		Or StructureOfChangedProps.Property("BusinessUnitManagementAccounting") 
		Or StructureOfChangedProps.Property("LineOfBusinessManagementAccounting") 
		Or StructureOfChangedProps.Property("BusinessUnitAndLineOfBusinessMatchAccountingDataManagementAccounting") 
		Or UpdateAll Then
		
		If IAAcceptanceParameters.ExpenseItemManagementAccountingRequired_ 
			Or ValueIsFilled(Object.ExpenseItemManagementAccounting) Then
			
			Items.MethodForReflectingMaExpenses.InputHint = "";
			Items.ExpenseItemManagementAccounting.InputHint = "";
			Items.ExpensesDimensionManagementAccounting.InputHint = "";
			Items.BusinessUnitManagementAccounting.InputHint = "";
			Items.LineOfBusinessManagementAccounting.InputHint = "";
			
		ElsIf Not IAAcceptanceParameters.ExpenseItemManagementAccountingRequired_ Then

			ArticleInputPrompt = NStr("vi = 'trùng với kế toán doanh nghiệp';
										|ru = 'совпадает с бухгалтерским учетом';
										|en = 'matches local accounting'; fa = 'matches local accounting';
										|it = 'corrisponde alla contabilità';
										|pl = 'jest zgodne z ewidencją księgową';
										|tr = 'genel muhasebe ile örtüşmektedir'");
			
			Items.MethodForReflectingMaExpenses.InputHint = ArticleInputPrompt;
			Items.ExpenseItemManagementAccounting.InputHint = ArticleInputPrompt;
			Items.ExpensesDimensionManagementAccounting.InputHint = ArticleInputPrompt;
			Items.BusinessUnitManagementAccounting.InputHint = ArticleInputPrompt;
			Items.LineOfBusinessManagementAccounting.InputHint = ArticleInputPrompt;
			
		EndIf; 
		
	EndIf;
	
	If StructureOfChangedProps.Property("ExpenseRecordMethodAC") 
		Or UpdateAll Then
			
		NonCurrentAssetsClientServer.CustomizeItemsAccordingToWayExpensesAreReflected(
			Object.ExpenseRecordMethodAC, 
			Form,
			"ExpenseItemAccounting,ExpensesDimensionAccounting,DepartmentACC,LineOfBusinessBookkeeping,BusinessUnitAndLineOfBusinessMatchAccountingDataBookkeeping");
	
	EndIf;

	If StructureOfChangedProps.Property("MethodForReflectingMaExpenses") 
		Or UpdateAll Then
			
		NonCurrentAssetsClientServer.CustomizeItemsAccordingToWayExpensesAreReflected(
			Object.MethodForReflectingMaExpenses,
			Form, 
			"ExpenseItemManagementAccounting,ExpensesDimensionManagementAccounting,BusinessUnitManagementAccounting,LineOfBusinessManagementAccounting,BusinessUnitAndLineOfBusinessMatchAccountingDataManagementAccounting");
	
	EndIf;
	
	If StructureOfChangedProps.Property("RecordInLocalAccounting") 
		Or StructureOfChangedProps.Property("KindOfAccountingObject") 
		Or StructureOfChangedProps.Property("AccountingProcedureMA") 
		Or UpdateAll Then
		
		If Object.AccountingProcedureMA = PredefinedValue("Enum.FixedAssetValueRegistrationProcedure.DoNotTakeIntoAccountIncludeInExpenses") Then
			
			Items.UUExpensesGroup.Title = NStr("vi = 'Ghi giảm vào chi phí (kế toán quản trị)';
												|ru = 'Списание на расходы (управленческий учет)';
												|en = 'Write-off for expenses (management accounting)'; fa = 'Write-off for expenses (management accounting)';
												|it = 'Storno nelle spese (contabilità gestionale)';
												|pl = 'Spisanie na rozchody (ewidencja zarządcza)';
												|tr = 'Giderlere yazılma (yönetim muhasebesi)'");
			Items.ExpenseItemManagementAccounting.ToolTip = NStr("vi = 'Dạng chi phí được ghi giảm chi phí khi được chấp nhận cho kế toán';
																|ru = 'Статья расходов, на которую списываются расходы при принятии к учету';
																|en = 'Expense item to which the expenses are charged to on initial recognition'; fa = 'Expense item to which the expenses are charged to on initial recognition';
																|it = 'Voce di spesa a cui vengono stornate le spese all''accettazione in contabilità';
																|pl = 'Rodzaj kosztu, na który wyksięgowuje się rozchody przy przyjęciu do ewidencji';
																|tr = 'Dikkate alındığında giderlerin mahsup edildiği harcama kalemi'");
			
		Else
			
			If Object.KindOfAccountingObject = PredefinedValue("Enum.IntangibleAssetsAccountingItemKinds.IntangibleAsset") Then
				
				Items.UUExpensesGroup.Title = NStr("vi = 'Khấu hao (kế toán quản trị)';
													|ru = 'Амортизация (управленческий учет)';
													|en = 'Amortization (management accounting)'; fa = 'استهلاک دارایی نامشهود (حسابداری مدیریتی)';
													|it = 'Ammortamento (contabilità gestionale)';
													|pl = 'Amortyzacja (ewidencja administracyjna)';
													|tr = 'Amortisman (yönetim muhasebesi)'");
				Items.ExpenseItemManagementAccounting.ToolTip = NStr("vi = 'Dạng chi phí mà chi phí khấu hao được phản ánh';
																	|ru = 'Статья расходов, по которой отражаются амортизационные расходы';
																	|en = 'Expense item recording amortization expenses'; fa = 'قلم هزینه ثبت هزینه‌های استهلاک دارایی نامشهود';
																	|it = 'Voce di uscita per la quale vengono rilevate le spese di ammortamento';
																	|pl = 'Rodzaj kosztu, według którego odzwierciedlane są rozchody amortyzacyjne';
																	|tr = 'Amortisman giderinin yansıtıldığı gider kalemi'");
						
			Else

				Items.UUExpensesGroup.Title = NStr("vi = 'Ghi giảm chi phí (kế toán quản trị)';
													|ru = 'Списание расходов (управленческий учет)';
													|en = 'Expense write-off (management accounting)'; fa = 'Expense write-off (management accounting)';
													|it = 'Storno spese (contabilità gestionale)';
													|pl = 'Spisanie rozchodów (ewidencja zarządcza)';
													|tr = 'Giderlerin mahsuplaşması (yönetim muhasebesi)'");
				Items.ExpenseItemManagementAccounting.ToolTip = NStr("vi = 'Dạng chi phí, phản ánh việc xóa bỏ chi phí';
																	|ru = 'Статья расходов, по которой отражается списание расходов';
																	|en = 'Expense item on which the expenses write-off is recognized'; fa = 'Expense item on which the expenses write-off is recognized';
																	|it = 'Voce di spesa, che rispecchia lo storno delle spese';
																	|pl = 'Rodzaj kosztu, dla którego odzwierciedla się wyksięgowanie rozchodów';
																	|tr = 'Mahsuplaşmaların kaydedildiği harcama kalemi'");
						
			EndIf;
			
		EndIf; 
		
	EndIf;
	
	#EndRegion
	
	IntangibleAssetsInitialRecognitionClientServerLocalization.ConfigureDependentFormElements(
		Form, 
		AuxiliaryAttributes,
		StructureOfChangedProps, 
		IAAcceptanceParameters, 
		ItemDetailsParameters);
	
	FillInDetailsValuesBeforeChange(Form);
	
EndProcedure

&AtServer
Procedure ConfigureDependentFormElementsOnServer(Val ChangedBankingDetails = "")

	StructureOfChangedProps = New Structure(ChangedBankingDetails);
	
	UpdateAll = StructureOfChangedProps.Count() = 0;

	DateOfParameters = EndOfMonth(?(Object.Date <> '000101010000', Object.Date, CurrentSessionDate()));

	If UpdateAll Then
		
		Items.LineOfBusinessTaxAccounting.Visible = False;
		Items.InitialCostOfNUValyut.Visible = False;
		Items.TheInitialCostOfTheCurrency.Visible = False;
		
		Items.BusinessOperation.Visible = (Items.BusinessOperation.ChoiceList.Count() > 1);
		
	EndIf;
	
	If StructureOfChangedProps.Property("Organization")
		Or UpdateAll Then
		
		NonCurrentAssetsInternal.SetStructureProperty(
			"ThereAreRelatedCompanies",
			Catalogs.Companies.OrganizationIsInterconnectedWithOtherOrganizations(Object.Organization),
			FormServiceParameters);
		
	EndIf;
	
	If StructureOfChangedProps.Property("KindOfAccountingObject") Then
		ViewOfAccountingObjectWhenChangedOnServer(ChangedBankingDetails);
	EndIf; 
	
	If StructureOfChangedProps.Property("Date") 
		Or UpdateAll Then
		
		NonCurrentAssetsInternal.SetStructureProperty(
			"ThereIsCostAccounting",
			CalculationOfCostCached.GenerateRegisteredRecordsOnCostRegisters(DateOfParameters),
			FormServiceParameters);
		
	EndIf;
	
	If StructureOfChangedProps.Property("Organization")
		Or StructureOfChangedProps.Property("Date")
		Or UpdateAll Then
	
		NonCurrentAssets.SetParametersOfFunctionalOptionsOfObjectForm(ThisObject, Object.Organization, Object.Date);
	
		NonCurrentAssetsInternal.SetStructureProperty(
			"FALocalAccountingIsConductedIndependently",
			AccountingPoliciesTaxSettingsCached.FALocalAccountingIsConductedIndependently(Object.Organization, DateOfParameters),
			FormServiceParameters);
			
		NonCurrentAssetsInternal.SetStructureProperty(
			"AccountPolicySettings",
			AccountingPoliciesTaxSettingsCached.AccountingSettingsForNonCurrentAssets(Object.Organization, DateOfParameters),
			FormServiceParameters);

	EndIf;
		
	If StructureOfChangedProps.Property("AccountingProcedureAC") 
		Or UpdateAll Then
		
		ChoiceParametersValues = TMCommonUseClientServer.PickingParameters(Items.ExpenseItemAccounting, ThisObject);

		NonCurrentAssets.SetArticleSelectionParametersByAccountingOrder(
			Items.ExpenseItemAccounting.ChoiceParameters,
			ChoiceParametersValues);
		
	EndIf;
	
	If StructureOfChangedProps.Property("AccountingProcedureMA") 
		Or UpdateAll Then
		
		ChoiceParametersValues = TMCommonUseClientServer.PickingParameters(Items.ExpenseItemManagementAccounting, ThisObject);

		NonCurrentAssets.SetArticleSelectionParametersByAccountingOrder(
			Items.ExpenseItemManagementAccounting.ChoiceParameters,
			ChoiceParametersValues);
		
	EndIf;

	IntangibleAssetsInitialRecognitionLocalization.ConfigureDependentFormElements(ThisObject, StructureOfChangedProps);
	
	ConfigureDependentFormElementsOnClientOnServer(ThisObject, ChangedBankingDetails);
	
EndProcedure
 
&AtClient
Function RequiresServerCallToConfigureFormElements(StructureOfChangedProps)

	If StructureOfChangedProps.Count() = 0
		Or StructureOfChangedProps.Property("Date") 
		Or StructureOfChangedProps.Property("Organization") 
		Or StructureOfChangedProps.Property("RecordInLocalAccounting")
		Or StructureOfChangedProps.Property("RecordInManAccounting") Then
			
		Return True;
	EndIf; 
	
	Return FixedAssetsInitialRecognitionClientLocalization.RequiresServerCallToConfigureFormElements(Object, StructureOfChangedProps);

EndFunction

&AtClientAtServerNoContext
Procedure OnChangeAttributes(Form, StructureOfChangedProps)

	If StructureOfChangedProps.Count() = 0 Then
		Return; 
	EndIf; 
	
	Object = Form.Object;
	
	If StructureOfChangedProps.Property("Organization") Then
		
		If Not Form.FormServiceParameters.ThereAreRelatedCompanies Then
			Object.TransferExpensesToAnotherCompany = False;
			StructureOfChangedProps.Insert("TransferExpensesToAnotherCompany");
		EndIf;
		
	EndIf;
	
	IntangibleAssetsInitialRecognitionClientServerLocalization.OnChangeAttributes(Form, StructureOfChangedProps);
	
EndProcedure
 
&AtClientAtServerNoContext
Procedure FillInDetailsDependingOnProperties(Form, ItemDetailsParameters, ChangedBankingDetails)

	Object = Form.Object;
	
	For Each AttributeParameters In ItemDetailsParameters Do
		
		If Not ValueIsFilled(AttributeParameters.AttributeName)
			Or StrSplit(AttributeParameters.AttributeName, ".").UBound() <> 0 Then
			Continue;
		EndIf;
		
		Action = NonCurrentAssetsClientServer.ClearOrFill(Object, AttributeParameters);
		
		If Not ValueIsFilled(Action) Then
			Continue;
		EndIf;
		
		#Region TheAccountingPage
		
		If AttributeParameters.AttributeName = "AccountingProcedureAC" Then
			If Action = "Fill" Then
				Object[AttributeParameters.AttributeName] = PredefinedValue("Enum.FixedAssetValueRegistrationProcedure.AccrueDepreciationOrAmortization");
				ChangedBankingDetails.Add(AttributeParameters.AttributeName);
			EndIf;
		EndIf;
		
		If AttributeParameters.AttributeName = "DepreciationMethodAccounting" Then
			If Action = "Fill" Then
				Object[AttributeParameters.AttributeName] = PredefinedValue("Enum.AccrualMethodOfIntangibleAssetDepreciation.Linear");
				ChangedBankingDetails.Add(AttributeParameters.AttributeName);
			EndIf;
		EndIf;
	
		If AttributeParameters.AttributeName = "AccountingProcedureMA" Then
			If Action = "Fill" Then
				Object[AttributeParameters.AttributeName] = PredefinedValue("Enum.FixedAssetValueRegistrationProcedure.AccrueDepreciationOrAmortization");
				ChangedBankingDetails.Add(AttributeParameters.AttributeName);
			EndIf;
		EndIf;
		
		If AttributeParameters.AttributeName = "DepreciationAccrualMethodManagementAccounting" Then
			If Action = "Fill" Then
				Object[AttributeParameters.AttributeName] = PredefinedValue("Enum.AccrualMethodOfIntangibleAssetDepreciation.Linear");
				ChangedBankingDetails.Add(AttributeParameters.AttributeName);
			EndIf;
		EndIf;
		
		#EndRegion
		
		IntangibleAssetsInitialRecognitionClientServerLocalization.FillInDetailsDependingOnProperties(
			Form, AttributeParameters, Action, ChangedBankingDetails);
		
	EndDo; 
	
EndProcedure

&AtServer
Procedure FillInInformationInBasement()

	LabelTitle = NonCurrentAssetsInternal.DocumentInformationInAnotherAccounting(Object);
	If PreliminaryCostDiffersFromActual() Then
		If LabelTitle.Count() <> 0 Then
			LabelTitle.Add(Chars.LF);
		EndIf;
		LabelTitle.Add(NStr("vi = 'Giá trị tạm tính khác với giá trị thực tế.';
							|ru = 'Предварительная стоимость отличается от фактической.';
							|en = 'The preliminary cost differs from the actual cost.'; fa = 'The preliminary cost differs from the actual cost.';
							|it = 'The preliminary cost differs from the actual cost.';
							|pl = 'The preliminary cost differs from the actual cost.';
							|tr = 'Ön maliyet, gerçek maliyetten farklıdır.'"));
	EndIf; 
	
	If LabelTitle.Count() <> 0 Then
		Items.Information.Title = New FormattedString(LabelTitle);
		Items.Information.Visible = True;
		Items.PictureInformation.Visible = True;
	Else
		Items.Information.Visible = False;
		Items.PictureInformation.Visible = Items.BasementInformationPreliminaryCostText.Visible;
	EndIf; 
	
EndProcedure

&AtServer
Function PreliminaryCostDiffersFromActual()

	If Not ValueIsFilled(Object.Ref) 
		Or Object.BusinessOperation = Enums.BusinessTransactions.IntangibleAssetsInitialRecognitionByInventoryCount Then
		Return False;
	EndIf;
	
	QueryText = 
	"SELECT
	|	IACost.IntangibleAsset AS IntangibleAsset
	|FROM
	|	AccumulationRegister.IACost AS IACost
	|WHERE
	|	IACost.Recorder = &Ref
	|	AND IACost.CostCalculation
	|	AND (IACost.RecordType = VALUE(AccumulationRecordType.Receipt))
	|
	|GROUP BY
	|	IACost.IntangibleAsset
	|
	|HAVING
	|	(&PostInAccounting
	|			AND &InitialCostLocalAccounting <> SUM(IACost.LocalCost + IACost.CostTargetFinancing)
	|			AND &AccountingProcedureAC <> VALUE(Enum.FixedAssetValueRegistrationProcedure.DoNotTakeIntoAccountIncludeInExpenses)
	|		OR &RecordInManAccounting
	|			AND &InitialCostMA <> SUM(IACost.Cost))
	|			AND &AccountingProcedureMA <> VALUE(Enum.FixedAssetValueRegistrationProcedure.DoNotTakeIntoAccountIncludeInExpenses)
	|";
	
	Query = New Query(QueryText);
	Query.SetParameter("Ref", Object.Ref);
	Query.SetParameter("IntangibleAsset", Object.IntangibleAsset);
	Query.SetParameter("InitialCostLocalAccounting", Object.InitialCostLocalAccounting);
	Query.SetParameter("InitialCostMA", Object.InitialCostMA);
	Query.SetParameter("PostInAccounting", Object.PostInAccounting);
	Query.SetParameter("RecordInManAccounting", Object.RecordInManAccounting);
	Query.SetParameter("AccountingProcedureAC", Object.AccountingProcedureAC);
	Query.SetParameter("AccountingProcedureMA", Object.AccountingProcedureMA);
	
	Result = Query.Execute();
	
	Return Not Result.IsEmpty();

EndFunction

&AtServer
Procedure FillInPreliminaryCost(ReportErrors)
	
	If Not FormServiceParameters.ThereIsCostAccounting Then
		Return;
	EndIf;
	
	Cancel = False;
	
	If Not ValueIsFilled(Object.Date) Then
		If ReportErrors Then
			MessageText = NStr("vi = 'Trường ""Ngày"" chưa điền';
								|ru = 'Поле ""Дата"" не заполнено';
								|en = '""Date"" is required'; fa = '""Date"" is required';
								|it = 'Il campo ""Data"" non è compilato';
								|pl = 'Pole ""Дата"" nie jest wypełnione';
								|tr = '""Tarih"" alanı doldurulmadı'");
			CommonClientServer.MessageToUser(MessageText,, "Object", "Date", Cancel);
		Else
			Cancel = True;
		EndIf;
	EndIf;
	
	If Not ValueIsFilled(Object.Organization) Then
		If ReportErrors Then
			MessageText = NStr("vi = 'Chưa điền trường ""Doanh nghiệp""';
								|ru = 'Поле ""Организация"" не заполнено';
								|en = '""Company"" is required'; fa = '""Company"" is required';
								|it = 'Il campo ""Società"" non è compilato';
								|pl = 'Nie wypełniono pola ""Firma""';
								|tr = '""İş yeri"" alanı doldurulmadı'");
			CommonClientServer.MessageToUser(MessageText,, "Object", "Organization", Cancel);
		Else
			Cancel = True;
		EndIf;
	EndIf;
	
	If Not ValueIsFilled(Object.IntangibleAsset) Then
		If ReportErrors Then
			MessageText = NStr("vi = 'Trường Tài sản vô hình trống';
								|ru = 'Поле ""Нематериальный актив"" не заполнено';
								|en = '""Intangible asset"" is required'; fa = '""Intangible asset"" is required';
								|it = 'Il campo ""Bene immateriale"" non è compilato';
								|pl = 'Pole ""Aktywa niematerialne"" nie jest wypełnione';
								|tr = '""Maddi olmayan duran varlık"" alanı boş'");
			CommonClientServer.MessageToUser(MessageText,, "Object", "IntangibleAsset", Cancel);
		Else
			Cancel = True;
		EndIf;
	EndIf;
	
	If Not Cancel Then
		Documents.IntangibleAssetsInitialRecognition2_4.FillInCost(Object);
		FillInInformationInBasement();
	EndIf;
	
EndProcedure

&AtServer
Procedure ConfigureHFCSelectionParameters()
	
	ParametersArray = New Array;
	
	If Object.KindOfAccountingObject = Enums.IntangibleAssetsAccountingItemKinds.IntangibleAsset Then
		ParametersArray.Add(New ChoiceParameter("Filter.AssetKind", Enums.KindsOfNonCurrentAssets.IA));
	Else
		ParametersArray.Add(New ChoiceParameter("Filter.AssetKind", Enums.KindsOfNonCurrentAssets.RD));
	EndIf;
	
	Items.FinancialAccountingGroup.ChoiceParameters = New FixedArray(ParametersArray);
	
EndProcedure

&AtClientAtServerNoContext
Procedure FillInDetailsValuesBeforeChange(Form)

	AttributesValuesBeforeChange = New Structure();
	AttributesValuesBeforeChange.Insert("UsefulLifeAccounting", Form.Object.UsefulLifeAccounting);
	AttributesValuesBeforeChange.Insert("UsefulLifeManagementAccounting", Form.Object.UsefulLifeManagementAccounting);
	AttributesValuesBeforeChange.Insert("InitialCostLocalAccounting", Form.Object.InitialCostLocalAccounting);
	AttributesValuesBeforeChange.Insert("InitialCostMA", Form.Object.InitialCostMA);
	
	IntangibleAssetsInitialRecognitionClientServerLocalization.AddDetailsValuesBeforeChanges(Form, AttributesValuesBeforeChange);
	
	Form.AttributesValuesBeforeChange = New FixedStructure(AttributesValuesBeforeChange);

EndProcedure

&AtServer
Procedure InitialCostOfBUWhenChangingOnServer()

	FillInDetailsValuesBeforeChange(ThisObject);
	FillInInformationInBasement();

	ConfigureDependentFormElementsOnServer("InitialCostLocalAccounting");
		
EndProcedure

&AtServer
Procedure InitialCostOfMAWhenChangedOnServer()

	FillInDetailsValuesBeforeChange(ThisObject);
	FillInInformationInBasement();

EndProcedure

&AtServer
Procedure ViewOfAccountingObjectWhenChangedOnServer(ChangedBankingDetails)
	
	FillInMethodsOfDepreciation(ThisObject);
		
	If Object.KindOfAccountingObject = PredefinedValue("Enum.IntangibleAssetsAccountingItemKinds.RDExpenses") Then
		If Object.DepreciationAccrualMethodManagementAccounting = PredefinedValue("Enum.AccrualMethodOfIntangibleAssetDepreciation.ReducedBalance") Then
			Object.DepreciationAccrualMethodManagementAccounting = Undefined;
			ChangedBankingDetails = ChangedBankingDetails + ",DepreciationAccrualMethodManagementAccounting";
		EndIf;
		If Object.DepreciationMethodAccounting = PredefinedValue("Enum.AccrualMethodOfIntangibleAssetDepreciation.ReducedBalance") Then
			Object.DepreciationMethodAccounting = Undefined;
			ChangedBankingDetails = ChangedBankingDetails + ",DepreciationMethodAccounting";
		EndIf;
	EndIf;
	
	If Object.KindOfAccountingObject = Enums.IntangibleAssetsAccountingItemKinds.RDExpenses Then
		CapitalAssetKind = Enums.KindsOfNonCurrentAssets.RD;
	Else
		CapitalAssetKind = Enums.KindsOfNonCurrentAssets.IA;
	EndIf;
	Object.FinancialAccountingGroup = Catalogs.NonCurrentAssetsAccountingGroups.DefaultValue(CapitalAssetKind);
	
	ConfigureHFCSelectionParameters();
	
EndProcedure

&AtServer
Procedure OrganizationWhenChangedOnServer()
	
	ACCurrency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Object.Organization);
	
	Object.VATTaxation = NonCurrentAssets.VATTaxation(Object.Organization, Object.Date);
	
	ConfigureDependentFormElementsOnServer("Organization,VATTaxation");
	
EndProcedure

&AtServer
Procedure InitializeServiceParametersOfForm()

	NewServiceParametersOfForm = New Structure;
	NewServiceParametersOfForm.Insert("ThereIsCostAccounting", False);
	NewServiceParametersOfForm.Insert("ComplianceCAAccountingIsKept", NonCurrentAssetsInternal.ComplianceCAAccountingIsKept());
	
	NewServiceParametersOfForm.Insert(
		"UseAccountingByAreasOfActivity", 
		GetFunctionalOption("UseFixedAssetAccountingByActivities"));
	
	FormServiceParameters = New FixedStructure(NewServiceParametersOfForm);

EndProcedure

&AtClient
Procedure GeneratedDocumentOnChangeCompletion(ClosingResult, AdditionalParameters) Export

	If ValueIsFilled(ClosingResult) Then
		Object.DocumentBasis = ClosingResult;
	Else
		Object.GeneratedDocument = False;
	EndIf;
	
	If ValueIsFilled(Object.DocumentBasis) Then
		QueryText = NStr("vi = 'Điền chứng từ theo kiểm kê?';
						|ru = 'Заполнить документ по инвентаризации?';
						|en = 'Fill in the physical inventory count document?'; fa = 'Fill in the physical inventory count document?';
						|it = 'Fill in the physical inventory count document?';
						|pl = 'Fill in the physical inventory count document?';
						|tr = 'Belge stok sayımına göre doldurulsun mu?'");
		CallbackDescription = New CallbackDescription("FillInAccordingToBaseEnd", ThisObject);
		ShowQueryBox(CallbackDescription, QueryText, QuestionDialogMode.YesNo); 
	EndIf; 
	
EndProcedure

&AtClient
Procedure FillInAccordingToBaseEnd(QuestionResult, AdditionalParameters) Export
	
	If QuestionResult = DialogReturnCode.Yes Then
		FillInAccordingToBaseDataOnServer();
	EndIf;
	
EndProcedure

&AtServer
Procedure FillInAccordingToBaseDataOnServer()
	
	Documents.IntangibleAssetsInitialRecognition2_4.FillInBasedOnInventory(Object, True);
	
	ConfigureDependentFormElementsOnServer("GeneratedDocument");
	
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

&AtClient
Procedure AtEndOfChangingLocalizationDetails(TagName, NotificationParameters) Export
	
	Var ActionParameters;

	If NotificationParameters.ServerCallRequired_ Then
		WhenYouChangeDetailsOfCompletionOnServer(TagName, NotificationParameters.ProcessingParameters);
		Return;
	EndIf;

	If NotificationParameters.ProcessingParameters.Property("Execute_WhenChangingPeriodOfUse", ActionParameters) Then
		WhenChangingPeriodOfUse(ActionParameters.AttributeName, ActionParameters.UpdateIfMatch);
	EndIf;

	If NotificationParameters.ProcessingParameters.Property("Execute_ConfigureDependentFormElements", ActionParameters) Then
		ConfigureDependentFormElementsOnClientOnServer(ThisObject, ActionParameters);
	EndIf; 
	
EndProcedure

&AtClient
Procedure ContinueRunningLocalizationCommand(CommandName, NotificationParameters) Export

	Var ActionParameters;
	
	If NotificationParameters.ServerCallRequired_ Then
		WhenExecutingEndCommandOnServer(CommandName, NotificationParameters.ProcessingParameters);
		Return;
	EndIf;

	If NotificationParameters.ProcessingParameters.Property("Execute_ConfigureDependentFormElements", ActionParameters) Then
		ConfigureDependentFormElementsOnClientOnServer(ThisObject, ActionParameters);
	EndIf; 
	
EndProcedure

&AtServer
Procedure OrderOfAccountingForBUWhenChangingOnServer()

	ChangedBankingDetails = NonCurrentAssetsClientServer.WhenChangingAccountingProcedureBU_NMA(Object, FormServiceParameters, True);
	
	If ValueIsFilled(Object.ExpenseItemAccounting) Then
		
		CostAllocationOptions = NonCurrentAssetsClientServer.AvailableCostSharingOptions(Object.AccountingProcedureAC);
		If CostAllocationOptions.Count() <> 0 Then
			
			AllocationOption = Common.ObjectAttributeValue(Object.ExpenseItemAccounting, "CostAllocationOptionLocal");
			
			If CostAllocationOptions.Find(AllocationOption) = Undefined Then
			
				Object.ExpenseItemAccounting = Undefined;
				Object.ExpensesDimensionAccounting = Undefined;
				IncomeAndExpensesClientServer.AssetRefOnChange(ThisObject, Items.ExpenseItemAccounting);
				
				ChangedBankingDetails = ChangedBankingDetails + ",ExpenseItemAccounting,ExpensesDimensionAccounting";
				
			EndIf;
			
		EndIf;
		
	EndIf;
	
	ConfigureDependentFormElementsOnServer(ChangedBankingDetails);
	
EndProcedure

&AtServer
Procedure AccountingProcedureForMAWhenChangingOnServer()
	
	ChangedBankingDetails = NonCurrentAssetsClientServer.WhenChangingOrderOfAccountingUU_NMA(Object, FormServiceParameters, True);
							
	If ValueIsFilled(Object.ExpenseItemManagementAccounting) Then
		
		CostAllocationOptions = NonCurrentAssetsClientServer.AvailableCostSharingOptions(Object.AccountingProcedureMA);
		If CostAllocationOptions.Count() <> 0 Then
			
			AllocationOption = Common.ObjectAttributeValue(Object.ExpenseItemManagementAccounting, "CostAllocationOptionManag");
			
			If CostAllocationOptions.Find(AllocationOption) = Undefined Then
				Object.ExpenseItemManagementAccounting = Undefined;
				Object.ExpensesDimensionManagementAccounting = Undefined;
				IncomeAndExpensesClientServer.AssetRefOnChange(ThisObject, Items.ExpenseItemManagementAccounting);
				ChangedBankingDetails = ChangedBankingDetails + ",ExpenseItemManagementAccounting,ExpensesDimensionManagementAccounting";
			EndIf;
			
		EndIf;
		
	EndIf;
	
	ConfigureDependentFormElementsOnServer(ChangedBankingDetails);
	
EndProcedure

&AtClient
Procedure WhenChangingPeriodOfUse(Var_AttributeName, UpdateIfMatch)

	AttributesList = NonCurrentAssetsClient.WhenChangingPeriodOfUse(
						Object, Var_AttributeName, UsefulLivesMatch And UpdateIfMatch);
	
	SetTermsOfUseToMatch(ThisObject);
	
	ConfigureDependentFormElementsOnClientOnServer(ThisObject, AttributesList);		

EndProcedure

&AtClientAtServerNoContext
Procedure SetTermsOfUseToMatch(Form)

	Form.UsefulLivesMatch = 
		(Not Form.Object.RecordInLocalAccounting 
					Or Not Form.FormServiceParameters.FALocalAccountingIsConductedIndependently
					Or (Form.Object.UsefulLifeAccounting = Form.Object.UsefulLifeTaxAccounting))
			And (Not Form.Object.RecordInManAccounting 
					Or (Form.Object.UsefulLifeAccounting = Form.Object.UsefulLifeManagementAccounting));

EndProcedure

&AtServer
Procedure ExecuteCommandAtServer(ExecutionParameters)
	AttachableCommands.ExecuteCommand(ThisObject, ExecutionParameters, Object);
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
