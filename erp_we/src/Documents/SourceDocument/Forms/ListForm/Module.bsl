#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	CanBeEdited = AccessRight("Edit", Metadata.Documents.SourceDocument);
	Items.ListContextMenuChangeSelectedItems.Visible = CanBeEdited;
	
	StandardSubsystemsServer.SetDateFieldConditionalAppearance(ThisObject, "List.Date", Items.Date.Name);
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject);
	// End IntegrationWith1CDocumentManagementSubsystem
	
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure FilterOrganizationOnChange(Item)

	ListSelectionsClientServer.ChangeListSelectionElement(
		List, 
		"Organization", 
		FilterOrganization, 
		ValueIsFilled(FilterOrganization));

EndProcedure

&AtClient
Procedure FilterCounterpartyOnChange(Item)
	
	CommonClientServer.SetDynamicListFilterItem(
		List,
		"Counterparty", 
		FilterCounterparty, 
		DataCompositionComparisonType.Equal, 
		, 
		ValueIsFilled(FilterCounterparty));
		
EndProcedure

&AtClient
Procedure FilterSourceDocumentTypeOnChange(Item)
	
	FilterSourceDocumentTypeOnChangeServer();
	
EndProcedure

&AtClient
Procedure FilterPartnerOnChange(Item)
	
	FilterPartnerOnChangeServer();
	
EndProcedure

&AtClient
Procedure ChangeSelectedItems(Command)
	
	BatchEditObjectsClient.ChangeSelectedItems(Items.List);

EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure FilterSourceDocumentTypeOnChangeServer()
	
	ListSelectionsClientServer.ChangeListSelectionElement(
		List, 
		"SourceDocumentType", 
		FilterSourceDocumentType, 
		ValueIsFilled(FilterSourceDocumentType));
	
	SetPartnerSelectionParameters();
	
EndProcedure

&AtServer
Procedure FilterPartnerOnChangeServer()
	
	If FilterPartner = Catalogs.Partners.OurEnterprise Then
		If TypeOf(FilterCounterparty) <> Type("CatalogRef.Companies") Then
			FilterCounterparty = Catalogs.Companies.EmptyRef();
		EndIf;
	Else
		If TypeOf(FilterCounterparty) <> Type("CatalogRef.Counterparties") Then
			FilterCounterparty = Catalogs.Counterparties.EmptyRef();
		EndIf;
		PartnersAndCounterparties.FillInPartnerSDefaultCounterparty(FilterPartner, FilterCounterparty);
	EndIf;
	
	CommonClientServer.SetDynamicListFilterItem(
		List,
		"Counterparty", 
		FilterCounterparty, 
		DataCompositionComparisonType.Equal, 
		, 
		ValueIsFilled(FilterCounterparty));
	
	CommonClientServer.SetDynamicListFilterItem(
		List,
		"Partner", 
		FilterPartner, 
		DataCompositionComparisonType.Equal, 
		, 
		ValueIsFilled(FilterPartner));

EndProcedure

&AtServer
Procedure SetPartnerSelectionParameters()
	
	ParametersArray = New Array;
	If FilterSourceDocumentType = Enums.SourceDocumentTypes.PaymentFromCustomer
		 Or FilterSourceDocumentType = Enums.SourceDocumentTypes.SaleToCustomer
		 Or FilterSourceDocumentType = Enums.SourceDocumentTypes.SaleAdjustment Then
		ParametersArray.Add(New ChoiceParameter("Filter.Client", True));
	ElsIf FilterSourceDocumentType = Enums.SourceDocumentTypes.PaymentToVendor
		 Or FilterSourceDocumentType = Enums.SourceDocumentTypes.PurchaseFromVendor
		 Or FilterSourceDocumentType = Enums.SourceDocumentTypes.PurchaseAdjustment Then
		ParametersArray.Add(New ChoiceParameter("Filter.Vendor", True));
	EndIf;
	If GetFunctionalOption("UseCustomerInvoiceIntercompany") Then
		ParametersArray.Add(New ChoiceParameter("SetSelectionByPartnerTypeAsOR", True));
		ParametersArray.Add(New ChoiceParameter("Filter.OurEnterprise", True));
	EndIf;
	Items.FilterPartner.ChoiceParameters = New FixedArray(ParametersArray);
	
EndProcedure

#Region FormTableItemsEventHandlersList

&AtClient
Procedure ListOnActivateRow(Item)
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
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

// IntegrationWith1CDocumentManagementSubsystem
&AtClient
Procedure Attachable_ExecuteIntegrationCommand(Command)
	
	IntegrationWith1CDocumentManagementCoreClient.ExecutePlugInIntegrationCommand(Command, ThisObject, Items.List);
	
EndProcedure
// End IntegrationWith1CDocumentManagementSubsystem

#EndRegion

#Region BSPServiceProceduresAndFunctions

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

#EndRegion

#EndRegion
