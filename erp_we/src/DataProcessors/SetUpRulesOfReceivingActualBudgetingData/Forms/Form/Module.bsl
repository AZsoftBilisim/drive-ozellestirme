
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	SettingUpRulesForAssetLiabilityItems = GetFunctionalOption("SetUpRulesForObtainingActualDataByAssetAndLiabilityItems");
	
	UseInternationalAccounting = False;
	UseInternationalAccounting = GetFunctionalOption("UseFinancialAccounting");
	
	QueryText = 
	"SELECT
	|	ChartOfAccountsTable.Ref AS Ref,
	|	ChartOfAccountsTable.ChartOfAccounts AS ChartOfAccounts,
	|	ChartOfAccountsTable.Code AS Code,
	|	ChartOfAccountsTable.Description AS Description,
	|	MAX(CASE
	|			WHEN ActualDataQueryRulesByBudgetFlowItems.DataSource IS NULL
	|					AND ActualDataQueryRulesByBudgetBalanceItems.DataSource IS NULL
	|				THEN FALSE
	|			ELSE TRUE
	|		END) AS ThereAreFactReceiptRules
	|FROM
	|	&ChartOfAccountsSource AS ChartOfAccountsTable
	|		LEFT JOIN Catalog.ActualDataQueryRulesByBudgetFlowItems AS ActualDataQueryRulesByBudgetFlowItems
	|		ON (ActualDataQueryRulesByBudgetFlowItems.DataSourceSection = VALUE(Enum.SectionsOfBudgetingDataSources.FinancialAccounting))
	|			AND ChartOfAccountsTable.Ref = ActualDataQueryRulesByBudgetFlowItems.DataSource
	|		LEFT JOIN Catalog.ActualDataQueryRulesByBudgetBalanceItems AS ActualDataQueryRulesByBudgetBalanceItems
	|		ON (ActualDataQueryRulesByBudgetBalanceItems.DataSourceSection = VALUE(Enum.SectionsOfBudgetingDataSources.FinancialAccounting))
	|			AND ChartOfAccountsTable.Ref = ActualDataQueryRulesByBudgetBalanceItems.DataSource
	|
	|GROUP BY
	|	ChartOfAccountsTable.Ref,
	|	ChartOfAccountsTable.Code,
	|	ChartOfAccountsTable.Description,
	|	ChartOfAccountsTable.ChartOfAccounts";
	TableName   = "ChartOfAccounts." + FinancialAccountingClientServer.ChartOfAccountsName();
	QueryText = StrReplace(QueryText, "&ChartOfAccountsSource", TableName);
	
	ListProperties = Common.DynamicListPropertiesStructure();
	ListProperties.MainTable = TableName;
	ListProperties.DynamicDataRead = True;
	ListProperties.QueryText = QueryText;
	Common.SetDynamicListProperties(Items.FinancialAccountingChartOfAccounts,
		ListProperties);
	
	FilterFinancialAccountingChartOfAccounts = Catalogs.FinancialAccountingChartsOfAccounts.DefaultChartOfAccounts();
	CommonClientServer.SetDynamicListFilterItem(FinancialAccountingChartOfAccounts, "ChartOfAccounts", FilterFinancialAccountingChartOfAccounts);
	
	ManagingFormElementsDuringCreation();
	
	FormControl();
	
EndProcedure


&AtServer
Procedure OnLoadDataFromSettingsAtServer(Settings)
	
	CommonClientServer.SetDynamicListFilterItem(FinancialAccountingChartOfAccounts, "ChartOfAccounts", FilterFinancialAccountingChartOfAccounts);
	FormControl();
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	AttachIdleHandler("CheckingNeedForReflectionInAccounting", 60);
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If EventName = "RecordedRuleForObtainingFactUnderBudgetItem" Then
		FormControl();
	EndIf;
	
EndProcedure

#EndRegion

#Region FormElementHandlers

&AtClient
Procedure RuleSettingModeOnChange(Item)
	
	FormControl();
	
EndProcedure

