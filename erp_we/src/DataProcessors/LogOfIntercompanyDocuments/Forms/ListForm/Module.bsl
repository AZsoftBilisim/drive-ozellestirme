#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetConditionalAppearance();
	
	// Refund upon receipt of the form for analysis.
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	// DynamicListsSettings
	InitiateDynamicListSettings();
	// End DynamicListsSettings
	
	TMCommonUse.CustomizePeripherals(ThisForm);
	
	If Not ValueIsFilled(Parameters.PurposeUseKey) Then
		PurposeUseKey = DefaultFormAssignmentKey();
		SettingsKey                = "";
	Else
		PurposeUseKey = Parameters.PurposeUseKey;
		SettingsKey                = Parameters.PurposeUseKey;
	EndIf;
	
	URL = "e1cib/app/DataProcessor.LogOfIntercompanyDocuments";
	
	RestrictionByCompanyIsUsed = AccessManagementInternal.HasTableRestrictionByAccessKind(
		"InformationRegister.DocumentsRegistry", "Companies", "PartnerGroups,Companies,Departments,Warehouses");
	
	RestoreSettings(Parameters);
	
	VTBusinessTransactionsAndDocumentTypes = DataProcessors.LogOfIntercompanyDocuments.InitializeBusinessTransactionsAndDocuments(
		FilterBusinessTransactions, FilterDocumentTypes, SettingsKey);
	
	BusinessTransactionsAndDocuments.Load(VTBusinessTransactionsAndDocumentTypes);
	
	ConfigureFormForSelectedOperationsAndDocuments(VTBusinessTransactionsAndDocumentTypes);
	
	DocumentTypesUsed = VTBusinessTransactionsAndDocumentTypes.UnloadColumn("DocumentType");
	
	
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject, Items.GlobalCommandsGroup);
	// End IntegrationWith1CDocumentManagementSubsystem
	
	AdditionalParameters = New Structure("LocationOfLocalValidationData", Items.ReglGroupVerification);
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing, AdditionalParameters);
	
	DocumentTypesUsed.Add(Type("DocumentRef.ReversingEntry"));
	
	// StandardSubsystems.AttachableCommands
	PlacementParameters = AttachableCommands.PlacementParameters();
	PlacementParameters.Sources = New TypeDescription(DocumentTypesUsed);
	PlacementParameters.CommandBar = Items.ListRegisteredCommandBar;
	
	AttachableCommands.OnCreateAtServer(ThisObject, PlacementParameters);
	// End StandardSubsystems.AttachableCommands
	
	If Items.StatusPresentation.Parent = Items.ListRegistered Then
		Placement = Items.StatusPresentation;
	Else
		Placement = Items.StatusPresentation.Parent;
	EndIf;
	
	// StandardSubsystems.SourceDocumentsOriginalsRecording
	SourceDocumentsOriginalsRecording.OnCreateAtServerListForm(ThisObject,Items.ListRegistered, Placement);
	// End StandardSubsystems.SourceDocumentsOriginalsRecording
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	
	EquipmentManagerClient.StartConnectingDevicesWhenYouOpenForm(Undefined, ThisForm, "BarcodeScanner");
	
	ConnectHyperlinkWaitingHandlerToLayout();
	
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
	If Source = "Peripherals"
		And IsInputAvailable() Then
		
		If EventName = "ScanData"
			And EquipmentManagerTMClient.ThereIsRawEvent() Then
			
			ProcessBarcodes(EquipmentManagerTMClient.ConvertDataFromScannerToStructure(Parameter));
			
		EndIf;
		
	EndIf;
	// End Peripherals
	
	
	If EventName = "Write_IntercompanyGoodsReturn"
		Or EventName = "Write_CommissionReportIntercompany"
		Or EventName = "Write_CommissionWriteOffReportIntercompany"
		Or EventName = "Write_CustomerInvoiceIntercompany"
		Or EventName = "Write_ConsumptionReportSubcontractingServicesDeliveredIntercompany"
		Or EventName = "Conducting_Storno"
		Or EventName = "Write_ReversingEntry" Then
		
		// DynamicListsSettings
		UpdateListOfDocumentsEventNotificationProcessing("ListRegistered", Parameter);
		// End DynamicListsSettings
		
		UpdateHyperlinkToLayout();
		ConnectHyperlinkWaitingHandlerToLayout();
		
	EndIf;
	
	// StandardSubsystems.SourceDocumentsOriginalsRecording
	SourceDocumentsOriginalsRecordingClient.NotificationHandlerListForm(EventName, ThisObject, Items.ListRegistered);
	// End StandardSubsystems.SourceDocumentsOriginalsRecording
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure OrganizationOnChange(Item)
	
	OrganizationOnChangeServer();
	ConnectHyperlinkWaitingHandlerToLayout();
	
