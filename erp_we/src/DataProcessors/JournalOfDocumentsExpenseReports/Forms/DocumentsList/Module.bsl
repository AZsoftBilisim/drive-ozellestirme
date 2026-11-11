#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetConditionalAppearance();
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	// DynamicListsSettings
	InitiateDynamicListSettings();
	// End DynamicListsSettings
	
	TMCommonUse.CustomizePeripherals(ThisForm);
	
	If Parameters.Property("PurposeUseKey") 
		And ValueIsFilled(Parameters.PurposeUseKey) Then
		PurposeUseKey = Parameters.PurposeUseKey;
	ElsIf Parameters.Property("FormAssignmentKey")
		And Not IsBlankString(Parameters.FormAssignmentKey) Then
		PurposeUseKey = Parameters.FormAssignmentKey;
	Else
		PurposeUseKey = DefaultFormAssignmentKey();
	EndIf;
	
	URL = "e1cib/app/DataProcessor.JournalOfDocumentsExpenseReports";
	
	RestoreSettings(Parameters);
	
	AvailableBusinessTransactionsAndDocuments = DataProcessors.JournalOfDocumentsExpenseReports.InitializeBusinessTransactionsAndDocuments(
		FilterBusinessTransactions, FilterDocumentTypes, PurposeUseKey);
	BusinessTransactionsAndDocuments.Load(AvailableBusinessTransactionsAndDocuments);
	ConfigureFormForSelectedOperationsAndDocuments(AvailableBusinessTransactionsAndDocuments);
	
	DocumentTypesUsed = AvailableBusinessTransactionsAndDocuments.UnloadColumn("DocumentType");
	
	DocumentsList.Parameters.SetParameterValue("UsingOfCheckIsAnOption", False);

	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject, Items.GlobalCommandsGroup);
	// End IntegrationWith1CDocumentManagementSubsystem
	
	DocumentTypesUsed.Add(Type("DocumentRef.ReversingEntry"));
	
	ReplacementText = "CASE
	|	WHEN DocumentsRegistryOverridable.Ref REFS Document.VendorInvoice
	|		THEN CAST(DocumentsRegistryOverridable.Ref AS Document.VendorInvoice)
	|	WHEN DocumentsRegistryOverridable.Ref REFS Document.ExpenseReport
	|		THEN CAST(DocumentsRegistryOverridable.Ref AS Document.ExpenseReport)
	|	WHEN DocumentsRegistryOverridable.Ref REFS Document.ReversingEntry
	|		THEN CAST(DocumentsRegistryOverridable.Ref AS Document.ReversingEntry)
	|END";
	
	DocumentsList.QueryText = StrReplace(DocumentsList.QueryText, "CAST(&Ref AS Document.ExpenseReport)", ReplacementText);
	
	Items.ControlCash.Visible = AccessRight("Use", Metadata.Reports.CashTransactionControl);
	
	// Document verificationreferences
	ListProperties = Common.DynamicListPropertiesStructure();
	FillPropertyValues(ListProperties, DocumentsList);
	ListProperties.QueryText = DocumentsList.QueryText;
	DocumentVerificationServer.ModifyDynamicDocumentLogListRequest(ListProperties.QueryText, "DocumentsRegistryOverridable");
	Common.SetDynamicListProperties(Items.DocumentsList, ListProperties);
	// End Document verificationreferences
	
	
	AdditionalParameters = New Structure("LocationOfLocalValidationData", Items.ReglGroupVerification);
	FormEvents.OnCreateAtServer(ThisObject, Cancel, StandardProcessing, AdditionalParameters);
	
	// StandardSubsystems.AttachableCommands
	PlacementParameters = AttachableCommands.PlacementParameters();
	PlacementParameters.Sources = New TypeDescription(DocumentTypesUsed);
	PlacementParameters.CommandBar = Items.DocumentsListCommandBar;
	AttachableCommands.OnCreateAtServer(ThisObject, PlacementParameters);
	// End StandardSubsystems.AttachableCommands
	
	// StandardSubsystems.SourceDocumentsOriginalsRecording
	SourceDocumentsOriginalsRecording.OnCreateAtServerListForm(ThisObject,Items.DocumentsList, Items.DocumentsListComment);
	// End StandardSubsystems.SourceDocumentsOriginalsRecording
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
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
	
	
	If EventName = "Write_ExpenseReport"
		Or EventName = "Write_VendorInvoice"
		Or EventName = "Write_ReceiptOfMonetaryDocuments"
		Or EventName = "Conducting_Storno" Or EventName = "Write_ReversingEntry"
		Then
		
		// DynamicListsSettings
		UpdateListOfDocumentsEventNotificationProcessing("DocumentsList", Parameter);
		// End DynamicListsSettings

		UpdateHyperlinkToLayout();
		
	EndIf;
	
	// StandardSubsystems.SourceDocumentsOriginalsRecording
	SourceDocumentsOriginalsRecordingClient.NotificationHandlerListForm(EventName, ThisObject, Items.DocumentsList);
	// End StandardSubsystems.SourceDocumentsOriginalsRecording
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure AdvanceHolderOnChange(Item)
	
	SetSelectionForAccountablePerson();
	
