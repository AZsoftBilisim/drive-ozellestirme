#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Returns the names of blocked details for the BSP details blocking mechanism.
// 
// Returns:
// 	Array of String - names of blocked Bank details:
//		* AttributeToLock - String - Name of the blocked account.
//
Function GetObjectAttributesToLock() Export
	
	Result = New Array;
	
	Result.Add("Periodicity");
	Result.Add("Currency");
	Result.Add("TheBaseCurrencyOfTheExchangeRates");
	
	Return Result;
	
EndFunction

// Returns the lowest of the passed frequency and script frequency
//
// Parameters:
//  BudgetingScenarios - Array of CatalogRef.BudgetingScenarios - scenarios for which it is required to compare the time fence.
//  Periodicity - EnumRef.Periodicity - The time fence with which you want to compare the time fence of scenarios.
//
// Returns:
// 	EnumRef.Periodicity - calculated periodicity.
//
Function BringPeriodicityToPeriodicityOfScenario(BudgetingScenarios, Periodicity) Export
	
	PeriodicityOfScenarios = Common.ObjectsAttributeValue(BudgetingScenarios, "Periodicity");
	PeriodicityInOrder = Enums.Periodicity.OrderedPeriodicities();
	
	PeriodicityOfScenarios_       = Enums.Periodicity.EmptyRef();
	ScenarioPeriodicityIndex = 0;
	For Each Item In PeriodicityOfScenarios Do
		IndexOf = PeriodicityInOrder.Find(Item.Value);
		If IndexOf > ScenarioPeriodicityIndex Then
			ScenarioPeriodicityIndex = IndexOf;
			PeriodicityOfScenarios_       = Item.Value;
		EndIf;
	EndDo;
	
	If Not ValueIsFilled(Periodicity) Then
		Periodicity = PeriodicityOfScenarios_;
	ElsIf ScenarioPeriodicityIndex > PeriodicityInOrder.Find(Periodicity) Then 
		Periodicity = PeriodicityOfScenarios_;
	EndIf;

	Return Periodicity;
	
EndFunction

// Returns the Query Text for getting the script course table
//
// Parameters:
//  TempTableName - String - the name of the temporary table (empty if you don't want to put it in a temporary table)
//
// Returns:
//  String - Query text
//
Function QueryTextScriptCourseTable(TempTableName = "") Export
	
	QueryText =
	"SELECT ALLOWED
	|	BudgetingScenarios.Ref AS Scenario,
	|	BudgetingScenarios.Ref AS RateScenario
	|INTO FilterByScenario
	|FROM
	|	Catalog.BudgetingScenarios AS BudgetingScenarios
	|WHERE
	|	&ScenarioCondition
	|	AND NOT BudgetingScenarios.UseExchangeRatesOfAnotherScenario
	|
	|UNION ALL
	|
	|SELECT
	|	BudgetingScenarios.Ref,
	|	BudgetingScenarios.RateScenario
	|FROM
	|	Catalog.BudgetingScenarios AS BudgetingScenarios
	|WHERE
	|	&ScenarioCondition
	|	AND BudgetingScenarios.UseExchangeRatesOfAnotherScenario
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED
	|	&BeginOfPeriod AS Period,
	|	ForecastedExchangeRatesOfScenarios.Currency AS Currency,
	|	FilterByScenario.Scenario AS Scenario,
	|	FilterByScenario.Scenario.TheBaseCurrencyOfTheExchangeRates AS BaseCurrency,
	|	CASE
	|		WHEN ForecastedExchangeRatesOfScenarios.CourseDenominator = 0
	|			THEN 0
	|		ELSE ForecastedExchangeRatesOfScenarios.CourseNumerator / ForecastedExchangeRatesOfScenarios.CourseDenominator
	|	END AS Rate
	|FROM
	|	InformationRegister.ForecastedExchangeRatesOfScenarios.SliceLast(
	|			&BeginOfPeriod,
	|			Scenario IN (SELECT DISTINCT Filter.RateScenario FROM FilterByScenario AS Filter)
	|			AND &ConditionByCurrency1
	|			) AS ForecastedExchangeRatesOfScenarios
	|		INNER JOIN FilterByScenario AS FilterByScenario
	|		ON ForecastedExchangeRatesOfScenarios.Scenario = FilterByScenario.RateScenario
	|
	|UNION
	|
	|SELECT
	|	ForecastedExchangeRatesOfScenarios.Period,
	|	ForecastedExchangeRatesOfScenarios.Currency,
	|	FilterByScenario.Scenario,
	|	FilterByScenario.Scenario.TheBaseCurrencyOfTheExchangeRates,
	|	CASE
	|		WHEN ForecastedExchangeRatesOfScenarios.CourseDenominator = 0
	|			THEN 0
	|		ELSE ForecastedExchangeRatesOfScenarios.CourseNumerator / ForecastedExchangeRatesOfScenarios.CourseDenominator
	|	END AS Rate
	|FROM
	|	FilterByScenario AS FilterByScenario
	|		INNER JOIN InformationRegister.ForecastedExchangeRatesOfScenarios AS ForecastedExchangeRatesOfScenarios
	|		ON (ForecastedExchangeRatesOfScenarios.Period BETWEEN &BeginOfPeriod AND &EndOfPeriod)
	|			AND (ForecastedExchangeRatesOfScenarios.Scenario = FilterByScenario.RateScenario)
	|			AND &ConditionByCurrency2";
	If Not IsBlankString(TempTableName) Then
		QueryText = RequestSchemes.SetRoomToTemporaryTable(QueryText, TempTableName, 1);
		QueryText = RequestSchemes.SetIndexingOfQueryFields(QueryText, "Scenario, Currency, Period", 1);
	EndIf;
	
	Return QueryText;
	
