
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
	
	URL = "e1cib/app/DataProcessor.LogOfProductionDocuments";
	
	RestoreSettings(Parameters);
	
	VTBusinessTransactionsAndDocumentTypes = TMCommonUse.AvailableBusinessTransactionsAndDocuments(DescriptionOfOperationsAndDocumentTypes(),
		FilterBusinessTransactions, FilterDocumentTypes, SettingsKey);
	VTBusinessTransactionsAndDocumentTypes.Sort("Order");
	
	BusinessTransactionsAndDocuments.Load(VTBusinessTransactionsAndDocumentTypes);
	
	RestrictionByCompanyIsUsed = AccessManagement.HasTableRestrictionByAccessKind(
		"InformationRegister.DocumentsRegistry", "Companies", "PartnerGroups,Companies,Departments,Warehouses");
	
	RestrictionByWarehouseIsUsed = AccessManagement.HasTableRestrictionByAccessKind(
		"InformationRegister.DocumentsRegistry", "Warehouses", "PartnerGroups,Companies,Departments,Warehouses");
	
	DivisionRestrictionIsUsed = AccessManagement.HasTableRestrictionByAccessKind(
		"InformationRegister.DocumentsRegistry", "Departments", "PartnerGroups,Companies,Departments,Warehouses");
	
	ConfigureFormForSelectedOperationsAndDocuments(VTBusinessTransactionsAndDocumentTypes);
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject, Items.GlobalCommandsGroup);
	// End IntegrationWith1CDocumentManagementSubsystem


	// Document verificationreferences
	ListProperties = Common.DynamicListPropertiesStructure();
	FillPropertyValues(ListProperties, ListProductionDocuments);
	DocumentVerificationServer.ModifyDynamicDocumentLogListRequest(ListProperties.QueryText, "DocumentsRegistryOverridable");
	Common.SetDynamicListProperties(Items.ListProductionDocuments, ListProperties);
	// End Document verificationreferences
	
	DocumentTypesUsed = VTBusinessTransactionsAndDocumentTypes.UnloadColumn("DocumentType");
	DocumentTypesUsed.Add(Type("DocumentRef.ReversingEntry"));
	
	// StandardSubsystems.AttachableCommands
	PlacementParameters = AttachableCommands.PlacementParameters();
	PlacementParameters.Sources = New TypeDescription(DocumentTypesUsed);
	PlacementParameters.CommandBar = Items.ListProductionDocumentsCommandBar;
	AttachableCommands.OnCreateAtServer(ThisObject, PlacementParameters);
	// End StandardSubsystems.AttachableCommands
	
	AdditionalParameters = New Structure("LocationOfLocalValidationData", Items.ReglGroupVerification);
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing, AdditionalParameters);
	
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
	
	
	If EventName = "Write_InternalAcceptanceCertificate"
		Or EventName = "Write_RetirementOfRNPTMaterialsFromManufacturing"
		Or EventName = "Write_WorkOutput"
		Or EventName = "Write_MovementOfProductsAndMaterials"
		Or EventName = "Write_TransferOfProductBatchIDMaterialsToManufacturedProducts"
		Or EventName = "Write_BackflushProduction"
		Or EventName = "Write_RecyclableWasteAllocation"
		Or EventName = "Write_ProductionCostAllocation"
		Or EventName = "Write_AllocationOfOtherCosts"
		Or EventName = "Write_ReversingEntry"
		Or EventName = "Write_ProductionStages"
		Or EventName = "Conducting_Storno" Then
		
		// DynamicListsSettings
		UpdateListOfDocumentsEventNotificationProcessing("ListProductionDocuments", Parameter);
		// End DynamicListsSettings
		
		UpdateHyperlinkToLayout();
		ConnectHyperlinkWaitingHandlerToLayout();
		
	ElsIf EventName = "Write_OrderOfMaterialsForProduction"
		Or EventName = "Write_ProductionStages"
		Then
		
		UpdateHyperlinkToLayout();
		ConnectHyperlinkWaitingHandlerToLayout();
		
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure OrganizationOnChange(Item)
	
	OrganizationWhenChangedOnServer();
	ConnectHyperlinkWaitingHandlerToLayout();
	
EndProcedure

&AtClient
Procedure DepartmentOnChange(Item)
	
	DivisionWhenChangedOnServer();
	ConnectHyperlinkWaitingHandlerToLayout();
	
EndProcedure

&AtClient
Procedure ManagerOnChange(Item)
	
	CommonClientServer.SetDynamicListFilterItem(ListProductionDocuments,
		"Manager",
		Manager,
		DataCompositionComparisonType.Equal,,
		ValueIsFilled(Manager));
	
	UpdateHyperlinkToLayout();
	ConnectHyperlinkWaitingHandlerToLayout();
	
	// DynamicListsSettings
	OperationsWithDocumentJournalsClient.SetVisibilityOfDefaultUpdateSettingsGroup(ThisObject, "ListProductionDocuments");
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
		
		AddressOfAvailableBusinessTransactionsAndDocuments = ValueSelected;
		
		SelectionOperationTypeSelectionProcessingServer(AddressOfAvailableBusinessTransactionsAndDocuments);
		ConnectHyperlinkWaitingHandlerToLayout();
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ToRegisterURLProcessing(Item, FormattedStringURL, StandardProcessing)
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.TimeMeasurement(
		"DataProcessor.LogOfProductionDocuments.Form.DocumentsList.Event.ToRegisterURLProcessing");
	
	StandardProcessing = False;
	
	FormParameters = New Structure;
	QuickFilterStructure = New Structure;
	QuickFilterStructure.Insert("Organization",		Organization);
	QuickFilterStructure.Insert("Department",	Department);
	QuickFilterStructure.Insert("Manager",		Manager);
	QuickFilterStructure.Insert("FilterDocumentTypes",			FilterDocumentTypes);
	QuickFilterStructure.Insert("FilterBusinessTransactions",	FilterBusinessTransactions);
	FormParameters.Insert("QuickFilterStructure", QuickFilterStructure);
	
	OpenForm(FormattedStringURL,FormParameters);
	
