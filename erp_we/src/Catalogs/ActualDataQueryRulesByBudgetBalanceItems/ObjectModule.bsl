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
	ClearUnusedDataSourceIfNecessary();
	
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
	
	RuleOnItemOfAssetsLiabilities = Catalogs.ActualDataQueryRulesByBudgetBalanceItems.RuleOnItemOfAssetsLiabilities(ThisObject);
	
	TransactionAmountSourceNotFilledIn = DataSourceSection = Enums.SectionsOfBudgetingDataSources.OperationalAccounting
		And RuleOnItemOfAssetsLiabilities And Not ValueIsFilled(TransactionAmountSource);
	
	TotalTypeNotFilledIn = (DataSourceSection = Enums.SectionsOfBudgetingDataSources.LocalAccounting
							Or DataSourceSection = Enums.SectionsOfBudgetingDataSources.FinancialAccounting)
						And Not ValueIsFilled(TotalType);
	
	If TransactionAmountSourceNotFilledIn Then
		MessageText = NStr("vi = 'Trường số lượng trống';
							|ru = 'Поле Источник суммы не заполнено';
							|en = '""Amount source"" is required'; fa = '""Amount source"" is required';
							|it = 'Campo Origine importo non compilato';
							|pl = 'Nie wypełniono pola Źródło kwoty';
							|tr = 'Tutar kaynağı alanı doldurulmamış'");
		Common.MessageToUser(MessageText,,"TransactionAmountSource", "Object", Cancel);
	EndIf;
	
	If TotalTypeNotFilledIn Then
		MessageText = NStr("vi = 'Chưa điền trường Kiểu tổng số';
							|ru = 'Поле Тип итога не заполнено';
							|en = '""Total type"" is required'; fa = '""Total type"" is required';
							|it = 'Il campo Tipo del totale non è compilato';
							|pl = 'Nie wypełniono pola Typ';
							|tr = 'Toplam türü alanı doldurulmamış'");
		Common.MessageToUser(	MessageText,,"TotalType", "Object", Cancel);
	EndIf;
	
	If DataSourceSection = Enums.SectionsOfBudgetingDataSources.OperationalAccounting
		And RuleOnItemOfAssetsLiabilities Then
		TypeOfArticle = Common.ObjectAttributeValue(DataSource, "Type");
		If TypeOfArticle = Enums.AssetAndLiabilityItemKinds.Income_2
		 Or TypeOfArticle = Enums.AssetAndLiabilityItemKinds.Expense Then
			MessageText = StrTemplate(
				NStr("vi = 'Dạng tài sản/nguồn vốn có dạng ""%1"" không thể là nguồn của dữ liệu thực tế của chỉ tiêu ngân sách.';
					|ru = 'Статья активов/пассивов с видом ""%1"" не может быть источником фактических данных показателя бюджетов.';
					|en = 'An asset/liability item with the ""%1"" type cannot be a source of actual budget balance item data.'; fa = 'An asset/liability item with the ""%1"" type cannot be a source of actual budget balance item data.';
					|it = 'An asset/liability item with the ""%1"" type cannot be a source of actual budget balance item data.';
					|pl = 'An asset/liability item with the ""%1"" type cannot be a source of actual budget balance item data.';
					|tr = '""%1"" türündeki varlık/yükümlülük kalemi, bütçe göstergesi için gerçek veri kaynağı olamaz.'"),
				TypeOfArticle);
			Common.MessageToUser(MessageText,,"DataSource", "Object", Cancel);
		EndIf;
	EndIf;
	
EndProcedure

Procedure BeforeWrite(Cancel)
	
	If DataExchange.Load Then 
		Return;
	EndIf;

	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	
	Description = String(DataSourceSection) + ": " + DataSource;
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
		   And ValueIsFilled(BudgetBalanceItem["DimensionKind" + Cnt]) Then
			
			TypeOfAnalytics = BudgetBalanceItem["DimensionKind" + Cnt].ValueType;
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
	If Not AdvancedModeOfDimensionFillSetting Then
		BudgetingServer.FillInDetailsOfObjectInAnalyticsSettings(ThisObject);
	EndIf;
	
	SettingTransitionHistoryDetailsForNewFormulas();
	
EndProcedure

Procedure OnCopy(CopiedObject)
	
	ClearUnusedDataSourceIfNecessary();
	
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

Procedure ClearUnusedDataSourceIfNecessary()
	
	If DataSourceSection = Enums.SectionsOfBudgetingDataSources.OperationalAccounting Then
		If GetFunctionalOption("SetUpRulesForObtainingActualDataByAssetAndLiabilityItems") Then
			If ValueIsFilled(DataSource) And Not DataSourcesServer.ThisIsItemOfAssetsLiabilities(DataSource) Then
				DataSource = Undefined;
			EndIf;
		Else
			If ValueIsFilled(DataSource) And Not DataSourcesServer.ThisIsItemOfManagementBalanceSheet(DataSource) Then
				DataSource = Undefined;
			EndIf;
			If ValueIsFilled(TransactionAmountSource) Then
				TransactionAmountSource = Undefined;
			EndIf;
		EndIf;
	EndIf;
	
EndProcedure

#EndRegion

#EndIf