EndProcedure

&AtClient
Procedure OrganizationOnChange(Item)
	
	SetSelectionByOrganization();
	
EndProcedure

&AtClient
Procedure DepartmentOnChange(Item)
	
	SetSelectionByDivision();
	
EndProcedure

&AtClient
Procedure HelpTextFilterURLProcessing(Item, FormattedStringURL, StandardProcessing)
	
	StandardProcessing = False;
	
	FormParameters = New Structure();
	FormParameters.Insert("AvailableBusinessTransactionsAndDocuments", PlaceBusinessTransactionsAndDocumentsInTemporaryStorage());
	FormParameters.Insert("SettingsKey", PurposeUseKey);
	FormParameters.Insert("FormKey", DefaultFormAssignmentKey());
	
	OpenForm("Catalog.BusinessTransactionsSettings.Form.FormOfFilterSetting",
		FormParameters,,,,, New CallbackDescription("EstablishSelectionsForBusinessTransactionsAndDocuments", ThisObject));
	
EndProcedure

&AtClient
Procedure EstablishSelectionsForBusinessTransactionsAndDocuments(ValueSelected, AdditionalParameters) Export
	
	If ValueSelected = Undefined Then
		Return;
	EndIf;
	
	If TypeOf(ValueSelected) = Type("String") Then
		AddressOfAvailableBusinessTransactionsAndDocuments = ValueSelected;
		SelectionOperationTypeSelectionProcessingServer(AddressOfAvailableBusinessTransactionsAndDocuments);
	EndIf;
	
EndProcedure

&AtClient
Procedure ToRegisterURLProcessing(Item, FormattedStringURL, StandardProcessing)
	
	StandardProcessing = False;
	
	FormParameters = New Structure;
	QuickFilterStructure = New Structure;
	QuickFilterStructure.Insert("Organization", Organization);
	QuickFilterStructure.Insert("AdvanceHolder", AdvanceHolder);
	QuickFilterStructure.Insert("Department", Department);
	FormParameters.Insert("QuickFilterStructure", QuickFilterStructure);
	FormParameters.Insert("PurposeUseKey", DefaultFormAssignmentKey());
	
	If FormattedStringURL = "PageOfTheOrderForRegistration" Then
		// &PerformanceMeasurement
		PerformanceMonitorClient.StartTimeMeasurement(True,
			"DataProcessor.JournalOfDocumentsExpenseReports.Command.ExpenseReportsForRegistration");
		
		FormParameters.Insert("CurrentPageName", FormattedStringURL);
		FormattedStringURL = "DataProcessor.JournalOfDocumentsExpenseReports.Form.ExpenseReportsForRegistration";
	EndIf;
	
	OpenForm(FormattedStringURL, FormParameters);
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersDocumentsList

