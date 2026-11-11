#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Internal

Function ThereAreDisabledRulesForGettingFact(BudgetBalanceItem = Undefined, DataSource = Undefined) Export
	
	QueryText = "
	|SELECT TOP 1
	|	TRUE
	|FROM
	|	Catalog.ActualDataQueryRulesByBudgetBalanceItems AS ActualDataQueryRules_
	|	INNER JOIN ChartOfCharacteristicTypes.AssetLiabilityItems AS AssetLiabilityItems
	|	ON ActualDataQueryRules_.DataSource = AssetLiabilityItems.Ref
	|WHERE
	|	ActualDataQueryRules_.DataSourceSection = VALUE(Enum.SectionsOfBudgetingDataSources.OperationalAccounting)
	|	AND NOT ActualDataQueryRules_.DeletionMark
	|	AND AssetLiabilityItems.Predefined
	|	AND &ThisIsDisabledSettingRule
	|	AND &SelectionCriteriaByBudgetIndicator
	|	AND &SelectionCriteriaByDataSource
	|";
	
	If GetFunctionalOption("SetUpRulesForObtainingActualDataByAssetAndLiabilityItems") Then
		ThisIsDisabledSettingRule = "AssetLiabilityItems.DataSource = """"";
	Else
		ThisIsDisabledSettingRule = "AssetLiabilityItems.NameOfBudgetDataSource = """"";
	EndIf;
	
	If ValueIsFilled(BudgetBalanceItem) Then
		SelectionCriteriaByBudgetIndicator = "ActualDataQueryRules_.BudgetBalanceItem = &BudgetBalanceItem";
	Else
		SelectionCriteriaByBudgetIndicator = "TRUE";
	EndIf;
	
	If ValueIsFilled(DataSource) Then
		SelectionCriteriaByDataSource = "ActualDataQueryRules_.DataSource = &DataSource";
	Else
		SelectionCriteriaByDataSource = "TRUE";
	EndIf;
	
	QueryText = StrReplace(QueryText, "&ThisIsDisabledSettingRule", ThisIsDisabledSettingRule);
	QueryText = StrReplace(QueryText, "&SelectionCriteriaByBudgetIndicator", SelectionCriteriaByBudgetIndicator);
	QueryText = StrReplace(QueryText, "&SelectionCriteriaByDataSource", SelectionCriteriaByDataSource);
	
	Query = New Query(QueryText);
	Query.SetParameter("BudgetBalanceItem", BudgetBalanceItem);
	Query.SetParameter("DataSource", DataSource);
	
	Result = Query.Execute();
	
	Return Not Result.IsEmpty();
	
EndFunction

Function RuleOnItemOfAssetsLiabilities(Rule) Export
	
	RuleType = TypeOf(Rule);
	
	If RuleType = Type("CatalogRef.ActualDataQueryRulesByBudgetBalanceItems") Then
		AttributeValuesForRule = Common.ObjectAttributesValues(
			Rule, "DataSource,DataSourceSection");
	ElsIf RuleType = Type("CatalogObject.ActualDataQueryRulesByBudgetBalanceItems") Then
		AttributeValuesForRule = Rule;
	ElsIf (RuleType = Type("Structure") Or RuleType = Type("FormDataStructure"))
		And Rule.Property("DataSource") And Rule.Property("DataSourceSection") Then
		AttributeValuesForRule = Rule;
	ElsIf RuleType = Type("ValueTableRow") Then
		RulesTable = Rule.Owner(); // ValueTable -
		ColumnsOfRulesTable = RulesTable.Columns;
		If ColumnsOfRulesTable.Find("DataSource") <> Undefined
		   And ColumnsOfRulesTable.Find("DataSourceSection") <> Undefined Then
			AttributeValuesForRule = Rule;
		Else
			Return False;
		EndIf;
	Else
		Return False;
	EndIf;
	
	Return AttributeValuesForRule.DataSourceSection = Enums.SectionsOfBudgetingDataSources.OperationalAccounting
		And ?(ValueIsFilled(AttributeValuesForRule.DataSource),
			?(GetFunctionalOption("SetUpRulesForObtainingActualDataByAssetAndLiabilityItems"),
				DataSourcesServer.ThisIsItemOfAssetsLiabilities(AttributeValuesForRule.DataSource),
				Not DataSourcesServer.ThisIsItemOfManagementBalanceSheet(AttributeValuesForRule.DataSource)),
			GetFunctionalOption("SetUpRulesForObtainingActualDataByAssetAndLiabilityItems"));
	
EndFunction

#EndRegion

#Region Private

#Region Reports