EndProcedure

&AtClient
Procedure WarehouseOnChange(Item)
	
	WarehouseOnChangeServer();
	ConnectHyperlinkWaitingHandlerToLayout();
	
EndProcedure

&AtClient
Procedure HelpTextFilterURLProcessing(Item, FormattedStringURL,
		StandardProcessing)
	
	StandardProcessing = False;
	
	FormParameters = New Structure();
	FormParameters.Insert("SettingsKey", PurposeUseKey);
	FormParameters.Insert("FormKey",    DefaultFormAssignmentKey());
	FormParameters.Insert("AvailableBusinessTransactionsAndDocuments",
		PlaceBusinessTransactionsAndDocumentsInTemporaryStorage());
	
	NotificationForms = New CallbackDescription("EstablishSelectionsForBusinessTransactionsAndDocuments", ThisObject);
	
	OpenForm("Catalog.BusinessTransactionsSettings.Form.FormOfFilterSetting", FormParameters, , , , ,
		NotificationForms);
	
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
		ConnectHyperlinkWaitingHandlerToLayout();
	EndIf;
	
EndProcedure

&AtClient
Procedure ToRegisterURLProcessing(Item, FormattedStringURL, StandardProcessing)
	
	KeyOperationName = 
		"DataProcessor.LogOfIntercompanyDocuments.ListForm.Command.ToRegisterURLProcessing."
		+ FormattedStringURL;
	
	PerformanceMonitorClient.StartTimeMeasurement(True, KeyOperationName);
	
	StandardProcessing = False;
	
	UserSettings = New DataCompositionUserSettings;
	
	ListFormSelections = New Structure;
	ListFormSelections.Insert("Organization", Organization);
	ListFormSelections.Insert("Warehouse",       Warehouse);
	
	FormParameters = New Structure;
	FormParameters.Insert("FormAssignmentKey", DefaultFormAssignmentKey());
	FormParameters.Insert("ListFormSelections",   ListFormSelections);
	
	If StrFind(FormattedStringURL, "RegisterTransfersAndRedemptions") > 0 Then
		UniquenessParameter = DefaultFormAssignmentKey();
	Else
		UniquenessParameter = False;
	EndIf;
	
	OpenForm(FormattedStringURL, FormParameters, , UniquenessParameter);
	
EndProcedure

&AtClient
Procedure SeeAlsoInProgressURLProcessing(Item, FormattedStringURL, StandardProcessing)
	StandardProcessing = False;
	FormParameters = New Structure;
	If ValueIsFilled(Warehouse) Then
		FormParameters.Insert("Basis", Warehouse);
	EndIf;
	OpenForm(FormattedStringURL, FormParameters);
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

#Region CreateButton

&AtClient
Procedure Attachable_CreateDocument(Command)
	
	FilterStructure1 = New Structure;
	FilterStructure1.Insert("Organization", Organization);
	FilterStructure1.Insert("Warehouse",       Warehouse);
	
	TMCommonUseClient.CreateDocumentUsingCommand(Command.Name, FilterStructure1);
	
EndProcedure

&AtClient
Procedure Attachable_CreateDocumentViaSelectionForm(Command)
	
	FormKey = DefaultFormAssignmentKey();
	AddressBusinessTransactionsAndDocuments = PlaceBusinessTransactionsAndDocumentsInTemporaryStorage();
	
	FilterStructure1 = New Structure;
	FilterStructure1.Insert("Organization", Organization);
	FilterStructure1.Insert("Warehouse",       Warehouse);
	
	TMCommonUseClient.CreateDocumentViaSelectionForm(AddressBusinessTransactionsAndDocuments, FormKey,
		PurposeUseKey, FilterStructure1);
	
EndProcedure

#EndRegion

// StandardSubsystems.AttachableCommands
&AtClient
Procedure Attachable_ExecuteCommand(Command)
	AttachableCommandsClient.ExecuteCommand(ThisObject, Command, Items.ListRegistered);
