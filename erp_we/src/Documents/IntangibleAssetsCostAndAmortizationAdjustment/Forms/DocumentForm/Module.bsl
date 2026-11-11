
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
	
	ItemsAndDimensionsSelectionParameters = Documents.IntangibleAssetsCostAndAmortizationAdjustment.ItemsAndDimensionsSelectionParameters(Object);
	IncomeAndExpensesServer.OnCreateAtServer(ThisObject, ItemsAndDimensionsSelectionParameters);
	
	AccountSettings_ = Documents.IntangibleAssetsCostAndAmortizationAdjustment.AccountingAccountSettings_();
	GLAccountSettingsServer.OnCreateAtServer(ThisObject, AccountSettings_);
	
	#Region StandardSubsystems
	
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
	
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	
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
	
	PeriodClosingDates.ObjectOnReadAtServer(ThisForm, CurrentObject);
	
	OnReadCreateAtServer();
	
	ItemsAndDimensionsSelectionParameters = Documents.IntangibleAssetsCostAndAmortizationAdjustment.ItemsAndDimensionsSelectionParameters(Object);
	IncomeAndExpensesServer.OnReadAtServer(ThisObject, ItemsAndDimensionsSelectionParameters);
	
	AccountingAccountSettings_ = Documents.IntangibleAssetsCostAndAmortizationAdjustment.AccountingAccountSettings_();
	GLAccountSettingsServer.OnReadAtServer(ThisObject, AccountingAccountSettings_);
	
	FormEvents.OnReadAtServer(ThisObject, CurrentObject);
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	GLAccountSettingsServer.BeforeWriteAtServer(ThisObject, CurrentObject);
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.BeforeWriteAtServer(
		ThisObject,
		CurrentObject,
		WriteParameters);
	// End IntegrationWith1CDocumentManagementSubsystem
	
EndProcedure

&AtClient
Procedure BeforeWrite(Cancel, WriteParameters)
	
	FormEventsClient.BeforeWrite(ThisObject, Cancel, WriteParameters);

EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	
	Notify("Write_IntangibleAssetsCostAndAmortizationAdjustment", WriteParameters, Object.Ref);
	TMCommonUseClient.NotifyAboutEntryOfDocumentInJournal();
	NonCurrentAssetsClient.NotifyAboutEntryOfDocumentInJournalOfIA();
	
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
	
	ConfigurationModificationOverridable.AfterWriteAtServer(ThisForm, CurrentObject, WriteParameters);
	
	IncomeAndExpensesServer.AfterWriteAtServer(ThisObject);
	
	FormEvents.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
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
	
EndProcedure

&AtClient
Procedure PostInAccountingOnChange(Item)
	
	If Not Object.PostInAccounting And Not Object.RecordInTA And Not Object.RecordInManAccounting Then
		Object.PostInAccounting = True;
	EndIf;
	
	Object.RecordInLocalAccounting = Object.PostInAccounting Or Object.RecordInTA;

	ConfigureDependentFormElementsOnServer("RecordInLocalAccounting,PostInAccounting");

EndProcedure

&AtClient
Procedure RecordInTAOnChange(Item)
	
	If Not Object.PostInAccounting And Not Object.RecordInTA And Not Object.RecordInManAccounting Then
		Object.RecordInTA = True;
	EndIf;

	Object.RecordInLocalAccounting = Object.PostInAccounting Or Object.RecordInTA;

	ConfigureDependentFormElementsOnServer("RecordInLocalAccounting,RecordInTA");

EndProcedure

&AtClient
Procedure RecordInManAccountingOnChange(Item)
	
	If Not Object.PostInAccounting And Not Object.RecordInTA And Not Object.RecordInManAccounting Then
		Object.RecordInManAccounting = True;
	EndIf;

	ConfigureDependentFormElementsOnServer("RecordInManAccounting");

EndProcedure

&AtClient
Procedure OrganizationOnChange(Item)
	
	ConfigureDependentFormElements(Item);
	
EndProcedure