&AtClient
Procedure DocumentsListSelection(Item, RowSelected, Field, StandardProcessing)
	
	StandardProcessing = False;
	
	If Field.Name = "SourceDocumentOriginalState" Or Field.Name = "StateOriginalReceived" Then
		// StandardSubsystems.SourceDocumentsOriginalsRecording
		SourceDocumentsOriginalsRecordingClient.ListSelection(Field.Name,ThisObject,Items.DocumentsList, StandardProcessing);
		// End StandardSubsystems.SourceDocumentsOriginalsRecording
		Return;
	EndIf;
		
	TMCommonUseClient.ChangeElement(Item);
	
	
EndProcedure

&AtClient
Procedure DocumentsListOnActivateRow(Item)
	
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	
EndProcedure

&AtClient
Procedure DocumentsListBeforeAddRow(Item, Cancel, Copy, Parent, Var_Group, Parameter)
	
	If Items.CreateGroupGenerated.ChildItems.Count() <> 0 Then 
		If Copy Then
			TMCommonUseClient.CopyItem(Item);
		ElsIf FilterDocumentTypes.Count() = 1 And FilterBusinessTransactions.Count() = 1 Then
			SubordinateItem = Items.CreateGroupGenerated.ChildItems[0]; // FormField
			TeamStructure_ = New Structure("Name", SubordinateItem.Name);
			Attachable_CreateDocument(TeamStructure_);
		Else
			Attachable_CreateDocumentViaSelectionForm(Undefined);
		EndIf;
	EndIf;
	Cancel = True;
	
EndProcedure

&AtClient
Procedure DocumentsListBeforeRowChange(Item, Cancel)
	
	Cancel = True;
	TMCommonUseClient.ChangeElement(Item);
	
EndProcedure

&AtClient
Procedure DocumentsListBeforeDeleteRow(Item, Cancel)
	
	Cancel = True;
	DescriptionOfNotificationAfterEnd = New CallbackDescription("AfterChangingDocumentList", ThisObject);
	TMCommonUseClient.SetDeletionMark(Item, Title, DescriptionOfNotificationAfterEnd);
	
EndProcedure

&AtClient
Procedure ListCopy(Command)
	
	TMCommonUseClient.CopyItem(Items.DocumentsList);
	
EndProcedure

&AtClient
Procedure ListChange(Command)
	
	TMCommonUseClient.ChangeElement(Items.DocumentsList);
	
EndProcedure

&AtClient
Procedure ListUndoPosting(Command)
	
	TMCommonUseClient.UndoPosting(Items.DocumentsList, Title,
		OperationsWithDocumentJournalsClient.ParametersForUpdatingDocumentList(ThisObject, "DocumentsList"));
	UpdateHyperlinkToLayout();
	
EndProcedure

&AtClient
Procedure ListPost(Command)
	
	TMCommonUseClient.PostDocuments(Items.DocumentsList, Title,
		OperationsWithDocumentJournalsClient.ParametersForUpdatingDocumentList(ThisObject, "DocumentsList"));
	UpdateHyperlinkToLayout();
	
EndProcedure

&AtClient
Procedure ListSetClearADeletionMark(Command)
	
	DescriptionOfNotificationAfterEnd = New CallbackDescription("AfterChangingDocumentList", ThisObject);
	TMCommonUseClient.SetDeletionMark(Items.DocumentsList, Title, DescriptionOfNotificationAfterEnd,
		OperationsWithDocumentJournalsClient.ParametersForUpdatingDocumentList(ThisObject, "DocumentsList"));
	
EndProcedure

&AtServerNoContext
Procedure DocumentsListOnGetDataAtServer(TagName, Settings, Rows)
	
	// StandardSubsystems.SourceDocumentsOriginalsRecording
	SourceDocumentsOriginalsRecording.OnGetDataAtServer(Rows);
	// End StandardSubsystems.SourceDocumentsOriginalsRecording

EndProcedure

&AtServer
Procedure DocumentsListOnUpdateUserSettingSetAtServer(Item, StandardProcessing)
	
	// DynamicListsSettings
	OperationsWithDocumentJournals.SetVisibilityOfDefaultUpdateSettingsGroup(ThisObject, "DocumentsList");
	// End DynamicListsSettings
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

// StandardSubsystems.AttachableCommands
&AtClient
Procedure Attachable_ExecuteCommand(Command)
	AttachableCommandsClient.ExecuteCommand(ThisObject, Command, Items.DocumentsList);
