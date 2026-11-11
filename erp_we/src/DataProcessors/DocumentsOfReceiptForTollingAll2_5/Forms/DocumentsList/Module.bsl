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
		And ValueIsFilled(Parameters.FormAssignmentKey) Then
		PurposeUseKey = Parameters.FormAssignmentKey;
	Else
		PurposeUseKey = TollingSchemeClientServer.AssignmentKeyDocumentsOfAcceptanceForProcessing();
	EndIf;
	
	If PurposeUseKey = TollingSchemeClientServer.AssignmentKeyDocumentsOfAcceptanceForProcessing() Then
		SettingsKey = "";
	Else
		SettingsKey = PurposeUseKey;
	EndIf;
	
	URL = "e1cib/app/DataProcessor.DocumentsOfReceiptForTollingAll2_5";
	
	RestoreSettings(Parameters);
	
	VTBusinessTransactionsAndDocumentTypes = DataProcessors.DocumentsOfReceiptForTollingAll2_5.InitializeBusinessTransactionsAndDocuments(FilterBusinessTransactions,
		FilterDocumentTypes, PurposeUseKey);
	
	BusinessTransactionsAndDocuments.Load(VTBusinessTransactionsAndDocumentTypes);
	
	ConfigureFormForSelectedOperationsAndDocuments(VTBusinessTransactionsAndDocumentTypes);
	
	DocumentTypesUsed = VTBusinessTransactionsAndDocumentTypes.UnloadColumn("DocumentType");
	InfobaseUpdateTM.CheckWhetherDocumentLogCanBeOpened(DocumentTypesUsed);
	
		
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject, Items.GlobalCommandsGroup);
	// End IntegrationWith1CDocumentManagementSubsystem

	
	
	// Document verificationreferences
	ListProperties = Common.DynamicListPropertiesStructure();
	FillPropertyValues(ListProperties, List);
	
	DocumentVerificationServer.ModifyDynamicDocumentLogListRequest(
		ListProperties.QueryText, "DocumentsRegistryOverridable");
	
	Common.SetDynamicListProperties(Items.List, ListProperties);
	// End Document verificationreferences
		
	AdditionalParameters = New Structure("LocationOfLocalValidationData", Items.ReglGroupVerification);
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing, AdditionalParameters);
	
	// StandardSubsystems.AttachableCommands
	If ValueIsFilled(DocumentTypesUsed) Then
		PlacementParameters = AttachableCommands.PlacementParameters();
		PlacementParameters.Sources = New TypeDescription(DocumentTypesUsed);
		PlacementParameters.CommandBar = Items.ListCommandBar;
		AttachableCommands.OnCreateAtServer(ThisObject, PlacementParameters);
	EndIf;
	// End StandardSubsystems.AttachableCommands
	
	// StandardSubsystems.SourceDocumentsOriginalsRecording
	SourceDocumentsOriginalsRecording.OnCreateAtServerListForm(
		ThisObject, Items.List, Items.ListDocumentAmount);
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
	If Source = "Peripherals" And IsInputAvailable() Then
		If EventName = "ScanData" And EquipmentManagerTMClient.ThereIsRawEvent() Then
			ProcessBarcodes(EquipmentManagerTMClient.ConvertDataFromScannerToStructure(Parameter));
		EndIf;
	EndIf;
	// End Peripherals
	
	If EventName = "Write_MaterialProviderOrder2_5"
	 Or EventName = "Write_GoodsReceiptForStorage"
	 Or EventName = "Write_GoodsShipmentFromStorage"
	 Or EventName = "Write_ReportToMaterialProvider2_5"
	 Or EventName = "Write_RedemptionOfGoodsFromStorage"
	 Or EventName = "Write_ReportOnVMIAdjustment"
	 Or EventName = "Write_GoodsDamage"
	 Or EventName = "Write_GoodsMisgrading"
	 Or EventName = "Write_DiscrepancyReportFollowingReceipt"
	 Or EventName = "Write_DiscrepancyReportFollowingShipment"
	 Or EventName = "Write_InvoiceIssued"
	 Or EventName = "Write_SaleAdjustment"
	 Or EventName = "Accept_FormOfCreatedDocuments" Then
		
		// DynamicListsSettings
		UpdateListOfDocumentsEventNotificationProcessing("List", Parameter);
		// End DynamicListsSettings
		
		UpdateHyperlinkToLayout();
		ConnectHyperlinkWaitingHandlerToLayout();
			
	EndIf;
	
	
	// StandardSubsystems.SourceDocumentsOriginalsRecording
	SourceDocumentsOriginalsRecordingClient.NotificationHandlerListForm(EventName, ThisObject, Items.List);
	// End StandardSubsystems.SourceDocumentsOriginalsRecording
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure ManagerOnChange(Item)
	
	CommonClientServer.SetDynamicListFilterItem(
		List, "Manager", Manager, DataCompositionComparisonType.Equal,, ValueIsFilled(Manager));
		
	// DynamicListsSettings
	OperationsWithDocumentJournalsClient.SetVisibilityOfDefaultUpdateSettingsGroup(ThisObject, "List");
	// End DynamicListsSettings
	
