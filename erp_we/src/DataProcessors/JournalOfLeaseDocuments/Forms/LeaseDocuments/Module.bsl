
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
	
	TMCommonUse.CustomizePeripherals(ThisObject);
	
	If Not Parameters.Property("FormAssignmentKey")
		Or IsBlankString(Parameters.FormAssignmentKey) Then
		PurposeUseKey = "LeaseDocuments";
		SettingsKey = "";
	Else
		PurposeUseKey = Parameters.FormAssignmentKey;
		SettingsKey                = Parameters.FormAssignmentKey;
	EndIf;
	
	ListOfDocumentsAutoUpdateMode = True;
	If Parameters.Property("ListFormSelections") Then
		FormsOpenedByHyperlink = True;
		FilterDocumentTypes = Parameters.ListFormSelections.FilterDocumentTypes;
		FilterBusinessTransactions = Parameters.ListFormSelections.FilterBusinessTransactions;
	Else
		RestoreSettings();
	EndIf;
	
	AdditionalParameters = New Structure("LocationOfLocalValidationData", Items.ListOfReglGroupVerification);
	FormEvents.OnCreateAtServer(ThisObject, Cancel, StandardProcessing, AdditionalParameters);
	
	VTBusinessTransactionsAndDocumentTypes = InitializeBusinessTransactionsAndDocuments(
		BusinessTransactionsAndDocuments.Unload(),
		FilterBusinessTransactions,
		FilterDocumentTypes,
		SettingsKey);
	
	BusinessTransactionsAndDocuments.Load(VTBusinessTransactionsAndDocumentTypes);
	
	SetRequestTextList();
	SetDynamicListSelections_();
	SetSelectionParameters();
	
	CustomizeFormElementsWhenCreating();
	
	TMCommonUse.FormInscriptionSelection(Items.HelpTextFilter.Title,
		BusinessTransactionsAndDocuments, FilterDocumentTypes, FilterBusinessTransactions);
	
	DocumentTypesUsed = VTBusinessTransactionsAndDocumentTypes.UnloadColumn("DocumentType");
	
	
	DocumentTypesUsed.Add(Type("DocumentRef.ReversingEntry"));
	
	// StandardSubsystems.AttachableCommands
	If DocumentTypesUsed.Count() > 0 Then
		PlacementParameters = AttachableCommands.PlacementParameters();
		PlacementParameters.Sources = New TypeDescription(DocumentTypesUsed);
		PlacementParameters.CommandBar = Items.ListCommandBar;
		PlacementParameters.GroupsPrefix = "List";
		AttachableCommands.OnCreateAtServer(ThisObject, PlacementParameters);
	EndIf
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	EquipmentManagerClient.StartConnectingDevicesWhenYouOpenForm(Undefined, ThisObject, "BarcodeScanner");
	// DynamicListsSettings
	SetParametersForUpdatingDocumentLists(False, 0);
	// End DynamicListsSettings
	
EndProcedure

&AtClient
Procedure OnClose(Exit)
	
	If Not Exit Then
		ShouldSaveSettings();
	EndIf;
	
	EquipmentManagerClient.StartDisablingHardwareWhenClosingForm(Undefined, ThisObject);
	
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
	
	TheListNeedsToBeUpdated = False;
	If EventName = "Write_File"
		Or EventName = "Conducting_Storno"
		Or EventName = "Write_ReversingEntry" Then
			
		TheListNeedsToBeUpdated = True;
		
	ElsIf StrFind(EventName, "Record_") <> 0 Then
		
		For Each LineDocument In BusinessTransactionsAndDocuments Do
			EventNameDocumentEntry = StrReplace(LineDocument.FullDocumentName, "Document.", "Record_");
			If EventNameDocumentEntry = EventName Then
				TheListNeedsToBeUpdated = True;
				Break;
			EndIf; 
		EndDo;
		
	EndIf;
	
	If TheListNeedsToBeUpdated Then
		// DynamicListsSettings
		UpdateListOfDocumentsEventNotificationProcessing("List", Parameter);
		// End DynamicListsSettings
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure FilterOrganizationOnChange(Item)
	
	WhenSelectionChanges();
	
EndProcedure

&AtClient
Procedure FilterPartnerOnChange(Item)
	
	WhenSelectionChanges();

EndProcedure

&AtClient
Procedure FilterCounterpartyOnChange(Item)
	
	WhenSelectionChanges();
	
EndProcedure

&AtClient
Procedure FilterContractOnChange(Item)
	
	WhenSelectionChanges();

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
	TMCommonUseClient.SetDeletionMark(Item, Title);
	
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
	
EndProcedure

&AtClient
Procedure ListPost(Command)
	
	TMCommonUseClient.PostDocuments(Items.List, Title,
		OperationsWithDocumentJournalsClient.ParametersForUpdatingDocumentList(ThisObject, "List"));
	
EndProcedure

&AtClient
Procedure ListSetClearADeletionMark(Command)
	
	TMCommonUseClient.SetDeletionMark(Items.List, Title, Undefined,
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

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisObject, Command);
	
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
	
	Settings = Common.CommonSettingsStorageLoad("DataProcessor.JournalOfLeaseDocuments.Form.DocumentsLeasing", PurposeUseKey);
	
	ListOfDocumentsAutoUpdateMode = True;
	
	If TypeOf(Settings) = Type("Structure") Then
	
		ListInterval = Settings.ListInterval;

		Settings.Property("FilterOrganization", FilterOrganization);
		Settings.Property("FilterPartner", FilterPartner);
		Settings.Property("FilterCounterparty", FilterCounterparty);
		Settings.Property("FilterContract", FilterContract);
		
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
		|FilterOrganization,FilterPartner,FilterCounterparty,FilterContract,
		|FilterBusinessTransactions,
		|FilterDocumentTypes,
		|ListOfDocumentsAutoUpdateMode";
	
	Settings = New Structure(AttributesToSaveNames);
	FillPropertyValues(Settings, ThisObject);
	
	Common.CommonSettingsStorageSave("DataProcessor.JournalOfLeaseDocuments.Form.DocumentsLeasing", PurposeUseKey, Settings);
	
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
	
	If GetFunctionalOption("UsePartnersAndCounterparties") Then
		// If counterparties are available, then the selection by partner is redundant.
		Items.FilterPartner.Visible = False;
	Else
		Items.ListCounterparty.Visible = False;
		Items.FilterCounterparty.Visible = False;
	EndIf;
	
	If Not GetFunctionalOption("UseMultipleCompanies") Then
		Items.FilterOrganization.Visible = False;
		Items.ListOrganization.Visible = False;
	EndIf;
	
	ConfigureFormUsingSettingsForBusinessOperationsAndDocuments();
	
EndProcedure

