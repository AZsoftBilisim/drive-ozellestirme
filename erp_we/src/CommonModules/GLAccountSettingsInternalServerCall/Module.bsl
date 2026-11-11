
#Region Internal


Function LinkToNewInvoiceSettingsElement() Export
	
	Return Catalogs.OtherTransactionsGLAccountsSettings.GetRef();
	
EndFunction

Function DefaultAccountSettingsData(AssetLiabilityItems, Val AccountSettingsData_1 = Undefined) Export
	
	ReturnValue = New Map();
	
	If TypeOf(AssetLiabilityItems) = Type("Array") Then
		ListOfArticles = AssetLiabilityItems;
	Else
		ListOfArticles = CommonClientServer.ValueInArray(AssetLiabilityItems);
	EndIf;
	
	SetPrivilegedMode(True);
	
	Query = New Query();
	Query.SetParameter("ListOfArticles", ListOfArticles);
	Query.Text = "
	|SELECT
	|	AssetLiabilityItems.Ref    AS Ref
	|	,
	|	AssetLiabilityItems.LedgerAccountsInEntrySettings AS LedgerAccountsInEntrySettings,
	|	AssetLiabilityItems.FinancialAccountingSettings AS FinancialAccountingSettings
	|FROM
	|	ChartOfCharacteristicTypes.AssetLiabilityItems AS AssetLiabilityItems
	|WHERE
	|	AssetLiabilityItems.Ref IN (&ListOfArticles)
	|";
	
	Result = Query.Execute();
	SelectingSettings = Result.Select();
	
	While SelectingSettings.Next() Do
		ConfigurationData = GLAccountSettingsClientServer.CompositionOfAccountingAccountSettings();
		SettingFilledIn = False;
		If Not SelectingSettings.LedgerAccountsInEntrySettings Then
			ResultOfSettingUpInternationalAccounting = SelectingSettings.FinancialAccountingSettings; // QueryResultSelection -
			SelectionOfInternationalAccountingSettings = ResultOfSettingUpInternationalAccounting.Select();
			While SelectionOfInternationalAccountingSettings.Next() Do
				If ValueIsFilled(SelectionOfInternationalAccountingSettings.GLAccount) Then
					InternationalConfigurationData = GLAccountSettingsClientServer.CompositionOfInternationalAccountingAccounts();
					FillPropertyValues(InternationalConfigurationData, SelectionOfInternationalAccountingSettings);
					ConfigurationData.FinancialAccountingSettings.Add(InternationalConfigurationData);
					SettingFilledIn = True;
				EndIf;
			EndDo;
		EndIf;
		If SettingFilledIn Then
			ReturnValue.Insert(SelectingSettings.Ref,
				New Structure("ConfigurationData,GLAccountSettings",
					ConfigurationData, LinkToNewInvoiceSettingsElement()));
		EndIf;
	EndDo;
	
	Return ReturnValue;
	
EndFunction

Function AccountingAccountsAreSpecifiedInTransactionSettings(AssetAndLiabilityItem) Export
	
	LedgerAccountsInEntrySettings = False;
	
	SetPrivilegedMode(True);
	
	If ValueIsFilled(AssetAndLiabilityItem)
		And TypeOf(AssetAndLiabilityItem) = Type("ChartOfCharacteristicTypesRef.AssetLiabilityItems") Then
		LedgerAccountsInEntrySettings = Common.ObjectAttributeValue(AssetAndLiabilityItem, "LedgerAccountsInEntrySettings");
	EndIf;
	
	Return LedgerAccountsInEntrySettings;
	
EndFunction

Function YouCanConfigureAccountingAccounts() Export
	
	Return GLAccountSettingsServer.LocalAccountingAccountsCanBeConfigured()
		Or GLAccountSettingsServer.SettingUpInternationalAccountingAccountsIsAvailable();
	
EndFunction

#Region SettingUpExtdimensionSelection

Function DescriptionOfAllDocumentsType() Export
	
	Return Documents.AllRefsType() ;
	
EndFunction

Function DescriptionOfContractTypes(OnlyWithCounterparty = True) Export
	
	ContractTypes = New Array;
	ContractTypes.Add(Type("CatalogRef.CounterpartyContracts"));
	ContractTypes.Add(Type("CatalogRef.LoanAndDepositContracts"));
	ContractTypes.Add(Type("CatalogRef.LeaseContract"));
	
	If Not OnlyWithCounterparty Then
		ContractTypes.Add(Type("CatalogRef.IntercompanyContracts"));
	EndIf;
	
	Return New TypeDescription(ContractTypes);
	
EndFunction

Function AllTypesOfExtdimensionRelated() Export
	
	RelatedExtdimension = New Map;
	
	SetTypesOfRelatedExtdimension(RelatedExtdimension);
	
	RelatedExtdimension.Insert("Organization", GLAccountSettingsServer.TypesConnectedWithTheCompany());
	
	Return RelatedExtdimension;
	
EndFunction

Procedure SetTypesOfRelatedExtdimension(RelatedExtdimension) Export
	
	TypesOfExtdimension =  DescriptionOfContractTypes(True);
	TypesOfExtdimension = New TypeDescription(TypesOfExtdimension, Documents.AllRefsType().Types());
	TypesOfExtdimension = New TypeDescription(TypesOfExtdimension,"CatalogRef.CounterpartyBankAccounts");
	RelatedExtdimension.Insert("Counterparty", TypesOfExtdimension);
	RelatedExtdimension.Insert("Partner", TypesOfExtdimension);
	
	TypesOfExtdimension = New TypeDescription("CatalogRef.CounterpartyBankAccounts");
	RelatedExtdimension.Insert("Individual", TypesOfExtdimension);
	
	TypesOfExtdimension = New TypeDescription(Documents.AllRefsType().Types());
	RelatedExtdimension.Insert("AdvanceHolder", TypesOfExtdimension);
	
	TypesOfExtdimension = New TypeDescription("CatalogRef.CCDNumbers");
	RelatedExtdimension.Insert("WorldCountries", TypesOfExtdimension);
	
	
	TypesOfExtdimension = New TypeDescription("CatalogRef.Products");
	RelatedExtdimension.Insert("ItemsType", TypesOfExtdimension);
	RelatedExtdimension.Insert("FinancialProductAccountingGroup", TypesOfExtdimension);
	RelatedExtdimension.Insert("AnalyticalProductGroup", TypesOfExtdimension);
	
EndProcedure

Function GetAccountProperties(Account) Export
	
	
	If TypeOf(Account) = FinancialAccountingClientServer.TypeChartOfAccounts() Then
		Return FinancialAccountingServerCall.AccountProperties(Account);
	EndIf;
EndFunction

#EndRegion

// Checks whether the transferred invoice is an INV account
// 
// Parameters:
//  GLAccount - See LocalAccntingClientServer.TypeChartOfAccounts
// 
// Returns:
//  Boolean
Function ThisIsINVAccount(GLAccount) Export
	
	ThisIsINVAccount = False;
	
	
	Return ThisIsINVAccount;
	
EndFunction

// See Catalogs.Companies.ArrayOfInterconnectedOrganizations
// 
// Parameters:
//  Organization - CatalogRef.Companies
// 
// Returns:
//  Array of CatalogRef.Companies
Function ArrayOfInterconnectedOrganizations(Organization) Export
	
	Return Catalogs.Companies.ArrayOfInterconnectedOrganizations(Organization);
	
EndFunction

#EndRegion
