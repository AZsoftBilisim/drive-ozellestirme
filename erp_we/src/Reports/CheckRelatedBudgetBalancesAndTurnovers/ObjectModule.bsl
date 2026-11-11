#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure OnComposeResult(ResultDocument, DetailsData, StandardProcessing)
	
	StandardProcessing = False;
	
	TemplateComposer = New DataCompositionTemplateComposer;
	CompositionTemplate = TemplateComposer.Execute(DataCompositionSchema,
				SettingsComposer.GetSettings(),
				DetailsData);
	
	RequestAccordingToCalculationRules = DataCompositionServer.GETRequestFromLayoutTemplate(CompositionTemplate, "CalculationsRules");
	CalculationRulesTable = RequestAccordingToCalculationRules.Execute().Unload();
	
	ExternalSets = New Structure;
	ExternalSets.Insert("RelatedBalancesAndTurnover", RelatedBalancesAndBudgetTurnover(
		CalculationRulesTable.UnloadColumn("CalculationRule")));
	ExternalSets.Insert("BudgetFlowItemSettings", BudgetFlowItemSettings(CalculationRulesTable.UnloadColumn(
		"Receiver")));
	
	DataCompositionProcessor = New DataCompositionProcessor;
	DataCompositionProcessor.Initialize(CompositionTemplate, ExternalSets , DetailsData, True);
	
	ProcessorOutputToTabularDocument = New DataCompositionResultSpreadsheetDocumentOutputProcessor;
	ProcessorOutputToTabularDocument.SetDocument(ResultDocument);
	ProcessorOutputToTabularDocument.Output(DataCompositionProcessor);
	
	ReportIsBlank = ReportsServer.ReportIsBlank(ThisObject, DataCompositionProcessor);
	SettingsComposer.UserSettings.AdditionalProperties.Insert("ReportIsBlank", ReportIsBlank);
	
EndProcedure

#EndRegion

#Region Internal

// Settings for the General report form in the report Options subsystem.
//
// Parameters:
//   Form - ClientApplicationForm - report form.
//   VariantKey - String - The name of the predefined report variant or the unique ID of the custom one.
//   Settings - See ReportsClientServer.GetDefaultReportSettings
//
Procedure DefineFormSettings(Form, VariantKey, Settings) Export

EndProcedure

#EndRegion

#Region Private

#Region GettingReportData

