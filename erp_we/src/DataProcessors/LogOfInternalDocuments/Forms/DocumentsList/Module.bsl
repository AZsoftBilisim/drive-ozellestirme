
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
	
	If IsBlankString(Parameters.FormAssignmentKey) Then
		PurposeUseKey = DefaultFormAssignmentKey();
	Else
		PurposeUseKey = Parameters.FormAssignmentKey;
	EndIf;
	
	If PurposeUseKey = DefaultFormAssignmentKey() Then
		SettingsKey = "";
	Else
		SettingsKey = PurposeUseKey;
	EndIf;
	
	URL = "e1cib/command/DataProcessor.LogOfInternalDocuments.Command.InternalInventoryTransfers";
	
	RestoreSettings(Parameters);
	
	VTBusinessTransactionsAndDocumentTypes = TMCommonUse.AvailableBusinessTransactionsAndDocuments(DescriptionOfOperationsAndDocumentTypes(),
		FilterBusinessTransactions, FilterDocumentTypes, SettingsKey);
	
	BusinessTransactionsAndDocuments.Load(VTBusinessTransactionsAndDocumentTypes);
	
	FormCaption = Parameters.FormCaption;
	If Not ValueIsFilled(FormCaption) Then
		FormCaption = NStr("vi = 'Chứng từ nội bộ (tất cả)';
							|ru = 'Внутренние документы (все)';
							|en = 'Internal documents (all)'; fa = 'اسناد داخلی (همه)';
							|it = 'Внутренние документы (все)';
							|pl = 'Dokumenty na rozchód materiałów  (wszystkie)';
							|tr = 'Dahili belgeler (tümü)'");
	EndIf;
	Title = FormCaption;
	
	RestrictionByWarehouseIsUsed = AccessManagementInternal.HasTableRestrictionByAccessKind(
		"InformationRegister.DocumentsRegistry", "Warehouses", "PartnerGroups,Companies,Departments,Warehouses");
	ConfigureFormForSelectedOperationsAndDocuments(VTBusinessTransactionsAndDocumentTypes);
	
	DocumentTypesUsed = VTBusinessTransactionsAndDocumentTypes.UnloadColumn("DocumentType");
	DocumentTypesUsed.Add(Type("DocumentRef.ReversingEntry"));
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject, Items.GlobalCommandsGroup);
	// End IntegrationWith1CDocumentManagementSubsystem
	
	// Document verificationreferences
	ListProperties = Common.DynamicListPropertiesStructure();
	FillPropertyValues(ListProperties, ListDocumentsOfInternalGoodsMovement);
	DocumentVerificationServer.ModifyDynamicDocumentLogListRequest(ListProperties.QueryText, "DocumentsRegistryOverridable");
	Common.SetDynamicListProperties(Items.ListDocumentsOfInternalGoodsMovement, ListProperties);
	// End Document verificationreferences
	
	DocumentTypesUsed.Add(Type("DocumentRef.ReversingEntry"));
	
	
	// StandardSubsystems.AttachableCommands
	PlacementParameters = AttachableCommands.PlacementParameters();
	PlacementParameters.Sources = New TypeDescription(DocumentTypesUsed);
	PlacementParameters.CommandBar = Items.ListDocumentsOfInternalGoodsMovementCommandBar;
	AttachableCommands.OnCreateAtServer(ThisObject, PlacementParameters);
	// End StandardSubsystems.AttachableCommands
	
	AdditionalParameters = New Structure("LocationOfLocalValidationData", Items.ReglGroupVerification);
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing, AdditionalParameters);
	
	// StandardSubsystems.SourceDocumentsOriginalsRecording
	SourceDocumentsOriginalsRecording.OnCreateAtServerListForm(ThisObject,Items.ListDocumentsOfInternalGoodsMovement, Items.ListDocumentsOfInternalGoodsMovementOrganization);
	// End StandardSubsystems.SourceDocumentsOriginalsRecording
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	ConnectHyperlinkWaitingHandlerToLayout();
	
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
	
	
	If EventName = "Write_DiscrepancyReportFollowingTransfer"
		Or EventName = "Write_InventoryConsumption"
		Or EventName = "Write_ReturnOfMaterialsFromProduction"
		Or EventName = "Write_ProductsRelease"
		Or EventName = "Write_MaterialTransferToProduction"
		Or EventName = "Write_MovementOfProductsAndMaterials"
		Or EventName = "Write_InventorySurplusRecognition"
		Or EventName = "Write_InventoryTransfer"
		Or EventName = "Write_GoodsMisgrading"
		Or EventName = "Write_GoodsDamage"
		Or EventName = "Write_OtherGoodsRecordingAsReceived"
		Or EventName = "Write_AssemblyFromComponents"
		Or EventName = "Write_WriteOffOfGoodsShortages"
		Or EventName = "Conducting_Storno"
		Or EventName = "Write_ReversingEntry" Then
		
		// DynamicListsSettings
		UpdateListOfDocumentsEventNotificationProcessing("ListDocumentsOfInternalGoodsMovement", Parameter);
		// End DynamicListsSettings
		
		UpdateHyperlinkToLayout();
		ConnectHyperlinkWaitingHandlerToLayout();
		
	ElsIf EventName = "Write_InventoryConsumptionOrder"
		Or EventName = "Write_OrderOfMaterialsForProduction"
		Or EventName = "Write_ProductionOrder"
		Or EventName = "Write_RMOrder"
		Or EventName = "Write_ProductionStages"
		Or EventName = "Write_TransferOrder"
		Or EventName = "Write_ByAssemblyDisassemblyOrder"
		Or EventName = "Write_GoodsIssueNote"
		Or EventName = "Write_GoodsReceiptNote"
		Or EventName = "Write_InventoryRecount" Then
		
		UpdateHyperlinkToLayout();
		ConnectHyperlinkWaitingHandlerToLayout();
		
	EndIf;
	
	// StandardSubsystems.SourceDocumentsOriginalsRecording
	SourceDocumentsOriginalsRecordingClient.NotificationHandlerListForm(EventName, ThisObject, Items.ListDocumentsOfInternalGoodsMovement);
	// End StandardSubsystems.SourceDocumentsOriginalsRecording
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure OrganizationOnChange(Item)
	
	OrganizationWhenChangedOnServer();
	ConnectHyperlinkWaitingHandlerToLayout();
	
