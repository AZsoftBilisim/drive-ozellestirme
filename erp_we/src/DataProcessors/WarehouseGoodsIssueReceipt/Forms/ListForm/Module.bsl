
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
	
	URL = "e1cib/app/DataProcessor.WarehouseGoodsIssueReceipt";
	TMCommonUse.CustomizePeripherals(ThisForm);
	
	Parameters.Property("QuickFilterStructure", QuickFilterStructure);
	
	ListOfDocumentsAutoUpdateMode = True;
	If QuickFilterStructure = Undefined Then
		RestoreSettings();
	EndIf;
	
	VTBusinessTransactionsAndDocumentTypes = TMCommonUse.AvailableBusinessTransactionsAndDocuments(DescriptionOfOperationsAndDocumentTypes(),
		FilterBusinessTransactions, FilterDocumentTypes, "");
	
	BusinessTransactionsAndDocuments.Load(VTBusinessTransactionsAndDocumentTypes);
	
	EstablishSelectionsForBusinessOperationsAndDocuments();
	ConfigureDocumentManagementButtons();
	
	WarehouseOnChangeServer();
	
	DocumentTypesUsed = VTBusinessTransactionsAndDocumentTypes.UnloadColumn("DocumentType");
	
	
	// StandardSubsystems.AttachableCommands
	PlacementParameters = AttachableCommands.PlacementParameters();
	PlacementParameters.Sources = New TypeDescription(DocumentTypesUsed);
	PlacementParameters.CommandBar = Items.CertificateListCommandBar;
	
	AttachableCommands.OnCreateAtServer(ThisObject, PlacementParameters);
	// End StandardSubsystems.AttachableCommands
	
	TMCommonUse.ReplaceLinkFieldWithExpressByDocumentTypeConstruct(Items.CertificateList,
		BusinessTransactionsAndDocuments, "InternalDocumentDataOverridable");
	
	// Document verificationreferences
	ListProperties = Common.DynamicListPropertiesStructure();
	FillPropertyValues(ListProperties, CertificateList);
	DocumentVerificationServer.ModifyDynamicDocumentLogListRequest(ListProperties.QueryText, "InternalDocumentDataOverridable");
	Common.SetDynamicListProperties(Items.CertificateList, ListProperties);
	// End Document verificationreferences
	
	AdditionalParameters = New Structure("LocationOfLocalValidationData", Items.ReglGroupVerification);
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing, AdditionalParameters);
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	EnableWaitingHandlerForMonitoringOperationOfBackgroundJobsFormingQueue();
	
	EquipmentManagerClient.StartConnectingDevicesWhenYouOpenForm(Undefined, ThisForm, "BarcodeScanner");
	
	
	// DynamicListsSettings
	SetParametersForUpdatingDocumentLists(False, 0);
	// End DynamicListsSettings

EndProcedure

&AtClient
Procedure OnClose(Exit)
	
	EquipmentManagerClient.StartDisablingHardwareWhenClosingForm(Undefined, ThisForm);
	
	If Not Exit
		And QuickFilterStructure = Undefined Then
		
		ShouldSaveSettings();
		
	EndIf;
	
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
	
	
	If EventName = "Creation_WarehouseCertificates"
		Or EventName = "Write_WriteOffOfGoodsShortages"
		Or EventName = "Write_GoodsDamage"
		Or EventName = "Write_GoodsMisgrading"
		Or EventName = "Write_InventorySurplusRecognition"
		Or EventName = "Write_PhysicalCountReport"
		Or EventName = "Recording_OrderToReflectSurplusGoods"
		Or EventName = "GoodsShortageNote"
		Or EventName = "DamageNote" Then
		
		// DynamicListsSettings
		UpdateListOfDocumentsEventNotificationProcessing("CertificateList", Parameter);
		// End DynamicListsSettings
		
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure WarehouseOnChange(Item)
	
    WarehouseOnChangeServer();

	EnableWaitingHandlerForMonitoringOperationOfBackgroundJobsFormingQueue();
	
