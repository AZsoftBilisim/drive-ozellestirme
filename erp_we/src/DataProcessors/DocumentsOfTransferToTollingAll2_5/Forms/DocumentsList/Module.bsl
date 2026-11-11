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
	
	URL = "e1cib/app/DataProcessor.DocumentsOfTransferToTollingAll2_5";
	
	RestoreSettings(Parameters);
	
	VTBusinessTransactionsAndDocumentTypes = TMCommonUse.AvailableBusinessTransactionsAndDocuments(
		DescriptionOfOperationsAndDocumentTypes(), FilterBusinessTransactions, FilterDocumentTypes, PurposeUseKey);
		
	VTBusinessTransactionsAndDocumentTypes.Sort("Order");
	
	BusinessTransactionsAndDocuments.Load(VTBusinessTransactionsAndDocumentTypes);
	
	ConfigureFormForSelectedOperationsAndDocuments(VTBusinessTransactionsAndDocumentTypes);
	
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject, Items.GlobalCommandsGroup);
	// End IntegrationWith1CDocumentManagementSubsystem
	
	// Document verificationreferences
	ListProperties = Common.DynamicListPropertiesStructure();
	FillPropertyValues(ListProperties, ListProcessingDocuments);
	DocumentVerificationServer.ModifyDynamicDocumentLogListRequest(ListProperties.QueryText, "DocumentsRegistryOverridable");
	Common.SetDynamicListProperties(Items.ListProcessingDocuments, ListProperties);
	// End Document verificationreferences
	
	DocumentTypesUsed = VTBusinessTransactionsAndDocumentTypes.UnloadColumn("DocumentType");
	DocumentTypesUsed.Add(Type("DocumentRef.ReversingEntry"));
	
	
	// StandardSubsystems.AttachableCommands
	PlacementParameters = AttachableCommands.PlacementParameters();
	PlacementParameters.Sources = New TypeDescription(DocumentTypesUsed);
	PlacementParameters.CommandBar = Items.ListProcessingDocumentsCommandBar;
	AttachableCommands.OnCreateAtServer(ThisObject, PlacementParameters);
	// End StandardSubsystems.AttachableCommands
	
	// StandardSubsystems.SourceDocumentsOriginalsRecording
	SourceDocumentsOriginalsRecording.OnCreateAtServerListForm(
		ThisObject,
		Items.ListProcessingDocuments,
		Items.ListProcessingDocumentsWarehouse);
	// End StandardSubsystems.SourceDocumentsOriginalsRecording
	
	AdditionalParameters = New Structure("LocationOfLocalValidationData", Items.ReglGroupVerification);
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing, AdditionalParameters);
	
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
	
	// Peripherals
	If Source = "Peripherals" And IsInputAvailable() Then
		If EventName = "ScanData" And EquipmentManagerTMClient.ThereIsRawEvent() Then
			ProcessBarcodes(EquipmentManagerTMClient.ConvertDataFromScannerToStructure(Parameter));
		EndIf;
	EndIf;
	// End Peripherals
	
	If EventName = "Write_TransferOfGoodsToBailee"
	 Or EventName = "Write_ReceiptOfGoodsFromCustodian"
	 Or EventName = "Write_SubcontractorReport2_5"
	 Or EventName = "Write_VendorInvoiceReceived"
	 Or EventName = "Write_WriteOffOfShippedGoods"
	 Or EventName = "Write_RedemptionOfGoodsByCustodian"
	 Or EventName = "Write_DiscrepancyReportFollowingShipment"
	 Or EventName = "Write_DiscrepancyReportFollowingReceipt"
	 Or EventName = "Write_PurchaseAdjustment"
	 Or EventName = "Accept_FormOfCreatedDocuments"
	 Or EventName = "Conducting_Storno"
	 Or EventName = "Write_ReversingEntry"
	 Or EventName = "IssuedSalesDocument"
	 	And (Source.FormName = "DataProcessor.DocumentsOfTransferToTollingAll2_5.Form.DocumentsList"
	 		Or Source.FormName = "DataProcessor.DocumentsOfTransferToTollingAll2_5.Form.ToRegisterInvoices") Then
		
		// DynamicListsSettings
		UpdateListOfDocumentsEventNotificationProcessing("ListProcessingDocuments", Parameter);
		// End DynamicListsSettings
		
		UpdateHyperlinkToLayout();
		
	ElsIf EventName = "Write_MisgradingOfGoodsAtCustodian"
		  Or EventName = "Write_DamageAtCustodian" Then
		
		// DynamicListsSettings
		UpdateListOfDocumentsEventNotificationProcessing("ListProcessingDocuments", Parameter);
		// End DynamicListsSettings
		
	ElsIf EventName = "Write_SubcontractOrder2_5" Then
		
		UpdateHyperlinkToLayout();
		
	EndIf;
	
	
	// StandardSubsystems.SourceDocumentsOriginalsRecording
	SourceDocumentsOriginalsRecordingClient.NotificationHandlerListForm(EventName, ThisObject, Items.ListProcessingDocuments);
	// End StandardSubsystems.SourceDocumentsOriginalsRecording
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure OrganizationOnChange(Item)
	OrganizationWhenChangedOnServer();
EndProcedure

&AtClient
Procedure WarehouseOnChange(Item)
	WarehouseWhenChangedOnServer();
EndProcedure