EndProcedure

&AtClient
Procedure WarehouseOnChange(Item)
	
	WarehouseWhenChangedOnServer();
	ConnectHyperlinkWaitingHandlerToLayout();
	
EndProcedure

&AtClient
Procedure ManagerOnChange(Item)
	
	CommonClientServer.SetDynamicListFilterItem(ListDocumentsOfInternalGoodsMovement,
		"Manager",
		Manager,
		DataCompositionComparisonType.Equal,,
		ValueIsFilled(Manager));
	
	UpdateHyperlinkToLayout();
	ConnectHyperlinkWaitingHandlerToLayout();
	
	// DynamicListsSettings
	OperationsWithDocumentJournalsClient.SetVisibilityOfDefaultUpdateSettingsGroup(ThisObject, "ListDocumentsOfInternalGoodsMovement");
	// End DynamicListsSettings
	
EndProcedure

&AtClient
Procedure HelpTextFilterURLProcessing(Item, FormattedStringURL, StandardProcessing)
	
	StandardProcessing = False;
	
	FormParameters = New Structure();
	FormParameters.Insert("AvailableBusinessTransactionsAndDocuments", PlaceBusinessTransactionsAndDocumentsInTemporaryStorage());
	FormParameters.Insert("SettingsKey", PurposeUseKey);
	FormParameters.Insert("FormKey", DefaultFormAssignmentKey());
	
	OpenForm("Catalog.BusinessTransactionsSettings.Form.FormOfFilterSetting",
		FormParameters,,,,,
		New CallbackDescription("EstablishSelectionsForBusinessTransactionsAndDocuments", 
		ThisObject));
	
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
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.StartTimeMeasurement(True,
		"DataProcessor.LogOfInternalDocuments.Form.DocumentsList.Event.ToRegisterURLProcessing");
	
	StandardProcessing = False;
	
	FormParameters = New Structure;
	QuickFilterStructure = New Structure;
	QuickFilterStructure.Insert("Organization",	Organization);
	QuickFilterStructure.Insert("Warehouse",		Warehouse);
	QuickFilterStructure.Insert("Manager",	Manager);
	QuickFilterStructure.Insert("FilterDocumentTypes",			FilterDocumentTypes);
	QuickFilterStructure.Insert("FilterBusinessTransactions",	FilterBusinessTransactions);
	FormParameters.Insert("QuickFilterStructure", QuickFilterStructure);
	
	FormParameters.Insert("FixedSettings", Undefined);
	FormParameters.Insert("UserSettings", New DataCompositionUserSettings);
	FormParameters.Insert("GenerateOnOpen", True);
	FormParameters.Insert("ReportOptionsCommandsVisibility", False);
	If ValueIsFilled(Warehouse) Then
		VariantKey = "RegistrationOfSurplusShortagesContext";
		FormParameters.Insert("Warehouse", Warehouse);
		FormParameters.Insert("Filter", New Structure("Warehouse", Warehouse));
	Else
		VariantKey = "RegistrationOfSurplusShortages";
	EndIf;
	FormParameters.Insert("VariantKey", VariantKey);
	
	
	OpenForm(FormattedStringURL, FormParameters);
	
EndProcedure

&AtClient
Procedure SeeAlsoInProgressURLProcessing(Item, FormattedStringURL, StandardProcessing)
	
	StandardProcessing = False;
	
	FormParameters = New Structure;
	
	
	OpenForm(FormattedStringURL, FormParameters, ThisForm, ThisForm.UUID);
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersListRegistered

