//@strict-types

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If ExchangePlans.MasterNode() <> Undefined Then
		
		Items.List.ChangeRowSet = False;
		
	EndIf;
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject, Items.GlobalCommandsGroup);
	// End IntegrationWith1CDocumentManagementSubsystem
	
	If Not GetFunctionalOption("UseMultipleCompanies") Then
		
		CommonClientServer.SetFormItemProperty(
			Items, "FilterOrganization", "Visible", False);
		
	EndIf;
	
	QuickFilterStructure = Undefined;
	Parameters.Property("QuickFilterStructure", QuickFilterStructure);
	
	ListSelectionsClientServer.SelectionByListValueWhenCreatedOnServer(
		List, "Organization", Organization, QuickFilterStructure);
	CommonClientServer.SetFormItemProperty(
		Items, "Organization", "Visible", Not ValueIsFilled(Organization));
	
	ListSelectionsClientServer.SelectionByListValueWhenCreatedOnServer(
		List, "RebateKind", RebateKind, QuickFilterStructure);
	CommonClientServer.SetFormItemProperty(
		Items, "RebateKind", "Visible", Not ValueIsFilled(RebateKind));
	
	ListSelectionsClientServer.SelectionByListValueWhenCreatedOnServer(
		List, "Status", Status, QuickFilterStructure);
	CommonClientServer.SetFormItemProperty(
		Items, "Status", "Visible", Not ValueIsFilled(Status));
	
	ListSelectionsClientServer.SelectionByListValueWhenCreatedOnServer(
		List, "EmployeeResponsible", EmployeeResponsible, QuickFilterStructure);
	CommonClientServer.SetFormItemProperty(
		Items, "EmployeeResponsible", "Visible", Not ValueIsFilled(EmployeeResponsible));
	
	SetEditingViewMode();
	
	FormEvents.OnCreateAtServer(ThisObject, Cancel, StandardProcessing);
	
	SetConditionalAppearance();
	
EndProcedure

&AtServer
Procedure OnLoadDataFromSettingsAtServer(Settings)
	
	ListSelectionsClientServer.SelectionByListValueWhenLoadingFromSettings(
		List, "Organization", Organization, QuickFilterStructure, Settings);
	ListSelectionsClientServer.SelectionByListValueWhenLoadingFromSettings(
		List, "RebateKind", RebateKind, QuickFilterStructure, Settings);
	ListSelectionsClientServer.SelectionByListValueWhenLoadingFromSettings(
		List, "Status", Status, QuickFilterStructure, Settings);
	ListSelectionsClientServer.SelectionByListValueWhenLoadingFromSettings(
		List, "EmployeeResponsible", EmployeeResponsible, QuickFilterStructure, Settings);
	
	SetEditingViewMode();
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure FilterOrganizationOnChange(Item)
	
	CompanyIsFull = ValueIsFilled(Organization);
	
	CommonClientServer.SetDynamicListFilterItem(
		List,
		"Organization",
		Organization,
		DataCompositionComparisonType.Equal,
		,
		CompanyIsFull);
	
	CommonClientServer.SetFormItemProperty(
		Items, "Organization", "Visible", Not CompanyIsFull);
	
EndProcedure

&AtClient
Procedure FilterRebateKindOnChange(Item)
	
	RebateKindIsFilledIn = ValueIsFilled(RebateKind);
	
	CommonClientServer.SetDynamicListFilterItem(
		List,
		"RebateKind",
		RebateKind,
		DataCompositionComparisonType.Equal,
		,
		RebateKindIsFilledIn);
	
	CommonClientServer.SetFormItemProperty(
		Items, "RebateKind", "Visible", Not RebateKindIsFilledIn);
	
EndProcedure

&AtClient
Procedure FilterStatusOnChange(Item)
	
	StatusFilledIn = ValueIsFilled(Status);
	
	CommonClientServer.SetDynamicListFilterItem(
		List,
		"Status",
		Status,
		DataCompositionComparisonType.Equal,
		,
		StatusFilledIn);
	
	CommonClientServer.SetFormItemProperty(
		Items, "Status", "Visible", Not StatusFilledIn);
	
