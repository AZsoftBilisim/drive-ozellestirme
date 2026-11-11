
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	// StandardSubsystems.ObjectsVersioning
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.ObjectsVersioning
	
	FillInAvailableActions();
	
	StandardSubsystemsServer.SetDateFieldConditionalAppearance(ThisObject, "List.Date", Items.Date.Name);
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject,
		Items.GroupCommandBar);
	// End IntegrationWith1CDocumentManagementSubsystem
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersList

&AtClient
Procedure ListOnActivateRow(Item)
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

&AtClient
Procedure ListOnChange(Item)
	ProvisionInDocumentsClient.CheckToRunBackgroundInventoryAllocationJob();
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
	
	IntegrationWith1CDocumentManagementCoreClient.ExecutePlugInIntegrationCommand(
		Command,
		ThisObject,
		Items.List);
	
EndProcedure
// End IntegrationWith1CDocumentManagementSubsystem

// MenuReports


&AtClient
Procedure CreateReserveRemovalByAssignment(Command)
	
	CreateAdjustment(PredefinedValue("Enum.KindsOfAssignmentAdjustmentOperations.RemoveFromReserve"));
	
EndProcedure

&AtClient
Procedure CreateAReserveWithdrawalForManyAssignments(Command)
	
	CreateAdjustment(PredefinedValue("Enum.KindsOfAssignmentAdjustmentOperations.RemoveFromReserveForMultipleAssignments"));
	
EndProcedure

&AtClient
Procedure CreateAWarehouseReservationAndMoveTheReserves(Command)
	
	CreateAdjustment(PredefinedValue("Enum.KindsOfAssignmentAdjustmentOperations.ReservationAndAdjustment"));
	
EndProcedure

&AtClient
Procedure CreateAReservationInWarehouses(Command)
	
	CreateAdjustment(PredefinedValue("Enum.KindsOfAssignmentAdjustmentOperations.ToReserve_"));
	
EndProcedure

&AtClient
Procedure CreateAnAssignmentAdjustment(Command)
	
	CreateAdjustment(PredefinedValue("Enum.KindsOfAssignmentAdjustmentOperations.AdvancedAssignmentAdjustment"));
	
EndProcedure

&AtClient
Procedure CreateAdjustment(OperationKind)
	
	StructureBase = New Structure("OperationKind", OperationKind);
	ParametersStructure1 = New Structure("Basis", StructureBase);
	
	OpenForm("Document.InventoryAssignmentAdjustment.ObjectForm", ParametersStructure1, Items.List);
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure FillInAvailableActions()
	
	AvailableAction = Documents.InventoryAssignmentAdjustment.AvailableAction();
	
	If AvailableAction.Find(Enums.KindsOfAssignmentAdjustmentOperations.RemoveFromReserveForMultipleAssignments)
			= Undefined Then
		Items.CreateWithdrawalFormForMultipleAssignments.Visible = False;
	EndIf;
	
	If AvailableAction.Find(Enums.KindsOfAssignmentAdjustmentOperations.ReservationAndAdjustment)
			= Undefined Then
		Items.FormCreateAWarehouseReservationAndMoveTheReserves.Visible = False;
	EndIf;
	
	If AvailableAction.Find(Enums.KindsOfAssignmentAdjustmentOperations.AdvancedAssignmentAdjustment)
			= Undefined Then
		Items.CreateAnAssignmentAdjustment.Visible = False;
	EndIf;
	
	If Not AccessRight("Insert", Metadata.Documents.InventoryAssignmentAdjustment) Then
		
		Items.FormCreateReserveRemovalByAssignment.Enabled = False;
		Items.CreateWithdrawalFormForMultipleAssignments.Enabled = False;
		Items.FormCreateAReservationInWarehouses.Enabled = False;
		Items.FormCreateAWarehouseReservationAndMoveTheReserves.Enabled = False;
		Items.FormCreateGroup.Enabled = False;
		
	EndIf;
	
EndProcedure

#EndRegion