EndProcedure

&AtServer
Procedure Attachable_ExecuteCommandAtServer(Context, Result) Export
	AttachableCommands.ExecuteCommand(ThisObject, Context, Items.ListRegistered, Result);
EndProcedure

&AtClient
Procedure Attachable_UpdateCommands()
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Items.ListRegistered);
EndProcedure
// End StandardSubsystems.AttachableCommands


&AtClient
Procedure SetDateInterval(Command)
	
	Notification = New CallbackDescription("SetDateIntervalCompletion", ThisObject);
	
	TMCommonUseClient.EditPeriod(Period, Undefined, Notification);
	
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
Procedure ListCopy(Command)
	
	TMCommonUseClient.CopyItem(Items.ListRegistered);
	
EndProcedure

&AtClient
Procedure ListChange(Command)
	
	TMCommonUseClient.ChangeElement(Items.ListRegistered);
	
EndProcedure

&AtClient
Procedure ListPost(Command)
	
	TMCommonUseClient.PostDocuments(Items.ListRegistered, Title,
		OperationsWithDocumentJournalsClient.ParametersForUpdatingDocumentList(ThisObject, "ListRegistered"));
	ListPostServer();
	ConnectHyperlinkWaitingHandlerToLayout();
	
EndProcedure

&AtClient
Procedure ListUndoPosting(Command)
	
	TMCommonUseClient.UndoPosting(Items.ListRegistered, Title,
		OperationsWithDocumentJournalsClient.ParametersForUpdatingDocumentList(ThisObject, "ListRegistered"));
	ListUndoPostingServer();
	ConnectHyperlinkWaitingHandlerToLayout();
	
EndProcedure

&AtClient
Procedure ListSetClearADeletionMark(Command)
	
	SetClearDeletionMark();

EndProcedure

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

// IntegrationWith1CDocumentManagementSubsystem
&AtClient
Procedure Attachable_ExecuteIntegrationCommand(Command)
	
	IntegrationWith1CDocumentManagementCoreClient.ExecutePlugInIntegrationCommand(Command, ThisObject,
		Items.ListRegistered);
	
EndProcedure
// End IntegrationWith1CDocumentManagementSubsystem

// StandardSubsystems.SourceDocumentsOriginalsRecording
&AtClient
Procedure Attachable_UpdateOriginalStateCommands()
	
	UpdateOriginalStateCommands()
   
EndProcedure

&AtServer
Procedure UpdateOriginalStateCommands()
	
	VTBusinessTransactionsAndDocumentTypes = DataProcessors.LogOfIntercompanyDocuments.InitializeBusinessTransactionsAndDocuments(
		FilterBusinessTransactions, FilterDocumentTypes, SettingsKey);	
	
	DocumentTypesUsed = VTBusinessTransactionsAndDocumentTypes.UnloadColumn("DocumentType");

	// StandardSubsystems.AttachableCommands
	PlacementParameters = AttachableCommands.PlacementParameters();
	PlacementParameters.Sources = New TypeDescription(DocumentTypesUsed);
	PlacementParameters.CommandBar = Items.ListRegisteredCommandBar;
	AttachableCommands.OnCreateAtServer(ThisObject, PlacementParameters);
	// End StandardSubsystems.AttachableCommands
		
EndProcedure
//End StandardSubsystems.SourceDocumentsOriginalsRecording

&AtClient
Procedure DocumentsListRefresh(Command)
	
	// DynamicListsSettings
	UpdateDocumentListDataWithTimeMeasurement("ListRegistered");
	// End DynamicListsSettings
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersListRegistered

&AtClient
Procedure ListRegisteredSelection(Item, RowSelected, Field, StandardProcessing)
	
	StandardProcessing = False;
	
	If Field.Name = "SourceDocumentOriginalState" Or Field.Name = "StateOriginalReceived" Then
		// StandardSubsystems.SourceDocumentsOriginalsRecording
		SourceDocumentsOriginalsRecordingClient.ListSelection(Field.Name,ThisObject, Items.ListRegistered, StandardProcessing);
		// End StandardSubsystems.SourceDocumentsOriginalsRecording
		Return;
	EndIf;
	
	TMCommonUseClient.ChangeElement(Item);
	
	If Field = Items.StatusPresentation Then
	EndIf;
	
EndProcedure

