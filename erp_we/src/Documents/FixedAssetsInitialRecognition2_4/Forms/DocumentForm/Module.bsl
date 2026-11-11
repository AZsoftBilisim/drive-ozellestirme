
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
	
	ItemsAndDimensionsSelectionParameters = Documents.FixedAssetsInitialRecognition2_4.ItemsAndDimensionsSelectionParameters();
	IncomeAndExpensesServer.OnCreateAtServer(ThisObject, ItemsAndDimensionsSelectionParameters);
	
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
	
	TMCommonUse.CustomizePeripherals(ThisObject);
	
	FormEvents.OnCreateAtServer(ThisObject, Cancel, StandardProcessing);
	
	#EndRegion
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject);
	// End IntegrationWith1CDocumentManagementSubsystem
	
	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	EquipmentManagerClient.StartConnectingDevicesWhenYouOpenForm(Undefined, ThisObject, "BarcodeScanner");
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands


	// StandardSubsystems.FilesOperations
	FilesOperationsClient.OnOpen(ThisObject, Cancel);
	// End StandardSubsystems.FilesOperations

EndProcedure

&AtClient
Procedure OnClose(Exit)
	
	EquipmentManagerClient.StartDisablingHardwareWhenClosingForm(Undefined, ThisObject);
	
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)

	// StandardSubsystems.AccessManagement
	AccessManagement.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.AccessManagement
	
	// Handler of the "Date-change" mechanism
	PeriodClosingDates.ObjectOnReadAtServer(ThisObject, CurrentObject);
	
	OnReadCreateAtServer();

	ItemsAndDimensionsSelectionParameters = Documents.FixedAssetsInitialRecognition2_4.ItemsAndDimensionsSelectionParameters();
	IncomeAndExpensesServer.OnReadAtServer(ThisObject, ItemsAndDimensionsSelectionParameters);
	
	FormEvents.OnReadAtServer(ThisObject, CurrentObject);
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	// End StandardSubsystems.AttachableCommands

	
EndProcedure

&AtClient
Procedure BeforeWrite(Cancel, WriteParameters)
	
	FormEventsClient.BeforeWrite(ThisObject, Cancel, WriteParameters);
	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	ConfigurationModificationOverridable.BeforeWriteAtServer(ThisObject, Cancel, CurrentObject, WriteParameters);
	
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
	Notify("Write_FixedAssetsInitialRecognition2_4", WriteParameters, Object.Ref);
	TMCommonUseClient.NotifyAboutEntryOfDocumentInJournal();
	NonCurrentAssetsClient.NotifyAboutDocumentEntryInFALog();
	
	If Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.FixedAssetsInitialRecognitionByInventoryCount") Then
		Notify("RecordDocumentBasedOnInventory",, Object.Ref);
	EndIf; 
	

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

	FillInInformationInBasement();
	FillInContractInTablePart();
	
	// StandardSubsystems.AccessManagement
	AccessManagement.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	// End StandardSubsystems.AccessManagement
	

	Items.CommentPage.Picture = CommonClientServer.CommentPicture(Object.Comment);
	
	FixedAssetsInitialRecognitionLocalization.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	
	IncomeAndExpensesServer.AfterWriteAtServer(ThisObject);
	
	ConfigurationModificationOverridable.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	
	FormEvents.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If EventName = "Write_FixedAssetsInitialRecognition2_4" 
		And Source <> Object.Ref Then
			
		FillInInformationInBasement();
		
	ElsIf EventName = "Write_FixedAssetCostAndDepreciationAdjustment" 
		And Source <> Object.Ref Then
			
		ConfigureDependentFormElements("Write_FixedAssetCostAndDepreciationAdjustment");
		
	EndIf; 
	
	// Peripherals
	If Source = "Peripherals" And IsInputAvailable() Then
		If EventName = "ScanData" And EquipmentManagerTMClient.ThereIsRawEvent() Then
			ProcessBarcodes(EquipmentManagerTMClient.ConvertDataFromScannerToStructure(Parameter));
		EndIf;
	EndIf;
	// End Peripherals
	

	FormEventsClient.NotificationProcessing(ThisObject, EventName, Parameter, Source);
	
	// StandardSubsystems.FilesOperations
	FilesOperationsClient.NotificationProcessing(ThisObject, EventName);
	// End StandardSubsystems.FilesOperations

EndProcedure

&AtClient
Procedure URLProcessing(FormattedStringURL, StandardProcessing)
	
	FixedAssetsInitialRecognitionClientLocalization.URLProcessing(
		ThisObject, FormattedStringURL, StandardProcessing);
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

#Region PageGeneral

&AtClient
Procedure DateOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	
	NonCurrentAssetsClient.SetCurrentTimeForLastDate(Object.Date);
	
	ConfigureDependentFormElements("Date");
	
EndProcedure

&AtClient
Procedure AdjustmentModeFromPreviousDateOnChange(Item)
	
	If Not ValueIsFilled(Object.DepreciationAdjustmentOption)
		And Object.AdjustmentModeFromPreviousDate Then
		Object.DepreciationAdjustmentOption = PredefinedValue("Enum.AdditionalDepreciationAccrualOptions.Automatically");
	EndIf;
	 
	ConfigureDependentFormElements("AdjustmentModeFromPreviousDate,DepreciationAdjustmentOption");
	
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
	
	If Not Object.PostInAccounting And Not Object.RecordInTA And Not Object.RecordInManAccounting Then
		Object.RecordInManAccounting = True;
	EndIf;

	ConfigureDependentFormElements("RecordInManAccounting");

EndProcedure

&AtClient
Procedure BusinessOperationOnChange(Item)
	
	Object.DocumentBasis = Undefined;
	Object.GeneratedDocument = False;
	
	ConfigureDependentFormElements("BusinessOperation");
	
EndProcedure

&AtClient
Procedure OrganizationOnChange(Item)
	
	OrganizationWhenChangedOnServer();
	
EndProcedure

&AtClient
Procedure FixedAssetsLocationOnChange(Item)

	ConfigureDependentFormElements(Item.Name);
	
EndProcedure

&AtClient
Procedure ContractOnChange(Item)
	
	ConfigureDependentFormElements("Contract");

EndProcedure

&AtClient
Procedure PartialCommissioningOnChange(Item)
	
	ConfigureDependentFormElements("PartialCommissioning");
	
EndProcedure

&AtClient
Procedure TypeOfExpenseAnalysisFixedAssetsOnChange(Item)
	
	ConfigureDependentFormElements("DimensionKindExpenseCapitalization,PartialCommissioning");
	
EndProcedure

&AtClient
Procedure TypeOfCostAnalysisConstructionObjectsOnChange(Item)
	
	ConfigureDependentFormElements("DimensionKindExpenseCapitalization");
	
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
		Object,, 
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
		OpenForm("Document.FixedAssetsInitialRecognition2_4.ObjectForm", FormParameters);
	EndIf; 
	
EndProcedure

