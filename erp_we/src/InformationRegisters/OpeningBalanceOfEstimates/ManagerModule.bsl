
#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

#Region InterfaceImplementation

// StandardSubsystems.AccessManagement

// Parameters:
//  Restriction - See AccessManagementOverridable.OnFillAccessRestriction.Restriction.
//
Procedure OnFillAccessRestriction(Restriction) Export

	Restriction.Text =
	"AllowReadUpdate
	|WHERE
	|	( Scenario = VALUE(Catalog.BudgetingScenarios.EmptyRef)
	|	OR ValueAllowed(Scenario)
	|	) AND ( Organization = VALUE(Catalog.Companies.EmptyRef)
	|	OR ValueAllowed(Organization)
	|	) AND ( Department = VALUE(Catalog.BusinessStructure.EmptyRef)
	|	OR ValueAllowed(Department)
	|	) AND ValueAllowed(BudgetBalanceItem)";

EndProcedure

// End StandardSubsystems.AccessManagement

#EndRegion

#EndRegion

#Region Internal

Function QueryTextsCurrentBalanceDatesByScenario(SelectionSet, DataLayoutSelectionIsSet, BalancesForSpecificDate) Export
	
	QueriesTexts = New Array;
	QueryText = 
	"SELECT ALLOWED
	|	BudgetingScenarios.Ref AS Scenario
	|INTO BudgetingScenarios
	|{SELECT
	|	Scenario.*}
	|FROM
	|	Catalog.BudgetingScenarios AS BudgetingScenarios
	|WHERE
	|	BudgetingScenarios.Ref <> VALUE(Catalog.BudgetingScenarios.ActualData)
	|	AND NOT BudgetingScenarios.IsFolder
	|	AND &ConditionScenario";
	ConditionText = "";
	If SelectionSet Then
		ConditionText = "BudgetingScenarios.Ref = &Scenario"; // @query-part
	EndIf;
	If DataLayoutSelectionIsSet Then
		ConditionText = ?(ConditionText = "", "TRUE", ConditionText + Chars.LF + Chars.Tab) + 
		"{WHERE
		|	BudgetingScenarios.Ref.* AS Scenario}"; // @query-part
	EndIf;
	If Not IsBlankString(ConditionText) Then
		QueryText = StrReplace(QueryText, "&ConditionScenario", ConditionText);
	EndIf;
	QueriesTexts.Add(QueryText);
	
	If BalancesForSpecificDate Then
		QueryText = 
		"SELECT ALLOWED
		|	OpeningBalanceOfEstimates.BudgetBalanceItem AS BudgetBalanceItem,
		|	OpeningBalanceOfEstimates.DateOfRemainingGoods AS DateOfRemainingGoods
		|INTO CurrentBalanceDates
		|FROM
		|	InformationRegister.OpeningBalanceOfEstimates AS OpeningBalanceOfEstimates
		|WHERE
		|	OpeningBalanceOfEstimates.DateOfRemainingGoods = &StartingDateOfBalances
		|	AND &ConditionIndicatorOfBudgets
		|
		|INDEX BY
		|	DateOfRemainingGoods,
		|	BudgetBalanceItem";
	Else
		QueryText = 
		"SELECT ALLOWED
		|	OpeningBalanceOfEstimates.BudgetBalanceItem AS BudgetBalanceItem,
		|	MAX(OpeningBalanceOfEstimates.DateOfRemainingGoods) AS DateOfRemainingGoods
		|INTO CurrentBalanceDates
		|FROM
		|	InformationRegister.OpeningBalanceOfEstimates AS OpeningBalanceOfEstimates
		|WHERE
		|	OpeningBalanceOfEstimates.DateOfRemainingGoods BETWEEN &StartingDateOfBalances AND &EndDateOfBalances
		|	AND &ConditionIndicatorOfBudgets
		|
		|GROUP BY
		|	OpeningBalanceOfEstimates.BudgetBalanceItem
		|
		|INDEX BY
		|	DateOfRemainingGoods,
		|	BudgetBalanceItem";
	EndIf;
	ConditionText = "";
	If SelectionSet Then
		ConditionText = "OpeningBalanceOfEstimates.BudgetBalanceItem = &BudgetBalanceItem"; // @query-part
	EndIf;
	If DataLayoutSelectionIsSet Then
		ConditionText = ?(ConditionText = "", "TRUE", ConditionText + Chars.LF + Chars.Tab) + 
		"{WHERE
		|	OpeningBalanceOfEstimates.BudgetBalanceItem.* AS BudgetBalanceItem}"; // @query-part
	EndIf;
	If Not IsBlankString(ConditionText) Then
		QueryText = StrReplace(QueryText, "&ConditionIndicatorOfBudgets", ConditionText);
	EndIf;
	QueriesTexts.Add(QueryText);
	
	QueryText = 
	"SELECT DISTINCT
	|	OpeningBalanceOfEstimates.BudgetBalanceItem AS BudgetBalanceItem,
	|	OpeningBalanceOfEstimates.Scenario AS Scenario,
	|	OpeningBalanceOfEstimates.DateOfRemainingGoods AS DateOfRemainingGoods
	|INTO CurrentBalanceDatesByScenario
	|FROM
	|	InformationRegister.OpeningBalanceOfEstimates AS OpeningBalanceOfEstimates
	|WHERE
	|	&ConditionByBalanceDate
	|	AND TRUE IN
	|			(SELECT TOP 1
	|				TRUE
	|			FROM
	|				CurrentBalanceDates
	|			WHERE
	|				CurrentBalanceDates.DateOfRemainingGoods = OpeningBalanceOfEstimates.DateOfRemainingGoods
	|				AND CurrentBalanceDates.BudgetBalanceItem = OpeningBalanceOfEstimates.BudgetBalanceItem)
	|	AND TRUE IN
	|			(SELECT TOP 1
	|				TRUE
	|			FROM
	|				BudgetingScenarios
	|			WHERE
	|				OpeningBalanceOfEstimates.Scenario = BudgetingScenarios.Scenario)
	|
	|INDEX BY
	|	DateOfRemainingGoods,
	|	BudgetBalanceItem,
	|	Scenario";
	If BalancesForSpecificDate Then
		QueryText = StrReplace(QueryText, "&ConditionByBalanceDate", "OpeningBalanceOfEstimates.DateOfRemainingGoods = &StartingDateOfBalances");
	Else
		QueryText = StrReplace(QueryText, "&ConditionByBalanceDate", "TRUE");
	EndIf;
	QueriesTexts.Add(QueryText);
	
	Return QueriesTexts;
	