EndFunction

// Returns a table of forecast scenario rates for the selected period,
// supplemented with initial rates.
//
// Parameters:
//  Scenario 		 - Array - Spravochnike.Scenarios for which 
//								you need to get courses.
//  Currencies 			 - Array - Currencies for which you want to get a table of rates,
//								if not specified, then for all
//  StartDate 		 - Date - Course start date.
//  EndDate 	 - Date - End date of the course.
//
// Returns:
// 	ValueTable - table of courses:
//		* Scenario - CatalogRef.BudgetingScenarios - Scenario.
//      * Currency - CatalogRef.Currencies - Currency.
//      * BaseCurrency - CatalogRef.Currencies - The base currency of the exchange rates.
//		* Period - Date - The period of the exchange rate.
//		* Rate - Number - exchange rate.
//
Function ScenarioCourseTable(Scenario = Undefined, Currencies = Undefined, StartDate, EndDate) Export
	
	Query = New Query;
	QueryText = QueryTextScriptCourseTable();
	
	If Scenario = Undefined Then
		QueryText = StrReplace(QueryText, "&ScenarioCondition", "TRUE");
	Else
		QueryText = StrReplace(QueryText, "&ScenarioCondition", "BudgetingScenarios.Ref IN (&Scenario)");
	EndIf;
	If Currencies = Undefined Then
		QueryText = StrReplace(QueryText, "&ConditionByCurrency1", "TRUE");
		QueryText = StrReplace(QueryText, "&ConditionByCurrency2", "TRUE");
	Else
		QueryText = StrReplace(QueryText, "&ConditionByCurrency1", "Currency IN (&Currencies)");
		QueryText = StrReplace(QueryText, "&ConditionByCurrency2", "ForecastedExchangeRatesOfScenarios.Currency IN (&Currencies)");
	EndIf;
	Query.Text = QueryText;
	Query.SetParameter("Currencies", Currencies);
	
	Query.SetParameter("Scenario", Scenario);
	Query.SetParameter("BeginOfPeriod", StartDate);
	Query.SetParameter("EndOfPeriod", EndDate);
	
	Return Query.Execute().Unload();
	
EndFunction