&AtClient
Procedure ListBeforeAddRow(Item, Cancel, Copy, Parent, Var_Group, Parameter)
	
	If Items.CreateGroupGenerated.ChildItems.Count() <> 0 Then 
		If Copy Then
			TMCommonUseClient.CopyItem(Item);
		ElsIf FilterDocumentTypes.Count() = 1 And FilterBusinessTransactions.Count() = 1 Then 
			TeamStructure_ = New Structure("Name", Items.CreateGroupGenerated.ChildItems[0].Name);
			Attachable_CreateDocument(TeamStructure_);
		Else
			Attachable_CreateDocumentViaSelectionForm(Undefined);
		EndIf;
	EndIf;
	Cancel = True;

EndProcedure

&AtClient
Procedure ListOnActivateRow(Item)
	
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	
EndProcedure

&AtClient
Procedure ListSelection(Item, RowSelected, Field, StandardProcessing)
	
	StandardProcessing = False;
	
	If Field.Name = "SourceDocumentOriginalState" Or Field.Name = "StateOriginalReceived" Then
		// StandardSubsystems.SourceDocumentsOriginalsRecording
		SourceDocumentsOriginalsRecordingClient.ListSelection(Field.Name,ThisObject,Items.ListDocumentsOfInternalGoodsMovement, StandardProcessing);
		// End StandardSubsystems.SourceDocumentsOriginalsRecording
		Return;
	EndIf;
	
	TMCommonUseClient.ChangeElement(Item);
	
	
EndProcedure

&AtClient
Procedure ListBeforeRowChange(Item, Cancel)
	
	Cancel = True;
	TMCommonUseClient.ChangeElement(Item);
	
EndProcedure

&AtClient
Procedure ListBeforeDeleteRow(Item, Cancel)
	
	Cancel = True;
	Notification = New CallbackDescription("ListSetDeletionMarkCompletion", ThisObject);
	TMCommonUseClient.SetDeletionMark(Item, Title, Notification);
	
EndProcedure

&AtServerNoContext
Procedure ListDocumentsOfInternalGoodsMovementOnGetDataAtServer(TagName, Settings, Rows)
	
	// StandardSubsystems.SourceDocumentsOriginalsRecording
	SourceDocumentsOriginalsRecording.OnGetDataAtServer(Rows);
	// End StandardSubsystems.SourceDocumentsOriginalsRecording

EndProcedure

&AtServer
Procedure ListDocumentsOfInternalGoodsMovementOnUpdateUserSettingSetAtServer(Item, StandardProcessing)
	
	// DynamicListsSettings
	OperationsWithDocumentJournals.SetVisibilityOfDefaultUpdateSettingsGroup(ThisObject, "ListDocumentsOfInternalGoodsMovement");
	// End DynamicListsSettings
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

#Region CreateButton

&AtClient
Procedure Attachable_CreateDocument(Command)
	
	FilterStructure1 = New Structure;
	FilterStructure1.Insert("Organization",Organization);
	FilterStructure1.Insert("Warehouse",Warehouse);
	TMCommonUseClient.CreateDocumentUsingCommand(Command.Name, FilterStructure1);
	
EndProcedure

&AtClient
Procedure Attachable_CreateDocumentViaSelectionForm(Command)
	FormKey = DefaultFormAssignmentKey();
	AddressBusinessTransactionsAndDocuments = PlaceBusinessTransactionsAndDocumentsInTemporaryStorage();
	FilterStructure1 = New Structure;
	FilterStructure1.Insert("Organization",Organization);
	FilterStructure1.Insert("Warehouse",Warehouse);
	TMCommonUseClient.CreateDocumentViaSelectionForm(AddressBusinessTransactionsAndDocuments,
		FormKey, PurposeUseKey, FilterStructure1);
EndProcedure

#EndRegion

&AtClient
Procedure ListCopy(Command)
	
	TMCommonUseClient.CopyItem(Items.ListDocumentsOfInternalGoodsMovement);
	
EndProcedure

&AtClient
Procedure ListChange(Command)
	
	TMCommonUseClient.ChangeElement(Items.ListDocumentsOfInternalGoodsMovement);
	
EndProcedure

&AtClient
Procedure ListSetDeletionMark(Command)
	
	Notification = New CallbackDescription("ListSetDeletionMarkCompletion", ThisObject);
	TMCommonUseClient.SetDeletionMark(Items.ListDocumentsOfInternalGoodsMovement, Title,
		Notification, OperationsWithDocumentJournalsClient.ParametersForUpdatingDocumentList(ThisObject,
		"ListDocumentsOfInternalGoodsMovement"));
	
EndProcedure