EndProcedure

&AtClient
Procedure ThereIsAProblemURLProcessing(Item, FormattedStringURL, StandardProcessing)
	
	StandardProcessing = False;
	
	If URL = "StartGeneration" Then
		
		ClearMessages();
		StartCreatingAdjustments();		
		
	EndIf;
	
EndProcedure

&AtClient
Procedure AttentionClick(Item)
	ClearMessages();
	StartCreatingAdjustments();
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersCertificateList

&AtClient
Procedure CertificateListOnChange(Item)
	UpdateHyperlinkToLayout();
EndProcedure

&AtClient
Procedure CertificateListSelection(Item, RowSelected, Field, StandardProcessing)
	
	StandardProcessing = False;
	
	TMCommonUseClient.ChangeElement(Item);
	
	
EndProcedure

&AtClient
Procedure CertificateListBeforeDeleteRow(Item, Cancel)
	
	Cancel = True;
	CallbackOnCompletion = New CallbackDescription("SetDeletionMarkCompletion", ThisObject);
	TMCommonUseClient.SetDeletionMark(Item, Title, CallbackOnCompletion);
	
EndProcedure

&AtClient
Procedure CertificateListBeforeRowChange(Item, Cancel)
	
	Cancel = True;
	TMCommonUseClient.ChangeElement(Item);
	
EndProcedure

&AtClient
Procedure CertificateListBeforeAddRow(Item, Cancel, Copy, Parent, Var_Group, Parameter)
	
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
Procedure CertificateListOnActivateRow(Item)
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

&AtServer
Procedure CertificateListOnUpdateUserSettingSetAtServer(Item, StandardProcessing)
	
	// DynamicListsSettings
	OperationsWithDocumentJournals.SetVisibilityOfDefaultUpdateSettingsGroup(ThisObject, "CertificateList");
	// End DynamicListsSettings
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure UpdateAll(Command)
	UpdateEverythingOnServer();
EndProcedure

&AtClient
Procedure ListOfActsToCopy(Command)
	
	TMCommonUseClient.CopyItem(Items.CertificateList);
	
EndProcedure

&AtClient
Procedure CertificateListChange(Command)
	
	TMCommonUseClient.ChangeElement(Items.CertificateList);
	
EndProcedure

&AtClient
Procedure ListOfActsToConduct(Command)
	
	TMCommonUseClient.PostDocuments(Items.CertificateList, Title,
		OperationsWithDocumentJournalsClient.ParametersForUpdatingDocumentList(ThisObject, "CertificateList"));
	ListPostServer();
	
EndProcedure

&AtClient
Procedure ListOfActsOfCancellation(Command)
	
	TMCommonUseClient.UndoPosting(Items.CertificateList, Title,
		OperationsWithDocumentJournalsClient.ParametersForUpdatingDocumentList(ThisObject, "CertificateList"));
	ListUndoPostingServer();
	
EndProcedure

&AtClient
Procedure CertificateListSetDeletionMark(Command)
	
	Notification = New CallbackDescription("CertificateListSetDeletionMarkCompletion", ThisObject);

	TMCommonUseClient.SetDeletionMark(Items.CertificateList, Title, Notification,
		OperationsWithDocumentJournalsClient.ParametersForUpdatingDocumentList(ThisObject, "CertificateList"));
	
EndProcedure

&AtClient
Procedure CertificateListSetDeletionMarkCompletion(Command, AdditionalParameters) Export
	
	ListDeletionMarkServer();
	
EndProcedure

&AtClient
Procedure SetDateInterval(Command)
	
	Notification = New CallbackDescription("SetDateIntervalCompletion", ThisObject);
	
	TMCommonUseClient.EditPeriod(Interval, , Notification);
	
EndProcedure