EndProcedure

&AtServer
Procedure Attachable_ExecuteCommandAtServer(Context, Result) Export
	AttachableCommands.ExecuteCommand(ThisObject, Context, Items.DocumentsList, Result);
EndProcedure

&AtClient
Procedure Attachable_UpdateCommands()
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Items.DocumentsList);
EndProcedure
// End StandardSubsystems.AttachableCommands

// IntegrationWith1CDocumentManagementSubsystem
&AtClient
Procedure Attachable_ExecuteIntegrationCommand(Command)
	
	IntegrationWith1CDocumentManagementCoreClient.ExecutePlugInIntegrationCommand(Command, ThisObject, Items.DocumentsList);
	
EndProcedure
// End IntegrationWith1CDocumentManagementSubsystem

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure



&AtClient
Procedure Attachable_CreateDocument(Command)
	
	FilterStructure1 = New Structure;
	FilterStructure1.Insert("Organization", Organization);
	FilterStructure1.Insert("AdvanceHolder", AdvanceHolder);
	TMCommonUseClient.CreateDocumentUsingCommand(Command.Name, FilterStructure1);
	
EndProcedure

&AtClient
Procedure Attachable_CreateDocumentViaSelectionForm(Command)
	
	FormKey = DefaultFormAssignmentKey();
	AddressBusinessTransactionsAndDocuments = PlaceBusinessTransactionsAndDocumentsInTemporaryStorage();
	FilterStructure1 = New Structure;
	FilterStructure1.Insert("Organization", Organization);
	FilterStructure1.Insert("AdvanceHolder", AdvanceHolder);
	TMCommonUseClient.CreateDocumentViaSelectionForm(
		AddressBusinessTransactionsAndDocuments, FormKey, PurposeUseKey, FilterStructure1);
		
EndProcedure

&AtClient
Procedure SetDateInterval(Command)
	
	Notification = New CallbackDescription("SetDateIntervalCompletion", ThisObject);
	TMCommonUseClient.EditPeriod(Period,, Notification);
	
EndProcedure

&AtClient
Procedure SetDateIntervalCompletion(ValueSelected, AdditionalParameters) Export
	
	If ValueSelected = Undefined Then
		Return;
	EndIf;
	Period = ValueSelected;
	SetSelectionByPeriod();
	
EndProcedure

&AtClient
Procedure OnlyPreparedOnes(Command)
	
	Items.DocumentsListOnlyPreparedOnes.Check = Not Items.DocumentsListOnlyPreparedOnes.Check;
	
	OnlyPreparedOnes = ?(Items.DocumentsListOnlyPreparedOnes.Check, 1, 0);
	OnlyPreparedWhenServerChanges();
	
EndProcedure

&AtClient
Procedure ControlCash(Command)
	
	FormParameters = New Structure("Filter, VariantKey, PurposeUseKey, GenerateOnOpen");
	FormParameters.GenerateOnOpen = True;
	
	FormParameters.VariantKey = "ControlOfAdvanceHoldersCash";
	FormParameters.PurposeUseKey = "ControlOfAdvanceHoldersCash";
	
	Filter = New Structure;
	If ValueIsFilled(AdvanceHolder) Then
		Filter.Insert("AdvanceHolder", AdvanceHolder);
	EndIf;
	If ValueIsFilled(Organization) Then
		Filter.Insert("Organization", Organization);
	EndIf;
	If ValueIsFilled(Department) Then
		Filter.Insert("Department", Department);
	EndIf;
	FormParameters.Filter = Filter;
	
	OpenForm("Report.CashTransactionControl.Form", FormParameters, ThisForm,);
	
EndProcedure

// StandardSubsystems.SourceDocumentsOriginalsRecording
&AtClient
Procedure Attachable_UpdateOriginalStateCommands()
	
	UpdateOriginalStateCommands()
   
EndProcedure

