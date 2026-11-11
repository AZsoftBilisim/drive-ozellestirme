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
		PurposeUseKey = DefaultFormAssignmentKey();
		SettingsKey = "";
	Else
		PurposeUseKey = Parameters.FormAssignmentKey;
		SettingsKey = Parameters.FormAssignmentKey;
	EndIf;
	
	RestoreSettings();
	
	FormEvents.OnCreateAtServer(ThisObject, Cancel, StandardProcessing);
	
	FillInFormDetailsWhenCreating();
	CustomizeFormElementsWhenCreating();
	
	TMCommonUse.FormInscriptionSelection(
		HelpTextFilter, 
		BusinessTransactionsAndDocuments, 
		FilterDocumentTypes, 
		FilterBusinessTransactions);
		
	DocumentTypesUsed = New Array;
	For Each OperationDescription In BusinessTransactionsAndDocuments Do
		DocumentTypesUsed.Add(Type("DocumentRef." + StrSplit(OperationDescription.FullDocumentName, ".")[1]));
	EndDo;
	
	// StandardSubsystems.AttachableCommands
	PlacementParameters = AttachableCommands.PlacementParameters();
	PlacementParameters.Sources = New TypeDescription(DocumentTypesUsed);
	PlacementParameters.CommandBar = Items.ListCommandBar;
	PlacementParameters.GroupsPrefix = "List";
	AttachableCommands.OnCreateAtServer(ThisObject, PlacementParameters);
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
	
	If EventName = "Write_File" Then
		
		// DynamicListsSettings
		UpdateListOfDocumentsEventNotificationProcessing("List", Parameter);
		// End DynamicListsSettings
		
	ElsIf StrFind(EventName, "Record_") <> 0 Then
	
		For Each LineDocument In BusinessTransactionsAndDocuments Do
			EventNameDocumentEntry = StrReplace(LineDocument.FullDocumentName, "Document.", "Record_");
			If EventNameDocumentEntry = EventName Then
				// DynamicListsSettings
				UpdateListOfDocumentsEventNotificationProcessing("List", Parameter);
				// End DynamicListsSettings
				Break;
			EndIf; 
		EndDo; 
		
	EndIf; 
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure FilterOrganizationOnChange(Item)
	
	WhenSelectionChanges();
	
EndProcedure

&AtClient
Procedure FilterDepartmentOnChange(Item)
	
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

#Region AttachableCommands

&AtClient
Procedure Attachable_CreateDocument(Command)
	
	TMCommonUseClient.CreateDocumentUsingCommand(Command.Name, SelectionsForCreatingDocument());
	
EndProcedure

&AtClient
Procedure Attachable_CreateDocumentViaSelectionForm(Command)
	
	AddressBusinessTransactionsAndDocuments = PlaceBusinessTransactionsAndDocumentsInTemporaryStorage();
	TMCommonUseClient.CreateDocumentViaSelectionForm(AddressBusinessTransactionsAndDocuments,
		DefaultFormAssignmentKey(), PurposeUseKey, SelectionsForCreatingDocument());
		
EndProcedure

// StandardSubsystems.AttachableCommands
&AtClient
Procedure Attachable_ExecuteCommand(Command)
	AttachableCommandsClient.ExecuteCommand(ThisObject, Command, CurrentList(ThisObject));
EndProcedure

&AtServer
Procedure Attachable_ExecuteCommandAtServer(Context, Result) Export
	AttachableCommands.ExecuteCommand(ThisObject, Context, CurrentList(ThisObject), Result);
EndProcedure

&AtClient
Procedure Attachable_UpdateCommands()
	AttachableCommandsClientServer.UpdateCommands(ThisObject, CurrentList(ThisObject));
EndProcedure
// End StandardSubsystems.AttachableCommands

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisObject, Command);
	
EndProcedure

&AtClient
Function SelectionsForCreatingDocument()
	
	StructureSelections = New Structure;
	
	If ValueIsFilled(FilterOrganization) Then
		StructureSelections.Insert("Organization", FilterOrganization);
	EndIf;
	If ValueIsFilled(FilterDepartment) Then
		StructureSelections.Insert("Department", FilterDepartment);
	EndIf;
	
	Return StructureSelections;
	
