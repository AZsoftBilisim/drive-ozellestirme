#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	EstablishPossibleValuesOfAcquiringAgreement();
	
	DocumentTypesUsed = New Array();
	DocumentTypesUsed.Add(Type("DocumentRef.BankReportOnAcquiringTransactions"));
	DocumentTypesUsed.Add(Type("DocumentRef.ReversingEntry"));
	
	FillInFormDetailsWhenCreating();
	ConfigureDocumentManagementButtons();
	
	// StandardSubsystems.AttachableCommands
	PlacementParameters = AttachableCommands.PlacementParameters();
	PlacementParameters.Sources = New TypeDescription(DocumentTypesUsed);
	PlacementParameters.CommandBar = Items.ListCommandBar;
	AttachableCommands.OnCreateAtServer(ThisObject, PlacementParameters);
	// End StandardSubsystems.AttachableCommands
	
	URL = "e1cib/list/Document.BankReportOnAcquiringTransactions";

	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject, Items.GlobalCommandsGroup);
	// End IntegrationWith1CDocumentManagementSubsystem
	
	List.Parameters.SetParameterValue("RefType",
		Common.MetadataObjectID("Document.BankReportOnAcquiringTransactions"));
		
	TMCommonUse.ReplaceLinkFieldWithExpressByDocumentTypeConstruct(Items.List,
		BusinessTransactionsAndDocuments);
	
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	
	StandardSubsystemsServer.SetDateFieldConditionalAppearance(ThisObject, "List.Date", Items.Date.Name);
	
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	
EndProcedure

&AtServer
Procedure OnLoadDataFromSettingsAtServer(Settings)
	
	Period = Settings.Get("Period");
	
	EstablishPossibleValuesOfAcquiringAgreement();
	SetDynamicListSelection_();
	
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
	
	OrganizingChangesWhenChangesAreMadeOnServer();
	
EndProcedure

&AtServer
Procedure OrganizingChangesWhenChangesAreMadeOnServer()
	
	EstablishPossibleValuesOfAcquiringAgreement();
	SetDynamicListSelection_();
	
EndProcedure

&AtClient
Procedure AcquiringAgreementSelectionOnChange(Item)
	
	SetDynamicListSelection_();
	
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
		StructureFilter = New Structure;
		StructureFilter.Insert("Organization", Organization);
		StructureFilter.Insert("AcquiringContract", AcquiringContract);
		
		ParametersStructure1 = New Structure("Basis", StructureFilter);
		OpenForm("Document.BankReportOnAcquiringTransactions.ObjectForm", ParametersStructure1, Items.List);
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
	
	FillingValues = New Structure("Organization, AcquiringContract", Organization, AcquiringContract);
	ParametersStructure = New Structure("FillingValues", FillingValues);
	OpenForm("Document.BankReportOnAcquiringTransactions.ObjectForm", ParametersStructure);
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure EstablishPossibleValuesOfAcquiringAgreement()
	
	Query = New Query("
	|SELECT ALLOWED
	|	CatalogData.Ref AS Ref
	|FROM
	|	Catalog.AcquiringContracts AS CatalogData
	|WHERE
	|	(CatalogData.Organization = &Organization OR &OrganizationNotFilledIn)
	|	AND (CatalogData.DetailedTransactionReconciliation
	|		OR CatalogData.CommissionPostingMethod = VALUE(Enum.MethodsOfAcquiringCommissionRecording.InReport))
	|");
	
	Query.SetParameter("Organization", Organization);
	Query.SetParameter("OrganizationNotFilledIn", Not ValueIsFilled(Organization));
	
	Items.AcquiringAgreementSelection.ChoiceList.LoadValues(
		Query.Execute().Unload().UnloadColumn("Ref"));
	
	If Items.AcquiringAgreementSelection.ChoiceList.FindByValue(AcquiringContract) = Undefined Then
		AcquiringContract = Undefined;
	EndIf;
	
EndProcedure

&AtServer
Procedure SetDynamicListSelection_()
	
	CommonClientServer.SetDynamicListFilterItem(
		List,
		"Organization",
		Organization,
		DataCompositionComparisonType.Equal,,
		ValueIsFilled(Organization));
		
	CommonClientServer.SetDynamicListFilterItem(
		List,
		"AcquiringContract",
		AcquiringContract,
		DataCompositionComparisonType.Equal,,
		ValueIsFilled(AcquiringContract));
		
	SetSelectionByPeriod();
	
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

&AtServer
Procedure FillInFormDetailsWhenCreating()
	
	TableOfValuesAvailable = Documents.BankReportOnAcquiringTransactions.InitializeBusinessTransactionsAndDocuments(
		BusinessTransactionsAndDocuments.Unload());
	
	BusinessTransactionsAndDocuments.Load(TableOfValuesAvailable);
	
EndProcedure

&AtServer
Procedure ConfigureDocumentManagementButtons()
	
	ParametersStructure = TMCommonUse.StructureOfSettingsForDocumentManagementButtons();
	ParametersStructure.Form 												= ThisObject;
	ParametersStructure.NameOfCreateGroup 									= "ListGroupCreateGenerated";
	ParametersStructure.GroupNameCreateContext							= "";
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
