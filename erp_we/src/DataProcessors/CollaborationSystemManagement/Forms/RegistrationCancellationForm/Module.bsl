#Region FormHeaderItemsEventHandlers

&AtClient
Procedure AgreeOnChange(Item)
	
	Items.CancelRegistration.Enabled = Agree;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure CancelRegistration(Command)
	
	YouCanStartCancelingRegistration = True;
	
	If IntegrationWithCollaborationSystemUsedSaaS Then
		
		CheckResult = CheckPossibilityOfDisablingDatabase();
		
		If Not CheckResult.CanBeDisabled Then
			Message(CheckResult.MessageText);
			YouCanStartCancelingRegistration = False;
			Return;
		EndIf;
		
	EndIf;
	
	If YouCanStartCancelingRegistration Then
		CollaborationSystem.BeginInfoBaseUnregistration(
			New CallbackDescription("CancellationOfRegistrationCompletion", ThisObject, , "RegistrationCancellationError", ThisObject));
		ThisForm.Enabled = False;
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure Initialize(IntegrationWithInteractionSystemIsUsed) Export
	
	IntegrationWithCollaborationSystemUsedSaaS = IntegrationWithInteractionSystemIsUsed;
	
EndProcedure

&AtClient
Procedure CancellationOfRegistrationCompletion(AdditionalParameters) Export
	
	If IntegrationWithCollaborationSystemUsedSaaS Then
		ReportDatabaseDisconnectionToServiceManager(True);
	EndIf;
	
	CallbackDescription = New CallbackDescription("CancelRegistrationWarning", ThisObject);
	ShowMessageBox(CallbackDescription, NStr("vi = 'Đã hủy đăng ký';
											|ru = 'Регистрация отменена';
											|en = 'Registration canceled'; fa = 'Registration canceled';
											|it = 'Registrazione annullata';
											|pl = 'Rejestracja została anulowana';
											|tr = 'Kayıt iptal edildi'"));
	
EndProcedure

&AtClient
Procedure CancelRegistrationWarning(AdditionalParameters) Export
	
	Close(1);
	
EndProcedure

&AtClient
Procedure RegistrationCancellationError(ErrorInfo, StandardProcessing, AdditionalParameters) Export
	
	If IntegrationWithCollaborationSystemUsedSaaS Then
		ReportDatabaseDisconnectionToServiceManager(False, ErrorProcessing.BriefErrorDescription(ErrorInfo));
	EndIf;

	StandardProcessing = False;
	ShowErrorInfo(ErrorInfo);

	Close(0);
	
EndProcedure

// @skip-warning EmptyMethod - a feature of the implementation.
// 
// Returns:
//	Structure:
//	 * CanBeDisabled - Boolean
//	 * MessageText - String
//
&AtServer
Function CheckPossibilityOfDisablingDatabase()
	
EndFunction

// @skip-warning EmptyMethod - a feature of the implementation.
&AtServer
Procedure ReportDatabaseDisconnectionToServiceManager(Success, MessageText = "")
	
EndProcedure

#EndRegion

