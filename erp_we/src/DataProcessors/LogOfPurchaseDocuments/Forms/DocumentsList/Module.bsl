
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Not AccessRight("View",Metadata.DataProcessors.LogOfPurchaseDocuments.Commands.PurchaseDocumentsAll) Then
		Cancel = True;
		Return;
	EndIf;
	
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
	
	URL = "e1cib/app/DataProcessor.LogOfPurchaseDocuments";
	
	RestoreSettings(Parameters);
	
	If ThisIsSelectionOfDocumentsForAccrualOfVendorRebatesOfRetroBonuses() Then
		
		ChoosingAcquisitionDocument = True;
		Items.HelpTextFilter.Visible = False;
		Items.ListPurchaseDocuments.ChoiceMode = True;
		
		If GetFunctionalOption("UseTermsOfPurchases") Then
			Items.ListPurchaseDocumentsTerms.Visible = True;
		EndIf;
		
	EndIf;
	
	If Parameters.Property("FilterDocumentTypes") Then
		
		FilterDocumentTypes.LoadValues(Parameters.FilterDocumentTypes);
		
	EndIf;
	
	If Parameters.Property("FilterBusinessTransactions") Then
		
		FilterBusinessTransactions.LoadValues(Parameters.FilterBusinessTransactions);
		
	EndIf;
	
	VTBusinessTransactionsAndDocumentTypes = DataProcessors.LogOfPurchaseDocuments.InitializeBusinessTransactionsAndDocuments(FilterBusinessTransactions,
		FilterDocumentTypes, PurposeUseKey);
	
	BusinessTransactionsAndDocuments.Load(VTBusinessTransactionsAndDocumentTypes);
	
	TraceabilitySelection();
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
	PlacementParameters.CommandBar = Items.ListPurchaseDocumentsCommandBar;
	AttachableCommands.OnCreateAtServer(ThisObject, PlacementParameters);
	// End StandardSubsystems.AttachableCommands
	
	If Items.EDIState.Parent = Items.ListPurchaseDocuments Then
		Placement = Items.EDIState;
	Else
		Placement = Items.EDIState.Parent;
	EndIf;
	
	// StandardSubsystems.SourceDocumentsOriginalsRecording
	SourceDocumentsOriginalsRecording.OnCreateAtServerListForm(ThisObject,Items.ListPurchaseDocuments, Placement);
	// End StandardSubsystems.SourceDocumentsOriginalsRecording
	
	RunPerformanceMeasurements = PerformanceMonitorServerCallCached.RunPerformanceMeasurements();
	EstablishCorrespondenceOfDocumentTypesAndForms(VTBusinessTransactionsAndDocumentTypes);
	
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
	
	
	
	If EventName = "Write_DiscrepancyReportFollowingReceipt"
		  Or EventName = "Write_ApplicationForImportationOfGoods"
		  Or EventName = "Write_PurchaseAdjustment"
		  Or EventName = "Write_VendorInvoice"
		  Or EventName = "Write_VendorInvoiceServicesAndAssets"
		  Or EventName = "Write_VendorInvoiceReceived"
		  Or EventName = "Write_InvoiceReceivedByTaxAgent"
		  Or EventName = "Write_CCDImport"
		  Or EventName = "ChangingStateOfUSAIS"
		  Or EventName = "Write_PaymentRequest"
		  Or EventName = "Write_BankAccountIssue"
		  Or EventName = "Write_ReturnOfGoodsToVendor"
		  Or EventName = "Write_GoodsShipmentFromStorage"
		  Or EventName = "Write_GoodsReceiptForStorage"
		  Or EventName = "Write_RedemptionOfGoodsFromStorage"
		  Or EventName = "Write_ReportOnVMIAdjustment"
		  Or EventName = "Write_UninvoicedReceipt" 
		  Or EventName = "Conducting_Storno"
		  Or EventName = "Write_ReversingEntry"
		  Or EventName = "Write_DiscrepancyReportFollowingShipment"
		  Or EventName = "Record_WriteOffOfDiscrepancies" Then
		  
			// DynamicListsSettings
			UpdateListOfDocumentsEventNotificationProcessing("ListPurchaseDocuments", Parameter);
			// End DynamicListsSettings
		  
		  WhenNotifyingAboutRecordingOfDocumentBeingProcessed();
		  ConnectHyperlinkWaitingHandlerToLayout();

	 EndIf;

	// StandardSubsystems.SourceDocumentsOriginalsRecording
	SourceDocumentsOriginalsRecordingClient.NotificationHandlerListForm(EventName, ThisObject, Items.ListPurchaseDocuments);
	// End StandardSubsystems.SourceDocumentsOriginalsRecording
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure ManagerOnChange(Item)
	
	CommonClientServer.SetDynamicListFilterItem(ListPurchaseDocuments,
		"Manager", Manager, DataCompositionComparisonType.Equal,, ValueIsFilled(Manager));
	
	// DynamicListsSettings
	OperationsWithDocumentJournalsClient.SetVisibilityOfDefaultUpdateSettingsGroup(ThisObject, "ListPurchaseDocuments");
	// End DynamicListsSettings
	
