#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	IDOfPackage = Parameters.IDOfPackage;
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	AttachIdleHandler("WaitingForPermissionRequestToBeApplied", 5, True);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Cancel(Command)
	
	Close(DialogReturnCode.Cancel);
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure WaitingForPermissionRequestToBeApplied()
	
	Result = RequestsProcessingResult(IDOfPackage);
	
	If Result = Undefined Then
		AttachIdleHandler("WaitingForPermissionRequestToBeApplied", 5, True);
	Else
		
		If Result Then
			
			Close(DialogReturnCode.OK);
			
		Else
			
			Close(DialogReturnCode.Cancel);
			
		EndIf;
		
	EndIf;
	
EndProcedure

&AtServerNoContext
Function RequestsProcessingResult(Val IDOfPackage)
	
	Result = SafeModeManagerInternalSaaS.PackageProcessingResult(IDOfPackage);
	
	If ValueIsFilled(Result) Then
		
		If Result = Enums.ExternalResourcesUsageQueriesProcessingResultsSaaS.RequestApproved Then
			Return True;
		Else
			Return False;
		EndIf;
		
	Else
		
		Return Undefined;
		
	EndIf;
	
EndFunction

#EndRegion