&AtClient
Procedure ManagerOnChange(Item)
	ManagerForChangesOnServer();
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
		
		AddressOfAvailableBusinessTransactionsAndDocuments = ValueSelected;
		
		SelectionOperationTypeSelectionProcessingServer(AddressOfAvailableBusinessTransactionsAndDocuments);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ToRegisterURLProcessing(Item, FormattedStringURL, StandardProcessing)
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.TimeMeasurement(
		"DataProcessor.DocumentsOfTransferToTollingAll2_5.Form.DocumentsList.Event.ToRegisterURLProcessing");
	
	StandardProcessing = False;
	
	FormParameters = New Structure;
	QuickFilterStructure = New Structure;
	QuickFilterStructure.Insert("Organization",	Organization);
	QuickFilterStructure.Insert("Warehouse",		Warehouse);
	QuickFilterStructure.Insert("Manager",	Manager);
	FormParameters.Insert("QuickFilterStructure", QuickFilterStructure);
	FormParameters.Insert("PurposeUseKey", DefaultFormAssignmentKey());
	
	NamesArray = StrSplit(FormattedStringURL, "/", False);
	If NamesArray.Count() > 1 Then
		FormParameters.Insert("CurrentPageName", TrimAll(NamesArray[1]));
	EndIf;
	
	OpenForm(NamesArray[0], FormParameters);
	
	If FormParameters.Property("CurrentPageName") Then // If the form has already been opened
		Notify("PageChange_" + Item.Name, FormParameters.CurrentPageName, ThisForm);
	EndIf;
	
EndProcedure

&AtClient
Procedure SeeAlsoInProgressURLProcessing(Item, FormattedStringURL, StandardProcessing)
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.TimeMeasurement(
		"DataProcessor.DocumentsOfTransferToTollingAll2_5.Form.DocumentsList.Event.SeeAlsoInProgressURLProcessing");
	
	StandardProcessing = False;
	
	FormParameters = New Structure;
	QuickFilterStructure = New Structure;
	QuickFilterStructure.Insert("Organization",Organization);
	QuickFilterStructure.Insert("Warehouse",Warehouse);
	FormParameters.Insert("QuickFilterStructure", QuickFilterStructure);
	
	OpenForm(FormattedStringURL, FormParameters,ThisForm, UUID);
	
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
		SourceDocumentsOriginalsRecordingClient.ListSelection(
			Field.Name,
			ThisObject,
			Items.ListProcessingDocuments,
			StandardProcessing);
		// End StandardSubsystems.SourceDocumentsOriginalsRecording
		Return;
	EndIf;
	
	TMCommonUseClient.ChangeElement(Item);
	
	If Field = Items.StatusPresentation Then
	EndIf;
	
EndProcedure

&AtClient
Procedure ListBeforeRowChange(Item, Cancel)
	
	Cancel = True;
	TMCommonUseClient.ChangeElement(Item);
	
EndProcedure

&AtServerNoContext
Procedure ListProcessingDocumentsOnGetDataAtServer(TagName, Settings, Rows)
	
	// StandardSubsystems.SourceDocumentsOriginalsRecording
	SourceDocumentsOriginalsRecording.OnGetDataAtServer(Rows);
	// End StandardSubsystems.SourceDocumentsOriginalsRecording
	
EndProcedure

&AtClient
Procedure ListBeforeDeleteRow(Item, Cancel)
	
	Cancel = True;
	
	Notification = New CallbackDescription("ListSetDeletionMarkCompletion", ThisForm);
	TMCommonUseClient.SetDeletionMark(Item, Title, Notification);
	
EndProcedure

&AtServer
Procedure ListProcessingDocumentsOnUpdateUserSettingSetAtServer(Item, StandardProcessing)
	
	// DynamicListsSettings
	OperationsWithDocumentJournals.SetVisibilityOfDefaultUpdateSettingsGroup(ThisObject, "ListProcessingDocuments");
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
	
	TMCommonUseClient.CopyItem(Items.ListProcessingDocuments);
	
EndProcedure

&AtClient
Procedure ListChange(Command)
	
	TMCommonUseClient.ChangeElement(Items.ListProcessingDocuments);
	
EndProcedure

&AtClient
Procedure ListSetDeletionMark(Command)
	
	Notification = New CallbackDescription("ListSetDeletionMarkCompletion", ThisForm);
	TMCommonUseClient.SetDeletionMark(Items.ListProcessingDocuments, Title, Notification,
		OperationsWithDocumentJournalsClient.ParametersForUpdatingDocumentList(ThisObject, "ListProcessingDocuments"));
	
EndProcedure

&AtClient
Procedure ListSetDeletionMarkCompletion(Result, AdditionalParameters) Export
	
	If Result = DialogReturnCode.Yes Then
		Notify("SetDeleteMark_JournalOfDocumentsTransferredToProcessing2_5",, ThisForm);
		ListDeletionMarkServer();
	EndIf;
	
EndProcedure

&AtClient
Procedure ListUndoPosting(Command)
	
	TMCommonUseClient.UndoPosting(Items.ListProcessingDocuments, Title,
		OperationsWithDocumentJournalsClient.ParametersForUpdatingDocumentList(ThisObject, "ListProcessingDocuments"));
	Notify("CancellationOf_JournalOfDocumentsOfTransferToProcessing2_5", , ThisForm);
	ListUndoPostingServer();
	
EndProcedure

&AtClient
Procedure ListPost(Command)
	
	TMCommonUseClient.PostDocuments(Items.ListProcessingDocuments, Title,
		OperationsWithDocumentJournalsClient.ParametersForUpdatingDocumentList(ThisObject, "ListProcessingDocuments"));
	Notify("ToCarryOut_JournalOfDocumentsOfTransferToProcessing2_5", , ThisForm);
	ListPostServer();
	
EndProcedure

