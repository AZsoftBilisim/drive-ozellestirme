
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	DocumentTypesUsed = New Array();
	DocumentTypesUsed.Add(Type("DocumentRef.ARAPAdjustmentFinancialInstruments"));
	DocumentTypesUsed.Add(Type("DocumentRef.ReversingEntry"));
	
	FillInFormDetailsWhenCreating();
	ConfigureDocumentManagementButtons();
	If Parameters.Property("CurrentRow") And ValueIsFilled(Parameters.CurrentRow) Then
		Parameters.CurrentRow = InformationRegisters.DocumentsRegistry.DocumentRecordingKey(Parameters.CurrentRow);
	EndIf;
	
	// StandardSubsystems.AttachableCommands
	PlacementParameters = AttachableCommands.PlacementParameters();
	PlacementParameters.Sources = New TypeDescription(DocumentTypesUsed);
	PlacementParameters.CommandBar = Items.ListCommandBar;
	AttachableCommands.OnCreateAtServer(ThisObject, PlacementParameters);
	// End StandardSubsystems.AttachableCommands
	
	URL = "e1cib/list/Document.ARAPAdjustmentFinancialInstruments";
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject, Items.GlobalCommandsGroup);
	// End IntegrationWith1CDocumentManagementSubsystem
	
	List.Parameters.SetParameterValue("RefType",
		Common.MetadataObjectID("Document.ARAPAdjustmentFinancialInstruments"));
		
	TMCommonUse.ReplaceLinkFieldWithExpressByDocumentTypeConstruct(Items.List,
		Metadata.Documents.ARAPAdjustmentFinancialInstruments.FullName());
	
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	
	StandardSubsystemsServer.SetDateFieldConditionalAppearance(ThisObject, "List.Date", Items.Date.Name);
	
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	
EndProcedure

&AtServer
Procedure OnLoadDataFromSettingsAtServer(Settings)
	
	Organization = Settings.Get("Organization");
	Counterparty = Settings.Get("Counterparty");
	ContractKind = Settings.Get("ContractKind");
	Period = Settings.Get("Period");
	
	CommonClientServer.SetDynamicListFilterItem(
		List, "Organization", Organization, DataCompositionComparisonType.Equal,, ValueIsFilled(Organization));
	CommonClientServer.SetDynamicListFilterItem(
		List, "Counterparty", Counterparty, DataCompositionComparisonType.Equal,, ValueIsFilled(Counterparty));
	CommonClientServer.SetDynamicListFilterItem(
		List, "ContractKind", ContractKind, DataCompositionComparisonType.Equal,, ValueIsFilled(ContractKind));
	
	SetSelectionByPeriod();
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If EventName = "Conducting_Storno"
			Or EventName = "Write_ReversingEntry"
			Or EventName = "Write_ARAPAdjustmentFinancialInstruments" Then
		Items.List.Refresh();
	EndIf;

EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure CompanyFilterOnChange(Item)
	
	CommonClientServer.SetDynamicListFilterItem(
		List, "Organization", Organization, DataCompositionComparisonType.Equal,, ValueIsFilled(Organization));
	
EndProcedure

&AtClient
Procedure CounterpartySelection_OnChange(Item)
	
	CommonClientServer.SetDynamicListFilterItem(
		List, "Counterparty", Counterparty, DataCompositionComparisonType.Equal,, ValueIsFilled(Counterparty));
	
EndProcedure

&AtClient
Procedure NatureOfTheContractSelectionOnChange(Item)
	
	CommonClientServer.SetDynamicListFilterItem(
		List, "ContractKind", ContractKind, DataCompositionComparisonType.Equal,, ValueIsFilled(ContractKind));
		
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersList

&AtClient
Procedure ListOnActivateRow(Item)
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

&AtClient
Procedure ListSelection(Item, RowSelected, Field, StandardProcessing)
	
	StandardProcessing = False;
	TMCommonUseClient.ChangeElement(Item);
	
EndProcedure

&AtClient
Procedure ListBeforeAddRow(Item, Cancel, Copy, Parent, IsFolder, Parameter)	
	
	If Copy Then
		TMCommonUseClient.CopyItem(Item);
	Else
		OpenForm("Document.ARAPAdjustmentFinancialInstruments.ObjectForm", , Items.List);
	EndIf;
	Cancel = True;
	
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
Procedure ListPost(Command)
	
	TMCommonUseClient.PostDocuments(Items.List, Title);
	
EndProcedure

&AtClient
Procedure ListBeforeDeleteRow(Item, Cancel)
	Cancel = True;
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

&AtServer
Procedure ExecuteCommandAtServer(ExecutionParameters)
	AttachableCommands.ExecuteCommand(ThisObject, ExecutionParameters, Items.List);
EndProcedure

&AtClient
Procedure Attachable_ContinueCommandExecutionAtServer(ExecutionParameters, AdditionalParameters) Export
	ExecuteCommandAtServer(ExecutionParameters);
EndProcedure

// StandardSubsystems.AttachableCommands
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
	
	StructureSelections = New Structure("Organization, Counterparty", Organization, Counterparty);
	TMCommonUseClient.CreateDocumentUsingCommand(Command.Name, StructureSelections);
	
EndProcedure

#EndRegion

#Region Private

#Region DocumentJournal

&AtServer
Procedure FillInFormDetailsWhenCreating()
	
	TableOfValuesAvailable = Documents.ARAPAdjustmentFinancialInstruments.InitializeBusinessTransactionsAndDocuments(
		BusinessTransactionsAndDocuments.Unload());
	
	BusinessTransactionsAndDocuments.Load(TableOfValuesAvailable);
	
EndProcedure

&AtServer
Procedure ConfigureDocumentManagementButtons()
	
	ParametersStructure = TMCommonUse.StructureOfSettingsForDocumentManagementButtons();
	ParametersStructure.Form 												= ThisObject;
	ParametersStructure.NameOfCreateGroup                                    = "ListGroupCreateGenerated";
	ParametersStructure.GroupNameCreateContext                            = "ListGroupCreateGeneratedByContext";
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

#EndRegion
