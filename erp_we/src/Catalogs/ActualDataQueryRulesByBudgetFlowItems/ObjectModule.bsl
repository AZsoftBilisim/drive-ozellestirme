#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure Filling(FillingData, FillingText, StandardProcessing)
	
	If TypeOf(FillingData) = Type("Structure")  Then
		FillPropertyValues(ThisObject, FillingData);
	EndIf;
	If Not ValueIsFilled(FinancialAccountingChartOfAccounts)
		And AccessRight("Read", FinancialAccountingChartOfAccounts.Metadata()) Then
		FinancialAccountingChartOfAccounts = Catalogs.FinancialAccountingChartsOfAccounts.DefaultChartOfAccounts();
	EndIf;
	CleanUpUnusedDataSourcesIfNecessary();
	
EndProcedure

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	NotCheckedAttributeArray = New Array;
	NotCheckedAttributeArray.Add("TransactionAmountSource");
	NotCheckedAttributeArray.Add("TotalType");
	
	If Not ValueIsFilled(DataSourceSection) Then
		NotCheckedAttributeArray.Add("DataSource");
	EndIf;
	
	If DataSourceSection <> Enums.SectionsOfBudgetingDataSources.FinancialAccounting Then
		NotCheckedAttributeArray.Add("FinancialAccountingChartOfAccounts");
	EndIf;
	
	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes, NotCheckedAttributeArray);
	
	TransactionAmountSourceNotFilledIn = 
		DataSourceSection = Enums.SectionsOfBudgetingDataSources.OperationalAccounting
		And Not ValueIsFilled(TransactionAmountSource);
		
	TotalTypeNotFilledIn = 
		(DataSourceSection = Enums.SectionsOfBudgetingDataSources.LocalAccounting
		Or DataSourceSection = Enums.SectionsOfBudgetingDataSources.FinancialAccounting
		Or (DataSourceSection = Enums.SectionsOfBudgetingDataSources.OperationalAccounting
			And Catalogs.ActualDataQueryRulesByBudgetFlowItems.RuleOnItemOfAssetsLiabilities(ThisObject)))
		And Not ValueIsFilled(TotalType);
	
	If TransactionAmountSourceNotFilledIn Then
		MessageText = NStr("vi = 'Trường số lượng trống';
							|ru = 'Поле Источник суммы не заполнено';
							|en = '""Amount source"" is required'; fa = '""Amount source"" is required';
							|it = 'Campo Origine importo non compilato';
							|pl = 'Nie wypełniono pola Źródło kwoty';
							|tr = 'Tutar kaynağı alanı doldurulmamış'");
		CommonClientServer.MessageToUser(
			MessageText, ,"TransactionAmountSource", "Record", Cancel);
	EndIf;
	
	If TotalTypeNotFilledIn Then
		MessageText = NStr("vi = 'Trường tổng loại chưa điền';
							|ru = 'Поле Тип итога не заполнено';
							|en = '""Total type"" is required'; fa = '""Total type"" is required';
							|it = 'Il campo Tipo del totale non è compilato';
							|pl = 'Nie wypełniono pola Typ';
							|tr = 'Toplam türü alanı doldurulmamış'");
		CommonClientServer.MessageToUser(
			MessageText, ,"TotalType", "Record", Cancel);
	EndIf;
	
EndProcedure

Procedure BeforeWrite(Cancel)
	
	If DataExchange.Load Then 
		Return;
	EndIf;

	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	
	Description = String(DataSourceSection) + ": " + DataSource;
	If ValueIsFilled(CorDataSource) Then
		Description = Description + ", " + CorDataSource;
	EndIf;
	If ValueIsFilled(TransactionAmountSource) Then
		Description = Description + ", " + TransactionAmountSource;
	EndIf;
	If ValueIsFilled(TotalType) Then
		Description = Description + ", " + TotalType;
	EndIf;
	If ValueIsFilled(FilterPresentation) Then
		Description = Description + ", " + FilterPresentation;
	EndIf;
	
	MaximumNumberOfAnalysts = BudgetingClientServer.MaximumNumberOfAnalysts();
	For Cnt = 1 To MaximumNumberOfAnalysts Do
		
		If ThisObject["FillInAnalyticsWithSpecifiedValue" + Cnt]
		   And ValueIsFilled(BudgetFlowItem["DimensionKind" + Cnt]) Then
			
			TypeOfAnalytics = BudgetFlowItem["DimensionKind" + Cnt].ValueType;
			ThisObject["DimensionValue" + Cnt] = BudgetingClientServer.ReducedAnalyticsValue(
				ThisObject["DimensionValue" + Cnt],
				TypeOfAnalytics);
				
		Else
			
			ThisObject["DimensionValue" + Cnt] = BudgetingClientServer.EmptyDimensionValue();
			
		EndIf;
		
	EndDo;
	
	// We will make a cast of the settings and the scheme for future comparison between them without analyzing each element.
	If Not DeletionMark Then
		BudgetingServer.FillInDetailsOfSettingsAndSchemaHashes(ThisObject);
	EndIf;
	
	// Fill in the settings for filling in the analytics
	If Not AdvancedModeOfDimensionFillSetting And Not DeletionMark Then
		BudgetingServer.FillInDetailsOfObjectInAnalyticsSettings(ThisObject);
	EndIf;
	
	SettingTransitionHistoryDetailsForNewFormulas();
	
	CheckingForChangesToCachedData();
	
EndProcedure

Procedure OnCopy(CopiedObject)
	
	CleanUpUnusedDataSourcesIfNecessary();
	
EndProcedure

#EndRegion

#Region Private

Procedure SettingTransitionHistoryDetailsForNewFormulas()
	
	If IsBlankString(DimensionPopulationExpression1HistoryOfTransitionToNewFormulas)
		And Not IsBlankString(DimensionPopulationExpression1) Then
		DimensionPopulationExpression1HistoryOfTransitionToNewFormulas = DimensionPopulationExpression1;
	EndIf;
	If IsBlankString(DimensionPopulationExpression2HistoryOfTransitionToNewFormulas)
		And Not IsBlankString(DimensionPopulationExpression2) Then
		DimensionPopulationExpression2HistoryOfTransitionToNewFormulas = DimensionPopulationExpression2;
	EndIf;
	If IsBlankString(DimensionPopulationExpression3HistoryOfTransitionToNewFormulas)
		And Not IsBlankString(DimensionPopulationExpression3) Then
		DimensionPopulationExpression2HistoryOfTransitionToNewFormulas = DimensionPopulationExpression3;
	EndIf;
	If IsBlankString(DimensionPopulationExpression4HistoryOfTransitionToNewFormulas)
		And Not IsBlankString(DimensionPopulationExpression4) Then
		DimensionPopulationExpression4HistoryOfTransitionToNewFormulas = DimensionPopulationExpression4;
	EndIf;
	If IsBlankString(DimensionPopulationExpression5HistoryOfTransitionToNewFormulas)
		And Not IsBlankString(DimensionPopulationExpression5) Then
		DimensionPopulationExpression5HistoryOfTransitionToNewFormulas = DimensionPopulationExpression5;
	EndIf;
	If IsBlankString(DimensionPopulationExpression6HistoryOfTransitionToNewFormulas)
		And Not IsBlankString(DimensionPopulationExpression6) Then
		DimensionPopulationExpression6HistoryOfTransitionToNewFormulas = DimensionPopulationExpression6;
	EndIf;
	
EndProcedure

Procedure CheckingForChangesToCachedData()
	
	ClearDocumentNameCache = False;
	ClearCacheOfBudgetTypes  = False;
	ClearCacheOfLimitSettings = False;
	
	If Not IsNew() Then
		
		PreviousDocumentReflectionOptions = Common.ObjectAttributesValues(Ref,
			"CachingOfRuleResults, DataSource, DataSourceSection, RuleType, HashOfDataCompositionSchema, DeletionMark");
		
		If CachingOfRuleResults
			Or PreviousDocumentReflectionOptions["CachingOfRuleResults"] Then
			
			For Each KeyAndValue In PreviousDocumentReflectionOptions Do
				If ThisObject[KeyAndValue.Key] <> KeyAndValue.Value Then
					If KeyAndValue.Key = "CachingOfRuleResults" Then
						ClearDocumentNameCache = True;
						ClearCacheOfBudgetTypes  = True;
					ElsIf KeyAndValue.Key = "DeletionMark" Then
						ClearCacheOfBudgetTypes  = True;
					Else
						ClearDocumentNameCache = True;
					EndIf;
				EndIf;
			EndDo;
		EndIf;
		
		If RuleType <> Enums.ActualBudgetingDataQueryRuleType.ActualData
			Or PreviousDocumentReflectionOptions["RuleType"] <> Enums.ActualBudgetingDataQueryRuleType.ActualData Then
			ClearCacheOfLimitSettings = True;
		EndIf;
		
	Else
		
		If CachingOfRuleResults Then
			ClearCacheOfBudgetTypes = True;
		EndIf;
		If RuleType <> Enums.ActualBudgetingDataQueryRuleType.ActualData Then
			ClearCacheOfLimitSettings = True;
		EndIf;
		
	EndIf;
	
	If ClearCacheOfLimitSettings
		And LimitsByBudgetingDataServer.BudgetFlowItemIsUsedInLimitSettings(BudgetFlowItem, True) Then
		SetOfCacheSettingsLimits = InformationRegisters.BudgetingLimitSettingsCache.CreateRecordSet();
		SetPrivilegedMode(True);
		SetOfCacheSettingsLimits.Write();
		SetPrivilegedMode(False);
	EndIf;
	
	If ClearDocumentNameCache Then
		NamesOfReflectedDocuments = InformationRegisters.DocumentNameCacheForProcessingByRule.CreateRecordSet();
		NamesOfReflectedDocuments.Filter.Rule.Set(Ref);
		SetPrivilegedMode(True);
		NamesOfReflectedDocuments.Write(True);
		SetPrivilegedMode(False);
	EndIf;
	If ClearCacheOfBudgetTypes Then
		OtherTypesOfBudget = GetBudgetTypesThatUseRule();
		For Each BudgetProfile In OtherTypesOfBudget Do
			RecruitmentByBudgetType = InformationRegisters.CacheOfAuxiliaryBudgetProfileData.CreateRecordSet();
			RecruitmentByBudgetType.Filter.BudgetProfile.Set(BudgetProfile);
			SetPrivilegedMode(True);
			RecruitmentByBudgetType.Write(True);
			SetPrivilegedMode(False);
		EndDo;
	EndIf;
	
EndProcedure

Function GetBudgetTypesThatUseRule()
	
	// The rule for obtaining factual data on an article can be used in the cache
	// to obtain a fact on an article or as a fact affecting an indicator.
	Query = New Query;
	Query.SetParameter("BudgetFlowItem", BudgetFlowItem);
	Query.Text =
	"SELECT
	|	CalculationsRules.Receiver AS ItemIndicator
	|INTO ArticlesAndIndicators
	|FROM
	|	Catalog.RuleForCalculatingRelatedBudgetBalancesAndTurnovers AS CalculationsRules
	|WHERE
	|	CalculationsRules.Source = &BudgetFlowItem
	|	AND NOT CalculationsRules.DeletionMark
	|	AND CalculationsRules.Status = VALUE(Enum.BudgetingRuleStatuses.Valid)
	|
	|UNION ALL
	|
	|SELECT
	|	BudgetFlowItems.Ref
	|FROM
	|	Catalog.BudgetFlowItems AS BudgetFlowItems
	|WHERE
	|	BudgetFlowItems.Ref = &BudgetFlowItem
	|
	|INDEX BY
	|	ItemIndicator
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	BudgetProfilesItemAndIndicatorCache.Ref AS BudgetProfile
	|FROM
	|	Catalog.BudgetProfiles.ItemAndIndicatorCache AS BudgetProfilesItemAndIndicatorCache
	|WHERE
	|	BudgetProfilesItemAndIndicatorCache.ItemIndicator IN
	|			(SELECT
	|				T.ItemIndicator
	|			FROM
	|				ArticlesAndIndicators AS T)";
	
	Return Query.Execute().Unload().UnloadColumn("BudgetProfile");
	
EndFunction

Procedure CleanUpUnusedDataSourcesIfNecessary()
	
	If DataSourceSection = Enums.SectionsOfBudgetingDataSources.OperationalAccounting Then
		If GetFunctionalOption("SetUpRulesForObtainingActualDataByAssetAndLiabilityItems")
			And RuleType = Enums.ActualBudgetingDataQueryRuleType.ActualData Then
			If ValueIsFilled(DataSource) And Not DataSourcesServer.ThisIsItemOfAssetsLiabilities(DataSource) Then
				DataSource = Undefined;
			EndIf;
			If ValueIsFilled(CorDataSource) And Not DataSourcesServer.ThisIsItemOfAssetsLiabilities(CorDataSource) Then
				CorDataSource = Undefined;
			EndIf;
		Else
			If ValueIsFilled(DataSource) And Not DataSourcesServer.ThisIsSettingUpBusinessOfOperation(DataSource) Then
				DataSource = Undefined;
			EndIf;
			If ValueIsFilled(CorDataSource) Then
				CorDataSource = Undefined;
			EndIf;
			If ValueIsFilled(TotalType) Then
				TotalType = Undefined;
			EndIf;
		EndIf;
	EndIf;
	
EndProcedure

#EndRegion

#EndIf