// StandardSubsystems.AttachableCommands
&AtClient
Procedure Attachable_ExecuteCommand(Command)
	AttachableCommandsClient.ExecuteCommand(ThisObject, Command, Items.ListProcessingDocuments);
EndProcedure

&AtServer
Procedure Attachable_ExecuteCommandAtServer(Context, Result) Export
	AttachableCommands.ExecuteCommand(ThisObject, Context, Items.ListProcessingDocuments, Result);
EndProcedure

&AtClient
Procedure Attachable_UpdateCommands()
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Items.ListProcessingDocuments);
EndProcedure
// End StandardSubsystems.AttachableCommands

// IntegrationWith1CDocumentManagementSubsystem
&AtClient
Procedure Attachable_ExecuteIntegrationCommand(Command)
	
	IntegrationWith1CDocumentManagementCoreClient.ExecutePlugInIntegrationCommand(Command, ThisObject, Items.ListProcessingDocuments);
	
EndProcedure
// End IntegrationWith1CDocumentManagementSubsystem

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure


// StandardSubsystems.SourceDocumentsOriginalsRecording
&AtClient
Procedure Attachable_UpdateOriginalStateCommands()
	
	UpdateOriginalStateCommands()
	
EndProcedure

&AtServer
Procedure UpdateOriginalStateCommands()
	
	VTBusinessTransactionsAndDocumentTypes = TMCommonUse.AvailableBusinessTransactionsAndDocuments(DescriptionOfOperationsAndDocumentTypes(),
		FilterBusinessTransactions, FilterDocumentTypes, PurposeUseKey);
	VTBusinessTransactionsAndDocumentTypes.Sort("Order");	
	DocumentTypesUsed = VTBusinessTransactionsAndDocumentTypes.UnloadColumn("DocumentType");

	// StandardSubsystems.AttachableCommands
	PlacementParameters = AttachableCommands.PlacementParameters();
	PlacementParameters.Sources = New TypeDescription(DocumentTypesUsed);
	PlacementParameters.CommandBar = Items.ListProcessingDocumentsCommandBar;
	AttachableCommands.OnCreateAtServer(ThisObject, PlacementParameters);
	// End StandardSubsystems.AttachableCommands
	
EndProcedure
//End StandardSubsystems.SourceDocumentsOriginalsRecording

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
Procedure DocumentsListRefresh(Command)
	
	// DynamicListsSettings
	UpdateDocumentListDataWithTimeMeasurement("ListProcessingDocuments");
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
				|tr = 'Barkoda göre belge araması gerçekleşiyor...'"));
	BarcodeData = BarcodeDataOfPrintedForm(Data.Barcode, "ListProcessingDocuments");
	TMCommonUseClient.ProcessBarcodes(Data.Barcode, BarcodeData, ThisForm, "ListProcessingDocuments");
	
EndProcedure

#EndRegion

#Region AttributesOnChange

&AtServer
Procedure OrganizationWhenChangedOnServer()
	
	SetSelectionByOrganization();
	SetVisibilityAvailability();
	UpdateHyperlinkToLayout();
	
EndProcedure

&AtServer
Procedure WarehouseWhenChangedOnServer()
	
	SetSelectionByWarehouse();
	SetVisibilityAvailability();
	UpdateHyperlinkToLayout();
	
EndProcedure

&AtServer
Procedure ManagerForChangesOnServer()
	
	CommonClientServer.SetDynamicListFilterItem(
		ListProcessingDocuments,
		"Manager",
		Manager,
		DataCompositionComparisonType.Equal,
		,
		ValueIsFilled(Manager));
	SetVisibilityAvailability();
	UpdateHyperlinkToLayout();
	
	// DynamicListsSettings
	OperationsWithDocumentJournals.SetVisibilityOfDefaultUpdateSettingsGroup(ThisObject, "ListProcessingDocuments");
	// End DynamicListsSettings
	
EndProcedure

#EndRegion

#Region FormSettings

