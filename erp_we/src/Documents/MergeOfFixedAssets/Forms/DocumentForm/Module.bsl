
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(Object, ThisObject);
	
	If Not ValueIsFilled(Object.Ref) Then
		
		OnReadCreateAtServer();
		
	EndIf;
	
	ItemsAndDimensionsSelectionParameters = Documents.MergeOfFixedAssets.ItemsAndDimensionsSelectionParameters();
	IncomeAndExpensesServer.OnCreateAtServer(ThisObject, ItemsAndDimensionsSelectionParameters);
	
	#Region UniversalMechanisms
	
	// StandardSubsystems.ObjectsVersioning
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.ObjectsVersioning
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	// StandardSubsystems.FilesOperations
	FilesHyperlink = FilesOperations.FilesHyperlink();
	FilesHyperlink.Location = "CommandBar";
	FilesOperations.OnCreateAtServer(ThisObject, FilesHyperlink);
	// End StandardSubsystems.FilesOperations
	
	Items.TraceableGoodsFixedAsset.ChoiceList.LoadValues(AvailableFixedAssets());	
	
	AccountingForTraceableGoodsLocalization.SetTitleNumberOfCCD(Items, 
		Items.TraceableGoodsCCDNumber.Name, True);
	
	FormEvents.OnCreateAtServer(ThisObject, Cancel, StandardProcessing);
	
	#EndRegion
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject);
	// End IntegrationWith1CDocumentManagementSubsystem
	
	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	// StandardSubsystems.FilesOperations
	FilesOperationsClient.OnOpen(ThisObject, Cancel);
	// End StandardSubsystems.FilesOperations

EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)
	
	// StandardSubsystems.AccessManagement
	AccessManagement.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.AccessManagement
	
	OnReadCreateAtServer();
	
	ItemsAndDimensionsSelectionParameters = Documents.MergeOfFixedAssets.ItemsAndDimensionsSelectionParameters();
	IncomeAndExpensesServer.OnReadAtServer(ThisObject, ItemsAndDimensionsSelectionParameters);
	
	// Handler of the "Date-change" mechanism
	PeriodClosingDates.ObjectOnReadAtServer(ThisObject, CurrentObject);
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	// End StandardSubsystems.AttachableCommands
	
	FormEvents.OnReadAtServer(ThisObject, CurrentObject);
	
EndProcedure

&AtClient
Procedure BeforeWrite(Cancel, WriteParameters)
	
	FormEventsClient.BeforeWrite(ThisObject, Cancel, WriteParameters);
	
	If WriteParameters.WriteMode = DocumentWriteMode.Posting And Not DataOnTraceableGoodsIsCorrect() Then
		Cancel = True;	
	EndIf;
	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.BeforeWriteAtServer(
		ThisObject,
		CurrentObject,
		WriteParameters);
	// End IntegrationWith1CDocumentManagementSubsystem
	
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	
	WriteParameters.Insert("NotificationDocumentKeys", OperationsWithDocumentJournalsClient.GetKeyParametersForDocument(
		Object.Ref, Object.Date, Object.BusinessOperation));
	Notify("Write_MergeOfFixedAssets", WriteParameters, Object.Ref);
	TMCommonUseClient.NotifyAboutEntryOfDocumentInJournal();
	NonCurrentAssetsClient.NotifyAboutDocumentEntryInFALog();
	
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
	
	FillInCurParameterValues();
	
	FillInInformationInBasement();
	
	FillInLineSelectionCriteria();
	
	IncomeAndExpensesServer.AfterWriteAtServer(ThisObject);
	
	ConfigurationModificationOverridable.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	
	FormEvents.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If EventName = "Write_MergeOfFixedAssets" Then
		FillInInformationInBasement();
	EndIf; 
	
	FormEventsClient.NotificationProcessing(ThisObject, EventName, Parameter, Source);
	
	// StandardSubsystems.FilesOperations
	FilesOperationsClient.NotificationProcessing(ThisObject, EventName);
	// End StandardSubsystems.FilesOperations

EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

#Region PageGeneral

&AtClient
Procedure DateOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi

	NonCurrentAssetsClient.SetCurrentTimeForLastDate(Object.Date);

	ConfigureDependentFormElements(Item);

	FillInCGUForSelectedFA();
	
EndProcedure

&AtClient
Procedure RecordInLocalAccountingOnChange(Item)
	
	If Not Object.RecordInLocalAccounting And Not Object.RecordInManAccounting Then
		Object.RecordInLocalAccounting = True;
	EndIf;
	
	ConfigureDependentFormElementsOnServer("RecordInLocalAccounting");

EndProcedure

&AtClient
Procedure RecordInManAccountingOnChange(Item)
	
	If Not Object.RecordInLocalAccounting And Not Object.RecordInManAccounting Then
		Object.RecordInManAccounting = True;
	EndIf;

	ConfigureDependentFormElementsOnServer("RecordInManAccounting");

EndProcedure

&AtClient
Procedure BusinessOperationOnChange(Item)
	
	If Not ValueIsFilled(Object.BusinessOperation) Then
		Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.MergeOfFixedAssets");
	EndIf;
	
	Object.FixedAsset = PredefinedValue("Catalog.Assets.EmptyRef");
	FillInFASelectionParameters();
	
	If Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.AttachingToExistingFixedAsset") Then
		
		Object.MergeOfSimilarFixedAssets = True;
		
		CheckUniformityOfFixedAssets();
		
	Else
		
		ConfigureDependentFormElements(Item);
		
		AttachableCommandsClient.StartCommandUpdate(ThisObject);
		
	EndIf; 
	
EndProcedure

&AtClient
Procedure OrganizationOnChange(Item)
	
	OrganizationOnChangeServer();
	
	FillInCGUForSelectedFA();
	
EndProcedure

&AtClient
Procedure FixedAssetOnChange(Item)
	
	WhenChangingFixedAssetInHeaderOnServer();
	
	FillInValuesOfFADetailsBeforeChange(ThisObject);
	
	FillInCGUForSelectedFA();
	
EndProcedure

&AtClient
Procedure MergeOfSimilarFixedAssetsOnChange(Item)
	
	If Object.MergeOfSimilarFixedAssets Then
		CheckUniformityOfFixedAssets();
	Else
		CombiningSameTypeOfFAWhenChangingOnServer();
	EndIf;
	
EndProcedure

&AtClient
Procedure LocationAddressOnChange(Item)
	
	WhenChangingAddressPresentation(Item);
	
EndProcedure

&AtClient
Procedure LocationAddressStartChoice(Item, ChoiceData, StandardProcessing)
	
	NonCurrentAssetsClient.OpenAddressSelectionFormAndProcessResult(
		ThisObject, 
		Item,
		Object,
		"LocationAddress",
		StandardProcessing);
	
EndProcedure

&AtClient
Procedure LocationAddressClearing(Item, StandardProcessing)
	
	WhenChangingAddressPresentation(Item);
	
EndProcedure

&AtClient
Procedure DocumentInformationInAnotherAccountingURLProcessing(Item, FormattedStringURL, StandardProcessing)
	
	If FormattedStringURL = "#CreateDocument" Then
		StandardProcessing = False;
		FormParameters = New Structure("Basis", Object.Ref);
		OpenForm("Document.MergeOfFixedAssets.ObjectForm", FormParameters);
	EndIf; 
	
EndProcedure

&AtClient
Procedure GroupPagesOnCurrentPageChange(Item, CurrentPage)
	
	If CurrentPage = Items.GroupPages.ChildItems.TraceableProductsPage Then
		Items.TraceableGoodsFixedAsset.ChoiceList.LoadValues(AvailableFixedAssets());
	EndIf;

EndProcedure

#EndRegion

#Region TheAccountingPage

&AtClient
Procedure AccountingProcedureACOnChange(Item)
	
	ChangedBankingDetails = NonCurrentAssetsClientServer.WhenChangingAccountingOrderOfBU_OS(Object, FormServiceParameters, True);

	ConfigureDependentFormElements(ChangedBankingDetails);
	
EndProcedure

&AtClient
Procedure UsefulLifeAccountingOnChange(Item)
	ConfigureDependentFormElements(Item.Name);
EndProcedure

&AtClient
Procedure ResidualUsefulLifeAccounting_OnChange(Item)
	ConfigureDependentFormElements(Item.Name);
EndProcedure

&AtClient
Procedure TermOfUseRemainingUsedCombiningTheSameTypeOfOSOnChange(Item)
	ConfigureDependentFormElements("ResidualUsefulLifeAccounting_");
EndProcedure

&AtClient
Procedure AccountingProcedureMAOnChange(Item)
	
	ChangedBankingDetails = NonCurrentAssetsClientServer.WhenChangingOrderOfAccountingUU_OS(Object, FormServiceParameters, True);
	
	If ValueIsFilled(ChangedBankingDetails) Then
		ConfigureDependentFormElements(ChangedBankingDetails);
	EndIf;
	
EndProcedure

&AtClient
Procedure UsefulLifeManagementAccountingOnChange(Item)
	
	WhenChangingPeriodOfUse("UsefulLifeManagementAccounting", False);
	
EndProcedure

&AtClient
Procedure ResidualUsefulLifeManagementAccounting_OnChange(Item)
	
	ConfigureDependentFormElements("ResidualUsefulLifeManagementAccounting_");
	
EndProcedure

&AtClient
Procedure DepreciationAccrualMethodManagementAccountingOnChange(Item)
	
	ConfigureDependentFormElements("DepreciationAccrualMethodManagementAccounting");
	
EndProcedure

#EndRegion

#Region PageExpenseRecord

&AtClient
Procedure ExpenseItemAccountingOnChange(Item)
	
	IncomeAndExpensesClientServer.AssetRefOnChange(ThisObject, Items.ExpenseItemAccounting);

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
Procedure ExpensesDimensionAccountingStartChoice(Item, ChoiceData, StandardProcessing)
	
	IncomeAndExpensesClient.StartSelectingExpenseAnalytics(ThisObject, Item, StandardProcessing);
	
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
Procedure ExpenseItemManagementAccountingOnChange(Item)
	
	IncomeAndExpensesClientServer.AssetRefOnChange(ThisObject, Items.ExpenseItemManagementAccounting);

	If ValueIsFilled(Object.MethodForReflectingMaExpenses) Then
		Object.MethodForReflectingMaExpenses = PredefinedValue("Catalog.WaysToReflectExpenses.EmptyRef");
	EndIf;
	
	ConfigureDependentFormElementsOnServer("MethodForReflectingMaExpenses,ExpenseItemManagementAccounting");
	
EndProcedure

&AtClient
Procedure ExpensesDimensionManagementAccountingOnChange(Item)

	If ValueIsFilled(Object.MethodForReflectingMaExpenses) Then
		Object.MethodForReflectingMaExpenses = PredefinedValue("Catalog.WaysToReflectExpenses.EmptyRef");
		ConfigureDependentFormElements("MethodForReflectingMaExpenses");
	EndIf;

EndProcedure

&AtClient
Procedure ExpenseItemManagementAccountingStartChoice(Item, ChoiceData, StandardProcessing)
	
	IncomeAndExpensesClient.StartArticleSelection(ThisObject, Item, StandardProcessing);
	
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

	ConfigureDependentFormElements(Item.Name);
	
EndProcedure

#EndRegion

