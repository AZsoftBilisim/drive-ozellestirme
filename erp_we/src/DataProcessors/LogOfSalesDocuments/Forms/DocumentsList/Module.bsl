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
	
	URL = "e1cib/app/DataProcessor.LogOfSalesDocuments";
	
	RestoreSettings(Parameters);
	
	VTBusinessTransactionsAndDocumentTypes = TMCommonUse.AvailableBusinessTransactionsAndDocuments(DescriptionOfOperationsAndDocumentTypes(),
		FilterBusinessTransactions, FilterDocumentTypes, SettingsKey);
		
	FormCaption = Parameters.FormCaption;
	If Not ValueIsFilled(FormCaption) Then
		FormCaption = NStr("vi = 'Chứng từ bán hàng (tất cả)';
							|ru = 'Документы продажи (все)';
							|en = 'Sales documents (all)'; fa = 'اسناد فروش (همه)';
							|it = 'Documenti di vendita (tutti)';
							|pl = 'Dokumenty sprzedaży (wszystkie)';
							|tr = 'Satış belgeleri (tümü)'");
	EndIf;
	
	Title = FormCaption;
	
	UseNonConformanceCertificatesFollowingShipmentByCustody = GetFunctionalOption(
		"UseReportsOfDiscrepanciesAfterShipment");
	UseNonConformanceCertificatesFollowingReceiptsOfGoodsFromCustodian = GetFunctionalOption(
		"UseNonConformanceCertificatesFollowingAcceptance");
	
	If Not GetFunctionalOption("UseReportsOfDiscrepanciesAfterShipment") Then
		LinesToDelete = VTBusinessTransactionsAndDocumentTypes.FindRows(New Structure("FullDocumentName",Metadata.Documents.DiscrepancyReportFollowingShipment.FullName()));
		For Each RowToDelete In LinesToDelete Do
			If RowToDelete.BusinessOperation <> Enums.BusinessTransactions.TransferToStorageWithRightOfSale Then
				VTBusinessTransactionsAndDocumentTypes.Delete(RowToDelete);
			EndIf;
		EndDo;
	EndIf;
	
	If Not UseNonConformanceCertificatesFollowingShipmentByCustody Then
		LinesToDelete = VTBusinessTransactionsAndDocumentTypes.FindRows(New Structure("FullDocumentName, BusinessOperation",
																	Metadata.Documents.DiscrepancyReportFollowingShipment.FullName(),
																	Enums.BusinessTransactions.TransferToStorageWithRightOfSale));
		For Each RowToDelete In LinesToDelete Do
			VTBusinessTransactionsAndDocumentTypes.Delete(RowToDelete);
		EndDo;
	EndIf;
	
	If Not GetFunctionalOption("UseNonConformanceCertificatesFollowingAcceptance") Then
		LinesToDelete = VTBusinessTransactionsAndDocumentTypes.FindRows(New Structure("FullDocumentName",
																					Metadata.Documents.DiscrepancyReportFollowingReceipt.FullName()));
		For Each RowToDelete In LinesToDelete Do
			If RowToDelete.BusinessOperation <> Enums.BusinessTransactions.ReturnFromCustodian Then
				VTBusinessTransactionsAndDocumentTypes.Delete(RowToDelete);
			EndIf;
		EndDo;
	EndIf;
	
	If Not UseNonConformanceCertificatesFollowingReceiptsOfGoodsFromCustodian Then
		LinesToDelete = VTBusinessTransactionsAndDocumentTypes.FindRows(New Structure("FullDocumentName, BusinessOperation",
																	Metadata.Documents.DiscrepancyReportFollowingReceipt.FullName(),
																	Enums.BusinessTransactions.ReturnFromCustodian));
		For Each RowToDelete In LinesToDelete Do
			VTBusinessTransactionsAndDocumentTypes.Delete(RowToDelete);
		EndDo;
	EndIf;
	
	BusinessTransactionsAndDocuments.Load(VTBusinessTransactionsAndDocumentTypes);
	TMCommonUse.FillInSelectionsAccordingToTableOfBusinessTransactionsAndDocumentTypes(VTBusinessTransactionsAndDocumentTypes, FilterBusinessTransactions, FilterDocumentTypes);
	
	TraceabilitySelection();
	
	ConfigureFormForSelectedOperationsAndDocuments(VTBusinessTransactionsAndDocumentTypes);
	
	DocumentTypesUsed = VTBusinessTransactionsAndDocumentTypes.UnloadColumn("DocumentType");
	
		
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject, Items.GlobalCommandsGroup);
	// End IntegrationWith1CDocumentManagementSubsystem

	
	
	AdditionalParameters = New Structure("LocationOfLocalValidationData", Items.ReglGroupVerification);
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing, AdditionalParameters);
	
	// StandardSubsystems.AttachableCommands
	If ValueIsFilled(DocumentTypesUsed) Then
		DocumentTypesUsed.Add(Type("DocumentRef.ReversingEntry"));
		
		PlacementParameters = AttachableCommands.PlacementParameters();
		PlacementParameters.Sources = New TypeDescription(DocumentTypesUsed);
		PlacementParameters.CommandBar = Items.ListSalesDocumentsCommandBar;
		AttachableCommands.OnCreateAtServer(ThisObject, PlacementParameters);
	EndIf;
	// End StandardSubsystems.AttachableCommands
	
	If Items.StatusPresentation.Parent = Items.ListSalesDocuments Then
		Placement = Items.StatusPresentation;
	Else
		Placement = Items.StatusPresentation.Parent;
	EndIf;
		
	// StandardSubsystems.SourceDocumentsOriginalsRecording
	SourceDocumentsOriginalsRecording.OnCreateAtServerListForm(ThisObject,Items.ListSalesDocuments, Placement);
	// End StandardSubsystems.SourceDocumentsOriginalsRecording
	
	RunPerformanceMeasurements = PerformanceMonitorServerCallCached.RunPerformanceMeasurements();
	EstablishCorrespondenceOfDocumentTypesAndForms(VTBusinessTransactionsAndDocumentTypes);
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	EquipmentManagerClient.StartConnectingDevicesWhenYouOpenForm(Undefined, ThisForm, "BarcodeScanner");
	
	
	
	// DynamicListsSettings
	SetParametersForUpdatingDocumentLists(False, 0);
	// End DynamicListsSettings
	
	ConnectHyperlinkWaitingHandlerToLayout();
	
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
	
	
	If (EventName = "Write_CustomerInvoice"
		Or EventName = "Write_GoodsShipmentToCustomer"
		Or EventName = "Write_GoodsReceiptFromCustomer"
		Or EventName = "Write_CustomerInvoiceServicesAndAssets"
		Or EventName = "Write_RedemptionOfGoodsByCustodian"
		Or EventName = "Write_TransferOfGoodsToBailee"
		Or EventName = "Write_ReceiptOfGoodsFromCustodian"
		Or EventName = "Write_RecognitionOfStockSurplusShippedToCustomer"
		Or EventName = "Write_WriteOffOfShippedGoods"
		Or EventName = "Write_MisgradingOfGoodsAtCustodian"
		Or EventName = "Write_DamageAtCustodian"
		Or EventName = "Write_SaleAdjustment"
		Or EventName = "Write_InvoiceIssued"
		Or EventName = "Write_DiscrepancyReportFollowingShipment"
		Or EventName = "Record_ReportOfDiscrepanciesAfterReceipt"
		Or EventName = "Write_CustomerInvoiceServices"
		Or EventName = "Write_RequestForReturnOfGoodsFromCustomer"
		Or EventName = "Write_ReturnOfGoodsFromCustomer"
		Or EventName = "Write_DiscrepancyReportFollowingReceipt"
		Or EventName = "Write_ConsignmentReportFromCustomer"
		Or EventName = "Accept_FormOfCreatedDocuments"
		Or EventName = "Conducting_Storno"
		Or EventName = "Write_ReversingEntry") Then
		
			// DynamicListsSettings
			UpdateListOfDocumentsEventNotificationProcessing("ListSalesDocuments", Parameter);
			// End DynamicListsSettings
		
			UpdateHyperlinkToLayout();
			ConnectHyperlinkWaitingHandlerToLayout();
			
	EndIf;
	
	// StandardSubsystems.SourceDocumentsOriginalsRecording
	SourceDocumentsOriginalsRecordingClient.NotificationHandlerListForm(EventName, ThisObject, Items.ListSalesDocuments);
	// End StandardSubsystems.SourceDocumentsOriginalsRecording
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure ManagerOnChange(Item)
	
	CommonClientServer.SetDynamicListFilterItem(ListSalesDocuments,
		"Manager",
		Manager,
		DataCompositionComparisonType.Equal,,
		ValueIsFilled(Manager));
		
	// DynamicListsSettings
	OperationsWithDocumentJournalsClient.SetVisibilityOfDefaultUpdateSettingsGroup(ThisObject, "ListSalesDocuments");
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
	FormParameters.Insert("DisplayPageForLayout", True);
	
	If FormattedStringURL = "DataProcessor.LogOfSalesDocuments.Form.ToRegisterInvoices" Then
		// &PerformanceMeasurement
		PerformanceMonitorClient.StartTimeMeasurement(True,
			"DataProcessor.LogOfSalesDocuments.Command.InvoicesForRegistration");
	EndIf;
	
	PositionOfParameterSeparator = StrFind(FormattedStringURL, "%");
	
	If PositionOfParameterSeparator > 0 Then
		NavigationLinkParameter = 
			Mid(FormattedStringURL, PositionOfParameterSeparator + 1);
		FormattedStringURL = 
			Mid(FormattedStringURL, 1, PositionOfParameterSeparator - 1);
		
		FormParameters.Insert("FormAssignmentKey", NavigationLinkParameter);
		FormParameters.Insert("VariantKey", NavigationLinkParameter);
	EndIf;
	
	FormParameters.Insert("FormUniqueID", False);
	
	OpenForm(FormattedStringURL, FormParameters,, FormParameters.FormUniqueID);
	
EndProcedure

