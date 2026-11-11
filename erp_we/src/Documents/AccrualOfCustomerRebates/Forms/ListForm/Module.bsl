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
		List, "TermDocument", TermDocument, QuickFilterStructure);
	ListSelectionsClientServer.SelectionByListValueWhenCreatedOnServer(
		List, "Organization", Organization, QuickFilterStructure);
	ListSelectionsClientServer.SelectionByListValueWhenCreatedOnServer(
		List, "Counterparty", Counterparty, QuickFilterStructure);
	ListSelectionsClientServer.SelectionByListValueWhenCreatedOnServer(
		List, "Partner", Partner, QuickFilterStructure);
	
	FormEvents.OnCreateAtServer(ThisObject, Cancel, StandardProcessing);
	
	SetConditionalAppearance();
	
	HasRightToAdd = AccessRight("Insert", Metadata.Documents.AccrualOfCustomerRebates);
	If HasRightToAdd Then
		
		CommonClientServer.SetFormItemProperty(
			Items,
			"ListCreate",
			"Visible",
			False);
		
	Else
		
		ItemsNames = New Array; // Array of String
		ItemsNames.Add("CreateNewList");
		ItemsNames.Add("ListGroupDocumentCreation");
		
		TMCommonUseClientServer.SetPropertyOfFormElements(
			Items,
			ItemsNames,
			"Visible",
			False);
		
	EndIf;
	
EndProcedure

&AtServer
Procedure OnLoadDataFromSettingsAtServer(Settings)
	
	ListSelectionsClientServer.SelectionByListValueWhenLoadingFromSettings(
		List, "TermDocument", TermDocument, QuickFilterStructure, Settings);
	ListSelectionsClientServer.SelectionByListValueWhenLoadingFromSettings(
		List, "Organization", Organization, QuickFilterStructure, Settings);
	ListSelectionsClientServer.SelectionByListValueWhenLoadingFromSettings(
		List, "Counterparty", Counterparty, QuickFilterStructure, Settings);
	ListSelectionsClientServer.SelectionByListValueWhenLoadingFromSettings(
		List, "Partner", Partner, QuickFilterStructure, Settings);
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure FilterOrganizationOnChange(Item)
	
	FilterOrganizationOnChangeServer();
	
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
Procedure FilterPartnerOnChange(Item)
	
	CommonClientServer.SetDynamicListFilterItem(
		List,
		"Partner",
		Partner,
		DataCompositionComparisonType.Equal,
		,
		ValueIsFilled(Partner));
		
EndProcedure

&AtClient
Procedure FilterTermDocumentOnChange(Item)
	
	SetSelectionAccordingToConditionsDocument(ThisObject);
	
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
	
	IntegrationWith1CDocumentManagementCoreClient.ExecutePlugInIntegrationCommand(Command, ThisObject, Items.List);
	
EndProcedure

// End IntegrationWith1CDocumentManagementSubsystem

&AtClient
Procedure GroupDocumentCreation(Command)
	
	OpenForm("DataProcessor.BulkAccrualOfCustomerRebates.Form");
	
EndProcedure

#EndRegion

#Region Private

#Region EventHandlersForFormHeaderElementsAuxiliary

&AtServer
Procedure FilterOrganizationOnChangeServer()
	
	CompanyIsSpecified = ValueIsFilled(Organization);
	
	CommonClientServer.SetDynamicListFilterItem(
		List,
		"Organization",
		Organization,
		DataCompositionComparisonType.Equal,
		,
		CompanyIsSpecified);
	
	ChoiceParameterLinks = New Array(); // Array of ChoiceParameterLink
	If CompanyIsSpecified Then
		
		NewLink = New ChoiceParameterLink(
			"Filter.Organization",
			"Organization",
			LinkedValueChangeMode.DontChange);
		ChoiceParameterLinks.Add(NewLink);
		
		If Not TermDocument.IsEmpty() Then
			
			DocumentOrganization = Common.ObjectAttributeValue(TermDocument, "Organization");
			If DocumentOrganization <> Organization Then
				
				TermDocument = Documents.ConditionsOfCustomerRebates.EmptyRef();
				SetSelectionAccordingToConditionsDocument(ThisObject);
				
			EndIf;
			
		EndIf;
		
	EndIf;
	
	Items.FilterTermDocument.ChoiceParameterLinks = New FixedArray(ChoiceParameterLinks);
	
EndProcedure

&AtClientAtServerNoContext
Procedure SetSelectionAccordingToConditionsDocument(Form)
	
	CommonClientServer.SetDynamicListFilterItem(
		Form.List,
		"TermDocument",
		Form.TermDocument,
		DataCompositionComparisonType.Equal,
		,
		ValueIsFilled(Form.TermDocument));
		
EndProcedure

#EndRegion

#Region Other

&AtServer
Procedure SetConditionalAppearance()
	
	StandardSubsystemsServer.SetDateFieldConditionalAppearance(ThisObject);
	
	ObjectManager = Documents.AccrualOfCustomerRebates;
	ObjectManager.SetConditionalAppearanceOfCounterpartyList(ConditionalAppearance, Items);
	ObjectManager.SetConditionalAppearanceOfPartnerList(ConditionalAppearance, Items);
	
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