&AtServer
Procedure UpdateOriginalStateCommands()
	
	AvailableBusinessTransactionsAndDocuments = DataProcessors.JournalOfDocumentsExpenseReports.InitializeBusinessTransactionsAndDocuments(
		FilterBusinessTransactions, FilterDocumentTypes, PurposeUseKey);
		
	DocumentTypesUsed = AvailableBusinessTransactionsAndDocuments.UnloadColumn("DocumentType");

	// StandardSubsystems.AttachableCommands
	PlacementParameters = AttachableCommands.PlacementParameters();
	PlacementParameters.Sources = New TypeDescription(DocumentTypesUsed);
	PlacementParameters.CommandBar = Items.DocumentsListCommandBar;
	AttachableCommands.OnCreateAtServer(ThisObject, PlacementParameters);
	// End StandardSubsystems.AttachableCommands
		
EndProcedure
//End StandardSubsystems.SourceDocumentsOriginalsRecording

&AtClient
Procedure ListDocumentsRefresh(Command)
	
	// DynamicListsSettings
	UpdateDocumentListDataWithTimeMeasurement("DocumentsList");
	// End DynamicListsSettings
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure AfterChangingDocumentList(Result, AdditionalParameters) Export
	If Not Result = DialogReturnCode.Yes Then
		Return;
	EndIf;
	UpdateHyperlinkToLayout();
EndProcedure

&AtServer
Procedure SetConditionalAppearance()
	
	ConditionalAppearance.Items.Clear();
	
	//
	
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.DocumentsListCurrency.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("DocumentsList.Multicurrency");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<Đa tiền tệ>';
													|ru = '<Мультивалютный>';
													|en = '<Multicurrency>'; fa = '<Multicurrency>';
													|it = '<Multivaluta>';
													|pl = '<Multicurrency>';
													|tr = '<Çoklu para birimi>'"));
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.DocumentsListCurrency.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("DocumentsList.Currency");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<Đa tiền tệ>';
													|ru = '<Мультивалютный>';
													|en = '<Multicurrency>'; fa = '<Multicurrency>';
													|it = '<Multivaluta>';
													|pl = '<Multicurrency>';
													|tr = '<Çoklu para birimi>'"));
	StandardSubsystemsServer.SetDateFieldConditionalAppearance(ThisObject, "DocumentsList.Date", Items.DocumentsListDate.Name);
	
EndProcedure

&AtClientAtServerNoContext
Function DefaultFormAssignmentKey()
	
	Return "ExpenseReports";
	
EndFunction

