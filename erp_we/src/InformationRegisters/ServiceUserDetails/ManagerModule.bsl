
#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Internal

Procedure AddRecord(CurrentUser, WriteParameters) Export
	
	SetSafeModeDisabled(True);
	SetPrivilegedMode(True);
	
	ServiceUserID = Common.ObjectAttributeValue(
		CurrentUser,
		"ServiceUserID");
	
	If Not ValueIsFilled(ServiceUserID) Then
		Return;
	EndIf;
	
	Block = New DataLock();
	LockItem = Block.Add("InformationRegister.ServiceUserDetails");
	LockItem.SetValue("ServiceUserID", ServiceUserID);
	
	BeginTransaction();
	
	Try
		
		Block.Lock();
		
		Write = False;
		
		RegisterRecord = CreateRecordManager();
		RegisterRecord.ServiceUserID = ServiceUserID;
		RegisterRecord.Read();
		
		If Not RegisterRecord.Selected() Then
			RegisterRecord.ServiceUserID = ServiceUserID;
			Write = True;
		Else
			
			For Each ParameterItem In WriteParameters Do
				
				If RegisterRecord[ParameterItem.Key] <> ParameterItem.Value Then
					Write = True;
					Break;
				EndIf;
				
			EndDo;
			
		EndIf;
		
		If Write Then
			
			FillPropertyValues(RegisterRecord, WriteParameters);
			RegisterRecord.NotifyChanged = True;
			RegisterRecord.Write();
			
		EndIf;
		
		CommitTransaction();
		
	Except
		
		RollbackTransaction();
		Raise;
		
	EndTry;
	
	SetPrivilegedMode(False);
	
EndProcedure

#EndRegion

#EndIf
