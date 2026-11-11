
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetConditionalAppearance();
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	// DynamicListsSettings
	InitiateDynamicListSettings();
	ListOfDocumentsAutoUpdateMode = True;
	// End DynamicListsSettings
	
	If Parameters.Property("FormAssignmentKey") And Not IsBlankString(Parameters.FormAssignmentKey) Then
		PurposeUseKey = Parameters.FormAssignmentKey;
	Else
		PurposeUseKey = "ElectronicTicketsAndBookings";
	EndIf;
	
	If PurposeUseKey = "ElectronicTicketsAndBookings" Then
		SettingsKey = "";
	Else
		SettingsKey = PurposeUseKey;
	EndIf;
	URL = "e1cib/app/DataProcessor.TicketsAndBookingsLog";
	
	SetQueryTextToListOfDocuments();
	
	DocumentsList.Parameters.SetParameterValue("ObjectIdOfOperationWithElectronicTicket",
		Common.MetadataObjectID("Document.ElectronicTicketTransaction"));
		
	
	DocumentsList.Parameters.SetParameterValue("DocumentTypeElectronicTicket", NStr("vi = 'Vé điện tử';
																					|ru = 'Электронный билет';
																					|en = 'Electronic ticket'; fa = 'بلیت الکترونیکی';
																					|it = 'Biglietto elettronico';
																					|pl = 'Bilet elektroniczny';
																					|tr = 'Elektronik bilet'"));
	
	MetadataOfOperationTypes = Metadata.Enums.TypesOfTicketOperations.EnumValues;
	DocumentsList.Parameters.SetParameterValue("DocumentTypeSurcharge", MetadataOfOperationTypes.ExtraPay.Synonym);
	DocumentsList.Parameters.SetParameterValue("DocumentTypeReturn", MetadataOfOperationTypes.Return.Synonym);
		
	// Document verificationreferences
	ListProperties = Common.DynamicListPropertiesStructure();
	FillPropertyValues(ListProperties, DocumentsList);
	DocumentVerificationServer.ModifyDynamicDocumentLogListRequest(ListProperties.QueryText, "DocumentsRegistryOverridable");
	Common.SetDynamicListProperties(Items.DocumentsList, ListProperties);
	// End Document verificationreferences
	
	SetVisibilityAvailability();
	SetDynamicListSelection();
	ConfigureDocumentManagementButtons();
	
	// StandardSubsystems.AttachableCommands
	PlacementParameters = AttachableCommands.PlacementParameters();
	
	ArrayOfSourceTypes = New Array;
	ArrayOfSourceTypes.Add(Type("DocumentRef.ElectronicTicketTransaction"));
	
	PlacementParameters.Sources = New TypeDescription(ArrayOfSourceTypes);
	
	PlacementParameters.CommandBar = Items.DocumentsListCommandBar;
	AttachableCommands.OnCreateAtServer(ThisObject, PlacementParameters);
	// End StandardSubsystems.AttachableCommands
	
	If Not ValueIsFilled(CurrentOptionForSelectingDocuments) Then
		CurrentOptionForSelectingDocuments = DefaultDocumentSelectionOption();
	EndIf;
	
	AdditionalParameters = New Structure("LocationOfLocalValidationData", Items.ReglGroupVerification);
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing, AdditionalParameters);
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	// DynamicListsSettings
	SetParametersForUpdatingDocumentLists(False, 0);
	// End DynamicListsSettings
	
EndProcedure

&AtServer
Procedure OnLoadDataFromSettingsAtServer(Settings)
	
	Period            = Settings.Get("Period");
	Organization       = Settings.Get("Organization");
	Employee         = Settings.Get("Employee");
	
	// DynamicListsSettings
	OperationsWithDocumentJournals.SetFlagForAutoUpdatingListOfDocumentsWhenUploadingDataFromSettings(ThisObject,
		"DocumentsList", Settings);
	// End DynamicListsSettings
	
	SetDynamicListSelection();
	
	If Not ValueIsFilled(CurrentOptionForSelectingDocuments) Then
		CurrentOptionForSelectingDocuments = DefaultDocumentSelectionOption();
	EndIf;
	ApplyDocumentSelectionOption(CurrentOptionForSelectingDocuments);
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If EventName = "Record_TicketsAndReservations" Then
		
		// DynamicListsSettings
		UpdateListOfDocumentsEventNotificationProcessing("DocumentsList", Parameter);
		// End DynamicListsSettings
		
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure HelpTextFilterURLProcessing(Item, FormattedStringURL, StandardProcessing)
	
	StandardProcessing = False;
	ShowSelectionOfDocumentSelectionOption();
	
EndProcedure

&AtClient
Procedure CompanyFilterOnChange(Item)
	SetDynamicListSelection();
EndProcedure

&AtClient
Procedure EmployeeFilterOnChange(Item)
	SetDynamicListSelection();
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersList

&AtClient
Procedure DocumentsListSelection(Item, RowSelected, Field, StandardProcessing)
	
	StandardProcessing = False;
	TMCommonUseClient.ChangeElement(Item);
	
EndProcedure

&AtClient
Procedure DocumentsListOnActivateRow(Item)
	
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	
EndProcedure

&AtClient
Procedure DocumentsListBeforeAddRow(Item, Cancel, Copy, Parent, Var_Group, Parameter)
	
	If Copy Then
		TMCommonUseClient.CopyItem(Item);
	Else
		BasisParameters = New Structure;
		BasisParameters.Insert("Organization", Organization);
		BasisParameters.Insert("Employee", Employee);
		
		OpenForm("Document.ElectronicTicketTransaction.Form.DocumentForm", New Structure("Basis", BasisParameters));
	EndIf;
	
	Cancel = True;
	
EndProcedure

&AtClient
Procedure DocumentsListBeforeRowChange(Item, Cancel)
	
	Cancel = True;
	TMCommonUseClient.ChangeElement(Item);
	
EndProcedure

&AtClient
Procedure DocumentsListBeforeDeleteRow(Item, Cancel)
	
	Cancel = True;
	TMCommonUseClient.SetDeletionMark(Item, Title);
	
EndProcedure

&AtClient
Procedure DocumentsListCopy(Command)
	
	TMCommonUseClient.CopyItem(Items.DocumentsList);
	
EndProcedure

&AtClient
Procedure EditDocumentList(Command)
	
	TMCommonUseClient.ChangeElement(Items.DocumentsList);
	
EndProcedure

&AtClient
Procedure ListOfDocumentsCancellationOfTheEvent(Command)
	
	TMCommonUseClient.UndoPosting(Items.DocumentsList, Title,
		OperationsWithDocumentJournalsClient.ParametersForUpdatingDocumentList(ThisObject, "DocumentsList"));
	
EndProcedure

&AtClient
Procedure ListOfDocumentsToHold(Command)
	
	TMCommonUseClient.PostDocuments(Items.DocumentsList, Title,
		OperationsWithDocumentJournalsClient.ParametersForUpdatingDocumentList(ThisObject, "DocumentsList"));
	
EndProcedure

&AtClient
Procedure AListOfDocumentsToEstablishClearMarkRemoval(Command)
	
	TMCommonUseClient.SetDeletionMark(Items.DocumentsList, Title, Undefined,
		OperationsWithDocumentJournalsClient.ParametersForUpdatingDocumentList(ThisObject, "DocumentsList"));
	
EndProcedure

&AtServer
Procedure DocumentsListOnUpdateUserSettingSetAtServer(Item, StandardProcessing)
	
	// DynamicListsSettings
	OperationsWithDocumentJournals.SetVisibilityOfDefaultUpdateSettingsGroup(ThisObject, "DocumentsList");
	// End DynamicListsSettings
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

// StandardSubsystems.AttachableCommands
&AtClient
Procedure Attachable_ExecuteCommand(Command)
	AttachableCommandsClient.ExecuteCommand(ThisObject, Command, Items.DocumentsList);
EndProcedure

&AtServer
Procedure Attachable_ExecuteCommandAtServer(Context, Result) Export
	AttachableCommands.ExecuteCommand(ThisObject, Context, Items.DocumentsList, Result);
EndProcedure

&AtClient
Procedure Attachable_UpdateCommands()
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Items.DocumentsList);
	UpdateDocumentCreationCommands();
