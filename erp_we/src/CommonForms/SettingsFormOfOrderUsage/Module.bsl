
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	// Skip initialization to ensure that the form is received when passing the "AutoTest" parameter.
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	OrderExecutionMode = Parameters.OrderExecutionMode;
	
	SetAvailability(ThisForm);
	
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)
	
	Notification = New CallbackDescription("WriteAndClose", ThisObject);
	CommonClient.ShowFormClosingConfirmation(Notification, Cancel, Exit);
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure OrderExecutionModeOnChange(Item)
	
	SetAvailability(ThisForm);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure OkCommand(Command)
	
	WriteAndClose();
	
EndProcedure

&AtClient
Procedure CancelCommand(Command)
	
	Modified = False;
	Close(Undefined);
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure WriteAndClose(Result = Undefined, AdditionalParameters = Undefined) Export
	
	Modified = False;
	Close(OrderExecutionMode)
	
EndProcedure

&AtClientAtServerNoContext
Procedure SetAvailability(Form)
	
	TMCommonUseClientServer.WarningOnEditRepresentation(
			Form.Items.OrderExecutionMode,  Form.OrderExecutionMode > 0);
	TMCommonUseClientServer.WarningOnEditRepresentation(
			Form.Items.OrderExecutionMode1, Form.OrderExecutionMode > 1)
	
EndProcedure

#EndRegion