&AtClient
Procedure ListRegisteredBeforeAddRow(Item, Cancel, Copy, Parent, Var_Group, Parameter)
	
	Cancel = True;
	
	If Items.CreateGroupGenerated.ChildItems.Count() <> 0 Then
		
		If Copy Then
			
			TMCommonUseClient.CopyItem(Item);
			
		ElsIf FilterDocumentTypes.Count() = 1
			And FilterBusinessTransactions.Count() = 1 Then
			
			TeamStructure_ = New Structure("Name", Items.CreateGroupGenerated.ChildItems[0].Name);
			Attachable_CreateDocument(TeamStructure_);
			
		Else
			
			Attachable_CreateDocumentViaSelectionForm(Undefined);
			
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ListRegisteredBeforeRowChange(Item, Cancel)
	
	Cancel = True;
	
	TMCommonUseClient.ChangeElement(Item);
	
EndProcedure

&AtClient
Procedure ListRegisteredBeforeDeleteRow(Item, Cancel)
	
	Cancel = True;
	
	SetClearDeletionMark();
	
EndProcedure

&AtClient
Procedure ListRegisteredOnActivateRow(Item)
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

&AtServerNoContext
Procedure ListRegisteredOnGetDataAtServer(TagName, Settings, Rows)
	
	// StandardSubsystems.SourceDocumentsOriginalsRecording
	SourceDocumentsOriginalsRecording.OnGetDataAtServer(Rows);
	// End StandardSubsystems.SourceDocumentsOriginalsRecording
	
	
EndProcedure

&AtServer
Procedure ListRegisteredOnUpdateUserSettingSetAtServer(Item, StandardProcessing)
	
	// DynamicListsSettings
	OperationsWithDocumentJournals.SetVisibilityOfDefaultUpdateSettingsGroup(ThisObject, "ListRegistered");
	// End DynamicListsSettings
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure SetClearDeletionMark()
	
	CallbackDescription = New CallbackDescription("SetClearDeletionMarkCompletion", ThisObject);
	
	TMCommonUseClient.SetDeletionMark(Items.ListRegistered, Title, CallbackDescription,
		OperationsWithDocumentJournalsClient.ParametersForUpdatingDocumentList(ThisObject, "ListRegistered"));
	
EndProcedure

&AtClient
Procedure SetClearDeletionMarkCompletion(QuestionResult, AdditionalParameters) Export
	
	If QuestionResult = DialogReturnCode.Yes Then
		ListDeletionMarkServer();
		ConnectHyperlinkWaitingHandlerToLayout();
	EndIf;
	
EndProcedure

&AtServer
Procedure ListDeletionMarkServer()
	ProvisionInDocumentsServer.CheckToRunBackgroundInventoryAllocationJob();
	UpdateHyperlinkToLayout();
EndProcedure

&AtServer
Procedure ListUndoPostingServer()
	ProvisionInDocumentsServer.CheckToRunBackgroundInventoryAllocationJob();
	UpdateHyperlinkToLayout();
EndProcedure

&AtServer
Procedure ListPostServer()
	ProvisionInDocumentsServer.CheckToRunBackgroundInventoryAllocationJob();
	UpdateHyperlinkToLayout();
EndProcedure

&AtServer
Procedure SetConditionalAppearance()
	
	ConditionalAppearance.Items.Clear();
	
	StandardSubsystemsServer.SetDateFieldConditionalAppearance(ThisObject, "ListRegistered.Date",
		"ListRegisteredDate");
	
EndProcedure

&AtClientAtServerNoContext
Function DefaultFormAssignmentKey()
	
	Return "DocumentsBetweenCompaniesAll";
	
EndFunction

