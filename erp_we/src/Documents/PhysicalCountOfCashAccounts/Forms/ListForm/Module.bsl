#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	Items.CompanyFilter.Visible = GetFunctionalOption("UseMultipleCompanies");
	
	DocumentTypesUsed = New Array();
	DocumentTypesUsed.Add(Type("DocumentRef.PhysicalCountOfCashAccounts"));
	DocumentTypesUsed.Add(Type("DocumentRef.ReversingEntry"));
	
	FillInFormDetailsWhenCreating();
	ConfigureDocumentManagementButtons();
	
	// StandardSubsystems.AttachableCommands
	PlacementParameters = AttachableCommands.PlacementParameters();
	PlacementParameters.Sources = New TypeDescription(DocumentTypesUsed);
	PlacementParameters.CommandBar = Items.ListCommandBar;
	AttachableCommands.OnCreateAtServer(ThisObject, PlacementParameters);
	// End StandardSubsystems.AttachableCommands
	
	URL = "e1cib/list/Document.PhysicalCountOfCashAccounts";

	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject, Items.GlobalCommandsGroup);
	// End IntegrationWith1CDocumentManagementSubsystem
	
	
	List.Parameters.SetParameterValue("RefType",
		Common.MetadataObjectID("Document.PhysicalCountOfCashAccounts"));
		
	TMCommonUse.ReplaceLinkFieldWithExpressByDocumentTypeConstruct(Items.List,
		Metadata.Documents.PhysicalCountOfCashAccounts.FullName());
	
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	
	StandardSubsystemsServer.SetDateFieldConditionalAppearance(ThisObject, "List.Date", Items.Date.Name);
	
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	
EndProcedure

&AtServer
Procedure OnLoadDataFromSettingsAtServer(Settings)
	
	Organization = Settings.Get("Organization");
	Period = Settings.Get("Period");
	
	
	SetDynamicListSelection();
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	
	Return;
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	
	If EventName = "Conducting_Storno"
			Or EventName = "Write_ReversingEntry"
			Or EventName = "Write_BankReportOnAcquiringTransactions" Then
		Items.List.Refresh();
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure CompanyFilterOnChange(Item)
	
	CompanyFilterOnChangeServer();
	
EndProcedure

&AtServer
Procedure CompanyFilterOnChangeServer()
	
	
	SetDynamicListSelection();
	
EndProcedure

&AtClient
Procedure CashRegisterSelectionStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	
	
EndProcedure


&AtClient
Procedure CashRegisterSelectionClearing(Item, StandardProcessing)
	
	
	Return;
	
EndProcedure

&AtClient
Procedure CashRegisterSelectionChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	
	Return;
	
EndProcedure



#EndRegion

#Region FormTableItemsEventHandlersList

&AtClient
Procedure ListBeforeDeleteRow(Item, Cancel)
	
	Cancel = True;
	DescriptionOfNotificationAfterMarkingDeletion = New CallbackDescription("SetClearDeletionMarkCompletion",ThisObject);
	TMCommonUseClient.SetDeletionMark(Item, Title, DescriptionOfNotificationAfterMarkingDeletion);

EndProcedure

&AtClient
Procedure ListOnActivateRow(Item)
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

&AtClient
Procedure ListSelection(Item, RowSelected, Field, StandardProcessing)
	
	If Field = Items.StatusPresentation Then
	Else
		StandardProcessing = False;
		TMCommonUseClient.ChangeElement(Item);
	EndIf;
	
EndProcedure

&AtClient
Procedure ListBeforeRowChange(Item, Cancel)
	
	Cancel = True;
	TMCommonUseClient.ChangeElement(Item);
	
EndProcedure

&AtClient
Procedure ListUndoPosting(Command)
	
	TMCommonUseClient.UndoPosting(Items.List, Title);
	
EndProcedure

&AtClient
Procedure ListBeforeAddRow(Item, Cancel, Copy, Parent, IsFolder, Parameter)
	
	If Copy Then
		TMCommonUseClient.CopyItem(Item);
	Else
		StructureFilter = New Structure;
		StructureFilter.Insert("Organization", Organization);
		StructureFilter.Insert("CashBook", CashBook);
		
		ParametersStructure1 = New Structure("Basis", StructureFilter);
		OpenForm("Document.PhysicalCountOfCashAccounts.ObjectForm", ParametersStructure1, Items.List);
	EndIf;
	Cancel = True;
	
