
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetConditionalAppearance();
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	#Region StandardMechanisms
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
		
	FormEvents.OnCreateAtServer(ThisObject, Cancel, StandardProcessing);
	
	#EndRegion

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

#Region AttachableCommands

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

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisObject, Command);
	
EndProcedure

#EndRegion

&AtClient
Procedure CreateInputOfBalancesOnBankAccounts(Command)

	CreateDocument(PredefinedValue("Enum.BusinessTransactions.OBEntryCashInBankAccounts"));

EndProcedure

&AtClient
Procedure CreateBalanceEntryAtCashAccount(Command)

	CreateDocument(PredefinedValue("Enum.BusinessTransactions.OBEntryCashInHand"));

EndProcedure

&AtClient
Procedure CreateOBEntryInAutonomousCashRegistersToRegisterRetailSalesReports(Command)

	CreateDocument(PredefinedValue("Enum.BusinessTransactions.OBEntryOpenSalesInvoicesFromRetailCashRegisters"));

EndProcedure

&AtClient
Procedure CreateOBEntryInAutonomousCashRegistersForRetailRevenue(Command)

	CreateDocument(PredefinedValue("Enum.BusinessTransactions.OBEntryCashInRetailCashRegister"));

EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()
	
	ConditionalAppearance.Items.Clear();
	StandardSubsystemsServer.SetDateFieldConditionalAppearance(ThisObject);
	
EndProcedure

&AtClient
Procedure CreateDocument(BusinessOperation)
	
	FillingData = New Structure;
	FillingData.Insert("BusinessOperation", BusinessOperation);
	
	FormParameters = New Structure("Basis", FillingData);
	OpenForm("Document.OBEntryCash.ObjectForm", FormParameters, Items.List);
	
EndProcedure

#EndRegion