&AtServer
Procedure ConfigureFormUsingSettingsForBusinessOperationsAndDocuments()
	
	TMCommonUse.WorkplaceData(
		BusinessTransactionsAndDocuments.Unload(), 
		DefaultFormAssignmentKey(), 
		NStr("vi = 'tất cả';
			|ru = 'все';
			|en = 'all'; fa = 'همه';
			|it = 'tutti';
			|pl = 'all';
			|tr = 'tümü'"));
	
	ConfigureDocumentManagementButtons();
	
	TMCommonUse.ReplaceLinkFieldWithExpressByDocumentTypeConstruct(Items.List,
		BusinessTransactionsAndDocuments);
	
EndProcedure

// Defines the composition of documents and business operations that are available for display in the workplace.
//
// Parameters:
//  BusinessTransactionsAndDocuments	 - ValueTable - Table of values with columns:
//     * BusinessOperation					 - EnumRef.BusinessTransactions
//     * MetadataObjectID			 - CatalogRef.MetadataObjectIDs
//     * Filter									 - Boolean
//     * DocumentPresentation					 - String
//     * FullDocumentName						 - String
//     * Invoice								 - Boolean
//     * ReferenceIsUsed				 - Boolean
//     * StatusesAreUsed					 - Boolean
//     * BySeveralOrders					 - Boolean
//     * GoodsReceiptNoteIsImpossible				 - Boolean
//     * DivideDocumentsByDepartment		 - Boolean
//     * InvoiceFullName						 - String
//     * PurposeUseKey			 - String
//     * AccessRightInsert					 - Boolean
//     * AccessRightUpdate					 - Boolean
//     * WorkplaceTitle					 - String
//     * NamesOfElementsWithManagedVisibility	 - String
//     * WorkplaceItemNames			 - String
//     * NamesOfDisplayedElements				 - String
//     * HyperlinkCalculationManagerForRegistration	 - String
//  FilterBusinessTransactions		 - ValueList of EnumRef.BusinessTransactions
//  FilterDocumentTypes				 - ValueList of CatalogRef.MetadataObjectIDs
//  PurposeUseKey		 - String - key of the workplace for which the function is called
//  UnregisteredDocuments			 - Boolean - indicates whether to call the method for the form "Formspiskakoformleniyu".
// 
// Returns:
//   - ValueTable - Table of values with columns:
//     * BusinessOperation					 - EnumRef.BusinessTransactions
//     * MetadataObjectID			 - CatalogRef.MetadataObjectIDs
//     * Filter									 - Boolean
//     * DocumentPresentation					 - String
//     * FullDocumentName						 - String
//     * Invoice								 - Boolean
//     * ReferenceIsUsed				 - Boolean
//     * StatusesAreUsed					 - Boolean
//     * BySeveralOrders					 - Boolean
//     * GoodsReceiptNoteIsImpossible				 - Boolean
//     * DivideDocumentsByDepartment		 - Boolean
//     * InvoiceFullName						 - String
//     * PurposeUseKey			 - String
//     * AccessRightInsert					 - Boolean
//     * AccessRightUpdate					 - Boolean
//     * WorkplaceTitle					 - String
//     * NamesOfElementsWithManagedVisibility	 - String
//     * WorkplaceItemNames			 - String
//     * NamesOfDisplayedElements				 - String
//     * HyperlinkCalculationManagerForRegistration	 - String
//
//
&AtServerNoContext
Function InitializeBusinessTransactionsAndDocuments(BusinessTransactionsAndDocuments, FilterBusinessTransactions, FilterDocumentTypes, PurposeUseKey, UnregisteredDocuments = False)
	
	#Region AccountingForTenantOnBalanceSheet
	String = BusinessTransactionsAndDocuments.Add();
	String.BusinessOperation        = Enums.BusinessTransactions.SigningOfLeaseContract;
	String.DocumentType                 = Type("DocumentRef.SigningOfLeaseContract");
	String.FullDocumentName           = Metadata.Documents.SigningOfLeaseContract.FullName();
	String.PurposeUseKey  = PurposeUseKey;
	String.WorkplaceTitle       = NStr("vi = 'Ký hợp đồng thuê';
										|ru = 'Заключение договора аренды';
										|en = 'Rental term commitment'; fa = 'تعهد مدت اجاره';
										|it = 'Conclusione del contratto di affitto';
										|pl = 'Zawarcie umowy dzierżawy';
										|tr = 'Kira sözleşmesinin imzalanması '");
	String.Order                      = 1;
	String.ButtonGroup                 = "AccountingForTenantOnBalanceSheet";
	String.AddButtonCreate        = True;
	
	String = BusinessTransactionsAndDocuments.Add();
	String.BusinessOperation        = Enums.BusinessTransactions.RecognitionOfLeaseItems;
	String.DocumentType                 = Type("DocumentRef.FixedAssetsInitialRecognition2_4");
	String.FullDocumentName           = Metadata.Documents.FixedAssetsInitialRecognition2_4.FullName();
	String.PurposeUseKey  = PurposeUseKey;
	String.WorkplaceTitle       = NStr("vi = 'Tiếp nhận vào kế toán đối tượng thuê';
										|ru = 'Принятие к учету предметов аренды';
										|en = 'Recognition of rental objects'; fa = 'شناسایی موضوعات اجاره';
										|it = 'Ricezione in contabilità degli elementi di affitto';
										|pl = 'Przyjęcie do ewidencji przedmiotów dzierżawy';
										|tr = 'Kira kalemlerinin muhasebesine kabul edilmesi'");
	String.Order                      = 2;
	String.ButtonGroup                 = "AccountingForTenantOnBalanceSheet";
	String.AddButtonCreate        = True;
	
	String = BusinessTransactionsAndDocuments.Add();
	String.BusinessOperation        = Enums.BusinessTransactions.DisposeFixedAssets;
	String.DocumentType                 = Type("DocumentRef.DisposeFixedAssets2_4");
	String.FullDocumentName           = Metadata.Documents.DisposeFixedAssets2_4.FullName();
	String.PurposeUseKey  = PurposeUseKey;
	String.WorkplaceTitle       = NStr("vi = 'Ghi giảm các đối tượng thuê';
										|ru = 'Списание предметов аренды';
										|en = 'Write off rental objects'; fa = 'Write off rental objects';
										|it = 'Списание предметов аренды';
										|pl = 'Write off rental objects';
										|tr = 'Kiralanan varlıkların gider yazılması'");
	String.Order                      = 2;
	String.ButtonGroup                 = "AccountingForTenantOnBalanceSheet";
	String.AddButtonCreate        = True;

	String = BusinessTransactionsAndDocuments.Add();
	String.BusinessOperation        = Enums.BusinessTransactions.ReceivingLeaseServices;
	String.DocumentType                 = Type("DocumentRef.ReceivingLeaseServices");
	String.FullDocumentName           = Metadata.Documents.ReceivingLeaseServices.FullName();
	String.PurposeUseKey  = PurposeUseKey;
	String.WorkplaceTitle       = NStr("vi = 'Tiếp nhận dịch vụ thuê';
										|ru = 'Поступление услуг по аренде';
										|en = 'Receiving rental services'; fa = 'دریافت خدمات اجاره';
										|it = 'Ricezione dei servizi relativi all''affitto';
										|pl = 'Wpływ usług dotyczących dzierżawy';
										|tr = 'Kiralama hizmetleri makbuzu'");
	String.Order                      = 3;
	String.ButtonGroup                 = "AccountingForTenantOnBalanceSheet";
	String.AddButtonCreate        = True;

	String = BusinessTransactionsAndDocuments.Add();
	String.BusinessOperation        = Enums.BusinessTransactions.LeaseTermAdjustment;
	String.DocumentType                 = Type("DocumentRef.LeaseTermAdjustment");
	String.FullDocumentName           = Metadata.Documents.LeaseTermAdjustment.FullName();
	String.PurposeUseKey  = PurposeUseKey;
	String.WorkplaceTitle       = NStr("vi = 'Thay đổi điều khoản hợp đồng thuê TSCĐ';
										|ru = 'Изменение условий договора аренды ОС';
										|en = 'Fixed asset rental term adjustment'; fa = 'Fixed asset rental term adjustment';
										|it = 'Modifica delle condizioni del contratto di affitto delle immobilizzazioni';
										|pl = 'Zmiana warunków umowy dzierżawy środków trwałych';
										|tr = 'Sabit kıymet kira sözleşmesinin şartlarını değiştirme'");
	String.Order                      = 4;
	String.ButtonGroup                 = "AccountingForTenantOnBalanceSheet";
	String.AddButtonCreate        = True;

	String = BusinessTransactionsAndDocuments.Add();
	String.BusinessOperation        = Enums.BusinessTransactions.VendorInvoiceLeasedAssets;
	String.DocumentType                 = Type("DocumentRef.VendorInvoiceLeasedAssets");
	String.FullDocumentName           = Metadata.Documents.VendorInvoiceLeasedAssets.FullName();
	String.PurposeUseKey  = PurposeUseKey;
	String.WorkplaceTitle       = NStr("vi = 'Mua lại TSCĐ đã thuê';
										|ru = 'Выкуп арендованных ОС';
										|en = 'Vendor invoice — Leased assets'; fa = 'فاکتور تأمین‌کننده — دارایی‌های اجاره‌ای';
										|it = 'Rimborso delle immobilizzazioni in affitto';
										|pl = 'Wykup wynajmowanych środków trwałych';
										|tr = 'Kiralanan sabit kıymetlerin itfası'");
	String.Order                      = 5;
	String.ButtonGroup                 = "AccountingForTenantOnBalanceSheet";
	String.AddButtonCreate        = True;

	String = BusinessTransactionsAndDocuments.Add();
	String.BusinessOperation        = Enums.BusinessTransactions.EarlyBuyoutOfLeasedAssets;
	String.DocumentType                 = Type("DocumentRef.VendorInvoiceLeasedAssets");
	String.FullDocumentName           = Metadata.Documents.VendorInvoiceLeasedAssets.FullName();
	String.PurposeUseKey  = PurposeUseKey;
	String.WorkplaceTitle       = NStr("vi = 'Mua lại TSCĐ đã thuê trước thời hạn';
										|ru = 'Досрочный выкуп арендованных ОС';
										|en = 'Early vendor invoice — leased assets'; fa = 'فاکتور تأمین‌کننده زودهنگام — دارایی‌های اجاره‌ای';
										|it = 'Rimborso anticipato delle immobilizzazioni in affitto';
										|pl = 'Przedterminowy wykup wynajmowanych środków trwałych';
										|tr = 'Erken satıcı faturası - kiralanan varlıklar'");
	String.Order                      = 6;
	String.ButtonGroup                 = "AccountingForTenantOnBalanceSheet";
	String.AddButtonCreate        = True;

	String = BusinessTransactionsAndDocuments.Add();
	String.BusinessOperation        = Enums.BusinessTransactions.LeaseTermination;
	String.DocumentType                 = Type("DocumentRef.LeaseTermination");
	String.FullDocumentName           = Metadata.Documents.LeaseTermination.FullName();
	String.PurposeUseKey  = PurposeUseKey;
	String.WorkplaceTitle       = NStr("vi = 'Chấm dứt hợp đồng thuê';
										|ru = 'Прекращение договоров аренды';
										|en = 'Termination of rental contracts'; fa = 'فسخ قراردادهای اجاره';
										|it = 'Soluzione del contratto di affitto';
										|pl = 'Wygaśnięcie umów dzierżawy';
										|tr = 'Kira sözleşmesi feshi'");
	String.Order                      = 7;
	String.ButtonGroup                 = "AccountingForTenantOnBalanceSheet";
	String.AddButtonCreate        = True;

	String = BusinessTransactionsAndDocuments.Add();
	String.BusinessOperation        = Enums.BusinessTransactions.EarlyTerminationOfLeaseContract;
	String.DocumentType                 = Type("DocumentRef.LeaseTermination");
	String.FullDocumentName           = Metadata.Documents.LeaseTermination.FullName();
	String.PurposeUseKey  = PurposeUseKey;
	String.WorkplaceTitle       = NStr("vi = 'Chấm dứt hợp đồng thuê trước thời hạn';
										|ru = 'Досрочное прекращение договоров аренды';
										|en = 'Early termination of the rental contracts'; fa = 'Early termination of the rental contracts';
										|it = 'Soluzione anticipata dei contratti di affitto';
										|pl = 'Przedterminowe wygaśnięcie umów dzierżawy';
										|tr = 'Kira sözleşmelerinin erken feshi'");
	String.Order                      = 8;
	String.ButtonGroup                 = "AccountingForTenantOnBalanceSheet";
	String.AddButtonCreate        = True;
	#EndRegion
	
	#Region AccountingWithLesseeForBalanceSheet
	String = BusinessTransactionsAndDocuments.Add();
	String.BusinessOperation        = Enums.BusinessTransactions.ReceiveLeasedAssets;
	String.DocumentType                 = Type("DocumentRef.ReceiveLeasedAssets");
	String.FullDocumentName           = Metadata.Documents.ReceiveLeasedAssets.FullName();
	String.PurposeUseKey  = PurposeUseKey;
	String.WorkplaceTitle       = NStr("vi = 'Nhận TSCĐ thuê (ngoài bảng)';
										|ru = 'Поступление арендованных ОС (забалансовый учет)';
										|en = 'Receive leased assets (off-balance)'; fa = 'دریافت دارایی‌های اجاره‌ای (خارج از ترازنامه)';
										|it = 'Ricezione delle immobilizzazioni in affitto (contabilità fuori bilancio)';
										|pl = 'Wpływ wynajmowanych środków trwałych (ewidencja pozabilansowa)';
										|tr = 'Kiralanan SV''lerin alınması (bilanço dışı)'");
	String.DocumentPresentation        = NStr("vi = 'Tiếp nhận (ngoài bảng)';
												|ru = 'Поступление (забалансовый учет)';
												|en = 'Receipt (off-balance accounting)'; fa = 'Receipt (off-balance accounting)';
												|it = 'Ricezione (contabilità fuori bilancio)';
												|pl = 'Wpływ (ewidencja pozabilansowa)';
												|tr = 'Makbuz (bilanço dışı muhasebe)'");
	String.Order                      = 9;
	String.ButtonGroup                 = "AccountingWithLesseeForBalanceSheet";
	String.AddButtonCreate        = True;
	
	String = BusinessTransactionsAndDocuments.Add();
	String.BusinessOperation        = Enums.BusinessTransactions.ReturnLeasedAssets;
	String.DocumentType                 = Type("DocumentRef.ReturnLeasedAssets");
	String.FullDocumentName           = Metadata.Documents.ReturnLeasedAssets.FullName();
	String.PurposeUseKey  = PurposeUseKey;
	String.WorkplaceTitle       = NStr("vi = 'Thanh lý TSCĐ đã thuê (kế toán ngoài bảng)';
										|ru = 'Выбытие арендованных ОС (забалансовый учет)';
										|en = 'Return leased assets (off-balance)'; fa = 'برگشت دارایی‌های اجاره‌ای (خارج از ترازنامه)';
										|it = 'Dismissione immobilizzazioni in affitto (contabilità fuori bilancio)';
										|pl = 'Wycofanie wynajmowanych środków trwałych (ewidencja pozabilansowa)';
										|tr = 'Kiralanan sabit kıymetlerin iadesi (bilanço dışı)'");
	String.DocumentPresentation        = NStr("vi = 'Thanh lý (kế toán ngoài bảng)';
												|ru = 'Выбытие (забалансовый учет)';
												|en = 'Disposal (off-balance accounting)'; fa = 'Disposal (off-balance accounting)';
												|it = 'Dismissione (contabilità fuori bilancio)';
												|pl = 'Wycofanie (ewidencja pozabilansowa)';
												|tr = 'Elden çıkarma (bilanço dışı muhasebe)'");
	String.Order                      = 10;
	String.ButtonGroup                 = "AccountingWithLesseeForBalanceSheet";
	String.AddButtonCreate        = True;
	#EndRegion
	
	#Region AccountingWithLessor
	String = BusinessTransactionsAndDocuments.Add();
	String.BusinessOperation        = Enums.BusinessTransactions.ProvideAssetsToLeasee;
	String.DocumentType                 = Type("DocumentRef.ProvideAssetsToLeasee2_4");
	String.FullDocumentName           = Metadata.Documents.ProvideAssetsToLeasee2_4.FullName();
	String.PurposeUseKey  = PurposeUseKey;
	String.WorkplaceTitle       = NStr("vi = 'Chuyển giao TSCĐ cho thuê';
										|ru = 'Передача ОС в аренду';
										|en = 'Provide assets to lessee'; fa = 'واگذاری دارایی‌ها به مستأجر';
										|it = 'Trasferimento delle immobilizzazioni in affitto';
										|pl = 'Przekazanie środków trwałych do dzierżawy';
										|tr = 'Sabit kıymetlerin kiralayana temini'");
	String.Order                      = 11;
	String.ButtonGroup                 = "AccountingWithLessor";
	String.AddButtonCreate        = True;
	
	String = BusinessTransactionsAndDocuments.Add();
	String.BusinessOperation        = Enums.BusinessTransactions.ReturnAssetsFromLeasee;
	String.DocumentType                 = Type("DocumentRef.ReturnAssetsFromLeasee2_4");
	String.FullDocumentName           = Metadata.Documents.ReturnAssetsFromLeasee2_4.FullName();
	String.PurposeUseKey  = PurposeUseKey;
	String.WorkplaceTitle       = NStr("vi = 'Trả lại TSCĐ đã thuê';
										|ru = 'Возврат ОС из аренды';
										|en = 'Return assets from lessee'; fa = 'برگشت دارایی‌ها از مستأجر';
										|it = 'Reso delle immobilizzazioni dall''affitto';
										|pl = 'Zwrot środków trwałych z dzierżawy';
										|tr = 'Sabit kıymetlerin kiralayandan iadesi'");
	String.Order                      = 12;
	String.ButtonGroup                 = "AccountingWithLessor";
	String.AddButtonCreate        = True;
	
	String = BusinessTransactionsAndDocuments.Add();
	String.BusinessOperation        = Enums.BusinessTransactions.ChangeRentalTerms;
	String.DocumentType                 = Type("DocumentRef.ChangeRentalTerms");
	String.FullDocumentName           = Metadata.Documents.ChangeRentalTerms.FullName();
	String.PurposeUseKey  = PurposeUseKey;
	String.WorkplaceTitle       = NStr("vi = 'Thay đổi điều kiện chuyển giao cho thuê';
										|ru = 'Изменение условий передачи в аренду';
										|en = 'Change rental terms'; fa = 'تغییر شرایط اجاره';
										|it = 'Изменение условий передачи в аренду';
										|pl = 'Change rental terms';
										|tr = 'Kira devir şartlarının değiştirilmesi'");
	String.Order                      = 13;
	String.ButtonGroup                 = "AccountingWithLessor";
	String.AddButtonCreate        = True;

	String = BusinessTransactionsAndDocuments.Add();
	String.BusinessOperation        = Enums.BusinessTransactions.RenderRentalServices;
	String.DocumentType                 = Type("DocumentRef.CustomerInvoiceServicesAndAssets");
	String.FullDocumentName           = Metadata.Documents.CustomerInvoiceServicesAndAssets.FullName();
	String.PurposeUseKey  = PurposeUseKey;
	String.WorkplaceTitle       = NStr("vi = 'Cung cấp dịch vụ và tài sản khác';
										|ru = 'Реализация услуг и прочих активов';
										|en = 'Customer invoice — Services and Assets'; fa = 'فاکتور مشتری — خدمات و دارایی‌ها';
										|it = 'Vendita dei servizi e altri attivi';
										|pl = 'Realizacja usług i innych aktywów';
										|tr = 'Müşteri faturası - Hizmetler ve Varlıklar'");
	String.Order                      = 14;
	String.ButtonGroup                 = "AccountingWithLessor";
	String.AddButtonCreate        = True;
	#EndRegion
	
	#Region TreasuryAndARAPAccounting
	String = BusinessTransactionsAndDocuments.Add();
	String.BusinessOperation        = Enums.BusinessTransactions.PaymentToLessor;
	String.DocumentType                 = Type("DocumentRef.BankAccountIssue");
	String.FullDocumentName           = Metadata.Documents.BankAccountIssue.FullName();
	String.PurposeUseKey  = PurposeUseKey;
	String.WorkplaceTitle       = NStr("vi = 'Chi tiền từ tài khoản ngân hàng';
										|ru = 'Списания безналичных ДС';
										|en = 'Outgoing payments — Bank account'; fa = 'پرداخت‌های وجه — حساب بانکی';
										|it = 'Addebito di fondi non in contanti';
										|pl = 'Pobrania bezgotówkowych ŚP';
										|tr = 'Gayri nakdin gider yazılması'");
	String.Order                      = 15;
	String.ButtonGroup                 = "TreasuryAndARAPAccounting";
	String.AddButtonCreate        = True;
	
	String = BusinessTransactionsAndDocuments.Add();
	String.BusinessOperation        = Enums.BusinessTransactions.PaymentToLessor;
	String.DocumentType                 = Type("DocumentRef.CashVoucher");
	String.FullDocumentName           = Metadata.Documents.CashVoucher.FullName();
	String.PurposeUseKey  = PurposeUseKey;
	String.WorkplaceTitle       = NStr("vi = 'Phiếu chi';
										|ru = 'Расходные кассовые ордера';
										|en = 'Outgoing payments — Cash account'; fa = 'پرداخت‌های وجه — صندوق';
										|it = 'Mandati di pagamento';
										|pl = 'Dowody kasowe KW';
										|tr = 'Giden ödemeler - kasa hesabı'");
	String.Order                      = 16;
	String.ButtonGroup                 = "TreasuryAndARAPAccounting";
	String.AddButtonCreate        = True;
	
	String = BusinessTransactionsAndDocuments.Add();
	String.BusinessOperation        = Enums.BusinessTransactions.CashReceiptFromCustomer;
	String.DocumentType                 = Type("DocumentRef.BankAccountReceiptNote");
	String.FullDocumentName           = Metadata.Documents.BankAccountReceiptNote.FullName();
	String.PurposeUseKey  = PurposeUseKey;
	String.WorkplaceTitle       = NStr("vi = 'Thu tiền vào tài khoản ngân hàng';
										|ru = 'Поступления безналичных ДС';
										|en = 'Incoming payments — Bank account'; fa = 'دریافت‌های وجه — حساب بانکی';
										|it = 'Entrate di fondi monetari non in contanti';
										|pl = 'Przelew przychodzący';
										|tr = 'Gayri nakdin girişleri'");
	String.Order                      = 17;
	String.ButtonGroup                 = "TreasuryAndARAPAccounting";
	String.AddButtonCreate        = True;
	
	String = BusinessTransactionsAndDocuments.Add();
	String.BusinessOperation        = Enums.BusinessTransactions.RefundFromLessor;
	String.DocumentType                 = Type("DocumentRef.BankAccountReceiptNote");
	String.FullDocumentName           = Metadata.Documents.BankAccountReceiptNote.FullName();
	String.PurposeUseKey  = PurposeUseKey;
	String.WorkplaceTitle       = NStr("vi = 'Thu tiền vào tài khoản ngân hàng';
										|ru = 'Поступления безналичных ДС';
										|en = 'Incoming payments — Bank account'; fa = 'دریافت‌های وجه — حساب بانکی';
										|it = 'Entrate di fondi monetari non in contanti';
										|pl = 'Przelew przychodzący';
										|tr = 'Gayri nakdin girişleri'");
	String.Order                      = 18;
	String.ButtonGroup                 = "TreasuryAndARAPAccounting";
	String.AddButtonCreate        = True;

	String = BusinessTransactionsAndDocuments.Add();
	String.BusinessOperation        = Enums.BusinessTransactions.CashReceiptFromCustomer;
	String.DocumentType                 = Type("DocumentRef.CashAccountReceiptNote");
	String.FullDocumentName           = Metadata.Documents.CashAccountReceiptNote.FullName();
	String.PurposeUseKey  = PurposeUseKey;
	String.WorkplaceTitle       = NStr("vi = 'Phiếu thu';
										|ru = 'Приходные кассовые ордера';
										|en = 'Incoming payments — Cash account'; fa = 'دریافت‌های وجه — صندوق';
										|it = 'Ricevuta ordine contanti';
										|pl = 'Asygnaty kasowo przychodowe';
										|tr = 'Gelen ödemeler - kasa hesabı '");
	String.Order                      = 19;
	String.ButtonGroup                 = "TreasuryAndARAPAccounting";
	String.AddButtonCreate        = True;
	
	String = BusinessTransactionsAndDocuments.Add();
	String.BusinessOperation        = Enums.BusinessTransactions.RefundFromLessor;
	String.DocumentType                 = Type("DocumentRef.CashAccountReceiptNote");
	String.FullDocumentName           = Metadata.Documents.CashAccountReceiptNote.FullName();
	String.PurposeUseKey  = PurposeUseKey;
	String.WorkplaceTitle       = NStr("vi = 'Phiếu thu';
										|ru = 'Приходные кассовые ордера';
										|en = 'Incoming payments — Cash account'; fa = 'دریافت‌های وجه — صندوق';
										|it = 'Ricevuta ordine contanti';
										|pl = 'Asygnaty kasowo przychodowe';
										|tr = 'Gelen ödemeler - kasa hesabı '");
	String.Order                      = 20;
	String.ButtonGroup                 = "TreasuryAndARAPAccounting";
	String.AddButtonCreate        = True;
	#EndRegion
	
	#Region OBEntry
	String = BusinessTransactionsAndDocuments.Add();
	String.BusinessOperation 		= Enums.BusinessTransactions.OBEntryOnBalanceSheetLeasedFixedAssets;
	String.DocumentType                 = Type("DocumentRef.EntryOfCapitalAssetsBalance2_4");
	String.FullDocumentName			= Metadata.Documents.EntryOfCapitalAssetsBalance2_4.FullName();
	String.PurposeUseKey 	= PurposeUseKey;
	String.WorkplaceTitle	 	= NStr("vi = 'Nhập số dư đầu TSCĐ đã thuê (trong bảng cân đối)';
										|ru = 'Ввод начальных остатков арендованных ОС (на балансе)';
										|en = 'OB entry: leased fixed assets (on balance sheet)'; fa = 'ورود مانده افتتاحیه: دارایی‌های ثابت اجاره‌ای (در ترازنامه)';
										|it = 'Inserimento dei saldi iniziali delle immobilizzazioni in affitto (in bilancio)';
										|pl = 'Wprowadzenie sald początkowych wynajmowanych środków trwałych (na bilansie)';
										|tr = 'Kiralanan sabit kıymetlerin başlangıç bakiyelerinin girilmesi (bilançoda)'");
	String.Order                      = 21;
	String.ButtonGroup                 = "OBEntry";
	String.AddButtonCreate        = False;
	
	String = BusinessTransactionsAndDocuments.Add();
	String.BusinessOperation 		= Enums.BusinessTransactions.OBEntryOffBalanceSheetLeasedFixedAssets;
	String.DocumentType                 = Type("DocumentRef.EntryOfCapitalAssetsBalance2_4");
	String.FullDocumentName			= Metadata.Documents.EntryOfCapitalAssetsBalance2_4.FullName();
	String.PurposeUseKey 	= PurposeUseKey;
	String.WorkplaceTitle	 	= NStr("vi = 'Nhập số dư đầu TSCĐ đã thuê (ngoài bảng cân đối)';
										|ru = 'Ввод начальных остатков арендованных ОС (за балансом)';
										|en = 'OB entry: leased fixed assets (off balance sheet)'; fa = 'ورود مانده افتتاحیه: دارایی‌های ثابت اجاره‌ای (خارج از ترازنامه)';
										|it = 'Inserimento dei saldi iniziali delle immobilizzazioni in affitto (fuori bilancio)';
										|pl = 'Wprowadzenie sald początkowych środków trwałych (poza bilansem)';
										|tr = 'Kiralanan sabit kıymetlerin başlangıç bakiyelerinin girilmesi (bakiyenin arkasında)'");
	String.Order                      = 22;
	String.ButtonGroup                 = "OBEntry";
	String.AddButtonCreate        = False;

	String = BusinessTransactionsAndDocuments.Add();
	String.BusinessOperation 		= Enums.BusinessTransactions.OBEntryOffBalanceSheetFixedAssetsLeasedOut;
	String.DocumentType                 = Type("DocumentRef.EntryOfCapitalAssetsBalance2_4");
	String.FullDocumentName			= Metadata.Documents.EntryOfCapitalAssetsBalance2_4.FullName();
	String.PurposeUseKey 	= PurposeUseKey;
	String.WorkplaceTitle	 	= NStr("vi = 'Nhập số dư ban đầu của các mặt hàng cho thuê ngoài bảng';
										|ru = 'Ввод начальных остатков предметов лизинга за балансом';
										|en = 'OB entry: financial lease items off the balance sheet'; fa = 'ورود مانده افتتاحیه: اقلام اجاره مالی خارج از ترازنامه';
										|it = 'Inserimento dei saldi iniziali degli elementi del leasing in bilancio';
										|pl = 'Wprowadzenie sald początkowych przedmiotów leasingu poza bilansem';
										|tr = 'Kiralanan kalemlerin ilk bilanço arkasına girilmesi'");
	String.Order                      = 23;
	String.ButtonGroup                 = "OBEntry";
	String.AddButtonCreate        = False;
	
	String = BusinessTransactionsAndDocuments.Add();
	String.BusinessOperation 		= Enums.BusinessTransactions.OBEntryOnBalanceSheetFixedAssetsLeasedOut;
	String.DocumentType                 = Type("DocumentRef.EntryOfCapitalAssetsBalance2_4");
	String.FullDocumentName			= Metadata.Documents.EntryOfCapitalAssetsBalance2_4.FullName();
	String.PurposeUseKey 	= PurposeUseKey;
	String.WorkplaceTitle	 	= NStr("vi = 'Nhập số dư ban đầu của các mặt hàng cho thuê trong bảng';
										|ru = 'Ввод начальных остатков переданных в аренду предметов лизинга на балансе';
										|en = 'OB entry: financial lease items on the balance sheet'; fa = 'ورود مانده افتتاحیه: اقلام اجاره مالی در ترازنامه';
										|it = 'Inserimento dei saldi iniziali degli elementi del leasing in bilancio dati in affitto';
										|pl = 'Wprowadzenie początkowych sald przekazanych do dzierżawy przedmiotów leasingu na bilansie';
										|tr = 'Kiralanan kalemlerin ilk bakiyelerinin bilançoya girilmesi'");
	String.Order                      = 24;
	String.ButtonGroup                 = "OBEntry";
	String.AddButtonCreate        = False;

	String = BusinessTransactionsAndDocuments.Add();
	String.BusinessOperation 		= Enums.BusinessTransactions.OBEntryCostOfOwnedInvestmentProperty;
	String.DocumentType                 = Type("DocumentRef.EntryOfCapitalAssetsBalance2_4");
	String.FullDocumentName			= Metadata.Documents.EntryOfCapitalAssetsBalance2_4.FullName();
	String.PurposeUseKey 	= PurposeUseKey;
	String.WorkplaceTitle	 	= NStr("vi = 'Nhập số dư ban đầu của tài sản cố định cho thuê';
										|ru = 'Ввод начальных остатков переданных в аренду основных средств';
										|en = 'OB entry: leased out fixed assets'; fa = 'ورود مانده افتتاحیه: دارایی‌های ثابت اجاره‌داده‌شده';
										|it = 'Inserimento dei saldi iniziali dei capitali fissi dati in affitto';
										|pl = 'Wprowadzenie sald początkowych przekazanych do dzierżawy środków trwałych';
										|tr = 'Kiralanan sabit kıymetlerin başlangıç bakiyelerinin girilmesi'");
	String.Order                      = 25;
	String.ButtonGroup                 = "OBEntry";
	String.AddButtonCreate        = False;
	
	String = BusinessTransactionsAndDocuments.Add();
	String.BusinessOperation 		= Enums.BusinessTransactions.OBEntryLeaseContractsARAP;
	String.DocumentType                 = Type("DocumentRef.OBEntryOfLeaseSettlements");
	String.FullDocumentName			= Metadata.Documents.OBEntryOfLeaseSettlements.FullName();
	String.PurposeUseKey 	= PurposeUseKey;
	String.WorkplaceTitle	 	= NStr("vi = 'Nhập số dư hạch toán công nợ về thuê';
										|ru = 'Ввод остатков взаиморасчетов по аренде';
										|en = 'OB entry: rental AR/AP'; fa = 'ورود مانده افتتاحیه: دریافتنی/پرداختنی اجاره';
										|it = 'Inserimento dei saldi dei regolamenti di conti reciproci di affitto';
										|pl = 'Wprowadzenie sald rozliczeń wzajemnych z tytułu dzierżawy';
										|tr = 'Kira karşılıklı yerleşim bakiyelerinin girilmesi'");
	String.Order                      = 26;
	String.ButtonGroup                 = "OBEntry";
	String.AddButtonCreate        = False;
	
	String = BusinessTransactionsAndDocuments.Add();
	String.BusinessOperation 		= Enums.BusinessTransactions.EnterRentalInvestmentBalance;
	String.DocumentType                 = Type("DocumentRef.EnterRentalInvestmentBalance");
	String.FullDocumentName			= Metadata.Documents.EnterRentalInvestmentBalance.FullName();
	String.PurposeUseKey 	= PurposeUseKey;
	String.WorkplaceTitle	 	= NStr("vi = 'Nhập số dư đầu tư cho thuê';
										|ru = 'Ввод остатков инвестиции в аренду';
										|en = 'Enter rental investment balance'; fa = 'ورود مانده سرمایه‌گذاری اجاره';
										|it = 'Ввод остатков инвестиции в аренду';
										|pl = 'Enter rental investment balance';
										|tr = 'Kiralama için yatırım bakiyelerinin girişi'");
	String.Order                      = 27;
	String.ButtonGroup                 = "OBEntry";
	String.AddButtonCreate        = False;
	#EndRegion
	
	If PurposeUseKey = DefaultFormAssignmentKey() Then
		SettingsKey = "";
	Else
		SettingsKey = PurposeUseKey;
	EndIf;
	
	TableOfValuesAvailable = TMCommonUse.AvailableBusinessTransactionsAndDocuments(
								BusinessTransactionsAndDocuments, 
								FilterBusinessTransactions, 
								FilterDocumentTypes, 
								SettingsKey);
	
	Return TableOfValuesAvailable;
		
EndFunction

&AtServer
Procedure InitializeAddTextTTDocumentsContractAtTS(TextTTDocumentsContractWH)
	
	If TextTTDocumentsContractWH = "" Then
		
		TextTTDocumentsContractWH =
		"SELECT ALLOWED
		|	DocumentData.Ref AS Ref
		|INTO TTDocumentsContractWH
		|";
		
	Else
		TextTTDocumentsContractWH = TextTTDocumentsContractWH + "
		|
		|UNION ALL
		|
		|SELECT
		|	DocumentData.Ref AS Ref
		|";
	EndIf;
	
EndProcedure

&AtServer
Procedure SetRequestTextList()
	
	QueryText =
	"SELECT
	|	DocumentsRegistryOverridable.Ref AS Ref,
	|	DocumentsRegistryOverridable.IBDocumentNumber AS Number,
	|	DocumentsRegistryOverridable.IBDocumentDate AS Date,
	|	DocumentsRegistryOverridable.Status AS Status,
	|	DocumentsRegistryOverridable.Posted AS Posted,
	|	DocumentsRegistryOverridable.DeletionMark AS DeletionMark,
	|	DocumentsRegistryOverridable.BusinessOperation AS BusinessOperation,
	|	DocumentsRegistryOverridable.Partner AS Partner,
	|	CAST(DocumentsRegistryOverridable.Counterparty.Key AS Catalog.Counterparties) AS Counterparty,
	|	DocumentsRegistryOverridable.Counterparty AS CounterpartyKey,
	|	DocumentsRegistryOverridable.Contract AS Contract,
	|	DocumentsRegistryOverridable.Organization AS Organization,
	|	DocumentsRegistryOverridable.Department AS Department,
	|	DocumentsRegistryOverridable.Currency AS Currency,
	|	DocumentsRegistryOverridable.Sum AS DocumentAmount,
	|	DocumentsRegistryOverridable.EmployeeResponsible AS EmployeeResponsible,
	|	DocumentsRegistryOverridable.Comment AS Comment,
	|	DocumentsRegistryOverridable.SourceDocumentNumber AS IncomingDocumentNumber,
	|	DocumentsRegistryOverridable.SourceDocumentDate AS IncomingDocumentDate,
	|	DocumentsRegistryOverridable.More AS More,
	|	EDStatesOverridable.EDIState AS EDIState,	
	|	CASE
	|		WHEN DocumentsWithCounterpartyCheckErrorsOverridable.Document IS NULL
	|			THEN FALSE
	|		ELSE TRUE
	|	END AS ThereAreErrorsInCheckingCounterparties,
	|	CASE
	|		WHEN DocumentsRegistryOverridable.Posted
	|			THEN 0
	|		WHEN DocumentsRegistryOverridable.DeletionMark
	|			THEN 1
	|		ELSE 2
	|	END AS CustomPicture,
	|	DocumentsRegistryOverridable.AdditionalRecord AS AdditionalRecord,
	|	DocumentsRegistryOverridable.RefType AS RefType,
	|	VALUETYPE(DocumentsRegistryOverridable.Ref) AS ValueType,
	|	&Contract AS FilterContract,
	|	DATETIME(1, 1, 1) AS DateOfPaymentConfirmation,
	|	&CheckStatus AS CheckStatus,
	|	CAST(&CheckingIndicator AS BOOLEAN) AS CheckingIndicator,
	|	FALSE AS ThereIsARequestForPayment,
	|	FALSE AS ThereIsAPayment,
	|	DocumentsRegistryOverridable.RecordID AS RecordID,
	|	CASE
	|		WHEN FilesExistOverridable.HasFiles IS NULL
	|			THEN 0
	|		WHEN FilesExistOverridable.HasFiles
	|			THEN 1
	|		ELSE 0
	|	END AS HasFiles
	|FROM
	|	InformationRegister.DocumentsRegistry AS DocumentsRegistryOverridable
	|
	|		{LEFT JOIN InformationRegister.StatesByEDIAccountingObjects AS EDStatesOverridable
	|		ON (EDStatesOverridable.ObjectReference = DocumentsRegistryOverridable.Ref)
	|
	|		LEFT JOIN InformationRegister.DocumentsWithCounterpartyCheckErrors AS DocumentsWithCounterpartyCheckErrorsOverridable
	|		ON DocumentsRegistryOverridable.Ref = DocumentsWithCounterpartyCheckErrorsOverridable.Document
	|			AND (&UsingOfCheckIsAnOption)}
	|
	|		LEFT JOIN InformationRegister.FilesExist AS FilesExistOverridable
	|		ON DocumentsRegistryOverridable.Ref = FilesExistOverridable.ObjectWithFiles
	|
	|		LEFT JOIN TTDocumentsContractWH AS TTDocumentsContractWH
	|		ON TTDocumentsContractWH.Ref = DocumentsRegistryOverridable.Ref
	|WHERE
	|	&AdditionalSelectionCondition
	|
	|{WHERE
	|	DocumentsRegistryOverridable.Ref.* AS Ref,
	|	DocumentsRegistryOverridable.Organization.* AS Organization,
	|	DocumentsRegistryOverridable.IBDocumentDate AS Date,
	|	DocumentsRegistryOverridable.IBDocumentNumber AS Number,
	|	DocumentsRegistryOverridable.Status AS Status,
	|	DocumentsRegistryOverridable.RefType AS RefType,
	|	DocumentsRegistryOverridable.BusinessOperation AS BusinessOperation,
	|	DocumentsRegistryOverridable.Partner.* AS Partner,
	|	CAST(DocumentsRegistryOverridable.Counterparty.Key AS Catalog.Counterparties).* AS Counterparty,
	|	DocumentsRegistryOverridable.Contract.* AS Contract,
	|	DocumentsRegistryOverridable.Department.* AS Department,
	|	DocumentsRegistryOverridable.EmployeeResponsible.* AS Manager,
	|	DocumentsRegistryOverridable.More AS More,
	|	DocumentsRegistryOverridable.Comment AS Comment,
	|	DocumentsRegistryOverridable.Posted AS Posted,
	|	DocumentsRegistryOverridable.DeletionMark AS DeletionMark,
	|	(DocumentsRegistryOverridable.IBDocumentDate >= &BeginOfPeriod
	|		AND DocumentsRegistryOverridable.IBDocumentDate <= &EndOfPeriod)}";
	
	If ValueIsFilled(FilterContract) Then
		
		TextTTDocumentsContractWH = "";
		
		If AccessRight("Read", Metadata.Documents.CashVoucher) Then
			
			InitializeAddTextTTDocumentsContractAtTS(TextTTDocumentsContractWH);
			
			TextTTDocumentsContractWH = TextTTDocumentsContractWH + 
			"FROM
			|	Document.CashVoucher AS DocumentData
			|WHERE
			|	DocumentData.Ref IN
			|			(SELECT
			|				TabularSectionData.Ref
			|			FROM
			|				Document.CashVoucher.ARAPDetails AS TabularSectionData
			|			WHERE
			|				TabularSectionData.Ref = DocumentData.Ref
			|				AND TabularSectionData.LeaseContracts = &Contract)";
			
		EndIf;
		
		If AccessRight("Read", Metadata.Documents.CashAccountReceiptNote) Then

			InitializeAddTextTTDocumentsContractAtTS(TextTTDocumentsContractWH);

			TextTTDocumentsContractWH = TextTTDocumentsContractWH + 
			"FROM
			|	Document.CashAccountReceiptNote AS DocumentData
			|WHERE
			|	DocumentData.Ref IN
			|			(SELECT
			|				TabularSectionData.Ref
			|			FROM
			|				Document.CashAccountReceiptNote.ARAPDetails AS TabularSectionData
			|			WHERE
			|				TabularSectionData.Ref = DocumentData.Ref
			|				AND TabularSectionData.LeaseContracts = &Contract)";
			
		EndIf;
		
		If AccessRight("Read", Metadata.Documents.BankAccountIssue) Then
			
			InitializeAddTextTTDocumentsContractAtTS(TextTTDocumentsContractWH);
			
			TextTTDocumentsContractWH = TextTTDocumentsContractWH + 
			"FROM
			|	Document.BankAccountIssue AS DocumentData
			|WHERE
			|	DocumentData.Ref IN
			|			(SELECT
			|				TabularSectionData.Ref
			|			FROM
			|				Document.BankAccountIssue.ARAPDetails AS TabularSectionData
			|			WHERE
			|				TabularSectionData.Ref = DocumentData.Ref
			|				AND TabularSectionData.LeaseContracts = &Contract)";
			
		EndIf;
		
		If AccessRight("Read", Metadata.Documents.BankAccountReceiptNote) Then

			InitializeAddTextTTDocumentsContractAtTS(TextTTDocumentsContractWH);

			TextTTDocumentsContractWH = TextTTDocumentsContractWH + 
			"FROM
			|	Document.BankAccountReceiptNote AS DocumentData
			|WHERE
			|	DocumentData.Ref IN
			|			(SELECT
			|				TabularSectionData.Ref
			|			FROM
			|				Document.BankAccountReceiptNote.ARAPDetails AS TabularSectionData
			|			WHERE
			|				TabularSectionData.Ref = DocumentData.Ref
			|				AND TabularSectionData.LeaseContracts = &Contract)";
			
		EndIf;
		
		If AccessRight("Read", Metadata.Documents.EntryOfCapitalAssetsBalance2_4) Then
			
			InitializeAddTextTTDocumentsContractAtTS(TextTTDocumentsContractWH);
			
			TextTTDocumentsContractWH = TextTTDocumentsContractWH + 
			"FROM
			|	Document.EntryOfCapitalAssetsBalance2_4 AS DocumentData
			|WHERE
			|	DocumentData.Ref IN
			|			(SELECT
			|				TabularSectionData.Ref
			|			FROM
			|				Document.EntryOfCapitalAssetsBalance2_4.FA AS TabularSectionData
			|			WHERE
			|				TabularSectionData.Ref = DocumentData.Ref
			|				AND TabularSectionData.Contract = &Contract)
			|
			|UNION ALL
			|
			|SELECT
			|	DocumentData.Ref AS Ref
			|FROM
			|	Document.EntryOfCapitalAssetsBalance2_4 AS DocumentData
			|WHERE
			|	DocumentData.Ref IN
			|			(SELECT
			|				TabularSectionData.Ref
			|			FROM
			|				Document.EntryOfCapitalAssetsBalance2_4.LeasedAsset AS TabularSectionData
			|			WHERE
			|				TabularSectionData.Ref = DocumentData.Ref
			|				AND TabularSectionData.Contract = &Contract)";
			
		EndIf;
		
		If TextTTDocumentsContractWH <> "" Then
			
			TextTTDocumentsContractWH = TextTTDocumentsContractWH + "
			|INDEX BY
			|	Ref";
			
			ReplacementText =
			"CASE
			|	WHEN NOT TTDocumentsContractWH.Ref IS NULL
			|		THEN &Contract
			|	ELSE DocumentsRegistryOverridable.Contract
			|END AS Contract";
			QueryText = StrReplace(QueryText, "DocumentsRegistryOverridable.Contract AS Contract", ReplacementText);
			QueryText = StrReplace(QueryText, "DocumentsRegistryOverridable.Contract.* AS Contract", ReplacementText);
		
			QueryText =
				TextTTDocumentsContractWH 
				+ Common.QueryBatchSeparator()
				+ QueryText; 
			
		EndIf;
		
	Else
		
		SearchText =
			"LEFT JOIN TTDocumentsContractWH AS TTDocumentsContractWH
			|		ON TTDocumentsContractWH.Ref = DocumentsRegistryOverridable.Ref";
		QueryText = StrReplace(QueryText, SearchText, "");
		
	EndIf;

	TextOfAdditionalSelectionCondition = "";
	TextAdditionalTables = "";
	
	If FilterBusinessTransactions.FindByValue(Enums.BusinessTransactions.DisposeFixedAssets) <> Undefined Then
		
		TextAdditionalTables = "
		|SELECT
		|	DisposeFixedAssets2_4.Ref AS Ref
		|INTO DisposeFixedAssets2_4
		|FROM
		|	Document.DisposeFixedAssets2_4 AS DisposeFixedAssets2_4
		|WHERE
		|	VALUETYPE(DisposeFixedAssets2_4.DocumentBasis) IN (TYPE(Document.LeaseTermAdjustment))
		|
		|INDEX BY
		|	Ref";
		
		TextOfAdditionalSelectionCondition = "
		|		WHEN VALUETYPE(DocumentsRegistryOverridable.Ref) = TYPE(Document.DisposeFixedAssets2_4)
		|			THEN DocumentsRegistryOverridable.Ref IN (SELECT Ref FROM DisposeFixedAssets2_4)";

	EndIf;
	
	If FilterBusinessTransactions.FindByValue(Enums.BusinessTransactions.CashReceiptFromCustomer) <> Undefined Then
		
		TextAdditionalTables = ?(ValueIsFilled(TextAdditionalTables),
			TextAdditionalTables + Common.QueryBatchSeparator(), TextAdditionalTables) + "
			|SELECT
			|	CounterpartyContracts.Ref AS Ref
			|INTO CounterpartyContracts
			|FROM
			|	Catalog.CounterpartyContracts AS CounterpartyContracts
			|WHERE
			|	CounterpartyContracts.ContractType IN (&ProfitableLeaseContracts)
			|
			|INDEX BY
			|	Ref";
	
		TextOfAdditionalSelectionCondition = TextOfAdditionalSelectionCondition + "
		|		WHEN DocumentsRegistryOverridable.BusinessOperation = VALUE(Enum.BusinessTransactions.CashReceiptFromCustomer)
		|			AND VALUETYPE(DocumentsRegistryOverridable.Ref) IN (
		|				TYPE(Document.BankAccountReceiptNote),
		|				TYPE(Document.CashAccountReceiptNote),
		|				TYPE(Document.ReversingEntry))
		|			THEN DocumentsRegistryOverridable.Contract IN (SELECT Ref FROM CounterpartyContracts)";
		
	EndIf;
	
	If ValueIsFilled(TextOfAdditionalSelectionCondition) Then
	
		TextOfAdditionalSelectionCondition = "
		|	CASE " + TextOfAdditionalSelectionCondition + "
		|		ELSE
		|			TRUE
		|	END";
		QueryText = StrReplace(QueryText, "&AdditionalSelectionCondition", TextOfAdditionalSelectionCondition);

		QueryText = TextAdditionalTables + Common.QueryBatchSeparator() + QueryText;

	Else
		QueryText = StrReplace(QueryText, "&AdditionalSelectionCondition", "TRUE");
	EndIf;
	
	// Document verificationreferences
	DocumentVerificationServer.ModifyDynamicDocumentLogListRequest(QueryText, "DocumentsRegistryOverridable");
	// End Document verificationreferences
	
	ListProperties = Common.DynamicListPropertiesStructure();
	FillPropertyValues(ListProperties, List);
	ListProperties.QueryText = QueryText;
	Common.SetDynamicListProperties(Items.List, ListProperties);
	
EndProcedure

&AtServer
Procedure SetDynamicListSelections_()
	
	CommonClientServer.SetDynamicListFilterItem(
		List,
		"BusinessOperation",
		FilterBusinessTransactions,
		DataCompositionComparisonType.InList,,
		True);

	CommonClientServer.SetDynamicListFilterItem(
		List,
		"RefType",
		FilterDocumentTypes,
		DataCompositionComparisonType.InList,,
		True);
		
	CommonClientServer.SetDynamicListFilterItem(
		List,
		"Organization",
		FilterOrganization,
		DataCompositionComparisonType.Equal,,
		ValueIsFilled(FilterOrganization));
	
	CommonClientServer.SetDynamicListFilterItem(
		List,
		"Partner",
		FilterPartner,
		DataCompositionComparisonType.Equal,,
		ValueIsFilled(FilterPartner));
	
	CommonClientServer.SetDynamicListFilterItem(
		List,
		"Counterparty",
		FilterCounterparty,
		DataCompositionComparisonType.Equal,,
		ValueIsFilled(FilterCounterparty));
	
	CommonClientServer.SetDynamicListFilterItem(
		List,
		"Contract",
		FilterContract,
		DataCompositionComparisonType.Equal,,
		ValueIsFilled(FilterContract));
	
	List.Parameters.SetParameterValue("Contract", FilterContract);
	List.Parameters.SetParameterValue("BeginOfPeriod", ListInterval.StartDate);
	
	List.Parameters.SetParameterValue("EndOfPeriod", 
		?(ValueIsFilled(ListInterval.EndDate),
			EndOfDay(ListInterval.EndDate),
			EndOfDay(Date(3999, 12, 31))));

	If List.Parameters.FindParameterValue(
			New DataCompositionParameter("ProfitableLeaseContracts")) <> Undefined Then
		List.Parameters.SetParameterValue("ProfitableLeaseContracts",
			LeasedAssetAccountingClientServer.TypesOfProfitableLeaseContracts());
	EndIf;
			
	Items.ListSetDateInterval.Check = 
		ValueIsFilled(ListInterval.StartDate) Or ValueIsFilled(ListInterval.EndDate);
	
	// DynamicListsSettings
	OperationsWithDocumentJournals.SetVisibilityOfDefaultUpdateSettingsGroup(ThisObject, "List");
	// End DynamicListsSettings
	
EndProcedure
 
&AtClientAtServerNoContext
Function DefaultFormAssignmentKey()
	
	Return "FADocuments";
	
EndFunction

&AtServer
Procedure WhenSelectionChanges()
	
	ShouldSaveSettings();
	SetRequestTextList();
	SetDynamicListSelections_();
	SetSelectionParameters();
	
EndProcedure

&AtServer
Procedure ConfigureDocumentManagementButtons()
	
	ParametersStructure = TMCommonUse.StructureOfSettingsForDocumentManagementButtons();
	ParametersStructure.Form 												= ThisObject;
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
	ParametersStructure.MaximumNumberOfCommandsPerSubmenu                = 10;
	
	TMCommonUse.ConfigureDocumentManagementButtons(ParametersStructure);

EndProcedure

&AtServer
Procedure SetConditionalAppearance()
	
	ConditionalAppearance.Items.Clear();
	
	StandardSubsystemsServer.SetDateFieldConditionalAppearance(ThisObject, "List.Date", "ListDate");
	
	TMCommonUse.SetConditionalAppearanceOfFieldWithDocumentRegistryKey(
		ThisObject,
		Items.ListCounterparty.Name,
		"List.Counterparty");
	
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

&AtServer
Procedure SelectionOperationTypeSelectionProcessingServer(AddressOfAvailableBusinessTransactionsAndDocuments)
	
	TableBusinessOperationsAndDocuments = GetFromTempStorage(AddressOfAvailableBusinessTransactionsAndDocuments);
	BusinessTransactionsAndDocuments.Load(TableBusinessOperationsAndDocuments);
	
	TMCommonUse.FillInSelectionsAccordingToTableOfBusinessTransactionsAndDocumentTypes(
		TableBusinessOperationsAndDocuments, FilterBusinessTransactions, FilterDocumentTypes);
	
	ConfigureFormUsingSettingsForBusinessOperationsAndDocuments();
	
	WhenSelectionChanges();
	
	TMCommonUse.FormInscriptionSelection(Items.HelpTextFilter.Title,
		BusinessTransactionsAndDocuments, FilterDocumentTypes, FilterBusinessTransactions);
	
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

&AtServer
Procedure SetSelectionParameters()
	
	ChoiceParameterLinks = New Array;
	
	If Not FilterOrganization.IsEmpty() Then
		ChoiceParameterLink = New ChoiceParameterLink("Filter.Organization", "FilterOrganization", LinkedValueChangeMode.Clear);
		ChoiceParameterLinks.Add(ChoiceParameterLink);
	EndIf;
	
	If Not FilterCounterparty.IsEmpty() Then
		ChoiceParameterLink = New ChoiceParameterLink("Filter.Counterparty", "FilterCounterparty", LinkedValueChangeMode.Clear);
		ChoiceParameterLinks.Add(ChoiceParameterLink);
	EndIf;
	
	Items.FilterContract.ChoiceParameterLinks = New FixedArray(ChoiceParameterLinks);
	
EndProcedure

&AtClient
Function SelectionsForCreatingDocument()
	
	StructureSelections = New Structure;
	
	If ValueIsFilled(FilterOrganization) Then
		StructureSelections.Insert("Organization", FilterOrganization);
	EndIf;
	If ValueIsFilled(FilterPartner) Then
		StructureSelections.Insert("Partner", FilterPartner);
	EndIf;
	If ValueIsFilled(FilterCounterparty) Then
		StructureSelections.Insert("Counterparty", FilterCounterparty);
	EndIf;
	If ValueIsFilled(FilterContract) Then
		StructureSelections.Insert("Contract", FilterContract);
	EndIf;
	
	Return StructureSelections;
	
EndFunction

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
	TMCommonUseClient.ProcessBarcodes(Data.Barcode, BarcodeData, ThisObject, "List");
	
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
