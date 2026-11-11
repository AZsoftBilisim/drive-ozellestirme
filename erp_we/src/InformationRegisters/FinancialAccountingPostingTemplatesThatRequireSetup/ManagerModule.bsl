#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Internal

Procedure RegisterForConfiguration(ChartOfAccounts, PostingGenerationSetting, AccountingObject, Val SettingObject1, Val Document) Export
	
	If Not ValueIsFilled(ChartOfAccounts) Then
		Return;
	ElsIf Not ValueIsFilled(PostingGenerationSetting) Then
		Return;
	ElsIf Not ValueIsFilled(AccountingObject) Then
		Return;
	ElsIf Not ValueIsFilled(SettingObject1) Then
		SettingObject1 = Undefined;
	ElsIf Not ValueIsFilled(Document) Then
		Document = Undefined;
	EndIf;
	
	RecordSet = CreateRecordSet();
	RecordSet.Filter.ChartOfAccounts.Set(ChartOfAccounts);
	RecordSet.Filter.PostingGenerationSetting.Set(PostingGenerationSetting);
	RecordSet.Filter.AccountingObject.Set(AccountingObject);
	RecordSet.Filter.SettingObject1.Set(SettingObject1);
	RecordSet.Filter.Document.Set(Document);
	RecordSet.Read();
	
	If RecordSet.Count() = 0 Then
		NewRecord = RecordSet.Add();
		NewRecord.ChartOfAccounts = ChartOfAccounts;
		NewRecord.PostingGenerationSetting = PostingGenerationSetting;
		NewRecord.AccountingObject = AccountingObject;
		NewRecord.SettingObject1 = SettingObject1;
		NewRecord.Document = Document;
		RecordSet.Write();
	EndIf;
	
EndProcedure

#EndRegion

#EndIf