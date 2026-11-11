#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If ValueIsFilled(Record.SourceRecordKey.User) Then
		
		SetPrivilegedMode(True);
		VaultPassword = Common.ReadDataFromSecureStorage(
			InformationRegisters.AuthorizationIn1cFresh.OwnerOfSecureStorage(Record.SourceRecordKey.User));
		SetPrivilegedMode(False);
		
		If ValueIsFilled(VaultPassword) Then
			Password = New UUID;			
		EndIf;
		
	EndIf;
	
	If Not ValueIsFilled(Record.User) Then
		Record.User = Users.CurrentUser();
	EndIf; 
	
EndProcedure

&AtServer
Procedure OnWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	If PasswordChanged Then
		Owner = InformationRegisters.AuthorizationIn1cFresh.OwnerOfSecureStorage(Record.User);
		Common.WriteDataToSecureStorage(Owner, Password);
	EndIf;
	
EndProcedure

#EndRegion 

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure PasswordOnChange(Item)
	
	PasswordChanged = True;
	
EndProcedure

#EndRegion 