EndProcedure

&AtClient
Procedure WarehouseOnChange(Item)
	
	WarehouseOnChangeServer();
	ConnectHyperlinkWaitingHandlerToLayout();

EndProcedure

&AtClient
Procedure OrganizationOnChange(Item)
	
	SetSelectionByOrganization();
	ConnectHyperlinkWaitingHandlerToLayout();

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
	
	StandardProcessing = False;
	
	FormParameters = New Structure;
	QuickFilterStructure = New Structure;
	QuickFilterStructure.Insert("Organization",Organization);
	QuickFilterStructure.Insert("Warehouse",Warehouse);
	FormParameters.Insert("QuickFilterStructure", QuickFilterStructure);
	FormParameters.Insert("PurposeUseKey", DefaultFormAssignmentKey());
	
	If FormattedStringURL = "PageOfTheOrderForRegistration" Then
		// &PerformanceMeasurement
		PerformanceMonitorClient.StartTimeMeasurement(True,
			"DataProcessor.LogOfPurchaseDocuments.Command.InvoicesForPlacingOrders");
		
		FormParameters.Insert("CurrentPageName", FormattedStringURL);
		FormattedStringURL = "DataProcessor.LogOfPurchaseDocuments.Form.InvoicesForRegistrationList";
	ElsIf FormattedStringURL = "PageReceivingReferences" Then
		// &PerformanceMeasurement
		PerformanceMonitorClient.StartTimeMeasurement(True,
			"DataProcessor.LogOfPurchaseDocuments.Command.InvoicesForRegistrationOnAcceptance");
			
		FormParameters.Insert("CurrentPageName", FormattedStringURL);
		FormattedStringURL = "DataProcessor.LogOfPurchaseDocuments.Form.InvoicesForRegistrationList";
	ElsIf FormattedStringURL = "ReceiptOrderPage" Then
		// &PerformanceMeasurement
		PerformanceMonitorClient.StartTimeMeasurement(True,
			"DataProcessor.LogOfPurchaseDocuments.Command.InvoicesForRegistrationOfReceipts");
			
		FormParameters.Insert("CurrentPageName", FormattedStringURL);
		FormattedStringURL = "DataProcessor.LogOfPurchaseDocuments.Form.InvoicesForRegistrationList";
	EndIf;
	OpenForm(FormattedStringURL,FormParameters);
	
EndProcedure

