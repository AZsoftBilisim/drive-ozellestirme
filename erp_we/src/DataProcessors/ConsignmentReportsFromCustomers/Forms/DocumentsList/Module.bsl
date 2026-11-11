#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetConditionalAppearance();
	
	// DynamicListsSettings
	InitiateDynamicListSettings();
	ListOfDocumentsAutoUpdateMode = True;
	// End DynamicListsSettings
		
	TMCommonUse.CustomizePeripherals(ThisForm);
	
	URL = "e1cib/app/DataProcessor.ConsignmentReportsFromCustomers";
	
	DocumentTypesUsed = New Array;
	DocumentTypesUsed.Add(Type("DocumentRef.ConsignmentReportFromCustomer"));
	DocumentTypesUsed.Add(Type("DocumentRef.WriteOffReportFromCommissionAgent"));
		
	Items.GoodsTransferredCreateAccountSalesFromConsignee.Visible = 
		AccessRight("Insert", Metadata.Documents.ConsignmentReportFromCustomer);
	Items.GoodsTransferredToCreateAReportOfTheCommissionOnWriteOff.Visible = 
		AccessRight("Insert", Metadata.Documents.WriteOffReportFromCommissionAgent);
		
	Items.GoodsTransferredOrganization.Visible = GetFunctionalOption("UseMultipleCompanies");
	Items.Counterparty.Visible = GetFunctionalOption("UsePartnersAndCounterparties");
	
	List.Parameters.SetParameterValue("ObjectIDCommissionAgentReport",
		Common.MetadataObjectID("Document.ConsignmentReportFromCustomer"));
	List.Parameters.SetParameterValue("ObjectIDCommissionAgentSReportOnWriteOff",
		Common.MetadataObjectID("Document.WriteOffReportFromCommissionAgent"));
		
	DocumentTypes = New Array();
	DocumentTypes.Add("Document.ConsignmentReportFromCustomer");
	DocumentTypes.Add("Document.WriteOffReportFromCommissionAgent");
	
	TMCommonUse.ReplaceLinkFieldWithExpressByDocumentTypeConstruct(Items.List,
		DocumentTypes);
	
	
	DocumentTypesUsed.Add(Type("DocumentRef.ReversingEntry"));
	
	// StandardSubsystems.AttachableCommands
	PlacementParameters = AttachableCommands.PlacementParameters();
	PlacementParameters.Sources = New TypeDescription(DocumentTypesUsed);
	PlacementParameters.CommandBar = Items.ListCommandBar;
	AttachableCommands.OnCreateAtServer(ThisObject, PlacementParameters);
	// End StandardSubsystems.AttachableCommands
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject, Items.ListCommandBar);
	// End IntegrationWith1CDocumentManagementSubsystem
	
	
	SetFilter();
	SetParametersForDynamicLists();
	SetCurrentPage();
	SetPropertiesOfOutdatedCommissionUsageComment();
	
EndProcedure

&AtServer
Procedure OnLoadDataFromSettingsAtServer(Settings)
	
	Consignee = Settings.Get("Consignee");
	
	// DynamicListsSettings
	OperationsWithDocumentJournals.SetFlagForAutoUpdatingListOfDocumentsWhenUploadingDataFromSettings(ThisObject,
		"List", Settings);
	// End DynamicListsSettings
	
	SetFilter();
	
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
	
	If EventName = "Write_ConsignmentReportFromCustomer"
		Or EventName = "Write_WriteOffReportFromCommissionAgent"
		Or EventName = "RecordingStorno"
		Or EventName = "Conducting_Storno" Then
		Items.GoodsTransferred.Refresh();
		// DynamicListsSettings
		UpdateListOfDocumentsEventNotificationProcessing("List", Parameter);
		// End DynamicListsSettings
	EndIf;
	

EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure ConsigneeOnChange(Item)
	
	SetFilter();
	
EndProcedure

&AtClient
Procedure PeriodOptionOnChange(Item)
	
	SetParametersForDynamicLists();
	
EndProcedure

&AtClient
Procedure PeriodStartDate_OnChange(Item)
	
	If Period.StartDate > Period.EndDate Then
		Period.EndDate = Period.StartDate;
	EndIf;
	
	SetParametersForDynamicLists();
	