Function RelatedBalancesAndBudgetTurnover(CalculationsRules)
	
	TableOfBalancesAndTurnover = New ValueTable;
	For Each Field In DataCompositionSchema.DataSets.RelatedBalancesAndTurnover.Fields Do
		TableOfBalancesAndTurnover.Columns.Add(Field.Field, Field.ValueType, Field.Title);
	EndDo;
	
	Query = New Query;
	Period = DataCompositionClientServer.GetParameter(SettingsComposer.UserSettings,
		"Period").Value; // -Standard period-
	Query.SetParameter("BeginOfPeriod", Period.StartDate);
	Query.SetParameter("EndOfPeriod", Period.EndDate);
	
	QueryText = 
	"SELECT
	|	Data.BudgetFlowItem AS BudgetFlowItem,
	|	Data.DayPeriod AS DayPeriod,
	|	Data.PlanningPeriod AS PlanningPeriod,
	|	Data.Scenario AS Scenario,
	|	Data.Organization AS Organization,
	|	Data.Department AS Department,
	|	Data.Currency AS Currency,
	|	&TextOfDimensionsFields,
	|	CASE
	|		WHEN Data.BudgetFlowItem.RecordByQuantity
	|			THEN Data.CountTurnover
	|		ELSE 0
	|	END AS Count,
	|	Data.SumManTurnover AS SumMan,
	|	Data.SumComplTurnover AS SumCompl,
	|	Data.ScenarioAmountTurnover AS ScenarioAmount,
	|	CASE
	|		WHEN Data.BudgetFlowItem.RecordByCurrency
	|			THEN Data.AmountInCurrencyTurnover
	|		ELSE 0
	|	END AS AmountInCurrency,
	|	&CalculationRule AS CalculationRule
	|FROM
	|	Data AS Data";
	ArrayOfAnalystFields = New Array;
	MaximumNumberOfAnalysts = BudgetingClientServer.MaximumNumberOfAnalysts();
	For DimensionNumber = 1 To MaximumNumberOfAnalysts Do
		ArrayOfAnalystFields.Add(StringFunctionsClientServer.SubstituteParametersToString(
			"Data.Dimension%1 AS Dimension%1", DimensionNumber));
	EndDo;
	QueryText = StrReplace(QueryText, "&TextOfDimensionsFields", StrConcat(ArrayOfAnalystFields, "," + Chars.LF
		+ Chars.Tab));
	
	For Each CalculationRule In CalculationsRules Do
		
		QueryData = CalculationRule.RequestStorage.Get();
		If TypeOf(QueryData) <> Type("Structure") Then
			Continue;
		EndIf;
		
		NameOfSourceParameter = "Source_" + QueryData.RuleID;
		NameOfReceiverParameter = "Receiver_" + QueryData.RuleID;
		
		QueriesTexts = New Array;
		If Not IsBlankString(QueryData.QueryTextsOfDistributionDatabase) Then
			For Each KeyAndValue In QueryData.QueryTextsOfDistributionDatabase Do
				QueriesTexts.Add(KeyAndValue.Value);
			EndDo;
		EndIf;
		If Not IsBlankString(QueryData.QueryTextForecastExchangeRates) Then
			QueryTextForecastExchangeRates = StrReplace(QueryData.QueryTextForecastExchangeRates, "&DateEmpty",
				"&BeginOfPeriod");
			QueryTextForecastExchangeRates = StrReplace(QueryTextForecastExchangeRates, "(TRUE)",
				"ForecastedExchangeRatesOfScenarios.Period BETWEEN &BeginOfPeriod AND &EndOfPeriod");
			QueriesTexts.Add(QueryTextForecastExchangeRates);
		EndIf;
		If Not IsBlankString(QueryData.QueryTextPartnersCounterparties) Then
			QueryTextPartnersCounterparties = StrReplace(QueryData.QueryTextPartnersCounterparties,
				"Plans.Recorder IN (&Recorders)", "(Plans.Period BETWEEN &BeginOfPeriod AND &EndOfPeriod)");
			QueriesTexts.Add(QueryTextPartnersCounterparties);
		EndIf;
		If Not IsBlankString(QueryData.QueryTextTemporaryTable) Then
			QueriesTexts.Add(QueryData.QueryTextTemporaryTable);
		EndIf;
		QueriesTexts.Add(QueryData.QueryText);
		QueriesTexts.Add(QueryText);
		
		Query.Text = StrConcat(QueriesTexts, Common.QueryBatchSeparator());
		Query.Text = StrReplace(Query.Text, "ExpressionStartOfPeriod", "BeginOfPeriod");
		Query.Text = StrReplace(Query.Text, "ExpressionEndOfPeriod", "EndOfPeriod");
		For Each QueryParameter In QueryData.QueryOptions Do
			If QueryParameter.Key = QueryData.SourceIdentificator Then
				Query.Text = StrReplace(Query.Text, NameOfSourceParameter, QueryParameter.Key);
			ElsIf QueryParameter.Key = QueryData.ReceiverId Then
				Query.Text = StrReplace(Query.Text, NameOfReceiverParameter, QueryParameter.Key);
			EndIf;
			Query.SetParameter(QueryParameter.Key, QueryParameter.Value);
		EndDo;
		If StrFind(QueryData.SourceIdentificator, "SourceType_") > 0 Then
			SourceType = StrReplace(QueryData.SourceIdentificator, "SourceType_", "");
			Query.Text = StrReplace(Query.Text, StringFunctionsClientServer.SubstituteParametersToString(
				"AliasOfSourceTable.Recorder IN (&Recorders_%1)", SourceType), "TRUE");
		EndIf;
		Query.SetParameter("CalculationRule", CalculationRule);
		Try
			QueryResult = Query.Execute(); //@skip-check query-in-loop
			If QueryResult.IsEmpty() Then
				Continue;
			EndIf;
			TMCommonUse.AddRowsToTable(TableOfBalancesAndTurnover, QueryResult.Unload());
		Except
			ErrorText = NStr("vi = 'Lỗi khi tính dữ liệu theo quy tắc %1. Hãy kiểm tra tùy chỉnh quy tắc.';
							|ru = 'Ошибка при расчете данных по правилу %1. Проверьте настройки правила.';
							|en = 'An error occurred when calculating data according to the %1 rule. Check the rule settings.'; fa = 'An error occurred when calculating data according to the %1 rule. Check the rule settings.';
							|it = 'An error occurred when calculating data according to the %1 rule. Check the rule settings.';
							|pl = 'An error occurred when calculating data according to the %1 rule. Check the rule settings.';
							|tr = '%1 kuralına göre veriler hesaplanırken hata oluştu. Kural ayarlarını kontrol edin.'");
			Raise StringFunctionsClientServer.SubstituteParametersToString(ErrorText, CalculationRule);
		EndTry;
		
	EndDo;
	
	Return TableOfBalancesAndTurnover;
	
EndFunction

Function BudgetFlowItemSettings(ArticlesIndicatorsOfCalculationRules)
	
	SettingsTable = New ValueTable;
	For Each Field In DataCompositionSchema.DataSets.BudgetFlowItemSettings.Fields Do
		SettingsTable.Columns.Add(Field.Field, Field.ValueType, Field.Title);
	EndDo;
	
	MaximumNumberOfAnalysts = BudgetingClientServer.MaximumNumberOfAnalysts();
	
	For Each ItemIndicator In ArticlesIndicatorsOfCalculationRules Do
		NewRow = SettingsTable.Add();
		NewRow.BudgetFlowItem = ItemIndicator;
		MaximumNumberOfAnalytics = 0;
		DimensionKinds = BudgetingServer.DimensionKinds(ItemIndicator);
		For DimensionNumber = 1 To MaximumNumberOfAnalysts Do
			DimensionKind = DimensionKinds[StringFunctionsClientServer.SubstituteParametersToString("DimensionKind%1",
				DimensionNumber)];
			If ValueIsFilled(DimensionKind) Then
				MaximumNumberOfAnalytics = DimensionNumber;
				PresentationOfAnalyticsView = BudgetReportingServerCall.PresentationOfAnalyticsView(DimensionKind);
				NewRow[StringFunctionsClientServer.SubstituteParametersToString("PresentationOfAnalyticsView%1",
					DimensionNumber)] = PresentationOfAnalyticsView;
				PresentationOfOtherAnalytics = BudgetReportingClientServer.PresentationOfOtherBudgetingAnalytics(
					DimensionKind, "OtherItems");
				NewRow[StringFunctionsClientServer.SubstituteParametersToString("PresentationOfOtherAnalytics%1",
					DimensionNumber)] = PresentationOfOtherAnalytics;
			EndIf;
		EndDo;
		NewRow.MaximumNumberOfAnalytics = MaximumNumberOfAnalytics;
	EndDo;
	
	Return SettingsTable;
	
EndFunction

#EndRegion

#EndRegion

#EndIf
