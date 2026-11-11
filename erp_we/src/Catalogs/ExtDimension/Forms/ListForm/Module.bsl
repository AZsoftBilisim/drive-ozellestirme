
&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	
	OwnerIsNotSpecified = Not Parameters.Filter.Property("Owner") 
		Or Not ValueIsFilled(Parameters.Filter.Owner);
	
	CanBeEdited = AccessRight("Edit", Metadata.Catalogs.ExtDimension);
	Items.ListContextMenuChangeSelectedItems.Visible = CanBeEdited;
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	If OwnerIsNotSpecified Then
		ShowMessageBox( , NStr("vi = 'Sử dụng danh mục khi nhập thủ công giao dịch';
								|ru = 'Справочник используется при вводе операций вручную';
								|en = 'Catalog is used while entering transactions manually'; fa = 'Catalog is used while entering transactions manually';
								|it = 'Si utilizza la directory durante l''inserimento manuale dell''operazione';
								|pl = 'Katalog jest używany przy wprowadzaniu operacji ręcznie';
								|tr = 'Katalog, işlemleri manuel olarak girerken kullanılır'"));
		Cancel = True;
	EndIf;
	
EndProcedure

&AtClient
Procedure ChangeSelectedItems(Command)
	
	BatchEditObjectsClient.ChangeSelectedItems(Items.List);
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// SERVICE PROCEDURES AND FUNCTIONS OF BSP

// StandardSubsystems.AttachableCommands
&AtClient
Procedure Attachable_ExecuteCommand(Command)
	AttachableCommandsClient.ExecuteCommand(ThisObject, Command, Items.List);
EndProcedure

&AtServer
Procedure Attachable_ExecuteCommandAtServer(Context, Result) Export
	AttachableCommands.ExecuteCommand(ThisObject, Context, Items.List, Result);
EndProcedure

&AtClient
Procedure Attachable_UpdateCommands()
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Items.List);
EndProcedure
// End StandardSubsystems.AttachableCommands

#Region FormTableItemsEventHandlersList

&AtClient
Procedure ListOnActivateRow(Item)
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

#EndRegion