&AtClient
Procedure SetDateIntervalCompletion(ValueSelected, AdditionalParameters) Export
	
	If ValueSelected = Undefined Then
		Return;
	EndIf;
	
	CertificateList.Parameters.SetParameterValue("BeginOfPeriod", Interval.StartDate);
	CertificateList.Parameters.SetParameterValue("EndOfPeriod", 
		?(ValueIsFilled(Interval.EndDate),
			EndOfDay(Interval.EndDate),
			EndOfDay(Date(3999, 12, 31))));
			
	// DynamicListsSettings
	OperationsWithDocumentJournalsClient.SetVisibilityOfDefaultUpdateSettingsGroup(ThisObject, "CertificateList");
	// End DynamicListsSettings
			
EndProcedure

#Region CreateButton

&AtClient
Procedure ByUsingWizard(Command)
	
	FormParameters = New Structure("Warehouse", Warehouse);
	OpenForm("DataProcessor.WarehouseGoodsIssueReceiptWizard.Form", FormParameters, ThisForm);
	
EndProcedure

&AtClient
Procedure Attachable_CreateDocument(Command)
	
	FilterStructure1 = New Structure("Warehouse",Warehouse);
	TMCommonUseClient.CreateDocumentUsingCommand(Command.Name, FilterStructure1);
	
EndProcedure

&AtClient
Procedure Attachable_CreateDocumentViaSelectionForm(Command)
	
	FilterStructure1 = New Structure("Warehouse",Warehouse);
	AddressBusinessTransactionsAndDocuments = PlaceBusinessTransactionsAndDocumentsInTemporaryStorage();
	TMCommonUseClient.CreateDocumentViaSelectionForm(AddressBusinessTransactionsAndDocuments, "WarehouseActs", PurposeUseKey, FilterStructure1);
	
EndProcedure

#EndRegion

// StandardSubsystems.AttachableCommands
&AtClient
Procedure Attachable_ExecuteCommand(Command)
	AttachableCommandsClient.ExecuteCommand(ThisObject, Command, Items.CertificateList);
EndProcedure

&AtServer
Procedure Attachable_ExecuteCommandAtServer(Context, Result) Export
	AttachableCommands.ExecuteCommand(ThisObject, Context, Items.CertificateList, Result);
EndProcedure

&AtClient
Procedure Attachable_UpdateCommands()
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Items.CertificateList);
EndProcedure
// End StandardSubsystems.AttachableCommands


&AtClient
Procedure DocumentsListRefresh(Command)
	
	// DynamicListsSettings
	UpdateDocumentListDataWithTimeMeasurement("CertificateList");
	// End DynamicListsSettings

EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()
	
	StandardSubsystemsServer.SetDateFieldConditionalAppearance(ThisObject, "CertificateList.Date", "CertificateListDate");
	
EndProcedure

#Region OnChangeAttributes

&AtServer
Procedure WarehouseOnChangeServer()
	
	SetFormFunctionalOptionParameters(New Structure("Warehouse", Warehouse));
	FilterWarehouses = WarehousesServer.ListOfSubordinateWarehouses(Warehouse);
	FilterStorageLocations_ = Catalogs.DocumentRegistryKeys.KeysByValue(FilterWarehouses);
	
	CommonClientServer.SetDynamicListFilterItem(CertificateList,
																			"StorageLocation",
																			FilterStorageLocations_,
																			DataCompositionComparisonType.InList,
																			,
																			ValueIsFilled(FilterStorageLocations_));
	
	UseWarehouseManagemantSystemForGoodsSurplusesShortages =
		WarehousesServer.UseWarehouseManagemantSystemForGoodsSurplusesShortages(Warehouse);
	
	BinLocationWarehousingIsUsedInTheWarehouseOrItsWarerooms = GetFunctionalOption("UseBinLocationWarehousing", New Structure("Warehouse", Warehouse));
	
	UpdateHyperlinkToLayout();
	
	// DynamicListsSettings
	OperationsWithDocumentJournals.SetVisibilityOfDefaultUpdateSettingsGroup(ThisObject, "CertificateList");
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
				|tr = 'Belge barkoda göre aranıyor...'"));
	BarcodeData = BarcodeDataOfPrintedForm(Data.Barcode, "CertificateList");
	TMCommonUseClient.ProcessBarcodes(Data.Barcode, BarcodeData, ThisForm, "CertificateList");
	
