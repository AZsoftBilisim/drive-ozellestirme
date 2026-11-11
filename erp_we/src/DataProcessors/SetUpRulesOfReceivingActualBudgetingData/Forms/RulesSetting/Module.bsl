
&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetConditionalAppearance();
	
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;

	SettingObject1 = Parameters.SettingObject1;
	If Not Parameters.Property("SettingObject1", SettingObject1) Then
		MessageText = NStr("vi = 'Không thể mở trực tiếp biểu mẫu này. Để mở biểu mẫu, bạn có thể sử dụng lệnh ""Thiết lập nguyên tắc"" trong biểu mẫu thiết lập nguyên tắc nhận dữ liệu thực tế.';
							|ru = 'Непосредственное открытие этой формы не предусмотрено. Для открытия формы можно воспользоваться командой ""Настроить правила"" в форме настроек правил получения факта.';
							|en = 'Application cannot open this form explicitly. It opens implicitly when you select the ""Configure rules"" command in the settings form of actual receipt rules.'; fa = 'Application cannot open this form explicitly. It opens implicitly when you select the ""Configure rules"" command in the settings form of actual receipt rules.';
							|it = 'L''apertura diretta di questo modulo non è prevista. Per aprire un modulo, è possibile utilizzare il comando ""Configura regole"" sotto forma di impostazioni per la ricezione delle regole dei fatti.';
							|pl = 'Bezpośrednie otwieranie tego formularza nie jest zapewnione. Aby otworzyć formularz, możesz użyć polecenia ""Konfiguruj reguły"" w formie ustawień do odbierania reguł faktów.';
							|tr = 'Bu formun doğrudan açılması sağlanamadı. Formun açılması için veri alma kuralı rapor ayarları formunda yer alan ""Kuralları ayarla"" komutundan faydalanabilirsiniz .'");
		Raise MessageText;
	ElsIf SettingObject1 = Undefined Then
		Raise NStr("vi = 'Không có đối tượng cài đặt nào được chọn!';
					|ru = 'Не выбран объект настройки!';
					|en = 'Configuration object is not selected.'; fa = 'Configuration object is not selected.';
					|it = 'Oggetto dell''impostazione non selezionato!';
					|pl = 'Nie wybrano żadnego obiektu ustawień!';
					|tr = 'Ayar nesnesi seçilmemiş!'");
	EndIf;
	
	RuleTypeBudgetItem = Enums.ActualBudgetingDataQueryRuleType.ActualData;
	RuleTypeBudgetIndicator = Enums.ActualBudgetingDataQueryRuleType.ActualData;
	SettingUpRulesForAssetLiabilityItems = GetFunctionalOption("SetUpRulesForObtainingActualDataByAssetAndLiabilityItems");
	
	FirstPartOfKey = "";
	If TypeOf(Parameters.SettingObject1) = Type("CatalogRef.BusinessTransactionsSettings") Then
		Items.SettingObject1.Title = NStr("vi = 'Giao dịch';
											|ru = 'Хоз.операция';
											|en = 'Business transaction'; fa = 'عملیات تجاری';
											|it = 'Operazione commerciale';
											|pl = 'Business transaction';
											|tr = 'Ticari işlem'");
		Items.CalculationIndicators.Visible = False;
		Items.TargetValues.Visible = False;
		FirstPartOfKey = "1";
	ElsIf TypeOf(Parameters.SettingObject1) = Type("ChartOfCharacteristicTypesRef.AssetLiabilityItems") Then
		Items.SettingObject1.Title = NStr("vi = 'Dạng tài sản/nguồn vốn';
											|ru = 'Статья активов/пассивов';
											|en = 'Asset/liability item'; fa = 'قلم دارایی/بدهی';
											|it = 'Voce attività/passività';
											|pl = 'Pozycja aktywów/pasywów';
											|tr = 'Varlık/yükümlülük kalemi'");
		If SettingUpRulesForAssetLiabilityItems Then
			VisibilityOfBudgetItems = DataSourcesServer.ThisIsItemOfAssetsLiabilities(Parameters.SettingObject1);
		Else
			VisibilityOfBudgetItems = Catalogs.ActualDataQueryRulesByBudgetFlowItems.ThereAreDisabledRulesForGettingFact(, Parameters.SettingObject1);
		EndIf;
		Items.BudgetFlowItems.Visible = VisibilityOfBudgetItems;
		FirstPartOfKey = "2";
	ElsIf TypeOf(Parameters.SettingObject1) = LocalAccntingClientServer.TypeChartOfAccounts() Then
		Items.SettingObject1.Title = NStr("vi = 'Tài khoản VN';
											|ru = 'Счет РСБУ';
											|en = 'Russian Accounting Standards account'; fa = 'Russian Accounting Standards account';
											|it = 'Conto RSBU (Standard russi di contabilità generale)';
											|pl = 'Konto RSK';
											|tr = 'RMSH hesabı'");
		FirstPartOfKey = "3";
	ElsIf TypeOf(Parameters.SettingObject1) = FinancialAccountingClientServer.TypeChartOfAccounts() Then
		Items.SettingObject1.Title = NStr("vi = 'Tài khoản IA';
											|ru = 'Счет МФУ';
											|en = 'Financial account'; fa = 'Financial account';
											|it = 'Conto dispositivo multifunzione';
											|pl = 'Konto MFU';
											|tr = 'UFM hesabı'");
		FirstPartOfKey = "4";
	ElsIf TypeOf(Parameters.SettingObject1) = Type("CatalogRef.BudgetFlowItems") Then
		Items.SettingObject1.Title = NStr("vi = 'Khoản mục ngân sách';
											|ru = 'Статья бюджетов';
											|en = 'Budget flow item'; fa = 'قلم جریان بودجه';
											|it = 'Voce di bilanci';
											|pl = 'Pozycja budżetowa';
											|tr = 'Bütçe kalemi'");
		Items.CalculationIndicators.Visible = False;
		Items.TargetValues.Visible = False;
		FirstPartOfKey = "5";
	ElsIf TypeOf(Parameters.SettingObject1) = Type("CatalogRef.BudgetBalanceItems") Then
		Items.SettingObject1.Title = NStr("vi = 'Chỉ tiêu ngân sách';
											|ru = 'Показатель бюджетов';
											|en = 'Budget balance item'; fa = 'قلم مانده بودجه';
											|it = 'Indice dei bilanci';
											|pl = 'Wskaźnik budżetowy';
											|tr = 'Bütçe kalemi'");
		Items.BudgetFlowItems.Visible = False;
		If Common.ObjectAttributeValue(SettingObject1, "IndicatorType") = Enums.BudgetBalanceItemType.Estimated_ Then
			Items.TargetValues.Visible = False;
			FirstPartOfKey = "6";
		Else
			Items.CalculationIndicators.Visible = False;
			FirstPartOfKey = "7";
		EndIf;
	EndIf;
	
	Count = 0;
	For Each Item In Items.FormPages.ChildItems Do
		If Item.Visible Then
			Count = Count + 1;
		EndIf;
	EndDo;
	
	If Count = 1 Then
		Items.FormPages.PagesRepresentation = FormPagesRepresentation.None;
	EndIf;
	
	If Items.BudgetFlowItems.Visible Then
		If TypeOf(Parameters.SettingObject1) = Type("CatalogRef.BudgetFlowItems") Then
			CommonClientServer.SetDynamicListFilterItem(ActualDataQueryRulesByBudgetFlowItems,
						"BudgetFlowItem",
						Parameters.SettingObject1,
						DataCompositionComparisonType.Equal,
						True);
			ThereAreDisabledRulesForGettingFactsByArticles = 
				Catalogs.ActualDataQueryRulesByBudgetFlowItems.ThereAreDisabledRulesForGettingFact(Parameters.SettingObject1);
		Else
			CommonClientServer.SetDynamicListFilterItem(ActualDataQueryRulesByBudgetFlowItems,
						"DataSource",
						Parameters.SettingObject1,
						DataCompositionComparisonType.Equal,
						True);
			ThereAreDisabledRulesForGettingFactsByArticles = 
				Catalogs.ActualDataQueryRulesByBudgetFlowItems.ThereAreDisabledRulesForGettingFact(, Parameters.SettingObject1);
		EndIf;
		
		Items.HideRulesForDisabledSettingsSpeedRule.Visible = ThereAreDisabledRulesForGettingFactsByArticles;
		
		If TypeOf(Parameters.SettingObject1) = Type("ChartOfCharacteristicTypesRef.AssetLiabilityItems") Then
			If SettingUpRulesForAssetLiabilityItems Then
				CreatingNewRulesIsAvailable = DataSourcesServer.ThisIsItemOfAssetsLiabilities(Parameters.SettingObject1);
			Else
				CreatingNewRulesIsAvailable = False;
			EndIf;
			Items.ActualDataQueryRulesByBudgetFlowItems.ChangeRowSet = CreatingNewRulesIsAvailable;
			Items.RuleTypeBudgetItem.Visible = False;
		EndIf;
	EndIf;
	
	If Items.CalculationIndicators.Visible Or Items.TargetValues.Visible Then
		If TypeOf(Parameters.SettingObject1) = Type("CatalogRef.BudgetBalanceItems") Then
			CommonClientServer.SetDynamicListFilterItem(ActualDataQueryRulesByBudgetBalanceItems,
						"BudgetBalanceItem",
						Parameters.SettingObject1,
						DataCompositionComparisonType.Equal,
						True);
			ThereAreDisabledRulesForGettingFactsBasedOnIndicators =
				Catalogs.ActualDataQueryRulesByBudgetBalanceItems.ThereAreDisabledRulesForGettingFact(Parameters.SettingObject1);
		Else
			CommonClientServer.SetDynamicListFilterItem(ActualDataQueryRulesByBudgetBalanceItems,
						"DataSource",
						Parameters.SettingObject1,
						DataCompositionComparisonType.Equal,
						True);
			ThereAreDisabledRulesForGettingFactsBasedOnIndicators =
				Catalogs.ActualDataQueryRulesByBudgetBalanceItems.ThereAreDisabledRulesForGettingFact(, Parameters.SettingObject1);
		EndIf;
		
		Items.RulesForGettingAFactBasedOnCalculatedIndicatorsHideRulesForDisabledSettings.Visible = ThereAreDisabledRulesForGettingFactsBasedOnIndicators;
		Items.HideRulesForDisabledSettingsTargets.Visible = ThereAreDisabledRulesForGettingFactsBasedOnIndicators;
		
		If TypeOf(Parameters.SettingObject1) = Type("ChartOfCharacteristicTypesRef.AssetLiabilityItems") Then
			If SettingUpRulesForAssetLiabilityItems Then
				CreatingNewRulesIsAvailable = DataSourcesServer.ThisIsItemOfAssetsLiabilities(Parameters.SettingObject1);
			Else
				CreatingNewRulesIsAvailable = DataSourcesServer.ThisIsItemOfManagementBalanceSheet(Parameters.SettingObject1);
			EndIf;
			Items.RulesForGettingAFactBasedOnCalculatedIndicators.ChangeRowSet = CreatingNewRulesIsAvailable;
			Items.RulesForGettingAFactByTargetIndicators.ChangeRowSet = CreatingNewRulesIsAvailable;
		EndIf;
	EndIf;
	
	If Items.BudgetFlowItems.Visible Then
		Items.FormPages.CurrentPage = Items.BudgetFlowItems;
	ElsIf Items.CalculationIndicators.Visible Then
		Items.FormPages.CurrentPage = Items.CalculationIndicators;
	ElsIf Items.TargetValues.Visible Then
		Items.FormPages.CurrentPage = Items.TargetValues;
	EndIf;
	
	If TypeOf(Parameters.SettingObject1) = Type("CatalogRef.BudgetFlowItems") Then
		DisabledConfigurationRulesAreHidden = Common.FormDataSettingsStorageLoad(
			"Catalog.ActualDataQueryRulesByBudgetFlowItems.ListForm",
			"DisabledConfigurationRulesAreHidden",
			False);
		Items.ActualDataQueryRulesByBudgetFlowItemsBudgetFlowItem.Visible = False;
	ElsIf TypeOf(Parameters.SettingObject1) = Type("CatalogRef.BudgetBalanceItems") Then
		DisabledConfigurationRulesAreHidden = Common.FormDataSettingsStorageLoad(
			"Catalog.ActualDataQueryRulesByBudgetBalanceItems.ListForm",
			"DisabledConfigurationRulesAreHidden",
			False);
		Items.RulesForGettingAFactBasedOnCalculatedIndicatorsBudgetBalanceItem.Visible = False;
		Items.RulesForGettingAFactByTargetIndicatorsBudgetBalanceItem.Visible = False;
	Else
		Items.ActualDataQueryRulesByBudgetFlowItemsDataSource.Visible = False;
		Items.RulesForGettingAFactByTargetIndicatorsDataSource.Visible = False;
		Items.ActualDataQueryRulesByBudgetBalanceItemsDataSource.Visible = False;
	EndIf;
	
	FormControl(ThisObject);
	
	CommonClientServer.SetDynamicListParameter(
		ActualDataQueryRulesByBudgetFlowItems,
		"DisabledConfigurationRulesAreHidden",
		DisabledConfigurationRulesAreHidden);
	
	CommonClientServer.SetDynamicListParameter(
		ActualDataQueryRulesByBudgetBalanceItems,
		"DisabledConfigurationRulesAreHidden",
		DisabledConfigurationRulesAreHidden);
	
	If Items.FormPages.ChildItems.Count() > 1 Then
		SetBookmarkTitles();
	EndIf;
	
	WindowOptionsKey = "SetUpRulesOfReceivingActualBudgetingData.RulesSetting_" + FirstPartOfKey + "_" + Count;
	
EndProcedure

&AtClientAtServerNoContext
Procedure FormControl(Form)
	
	ListOfRuleTypes_ = New ValueList;
	ListOfRuleTypes_.Add(PredefinedValue("Enum.ActualBudgetingDataQueryRuleType.BudgetFulfillmentAndActualData"));
	
	If Form.Items.FormPages.CurrentPage = Form.Items.BudgetFlowItems Then
		If Not ValueIsFilled(Form.RuleTypeBudgetItem) Then
			CommonClientServer.DeleteDynamicListFilterGroupItems(
				Form.ActualDataQueryRulesByBudgetFlowItems,
				"RuleType");
		Else
			ListOfRuleTypes_.Add(Form.RuleTypeBudgetItem);
			CommonClientServer.SetDynamicListFilterItem(
				Form.ActualDataQueryRulesByBudgetFlowItems,
				"RuleType",
				ListOfRuleTypes_,
				DataCompositionComparisonType.InList,,
				True);
		EndIf;
	ElsIf Form.Items.FormPages.CurrentPage = Form.Items.TargetValues Then
		If Not ValueIsFilled(Form.RuleTypeBudgetIndicator) Then
			CommonClientServer.DeleteDynamicListFilterGroupItems(
				Form.ActualDataQueryRulesByBudgetBalanceItems,
				"RuleType");
		Else
			ListOfRuleTypes_.Add(Form.RuleTypeBudgetIndicator);
			CommonClientServer.SetDynamicListFilterItem(
				Form.ActualDataQueryRulesByBudgetBalanceItems,
				"RuleType",
				ListOfRuleTypes_,
				DataCompositionComparisonType.InList,,
				True);
			CommonClientServer.SetDynamicListFilterItem(
				Form.ActualDataQueryRulesByBudgetBalanceItems,
				"ThisIsACalculated",
				False,
				DataCompositionComparisonType.Equal,,
				True);
		EndIf;
	ElsIf Form.Items.FormPages.CurrentPage = Form.Items.CalculationIndicators Then
		CommonClientServer.SetDynamicListFilterItem(
			Form.ActualDataQueryRulesByBudgetBalanceItems,
			"RuleType",,
			DataCompositionComparisonType.Equal,,
			False);
		CommonClientServer.SetDynamicListFilterItem(
			Form.ActualDataQueryRulesByBudgetBalanceItems,
			"ThisIsACalculated",
			True,
			DataCompositionComparisonType.Equal,,
			True);
	EndIf;
	
	If Form.DisabledConfigurationRulesAreHidden Then
		TitleOfHideRulesCommand = NStr("vi = 'Hiển thị quy tắc bị tắt';
										|ru = 'Показать отключенные правила';
										|en = 'Show disabled rules'; fa = 'Show disabled rules';
										|it = 'Show disabled rules';
										|pl = 'Show disabled rules';
										|tr = 'Devre dışı bırakılan kuralları göster'");
	Else
		TitleOfHideRulesCommand = NStr("vi = 'Ẩn quy tắc bị tắt';
										|ru = 'Скрыть отключенные правила';
										|en = 'Hide disabled rules'; fa = 'پنهان کردن قواعد غیرفعال';
										|it = 'Hide disabled rules';
										|pl = 'Hide disabled rules';
										|tr = 'Devre dışı bırakılan kuralları gizle'");
	EndIf;
	
	If Form.Items.BudgetFlowItems.Visible Then
		Form.Items.HideRulesForDisabledSettingsSpeedRule.Title = TitleOfHideRulesCommand;
	EndIf;
	
	If Form.Items.CalculationIndicators.Visible Then
		Form.Items.RulesForGettingAFactBasedOnCalculatedIndicatorsHideRulesForDisabledSettings.Title = TitleOfHideRulesCommand;
	EndIf;
	
	If Form.Items.TargetValues.Visible Then
		Form.Items.HideRulesForDisabledSettingsTargets.Title = TitleOfHideRulesCommand;
	EndIf;
	
EndProcedure

&AtClient
Procedure FormPagesOnCurrentPageChange(Item, CurrentPage)
	
	FormControl(ThisObject);
	
EndProcedure

&AtClient
Procedure NewWriteProcessing(NewObject, Source, StandardProcessing)
	
	If Items.FormPages.ChildItems.Count() > 1 Then
		SetBookmarkTitles();
	EndIf;
	
EndProcedure

&AtServer
Procedure SetBookmarkTitles()
	
	Query = New QueryBuilder;
	Query.Text = 
		"SELECT
		|	NULL AS ArticleFactualData,
		|	NULL AS ArticleBudgetExecution,
		|	CASE
		|		WHEN ActualDataQueryRulesByBudgetBalanceItems.RuleType = &ActualData
		|			THEN ActualDataQueryRulesByBudgetBalanceItems.Ref
		|		ELSE NULL
		|	END AS EstimatedActualData,
		|	NULL AS TargetActualData,
		|	NULL AS TargetBudgetExecution,
		|	ActualDataQueryRulesByBudgetBalanceItems.DataSource,
		|	NULL AS BudgetFlowItem,
		|	ActualDataQueryRulesByBudgetBalanceItems.BudgetBalanceItem
		|INTO RulesTable
		|FROM
		|	Catalog.ActualDataQueryRulesByBudgetBalanceItems AS ActualDataQueryRulesByBudgetBalanceItems
		|	LEFT JOIN ChartOfCharacteristicTypes.AssetLiabilityItems AS AssetLiabilityItems
		|	ON ActualDataQueryRulesByBudgetBalanceItems.DataSourceSection = &OperationalAccounting
		|	 AND ActualDataQueryRulesByBudgetBalanceItems.DataSource = AssetLiabilityItems.Ref
		|WHERE
		|	ActualDataQueryRulesByBudgetBalanceItems.BudgetBalanceItem.IndicatorType = &Estimated_
		|	AND CASE
		|		WHEN AssetLiabilityItems.Ref IS NULL
		|			THEN TRUE
		|		WHEN NOT AssetLiabilityItems.Predefined
		|			THEN TRUE
		|		WHEN &SetUpRulesForObtainingActualDataByAssetAndLiabilityItems
		|			THEN AssetLiabilityItems.DataSource <> """"
		|		ELSE AssetLiabilityItems.NameOfBudgetDataSource <> """"
		|	END
		|{WHERE
		|	ActualDataQueryRulesByBudgetBalanceItems.BudgetBalanceItem,
		|	ActualDataQueryRulesByBudgetBalanceItems.DataSource}
		|
		|UNION ALL
		|
		|SELECT
		|	NULL,
		|	NULL,
		|	NULL,
		|	CASE
		|		WHEN ActualDataQueryRulesByBudgetBalanceItems.RuleType = &ActualData
		|			THEN ActualDataQueryRulesByBudgetBalanceItems.Ref
		|		ELSE NULL
		|	END,
		|	CASE
		|		WHEN ActualDataQueryRulesByBudgetBalanceItems.RuleType <> &ActualData
		|			THEN ActualDataQueryRulesByBudgetBalanceItems.Ref
		|		ELSE NULL
		|	END,
		|	ActualDataQueryRulesByBudgetBalanceItems.DataSource,
		|	NULL,
		|	ActualDataQueryRulesByBudgetBalanceItems.BudgetBalanceItem
		|FROM
		|	Catalog.ActualDataQueryRulesByBudgetBalanceItems AS ActualDataQueryRulesByBudgetBalanceItems
		|	LEFT JOIN ChartOfCharacteristicTypes.AssetLiabilityItems AS AssetLiabilityItems
		|	ON ActualDataQueryRulesByBudgetBalanceItems.DataSourceSection = &OperationalAccounting
		|	 AND ActualDataQueryRulesByBudgetBalanceItems.DataSource = AssetLiabilityItems.Ref
		|WHERE
		|	NOT ActualDataQueryRulesByBudgetBalanceItems.BudgetBalanceItem.IndicatorType = &Estimated_
		|	AND CASE
		|		WHEN AssetLiabilityItems.Ref IS NULL
		|			THEN TRUE
		|		WHEN NOT AssetLiabilityItems.Predefined
		|			THEN TRUE
		|		WHEN &SetUpRulesForObtainingActualDataByAssetAndLiabilityItems
		|			THEN AssetLiabilityItems.DataSource <> """"
		|		ELSE AssetLiabilityItems.NameOfBudgetDataSource <> """"
		|	END
		|{WHERE
		|	ActualDataQueryRulesByBudgetBalanceItems.BudgetBalanceItem,
		|	ActualDataQueryRulesByBudgetBalanceItems.DataSource}
		|
		|UNION ALL
		|
		|SELECT
		|	CASE
		|		WHEN ActualDataQueryRulesByBudgetFlowItems.RuleType = &ActualData
		|			THEN ActualDataQueryRulesByBudgetFlowItems.Ref
		|		ELSE NULL
		|	END,
		|	CASE
		|		WHEN ActualDataQueryRulesByBudgetFlowItems.RuleType <> &ActualData
		|			THEN ActualDataQueryRulesByBudgetFlowItems.Ref
		|		ELSE NULL
		|	END,
		|	NULL,
		|	NULL,
		|	NULL,
		|	ActualDataQueryRulesByBudgetFlowItems.DataSource,
		|	ActualDataQueryRulesByBudgetFlowItems.BudgetFlowItem,
		|	NULL
		|FROM
		|	Catalog.ActualDataQueryRulesByBudgetFlowItems AS ActualDataQueryRulesByBudgetFlowItems
		|WHERE
		|	CASE
		|		WHEN ActualDataQueryRulesByBudgetFlowItems.DataSourceSection <> &OperationalAccounting
		|			THEN TRUE
		|		WHEN ActualDataQueryRulesByBudgetFlowItems.RuleType <> &ActualData
		|			THEN TRUE
		|		WHEN &SetUpRulesForObtainingActualDataByAssetAndLiabilityItems
		|			THEN VALUETYPE(ActualDataQueryRulesByBudgetFlowItems.DataSource) = TYPE(ChartOfCharacteristicTypes.AssetLiabilityItems)
		|		ELSE VALUETYPE(ActualDataQueryRulesByBudgetFlowItems.DataSource) = TYPE(Catalog.BusinessTransactionsSettings)
		|	END
		|{WHERE
		|	ActualDataQueryRulesByBudgetFlowItems.BudgetFlowItem,
		|	ActualDataQueryRulesByBudgetFlowItems.DataSource}
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	COUNT(DISTINCT RulesTable.ArticleFactualData) AS ArticleFactualData,
		|	COUNT(DISTINCT RulesTable.ArticleBudgetExecution) AS ArticleBudgetExecution,
		|	COUNT(DISTINCT RulesTable.EstimatedActualData) AS EstimatedActualData,
		|	COUNT(DISTINCT RulesTable.TargetActualData) AS TargetActualData,
		|	COUNT(DISTINCT RulesTable.TargetBudgetExecution) AS TargetBudgetExecution
		|FROM
		|	RulesTable AS RulesTable
		|{WHERE
		|	RulesTable.DataSource,
		|	RulesTable.BudgetFlowItem,
		|	RulesTable.BudgetBalanceItem}";
	
	Query.Parameters.Insert("SetUpRulesForObtainingActualDataByAssetAndLiabilityItems", SettingUpRulesForAssetLiabilityItems);
	Query.Parameters.Insert("ActualData", Enums.ActualBudgetingDataQueryRuleType.ActualData);
	Query.Parameters.Insert("OperationalAccounting", Enums.SectionsOfBudgetingDataSources.OperationalAccounting);
	Query.Parameters.Insert("Estimated_", Enums.BudgetBalanceItemType.Estimated_);
	If TypeOf(SettingObject1) = Type("CatalogRef.BudgetFlowItems") Then
		Filter = Query.Filter.Add("BudgetFlowItem");
	ElsIf TypeOf(SettingObject1) = Type("CatalogRef.BudgetBalanceItems") Then
		Filter = Query.Filter.Add("BudgetBalanceItem");
	Else
		Filter = Query.Filter.Add("DataSource");
	EndIf;
		
	Filter.ComparisonType = ComparisonType.Equal;
	Filter.Value = SettingObject1;
	Filter.Use = True;
	
	Query.Execute();
	
	Selection = Query.Result.Select();
	Selection.Next();
	
	If TypeOf(SettingObject1) = Type("ChartOfCharacteristicTypesRef.AssetLiabilityItems") Then
		BookmarkTitle = NStr("vi = 'Khoản mục ngân sách (%1)';
							|ru = 'Статьи бюджетов (%1)';
							|en = 'Budget flow items (%1)'; fa = 'Budget flow items (%1)';
							|it = 'Budget flow items (%1)';
							|pl = 'Budget flow items (%1)';
							|tr = 'Bütçe kalemleri  (%1)'");
		NumerationItemOptions = NStr("vi = 'quy tắc';
									|ru = 'правило,правила,правил';
									|en = 'rule,rules,rules'; fa = 'rule,rules,rules';
									|it = 'regola, regole';
									|pl = 'reguła,reguły,reguł';
									|tr = 'kural,kural,kural'");
		ArticleFactualData = StringFunctionsClientServer.NumberInDigitsUnitOfMeasurementInWords(Selection.ArticleFactualData, NumerationItemOptions);
		ArticleBudgetExecution = StringFunctionsClientServer.NumberInDigitsUnitOfMeasurementInWords(Selection.ArticleBudgetExecution, NumerationItemOptions);
	Else
		BookmarkTitle = NStr("vi = 'Khoản mục ngân sách(%1 thực tế.,%2 th.)';
							|ru = 'Статьи бюджетов (%1 факт., %2 исп.)';
							|en = 'Budget flow items (%1 act., %2 impl.)'; fa = 'Budget flow items (%1 act., %2 impl.)';
							|it = 'Voci di bilanci (%1 eff., %2eseg.)';
							|pl = 'Pozycje budżetowe (%1 fakt., %2 wyk.)';
							|tr = 'Bütçe kalemleri (%1 gerçek, %2 kul.)'");
		ArticleFactualData = Selection.ArticleFactualData;
		ArticleBudgetExecution = Selection.ArticleBudgetExecution;
	EndIf;
	Items.BudgetFlowItems.Title = StringFunctionsClientServer.SubstituteParametersToString(
			BookmarkTitle, ArticleFactualData, ArticleBudgetExecution);
	
	BookmarkTitle = NStr("vi = 'Hiệu suất ước tính (%1)';
						|ru = 'Расчетные показатели (%1)';
						|en = 'Estimates (%1)'; fa = 'Estimates (%1)';
						|it = 'Indicatori di calcolo (%1)';
						|pl = 'Szacunki (%1)';
						|tr = 'Tahmini hesaplamalar (%1)'");
	NumerationItemOptions = NStr("vi = 'quy tắc';
								|ru = 'правило,правила,правил';
								|en = 'rule,rules,rules'; fa = 'rule,rules,rules';
								|it = 'regola, regole';
								|pl = 'reguła,reguły,reguł';
								|tr = 'kural,kural,kural'");
	NumberOfRules = StringFunctionsClientServer.NumberInDigitsUnitOfMeasurementInWords(Selection.EstimatedActualData, NumerationItemOptions);
	Items.CalculationIndicators.Title = StringFunctionsClientServer.SubstituteParametersToString(BookmarkTitle, NumberOfRules);
	
	BookmarkTitle = NStr("vi = 'Các chỉ số mục tiêu (%1 thực tế.,%2 isp.)';
						|ru = 'Целевые показатели (%1 факт., %2 исп.)';
						|en = 'Target values (%1 actual, %2 impl.)'; fa = 'Target values (%1 actual, %2 impl.)';
						|it = 'Indicatori finalizzati (%1eff.,%2 eseg.)';
						|pl = 'Wskaźniki celowe (%1 fakt., %2 wyk.)';
						|tr = 'Hedef değerler (%1 gerçek., %2 kul.)'");
	Items.TargetValues.Title = StringFunctionsClientServer.SubstituteParametersToString(
			BookmarkTitle, Selection.TargetActualData, Selection.TargetBudgetExecution);
	
EndProcedure


// LongDesc
// 
// Parameters:
// 	TableName - String - Name of the form table.
// Returns:
// 	FormDataCollectionItem -:
// 	 *Ref - CatalogRef.ActualDataQueryRulesByBudgetBalanceItems - 
// 	 		- CatalogRef.ActualDataQueryRulesByBudgetFlowItems - 
&AtClient
Function CurFormTableData(TableName)
	TableFormElement = Items[TableName]; // FormTable -
	Return TableFormElement.CurrentData;
EndFunction

&AtClient
Procedure OpenNewRuleForm(TableName, Cancel, Copy, Estimated_ = Undefined)
	
	Cancel = True;
	FormParameters = New Structure;
	
	If Copy Then
		LineCurData = CurFormTableData(TableName);
		FormParameters.Insert("CopyingValue", LineCurData.Ref);
	Else 
		If TypeOf(SettingObject1) = Type("CatalogRef.BudgetFlowItems") Then
			
			FillingValues = New Structure("BudgetFlowItem", SettingObject1);
			
		ElsIf TypeOf(SettingObject1) = Type("CatalogRef.BudgetBalanceItems") Then
			
			FillingValues = New Structure("BudgetBalanceItem", SettingObject1);
			
		ElsIf TypeOf(SettingObject1) = Type("CatalogRef.BusinessTransactionsSettings") Then
			
			FillingValues = New Structure("DataSourceSection, DataSource", 
				PredefinedValue("Enum.SectionsOfBudgetingDataSources.OperationalAccounting"), SettingObject1);
			
		ElsIf TypeOf(SettingObject1) = Type("ChartOfCharacteristicTypesRef.AssetLiabilityItems") Then
			
			FillingValues = New Structure("DataSourceSection, DataSource", 
				PredefinedValue("Enum.SectionsOfBudgetingDataSources.OperationalAccounting"), SettingObject1);
			
		ElsIf TypeOf(SettingObject1) = LocalAccntingClientServer.TypeChartOfAccounts() Then
			
			FillingValues = New Structure("DataSourceSection, DataSource", 
				PredefinedValue("Enum.SectionsOfBudgetingDataSources.LocalAccounting"), SettingObject1);
		ElsIf TypeOf(SettingObject1) = FinancialAccountingClientServer.TypeChartOfAccounts() Then
			FillingValues = New Structure("DataSourceSection, DataSource", 
				PredefinedValue("Enum.SectionsOfBudgetingDataSources.FinancialAccounting"), SettingObject1);
		EndIf;
		
		If TableName = "ActualDataQueryRulesByBudgetFlowItems" Then
			FillingValues.Insert("RuleType", RuleTypeBudgetItem);
		Else
			FillingValues.Insert("RuleType", RuleTypeBudgetIndicator);
		EndIf;
		
		FormParameters.Insert("FillingValues", FillingValues);
		
		If Estimated_ <> Undefined Then
			If Estimated_ Then
				FormParameters.Insert("IndicatorType", PredefinedValue("Enum.BudgetBalanceItemType.Estimated_"));
			Else
				FormParameters.Insert("IndicatorType", PredefinedValue("Enum.BudgetBalanceItemType.SpecialPurpose"));
			EndIf;
		EndIf;
	EndIf;
	
	NewFormName = ?(TableName = "ActualDataQueryRulesByBudgetFlowItems", TableName,
		"ActualDataQueryRulesByBudgetBalanceItems");
	OpenForm("Catalog." + NewFormName + ".Form.ObjectForm", FormParameters,,,,,,
																	FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure ActualDataQueryRulesByBudgetFlowItemsBeforeAddRow(Item, Cancel, Copy, Parent, Var_Group, Parameter)
	
	OpenNewRuleForm("ActualDataQueryRulesByBudgetFlowItems", Cancel, Copy);
	
EndProcedure

&AtClient
Procedure RulesForGettingAFactBasedOnCalculatedIndicatorsBeforeAddRow(Item, Cancel, Copy, Parent, Var_Group, Parameter)
	
	OpenNewRuleForm("RulesForGettingAFactBasedOnCalculatedIndicators", Cancel, Copy, True);
	
EndProcedure

&AtClient
Procedure RulesForGettingAFactByTargetIndicatorsBeforeAddRow(Item, Cancel, Copy, Parent, Var_Group, Parameter)
	
	OpenNewRuleForm("RulesForGettingAFactByTargetIndicators", Cancel, Copy, False);
	
EndProcedure

&AtClient
Procedure RuleTypeBudgetItemOnChange(Item)
	
	FormControl(ThisObject);
	
EndProcedure

&AtClient
Procedure RuleTypeBudgetIndicatorOnChange(Item)
	
	FormControl(ThisObject);
	
EndProcedure

&AtServerNoContext
Procedure ActualDataQueryRulesByBudgetFlowItemsOnGetDataAtServer(TagName, Settings, Rows)
	DisplaySelectionInUserSLanguage(Rows, "ActualDataQueryRulesByBudgetFlowItems");
EndProcedure

&AtServerNoContext
Procedure RulesForGettingAFactBasedOnCalculatedIndicatorsOnGetDataAtServer(TagName, Settings, Rows)
	DisplaySelectionInUserSLanguage(Rows, "ActualDataQueryRulesByBudgetBalanceItems");
EndProcedure

&AtServerNoContext
Procedure RulesForGettingAFactByTargetIndicatorsOnGetDataAtServer(TagName, Settings, Rows)
	DisplaySelectionInUserSLanguage(Rows, "ActualDataQueryRulesByBudgetBalanceItems")
EndProcedure

&AtServerNoContext
Procedure DisplaySelectionInUserSLanguage(Rows, DataSource)
	
	Query = New Query;
	Query.Text = 
		"SELECT
		|	Rules.Ref AS Ref,
		|	Rules.SettingsComposer AS SettingsComposer
		|FROM
		|	&RulesSource AS Rules
		|WHERE
		|	Rules.Ref IN(&Rules)";
	
	Query.SetParameter("Rules", Rows.GetKeys());
	Query.Text = StrReplace(Query.Text, "&RulesSource", "Catalog." + DataSource);
	QueryResult = Query.Execute();
	
	SelectionDetailRecords = QueryResult.Select();
	CustomizingByRule = New Map();
	While SelectionDetailRecords.Next() Do
		SettingsStorage = SelectionDetailRecords.SettingsComposer;// ValueStorage
		CustomizingByRule.Insert(SelectionDetailRecords.Ref, SettingsStorage.Get());
	EndDo;
	
	MessageTemplate = NStr("vi = 'Lỗi khi đọc tùy chỉnh theo quy tắc %1';
							|ru = 'Ошибка при чтении настроек по правилу %1';
							|en = 'An error occurred when reading settings by the rule %1'; fa = 'An error occurred when reading settings by the rule %1';
							|it = 'Errore durante la letture delle impostazioni della regola %1';
							|pl = 'Błąd podczas wczytywania ustawień według reguły %1';
							|tr = 'Ayarların %1 kuralına göre okunmasında hata meydana geldi'");
	
	ReceiptOfFactByCorrespondenceOfRegisters = DataSource = "ActualDataQueryRulesByBudgetFlowItems"
		And GetFunctionalOption("SettingUpRulesForObtainingFactsFromCorrespondingRegisters");
	
	For Each String In Rows Do
		If String.Value.Data.DataSourceSection <> Enums.SectionsOfBudgetingDataSources.OperationalAccounting Then
			CorrespondencesTable = Undefined;
		ElsIf ReceiptOfFactByCorrespondenceOfRegisters
			And DataSourcesServer.ThisIsSettingUpBusinessOfOperation(String.Value.Data.DataSource) Then
			CorrespondencesTable = DataSourcesServer.TableOfCorrespondenceRegisters(String.Value.Data.DataSource);
		Else
			CorrespondencesTable = Undefined;
		EndIf;
		DCSByRule = DataSourcesServer.DataLayoutRules(String.Key, , , , CorrespondencesTable);
		If DCSByRule <> Undefined Then
			Try
				SettingsComposer = New DataCompositionSettingsComposer;
				SettingsComposer.Initialize(New DataCompositionAvailableSettingsSource(DCSByRule));

				AdditionalSelection = CustomizingByRule.Get(String.Key);
				If AdditionalSelection <> Undefined Then
					SettingsComposer.LoadSettings(AdditionalSelection);
					String.Value.Data.FilterPresentation = String(SettingsComposer.Settings.Filter);
				EndIf;
			Except
				MessageText = StringFunctionsClientServer.SubstituteParametersToString(MessageTemplate, TrimAll(
					String.Key));
				Common.MessageToUser(MessageText, String.Key);
			EndTry;
		EndIf;
	EndDo;

EndProcedure

#Region FormCommandsEventHandlers

&AtClient
Procedure RuleOperationResult(Command)
	Var ReportHeader;
	
	FormParameters = New Structure;
	FormParameters.Insert("GenerateOnOpen", True);
	FormParameters.Insert("ReportOptionsCommandsVisibility", False);
	
	If Items.FormPages.CurrentPage = Items.BudgetFlowItems Then
		ReportHeader = "BudgetFlowItem = " + SettingObject1;
		FormParameters.Insert("VariantKey", "RuleOperationResultByBudgetItem");
		FormParameters.Insert("Filter", New Structure("BudgetFlowItem", SettingObject1));
	Else
		ReportHeader = "BudgetBalanceItem = " + SettingObject1;
		FormParameters.Insert("VariantKey", "RuleOperationResultByBudgetIndicator");
		FormParameters.Insert("Filter", New Structure("BudgetBalanceItem", SettingObject1));
	EndIf;
	
	OpenForm("Report.ResultOfActualDataQuery.Form", FormParameters, , ReportHeader);
		
EndProcedure

&AtClient
Procedure HideRulesForDisabledSettings(Command)
	
	HideDisabledConfigurationRulesAtServer();
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure HideDisabledConfigurationRulesAtServer()
	
	DisabledConfigurationRulesAreHidden = Not DisabledConfigurationRulesAreHidden;
	
	If TypeOf(SettingObject1) = Type("CatalogRef.BudgetFlowItems") Then
		Common.FormDataSettingsStorageSave(
			"Catalog.ActualDataQueryRulesByBudgetFlowItems.ListForm",
			"DisabledConfigurationRulesAreHidden",
			DisabledConfigurationRulesAreHidden);
	ElsIf TypeOf(SettingObject1) = Type("CatalogRef.BudgetBalanceItems") Then
		Common.FormDataSettingsStorageSave(
			"Catalog.ActualDataQueryRulesByBudgetBalanceItems.ListForm",
			"DisabledConfigurationRulesAreHidden",
			DisabledConfigurationRulesAreHidden);
	EndIf;
	
	FormControl(ThisObject);
	
	CommonClientServer.SetDynamicListParameter(
		ActualDataQueryRulesByBudgetFlowItems,
		"DisabledConfigurationRulesAreHidden",
		DisabledConfigurationRulesAreHidden);
	
	CommonClientServer.SetDynamicListParameter(
		ActualDataQueryRulesByBudgetBalanceItems,
		"DisabledConfigurationRulesAreHidden",
		DisabledConfigurationRulesAreHidden);
	
EndProcedure

&AtServer
Procedure SetConditionalAppearance() 
	
	ConditionalAppearance.Items.Clear();
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ActualDataQueryRulesByBudgetFlowItems.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ActualDataQueryRulesByBudgetFlowItems.DataSourceSection");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.SectionsOfBudgetingDataSources.OperationalAccounting;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ActualDataQueryRulesByBudgetFlowItems.RuleType");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.ActualBudgetingDataQueryRuleType.ActualData;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ActualDataQueryRulesByBudgetFlowItems.ThisIsItemOfAssetsLiabilities");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("SettingUpRulesForAssetLiabilityItems");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	Item.Appearance.SetParameterValue("TextColor", StyleColors.GrayTextColor1);
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ActualDataQueryRulesByBudgetFlowItems.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ActualDataQueryRulesByBudgetFlowItems.DataSourceSection");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.SectionsOfBudgetingDataSources.OperationalAccounting;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ActualDataQueryRulesByBudgetFlowItems.RuleType");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.ActualBudgetingDataQueryRuleType.ActualData;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ActualDataQueryRulesByBudgetFlowItems.ThisIsSettingUpBusinessOfOperation");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("SettingUpRulesForAssetLiabilityItems");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;

	Item.Appearance.SetParameterValue("TextColor", StyleColors.GrayTextColor1);
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.RulesForGettingAFactBasedOnCalculatedIndicators.Name);
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.RulesForGettingAFactByTargetIndicators.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ActualDataQueryRulesByBudgetBalanceItems.DataSourceSection");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.SectionsOfBudgetingDataSources.OperationalAccounting;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ActualDataQueryRulesByBudgetBalanceItems.ThisIsItemOfAssetsLiabilities");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("SettingUpRulesForAssetLiabilityItems");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	Item.Appearance.SetParameterValue("TextColor", StyleColors.GrayTextColor1);
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.RulesForGettingAFactBasedOnCalculatedIndicators.Name);
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.RulesForGettingAFactByTargetIndicators.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ActualDataQueryRulesByBudgetBalanceItems.DataSourceSection");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.SectionsOfBudgetingDataSources.OperationalAccounting;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ActualDataQueryRulesByBudgetBalanceItems.ThisIsItemOfManagementBalanceSheet");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("SettingUpRulesForAssetLiabilityItems");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;

	Item.Appearance.SetParameterValue("TextColor", StyleColors.GrayTextColor1);
	
	//
	
EndProcedure

#EndRegion