EndProcedure
// End StandardSubsystems.AttachableCommands

&AtClient
Procedure UpdateDocumentCreationCommands()
	
	Items.CreateSurchargeList.Visible = False;
	Items.CreateReturnList.Visible = False;
	
	CurrentData = Items.DocumentsList.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	TicketOperationsAreAvailable = Items.CreateTicketList.Visible
		And (CurrentOptionForSelectingDocuments = DefaultDocumentSelectionOption()
		Or CurrentOptionForSelectingDocuments = "ElectronicTicketsAndOfOperations");
	
	Items.CreateSurchargeList.Visible = TicketOperationsAreAvailable And CurrentData.ThisIsElectronicTicket;
	Items.CreateReturnList.Visible = TicketOperationsAreAvailable And CurrentData.ThisIsElectronicTicket;
	
EndProcedure

&AtClient
Procedure CreateATicket(Command)
	
	BasisParameters = New Structure;
	BasisParameters.Insert("Organization", Organization);
	BasisParameters.Insert("Employee", Employee);
	OpenForm("Document.ElectronicTicketTransaction.Form.DocumentForm", New Structure("Basis", BasisParameters));
	
EndProcedure

&AtClient
Procedure CreateSurcharge(Command)
	CreateOperationOfOperationWithElectronicTicket(PredefinedValue("Enum.TypesOfTicketOperations.ExtraPay"));