EndProcedure

&AtClient
Procedure FilterEmployeeResponsibleOnChange(Item)
	
	ResponsiblePersonFilledIn = ValueIsFilled(EmployeeResponsible);
	
	CommonClientServer.SetDynamicListFilterItem(
		List,
		"EmployeeResponsible",
		EmployeeResponsible,
		DataCompositionComparisonType.Equal,
		,
		ResponsiblePersonFilledIn);
	
	CommonClientServer.SetFormItemProperty(
		Items, "EmployeeResponsible", "Visible", Not ResponsiblePersonFilledIn);
	
EndProcedure

&AtClient
Procedure CurrentEditionsOnChange(Item)
	
	SetEditingViewMode();
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersList

&AtClient
Procedure ListSelection(Item, RowSelected, Field, StandardProcessing)
	
	If CurrentEditions Then
		
		StandardProcessing = False;
		CurrentData = Items.List.CurrentData;
		
		ParametersStructure = New Structure;
		ParametersStructure.Insert("Key", FinalDocument(CurrentData.Ref));
		OpenForm("Document.ConditionsOfCustomerRebates.Form.DocumentForm", ParametersStructure);
		
	EndIf;	
	
EndProcedure

&AtClient
Procedure ListOnActivateRow(Item)
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

// StandardSubsystems.AttachableCommands

// Parameters:
//   Command - FormCommand - executed command
//
&AtClient
Procedure Attachable_ExecuteCommand(Command)
	
	AttachableCommandsClient.StartCommandExecution(ThisObject, Command, Items.List);
	
EndProcedure

// End StandardSubsystems.AttachableCommands

// IntegrationWith1CDocumentManagementSubsystem

// Parameters:
//   Command - FormCommand - executed command
//
&AtClient
Procedure Attachable_ExecuteIntegrationCommand(Command)
	
	IntegrationWith1CDocumentManagementCoreClient.ExecutePlugInIntegrationCommand(Command, ThisObject, Items.List);
	
EndProcedure

// End IntegrationWith1CDocumentManagementSubsystem

#EndRegion

#Region Private

#Region Other

&AtServer
Procedure SetConditionalAppearance()
	
	RebatesServer.SetStatusFormalization(ThisObject);
	StandardSubsystemsServer.SetDateFieldConditionalAppearance(ThisObject);
	
EndProcedure

&AtServer
Procedure SetEditingViewMode()
	
	CommonClientServer.SetDynamicListParameter(
		List, "CurrentEditions", CurrentEditions);
	
	CommonClientServer.SetDynamicListFilterItem(
		List, "Patch", False,,, CurrentEditions);
	
	CommonClientServer.SetFormItemProperty(
		Items, "Patch", "Visible", Not CurrentEditions);
		
EndProcedure

&AtServerNoContext
Function FinalDocument(Val DocumentRef)
	
	Result = DocumentRef;
	
	DocumentData = DocumentCorrection.LastCorrectiveDocument(DocumentRef); // DocumentRef.ConditionsOfCustomerRebates
	If DocumentData <> Undefined Then
		
		Result = DocumentData.Ref;
		
	EndIf;
	
	Return Result;
	
EndFunction

#EndRegion

#Region StandardSubsystems_PlugInCommands

// StandardSubsystems.AttachableCommands

// The Attachable one continues to execute the Commands on the server.
// 
// Parameters:
//  ExecutionParameters - Structure -
//  AdditionalParameters - Structure -
//
&AtClient
Procedure Attachable_ContinueCommandExecutionAtServer(ExecutionParameters, AdditionalParameters) Export
	
	ExecuteCommandAtServer(ExecutionParameters);
	
EndProcedure

&AtServer
Procedure ExecuteCommandAtServer(ExecutionParameters)
	
	AttachableCommands.ExecuteCommand(ThisObject, ExecutionParameters, Items.List);
	
EndProcedure

&AtClient
Procedure Attachable_UpdateCommands()
	
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Items.List);
	
EndProcedure

// End StandardSubsystems.AttachableCommands

#EndRegion

#EndRegion