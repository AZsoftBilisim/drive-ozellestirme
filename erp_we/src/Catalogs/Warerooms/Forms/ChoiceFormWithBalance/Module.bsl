
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;

	CommonClientServer.SetDynamicListParameter(List, "Products",   Parameters.Products);
	CommonClientServer.SetDynamicListParameter(List, "Characteristic", Parameters.Characteristic);
	CommonClientServer.SetDynamicListParameter(List, "Warehouse",          Parameters.Filter.Owner);
	
	AutoTitle = False;
	Title = NStr("vi = 'Chọn nhà kho';
				|ru = 'Выбор помещения';
				|en = 'Select premises'; fa = 'Select premises';
				|it = 'La scelta del locale';
				|pl = 'Wybór pomieszczenia';
				|tr = 'Alan seçimi'");
	
	Items.Premise.Title = Parameters.Filter.Owner;
	
	ProductName = "" + Parameters.Products + ?(ValueIsFilled(Parameters.Characteristic), " (" + Parameters.Characteristic + ")","");
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands

	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);

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
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

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

#EndRegion