EndProcedure

&AtClient
Procedure CreateRefund(Command)
	CreateOperationOfOperationWithElectronicTicket(PredefinedValue("Enum.TypesOfTicketOperations.Return"));
EndProcedure

&AtClient
Procedure SetDateInterval(Command)
	
	Notification = New CallbackDescription("SetDateIntervalCompletion", ThisObject);
	TMCommonUseClient.EditPeriod(Period,, Notification);
	
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
Procedure GetBookingDetails(Command)
	
	
	Return;
	
EndProcedure


&AtClient
Procedure RegisterBusinessTrip(Command)
	
	
	Return;
	
EndProcedure

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

&AtClient
Procedure DocumentsListRefresh(Command)
	
	// DynamicListsSettings
	UpdateDocumentListDataWithTimeMeasurement("DocumentsList");
	// End DynamicListsSettings
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure CreateOperationOfOperationWithElectronicTicket(OperationType)
	
	CurrentData = Items.DocumentsList.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	OperationDescription = New Structure;
	OperationDescription.Insert("OperationType", OperationType);
	OperationDescription.Insert("ThisIsFullReturn", False);
	
	DataForCreatingTicketOperation = New Structure;
	DataForCreatingTicketOperation.Insert("ETicketData");
	DataForCreatingTicketOperation.Insert("OperationDescription", OperationDescription);
	DataForCreatingTicketOperation.Insert("ThisIsTicketSplit", False);
	
	BasisParameters = New Structure();
	BasisParameters.Insert("ElectronicTicket", CurrentData.Ref);
	BasisParameters.Insert("DataForCreatingTicketOperation", DataForCreatingTicketOperation);
	
	OpenForm("Document.ElectronicTicketTransaction.Form.ElectronicTicketTransactionForm", New Structure("Basis", BasisParameters));
	
EndProcedure

&AtServer
Procedure SetConditionalAppearance()
	
	StandardSubsystemsServer.SetDateFieldConditionalAppearance(ThisObject, "DocumentsList.Date", Items.Date.Name);
	
EndProcedure

&AtServer
Procedure SetDynamicListSelection()
	
	CommonClientServer.SetDynamicListFilterItem(
		DocumentsList,
		"Organization",
		Organization,
		DataCompositionComparisonType.Equal,,
		ValueIsFilled(Organization));
		
	CommonClientServer.SetDynamicListFilterItem(
		DocumentsList,
		"Employee",
		Employee,
		DataCompositionComparisonType.Equal,,
		ValueIsFilled(Employee));
		
	SetSelectionByPeriod();
	
	// DynamicListsSettings
	OperationsWithDocumentJournals.SetVisibilityOfDefaultUpdateSettingsGroup(ThisObject, "DocumentsList");
	// End DynamicListsSettings
	
EndProcedure

&AtServer
Procedure SetSelectionByPeriod()
	
	DocumentsList.Parameters.SetParameterValue("BeginOfPeriod", Period.StartDate);
	DocumentsList.Parameters.SetParameterValue("EndOfPeriod", Period.EndDate);
	// DynamicListsSettings
	OperationsWithDocumentJournals.SetVisibilityOfDefaultUpdateSettingsGroup(ThisObject, "DocumentsList");
	// End DynamicListsSettings
	
EndProcedure

&AtServer
Procedure SetVisibilityAvailability()
	
	If Not GetFunctionalOption("UseMultipleCompanies") Then
		Items.CompanyFilter.Visible = False;
	EndIf;
	
	Items.Department.Visible = GetFunctionalOption("UseBusinessUnits");
	
	
EndProcedure

