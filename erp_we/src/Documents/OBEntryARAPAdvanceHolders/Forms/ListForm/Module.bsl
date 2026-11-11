
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetConditionalAppearance();
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	If AccessRight("InteractiveInsert", Metadata.Documents.OBEntryARAPAdvanceHolders) Then
		
		FullDocumentName		= "Document.OBEntryARAPAdvanceHolders";
		DocumentType			= Type("DocumentRef.OBEntryARAPAdvanceHolders");
		DocumentID= Common.MetadataObjectID(FullDocumentName);
		
		ArrayOfBusinessOperations = New Array;
		ArrayOfBusinessOperations.Add(Enums.BusinessTransactions.OBEntryAdvanceHolderReceivables);
		ArrayOfBusinessOperations.Add(Enums.BusinessTransactions.OBEntryOpenExpenseReportOfEmployees);
		
		For Each AvailableBusinessOfOperation In ArrayOfBusinessOperations Do
		
			String = BusinessTransactionsAndDocuments.Add();
			String.AddButtonCreate	= True;
			String.AccessRightInsert	= True;
			String.AccessRightUpdate	= True;
			String.Filter					= True;
			String.DocumentType				= DocumentType;
			String.FullDocumentName		= FullDocumentName;
			String.BusinessOperation 	= AvailableBusinessOfOperation;
			String.MetadataObjectID = DocumentID;
		
		EndDo;
		
		ParametersStructure = TMCommonUse.StructureOfSettingsForDocumentManagementButtons();
		ParametersStructure.Form = ThisObject;
		TMCommonUse.ConfigureDocumentManagementButtons(ParametersStructure);
		
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