&AtClient
Procedure SeeAlsoInProgressURLProcessing(Item, FormattedStringURL, StandardProcessing)
	
	// &PerformanceMeasurement
	KeyOperationName = StrTemplate("DataProcessor.LogOfPurchaseDocuments.Form.DocumentsList.SeeAlso.%1",
									FormattedStringURL);
	PerformanceMonitorClient.StartTimeMeasurement(True, KeyOperationName);
	
	StandardProcessing = False;
	
	FormParameters = New Structure;
	QuickFilterStructure = New Structure;
	QuickFilterStructure.Insert("Organization",Organization);
	QuickFilterStructure.Insert("Warehouse",Warehouse);
	FormParameters.Insert("QuickFilterStructure", QuickFilterStructure);
	FormParameters.Insert("CurrentPageName", "PageOfTheOrderForRegistration");
	
	// Power of attorney issued
	FormParameters.Insert("AvailabilityOfOrdersGoods", True);
	FormParameters.Insert("FormCaption", NStr("vi = 'Giấy giới thiệu để nhận hàng hóa';
												|ru = 'Доверенности на получение товаров';
												|en = 'Authorization letters for goods receipt'; fa = 'وکالت‌نامه‌های دریافت کالا';
												|it = 'Deleghe per il ritiro merci';
												|pl = 'Pełnomocnictwa do odbioru towarów';
												|tr = 'Malların kabulüne ilişkin vekaletnameler'"));
	
	
	OpenForm(FormattedStringURL, FormParameters);
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersListPurchaseDocuments

&AtClient
Procedure ListPurchaseDocumentsOnActivateRow(Item)
	
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	
EndProcedure

&AtClient
Procedure ListSelection(Item, RowSelected, Field, StandardProcessing)
	
	StandardProcessing = False;
	
	If TypeOf(RowSelected) = Type("DynamicListGroupRow") Then
		ShowMessageBox(, NStr("vi = 'Thao tác không được phép đối với dòng gom nhóm danh sách!';
								|ru = 'Действие недоступно для строки группировки списка!';
								|en = 'The action cannot be performed for a list group row.'; fa = 'The action cannot be performed for a list group row.';
								|it = 'Действие недоступно для строки группировки списка!';
								|pl = 'The action cannot be performed for a list group row.';
								|tr = 'Eylem, liste gruplama satırı için mevcut değildir!'"));
		Return;
	EndIf;
	
	If ChoosingAcquisitionDocument Then
		
		NotifyChoice(Item.CurrentData.Ref);
		Return;
		
	EndIf;
	
	If Field.Name = "SourceDocumentOriginalState" Or Field.Name = "StateOriginalReceived" Then
		// StandardSubsystems.SourceDocumentsOriginalsRecording
		SourceDocumentsOriginalsRecordingClient.ListSelection(Field.Name,ThisObject,Items.ListPurchaseDocuments, StandardProcessing);
		// End StandardSubsystems.SourceDocumentsOriginalsRecording
		Return;
	EndIf;
	
	If RunPerformanceMeasurements Then
		
		NameOfKeyOperationForOpeningForm = GetKeyOperationForOpeningDocumentFormByClickingOnLink(Item.CurrentData.Ref);
		If Not IsBlankString(NameOfKeyOperationForOpeningForm) Then
			PerformanceMonitorClient.TimeMeasurement(NameOfKeyOperationForOpeningForm);
		EndIf;
		
	EndIf;
	
	TMCommonUseClient.ChangeElement(Item);

	
EndProcedure

&AtClient
Procedure ListPurchaseDocumentsValueChoice(Item, Value, StandardProcessing)
	
	StandardProcessing = False;
	
	If ChoosingAcquisitionDocument Then
		
		NotifyChoice(Item.CurrentData.Ref);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ListCopy(Command)
	
	TMCommonUseClient.CopyItem(Items.ListPurchaseDocuments);
	
EndProcedure

&AtClient
Procedure ListChange(Command)
	
	TMCommonUseClient.ChangeElement(Items.ListPurchaseDocuments);
	
EndProcedure

&AtClient
Procedure ListUndoPosting(Command)
	
	TMCommonUseClient.UndoPosting(Items.ListPurchaseDocuments, Title,
		OperationsWithDocumentJournalsClient.ParametersForUpdatingDocumentList(ThisObject, "ListPurchaseDocuments"));
	ListUndoPostingServer();
	ConnectHyperlinkWaitingHandlerToLayout();

EndProcedure

&AtClient
Procedure ListPost(Command)
	
	TMCommonUseClient.PostDocuments(Items.ListPurchaseDocuments, Title,
		OperationsWithDocumentJournalsClient.ParametersForUpdatingDocumentList(ThisObject, "ListPurchaseDocuments"));
	ListPostServer();
	ConnectHyperlinkWaitingHandlerToLayout();

EndProcedure

&AtClient
Procedure ListSetClearADeletionMark(Command)
	
	TMCommonUseClient.SetDeletionMark(Items.ListPurchaseDocuments, Title, Undefined,
		OperationsWithDocumentJournalsClient.ParametersForUpdatingDocumentList(ThisObject, "ListPurchaseDocuments"));
	ListDeletionMarkServer();
	ConnectHyperlinkWaitingHandlerToLayout();

EndProcedure

&AtClient
Procedure ListBeforeRowChange(Item, Cancel)
	
	Cancel = True;
	TMCommonUseClient.ChangeElement(Item);
	
EndProcedure

&AtClient
Procedure ListBeforeDeleteRow(Item, Cancel)
	
	Cancel = True;
	TMCommonUseClient.SetDeletionMark(Item, Title);
	ListDeletionMarkServer();
	ConnectHyperlinkWaitingHandlerToLayout();

EndProcedure

&AtServerNoContext
Procedure ListPurchaseDocumentsOnGetDataAtServer(TagName, Settings, Rows)
	
	// StandardSubsystems.SourceDocumentsOriginalsRecording
	SourceDocumentsOriginalsRecording.OnGetDataAtServer(Rows);
	// End StandardSubsystems.SourceDocumentsOriginalsRecording
EndProcedure

&AtServer
Procedure ListPurchaseDocumentsOnUpdateUserSettingSetAtServer(Item, StandardProcessing)
	
	// DynamicListsSettings
	OperationsWithDocumentJournals.SetVisibilityOfDefaultUpdateSettingsGroup(ThisObject, "ListPurchaseDocuments");
	// End DynamicListsSettings
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

// StandardSubsystems.AttachableCommands
&AtClient
Procedure Attachable_ExecuteCommand(Command)
	AttachableCommandsClient.ExecuteCommand(ThisObject, Command, Items.ListPurchaseDocuments);
EndProcedure

&AtServer
Procedure Attachable_ExecuteCommandAtServer(Context, Result) Export
	AttachableCommands.ExecuteCommand(ThisObject, Context, Items.ListPurchaseDocuments, Result);
EndProcedure

&AtClient
Procedure Attachable_UpdateCommands()
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Items.ListPurchaseDocuments);
EndProcedure
// End StandardSubsystems.AttachableCommands

// IntegrationWith1CDocumentManagementSubsystem
&AtClient
Procedure Attachable_ExecuteIntegrationCommand(Command)
	
	IntegrationWith1CDocumentManagementCoreClient.ExecutePlugInIntegrationCommand(Command, ThisObject, Items.ListPurchaseDocuments);
	
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

// Parameters:
// 	Command - FormCommand - 
&AtClient
Procedure Attachable_SetStatus(Command)
	
	TMCommonUseClient.SetStatus(Command.Name, CorrespondenceOfCommandsToStatuses, Items.ListPurchaseDocuments,
		OperationsWithDocumentJournalsClient.ParametersForUpdatingDocumentList(ThisObject,
		"ListPurchaseDocuments"));
	
EndProcedure

// StandardSubsystems.SourceDocumentsOriginalsRecording
&AtClient
Procedure Attachable_UpdateOriginalStateCommands()
	
	UpdateOriginalStateCommands()
   
EndProcedure

&AtServer
Procedure UpdateOriginalStateCommands()
	
	VTBusinessTransactionsAndDocumentTypes = DataProcessors.LogOfPurchaseDocuments.InitializeBusinessTransactionsAndDocuments(FilterBusinessTransactions,
		FilterDocumentTypes, PurposeUseKey);
	DocumentTypesUsed = VTBusinessTransactionsAndDocumentTypes.UnloadColumn("DocumentType");
	DocumentTypesUsed.Add(Type("DocumentRef.ReversingEntry"));
	EstablishCorrespondenceOfDocumentTypesAndForms(VTBusinessTransactionsAndDocumentTypes);
	
	// StandardSubsystems.AttachableCommands
	PlacementParameters = AttachableCommands.PlacementParameters();
	PlacementParameters.Sources = New TypeDescription(DocumentTypesUsed);
	PlacementParameters.CommandBar = Items.ListPurchaseDocumentsCommandBar;
	AttachableCommands.OnCreateAtServer(ThisObject, PlacementParameters);
	// End StandardSubsystems.AttachableCommands
	
EndProcedure
//End StandardSubsystems.SourceDocumentsOriginalsRecording

&AtClient
Procedure DocumentsListRefresh(Command)
	
	// DynamicListsSettings
	UpdateDocumentListDataWithTimeMeasurement("ListPurchaseDocuments");
	// End DynamicListsSettings
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()
	
	StandardSubsystemsServer.SetDateFieldConditionalAppearance(ThisObject,
		"ListPurchaseDocuments.Date",
		"ListPurchaseDocumentsDate"
	);
	
	TMCommonUse.SetConditionalAppearanceOfFieldWithDocumentRegistryKey(ThisObject,
		Items.ListPurchaseDocumentsCounterparty.Name,
		"ListPurchaseDocuments.Counterparty"
	);
	
	TMCommonUse.SetConditionalAppearanceOfFieldWithDocumentRegistryKey(ThisObject,
		Items.ListPurchaseDocumentsWarehouse.Name,
		"ListPurchaseDocuments.Warehouse"
	);
	
	AppearanceItem = ConditionalAppearance.Items.Add();
	AppearanceItem.Use = True;
	AppearanceItem.Appearance.SetParameterValue("Format", "DLF=D");
	
	FormattedField = AppearanceItem.Fields.Items.Add();
	FormattedField.Field = New DataCompositionField("ListPurchaseDocumentsIncomingDocumentDate");
	
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
	BarcodeData = BarcodeDataOfPrintedForm(Data.Barcode, "ListPurchaseDocuments");
	TMCommonUseClient.ProcessBarcodes(Data.Barcode, BarcodeData, ThisForm, "ListPurchaseDocuments");
	
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
Procedure SetVisibilityAvailability(CurrentKey)
	
	If Not GetFunctionalOption("UseMultipleCompanies") Then
		Items.Organization.Visible = False;
	EndIf;
	
	If Not GetFunctionalOption("UseSeveralWarehouses") Then
		Items.ListPurchaseDocumentsWarehouse.Visible 				= False;
		Items.Warehouse.Visible 									= False;
	EndIf;
	
	Items.ListPurchaseDocumentsContract.Visible = GetFunctionalOption("UseContractsWithVendors");
	Items.ListPurchaseDocumentsCounterparty.Visible = GetFunctionalOption("UsePartnersAndCounterparties");
	
	// Re-filling the list of statuses
	TMCommonUse.SetListOfStatuses(ThisForm, Items.SetStatus);
	
	Items.GroupListDownloadFromScan.Visible = GetFunctionalOption("NotBaseVersion");
		
EndProcedure

&AtServer
Procedure SelectionOperationTypeSelectionProcessingServer(AddressOfBusinessTransactionsAndDocuments)
	
	VTBusinessTransactionsAndDocumentTypes = GetFromTempStorage(AddressOfBusinessTransactionsAndDocuments);
	BusinessTransactionsAndDocuments.Load(VTBusinessTransactionsAndDocumentTypes);
	TMCommonUse.FillInSelectionsAccordingToTableOfBusinessTransactionsAndDocumentTypes(VTBusinessTransactionsAndDocumentTypes, FilterBusinessTransactions, FilterDocumentTypes);
	EstablishCorrespondenceOfDocumentTypesAndForms(VTBusinessTransactionsAndDocumentTypes);
	ConfigureFormForSelectedOperationsAndDocuments(VTBusinessTransactionsAndDocumentTypes);
	
EndProcedure

&AtServer
Procedure SetDynamicListSelections(CurrentKey = Undefined)
	
	FilterWarehouses = WarehousesServer.ListOfSubordinateWarehouses(Warehouse);
	FilterStorageLocations_ = Catalogs.DocumentRegistryKeys.KeysByValue(FilterWarehouses);
	
	CommonClientServer.SetDynamicListFilterItem(
		ListPurchaseDocuments,
		"RefType",
		FilterDocumentTypes,
		DataCompositionComparisonType.InList,
		,
		True);
	
	CommonClientServer.SetDynamicListFilterItem(
		ListPurchaseDocuments,
		"BusinessOperation",
		FilterBusinessTransactions,
		DataCompositionComparisonType.InList,
		,
		True);
	
	CommonClientServer.SetDynamicListFilterItem(ListPurchaseDocuments,
																			"StorageLocation",
																			FilterStorageLocations_,
																			DataCompositionComparisonType.InList,
																			,
																			ValueIsFilled(FilterStorageLocations_));
	
	CommonClientServer.SetDynamicListFilterItem(
		ListPurchaseDocuments,
		"Manager",
		Manager,
		DataCompositionComparisonType.Equal,
		,
		ValueIsFilled(Manager));
		
	SetSelectionByOrganization();
	
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
		ListPurchaseDocuments,
		"Organization",
		CompaniesList,
		DataCompositionComparisonType.InList,
		,
		ValueIsFilled(Organization));
		
	UpdateHyperlinkToLayout();
	
	// DynamicListsSettings
	OperationsWithDocumentJournals.SetVisibilityOfDefaultUpdateSettingsGroup(ThisObject, "ListPurchaseDocuments");
	// End DynamicListsSettings
	
EndProcedure

&AtClientAtServerNoContext
Function DefaultFormAssignmentKey()
	
	Return "PurchaseDocumentsAll";
	
EndFunction

&AtServer
Function ThisIsSelectionOfDocumentsForAccrualOfVendorRebatesOfRetroBonuses()
	
	FormInSelectionMode = False;
	If PurposeUseKey = "PurchaseDocumentsAllSelection" Then
		FormInSelectionMode = True
	EndIf;
	
	Return FormInSelectionMode;
	
EndFunction

&AtServer
Procedure RestoreSettings(Var_Parameters)
	
	If ChoosingAcquisitionDocument Then
		Return;
	EndIf;
	
	ListOfDocumentsAutoUpdateMode = True;
	
	If Var_Parameters.Property("QuickFilterStructure") Then
		QuickFilterStructure = Var_Parameters.QuickFilterStructure;
		QuickFilterStructure.Property("Organization",Organization);
		QuickFilterStructure.Property("Warehouse",Warehouse);
		QuickFilterStructure.Property("Manager",Manager);
		QuickFilterStructure.Property("Period",Period);
	Else
		Settings = Common.CommonSettingsStorageLoad("DataProcessor.LogOfPurchaseDocuments.Form.ListForm", PurposeUseKey);
		
		If TypeOf(Settings) = Type("Structure") Then
			
			Warehouse                          = Settings.Warehouse;
			Manager                       = Settings.Manager;
			Period                         = Settings.Period;
			Organization                    = Settings.Organization;
		
			FilterDocumentTypes        = Settings.FilterDocumentTypes;
			FilterBusinessTransactions = Settings.FilterBusinessTransactions;
			
			If Settings.Property("ListOfDocumentsAutoUpdateMode") Then
				ListOfDocumentsAutoUpdateMode = Settings.ListOfDocumentsAutoUpdateMode;
			EndIf;
		
		EndIf;
	EndIf;
	
EndProcedure

&AtServer
Procedure ShouldSaveSettings()
	
	If ChoosingAcquisitionDocument Then
		Return;
	EndIf;
	
	AttributesToSaveNames =
		"Warehouse,
		|FilterBusinessTransactions,
		|FilterDocumentTypes,
		|Manager,
		|Period,
		|Organization,
		|ListOfDocumentsAutoUpdateMode";
	
	Settings = New Structure(AttributesToSaveNames);
	FillPropertyValues(Settings, ThisForm);
	
	Common.CommonSettingsStorageSave("DataProcessor.LogOfPurchaseDocuments.Form.ListForm", PurposeUseKey, Settings);
	
EndProcedure

&AtServer
Procedure WarehouseOnChangeServer()
	
	SetDynamicListSelections();
	UpdateHyperlinkToLayout();
	
EndProcedure

&AtServer
Function QueryTextListPurchaseDocuments()
	
	QueryText =
	"SELECT
	|	DocumentsRegistry.Ref AS Ref,
	|	DocumentsRegistry.IBDocumentNumber AS Number,
	|	DocumentsRegistry.IBDocumentDate AS Date,
	|	DocumentsRegistry.Status,
	|	DocumentsRegistry.Posted,
	|	DocumentsRegistry.DeletionMark,
	|	DocumentsRegistry.BusinessOperation,
	|	DocumentsRegistry.Partner,
	|	CAST(DocumentsRegistry.Counterparty.Key AS Catalog.Counterparties) AS Counterparty,
	|	DocumentsRegistry.Counterparty AS CounterpartyKey,
	|	DocumentsRegistry.Contract,
	|	&Terms AS Terms,
	|	DocumentsRegistry.Organization,
	|	DocumentsRegistry.Department,
	|	DocumentsRegistry.StorageLocation AS StorageLocation,
	|	CAST(DocumentsRegistry.StorageLocation.Key AS Catalog.Warehouses) AS Warehouse,
	|	DocumentsRegistry.Currency,
	|	DocumentsRegistry.Sum AS DocumentAmount,
	|	DocumentsRegistry.EmployeeResponsible AS Manager,
	|	DocumentsRegistry.Author AS Author,
	|	DocumentsRegistry.Comment,
	|	DocumentsRegistry.SourceDocumentNumber AS IncomingDocumentNumber,
	|	DocumentsRegistry.SourceDocumentDate AS IncomingDocumentDate,
	|	DocumentsRegistry.More,
	|	CASE
	|		WHEN DocumentsWithCounterpartyCheckErrors.Document IS NULL
	|			THEN FALSE
	|		ELSE TRUE
	|	END AS ThereAreErrorsInCheckingCounterparties,
	|	CASE
	|		WHEN DocumentsRegistry.Posted
	|			THEN 0
	|		WHEN DocumentsRegistry.DeletionMark
	|			THEN 1
	|		ELSE 2
	|	END AS CustomPicture,
	|	DocumentsRegistry.AdditionalRecord,
	|	DocumentsRegistry.RefType AS RefType,
	|	VALUETYPE(DocumentsRegistry.Ref) AS ValueType,
	|	&CheckStatus AS CheckStatus,
	|	&CheckingIndicator AS CheckingIndicator,
	|	DocumentsRegistry.ReverseTransactionCorrection AS ReverseTransactionCorrection,
	|	CASE
	|		WHEN NOT DocumentsRegistry.ReverseTransactionCorrection
	|			THEN UNDEFINED
	|		ELSE DocumentsRegistry.ReversedDocument
	|	END AS ReversedCorrectedDocument,
	|	DocumentsRegistry.RecordID AS RecordID,
	// StandardSubsystems.SourceDocumentsOriginalsRecording
	|	NULL AS SourceDocumentOriginalState,
	|	TRUE AS OverallState,
	|	0 AS StateOriginalReceived,
	|	CAST("""" AS STRING(50)) AS StateOfGISMT
	// End StandardSubsystems.SourceDocumentsOriginalsRecording
	|{WHERE
	|	DocumentsRegistry.Ref.* AS Ref,
	|	DocumentsRegistry.StorageLocation.* AS StorageLocation,
	|	CAST(DocumentsRegistry.StorageLocation.Key AS Catalog.Warehouses).* AS Warehouse,
	|	DocumentsRegistry.Organization.* AS Organization,
	|	DocumentsRegistry.IBDocumentDate AS Date,
	|	DocumentsRegistry.IBDocumentNumber AS Number,
	|	DocumentsRegistry.Status AS Status,
	|	DocumentsRegistry.RefType AS RefType,
	|	DocumentsRegistry.BusinessOperation AS BusinessOperation,
	|	DocumentsRegistry.Partner.* AS Partner,
	|	CAST(DocumentsRegistry.Counterparty.Key AS Catalog.Counterparties).* AS Counterparty,
	|	DocumentsRegistry.Contract.* AS Contract,
	|	&Terms AS Terms,
	|	DocumentsRegistry.Department.* AS Department,
	|	DocumentsRegistry.EmployeeResponsible.* AS Manager,
	|	DocumentsRegistry.Author.* AS Author,
	|	DocumentsRegistry.More AS More,
	|	DocumentsRegistry.Comment AS Comment,
	|	DocumentsRegistry.Posted AS Posted,
	|	DocumentsRegistry.DeletionMark AS DeletionMark,
	|	(DocumentsRegistry.IBDocumentDate >= &BeginOfPeriod
	|	AND DocumentsRegistry.IBDocumentDate <= &EndOfPeriod)}
	|FROM
	|	InformationRegister.DocumentsRegistry AS DocumentsRegistry
	|		{
	|		LEFT JOIN InformationRegister.DocumentsWithCounterpartyCheckErrors AS DocumentsWithCounterpartyCheckErrors
	|		ON DocumentsRegistry.Ref = DocumentsWithCounterpartyCheckErrors.Document
	|		AND (&UsingOfCheckIsAnOption)}";
	
	Return QueryText;
	
EndFunction

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
Procedure ConfigureFormForSelectedOperationsAndDocuments(VTBusinessTransactionsAndDocumentTypes)
	
	WorkplaceData = TMCommonUse.WorkplaceData(VTBusinessTransactionsAndDocumentTypes,
		DefaultFormAssignmentKey(), NStr("vi = 'Chứng từ mua hàng (tất cả)';
										|ru = 'Документы закупки (все)';
										|en = 'Purchase documents (all)'; fa = 'اسناد خرید (همه)';
										|it = 'Documenti d''acquisto (tutti)';
										|pl = 'Dokumenty zakupu (wszystkie)';
										|tr = 'Satın alma belgeleri (tümü)'"));
	
	Title   = WorkplaceData.WorkplaceTitle;
	
	CurrentKey = WorkplaceData.PurposeUseKey;
	
	// Document verificationreferences
	ListProperties = Common.DynamicListPropertiesStructure();
	FillPropertyValues(ListProperties, ListPurchaseDocuments);
	ListProperties.QueryText = QueryTextListPurchaseDocuments();
	If ChoosingAcquisitionDocument
	   And GetFunctionalOption("UseTermsOfPurchases") Then
		
		AddAgreementDataToList(ListProperties.QueryText);
		
	EndIf;
	DocumentVerificationServer.ModifyDynamicDocumentLogListRequest(ListProperties.QueryText, "DocumentsRegistry");
	Common.SetDynamicListProperties(Items.ListPurchaseDocuments, ListProperties);
	// End Document verificationreferences
		
	SetDynamicListSelections(CurrentKey);
	SetVisibilityAvailability(CurrentKey);
	
	TMCommonUse.ReplaceLinkFieldWithExpressByDocumentTypeConstruct(Items.ListPurchaseDocuments,
		BusinessTransactionsAndDocuments);
	
	TMCommonUse.FormInscriptionSelection(Items.HelpTextFilter.Title,
		BusinessTransactionsAndDocuments, FilterDocumentTypes, FilterBusinessTransactions);
	ConfigureDocumentManagementButtons();
	
EndProcedure

&AtServer
Procedure AddAgreementDataToList(QueryText)
	
	TextFragmentOfAgreement =
	"CASE
	|	WHEN DocumentsRegistry.Ref REFS Document.VendorInvoice
	|		THEN CAST(DocumentsRegistry.Ref AS Document.VendorInvoice).Terms
	|	WHEN DocumentsRegistry.Ref REFS Document.PurchaseAdjustment
	|		THEN CAST(DocumentsRegistry.Ref AS Document.PurchaseAdjustment).Terms
	|	WHEN DocumentsRegistry.Ref REFS Document.ReturnOfGoodsToVendor
	|		THEN CAST(DocumentsRegistry.Ref AS Document.ReturnOfGoodsToVendor).Terms
	|	WHEN DocumentsRegistry.Ref REFS Document.RedemptionOfGoodsFromStorage
	|		THEN CAST(DocumentsRegistry.Ref AS Document.RedemptionOfGoodsFromStorage).Terms
	|	ELSE VALUE(Catalog.TermsOfPurchaseFromVendors.EmptyRef)
	|END";
	
	TextToReplace = "&Terms";
	
	QueryText = StrReplace(QueryText, TextToReplace, TextFragmentOfAgreement);
	
EndProcedure

&AtClient
Procedure ListPurchaseDocumentsBeforeAddRow(Item, Cancel, Copy, Parent, Var_Group, Parameter)
	
	If Items.CreateGroupGenerated.ChildItems.Count() <> 0 Then 
		If Copy Then
			TMCommonUseClient.CopyItem(Item);
		ElsIf FilterDocumentTypes.Count() = 1 And FilterBusinessTransactions.Count() = 1 Then 
			SubordinateFormElements = Items.CreateGroupGenerated.ChildItems[0]; // FormGroup
			TeamStructure_ = New Structure("Name", SubordinateFormElements.Name);
			Attachable_CreateDocument(TeamStructure_);
		Else
			Attachable_CreateDocumentViaSelectionForm(Undefined);
		EndIf;
	EndIf;
	Cancel = True;
	
EndProcedure

&AtServer
Procedure SetSelectionByPeriod()
	
	ListPurchaseDocuments.Parameters.SetParameterValue("BeginOfPeriod",
		Period.StartDate);
	ListPurchaseDocuments.Parameters.SetParameterValue("EndOfPeriod", 
		?(ValueIsFilled(Period.EndDate), Period.EndDate, EndOfDay(Date(3999, 12, 31))));
		
	// DynamicListsSettings
	OperationsWithDocumentJournals.SetVisibilityOfDefaultUpdateSettingsGroup(ThisObject, "ListPurchaseDocuments");
	// End DynamicListsSettings
	
EndProcedure

&AtServer
Procedure WhenNotifyingAboutRecordingOfDocumentBeingProcessed()
	
	UpdateHyperlinkToLayout();
	
EndProcedure

&AtServer
Procedure EstablishCorrespondenceOfDocumentTypesAndForms(VTBusinessTransactionsAndDocumentTypes)
	
	If RunPerformanceMeasurements Then
		
		DataOnDocumentTypes = VTBusinessTransactionsAndDocumentTypes.Copy(,"DocumentType,FullDocumentName");
		DataOnDocumentTypes.GroupBy("DocumentType, FullDocumentName");
		MatchingDocumentTypes.Clear();
		
		For Each DocumentTypeString In DataOnDocumentTypes Do
			MatchingDocumentTypes.Add(DocumentTypeString.DocumentType, DocumentTypeString.FullDocumentName+ ".OpenDocumentForm");
		EndDo;
		
	EndIf;

EndProcedure


#EndRegion

#Region HyperlinkToDesign

&AtServer
Procedure UpdateHyperlinkToLayout()
	
	GenerationParameters = New Structure;
	GenerationParameters.Insert("Organization",          Organization);
	GenerationParameters.Insert("Warehouse",                Warehouse);
	GenerationParameters.Insert("ThisIsHyperlinkCalculation", True);
	GenerationParameters.Insert("PurposeUseKey", DefaultFormAssignmentKey());

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

	CalculationProcedure_ = "DataProcessors.LogOfPurchaseDocuments.CreateHyperlinkToBackgroundTaskLayout";

	ExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(UUID);
	ExecutionParameters.WaitCompletion = 0;
	ExecutionParameters.RunInBackground = True;
	CalculationResult2 = TimeConsumingOperations.ExecuteInBackground(CalculationProcedure_,
	                                                     JobParameters,
	                                                     ExecutionParameters);
	
	If CalculationResult2.Status = "Completed2" Then
		UpdateHyperlinkToLayoutCompletion(
			CalculationResult2.ResultAddress,
			ToRegister,
			Items.SeeAlsoInProgress.Visible,
			SeeAlsoInProgress);
			
		ResultOfFormationOfHyperlinksToDesign = Undefined;
	Else
		ResultOfFormationOfHyperlinksToDesign = CalculationResult2;
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
//
// Parameters:
// 	Storage address - String - address of data in temporary storage
// 	Co-formation - Formatted string - form details Co-formation
// 	Smtakzhevrabotevision - Boolean - visibility of the props SmTakzhEVrabot
// 	Smtakzhevrabotesvalue - String - the value of the SmTakzhEVrabot props
// 	Task ID is a unique identifier, Undefined is the ID of the background task
// 		
Procedure UpdateHyperlinkToLayoutCompletion(
	Val StorageAddress,
	ToRegister,
	SeeAlsoInVisibility, 
	SeeAlsoInWorkValue)

	Result = GetFromTempStorage(StorageAddress);

	If Not ValueIsFilled(Result.ToRegister) Then
		TextIsUpdatingData = NStr("vi = 'Cần lập: không';
									|ru = 'К оформлению: нет';
									|en = 'To register: no'; fa = 'To register: no';
									|it = 'Da formalizzare: no';
									|pl = 'Do rejestracji: brak';
									|tr = 'Düzenlenecek: yok'");
		ToRegister = New FormattedString(TextIsUpdatingData);
	Else
		ToRegister = Result.ToRegister;
	EndIf;

	If Not ValueIsFilled(Result.SeeAlsoInProgress) Then
		SeeAlsoInVisibility = False;
	Else
		SeeAlsoInVisibility = True;
		SeeAlsoInWorkValue = Result.SeeAlsoInProgress;
	EndIf;

EndProcedure

&AtClient
Procedure UpdateHyperlinkToNotificationDesign(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	If Result.Status = "Completed2" Then
		UpdateHyperlinkToLayoutCompletion(
			Result.ResultAddress,
			ToRegister,
			Items.SeeAlsoInProgress.Visible,
			SeeAlsoInProgress);
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

#EndRegion

&AtServer
Procedure TraceabilitySelection()
	
	If Parameters.Property("TraceabilityAdmissionToCommission") Then
		
		FilterBusinessTransactions.Clear();
		FilterBusinessTransactions.Add(Enums.BusinessTransactions.ReturnOfGoodsToConsignor);
		FilterBusinessTransactions.Add(Enums.BusinessTransactions.ConsignmentProcurement);
		
		FilterDocumentTypes.Clear();
		FilterDocumentTypes.Add(Catalogs.MetadataObjectIDs.FindByAttribute("Name", "DiscrepancyReportFollowingShipment"));
		FilterDocumentTypes.Add(Catalogs.MetadataObjectIDs.FindByAttribute("Name", "ReturnOfGoodsToVendor"));
		FilterDocumentTypes.Add(Catalogs.MetadataObjectIDs.FindByAttribute("Name", "DiscrepancyReportFollowingReceipt"));
		FilterDocumentTypes.Add(Catalogs.MetadataObjectIDs.FindByAttribute("Name", "VendorInvoice"));
		
	EndIf;
	
EndProcedure

&AtClient
Function GetKeyOperationForOpeningDocumentFormByClickingOnLink(Ref)
	
	NameOfDocumentForm = "";
	
	If Ref <> Undefined And ValueIsFilled(Ref) Then
		
		FoundDocumentTypeElement = MatchingDocumentTypes.FindByValue(TypeOf(Ref));
		
		If FoundDocumentTypeElement <> Undefined Then
			NameOfDocumentForm = FoundDocumentTypeElement.Presentation;
		EndIf;
		
	EndIf;
	
	Return NameOfDocumentForm;
	
EndFunction

#Region DynamicListsSettings

&AtServer
Procedure InitiateDynamicListSettings()
	
	DocumentListParameters = New Array;
	
	ListParameterStructure = OperationsWithDocumentJournals.StructureOfFormationOfGroupOfUserSettingsForDynamicListOnForm();
	ListParameterStructure.ListName = "ListPurchaseDocuments";
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