&AtServer
Procedure ConfigureDocumentManagementButtons()
	
	VisibilityOfEditingCommands = AccessRight("Insert", Metadata.Documents.ElectronicTicketTransaction);
	
	If Not VisibilityOfEditingCommands Then
		
		EditingCommands = New Array;
		EditingCommands.Add(Items.CreateTicketList);
		EditingCommands.Add(Items.CreateSurchargeList);
		EditingCommands.Add(Items.CreateReturnList);
		
		
		EditingCommands.Add(Items.ListCopy);
		EditingCommands.Add(Items.ListSetClearADeletionMark);
		EditingCommands.Add(Items.ListPost);
		EditingCommands.Add(Items.ListUndoPosting);
		EditingCommands.Add(Items.ListContextMenuCopy);
		EditingCommands.Add(Items.ListContextMenuSetDeletionMark);
		EditingCommands.Add(Items.ListContextMenuPost);
		EditingCommands.Add(Items.ListContextMenuUndoPosting);
		
		For Each EditCommand In EditingCommands Do
			EditCommand.Visible = False;
		EndDo;
	EndIf;
	
	
EndProcedure

#Region DynamicListsSettings

&AtServer
Procedure InitiateDynamicListSettings()
	
	DocumentListParameters = New Array;
	
	ListParameterStructure = OperationsWithDocumentJournals.StructureOfFormationOfGroupOfUserSettingsForDynamicListOnForm();
	ListParameterStructure.ListName = "DocumentsList";
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