&AtClient
Procedure ListUndoPosting(Command)
	
	TMCommonUseClient.UndoPosting(Items.ListDocumentsOfInternalGoodsMovement, Title,
		OperationsWithDocumentJournalsClient.ParametersForUpdatingDocumentList(ThisObject,
		"ListDocumentsOfInternalGoodsMovement"));
	ListUndoPostingServer();
	ConnectHyperlinkWaitingHandlerToLayout();
	
EndProcedure

&AtClient
Procedure ListPost(Command)
	
	TMCommonUseClient.PostDocuments(Items.ListDocumentsOfInternalGoodsMovement, Title,
		OperationsWithDocumentJournalsClient.ParametersForUpdatingDocumentList(ThisObject,
		"ListDocumentsOfInternalGoodsMovement"));
	ListPostServer();
	ConnectHyperlinkWaitingHandlerToLayout();
	
EndProcedure

// StandardSubsystems.AttachableCommands
&AtClient
Procedure Attachable_ExecuteCommand(Command)
	AttachableCommandsClient.ExecuteCommand(ThisObject, Command, Items.ListDocumentsOfInternalGoodsMovement);
EndProcedure

&AtServer
Procedure Attachable_ExecuteCommandAtServer(Context, Result) Export
	AttachableCommands.ExecuteCommand(ThisObject, Context, Items.ListDocumentsOfInternalGoodsMovement, Result);
EndProcedure

&AtClient
Procedure Attachable_UpdateCommands()
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Items.ListDocumentsOfInternalGoodsMovement);
EndProcedure
// End StandardSubsystems.AttachableCommands

// IntegrationWith1CDocumentManagementSubsystem
&AtClient
Procedure Attachable_ExecuteIntegrationCommand(Command)
	
	IntegrationWith1CDocumentManagementCoreClient.ExecutePlugInIntegrationCommand(Command, ThisObject, Items.ListDocumentsOfInternalGoodsMovement);
	
EndProcedure
// End IntegrationWith1CDocumentManagementSubsystem


&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

&AtClient
Procedure SetDateInterval(Command)
	
	Notification = New CallbackDescription("SetDateIntervalCompletion", ThisObject);
	
	TMCommonUseClient.EditPeriod(Period, , Notification);
	
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
Procedure Attachable_SetStatus(Command)
	
	TMCommonUseClient.SetStatus(Command.Name, CorrespondenceOfCommandsToStatuses,
		Items.ListDocumentsOfInternalGoodsMovement,
		OperationsWithDocumentJournalsClient.ParametersForUpdatingDocumentList(ThisObject, "ListDocumentsOfInternalGoodsMovement"));
	
EndProcedure

// StandardSubsystems.SourceDocumentsOriginalsRecording
&AtClient
Procedure Attachable_UpdateOriginalStateCommands()
	
	UpdateOriginalStateCommands()
   
EndProcedure

&AtServer
Procedure UpdateOriginalStateCommands()
	
	If PurposeUseKey = DefaultFormAssignmentKey() Then
		SettingsKey = "";
	Else
		SettingsKey = PurposeUseKey;
	EndIf;

	VTBusinessTransactionsAndDocumentTypes = TMCommonUse.AvailableBusinessTransactionsAndDocuments(DescriptionOfOperationsAndDocumentTypes(),
		FilterBusinessTransactions, FilterDocumentTypes, SettingsKey);
		
	DocumentTypesUsed = VTBusinessTransactionsAndDocumentTypes.UnloadColumn("DocumentType");
	DocumentTypesUsed.Add(Type("DocumentRef.ReversingEntry"));

	// StandardSubsystems.AttachableCommands
	PlacementParameters = AttachableCommands.PlacementParameters();
	PlacementParameters.Sources = New TypeDescription(DocumentTypesUsed);
	PlacementParameters.CommandBar = Items.ListDocumentsOfInternalGoodsMovementCommandBar;
	AttachableCommands.OnCreateAtServer(ThisObject, PlacementParameters);
	// End StandardSubsystems.AttachableCommands
		
EndProcedure
//End StandardSubsystems.SourceDocumentsOriginalsRecording

&AtClient
Procedure DocumentsListRefresh(Command)
	
	// DynamicListsSettings
	UpdateDocumentListDataWithTimeMeasurement("ListDocumentsOfInternalGoodsMovement");
	// End DynamicListsSettings
	
EndProcedure

#EndRegion

#Region Private

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
	BarcodeData = BarcodeDataOfPrintedForm(Data.Barcode, "ListDocumentsOfInternalGoodsMovement");
	TMCommonUseClient.ProcessBarcodes(Data.Barcode, BarcodeData, ThisForm, "ListDocumentsOfInternalGoodsMovement");
	
EndProcedure

#EndRegion

&AtClient
Procedure ListSetDeletionMarkCompletion(Result, AdditionalParameters) Export
	
	If Result = DialogReturnCode.Yes Then
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
	
	//
	
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ListDocumentsOfInternalGoodsMovementStatus.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ThereAreDocumentsUsingAStatus");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;

	Item.Appearance.SetParameterValue("Visible", False);
	
	StandardSubsystemsServer.SetDateFieldConditionalAppearance(ThisObject, "ListDocumentsOfInternalGoodsMovement.Date", "Date");
	
