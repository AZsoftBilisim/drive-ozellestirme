
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
	
	If AccessRight("InteractiveInsert", Metadata.Documents.OBEntryFinancialInstruments) Then
		
		FullDocumentName		= "Document.OBEntryFinancialInstruments";
		DocumentType			= Type("DocumentRef.OBEntryFinancialInstruments");
		DocumentID =
			Common.MetadataObjectID(FullDocumentName);
		
		// OBEntryDebtOutstandingOfLoansAndBorrowings
		String = BusinessTransactionsAndDocuments.Add();
		String.AddButtonCreate	= True;
		String.AccessRightInsert	= True;
		String.AccessRightUpdate	= True;
		String.Filter					= True;
		String.DocumentType				= DocumentType;
		String.FullDocumentName		= FullDocumentName;
		String.BusinessOperation =
			Enums.BusinessTransactions.OBEntryDebtOutstandingOfLoansAndBorrowings;
		String.MetadataObjectID = DocumentID;
		
		ParametersStructure =
			TMCommonUse.StructureOfSettingsForDocumentManagementButtons();
		ParametersStructure.Form = ThisObject;
		TMCommonUse.ConfigureDocumentManagementButtons(ParametersStructure);
		
	EndIf;
	
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
Procedure Attachable_ContinueCommandExecutionAtServer(ExecutionParameters, AdditionalParameters) Export
	ExecuteCommandAtServer(ExecutionParameters);
EndProcedure

#Region AttachableCommands

&AtClient
Procedure Attachable_CreateDocument(Command)
	TMCommonUseClient.CreateDocumentUsingCommand(Command.Name, New Structure);
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

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisObject, Command);
	
EndProcedure

#EndRegion

#EndRegion

#Region Private

&AtServer
Procedure ExecuteCommandAtServer(ExecutionParameters)
	AttachableCommands.ExecuteCommand(ThisObject, ExecutionParameters, Items.List);
EndProcedure

&AtServer
Procedure SetConditionalAppearance()
	
	ConditionalAppearance.Items.Clear();
	StandardSubsystemsServer.SetDateFieldConditionalAppearance(ThisObject);
	
EndProcedure

#EndRegion