EndProcedure

&AtClient
Procedure WarehouseOnChange(Item)
	
	WarehouseWhenChangedOnServer();
	ConnectHyperlinkWaitingHandlerToLayout();
	
EndProcedure

&AtClient
Procedure OrganizationOnChange(Item)
	
	OrganizationWhenChangedOnServer();
	ConnectHyperlinkWaitingHandlerToLayout();
	
EndProcedure

&AtClient
Procedure HelpTextFilterURLProcessing(Item, FormattedStringURL, StandardProcessing)
	
	StandardProcessing = False;
	
	FormParameters = New Structure();
	FormParameters.Insert(
		"AvailableBusinessTransactionsAndDocuments", PlaceBusinessTransactionsAndDocumentsInTemporaryStorage());
	FormParameters.Insert("SettingsKey", PurposeUseKey);
	FormParameters.Insert("FormKey", TollingSchemeClientServer.AssignmentKeyDocumentsOfAcceptanceForProcessing());
	
	OpenForm(
		"Catalog.BusinessTransactionsSettings.Form.FormOfFilterSetting",
		FormParameters,,,,,
		New CallbackDescription("EstablishSelectionsForBusinessTransactionsAndDocuments", ThisObject));
	
EndProcedure

&AtClient
Procedure EstablishSelectionsForBusinessTransactionsAndDocuments(ValueSelected, AdditionalParameters) Export
	
	If ValueSelected = Undefined Then
		Return;
	EndIf;
	
	If TypeOf(ValueSelected) = Type("String") Then
		
		AddressOfAvailableBusinessTransactionsAndDocuments = ValueSelected;
		
		SelectionOperationTypeSelectionProcessingServer(AddressOfAvailableBusinessTransactionsAndDocuments);
		ConnectHyperlinkWaitingHandlerToLayout();
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ToRegisterURLProcessing(Item, FormattedStringURL, StandardProcessing)
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.TimeMeasurement(
		"DataProcessor.DocumentsOfReceiptForTollingAll2_5.Form.List.Event.ToRegisterURLProcessing");
	
	StandardProcessing = False;
	
	NamesArray = StrSplit(FormattedStringURL, "/");
	NameOfInvoiceForm = NamesArray[0];
	
	QuickFilterStructure = New Structure;
	QuickFilterStructure.Insert("Organization", Organization);
	QuickFilterStructure.Insert("Warehouse",       Warehouse);
	QuickFilterStructure.Insert("Manager",    Manager);
	
	FormParameters = New Structure;
	FormParameters.Insert("QuickFilterStructure",     QuickFilterStructure);
	FormParameters.Insert("CurrentPageName",          ?(NamesArray.Count() > 1, NamesArray[1], ""));
	FormParameters.Insert("PurposeUseKey", "DocumentsOfAcceptanceForProcessing");
	
	OpenForm(NameOfInvoiceForm, FormParameters);
	
EndProcedure

