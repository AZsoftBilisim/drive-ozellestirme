
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	DocumentTypesUsed = New Array();
	DocumentTypesUsed.Add(Type("DocumentRef.LoanAndDepositInterestCharge"));
	DocumentTypesUsed.Add(Type("DocumentRef.ReversingEntry"));
	
	// StandardSubsystems.AttachableCommands
	PlacementParameters = AttachableCommands.PlacementParameters();
	PlacementParameters.Sources = New TypeDescription(DocumentTypesUsed);
	PlacementParameters.CommandBar = Items.ListCommandBar;
	AttachableCommands.OnCreateAtServer(ThisObject, PlacementParameters);
	// End StandardSubsystems.AttachableCommands
	
	FillInFormDetailsWhenCreating();
	ConfigureDocumentManagementButtons();
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject, Items.GlobalCommandsGroup);
	// End IntegrationWith1CDocumentManagementSubsystem

	URL = "e1cib/list/Document.LoanAndDepositInterestCharge";

	FormEvents.OnCreateAtServer(ThisObject, Cancel, StandardProcessing);
	
	StandardSubsystemsServer.SetDateFieldConditionalAppearance(ThisObject, "List.Date", Items.Date.Name);
	
	List.Parameters.SetParameterValue("RefType",
		Common.MetadataObjectID("Document.LoanAndDepositInterestCharge"));
		
	TMCommonUse.ReplaceLinkFieldWithExpressByDocumentTypeConstruct(Items.List,
		BusinessTransactionsAndDocuments);

	// StandardSubsystems.ObjectsVersioning
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.ObjectsVersioning
	
EndProcedure

&AtServer
Procedure OnLoadDataFromSettingsAtServer(Settings)
	
	Period = Settings.Get("Period");
	SetSelectionByPeriod();
	
	If Parameters.Property("Organization") Then
		Organization = Parameters.Organization;
	EndIf;
	
	CommonClientServer.SetDynamicListFilterItem(
		List, 
		"Organization", 
		Organization, 
		DataCompositionComparisonType.Equal,
		, 
		ValueIsFilled(Organization));
	
	If Parameters.Property("Period") Then
		
		ListPeriod_ = Items.List.Period;
		ListPeriod_.Variant = StandardPeriodVariant.Month;
		ListPeriod_.StartDate = BegOfMonth(Parameters.Period);
		ListPeriod_.EndDate = EndOfMonth(Parameters.Period);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If EventName = "Conducting_Storno"
			Or EventName = "Write_ReversingEntry"
			Or EventName = "Write_LoanAndDepositInterestCharge" Then
		Items.List.Refresh();
	EndIf;
	
EndProcedure

&AtClient
Procedure NavigationProcessing(NavigationObject, StandardProcessing)
	
	If Not ValueIsFilled(NavigationObject) Then
		Return;
	EndIf;
	StandardProcessing = False;
	SelectTransitionObject(NavigationObject);
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands

EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure CompanyFilterOnChange(Item)
	
	CommonClientServer.SetDynamicListFilterItem(
		List, 
		"Organization", 
		Organization, 
		DataCompositionComparisonType.Equal,
		, 
		ValueIsFilled(Organization));
	
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
	
	StandardProcessing = False;
	TMCommonUseClient.ChangeElement(Item);
	
EndProcedure

&AtClient
Procedure ListBeforeRowChange(Item, Cancel)
	
	Cancel = True;
	TMCommonUseClient.ChangeElement(Item);
	
EndProcedure

&AtClient
Procedure ListBeforeAddRow(Item, Cancel, Copy, Parent, IsFolder, Parameter)
	
	If Copy Then
		TMCommonUseClient.CopyItem(Item);
	Else
		OpenForm("Document.LoanAndDepositInterestCharge.ObjectForm", , Items.List);
	EndIf;
	Cancel = True;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure ListPost(Command)
	
	TMCommonUseClient.PostDocuments(Items.List, Title);
	
EndProcedure

&AtClient
Procedure ListUndoPosting(Command)
	
	TMCommonUseClient.UndoPosting(Items.List, Title);
	
EndProcedure

&AtClient
Procedure ListCopy(Command)
	
	TMCommonUseClient.CopyItem(Items.List);
	
EndProcedure

&AtClient
Procedure SetDateInterval(Command)
	
	Notification = New CallbackDescription("SetDateIntervalCompletion", ThisObject);
	
	TMCommonUseClient.EditPeriod(Period, , Notification);
	
EndProcedure

&AtClient
Procedure Attachable_ContinueCommandExecutionAtServer(ExecutionParameters, AdditionalParameters) Export
	ExecuteCommandAtServer(ExecutionParameters);
EndProcedure

// IntegrationWith1CDocumentManagementSubsystem
&AtClient
Procedure Attachable_ExecuteIntegrationCommand(Command)
	
	IntegrationWith1CDocumentManagementCoreClient.ExecutePlugInIntegrationCommand(Command, ThisObject, Items.List);
	
EndProcedure
// End IntegrationWith1CDocumentManagementSubsystem

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisObject, Command);
	
EndProcedure

&AtClient
Procedure Attachable_CreateDocument(Command)
	
	StructureSelections = New Structure("Organization", Organization);
	TMCommonUseClient.CreateDocumentUsingCommand(Command.Name, StructureSelections);
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure SetClearDeletionMarkCompletion(Result,AdditionalParameters) Export
	Items.List.Refresh();
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
Procedure SelectTransitionObject(NavigationObject)
	
	Query = New Query;
	Query.SetParameter("NavigationObject",NavigationObject);
	Query.Text =
	"SELECT
	|	&RegisterDimensions
	|FROM
	|	InformationRegister.DocumentsRegistry AS DocumentsRegistry
	|WHERE
	|	DocumentsRegistry.Ref = &NavigationObject";
	
	RegisterDimensions = Metadata.InformationRegisters.DocumentsRegistry.Dimensions;
	ArrayOfDimensionsInRequest = New Array;
	For Each RegisterDimension In RegisterDimensions Do
		ArrayOfDimensionsInRequest.Add(RegisterDimension.Name);
	EndDo;	
	MeasurementsInRequest = StrConcat(ArrayOfDimensionsInRequest,"," + Chars.CR);
	
	Query.Text = StrReplace(Query.Text,"&RegisterDimensions",MeasurementsInRequest);
	Selection = Query.Execute().Select();
	
	If Selection.Next() Then
		StructureOfRecordKey = New Structure(MeasurementsInRequest);
		FillPropertyValues(StructureOfRecordKey,Selection);
		RecordKey = InformationRegisters.DocumentsRegistry.CreateRecordKey(StructureOfRecordKey);
		Items.List.CurrentRow = RecordKey;
	EndIf;
	
EndProcedure

&AtServer
Procedure ExecuteCommandAtServer(ExecutionParameters)
	AttachableCommands.ExecuteCommand(ThisObject, ExecutionParameters, Items.List);
EndProcedure

&AtServer
Procedure SetSelectionByPeriod()
	
	List.Parameters.SetParameterValue("BeginOfPeriod",
		Period.StartDate);
	List.Parameters.SetParameterValue("EndOfPeriod", 
		Period.EndDate);
	
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

#Region DocumentJournal

&AtServer
Procedure FillInFormDetailsWhenCreating()
	
	TableOfValuesAvailable = Documents.LoanAndDepositInterestCharge.InitializeBusinessTransactionsAndDocuments(
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
