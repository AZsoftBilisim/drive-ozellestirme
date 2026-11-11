
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetConditionalAppearance();
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	UseLocal              = GetFunctionalOption("UseLocal");
	
	
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

&AtClient
Procedure OBEntryUnmatchedPrepaymentFromCustomer(Command)
	CreateInputOfBalancesOfSettlements(PredefinedValue("Enum.BusinessTransactions.OBEntryUnmatchedPrepaymentFromCustomer"));
EndProcedure

&AtClient
Procedure OBEntryUnmatchedPrepaymentToVendor(Command)
	CreateInputOfBalancesOfSettlements(PredefinedValue("Enum.BusinessTransactions.OBEntryUnmatchedPrepaymentToVendor"));
EndProcedure

&AtClient
Procedure OBEntryCustomerAccountsReceivable(Command)
	CreateInputOfBalancesOfSettlements(PredefinedValue("Enum.BusinessTransactions.OBEntryCustomerAccountsReceivable"));
EndProcedure

&AtClient
Procedure OBEntryVendorAccountsPayable(Command)
	CreateInputOfBalancesOfSettlements(PredefinedValue("Enum.BusinessTransactions.OBEntryVendorAccountsPayable"));
EndProcedure

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

#EndRegion

#Region FormTableItemsEventHandlersList

&AtClient
Procedure ListBeforeAddRow(Item, Cancel, Copy, Parent, Var_Group, Parameter)
	
	Cancel = True;
	
	If Not Copy Then
		
		TransactionList = New ValueList;
		TransactionList.Add(PredefinedValue("Enum.BusinessTransactions.OBEntryUnmatchedPrepaymentFromCustomer"));
		TransactionList.Add(PredefinedValue("Enum.BusinessTransactions.OBEntryUnmatchedPrepaymentToVendor"));
		TransactionList.Add(PredefinedValue("Enum.BusinessTransactions.OBEntryCustomerAccountsReceivable"));
		TransactionList.Add(PredefinedValue("Enum.BusinessTransactions.OBEntryVendorAccountsPayable"));
		
		FormParameters = New Structure;
		FormParameters.Insert("FilterByTransactionTypes", TransactionList);
		FormParameters.Insert("FillParameters", 
			New Structure("RecordInOperationalAccounting,PostInFinancialAndTaxAccounting, RecordInMA", True, UseLocal, WannaMaintainTheChartOfAccountsSelfSupporting));
		
		OpenForm("DataProcessor.JournalOfOBEntryDocuments.Form.BusinessTransactionSelection", FormParameters);
		
	Else
		TMCommonUseClient.CopyItem(Items.List);
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()
	
	ConditionalAppearance.Items.Clear();
	StandardSubsystemsServer.SetDateFieldConditionalAppearance(ThisObject);
	
EndProcedure

&AtClient
Procedure CreateInputOfBalancesOfSettlements(BusinessOperation)
	
	FillParameters = New Structure;
	FillParameters.Insert("BusinessOperation", BusinessOperation);
	FillParameters.Insert("RecordInOperationalAccounting", True);
	FillParameters.Insert("PostInFinancialAndTaxAccounting", UseLocal);
	FillParameters.Insert("RecordInMA", WannaMaintainTheChartOfAccountsSelfSupporting);
	
	OpenForm("Document.OBEntryARAP.ObjectForm", New Structure("FillingValues", FillParameters));
	
EndProcedure

#EndRegion
