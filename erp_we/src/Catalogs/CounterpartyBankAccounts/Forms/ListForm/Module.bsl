
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;

	If Parameters.Property("FilterByPartner") Then
		
		CommonClientServer.SetDynamicListFilterItem(
			List,
			"Owner",
			PartnersAndCounterparties.GetPartnerSDefaultCounterparty(Parameters.FilterByPartner));
	EndIf;
		
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject);
	// End IntegrationWith1CDocumentManagementSubsystem

	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	
	CashServerLocalization.AddBankAccountCreationCommands(ThisObject, Metadata.Catalogs.CounterpartyBankAccounts);
	
EndProcedure

&AtServer
Procedure OnLoadDataFromSettingsAtServer(Settings)
	
	OnlyValidOnes = Settings.Get("OnlyValidOnes");
	Items.OnlyValidOnes.Check = OnlyValidOnes;
	OnlyValidWhenServerChanges();
	
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
Procedure OnlyValidOnes(Command)
	
	Items.OnlyValidOnes.Check = Not Items.OnlyValidOnes.Check;
	
	OnlyValidOnes = Items.OnlyValidOnes.Check;
	OnlyValidWhenServerChanges();
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure OnlyValidWhenServerChanges()
	
	CommonClientServer.SetDynamicListFilterItem(
		List,
		"Closed",
		OnlyValidOnes,
		DataCompositionComparisonType.NotEqual,
		,
		OnlyValidOnes);
	
EndProcedure

// StandardSubsystems.AttachableCommands
&AtClient
Procedure Attachable_ExecuteCommand(Command)
	AttachableCommandsClient.StartCommandExecution(ThisObject, Command, Items.List);
EndProcedure

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

&AtClient
Procedure Attachable_CreateBankAccount(Command)
	CashClientLocalization.OpenBankAccountCreation(List, Command, False);
EndProcedure

#EndRegion