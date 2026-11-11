#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	AccountingSettings = ChartsOfCharacteristicTypes.AssetLiabilityItems.FinancialAccounting_Settings();
	Filter_Settings = ChartsOfCharacteristicTypes.AssetLiabilityItems.SettingsForSelectingItemsOfAssetsLiabilities();
	
	If TypeOf(Parameters.FinancialAccounting_Settings) = Type("Structure") Then
		FillPropertyValues(AccountingSettings, Parameters.FinancialAccounting_Settings);
	Else
		
		TransactionSettings = Catalogs.FinancialAccountingPostingGenerationSetting.TransactionGenerationSettings(
			Parameters.PostingGenerationSetting);
		
		If TransactionSettings.RevenueExcludingVAT = Undefined Then
			TransactionSettings.RevenueExcludingVAT = True;
		EndIf;
		
		FillPropertyValues(AccountingSettings,
			FinancialAccountingByFinancialRegisterData.AccountingSettingsByTransactionGenerationSettings(TransactionSettings));
		
	EndIf;
	
	If TypeOf(Parameters.ThereIsDataSource) = Type("Boolean") Then
		Filter_Settings.ThereIsDataSource = Parameters.ThereIsDataSource;
	EndIf;
	
	ArticlesKinds = Undefined;
	AccountingDataTypes = Undefined;
	LedgerAccountsInEntrySettings = False;
	NotOwnedControlledValues = False;
	
	If Parameters.Property("Filter") Then
		If Parameters.Filter.Property("Kind", ArticlesKinds) And ValueIsFilled(ArticlesKinds) Then
			Filter_Settings.Kind = TMCommonUseClientServer.Array(ArticlesKinds);
		EndIf;
		If Parameters.Filter.Property("TypeOfAccountingData", AccountingDataTypes) And ValueIsFilled(AccountingDataTypes) Then
			Filter_Settings.TypeOfAccountingData = TMCommonUseClientServer.Array(AccountingDataTypes);
		EndIf;
		If Parameters.Filter.Property("LedgerAccountsInEntrySettings", LedgerAccountsInEntrySettings) Then
			Filter_Settings.LedgerAccountsInEntrySettings = LedgerAccountsInEntrySettings;
		EndIf;
		If Parameters.Filter.Property("NotOwnedControlledValues", NotOwnedControlledValues) Then
			AccountingSettings.AccountingForImproperValues = NotOwnedControlledValues;
		EndIf;
	EndIf;
	
	Common.FillFormDataTreeItemCollection(
		TreeOfAccountingObjects.GetItems(),
		ChartsOfCharacteristicTypes.AssetLiabilityItems.TreeOfFinancialAccountingObjects(AccountingSettings, Filter_Settings));
	
	AccumulationRegistersMetadata = Metadata.AccumulationRegisters;
	
	For Each Var_Group In TreeOfAccountingObjects.GetItems() Do
		For Each AccountingObjectLine In Var_Group.GetItems() Do
			If AccountingObjectLine.AccountingObject = Parameters.CurrentRow Then
				Items.TreeOfAccountingObjects.CurrentRow = AccountingObjectLine.GetID();
			EndIf;
			
			RegisterMetadata = AccumulationRegistersMetadata.Find(AccountingObjectLine.DataSource);
			If RegisterMetadata <> Undefined Then
				AccountingObjectLine.DataSourcePresentation = RegisterMetadata.Synonym;
			EndIf;
		EndDo;
	EndDo;
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersTreeOfAccountingObjects

&AtClient
Procedure TreeOfAccountingObjectsSelection(Item, RowSelected, Field, StandardProcessing)
	
	CurrentData = TreeOfAccountingObjects.FindByID(RowSelected);
	If CurrentData.IsFolder Then
		Return;
	EndIf;
	
	NotifyChoice(CurrentData.AccountingObject);
	
EndProcedure

&AtClient
Procedure TreeOfAccountingObjectsValueChoice(Item, Value, StandardProcessing)
	
	CurrentData = TreeOfAccountingObjects.FindByID(Value);
	If CurrentData.IsFolder Then
		Return;
	EndIf;
	
	NotifyChoice(CurrentData.AccountingObject);

EndProcedure

#EndRegion