#Region Localization

&AtClient
Procedure Attachable_OnChangeAttribute(Item)

	MergeOfFixedAssetsClientLocalization.OnChangeAttribute(Item, ThisObject);

EndProcedure

&AtClient
Procedure Attachable_StartChoice(Item, ChoiceData, StandardProcessing)
	
	MergeOfFixedAssetsClientLocalization.StartChoice(Item, ChoiceData, StandardProcessing, ThisObject);
	
EndProcedure

&AtClient
Procedure Attachable_AutoComplete(Item, Text, ChoiceData, DataGetParameters, Waiting, StandardProcessing)
	
	MergeOfFixedAssetsClientLocalization.AutoComplete(Item, Text, ChoiceData, DataGetParameters, Waiting, StandardProcessing, ThisObject);
	
EndProcedure

&AtClient
Procedure Attachable_TextEditEnd(Item, Text, ChoiceData, DataGetParameters, StandardProcessing)
	
	MergeOfFixedAssetsClientLocalization.TextEditEnd(Item, Text, ChoiceData, DataGetParameters, StandardProcessing, ThisObject);
	
EndProcedure

#EndRegion

#Region StandardSubsystems

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

#Region FormTableItemsEventHandlersFA

&AtClient
Procedure FAChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	SelectionOnServer(ValueSelected);
	
EndProcedure

&AtClient
Procedure FANodesComponentsChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	SelectionOnServer(ValueSelected, True);
	
EndProcedure

&AtClient
Procedure FAOnChange(Item)
	
	WhenChangingFixedAssetsOnServer();
	
EndProcedure

&AtClient
Procedure FAFixedAssetOnChange(Item)
	
	WhenChangingFixedAssetsOnServer();
	
EndProcedure

&AtClient
Procedure FAOnStartEdit(Item, NewRow, Copy)

	Item.CurrentData.ThisIsNodeComponent = False;

EndProcedure

&AtClient
Procedure FANodesComponentsOnChange(Item)

	If Item.CurrentData <> Undefined
		And Not Item.CurrentData.ThisIsNodeComponent Then
		Item.CurrentData.ThisIsNodeComponent = True;
	EndIf;
	WhenChangingComponentNodesOnServer();

EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Pick(Command)
	
	PerformanceMonitorClient.TimeMeasurement("Catalog.Assets.ChoiceForm");

	PickingParameters = TMCommonUseClientServer.PickingParameters(Items.FAFixedAsset, ThisObject);
	
	OpenForm("Catalog.Assets.ChoiceForm", 
					PickingParameters, Items.FA,,,,, 
					FormWindowOpeningMode.LockOwnerWindow)
	
EndProcedure

&AtClient
Procedure PickUpNodesComponents(Command)
	
	PickingParameters = TMCommonUseClientServer.PickingParameters(Items.FANodesComponentsFixedAsset, ThisObject);
	
	OpenForm("Catalog.Assets.ChoiceForm", 
					PickingParameters, Items.FANodesComponents,,,,, 
					FormWindowOpeningMode.LockOwnerWindow)
	
EndProcedure

&AtClient
Procedure ShowAccountingParameters(Command)
	ShowAccountingParametersOnServer();
EndProcedure

&AtClient
Procedure WriteDocument(Command)
	
	TMCommonUseClient.Write(ThisObject, True);
	
EndProcedure

&AtClient
Procedure PostAndClose(Command)
	
	TMCommonUseClient.PostAndClose(ThisObject);
	
EndProcedure

&AtClient
Procedure PostDocument(Command)
	
	TMCommonUseClient.Post(ThisObject);
	
EndProcedure