&AtClient
Procedure GeneratedDocumentOnChange(Item)
	
	If Not Object.GeneratedDocument Then
		Object.DocumentBasis = Undefined;
		Return;
	EndIf; 
			
	If Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.RecognitionOfLeaseItems") Then

		ChoiceList = New ValueList;
		ChoiceList.Add(Type("DocumentRef.SigningOfLeaseContract"));
		ChoiceList.Add(Type("DocumentRef.LeaseTermAdjustment"));
		
		Notification = New CallbackDescription("SelectingBaseDataTypeEnd", ThisObject);
		ChoiceList.ShowChooseItem(Notification, NStr("vi = 'Chọn dạng cơ sở';
													|ru = 'Выбор вида основания';
													|en = 'Select a base document kind'; fa = 'Select a base document kind';
													|it = 'Выбор вида основания';
													|pl = 'Select a base document kind';
													|tr = 'Taban türü seçimi'"));
		
	ElsIf Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.FixedAssetsInitialRecognitionByInventoryCount") Then
		
		ListFilter = New Structure;
		ListFilter.Insert("Posted", True);
		If ValueIsFilled(Object.Organization) Then
			ListFilter.Insert("Organization", Object.Organization);
		EndIf;
		
		If ValueIsFilled(Object.FixedAssetsLocation) Then
			ListFilter.Insert("Department_Company", Object.FixedAssetsLocation);
		EndIf;
		
		CallbackDescription = New CallbackDescription("GeneratedDocumentOnChangeCompletion", ThisObject);
		
		FormParameters = New Structure;
		FormParameters.Insert("Filter", ListFilter);
		OpenForm("Document.FixedAssetsPhysicalCount.ChoiceForm", FormParameters,,,,, CallbackDescription);
		
	EndIf;
				
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
Procedure Decorationedonage(Item, StandardProcessing)
	
	
	Return; // WE have an empty handler

EndProcedure

#EndRegion

#Region TheAccountingPage

&AtClient
Procedure AccountingProcedureACOnChange(Item)
	
	OrderOfAccountingForBUWhenChangingOnServer();
	
EndProcedure

&AtClient
Procedure UsefulLifeAccountingOnChange(Item)
	
	WhenChangingPeriodOfUse("UsefulLifeAccounting", True);

EndProcedure

&AtClient
Procedure DepreciationMethodAccountingOnChange(Item)
	ConfigureDependentFormElements(Item.Name);
EndProcedure

&AtClient
Procedure AccountingProcedureMAOnChange(Item)
	
	AccountingProcedureForMAWhenChangingOnServer();
	
EndProcedure

&AtClient
Procedure UsefulLifeManagementAccountingOnChange(Item)
	
	WhenChangingPeriodOfUse("UsefulLifeManagementAccounting", False);
	
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
	
	ConfigureDependentFormElements(Item.Name);
	
EndProcedure

#EndRegion

#Region Localization

&AtClient
Procedure Attachable_OnChangeAttribute(Item)

	FixedAssetsInitialRecognitionClientLocalization.OnChangeAttribute(Item, ThisObject);

EndProcedure

&AtClient
Procedure Attachable_StartChoice(Item, ChoiceData, StandardProcessing)
	
	FixedAssetsInitialRecognitionClientLocalization.StartChoice(Item, ChoiceData, StandardProcessing, ThisObject);
	
EndProcedure

&AtClient
Procedure Attachable_AutoComplete(Item, Text, ChoiceData, DataGetParameters, Waiting, StandardProcessing)
	
	FixedAssetsInitialRecognitionClientLocalization.AutoComplete(Item, Text, ChoiceData, DataGetParameters, Waiting, StandardProcessing, ThisObject);
	
EndProcedure

&AtClient
Procedure Attachable_TextEditEnd(Item, Text, ChoiceData, DataGetParameters, StandardProcessing)
	
	FixedAssetsInitialRecognitionClientLocalization.TextEditEnd(Item, Text, ChoiceData, DataGetParameters, StandardProcessing, ThisObject);
	
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
Procedure FAAfterDeleteRow(Item)
	
	ConfigureDependentFormElements("FixedAsset");
	
EndProcedure

&AtClient
Procedure FASelection(Item, RowSelected, Field, StandardProcessing)
	
	CurrentData = Items.FA.CurrentData;
	
	If Field = Items.FAContract
		And CurrentData <> Undefined
		And ValueIsFilled(CurrentData.Contract) Then
		
		StandardProcessing = False;
		ShowValue(, CurrentData.Contract);
	EndIf;

EndProcedure

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
Procedure FACostInAccountingOnChange(Item)
	
	FACostOfACWhenChangedOnServer();
	
	FillInValuesOfFADetailsBeforeChange();
	
EndProcedure

&AtClient
Procedure FACostInManagementAccountingOnChange(Item)
	
	FillInInformationInBasement();
	
	FillInValuesOfFADetailsBeforeChange();
	
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
Procedure FillInCost(Command)
	
	ClearMessages();
	
	FillInPreliminaryCost();
	
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

#Region BarcodesAndTradeEquipment

&AtClient
Procedure ImportDataFromPDT(Command)
	
	LoadDataFromTSD();
	
EndProcedure

#EndRegion

#Region AttachableCommands

&AtClient
Procedure Attachable_OnExecuteCommand(Command)

	FixedAssetsInitialRecognitionClientLocalization.OnExecuteCommand(Command, ThisObject);

EndProcedure

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

#Region FAFilling

&AtServer
Procedure SelectionOnServer(ValueSelected)

	AddedRows = NonCurrentAssetsClientServer.ProcessingElementSelection(Object.FA, "FixedAsset", ValueSelected);

	If AddedRows.Count() <> 0 Then
		
		ChangedBankingDetails = "FixedAsset";
		FixedAssetsInitialRecognitionLocalization.ProcessingElementSelection(ThisObject, ChangedBankingDetails);
		ConfigureDependentFormElementsOnServer(ChangedBankingDetails);
		
		FillInPreliminaryCost(AddedRows);
		
	EndIf;
	
EndProcedure

&AtServer
Procedure FillInPreliminaryCost(RowsSelected = Undefined)

	If Not FormServiceParameters.ThereIsCostAccounting
		Or Object.BusinessOperation = Enums.BusinessTransactions.FixedAssetsInitialRecognitionByInventoryCount Then
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
			CommonClientServer.MessageToUser(MessageText, , "Object", "Date", Cancel);
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
			CommonClientServer.MessageToUser(MessageText, , "Object", "Organization", Cancel); 
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
			CommonClientServer.MessageToUser(MessageText, , "Object", "ConstructionObject", Cancel); 
		Else
			Cancel = True;
		EndIf; 
	EndIf;
	
	If Not Cancel Then
		Documents.FixedAssetsInitialRecognition2_4.FillInCost(Object, RowsSelected);
	EndIf;
	
	FillInInformationInBasement();
	
EndProcedure

#EndRegion

#Region BarcodesAndTradeEquipment

&AtServer
Procedure ProcessBarcodes(Val BarcodeData_5)
	
	PickingParameters = TMCommonUseClientServer.PickingParameters(Items.FAFixedAsset, ThisObject);
	ObjectsArray = NonCurrentAssets.FindFixedAssetsByBarcodes(BarcodeData_5, PickingParameters);
	SelectionOnServer(ObjectsArray);
	
EndProcedure

&AtClient
Procedure LoadDataFromTSD()
	
	ClearMessages();
	
	EquipmentManagerClient.StartDownloadingDataFromTSD(
		New CallbackDescription("DownloadFromTSDCompletion", ThisObject),
		UUID);
	
EndProcedure

&AtClient
Procedure DownloadFromTSDCompletion(Result, AdditionalParameters) Export
	
	If Result.Result Then
		ProcessBarcodes(Result.TableOfGoods);
	Else
		EquipmentManagerTMClient.ReportError(Result);
	EndIf;
	
EndProcedure

#EndRegion

#Region OnChangeAttributes

&AtClient
Procedure AtEndOfChangingLocalizationDetails(TagName, NotificationParameters) Export
	
	Var ActionParameters;

	If NotificationParameters.ServerCallRequired_ Then
		WhenYouChangeDetailsOfCompletionOnServer(TagName, NotificationParameters.ProcessingParameters);
	EndIf;

	If Not NotificationParameters.ServerCallRequired_ Then
		
		If NotificationParameters.ProcessingParameters.Property("Execute_ConfigureDependentFormElements", ActionParameters) Then
			ConfigureDependentFormElements(ActionParameters);
		EndIf;

		If NotificationParameters.ProcessingParameters.Property("Execute_WhenChangingPeriodOfUse", ActionParameters) Then
			WhenChangingPeriodOfUse(ActionParameters.AttributeName, ActionParameters.UpdateIfMatch);
		EndIf;

		If NotificationParameters.ProcessingParameters.Property("Execute_FillInFADetailsValuesBeforeChanging", ActionParameters) Then
			FillInValuesOfFADetailsBeforeChange();
		EndIf;

	EndIf;
	
EndProcedure

&AtServer
Procedure WhenYouChangeDetailsOfCompletionOnServer(Val TagName, Val AdditionalParameters)
	
	Var ActionParameters;

	FixedAssetsInitialRecognitionLocalization.OnChangeAttribute(TagName, ThisObject, AdditionalParameters);

	If AdditionalParameters.Property("Execute_ConfigureDependentFormElements", ActionParameters) Then
		ConfigureDependentFormElementsOnServer(ActionParameters);
	EndIf;
	
	If AdditionalParameters.Property("Execute_FillInformationInBasement", ActionParameters) Then
		FillInInformationInBasement();
	EndIf;
	
EndProcedure

&AtServer
Procedure FAIsPrimaryMeansWhenChangingOnServer()

	ChangedBankingDetails = "FixedAsset";
	
	CurrentRow = Items.FA.CurrentRow;
	RowData = Object.FA.FindByID(CurrentRow);
	
	FillInPreliminaryCost(CommonClientServer.ValueInArray(RowData));
	
	FixedAssetsInitialRecognitionLocalization.FAFixedAssetOnChange(ThisObject, ChangedBankingDetails);
	
	ConfigureDependentFormElementsOnServer(ChangedBankingDetails);
	
EndProcedure

&AtClient
Procedure WhenChangingPeriodOfUse(Var_AttributeName, UpdateIfMatch)

	AttributesList = NonCurrentAssetsClient.WhenChangingPeriodOfUse(
						Object, Var_AttributeName, UsefulLivesMatch And UpdateIfMatch);
	
	SetTermsOfUseToMatch(ThisObject);
	
	ConfigureDependentFormElements(AttributesList);		

EndProcedure

&AtServer
Procedure FACostOfACWhenChangedOnServer()

	CurrentRow = Items.FA.CurrentRow;
	CurrentData = Object.FA.FindByID(CurrentRow);
	
	If FAAttributeValuesBeforeChange.CostInAccounting = FAAttributeValuesBeforeChange.CostInManagementAccounting 
		And Object.RecordInManAccounting 
		And FormServiceParameters.ComplCurrency = FormServiceParameters.CurrencyOfMan
		And FormServiceParameters.ComplianceCAAccountingIsKept Then
		CurrentData.CostInManagementAccounting = CurrentData.CostInAccounting;
	EndIf; 

	FixedAssetsInitialRecognitionLocalization.FACostInAccountingOnChange(ThisObject, CurrentData);
	
	FillInInformationInBasement();
	
	ConfigureDependentFormElementsOnServer("CostInAccounting");
	
EndProcedure

&AtClient
Procedure WhenChangingAddressPresentation(Item)

	NonCurrentAssetsClient.WhenChangingAddressPresentation(
		Item,
		Object.LocationAddress,
		Object.LocationAddressValue);

EndProcedure

&AtServer
Procedure OrganizationWhenChangedOnServer()
	
	Object.VATTaxation = NonCurrentAssets.VATTaxation(Object.Organization, Object.Date);
	
	ConfigureDependentFormElementsOnServer("Organization,ThereAreRelatedCompanies, VATTaxation");
	
EndProcedure

#EndRegion

#Region Other

&AtServer
Procedure ExecuteCommandAtServer(ExecutionParameters)
	AttachableCommands.ExecuteCommand(ThisObject, ExecutionParameters, Object);
EndProcedure

&AtClient
Procedure ContinueRunningLocalizationCommand(CommandName, NotificationParameters) Export

	Var ActionParameters;
	
	If NotificationParameters.ServerCallRequired_ Then
		WhenExecutingEndCommandOnServer(CommandName, NotificationParameters.ProcessingParameters);
		Return;
	EndIf;

	If NotificationParameters.ProcessingParameters.Property("Execute_ConfigureDependentFormElements", ActionParameters) Then
		ConfigureDependentFormElements(ActionParameters);
	EndIf; 
	
EndProcedure

&AtServer
Procedure WhenExecutingEndCommandOnServer(Val CommandName, Val AdditionalParameters)

	FixedAssetsInitialRecognitionLocalization.OnExecuteCommand(CommandName, ThisObject);
	
	If AdditionalParameters.Property("Execute_ConfigureDependentFormElements") Then
		ConfigureDependentFormElementsOnServer(AdditionalParameters.Execute_ConfigureDependentFormElements);
	EndIf; 

EndProcedure
 
&AtClient
Procedure Attachable_CloseForm()
	
	Close();
	
EndProcedure

&AtServer
Procedure OnReadCreateAtServer()

	InitializingFormWhenCreatingItOnServer();
	
	ExpenseItemBeforeChange = Object.ExpenseItemAccounting;
	ExpenditureDimensionBeforeChange = Object.ExpensesDimensionAccounting;
	
	Items.CommentPage.Picture = CommonClientServer.CommentPicture(Object.Comment);
	
	FillInInformationInBasement();
	
	ConfigureDependentFormElementsOnServer();
		
	Items.GroupSettingTheAccountingParameterWELL.Enabled = Not ReadOnly And
		AccessRight("Edit", Metadata.Documents.FixedAssetsInitialRecognition2_4);
		
	FixedAssetsInitialRecognitionLocalization.OnReadCreateAtServer(ThisObject);
	
EndProcedure

&AtServer
Procedure InitializingFormWhenCreatingItOnServer()

	InitializeServiceParametersOfForm();
	
	CurrencyOfMan = Constants.ManagementAccountingCurrency.Get();
	ComplCurrency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Object.Organization);
	
	CurrenciesDoNotMatch = (CurrencyOfMan = ComplCurrency);
	
	UseConstructionObjects = GetFunctionalOption("UseConstructionObjects");
	
EndProcedure

&AtServer
Procedure InitializeServiceParametersOfForm()

	NewServiceParametersOfForm = New Structure;
	NewServiceParametersOfForm.Insert("PresentationOfDetails", Documents.FixedAssetsInitialRecognition2_4.PresentationOfDetails(Object.Organization, Object.Date));
	NewServiceParametersOfForm.Insert("ThereIsCostAccounting", False);
	NewServiceParametersOfForm.Insert("UseLocal", LocalAccntingServer.ReglRecordsAreMaintained(Object.Date));
	NewServiceParametersOfForm.Insert("AssetHolder", Enums.LeasedAssetHolder.Leaseholder);
	NewServiceParametersOfForm.Insert("RecognizeLeasedItemsInLocalAccounting", True);
	NewServiceParametersOfForm.Insert("RecognizeLeasedAssetsInManagementAccounting", True);
	NewServiceParametersOfForm.Insert("RentalItemsAreTakenIntoAccountIn", False);
	NewServiceParametersOfForm.Insert("ComplianceWithContracts", New FixedMap(New Map()));
	NewServiceParametersOfForm.Insert("ThereIsRightToAddAdjustments", AccessRight("InteractiveInsert", Metadata.Documents.FixedAssetCostAndDepreciationAdjustment));
	NewServiceParametersOfForm.Insert("ComplianceCAAccountingIsKept", NonCurrentAssetsInternal.ComplianceCAAccountingIsKept());
	NewServiceParametersOfForm.Insert("CurrencyOfMan",  Constants.ManagementAccountingCurrency.Get());
	
	NewServiceParametersOfForm.Insert(
		"UseAccountingByAreasOfActivity", 
		GetFunctionalOption("UseFixedAssetAccountingByActivities"));
	
	FormServiceParameters = New FixedStructure(NewServiceParametersOfForm);

EndProcedure

&AtServer
Procedure SetConditionalAppearance()
	
	ConditionalAppearance.Items.Clear();
	
	FixedAssetsInitialRecognitionLocalization.SetConditionalAppearance(ConditionalAppearance, Items);

	NonCurrentAssetsInternal.EstablishConditionalAppearanceOfTargetedFinancing(ConditionalAppearance, Items);
		
	#Region OSContract_TextColor
	Item = ConditionalAppearance.Items.Add();
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.FAContract.Name);
	Item.Appearance.SetParameterValue("TextColor", StyleColors.HyperlinkColor);
	#EndRegion
		
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
Procedure ConfigureDependentFormElementsOnClientOnServer(Form, ChangedBankingDetails)

	Object = Form.Object;
	Items = Form.Items;
	FormServiceParameters = Form.FormServiceParameters;
	PresentationOfDetails = FormServiceParameters.PresentationOfDetails; // Map
	
	AuxiliaryAttributes = New Structure;
	AuxiliaryAttributes.Insert("UseConstructionObjects", Form.UseConstructionObjects);
	AuxiliaryAttributes.Insert("RecordInLocalAccounting", Object.RecordInLocalAccounting);
	AuxiliaryAttributes.Insert("RecordInManAccounting", Object.RecordInManAccounting);
	AuxiliaryAttributes.Insert("PostInAccounting", Object.PostInAccounting);
	AuxiliaryAttributes.Insert("RecordInTA", Object.RecordInTA);
	AuxiliaryAttributes.Insert("ComplianceCAAccountingIsKept", FormServiceParameters.ComplianceCAAccountingIsKept);
	AuxiliaryAttributes.Insert("CurrenciesDoNotMatch", FormServiceParameters.ComplCurrency = FormServiceParameters.CurrencyOfMan);
	AuxiliaryAttributes.Insert("ThereIsCostAccounting", FormServiceParameters.ThereIsCostAccounting);
	AuxiliaryAttributes.Insert("UseLocal", FormServiceParameters.UseLocal);
	AuxiliaryAttributes.Insert("FALocalAccountingIsConductedIndependently", FormServiceParameters.FALocalAccountingIsConductedIndependently);
	AuxiliaryAttributes.Insert("UseAccountingByAreasOfActivity", FormServiceParameters.UseAccountingByAreasOfActivity);
	AuxiliaryAttributes.Insert("AccountPolicySettings", FormServiceParameters.AccountPolicySettings);
	AuxiliaryAttributes.Insert("SettingUpReflectionOfTaxExpensesIsRequired", False);
	AuxiliaryAttributes.Insert("PropertyTaxAdvancesArePaid", False);
	AuxiliaryAttributes.Insert("ThereAreRelatedCompanies", FormServiceParameters.ThereAreRelatedCompanies);
	FixedAssetsInitialRecognitionClientServerLocalization.AddAuxiliaryDetails(Form, AuxiliaryAttributes);
	
	NonCurrentAssetsClientServer.WhenChangingBankingDetails_AcceptanceForAccountingByFA(Object, AuxiliaryAttributes, ChangedBankingDetails);
	
	StructureOfChangedProps = New Structure(ChangedBankingDetails);
	
	UpdateAll = StructureOfChangedProps.Count() = 0;
	
	FAAcceptanceParameters = NonCurrentAssetsClientServer.FAAcceptanceParameters(Object, AuxiliaryAttributes);
	
	ItemDetailsParameters = NonCurrentAssetsClientServer.PropertyValuesOfDependentProps_AcceptanceForAccountingByFA(
									Object, AuxiliaryAttributes, ChangedBankingDetails);
	
	TMCommonUseClientServer.ConfigureDependentFormElements(Form, ItemDetailsParameters);
	
	If Not UpdateAll Then
		
		ChangedAttributesAfterSettingUp = New Array;
		
		TMCommonUseClientServer.ClearUnusedProps(
			Object, ItemDetailsParameters, "FA,TargetFinancing", ChangedAttributesAfterSettingUp);
		
		FillInDetailsDependingOnProperties(Form, ItemDetailsParameters, ChangedAttributesAfterSettingUp);

		If ChangedAttributesAfterSettingUp.Count() <> 0 Then
			
			ChangedAttributesAfterSettingUp = StrConcat(ChangedAttributesAfterSettingUp, ",");
			
			NonCurrentAssetsClientServer.WhenChangingBankingDetails_AcceptanceForAccountingByFA(Object, AuxiliaryAttributes, ChangedAttributesAfterSettingUp);
			
			ItemDetailsParameters = NonCurrentAssetsClientServer.PropertyValuesOfDependentProps_AcceptanceForAccountingByFA(
											Object, AuxiliaryAttributes, ChangedAttributesAfterSettingUp);
		
			TMCommonUseClientServer.ConfigureDependentFormElements(Form, ItemDetailsParameters);
			
		EndIf;
		
	EndIf;
	
	LocalAccountingSettingsAreAvailable = (Object.RecordInLocalAccounting And AuxiliaryAttributes.FALocalAccountingIsConductedIndependently);
	
	#Region PageGeneral
	
	Items.DecorationIndentPartialCommissioning.Visible = Items.PartialCommissioning.Visible;
	
	If UpdateAll Then
		SetTermsOfUseToMatch(Form);
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
	
	If StructureOfChangedProps.Property("AdjustmentModeFromPreviousDate")
		Or StructureOfChangedProps.Property("DepreciationAdjustmentOption")
		Or StructureOfChangedProps.Property("Write_FixedAssetCostAndDepreciationAdjustment")
		Or UpdateAll Then
		
		If Object.AdjustmentModeFromPreviousDate
			And Object.DepreciationAdjustmentOption = PredefinedValue("Enum.AdditionalDepreciationAccrualOptions.Manually") Then
				
			Form.DepreciationAdjustment = InscriptionDepreciationAdjustment(Object.Ref);
			
			Items.DepreciationAdjustment.Visible = True;
			
		Else
			Items.DepreciationAdjustment.Visible = False;
		EndIf;
		
	EndIf;
	
	#EndRegion

	#Region OSPage
		
	If StructureOfChangedProps.Property("Date")
		Or StructureOfChangedProps.Property("Organization")
		Or StructureOfChangedProps.Property("OSGroup")
		Or StructureOfChangedProps.Property("DepreciationGroup")
		Or StructureOfChangedProps.Property("RealEstate")
		Or StructureOfChangedProps.Property("BusinessOperation")
		Or StructureOfChangedProps.Property("FixedAsset")
		Or StructureOfChangedProps.Property("Contract")
		Or StructureOfChangedProps.Property("PostInAccounting")
		Or StructureOfChangedProps.Property("RecordInManAccounting")
		Or StructureOfChangedProps.Property("AccountingProcedureAC")
		Or StructureOfChangedProps.Property("AccountingProcedureMA")
		Or StructureOfChangedProps.Property("AdjustmentModeFromPreviousDate")
		Or StructureOfChangedProps.Property("AccrueAdditionalDepreciationForPreviousPeriod")
		Or StructureOfChangedProps.Property("PartialCommissioning")
		Or UpdateAll Then
		
		Items.FAFillInCost.Visible = 
			Not FAAcceptanceParameters.ActualCost
			And (Items.FACostInAccounting.Visible
				Or Items.FACostInTaxAccounting.Visible
				Or Items.FACostInManagementAccounting.Visible);
		
	EndIf;
	
	If StructureOfChangedProps.Property("BusinessOperation")
		Or StructureOfChangedProps.Property("Contract")
		Or UpdateAll Then
		
		Items.FAContract.Visible = 
			Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.RecognitionOfLeaseItems")
			And Not ValueIsFilled(Object.Contract);
				
	EndIf;
	
	If StructureOfChangedProps.Property("Date")
		Or StructureOfChangedProps.Property("Organization")
		Or UpdateAll Then
		
		Items.FACostInManagementAccounting.Title = PresentationOfDetails.Get("FA.CostInManagementAccounting");
		Items.FACostInAccounting.Title = PresentationOfDetails.Get("FA.CostInAccounting");
		Items.FACostInTaxAccounting.Title = PresentationOfDetails.Get("FA.CostInTaxAccounting");
		Items.FACostPermanentDifference.Title = PresentationOfDetails.Get("FA.CostPermanentDifference");
		Items.FAResidualValueMan.Title = PresentationOfDetails.Get("FA.ResidualValueMan");
		Items.FAResidualValueLocal.Title = PresentationOfDetails.Get("FA.ResidualValueLocal");
		
	EndIf;
	
	If StructureOfChangedProps.Property("Date")
		Or StructureOfChangedProps.Property("Organization")
		Or StructureOfChangedProps.Property("OSGroup")
		Or StructureOfChangedProps.Property("DepreciationGroup")
		Or StructureOfChangedProps.Property("RealEstate")
		Or StructureOfChangedProps.Property("BusinessOperation")
		Or StructureOfChangedProps.Property("FixedAsset")
		Or StructureOfChangedProps.Property("Contract")
		Or StructureOfChangedProps.Property("PostInAccounting")
		Or StructureOfChangedProps.Property("RecordInManAccounting")
		Or StructureOfChangedProps.Property("AccountingProcedureAC")
		Or StructureOfChangedProps.Property("AccountingProcedureMA")
		Or UpdateAll Then
		
		If (FAAcceptanceParameters.CostIsRequiredToCalculateDepreciationOfAC
				Or FAAcceptanceParameters.CostIsRequiredToCalculateDepreciationOfAC)
			And FAAcceptanceParameters.CostIsRequiredToCalculateTax
			And (Items.FACostInAccounting.Visible
				Or Items.FACostInManagementAccounting.Visible) Then
			
			Items.FABasementInfoText.Visible = True;
			Items.FABasementInformationPicture.Visible = True;
			
			Items.FABasementInfoText.Title =
				NStr("vi = 'Giá trị được sử dụng để tính khấu hao trong tháng hiện tại và để tính thuế tài sản.
					 |Số tiền này có thể không khớp với giá trị thực tế, trong trường hợp đó, khấu hao sẽ được điều chỉnh vào tháng sau, còn số thuế sẽ được tính trong cùng tháng này.';
					 |ru = 'Стоимость используется для расчета амортизации в текущем месяце и для начисления налога на имущество.
					 |Она может не совпадать с фактической стоимостью, в этом случае амортизация будет скорректирована в следующем месяце, а сумма налога в этом же месяце.';
					 |en = 'The cost is used to calculate depreciation for the current month and to calculate the property tax.
					 |It may not match the actual cost. In this case, the depreciation will be adjusted next month, and the tax amount will be adjusted in the same month.'; fa = 'The cost is used to calculate depreciation for the current month and to calculate the property tax.
					 |It may not match the actual cost. In this case, the depreciation will be adjusted next month, and the tax amount will be adjusted in the same month.';
					 |it = 'The cost is used to calculate depreciation for the current month and to calculate the property tax.
					 |It may not match the actual cost. In this case, the depreciation will be adjusted next month, and the tax amount will be adjusted in the same month.';
					 |pl = 'The cost is used to calculate depreciation for the current month and to calculate the property tax.
					 |It may not match the actual cost. In this case, the depreciation will be adjusted next month, and the tax amount will be adjusted in the same month.';
					 |tr = 'Maliyet, cari ayda amortisman hesaplaması ve emlak vergisi tahakkuku için kullanılır.
					 |Gerçek maliyetle örtüşmeyebilir, bu durumda amortisman bir sonraki ayda, vergi tutarı ise aynı ayda düzeltilir.'");
		 
		ElsIf (FAAcceptanceParameters.CostIsRequiredToCalculateDepreciationOfAC
				Or FAAcceptanceParameters.CostIsRequiredToCalculateDepreciationOfAC)
			And (Items.FACostInAccounting.Visible
				Or Items.FACostInManagementAccounting.Visible) Then
			
			Items.FABasementInfoText.Visible = True;
			Items.FABasementInformationPicture.Visible = True;
			
			Items.FABasementInfoText.Title =
				NStr("vi = 'Giá trị được sử dụng để tính khấu hao trong tháng hiện tại.
					 |Số tiền này có thể không khớp với giá trị thực tế, trong trường hợp đó, khấu hao sẽ được điều chỉnh vào tháng sau.';
					 |ru = 'Стоимость используется для расчета амортизации в текущем месяце.
					 |Она может не совпадать с фактической стоимостью, в этом случае амортизация будет скорректирована в следующем месяце.';
					 |en = 'The cost is used to calculate depreciation for the current month.
					 |It may not match the actual cost. In this case, the depreciation will be adjusted next month.'; fa = 'The cost is used to calculate depreciation for the current month.
					 |It may not match the actual cost. In this case, the depreciation will be adjusted next month.';
					 |it = 'The cost is used to calculate depreciation for the current month.
					 |It may not match the actual cost. In this case, the depreciation will be adjusted next month.';
					 |pl = 'The cost is used to calculate depreciation for the current month.
					 |It may not match the actual cost. In this case, the depreciation will be adjusted next month.';
					 |tr = 'Maliyet, cari ayda amortisman hesaplaması için kullanılır.
					 | Gerçek maliyetle örtüşmeyebilir, bu durumda amortisman bir sonraki ayda düzeltilir.'");
					 
		ElsIf FAAcceptanceParameters.CostIsRequiredToCalculateTax
			And Items.FACostInAccounting.Visible Then
			
			Items.FABasementInfoText.Visible = True;
			Items.FABasementInformationPicture.Visible = True;
			
			Items.FABasementInfoText.Title =
				NStr("vi = 'Giá trị được sử dụng để tính thuế tài sản.
					 |Số tiền này có thể không khớp với giá trị thực tế, trong trường hợp đó, số thuế sẽ được điều chỉnh trong cùng tháng này.';
					 |ru = 'Стоимость используется для начисления налога на имущество.
					 |Она может не совпадать с фактической стоимостью, в этом случае сумма налога будет скорректирована в этом же месяце.';
					 |en = 'The cost is used to calculate the property tax.
					 |It may not match the actual cost. In this case, the tax amount will be adjusted in the same month.'; fa = 'The cost is used to calculate the property tax.
					 |It may not match the actual cost. In this case, the tax amount will be adjusted in the same month.';
					 |it = 'The cost is used to calculate the property tax.
					 |It may not match the actual cost. In this case, the tax amount will be adjusted in the same month.';
					 |pl = 'The cost is used to calculate the property tax.
					 |It may not match the actual cost. In this case, the tax amount will be adjusted in the same month.';
					 |tr = 'Maliyet, emlak vergisi tahakkuku için kullanılır.
					 |Gerçek maliyetle örtüşmeyebilir, bu durumda vergi tutarı aynı ayda düzeltilir.'");
					 
		Else
		 
			Items.FABasementInfoText.Visible = False;
			Items.FABasementInformationPicture.Visible = False;
			
		EndIf;
		
	EndIf;
	
	#EndRegion
	
	#Region TheAccountingPage
	
	If StructureOfChangedProps.Property("UsefulLifeAccounting")
		Or StructureOfChangedProps.Property("AccountingProcedureAC")
		Or StructureOfChangedProps.Property("RecordInLocalAccounting")
		Or UpdateAll Then
		
		Form.ACUsefulLifeExplanation = NonCurrentAssetsClientServer.PresentationOfNumberOfMonthsByString(
			Object.UsefulLifeAccounting);
			
	EndIf;
	
	If StructureOfChangedProps.Property("UsefulLifeManagementAccounting")
		Or StructureOfChangedProps.Property("AccountingProcedureMA")
		Or StructureOfChangedProps.Property("RecordInManAccounting")
		Or UpdateAll Then
		
		Form.UsefulLifeMAExplanation = NonCurrentAssetsClientServer.PresentationOfNumberOfMonthsByString(
			Object.UsefulLifeManagementAccounting);
			
	EndIf;
	
	#EndRegion
	
	#Region PageExpenseRecord
	
	If StructureOfChangedProps.Property("RecordInLocalAccounting")
		Or StructureOfChangedProps.Property("RecordInManAccounting")
		Or StructureOfChangedProps.Property("AccountingProcedureMA") 
		Or UpdateAll Then
	
		If Object.AccountingProcedureMA = PredefinedValue("Enum.FixedAssetValueRegistrationProcedure.IncludeInExpensesOnRecognition")
			Or Object.AccountingProcedureMA = PredefinedValue("Enum.FixedAssetValueRegistrationProcedure.DoNotTakeIntoAccountIncludeInExpenses") Then
			
			Items.GroupAccountingForDepreciationAndAmortisationUpr.Title = 
				?(LocalAccountingSettingsAreAvailable, NStr("vi = 'Đưa vào chi phí (kế toán quản trị)';
															|ru = 'Включение в расходы (управленческий учет)';
															|en = 'Add to expenses (management accounting)'; fa = 'Add to expenses (management accounting)';
															|it = 'Inclusione nelle uscite (contabilità gestionale)';
															|pl = 'Włączenie do rozchodów (ewidencja zarządcza)';
															|tr = 'Gider Dahil Etme (Yönetim Muhasebesi)'"), NStr("vi = 'Đưa vào chi phí';
																													|ru = 'Включение в расходы';
																													|en = 'Add to expenses'; fa = 'Add to expenses';
																													|it = 'Inclusione nelle uscite';
																													|pl = 'Włączenie do rozchodów';
																													|tr = 'Giderlere dahil edilme'"));
				 
			Items.ExpenseItemManagementAccounting.ToolTip = NStr("vi = 'Dạng chi phí, theo đó giá trị được đưa vào chi phí';
																|ru = 'Статья расходов, по которой стоимость включается в расходы';
																|en = 'Expense item by which a cost is included in expenses'; fa = 'Expense item by which a cost is included in expenses';
																|it = 'Voci di uscita in base alle quali il costo viene incluso nelle uscite';
																|pl = 'Pozycja rozchodów, według której wartość jest włączana do rozchodów';
																|tr = 'Maliyetin gidere dahil edildiği gider kalemi'");
			
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
			 
			Items.ExpenseItemManagementAccounting.ToolTip = NStr("vi = 'Dạng chi phí mà chi phí khấu hao được phản ánh';
																|ru = 'Статья расходов, по которой отражаются амортизационные расходы';
																|en = 'Expense item recording depreciation expenses'; fa = 'قلم هزینه ثبت هزینه‌های استهلاک';
																|it = 'Voce di uscita per la quale vengono rilevate le spese di ammortamento';
																|pl = 'Rodzaj kosztu, według którego odzwierciedlane są rozchody amortyzacyjne';
																|tr = 'Amortisman giderinin yansıtıldığı gider kalemi'");
			
		EndIf;
		
	EndIf;
	
	If StructureOfChangedProps.Property("RecordInLocalAccounting") 
		Or StructureOfChangedProps.Property("RecordInManAccounting") 
		Or StructureOfChangedProps.Property("AccountingProcedureAC") 
		Or StructureOfChangedProps.Property("AccountingProcedureTA") 
		Or StructureOfChangedProps.Property("AccountingProcedureMA") 
		Or StructureOfChangedProps.Property("ExpenseItemManagementAccounting") 
		Or StructureOfChangedProps.Property("ExpensesDimensionManagementAccounting") 
		Or StructureOfChangedProps.Property("MethodForReflectingMaExpenses") 
		Or StructureOfChangedProps.Property("BusinessUnitManagementAccounting") 
		Or StructureOfChangedProps.Property("LineOfBusinessManagementAccounting") 
		Or StructureOfChangedProps.Property("BusinessUnitAndLineOfBusinessMatchAccountingDataManagementAccounting") 
		Or UpdateAll Then
		
		If FAAcceptanceParameters.ExpenseItemManagementAccountingRequired_ 
			Or ValueIsFilled(Object.ExpenseItemManagementAccounting) Then
			
			Items.MethodForReflectingMaExpenses.InputHint = "";
			Items.ExpenseItemManagementAccounting.InputHint = "";
			Items.ExpensesDimensionManagementAccounting.InputHint = "";
			Items.BusinessUnitManagementAccounting.InputHint = "";
			Items.LineOfBusinessManagementAccounting.InputHint = "";
			
		ElsIf Not FAAcceptanceParameters.ExpenseItemManagementAccountingRequired_ Then

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

	#EndRegion
	
	FixedAssetsInitialRecognitionClientServerLocalization.ConfigureDependentFormElements(
		Form, 
		AuxiliaryAttributes,
		StructureOfChangedProps, 
		ItemDetailsParameters);
	
EndProcedure

&AtServer
Procedure ConfigureDependentFormElementsOnServer(ChangedBankingDetails = "")

	StructureOfChangedProps = New Structure(ChangedBankingDetails);
	
	UpdateAll = StructureOfChangedProps.Count() = 0;
	
	DateOfParameters = EndOfMonth(?(Object.Date <> '000101010000', Object.Date, CurrentSessionDate()));
	
	If UpdateAll Then
		
		Items.DecorationSetTAAccountingParameter.Visible = False;
		Items.DecorationBonusDepreciationPicture.Visible = False;
		Items.DecorationBonusDepreciationInscription.Visible = False;
		Items.LineOfBusinessTaxAccounting.Visible = False;
		Items.LineOfBusinessBonusDepreciation.Visible = False;
		
	EndIf;

	If StructureOfChangedProps.Property("Organization") 
		Or UpdateAll Then
		
		NonCurrentAssetsInternal.SetStructureProperty(
			"ComplCurrency",
			SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Object.Organization),
			FormServiceParameters);
		
		NonCurrentAssetsInternal.SetStructureProperty(
			"ThereAreRelatedCompanies",
			Catalogs.Companies.OrganizationIsInterconnectedWithOtherOrganizations(Object.Organization),
			FormServiceParameters);
			
	EndIf;

	If StructureOfChangedProps.Property("Organization") 
		Or StructureOfChangedProps.Property("Date")
		Or UpdateAll Then
		
		NonCurrentAssets.SetParametersOfFunctionalOptionsOfObjectForm(ThisObject, Object.Organization, Object.Date);
		
		NonCurrentAssetsInternal.SetStructureProperty(
			"PresentationOfDetails",
			Documents.FixedAssetsInitialRecognition2_4.PresentationOfDetails(Object.Organization, Object.Date),
			FormServiceParameters);
		
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

	EndIf;
	
	If StructureOfChangedProps.Property("Date") 
		Or UpdateAll Then
		
		NonCurrentAssetsInternal.SetStructureProperty(
			"ThereIsCostAccounting",
			CalculationOfCostCached.GenerateRegisteredRecordsOnCostRegisters(DateOfParameters),
			FormServiceParameters);
		
		NonCurrentAssetsInternal.SetStructureProperty(
			"UseLocal",
			LocalAccntingServer.ReglRecordsAreMaintained(DateOfParameters),
			FormServiceParameters);
		
	EndIf;
	
	If StructureOfChangedProps.Property("Organization") 
		Or StructureOfChangedProps.Property("Date") 
		Or StructureOfChangedProps.Property("FA") 
		Or StructureOfChangedProps.Property("FixedAsset") 
		Or StructureOfChangedProps.Property("BusinessOperation") 
		Or StructureOfChangedProps.Property("Contract") 
		Or UpdateAll Then
		
		FillInContractInTablePart();
		
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
	
	If StructureOfChangedProps.Property("FA") 
		Or StructureOfChangedProps.Property("FixedAsset") 
		Or StructureOfChangedProps.Property("AccountingProcedureAC") 
		Or StructureOfChangedProps.Property("AccountingProcedureTA") 
		Or StructureOfChangedProps.Property("AccountingProcedureMA") 
		Or UpdateAll Then
		
		NonCurrentAssetsInternal.SetStructureProperty(
			"ThereAreGroupFA",
			ThereAreGroupFA(),
			FormServiceParameters);
		
		If FormServiceParameters.ThereAreGroupFA Then
			
			ToolTipText =
				NStr("vi = 'Đối với TSCĐ nhóm, khi bật hộp kiểm, khấu hao được phản ánh vào chi phí theo bộ phận và lĩnh vực hoạt động tương ứng với nơi hạch toán TSCĐ đang sử dụng.
					 |Nếu TSCĐ đang sử dụng được hạch toán ở các bộ phận khác nhau hoặc theo các lĩnh vực hoạt động khác nhau, thì số khấu hao sẽ được phân bổ theo tỷ lệ giá trị của các vật tư này.';
					 |ru = 'Для групповых ОС при включенном флаге, амортизация отражается в расходах по подразделению и направлению деятельности соответствующему тому, где учитываются ТМЦ в эксплуатации.
					 |Если ТМЦ в эксплуатации  учитываются в разных подразделениях или по разным направлениям деятельности, то сумма амортизации будет распределена пропорционально стоимости этих ТМЦ.';
					 |en = 'For group fixed assets, when the checkbox is selected, depreciation is recorded in expenses by business unit and line of business corresponding to the one where inventory in operation is recorded.
					 |If inventory in operation is recorded in different business units or by different lines of business, the depreciation amount will be allocated in proportion to the cost of this inventory.'; fa = 'For group fixed assets, when the checkbox is selected, depreciation is recorded in expenses by business unit and line of business corresponding to the one where inventory in operation is recorded.
					 |If inventory in operation is recorded in different business units or by different lines of business, the depreciation amount will be allocated in proportion to the cost of this inventory.';
					 |it = 'For group fixed assets, when the checkbox is selected, depreciation is recorded in expenses by business unit and line of business corresponding to the one where inventory in operation is recorded.
					 |If inventory in operation is recorded in different business units or by different lines of business, the depreciation amount will be allocated in proportion to the cost of this inventory.';
					 |pl = 'For group fixed assets, when the checkbox is selected, depreciation is recorded in expenses by business unit and line of business corresponding to the one where inventory in operation is recorded.
					 |If inventory in operation is recorded in different business units or by different lines of business, the depreciation amount will be allocated in proportion to the cost of this inventory.';
					 |tr = 'Sabit kıymet grupları için, bayrak etkinleştirildiğinde amortisman, kullanımdaki stokların muhasebeleştirildiği bölüm ve iş koluna ait giderlerde yansıtılır.
					 | Kullanımdaki stoklar farklı bölümlerde veya farklı iş kollarında muhasebeleştiriliyorsa, amortisman tutarı bu stokların maliyetiyle orantılı olarak dağıtılır.'");
					 
			If Object.AccountingProcedureAC = Enums.FARepaymentProcedure.DepreciationAccrual
				Or Object.AccountingProcedureAC = Enums.FARepaymentProcedure.AccrueDepreciationOnRecognition
				Or Object.AccountingProcedureAC = Enums.FARepaymentProcedure.DepreciationIsAccrued
				Or Not ValueIsFilled(Object.AccountingProcedureAC) Then
					
				Items.BusinessUnitAndLineOfBusinessMatchAccountingDataBookkeeping.ToolTip = ToolTipText;
				Items.BusinessUnitAndLineOfBusinessMatchAccountingDataBookkeeping.ToolTipRepresentation = ToolTipRepresentation.Button;
			EndIf;
			
			If Object.AccountingProcedureTA = Enums.ProcedureOfIncludingFixedAssetCostInExpensesTA.DepreciationAccrual
				Or Object.AccountingProcedureTA = Enums.ProcedureOfIncludingFixedAssetCostInExpensesTA.DepreciationIsAccrued
				Or Not ValueIsFilled(Object.AccountingProcedureTA) Then
					
				Items.BusinessUnitAndLineOfBusinessMatchAccountingDataTaxAccounting.ToolTip = ToolTipText;
				Items.BusinessUnitAndLineOfBusinessMatchAccountingDataTaxAccounting.ToolTipRepresentation = ToolTipRepresentation.Button;
			EndIf;
			
			If Object.AccountingProcedureMA = Enums.FixedAssetValueRegistrationProcedure.AccrueDepreciationOrAmortization
				Or Object.AccountingProcedureMA = Enums.FixedAssetValueRegistrationProcedure.AccrueDepreciationOnRecognition
				Or Object.AccountingProcedureMA = Enums.FixedAssetValueRegistrationProcedure.DepreciationIsAccrued
				Or Not ValueIsFilled(Object.AccountingProcedureMA) Then
					
				Items.BusinessUnitAndLineOfBusinessMatchAccountingDataManagementAccounting.ToolTip = ToolTipText;
				Items.BusinessUnitAndLineOfBusinessMatchAccountingDataManagementAccounting.ToolTipRepresentation = ToolTipRepresentation.Button;
			EndIf;
			
		Else
			
			Items.BusinessUnitAndLineOfBusinessMatchAccountingDataBookkeeping.ToolTipRepresentation = ToolTipRepresentation.None;

		EndIf;
		
	EndIf;
	
	FixedAssetsInitialRecognitionLocalization.ConfigureDependentFormElements(ThisObject, StructureOfChangedProps);
	
	ConfigureDependentFormElementsOnClientOnServer(ThisObject, ChangedBankingDetails);
	
EndProcedure

&AtClient
Function RequiresServerCallToConfigureFormElements(StructureOfChangedProps)

	If StructureOfChangedProps.Count() = 0
		Or StructureOfChangedProps.Property("Date") 
		Or StructureOfChangedProps.Property("Organization") 
		Or StructureOfChangedProps.Property("RecordInLocalAccounting")
		Or StructureOfChangedProps.Property("RecordInManAccounting") 
		Or StructureOfChangedProps.Property("FA") 
		Or StructureOfChangedProps.Property("FixedAsset") 
		Or StructureOfChangedProps.Property("Contract") Then
			
		Return True;
	EndIf; 
	
	Return FixedAssetsInitialRecognitionClientLocalization.RequiresServerCallToConfigureFormElements(Object, StructureOfChangedProps);

EndFunction

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
		
		#Region PageGeneral
		
		If AttributeParameters.AttributeName = "ConstructionObject" Then
			If Action = "Clear" Then
				Object[AttributeParameters.AttributeName] = Undefined;
				ChangedBankingDetails.Add(AttributeParameters.AttributeName);
			EndIf; 
		EndIf;
		
		If AttributeParameters.AttributeName = "SeparateVATAccountingOption"
			And Action = "Fill" Then
			Object[AttributeParameters.AttributeName] = PredefinedValue("Enum.SeparateVATAccountingOptions.FromDocument");
			ChangedBankingDetails.Add(AttributeParameters.AttributeName);
		EndIf;
		
		If AttributeParameters.AttributeName = "VATTaxation"
			And Action = "Fill" Then
			Object[AttributeParameters.AttributeName] = PredefinedValue("Enum.VATTaxationTypes.SaleIsSubjectToVAT");
			ChangedBankingDetails.Add(AttributeParameters.AttributeName);
		EndIf;
		
		#EndRegion
		
		#Region TheAccountingPage
		
		If AttributeParameters.AttributeName = "AccountingProcedureAC"
			And Action = "Fill" Then
			Object[AttributeParameters.AttributeName] = PredefinedValue("Enum.FARepaymentProcedure.DepreciationAccrual");
			ChangedBankingDetails.Add(AttributeParameters.AttributeName);
		EndIf;
		
		If AttributeParameters.AttributeName = "DepreciationAccrualAccounting" Then
			Object[AttributeParameters.AttributeName] = ?(Action = "Fill", True, False);
			ChangedBankingDetails.Add(AttributeParameters.AttributeName);
		EndIf;
		
		If AttributeParameters.AttributeName = "DepreciationMethodAccounting"
			And Action = "Fill" Then
			Object[AttributeParameters.AttributeName] = PredefinedValue("Enum.AccrualMethodOfFixedAssetsDepreciation.Linear");
			ChangedBankingDetails.Add(AttributeParameters.AttributeName);
		EndIf;
		
		//
		If AttributeParameters.AttributeName = "AccountingProcedureMA"
			And Action = "Fill" Then
			Object[AttributeParameters.AttributeName] = PredefinedValue("Enum.FixedAssetValueRegistrationProcedure.AccrueDepreciationOrAmortization");
			ChangedBankingDetails.Add(AttributeParameters.AttributeName);
		EndIf;
		
		If AttributeParameters.AttributeName = "DepreciationAccrualManagementAccounting" Then
			Object[AttributeParameters.AttributeName] = ?(Action = "Fill", True, False);
			ChangedBankingDetails.Add(AttributeParameters.AttributeName);
		EndIf;
		
		If AttributeParameters.AttributeName = "DepreciationAccrualMethodManagementAccounting"
			And Action = "Fill" Then
			Object[AttributeParameters.AttributeName] = PredefinedValue("Enum.AccrualMethodOfFixedAssetsDepreciation.Linear");
			ChangedBankingDetails.Add(AttributeParameters.AttributeName);
		EndIf;
		
		#EndRegion
		
		#Region PageExpenseRecord
		
		If AttributeParameters.AttributeName = "ExpenseItemAccounting" Then
			If Action = "Clear" Then
				Object.ExpenseItemAccounting = Undefined;
				Object.ExpensesDimensionAccounting = Undefined;
				ChangedBankingDetails.Add("ExpenseItemAccounting");
				ChangedBankingDetails.Add("ExpensesDimensionAccounting");
			EndIf;
		EndIf;
	
		If AttributeParameters.AttributeName = "ExpenseItemManagementAccounting" Then
			If Action = "Clear" Then
				Object.ExpenseItemManagementAccounting = Undefined;
				Object.ExpensesDimensionManagementAccounting = Undefined;
				ChangedBankingDetails.Add("ExpenseItemManagementAccounting");
				ChangedBankingDetails.Add("ExpensesDimensionManagementAccounting");
			EndIf;
		EndIf;
		
		#EndRegion
		
		FixedAssetsInitialRecognitionClientServerLocalization.FillInDetailsDependingOnProperties(
			Form, AttributeParameters, Action, ChangedBankingDetails);
		
	EndDo; 
	
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
		Items.PictureInformation.Visible = True;
		Items.Information.Visible = True;
	Else
		Items.PictureInformation.Visible = False;
		Items.Information.Visible = False;
	EndIf; 
	
EndProcedure

&AtServer
Function PreliminaryCostDiffersFromActual()

	If Not ValueIsFilled(Object.Ref)
		Or Object.PartialCommissioning Then
		Return False;
	EndIf;
	
	QueryText = 
	"SELECT
	|	FATable.FixedAsset AS FixedAsset,
	|	FATable.CostInAccounting AS CostInAccounting,
	|	FATable.CostInManagementAccounting AS CostInManagementAccounting
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
	|			AND &AccountingProcedureAC <> VALUE(Enum.FARepaymentProcedure.DoNotTakeIntoAccountIncludeInExpenses)
	|			AND MAX(FATable.CostInAccounting) <> SUM(FACost.LocalCost + FACost.CostTargetFinancing)
	|		OR &RecordInManAccounting
	|			AND &AccountingProcedureMA <> VALUE(Enum.FixedAssetValueRegistrationProcedure.DoNotTakeIntoAccountIncludeInExpenses)
	|			AND MAX(FATable.CostInManagementAccounting) <> SUM(FACost.Cost))";
	
	Query = New Query(QueryText);
	Query.SetParameter("Ref", Object.Ref);
	Query.SetParameter("FATable", Object.FA.Unload());
	Query.SetParameter("PostInAccounting", Object.PostInAccounting);
	Query.SetParameter("AccountingProcedureAC", Object.AccountingProcedureAC);
	Query.SetParameter("AccountingProcedureMA", Object.AccountingProcedureMA);
	Query.SetParameter("RecordInManAccounting", Object.RecordInManAccounting);
	
	Result = Query.Execute();
	Result = Not Result.IsEmpty();
		
	Return Result;

EndFunction

&AtClient
Procedure FillInValuesOfFADetailsBeforeChange()

	AttributesValuesBeforeChange = New Structure;
	AttributesValuesBeforeChange.Insert("CostInManagementAccounting", 0);
	AttributesValuesBeforeChange.Insert("CostInAccounting", 0);
	AttributesValuesBeforeChange.Insert("CostInTaxAccounting", 0);
	
	CurrentData = Items.FA.CurrentData;
	If CurrentData <> Undefined Then
		FillPropertyValues(AttributesValuesBeforeChange, CurrentData);
	EndIf;
	
	FAAttributeValuesBeforeChange = New FixedStructure(AttributesValuesBeforeChange);

EndProcedure

&AtClient
Procedure SelectingBaseDataTypeEnd(SelectedElement, ParametersList) Export
	
	If SelectedElement = Undefined Then
		Return
	EndIf;
		
	NameOfFormToOpen_ = "";
	
	If SelectedElement.Value = Type("DocumentRef.SigningOfLeaseContract") Then
		NameOfFormToOpen_ = "Document.SigningOfLeaseContract.ChoiceForm";
	ElsIf SelectedElement.Value = Type("DocumentRef.LeaseTermAdjustment") Then
		NameOfFormToOpen_ = "Document.LeaseTermAdjustment.ChoiceForm";
	EndIf;
	
	ListFilter = New Structure;
	ListFilter.Insert("Posted", True);
	If ValueIsFilled(Object.Organization) Then
		ListFilter.Insert("Organization", Object.Organization);
	EndIf;
	
	CallbackDescription = New CallbackDescription("GeneratedDocumentOnChangeCompletion", ThisObject);
	
	FormParameters = New Structure;
	FormParameters.Insert("Filter", ListFilter);
	OpenForm(NameOfFormToOpen_, FormParameters,,,,, CallbackDescription);
	
EndProcedure

&AtClient
Procedure GeneratedDocumentOnChangeCompletion(ClosingResult, AdditionalParameters) Export

	If ValueIsFilled(ClosingResult) Then
		Object.DocumentBasis = ClosingResult;
		Object.GeneratedDocument = True;
	Else
		Object.GeneratedDocument = False;
	EndIf;
	
	If ValueIsFilled(Object.DocumentBasis) Then
		QueryText = NStr("vi = 'Điền chứng từ theo dữ liệu chứng từ cơ sở?';
						|ru = 'Заполнить документ по данным документа-основания?';
						|en = 'Fill in the document by base document data?'; fa = 'Fill in the document by base document data?';
						|it = 'Compilare il documento in base ai dati del documento principale?';
						|pl = 'Wypełnić dokument wg danych dokumentu-podstawy?';
						|tr = 'Belgeyi belge bazındaki verilere göre mi dolduruyorsunuz?'");
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
	
	If TypeOf(Object.DocumentBasis) = Type("DocumentRef.SigningOfLeaseContract") Then
		Documents.FixedAssetsInitialRecognition2_4.FillInBasedOnConclusionOfLeaseAgreement(Object, Object.DocumentBasis);
	ElsIf TypeOf(Object.DocumentBasis) = Type("DocumentRef.LeaseTermAdjustment") Then
		Documents.FixedAssetsInitialRecognition2_4.FillInOnBasisOfRentalTermsADJUSTMENTChanges(Object, Object.DocumentBasis);
	ElsIf TypeOf(Object.DocumentBasis) = Type("DocumentRef.FixedAssetsPhysicalCount") Then
		Documents.FixedAssetsInitialRecognition2_4.FillInBasedOnInventory(Object, True);
	EndIf;
	
	ConfigureDependentFormElementsOnServer("Organization,FixedAsset,RecordInLocalAccounting,RecordInManAccounting,PostInAccounting,RecordInTA");
	
EndProcedure

&AtServer
Procedure FillInContractInTablePart()
	
	If Object.BusinessOperation <> Enums.BusinessTransactions.RecognitionOfLeaseItems Then
		Return;
	EndIf;
	
	ListOfFA = New Array;
	For Each RowData In Object.FA Do
		If ValueIsFilled(RowData.FixedAsset) Then
			ListOfFA.Add(RowData.FixedAsset);
		EndIf;
		RowData.Contract = Undefined;
		RowData.TheSubjectOfTheLeaseIsTakenIntoAccountInTheBudget = False;
	EndDo;
	
	If ValueIsFilled(Object.Contract) Then
		RentalItemsAreTakenIntoAccountIn = 
			(Common.ObjectAttributeValue(Object.Contract, "AssetHolder") = Enums.LeasedAssetHolder.Leaseholder);
	ElsIf ListOfFA.Count() <> 0 Then	
		RentalItemsAreTakenIntoAccountIn = False;
	Else
		RentalItemsAreTakenIntoAccountIn = True;
	EndIf;
	 
	QueryText = 
	"SELECT
	|	LeasedAsset.FixedAsset,
	|	LeasedAsset.Contract.AssetHolder AS AssetHolder,
	|	LeasedAsset.Contract
	|FROM
	|	InformationRegister.LeasedAsset.SliceLast(
	|		&Date, 
	|		FixedAsset IN (&ListOfFA)) AS LeasedAsset";
	
	Query = New Query(QueryText);
	Query.SetParameter("Date", Object.Date);
	Query.SetParameter("Organization", Object.Organization);
	Query.SetParameter("ListOfFA", ListOfFA);
	
	Result = Query.Execute();
	Selection = Result.Select();
	
	ComplianceWithContracts = New Map();
	While Selection.Next() Do
		
		ContractParameters = New Structure;
		ContractParameters.Insert("Contract", Selection.Contract);
		ContractParameters.Insert(
			"TheSubjectOfTheLeaseIsTakenIntoAccountInTheBudget", 
			Selection.AssetHolder = Enums.LeasedAssetHolder.Leaseholder);
		
		ComplianceWithContracts.Insert(Selection.FixedAsset, ContractParameters);
		
		If ContractParameters.TheSubjectOfTheLeaseIsTakenIntoAccountInTheBudget Then
			RentalItemsAreTakenIntoAccountIn = True;
		EndIf;
		
	EndDo;
	
	For Each RowData In Object.FA Do
		ContractParameters = ComplianceWithContracts.Get(RowData.FixedAsset);
		If ContractParameters <> Undefined Then
			RowData.Contract = ContractParameters.Contract;
			RowData.TheSubjectOfTheLeaseIsTakenIntoAccountInTheBudget = ContractParameters.TheSubjectOfTheLeaseIsTakenIntoAccountInTheBudget;
		EndIf;
	EndDo;
	
	NonCurrentAssetsInternal.SetStructureProperty(
		"RentalItemsAreTakenIntoAccountIn",
		RentalItemsAreTakenIntoAccountIn, 
		FormServiceParameters);
		
EndProcedure

&AtServer
Procedure OrderOfAccountingForBUWhenChangingOnServer()

	ChangedBankingDetails = NonCurrentAssetsClientServer.WhenChangingAccountingOrderOfBU_OS(Object, FormServiceParameters, True);
	
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
	
	ChangedBankingDetails = NonCurrentAssetsClientServer.WhenChangingOrderOfAccountingUU_OS(Object, FormServiceParameters, True);
							
	ChangedBankingDetails = "AccountingProcedureMA" + ?(Not IsBlankString(ChangedBankingDetails), "," + ChangedBankingDetails, "");
	
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
Function ThereAreGroupFA()

	If Object.FA.Count() = 0 Then
		Return False;
	EndIf;
	
	QueryText = 
	"SELECT TOP 1
	|	TRUE
	|FROM
	|	Catalog.Assets AS ListOfFA
	|WHERE
	|	ListOfFA.Ref IN (&ListOfFA)
	|	AND ListOfFA.OSType = VALUE(Enum.FATypes.GroupFA)
	|";
	
	Query = New Query(QueryText);
	Query.SetParameter("ListOfFA", Object.FA.Unload(, "FixedAsset").UnloadColumn("FixedAsset"));
	
	SetPrivilegedMode(True);
	Result = Query.Execute();
	SetPrivilegedMode(False);
	
	Return Not Result.IsEmpty();
	 
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