EndFunction

Procedure GenerateTemporaryTables_ActualOpeningBalancesOfCalculatedIndicators(TempTablesManager, Parameters) Export
	
	QueriesTexts = QueryTextsCurrentBalanceDatesByScenario(Parameters.SelectionSet,
		Parameters.DataLayoutSelectionIsSet, Parameters.BalancesForSpecificDate);
	
	ArrayOfSubqueries = New Array;
	QueryText = 
	"SELECT
	|	OpeningBalanceOfEstimates.BudgetBalanceItem AS BudgetBalanceItem,
	|	OpeningBalanceOfEstimates.Scenario AS Scenario,
	|	&TextOfOrganizationField,
	|	&TextOfDivisionField,
	|	&TextOfDimensionsFields,
	|	OpeningBalanceOfEstimates.Currency AS Currency,
	|	CASE
	|		WHEN OpeningBalanceOfEstimates.Currency <> VALUE(Catalog.Currencies.EmptyRef)
	|			THEN OpeningBalanceOfEstimates.Currency
	|		ELSE &CurrencyOfMan
	|	END AS StorageCurrency,
	|	OpeningBalanceOfEstimates.Count AS Count,
	|	OpeningBalanceOfEstimates.AmountInCurrency AS AmountInCurrency,
	|	CASE
	|		WHEN OpeningBalanceOfEstimates.Currency <> VALUE(Catalog.Currencies.EmptyRef)
	|			THEN OpeningBalanceOfEstimates.AmountInCurrency
	|		ELSE OpeningBalanceOfEstimates.SumMan
	|	END AS AmountInStorageCurrency,
	|	OpeningBalanceOfEstimates.SumMan AS SumMan,
	|	OpeningBalanceOfEstimates.SumCompl AS SumCompl,
	|	CASE
	|		WHEN &FunctionalCurrency = VALUE(Enum.AccountingKindsInFunctionalCurrency.InCurrencyOfLocal)
	|			THEN OpeningBalanceOfEstimates.SumCompl
	|		WHEN &FunctionalCurrency = VALUE(Enum.AccountingKindsInFunctionalCurrency.InManagementAccountingCurrency_)
	|			THEN OpeningBalanceOfEstimates.SumMan
	|		ELSE 0
	|	END AS AmountInFunctionalCurrency,
	|	0 AS Sum,
	|	&RatePeriod AS RatePeriod
	|INTO BalancesAccordingToCalculatedIndicators
	|FROM
	|	InformationRegister.OpeningBalanceOfEstimates AS OpeningBalanceOfEstimates
	|WHERE
	|	&ConditionByBalanceDate
	|	AND TRUE IN
	|			(SELECT TOP 1
	|				TRUE
	|			FROM
	|				CurrentBalanceDatesByScenario
	|			WHERE
	|				OpeningBalanceOfEstimates.DateOfRemainingGoods = CurrentBalanceDatesByScenario.DateOfRemainingGoods
	|				AND OpeningBalanceOfEstimates.BudgetBalanceItem = CurrentBalanceDatesByScenario.BudgetBalanceItem
	|				AND OpeningBalanceOfEstimates.Scenario = CurrentBalanceDatesByScenario.Scenario)";
	ArrayOfSubqueries.Add(QueryText);
	
	QueryText = 
	"SELECT
	|	OpeningBalanceOfEstimates.BudgetBalanceItem,
	|	BudgetingScenarios.Scenario,
	|	&TextOfOrganizationField,
	|	&TextOfDivisionField,
	|	&TextOfDimensionsFields,
	|	OpeningBalanceOfEstimates.Currency,
	|	CASE
	|		WHEN OpeningBalanceOfEstimates.Currency <> VALUE(Catalog.Currencies.EmptyRef)
	|			THEN OpeningBalanceOfEstimates.Currency
	|		ELSE &CurrencyOfMan
	|	END,
	|	OpeningBalanceOfEstimates.Count,
	|	OpeningBalanceOfEstimates.AmountInCurrency,
	|	CASE
	|		WHEN OpeningBalanceOfEstimates.Currency <> VALUE(Catalog.Currencies.EmptyRef)
	|			THEN OpeningBalanceOfEstimates.AmountInCurrency
	|		ELSE OpeningBalanceOfEstimates.SumMan
	|	END,
	|	OpeningBalanceOfEstimates.SumMan,
	|	OpeningBalanceOfEstimates.SumCompl,
	|	CASE
	|		WHEN &FunctionalCurrency = VALUE(Enum.AccountingKindsInFunctionalCurrency.InCurrencyOfLocal)
	|			THEN OpeningBalanceOfEstimates.SumCompl
	|		WHEN &FunctionalCurrency = VALUE(Enum.AccountingKindsInFunctionalCurrency.InManagementAccountingCurrency_)
	|			THEN OpeningBalanceOfEstimates.SumMan
	|		ELSE 0
	|	END,
	|	0,
	|	&RatePeriod
	|FROM
	|	InformationRegister.OpeningBalanceOfEstimates AS OpeningBalanceOfEstimates
	|		LEFT JOIN BudgetingScenarios AS BudgetingScenarios
	|		ON (BudgetingScenarios.Scenario <> VALUE(Catalog.BudgetingScenarios.BudgetFulfillment))
	|WHERE
	|	&ConditionByBalanceDate
	|	AND TRUE IN
	|			(SELECT TOP 1
	|				TRUE
	|			FROM
	|				CurrentBalanceDates
	|			WHERE
	|				OpeningBalanceOfEstimates.DateOfRemainingGoods = CurrentBalanceDates.DateOfRemainingGoods
	|				AND OpeningBalanceOfEstimates.BudgetBalanceItem = CurrentBalanceDates.BudgetBalanceItem)
	|	AND NOT TRUE IN
	|				(SELECT TOP 1
	|					TRUE
	|				FROM
	|					CurrentBalanceDatesByScenario
	|				WHERE
	|					OpeningBalanceOfEstimates.DateOfRemainingGoods = CurrentBalanceDatesByScenario.DateOfRemainingGoods
	|					AND OpeningBalanceOfEstimates.BudgetBalanceItem = CurrentBalanceDatesByScenario.BudgetBalanceItem
	|					AND CurrentBalanceDatesByScenario.Scenario = BudgetingScenarios.Scenario)
	|	AND OpeningBalanceOfEstimates.Scenario = VALUE(Catalog.BudgetingScenarios.EmptyRef)";
	ArrayOfSubqueries.Add(QueryText);
	
	QueryText = StrConcat(ArrayOfSubqueries, TMCommonUse.QuerySeparatorInJoin());
	If Parameters.ByCompanies Then
		QueryText = StrReplace(QueryText, "&TextOfOrganizationField",
			"OpeningBalanceOfEstimates.Organization AS Organization");
	Else
		QueryText = StrReplace(QueryText, "&TextOfOrganizationField,", "");
	EndIf;
	
	If Parameters.ByBusinessUnits Then
		QueryText = StrReplace(QueryText, "&TextOfDivisionField",
			"OpeningBalanceOfEstimates.Department AS Department");
	Else
		QueryText = StrReplace(QueryText, "&TextOfDivisionField,", "");
	EndIf;
	If Parameters.BalancesForSpecificDate Then
		QueryText = StrReplace(QueryText, "&ConditionByBalanceDate", "OpeningBalanceOfEstimates.DateOfRemainingGoods = &StartingDateOfBalances");
	Else
		QueryText = StrReplace(QueryText, "&ConditionByBalanceDate", "TRUE");
	EndIf;
	MaximumNumberOfAnalysts = BudgetingClientServer.MaximumNumberOfAnalysts();
	ArrayOfAnalystFields = New Array;
	For DimensionNumber = 1 To MaximumNumberOfAnalysts Do
		ArrayOfAnalystFields.Add(StringFunctionsClientServer.SubstituteParametersToString(
			"OpeningBalanceOfEstimates.Dimension%1 AS Dimension%1", DimensionNumber));
	EndDo;
	QueryText = StrReplace(QueryText, "&TextOfDimensionsFields", StrConcat(ArrayOfAnalystFields, "," + Chars.LF
		+ Chars.Tab));
	QueriesTexts.Add(QueryText);
	
	QueryText = StrConcat(QueriesTexts, Common.QueryBatchSeparator());
	
	If Parameters.SelectionSet Then
		
		Query = New Query;
		Query.Text = QueryText;
		
	Else
		
		QueryText = StrReplace(QueryText, "INTO BalancesAccordingToCalculatedIndicators", ""); //@query-part
		DataCompositionSchema = DataCompositionServer.DataCompositionSchemaForQueryText(QueryText);
	
		Settings = New DataCompositionSettings;
		DataCompositionClientServer.AddGrouping(Settings);
		DataCompositionClientServer.AddSelectedField(Settings, "BudgetBalanceItem");
		DataCompositionClientServer.AddSelectedField(Settings, "Scenario");
		DataCompositionClientServer.AddSelectedField(Settings, "Organization");
		DataCompositionClientServer.AddSelectedField(Settings, "Department");
		For DimensionNumber = 1 To MaximumNumberOfAnalysts Do
			DataCompositionClientServer.AddSelectedField(Settings,
				StringFunctionsClientServer.SubstituteParametersToString("Dimension%1", DimensionNumber));
		EndDo;
		DataCompositionClientServer.AddSelectedField(Settings, "Currency");
		DataCompositionClientServer.AddSelectedField(Settings, "StorageCurrency");
		DataCompositionClientServer.AddSelectedField(Settings, "Count");
		DataCompositionClientServer.AddSelectedField(Settings, "AmountInCurrency");
		DataCompositionClientServer.AddSelectedField(Settings, "AmountInStorageCurrency");
		DataCompositionClientServer.AddSelectedField(Settings, "AmountInFunctionalCurrency");
		DataCompositionClientServer.AddSelectedField(Settings, "SumMan");
		DataCompositionClientServer.AddSelectedField(Settings, "SumCompl");
		DataCompositionClientServer.AddSelectedField(Settings, "Sum");
		DataCompositionClientServer.AddSelectedField(Settings, "RatePeriod");
		DataCompositionClientServer.CopyDataCompositionFilter(DataCompositionSchema, Settings,
			Parameters.ReportSettings);
		Query = DataCompositionServer.GETRequestFromLayoutTemplate(DataCompositionServer.GetLayoutTemplate(
			DataCompositionSchema, Settings), DataCompositionSchema.DataSets[0].Name);
		Query.Text = StrReplace(Query.Text, "&RatePeriod AS RatePeriod", "&RatePeriod AS RatePeriod" + Chars.LF
			+ "INTO BalancesAccordingToCalculatedIndicators"); //@query-part
		
	EndIf;
	
	Query.TempTablesManager = TempTablesManager;
	
	Query.SetParameter("RatePeriod", Parameters.DateOfRemainingGoods);
	If Parameters.BalancesForSpecificDate Then
		Query.SetParameter("StartingDateOfBalances", Parameters.DateOfRemainingGoods);
	Else
		Query.SetParameter("StartingDateOfBalances", BegOfYear(Parameters.DateOfRemainingGoods-1));
		Query.SetParameter("EndDateOfBalances", BegOfDay(Parameters.DateOfRemainingGoods-1));
	EndIf;
	Query.SetParameter("ByCompanies", Parameters.ByCompanies);
	Query.SetParameter("ByBusinessUnits", Parameters.ByBusinessUnits);
	If Parameters.SelectionSet Then
		FilterElement = FinancialReportingServer.FindSelectionElement(Parameters.ReportSettings.Filter, "BudgetBalanceItem");
		Query.SetParameter("BudgetBalanceItem", FilterElement.RightValue);
		FilterElement = FinancialReportingServer.FindSelectionElement(Parameters.ReportSettings.Filter, "Scenario");
		Query.SetParameter("Scenario", FilterElement.RightValue);
	EndIf;
	Query.SetParameter("CurrencyOfMan", SettingsValueCached.ManagementAccountingCurrency());
	Query.SetParameter("FunctionalCurrency", Parameters.FunctionalCurrency);
	
	Query.Execute();
	
EndProcedure

#EndRegion

#EndIf