EndFunction

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
	
	ListOfDocumentsAutoUpdateMode = True;
	
	If Parameters.Property("ListFormSelections") Then
		
		FormsOpenedByHyperlink = True;
		FilterBusinessTransactions.LoadValues(Parameters.ListFormSelections.FilterBusinessTransactions.UnloadValues());
		FilterDocumentTypes.LoadValues(Parameters.ListFormSelections.FilterDocumentTypes.UnloadValues());
		
	Else
	
		Settings = Common.CommonSettingsStorageLoad("DataProcessor.RMDocumentJournal.Form.RMDocuments", PurposeUseKey);
		
		If TypeOf(Settings) = Type("Structure") Then
		
			ListInterval = Settings.ListInterval;
			FilterOrganization = Settings.FilterOrganization;
			FilterDepartment = Settings.FilterDepartment;
			
			If Settings.Property("FilterBusinessTransactions") Then
				FilterBusinessTransactions.LoadValues(Settings.FilterBusinessTransactions.UnloadValues());
			EndIf;
			If Settings.Property("FilterDocumentTypes") Then
				FilterDocumentTypes.LoadValues(Settings.FilterDocumentTypes.UnloadValues());
			EndIf;
			If Settings.Property("ListOfDocumentsAutoUpdateMode") Then
				ListOfDocumentsAutoUpdateMode = Settings.ListOfDocumentsAutoUpdateMode;
			EndIf;
			
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
		|FilterOrganization,FilterDepartment,
		|FilterBusinessTransactions,
		|FilterDocumentTypes,
		|ListOfDocumentsAutoUpdateMode";
	
	Settings = New Structure(AttributesToSaveNames);
	FillPropertyValues(Settings, ThisObject);
	
	Common.CommonSettingsStorageSave("DataProcessor.RMDocumentJournal.Form.RMDocuments", PurposeUseKey, Settings);
	
EndProcedure

&AtServer
Procedure FillInFormDetailsWhenCreating()
	
	BusinessOperationsAndVTDocuments = BusinessTransactionsAndDocuments.Unload();
	InitializeBusinessTransactionsAndDocuments(BusinessOperationsAndVTDocuments, PurposeUseKey);
	
	TableOfValuesAvailable = TMCommonUse.AvailableBusinessTransactionsAndDocuments(
								BusinessOperationsAndVTDocuments, 
								FilterBusinessTransactions, 
								FilterDocumentTypes, 
								PurposeUseKey);
	
	BusinessTransactionsAndDocuments.Load(TableOfValuesAvailable);
	
	SetDynamicListSelections_();
	
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
	
	ConfigureFormUsingSettingsForBusinessOperationsAndDocuments();
	
EndProcedure