&AtClient
Procedure SeeAlsoInProgressURLProcessing(Item, FormattedStringURL, StandardProcessing)
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.TimeMeasurement(
		"DataProcessor.DocumentsOfReceiptForTollingAll2_5.Form.List.Event.SeeAlsoInProgressURLProcessing");
	
	StandardProcessing = False;
	
	QuickFilterStructure = New Structure;
	QuickFilterStructure.Insert("Organization", Organization);
	QuickFilterStructure.Insert("Warehouse",       Warehouse);
	
	FormParameters = New Structure;
	FormParameters.Insert("QuickFilterStructure", QuickFilterStructure);
	FormParameters.Insert(
		"PurposeUseKey", TollingSchemeClientServer.AssignmentKeyDocumentsOfAcceptanceForProcessing());
	
	// Power of attorney issued
	FormParameters.Insert("AvailabilityOfCashOrders", True);
	FormParameters.Insert("AvailabilityOfOrdersGoods", False);
	FormParameters.Insert("FormCaption", NStr("vi = 'Giấy ủy quyền';
												|ru = 'Доверенности на получение денежных средств';
												|en = 'Authorization letters to receive cash'; fa = 'Authorization letters to receive cash';
												|it = 'Delega per incasso fondi monetari';
												|pl = 'Pełnomocnictwo na otrzymanie środków pieniężnych';
												|tr = 'Para tahsilatı için yetki belgesi'"));
	
	OpenForm(FormattedStringURL, FormParameters, ThisForm, UUID);
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersListRegistered

&AtClient
Procedure ListBeforeAddRow(Item, Cancel, Copy, Parent, Var_Group, Parameter)
	
	If Items.CreateGroupGenerated.ChildItems.Count() <> 0 Then
		
		If Copy Then
			
			TMCommonUseClient.CopyItem(Item);
			
		ElsIf FilterDocumentTypes.Count() = 1 And FilterBusinessTransactions.Count() = 1 Then
			
			Attachable_CreateDocument(
				New Structure("Name", Items.CreateGroupGenerated.ChildItems[0].Name));
			
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
		SourceDocumentsOriginalsRecordingClient.ListSelection(Field.Name, ThisObject, Items.List, StandardProcessing);
		// End StandardSubsystems.SourceDocumentsOriginalsRecording
		Return;
	EndIf;
	
	TMCommonUseClient.ChangeElement(Item);
	
	If Field = Items.StatusPresentation Then
	EndIf;
	
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

	ListUndoPostingServer();
	ConnectHyperlinkWaitingHandlerToLayout();
	
EndProcedure

&AtServer
Procedure ListOnUpdateUserSettingSetAtServer(Item, StandardProcessing)
	
	// DynamicListsSettings
	OperationsWithDocumentJournals.SetVisibilityOfDefaultUpdateSettingsGroup(ThisObject, "List");
	// End DynamicListsSettings
	
EndProcedure

&AtClient
Procedure ListPost(Command)
	
	TMCommonUseClient.PostDocuments(Items.List, Title,
		OperationsWithDocumentJournalsClient.ParametersForUpdatingDocumentList(ThisObject, "List"));
	
	ListPostServer();
	ConnectHyperlinkWaitingHandlerToLayout();
	
EndProcedure

&AtClient
Procedure ListSetClearADeletionMark(Command)
	
	Notification = New CallbackDescription("ListSetDeletionMarkCompletion", ThisObject);
	
	TMCommonUseClient.SetDeletionMark(Items.List, Title, Notification,
		OperationsWithDocumentJournalsClient.ParametersForUpdatingDocumentList(ThisObject, "List"));

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
Procedure ListOnGetDataAtServer(TagName, Settings, Rows)
	
	// StandardSubsystems.SourceDocumentsOriginalsRecording
	SourceDocumentsOriginalsRecording.OnGetDataAtServer(Rows);
	// End StandardSubsystems.SourceDocumentsOriginalsRecording
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

// StandardSubsystems.AttachableCommands
&AtClient
Procedure Attachable_ExecuteCommand(Command)
	AttachableCommandsClient.ExecuteCommand(ThisObject, Command, Items.List);
EndProcedure

&AtServer
Procedure Attachable_ExecuteCommandAtServer(Context, Result) Export
	AttachableCommands.ExecuteCommand(ThisObject, Context, Items.List, Result);
EndProcedure

&AtClient
Procedure Attachable_UpdateCommands()
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Items.List);
EndProcedure
// End StandardSubsystems.AttachableCommands

// IntegrationWith1CDocumentManagementSubsystem
&AtClient
Procedure Attachable_ExecuteIntegrationCommand(Command)
	
	IntegrationWith1CDocumentManagementCoreClient.ExecutePlugInIntegrationCommand(Command, ThisObject, Items.List);
	
EndProcedure
// End IntegrationWith1CDocumentManagementSubsystem

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure



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
	
	FormKey = TollingSchemeClientServer.AssignmentKeyDocumentsOfAcceptanceForProcessing();
	
	AddressBusinessTransactionsAndDocuments = PlaceBusinessTransactionsAndDocumentsInTemporaryStorage();
	
	FilterStructure1 = New Structure;
	FilterStructure1.Insert("Organization", Organization);
	FilterStructure1.Insert("Warehouse",       Warehouse);
	
	TMCommonUseClient.CreateDocumentViaSelectionForm(
		AddressBusinessTransactionsAndDocuments, FormKey, PurposeUseKey, FilterStructure1);
	
EndProcedure

#EndRegion

&AtClient
Procedure SetDateInterval(Command)
	
	TMCommonUseClient.EditPeriod(
		Period,, New CallbackDescription("SetDateIntervalCompletion", ThisObject));
	
EndProcedure

&AtClient
Procedure SetDateIntervalCompletion(ValueSelected, AdditionalParameters) Export
	
	If ValueSelected = Undefined Then
		Return;
	EndIf;
	
	Period = ValueSelected;
	
	SetSelectionByPeriod();
	
EndProcedure

// Parameters:
// 	Command - FormCommand - 
&AtClient
Procedure Attachable_SetStatus(Command)
	
	TMCommonUseClient.SetStatus(Command.Name, CorrespondenceOfCommandsToStatuses, Items.List);
	
EndProcedure

// StandardSubsystems.SourceDocumentsOriginalsRecording
&AtClient
Procedure Attachable_UpdateOriginalStateCommands()
	
	UpdateOriginalStateCommands()
	
EndProcedure

&AtServer
Procedure UpdateOriginalStateCommands()
	
	If PurposeUseKey = TollingSchemeClientServer.AssignmentKeyDocumentsOfAcceptanceForProcessing() Then
		SettingsKey = "";
	Else
		SettingsKey = PurposeUseKey;
	EndIf;
	
	VTBusinessTransactionsAndDocumentTypes = DataProcessors.DocumentsOfReceiptForTollingAll2_5.InitializeBusinessTransactionsAndDocuments(FilterBusinessTransactions,
		FilterDocumentTypes, PurposeUseKey);
	
	DocumentTypesUsed = VTBusinessTransactionsAndDocumentTypes.UnloadColumn("DocumentType");
	
	// StandardSubsystems.AttachableCommands
	PlacementParameters = AttachableCommands.PlacementParameters();
	PlacementParameters.Sources = New TypeDescription(DocumentTypesUsed);
	PlacementParameters.CommandBar = Items.ListCommandBar;
	AttachableCommands.OnCreateAtServer(ThisObject, PlacementParameters);
	// End StandardSubsystems.AttachableCommands
	
EndProcedure
//End StandardSubsystems.SourceDocumentsOriginalsRecording

&AtClient
Procedure DocumentsListRefresh(Command)
	
	// DynamicListsSettings
	UpdateDocumentListDataWithTimeMeasurement("List");
	// End DynamicListsSettings
	
EndProcedure
#EndRegion

#Region Private

#Region BarcodesAndTradeEquipment

&AtServer
Function BarcodeDataOfPrintedForm(Barcode, ListName = "")
	
	ThereIsMainTableOfList = OperationsWithDocumentJournals.ThereIsMainTableOfList(ThisObject, ListName);
	
	BarcodeData =
		TMCommonUse.BarcodeDataOfPrintedForm(Barcode, BusinessTransactionsAndDocuments.Unload(), ThereIsMainTableOfList);
	
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

#Region AttributesOnChange

&AtServer
Procedure OrganizationWhenChangedOnServer()
	
	SetSelectionByOrganization();
	SetVisibilityAvailability();
	
EndProcedure

&AtServer
Procedure WarehouseWhenChangedOnServer()
	
	SetDynamicListSelections();
	SetVisibilityAvailability();
	UpdateHyperlinkToLayout();
		
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
	
	StandardSubsystemsServer.SetDateFieldConditionalAppearance(ThisObject, "List.Date", "ListDate");
	
EndProcedure

&AtServer
Procedure RestoreSettings(Var_Parameters)
	
	ListOfDocumentsAutoUpdateMode = True;
	
	If Var_Parameters.Property("QuickFilterStructure") Then
		
		QuickFilterStructure = Var_Parameters.QuickFilterStructure;
		QuickFilterStructure.Property("Organization", Organization);
		QuickFilterStructure.Property("Warehouse",       Warehouse);
		QuickFilterStructure.Property("Manager",    Manager);
		QuickFilterStructure.Property("Period",      Period);
		
	Else
		
		Settings = Common.CommonSettingsStorageLoad(
			"DataProcessor.DocumentsOfReceiptForTollingAll2_5.Form.ListForm", PurposeUseKey);
		
		If TypeOf(Settings) = Type("Structure") Then
			
			Settings.Property("Organization", Organization);
			Settings.Property("Warehouse",       Warehouse);
			Settings.Property("Manager",    Manager);
			Settings.Property("Period",      Period);
			
			Settings.Property("FilterDocumentTypes",        FilterDocumentTypes);
			Settings.Property("FilterBusinessTransactions", FilterBusinessTransactions);
			
			If Settings.Property("ListOfDocumentsAutoUpdateMode") Then
				ListOfDocumentsAutoUpdateMode = Settings.ListOfDocumentsAutoUpdateMode;
			EndIf;
			
		EndIf;
		
	EndIf;
	
EndProcedure

&AtServer
Procedure ShouldSaveSettings()
	
	AttributesToSaveNames =
		"Organization,
		|Warehouse,
		|Manager,
		|Period,
		|FilterDocumentTypes,
		|FilterBusinessTransactions,
		|ListOfDocumentsAutoUpdateMode";
	
	Settings = New Structure(AttributesToSaveNames);
	FillPropertyValues(Settings, ThisForm);
	
	Common.CommonSettingsStorageSave(
		"DataProcessor.DocumentsOfReceiptForTollingAll2_5.Form.ListForm", PurposeUseKey, Settings);
	
EndProcedure

&AtServer
Procedure ConfigureFormForSelectedOperationsAndDocuments(VTBusinessTransactionsAndDocumentTypes)
	
	WorkplaceData = TMCommonUse.WorkplaceData(
							VTBusinessTransactionsAndDocumentTypes,
							TollingSchemeClientServer.AssignmentKeyDocumentsOfAcceptanceForProcessing(),
							DataProcessors.DocumentsOfReceiptForTollingAll2_5.WorkplaceTitle());
	
	Title = WorkplaceData.WorkplaceTitle;
	
	TMCommonUse.ReplaceLinkFieldWithExpressByDocumentTypeConstruct(Items.List,
		BusinessTransactionsAndDocuments);
	
	SetDynamicListSelections();
	SetVisibilityAvailability();
	
	TMCommonUse.FormInscriptionSelection(
							Items.HelpTextFilter.Title,
							BusinessTransactionsAndDocuments,
							FilterDocumentTypes,
							FilterBusinessTransactions);
	
	ConfigureDocumentManagementButtons();
	
EndProcedure

&AtServer
Procedure SetVisibilityAvailability()
	
	If Not GetFunctionalOption("UseMultipleCompanies") Then
		Items.Organization.Visible       = False;
		Items.ListOrganization.Visible = False;
	Else
		Items.ListOrganization.Visible = Not ValueIsFilled(Organization);
	EndIf;
	
	If Not GetFunctionalOption("UseSeveralWarehouses") Then
		Items.Warehouse.Visible       = False;
		Items.ListWarehouse.Visible = False;
	Else
		Items.ListWarehouse.Visible = Not ValueIsFilled(Warehouse);
	EndIf;
	
	If Not GetFunctionalOption("EmployeeInChargeInDocuments") Then
		Items.Manager.Visible = False;
	EndIf;
	
	If Not GetFunctionalOption("UseMultipleCurrencies") Then
		Items.ListCurrency.Visible = False;
	EndIf;
	
	Items.ListCounterparty.Visible = GetFunctionalOption("UsePartnersAndCounterparties");
	
	// Re-filling the list of statuses
	TMCommonUse.SetListOfStatuses(ThisForm, Items.SetStatus);
	
EndProcedure

&AtServer
Procedure ConfigureDocumentManagementButtons()
	
	ParametersStructure = TMCommonUse.StructureOfSettingsForDocumentManagementButtons();
	ParametersStructure.Form 											  = ThisForm;
	ParametersStructure.NameOfCopyButton 							  = "ListCopy";
	ParametersStructure.NameOfCopyContextMenuButton 			  = "ListContextMenuCopy";
	ParametersStructure.ChangeButtonName 								  = "ListChange";
	ParametersStructure.NameOfChangeContextMenuButton 				  = "ListContextMenuChange";
	ParametersStructure.ButtonNamePost 								  = "ListPost";
	ParametersStructure.NameOfHoldContextMenuButton 				  = "ListContextMenuPost";
	ParametersStructure.NameOfCancelEventButton 						  = "ListUndoPosting";
	ParametersStructure.NameOfCancelButtonIsContextMenu 		  = "ListContextMenuUndoPosting";
	ParametersStructure.NameOfMarkDeleteButton 				  = "ListSetDeletionMark";
	ParametersStructure.ButtonNameMarkDeleteContextMenu = "ListContextMenuSetDeletionMark";
	
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
	
	TMCommonUse.FillInSelectionsAccordingToTableOfBusinessTransactionsAndDocumentTypes(
		VTBusinessTransactionsAndDocumentTypes, FilterBusinessTransactions, FilterDocumentTypes);
	
	ConfigureFormForSelectedOperationsAndDocuments(VTBusinessTransactionsAndDocumentTypes);
	
EndProcedure

#Region Filters

&AtServer
Procedure SetDynamicListSelections()
	
	FilterWarehouses        = WarehousesServer.ListOfSubordinateWarehouses(Warehouse);
	FilterStorageLocations_ = Catalogs.DocumentRegistryKeys.KeysByValue(FilterWarehouses);
	
	CommonClientServer.SetDynamicListFilterItem(
		List, "RefType", FilterDocumentTypes, DataCompositionComparisonType.InList,, True);
	
	CommonClientServer.SetDynamicListFilterItem(
		List, "BusinessOperation", FilterBusinessTransactions, DataCompositionComparisonType.InList,, True);
	
	CommonClientServer.SetDynamicListFilterItem(
		List,
		"StorageLocation",
		FilterStorageLocations_,
		DataCompositionComparisonType.InList,,
		ValueIsFilled(FilterStorageLocations_));
	
	CommonClientServer.SetDynamicListFilterItem(
		List, "Manager", Manager, DataCompositionComparisonType.Equal,, ValueIsFilled(Manager));
		
	SetSelectionByOrganization();
	
	SetSelectionByPeriod();
	
	// DynamicListsSettings
	OperationsWithDocumentJournals.SetVisibilityOfDefaultUpdateSettingsGroup(ThisObject, "List");
	// End DynamicListsSettings
	
EndProcedure

&AtServer
Procedure SetSelectionByOrganization()

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
	
	CommonClientServer.SetDynamicListFilterItem(
		List,
		"Organization",
		CompaniesList,
		DataCompositionComparisonType.InList,,
		ValueIsFilled(Organization));
		
	UpdateHyperlinkToLayout();
	
	// DynamicListsSettings
	OperationsWithDocumentJournals.SetVisibilityOfDefaultUpdateSettingsGroup(ThisObject, "List");
	// End DynamicListsSettings
	
EndProcedure

&AtServer
Procedure SetSelectionByPeriod()
	
	List.Parameters.SetParameterValue("BeginOfPeriod", Period.StartDate);
	List.Parameters.SetParameterValue("EndOfPeriod", 
		?(ValueIsFilled(Period.EndDate), Period.EndDate, EndOfDay(Date(3999, 12, 31))));
		
	// DynamicListsSettings
	OperationsWithDocumentJournals.SetVisibilityOfDefaultUpdateSettingsGroup(ThisObject, "List");
	// End DynamicListsSettings
	
EndProcedure

#EndRegion 

#Region HyperlinkToDesign

&AtServer
Procedure UpdateHyperlinkToLayout()
	
	Items.ToRegister.Visible = True;
	ToRegister = New FormattedString(NStr("vi = 'Cần lập: <đang cập nhật dữ liệu>';
											|ru = 'К оформлению: <идет обновление данных>';
											|en = 'To register: <updating data>'; fa = 'To register: <updating data>';
											|it = 'Da formalizzare: <dati in fase di aggiornamento>';
											|pl = 'Do rejestracji: <odbywa się aktualizacja danych>';
											|tr = 'Düzenlenecek: <veri güncellemesi devam ediyor>'"));
	
	Items.SeeAlsoInProgress.Visible = True;
	SeeAlsoInProgress = New FormattedString(NStr("vi = 'Xem thêm: <đang cập nhật dữ liệu>';
												|ru = 'См. также: <идет обновление данных>';
												|en = 'See also: <data is being updated>'; fa = 'See also: <data is being updated>';
												|it = 'Vedi anche: <aggiornamento dati in corso>';
												|pl = 'Patrz również: <odbywa się aktualizacja danych>';
												|tr = 'Ayrıca bakınız: <veri güncellemesi devam ediyor>'"));
	
	GenerationParameters = New Structure;
	GenerationParameters.Insert("Warehouse",       Warehouse);
	GenerationParameters.Insert("Organization", Organization);
	GenerationParameters.Insert("Manager",    Manager);
	GenerationParameters.Insert(
		"PurposeUseKey", TollingSchemeClientServer.AssignmentKeyDocumentsOfAcceptanceForProcessing());
	
	JobParameters = New Array;
	JobParameters.Add(BusinessTransactionsAndDocuments.Unload());
	JobParameters.Add(GenerationParameters);
	
	CalculationProcedure_ =
		"DataProcessors.DocumentsOfReceiptForTollingAll2_5.CreateHyperlinkToBackgroundTaskLayout";
	
	ExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(UUID);
	ExecutionParameters.WaitCompletion = 0;
	ExecutionParameters.RunInBackground    = True;
	
	CalculationResult2 = TimeConsumingOperations.ExecuteInBackground(CalculationProcedure_, JobParameters, ExecutionParameters);
	
	If CalculationResult2.Status = "Completed2" Then
		UpdateHyperlinkToLayoutCompletion(CalculationResult2.ResultAddress);
		ResultOfFormationOfHyperlinksToDesign = Undefined;
	Else
		ResultOfFormationOfHyperlinksToDesign = CalculationResult2;
	EndIf;
	
EndProcedure

&AtServer
Procedure UpdateHyperlinkToLayoutCompletion(ResultAddress)
	
	Result = GetFromTempStorage(ResultAddress);
	
	If ValueIsFilled(Result.ToRegister) Then
		ToRegister = Result.ToRegister;
	Else
		ToRegister = New FormattedString(NStr("vi = 'Cần lập: không';
												|ru = 'К оформлению: нет';
												|en = 'To register: no'; fa = 'To register: no';
												|it = 'Da formalizzare: no';
												|pl = 'Do rejestracji: brak';
												|tr = 'Düzenlenecek: yok'"));
	EndIf;
	
	If ValueIsFilled(Result.SeeAlsoInProgress) Then
		SeeAlsoInProgress = Result.SeeAlsoInProgress;
		Items.SeeAlsoInProgress.Visible = True;
	Else
		Items.SeeAlsoInProgress.Visible = False;
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
		UpdateHyperlinkToLayoutCompletion(Result.ResultAddress);
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
