
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetConditionalAppearance();
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	// DynamicListsSettings
	InitiateDynamicListSettings();
	ListOfDocumentsAutoUpdateMode = True;
	// End DynamicListsSettings
	
	TMCommonUse.CustomizePeripherals(ThisForm);
	
	If Not Parameters.Property("FormAssignmentKey")
		Or IsBlankString(Parameters.FormAssignmentKey) Then
		PurposeUseKey = DataProcessors.DocumentJournalInventoryInOperation.DefaultFormAssignmentKey();
		SettingsKey = "";
	Else
		PurposeUseKey = Parameters.FormAssignmentKey;
		SettingsKey = Parameters.FormAssignmentKey;
	EndIf;
	
	If Parameters.Property("ListFormSelections") Then
		FormsOpenedByHyperlink = True;
		FilterDocumentTypes = Parameters.ListFormSelections.FilterDocumentTypes;
		FilterBusinessTransactions = Parameters.ListFormSelections.FilterBusinessTransactions;
	Else
		RestoreSettings();
	EndIf;
	
	// Document verificationreferences
	QueryText = List.QueryText;
	DocumentVerificationServer.ModifyDynamicDocumentLogListRequest(QueryText, "DocumentsRegistryOverridable");
	
	ListProperties = Common.DynamicListPropertiesStructure();
	ListProperties.QueryText = QueryText;
	Common.SetDynamicListProperties(Items.List, ListProperties);
	// End Document verificationreferences
	
	
	AdditionalParameters = New Structure("LocationOfLocalValidationData", Items.ListOfReglGroupVerification);
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing, AdditionalParameters);
	
	VTBusinessTransactionsAndDocumentTypes = DataProcessors.DocumentJournalInventoryInOperation.InitializeBusinessTransactionsAndDocuments(
		BusinessTransactionsAndDocuments.Unload(),
		FilterBusinessTransactions,
		FilterDocumentTypes,
		SettingsKey);
	
	BusinessTransactionsAndDocuments.Load(VTBusinessTransactionsAndDocumentTypes);
	
	SetDynamicListSelections_();
	
	CustomizeFormElementsWhenCreating();
	
	TMCommonUse.ReplaceLinkFieldWithExpressByDocumentTypeConstruct(Items.List, BusinessTransactionsAndDocuments);
	
	TMCommonUse.FormInscriptionSelection(
		HelpTextFilter, 
		BusinessTransactionsAndDocuments, 
		FilterDocumentTypes, 
		FilterBusinessTransactions);
	
	DocumentTypesUsed = VTBusinessTransactionsAndDocumentTypes.UnloadColumn("DocumentType");
	
	// StandardSubsystems.AttachableCommands
	PlacementParameters = AttachableCommands.PlacementParameters();
	PlacementParameters.Sources = New TypeDescription(DocumentTypesUsed);
	PlacementParameters.CommandBar = Items.ListCommandBar;
	PlacementParameters.GroupsPrefix = "List";
	AttachableCommands.OnCreateAtServer(ThisObject, PlacementParameters);
	
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	StartUpdatingDataInBackground();

	EquipmentManagerClient.StartConnectingDevicesWhenYouOpenForm(Undefined, ThisForm, "BarcodeScanner");
	
	
	// DynamicListsSettings
	SetParametersForUpdatingDocumentLists(False, 0);
	// End DynamicListsSettings
	
EndProcedure

&AtClient
Procedure OnClose(Exit)
	
	If Not Exit Then
		ShouldSaveSettings();
	EndIf;
	
	EquipmentManagerClient.StartDisablingHardwareWhenClosingForm(Undefined, ThisForm);
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	// Peripherals
	If Source = "Peripherals" And IsInputAvailable() Then
		If EventName = "ScanData" And EquipmentManagerTMClient.ThereIsRawEvent() Then
			ProcessBarcodes(EquipmentManagerTMClient.ConvertDataFromScannerToStructure(Parameter));
		EndIf;
	EndIf;
	// End Peripherals
	
	DataNeedsToBeUpdated = False;
	If StrFind(EventName, "Record_") <> 0 Then
	
		For Each LineDocument In BusinessTransactionsAndDocuments Do
			EventNameDocumentEntry = StrReplace(LineDocument.FullDocumentName, "Document.", "Record_");
			If EventNameDocumentEntry = EventName Then
				DataNeedsToBeUpdated = True;
				Break;
			EndIf; 
		EndDo; 
		
	EndIf; 
	
	
	If EventName = "Write_Decomissioning" Then
		DataNeedsToBeUpdated = True;
	EndIf;
	
	If DataNeedsToBeUpdated Then
		UpdateDataWhenFormBecomesActive();
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure FilterOrganizationOnChange(Item)
	
	WhenSelectionChanges();
	