EndProcedure

&AtClientAtServerNoContext
Function DefaultFormAssignmentKey()
	
	Return "InternalInventoryTransfers";
	
EndFunction

&AtServer
Procedure RestoreSettings(Var_Parameters)
	
	ListOfDocumentsAutoUpdateMode = True;
	
	If Var_Parameters.Property("ListFormSelections") Then
		FillPropertyValues(ThisForm, FormSettings(Var_Parameters.ListFormSelections));
	ElsIf Var_Parameters.Property("QuickFilterStructure") Then
		FillPropertyValues(ThisForm, FormSettings(Var_Parameters.QuickFilterStructure));
	Else
		SettingsFromStorage = Common.CommonSettingsStorageLoad(
			"DataProcessor.LogOfInternalDocuments.Form.DocumentsList", PurposeUseKey);
		
		If TypeOf(SettingsFromStorage) = Type("Structure") Then
			FillPropertyValues(ThisForm, FormSettings(SettingsFromStorage));
			If SettingsFromStorage.Property("ListOfDocumentsAutoUpdateMode") Then
				ListOfDocumentsAutoUpdateMode = SettingsFromStorage.ListOfDocumentsAutoUpdateMode;
			EndIf;
		EndIf;
	EndIf;
	
EndProcedure

&AtServer
Procedure ShouldSaveSettings()
	
	Common.CommonSettingsStorageSave("DataProcessor.LogOfInternalDocuments.Form.DocumentsList",
		PurposeUseKey, FormSettings(ThisForm));
	
EndProcedure

&AtServer
Function FormSettings(SettingsSource)
	
	AttributesToSaveNames =
		"Organization,
		|Warehouse,
		|Manager,
		|Period,
		|FilterBusinessTransactions,
		|FilterDocumentTypes,
		|ListOfDocumentsAutoUpdateMode";
	
	Settings = New Structure(AttributesToSaveNames);
	FillPropertyValues(Settings, SettingsSource);
	
	Return Settings;
	
EndFunction

&AtServer
Procedure CalculateNeedToDisplayColumns()
	
	InvoicesWithStatuses = BusinessTransactionsAndDocuments.FindRows(New Structure("Filter, StatusesAreUsed", True, True));
	
	ThereAreDocumentsUsingAStatus = InvoicesWithStatuses.Count() <> 0;
	
EndProcedure

&AtServer
Function DescriptionOfOperationsAndDocumentTypes()
	
	VTBusinessTransactionsAndDocumentTypes = DataProcessors.LogOfInternalDocuments.DescriptionOfOperationsAndDocumentTypes(BusinessTransactionsAndDocuments.Unload(New Array));
	
	DescriptionOfOperationsAndDocumentTypesByFormOpeningParameter(VTBusinessTransactionsAndDocumentTypes);
	
	Return VTBusinessTransactionsAndDocumentTypes;
	
EndFunction

// Changes the composition of business transactions and types of documents, leaving only the transferred ones.
// The possible title of the business transaction form is also filled in.
//
// Parameters:
//   VTBusinessTransactionsAndDocumentTypes - ValueTable - See DescriptionOfOperationsAndDocumentTypes.
//   The operations used are undefined - the form parameter is not filled in.
//                           - Map of KeyAndValue - Business transactions used:
//     * Key  - EnumRef.BusinessTransactions - the business transaction used;
//     * Value - Map of KeyAndValue - types of documents used:
//       ** Key     - String - full name of the document for which the current business transaction is used;
//       ** Value - String - the title of the form when selecting the current business transaction and the type of document.
//
&AtServer
Procedure DescriptionOfOperationsAndDocumentTypesByFormOpeningParameter(VTBusinessTransactionsAndDocumentTypes)

	If Parameters.Property("UsedHouseholdOfOperations")
			And ValueIsFilled(Parameters.UsedHouseholdOfOperations) Then
		LinesToDelete = New Array;
		ThereAreSelectionLines = False;

		For Each HouseholdDataOfOperations In VTBusinessTransactionsAndDocumentTypes Do
			HouseholdDocumentsOfOperations = Parameters.UsedHouseholdOfOperations[HouseholdDataOfOperations.BusinessOperation];
			If HouseholdDocumentsOfOperations = Undefined Then
				LinesToDelete.Add(HouseholdDataOfOperations);
			Else
				WorkplaceTitle = HouseholdDocumentsOfOperations[HouseholdDataOfOperations.FullDocumentName];
				If WorkplaceTitle = Undefined Then
					LinesToDelete.Add(HouseholdDataOfOperations);
				Else
					If Not IsBlankString(WorkplaceTitle) Then
						HouseholdDataOfOperations.WorkplaceTitle = WorkplaceTitle;
					EndIf;

					If Not ThereAreSelectionLines Then
						ThereAreSelectionLines = HouseholdDataOfOperations.Filter;
					EndIf;
				EndIf;
			EndIf;
		EndDo;

		If LinesToDelete.Count() > 0 Then
			For Each RowToDelete In LinesToDelete Do
				VTBusinessTransactionsAndDocumentTypes.Delete(RowToDelete);
			EndDo;

			If Not ThereAreSelectionLines Then
				VTBusinessTransactionsAndDocumentTypes.FillValues(True, "Filter");
			EndIf;
		EndIf;
	EndIf;