EndProcedure

&AtClient
Procedure PeriodEndDate_2OnChange(Item)
	
	If Period.StartDate > Period.EndDate Then
		Period.StartDate = Period.EndDate;
	EndIf;

	SetParametersForDynamicLists();
	
EndProcedure

&AtClient
Procedure PagesOnCurrentPageChange(Item, CurrentPage)
	
	If CurrentPage = Items.TheCommissionAgentsPage Then
		Items.GoodsTransferred.Refresh();
	EndIf;
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersList

&AtClient
Procedure ListOnActivateRow(Item)
	
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	
EndProcedure

&AtClient
Procedure ListSelection(Item, RowSelected, Field, StandardProcessing)
	
	StandardProcessing = False;
	TMCommonUseClient.ChangeElement(Item);

	
EndProcedure

&AtClient
Procedure ListBeforeRowChange(Item, Cancel)
	
	Cancel = True;
	TMCommonUseClient.ChangeElement(Item);
	
EndProcedure

&AtClient
Procedure ListBeforeAddRow(Item, Cancel, Copy, Parent, Var_Group, Parameter)
	
	If Copy Then
		Cancel = True;
	EndIf;
	
EndProcedure

&AtClient
Procedure ListBeforeDeleteRow(Item, Cancel)
	
	Cancel = True;
	TMCommonUseClient.SetDeletionMark(Item, Title);
	
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
Procedure ListChange(Command)
	
	TMCommonUseClient.ChangeElement(Items.List);
	
EndProcedure

&AtClient
Procedure ListPost(Command)
	
	TMCommonUseClient.PostDocuments(Items.List, Title,
		OperationsWithDocumentJournalsClient.ParametersForUpdatingDocumentList(ThisObject, "List"));
	
EndProcedure

&AtClient
Procedure ListUndoPosting(Command)
	
	TMCommonUseClient.UndoPosting(Items.List, Title,
		OperationsWithDocumentJournalsClient.ParametersForUpdatingDocumentList(ThisObject, "List"));
	
EndProcedure

&AtClient
Procedure ListSetClearADeletionMark(Command)
	
	TMCommonUseClient.SetDeletionMark(Items.List, Title, Undefined,
		OperationsWithDocumentJournalsClient.ParametersForUpdatingDocumentList(ThisObject, "List"));
		
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
Procedure CreateAccountSalesFromConsignee(Command)
	
	String = Items.GoodsTransferred.CurrentData;
	If String <> Undefined Then
		ParametersStructure1 = StructureOfCommissionAgentReportParameters(String);
		OpenForm("Document.ConsignmentReportFromCustomer.ObjectForm", ParametersStructure1, Items.List);
	Else
		OpenForm("Document.ConsignmentReportFromCustomer.ObjectForm", , Items.List);
	EndIf;
	
EndProcedure

