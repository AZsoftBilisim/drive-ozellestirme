
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
	
	#Region StandardSubsystems
	
	// StandardSubsystems.ObjectsVersioning
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.ObjectsVersioning
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	
	Items.DecorationEDOState.Visible = GetFunctionalOption("UseElectronicDocumentExchangeWithCounterparties");
	
	// StandardSubsystems.FilesOperations
	FilesHyperlink = FilesOperations.FilesHyperlink();
	FilesHyperlink.Location = "CommandBar";
	FilesOperations.OnCreateAtServer(ThisObject, FilesHyperlink);
	// End StandardSubsystems.FilesOperations
	
	FormEvents.OnCreateAtServer(ThisObject, Cancel, StandardProcessing);
	
	#EndRegion
	
	ItemsAndDimensionsSelectionParameters = Documents.AllocateVariancesToFixedAssetCost.ItemsAndDimensionsSelectionParameters();
	IncomeAndExpensesServer.OnCreateAtServer(ThisObject, ItemsAndDimensionsSelectionParameters);
	
	AllocateVariancesToFixedAssetCostLocalization.OnCreateAtServer(ThisObject, Cancel, StandardProcessing);
	
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
	
	// Handler of the "Date-change" mechanism
	PeriodClosingDates.ObjectOnReadAtServer(ThisObject, CurrentObject);
	
	ItemsAndDimensionsSelectionParameters = Documents.AllocateVariancesToFixedAssetCost.ItemsAndDimensionsSelectionParameters();
	IncomeAndExpensesServer.OnReadAtServer(ThisObject, ItemsAndDimensionsSelectionParameters);

	OnReadCreateAtServer();

	FormEvents.OnReadAtServer(ThisObject, CurrentObject);
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	// End StandardSubsystems.AttachableCommands

	
	AllocateVariancesToFixedAssetCostLocalization.OnReadAtServer(ThisObject, CurrentObject);
	
EndProcedure

&AtClient
Procedure BeforeWrite(Cancel, WriteParameters)
	
	FormEventsClient.BeforeWrite(ThisObject, Cancel, WriteParameters);
	
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

	Notify("Write_AllocateVariancesToFixedAssetCost", WriteParameters, Object.Ref);
	TMCommonUseClient.NotifyAboutEntryOfDocumentInJournal();
	NonCurrentAssetsClient.NotifyAboutDocumentEntryInFALog();
	

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
	

	Items.CommentPage.Picture = CommonClientServer.CommentPicture(Object.Comment);
	
	FillInInformationInBasement();
	
	AllocateVariancesToFixedAssetCostLocalization.AfterWriteAtServer(ThisObject);
	
	FormEvents.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If EventName = "Write_AllocateVariancesToFixedAssetCost"
		Or EventName = "Write_ChangeFixedAssetFinancialDetails2_4" Then
		FillInInformationInBasement();
	EndIf;
	

	FormEventsClient.NotificationProcessing(ThisObject, EventName, Parameter, Source);
	
	// StandardSubsystems.FilesOperations
	FilesOperationsClient.NotificationProcessing(ThisObject, EventName);
	// End StandardSubsystems.FilesOperations

EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure OrganizationOnChange(Item)
	
	OrganizationWhenChangedOnServer();
	
EndProcedure

&AtClient
Procedure DateOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	
	NonCurrentAssetsClient.SetCurrentTimeForLastDate(Object.Date);
	
	DateOfChangeOnServer();
	
EndProcedure

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
	
	If Not Object.RecordInLocalAccounting And Not Object.RecordInManAccounting Then
		Object.RecordInManAccounting = True;
	EndIf;

	ConfigureDependentFormElements("RecordInManAccounting");

EndProcedure

