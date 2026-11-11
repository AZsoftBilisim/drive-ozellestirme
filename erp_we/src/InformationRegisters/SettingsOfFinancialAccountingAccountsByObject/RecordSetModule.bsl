#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure BeforeWrite(Cancel, Replacing)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	For Each SetRecord In ThisObject Do
		If SetRecord.SettingType = Enums.TypesOfPostingsSettingsInFinancialAccounting.TotalByAccountingObject Then
			SetRecord.Organization = Undefined;
			SetRecord.PlaceOfRegistration = Undefined;
		ElsIf Not ValueIsFilled(SetRecord.PlaceOfRegistration) Then
			SetRecord.PlaceOfRegistration = Undefined;
		EndIf;
		If Not ValueIsFilled(SetRecord.SettingObject1) Then
			SetRecord.SettingObject1 = Undefined;
		EndIf;
	EndDo;
	
EndProcedure

Procedure OnWrite(Cancel, Replacing)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	VATSettlementAccounts = UnloadColumns();
	
	For Each SetRecord In ThisObject Do
		If ValueIsFilled(SetRecord.GLAccount) Or ValueIsFilled(SetRecord.LedgerAccountLongTerm) Then
			AccountsThatRequireConfiguration = InformationRegisters.FinancialAccountingAccountsThatRequireSettings.CreateRecordSet();
			AccountsThatRequireConfiguration.Filter.ChartOfAccounts.Set(SetRecord.ChartOfAccounts);
			AccountsThatRequireConfiguration.Filter.PostingGenerationSetting.Set(SetRecord.PostingGenerationSetting);
			AccountsThatRequireConfiguration.Filter.SettingObject1.Set(SetRecord.SettingObject1);
			AccountsThatRequireConfiguration.Filter.AccountingObject.Set(SetRecord.AccountingObject);
			
			If ValueIsFilled(SetRecord.GLAccount) And ValueIsFilled(SetRecord.LedgerAccountLongTerm) Then
			ElsIf ValueIsFilled(SetRecord.GLAccount) Then
				AccountsThatRequireConfiguration.Filter.LongTerm.Set(False);
			Else
				AccountsThatRequireConfiguration.Filter.LongTerm.Set(True);
			EndIf;
			
			AccountsThatRequireConfiguration.Write();
		EndIf;
		
		If SetRecord.AccountingObject = ChartsOfCharacteristicTypes.AssetLiabilityItems.VATAccountsPayable
		And Not ValueIsFilled(SetRecord.SettingObject1) Then
			FillPropertyValues(VATSettlementAccounts.Add(), SetRecord);
		EndIf;
	EndDo;
	
	If VATSettlementAccounts.Count() > 0 Then
		QueryText = "
		|SELECT
		|	VATSettlementAccounts.ChartOfAccounts AS ChartOfAccounts,
		|	VATSettlementAccounts.PostingGenerationSetting AS PostingGenerationSetting,
		|	VATSettlementAccounts.SettingType AS SettingType,
		|	VATSettlementAccounts.Organization AS Organization,
		|	VATSettlementAccounts.PlaceOfRegistration AS PlaceOfRegistration,
		|	VATSettlementAccounts.GLAccount AS GLAccount,
		|	VATSettlementAccounts.LedgerAccountLongTerm AS LedgerAccountLongTerm
		|INTO TTOfVATInvoice
		|FROM
		|	&VATSettlementAccounts AS VATSettlementAccounts
		|INDEX BY
		|	ChartOfAccounts,
		|	PostingGenerationSetting,
		|	SettingType,
		|	Organization,
		|	PlaceOfRegistration
		|
		|;
		|
		|SELECT
		|	VATSettlementAccounts.ChartOfAccounts AS ChartOfAccounts,
		|	VATSettlementAccounts.PostingGenerationSetting AS PostingGenerationSetting,
		|	VATSettlementAccounts.SettingType AS SettingType,
		|	VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.Taxes) AS AccountingObject,
		|	VALUE(Catalog.TaxContributionKinds.VAT) AS SettingObject1,
		|	VATSettlementAccounts.Organization AS Organization,
		|	VATSettlementAccounts.PlaceOfRegistration AS PlaceOfRegistration,
		|	CASE
		|		WHEN ISNULL(AccountingAccountSettings.GLAccount, VALUE(ChartOfAccounts.International.EmptyRef)) = VALUE(ChartOfAccounts.International.EmptyRef)
		|			THEN VATSettlementAccounts.GLAccount
		|		ELSE AccountingAccountSettings.GLAccount
		|	END AS GLAccount,
		|	CASE
		|		WHEN ISNULL(AccountingAccountSettings.LedgerAccountLongTerm, VALUE(ChartOfAccounts.International.EmptyRef)) = VALUE(ChartOfAccounts.International.EmptyRef)
		|			THEN VATSettlementAccounts.LedgerAccountLongTerm
		|		ELSE AccountingAccountSettings.LedgerAccountLongTerm
		|	END AS LedgerAccountLongTerm
		|FROM
		|	TTOfVATInvoice AS VATSettlementAccounts
		|	LEFT JOIN InformationRegister.SettingsOfFinancialAccountingAccountsByObject AS AccountingAccountSettings
		|	ON VATSettlementAccounts.ChartOfAccounts = AccountingAccountSettings.ChartOfAccounts
		|	 AND VATSettlementAccounts.PostingGenerationSetting = AccountingAccountSettings.PostingGenerationSetting
		|	 AND VATSettlementAccounts.SettingType = AccountingAccountSettings.SettingType
		|	 AND VATSettlementAccounts.Organization = AccountingAccountSettings.Organization
		|	 AND VATSettlementAccounts.PlaceOfRegistration = AccountingAccountSettings.PlaceOfRegistration
		|	 AND AccountingAccountSettings.AccountingObject = VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.Taxes)
		|	 AND AccountingAccountSettings.SettingObject1 = VALUE(Catalog.TaxContributionKinds.VAT)
		|WHERE
		|	(ISNULL(AccountingAccountSettings.GLAccount, VALUE(ChartOfAccounts.International.EmptyRef)) = VALUE(ChartOfAccounts.International.EmptyRef)
		|	 AND VATSettlementAccounts.GLAccount <> VALUE(ChartOfAccounts.International.EmptyRef))
		|	OR
		|	(ISNULL(AccountingAccountSettings.LedgerAccountLongTerm, VALUE(ChartOfAccounts.International.EmptyRef)) = VALUE(ChartOfAccounts.International.EmptyRef)
		|	 AND VATSettlementAccounts.LedgerAccountLongTerm <> VALUE(ChartOfAccounts.International.EmptyRef))
		|";
		
		Query = New Query(QueryText);
		Query.SetParameter("VATSettlementAccounts", VATSettlementAccounts);
		Result = Query.Execute();
		
		Selection = Result.Select();
		While Selection.Next() Do
			RecordManager = InformationRegisters.SettingsOfFinancialAccountingAccountsByObject.CreateRecordManager();
			FillPropertyValues(RecordManager, Selection);
			RecordManager.Write(True);
		EndDo;
	EndIf;
	
EndProcedure

#EndRegion

#EndIf