&AtServer
Procedure ConfigureFormUsingSettingsForBusinessOperationsAndDocuments()
	
	WorkplaceData = TMCommonUse.WorkplaceData(
		BusinessTransactionsAndDocuments.Unload(), 
		DefaultFormAssignmentKey(), 
		NStr("vi = 'Chứng từ bảo dưỡng và sửa chữa (toàn bộ)';
			|ru = 'Документы по обслуживанию и ремонтам (все)';
			|en = 'R&M documents (all)'; fa = 'R&M documents (all)';
			|it = 'Documenti di manutenzione e riparazione (tutti)';
			|pl = 'Dokumenty dotyczące obsługi i napraw (wszystkie)';
			|tr = 'Bakım ve onarım belgeleri (tümü)'"));
	
	Title = WorkplaceData.WorkplaceTitle;
	
	ConfigureDocumentManagementButtons();
	
EndProcedure

&AtServer
Procedure SetDynamicListSelections_()
	
	CommonClientServer.SetDynamicListFilterItem(
		List,
		"BusinessOperation",
		FilterBusinessTransactions,
		DataCompositionComparisonType.InList,
		,
		True);

	CommonClientServer.SetDynamicListFilterItem(
		List,
		"RefType",
		FilterDocumentTypes,
		DataCompositionComparisonType.InList,
		,
		True);
		
	CommonClientServer.SetDynamicListFilterItem(
		List,
		"Organization",
		FilterOrganization,
		DataCompositionComparisonType.Equal,
		,
		ValueIsFilled(FilterOrganization));
		
	CommonClientServer.SetDynamicListFilterItem(
		List,
		"Department",
		FilterDepartment,
		DataCompositionComparisonType.Equal,
		,
		ValueIsFilled(FilterDepartment));
		
	List.Parameters.SetParameterValue("BeginOfPeriod", ListInterval.StartDate);
	
	List.Parameters.SetParameterValue("EndOfPeriod", 
		?(ValueIsFilled(ListInterval.EndDate),
			EndOfDay(ListInterval.EndDate),
			EndOfDay(Date(3999, 12, 31))));
			
	Items.ListSetDateInterval.Check = 
		ValueIsFilled(ListInterval.StartDate) Or ValueIsFilled(ListInterval.EndDate);
	
	// DynamicListsSettings
	OperationsWithDocumentJournals.SetVisibilityOfDefaultUpdateSettingsGroup(ThisObject, "List");
	// End DynamicListsSettings
	
EndProcedure

&AtClientAtServerNoContext
Function DefaultFormAssignmentKey()
	
	Return "RMDocuments";
	
EndFunction

&AtServer
Procedure WhenSelectionChanges()
	
	ShouldSaveSettings();
	SetDynamicListSelections_();
	
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
	
	TMCommonUse.ConfigureDocumentManagementButtons(ParametersStructure);
	
EndProcedure

&AtServer
Procedure SetConditionalAppearance()
	
	ConditionalAppearance.Items.Clear();
	
	StandardSubsystemsServer.SetDateFieldConditionalAppearance(ThisObject, "List.Date", "ListDate");
	
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
	
	TMCommonUse.FormInscriptionSelection(
		HelpTextFilter, BusinessTransactionsAndDocuments, FilterDocumentTypes, FilterBusinessTransactions);
	
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

&AtClientAtServerNoContext
Function CurrentList(Form)

	Return Form.Items.List;

EndFunction

&AtServerNoContext
Procedure InitializeBusinessTransactionsAndDocuments(BusinessTransactionsAndDocuments, PurposeUseKey)
	
	// RMOrder
	String = BusinessTransactionsAndDocuments.Add();
	String.BusinessOperation 		= Enums.BusinessTransactions.Repair;
	String.FullDocumentName			= Metadata.Documents.RMOrder.FullName();
	String.PurposeUseKey 	= PurposeUseKey;
	String.WorkplaceTitle	 	= NStr("vi = 'Phiếu yêu cầu sửa chữa';
										|ru = 'Заказы на ремонт';
										|en = 'R&M orders'; fa = 'سفارش‌های تعمیر و نگهداری';
										|it = 'Ordini di manutenzione';
										|pl = 'Zamówienia na remont';
										|tr = 'Onarım siparişleri'");
	String.AddButtonCreate        = True;
	String.Order                      = 1;
	String.ButtonGroup                 = "RM";
	
	// RMRequest
	String = BusinessTransactionsAndDocuments.Add();
	String.BusinessOperation 		= Enums.BusinessTransactions.RMRequest;
	String.FullDocumentName			= Metadata.Documents.RMRequest.FullName();
	String.PurposeUseKey 	= PurposeUseKey;
	String.WorkplaceTitle	 	= NStr("vi = 'Đăng ký hỏng hóc tài sản đang vận hành';
										|ru = 'Регистрация дефектов объектов эксплуатации';
										|en = 'Asset R&M request'; fa = 'درخواست تعمیر و نگهداری دارایی';
										|it = 'Registrazione dei difetti degli oggetti dell''uso operativo';
										|pl = 'Rejestracja wad obiektów eksploatacji';
										|tr = 'İşletme tesislerindeki kusurların kaydedilmesi'");
	String.AddButtonCreate        = True;
	String.Order                      = 3;
	String.ButtonGroup                 = "RM";
	
	// AssetActivityRecord
	String = BusinessTransactionsAndDocuments.Add();
	String.BusinessOperation 		= Enums.BusinessTransactions.AssetActivityRecord;
	String.FullDocumentName			= Metadata.Documents.AssetActivityRecord.FullName();
	String.PurposeUseKey 	= PurposeUseKey;
	String.WorkplaceTitle	 	= NStr("vi = 'Thời gian sử dụng tài sản đang vận hành';
										|ru = 'Наработка объектов эксплуатации';
										|en = 'Asset activity record'; fa = 'سابقه فعالیت دارایی';
										|it = 'Tempo senza guasti dei macchinari e oggetti in uso';
										|pl = 'Okres zdolności użytkowej obiektów eksploatacji';
										|tr = 'Varlık işletme süresi'");
	String.AddButtonCreate        = True;
	String.Order                      = 5;
	String.ButtonGroup                 = "SupportAndService";
	
	// SetRunningTimeValues
	String = BusinessTransactionsAndDocuments.Add();
	String.BusinessOperation 		= Enums.BusinessTransactions.SetRunningTimeValues;
	String.FullDocumentName			= Metadata.Documents.SetRunningTimeValues.FullName();
	String.PurposeUseKey 	= PurposeUseKey;
	String.WorkplaceTitle	 	= NStr("vi = 'Cài giá trị sản lượng';
										|ru = 'Установка значений наработки';
										|en = 'Set running time values'; fa = 'تنظیم مقادیر زمان کارکرد';
										|it = 'L''impostazione dei valori degli sviluppi';
										|pl = 'Ustawianie znaczeń nadpracowań';
										|tr = 'Başarı değerlerini ayarlama'");
	String.AddButtonCreate        = True;
	String.Order                      = 6;
	String.ButtonGroup                 = "SupportAndService";
	
	// EnterInformationAboutPastRM
	String = BusinessTransactionsAndDocuments.Add();
	String.BusinessOperation 		= Enums.BusinessTransactions.EnterInformationAboutPastRM;
	String.FullDocumentName			= Metadata.Documents.EnterInformationAboutPastRM.FullName();
	String.PurposeUseKey 	= PurposeUseKey;
	String.WorkplaceTitle	 	= NStr("vi = 'Nhập thông tin về những lần đã sửa chữa';
										|ru = 'Ввод информации о прошлых ремонтах';
										|en = 'Enter information about past R&M'; fa = 'ورود اطلاعات تعمیر و نگهداری گذشته';
										|it = 'Inserimento dell''informazione sulle riparazioni precedenti';
										|pl = 'Wprowadzenie informacji o poprzednich naprawach';
										|tr = 'Geçmiş onarımlar hakkında bilgi girilmesi'");
	String.AddButtonCreate        = True;
	String.Order                      = 7;
	String.ButtonGroup                 = "Other";
		
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