EndProcedure

#EndRegion

#Region BackgroundTaskForCreatingAdjustments

&AtServer
Procedure StartCreatingAdjustments()
	
	HasError = WarehousesServer.GenerateAdjustmentsForSurplusShortagesByProductLocationsForAllWarehousePremises(Warehouse);
	
	Items.StateOfAutomaticAdjustmentGeneration.Visible = HasError; 	
	
EndProcedure

&AtClient
Procedure MonitoringOperationOfBackgroundQueueFormationTasks()
		
	MonitoringOperationOfBackgroundQueueGenerationTasksOnServer()
			
EndProcedure

&AtServer
Procedure MonitoringOperationOfBackgroundQueueGenerationTasksOnServer()
			
	Items.StateOfAutomaticAdjustmentGeneration.Visible = 
		WarehousesServer.ThereArePremisesForWhichThereIsNoBackgroundTaskForFormationOfAdjustmentsForSurplusShortagesInCommodityPlaces(Warehouse);
				
EndProcedure

&AtClient
Procedure EnableWaitingHandlerForMonitoringOperationOfBackgroundJobsFormingQueue()
	
	If Not BinLocationWarehousingIsUsedInTheWarehouseOrItsWarerooms Then
		Items.StateOfAutomaticAdjustmentGeneration.Visible = False;
		DetachIdleHandler("MonitoringOperationOfBackgroundQueueFormationTasks");
		Return;
	EndIf; 
	
	MonitoringOperationOfBackgroundQueueFormationTasks();
	AttachIdleHandler("MonitoringOperationOfBackgroundQueueFormationTasks", 600);
	
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
Procedure RestoreSettings()
	Var SettingsValue;

	ListOfDocumentsAutoUpdateMode = True;
	
	SettingsValue = Common.CommonSettingsStorageLoad("DataProcessor.WarehouseGoodsIssueReceipt", "ProcessingSettings");
	If TypeOf(SettingsValue) = Type("Structure") Then
		SettingsValue.Property("Warehouse", Warehouse);
		If SettingsValue.Property("ListOfDocumentsAutoUpdateMode") Then
			ListOfDocumentsAutoUpdateMode = SettingsValue.ListOfDocumentsAutoUpdateMode;
		EndIf;
	EndIf;

EndProcedure

&AtServer
Procedure ShouldSaveSettings()
	Var Settings;

	Settings = New Structure;
	Settings.Insert("Warehouse", Warehouse);
	Settings.Insert("ListOfDocumentsAutoUpdateMode", ListOfDocumentsAutoUpdateMode);

	Common.CommonSettingsStorageSave("DataProcessor.WarehouseGoodsIssueReceipt", "ProcessingSettings", Settings);

EndProcedure

&AtClient
Procedure DecorationRecalculationsProcessingOfTheNavigationLink(Item, Var_URL, StandardProcessing)
	
	StandardProcessing = False;
	QuickFilterStructure = New Structure;
	QuickFilterStructure.Insert("Warehouse", Warehouse);
	FormParameters = New Structure;
	FormParameters.Insert("QuickFilterStructure", QuickFilterStructure);
	If Var_URL = "ListOfRecalculationsOnlyOutstanding" Then
		FormParameters.Insert("Status",  "OnlyNotCompleted");
	EndIf;
	OpenForm("Document.InventoryRecount.Form.ListForm", FormParameters, ThisForm);
	
EndProcedure

&AtServerNoContext
Function ThereAreUnformulatedWarehouseRecalculations(Warehouse)
	
	Return ?(ValueIsFilled(Warehouse),Documents.InventoryRecount.UnformattedRecalculationsByWarehouse(Warehouse).Count() > 0,False);
	
