#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Internal

// Settings for the General report form in the report Options subsystem.
//
// Parameters:
//   Form - ClientApplicationForm - report form.
//   VariantKey - String - The name of the predefined report variant or the unique ID of the custom one.
//   Settings - Structure - see the return value of the Clientserver report.Get a setup report for silence().
//
Procedure DefineFormSettings(Form, VariantKey, Settings) Export
	Settings.Events.OnCreateAtServer = True;
	Settings.Events.BeforeLoadVariantAtServer = True;
	Settings.Events.OnLoadVariantAtServer = True;
EndProcedure

// Called in the report form handler of the same name after executing the form code.
//
// More detailed - See ReportsOverridable.BeforeLoadVariantAtServer
//
Procedure BeforeLoadVariantAtServer(ThisForm, NewDCSettings) Export
	
	Report = ThisForm.Report;
	FormSettingsComposer = Report.SettingsComposer;
	If Not FormSettingsComposer.Settings.AdditionalProperties.Property("CurrentVariantKey") Then
		FormSettingsComposer.Settings.AdditionalProperties.Insert("CurrentVariantKey", ThisForm.CurrentVariantKey);
	EndIf;
	NewDCSettings = FormSettingsComposer.Settings;
	
EndProcedure

// Called in the report form handler of the same name after executing the form code.
//
Procedure OnLoadVariantAtServer(ThisForm, NewDCSettings) Export
	
	If ThisForm.CurrentVariantKey = "Details" Then
		
		FormSettingsComposer = ThisForm.Report.SettingsComposer; // DataCompositionSettingsComposer -
		FixedSettings = FormSettingsComposer.FixedSettings;
		
		AddSource_1 = FixedSettings.Structure;
		PlaceAdded = FormSettingsComposer.Settings.Structure;
		PlaceAdded.Clear();
		
		While AddSource_1.Count() Do
			Group = AddSource_1[0];
			NewGrouping = FinancialReportingServer.NewGrouping(PlaceAdded, Group.Name,, False);
			For Each GroupingField In Group.GroupFields.Items Do
				FinancialReportingServer.NewDimensionField(
					NewGrouping,
					String(GroupingField.Field),
					GroupingField.GroupType);
			EndDo;
			PlaceAdded = NewGrouping.Structure;
			AddSource_1 = Group.Structure;
		EndDo;
		
		If FixedSettings.Selection.Items.Count() > 0 Then
			DataCompositionClientServer.CopyElements(FormSettingsComposer.Settings.Selection,
					FixedSettings.Selection,
					True);
		EndIf;
		
	EndIf;
	
EndProcedure

#EndRegion

#Region EventHandlers