EndProcedure

&AtServer
Procedure ConfigureFormForSelectedOperationsAndDocuments(VTBusinessTransactionsAndDocumentTypes)
	
	WorkplaceData = TMCommonUse.WorkplaceData(VTBusinessTransactionsAndDocumentTypes,
		DefaultFormAssignmentKey(), FormCaption);
	
	Title = WorkplaceData.WorkplaceTitle;
	
	CalculateNeedToDisplayColumns();
	SetDynamicListSelections();
	UpdateHyperlinkToLayout();
	SetVisibilityAvailability();
	
	TMCommonUse.ReplaceLinkFieldWithExpressByDocumentTypeConstruct(
		Items.ListDocumentsOfInternalGoodsMovement, BusinessTransactionsAndDocuments);
	
	TMCommonUse.FormInscriptionSelection(Items.HelpTextFilter.Title,
		BusinessTransactionsAndDocuments, FilterDocumentTypes, FilterBusinessTransactions);
	ConfigureDocumentManagementButtons();
	
EndProcedure

&AtServer
Procedure SetVisibilityAvailability()
	
	If Not GetFunctionalOption("UseMultipleCompanies") Then
		Items.Organization.Visible = False;
	EndIf;
	
	If Not GetFunctionalOption("UseSeveralWarehouses") Then
		Items.Warehouse.Visible = False;
		Items.ListDocumentsOfInternalGoodsMovementWarehouse.Visible = False;
	EndIf;
	
	If Not GetFunctionalOption("EmployeeInChargeInDocuments") Then
		Items.Manager.Visible = False;
		Items.ListDocumentsOfInternalGoodsMovementManager.Visible = False;
	EndIf;
	
	// Re-filling the list of statuses
	TMCommonUse.SetListOfStatuses(ThisForm, Items.SetStatus);
	
EndProcedure

&AtServer
Procedure ConfigureDocumentManagementButtons()
	
	ParametersStructure = TMCommonUse.StructureOfSettingsForDocumentManagementButtons();
	ParametersStructure.Form 												= ThisForm;
	ParametersStructure.NameOfCopyButton 								= "ListCopy";
	ParametersStructure.NameOfCopyContextMenuButton 				= "ListContextMenuCopy";
	ParametersStructure.ChangeButtonName 									= "ListChange";
	ParametersStructure.NameOfChangeContextMenuButton 					= "ListContextMenuChange";
	ParametersStructure.ButtonNamePost 									= "ListPost";
	ParametersStructure.NameOfHoldContextMenuButton 					= "ListContextMenuPost";
	ParametersStructure.NameOfCancelEventButton 							= "ListUndoPosting";
	ParametersStructure.NameOfCancelButtonIsContextMenu 			= "ListContextMenuUndoPosting";
	ParametersStructure.NameOfMarkDeleteButton 					= "ListSetDeletionMark";
	ParametersStructure.ButtonNameMarkDeleteContextMenu 	= "ListContextMenuSetDeletionMark";
	
	TMCommonUse.ConfigureDocumentManagementButtons(ParametersStructure);

EndProcedure

&AtServer
Function PlaceBusinessTransactionsAndDocumentsInTemporaryStorage()
	Return PutToTempStorage(BusinessTransactionsAndDocuments.Unload(), UUID);
EndFunction

&AtServer
Procedure SelectionOperationTypeSelectionProcessingServer(AddressOfBusinessTransactionsAndDocuments)
	
	VTBusinessTransactionsAndDocumentTypes = GetFromTempStorage(AddressOfBusinessTransactionsAndDocuments);
	BusinessTransactionsAndDocuments.Load(VTBusinessTransactionsAndDocumentTypes);
	TMCommonUse.FillInSelectionsAccordingToTableOfBusinessTransactionsAndDocumentTypes(VTBusinessTransactionsAndDocumentTypes, FilterBusinessTransactions, FilterDocumentTypes);
	
	ConfigureFormForSelectedOperationsAndDocuments(VTBusinessTransactionsAndDocumentTypes);
	
EndProcedure

#Region Filters

&AtServer
Procedure OrganizationWhenChangedOnServer()
	
	SetSelectionByOrganization();
	
	UpdateHyperlinkToLayout();
	
EndProcedure