&AtClient
Procedure ListSelection(Item, RowSelected, Field, StandardProcessing)
	
	StandardProcessing = False;
	
	SetupParameters = New Structure("SettingObject1", RowSelected);
	OpenForm("DataProcessor.SetUpRulesOfReceivingActualBudgetingData.Form.RulesSetting",
									SetupParameters,,,,,,FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure BudgetFlowItemsOnActivateRow(Item)
	SetCommandsAvailability(Items, "BudgetFlowItems", "BudgetFlowItemsConfigureRules");
EndProcedure

&AtClient
Procedure BudgetBalanceItemsOnActivateRow(Item)
	SetCommandsAvailability(Items, "BudgetBalanceItems", "BudgetBalanceItemsConfigureRules");
EndProcedure

&AtClient
Procedure BusinessTransactionsOnActivateRow(Item)
	SetCommandsAvailability(Items, "BusinessTransactions", "BusinessTransactionsConfigureRules");
EndProcedure

&AtClient
Procedure AssetLiabilityItemsOnActivateRow(Item)
	SetCommandsAvailability(Items, "AssetLiabilityItems", "AssetLiabilityItemsConfigureRules");
EndProcedure

&AtClient
Procedure FilterFinancialAccountingChartOfAccountsOnChange(Item)
	CommonClientServer.SetDynamicListFilterItem(FinancialAccountingChartOfAccounts, "ChartOfAccounts", FilterFinancialAccountingChartOfAccounts);
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure RecordInAccounting(Command)
	
	ReflectInAccountingOnServer();
	
EndProcedure

&AtClient
Procedure ScheduleLabelClick(Item)
	
	FormParameters = ParametersOfRoutineTaskConfigurationForm();
	OpenForm("DataProcessor.ScheduledAndBackgroundJobs.Form.ScheduledJob",
		FormParameters,ThisForm,,,,,FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure RuleOperationResult(Command)
	Var ReportHeader;
	
	FormParameters = New Structure;
	FormParameters.Insert("GenerateOnOpen", True);
	FormParameters.Insert("ReportOptionsCommandsVisibility", False);
	
	DefineRuleConfigurationObject(FormParameters, ReportHeader);
	
	OpenForm("Report.ResultOfActualDataQuery.Form",
														FormParameters, , ReportHeader);
		
EndProcedure

&AtClient
Procedure ConfigureRules(Command)
	
	SetupParameters = New Structure("SettingObject1", DefineRuleConfigurationObject());
	OpenForm("DataProcessor.SetUpRulesOfReceivingActualBudgetingData.Form.RulesSetting",
									SetupParameters,,,,,,FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure OpenTheSettingsObject(Command)
	
	ShowValue(,DefineRuleConfigurationObject());
	
EndProcedure

&AtClient
Function TabularSections()
	
	ReturnValue = New Structure;
	ReturnValue.Insert("BudgetFlowItems", "OnlyWithTheRulesForBudgetItems");
	ReturnValue.Insert("BudgetBalanceItems", "OnlyWithTheBudgetIndicatorsRules");
	ReturnValue.Insert("BusinessTransactions", "OnlyWithTheRulesOfBusinessOperations");
	ReturnValue.Insert("AssetLiabilityItems", "OnlyWithTheRulesForAssetLiabilityItems");
	ReturnValue.Insert("FinancialAccountingChartOfAccounts", "OnlyWithTheInternationalAccountingChartOfAccountsRules");
	Return ReturnValue;

EndFunction

&AtClient
Procedure ShowAllItems(Command)
	
	Structure = TabularSections();
	For Each KeyValue In Structure Do
	
		CommonClientServer.SetDynamicListFilterItem(ThisForm[KeyValue.Key], 
						"ThereAreFactReceiptRules",,,,
						False);
		FormField = Items[KeyValue.Value]; // FormField - 
		FormField.Title = NStr("vi = 'Hiển thị';
								|ru = 'Показывать';
								|en = 'Show'; fa = 'نمایش';
								|it = 'Mostrare';
								|pl = 'Show';
								|tr = 'Göster'");
		
	EndDo;
	
EndProcedure

&AtClient
Procedure WithoutCurrentRules(Command)
	
	Structure = TabularSections();
	For Each KeyValue In Structure Do
	
		CommonClientServer.SetDynamicListFilterItem(ThisForm[KeyValue.Key], 
						"ThereAreFactReceiptRules",
						False,
						DataCompositionComparisonType.Equal,,
						True);
		FormField = Items[KeyValue.Value]; // FormField - 
		FormField.Title = NStr("vi = 'Chỉ không có quy tắc đang hiệu lực';
								|ru = 'Только без действующих правил';
								|en = 'Only without valid rules'; fa = 'فقط بدون قواعد معتبر';
								|it = 'Only without valid rules';
								|pl = 'Only without valid rules';
								|tr = 'Sadece geçerli kuralı olmayanlar'");
		
	EndDo;
	
EndProcedure

&AtClient
Procedure WithCurrentRules(Command)
	
	Structure = TabularSections();
	For Each KeyValue In Structure Do
	
		CommonClientServer.SetDynamicListFilterItem(ThisForm[KeyValue.Key], 
						"ThereAreFactReceiptRules",
						True,
						DataCompositionComparisonType.Equal,,
						True);
		FormField = Items[KeyValue.Value]; // FormField - 
		FormField.Title = NStr("vi = 'Chỉ với các quy tắc đang hiệu lực';
								|ru = 'Только с действующими правилами';
								|en = 'Only with valid rules'; fa = 'فقط با قواعد معتبر';
								|it = 'Only with valid rules';
								|pl = 'Only with valid rules';
								|tr = 'Sadece geçerli kuralı olanlar'");
		
	EndDo;
	
EndProcedure

#EndRegion

#Region Private
	
&AtServer
Procedure ManagingFormElementsDuringCreation()
	
	If Not GetFunctionalOption("EnterpriseManagement")
		And Not GetFunctionalOption("ComplexAutomation") Then
		Items.GroupRecordInAccounting.Visible = False;
	EndIf;
	
	If SettingUpRulesForAssetLiabilityItems Then
		VisibilityOfBusinessOperations = False;
		TitleOfArticlesOfAssetsLiabilities = NStr("vi = 'Kế toán hoạt động';
													|ru = 'Оперативный учет';
													|en = 'Operational accounting'; fa = 'حسابداری عملیاتی';
													|it = 'Contabilità operativa';
													|pl = 'Ewidencja operacyjna';
													|tr = 'Operasyonel muhasebe'");
	Else
		VisibilityOfBusinessOperations = True;
		TitleOfArticlesOfAssetsLiabilities = NStr("vi = 'Kế toán hoạt động (Số dư)';
													|ru = 'Оперативный учет (Остатки)';
													|en = 'Operational accounting (Balance)'; fa = 'حسابداری عملیاتی (مانده)';
													|it = 'Contabilità operativa (Rimanenze)';
													|pl = 'Ewidencja operacyjna (Salda)';
													|tr = 'Operasyonel muhasebe (Bakiyeler)'");
	EndIf;
	
	Items.PageRulesForBusinessOperations.Visible = VisibilityOfBusinessOperations;
	Items.PageRulesForItemsOfAssetsAndLiabilities.Title = TitleOfArticlesOfAssetsLiabilities;
	
EndProcedure

&AtServer
Procedure FormControl()
	Var DocumentsCount;
	
	If RuleSettingMode = 0 Then
		Items.PageByItemsAndIndicatorsOfBudgets.Visible = True;
		Items.PageByDataSources.Visible = False;
	Else
		Items.PageByItemsAndIndicatorsOfBudgets.Visible = False;
		Items.PageByDataSources.Visible = True;
	EndIf;
	
	Items.TheRulesPageInAccountsTheInternationalAccounting.Visible = UseInternationalAccounting;
	Items.TheRulesPageOnTheAccountsOfTheRegulatedAccounting.Visible = GetFunctionalOption("UseLocal");
	
	If DocumentsAreReflectedInBudgeting() Then
		Items.RecordInAccounting.Visible = False;
		Items.DecorationDocumentsAreRecorded.Visible = True;
		Items.DecorationForTheReflection.Title = NStr("vi = 'Phản ánh các chứng từ trong hệ thống con ""Lập ngân sách và lập kế hoạch""';
														|ru = 'Выполняется отражение документов в подсистеме ""Бюджетирование и планирование""';
														|en = 'Recording documents in the ""Budgeting and Planning"" subsystem'; fa = 'Recording documents in the ""Budgeting and Planning"" subsystem';
														|it = 'Riflessione dei documenti nel sottosistema ""Budgeting e pianificazione"" in corso';
														|pl = 'Wykonuje odbicie dokumentów w podsystemie ""Budżetowanie i planowanie""';
														|tr = '""Bütçeleme ve planlama"" alt sistemindeki belgeleri yansıtma işlemi gerçekleştirildi'");
	Else
		
		DocumentsCount = 0;
		If InformationRegisters.JobsForPostingInBudgeting.RequiredReflectionInBudgetingForReportForPeriod(
																			Date(1, 1, 1), , DocumentsCount, True) Then
		
			Items.RecordInAccounting.Visible = True;
			Items.DecorationDocumentsAreRecorded.Visible = False;
			Items.DecorationForTheReflection.Title = NStr("vi = 'Để phản ánh trong hệ thống con ""Lập kế hoạch và lập ngân sách"" %1 chứng từ';
															|ru = 'К отражению в подсистеме ""Бюджетирование и планирование"" %1 документов';
															|en = 'For recording %1 documents in the ""Budgeting and Planning"" subsystem'; fa = 'For recording %1 documents in the ""Budgeting and Planning"" subsystem';
															|it = 'In riflessione nel sottosistema ""Budgeting e pianificazione"" %1 documenti';
															|pl = 'Do odparcia w podsystemie ""Budżetowanie i planowanie"" %1 dokumentów';
															|tr = '""Bütçeleme ve planlama"" alt sistemine yansıtılacak %1 belgeleri'");
			Items.DecorationForTheReflection.Title = StringFunctionsClientServer.SubstituteParametersToString(
																Items.DecorationForTheReflection.Title, DocumentsCount);
		Else
			Items.RecordInAccounting.Visible = False;
			Items.DecorationDocumentsAreRecorded.Visible = False;
			Items.DecorationForTheReflection.Title = NStr("vi = 'Không cần phải phản ánh các chứng từ trong hệ thống con ""Lập ngân sách và lập kế hoạch""';
															|ru = 'Отражение документов в подсистеме ""Бюджетирование и планирование"" не требуется';
															|en = 'It is not required to record documents in the ""Budgeting and Planning"" subsystem'; fa = 'It is not required to record documents in the ""Budgeting and Planning"" subsystem';
															|it = 'Riflessione dei documenti nel sottosistema ""Budgeting e pianificazione"" non richiesta';
															|pl = 'Odbicie dokumentów w podsystemie ""Budżetowanie i planowanie"" nie jest wymagane';
															|tr = 'Belgelerin ""Bütçeleme ve planlama"" alt sistemine yansıtılmaları gerekmemektedir'");
		EndIf;
	EndIf;
	
	Items.SetUpSchedule.Visible = Not Common.DataSeparationEnabled();
	Items.GroupSwitchingToLimitControl2_5.Visible = GetFunctionalOption(
		"ControllingLimitsBasedOnBudgetingData2_4");

EndProcedure

&AtServerNoContext
Function DocumentsAreReflectedInBudgeting()
	
	Var_Key = "DocumentPostingInBudgeting";
	
	Filter = New Structure();
	Filter.Insert("Key", Var_Key);
	
	SetPrivilegedMode(True);
	ActiveTasks = New Array();
	If Common.DataSeparationEnabled() Then
		// A special fresh extension must be installed.
		If Common.SubsystemExists("CloudTechnology.JobsQueue") Then
			Filter.Insert("JobState", Enums.JobsStates.Running);
			ModuleJobsQueue = Common.CommonModule("JobsQueue");
			ActiveTasks = ModuleJobsQueue.GetJobs(Filter);
		EndIf;
	Else
		Filter.Insert("State", BackgroundJobState.Active);
		ActiveTasks = BackgroundJobs.GetBackgroundJobs(Filter);
	EndIf;
	SetPrivilegedMode(False);
	
	Return ActiveTasks.Count();
	
EndFunction

&AtClient
Procedure CheckingNeedForReflectionInAccounting()
	
	FormControl();
	
EndProcedure

&AtServer
Procedure ReflectInAccountingOnServer()
	
	ActualBudgetingDataServer.ReflectDocumentsAsBackgroundTask(,);
	FormControl();
	
EndProcedure

&AtServerNoContext
Function ParametersOfRoutineTaskConfigurationForm()
	Filter = New Structure();
	Filter.Insert("Metadata", "DocumentPostingInBudgeting");
	Jobs = ScheduledJobsServer.FindJobs(Filter);
	
	ScheduledJobUUID = Undefined;
	If Jobs.Count() > 0 Then
		ScheduledJobUUID = Jobs[0].UUID;		
	EndIf;
		
	FormParameters = New Structure("Action, Id","Change",ScheduledJobUUID);
	Return FormParameters;
EndFunction

&AtClient
Function DefineRuleConfigurationObject(UpdatedFormParameters = Undefined, ReportHeader = "")
	
	If RuleSettingMode = 0 Then
		If Items.PagesRulesByItemsBudgetIndicators.CurrentPage =
											Items.RulesForBudgetItemsPage Then
			SettingObject1 = Items.BudgetFlowItems.CurrentRow;
			ReportHeader = "BudgetFlowItem = " + SettingObject1;
			If UpdatedFormParameters <> Undefined Then
				UpdatedFormParameters.Insert("VariantKey", "RuleOperationResultByBudgetItem");
				UpdatedFormParameters.Insert("Filter", New Structure("BudgetFlowItem", SettingObject1));
			EndIf;
		ElsIf Items.PagesRulesByItemsBudgetIndicators.CurrentPage =
											Items.TheRulesPageInTermsOfBudgets Then
			SettingObject1 = Items.BudgetBalanceItems.CurrentRow;
			ReportHeader = "BudgetBalanceItem = " + SettingObject1;
			If UpdatedFormParameters <> Undefined Then
				UpdatedFormParameters.Insert("VariantKey", "RuleOperationResultByBudgetIndicator");
				UpdatedFormParameters.Insert("Filter", New Structure("BudgetBalanceItem", SettingObject1));
			EndIf;
		EndIf;
	Else
		If Items.PagesDataSourceSections.CurrentPage = 
											Items.PageRulesForBusinessOperations Then
			SettingObject1 = Items.BusinessTransactions.CurrentRow;
			ReportHeader = "BusinessOperation = " + SettingObject1;
			If UpdatedFormParameters <> Undefined Then
				UpdatedFormParameters.Insert("VariantKey", "RuleOperationResultByBudgetItems");
				UpdatedFormParameters.Insert("Filter", New Structure("DataSource", SettingObject1));
			EndIf;
		ElsIf Items.PagesDataSourceSections.CurrentPage = 
											Items.PageRulesForItemsOfAssetsAndLiabilities Then
			SettingObject1 = Items.AssetLiabilityItems.CurrentRow;
			ReportHeader = "AssetAndLiabilityItem = " + SettingObject1;
			If UpdatedFormParameters <> Undefined Then
				UpdatedFormParameters.Insert("VariantKey", "RuleOperationResultByBudgetIndicators");
				UpdatedFormParameters.Insert("Filter", New Structure("DataSource", SettingObject1));
			EndIf;
		ElsIf Items.PagesDataSourceSections.CurrentPage = 
											Items.TheRulesPageOnTheAccountsOfTheRegulatedAccounting Then
			SettingObject1 = Items.ComplianceAccountingAccountPlan.CurrentRow;
			ReportHeader = "GLAccount = " + SettingObject1;
			If UpdatedFormParameters <> Undefined Then
				UpdatedFormParameters.Insert("VariantKey", "RuleOperationResultByBudgetItemsAndIndicators");
				UpdatedFormParameters.Insert("Filter", New Structure("DataSource", SettingObject1));
			EndIf;
		ElsIf Items.PagesDataSourceSections.CurrentPage = 
											Items.TheRulesPageInAccountsTheInternationalAccounting Then
			SettingObject1 = Items.FinancialAccountingChartOfAccounts.CurrentRow;
			ReportHeader = "GLAccount = " + SettingObject1;
			If UpdatedFormParameters <> Undefined Then
				UpdatedFormParameters.Insert("VariantKey", "RuleOperationResultByBudgetItemsAndIndicators");
				UpdatedFormParameters.Insert("Filter", New Structure("DataSource", SettingObject1));
			EndIf;
		EndIf;
	EndIf;
	
	Return SettingObject1;
	
EndFunction

&AtClientAtServerNoContext 
Procedure SetCommandsAvailability(Items, NameOfDynamicList, FormItemName)
	
	If Items[NameOfDynamicList].CurrentRow = Undefined
		Or Items[NameOfDynamicList].CurrentData.IsFolder Then
		Items[FormItemName].Enabled = False;
	Else
		Items[FormItemName].Enabled = True;
	EndIf;
	
EndProcedure


#EndRegion