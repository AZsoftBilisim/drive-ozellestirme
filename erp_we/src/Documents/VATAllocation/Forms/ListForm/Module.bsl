
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;

	
	If Parameters.Property("Organization") Then
		
		ByAllCompanies = Parameters.Organization = Catalogs.Companies.EmptyRef();
		CommonClientServer.SetDynamicListFilterItem(
			List, "Organization",
			Parameters.Organization,
			?(ByAllCompanies,DataCompositionComparisonType.NotEqual, DataCompositionComparisonType.Equal),
			,
			True);
		
		List.AutoSaveUserSettings = False;
		
	EndIf;
	
	If Parameters.Property("RegistrationPeriod") Then
		
		CommonClientServer.AddCompositionItem(
			List.SettingsComposer.Settings.Filter, "Date",
			DataCompositionComparisonType.GreaterOrEqual,
			BegOfMonth(Parameters.RegistrationPeriod),
			,
			True,
			DataCompositionSettingsItemViewMode.Normal,
			"BeginOfPeriod");
			
		CommonClientServer.AddCompositionItem(
			List.SettingsComposer.Settings.Filter, "Date",
			DataCompositionComparisonType.LessOrEqual,
			EndOfMonth(Parameters.RegistrationPeriod),
			,
			True,
			DataCompositionSettingsItemViewMode.Normal,
			"EndOfPeriod");
			
		List.AutoSaveUserSettings = False;
		
	EndIf;
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject);
	// End IntegrationWith1CDocumentManagementSubsystem

	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	

	StandardSubsystemsServer.SetDateFieldConditionalAppearance(ThisObject, "List.Date", Items.Date.Name);


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

#EndRegion