&AtClient
Procedure KindOfAccountingObjectsOnChange(Item)
	
	If Object.IA.Count() <> 0 Then
		
		QueryText = 
			?(Object.KindOfAccountingObjects = PredefinedValue("Enum.IntangibleAssetsAccountingItemKinds.IntangibleAsset"),
				NStr("vi = 'Danh sách chi phí nghiên cứu, triển khai sẽ bị xóa.
                      |Tiếp tục?';
                      |ru = 'Список расходов на НИОКР будет очищен.
                      |Продолжить?';
                      |en = 'R&D expenses list will be cleared.
                      | Continue?'; fa = 'R&D expenses list will be cleared.
                      | Continue?';
                      |it = 'Elenco di spese di Ricerca e Sviluppo sarà cancellato. 
                      | Continuare?';
                      |pl = 'Lista wydatków na R&D będzie oczyszczona.
                      |Kontynuować?';
                      |tr = 'Ar-Ge harcamaları listesi temizlenecektir. 
                      | Devam edilsin mi?'"),
				NStr("vi = 'Danh sách tài sản vô hình sẽ bị xóa.
                      |Tiếp tục?';
                      |ru = 'Список нематериальных активов будет очищен.
                      |Продолжить?';
                      |en = 'Intangible assets list will be cleared.
                      | Continue?'; fa = 'Intangible assets list will be cleared.
                      | Continue?';
                      |it = 'Elenco di attivi immateriali sarà cancellato.
                      |Continuare?';
                      |pl = 'Lista aktywów niematerialnych będzie oczyszczona.
                      |Kontynuować?';
                      |tr = 'Maddi olmayan duran varlıklar temizlenecektir. 
                      |Devam edilsin mi?'"));
				
		CallbackDescription = New CallbackDescription("KindOfAccountingObjectsOnChangeCompletion", ThisObject);
		ShowQueryBox(CallbackDescription, QueryText, QuestionDialogMode.YesNo);
		
	Else
		KindOfAccountingObjectsOnChangeCompletion(DialogReturnCode.Yes, Undefined);
	EndIf; 
	
EndProcedure

#EndRegion

#Region ExpensesAndIncomePage

#Region CostIncrease

&AtClient
Procedure IncomeLiabilityItemCostIncreaseOnChange(Item)
	
	IncomeAndExpensesClientServer.AssetRefOnChange(ThisObject, Item);
	
EndProcedure

&AtClient
Procedure IncomeLiabilityItemCostIncreaseStartChoice(Item, ChoiceData, StandardProcessing)
	
	IncomeAndExpensesClient.StartArticleSelection(ThisObject, Item, StandardProcessing);
	
EndProcedure

&AtClient
Procedure PresentationOfReflectionCostIncreaseClick(Item, StandardProcessing)
	
	GLAccountSettingsClient.OnClick(ThisObject, Item, StandardProcessing);
	
EndProcedure

&AtClient
Procedure BusinessUnitAndLineOfBusinessMatchAccountingDataCostIncreaseOnChange(Item)
	
	ConfigureDependentFormElements(
		"WayToReflectExpensesIsToIncreaseCost,BusinessUnitAndLineOfBusinessMatchAccountingDataCostIncrease");
	
EndProcedure

#EndRegion

#Region CostReduction

&AtClient
Procedure ExpenseRecordMethodCostDecreaseOnChange(Item)
	
	ChangedBankingDetails = 
	"ExpenseRecordMethodCostDecrease,
	|AssetExpenseItemCostReduction,BusinessUnitAndLineOfBusinessMatchAccountingDataCostDecrease";
	
	NonCurrentAssetsClientServer.FillInAccordingToMethodOfReflectingExpenses(
		Object.ExpenseRecordMethodCostDecrease, 
		Object.AssetExpenseItemCostReduction, 
		Object.DimensionOfExpensesCostReduction, 
		Object.BusinessUnitCostDecrease, 
		Object.LineOfBusinessCostDecrease, 
		Object.BusinessUnitAndLineOfBusinessMatchAccountingDataCostDecrease);
	
	IncomeAndExpensesClientServer.AssetRefOnChange(ThisObject, Items.AssetExpenseItemCostReduction);

	ConfigureDependentFormElements(ChangedBankingDetails);

EndProcedure

&AtClient
Procedure AssetExpenseItemCostReductionOnChange(Item)
	
	IncomeAndExpensesClientServer.AssetRefOnChange(ThisObject, Item);
	
	If ValueIsFilled(Object.ExpenseRecordMethodCostDecrease) Then
		Object.ExpenseRecordMethodCostDecrease = PredefinedValue("Catalog.WaysToReflectExpenses.EmptyRef");
	EndIf;
	
	ConfigureDependentFormElements(
		"ExpenseRecordMethodCostDecrease,AssetExpenseItemCostReduction");
	
EndProcedure

&AtClient
Procedure AssetExpenseItemCostReductionStartChoice(Item, ChoiceData, StandardProcessing)
	
	IncomeAndExpensesClient.StartArticleSelection(ThisObject, Item, StandardProcessing);
	
EndProcedure

&AtClient
Procedure DimensionOfExpensesCostReductionStartChoice(Item, ChoiceData, StandardProcessing)
	
	IncomeAndExpensesClient.StartSelectingExpenseAnalytics(ThisObject, Item, StandardProcessing);
	
EndProcedure

&AtClient
Procedure DimensionOfExpensesCostReductionOnChange(Item)
	
	If ValueIsFilled(Object.ExpenseRecordMethodCostDecrease) Then
		Object.ExpenseRecordMethodCostDecrease = PredefinedValue("Catalog.WaysToReflectExpenses.EmptyRef");
		ConfigureDependentFormElements("ExpenseRecordMethodCostDecrease");
	EndIf;
	
EndProcedure

&AtClient
Procedure DimensionOfExpensesCostReductionAutoComplete(Item, Text, ChoiceData, DataGetParameters, Waiting, StandardProcessing)
	
	IncomeAndExpensesClient.AutoSelectionOfExpenseAnalytics(ThisObject, Item, Text, ChoiceData, DataGetParameters, StandardProcessing);
	
EndProcedure

&AtClient
Procedure DimensionOfExpensesCostReductionTextEditEnd(Item, Text, ChoiceData, DataGetParameters, StandardProcessing)
	
	IncomeAndExpensesClient.EndOfCostAnalyticsTextEntry(ThisObject, Item, Text, ChoiceData, DataGetParameters, StandardProcessing);
	
EndProcedure

&AtClient
Procedure PresentationOfReflectionCostReductionClick(Item, StandardProcessing)
	
	GLAccountSettingsClient.OnClick(ThisObject, Item, StandardProcessing);
	
EndProcedure

&AtClient
Procedure BusinessUnitCostDecreaseOnChange(Item)
	
	If ValueIsFilled(Object.ExpenseRecordMethodCostDecrease) Then
		Object.ExpenseRecordMethodCostDecrease = PredefinedValue("Catalog.WaysToReflectExpenses.EmptyRef");
		ConfigureDependentFormElements("ExpenseRecordMethodCostDecrease");
	EndIf;
	
EndProcedure

&AtClient
Procedure LineOfBusinessCostDecreaseOnChange(Item)
	
	If ValueIsFilled(Object.ExpenseRecordMethodCostDecrease) Then
		Object.ExpenseRecordMethodCostDecrease = PredefinedValue("Catalog.WaysToReflectExpenses.EmptyRef");
		ConfigureDependentFormElements("ExpenseRecordMethodCostDecrease");
	EndIf;
	
EndProcedure

&AtClient
Procedure BusinessUnitAndLineOfBusinessMatchAccountingDataCostDecreaseOnChange(Item)
	
	If ValueIsFilled(Object.ExpenseRecordMethodCostDecrease) Then
		Object.ExpenseRecordMethodCostDecrease = PredefinedValue("Catalog.WaysToReflectExpenses.EmptyRef");
	EndIf;
	
	ConfigureDependentFormElements(
		"ExpenseRecordMethodCostDecrease,BusinessUnitAndLineOfBusinessMatchAccountingDataCostDecrease");
	
EndProcedure

#EndRegion

#Region IncreasedDepreciation

&AtClient
Procedure ExpenseRecordMethodDepreciationIncreaseOnChange(Item)
	
	ChangedBankingDetails = 
	"ExpenseRecordMethodDepreciationIncrease,
	|AssetExpenseItemDepreciationIncrease,BusinessUnitAndLineOfBusinessMatchAccountingDataDepreciationIncrease";
	
	NonCurrentAssetsClientServer.FillInAccordingToMethodOfReflectingExpenses(
		Object.ExpenseRecordMethodDepreciationIncrease, 
		Object.AssetExpenseItemDepreciationIncrease, 
		Object.DimensionOfExpensesDepreciationIncrease, 
		Object.BusinessUnitDepreciationIncrease, 
		Object.LineOfBusinessDepreciationIncrease, 
		Object.BusinessUnitAndLineOfBusinessMatchAccountingDataDepreciationIncrease);
	
	IncomeAndExpensesClientServer.AssetRefOnChange(ThisObject, Items.AssetExpenseItemDepreciationIncrease);

	ConfigureDependentFormElements(ChangedBankingDetails);
	
EndProcedure

&AtClient
Procedure AssetExpenseItemDepreciationIncreaseOnChange(Item)
	
	IncomeAndExpensesClientServer.AssetRefOnChange(ThisObject, Item);
	
	If ValueIsFilled(Object.ExpenseRecordMethodDepreciationIncrease) Then
		Object.ExpenseRecordMethodDepreciationIncrease = PredefinedValue("Catalog.WaysToReflectExpenses.EmptyRef");
	EndIf;
	
	ConfigureDependentFormElements(
		"ExpenseRecordMethodDepreciationIncrease,AssetExpenseItemDepreciationIncrease");
	
EndProcedure

&AtClient
Procedure AssetExpenseItemDepreciationIncreaseStartChoice(Item, ChoiceData, ChoiceByAdding, StandardProcessing)
	
	IncomeAndExpensesClient.StartArticleSelection(ThisObject, Item, StandardProcessing);
	
EndProcedure

&AtClient
Procedure DimensionOfExpensesDepreciationIncreaseOnChange(Item)
	
	If ValueIsFilled(Object.ExpenseRecordMethodDepreciationIncrease) Then
		Object.ExpenseRecordMethodDepreciationIncrease = PredefinedValue("Catalog.WaysToReflectExpenses.EmptyRef");
		ConfigureDependentFormElements("ExpenseRecordMethodDepreciationIncrease");
	EndIf;
	
EndProcedure

&AtClient
Procedure DimensionOfExpensesDepreciationIncreaseStartChoice(Item, ChoiceData, StandardProcessing)
	
	IncomeAndExpensesClient.StartSelectingExpenseAnalytics(ThisObject, Item, StandardProcessing);
	
EndProcedure

&AtClient
Procedure DimensionOfExpensesDepreciationIncreaseAutoComplete(Item, Text, ChoiceData, DataGetParameters, Waiting, StandardProcessing)
	
	IncomeAndExpensesClient.AutoSelectionOfExpenseAnalytics(ThisObject, Item, Text, ChoiceData, DataGetParameters, StandardProcessing);
	
EndProcedure

&AtClient
Procedure DimensionOfExpensesDepreciationIncreaseTextEditEnd(Item, Text, ChoiceData, DataGetParameters, StandardProcessing)
	
	IncomeAndExpensesClient.EndOfCostAnalyticsTextEntry(ThisObject, Item, Text, ChoiceData, DataGetParameters, StandardProcessing);
	
EndProcedure

&AtClient
Procedure PresentationOfReflectionIncreaseInDepreciationClick(Item, StandardProcessing)
	
	GLAccountSettingsClient.OnClick(ThisObject, Item, StandardProcessing);
	
EndProcedure

&AtClient
Procedure BusinessUnitDepreciationIncreaseOnChange(Item)
	
	If ValueIsFilled(Object.ExpenseRecordMethodDepreciationIncrease) Then
		Object.ExpenseRecordMethodDepreciationIncrease = PredefinedValue("Catalog.WaysToReflectExpenses.EmptyRef");
		ConfigureDependentFormElements("ExpenseRecordMethodDepreciationIncrease");
	EndIf;
	
EndProcedure

&AtClient
Procedure LineOfBusinessDepreciationIncreaseOnChange(Item)
	
	If ValueIsFilled(Object.ExpenseRecordMethodDepreciationIncrease) Then
		Object.ExpenseRecordMethodDepreciationIncrease = PredefinedValue("Catalog.WaysToReflectExpenses.EmptyRef");
		ConfigureDependentFormElements("ExpenseRecordMethodDepreciationIncrease");
	EndIf;
	
EndProcedure

&AtClient
Procedure BusinessUnitAndLineOfBusinessMatchAccountingDataDepreciationIncreaseOnChange(Item)
	
	If ValueIsFilled(Object.ExpenseRecordMethodDepreciationIncrease) Then
		Object.ExpenseRecordMethodDepreciationIncrease = PredefinedValue("Catalog.WaysToReflectExpenses.EmptyRef");
	EndIf;
	
	ConfigureDependentFormElements(
		"ExpenseRecordMethodDepreciationIncrease,BusinessUnitAndLineOfBusinessMatchAccountingDataDepreciationIncrease");
	
EndProcedure

#EndRegion

#Region DecreaseInDepreciationOfCurrentYear

&AtClient
Procedure ExpenseRecordMethodCurrentYearDepreciationDecreaseOnChange(Item)
	
	ChangedBankingDetails = 
	"ExpenseRecordMethodCurrentYearDepreciationDecrease,
	|ExpenseItemThisYearDepreciationDecrease,BusinessUnitAndLineOfBusinessMatchAccountingDataThisYearDepreciationDecrease";
	
	NonCurrentAssetsClientServer.FillInAccordingToMethodOfReflectingExpenses(
		Object.ExpenseRecordMethodCurrentYearDepreciationDecrease, 
		Object.ExpenseItemThisYearDepreciationDecrease, 
		Object.DimensionThisYearDepreciationDecrease, 
		Object.BusinessUnitThisYearDepreciationDecrease, 
		Object.LineOfBusinessThisYearDepreciationDecrease, 
		Object.BusinessUnitAndLineOfBusinessMatchAccountingDataThisYearDepreciationDecrease);
	
	IncomeAndExpensesClientServer.AssetRefOnChange(ThisObject, Items.ExpenseItemThisYearDepreciationDecrease);

	ConfigureDependentFormElements(ChangedBankingDetails);
	
EndProcedure

&AtClient
Procedure ExpenseItemThisYearDepreciationDecreaseOnChange(Item)
	
	IncomeAndExpensesClientServer.AssetRefOnChange(ThisObject, Item);
	
	If ValueIsFilled(Object.ExpenseRecordMethodCurrentYearDepreciationDecrease) Then
		Object.ExpenseRecordMethodCurrentYearDepreciationDecrease = PredefinedValue("Catalog.WaysToReflectExpenses.EmptyRef");
	EndIf;
	
	ConfigureDependentFormElements(
		"ExpenseRecordMethodCurrentYearDepreciationDecrease,ExpenseItemThisYearDepreciationDecrease");
	
EndProcedure

&AtClient
Procedure ExpenseItemThisYearDepreciationDecreaseStartChoice(Item, ChoiceData, ChoiceByAdding, StandardProcessing)
	
	IncomeAndExpensesClient.StartArticleSelection(ThisObject, Item, StandardProcessing);
	
EndProcedure

&AtClient
Procedure DimensionThisYearDepreciationDecreaseOnChange(Item)
	
	If ValueIsFilled(Object.ExpenseRecordMethodCurrentYearDepreciationDecrease) Then
		Object.ExpenseRecordMethodCurrentYearDepreciationDecrease = PredefinedValue("Catalog.WaysToReflectExpenses.EmptyRef");
		ConfigureDependentFormElements("ExpenseRecordMethodCurrentYearDepreciationDecrease");
	EndIf;
	
EndProcedure

&AtClient
Procedure DimensionThisYearDepreciationDecreaseStartChoice(Item, ChoiceData, StandardProcessing)
	
	IncomeAndExpensesClient.StartSelectingExpenseAnalytics(ThisObject, Item, StandardProcessing);
	
EndProcedure

&AtClient
Procedure DimensionThisYearDepreciationDecreaseAutoComplete(Item, Text, ChoiceData, DataGetParameters, Waiting, StandardProcessing)
	
	IncomeAndExpensesClient.AutoSelectionOfExpenseAnalytics(ThisObject, Item, Text, ChoiceData, DataGetParameters, StandardProcessing);
	
EndProcedure

&AtClient
Procedure DimensionThisYearDepreciationDecreaseTextEditEnd(Item, Text, ChoiceData, DataGetParameters, StandardProcessing)
	
	IncomeAndExpensesClient.EndOfCostAnalyticsTextEntry(ThisObject, Item, Text, ChoiceData, DataGetParameters, StandardProcessing);
	
EndProcedure

&AtClient
Procedure BusinessUnitThisYearDepreciationDecreaseOnChange(Item)
	
	If ValueIsFilled(Object.ExpenseRecordMethodCurrentYearDepreciationDecrease) Then
		Object.ExpenseRecordMethodCurrentYearDepreciationDecrease = PredefinedValue("Catalog.WaysToReflectExpenses.EmptyRef");
		ConfigureDependentFormElements("ExpenseRecordMethodCurrentYearDepreciationDecrease");
	EndIf;
	
EndProcedure

&AtClient
Procedure LineOfBusinessThisYearDepreciationDecreaseOnChange(Item)
	
	If ValueIsFilled(Object.ExpenseRecordMethodCurrentYearDepreciationDecrease) Then
		Object.ExpenseRecordMethodCurrentYearDepreciationDecrease = PredefinedValue("Catalog.WaysToReflectExpenses.EmptyRef");
		ConfigureDependentFormElements("ExpenseRecordMethodCurrentYearDepreciationDecrease");
	EndIf;
	
EndProcedure

&AtClient
Procedure BusinessUnitAndLineOfBusinessMatchAccountingDataThisYearDepreciationDecreaseOnChange(Item)
	
	If ValueIsFilled(Object.ExpenseRecordMethodCurrentYearDepreciationDecrease) Then
		Object.ExpenseRecordMethodCurrentYearDepreciationDecrease = PredefinedValue("Catalog.WaysToReflectExpenses.EmptyRef");
	EndIf;
	
	ConfigureDependentFormElements(
		"ExpenseRecordMethodCurrentYearDepreciationDecrease,BusinessUnitAndLineOfBusinessMatchAccountingDataThisYearDepreciationDecrease");
	
EndProcedure

#EndRegion

#Region DecreaseInDepreciationOfPreviousYears

&AtClient
Procedure IncomeLiabilityItemDepreciationDecreaseOnChange(Item)
	
	IncomeAndExpensesClientServer.AssetRefOnChange(ThisObject, Item);
	
EndProcedure

&AtClient
Procedure IncomeLiabilityItemDepreciationDecreaseStartChoice(Item, ChoiceData, StandardProcessing)
	
	IncomeAndExpensesClient.StartArticleSelection(ThisObject, Item, StandardProcessing);
	
EndProcedure

&AtClient
Procedure PresentationOfReflectionReductionOfDepreciationClick(Item, StandardProcessing)
	
	GLAccountSettingsClient.OnClick(ThisObject, Item, StandardProcessing);
	
EndProcedure

&AtClient
Procedure BusinessUnitAndLineOfBusinessMatchAccountingDataDepreciationDecreaseOnChange(Item)
	
	ConfigureDependentFormElements("BusinessUnitAndLineOfBusinessMatchAccountingDataDepreciationDecrease");
	
EndProcedure

#EndRegion

#Region IncreaseInCFRevenues

&AtClient
Procedure AssetExpenseItemTargetFinancingIncomeIncreaseOnChange(Item)
	
	IncomeAndExpensesClientServer.AssetRefOnChange(ThisObject, Item);
	
EndProcedure

&AtClient
Procedure AssetExpenseItemTargetFinancingIncomeIncreaseStartChoice(Item, ChoiceData, ChoiceByAdding, StandardProcessing)
	
	IncomeAndExpensesClient.StartArticleSelection(ThisObject, Item, StandardProcessing);
	
EndProcedure

&AtClient
Procedure DimensionOfExpensesDecreaseInIncomeTFStartChoice(Item, ChoiceData, StandardProcessing)
	
	IncomeAndExpensesClient.StartSelectingExpenseAnalytics(ThisObject, Item, StandardProcessing);
	
EndProcedure

&AtClient
Procedure DimensionOfExpensesDecreaseInIncomeTFAutoComplete(Item, Text, ChoiceData, DataGetParameters, Waiting, StandardProcessing)
	
	IncomeAndExpensesClient.AutoSelectionOfExpenseAnalytics(ThisObject, Item, Text, ChoiceData, DataGetParameters, StandardProcessing);
	
EndProcedure

&AtClient
Procedure DimensionOfExpensesDecreaseInIncomeTFTextEditEnd(Item, Text, ChoiceData, DataGetParameters, StandardProcessing)
	
	IncomeAndExpensesClient.EndOfCostAnalyticsTextEntry(ThisObject, Item, Text, ChoiceData, DataGetParameters, StandardProcessing);
	
EndProcedure

&AtClient
Procedure PresentationOfReflectionIncreaseInCFRevenuesClick(Item, StandardProcessing)
	
	GLAccountSettingsClient.OnClick(ThisObject, Item, StandardProcessing);
	
EndProcedure

&AtClient
Procedure BusinessUnitAndLineOfBusinessMatchAccountingDataTargetFinancingIncomeIncreaseOnChange(Item)
	
	ConfigureDependentFormElements(Item.Name);
	
EndProcedure

#EndRegion

#Region DecreaseInIncomeOfTF

&AtClient
Procedure IncomeLiabilityItemTargetFinancingIncomeDecreaseOnChange(Item)
	
	IncomeAndExpensesClientServer.AssetRefOnChange(ThisObject, Item);
	
EndProcedure

&AtClient
Procedure IncomeLiabilityItemTargetFinancingIncomeDecreaseStartChoice(Item, ChoiceData, StandardProcessing)
	
	IncomeAndExpensesClient.StartArticleSelection(ThisObject, Item, StandardProcessing);
	
EndProcedure

&AtClient
Procedure PresentationOfReflectionOfDecreaseInIncomeOfCFClick(Item, StandardProcessing)
	
	GLAccountSettingsClient.OnClick(ThisObject, Item, StandardProcessing);
	
EndProcedure

&AtClient
Procedure BusinessUnitAndLineOfBusinessMatchAccountingDataTargetFinancingIncomeDecreaseOnChange(Item)
	
	ConfigureDependentFormElements("BusinessUnitAndLineOfBusinessMatchAccountingDataTargetFinancingIncomeDecrease");
	
EndProcedure

#EndRegion

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

#Region FormTableItemsEventHandlersIA

&AtClient
Procedure IAChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	SelectionOnServer(ValueSelected);
	
EndProcedure

&AtClient
Procedure IAIntangibleAssetOnChange(Item)
	
	IAIntangibleAssetWhenModifiedOnServer();
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Pick(Command)
	
	PickingParameters = TMCommonUseClientServer.PickingParameters(Items.IAIntangibleAsset, ThisForm);
	
	OpenForm(
		"Catalog.IntangibleAssets.ChoiceForm",
		PickingParameters,
		Items.IA,,,,,
		FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure FillInTheAccountingForm(Command)
	
	If Items.IA.SelectedRows.Count() = 0 Then
		Return;
	EndIf;
	
	ButtonsList = New ValueList;
	ButtonsList.Add(DialogReturnCode.Yes, NStr("vi = 'Điền';
												|ru = 'Заполнить';
												|en = 'Fill'; fa = 'پرکردن';
												|it = 'Compilare';
												|pl = 'Fill';
												|tr = 'Doldur'"));
	ButtonsList.Add(DialogReturnCode.No);
	
	QueryText = NStr("vi = 'Điền giá trị và khấu hao theo dữ liệu kế toán trong các hàng đã chọn?';
					|ru = 'Заполнить стоимость и амортизацию по данным учета в выбранных строках?';
					|en = 'Fill in the cost and amortization according to accounting data in the selected lines?'; fa = 'Fill in the cost and amortization according to accounting data in the selected lines?';
					|it = 'Compilare il costo e l''ammortamento in base ai dati contabili nelle righe selezionate?';
					|pl = 'Wypełnić wartość i amortyzację wg danych ewidencji w wybranych wierszach?';
					|tr = 'Seçilen satırlardaki muhasebe verilerine göre maliyet ve amortismanı doldur'");
			
	CallbackDescription = New CallbackDescription("FillInTheAccountingFormCompletion", ThisObject);
	ShowQueryBox(CallbackDescription, QueryText, ButtonsList,, DialogReturnCode.Yes);
	
EndProcedure

&AtClient
Procedure CalculateDepreciationWhenSwitchingToFSB14(Command)
	
	If Items.IA.SelectedRows.Count() = 0 Then
		Return;
	EndIf;
	
	ButtonsList = New ValueList;
	ButtonsList.Add(DialogReturnCode.Yes, NStr("vi = 'Tính toán';
												|ru = 'Рассчитать';
												|en = 'Calculate'; fa = 'محاسبه';
												|it = 'Рассчитать';
												|pl = 'Calculate';
												|tr = 'Hesapla'"));
	ButtonsList.Add(DialogReturnCode.No);
	
	QueryText = NStr("vi = 'Tính khấu hao khi chuyển sang chuẩn mực kế toán số 14 trong các dòng được chọn?';
					|ru = 'Рассчитать амортизацию при переходе на ФСБУ 14 в выбранных строках?';
					|en = 'Do you want to calculate amortization in the selected lines when switching to the Russian GAAP (FSBU) 14?'; fa = 'Do you want to calculate amortization in the selected lines when switching to the Russian GAAP (FSBU) 14?';
					|it = 'Рассчитать амортизацию при переходе на ФСБУ 14 в выбранных строках?';
					|pl = 'Do you want to calculate amortization in the selected lines when switching to the Russian GAAP (FSBU) 14?';
					|tr = 'Seçilen satırlarda FSBU 14''e geçerken amortismanı hesaplayın?'");
			
	CallbackDescription = New CallbackDescription("CalculateDepreciationWhenSwitchingToFSB14Completion", ThisObject);
	ShowQueryBox(CallbackDescription, QueryText, ButtonsList,, DialogReturnCode.Yes);
	
EndProcedure
 
&AtClient
Procedure AdjustAdjustmentParameters(Command)
	
	FormParameters = New Structure(AdjustmentParameters());
	FillPropertyValues(FormParameters, Object);
	FormParameters.Insert("ReadOnly", ReadOnly);
	FormParameters.Insert("Date", Object.Date);
	FormParameters.Insert("KindOfAccountingObjects", Object.KindOfAccountingObjects);
	FormParameters.Insert("PostInAccounting", Object.PostInAccounting);
	FormParameters.Insert("RecordInTA", Object.RecordInTA);
	FormParameters.Insert("RecordInManAccounting", Object.RecordInManAccounting);
	
	CallbackDescription = New CallbackDescription("AdjustAdjustmentParametersCompletion", ThisObject);
	
	OpenForm("Document.IntangibleAssetsCostAndAmortizationAdjustment.Form.AdjustmentParameters", FormParameters,,,,, CallbackDescription);
	
EndProcedure

&AtClient
Procedure ShowPD(Command)
	
	Items.IAShowPD.Check = Not Items.IAShowPD.Check;
	
	ConfigureDependentFormElements(Command.Name);
	
EndProcedure

&AtClient
Procedure WriteDocument(Command)
	
	TMCommonUseClient.Write(ThisForm, True);
	
EndProcedure

&AtClient
Procedure PostAndClose(Command)
	
	TMCommonUseClient.PostAndClose(ThisForm);
	
EndProcedure

&AtClient
Procedure PostDocument(Command)
	
	TMCommonUseClient.Post(ThisForm);
	
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
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
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

	If NotificationParameters.ProcessingParameters.Property("Execute_ConfigureDependentFormElements", ActionParameters) Then
		ConfigureDependentFormElements(ActionParameters);
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
		ConfigureDependentFormElementsOnClientOnServer(ThisForm, ChangedBankingDetails);
	EndIf;

EndProcedure

&AtClientAtServerNoContext
Procedure ConfigureDependentFormElementsOnClientOnServer(Form, ChangedBankingDetails)

	Object = Form.Object;
	Items = Form.Items;
	FormServiceParameters = Form.FormServiceParameters;
	
	AuxiliaryAttributes = New Structure;
	AuxiliaryAttributes.Insert("ComplianceCAAccountingIsKept", FormServiceParameters.ComplianceCAAccountingIsKept);
	AuxiliaryAttributes.Insert("CurrenciesDoNotMatch", FormServiceParameters.CurrenciesDoNotMatch);
	AuxiliaryAttributes.Insert("UseFixedAssetAccountingByActivities", FormServiceParameters.UseFixedAssetAccountingByActivities);
	AuxiliaryAttributes.Insert("IncomeTaxPayer", False);
	AuxiliaryAttributes.Insert("SupportPBU18", False);
	AuxiliaryAttributes.Insert("CalculationOfPermanentAndTemporaryDifferencesIsKept", False);
	AuxiliaryAttributes.Insert("FALocalAccountingIsConductedIndependently", FormServiceParameters.FALocalAccountingIsConductedIndependently);
	IntangibleAssetsCostAndAmortizationAdjustmentClientServerLocalization.AddAuxiliaryDetails(Form, AuxiliaryAttributes);
	
	StructureOfChangedProps = New Structure(ChangedBankingDetails);
	UpdateAll = StructureOfChangedProps.Count() = 0;
	
	ItemDetailsParameters = NonCurrentAssetsClientServer.ValuesOfPropertiesOfDependentDetails_AdjustmentOfCostAndDepreciationOfIa(
									Object, AuxiliaryAttributes, ChangedBankingDetails);
									
	TMCommonUseClientServer.ConfigureDependentFormElements(Form, ItemDetailsParameters);

	If Not UpdateAll Then
		
		TMCommonUseClientServer.ClearUnusedProps(Object, ItemDetailsParameters, "IA");
		FillInDetailsDependingOnProperties(Form, ItemDetailsParameters);
		
	EndIf;

	If StructureOfChangedProps.Property("CostAdjustment") Then
		IncomeAndExpensesClientServer.AssetRefOnChange(Form, Items.IncomeLiabilityItemCostIncrease);
		IncomeAndExpensesClientServer.AssetRefOnChange(Form, Items.AssetExpenseItemCostReduction);
	EndIf;
	
	If StructureOfChangedProps.Property("DepreciationAdjustment") Then
		IncomeAndExpensesClientServer.AssetRefOnChange(Form, Items.AssetExpenseItemDepreciationIncrease);
		IncomeAndExpensesClientServer.AssetRefOnChange(Form, Items.ExpenseItemThisYearDepreciationDecrease);
		IncomeAndExpensesClientServer.AssetRefOnChange(Form, Items.IncomeLiabilityItemDepreciationDecrease);
	EndIf;
	
	If StructureOfChangedProps.Property("CostAdjustment")
		Or StructureOfChangedProps.Property("DepreciationAdjustment")
		Or StructureOfChangedProps.Property("IncludesDepreciationOfCurrentMonth")
		Or StructureOfChangedProps.Property("KindOfAccountingObjects")
		Or UpdateAll Then
		
		If Object.DepreciationAdjustment
			Or Object.CostAdjustment
				And Object.KindOfAccountingObjects = PredefinedValue("Enum.IntangibleAssetsAccountingItemKinds.RDExpenses") Then
			
			Items.PictureInformation.Visible = True;
			Items.TipDepreciation.Visible = True;
			
			If Object.IncludesDepreciationOfCurrentMonth Then
				
				If Object.KindOfAccountingObjects = PredefinedValue("Enum.IntangibleAssetsAccountingItemKinds.RDExpenses") Then
					
					Items.TipDepreciation.Title = 
						NStr("vi = 'Giá trị vào cuối tháng mà sẽ được chỉ ra trong chứng từ.
							 |Khi đóng tháng sẽ không thực hiện ghi giảm giá trị sang chi phí khi tính khấu hao.';
							 |ru = 'Стоимость на конец месяца будет, как указано в документе.
							 |При закрытии месяца не будет выполняться списание стоимости на расходы при начислении амортизации.';
							 |en = 'The cost at the end of the month will be the same as specified in the document.
							 |Upon month-end closing, the cost will not be written off to expenses when amortization is accrued.'; fa = 'The cost at the end of the month will be the same as specified in the document.
							 |Upon month-end closing, the cost will not be written off to expenses when amortization is accrued.';
							 |it = 'Стоимость на конец месяца будет, как указано в документе.
							 |При закрытии месяца не будет выполняться списание стоимости на расходы при начислении амортизации.';
							 |pl = 'The cost at the end of the month will be the same as specified in the document.
							 |Upon month-end closing, the cost will not be written off to expenses when amortization is accrued.';
							 |tr = 'Ay sonu maliyeti belgede belirtildiği gibi olacaktır.
							 |Ay sonu kapanışında, amortisman tahakkuk ettirildiğinde maliyetin giderlere yazılması gerçekleşmeyecektir.'");
							 
				Else
					
					Items.TipDepreciation.Title = 
						NStr("vi = 'Số tiền khấu hao cuối tháng sẽ như chỉ ra trong chứng từ.
							 |Khi đóng tháng, sẽ không thực hiện tính khấu hao.';
							 |ru = 'Сумма амортизации на конец месяца будет, как указано в документе.
							 |При закрытии месяца не будет выполняться начисление амортизации.';
							 |en = 'The amortization amount at the end of the month will be the same as specified in the document.
							 |Upon month-end closing, amortization will not be accrued.'; fa = 'The amortization amount at the end of the month will be the same as specified in the document.
							 |Upon month-end closing, amortization will not be accrued.';
							 |it = 'Сумма амортизации на конец месяца будет, как указано в документе.
							 |При закрытии месяца не будет выполняться начисление амортизации.';
							 |pl = 'The amortization amount at the end of the month will be the same as specified in the document.
							 |Upon month-end closing, amortization will not be accrued.';
							 |tr = 'Ay sonu amortisman tutarı belgede belirtildiği gibi olacaktır.
							 |Ay sonu kapanışında, amortisman tahakkuku gerçekleşmeyecektir.'");
							 
				EndIf;
				
			Else
				
				If Object.KindOfAccountingObjects = PredefinedValue("Enum.IntangibleAssetsAccountingItemKinds.RDExpenses") Then
					
					Items.TipDepreciation.Title = 
						NStr("vi = 'Giá trị cuối tháng sẽ bao gồm số tiền được chỉ ra trong chứng từ và số tiền được tính khi trích khấu hao.';
							|ru = 'Стоимость на конец месяца будет складываться из суммы, указанной в документе и суммы, рассчитанной при начислении амортизации.';
							|en = 'The cost at the end of the month will consist of the amount specified in the document and the amount calculated upon amortization accrual.'; fa = 'The cost at the end of the month will consist of the amount specified in the document and the amount calculated upon amortization accrual.';
							|it = 'Стоимость на конец месяца будет складываться из суммы, указанной в документе и суммы, рассчитанной при начислении амортизации.';
							|pl = 'The cost at the end of the month will consist of the amount specified in the document and the amount calculated upon amortization accrual.';
							|tr = 'Ay sonu maliyeti, belgede gösterilen tutar ile amortisman tahakkukunda hesaplanan tutarın toplamı olacaktır.'");
						
				Else
					
					Items.TipDepreciation.Title = 
						NStr("vi = 'Số tiền khấu hao vào cuối tháng sẽ bao gồm số tiền được chỉ ra trong chứng từ và số tiền được tính khi trích khấu hao.';
							|ru = 'Сумма амортизации на конец месяца будет складываться из суммы, указанной в документе и суммы, рассчитанной при начислении амортизации.';
							|en = 'The amortization amount at the end of the month will consist of the amount specified in the document and the amount calculated upon amortization accrual.'; fa = 'The amortization amount at the end of the month will consist of the amount specified in the document and the amount calculated upon amortization accrual.';
							|it = 'Сумма амортизации на конец месяца будет складываться из суммы, указанной в документе и суммы, рассчитанной при начислении амортизации.';
							|pl = 'The amortization amount at the end of the month will consist of the amount specified in the document and the amount calculated upon amortization accrual.';
							|tr = 'Ay sonu amortisman tutarı, belgede gösterilen tutar ile amortisman tahakkukunda hesaplanan tutarın toplamı olacaktır.'");
						
				EndIf;
				
			EndIf;
			
		Else
			
			Items.PictureInformation.Visible = False;
			Items.TipDepreciation.Visible = False;
			
		EndIf;	
		
	EndIf;

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
	
	If StructureOfChangedProps.Property("KindOfAccountingObjects")
		Or StructureOfChangedProps.Property("PeriodAdjustment")
		Or UpdateAll Then
			
		Items.IACalculateDepreciationWhenSwitchingToFSB14.Visible = 
			Object.PeriodAdjustment <> 0
			And Object.KindOfAccountingObjects = PredefinedValue("Enum.IntangibleAssetsAccountingItemKinds.IntangibleAsset");
		
	EndIf;

	#Region ExpensesAndIncomePage

	If StructureOfChangedProps.Property("CostAdjustment") 
		Or StructureOfChangedProps.Property("ExpenseRecordMethodCostDecrease") 
		Or UpdateAll Then
			
		FieldsNames = 
			"AssetExpenseItemCostReduction,DimensionOfExpensesCostReduction,
			|BusinessUnitCostDecrease,LineOfBusinessCostDecrease,
			|BusinessUnitAndLineOfBusinessMatchAccountingDataCostDecrease";
			
		NonCurrentAssetsClientServer.CustomizeItemsAccordingToWayExpensesAreReflected(
			Object.ExpenseRecordMethodCostDecrease,
			Form, 
			FieldsNames);
	
	EndIf;

	If StructureOfChangedProps.Property("DepreciationAdjustment") 
		Or StructureOfChangedProps.Property("ExpenseRecordMethodDepreciationIncrease") 
		Or UpdateAll Then
			
		FieldsNames = 
			"AssetExpenseItemDepreciationIncrease,DimensionOfExpensesDepreciationIncrease,
			|BusinessUnitDepreciationIncrease,LineOfBusinessDepreciationIncrease,
			|BusinessUnitAndLineOfBusinessMatchAccountingDataDepreciationIncrease";
			
		NonCurrentAssetsClientServer.CustomizeItemsAccordingToWayExpensesAreReflected(
			Object.ExpenseRecordMethodDepreciationIncrease,
			Form, 
			FieldsNames);
	
	EndIf;

	If StructureOfChangedProps.Property("DepreciationAdjustment") 
		Or StructureOfChangedProps.Property("ExpenseRecordMethodCurrentYearDepreciationDecrease") 
		Or UpdateAll Then
			
		FieldsNames = 
			"ExpenseItemThisYearDepreciationDecrease,DimensionThisYearDepreciationDecrease,
			|BusinessUnitThisYearDepreciationDecrease,LineOfBusinessThisYearDepreciationDecrease,
			|BusinessUnitAndLineOfBusinessMatchAccountingDataThisYearDepreciationDecrease";
			
		NonCurrentAssetsClientServer.CustomizeItemsAccordingToWayExpensesAreReflected(
			Object.ExpenseRecordMethodCurrentYearDepreciationDecrease,
			Form, 
			FieldsNames);
	
	EndIf;
	
	If StructureOfChangedProps.Property("CostAdjustment") 
		Or StructureOfChangedProps.Property("CostDecreaseRecording") 
		Or StructureOfChangedProps.Property("RecordCostDecreaseByReversal") 
		Or UpdateAll Then

		If Object.RecordCostDecreaseByReversal Then
			Items.CostReductionGroup.Title = NStr("vi = 'Giảm giá trị (đảo ngược)';
													|ru = 'Уменьшение стоимости (сторно)';
													|en = 'Cost decrease (storno)'; fa = 'Cost decrease (storno)';
													|it = 'Уменьшение стоимости (сторно)';
													|pl = 'Cost decrease (storno)';
													|tr = 'Maliyet düşüşü (YM)'");
		Else
			Items.CostReductionGroup.Title = NStr("vi = 'Giảm giá trị';
													|ru = 'Уменьшение стоимости';
													|en = 'Cost reduction'; fa = 'Cost reduction';
													|it = 'Уменьшение стоимости';
													|pl = 'Zmniejszenie kosztów';
													|tr = 'Maliyet düşüşü'");
		EndIf;

	EndIf;

	If StructureOfChangedProps.Property("DepreciationAdjustment") 
		Or StructureOfChangedProps.Property("DepreciationDecreaseRecording") 
		Or StructureOfChangedProps.Property("RecordThisYearDepreciationDecreaseAsStorno") 
		Or UpdateAll Then

		If Object.RecordThisYearDepreciationDecreaseAsStorno Then
			Items.GroupDecreaseInDepreciationOfPreviousYears.Title = NStr("vi = 'Giảm khấu hao các năm trước';
																			|ru = 'Уменьшение амортизации прошлых лет';
																			|en = 'Amortization decrease of previous years'; fa = 'کاهش استهلاک دارایی نامشهود سال‌های قبل';
																			|it = 'Уменьшение амортизации прошлых лет';
																			|pl = 'Amortization decrease of previous years';
																			|tr = 'Önceki yıllara göre amortismanın azaltılması'");
			Items.DecorationReductionOfDepreciation.Title = NStr("vi = 'Giảm khấu hao các năm trước';
																|ru = 'Уменьшение амортизации прошлых лет';
																|en = 'Amortization decrease of previous years'; fa = 'کاهش استهلاک دارایی نامشهود سال‌های قبل';
																|it = 'Уменьшение амортизации прошлых лет';
																|pl = 'Amortization decrease of previous years';
																|tr = 'Önceki yıllara göre amortismanın azaltılması'");
		Else
			Items.GroupDecreaseInDepreciationOfPreviousYears.Title = NStr("vi = 'Giảm khấu hao';
																			|ru = 'Уменьшение амортизации';
																			|en = 'Amortization decrease'; fa = 'Amortization decrease';
																			|it = 'Уменьшение амортизации';
																			|pl = 'Amortization decrease';
																			|tr = 'Amortismanın azaltılması'");
			Items.DecorationReductionOfDepreciation.Title = NStr("vi = 'Giảm khấu hao';
																|ru = 'Уменьшение амортизации';
																|en = 'Amortization decrease'; fa = 'Amortization decrease';
																|it = 'Уменьшение амортизации';
																|pl = 'Amortization decrease';
																|tr = 'Amortismanın azaltılması'");
		EndIf;

	EndIf;

	#EndRegion

	IntangibleAssetsCostAndAmortizationAdjustmentClientServerLocalization.ConfigureDependentFormElements(Form, StructureOfChangedProps);
	
EndProcedure

&AtServer
Procedure ConfigureDependentFormElementsOnServer(ChangedBankingDetails = "")

	StructureOfChangedProps = New Structure(ChangedBankingDetails);
	
	UpdateAll = StructureOfChangedProps.Count() = 0;
	
	CurrencyOfManPresentation = FormServiceParameters.CurrencyOfManPresentation;
	ComplCurrencyPresentation = FormServiceParameters.ComplCurrencyPresentation;

	If UpdateAll Then
		
		If Not FormServiceParameters.ComplianceCAAccountingIsKept Then
			Items.LineOfBusinessTargetFinancingIncomeIncrease.Visible = False;
			Items.LineOfBusinessTargetFinancingIncomeDecrease.Visible = False;
			Items.DecorationIncreaseInCFRevenues.Visible = False;
			Items.DecorationReductionOfCFRevenues.Visible = False;
		EndIf;
		
		NonCurrentAssetsInternal.SetStructureProperty(
			"ComplianceCAAccountingIsKept",
			NonCurrentAssetsInternal.ComplianceCAAccountingIsKept(),
			FormServiceParameters);
		
	EndIf;
	
	If StructureOfChangedProps.Property("Organization") 
		Or UpdateAll Then
			
		NonCurrentAssetsInternal.SetStructureProperty(
			"ComplCurrency",
			SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Object.Organization),
			FormServiceParameters);
			
		NonCurrentAssetsInternal.SetStructureProperty(
			"ComplCurrencyPresentation",
			String(FormServiceParameters.ComplCurrency),
			FormServiceParameters);
			
		NonCurrentAssetsInternal.SetStructureProperty(
			"CurrenciesDoNotMatch",
			FormServiceParameters.CurrencyOfMan = FormServiceParameters.ComplCurrency,
			FormServiceParameters);
		
		ParentCompany = AccountingPoliciesTaxSettingsCached.ParentCompany(Object.Organization);
		SetFormFunctionalOptionParameters(New Structure("Organization", ParentCompany));
		
	EndIf;
	
	If StructureOfChangedProps.Property("Date") 
		Or StructureOfChangedProps.Property("Organization") 
		Or UpdateAll Then
			
		NonCurrentAssetsInternal.SetStructureProperty(
			"FALocalAccountingIsConductedIndependently",
			AccountingPoliciesTaxSettingsCached.FALocalAccountingIsConductedIndependently(Object.Organization, EndOfMonth(?(Object.Date <> '000101010000', Object.Date, CurrentSessionDate()))),
			FormServiceParameters);
			
	EndIf;
		
	If StructureOfChangedProps.Property("KindOfAccountingObjects") 
		Or UpdateAll Then
		
		If Object.KindOfAccountingObjects = Enums.IntangibleAssetsAccountingItemKinds.RDExpenses Then
			Items.NMAPage.Title = NStr("vi = 'Chi phí nghiên cứu, triển khai';
										|ru = 'Расходы на НИОКР';
										|en = 'R&D expenses'; fa = 'هزینه‌های تحقیق و توسعه';
										|it = 'Spese per Ricerca e Sviluppo';
										|pl = 'Wydatki na R&D';
										|tr = 'Ar-Ge giderleri'");
			Items.IAIntangibleAsset.Title = NStr("vi = 'Chi phí nghiên cứu, triển khai';
												|ru = 'Расходы на НИОКР';
												|en = 'R&D expenses'; fa = 'هزینه‌های تحقیق و توسعه';
												|it = 'Spese per Ricerca e Sviluppo';
												|pl = 'Wydatki na R&D';
												|tr = 'Ar-Ge giderleri'");
		Else
			Items.NMAPage.Title = NStr("vi = 'Tài sản cố định vô hình';
										|ru = 'Нематериальные активы';
										|en = 'Intangible assets'; fa = 'دارایی‌های نامشهود';
										|it = 'Beni immateriali';
										|pl = 'Wartości niematerialne';
										|tr = 'Maddi olmayan varlıklar'");
			Items.IAIntangibleAsset.Title = NStr("vi = 'Tài sản vô hình';
												|ru = 'Нематериальный актив';
												|en = 'Intangible asset'; fa = 'دارایی نامشهود';
												|it = 'Bene immateriale';
												|pl = 'Wartości niematerialne';
												|tr = 'Maddi olmayan varlık'");
		EndIf; 
				
		ItemsAndDimensionsSelectionParameters = Documents.IntangibleAssetsCostAndAmortizationAdjustment.ItemsAndDimensionsSelectionParameters(Object);
		IncomeAndExpensesServer.WhenChangingArticleSelectionParameters(ThisObject, ItemsAndDimensionsSelectionParameters);
		
	EndIf;
	
	If StructureOfChangedProps.Property("Organization") 
		Or UpdateAll Then
		
		Items.IACostInManagementAccounting.Visible = False;
		Items.IACostPermanentDifference.Visible = False;
		Items.IACostInTaxAccounting.Visible = False;
		Items.IACostInAccounting.Visible = False;
		
		Items.IADepreciationInAccounting.Visible = False;
		Items.IADepreciationInTaxAccounting.Visible = False;
		Items.IADepreciationPermanentDifferences.Visible = False;
		Items.IADepreciationManagementAccounting.Visible = False;
		
		Items.IAInitialCostTA.Visible = False;
		
		//
		Items.IACostInManagementAccounting.Title = 
			NonCurrentAssetsClientServer.AddCurrencyToLine(NStr("vi = 'KTQT';
																|ru = 'УУ';
																|en = 'MA'; fa = 'مدیریت';
																|it = 'MA';
																|pl = 'MA';
																|tr = 'Yönetim muhasebesi'"), CurrencyOfManPresentation);
			
		Items.IADepreciationManagementAccounting.Title = 
			NonCurrentAssetsClientServer.AddCurrencyToLine(NStr("vi = 'QT';
																|ru = 'УУ';
																|en = 'MA'; fa = 'مدیریت';
																|it = 'Contabilità gestionale';
																|pl = 'Ewidencja zarządcza';
																|tr = 'Yönetim Muhasebesi'"), CurrencyOfManPresentation);
		
		Items.NmastoimostYYSeparately.Title = 
			NonCurrentAssetsClientServer.AddCurrencyToLine(NStr("vi = 'Giá trị';
																|ru = 'Стоимость';
																|en = 'Cost'; fa = 'بهای تمام‌شده';
																|it = 'Costo';
																|pl = 'Wartość';
																|tr = 'Maliyet'"), CurrencyOfManPresentation);
		
		Items.NmaamortisationOfUUSeparately.Title = 
			NonCurrentAssetsClientServer.AddCurrencyToLine(NStr("vi = 'Khấu hao';
																|ru = 'Амортизация';
																|en = 'Amortization'; fa = 'استهلاک دارایی نامشهود';
																|it = 'Ammortamento';
																|pl = 'Amortyzacja';
																|tr = 'Amortisman'"), CurrencyOfManPresentation);
		
		Items.IAInitialCostMA.Title = 
			NonCurrentAssetsClientServer.AddCurrencyToLine(NStr("vi = 'KTQT';
																|ru = 'УУ';
																|en = 'MA'; fa = 'مدیریت';
																|it = 'Contabilità gestionale';
																|pl = 'EZ';
																|tr = 'Yönetim Muhasebesi'"), CurrencyOfManPresentation);
		
		Items.NmaprivalCostYYSeparately.Title = 
			NonCurrentAssetsClientServer.AddCurrencyToLine(NStr("vi = 'Nguyên giá';
																|ru = 'Первоначальная стоимость';
																|en = 'Initial cost'; fa = 'بهای تمام‌شده اولیه';
																|it = 'Costo iniziale';
																|pl = 'Wartość początkowa';
																|tr = 'Başlangıç değeri'"), CurrencyOfManPresentation);
		
		Items.IADepreciationAtBeginningOfYearMa.Title = 
			NonCurrentAssetsClientServer.AddCurrencyToLine(NStr("vi = 'KTQT';
																|ru = 'УУ';
																|en = 'MA'; fa = 'مدیریت';
																|it = 'Contabilità gestionale';
																|pl = 'Ewidencja zarządcza';
																|tr = 'YM'"), CurrencyOfManPresentation);
		
		Items.IADepreciationAtBeginningOfYearUU_Separately.Title = 
			NonCurrentAssetsClientServer.AddCurrencyToLine(NStr("vi = 'Khấu hao vào đầu kỳ (KTQT)';
																|ru = 'Амортизация на начало года (УУ)';
																|en = 'Amortization as of the beginning of the year (MA)'; fa = 'Amortization as of the beginning of the year (MA)';
																|it = 'Amortization as of the beginning of the year (MA)';
																|pl = 'Amortization as of the beginning of the year (MA)';
																|tr = 'Yıl başı amortismanı (YM)'"), CurrencyOfManPresentation);
			
		Items.IACostInAccounting.Title = 
			NonCurrentAssetsClientServer.AddCurrencyToLine(NStr("vi = 'KTDN';
																|ru = 'БУ';
																|en = 'LA'; fa = 'محلی';
																|it = 'Contabilità civilistica';
																|pl = 'EK';
																|tr = 'Genel Muhasebe'"), ComplCurrencyPresentation);
		
		Items.IADepreciationInAccounting.Title = 
			NonCurrentAssetsClientServer.AddCurrencyToLine(NStr("vi = 'KTDN';
																|ru = 'БУ';
																|en = 'LA'; fa = 'محلی';
																|it = 'Contabilità civilistica';
																|pl = 'EK';
																|tr = 'Genel Muhasebe'"), ComplCurrencyPresentation);
		
		Items.NmastoimostUsedSeparately.Title = 
			NonCurrentAssetsClientServer.AddCurrencyToLine(NStr("vi = 'Giá trị';
																|ru = 'Стоимость';
																|en = 'Cost'; fa = 'بهای تمام‌شده';
																|it = 'Costo';
																|pl = 'Wartość';
																|tr = 'Maliyet'"), ComplCurrencyPresentation);
		
		Items.NmaamortisationUsedSeparately.Title = 
			NonCurrentAssetsClientServer.AddCurrencyToLine(NStr("vi = 'Khấu hao';
																|ru = 'Амортизация';
																|en = 'Amortization'; fa = 'استهلاک دارایی نامشهود';
																|it = 'Ammortamento';
																|pl = 'Amortyzacja';
																|tr = 'Amortisman'"), ComplCurrencyPresentation);
		
		Items.IAInitialCostLocalAccounting.Title = 
			NonCurrentAssetsClientServer.AddCurrencyToLine(NStr("vi = 'KTDN';
																|ru = 'БУ';
																|en = 'LA'; fa = 'محلی';
																|it = 'Contabilità civilistica';
																|pl = 'EK';
																|tr = 'Genel Muhasebe'"), ComplCurrencyPresentation);
		
		Items.NmapfirstCostUsedSeparately.Title = 
			NonCurrentAssetsClientServer.AddCurrencyToLine(NStr("vi = 'Nguyên giá (KTDN)';
																|ru = 'Первоначальная стоимость (БУ)';
																|en = 'Initial cost (local)'; fa = 'بهای اولیه (محلی)';
																|it = 'Costo iniziale (regol)';
																|pl = 'Wartość początkowa (regl)';
																|tr = 'Başlangıç değeri (LA)'"), ComplCurrencyPresentation);
		
		Items.IADepreciationAsOfTheYearStartBookkeeping.Title = 
			NonCurrentAssetsClientServer.AddCurrencyToLine(NStr("vi = 'KTDN';
																|ru = 'БУ';
																|en = 'LA'; fa = 'محلی';
																|it = 'Contabilità civilistica';
																|pl = 'EK';
																|tr = 'Genel Muhasebe'"), ComplCurrencyPresentation);
		
		Items.IADepreciationAsOfTheYearStartTaxAccounting.Title = 
			NonCurrentAssetsClientServer.AddCurrencyToLine(NStr("vi = 'KTTh';
																|ru = 'НУ';
																|en = 'TA'; fa = 'مالیاتی';
																|it = 'НУ';
																|pl = 'EP';
																|tr = 'VM'"), ComplCurrencyPresentation);
		
		Items.IAPermanentDifferencesInDepreciationAsOfTheYearStart.Title = 
			NonCurrentAssetsClientServer.AddCurrencyToLine(NStr("vi = 'CLVV';
																|ru = 'ПР';
																|en = 'PD'; fa = 'تفاوت دائم';
																|it = 'ПР';
																|pl = 'RT';
																|tr = 'SF'"), ComplCurrencyPresentation);
		
		Items.IADepreciationAtBeginningOfYearAC_Separately.Title = 
			NonCurrentAssetsClientServer.AddCurrencyToLine(NStr("vi = 'Khấu hao vào đầu kỳ (KTDN)';
																|ru = 'Амортизация на начало года (БУ)';
																|en = 'Amortization as of the beginning of the year (LA)'; fa = 'Amortization as of the beginning of the year (LA)';
																|it = 'Amortization as of the beginning of the year (LA)';
																|pl = 'Amortization as of the beginning of the year (LA)';
																|tr = 'Yıl başı amortismanı (GM)'"), ComplCurrencyPresentation);
		
	EndIf;
	
	IntangibleAssetsCostAndAmortizationAdjustmentLocalization.ConfigureDependentFormElements(ThisForm, StructureOfChangedProps);
	
	ConfigureDependentFormElementsOnClientOnServer(ThisForm, ChangedBankingDetails);

EndProcedure

&AtClient
Function RequiresServerCallToConfigureFormElements(StructureOfChangedProps)
	If StructureOfChangedProps.Count() = 0
		Or StructureOfChangedProps.Property("Date") 
		Or StructureOfChangedProps.Property("Organization")
		Or StructureOfChangedProps.Property("RecordInLocalAccounting")
		Or StructureOfChangedProps.Property("RecordInManAccounting")
		Or StructureOfChangedProps.Property("KindOfAccountingObjects") Then
			
		Return True;
	EndIf; 
	
	Return False;

EndFunction

&AtServer
Procedure IAIntangibleAssetWhenModifiedOnServer()

	FillInHeaderForSelectedIA();

	CurrentData = Object.IA.FindByID(Items.IA.CurrentRow);
	FillInAccordingToAccountingDataOnServer(CommonClientServer.ValueInArray(CurrentData));

EndProcedure

&AtClient
Procedure KindOfAccountingObjectsOnChangeCompletion(QuestionResult, AdditionalParameters) Export
	
	If QuestionResult <> DialogReturnCode.Yes Then
		
		Object.KindOfAccountingObjects = 
			?(Object.KindOfAccountingObjects = PredefinedValue("Enum.IntangibleAssetsAccountingItemKinds.IntangibleAsset"),
				PredefinedValue("Enum.IntangibleAssetsAccountingItemKinds.RDExpenses"),
				PredefinedValue("Enum.IntangibleAssetsAccountingItemKinds.IntangibleAsset"));
		
		Return;
	EndIf;
	
	Object.IA.Clear();
	
	If Object.KindOfAccountingObjects = PredefinedValue("Enum.IntangibleAssetsAccountingItemKinds.RDExpenses")
		And Object.DepreciationAdjustment Then
		
		Object.CostAdjustment = True;
		Object.CostIncreaseRecording = True;
		Object.DepreciationAdjustment = False;
		Object.DepreciationIncreaseRecording = False;
		Object.DepreciationDecreaseRecording = False;
		Object.SeparateAdjustmentOfCurrentAndPreviousPeriods = False;
		Object.RecordThisYearDepreciationDecreaseAsStorno = False;
		
	ElsIf Object.KindOfAccountingObjects = PredefinedValue("Enum.IntangibleAssetsAccountingItemKinds.IntangibleAsset")
		And Object.IncludesDepreciationOfCurrentMonth
		And Not Object.DepreciationAdjustment Then
		
		Object.CostAdjustment = False;
		Object.DepreciationAdjustment = True;
		Object.DepreciationIncreaseRecording = True;
		
	EndIf;
	
	ConfigureDependentFormElements("KindOfAccountingObjects,CostAdjustment,DepreciationAdjustment");
	
EndProcedure

#EndRegion

#Region Other

&AtServer
Procedure OnReadCreateAtServer()
	
	InitializingFormWhenCreatingItOnServer();
	
	ConfigureDependentFormElementsOnServer();
	
EndProcedure

&AtServer
Procedure InitializingFormWhenCreatingItOnServer()

	InitializeServiceParametersOfForm();
	
EndProcedure

&AtServer
Procedure InitializeServiceParametersOfForm()

	InternalParameters = New Structure;
	
	InternalParameters.Insert("CurrencyOfMan", Constants.ManagementAccountingCurrency.Get());
	InternalParameters.Insert("ComplCurrency", SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Object.Organization));
	InternalParameters.Insert("CurrenciesDoNotMatch", InternalParameters.CurrencyOfMan = InternalParameters.ComplCurrency);
	InternalParameters.Insert("ComplianceCAAccountingIsKept", NonCurrentAssetsInternal.ComplianceCAAccountingIsKept());
	InternalParameters.Insert("CurrencyOfManPresentation", String(InternalParameters.CurrencyOfMan));
	InternalParameters.Insert("ComplCurrencyPresentation", String(InternalParameters.ComplCurrency));
	
	InternalParameters.Insert("UseFixedAssetAccountingByActivities", 
		GetFunctionalOption("UseFixedAssetAccountingByActivities"));
		
	FormServiceParameters = New FixedStructure(InternalParameters);
	
EndProcedure

&AtServer
Procedure SelectionOnServer(ValueSelected)

	AddedRows = NonCurrentAssetsClientServer.ProcessingElementSelection(Object.IA, "IntangibleAsset", ValueSelected);
	If AddedRows.Count() <> 0 Then
		FillInHeaderForSelectedIA();
		FillInAccordingToAccountingDataOnServer(AddedRows);
	EndIf;
	
EndProcedure

&AtClient
Procedure FillInTheAccountingFormCompletion(QuestionResult, AdditionalParameters) Export
	
	If QuestionResult = DialogReturnCode.Yes Then
		FillInAccountInformationOnServer();
	EndIf;
	
EndProcedure

&AtServer
Procedure FillInAccountInformationOnServer()

	StringsList = New Array;
	
	For Each RowID In Items.IA.SelectedRows Do
		RowData = Object.IA.FindByID(RowID);
		StringsList.Add(RowData);
	EndDo; 
	
	FillInAccordingToAccountingDataOnServer(StringsList);

EndProcedure
 
&AtServer
Procedure FillInAccordingToAccountingDataOnServer(StringsList)

	Documents.IntangibleAssetsCostAndAmortizationAdjustment.FillInByAccountingData(Object, StringsList);

EndProcedure

&AtClientAtServerNoContext
Function FillInDetailsDependingOnProperties(Form, ItemDetailsParameters)

	Object = Form.Object;
	Items = Form.Items;

	ChangedBankingDetails = New Array;
	
	For Each AttributeParameters In ItemDetailsParameters Do
		
		If Not ValueIsFilled(AttributeParameters.AttributeName)
			Or StrSplit(AttributeParameters.AttributeName, ".").UBound() <> 0 Then
			Continue;
		EndIf;
		
		Action = NonCurrentAssetsClientServer.ClearOrFill(Object, AttributeParameters);
		
		If Not ValueIsFilled(Action) Then
			Continue;
		EndIf;
		
		If AttributeParameters.AttributeName = "AssetExpenseItemCostReduction" Then
			
			If Action = "Fill" And Object.AssetExpenseItemCostReduction = Undefined Then
				Object.AssetExpenseItemCostReduction = PredefinedValue("ChartOfCharacteristicTypes.ExpenseItems.EmptyRef");
			EndIf; 
			
			IncomeAndExpensesClientServer.AssetRefOnChange(Form, Items.AssetExpenseItemCostReduction);
			
		ElsIf AttributeParameters.AttributeName = "IncomeLiabilityItemCostIncrease" Then
			
			If Action = "Fill" And Object.IncomeLiabilityItemCostIncrease = Undefined Then
				Object.IncomeLiabilityItemCostIncrease = PredefinedValue("ChartOfCharacteristicTypes.IncomeItems.EmptyRef");
			EndIf; 
			
			IncomeAndExpensesClientServer.AssetRefOnChange(Form, Items.IncomeLiabilityItemCostIncrease);
			
		EndIf;
		
		IntangibleAssetsCostAndAmortizationAdjustmentClientServerLocalization.FillInDetailsDependingOnProperties(
			Object, AttributeParameters, Action, ChangedBankingDetails);
		
	EndDo; 
	
	Return StrConcat(ChangedBankingDetails, ",");
	
EndFunction

&AtServer
Procedure FillInHeaderForSelectedIA()

	NonCurrentAssetsInternal.FillInHeaderForSelectedIA("Organization,Department", Object.IA, Object);
	
	
	ConfigureDependentFormElementsOnServer("Organization,Department,ApplicationOfTargetFinancing");
	
EndProcedure

&AtClient
Procedure CalculateDepreciationWhenSwitchingToFSB14Completion(QuestionResult, AdditionalParameters) Export
	
	If QuestionResult = DialogReturnCode.Yes Then
		CalculateDepreciationWhenSwitchingToFsb14OnServer();
	EndIf;
	
EndProcedure

&AtServer
Procedure CalculateDepreciationWhenSwitchingToFsb14OnServer()

	StringsList = New Array;
	
	For Each RowID In Items.IA.SelectedRows Do
		RowData = Object.IA.FindByID(RowID);
		StringsList.Add(RowData);
	EndDo; 
	
	Documents.IntangibleAssetsCostAndAmortizationAdjustment.CalculateDepreciationWhenSwitchingToFSB14(Object, StringsList);
	
EndProcedure

&AtServer
Procedure SetConditionalAppearance()
	
	ConditionalAppearance.Items.Clear();
	
	IntangibleAssetsCostAndAmortizationAdjustmentLocalization.SetConditionalAppearance(ThisObject);
		
EndProcedure

&AtClient
Procedure AdjustAdjustmentParametersCompletion(Result, AdditionalParameters) Export
	
	If Result = Undefined Or ReadOnly Then
		Return;
	EndIf;
	
	Modified = True;
	
	FillPropertyValues(Object, Result);
	
	If Object.PeriodAdjustment <> 0 And Object.Date <> EndOfYear(Object.Date) Then
		 Object.Date = EndOfYear(Object.Date);
	EndIf;

	ConfigureAdjustmentParametersEndOnServer();
	
EndProcedure

&AtServer
Procedure ConfigureAdjustmentParametersEndOnServer()

	ChangedBankingDetails = AdjustmentParameters();
	
	ConfigureDependentFormElementsOnServer(ChangedBankingDetails);
	
	ItemsAndDimensionsSelectionParameters = Documents.IntangibleAssetsCostAndAmortizationAdjustment.ItemsAndDimensionsSelectionParameters(Object);
	IncomeAndExpensesServer.WhenChangingArticleSelectionParameters(ThisObject, ItemsAndDimensionsSelectionParameters);

EndProcedure

&AtClientAtServerNoContext
Function AdjustmentParameters()
	
	AdjustmentParameters = 
	"CostAdjustment,AdjustmentOfInitialCost,
	|DepreciationAdjustment,IncludesDepreciationOfCurrentMonth,
	|PeriodAdjustment,ApplicationOfTargetFinancing,
	|CostIncreaseRecording,CostDecreaseRecording,RecordCostDecreaseByReversal,
	|DepreciationIncreaseRecording,DepreciationDecreaseRecording,RecordThisYearDepreciationDecreaseAsStorno,
	|SeparateAdjustmentOfCurrentAndPreviousPeriods";
	
	Return AdjustmentParameters;
	
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