// Returns a table containing information about unfilled script courses. 
//
// Parameters:
//  BudgetingScenarios - Array of CatalogRef.BudgetingScenarios - scenarios for which you need to check the completion of courses.
//  Currencies - Array of CatalogRef.Currencies - Currencies for which you need to check the exchange rate completion.
//  StartDate - Date - Start of the verification period.
//  EndDate - Date - End of the verification period.
//
// Returns:
// 	ValueTable - table of unfilled courses:
//		* Scenario - CatalogRef.BudgetingScenarios - Scenario.
//      * Currency - CatalogRef.Currencies - Currency.
//		* Period - Date - The period of the exchange rate.
//
Function CheckCompletionOfScriptCourses(BudgetingScenarios, Currencies, StartDate, EndDate) Export
	
	PeriodicityOfScenarios = Common.ObjectsAttributeValue(BudgetingScenarios, "Periodicity");
	ScriptCourses = Catalogs.BudgetingScenarios.ScenarioCourseTable(BudgetingScenarios, Currencies, StartDate, EndDate);
	ScriptCourses.Indexes.Add("Scenario, Currency, Period");
	
	UnfilledCourses = ScriptCourses.CopyColumns("Scenario, Currency, Period");
	
	For Each Scenario In BudgetingScenarios Do
		TimeIntervals = BudgetReportingDisplayServer.BudgetReportPeriods(StartDate, EndDate, PeriodicityOfScenarios[Scenario]);
		For Each Period In TimeIntervals Do
			For Each Currency In Currencies Do
				TheStructureOfTheSearch = New Structure("Scenario, Currency, Period", Scenario, Currency, Period);
				If ScriptCourses.FindRows(TheStructureOfTheSearch).Count() = 0 Then
					NewRow = UnfilledCourses.Add();
					FillPropertyValues(NewRow, TheStructureOfTheSearch);
				EndIf;
			EndDo;
		EndDo;
	EndDo;
	
	Return UnfilledCourses;
	
EndFunction

// Defines the configuration for the initial fill of elements
//
// Parameters:
//  Settings - Structure - filling settings:
//   * OnInitialItemFilling - Boolean - if True,
//      the individual filling procedure will be called for each element at the beginning of the element Filling.
Procedure OnSetUpInitialItemsFilling(Settings) Export
	
	Settings.OnInitialItemFilling = True;
	
EndProcedure

// Called when the directory is initially filled in.
//
// Parameters:
//  LanguagesCodes - Array - list of configuration languages. Relevant for multilingual configurations.
//  Items   - ValueTable - fill-in data. The composition of columns corresponds to the set
//                                 of reference book details.
//  TabularSections - Structure - Key - Name of the table part of the object.
//                               Value-Uploads an empty table part to the table of values.
//
Procedure OnInitialItemsFilling(LanguagesCodes, Items, TabularSections) Export

	DefaultLanguageCode = Common.DefaultLanguageCode();

	#Region BudgetFulfillment
	Item = Items.Add();
	Item.PredefinedDataName = "BudgetFulfillment";
	Item.Description = NStr("vi = 'Thực hiện ngân sách';
							|ru = 'Исполнение бюджета';
							|en = 'Budget implementation'; fa = 'اجرای بودجه';
							|it = 'Esecuzione del budget';
							|pl = 'Wykonanie budżetu';
							|tr = 'Bütçenin uygulanması'", DefaultLanguageCode);
	Item.Code = "00001";
	Item.TheBaseCurrencyOfTheExchangeRates = SettingsValueCached.DefaultBaseCurrency();
	#EndRegion

	#Region ActualData
	Item = Items.Add();
	Item.PredefinedDataName = "ActualData";
	Item.Description = NStr("vi = 'Dữ liệu thực tế';
							|ru = 'Фактические данные';
							|en = 'Actual data'; fa = 'داده‌های واقعی';
							|it = 'Dati effettivi';
							|pl = 'Dane faktyczne';
							|tr = 'Gerçek veriler'", DefaultLanguageCode);
	Item.Code = "00002";
	Item.TheBaseCurrencyOfTheExchangeRates = SettingsValueCached.DefaultBaseCurrency();
	#EndRegion

EndProcedure

// Called when the element being created is initially filled in.
//
// Parameters:
//  Object                  - CatalogObject.BudgetingScenarios - the object to fill in.
//  Data                  - ValueTableRow - fill-in data.
//  AdditionalParameters - Structure - advanced setting.
//
Procedure OnInitialItemFilling(Object, Data, AdditionalParameters) Export
	
	
	
EndProcedure

#Region InterfaceImplementation

// StandardSubsystems.AccessManagement

// Parameters:
//   Restriction - See AccessManagementOverridable.OnFillAccessRestriction.Restriction.
//
Procedure OnFillAccessRestriction(Restriction) Export

	Restriction.Text =
	"AllowReadUpdate
	|WHERE
	|	IsFolder OR
	|	ValueAllowed(Ref)";

EndProcedure

// End StandardSubsystems.AccessManagement

#EndRegion

#EndRegion

#EndIf

#Region EventHandlers

Procedure ChoiceDataGetProcessing(ChoiceData, Parameters, StandardProcessing)
	
	BudgetReportingServerCall.ScenariosWithFilter(ChoiceData, Parameters, StandardProcessing);
	
EndProcedure

#EndRegion