&AtServer
Procedure RestoreSettings(Var_Parameters)
	
	ListOfDocumentsAutoUpdateMode = True;
	
	If Var_Parameters.Property("QuickFilterStructure") Then
		
		FormIsOpenedByHyperlink = True;
		ListFormSelections = Var_Parameters.QuickFilterStructure;
		
		If CommonClientServer.HasAttributeOrObjectProperty(ListFormSelections, "Organization") Then
			Organization = ListFormSelections.Organization;
		Else
			Organization = Undefined;
		EndIf;
		
		If CommonClientServer.HasAttributeOrObjectProperty(ListFormSelections, "StorageLocation") Then
			Warehouse = ListFormSelections.StorageLocation;
		Else
			Warehouse = Undefined;
		EndIf;
		
	Else
		
		FormIsOpenedByHyperlink = False;
		
		ObjectKey = "DataProcessor.LogOfIntercompanyDocuments.Form.ListForm";
		Settings   = Common.CommonSettingsStorageLoad(ObjectKey, PurposeUseKey);
		
		If Settings <> Undefined Then
			
			Organization = Settings.Organization;
			Warehouse       = Settings.Warehouse;
			Period      = Settings.Period;
			
			FilterDocumentTypes        = Settings.FilterDocumentTypes;
			FilterBusinessTransactions = Settings.FilterBusinessTransactions;
			
			If TypeOf(Settings) = Type("Structure") And Settings.Property("ListOfDocumentsAutoUpdateMode") Then
				ListOfDocumentsAutoUpdateMode = Settings.ListOfDocumentsAutoUpdateMode;
			EndIf;
			
		EndIf;
		
	EndIf;
	
EndProcedure

