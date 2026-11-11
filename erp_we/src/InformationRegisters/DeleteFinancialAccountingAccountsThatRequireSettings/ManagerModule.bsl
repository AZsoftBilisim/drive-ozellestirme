#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Internal

Function NewAccountRegistrationData() Export
	
	AccountRegistrationData = New Structure();
	MetadataRegister = CreateRecordSet().Metadata();
	
	For Each Dimension In MetadataRegister.Dimensions Do
		AccountRegistrationData.Insert(Dimension.Name);
	EndDo;
	
	Return AccountRegistrationData;
	
EndFunction

Procedure RegisterForConfiguration(AccountRegistrationData) Export
	
	For Each KeyAndValue In AccountRegistrationData Do
		If Not ValueIsFilled(KeyAndValue.Value)
			And (KeyAndValue.Key = "ChartOfAccounts"
			Or KeyAndValue.Key = "PostingGenerationSetting"
			Or KeyAndValue.Key = "AccountingObject") Then
			Return;
		EndIf;
	EndDo;
	
	If Not ValueIsFilled(AccountRegistrationData.SettingObject1) Then
		AccountRegistrationData.Insert("SettingObject1", Undefined);
	EndIf;
	
	If Not ValueIsFilled(AccountRegistrationData.Document) Then
		AccountRegistrationData.Insert("Document", Undefined);
	EndIf;
	
	SetPrivilegedMode(True);
	
	RecordSet = CreateRecordSet();
	
	For Each KeyAndValue In AccountRegistrationData Do
		RecordSet.Filter[KeyAndValue.Key].Set(KeyAndValue.Value);
	EndDo;
	
	RecordSet.Read();
	
	If RecordSet.Count() = 0 Then
		NewRecord = RecordSet.Add();
		FillPropertyValues(NewRecord, AccountRegistrationData);
		RecordSet.Write();
	EndIf;
	
EndProcedure

#EndRegion

#EndIf