EndProcedure

&AtClient
Procedure FilterDepartmentOnChange(Item)
	
	FilterDivisionWhenChangedOnServer();
	
EndProcedure

&AtClient
Procedure HelpTextFilterURLProcessing(Item, FormattedStringURL, StandardProcessing)
	
	StandardProcessing = False;
	
	FormParameters = New Structure();
	FormParameters.Insert("AvailableBusinessTransactionsAndDocuments", PlaceBusinessTransactionsAndDocumentsInTemporaryStorage());
	
	FormParameters.Insert("SettingsKey", PurposeUseKey);
	FormParameters.Insert("FormKey", DefaultFormAssignmentKey());
	
	OpenForm("Catalog.BusinessTransactionsSettings.Form.FormOfFilterSetting",
	FormParameters,,,,,New CallbackDescription("EstablishSelectionsForBusinessTransactionsAndDocuments", ThisObject));
	
EndProcedure

&AtClient
Procedure ToRegisterURLProcessing(Item, FormattedStringURL, StandardProcessing)
	
	StandardProcessing = False;
	
	If FormattedStringURL = "#Decomissioning" Then
		OpenForm("Document.Decomissioning.Form.Workplace");
	EndIf;

EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersList

&AtClient
Procedure ListSelection(Item, RowSelected, Field, StandardProcessing)
	
	StandardProcessing = False;
	
	TMCommonUseClient.ChangeElement(Item);
	
	
EndProcedure

&AtClient
Procedure ListBeforeAddRow(Item, Cancel, Copy, Parent, Var_Group, Parameter)
	
	Cancel = True;
	If Items.ListGroupCreateGenerated.ChildItems.Count() <> 0 Then 
		If Copy Then
			TMCommonUseClient.CopyItem(Item);
		ElsIf FilterDocumentTypes.Count() = 1 And FilterBusinessTransactions.Count() = 1 Then 
			TeamStructure_ = New Structure("Name", Items.ListGroupCreateGenerated.ChildItems[0].Name);
			Attachable_CreateDocument(TeamStructure_);
		Else
			Attachable_CreateDocumentViaSelectionForm(Undefined);
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure ListBeforeRowChange(Item, Cancel)
	
	Cancel = True;
	TMCommonUseClient.ChangeElement(Item);
	
EndProcedure

&AtClient
Procedure ListBeforeDeleteRow(Item, Cancel)
	
	Cancel = True;
	
	CompletionHandler = New CallbackDescription("SetClearDeletionMarkCompletion", ThisObject);

	TMCommonUseClient.SetDeletionMark(Item, Title, CompletionHandler);
	
EndProcedure

&AtClient
Procedure ListOnActivateRow(Item)
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

&AtServer
Procedure ListOnUpdateUserSettingSetAtServer(Item, StandardProcessing)
	// DynamicListsSettings
	OperationsWithDocumentJournals.SetVisibilityOfDefaultUpdateSettingsGroup(ThisObject, "List");
	// End DynamicListsSettings
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

#Region List

&AtClient
Procedure ListSetDateInterval(Command)
	
	Notification = New CallbackDescription("SetDateIntervalCompletion", ThisObject);
	
	TMCommonUseClient.EditPeriod(ListInterval,, Notification);
	
EndProcedure

&AtClient
Procedure ListCopy(Command)
	
	TMCommonUseClient.CopyItem(Items.List);
	
EndProcedure

