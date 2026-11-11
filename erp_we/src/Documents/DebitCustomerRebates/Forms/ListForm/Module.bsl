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
	
	If Not GetFunctionalOption("UseApprovalOfCustomerRebatesWriteOffs") Then
		
		CommonClientServer.SetFormItemProperty(
			Items, "FilterStatus", "Visible", False);
		
	EndIf;
	
	If Not GetFunctionalOption("UseMultipleCompanies") Then
		
		CommonClientServer.SetFormItemProperty(
			Items, "FilterOrganization", "Visible", False);
		
	EndIf;
	
	QuickFilterStructure = Undefined;
	Parameters.Property("QuickFilterStructure", QuickFilterStructure);
	
	ListSelectionsClientServer.SelectionByListValueWhenCreatedOnServer(
		List, "Organization", Organization, QuickFilterStructure);
	ListSelectionsClientServer.SelectionByListValueWhenCreatedOnServer(
		List, "Counterparty", Counterparty, QuickFilterStructure);
	ListSelectionsClientServer.SelectionByListValueWhenCreatedOnServer(
		List, "Status", Status, QuickFilterStructure);
	
	SetConditionalAppearance();
	
	FormEvents.OnCreateAtServer(ThisObject, Cancel, StandardProcessing);
	
EndProcedure

&AtServer
Procedure OnLoadDataFromSettingsAtServer(Settings)
	
	ListSelectionsClientServer.SelectionByListValueWhenLoadingFromSettings(
		List, "Organization", Organization, QuickFilterStructure, Settings);
	ListSelectionsClientServer.SelectionByListValueWhenLoadingFromSettings(
		List, "Counterparty", Counterparty, QuickFilterStructure, Settings);
	ListSelectionsClientServer.SelectionByListValueWhenLoadingFromSettings(
		List, "Status", Status, QuickFilterStructure, Settings);
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure FilterOrganizationOnChange(Item)
	
	CommonClientServer.SetDynamicListFilterItem(
		List,
		"Organization",
		Organization,
		DataCompositionComparisonType.Equal,
		,
		ValueIsFilled(Organization));
	
EndProcedure

&AtClient
Procedure FilterCounterpartyOnChange(Item)
	
	CommonClientServer.SetDynamicListFilterItem(
		List,
		"Counterparty",
		Counterparty,
		DataCompositionComparisonType.Equal,
		,
		ValueIsFilled(Counterparty));
	
EndProcedure

&AtClient
Procedure FilterStatusOnChange(Item)
	
	CommonClientServer.SetDynamicListFilterItem(
		List,
		"Status",
		Status,
		DataCompositionComparisonType.Equal,
		,
		ValueIsFilled(Status));
		
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersList

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
	
	IntegrationWith1CDocumentManagementCoreClient.ExecutePlugInIntegrationCommand(
		Command, ThisObject, Items.List);
	
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