EndProcedure

&AtClient
Procedure SeeAlsoInProgressURLProcessing(Item, FormattedStringURL, StandardProcessing)
	
	StandardProcessing = False;
	
	FormParameters = New Structure;
	QuickFilterStructure = New Structure;
	
	If ValueIsFilled(Organization) Then
		QuickFilterStructure.Insert("Organization", Organization);
	EndIf;
	
	If ValueIsFilled(Department) Then
		QuickFilterStructure.Insert("Department", Department);
	EndIf;
	
	//If the value is filled in(Manager) Then
	//	The structure of the quick selection.Insert ("Responsible", Manager);
	//Endings;
	
	FormParameters.Insert("QuickFilterStructure", QuickFilterStructure);
	
	OpenForm(FormattedStringURL, FormParameters,ThisForm, ThisForm.UUID);
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersListRegistered

&AtClient
Procedure ListProductionDocumentsBeforeAddRow(Item, Cancel, Copy, Parent, Var_Group, Parameter)
	
	Cancel = True;
	If Items.CreateGroupGenerated.ChildItems.Count() <> 0 Then 
		If Copy Then
			CurrentData = Items.ListProductionDocuments.CurrentData;
			If CurrentData = Undefined Then
				Return;
			EndIf;
			If Not TypeOf(CurrentData.Ref) = Type("DocumentRef.ProductionCostAllocation")
				And Not TypeOf(CurrentData.Ref) = Type("DocumentRef.ProductionStage2_2")
				And Not TypeOf(CurrentData.Ref) = Type("DocumentRef.AllocationOfOtherCosts") Then
				TMCommonUseClient.CopyItem(Item);
			Else
				MessageText = NStr("vi = 'Sao chép chứng từ ""Phân bổ chi phí nguyên vật liệu và nhân công"", ""Phân bổ chi phí cho giá thành"", ""Công đoạn sản xuất"" không được phép.';
									|ru = 'Копирование документов ""Распределение материалов и работ"", ""Распределение расходов на себестоимость продукции"", ""Этап производства"" не допускается.';
									|en = 'Cannot copy documents ""Material and labor allocation"", ""Allocation of expenses to product cost"", ""Production stage"".'; fa = 'Cannot copy documents ""Material and labor allocation"", ""Allocation of expenses to product cost"", ""Production stage"".';
									|it = 'Copia di documenti ""Allocazione di materiali e lavori"", ""Allocazione delle spese sul costo di produzione"", ""Fase di produzione"" non è consentita.';
									|pl = 'Kopiowanie dokumentów ""Podział materiałów i prac"", ""Podział rozchodów na koszty własne produkcji"", ""Etap produkcji"" nie jest dozwolone.';
									|tr = '""Malzeme ve işçilik tahsisatı"", ""Ürün Maliyetine Gider Dağıtımı"", ""Üretim Aşaması"" belgelerinin kopyalanmasına izin verilmemektedir.'");
				CommonClientServer.MessageToUser(MessageText);
			EndIf;
		ElsIf FilterDocumentTypes.Count() = 1 And FilterBusinessTransactions.Count() = 1 Then 
			TeamStructure_ = New Structure("Name", Items.CreateGroupGenerated.ChildItems[0].Name);
			Attachable_CreateDocument(TeamStructure_);
		Else
			Attachable_CreateDocumentViaSelectionForm(Undefined);
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure ListProductionDocumentsOnActivateRow(Item)
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

&AtClient
Procedure ListProductionDocumentsSelection(Item, RowSelected, Field, StandardProcessing)
	
	StandardProcessing = False;
	
	TMCommonUseClient.ChangeElement(Item);
	
	
EndProcedure

&AtClient
Procedure ListProductionDocumentsBeforeRowChange(Item, Cancel)
	
	Cancel = True;
	TMCommonUseClient.ChangeElement(Item);
	
EndProcedure

&AtClient
Procedure ListProductionDocumentsBeforeDeleteRow(Item, Cancel)
	
	ClearMessages();
	
	Cancel = True;
	List = Items.ListProductionDocuments;
	ProductionManagementClient.CheckRemoveIncompleteStageChainsFromList(List);
	If List.SelectedRows.Count() > 0 Then
		Notification = New CallbackDescription(
			"ListProductionDocumentsToMarkDeletionEnd",
			ThisObject);
		TMCommonUseClient.SetDeletionMark(List, Title, Notification);
	EndIf;
	
EndProcedure

&AtClient
Procedure ListCopy(Command)
	
	CurrentData = Items.ListProductionDocuments.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	If Not TypeOf(CurrentData.Ref) = Type("DocumentRef.ProductionCostAllocation")
		And Not TypeOf(CurrentData.Ref) = Type("DocumentRef.ProductionStage2_2")
		And Not TypeOf(CurrentData.Ref) = Type("DocumentRef.AllocationOfOtherCosts") Then
		TMCommonUseClient.CopyItem(Items.ListProductionDocuments);
	Else
		MessageText = NStr("vi = 'Sao chép chứng từ ""Phân bổ chi phí nguyên vật liệu và nhân công"", ""Phân bổ chi phí cho giá thành"", ""Công đoạn sản xuất"" không được phép.';
							|ru = 'Копирование документов ""Распределение материалов и работ"", ""Распределение расходов на себестоимость продукции"", ""Этап производства"" не допускается.';
							|en = 'Cannot copy documents ""Material and labor allocation"", ""Allocation of expenses to product cost"", ""Production stage"".'; fa = 'Cannot copy documents ""Material and labor allocation"", ""Allocation of expenses to product cost"", ""Production stage"".';
							|it = 'Copia di documenti ""Allocazione di materiali e lavori"", ""Allocazione delle spese sul costo di produzione"", ""Fase di produzione"" non è consentita.';
							|pl = 'Kopiowanie dokumentów ""Podział materiałów i prac"", ""Podział rozchodów na koszty własne produkcji"", ""Etap produkcji"" nie jest dozwolone.';
							|tr = '""Malzeme ve işçilik tahsisatı"", ""Ürün Maliyetine Gider Dağıtımı"", ""Üretim Aşaması"" belgelerinin kopyalanmasına izin verilmemektedir.'");
		CommonClientServer.MessageToUser(MessageText);
	EndIf;
	
EndProcedure

&AtClient
Procedure ListChange(Command)
	
	TMCommonUseClient.ChangeElement(Items.ListProductionDocuments);
	
EndProcedure

&AtClient
Procedure ListSetDeletionMark(Command)
	
	List = Items.ListProductionDocuments;
	ProductionManagementClient.CheckRemoveIncompleteStageChainsFromList(List);
	If List.SelectedRows.Count() > 0 Then
		Notification = New CallbackDescription(
			"ListProductionDocumentsToMarkDeletionEnd",
			ThisObject);
		TMCommonUseClient.SetDeletionMark(List, Title, Notification,
			OperationsWithDocumentJournalsClient.ParametersForUpdatingDocumentList(ThisObject,
			"ListProductionDocuments"));
	EndIf;
	
EndProcedure

&AtServer
Procedure ListProductionDocumentsOnUpdateUserSettingSetAtServer(Item, StandardProcessing)
	
	// DynamicListsSettings
	OperationsWithDocumentJournals.SetVisibilityOfDefaultUpdateSettingsGroup(ThisObject, "ListProductionDocuments");
	// End DynamicListsSettings
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

#Region CreateButton

&AtClient
Procedure Attachable_CreateDocument(Command)
	
	FilterStructure1 = New Structure;
	FilterStructure1.Insert("Organization",Organization);
	FilterStructure1.Insert("Department",Department);
	TMCommonUseClient.CreateDocumentUsingCommand(Command.Name, FilterStructure1);
	
EndProcedure

&AtClient
Procedure Attachable_CreateDocumentViaSelectionForm(Command)
	FormKey = DefaultFormAssignmentKey();
	AddressBusinessTransactionsAndDocuments = PlaceBusinessTransactionsAndDocumentsInTemporaryStorage();
	FilterStructure1 = New Structure;
	FilterStructure1.Insert("Organization",Organization);
	FilterStructure1.Insert("Department",Department);
	TMCommonUseClient.CreateDocumentViaSelectionForm(AddressBusinessTransactionsAndDocuments,
		FormKey, PurposeUseKey, FilterStructure1);
EndProcedure

#EndRegion

&AtClient
Procedure ListUndoPosting(Command)
	
	TMCommonUseClient.UndoPosting(Items.ListProductionDocuments, Title,
		OperationsWithDocumentJournalsClient.ParametersForUpdatingDocumentList(ThisObject, "ListProductionDocuments"));
	ListUndoPostingServer();
	ConnectHyperlinkWaitingHandlerToLayout();
	
EndProcedure

&AtClient
Procedure ListPost(Command)
	
	TMCommonUseClient.PostDocuments(Items.ListProductionDocuments, Title,
		OperationsWithDocumentJournalsClient.ParametersForUpdatingDocumentList(ThisObject, "ListProductionDocuments"));
	ListPostServer();
	ConnectHyperlinkWaitingHandlerToLayout();
	
EndProcedure

// StandardSubsystems.AttachableCommands
&AtClient
Procedure Attachable_ExecuteCommand(Command)
	AttachableCommandsClient.ExecuteCommand(ThisObject, Command, Items.ListProductionDocuments);
EndProcedure

&AtServer
Procedure Attachable_ExecuteCommandAtServer(Context, Result) Export
	AttachableCommands.ExecuteCommand(ThisObject, Context, Items.ListProductionDocuments, Result);
EndProcedure

&AtClient
Procedure Attachable_UpdateCommands()
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Items.ListProductionDocuments);
EndProcedure
// End StandardSubsystems.AttachableCommands

// IntegrationWith1CDocumentManagementSubsystem
&AtClient
Procedure Attachable_ExecuteIntegrationCommand(Command)
	
	IntegrationWith1CDocumentManagementCoreClient.ExecutePlugInIntegrationCommand(Command, ThisObject, Items.ListProductionDocuments);
	
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

// Parameters:
// 	Command - FormCommand - form command
&AtClient
Procedure Attachable_SetStatus(Command)
	
	TMCommonUseClient.SetStatus(Command.Name, CorrespondenceOfCommandsToStatuses,
		Items.ListProductionDocuments, OperationsWithDocumentJournalsClient.ParametersForUpdatingDocumentList(
		ThisObject, "ListProductionDocuments"));
	
EndProcedure

&AtClient
Procedure DocumentsListRefresh(Command)
	
	// DynamicListsSettings
	UpdateDocumentListDataWithTimeMeasurement("ListProductionDocuments");
	// End DynamicListsSettings
	
EndProcedure

#EndRegion

#Region Private

#Region ServiceEventHandlersForFormHeaderElements

&AtServer
Procedure OrganizationWhenChangedOnServer()
	
	SetSelectionByOrganization();
	SetSelectionAdditionalEntry();
	
	If ValueIsFilled(Organization) Then
		Items.ListProductionDocumentsOrganization.Visible = False;
	Else
		Items.ListProductionDocumentsOrganization.Visible = True;
	EndIf;
	
	UpdateHyperlinkToLayout();
	
EndProcedure

&AtServer
Procedure DivisionWhenChangedOnServer()
	
	CommonClientServer.SetDynamicListFilterItem(ListProductionDocuments,
		"Department",
		Department,
		DataCompositionComparisonType.Equal,,
		ValueIsFilled(Department));
	SetSelectionAdditionalEntry();
	
	If ValueIsFilled(Department) Then
		Items.ListProductionDocumentsDepartment.Visible = False;
	Else
		Items.ListProductionDocumentsDepartment.Visible = True;
	EndIf;
	
	UpdateHyperlinkToLayout();
	
	// DynamicListsSettings
	OperationsWithDocumentJournals.SetVisibilityOfDefaultUpdateSettingsGroup(ThisObject, "ListProductionDocuments");
	// End DynamicListsSettings
	
EndProcedure

#EndRegion

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
	BarcodeData = BarcodeDataOfPrintedForm(Data.Barcode, "ListProductionDocuments");
	TMCommonUseClient.ProcessBarcodes(Data.Barcode, BarcodeData, ThisForm, "ListProductionDocuments");
	
EndProcedure

#EndRegion

&AtClient
Procedure ListProductionDocumentsToMarkDeletionEnd(Result, AdditionalParameters) Export
	
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
	
	StandardSubsystemsServer.SetDateFieldConditionalAppearance(ThisObject, "ListProductionDocuments.Date", Items.ListProductionDocumentsDate.Name);
	
	//
	
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ListProductionDocumentsStatus.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ThereAreDocumentsUsingAStatus");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;

	Item.Appearance.SetParameterValue("Visible", False);
	
EndProcedure

&AtClientAtServerNoContext
Function DefaultFormAssignmentKey()
	
	Return "ProductionDocumentsAll";
	
EndFunction

&AtServer
Procedure RestoreSettings(Var_Parameters)
	
	ListOfDocumentsAutoUpdateMode = True;
	If Var_Parameters.Property("ListFormSelections") Then
		FillPropertyValues(ThisObject, FormSettings(Var_Parameters.ListFormSelections));
	ElsIf Var_Parameters.Property("QuickFilterStructure") Then
		FillPropertyValues(ThisObject, FormSettings(Var_Parameters.QuickFilterStructure));
	ElsIf Var_Parameters.Property("Filter")
		And ValueIsFilled(Var_Parameters.Filter) Then
		
		FormSettings = FormSettings(Var_Parameters.Filter);
		FillPropertyValues(ThisObject, FormSettings);
		
		If TypeOf(FormSettings.Organization) = Type("Array")
			And FormSettings.Organization.Count() = 1 Then
			Organization = FormSettings.Organization[0];
		EndIf;
		
	Else
		
		SettingsFromStorage = Common.CommonSettingsStorageLoad(
			"DataProcessor.LogOfProductionDocuments.Form.DocumentsList", PurposeUseKey);
		
		If TypeOf(SettingsFromStorage) = Type("Structure") Then
			FillPropertyValues(ThisObject, FormSettings(SettingsFromStorage));
			If SettingsFromStorage.Property("ListOfDocumentsAutoUpdateMode") Then
				ListOfDocumentsAutoUpdateMode = SettingsFromStorage.ListOfDocumentsAutoUpdateMode;
			EndIf;
		EndIf;
		
	EndIf;
	
EndProcedure

&AtServer
Procedure ShouldSaveSettings()
	
	Common.CommonSettingsStorageSave("DataProcessor.LogOfProductionDocuments.Form.DocumentsList",
		PurposeUseKey, FormSettings(ThisForm));
	
EndProcedure

&AtServer
Function FormSettings(SettingsSource)
	
	AttributesToSaveNames =
		"Organization,
		|Department,
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
Function DescriptionOfOperationsAndDocumentTypes()
	
	VTBusinessTransactionsAndDocumentTypes = BusinessTransactionsAndDocuments.Unload();
	VTBusinessTransactionsAndDocumentTypes.Clear();
	
	#Region InternalAcceptanceCertificate
	
	LineActOfInternalWorks			= VTBusinessTransactionsAndDocumentTypes.Add();
	String								= LineActOfInternalWorks;
	String.BusinessOperation		= Enums.BusinessTransactions.WorkAcceptanceAndTransferBetweenBusinessUnits;
	String.PurposeUseKey	= "ProductionDocumentsAll";
	String.WorkplaceTitle		= NStr("vi = 'Biên bản nghiệm thu công việc nội bộ';
										|ru = 'Акты выполненных внутренних работ';
										|en = 'Internal works acceptance'; fa = 'پذیرش کارهای داخلی';
										|it = 'Verbali di consegna dei lavori interni';
										|pl = 'Protokoły odbioru';
										|tr = 'Gerçekleştirilen dahili iş tutanakları'");
	String.DocumentType					= Type("DocumentRef.InternalAcceptanceCertificate");
	String.FullDocumentName			= Metadata.Documents.InternalAcceptanceCertificate.FullName();
	String.StatusesAreUsed			= GetFunctionalOption("UseStatusesOfInternalWorksAcceptance");
	String.AddButtonCreate		= True;
	String.Order						= 10;
	
	If GetFunctionalOption("UseBranchOfficesWithSeparateBalanceSheets") Then
		String								= VTBusinessTransactionsAndDocumentTypes.Add();
		FillPropertyValues(String, LineActOfInternalWorks);
		String.BusinessOperation		= Enums.BusinessTransactions.WorkAcceptanceAndTransferBetweenBranchOffices;
	EndIf;
	
	#EndRegion
	
	#Region MovementOfProductsAndMaterials
	
	AvailableDocumentOperations = Documents.MovementOfProductsAndMaterials.TransactionList();
	
	DefaultProperties = New Structure(
		"PurposeUseKey,WorkplaceTitle,DocumentType,FullDocumentName,StatusesAreUsed,
		|AddButtonCreate,HyperlinkCalculationManagerForRegistration, Order");
	
	DefaultProperties.PurposeUseKey           = "ProductionDocumentsAll";
	DefaultProperties.WorkplaceTitle                = NStr("vi = 'Biến động sản phẩm và nguyên vật liệu';
															|ru = 'Движение продукции и материалов';
															|en = 'Movement of products and materials'; fa = 'جابه‌جایی محصولات و مواد';
															|it = 'Movimentazione di prodotti e materiali';
															|pl = 'Obrót produkcji i materiałów';
															|tr = 'İmal edilen ürün ve malzeme hareketi'");
	DefaultProperties.DocumentType                          = Type("DocumentRef.MovementOfProductsAndMaterials");
	DefaultProperties.FullDocumentName                    = Metadata.Documents.MovementOfProductsAndMaterials.FullName();
	DefaultProperties.StatusesAreUsed                   = GetFunctionalOption("UseStatusesOfProductsAndMaterialsMovements");
	DefaultProperties.AddButtonCreate                 = True;
	DefaultProperties.Order                               = 20;
	DefaultProperties.HyperlinkCalculationManagerForRegistration = "Document.MovementOfProductsAndMaterials";
	
	CurrentOperation = Enums.BusinessTransactions.TransferOfMaterialsToStoreroom;
	If AvailableDocumentOperations.FindByValue(CurrentOperation) <> Undefined Then
		
		String								= VTBusinessTransactionsAndDocumentTypes.Add();
		String.BusinessOperation		= CurrentOperation;
		FillPropertyValues(String, DefaultProperties);
		
	EndIf;
	
	CurrentOperation = Enums.BusinessTransactions.MaterialTransferToProduction;
	If AvailableDocumentOperations.FindByValue(CurrentOperation) <> Undefined Then
		
		String								= VTBusinessTransactionsAndDocumentTypes.Add();
		String.BusinessOperation		= CurrentOperation;
		FillPropertyValues(String, DefaultProperties);
		
	EndIf;
	
	CurrentOperation = Enums.BusinessTransactions.ReturnOfMaterialsFromProduction;
	If AvailableDocumentOperations.FindByValue(CurrentOperation) <> Undefined Then
		
		String								= VTBusinessTransactionsAndDocumentTypes.Add();
		String.BusinessOperation		= CurrentOperation;
		FillPropertyValues(String, DefaultProperties);
		
	EndIf;
	
	CurrentOperation = Enums.BusinessTransactions.TransferOfProductsFromProduction;
	If AvailableDocumentOperations.FindByValue(CurrentOperation) <> Undefined Then
		
		String								= VTBusinessTransactionsAndDocumentTypes.Add();
		String.BusinessOperation		= CurrentOperation;
		FillPropertyValues(String, DefaultProperties);
		
	EndIf;
	
	CurrentOperation = Enums.BusinessTransactions.ReturnOfMaterialsFromStoreroom;
	If AvailableDocumentOperations.FindByValue(CurrentOperation) <> Undefined Then
		
		String								= VTBusinessTransactionsAndDocumentTypes.Add();
		String.BusinessOperation		= CurrentOperation;
		FillPropertyValues(String, DefaultProperties);
		
	EndIf;
	
	CurrentOperation = Enums.BusinessTransactions.TransferOfProductsFromStoreroom;
	If AvailableDocumentOperations.FindByValue(CurrentOperation) <> Undefined Then
		
		String								= VTBusinessTransactionsAndDocumentTypes.Add();
		String.BusinessOperation		= CurrentOperation;
		FillPropertyValues(String, DefaultProperties);
		
	EndIf;
	
	CurrentOperation = Enums.BusinessTransactions.TransferOfSemiFinishedProducts;
	If AvailableDocumentOperations.FindByValue(CurrentOperation) <> Undefined Then
		
		String								= VTBusinessTransactionsAndDocumentTypes.Add();
		String.BusinessOperation		= CurrentOperation;
		FillPropertyValues(String, DefaultProperties);
		String.Order						= 25;
		String.HyperlinkCalculationManagerForRegistration = "";
		
	EndIf;
	
	CurrentOperation = Enums.BusinessTransactions.TransferOfSemiFinishedProductsBetweenBranchOffices;
	If AvailableDocumentOperations.FindByValue(CurrentOperation) <> Undefined Then
		
		String								= VTBusinessTransactionsAndDocumentTypes.Add();
		String.BusinessOperation		= CurrentOperation;
		FillPropertyValues(String, DefaultProperties);
		String.Order						= 25;
		String.HyperlinkCalculationManagerForRegistration = "";
		
	EndIf;
	
	#EndRegion
	
	#Region BackflushProduction
	
	StringProductionWithoutOrder			= VTBusinessTransactionsAndDocumentTypes.Add();
	String								= StringProductionWithoutOrder;
	String.BusinessOperation		= Enums.BusinessTransactions.ProductsRelease;
	String.PurposeUseKey	= "ProductionDocumentsAll";
	String.WorkplaceTitle		= NStr("vi = 'Sản xuất không theo đơn đặt hàng';
										|ru = 'Производство без заказа';
										|en = 'Backflush production'; fa = 'تولید با کسر خودکار مواد';
										|it = 'Produzione senza ordine';
										|pl = 'Produkcja bez zamówień';
										|tr = 'Geriye dönük üretim'");
	String.DocumentType					= Type("DocumentRef.BackflushProduction");
	String.FullDocumentName			= Metadata.Documents.BackflushProduction.FullName();
	String.StatusesAreUsed			= False;
	String.AddButtonCreate		= True;
	String.Order						= 30;
	String.HyperlinkCalculationManagerForRegistration = "DataProcessor.RegisterBackflushProduction";
	
	String								= VTBusinessTransactionsAndDocumentTypes.Add();
	FillPropertyValues(String, StringProductionWithoutOrder);
	String.BusinessOperation		= Enums.BusinessTransactions.ExpensingToProductionLots;
	String.AddButtonCreate		= False;
	
	#EndRegion
	
	#Region RecyclableWasteAllocation
	
	DistributionOfReturnableWaste = VTBusinessTransactionsAndDocumentTypes.Add();
	String								= DistributionOfReturnableWaste;
	String.BusinessOperation		= Enums.BusinessTransactions.ProductsRelease;
	String.PurposeUseKey	= "ProductionDocumentsAll";
	String.WorkplaceTitle		= NStr("vi = 'Phân bổ phế liệu thu hồi';
										|ru = 'Распределение возвратных отходов';
										|en = 'Recyclable waste allocation'; fa = 'تسهیم ضایعات قابل بازیافت';
										|it = 'Ripartizione degli scarti riciclabili';
										|pl = 'Przydział odpadów zwrotnych';
										|tr = 'Geri dönüştürülebilir atıkların dağıtımı'");
	String.DocumentType 				= Type("DocumentRef.RecyclableWasteAllocation");
	String.FullDocumentName			= Metadata.Documents.RecyclableWasteAllocation.FullName();
	String.StatusesAreUsed			= False;
	String.AddButtonCreate		= True;
	String.Order						= 40;
	String.HyperlinkCalculationManagerForRegistration = "DataProcessor.RegisterBackflushProduction";
	
	#EndRegion
	
	#Region ProductionCostAllocation
	
	LineAllocationOfProductionCosts	= VTBusinessTransactionsAndDocumentTypes.Add();
	String										= LineAllocationOfProductionCosts;
	String.BusinessOperation				= Enums.BusinessTransactions.ExpensingToProductionLots;
	String.PurposeUseKey			= "ProductionDocumentsAll";
	String.WorkplaceTitle				= NStr("vi = 'Phân bổ chi phí nguyên vật liệu và nhân công';
												|ru = 'Распределение материалов и работ';
												|en = 'Material and labor allocation'; fa = 'تسهیم مواد و دستمزد';
												|it = 'Distribuzione di materiali e lavori';
												|pl = 'Rozdział materiałów i prac';
												|tr = 'Malzeme ve iş dağıtımı'");
	String.DocumentType 						= Type("DocumentRef.ProductionCostAllocation");
	String.FullDocumentName					= Metadata.Documents.ProductionCostAllocation.FullName();
	String.StatusesAreUsed					= False;
	String.AddButtonCreate				= False;
	String.Order								= 50;
	String.HyperlinkCalculationManagerForRegistration = "Document.ProductionCostAllocation";
	
	#EndRegion
	
	#Region AllocationOfOtherCosts
	
	LineAllocationOfOtherCosts		= VTBusinessTransactionsAndDocumentTypes.Add();
	String								= LineAllocationOfOtherCosts;
	String.BusinessOperation		= Enums.BusinessTransactions.ExpensingToProductionLots;
	String.PurposeUseKey	= "ProductionDocumentsAll";
	String.WorkplaceTitle		= NStr("vi = 'Phân bổ các chi phí khác';
										|ru = 'Распределение прочих расходов';
										|en = 'Other expense allocation'; fa = 'Other expense allocation';
										|it = 'Allocazione di altre spese';
										|pl = 'Podział innych rozchodów';
										|tr = 'Diğer giderlerin dağıtımı'");
	String.DocumentType 				= Type("DocumentRef.AllocationOfOtherCosts");
	String.FullDocumentName			= Metadata.Documents.AllocationOfOtherCosts.FullName();
	String.StatusesAreUsed			= False;
	String.AddButtonCreate		= False;
	String.Order						= 60;
	String.HyperlinkCalculationManagerForRegistration = "Document.AllocationOfOtherCosts";
	
	#EndRegion
	#Region ProductionStage
	
	FirstStageOfProduction_ = VTBusinessTransactionsAndDocumentTypes.Add();
	String								= FirstStageOfProduction_;
	String.BusinessOperation		= Enums.BusinessTransactions.ProductsRelease;
	String.PurposeUseKey	= "ProductionDocumentsAll";
	String.WorkplaceTitle		= NStr("vi = 'Công đoạn sản xuất';
										|ru = 'Этапы производства';
										|en = 'Production stages'; fa = 'مراحل تولید';
										|it = 'Fasi di produzione';
										|pl = 'Etapy produkcji';
										|tr = 'Üretim aşamaları'");
	String.AccessRightInsert		= False;
	String.DocumentType					= Type("DocumentRef.ProductionStage2_2");
	String.FullDocumentName			= Metadata.Documents.ProductionStage2_2.FullName();
	String.StatusesAreUsed			= True;
	String.AddButtonCreate		= False;
	String.Order						= 70;
	
	String								= VTBusinessTransactionsAndDocumentTypes.Add();
	FillPropertyValues(String, FirstStageOfProduction_);
	String.BusinessOperation		= Enums.BusinessTransactions.ExpensingToProductionLots;
	String.AddButtonCreate		= False;
	
	String								= VTBusinessTransactionsAndDocumentTypes.Add();
	FillPropertyValues(String, FirstStageOfProduction_);
	String.BusinessOperation		= Enums.BusinessTransactions.ReturnOfMaterialsFromProduction;
	String.AddButtonCreate		= False;
	
	#EndRegion
	#Region WorkOutput
	
	EmployeeDevelopmentLine					= VTBusinessTransactionsAndDocumentTypes.Add();
	String										= EmployeeDevelopmentLine;
	String.BusinessOperation				= Enums.BusinessTransactions.PieceworkRegistration;
	String.PurposeUseKey			= "ProductionDocumentsAll";
	String.WorkplaceTitle				= NStr("vi = 'Sản lượng nhân viên';
												|ru = 'Выработка сотрудников';
												|en = 'Timesheets charge'; fa = 'محاسبه برگه‌های کارکرد';
												|it = 'Produttività dei dipendenti';
												|pl = 'Ustawienia wydajności pracowników';
												|tr = 'Zaman çizelgesi bazlı ücretlendirme'");
	String.DocumentType 						= Type("DocumentRef.WorkOutput");
	String.FullDocumentName					= Metadata.Documents.WorkOutput.FullName();
	String.StatusesAreUsed					= False;
	String.AddButtonCreate				= True;
	String.Order								= 80;
	String.HyperlinkCalculationManagerForRegistration = "Document.WorkOutput";
	
	#EndRegion
	
	
	Return VTBusinessTransactionsAndDocumentTypes;
	
EndFunction

&AtServer
Procedure CalculateNeedToDisplayColumns()
	
	InvoicesWithStatuses = BusinessTransactionsAndDocuments.FindRows(New Structure("Filter, StatusesAreUsed", True, True));
	
	ThereAreDocumentsUsingAStatus = InvoicesWithStatuses.Count() <> 0;
	
EndProcedure

&AtServer
Procedure ConfigureFormForSelectedOperationsAndDocuments(VTBusinessTransactionsAndDocumentTypes)
	
	WorkplaceData = TMCommonUse.WorkplaceData(VTBusinessTransactionsAndDocumentTypes,
		DefaultFormAssignmentKey(), NStr("vi = 'Chứng từ sản xuất (tất cả)';
										|ru = 'Документы производства (все)';
										|en = 'Production documents (all)'; fa = 'اسناد تولید (همه)';
										|it = 'Documenti della produzione (tutti)';
										|pl = 'Dokumenty produkcyjne (wszystkie)';
										|tr = 'Üretim belgeleri (tümü)'"));
	
	Title = WorkplaceData.WorkplaceTitle;
	
	CalculateNeedToDisplayColumns();
	SetDynamicListSelections();
	UpdateHyperlinkToLayout();
	SetVisibilityAvailability();
	
	TMCommonUse.ReplaceLinkFieldWithExpressByDocumentTypeConstruct(Items.ListProductionDocuments,
		BusinessTransactionsAndDocuments);
	
	TMCommonUse.FormInscriptionSelection(Items.HelpTextFilter.Title,
		BusinessTransactionsAndDocuments, FilterDocumentTypes, FilterBusinessTransactions);
	ConfigureDocumentManagementButtons();
	
EndProcedure

&AtServer
Procedure SetVisibilityAvailability()
	
	If GetFunctionalOption("UseMultipleCompanies")
		And ValueIsFilled(Organization) Then
		Items.ListProductionDocumentsOrganization.Visible = False;
	ElsIf GetFunctionalOption("UseMultipleCompanies") Then
		Items.ListProductionDocumentsOrganization.Visible = True;
	ElsIf Not GetFunctionalOption("UseMultipleCompanies") Then
		Items.Organization.Visible = False;
	EndIf;
	
	If ValueIsFilled(Department) Then
		Items.ListProductionDocumentsDepartment.Visible = False;
	Else
		Items.ListProductionDocumentsDepartment.Visible = True;
	EndIf;
	
	If Not GetFunctionalOption("EmployeeInChargeInDocuments") Then
		Items.Manager.Visible = False;
		Items.ListProductionDocumentsManager.Visible = False;
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
Procedure SetDynamicListSelections()
	
	SetSelectionAdditionalEntry();
	
	CommonClientServer.SetDynamicListFilterItem(
		ListProductionDocuments,
		"RefType",
		FilterDocumentTypes,
		DataCompositionComparisonType.InList,
		,
		True);
	
	CommonClientServer.SetDynamicListFilterItem(
		ListProductionDocuments,
		"BusinessOperation",
		FilterBusinessTransactions,
		DataCompositionComparisonType.InList,
		,
		True);
	
	SetSelectionByOrganization();
	
	CommonClientServer.SetDynamicListFilterItem(ListProductionDocuments,
		"Department",
		Department,
		DataCompositionComparisonType.Equal,,
		ValueIsFilled(Department));
	
	CommonClientServer.SetDynamicListFilterItem(
		ListProductionDocuments,
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
	
	CommonClientServer.SetDynamicListFilterItem(
		ListProductionDocuments,
		"Organization",
		CompaniesList,
		DataCompositionComparisonType.InList,
		,
		ValueIsFilled(Organization));
		
	// DynamicListsSettings
	OperationsWithDocumentJournals.SetVisibilityOfDefaultUpdateSettingsGroup(ThisObject, "ListProductionDocuments");
	// End DynamicListsSettings
	
EndProcedure

&AtServer
Procedure SetSelectionByPeriod()
	
	ListProductionDocuments.Parameters.SetParameterValue("BeginOfPeriod",
		Period.StartDate);
	ListProductionDocuments.Parameters.SetParameterValue("EndOfPeriod", 
		?(ValueIsFilled(Period.EndDate), Period.EndDate, EndOfDay(Date(3999, 12, 31))));
		
	// DynamicListsSettings
	OperationsWithDocumentJournals.SetVisibilityOfDefaultUpdateSettingsGroup(ThisObject, "ListProductionDocuments");
	// End DynamicListsSettings
		
EndProcedure

&AtServer
Procedure SetSelectionAdditionalEntry()
	
	If Not RestrictionByCompanyIsUsed
		And Not RestrictionByWarehouseIsUsed
		And Not DivisionRestrictionIsUsed Then
		CommonClientServer.SetDynamicListFilterItem(
			ListProductionDocuments,
			"AdditionalRecord",
			False,
			DataCompositionComparisonType.Equal,
			,
			Not ValueIsFilled(Organization)
				And Not ValueIsFilled(Department));
	EndIf;
	
EndProcedure

#EndRegion

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
	GenerationParameters.Insert("Organization", Organization);
	GenerationParameters.Insert("Department", Department);
	GenerationParameters.Insert("Manager", Manager);
	GenerationParameters.Insert("FilterBusinessTransactions", FilterBusinessTransactions);
	
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
		
		ExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(UUID);
		ExecutionParameters.WaitCompletion = 0;
		ExecutionParameters.RunInBackground = True;
		CalculationResult2 = TimeConsumingOperations.ExecuteInBackground("DataProcessors.LogOfProductionDocuments.CreateHyperlinkToBackgroundTaskLayout",
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
	ArrayCalculationManagersSeeAlsoInWork.Add("Document.OrderOfMaterialsForProduction");
	ArrayCalculationManagersSeeAlsoInWork.Add("Document.ProductionOrder2_2");
	ArrayCalculationManagersSeeAlsoInWork.Add("Document.ProductionStage2_2");
	
	SeeAlsoInProgress = TMCommonUse.CreateHyperlinkSeeAlsoIn(ArrayCalculationManagersSeeAlsoInWork, GenerationParameters);
	Items.SeeAlsoInProgress.Visible = ValueIsFilled(SeeAlsoInProgress);

EndProcedure

&AtServerNoContext
Procedure UpdateHyperlinkToLayoutCompletion(StorageAddress, ToRegister)
	
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
		UpdateHyperlinkToLayoutCompletion(
			Result.ResultAddress,
			ToRegister);
	EndIf;
	
EndProcedure

#EndRegion

#Region DynamicListsSettings

&AtServer
Procedure InitiateDynamicListSettings()
	
	DocumentListParameters = New Array;
	
	ListParameterStructure = OperationsWithDocumentJournals.StructureOfFormationOfGroupOfUserSettingsForDynamicListOnForm();
	ListParameterStructure.ListName = "ListProductionDocuments";
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
