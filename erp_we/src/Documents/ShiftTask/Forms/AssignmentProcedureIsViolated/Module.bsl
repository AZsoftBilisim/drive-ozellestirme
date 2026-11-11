
#Region FormCommandsEventHandlers

&AtClient
Procedure Exclude(Command)
	
	Cancel = False;
	
	Try
		
		ExcludeOnServer();
		
	Except
		
		Cancel = True;
		
	    ShowMessageBox(,
			NStr("vi = 'Các hoạt động không thể được hoàn thành do:';
				|ru = 'Операция не может быть выполнена по причине:';
				|en = 'Cannot execute the operation. Reason:'; fa = 'Cannot execute the operation. Reason:';
				|it = 'L''operazione non può essere eseguita a causa di:';
				|pl = 'Operacja nie może być wykonana z powodu:';
				|tr = 'İşlem şu nedenden dolayı gerçekleştirilemez:'")
			+ Chars.LF
			+ BriefErrorDescription(ErrorInfo()));
		
	EndTry;
	
	If Not Cancel Then
		Close(True);
	EndIf;
	
EndProcedure

&AtClient
Procedure Adjust(Command)
	
	Cancel = False;
	
	Try
		
		CorrectOnServer();
		
	Except
		
		Cancel = True;
		
	    ShowMessageBox(,
			NStr("vi = 'Các hoạt động không thể được hoàn thành do:';
				|ru = 'Операция не может быть выполнена по причине:';
				|en = 'Cannot execute the operation. Reason:'; fa = 'Cannot execute the operation. Reason:';
				|it = 'L''operazione non può essere eseguita a causa di:';
				|pl = 'Operacja nie może być wykonana z powodu:';
				|tr = 'İşlem şu nedenden dolayı gerçekleştirilemez:'")
			+ Chars.LF
			+ BriefErrorDescription(ErrorInfo()));
		
	EndTry;
	
	If Not Cancel Then
		Close(True);
	EndIf;
	
EndProcedure

&AtClient
Procedure DontChange(Command)
	
	Close(True);
	
EndProcedure

&AtClient
Procedure Cancel(Command)
	
	Close();
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure ExcludeOnServer()
	
	InformationRegisters.OperationsToCreateShiftTasks.ExcludeOperationsThatViolateAssignmentOrder(
		Parameters.Ref);
	
EndProcedure

&AtServer
Procedure CorrectOnServer()
	
	InformationRegisters.OperationsToCreateShiftTasks.AdjustOperationsThatViolateAssignmentOrder(
		Parameters.Ref);
	
EndProcedure

#EndRegion
