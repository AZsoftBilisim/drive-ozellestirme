#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure OnWrite(Cancel, Replacing)

	If DataExchange.Load Then
		Return;
	EndIf;
		
	If AdditionalProperties.Property("Password")
		And Not Common.IsRecordSetDeletion(Replacing) Then
		For Each Record In ThisObject Do
			SecureStorageKey = InformationRegisters.AuthorizationIn1cFresh.OwnerOfSecureStorage(Record.User);
			Common.WriteDataToSecureStorage(SecureStorageKey, AdditionalProperties.Password);
		EndDo;
	EndIf;
	
EndProcedure

#EndRegion 

#EndIf