EndFunction

&AtServer
Procedure UpdateEverythingOnServer()
	Items.CertificateList.Refresh();
	UpdateHyperlinkToLayout();
EndProcedure

&AtClient
Procedure SetDeletionMarkCompletion(Result, AdditionalParameters) Export
	
	UpdateHyperlinkToLayout();
	
EndProcedure

&AtServer
Function DescriptionOfOperationsAndDocumentTypes()
	
	VTBusinessTransactionsAndDocumentTypes = BusinessTransactionsAndDocuments.Unload();
	VTBusinessTransactionsAndDocumentTypes.Clear();
	
	String = VTBusinessTransactionsAndDocumentTypes.Add();
	String.BusinessOperation 		= Enums.BusinessTransactions.GoodsRecordingAsReceived;
	String.AddButtonCreate		= True;
	String.DocumentType					= Type("DocumentRef.InventorySurplusRecognition");
	String.FullDocumentName			= Metadata.Documents.InventorySurplusRecognition.FullName();
	String.HyperlinkCalculationManagerForRegistration	= "DataProcessor.WarehouseGoodsIssueReceipt";
	
	String = VTBusinessTransactionsAndDocumentTypes.Add();
	String.BusinessOperation 		= Enums.BusinessTransactions.GoodsMisgrading;
	String.AddButtonCreate		= True;
	String.DocumentType					= Type("DocumentRef.GoodsMisgrading");
	String.FullDocumentName			= Metadata.Documents.GoodsMisgrading.FullName();
	String.HyperlinkCalculationManagerForRegistration	= "DataProcessor.WarehouseGoodsIssueReceipt";
	
	ProductDamageLine = VTBusinessTransactionsAndDocumentTypes.Add();
	String = ProductDamageLine;
	String.BusinessOperation 		= Enums.BusinessTransactions.GoodsDamage;
	String.AddButtonCreate		= True;
	String.DocumentType					= Type("DocumentRef.GoodsDamage");
	String.FullDocumentName			= Metadata.Documents.GoodsDamage.FullName();
	String.HyperlinkCalculationManagerForRegistration	= "DataProcessor.WarehouseGoodsIssueReceipt";
	
	String = VTBusinessTransactionsAndDocumentTypes.Add();
	String.BusinessOperation 		= Enums.BusinessTransactions.GoodsConsumption;
	String.AddButtonCreate		= True;
	String.DocumentType					= Type("DocumentRef.WriteOffOfGoodsShortages");
	String.FullDocumentName			= Metadata.Documents.WriteOffOfGoodsShortages.FullName();
	String.HyperlinkCalculationManagerForRegistration	= "DataProcessor.WarehouseGoodsIssueReceipt";
	
	String = VTBusinessTransactionsAndDocumentTypes.Add();
	String.BusinessOperation 		= Enums.BusinessTransactions.PhysicalCountReport;
	String.AddButtonCreate		= True;
	String.DocumentType					= Type("DocumentRef.PhysicalCountReport");
	String.FullDocumentName			= Metadata.Documents.PhysicalCountReport.FullName();
	String.HyperlinkCalculationManagerForRegistration	= "DataProcessor.WarehouseGoodsIssueReceipt";
	
	Return VTBusinessTransactionsAndDocumentTypes;
	
EndFunction

&AtServer
Procedure EstablishSelectionsForBusinessOperationsAndDocuments()
	
	CommonClientServer.SetDynamicListFilterItem(
		CertificateList,
		"BusinessOperation",
		FilterBusinessTransactions,
		DataCompositionComparisonType.InList,
		,
		True);

	CommonClientServer.SetDynamicListFilterItem(
		CertificateList,
		"RefType",
		FilterDocumentTypes,
		DataCompositionComparisonType.InList,
		,
		True);
		
	// DynamicListsSettings
	OperationsWithDocumentJournals.SetVisibilityOfDefaultUpdateSettingsGroup(ThisObject, "CertificateList");
	// End DynamicListsSettings
	
