
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Filter.Property("Owner") Then
		
		OwnerFilter = Parameters.Filter.Owner;
		Items.List.Representation = TableRepresentation.Tree;
		Items.OwnerFilter.ReadOnly = True;
		
	EndIf;
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject);
	// End IntegrationWith1CDocumentManagementSubsystem
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure OwnerFilterOnChange(Item)
	
	CommonClientServer.SetDynamicListFilterItem(List, "Owner", OwnerFilter, , ,
																			ValueIsFilled(OwnerFilter));
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersList

&AtClient
Procedure ListDrag(Item, DragParameters, StandardProcessing, String, Field)
	
	If String = Undefined Then
		Return;
	EndIf; 
	
	StandardProcessing = False;
	
	ReceiverOwner = GetOwnerOfReceiver(String);
	
	For Each ArrayRow In DragParameters.Value Do
		
		If DragParameters.Action = DragAction.Move Then
			TransferSourceToReceiver(ArrayRow, String, ReceiverOwner);
		Else
			CopySourceToReceiver(ArrayRow, String, ReceiverOwner);
		EndIf;
		
	EndDo;
	
	Items.List.Refresh();
	
EndProcedure

&AtClient
Procedure ListOnActivateRow(Item)
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

#EndRegion

#Region Private

// Performs a move check and moves items in the directory.
//
// Parameters:
//	Source - CatalogRef.POSTerminals - a movable element of the directory.
//	Receiver - CatalogRef.POSTerminals - the element (group) of the directory to which
// the source is being moved.
//	ReceiverOwner - CatalogRef.AcquiringContracts - The owner of the element (group) that
// the source is being moved to.
//
&AtServerNoContext
Procedure TransferSourceToReceiver(Source, Receiver, ReceiverOwner)
	
	If ValueIsFilled(ReceiverOwner)
		And ReceiverOwner <> Source.Owner Then
		
		MessageText = StrTemplate(NStr("vi = 'Không thể di chuyển phần tử %1:
							|	hợp đồng kết nối đến hệ thống thanh toán của nhóm không tương ứng với phần tử được di chuyển';
							|ru = 'Невозможно переместить элемент %1:
							|	договор подключения к платежной системе у группы не соответствует перемещаемому элементу';
							|en = 'Cannot transfer the %1 item:
							|	the payment system contract of the group does not match the item to transfer'; fa = 'Cannot transfer the %1 item:
							|	the payment system contract of the group does not match the item to transfer';
							|it = 'Невозможно переместить элемент %1:
							|	договор подключения к платежной системе у группы не соответствует перемещаемому элементу';
							|pl = 'Cannot transfer the %1 item:
							|	the payment system contract of the group does not match the item to transfer';
							|tr = '%1 öğesi taşınamıyor:
							|	grubun ödeme sistemi bağlantı sözleşmesi taşınacak öğeyle eşleşmiyor'"), String(Source.Description));
		Common.MessageToUser(MessageText, Source);
		
	Else
		
		If Source.Parent <> Receiver Then
			
			SourceObject_ = Source.GetObject();
			SourceObject_.Parent = Receiver;
			SourceObject_.Write();
			
		EndIf;
		
	EndIf;
	
EndProcedure

// Copies items in the directory. If the source and receiver are subject to different contracts, then 
// a new element is created with the owner of the receiver.
//
// Parameters:
//	Source - CatalogRef.POSTerminals - the copied element of the directory.
//	Receiver - CatalogRef.POSTerminals - the element (group) of the directory to which
// the source is being copied.
//	ReceiverOwner - CatalogRef.AcquiringContracts - The owner of the element (group) that
// the source is being moved to.
//
&AtServerNoContext
Procedure CopySourceToReceiver(Source, Receiver, ReceiverOwner)
	
	NewItem = Catalogs.POSTerminals.CreateItem();
	FillPropertyValues(NewItem, Source, , "Parent, Owner");
	NewItem.Parent = Receiver;
	NewItem.Owner = ReceiverOwner;
	NewItem.Write();
	
EndProcedure

&AtServerNoContext
Function GetOwnerOfReceiver(Receiver)
	
	Return Common.ObjectAttributeValue(Receiver, "Owner");
	
EndFunction

#EndRegion

#Region FormCommandsEventHandlers

// IntegrationWith1CDocumentManagementSubsystem
&AtClient
Procedure Attachable_ExecuteIntegrationCommand(Command)
	
	IntegrationWith1CDocumentManagementCoreClient.ExecutePlugInIntegrationCommand(
		Command,
		ThisObject,
		Items.List);
	
EndProcedure
// End IntegrationWith1CDocumentManagementSubsystem

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

#EndRegion