&AtServer
Procedure ConfigureFormForSelectedOperationsAndDocuments(VTBusinessOperationsAndDocuments)
	
	FormAssignmentKey = DefaultFormAssignmentKey();
	FormCaption      = NStr("vi = 'Chứng từ giữa các doanh nghiệp (tất cả)';
							|ru = 'Документы между организациями (все)';
							|en = 'Intercompany sales documents (all)'; fa = 'اسناد فروش درون‌گروهی (همه)';
							|it = 'Documenti tra le società (tutti)';
							|pl = 'Dokumenty międzyfirmowe (wszystkie)';
							|tr = 'İş yerleri arasındaki belgeler (tümü)'");
	
	WorkplaceData = TMCommonUse.WorkplaceData(VTBusinessOperationsAndDocuments, FormAssignmentKey,
		FormCaption);
	
	Title = WorkplaceData.WorkplaceTitle;
	
	// Document verificationreferences
	DocumentVerificationServer.ModifyDynamicDocumentLogListRequest(ListRegistered.QueryText, "DocumentsRegistry");
	SetDynamicListSelections_();
	SetVisibilityAvailability();
	
	TMCommonUse.FormInscriptionSelection(HelpTextFilter, BusinessTransactionsAndDocuments,
		FilterDocumentTypes, FilterBusinessTransactions);
	
	ConfigureDocumentManagementButtons();
	
EndProcedure

&AtServer
Procedure SetDynamicListSelections_()
	
	CommonClientServer.SetDynamicListFilterItem(ListRegistered, "RefType",
		FilterDocumentTypes, DataCompositionComparisonType.InList, Undefined, True);
	
	CommonClientServer.SetDynamicListFilterItem(ListRegistered, "BusinessOperation",
		FilterBusinessTransactions, DataCompositionComparisonType.InList, Undefined, True);
	
	SetSelectionByOrganization();
	SetSelectionByWarehouse();
	SetSelectionByPeriod();
	
	// DynamicListsSettings
	OperationsWithDocumentJournals.SetVisibilityOfDefaultUpdateSettingsGroup(ThisObject, "ListRegistered");
	// End DynamicListsSettings
	
	UpdateHyperlinkToLayout();
	
EndProcedure

&AtServer
Procedure SetSelectionByOrganization()
	
	If Not RestrictionByCompanyIsUsed Then
		CommonClientServer.SetDynamicListFilterItem(ListRegistered, "AdditionalRecord",
			False, DataCompositionComparisonType.Equal, Undefined, Not ValueIsFilled(Organization));
	EndIf;
	
	CompaniesList = New ValueList;
	CompaniesList.Add(Organization);
	
	If ValueIsFilled(Organization)
		And GetFunctionalOption("UseBranchOfficesWithSeparateBalanceSheets") Then
		
		Query = New Query;
		Query.Text =
		"SELECT ALLOWED
		|	Companies.Ref
		|FROM
		|	Catalog.Companies AS Companies
		|WHERE
		|	Companies.BranchOffice
		|	AND Companies.ParentCompany = &Organization
		|	AND Companies.TransactionsUsingParentCompanyAreAllowed";
		
		Query.SetParameter("Organization", Organization);
		
		Selection = Query.Execute().Select();
		
		While Selection.Next() Do
			CompaniesList.Add(Selection.Ref);
		EndDo;
		
	EndIf;
	
	CommonClientServer.SetDynamicListFilterItem(ListRegistered, "Organization",
		CompaniesList, DataCompositionComparisonType.InList, Undefined, ValueIsFilled(Organization));
	
	// DynamicListsSettings
	OperationsWithDocumentJournals.SetVisibilityOfDefaultUpdateSettingsGroup(ThisObject, "ListRegistered");
	// End DynamicListsSettings
	
EndProcedure

&AtServer
Procedure SetSelectionByWarehouse()
	
	FilterWarehouses = WarehousesServer.ListOfSubordinateWarehouses(Warehouse);
	FilterStorageLocations_ = Catalogs.DocumentRegistryKeys.KeysByValue(FilterWarehouses);
	
	CommonClientServer.SetDynamicListFilterItem(ListRegistered,
																			"StorageLocation",
																			FilterStorageLocations_,
																			DataCompositionComparisonType.InList,
																			,
																			ValueIsFilled(FilterStorageLocations_));
																			
	// DynamicListsSettings
	OperationsWithDocumentJournals.SetVisibilityOfDefaultUpdateSettingsGroup(ThisObject, "ListRegistered");
	// End DynamicListsSettings
	
EndProcedure

&AtServer
Procedure SetSelectionByPeriod()
	
	EndOfPeriod = ?(ValueIsFilled(Period.EndDate), Period.EndDate, Date(2999, 12, 31));
	
	If Period.StartDate > EndOfPeriod Then
		Raise NStr("vi = 'Ngày bắt đầu Kỳ không thể dài hơn ngày kết thúc';
					|ru = 'Дата начала периода не может быть больше даты окончания периода';
					|en = 'The period start date cannot be greater than the period end date'; fa = 'The period start date cannot be greater than the period end date';
					|it = 'La data di inizio periodo non può essere superiore alla data del termine periodo';
					|pl = 'Data rozpoczęcia okresu nie może być dłuższa niż data zakończenia okresu';
					|tr = 'Dönemin başlangıç tarihi, dönemin bitiş tarihinden büyük olamaz'");
	EndIf;
	
	ListRegistered.Parameters.SetParameterValue("BeginOfPeriod", Period.StartDate);
	ListRegistered.Parameters.SetParameterValue("EndOfPeriod", 
		?(ValueIsFilled(Period.EndDate), Period.EndDate, EndOfDay(Date(3999, 12, 31))));
	
	// DynamicListsSettings
	OperationsWithDocumentJournals.SetVisibilityOfDefaultUpdateSettingsGroup(ThisObject, "ListRegistered");
	// End DynamicListsSettings
	
EndProcedure

#Region HyperlinkToDesign

&AtServer
Procedure UpdateHyperlinkToLayout()
	
	// Checking whether the form element should be displayed to the form
	Filter = New Structure("Filter", True);
	BsnsTransactionsAndDocuments = BusinessTransactionsAndDocuments.FindRows(Filter);
	
	YouNeedHyperlinkToDesign = False;
	
	For Each String In BsnsTransactionsAndDocuments Do
		If ValueIsFilled(String.HyperlinkCalculationManagerForRegistration) Then
			YouNeedHyperlinkToDesign = True;
			Break;
		EndIf;
	EndDo;
	
	GenerationParameters = New Structure;
	GenerationParameters.Insert("Organization",          Organization);
	GenerationParameters.Insert("Warehouse",                Warehouse);
	GenerationParameters.Insert("ThisIsHyperlinkCalculation", True);
	GenerationParameters.Insert("PurposeUseKey", DefaultFormAssignmentKey());
	
	If YouNeedHyperlinkToDesign Then
	
		Items.ToRegister.Visible = True;
		TextIsUpdatingData = NStr("vi = 'Cần lập: <dữ liệu đang được cập nhật>';
									|ru = 'К оформлению: <идет обновление данных>';
									|en = 'To register: <updating data>'; fa = 'To register: <updating data>';
									|it = 'Da formalizzare: <dati in fase di aggiornamento>';
									|pl = 'Do rejestracji: <odbywa się aktualizacja danych>';
									|tr = 'Düzenlenecek: <veri güncellemesi devam ediyor>'");
		ToRegister = New FormattedString(TextIsUpdatingData);
		
		JobParameters = New Array;
		JobParameters.Add(BusinessTransactionsAndDocuments.Unload());
		JobParameters.Add(GenerationParameters);
		
		CalculationProcedure_ = "DataProcessors.LogOfIntercompanyDocuments.CreateHyperlinkToBackgroundTaskLayout";
		
		ExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(UUID);
		ExecutionParameters.WaitCompletion = 0;
		ExecutionParameters.RunInBackground = True;
		CalculationResult2 = TimeConsumingOperations.ExecuteInBackground(CalculationProcedure_,
		                                                     JobParameters,
		                                                     ExecutionParameters);
		
		If CalculationResult2.Status = "Completed2" Then
			UpdateHyperlinkToLayoutCompletion(CalculationResult2.ResultAddress, ToRegister);
			ResultOfFormationOfHyperlinksToDesign = Undefined;
		Else
			ResultOfFormationOfHyperlinksToDesign = CalculationResult2;
		EndIf;
	Else
		Items.ToRegister.Visible = False;
	EndIf;
	
	ArrayCalculationManagersSeeAlsoInWork = New Array();
	ArrayCalculationManagersSeeAlsoInWork.Add("DataProcessor.GenerationOfIntercompanyCustomerInvoicesAndRedemption");
	
	FormEvents.WhenChangingElement(ThisObject, "SeeAlsoInProgress", ArrayCalculationManagersSeeAlsoInWork);
	
	SeeAlsoInProgress = TMCommonUse.CreateHyperlinkSeeAlsoIn(ArrayCalculationManagersSeeAlsoInWork, GenerationParameters);
	Items.SeeAlsoInProgress.Visible = ValueIsFilled(SeeAlsoInProgress);
	
EndProcedure

&AtClientAtServerNoContext
Procedure UpdateHyperlinkToLayoutCompletion(Val StorageAddress,ToRegister)
	
	ToRegister = GetFromTempStorage(StorageAddress);
	
	If Not ValueIsFilled(ToRegister) Then
		TextIsUpdatingData = NStr("vi = 'Cần lập: không';
									|ru = 'К оформлению: нет';
									|en = 'To register: no'; fa = 'To register: no';
									|it = 'Da formalizzare: no';
									|pl = 'Do rejestracji: brak';
									|tr = 'Düzenlenecek: yok'");
		ToRegister = New FormattedString(TextIsUpdatingData);
	EndIf;
	
EndProcedure

&AtClient
Procedure ConnectHyperlinkWaitingHandlerToLayout()
	
	If ResultOfFormationOfHyperlinksToDesign <> Undefined Then
		IdleParameters = TimeConsumingOperationsClient.IdleParameters(ThisObject);
		IdleParameters.OutputIdleWindow = False;
		CallbackOnCompletion = New CallbackDescription("UpdateHyperlinkToNotificationDesign", ThisObject);
	
		TimeConsumingOperationsClient.WaitCompletion(
			ResultOfFormationOfHyperlinksToDesign, CallbackOnCompletion, IdleParameters);
	EndIf;
	
EndProcedure

&AtClient
Procedure UpdateHyperlinkToNotificationDesign(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	If Result.Status = "Completed2" Then
		UpdateHyperlinkToLayoutCompletion(Result.ResultAddress, ToRegister);
	EndIf;
	
EndProcedure

#EndRegion

&AtServer
Procedure OrganizationOnChangeServer()
	
	SetSelectionByOrganization();
	UpdateHyperlinkToLayout();

EndProcedure

&AtServer
Procedure WarehouseOnChangeServer()
	
	SetSelectionByWarehouse();
	UpdateHyperlinkToLayout();
	
EndProcedure

&AtServer
Procedure SetVisibilityAvailability()
	
	If Not GetFunctionalOption("UseMultipleCompanies") Then
		Items.Organization.Visible = False;
	EndIf;
	
	If Not GetFunctionalOption("UseSeveralWarehouses") Then
		Items.Warehouse.Visible = False;
	EndIf;
	
	If Not GetFunctionalOption("UseMultipleCurrencies") Then
		Items.ListRegisteredCurrency.Visible = False;
	EndIf;
	
	Items.ListRegisteredContract.Visible = GetFunctionalOption("UseIntercompanyContracts");
	Items.ListRegisteredCounterparty.Visible = GetFunctionalOption("UsePartnersAndCounterparties");
	
EndProcedure

&AtServer
Procedure ConfigureDocumentManagementButtons()
	
	ParametersStructure = TMCommonUse.StructureOfSettingsForDocumentManagementButtons();
	ParametersStructure.Form                                             = ThisForm;
	ParametersStructure.NameOfCopyButton                              = "ListCopy";
	ParametersStructure.NameOfCopyContextMenuButton               = "ListCopy1";
	ParametersStructure.ChangeButtonName                                 = "ListChange";
	ParametersStructure.NameOfChangeContextMenuButton                  = "ListChange1";
	ParametersStructure.ButtonNamePost                                 = "ListPost";
	ParametersStructure.NameOfHoldContextMenuButton                  = "ListPost1";
	ParametersStructure.NameOfCancelEventButton                         = "ListUndoPosting";
	ParametersStructure.NameOfCancelButtonIsContextMenu          = "ListUndoPosting1";
	ParametersStructure.NameOfMarkDeleteButton                = "ListSetDeletionMark";
	ParametersStructure.ButtonNameMarkDeleteContextMenu = "ListSetDeletionMark1";
	
	TMCommonUse.ConfigureDocumentManagementButtons(ParametersStructure);
	
EndProcedure

&AtServer
Procedure ShouldSaveSettings()
	
	If FormIsOpenedByHyperlink Then
		Return;
	EndIf;
	
	ObjectKey = "DataProcessor.LogOfIntercompanyDocuments.Form.ListForm";
	AttributesToSaveNames = "Organization,Warehouse,Period,FilterBusinessTransactions,FilterDocumentTypes, ListOfDocumentsAutoUpdateMode";
	
	Settings = New Structure(AttributesToSaveNames);
	FillPropertyValues(Settings, ThisForm);
	
	Common.CommonSettingsStorageSave(ObjectKey, PurposeUseKey, Settings);
	
EndProcedure

#Region BarcodesAndTradeEquipment

&AtClient
Procedure ProcessBarcodes(Data)
	
	StateText = NStr("vi = 'Đang tìm kiếm chứng từ theo mã vạch...';
					|ru = 'Выполняется поиск документа по штрихкоду...';
					|en = 'Searching for the document by barcode...'; fa = 'Searching for the document by barcode...';
					|it = 'Viene effettuata la ricerca del documento per codice a barre...';
					|pl = 'Wyszukiwanie dokumentu według kodu kreskowego...';
					|tr = 'Belge barkoda göre aranıyor...'");
	Status(StateText);
	
	BarcodeData = BarcodeDataOfPrintedForm(Data.Barcode, "ListRegistered");
	TMCommonUseClient.ProcessBarcodes(Data.Barcode, BarcodeData, ThisForm, "ListRegistered");
	
EndProcedure

&AtServer
Function BarcodeDataOfPrintedForm(Barcode, ListName = "")
	
	ThereIsMainTableOfList = OperationsWithDocumentJournals.ThereIsMainTableOfList(ThisObject, ListName);
	
	VTBusinessOperationsAndDocuments = BusinessTransactionsAndDocuments.Unload();
	BarcodeData = TMCommonUse.BarcodeDataOfPrintedForm(Barcode, VTBusinessOperationsAndDocuments, ThereIsMainTableOfList);
	
	Return BarcodeData;
	
EndFunction

#EndRegion

#Region WorkingWithCachedValues

&AtServer
Function PlaceBusinessTransactionsAndDocumentsInTemporaryStorage()
	
	Return PutToTempStorage(BusinessTransactionsAndDocuments.Unload(), UUID);
	
EndFunction

#EndRegion

&AtServer
Procedure SelectionOperationTypeSelectionProcessingServer(AddressOfAvailableBusinessTransactionsAndDocuments)
	
	VTBusinessOperationsAndDocuments = GetFromTempStorage(AddressOfAvailableBusinessTransactionsAndDocuments);
	BusinessTransactionsAndDocuments.Load(VTBusinessOperationsAndDocuments);
	
	TMCommonUse.FillInSelectionsAccordingToTableOfBusinessTransactionsAndDocumentTypes(VTBusinessOperationsAndDocuments,
		FilterBusinessTransactions, FilterDocumentTypes);
	
	ConfigureFormForSelectedOperationsAndDocuments(VTBusinessOperationsAndDocuments);
	
EndProcedure

#Region DynamicListsSettings

&AtServer
Procedure InitiateDynamicListSettings()
	
	DocumentListParameters = New Array;
	
	ListParameterStructure = OperationsWithDocumentJournals.StructureOfFormationOfGroupOfUserSettingsForDynamicListOnForm();
	ListParameterStructure.ListName = "ListRegistered";
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