Procedure OnComposeResult(ResultDocument, DetailsData, StandardProcessing)
	DocumentsCount = Undefined;
	
	StandardProcessing = False;
	UserSettingsModified = False;
	
	SetRequiredSettings(UserSettingsModified);
	
	TempTablesManager = PrepareTemporaryTables();
	
	BudgetingServer.AddDCSAnalyticsByType(DataCompositionSchema, "BudgetBalanceItem");
	
	BudgetingServer.AddAnalyticsPresentationExpressionsToDCS(DataCompositionSchema,
			"DataSets.Dimension.Fields",
			"BudgetBalanceItem");
	
	#Region StartBackgroundReflectionOfDocumentsInBudgeting
	
		Period = BudgetingClientServer.ValueOfDCSSettings(SettingsComposer, "Period"); // StandardPeriod -
		BeginOfPeriod = Period.StartDate;
		EndOfPeriod = Period.EndDate;
		AuxProperties = SettingsComposer.UserSettings.AdditionalProperties;
		If AuxProperties.Property("NumberOfDocumentsToBeReflectedInBudgeting") Then
			AuxProperties.Delete("NumberOfDocumentsToBeReflectedInBudgeting");
			UserSettingsModified = True;
		EndIf;
		StartBackgroundTask = False;
		If InformationRegisters.JobsForPostingInBudgeting.RequiredReflectionInBudgetingForReportForPeriod(
		BeginOfPeriod, EndOfPeriod, DocumentsCount, StartBackgroundTask) Then
			
			If StartBackgroundTask Then
				ActualBudgetingDataServer.ReflectDocumentsAsBackgroundTask(BeginOfPeriod, EndOfPeriod);
			EndIf;
			AuxProperties.Insert("NumberOfDocumentsToBeReflectedInBudgeting", DocumentsCount);
			AuxProperties.Insert("BeginOfPeriod", BeginOfPeriod);
			AuxProperties.Insert("EndOfPeriod", EndOfPeriod);
			
			AddParametersForCheckingDocumentReflection(AuxProperties, SettingsComposer);
			
		EndIf;
	#EndRegion
	
	For Each DataSet In DataCompositionSchema.DataSets Do
		AdjustQueryTextOfDataset(DataSet, TempTablesManager);
	EndDo;
	
	ReportSettings = SettingsComposer.GetSettings();
	If ReportSettings.AdditionalProperties.Property("VariantKey")
		And ReportSettings.AdditionalProperties.VariantKey = "Details"
		And AvailabilityOfActualDataInScriptReportSettings(ReportSettings) Then
		For Each SelectedField In ReportSettings.Selection.Items Do
			If StrEndsWith(TrimAll(SelectedField.Field), "Script_") Then
				SelectedField.Field = New DataCompositionField(StrReplace(TrimAll(SelectedField.Field), "Script_", "Real"));
			EndIf;
		EndDo;
	EndIf;
	
	TemplateComposer = New DataCompositionTemplateComposer;
	CompositionTemplate = TemplateComposer.Execute(
		DataCompositionSchema, ReportSettings, DetailsData);
	DataCompositionProcessor = New DataCompositionProcessor;
	DataCompositionProcessor.Initialize(CompositionTemplate, , DetailsData,
		True, , TempTablesManager);
	
	ProcessorOutputToTabularDocument = New DataCompositionResultSpreadsheetDocumentOutputProcessor;
	ProcessorOutputToTabularDocument.SetDocument(ResultDocument);
	ProcessorOutputToTabularDocument.Output(DataCompositionProcessor);
	
	ActualBudgetingDataServer.DeduceRelevanceOfReflectionOfActualData(ResultDocument, AuxProperties,
		StartBackgroundTask);
	
	// We will inform the report form that the settings have been modified
	If UserSettingsModified Then
		SettingsComposer.UserSettings.AdditionalProperties.Insert("UserSettingsModified", True);
	EndIf;
	
	ReportIsBlank = ReportsServer.ReportIsBlank(ThisObject, DataCompositionProcessor);
	SettingsComposer.UserSettings.AdditionalProperties.Insert("ReportIsBlank", ReportIsBlank);
	
EndProcedure

#EndRegion

#Region Private

#Region GettingReportData