EndProcedure

&AtClient
Procedure ListCreate(Command)
	
	FillingValues = New Structure("Organization, CashBook", Organization, CashBook);
	ParametersStructure = New Structure("FillingValues", FillingValues);
	OpenForm("Document.PhysicalCountOfCashAccounts.ObjectForm", ParametersStructure);
	
EndProcedure

&AtClient
Procedure ListCopy(Command)
	
	TMCommonUseClient.CopyItem(Items.List);
	
EndProcedure

&AtClient
Procedure ListPost(Command)
	
	TMCommonUseClient.PostDocuments(Items.List, Title);
	
EndProcedure

&AtClient
Procedure ListSetClearADeletionMark(Command)
	
	TMCommonUseClient.SetDeletionMark(Items.List, Title);
	
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

&AtServer
Procedure SetSelectionByPeriod()
	
	List.Parameters.SetParameterValue("BeginOfPeriod",
		Period.StartDate);
	List.Parameters.SetParameterValue("EndOfPeriod", 
		Period.EndDate);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

// StandardSubsystems.AttachableCommands
&AtServer
Procedure ExecuteCommandAtServer(ExecutionParameters)
	AttachableCommands.ExecuteCommand(ThisObject, ExecutionParameters, Items.List);
EndProcedure


&AtClient
Procedure Attachable_ContinueCommandExecutionAtServer(ExecutionParameters, AdditionalParameters) Export
	ExecuteCommandAtServer(ExecutionParameters);
EndProcedure


&AtClient
Procedure Attachable_ExecuteCommand(Command)
	AttachableCommandsClient.StartCommandExecution(ThisObject, Command, Items.List);
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

&AtClient
Procedure Attachable_CreateDocument(Command)
	
	FillingValues = New Structure("Organization, CashBook", Organization, CashBook);
	ParametersStructure = New Structure("FillingValues", FillingValues);
	OpenForm("Document.PhysicalCountOfCashAccounts.ObjectForm", ParametersStructure);
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure SetClearDeletionMarkCompletion(Result,AdditionalParameters) Export
	Items.List.Refresh();
EndProcedure


&AtServer
Procedure SetDynamicListSelection()
	
	CommonClientServer.SetDynamicListFilterItem(
		List, "Organization", Organization, DataCompositionComparisonType.Equal,, ValueIsFilled(Organization));
		
	CommonClientServer.SetDynamicListFilterItem(
		List, "CashBook", CashBook, DataCompositionComparisonType.Equal,, CashBook <> Undefined);
		
	SetSelectionByPeriod();
	
EndProcedure

&AtServer
Procedure FillInFormDetailsWhenCreating()
	
	TableOfValuesAvailable = Documents.PhysicalCountOfCashAccounts.InitializeBusinessTransactionsAndDocuments(
		BusinessTransactionsAndDocuments.Unload());
	
	BusinessTransactionsAndDocuments.Load(TableOfValuesAvailable);
	
EndProcedure

&AtServer
Procedure ConfigureDocumentManagementButtons()
	
	ParametersStructure = TMCommonUse.StructureOfSettingsForDocumentManagementButtons();
	ParametersStructure.Form = ThisObject;
	ParametersStructure.NameOfCreateGroup = "ListGroupCreateGenerated";
	ParametersStructure.GroupNameCreateContext = "";
	ParametersStructure.NameOfCopyButton = "ListCopy";
	ParametersStructure.NameOfCopyContextMenuButton = "ListContextMenuCopy";
	ParametersStructure.ChangeButtonName = "ListChange";
	ParametersStructure.NameOfChangeContextMenuButton = "ListContextMenuChange";
	ParametersStructure.ButtonNamePost = "ListPost";
	ParametersStructure.NameOfHoldContextMenuButton = "ListContextMenuPost";
	ParametersStructure.NameOfCancelEventButton = "ListUndoPosting";
	ParametersStructure.NameOfCancelButtonIsContextMenu = "ListContextMenuUndoPosting";
	ParametersStructure.NameOfMarkDeleteButton = "ListSetDeletionMark";
	ParametersStructure.ButtonNameMarkDeleteContextMenu = "ListContextMenuSetDeletionMark";
	
	TMCommonUse.ConfigureDocumentManagementButtons(ParametersStructure);
	
EndProcedure

#EndRegion