&AtClient
Procedure ListChange(Command)
	
	TMCommonUseClient.ChangeElement(Items.List);
	
EndProcedure

&AtClient
Procedure ListUndoPosting(Command)
	
	TMCommonUseClient.UndoPosting(Items.List, Title,
		OperationsWithDocumentJournalsClient.ParametersForUpdatingDocumentList(ThisObject, "List"));
	UpdateDataWhenFormBecomesActive();
	
EndProcedure

&AtClient
Procedure ListPost(Command)
	
	TMCommonUseClient.PostDocuments(Items.List, Title,
		OperationsWithDocumentJournalsClient.ParametersForUpdatingDocumentList(ThisObject, "List"));
	UpdateDataWhenFormBecomesActive();
	
EndProcedure

&AtClient
Procedure ListSetClearADeletionMark(Command)
	
	CompletionHandler = New CallbackDescription("SetClearDeletionMarkCompletion", ThisObject);

	TMCommonUseClient.SetDeletionMark(Items.List, Title, CompletionHandler,
		OperationsWithDocumentJournalsClient.ParametersForUpdatingDocumentList(ThisObject, "List"));
	
EndProcedure

#EndRegion

#Region AttachableCommands

&AtClient
Procedure Attachable_CreateDocument(Command)
	
	TMCommonUseClient.CreateDocumentUsingCommand(Command.Name, SelectionsForCreatingDocument());
	
EndProcedure

&AtClient
Procedure Attachable_CreateDocumentViaSelectionForm(Command)
	
	FormKey = DefaultFormAssignmentKey();
	AddressBusinessTransactionsAndDocuments = PlaceBusinessTransactionsAndDocumentsInTemporaryStorage();
	TMCommonUseClient.CreateDocumentViaSelectionForm(AddressBusinessTransactionsAndDocuments,
		FormKey, PurposeUseKey, SelectionsForCreatingDocument());
		
EndProcedure

// StandardSubsystems.AttachableCommands
&AtClient
Procedure Attachable_ExecuteCommand(Command)
	AttachableCommandsClient.ExecuteCommand(ThisObject, Command, CurrentList(ThisForm));
EndProcedure

&AtServer
Procedure Attachable_ExecuteCommandAtServer(Context, Result) Export
	AttachableCommands.ExecuteCommand(ThisObject, Context, CurrentList(ThisForm), Result);
EndProcedure

&AtClient
Procedure Attachable_UpdateCommands()
	AttachableCommandsClientServer.UpdateCommands(ThisObject, CurrentList(ThisForm));
EndProcedure
// End StandardSubsystems.AttachableCommands

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

#EndRegion

&AtClient
Procedure DocumentsListRefresh(Command)
	
	// DynamicListsSettings
	UpdateDocumentListDataWithTimeMeasurement("List");
	// End DynamicListsSettings
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure RestoreSettings()
	
	ListOfDocumentsAutoUpdateMode = True;
	
	Settings = Common.CommonSettingsStorageLoad("DataProcessor.DocumentJournalInventoryInOperation.Form.InventoryDocumentsInOperation", PurposeUseKey);
	
	If TypeOf(Settings) = Type("Structure") Then
	
		ListInterval = Settings.ListInterval;
		FilterOrganization = Settings.FilterOrganization;
		FilterDepartment = Settings.FilterDepartment;
		
		Settings.Property("FilterBusinessTransactions", FilterBusinessTransactions);
		Settings.Property("FilterDocumentTypes", FilterDocumentTypes);
		
		If Settings.Property("ListOfDocumentsAutoUpdateMode") Then
			ListOfDocumentsAutoUpdateMode = Settings.ListOfDocumentsAutoUpdateMode;
		EndIf;
		
	EndIf;
	
EndProcedure

&AtServer
Procedure ShouldSaveSettings()
	
	If FormsOpenedByHyperlink Then
		Return;
	EndIf;
	
	AttributesToSaveNames =
		"ListInterval,
		|FilterOrganization,
		|FilterDepartment,
		|FilterBusinessTransactions,
		|FilterDocumentTypes,
		|ListOfDocumentsAutoUpdateMode";
	
	Settings = New Structure(AttributesToSaveNames);
	FillPropertyValues(Settings, ThisForm);
	
	Common.CommonSettingsStorageSave("DataProcessor.DocumentJournalInventoryInOperation.Form.InventoryDocumentsInOperation", PurposeUseKey, Settings);
	