Function PrepareTemporaryTables()
	
	ReportSettings = SettingsComposer.GetSettings();
	FactGettingParameters = ParametersForGettingFactByReportSettings(ReportSettings);
	
	Period = DataCompositionClientServer.GetParameter(ReportSettings, "Period").Value; // StandardPeriod -
	PeriodOfBalancesAtBeginning = Period.StartDate;
	
	SelectionElementByPeriod = Undefined;
	For Each Periodicity In Enums.Periodicity.OrderedPeriodicities() Do
		
		Period =  FinancialReportingClientServer.PeriodStrings(Periodicity).Period;
		SelectionElementByPeriod = FinancialReportingServer.FindSelectionElement(ReportSettings.Filter, Period);
		If SelectionElementByPeriod <> Undefined Then
			SelectionElementByPeriod.Use = False; // Turn it off so that it does not interfere with getting turns
			Break;
		EndIf;
	EndDo;
	
	TempTablesManager = New TempTablesManager;
	
	// Balances At The Beginning
	ParametersForObtainingBalances = ParametersForGettingPlannedOpeningBalancesBasedOnReportSettings(ReportSettings);
	InformationRegisters.OpeningBalanceOfEstimates.GenerateTemporaryTables_ActualOpeningBalancesOfCalculatedIndicators(
		TempTablesManager, ParametersForObtainingBalances);
	If TMCommonUse.TemporaryTableSize(TempTablesManager, "CurrentBalanceDates") > 0 Then
		DataTableParameters = BudgetingServer.ParametersForConvertingDataTableToCurrency();
		DataTableParameters.TempTablesManager = TempTablesManager;
		DataTableParameters.TempTableName = "BalancesAccordingToCalculatedIndicators";
		BudgetingServer.ConvertDataTableToCurrency(DataTableParameters, FactGettingParameters.ReportCurrency,
			FactGettingParameters.FunctionalCurrency);
	EndIf;
	
	FactOnBudgetIndicators = BudgetingServer.FactOnBudgetIndicators(ReportSettings, FactGettingParameters,
		TempTablesManager, "FactOnBudgetIndicators");
	
	// Turnover plan
	TurnoversPlan = TurnoversPlan(ReportSettings);
	Query = New Query;
	Query.TempTablesManager = TempTablesManager;
	Query.SetParameter("TurnoversPlan", TurnoversPlan);
	Query.Text = TMCommonUse.QueryTextDataFromValueTable(TurnoversPlan, "TurnoversPlan");
	Query.Execute();
	
	// Turnover Fact
	TurnoverFact = BudgetingServer.FactOnItemsThatAffectBudgetPerformance(
		ReportSettings, FactGettingParameters, True, TempTablesManager);
	
	If SelectionElementByPeriod <> Undefined Then
		
		If SelectionElementByPeriod.ComparisonType <> DataCompositionComparisonType.Equal
			And SelectionElementByPeriod.ComparisonType <> DataCompositionComparisonType.InList Then
			Raise NStr("vi = 'Không được phép xây dựng báo cáo với loại so sánh trong lựa chọn trong khoảng thời gian khác với ""Bằng"" hoặc ""Trong danh sách"".';
						|ru = 'Не допускается строить отчет c видом сравнения в отборе по периоду отличном от ""Равно"" или ""В списке""';
						|en = 'You cannot make a report with a comparison kind in the filter by period which differs from ""Equal to"" or ""In list""'; fa = 'You cannot make a report with a comparison kind in the filter by period which differs from ""Equal to"" or ""In list""';
						|it = 'Non è consentito creare un report con il tipo di confronto nel filtro in base al periodo diverso da ""Uguale"" oppure ""Nell''elenco""';
						|pl = 'Niedozwolone jest tworzenie raportu z typem porównania w okresie innym, niż ""Równy"" lub ""Na liście""';
						|tr = 'Döneme göre filtrede ""Eşit"" veya ""Listede"" dışında karşılaştırma türüne sahip bir rapor oluşturulmasına izin verilmez'");
		EndIf;
		
		If SelectionElementByPeriod.ComparisonType = DataCompositionComparisonType.InList Then
			PeriodOfBalancesAtBeginning = SelectionElementByPeriod.RightValue[0].Value;
		Else
			PeriodOfBalancesAtBeginning = SelectionElementByPeriod.RightValue;
		EndIf;
		
		// Additional calculation of balances for the selection period based on turnover data and balances at the beginning of the period.
		SchemeForCalculatingBalances = Reports.TrialBalanceForBudgetBalanceItems.GetTemplate("OpeningBalanceCalculation");
		
		BalanceCalculationSettings = SchemeForCalculatingBalances.DefaultSettings;
		DataCompositionClientServer.AddFilter(
			BalanceCalculationSettings, 
			SelectionElementByPeriod.LeftValue,
			PeriodOfBalancesAtBeginning,
			DataCompositionComparisonType.Less);
		
		For Each DataSet In SchemeForCalculatingBalances.DataSets Do
			AdjustQueryTextOfDataset(DataSet, TempTablesManager);
		EndDo;
		
		BalancesAtBeginning = FinancialReportingServer.UploadDCSResults(SchemeForCalculatingBalances,
			BalanceCalculationSettings, , , TempTablesManager);
		
		QueriesTexts = New Array;
		FinancialAccountingByBalanceSheetRegisterData.AddRequestToDeleteTemporaryTable(QueriesTexts,
			"FactOnBudgetIndicators");
		FinancialAccountingByBalanceSheetRegisterData.AddRequestToDeleteTemporaryTable(QueriesTexts,
			"BalancesAccordingToCalculatedIndicators");
		QueriesTexts.Add(TMCommonUse.QueryTextDataFromValueTable(BalancesAtBeginning,
			"BalancesAccordingToCalculatedIndicators"));
		Query.SetParameter("BalancesAccordingToCalculatedIndicators", BalancesAtBeginning);
		Query.Text = StrConcat(QueriesTexts, Common.QueryBatchSeparator());
		Query.Execute();
		
		// Correction of Query Texts of data sets of the main data layout scheme
		QueriesTexts = StringFunctionsClientServer.SplitStringIntoSubstringsArray(
			DataCompositionSchema.DataSets.Dimension.Query, TMCommonUse.QuerySeparatorInJoin());
		QueriesTexts.Delete(1);
		DataCompositionSchema.DataSets.Dimension.Query = StrConcat(QueriesTexts,
			TMCommonUse.QuerySeparatorInJoin());
		
		QueriesTexts = StringFunctionsClientServer.SplitStringIntoSubstringsArray(
			DataCompositionSchema.DataSets.BalancesAtBeginning.Query,
			TMCommonUse.QuerySeparatorInJoin());
		QueryText = QueriesTexts[0];
		QueryText = StrReplace(QueryText,
			"0 AS QuantityStartBalanceFact",
			"BalancesAccordingToCalculatedIndicators.CountReal AS QuantityStartBalanceFact");
		QueryText = StrReplace(QueryText,
			"0 AS AmountStartBalanceFact",
			"BalancesAccordingToCalculatedIndicators.SumReal AS AmountStartBalanceFact");
		QueryText = StrReplace(QueryText, "&TextOfFieldsQuantityAmountFact",
			"BalancesAccordingToCalculatedIndicators.CountReal AS QuantityStartBalanceFact,
			|BalancesAccordingToCalculatedIndicators.SumReal AS AmountStartBalanceFact");
		DataCompositionSchema.DataSets.BalancesAtBeginning.Query = QueryText;
		
	EndIf;
	
	DataCompositionServer.SetDCSParameter(DataCompositionSchema, "DateOfRemainingGoods", ?(TypeOf(PeriodOfBalancesAtBeginning)
		= Type("StandardBeginningDate"), PeriodOfBalancesAtBeginning.Date, PeriodOfBalancesAtBeginning));
	
	// After the final calculation of the initial balances.
	// In the case of decryption of another report, the analyst and the registrars of the turnover of the fact should not be included in the report if the planned data is decrypted.
	NeedToObtainFact = True;
	NeedToAddFactScript = False;
	If ReportSettings.AdditionalProperties.Property("VariantKey")
		And ReportSettings.AdditionalProperties.VariantKey = "Details" Then
		NeedToObtainFact = AvailabilityOfActualDataInScriptReportSettings(ReportSettings);
		NeedToAddFactScript = NeedToObtainFact;
	EndIf;
	
	If NeedToAddFactScript Then
		Query.Text = 
		"SELECT
		|	VALUE(Catalog.BudgetingScenarios.ActualData) AS Scenario
		|ADD BudgetingScenarios";
		Query.Execute();
	EndIf;
	
	If Not NeedToObtainFact Then
		TurnoverFact = New ValueTable;
		TempTableTurnoverFact = TempTablesManager.Tables.Find("TurnoverFactByInfluencingBudgetItems");
		For Each Column In TempTableTurnoverFact.Columns Do
			TurnoverFact.Columns.Add(Column.Name, Column.ValueType);
		EndDo;
		If TempTableTurnoverFact.Columns.Find("Scenario") = Undefined Then
			TurnoverFact.Columns.Add("Scenario", New TypeDescription("CatalogRef.BudgetingScenarios"));
		EndIf;
		QueriesTexts = New Array;
		FinancialAccountingByBalanceSheetRegisterData.AddRequestToDeleteTemporaryTable(QueriesTexts,
			"TurnoverFactByInfluencingBudgetItems");
		QueriesTexts.Add(TMCommonUse.QueryTextDataFromValueTable(TurnoverFact,
			"TurnoverFactByInfluencingBudgetItems"));
		Query.SetParameter("TurnoverFactByInfluencingBudgetItems", TurnoverFact);
		Query.Text = StrConcat(QueriesTexts, Common.QueryBatchSeparator());
		Query.Execute();
	EndIf;
	
	Return TempTablesManager;
	
EndFunction

Procedure AdjustQueryTextOfDataset(DataSet, TempTablesManager)
	
	If TypeOf(DataSet) = Type("DataCompositionSchemaDataSetUnion") Then
		For Each DataSet In DataSet.Items Do
			AdjustQueryTextOfDataset(DataSet, TempTablesManager);
		EndDo;
	ElsIf TypeOf(DataSet) = Type("DataCompositionSchemaDataSetQuery") Then
		ReplacementTextTemplate = "&FieldText%1%2_";
		For Each TempTable In TempTablesManager.Tables Do
			TableName = TempTable.FullName;
			ReplacementText = StringFunctionsClientServer.SubstituteParametersToString(ReplacementTextTemplate, TableName,
				"SecondPeriod");
			If StrFind(DataSet.Query, ReplacementText) > 0 Then
				TMCommonUse.ReplaceMissingTTFieldsInQueryText(TempTablesManager, DataSet.Query,
					ReplacementText, TableName, "SecondPeriod");
			EndIf;
			ReplacementText = StringFunctionsClientServer.SubstituteParametersToString(ReplacementTextTemplate, TableName,
				"RatePeriod");
			If StrFind(DataSet.Query, ReplacementText) > 0 Then
				TMCommonUse.ReplaceMissingTTFieldsInQueryText(TempTablesManager, DataSet.Query,
					ReplacementText, TableName, "RatePeriod");
			EndIf;
		EndDo;
	EndIf;
	
EndProcedure

Function TurnoversPlan(ReportSettings)
	
	RulesForCalculatingIndicators = BudgetingServer.GetRulesForCalculatingBudgetMetrics(ReportSettings);
	
	RequestAccordingToCalculationRules = BudgetingServer.GenerateRequestToDataSourceAccordingToCalculationRules(
		RulesForCalculatingIndicators.UnloadColumn("CalculationRule"), "Plan");
	QueryText = RequestAccordingToCalculationRules.QueryText;
	If IsBlankString(QueryText) Then
		QueryText = BudgetingServer.GetQueryTextToSourceOfIndicatorDataWithoutCalculationRules();
		QueryText = RequestSchemes.SetRoomToTemporaryTable(QueryText, "Data");
		QueryText = StrReplace(QueryText, "&ConditionText", "FALSE");
		QueryText = StrReplace(QueryText, "UNDEFINED AS Recorder",
			"VALUE(Document.BudgetEntryForm.EmptyRef) AS Recorder");
	Else
		QueryText = StrReplace(QueryText,
			"PlanningPeriod BETWEEN &ExpressionStartOfPeriod AND &ExpressionEndOfPeriod",
			"PlanningPeriod BETWEEN &ExpressionStartOfPeriod AND &ExpressionEndOfPeriod AND Status IN (&TurnoversInStatuses)");
		QueryText = StrReplace(QueryText, "&SourceTableConditionsAndAlignmentFields",
			"TRUE {(Scenario).* AS Scenario, (Organization).* AS Organization, (Department).* AS Department, (Currency).* AS Currency}");
		QueryText = StrReplace(QueryText, "UNDEFINED AS Recorder",
			"AliasOfSourceTable.Recorder AS Recorder");
	EndIf;
	
	QueryText = StrReplace(QueryText, "DayPeriod", "SecondPeriod");
	
	LayoutSchemeOfPlan = Reports.TrialBalanceForBudgetBalanceItems.GetTemplate("TurnoversPlan");
	Settings = LayoutSchemeOfPlan.DefaultSettings;
	
	BudgetingServer.AddDCSAnalyticsByType(LayoutSchemeOfPlan, "BudgetBalanceItem");
	
	Set = LayoutSchemeOfPlan.DataSets.Plan;
	Set.Query = QueryText + Common.QueryBatchSeparator() + Set.Query;
	For Each QueryParameter In RequestAccordingToCalculationRules.QueryOptions Do
		DataCompositionServer.AddParameter(LayoutSchemeOfPlan, QueryParameter.Key, , QueryParameter.Value,
			True, True);
	EndDo;
	
	DataCompositionClientServer.FillInElements(Settings.DataParameters, ReportSettings.DataParameters);
	DataCompositionClientServer.CopyDataCompositionFilter(LayoutSchemeOfPlan, Settings, ReportSettings);
	
	Group = Settings.Structure[0];
	
	If DataCompositionClientServer.FieldUsed_(ReportSettings, "Recorder", True) Then
		FinancialReportingServer.NewDimensionField(Group, "Recorder");
	EndIf;
	
	For Each Periodicity In Enums.Periodicity.OrderedPeriodicities() Do
		If Not ValueIsFilled(Periodicity) Then
			Continue;
		EndIf;
		PeriodField = FinancialReportingClientServer.PeriodStrings(Periodicity).Period;
		FinancialReportingServer.NewDimensionField(Group, PeriodField);
	EndDo;
	
	If DataCompositionClientServer.FieldUsed_(ReportSettings, "UpdateDate", True) Then
		FinancialReportingServer.NewDimensionField(Group, "UpdateDate");
	EndIf;
	
	ReportCurrency = DataCompositionClientServer.GetParameter(ReportSettings, "Currency").Value;
	FunctionalCurrency = DataCompositionClientServer.GetParameter(ReportSettings, "FunctionalCurrency").Value;
	
	If FunctionalCurrency = Enums.AccountingKindsInFunctionalCurrency.InManagementAccountingCurrency_ Then
		If ReportCurrency = Constants.ManagementAccountingCurrency.Get() Then
			SumExpression = "SumMan";
		Else
			SumExpression = "
			|CASE
			|	WHEN Currency = &Currency THEN
			|		AmountInCurrency
			|	ELSE
			|		SumMan * RelativeRateOfManAccounting / RelativeExchangeRateBaseCurrencyOfManScenarioAccounting * ISNULL(ForecastRate, 1)
			|END
			|";
		EndIf;
	ElsIf FunctionalCurrency = Enums.AccountingKindsInFunctionalCurrency.InCurrencyOfLocal Then
		SumExpression = "
		|CASE
		|	WHEN LocalAccountingCurrency = &Currency THEN
		|		SumCompl
		|	ELSE
		|		CASE
		|			WHEN Currency = &Currency THEN
		|				AmountInCurrency
		|			ELSE
		|				SumCompl / RelativeExchangeRateBaseCurrencyOfLocalAccountingScenario * ISNULL(ForecastRate, 1)
		|		END
		|END
		|";
	Else
		SumExpression = "0";
	EndIf;
	
	Resources = New Structure;
	Resources.Insert("Sum", New Structure("NameReceipt, NameExpense, Expression", "TotalParishPlan", "AmountExpensePlan",
		SumExpression));
	Resources.Insert("Count", New Structure("NameReceipt, NameExpense, Expression", "NumberOfParishPlan",
		"NumberOfConsumable_", "Count"));
	ExpressionReceipt = "CASE WHEN Expense THEN 0 ELSE %Field END";
	ExpressionExpense = "CASE WHEN Expense THEN %Field ELSE 0 END";
	For Each Resource In Resources Do
		ResourceReceipt = Resource.Value.NameReceipt;
		FinancialReportingServer.NewCalculatedResource(
			LayoutSchemeOfPlan, 
			ResourceReceipt, 
			StrReplace(ExpressionReceipt, "%Field", Resource.Value.Expression), 
			"Sum");
		FinancialReportingServer.NewSelectionField(Settings, ResourceReceipt);
		
		ResourceExpense = Resource.Value.NameExpense;
		FinancialReportingServer.NewCalculatedResource(
			LayoutSchemeOfPlan, 
			ResourceExpense, 
			StrReplace(ExpressionExpense, "%Field", Resource.Value.Expression),
			"Sum");
		FinancialReportingServer.NewSelectionField(Settings, ResourceExpense);
	EndDo;
	
	TurnoversPlan = FinancialReportingServer.UploadDCSResults(LayoutSchemeOfPlan, Settings);
	
	Return TurnoversPlan;
	
EndFunction

#EndRegion

#Region Other

Procedure AddParametersForCheckingDocumentReflection(AuxProperties, Var_SettingsComposer)
	//If there is a simple selection that may affect the need for a warning about non-reflected documents, then we will add the parameters.
	NameOfLayoutField = "BudgetBalanceItem";
	FilterItems1 = New Array;
	BudgetReportingCacheCalculationServer.FindSelectionByName(Var_SettingsComposer.GetSettings(), NameOfLayoutField, FilterItems1);
	If FilterItems1.Count() = 1 Then
		FilterElement = FilterItems1[0]; // DataCompositionFilterItem -
		If FilterElement.Use
			And FilterElement.ComparisonType = DataCompositionComparisonType.Equal
			And FilterElement.Parent = Undefined Then
			AuxProperties.Insert("CheckingStoredRulesAndBudgets", FilterElement.RightValue);
		EndIf;
	EndIf;
EndProcedure

Function AvailabilityOfActualDataInScriptReportSettings(ReportSettings)
	
	QueryText = 
	"SELECT ALLOWED
	|	BudgetingScenarios.Ref AS Scenario
	|FROM
	|	Catalog.BudgetingScenarios AS BudgetingScenarios
	|WHERE
	|	BudgetingScenarios.Ref = VALUE(Catalog.BudgetingScenarios.ActualData)";
	
	SchemaOfReportScript = DataCompositionServer.DataCompositionSchemaForQueryText(QueryText);
	
	ScriptSettings = New DataCompositionSettings;
	DataCompositionClientServer.AddGrouping(ScriptSettings);
	DataCompositionClientServer.AddSelectedField(ScriptSettings, "Scenario");
	
	DataCompositionClientServer.CopyDataCompositionFilter(SchemaOfReportScript, ScriptSettings, ReportSettings);
	
	BudgetingScenarios = FinancialReportingServer.UploadDCSResults(SchemaOfReportScript, ScriptSettings);
	
	Return BudgetingScenarios.Count() > 0;
	
EndFunction

Function ParametersForGettingFactByReportSettings(ReportSettings)
	
	Parameters = BudgetingServer.TemplateForGettingFactParameters();
	
	Parameters.ReportCurrency = DataCompositionClientServer.GetParameter(ReportSettings, "Currency").Value;
	Parameters.FunctionalCurrency = DataCompositionClientServer.GetParameter(ReportSettings, "FunctionalCurrency").Value;
	Parameters.Period = DataCompositionClientServer.GetParameter(ReportSettings, "Period").Value;
	
	Parameters.BalancesOnlyAtBeginningOfPeriod = True;
	Parameters.ByCompanies = True;
	Parameters.ByBusinessUnits = True;
	
	If DataCompositionClientServer.FieldUsed_(ReportSettings, "Recorder", True) Then
		Parameters.ByRegistrar = True;
	EndIf;
	
	For Each Periodicity In Enums.Periodicity.OrderedPeriodicities() Do
		If Not ValueIsFilled(Periodicity) Then
			PeriodField = "Period";
		Else
			PeriodField = FinancialReportingClientServer.PeriodStrings(Periodicity).Period;
		EndIf;
		If DataCompositionClientServer.FieldUsed_(ReportSettings, PeriodField, True) Then
			Parameters.Periodicity = Periodicity;
			Break;
		EndIf;
	EndDo;
	
	ThereIsPeriodicityOfSecond = DataCompositionClientServer.FieldUsed_(ReportSettings,
				"UpdateDate",
				True);
	Parameters.Insert("ThereIsPeriodicityOfSecond", ThereIsPeriodicityOfSecond);
	
	Return Parameters; 
	
EndFunction

Procedure SetRequiredSettings(UserSettingsModified)
	
	CurrencyCustomParameter = DataCompositionClientServer.GetParameter(SettingsComposer, "Currency");
	CurrencyFixedParameter = DataCompositionClientServer.GetParameter(SettingsComposer.FixedSettings, "Currency");
	
	ThereIsCurrency = CurrencyCustomParameter <> Undefined And ValueIsFilled(CurrencyCustomParameter.Value);
	If Not ThereIsCurrency Then
		ThereIsCurrency = CurrencyFixedParameter <> Undefined And ValueIsFilled(CurrencyFixedParameter.Value);
	EndIf;
	
	If Not ThereIsCurrency Then
		DataCompositionClientServer.SetParameter(
			SettingsComposer, "Currency", Constants.ManagementAccountingCurrency.Get());
		UserSettingsModified = True;
	Else
		UseMultipleCurrencies = GetFunctionalOption("UseMultipleCurrencies");
		If Not UseMultipleCurrencies Then
			CurrencyValue = ?(CurrencyCustomParameter = Undefined, Undefined, CurrencyCustomParameter.Value);
			If Not ValueIsFilled(CurrencyValue) Then
				CurrencyValue = ?(CurrencyFixedParameter = Undefined, Undefined, CurrencyFixedParameter.Value);
			EndIf;
			CurrencyOfMan = Constants.ManagementAccountingCurrency.Get();
			If CurrencyValue <> CurrencyOfMan Then
				DataCompositionClientServer.SetParameter(
					SettingsComposer, "Currency", CurrencyOfMan);
				UserSettingsModified = True;
			EndIf;
		EndIf;
	EndIf;
	
EndProcedure

Function ParametersForGettingPlannedOpeningBalancesBasedOnReportSettings(ReportSettings)
	
	BalanceParameters = New Structure;
	PeriodParameter =  DataCompositionClientServer.GetParameter(ReportSettings, "Period").Value; // StandardPeriod
	BalanceParameters.Insert("DateOfRemainingGoods", PeriodParameter.StartDate);
	BalanceParameters.Insert("ByCompanies", True);
	BalanceParameters.Insert("ByBusinessUnits", True);
	BalanceParameters.Insert("BalancesForSpecificDate", True);
	BalanceParameters.Insert("ReportSettings", ReportSettings);
	BalanceParameters.Insert("SelectionSet", False);
	BalanceParameters.Insert("DataLayoutSelectionIsSet", True);
	BalanceParameters.Insert("FunctionalCurrency", DataCompositionClientServer.GetParameter(ReportSettings,
		"FunctionalCurrency").Value);
	
	Return BalanceParameters;
	
EndFunction

// Called in the handler of the report form event of the same name after executing the form code.
//
// Parameters:
//   ThisForm - ClientApplicationForm - report form.
//   Cancel - Boolean - passed from the handler parameters "as is".
//   StandardProcessing - Boolean - passed from the handler parameters "as is".
//
// See also:
//   "Formaclientapplications.Joining the server" in the syntax assistant.
//
Procedure OnCreateAtServer(ThisForm, Cancel, StandardProcessing) Export
	
	Parameters = ThisForm.Parameters;
	
	If Parameters.Property("CommandParameter") Then
		ThisForm.ParametersForm.Filter.Insert("BudgetBalanceItem", Parameters.CommandParameter);
	EndIf;
	
	UseMultipleCurrencies = GetFunctionalOption("UseMultipleCurrencies");
	If Not UseMultipleCurrencies Then
		CurrencyParameter = DataCompositionSchema.Parameters.Currency;
		CurrencyParameter.IncludeInAvailableFields = False;
		CurrencyParameter.UseRestriction = True;
		ReportsServer.AttachSchema(ThisObject, ThisForm, DataCompositionSchema, "");
	EndIf;
	
EndProcedure

#EndRegion

#EndRegion

#EndIf