&AtServer
Procedure ConfigureFormForSelectedOperationsAndDocuments(VTBusinessTransactionsAndDocumentTypes)
	
	WorkplaceData = TMCommonUse.WorkplaceData(VTBusinessTransactionsAndDocumentTypes,
		DefaultFormAssignmentKey(), NStr("vi = 'Giấy thanh toán tiền tạm ứng';
										|ru = 'Авансовые отчеты';
										|en = 'Expense reports'; fa = 'گزارش‌های هزینه';
										|it = 'Note spese';
										|pl = 'Raporty zaliczkowe';
										|tr = 'Gider raporları'"));
	
	Title = WorkplaceData.WorkplaceTitle;
	
	SetDynamicListSelections();
	SetVisibilityAvailability();
	
	TMCommonUse.ReplaceLinkFieldWithExpressByDocumentTypeConstruct(Items.DocumentsList,
		BusinessTransactionsAndDocuments);
	
	TMCommonUse.FormInscriptionSelection(
		Items.HelpTextFilter.Title, BusinessTransactionsAndDocuments, FilterDocumentTypes, FilterBusinessTransactions);
	ConfigureDocumentManagementButtons();
	
EndProcedure

&AtServer
Procedure SelectionOperationTypeSelectionProcessingServer(AddressOfBusinessTransactionsAndDocuments)
	
	VTBusinessTransactionsAndDocumentTypes = GetFromTempStorage(AddressOfBusinessTransactionsAndDocuments);
	BusinessTransactionsAndDocuments.Load(VTBusinessTransactionsAndDocumentTypes);
	TMCommonUse.FillInSelectionsAccordingToTableOfBusinessTransactionsAndDocumentTypes(VTBusinessTransactionsAndDocumentTypes, FilterBusinessTransactions, FilterDocumentTypes);
	ConfigureFormForSelectedOperationsAndDocuments(VTBusinessTransactionsAndDocumentTypes);
	
EndProcedure

&AtServer
Procedure SetVisibilityAvailability()
	
	If Not GetFunctionalOption("UseMultipleCompanies") Then
		Items.Organization.Visible = False;
	EndIf;
	
	Items.DocumentsListDepartment.Visible = GetFunctionalOption("UseBusinessUnits");
	Items.DocumentsListStatus.Visible = GetFunctionalOption("UseExpenseReportStatuses");
	
EndProcedure

&AtServer
Procedure SetDynamicListSelections()
	
	CommonClientServer.SetDynamicListFilterItem(
		DocumentsList,
		"RefType",
		FilterDocumentTypes,
		DataCompositionComparisonType.InList,,
		True);
	
	CommonClientServer.SetDynamicListFilterItem(
		DocumentsList,
		"BusinessOperation",
		FilterBusinessTransactions,
		DataCompositionComparisonType.InList,,
		True);
	
	SetSelectionByOrganization();
	SetSelectionForAccountablePerson();
	SetSelectionByDivision();
	SetSelectionByPeriod();
	
EndProcedure

&AtServer
Procedure SetSelectionByOrganization()
	
	CommonClientServer.SetDynamicListFilterItem(
		DocumentsList,
		"Organization",
		Organization,
		DataCompositionComparisonType.Equal,,
		ValueIsFilled(Organization));
		
	UpdateHyperlinkToLayout();
	
	// DynamicListsSettings
	OperationsWithDocumentJournals.SetVisibilityOfDefaultUpdateSettingsGroup(ThisObject, "DocumentsList");
	// End DynamicListsSettings
	
EndProcedure

&AtServer
Procedure SetSelectionByDivision()
	
	CommonClientServer.SetDynamicListFilterItem(
		DocumentsList,
		"Department",
		Department,
		DataCompositionComparisonType.Equal,,
		ValueIsFilled(Department));
		
	UpdateHyperlinkToLayout();
	
	// DynamicListsSettings
	OperationsWithDocumentJournals.SetVisibilityOfDefaultUpdateSettingsGroup(ThisObject, "DocumentsList");
	// End DynamicListsSettings
	
EndProcedure

&AtServer
Procedure SetSelectionForAccountablePerson()
	
	CommonClientServer.SetDynamicListFilterItem(DocumentsList,
																			"AdvanceHolder",
																			AdvanceHolder,
																			DataCompositionComparisonType.Equal,
																			,
																			ValueIsFilled(AdvanceHolder));
	
	UpdateHyperlinkToLayout();
	
	// DynamicListsSettings
	OperationsWithDocumentJournals.SetVisibilityOfDefaultUpdateSettingsGroup(ThisObject, "DocumentsList");
	// End DynamicListsSettings
	
EndProcedure

&AtServer
Procedure SetSelectionByPeriod()
	
	DocumentsList.Parameters.SetParameterValue("BeginOfPeriod",
		Period.StartDate);
	DocumentsList.Parameters.SetParameterValue("EndOfPeriod", 
		?(ValueIsFilled(Period.EndDate), Period.EndDate, EndOfDay(Date(3999, 12, 31))));
		
	// DynamicListsSettings
	OperationsWithDocumentJournals.SetVisibilityOfDefaultUpdateSettingsGroup(ThisObject, "DocumentsList");
	// End DynamicListsSettings
	
EndProcedure

&AtServer
Procedure OnlyPreparedWhenServerChanges()

	CommonClientServer.SetDynamicListFilterItem(
		DocumentsList,
		"Status",
		Enums.ExpenseReportStatuses.Prepared,
		DataCompositionComparisonType.Equal,,
		OnlyPreparedOnes = 1);
		
	// DynamicListsSettings
	OperationsWithDocumentJournals.SetVisibilityOfDefaultUpdateSettingsGroup(ThisObject, "DocumentsList");
	// End DynamicListsSettings
	
EndProcedure

&AtServer
Function PlaceBusinessTransactionsAndDocumentsInTemporaryStorage()
	Return PutToTempStorage(BusinessTransactionsAndDocuments.Unload(), UUID);
EndFunction

&AtServer
Procedure UpdateHyperlinkToLayout()
	
	GenerationParameters = New Structure;
	GenerationParameters.Insert("AdvanceHolder", AdvanceHolder);
	GenerationParameters.Insert("Organization", Organization);
	GenerationParameters.Insert("Department", Department);
	GenerationParameters.Insert("ThisIsHyperlinkCalculation", True);
	GenerationParameters.Insert("PurposeUseKey", DefaultFormAssignmentKey());
	
	ToRegister = TMCommonUse.CreateHyperlinkToDesign(BusinessTransactionsAndDocuments.Unload(), GenerationParameters);
	Items.ToRegister.Visible = ValueIsFilled(ToRegister);
	
EndProcedure

&AtServer
Procedure ConfigureDocumentManagementButtons()
	
	ParametersStructure = TMCommonUse.StructureOfSettingsForDocumentManagementButtons();
	ParametersStructure.Form                                               = ThisForm;
	ParametersStructure.NameOfCopyButton                                = "ListCopy";
	ParametersStructure.NameOfCopyContextMenuButton                 = "ListContextMenuCopy";
	ParametersStructure.ChangeButtonName                                   = "ListChange";
	ParametersStructure.NameOfChangeContextMenuButton                    = "ListContextMenuChange";
	ParametersStructure.ButtonNamePost                                   = "ListPost";
	ParametersStructure.NameOfHoldContextMenuButton                    = "ListContextMenuPost";
	ParametersStructure.NameOfCancelEventButton                           = "ListUndoPosting";
	ParametersStructure.NameOfCancelButtonIsContextMenu            = "ListContextMenuUndoPosting";
	ParametersStructure.NameOfMarkDeleteButton                  = "ListSetDeletionMark";
	ParametersStructure.ButtonNameMarkDeleteContextMenu   = "ListContextMenuSetDeletionMark";
	
	TMCommonUse.ConfigureDocumentManagementButtons(ParametersStructure);

EndProcedure

&AtServer
Procedure ShouldSaveSettings()
	
	AttributesToSaveNames = "
		|FilterBusinessTransactions,
		|FilterDocumentTypes,
		|AdvanceHolder,
		|Organization,
		|Period,
		|ListOfDocumentsAutoUpdateMode";
	
	Settings = New Structure(AttributesToSaveNames);
	FillPropertyValues(Settings, ThisForm);
	
	Common.CommonSettingsStorageSave(
		"DataProcessor.JournalOfDocumentsExpenseReports.Form.ListForm", PurposeUseKey, Settings);
	
EndProcedure

&AtServer
Procedure RestoreSettings(Var_Parameters)
	
	ListOfDocumentsAutoUpdateMode = True;
	
	If Var_Parameters.Property("QuickFilterStructure") Then
		QuickFilterStructure = Var_Parameters.QuickFilterStructure;
		QuickFilterStructure.Property("Organization", Organization);
		QuickFilterStructure.Property("AdvanceHolder", AdvanceHolder);
		QuickFilterStructure.Property("Department", Department);
		QuickFilterStructure.Property("Period", Period);
	Else
		Settings = Common.CommonSettingsStorageLoad(
			"DataProcessor.JournalOfDocumentsExpenseReports.Form.ListForm", PurposeUseKey);
		If TypeOf(Settings) = Type("Structure") Then
			
			FillPropertyValues(ThisForm, Settings);
			
			If Settings.Property("ListOfDocumentsAutoUpdateMode") Then
				ListOfDocumentsAutoUpdateMode = Settings.ListOfDocumentsAutoUpdateMode;
			EndIf;
			
		EndIf;
		
	EndIf;

EndProcedure

#Region DynamicListsSettings

&AtServer
Procedure InitiateDynamicListSettings()
	
	DocumentListParameters = New Array;
	
	ListParameterStructure = OperationsWithDocumentJournals.StructureOfFormationOfGroupOfUserSettingsForDynamicListOnForm();
	ListParameterStructure.ListName = "DocumentsList";
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