EndProcedure

&AtServer
Procedure CustomizeFormElementsWhenCreating()
	
	If Parameters.Property("QuickFilterStructure") Then
		If Parameters.QuickFilterStructure.Property("FullDocumentName") Then
						
			Filter = New Structure();
			Filter.Insert("FullDocumentName", Parameters.QuickFilterStructure.FullDocumentName);
			
			FoundRows = BusinessTransactionsAndDocuments.FindRows(Filter);
			
			For Each FoundRow In FoundRows Do
				FoundRow.Filter = True;
			EndDo;
			
		EndIf;
	EndIf;
	
	ConfigureFormUsingSettingsForBusinessOperationsAndDocuments();
	
EndProcedure

&AtServer
Procedure ConfigureFormUsingSettingsForBusinessOperationsAndDocuments()
	
	WorkplaceData = TMCommonUse.WorkplaceData(
		BusinessTransactionsAndDocuments.Unload(), 
		DefaultFormAssignmentKey(), 
		NStr("vi = 'tất cả';
			|ru = 'все';
			|en = 'all'; fa = 'همه';
			|it = 'tutti';
			|pl = 'wszystkie';
			|tr = 'tümü'"));
	
	ConfigureDocumentManagementButtons();
	
EndProcedure

&AtServer
Procedure SetDynamicListSelections_()
	
	CommonClientServer.SetDynamicListFilterItem(
		List,
		"BusinessOperation",
		FilterBusinessTransactions,
		DataCompositionComparisonType.InList,
		,
		True);

	CommonClientServer.SetDynamicListFilterItem(
		List,
		"RefType",
		FilterDocumentTypes,
		DataCompositionComparisonType.InList,
		,
		True);
		
	CommonClientServer.SetDynamicListFilterItem(
		List,
		"Organization",
		FilterOrganization,
		DataCompositionComparisonType.Equal,
		,
		ValueIsFilled(FilterOrganization));
		
	CommonClientServer.SetDynamicListFilterItem(
		List,
		"Department",
		FilterDepartment,
		DataCompositionComparisonType.Equal,
		,
		ValueIsFilled(FilterDepartment));
		
	CommonClientServer.SetDynamicListFilterItem(
		List,
		"AdditionalRecord",
		False,
		DataCompositionComparisonType.Equal,
		,
		Not ValueIsFilled(FilterOrganization));
		
	List.Parameters.SetParameterValue("BeginOfPeriod", ListInterval.StartDate);
	
	List.Parameters.SetParameterValue("EndOfPeriod", 
		?(ValueIsFilled(ListInterval.EndDate),
			EndOfDay(ListInterval.EndDate),
			EndOfDay(Date(3999, 12, 31))));
			
	Items.ListSetDateInterval.Check = 
		ValueIsFilled(ListInterval.StartDate) Or ValueIsFilled(ListInterval.EndDate);
	
	// DynamicListsSettings
	OperationsWithDocumentJournals.SetVisibilityOfDefaultUpdateSettingsGroup(ThisObject, "List");
	// End DynamicListsSettings
	
EndProcedure

&AtServer
Procedure FilterDivisionWhenChangedOnServer()

	WhenSelectionChanges();

EndProcedure

&AtClientAtServerNoContext
Function DefaultFormAssignmentKey()
	
	Return "InventoryDocumentsInOperation";
	
EndFunction

&AtServer
Procedure WhenSelectionChanges()
	
	ShouldSaveSettings();
	SetDynamicListSelections_();
	
EndProcedure

&AtServer
Procedure ConfigureDocumentManagementButtons()
	
	ParametersStructure = TMCommonUse.StructureOfSettingsForDocumentManagementButtons();
	ParametersStructure.Form 												= ThisForm;
	ParametersStructure.NameOfCreateGroup                                    = "ListGroupCreateGenerated";
	ParametersStructure.GroupNameCreateContext                            = "ListGroupCreateGeneratedByContext";
	ParametersStructure.NameOfCopyButton                                = "ListCopy";
	ParametersStructure.NameOfCopyContextMenuButton                 = "CopyContextList";
	ParametersStructure.ChangeButtonName                                   = "ListChange";
	ParametersStructure.NameOfChangeContextMenuButton                    = "EditContextList";
	ParametersStructure.ButtonNamePost                                   = "ListPost";
	ParametersStructure.NameOfHoldContextMenuButton                    = "ListAndContext";
	ParametersStructure.NameOfCancelEventButton                           = "ListUndoPosting";
	ParametersStructure.NameOfCancelButtonIsContextMenu            = "ListOfCancellationsOfTheEventContext";
	ParametersStructure.NameOfMarkDeleteButton                  = "ListSetDeletionMark";
	ParametersStructure.ButtonNameMarkDeleteContextMenu   = "SetMarkDeleteContextList";
	
	TMCommonUse.ConfigureDocumentManagementButtons(ParametersStructure);
	
EndProcedure

&AtServer
Procedure SetConditionalAppearance()
	
	ConditionalAppearance.Items.Clear();
	
	StandardSubsystemsServer.SetDateFieldConditionalAppearance(ThisObject, "List.Date", "ListDate");
	
EndProcedure

&AtClient
Procedure EstablishSelectionsForBusinessTransactionsAndDocuments(ValueSelected, AdditionalParameters) Export
	
	If ValueSelected = Undefined Then
		Return;
	EndIf;
	
	If TypeOf(ValueSelected) = Type("String") Then
		StandardProcessing = False;
		
		AddressOfAvailableBusinessTransactionsAndDocuments = ValueSelected;
		
		SelectionOperationTypeSelectionProcessingServer(AddressOfAvailableBusinessTransactionsAndDocuments);
		
	EndIf;
	
EndProcedure

&AtServer
Procedure SelectionOperationTypeSelectionProcessingServer(AddressOfAvailableBusinessTransactionsAndDocuments)
	
	TableBusinessOperationsAndDocuments = GetFromTempStorage(AddressOfAvailableBusinessTransactionsAndDocuments);
	BusinessTransactionsAndDocuments.Load(TableBusinessOperationsAndDocuments);
	
	TMCommonUse.FillInSelectionsAccordingToTableOfBusinessTransactionsAndDocumentTypes(
		TableBusinessOperationsAndDocuments, FilterBusinessTransactions, FilterDocumentTypes);
	
	TMCommonUse.ReplaceLinkFieldWithExpressByDocumentTypeConstruct(
		Items.List, BusinessTransactionsAndDocuments);
	
	ConfigureFormUsingSettingsForBusinessOperationsAndDocuments();
	
	WhenSelectionChanges();
	
	TMCommonUse.FormInscriptionSelection(
		HelpTextFilter, BusinessTransactionsAndDocuments, FilterDocumentTypes, FilterBusinessTransactions);
	
EndProcedure

&AtServer
Function PlaceBusinessTransactionsAndDocumentsInTemporaryStorage()
	Return PutToTempStorage(BusinessTransactionsAndDocuments.Unload(), UUID);
EndFunction

&AtClient
Procedure SetDateIntervalCompletion(ValueSelected, AdditionalParameters) Export
	
	If ValueSelected = Undefined Then
		Return;
	EndIf;
	
	WhenSelectionChanges();
	
EndProcedure

&AtClientAtServerNoContext
Function CurrentList(Form)

	Return Form.Items.List;

EndFunction

&AtClient
Procedure UpdateDataWhenFormBecomesActive()

	AttachIdleHandler("Attachable_UpdateDataWhenFormBecomesActive", 0.8, True);

EndProcedure

&AtClient
Procedure Attachable_UpdateDataWhenFormBecomesActive()
	
	If IsInputAvailable() Then
		
		// DynamicListsSettings
		UpdateListOfDocumentsEventNotificationProcessing("List");
		// End DynamicListsSettings
		
		StartUpdatingDataInBackground();
	Else
		UpdateDataWhenFormBecomesActive();
	EndIf;

EndProcedure

&AtClient
Function SelectionsForCreatingDocument()
	
	StructureSelections = New Structure;
	
	If ValueIsFilled(FilterOrganization) Then
		StructureSelections.Insert("Organization", FilterOrganization);
	EndIf;
	If ValueIsFilled(FilterDepartment) Then
		StructureSelections.Insert("Department", FilterDepartment);
	EndIf;
	
	Return StructureSelections;
	
EndFunction

&AtClient
Procedure SetClearDeletionMarkCompletion(QuestionResult, AdditionalParameters) Export

	If QuestionResult = DialogReturnCode.Yes Then
		TMCommonUseClient.NotifyAboutEntryOfDocumentInJournal();
		UpdateDataWhenFormBecomesActive();	
	EndIf;
	
EndProcedure

#Region BarcodesAndTradeEquipment

&AtServer
Function BarcodeDataOfPrintedForm(Barcode, ListName = "")
	
	ThereIsMainTableOfList = OperationsWithDocumentJournals.ThereIsMainTableOfList(ThisObject, ListName);
	
	BarcodeData = TMCommonUse.BarcodeDataOfPrintedForm(Barcode, BusinessTransactionsAndDocuments.Unload(), ThereIsMainTableOfList);	
	
	Return BarcodeData;
	
EndFunction

&AtClient
Procedure ProcessBarcodes(Data)
	
	Status(NStr("vi = 'Đang tìm kiếm chứng từ theo mã vạch...';
				|ru = 'Выполняется поиск документа по штрихкоду...';
				|en = 'Searching for the document by barcode...'; fa = 'Searching for the document by barcode...';
				|it = 'Viene effettuata la ricerca del documento per codice a barre...';
				|pl = 'Wyszukiwanie dokumentu według kodu kreskowego...';
				|tr = 'Belge barkoda göre aranıyor...'"));
	BarcodeData = BarcodeDataOfPrintedForm(Data.Barcode, "List");
	TMCommonUseClient.ProcessBarcodes(Data.Barcode, BarcodeData, ThisForm, "List");
	
EndProcedure

#EndRegion

#Region HyperlinkToDesign

&AtClient
Procedure StartUpdatingDataInBackground()
	
	TimeConsumingOperation = StartUpdatingDataInBackgroundOnServer();
	
	CallbackOnCompletion = New CallbackDescription("UpdatingDataInBackgroundEnds", ThisObject);
	
	IdleParameters = TimeConsumingOperationsClient.IdleParameters(ThisObject);
	IdleParameters.OutputIdleWindow = False;
	
	TimeConsumingOperationsClient.WaitCompletion(TimeConsumingOperation, CallbackOnCompletion, IdleParameters);
	
EndProcedure

&AtServer
Function StartUpdatingDataInBackgroundOnServer()

	FunctionParameters = New Structure;
	FunctionParameters.Insert("Organization", FilterOrganization);
	FunctionParameters.Insert("Department", FilterDepartment);

	ExecutionParameters = TimeConsumingOperations.FunctionExecutionParameters(UUID);
	
	TimeConsumingOperation = TimeConsumingOperations.ExecuteFunction(
		ExecutionParameters, "DataProcessors.DocumentJournalInventoryInOperation.WorkplaceData", FunctionParameters);
	
	If TimeConsumingOperation.Status = "Running" Then
		TextIsUpdatingData = NStr("vi = 'Cần lập: <đang cập nhật dữ liệu>';
									|ru = 'К оформлению: <идет обновление данных>';
									|en = 'To register: <updating data>'; fa = 'To register: <updating data>';
									|it = 'Da formalizzare: <dati in fase di aggiornamento>';
									|pl = 'Do rejestracji: <odbywa się aktualizacja danych>';
									|tr = 'Düzenlenecek: <veri güncellemesi devam ediyor>'");
		ToRegister = New FormattedString(TextIsUpdatingData);
	EndIf;

	Return TimeConsumingOperation;
	
EndFunction

&AtClient
Procedure UpdatingDataInBackgroundEnds(Result, AdditionalParameters) Export

	If Result = Undefined Then
		Return;
	EndIf;
	
	If Result.Status = "Error" Then
		Raise Result.BriefErrorDescription;
	EndIf;
			
	UpdatingDataInBackgroundOrOnServer(Result.ResultAddress);
	
EndProcedure 

&AtServer
Procedure UpdatingDataInBackgroundOrOnServer(Val ResultAddress)
	
	Result = GetFromTempStorage(ResultAddress);

	If ValueIsFilled(Result) Then
		ToRegister = New FormattedString(Result);
		Items.ToRegister.Visible = True;
	Else
		Items.ToRegister.Visible = False;
	EndIf;
	
EndProcedure

#EndRegion

#Region DynamicListsSettings

&AtServer
Procedure InitiateDynamicListSettings()
	
	DocumentListParameters = New Array;
	
	ListParameterStructure = OperationsWithDocumentJournals.StructureOfFormationOfGroupOfUserSettingsForDynamicListOnForm();
	ListParameterStructure.ListName = "List";
	ListParameterStructure.PlacementGroupSettings = Items.DocumentListSettingsGroup;
	ListParameterStructure.AttributeNameAutoUpdateMode = "ListOfDocumentsAutoUpdateMode";
	ListParameterStructure.NameOfListUpdateCommands = Commands.DocumentsListRefresh.Name;
	DocumentListParameters.Add(ListParameterStructure);
	
	OperationsWithDocumentJournals.InitiateDynamicListSettings(ThisObject, DocumentListParameters);

EndProcedure

&AtClient
Procedure DisplayingGroupOfUserSelectionsAndSettings(ListName)
	
	LongTermUpdate = OperationsWithDocumentJournalsClient.TimeToUpdateListExceedsAllowedTime(ThisObject,
		ListName);
		
	If LongTermUpdate Then
		OperationsWithDocumentJournalsClient.SetValueOfDocumentListSettings(ThisObject, ListName,
			"DataLayoutSettingsHaveBeenChecked", True);
		DataCompositionSettingStructure = GetPerformingDataCompositionSettings(ListName);
		OperationsWithDocumentJournalsClient.SetValueOfDocumentListSettings(ThisObject, ListName,
			"DataCompositionSettings", DataCompositionSettingStructure.DataCompositionSettings);
		OperationsWithDocumentJournalsClient.SetValueOfDocumentListSettings(ThisObject, ListName,
			"StructureOfUserSettings", DataCompositionSettingStructure.StructureOfUserSettings);
	Else
		OperationsWithDocumentJournalsClient.SetValueOfDocumentListSettings(ThisObject, ListName,
			"DataLayoutSettingsHaveBeenChecked", False);
		OperationsWithDocumentJournalsClient.SetValueOfDocumentListSettings(ThisObject, ListName,
			"DataCompositionSettings", New DataCompositionSettings);
		OperationsWithDocumentJournalsClient.SetValueOfDocumentListSettings(ThisObject, ListName,
			"StructureOfUserSettings", New Structure);
	EndIf;

	OperationsWithDocumentJournalsClient.DocumentsDisplayGroupOfUserSelectionsAndSettings(ThisObject, ListName);
	
EndProcedure

&AtServer
Function GetPerformingDataCompositionSettings(ListName)
	
	TagName = OperationsWithDocumentJournals.ValueOfDocumentListSettings(ThisObject, ListName,
		"NameOfListItem");
	ListFormElement = Items[TagName];
	DataCompositionSettings = ListFormElement.GetPerformingDataCompositionSettings();

	ReturnStructure = New Structure;
	ReturnStructure.Insert("DataCompositionSettings", DataCompositionSettings);

	ListOfCompositeTypeFields = OperationsWithDocumentJournals.ValueOfDocumentListSettings(ThisObject,
		ListName, "ListOfCompositeTypeFields");

	StructureOfUserSettings = OperationsWithDocumentJournals.CheckUserSettingsOfDynamicList(
		DataCompositionSettings, ListOfCompositeTypeFields);

	ReturnStructure.Insert("StructureOfUserSettings", StructureOfUserSettings);
	
	Return ReturnStructure;
	
EndFunction

&AtClient
Procedure SetParametersForUpdatingDocumentLists(DataIsOutdated, UpdatingDuration = Undefined)
	
	SettingName = "ListOfDocumentsCacheSettings";
	ListName = "";
	For Each SettingUpListOfDocuments In ThisObject[SettingName] Do
		ListName = SettingUpListOfDocuments.Key;
		OperationsWithDocumentJournalsClient.SetParametersForUpdatingDocumentList(ThisObject, ListName, DataIsOutdated,
			UpdatingDuration);
		DisplayingGroupOfUserSelectionsAndSettings(ListName);
	EndDo;
	
EndProcedure

&AtClient
Procedure UpdateDocumentListDataWithTimeMeasurement(ListName, ConsiderAutoUpdateParameter = False)

	If Not ConsiderAutoUpdateParameter Then

		TheListNeedsToBeUpdated = True;

	Else

		TheListNeedsToBeUpdated = OperationsWithDocumentJournalsClient.SettingValueForAutoUpdatingListOfDocuments(
			ThisObject, ListName);

		If Not TheListNeedsToBeUpdated Then
			OperationsWithDocumentJournalsClient.SetFlagForDisplayingIrrelevantDataInList(ThisObject, ListName);
		EndIf;

	EndIf;

	If TheListNeedsToBeUpdated Then

		OperationsWithDocumentJournalsClient.UpdateDocumentListDataWithTimeMeasurement(ThisObject, ListName);
		DisplayingGroupOfUserSelectionsAndSettings(ListName);

	EndIf;

EndProcedure

&AtClient
Procedure UpdateListOfDocumentsEventNotificationProcessing(ListName, Parameter = Undefined)
	
	OperationsWithDocumentJournalsClient.UpdateListOfDocumentsEventNotificationProcessing(ThisObject, ListName, Parameter);
	DisplayingGroupOfUserSelectionsAndSettings(ListName);

EndProcedure

// Processing the form element event.
// 
// Parameters:
//  Item - FormField
//@skip-check module-unused-method
&AtClient
Procedure ListOfDocumentsFormElementEventHandling(Item)

	ActionForList = OperationsWithDocumentJournalsClient.NameOfListOfDocumentsByNameOfFormElement(ThisObject, Item.Name);
	
	If ActionForList.ListName = "" Then
		Return;
	EndIf;
	
	ListName = ActionForList.ListName;
	Action = ActionForList.Action;
	
	If Action = "Filters" Or Action = "Order" Or Action = "ConditionalAppearance" Then
		OperationsWithDocumentJournalsClient.SetValueOfDocumentListSettings(ThisObject, ListName,
			"DataLayoutSettingsHaveBeenChecked", True);
		DataCompositionSettingStructure = GetPerformingDataCompositionSettings(ListName);
		OperationsWithDocumentJournalsClient.SetValueOfDocumentListSettings(ThisObject, ListName,
			"DataCompositionSettings", DataCompositionSettingStructure.DataCompositionSettings);
		OperationsWithDocumentJournalsClient.SetValueOfDocumentListSettings(ThisObject, ListName,
			"StructureOfUserSettings", DataCompositionSettingStructure.StructureOfUserSettings);
	EndIf;
	
	If Action = "Filters" Then
		OperationsWithDocumentJournalsClient.FixCustomSelectionsInDocumentList(ThisObject, ListName);
	ElsIf Action = "Order" Then
		OperationsWithDocumentJournalsClient.FixSortingSettingsInDocumentList(ThisObject, ListName);
	ElsIf Action = "ConditionalAppearance" Then
		OperationsWithDocumentJournalsClient.FixConditionalAppearanceSettingsInDocumentList(ThisObject, ListName);
	ElsIf Action = "RefreshEnabled" Then
		UpdateDocumentListDataWithTimeMeasurement(ListName);
	ElsIf Action = "SpeedingUpListUpdates" Then
		OperationsWithDocumentJournalsClient.SaveSettingProductiveListUpdateMode(ThisObject, ListName);
	EndIf;
	
EndProcedure

#EndRegion

#EndRegion