&AtServer
Procedure SetConditionalAppearance()

	StandardSubsystemsServer.SetDateFieldConditionalAppearance(ThisObject, "ListProcessingDocuments.Date", "Date");
	
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
Procedure ConfigureFormForSelectedOperationsAndDocuments(VTBusinessTransactionsAndDocumentTypes)
	
	WorkplaceData = TMCommonUse.WorkplaceData(
												VTBusinessTransactionsAndDocumentTypes, 
												DefaultFormAssignmentKey(),
												NStr("vi = 'Chứng từ chuyển giao vào gia công (tất cả)';
													|ru = 'Документы передачи в переработку (все)';
													|en = 'External subcontracting — All documents'; fa = 'پیمانکاری فرعی خارجی — همه اسناد';
													|it = 'Documenti di consegna in trasformazione (tutti)';
													|pl = 'Dokumenty przekazania do przetwarzania (wszystkie)';
													|tr = 'Fason üretim transfer belgeleri (tümü)'"));
	
	Title = WorkplaceData.WorkplaceTitle;
	
	PurposeUseKey = WorkplaceData.PurposeUseKey;
	
	SetDynamicListSelections();
	UpdateHyperlinkToLayout();
	SetVisibilityAvailability();
	
	TMCommonUse.ReplaceLinkFieldWithExpressByDocumentTypeConstruct(Items.ListProcessingDocuments,
		BusinessTransactionsAndDocuments);
	
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
		Items.Organization.Visible = False;
		Items.ListProcessingDocumentsOrganization.Visible = False;
	Else
		Items.ListProcessingDocumentsOrganization.Visible = Not ValueIsFilled(Organization);
	EndIf;
	
	If Not GetFunctionalOption("UseSeveralWarehouses") Then
		Items.Warehouse.Visible = False;
		Items.ListProcessingDocumentsWarehouse.Visible = False;
	Else
		Items.ListProcessingDocumentsWarehouse.Visible = Not ValueIsFilled(Warehouse);
	EndIf;
	
	If Not GetFunctionalOption("EmployeeInChargeInDocuments") Then
		Items.Manager.Visible = False;
		Items.ListProcessingDocumentsManager.Visible = False;
	Else
		Items.ListProcessingDocumentsManager.Visible = Not ValueIsFilled(Manager);
	EndIf;
	
	If Not GetFunctionalOption("UseMultipleCurrencies") Then
		Items.ListProcessingDocumentsCurrency.Visible = False;
	EndIf;
	
	Items.ListProcessingDocumentsCounterparty.Visible = GetFunctionalOption("UsePartnersAndCounterparties");
	
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

#EndRegion

#Region Filters

&AtServer
Procedure SelectionOperationTypeSelectionProcessingServer(AddressOfBusinessTransactionsAndDocuments)
	
	VTBusinessTransactionsAndDocumentTypes = GetFromTempStorage(AddressOfBusinessTransactionsAndDocuments);
	BusinessTransactionsAndDocuments.Load(VTBusinessTransactionsAndDocumentTypes);
	TMCommonUse.FillInSelectionsAccordingToTableOfBusinessTransactionsAndDocumentTypes(VTBusinessTransactionsAndDocumentTypes, FilterBusinessTransactions, FilterDocumentTypes);
	
	ConfigureFormForSelectedOperationsAndDocuments(VTBusinessTransactionsAndDocumentTypes);
	
EndProcedure

&AtServer
Procedure SetDynamicListSelections()
	
	CommonClientServer.SetDynamicListFilterItem(
		ListProcessingDocuments,
		"RefType",
		FilterDocumentTypes,
		DataCompositionComparisonType.InList,
		,
		True);
	
	CommonClientServer.SetDynamicListFilterItem(
		ListProcessingDocuments,
		"BusinessOperation",
		FilterBusinessTransactions,
		DataCompositionComparisonType.InList,
		,
		True);
	
	SetSelectionByOrganization();
	SetSelectionByWarehouse();
	
	CommonClientServer.SetDynamicListFilterItem(
		ListProcessingDocuments,
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
	CompaniesList.Add(Organization);
	If ValueIsFilled(Organization)
		And GetFunctionalOption("UseBranchOfficesWithSeparateBalanceSheets") Then
		
		Query = New Query("
		|SELECT ALLOWED
		|	Companies.Ref
		|FROM
		|	Catalog.Companies AS Companies
		|WHERE
		|	Companies.BranchOffice
		|	AND Companies.ParentCompany = &Organization
		|	AND Companies.TransactionsUsingParentCompanyAreAllowed");
		Query.SetParameter("Organization", Organization);
		
		Selection = Query.Execute().Select();
		While Selection.Next() Do
			CompaniesList.Add(Selection.Ref);
		EndDo;
	EndIf;
	
	CommonClientServer.SetDynamicListFilterItem(
		ListProcessingDocuments,
		"Organization",
		CompaniesList,
		DataCompositionComparisonType.InList,
		,
		ValueIsFilled(Organization));
	
	// DynamicListsSettings
	OperationsWithDocumentJournals.SetVisibilityOfDefaultUpdateSettingsGroup(ThisObject, "ListProcessingDocuments");
	// End DynamicListsSettings
	
EndProcedure

&AtServer
Procedure SetSelectionByWarehouse()
	
	FilterWarehouses = WarehousesServer.ListOfSubordinateWarehouses(Warehouse);
	FilterStorageLocations_ = Catalogs.DocumentRegistryKeys.KeysByValue(FilterWarehouses);
	
	CommonClientServer.SetDynamicListFilterItem(ListProcessingDocuments,
																			"StorageLocation",
																			FilterStorageLocations_,
																			DataCompositionComparisonType.InList,
																			,
																			ValueIsFilled(FilterStorageLocations_));
	// DynamicListsSettings
	OperationsWithDocumentJournals.SetVisibilityOfDefaultUpdateSettingsGroup(ThisObject, "ListProcessingDocuments");
	// End DynamicListsSettings
	
EndProcedure

&AtServer
Procedure SetSelectionByPeriod()
	
	ListProcessingDocuments.Parameters.SetParameterValue("BeginOfPeriod", Period.StartDate);
	ListProcessingDocuments.Parameters.SetParameterValue("EndOfPeriod", 
		?(ValueIsFilled(Period.EndDate), Period.EndDate, EndOfDay(Date(3999, 12, 31))));
	
	// DynamicListsSettings
	OperationsWithDocumentJournals.SetVisibilityOfDefaultUpdateSettingsGroup(ThisObject, "ListProcessingDocuments");
	// End DynamicListsSettings
	
EndProcedure

#EndRegion

#Region Other

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
Procedure RestoreSettings(Var_Parameters)
	
	ListOfDocumentsAutoUpdateMode = True;
	
	If Var_Parameters.Property("QuickFilterStructure") Then
		FillPropertyValues(ThisForm, FormSettings(Var_Parameters.QuickFilterStructure));
	Else
		SettingsFromStorage = Common.CommonSettingsStorageLoad(
			"DataProcessor.DocumentsOfTransferToTollingAll2_5.Form.DocumentsList", PurposeUseKey);
		
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
	
	Common.CommonSettingsStorageSave(
		"DataProcessor.DocumentsOfTransferToTollingAll2_5.Form.DocumentsList",
		PurposeUseKey,
		FormSettings(ThisForm));
	
EndProcedure

&AtServer
Function DescriptionOfOperationsAndDocumentTypes()
	
	VTBusinessTransactionsAndDocumentTypes = BusinessTransactionsAndDocuments.Unload();
	VTBusinessTransactionsAndDocumentTypes.Clear();
	
	RowData = New Structure;
	For Each Column In VTBusinessTransactionsAndDocumentTypes.Columns Do
		RowData.Insert(Column.Name);
	EndDo;
	
	String = VTBusinessTransactionsAndDocumentTypes.Add();
	String.BusinessOperation 				 = Enums.BusinessTransactions.TransferToToller2_5;
	String.DocumentType 						 = Type("DocumentRef.TransferOfGoodsToBailee");
	String.FullDocumentName					 = Metadata.Documents.TransferOfGoodsToBailee.FullName();
	String.AddButtonCreate				 = True;
	String.PurposeUseKey			 = "SubcontractingServicesReceivedAllDocuments";
	String.WorkplaceTitle				 = NStr("vi = 'Chứng từ chuyển giao vào gia công (chuyển giao cho người nhận gia công)';
												|ru = 'Документы передачи в переработку (передачи переработчику)';
												|en = 'Subcontracting services received — Transfers to subcontractor'; fa = 'Subcontracting services received — Transfers to subcontractor';
												|it = 'Documenti di trasferimento in elaborazione (trasferimenti all''elaboratore)';
												|pl = 'Dokumenty przekazania do przetwarzania (przekazania przetwórcy)';
												|tr = 'Fason üretim transfer belgeleri (fason üreticiye transferler)'");
	String.HyperlinkCalculationManagerForRegistration = "TransferToToller";
	String.DocumentPresentation				 = NStr("vi = 'Chuyển giao cho bên nhận gia công';
														|ru = 'Передача переработчику';
														|en = 'Customer stock fill-up'; fa = 'تکمیل موجودی مشتری';
														|it = 'Trasferimento al subfornitore';
														|pl = 'Przekazanie przetwórcy';
														|tr = 'Fason üreticiye transfer'");
	String.Order								 = 1;
	
	String = VTBusinessTransactionsAndDocumentTypes.Add();
	String.BusinessOperation				 = Enums.BusinessTransactions.ProductionByToller2_5;
	String.DocumentType							 = Type("DocumentRef.SubcontractorReport2_5");
	String.FullDocumentName					 = Metadata.Documents.SubcontractorReport2_5.FullName();
	String.AddButtonCreate				 = True;
	String.PurposeUseKey			 = "SubcontractingServicesReceivedAllDocuments";
	String.WorkplaceTitle				 = NStr("vi = 'Chứng từ chuyển giao vào gia công (bảng kê của người nhận gia công)';
												|ru = 'Документы передачи в переработку (отчеты переработчика)';
												|en = 'Subcontracting services notifications received'; fa = 'اعلامیه‌های خدمات پیمانکاری فرعی دریافت‌شده';
												|it = 'Documenti di trasferimento in elaborazione (report elaboratore)';
												|pl = 'Dokumenty przekazania do przetwarzania (raporty przetwórcy)';
												|tr = 'Fason üretim transfer belgeleri (Fason üretici raporları)'");
	String.HyperlinkCalculationManagerForRegistration = "Document.SubcontractorReport2_5";
	String.Order								 = 2;
	
	String = VTBusinessTransactionsAndDocumentTypes.Add();
	String.BusinessOperation				 = Enums.BusinessTransactions.ProductionAtProcessorInEAEUCountries2_5;
	String.DocumentType							 = Type("DocumentRef.SubcontractorReport2_5");
	String.FullDocumentName					 = Metadata.Documents.SubcontractorReport2_5.FullName();
	String.AddButtonCreate				 = True;
	String.PurposeUseKey			 = "SubcontractingServicesReceivedAllDocuments";
	String.WorkplaceTitle				 = NStr("vi = 'Chứng từ chuyển giao vào gia công (bảng kê của người nhận gia công)';
												|ru = 'Документы передачи в переработку (отчеты переработчика)';
												|en = 'Subcontracting services notifications received'; fa = 'اعلامیه‌های خدمات پیمانکاری فرعی دریافت‌شده';
												|it = 'Documenti di trasferimento in elaborazione (report elaboratore)';
												|pl = 'Dokumenty przekazania do przetwarzania (raporty przetwórcy)';
												|tr = 'Fason üretim transfer belgeleri (Fason üretici raporları)'");
	String.HyperlinkCalculationManagerForRegistration = "Document.SubcontractorReport2_5";
	String.Order								 = 3;
	
	String = VTBusinessTransactionsAndDocumentTypes.Add();
	String.BusinessOperation 		         = Enums.BusinessTransactions.ReceiptFromToller2_5;
	String.DocumentType 				         = Type("DocumentRef.ReceiptOfGoodsFromCustodian");
	String.FullDocumentName			         = Metadata.Documents.ReceiptOfGoodsFromCustodian.FullName();
	String.AddButtonCreate		         = True;
	String.PurposeUseKey	         = "SubcontractingServicesReceivedAllDocuments";
	String.WorkplaceTitle		         = NStr("vi = 'Chứng từ chuyển giao vào gia công (tiếp nhận từ người nhận gia công)';
												|ru = 'Документы передачи в переработку (поступления от переработчика)';
												|en = 'Subcontracting services received — Receipts from subcontractor'; fa = 'Subcontracting services received — Receipts from subcontractor';
												|it = 'Documenti di trasferimento in elaborazione (ricezione dall''elaboratore)';
												|pl = 'Dokumenty przekazania do przetwarzania (wpływy od przetwórcy)';
												|tr = 'Fason üretim transfer belgeleri (Fason üreticiden giriş)'");
	String.HyperlinkCalculationManagerForRegistration = "ReceiptFromToller";
	String.DocumentPresentation				 = NStr("vi = 'Tiếp nhận từ người nhận gia công';
														|ru = 'Поступление от переработчика';
														|en = 'Goods receipt — External subcontracting'; fa = 'رسید انبار — پیمانکاری فرعی خارجی';
														|it = 'Ricezione dal subfornitore';
														|pl = 'Wpływ od przetwórcy';
														|tr = 'Fason üreticiden gelen ürünleri teslim alma'");
	String.Order								 = 4;
	
	FillPropertyValues(RowData, String);
	
	String = VTBusinessTransactionsAndDocumentTypes.Add();
	FillPropertyValues(String, RowData);
	String.BusinessOperation                 = Enums.BusinessTransactions.ReturnFromProcessingCompany2_5;
	String.HyperlinkCalculationManagerForRegistration = "ReturnFromProcessingCompany";
	String.Order								 = 5;
	
	String = VTBusinessTransactionsAndDocumentTypes.Add();
	String.BusinessOperation 		         = Enums.BusinessTransactions.GoodsWriteOffAtToller;
	String.DocumentType 				         = Type("DocumentRef.WriteOffOfShippedGoods");
	String.FullDocumentName			         = Metadata.Documents.WriteOffOfShippedGoods.FullName();
	String.AddButtonCreate		         = True;
	String.PurposeUseKey	         = "SubcontractingServicesReceivedAllDocuments";
	String.WorkplaceTitle		         = NStr("vi = 'Chứng từ chuyển giao vào gia công (ghi giảm từ người nhận gia công)';
												|ru = 'Документы передачи в переработку (списания у переработчика)';
												|en = 'Subcontracting services received — Write-off at subcontractor'; fa = 'Subcontracting services received — Write-off at subcontractor';
												|it = 'Documenti di trasferimento in elaborazione (storno presso l''elaboratore)';
												|pl = 'Dokumenty przekazania do przetwarzania (rozchody u przetwórcy)';
												|tr = 'Fason üretim transfer belgeleri (Fason üreticide silinenler)'");
	String.DocumentPresentation				 = NStr("vi = 'Bảng kê ghi giảm hàng hóa của người nhận gia công';
														|ru = 'Отчет о списании товаров у переработчика';
														|en = 'Subcontractor stock adjustment'; fa = 'تعدیل موجودی نزد پیمانکار فرعی';
														|it = 'Report sulla cancellazione degli articoli presso l''elaboratore';
														|pl = 'Raport o rozchodzie towarów u przetwórcy';
														|tr = 'Fason üreticide ürünlerin silinmesine ilişkin rapor'");
	String.Order								 = 7;
	
	String = VTBusinessTransactionsAndDocumentTypes.Add();
	String.BusinessOperation 		         = Enums.BusinessTransactions.RedemptionOfGoodsByToller;
	String.DocumentType 				         = Type("DocumentRef.RedemptionOfGoodsByCustodian");
	String.FullDocumentName			         = Metadata.Documents.RedemptionOfGoodsByCustodian.FullName();
	String.AddButtonCreate		         = True;
	String.PurposeUseKey	         = "SubcontractingServicesReceivedAllDocuments";
	String.WorkplaceTitle		         = NStr("vi = 'Chứng từ chuyển giao vào gia công (mua lại bởi người nhận gia công)';
												|ru = 'Документы передачи в переработку (выкупы переработчиком)';
												|en = 'External subcontracting — Repurchase by subcontractor'; fa = 'External subcontracting — Repurchase by subcontractor';
												|it = 'Documenti di trasferimento in elaborazione (reso da parte dell''elaboratore)';
												|pl = 'Dokumenty przekazania do przetwarzania (wykupy przez przetwórcę)';
												|tr = 'Fason üretim transfer belgeleri (Fason üretici tarafından geri alma)'");
	String.DocumentPresentation				 = NStr("vi = 'Người nhận gia công mua lại hàng hóa';
														|ru = 'Выкуп товаров переработчиком';
														|en = 'Sales invoice — External subcontracting'; fa = 'فاکتور فروش — پیمانکاری فرعی خارجی';
														|it = 'Rimborso dei materiali da parte dell''elaboratore';
														|pl = 'Wykup towarów przez przetwórcę';
														|tr = 'Ürünlerin fason üretici tarafından geri alınması'");
	String.Order								 = 8;
	
	String = VTBusinessTransactionsAndDocumentTypes.Add();
	String.BusinessOperation 		         = Enums.BusinessTransactions.DamageAtToller;
	String.DocumentType 				         = Type("DocumentRef.DamageAtCustodian");
	String.FullDocumentName			         = Metadata.Documents.DamageAtCustodian.FullName();
	String.AddButtonCreate		         = True;
	String.PurposeUseKey	         = "SubcontractingServicesReceivedAllDocuments";
	String.WorkplaceTitle		         = NStr("vi = 'Chứng từ chuyển giao vào gia công (hàng hỏng của người nhận gia công)';
												|ru = 'Документы передачи в переработку (порчи у переработчика)';
												|en = 'External subcontracting — Stock quality change at subcontractor'; fa = 'External subcontracting — Stock quality change at subcontractor';
												|it = 'Documenti di trasferimento in elaborazione (usura presso l''elaboratore)';
												|pl = 'Dokumenty przekazania do przetwarzania (uszkodzenia u przetwórcy)';
												|tr = 'Fason üretim transfer belgeleri (Fason üreticide stok kalite değişikliği)'");
	String.DocumentPresentation				 = NStr("vi = 'Hàng hỏng của bên nhận gia công';
														|ru = 'Порча товаров у переработчика';
														|en = 'Stock quality change at subcontractor'; fa = 'تغییر کیفیت موجودی نزد پیمانکار فرعی';
														|it = 'Usura dei prodotti presso l''elaboratore';
														|pl = 'Uszkodzenie towarów u przetwórcy';
														|tr = 'Fason üretici ürünlerinin stok kalite değişikliği'");
	String.Order								 = 9;
	
	String = VTBusinessTransactionsAndDocumentTypes.Add();
	String.BusinessOperation 		         = Enums.BusinessTransactions.MisgradingOfGoodsAtToller;
	String.DocumentType 				         = Type("DocumentRef.MisgradingOfGoodsAtCustodian");
	String.FullDocumentName			         = Metadata.Documents.MisgradingOfGoodsAtCustodian.FullName();
	String.AddButtonCreate		         = True;
	String.PurposeUseKey	         = "SubcontractingServicesReceivedAllDocuments";
	String.WorkplaceTitle		         = NStr("vi = 'Chứng từ chuyển giao vào gia công (chuyển tồn của người nhận gia công)';
												|ru = 'Документы передачи в переработку (пересортицы у переработчика)';
												|en = 'External subcontracting — Stock reclass at subcontractor'; fa = 'External subcontracting — Stock reclass at subcontractor';
												|it = 'Documenti di trasferimento in elaborazione (riordino presso l''elaboratore)';
												|pl = 'Dokumenty przekazania do przetwarzania (przeklasyfikwowania u przetwórcy)';
												|tr = 'Fason üretim belgeleri (Fason üreticide yeniden sınıflandırma)'");
	String.DocumentPresentation				 = NStr("vi = 'Chuyển tồn hàng hóa của bên nhận gia công';
														|ru = 'Пересортица товаров у переработчика';
														|en = 'Stock reclass at subcontractor'; fa = 'طبقه‌بندی مجدد موجودی نزد پیمانکار فرعی';
														|it = 'Riclassificazione dei prodotti presso l''elaboratore';
														|pl = 'Przeklasyfikowanie towarów u przetwórcy';
														|tr = 'Fason üretici stoku yeniden sınıflandırma'");
	String.Order								 = 10;
	
	String = VTBusinessTransactionsAndDocumentTypes.Add();
	String.BusinessOperation 		= Enums.BusinessTransactions.SubcontractorReportAdjustment;
	String.DocumentType 				= Type("DocumentRef.PurchaseAdjustment");
	String.FullDocumentName			= Metadata.Documents.PurchaseAdjustment.FullName();
	String.AddButtonCreate		= False;
	String.PurposeUseKey	= "SubcontractingServicesReceivedAllDocuments";
	String.WorkplaceTitle		= NStr("vi = 'Chứng từ chuyển vào gia công (điều chỉnh)';
										|ru = 'Документы передачи в переработку (корректировки)';
										|en = 'External subcontracting — Adjustments'; fa = 'External subcontracting — Adjustments';
										|it = 'Documenti di trasferimento in elaborazione (correzioni)';
										|pl = 'Dokumenty przekazania do przetwarzania (korekty)';
										|tr = 'Fason üretim belgeleri (düzeltme)'");
	String.DocumentPresentation		= NStr("vi = 'Điều chỉnh bảng kê của bên nhận gia công';
												|ru = 'Корректировка отчета переработчика';
												|en = '""Adjust subcontracting services notification received""'; fa = '""Adjust subcontracting services notification received""';
												|it = 'Rettifica report elaboratore';
												|pl = 'Korekta raportu przetwórcy';
												|tr = 'Alınan fason üretici hizmetleri bildiriminin düzenlenmesi'");
	String.Order						= 11;
	
	If GetFunctionalOption("UseDiscrepancyReportFollowingShipmentByTransfersToSubcontractor2_5") Then
	
		String = VTBusinessTransactionsAndDocumentTypes.Add();
		String.BusinessOperation 		= Enums.BusinessTransactions.TransferToToller2_5;
		String.DocumentType 				= Type("DocumentRef.DiscrepancyReportFollowingShipment");
		String.FullDocumentName			= Metadata.Documents.DiscrepancyReportFollowingShipment.FullName();
		String.AddButtonCreate		= True;
		String.StatusesAreUsed			= True;
		String.PurposeUseKey	= "SubcontractingServicesReceivedAllDocuments";
		String.WorkplaceTitle		= NStr("vi = 'Chứng từ chuyển giao vào gia công (chênh lệch)';
											|ru = 'Документы передачи в переработку (расхождения)';
											|en = 'External subcontracting — Discrepancies'; fa = 'External subcontracting — Discrepancies';
											|it = 'Documenti di trasferimento in elaborazione (discrepanze)';
											|pl = 'Dokumenty przekazania do przetwarzania (rozbieżności)';
											|tr = 'Fason üretim belgeleri (tutarsızlık)'");
		String.DocumentPresentation		= NStr("vi = 'Biên bản chênh lệch sau khi chuyển giao cho bên nhận gia công';
													|ru = 'Акт о расхождениях после передачи переработчику';
													|en = 'Customer stock fill-up discrepancy reports'; fa = 'گزارش‌های مغایرت تکمیل موجودی مشتری';
													|it = 'Atto sulle discrepanze in seguito al trasferimento al subfornitore';
													|pl = 'Protokół o odchyleniu po przekazaniu przetwórcy';
													|tr = 'Fason üreticiye teslimi sonrası tutarsızlık raporu'");
		String.Order						= 12;
	
	EndIf;
	
	If GetFunctionalOption("UseDiscrepancyReportFollowingReceiptFromSubcontractor2_5") Then
		
		String = VTBusinessTransactionsAndDocumentTypes.Add();
		String.BusinessOperation 		= Enums.BusinessTransactions.ReceiptFromToller2_5;
		String.DocumentType 				= Type("DocumentRef.DiscrepancyReportFollowingReceipt");
		String.FullDocumentName			= Metadata.Documents.DiscrepancyReportFollowingReceipt.FullName();
		String.AddButtonCreate		= True;
		String.StatusesAreUsed			= True;
		String.PurposeUseKey	= "SubcontractingServicesReceivedAllDocuments";
		String.WorkplaceTitle       = NStr("vi = 'Chứng từ chuyển giao vào gia công (chênh lệch)';
											|ru = 'Документы передачи в переработку (расхождения)';
											|en = 'External subcontracting — Discrepancies'; fa = 'External subcontracting — Discrepancies';
											|it = 'Documenti di trasferimento in elaborazione (discrepanze)';
											|pl = 'Dokumenty przekazania do przetwarzania (rozbieżności)';
											|tr = 'Fason üretim belgeleri (tutarsızlık)'");
		String.DocumentPresentation		= NStr("vi = 'Biên bản chênh lệch sau khi bên nhận gia công tiếp nhận';
													|ru = 'Акт о расхождениях после приемки от переработчика';
													|en = 'Receipt discrepancy report from the subcontractor'; fa = 'Receipt discrepancy report from the subcontractor';
													|it = 'Atto sulle discrepanze dopo la ricezione dal subfornitore';
													|pl = 'Protokół o odchyleniach po przyjęciu od przetwórcy';
													|tr = 'Fason üreticiden alınan stok farkları raporu'");
		String.Order						= 13;
	
		FillPropertyValues(RowData, String);
		
		String = VTBusinessTransactionsAndDocumentTypes.Add();
		FillPropertyValues(String, RowData);
		String.BusinessOperation		= Enums.BusinessTransactions.ReturnFromProcessingCompany2_5;
		String.DocumentPresentation		= NStr("vi = 'Biên bản chênh lệch sau khi bên nhận gia công tiếp nhận';
													|ru = 'Акт о расхождениях после приемки от переработчика';
													|en = 'Receipt discrepancy report from the subcontractor'; fa = 'Receipt discrepancy report from the subcontractor';
													|it = 'Atto sulle discrepanze dopo la ricezione dal subfornitore';
													|pl = 'Protokół o odchyleniach po przyjęciu od przetwórcy';
													|tr = 'Fason üreticiden alınan stok farkları raporu'");
		String.Order						= 14;
		
	EndIf;
	
	VATAccountingERP.DescriptionOfOperationsAndTypesOfDocumentsForJournalOfDocumentsOfTransferToProcessing2_5(VTBusinessTransactionsAndDocumentTypes);
	
	Return VTBusinessTransactionsAndDocumentTypes;
	
EndFunction

&AtServer
Function PlaceBusinessTransactionsAndDocumentsInTemporaryStorage()
	Return PutToTempStorage(BusinessTransactionsAndDocuments.Unload(), UUID);
EndFunction

&AtClientAtServerNoContext
Function DefaultFormAssignmentKey()
	
	Return "SubcontractingServicesReceivedAllDocuments";
	
EndFunction

#EndRegion

#Region HyperlinkToDesign

&AtServer
Procedure UpdateHyperlinkToLayout()
	
	GenerationParameters = New Structure;
	GenerationParameters.Insert("Organization", Organization);
	GenerationParameters.Insert("Warehouse",       Warehouse);
	GenerationParameters.Insert("Manager",    Manager);
	GenerationParameters.Insert("PurposeUseKey", DefaultFormAssignmentKey());
	
	ToRegisterTransfer = TMCommonUse.CreateHyperlinkToDesign(
							BusinessTransactionsAndDocuments.Unload(), GenerationParameters);
		
	Items.ToRegisterTransfer.Visible = ValueIsFilled(ToRegisterTransfer);
	
	ArrayCalculationManagersSeeAlsoInWork = New Array();
	
	If GetFunctionalOption("UseSubcontractOrders2_5") Then
		ArrayCalculationManagersSeeAlsoInWork.Add("Document.SubcontractOrder2_5");
	EndIf;
	
	ToCompleteArrayOfCalculationManagersSeeAlsoLocalization(ArrayCalculationManagersSeeAlsoInWork, GenerationParameters);
	
	SeeAlsoInProgress = TMCommonUse.CreateHyperlinkSeeAlsoIn(ArrayCalculationManagersSeeAlsoInWork, GenerationParameters);
	Items.SeeAlsoInProgress.Visible = ValueIsFilled(SeeAlsoInProgress);
	
EndProcedure

#Region Localization

&AtServer
Procedure ToCompleteArrayOfCalculationManagersSeeAlsoLocalization(ArrayCalculationManagersSeeAlsoInWork, GenerationParameters)

	
	Return;
	
EndProcedure

#EndRegion

#EndRegion

#Region DynamicListsSettings

&AtServer
Procedure InitiateDynamicListSettings()
	
	DocumentListParameters = New Array;
	
	ListParameterStructure = OperationsWithDocumentJournals.StructureOfFormationOfGroupOfUserSettingsForDynamicListOnForm();
	ListParameterStructure.ListName = "ListProcessingDocuments";
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
