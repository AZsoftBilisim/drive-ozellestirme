
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	// Skip initialization to ensure that the form is received when passing the "AutoTest" parameter.
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	AgreementUsage = Parameters.AgreementUsage;
	
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)
	
	Notification = New CallbackDescription("WriteAndClose", ThisObject);
	CommonClient.ShowFormClosingConfirmation(Notification, Cancel, Exit);
	
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

#Region ServiceProcedures

&AtClient
Procedure WriteAndClose(Result = Undefined, AdditionalParameters = Undefined) Export
	
	Modified = False;
	Close(AgreementUsage)
	
EndProcedure

#EndRegion