EndProcedure

&AtServer
Function PlaceBusinessTransactionsAndDocumentsInTemporaryStorage()
	Return PutToTempStorage(BusinessTransactionsAndDocuments.Unload(), UUID);
EndFunction

&AtServer
Procedure ConfigureDocumentManagementButtons()
	
	ParametersStructure = TMCommonUse.StructureOfSettingsForDocumentManagementButtons();
	ParametersStructure.Form 												= ThisForm;
	ParametersStructure.NameOfCopyButton 								= "ListOfActsToCopy";
	ParametersStructure.NameOfCopyContextMenuButton 				= "TheListOfActsTheContextMenuToCopy";
	ParametersStructure.ChangeButtonName 									= "CertificateListChange";
	ParametersStructure.NameOfChangeContextMenuButton 					= "CertificateListContextMenuChange";
	ParametersStructure.ButtonNamePost 									= "ListOfActsToConduct";
	ParametersStructure.NameOfHoldContextMenuButton 					= "ListOfActsContextMenuHold";
	ParametersStructure.NameOfCancelEventButton 							= "ListOfActsOfCancellation";
	ParametersStructure.NameOfCancelButtonIsContextMenu 			= "ListOfActsContextMenuCancelTheEvent";
	ParametersStructure.NameOfMarkDeleteButton 					= "CertificateListSetDeletionMark";
	ParametersStructure.ButtonNameMarkDeleteContextMenu 	= "ListOfActsContextMenuSetDeleteMark";
	
	TMCommonUse.ConfigureDocumentManagementButtons(ParametersStructure);

EndProcedure

#Region HyperlinkToDesign

&AtServer
Function UpdateHyperlinkToLayout()
	
	GenerationParameters = New Structure;
	GenerationParameters.Insert("Warehouse",Warehouse);
		
	ToRegister = TMCommonUse.CreateHyperlinkToDesign(BusinessTransactionsAndDocuments.Unload(), GenerationParameters);
	
	Items.ToRegister.Visible = ValueIsFilled(ToRegister);
	
	Items.PagesRecounts.Visible = ValueIsFilled(ToRegister);

	If ThereAreUnformulatedWarehouseRecalculations(Warehouse) Then
		Items.PagesRecounts.CurrentPage = Items.PageThereAreRecounts;
	Else
		Items.PagesRecounts.CurrentPage = Items.PageNoRecounts;
	EndIf;
	
EndFunction

&AtClient
Procedure ToRegisterURLProcessing(Item, FormattedStringURL, StandardProcessing)
	
	StandardProcessing = False;
	
	FormParameters = New Structure;
		
	FormParameters.Insert("FixedSettings", Undefined);
	FormParameters.Insert("UserSettings", New DataCompositionUserSettings);
	If ValueIsFilled(Warehouse) Then
		VariantKey = "RegistrationOfSurplusShortagesContext";
		FormParameters.Insert("Warehouse", Warehouse);
		FormParameters.Insert("Filter", New Structure("Warehouse", Warehouse)); 
	Else
		VariantKey = "UnregisteredSurplusesAndShortagesOfGoods";
	EndIf;
	FormParameters.Insert("VariantKey", VariantKey);
	FormParameters.Insert("PurposeUseKey", VariantKey);
	FormParameters.Insert("GenerateOnOpen", True);
	FormParameters.Insert("ReportOptionsCommandsVisibility", False);
	
	OpenForm(FormattedStringURL,FormParameters,,UUID);
	
EndProcedure

#EndRegion

#EndRegion

#Region DynamicListsSettings

&AtServer
Procedure InitiateDynamicListSettings()
	
	DocumentListParameters = New Array;
	
	ListParameterStructure = OperationsWithDocumentJournals.StructureOfFormationOfGroupOfUserSettingsForDynamicListOnForm();
	ListParameterStructure.ListName = "CertificateList";
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