&AtClient
Procedure ShowSelectionOfDocumentSelectionOption()
	
	FilterOptionsList = FilterOptionsList();
	DescriptionOfOptionSelectionNotification = New CallbackDescription("WhenChoosingDocumentSelectionOption", ThisObject);
	FilterOptionsList.ShowChooseItem(
		DescriptionOfOptionSelectionNotification,
		NStr("vi = 'Phương án lọc chứng từ';
			|ru = 'Варианты отбора документов';
			|en = 'Document filter options'; fa = 'Document filter options';
			|it = 'Document filter options';
			|pl = 'Document filter options';
			|tr = 'Belge filtreleme seçenekleri'"),
		FilterOptionsList.FindByValue(CurrentOptionForSelectingDocuments));
	
EndProcedure

&AtClientAtServerNoContext
Function DefaultDocumentSelectionOption()
	Return "AllDocuments";
EndFunction

&AtClientAtServerNoContext
Function FilterOptionsList()
	
	FilterOptionsList = New ValueList;
	FilterOptionsList.Add(DefaultDocumentSelectionOption(), NStr("vi = 'Tất cả chứng từ của nhật ký';
																|ru = 'Все документы журнала';
																|en = 'All log documents'; fa = 'All log documents';
																|it = 'All log documents';
																|pl = 'All log documents';
																|tr = 'Günlükteki tüm belgeler'"));
	FilterOptionsList.Add("ElectronicTickets", NStr("vi = 'Vé điện tử';
													|ru = 'Электронные билеты';
													|en = 'Electronic tickets'; fa = 'Electronic tickets';
													|it = 'Electronic tickets';
													|pl = 'Electronic tickets';
													|tr = 'Elektronik biletler'"));
	FilterOptionsList.Add("ElectronicTicketsAndOfOperations", NStr("vi = 'Vé điện tử và giao dịch';
																	|ru = 'Электронные билеты и операции';
																	|en = 'Electronic tickets and transactions'; fa = 'Electronic tickets and transactions';
																	|it = 'Electronic tickets and transactions';
																	|pl = 'Electronic tickets and transactions';
																	|tr = 'Elektronik biletler ve işlemler'"));
	
	
	Return FilterOptionsList;
	
EndFunction

&AtClient
Procedure WhenChoosingDocumentSelectionOption(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	If Result.Value = CurrentOptionForSelectingDocuments Then
		Return;
	EndIf;
	
	ApplyDocumentSelectionOption(Result.Value);
	
EndProcedure

&AtServer
Procedure ApplyDocumentSelectionOption(DocumentSelectionOption)
	
	// Fixing the current version
	CurrentOptionForSelectingDocuments = DocumentSelectionOption;
	
	// Redrawing the creation buttons
	VisibilityOfEditingCommands = AccessRight("Insert", Metadata.Documents.ElectronicTicketTransaction);
	
	Items.CreateTicketList.Visible = VisibilityOfEditingCommands;
	Items.CreateSurchargeList.Visible = VisibilityOfEditingCommands;
	Items.CreateReturnList.Visible = VisibilityOfEditingCommands;
	
	
	ListOfDocumentTypes = New ValueList;
	ListOfDocumentTypes.Add(1);
	
	If CurrentOptionForSelectingDocuments = "ElectronicTickets" Then
		
		Items.CreateSurchargeList.Visible = False;
		Items.CreateReturnList.Visible = False;
		
		
	ElsIf CurrentOptionForSelectingDocuments = "ElectronicTicketsAndOfOperations" Then
		
		
		ListOfDocumentTypes.Add(2);
		ListOfDocumentTypes.Add(3);
		
		
	Else
		
		ListOfDocumentTypes.Add(2);
		ListOfDocumentTypes.Add(3);
		ListOfDocumentTypes.Add(4);
		
	EndIf;
	
	// Dynamic list selection
	CommonClientServer.SetDynamicListFilterItem(
		DocumentsList,
		"DocumentTypeId",
		ListOfDocumentTypes,
		DataCompositionComparisonType.InList,,
		True);
	
	// Hyperlink Formation
	ArrayOfLabelLines = New Array;
	ArrayOfLabelLines.Add(StrTemplate(NStr("vi = 'Hiển thị %1';
											|ru = 'Показаны %1';
											|en = '%1 are shown'; fa = '%1 are shown';
											|it = '%1 are shown';
											|pl = '%1 are shown';
											|tr = 'Gösterilenler  %1'"),
		Lower(FilterOptionsList().FindByValue(CurrentOptionForSelectingDocuments).Presentation)));
	ArrayOfLabelLines.Add("  ");
	ArrayOfLabelLines.Add(New FormattedString(NStr("vi = 'Tùy chỉnh';
													|ru = 'Настроить';
													|en = 'Set up'; fa = 'تنظیم';
													|it = 'Set up';
													|pl = 'Set up';
													|tr = 'Ayarla'"),,,,"ConfigureFilter"));
	//
	Items.HelpTextFilter.Title = New FormattedString(ArrayOfLabelLines);
	
EndProcedure

Procedure SetQueryTextToListOfDocuments()
	
	ArrayOfTexts = New Array;
	QueryText =
	"SELECT
	|	CAST(DocumentsRegistryOverridable.Ref AS Document.ElectronicTicketTransaction) AS Ref,
	|	CASE
	|		WHEN DocumentDataOverridable.OperationType = VALUE(Enum.TypesOfTicketOperations.ExtraPay)
	|			THEN &DocumentTypeSurcharge
	|		WHEN DocumentDataOverridable.OperationType = VALUE(Enum.TypesOfTicketOperations.Return)
	|			THEN &DocumentTypeReturn
	|		ELSE &DocumentTypeElectronicTicket
	|	END AS DocumentType,
	|	CASE
	|		WHEN DocumentDataOverridable.OperationType = VALUE(Enum.TypesOfTicketOperations.ExtraPay)
	|			THEN 2
	|		WHEN DocumentDataOverridable.OperationType = VALUE(Enum.TypesOfTicketOperations.Return)
	|			THEN 3
	|		ELSE 1
	|	END AS DocumentTypeId,
	|	DocumentDataOverridable.OperationType = VALUE(Enum.TypesOfTicketOperations.EmptyRef) AS ThisIsElectronicTicket,
	|	DocumentsRegistryOverridable.IBDocumentDate AS Date,
	|	CASE
	|		WHEN InformationAboutElectronicTicketOverridable.Ref IS NULL
	|			THEN DocumentsRegistryOverridable.SourceDocumentNumber
	|		ELSE DocumentDataOverridable.TicketNumber
	|	END AS Number,
	|	DocumentsRegistryOverridable.DeletionMark AS DeletionMark,
	|	DocumentsRegistryOverridable.Posted AS Posted,
	|	DocumentsRegistryOverridable.Organization AS Organization,
	|	CAST(DocumentsRegistryOverridable.StorageLocation.Key AS Catalog.Persons) AS Employee,
	|	CASE
	|		WHEN DocumentDataOverridable.OperationType = VALUE(Enum.TypesOfTicketOperations.EmptyRef)
	|			THEN DocumentDataOverridable.PassengerSFullName
	|		ELSE InformationAboutElectronicTicketOverridable.PassengerSFullName
	|	END AS PassengerSFullName,
	|	DocumentsRegistryOverridable.Partner AS Partner,
	|	DocumentsRegistryOverridable.Counterparty AS Counterparty,
	|	DocumentsRegistryOverridable.Department AS Department,
	|	DocumentsRegistryOverridable.EmployeeResponsible AS EmployeeResponsible,
	|	DocumentsRegistryOverridable.Comment AS Comment,
	|	DocumentsRegistryOverridable.BusinessOperation AS BusinessOperation,
	|	VALUETYPE(DocumentsRegistryOverridable.Ref) AS Type,
	|	DocumentsRegistryOverridable.Sum AS Sum,
	|	DocumentsRegistryOverridable.Currency AS Currency,
	|	DocumentDataOverridable.ServiceType AS ServiceType,
	|	DocumentDataOverridable.PostingDate AS BookingDate,
	|	DocumentDataOverridable.TripDetails AS TripDetails,
	|	CASE
	|		WHEN DocumentDataOverridable.OperationType
	|			IN (VALUE(Enum.TypesOfTicketOperations.ExtraPay), VALUE(Enum.TypesOfTicketOperations.Return))
	|			THEN UNDEFINED
	|		ELSE DocumentDataOverridable.State END AS State,
	|	DocumentDataOverridable.DocumentBasis AS Request,
	|	DocumentDataOverridable.PostingDate AS PostingDate,
	|	DocumentDataOverridable.ArrivalDate AS ArrivalDate,
	|	CASE
	|		WHEN DocumentsRegistryOverridable.Posted
	|			THEN 0
	|		WHEN DocumentsRegistryOverridable.DeletionMark
	|			THEN 1
	|		ELSE 2
	|	END AS CustomPicture,
	|	&CheckStatus AS CheckStatus,
	|	&CheckingIndicator AS CheckingIndicator,
	|	DocumentsRegistryOverridable.RefType AS RefType,
	|	DocumentsRegistryOverridable.RecordID AS RecordID
	|FROM
	|	InformationRegister.DocumentsRegistry AS DocumentsRegistryOverridable
	|		INNER JOIN Document.ElectronicTicketTransaction AS DocumentDataOverridable
	|		ON (DocumentDataOverridable.Ref = DocumentsRegistryOverridable.Ref)
	|		LEFT JOIN Document.ElectronicTicketTransaction AS InformationAboutElectronicTicketOverridable
	|		ON DocumentDataOverridable.ElectronicTicket = InformationAboutElectronicTicketOverridable.Ref
	|WHERE
	|	DocumentsRegistryOverridable.RefType IN(&ObjectIdOfOperationWithElectronicTicket)
	|	AND NOT DocumentDataOverridable.DeleteBookingType = VALUE(Enum.DeleteBookingTypes.Booking)
	|{WHERE
	|	(CAST(DocumentsRegistryOverridable.Ref AS Document.ElectronicTicketTransaction)).* AS Ref,
	|	DocumentsRegistryOverridable.Organization.* AS Organization,
	|	DocumentsRegistryOverridable.IBDocumentDate AS Date,
	|	DocumentsRegistryOverridable.SourceDocumentNumber AS Number,
	|	DocumentsRegistryOverridable.RefType AS RefType,
	|	DocumentsRegistryOverridable.BusinessOperation AS BusinessOperation,
	|	(CAST(DocumentsRegistryOverridable.StorageLocation.Key AS Catalog.Persons)).* AS Employee,
	|	DocumentsRegistryOverridable.Partner.* AS Partner,
	|	DocumentsRegistryOverridable.Counterparty.* AS Counterparty,
	|	DocumentsRegistryOverridable.Currency.* AS Currency,
	|	DocumentsRegistryOverridable.Department.* AS Department,
	|	DocumentsRegistryOverridable.EmployeeResponsible.* AS EmployeeResponsible,
	|	DocumentsRegistryOverridable.More AS PaymentPurposes,
	|	DocumentsRegistryOverridable.Comment AS Comment,
	|	DocumentsRegistryOverridable.Posted AS Posted,
	|	DocumentsRegistryOverridable.DeletionMark AS DeletionMark,
	|	(DocumentsRegistryOverridable.RecordingInAccountingDate BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|			OR &EndOfPeriod = DATETIME(1, 1, 1)
	|				AND DocumentsRegistryOverridable.RecordingInAccountingDate >= &BeginOfPeriod
	|				AND NOT DocumentsRegistryOverridable.AdditionalRecord)}";
	
	ArrayOfTexts.Add(QueryText);
	
	
	DocumentsList.QueryText = StrConcat(ArrayOfTexts, TMCommonUse.QuerySeparatorInJoin());
	
EndProcedure

#EndRegion

#EndRegion