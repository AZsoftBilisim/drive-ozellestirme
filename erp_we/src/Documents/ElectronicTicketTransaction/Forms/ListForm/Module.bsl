
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
	FormEvents.OnCreateAtServer(ThisObject, Cancel, StandardProcessing);
	
	List.Parameters.SetParameterValue("DocumentTypeElectronicTicket", NStr("vi = 'Vé điện tử';
																			|ru = 'Электронный билет';
																			|en = 'Electronic ticket'; fa = 'بلیت الکترونیکی';
																			|it = 'Biglietto elettronico';
																			|pl = 'Bilet elektroniczny';
																			|tr = 'Elektronik bilet'"));
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersList

&AtClient
Procedure ListOnActivateRow(Item)
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure CreateATicket(Command)
	OpenForm("Document.ElectronicTicketTransaction.Form.DocumentForm", New Structure("Basis"));
EndProcedure

&AtClient
Procedure CreateSurcharge(Command)
	CreateOperationOfOperationWithElectronicTicket(PredefinedValue("Enum.TypesOfTicketOperations.ExtraPay"));
EndProcedure

&AtClient
Procedure CreateRefund(Command)
	CreateOperationOfOperationWithElectronicTicket(PredefinedValue("Enum.TypesOfTicketOperations.Return"));
EndProcedure

// StandardSubsystems.AttachableCommands
&AtClient
Procedure Attachable_UpdateCommands()
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Items.List);
	UpdateDocumentCreationCommands();
EndProcedure

&AtClient
Procedure Attachable_ContinueCommandExecutionAtServer(ExecutionParameters, AdditionalParameters) Export
	ExecuteCommandAtServer(ExecutionParameters);
EndProcedure

&AtClient
Procedure Attachable_ExecuteCommand(Command)
	AttachableCommandsClient.StartCommandExecution(ThisObject, Command, Items.List);
EndProcedure
// End StandardSubsystems.AttachableCommands

&AtClient
Procedure UpdateDocumentCreationCommands()
	
	Items.CreateSurchargeList.Visible = False;
	Items.CreateReturnList.Visible = False;
	
	CurrentData = Items.List.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	Items.CreateSurchargeList.Visible = CurrentData.ThisIsElectronicTicket;
	Items.CreateReturnList.Visible = CurrentData.ThisIsElectronicTicket;
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure CreateOperationOfOperationWithElectronicTicket(OperationType)
	
	CurrentData = Items.List.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	OperationDescription = New Structure;
	OperationDescription.Insert("OperationType", OperationType);
	OperationDescription.Insert("ThisIsFullReturn", False);
	
	DataForCreatingTicketOperation = New Structure;
	DataForCreatingTicketOperation.Insert("ETicketData");
	DataForCreatingTicketOperation.Insert("OperationDescription", OperationDescription);
	DataForCreatingTicketOperation.Insert("ThisIsTicketSplit", False);
	
	BasisParameters = New Structure();
	BasisParameters.Insert("ElectronicTicket", CurrentData.Ref);
	BasisParameters.Insert("DataForCreatingTicketOperation", DataForCreatingTicketOperation);
	
	OpenForm("Document.ElectronicTicketTransaction.Form.ElectronicTicketTransactionForm", New Structure("Basis", BasisParameters));
	
EndProcedure

// StandardSubsystems.AttachableCommands
&AtServer
Procedure ExecuteCommandAtServer(ExecutionParameters)
	AttachableCommands.ExecuteCommand(ThisObject, ExecutionParameters, Items.List);
EndProcedure
// End StandardSubsystems.AttachableCommands

#EndRegion