&AtClient
Procedure InformationOnBalanceOfTraceableGoods(Command)
			
	If Object.TraceableGoods.Count()>0 Then
		
		QueryText = NStr("vi = 'Trước khi điền, phần bảng chứng từ sẽ bị xóa, tiếp tục?';
						|ru = 'Перед заполнением табличная часть документа будет очищена, продолжить?';
						|en = 'The document table will be cleared before filling in. Do you want to continue?'; fa = 'The document table will be cleared before filling in. Do you want to continue?';
						|it = 'Prima del completamento, la parte tabellare del documento sarà cancellata. Continuare?';
						|pl = 'Przed wypełnieniem sekcja tabelaryczna zostanie wyczyszczona, kontynuować?';
						|tr = 'Doldurmadan önce, belgenin tablo kısmı temizlenecek, devam edecek mi?'");
		Notification = New CallbackDescription("AnswerToQuestionAboutClearingTablePart", ThisObject);
		
		ShowQueryBox(Notification, QueryText, QuestionDialogMode.YesNo); 
	Else
		PerformanceMonitorClient.TimeMeasurement(
		"Document.SplitFixedAssets.Form.DocumentForm.InformationOnBalanceOfTraceableGoods");
		FillInByRemainingTraceableItemsOnServer();	
		
	EndIf;
	
EndProcedure

&AtClient
Procedure GenerateStatement(Command)
	
	AvailableFixedAssets = AvailableFixedAssets();
	AvailableFixedAssets.Add(Object.FixedAsset);
	    
    Filter = New Structure;
    Filter.Insert("Organization", Object.Organization);    
	Filter.Insert("FixedAsset", AvailableFixedAssets);
	
	ReportPeriod = New StandardPeriod();
	ReportPeriod.StartDate = BegOfDay(Object.Date);
	ReportPeriod.EndDate = EndOfDay(Object.Date);
 	Filter.Insert("Period", ReportPeriod);
	
	FormParameters = New Structure("Filter, GenerateOnOpen, VariantKey", Filter, True, "Main");	
	
	AccountingForTraceableGoodsClientLocalization.GenerateStatement(FormParameters);
			
EndProcedure

#Region AttachableCommands

&AtClient
Procedure Attachable_ContinueCommandExecutionAtServer(ExecutionParameters, AdditionalParameters) Export
	ExecuteCommandAtServer(ExecutionParameters);
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

#Region OnChangeAttributes

&AtClient
Procedure AtEndOfChangingLocalizationDetails(TagName, NotificationParameters) Export
	
	Var ActionParameters;

	If NotificationParameters.ServerCallRequired_ Then
		WhenYouChangeDetailsOfCompletionOnServer(TagName, NotificationParameters.ProcessingParameters);
		Return;
	EndIf;

	If NotificationParameters.ProcessingParameters.Property("Execute_ConfigureDependentFormElements", ActionParameters) Then
		ConfigureDependentFormElements(ActionParameters);
	EndIf;

	If NotificationParameters.ProcessingParameters.Property("Execute_WhenChangingPeriodOfUse", ActionParameters) Then
		WhenChangingPeriodOfUse(ActionParameters.AttributeName, ActionParameters.UpdateIfMatch);
	EndIf;
	
EndProcedure

&AtServer
Procedure WhenYouChangeDetailsOfCompletionOnServer(Val TagName, Val AdditionalParameters)
	
	Var ActionParameters;

	If AdditionalParameters.Property("Execute_ConfigureDependentFormElements", ActionParameters) Then
		ConfigureDependentFormElementsOnServer(ActionParameters);
	EndIf;
	
	If AdditionalParameters.Property("Execute_FillInformationInBasement", ActionParameters) Then
		FillInInformationInBasement();
	EndIf;
	
EndProcedure

&AtClient
Procedure ConfigureDependentFormElements(Val ChangedDetailsOrElement = "")

	If TypeOf(ChangedDetailsOrElement) = Type("String") Then
		ChangedBankingDetails = ChangedDetailsOrElement;
	Else
		ChangedBankingDetails = ChangedDetailsOrElement.Name;
	EndIf;
	
	StructureOfChangedProps = New Structure(ChangedBankingDetails);
	
	If RequiresServerCallToConfigureFormElements(StructureOfChangedProps) Then
		ConfigureDependentFormElementsOnServer(ChangedBankingDetails)
	Else
		ConfigureDependentFormElementsOnClientOnServer(ThisObject, ChangedBankingDetails);
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Procedure ConfigureDependentFormElementsOnClientOnServer(Form, ChangedBankingDetails)

	Object = Form.Object;
	Items = Form.Items;
	FormServiceParameters = Form.FormServiceParameters;
	
	AuxiliaryAttributes = New Structure;
	AuxiliaryAttributes.Insert("RecordInLocalAccounting", Object.RecordInLocalAccounting);
	AuxiliaryAttributes.Insert("RecordInManAccounting", Object.RecordInManAccounting);
	AuxiliaryAttributes.Insert("PostInAccounting", Object.RecordInLocalAccounting);
	AuxiliaryAttributes.Insert("RecordInTA", Object.RecordInLocalAccounting);
	AuxiliaryAttributes.Insert("ComplianceCAAccountingIsKept", Form.ComplianceCAAccountingIsKept);
	AuxiliaryAttributes.Insert("CurrenciesDoNotMatch", Form.CurrenciesDoNotMatch);
	AuxiliaryAttributes.Insert("AccordingToMaOperatingTime", FormServiceParameters.AccordingToMaOperatingTime);
	AuxiliaryAttributes.Insert("AccordingToOperatingTimeOfAC", FormServiceParameters.AccordingToOperatingTimeOfAC);
	AuxiliaryAttributes.Insert("AvailableMaDepreciationParameters", FormServiceParameters.AvailableMaDepreciationParameters);
	AuxiliaryAttributes.Insert("ACDepreciationParametersAreAvailable", FormServiceParameters.ACDepreciationParametersAreAvailable);
	AuxiliaryAttributes.Insert("UsedByCF", FormServiceParameters.UsedByCF);
	AuxiliaryAttributes.Insert("FALocalAccountingIsConductedIndependently", FormServiceParameters.FALocalAccountingIsConductedIndependently);
	AuxiliaryAttributes.Insert("ThereAreRelatedCompanies", FormServiceParameters.ThereAreRelatedCompanies);
	MergeOfFixedAssetsClientServerLocalization.AddAuxiliaryDetails(Form, AuxiliaryAttributes);
	
	NonCurrentAssetsClientServer.WhenChangingBankingDetails_MergeFA(Object, AuxiliaryAttributes, ChangedBankingDetails);
	
	StructureOfChangedProps = New Structure(ChangedBankingDetails);
	UpdateAll = StructureOfChangedProps.Count() = 0;
	
	ItemDetailsParameters = NonCurrentAssetsClientServer.PropertyValuesOfDependentProps_FAUnion(
									Object, AuxiliaryAttributes, ChangedBankingDetails);
									
	TMCommonUseClientServer.ConfigureDependentFormElements(Form, ItemDetailsParameters);
	
	If Not UpdateAll Then
		
		TMCommonUseClientServer.ClearUnusedProps(Object, ItemDetailsParameters, "FA");
		
		ChangedBankingDetails = NonCurrentAssetsClientServer.FillInDetailsDependingOnProperties__FA_(Object, ItemDetailsParameters);

		If ValueIsFilled(ChangedBankingDetails) Then
			NonCurrentAssetsClientServer.WhenChangingBankingDetails_MergeFA(Object, AuxiliaryAttributes, ChangedBankingDetails);
			ItemDetailsParameters = NonCurrentAssetsClientServer.PropertyValuesOfDependentProps_FAUnion(
											Object, AuxiliaryAttributes, ChangedBankingDetails);
		
			TMCommonUseClientServer.ConfigureDependentFormElements(Form, ItemDetailsParameters);
		EndIf;
	EndIf;
	
	FAPoolingOptions = NonCurrentAssetsClientServer.FAPoolingOptions(Object, AuxiliaryAttributes);

	LocalAccountingSettingsAreAvailable = (Object.RecordInLocalAccounting And AuxiliaryAttributes.ComplianceCAAccountingIsKept);
	
	#Region PageGeneral
	
	If StructureOfChangedProps.Property("Organization")
		Or StructureOfChangedProps.Property("Date")
		Or UpdateAll Then

		Items.RecordInLocalAccounting.Visible = FormServiceParameters.FALocalAccountingIsConductedIndependently;
		Items.RecordInManAccounting.Visible = FormServiceParameters.FALocalAccountingIsConductedIndependently;
		Items.DecorationIsReflectionOption.Visible = Items.RecordInLocalAccounting.Visible Or Items.RecordInManAccounting.Visible;
		
		If Not FormServiceParameters.FALocalAccountingIsConductedIndependently 
			And Not UpdateAll Then

			Object.RecordInLocalAccounting = True;
			Object.RecordInManAccounting = True;
		EndIf;

	EndIf;
	
	If StructureOfChangedProps.Property("BusinessOperation")
		Or UpdateAll Then
		
		Items.OSPage.Title = ?(Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.AttachingToExistingFixedAsset"), 
											NStr("vi = 'Tài sản cố định có thể đính kèm';
												|ru = 'Присоединяемые основные средства';
												|en = 'Attached fixed assets'; fa = 'Attached fixed assets';
												|it = 'Capitali fissi collegati';
												|pl = 'Dołączane środki trwałe';
												|tr = 'Eklenen sabit kıymetler'"), 
											NStr("vi = 'Tài sản cố định hợp nhất';
												|ru = 'Объединяемые основные средства';
												|en = 'Merged fixed assets'; fa = 'Merged fixed assets';
												|it = 'Capitali fissi uniti';
												|pl = 'Połączane środki trwałe';
												|tr = 'Birleştirilen sabit kıymetler'"));
											
		Items.FixedAsset.ToolTip = ?(Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.AttachingToExistingFixedAsset"),
			NStr("vi = 'Một tài sản cố định mà tài sản cố định khác được đính kèm.';
				|ru = 'Основное средство, к которому присоединены другие основные средства.';
				|en = 'The fixed asset to which other fixed assets are attached.'; fa = 'The fixed asset to which other fixed assets are attached.';
				|it = 'Capitale fisso al quale vengono collegati altri capitali fissi.';
				|pl = 'Środek trwały, do którego są dołączone inne środki trwałe.';
				|tr = 'Diğer sabit kıymetlerin bağlı olduğu bir sabit kıymet.'"),
			NStr("vi = 'Các tài sản cố định kết quả từ sự kết hợp.';
				|ru = 'Основное средство, которое получено в результате объединения.';
				|en = 'Fixed asset as a result of merge.'; fa = 'دارایی ثابت حاصل از ادغام.';
				|it = 'Capitale fisso ottenuto come risultato di unione.';
				|pl = 'Środek trwały uzyskany w wyniku połączenia.';
				|tr = 'Birleşmeden elde edilen sabit kıymet.'"));
			
		Items.FAFixedAsset.ToolTip = ?(Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.AttachingToExistingFixedAsset"),
			NStr("vi = 'Tài sản chính cần được gắn vào tài sản cố định được chấp nhận cho kế toán.';
				|ru = 'Основное средство, которое нужно присоединить к принятому к учету основному средству.';
				|en = 'The fixed asset that needs to be attached to a recognized fixed asset.'; fa = 'The fixed asset that needs to be attached to a recognized fixed asset.';
				|it = 'Capitale fisso che deve essere collegato ad un capitale fisso registrato in contabilità.';
				|pl = 'Środek trwały, który należy dołączyć do przyjętego do ewidencji środka trwałego.';
				|tr = 'Muhasebeleştirilmiş bir sabit kıymetin bir sabit kıymet kalemine eklenmesi.'"),
			NStr("vi = 'Một tài sản cố định cần được kết hợp với các tài sản cố định khác.';
				|ru = 'Основное средство, которое нужно объединить с другими основными средствами.';
				|en = 'The fixed asset that needs to be merged to other fixed assets.'; fa = 'The fixed asset that needs to be merged to other fixed assets.';
				|it = 'Capitale fisso che deve essere unito ad altri capitali fissi.';
				|pl = 'Środek trwały, który należy połączyć z innymi środkami trwałymi.';
				|tr = 'Sabit kıymetlerin diğer sabit kıymetlerle birleştirilmesi.'"));
			
	EndIf;
	
	#EndRegion
	
	#Region OSPage
	
	If StructureOfChangedProps.Property("Date")
		Or StructureOfChangedProps.Property("Organization")
		Or StructureOfChangedProps.Property("ShowAccountingParameters")
		Or StructureOfChangedProps.Property("RecordInLocalAccounting")
		Or StructureOfChangedProps.Property("RecordInManAccounting")
		Or UpdateAll Then
		
		PropertyValue = Form.ShowAccountingParameters And Object.RecordInLocalAccounting And FormServiceParameters.FALocalAccountingIsConductedIndependently;
		Items.FAUsefulLifeAccounting.Visible = PropertyValue;
		Items.FAResidualLifetimeAC.Visible = PropertyValue;
		Items.FADepreciationMethodAccounting.Visible = PropertyValue;

		PropertyValue = Form.ShowAccountingParameters And Object.RecordInManAccounting;
		Items.FAUsefulLifeManagementAccounting.Visible = PropertyValue;
		Items.FAResidualLifetimeMA.Visible = PropertyValue;
		Items.FADepreciationAccrualMethodManagementAccounting.Visible = PropertyValue;
		
		//
		Items.FAUsefulLifeAccounting.Title = 
			?(Object.RecordInManAccounting Or Object.RecordInLocalAccounting And Form.ComplianceCAAccountingIsKept,
				NStr("vi = 'KTDN';
					|ru = 'БУ';
					|en = 'LA'; fa = 'محلی';
					|it = 'Contabilità';
					|pl = 'LA';
					|tr = 'Genel Muhasebe'"),
				NStr("vi = 'Thời hạn sử dụng, tháng';
					|ru = 'Срок использования, мес';
					|en = 'Useful life, months'; fa = 'عمر مفید، ماه';
					|it = 'Vita utile, mese';
					|pl = 'Okres użytkowania, mies.';
					|tr = 'Kullanım süresi, ay'"));
		
		Items.FAResidualLifetimeAC.Title = 
			?(Object.RecordInManAccounting Or Object.RecordInLocalAccounting And Form.ComplianceCAAccountingIsKept,
				NStr("vi = 'KTDN';
					|ru = 'БУ';
					|en = 'LA'; fa = 'محلی';
					|it = 'Contabilità';
					|pl = 'EK';
					|tr = 'Genel Muhasebe'"),
				NStr("vi = 'Thời hạn sử dụng còn lại , tháng';
					|ru = 'Остаточный срок использования, мес';
					|en = 'Residual useful life, months'; fa = 'عمر مفید باقی‌مانده، ماه';
					|it = 'Vita utile residua, mesi';
					|pl = 'Pozostały okres użytkowania, mies';
					|tr = 'Kalan kullanım süresi, ay'"));
		
		Items.FADepreciationMethodAccounting.Title = 
			?(Object.RecordInManAccounting Or Object.RecordInLocalAccounting And Form.ComplianceCAAccountingIsKept,
				NStr("vi = 'KTDN';
					|ru = 'БУ';
					|en = 'LA'; fa = 'محلی';
					|it = 'Contabilità';
					|pl = 'LA';
					|tr = 'Genel Muhasebe'"),
				NStr("vi = 'Phương pháp khấu hao';
					|ru = 'Метод начисления амортизации';
					|en = 'Depreciation method'; fa = 'روش استهلاک';
					|it = 'Metodo di maturazione dell''ammortamento';
					|pl = 'Metoda naliczania amortyzacji';
					|tr = 'Amortisman tahakkuk yöntemi'"));
		
		//
		Items.FAUsefulLifeManagementAccounting.Title = 
			?(Object.RecordInLocalAccounting And FormServiceParameters.FALocalAccountingIsConductedIndependently,
				NStr("vi = 'QT';
					|ru = 'УУ';
					|en = 'MA'; fa = 'مدیریت';
					|it = 'Contabilità Gestionale';
					|pl = 'MA';
					|tr = 'Yönetim Muhasebesi'"),
				NStr("vi = 'Thời hạn sử dụng, tháng';
					|ru = 'Срок использования, мес';
					|en = 'Useful life, months'; fa = 'عمر مفید، ماه';
					|it = 'Vita utile, mese';
					|pl = 'Okres użytkowania, mies.';
					|tr = 'Kullanım süresi, ay'"));
				
		Items.FAResidualLifetimeMA.Title = 
			?(Object.RecordInLocalAccounting And FormServiceParameters.FALocalAccountingIsConductedIndependently,
				NStr("vi = 'QT';
					|ru = 'УУ';
					|en = 'MA'; fa = 'مدیریت';
					|it = 'Contabilità Gestionale';
					|pl = 'MA';
					|tr = 'Yönetim Muhasebesi'"),
				NStr("vi = 'Thời hạn sử dụng còn lại , tháng';
					|ru = 'Остаточный срок использования, мес';
					|en = 'Residual useful life, months'; fa = 'عمر مفید باقی‌مانده، ماه';
					|it = 'Vita utile residua, mesi';
					|pl = 'Pozostały okres użytkowania, mies';
					|tr = 'Kalan kullanım süresi, ay'"));
				
		Items.FADepreciationAccrualMethodManagementAccounting.Title = 
			?(Object.RecordInLocalAccounting And FormServiceParameters.FALocalAccountingIsConductedIndependently,
				NStr("vi = 'QT';
					|ru = 'УУ';
					|en = 'MA'; fa = 'مدیریت';
					|it = 'Contabilità Gestionale';
					|pl = 'MA';
					|tr = 'Yönetim Muhasebesi'"),
				NStr("vi = 'Phương pháp khấu hao';
					|ru = 'Метод начисления амортизации';
					|en = 'Depreciation method'; fa = 'روش استهلاک';
					|it = 'Metodo di maturazione dell''ammortamento';
					|pl = 'Metoda naliczania amortyzacji';
					|tr = 'Amortisman tahakkuk yöntemi'"));
				
		//
		PropertyValue = 
			Object.RecordInLocalAccounting
			And Object.RecordInLocalAccounting 
			And FormServiceParameters.FALocalAccountingIsConductedIndependently;
					
		Items.OsgroupSPI.ShowInHeader = PropertyValue;
		Items.OsgroupResidualSPI.ShowInHeader = PropertyValue;
		Items.OsgroupDepreciationMethod.ShowInHeader = PropertyValue;
		
		//
		Items.FANodesComponentsLifetimeOfAC.Visible = Items.FAUsefulLifeAccounting.Visible;
		Items.FANodesComponentsResidualLifeOfAC.Visible = Items.FAResidualLifetimeAC.Visible;
		Items.FANodesComponentsACDepreciationMethod.Visible = Items.FADepreciationMethodAccounting.Visible;

		Items.FANodesComponentsMaUsagePeriod.Visible = Items.FAUsefulLifeManagementAccounting.Visible;
		Items.FANodesComponentsResidualLifeOfMa.Visible = Items.FAResidualLifetimeMA.Visible;
		Items.FANodesComponentsMaDepreciationMethod.Visible = Items.FADepreciationAccrualMethodManagementAccounting.Visible;
		
		Items.FANodesComponentsMaUsagePeriod.Title = Items.FAUsefulLifeManagementAccounting.Title;
		Items.FANodesComponentsResidualLifeOfMa.Title = Items.FAResidualLifetimeMA.Title;
		Items.FANodesComponentsMaDepreciationMethod.Title = Items.FADepreciationAccrualMethodManagementAccounting.Title;
		
		Items.FANodesComponentsSPIGroup.ShowInHeader = Items.OsgroupSPI.ShowInHeader;
		Items.FANodesComponentsGroupResidualSPI.ShowInHeader = Items.OsgroupResidualSPI.ShowInHeader;
		Items.FAUnitsComponentsGroupDepreciationMethod.ShowInHeader = Items.OsgroupDepreciationMethod.ShowInHeader;

	EndIf;
	
	If StructureOfChangedProps.Property("Date") Then
		FillInRemainingPeriodOfUse(Form);
	EndIf;
	
	#EndRegion
	
	#Region TheAccountingPage
	
	If StructureOfChangedProps.Property("RecordInManAccounting")
		Or UpdateAll Then
		
		Items.TermOfUseRemainingUsedCombiningTheSameTypeOfOS.Title = 
			?(Not Object.RecordInManAccounting,
				NStr("vi = 'Thời gian còn lại';
					|ru = 'Остаточный срок';
					|en = 'Residual period'; fa = 'دوره باقی‌مانده';
					|it = 'Durata residua';
					|pl = 'Pozostały okres';
					|tr = 'Kalan süre'"),
				NStr("vi = 'Thời hạn còn lại (KTDN)';
					|ru = 'Остаточный срок (БУ)';
					|en = 'Residual lifetime (LA)'; fa = 'عمر باقی‌مانده (محلی)';
					|it = 'Vita utile residua (contabilità)';
					|pl = 'Pozostały okres (EK)';
					|tr = 'Kalan süre (genel muhasebe)'"));
	EndIf;
	
	If StructureOfChangedProps.Property("UsefulLifeAccounting")
		Or StructureOfChangedProps.Property("AccountingProcedureAC")
		Or StructureOfChangedProps.Property("RecordInLocalAccounting")
		Or UpdateAll Then
		
		Form.ACUsefulLifeExplanation = NonCurrentAssetsClientServer.PresentationOfNumberOfMonthsByString(
			Object.UsefulLifeAccounting);
			
	EndIf;
	
	If StructureOfChangedProps.Property("ResidualUsefulLifeAccounting_")
		Or UpdateAll Then
		
		Form.TermUseResidualBorschagovka = NonCurrentAssetsClientServer.PresentationOfNumberOfMonthsByString(
			Object.ResidualUsefulLifeAccounting_);
			
	EndIf;
	
	If StructureOfChangedProps.Property("UsefulLifeManagementAccounting")
		Or StructureOfChangedProps.Property("AccountingProcedureMA")
		Or StructureOfChangedProps.Property("RecordInManAccounting")
		Or UpdateAll Then
		
		Form.UsefulLifeMAExplanation = NonCurrentAssetsClientServer.PresentationOfNumberOfMonthsByString(
			Object.UsefulLifeManagementAccounting);
			
	EndIf;
	
	If StructureOfChangedProps.Property("ResidualUsefulLifeManagementAccounting_")
		Or UpdateAll Then
		
		Form.TermOfUseResidualUurasshifrovka = NonCurrentAssetsClientServer.PresentationOfNumberOfMonthsByString(
			Object.ResidualUsefulLifeManagementAccounting_);
			
	EndIf;
	
	If StructureOfChangedProps.Property("RecordInLocalAccounting")
		Or UpdateAll Then
		
		Items.TermOfUseResidualYYCombiningTheSameTypeOfOS.Title = 
			?(Not Object.RecordInLocalAccounting Or Not AuxiliaryAttributes.ComplianceCAAccountingIsKept,
				NStr("vi = 'Thời gian còn lại';
					|ru = 'Остаточный срок';
					|en = 'Residual period'; fa = 'دوره باقی‌مانده';
					|it = 'Durata residua';
					|pl = 'Pozostały okres';
					|tr = 'Kalan süre'"),
				NStr("vi = 'Thời hạn còn lại (QT)';
					|ru = 'Остаточный срок (УУ)';
					|en = 'Residual period (MA)'; fa = 'دوره باقی‌مانده (مدیریت)';
					|it = 'Vita utile residua (CO)';
					|pl = 'Pozostały termin (EZ)';
					|tr = 'Kalan süre (yönetim muhasebesi)'"));
	EndIf;
	
	If StructureOfChangedProps.Property("Organization")
		Or UpdateAll Then
		
		Items.LiquidationValueReglCurrency.Title = String(Form.FormServiceParameters.ComplCurrency);
		
	EndIf;
	
	#EndRegion
	
	#Region PageExpenseRecord
	
	If StructureOfChangedProps.Property("RecordInLocalAccounting")
		Or StructureOfChangedProps.Property("RecordInManAccounting")
		Or StructureOfChangedProps.Property("AccountingProcedureMA")
		Or UpdateAll Then
		
		If Object.RecordInManAccounting 
			And Object.AccountingProcedureMA = PredefinedValue("Enum.FixedAssetValueRegistrationProcedure.IncludeInExpensesOnRecognition") Then
			
			Items.GroupAccountingForDepreciationAndAmortisationUpr.Title = 
				?(LocalAccountingSettingsAreAvailable, NStr("vi = 'Phản ánh chi phí (kế toán quản trị)';
															|ru = 'Отражение расходов (управленческий учет)';
															|en = 'Record expenses (management accounting)'; fa = 'Record expenses (management accounting)';
															|it = 'Riflessione spese (contabilità gestionale)';
															|pl = 'Odzwierciedlenie rozchodów (ewidencja zarządcza)';
															|tr = 'Giderlerin kaydı (yönetim muhasebesi)'"), NStr("vi = 'Khấu hao';
																													|ru = 'Амортизация';
																													|en = 'Depreciation'; fa = 'استهلاک';
																													|it = 'Ammortamento';
																													|pl = 'Depreciation';
																													|tr = 'Amortisman'"));
		Else	
			Items.GroupAccountingForDepreciationAndAmortisationUpr.Title = 
				?(LocalAccountingSettingsAreAvailable, NStr("vi = 'Khấu hao (kế toán quản trị)';
															|ru = 'Амортизация (управленческий учет)';
															|en = 'Depreciation (management accounting)'; fa = 'استهلاک (حسابداری مدیریتی)';
															|it = 'Ammortamento (contabilità gestionale)';
															|pl = 'Amortyzacja (ewidencja administracyjna)';
															|tr = 'Amortisman (yönetim muhasebesi)'"), NStr("vi = 'Khấu hao';
																												|ru = 'Амортизация';
																												|en = 'Depreciation'; fa = 'استهلاک';
																												|it = 'Ammortamento';
																												|pl = 'Depreciation';
																												|tr = 'Amortisman'"));
		EndIf; 
		
	EndIf;
	
	If StructureOfChangedProps.Property("AccountingProcedureTA")
		Or StructureOfChangedProps.Property("Organization")
		Or UpdateAll Then
		
		If FAPoolingOptions.AvailableReflectionOfBUExpenses 
			And FAPoolingOptions.ExpenseReflectionIsAvailable Then
			GroupTitle = NStr("vi = 'Khấu hao (kế toán doanh nghiệp và kế toán thuế)';
								|ru = 'Амортизация (бухгалтерский и налоговый учет)';
								|en = 'Depreciation (accounting and tax accounting)'; fa = 'Depreciation (accounting and tax accounting)';
								|it = 'Ammortamento (contabilità e contabilità gestionale)';
								|pl = 'Amortyzacja (ewidencja księgowa i podatkowa)';
								|tr = 'Amortisman (muhasebe ve vergi muhasebesi)'");
		ElsIf FAPoolingOptions.ExpenseReflectionIsAvailable Then
			GroupTitle = NStr("vi = 'Khấu hao (kế toán thuế)';
								|ru = 'Амортизация (налоговый учет)';
								|en = 'Depreciation (tax accounting)'; fa = 'استهلاک (حسابداری مالیاتی)';
								|it = 'Ammortamento (contabilità fiscale)';
								|pl = 'Amortyzacja (ewidencja podatkowa)';
								|tr = 'Amortisman (vergi muhasebesi)'");
		Else
			GroupTitle = NStr("vi = 'Khấu hao (kế toán doanh nghiệp)';
								|ru = 'Амортизация (бухгалтерский учет)';
								|en = 'Depreciation (local accounting)'; fa = 'استهلاک (حسابداری محلی)';
								|it = 'Ammortamento (contabilità ordinaria)';
								|pl = 'Amortyzacja (ewidencja księgowa)';
								|tr = 'Amortisman (genel muhasebe)'");
		EndIf; 
		Items.TheGroupIsAReflectionOfTheDepreciationExpenseOfRegl.Title = GroupTitle;
		
	EndIf;
	
	If StructureOfChangedProps.Property("RecordInLocalAccounting") 
		Or StructureOfChangedProps.Property("RecordInManAccounting") 
		Or StructureOfChangedProps.Property("AccountingProcedureAC") 
		Or StructureOfChangedProps.Property("AccountingProcedureTA") 
		Or StructureOfChangedProps.Property("AccountingProcedureMA") 
		Or StructureOfChangedProps.Property("Organization")
		Or StructureOfChangedProps.Property("ExpenseItemManagementAccounting") 
		Or StructureOfChangedProps.Property("ExpensesDimensionManagementAccounting") 
		Or StructureOfChangedProps.Property("MethodForReflectingMaExpenses") 
		Or StructureOfChangedProps.Property("BusinessUnitManagementAccounting") 
		Or StructureOfChangedProps.Property("LineOfBusinessManagementAccounting") 
		Or StructureOfChangedProps.Property("BusinessUnitAndLineOfBusinessMatchAccountingDataManagementAccounting") 
		Or UpdateAll Then
		
		If FAPoolingOptions.ExpenseItemManagementAccountingRequired_ 
			Or ValueIsFilled(Object.ExpenseItemManagementAccounting) Then
			
			Items.MethodForReflectingMaExpenses.InputHint = "";
			Items.ExpenseItemManagementAccounting.InputHint = "";
			Items.ExpensesDimensionManagementAccounting.InputHint = "";
			Items.BusinessUnitManagementAccounting.InputHint = "";
			Items.LineOfBusinessManagementAccounting.InputHint = "";
			
		ElsIf Not FAPoolingOptions.ExpenseItemManagementAccountingRequired_ Then
			
			If FAPoolingOptions.AvailableReflectionOfBUExpenses 
				And FAPoolingOptions.ExpenseReflectionIsAvailable Then
				ArticleInputPrompt = NStr("vi = 'trùng với kế toán doanh nghiệp và kế toán thuế';
											|ru = 'совпадает с бухгалтерским и налоговым учетом';
											|en = 'matches local accounting and tax accounting'; fa = 'matches local accounting and tax accounting';
											|it = 'corrisponde alla contabilità e la contabilità fiscale';
											|pl = 'jest zgodne z ewidencją księgową i podatkową';
											|tr = 'genel ve vergi muhasebesi ile örtüşmektedir'");
			ElsIf FAPoolingOptions.ExpenseReflectionIsAvailable Then
				ArticleInputPrompt = NStr("vi = 'trùng với kế toán thuế';
											|ru = 'совпадает с налоговым учетом';
											|en = 'matches tax accounting'; fa = 'matches tax accounting';
											|it = 'corrisponde alla contabilità fiscale';
											|pl = 'jest zgodne z ewidencją podatkową';
											|tr = 'vergi muhasebesi ile örtüşmektedir'");
			Else
				ArticleInputPrompt = NStr("vi = 'trùng với kế toán doanh nghiệp';
											|ru = 'совпадает с бухгалтерским учетом';
											|en = 'matches local accounting'; fa = 'matches local accounting';
											|it = 'corrisponde alla contabilità';
											|pl = 'jest zgodne z ewidencją księgową';
											|tr = 'genel muhasebe ile örtüşmektedir'");
			EndIf;
			
			Items.MethodForReflectingMaExpenses.InputHint = ArticleInputPrompt;
			Items.ExpenseItemManagementAccounting.InputHint = ArticleInputPrompt;
			Items.ExpensesDimensionManagementAccounting.InputHint = ArticleInputPrompt;
			Items.BusinessUnitManagementAccounting.InputHint = ArticleInputPrompt;
			Items.LineOfBusinessManagementAccounting.InputHint = ArticleInputPrompt;

		EndIf; 
		
	EndIf;

	If StructureOfChangedProps.Property("RecordInManAccounting")
		Or StructureOfChangedProps.Property("RecordInLocalAccounting")
		Or UpdateAll Then
			
		Items.GroupAccountingForDepreciationAndAmortisationUpr.ShowTitle = 
			(Object.RecordInManAccounting And Object.RecordInLocalAccounting);
			
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
		
	#EndRegion
	
	MergeOfFixedAssetsClientServerLocalization.ConfigureDependentFormElements(
		Form, 
		AuxiliaryAttributes,
		StructureOfChangedProps, 
		ItemDetailsParameters);
		
EndProcedure

&AtServer
Procedure ConfigureDependentFormElementsOnServer(ChangedBankingDetails = "")

	StructureOfChangedProps = New Structure(ChangedBankingDetails);
	
	UpdateAll = StructureOfChangedProps.Count() = 0;
	
	If UpdateAll Then
		
		NonCurrentAssetsInternal.SetStructureProperty(
			"ComplianceCAAccountingIsKept",
			NonCurrentAssetsInternal.ComplianceCAAccountingIsKept(),
			FormServiceParameters);

	EndIf;

	If StructureOfChangedProps.Property("BusinessOperation") 
		Or StructureOfChangedProps.Property("FixedAsset") 
		Or UpdateAll Then
		
		ThisIsOperationUnion = Object.BusinessOperation = Enums.BusinessTransactions.MergeOfFixedAssets;
		If ThisIsOperationUnion Then
			Items.PageFANodesComponents.Visible = False;
			ClearRowsBySelection(Object.FA, "ThisIsNodeComponent", True);
		Else
			Items.PageFANodesComponents.Visible = True;
		EndIf;
		
		OSType = Common.ObjectAttributeValue(Object.FixedAsset, "OSType");
		If ValueIsFilled(Object.FixedAsset) And (OSType = Enums.FATypes.Node
			Or OSType = Enums.FATypes.DepreciationComponent) Then
			Items.OSPage.Visible = False;
			ClearRowsBySelection(Object.FA, "ThisIsNodeComponent", False);
		Else
			Items.OSPage.Visible = True;
		EndIf;
		
		FillInLinksOfFASelectionParameters();
	EndIf;
	
	If StructureOfChangedProps.Property("Date") 
		Or UpdateAll Then

		AccountingForTraceableGoodsLocalization.SetVisibilityOfTraceableGoodsPage(ThisObject, Object.Date);

	EndIf;
	
	If StructureOfChangedProps.Property("Date") 
		Or StructureOfChangedProps.Property("Organization") Then
			
		FillInCurParameterValues();
		
	EndIf;
	
	If StructureOfChangedProps.Property("Date") 
		Or StructureOfChangedProps.Property("Organization")
		Or UpdateAll Then
		
		NonCurrentAssetsInternal.SetStructureProperty(
			"FALocalAccountingIsConductedIndependently",
			AccountingPoliciesTaxSettingsCached.FALocalAccountingIsConductedIndependently(Object.Organization, EndOfMonth(?(Object.Date <> '000101010000', Object.Date, CurrentSessionDate()))),
			FormServiceParameters);
		
	EndIf;
	
	If StructureOfChangedProps.Property("Organization") 
		Or StructureOfChangedProps.Property("FixedAsset") 
		Or StructureOfChangedProps.Property("BusinessOperation") 
		Or StructureOfChangedProps.Property("MergeOfSimilarFixedAssets") 
		Or UpdateAll Then
		
		If Object.MergeOfSimilarFixedAssets
			And Object.BusinessOperation = Enums.BusinessTransactions.MergeOfFixedAssets Then
			
			If ValueIsFilled(FormServiceParameters.FirstFA) Then
				TitleText = StrTemplate(NStr("vi = 'Các tham số trái trùng với tham số kế toán của tài sản cố định <a href = ""%1"">%2</a>';
											|ru = 'Остальные параметры совпадают с параметрами учета основного средства <a href = ""%1"">%2</a>';
											|en = 'Other parameters match with the fixed asset accounting parameters <a href = ""%1"">%2</a>'; fa = 'Other parameters match with the fixed asset accounting parameters <a href = ""%1"">%2</a>';
											|it = 'Остальные параметры совпадают с параметрами учета основного средства <a href = ""%1"">%2</a>';
											|pl = 'Other parameters match with the fixed asset accounting parameters <a href = ""%1"">%2</a>';
											|tr = 'Diğer parametreler sabit kıymetin muhasebe parametreleri ile aynıdır <a href = ""%1"">%2</a>'"),
												GetURL(FormServiceParameters.FirstFA),
												FormServiceParameters.FirstFAPresentation);
				TitleText = NonCurrentAssetsClientServer.FormattedString(TitleText);
			Else
				TitleText = NStr("vi = 'Các tham số trái trùng với tham số kế toán của tài sản cố định đầu tiên';
								|ru = 'Остальные параметры совпадают с параметрами учета первого основного средства';
								|en = 'Other parameters match with the first fixed asset accounting parameters'; fa = 'Other parameters match with the first fixed asset accounting parameters';
								|it = 'Altri parametri coincidono con i parametri della registrazione contabile del primo capitale fisso';
								|pl = 'Pozostałe parametry są identyczne z parametrami ewidencji pierwszego środka trwałego';
								|tr = 'Diğer parametreler ilk sabit kıymet için olanlarla aynıdır'");
			EndIf;
			
			Items.TheInscriptionTheRestOfTheOptions.Title = TitleText;
			Items.TheInscriptionTheRestOfTheOptions.Visible = True;
			Items.PictureOtherParameters.Visible = True;
			
		Else
			Items.TheInscriptionTheRestOfTheOptions.Visible = False;
			Items.PictureOtherParameters.Visible = False;
		EndIf; 
		
	EndIf;
	
	If StructureOfChangedProps.Property("Organization") 
		Or UpdateAll Then
		
		NonCurrentAssetsInternal.SetStructureProperty(
			"ComplCurrency",
			SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Object.Organization),
			FormServiceParameters);
		
		NonCurrentAssetsInternal.SetStructureProperty(
			"PresentationOfDetails",
			Documents.MergeOfFixedAssets.PresentationOfDetails(Object.Organization),
			FormServiceParameters);
		
		ParentCompany = AccountingPoliciesTaxSettingsCached.ParentCompany(Object.Organization);
		SetFormFunctionalOptionParameters(New Structure("Organization", ParentCompany));
		
		NonCurrentAssetsInternal.SetStructureProperty(
			"ThereAreRelatedCompanies",
			Catalogs.Companies.OrganizationIsInterconnectedWithOtherOrganizations(Object.Organization),
			FormServiceParameters);
			
	EndIf;
	
	MergeOfFixedAssetsLocalization.ConfigureDependentFormElements(ThisObject, StructureOfChangedProps);
	
	ConfigureDependentFormElementsOnClientOnServer(ThisObject, ChangedBankingDetails);
	
EndProcedure

&AtClient
Function RequiresServerCallToConfigureFormElements(StructureOfChangedProps)

	If StructureOfChangedProps.Count() = 0
		Or StructureOfChangedProps.Property("Date") 
		Or StructureOfChangedProps.Property("Organization") 
		Or StructureOfChangedProps.Property("BusinessOperation") 
		Or StructureOfChangedProps.Property("FixedAsset") 
		Or StructureOfChangedProps.Property("MergeOfSimilarFixedAssets") 
		Or StructureOfChangedProps.Property("RecordInLocalAccounting")
		Or StructureOfChangedProps.Property("RecordInManAccounting") Then
			
		Return True;
	EndIf; 
	
	Return False;

EndFunction

&AtClient
Procedure WhenChangingPeriodOfUse(Var_AttributeName, UpdateIfMatch)

	AttributesList = NonCurrentAssetsClient.WhenChangingPeriodOfUse(
						Object, Var_AttributeName, UsefulLivesMatch And UpdateIfMatch);
	
	SetTermsOfUseToMatch(ThisObject);
	
	ConfigureDependentFormElements(AttributesList);		

EndProcedure

&AtClientAtServerNoContext
Procedure SetTermsOfUseToMatch(Form)

	Form.UsefulLivesMatch = (Not Form.Object.RecordInLocalAccounting Or (Form.Object.UsefulLifeAccounting = Form.Object.UsefulLifeTaxAccounting))
									And (Not Form.Object.RecordInManAccounting Or (Form.Object.UsefulLifeAccounting = Form.Object.UsefulLifeManagementAccounting));

EndProcedure

&AtClient
Procedure CheckUniformityOfFixedAssets()

	ParametersForSelectingFormSFixedAssets = ParametersForSelectingFormSFixedAssets(ThisObject);
	
	If ParametersForSelectingFormSFixedAssets.ThereAreNotSameTypeOfFA Then
		
		ButtonsList = New ValueList;
		ButtonsList.Add(DialogReturnCode.Yes, NStr("vi = 'Tiếp tục';
													|ru = 'Продолжить';
													|en = 'Continue'; fa = 'ادامه';
													|it = 'Continuare';
													|pl = 'Continue';
													|tr = 'Devam'"));
		ButtonsList.Add(DialogReturnCode.Cancel);
		
		QueryText = NStr("vi = 'Trong danh sách TSCĐ hợp nhất có những tài sản cố định không cùng kiểu, mà sẽ bị xóa.
                             |Tiếp tục?';
                             |ru = 'В списке объединяемых ОС есть не однотипные основные средства, которые будут удалены.
                             |Продолжить?';
                             |en = 'There are fixed assets that are not of the same type in the list of merged fixed assets that will be deleted.
                             | Continue?'; fa = 'There are fixed assets that are not of the same type in the list of merged fixed assets that will be deleted.
                             | Continue?';
                             |it = 'Nell''elenco di capitali fissi da collegare esistono capitali fissi di tipo diverso, che verranno eliminati.
                             | Continuare?';
                             |pl = 'Na liście połączanych ŚT są środki trwałe nie tego samego typu, które zostaną usunięte.
                             |Kontynuować?';
                             |tr = 'Birleştirilen sabit kıymetler listesinde, silinecek benzer olmayan sabit kıymetler vardır.
                             | Devam edilsin mi?'");
			
		CallbackDescription = New CallbackDescription("CheckUniformityOfFixedAssetsCompletion", 
														ThisObject, 
														ParametersForSelectingFormSFixedAssets);
														
		ShowQueryBox(CallbackDescription, QueryText, ButtonsList);
		
	Else
		
		CheckUniformityOfFixedAssetsCompletion(DialogReturnCode.Yes, ParametersForSelectingFormSFixedAssets);
		
	EndIf; 

EndProcedure

&AtClient
Procedure CheckUniformityOfFixedAssetsCompletion(QuestionResult, ParametersForSelectingFormSFixedAssets) Export
	
	If QuestionResult <> DialogReturnCode.Yes Then
		
		Object.MergeOfSimilarFixedAssets = False;
		
		If Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.AttachingToExistingFixedAsset") Then
			Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.MergeOfFixedAssets");
			Object.FixedAsset = AttributesValuesBeforeChange.FixedAsset;
		EndIf;
		
		FillInValuesOfFADetailsBeforeChange(ThisObject);
		
		Return;
		
	EndIf;
	
	CheckSamenessOfFixedAssetsOnServer(ParametersForSelectingFormSFixedAssets);
	
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	
EndProcedure

&AtServer
Procedure CheckSamenessOfFixedAssetsOnServer(Val ParametersForSelectingFormSFixedAssets)

	If ParametersForSelectingFormSFixedAssets.ThereAreNotSameTypeOfFA Then
		
		ParametersForSelectingFixedAssets = GetFromTempStorage(ParametersForSelectingFormSFixedAssets.StorageAddress);
		
		// Removing non-similar operating systems.
		LinesToDelete = New Array;
		For Each RowData In Object.FA Do
			If ParametersForSelectingFixedAssets.NotSameTypeOfFA.Find(RowData.FixedAsset) <> Undefined Then
				LinesToDelete.Add(RowData);
			EndIf; 
		EndDo; 

		For Each RowData In LinesToDelete Do
			Object.FA.Delete(RowData);
		EndDo; 
		
	EndIf; 
	
	CombiningSameTypeOfFAWhenChangingOnServer(ParametersForSelectingFormSFixedAssets);
	
EndProcedure

&AtServer
Procedure CombiningSameTypeOfFAWhenChangingOnServer(ParametersForSelectingFormSFixedAssets = Undefined)

	FillInFASelectionParameters(ParametersForSelectingFormSFixedAssets);
	
	ChangedBankingDetails = "MergeOfSimilarFixedAssets";
	If Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.AttachingToExistingFixedAsset") Then
		ChangedBankingDetails = ChangedBankingDetails + ",BusinessOperation";
	EndIf;
	
	ConfigureDependentFormElementsOnServer(ChangedBankingDetails);
	
EndProcedure

&AtServer
Procedure SelectionOnServer(ValueSelected, ThisIsNodeComponent = False)

	AddedRows = NonCurrentAssetsClientServer.ProcessingElementSelection(Object.FA, "FixedAsset", ValueSelected);
	For Each AddedRow In AddedRows Do
		AddedRow.ThisIsNodeComponent = ThisIsNodeComponent;
	EndDo;
	
	If AddedRows.Count() <> 0 And Not ThisIsNodeComponent Then
		WhenChangingFixedAssetsOnServer();
	ElsIf AddedRows.Count() <> 0 And ThisIsNodeComponent Then
		WhenChangingComponentNodesOnServer();
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Procedure FillInValuesOfFADetailsBeforeChange(Form)

	AttributesValuesBeforeChange = New Structure;
	AttributesValuesBeforeChange.Insert("FixedAsset", Form.Object.FixedAsset);
	
	Form.AttributesValuesBeforeChange = New FixedStructure(AttributesValuesBeforeChange);

EndProcedure

&AtServer
Procedure WhenChangingFixedAssetInHeaderOnServer()

	FillInHeaderForSelectedOSVHeader();
	FillInFASelectionParameters();
	FillInCurParameterValues();
	
	ConfigureDependentFormElementsOnServer("FixedAsset");

EndProcedure

&AtServer
Procedure WhenChangingFixedAssetsOnServer()

	FillInHeaderForSelectedFA();
	FillInFASelectionParameters();
	FillInCurParameterValues();
	Items.TraceableGoodsFixedAsset.ChoiceList.LoadValues(AvailableFixedAssets());	
	NumberOfOSLines = GetNumberOfRowsOfSelectionTable(Object.FA, "ThisIsNodeComponent", False);
	
	ConfigureDependentFormElementsOnServer("FixedAsset");
	
EndProcedure

&AtServer
Procedure OrganizationOnChangeServer()
	
	CurrencyOfMan = Constants.ManagementAccountingCurrency.Get();
	ComplCurrency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Object.Organization);
	CurrenciesDoNotMatch = (CurrencyOfMan = ComplCurrency);
	
	Object.VATTaxation = NonCurrentAssets.VATTaxation(Object.Organization, Object.Date);
	
	ConfigureDependentFormElementsOnServer("Organization");
	
EndProcedure

&AtServer
Procedure WhenChangingComponentNodesOnServer()

	NumberOfRowsOfComponentNodes = GetNumberOfRowsOfSelectionTable(Object.FA, "ThisIsNodeComponent", True);

EndProcedure

#EndRegion

#Region Other

&AtServer
Procedure OnReadCreateAtServer()

	InitializingFormWhenCreatingItOnServer();
	
	FillInInformationInBasement();
	
	FillInCurParameterValues();
	
	FillInLineSelectionCriteria();
	SetRowSelection();
	
	NumberOfOSLines               = GetNumberOfRowsOfSelectionTable(Object.FA, "ThisIsNodeComponent", False);
	NumberOfRowsOfComponentNodes = GetNumberOfRowsOfSelectionTable(Object.FA, "ThisIsNodeComponent", True);
	
	ConfigureDependentFormElementsOnServer();
	
EndProcedure

&AtServer
Procedure InitializingFormWhenCreatingItOnServer()

	InitializeServiceParametersOfForm();
	
	Items.CommentPage.Picture = CommonClientServer.CommentPicture(Object.Comment);
	
	CurrencyOfMan = Constants.ManagementAccountingCurrency.Get();
	ComplCurrency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Object.Organization);
	
	Items.LiquidationValueReglCurrency.Title = String(ComplCurrency);
	Items.LiquidationValueCurrency.Title = String(CurrencyOfMan);
	
	CurrenciesDoNotMatch = (CurrencyOfMan = ComplCurrency);
	
	ComplianceCAAccountingIsKept = NonCurrentAssetsInternal.ComplianceCAAccountingIsKept();
	
	FillInFASelectionParameters();
	
	FillInValuesOfFADetailsBeforeChange(ThisObject);
	
EndProcedure

&AtClientAtServerNoContext
Function ParametersForSelectingFormSFixedAssets(Form)

	Object = Form.Object;
	
	ListOfFA = New Array;
	For Each RowData In Object.FA Do
		If ValueIsFilled(RowData.FixedAsset) Then
			ListOfFA.Add(RowData.FixedAsset);
		EndIf;
	EndDo;
	
	ProcedureParameters = New Structure;
	ProcedureParameters.Insert("Ref", Object.Ref);
	ProcedureParameters.Insert("FixedAsset", Object.FixedAsset);
	ProcedureParameters.Insert("ListOfFA", ListOfFA);
	ProcedureParameters.Insert("Date", Object.Date);
	ProcedureParameters.Insert("RecordInManAccounting", Object.RecordInManAccounting);
	ProcedureParameters.Insert("RecordInLocalAccounting", Object.RecordInLocalAccounting);
	ProcedureParameters.Insert("Organization", Object.Organization);
	ProcedureParameters.Insert("FixedAssetsLocation", Object.Department);
	ProcedureParameters.Insert("MergeOfSimilarFixedAssets", Object.MergeOfSimilarFixedAssets);
	ProcedureParameters.Insert("BusinessOperation", Object.BusinessOperation);
	
	ParametersForSelectingFormSFixedAssets = ParametersForSelectingFixedAssetsOnServer(
		ProcedureParameters, Form.UUID);

	Return ParametersForSelectingFormSFixedAssets;
	
EndFunction
 
&AtServerNoContext
Function ParametersForSelectingFixedAssetsOnServer(Val ProcedureParameters, Val FormUniqueID)

	ParametersForSelectingFixedAssets = Documents.MergeOfFixedAssets.ParametersForSelectingFixedAssets(ProcedureParameters);
											
	NotSameTypeOfFA = New Array;
	If ParametersForSelectingFixedAssets.ProblematicFA <> Undefined Then
		For Each CheckResult In ParametersForSelectingFixedAssets.ProblematicFA Do
			If CheckResult <> Undefined
				And (CheckResult.MainDirectionOfActivity
					Or CheckResult.TermOfUseOfMaDiffers
					Or CheckResult.PeriodOfUseOfBUDiffers
					Or MergeOfFixedAssetsLocalization.ThisIsNotSameTypeOfFAAccordingToResultsOfCheck(CheckResult)) Then
				NotSameTypeOfFA.Add(CheckResult.FixedAsset);
			EndIf;
		EndDo; 
	EndIf;
					
	ParametersForSelectingFixedAssets.Insert("NotSameTypeOfFA", NotSameTypeOfFA);
	
	StorageAddress = PutToTempStorage(ParametersForSelectingFixedAssets, FormUniqueID);
	
	Return New Structure("StorageAddress,ThereAreNotSameTypeOfFA", StorageAddress, NotSameTypeOfFA.Count() <> 0);

EndFunction

&AtServer
Procedure FillInFASelectionParameters(ParametersForSelectingFormSFixedAssets = Undefined)
	
	If ParametersForSelectingFormSFixedAssets = Undefined Then
		ParametersForSelectingFormSFixedAssets = ParametersForSelectingFormSFixedAssets(ThisObject);
	EndIf;
	
	ParametersForSelectingFixedAssets = GetFromTempStorage(ParametersForSelectingFormSFixedAssets.StorageAddress);
	
	NonCurrentAssetsInternal.SetStructureProperty(
		"AccordingToOperatingTimeOfAC",
		ParametersForSelectingFixedAssets.AccordingToOperatingTimeOfAC,
		FormServiceParameters);
	
	NonCurrentAssetsInternal.SetStructureProperty(
		"AccordingToMaOperatingTime",
		ParametersForSelectingFixedAssets.AccordingToMaOperatingTime,
		FormServiceParameters);
		
	NonCurrentAssetsInternal.SetStructureProperty(
		"AvailableMaDepreciationParameters",
		ParametersForSelectingFixedAssets.AvailableMaDepreciationParameters,
		FormServiceParameters);
		
	NonCurrentAssetsInternal.SetStructureProperty(
		"ACDepreciationParametersAreAvailable",
		ParametersForSelectingFixedAssets.ACDepreciationParametersAreAvailable,
		FormServiceParameters);
		
	NonCurrentAssetsInternal.SetStructureProperty(
		"UsedByCF",
		ParametersForSelectingFixedAssets.UsedByCF,
		FormServiceParameters);
		
	NonCurrentAssetsInternal.SetStructureProperty(
		"FirstFA",
		ParametersForSelectingFixedAssets.FirstFA,
		FormServiceParameters);
		
	NonCurrentAssetsInternal.SetStructureProperty(
		"FirstFAPresentation",
		ParametersForSelectingFixedAssets.FirstFAPresentation,
		FormServiceParameters);
		
	ParameterValues = ParametersForSelectingFixedAssets.ParameterValues;
	
	ListOfHeaderSelectionParameters = New Array;
	ListOfTSSelectionParameters = New Array;
	ListOfTSSelectionParametersNodesComponents = New Array;;
	
	If Object.BusinessOperation = Enums.BusinessTransactions.MergeOfFixedAssets Then
		
		StateNotAccepted = New Array;
		StateNotAccepted.Add(Enums.FixedAssetsStates.NotRecognized_);
		StateNotAccepted.Add(Enums.FixedAssetsStates.TakenOffBooks);
		ChoiceParameter = New ChoiceParameter("Filter.State", StateNotAccepted);
		ListOfHeaderSelectionParameters.Add(ChoiceParameter);
		
	Else
		
		ChoiceParameter = New ChoiceParameter("Filter.State", Enums.FixedAssetsStates.Recognized_);
		ListOfHeaderSelectionParameters.Add(ChoiceParameter);
		
	EndIf; 
	
	ChoiceParameter = New ChoiceParameter("Filter.State", Enums.FixedAssetsStates.Recognized_);
	ListOfTSSelectionParameters.Add(ChoiceParameter);
	ListOfTSSelectionParametersNodesComponents.Add(ChoiceParameter);
	
	ChoiceParameter = New ChoiceParameter("Context", "ACC,MA");
	ListOfHeaderSelectionParameters.Add(ChoiceParameter);
	ListOfTSSelectionParameters.Add(ChoiceParameter);
	ListOfTSSelectionParametersNodesComponents.Add(ChoiceParameter);
	
	ChoiceParameter = New ChoiceParameter("Filter.Contract", Catalogs.LeaseContract.EmptyRef());
	ListOfTSSelectionParameters.Add(ChoiceParameter);
	
	AttributesThatShouldMatch = "";
	If Object.MergeOfSimilarFixedAssets Then
		
		If ParameterValues <> Undefined Then
			
			For Each FASelectionParameter In ParameterValues Do
				
				ChoiceParameter = New ChoiceParameter("Filter." + FASelectionParameter.Key, FASelectionParameter.Value);
				ListOfTSSelectionParameters.Add(ChoiceParameter);
				
				If Object.BusinessOperation = Enums.BusinessTransactions.AttachingToExistingFixedAsset
					Or FASelectionParameter.Key <> "UsefulLifeManagementAccounting"
						And FASelectionParameter.Key <> "UsefulLifeAccounting"
						And FASelectionParameter.Key <> "UsefulLifeTaxAccounting"
						And FASelectionParameter.Key <> "VATTaxation"
						And FASelectionParameter.Key <> "LineOfBusiness"
						And FASelectionParameter.Key <> "DepreciationGroup"
						And FASelectionParameter.Key <> "AccountingProcedureAC"
						And ValueIsFilled(ParametersForSelectingFixedAssets.FirstFA) Then
						
					ListOfHeaderSelectionParameters.Add(ChoiceParameter);
				EndIf;
				
			EndDo;
			
		Else
			
			// The document has not yet selected the OS for which you can immediately determine the selection.
			// Therefore, in the selection form, you need to check the matching of the details as you select.
			AttributesThatShouldMatch = "," + FormServiceParameters.AttributesThatShouldMatch;
			
		EndIf;
		
	EndIf; 

	ChoiceParameter = New ChoiceParameter("AttributesThatShouldMatch", 
										  "Organization,Department" + AttributesThatShouldMatch);
										  
	ListOfTSSelectionParameters.Add(ChoiceParameter);
	ListOfTSSelectionParametersNodesComponents.Add(ChoiceParameter);
	
	ArrayOfFATypes = New Array;
	ArrayOfFATypes.Add(PredefinedValue("Enum.FATypes.Asset"));
	ArrayOfFATypes.Add(PredefinedValue("Enum.FATypes.GroupFA"));
	ArrayOfFATypes.Add(PredefinedValue("Enum.FATypes.CapitalExpenditureInLeasedAssets"));
	ChoiceParameter = New ChoiceParameter("Filter.OSType", New FixedArray(ArrayOfFATypes));
	ListOfTSSelectionParameters.Add(ChoiceParameter);
	
	If Object.BusinessOperation = Enums.BusinessTransactions.MergeOfFixedAssets Then
		ListOfHeaderSelectionParameters.Add(ChoiceParameter);
	EndIf;
	
	ArrayOfFATypes = New Array;
	ArrayOfFATypes.Add(PredefinedValue("Enum.FATypes.Node"));
	ArrayOfFATypes.Add(PredefinedValue("Enum.FATypes.DepreciationComponent"));
	ChoiceParameter = New ChoiceParameter("Filter.OSType", New FixedArray(ArrayOfFATypes));
	ListOfTSSelectionParametersNodesComponents.Add(ChoiceParameter);
	
	Items.FixedAsset.ChoiceParameters = New FixedArray(ListOfHeaderSelectionParameters);
	Items.FAFixedAsset.ChoiceParameters = New FixedArray(ListOfTSSelectionParameters);
	Items.FANodesComponentsFixedAsset.ChoiceParameters = New FixedArray(ListOfTSSelectionParametersNodesComponents);

EndProcedure

&AtServer
Procedure FillInLinksOfFASelectionParameters()

	ListOfHeaderSelectionParameters = New Array;

	ChoiceParameter = New ChoiceParameterLink("DateOfLastEdit", "Object.Date", LinkedValueChangeMode.DontChange);
	ListOfHeaderSelectionParameters.Add(ChoiceParameter);
	
	ChoiceParameter = New ChoiceParameterLink("CurrentRegistrar", "Object.Ref", LinkedValueChangeMode.DontChange);
	ListOfHeaderSelectionParameters.Add(ChoiceParameter);
	
	If Object.BusinessOperation = Enums.BusinessTransactions.AttachingToExistingFixedAsset Then
		
		ChoiceParameter = New ChoiceParameterLink("Filter.Organization", "Object.Organization", LinkedValueChangeMode.DontChange);
		ListOfHeaderSelectionParameters.Add(ChoiceParameter);
		
		ChoiceParameter = New ChoiceParameterLink("Filter.Department", "Object.Department", LinkedValueChangeMode.DontChange);
		ListOfHeaderSelectionParameters.Add(ChoiceParameter);
		
	EndIf; 
	
	Items.FixedAsset.ChoiceParameterLinks = New FixedArray(ListOfHeaderSelectionParameters);
	
	ListOfComponentTableSelectionOptions = New Array;
	
	ChoiceParameter = New ChoiceParameterLink("DateOfLastEdit", "Object.Date", LinkedValueChangeMode.DontChange);
	ListOfComponentTableSelectionOptions.Add(ChoiceParameter);

	ChoiceParameter = New ChoiceParameterLink("OwnerOfFAComponentNode", "Object.FixedAsset", LinkedValueChangeMode.DontChange);
	ListOfComponentTableSelectionOptions.Add(ChoiceParameter);
	
	Items.FANodesComponentsFixedAsset.ChoiceParameterLinks = New FixedArray(ListOfComponentTableSelectionOptions);
	
EndProcedure

&AtServer
Procedure FillInInformationInBasement()

	If Not ValueIsFilled(Object.Ref) Then
		Items.PictureInformation.Visible = False;
		Items.Information.Visible = False;
		Return;
	EndIf;
	
	If (Not Object.RecordInManAccounting
			Or Not Object.RecordInLocalAccounting)
		And NonCurrentAssetsInternal.ComplianceCAAccountingIsKept()
		And Object.FA.Count() <> 0 Then
		
		// We will not display the inscription that the document can be created in another account if the OS is accepted for accounting in only one of the accounts.
		ShowInformationIfNotCreated = False;
		ListOfFA = Object.FA.Unload(, "FixedAsset").UnloadColumn("FixedAsset");
		InitialInformation = Catalogs.Assets.InitialInformation(ListOfFA, Object.Date);
		For Each CollectionItem In InitialInformation Do
			
			If Object.RecordInLocalAccounting 
					And CollectionItem.Value.StateOfTheUU = Enums.FixedAssetsStates.Recognized_ 
				Or Object.RecordInManAccounting 
					And CollectionItem.Value.BUState = Enums.FixedAssetsStates.Recognized_ Then
					
				ShowInformationIfNotCreated = True;
				Break;
			EndIf;
			
		EndDo;
					
	Else
		ShowInformationIfNotCreated = True;
	EndIf;
				
	LabelTitle = NonCurrentAssetsInternal.DocumentInformationInAnotherAccounting(Object, ShowInformationIfNotCreated);

	If LabelTitle.Count() <> 0 Then
		Items.Information.Title = New FormattedString(LabelTitle);
		Items.PictureInformation.Visible = True;
		Items.Information.Visible = True;
	Else
		Items.PictureInformation.Visible = False;
		Items.Information.Visible = False;
	EndIf; 
	
EndProcedure

&AtClient
Procedure Attachable_CloseForm()
	
	Close();
	
EndProcedure

&AtServer
Procedure ShowAccountingParametersOnServer()
	
	ShowAccountingParameters = Not ShowAccountingParameters;
	Items.FAShowAccountingParameters.Check = ShowAccountingParameters;
	Items.FANodesComponentsShowAccountingParameters.Check = ShowAccountingParameters;
	
	If ShowAccountingParameters Then
		FillInCurParameterValues();
	EndIf; 
	
	ConfigureDependentFormElementsOnServer("ShowAccountingParameters");
	
EndProcedure

&AtServer
Procedure FillInCurParameterValues()
	
	If Object.FA.Count() = 0 Or Not ShowAccountingParameters Then
		Return;
	EndIf;

	QueryText = MergeOfFixedAssetsLocalization.AddRequestTextToFillInCurParameterValues();
	If QueryText = Undefined Then
		
		QueryText = 
		"SELECT
		|	Assets.Ref AS FixedAsset,
		|	InitialFixedAssetsInformation.CommissioningDateMA AS DateOfRecognitionManagementAccounting,
		|	InitialFixedAssetsInformation.CommissioningDateAC AS DateOfRecognitionAccounting,
		|	FixedAssetDepreciationParametersManagementAccounting.DepreciationMethod AS DepreciationAccrualMethodManagementAccounting,
		|	InitialFixedAssetsInformation.DepreciationMethodAccounting AS DepreciationMethodAccounting,
		|	FixedAssetDepreciationParametersManagementAccounting.UsefulLifeMonths AS UsefulLifeManagementAccounting,
		|	OSBUDepreciationParameters.UsefulLifeMonthsAC AS UsefulLifeAccounting
		|FROM
		|	Catalog.Assets AS Assets
		|
		|		LEFT JOIN InformationRegister.FixedAssetDepreciationParametersManagementAccounting.SliceLast(
		|				&Period,
		|				Recorder <> &Ref
		|					AND CorrectionDate = DATETIME(1,1,1)
		|					AND Organization = &Organization
		|					AND FixedAsset IN (&ListOfFA)) AS FixedAssetDepreciationParametersManagementAccounting
		|		ON (FixedAssetDepreciationParametersManagementAccounting.FixedAsset = Assets.Ref)
		|
		|		LEFT JOIN InformationRegister.OSBUDepreciationParameters.SliceLast(
		|				&Period,
		|				Recorder <> &Ref
		|					AND CorrectionDate = DATETIME(1,1,1)
		|					AND Organization = &Organization
		|					AND FixedAsset IN (&ListOfFA)) AS OSBUDepreciationParameters
		|		ON (OSBUDepreciationParameters.FixedAsset = Assets.Ref)
		|
		|		LEFT JOIN InformationRegister.InitialFixedAssetsInformation.SliceLast(
		|				&Period,
		|				Recorder <> &Ref
		|					AND CorrectionDate = DATETIME(1,1,1)
		|					AND Organization = &Organization
		|					AND FixedAsset IN (&ListOfFA)) AS InitialFixedAssetsInformation
		|		ON (InitialFixedAssetsInformation.FixedAsset = Assets.Ref)";
	EndIf;
	
	Query = New Query(QueryText);
	Query.SetParameter("ListOfFA", Object.FA.Unload().UnloadColumn("FixedAsset"));
	Query.SetParameter("Organization", Object.Organization);
	Query.SetParameter("Ref", Object.Ref);
	Query.SetParameter("Period", EndOfDay(?(ValueIsFilled(Object.Date), Object.Date, CurrentSessionDate())));
	
	SetPrivilegedMode(True);
	Result = Query.Execute().Unload();
	SetPrivilegedMode(False);
	
	For Each RowData In Object.FA Do
		CurrentValues = Result.Find(RowData.FixedAsset, "FixedAsset");
		If CurrentValues <> Undefined Then
			FillPropertyValues(RowData, CurrentValues);
		EndIf;
	EndDo; 
	
	FillInRemainingPeriodOfUse(ThisObject);
	
EndProcedure

&AtClientAtServerNoContext
Procedure FillInRemainingPeriodOfUse(Form)

	Object = Form.Object;

	For Each RowData In Object.FA Do
		
		RowData.ResidualLifetimeAC = ResidualPeriodOfUse(RowData.DateOfRecognitionAccounting, Object.Date, RowData.UsefulLifeAccounting);
		RowData.ResidualLifetimeTA = ResidualPeriodOfUse(RowData.DateOfRecognitionAccounting, Object.Date, RowData.UsefulLifeTaxAccounting);
		RowData.ResidualLifetimeMA = ResidualPeriodOfUse(RowData.DateOfRecognitionManagementAccounting, Object.Date, RowData.UsefulLifeManagementAccounting);
		
	EndDo; 
	
EndProcedure

&AtClientAtServerNoContext
Function ResidualPeriodOfUse(StartDate, EndDate, UsefulLifeMonths)

	If StartDate = '000101010000' Or EndDate = '000101010000' Then
		Return 0;
	EndIf;
	
	Return UsefulLifeMonths - (Month(EndDate) - Month(StartDate) + 12*(Year(EndDate) - Year(StartDate)));

EndFunction
 
&AtServer
Procedure InitializeServiceParametersOfForm()

	InternalParameters = New Structure;
	InternalParameters.Insert("AttributesThatShouldMatch", "LineOfBusiness,UsefulLifeManagementAccounting,UsefulLifeAccounting");
	InternalParameters.Insert("PresentationOfDetails", Documents.MergeOfFixedAssets.PresentationOfDetails(Object.Organization));
	InternalParameters.Insert("AccordingToMaOperatingTime", False);
	InternalParameters.Insert("AccordingToOperatingTimeOfAC", False);
	InternalParameters.Insert("AvailableMaDepreciationParameters", False);
	InternalParameters.Insert("ACDepreciationParametersAreAvailable", False);
	InternalParameters.Insert("UsedByCF", False);
	InternalParameters.Insert("FirstFA", Undefined);
	InternalParameters.Insert("FirstFAPresentation", "");
	InternalParameters.Insert("FirstFAPresentation", "");
	InternalParameters.Insert("ComplCurrency", SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Object.Organization));
	
	MergeOfFixedAssetsLocalization.AddServiceParametersToForm(InternalParameters);
	
	FormServiceParameters = New FixedStructure(InternalParameters);
	
EndProcedure

&AtServer
Procedure FillInHeaderForSelectedOSVHeader()

	If Object.BusinessOperation <> Enums.BusinessTransactions.AttachingToExistingFixedAsset Then
		Return;
	EndIf;
	
	ChangedBankingDetails = "";
	NonCurrentAssetsInternal.FillInHeaderForSelectedFA(
		"Organization,Department", 
		Undefined, 
		Object, 
		ChangedBankingDetails);
		
	FillInCGUForSelectedFA();
	
	If ChangedBankingDetails <> "" Then
		ConfigureDependentFormElementsOnServer(ChangedBankingDetails);
	EndIf;
	
EndProcedure

&AtServer
Procedure FillInHeaderForSelectedFA()

	ChangedBankingDetails = "";
	NonCurrentAssetsInternal.FillInHeaderForSelectedFA(
		"Organization,Department", 
		Object.FA, 
		Object, 
		ChangedBankingDetails);
	
	If ChangedBankingDetails <> "" Then
		ConfigureDependentFormElementsOnServer(ChangedBankingDetails);
	EndIf;
	
EndProcedure

&AtServer
Procedure FillInCGUForSelectedFA()
	
	If Object.BusinessOperation <> Enums.BusinessTransactions.AttachingToExistingFixedAsset Then
		Return;
	EndIf;
	
	Object.CGU = ImpairmentFAServer.GetEGDSVNAOnDate(Object.Organization, Object.FixedAsset, Object.Date);
	
EndProcedure

&AtClient
Procedure WhenChangingAddressPresentation(Item)

	NonCurrentAssetsClient.WhenChangingAddressPresentation(
		Item,
		Object.LocationAddress,
		Object.LocationAddressValue);

EndProcedure

&AtServer
Procedure FillInByRemainingTraceableItemsOnServer()
	
	AccountingForTraceableGoodsLocalization.FillInTabularPartOnRemainsOfTraceableGoods(Object, AvailableFixedAssets());
	
EndProcedure

&AtClient
Procedure AnswerToQuestionAboutClearingTablePart(Result, AdditionalParameters) Export
	
	If Result = DialogReturnCode.No Then
		Return;
	EndIf;
	PerformanceMonitorClient.TimeMeasurement(
	"Document.MergeOfFixedAssets.Form.DocumentForm.InformationOnBalanceOfTraceableGoods");
	FillInByRemainingTraceableItemsOnServer();
	
EndProcedure 

&AtServer
Function AvailableFixedAssets()
	
	AvailableFixedAssets = Object.FA.Unload(,"FixedAsset").UnloadColumn("FixedAsset");
	NodesList = NonCurrentAssets.GetFANodes(AvailableFixedAssets, Object.Date);
	
	While NodesList.Next() Do
		AvailableFixedAssets.Add(NodesList.FixedAsset);
	EndDo;
	
	Return AvailableFixedAssets;
	
EndFunction

&AtClient
Function DataOnTraceableGoodsIsCorrect()
	
	DataCorrect = True;
	FixedAssets = AvailableFixedAssets();
	For Each Page1 In Object.TraceableGoods Do
		If FixedAssets.Find(Page1.FixedAsset) = Undefined Then
			MessageString = NStr("vi = 'Dữ liệu phần bảng hàng hóa có truy xuất nguồn gốc không tương ứng với dữ liệu về tài sản cố định kèm theo. 
			|Giá trị %1 không có trong phần bảng tài sản cố định đính kèm.';
			|ru = 'Данные табличной части прослеживаемых товаров не соответствуют данным о присоединяемых основных средствах. 
			|Значение %1 отсутствует в присоединяемых основных средствах.';
			|en = 'Data of the traceable goods table does not correspond to the data of fixed assets to attach. 
			|The %1 value is missing in the fixed assets to attach.'; fa = 'Data of the traceable goods table does not correspond to the data of fixed assets to attach. 
			|The %1 value is missing in the fixed assets to attach.';
			|it = 'I dati della parte tabellare degli articoli tracciabili non corrispondono ai dati sulle immobilizzazioni allegabili. 
			|Il valore %1 manca nelle immobilizzazioni allegabili.';
			|pl = 'Dane sekcji tabelarycznej towarów identyfikowalnych nie są zgodne z danymi załączanych środkach trwałłych. 
			|Brak wartości %1 w załączanych środkach trwałych.';
			|tr = 'İzlenebilir malların tablo kısmının verileri, eklenecek sabit kıymetlerin verilerine karşılık gelmiyor.
			|Eklenecek sabit kıymetlerde %1 değeri mevcut değil.'"); 
			MessageString = StringFunctionsClientServer.SubstituteParametersToString(MessageString, Page1.FixedAsset);
			CommonClient.MessageToUser(MessageString,Object.Ref);
			DataCorrect = False;	
		EndIf;	
	EndDo;

	Return DataCorrect;
EndFunction

&AtServer
Procedure FillInLineSelectionCriteria()

	ValueMap = Common.ObjectsAttributeValue(
		Object.FA.Unload().UnloadColumn("FixedAsset"), "OSType");
		
	For Each FAString In Object.FA Do
		If ValueMap[FAString.FixedAsset] = Enums.FATypes.Node
			Or ValueMap[FAString.FixedAsset] = Enums.FATypes.DepreciationComponent Then
			FAString.ThisIsNodeComponent = True;
		Else
			FAString.ThisIsNodeComponent = False;
		EndIf;
	EndDo;

EndProcedure

&AtServer
Procedure SetRowSelection()

	Items.FA.RowFilter = New FixedStructure("ThisIsNodeComponent", False);
	Items.FANodesComponents.RowFilter = New FixedStructure("ThisIsNodeComponent", True);

EndProcedure

&AtServerNoContext
Procedure ClearRowsBySelection(FATable, AttributeName, Value)
	
	FilterParameters = New Structure(AttributeName, Value);
	
	FoundRows = FATable.FindRows(FilterParameters);
	
	For Each FAString In FoundRows Do
		FATable.Delete(FAString);
	EndDo;
	
EndProcedure

&AtServerNoContext
Function GetNumberOfRowsOfSelectionTable(FATable, NameOfSelectionProps, FilterValue)

	FilterParameters = New Structure(NameOfSelectionProps, FilterValue);
	
	FoundRows = FATable.FindRows(FilterParameters);
	
	Return FoundRows.Count();

EndFunction

&AtServer
Procedure ExecuteCommandAtServer(ExecutionParameters)
	AttachableCommands.ExecuteCommand(ThisObject, ExecutionParameters, Object);
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
