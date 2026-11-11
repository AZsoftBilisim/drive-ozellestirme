
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	SetUnavailableSelectionsFromParameters(Parameters.Filter, Parameters.TheSelectionOfOrganizationsOr);
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject);
	// End IntegrationWith1CDocumentManagementSubsystem
	
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	
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

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
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

#EndRegion

#Region Private

#Region Other

// The procedure sets the selections passed in the structure. Selections cannot be changed.
//
// Parameters:
//	FilterStructure1 - Structure - Key: name of the data layout field, Value: selection value.
//
&AtServer
Procedure SetUnavailableSelectionsFromParameters(FilterStructure1, TheSelectionOfOrganizationsOr)
	
	If FilterStructure1.Property("Owner") Then
		FilterStructure1.Delete("Owner");
	EndIf;
	
	If FilterStructure1.Property("ArticleOwner") Then
		FilterStructure1.Delete("ArticleOwner");
	EndIf;
	
	If FilterStructure1.Property("Organization")
		And FilterStructure1.Property("CompanyRecipient") Then
		
		If (FilterStructure1.Organization = FilterStructure1.CompanyRecipient
				And TypeOf(FilterStructure1.Organization) = Type("CatalogRef.Companies")) Then
			// The set selections for organizations are equal, which means it is necessary to apply the "OR" condition to them.
			FilterOrganizations = CommonClientServer.CreateFilterItemGroup(
								List.SettingsComposer.FixedSettings.Filter.Items,
								"FilterOrganizations",
								DataCompositionFilterItemsGroupType.OrGroup);
			
			CommonClientServer.SetFilterItem(FilterOrganizations,
																"Organization",
																FilterStructure1.Organization);
			CommonClientServer.SetFilterItem(FilterOrganizations,
																"CompanyRecipient",
																FilterStructure1.Organization);
			
			FilterStructure1.Delete("Organization");
			FilterStructure1.Delete("CompanyRecipient");
			
		ElsIf TheSelectionOfOrganizationsOr Then
			
			OrganizationArray = New ValueList;
			OrganizationArray.Add(FilterStructure1.Organization);
			OrganizationArray.Add(FilterStructure1.CompanyRecipient);
			
			CommonClientServer.SetFilterItem(
				List.SettingsComposer.FixedSettings.Filter,
				"Organization",
				OrganizationArray,
				DataCompositionComparisonType.InList);
			CommonClientServer.SetFilterItem(
				List.SettingsComposer.FixedSettings.Filter,
				"CompanyRecipient",
				OrganizationArray,
				DataCompositionComparisonType.InList);
				
			FilterStructure1.Delete("Organization");
			FilterStructure1.Delete("CompanyRecipient");
			
		EndIf;
		
	EndIf;
	
	For Each FilterElement In FilterStructure1 Do
		
		If FilterElement.Key = "Counterparty"
			Or FilterElement.Key = "Partner" Then
			
			Continue;
			
		EndIf;
				
		CommonClientServer.SetDynamicListFilterItem(List,
																				FilterElement.Key,
																				FilterElement.Value);
		
	EndDo;
	
EndProcedure

#EndRegion

#EndRegion
