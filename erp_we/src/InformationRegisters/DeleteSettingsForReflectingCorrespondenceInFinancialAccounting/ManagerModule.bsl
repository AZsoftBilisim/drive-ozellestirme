#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Internal

Function ParametersForReceivingConfigurationData() Export
	
	ReceivingParameters = New Structure();
	
	MetadataRegister = CreateRecordSet().Metadata();
	
	For Each Dimension In MetadataRegister.Dimensions Do
		If Not Dimension.Name = "ApplicationProcedure" Then
			ReceivingParameters.Insert(Dimension.Name);
		EndIf;
	EndDo;
	
	Return ReceivingParameters;
	
EndFunction

Function NumberOfCorrenspondencySettings(DataGetParameters) Export
	
	SettingsCount = 0;
	
	If Not ValueIsFilled(DataGetParameters.ChartOfAccounts) 
		Or Not ValueIsFilled(DataGetParameters.PostingGenerationSetting)
		Or Not ValueIsFilled(DataGetParameters.AccountingObjectDr) 
		Or Not ValueIsFilled(DataGetParameters.AccountingObjectCr) Then
		Return SettingsCount;
	EndIf;
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	COUNT(1) AS Count
	|FROM
	|	InformationRegister.DeleteSettingsForReflectingCorrespondenceInFinancialAccounting AS RecordSettings
	|WHERE
	|	RecordSettings.ChartOfAccounts = &ChartOfAccounts
	|	AND RecordSettings.PostingGenerationSetting = &PostingGenerationSetting
	|	AND RecordSettings.AccountingObjectDr = &AccountingObjectDr
	|	AND RecordSettings.AccountingObjectCr = &AccountingObjectCr
	|	AND RecordSettings.LongTermDr = &LongTermDr
	|	AND RecordSettings.LongTermCr = &LongTermCr
	|";
	Query.SetParameter("ChartOfAccounts", DataGetParameters.ChartOfAccounts);
	Query.SetParameter("PostingGenerationSetting", DataGetParameters.PostingGenerationSetting);
	Query.SetParameter("AccountingObjectDr", DataGetParameters.AccountingObjectDr);
	Query.SetParameter("AccountingObjectCr", DataGetParameters.AccountingObjectCr);
	Query.SetParameter("LongTermDr", DataGetParameters.LongTermDr);
	Query.SetParameter("LongTermCr", DataGetParameters.LongTermCr);
	
	Selection = Query.Execute().Select();
	If Selection.Next() Then
		SettingsCount = Selection.Count;
	EndIf;
	
	Return SettingsCount;
	
EndFunction

Function ProcedureForApplyingSetting(DataGetParameters) Export
	
	ApplicationProcedure = 0;
	
	If Not ValueIsFilled(DataGetParameters.ChartOfAccounts) 
		Or Not ValueIsFilled(DataGetParameters.PostingGenerationSetting)
		Or Not ValueIsFilled(DataGetParameters.AccountingObjectDr) 
		Or Not ValueIsFilled(DataGetParameters.AccountingObjectCr) Then
		Return ApplicationProcedure;
	EndIf;
	
	Query = New Query;
	Query.Text =
	"SELECT TOP 1
	|	RecordSettings.ApplicationProcedure AS ApplicationProcedure
	|FROM
	|	InformationRegister.DeleteSettingsForReflectingCorrespondenceInFinancialAccounting AS RecordSettings
	|WHERE
	|	RecordSettings.ChartOfAccounts = &ChartOfAccounts
	|	AND RecordSettings.PostingGenerationSetting = &PostingGenerationSetting
	|	AND RecordSettings.AccountingObjectDr = &AccountingObjectDr
	|	AND RecordSettings.AccountingObjectCr = &AccountingObjectCr
	|	AND RecordSettings.LongTermDr = &LongTermDr
	|	AND RecordSettings.LongTermCr = &LongTermCr
	|	
	|ORDER BY
	|	RecordSettings.ApplicationProcedure DESC";
	Query.SetParameter("ChartOfAccounts", DataGetParameters.ChartOfAccounts);
	Query.SetParameter("PostingGenerationSetting", DataGetParameters.PostingGenerationSetting);
	Query.SetParameter("AccountingObjectDr", DataGetParameters.AccountingObjectDr);
	Query.SetParameter("AccountingObjectCr", DataGetParameters.AccountingObjectCr);
	Query.SetParameter("LongTermDr", DataGetParameters.LongTermDr);
	Query.SetParameter("LongTermCr", DataGetParameters.LongTermCr);
	
	Selection = Query.Execute().Select();
	If Selection.Next() Then
		ApplicationProcedure = Selection.ApplicationProcedure;
	EndIf;
	
	ApplicationProcedure = ApplicationProcedure + 1;
	
	Return ApplicationProcedure;
	