&AtClient
Procedure SourceDocumentOnChange(Item)
	
	If Not ValueIsFilled(Object.SourceDocument) Then
		Return;
	EndIf;
	
	QueryText = NStr("vi = 'Điền chứng từ theo dữ liệu chứng từ gốc?';
					|ru = 'Заполнить документ по данным первичного документа?';
					|en = 'Fill in the document based on the source document data?'; fa = 'Fill in the document based on the source document data?';
					|it = 'Fill in the document based on the source document data?';
					|pl = 'Fill in the document based on the source document data?';
					|tr = 'Belge, birincil belge verilerine göre doldurulsun mu?'");
	CallbackDescription = New CallbackDescription("SourceDocumentOnChangeCompletion", ThisObject);
	ShowQueryBox(CallbackDescription, QueryText, QuestionDialogMode.YesNo); 
	
EndProcedure

&AtClient
Procedure TypeOfExpenseAnalysisFixedAssetsOnChange(Item)
	
	ConfigureDependentFormElements("DimensionKindExpenseCapitalization");
	
EndProcedure

&AtClient
Procedure TypeOfCostAnalysisConstructionObjectsOnChange(Item)
	
	ConfigureDependentFormElements("DimensionKindExpenseCapitalization");
	
EndProcedure

&AtClient
Procedure DepreciationAdjustmentOptionOnChange(Item)
	
	ConfigureDependentFormElements(Item.Name);
	
EndProcedure

&AtClient
Procedure DepreciationAdjustmentURLProcessing(Item, FormattedStringURL, StandardProcessing)
	
	If FormattedStringURL = "#Create" Then
		
		StandardProcessing = False;
		
		If Not ValueIsFilled(Object.Ref)
			Or Modified Then
			
			ButtonsList = New ValueList();
			ButtonsList.Add(DialogReturnCode.Yes, NStr("vi = 'Kết chuyển và tạo';
														|ru = 'Провести и создать';
														|en = 'Post and create'; fa = 'Post and create';
														|it = 'Провести и создать';
														|pl = 'Post and create';
														|tr = 'Kaydet ve oluştur'"));
			ButtonsList.Add(DialogReturnCode.Cancel);
			
			QueryText = NStr("vi = 'Chỉ có thể tạo chứng từ sau khi kết chuyển.
					|Kết chuyển và tiếp tục?';
					|ru = 'Оформление документа возможно только после проведения.
					|Провести и продолжить?';
					|en = 'Document registration is only available after posting.
					|Post and continue?'; fa = 'Document registration is only available after posting.
					|Post and continue?';
					|it = 'Оформление документа возможно только после проведения.
					|Провести и продолжить?';
					|pl = 'Document registration is only available after posting.
					|Post and continue?';
					|tr = 'Belgenin oluşturulması ancak kayıttan sonra mümkündür.
					|Kaydedilsin ve devam edilsin mi?'");
			
			CallbackDescription = New CallbackDescription("CreateAdjustmentCompletion", ThisObject);
			ShowQueryBox(CallbackDescription, QueryText, ButtonsList,, DialogReturnCode.Yes);
			
		Else
			CreateAdjustmentCompletion(DialogReturnCode.Yes, Undefined);
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure IncludeInCostsExpensesForModernizationONChange(Item)

	ConfigureDependentFormElements(Item.Name);
		
EndProcedure

&AtClient
Procedure DocumentInformationInAnotherAccountingURLProcessing(Item, FormattedStringURL, StandardProcessing)
	
	If FormattedStringURL = "#CreateDocument" Then
		StandardProcessing = False;
		FormParameters = New Structure("Basis", Object.Ref);
		OpenForm("Document.AllocateVariancesToFixedAssetCost.ObjectForm", FormParameters);
	EndIf; 
	
EndProcedure

#Region TheAccountingPage

&AtClient
Procedure ExpenseItemWriteOffCostsOnChange(Item)
	
	IncomeAndExpensesClientServer.AssetRefOnChange(ThisObject, Items.ExpenseItemWriteOffCosts);

EndProcedure

&AtClient
Procedure ExpenseItemWriteOffCostsStartChoice(Item, ChoiceData, StandardProcessing)
	
	IncomeAndExpensesClient.StartArticleSelection(ThisObject, Item, StandardProcessing);
	
EndProcedure

&AtClient
Procedure ExpenseDimensionWriteOffCostsStartChoice(Item, ChoiceData, StandardProcessing)
	
	IncomeAndExpensesClient.StartSelectingExpenseAnalytics(ThisObject, Item, StandardProcessing);
	
EndProcedure

&AtClient
Procedure ExpenseDimensionWriteOffCostsAutoComplete(Item, Text, ChoiceData, DataGetParameters, Waiting, StandardProcessing)
	
	IncomeAndExpensesClient.AutoSelectionOfExpenseAnalytics(ThisObject, Item, Text, ChoiceData, DataGetParameters, StandardProcessing);
	
EndProcedure

&AtClient
Procedure ExpenseDimensionWriteOffCostsTextEditEnd(Item, Text, ChoiceData, DataGetParameters, StandardProcessing)
	
	IncomeAndExpensesClient.EndOfCostAnalyticsTextEntry(ThisObject, Item, Text, ChoiceData, DataGetParameters, StandardProcessing);
	
EndProcedure

&AtClient
Procedure BusinessUnitAndLineOfBusinessMatchAccountingDataWriteOffCostsOnChange(Item)
	
	ConfigureDependentFormElements(Item.Name);
	
EndProcedure

&AtClient
Procedure ExpenseRecordMethodTAOnChange(Item)

	NonCurrentAssetsClientServer.FillInAccordingToMethodOfReflectingExpenses(
		Object.ExpenseRecordMethodTA, 
		Object.ExpenseItemTaxAccounting, 
		Object.ExpensesDimensionTaxAccounting, 
		Object.BusinessUnitTaxAccounting, 
		Object.LineOfBusinessTaxAccounting, 
		Object.BusinessUnitAndLineOfBusinessMatchAccountingDataTaxAccounting);
	
	If ValueIsFilled(Object.ExpenseRecordMethodTA) Then
		IncomeAndExpensesClientServer.AssetRefOnChange(ThisObject, Items.ExpenseItemTaxAccounting);
	EndIf;

	ConfigureDependentFormElements("ExpenseRecordMethodTA,ExpenseItemTaxAccounting,BusinessUnitAndLineOfBusinessMatchAccountingDataTaxAccounting");
	
EndProcedure

&AtClient
Procedure ExpenseItemTaxAccountingOnChange(Item)
	
	IncomeAndExpensesClientServer.AssetRefOnChange(ThisObject, Items.ExpenseItemWriteOffCosts);

	If ValueIsFilled(Object.ExpenseRecordMethodTA) Then
		Object.ExpenseRecordMethodTA = PredefinedValue("Catalog.WaysToReflectExpenses.EmptyRef");
	EndIf;
	
	ConfigureDependentFormElements("ExpenseRecordMethodTA,ExpenseItemTaxAccounting");

EndProcedure

&AtClient
Procedure ExpensesDimensionTaxAccountingOnChange(Item)
	
	If ValueIsFilled(Object.ExpenseRecordMethodTA) Then
		Object.ExpenseRecordMethodTA = PredefinedValue("Catalog.WaysToReflectExpenses.EmptyRef");
		ConfigureDependentFormElements("ExpenseRecordMethodTA");
	EndIf;
	
EndProcedure

&AtClient
Procedure ExpenseItemTaxAccountingStartChoice(Item, ChoiceData, StandardProcessing)
	
	IncomeAndExpensesClient.StartArticleSelection(ThisObject, Item, StandardProcessing);
	
EndProcedure

&AtClient
Procedure ExpensesDimensionTaxAccountingStartChoice(Item, ChoiceData, StandardProcessing)
	
	IncomeAndExpensesClient.StartSelectingExpenseAnalytics(ThisObject, Item, StandardProcessing);
	
EndProcedure

&AtClient
Procedure ExpensesDimensionTaxAccountingAutoComplete(Item, Text, ChoiceData, DataGetParameters, Waiting, StandardProcessing)
	
	IncomeAndExpensesClient.AutoSelectionOfExpenseAnalytics(ThisObject, Item, Text, ChoiceData, DataGetParameters, StandardProcessing);
	
EndProcedure

&AtClient
Procedure ExpensesDimensionTaxAccountingTextEditEnd(Item, Text, ChoiceData, DataGetParameters, StandardProcessing)
	
	IncomeAndExpensesClient.EndOfCostAnalyticsTextEntry(ThisObject, Item, Text, ChoiceData, DataGetParameters, StandardProcessing);
	
EndProcedure

&AtClient
Procedure BusinessUnitTaxAccountingOnChange(Item)
	
	If ValueIsFilled(Object.ExpenseRecordMethodTA) Then
		Object.ExpenseRecordMethodTA = PredefinedValue("Catalog.WaysToReflectExpenses.EmptyRef");
	EndIf;
	
	ConfigureDependentFormElements("ExpenseRecordMethodTA,BusinessUnitTaxAccounting");

EndProcedure

&AtClient
Procedure LineOfBusinessTaxAccountingOnChange(Item)
	
	If ValueIsFilled(Object.ExpenseRecordMethodTA) Then
		Object.ExpenseRecordMethodTA = PredefinedValue("Catalog.WaysToReflectExpenses.EmptyRef");
	EndIf;
	
	ConfigureDependentFormElements("ExpenseRecordMethodTA,LineOfBusinessTaxAccounting");
	
EndProcedure

&AtClient
Procedure BusinessUnitAndLineOfBusinessMatchAccountingDataTaxAccountingOnChange(Item)
	
	If ValueIsFilled(Object.ExpenseRecordMethodTA) Then
		Object.ExpenseRecordMethodTA = PredefinedValue("Catalog.WaysToReflectExpenses.EmptyRef");
	EndIf;

	ConfigureDependentFormElements("ExpenseRecordMethodTA,BusinessUnitAndLineOfBusinessMatchAccountingDataTaxAccounting");
	
EndProcedure

&AtClient
Procedure AccountingProcedureTAOnChange(Item)
	
	
	Return;
	
EndProcedure

&AtClient
Procedure UsefulLifeTaxAccountingOnChange(Item)
	
	ConfigureDependentFormElements(Item.Name);

EndProcedure

&AtClient
Procedure ToIncludeDepreciationAllowanceInExpensesOnChange(Item)
	
	
	Return;
	
EndProcedure

&AtClient
Procedure BonusDepreciationInputMethodOnChange(Item)
	

	Return;
	
EndProcedure

&AtClient
Procedure MethodOfRecordingBonusDepreciationExpensesOnChange(Item)
	
	NonCurrentAssetsClientServer.FillInAccordingToMethodOfReflectingExpenses(
		Object.MethodOfRecordingBonusDepreciationExpenses, 
		Object.ExpenseItemOfDepreciationAllowance, 
		Object.DepreciationAllowanceExpensesDimension, 
		Object.BusinessUnitBonusDepreciation, 
		Object.LineOfBusinessBonusDepreciation, 
		Object.BusinessUnitAndLineOfBusinessMatchAccountingDataBonusDepreciation);
	
	If ValueIsFilled(Object.MethodOfRecordingBonusDepreciationExpenses) Then
		IncomeAndExpensesClientServer.AssetRefOnChange(ThisObject, Items.ExpenseItemOfDepreciationAllowance);
	EndIf;

	ConfigureDependentFormElements("MethodOfRecordingBonusDepreciationExpenses,ExpenseItemOfDepreciationAllowance,BusinessUnitAndLineOfBusinessMatchAccountingDataBonusDepreciation");
	
EndProcedure

&AtClient
Procedure ExpenseItemOfDepreciationAllowanceOnChange(Item)
	
	IncomeAndExpensesClientServer.AssetRefOnChange(ThisObject, Items.ExpenseItemOfDepreciationAllowance);

	If ValueIsFilled(Object.MethodOfRecordingBonusDepreciationExpenses) Then
		Object.MethodOfRecordingBonusDepreciationExpenses = PredefinedValue("Catalog.WaysToReflectExpenses.EmptyRef");
	EndIf;
	
	ConfigureDependentFormElements("MethodOfRecordingBonusDepreciationExpenses,ExpenseItemOfDepreciationAllowance");

EndProcedure

&AtClient
Procedure ExpenseItemOfDepreciationAllowanceStartChoice(Item, ChoiceData, StandardProcessing)
	
	IncomeAndExpensesClient.StartArticleSelection(ThisObject, Item, StandardProcessing);
	
EndProcedure

&AtClient
Procedure DepreciationAllowanceExpensesDimensionStartChoice(Item, ChoiceData, StandardProcessing)
	
	IncomeAndExpensesClient.StartSelectingExpenseAnalytics(ThisObject, Item, StandardProcessing);
	
EndProcedure

&AtClient
Procedure DepreciationAllowanceExpensesDimensionAutoComplete(Item, Text, ChoiceData, DataGetParameters, Waiting, StandardProcessing)
	
	IncomeAndExpensesClient.AutoSelectionOfExpenseAnalytics(ThisObject, Item, Text, ChoiceData, DataGetParameters, StandardProcessing);
	
EndProcedure

&AtClient
Procedure DepreciationAllowanceExpensesDimensionTextEditEnd(Item, Text, ChoiceData, DataGetParameters, StandardProcessing)
	
	IncomeAndExpensesClient.EndOfCostAnalyticsTextEntry(ThisObject, Item, Text, ChoiceData, DataGetParameters, StandardProcessing);
	
EndProcedure

&AtClient
Procedure DepreciationAllowanceExpensesDimensionOnChange(Item)
	
	If ValueIsFilled(Object.MethodOfRecordingBonusDepreciationExpenses) Then
		Object.MethodOfRecordingBonusDepreciationExpenses = PredefinedValue("Catalog.WaysToReflectExpenses.EmptyRef");
		ConfigureDependentFormElements("MethodOfRecordingBonusDepreciationExpenses");
	EndIf;
	
EndProcedure

&AtClient
Procedure BusinessUnitBonusDepreciationOnChange(Item)

	If ValueIsFilled(Object.MethodOfRecordingBonusDepreciationExpenses) Then
		Object.MethodOfRecordingBonusDepreciationExpenses = PredefinedValue("Catalog.WaysToReflectExpenses.EmptyRef");
	EndIf;
	
	ConfigureDependentFormElements("MethodOfRecordingBonusDepreciationExpenses,BusinessUnitBonusDepreciation");
	
EndProcedure

&AtClient
Procedure LineOfBusinessBonusDepreciationOnChange(Item)
	
	If ValueIsFilled(Object.MethodOfRecordingBonusDepreciationExpenses) Then
		Object.MethodOfRecordingBonusDepreciationExpenses = PredefinedValue("Catalog.WaysToReflectExpenses.EmptyRef");
	EndIf;

	ConfigureDependentFormElements("MethodOfRecordingBonusDepreciationExpenses,LineOfBusinessBonusDepreciation");

EndProcedure

&AtClient
Procedure BusinessUnitAndLineOfBusinessMatchAccountingDataBonusDepreciationOnChange(Item)
	
	If ValueIsFilled(Object.MethodOfRecordingBonusDepreciationExpenses) Then
		Object.MethodOfRecordingBonusDepreciationExpenses = PredefinedValue("Catalog.WaysToReflectExpenses.EmptyRef");
	EndIf;

	ConfigureDependentFormElements("MethodOfRecordingBonusDepreciationExpenses,BusinessUnitAndLineOfBusinessMatchAccountingDataBonusDepreciation");
	
EndProcedure

#EndRegion

#Region Localization

&AtClient
Procedure Decorationedonage(Item, StandardProcessing)
	
	
	Return; // WE have an empty handler

EndProcedure

&AtClient
Procedure IncomeItemOnChange(Item)
	
	IncomeAndExpensesClientServer.AssetRefOnChange(ThisObject, Items.IncomeItem);
	
EndProcedure

&AtClient
Procedure DimensionOfRevenueOnChange(Item)
	
	IncomeAndExpensesClientServer.DimensionOfRevenueOnChange(ThisObject, Items.DimensionOfRevenue);
	
EndProcedure

&AtClient
Procedure TargetFinancingApplicationOptionOnChange(Item)
	
	ConfigureDependentFormElements(Item.Name);
	
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
Procedure FAOnStartEdit(Item, NewRow, Copy)
	
	FillInValuesOfFADetailsBeforeChange();
	
EndProcedure

&AtClient
Procedure FAFixedAssetOnChange(Item)
	FAIsPrimaryMeansWhenChangingOnServer();
EndProcedure

&AtClient
Procedure FAAmountAccountingOnChange(Item)

	FAAmountOfACOnChangeATServer();	

EndProcedure

&AtClient
Procedure FAAmountOfUUOnChange(Item)
	
	FillInInformationInBasement();
	
EndProcedure

&AtClient
Procedure FAAfterDeleteRow(Item)
	
	ConfigureDependentFormElements("FA");
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersTargetFinancing

&AtClient
Procedure TargetFinancingAccountOnChange(Item)
	
		
	Return;
	
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
Procedure FillInAmountOfDeviations(Command)
	
	FillInCostAmount();
	
EndProcedure

&AtClient
Procedure FillInFundingSources(Command)
	
	
	Return;
	
EndProcedure

&AtClient
Procedure ShowPD(Command)
	
	Items.FAShowPD.Check = Not Items.FAShowPD.Check;
	
	ConfigureDependentFormElements(Command.Name);	
	
EndProcedure

&AtClient
Procedure WriteDocument(Command)
	
	TMCommonUseClient.Write(ThisObject);
	
EndProcedure

&AtClient
Procedure PostAndClose(Command)
	
	TMCommonUseClient.PostAndClose(ThisObject);
	
EndProcedure

&AtClient
Procedure PostDocument(Command)
	
	TMCommonUseClient.Post(ThisObject);
	
EndProcedure

#Region AttachableCommands

&AtClient
Procedure Attachable_ContinueCommandExecutionAtServer(ExecutionParameters, AdditionalParameters) Export
	ExecuteCommandAtServer(ExecutionParameters);
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


// IntegrationWith1CDocumentManagementSubsystem
&AtClient
Procedure Attachable_ExecuteIntegrationCommand(Command)
	
	IntegrationWith1CDocumentManagementCoreClient.ExecutePlugInIntegrationCommand(
		Command,
		ThisObject,
		Object);
	
EndProcedure
// End IntegrationWith1CDocumentManagementSubsystem

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
 
&AtServer
Procedure OrganizationWhenChangedOnServer()

	NonCurrentAssets.SetParametersOfFunctionalOptionsOfObjectForm(ThisObject, Object.Organization, Object.Date);
	
	ConfigureDependentFormElementsOnServer("Organization,VATTaxation");
	
EndProcedure

&AtServer
Procedure DateOfChangeOnServer()

	NonCurrentAssets.SetParametersOfFunctionalOptionsOfObjectForm(ThisObject, Object.Organization, Object.Date);

	ConfigureDependentFormElementsOnServer("Date");
	
EndProcedure

&AtServer
Procedure FAIsPrimaryMeansWhenChangingOnServer()
	
	CurrentRow = Items.FA.CurrentRow;
	RowData = Object.FA.FindByID(CurrentRow);
	WhenChangingFixedAsset(CommonClientServer.ValueInArray(RowData));

EndProcedure

&AtServer
Procedure FAAmountOfACOnChangeATServer()

	CurrentRow = Items.FA.CurrentRow;
	CurrentData = Object.FA.FindByID(CurrentRow);
	
	If FAAttributeValuesBeforeChange.AmountAccounting = FAAttributeValuesBeforeChange.AmountOfUU 
		And Object.RecordInManAccounting 
		And FormServiceParameters.CurrenciesDoNotMatch
		And FormServiceParameters.ComplianceCAAccountingIsKept Then
		
		CurrentData.AmountOfUU = CurrentData.AmountAccounting;
	EndIf; 

	If CurrentData.AmountFA = FAAttributeValuesBeforeChange.AmountAccounting 
		And Object.RecordInTA 
		And FormServiceParameters.IncomeTaxPayer Then
		
		CurrentData.AmountFA = CurrentData.AmountAccounting;
	EndIf;
	
	FillInInformationInBasement();
	
EndProcedure

&AtClientAtServerNoContext
Procedure SaveDetailsValues(Form)

	NewSavedBankingDetails = New Structure(Form.FormServiceParameters.ListOfDetailsForSavingValueBeforeChangingIt);
	FillPropertyValues(NewSavedBankingDetails, Form.Object);
	
	Form.SavedBankDetails_3 = New FixedStructure(NewSavedBankingDetails);

EndProcedure

&AtClient
Procedure SourceDocumentOnChangeCompletion(QuestionResult, AdditionalParameters) Export
	
	If QuestionResult = DialogReturnCode.Yes Then
		FillInAccordingToPrimaryDocumentAtServer();
	EndIf;
	
EndProcedure

&AtServer
Procedure FillInAccordingToPrimaryDocumentAtServer()
	
	Documents.AllocateVariancesToFixedAssetCost.FillInBasedOnPrimaryDocument(Object);
	
	ConfigureDependentFormElementsOnServer(
		"Organization,RecordInLocalAccounting,RecordInManAccounting,PostInAccounting,RecordInTA,FA,
		|DimensionKindExpenseCapitalization,TargetFinancingApplicationOption");
		
EndProcedure

#EndRegion

#Region FillType

&AtServer
Procedure SelectionOnServer(ValueSelected)

	AddedRows = NonCurrentAssetsClientServer.ProcessingElementSelection(Object.FA, "FixedAsset", ValueSelected);

	If AddedRows.Count() <> 0 Then
		WhenChangingFixedAsset(AddedRows);
	EndIf;
	
EndProcedure

&AtServer
Procedure WhenChangingFixedAsset(RowsSelected = Undefined)

	FillInHeaderForSelectedFA();

	FillInCostAmount(RowsSelected);
	
	
	ConfigureDependentFormElementsOnServer("FixedAsset");
	
EndProcedure
 
&AtServer
Procedure FillInCostAmount(RowsSelected = Undefined)

	If Not FormServiceParameters.ThereIsCostAccounting Then
		Return;
	EndIf;
	
	ReportErrors = RowsSelected = Undefined;
	
	Cancel = False;
	If Not ValueIsFilled(Object.Date)  Then
		If ReportErrors Then
			MessageText = NStr("vi = 'Trường ""Ngày"" chưa điền';
								|ru = 'Поле ""Дата"" не заполнено';
								|en = '""Date"" is required'; fa = '""Date"" is required';
								|it = 'Il campo ""Data"" non è compilato';
								|pl = 'Pole ""Дата"" nie jest wypełnione';
								|tr = '""Tarih"" alanı doldurulmadı'");
			Common.MessageToUser(MessageText, , "Object", "Date", Cancel);
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
			Common.MessageToUser(MessageText, , "Object", "Organization", Cancel); 
		Else
			Cancel = True;
		EndIf; 
	EndIf;
	If Not ValueIsFilled(Object.ConstructionObject) 
		And Object.DimensionKindExpenseCapitalization = Enums.KindsOfExpenseCapitalizationDimension.ConstructionObject Then
		
		If ReportErrors Then
			MessageText = NStr("vi = 'Trường ""Đối tượng xây dựng"" không được điền';
								|ru = 'Поле ""Объект строительства"" не заполнено';
								|en = '""Assets under construction"" is required'; fa = '""Assets under construction"" is required';
								|it = 'Il campo ""Oggetto in costruzione"" non è compilato';
								|pl = 'Pole ""Obiekty budowy"" nie jest wypełnione';
								|tr = '""Yapı nesnesi"" alanı doldurulmadı'");
			Common.MessageToUser(MessageText, , "Object", "ConstructionObject", Cancel); 
		Else
			Cancel = True;
		EndIf; 
	EndIf;
	
	If Not Cancel Then
		Documents.AllocateVariancesToFixedAssetCost.FillInCostAmount(Object, RowsSelected);
		FillInInformationInBasement();
	EndIf;
	
EndProcedure
 
#EndRegion

#Region Other

&AtClient
Procedure Attachable_CloseForm()
	
	Close();
	
EndProcedure

&AtServer
Procedure OnReadCreateAtServer()

	InitializingFormWhenCreatingItOnServer();
	
	SaveDetailsValues(ThisObject);
	
	Items.CommentPage.Picture = CommonClientServer.CommentPicture(Object.Comment);
	
 	UseConstructionObjects = GetFunctionalOption("UseConstructionObjects");
	
	AllocateVariancesToFixedAssetCostLocalization.OnReadCreateAtServer(ThisObject);
	
	ConfigureDependentFormElementsOnServer();
	
EndProcedure

&AtServer
Procedure InitializingFormWhenCreatingItOnServer()

	InitializeServiceParametersOfForm();
	
EndProcedure

&AtServer
Procedure SetConditionalAppearance()
	
	ConditionalAppearance.Items.Clear();
	
	AllocateVariancesToFixedAssetCostLocalization.SetConditionalAppearance(ThisObject);
		
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
	
	Object = Form.Object;
	Items = Form.Items;
	FormServiceParameters = Form.FormServiceParameters;
	
	AuxiliaryAttributes = New Structure;
	AuxiliaryAttributes.Insert("ComplianceCAAccountingIsKept", FormServiceParameters.ComplianceCAAccountingIsKept);
	AuxiliaryAttributes.Insert("CurrenciesDoNotMatch", FormServiceParameters.CurrenciesDoNotMatch);
	AuxiliaryAttributes.Insert("UseConstructionObjects", Form.UseConstructionObjects);
	AuxiliaryAttributes.Insert("LineOfBusinessIsMandatory", False);
	AuxiliaryAttributes.Insert("ThereIsCostAccounting", FormServiceParameters.ThereIsCostAccounting);
	AuxiliaryAttributes.Insert("AccountPolicySettings", FormServiceParameters.AccountPolicySettings);
	AuxiliaryAttributes.Insert("PropertyTaxMayBeCharged", False);
	AuxiliaryAttributes.Insert("PropertyTaxAdvancesArePaid", False);
	NonCurrentAssetsClientServerLocalization.AddAuxiliaryDetails_AttributionOfDeviationsToCostOfFA(Form, AuxiliaryAttributes);
	
	NonCurrentAssetsClientServer.OnChangeOfBankingDetails_AttributionOfDeviationsToCostOfFA(Object, AuxiliaryAttributes, ChangedBankingDetails);
	
	ItemDetailsParameters = NonCurrentAssetsClientServer.PropertyValuesOfDependentProps_AttributionOfDeviationsToCostOfFA(
									Object, AuxiliaryAttributes, ChangedBankingDetails);
	
	TMCommonUseClientServer.ConfigureDependentFormElements(Form, ItemDetailsParameters);
	
	If Not UpdateAll Then
		
		TMCommonUseClientServer.ClearUnusedProps(Object, ItemDetailsParameters, "FA,TargetFinancing");
		
	EndIf;
	
	DocumentParameters = NonCurrentAssetsClientServer.ParametersForAttributingDeviationsToCostOfFA(Object, AuxiliaryAttributes);

	#Region PageGeneral
	
	If StructureOfChangedProps.Property("Date")
		Or StructureOfChangedProps.Property("Organization")
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
			Object.RecordInTA = True;
		EndIf;
		
	EndIf;
	
	If StructureOfChangedProps.Property("DepreciationAdjustmentOption")
		Or StructureOfChangedProps.Property("WriteOffVariancesAsExpenses")
		Or StructureOfChangedProps.Property("Write_FixedAssetCostAndDepreciationAdjustment")
		Or UpdateAll Then
		
		If Object.DepreciationAdjustmentOption = PredefinedValue("Enum.AdditionalDepreciationAccrualOptions.Manually") Then
				
			Form.DepreciationAdjustment = InscriptionDepreciationAdjustment(Object.Ref);
			
			Items.DepreciationAdjustment.Visible = True;
			
		Else
			Items.DepreciationAdjustment.Visible = False;
		EndIf;
		
	EndIf;
	
	#EndRegion
	
	#Region FixedAssetsPage
	
	If StructureOfChangedProps.Property("Date")
		Or StructureOfChangedProps.Property("Organization")
		Or StructureOfChangedProps.Property("RecordInLocalAccounting")
		Or StructureOfChangedProps.Property("RecordInManAccounting")
		Or StructureOfChangedProps.Property("DimensionKindExpenseCapitalization")
		Or StructureOfChangedProps.Property("FixedAssetCostAdditionsPartial")
		Or StructureOfChangedProps.Property("FA")
		Or StructureOfChangedProps.Property("FixedAsset")
		Or UpdateAll Then
		
		Items.FAFillInAmountOfDeviations.Visible = 
			Not DocumentParameters.ActualCost
			And (Items.FAAmountAccounting.Visible
				Or Items.FAAmountFA.Visible
				Or Items.FAAmountOfUU.Visible);
		
		If (DocumentParameters.CostIsRequiredToCalculateDepreciationOfAC
				Or DocumentParameters.CostIsRequiredToCalculateDepreciationOfAC)
			And DocumentParameters.CostIsRequiredToCalculateTax
			And (Items.FAAmountAccounting.Visible
				Or Items.FAAmountOfUU.Visible) Then
			
			Items.FABasementInfoText.Visible = True;
			Items.FABasementInformationPicture.Visible = True;
			
			Items.FABasementInfoText.Title =
				NStr("vi = 'Số tiền chi phí được sử dụng để tính khấu hao trong tháng hiện tại và để tính thuế tài sản.
					 |Số tiền này có thể không khớp với chi phí thực tế, trong trường hợp đó, khấu hao sẽ được điều chỉnh vào tháng sau, còn số thuế sẽ được tính trong cùng tháng này.';
					 |ru = 'Сумма затрат используется для расчета амортизации в текущем месяце и для начисления налога на имущество.
					 |Она может не совпадать с фактическими затратами, в этом случае амортизация будет скорректирована в следующем месяце, а сумма налога в этом же месяце.';
					 |en = 'The cost amount is used to calculate depreciation for the current month and to calculate the property tax.
					 |It may not match the actual cost. In this case, the depreciation will be adjusted next month, and the tax amount will be adjusted in the same month.'; fa = 'The cost amount is used to calculate depreciation for the current month and to calculate the property tax.
					 |It may not match the actual cost. In this case, the depreciation will be adjusted next month, and the tax amount will be adjusted in the same month.';
					 |it = 'The cost amount is used to calculate depreciation for the current month and to calculate the property tax.
					 |It may not match the actual cost. In this case, the depreciation will be adjusted next month, and the tax amount will be adjusted in the same month.';
					 |pl = 'The cost amount is used to calculate depreciation for the current month and to calculate the property tax.
					 |It may not match the actual cost. In this case, the depreciation will be adjusted next month, and the tax amount will be adjusted in the same month.';
					 |tr = 'Gider tutarı, cari ayda amortisman hesaplaması ve emlak vergisi tahakkuku için kullanılır.
					 |Gerçek giderlerle örtüşmeyebilir, bu durumda amortisman bir sonraki ayda, vergi tutarı ise aynı ayda düzeltilir.'");
		 
		ElsIf (DocumentParameters.CostIsRequiredToCalculateDepreciationOfAC
				Or DocumentParameters.CostIsRequiredToCalculateDepreciationOfAC)
			And (Items.FAAmountAccounting.Visible
				Or Items.FAAmountOfUU.Visible) Then
			
			Items.FABasementInfoText.Visible = True;
			Items.FABasementInformationPicture.Visible = True;
			
			Items.FABasementInfoText.Title =
				NStr("vi = 'Số tiền chi phí được sử dụng để tính khấu hao trong tháng hiện tại.
					 |Số tiền này có thể không khớp với chi phí thực tế, trong trường hợp đó, khấu hao sẽ được điều chỉnh vào tháng sau.';
					 |ru = 'Сумма затрат используется для расчета амортизации в текущем месяце.
					 |Она может не совпадать с фактическими затратами, в этом случае амортизация будет скорректирована в следующем месяце.';
					 |en = 'The cost amount is used to calculate depreciation for the current month.
					 |It may not match the actual cost. In this case, the depreciation will be adjusted next month.'; fa = 'The cost amount is used to calculate depreciation for the current month.
					 |It may not match the actual cost. In this case, the depreciation will be adjusted next month.';
					 |it = 'The cost amount is used to calculate depreciation for the current month.
					 |It may not match the actual cost. In this case, the depreciation will be adjusted next month.';
					 |pl = 'The cost amount is used to calculate depreciation for the current month.
					 |It may not match the actual cost. In this case, the depreciation will be adjusted next month.';
					 |tr = 'Gider tutarı, cari ayda amortisman hesaplaması için kullanılır.
					 |Gerçek giderlerle örtüşmeyebilir, bu durumda amortisman bir sonraki ayda düzeltilir.'");
					 
		ElsIf DocumentParameters.CostIsRequiredToCalculateTax
			And Items.FAAmountAccounting.Visible Then
			
			Items.FABasementInfoText.Visible = True;
			Items.FABasementInformationPicture.Visible = True;
			
			Items.FABasementInfoText.Title =
				NStr("vi = 'Số tiền chi phí được sử dụng để tính thuế tài sản.
					 |Số tiền này có thể không khớp với chi phí thực tế, trong trường hợp đó, số thuế sẽ được điều chỉnh trong cùng tháng này.';
					 |ru = 'Сумма затрат используется для начисления налога на имущество.
					 |Она может не совпадать с фактическими затратами, в этом случае сумма налога будет скорректирована в этом же месяце.';
					 |en = 'The cost amount is used to calculate the property tax.
					 |It may not match the actual cost. In this case, the tax amount will be adjusted in the same month.'; fa = 'The cost amount is used to calculate the property tax.
					 |It may not match the actual cost. In this case, the tax amount will be adjusted in the same month.';
					 |it = 'The cost amount is used to calculate the property tax.
					 |It may not match the actual cost. In this case, the tax amount will be adjusted in the same month.';
					 |pl = 'The cost amount is used to calculate the property tax.
					 |It may not match the actual cost. In this case, the tax amount will be adjusted in the same month.';
					 |tr = 'Gider tutarı, emlak vergisi tahakkuku için kullanılır.
					 |Gerçek giderlerle örtüşmeyebilir, bu durumda vergi tutarı aynı ayda düzeltilir.'");
					 
		Else
		 
			Items.FABasementInfoText.Visible = False;
			Items.FABasementInformationPicture.Visible = False;
			
		EndIf;
		
	EndIf;

	#EndRegion
	
	NonCurrentAssetsClientServerLocalization.ConfigureDependentFormElements_AttributionOfDeviationsToCostOfFA(
		Form, StructureOfChangedProps);
	
EndProcedure

&AtServer
Procedure ConfigureDependentFormElementsOnServer(Val ChangedBankingDetails = "")

	StructureOfChangedProps = New Structure(ChangedBankingDetails);
	UpdateAll = StructureOfChangedProps.Count() = 0;
	
	DateOfParameters = EndOfMonth(?(Object.Date <> '000101010000', Object.Date, CurrentSessionDate()));

	#Region FixedAssetsPage
	
	If StructureOfChangedProps.Property("WriteOffVariancesAsExpenses")
		Or UpdateAll Then
		
		NewSelectionOptions = New Array;
		NewSelectionOptions.Add(New ChoiceParameter("Context", "ACC,MA"));
		
		If Not Object.WriteOffVariancesAsExpenses Then
			NewSelectionOptions.Add(New ChoiceParameter("Filter.State", PredefinedValue("Enum.FixedAssetsStates.Recognized_")));
			NewSelectionOptions.Add(New ChoiceParameter("AttributesThatShouldMatch", "Organization,Department"));
		EndIf;
		
		Items.FAFixedAsset.ChoiceParameters = New FixedArray(NewSelectionOptions);

		//
		NewSelectionParameterRelationships = New Array;
		NewSelectionParameterRelationships.Add(New ChoiceParameterLink("DateOfLastEdit", "Object.Date", LinkedValueChangeMode.DontChange));
		NewSelectionParameterRelationships.Add(New ChoiceParameterLink("CurrentRegistrar", "Object.Ref", LinkedValueChangeMode.DontChange));

		If Not Object.WriteOffVariancesAsExpenses Then
			NewSelectionParameterRelationships.Add(New ChoiceParameterLink("Filter.Organization", "Object.Organization", LinkedValueChangeMode.DontChange));
			NewSelectionParameterRelationships.Add(New ChoiceParameterLink("Filter.Department", "Object.Department", LinkedValueChangeMode.DontChange));
			NewSelectionParameterRelationships.Add(New ChoiceParameterLink("RecordInLocalAccounting", "Object.RecordInLocalAccounting", LinkedValueChangeMode.DontChange));
			NewSelectionParameterRelationships.Add(New ChoiceParameterLink("RecordInManAccounting", "Object.RecordInManAccounting", LinkedValueChangeMode.DontChange));
		EndIf;
		
		Items.FAFixedAsset.ChoiceParameterLinks = New FixedArray(NewSelectionParameterRelationships);
		
	EndIf;
	
	#EndRegion

	#Region TheAccountingPage
	
	If UpdateAll Then
		
		Items.LineOfBusinessTaxAccounting.Visible = False;
		Items.LineOfBusinessBonusDepreciation.Visible = False;
		
	EndIf;

	#EndRegion
	
	#Region Other
	
	If StructureOfChangedProps.Property("Organization") 
		Or UpdateAll Then
			
		ComplCurrency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Object.Organization);
		NonCurrentAssetsInternal.SetStructureProperty(
			"CurrenciesDoNotMatch",
			FormServiceParameters.CurrencyOfMan = ComplCurrency,
			FormServiceParameters);
			
		NonCurrentAssetsInternal.SetStructureProperty(
			"ComplCurrencyPresentation",
			String(ComplCurrency),
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
			
		NonCurrentAssetsInternal.SetStructureProperty(
			"PropertyTaxAdvancesArePaid",
			AccountingPoliciesTaxSettingsCached.PropertyTaxAdvancesArePaid(Object.Organization, DateOfParameters),
			FormServiceParameters);
			
		NonCurrentAssetsInternal.SetStructureProperty(
			"PresentationOfDetails",
			Documents.FixedAssetsCostAdditions2_4.PresentationOfDetails(Object.Organization, Object.Date),
			FormServiceParameters);
			
		Items.FAAmountAccounting.Title =
			NonCurrentAssetsClientServer.PresentationOfCurrencyField(
				NStr("vi = 'Số tiền';
					|ru = 'Сумма';
					|en = 'Amount'; fa = 'مبلغ';
					|it = 'Amount';
					|pl = 'Amount';
					|tr = 'Tutar'"), 
				NStr("vi = 'Số tiền (KTDN)';
					|ru = 'Сумма (БУ)';
					|en = 'Amount (LA)'; fa = 'مبلغ (محلی)';
					|it = 'Importo (Contabilità)';
					|pl = 'Wartość (EK)';
					|tr = 'Tutar (AC)'"), 
				FormServiceParameters.FALocalAccountingIsConductedIndependently, 
				FormServiceParameters.CurrenciesDoNotMatch,
				FormServiceParameters.ComplCurrencyPresentation);
		
		Items.FAAmountOfUU.Title =
			NonCurrentAssetsClientServer.PresentationOfCurrencyField(
				NStr("vi = 'Số tiền';
					|ru = 'Сумма';
					|en = 'Amount'; fa = 'مبلغ';
					|it = 'Amount';
					|pl = 'Amount';
					|tr = 'Tutar'"), 
				NStr("vi = 'Số tiền (KTQT)';
					|ru = 'Сумма (УУ)';
					|en = 'Amount (MA)'; fa = 'مبلغ (مدیریت)';
					|it = 'Amount (MA)';
					|pl = 'Amount (MA)';
					|tr = 'Tutar (YM)'"), 
				FormServiceParameters.FALocalAccountingIsConductedIndependently, 
				FormServiceParameters.CurrenciesDoNotMatch,
				FormServiceParameters.CurrencyOfManPresentation);
			
		Items.FAAmountFA.Title =
			NonCurrentAssetsClientServer.AddCurrencyToLine(NStr("vi = 'Số tiền (KTTh)';
																|ru = 'Сумма (НУ)';
																|en = 'TA amount'; fa = 'مبلغ حسابداری مالیاتی';
																|it = 'Importo (Registro Fiscale)';
																|pl = 'Wartość (EP)';
																|tr = 'Tutar (VM)'"), FormServiceParameters.ComplCurrencyPresentation);
		
		Items.FAAmountPermanentDifferences.Title =
			NonCurrentAssetsClientServer.AddCurrencyToLine(NStr("vi = 'Số tiền (CLVV)';
																|ru = 'Сумма (ПР)';
																|en = 'Amount (PD)'; fa = 'مبلغ (تفاوت دائم)';
																|it = 'Importo (differenza costante)';
																|pl = 'Wartość (różnica trwała)';
																|tr = 'Tutar (Kalıcı fark)'"), FormServiceParameters.ComplCurrencyPresentation);
			
	EndIf;
	
	If StructureOfChangedProps.Property("Date") 
		Or UpdateAll Then
		
		NonCurrentAssetsInternal.SetStructureProperty(
			"ThereIsCostAccounting",
			CalculationOfCostCached.GenerateRegisteredRecordsOnCostRegisters(Object.Date),
			FormServiceParameters);
		
	EndIf;
	
	If StructureOfChangedProps.Property("Date") 
		Or StructureOfChangedProps.Property("FixedAsset") 
		Or UpdateAll Then
		FillInInformationInBasement();
	EndIf;

	#EndRegion
	
	AllocateVariancesToFixedAssetCostLocalization.ConfigureDependentFormElements(ThisObject, StructureOfChangedProps);
	
	ConfigureDependentFormElementsOnClientOnServer(ThisObject, ChangedBankingDetails);

EndProcedure

&AtClient
Function RequiresServerCallToConfigureFormElements(StructureOfChangedProps)

	If StructureOfChangedProps.Count() = 0
		Or StructureOfChangedProps.Property("Date") 
		Or StructureOfChangedProps.Property("Organization") 
		Or StructureOfChangedProps.Property("WriteOffVariancesAsExpenses")
		Or StructureOfChangedProps.Property("FixedAsset")
		Or StructureOfChangedProps.Property("FA") Then
		Return True;
	EndIf; 
	
	Return False;

EndFunction

&AtServer
Procedure FillInInformationInBasement()

	LabelTitle = New Array;
	
	If PreliminaryCostDiffersFromActual() Then
		If LabelTitle.Count() <> 0 Then
			LabelTitle.Add(Chars.LF);
		EndIf;
		LabelTitle.Add(NStr("vi = 'Giá trị được chỉ ra trong chứng từ khác với giá trị thực tế.';
							|ru = 'Сумма расходов, указанная в документе, отличается от фактической.';
							|en = 'The expense amount specified in the document differs from the actual amount.'; fa = 'The expense amount specified in the document differs from the actual amount.';
							|it = 'The expense amount specified in the document differs from the actual amount.';
							|pl = 'The expense amount specified in the document differs from the actual amount.';
							|tr = 'Belgede belirtilen gider tutarı gerçek tutardan farklıdır.'"));
	EndIf; 
	
	If LabelTitle.Count() <> 0 Then
		Items.Information.Title = New FormattedString(LabelTitle);
		Items.PictureInformation.Visible = True;
		Items.Information.Visible = True;
	Else
		Items.PictureInformation.Visible = False;
		Items.Information.Visible = False;
	EndIf; 
	
EndProcedure

&AtServer
Function PreliminaryCostDiffersFromActual()

	If Not ValueIsFilled(Object.Ref) Then
		Return False;
	EndIf;
	
	QueryText = 
	"SELECT
	|	FATable.FixedAsset AS FixedAsset,
	|	FATable.AmountAccounting AS AmountAccounting,
	|	FATable.AmountFA AS AmountFA,
	|	FATable.AmountOfUU AS AmountOfUU
	|INTO TTFATable
	|FROM
	|	&FATable AS FATable
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT TOP 1
	|	FATable.FixedAsset AS FixedAsset
	|FROM
	|	TTFATable AS FATable
	|		INNER JOIN AccumulationRegister.FACost AS FACost
	|		ON (FACost.Recorder = &Ref)
	|			AND FATable.FixedAsset = FACost.FixedAsset
	|			AND (FACost.CostCalculation)
	|			AND (FACost.RecordType = VALUE(AccumulationRecordType.Receipt))
	|
	|GROUP BY
	|	FATable.FixedAsset
	|
	|HAVING
	|	(&PostInAccounting
	|			AND MAX(FATable.AmountAccounting) <> SUM(FACost.LocalCost + FACost.CostTargetFinancing)
	|		OR &RecordInTA
	|			AND MAX(FATable.AmountFA) <> SUM(FACost.CostInTaxAccounting)
	|		OR &RecordInManAccounting
	|			AND MAX(FATable.AmountOfUU) <> SUM(FACost.Cost))";
	
	Query = New Query(QueryText);
	Query.SetParameter("Ref", Object.Ref);
	Query.SetParameter("FATable", Object.FA.Unload());
	Query.SetParameter("PostInAccounting", Object.PostInAccounting);
	Query.SetParameter("RecordInTA", Object.RecordInTA);
	Query.SetParameter("RecordInManAccounting", Object.RecordInManAccounting);
	
	Result = Query.Execute();
	
	Return Not Result.IsEmpty();

EndFunction

&AtServer
Procedure InitializeServiceParametersOfForm()

	NewServiceParametersOfForm = New Structure;
	
	ListOfDetailsForSavingValueBeforeChangingIt = "";
	NewServiceParametersOfForm.Insert("ComplianceCAAccountingIsKept", NonCurrentAssetsInternal.ComplianceCAAccountingIsKept());
	NewServiceParametersOfForm.Insert("ListOfDetailsForSavingValueBeforeChangingIt", ListOfDetailsForSavingValueBeforeChangingIt);
	NewServiceParametersOfForm.Insert("CurrencyOfMan", Constants.ManagementAccountingCurrency.Get());
	NewServiceParametersOfForm.Insert("CurrencyOfManPresentation", String(NewServiceParametersOfForm.CurrencyOfMan));
	NewServiceParametersOfForm.Insert("ThereIsCostAccounting", False);
	
	AllocateVariancesToFixedAssetCostLocalization.FillInServiceParameters(NewServiceParametersOfForm);
	
	FormServiceParameters = New FixedStructure(NewServiceParametersOfForm);
	
EndProcedure

&AtClient
Procedure FillInValuesOfFADetailsBeforeChange()

	AttributesValuesBeforeChange = New Structure;
	AttributesValuesBeforeChange.Insert("AmountOfUU", 0);
	AttributesValuesBeforeChange.Insert("AmountAccounting", 0);
	AttributesValuesBeforeChange.Insert("AmountFA", 0);
	AttributesValuesBeforeChange.Insert("AmountPermanentDifferences", 0);
	
	CurrentData = Items.FA.CurrentData;
	If CurrentData <> Undefined Then
		FillPropertyValues(AttributesValuesBeforeChange, CurrentData);
	EndIf;
	
	FAAttributeValuesBeforeChange = New FixedStructure(AttributesValuesBeforeChange);

EndProcedure

&AtServer
Procedure FillInHeaderForSelectedFA()

	ChangedBankingDetails = "";
	NonCurrentAssetsInternal.FillInHeaderForSelectedFA(
		"Organization,Department", 
		Object.FA, 
		Object, 
		ChangedBankingDetails);
	
	ConfigureDependentFormElementsOnServer(ChangedBankingDetails);
	
EndProcedure

&AtServerNoContext
Function InscriptionDepreciationAdjustment(Val Ref)
	
	Return Documents.FixedAssetCostAndDepreciationAdjustment.TextOfDepreciationAdjustmentLabel(Ref);
		
EndFunction

&AtClient
Procedure CreateAdjustmentCompletion(QuestionResult, AdditionalParameters) Export
	
	If Not ValueIsFilled(Object.Ref)
		Or Modified Then
		
		If QuestionResult <> DialogReturnCode.Yes Then
			Return;
		EndIf;
		
		WriteParameters = New Structure("WriteMode", DocumentWriteMode.Posting);
		If Not Write(WriteParameters) Then
			Return;
		EndIf;
		
	EndIf;
	
	FormParameters = New Structure("Basis", Object.Ref);
	OpenForm("Document.FixedAssetCostAndDepreciationAdjustment.Form.DocumentForm", FormParameters);
	
EndProcedure

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
