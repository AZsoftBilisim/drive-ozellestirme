
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	#Region StandardMechanisms
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject, Items.GlobalCommandsGroup);
	// End IntegrationWith1CDocumentManagementSubsystem
	
	FormEvents.OnCreateAtServer(ThisObject, Cancel, StandardProcessing);
	
	// StandardSubsystems.ObjectsVersioning
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.ObjectsVersioning
	
	#EndRegion

	ObjectsVersioning.OnCreateAtServer(ThisObject);
	
	AvailableBusinessTransactions = New Array;
	AvailableBusinessTransactions.Add(Enums.BusinessTransactions.AdvanceHolderARAPWriteOff);
	AvailableBusinessTransactions.Add(Enums.BusinessTransactions.RecognitionOfDebtToAdvanceHolderAsIncome);
	
	FullDocumentName = "Document.AdjustmentOfARAPAccountingForAdvanceHolders";
	DocumentType       = Type("DocumentRef.AdjustmentOfARAPAccountingForAdvanceHolders");
	DocumentID =
			Common.MetadataObjectID(FullDocumentName);
	
	For Each AvailableHouseholdOperation In AvailableBusinessTransactions Do
		
		String = BusinessTransactionsAndDocuments.Add();
		String.AddButtonCreate    = True;
		String.AccessRightInsert   = True;
		String.AccessRightUpdate    = True;
		String.Filter                    = True;
		String.DocumentType             = DocumentType;
		String.FullDocumentName       = FullDocumentName;
		String.BusinessOperation    = AvailableHouseholdOperation;
		String.MetadataObjectID = DocumentID;
		
		ParametersStructure =
			TMCommonUse.StructureOfSettingsForDocumentManagementButtons();
		ParametersStructure.Form = ThisObject;
		TMCommonUse.ConfigureDocumentManagementButtons(ParametersStructure);
		
	EndDo;
	
EndProcedure

#EndRegion

#Region Private

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
Procedure Attachable_ContinueCommandExecutionAtServer(ExecutionParameters, AdditionalParameters) Export
	ExecuteCommandAtServer(ExecutionParameters);
EndProcedure

&AtClient
Procedure Attachable_UpdateCommands()
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Items.List);
EndProcedure

&AtServer
Procedure ExecuteCommandAtServer(ExecutionParameters)
	AttachableCommands.ExecuteCommand(ThisObject, ExecutionParameters, Items.List);
EndProcedure
// End StandardSubsystems.AttachableCommands

#EndRegion