&AtServer
Procedure WarehouseWhenChangedOnServer()
	
	If Not RestrictionByWarehouseIsUsed Then
		CommonClientServer.SetDynamicListFilterItem(ListDocumentsOfInternalGoodsMovement, "AdditionalRecord",
			False, DataCompositionComparisonType.Equal, Undefined, Not ValueIsFilled(Warehouse));
	EndIf;
	
	FilterWarehouses = WarehousesServer.ListOfSubordinateWarehouses(Warehouse);
	FilterStorageLocations_ = Catalogs.DocumentRegistryKeys.KeysByValue(FilterWarehouses);
	
	CommonClientServer.SetDynamicListFilterItem(ListDocumentsOfInternalGoodsMovement,
																			"StorageLocation",
																			FilterStorageLocations_,
																			DataCompositionComparisonType.InList,
																			,
																			ValueIsFilled(FilterStorageLocations_));
	
	UpdateHyperlinkToLayout();
	
	// DynamicListsSettings
	OperationsWithDocumentJournals.SetVisibilityOfDefaultUpdateSettingsGroup(ThisObject, "ListDocumentsOfInternalGoodsMovement");
	// End DynamicListsSettings
	
EndProcedure

&AtServer
Procedure SetDynamicListSelections()
	
	If Not RestrictionByWarehouseIsUsed Then
		CommonClientServer.SetDynamicListFilterItem(ListDocumentsOfInternalGoodsMovement, "AdditionalRecord",
			False, DataCompositionComparisonType.Equal, Undefined, Not ValueIsFilled(Warehouse));
	EndIf;
	
	CommonClientServer.SetDynamicListFilterItem(
		ListDocumentsOfInternalGoodsMovement,
		"BusinessOperation",
		FilterBusinessTransactions,
		DataCompositionComparisonType.InList,
		,
		True);
	
	CommonClientServer.SetDynamicListFilterItem(
		ListDocumentsOfInternalGoodsMovement,
		"RefType",
		FilterDocumentTypes,
		DataCompositionComparisonType.InList,
		,
		True);
	
	SetSelectionByOrganization();
	
	FilterWarehouses = WarehousesServer.ListOfSubordinateWarehouses(Warehouse);
	FilterStorageLocations_ = Catalogs.DocumentRegistryKeys.KeysByValue(FilterWarehouses);
	
	CommonClientServer.SetDynamicListFilterItem(ListDocumentsOfInternalGoodsMovement,
																			"StorageLocation",
																			FilterStorageLocations_,
																			DataCompositionComparisonType.InList,
																			,
																			ValueIsFilled(FilterStorageLocations_));
	
	CommonClientServer.SetDynamicListFilterItem(
		ListDocumentsOfInternalGoodsMovement,
		"Manager",
		Manager,
		DataCompositionComparisonType.Equal,
		,
		ValueIsFilled(Manager));
	
	SetSelectionByPeriod();
	
EndProcedure

&AtServer
Procedure SetSelectionByOrganization()

	CompaniesList = New ValueList;
	If ValueIsFilled(Organization) Then
		CompaniesList.LoadValues(Catalogs.Companies.BranchesWithPaymentsThroughParentOrganization(Organization));
		CompaniesList.Add(Organization);
	EndIf;
	
	CommonClientServer.SetDynamicListFilterItem(ListDocumentsOfInternalGoodsMovement,
		"Organization",
		CompaniesList,
		DataCompositionComparisonType.InList,,
		ValueIsFilled(Organization));
		
	// DynamicListsSettings
	OperationsWithDocumentJournals.SetVisibilityOfDefaultUpdateSettingsGroup(ThisObject, "ListDocumentsOfInternalGoodsMovement");
	// End DynamicListsSettings
	
EndProcedure

&AtServer
Procedure SetSelectionByPeriod()
	
	ListDocumentsOfInternalGoodsMovement.Parameters.SetParameterValue("BeginOfPeriod",
		Period.StartDate);
	ListDocumentsOfInternalGoodsMovement.Parameters.SetParameterValue("EndOfPeriod",
		?(ValueIsFilled(Period.EndDate), Period.EndDate, EndOfDay(Date(3999, 12, 31))));
	
	// DynamicListsSettings
	OperationsWithDocumentJournals.SetVisibilityOfDefaultUpdateSettingsGroup(ThisObject, "ListDocumentsOfInternalGoodsMovement");
	// End DynamicListsSettings
	
EndProcedure

#EndRegion

#Region HyperlinkToDesign

