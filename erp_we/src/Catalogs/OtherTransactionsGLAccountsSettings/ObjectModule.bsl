#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure BeforeWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	Description = GLAccountSettingsClientServer.ReflectionSettingPresentation(ThisObject, Undefined, Undefined);
	
	If Not ValueIsFilled(SettingsOwner) Then
		SettingsOwner = Undefined;
	EndIf;
	
	HashSum = HashAmountAccountSettings();
	
EndProcedure

#EndRegion

#Region Private

Function HashAmountAccountSettings()
	
	HashSumData = New Array();
	
	
	IntSettings = New ValueTable();
	IntSettings.Columns.Add("ChartOfAccounts", Common.StringTypeDetails(50));
	IntSettings.Columns.Add("GLAccount", Common.StringTypeDetails(50));
	IntSettings.Columns.Add("ExtDimension1");
	IntSettings.Columns.Add("ExtDimension2");
	IntSettings.Columns.Add("ExtDimension3");
	
	For Each InternationalSetting In FinancialAccountingSettings Do
		If ValueIsFilled(InternationalSetting.GLAccount) Then
			NewRow = IntSettings.Add();
			FillPropertyValues(NewRow, InternationalSetting, "ExtDimension1,ExtDimension2,ExtDimension3");
			NewRow.ChartOfAccounts = XMLString(InternationalSetting.ChartOfAccounts);
			NewRow.GLAccount = XMLString(InternationalSetting.GLAccount);
		EndIf;
	EndDo;

	IntSettings.Sort("ChartOfAccounts,GLAccount");
	
	For Each SettingUpINT In IntSettings Do
		HashSumData.Add(SettingUpINT.ChartOfAccounts);
		AddAccountAndExtdimensionToHashAmountData(SettingUpINT, HashSumData);
	EndDo;
	DataHashing = New DataHashing(HashFunction.SHA256);
	DataHashing.Append(StrConcat(HashSumData));
	
	Return Base64String(DataHashing.HashSum);
	
EndFunction

Procedure AddAccountAndExtdimensionToHashAmountData(ConfigurationData, HashSumData)
	
	HashSumData.Add(XMLString(ConfigurationData.GLAccount));
	
	If ValueIsFilled(ConfigurationData.ExtDimension1) Then
		HashSumData.Add(XMLString(ConfigurationData.ExtDimension1));
	EndIf;
	
	If ValueIsFilled(ConfigurationData.ExtDimension2) Then
		HashSumData.Add(XMLString(ConfigurationData.ExtDimension2));
	EndIf;
	
	If ValueIsFilled(ConfigurationData.ExtDimension3) Then
		HashSumData.Add(XMLString(ConfigurationData.ExtDimension3));
	EndIf;
	
EndProcedure

#EndRegion

#EndIf