EndFunction

// Changes the order in which the setting is applied to a certain number of positions
// 
// Parameters:
// 	RecordKey - InformationRegisterRecordKey.DeleteSettingsForReflectingCorrespondenceInFinancialAccounting - The original key of the configuration entry
// 	Move - Number - The number of positions to change the order of applying the setting to
//
// Returns:
// 	InformationRegisterRecordKey.DeleteSettingsForReflectingCorrespondenceInFinancialAccounting - The key for recording the settings after changing the order of application.
Function ChangeOrderInWhichSettingsAreApplied(RecordKey, Move) Export
	
	BeginTransaction();
	
	Try
		DataLock = New DataLock();
		DataLockItem = DataLock.Add("InformationRegister.DeleteSettingsForReflectingCorrespondenceInFinancialAccounting");
		DataLockItem.SetValue("ChartOfAccounts", RecordKey.ChartOfAccounts);
		DataLockItem.SetValue("PostingGenerationSetting", RecordKey.PostingGenerationSetting);
		DataLockItem.SetValue("AccountingObjectDr", RecordKey.AccountingObjectDr);
		DataLockItem.SetValue("AccountingObjectCr", RecordKey.AccountingObjectCr);
		DataLockItem.SetValue("LongTermDr", RecordKey.LongTermDr);
		DataLockItem.SetValue("LongTermCr", RecordKey.LongTermCr);
		DataLockItem.Mode = DataLockMode.Exclusive;
		DataLock.Lock();
		
		CurOrderOfApplication = RecordKey.ApplicationProcedure;
		
		RecordSet = InformationRegisters.DeleteSettingsForReflectingCorrespondenceInFinancialAccounting.CreateRecordSet();
		RecordSet.Filter.ChartOfAccounts.Set(RecordKey.ChartOfAccounts);
		RecordSet.Filter.PostingGenerationSetting.Set(RecordKey.PostingGenerationSetting);
		RecordSet.Filter.AccountingObjectDr.Set(RecordKey.AccountingObjectDr);
		RecordSet.Filter.AccountingObjectCr.Set(RecordKey.AccountingObjectCr);
		RecordSet.Filter.LongTermDr.Set(RecordKey.LongTermDr);
		RecordSet.Filter.LongTermCr.Set(RecordKey.LongTermCr);
		
		RecordSet.Read();
		
		NewOrderOfApplication = CurOrderOfApplication + Move;
		
		If NewOrderOfApplication < 1 Or NewOrderOfApplication > RecordSet.Count() Then
			RollbackTransaction();
			Return RecordKey;
		EndIf;
		
		RecordsTable = RecordSet.Unload();
		
		Record = RecordsTable[CurOrderOfApplication - 1];
		RecordsTable.Move(Record, Move);
		
		ApplicationProcedure = 1;
		For Each TableRow In RecordsTable Do
			TableRow.ApplicationProcedure = ApplicationProcedure;
			ApplicationProcedure = ApplicationProcedure + 1;
		EndDo;
	
		KeyValues = New Structure;
		For Each Dimension In Metadata.InformationRegisters.DeleteSettingsForReflectingCorrespondenceInFinancialAccounting.Dimensions Do
			KeyValues.Insert(Dimension.Name);
		EndDo;
		FillPropertyValues(KeyValues, Record);
		NewRecordKey = CreateRecordKey(KeyValues);
		
		RecordSet.Load(RecordsTable);
		RecordSet.Write();
		
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise StrTemplate(NStr("vi = 'Không cần thay đổi trình tự áp dụng bản ghi do nguyên nhân: %1';
								|ru = 'Не удалось изменить порядок применения записи по причине: %1';
								|en = 'Cannot change the record application procedure due to: %1'; fa = 'Cannot change the record application procedure due to: %1';
								|it = 'Не удалось изменить порядок применения записи по причине: %1';
								|pl = 'Nie udało się zmienić trybu zastosowania wpisu z powodu: %1';
								|tr = 'Kaydın uygulanma sırası şu nedenlerden değiştirilemedi: %1'"),  DetailErrorDescription(ErrorInfo()));
	EndTry;
	
	Return NewRecordKey;
	
EndFunction

#EndRegion

#EndIf