&AtClient
Procedure SeeAlsoInProgressURLProcessing(Item, FormattedStringURL, StandardProcessing)
	
	StandardProcessing = False;
	
	FormParameters = New Structure;
	QuickFilterStructure = New Structure;
	QuickFilterStructure.Insert("Organization",Organization);
	QuickFilterStructure.Insert("Warehouse",Warehouse);
	FormParameters.Insert("QuickFilterStructure", QuickFilterStructure);
	
	// Power of attorney issued
	If FormattedStringURL = "Document.IssuedLetterOfAuthority.Form.DocumentsListForm" Then
		FormParameters.Insert("AvailabilityOfCashOrders", True);
		FormParameters.Insert("AvailabilityOfOrdersGoods", False);
		FormParameters.Insert("FormCaption", NStr("vi = 'Giấy ủy quyền';
													|ru = 'Доверенности на получение денежных средств';
													|en = 'Authorization letters to receive cash'; fa = 'Authorization letters to receive cash';
													|it = 'Delega per incasso fondi monetari';
													|pl = 'Pełnomocnictwo na otrzymanie środków pieniężnych';
													|tr = 'Para tahsilatı için yetki belgesi'"));
	EndIf;
	
	FormParameters.Insert("OwnerOfFormBeingOpened",     ThisObject);
	FormParameters.Insert("FormUniqueID", UUID);
	
	
	// Redefining the form owner
	OwnerOfFormBeingOpened = FormParameters.OwnerOfFormBeingOpened;
	FormParameters.Delete("OwnerOfFormBeingOpened");
	
	OpenForm(FormattedStringURL, FormParameters, OwnerOfFormBeingOpened,
		FormParameters.FormUniqueID);
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersListRegistered

&AtClient
Procedure ListSalesDocumentsBeforeAddRow(Item, Cancel, Copy, Parent, Var_Group, Parameter)
	
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

&AtClient
Procedure ListSalesDocumentsOnActivateRow(Item)
	
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
	
	If Field.Name = "SourceDocumentOriginalState" Or Field.Name = "StateOriginalReceived" Then
		// StandardSubsystems.SourceDocumentsOriginalsRecording
		SourceDocumentsOriginalsRecordingClient.ListSelection(Field.Name,ThisObject,Items.ListSalesDocuments, StandardProcessing);
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
Procedure ListCopy(Command)
	
	TMCommonUseClient.CopyItem(Items.ListSalesDocuments);
	
EndProcedure

&AtClient
Procedure ListChange(Command)
	
	TMCommonUseClient.ChangeElement(Items.ListSalesDocuments);
	
EndProcedure

&AtClient
Procedure ListUndoPosting(Command)
	
	TMCommonUseClient.UndoPosting(Items.ListSalesDocuments, Title,
		OperationsWithDocumentJournalsClient.ParametersForUpdatingDocumentList(ThisObject, "ListSalesDocuments"));
	ListUndoPostingServer();
	ConnectHyperlinkWaitingHandlerToLayout();
	
EndProcedure

&AtClient
Procedure ListPost(Command)
	
	TMCommonUseClient.PostDocuments(Items.ListSalesDocuments, Title,
		OperationsWithDocumentJournalsClient.ParametersForUpdatingDocumentList(ThisObject, "ListSalesDocuments"));
	ListPostServer();
	ConnectHyperlinkWaitingHandlerToLayout();
	
EndProcedure

&AtClient
Procedure ListSetClearADeletionMark(Command)
	
	TMCommonUseClient.SetDeletionMark(Items.ListSalesDocuments, Title, Undefined,
		OperationsWithDocumentJournalsClient.ParametersForUpdatingDocumentList(ThisObject, "ListSalesDocuments"));
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
Procedure ListSalesDocumentsOnGetDataAtServer(TagName, Settings, Rows)
	
	// StandardSubsystems.SourceDocumentsOriginalsRecording
	SourceDocumentsOriginalsRecording.OnGetDataAtServer(Rows);
	// End StandardSubsystems.SourceDocumentsOriginalsRecording
	
	
EndProcedure

&AtServer
Procedure ListSalesDocumentsOnUpdateUserSettingSetAtServer(Item, StandardProcessing)
	
	// DynamicListsSettings
	OperationsWithDocumentJournals.SetVisibilityOfDefaultUpdateSettingsGroup(ThisObject, "ListSalesDocuments");
	// End DynamicListsSettings
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

// StandardSubsystems.AttachableCommands
&AtClient
Procedure Attachable_ExecuteCommand(Command)
	AttachableCommandsClient.ExecuteCommand(ThisObject, Command, Items.ListSalesDocuments);
EndProcedure

&AtServer
Procedure Attachable_ExecuteCommandAtServer(Context, Result) Export
	AttachableCommands.ExecuteCommand(ThisObject, Context, Items.ListSalesDocuments, Result);
EndProcedure

&AtClient
Procedure Attachable_UpdateCommands()
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Items.ListSalesDocuments);
EndProcedure
// End StandardSubsystems.AttachableCommands

// IntegrationWith1CDocumentManagementSubsystem
&AtClient
Procedure Attachable_ExecuteIntegrationCommand(Command)
	
	IntegrationWith1CDocumentManagementCoreClient.ExecutePlugInIntegrationCommand(Command, ThisObject, Items.ListSalesDocuments);
	
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
	
	TMCommonUseClient.SetStatus(Command.Name, CorrespondenceOfCommandsToStatuses, Items.ListSalesDocuments,
		OperationsWithDocumentJournalsClient.ParametersForUpdatingDocumentList(ThisObject,
		"ListSalesDocuments"));
	
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
	
	UseNonConformanceCertificatesFollowingShipmentByCustody = GetFunctionalOption(
		"UseReportsOfDiscrepanciesAfterShipment");
	UseNonConformanceCertificatesFollowingReceiptsOfGoodsFromCustodian = GetFunctionalOption(
		"UseNonConformanceCertificatesFollowingAcceptance");
	
	If Not GetFunctionalOption("UseReportsOfDiscrepanciesAfterShipment") Then
		LinesToDelete = VTBusinessTransactionsAndDocumentTypes.FindRows(New Structure("FullDocumentName",Metadata.Documents.DiscrepancyReportFollowingShipment.FullName()));
		For Each RowToDelete In LinesToDelete Do
			If RowToDelete.BusinessOperation <> Enums.BusinessTransactions.TransferToStorageWithRightOfSale Then
				VTBusinessTransactionsAndDocumentTypes.Delete(RowToDelete);
			EndIf;
		EndDo;
	EndIf;
	
	If Not UseNonConformanceCertificatesFollowingShipmentByCustody Then
		LinesToDelete = VTBusinessTransactionsAndDocumentTypes.FindRows(New Structure("FullDocumentName, BusinessOperation",
																	Metadata.Documents.DiscrepancyReportFollowingShipment.FullName(),
																	Enums.BusinessTransactions.TransferToStorageWithRightOfSale));
		For Each RowToDelete In LinesToDelete Do
			VTBusinessTransactionsAndDocumentTypes.Delete(RowToDelete);
		EndDo;
	EndIf;
	
	If Not GetFunctionalOption("UseNonConformanceCertificatesFollowingAcceptance") Then
		LinesToDelete = VTBusinessTransactionsAndDocumentTypes.FindRows(New Structure("FullDocumentName",
																					Metadata.Documents.DiscrepancyReportFollowingReceipt.FullName()));
		For Each RowToDelete In LinesToDelete Do
			If RowToDelete.BusinessOperation <> Enums.BusinessTransactions.ReturnFromCustodian Then
				VTBusinessTransactionsAndDocumentTypes.Delete(RowToDelete);
			EndIf;
		EndDo;
	EndIf;
	
	If Not UseNonConformanceCertificatesFollowingReceiptsOfGoodsFromCustodian Then
		LinesToDelete = VTBusinessTransactionsAndDocumentTypes.FindRows(New Structure("FullDocumentName, BusinessOperation",
																	Metadata.Documents.DiscrepancyReportFollowingReceipt.FullName(),
																	Enums.BusinessTransactions.ReturnFromCustodian));
		For Each RowToDelete In LinesToDelete Do
			VTBusinessTransactionsAndDocumentTypes.Delete(RowToDelete);
		EndDo;
	EndIf;
		
	DocumentTypesUsed = VTBusinessTransactionsAndDocumentTypes.UnloadColumn("DocumentType");

	// StandardSubsystems.AttachableCommands
	If ValueIsFilled(DocumentTypesUsed) Then
		DocumentTypesUsed.Add(Type("DocumentRef.ReversingEntry"));
		
		PlacementParameters = AttachableCommands.PlacementParameters();
		PlacementParameters.Sources = New TypeDescription(DocumentTypesUsed);
		PlacementParameters.CommandBar = Items.ListSalesDocumentsCommandBar;
		AttachableCommands.OnCreateAtServer(ThisObject, PlacementParameters);
	EndIf;
	// End StandardSubsystems.AttachableCommands
	
	EstablishCorrespondenceOfDocumentTypesAndForms(VTBusinessTransactionsAndDocumentTypes);
	
EndProcedure
//End StandardSubsystems.SourceDocumentsOriginalsRecording

&AtClient
Procedure ListOfSalesDocumentsToUpdate(Command)
	
	// DynamicListsSettings
	UpdateDocumentListDataWithTimeMeasurement("ListSalesDocuments");
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
	
	If Not BarcodingOfItemsClient.BarcodesAreValid(Data) Then
		Return;
	EndIf;
	
	Status(NStr("vi = 'Đang tìm kiếm chứng từ theo mã vạch...';
				|ru = 'Выполняется поиск документа по штрихкоду...';
				|en = 'Searching for the document by barcode...'; fa = 'Searching for the document by barcode...';
				|it = 'Viene effettuata la ricerca del documento per codice a barre...';
				|pl = 'Wyszukiwanie dokumentu według kodu kreskowego...';
				|tr = 'Belge barkoda göre aranıyor...'"));
	BarcodeData = BarcodeDataOfPrintedForm(Data.Barcode, "ListSalesDocuments");
	TMCommonUseClient.ProcessBarcodes(Data.Barcode, BarcodeData, ThisForm, "ListSalesDocuments");
	
EndProcedure

#EndRegion

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
	
	StandardSubsystemsServer.SetDateFieldConditionalAppearance(ThisObject, "ListSalesDocuments.Date", "ListSalesDocumentsDate");
	
EndProcedure

&AtClientAtServerNoContext
Function DefaultFormAssignmentKey()
	
	Return "SalesDocumentsAll";
	
EndFunction

&AtServer
Procedure RestoreSettings(Var_Parameters)
	
	ListOfSalesDocumentsAutoUpdateMode = True;
	
	If Var_Parameters.Property("QuickFilterStructure") Then
		QuickFilterStructure = Var_Parameters.QuickFilterStructure;
		QuickFilterStructure.Property("Organization",Organization);
		QuickFilterStructure.Property("Warehouse",Warehouse);
		QuickFilterStructure.Property("Manager",Manager);
		QuickFilterStructure.Property("Period",Period);

		UseSettingsUpload    = Var_Parameters.UseDownloadOfSavedSettings;
		FillInQuickSelectionFromSettings = False;
	Else
		UseSettingsUpload    = True;
		FillInQuickSelectionFromSettings = True;
	EndIf;

	If UseSettingsUpload Then
		Settings = Common.CommonSettingsStorageLoad("DataProcessor.LogOfSalesDocuments.Form.ListForm", PurposeUseKey);
		
		If TypeOf(Settings) = Type("Structure") Then
			
			If FillInQuickSelectionFromSettings Then
				Warehouse                          = Settings.Warehouse;
				Manager                       = Settings.Manager;
				Period                         = Settings.Period;
				Organization                    = Settings.Organization;
			EndIf;
		
			FilterDocumentTypes        = Settings.FilterDocumentTypes;
			FilterBusinessTransactions = Settings.FilterBusinessTransactions;
			If Settings.Property("ListOfSalesDocumentsAutoUpdateMode") Then
				ListOfSalesDocumentsAutoUpdateMode = Settings.ListOfSalesDocumentsAutoUpdateMode;
			EndIf;
			
		EndIf;
	EndIf;
	
EndProcedure

&AtServer
Procedure ShouldSaveSettings()
	
	AttributesToSaveNames =
		"Warehouse,
		|FilterBusinessTransactions,
		|FilterDocumentTypes,
		|Manager,
		|Period,
		|Organization,
		|ListOfSalesDocumentsAutoUpdateMode";
	
	Settings = New Structure(AttributesToSaveNames);
	FillPropertyValues(Settings, ThisForm);

	Common.CommonSettingsStorageSave("DataProcessor.LogOfSalesDocuments.Form.ListForm", PurposeUseKey, Settings);
	
EndProcedure

&AtServer
Procedure WarehouseOnChangeServer()
	
	SetDynamicListSelections();
	UpdateHyperlinkToDesignOnServer();
		
EndProcedure

&AtServer
Function QueryTextListSalesDocuments()
	
	QueryText = 
	"SELECT
	|	DocumentsRegistry.Ref AS Ref,
	|	DocumentsRegistry.IBDocumentNumber AS Number,
	|	DocumentsRegistry.IBDocumentDate AS Date,
	|	DocumentsRegistry.Status AS Status,
	|	DocumentsRegistry.Posted AS Posted,
	|	DocumentsRegistry.DeletionMark AS DeletionMark,
	|	DocumentsRegistry.BusinessOperation AS BusinessOperation,
	|	DocumentsRegistry.Partner AS Partner,
	|	CAST(DocumentsRegistry.Counterparty.Key AS Catalog.Counterparties) AS Counterparty,
	|	DocumentsRegistry.Counterparty AS CounterpartyKey,
	|	DocumentsRegistry.Contract AS Contract,
	|	DocumentsRegistry.Organization AS Organization,
	|	DocumentsRegistry.Department AS Department,
	|	DocumentsRegistry.StorageLocation AS StorageLocation,
	|	CAST(DocumentsRegistry.StorageLocation.Key AS Catalog.Warehouses) AS Warehouse,
	|	DocumentsRegistry.Currency AS Currency,
	|	DocumentsRegistry.Sum AS DocumentAmount,
	|	DocumentsRegistry.EmployeeResponsible AS Manager,
	|	DocumentsRegistry.Author AS Author,
	|	DocumentsRegistry.Comment AS Comment,
	|	DocumentsRegistry.SourceDocumentNumber AS IncomingDocumentNumber,
	|	DocumentsRegistry.SourceDocumentDate AS IncomingDocumentDate,
	|	DocumentsRegistry.More AS More,
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
	|	DocumentsRegistry.AdditionalRecord AS AdditionalRecord,
	|	DocumentsRegistry.RefType AS RefType,
	|	&CheckStatus AS CheckStatus,
	|	&CheckingIndicator AS CheckingIndicator,
	|	VALUETYPE(DocumentsRegistry.Ref) AS ValueType,
	// StandardSubsystems.SourceDocumentsOriginalsRecording
	|	NULL AS SourceDocumentOriginalState,
	|	TRUE AS OverallState,
	|	0 AS StateOriginalReceived,
	// End StandardSubsystems.SourceDocumentsOriginalsRecording
	|	DocumentsRegistry.ReverseTransactionCorrection AS ReverseTransactionCorrection,
	|	DocumentsRegistry.RecordID AS RecordID,
	|	CASE 
	|		WHEN NOT DocumentsRegistry.ReverseTransactionCorrection
	|			THEN UNDEFINED
	|		ELSE DocumentsRegistry.ReversedDocument
	|	END AS ReversedCorrectedDocument,
	|	CAST("""" AS STRING(50)) AS StateOfGISMT
	|FROM
	|	InformationRegister.DocumentsRegistry AS DocumentsRegistry
	|		{
	|		LEFT JOIN InformationRegister.DocumentsWithCounterpartyCheckErrors AS DocumentsWithCounterpartyCheckErrors
	|		ON DocumentsRegistry.Ref = DocumentsWithCounterpartyCheckErrors.Document
	|			AND (&UsingOfCheckIsAnOption)}
	|{WHERE
	|	DocumentsRegistry.Ref.* AS Ref,
	|	DocumentsRegistry.StorageLocation.* AS StorageLocation,
	|	(CAST(DocumentsRegistry.StorageLocation.Key AS Catalog.Warehouses)).* AS Warehouse,
	|	DocumentsRegistry.Organization.* AS Organization,
	|	DocumentsRegistry.IBDocumentDate AS Date,
	|	DocumentsRegistry.IBDocumentNumber AS Number,
	|	DocumentsRegistry.Status AS Status,
	|	DocumentsRegistry.RefType AS RefType,
	|	DocumentsRegistry.BusinessOperation AS BusinessOperation,
	|	DocumentsRegistry.Partner.* AS Partner,
	|	(CAST(DocumentsRegistry.Counterparty.Key AS Catalog.Counterparties)).* AS Counterparty,
	|	DocumentsRegistry.Contract.* AS Contract,
	|	DocumentsRegistry.Department.* AS Department,
	|	DocumentsRegistry.EmployeeResponsible.* AS Manager,
	|	DocumentsRegistry.Author.* AS Author,
	|	DocumentsRegistry.More AS More,
	|	DocumentsRegistry.Comment AS Comment,
	|	DocumentsRegistry.Posted AS Posted,
	|	DocumentsRegistry.DeletionMark AS DeletionMark,
	|	((DocumentsRegistry.IBDocumentDate >= &BeginOfPeriod
	|			OR &BeginOfPeriod = DATETIME(1, 1, 1))
	|			AND (DocumentsRegistry.IBDocumentDate <= &EndOfPeriod
	|				OR &EndOfPeriod = DATETIME(1, 1, 1)))}";
	
	Return QueryText;
	
EndFunction

&AtServer
Function DescriptionOfOperationsAndDocumentTypes()
	
	VTBusinessTransactionsAndDocumentTypes = BusinessTransactionsAndDocuments.Unload();
	VTBusinessTransactionsAndDocumentTypes.Clear();
	UseShipmentWithDeferredTransferOfTitle2_0 =
		GetFunctionalOption("UseShipmentWithDeferredTransferOfTitle2_0");
	
	// CustomerInvoice
	
	LineSalesOfGoodsAndServices = VTBusinessTransactionsAndDocumentTypes.Add();
	String = LineSalesOfGoodsAndServices;
	String.PurposeUseKey 	= "Invoices";
	String.BusinessOperation 		= Enums.BusinessTransactions.SaleToCustomer;
	String.AddButtonCreate		= True;
	String.DocumentType 				= Type("DocumentRef.CustomerInvoice");
	String.FullDocumentName			= "Document.CustomerInvoice";
	String.WorkplaceTitle = NStr("vi = 'Chứng từ bán hàng (hóa đơn)';
								|ru = 'Документы продажи (накладные)';
								|en = 'Sales documents (invoices)'; fa = 'Sales documents (invoices)';
								|it = 'Documenti di vendita (bolle)';
								|pl = 'Dokumenty sprzedaży (faktury)';
								|tr = 'Satış belgeleri (irsaliyeler)'");
	String.HyperlinkCalculationManagerForRegistration = "DataProcessor.LogOfSalesDocuments";
	String.StatusesAreUsed          = True;
	
	String = VTBusinessTransactionsAndDocumentTypes.Add();
	FillPropertyValues(String,LineSalesOfGoodsAndServices);
	String.BusinessOperation 		= Enums.BusinessTransactions.SaleToCustomerLocalAccounting;
	
	If Not GetFormFunctionalOption("OnlyConsignmentSales25")
		And GetFormFunctionalOption("ToUseTermsOfSales") Then
	
		String = VTBusinessTransactionsAndDocumentTypes.Add();
		FillPropertyValues(String,LineSalesOfGoodsAndServices);
		String.BusinessOperation 	= Enums.BusinessTransactions.TransferToCommissionAgent;
	
	EndIf;
	
	If GetFunctionalOption("UseSalesCommission") Then
		String = VTBusinessTransactionsAndDocumentTypes.Add();
		FillPropertyValues(String,LineSalesOfGoodsAndServices);
		String.BusinessOperation 	= Enums.BusinessTransactions.SalesViaCommissionAgent;
		
		If UseShipmentWithDeferredTransferOfTitle2_0 Then
			String = VTBusinessTransactionsAndDocumentTypes.Add();
			FillPropertyValues(String,LineSalesOfGoodsAndServices);
			String.BusinessOperation = Enums.BusinessTransactions.SalesViaCommissionAgentGoodsInTransit;
		EndIf;
	EndIf;
	
	String = VTBusinessTransactionsAndDocumentTypes.Add();
	FillPropertyValues(String,LineSalesOfGoodsAndServices);
	String.BusinessOperation 		= Enums.BusinessTransactions.SaleWithDeferredTransferOfTitle;
	
	String = VTBusinessTransactionsAndDocumentTypes.Add();
	FillPropertyValues(String,LineSalesOfGoodsAndServices);
	String.BusinessOperation = Enums.BusinessTransactions.TransferOfTitleToGoods;
		
	// CustomerInvoiceServices
	
	String = VTBusinessTransactionsAndDocumentTypes.Add();
	String.PurposeUseKey 	= "Invoices";
	String.BusinessOperation 		= Enums.BusinessTransactions.SaleToCustomer;
	String.AddButtonCreate		= True;
	String.DocumentType 				= Type("DocumentRef.CustomerInvoiceServices");
	String.FullDocumentName			= "Document.CustomerInvoiceServices";
	String.WorkplaceTitle = NStr("vi = 'Chứng từ bán hàng (hóa đơn)';
								|ru = 'Документы продажи (накладные)';
								|en = 'Sales documents (invoices)'; fa = 'Sales documents (invoices)';
								|it = 'Documenti di vendita (bolle)';
								|pl = 'Dokumenty sprzedaży (faktury)';
								|tr = 'Satış belgeleri (irsaliyeler)'");
	String.HyperlinkCalculationManagerForRegistration = "DataProcessor.LogOfSalesDocuments";
	
	// DiscrepancyReportFollowingShipment
	
	LineReportOfDiscrepanciesAfterShipment = VTBusinessTransactionsAndDocumentTypes.Add();
	String = LineReportOfDiscrepanciesAfterShipment;
	String.BusinessOperation 		= Enums.BusinessTransactions.SaleToCustomer;
	String.AddButtonCreate		= True;
	String.DocumentType 				= Type("DocumentRef.DiscrepancyReportFollowingShipment");
	String.FullDocumentName			= "Document.DiscrepancyReportFollowingShipment";
	String.DocumentPresentation		= NStr("vi = 'Biên bản chênh lệch sau khi gửi hàng';
												|ru = 'Акт о расхождениях после отгрузки';
												|en = 'Sales dispute'; fa = 'اختلاف فروش';
												|it = 'Documento di accettazione con riserva dopo la spedizione';
												|pl = 'Protokół o odchyleniu po wysyłce';
												|tr = 'Sevkiyat sonrası tutarsızlık raporu'");
	String.StatusesAreUsed			= True;
	String.PurposeUseKey	= "ReportsOfDiscrepanciesAfterShipment";
	String.WorkplaceTitle = NStr("vi = 'Chứng từ bán hàng (chênh lệch)';
								|ru = 'Документы продажи (расхождения)';
								|en = 'Sales documents (discrepancy)'; fa = 'Sales documents (discrepancy)';
								|it = 'Documenti di vendita (divergenze)';
								|pl = 'Dokumenty sprzedaży (odchylenie)';
								|tr = 'Satış belgeleri (siparişler)'");
	
	String = VTBusinessTransactionsAndDocumentTypes.Add();
	FillPropertyValues(String,LineReportOfDiscrepanciesAfterShipment);
	String.BusinessOperation 		= Enums.BusinessTransactions.TransferToCommissionAgent;
	
	String = VTBusinessTransactionsAndDocumentTypes.Add();
	FillPropertyValues(String,LineReportOfDiscrepanciesAfterShipment);
	String.BusinessOperation 		= Enums.BusinessTransactions.SaleToCustomerLocalAccounting;
	
	String = VTBusinessTransactionsAndDocumentTypes.Add();
	FillPropertyValues(String,LineReportOfDiscrepanciesAfterShipment);
	String.BusinessOperation 		= Enums.BusinessTransactions.SaleWithDeferredTransferOfTitle;
	
	String = VTBusinessTransactionsAndDocumentTypes.Add();
	FillPropertyValues(String,LineReportOfDiscrepanciesAfterShipment);
	String.BusinessOperation 		= Enums.BusinessTransactions.TransferToStorageWithRightOfSale;
	
	String = VTBusinessTransactionsAndDocumentTypes.Add();
	FillPropertyValues(String,LineReportOfDiscrepanciesAfterShipment);
	String.BusinessOperation 		= Enums.BusinessTransactions.DeliveryForPrincipal;
	
	String = VTBusinessTransactionsAndDocumentTypes.Add();
	FillPropertyValues(String,LineReportOfDiscrepanciesAfterShipment);
	String.BusinessOperation = Enums.BusinessTransactions.GoodsShipmentToCustomer;
	
	String = VTBusinessTransactionsAndDocumentTypes.Add();
	FillPropertyValues(String,LineReportOfDiscrepanciesAfterShipment);
	String.BusinessOperation = Enums.BusinessTransactions.TransferOfTitleToGoods;
	
	// Actorreferencesexternal links
	
	LineReportOfDiscrepanciesAfterReceipt = VTBusinessTransactionsAndDocumentTypes.Add();
	String = LineReportOfDiscrepanciesAfterReceipt;
	String.BusinessOperation 		= Enums.BusinessTransactions.ReturnOfGoodsFromCustomer;
	String.AddButtonCreate		= True;
	String.DocumentType 				= Type("DocumentRef.DiscrepancyReportFollowingReceipt");
	String.FullDocumentName			= "Document.DiscrepancyReportFollowingReceipt";
	String.DocumentPresentation		= NStr("vi = 'Biên bản chênh lệch sau khi nhập hàng';
												|ru = 'Акт о расхождениях после приемки';
												|en = 'Receipt discrepancy report'; fa = 'گزارش مغایرت دریافت';
												|it = 'Atto di discrepanze dopo l''accettazione';
												|pl = 'Protokół o odchyleniu po przyjęciu';
												|tr = 'Giriş tutarsızlık raporu'");
	String.StatusesAreUsed			= True;
	String.PurposeUseKey	= "DiscrepancyReportFollowingReceipt";
	String.WorkplaceTitle = NStr("vi = 'Chứng từ bán hàng (chênh lệch)';
								|ru = 'Документы продажи (расхождения)';
								|en = 'Sales documents (discrepancy)'; fa = 'Sales documents (discrepancy)';
								|it = 'Documenti di vendita (divergenze)';
								|pl = 'Dokumenty sprzedaży (odchylenie)';
								|tr = 'Satış belgeleri (siparişler)'");
	
	String = VTBusinessTransactionsAndDocumentTypes.Add();
	FillPropertyValues(String, LineReportOfDiscrepanciesAfterReceipt);
	String.BusinessOperation		= Enums.BusinessTransactions.ReturnFromCommissionAgent;
	
	String = VTBusinessTransactionsAndDocumentTypes.Add();
	FillPropertyValues(String, LineReportOfDiscrepanciesAfterReceipt);
	String.BusinessOperation		= Enums.BusinessTransactions.ReturnFromCustodian;
	
	// SaleAdjustment
	
	LineImplementationAdjustment = VTBusinessTransactionsAndDocumentTypes.Add();
	String = LineImplementationAdjustment;
	String.PurposeUseKey 	= "CreditNotes";
	String.BusinessOperation 		= Enums.BusinessTransactions.ErrorCorrection;
	String.AddButtonCreate		= True;
	String.DocumentType 				= Type("DocumentRef.SaleAdjustment");
	String.FullDocumentName			= "Document.SaleAdjustment";
	String.WorkplaceTitle = NStr("vi = 'Chứng từ bán hàng (điều chỉnh)';
								|ru = 'Документы продажи (корректировки)';
								|en = 'Sales documents (adjusting entries)'; fa = 'Sales documents (adjusting entries)';
								|it = 'Documenti di vendita (rettifiche)';
								|pl = 'Dokumenty sprzedaży (zapisy korygujące)';
								|tr = 'Satış belgeleri (düzeltmeler)'");
	
	String = VTBusinessTransactionsAndDocumentTypes.Add();
	FillPropertyValues(String,LineImplementationAdjustment);
	String.BusinessOperation 		= Enums.BusinessTransactions.AdjustmentUnderApprovalOfParties;
	
	String = VTBusinessTransactionsAndDocumentTypes.Add();
	FillPropertyValues(String,LineImplementationAdjustment);
	String.BusinessOperation 		= Enums.BusinessTransactions.SaleOfOverdeliveredGoods;
	
	String = VTBusinessTransactionsAndDocumentTypes.Add();
	FillPropertyValues(String,LineImplementationAdjustment);
	String.BusinessOperation 		= Enums.BusinessTransactions.ReturnOfUnderdeliveredGoods;
	
	String = VTBusinessTransactionsAndDocumentTypes.Add();
	FillPropertyValues(String,LineImplementationAdjustment);
	String.BusinessOperation 		= Enums.BusinessTransactions.SaleToCustomer;
	String.AddButtonCreate		= False;
	
	String = VTBusinessTransactionsAndDocumentTypes.Add();
	FillPropertyValues(String,LineImplementationAdjustment);
	String.BusinessOperation 		= Enums.BusinessTransactions.SaleToCustomerLocalAccounting;
	String.AddButtonCreate		= False;
	
	String = VTBusinessTransactionsAndDocumentTypes.Add();
	FillPropertyValues(String,LineImplementationAdjustment);
	String.BusinessOperation 		= Enums.BusinessTransactions.TransferToCommissionAgent;
	String.AddButtonCreate		= False;
	
	String = VTBusinessTransactionsAndDocumentTypes.Add();
	FillPropertyValues(String,LineImplementationAdjustment);
	String.BusinessOperation 		= Enums.BusinessTransactions.SaleWithDeferredTransferOfTitle;
	String.AddButtonCreate		= False;
	
	If GetFunctionalOption("UseSalesCommission") Then
		String = VTBusinessTransactionsAndDocumentTypes.Add();
		FillPropertyValues(String,LineImplementationAdjustment);
		String.BusinessOperation 	= Enums.BusinessTransactions.SalesViaCommissionAgent;
		String.AddButtonCreate	= False;
		
		If UseShipmentWithDeferredTransferOfTitle2_0 Then
			String = VTBusinessTransactionsAndDocumentTypes.Add();
			FillPropertyValues(String,LineImplementationAdjustment);
			String.BusinessOperation = Enums.BusinessTransactions.SalesViaCommissionAgentGoodsInTransit;
			String.AddButtonCreate = False;
		EndIf;
	EndIf;
	
	String = VTBusinessTransactionsAndDocumentTypes.Add();
	FillPropertyValues(String,LineImplementationAdjustment);
	String.BusinessOperation 		= Enums.BusinessTransactions.AdjustmentOfSalesIncreaseInDebtConsolidated;
	
	String = VTBusinessTransactionsAndDocumentTypes.Add();
	FillPropertyValues(String,LineImplementationAdjustment);
	String.BusinessOperation 		= Enums.BusinessTransactions.AdjustmentOfImplementationDebtReductionConsolidated;
	
	If GetFunctionalOption("NewOnlineARAPAccounting") Then
		String = VTBusinessTransactionsAndDocumentTypes.Add();
		FillPropertyValues(String,LineImplementationAdjustment);
		String.BusinessOperation 		= Enums.BusinessTransactions.AdjustBeforeEnteringBalance;
	EndIf;
	
	String = VTBusinessTransactionsAndDocumentTypes.Add();
	FillPropertyValues(String,LineImplementationAdjustment);
	String.BusinessOperation = Enums.BusinessTransactions.TransferOfTitleToGoods;
	
	// CustomerInvoiceServicesAndAssets
	
	LineImplementationOfServices = VTBusinessTransactionsAndDocumentTypes.Add();
	String = LineImplementationOfServices;
	String.PurposeUseKey 	= "CustomerInvoicesServicesAndAssets";
	String.StatusesAreUsed			= True;
	String.BusinessOperation 		= Enums.BusinessTransactions.SaleToCustomer;
	String.AddButtonCreate		= True;
	String.DocumentType 				= Type("DocumentRef.CustomerInvoiceServicesAndAssets");
	String.FullDocumentName			= "Document.CustomerInvoiceServicesAndAssets";
	String.WorkplaceTitle = NStr("vi = 'Chứng từ bán hàng (hóa đơn)';
								|ru = 'Документы продажи (накладные)';
								|en = 'Sales documents (invoices)'; fa = 'Sales documents (invoices)';
								|it = 'Documenti di vendita (bolle)';
								|pl = 'Dokumenty sprzedaży (faktury)';
								|tr = 'Satış belgeleri (irsaliyeler)'");
	
	String = VTBusinessTransactionsAndDocumentTypes.Add();
	FillPropertyValues(String,LineImplementationOfServices);
	String.BusinessOperation 		= Enums.BusinessTransactions.SaleWithDeferredTransferOfTitle;
	
	// PurchasingReportToConsignorPrincipal
	
	LineReportToPurchasingCommittee = VTBusinessTransactionsAndDocumentTypes.Add();
	String = LineReportToPurchasingCommittee;
	String.PurposeUseKey	= "DeliveryForPrincipal";
	String.BusinessOperation		= Enums.BusinessTransactions.DeliveryForPrincipal;
	String.AddButtonCreate		= True;
	String.DocumentType					= Type("DocumentRef.PurchasingReportToConsignorPrincipal");
	String.FullDocumentName			= "Document.PurchasingReportToConsignorPrincipal";
	String.WorkplaceTitle		= NStr("vi = 'Chứng từ bán hàng (báo cáo cho ủy ban mua hàng)';
										|ru = 'Документы продажи (отчеты комитентам о закупке)';
										|en = 'Sale documents (purchase notifications)'; fa = 'Sale documents (purchase notifications)';
										|it = 'Documenti di vendita (report sugli acquisti ai committenti)';
										|pl = 'Dokumenty sprzedaży (raporty do komitentów o zakupie)';
										|tr = 'Satış belgeleri (satın alımlara ilişkin konsinye raporları)'");
	String.HyperlinkCalculationManagerForRegistration = "Document.PurchasingReportToConsignorPrincipal";
	
	LineShipmentToPrincipal = VTBusinessTransactionsAndDocumentTypes.Add();
	String = LineShipmentToPrincipal;
	String.PurposeUseKey	= "DeliveryForPrincipal";
	String.BusinessOperation		= Enums.BusinessTransactions.DeliveryForPrincipal;
	String.AddButtonCreate		= True;
	String.DocumentType					= Type("DocumentRef.GoodsShipmentFromStorage");
	String.FullDocumentName			= "Document.GoodsShipmentFromStorage";
	String.WorkplaceTitle		= NStr("vi = 'Chứng từ gửi hàng (Giao hàng cho người đặt ký gửi)';
										|ru = 'Документы отгрузки (отгрузки комитентам о закупках)';
										|en = 'Shipping documents (purchase notifications)'; fa = 'Shipping documents (purchase notifications)';
										|it = 'Documenti di spedizione (spedizioni sugli acquisti ai committenti)';
										|pl = 'Dokumenty wysyłki (wysyłki do komitentów o zakupach)';
										|tr = 'Satış belgeleri (satın alımlara ilişkin konsinye sevkiyatı)'");
	If GetFunctionalOption("UseNonCurrentAssets2_4") Then
		String = VTBusinessTransactionsAndDocumentTypes.Add();
		FillPropertyValues(String,LineImplementationOfServices);
		String.BusinessOperation = Enums.BusinessTransactions.NonCurrentAssetsSale;

		If UseShipmentWithDeferredTransferOfTitle2_0 Then
			String = VTBusinessTransactionsAndDocumentTypes.Add();
			FillPropertyValues(String,LineImplementationOfServices);
			String.BusinessOperation = Enums.BusinessTransactions.FixedAssetsSaleWithDeferredTitleTransfer;
		EndIf;
		
		String = VTBusinessTransactionsAndDocumentTypes.Add();
		FillPropertyValues(String,LineImplementationOfServices);
		String.BusinessOperation = Enums.BusinessTransactions.RenderRentalServices;
	EndIf;
	#Region GoodsAtKeeper
	
	// RedemptionOfGoodsByCustodian
	
	OperationAndTypeString = VTBusinessTransactionsAndDocumentTypes.Add();
	String = OperationAndTypeString;
	String.PurposeUseKey	= "RedemptionsOfGoodsByTheCustodian";
	String.BusinessOperation		= Enums.BusinessTransactions.RedemptionOfGoodsByCustodian;
	String.AddButtonCreate		= True;
	String.DocumentType					= Type("DocumentRef.RedemptionOfGoodsByCustodian");
	String.FullDocumentName			= "Document.RedemptionOfGoodsByCustodian";
	String.WorkplaceTitle		= NStr("vi = 'Chứng từ bán hàng (mua lại bởi người giữ)';
										|ru = 'Документы продажи (выкупы хранителем)';
										|en = 'Sales documents (redemptions by the custodian)'; fa = 'Sales documents (redemptions by the custodian)';
										|it = 'Documenti delle vendite (acquisti da parte del depositario)';
										|pl = 'Dokumenty sprzedaży (umorzenia przez powiernika)';
										|tr = 'Satış belgeleri (emanetçi tarafından alınması)'");
	
	// TransferOfGoodsToBailee
	
	OperationAndTypeString = VTBusinessTransactionsAndDocumentTypes.Add();
	String = OperationAndTypeString;
	String.PurposeUseKey	= "TransferOfGoodsToBailee";
	String.BusinessOperation		= Enums.BusinessTransactions.TransferToStorageWithRightOfSale;
	String.AddButtonCreate		= True;
	String.DocumentType					= Type("DocumentRef.TransferOfGoodsToBailee");
	String.FullDocumentName			= "Document.TransferOfGoodsToBailee";
	String.WorkplaceTitle		= NStr("vi = 'Chứng từ bán hàng (chuyển vào kho)';
										|ru = 'Документы продажи (передачи на хранение)';
										|en = 'Sales documents (VMI fill-up)'; fa = 'Sales documents (VMI fill-up)';
										|it = 'Documenti delle vendite (trasferimento al deposito)';
										|pl = 'Dokumenty sprzedaży (przeniesienie do magazynu)';
										|tr = 'Satış belgeleri (depoya transfer)'");
	String.HyperlinkCalculationManagerForRegistration = "DataProcessor.LogOfSalesDocuments";
	
	OperationAndTypeString = VTBusinessTransactionsAndDocumentTypes.Add();
	String = OperationAndTypeString;
	String.PurposeUseKey	= "TransferOfGoodsToBailee";
	String.BusinessOperation		= Enums.BusinessTransactions.TransferToCommissionAgent;
	String.AddButtonCreate		= True;
	String.DocumentType					= Type("DocumentRef.TransferOfGoodsToBailee");
	String.FullDocumentName			= "Document.TransferOfGoodsToBailee";
	String.WorkplaceTitle		= NStr("vi = 'Chứng từ bán hàng (chuyển đi ký gửi)';
										|ru = 'Документы продажи (передачи на комиссию)';
										|en = 'Sales documents (consignment sales)'; fa = 'Sales documents (consignment sales)';
										|it = 'Documenti di vendita (trasferimento in commissione)';
										|pl = 'Dokumenty sprzedaży (wydania do komisu)';
										|tr = 'Satış belgeleri (konsinyeye transfer)'");
	String.HyperlinkCalculationManagerForRegistration = "DataProcessor.LogOfSalesDocuments";
	
	// ReceiptOfGoodsFromCustodian
	
	OperationAndTypeString = VTBusinessTransactionsAndDocumentTypes.Add();
	String = OperationAndTypeString;
	String.PurposeUseKey	= "ReceiptOfGoodsFromCustodian";
	String.BusinessOperation		= Enums.BusinessTransactions.ReturnFromCustodian;
	String.AddButtonCreate		= True;
	String.DocumentType					= Type("DocumentRef.ReceiptOfGoodsFromCustodian");
	String.FullDocumentName			= "Document.ReceiptOfGoodsFromCustodian";
	String.WorkplaceTitle		= NStr("vi = 'Chứng từ bán hàng (biên lai từ người giám sát)';
										|ru = 'Документы продажи (поступления от хранителя)';
										|en = 'Sales documents (receipts from the custodian)'; fa = 'Sales documents (receipts from the custodian)';
										|it = 'Documenti delle vendite (ricevimento dal depositario)';
										|pl = 'Dokumenty sprzedaży (pokwitowania od powiernika)';
										|tr = 'Satış belgeleri (emanetçiden teslim alma)'");
	String.HyperlinkCalculationManagerForRegistration = "DataProcessor.LogOfSalesDocuments";
	
	OperationAndTypeString = VTBusinessTransactionsAndDocumentTypes.Add();
	String = OperationAndTypeString;
	String.PurposeUseKey	= "ReceiptOfGoodsFromCustodian";
	String.BusinessOperation		= Enums.BusinessTransactions.ReturnFromCommissionAgent;
	String.AddButtonCreate		= True;
	String.DocumentType					= Type("DocumentRef.ReceiptOfGoodsFromCustodian");
	String.FullDocumentName			= "Document.ReceiptOfGoodsFromCustodian";
	String.WorkplaceTitle		= NStr("vi = 'Chứng từ bán hàng (trả lại hàng từ người nhận ký gửi)';
										|ru = 'Документы продажи (возврат от комиссионера)';
										|en = 'Sales documents (consignment pick-up)'; fa = 'Sales documents (consignment pick-up)';
										|it = 'Documenti di vendita (reso dal commissionario)';
										|pl = 'Dokumenty sprzedaży (zwrot od komisanta)';
										|tr = 'Satış belgeleri (konsinye teslim alma)'");
	String.HyperlinkCalculationManagerForRegistration = "DataProcessor.LogOfSalesDocuments";
	
	// WriteOffOfShippedGoods
	
	LineReportOnGoodsWriteOff = VTBusinessTransactionsAndDocumentTypes.Add();
	String = LineReportOnGoodsWriteOff;
	String.PurposeUseKey	= "WriteOffOfShippedGoods";
	String.BusinessOperation		= Enums.BusinessTransactions.WriteOffShortagesAtDepositorSExpense;
	String.AddButtonCreate		= True;
	String.DocumentType					= Type("DocumentRef.WriteOffOfShippedGoods");
	String.FullDocumentName			= "Document.WriteOffOfShippedGoods";
	String.WorkplaceTitle		= NStr("vi = 'Chứng từ bán hàng (ghi giảm từ người giám sát)';
										|ru = 'Документы продажи (списания у хранителя)';
										|en = 'Sales documents (write-off on the custodian)'; fa = 'Sales documents (write-off on the custodian)';
										|it = 'Documenti delle vendite (cancellazione dal depositario)';
										|pl = 'Dokumenty sprzedaży (spisane przez powiernika)';
										|tr = 'Satış belgeleri (emanetçiden gider yazma)'");
	
	String = VTBusinessTransactionsAndDocumentTypes.Add();
	FillPropertyValues(String,LineReportOnGoodsWriteOff);
	String.BusinessOperation = Enums.BusinessTransactions.WriteOffOfShippedGoods;
	
	OperationAndTypeString = VTBusinessTransactionsAndDocumentTypes.Add();
	String = OperationAndTypeString;
	String.PurposeUseKey	= "WriteOffOfShippedGoods";
	String.BusinessOperation		= Enums.BusinessTransactions.WriteOffShortagesAtConsignorSExpense;
	String.AddButtonCreate		= True;
	String.DocumentType					= Type("DocumentRef.WriteOffOfShippedGoods");
	String.FullDocumentName			= "Document.WriteOffOfShippedGoods";
	String.WorkplaceTitle		= NStr("vi = 'Chứng từ bán hàng (ghi giảm hàng hóa từ người nhận ký gửi)';
										|ru = 'Документы продажи (списания у комиссионера)';
										|en = 'Sales documents (write-off at consignee)'; fa = 'Sales documents (write-off at consignee)';
										|it = 'Documenti di vendita (storno presso commissionario)';
										|pl = 'Dokumenty sprzedaży (rozchodu u komisanta)';
										|tr = 'Satış belgeleri (konsinyeden gider yazma)'");
	
	// MisgradingOfGoodsAtCustodian
	
	OperationAndTypeString = VTBusinessTransactionsAndDocumentTypes.Add();
	String = OperationAndTypeString;
	String.PurposeUseKey	= "MisgradingOfGoodsAtCustodian";
	String.BusinessOperation		= Enums.BusinessTransactions.MisgradingOfGoodsAtCustodian;
	String.AddButtonCreate		= True;
	String.DocumentType					= Type("DocumentRef.MisgradingOfGoodsAtCustodian");
	String.FullDocumentName			= "Document.MisgradingOfGoodsAtCustodian";
	String.WorkplaceTitle		= NStr("vi = 'Chứng từ bán hàng (chuyển tồn tại nơi cất giữ)';
										|ru = 'Документы продажи (пересортица у хранителя)';
										|en = 'Sales documents (stock reclass at custodian)'; fa = 'Sales documents (stock reclass at custodian)';
										|it = 'Documenti di vendita (riclassificazione presso i magazzini)';
										|pl = 'Dokumenty sprzedaży (przeklasyfikowanie u opiekuna)';
										|tr = 'Satış belgeleri (emanetçide yeniden sınıflandırma)'");
	
	// DamageAtCustodian
	
	OperationAndTypeString = VTBusinessTransactionsAndDocumentTypes.Add();
	String = OperationAndTypeString;
	String.PurposeUseKey	= "DamageAtCustodian";
	String.BusinessOperation		= Enums.BusinessTransactions.DamageAtCustodian;
	String.AddButtonCreate		= True;
	String.DocumentType					= Type("DocumentRef.DamageAtCustodian");
	String.FullDocumentName			= "Document.DamageAtCustodian";
	String.WorkplaceTitle		= NStr("vi = 'Chứng từ bán hàng (hàng hỏng ở nơi cất giữ)';
										|ru = 'Документы продажи (порча у хранителя)';
										|en = 'Sales documents (damage at custodian)'; fa = 'Sales documents (damage at custodian)';
										|it = 'Documenti di vendita (usura presso i magazzini)';
										|pl = 'Dokumenty sprzedaży (uszkodzenie u opiekuna)';
										|tr = 'Satış belgeleri (emanetçide kalite değişikliği)'");
	
	// RecognitionOfStockSurplusShippedToCustomer
	
	LineIsRegistrationOfSurpluses = VTBusinessTransactionsAndDocumentTypes.Add();
	String = LineIsRegistrationOfSurpluses;
	String.PurposeUseKey	= "RecognitionOfStockSurplusShippedToCustomer";
	String.BusinessOperation		= Enums.BusinessTransactions.RecognizeInventorySurplusForTheBenefitOfDepositor;
	String.AddButtonCreate		= True;
	String.DocumentType					= Type("DocumentRef.RecognitionOfStockSurplusShippedToCustomer");
	String.FullDocumentName			= "Document.RecognitionOfStockSurplusShippedToCustomer";
	String.WorkplaceTitle		= NStr("vi = 'Chứng từ bán hàng (ghi tăng hàng thừa của người cất giữ)';
										|ru = 'Документы продажи (оприходование излишков у хранителя)';
										|en = 'Sales documents (surplus recognition at custodian)'; fa = 'Sales documents (surplus recognition at custodian)';
										|it = 'Documenti di vendita (accettazione eccedenze presso il magazzino)';
										|pl = 'Dokumenty sprzedaży (rejestracja nadwyżek u depozytariusza)';
										|tr = 'Satış belgeleri (emanetçide envanter fazlalıkları)'");
	
	String = VTBusinessTransactionsAndDocumentTypes.Add();
	FillPropertyValues(String,LineIsRegistrationOfSurpluses);
	String.BusinessOperation = Enums.BusinessTransactions.RecognitionOfStockSurplusShippedToCustomer;
	
	OperationAndTypeString = VTBusinessTransactionsAndDocumentTypes.Add();
	String = OperationAndTypeString;
	String.PurposeUseKey	= "RecognitionOfStockSurplusShippedToCustomer";
	String.BusinessOperation		= Enums.BusinessTransactions.RecognizeInventorySurplusForTheBenefitOfConsignor;
	String.AddButtonCreate		= True;
	String.DocumentType					= Type("DocumentRef.RecognitionOfStockSurplusShippedToCustomer");
	String.FullDocumentName			= "Document.RecognitionOfStockSurplusShippedToCustomer";
	String.WorkplaceTitle		= NStr("vi = 'Chứng từ bán hàng (ghi tăng hàng thừa của người nhận ký gửi)';
										|ru = 'Документы продажи (оприходование излишков у комиссионера)';
										|en = 'Sales documents (surplus recognition at consignee)'; fa = 'Sales documents (surplus recognition at consignee)';
										|it = 'Documenti di vendita (accettazione eccedenze presso il commissionario)';
										|pl = 'Dokumenty sprzedaży (rejestracja nadwyżek u komisanta)';
										|tr = 'Satış belgeleri (konsinye envanter fazlalıkları)'");
	
	#EndRegion
	
	// ReturnOfGoodsFromCustomer
	
	OperationAndTypeString = VTBusinessTransactionsAndDocumentTypes.Add();
	String = OperationAndTypeString;
	String.PurposeUseKey = "ReturnOfGoodsFromCustomer";
	String.BusinessOperation = Enums.BusinessTransactions.ReturnOfGoodsFromCustomer;
	String.AddButtonCreate = True;
	String.DocumentType = Type("DocumentRef.ReturnOfGoodsFromCustomer");
	String.FullDocumentName = "Document.ReturnOfGoodsFromCustomer";
	String.WorkplaceTitle = NStr("vi = 'Chứng từ bán hàng (hóa đơn)';
								|ru = 'Документы продажи (накладные)';
								|en = 'Sales documents (invoices)'; fa = 'Sales documents (invoices)';
								|it = 'Documenti di vendita (bolle)';
								|pl = 'Dokumenty sprzedaży (faktury)';
								|tr = 'Satış belgeleri (irsaliyeler)'");
	String.HyperlinkCalculationManagerForRegistration = "DataProcessor.LogOfSalesDocuments";
	String.StatusesAreUsed = False;
	
	// ReturnFromCommissionAgent
	
	OperationAndTypeString = VTBusinessTransactionsAndDocumentTypes.Add();
	String = OperationAndTypeString;
	String.PurposeUseKey = "ReturnFromCommissionAgent";
	String.BusinessOperation = Enums.BusinessTransactions.ReturnFromCommissionAgent;
	String.AddButtonCreate = True;
	String.DocumentType = Type("DocumentRef.ReturnOfGoodsFromCustomer");
	String.FullDocumentName = "Document.ReturnOfGoodsFromCustomer";
	String.WorkplaceTitle = NStr("vi = 'Chứng từ bán hàng (hóa đơn)';
								|ru = 'Документы продажи (накладные)';
								|en = 'Sales documents (invoices)'; fa = 'Sales documents (invoices)';
								|it = 'Documenti di vendita (bolle)';
								|pl = 'Dokumenty sprzedaży (faktury)';
								|tr = 'Satış belgeleri (irsaliyeler)'");
	String.HyperlinkCalculationManagerForRegistration = "DataProcessor.LogOfSalesDocuments";
	String.StatusesAreUsed = False;
	
	// ReturnFromRetailCustomer
	
	OperationAndTypeString = VTBusinessTransactionsAndDocumentTypes.Add();
	String = OperationAndTypeString;
	String.PurposeUseKey = "ReturnFromRetailCustomer";
	String.BusinessOperation = Enums.BusinessTransactions.ReturnFromRetailCustomer;
	String.AddButtonCreate = True;
	String.DocumentType = Type("DocumentRef.ReturnOfGoodsFromCustomer");
	String.FullDocumentName = "Document.ReturnOfGoodsFromCustomer";
	String.WorkplaceTitle = NStr("vi = 'Chứng từ bán hàng (hóa đơn)';
								|ru = 'Документы продажи (накладные)';
								|en = 'Sales documents (invoices)'; fa = 'Sales documents (invoices)';
								|it = 'Documenti di vendita (bolle)';
								|pl = 'Dokumenty sprzedaży (faktury)';
								|tr = 'Satış belgeleri (irsaliyeler)'");
	String.HyperlinkCalculationManagerForRegistration = "DataProcessor.LogOfSalesDocuments";
	String.StatusesAreUsed = False;
	
	// ReturnOfGoodsViaCommissionAgent
	
	OperationAndTypeString = VTBusinessTransactionsAndDocumentTypes.Add();
	String = OperationAndTypeString;
	String.PurposeUseKey = "ReturnOfGoodsViaCommissionAgent";
	String.BusinessOperation = Enums.BusinessTransactions.ReturnOfGoodsViaCommissionAgent;
	String.AddButtonCreate = True;
	String.DocumentType = Type("DocumentRef.ReturnOfGoodsFromCustomer");
	String.FullDocumentName = "Document.ReturnOfGoodsFromCustomer";
	String.WorkplaceTitle = NStr("vi = 'Chứng từ bán hàng (hóa đơn)';
								|ru = 'Документы продажи (накладные)';
								|en = 'Sales documents (invoices)'; fa = 'Sales documents (invoices)';
								|it = 'Documenti di vendita (bolle)';
								|pl = 'Dokumenty sprzedaży (faktury)';
								|tr = 'Satış belgeleri (irsaliyeler)'");
	String.HyperlinkCalculationManagerForRegistration = "DataProcessor.LogOfSalesDocuments";
	String.StatusesAreUsed = False;
	
	// ConsignmentReportFromCustomer
	
	OperationAndTypeString = VTBusinessTransactionsAndDocumentTypes.Add();
	String = OperationAndTypeString;
	String.PurposeUseKey 	= "Invoices";
	String.BusinessOperation 		= Enums.BusinessTransactions.SalesViaCommissionAgent;
	String.AddButtonCreate		= True;
	String.DocumentType 				= Type("DocumentRef.ConsignmentReportFromCustomer");
	String.FullDocumentName			= "Document.ConsignmentReportFromCustomer";
	String.WorkplaceTitle = NStr("vi = 'Bảng kê hàng bán của người nhận ký gửi';
								|ru = 'Отчет комиссионера';
								|en = 'Consignment issue notification'; fa = 'اعلان صدور امانی';
								|it = 'Report del commissionario';
								|pl = 'Raport komisanta';
								|tr = 'Konsinye raporu'");
	String.HyperlinkCalculationManagerForRegistration = "DataProcessor.ConsignmentReportsFromCustomers";
	String.StatusesAreUsed          = False;
	
	// RetailSalesReport
	
	OperationAndTypeString = VTBusinessTransactionsAndDocumentTypes.Add();
	String = OperationAndTypeString;
	String.PurposeUseKey = "RetailSalesReport";
	String.BusinessOperation = Enums.BusinessTransactions.RetailSaleOfGoods;
	String.AddButtonCreate = True;
	String.DocumentType = Type("DocumentRef.RetailSalesReport");
	String.FullDocumentName = "Document.RetailSalesReport";
	String.WorkplaceTitle = NStr("vi = 'Chứng từ bán hàng (khách lẻ)';
								|ru = 'Документы продажи (розничный покупатель)';
								|en = 'Sales documents (retail customer)'; fa = 'Sales documents (retail customer)';
								|it = 'Documenti di vendita (acquirente al dettaglio)';
								|pl = 'Dokumenty sprzedaży (nabywca detaliczny)';
								|tr = 'Satış belgeleri (perakende müşteriler)'");
	String.HyperlinkCalculationManagerForRegistration = "DataProcessor.LogOfSalesDocuments";
	String.StatusesAreUsed = False;
	
	// RetailReturnsReport
	
	OperationAndTypeString = VTBusinessTransactionsAndDocumentTypes.Add();
	String = OperationAndTypeString;
	String.PurposeUseKey = "RetailReturnsReport";
	String.BusinessOperation = Enums.BusinessTransactions.ReturnFromRetailCustomer;
	String.AddButtonCreate = True;
	String.DocumentType = Type("DocumentRef.RetailReturnsReport");
	String.FullDocumentName = "Document.RetailReturnsReport";
	String.WorkplaceTitle = NStr("vi = 'Chứng từ bán hàng (khách lẻ)';
								|ru = 'Документы продажи (розничный покупатель)';
								|en = 'Sales documents (retail customer)'; fa = 'Sales documents (retail customer)';
								|it = 'Documenti di vendita (acquirente al dettaglio)';
								|pl = 'Dokumenty sprzedaży (nabywca detaliczny)';
								|tr = 'Satış belgeleri (perakende müşteriler)'");
	String.HyperlinkCalculationManagerForRegistration = "DataProcessor.LogOfSalesDocuments";
	String.StatusesAreUsed = False;
	
	//GoodsShipmentToCustomer
	OperationAndTypeString = VTBusinessTransactionsAndDocumentTypes.Add();
	String = OperationAndTypeString;
	String.PurposeUseKey 	= "GoodsShipmentToCustomer";
	String.BusinessOperation 		= Enums.BusinessTransactions.GoodsShipmentToCustomer;
	String.AddButtonCreate		= True;
	String.DocumentType 				= Type("DocumentRef.GoodsShipmentToCustomer");
	String.FullDocumentName			= "Document.GoodsShipmentToCustomer";
	String.WorkplaceTitle 		= NStr("vi = 'Chứng từ bán hàng (giao hàng cho khách)';
										|ru = 'Документы продажи (отгрузка товаров клиенту)';
										|en = 'Sales documents (goods shipment to customer)'; fa = 'Sales documents (goods shipment to customer)';
										|it = 'Sales documents (goods shipment to customer)';
										|pl = 'Sales documents (goods shipment to customer)';
										|tr = 'Satış belgeleri (müşteriye ürün sevkiyatı)'");
	String.HyperlinkCalculationManagerForRegistration = "DataProcessor.LogOfSalesDocuments";
	String.StatusesAreUsed          = False;
	
	//GoodsReceiptFromCustomer
	OperationAndTypeString = VTBusinessTransactionsAndDocumentTypes.Add();
	String = OperationAndTypeString;
	String.PurposeUseKey 	= "GoodsReceiptFromCustomer";
	String.BusinessOperation 		= Enums.BusinessTransactions.GoodsReceiptFromCustomer;
	String.AddButtonCreate		= True;
	String.DocumentType 				= Type("DocumentRef.GoodsReceiptFromCustomer");
	String.FullDocumentName			= "Document.GoodsReceiptFromCustomer";
	String.WorkplaceTitle 		= NStr("vi = 'Chứng từ bán hàng (hóa đơn)';
										|ru = 'Документы продажи (накладные)';
										|en = 'Sales documents (invoices)'; fa = 'Sales documents (invoices)';
										|it = 'Documenti di vendita (bolle)';
										|pl = 'Dokumenty sprzedaży (faktury)';
										|tr = 'Satış belgeleri (irsaliyeler)'");
	String.HyperlinkCalculationManagerForRegistration = "DataProcessor.LogOfSalesDocuments";
	String.StatusesAreUsed          = False;
	
	VATAccountingERP.DescriptionOfOperationsAndDocumentTypesForSalesDocumentLog(VTBusinessTransactionsAndDocumentTypes);
	DescriptionOfOperationsAndDocumentTypesByFormOpeningParameter(VTBusinessTransactionsAndDocumentTypes);
	
	Return VTBusinessTransactionsAndDocumentTypes;
	
EndFunction

&AtServer
Procedure ConfigureFormForSelectedOperationsAndDocuments(VTBusinessTransactionsAndDocumentTypes)
	
	WorkplaceData = TMCommonUse.WorkplaceData(VTBusinessTransactionsAndDocumentTypes,
		DefaultFormAssignmentKey(), FormCaption);
	
	Title   = WorkplaceData.WorkplaceTitle;
	
	CurrentKey = WorkplaceData.PurposeUseKey;
	
	// Document verificationreferences
	ListProperties = Common.DynamicListPropertiesStructure();
	FillPropertyValues(ListProperties, ListSalesDocuments);
	ListProperties.QueryText = QueryTextListSalesDocuments();
	DocumentVerificationServer.ModifyDynamicDocumentLogListRequest(ListProperties.QueryText, "DocumentsRegistry");
	Common.SetDynamicListProperties(Items.ListSalesDocuments, ListProperties);
	// End Document verificationreferences
		
	SetDynamicListSelections(CurrentKey);
	SetVisibilityAvailability(CurrentKey);
	
	TMCommonUse.ReplaceLinkFieldWithExpressByDocumentTypeConstruct(Items.ListSalesDocuments,
		BusinessTransactionsAndDocuments);
	
	TMCommonUse.FormInscriptionSelection(Items.HelpTextFilter.Title,
		BusinessTransactionsAndDocuments, FilterDocumentTypes, FilterBusinessTransactions);
	ConfigureDocumentManagementButtons();
	
EndProcedure

&AtServer
Procedure SetVisibilityAvailability(CurrentKey)
	
	If Not GetFunctionalOption("UseMultipleCompanies") Then
		Items.Organization.Visible = False;
	EndIf;
	
	If Not GetFunctionalOption("UseSeveralWarehouses") Then
		Items.ListSalesDocumentsWarehouse.Visible = False;
		Items.Warehouse.Visible                       = False;
	EndIf;
	
	If Not GetFunctionalOption("UseMultipleCurrencies") Then
		Items.ListSalesDocumentsCurrency.Visible = False;
	EndIf;
	
	Items.ListSalesDocumentsContract.Visible = GetFunctionalOption("UseCustomerContracts");
	Items.ListSalesDocumentsCounterparty.Visible = GetFunctionalOption("UsePartnersAndCounterparties");
	
	// Re-filling the list of statuses
	TMCommonUse.SetListOfStatuses(ThisForm, Items.SetStatus);
	
	Items.GroupListDownloadFromScan.Visible = GetFunctionalOption("NotBaseVersion");
		
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
	EstablishCorrespondenceOfDocumentTypesAndForms(VTBusinessTransactionsAndDocumentTypes);
	ConfigureFormForSelectedOperationsAndDocuments(VTBusinessTransactionsAndDocumentTypes);
	
EndProcedure

#Region Filters

&AtServer
Procedure SetDynamicListSelections(CurrentKey = Undefined)
	
	FilterWarehouses = WarehousesServer.ListOfSubordinateWarehouses(Warehouse);
	FilterStorageLocations_ = Catalogs.DocumentRegistryKeys.KeysByValue(FilterWarehouses);
	
	CommonClientServer.SetDynamicListFilterItem(
		ListSalesDocuments,
		"RefType",
		FilterDocumentTypes,
		DataCompositionComparisonType.InList,
		,
		True);
	
	CommonClientServer.SetDynamicListFilterItem(
		ListSalesDocuments,
		"BusinessOperation",
		FilterBusinessTransactions,
		DataCompositionComparisonType.InList,
		,
		True);
	
	CommonClientServer.SetDynamicListFilterItem(ListSalesDocuments,
																			"StorageLocation",
																			FilterStorageLocations_,
																			DataCompositionComparisonType.InList,
																			,
																			ValueIsFilled(FilterStorageLocations_));
	
	CommonClientServer.SetDynamicListFilterItem(
		ListSalesDocuments,
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
		ListSalesDocuments,
		"Organization",
		CompaniesList,
		DataCompositionComparisonType.InList,
		,
		ValueIsFilled(Organization));
		
	UpdateHyperlinkToDesignOnServer();
	
	// DynamicListsSettings
	OperationsWithDocumentJournals.SetVisibilityOfDefaultUpdateSettingsGroup(ThisObject, "ListSalesDocuments");
	// End DynamicListsSettings
	
EndProcedure

&AtServer
Procedure SetSelectionByPeriod()
	
	ListSalesDocuments.Parameters.SetParameterValue("BeginOfPeriod",
		Period.StartDate);
	ListSalesDocuments.Parameters.SetParameterValue("EndOfPeriod", 
		?(ValueIsFilled(Period.EndDate), Period.EndDate, EndOfDay(Date(3999, 12, 31))));
	
	// DynamicListsSettings
	OperationsWithDocumentJournals.SetVisibilityOfDefaultUpdateSettingsGroup(ThisObject, "ListSalesDocuments");
	// End DynamicListsSettings
	
EndProcedure

#EndRegion 

#Region HyperlinkToDesign

&AtServer
Function UpdateHyperlinkToDesignOnServer()
	
	UpdateHyperlinkToLayout();

EndFunction

&AtServer
Procedure UpdateHyperlinkToLayout()
	
	GenerationParameters = New Structure;
	GenerationParameters.Insert("Warehouse", ThisForm.Warehouse);
	GenerationParameters.Insert("Organization", ThisForm.Organization);
	GenerationParameters.Insert("AuthorizationLetterType", PredefinedValue("Enum.TypesOfIssuedLettersOfAuthority.ToReceiveCash"));
	GenerationParameters.Insert("ReSubmissionToCommittees", True);
	
	Items.ToRegister.Visible = True;
	TextIsUpdatingData = NStr("vi = '<đang cập nhật dữ liệu>';
								|ru = '<идет обновление данных>';
								|en = '<data is being updated>'; fa = '<data is being updated>';
								|it = '<aggiornamento dati in corso>';
								|pl = '<trwa aktualizacja danych>';
								|tr = '<veriler güncelleniyor>'");
	Items.ToRegister.Title = New FormattedString(TextIsUpdatingData);
	
	Items.SeeAlsoInProgress.Visible = True;
	TextIsUpdatingData = NStr("vi = 'Xem thêm: <đang cập nhật dữ liệu>';
								|ru = 'См. также: <идет обновление данных>';
								|en = 'See also: <data is being updated>'; fa = 'See also: <data is being updated>';
								|it = 'Vedi anche: <aggiornamento dati in corso>';
								|pl = 'Patrz również: <odbywa się aktualizacja danych>';
								|tr = 'Ayrıca bakınız: <veri güncellemesi devam ediyor>'");
	SeeAlsoInProgress = New FormattedString(TextIsUpdatingData);
	
	JobParameters = New Array;
	JobParameters.Add(BusinessTransactionsAndDocuments.Unload());
	JobParameters.Add(GenerationParameters);
	
	CalculationProcedure_ = "DataProcessors.LogOfSalesDocuments.CreateHyperlinkToBackgroundTaskLayout";
	
	ExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(UUID);
	ExecutionParameters.WaitCompletion = 0;
	ExecutionParameters.RunInBackground = True;
	
	CalculationResult2 = TimeConsumingOperations.ExecuteInBackground(CalculationProcedure_,
	                                                     JobParameters,
	                                                     ExecutionParameters);
	
	If CalculationResult2.Status = "Completed2" Then
		UpdateHyperlinkToLayoutCompletion(
			CalculationResult2.ResultAddress,
			Items.ToRegister.Title,
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
// 	Storage address - String - address of the data in the temporary storage
// 	To the form - Formatted string - Attributes of the Form to the form
// 	Smtakzhevodevision - Boolean - visibility of the Attribute SmTakzhEVision
// 	smtakzhevrabotesvalue - String - value of the Attribute SmTakzhEVrabot
// 		
Procedure UpdateHyperlinkToLayoutCompletion(
	Val StorageAddress,
	ToRegister,
	SeeAlsoInVisibility, 
	SeeAlsoInWorkValue)

	Result = GetFromTempStorage(StorageAddress);

	If Not ValueIsFilled(Result.ToRegister) Then
		TextIsUpdatingData = NStr("vi = 'không';
									|ru = 'нет';
									|en = 'no'; fa = 'no';
									|it = 'no';
									|pl = 'no';
									|tr = 'hayır'");
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
			Items.ToRegister.Title,
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

#Region DynamicListsSettings

&AtServer
Procedure InitiateDynamicListSettings()
	
	DocumentListParameters = New Array;
	
	ListParameterStructure = OperationsWithDocumentJournals.StructureOfFormationOfGroupOfUserSettingsForDynamicListOnForm();
	ListParameterStructure.ListName = "ListSalesDocuments";
	ListParameterStructure.PlacementGroupSettings = Items.DocumentListSettingsGroup;
	ListParameterStructure.AttributeNameAutoUpdateMode = "ListOfSalesDocumentsAutoUpdateMode";
	ListParameterStructure.NameOfListUpdateCommands = Commands.ListOfSalesDocumentsToUpdate.Name;
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
Procedure TraceabilitySelection()
	
	If Parameters.Property("TraceabilityReturnsOfGoodsFromCommissionAgents") Then
		
		FilterBusinessTransactions.Clear();
		FilterBusinessTransactions.Add(Parameters.TraceabilityReturnsOfGoodsFromCommissionAgents);
		
		FilterDocumentTypes.Clear();
		FilterDocumentTypes.Add(Catalogs.MetadataObjectIDs.FindByAttribute("Name", "DiscrepancyReportFollowingReceipt"));
		FilterDocumentTypes.Add(Catalogs.MetadataObjectIDs.FindByAttribute("Name", "ReturnOfGoodsFromCustomer"));
		FilterDocumentTypes.Add(Catalogs.MetadataObjectIDs.FindByAttribute("Name", "ReceiptOfGoodsFromCustodian"));
		
	ElsIf Parameters.Property("TraceabilityOfTransferToCommissionAgents") Then
		
		FilterBusinessTransactions.Clear();
		FilterBusinessTransactions.Add(Parameters.TraceabilityOfTransferToCommissionAgents);
		
		FilterDocumentTypes.Clear();
		FilterDocumentTypes.Add(Catalogs.MetadataObjectIDs.FindByAttribute("Name", "DiscrepancyReportFollowingShipment"));
		FilterDocumentTypes.Add(Catalogs.MetadataObjectIDs.FindByAttribute("Name", "CustomerInvoice"));
		FilterDocumentTypes.Add(Catalogs.MetadataObjectIDs.FindByAttribute("Name", "TransferOfGoodsToBailee"));
		
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