&AtClient
Procedure ToCreateAReportOfTheCommissionOnWriteOff(Command)
	
	String = Items.GoodsTransferred.CurrentData;
	If String <> Undefined Then
		ParametersStructure1 = StructureOfCommissionAgentReportParameters(String);
		OpenForm("Document.WriteOffReportFromCommissionAgent.ObjectForm", ParametersStructure1, Items.List);
	Else
		ShowMessageBox(Undefined, NStr("vi = 'Không thể thực hiện lệnh đối với đối tượng đã chọn.';
										|ru = 'Команда не может быть выполнена для указанного объекта.';
										|en = 'Cannot execute the command for the object.'; fa = 'Cannot execute the command for the object.';
										|it = 'Il comando non può essere eseguito per l''oggetto indicato.';
										|pl = 'Nie można wykonać polecenia dla określonego obiektu.';
										|tr = 'Komut, belirtilen nesne için yürütülemiyor.'"));
	EndIf;
	
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

// IntegrationWith1CDocumentManagementSubsystem
&AtClient
Procedure Attachable_ExecuteIntegrationCommand(Command)
	
	IntegrationWith1CDocumentManagementCoreClient.ExecutePlugInIntegrationCommand(Command, ThisObject, Items.List);
	
EndProcedure
// End IntegrationWith1CDocumentManagementSubsystem


&AtClient
Procedure DocumentsListRefresh(Command)
	
	// DynamicListsSettings
	UpdateDocumentListDataWithTimeMeasurement("List");
	// End DynamicListsSettings
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()
	
	StandardSubsystemsServer.SetDateFieldConditionalAppearance(ThisObject, "List.Date", Items.Date.Name);
	
EndProcedure

&AtServer
Procedure SetFilter()
	
	CommonClientServer.SetDynamicListFilterItem(
		List,
		"Partner",
		Consignee,
		DataCompositionComparisonType.Equal,
		,
		ValueIsFilled(Consignee));
	
	CommonClientServer.SetDynamicListFilterItem(
		GoodsTransferred,
		"ItemsLocationAttributes.StorageLocation",
		Consignee,
		DataCompositionComparisonType.Equal,
		,
		ValueIsFilled(Consignee));

	SetSelectionByPeriod();
	
EndProcedure

&AtServer
Procedure SetSelectionByPeriod()
	
	List.Parameters.SetParameterValue("BeginOfPeriod",
		Period.StartDate);
	List.Parameters.SetParameterValue("EndOfPeriod", 
		?(ValueIsFilled(Period.EndDate), Period.EndDate, EndOfDay(Date(3999, 12, 31))));
	
	// DynamicListsSettings
	OperationsWithDocumentJournals.SetVisibilityOfDefaultUpdateSettingsGroup(ThisObject, "List");
	// End DynamicListsSettings
	
EndProcedure

&AtServer
Procedure SetCurrentPage()
	
	CurrentPageName = "";
	
	If Parameters.Property("CurrentPageName", CurrentPageName) Then
		If ValueIsFilled(CurrentPageName) Then
			CurrentItem = Items[CurrentPageName];
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Function StructureOfCommissionAgentReportParameters(String)
	
	StructureBase = New Structure;
	StructureBase.Insert("Organization", String.Organization);
	StructureBase.Insert("Partner", String.Consignee);
	StructureBase.Insert("Terms", String.Terms);
	StructureBase.Insert("BeginOfPeriod", Period.StartDate);
	StructureBase.Insert("EndOfPeriod", Period.EndDate);
	StructureBase.Insert("ByPhysicalCountResults", True);
	StructureBase.Insert("FillInByAgreement", True);
	
	ParametersStructure1 = New Structure;
	ParametersStructure1.Insert("Basis", StructureBase);
	
	Return ParametersStructure1;
	
EndFunction

&AtServer
Procedure SetParametersForDynamicLists()
	
	DateOfRemainingGoods = ?(ValueIsFilled(Period.EndDate), Period.EndDate, '00010101');
	
	If ValueIsFilled(DateOfRemainingGoods) Then
		Boundary = New Boundary(EndOfDay(DateOfRemainingGoods), BoundaryType.Including);
	Else
		Boundary = DateOfRemainingGoods;
	EndIf;
	
	GoodsTransferred.Parameters.SetParameterValue("Boundary", Boundary);
	
EndProcedure

&AtServer
Procedure SetPropertiesOfOutdatedCommissionUsageComment()
	
	Items.CommentUsingOutdatedCommission.Title = ConsignmentSalesServer.CommentUsingOutdatedCommission();
	
EndProcedure

#Region BarcodesAndTradeEquipment

&AtClient
Function LinkToListItemByBarcode(Barcode)
	
	Managers = New Array();
	Managers.Add(PredefinedValue("Document.ConsignmentReportFromCustomer.EmptyRef"));
	Managers.Add(PredefinedValue("Document.WriteOffReportFromCommissionAgent.EmptyRef"));
	Return BarcodingOfPrintFormsClient.GetLinkFromBarcodeOfTabularDocument(Barcode, Managers);
	
EndFunction

&AtClient
Procedure ProcessBarcodes(Data)
	
	ReferencesArrray = LinkToListItemByBarcode(Data.Barcode);
	If ReferencesArrray.Count() > 0 Then
		Ref = ReferencesArrray[0];
		Items.List.CurrentRow = Ref;
		ShowValue(Undefined, Ref);
	Else
		BarcodingOfPrintFormsClient.ObjectIsNotFound(Data.Barcode);
	EndIf;
	
EndProcedure

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

#EndRegion