// Defines a list of report commands.
//
// Parameters:
//   ReportsCommands - See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
//   Parameters - See ReportsOptionsOverridable.BeforeAddReportCommands.Parameters
//
Procedure AddReportCommands(ReportsCommands, Parameters) Export
	Reports.ResultOfActualDataQuery.AddBudgetIndicatorReportCommand(ReportsCommands);
EndProcedure

#EndRegion

#Region SetUpRulesForObtainingActualDataByAssetAndLiabilityItems

Procedure ChangeSettingsForFactReceiptRules(Parameters, StorageAddress) Export
	
	LoansIssuedByManBalance = New Array();
	LoansIssuedByManBalance.Add(ChartsOfCharacteristicTypes.AssetLiabilityItems.IssuedBorrowings);
	
	LoansIssuedAccountingObjects = New Array();
	LoansIssuedAccountingObjects.Add(ChartsOfCharacteristicTypes.AssetLiabilityItems.DepositsLoansLoansIssuedDebt);
	LoansIssuedAccountingObjects.Add(ChartsOfCharacteristicTypes.AssetLiabilityItems.DepositsLoansLoansIssuedFee);
	LoansIssuedAccountingObjects.Add(ChartsOfCharacteristicTypes.AssetLiabilityItems.DepositsLoansLoansIssuedInterest);
	
	SettingUpRulesForAssetLiabilityItems = Parameters.SetUpRulesForObtainingActualDataByAssetAndLiabilityItems;
	AllLoansIssued = Common.CopyRecursive(LoansIssuedByManBalance);
	
	If Not SettingUpRulesForAssetLiabilityItems Then
		CommonClientServer.SupplementArray(AllLoansIssued, LoansIssuedAccountingObjects);
	EndIf;
	
	SetPrivilegedMode(True);
	
	QueryText = "
	|SELECT
	|	ActualDataQueryRules_.Ref AS Ref,
	|	ActualDataQueryRules_.DataSource AS DataSource,
	|	ActualDataQueryRules_.TransactionAmountSource AS TransactionAmountSource,
	|	ActualDataQueryRules_.SettingsComposer AS SettingsComposer,
	|	CAST(ActualDataQueryRules_.FilterPresentation AS STRING(16)) AS FilterPresentation
	|FROM
	|	Catalog.ActualDataQueryRulesByBudgetBalanceItems AS ActualDataQueryRules_
	|WHERE
	|	NOT ActualDataQueryRules_.DeletionMark
	|	AND ActualDataQueryRules_.DataSourceSection = VALUE(Enum.SectionsOfBudgetingDataSources.OperationalAccounting)
	|	AND (ActualDataQueryRules_.DataSource IN (&IssuedBorrowings)
	|	OR (ActualDataQueryRules_.DataSource IN (
	|		VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.Taxes),
	|		VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.Payroll))
	|	AND ActualDataQueryRules_.TransactionAmountSource = VALUE(Enum.IndicatorsOfAnalyticalRegisters.EmptyRef)))
	|";
		
	Query = New Query(QueryText);
	Query.SetParameter("IssuedBorrowings", AllLoansIssued);
	Result = Query.Execute();
	
	BeginTransaction();
	
	Try
		
		Block = New DataLock();
		LockItem = Block.Add("Catalog.ActualDataQueryRulesByBudgetBalanceItems");
		LockItem.DataSource = Result;
		LockItem.UseFromDataSource("Ref", "Ref");
		LockItem.Mode = DataLockMode.Exclusive;
		Block.Lock();
		
		Selection = Result.Select();
		While Selection.Next() Do
			RuleObject_ = Selection.Ref.GetObject(); // 
			
			If SettingUpRulesForAssetLiabilityItems Then
				If LoansIssuedByManBalance.Find(Selection.DataSource) <> Undefined
				And Not ValueIsFilled(Selection.TransactionAmountSource) Then
					If IsBlankString(Selection.FilterPresentation) Then
						NewSourceOfData = ChartsOfCharacteristicTypes.AssetLiabilityItems.DepositsLoansLoansIssuedDebt;
					Else
						AmountType = TypeOfAmountFromRuleSelection(Selection.SettingsComposer);
						If AmountType = Enums.LoanAndDepositScheduleAmountTypes.Fee Then
							NewSourceOfData = ChartsOfCharacteristicTypes.AssetLiabilityItems.DepositsLoansLoansIssuedFee;
						ElsIf AmountType = Enums.LoanAndDepositScheduleAmountTypes.Interests Then
							NewSourceOfData = ChartsOfCharacteristicTypes.AssetLiabilityItems.DepositsLoansLoansIssuedInterest;
						Else
							NewSourceOfData = ChartsOfCharacteristicTypes.AssetLiabilityItems.DepositsLoansLoansIssuedDebt;
						EndIf;
					EndIf;
					RuleObject_.DataSource = NewSourceOfData;
					RuleObject_.TransactionAmountSource = Enums.IndicatorsOfAnalyticalRegisters.Sum;
				EndIf;
			Else
				If LoansIssuedAccountingObjects.Find(Selection.DataSource) <> Undefined Then
					NewSourceOfData = ChartsOfCharacteristicTypes.AssetLiabilityItems.IssuedBorrowings;
					RuleObject_.DataSource = NewSourceOfData;
					RuleObject_.TransactionAmountSource = Undefined;
				EndIf;
				
				If LoansIssuedByManBalance.Find(Selection.DataSource) <> Undefined
					And ValueIsFilled(Selection.TransactionAmountSource) Then
					RuleObject_.DeletionMark = True;
				EndIf;
			EndIf;
			
			If Selection.DataSource = ChartsOfCharacteristicTypes.AssetLiabilityItems.Taxes
			 Or Selection.DataSource = ChartsOfCharacteristicTypes.AssetLiabilityItems.Payroll Then
				If Not ValueIsFilled(Selection.TransactionAmountSource) Then
					RuleObject_.TransactionAmountSource = Enums.IndicatorsOfAnalyticalRegisters.Sum;
				EndIf;
			EndIf;
			
			If RuleObject_.Modified() Then
				RuleObject_.Write();
			EndIf;
		EndDo;
		
		CommitTransaction();
		
	Except
		
		RollbackTransaction();
		
		ErrorText = StrTemplate(
			NStr("vi = 'Không thể thay đổi cài đặt quy tắc nhận dữ liệu thực tế theo chỉ tiêu do nguyên nhân: %1';
				|ru = 'Не удалось изменить настройки правил получения фактических данных по показателям по причине: %1';
				|en = 'Cannot change the settings of actual data query rules by items. Reason: %1'; fa = 'Cannot change the settings of actual data query rules by items. Reason: %1';
				|it = 'Cannot change the settings of actual data query rules by items. Reason: %1';
				|pl = 'Cannot change the settings of actual data query rules by items. Reason: %1';
				|tr = 'Şu nedenle göstergelere ait gerçek veri alma kurallarının ayarları değiştirilemedi: %1'"),
			ErrorProcessing.DetailErrorDescription(ErrorInfo()));
		
		WriteLogEvent(
			NStr("vi = 'Thay đổi cài đặt quy tắc nhận dữ liệu thực tế theo chỉ tiêu.';
				|ru = 'Изменение настроек правил получения фактических данных по показателям.';
				|en = 'Change the settings of actual data query rules by items.'; fa = 'Change the settings of actual data query rules by items.';
				|it = 'Change the settings of actual data query rules by items.';
				|pl = 'Change the settings of actual data query rules by items.';
				|tr = 'Göstergelere ait gerçek veri alma kurallarının ayarlarının değiştirilmesi.'",
			Common.DefaultLanguageCode()),
			EventLogLevel.Error,
			Metadata.Catalogs.ActualDataQueryRulesByBudgetBalanceItems,,
			ErrorText);
		
		Raise ErrorText;
		
	EndTry;
	
	PutToTempStorage(Parameters, StorageAddress);
	
EndProcedure

Function TypeOfAmountFromRuleSelection(SettingsStorage)
	
	AmountType = Enums.LoanAndDepositScheduleAmountTypes.EmptyRef();
	
	SettingsComposer = New DataCompositionSettingsComposer();
	CompositionSettings = SettingsStorage.Get(); // DataCompositionSettings
	
	ChartsOfCharacteristicTypes.AssetLiabilityItems.InitializeSettingsComposerWithDataSource(
		SettingsComposer, Metadata.AccumulationRegisters.FinancialInstrumentsARAP.Name);
	
	If TypeOf(CompositionSettings) = Type("DataCompositionSettings") Then
		SettingsComposer.LoadSettings(CompositionSettings);
	EndIf;
	
	Filter_Settings = SettingsComposer.Settings.Filter;
	SelectionForEqualityOfSumType = Undefined;
	
	For Each FilterElement In Filter_Settings.Items Do
		If FilterElement.Use = True
			And TypeOf(FilterElement) = Type("DataCompositionFilterItem")
			And FilterElement.LeftValue = New DataCompositionField("AmountType")
			And FilterElement.ComparisonType = DataCompositionComparisonType.Equal Then
			SelectionForEqualityOfSumType = FilterElement;
			Break;
		EndIf;
	EndDo;
	
	If SelectionForEqualityOfSumType <> Undefined Then
		AmountType = SelectionForEqualityOfSumType.RightValue;
	EndIf;
	
	Return AmountType;
	
EndFunction

#EndRegion

#EndRegion

#EndIf