&AtServer
Procedure UpdateHyperlinkToLayout()
	
	// Checking whether the form element should be displayed to the form
	Filter = New Structure("Filter", True);
	BsnsTransactionsAndDocuments = BusinessTransactionsAndDocuments.FindRows(Filter);
	
	YouNeedHyperlinkToDesign = False;
	
	If AccessRight("View", Metadata.CommonCommands.DocumentsOfInternalGoodsTransferForRegistration) Then
		
		For Each String In BsnsTransactionsAndDocuments Do
			If ValueIsFilled(String.HyperlinkCalculationManagerForRegistration) Then
				YouNeedHyperlinkToDesign = True;
				Break;
			EndIf;
		EndDo;
		
	EndIf;
	
	GenerationParameters = New Structure;
	GenerationParameters.Insert("Organization", Organization);
	GenerationParameters.Insert("Warehouse", Warehouse);
	GenerationParameters.Insert("Manager", Manager);
	GenerationParameters.Insert("FilterBusinessTransactions", FilterBusinessTransactions);
	
	If YouNeedHyperlinkToDesign Then
		
		Items.ToRegister.Visible = True;
		TextIsUpdatingData = NStr("vi = 'Cần lập: <đang cập nhật dữ liệu>';
									|ru = 'К оформлению: <идет обновление данных>';
									|en = 'To register: <updating data>'; fa = 'To register: <updating data>';
									|it = 'Da formalizzare: <dati in fase di aggiornamento>';
									|pl = 'Do rejestracji: <odbywa się aktualizacja danych>';
									|tr = 'Düzenlenecek: <veri güncellemesi devam ediyor>'");
		ToRegister = New FormattedString(TextIsUpdatingData);
		
		JobParameters = New Array;
		JobParameters.Add(BusinessTransactionsAndDocuments.Unload());
		JobParameters.Add(GenerationParameters);
		
		ExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(UUID);
		ExecutionParameters.WaitCompletion = 0;
		ExecutionParameters.RunInBackground = True;
		CalculationResult2 = TimeConsumingOperations.ExecuteInBackground("DataProcessors.LogOfInternalDocuments.CreateHyperlinkToBackgroundTaskLayout",
		                                                     JobParameters,
		                                                     ExecutionParameters);
		
		
		If CalculationResult2.Status = "Completed2" Then
			ToRegister = UpdateHyperlinkToLayoutCompletion(CalculationResult2.ResultAddress);
			ResultOfFormationOfHyperlinksToDesign = Undefined;
		Else
			ResultOfFormationOfHyperlinksToDesign = CalculationResult2;
		EndIf;
	Else
		Items.ToRegister.Visible = False;
	EndIf;
	
	SeeAlsoInProgress = TMCommonUse.CreateHyperlinkSeeAlsoIn(ArrayCalculationManagersSeeAlsoInWork(), GenerationParameters);
	Items.SeeAlsoInProgress.Visible = ValueIsFilled(SeeAlsoInProgress);
	
EndProcedure

&AtServer
Function ArrayCalculationManagersSeeAlsoInWork()
	
	ArrayCalculationManagersSeeAlsoInWork = New Array;
	
	For Each String In BusinessTransactionsAndDocuments Do
		If String.Filter Then
			If String.DocumentType = Type("DocumentRef.InventoryConsumption") Then
				ArrayCalculationManagersSeeAlsoInWork.Add("Document.InventoryConsumptionOrder");
				ArrayCalculationManagersSeeAlsoInWork.Add("Document.RMOrder");
			ElsIf String.DocumentType = Type("DocumentRef.AssemblyFromComponents") Then
				ArrayCalculationManagersSeeAlsoInWork.Add("Document.ByAssemblyDisassemblyOrder");


			ElsIf String.DocumentType = Type("DocumentRef.MovementOfProductsAndMaterials") Then
				ArrayCalculationManagersSeeAlsoInWork.Add("Document.OrderOfMaterialsForProduction");
			ElsIf String.DocumentType = Type("DocumentRef.InventoryTransfer") Then
				ArrayCalculationManagersSeeAlsoInWork.Add("Document.TransferOrder");
			EndIf;
		EndIf;
	EndDo;

	ToCompleteArrayOfCalculationManagersSeeAlsoLocalization(ArrayCalculationManagersSeeAlsoInWork);

	ArrayCalculationManagersSeeAlsoInWork = CommonClientServer.CollapseArray(ArrayCalculationManagersSeeAlsoInWork);
	
	Return ArrayCalculationManagersSeeAlsoInWork;
	
EndFunction

&AtServerNoContext
Function UpdateHyperlinkToLayoutCompletion(StorageAddress)
	
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
	Return ToRegister;
	
EndFunction

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
		ToRegister = UpdateHyperlinkToLayoutCompletion(Result.ResultAddress);
	EndIf;
	
EndProcedure


#EndRegion

#Region DynamicListsSettings

&AtServer
Procedure InitiateDynamicListSettings()
	
	DocumentListParameters = New Array;
	
	ListParameterStructure = OperationsWithDocumentJournals.StructureOfFormationOfGroupOfUserSettingsForDynamicListOnForm();
	ListParameterStructure.ListName = "ListDocumentsOfInternalGoodsMovement";
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

#Region Localization

Procedure ToCompleteArrayOfCalculationManagersSeeAlsoLocalization(ArrayCalculationManagersSeeAlsoInWork)
	
	
	Return;
	
EndProcedure

#EndRegion
