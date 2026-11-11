////////////////////////////////////////////////////////////////////////////////
// The module "Provision in documents (Server)" contains procedures and functions
// that serve the operation of the mechanism for reserving and ensuring the needs for documents on the server.
//
////////////////////////////////////////////////////////////////////////////////
//

#Region Public

#Region CalculationOfDatesBySupplyMethod

// Prepares the Query Text of the temp table containing the cumulative value of the number of working days for 
// the year of the enterprise schedule.
//
// Returns:
// String - query text.
Function TempTableYearsOfEnterpriseSchedule() Export
	
	Texts = New ValueList();
	AddTemporaryTablesYearsOfEnterpriseSchedule(Texts);
	Text = StrConcat(Texts.UnloadValues(), Common.QueryBatchSeparator());
	Return Text;
	
EndFunction

// Prepares the Query Text of a temporary table containing the cumulative value of the number of working days for 
// the year of the enterprise schedule. Adds the received text to the list of values.
// Parameters:
//  Texts - ValueList of String - the collection.
Procedure AddTemporaryTablesYearsOfEnterpriseSchedule(Texts) Export
	
	Texts.Add(
		"SELECT
		|	CalendarSchedules.Year AS Year,
		|	MAX(CalendarSchedules.DaysCountInScheduleSinceBegOfYear) DaysCount
		|INTO YearsOfEnterpriseScheduleTemporary
		|FROM
		|	InformationRegister.CalendarSchedules AS CalendarSchedules
		|		INNER JOIN Constant.MainEnterpriseCalendar AS EnterpriseCalendar
		|		ON EnterpriseCalendar.Value = CalendarSchedules.Calendar
		|GROUP BY
		|	CalendarSchedules.Year
		|INDEX BY
		|	Year", "YearsOfEnterpriseScheduleTemporary");
		
	Texts.Add(
		"SELECT
		|	Years.Year AS Year,
		|	SUM(ISNULL(PreviousYears.DaysCount, 0)) AS OpeningBalance,
		|	SUM(ISNULL(PreviousYears.DaysCount, 0)) + MAX(Years.DaysCount) AS ClosingBalance
		|INTO YearsOfEnterpriseSchedule
		|FROM
		|	YearsOfEnterpriseScheduleTemporary AS Years
		|		LEFT JOIN YearsOfEnterpriseScheduleTemporary AS PreviousYears
		|		ON PreviousYears.Year < Years.Year
		|GROUP BY
		|	Years.Year
		|INDEX BY
		|	Year", "YearsOfEnterpriseSchedule");
	
EndProcedure

// Used to include information about the main method of providing items in a warehouse in an arbitrary request. 
// 
// Parameters:
//  Products - String - Expression of the field of the master table associated with the item for which it is necessary to obtain the provision method. 
//  Characteristic - String - Expression of the field of the master table associated with the characteristic for which it is necessary to obtain a provision method.
//  Warehouse - String - Expression of the field of the master table associated with the warehouse for which it is necessary to obtain a method of provision.
//  GettingCondition - String - An expression of the query language, if it is true, you need to get data about the provision method.
// 
// Returns:
//  Structure - Sodezhrzhit fields:
//  * Field - String - An expression for substitution into the Query Text, which allows you to get a way to provide for writing the master table.
//  * Joins - String - Expression, for substitution in the Query Text as the necessary left connections to the master table.
Function SubstitutionsOfMainMethodOfProviding(Products, Characteristic, Warehouse, GettingCondition) Export
	
	QueryText =
		"SELECT
		|	CASE WHEN LeadingTable.Products.ItemsType = VALUE(Enum.ItemsTypes.Work_5) THEN
		|			
		|			ISNULL(WorksProcurementStrategy.ProcurementStrategy,
		|				LeadingTable.Products.ProcurementStrategy)
		|			
		|			ELSE
		|				ISNULL(GoodsProcurementStrategy.ProcurementStrategy,
		|					ISNULL(WarehouseSupportSchemes.ProcurementStrategy,
		|						ISNULL(SchemesForProvidingFormats.ProcurementStrategy,
		|						VALUE(Catalog.ProcurementStrategies.EmptyRef))))
		|		END AS MethodOfEnsuringIsReOperable
		|FROM
		|	LeadingTableIsRepurposed AS LeadingTable
		|		
		|		LEFT JOIN InformationRegister.WorksProcurementStrategy AS WorksProcurementStrategy
		|		ON (LeadingTable.GettingCondition)
		|			AND (WorksProcurementStrategy.Products = LeadingTable.Products)
		|			AND (WorksProcurementStrategy.Characteristic = LeadingTable.Characteristic)
		|			AND (WorksProcurementStrategy.AddlOrderingAttribute = 1)
		|		LEFT JOIN InformationRegister.GoodsProcurementStrategy AS GoodsProcurementStrategy
		|		ON (LeadingTable.GettingCondition)
		|			AND (GoodsProcurementStrategy.Products = LeadingTable.Products)
		|			AND (GoodsProcurementStrategy.Characteristic = LeadingTable.Characteristic)
		|			AND (GoodsProcurementStrategy.Warehouse = LeadingTable.Warehouse)
		|			AND (GoodsProcurementStrategy.AddlOrderingAttribute = 1)
		|		LEFT JOIN Catalog.Products AS AllProducts
		|		ON (LeadingTable.GettingCondition)
		|			AND (AllProducts.Ref = LeadingTable.Products)
		|			AND (AllProducts.SupplyScheme <> VALUE(Catalog.SupplySchemes.EmptyRef))
		|		LEFT JOIN InformationRegister.SupplySchemes AS WarehouseSupportSchemes
		|		ON (LeadingTable.GettingCondition)
		|			AND (WarehouseSupportSchemes.SupplyScheme = AllProducts.SupplyScheme)
		|			AND (WarehouseSupportSchemes.Warehouse = LeadingTable.Warehouse)
		|		LEFT JOIN InformationRegister.HistoryOfStoreFormatChange.SliceLast(, ) AS StoreFormats_
		|		ON (LeadingTable.GettingCondition)
		|			AND (StoreFormats_.Warehouse = LeadingTable.Warehouse)
		|		LEFT JOIN InformationRegister.SupplySchemes AS SchemesForProvidingFormats
		|		ON (LeadingTable.GettingCondition)
		|			AND (SchemesForProvidingFormats.SupplyScheme = AllProducts.SupplyScheme)
		|			AND (SchemesForProvidingFormats.Warehouse = StoreFormats_.StoreFormat)";
		
		Field = QueryText;
		
		SELECTText = "SELECT"; // @query-part-1
		SearchExpression = "\s*" + SELECTText + "\s+[^\s]";
		
		SearchResult = StrFindByRegularExpression(
			Field,
			SearchExpression,
			SearchDirection.FromBegin,
			1,
			1,
			True);
		Field = Mid(Field, SearchResult.StartIndex + SearchResult.Length - 1);
		
		TextAs = "AS"; // @query-part-1
		TextOfFieldName = "MethodOfEnsuringIsReOperable";
		SearchExpression = "[^\s]\s+" + TextAs + "\s+" + TextOfFieldName + "\s";
		
		SearchResult = StrFindByRegularExpression(
			Field,
			SearchExpression,
			SearchDirection.FromBegin,
			1,
			1,
			True);
		Field = Left(Field, SearchResult.StartIndex + 1);
		
		Joins = QueryText;
		
		TextLeftConnection = "LEFT JOIN"; // @query-part-1
		TextLeftConnection = StrReplace(TextLeftConnection, " ", "\s+");
		SearchExpression = "\s" + TextLeftConnection + "\s";
		
		SearchResult = StrFindByRegularExpression(
			Joins,
			SearchExpression,
			SearchDirection.FromBegin,
			1,
			1,
			True);
		Joins = Mid(Joins, SearchResult.StartIndex + 1);
		
		Substitutions_3 = New Array();
		SearchString = "LeadingTable.Products";
		Substitutions_3.Add(New Structure("SearchString,ReplacementString", SearchString, Products));
		SearchString = "LeadingTable.Characteristic";
		Substitutions_3.Add(New Structure("SearchString,ReplacementString", SearchString, Characteristic));
		SearchString = "LeadingTable.Warehouse";
		Substitutions_3.Add(New Structure("SearchString,ReplacementString", SearchString, Warehouse));
		SearchString = "LeadingTable.GettingCondition";
		Substitutions_3.Add(New Structure("SearchString,ReplacementString", SearchString, GettingCondition));
		
		For IndexOf = 0 To Substitutions_3.Count() - 1 Do
			Field = StrReplace(Field, Substitutions_3[IndexOf].SearchString, Substitutions_3[IndexOf].ReplacementString);
			Joins = StrReplace(Joins, Substitutions_3[IndexOf].SearchString, Substitutions_3[IndexOf].ReplacementString);
		EndDo;
		
	Return New Structure("Field,Joins", Field, Joins);
	
EndFunction

// It is used to include in an arbitrary request information about the planned date of provision of the need for the method of provision.
// Security method parameters: 
// - The deadline for the execution of the order - days, abbreviated delivery time 
// - "By order point" - flag
// - "On schedule" - flag
// Switch
//  - "According to the delivery schedule":
//    - Delivery schedule
//  - "On schedule":
//    - The first date in the schedule is the date in the interface field "Start with".
//    - Periodicity - day, week, month, quarter, half-year, year
//    - Number of periods - a number greater than 0
//
// Calculation of the date of provision of needs:
// 
// Intermediate calculation 1. Date of access to the delivery time:
//
// The company calendar is not used or the delivery time is 0 (by the method of provision or the method is not specified).
// = current date + Delivery time
// Enterprise calendar - used, delivery time - not 0.
// = current date + Delivery time in the working days of the enterprise calendar
//
// The final calculation. Scheduled Delivery date:
//
// 1. The security method is not used:
// = current date
//
// 2. Method of provision: only "At the point of order".
// = Date of access to the delivery process
// = empty date, exception: The schedule of the enterprise is used, but not filled in for a non-zero deadline for the execution of the order
//
// 3. The way of providing: "At the point of order" Or "On schedule", or only "On schedule"
//
// Nearest delivery.
//
// Schedule: "According to the delivery schedule"
//
// Nearest Delivery:
// = Date of access to the delivery time, if it is working in the delivery calendar,
// = the nearest working date in the delivery calendar to the right of the date of access to the delivery time in the same or next year, otherwise
// = empty date, exception: The company's schedule is used, but not filled in for a non-zero delivery time
// = empty date, exception: the delivery schedule is not filled to the depth of the date of access to the delivery time
//
// Schedule: "Using periodicity and number of periods"
//
// Nearest delivery:
// = The first date in the schedule, if it is later or equal to the date of access to the delivery time
// = The first date in the schedule + The number of full periods before the date of access to the delivery date, inclusive * The duration of one period, otherwise
// = an empty date, except when the provision method is configured incorrectly: The number of periods is 0 or the Periodicity is not filled in
// = empty date, exception: The company's schedule is used, but not filled in for a non-zero delivery time
//  
// Calculation of the number of full periods:
// If the periodicity is a month, quarter, half-year, year, then:
//   - We find the date closest to the left of the date of access to the order of delivery and spaced from the First date according to the schedule for an even number of months, we fix the found Number of months before this date.
//   - Next, we divide the fully found Number of months by the number of months in one full period, according to the settings of the provision method (Periodicity and Number of periods of this periodicity).
//   - Next, we increase the found Number of full periods by one to be to the right of the date of access to the order of delivery.
// 
// The calculated date of provision of needs is extended by the quality control period calculated according to the work schedule of the enterprise, if quality control of the received item is enabled for the item in the warehouse.
// 
// Parameters:
//  SupplyMethod - String - Expression of the field of the master table associated with the way needs are met. 
//  BeginningOfThisDay - String - Expression of the field of the master table or parameter associated with the date value of the Cur day for counting days until the scheduled delivery date.
//  Products - String - Expression, fields of the leading table, or parameter associated with the value of the item, if you need to add a quality control period.
//  Warehouse - String - Expression, fields of the master table, or parameter associated with the warehouse value, if you need to add a quality control period.
// 
// Returns:
//  Structure - Contains fields:
//  * Field - String - An expression to be inserted into the Query Text that allows you to get the planned delivery date for the collateral method.
//  * Joins - String - Expression, for substitution in the Query Text as the necessary left connections to the master table.
//  * DeliveryDateFieldAtOrderPoint - String - An expression to insert into the request text that allows you to get the planned delivery date at the order point.
Function SubstitutionsOfPlannedDeliveryDate(SupplyMethod, BeginningOfThisDay, Products = "", Warehouse = "") Export
	
	QueryText =
		"SELECT
		|	ISNULL(
		|		CASE
// Boundary case - the calendar is not filled.
		|			WHEN &OrderDueDate IS NULL
		|				
		|				THEN NULL
		|				
		|			WHEN SupplyMethodOverridable.GenerateOrdersOnSchedule
		|				
		|				THEN
		|					
		|					CASE
		|						
// The schedule is set manually according to the calendar: Delivery schedule.
		|						WHEN SupplyMethodOverridable.DeliverySchedule <> VALUE(Catalog.Calendars.EmptyRef)
		|							
		|							THEN
		|								CASE
		|									WHEN EnterpriseCalendar.Value = VALUE(Catalog.Calendars.EmptyRef)
		|											OR &OrderExecutionTimeInDays = 0
		|										THEN
		|											CASE
		|											WHEN DeliveryScheduleOrderDueDateWithoutCalendar.DayAddedToSchedule
		|												THEN DeliveryScheduleOrderDueDateWithoutCalendar.ScheduleDate
		|											WHEN NOT DeliveryScheduleOrderDueDatePlusOneDayDateWithoutCalendar.ScheduleDate IS NULL
		|												THEN DeliveryScheduleOrderDueDatePlusOneDayDateWithoutCalendar.ScheduleDate
		|											ELSE DeliveryScheduleOrderDueDateFirstDayOfNextYearWithoutCalendar.ScheduleDate
		|										END
		|									ELSE
		|										CASE
		|											WHEN DeliveryScheduleOrderDueDate.DayAddedToSchedule
		|												THEN DeliveryScheduleOrderDueDate.ScheduleDate
		|											WHEN NOT DeliveryScheduleOrderDueDatePlusOneDayDate.ScheduleDate IS NULL
		|												THEN DeliveryScheduleOrderDueDatePlusOneDayDate.ScheduleDate
		|											ELSE DeliveryScheduleOrderDueDateFirstDayOfNextYear.ScheduleDate
		|										END
		|									END
// Boundary case - the provision method is not filled in correctly.
		|						WHEN SupplyMethodOverridable.NumberOfPeriodsBetweenDeliveries = 0
		|							
		|							THEN NULL
		|						
// The boundary case is the first delivery date in the schedule.
		|						WHEN SupplyMethodOverridable.FirstDateInDeliverySchedule >= &OrderDueDate
		|							
		|							THEN SupplyMethodOverridable.FirstDateInDeliverySchedule
		|							
// Schedule - Month, Quarter, Half-Year, Year. Calculation of the date according to the schedule.
		|						WHEN SupplyMethodOverridable.DeliveryScheduleFrequency IN(
		|								VALUE(Enum.ScheduleTimeFence.MONTH),
		|								VALUE(Enum.ScheduleTimeFence.QUARTER),
		|								VALUE(Enum.ScheduleTimeFence.HALFYEAR),
		|								VALUE(Enum.ScheduleTimeFence.YEAR))
		|							
		|							THEN
		|								
		|								DATEADD(
		|									SupplyMethodOverridable.FirstDateInDeliverySchedule,
		|									MONTH,
		|									SupplyMethodOverridable.NumberOfPeriodsBetweenDeliveries
		|										* CASE
		|											WHEN SupplyMethodOverridable.DeliveryScheduleFrequency
		|													= VALUE(Enum.ScheduleTimeFence.MONTH)
		|												THEN 1
		|											WHEN SupplyMethodOverridable.DeliveryScheduleFrequency
		|													= VALUE(Enum.ScheduleTimeFence.QUARTER)
		|												THEN 3
		|											WHEN SupplyMethodOverridable.DeliveryScheduleFrequency
		|													= VALUE(Enum.ScheduleTimeFence.HALFYEAR)
		|												THEN 6
		|											WHEN SupplyMethodOverridable.DeliveryScheduleFrequency
		|													= VALUE(Enum.ScheduleTimeFence.YEAR)
		|												THEN 12
		|										END
		|										* (1 + INT(
		|												(DATEDIFF(
		|														SupplyMethodOverridable.FirstDateInDeliverySchedule,
		|														&OrderDueDate,
		|														MONTH)
		|													- CASE
		|															WHEN
		|																DATEADD(
		|																	SupplyMethodOverridable.FirstDateInDeliverySchedule,
		|																	MONTH,
		|																	DATEDIFF(
		|																		SupplyMethodOverridable.FirstDateInDeliverySchedule,
		|																		&OrderDueDate,
		|																		MONTH)) >= &OrderDueDate
		|																THEN 1
		|														ELSE 0
		|													END
		|												)
		|												/ (SupplyMethodOverridable.NumberOfPeriodsBetweenDeliveries
		|													* CASE
		|														WHEN SupplyMethodOverridable.DeliveryScheduleFrequency
		|																= VALUE(Enum.ScheduleTimeFence.MONTH)
		|															THEN 1
		|														WHEN SupplyMethodOverridable.DeliveryScheduleFrequency
		|																= VALUE(Enum.ScheduleTimeFence.QUARTER)
		|															THEN 3
		|														WHEN SupplyMethodOverridable.DeliveryScheduleFrequency
		|																= VALUE(Enum.ScheduleTimeFence.HALFYEAR)
		|															THEN 6
		|														WHEN SupplyMethodOverridable.DeliveryScheduleFrequency
		|																= VALUE(Enum.ScheduleTimeFence.YEAR)
		|															THEN 12
		|													END)
		|												)
		|											)
		|								)
		|								
// Schedule - Day, Week. Calculation of the date according to the schedule.
		|						WHEN SupplyMethodOverridable.DeliveryScheduleFrequency IN(
		|								VALUE(Enum.ScheduleTimeFence.DAY),
		|								VALUE(Enum.ScheduleTimeFence.WEEK))
		|							
		|							THEN
		|								DATEADD(
		|									SupplyMethodOverridable.FirstDateInDeliverySchedule,
		|									DAY,
		|									SupplyMethodOverridable.NumberOfPeriodsBetweenDeliveries
		|									* CASE
		|										WHEN SupplyMethodOverridable.DeliveryScheduleFrequency
		|												= VALUE(Enum.ScheduleTimeFence.DAY)
		|											THEN 1
		|										WHEN SupplyMethodOverridable.DeliveryScheduleFrequency
		|												= VALUE(Enum.ScheduleTimeFence.WEEK)
		|											THEN 7
		|									END
		|									* (1 + INT(
		|												(DATEDIFF(
		|														SupplyMethodOverridable.FirstDateInDeliverySchedule,
		|														&OrderDueDate,
		|														DAY)
		|													- CASE
		|															WHEN
		|																DATEADD(
		|																	SupplyMethodOverridable.FirstDateInDeliverySchedule,
		|																	DAY,
		|																	DATEDIFF(
		|																		SupplyMethodOverridable.FirstDateInDeliverySchedule,
		|																		&OrderDueDate,
		|																		DAY)) >= &OrderDueDate
		|																THEN 1
		|														ELSE 0
		|													END)
		|													/ (SupplyMethodOverridable.NumberOfPeriodsBetweenDeliveries
		|														* CASE
		|															WHEN SupplyMethodOverridable.DeliveryScheduleFrequency
		|																	= VALUE(Enum.ScheduleTimeFence.DAY)
		|																THEN 1
		|															WHEN SupplyMethodOverridable.DeliveryScheduleFrequency
		|																	= VALUE(Enum.ScheduleTimeFence.WEEK)
		|																THEN 7
		|														END)
		|												)
		|										)
		|								)
		|								
// Boundary case - the provision method is not filled in correctly.
		|						ELSE NULL
		|						
		|					END
		|					
// Calculation of the date for the reorder point.
		|			ELSE &OrderDueDate
		|			
		|		END,
		|
// Value if the date cannot be calculated.
		|		DATETIME(1, 1, 1)
		|
		|	) AS PlannedDeliveryDateOverridable,
		|	ISNULL(&OrderDueDate, DATETIME(1, 1, 1)) AS DeliveryDateByReorderPointOverridable
		|FROM
		|	&LeadingTable AS LeadingTable
		|		
		|		LEFT JOIN Catalog.ProcurementStrategies AS SupplyMethodOverridable
		|		ON SupplyMethodOverridable.Ref = LeadingTable.SupplyMethod
		|		
		|		LEFT JOIN Constant.MainEnterpriseCalendar AS EnterpriseCalendar
		|		ON TRUE
		|		
		// Getting the date in the schedule for the due date of the order.
		|		LEFT JOIN YearsOfEnterpriseSchedule AS ThisDayIsYear
		|		ON ThisDayIsYear.Year = YEAR(LeadingTable.BeginningOfThisDay)
		|		
		|		LEFT JOIN InformationRegister.CalendarSchedules AS ThisDayIsDate
		|		ON ThisDayIsDate.Calendar = EnterpriseCalendar.Value
		|		AND ThisDayIsDate.Year = YEAR(LeadingTable.BeginningOfThisDay)
		|		AND ThisDayIsDate.ScheduleDate = LeadingTable.BeginningOfThisDay
		|		
		|		LEFT JOIN YearsOfEnterpriseSchedule AS OrderExecutionPeriodIsOneYear
		|		ON ThisDayIsYear.OpeningBalance
		|				+ ThisDayIsDate.DaysCountInScheduleSinceBegOfYear
		|				+ &OrderExecutionTimeInDays
		|			BETWEEN OrderExecutionPeriodIsOneYear.OpeningBalance + 1
		|				AND OrderExecutionPeriodIsOneYear.ClosingBalance
		|		
		|		LEFT JOIN InformationRegister.CalendarSchedules AS OrderDueDate
		|		ON OrderDueDate.Calendar = EnterpriseCalendar.Value
		|		AND OrderDueDate.Year = OrderExecutionPeriodIsOneYear.Year
		|		AND OrderDueDate.DayAddedToSchedule
		|		AND OrderDueDate.DaysCountInScheduleSinceBegOfYear
		|			= ThisDayIsYear.OpeningBalance
		|				+ ThisDayIsDate.DaysCountInScheduleSinceBegOfYear
		|				+ &OrderExecutionTimeInDays
		|				- OrderExecutionPeriodIsOneYear.OpeningBalance
		|		
		// Getting the date in the delivery schedule according to the schedule.
		|		LEFT JOIN InformationRegister.CalendarSchedules AS DeliveryScheduleOrderDueDate
		|		ON DeliveryScheduleOrderDueDate.Calendar = SupplyMethodOverridable.DeliverySchedule
		|		AND DeliveryScheduleOrderDueDate.Year = OrderExecutionPeriodIsOneYear.Year
		|		AND DeliveryScheduleOrderDueDate.ScheduleDate = OrderDueDate.ScheduleDate
		|		
		|		LEFT JOIN InformationRegister.CalendarSchedules AS DeliveryScheduleOrderDueDatePlusOneDayDate
		|		ON DeliveryScheduleOrderDueDatePlusOneDayDate.Calendar = SupplyMethodOverridable.DeliverySchedule
		|		AND DeliveryScheduleOrderDueDatePlusOneDayDate.DayAddedToSchedule
		|		AND DeliveryScheduleOrderDueDatePlusOneDayDate.Year = OrderExecutionPeriodIsOneYear.Year
		|		AND DeliveryScheduleOrderDueDatePlusOneDayDate.DaysCountInScheduleSinceBegOfYear
		|			= DeliveryScheduleOrderDueDate.DaysCountInScheduleSinceBegOfYear + 1
		|		
		|		LEFT JOIN InformationRegister.CalendarSchedules AS DeliveryScheduleOrderDueDateFirstDayOfNextYear
		|		ON DeliveryScheduleOrderDueDateFirstDayOfNextYear.Calendar = SupplyMethodOverridable.DeliverySchedule
		|		AND DeliveryScheduleOrderDueDateFirstDayOfNextYear.DayAddedToSchedule
		|		AND DeliveryScheduleOrderDueDateFirstDayOfNextYear.Year = YEAR(OrderDueDate.ScheduleDate) + 1
		|		AND DeliveryScheduleOrderDueDateFirstDayOfNextYear.DaysCountInScheduleSinceBegOfYear = 1
		|
		// Getting the date in the delivery schedule according to the schedule if the company's calendar is not filled in or the deadline is zero.
		|		LEFT JOIN InformationRegister.CalendarSchedules AS DeliveryScheduleOrderDueDateWithoutCalendar
		|		ON DeliveryScheduleOrderDueDateWithoutCalendar.Calendar = SupplyMethodOverridable.DeliverySchedule
		|		AND DeliveryScheduleOrderDueDateWithoutCalendar.Year = YEAR(
		|			DATEADD(LeadingTable.BeginningOfThisDay, DAY, &OrderExecutionTimeInDays))
		|		AND DeliveryScheduleOrderDueDateWithoutCalendar.ScheduleDate
		|			= DATEADD(LeadingTable.BeginningOfThisDay, DAY, &OrderExecutionTimeInDays)
		|		
		|		LEFT JOIN InformationRegister.CalendarSchedules AS DeliveryScheduleOrderDueDatePlusOneDayDateWithoutCalendar
		|		ON DeliveryScheduleOrderDueDatePlusOneDayDateWithoutCalendar.Calendar = SupplyMethodOverridable.DeliverySchedule
		|		AND DeliveryScheduleOrderDueDatePlusOneDayDateWithoutCalendar.DayAddedToSchedule
		|		AND DeliveryScheduleOrderDueDatePlusOneDayDateWithoutCalendar.Year = YEAR(
		|			DATEADD(LeadingTable.BeginningOfThisDay, DAY, &OrderExecutionTimeInDays))
		|		AND DeliveryScheduleOrderDueDatePlusOneDayDateWithoutCalendar.DaysCountInScheduleSinceBegOfYear
		|			= DeliveryScheduleOrderDueDateWithoutCalendar.DaysCountInScheduleSinceBegOfYear + 1
		|		
		|		LEFT JOIN InformationRegister.CalendarSchedules AS DeliveryScheduleOrderDueDateFirstDayOfNextYearWithoutCalendar
		|		ON DeliveryScheduleOrderDueDateFirstDayOfNextYearWithoutCalendar.Calendar = SupplyMethodOverridable.DeliverySchedule
		|		AND DeliveryScheduleOrderDueDateFirstDayOfNextYearWithoutCalendar.DayAddedToSchedule
		|		AND DeliveryScheduleOrderDueDateFirstDayOfNextYearWithoutCalendar.Year = YEAR(
		|			DATEADD(LeadingTable.BeginningOfThisDay, DAY, &OrderExecutionTimeInDays)) + 1
		|		AND DeliveryScheduleOrderDueDateFirstDayOfNextYearWithoutCalendar.DaysCountInScheduleSinceBegOfYear = 1";
	
	OrderDueDate =
		"CASE
		|	WHEN &OrderExecutionTimeInDays = 0
		|		THEN LeadingTable.BeginningOfThisDay
		|	WHEN EnterpriseCalendar.Value = VALUE(Catalog.Calendars.EmptyRef)
		|		THEN DATEADD(LeadingTable.BeginningOfThisDay, DAY, &OrderExecutionTimeInDays)
		|	ELSE OrderDueDate.ScheduleDate
		|END"; // @query-part-1
	QueryText = StrReplace(QueryText, "&OrderDueDate", OrderDueDate);
	
	OrderExecutionTimeInDays = "ISNULL(SupplyMethodOverridable.OrderFulfillmentPeriod, 0)"; // @query-part-1
	GettingQualityControlDeadline = Products <> "" And GetFunctionalOption("UseGoodsQualityControl");
	If GettingQualityControlDeadline Then
		ControlTerm =
			"CASE
			|	WHEN LeadingTable.Products.ControlQualityOfReceivedGoods
			|			AND CAST(LeadingTable.Warehouse AS Catalog.Warehouses).ControlQualityOfReceivedGoods
			|		THEN LeadingTable.Products.TermOfQualityControl
			|	ELSE 0
			|END"; // @query-part-1
		OrderExecutionTimeInDays = StrTemplate("(%1 + %2)", OrderExecutionTimeInDays, ControlTerm);
	EndIf;
	QueryText = StrReplace(QueryText, "&OrderExecutionTimeInDays", OrderExecutionTimeInDays);
	
	Field = QueryText;
	
	SELECTText = "SELECT"; // @query-part-1
	SearchExpression = "\s*" + SELECTText + "\s+[^\s]";
	
	SearchResult = StrFindByRegularExpression(
		Field,
		SearchExpression,
		SearchDirection.FromBegin,
		1,
		1,
		True);
	Field = Mid(Field, SearchResult.StartIndex + SearchResult.Length - 1);
	
	TextAs = "AS"; // @query-part-1
	TextOfFieldName = "PlannedDeliveryDateOverridable";
	SearchExpression = "[^\s]\s+" + TextAs + "\s+" + TextOfFieldName + "\s*" + ",";
	
	SearchResult = StrFindByRegularExpression(
		Field,
		SearchExpression,
		SearchDirection.FromBegin,
		1,
		1,
		True);
	DeliveryDateFieldAtOrderPoint = Mid(Field, SearchResult.StartIndex + SearchResult.Length);
	Field = Left(Field, SearchResult.StartIndex + 1);
	
	TextAs = "AS"; // @query-part-1
	TextOfFieldName = "DeliveryDateByReorderPointOverridable";
	SearchExpression = "[^\s]\s+" + TextAs + "\s+" + TextOfFieldName + "\s*";
	
	SearchResult = StrFindByRegularExpression(
		DeliveryDateFieldAtOrderPoint,
		SearchExpression,
		SearchDirection.FromBegin,
		1,
		1,
		True);
	DeliveryDateFieldAtOrderPoint = Left(DeliveryDateFieldAtOrderPoint, SearchResult.StartIndex + 1);
	
	Joins = QueryText;
	
	TextLeftConnection = "LEFT JOIN"; // @query-part-1
	TextLeftConnection = StrReplace(TextLeftConnection, " ", "\s+");
	SearchExpression = "\s" + TextLeftConnection + "\s";
	
	SearchResult = StrFindByRegularExpression(
		Joins,
		SearchExpression,
		SearchDirection.FromBegin,
		1,
		1,
		True);
	Joins = Mid(Joins, SearchResult.StartIndex + 1);
	
	Substitutions_3 = New Array();
	SearchString = "LeadingTable.SupplyMethod";
	Substitutions_3.Add(New Structure("SearchString,ReplacementString", SearchString, SupplyMethod));
	SearchString = "LeadingTable.BeginningOfThisDay";
	Substitutions_3.Add(New Structure("SearchString,ReplacementString", SearchString, BeginningOfThisDay));
	
	If GettingQualityControlDeadline Then
		
		SearchString = "LeadingTable.Products";
		Substitutions_3.Add(New Structure("SearchString,ReplacementString", SearchString, Products));
		SearchString = "LeadingTable.Warehouse";
		Substitutions_3.Add(New Structure("SearchString,ReplacementString", SearchString, Warehouse));
		
	EndIf;
	
	For IndexOf = 0 To Substitutions_3.Count() - 1 Do
		Field = StrReplace(Field, Substitutions_3[IndexOf].SearchString, Substitutions_3[IndexOf].ReplacementString);
		DeliveryDateFieldAtOrderPoint = StrReplace(DeliveryDateFieldAtOrderPoint, Substitutions_3[IndexOf].SearchString, Substitutions_3[IndexOf].ReplacementString);
		Joins = StrReplace(Joins, Substitutions_3[IndexOf].SearchString, Substitutions_3[IndexOf].ReplacementString);
	EndDo;
	
	Result = New Structure("Field,DeliveryDateFieldAtOrderPoint,Joins",
		Field, DeliveryDateFieldAtOrderPoint, Joins);
		
	Return Result;
	
EndFunction

// It is used to include information about the planned delivery date according to the method of provision in an arbitrary request.
// If the provision method is not configured, the current date will be returned. 
// 
// Parameters:
//  LeadingTable - String - The name of the table in the temp table manager that contains:
//                            the field associated with the provisioning method.
//                            the field associated with the reference date. 
// Returns:
//  String - The Query Text of a temporary table containing information about the planned delivery date according to the method of ensuring without taking into account the timing of quality control.
Function TempTablePlannedDeliveryDates(LeadingTable) Export
	
	QueryText =
		"SELECT DISTINCT
		|	LeadingTable.SupplyMethod AS Ref,
		|	LeadingTable.SupplyMethod.DeliverySchedule AS DeliverySchedule,
		|	LeadingTable.SupplyMethod.OrderFulfillmentPeriod AS OrderFulfillmentPeriod,
		|	LeadingTable.SupplyMethod.NumberOfPeriodsBetweenDeliveries AS NumberOfPeriodsBetweenDeliveries,
		|	LeadingTable.SupplyMethod.DeliveryScheduleFrequency AS DeliveryScheduleFrequency,
		|	LeadingTable.SupplyMethod.FirstDateInDeliverySchedule AS FirstDateInDeliverySchedule,
		|	LeadingTable.SupplyMethod.GenerateOrdersOnSchedule AS GenerateOrdersOnSchedule,
		|	LeadingTable.BeginningOfThisDay AS BeginningOfThisDay,
		|	DATEADD(LeadingTable.BeginningOfThisDay, DAY, ISNULL(LeadingTable.SupplyMethod.OrderFulfillmentPeriod, 0)) OrderDueDateWithoutCalendar
		|INTO VariousWaysToSupply
		|FROM
		|	&LeadingTable AS LeadingTable
		|;
		|
		|///////////////////////////////////////////////////
		|SELECT DISTINCT
		|	Table.Ref AS Ref,
		|	Table.DeliverySchedule AS DeliverySchedule,
		|	Table.OrderFulfillmentPeriod AS OrderFulfillmentPeriod,
		|	Table.NumberOfPeriodsBetweenDeliveries AS NumberOfPeriodsBetweenDeliveries,
		|	Table.DeliveryScheduleFrequency AS DeliveryScheduleFrequency,
		|	Table.FirstDateInDeliverySchedule AS FirstDateInDeliverySchedule,
		|	Table.GenerateOrdersOnSchedule AS GenerateOrdersOnSchedule,
		|	EnterpriseCalendar.Value AS EnterpriseCalendar,
		|	OrderExecutionPeriodIsOneYear.Year AS OrderExecutionPeriodIsOneYear,
		|	Table.OrderDueDateWithoutCalendar OrderDueDateWithoutCalendar,
		|	YEAR(Table.OrderDueDateWithoutCalendar) OrderExecutionPeriodIsYearWithoutCalendar,
		|	ThisDayIsYear.OpeningBalance AS ThisDayOpeningBalance,
		|	ThisDayIsDate.DaysCountInScheduleSinceBegOfYear AS ThisDayIsNumberOfDaysInScheduleSinceBeginningOfYear,
		|	OrderExecutionPeriodIsOneYear.OpeningBalance AS OrderFulfillmentPeriodOpeningBalance
		|INTO DataOfSupplyMethods
		|FROM
		|	VariousWaysToSupply AS Table
		|		
		|		LEFT JOIN Constant.MainEnterpriseCalendar AS EnterpriseCalendar
		|		ON TRUE
		|		
		|		LEFT JOIN YearsOfEnterpriseSchedule AS ThisDayIsYear
		|		ON ThisDayIsYear.Year = YEAR(Table.BeginningOfThisDay)
		|		
		// Getting the date in the schedule for the due date of the order.
		|		LEFT JOIN InformationRegister.CalendarSchedules AS ThisDayIsDate
		|		ON ThisDayIsDate.Calendar = EnterpriseCalendar.Value
		|		AND ThisDayIsDate.Year = YEAR(Table.BeginningOfThisDay)
		|		AND ThisDayIsDate.ScheduleDate = Table.BeginningOfThisDay
		|		
		|		LEFT JOIN YearsOfEnterpriseSchedule AS OrderExecutionPeriodIsOneYear
		|		ON ThisDayIsYear.OpeningBalance
		|				+ ThisDayIsDate.DaysCountInScheduleSinceBegOfYear
		|				+ ISNULL(Table.OrderFulfillmentPeriod, 0)
		|			BETWEEN OrderExecutionPeriodIsOneYear.OpeningBalance + 1
		|				AND OrderExecutionPeriodIsOneYear.ClosingBalance
		|INDEX BY
		|	Ref
		|;
		|DROP VariousWaysToSupply
		|;
		|
		|////////////////////////////////////////////
		|SELECT DISTINCT
		|	Set.Calendar AS Calendar,
		|	Set.Year AS Year
		|INTO CalendarsAndYearsForCalculatingPlannedDeliveryDate
		|FROM(
		|	SELECT
		|		Table.DeliverySchedule AS Calendar,
		|		Table.OrderExecutionPeriodIsOneYear AS Year
		|	FROM
		|		DataOfSupplyMethods AS Table
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		Table.DeliverySchedule AS Calendar,
		|		Table.OrderExecutionPeriodIsOneYear + 1 AS Year
		|	FROM
		|		DataOfSupplyMethods AS Table
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		Table.DeliverySchedule AS Calendar,
		|		Table.OrderExecutionPeriodIsYearWithoutCalendar AS Year
		|	FROM
		|		DataOfSupplyMethods AS Table
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		Table.DeliverySchedule AS Calendar,
		|		Table.OrderExecutionPeriodIsYearWithoutCalendar + 1 AS Year
		|	FROM
		|		DataOfSupplyMethods AS Table
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		Table.EnterpriseCalendar AS Calendar,
		|		Table.OrderExecutionPeriodIsOneYear AS Year
		|	FROM
		|		DataOfSupplyMethods AS Table) AS Set
		|INDEX BY
		|	Calendar, Year
		|;
		|
		|////////////////////////////////////////////////////////////
		|SELECT
		|	Schedules.Calendar AS Calendar,
		|	Schedules.Year AS Year,
		|	Schedules.ScheduleDate AS ScheduleDate,
		|	Schedules.DaysCountInScheduleSinceBegOfYear AS DaysCountInScheduleSinceBegOfYear
		|INTO CalendarChartData
		|FROM
		|	CalendarsAndYearsForCalculatingPlannedDeliveryDate AS Table
		|		INNER JOIN InformationRegister.CalendarSchedules AS Schedules
		|		ON Schedules.Calendar = Table.Calendar
		|		AND Schedules.Year = Table.Year
		|		AND Schedules.DayAddedToSchedule
		|INDEX BY
		|	Calendar,Year,DaysCountInScheduleSinceBegOfYear
		|;
		|DROP CalendarsAndYearsForCalculatingPlannedDeliveryDate
		|
		|;
		|///////////////////////////////////////////
		|SELECT
		|	SupplyMethod.Ref AS SupplyMethod,
		|	ISNULL(
// Boundary case - the calendar is not filled.
		|		CASE
		|			WHEN &OrderDueDate IS NULL
		|					
		|					THEN NULL
		|					
		|			WHEN SupplyMethod.GenerateOrdersOnSchedule
		|				
		|				THEN
		|					
		|					CASE
		|						
// The schedule is set manually according to the calendar: Delivery schedule.
		|						WHEN SupplyMethod.DeliverySchedule <> VALUE(Catalog.Calendars.EmptyRef)
		|							
		|							THEN
		|								CASE
		|									WHEN SupplyMethod.EnterpriseCalendar = VALUE(Catalog.Calendars.EmptyRef)
		|											OR ISNULL(SupplyMethod.OrderFulfillmentPeriod, 0) = 0
		|										THEN
		|											CASE
		|											WHEN DeliveryScheduleOrderDueDateWithoutCalendar.DayAddedToSchedule
		|												THEN DeliveryScheduleOrderDueDateWithoutCalendar.ScheduleDate
		|											WHEN NOT DeliveryScheduleOrderDueDatePlusOneDayDateWithoutCalendar.ScheduleDate IS NULL
		|												THEN DeliveryScheduleOrderDueDatePlusOneDayDateWithoutCalendar.ScheduleDate
		|											ELSE DeliveryScheduleOrderDueDateFirstDayOfNextYearWithoutCalendar.ScheduleDate
		|										END
		|									ELSE
		|										CASE
		|											WHEN DeliveryScheduleOrderDueDate.DayAddedToSchedule
		|												THEN DeliveryScheduleOrderDueDate.ScheduleDate
		|											WHEN NOT DeliveryScheduleOrderDueDatePlusOneDayDate.ScheduleDate IS NULL
		|												THEN DeliveryScheduleOrderDueDatePlusOneDayDate.ScheduleDate
		|											ELSE DeliveryScheduleOrderDueDateFirstDayOfNextYear.ScheduleDate
		|										END
		|									END
// Boundary case - the provision method is not filled in correctly.
		|						WHEN SupplyMethod.NumberOfPeriodsBetweenDeliveries = 0
		|							
		|							THEN NULL
		|						
// The boundary case is the first delivery date in the schedule.
		|						WHEN SupplyMethod.FirstDateInDeliverySchedule >= &OrderDueDate
		|							
		|							THEN SupplyMethod.FirstDateInDeliverySchedule
		|							
// Schedule - Month, Quarter, Half-Year, Year. Calculation of the date according to the schedule.
		|						WHEN SupplyMethod.DeliveryScheduleFrequency IN(
		|								VALUE(Enum.ScheduleTimeFence.MONTH),
		|								VALUE(Enum.ScheduleTimeFence.QUARTER),
		|								VALUE(Enum.ScheduleTimeFence.HALFYEAR),
		|								VALUE(Enum.ScheduleTimeFence.YEAR))
		|							
		|							THEN
		|								
		|								DATEADD(
		|									SupplyMethod.FirstDateInDeliverySchedule,
		|									MONTH,
		|									SupplyMethod.NumberOfPeriodsBetweenDeliveries
		|										* CASE
		|											WHEN SupplyMethod.DeliveryScheduleFrequency
		|													= VALUE(Enum.ScheduleTimeFence.MONTH)
		|												THEN 1
		|											WHEN SupplyMethod.DeliveryScheduleFrequency
		|													= VALUE(Enum.ScheduleTimeFence.QUARTER)
		|												THEN 3
		|											WHEN SupplyMethod.DeliveryScheduleFrequency
		|													= VALUE(Enum.ScheduleTimeFence.HALFYEAR)
		|												THEN 6
		|											WHEN SupplyMethod.DeliveryScheduleFrequency
		|													= VALUE(Enum.ScheduleTimeFence.YEAR)
		|												THEN 12
		|										END
		|										* (1 + INT(
		|												(DATEDIFF(
		|														SupplyMethod.FirstDateInDeliverySchedule,
		|														&OrderDueDate,
		|														MONTH)
		|													- CASE
		|															WHEN
		|																DATEADD(
		|																	SupplyMethod.FirstDateInDeliverySchedule,
		|																	MONTH,
		|																	DATEDIFF(
		|																		SupplyMethod.FirstDateInDeliverySchedule,
		|																		&OrderDueDate,
		|																		MONTH)) >= &OrderDueDate
		|																THEN 1
		|														ELSE 0
		|													END
		|												)
		|												/ (SupplyMethod.NumberOfPeriodsBetweenDeliveries
		|													* CASE
		|														WHEN SupplyMethod.DeliveryScheduleFrequency
		|																= VALUE(Enum.ScheduleTimeFence.MONTH)
		|															THEN 1
		|														WHEN SupplyMethod.DeliveryScheduleFrequency
		|																= VALUE(Enum.ScheduleTimeFence.QUARTER)
		|															THEN 3
		|														WHEN SupplyMethod.DeliveryScheduleFrequency
		|																= VALUE(Enum.ScheduleTimeFence.HALFYEAR)
		|															THEN 6
		|														WHEN SupplyMethod.DeliveryScheduleFrequency
		|																= VALUE(Enum.ScheduleTimeFence.YEAR)
		|															THEN 12
		|													END)
		|												)
		|											)
		|								)
		|								
// Schedule - Day, Week. Calculation of the date according to the schedule.
		|						WHEN SupplyMethod.DeliveryScheduleFrequency IN(
		|								VALUE(Enum.ScheduleTimeFence.DAY),
		|								VALUE(Enum.ScheduleTimeFence.WEEK))
		|							
		|							THEN
		|								DATEADD(
		|									SupplyMethod.FirstDateInDeliverySchedule,
		|									DAY,
		|									SupplyMethod.NumberOfPeriodsBetweenDeliveries
		|									* CASE
		|										WHEN SupplyMethod.DeliveryScheduleFrequency
		|												= VALUE(Enum.ScheduleTimeFence.DAY)
		|											THEN 1
		|										WHEN SupplyMethod.DeliveryScheduleFrequency
		|												= VALUE(Enum.ScheduleTimeFence.WEEK)
		|											THEN 7
		|									END
		|									* (1 + INT(
		|												(DATEDIFF(
		|														SupplyMethod.FirstDateInDeliverySchedule,
		|														&OrderDueDate,
		|														DAY)
		|													- CASE
		|															WHEN
		|																DATEADD(
		|																	SupplyMethod.FirstDateInDeliverySchedule,
		|																	DAY,
		|																	DATEDIFF(
		|																		SupplyMethod.FirstDateInDeliverySchedule,
		|																		&OrderDueDate,
		|																		DAY)) >= &OrderDueDate
		|																THEN 1
		|														ELSE 0
		|													END)
		|													/ (SupplyMethod.NumberOfPeriodsBetweenDeliveries
		|														* CASE
		|															WHEN SupplyMethod.DeliveryScheduleFrequency
		|																	= VALUE(Enum.ScheduleTimeFence.DAY)
		|																THEN 1
		|															WHEN SupplyMethod.DeliveryScheduleFrequency
		|																	= VALUE(Enum.ScheduleTimeFence.WEEK)
		|																THEN 7
		|														END)
		|												)
		|										)
		|								)
		|								
// Boundary case - the provision method is not filled in correctly.
		|						ELSE NULL
		|						
		|					END
		|					
// Calculation of the date for the reorder point.
		|			ELSE &OrderDueDate
		|			
		|		END,
		|
// Value if the date cannot be calculated.
		|		DATETIME(1, 1, 1)
		|
		|	) AS PlannedDeliveryDate
		|INTO ScheduledDeliveryDates
		|FROM
		|	DataOfSupplyMethods AS SupplyMethod
		|	
		// Getting the date in the schedule for the due date of the order.
		|		LEFT JOIN CalendarChartData AS OrderDueDate
		|		ON OrderDueDate.Calendar = SupplyMethod.EnterpriseCalendar
		|		AND OrderDueDate.Year = SupplyMethod.OrderExecutionPeriodIsOneYear
		|		AND OrderDueDate.DaysCountInScheduleSinceBegOfYear
		|			= SupplyMethod.ThisDayOpeningBalance
		|				+ SupplyMethod.ThisDayIsNumberOfDaysInScheduleSinceBeginningOfYear
		|				+ ISNULL(SupplyMethod.OrderFulfillmentPeriod, 0)
		|				- SupplyMethod.OrderFulfillmentPeriodOpeningBalance
		|		
		// Getting the date in the delivery schedule according to the schedule.
		|		LEFT JOIN InformationRegister.CalendarSchedules AS DeliveryScheduleOrderDueDate
		|		ON DeliveryScheduleOrderDueDate.Calendar = SupplyMethod.DeliverySchedule
		|		AND DeliveryScheduleOrderDueDate.Year = SupplyMethod.OrderExecutionPeriodIsOneYear
		|		AND DeliveryScheduleOrderDueDate.ScheduleDate = OrderDueDate.ScheduleDate
		|		
		|		LEFT JOIN CalendarChartData AS DeliveryScheduleOrderDueDatePlusOneDayDate
		|		ON DeliveryScheduleOrderDueDatePlusOneDayDate.Calendar = SupplyMethod.DeliverySchedule
		|		AND DeliveryScheduleOrderDueDatePlusOneDayDate.Year = SupplyMethod.OrderExecutionPeriodIsOneYear
		|		AND DeliveryScheduleOrderDueDatePlusOneDayDate.DaysCountInScheduleSinceBegOfYear
		|			= DeliveryScheduleOrderDueDate.DaysCountInScheduleSinceBegOfYear + 1
		|		
		|		LEFT JOIN CalendarChartData AS DeliveryScheduleOrderDueDateFirstDayOfNextYear
		|		ON DeliveryScheduleOrderDueDateFirstDayOfNextYear.Calendar = SupplyMethod.DeliverySchedule
		|		AND DeliveryScheduleOrderDueDateFirstDayOfNextYear.Year = SupplyMethod.OrderExecutionPeriodIsOneYear + 1
		|		AND DeliveryScheduleOrderDueDateFirstDayOfNextYear.DaysCountInScheduleSinceBegOfYear = 1
		|
		// Getting the date in the delivery schedule according to the schedule if the calendar is not full or the deadline is zero.
		|		LEFT JOIN InformationRegister.CalendarSchedules AS DeliveryScheduleOrderDueDateWithoutCalendar
		|		ON DeliveryScheduleOrderDueDateWithoutCalendar.Calendar = SupplyMethod.DeliverySchedule
		|		AND DeliveryScheduleOrderDueDateWithoutCalendar.Year = SupplyMethod.OrderExecutionPeriodIsYearWithoutCalendar
		|		AND DeliveryScheduleOrderDueDateWithoutCalendar.ScheduleDate = SupplyMethod.OrderDueDateWithoutCalendar
		|		
		|		LEFT JOIN CalendarChartData AS DeliveryScheduleOrderDueDatePlusOneDayDateWithoutCalendar
		|		ON DeliveryScheduleOrderDueDatePlusOneDayDateWithoutCalendar.Calendar = SupplyMethod.DeliverySchedule
		|		AND DeliveryScheduleOrderDueDatePlusOneDayDateWithoutCalendar.Year = SupplyMethod.OrderExecutionPeriodIsYearWithoutCalendar
		|		AND DeliveryScheduleOrderDueDatePlusOneDayDateWithoutCalendar.DaysCountInScheduleSinceBegOfYear
		|			= DeliveryScheduleOrderDueDateWithoutCalendar.DaysCountInScheduleSinceBegOfYear + 1
		|		
		|		LEFT JOIN CalendarChartData AS DeliveryScheduleOrderDueDateFirstDayOfNextYearWithoutCalendar
		|		ON DeliveryScheduleOrderDueDateFirstDayOfNextYearWithoutCalendar.Calendar = SupplyMethod.DeliverySchedule
		|		AND DeliveryScheduleOrderDueDateFirstDayOfNextYearWithoutCalendar.Year = SupplyMethod.OrderExecutionPeriodIsYearWithoutCalendar + 1
		|		AND DeliveryScheduleOrderDueDateFirstDayOfNextYearWithoutCalendar.DaysCountInScheduleSinceBegOfYear = 1
		|INDEX BY
		|	SupplyMethod
		|;
		|
		|DROP CalendarChartData;
		|DROP DataOfSupplyMethods";
	
	OrderDueDate = // to simplify the recording of the original text of the request.
		"CASE
		|	WHEN SupplyMethod.EnterpriseCalendar = VALUE(Catalog.Calendars.EmptyRef)
		|				OR ISNULL(SupplyMethod.OrderFulfillmentPeriod, 0) = 0
		|			THEN SupplyMethod.OrderDueDateWithoutCalendar
		|	ELSE OrderDueDate.ScheduleDate
		|END";
	QueryText = StrReplace(QueryText, "&OrderDueDate", OrderDueDate);
	QueryText = StrReplace(QueryText, "&LeadingTable", LeadingTable);
	Return QueryText;
	
EndFunction

// It is used to include in an arbitrary request information about the delivery date according to the method of providing the closest to a certain date.
// 
// Parameters:
//  SupplyMethod - String - Expression of the field of the master table associated with the way needs are met. 
//  Date - String - Expression of the field of the master table or parameter associated with the value of the start date.
// 
// Returns:
//  Structure - Contains fields:
//  * Field - String - An expression to be inserted into the Query Text that allows you to get the delivery date using the collateral method.
//  * Joins - String - Expression, for substitution in the Query Text as the necessary left connections to the master table.
Function SubstitutionsOfDeliveryDateClosestToShipmentDate(SupplyMethod, Date) Export
	
	QueryText =
		"SELECT
		|	ISNULL(
// Boundary case - the date by which we are looking for the delivery date is not filled in.
		|		CASE
		|			WHEN LeadingTable.Date = DATETIME(1, 1, 1)
		|					
		|					THEN NULL
		|					
		|			WHEN SupplyMethodOverridable.GenerateOrdersOnSchedule
		|				
		|				THEN
		|					
		|					CASE
		|						
// The schedule is set manually according to the calendar: Delivery schedule.
		|						WHEN SupplyMethodOverridable.DeliverySchedule <> VALUE(Catalog.Calendars.EmptyRef)
		|							
		|							THEN
		|								
		|								CASE
		|									WHEN DeliveryScheduleDate.DayAddedToSchedule
		|										THEN DeliveryScheduleDate.ScheduleDate
		|									WHEN NOT DeliveryScheduleDateMinusOneDay.ScheduleDate IS NULL
		|										THEN DeliveryScheduleDateMinusOneDay.ScheduleDate
		|									WHEN NOT DeliveryScheduleLastDayOfPreviousYear.ScheduleDate IS NULL
		|										THEN DeliveryScheduleLastDayOfPreviousYear.ScheduleDate
		|									ELSE NULL
		|								END
// Boundary case - the provision method is not filled in correctly.
		|						WHEN SupplyMethodOverridable.NumberOfPeriodsBetweenDeliveries = 0
		|							
		|							THEN NULL
		|						
// The boundary case is the first delivery date in the schedule.
		|						WHEN SupplyMethodOverridable.FirstDateInDeliverySchedule >= LeadingTable.Date
		|							
		|							THEN SupplyMethodOverridable.FirstDateInDeliverySchedule
		|							
// Schedule - Month, Quarter, Half-Year, Year. Calculation of the date according to the schedule.
		|						WHEN SupplyMethodOverridable.DeliveryScheduleFrequency IN(
		|								VALUE(Enum.ScheduleTimeFence.MONTH),
		|								VALUE(Enum.ScheduleTimeFence.QUARTER),
		|								VALUE(Enum.ScheduleTimeFence.HALFYEAR),
		|								VALUE(Enum.ScheduleTimeFence.YEAR))
		|							
		|							THEN
		|								
		|								DATEADD(
		|									SupplyMethodOverridable.FirstDateInDeliverySchedule,
		|									MONTH,
		|									SupplyMethodOverridable.NumberOfPeriodsBetweenDeliveries
		|										* CASE
		|											WHEN SupplyMethodOverridable.DeliveryScheduleFrequency
		|													= VALUE(Enum.ScheduleTimeFence.MONTH)
		|												THEN 1
		|											WHEN SupplyMethodOverridable.DeliveryScheduleFrequency
		|													= VALUE(Enum.ScheduleTimeFence.QUARTER)
		|												THEN 3
		|											WHEN SupplyMethodOverridable.DeliveryScheduleFrequency
		|													= VALUE(Enum.ScheduleTimeFence.HALFYEAR)
		|												THEN 6
		|											WHEN SupplyMethodOverridable.DeliveryScheduleFrequency
		|													= VALUE(Enum.ScheduleTimeFence.YEAR)
		|												THEN 12
		|										END
		|										* (INT(
		|												(DATEDIFF(
		|														SupplyMethodOverridable.FirstDateInDeliverySchedule,
		|														LeadingTable.Date,
		|														MONTH)
		|													- CASE
		|															WHEN
		|																DATEADD(
		|																	SupplyMethodOverridable.FirstDateInDeliverySchedule,
		|																	MONTH,
		|																	DATEDIFF(
		|																		SupplyMethodOverridable.FirstDateInDeliverySchedule,
		|																		LeadingTable.Date,
		|																		MONTH)) >= LeadingTable.Date
		|																THEN 1
		|														ELSE 0
		|													END
		|												)
		|												/ (SupplyMethodOverridable.NumberOfPeriodsBetweenDeliveries
		|													* CASE
		|														WHEN SupplyMethodOverridable.DeliveryScheduleFrequency
		|																= VALUE(Enum.ScheduleTimeFence.MONTH)
		|															THEN 1
		|														WHEN SupplyMethodOverridable.DeliveryScheduleFrequency
		|																= VALUE(Enum.ScheduleTimeFence.QUARTER)
		|															THEN 3
		|														WHEN SupplyMethodOverridable.DeliveryScheduleFrequency
		|																= VALUE(Enum.ScheduleTimeFence.HALFYEAR)
		|															THEN 6
		|														WHEN SupplyMethodOverridable.DeliveryScheduleFrequency
		|																= VALUE(Enum.ScheduleTimeFence.YEAR)
		|															THEN 12
		|													END)
		|												)
		|											)
		|								)
		|								
// Schedule - Day, Week. Calculation of the date according to the schedule.
		|						WHEN SupplyMethodOverridable.DeliveryScheduleFrequency IN(
		|								VALUE(Enum.ScheduleTimeFence.DAY),
		|								VALUE(Enum.ScheduleTimeFence.WEEK))
		|							
		|							THEN
		|								DATEADD(
		|									SupplyMethodOverridable.FirstDateInDeliverySchedule,
		|									DAY,
		|									SupplyMethodOverridable.NumberOfPeriodsBetweenDeliveries
		|									* CASE
		|										WHEN SupplyMethodOverridable.DeliveryScheduleFrequency
		|												= VALUE(Enum.ScheduleTimeFence.DAY)
		|											THEN 1
		|										WHEN SupplyMethodOverridable.DeliveryScheduleFrequency
		|												= VALUE(Enum.ScheduleTimeFence.WEEK)
		|											THEN 7
		|									END
		|									* (INT(
		|											(DATEDIFF(
		|														SupplyMethodOverridable.FirstDateInDeliverySchedule,
		|														LeadingTable.Date,
		|														DAY)
		|												- CASE
		|															WHEN
		|																DATEADD(
		|																	SupplyMethodOverridable.FirstDateInDeliverySchedule,
		|																	DAY,
		|																	DATEDIFF(
		|																		SupplyMethodOverridable.FirstDateInDeliverySchedule,
		|																		LeadingTable.Date,
		|																		DAY)) >= LeadingTable.Date
		|																THEN 1
		|														ELSE 0
		|													END)
		|													/ (SupplyMethodOverridable.NumberOfPeriodsBetweenDeliveries
		|														* CASE
		|															WHEN SupplyMethodOverridable.DeliveryScheduleFrequency
		|																	= VALUE(Enum.ScheduleTimeFence.DAY)
		|																THEN 1
		|															WHEN SupplyMethodOverridable.DeliveryScheduleFrequency
		|																	= VALUE(Enum.ScheduleTimeFence.WEEK)
		|																THEN 7
		|														END)
		|												)
		|										)
		|								)
		|								
// Boundary case - the provision method is not filled in correctly.
		|						ELSE NULL
		|						
		|					END
		|					
// Calculation of the date for the reorder point.
		|			ELSE
		|				CASE
		|					WHEN LeadingTable.Date < &CurrentDayStart
		|						THEN &CurrentDayStart
		|					ELSE LeadingTable.Date
		|				END
		|		END,
		|
// Value if the date cannot be calculated.
		|		DATETIME(1, 1, 1)
		|
		|	) AS PlannedDeliveryDateOverridable
		|FROM
		|	LeadingTableOverridable AS LeadingTable
		|		
		|		LEFT JOIN Catalog.ProcurementStrategies AS SupplyMethodOverridable
		|		ON SupplyMethodOverridable.Ref = LeadingTable.SupplyMethod
		|		
		|		LEFT JOIN InformationRegister.CalendarSchedules AS DeliveryScheduleDate
		|		ON DeliveryScheduleDate.Calendar = SupplyMethodOverridable.DeliverySchedule
		|		AND DeliveryScheduleDate.Year = YEAR(LeadingTable.Date)
		|		AND DeliveryScheduleDate.ScheduleDate = LeadingTable.Date
		|		
		|		LEFT JOIN InformationRegister.CalendarSchedules AS DeliveryScheduleDateMinusOneDay
		|		ON DeliveryScheduleDateMinusOneDay.Calendar = SupplyMethodOverridable.DeliverySchedule
		|		AND DeliveryScheduleDateMinusOneDay.DayAddedToSchedule
		|		AND DeliveryScheduleDateMinusOneDay.Year = DeliveryScheduleDate.Year
		|		AND DeliveryScheduleDateMinusOneDay.DaysCountInScheduleSinceBegOfYear
		|			= DeliveryScheduleDate.DaysCountInScheduleSinceBegOfYear
		|		
		|		LEFT JOIN InformationRegister.CalendarSchedules AS Day365
		|		ON Day365.Calendar = SupplyMethodOverridable.DeliverySchedule
		|		AND Day365.Year = DeliveryScheduleDate.Year - 1
		|		AND Day365.ScheduleDate = DATEADD(BEGINOFPERIOD(DeliveryScheduleDate.ScheduleDate, Year), DAY, - 1)
		|		
		|		LEFT JOIN InformationRegister.CalendarSchedules AS DeliveryScheduleLastDayOfPreviousYear
		|		ON DeliveryScheduleLastDayOfPreviousYear.Calendar = SupplyMethodOverridable.DeliverySchedule
		|		AND DeliveryScheduleLastDayOfPreviousYear.DayAddedToSchedule
		|		AND DeliveryScheduleLastDayOfPreviousYear.Year = DeliveryScheduleDate.Year - 1
		|		AND DeliveryScheduleLastDayOfPreviousYear.DaysCountInScheduleSinceBegOfYear = Day365.DaysCountInScheduleSinceBegOfYear";
	
		Field = QueryText;
		
		SELECTText = "SELECT"; // @query-part-1
		SearchExpression = "\s*" + SELECTText + "\s+[^\s]";
		
		SearchResult = StrFindByRegularExpression(
			Field,
			SearchExpression,
			SearchDirection.FromBegin,
			1,
			1,
			True);
		Field = Mid(Field, SearchResult.StartIndex + SearchResult.Length - 1);
		
		TextAs = "AS"; // @query-part-1
		TextOfFieldName = "PlannedDeliveryDateOverridable";
		SearchExpression = "[^\s]\s+" + TextAs + "\s+" + TextOfFieldName + "\s";
		
		SearchResult = StrFindByRegularExpression(
			Field,
			SearchExpression,
			SearchDirection.FromBegin,
			1,
			1,
			True);
		Field = Left(Field, SearchResult.StartIndex + 1);
		
		Joins = QueryText;
		
		TextLeftConnection = "LEFT JOIN"; // @query-part-1
		TextLeftConnection = StrReplace(TextLeftConnection, " ", "\s+");
		SearchExpression = "\s" + TextLeftConnection + "\s";
		
		SearchResult = StrFindByRegularExpression(
			Joins,
			SearchExpression,
			SearchDirection.FromBegin,
			1,
			1,
			True);
		Joins = Mid(Joins, SearchResult.StartIndex + 1);
		
		Substitutions_3 = New Array();
		SearchString = "LeadingTable.SupplyMethod";
		Substitutions_3.Add(New Structure("SearchString,ReplacementString", SearchString, SupplyMethod));
		SearchString = "LeadingTable.Date";
		Substitutions_3.Add(New Structure("SearchString,ReplacementString", SearchString, Date));
		
		For IndexOf = 0 To Substitutions_3.Count() - 1 Do
			Field = StrReplace(Field, Substitutions_3[IndexOf].SearchString, Substitutions_3[IndexOf].ReplacementString);
			Joins = StrReplace(Joins, Substitutions_3[IndexOf].SearchString, Substitutions_3[IndexOf].ReplacementString);
		EndDo;
		
	Return New Structure("Field,Joins", Field, Joins);
	
EndFunction

// It is used to include in an arbitrary request information about the date counted according to the enterprise calendar from an arbitrary date for an arbitrary number of working days. 
// 
// Parameters:
//  Support method - A string is an expression of a field in the master table associated with a way to meet needs. 
//  StartingDate - String - Expression of the field of the master table or parameter associated with the value of the start date.
//  NumberOfDays - String - Expression of the leading table field or parameter associated with the value of the number of days to be counted.
//  SearchFor0Days - Boolean - If False, and the parameter number of days equal to 0 is passed, then the value equal to the reference date parameter will be returned,
//                         if True, then 0 days will be counted according to the enterprise calendar, which is important if the reference date falls on a day off.
// 
// Returns:
//  Structure - Sodezhrzhit fields:
//  * Field - String - An expression to insert into the Query Text that allows you to get the date you are looking for.
//  * Joins - String - Expression, for substitution in the Query Text as the necessary left connections to the master table.
Function AddToDateAccordingToEnterpriseCalendar(StartingDate, NumberOfDays, SearchFor0Days = False) Export
	
	QueryText =
		"SELECT
		|	CASE
		|		WHEN EnterpriseCalendar.Value = VALUE(Catalog.Calendars.EmptyRef)
		|				OR (LeadingTable.NumberOfDays) = 0 AND NOT &SearchFor0Days
		|			THEN DATEADD(LeadingTable.StartingDate, DAY, (LeadingTable.NumberOfDays))
		|		ELSE ISNULL(NumberOfDaysDate.ScheduleDate, DATETIME(1, 1, 1))
		|	END AS DateFoundOverridable
		|FROM
		|	LeadingTableOverridable AS LeadingTable
		|		
		|		LEFT JOIN Constant.MainEnterpriseCalendar AS EnterpriseCalendar
		|		ON TRUE
		|		
		|		LEFT JOIN YearsOfEnterpriseSchedule AS ReferenceDateYear
		|		ON ReferenceDateYear.Year = YEAR(LeadingTable.StartingDate)
		|		
		|		LEFT JOIN InformationRegister.CalendarSchedules AS DateOfCountdownDate
		|		ON DateOfCountdownDate.Calendar = EnterpriseCalendar.Value
		|		AND DateOfCountdownDate.Year = YEAR(LeadingTable.StartingDate)
		|		AND DateOfCountdownDate.ScheduleDate = LeadingTable.StartingDate
		|		
		|		LEFT JOIN YearsOfEnterpriseSchedule AS NumberOfDaysYear
		|		ON ReferenceDateYear.OpeningBalance
		|				+ DateOfCountdownDate.DaysCountInScheduleSinceBegOfYear
		|				+ (LeadingTable.NumberOfDays)
		|			BETWEEN NumberOfDaysYear.OpeningBalance + 1
		|				AND NumberOfDaysYear.ClosingBalance
		|		
		|		LEFT JOIN InformationRegister.CalendarSchedules AS NumberOfDaysDate
		|		ON NumberOfDaysDate.Calendar = EnterpriseCalendar.Value
		|		AND NumberOfDaysDate.Year = NumberOfDaysYear.Year
		|		AND NumberOfDaysDate.DayAddedToSchedule
		|		AND NumberOfDaysDate.DaysCountInScheduleSinceBegOfYear
		|			= ReferenceDateYear.OpeningBalance
		|				+ DateOfCountdownDate.DaysCountInScheduleSinceBegOfYear
		|				+ (LeadingTable.NumberOfDays)
		|				- NumberOfDaysYear.OpeningBalance";
	
	If SearchFor0Days Then
		QueryText = StrReplace(QueryText, "&SearchFor0Days", "TRUE");
	Else
		QueryText = StrReplace(QueryText, "&SearchFor0Days", "FALSE");
	EndIf;
	
	Field = QueryText;
	
	SELECTText = "SELECT"; // @query-part-1
	SearchExpression = "\s*" + SELECTText + "\s+[^\s]";
	
	SearchResult = StrFindByRegularExpression(
		Field,
		SearchExpression,
		SearchDirection.FromBegin,
		1,
		1,
		True);
	Field = Mid(Field, SearchResult.StartIndex + SearchResult.Length - 1);
	
	TextAs = "AS"; // @query-part-1
	TextOfFieldName = "DateFoundOverridable";
	SearchExpression = "[^\s]\s+" + TextAs + "\s+" + TextOfFieldName + "\s";
	
	SearchResult = StrFindByRegularExpression(
		Field,
		SearchExpression,
		SearchDirection.FromBegin,
		1,
		1,
		True);
	Field = Left(Field, SearchResult.StartIndex + 1);
	
	Joins = QueryText;
	
	TextLeftConnection = "LEFT JOIN"; // @query-part-1
	TextLeftConnection = StrReplace(TextLeftConnection, " ", "\s+");
	SearchExpression = "\s" + TextLeftConnection + "\s";
	
	SearchResult = StrFindByRegularExpression(
		Joins,
		SearchExpression,
		SearchDirection.FromBegin,
		1,
		1,
		True);
	Joins = Mid(Joins, SearchResult.StartIndex + 1);
	
	Substitutions_3 = New Array();
	SearchString = "LeadingTable.NumberOfDays";
	Substitutions_3.Add(New Structure("SearchString,ReplacementString", SearchString, NumberOfDays));
	SearchString = "LeadingTable.StartingDate";
	Substitutions_3.Add(New Structure("SearchString,ReplacementString", SearchString, StartingDate));
	
	For IndexOf = 0 To Substitutions_3.Count() - 1 Do
		Field = StrReplace(Field, Substitutions_3[IndexOf].SearchString, Substitutions_3[IndexOf].ReplacementString);
		Joins = StrReplace(Joins, Substitutions_3[IndexOf].SearchString, Substitutions_3[IndexOf].ReplacementString);
	EndDo;
	
	Return New Structure("Field,Joins", Field, Joins);
	
EndFunction

// Prepares the Query Text of the temp table containing data on the boundary of the security period for the goods and the warehouse, calculated according to the security method. 
// 
// Parameters:
//  Goods - String - The name of the temp table containing the goods and warehouses to get data for.
//  BeginningOfThisDay - String - Expression of the field of the master table or parameter associated with the value of the reference date.
// 
// Returns:
//  String - query text.
Function TempTableBoundariesOfSupplyPeriod(Goods, BeginningOfThisDay) Export
	
	Texts = New Array();
	
	QueryText = TempTableYearsOfEnterpriseSchedule();
	Texts.Add(QueryText);
	
	QueryText =
		"SELECT
		|	LeadingTable.Products AS Products,
		|	LeadingTable.Characteristic AS Characteristic,
		|	LeadingTable.Warehouse AS Warehouse,
		|	LeadingTable.BeginningOfThisDay AS BeginningOfThisDay,
		|	CalculationOfSecurityMethodOverridable.Ref AS SupplyMethod
		|INTO TableMainSupplyMethod
		|FROM
		|	LeadingTableOverridable AS LeadingTable
		|		
		|		LEFT JOIN CalculationOfSecurityMethodOverridable ON TRUE
		|		
		|WHERE
		|	CAST (CalculationOfSecurityMethodOverridable.Ref AS Catalog.ProcurementStrategies).CoveredPeriodOption IN(
		|		VALUE(Enum.CoveredPeriodOptions.CertainNumberOfDays),
		|		VALUE(Enum.CoveredPeriodOptions.UpToTheNextDeliveryDate))
		|INDEX BY
		|	SupplyMethod";
		
	Substitutions = SubstitutionsOfMainMethodOfProviding(
		"LeadingTable.Products",
		"LeadingTable.Characteristic",
		"LeadingTable.Warehouse",
		"TRUE");
	
	QueryText = StrReplace(QueryText, "CalculationOfSecurityMethodOverridable.Ref", Substitutions.Field);
	QueryText = StrReplace(QueryText, "LEFT JOIN CalculationOfSecurityMethodOverridable ON TRUE",
		Substitutions.Joins);
	QueryText = StrReplace(QueryText, "LeadingTableOverridable", Goods);
	QueryText = StrReplace(QueryText, "LeadingTable.BeginningOfThisDay", BeginningOfThisDay);
	Texts.Add(QueryText);
	
	QueryText = TempTablePlannedDeliveryDates("TableMainSupplyMethod");
	Texts.Add(QueryText);
	
	QueryText =
		"SELECT
		|	LeadingTable.Products AS Products,
		|	LeadingTable.Characteristic AS Characteristic,
		|	LeadingTable.Warehouse AS Warehouse,
		|	LeadingTable.SupplyMethod AS MainWayToEnsure,
		|	ScheduledDeliveryDates.PlannedDeliveryDate AS PlannedDeliveryDate
		|INTO PlannedDeliveryDateIsTemporary
		|FROM
		|	TableMainSupplyMethod AS LeadingTable
		|		
		|		LEFT JOIN ScheduledDeliveryDates AS ScheduledDeliveryDates
		|		ON ScheduledDeliveryDates.SupplyMethod = LeadingTable.SupplyMethod
		|WHERE
		|	ScheduledDeliveryDates.PlannedDeliveryDate > DATETIME(1, 1, 1)
		|INDEX BY
		|	Products, Characteristic, Warehouse
		|;
		|DROP TableMainSupplyMethod;
		|DROP ScheduledDeliveryDates";
		
	Texts.Add(QueryText);
	
	QueryText = TempTableBoundariesOfSupplyPeriodAccordingToPlannedDeliveryDateTable("BY_TOWARE");
	Texts.Add(QueryText);
	
	Texts.Add("DROP PlannedDeliveryDateIsTemporary");
	Texts.Add("DROP YearsOfEnterpriseScheduleTemporary");
	Texts.Add("DROP YearsOfEnterpriseSchedule");
	
	QueryText = StrConcat(Texts, Common.QueryBatchSeparator());
	
	Return QueryText;
	
EndFunction

// Prepares the Query Text of the temp table containing data on the boundary of the security period for the item and the warehouse, calculated according to the security method. 
// It is used when a table of planned delivery dates has already been received in the temp tables query manager.
// 
// Parameters:
//  GetOption - String - "ACCORDING TO THE PRODUCT" or "ACCORDING TO THE ABILITY". If the item, the boundaries will be obtained taking into account the timing of quality control.
// Returns:
//  String - query text.
Function TempTableBoundariesOfSupplyPeriodAccordingToPlannedDeliveryDateTable(GetOption) Export
	
	Texts = New Array();
	
	QueryText =
		"SELECT DISTINCT
		|	SupplyMethod.Ref AS Ref,
		|	SupplyMethod.DeliverySchedule AS DeliverySchedule,
		|	SupplyMethod.CoveredPeriod AS CoveredPeriod,
		|	EnterpriseCalendar.Value AS EnterpriseCalendar,
		|	PeriodProvidedIsYear.Year AS PeriodProvidedIsYear,
		|	PlannedDeliveryDateYear.Year AS PlannedDeliveryDateYear,
		|	PlannedDeliveryDateYear.OpeningBalance AS PlannedDeliveryDateOpeningBalance,
		|	PeriodProvidedIsYear.OpeningBalance AS CoveredPeriodOpeningBalance,
		|	PeriodProvidedIsYear.ClosingBalance AS CoveredPeriodClosingBalance,
		|	PlannedDeliveryDateDate.DaysCountInScheduleSinceBegOfYear AS ScheduledDeliveryDateNumberOfDaysInScheduleSinceBeginningOfYear,
		|	SupplyMethod.DeliveryScheduleFrequency AS DeliveryScheduleFrequency,
		|	SupplyMethod.NumberOfPeriodsBetweenDeliveries AS NumberOfPeriodsBetweenDeliveries,
		|	SupplyMethod.CoveredPeriodOption AS CoveredPeriodOption
		|INTO DataOfSupplyMethods
		|FROM
		|	PlannedDeliveryDateIsTemporary AS Table
		|		
		|		LEFT JOIN Catalog.ProcurementStrategies AS SupplyMethod
		|		ON SupplyMethod.Ref = Table.MainWayToEnsure
		|		
		|		LEFT JOIN Constant.MainEnterpriseCalendar AS EnterpriseCalendar
		|		ON TRUE
		|		
		|		LEFT JOIN YearsOfEnterpriseSchedule AS PlannedDeliveryDateYear
		|		ON PlannedDeliveryDateYear.Year = YEAR(Table.PlannedDeliveryDate)
		|		
		|		LEFT JOIN InformationRegister.CalendarSchedules AS PlannedDeliveryDateDate
		|		ON PlannedDeliveryDateDate.Calendar = EnterpriseCalendar.Value
		|		AND PlannedDeliveryDateDate.Year = PlannedDeliveryDateYear.Year
		|		AND PlannedDeliveryDateDate.ScheduleDate = Table.PlannedDeliveryDate
		|		
		|		LEFT JOIN YearsOfEnterpriseSchedule AS PeriodProvidedIsYear
		|		ON PlannedDeliveryDateYear.OpeningBalance
		|				+ PlannedDeliveryDateDate.DaysCountInScheduleSinceBegOfYear
		|				+ ISNULL(SupplyMethod.CoveredPeriod, 0)
		|			BETWEEN PeriodProvidedIsYear.OpeningBalance + 1
		|				AND PeriodProvidedIsYear.ClosingBalance
		|INDEX BY
		|	Ref
		|;
		|
		|////////////////////////////////////////////////////////////
		|SELECT DISTINCT
		|	Set.Calendar AS Calendar,
		|	Set.Year AS Year
		|INTO CalendarsAndYearsForCalculatingPeriodBoundaries
		|FROM(
		|	SELECT
		|		Table.DeliverySchedule AS Calendar,
		|		Table.PlannedDeliveryDateYear AS Year
		|	FROM
		|		DataOfSupplyMethods AS Table
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		Table.DeliverySchedule AS Calendar,
		|		Table.PlannedDeliveryDateYear + 1 AS Year
		|	FROM
		|		DataOfSupplyMethods AS Table
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		Table.EnterpriseCalendar AS Calendar,
		|		Table.PeriodProvidedIsYear AS Year
		|	FROM
		|		DataOfSupplyMethods AS Table) AS Set
		|INDEX BY
		|	Calendar, Year
		|;
		|
		|////////////////////////////////////////////////////////////
		|SELECT
		|	Schedules.Calendar AS Calendar,
		|	Schedules.Year AS Year,
		|	Schedules.ScheduleDate AS ScheduleDate,
		|	Schedules.DaysCountInScheduleSinceBegOfYear AS DaysCountInScheduleSinceBegOfYear
		|INTO CalendarChartData
		|FROM
		|	CalendarsAndYearsForCalculatingPeriodBoundaries AS Table
		|		INNER JOIN InformationRegister.CalendarSchedules AS Schedules
		|		ON Schedules.Calendar = Table.Calendar
		|		AND Schedules.Year = Table.Year
		|		AND Schedules.DayAddedToSchedule
		|INDEX BY
		|	Calendar,Year,DaysCountInScheduleSinceBegOfYear
		|;
		|DROP CalendarsAndYearsForCalculatingPeriodBoundaries";
		
	Texts.Add(QueryText);
	
	QueryText =
		"SELECT
		|	&ItemFields,
		|	SupplyMethod.Ref AS MainWayToEnsure,
		|	ISNULL(
		|			CASE
		|				WHEN Table.PlannedDeliveryDate = DATETIME(1, 1, 1)
		|					
		|					THEN NULL
		|					
		|				WHEN SupplyMethod.CoveredPeriodOption = VALUE(Enum.CoveredPeriodOptions.UpToTheNextDeliveryDate)
		|					
		|					THEN
		|					
		|						CASE
		|							
// The schedule is set manually according to the calendar: Delivery schedule.
		|							WHEN SupplyMethod.DeliverySchedule <> VALUE(Catalog.Calendars.EmptyRef)
		|								
		|								THEN
		|									
		|									CASE
		|										WHEN NOT DeliveryScheduleScheduledDeliveryDatePlusOneDayDate.ScheduleDate IS NULL
		|											THEN DeliveryScheduleScheduledDeliveryDatePlusOneDayDate.ScheduleDate
		|										ELSE DeliveryScheduleScheduledDeliveryDateFirstDayOfNextYear.ScheduleDate
		|									END
		|									
// Schedule - Month, Quarter, Half-Year, Year. Calculation of the date according to the schedule.
		|							WHEN SupplyMethod.DeliveryScheduleFrequency IN(
		|									VALUE(Enum.ScheduleTimeFence.MONTH),
		|									VALUE(Enum.ScheduleTimeFence.QUARTER),
		|									VALUE(Enum.ScheduleTimeFence.HALFYEAR),
		|									VALUE(Enum.ScheduleTimeFence.YEAR))
		|								
		|								THEN
		|									
		|									DATEADD(
		|										Table.PlannedDeliveryDate,
		|										MONTH,
		|										SupplyMethod.NumberOfPeriodsBetweenDeliveries
		|											* CASE
		|												WHEN SupplyMethod.DeliveryScheduleFrequency
		|														= VALUE(Enum.ScheduleTimeFence.MONTH)
		|													THEN 1
		|												WHEN SupplyMethod.DeliveryScheduleFrequency
		|														= VALUE(Enum.ScheduleTimeFence.QUARTER)
		|													THEN 3
		|												WHEN SupplyMethod.DeliveryScheduleFrequency
		|														= VALUE(Enum.ScheduleTimeFence.HALFYEAR)
		|													THEN 6
		|												WHEN SupplyMethod.DeliveryScheduleFrequency
		|														= VALUE(Enum.ScheduleTimeFence.YEAR)
		|													THEN 12
		|											END
		|									)
		|								
// Schedule - Day, Week. Calculation of the date according to the schedule.
		|							WHEN SupplyMethod.DeliveryScheduleFrequency IN(
		|									VALUE(Enum.ScheduleTimeFence.DAY),
		|									VALUE(Enum.ScheduleTimeFence.WEEK))
		|								
		|								THEN
		|									DATEADD(
		|										Table.PlannedDeliveryDate,
		|										DAY,
		|										SupplyMethod.NumberOfPeriodsBetweenDeliveries
		|										* CASE
		|											WHEN SupplyMethod.DeliveryScheduleFrequency
		|													= VALUE(Enum.ScheduleTimeFence.DAY)
		|												THEN 1
		|											WHEN SupplyMethod.DeliveryScheduleFrequency
		|													= VALUE(Enum.ScheduleTimeFence.WEEK)
		|												THEN 7
		|										END
		|									)
		|									
// Boundary case - the provision method is not filled in correctly.
		|							ELSE NULL
		|							
		|						END
		|						
// Calculation of the date after a certain number of days.
		|				WHEN SupplyMethod.CoveredPeriodOption = VALUE(Enum.CoveredPeriodOptions.CertainNumberOfDays)
		|					
		|					THEN
		|						
		|						CASE
		|							WHEN SupplyMethod.EnterpriseCalendar = VALUE(Catalog.Calendars.EmptyRef)
		|								THEN
		|									DATEADD(Table.PlannedDeliveryDate, DAY,
		|										ISNULL(SupplyMethod.CoveredPeriod, 0))
		|							ELSE PeriodProvidedIsDate.ScheduleDate
		|						END
		|				
		|			END,
		|	
// Value if the date cannot be calculated.
		|			DATETIME(1, 1, 1)
		|	) AS PeriodBoundary
		|INTO BoundariesOfPeriodOfProvisionWithoutTakingIntoAccountTimingOfControl
		|FROM
		|	PlannedDeliveryDateIsTemporary AS Table
		|		
		|		LEFT JOIN DataOfSupplyMethods AS SupplyMethod
		|		ON SupplyMethod.Ref = Table.MainWayToEnsure
		|		
		|		LEFT JOIN CalendarChartData AS PeriodProvidedIsDate
		|		ON PeriodProvidedIsDate.Calendar = SupplyMethod.EnterpriseCalendar
		|		AND PeriodProvidedIsDate.Year = SupplyMethod.PeriodProvidedIsYear
		|		AND PeriodProvidedIsDate.DaysCountInScheduleSinceBegOfYear
		|			= SupplyMethod.PlannedDeliveryDateOpeningBalance
		|				+ SupplyMethod.ScheduledDeliveryDateNumberOfDaysInScheduleSinceBeginningOfYear
		|				+ ISNULL(SupplyMethod.CoveredPeriod, 0)
		|				- SupplyMethod.CoveredPeriodOpeningBalance
		|		
		// Getting the date in the delivery schedule according to the schedule.
		|		LEFT JOIN InformationRegister.CalendarSchedules AS DeliveryScheduleScheduledDeliveryDateDate
		|		ON DeliveryScheduleScheduledDeliveryDateDate.Calendar = SupplyMethod.DeliverySchedule
		|		AND DeliveryScheduleScheduledDeliveryDateDate.Year = SupplyMethod.PlannedDeliveryDateYear
		|		AND DeliveryScheduleScheduledDeliveryDateDate.ScheduleDate = Table.PlannedDeliveryDate
		|		
		|		LEFT JOIN CalendarChartData AS DeliveryScheduleScheduledDeliveryDatePlusOneDayDate
		|		ON DeliveryScheduleScheduledDeliveryDatePlusOneDayDate.Calendar = SupplyMethod.DeliverySchedule
		|		AND DeliveryScheduleScheduledDeliveryDatePlusOneDayDate.Year = SupplyMethod.PlannedDeliveryDateYear
		|		AND DeliveryScheduleScheduledDeliveryDatePlusOneDayDate.DaysCountInScheduleSinceBegOfYear
		|			= DeliveryScheduleScheduledDeliveryDateDate.DaysCountInScheduleSinceBegOfYear + 1
		|		
		|		LEFT JOIN CalendarChartData AS DeliveryScheduleScheduledDeliveryDateFirstDayOfNextYear
		|		ON DeliveryScheduleScheduledDeliveryDateFirstDayOfNextYear.Calendar = SupplyMethod.DeliverySchedule
		|		AND DeliveryScheduleScheduledDeliveryDateFirstDayOfNextYear.Year = SupplyMethod.PlannedDeliveryDateYear + 1
		|		AND DeliveryScheduleScheduledDeliveryDateFirstDayOfNextYear.DaysCountInScheduleSinceBegOfYear = 1
		|INDEX BY
		|	PeriodBoundary
		|;
		|
		|/////////////////////////////////////
		|DROP CalendarChartData;
		|DROP DataOfSupplyMethods";
		
	ItemFields = "";
	If GetOption = "BY_TOWARE" Then
		ItemFields =
			"Table.Products AS Products,
			|Table.Characteristic AS Characteristic,
			|Table.Warehouse AS Warehouse,";
	EndIf;
	QueryText = StrReplace(QueryText, "&ItemFields,", ItemFields);
	
	Texts.Add(QueryText);
	
	If GetOption = "BY_TOWARE" Then
		
		If GetFunctionalOption("UseGoodsQualityControl") Then
			
			Text =
				"SELECT
				|	Table.Products AS Products,
				|	Table.Characteristic AS Characteristic,
				|	Table.Warehouse AS Warehouse,
				|	CalculationOfControlPeriodsOverridable.DateFound AS PeriodBoundary
				|INTO LimitsOfSecurityPeriod
				|FROM
				|	BoundariesOfPeriodOfProvisionWithoutTakingIntoAccountTimingOfControl AS Table
				|		
				|		LEFT JOIN CalculationOfControlPeriodsOverridable ON TRUE
				|WHERE
				|	Table.PeriodBoundary <> DATETIME(1, 1, 1)
				|		AND CalculationOfControlPeriodsOverridable.DateFound <> DATETIME(1, 1, 1)
				|INDEX BY
				|	Products, Characteristic, Warehouse";
				
			Substitutions = AddToDateAccordingToEnterpriseCalendar(
				"Table.PeriodBoundary",
				"CASE
				|	WHEN Table.Products.ControlQualityOfReceivedGoods
				|			AND CAST(Table.Warehouse AS Catalog.Warehouses).ControlQualityOfReceivedGoods
				|		THEN Table.Products.TermOfQualityControl
				|	ELSE 0
				|END");
			
			Text = StrReplace(Text, "CalculationOfControlPeriodsOverridable.DateFound", Substitutions.Field);
			Text = StrReplace(Text, "LEFT JOIN CalculationOfControlPeriodsOverridable ON TRUE", Substitutions.Joins);
			
		Else
			
			Text =
				"SELECT
				|	Table.Products AS Products,
				|	Table.Characteristic AS Characteristic,
				|	Table.Warehouse AS Warehouse,
				|	Table.PeriodBoundary AS PeriodBoundary
				|INTO LimitsOfSecurityPeriod
				|FROM
				|	BoundariesOfPeriodOfProvisionWithoutTakingIntoAccountTimingOfControl AS Table
				|WHERE
				|	Table.PeriodBoundary <> DATETIME(1, 1, 1)
				|INDEX BY
				|	Products, Characteristic, Warehouse";
			
		EndIf;
		
	Else
		
		Text =
			"SELECT
			|	Table.MainWayToEnsure AS MainWayToEnsure,
			|	Table.PeriodBoundary AS PeriodBoundary
			|INTO LimitsOfSecurityPeriod
			|FROM
			|	BoundariesOfPeriodOfProvisionWithoutTakingIntoAccountTimingOfControl AS Table
			|WHERE
			|	Table.PeriodBoundary <> DATETIME(1, 1, 1)
			|INDEX BY
			|	MainWayToEnsure";
		
	EndIf;
	Texts.Add(Text);
	Texts.Add("DROP BoundariesOfPeriodOfProvisionWithoutTakingIntoAccountTimingOfControl");
	
	QueryText = StrConcat(Texts, Common.QueryBatchSeparator());
	
	Return QueryText;
	
EndFunction

// Executes a query of a temp table containing data on the nearest provision cycle for the specified provision methods.
// 
// Parameters:
//  TempTablesManager - TempTablesManager - temporary table Manager
//  NameOfMethodsTable - String - the name of the temp table that contains information about the security methods.
//  TableName - String - the name of the temp table for recording the calculation result in the temp table manager.
Procedure TempTableNearestCycleBySupplyMethods(TempTablesManager, NameOfMethodsTable = "Catalog.ProcurementStrategies", TableName = "NextCycleBySupplyMethods") Export
	
	Query = New Query();
	Query.TempTablesManager = TempTablesManager;
	Query.SetParameter("BeginningOfThisDay", BegOfDay(CurrentSessionDate()));
	
	Texts = New Array();
	Text = TempTableYearsOfEnterpriseSchedule();
	Texts.Add(Text);
	
	Text =
		"SELECT
		|	Table.SupplyMethod AS MainWayToEnsure,
		|	ISNULL(MethodTable.OrderFulfillmentPeriod, 0) AS OrderFulfillmentPeriod,
		|	CalculationOfDeliveryDateOverridable.DeliveryDateByReorderPoint AS DeliveryDateByReorderPoint,
		|	CalculationOfDeliveryDateOverridable.PlannedDeliveryDate AS PlannedDeliveryDate
		|INTO DeliveryDates
		|FROM
		|	SupplyMethods AS Table
		|		
		|		LEFT JOIN Catalog.ProcurementStrategies AS MethodTable
		|		ON MethodTable.Ref = Table.SupplyMethod
		|		
		|		LEFT JOIN CalculationOfDeliveryDateOverridable ON TRUE
		|INDEX BY
		|	MainWayToEnsure";
	
	Substitutions = SubstitutionsOfPlannedDeliveryDate(
		"Table.SupplyMethod",
		"&BeginningOfThisDay");
	
	Text = StrReplace(Text, "CalculationOfDeliveryDateOverridable.PlannedDeliveryDate", Substitutions.Field);
	Text = StrReplace(Text, "CalculationOfDeliveryDateOverridable.DeliveryDateByReorderPoint",
		Substitutions.DeliveryDateFieldAtOrderPoint);
	Text = StrReplace(Text, "LEFT JOIN CalculationOfDeliveryDateOverridable ON TRUE", Substitutions.Joins);
	
	Texts.Add(Text);
	
	Text =
		"SELECT
		|	Table.MainWayToEnsure AS MainWayToEnsure,
		|	ISNULL(
		|		MethodTable.GenerateOrdersOnSchedule, FALSE) AS GenerateOrdersOnSchedule,
		|	ISNULL(
		|		MethodTable.GenerateOrdersByReorderPoint, TRUE) AS GenerateOrdersByReorderPoint,
		|	ISNULL(
		|		MethodTable.DeliverySchedule, VALUE(Catalog.Calendars.EmptyRef)) AS DeliverySchedule,
		|	ISNULL(MethodTable.CoveredPeriodOption, VALUE(Enum.CoveredPeriodOptions.NoExpiration)) AS CoveredPeriodOption,
		|	Table.DeliveryDateByReorderPoint AS DeliveryDateByReorderPoint,
		|	Table.PlannedDeliveryDate AS PlannedDeliveryDate,
		|	CalculationOfOrderDateOverridable.DateFound AS PlannedOrderDate
		|INTO DeliveryDatesAndOrderDate
		|FROM
		|	DeliveryDates AS Table
		|		
		|		LEFT JOIN Catalog.ProcurementStrategies AS MethodTable
		|		ON MethodTable.Ref = Table.MainWayToEnsure
		|		
		|		LEFT JOIN CalculationOfOrderDateOverridable ON TRUE
		|INDEX BY
		|	MainWayToEnsure";
	
	Substitutions = AddToDateAccordingToEnterpriseCalendar("Table.PlannedDeliveryDate", "-Table.OrderFulfillmentPeriod");
	
	Text = StrReplace(Text, "CalculationOfOrderDateOverridable.DateFound", Substitutions.Field);
	Text = StrReplace(Text, "LEFT JOIN CalculationOfOrderDateOverridable ON TRUE", Substitutions.Joins);
	
	Texts.Add(Text);
	
	Text =
		"SELECT
		|	Table.MainWayToEnsure AS MainWayToEnsure,
		|	Table.PlannedDeliveryDate AS PlannedDeliveryDate
		|INTO PlannedDeliveryDateIsTemporary
		|FROM
		|	DeliveryDatesAndOrderDate AS Table
		|WHERE
		|	Table.GenerateOrdersOnSchedule
		|INDEX BY
		|	MainWayToEnsure";
	
	Texts.Add(Text);
	
	Text = TempTableBoundariesOfSupplyPeriodAccordingToPlannedDeliveryDateTable("BYTHEIRABILITY");
	Texts.Add(Text);
	
	Text =
		"SELECT
		|	Table.MainWayToEnsure AS MainWayToEnsure,
		|	Table.GenerateOrdersOnSchedule AS GenerateOrdersOnSchedule,
		|	Table.GenerateOrdersByReorderPoint AS GenerateOrdersByReorderPoint,
		|	Table.DeliverySchedule AS DeliverySchedule,
		|	Table.CoveredPeriodOption AS CoveredPeriodOption,
		|	Table.DeliveryDateByReorderPoint AS DeliveryDateByReorderPoint,
		|	Table.PlannedDeliveryDate AS DeliveryDateOnSchedule,
		|	ISNULL(Boundaries.PeriodBoundary, DATETIME(1, 1, 1)) AS CoveredPeriodBoundaryOnSchedule,
		|	Table.PlannedDeliveryDate AS PlannedDeliveryDate,
		|	Table.PlannedOrderDate AS PlannedOrderDate
		|INTO DeliveryDatesOfOrderAndBoundaryOfPeriodAccordingToSchedule
		|FROM
		|	DeliveryDatesAndOrderDate AS Table
		|		
		|		LEFT JOIN LimitsOfSecurityPeriod AS Boundaries
		|		ON Boundaries.MainWayToEnsure = Table.MainWayToEnsure
		|INDEX BY
		|	MainWayToEnsure";
	Texts.Add(Text);
	
	Texts.Add("DROP PlannedDeliveryDateIsTemporary");
	Texts.Add("DROP LimitsOfSecurityPeriod");
	
	Text =
		"SELECT
		|	Table.MainWayToEnsure AS MainWayToEnsure,
		|	Table.DeliveryDateByReorderPoint AS PlannedDeliveryDate
		|INTO PlannedDeliveryDateIsTemporary
		|FROM
		|	DeliveryDatesAndOrderDate AS Table
		|WHERE
		|	Table.GenerateOrdersByReorderPoint
		|		AND Table.CoveredPeriodOption <> VALUE(Enum.CoveredPeriodOptions.UpToTheNextDeliveryDate)
		|INDEX BY
		|	MainWayToEnsure";
	Texts.Add(Text);
	
	Text = TempTableBoundariesOfSupplyPeriodAccordingToPlannedDeliveryDateTable("BYTHEIRABILITY");
	Texts.Add(Text);
	
	Text =
		"SELECT
		|	Table.MainWayToEnsure AS Ref,
		|	Table.GenerateOrdersOnSchedule AS GenerateOrdersOnSchedule,
		|	Table.GenerateOrdersByReorderPoint AS GenerateOrdersByReorderPoint,
		|	Table.DeliverySchedule AS DeliverySchedule,
		|	Table.CoveredPeriodOption AS CoveredPeriodOption,
		|	Table.DeliveryDateOnSchedule AS DeliveryDateOnSchedule,
		|	Table.CoveredPeriodBoundaryOnSchedule AS CoveredPeriodBoundaryOnSchedule,
		|	Table.PlannedOrderDate AS PlannedOrderDate,
		|	CASE
		|		WHEN Table.GenerateOrdersOnSchedule AND Table.PlannedOrderDate > DATETIME(1, 1, 1)
		|			THEN DATEDIFF(&BeginningOfThisDay, Table.PlannedOrderDate, DAY)
		|		ELSE 0
		|	END AS DaysBeforePlannedOrder,
		|	Table.DeliveryDateByReorderPoint AS DeliveryDateByReorderPoint,
		|	CASE
		|		WHEN Table.CoveredPeriodOption = VALUE(Enum.CoveredPeriodOptions.UpToTheNextDeliveryDate)
		// When ordering before the date of the next delivery before the date of the order, the date of the next delivery shall be the date of the next delivery.
		|			THEN Table.DeliveryDateOnSchedule
		|		ELSE ISNULL(Boundaries.PeriodBoundary, DATETIME(1, 1, 1))
		|	END AS CoveredPeriodBoundaryByReorderPoint,
		|	CASE
		|		WHEN Table.GenerateOrdersOnSchedule
		|				AND CASE
		|					WHEN Table.GenerateOrdersOnSchedule AND Table.PlannedOrderDate > DATETIME(1, 1, 1)
		|						THEN DATEDIFF(&BeginningOfThisDay, Table.PlannedOrderDate, DAY)
		|					ELSE 0
		|				END <=0
		// Planned formation of orders.
		|			THEN 1
		|		WHEN Table.GenerateOrdersOnSchedule AND NOT Table.GenerateOrdersByReorderPoint
		// Wait for the order date to arrive.
		|			THEN 2
		// Reached the reorder point.
		|		ELSE 0
		|	END DemandConversionOption,
		|	CASE
		|		WHEN Table.GenerateOrdersOnSchedule
		|				AND CASE
		|					WHEN Table.GenerateOrdersOnSchedule AND Table.PlannedOrderDate > DATETIME(1, 1, 1)
		|						THEN DATEDIFF(&BeginningOfThisDay, Table.PlannedOrderDate, DAY)
		|					ELSE 0
		|				END <=0
		// Planned formation of orders.
		|			THEN Table.DeliveryDateOnSchedule
		|		WHEN Table.GenerateOrdersOnSchedule AND NOT Table.GenerateOrdersByReorderPoint
		// Wait for the order date to arrive.
		|			THEN Table.DeliveryDateOnSchedule
		// Reached the reorder point.
		|		ELSE Table.DeliveryDateByReorderPoint
		|	END ShipmentDate,
		|	CASE
		|		WHEN Table.GenerateOrdersOnSchedule
		|				AND CASE
		|					WHEN Table.GenerateOrdersOnSchedule AND Table.PlannedOrderDate > DATETIME(1, 1, 1)
		|						THEN DATEDIFF(&BeginningOfThisDay, Table.PlannedOrderDate, DAY)
		|					ELSE 0
		|				END <=0
		// Planned formation of orders.
		|			THEN Table.CoveredPeriodBoundaryOnSchedule
		|		WHEN Table.GenerateOrdersOnSchedule AND NOT Table.GenerateOrdersByReorderPoint
		// Wait for the order date to arrive.
		|			THEN Table.CoveredPeriodBoundaryOnSchedule
		// Reached the reorder point.
		|		ELSE
		|			CASE
		|				WHEN Table.CoveredPeriodOption = VALUE(Enum.CoveredPeriodOptions.UpToTheNextDeliveryDate)
		|					THEN Table.DeliveryDateOnSchedule
		|				ELSE ISNULL(Boundaries.PeriodBoundary, DATETIME(1, 1, 1))
		|			END
		|	END BoundaryOfCoveredPeriod
		|INTO TableNameOverridable
		|FROM
		|	DeliveryDatesOfOrderAndBoundaryOfPeriodAccordingToSchedule AS Table
		|		
		|		LEFT JOIN LimitsOfSecurityPeriod AS Boundaries
		|		ON Boundaries.MainWayToEnsure = Table.MainWayToEnsure
		|INDEX BY
		|	Ref";
	Text = StrReplace(Text, "TableNameOverridable", TableName);
	Texts.Add(Text);
	
	Texts.Add("DROP PlannedDeliveryDateIsTemporary");
	Texts.Add("DROP LimitsOfSecurityPeriod");
	Texts.Add("DROP DeliveryDates");
	Texts.Add("DROP DeliveryDatesOfOrderAndBoundaryOfPeriodAccordingToSchedule");
	Texts.Add("DROP DeliveryDatesAndOrderDate");
	Texts.Add("DROP YearsOfEnterpriseScheduleTemporary");
	Texts.Add("DROP YearsOfEnterpriseSchedule");
	
	Text = StrConcat(Texts, Common.QueryBatchSeparator());
	Query.Text = StrReplace(Text, "Catalog.ProcurementStrategies", NameOfMethodsTable);
	Query.Execute();
	
EndProcedure

// Prepares the Query Text of a temp table containing the number of days in the interval between two dates on the calendar.
//
// Returns:
// String - query text.
Function TempTableResultsOfCalculationOfNumberOfDaysInInterval() Export
	
	Text =
		"SELECT DISTINCT
		|	Table.Calendar AS Ref
		|INTO DifferentCalendars
		|FROM
		|	ToSearchForNumberOfDaysInInterval AS Table
		|WHERE
		|	Table.Calendar <> VALUE(Catalog.Calendars.EmptyRef)
		|INDEX BY
		|	Ref
		|;
		|
		|/////////////////////////////////////////
		|SELECT
		|	CalendarSchedules.Calendar AS Calendar,
		|	CalendarSchedules.Year AS Year,
		|	MAX(CalendarSchedules.DaysCountInScheduleSinceBegOfYear) DaysCount
		|INTO YearsOfScheduleTemporary
		|FROM
		|	DifferentCalendars AS Calendars
		|		INNER JOIN InformationRegister.CalendarSchedules AS CalendarSchedules
		|		ON CalendarSchedules.Calendar = Calendars.Ref
		|GROUP BY
		|	CalendarSchedules.Calendar,
		|	CalendarSchedules.Year
		|INDEX BY
		|	Calendar, Year
		|;
		|
		|/////////////////////////////////////////
		|SELECT
		|	Years.Calendar AS Calendar,
		|	Years.Year AS Year,
		|	MAX(Years.DaysCount) AS NumberOfWorkdaysPerYear,
		|	SUM(ISNULL(PreviousYears.DaysCount, 0))
		|		+ MAX(Years.DaysCount) AS NumberOfWorkdaysPerYearIsCumulative
		|INTO ScheduleYears
		|FROM
		|	YearsOfScheduleTemporary AS Years
		|		LEFT JOIN YearsOfScheduleTemporary AS PreviousYears
		|		ON PreviousYears.Calendar = Years.Calendar
		|		AND PreviousYears.Year < Years.Year
		|GROUP BY
		|	Years.Calendar,
		|	Years.Year
		|INDEX BY
		|	Calendar, Year
		|;
		|
		|////////////////////////////////////
		|SELECT
		|	Table.Calendar AS Calendar,
		|	Table.PeriodStartDate AS PeriodStartDate,
		|	Table.PeriodEndDate AS PeriodEndDate,
		|	CASE
		|		WHEN Table.YearOfStartInterval = Table.YearOfEndOfInterval
		|			THEN
		|				ScheduleForEndOfInterval.DaysCountInScheduleSinceBegOfYear
		|					- IntervalStartSchedule.DaysCountInScheduleSinceBegOfYear
		|		ELSE
		|			ScheduleForEndOfInterval.DaysCountInScheduleSinceBegOfYear
		|				+ ScheduleOfCumulativeStartInterval.NumberOfWorkdaysPerYear
		|				- IntervalStartSchedule.DaysCountInScheduleSinceBegOfYear
		|	END
		|		+ CASE
		|			WHEN ScheduleForEndOfInterval.DayAddedToSchedule
		|				THEN 0
		|			ELSE 1
		|		END
		|		- CASE
		|			WHEN IntervalStartSchedule.DayAddedToSchedule
		|				THEN 0
		|			ELSE 1
		|		END
				// days of full years between dates
		|		+ CASE
		|			WHEN Table.YearOfStartInterval + 1 < Table.YearOfEndOfInterval
		|				THEN
							// the number is cumulative in the previous year ending
		|					ScheduleOfCumulativeEndOfInterval.NumberOfWorkdaysPerYearIsCumulative
		|						- ScheduleOfCumulativeEndOfInterval.NumberOfWorkdaysPerYear
								// the number is cumulative in the year of commencement
		|						- ScheduleOfCumulativeStartInterval.NumberOfWorkdaysPerYearIsCumulative
		|				ELSE 0
		|		END AS DaysCount
		|INTO ResultsOfCalculatingNumberOfDaysInInterval
		|FROM
		|	ToSearchForNumberOfDaysInInterval AS Table
		|		
		|		LEFT JOIN InformationRegister.CalendarSchedules AS IntervalStartSchedule
		|		ON IntervalStartSchedule.Calendar = Table.Calendar
		|			AND IntervalStartSchedule.ScheduleDate = Table.PeriodStartDate
		|			AND IntervalStartSchedule.Year = Table.YearOfStartInterval
		|			
		|		LEFT JOIN InformationRegister.CalendarSchedules AS ScheduleForEndOfInterval
		|		ON ScheduleForEndOfInterval.Calendar = Table.Calendar
		|			AND ScheduleForEndOfInterval.ScheduleDate = Table.PeriodEndDate
		|			AND ScheduleForEndOfInterval.Year = Table.YearOfEndOfInterval
		|			
		|		LEFT JOIN ScheduleYears AS ScheduleOfCumulativeStartInterval
		|		ON ScheduleOfCumulativeStartInterval.Calendar = Table.Calendar
		|			AND ScheduleOfCumulativeStartInterval.Year = Table.YearOfStartInterval
		|			
		|		LEFT JOIN ScheduleYears AS ScheduleOfCumulativeEndOfInterval
		|		ON ScheduleOfCumulativeEndOfInterval.Calendar = Table.Calendar
		|			AND ScheduleOfCumulativeEndOfInterval.Year = Table.YearOfEndOfInterval
		|WHERE
		|	NOT IntervalStartSchedule.Calendar IS NULL
		|		AND NOT ScheduleForEndOfInterval.Calendar IS NULL
		|		AND Table.YearOfStartInterval <= Table.YearOfEndOfInterval
		|
		|UNION ALL
		|
		|SELECT
		|	Table.Calendar AS Calendar,
		|	Table.PeriodStartDate AS PeriodStartDate,
		|	Table.PeriodEndDate AS PeriodEndDate,
		|	DATEDIFF(Table.PeriodStartDate, Table.PeriodEndDate, DAY)
		|FROM
		|	ToSearchForNumberOfDaysInInterval AS Table
		|WHERE
		|	Table.Calendar = VALUE(Catalog.Calendars.EmptyRef)
		|INDEX BY
		|	Calendar, PeriodStartDate, PeriodEndDate
		|;
		|
		|////////////////////////////////////////
		|DROP DifferentCalendars;
		|DROP YearsOfScheduleTemporary;
		|DROP ScheduleYears";
		
	Return Text;
	
EndFunction

#EndRegion

// Constructor of parameters for setting actions in document lists.
// Returns:
//  Structure - structure with fields:
//   * NeedQuestion - Boolean - It is necessary to ask a question about shipment by one date.
//   * DateWhenTheNewLinesWereShipped - Undefined, Date - Shipping date for new rows when splitting rows as a result of filling in actions.
//   * UncheckShipByOneDateFlag - Boolean - It is necessary to remove the flag of shipment by one date.
//   * FillShippingDateWithSingleDate - Boolean - It is necessary to fill in the shipment date with one date.
//   * ExecutionParameters - Array of See StructureOrdersAndEmbeddingParameters
//   * ActionCode - String - "ACTION TO UNLOAD", "ACTION TO SUPPORT", etc.
Function NewParametersForExecutingCommandsAndSettingActions() Export
	
	Result = New Structure();
	Result.Insert("NeedQuestion", False);
	Result.Insert("DateWhenTheNewLinesWereShipped", Undefined);
	Result.Insert("UncheckShipByOneDateFlag", False);
	Result.Insert("FillShippingDateWithSingleDate", True);
	Result.Insert("ExecutionParameters", New Array());
	Result.Insert("ActionCode", "");
	
	Return Result;
	
EndFunction

// Constructor of parameters for setting actions in document lists for an array of links that have the same embedding parameters in the software.
// Returns:
//  Structure - structure with fields:
//   * Orders - Array of DocumentRef - array of orders.
//   * EmbeddingParameters - See ProvisionInDocumentsServer.AvailableRemainingEmbeddingOptions
Function StructureOrdersAndEmbeddingParameters() Export
	
	Return New Structure("Orders,EmbeddingParameters", New Array(), AvailableRemainingEmbeddingOptions());
	
EndFunction

// Parameters for creating a securing order for the creation mechanism based on.
// 
// Parameters:
//  CreationParameters - Structure - structure for filling in additional parameters
// Returns:
//  Structure - structure with fields:
//   * NameOfDocumentManager - String - the type of order to create based on.
//   * FormName - String - name of the form to open.
Function ParametersForCreatingSecuringOrder(CreationParameters) Export
	
	CreationParameters.Insert("NameOfDocumentManager");
	CreationParameters.Insert("ParametersAreDescribedInCommonModule", False);
	CreationParameters.Insert("FormName");
	Return CreationParameters;
	
EndFunction

// Parameters for creating a securing order for the creation mechanism based on.
// 
// Returns:
//  Structure - structure with fields:
//   * ItemsTypes - Array of EnumRef.ItemsTypes - selection by Product type
//   * OneWarehouse - Boolean
//   * NameOfDocumentManager - String - Manager's name.
//
Function ProductSelectionParametersForCreatingSecuringOrder() Export
	
	Result = New Structure();
	Result.Insert("ItemsTypes", New Array());
	Result.Insert("OneWarehouse", False);
	Result.Insert("NameOfDocumentManager", "");
	
	Return Result;
	
EndFunction

// If the background inventory allocation task is not running, then it starts it.
Procedure CheckToRunBackgroundInventoryAllocationJob() Export

	If InventoryAllocation.BlockInventoryAllocation() Then
		Return;
	EndIf;
	
	SetPrivilegedMode(True);
	
	DeferredJobs.Run("JobsForAllocatingInventory");
	
EndProcedure

// Fills in the warehouse and the date of shipment if the security option is set in the order lines earlier.
//  Parameters:
//   Changes - ValueTable - a table with changes after filling in the security option.
//
Procedure FillInWarehouseAndShipmentDateWhenChangeWasPassedEarlier(Changes) Export
	
	FoundRows = Changes.FindRows(New Structure("SupplyOption", Enums.SupplyOptions.TransferedEarlier));
	For Each Item In FoundRows Do
		Item.String.Warehouse = Catalogs.Warehouses.EmptyRef();
		Item.String.DateOfShipment = '00010101';
	EndDo;
	
EndProcedure

// Parameters:
//  Ref - AnyRef - a link to an order that has built-in commands for creating an assignment adjustment
//  AdditionalParameters - Structure - Structure with fields:
//  * IDInStorage - String - A unique identifier to put the goods of the document in the storage
//  * ThisIsWithdrawalOfReserve - Boolean - True if the data needs to be obtained for a reserve withdrawal operation, False if for a reservation operation
//  Returns:
//   Structure - Document data required to execute the assignment adjustment creation command
Function DocumentDataForCreatingDestinationAdjustment(Ref, AdditionalParameters) Export
	ManagerOfDocument = Common.ObjectManagerByRef(Ref);
	Return ManagerOfDocument.DocumentDataForCreatingDestinationAdjustment(Ref, AdditionalParameters);
EndFunction

Function PerformActionForMultipleOrderTypes(Parameters) Export
	
	ProcedureParameters = New Structure();
	
	ProcedureParameters.Insert("ActionCode", Parameters.ActionCode);
	FillParameters0 = Undefined;
	If Parameters.NeedQuestion Then
		FillParameters0 = New Structure();
		FillParameters0.Insert("UncheckShipByOneDateFlag", Parameters.UncheckShipByOneDateFlag);
		FillParameters0.Insert("FillShippingDateWithSingleDate", Parameters.FillShippingDateWithSingleDate);
	EndIf;
	ProcedureParameters.Insert("FillParameters", FillParameters0);
	
	ProcedureParameters.Insert("Orders", Parameters.ExecutionParameters[0].Orders);
	ProcedureParameters.Insert("EmbeddingParameters", Parameters.ExecutionParameters[0].EmbeddingParameters);
	
	ResultOfActions = PerformActionForOrdersAfterQuestion(ProcedureParameters);
	
	ProcedureParameters.Insert("ActionCode", Parameters.ActionCode);
	FillParameters1 = Undefined;
	If Parameters.NeedQuestion Then
		FillParameters1 = New Structure();
		FillParameters1.Insert("UncheckShipByOneDateFlag", Parameters.UncheckShipByOneDateFlag);
		FillParameters1.Insert("FillShippingDateWithSingleDate", Parameters.FillShippingDateWithSingleDate);
	EndIf;
	ProcedureParameters.Insert("FillParameters", FillParameters1);
	
	ProcedureParameters.Insert("Orders", Parameters.ExecutionParameters[1].Orders);
	ProcedureParameters.Insert("EmbeddingParameters", Parameters.ExecutionParameters[1].EmbeddingParameters);
	
	ResultOfActionsIsCur = PerformActionForOrdersAfterQuestion(ProcedureParameters);
	
	CommonClientServer.SupplementArray(ResultOfActions.ErrorList,
		ResultOfActionsIsCur.ErrorList);
	ResultOfActions.QuantityProcessed = ResultOfActions.QuantityProcessed
		+ ResultOfActionsIsCur.QuantityProcessed;
	Return ResultOfActions;
	
EndFunction

// Complements the structure of the result of the provision actions in the list, used if the list is processed
// in chunks.
//
// Parameters:
//  Receiver - See SupplyInDocumentsServerCall.PerformActionInOrderList
//  Source - See SupplyInDocumentsServerCall.PerformActionInOrderList
//
Procedure CompleteResultsOfActionsInOrderList(Receiver, Source) Export
	
	CommonClientServer.SupplementArray(Receiver.ErrorList, Source.ErrorList);
	Receiver.QuantityProcessed = Receiver.QuantityProcessed + Source.QuantityProcessed;
	
EndProcedure

// Handler for the command to fill in the "Separate" flag on the shipment order form.
//
// Parameters:
//  ActionCode - String - the code of the action being performed:
//                         is "FLAG_INDIVIDED", "FLAG_INDIVIDED", "ACTION_INDIVIDED",
//                         "ACTION_INDIVIDED", "ACTION_INDIVIDED".
//  Form - ClientApplicationForm - the form in the table part of which you need to run the command.
//  SelectedRows - Array - contains the row IDs of the collection to perform the action on.
//  SkipShipping - Boolean - True, if the command does not need to be executed in the drains with the "Ship" action.
// 
// Returns:
//  Structure - a structure containing a table of changes.
//
Function SetActionApart(ActionCode, Form, SelectedRows, SkipShipping = True) Export
	
	EmbeddingParameters = Form.AvailableRemainingEmbeddingOptions;
	CollectionOnForm = ProvisionInDocumentsClientServer.CollectionOnForm(Form, EmbeddingParameters);
	
	ChangesTable = New ValueTable();
	ChangesTable.Columns.Add("Id");
	ChangesTable.Columns.Add("String");
	
	For Each RowID In SelectedRows Do
		
		String = CollectionOnForm.FindByID(RowID);
		
		If ActionCode = "FLAG_UNITED" Then
			
			If String.ItemsType = Enums.ItemsTypes.ReusablePackage
					Or String.ItemsType = Enums.ItemsTypes.OperationService
					Or String.SupplyOption = Enums.SupplyOptions.Ship And SkipShipping Then
						
						Continue;
						
			EndIf;
			String.WithAssignment = True;
			String.SupplyOption = ProvisionInDocumentsClientServer.WithAssignmentOnChange(
				String.WithAssignment,
				String.SupplyOption,
				String.ItemsType);
			
			NewRow = ChangesTable.Add();
			NewRow.String = String;
			NewRow.Id = String.GetID();
			
		ElsIf ActionCode = "FLAG_NOTABLE" Then
			
			If String.SupplyOption = Enums.SupplyOptions.Ship And SkipShipping Then
				
				Continue;
				
			EndIf;
			
			String.WithAssignment = False;
			String.SupplyOption = ProvisionInDocumentsClientServer.WithAssignmentOnChange(
				String.WithAssignment,
				String.SupplyOption,
				String.ItemsType);
			
			NewRow = ChangesTable.Add();
			NewRow.String = String;
			NewRow.Id = String.GetID();
			
		EndIf;
		
	EndDo;
	
	Result = New Structure("ChangesTable", ChangesTable);
	Return Result;
	
EndFunction

// Constructor for the structure of the result of setting actions in an order
// 
// Returns:
//  Structure - structure with fields:
//   * AddressOfChanges - String - the address of the changes to be transferred to the table part.
//   * AskingAboutFillingWithWholePackages - Boolean - indicates whether you need to ask a question about shipping in whole
//                                                          or fractional packages.
//   * UncheckShipByOneDateFlag - Boolean - the need to remove the Ship one date flag, based on the changes.
//   * RemoveFlagShipOneDateInWholePackages - Boolean - the need to remove the Ship one date flag,
//                                                             based on changes when filling in whole packages.
//   * FillShippingDateWithSingleDate - Boolean - indicates that you need to fill in the shipment date in the order header.
//   * FillShippingDateWithOneDateWholePackages - Boolean - indicates that you need to fill in the shipment date in 
//                                                                the order header when filling in whole packages.
//   * TheShipmentDateOfAllLinesIsASingleDate - Date - the date of shipment from the order header, if any.
//   * DateOfShipmentOfCompletedLines  - Date - date of shipment of the modified lines.
//
Function ProvidingSetActionResultStructure() Export
	
	Result = New Structure();
	Result.Insert("AddressOfChanges",                                  Undefined);
	Result.Insert("AskingAboutFillingWithWholePackages",       False);
	Result.Insert("UncheckShipByOneDateFlag",                    False);
	Result.Insert("RemoveFlagShipOneDateInWholePackages",    False);
	Result.Insert("FillShippingDateWithSingleDate",                 False);
	Result.Insert("FillShippingDateWithOneDateWholePackages", False);
	Result.Insert("TheShipmentDateOfAllLinesIsASingleDate",                 Undefined);
	Result.Insert("DateOfShipmentOfCompletedLines",                    Undefined);
	
	Return Result;
	
EndFunction

// Handler of the action setup command in the shipment order form.
//
// Parameters:
//  ActionCode - String - the code of the action being performed:
//                         is "FLAG_ SEPARATELY", "FLAG_ SEPARATELY", "ACTION_TO ENSURE",
//                         "ACTION_TO PROVIDE", "ACTION_TO RESERVE", "ACTION_TO LOAD",
//                         "ACTION_TO TRANSFER", "ROLLBACK ACTION_TO LOAD".
//  Form - ClientApplicationForm - the form in the table part of which you need to run the command.
//  SelectedRows - Array - contains the row IDs of the collection to perform the action on.
//
// Returns:
//  See ProvidingSetActionResultStructure
//
Function SetAction(ActionCode, Form, SelectedRows) Export
	
	Changes = ChangesToSetActions(ActionCode, Form, SelectedRows);
	
	Result = ProvidingSetActionResultStructure();
	Result.Insert("ChangesTable", Undefined);
	
	NeedToAskQuestion_ = Changes.TableOfChangesByWholePackages <> Undefined
		Or Changes.UncheckShipByOneDateFlag;
	
	If Not NeedToAskQuestion_ Then
		
		SetActionsFromTable(Form, Changes.ChangesTable);
		Result.ChangesTable = Changes.ChangesTable;
		Result.FillShippingDateWithSingleDate = Changes.FillShippingDateWithSingleDate;
		
	Else
		
		AddressOfChanges = PutToTempStorage(Changes, Form.UUID);
		Result.AddressOfChanges = AddressOfChanges;
		Result.AskingAboutFillingWithWholePackages = Changes.TableOfChangesByWholePackages <> Undefined;
		FillPropertyValues(Result, Changes,
			"UncheckShipByOneDateFlag,
			|RemoveFlagShipOneDateInWholePackages,
			|FillShippingDateWithSingleDate,
			|FillShippingDateWithOneDateWholePackages,
			|TheShipmentDateOfAllLinesIsASingleDate,
			|DateOfShipmentOfCompletedLines");
		
	EndIf;
	
	Return Result;
	
EndFunction

// Handler of the action setup command in the shipment order form.
//
// Parameters:
//  Response - String - the symbol of the user's choice when answering questions when filling out the provision
//                   with "
//                   FRACTIONAL PACKAGINGS"," SHIP_PARTICULATE_UNIT_UNIT_UNIT_UNIT_UNIT_UNIT_UNIT_UNIT_UNIT_UNIT_UNIT_UNIT_UNIT_UNIT_UNIT_UNIT_UNIT_UNIT_UNIT_UNIT_UNIT_UNIT_UNIT_UNIT_UNIT_UNIT_UNIT_UNIT_UNIT_UNIT_UNIT_UNIT_UNIT_UNIT_UNIT_UNIT_UNIT_UNIT_UNIT_UNIT_UNIT_UNIT_UNIT_UNIT_UNIT_UNIT_UNIT_UNIT_UNIT_UNIT_UNIT_UNIT_UNIT_UNIT_UNIT_UNIT_UNIT_UNIT_UNIT_UNIT_UNIT_UNIT_UNIT_UNIT_UNIT_UNIT_UNIT"
//  Result - See ProvidingSetActionResultStructure
//  Form - ClientApplicationForm - the form in the tabular part of which you need to run the command to fill in the security option.
//
// Returns:
//  See ProvidingSetActionResultStructure
//
Function SetActionAfterQuestion(Response, Result, Form) Export
	
	Changes = GetFromTempStorage(Result.AddressOfChanges);
	
	DeleteFromTempStorage(Result.AddressOfChanges);
	
	ChangesTable = Undefined;
	If Response = "FractionalPackings"
			Or Response = "SHIPPING_PARTICIPATION_PACKAGES"
			Or Response = "SHIPPED_ODATE_DROBNY_PACKAGES" Then
		ChangesTable = Changes.ChangesTable;
	Else
		ChangesTable = Changes.TableOfChangesByWholePackages;
	EndIf;
	
	SetActionsFromTable(Form, ChangesTable);
	
	UncheckShipByOneDateFlag = Response = "SHIPPING_PARTICIPATION_PACKAGES"
		Or Response = "SHIPPING_PARTICELS_SELECT_PACKAGES";
		
	FillShippingDateWithSingleDate = Result.FillShippingDateWithSingleDate;
	If Response = "INTEGERS_UPACKAGES" Or Response = "SHIPPING_PARTICELS_SELECT_PACKAGES" Then
		FillShippingDateWithSingleDate = Result.FillShippingDateWithOneDateWholePackages;
	EndIf;
	FillShippingDateWithSingleDate = FillShippingDateWithSingleDate
		Or Response = "SHIPPED_ODATE_DROBNY_PACKAGES"
		Or Response = "SHIPPED_ODATE_SELECT_PACKAGES";
		
	ResultStructure1 = New Structure();
	ResultStructure1.Insert("ChangesTable",                ChangesTable);
	ResultStructure1.Insert("UncheckShipByOneDateFlag",    UncheckShipByOneDateFlag);
	ResultStructure1.Insert("FillShippingDateWithSingleDate", FillShippingDateWithSingleDate);
	
	Return ResultStructure1;
	
EndFunction

// Called from the handler for getting the data for selecting the "Security Options"enumeration.
// It is intended for getting the necessary data on the server.
//
// Parameters:
//  Parameters - Structure - the structure of parameters for getting server data.
//
// Returns:
//  Structure - structure with fields:
//   * UnitOfMeasure - CatalogRef.PackagesAndUnitsOfMeasure - the unit of measurement of the item in the line.
//   * YouNeedToSpecifySeriesInLine - Boolean - the need to specify the series for the order item and warehouse.
//   * AllowableVariance - Number - the permissible deviation of the measured units of measurement, if the item is measured.
//   * PackagingFactor - Number - the packing factor specified in the line.
//   * PostWithoutReserveControl - Boolean - the user has disabled reserve control for the duration of the session
//
Function ProcessingOfDataAcquisitionOfSoftwareOptionSelection(Parameters) Export
	
	SetPrivilegedMode(True);
	UnitOfMeasure = Common.ObjectAttributeValue(Parameters.Products, "UnitOfMeasure");
	
	Query = New Query();
	Query.SetParameter("Products", Parameters.Products);
	Query.SetParameter("Warehouse",        Parameters.Warehouse);
	
	Query.Text =
		"SELECT
		|	TRUE AS YouNeedToSpecifySeriesInLine
		|FROM
		|	Catalog.ItemKinds.BatchAccountingPolicies AS BatchAccountingPolicies
		|WHERE
		|	BatchAccountingPolicies.Warehouse = &Warehouse
		|		AND CAST(&Products AS Catalog.Products).ProductKind = BatchAccountingPolicies.Ref
		|		AND (BatchAccountingPolicies.BatchAccountingPolicy.UseCostAccountingByBatches
		|			OR BatchAccountingPolicies.BatchAccountingPolicy.SpecifyWhenPlanningShipment)";
	
	YouNeedToSpecifySeriesInLine = Not Query.Execute().IsEmpty();
	
	AllowableVariance = Constants.AllowableDeviationOfAutomaticRounding.Get();
	ThisIsADimensionalUnit = Catalogs.PackagesAndUnitsOfMeasure.ThisIsADimensionalUnit(Parameters.Package, "");
	PackagingFactor = 1;
	If ValueIsFilled(Parameters.Package) Then
		PackagingFactor = Catalogs.PackagesAndUnitsOfMeasure.PackagingFactor(
			Parameters.Package,
			Parameters.Products);
	EndIf;
	
	Result = New Structure();
	Result.Insert("UnitOfMeasure", UnitOfMeasure);
	Result.Insert("YouNeedToSpecifySeriesInLine", YouNeedToSpecifySeriesInLine);
	Result.Insert("AllowableVariance", AllowableVariance * ?(ThisIsADimensionalUnit, 1, 0));
	Result.Insert("PackagingFactor", 1 / PackagingFactor);
	PostWithoutReserveControl = SessionParameters.PostWithoutControlOfGoodsReservesUnderOrders;
	Result.Insert("PostWithoutReserveControl", PostWithoutReserveControl);
	
	Return Result;
	
EndFunction

// Handler for changing the security option in the order line.
//
// Parameters:
//  Form - ClientApplicationForm - order form.
//  CurrentRow - Number - id of the document line.
//  
//
// Returns:
//  ValueTable - a table of changes to transfer to the document.
//
Function SupplyOptionOnChange(Form, CurrentRow) Export
	
	EmbeddingParameters = Form.AvailableRemainingEmbeddingOptions;
	CollectionOnForm = ProvisionInDocumentsClientServer.CollectionOnForm(Form, EmbeddingParameters);
	
	CurrentData = CollectionOnForm.FindByID(CurrentRow);
	SecurityOptionSelectedValue = EmbeddingParameters.InternalParameters.SecurityOptionSelectedValue;
	
	ChangesTable = New ValueTable();
	ChangesTable.Columns.Add("Id");
	ChangesTable.Columns.Add("String");
	ChangesTable.Columns.Add("SupplyOption");
	ChangesTable.Columns.Add("IsNewLine", New TypeDescription("Boolean"));
	
	If SecurityOptionSelectedValue.SupplyOption
				= EmbeddingParameters.InternalParameters.SupplyOptionBeforeChange Then
			CurrentData.SupplyOption = EmbeddingParameters.InternalParameters.SupplyOptionBeforeChange;
	Else
	
		NewRow = ChangesTable.Add();
		NewRow.Id = CurrentRow;
		NewRow.SupplyOption = SecurityOptionSelectedValue.SupplyOption;
		
		If SecurityOptionSelectedValue.SplitRow Then
			
			Available = CurrentData.Available;
			If SecurityOptionSelectedValue.Available > 0 Then
				Available = SecurityOptionSelectedValue.Available;
			Else
				Available = CurrentData.Available;
			EndIf;
			ChangesTable.Columns.Add("NumberOfPackages");
			
			NumberOfPackages = CurrentData.NumberOfPackages - Available;
			
			NewRow.NumberOfPackages = Available;
			
			NewRow = ChangesTable.Add();
			NewRow.Id = CurrentRow;
			NewRow.SupplyOption = EmbeddingParameters.InternalParameters.SupplyOptionBeforeChange;
			NewRow.NumberOfPackages = NumberOfPackages;
			NewRow.IsNewLine = True;
			
		EndIf;
		SetActionsFromTable(Form, ChangesTable);
		
	EndIf;
	EmbeddingParameters.InternalParameters.SecurityOptionSelectedValue = Undefined;
	
	Return ChangesTable;
	
EndFunction

// Recalculates the number of units based on the number of packages in the transmitted table, which contains references to the
// table rows in which the recalculation should be performed.
// 
// Parameters:
//  Changes - ValueTable -
//   * Row - Data formelementcollection - the row of the tabular part in which to recalculate.
//  TabPart - FormDataCollection - The table part being processed.
//
Procedure RecalculateNumberOfUnits(Changes, TabPart) Export
	
	StructureOfActions = New Structure("RecalculateNumberOfUnits");
	CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		Changes.UnloadColumn("String"),
		StructureOfActions,
		TabPart,
		CachedValues);
	
EndProcedure

// The handler of the action setup command in the shipment order form without transferring the result to the document.
//
// Parameters:
//  ActionCode - String - the code of the action being performed:
//                         is "FLAG_ SEPARATELY", "FLAG_ SEPARATELY", "ACTION_TO ENSURE",
//                         "ACTION_TO PROVIDE", "ACTION_TO RESERVE", "ACTION_TO LOAD",
//                         "ACTION_TO RESERVE AFTER ACCESS", "ROLLBACK ACTION_TO LOAD".
//  Form - ClientApplicationForm - the form in the table part of which you need to run the command.
//  SelectedRows - Array of FormDataCollectionItem - contains the row IDs of the collection to perform the action on.
//
// Returns:
//  Structure - a structure containing tables for filling in the security option in the lines, as well as fields
//              necessary for further processing and making a decision on shipment by one or different dates.
//
Function ChangesToSetActions(ActionCode, Form, SelectedRows) Export
	
	// Initialization of parameters and query text, obtaining a temporary document data table
	// for the reflection operation and a temporary reflection table.
	EmbeddingParameters = Form.AvailableRemainingEmbeddingOptions;
	Tables = GetFromTempStorage(EmbeddingParameters.InternalParameters.AddressOfFormDataTable);
	FillInTablesFromFormData(Tables, Form);
	
	Query = New Query();
	Query.TempTablesManager = New TempTablesManager();
	AddTemporaryDocumentDataTable(Query.TempTablesManager, Tables, EmbeddingParameters);
	AddTemporaryDocumentDataTableForSelectedRows(Query, SelectedRows);
	ArrayOfTexts = New Array();
	Text = TemporaryTableOfDocumentRegisteredRecords();
	ArrayOfTexts.Add(Text);
	Text = StrReplace(Text, "TemporaryDocumentDataTable", "TemporaryDocumentDataTableForSelectedRows");
	Text = StrReplace(Text, "TemporaryTableOfDocumentRegisteredRecords", "TemporaryTableOfDocumentRegisteredRecordsForSelectedRows");
	ArrayOfTexts.Add(Text);
	Query.Text = StrConcat(ArrayOfTexts, Common.QueryBatchSeparator());
	Query.SetParameter("Ref", Undefined);
	Query.SetParameter("NewDestinationLink", Catalogs.Assignments.GetRef());
	Query.Execute();
	
	TableDecorated = TableDecorated(
		Query,
		AccumulationRegisters[EmbeddingParameters.NameOfShipmentRegistrationRegister],
		"TemporaryDocumentDataTableForSelectedRows",
		"TemporaryDocumentDataTable");
		
	GroupWarehouses_ = GroupWarehouses_(Query);
	
	SeparateAndNonSeparateBalances = (ActionCode = "Action_Ship_PRIORITY_WithAssignment" 
										Or ActionCode = "Action_ToReserve__PRIORITY_WithAssignment");
	CorrectionOfRegisteredRecords = ?(EmbeddingParameters.AddressOfMotionCorrection = Undefined,
		Undefined,
		GetFromTempStorage(Form[EmbeddingParameters.AddressOfMotionCorrection]));
	AddTemporaryTablesToGetBalances(
		Query,
		SeparateAndNonSeparateBalances,
		CorrectionOfRegisteredRecords,
		False,
		Not SessionParameters.PostWithoutControlOfGoodsReservesUnderOrders);
	WarehouseRemnants = LeftoversForSettingActions(Query, GroupWarehouses_);
	WarehouseLeftoversInWholePackages = WarehouseRemnants.Copy();
	
	Query.Text =
		"SELECT
		|	Table.Products                    AS Products,
		|	Table.Products.ItemsType    AS ItemsType,
		|	Table.Characteristic                  AS Characteristic,
		|	Table.Warehouse                           AS Warehouse,
		|	Table.ShipmentOrder                 AS ShipmentOrder,
		|	Table.RowCode                       AS RowCode,
		|	Table.WithAssignment                     AS WithAssignment,
		|	Table.TheShipmentDateOfAllLinesIsASingleDate AS TheShipmentDateOfAllLinesIsASingleDate,
		|	Table.SupplyOption              AS SupplyOption,
		|	Table.NumberOfPackages              AS NumberOfPackages,
		|	Table.Count                      AS Count,
		|	Table.LineNumber                     AS CollectionItem,
		|	
		|	CASE WHEN Table.WithAssignment THEN
		|				Table.Purpose
		|			ELSE
		|				VALUE(Catalog.Assignments.EmptyRef)
		|		END AS Purpose,
		|	Table.ControlledLotReference AS ControlledLotReference,
		|
		|	Table.Purpose AS AssignmentWithoutRegardToFlagIsSeparate,
		|	
		|	ISNULL((Table.Warehouse = VALUE(Catalog.Warehouses.EmptyRef)
		|		OR ISNULL(SettingUpCharacteristic.AvailableStockControl,
		|				ISNULL(SettingUpProducts.AvailableStockControl,
		|				ISNULL(SettingUpWarehouse.AvailableStockControl, FALSE))))
		|			AND NOT Table.Products.ItemsType IN(
		|				VALUE(Enum.ItemsTypes.Work_5),
		|				VALUE(Enum.ItemsTypes.OperationService)), TRUE) AS AvailableStockControl
		|FROM
		|	TemporaryDocumentDataTableForSelectedRows AS Table
		|		
		|		LEFT JOIN InformationRegister.SetUpSupplyControl AS SettingUpCharacteristic
		|		ON SettingUpCharacteristic.Warehouse          = Table.Warehouse
		|		 AND SettingUpCharacteristic.Products   = Table.Products
		|		 AND SettingUpCharacteristic.Characteristic = Table.Characteristic
		|		
		|		LEFT JOIN InformationRegister.SetUpSupplyControl AS SettingUpProducts
		|		ON SettingUpProducts.Warehouse        = Table.Warehouse
		|		 AND SettingUpProducts.Products = Table.Products
		|		 AND SettingUpProducts.Characteristic = VALUE(Catalog.ItemsCharacteristics.EmptyRef)
		|		 AND SettingUpCharacteristic.Warehouse IS NULL
		|		
		|		LEFT JOIN InformationRegister.SetUpSupplyControl AS SettingUpWarehouse
		|		ON SettingUpWarehouse.Warehouse          = Table.Warehouse
		|		 AND SettingUpWarehouse.Products   = VALUE(Catalog.Products.EmptyRef)
		|		 AND SettingUpWarehouse.Characteristic = VALUE(Catalog.ItemsCharacteristics.EmptyRef)
		|		 AND SettingUpCharacteristic.Warehouse IS NULL
		|		 AND SettingUpProducts.Warehouse IS NULL
		|WHERE
		|	NOT Table.Canceled";
	
	RowsData = Query.Execute().Unload();
	
	CollectionOnForm = ProvisionInDocumentsClientServer.CollectionOnForm(Form, EmbeddingParameters);
	PackingFactors = PackingFactors(RowsData, CollectionOnForm);
	
	DataOfAccounting = New Structure("WarehouseRemnants,TableDecorated", WarehouseRemnants, TableDecorated);
	ParametersForFillingInActions = New Structure("PopulateWithTheWholePackagings,PickUpWarehouse", False, True);
	ChangesTable = TableForSettingActions(
		ActionCode,
		ParametersForFillingInActions,
		CollectionOnForm,
		SelectedRows,
		RowsData,
		PackingFactors,
		DataOfAccounting);
		
	Result = New Structure();
	Result.Insert("ChangesTable",                                ChangesTable);
	Result.Insert("UncheckShipByOneDateFlag",                    False);
	Result.Insert("TableOfChangesByWholePackages",                Undefined);
	Result.Insert("RemoveFlagShipOneDateInWholePackages",    False);
	Result.Insert("FillShippingDateWithSingleDate",                 False);
	Result.Insert("FillShippingDateWithOneDateWholePackages", False);
	Result.Insert("TheShipmentDateOfAllLinesIsASingleDate",                 Undefined);
	Result.Insert("DateOfShipmentOfCompletedLines",                    Undefined);
	
	If RowsData.Count() = 0 Then
		Return Result;
	EndIf;
	
	Query.Text =
		"SELECT
		|	COUNT(*) AS TotalRecords
		|FROM
		|	TemporaryDocumentDataTable AS Table
		|WHERE
		|	NOT Table.Canceled";
	Selection = Query.Execute().Select();
	TotalLinesInDocument = 0;
	If Selection.Next() Then
		TotalLinesInDocument = Selection.TotalRecords;
	EndIf;
	
	PaddingForAllRows = RowsData.Count() = TotalLinesInDocument;
	FillingInShipmentDate = ActionCode = "ACTION_LOAD" Or ActionCode = "Action_Ship_PRIORITY_WithAssignment";
	AskAQuestion = False;
	If FillingInShipmentDate Then

		FilterShip = New Structure("SupplyOption", Enums.SupplyOptions.Ship);

		ShipBeforeChange = 0;
		TableShip = RowsData.Copy(FilterShip, "NumberOfPackages");
		If TableShip.Count() > 0 Then
			TableShip.GroupBy(, "NumberOfPackages");
			ShipBeforeChange = TableShip[0].NumberOfPackages;
		EndIf;

		TableAfterChanges = RowsData.Copy(New Array, "SupplyOption,NumberOfPackages");
		SetActionsFromTableToExternalTable(Form, ChangesTable, TableAfterChanges, EmbeddingParameters);
		ShipAfterChange = 0;
		TableShip = TableAfterChanges.Copy(FilterShip, "NumberOfPackages");
		ItBecamePossibleToShipInAllSelectedLines = TableShip.Count() = TableAfterChanges.Count();
		If TableShip.Count() > 0 Then
			TableShip.GroupBy(, "NumberOfPackages");
			ShipAfterChange = TableShip[0].NumberOfPackages;
		EndIf;
		
		WasToShip = ShipBeforeChange > 0;
		FillingInShipmentDate = ShipAfterChange > ShipBeforeChange;
		AskAQuestion = ?(Not PaddingForAllRows, True, // there were no highlighted lines, you need to ask a question unconditionally
			Not ItBecamePossibleToShipInAllSelectedLines Or WasToShip); // not all of them were marked to Ship or there were already Shipping lines with an overdue date
			
	EndIf;
	
	If FillingInShipmentDate Then
		
		Result.TheShipmentDateOfAllLinesIsASingleDate = RowsData[0].TheShipmentDateOfAllLinesIsASingleDate;
		Result.DateOfShipmentOfCompletedLines = BegOfDay(CurrentSessionDate());
		If AskAQuestion Then
			
			Result.UncheckShipByOneDateFlag
				= InChangesetThereIsShipmentAndShipmentDateOfAllRowsIsOneDateOverdue(
					ChangesTable,
					RowsData)
					And EmbeddingParameters.ExpressionForQuestionWhenPerformingActionInOrderList <> "UNDEFINED";
			
		Else
			
			Result.FillShippingDateWithSingleDate = RowsData.Count() > 0
				And RowsData[0].TheShipmentDateOfAllLinesIsASingleDate <> Undefined
				And RowsData[0].TheShipmentDateOfAllLinesIsASingleDate < BegOfDay(CurrentSessionDate());
			
		EndIf;
		
	EndIf;
	
	RowsData.Indexes.Add("CollectionItem");
	If ThereAreFractionalPackagesInChangeTable(ChangesTable, PackingFactors, RowsData) Then
		
		DataOfAccounting = New Structure("WarehouseRemnants,TableDecorated", WarehouseLeftoversInWholePackages, TableDecorated);
		ParametersForFillingInActions = New Structure("PopulateWithTheWholePackagings,PickUpWarehouse", True, True);
		ChangesTable = TableForSettingActions(
			ActionCode,
			ParametersForFillingInActions,
			CollectionOnForm,
			SelectedRows,
			RowsData,
			PackingFactors,
			DataOfAccounting);
			
		Result.TableOfChangesByWholePackages = ChangesTable;
		
		If FillingInShipmentDate Then
			
			If AskAQuestion Then
				
				Result.RemoveFlagShipOneDateInWholePackages
					= InChangesetThereIsShipmentAndShipmentDateOfAllRowsIsOneDateOverdue(
						ChangesTable,
						RowsData)
						And EmbeddingParameters.ExpressionForQuestionWhenPerformingActionInOrderList <> "UNDEFINED"						
				
			Else
				
				Result.FillShippingDateWithOneDateWholePackages = RowsData.Count() > 0
					And RowsData[0].TheShipmentDateOfAllLinesIsASingleDate <> Undefined
					And RowsData[0].TheShipmentDateOfAllLinesIsASingleDate < BegOfDay(CurrentSessionDate());
				
			EndIf;
			
		EndIf;
		
	EndIf;
	
	Return Result;
	
EndFunction

// The selection handler in the "Action" field in the table part of the shipment order.
// 
// Parameters:
//  ValueSelected - Structure - a structure containing a table:
//    * SelectedGoods - ValueTable - the table to transfer to the document.
//  Form - ClientApplicationForm - order form.
//  CurrentRow - Number - id of the line of the tabular part of the order for which the security option, series, or warehouse is specified.
//  FieldsToFillIn - String - the fields in the tabular part of the order are separated by commas, which must be filled in from the table of selected products.
//
// Returns:
//  ValueTable - a table containing links to the rows of the tabular part of the order to which the data was transferred.
//
Function WhenChoosingWarehouse(ValueSelected, Form, CurrentRow, FieldsToFillIn) Export
	
	FieldArray = StrSplit(FieldsToFillIn, ",");
	
	ChangesTable = New ValueTable();
	
	For Each Field In FieldArray Do
		ChangesTable.Columns.Add(Field);
	EndDo;
	ChangesTable.Columns.Add("Id");
	ChangesTable.Columns.Add("String");
	ChangesTable.Columns.Add("IsNewLine", New TypeDescription("Boolean"));
	
	For Each String In ValueSelected.SelectedGoods Do
		
		NewRow = ChangesTable.Add();
		FillPropertyValues(NewRow, String);
		NewRow.Id = CurrentRow;
		
	EndDo;
	
	SetActionsFromTable(Form, ChangesTable);
	Return ChangesTable;
	
EndFunction

// Generates parameters for transmission to the warehouse and series selection form in the order line.
//
// Parameters:
//  Form - ClientApplicationForm - order form.
//  CurrentRow - Number - id of the line of the tabular part of the order for which the security option, series, or warehouse is specified.
//  Mode - String - command execution mode.
//  Warehouses - Array of CatalogRef.Warehouses - warehouses, if the selection needs to be limited.
//
// Returns:
//  See ProvisionInDocumentsClientServer.ParametersOfQuantityAndSeriesRequestForm
//
Function SoftwareSelectionParameters(Form, CurrentRow, Mode, Warehouses = Undefined) Export
	
	// Initialization of parameters and query text, obtaining a temporary document data table
	// for the reflection operation and a temporary reflection table.
	EmbeddingParameters = Form.AvailableRemainingEmbeddingOptions;
	Tables = GetFromTempStorage(EmbeddingParameters.InternalParameters.AddressOfFormDataTable);
	FillInTablesFromFormData(Tables, Form);
	
	Query = New Query();
	Query.TempTablesManager = New TempTablesManager();
	AddTemporaryDocumentDataTable(Query.TempTablesManager, Tables, EmbeddingParameters);
	LineNumbers = CommonClientServer.ValueInArray(CurrentRow);
	AddTemporaryDocumentDataTableForSelectedRows(Query, LineNumbers);
	ArrayOfTexts = New Array();
	Text = TemporaryTableOfDocumentRegisteredRecords();
	ArrayOfTexts.Add(Text);
	Text = StrReplace(Text, "TemporaryDocumentDataTable", "TemporaryDocumentDataTableForSelectedRows");
	Text = StrReplace(Text, "TemporaryTableOfDocumentRegisteredRecords", "TemporaryTableOfDocumentRegisteredRecordsForSelectedRows");
	ArrayOfTexts.Add(Text);
	Query.Text = StrConcat(ArrayOfTexts, Common.QueryBatchSeparator());
	Query.SetParameter("Ref", Undefined);
	Query.SetParameter("NewDestinationLink", Catalogs.Assignments.GetRef());
	Query.Execute();
	
	TableDecorated = TableDecorated(
		Query,
		AccumulationRegisters[EmbeddingParameters.NameOfShipmentRegistrationRegister],
		"TemporaryDocumentDataTableForSelectedRows",
		"TemporaryDocumentDataTable");
	
	QuantityRegistered = ?(TableDecorated.Count() > 0, TableDecorated[0].Count, 0);
	
	GroupWarehouses_ = ?(Warehouses = Undefined, GroupWarehouses_(Query), Warehouses);
	If Mode = ProvisionInDocumentsClientServer.SeriesSelectionMode() Then
		GroupWarehouses_ = Undefined;
	EndIf;
	
	Query.Text =
		"SELECT
		|	Table.Purpose AS Purpose,
		|	Table.Products AS Products,
		|	Table.Characteristic AS Characteristic,
		|	Table.ControlledLotReference AS ControlledLotReference,
		|	CASE
		|		WHEN CAST(Table.Products AS Catalog.Products).ItemsType IN(
		|				VALUE(Enum.ItemsTypes.OwnGoods),
		|				VALUE(Enum.ItemsTypes.ReusablePackage))
		|			THEN Table.Warehouse
		|		ELSE Table.Department
		|	END AS Warehouse,
		|	Table.SupplyOption AS SupplyOption,
		|	Table.WithAssignment AS WithAssignment,
		|	Table.NumberOfPackages AS Count,
		|	Table.Package AS Package,
		|	Table.Recorder AS Recorder,
		|	Table.Series AS Series,
		|	Table.GroupOfWarehouses AS GroupOfWarehouses,
		|	CAST(Table.Products AS Catalog.Products).ItemsType AS ItemsType,
		|	Table.Department AS Department,
		|	Table.TheShipmentDateOfAllLinesIsASingleDate AS TheShipmentDateOfAllLinesIsASingleDate
		|FROM
		|	TemporaryDocumentDataTableForSelectedRows AS Table
		|;
		|
		|//////////////////////////////////////////////////////////////////////////
		|SELECT DISTINCT
		|	Table.ShipmentOrder AS Ref
		|FROM
		|	TemporaryDocumentDataTable AS Table";
	
	Package = Query.ExecuteBatch();
	RowsData = Package[0].Unload();
	
	PackagingFactor = 1;
	If ValueIsFilled(RowsData[0].Package) Then
		
		PackagingFactor = Catalogs.PackagesAndUnitsOfMeasure.PackagingFactor(
			RowsData[0].Package,
			RowsData[0].Products);
			
	EndIf;
	
	CorrectionOfRegisteredRecords = ?(EmbeddingParameters.AddressOfMotionCorrection = Undefined,
		Undefined,
		GetFromTempStorage(Form[EmbeddingParameters.AddressOfMotionCorrection]));
	AddTemporaryTablesToGetBalances(Query, True, CorrectionOfRegisteredRecords, True, True);
	WarehouseAndScheduleLeftovers = LeftoversForSelectingWarehouses(Query, GroupWarehouses_, PackagingFactor);
	WarehouseAndScheduleLeftovers.Sort("Products,Characteristic,Warehouse,Purpose,ControlledLotReference", New CompareValues());
	
	If Not ValueIsFilled(RowsData[0].Warehouse) Then
		NewRow = WarehouseAndScheduleLeftovers.Add();
		FillPropertyValues(NewRow, RowsData[0]);
		NewRow.WithAssignment = False;
		NewRow.ThisIsSelectedGroupWarehouse = True;
		NewRow.CheckAvailability = True;
		NewRow = WarehouseAndScheduleLeftovers.Add();
		FillPropertyValues(NewRow, RowsData[0]);
		NewRow.WithAssignment = True;
		NewRow.ThisIsSelectedGroupWarehouse = True;
		NewRow.CheckAvailability = True;
	EndIf;
	
	AddressAvailableBalances = PutToTempStorage(WarehouseAndScheduleLeftovers, Form.UUID);
	
	FormParameters = ProvisionInDocumentsClientServer.ParametersOfQuantityAndSeriesRequestForm();
	FillPropertyValues(FormParameters, RowsData[0]);
	
	FormParameters.ReadOnly                   = Mode = ProvisionInDocumentsClientServer.ViewAvailabilityMode(); // selection in the column available in orders
	FormParameters.Mode                            = Mode;
	FormParameters.SelectionOfWarehouses                    = True;
	FormParameters.AddressAvailableBalances            = AddressAvailableBalances;
	FormParameters.AllowedNonIsolatedActions = ProvisionInDocumentsClientServer.AllActions();
	FormParameters.AcceptableSeparateActions   = ProvisionInDocumentsClientServer.AllActions();
	FormParameters.WarehouseByDocument                 = RowsData[0].Warehouse;
	FormParameters.Warehouse                            = RowsData[0].GroupOfWarehouses;
	FormParameters.SecurityOptionForTheDocument    = RowsData[0].SupplyOption;
	FormParameters.SupplyOptionBeforeChange    = RowsData[0].SupplyOption;
	FormParameters.SeparatelyInTheDocument           = RowsData[0].WithAssignment;
	FormParameters.CountByDocument            = RowsData[0].Count;
	FormParameters.Recorder                      = RowsData[0].Recorder;
	FormParameters.Series                            = RowsData[0].Series;
	FormParameters.QuantityRegistered              = QuantityRegistered / PackagingFactor;
	FormParameters.ShippingOrders.LoadValues(Package[1].Unload().UnloadColumn("Ref"));
	FormParameters.SelectSeries = True;
	FormParameters.TableAddressSelectedEarlier = TableAddressSelectedEarlier(Query, Form.UUID);
	
	FormParameters.Insert("FieldsToFillIn");
	If Mode = ProvisionInDocumentsClientServer.ActionSelectionMode() Then
		FormParameters.FieldsToFillIn = "NumberOfPackages,SupplyOption,WithAssignment,Warehouse,Series";
	ElsIf Mode = ProvisionInDocumentsClientServer.SeriesSelectionMode() Then
		FormParameters.SeriesSelection_3 = True;
		FormParameters.FieldsToFillIn = "NumberOfPackages,Series";
	ElsIf Mode = ProvisionInDocumentsClientServer.WarehouseSelectionMode() Then
		FormParameters.FieldsToFillIn = "NumberOfPackages,Warehouse,Series";
	EndIf;
	
	FormParameters.Insert("TheShipmentDateOfAllLinesIsASingleDate", RowsData[0].TheShipmentDateOfAllLinesIsASingleDate);
	FormParameters.Insert("DateWhenTheNewLinesWereShipped", BegOfDay(CurrentSessionDate()));
	
	Query.Text =
		"SELECT
		|COUNT(*) Count
		|FROM
		|	TemporaryDocumentDataTable AS Table
		|WHERE
		|	NOT Table.Canceled";
	AllLinesOfDocumentAreSelected = False;
	Selection = Query.Execute().Select();
	If Selection.Next() Then
		AllLinesOfDocumentAreSelected = Selection.Count() = 1;
	EndIf;
	FormParameters.AllLinesOfDocumentAreSelected = AllLinesOfDocumentAreSelected;
	
	Return FormParameters;
	
EndFunction

// Generates the data of the modified object for the general form of the security status.
//
// Parameters:
//  Form - ClientApplicationForm - the form from which to open the security status form.
// 
// Returns:
//  String - the address of the order data in the temporary storage.
//
Function AddressOfMovementTableInRepository(Form) Export
	
	EmbeddingParameters = Form.AvailableRemainingEmbeddingOptions;
	Tables = GetFromTempStorage(EmbeddingParameters.InternalParameters.AddressOfFormDataTable);
	FillInTablesFromFormData(Tables, Form);
	
	Query = New Query();
	Query.TempTablesManager = New TempTablesManager();
	AddTemporaryDocumentDataTable(Query.TempTablesManager, Tables, EmbeddingParameters);
	Query.Text = TemporaryTableOfDocumentRegisteredRecords(True);
	Query.SetParameter("Ref", Undefined);
	Query.SetParameter("NewDestinationLink", Catalogs.Assignments.GetRef());
	Query.Execute();
	
	Texts = New Array();
	
	Text =
		"SELECT
		|	RegisteredRecordsDuringRecording.Products AS Products,
		|	RegisteredRecordsDuringRecording.Characteristic AS Characteristic,
		|	RegisteredRecordsDuringRecording.Warehouse AS Warehouse,
		|	RegisteredRecordsDuringRecording.Purpose AS Purpose,
		|	RegisteredRecordsDuringRecording.OrderDocument AS OrderDocument,
		|	RegisteredRecordsDuringRecording.OrderToShip AS OrderToShip,
		|	RegisteredRecordsDuringRecording.EventDate AS EventDate,
		|	RegisteredRecordsDuringRecording.RecordType AS RecordType,
		|	RegisteredRecordsDuringRecording.InStock AS InStock,
		|	RegisteredRecordsDuringRecording.LockedInStock AS LockedInStock,
		|	RegisteredRecordsDuringRecording.ReserveAtWarehouse AS ReserveAtWarehouse,
		|	RegisteredRecordsDuringRecording.ReserveAsReceived AS ReserveAsReceived,
		|	RegisteredRecordsDuringRecording.ReserveAtWarehouseFromLocked AS ReserveAtWarehouseFromLocked,
		|	RegisteredRecordsDuringRecording.ReserveUponReceiptFromLocked AS ReserveUponReceiptFromLocked,
		|	RegisteredRecordsDuringRecording.ToSupply AS ToSupply,
		|	RegisteredRecordsDuringRecording.NotProvide AS NotProvide,
		|	0 AS Ordered,
		|	0 AS Received_1,
		|	0 AS ToUnlock,
		|	0 AS LockedReceipt,
		|	0 AS SnoozeReservation,
		|	0 AS CloseScheduleShipping,
		|	0 AS CloseReceiptSchedule,
		|	FALSE AS ToControlQuality,
		|	FALSE AS SubjectToUnlocking
		|FROM
		|	TemporaryTableOfDocumentRegisteredRecords AS RegisteredRecordsDuringRecording";
	Texts.Add(Text);
	
	Text =
		"SELECT DISTINCT
		|	Table.ShipmentOrder AS ShipmentOrder,
		|	Table.Priority AS Priority,
		|	Table.DocumentDate AS DocumentDate
		|FROM
		|	TemporaryDocumentDataTable AS Table";
	Texts.Add(Text);
	Query.Text = StrConcat(Texts, Common.QueryBatchSeparator());
	Package = Query.ExecuteBatch();
	
	Data = New Structure();
	Data.Insert("RegisterRecordTable", Package[0].Unload());
	Data.Insert("TableSimulationRegistry", Package[1].Unload());
	AddressOfTheMovementTable = PutToTempStorage(Data, Form.UUID);
	
	Return AddressOfTheMovementTable;
	
EndFunction

////////////////////////////////////////////////////////////
// Special use cases, calling kernel functions directly.

// Sets the actions in the tabular part of the order based on the transmitted table of changes.
//
// Parameters:
//  Form - ClientApplicationForm - order form.
//  ChangesTable - See TableForSettingActions
//  EmbeddingParameters - See AvailableRemainingEmbeddingOptions
Procedure SetActionsFromTable(Form, ChangesTable, EmbeddingParameters = Undefined) Export
	
	If TypeOf(Form) = Type("ClientApplicationForm") Then
		EmbeddingParameters = Form.AvailableRemainingEmbeddingOptions;
		Collection = ProvisionInDocumentsClientServer.CollectionOnForm(Form, EmbeddingParameters);
	Else
		Collection = Form;
	EndIf;
	AttributesToBeCleared = New Structure(EmbeddingParameters.AttributesToBeCleared);
	DetailsToFillIn = New Structure(EmbeddingParameters.AttributesToBeCleared);
	
	Id = Undefined;
	ThisIsDataOfFormCollection = TypeOf(Collection) = Type("FormDataCollection");
	AddedLines_ = 0;
	For IndexOf = 0 To ChangesTable.Count() - 1 Do
		
		SecurityLine = ChangesTable[IndexOf];
		
		// Selecting an existing one, or adding a new line.
		If Id <> SecurityLine.Id Then
			
			Id = SecurityLine.Id;
			If ThisIsDataOfFormCollection Then
				LineProducts_ = Collection.FindByID(Id);
			Else
				LineProducts_ = Collection[Id - 1 + AddedLines_];
			EndIf;
			SecurityLine.String = LineProducts_;
			FillPropertyValues(DetailsToFillIn, LineProducts_);
			
		Else
			
			AddedLines_ = AddedLines_ + 1;
			NewRow = Collection.Insert(Collection.IndexOf(LineProducts_) + 1);
			FillPropertyValues(NewRow, LineProducts_);
			SecurityLine.String = NewRow;
			LineProducts_ = NewRow;
			
		EndIf;
		
		FillPropertyValues(LineProducts_, SecurityLine);
		If SecurityLine.IsNewLine Then
			FillPropertyValues(LineProducts_, AttributesToBeCleared);
		Else
			FillPropertyValues(LineProducts_, DetailsToFillIn);
		EndIf;
		
	EndDo;
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Service forms of documents

// Handler when creating on the server for order forms.
//
// Parameters:
//  Form - ClientApplicationForm - order form.
//  EmbeddingParameters - See ProvisionInDocumentsServer.AvailableRemainingEmbeddingOptions
//
Procedure AvailableBalancesWhenCreatedOnServer(Form, EmbeddingParameters) Export
	
	FillInEmbeddingParameters(Form, EmbeddingParameters);
	
	ItemAvailable = Form.Items[EmbeddingParameters.ConditionalAppearance.FormItems.Available];
	ItemAvailable.AutoMaxWidth = False;
	ItemAvailable.MaxWidth     = 8;
	ItemAvailable.Format                 = "NFD=3; NZ=0,000";
	ItemAvailable.ReadOnly         = True;
	ItemAvailable.TextColor             = StyleColors.HelpText;
	
	ElementSoftware = Form.Items[EmbeddingParameters.ConditionalAppearance.FormItems.SupplyOption];

	Links = EmbeddingParameters.ConnectionsOfSoftwareOptionSelectionParameters;
	NewArrayOfLinks = New Array();
	NewArrayOfParameters = New Array();
	For Each Property In Links Do
		If TypeOf(Property.Value) = Type("String") Then // this is the path to the field from the string
			NewLink = New ChoiceParameterLink(
				Property.Key,
				Property.Value,
				LinkedValueChangeMode.DontChange);
			NewArrayOfLinks.Add(NewLink);
		ElsIf Property.Value <> Undefined Then // these are the specific values
			NewParameter1 = New ChoiceParameter(
				Property.Key,
				Property.Value);
			NewArrayOfParameters.Add(NewParameter1);
		EndIf;
	EndDo;
	NewLinks = New FixedArray(NewArrayOfLinks);
	ElementSoftware.ChoiceParameterLinks = NewLinks;
	NewParameters = New FixedArray(NewArrayOfParameters);
	ElementSoftware.ChoiceParameters = NewParameters;
	
	CurrentParameters = Form.AvailableRemainingEmbeddingOptions;
	If Not CurrentParameters.Property("AddressOfBalances") Then
		CollectionOnForm = ProvisionInDocumentsClientServer.CollectionOnForm(Form, CurrentParameters);
		If TypeOf(CollectionOnForm) = Type("FormDataCollection") And CollectionOnForm.Count() = 0 Then
			Balance = NewStructureBalance();
			AddressOfBalances = PutToTempStorage(Balance, Form.UUID);
			CurrentParameters.Insert("AddressOfBalances", AddressOfBalances);
			CurrentParameters.InternalParameters.Insert("AddressProductRange",
				PutToTempStorage(New Map(), Form.UUID));
		Else
			AvailableBalancesWhenReadingOnServer(Form, CurrentParameters);
		EndIf;
	EndIf;
	
EndProcedure

// The handler when the reading on the server for the order forms.
//
// Parameters:
//  Form - ClientApplicationForm - order form.
//  EmbeddingParameters - See ProvisionInDocumentsServer.AvailableRemainingEmbeddingOptions
//
Procedure AvailableBalancesWhenReadingOnServer(Form, EmbeddingParameters) Export
	
	FillInEmbeddingParameters(Form, EmbeddingParameters);
	FillParameters = AvailableBalancesFillParameters();
	FillParameters.GettingLeftoversFromCache = False;
	AvailableBalancesToReplenish(Form, FillParameters);
	
EndProcedure

// Handler after recording on the server for order forms.
//
// Parameters:
//  Form - ClientApplicationForm - order form.
//
Procedure AfterWriteAtServer(Form) Export
	
	EmbeddingParameters = Form.AvailableRemainingEmbeddingOptions;
	Tables = GetFromTempStorage(EmbeddingParameters.InternalParameters.AddressOfFormDataTable);
	FillInTablesFromFormData(Tables, Form);
	
	Query = New Query();
	Query.TempTablesManager = New TempTablesManager();
	AddTemporaryDocumentDataTable(Query.TempTablesManager, Tables, EmbeddingParameters);
	
	Query.Text =
		"SELECT DISTINCT
		|	Table.ShipmentOrder AS ShipmentOrder
		|FROM
		|	TemporaryDocumentDataTable AS Table
		|WHERE
		|	TRUE IN(
		|		SELECT TOP 1
		|			TRUE AS ThereAreRecords
		|		FROM
		|			InformationRegister.JobsForAllocatingInventory AS Jobs
		|		WHERE
		|			Jobs.ShipmentOrder = Table.ShipmentOrder)";
	
	SetPrivilegedMode(True);
	Orders = Query.Execute().Unload().UnloadColumn("ShipmentOrder");
	SetPrivilegedMode(False);
	NeedAvailabilityUpdateHandler = Orders.Count() > 0;
	InternalParameters = Form.AvailableRemainingEmbeddingOptions.InternalParameters;
	InternalParameters.NeedAvailabilityUpdateHandler = NeedAvailabilityUpdateHandler;
	YouCanUpdateColumn = False;
	If EmbeddingParameters.Property("AddressOfBalances") Then
		ChangesTable = GetFromTempStorage(EmbeddingParameters.AddressOfBalances).ChangesToDocument;
		YouCanUpdateColumn = ChangesTable.Find(True, "ToUpdateColumnAvailableAfterInventoryAllocation") <> Undefined
			And NeedAvailabilityUpdateHandler;
	EndIf;
	InternalParameters.ToUpdateColumnAvailableAfterInventoryAllocation = YouCanUpdateColumn;
	InternalParameters.OrdersToUpdateAvailability = Orders;
	InternalParameters.IntervalForStartingHandler = 1;
	FillParameters = AvailableBalancesFillParameters();
	FillParameters.GettingLeftoversFromCache = YouCanUpdateColumn;
	AvailableBalancesToReplenish(Form, FillParameters, Query);
	
	If NeedAvailabilityUpdateHandler Then
		
		CheckToRunBackgroundInventoryAllocationJob();
		
	EndIf;
	
EndProcedure

// Updates the "Available" column in the table part of the order items after the order is recorded.
//
// Parameters:
//  Form - ClientApplicationForm - order form.
//
Procedure UpdateAvailabilityAfterRecording(Form) Export
	
	FillParameters = AvailableBalancesFillParameters();
	FillParameters.GettingLeftoversFromCache = False;
	AvailableBalancesToReplenish(Form, FillParameters);
	
EndProcedure

// Updates the "Available" column in the tabular part of the order items when the document details that affect this column change.
//
// Parameters:
//  Form - ClientApplicationForm - order form.
//
Procedure WhenChangingDocumentDetails(Form) Export
	
	UpdateColumnAvailable(Form);
	
EndProcedure

// Sets the conditional design of the "Available" column in the order form.
//
// Parameters:
//  Form - ClientApplicationForm - order form.
//
Procedure AvailableLeftoversAddColumnLayoutAvailable(Form) Export
	
	EmbeddingParameters = Form.AvailableRemainingEmbeddingOptions;
	
	ConditionalAppearance = Form.ConditionalAppearance;
	
	// The text of the forbidden cell, if the stock is redistributed in the warehouse.
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(EmbeddingParameters.ConditionalAppearance.FormItems.Available);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField(
		EmbeddingParameters.ConditionalAppearance.DataPaths.ReallocateInventory);
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.InaccessibleCellTextColor);
	
	// Hiding the column if the action is not "Reserve as received", not "To provide" and not "Not to provide".
	VariantList = New ValueList();
	VariantList.Add(Enums.SupplyOptions.ReserveAsReceived);
	VariantList.Add(Enums.SupplyOptions.ToSupply);
	VariantList.Add(Enums.SupplyOptions.NotRequired);
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(EmbeddingParameters.ConditionalAppearance.FormItems.Available);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField(
		Form.Items[EmbeddingParameters.ConditionalAppearance.FormItems.SupplyOption].DataPath);
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.SupplyOptions.NotRequired;
	ItemFilter.LeftValue = New DataCompositionField(
		EmbeddingParameters.ConditionalAppearance.DataPaths.ItemsType);
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.ItemsTypes.OperationService;
	
	Item.Appearance.SetParameterValue("Show", False);
	
	// Hiding the column if the action is "Do not provide" and the item is not a container.
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(EmbeddingParameters.ConditionalAppearance.FormItems.Available);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField(
		Form.Items[EmbeddingParameters.ConditionalAppearance.FormItems.SupplyOption].DataPath);
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotInList;
	ItemFilter.RightValue = VariantList;
	
	Item.Appearance.SetParameterValue("Show", False);
	
	// Hiding the column if the row is canceled.
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(EmbeddingParameters.ConditionalAppearance.FormItems.Available);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField(
		EmbeddingParameters.ConditionalAppearance.DataPaths.NoEditingAllowed);
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	Item.Appearance.SetParameterValue("Show", False);
	
	// Prohibition of editing fields.
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(EmbeddingParameters.ConditionalAppearance.FormItems.SupplyOption);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(EmbeddingParameters.ConditionalAppearance.FormItems.Series);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(EmbeddingParameters.ConditionalAppearance.FormItems.WithAssignment);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(EmbeddingParameters.ConditionalAppearance.FormItems.Warehouse);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField(
		EmbeddingParameters.ConditionalAppearance.DataPaths.NoEditingAllowed);
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	Item.Appearance.SetParameterValue("Enabled", False);
	
EndProcedure

// Constructor of the structure of parameters for embedding software in a document.
//
// Returns:
//  Structure - structure with fields:
//   * ObjectName - String - full name of the object.
//   * TableName - String - the name of the document's product table.
//   * NameOfShipmentRegistrationRegister - String - name of the register that stores information about the issued quantity on the order
//   * FormTableName - String - Name of the tabular part of the order form
//   * ConditionalAppearance - Structure - structure with fields:
//      ** FormItems - Structure - structure with fields:
//        *** SupplyOption - String - the name of the element in the form that is associated with the form's attribute of the same name.
//        *** Available - String - the name of the element in the form that is associated with the form's attribute of the same name.
//        *** Series - String - the name of the element in the form that is associated with the form's attribute of the same name.
//        *** WithAssignment - String - the name of the element in the form that is associated with the form's attribute of the same name.
//        *** Warehouse - String - the name of the element in the form that is associated with the form's attribute of the same name.
//       ** DataPaths - Structure - structure with fields:
//        *** ReallocateInventory - String - the path to the details of the goods list that stores the inventory reallocation attribute in the line.
//        *** NoEditingAllowed - String - the path to the details of the list of products in which the sign of the prohibition of editing in the line is stored.
//   * PropsAvailable - Structure - structure with fields:
//    ** TagName - String - the name of the element is "Available".
//   * PropsRedistributeInventory - Structure - structure with fields:
//    ** DataPath - String - the path to the data of the inventory reallocation props.
//   * PropsSecurityOption - Structure - structure with fields:
//    ** TagName - String - the name of the "Support options" element.
//   * DescriptionOfGettingDocumentData - String - the text of the request for the temporary data table of the document.
//   * AddressOfMotionCorrection - String - the name of the prop for storing the address of the document movement adjustment.
//   * FormDataSerializationPattern - Structure - contains the names of the tables used in the description of getting object data and the path to the data of these tables on the form.
//   * RelationshipFieldsOfTableParts - Structure - table connection fields, for extracting data from a document form.
//   * ExpressionForQuestionWhenPerformingActionInOrderList - String - string to be inserted into the query.
//   * ConnectionsOfSoftwareOptionSelectionParameters - Structure - structure with fields:
//    ** Available - String - The name of the corresponding field on the form.
//    ** NumberOfPackages - String - The name of the corresponding field on the form.
//    ** Count - String - The name of the corresponding field on the form.
//    ** ShipIfAvailable - String - The name of the corresponding field on the form.
//    ** WithAssignment - String - The name of the corresponding field on the form.
//    ** ItemsType - String - The name of the corresponding field on the form.
//    ** Package - String - The name of the corresponding field on the form.
//    ** Products - String - The name of the corresponding field on the form.
//    ** SupplyOption - String - The name of the corresponding field on the form.
//    ** Warehouse - String - The name of the corresponding field on the form.
//    ** MultipleWarehouses - String - The name of the corresponding field on the form.
//    ** UsePartialShipment - Boolean - True if it is allowed to split lines, False if it is not allowed.
//   * ItemsNames - Structure - structure with fields:
//    ** PagesHyperlinkSoftwareStatus - String - the name of the appropriate field on the form.
//    ** PageHyperlinkSoftwareStatus - String - the name of the appropriate field on the form.
//    ** SecurityStatusHyperlink - String - the name of the appropriate field on the form.
//    ** PageHyperlinkSecurityStatusIsBeingShipped - String - the name of the appropriate field on the form.
//    ** HyperlinkSecurityStatusIsBeingShipped - String - the name of the appropriate field on the form.
//    ** PageHyperlinkSoftwareStatusIssue - String - the name of the appropriate field on the form.
//    ** HyperlinkSecurityStatusIssue - String - the name of the appropriate field on the form.
//   * UseEventSubscriptions - Structure - structure with fields:
//    ** BeforePerformingActionsInOrderList - Boolean - if true, then you need to define a procedure in the order manager module
//       with the name before performing the actions in the list of orders and parameters:
//         Orders - Array from any link
//         Action Code - String.
//         The message to the user is an array from the Structure.
//   * AttributesToBeCleared - String - the Names Of The Object Attributes that are cleared when adding new lines when filling in actions in the table parts of the document.
Function AvailableRemainingEmbeddingOptions() Export
	
	EmbeddingParameters = New Structure();
	EmbeddingParameters.Insert("AttributesToBeCleared");
	
	UseEventSubscriptions = New Structure();
	UseEventSubscriptions.Insert("BeforePerformingActionsInOrderList", False);
	EmbeddingParameters.Insert("UseEventSubscriptions", UseEventSubscriptions);
	
	EmbeddingParameters.Insert("ObjectName");
	EmbeddingParameters.Insert("TableName");
	EmbeddingParameters.Insert("NameOfShipmentRegistrationRegister");
	EmbeddingParameters.Insert("FormTableName");
	
	EmbeddingParameters.Insert("ConditionalAppearance", New Structure());
	EmbeddingParameters.ConditionalAppearance.Insert("FormItems",
		New Structure(
			"SupplyOption,
			|Available,
			|Series,
			|WithAssignment,
			|Warehouse"));
	EmbeddingParameters.ConditionalAppearance.Insert("DataPaths",
		New Structure(
			"ReallocateInventory,NoEditingAllowed,ItemsType"));

	EmbeddingParameters.Insert("PropsAvailable",               New Structure("TagName"));
	EmbeddingParameters.Insert("PropsRedistributeInventory", New Structure("DataPath"));
	EmbeddingParameters.Insert("PropsSecurityOption",     New Structure("TagName"));
	
	EmbeddingParameters.Insert("DescriptionOfGettingDocumentData");
	EmbeddingParameters.Insert("AddressOfMotionCorrection");
	EmbeddingParameters.Insert("FormDataSerializationPattern",  New Structure());
	EmbeddingParameters.Insert("RelationshipFieldsOfTableParts",       New Structure());
	
	EmbeddingParameters.Insert("ExpressionForQuestionWhenPerformingActionInOrderList",
		"CASE WHEN Table.NotShipInInstallments THEN
		|			Table.DateOfShipment
		|		ELSE
		|			UNDEFINED
		|	END");
	
	EmbeddingParameters.Insert("ConnectionsOfSoftwareOptionSelectionParameters",
		New Structure(
			"Available,
			|NumberOfPackages,
			|Count,
			|ShipIfAvailable,
			|WithAssignment,
			|ItemsType,
			|Package,
			|Products,
			|SupplyOption,
			|Warehouse,
			|MultipleWarehouses,
			|UsePartialShipment"));
		
	ItemsNames = New Structure();
	ItemsNames.Insert("PagesHyperlinkSoftwareStatus", "PagesHyperlinkSoftwareStatus");
	ItemsNames.Insert("PageHyperlinkSoftwareStatus", "PageHyperlinkSoftwareStatus");
	ItemsNames.Insert("SecurityStatusHyperlink", "SecurityStatusHyperlink");
	ItemsNames.Insert("PageHyperlinkSecurityStatusIsBeingShipped", "PageHyperlinkSecurityStatusIsBeingShipped");
	ItemsNames.Insert("HyperlinkSecurityStatusIsBeingShipped", "HyperlinkSecurityStatusIsBeingShipped");
	ItemsNames.Insert("PageHyperlinkSoftwareStatusIssue", "PageHyperlinkSoftwareStatusIssue");
	ItemsNames.Insert("HyperlinkSecurityStatusIssue", "HyperlinkSecurityStatusIssue");
	ItemsNames.Insert("PageHyperlinkStateOfProvisionWithTitle", "PageHyperlinkStateOfProvisionWithTitle");
	ItemsNames.Insert("ProvisionStateHyperlinkWithTitle", "ProvisionStateHyperlinkWithTitle");
	
	EmbeddingParameters.Insert("ItemsNames", ItemsNames);
	
	Return EmbeddingParameters;
	
EndFunction

// Updates the "Available" column in the order forms.
//
// Parameters:
//  Form - ClientApplicationForm - order form.
//
Procedure UpdateColumnAvailable(Form) Export
	
	If Not AccessRight("Read", Metadata.AccumulationRegisters.InventoryAndDemands) Then
		Return;
	EndIf;
	
	EmbeddingParameters = Form.AvailableRemainingEmbeddingOptions;
	Tables = GetFromTempStorage(EmbeddingParameters.InternalParameters.AddressOfFormDataTable);
	FillInTablesFromFormData(Tables, Form);
	
	Query = New Query();
	Query.TempTablesManager = New TempTablesManager();
	AddTemporaryDocumentDataTable(Query.TempTablesManager, Tables, EmbeddingParameters);
	
	ChangesTable = UploadDocumentChangeTable(Query.TempTablesManager, Form);
	
	AddressOfBalances = Form.AvailableRemainingEmbeddingOptions.AddressOfBalances;
	Balance = GetFromTempStorage(AddressOfBalances);
	Balance.ChangesToDocument = ChangesTable;
	PutToTempStorage(Balance, AddressOfBalances);
	
	AvailableBalancesToReplenish(Form, Undefined, Query);
	
EndProcedure

// Filling in the service details of the tabular part and the header of the form
// required for conditional registration.
// Form details to be filled in:
//  Form.The date of the shipment is mandatory
//  Form.The warehouse is obligatory
//  Collection string.The date of the shipment is mandatory
//  Collection string.The warehouse is obligatory
// Event for processing tabular parts:
//  "When changing the nomenclature or support options".
// 
// Parameters:
//  DocumentParameters - Structure - Form data:
//   * Collection - FormDataCollection - the form table associated with the shipment order
//   * Object    - FormDataStructure - the form object associated with the shipment order,
//                                        including the "Link" field for determining the type of the shipment order.
Procedure FillInServiceDetailsOfDocumentForm(DocumentParameters) Export
	
	Collection = DocumentParameters.Collection;
	If Collection.Count() = 0 Then
		Return;
	EndIf;
	Form = DocumentParameters.Form;
	EmbeddingParameters = Form.AvailableRemainingEmbeddingOptions;
	Tables = GetFromTempStorage(EmbeddingParameters.InternalParameters.AddressOfFormDataTable);
	FillInTablesFromFormData(Tables, Form);
	TempTablesManager = New TempTablesManager();
	Query = New Query();
	Query.TempTablesManager = TempTablesManager;
	AddTemporaryDocumentDataTable(Query.TempTablesManager, Tables, EmbeddingParameters);
	
	Query.SetParameter("OnlyErrors", False);
	Table = MandatoryTableForTemporaryDocumentDataTable(Query);
	
	For Each String In Table Do
		FillPropertyValues(
			Collection.FindByID(String.LineNumber),
			String,
			"WarehouseIsRequired,DateOfShipmentRequired_");
	EndDo;
	
	ProvisionInDocumentsClientServer.FillInServiceDetails(
		Collection,
		Form.DateOfShipmentRequired_,
		Form.WarehouseIsRequired);
	
EndProcedure

// Updates the date of shipment in the header and table part after filling in the security in the order.
//
// Parameters:
//  FillParameters - See ProvisionInDocumentsClient.ParametersForProcessingShipmentDatesAfterFillingInCollateral
//  NotShipInInstallments - Boolean - the "Do not ship parts" flag of the document.
//  DateOfShipment - Date - the date of shipment from the document header.
//  Goods - FormDataCollection - the tabular part of the document.
//  FieldName - String - the name of the shipment date field in the table part of the order.
//  ThereIsPreviouslyTransmitted - Boolean - in the tabular part, there may be lines with the action passed earlier, it is necessary to clear the shipment date for them.
// Returns:
//  Boolean - True if there are shipment date changes
Function UpdateShipmentDate(FillParameters, NotShipInInstallments, DateOfShipment, Goods, FieldName, ThereIsPreviouslyTransmitted = False) Export
	
	If FillParameters = Undefined Then
		Return False;
	EndIf;
	
	If FillParameters.UncheckShipByOneDateFlag Then
		
		NotShipInInstallments = False;
		For Each String In Goods Do
			If ThereIsPreviouslyTransmitted And String.SupplyOption = Enums.SupplyOptions.TransferedEarlier Then
				String[FieldName] = '00010101';
			Else
				String[FieldName] = DateOfShipment;
			EndIf;
		EndDo;
		
	EndIf;
	
	If FillParameters.FillShippingDateWithSingleDate Then
		
		DateOfShipment = BegOfDay(CurrentSessionDate());
		For Each String In Goods Do
			If ThereIsPreviouslyTransmitted And String.SupplyOption = Enums.SupplyOptions.TransferedEarlier Then
				String[FieldName] = '00010101';
			Else
				String[FieldName] = DateOfShipment;
			EndIf;
		EndDo;
		
	EndIf;
	
	Return FillParameters.FillShippingDateWithSingleDate;
	
EndFunction

// Filling in the shipment date in the order line with the date from the header if the order is shipped on the same date or the Cur date
// if the "Ship" action is set in the line if the shipment date is unfilled or expired in the line.
// 
// Parameters:
//  Changes                      - Array         - array of rows of the tabular part of the document in which to perform the action.
//  FieldName                        - String         - the name of the shipment date field in the table part.
//  ShipInOneDay            - Boolean         - indicates that the order is shipped on the same date.
//  DateOfShipment                   - Date           - the date of shipment by a single date specified in the header of the document.
// Returns:
//  Boolean - True if the shipping dates in the lines have changed
Function CheckFillInShipmentDateForShipLines(Changes, FieldName, ShipInOneDay, DateOfShipment = Undefined) Export
	
	ShipOption = Enums.SupplyOptions.Ship;
	ShipmentDateHasChanged = False;
	
	If ShipInOneDay Then
		
		For Each String In Changes Do
			String[FieldName] = DateOfShipment;
		EndDo;
		
	Else
		
		FillValue = CurrentSessionDate();
		For Each String In Changes Do
			
			NeedToFillIn = String.SupplyOption = ShipOption
				And (Not ValueIsFilled(String[FieldName]) Or FillValue > String[FieldName]);
			If NeedToFillIn Then
				String[FieldName] = FillValue;
				If Not ShipmentDateHasChanged Then
					ShipmentDateHasChanged = True;
				EndIf;
			EndIf;
			
		EndDo;
		
	EndIf;
	
	Return ShipmentDateHasChanged;
	
EndFunction

// Calculates the shipment date of the order line after selecting the items.
//
// Parameters:
//  DateOfShipment - Date - the date of shipment from the document header.
//  SupplyOption - EnumRef.SupplyOptions - security option in the line.
//  BegOfDay - String - the beginning of the current day.
//
//  Returns:
//   Date - date of shipment.
//
Function ShipmentDateProcessingSelectionSelection(DateOfShipment, SupplyOption, BegOfDay) Export
	
	FillValue = DateOfShipment;
	
	If Not ValueIsFilled(FillValue) Then
		
		If SupplyOption = Enums.SupplyOptions.Ship Then
				
				FillValue = BegOfDay;
				
		EndIf;
		
	EndIf;
	
	Return FillValue;
	
EndFunction

// Updates the shipment date in the header after filling in the security in the order.
//
// Parameters:
//  ShipInOneDay - Boolean - the "Do not ship parts" flag of the document.
//  DateOfShipment - Date - the date of shipment from the document header.
//  Collection - FormDataCollection - the tabular part of the document.
//  FieldName - String - the name of the shipment date field in the table part of the order.
//
Procedure UpdateShipmentDateWithSingleDate(ShipInOneDay, DateOfShipment, Collection, FieldName) Export
	
	If ShipInOneDay Then
		
		MaxValue = '00010101';
		For Each String In Collection Do
			If String[FieldName] > MaxValue Then
				MaxValue = String[FieldName];
			EndIf;
		EndDo;
		
		DateOfShipment = Max(MaxValue, DateOfShipment);
		
		For Each String In Collection Do
			String[FieldName] = DateOfShipment;
		EndDo;
		
	EndIf;
	
EndProcedure

// Adds to the form the conditional design of the element (mark blank), based on the value of the document status
// according to the following rule: if the details are not filled in and the status is not included in a certain list of statuses,then the mark
// is set or removed.
//
// Parameters:
//   ConditionalAppearance - DataCompositionConditionalAppearance - conditional form design.
//   TagName - String - name of the element for the conditional design.
//   AttributeName - Arbitrary - Form details associated with the form element.
//   TSName - String - name of the table part, if you want to format the form table field.
//   DraftStatus - Array - list of statuses.
//
Procedure SetUncheckBlankByStatus(ConditionalAppearance, TagName, AttributeName, TSName, DraftStatus) Export
	
	AttributePath1 = "Object.Goods.AttributeName";
	AttributePath1 = StrReplace(AttributePath1, "Goods", TSName + ".");
	
	Substitution = ?(TSName = "", "", TSName + ".");
	AttributePath1 = "Object.Goods.AttributeName";
	AttributePath1 = StrReplace(AttributePath1, "Goods.", Substitution);
	AttributePath1 = StrReplace(AttributePath1, "AttributeName", AttributeName);
	
	// Setting the mark.
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(TagName);
	
	Filter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	Filter.LeftValue = New DataCompositionField(AttributePath1);
	Filter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	Filter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	Filter.LeftValue = New DataCompositionField("Object.Status");
	Filter.ComparisonType = DataCompositionComparisonType.NotInList;
	Filter.RightValue = DraftStatus;
	
	Item.Appearance.SetParameterValue("MarkIncomplete", True);
	
	// Removing the mark.
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(TagName);
	
	Filter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	Filter.LeftValue = New DataCompositionField("Object.Status");
	Filter.ComparisonType = DataCompositionComparisonType.InList;
	Filter.RightValue = DraftStatus;
	
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	
	// Removing the mark.
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(TagName);
	
	Filter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	Filter.LeftValue = New DataCompositionField(AttributePath1);
	Filter.ComparisonType = DataCompositionComparisonType.Filled;
	
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	
EndProcedure

// Filling in the shipment date in the table part of the order
// Specifies the maximum value of the field in the value collection column.
//
// Parameters:
//  Collection - FormDataCollection - The collection to fill in the field in.
//  FieldName - String - name of the search column.
//  InitialValue - Number - the initial value on which to search for max. value.
//
// Returns:
//  Number - The maximum value of the field.
//
Function MaximumValueInCollection(Collection, FieldName, InitialValue) Export

	MaxValue = InitialValue;
	For Each String In Collection Do

		If String[FieldName] > MaxValue Then
			MaxValue = String[FieldName];
		EndIf;

	EndDo;

	Return MaxValue;

EndFunction

// Filling in the shipment date in the table part of the order
// Fills in the value of the field in the rows of the value collection.
//
// Parameters:
//  Collection - FormDataCollection - The collection to fill in the field in.
//  FieldName - String - the name of the column that needs to be filled.
//  FillValue - AnyRef, Number, Date, Boolean - The value to fill in.
//  SelectedRows - Array - lines to fill in the value in.
//
Procedure FillInDetailsInCollection(Collection, FieldName, FillValue, SelectedRows = Undefined) Export

	If SelectedRows = Undefined Then

		For Each TableRow In Collection Do
			TableRow[FieldName] = FillValue;
		EndDo;

	Else

		For Each RowID In SelectedRows Do
			TableRow = Collection.FindByID(RowID);
			TableRow[FieldName] = FillValue;
		EndDo;

	EndIf;

EndProcedure

// Returns the text in the "rows affected".
// 
// Parameters:
//   Count - Number - the number of rows worked out.
//
// Returns:
//   String - the text "Processed rows: number".
//
Function TextProcessedLines(Count) Export
	Return StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = 'Đã xử lý dòng: %1';
																		|ru = 'Обработано строк: %1';
																		|en = 'Processed lines: %1'; fa = 'Processed lines: %1';
																		|it = 'Elaborate righe: %1';
																		|pl = 'Przetworzono wierszy: %1';
																		|tr = 'İşlenen satır: %1'"), Count);
EndFunction

// Returns the text "Desired shipment date".
// 
// Returns:
//   String - the text "Desired shipment date".
//
Function HintShipmentDate() Export
	Return NStr("vi = 'Ngày giao hàng mong muốn';
				|ru = 'Желаемая дата отгрузки';
				|en = 'Requested shipment date'; fa = 'Requested shipment date';
				|it = 'Data preferibile di spedizione';
				|pl = 'Planowana data wysyłki';
				|tr = 'İstenen sevkiyat tarihi'");
EndFunction

// Adds the conditional design of the element associated with the "Separate" flag in the order.
//
// Parameters:
//  ConditionalAppearance - DataCompositionConditionalAppearance - conditional form design.
//  FormElementApart - FormField - a form element associated with the "Isolated"attribute.
//  DataPathSoftwareOption - String - the path to the data in the "Security Option" field.
//  DataPathProductType  - String - the data path to the Item Type field.
//
Procedure SetConditionalAppearanceApart(ConditionalAppearance, FormElementApart, DataPathSoftwareOption, DataPathProductType) Export
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(FormElementApart.Name);
	
	ListOfProductTypes = New ValueList();
	ListOfProductTypes.Add(Enums.ItemsTypes.ReusablePackage);
	ListOfProductTypes.Add(Enums.ItemsTypes.OperationService);
	
	Filter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	Filter.LeftValue = New DataCompositionField(DataPathProductType);
	Filter.ComparisonType = DataCompositionComparisonType.InList;
	Filter.RightValue = ListOfProductTypes;
	Item.Appearance.SetParameterValue("ReadOnly", True);
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(FormElementApart.Name);
	
	Filter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	Filter.LeftValue = New DataCompositionField(DataPathSoftwareOption);
	Filter.ComparisonType = DataCompositionComparisonType.Equal;
	Filter.RightValue = Enums.SupplyOptions.Ship;
	Item.Appearance.SetParameterValue("ReadOnly", True);
	
EndProcedure

// Checks whether the user has the right to view the security status hyperlink in the order
//
// Returns:
//  Boolean  - The truth if there is a right, a lie - otherwise.
//
Function HaveRightToViewStateHyperlink() Export
	
	Return AccessRight("View", Metadata.DataProcessors.OrderSupplyForecast);
	
EndFunction

////////////////////////////////////////////////////////////////////////////////
// Serving forms of document lists

// Performs the action of filling in the security in the order from the list of orders.
//
// Parameters:
//  Orders - Array of AnyRef - orders highlighted in the list for performing provisioning actions.
//  ActionCode - String - the symbol of the command "ACTION_TO SUPPORT" or "ACTION_TO LOAD"
//                         or "ACTION_TO RESERVE" or "ACTION_TO PROVIDE" or "ROLLBACK ACTION_TO LOAD".
//  UUID - UUID - the unique ID of the form that will
//                                                       store the result of the execution in the background.
//  EmbeddingParametersIncoming - See AvailableRemainingEmbeddingOptions
//
// Returns:
//  Structure - the result of performing actions on orders.
//
Function PerformActionForOrders(Orders, ActionCode, UUID, EmbeddingParametersIncoming) Export
	
	EmbeddingParameters = EmbeddingParametersIncoming;
	If Orders.Count() > 0 Then
		ManagerOfDocument = Common.ObjectManagerByRef(Orders[0]);
		If EmbeddingParameters = Undefined Then
			EmbeddingParameters = ManagerOfDocument.AvailableRemainingEmbeddingOptions();
		EndIf;
	EndIf;
	Parameters = New Structure("Orders,ActionCode", Orders,ActionCode);
	FillParameters = Undefined;
	
	If ActionCode = "ACTION_LOAD" And Orders.Count() > 0 Then
		
		Result = New Structure();
		Result.Insert("NeedQuestion", NeedQuestionAboutShippingByOneDate(EmbeddingParameters, Orders));
		DateWhenTheNewLinesWereShipped = BegOfDay(CurrentSessionDate());
		Result.Insert("DateWhenTheNewLinesWereShipped", DateWhenTheNewLinesWereShipped);
		
		If Not Result.NeedQuestion Then
			
			Parameters.Insert("FillParameters", FillParameters);
			Parameters.Insert("EmbeddingParameters", EmbeddingParameters);
			Result = PerformActionForOrdersAfterQuestionByBackgroundTask(Parameters, UUID);
			
		Else
			Result.Insert("EmbeddingParameters", EmbeddingParameters);
		EndIf;
		
	Else
		
		Parameters.Insert("FillParameters", FillParameters);
		Parameters.Insert("EmbeddingParameters", EmbeddingParameters);
		Result = PerformActionForOrdersAfterQuestionByBackgroundTask(Parameters, UUID);
		
	EndIf;
	
	Return Result;
	
EndFunction

// Performs the action of filling in the security in the order from the list of orders after setting the question about the shipment by a single date.
//
// Parameters:
//  Parameters - Structure - parameter structure:
//   * ActionCode - String - the symbol of the command "ACTION_TO SUPPORT" or "ACTION_TO LOAD"
//                   or "ACTION_TO RESERVE" or "ACTION_TO PROVIDE" or "ROLLBACK ACTION_TO LOAD".
//   * FillParameters - Structure - parameter structure:
//     ** UncheckShipByOneDateFlag - Boolean - the result of answering a question about a single-date shipment.
//     ** FillShippingDateWithSingleDate - Boolean - the result of answering a question about a single-date shipment.
//   * Orders - Array of AnyRef - orders to set the action.
//   * EmbeddingParameters - See AvailableRemainingEmbeddingOptions
//  FillInShipmentDateForcibly - Boolean - True if you need to fill in the shipment date even if there are no changes in the document.
//  Load - Boolean - True, if necessary, the object must be recorded in a deceptive mode.Download.
//
// Returns:
//  Structure - structure with fields:
//   * ErrorList - Array - an array containing the texts of document processing errors.
//   * QuantityProcessed - Number - the number of documents processed.
//
Function PerformActionForOrdersAfterQuestion(Parameters, FillInShipmentDateForcibly = False, Load = False) Export
	
	Orders = Parameters.Orders;
	UserMessages = New Array();
	EmbeddingParameters = Parameters.EmbeddingParameters;
	ActionCode = Parameters.ActionCode;
	If Orders.Count() > 0 Then
		
		ObjectManager = Common.ObjectManagerByRef(Orders[0]);
		If EmbeddingParameters = Undefined Then
			EmbeddingParameters = ObjectManager.AvailableRemainingEmbeddingOptions();
		EndIf;
		If EmbeddingParameters.UseEventSubscriptions.BeforePerformingActionsInOrderList Then
			ObjectManager.BeforePerformingActionsInOrderList(Orders, ActionCode, UserMessages);
		EndIf;
		
	EndIf;
	FillParameters = Parameters.FillParameters;
	Result = New Structure("ErrorList,QuantityProcessed", New Array(), 0);
	For Each Item In UserMessages Do
		Result.ErrorList.Add(Item);
	EndDo;
	UserMessages.Clear();
	Processed = 0;
	
	For Each Ref In Orders Do
		
		ErrorText = "";
		
		BeginTransaction();
		Try
			
			ErrorText = NStr("vi = 'Không thể phong tỏa đối tượng, có thể là đối tượng đang được soạn. Đối với %1 chưa thực hiện thiết lập thao tác.';
							|ru = 'Не удалось заблокировать объект, возможно он редактируется. Для %1 установка действия не выполнена.';
							|en = 'Cannot lock the object, it may be being edited. Cannot set action for %1.'; fa = 'Cannot lock the object, it may be being edited. Cannot set action for %1.';
							|it = 'Non è stato possibile bloccare l''oggetto, potrebbe essere in modifica. Impostazione di azione per %1 non riuscita.';
							|pl = 'Nie udało się zablokować obiektu, może jest on edytowany. Dla %1 nie wykonano ustawienia działania.';
							|tr = 'Nesne kilitlenemedi, düzenleniyor olabilir. %1 için işlem ayarı gerçekleştirilemedi.'");
			
			LockDataForEdit(Ref);
			
			Block = New DataLock();
			
			LockItem = Block.Add(Ref.Metadata().FullName());
			LockItem.SetValue("Ref", Ref);
			LockItem.Mode = DataLockMode.Exclusive;
			
			ErrorText = NStr("vi = 'Không thể đặt phong tỏa đối tượng. Đối với %1 chưa đặt thao tác.';
							|ru = 'Не удалось установить блокировку объекта. Для %1 установка действия не выполнена.';
							|en = 'Cannot set object lock. Cannot set action for %1.'; fa = 'Cannot set object lock. Cannot set action for %1.';
							|it = 'Non è stato possibile impostare il blocco dell''oggetto, Impostazione di azione per %1 non riuscita.';
							|pl = 'Nie udało się ustawić blokowania obiektu. Dla %1 nie wykonano ustawienia działania.';
							|tr = 'Nesne kilidi ayarlanamadı. %1 için işlem ayarı gerçekleştirilemedi.'");
			
			Block.Lock();
			
			ErrorText = NStr("vi = 'Không thể xử lý đối tượng. Đối với %1 chưa đặt thao tác.';
							|ru = 'Не удалось обработать объект. Для %1 установка действия не выполнена.';
							|en = 'Cannot process object. Cannot set action for %1.'; fa = 'Cannot process object. Cannot set action for %1.';
							|it = 'Non è stato possibile elaborare l''oggetto. Impostazione di azione per %1 non riuscita.';
							|pl = 'Nie udało się przetworzyć obiektu. Dla %1 nie wykonano ustawienia działania.';
							|tr = 'Nesne işlenemedi. %1 için işlem ayarı gerçekleştirilemedi.'");
			
			DocumentObject = Ref.GetObject();
			If FillInShipmentDateForcibly Then
				DocumentObject.AdditionalProperties.Insert("FillInShipmentDateForcibly");
			EndIf;
			If DocumentObject.Posted And (ActionCode = "ACTION_LOAD" Or ActionCode = "Action_Ship_PRIORITY_WithAssignment") Then
				
				QuestionWasAsked = FillParameters <> Undefined;
				NeedQuestion = EmbeddingParameters.ExpressionForQuestionWhenPerformingActionInOrderList <> "UNDEFINED"
					And NeedQuestionAboutShippingByOneDate(EmbeddingParameters, Ref);
				
				If Not QuestionWasAsked And NeedQuestion Then
					ErrorText = NStr("vi = 'Đã thay đổi dữ liệu chứng từ %1. Chưa thiết lập thao tác.';
									|ru = 'Изменились данные документа %1. Установка действия не выполнена.';
									|en = 'The %1 document data is changed. The action setup failed.'; fa = 'The %1 document data is changed. The action setup failed.';
									|it = 'Изменились данные документа %1. Установка действия не выполнена.';
									|pl = 'The %1 document data is changed. The action setup failed.';
									|tr = '%1 belgesinin verileri değişti. Eylemin yapılandırılması başarısız oldu.'");
					Raise ErrorText;
				EndIf;
					
			EndIf;
			
			If DocumentObject.Posted Then
				
				FillingResult = FillInBalanceProvisionOptionForSelectedObjectRows(
					DocumentObject,
					ActionCode,
					FillParameters,
					Undefined,
					EmbeddingParameters);
				ChangesTable = FillingResult.ChangesTable;
				ThereAreLinesWithEmptyWarehouse = FillingResult.Warnings.ThereAreLinesWithEmptyWarehouse;
				If ThereAreLinesWithEmptyWarehouse Then
					ErrorText = NStr("vi = 'Trong chứng từ %1 có hàng hóa mà đối với chúng chưa chỉ ra kho giao. Không thể thiết lập thao tác đối với những hàng hóa như vậy.';
									|ru = 'В документе %1 есть товары для которых не указан склад отгрузки. Установка действия для таких товаров не выполнялась.';
									|en = 'In the %1 document, there are goods without the specified origin warehouse. Cannot set the action for such goods.'; fa = 'In the %1 document, there are goods without the specified origin warehouse. Cannot set the action for such goods.';
									|it = 'Nel documento %1 vi sono merci per le quali non è indicato il magazzino di spedizione. Non è stata seguita l''impostazione dell''attività per queste merci.';
									|pl = 'Dokument %1 zawiera towary, dla których nie jest określony magazyn wysyłki. Ustawienia czynności dla takich towarów nie była wykonan.';
									|tr = '%1 belgesinde, sevkiyat ambarı belirtilmeyen ürünler mevcut. Bu tür ürünler için işlem gerçekleştirilemedi.'");
					Result.ErrorList.Add(New Structure("Text,Ref", StrTemplate(ErrorText, Ref), Ref));
				EndIf;
				
				WriteMode = DocumentWriteMode.Posting;
				
				ErrorText = NStr("vi = 'Không thể ghi lại/kết chuyển đối tượng. Đối với %1 chưa đặt thao tác.';
								|ru = 'Не удалось записать/провести объект. Для %1 установка действия не выполнена.';
								|en = 'Cannot save/post object. Cannot set action for %1.'; fa = 'Cannot save/post object. Cannot set action for %1.';
								|it = 'Non è stato possibile salvare/registrare l''oggetto. Impostazione di azione per %1 non riuscita.';
								|pl = 'Nie udało się zapisać/zatwierdzić obiektu. Dla %1 nie wykonano ustawienia działania.';
								|tr = 'Nesne kaydedilmedi. %1 için işlem ayarı gerçekleştirilemedi.'");
				
				If Load Then
					DocumentObject.DataExchange.Load = True;
					DocumentObject.Write();
				ElsIf DocumentObject.CheckFilling() Then
					DocumentObject.Write(WriteMode);
				Else
					
					Result.ErrorList.Add(New Structure("Text,Ref", StrTemplate(ErrorText, Ref), Ref));
					
					For Each CurError In GetUserMessages(True) Do
						
						Error = New Structure;
						Error.Insert("Ref", Ref);
						Error.Insert("Text",  CurError.Text);
						Error.Insert("Field",   CurError.Field);
						Error.Insert("DataPath", CurError.DataPath);
						
						Result.ErrorList.Add(Error);
						
					EndDo;
					
				EndIf;
				
				Processed = Processed + ?(ChangesTable.Count() > 0, 1, 0);
				
			Else
				ErrorText = NStr("vi = 'Chứng từ %1 chưa được kết chuyển và sẽ chưa được xử lý.';
								|ru = 'Документ %1 не проведен и не будет обработан.';
								|en = 'Document %1 has not been posted and will not be processed.'; fa = 'Document %1 has not been posted and will not be processed.';
								|it = 'Documento %1 non è registrato e non sarà elaborato.';
								|pl = 'Dokument%1 nie jest zatwierdzony i nie będzie przetworzony.';
								|tr = '%1 belgesi kaydedilmedi ve işlenmeyecek.'");
				Result.ErrorList.Add(New Structure("Text,Ref", StrTemplate(ErrorText, Ref), Ref));
			EndIf;
			
			CommitTransaction();
			
		Except
			
			RollbackTransaction();
			
			LogParameters = New Structure("EventGroup_, Metadata, Data");
			LogParameters.EventGroup_ = NStr("vi = 'Điền thao tác trong đơn hàng';
											|ru = 'Заполнение действий в заказе';
											|en = 'Action population in order'; fa = 'Action population in order';
											|it = 'Compilazione di azioni nell''ordine';
											|pl = 'Wypełnienie działań w zamówieniu';
											|tr = 'Siparişteki işlemleri doldurma'");
			LogParameters.Metadata    = Ref.Metadata();
			LogParameters.Data        = Ref;
			TMCommonUse.LogReportToUser(
				LogParameters,
				EventLogLevel.Information,
				NStr("vi = 'Điền thao tác trong đơn hàng';
					|ru = 'Заполнение действий в заказе';
					|en = 'Action population in order'; fa = 'Action population in order';
					|it = 'Compilazione di azioni nell''ordine';
					|pl = 'Wypełnienie działań w zamówieniu';
					|tr = 'Siparişteki işlemleri doldurma'"),
				DetailErrorDescription(ErrorInfo()));
			
			Result.ErrorList.Add(New Structure("Text,Ref", StrTemplate(ErrorText, Ref), Ref));
			
		EndTry;
		
	EndDo;
	Result.QuantityProcessed = Processed;
	
	Return Result;
	
EndFunction

// Performs the action of filling in the security in the order from the list of orders after setting the question about the shipment by a single date.
//
// Parameters:
//  DocumentObject - DocumentObject.SalesOrder, DocumentObject.TransferOrder - the document being processed, any order.
//  ActionCode - String - The symbol of the provision option is "ACTION_TO ENSURE" or "ACTION_TO LOAD"
//                           or "ACTION_TO RESERVE" or "ACTION_TO PROVIDE" or "ROLLBACK ACTION_TO LOAD".
//  FillParameters - Structure - parameter structure:
//   * UncheckShipByOneDateFlag - Boolean - the result of answering a question about a single-date shipment.
//   * FillShippingDateWithSingleDate - Boolean - the result of answering a question about a single-date shipment.
//  Rows - Array of FormDataCollection - an array containing the strings to be processed in the document.
//  EmbeddingParameters - See AvailableRemainingEmbeddingOptions
//  AdditionalParameters - Structure - additional parameters used to obtain Balances.
//
// Returns:
//  Structure - structure with fields:
//   * ChangesTable - See TableForSettingActions
//   * Warnings - Structure - structure with fields:
//     ** ThereAreLinesWithEmptyWarehouse - Boolean
//  
Function FillInBalanceProvisionOptionForSelectedObjectRows(DocumentObject, ActionCode, FillParameters, Rows = Undefined, EmbeddingParameters = Undefined, AdditionalParameters = Undefined) Export
	
	ObjectManager = Common.ObjectManagerByRef(DocumentObject.Ref);
	
	If EmbeddingParameters = Undefined Then
		EmbeddingParameters = ObjectManager.AvailableRemainingEmbeddingOptions();
	EndIf;
	
	InternalParameters = New Structure("IsDocument", True);
	EmbeddingParameters.Insert("InternalParameters", InternalParameters);
	
	Tables = New Map();
	InsertTables(Tables, EmbeddingParameters.FormDataSerializationPattern, "");
	FillInTableNamesAsAppropriate(EmbeddingParameters, Tables);
	
	QueryText = QueryTextTemporaryDocumentDataTable(EmbeddingParameters, Tables);
	InternalParameters.Insert("QueryTextTemporaryDocumentDataTable", QueryText);
	
	FillInTablesFromObject(Tables, New Structure("Object", DocumentObject));
	
	Query = New Query();
	Query.TempTablesManager = New TempTablesManager();
	AddTemporaryDocumentDataTable(Query.TempTablesManager, Tables, EmbeddingParameters);
	
	ThereAreLinesWithEmptyWarehouse = False;
	If ActionCode = "ACTION_LOAD" Or ActionCode = "ACTION_RESERVE"
		Or ActionCode = "Action_Ship_PRIORITY_WithAssignment" Or ActionCode = "Action_ToReserve__PRIORITY_WithAssignment" Then 
		Query.Text =
			"SELECT TOP 1
			|TRUE AS ThereAreRecords
			|FROM
			|	TemporaryDocumentDataTable AS Table
			|WHERE
			|	CAST(Table.Products AS Catalog.Products).ItemsType IN(
			|			VALUE(Enum.ItemsTypes.OwnGoods),
			|			VALUE(Enum.ItemsTypes.ReusablePackage))
			|		AND Table.Warehouse = VALUE(Catalog.Warehouses.EmptyRef)";
		ThereAreLinesWithEmptyWarehouse = Not Query.Execute().IsEmpty();
	EndIf;
	
	TableDecorated = TableDecorated(
		Query,
		AccumulationRegisters[EmbeddingParameters.NameOfShipmentRegistrationRegister],
		"TemporaryDocumentDataTable",
		"TemporaryDocumentDataTable");
	
	SeparateAndNonSeparateBalances = (ActionCode = "Action_Ship_PRIORITY_WithAssignment"
		Or ActionCode = "Action_ToReserve__PRIORITY_WithAssignment");
	WarehouseRemnants = BalancesForRecordedDocument(Query.TempTablesManager, SeparateAndNonSeparateBalances, AdditionalParameters);
	Query.Text =
		"SELECT
		|	Table.Products AS Products,
		|	CAST(Table.Products AS Catalog.Products).ItemsType AS ItemsType,
		|	Table.Characteristic AS Characteristic,
		|	CASE
		|		WHEN CAST(Table.Products AS Catalog.Products).ItemsType IN(
		|				VALUE(Enum.ItemsTypes.OwnGoods),
		|				VALUE(Enum.ItemsTypes.ReusablePackage))
		|			THEN Table.Warehouse
		|		ELSE Table.Department
		|	END AS Warehouse,
		|	Table.ShipmentOrder AS ShipmentOrder,
		|	Table.RowCode AS RowCode,
		|	Table.WithAssignment AS WithAssignment,
		|	
		|	CASE
		|		WHEN Table.WithAssignment
		|			THEN Table.Purpose
		|		ELSE VALUE(Catalog.Assignments.EmptyRef)
		|	END AS Purpose,
		|	
		|	Table.Purpose AS AssignmentWithoutRegardToFlagIsSeparate,
		|	Table.ControlledLotReference AS ControlledLotReference,
		|	Table.SupplyOption AS SupplyOption,
		|	Table.Package AS Package,
		|	Table.NumberOfPackages AS NumberOfPackages,
		|	Table.Count AS Count,
		|	Table.LineNumber AS CollectionItem,
		|	
		|	ISNULL((Table.Warehouse = VALUE(Catalog.Warehouses.EmptyRef)
		|		OR ISNULL(SettingUpCharacteristic.AvailableStockControl,
		|				ISNULL(SettingUpProducts.AvailableStockControl,
		|				ISNULL(SettingUpWarehouse.AvailableStockControl, FALSE))))
		|			AND NOT CAST(Table.Products AS Catalog.Products).ItemsType IN(
		|				VALUE(Enum.ItemsTypes.Work_5),
		|				VALUE(Enum.ItemsTypes.OperationService)), TRUE) AS AvailableStockControl,
		|	Table.TheShipmentDateOfAllLinesIsASingleDate AS TheShipmentDateOfAllLinesIsASingleDate
		|FROM
		|	TemporaryDocumentDataTable AS Table
		|		
		|		LEFT JOIN InformationRegister.SetUpSupplyControl AS SettingUpCharacteristic
		|		ON SettingUpCharacteristic.Warehouse          = Table.Warehouse
		|		 AND SettingUpCharacteristic.Products   = Table.Products
		|		 AND SettingUpCharacteristic.Characteristic = Table.Characteristic
		|		
		|		LEFT JOIN InformationRegister.SetUpSupplyControl AS SettingUpProducts
		|		ON SettingUpProducts.Warehouse        = Table.Warehouse
		|		 AND SettingUpProducts.Products = Table.Products
		|		 AND SettingUpProducts.Characteristic = VALUE(Catalog.ItemsCharacteristics.EmptyRef)
		|		 AND SettingUpCharacteristic.Warehouse IS NULL
		|		
		|		LEFT JOIN InformationRegister.SetUpSupplyControl AS SettingUpWarehouse
		|		ON SettingUpWarehouse.Warehouse          = Table.Warehouse
		|		 AND SettingUpWarehouse.Products   = VALUE(Catalog.Products.EmptyRef)
		|		 AND SettingUpWarehouse.Characteristic = VALUE(Catalog.ItemsCharacteristics.EmptyRef)
		|		 AND SettingUpCharacteristic.Warehouse IS NULL
		|		 AND SettingUpProducts.Warehouse IS NULL
		|WHERE
		|	NOT Table.Canceled
		|		AND NOT Table.SupplyOption = VALUE(Enum.SupplyOptions.TransferedEarlier)";
	RowsData = Query.Execute().Unload();
	
	ArrayOfPaths = StrSplit(EmbeddingParameters.TableName, ".");
	TabularSectionName = "";
	If ArrayOfPaths.Count() = 3 Then
		TabularSectionName = ArrayOfPaths[2];
	EndIf;
	If TabularSectionName = "" Then
		Collection = RowsData.Copy();
		Collection.Columns.Add("RowID", Common.TypeDescriptionNumber(15, 0));
		Collection[0].RowID = 1;
		RowsIDs = CommonClientServer.ValueInArray(1);
	Else
		Collection = DocumentObject[TabularSectionName];
		RowsIDs = DocumentObject[TabularSectionName].Unload(Rows, "LineNumber").UnloadColumn("LineNumber");
	EndIf;
	
	PackingFactors = PackingFactors(Collection, Undefined);
	DataOfAccounting = New Structure("WarehouseRemnants,TableDecorated", WarehouseRemnants, TableDecorated);
	ParametersForFillingInActions = New Structure("PopulateWithTheWholePackagings,PickUpWarehouse", False, False);
	
	ChangesTable = TableForSettingActions(
		ActionCode,
		ParametersForFillingInActions,
		Collection,
		RowsIDs,
		RowsData,
		PackingFactors,
		DataOfAccounting);
		
	If TabularSectionName = "" Then
		If ChangesTable.Count() = 1 Then
			FillPropertyValues(DocumentObject, ChangesTable[0], "SupplyOption");
		EndIf;
	Else
		SetActionsFromTable(DocumentObject[TabularSectionName], ChangesTable, EmbeddingParameters);
	EndIf;
	
	Mode = ProvisionInDocumentsClientServer.FillActionFromListMode();
	
	CurFillingParameters = Undefined;
	If (ActionCode = "ACTION_LOAD" Or ActionCode = "Action_Ship_PRIORITY_WithAssignment")
			And ChangesTable.Count() > 0 And RowsData.Count() > 0 Then
		If RowsData[0].TheShipmentDateOfAllLinesIsASingleDate <> Undefined
				And RowsData[0].TheShipmentDateOfAllLinesIsASingleDate < BegOfDay(CurrentSessionDate()) Then
			
			If FillParameters <> Undefined Then
				CurFillingParameters = New Structure(New FixedStructure(FillParameters));
			EndIf;
			
		EndIf;
	ElsIf DocumentObject.AdditionalProperties.Property("FillInShipmentDateForcibly") Then
		CurFillingParameters = New Structure(New FixedStructure(FillParameters));
	EndIf;
	If TypeOf(DocumentObject.Ref) = Type("DocumentRef.ProductionStage2_2") Then
		StatusFillingData = ProductionManagement.FillInDataWhenStatusChanges(DocumentObject);
		Documents.ProductionStage2_2.AfterFillingOutCollateral(DocumentObject, ChangesTable, Mode, CurFillingParameters,
			StatusFillingData);
	Else
		ObjectManager.AfterFillingOutCollateral(DocumentObject, ChangesTable, Mode, CurFillingParameters);
	EndIf;
	Warnings = New Structure();
	Warnings.Insert("ThereAreLinesWithEmptyWarehouse", ThereAreLinesWithEmptyWarehouse);
	Return New Structure("ChangesTable,Warnings", ChangesTable, Warnings);
	
EndFunction

////////////////////////////////////////////////////////////////////////////////
// Document Object Service Modules

// Checks the completion of the document for conducting the security registers.
//
// Parameters:
//  Object - DocumentObject - The document being checked.
//  EmbeddingParameters - See AvailableRemainingEmbeddingOptions.
// 
// Returns:
//  ValueTable - table of document filling errors.
//
Function TableOfFillingErrors(Object, EmbeddingParameters) Export
	
	InternalParameters = New Structure("IsDocument", True);
	EmbeddingParameters.Insert("InternalParameters", InternalParameters);
	
	Tables = New Map();
	InsertTables(Tables, EmbeddingParameters.FormDataSerializationPattern, "");
	FillInTableNamesAsAppropriate(EmbeddingParameters, Tables);
	
	QueryText = QueryTextTemporaryDocumentDataTable(EmbeddingParameters, Tables);
	InternalParameters.Insert("QueryTextTemporaryDocumentDataTable", QueryText);
	
	FillInTablesFromObject(Tables, New Structure("Object", Object));
	
	Query = New Query();
	Query.TempTablesManager = New TempTablesManager();
	AddTemporaryDocumentDataTable(Query.TempTablesManager, Tables, EmbeddingParameters);
	
	Query.SetParameter("OnlyErrors", True);
	Table = MandatoryTableForTemporaryDocumentDataTable(Query);
	
	Return Table;
	
EndFunction

////////////////////////////////////////////////////////////////////////////////
// Discussing the possibility of creating an invoice for an order.

// Returns the text of the remainder control error.
//
// Returns:
//  String - the text of the errors of the control of the balances.
//
Function ErrorTextNoProductsAvailableForShipment() Export
	
	ErrorText = NStr("vi = 'Không thể giao hàng theo chứng từ, vì trong chứng từ chưa thực hiện các thao tác cần thiết.
		|Để bắt đầu quy trình giao hàng, cần chỉ định thao tác ""Cần giao hàng"" trong danh sách hàng hóa đối với các mục mặt hàng được giao.
		|Nếu đã chỉ định thao tác này, thì có thể là tất cả hàng hóa đã được giao từ trước.';
		|ru = 'Отгрузка по документу недоступна, так как в документе не выполнены необходимые действия.
		|Для начала процесса отгрузки необходимо указать действие ""Отгрузить"" в списке товаров для отгружаемых позиций номенклатуры.
		|Если данное действие указано, то, возможно, все товары уже отгружены ранее.';
		|en = 'Shipment is unavailable as the required actions are not performed in the document.
		|To start the shipping process, specify the ""Ship"" action in the list of goods for the items to be shipped.
		|If this action is specified, all the goods might be already shipped.'; fa = 'Shipment is unavailable as the required actions are not performed in the document.
		|To start the shipping process, specify the ""Ship"" action in the list of goods for the items to be shipped.
		|If this action is specified, all the goods might be already shipped.';
		|it = 'Shipment is unavailable as the required actions are not performed in the document.
		|To start the shipping process, specify the ""Ship"" action in the list of goods for the items to be shipped.
		|If this action is specified, all the goods might be already shipped.';
		|pl = 'Shipment is unavailable as the required actions are not performed in the document.
		|To start the shipping process, specify the ""Ship"" action in the list of goods for the items to be shipped.
		|If this action is specified, all the goods might be already shipped.';
		|tr = 'Belgede gerekli eylemler gerçekleştirilmediği için belge kapsamında sevkiyat yapılamıyor.
		|Sevkiyat işlemini başlatmak için, sevk edilecek öğe kalemleri için ürün listesinde ""Sevk et"" eylemini belirtmeniz gerekmektedir.
		|Bu eylem belirtilmişse, tüm ürünler daha önce sevk edilmiş olabilir.'");
	
	Return ErrorText;
	
EndFunction

////////////////////////////////////////////////////////////////////////////////
// Discussing the call of the general form "The status of securing orders" in the documents

// In the order form, checks that the document is completed.
//
// Parameters:
//  Ref - AnyRef - Link to the order.
//
// Returns:
//  Boolean - True if the document is held, False otherwise
//
Function HyperlinkStateOfProvisionClickDocumentCompleted(Ref) Export
	
	Return Common.ObjectAttributeValue(Ref, "Posted") = True;
	
EndFunction

// Configures the form elements associated with the provisioning status hyperlinks.
//
// Parameters:
//  Form - ClientApplicationForm - order form.
//  
//
Procedure ConfigureHyperlinkedSoftwareState(Form) Export
	
	If Not HaveRightToViewStateHyperlink() Then
		Return;
	EndIf;
	EmbeddingParameters = Form.AvailableRemainingEmbeddingOptions;
	If EmbeddingParameters.InternalParameters.NeedAvailabilityUpdateHandler Then
		Return;
	EndIf;
	Tables = GetFromTempStorage(EmbeddingParameters.InternalParameters.AddressOfFormDataTable);
	FillInTablesFromFormData(Tables, Form);
	
	TempTablesManager = New TempTablesManager();
	Query = New Query();
	Query.TempTablesManager = TempTablesManager;
	AddTemporaryDocumentDataTable(Query.TempTablesManager, Tables, EmbeddingParameters);
	
	Query.Text =
		"SELECT TOP 1
		|	TRUE AS ReadyForSupply
		|FROM
		|	TemporaryDocumentDataTable AS Table
		|WHERE
		|	Table.ReadyForSupply AND NOT Table.Canceled";
	ReadyForSupply = Not Query.Execute().IsEmpty();
	EmbeddingParameters.InternalParameters.ReadyForSupply = ReadyForSupply;
	
	Object = Form.Object; // DocumentObject
	HyperlinkProperties = PropertiesOfSoftwareStateHyperlink(
		False,
		Object.Ref,
		ReadyForSupply);
	
	Items = Form.Items;
	ItemsNames = EmbeddingParameters.ItemsNames;
	Items[ItemsNames["PagesHyperlinkSoftwareStatus"]].CurrentPage
		= Items[ItemsNames[HyperlinkProperties.PageName]];
	Items[ItemsNames[HyperlinkProperties.HyperlinkName]].Title = HyperlinkProperties.Title;
	
EndProcedure

// Properties for forming the security status label in the order form.
//
// Parameters:
//  Modified - Boolean - indicates that the order has been modified in the form.
//  Ref - AnyRef - Link to the order.
//  ReadyForSupply - Boolean - an Indication that the document Has The Proper Status to Be Considered secured.
//  ProblemWithStartingJob - Boolean - True if, as a result of queries, it is determined that there are problems with starting the distribution of spare parts.
//
// Returns:
//  Structure - structure with fields:
//   * Title - String - the text displayed in the header of the hyperlink.
//   * PageName - String - the name of the page of the order form where the desired hyperlink is located.
//   * HyperlinkName - String - name of the form element of the displayed hyperlink.
//
Function PropertiesOfSoftwareStateHyperlink(Modified, Ref, ReadyForSupply, ProblemWithStartingJob = False) Export
	
	HyperlinkProperties = New Structure("Title,PageName,HyperlinkName");
	
	If Modified Or Ref.IsEmpty() Or Not Common.ObjectAttributeValue(Ref, "Posted") Then
		
		HyperlinkProperties.Title      = NStr("vi = 'Trạng thái đảm bảo';
												|ru = 'Состояние обеспечения';
												|en = 'Supply forecast'; fa = 'پیش‌بینی تأمین';
												|it = 'Stato di approvvigionamento';
												|pl = 'Status zaopatrzenia';
												|tr = 'Tedarik durumu'");
		HyperlinkProperties.PageName    = "PageHyperlinkSoftwareStatus";
		HyperlinkProperties.HyperlinkName = "SecurityStatusHyperlink";
		
	ElsIf ProblemWithStartingJob Then
		
		HyperlinkProperties.Title      = NStr("vi = 'Lỗi phân bổ vật tư';
												|ru = 'Ошибка распределения запасов';
												|en = 'Inventory allocation error'; fa = 'خطای تسهیم موجودی';
												|it = 'Errore di ripartizione delle scorte';
												|pl = 'Błąd podziału zapasów';
												|tr = 'Stok dağıtım hatası'");
		HyperlinkProperties.PageName    = "PageHyperlinkSecurityStatusIsBeingShipped";
		HyperlinkProperties.HyperlinkName = "HyperlinkSecurityStatusIsBeingShipped";
		
	Else
		
		TextAndParameters = TextAndParametersOfRequestForSecuringShipmentOrders("TempTable");
		TextAndParameters.Parameters.CurrentDayStart = BegOfDay(CurrentSessionDate());
		TextAndParameters.Parameters.ShippingOrders = Ref;
		
		Query = New Query(TextAndParameters.Text);
		For Each Property In TextAndParameters.Parameters Do
			Query.SetParameter(Property.Key, Property.Value);
		EndDo;
		
		Query.TempTablesManager = New TempTablesManager;
		Query.Execute();
		Table = Query.TempTablesManager.Tables["TempTable"].GetData().Unload();
		Query.TempTablesManager.Close();
		
		If Table.Count() = 0 Then
			
			If Not ReadyForSupply Then
				HyperlinkProperties.Title      = NStr("vi = 'Trạng thái đảm bảo';
														|ru = 'Состояние обеспечения';
														|en = 'Supply forecast'; fa = 'پیش‌بینی تأمین';
														|it = 'Stato di approvvigionamento';
														|pl = 'Status zaopatrzenia';
														|tr = 'Tedarik durumu'");
				HyperlinkProperties.PageName    = "PageHyperlinkStateOfProvisionWithTitle";
				HyperlinkProperties.HyperlinkName = "ProvisionStateHyperlinkWithTitle";
			Else
				HyperlinkProperties.Title      = NStr("vi = 'Đang giao/Đã giao';
														|ru = 'Отгружается/Отгружено';
														|en = 'Shipment in progress/Shipped'; fa = 'Shipment in progress/Shipped';
														|it = 'In spedizione/Spedito';
														|pl = 'Shipment in progress/Shipped';
														|tr = 'Sevk ediliyor/Sevk edildi'");
				HyperlinkProperties.PageName    = "PageHyperlinkSecurityStatusIsBeingShipped";
				HyperlinkProperties.HyperlinkName = "HyperlinkSecurityStatusIsBeingShipped";
			EndIf;
			
		ElsIf Table[0].CanBeShippedNow Then
			
			HyperlinkProperties.Title      = NStr("vi = 'Có thể giao hàng bây giờ';
													|ru = 'Можно отгрузить сейчас';
													|en = 'Can be shipped now'; fa = 'Can be shipped now';
													|it = 'Disponibile ora per la spedizione';
													|pl = 'Można wysłać teraz';
													|tr = 'Şimdi sevk edilebilinir'");
			HyperlinkProperties.PageName    = "PageHyperlinkStateOfProvisionWithTitle";
			HyperlinkProperties.HyperlinkName = "ProvisionStateHyperlinkWithTitle";
			
		ElsIf Table[0].ShipmentDateNotValid Then
			
			HyperlinkProperties.Title      = NStr("vi = 'Ngày giao hàng chưa thực hiện';
													|ru = 'Дата отгрузки не исполнима';
													|en = 'Shipment date cannot be met'; fa = 'Shipment date cannot be met';
													|it = 'Data di spedizione non applicabile';
													|pl = 'Data wysyłki nie jest wykonalna';
													|tr = 'Sevkiyat tarihi yürütebilir değil'");
			HyperlinkProperties.PageName    = "PageHyperlinkSoftwareStatusIssue";
			HyperlinkProperties.HyperlinkName = "HyperlinkSecurityStatusIssue";
			
		ElsIf ValueIsFilled(Table[0].PossibleShippingDate) Then
			
			TitleTemplate1 = NStr("vi = 'Ngày giao hàng có thể: %PossibleShippingDate%';
									|ru = 'Возможная дата отгрузки: %PossibleShippingDate%';
									|en = 'Available shipment date: %PossibleShippingDate%'; fa = 'Available shipment date: %PossibleShippingDate%';
									|it = 'Possibile data di spedizione: %PossibleShippingDate%';
									|pl = 'Możliwa data wysyłki: %PossibleShippingDate%';
									|tr = 'Mümkün sevkiyat tarihi: %PossibleShippingDate%'");
			DateText = Format(Table[0].PossibleShippingDate, "DLF=D");
			HyperlinkProperties.Title      = StrReplace(TitleTemplate1, "%PossibleShippingDate%", DateText);
			HyperlinkProperties.PageName    = "PageHyperlinkStateOfProvisionWithTitle";
			HyperlinkProperties.HyperlinkName = "ProvisionStateHyperlinkWithTitle";
			
		Else
			
			HyperlinkProperties.Title      = NStr("vi = 'Chưa xác định ngày dự tính đảm bảo';
													|ru = 'Плановая дата обеспечения не определена';
													|en = 'Scheduled supply date is not defined'; fa = 'Scheduled supply date is not defined';
													|it = 'La data di approvvigionamento non è programmata';
													|pl = 'Planowana data zaopatrzenia nie jest określona';
													|tr = 'Planlanan tedarik tarihi tanımlanmadı'");
			HyperlinkProperties.PageName    = "PageHyperlinkStateOfProvisionWithTitle";
			HyperlinkProperties.HyperlinkName = "ProvisionStateHyperlinkWithTitle";
			
		EndIf;
		
	EndIf;
	
	Return HyperlinkProperties;
	
EndFunction

////////////////////////////////////////////////////////////////////////////////
// Serving the receipt of balances in the form of Processing.There are many criteria.Form".

// Returns the text of the request for available balances by date for displaying information in the selection.
// 
// Parameters:
//  ThereIsCharacteristic - Boolean - indicates whether there are characteristics.
//  QuerySections - Array, Undefined - request sections.
//  ControlledLotReference - CatalogRef.ControlledLots - controlled Lot reference.
//
// Returns:
//   String - the text of the request for available balances.
//
Function RequestTextForAvailableBalancesByDateForMatching(ThereIsCharacteristic, QuerySections, ControlledLotReference) Export
	
	If QuerySections = Undefined Then
		QuerySections = New Array();
	EndIf;
	
	QueryText =
		"SELECT ALLOWED
		|	InventoryAllocation.Warehouse AS Warehouse,
		|	MAX(InventoryAllocation.Warehouse.Description) AS WarehouseName,
		|	CASE
		|		WHEN
		|			InventoryAllocation.InventoryState IN(
		|				VALUE(Enum.InventoryStates.InStock),
		|				VALUE(Enum.InventoryStates.AvailablePendingUnlocking),
		|				VALUE(Enum.InventoryStates.AvailableNotSubjectToUnlocking))
		|			THEN DATETIME(1, 1, 1)
		|		ELSE InventoryAllocation.AvailabilityDate
		|	END AS Period,
		|	SUM(InventoryAllocation.Count) AS Inventory,
		|	SUM(
		|		CASE
		|			WHEN
		|				InventoryAllocation.Purpose = VALUE(Catalog.Assignments.EmptyRef)
		|					AND &ConditionIsFreeOverridable
		|				THEN InventoryAllocation.Count
		|			ELSE 0
		|		END) AS AvailableForInventoryAllocation,
		|	CASE
		|		WHEN
		|			InventoryAllocation.InventoryState IN(
		|				VALUE(Enum.InventoryStates.InStock),
		|				VALUE(Enum.InventoryStates.AvailablePendingUnlocking),
		|				VALUE(Enum.InventoryStates.AvailableNotSubjectToUnlocking))
		|			THEN 0
		|		ELSE 1
		|	END AS State
		|FROM
		|	InformationRegister.InventoryAllocation AS InventoryAllocation
		|WHERE
		|	InventoryAllocation.InventoryState IN(
		|			VALUE(Enum.InventoryStates.InStock),
		|			VALUE(Enum.InventoryStates.AvailablePendingUnlocking),
		|			VALUE(Enum.InventoryStates.AvailableNotSubjectToUnlocking),
		|			VALUE(Enum.InventoryStates.ExpectedForReceiptWithoutLock),
		|			VALUE(Enum.InventoryStates.ExpectedForReceiptWithLock),
		|			VALUE(Enum.InventoryStates.ExpectedForReceiptNotSubjectToUnlocking))
		|		AND InventoryAllocation.Products = &Products
		|		AND InventoryAllocation.Characteristic = &Characteristic
		|		AND &WhereIsControlledLotReferenceOverridable
		|		AND InventoryAllocation.Warehouse IN(&Warehouses)
		|GROUP BY
		|	InventoryAllocation.Warehouse,
		|	CASE
		|		WHEN
		|			InventoryAllocation.InventoryState IN(
		|				VALUE(Enum.InventoryStates.InStock),
		|				VALUE(Enum.InventoryStates.AvailablePendingUnlocking),
		|				VALUE(Enum.InventoryStates.AvailableNotSubjectToUnlocking))
		|			THEN 0
		|		ELSE 1
		|	END,
		|	CASE
		|		WHEN
		|			InventoryAllocation.InventoryState IN(
		|				VALUE(Enum.InventoryStates.InStock),
		|				VALUE(Enum.InventoryStates.AvailablePendingUnlocking),
		|				VALUE(Enum.InventoryStates.AvailableNotSubjectToUnlocking))
		|			THEN DATETIME(1, 1, 1)
		|		ELSE InventoryAllocation.AvailabilityDate
		|	END
		|HAVING
		|	SUM(InventoryAllocation.Count) > 0
		|		OR SUM(
		|				CASE
		|					WHEN
		|						InventoryAllocation.Purpose = VALUE(Catalog.Assignments.EmptyRef)
		|							AND &ConditionIsFreeOverridable
		|						THEN InventoryAllocation.Count
		|					ELSE 0
		|				END) <> 0
		|ORDER BY
		|	WarehouseName,
		|	Warehouse,
		|	State,
		|	Period";
	
	If Not ThereIsCharacteristic Then
		QueryText = StrReplace(QueryText, "&Characteristic", "InventoryAllocation.Characteristic");
	EndIf;
	
	If ValueIsFilled(ControlledLotReference) Then
		WhereIsControlledLotReference = "InventoryAllocation.ReceiptOrder = &ControlledLotReference";
		ConditionIsFree =
			"InventoryAllocation.InventoryState IN(
			|		VALUE(Enum.InventoryStates.AvailablePendingUnlocking),
			|		VALUE(Enum.InventoryStates.AvailableNotSubjectToUnlocking),
			|		VALUE(Enum.InventoryStates.ExpectedForReceiptWithLock),
			|		VALUE(Enum.InventoryStates.ExpectedForReceiptNotSubjectToUnlocking))
			|	AND InventoryAllocation.DemandCharacteristic IN(
			|		VALUE(Enum.DemandCharacteristics.ReserveAsReceived),
			|		VALUE(Enum.DemandCharacteristics.SnoozeReservation),
			|		VALUE(Enum.DemandCharacteristics.ToSupply),
			|		VALUE(Enum.DemandCharacteristics.Surplus))";
	Else
		WhereIsControlledLotReference = "TRUE";
		ConditionIsFree =
			"InventoryAllocation.InventoryState IN(
			|		VALUE(Enum.InventoryStates.InStock),
			|		VALUE(Enum.InventoryStates.ExpectedForReceiptWithoutLock))
			|	AND InventoryAllocation.DemandCharacteristic IN(
			|		VALUE(Enum.DemandCharacteristics.SnoozeReservation),
			|		VALUE(Enum.DemandCharacteristics.ToSupply),
			|		VALUE(Enum.DemandCharacteristics.Surplus))";
	EndIf;
	QueryText = StrReplace(QueryText, "&WhereIsControlledLotReferenceOverridable", WhereIsControlledLotReference);
	QueryText = StrReplace(QueryText, "&ConditionIsFreeOverridable", ConditionIsFree);
	
	QuerySections.Add("PlannedBalances_");
	
	Return QueryText;
	
EndFunction

////////////////////////////////////////////////////////////////////////////////
// Discussing the selection of goods in documents.

// Returns the shipping date set in the document header, if there is one in the document.
//
// Parameters:
//   DocumentParameters - Structure - structure with fields:
//    * AvailableRemainingDocumentParameters - See AvailableRemainingEmbeddingOptions
//
// Returns:
//  Date, Undefined - the date of shipment from the document header.
//
Function TheShipmentDateOfAllLinesIsASingleDate(DocumentParameters) Export
	
	TheShipmentDateOfAllLinesIsASingleDate = Undefined;
	If DocumentParameters <> Undefined Then
		
		EmbeddingParameters = DocumentParameters.EmbeddingParameters;
		If EmbeddingParameters <> Undefined Then
			
			Tables = GetFromTempStorage(EmbeddingParameters.InternalParameters.AddressOfFormDataTable);
			PopulateTablesFromSerializedObject(
				Tables,
				DocumentParameters.ProgramObjectData,
				EmbeddingParameters,
				New Structure());
			
			TempTablesManager = New TempTablesManager();
			AddTemporaryDocumentDataTable(TempTablesManager, Tables, EmbeddingParameters);
			
			Query = New Query();
			Query.TempTablesManager = TempTablesManager;
			Query.Text =
				"SELECT
				|	Table.TheShipmentDateOfAllLinesIsASingleDate AS TheShipmentDateOfAllLinesIsASingleDate
				|FROM
				|	TemporaryDocumentDataTable AS Table";
			Selection = Query.Execute().Select();
			If Selection.Next() Then
				TheShipmentDateOfAllLinesIsASingleDate = Selection.TheShipmentDateOfAllLinesIsASingleDate;
			EndIf;
			
		EndIf;
		
	EndIf;
	
	Return TheShipmentDateOfAllLinesIsASingleDate;
	
EndFunction

// Getting the inventory allocation in the context of the document being edited.
//
// Parameters:
//  CallingFromForm   - Boolean - if the call comes from a Form, then TRUE is passed,
//                            if from an object, then FALSE.
//  DataSource - Structure, ClientApplicationForm - if the call originates from a Form (see the Form call parameter),
//                                                           then the Client's formapplications or structure with keys:
//                                                             * Object - Structure - key: name of the table part,
//                                                                                    value: value table.
//                                                             * Items - FormAllItems -
//                                                             * UUID - UUID -
//                                                             * Modified - Boolean -
//                                                             * AvailableRemainingEmbeddingOptions - See ProvisionInDocumentsServer.AvailableRemainingEmbeddingOptions 
//                                                           if the call comes from an object, then a structure with keys:
//                                                             * Object - DocumentObject -
//                                                             * UUID - UUID -
//                                                             * Modified - Boolean -
//                                                             * AvailableRemainingEmbeddingOptions - See ProvisionInDocumentsServer.AvailableRemainingEmbeddingOptions
//  OnlyUnsecured - Boolean - If False, then only unsecured needs requiring collateral will be recorded for shipment orders.
//
// Returns:
//  ValueTable - Inventory distribution table for the document being edited.
//                    The structure of the table corresponds to the structure of the register "Inventory distribution".
//
Function InventoryAllocationForDocumentBeingEdited(CallingFromForm, DataSource, OnlyUnsecured) Export
	
	Modified = DataSource.Modified;
	
	Result = Undefined;
	
	EmbeddingParameters = DataSource.AvailableRemainingEmbeddingOptions;
	
	InternalParameters = EmbeddingParameters.InternalParameters;
	
	If CallingFromForm Then
		
		Tables = GetFromTempStorage(InternalParameters.AddressOfFormDataTable);
		FillInTablesFromFormData(Tables, DataSource);
		
	Else
		
		Tables = New Map;
		InsertTables(Tables, EmbeddingParameters.FormDataSerializationPattern, "");
		FillInTableNamesAsAppropriate(EmbeddingParameters, Tables);
		
		QueryText = QueryTextTemporaryDocumentDataTable(EmbeddingParameters, Tables);
		InternalParameters.Insert("QueryTextTemporaryDocumentDataTable", QueryText);
		
		FillInTablesFromObject(Tables, New Structure("Object", DataSource.Object));
		
	EndIf;
	
	TempTablesManager = New TempTablesManager();
	Query = New Query();
	Query.TempTablesManager = TempTablesManager;
	AddTemporaryDocumentDataTable(Query.TempTablesManager, Tables, EmbeddingParameters);
	Query.Text = TemporaryTableOfDocumentRegisteredRecords(False);
	Query.SetParameter("Ref", Undefined);
	Query.SetParameter("NewDestinationLink", Catalogs.Assignments.GetRef());
	Query.Execute();
	
	Query.Text =
		"SELECT DISTINCT
		|	Table.OrderDocument AS OrderDocument
		|FROM
		|	TemporaryTableOfDocumentRegisteredRecords AS Table
		|
		|UNION
		|
		|SELECT DISTINCT
		// for stages processed on the side.
		|	Table.Recorder AS OrderDocument
		|FROM
		|	TemporaryDocumentDataTable AS Table
		|
		|UNION
		|
		// to get records of free balances.
		|SELECT
		|	UNDEFINED AS OrderDocument";
	
	Orders = Query.Execute().Unload().UnloadColumn("OrderDocument");
	Query.SetParameter("Orders", Orders);
	
	If Modified Then
		
		RegisterRecordTable = TempTablesManager.Tables["TemporaryTableOfDocumentRegisteredRecords"].GetData().Unload();
		Query.Text =
			"SELECT DISTINCT
			|	Table.ShipmentOrder AS ShipmentOrder,
			|	Table.Priority AS Priority,
			|	Table.DocumentDate AS DocumentDate
			|FROM
			|	TemporaryDocumentDataTable AS Table";
		TableSimulationRegistry = Query.Execute().Unload();
		StockAllocationRecords.AddRegisterColumns(RegisterRecordTable);
		InventoryAllocation.StateWithReflectionOfChanges(
			Orders,
			RegisterRecordTable,
			TempTablesManager,
			TableSimulationRegistry);
			
		Query.Text =
			"SELECT ALLOWED
			|	Records.Products AS Products,
			|	Records.Characteristic AS Characteristic,
			|	Records.Warehouse AS Warehouse,
			|	Records.Purpose AS Purpose,
			|	Records.InventoryState AS InventoryState,
			|	Records.DemandCharacteristic AS DemandCharacteristic,
			|	Records.ShipmentOrder AS ShipmentOrder,
			|	Records.RequestShipmentOn AS RequestShipmentOn,
			|	Records.ReceiptOrder AS ReceiptOrder,
			|	Records.DateOfReceipt AS DateOfReceipt,
			|	Records.AvailabilityDate AS AvailabilityDate,
			|	Records.Count AS Count
			|FROM
			|	SimulationOfReflection AS Records
			|WHERE
			|	Records.ShipmentOrder IN(&Orders)
			|		AND Records.DemandCharacteristic IN(
			|			VALUE(Enum.DemandCharacteristics.ReserveAtWarehouse),
			|			VALUE(Enum.DemandCharacteristics.ReserveAsReceived),
			|			VALUE(Enum.DemandCharacteristics.SnoozeReservation),
			|			VALUE(Enum.DemandCharacteristics.ToSupply),
			|			VALUE(Enum.DemandCharacteristics.NotProvide))
			|		AND &OnlyUnsecuredOverridable
			|	
			|UNION ALL
			|
			|SELECT
			|	Records.Products AS Products,
			|	Records.Characteristic AS Characteristic,
			|	Records.Warehouse AS Warehouse,
			|	Records.Purpose AS Purpose,
			|	UNDEFINED AS InventoryState,
			|	UNDEFINED AS DemandCharacteristic,
			|	UNDEFINED AS ShipmentOrder,
			|	DATETIME(1, 1, 1) AS RequestShipmentOn,
			|	UNDEFINED AS ReceiptOrder,
			|	DATETIME(1, 1, 1) AS DateOfReceipt,
			|	DATETIME(1, 1, 1) AS AvailabilityDate,
			|	Records.Count AS Count
			|FROM
			|	SimulationOfReflection AS Records
			|WHERE
			|	Records.DemandCharacteristic IN(
			|		VALUE(Enum.DemandCharacteristics.SnoozeReservation),
			|		VALUE(Enum.DemandCharacteristics.ToSupply),
			|		VALUE(Enum.DemandCharacteristics.Surplus))
			|	AND Records.InventoryState = VALUE(Enum.InventoryStates.InStock)";
			
	Else
		
		Query.Text =
			"SELECT ALLOWED
			|	Orders.Products AS Products,
			|	Orders.Characteristic AS Characteristic,
			|	Orders.Warehouse AS Warehouse,
			|	Orders.Purpose AS Purpose
			|INTO Goods
			|FROM
			|	AccumulationRegister.InventoryAndDemands.Balance(, OrderDocument IN(&Orders)) AS Orders
			|WHERE
			|	Orders.ReserveAtWarehouseBalance > 0
			|		OR Orders.ReserveAsReceivedBalance > 0
			|		OR Orders.ToSupplyBalance > 0
			|		OR Orders.NotProvideBalance > 0
			|;
			|
			|/////////////////////////////////////////
			|SELECT ALLOWED
			|	Records.Products AS Products,
			|	Records.Characteristic AS Characteristic,
			|	Records.Warehouse AS Warehouse,
			|	Records.Purpose AS Purpose,
			|	Records.InventoryState AS InventoryState,
			|	Records.DemandCharacteristic AS DemandCharacteristic,
			|	Records.ShipmentOrder AS ShipmentOrder,
			|	Records.RequestShipmentOn AS RequestShipmentOn,
			|	Records.ReceiptOrder AS ReceiptOrder,
			|	Records.DateOfReceipt AS DateOfReceipt,
			|	Records.AvailabilityDate AS AvailabilityDate,
			|	Records.Count AS Count
			|FROM
			|	InformationRegister.InventoryAllocation AS Records
			|WHERE
			|	TRUE IN(
			|		SELECT
			|			TRUE AS SatisfiesTheFilter
			|		FROM
			|			Goods AS Goods
			|		WHERE
			|			Goods.Products = Records.Products
			|			AND Goods.Characteristic = Records.Characteristic
			|			AND Goods.Warehouse = Records.Warehouse
			|			AND Goods.Purpose = Records.Purpose)
			|	AND Records.ShipmentOrder IN(&Orders)
			|	AND Records.DemandCharacteristic IN(
			|		VALUE(Enum.DemandCharacteristics.ReserveAtWarehouse),
			|		VALUE(Enum.DemandCharacteristics.ReserveAsReceived),
			|		VALUE(Enum.DemandCharacteristics.SnoozeReservation),
			|		VALUE(Enum.DemandCharacteristics.ToSupply),
			|		VALUE(Enum.DemandCharacteristics.NotProvide))
			|	AND &OnlyUnsecuredOverridable
			|UNION ALL
			|
			|SELECT
			|	Records.Products AS Products,
			|	Records.Characteristic AS Characteristic,
			|	Records.Warehouse AS Warehouse,
			|	Records.Purpose AS Purpose,
			|	UNDEFINED AS InventoryState,
			|	UNDEFINED AS DemandCharacteristic,
			|	UNDEFINED AS ShipmentOrder,
			|	DATETIME(1, 1, 1) AS RequestShipmentOn,
			|	UNDEFINED AS ReceiptOrder,
			|	DATETIME(1, 1, 1) AS DateOfReceipt,
			|	DATETIME(1, 1, 1) AS AvailabilityDate,
			|	Records.Count AS Count
			|FROM
			|	InformationRegister.InventoryAllocation AS Records
			|WHERE
			|	TRUE IN(
			|		SELECT
			|			TRUE AS SatisfiesTheFilter
			|		FROM
			|			Goods AS Goods
			|		WHERE
			|			Goods.Products = Records.Products
			|			AND Goods.Characteristic = Records.Characteristic
			|			AND Goods.Warehouse = Records.Warehouse
			|			AND Goods.Purpose = Records.Purpose)
			|	AND Records.DemandCharacteristic IN(
			|		VALUE(Enum.DemandCharacteristics.SnoozeReservation),
			|		VALUE(Enum.DemandCharacteristics.ToSupply),
			|		VALUE(Enum.DemandCharacteristics.Surplus))
			|	AND Records.InventoryState = VALUE(Enum.InventoryStates.InStock)";
			
	EndIf;
	If OnlyUnsecured Then
		Substitution = "Records.InventoryState = VALUE(Enum.InventoryStates.NotProvided)
			|	AND Records.DemandCharacteristic <> VALUE(Enum.DemandCharacteristics.NotProvide)"; // @query-part-1
	Else
		Substitution = "TRUE"; // @query-part-1
	EndIf;
	Query.Text = StrReplace(Query.Text, "&OnlyUnsecuredOverridable", Substitution);
	Result = Query.Execute().Unload();
	
	Return Result;
	
EndFunction

////////////////////////////////////////////////////////////////////////////////
// Serving the initialization of the props Queue in the order and the props "Security option".

// Fills in the collateral option and the separate flag by default, depending on the item's settings.
//
// Parameters:
//  Table - TabularSection, FormDataCollection, ValueTable - Table of products.
//  FillInSeparately - ClientApplicationForm - order form.
//  SalesOrderStatus - EnumRef.SalesOrderStatuses - the status of the customer's order.
//
// Returns:
//  Boolean - indicates that the document has been modified.
//
Function FillInDefaultSecurityOption(Table, FillInSeparately = False, SalesOrderStatus = Undefined) Export
	
	If Table.Count() = 0 Then
		Return False;
	EndIf;
	
	ParametersForFillingInSecurityOption = DefaultSoftwareOptionFillOptions();
	ParametersForFillingInSecurityOption.UseShipmentByRowsInSalesOrder = GetFunctionalOption("UseShipmentByRowsInSalesOrder");
	
	If SalesOrderStatus = Undefined
		Or ParametersForFillingInSecurityOption.UseShipmentByRowsInSalesOrder Then
		
		ProductsTable = New ValueTable();
		ProductsTable.Columns.Add("Products", New TypeDescription("CatalogRef.Products"));
		ProductsTable.Columns.Add("IndexOf", New TypeDescription("Number"));

		UBound = Table.Count() - 1;
		For IndexOf = 0 To UBound Do

			NewRow = ProductsTable.Add();
			NewRow.IndexOf       = IndexOf;
			NewRow.Products = Table[IndexOf].Products;

		EndDo;

		Query = New Query();
		Query.Text =
			"SELECT
			|	Table.Products AS Products,
			|	Table.IndexOf       AS IndexOf
			|
			|INTO TT_Products
			|FROM
			|	&ProductsTable AS Table
			|;
			|
			|////////////////////////////////////////////
			|SELECT
			|	ISNULL(CatProducts.AssignedPurchaseSale, FALSE) AS AssignedPurchaseSale,
			|	ISNULL(CatProducts.ItemsType, VALUE(Enum.ItemsTypes.OwnGoods)) AS ItemsType,
			|	Table.IndexOf AS IndexOf
			|FROM
			|	TT_Products AS Table
			|		LEFT JOIN Catalog.Products AS CatProducts
			|		ON Table.Products = CatProducts.Ref";
		
		Query.SetParameter("ProductsTable", ProductsTable);
		Selection = Query.Execute().Select();
		Result = False;
		While Selection.Next() Do
		
			ParametersForFillingInSecurityOption.ItemsType = Selection.ItemsType;
			ParametersForFillingInSecurityOption.FillInSeparately = (FillInSeparately = True Or Selection.AssignedPurchaseSale);
			SecurityOptionAndFlagSeparately = ProvisionOptionAndFlagAreSeparateByDefault(ParametersForFillingInSecurityOption);
			
			Table[Selection.IndexOf].SupplyOption = SecurityOptionAndFlagSeparately.SupplyOption;
			Table[Selection.IndexOf].WithAssignment = SecurityOptionAndFlagSeparately.WithAssignment;
			Result = True;
		EndDo;
		
	Else
		
		ParametersForFillingInSecurityOption.SalesOrderStatus = SalesOrderStatus;
		SecurityOptionAndFlagSeparately = ProvisionOptionAndFlagAreSeparateByDefault(ParametersForFillingInSecurityOption);
		If Table[0].SupplyOption <> SecurityOptionAndFlagSeparately.SupplyOption
				Or Table[0].WithAssignment <> SecurityOptionAndFlagSeparately.WithAssignment Then
			For Each Page1 In Table Do
				Page1.SupplyOption = SecurityOptionAndFlagSeparately.SupplyOption;
				Page1.WithAssignment = SecurityOptionAndFlagSeparately.WithAssignment;
			EndDo;
			Result = True;
		Else
			Result = False;
		EndIf;
		
	EndIf;
	Return Result;
	
EndFunction

////////////////////////////////////////////////////////////////////////////////
// Serving filling in the shipping date in the lines, when recording the order, if the order is shipped on the same date.

// Fills in the shipment date in the table parameter in the field Name column for non-canceled rows.
//
// Parameters:
//  Value - Date - Value of the shipment date.
//  Table - ValueTable - The table where you need to fill in the shipment date.
//  FieldName - String - Name of the field that contains the shipment date.
//  IsCanceled - Boolean - indicates that the table has the "Canceled" field.
//
Procedure FillInShippingDatesInTable(Value, Table, FieldName, IsCanceled = True) Export
	
	If ValueIsFilled(Value) Then
		
		For Each String In Table Do
			If Not IsCanceled Or Not String.Canceled Then
				String[FieldName] = Value;
			EndIf;
		EndDo;
		
	EndIf;
	
EndProcedure

// Defines an item with the work type in the table part.
//
//  Parameters:
//   TabPart - TabularSection - the tabular part of the document for which you want to define the work.
//
//  Returns:
//   Map - the keys of correspondence are references to the nomenclature with the type of work, which is in the tabular part.
//
Function TablePartWorks(TabPart) Export
	
	Query = New Query();
	Query.SetParameter("References", TabPart.UnloadColumn("Products"));
	Query.Text =
		"SELECT DISTINCT
		|	AllProducts.Ref AS Ref
		|FROM
		|	Catalog.Products AS AllProducts
		|WHERE
		|	AllProducts.Ref IN(&References)
		|		AND AllProducts.ItemsType IN(
		|			VALUE(Enum.ItemsTypes.Work_5),
		|			VALUE(Enum.ItemsTypes.OperationService))";
	
	Works = New Map();
	SetPrivilegedMode(True);
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		Works.Insert(Selection.Ref);
	EndDo;
	Return Works;
	
EndFunction

// Returns the query text of the temporary table of available balances for all assignments.
// Parameters:
//  NameOfFilterTable - String - The name of the temporary product filter table.
//  TableNameResult - String - Name of the temporary result table.
// Returns:
//  String - Query text
Function TemporaryTableOfBalancesAvailableForAllAppointments(NameOfFilterTable, TableNameResult) Export
	
	QueryText =
		"SELECT ALLOWED
		|	Inventories.Products AS Products,
		|	Inventories.Characteristic AS Characteristic,
		|	Inventories.Warehouse AS Warehouse,
		|	Inventories.InStockBalance AS Count
		|INTO TableNameResultOverridable
		|FROM
		|	AccumulationRegister.InventoryAndDemands.Balance(,
		|		(Products, Characteristic, Warehouse) IN(
		|			SELECT
		|				Filter.Products AS Products,
		|				Filter.Characteristic AS Characteristic,
		|				Filter.Warehouse AS Warehouse
		|			FROM
		|				NameOfFilterTableOverridable AS Filter)) AS Inventories
		|WHERE
		|	Inventories.InStockBalance > 0
		|INDEX BY
		|	Products, Characteristic, Warehouse";
	
	QueryText = StrReplace(QueryText, "TableNameResultOverridable", TableNameResult);
	QueryText = StrReplace(QueryText, "NameOfFilterTableOverridable", NameOfFilterTable);
	Return QueryText;
	
EndFunction

// Checks whether it is necessary to ask a question about the shipment by one date.
// Parameters:
//  EmbeddingParameters - See ProvisionInDocumentsServer.AvailableRemainingEmbeddingOptions
//  Orders - Array of DefinedType.ExpectedShipment - Documents
// Returns:
//  Boolean - Truth, if you need to ask a question
Function NeedQuestionAboutShippingByOneDate(EmbeddingParameters, Orders) Export
	
	Text =
		"SELECT
		|	Table.Ref AS Ref
		|FROM
		|	&Table AS Table
		|WHERE
		|	Table.Ref IN(&Orders)
		|		AND Table.Posted
		|		AND (&Expression) <> UNDEFINED
		|		AND (&Expression) < &DateWhenTheNewLinesWereShipped";
		
	Text = StrReplace(Text, "&Table", EmbeddingParameters.ObjectName);
	Text = StrReplace(Text, "&Expression", EmbeddingParameters.ExpressionForQuestionWhenPerformingActionInOrderList);
	
	Query = New Query(Text);
	Query.SetParameter("DateWhenTheNewLinesWereShipped", BegOfDay(CurrentSessionDate()));
	Query.SetParameter("Orders", Orders);
	OrdersToCheckNeed = Query.Execute().Unload().UnloadColumn("Ref");
	NeedQuestion = ThereAreNeedsForOrders(OrdersToCheckNeed);
	
	Return NeedQuestion;
	
EndFunction

#Region InterfaceRequests

// To initialize inventory distribution calculation parameters.
// Returns:
//  Structure - a structure with the names of temp tables at the calculation input:
//   * BalanceSheetsOfControlledLotREFERENCES - String - the name of the incoming temporary table containing measurements and resources
//                                   of the Balances of controlled Lot references according to the Accumulation register "Inventories and needs".
//   * Balance - String - the name of the incoming temporary table containing measurements and Balance resources
//                        according to the Accumulation register "Inventories and needs".
//   * ReversingEntry - String - the name of the incoming temporary table containing the
//                       software Registered Records for the Accumulation register "Inventories and needs" that need to be reversed before receiving Balances.
//   * Result - String - the name of the outgoing temp table containing the calculation result.
Function NewTableNamesForInventoryAllocation() Export
	
	TablesNames = New Structure();
	TablesNames.Insert("BalanceSheetsOfControlledLotREFERENCES", "");
	TablesNames.Insert("Balance", "");
	TablesNames.Insert("ReversingEntry", "");
	TablesNames.Insert("Result", "");
	Return TablesNames;
	
EndFunction

// Substitution for obtaining data on the distribution of stocks.
// 
// Example of use:
// 
//	Query text =
//		"SELECT ALLOWED
//		|T Supplies.Nomenclature AS A Nomenclature,
//		|T Supplies.Characteristic AS A Characteristic,
//		|T Supplies.Warehouse AS A Warehouse,
//		|T Supplies.Appointment AS Appointment,
//		|T Supplies.Order AS an Order,
//		|T Supplies.Blocked CASH STATUS AS Blocked CASH status,
//		|T Supplies.Blocked access to A remote control AS blocked access to A remote control,
//		|T Supplies.KRAZBLOCKKEOSTAT AS KRAZBLOCKKEOSTAT,
//		|T Supplies.Reserving a Stored and locked state HOW to reserve a stored and locked State,
//		|T Supplies.RESERVING the number OF accesses to the blocked statuses HOW TO reserve the NUMBER of accesses to the blocked STATUSES
//		|PLACE THE INVENTORY OF NEEDSTATESCONTROLLABLE PARTIES
//		|FROM
//		|Taccumulation register.Reserves of need.Balances AS Stocks
//		|INDEX BY
//		|Nomenclature, Characteristics, Warehouse, Purpose
//		|;
//		|
//		|////////////////////////////////////////////////////////////
//		|SELECT ALLOWED
//		|T Supplies.Nomenclature AS A Nomenclature,
//		|T Supplies.Characteristic AS A Characteristic,
//		|T Supplies.Warehouse AS A Warehouse,
//		|T Supplies.Appointment AS Appointment,
//		|T Supplies.Cash AND CASH AS cash and CASH,
//		|T Supplies.Blocked CASH STATUS AS Blocked CASH status,
//		|T Supplies.Ordered quantity AS ordered QUANTITY,
//		|T Supplies.The way the way the way the way the way the way the way the way the way the way the way the way,
//		|T Supplies.Blocked access to A remote control AS blocked access to A remote control,
//		|T Supplies.RESERVING A Homeostat HOW TO RESERVE A HOMEOSTAT,
//		|T Supplies.Reserving the right to access the right to reserve the right to access the right to reserve the right to use the right to use the right to use the right to use the right to use the right to use the right to use the right to use the right to use the right to use the right,
//		|T Supplies.POSTPONING reservationostat HOW TO POSTPONE reservationostat,
//		|T Supplies.COBESPECHENIYOUSTATOK AS cobespecheniyoustatok,
//		|T Supplies.Unsecured status AS UNSECURED status
//		|PLACE THE INVENTORY OF NEEDSTATEMENTS
//		|FROM
//		|Taccumulation register.Reserves of need.Balances AS Stocks
//		|INDEX BY
//		|Nomenclature, Characteristics, Warehouse, Destination
//		|;
//		|SELECT
//		|T Calculation.Nomenclature AS A Nomenclature,
//		|T Calculation.Characteristic AS A Characteristic,
//		|T Calculation.Warehouse AS A Warehouse,
//		|T Calculation.Appointment AS Appointment,
//		
//		Reserves in stock in unblocked goods:
//		
//		|T Calculation.Cash_reservate,
//		|T Calculation.cash_reservation_pomer, 
//		
//		Needs that do not form a reserve, provided with a warehouse Balance of unblocked goods:
//		
//		|T Calculation.CASH_TO deposit,
//		|T Calculation.cash_reference,
//		
//		Surplus of unblocked goods in stock:
//		
//		|Taccount.CASH_ISL,
//		
//		Reserves in the warehouse in the blocked goods to be unblocked:
//		
//		|T Calculation.cashingisblocking_reservation_isblocked_isblocked_isblocked_isblocked_isblocked_isblocked,
//		|T Calculation.cashblock_reservation_isblocked,
//		|T Calculation.cashblocking_reservation in the meter,
//		
//		Needs that do not form a reserve, provided by the warehouse Balance of the blocked goods to be unblocked:
//		
//		|T Calculation.CASHBLOCK_ Deposit,
//		|T Calculation.In cash with a security lockout,
//		
//		Excess blocked goods in the warehouse to be unblocked:
//		
//		|T Calculation.cashingisblock_islishek,
//		
//		Reserves in a warehouse in a blocked goods that cannot be unblocked:
//		
//		|T Calculation.Cash out of unblocking_reservation_izablocked_,
//		|T Calculation.Cash out of unblocking_reservation_isblocked,
//		
//		Excess blocked goods in the warehouse that cannot be unblocked:
//		
//		|T Calculation.Cash out of unblocking_islishek,
//		
//		Reserves of goods in orders that are not blocked when they arrive at the warehouse:
//		
//		|Tcount.expectance_reservation in the meter,
//		
//		Needs that do not form a reserve, secured by orders of goods that are not blocked upon arrival at the warehouse:
//		
//		|Taccount.expectance_depose,
//		|T Calculation.Expected_Due
//		
//		to self-sufficiency, There is a surplus in orders of goods that are not blocked when they arrive at the warehouse:
//		
//		|Tcount.Waiting for_isl,
//		
//		Reserves in orders of goods that are blocked when they arrive at the warehouse and then unblocked at the warehouse:
//		
//		|Tcount.expectedblock_reservation_isblocked,
//		|T Calculation.Waiting for a deadlock_reservation in the meter,
//		
//		Needs that do not form a reserve, secured by orders of goods that are blocked when they arrive at the warehouse with subsequent unblocking in the warehouse:
//		
//		|Taccount.Waiting for a deadlock_references,
//		|T Calculation.A security lockout is expected,
//		
//		Surpluses in orders of goods that are blocked when they arrive at the warehouse, followed by unblocking at the warehouse:
//		
//		|	count.Waiting for a lock_isl,
//		
//		Reserves in orders of goods that are blocked when they arrive at the warehouse without further unblocking in the warehouse:
//		
//		|Tcount.It is expected to be unblocked_reservation_isblocked,
//		
//		Excess orders of goods that are blocked when they arrive at the warehouse, without further unblocking in the warehouse:
//		
//		|T Calculation.No lock_islishes are expected,
//		
//		Needs provided by unconfirmed orders of goods:
//		
//		|T Calculation.match_reservation_the meter,
//		|T Calculation.ALIGNMENT_OFFEND,
//		|T Calculation.Agreement_Due to self-sufficiency,
//		
//		Surpluses in unconfirmed goods orders to the warehouse:
//		
//		|	count.List_conformations,
//		
//		Unsecured needs:
//		
//		|T Calculation.unsecure_reservation_isblocked,
//		|T Calculation.unsecure_reservationpomere, 
//		|T Calculation.Unsecure_ Deposit,
//		|T Calculation.Unsecure_supply,
//		|T Calculation.unsecure_notecure,
//		
//		Total stocks of unblocked goods in stock:
//		
//		|Taccount.In cash,
//		
//		Total stocks of blocked goods in the warehouse to be unblocked:
//		
//		|T Calculation.Cash and blocking,
//		
//		Total stocks of blocked goods in a warehouse that cannot be unblocked:
//		
//		|T Calculation.cashiesnotesreferences,
//		
//		Total stocks in the planned receipts of goods that are not blocked upon arrival at the warehouse:
//		
//		|T Calculation.Expected,
//		
//		The total stocks in the planned receipts of the goods that are blocked upon arrival at the warehouse, with subsequent unblocking at the warehouse:
//		
//		|T Calculation.Pending Deadlock,
//		
//		The total stocks in the planned receipts of the goods that are blocked upon arrival at the warehouse, without subsequent unblocking at the warehouse:
//		
//		|T Calculation.No deadlock is expected,
//		
//		Total inventory in unconfirmed orders for the receipt of goods at the warehouse:
//		
//		|Tcount.Agreement,
//		
//		The total needs of shipping orders (secured and unsecured):
//		
//		|T Calculation.Reserve,
//		|T Calculation.Reservepomere,
//		|T Calculation.Postpone,
//		|T Calculation.Self- sufficiency,
//		
//		Total requirements of orders for the movement of goods of blocked goods:
//		
//		|T Calculation.RESERVE_IZABLOCKED,
//		|T Calculation.Back up_isblocked,
//		
//		Shipping orders that do not require collateral:
//		
//		|	count.Unsecure
//		
//		|FROM
//		|Taccounting THE Storage Allocation AS A Calculation";
//	
//	Nameplates = Document serviceservers.New Nameplate for the distribution of supplies();
//	Nameplates.Balances = "Inventory needs"; // @query-part-1
//	Nameplates.RemaindIngcontrolledpArties = "needstatingstatingcontrolledparties"; // @query-part-1
//	Nameplates.Result = "Calculation of inventory allocation"; // @query-part-1
//	Document serviceservers.Distribution of supplies (Query text, table names);
//
// End of the example.
//
// Parameters:
//  QueryText - String - Query Text,
//  TablesNames - See ProvisionInDocumentsServer.NewTableNamesForInventoryAllocation
//  DeleteTemporaryTables - Boolean - if True, the created intermediate temp tables will not be deleted from the query
// Returns:
//  Array of String - Request texts.
Function InventoryAllocation(QueryText, TablesNames, DeleteTemporaryTables = True) Export
	
	Texts = New Array();
	TablesThatAreBeingDestroyed = New Array();
	NamesOfLotReferenceTables = NewTableNamesForDistributionOfInventoryIntoControlledLotsReference();
	NamesOfLotReferenceTables.BalanceSheetsOfControlledLotREFERENCES = TablesNames.BalanceSheetsOfControlledLotREFERENCES;
	NamesOfLotReferenceTables.ReversingEntry = TablesNames.ReversingEntry;
	NamesOfLotReferenceTables.Result = "DistributionOfInventoryIntoControlledLotsReference";  // @query-part-1
	DistributionOfInventoryIntoControlledLotsReferenceInternal(Texts, TablesThatAreBeingDestroyed, NamesOfLotReferenceTables);
	
	Balance = TablesNames.Balance;
	If TablesNames.ReversingEntry <> "" Then
		
		Text =
			"SELECT
			|	Set.Products AS Products,
			|	Set.Characteristic AS Characteristic,
			|	Set.Warehouse AS Warehouse,
			|	Set.Purpose AS Purpose,
			|	SUM(Set.InStockBalance) AS InStockBalance,
			|	SUM(Set.LockedInStockBalance) AS LockedInStockBalance,
			|	SUM(Set.Received_1Balance) AS Received_1Balance,
			|	SUM(Set.LockedReceiptBalance) AS LockedReceiptBalance,
			|	SUM(Set.OrderedBalance) AS OrderedBalance,
			|	SUM(Set.ReserveAtWarehouseBalance) AS ReserveAtWarehouseBalance,
			|	SUM(Set.ReserveAsReceivedBalance) AS ReserveAsReceivedBalance,
			|	SUM(Set.SnoozeReservationBalance) AS SnoozeReservationBalance,
			|	SUM(Set.ToSupplyBalance) AS ToSupplyBalance,
			|	SUM(Set.NotProvideBalance) AS NotProvideBalance
			|INTO InventoryAllocationStage0
			|FROM(
			|	SELECT
			|		Inventories.Products AS Products,
			|		Inventories.Characteristic AS Characteristic,
			|		Inventories.Warehouse AS Warehouse,
			|		Inventories.Purpose AS Purpose,
			|		Inventories.InStockBalance AS InStockBalance,
			|		Inventories.LockedInStockBalance AS LockedInStockBalance,
			|		Inventories.OrderedBalance AS OrderedBalance,
			|		Inventories.Received_1Balance AS Received_1Balance,
			|		Inventories.LockedReceiptBalance AS LockedReceiptBalance,
			|		Inventories.OrderedBalance - Inventories.Received_1Balance AS PendingSupplyApprovalBalance,
			|		Inventories.ReserveAtWarehouseBalance AS ReserveAtWarehouseBalance,
			|		Inventories.ReserveAsReceivedBalance AS ReserveAsReceivedBalance,
			|		Inventories.SnoozeReservationBalance AS SnoozeReservationBalance,
			|		Inventories.ToSupplyBalance AS ToSupplyBalance,
			|		Inventories.NotProvideBalance AS NotProvideBalance
			|	FROM
			|		BalanceOverridable AS Inventories
			|	
			|	UNION ALL
			|	
			|	SELECT
			|		StornoTable.Products AS Products,
			|		StornoTable.Characteristic AS Characteristic,
			|		StornoTable.Warehouse AS Warehouse,
			|		StornoTable.Purpose AS Purpose,
			|		- StornoTable.InStock AS InStockBalance,
			|		- StornoTable.LockedInStock AS LockedInStockBalance,
			|		- StornoTable.Ordered AS OrderedBalance,
			|		- StornoTable.Received_1 AS Received_1Balance,
			|		- StornoTable.LockedReceipt AS LockedReceiptBalance,
			|		- StornoTable.Ordered - StornoTable.Received_1 AS PendingSupplyApprovalBalance,
			|		- StornoTable.ReserveAtWarehouse AS ReserveAtWarehouseBalance,
			|		- StornoTable.ReserveAsReceived AS ReserveAsReceivedBalance,
			|		- StornoTable.SnoozeReservation AS SnoozeReservationBalance,
			|		- StornoTable.ToSupply AS ToSupplyBalance,
			|		- StornoTable.NotProvide AS NotProvideBalance
			|	FROM
			|		ReversingEntryOverridable AS StornoTable) AS Set
			|GROUP BY
			|	Set.Products,
			|	Set.Characteristic,
			|	Set.Warehouse,
			|	Set.Purpose
			|HAVING
			|	SUM(Set.InStockBalance) <> 0
			|		OR SUM(Set.LockedInStockBalance) <> 0
			|		OR SUM(Set.OrderedBalance) <> 0
			|		OR SUM(Set.Received_1Balance) <> 0
			|		OR SUM(Set.LockedReceiptBalance) <> 0
			|		OR SUM(Set.PendingSupplyApprovalBalance) <> 0
			|		OR SUM(Set.ReserveAtWarehouseBalance) <> 0
			|		OR SUM(Set.ReserveAsReceivedBalance) <> 0
			|		OR SUM(Set.SnoozeReservationBalance) <> 0
			|		OR SUM(Set.ToSupplyBalance) <> 0
			|		OR SUM(Set.NotProvideBalance) <> 0";
		
		Text = StrReplace(Text, "BalanceOverridable", Balance); // @query-part-1
		Text = StrReplace(Text, "ReversingEntryOverridable", TablesNames.ReversingEntry); // @query-part-1
		Texts.Add(Text);
		TablesThatAreBeingDestroyed.Add("InventoryAllocationStage0");
		
		Balance = "InventoryAllocationStage0"; // @query-part-1
		
	EndIf;
	
	Text =
		"SELECT
		|	Table.Products AS Products,
		|	Table.Characteristic AS Characteristic,
		|	Table.Warehouse AS Warehouse,
		|	Table.Purpose AS Purpose,
		|	
		|	SUM(Table.AvailableWithLock) AS AvailableWithLock,
		|	SUM(Table.AvailableWithoutUnlocking) AS AvailableWithoutUnlocking,
		|	SUM(Table.ExpectedWithBlocking) AS ExpectedWithBlocking,
		|	SUM(Table.ExpectedWithoutUnlocking) AS ExpectedWithoutUnlocking,
		|	SUM(Table.Reserve_FromBlocked) AS Reserve_FromBlocked,
		|	SUM(Table.ReserveAsNeeded_FromBlocked) AS ReserveAsNeeded_FromBlocked,
		|	
		|	SUM(Table.AvailableWithLock_Reserve_FromBlocked) AS AvailableWithLock_Reserve_FromBlocked,
		|	SUM(Table.AvailableWithLock_ReserveAsNeeded_FromBlocked) AS AvailableWithLock_ReserveAsNeeded_FromBlocked,
		|	SUM(Table.AvailableWithoutUnlocking_Reserve_FromLocked) AS AvailableWithoutUnlocking_Reserve_FromLocked,
		|	SUM(Table.AvailableWithoutUnlocking_ReserveAsNeeded_FromBlocked) AS AvailableWithoutUnlocking_ReserveAsNeeded_FromBlocked,
		|	SUM(Table.ExpectedWithLock_ReserveAsNeeded_FromBlocked) AS ExpectedWithLock_ReserveAsNeeded_FromBlocked,
		|	SUM(Table.ExpectedWithoutUnlocking_ReserveAsNeeded_FromBlocked) AS ExpectedWithoutUnlocking_ReserveAsNeeded_FromBlocked,
		|	SUM(Table.AvailableWithLock_Surplus) AS AvailableWithLock_Surplus,
		|	SUM(Table.AvailableWithoutUnlocking_Surplus) AS AvailableWithoutUnlocking_Surplus,
		|	SUM(Table.ExpectedWithLock_Surplus) AS ExpectedWithLock_Surplus,
		|	SUM(Table.ExpectedWithoutUnlocking_Surplus) AS ExpectedWithoutUnlocking_Surplus,
		|	SUM(Table.NotProvided_ReserveAsNeeded_FromBlocked) AS NotProvided_ReserveAsNeeded_FromBlocked,
		|	
		|	SUM(Table.InStock) AS InStock,
		|	SUM(Table.Expected_) AS Expected_,
		|	SUM(Table.AwaitingApproval) AS AwaitingApproval,
		|	SUM(Table.ToReserve_) AS ToReserve_,
		|	SUM(Table.ToReserveAsNeeded) AS ToReserveAsNeeded,
		|	SUM(Table.Snooze) AS Snooze,
		|	SUM(Table.ToSupply) AS ToSupply,
		|	SUM(Table.NotProvide) AS NotProvide,
		|	
		|	SUM(Table.AvailableMinusReserveNonNegative) AS AvailableMinusReserveNonNegative,
		|	
		|	SUM(Table.ToReserve_) AS Available_Reserve,
		|	CASE
		|		WHEN SUM(Table.AvailableWithLock_Surplus) < 0
		|			THEN 0
		|		ELSE SUM(Table.AvailableWithLock_Surplus)
		|	END AS AvailableWithLock_SurplusNonNegative
		|INTO InventoryAllocationStage1
		|FROM(
		|	SELECT
		|		Table.Products AS Products,
		|		Table.Characteristic AS Characteristic,
		|		Table.Warehouse AS Warehouse,
		|		Table.Purpose AS Purpose,
		|		
		|		0 AS AvailableWithLock,
		|		0 AS AvailableWithoutUnlocking,
		|		0 AS ExpectedWithBlocking,
		|		0 AS ExpectedWithoutUnlocking,
		|		0 AS Reserve_FromBlocked,
		|		0 AS ReserveAsNeeded_FromBlocked,
		|		
		|		0 AS AvailableWithLock_Reserve_FromBlocked,
		|		0 AS AvailableWithLock_ReserveAsNeeded_FromBlocked,
		|		0 AS AvailableWithoutUnlocking_Reserve_FromLocked,
		|		0 AS AvailableWithoutUnlocking_ReserveAsNeeded_FromBlocked,
		|		0 AS ExpectedWithLock_ReserveAsNeeded_FromBlocked,
		|		0 AS ExpectedWithoutUnlocking_ReserveAsNeeded_FromBlocked,
		|		0 AS AvailableWithLock_Surplus,
		|		0 AS AvailableWithoutUnlocking_Surplus,
		|		0 AS ExpectedWithLock_Surplus,
		|		0 AS ExpectedWithoutUnlocking_Surplus,
		|		0 AS NotProvided_ReserveAsNeeded_FromBlocked,
		|		
		|		Table.InStockBalance - Table.LockedInStockBalance AS InStock,
		|		Table.Received_1Balance - Table.LockedReceiptBalance AS Expected_,
		|		Table.OrderedBalance - Table.Received_1Balance AS AwaitingApproval,
		|		Table.ReserveAtWarehouseBalance AS ToReserve_,
		|		Table.ReserveAsReceivedBalance AS ToReserveAsNeeded,
		|		Table.SnoozeReservationBalance AS Snooze,
		|		Table.ToSupplyBalance AS ToSupply,
		|		Table.NotProvideBalance AS NotProvide,
		|		
		|		CASE
		|			WHEN Table.InStockBalance - Table.LockedInStockBalance - Table.ReserveAtWarehouseBalance < 0
		|				THEN 0
		|			ELSE Table.InStockBalance - Table.LockedInStockBalance - Table.ReserveAtWarehouseBalance
		|		END AS AvailableMinusReserveNonNegative
		|	FROM
		|		BalanceOverridable AS Table
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		Lots.Products AS Products,
		|		Lots.Characteristic AS Characteristic,
		|		Lots.Warehouse AS Warehouse,
		|		Lots.Purpose AS Purpose,
		|		
		|		Lots.AvailableWithLock AS AvailableWithLock,
		|		Lots.AvailableWithoutUnlocking AS AvailableWithoutUnlocking,
		|		Lots.ExpectedWithBlocking AS ExpectedWithBlocking,
		|		Lots.ExpectedWithoutUnlocking AS ExpectedWithoutUnlocking,
		|		Lots.Reserve_FromBlocked AS Reserve_FromBlocked,
		|		Lots.ReserveAsNeeded_FromBlocked AS ReserveAsNeeded_FromBlocked,
		|		
		|		Lots.AvailableWithLock_Reserve_FromBlocked AS AvailableWithLock_Reserve_FromBlocked,
		|		Lots.AvailableWithLock_ReserveAsNeeded_FromBlocked AS AvailableWithLock_ReserveAsNeeded_FromBlocked,
		|		Lots.AvailableWithoutUnlocking_Reserve_FromLocked AS AvailableWithoutUnlocking_Reserve_FromLocked,
		|		Lots.AvailableWithoutUnlocking_ReserveAsNeeded_FromBlocked AS AvailableWithoutUnlocking_ReserveAsNeeded_FromBlocked,
		|		Lots.ExpectedWithLock_ReserveAsNeeded_FromBlocked AS ExpectedWithLock_ReserveAsNeeded_FromBlocked,
		|		Lots.ExpectedWithoutUnlocking_ReserveAsNeeded_FromBlocked AS ExpectedWithoutUnlocking_ReserveAsNeeded_FromBlocked,
		|		Lots.AvailableWithLock_Surplus AS AvailableWithLock_Surplus,
		|		Lots.AvailableWithoutUnlocking_Surplus AS AvailableWithoutUnlocking_Surplus,
		|		Lots.ExpectedWithLock_Surplus AS ExpectedWithLock_Surplus,
		|		Lots.ExpectedWithoutUnlocking_Surplus AS ExpectedWithoutUnlocking_Surplus,
		|		Lots.NotProvided_ReserveAsNeeded_FromBlocked AS NotProvided_ReserveAsNeeded_FromBlocked,
		|		
		|		0 AS InStock,
		|		0 AS Expected_,
		|		0 AS AwaitingApproval,
		|		0 AS ToReserve_,
		|		0 AS ToReserveAsNeeded,
		|		0 AS Snooze,
		|		0 AS ToSupply,
		|		0 AS NotProvide,
		|		
		|		0 AS AvailableMinusReserveNonNegative
		|	FROM
		|		DistributionOfInventoryIntoControlledLotsReference AS Lots) AS Table
		|GROUP BY
		|	Table.Products,
		|	Table.Characteristic,
		|	Table.Warehouse,
		|	Table.Purpose
		|HAVING
		|	SUM(Table.InStock) <> 0
		|		OR SUM(Table.Expected_) <> 0
		|		OR SUM(Table.AwaitingApproval) <> 0
		|		OR SUM(Table.ToReserve_) <> 0
		|		OR SUM(Table.ToReserveAsNeeded) <> 0
		|		OR SUM(Table.Snooze) <> 0
		|		OR SUM(Table.ToSupply) <> 0
		|		OR SUM(Table.NotProvide) <> 0
		|		OR SUM(Table.AvailableWithLock_Reserve_FromBlocked) <> 0
		|		OR SUM(Table.AvailableWithLock_ReserveAsNeeded_FromBlocked) <> 0
		|		OR SUM(Table.AvailableWithoutUnlocking_Reserve_FromLocked) <> 0
		|		OR SUM(Table.AvailableWithoutUnlocking_ReserveAsNeeded_FromBlocked) <> 0
		|		OR SUM(Table.ExpectedWithLock_ReserveAsNeeded_FromBlocked) <> 0
		|		OR SUM(Table.ExpectedWithoutUnlocking_ReserveAsNeeded_FromBlocked) <> 0
		|		OR SUM(Table.AvailableWithLock_Surplus) <> 0
		|		OR SUM(Table.AvailableWithoutUnlocking_Surplus) <> 0
		|		OR SUM(Table.ExpectedWithLock_Surplus) <> 0
		|		OR SUM(Table.ExpectedWithoutUnlocking_Surplus) <> 0
		|		OR SUM(Table.NotProvided_ReserveAsNeeded_FromBlocked) <> 0";
	
	Text = StrReplace(Text, "BalanceOverridable", Balance); // @query-part-1
	Text = StrReplace(Text, "ReversingEntryOverridable", TablesNames.ReversingEntry); // @query-part-1
	
	Texts.Add(Text);
	TablesThatAreBeingDestroyed.Add("InventoryAllocationStage1"); // @query-part-1
	
	NestedText =
		"SELECT
		|	Table.Products AS Products,
		|	Table.Characteristic AS Characteristic,
		|	Table.Warehouse AS Warehouse,
		|	Table.Purpose AS Purpose,
		|	
		|	Table.AvailableWithLock AS AvailableWithLock,
		|	Table.AvailableWithoutUnlocking AS AvailableWithoutUnlocking,
		|	Table.ExpectedWithBlocking AS ExpectedWithBlocking,
		|	Table.ExpectedWithoutUnlocking AS ExpectedWithoutUnlocking,
		|	Table.InStock AS InStock,
		|	Table.Expected_ AS Expected_,
		|	Table.AwaitingApproval AS AwaitingApproval,
		|	Table.ToReserve_ AS ToReserve_,
		|	Table.ToReserveAsNeeded AS ToReserveAsNeeded,
		|	Table.Snooze AS Snooze,
		|	Table.ToSupply AS ToSupply,
		|	Table.NotProvide AS NotProvide,
		|	Table.Reserve_FromBlocked AS Reserve_FromBlocked,
		|	Table.ReserveAsNeeded_FromBlocked AS ReserveAsNeeded_FromBlocked,
		|
		|	Table.AvailableWithLock_Reserve_FromBlocked AS AvailableWithLock_Reserve_FromBlocked,
		|	Table.AvailableWithLock_ReserveAsNeeded_FromBlocked AS AvailableWithLock_ReserveAsNeeded_FromBlocked,
		|	Table.AvailableWithoutUnlocking_Reserve_FromLocked AS AvailableWithoutUnlocking_Reserve_FromLocked,
		|	Table.AvailableWithoutUnlocking_ReserveAsNeeded_FromBlocked AS AvailableWithoutUnlocking_ReserveAsNeeded_FromBlocked,
		|	Table.ExpectedWithLock_ReserveAsNeeded_FromBlocked AS ExpectedWithLock_ReserveAsNeeded_FromBlocked,
		|	Table.ExpectedWithoutUnlocking_ReserveAsNeeded_FromBlocked AS ExpectedWithoutUnlocking_ReserveAsNeeded_FromBlocked,
		|	Table.AvailableWithLock_Surplus AS AvailableWithLock_Surplus,
		|	Table.AvailableWithoutUnlocking_Surplus AS AvailableWithoutUnlocking_Surplus,
		|	Table.ExpectedWithLock_Surplus AS ExpectedWithLock_Surplus,
		|	Table.ExpectedWithoutUnlocking_Surplus AS ExpectedWithoutUnlocking_Surplus,
		|	Table.NotProvided_ReserveAsNeeded_FromBlocked AS NotProvided_ReserveAsNeeded_FromBlocked,
		|	Table.Available_Reserve AS Available_Reserve,
		|	Table.AvailableMinusReserveNonNegative AS AvailableMinusReserveNonNegative,
		|	Table.AvailableWithLock_SurplusNonNegative AS AvailableWithLock_SurplusNonNegative,
		|	0 AS Inventory0,
		|	Table.AvailableMinusReserveNonNegative AS Inventory1,
		|	Table.AvailableMinusReserveNonNegative
		|		+ Table.AvailableWithLock_SurplusNonNegative AS Inventory2,
		|	Table.AvailableMinusReserveNonNegative
		|		+ Table.AvailableWithLock_SurplusNonNegative
		|		+ Table.Expected_ AS Inventory3,
		|	Table.AvailableMinusReserveNonNegative
		|		+ Table.AvailableWithLock_SurplusNonNegative
		|		+ Table.Expected_
		|		+ Table.ExpectedWithLock_Surplus AS Inventory4,
		|	Table.AvailableMinusReserveNonNegative
		|		+ Table.AvailableWithLock_SurplusNonNegative
		|		+ Table.Expected_
		|		+ Table.ExpectedWithLock_Surplus
		|		+ Table.AwaitingApproval AS Inventory5,
		|	
		|	0 AS Demand0,
		|	Table.ToReserveAsNeeded AS Demand1,
		|	Table.ToReserveAsNeeded
		|		+ Table.Snooze AS Demand2,
		|	Table.ToReserveAsNeeded
		|		+ Table.Snooze
		|		+ Table.ToSupply AS Demand3
		|FROM
		|	InventoryAllocationStage1 AS Table";
	
	FieldPattern =
		"CASE
		|	WHEN Table.Demand0 > Table.Inventory1 OR Table.Demand1 < Table.Inventory0
		|		THEN 0
		|	ELSE
		|		CASE
		|			WHEN Table.Demand1 < Table.Inventory1
		|				THEN Table.Demand1
		|			ELSE Table.Inventory1
		|		END
		|		- CASE
		|			WHEN Table.Demand0 > Table.Inventory0
		|				THEN Table.Demand0
		|			ELSE Table.Inventory0
		|		END
		|END"; // @query-part-1
	
	Fields = New ValueList();
	
	FieldText = FieldPattern;
	Fields.Add(FieldText, "Available_ReserveAsNeeded"); // @query-part-1
	
	FieldText = StrReplace(FieldPattern, "Inventory1", "Inventory2");
	FieldText = StrReplace(FieldText, "Inventory0", "Inventory1");
	Fields.Add(FieldText, "AvailableWithLock_ReserveAsNeeded"); // @query-part-1
	
	FieldText = StrReplace(FieldPattern, "Inventory1", "Inventory3");
	FieldText = StrReplace(FieldText, "Inventory0", "Inventory2");
	Fields.Add(FieldText, "ExpectedTo_ReserveAsNeeded"); // @query-part-1
	
	FieldText = StrReplace(FieldPattern, "Inventory1", "Inventory4");
	FieldText = StrReplace(FieldText, "Inventory0", "Inventory3");
	Fields.Add(FieldText, "ExpectedWithLock_ReserveAsNeeded"); // @query-part-1
	
	FieldText = StrReplace(FieldPattern, "Inventory1", "Inventory5");
	FieldText = StrReplace(FieldText, "Inventory0", "Inventory4");
	Fields.Add(FieldText, "OnApproval_ReserveAsNeeded"); // @query-part-1
	
	FieldPattern = StrReplace(FieldPattern, "Demand1", "Demand2");
	FieldPattern = StrReplace(FieldPattern, "Demand0", "Demand1");
	
	FieldText = FieldPattern;
	Fields.Add(FieldText, "Available_Postpone"); // @query-part-1
	
	FieldText = StrReplace(FieldPattern, "Inventory1", "Inventory2");
	FieldText = StrReplace(FieldText, "Inventory0", "Inventory1");
	Fields.Add(FieldText, "AvailableWithLock_Postpone"); // @query-part-1
	
	FieldText = StrReplace(FieldPattern, "Inventory1", "Inventory3");
	FieldText = StrReplace(FieldText, "Inventory0", "Inventory2");
	Fields.Add(FieldText, "ExpectedTo_Postpone"); // @query-part-1
	
	FieldText = StrReplace(FieldPattern, "Inventory1", "Inventory4");
	FieldText = StrReplace(FieldText, "Inventory0", "Inventory3");
	Fields.Add(FieldText, "PendingWithLock_Postpone"); // @query-part-1
	
	FieldText = StrReplace(FieldPattern, "Inventory1", "Inventory5");
	FieldText = StrReplace(FieldText, "Inventory0", "Inventory4");
	Fields.Add(FieldText, "PendingApproval_Postpone"); // @query-part-1
	
	FieldPattern = StrReplace(FieldPattern, "Demand2", "Demand3");
	FieldPattern = StrReplace(FieldPattern, "Demand1", "Demand2");
	
	FieldText = FieldPattern;
	Fields.Add(FieldText, "InStock_K"); // @query-part-1
	
	FieldText = StrReplace(FieldPattern, "Inventory1", "Inventory2");
	FieldText = StrReplace(FieldText, "Inventory0", "Inventory1");
	Fields.Add(FieldText, "AvailableWithLock_CSupply"); // @query-part-1
	
	FieldText = StrReplace(FieldPattern, "Inventory1", "Inventory3");
	FieldText = StrReplace(FieldText, "Inventory0", "Inventory2");
	Fields.Add(FieldText, "_KIsExpectedToProvide"); // @query-part-1
	
	FieldText = StrReplace(FieldPattern, "Inventory1", "Inventory4");
	FieldText = StrReplace(FieldText, "Inventory0", "Inventory3");
	Fields.Add(FieldText, "ExpectedWith_KLock"); // @query-part-1
	
	FieldText = StrReplace(FieldPattern, "Inventory1", "Inventory5");
	FieldText = StrReplace(FieldText, "Inventory0", "Inventory4");
	Fields.Add(FieldText, "OnApproval_CSupply"); // @query-part-1
	
	FieldArray = New Array();
	
	FieldPattern =
		"CASE
		|	WHEN Table.Demand0 > Table.Inventory5
		|		THEN Table.Demand1 - Table.Demand0
		|	WHEN Table.Demand1 > Table.Inventory5
		|		THEN Table.Demand1 - Table.Inventory5
		|	ELSE
		|		0
		|END"; // @query-part-1
	
	FieldText = FieldPattern;
	Fields.Add(FieldText, "NotProvided_ReserveAsNeeded"); // @query-part-1
	
	FieldText = StrReplace(FieldPattern, "Demand1", "Demand2");
	FieldText = StrReplace(FieldText, "Demand0", "Demand1");
	Fields.Add(FieldText, "NotProvided_Postpone"); // @query-part-1
	
	FieldText = StrReplace(FieldPattern, "Demand1", "Demand3");
	FieldText = StrReplace(FieldText, "Demand0", "Demand2");
	Fields.Add(FieldText, "Supply_CIsNotProvided"); // @query-part-1
	
	FieldPattern =
		"CASE
		|	WHEN Table.Demand3 > Table.Inventory1
		|		THEN 0
		|	WHEN Table.Demand3 > Table.Inventory0
		|		THEN Table.Inventory1 - Table.Demand3
		|	ELSE
		|		Table.Inventory1 - Table.Inventory0
		|END + &Adjustment "; // @query-part-1
	
	FieldText = FieldPattern;
	FieldText = StrReplace(FieldPattern, "&Adjustment", "Table.InStock - Table.ToReserve_ - Table.AvailableMinusReserveNonNegative"); // @query-part-2
	Fields.Add(FieldText, "Available_Surplus"); // @query-part-1
	
	FieldText = StrReplace(FieldPattern, "&Adjustment", "Table.AvailableWithLock_Surplus - Table.AvailableWithLock_SurplusNonNegative"); // @query-part-2
	FieldText = StrReplace(FieldText, "Inventory1", "Inventory2");
	FieldText = StrReplace(FieldText, "Inventory0", "Inventory1");
	Fields.Add(FieldText, "AvailableWithLock_Surplus"); // @query-part-1
	
	FieldText = StrReplace(FieldPattern, "&Adjustment", "0"); // @query-part-2
	FieldText = StrReplace(FieldText, "Inventory1", "Inventory3");
	FieldText = StrReplace(FieldText, "Inventory0", "Inventory2");
	Fields.Add(FieldText, "Expected_Surplus"); // @query-part-1
	
	FieldText = StrReplace(FieldPattern, "&Adjustment", "0"); // @query-part-2
	FieldText = StrReplace(FieldText, "Inventory1", "Inventory4");
	FieldText = StrReplace(FieldText, "Inventory0", "Inventory3");
	Fields.Add(FieldText, "ExpectedWithLock_Surplus"); // @query-part-1
	
	FieldText = StrReplace(FieldPattern, "&Adjustment", "0"); // @query-part-2
	FieldText = StrReplace(FieldText, "Inventory1", "Inventory5");
	FieldText = StrReplace(FieldText, "Inventory0", "Inventory4");
	Fields.Add(FieldText, "OnApproval_Surplus"); // @query-part-1
	
	FieldArray = New Array();
	For Each Item In Fields Do
		FieldArray.Add(StrTemplate("%1 AS %2", Item.Value, Item.Presentation)); // @query-part-1
	EndDo;
	
	FieldTexts = StrConcat(FieldArray,
		",
		|");
	
	Text =
		"SELECT
		|	Table.Products AS Products,
		|	Table.Characteristic AS Characteristic,
		|	Table.Warehouse AS Warehouse,
		|	Table.Purpose AS Purpose,
		|	
		|	Table.AvailableWithLock AS AvailableWithLock,
		|	Table.AvailableWithoutUnlocking AS AvailableWithoutUnlocking,
		|	Table.ExpectedWithBlocking AS ExpectedWithBlocking,
		|	Table.ExpectedWithoutUnlocking AS ExpectedWithoutUnlocking,
		|	Table.InStock AS InStock,
		|	Table.Expected_ AS Expected_,
		|	Table.AwaitingApproval AS AwaitingApproval,
		|	Table.ToReserve_ AS ToReserve_,
		|	Table.ToReserveAsNeeded AS ToReserveAsNeeded,
		|	Table.Reserve_FromBlocked AS Reserve_FromBlocked,
		|	Table.ReserveAsNeeded_FromBlocked AS ReserveAsNeeded_FromBlocked,
		|	Table.Snooze AS Snooze,
		|	Table.ToSupply AS ToSupply,
		|	Table.NotProvide AS NotProvide,
		|	
		|	Table.AvailableWithLock_Reserve_FromBlocked AS AvailableWithLock_Reserve_FromBlocked,
		|	Table.AvailableWithLock_ReserveAsNeeded_FromBlocked AS AvailableWithLock_ReserveAsNeeded_FromBlocked,
		|	Table.AvailableWithoutUnlocking_Reserve_FromLocked AS AvailableWithoutUnlocking_Reserve_FromLocked,
		|	Table.AvailableWithoutUnlocking_ReserveAsNeeded_FromBlocked AS AvailableWithoutUnlocking_ReserveAsNeeded_FromBlocked,
		|	Table.ExpectedWithLock_ReserveAsNeeded_FromBlocked AS ExpectedWithLock_ReserveAsNeeded_FromBlocked,
		|	Table.ExpectedWithoutUnlocking_ReserveAsNeeded_FromBlocked AS ExpectedWithoutUnlocking_ReserveAsNeeded_FromBlocked,
		|	Table.AvailableWithoutUnlocking_Surplus AS AvailableWithoutUnlocking_Surplus,
		|	Table.ExpectedWithoutUnlocking_Surplus AS ExpectedWithoutUnlocking_Surplus,
		|	Table.NotProvided_ReserveAsNeeded_FromBlocked AS NotProvided_ReserveAsNeeded_FromBlocked,
		|	Table.Available_Reserve AS Available_Reserve,
		|	Table.NotProvide AS NotProvided_NotProvided,
		|
		// cash_reservation_pomer 
		// CASH_TO deposit
		// cash_references
		// CASH_ISL
		// cashblocking_reservation in the meter
		// CASHBLOCK_ Deposit
		// Cash out of the blocking_references
		// cashingisblock_islishek
		// expectance_reservation in the meter
		// expectance_depose
		// Expected_Co-provision
		// Waiting for_isl
		// Waiting for a deadlock_reservation in the meter
		// expecting_block_out
		// Waiting for a lock_reservation
		// Waiting for a lock_isl
		// match_reservation_the meter
		// alignment_offend
		// Agreement_Self- sufficiency
		// List_conformations
		// unsecure_reservationpomere 
		// Unsecure_ Deposit
		// Unsecure_supply
		|	&FieldTexts
		|INTO InventoryAllocationOverridable
		|FROM
		|	NestedText AS Table";
	
	Text = StrReplace(Text, "NestedText", StrTemplate("(%1)", NestedText));
	Text = StrReplace(Text, "&FieldTexts", FieldTexts);
	Text = StrReplace(Text, "InventoryAllocationOverridable", TablesNames.Result); // @query-part-1
	
	Texts.Add(Text);
	TablesThatAreBeingDestroyed.Add(TablesNames.Result); // @query-part-1
	If Not DeleteTemporaryTables Then
		TablesThatAreBeingDestroyed.Clear();
	EndIf;
	
	If QueryText <> "" Then
		InsertTempTablesOfInventoryAllocation(QueryText, TablesNames.Result, Texts, TablesThatAreBeingDestroyed);
	EndIf;
	
	Return Texts;
	
EndFunction

// To initialize Balance calculation parameters for setting actions.
// Returns:
//  Structure - a structure with the names of temp tables at the calculation input:
//   * BalanceSheetsOfControlledLotREFERENCES - String - the name of the incoming temporary table containing measurements and resources
//                                   of the Balances of controlled Lot references according to the Accumulation register "Inventories and needs".
//   * Balance - String - the name of the incoming temporary table containing measurements and Balance resources
//                        according to the Accumulation register "Inventories and needs".
//   * Analysts - String - the name of the incoming temporary table containing analytics for selection,
//                          if you need to get a result not for all controlled Lot references.
//   * InventoryAndDemandsUpdate - String - the name of the incoming temp table containing changes in the Registered Records of
//                                            the Accumulation register of inventory requirements for correcting Registered Records before receiving Balances.
//   * InventoryAllocation - String - the name of the incoming temporary data table of the register of information "Inventory distribution"
//                            for orders for which the action is set. It is necessary to add the quantity
//                            previously received by the order as a reserve upon receipt."
//   * Demands - String - the name of the outgoing temporary table of data on the total needs of orders
//                            contained in the incoming table "Analytics".
//   * Result - String - the name of the outgoing temp table containing the calculation result.
Function NewTableNamesForCalculatingBalancesForSettingActions() Export
	
	TablesNames = New Structure();
	TablesNames.Insert("BalanceSheetsOfControlledLotREFERENCES", "");
	TablesNames.Insert("Balance", "");
	TablesNames.Insert("Analysts", "");
	TablesNames.Insert("InventoryAndDemandsUpdate", "");
	TablesNames.Insert("InventoryAllocation", "");
	TablesNames.Insert("Demands", "");
	TablesNames.Insert("Result", "");
	Return TablesNames;
	
EndFunction

// Substitution to get data on goods Balances
// available for setting the Ship, Reserve, and Reserve actions as they are received in orders.
// 
// Example of use:
// 
//	Query text =
//		"SELECT THE FIRST 10
//		|T Supplies.Nomenclature AS A Nomenclature,
//		|T Supplies.Characteristic AS A Characteristic,
//		|T Supplies.Warehouse AS A Warehouse,
//		|T Supplies.Appointment AS Appointment,
//		|T Supplies.Ordering AS A Controlled Party
//		|PLACE Analytics
//		|FROM
//		|Taccumulation register.Reserves of need.Balances AS Stocks
//		| WHERE
//		|T Supplies.Blocked Cash and status > 0
//		|INDEX BY
//		|Nomenclature, Characteristics, Warehouse, Purpose, Controlled Party
//		|;
//		|SELECT ALLOWED
//		|T Supplies.Nomenclature AS A Nomenclature,
//		|T Supplies.Characteristic AS A Characteristic,
//		|T Supplies.Warehouse AS A Warehouse,
//		|T Supplies.Appointment AS Appointment,
//		|T Supplies.Order AS an Order,
//		|T Supplies.Blocked CASH STATUS AS Blocked CASH status,
//		|T Supplies.Blocked access to A remote control AS blocked access to A remote control,
//		|T Supplies.KRAZBLOCKKEOSTAT AS KRAZBLOCKKEOSTAT,
//		|T Supplies.Reserving a Stored and locked state HOW to reserve a stored and locked State,
//		|T Supplies.RESERVING A number OF accesses to blocked statuses HOW TO reserve A NUMBER OF ACCESSES to blocked STATUSES
//		|PLACE THE INVENTORY OF NEEDSTATESCONTROLLABLE PARTIES
//		|FROM
//		|Taccumulation register.Reserves of need.Balances(,
//		|		(Nomenclature, Characteristics, Warehouse, Purpose) In (
//		|		T Select
//		|			T Filter.Nomenclature AS A Nomenclature,
//		|			T Filter.Characteristic AS A Characteristic,
//		|			T Filter.Warehouse AS A Warehouse,
//		|			T Filter.Appointment AS Appointment
//		|			IZ
//		|			Tanalysts AS A Filter)) HOW ARE THE Stocks
//		|INDEX BY
//		|Nomenclature, Characteristics, Warehouse, Purpose
//		|;
//		|
//		|////////////////////////////////////////////////////////////////////
//		|SELECT ALLOWED
//		|T Supplies.Nomenclature AS A Nomenclature,
//		|T Supplies.Characteristic AS A Characteristic,
//		|T Supplies.Warehouse AS A Warehouse,
//		|T Supplies.Appointment AS Appointment,
//		|T Supplies.Cash AND CASH AS cash and CASH,
//		|T Supplies.Blocked CASH STATUS AS Blocked CASH status,
//		|T Supplies.Ordered quantity AS ordered QUANTITY,
//		|T Supplies.The way the way the way the way the way the way the way the way the way the way the way the way,
//		|T Supplies.Blocked access to A remote control AS blocked access to A remote control,
//		|T Supplies.RESERVING A Homeostat HOW TO RESERVE A HOMEOSTAT,
//		|T Supplies.Reserving the right to access the right to reserve the right to access the right to reserve the right to use the right to use the right to use the right to use the right to use the right to use the right to use the right to use the right to use the right to use the right,
//		|T Supplies.POSTPONING reservationostat HOW TO POSTPONE reservationostat,
//		|T Supplies.COBESPECHENIYOUSTATOK AS cobespecheniyoustatok,
//		|T Supplies.Unsecured status AS UNSECURED status
//		|PLACE THE INVENTORY OF NEEDSTATEMENTS
//		|FROM
//		|Taccumulation register.Reserves of need.Balances(,
//		|		(Nomenclature, Characteristics, Warehouse, Purpose) In (
//		|		T Select
//		|			T Filter.Nomenclature AS A Nomenclature,
//		|			T Filter.Characteristic AS A Characteristic,
//		|			T Filter.Warehouse AS A Warehouse,
//		|			T Filter.Appointment AS Appointment
//		|			IZ
//		|			Tanalysts AS A Filter)) HOW ARE THE Stocks
//		|INDEX BY
//		|Nomenclature, Characteristic, Warehouse, Destination
//		|;
//		|SELECT ALLOWED
//		|	provestize order.Nomenclature AS A Nomenclature,
//		|Tthe notification of the order.Characteristic AS A Characteristic,
//		|	provestize order.Warehouse AS A Warehouse,
//		|	provestize order.Appointment AS Appointment,
//		|	-Distribution of the order.Cash AND STATUS AS cash,
//		|	-Distribution of the order.Blocked CASH Status AS Blocked Cash,
//		|	-Distribution of the order.Ordered AS Ordered,
//		|	-Distribution of the order.HOW will the applicant act,
//		|	-Distribution of the order.Blocked accesstostat AS blocked access,
//		|	-Distribution of the order.KRAZBLOCKKEOSTAT AS KRAZBLOCKKE,
//		|	-Distribution of the order.Reserving a list of blocked STATUSES HOW TO back up A list of blocked ones,
//		|	-Distribution of the order.Reserving the number of blocked STATUSES HOW TO reserve the number of blocked ones,
//		|	-Distribution of the order.reservingnaskladeostat AS reservingnaskladeostat,
//		|	-Distribution of the order.Reserving the number of accessesostat HOW TO reserve the number of accesses,
//		|	-Distribution of the order.Postponing reservationostat HOW to POSTPONE reserving,
//		|	-Distribution of the order.Cobesecure Status AS A cobesecure,
//		|	-Distribution of the order.Unsecured STATUS HOW TO UNSECURE
//		|PLACE INVENTORY NEEDS CHANGE
//		|FROM
//		|Taccumulation register.Reserves of need.Balances(, Order = &Orderposting) HOW TO DISTRIBUTE the order
//		|INDEX BY
//		|Nomenclature, Characteristic, Warehouse, Destination
//		|;
//		|SELECT ALLOWED
//		|T Storage allocation.Nomenclature AS A Nomenclature,
//		|T Storage allocation.Characteristic AS A Characteristic,
//		|T Storage allocation.Warehouse AS A Warehouse,
//		|T Storage allocation.Appointment AS Appointment,
//		|T Storage allocation.States of safety AS STATES of safety,
//		|T Storage allocation.CHARACTERIZATION of NEED AS A CHARACTERIZATION OF NEED,
//		|T Storage allocation.CUSTOM Access AS CUSTOM ACCESS,
//		|T Storage allocation.DATA ACCESSES AS DATA ACCESSES,
//		|T Storage allocation.DATADAVAILABILITY AS DATADAVAILABILITY,
//		|T Storage allocation.Ordering A shipment AS ORDERING A SHIPMENT,
//		|T Storage allocation.DESIRED LOADING DATE AS DESIRED LOADING DATE,
//		|T Storage allocation.Quantity AS Quantity
//		|PLACE THE DISTRIBUTION OF SUPPLIES
//		|FROM
//		|	registration.Distribution OF SUPPLIES AS A DISTRIBUTION of supplies
//		| WHERE
//		|T Storage allocation.CUSTOM Shipment = &CUSTOM TRANSFER
//		|;
//		|SELECT
//		|T Calculation.Nomenclature AS A Nomenclature,
//		|T Calculation.Characteristic AS A Characteristic,
//		|T Calculation.Warehouse AS A Warehouse,
//		|T Calculation.Appointment AS Appointment,
//		|T Calculation.Controlled PARTY AS A Controlled Party,
//		|T Calculation.Quantitative CASH AS Quantitative CASH,
//		|T Calculation.Quantity without control of reservesreferences TO upload AS quantity without control of reservesreferences to upload,
//		|T Calculation.Quantity of action to load HOW quantity of action to load,
//		|T Calculation.The number of actions to reserve the number of accesses AS the number of actions to reserve the number of accesses
//		|FROM
//		|Taccountingstatements FOR Setting ACTIONS AS A Calculation";
//	
//	Nameablice = Document serviceservers.New nameablecountingstatements for setingreferences();
//	Nameplates.Balances = "Inventory needs"; // @query-part-1
//	Nameplates.Leftovers of controlled Parties = "Inventory of needstates of controlled Parties"; // @query-part-1
//	Nameplates.Analysts = "Analysts"; // @query-part-1
//	Nameplates.Inventory Needs Change = "Inventory needs Change"; // @query-part-1
//	Nameplates.Inventory Allocation = "Inventory Allocation"; // @query-part-1
//	Nameplates.Needs = "Needs"; // @query-part-1
//	Nameplates.Result = "Calculation of statuses for setting actions"; // @query-part-1
//	Document servicer.Calculation of statuses for setting actions(Query text, name tables, Truth);
//
// End of the example.
//
// Parameters:
//  QueryText - String - Query Text,
//  TablesNames - See ProvisionInDocumentsServer.NewTableNamesForCalculatingBalancesForSettingActions
//  ExpandByOrders - Boolean - if True, then the outgoing temp table "Result" will be deployed by orders,
//                            since each order has its own quantity available due to the reserves received earlier for
//                            the "Reserve as received" lines.
//  DeleteTemporaryTables - Boolean - if True, the created intermediate temp tables will not be deleted from the query
// Returns:
//  Number - The number of temporary tables added and the number of destroyed ones.
Function CalculationOfBalancesForSettingActions(QueryText, TablesNames, ExpandByOrders = False, DeleteTemporaryTables = True) Export
	
	Texts = New Array();
	TablesThatAreBeingDestroyed = New Array();
	
	TableNameBalance = TablesNames.Balance;
	TableNameBalancesOfControlledLotReferences = TablesNames.BalanceSheetsOfControlledLotREFERENCES;
	DimensionTableName = TablesNames.Analysts;
	TableNameInventoryAndNeedsChange = TablesNames.InventoryAndDemandsUpdate;
	NameOfInventoryAllocationTable = TablesNames.InventoryAllocation;
	NeedsTableName = TablesNames.Demands;
	TableNameResult = TablesNames.Result;
	
	If TableNameBalance = ""
			And TableNameBalancesOfControlledLotReferences <> ""
			And DimensionTableName  = ""
			And TableNameInventoryAndNeedsChange = ""
			And NameOfInventoryAllocationTable = ""
			And NeedsTableName = "" Then
			
		#Region RemainsOfControlledLotReferencesForReports
		
		Text =
			"SELECT
			|	Inventories.Products AS Products,
			|	Inventories.Characteristic AS Characteristic,
			|	Inventories.Warehouse AS Warehouse,
			|	Inventories.Purpose AS Purpose,
			|	Inventories.OrderDocument AS ControlledLotReference,
			|	CASE
			|		WHEN Inventories.LockedInStockBalance
			|				- Inventories.ReserveAtWarehouseFromLockedBalance < 0
			|			THEN
			|				Inventories.LockedInStockBalance
			|					- Inventories.ReserveAtWarehouseFromLockedBalance
			|		WHEN
			|			Inventories.LockedInStockBalance
			|				- Inventories.ReserveAtWarehouseFromLockedBalance
			|				- Inventories.ReserveUponReceiptFromLockedBalance > 0
			|			THEN
			|				Inventories.LockedInStockBalance
			|					- Inventories.ReserveAtWarehouseFromLockedBalance
			|					- Inventories.ReserveUponReceiptFromLockedBalance
			|		ELSE 0
			|	END AS QuantityForShipAction,
			|	
			|	Inventories.LockedInStockBalance AS QuantityWithoutControlOfReservesForShipAction,
			|	
			|	CASE
			|		WHEN
			|			Inventories.LockedInStockBalance
			|				+ Inventories.LockedReceiptBalance
			|				- Inventories.ReserveAtWarehouseFromLockedBalance
			|				- Inventories.ReserveUponReceiptFromLockedBalance > 0
			|			THEN
			|				Inventories.LockedInStockBalance
			|				+ Inventories.LockedReceiptBalance
			|				- Inventories.ReserveAtWarehouseFromLockedBalance
			|				- Inventories.ReserveUponReceiptFromLockedBalance
			|		ELSE 0
			|	END AS QuantityForActionIsReservedAsItBecomesAvailable
			|INTO ResultOverridable
			|FROM
			|	BalanceSheetsOfControlledLotREFERENCESOverridable AS Inventories";
		Text = StrReplace(Text, "BalanceSheetsOfControlledLotREFERENCESOverridable", TableNameBalancesOfControlledLotReferences);
		Text = StrReplace(Text, "ResultOverridable", TableNameResult);
		
		Texts.Add(Text);
		
		If Not DeleteTemporaryTables Then
			TablesThatAreBeingDestroyed.Clear();
		EndIf;
		
		InsertTempTablesOfInventoryAllocation(QueryText, TableNameResult, Texts, TablesThatAreBeingDestroyed);
		Return Texts.Count() + TablesThatAreBeingDestroyed.Count();
		
		#EndRegion
		
	ElsIf TableNameBalance <> ""
			And TableNameBalancesOfControlledLotReferences = ""
			And DimensionTableName  = ""
			And TableNameInventoryAndNeedsChange = ""
			And NameOfInventoryAllocationTable = ""
			And NeedsTableName = "" Then
			
		#Region FreeBalanceForReports
		
		Text =
			"SELECT
			|	Inventories.Products AS Products,
			|	Inventories.Characteristic AS Characteristic,
			|	Inventories.Warehouse AS Warehouse,
			|	Inventories.Purpose AS Purpose,
			|	VALUE(Catalog.ControlledLots.EmptyRef) AS ControlledLotReference,
			|	
			|	CASE
			|		WHEN
			|			Inventories.InStockBalance
			|				- Inventories.LockedInStockBalance
			|				- Inventories.ReserveAtWarehouseBalance < 0
			|			THEN
			|				Inventories.InStockBalance
			|					- Inventories.LockedInStockBalance
			|					- Inventories.ReserveAtWarehouseBalance
			|		WHEN
			|			Inventories.InStockBalance
			|				- Inventories.LockedInStockBalance
			|				- Inventories.ReserveAtWarehouseBalance
			|				- Inventories.ReserveAsReceivedBalance > 0
			|			THEN
			|				Inventories.InStockBalance
			|					- Inventories.LockedInStockBalance
			|					- Inventories.ReserveAtWarehouseBalance
			|					- Inventories.ReserveAsReceivedBalance
			|		ELSE 0
			|	END AS QuantityForShipAction,
			|	
			|	Inventories.InStockBalance - Inventories.LockedInStockBalance AS QuantityWithoutControlOfReservesForShipAction,
			|	Inventories.InStockBalance AS QuantityInStock,
			// Dummy values.
			|	0 AS QuantityForActionIsReservedAsItBecomesAvailable,
			|	0 AS QuantityAvailableAndExpected
			|INTO ResultOverridable
			|FROM
			|	BalanceOverridable AS Inventories";
		Text = StrReplace(Text, "BalanceOverridable", TableNameBalance);
		Text = StrReplace(Text, "ResultOverridable", TableNameResult);
		
		Texts.Add(Text);
		
		If Not DeleteTemporaryTables Then
			TablesThatAreBeingDestroyed.Clear();
		EndIf;
		
		InsertTempTablesOfInventoryAllocation(QueryText, TableNameResult, Texts, TablesThatAreBeingDestroyed);
		Return Texts.Count() + TablesThatAreBeingDestroyed.Count();
		
		#EndRegion
		
	ElsIf TableNameBalance <> ""
			And TableNameBalancesOfControlledLotReferences <> ""
			And DimensionTableName  = ""
			And TableNameInventoryAndNeedsChange = ""
			And NameOfInventoryAllocationTable = ""
			And NeedsTableName = "" Then
			
		#Region AvailableInventoryAndExpectedReceiptsForReports
		
		Text =
			"SELECT
			|	Inventories.Products AS Products,
			|	Inventories.Characteristic AS Characteristic,
			|	Inventories.Warehouse AS Warehouse,
			|	Inventories.Purpose AS Purpose,
			|	SUM(
			|		CASE
			|			WHEN
			|				CASE
			|					WHEN Inventories.ToUnlockBalance
			|							< Inventories.LockedInStockBalance + Inventories.LockedReceiptBalance
			|						THEN Inventories.ToUnlockBalance
			|					ELSE Inventories.LockedInStockBalance + Inventories.LockedReceiptBalance
			|				END
			|					- Inventories.ReserveAtWarehouseFromLockedBalance
			|					- Inventories.ReserveUponReceiptFromLockedBalance > 0
			|				THEN
			|					CASE
			|						WHEN Inventories.ToUnlockBalance
			|								< Inventories.LockedInStockBalance + Inventories.LockedReceiptBalance
			|							THEN Inventories.ToUnlockBalance
			|						ELSE Inventories.LockedInStockBalance + Inventories.LockedReceiptBalance
			|					END
			|						- Inventories.ReserveAtWarehouseFromLockedBalance
			|						- Inventories.ReserveUponReceiptFromLockedBalance
			|			ELSE 0
			|		END) AS Count,
			|	SUM(
			|		CASE
			|			WHEN
			|				CASE
			|					WHEN Inventories.ToUnlockBalance
			|							< Inventories.LockedInStockBalance
			|						THEN Inventories.ToUnlockBalance
			|					ELSE Inventories.LockedInStockBalance
			|				END
			|					- Inventories.ReserveAtWarehouseFromLockedBalance
			|					- Inventories.ReserveUponReceiptFromLockedBalance > 0
			|				THEN
			|					CASE
			|						WHEN Inventories.ToUnlockBalance
			|								< Inventories.LockedInStockBalance
			|							THEN Inventories.ToUnlockBalance
			|						ELSE Inventories.LockedInStockBalance
			|					END
			|						- Inventories.ReserveAtWarehouseFromLockedBalance
			|						- Inventories.ReserveUponReceiptFromLockedBalance
			|			ELSE 0
			|		END) AS QuantityInStock
			|INTO SurplusOfLotReferences
			|FROM
			|	BalanceSheetsOfControlledLotREFERENCESOverridable AS Inventories
			|GROUP BY
			|	Inventories.Products,
			|	Inventories.Characteristic,
			|	Inventories.Warehouse,
			|	Inventories.Purpose
			|INDEX BY
			|	Products, Characteristic, Warehouse, Purpose";
		Text = StrReplace(Text, "BalanceSheetsOfControlledLotREFERENCESOverridable", TableNameBalancesOfControlledLotReferences);
		
		Texts.Add(Text);
		TablesThatAreBeingDestroyed.Add("SurplusOfLotReferences");
		
		Text =
			"SELECT
			|	Inventories.Products AS Products,
			|	Inventories.Characteristic AS Characteristic,
			|	Inventories.Warehouse AS Warehouse,
			|	Inventories.Purpose AS Purpose,
			|	VALUE(Catalog.ControlledLots.EmptyRef) AS ControlledLotReference,
			|	CASE
			|		WHEN
			|			Inventories.InStockBalance
			|				- Inventories.LockedInStockBalance
			|				- Inventories.ReserveAtWarehouseBalance < 0
			|			THEN
			|				Inventories.InStockBalance
			|					- Inventories.LockedInStockBalance
			|					- Inventories.ReserveAtWarehouseBalance
			|		WHEN
			|			Inventories.InStockBalance
			|				- Inventories.LockedInStockBalance
			|				- Inventories.ReserveAtWarehouseBalance
			|				- Inventories.ReserveAsReceivedBalance > 0
			|			THEN
			|				Inventories.InStockBalance
			|					- Inventories.LockedInStockBalance
			|					- Inventories.ReserveAtWarehouseBalance
			|					- Inventories.ReserveAsReceivedBalance
			|		ELSE 0
			|	END AS QuantityForShipAction,
			|	
			|	CASE
			|		WHEN
			|			Inventories.InStockBalance
			|				- Inventories.LockedInStockBalance
			|				+ ISNULL(SurplusOfLotReferences.QuantityInStock, 0)
			|				- Inventories.ReserveAtWarehouseBalance < 0
			|			THEN
			|				Inventories.InStockBalance
			|					- Inventories.LockedInStockBalance
			|					+ ISNULL(SurplusOfLotReferences.QuantityInStock, 0)
			|					- Inventories.ReserveAtWarehouseBalance
			|					+ ISNULL(SurplusOfLotReferences.QuantityInStock, 0)
			|		WHEN
			|			Inventories.InStockBalance
			|				- Inventories.LockedInStockBalance
			|				+ ISNULL(SurplusOfLotReferences.QuantityInStock, 0)
			|				- Inventories.ReserveAtWarehouseBalance
			|				- Inventories.ReserveAsReceivedBalance > 0
			|			THEN
			|				Inventories.InStockBalance
			|					- Inventories.LockedInStockBalance
			|					+ ISNULL(SurplusOfLotReferences.QuantityInStock, 0)
			|					- Inventories.ReserveAtWarehouseBalance
			|					- Inventories.ReserveAsReceivedBalance
			|		ELSE 0
			|	END AS QuantityInStockForActionToReserveAsReceived,
			|	
			|	Inventories.InStockBalance - Inventories.LockedInStockBalance AS QuantityWithoutControlOfReservesForShipAction,
			|	Inventories.InStockBalance AS QuantityInStock,
			|	
			|	CASE
			|		WHEN
			|				Inventories.InStockBalance
			|					+ Inventories.Received_1Balance
			|					+ ISNULL(SurplusOfLotReferences.Count, 0)
			|					- Inventories.LockedInStockBalance
			|					- Inventories.LockedReceiptBalance
			|					- Inventories.ReserveAtWarehouseBalance
			|					- Inventories.ReserveAsReceivedBalance > 0
			|			THEN
			|				Inventories.InStockBalance
			|					+ Inventories.Received_1Balance
			|					+ ISNULL(SurplusOfLotReferences.Count, 0)
			|					- Inventories.LockedInStockBalance
			|					- Inventories.LockedReceiptBalance
			|					- Inventories.ReserveAtWarehouseBalance
			|					- Inventories.ReserveAsReceivedBalance
			|		ELSE 0
			|	END AS QuantityForActionIsReservedAsItBecomesAvailable,
			|	
			|	Inventories.InStockBalance + Inventories.Received_1Balance AS QuantityAvailableAndExpected
			|
			|INTO ResultOverridable
			|FROM
			|	BalanceOverridable AS Inventories
			|		
			|		LEFT JOIN SurplusOfLotReferences AS SurplusOfLotReferences
			|		ON SurplusOfLotReferences.Products = Inventories.Products
			|		 AND SurplusOfLotReferences.Characteristic = Inventories.Characteristic
			|		 AND SurplusOfLotReferences.Warehouse = Inventories.Warehouse
			|		 AND SurplusOfLotReferences.Purpose = Inventories.Purpose";
		
		Text = StrReplace(Text, "BalanceOverridable", TableNameBalance);
		Text = StrReplace(Text, "ResultOverridable", TableNameResult);
		
		Texts.Add(Text);
		
		If Not DeleteTemporaryTables Then
			TablesThatAreBeingDestroyed.Clear();
		EndIf;
		
		InsertTempTablesOfInventoryAllocation(QueryText, TableNameResult, Texts, TablesThatAreBeingDestroyed);
		Return Texts.Count() + TablesThatAreBeingDestroyed.Count();
		
		#EndRegion
		
	ElsIf TableNameBalance <> ""
			And TableNameBalancesOfControlledLotReferences = ""
			And DimensionTableName  = ""
			And TableNameInventoryAndNeedsChange = ""
			And NameOfInventoryAllocationTable <> ""
			And NeedsTableName = "" Then
			
		#Region FreeBalanceIncludingOrderReserves
		
		Text =
			"SELECT
			|	InventoryAllocation.Products AS Products,
			|	InventoryAllocation.Characteristic AS Characteristic,
			|	InventoryAllocation.Warehouse AS Warehouse,
			|	InventoryAllocation.Purpose AS Purpose,
			|	SUM(InventoryAllocation.Count) AS QuantityToShip_
			|INTO ReservesAsReceivedReceivedEarlier
			|FROM
			|	InventoryAllocationOverridable AS InventoryAllocation
			|WHERE
			|	InventoryAllocation.InventoryState = VALUE(Enum.InventoryStates.InStock)
			|	AND InventoryAllocation.DemandCharacteristic = VALUE(Enum.DemandCharacteristics.ReserveAsReceived)
			|GROUP BY
			|	InventoryAllocation.Products,
			|	InventoryAllocation.Characteristic,
			|	InventoryAllocation.Warehouse,
			|	InventoryAllocation.Purpose
			|INDEX BY
			|	Products, Characteristic, Warehouse, Purpose";
			
		Text = StrReplace(Text, "InventoryAllocationOverridable", TablesNames.InventoryAllocation);
		
		Text =
			"SELECT
			|	Inventories.Products AS Products,
			|	Inventories.Characteristic AS Characteristic,
			|	Inventories.Warehouse AS Warehouse,
			|	Inventories.Purpose AS Purpose,
			|	VALUE(Catalog.ControlledLots.EmptyRef) AS ControlledLotReference,
			|	
			|	CASE
			|		WHEN
			|			Inventories.InStockBalance
			|				- Inventories.LockedInStockBalance
			|				- Inventories.ReserveAtWarehouseBalance < 0
			|			THEN
			|				Inventories.InStockBalance
			|					- Inventories.LockedInStockBalance
			|					- Inventories.ReserveAtWarehouseBalance
			|		WHEN
			|			Inventories.InStockBalance
			|				- Inventories.LockedInStockBalance
			|				- Inventories.ReserveAtWarehouseBalance
			|				- Inventories.ReserveAsReceivedBalance > 0
			|			THEN
			|				Inventories.InStockBalance
			|					- Inventories.LockedInStockBalance
			|					- Inventories.ReserveAtWarehouseBalance
			|					- Inventories.ReserveAsReceivedBalance
			|		ELSE 0
			|	END
			|	+ ISNULL(Reserves.QuantityToShip_, 0) AS QuantityForShipAction,
			|	
			|	Inventories.InStockBalance AS QuantityInStock,
			|	
			|	Inventories.InStockBalance
			|		- Inventories.LockedInStockBalance AS QuantityWithoutControlOfReservesForShipAction,
			|	
			|	UNDEFINED AS QuantityForActionIsReservedAsItBecomesAvailable
			|INTO ResultOverridable
			|FROM
			|	BalanceOverridable AS Inventories
			|		
			|		LEFT JOIN ReservesAsReceivedReceivedEarlier AS Reserves
			|		ON Reserves.Products = Inventories.Products
			|		 AND Reserves.Characteristic = Inventories.Characteristic
			|		 AND Reserves.Warehouse = Inventories.Warehouse
			|		 AND Reserves.Purpose = Inventories.Purpose
			|";
		Text = StrReplace(Text, "BalanceOverridable", TableNameBalance);
		Text = StrReplace(Text, "ResultOverridable", TableNameResult);
		
		Texts.Add(Text);
		
		If Not DeleteTemporaryTables Then
			TablesThatAreBeingDestroyed.Clear();
		EndIf;
		
		InsertTempTablesOfInventoryAllocation(QueryText, TableNameResult, Texts, TablesThatAreBeingDestroyed);
		Return Texts.Count() + TablesThatAreBeingDestroyed.Count();
		
		#EndRegion
		
	EndIf;
	
	// Other cases.
	CollateralData(QueryText, TablesNames, DeleteTemporaryTables, ExpandByOrders);
	
EndFunction

// Parameters:
//  QueryText - String - Query Text,
//  TablesNames - See ProvisionInDocumentsServer.NewTableNamesForCalculatingBalancesForSettingActions
//  DeleteTemporaryTables - Boolean - if True, the created intermediate temp tables will not be deleted from the query
//  ExpandByOrders - Boolean - if True, then the outgoing temporary table "Result" will be deployed by orders,
//                            since each order has its own quantity available due to the reserves received earlier for
//                            the "Reserve as received" lines.
//  Resources - String - Resources to get.
// Returns:
//  Number - The number of temporary tables added and the number of destroyed ones.
Function CollateralData(QueryText, TablesNames, DeleteTemporaryTables = True, ExpandByOrders = False) Export
	
	Texts = New Array();
	TablesThatAreBeingDestroyed = New Array();
	
	TableNameBalance = TablesNames.Balance;
	TableNameBalancesOfControlledLotReferences = TablesNames.BalanceSheetsOfControlledLotREFERENCES;
	
	#Region InventoryAndDemandsUpdate
	
	If TablesNames.InventoryAndDemandsUpdate <> "" Then
		
		TableNameBalance = TablesNames.Balance + "SubjectToChanges";
		TableNameBalancesOfControlledLotReferences = TablesNames.BalanceSheetsOfControlledLotREFERENCES + "SubjectToChanges";
		
		If TablesNames.BalanceSheetsOfControlledLotREFERENCES <> "" Then
			Text =
				"SELECT
				|	Set.Products AS Products,
				|	Set.Characteristic AS Characteristic,
				|	Set.Warehouse AS Warehouse,
				|	Set.Purpose AS Purpose,
				|	Set.OrderDocument AS OrderDocument,
				|	SUM(Set.LockedInStockBalance) AS LockedInStockBalance,
				|	SUM(Set.LockedReceiptBalance) AS LockedReceiptBalance,
				|	SUM(Set.ToUnlockBalance) AS ToUnlockBalance,
				|	SUM(Set.ReserveAtWarehouseFromLockedBalance) AS ReserveAtWarehouseFromLockedBalance,
				|	SUM(Set.ReserveUponReceiptFromLockedBalance) AS ReserveUponReceiptFromLockedBalance,
				|	&SumOfNeedField
				|INTO BalancesOfControlledLotReferencesTableNameOverridable
				|FROM (
				|	SELECT
				|		Inventories.Products AS Products,
				|		Inventories.Characteristic AS Characteristic,
				|		Inventories.Warehouse AS Warehouse,
				|		Inventories.Purpose AS Purpose,
				|		Inventories.OrderDocument AS OrderDocument,
				|		Inventories.LockedInStockBalance AS LockedInStockBalance,
				|		Inventories.LockedReceiptBalance AS LockedReceiptBalance,
				|		Inventories.ToUnlockBalance AS ToUnlockBalance,
				|		Inventories.ReserveAtWarehouseFromLockedBalance AS ReserveAtWarehouseFromLockedBalance,
				|		Inventories.ReserveUponReceiptFromLockedBalance AS ReserveUponReceiptFromLockedBalance,
				|		&BalanceOfNeedField
				|	FROM
				|		BalanceSheetsOfControlledLotREFERENCESOverridable AS Inventories
				|	
				|	UNION ALL
				|	
				|	SELECT
				|		ChangesInTable.Products AS Products,
				|		ChangesInTable.Characteristic AS Characteristic,
				|		ChangesInTable.Warehouse AS Warehouse,
				|		ChangesInTable.Purpose AS Purpose,
				|		ChangesInTable.OrderDocument AS OrderDocument,
				|		ChangesInTable.LockedInStock AS LockedInStockBalance,
				|		ChangesInTable.LockedReceipt AS LockedReceiptBalance,
				|		ChangesInTable.ToUnlock AS ToUnlock,
				|		ChangesInTable.ReserveAtWarehouseFromLocked AS ReserveAtWarehouseFromLockedBalance,
				|		ChangesInTable.ReserveUponReceiptFromLocked AS ReserveUponReceiptFromLockedBalance,
				|		&ChangesInFieldOfNeed
				|	FROM
				|		InventoryAndDemandsUpdateOverridable AS ChangesInTable) AS Set
				|GROUP BY
				|	Set.Products,
				|	Set.Characteristic,
				|	Set.Warehouse,
				|	Set.Purpose,
				|	Set.OrderDocument
				|	
				|INDEX BY
				|	Products, Characteristic, Warehouse, Purpose, OrderDocument";
				
			If TablesNames.Demands = "" Then
				Substitution = "0"; // @query-part-1
				Text = StrReplace(Text, "&BalanceOfNeedField", Substitution); // @query-part-1
				Text = StrReplace(Text, "&ChangesInFieldOfNeed", Substitution); // @query-part-1
				Text = StrReplace(Text, "&SumOfNeedField", Substitution); // @query-part-1
			// Adding fields to be included in the outgoing temporary Needs table.
			Else
				Substitution = "
				|		Inventories.ReserveAtWarehouseBalance AS ReserveAtWarehouseBalance,
				|		Inventories.ReserveAsReceivedBalance AS ReserveAsReceivedBalance,
				|		Inventories.SnoozeReservationBalance AS SnoozeReservationBalance,
				|		Inventories.ToSupplyBalance AS ToSupplyBalance,
				|		Inventories.NotProvideBalance AS NotProvideBalance"; // @query-part-1
				Text = StrReplace(Text, "&BalanceOfNeedField", Substitution); // @query-part-1
				
				Substitution = "
				|		ChangesInTable.ReserveAtWarehouse AS ReserveAtWarehouseBalance,
				|		ChangesInTable.ReserveAsReceived AS ReserveAsReceivedBalance,
				|		ChangesInTable.SnoozeReservation AS SnoozeReservationBalance,
				|		ChangesInTable.ToSupply AS ToSupplyBalance,
				|		ChangesInTable.NotProvide AS NotProvideBalance"; // @query-part-1
				Text = StrReplace(Text, "&ChangesInFieldOfNeed", Substitution); // @query-part-1
				
				Substitution = "
				|	SUM(Set.ReserveAtWarehouseBalance) AS ReserveAtWarehouseBalance,
				|	SUM(Set.ReserveAsReceivedBalance) AS ReserveAsReceivedBalance,
				|	SUM(Set.SnoozeReservationBalance) AS SnoozeReservationBalance,
				|	SUM(Set.ToSupplyBalance) AS ToSupplyBalance,
				|	SUM(Set.NotProvideBalance) AS NotProvideBalance"; // @query-part-1
				Text = StrReplace(Text, "&SumOfNeedField", Substitution); // @query-part-1
			EndIf;
			
			Text = StrReplace(Text, "BalanceSheetsOfControlledLotREFERENCESOverridable", TablesNames.BalanceSheetsOfControlledLotREFERENCES);
			Text = StrReplace(Text, "BalancesOfControlledLotReferencesTableNameOverridable", TableNameBalancesOfControlledLotReferences);
			Text = StrReplace(Text, "InventoryAndDemandsUpdateOverridable", TablesNames.InventoryAndDemandsUpdate);
			
			Texts.Add(Text);
			
			TablesThatAreBeingDestroyed.Add(TableNameBalancesOfControlledLotReferences);
			
		EndIf;
		
		Text =
			"SELECT
			|	Set.Products AS Products,
			|	Set.Characteristic AS Characteristic,
			|	Set.Warehouse AS Warehouse,
			|	Set.Purpose AS Purpose,
			|	SUM(Set.InStockBalance) AS InStockBalance,
			|	SUM(Set.LockedInStockBalance) AS LockedInStockBalance,
			|	SUM(Set.OrderedBalance) AS OrderedBalance,
			|	SUM(Set.Received_1Balance) AS Received_1Balance,
			|	SUM(Set.LockedReceiptBalance) AS LockedReceiptBalance,
			|	SUM(Set.ReserveAtWarehouseBalance) AS ReserveAtWarehouseBalance,
			|	SUM(Set.ReserveAsReceivedBalance) AS ReserveAsReceivedBalance,
			|	SUM(Set.SnoozeReservationBalance) AS SnoozeReservationBalance,
			|	SUM(Set.ToSupplyBalance) AS ToSupplyBalance,
			|	SUM(Set.NotProvideBalance) AS NotProvideBalance
			|INTO BalancesTableNameOverridable
			|FROM (
			|	SELECT
			|		Inventories.Products AS Products,
			|		Inventories.Characteristic AS Characteristic,
			|		Inventories.Warehouse AS Warehouse,
			|		Inventories.Purpose AS Purpose,
			|		Inventories.InStockBalance AS InStockBalance,
			|		Inventories.LockedInStockBalance AS LockedInStockBalance,
			|		Inventories.OrderedBalance AS OrderedBalance,
			|		Inventories.Received_1Balance AS Received_1Balance,
			|		Inventories.LockedReceiptBalance AS LockedReceiptBalance,
			|		Inventories.ReserveAtWarehouseBalance AS ReserveAtWarehouseBalance,
			|		Inventories.ReserveAsReceivedBalance AS ReserveAsReceivedBalance,
			|		Inventories.SnoozeReservationBalance AS SnoozeReservationBalance,
			|		Inventories.ToSupplyBalance AS ToSupplyBalance,
			|		Inventories.NotProvideBalance AS NotProvideBalance
			|	FROM
			|		BalanceOverridable AS Inventories
			|	
			|	UNION ALL
			|	
			|	SELECT
			|		Changes.Products AS Products,
			|		Changes.Characteristic AS Characteristic,
			|		Changes.Warehouse AS Warehouse,
			|		Changes.Purpose AS Purpose,
			|		Changes.InStock AS InStockBalance,
			|		Changes.LockedInStock AS LockedInStockBalance,
			|		Changes.Ordered AS OrderedBalance,
			|		Changes.Received_1 AS Received_1Balance,
			|		Changes.LockedReceipt AS LockedReceiptBalance,
			|		Changes.ReserveAtWarehouse AS ReserveAtWarehouseBalance,
			|		Changes.ReserveAsReceived AS ReserveAsReceivedBalance,
			|		Changes.SnoozeReservation AS SnoozeReservationBalance,
			|		Changes.ToSupply AS ToSupplyBalance,
			|		Changes.NotProvide AS NotProvideBalance
			|	FROM
			|		InventoryAndDemandsUpdateOverridable AS Changes) AS Set
			|GROUP BY
			|	Set.Products,
			|	Set.Characteristic,
			|	Set.Warehouse,
			|	Set.Purpose
			|INDEX BY
			|	Products, Characteristic, Warehouse, Purpose";
			
		Text = StrReplace(Text, "BalanceOverridable", TablesNames.Balance);
		Text = StrReplace(Text, "BalancesTableNameOverridable", TableNameBalance);
		Text = StrReplace(Text, "InventoryAndDemandsUpdateOverridable", TablesNames.InventoryAndDemandsUpdate);
		
		Texts.Add(Text);
		
		TablesThatAreBeingDestroyed.Add(TableNameBalance);
		
	EndIf;
	
	#EndRegion
	
	#Region InventoryAllocation
	
	If TablesNames.InventoryAllocation <> "" Then
		
		Text =
			"SELECT
			|	&ExpandByOrders AS ShipmentOrder,
			|	InventoryAllocation.Products AS Products,
			|	InventoryAllocation.Characteristic AS Characteristic,
			|	InventoryAllocation.Warehouse AS Warehouse,
			|	InventoryAllocation.Purpose AS Purpose,
			|	
			|	CASE
			|		WHEN InventoryAllocation.DemandCharacteristic
			|				= VALUE(Enum.DemandCharacteristics.ReserveUponReceiptFromLocked)
			|			THEN InventoryAllocation.ReceiptOrder
			|		ELSE VALUE(Catalog.ControlledLots.EmptyRef)
			|	END AS ControlledLotReference,
			|	
			|	SUM(
			|		CASE
			|			WHEN
			|				NOT InventoryAllocation.InventoryState IN(
			|					VALUE(Enum.InventoryStates.InStock),
			|					VALUE(Enum.InventoryStates.AvailablePendingUnlocking),
			|					VALUE(Enum.InventoryStates.AvailableNotSubjectToUnlocking))
			|				THEN 0
			|			WHEN InventoryAllocation.DemandCharacteristic
			|					= VALUE(Enum.DemandCharacteristics.ReserveUponReceiptFromLocked)
			|				THEN InventoryAllocation.Count
			|			WHEN InventoryAllocation.DemandCharacteristic
			|						= VALUE(Enum.DemandCharacteristics.ReserveAsReceived)
			|					AND InventoryAllocation.InventoryState = VALUE(Enum.InventoryStates.InStock)
			|				THEN InventoryAllocation.Count
			|			ELSE 0
			|		END) AS QuantityToShip_
			|	
			|INTO ReservesAsReceivedReceivedEarlier
			|FROM
			|	InventoryAllocationOverridable AS InventoryAllocation
			|GROUP BY
			|	&ExpandByOrders,
			|	InventoryAllocation.Products,
			|	InventoryAllocation.Characteristic,
			|	InventoryAllocation.Warehouse,
			|	InventoryAllocation.Purpose,
			|	CASE
			|		WHEN InventoryAllocation.DemandCharacteristic
			|				= VALUE(Enum.DemandCharacteristics.ReserveUponReceiptFromLocked)
			|			THEN InventoryAllocation.ReceiptOrder
			|		ELSE VALUE(Catalog.ControlledLots.EmptyRef)
			|	END
			|INDEX BY
			|	Products, Characteristic, Warehouse, Purpose";
			
		Text = StrReplace(Text, "InventoryAllocationOverridable", TablesNames.InventoryAllocation);
		
		Substitution = "UNDEFINED"; // @query-part-1
		Substitution = ?(ExpandByOrders, "InventoryAllocation.ShipmentOrder", Substitution); // @query-part-1
		Text = StrReplace(Text, "&ExpandByOrders", Substitution);
		
		Texts.Add(Text);
		TablesThatAreBeingDestroyed.Add("ReservesAsReceivedReceivedEarlier");
	
	EndIf;
	
	#EndRegion
	
#Region BalanceSheetsOfControlledLotREFERENCES
	
	If TablesNames.BalanceSheetsOfControlledLotREFERENCES <> "" Then
		
		Text =
			"SELECT
			|	Inventories.Products AS Products,
			|	Inventories.Characteristic AS Characteristic,
			|	Inventories.Warehouse AS Warehouse,
			|	Inventories.Purpose AS Purpose,
			|	SUM(
			|		CASE
			|			WHEN
			|				CASE
			|					WHEN Inventories.ToUnlockBalance
			|							< Inventories.LockedInStockBalance + Inventories.LockedReceiptBalance
			|						THEN Inventories.ToUnlockBalance
			|					ELSE Inventories.LockedInStockBalance + Inventories.LockedReceiptBalance
			|				END
			|					- Inventories.ReserveAtWarehouseFromLockedBalance
			|					- Inventories.ReserveUponReceiptFromLockedBalance > 0
			|				THEN
			|					CASE
			|						WHEN Inventories.ToUnlockBalance
			|								< Inventories.LockedInStockBalance + Inventories.LockedReceiptBalance
			|							THEN Inventories.ToUnlockBalance
			|						ELSE Inventories.LockedInStockBalance + Inventories.LockedReceiptBalance
			|					END
			|						- Inventories.ReserveAtWarehouseFromLockedBalance
			|						- Inventories.ReserveUponReceiptFromLockedBalance
			|			ELSE 0
			|		END) AS Count,
			|	SUM(
			|		CASE
			|			WHEN
			|				CASE
			|					WHEN Inventories.ToUnlockBalance
			|							< Inventories.LockedInStockBalance
			|						THEN Inventories.ToUnlockBalance
			|					ELSE Inventories.LockedInStockBalance
			|				END
			|					- Inventories.ReserveAtWarehouseFromLockedBalance
			|					- Inventories.ReserveUponReceiptFromLockedBalance > 0
			|				THEN
			|					CASE
			|						WHEN Inventories.ToUnlockBalance
			|								< Inventories.LockedInStockBalance
			|							THEN Inventories.ToUnlockBalance
			|						ELSE Inventories.LockedInStockBalance
			|					END
			|						- Inventories.ReserveAtWarehouseFromLockedBalance
			|						- Inventories.ReserveUponReceiptFromLockedBalance
			|			ELSE 0
			|		END) AS QuantityInStock
			|INTO SurplusOfLotReferences
			|FROM
			|	BalanceSheetsOfControlledLotREFERENCESOverridable AS Inventories
			|GROUP BY
			|	Inventories.Products,
			|	Inventories.Characteristic,
			|	Inventories.Warehouse,
			|	Inventories.Purpose
			|INDEX BY
			|	Products, Characteristic, Warehouse, Purpose";
		Text = StrReplace(Text, "BalanceSheetsOfControlledLotREFERENCESOverridable", TableNameBalancesOfControlledLotReferences);
		
		Texts.Add(Text);
		TablesThatAreBeingDestroyed.Add("SurplusOfLotReferences");
	
	EndIf;
	
#EndRegion

	#Region Demands
	
	If TablesNames.Demands <> "" Then
		
		Text =
			"SELECT
			|	Demands.Products AS Products,
			|	Demands.Characteristic AS Characteristic,
			|	Demands.Warehouse AS Warehouse,
			|	Demands.Purpose AS Purpose,
			|	Demands.OrderDocument AS ShipmentOrder,
			|	VALUE(Catalog.ControlledLots.EmptyRef) AS ControlledLotReference,
			|	Demands.ReserveAtWarehouseBalance AS ReserveAtWarehouse,
			|	Demands.ReserveAsReceivedBalance AS ReserveAsReceived,
			|	Demands.SnoozeReservationBalance AS SnoozeReservation,
			|	Demands.ToSupplyBalance AS ToSupply,
			|	Demands.NotProvideBalance AS NotProvide
			|INTO DemandsOverridable
			|FROM
			|	BalanceSheetsOfControlledLotREFERENCESOverridable AS Demands
			|WHERE
			|	Demands.ReserveAtWarehouseBalance <> 0
			|		OR Demands.ReserveAsReceivedBalance <> 0
			|		OR Demands.SnoozeReservationBalance <> 0
			|		OR Demands.ToSupplyBalance <> 0
			|		OR Demands.NotProvideBalance <> 0
			|
			|UNION ALL
			|
			|SELECT
			|	Demands.Products AS Products,
			|	Demands.Characteristic AS Characteristic,
			|	Demands.Warehouse AS Warehouse,
			|	Demands.Purpose AS Purpose,
			|	Demands.OrderDocument AS ShipmentOrder,
			|	Demands.OrderDocument AS ControlledLotReference,
			|	Demands.ReserveAtWarehouseFromLockedBalance AS ReserveAtWarehouse,
			|	Demands.ReserveUponReceiptFromLockedBalance AS ReserveAsReceived,
			|	0 AS SnoozeReservation,
			|	0 AS ToSupply,
			|	0 AS NotProvide
			|FROM
			|	BalanceSheetsOfControlledLotREFERENCESOverridable AS Demands
			|WHERE
			|	Demands.ReserveAtWarehouseFromLockedBalance <> 0
			|		OR Demands.ReserveUponReceiptFromLockedBalance <> 0";
			
		Text = StrReplace(Text, "BalanceSheetsOfControlledLotREFERENCESOverridable", TableNameBalancesOfControlledLotReferences);
		Text = StrReplace(Text, "DemandsOverridable", TablesNames.Demands);
		
		Texts.Add(Text);
		
	EndIf;
	
	#EndRegion
	
	Set = New Array();
	
	Text =
		"SELECT
		|	Inventories.Products AS Products,
		|	Inventories.Characteristic AS Characteristic,
		|	Inventories.Warehouse AS Warehouse,
		|	Inventories.Purpose AS Purpose,
		|	&ExpandByOrders AS ShipmentOrder,
		|	VALUE(Catalog.ControlledLots.EmptyRef) AS ControlledLotReference,
		|	CASE
		|		WHEN
		|			Inventories.InStockBalance
		|				- Inventories.LockedInStockBalance
		|				- Inventories.ReserveAtWarehouseBalance < 0
		|			THEN
		|				Inventories.InStockBalance
		|					- Inventories.LockedInStockBalance
		|					- Inventories.ReserveAtWarehouseBalance
		|		WHEN
		|			Inventories.InStockBalance
		|				- Inventories.LockedInStockBalance
		|				- Inventories.ReserveAtWarehouseBalance
		|				- Inventories.ReserveAsReceivedBalance > 0
		|			THEN
		|				Inventories.InStockBalance
		|					- Inventories.LockedInStockBalance
		|					- Inventories.ReserveAtWarehouseBalance
		|					- Inventories.ReserveAsReceivedBalance
		|		ELSE 0
		|	END
		|		+ ISNULL(&Reserves_QuantityToShip, 0) AS QuantityForShipAction,
		|	
		|	CASE
		|		WHEN
		|			Inventories.InStockBalance
		|				- Inventories.LockedInStockBalance
		|				+ ISNULL(&SurplusLotReferences_QuantityInStock, 0)
		|				- Inventories.ReserveAtWarehouseBalance < 0
		|			THEN
		|				Inventories.InStockBalance
		|					- Inventories.LockedInStockBalance
		|					+ ISNULL(&SurplusLotReferences_QuantityInStock, 0)
		|					- Inventories.ReserveAtWarehouseBalance
		|		WHEN
		|			Inventories.InStockBalance
		|				- Inventories.LockedInStockBalance
		|				+ ISNULL(&SurplusLotReferences_QuantityInStock, 0)
		|				- Inventories.ReserveAtWarehouseBalance
		|				- Inventories.ReserveAsReceivedBalance > 0
		|			THEN
		|				Inventories.InStockBalance
		|					- Inventories.LockedInStockBalance
		|					+ ISNULL(&SurplusLotReferences_QuantityInStock, 0)
		|					- Inventories.ReserveAtWarehouseBalance
		|					- Inventories.ReserveAsReceivedBalance
		|		ELSE 0
		|	END
		|		+ ISNULL(&Reserves_QuantityToShip, 0) AS QuantityInStockForActionToReserveAsReceived,
		|	
		|	Inventories.InStockBalance
		|		- Inventories.LockedInStockBalance AS QuantityWithoutControlOfReservesForShipAction,
		|	
		|	Inventories.InStockBalance
		|		+ Inventories.Received_1Balance
		|		+ ISNULL(&SurplusLotReferences_TotalQuantity, 0)
		|		- Inventories.LockedInStockBalance
		|		- Inventories.LockedReceiptBalance
		|		- Inventories.ReserveAtWarehouseBalance
		|		- Inventories.ReserveAsReceivedBalance AS QuantityForActionIsReservedAsItBecomesAvailable
		|INTO ResultOverridable
		|FROM
		|	BalanceOverridable AS Inventories
		|		,SurplusOfLotReferencesOverridable
		|		,ReservesOverridable
		|		
		|WHERE
		|	TRUE IN(
		|		&FilterByAnalytics)";
	
	FilterByAnalytics = "TRUE";
	If TablesNames.Analysts <> "" Then
		
		FilterByAnalytics =
			"SELECT TOP 1
			|			TRUE AS ThereAreRecords
			|		FROM
			|			AnalystsOverridable AS Filter
			|		WHERE
			|			Filter.Products = Inventories.Products
			|				AND Filter.Characteristic = Inventories.CHARACTERISTIC
			|				AND Filter.Warehouse = Inventories.Warehouse
			|				AND Filter.Purpose = Inventories.Purpose
			|				AND Filter.ControlledLotReference = VALUE(Catalog.ControlledLots.EmptyRef)";
	EndIf;
	Text = StrReplace(Text, "&FilterByAnalytics", FilterByAnalytics);
	
	If TablesNames.BalanceSheetsOfControlledLotREFERENCES <> "" Then
		Substitution =
			"		LEFT JOIN SurplusOfLotReferences AS SurplusOfLotReferences
			|		ON SurplusOfLotReferences.Products = Inventories.Products
			|		 AND SurplusOfLotReferences.Characteristic = Inventories.Characteristic
			|		 AND SurplusOfLotReferences.Warehouse = Inventories.Warehouse
			|		 AND SurplusOfLotReferences.Purpose = Inventories.Purpose";
		SubstitutingTotalField = "SurplusOfLotReferences.Count";
		FieldSubstitutionAvailable = "SurplusOfLotReferences.QuantityInStock";
	Else
		Substitution = "";
		SubstitutingTotalField = "0";
		FieldSubstitutionAvailable = "0";
	EndIf;
	Text = StrReplace(Text, ",SurplusOfLotReferencesOverridable", Substitution); // @query-part-1
	Text = StrReplace(Text, "&SurplusLotReferences_TotalQuantity", SubstitutingTotalField); // @query-part-1
	Text = StrReplace(Text, "&SurplusLotReferences_QuantityInStock", FieldSubstitutionAvailable); // @query-part-1
	
	Set.Add(Text);
	
	If TablesNames.BalanceSheetsOfControlledLotREFERENCES <> "" Then
		
		Text =
			"SELECT
			|	Inventories.Products AS Products,
			|	Inventories.Characteristic AS Characteristic,
			|	Inventories.Warehouse AS Warehouse,
			|	Inventories.Purpose AS Purpose,
			|	&ExpandByOrders AS ShipmentOrder,
			|	Inventories.OrderDocument AS ControlledLotReference,
			|	CASE
			|		WHEN Inventories.LockedInStockBalance
			|				- Inventories.ReserveAtWarehouseFromLockedBalance < 0
			|			THEN
			|				Inventories.LockedInStockBalance
			|					- Inventories.ReserveAtWarehouseFromLockedBalance
			|		WHEN
			|			Inventories.LockedInStockBalance
			|				- Inventories.ReserveAtWarehouseFromLockedBalance
			|				- Inventories.ReserveUponReceiptFromLockedBalance > 0
			|			THEN
			|				Inventories.LockedInStockBalance
			|					- Inventories.ReserveAtWarehouseFromLockedBalance
			|					- Inventories.ReserveUponReceiptFromLockedBalance
			|		ELSE 0
			|	END
			|		+ ISNULL(&Reserves_QuantityToShip, 0) AS QuantityForShipAction,
			|	
			|	CASE
			|		WHEN Inventories.LockedInStockBalance
			|				- Inventories.ReserveAtWarehouseFromLockedBalance < 0
			|			THEN
			|				Inventories.LockedInStockBalance
			|					- Inventories.ReserveAtWarehouseFromLockedBalance
			|		WHEN
			|			Inventories.LockedInStockBalance
			|				- Inventories.ReserveAtWarehouseFromLockedBalance
			|				- Inventories.ReserveUponReceiptFromLockedBalance > 0
			|			THEN
			|				Inventories.LockedInStockBalance
			|					- Inventories.ReserveAtWarehouseFromLockedBalance
			|					- Inventories.ReserveUponReceiptFromLockedBalance
			|		ELSE 0
			|	END
			|		+ ISNULL(&Reserves_QuantityToShip, 0) AS QuantityInStockForActionToReserveAsReceived,
			|
			|	Inventories.LockedInStockBalance AS QuantityWithoutControlOfReservesForShipAction,
			|	
			|	Inventories.LockedInStockBalance
			|		+ Inventories.LockedReceiptBalance
			|		- Inventories.ReserveAtWarehouseFromLockedBalance
			|		- Inventories.ReserveUponReceiptFromLockedBalance AS QuantityForActionIsReservedAsItBecomesAvailable
			|FROM
			|	BalanceSheetsOfControlledLotREFERENCESOverridable AS Inventories
			|		
			|		,ReservesOfLotReferencesOverridable
			|WHERE
			|	TRUE IN(
			|		&FilterByAnalytics)";
			
		FilterByAnalytics = "TRUE";
		If TablesNames.Analysts <> "" Then
			
			FilterByAnalytics =
				"SELECT TOP 1
				|			TRUE AS ThereAreRecords
				|		FROM
				|			AnalystsOverridable AS Filter
				|		WHERE
				|			Filter.Products = Inventories.Products
				|				AND Filter.Characteristic = Inventories.CHARACTERISTIC
				|				AND Filter.Warehouse = Inventories.Warehouse
				|				AND Filter.Purpose = Inventories.Purpose
				|				AND Filter.ControlledLotReference = Inventories.OrderDocument
				|				AND Filter.ControlledLotReference <> VALUE(Catalog.ControlledLots.EmptyRef)";
		EndIf;
		Text = StrReplace(Text, "&FilterByAnalytics", FilterByAnalytics);
			
		Set.Add(Text);
		Text = StrConcat(Set, TMCommonUse.QuerySeparatorInJoin());
		Set.Clear();
		Set.Add(Text);
		
	EndIf;
	
	Set.Add(
		"INDEX BY
		|	Products, Characteristic, Warehouse, Purpose, ControlledLotReference");
	
	Text = StrConcat(Set);
	
	If TablesNames.InventoryAllocation = "" Then
		
		Substitution = "UNDEFINED"; // @query-part-1
		Text = StrReplace(Text, "&ExpandByOrders", Substitution); // @query-part-1
		Text = StrReplace(Text, ",ReservesOfLotReferencesOverridable", ""); // @query-part-1
		Text = StrReplace(Text, ",ReservesOverridable", ""); // @query-part-1
		Substitution = "0"; // @query-part-1
		Text = StrReplace(Text, "&Reserves_QuantityToShip", Substitution); // @query-part-1
		
	// Adding a connection to receive reserves as they become available.
	Else
		
		Substitution = "ISNULL(Reserves.ShipmentOrder, UNDEFINED)"; // @query-part-1
		Text = StrReplace(Text, "&ExpandByOrders", Substitution); // @query-part-1
		
		Substitution = "
			|		LEFT JOIN ReservesAsReceivedReceivedEarlier AS Reserves
			|		ON Reserves.Products = Inventories.Products
			|		 AND Reserves.Characteristic = Inventories.Characteristic
			|		 AND Reserves.Warehouse = Inventories.Warehouse
			|		 AND Reserves.Purpose = Inventories.Purpose
			|		 AND Reserves.ControlledLotReference = Inventories.OrderDocument";
		Text = StrReplace(Text, ",ReservesOfLotReferencesOverridable", Substitution); // @query-part-1
		
		Substitution = "
			|		LEFT JOIN ReservesAsReceivedReceivedEarlier AS Reserves
			|		ON Reserves.Products = Inventories.Products
			|		 AND Reserves.Characteristic = Inventories.Characteristic
			|		 AND Reserves.Warehouse = Inventories.Warehouse
			|		 AND Reserves.Purpose = Inventories.Purpose
			|		 AND Reserves.ControlledLotReference = VALUE(Catalog.ControlledLots.EmptyRef)";
		Text = StrReplace(Text, ",ReservesOverridable", Substitution); // @query-part-1
		
		Text = StrReplace(Text, "&Reserves_QuantityToShip", "Reserves.QuantityToShip_"); // @query-part-1
		
	EndIf;
	
	Text = StrReplace(Text, "BalanceSheetsOfControlledLotREFERENCESOverridable", TableNameBalancesOfControlledLotReferences);
	Text = StrReplace(Text, "BalanceOverridable", TableNameBalance);
	Text = StrReplace(Text, "AnalystsOverridable", TablesNames.Analysts);
	Text = StrReplace(Text, "ResultOverridable", TablesNames.Result);
	Texts.Add(Text);
	
	TablesThatAreBeingDestroyed.Add(TablesNames.Result); // @query-part-1
	If Not DeleteTemporaryTables Then
		TablesThatAreBeingDestroyed.Clear();
	EndIf;
	
	InsertTempTablesOfInventoryAllocation(QueryText, TablesNames.Result, Texts, TablesThatAreBeingDestroyed);
	
	Return Texts.Count() + TablesThatAreBeingDestroyed.Count();
	
EndFunction

// Determines whether there are needs for orders.
// Parameters:
//  Orders - Array of DefinedType.ExpectedShipment - Orders
// Returns:
//  Boolean - Truth, if there are needs. False, otherwise.
Function ThereAreNeedsForOrders(Orders) Export
	
	If Orders.Count() = 0 Then
		Return False;
	EndIf;
	
	Query = New Query();
	Query.SetParameter("Orders", Orders);
	Query.Text =
	"SELECT
	|	TRUE AS ThereAreRecords
	|FROM
	|AccumulationRegister.InventoryAndDemands.Balance(, OrderDocument IN(&Orders)) AS Demands
	|WHERE
	|	Demands.ReserveAtWarehouseBalance > 0
	|	OR Demands.ReserveAsReceivedBalance > 0
	|	OR Demands.SnoozeReservationBalance > 0
	|	OR Demands.ToSupplyBalance > 0
	|	OR Demands.NotProvideBalance > 0
	|	OR Demands.ReserveAtWarehouseFromLockedBalance > 0
	|	OR Demands.ReserveUponReceiptFromLockedBalance > 0";
	
	Result = Query.Execute().IsEmpty();
	Return Not Result;
	
EndFunction

// To initialize the parameters for calculating the reserves of controlled Lot references.
// Returns:
//  Structure - a structure with the names of temp tables at the calculation input:
//   * BalanceSheetsOfControlledLotREFERENCES - String - the name of the incoming temporary table containing measurements and resources
//                                   of the Balances of controlled Lot references according to the Accumulation register "Inventories and needs".
//   * ReversingEntry - String - the name of the incoming temporary table containing the
//                       software Registered Records for the Accumulation register "Inventories and needs" that need to be reversed before receiving Balances.
//   * Result - String - the name of the outgoing temp table containing the calculation result.
Function NewTableNamesForDistributionOfInventoryIntoControlledLotsReference() Export
	
	TablesNames = New Structure();
	TablesNames.Insert("BalanceSheetsOfControlledLotREFERENCES", "");
	TablesNames.Insert("ReversingEntry", "");
	TablesNames.Insert("Result", "");
	Return TablesNames;
	
EndFunction

#EndRegion

#EndRegion

#Region Internal

// Parameters:
//  FillParameters - Structure - structure with fields:
//   *DimensionOfProduct - Structure - structure with fields:
//     **Products - CatalogRef.Products -
//     **Characteristic - CatalogRef.ItemsCharacteristics -
//     **Warehouse - CatalogRef.Assignments -
//     **Purpose - CatalogRef.Assignments -
//   *ShipmentOrder - DefinedType.ExpectedShipment -
//   *ToReserveEverything - Number -
//   *TheOrdersTable - ValueTable -
//  ResultAddress - String - address in temporary storage
Procedure ReserveFromOtherOrders(FillParameters, ResultAddress) Export
	
	Measurement = PerformanceMonitor.StartTimeConsumingOperationMeasurement(
		"DataProcessor.OrderSupplyForecast.Form.Form.Command.ReserveAtWarehouse");
	
	SetPrivilegedMode(True);
	ShipmentOrder = FillParameters.ShipmentOrder;
	ToReserveEverything = FillParameters.ToReserveEverything;
	DimensionOfProduct = FillParameters.DimensionOfProduct;
	TheOrdersTable = FillParameters.TheOrdersTable;
	
	// An attempt to reserve other orders without opening the reserve form.
	ReserveFromAvailable = FillParameters.TheOrdersTable = Undefined;
	InsufficientAvailableBalance = False;
	If ReserveFromAvailable Then
		TheOrdersTable = New ValueTable();
		TheOrdersTable.Columns.Add("OrderDocument", Metadata.DefinedTypes.ExpectedShipment.Type);
		TheOrdersTable.Columns.Add("ToWithdrawReserveFromWarehouse", New TypeDescription("Number"));
		TheOrdersTable.Columns.Add("ToWithdrawReserveAsReceived", New TypeDescription("Number"));
	EndIf;
	
	ToCompleteCalculationWithRoutineTask = InventoryAllocation.CountRegisterWithRoutineTask();
	Mode = ProvisionInDocumentsClientServer.FillActionFromListMode();
	UserMessages = New Array();
	ErrorText = Undefined;
	
	Orders = TheOrdersTable.Copy(, "OrderDocument,ToWithdrawReserveFromWarehouse,ToWithdrawReserveAsReceived");
	Orders.GroupBy("OrderDocument", "ToWithdrawReserveFromWarehouse,ToWithdrawReserveAsReceived");
	Orders.Sort("OrderDocument", New CompareValues());
	
	Recorders = Orders.UnloadColumn("OrderDocument");
	
	Recorders.Insert(0, ShipmentOrder);
	
	References = StepsForOrdersToProcessor(Recorders);
	CommonClientServer.SupplementArray(Recorders, References);
	
	ObjectLockIsSet = False;
	ManagedBlockingOnLinksIsInstalled = False;
	ControlledRegisteredRecordsLockIsInstalled = False;
	ControlledLockOnBalanceIsInstalled = False;
	
	BeginTransaction();
	Try
		
		// Blocking - documents, movements, tables of totals.
		For IndexOf = 0 To Recorders.Count() - 1 Do
			CurrentOrder = Recorders[IndexOf];
			LockDataForEdit(CurrentOrder);
		EndDo;
		ObjectLockIsSet = True;
		
		Block = New DataLock();
		For IndexOf = 0 To Recorders.Count() - 1 Do
			
			CurrentOrder = Recorders[IndexOf];
			LockItem = Block.Add(CurrentOrder.Metadata().FullName());
			LockItem.SetValue("Ref", CurrentOrder);
			LockItem.Mode = DataLockMode.Exclusive;
			
		EndDo;
		Block.Lock();
		ManagedBlockingOnLinksIsInstalled = True;
		
		Block = New DataLock();
		For IndexOf = 0 To Recorders.Count() - 1 Do
			CurrentOrder = Recorders[IndexOf];
			LockItem = Block.Add("AccumulationRegister.InventoryAndDemands.RecordSet");
			LockItem.SetValue("Recorder", CurrentOrder);
			LockItem.Mode = DataLockMode.Exclusive;
		EndDo;
		Block.Lock();
		ControlledRegisteredRecordsLockIsInstalled = True;
		
		Query = New Query();
		Query.SetParameter("Products", DimensionOfProduct.Products);
		Query.SetParameter("Characteristic", DimensionOfProduct.Characteristic);
		Query.SetParameter("Warehouse", DimensionOfProduct.Warehouse);
		Query.SetParameter("Purpose", DimensionOfProduct.Purpose);
		Query.SetParameter("Orders", Orders);
		Query.SetParameter("ShipmentOrder", ShipmentOrder);
		
		Query.SetParameter("Recorders", Recorders);
		Query.Text =
			"SELECT DISTINCT
			|	RegisterRecords.Products AS Products,
			|	RegisterRecords.Characteristic AS Characteristic,
			|	RegisterRecords.Warehouse AS Warehouse,
			|	RegisterRecords.Purpose AS Purpose,
			|	RegisterRecords.OrderDocument AS OrderDocument,
			|	RegisterRecords.EventDate AS EventDate
			|FROM
			|	AccumulationRegister.InventoryAndDemands AS RegisterRecords
			|WHERE
			|	RegisterRecords.Recorder IN(&Recorders)
			|		AND RegisterRecords.Active
			|;
			|
			|/////////////////////////////////////////
			|SELECT DISTINCT
			|	RegisterRecords.Products AS Products,
			|	RegisterRecords.Characteristic AS Characteristic,
			|	RegisterRecords.Warehouse AS Warehouse,
			|	RegisterRecords.Purpose AS Purpose
			|FROM
			|	AccumulationRegister.InventoryAndDemands AS RegisterRecords
			|WHERE
			|	RegisterRecords.Recorder IN(&Recorders)
			|		AND RegisterRecords.Active
			|;
			|
			|/////////////////////////////////////////
			|SELECT DISTINCT
			|	RegisterRecords.Products AS Products,
			|	RegisterRecords.Characteristic AS Characteristic,
			|	RegisterRecords.Warehouse AS Warehouse,
			|	RegisterRecords.Purpose AS Purpose
			|FROM
			|	AccumulationRegister.InventoryAndDemands AS RegisterRecords
			|WHERE
			|	RegisterRecords.Recorder IN(&Recorders)
			|		AND RegisterRecords.Active
			|		AND RegisterRecords.Warehouse <> UNDEFINED
			|		AND RegisterRecords.Warehouse <> VALUE(Catalog.Warehouses.EmptyRef)
			|		AND VALUETYPE(RegisterRecords.Warehouse) = TYPE(Catalog.Warehouses)";
		SetPrivilegedMode(True);
		QueryResult = Query.ExecuteBatch();
		SetPrivilegedMode(False);
		
		Block = New DataLock();
		LockItem = Block.Add("AccumulationRegister.InventoryAndDemands");
		LockItem.DataSource = QueryResult[0];
		LockItem.UseFromDataSource("Products", "Products");
		LockItem.UseFromDataSource("Characteristic", "Characteristic");
		LockItem.UseFromDataSource("Warehouse", "Warehouse");
		LockItem.UseFromDataSource("Purpose", "Purpose");
		LockItem.UseFromDataSource("OrderDocument", "OrderDocument");
		LockItem.UseFromDataSource("EventDate", "EventDate");
		LockItem.Mode = DataLockMode.Exclusive;
		
		If Not ToCompleteCalculationWithRoutineTask Then
			
			InventoryAllocation.AddLocks(Block, Undefined, QueryResult[1], QueryResult[2]);
			
		EndIf;
		
		Block.Lock();
		
		ControlledLockOnBalanceIsInstalled = True;
		
		If ReserveFromAvailable Then
			
			Indicators = DataProcessors.OrderSupplyForecast.NumericalReservationParameters(
				DimensionOfProduct.Products,
				DimensionOfProduct.Characteristic,
				DimensionOfProduct.Purpose,
				DimensionOfProduct.Warehouse,
				ShipmentOrder);
				
			If Indicators.Available < Indicators.NeedForOrder - Indicators.ReserveUnderOrder
					Or Indicators.NeedForOrder - Indicators.ReserveUnderOrder < 0 Then
						InsufficientAvailableBalance = True;
			Else
				ToReserveEverything = Indicators.NeedForOrder - Indicators.ReserveUnderOrder;
			EndIf;
			
		EndIf;
		
		If Not InsufficientAvailableBalance Then
			
			// Getting the current quantity that can be withdrawn from orders.
			// The backup team could have been launched a long time ago, there are no real reserves under orders anymore, we need to check.
			// The following situation is possible:
			// The arrival was canceled, according to the table of the register results, there are no stocks and no stock needs. In the task register
			// there are unfinished tasks. Their development should lead to the withdrawal of reserves under orders in
			// the Inventory Allocation information register. We receive data from the information register without blocking, without waiting for these tasks to be completed.
			// We receive reserves and for this amount we set a reserve in the warehouse in the order under which the reservation command is executed.
			// As a result of such execution of the command, a negative free Balance may occur in the warehouse.
			// We do not consider this situation to be a problem, since the arrival is canceled without controlling the reserve in orders and the arrival can
			// be canceled immediately after executing the reserve transfer command. The result will be similar.
			
			TempTablesManager = New TempTablesManager();
			
			Query.TempTablesManager = TempTablesManager;
			Query.Text =
				"SELECT
				|	Orders.OrderDocument AS OrderDocument,
				|	Orders.ToWithdrawReserveAsReceived AS ToWithdrawReserveAsReceived,
				|	Orders.ToWithdrawReserveFromWarehouse AS ToWithdrawReserveFromWarehouse
				|INTO Orders
				|FROM
				|	&Orders AS Orders
				|INDEX BY
				|	OrderDocument
				|;
				|
				|//////////////////////////////////////////////
				|SELECT
				|	Set.OrderDocument AS OrderDocument,
				|	SUM(Set.ReservesAsRequired) AS Count
				|INTO ReservesAsReceivedInOrders
				|FROM(
				|	SELECT
				|		Jobs.ShipmentOrder AS OrderDocument,
				|		-Jobs.ToReserveRemoval AS ReservesAsRequired
				|	FROM
				|		Orders AS Orders
				|			INNER JOIN InformationRegister.JobsForAllocatingInventory AS Jobs
				|			ON Jobs.ShipmentOrder = Orders.OrderDocument
				|			AND Jobs.Products = &Products
				|			AND Jobs.Characteristic = &Characteristic
				|			AND Jobs.Warehouse = &Warehouse
				|			AND Jobs.Purpose = &Purpose
				|	WHERE
				|		Jobs.ToReserveRemoval > 0
				|	
				|	UNION ALL
				|	
				|	SELECT
				|		Inventories.ShipmentOrder AS OrderDocument,
				|		Inventories.Count AS ReservesAsRequired
				|	FROM
				|		Orders AS Orders
				|			INNER JOIN InformationRegister.InventoryAllocation AS Inventories
				|			ON Inventories.ShipmentOrder = Orders.OrderDocument
				|			AND Inventories.Products = &Products
				|			AND Inventories.Characteristic = &Characteristic
				|			AND Inventories.Warehouse = &Warehouse
				|			AND Inventories.Purpose = &Purpose
				|	WHERE
				|		Inventories.Count > 0
				|			AND Inventories.InventoryState = VALUE(Enum.InventoryStates.InStock)
				|			AND Inventories.DemandCharacteristic = VALUE(Enum.DemandCharacteristics.ReserveAsReceived)) AS Set
				|GROUP BY
				|	Set.OrderDocument
				|HAVING
				|	SUM(Set.ReservesAsRequired) > 0
				|INDEX BY
				|	OrderDocument
				|;
				|
				|///////////////////////////////////////
				|SELECT
				|	Table.OrderDocument AS OrderDocument,
				|	Table.ReserveAtWarehouseBalance AS QuantityInStock_,
				|	Table.ReserveAsReceivedBalance AS QuantityAsNeeded
				|INTO ReservesInOrders
				|FROM
				|	AccumulationRegister.InventoryAndDemands.Balance(,
				|		(OrderDocument, Products, Characteristic, Warehouse, Purpose) IN(
				|			SELECT
				|				Orders.OrderDocument AS OrderDocument,
				|				&Products AS Products,
				|				&Characteristic AS Characteristic,
				|				&Warehouse AS Warehouse,
				|				&Purpose AS Purpose
				|			FROM
				|				Orders AS Orders)) AS Table
				|WHERE
				|	Table.ReserveAtWarehouseBalance > 0
				|		OR Table.ReserveAsReceivedBalance > 0
				|INDEX BY
				|	OrderDocument
				|;
				|
				|///////////////////////////////////////
				|SELECT
				|	Orders.OrderDocument AS OrderDocument,
				|	MAX(ReportOrders.Priority.AddlOrderingAttribute) AS Order,
				|	MAX(CASE
				|		WHEN FALSE
				|			OR NOT DynamicStep.Ref IS NULL
				|			THEN TRUE
				|		ELSE FALSE
				|	END) AS InstallingToEnsureAlways,
				|	MAX(CASE
				|		WHEN Orders.ToWithdrawReserveAsReceived < ISNULL(ReservesAsReceivedInOrders.Count, 0)
				|				AND Orders.ToWithdrawReserveAsReceived < ISNULL(ReservesInOrders.QuantityAsNeeded, 0)
				|			THEN Orders.ToWithdrawReserveAsReceived
				|		WHEN ISNULL(ReservesAsReceivedInOrders.Count, 0) < ISNULL(ReservesInOrders.QuantityAsNeeded, 0)
				|			THEN ISNULL(ReservesAsReceivedInOrders.Count, 0)
				|		ELSE ISNULL(ReservesInOrders.QuantityAsNeeded, 0)
				|	END) AS ToWithdrawReserveAsReceived,
				|	MAX(CASE
				|		WHEN Orders.ToWithdrawReserveFromWarehouse < ISNULL(ReservesInOrders.QuantityInStock_, 0)
				|			THEN Orders.ToWithdrawReserveFromWarehouse
				|		ELSE ISNULL(ReservesInOrders.QuantityInStock_, 0)
				|	END) AS ToWithdrawReserveFromWarehouse
				|INTO OrdersAfterLockIsSet
				|FROM
				|	Orders AS Orders
				|		
				|		LEFT JOIN ReservesAsReceivedInOrders AS ReservesAsReceivedInOrders
				|		ON ReservesAsReceivedInOrders.OrderDocument = Orders.OrderDocument
				|		
				|		LEFT JOIN ReservesInOrders AS ReservesInOrders
				|		ON ReservesInOrders.OrderDocument = Orders.OrderDocument
				|		
				|		LEFT JOIN InformationRegister.DocumentsRegistry AS ReportOrders
				|		ON ReportOrders.Ref = Orders.OrderDocument
				|		
				|		LEFT JOIN Document.ProductionStage2_2 AS DynamicStep
				|		ON DynamicStep.Ref = Orders.OrderDocument
				|		 AND DynamicStep.DynamicStructure
				|WHERE
				|	CASE
				|		WHEN Orders.ToWithdrawReserveAsReceived < ISNULL(ReservesAsReceivedInOrders.Count, 0)
				|				AND Orders.ToWithdrawReserveAsReceived < ISNULL(ReservesInOrders.QuantityAsNeeded, 0)
				|			THEN Orders.ToWithdrawReserveAsReceived
				|		WHEN ISNULL(ReservesAsReceivedInOrders.Count, 0) < ISNULL(ReservesInOrders.QuantityAsNeeded, 0)
				|			THEN ISNULL(ReservesAsReceivedInOrders.Count, 0)
				|		ELSE ISNULL(ReservesInOrders.QuantityAsNeeded, 0)
				|	END > 0
				|	OR CASE
				|		WHEN Orders.ToWithdrawReserveFromWarehouse < ISNULL(ReservesInOrders.QuantityInStock_, 0)
				|			THEN Orders.ToWithdrawReserveFromWarehouse
				|		ELSE ISNULL(ReservesInOrders.QuantityInStock_, 0)
				|	END > 0
				|GROUP BY
				|	Orders.OrderDocument
				|INDEX BY
				|	OrderDocument
				|;
				|
				|///////////////////////////
				|SELECT
				|	SUM(Orders.ToWithdrawReserveAsReceived) AS ToWithdrawReserveAsReceived,
				|	SUM(Orders.ToWithdrawReserveFromWarehouse) AS ToWithdrawReserveFromWarehouse
				|FROM
				|	OrdersAfterLockIsSet AS Orders
				|HAVING
				|	SUM(Orders.ToWithdrawReserveAsReceived) <> 0 OR SUM(Orders.ToWithdrawReserveFromWarehouse) <> 0";
			QuantityAsNeeded = 0;
			QuantityFromWarehouse = 0;
			Selection = Query.Execute().Select();
			If Selection.Next() Then
				QuantityAsNeeded = Selection.ToWithdrawReserveAsReceived;
				QuantityFromWarehouse = Selection.ToWithdrawReserveFromWarehouse;
			EndIf;
			
			TempTable = Query.TempTablesManager.Tables["OrdersAfterLockIsSet"];
			OrdersAfterLockIsSet = TempTable.GetData().Unload();
			OrdersAfterLockIsSet.Sort("InstallingToEnsureAlways,Order,OrderDocument", New CompareValues());
			
			Query.SetParameter("WithdrawnReserves", QuantityAsNeeded + QuantityFromWarehouse);
			Query.SetParameter("ToReserveEverything", ToReserveEverything);
			
			// Setting the reserve in the Cur document.
			QueryText =
				"SELECT
				|	&Products AS Products,
				|	&Characteristic AS Characteristic,
				|	&Warehouse AS Warehouse,
				|	&Purpose AS Purpose,
				|	&ShipmentOrder AS ShipmentOrder,
				|	VALUE(Catalog.ControlledLots.EmptyRef) AS ControlledLotReference
				|INTO Table
				|INDEX BY
				|	Products, Characteristic, Warehouse, Purpose, ShipmentOrder
				|;
				|
				|////////////////////////////////////////////////
				|SELECT
				|	Inventories.Products AS Products,
				|	Inventories.Characteristic AS Characteristic,
				|	Inventories.Warehouse AS Warehouse,
				|	Inventories.Purpose AS Purpose,
				|	Inventories.InStockBalance AS InStockBalance,
				|	Inventories.LockedInStockBalance AS LockedInStockBalance,
				|	Inventories.OrderedBalance AS OrderedBalance,
				|	Inventories.Received_1Balance AS Received_1Balance,
				|	Inventories.LockedReceiptBalance AS LockedReceiptBalance,
				|	Inventories.ReserveAtWarehouseBalance AS ReserveAtWarehouseBalance,
				|	Inventories.ReserveAsReceivedBalance AS ReserveAsReceivedBalance,
				|	Inventories.SnoozeReservationBalance AS SnoozeReservationBalance,
				|	Inventories.ToSupplyBalance AS ToSupplyBalance,
				|	Inventories.NotProvideBalance AS NotProvideBalance
				|INTO InventoryAndDemandsBalance
				|FROM
				|	AccumulationRegister.InventoryAndDemands.Balance(,
				|		(Products, Characteristic, Warehouse, Purpose) IN(
				|			SELECT
				|				Filter.Products AS Products,
				|				Filter.Characteristic AS Characteristic,
				|				Filter.Warehouse AS Warehouse,
				|				Filter.Purpose AS Purpose
				|			FROM
				|				Table AS Filter)) AS Inventories
				|INDEX BY
				|	Products, Characteristic, Warehouse, Purpose
				|;
				|
				|////////////////////////////////////////////////
				|SELECT ALLOWED
				|	InventoryAllocation.Products AS Products,
				|	InventoryAllocation.Characteristic AS Characteristic,
				|	InventoryAllocation.Warehouse AS Warehouse,
				|	InventoryAllocation.Purpose AS Purpose,
				|	InventoryAllocation.InventoryState AS InventoryState,
				|	InventoryAllocation.DemandCharacteristic AS DemandCharacteristic,
				|	InventoryAllocation.ReceiptOrder AS ReceiptOrder,
				|	InventoryAllocation.DateOfReceipt AS DateOfReceipt,
				|	InventoryAllocation.AvailabilityDate AS AvailabilityDate,
				|	InventoryAllocation.ShipmentOrder AS ShipmentOrder,
				|	InventoryAllocation.RequestShipmentOn AS RequestShipmentOn,
				|	InventoryAllocation.Count AS Count
				|INTO InventoryAllocation
				|FROM
				|	InformationRegister.InventoryAllocation AS InventoryAllocation
				|WHERE
				|	TRUE IN(
				|		SELECT TOP 1
				|			TRUE AS ThereAreRecords
				|		FROM
				|			Table AS Filter
				|		WHERE
				|			Filter.Products = InventoryAllocation.Products
				|			AND Filter.Characteristic = InventoryAllocation.Characteristic
				|			AND Filter.Warehouse = InventoryAllocation.Warehouse
				|			AND Filter.Purpose = InventoryAllocation.Purpose
				|			AND Filter.ShipmentOrder = InventoryAllocation.ShipmentOrder)
				|;
				|
				|/////////////////////////////////////////////////////////////
				|SELECT
				|	Table.Products AS Products,
				|	Table.Characteristic AS Characteristic,
				|	Table.Warehouse AS Warehouse,
				|	Table.Purpose AS Purpose,
				|	VALUE(Catalog.ControlledLots.EmptyRef) AS ControlledLotReference,
				|	CASE
				|		WHEN &ToReserveEverything > ISNULL(Balance.QuantityForShipAction, 0) + &WithdrawnReserves
				|			THEN (ISNULL(Balance.QuantityForShipAction, 0) + &WithdrawnReserves)
				|		ELSE &ToReserveEverything
				|	END AS Count
				|FROM
				|	Table AS Table
				|		
				|		LEFT JOIN CalculationOfBalancesForSettingActions AS Balance
				|		ON Balance.ShipmentOrder = Table.ShipmentOrder
				|		AND Balance.Products = Table.Products
				|		AND Balance.Characteristic = Table.Characteristic
				|		AND Balance.Warehouse = Table.Warehouse
				|		AND Balance.Purpose = Table.Purpose";
			
			TablesNames = NewTableNamesForCalculatingBalancesForSettingActions();
			TablesNames.Balance = "InventoryAndDemandsBalance"; // @query-part-1
			TablesNames.Analysts = "Table"; // @query-part-1
			TablesNames.InventoryAllocation = "InventoryAllocation"; // @query-part-1
			TablesNames.Result = "CalculationOfBalancesForSettingActions"; // @query-part-1
			CalculationOfBalancesForSettingActions(QueryText, TablesNames, True);
			
			Query.Text = QueryText;
			
			WarehouseRemnants = Query.Execute().Unload();
			
			ShippingOrders = StepsForOrdersToProcessor(CommonClientServer.ValueInArray(ShipmentOrder));
			If ShippingOrders.Count() = 0 Then
				ShippingOrders.Add(ShipmentOrder);
			EndIf;
			
			ActionCode = "ACTION_RESERVE";
			For Each CurrentOrder In ShippingOrders Do
				
				DocumentObject = CurrentOrder.GetObject(); // DocumentObject -
				If DocumentObject.Posted Then
					
					DocumentObject.AdditionalProperties.Insert("ControlSupply", False);
					DocumentObject.AdditionalProperties.Insert("BlockInventoryAllocation", True);
					
					ObjectManager = Common.ObjectManagerByRef(CurrentOrder);
					EmbeddingParameters = ObjectManager.AvailableRemainingEmbeddingOptions(DocumentObject);
					
					InternalParameters = New Structure("IsDocument", True);
					EmbeddingParameters.Insert("InternalParameters", InternalParameters);
					
					Tables = New Map();
					InsertTables(Tables, EmbeddingParameters.FormDataSerializationPattern, "");
					FillInTableNamesAsAppropriate(EmbeddingParameters, Tables);
					
					QueryText = QueryTextTemporaryDocumentDataTable(EmbeddingParameters, Tables);
					InternalParameters.Insert("QueryTextTemporaryDocumentDataTable", QueryText);
					
					FillInTablesFromObject(Tables, New Structure("Object", DocumentObject));
					
					Query.TempTablesManager = New TempTablesManager();
					AddTemporaryDocumentDataTable(Query.TempTablesManager, Tables, EmbeddingParameters);
					
					Query.Text =
						"SELECT
						|	Table.Products AS Products,
						|	Table.Products.ItemsType AS ItemsType,
						|	Table.Characteristic AS Characteristic,
						|	Table.Warehouse AS Warehouse,
						|	Table.ShipmentOrder AS ShipmentOrder,
						|	Table.RowCode AS RowCode,
						|	Table.WithAssignment AS WithAssignment,
						|	
						|	CASE
						|		WHEN Table.WithAssignment
						|			THEN Table.Purpose
						|			ELSE VALUE(Catalog.Assignments.EmptyRef)
						|	END AS Purpose,
						|	
						|	VALUE(Catalog.ControlledLots.EmptyRef) AS ControlledLotReference,
						|
						|	Table.SupplyOption AS SupplyOption,
						|	Table.Package AS Package,
						|	Table.NumberOfPackages AS NumberOfPackages,
						|	Table.Count AS Count,
						|	Table.LineNumber AS CollectionItem,
						|	TRUE AS AvailableStockControl,
						|	Table.TheShipmentDateOfAllLinesIsASingleDate AS TheShipmentDateOfAllLinesIsASingleDate
						|FROM
						|	TemporaryDocumentDataTable AS Table
						|WHERE
						|	NOT Table.Canceled
						|		AND Table.SupplyOption IN(
						|			VALUE(Enum.SupplyOptions.ReserveAsReceived),
						|			VALUE(Enum.SupplyOptions.ToSupply))
						|		AND Table.ShipmentOrder = &ShipmentOrder
						|		AND Table.Products = &Products
						|		AND Table.Characteristic = &Characteristic
						|		AND Table.Warehouse = &Warehouse
						|		AND Table.Products = &Products
						|		AND CASE
						|			WHEN Table.WithAssignment
						|				THEN Table.Purpose
						|			ELSE VALUE(Catalog.Assignments.EmptyRef)
						|		END = &Purpose";
					RowsData = Query.Execute().Unload();
					
					ArrayOfPaths = StrSplit(EmbeddingParameters.TableName, ".");
					TabularSectionName = "";
					If ArrayOfPaths.Count() = 3 Then
						TabularSectionName = ArrayOfPaths[2];
					EndIf;
					If TabularSectionName = "" Then
						Collection = RowsData.Copy();
						Collection.Columns.Add("RowID", Common.TypeDescriptionNumber(15, 0));
						Collection[0].RowID = 1;
						RowsIDs = CommonClientServer.ValueInArray(1);
					Else
						Collection = DocumentObject[TabularSectionName];
						RowsIDs = RowsData.UnloadColumn("CollectionItem");
					EndIf;
					
					PackingFactors = PackingFactors(Collection, Undefined);
					
					NewTable = NewTableIsDecorated();
					
					DataOfAccounting = New Structure("WarehouseRemnants,TableDecorated", WarehouseRemnants, NewTable);
					ParametersForFillingInActions = New Structure("PopulateWithTheWholePackagings,PickUpWarehouse", False, False);
					ChangesTable = TableForSettingActions(
						ActionCode,
						ParametersForFillingInActions,
						Collection,
						RowsIDs,
						RowsData,
						PackingFactors,
						DataOfAccounting);
						
					If TabularSectionName = "" Then
						If ChangesTable.Count() = 1 Then
							FillPropertyValues(DocumentObject, ChangesTable[0], "SupplyOption");
						EndIf;
					Else
						SetActionsFromTable(DocumentObject[TabularSectionName], ChangesTable, EmbeddingParameters);
					EndIf;
					If TypeOf(DocumentObject.Ref) = Type("DocumentRef.ProductionStage2_2") Then
						
						StatusFillingData = ProductionManagement.FillInDataWhenStatusChanges(DocumentObject);
						Documents.ProductionStage2_2.AfterFillingOutCollateral(
							DocumentObject,
							ChangesTable,
							Mode,
							Undefined,
							StatusFillingData);
							
					Else
						ObjectManager.AfterFillingOutCollateral(DocumentObject, ChangesTable, Mode, Undefined);
					EndIf;
					If DocumentObject.CheckFilling() Then
						SetPrivilegedMode(False);
						DocumentObject.Write(DocumentWriteMode.Posting);
						SetPrivilegedMode(True);
					Else
						UserMessages = GetUserMessages(True);
						Raise StrTemplate(NStr("vi = 'Chứng từ %1 chưa được kết chuyển và sẽ chưa được xử lý.';
												|ru = 'Документ %1 не проведен и не будет обработан.';
												|en = 'Document %1 has not been posted and will not be processed.'; fa = 'Document %1 has not been posted and will not be processed.';
												|it = 'Documento %1 non è registrato e non sarà elaborato.';
												|pl = 'Dokument%1 nie jest zatwierdzony i nie będzie przetworzony.';
												|tr = '%1 belgesi kaydedilmedi ve işlenmeyecek.'"), ShipmentOrder);
					EndIf;
					
				EndIf;
				
			EndDo;
			
			// Checking that the control has not been violated after the reserve has been set in the order.
			OrdersAfterLockIsSet.Columns.Add("ToInstallationToProvision", Common.TypeDescriptionNumber(15, 3));
			ToInstallationToProvision = 0;
			
			SelectedOrders_1 = OrdersAfterLockIsSet.Copy(New Structure("InstallingToEnsureAlways", True));
			If SelectedOrders_1.Count() > 0 Then
				SelectedOrders_1.GroupBy(, "ToWithdrawReserveFromWarehouse,ToWithdrawReserveAsReceived");
				ToInstallationToProvision = SelectedOrders_1[0].ToWithdrawReserveFromWarehouse + SelectedOrders_1[0].ToWithdrawReserveAsReceived;
			EndIf;
			
			If Constants.ControlBalanceOfGoodsToBeReservedUponReceipt.Get() Then
				
				Query.Text =
					"SELECT
					|	Balance.InStockBalance
					|		+ Balance.Received_1Balance
					|		- Balance.ReserveAtWarehouseBalance
					|		- Balance.ReserveAsReceivedBalance AS Balance
					|FROM
					|	AccumulationRegister.InventoryAndDemands.Balance(,
					|		Products = &Products
					|			AND Characteristic = &Characteristic
					|			AND Warehouse = &Warehouse
					|			AND Purpose = &Purpose) AS Balance
					|WHERE
					|	Balance.InStockBalance
					|		+ Balance.Received_1Balance
					|		- Balance.ReserveAtWarehouseBalance
					|		- Balance.ReserveAsReceivedBalance < 0";
				Selection = Query.Execute().Select();
				
				If Selection.Next() Then
					
					ToInstallationToProvision = Max(ToInstallationToProvision, Min(QuantityFromWarehouse + QuantityAsNeeded, - Selection.Balance));
					
				EndIf;
				
			EndIf;
			
			If ToInstallationToProvision > 0 Then
				
				TotalRows = OrdersAfterLockIsSet.Count();
				For Counter = 1 To TotalRows Do
					
					TableRow = OrdersAfterLockIsSet[TotalRows - Counter];
					TableRow.ToInstallationToProvision = Min(ToInstallationToProvision,
						TableRow.ToWithdrawReserveFromWarehouse + TableRow.ToWithdrawReserveAsReceived);
					ToInstallationToProvision = ToInstallationToProvision - TableRow.ToInstallationToProvision;
					
				EndDo;
				
			EndIf;
			
			// Withdrawal of the reserve in the warehouse in the documents.
			For IndexOf = 0 To OrdersAfterLockIsSet.Count() - 1 Do
				
				TableRow = OrdersAfterLockIsSet[IndexOf];
				ChangeQuantityFromStock = TableRow.ToWithdrawReserveFromWarehouse;
				ToProvideEverythingFromWarehouse = Min(TableRow.ToInstallationToProvision, ChangeQuantityFromStock);
				
				ToProvideAsSoonAsEverythingIsReceived = Min(
					TableRow.ToWithdrawReserveAsReceived,
					Max(0, TableRow.ToInstallationToProvision - TableRow.ToWithdrawReserveFromWarehouse));
				
				If TableRow.ToWithdrawReserveFromWarehouse > 0 Or TableRow.ToInstallationToProvision > 0 Then
					
					ShippingOrders = StepsForOrdersToProcessor(CommonClientServer.ValueInArray(TableRow.OrderDocument));
					
					If ShippingOrders.Count() = 0 Then
						ShippingOrders.Add(TableRow.OrderDocument);
					EndIf;
					
					For Each CurrentOrder In ShippingOrders Do
						
						DocumentObject = CurrentOrder.GetObject();
						If DocumentObject.Posted Then
							
							ThisIsInconsistentOrder = TypeOf(DocumentObject) = Type("DocumentObject.SalesOrder")
									And DocumentObject.Status = Enums.SalesOrderStatuses.NotApproved
								Or TypeOf(DocumentObject) = Type("DocumentObject.RequestForReturnOfGoodsFromCustomer")
									And DocumentObject.Status = Enums.StatusesOfRequestsForReturnOfGoodsFromCustomers.NotAgreedUpon;
							
							DocumentObject.AdditionalProperties.Insert("ControlSupply", False);
							DocumentObject.AdditionalProperties.Insert("BlockInventoryAllocation", True);
							ObjectManager = Common.ObjectManagerByRef(CurrentOrder);
							
							EmbeddingParameters = ObjectManager.AvailableRemainingEmbeddingOptions(DocumentObject);
							
							InternalParameters = New Structure("IsDocument", True);
							EmbeddingParameters.Insert("InternalParameters", InternalParameters);
							
							Tables = New Map();
							InsertTables(Tables, EmbeddingParameters.FormDataSerializationPattern, "");
							FillInTableNamesAsAppropriate(EmbeddingParameters, Tables);
							
							QueryText = QueryTextTemporaryDocumentDataTable(EmbeddingParameters, Tables);
							InternalParameters.Insert("QueryTextTemporaryDocumentDataTable", QueryText);
							
							FillInTablesFromObject(Tables, New Structure("Object", DocumentObject));
							
							Query.TempTablesManager = New TempTablesManager();
							AddTemporaryDocumentDataTable(Query.TempTablesManager, Tables, EmbeddingParameters);
							
							Query.SetParameter("ThisIsInconsistentOrder", ThisIsInconsistentOrder);
							Query.SetParameter("ReceiveReserveAsNeeded",
								TableRow.ToInstallationToProvision > 0
									And TableRow.ToInstallationToProvision > TableRow.ToWithdrawReserveFromWarehouse);
							Query.Text =
								"SELECT
								|	DocumentDataTable.Package AS Package,
								|	DocumentDataTable.Products AS Products,
								|	DocumentDataTable.LineNumber AS CollectionItem
								|FROM
								|	TemporaryDocumentDataTable AS DocumentDataTable
								|WHERE
								|	DocumentDataTable.Products = &Products
								|	AND DocumentDataTable.Characteristic = &Characteristic
								|	AND DocumentDataTable.Warehouse = &Warehouse
								|	AND CASE
								|		WHEN DocumentDataTable.WithAssignment
								|			THEN DocumentDataTable.Purpose
								|		ELSE VALUE(Catalog.Assignments.EmptyRef)
								|	END = &Purpose
								|	AND DocumentDataTable.SupplyOption = VALUE(Enum.SupplyOptions.FromWarehouse)
								|		OR (&ThisIsInconsistentOrder AND DocumentDataTable.SupplyOption = VALUE(Enum.SupplyOptions.Ship))
								|		OR (&ReceiveReserveAsNeeded AND DocumentDataTable.SupplyOption = VALUE(Enum.SupplyOptions.ReserveAsReceived))
								|	AND NOT DocumentDataTable.Canceled
								|ORDER BY
								|	CollectionItem";
							
							Table = Query.Execute().Unload();
							
							ChangesTable = New ValueTable();
							ChangesTable.Columns.Add("NumberOfPackages");
							ChangesTable.Columns.Add("SupplyOption");
							ChangesTable.Columns.Add("Series");
							ChangesTable.Columns.Add("Warehouse");
							ChangesTable.Columns.Add("Id");
							ChangesTable.Columns.Add("String");
							ChangesTable.Columns.Add("IsNewLine", New TypeDescription("Boolean"));
							
							OptionFromWarehouse = Enums.SupplyOptions.FromWarehouse;
							ShipOption = Enums.SupplyOptions.Ship;
							ReserveOptionAsNeeded = Enums.SupplyOptions.ReserveAsReceived;
							OptionToProvide = Enums.SupplyOptions.ToSupply;
							
							ArrayOfPaths = StrSplit(EmbeddingParameters.TableName, ".");
							TabularSectionName = "";
							If ArrayOfPaths.Count() = 3 Then
								TabularSectionName = ArrayOfPaths[2];
							EndIf;
							Collection = DocumentObject[TabularSectionName];
							PackingFactors = PackingFactors(Table, Undefined);
							For RowIndex = 0 To Table.Count() - 1 Do
								
								String = Table[RowIndex];
								RowID = String.CollectionItem;
								ZoomRatio = PackingFactors.Get(RowID);
								ZoomRatio = ?(ZoomRatio = Undefined, 1, ZoomRatio);
								String = Collection[String.CollectionItem - 1];
								
								If String.SupplyOption = ReserveOptionAsNeeded Then
									
									If String.Count = ToProvideAsSoonAsEverythingIsReceived Then // for dimensional units of measurement, rounding of the quantity is possible
										NumberOfPackagesEditTotal = String.NumberOfPackages;
									Else
										NumberOfPackagesEditTotal = ToProvideAsSoonAsEverythingIsReceived / ZoomRatio;
									EndIf;
									
									NumberOfPackages = Min(NumberOfPackagesEditTotal, String.NumberOfPackages);
									ToProvideAsSoonAsEverythingIsReceived = ToProvideAsSoonAsEverythingIsReceived - NumberOfPackages * ZoomRatio;
									
									If NumberOfPackages = String.NumberOfPackages Then
										
										AddedRow = ChangesTable.Add();
										FillPropertyValues(AddedRow, String);
										AddedRow.SupplyOption = OptionToProvide;
										AddedRow.Id = RowID;
										
									ElsIf NumberOfPackages > 0 Then
										
										AddedRow = ChangesTable.Add();
										FillPropertyValues(AddedRow, String);
										AddedRow.NumberOfPackages = AddedRow.NumberOfPackages - NumberOfPackages;
										AddedRow.Id = RowID;
										
										AddedRow = ChangesTable.Add();
										FillPropertyValues(AddedRow, String);
										AddedRow.SupplyOption = OptionToProvide;
										AddedRow.NumberOfPackages = NumberOfPackages;
										AddedRow.Id = RowID;
										AddedRow.IsNewLine = True;
										
									EndIf;
									
								ElsIf String.SupplyOption = OptionFromWarehouse Or String.SupplyOption = ShipOption And ThisIsInconsistentOrder Then
									
									If String.Count = ToProvideEverythingFromWarehouse Then // for dimensional units of measurement, rounding of the quantity is possible
										NumberOfPackagesEditTotal = String.NumberOfPackages;
									Else
										NumberOfPackagesEditTotal = ToProvideEverythingFromWarehouse / ZoomRatio;
									EndIf;
									
									NumberOfPackages = Min(NumberOfPackagesEditTotal, String.NumberOfPackages);
									ToProvideEverythingFromWarehouse = ToProvideEverythingFromWarehouse - NumberOfPackages * ZoomRatio;
									ChangeQuantityFromStock = ChangeQuantityFromStock - NumberOfPackages * ZoomRatio;
									
									BalanceOfPackagesInRow = String.NumberOfPackages - NumberOfPackages;
									BalanceInLine = BalanceOfPackagesInRow * ZoomRatio;
									
									If BalanceInLine = ChangeQuantityFromStock Then // for dimensional units of measurement, rounding of the quantity is possible
										NumberOfPackagesEditTotal = BalanceOfPackagesInRow;
									Else
										NumberOfPackagesEditTotal = ChangeQuantityFromStock / ZoomRatio;
									EndIf;
									
									NumberOfPackagesAsNeeded = Min(NumberOfPackagesEditTotal, BalanceOfPackagesInRow);
									ChangeQuantityFromStock = ChangeQuantityFromStock - NumberOfPackagesAsNeeded * ZoomRatio;
									
									If NumberOfPackages = String.NumberOfPackages Then
										
										AddedRow = ChangesTable.Add();
										FillPropertyValues(AddedRow, String);
										AddedRow.SupplyOption = OptionToProvide;
										AddedRow.Id = RowID;
										
									ElsIf NumberOfPackagesAsNeeded = String.NumberOfPackages Then
										
										AddedRow = ChangesTable.Add();
										FillPropertyValues(AddedRow, String);
										AddedRow.SupplyOption = ReserveOptionAsNeeded;
										AddedRow.Id = RowID;
										
									ElsIf NumberOfPackages + NumberOfPackagesAsNeeded = String.NumberOfPackages Then
										
										AddedRow = ChangesTable.Add();
										FillPropertyValues(AddedRow, String);
										AddedRow.SupplyOption = OptionToProvide;
										AddedRow.NumberOfPackages = AddedRow.NumberOfPackages - NumberOfPackagesAsNeeded;
										AddedRow.Id = RowID;
										
										AddedRow = ChangesTable.Add();
										FillPropertyValues(AddedRow, String);
										AddedRow.SupplyOption = ReserveOptionAsNeeded;
										AddedRow.NumberOfPackages = NumberOfPackagesAsNeeded;
										AddedRow.Id = RowID;
										AddedRow.IsNewLine = True;
										
									ElsIf NumberOfPackages > 0 Or NumberOfPackagesAsNeeded > 0 Then
										
										AddedRow = ChangesTable.Add();
										FillPropertyValues(AddedRow, String);
										AddedRow.NumberOfPackages = AddedRow.NumberOfPackages - NumberOfPackages - NumberOfPackagesAsNeeded;
										AddedRow.Id = RowID;
										
										If NumberOfPackages > 0 Then
											
											AddedRow = ChangesTable.Add();
											FillPropertyValues(AddedRow, String);
											AddedRow.SupplyOption = OptionToProvide;
											AddedRow.NumberOfPackages = NumberOfPackages;
											AddedRow.Id = RowID;
											AddedRow.IsNewLine = True;
											
										EndIf;
										
										If NumberOfPackagesAsNeeded > 0 Then
											
											AddedRow = ChangesTable.Add();
											FillPropertyValues(AddedRow, String);
											AddedRow.SupplyOption = ReserveOptionAsNeeded;
											AddedRow.NumberOfPackages = NumberOfPackagesAsNeeded;
											AddedRow.Id = RowID;
											AddedRow.IsNewLine = True;
											
										EndIf;
										
									EndIf;
									
								EndIf;
								
							EndDo;
							
							SetActionsFromTable(Collection, ChangesTable, EmbeddingParameters);
							If TypeOf(DocumentObject.Ref) = Type("DocumentRef.ProductionStage2_2") Then
								
								StatusFillingData = ProductionManagement.FillInDataWhenStatusChanges(DocumentObject);
								Documents.ProductionStage2_2.AfterFillingOutCollateral(
									DocumentObject,
									ChangesTable,
									Mode,
									Undefined,
									StatusFillingData);
									
							Else
								ObjectManager.AfterFillingOutCollateral(DocumentObject, ChangesTable, Mode, Undefined);
							EndIf;
							If DocumentObject.CheckFilling() Then
								SetPrivilegedMode(False);
								DocumentObject.Write(DocumentWriteMode.Posting);
								SetPrivilegedMode(True);
							Else
								UserMessages = GetUserMessages(True);
								Raise StrTemplate(NStr("vi = 'Chứng từ %1 chưa được kết chuyển và sẽ chưa được xử lý.';
														|ru = 'Документ %1 не проведен и не будет обработан.';
														|en = 'Document %1 has not been posted and will not be processed.'; fa = 'Document %1 has not been posted and will not be processed.';
														|it = 'Documento %1 non è registrato e non sarà elaborato.';
														|pl = 'Dokument%1 nie jest zatwierdzony i nie będzie przetworzony.';
														|tr = '%1 belgesi kaydedilmedi ve işlenmeyecek.'"), TableRow.OrderDocument);
							EndIf;
							
						EndIf;
						
					EndDo;
					
				EndIf;
				
			EndDo;
			
			// Withdrawal of the reserve as it is received from orders, recalculation of the register of information Distribution of stocks.
			Query.TempTablesManager = TempTablesManager;
			If ToCompleteCalculationWithRoutineTask Then
				
				RecordID = New UUID();
				// Recording of reserve withdrawal tasks as they are received.
				SetOfTasks = InformationRegisters.JobsForAllocatingInventory.CreateRecordSet();
				
				// To start recalculating the information register.
				Job = SetOfTasks.Add();
				Job.Products = DimensionOfProduct.Products;
				Job.Characteristic = DimensionOfProduct.Characteristic;
				Job.Warehouse = DimensionOfProduct.Warehouse;
				Job.Purpose = DimensionOfProduct.Purpose;
				Job.ShipmentOrder = ShipmentOrder;
				Job.RecordID = RecordID;
				
				For IndexOf = 0 To OrdersAfterLockIsSet.Count() - 1 Do
					TableRow = OrdersAfterLockIsSet[IndexOf];
					Job = SetOfTasks.Add();
					Job.Products = DimensionOfProduct.Products;
					Job.Characteristic = DimensionOfProduct.Characteristic;
					Job.Warehouse = DimensionOfProduct.Warehouse;
					Job.Purpose = DimensionOfProduct.Purpose;
					Job.RecordID = RecordID;
					Job.ShipmentOrder = TableRow.OrderDocument;
					Job.ToReserveRemoval = TableRow.ToWithdrawReserveAsReceived;
				EndDo;
				SetOfTasks.Write(False);
				
			ElsIf Not ToCompleteCalculationWithRoutineTask Then
				
				Query.Text =
					"SELECT
					|	&Products AS Products,
					|	&Characteristic AS Characteristic,
					|	&Warehouse AS Warehouse,
					|	&Purpose AS Purpose
					|INTO InventoryDistributionProducts
					|INDEX BY
					|	Products, Characteristic, Warehouse, Purpose
					|;
					|
					|///////////////////////////////////////
					|SELECT
					|	&Products AS Products,
					|	&Characteristic AS Characteristic,
					|	&Warehouse AS Warehouse,
					|	&Purpose AS Purpose,
					|	Table.OrderDocument AS ShipmentOrder,
					|	Table.ToWithdrawReserveAsReceived AS Shipment
					|INTO ChangingBalanceOfGoodsToControlBalance
					|FROM
					|	OrdersAfterLockIsSet AS Table
					|WHERE
					|	Table.ToWithdrawReserveAsReceived > 0
					|INDEX BY
					|	Products, Characteristic, Warehouse, Purpose, OrderDocument";
				
				SetPrivilegedMode(True);
				Query.Execute();
				
				RequestingStates = New Query();
				RequestingStates.TempTablesManager = TempTablesManager;
				InventoryAllocation.AddTemporaryStateUpdateTables(RequestingStates, "InventoryDistributionProducts", "BeforeWrite");
				
				InventoryAllocation.RecordDistributionOfStocksInTransaction(Query);
				
				InventoryAllocation.AddTemporaryStateUpdateTables(RequestingStates, "InventoryDistributionProducts", "OnWrite");
				InventoryAllocation.TableOfChangesStockAllocationForStateCalculation(RequestingStates);
				
				Document = DocumentsPosting.DocumentEmulation(Documents.SalesOrder.EmptyRef(), Undefined);
				DocumentsStates.ReflectDocumentStates(Document, TempTablesManager);
				OrderStructureDocumentPosting.CreateTasksForCalculatingStructureOfOrderDistributionOfInventoryWhenWritingDocument(Document, TempTablesManager);
				SetPrivilegedMode(False);
				
			EndIf;
			
		EndIf;
		
		CommitTransaction();
		
	Except
		
		RollbackTransaction();
		ErrorMessage = ErrorProcessing.BriefErrorDescription(ErrorInfo());
		LogEventName = NStr("vi = 'Trạng thái đảm bảo: Dự phòng trong kho';
							|ru = 'Состояние обеспечения: Резервировать на складе';
							|en = 'Supply forecast: Reserve at warehouse'; fa = 'Supply forecast: Reserve at warehouse';
							|it = 'Состояние обеспечения: Резервировать на складе';
							|pl = 'Supply forecast: Reserve at warehouse';
							|tr = 'Tedarik durumu: Ambarda rezerve et'", Common.DefaultLanguageCode());
		WriteLogEvent(LogEventName, EventLogLevel.Error);
		
		If Not ObjectLockIsSet Then
			ErrorText = StrTemplate(NStr("vi = 'Không thể phong tỏa đối tượng %1, có thể là nó đang được soạn.';
										|ru = 'Не удалось заблокировать объект %1, возможно он редактируется.';
										|en = 'Cannot lock the %1 object. It may be being edited.'; fa = 'Cannot lock the %1 object. It may be being edited.';
										|it = 'Не удалось заблокировать объект %1, возможно он редактируется.';
										|pl = 'Cannot lock the %1 object. It may be being edited.';
										|tr = '%1 nesnesi kilitlenemedi, düzenleniyor olabilir.'"), CurrentOrder);
		ElsIf Not ManagedBlockingOnLinksIsInstalled Then
			ErrorText = StrTemplate(NStr("vi = 'Không thể phong tỏa đối tượng %1, hãy thử lại sau. Chi tiết xem trong nhật ký sự kiện.';
										|ru = 'Не удалось заблокировать объект %1, через некоторое время попробуйте снова. Подробности см. в журнале регистрации.';
										|en = 'Cannot lock the %1 object. Please try again later. For details, see the event log.'; fa = 'Cannot lock the %1 object. Please try again later. For details, see the event log.';
										|it = 'Не удалось заблокировать объект %1, через некоторое время попробуйте снова. Подробности см. в журнале регистрации.';
										|pl = 'Cannot lock the %1 object. Please try again later. For details, see the event log.';
										|tr = '%1 nesnesi kilitlenemedi, biraz sonra tekrar deneyin. Ayrıntılar için kayıt günlüğüne bakın.'"), CurrentOrder);
		ElsIf Not ControlledRegisteredRecordsLockIsInstalled Then
			ErrorText = StrTemplate(NStr("vi = 'Không thể phong tỏa đối tượng %1, hãy thử lại sau. Chi tiết xem trong nhật ký sự kiện.';
										|ru = 'Не удалось заблокировать объект %1, через некоторое время попробуйте снова. Подробности см. в журнале регистрации.';
										|en = 'Cannot lock the %1 object. Please try again later. For details, see the event log.'; fa = 'Cannot lock the %1 object. Please try again later. For details, see the event log.';
										|it = 'Не удалось заблокировать объект %1, через некоторое время попробуйте снова. Подробности см. в журнале регистрации.';
										|pl = 'Cannot lock the %1 object. Please try again later. For details, see the event log.';
										|tr = '%1 nesnesi kilitlenemedi, biraz sonra tekrar deneyin. Ayrıntılar için kayıt günlüğüne bakın.'"), CurrentOrder);
		ElsIf Not ControlledLockOnBalanceIsInstalled Then
			ErrorText = NStr("vi = 'Không thể phong tỏa số dư hàng hóa, hãy thử lại sau. Chi tiết xem trong nhật ký sự kiện.';
							|ru = 'Не удалось заблокировать остатки товаров, через некоторое время попробуйте снова. Подробности см. в журнале регистрации.';
							|en = 'Cannot lock the goods balance. Please try again later. For details, see the event log.'; fa = 'Cannot lock the goods balance. Please try again later. For details, see the event log.';
							|it = 'Не удалось заблокировать остатки товаров, через некоторое время попробуйте снова. Подробности см. в журнале регистрации.';
							|pl = 'Cannot lock the goods balance. Please try again later. For details, see the event log.';
							|tr = 'Ürün bakiyeleri kilitlenemedi, biraz sonra tekrar deneyin. Ayrıntılar için kayıt günlüğüne bakın.'");
		Else
			ErrorText = ErrorMessage;
		EndIf;
		
	EndTry;
	
	CheckToRunBackgroundInventoryAllocationJob();
	
	Messages = New Structure("ErrorText,UserMessages", ErrorText,UserMessages);
	
	If InsufficientAvailableBalance Then
		Messages = Undefined;
	EndIf;
	
	PutToTempStorage(Messages, ResultAddress);
	
	NumberOfProcessedData = Recorders.Count();
	PerformanceMonitor.EndTimeConsumingOperationMeasurement(Measurement, NumberOfProcessedData);
	
EndProcedure

Procedure SetActionsFromTableToExternalTable(Form, ChangesTable, ExternalTable, EmbeddingParameters = Undefined) Export
	
	If TypeOf(Form) = Type("ClientApplicationForm") Then
		EmbeddingParameters = Form.AvailableRemainingEmbeddingOptions;
		Collection = ProvisionInDocumentsClientServer.CollectionOnForm(Form, EmbeddingParameters);
	Else
		Collection = Form;
	EndIf;
	
	ProcessedRows = New Map();
	Id = Undefined;
	ThisIsDataOfFormCollection = TypeOf(Collection) = Type("FormDataCollection");
	For IndexOf = 0 To ChangesTable.Count() - 1 Do
		
		SecurityLine = ChangesTable[IndexOf];
		
		// Selecting an existing one, or adding a new line.
		If Id <> SecurityLine.Id Then
			
			Id = SecurityLine.Id;
			If ThisIsDataOfFormCollection Then
				LineProducts_ = Collection.FindByID(Id);
			Else
				LineProducts_ = Collection[Id - 1];
			EndIf;
			ProcessedRows.Insert(LineProducts_, True);
			
		EndIf;
		
		NewRow = ExternalTable.Add();
		FillPropertyValues(NewRow, LineProducts_);
		FillPropertyValues(NewRow, SecurityLine);
		
	EndDo;
	
	For Each String In Collection Do
		If ProcessedRows.Get(String) <> True Then
			NewRow = ExternalTable.Add();
			FillPropertyValues(NewRow, String);
		EndIf;
	EndDo;
	
EndProcedure

// Parameters:
//  RecordSet - InformationRegisterRecordSet.InventoryAllocation
//  ItemCompliance - Matching From Matching From Matching From Matching From Reference Link.Warehouses
Procedure ExchangesWhenReceivingFileData(RecordSet, ItemCompliance) Export
	
	For Each Record In RecordSet Do
		
		CharacteristicCompliance = ItemCompliance.Get(Record.Products);
		If CharacteristicCompliance = Undefined Then
			CharacteristicCompliance = New Map();
			ItemCompliance.Insert(Record.Products, CharacteristicCompliance);
		EndIf;
		
		AssignmentCompliance = CharacteristicCompliance.Get(Record.Characteristic);
		If AssignmentCompliance = Undefined Then
			AssignmentCompliance = New Map();
			CharacteristicCompliance.Insert(Record.Characteristic, AssignmentCompliance);
		EndIf;
		
		WarehouseCompliance = AssignmentCompliance.Get(Record.Purpose);
		If WarehouseCompliance = Undefined Then
			WarehouseCompliance = New Map();
			AssignmentCompliance.Insert(Record.Purpose, WarehouseCompliance);
		EndIf;
		
		If Record.Warehouse = Undefined Then
			WarehouseCompliance.Insert(0);
		Else
			WarehouseCompliance.Insert(Record.Warehouse);
		EndIf;
		
	EndDo;
	
EndProcedure

// Parameters:
// ItemCompliance - Matching From Matching From Matching From Matching From Reference Link.Warehouses
Procedure ExchangesAfterDataUpload(ItemCompliance) Export
	
	MeasurementTable = InformationRegisters.JobsForAllocatingInventory.CreateRecordSet().Unload(,
		"Products,Characteristic,Warehouse,Purpose");
	
	For Each ProductItem In ItemCompliance Do
		
		CharacteristicCompliance = ProductItem.Value;
		
		For Each ElementCharacteristic In CharacteristicCompliance Do
			
			AssignmentCompliance = ElementCharacteristic.Value;
			
			For Each AssignmentItem In AssignmentCompliance Do
				
				WarehouseCompliance = AssignmentItem.Value;
				
				For Each WarehouseElement In WarehouseCompliance Do
					
					NewRow = MeasurementTable.Add();
					NewRow.Products = ProductItem.Key;
					NewRow.Characteristic = ElementCharacteristic.Key;
					NewRow.Purpose = AssignmentItem.Key;
					NewRow.Warehouse = ?(WarehouseElement.Key = 0, Undefined, WarehouseElement.Key);
					
				EndDo;
				
			EndDo;
			
		EndDo;
		
	EndDo;
	
	TempTablesManager = New TempTablesManager();
	Query = New Query();
	Query.TempTablesManager = TempTablesManager;
	Query.SetParameter("MeasurementTable", MeasurementTable);
	Query.Text =
		"SELECT
		|	Table.Products AS Products,
		|	Table.Characteristic AS Characteristic,
		|	Table.Warehouse AS Warehouse,
		|	Table.Purpose AS Purpose
		|INTO MeasurementTable
		|FROM
		|	&MeasurementTable AS Table
		|INDEX BY
		|	Products, Characteristic, Warehouse, Purpose
		|;
		|
		|//////////////////////////////////////
		|SELECT
		|	Balance.Products AS Products,
		|	Balance.Characteristic AS Characteristic,
		|	Balance.Warehouse AS Warehouse,
		|	Balance.Purpose AS Purpose,
		|	Balance.OrderDocument AS OrderDocument,
		|	Balance.EventDate AS EventDate,
		|	Balance.InStockBalance AS InStock,
		|	Balance.Received_1Balance AS Received_1,
		|	Balance.OrderedBalance AS Ordered,
		|	Balance.ReserveAtWarehouseBalance AS ReserveAtWarehouse,
		|	Balance.ReserveAsReceivedBalance AS ReserveAsReceived,
		|	Balance.SnoozeReservationBalance AS SnoozeReservation,
		|	Balance.ToSupplyBalance AS ToSupply,
		|	Balance.NotProvideBalance AS NotProvide,
		|	Balance.LockedInStockBalance AS LockedInStock,
		|	Balance.LockedReceiptBalance AS LockedReceipt,
		|	Balance.ToUnlockBalance AS ToUnlock,
		|	Balance.ReserveAtWarehouseFromLockedBalance AS ReserveAtWarehouseFromLocked,
		|	Balance.ReserveUponReceiptFromLockedBalance AS ReserveUponReceiptFromLocked
		|INTO RegisterRecords
		|FROM
		|	AccumulationRegister.InventoryAndDemands.Balance(,
		|		(Products, Characteristic, Warehouse, Purpose) IN(
		|			SELECT
		|				Table.Products AS Products,
		|				Table.Characteristic AS Characteristic,
		|				Table.Warehouse AS Warehouse,
		|				Table.Purpose AS Purpose
		|			FROM
		|				MeasurementTable AS Table)) AS Balance
		|INDEX BY
		|	Products, Characteristic, Warehouse, Purpose, OrderDocument, EventDate
		|;
		|
		|//////////////////////////////////////
		|SELECT
		|	Records.Products AS Products,
		|	Records.Characteristic AS Characteristic,
		|	Records.Warehouse AS Warehouse,
		|	Records.Purpose AS Purpose,
		|	Records.InventoryState AS InventoryState,
		|	Records.DemandCharacteristic AS DemandCharacteristic,
		|	Records.ShipmentOrder AS ShipmentOrder,
		|	Records.RequestShipmentOn AS RequestShipmentOn,
		|	Records.ReceiptOrder AS ReceiptOrder,
		|	Records.DateOfReceipt AS DateOfReceipt,
		|	Records.AvailabilityDate AS AvailabilityDate,
		|	Records.Count AS Count
		|INTO InventoryAllocation
		|FROM
		|	InformationRegister.InventoryAllocation AS Records
		|		INNER JOIN MeasurementTable AS Table
		|		ON Table.Products = Records.Products
		|		 AND Table.Characteristic = Records.Characteristic
		|		 AND Table.Warehouse = Records.Warehouse
		|		 AND Table.Purpose = Records.Purpose
		|WHERE
		|	Records.Count <> 0
		|INDEX BY
		|	DemandCharacteristic
		|;
		|
		|//////////////////////////////////////
		|SELECT
		|	Set.Products AS Products,
		|	Set.Characteristic AS Characteristic,
		|	Set.Warehouse AS Warehouse,
		|	Set.Purpose AS Purpose,
		|	Set.OrderDocument AS OrderDocument,
		|	Set.EventDate AS EventDate,
		|	SUM(Set.InStock) AS InStock,
		|	SUM(Set.Received_1) AS Received_1,
		|	SUM(Set.Ordered) AS Ordered,
		|	SUM(Set.ReserveAtWarehouse) AS ReserveAtWarehouse,
		|	SUM(Set.ReserveAsReceived) AS ReserveAsReceived,
		|	SUM(Set.SnoozeReservation) AS SnoozeReservation,
		|	SUM(Set.ToSupply) AS ToSupply,
		|	SUM(Set.NotProvide) AS NotProvide,
		|	SUM(Set.LockedInStock) AS LockedInStock,
		|	SUM(Set.LockedReceipt) AS LockedReceipt,
		|	SUM(Set.ToUnlock) AS ToUnlock,
		|	SUM(Set.ReserveAtWarehouseFromLocked) AS ReserveAtWarehouseFromLocked,
		|	SUM(Set.ReserveUponReceiptFromLocked) AS ReserveUponReceiptFromLocked
		|INTO InformationRecords
		|FROM(
		// Available.
		|	SELECT
		|		Table.Products AS Products,
		|		Table.Characteristic AS Characteristic,
		|		Table.Warehouse AS Warehouse,
		|		Table.Purpose AS Purpose,
		|		UNDEFINED AS OrderDocument,
		|		DATETIME(1, 1, 1) AS EventDate,
		|		Table.Count AS InStock,
		|		0 AS Received_1,
		|		0 AS Ordered,
		|		0 AS ReserveAtWarehouse,
		|		0 AS ReserveAsReceived,
		|		0 AS SnoozeReservation,
		|		0 AS ToSupply,
		|		0 AS NotProvide,
		|		0 AS LockedInStock,
		|		0 AS LockedReceipt,
		|		0 AS ToUnlock,
		|		0 AS ReserveAtWarehouseFromLocked,
		|		0 AS ReserveUponReceiptFromLocked
		|	FROM
		|		InventoryAllocation AS Table
		|	WHERE
		|		Table.InventoryState IN(
		|			VALUE(Enum.InventoryStates.InStock),
		|			VALUE(Enum.InventoryStates.AvailablePendingUnlocking),
		|			VALUE(Enum.InventoryStates.AvailableNotSubjectToUnlocking))
		|	
		|	UNION ALL
		|	
		// In the schedule and available for controlled Lot references.
		|	SELECT
		|		Table.Products AS Products,
		|		Table.Characteristic AS Characteristic,
		|		Table.Warehouse AS Warehouse,
		|		Table.Purpose AS Purpose,
		|		Table.ReceiptOrder AS OrderDocument,
		|		Table.DateOfReceipt AS EventDate,
		|		0 AS InStock,
		|		CASE
		|			WHEN Table.InventoryState IN(
		|					VALUE(Enum.InventoryStates.ExpectedForReceiptWithoutLock),
		|					VALUE(Enum.InventoryStates.ExpectedForReceiptWithLock),
		|					VALUE(Enum.InventoryStates.ExpectedForReceiptNotSubjectToUnlocking))
		|				THEN Table.Count
		|			ELSE 0
		|		END AS Received_1,
		|		CASE
		|			WHEN Table.InventoryState IN(
		|					VALUE(Enum.InventoryStates.ExpectedForReceiptWithoutLock),
		|					VALUE(Enum.InventoryStates.PendingSupplyApproval),
		|					VALUE(Enum.InventoryStates.ExpectedForReceiptWithLock),
		|					VALUE(Enum.InventoryStates.ExpectedForReceiptNotSubjectToUnlocking))
		|				THEN Table.Count
		|			ELSE 0
		|		END AS Ordered,
		|		0 AS ReserveAtWarehouse,
		|		0 AS ReserveAsReceived,
		|		0 AS SnoozeReservation,
		|		0 AS ToSupply,
		|		0 AS NotProvide,
		|		CASE
		|			WHEN Table.InventoryState IN(
		|					VALUE(Enum.InventoryStates.AvailablePendingUnlocking),
		|					VALUE(Enum.InventoryStates.AvailableNotSubjectToUnlocking))
		|				THEN Table.Count
		|			ELSE 0
		|		END AS LockedInStock,
		|		CASE
		|			WHEN Table.InventoryState IN(
		|					VALUE(Enum.InventoryStates.ExpectedForReceiptWithLock),
		|					VALUE(Enum.InventoryStates.ExpectedForReceiptNotSubjectToUnlocking))
		|				THEN Table.Count
		|			ELSE 0
		|		END AS LockedReceipt,
		|		0 AS ToUnlock,
		|		0 AS ReserveAtWarehouseFromLocked,
		|		0 AS ReserveUponReceiptFromLocked
		|	FROM
		|		InventoryAllocation AS Table
		|	WHERE
		|		Table.InventoryState IN(
		|			VALUE(Enum.InventoryStates.ExpectedForReceiptWithoutLock),
		|			VALUE(Enum.InventoryStates.PendingSupplyApproval),
		|			VALUE(Enum.InventoryStates.AvailablePendingUnlocking),
		|			VALUE(Enum.InventoryStates.AvailableNotSubjectToUnlocking),
		|			VALUE(Enum.InventoryStates.ExpectedForReceiptWithLock),
		|			VALUE(Enum.InventoryStates.ExpectedForReceiptNotSubjectToUnlocking))
		|	
		|	UNION ALL
		|	
		// Controlled Lot references to unlock.
		|	SELECT
		|		Table.Products AS Products,
		|		Table.Characteristic AS Characteristic,
		|		Table.Warehouse AS Warehouse,
		|		Table.Purpose AS Purpose,
		|		Table.ReceiptOrder AS OrderDocument,
		|		Table.AvailabilityDate AS EventDate,
		|		0 AS InStock,
		|		0 AS Received_1,
		|		0 AS Ordered,
		|		0 AS ReserveAtWarehouse,
		|		0 AS ReserveAsReceived,
		|		0 AS SnoozeReservation,
		|		0 AS ToSupply,
		|		0 AS NotProvide,
		|		0 AS LockedInStock,
		|		0 AS LockedReceipt,
		|		Table.Count AS ToUnlock,
		|		0 AS ReserveAtWarehouseFromLocked,
		|		0 AS ReserveUponReceiptFromLocked
		|	FROM
		|		InventoryAllocation AS Table
		|	WHERE
		|		Table.InventoryState IN(
		|			VALUE(Enum.InventoryStates.AvailablePendingUnlocking),
		|			VALUE(Enum.InventoryStates.ExpectedForReceiptWithLock))
		|	
		|	UNION ALL
		|	
		// Order requirements.
		|	SELECT
		|		Table.Products AS Products,
		|		Table.Characteristic AS Characteristic,
		|		Table.Warehouse AS Warehouse,
		|		Table.Purpose AS Purpose,
		|		Table.ShipmentOrder AS OrderDocument,
		|		Table.RequestShipmentOn AS EventDate,
		|		0 AS InStock,
		|		0 AS Received_1,
		|		0 AS Ordered,
		|		CASE
		|			WHEN
		|				Table.DemandCharacteristic = VALUE(Enum.DemandCharacteristics.ReserveAtWarehouse)
		|					THEN Table.Count
		|			ELSE 0
		|		END AS ReserveAtWarehouse,
		|		CASE
		|			WHEN
		|				Table.DemandCharacteristic = VALUE(Enum.DemandCharacteristics.ReserveAsReceived)
		|					THEN Table.Count
		|			ELSE 0
		|		END AS ReserveAsReceived,
		|		CASE
		|			WHEN
		|				Table.DemandCharacteristic = VALUE(Enum.DemandCharacteristics.SnoozeReservation)
		|					THEN Table.Count
		|			ELSE 0
		|		END AS SnoozeReservation,
		|		CASE
		|			WHEN
		|				Table.DemandCharacteristic = VALUE(Enum.DemandCharacteristics.ToSupply)
		|					THEN Table.Count
		|			ELSE 0
		|		END AS ToSupply,
		|		CASE
		|			WHEN
		|				Table.DemandCharacteristic = VALUE(Enum.DemandCharacteristics.NotProvide)
		|					THEN Table.Count
		|			ELSE 0
		|		END AS NotProvide,
		|		0 AS LockedInStock,
		|		0 AS LockedReceipt,
		|		0 AS ToUnlock,
		|		CASE
		|			WHEN
		|				Table.DemandCharacteristic = VALUE(Enum.DemandCharacteristics.ReserveAtWarehouseFromLocked)
		|					THEN Table.Count
		|			ELSE 0
		|		END AS ReserveAtWarehouseFromLocked,
		|		CASE
		|			WHEN
		|				Table.DemandCharacteristic = VALUE(Enum.DemandCharacteristics.ReserveUponReceiptFromLocked)
		|					THEN Table.Count
		|			ELSE 0
		|		END AS ReserveUponReceiptFromLocked
		|	FROM
		|		InventoryAllocation AS Table
		|	WHERE
		|		Table.DemandCharacteristic IN(
		|			VALUE(Enum.DemandCharacteristics.ReserveAtWarehouse),
		|			VALUE(Enum.DemandCharacteristics.ReserveAsReceived),
		|			VALUE(Enum.DemandCharacteristics.SnoozeReservation),
		|			VALUE(Enum.DemandCharacteristics.ToSupply),
		|			VALUE(Enum.DemandCharacteristics.NotProvide),
		|			VALUE(Enum.DemandCharacteristics.ReserveAtWarehouseFromLocked),
		|			VALUE(Enum.DemandCharacteristics.ReserveUponReceiptFromLocked))) AS Set
		|GROUP BY
		|	Set.Products,
		|	Set.Characteristic,
		|	Set.Warehouse,
		|	Set.Purpose,
		|	Set.OrderDocument,
		|	Set.EventDate
		|HAVING
		|	SUM(Set.InStock) <> 0
		|	OR SUM(Set.Received_1) <> 0
		|	OR SUM(Set.Ordered) <> 0
		|	OR SUM(Set.ReserveAtWarehouse) <> 0
		|	OR SUM(Set.ReserveAsReceived) <> 0
		|	OR SUM(Set.SnoozeReservation) <> 0
		|	OR SUM(Set.ToSupply) <> 0
		|	OR SUM(Set.NotProvide) <> 0
		|	OR SUM(Set.LockedInStock) <> 0
		|	OR SUM(Set.LockedReceipt) <> 0
		|	OR SUM(Set.ToUnlock) <> 0
		|	OR SUM(Set.ReserveAtWarehouseFromLocked) <> 0
		|	OR SUM(Set.ReserveUponReceiptFromLocked) <> 0
		|INDEX BY
		|	Products, Characteristic, Warehouse, Purpose, OrderDocument, EventDate
		|;
		|
		|/////////////////////////////////////////////////
		|SELECT DISTINCT
		|	Source.Products AS Products,
		|	Source.Characteristic AS Characteristic,
		|	Source.Warehouse AS Warehouse,
		|	Source.Purpose AS Purpose,
		|	UNDEFINED AS OrderDocument,
		|	0 AS InStockExpense,
		|	0 AS ReserveAtWarehouse,
		|	0 AS LockedInStockExpense,
		|	0 AS ReserveAtWarehouseFromLocked
		|INTO InventoryAndDemandsUpdate
		|FROM
		|	RegisterRecords AS Source
		|		
		|		LEFT JOIN InformationRecords AS Receiver
		|		ON Receiver.Products = Source.Products
		|		AND Receiver.Characteristic = Source.Characteristic
		|		AND Receiver.Warehouse = Source.Warehouse
		|		AND Receiver.Purpose = Source.Purpose
		|		AND Receiver.OrderDocument = Source.OrderDocument
		|		AND Receiver.EventDate = Source.EventDate
		|WHERE
		|	Source.InStock <> ISNULL(Receiver.InStock, 0)
		|	OR Source.Received_1 <> ISNULL(Receiver.Received_1, 0)
		|	OR Source.Ordered <> ISNULL(Receiver.Ordered, 0)
		|	OR Source.ReserveAtWarehouse <> ISNULL(Receiver.ReserveAtWarehouse, 0)
		|	OR Source.ReserveAsReceived <> ISNULL(Receiver.ReserveAsReceived, 0)
		|	OR Source.SnoozeReservation <> ISNULL(Receiver.SnoozeReservation, 0)
		|	OR Source.ToSupply <> ISNULL(Receiver.ToSupply, 0)
		|	OR Source.NotProvide <> ISNULL(Receiver.NotProvide, 0)
		|	OR Source.LockedInStock <> ISNULL(Receiver.LockedInStock, 0)
		|	OR Source.LockedReceipt <> ISNULL(Receiver.LockedReceipt, 0)
		|	OR Source.ToUnlock <> ISNULL(Receiver.ToUnlock, 0)
		|	OR Source.ReserveAtWarehouseFromLocked <> ISNULL(Receiver.ReserveAtWarehouseFromLocked, 0)
		|	OR Source.ReserveUponReceiptFromLocked <> ISNULL(Receiver.ReserveUponReceiptFromLocked, 0)
		|	
		|UNION
		|
		|SELECT DISTINCT
		|	Source.Products AS Products,
		|	Source.Characteristic AS Characteristic,
		|	Source.Warehouse AS Warehouse,
		|	Source.Purpose AS Purpose,
		|	UNDEFINED AS OrderDocument,
		|	0 AS InStockExpense,
		|	0 AS ReserveAtWarehouse,
		|	0 AS LockedInStockExpense,
		|	0 AS ReserveAtWarehouseFromLocked
		|FROM
		|	InformationRecords AS Receiver
		|		
		|		LEFT JOIN RegisterRecords AS Source
		|		ON Source.Products = Receiver.Products
		|		AND Source.Characteristic = Receiver.Characteristic
		|		AND Source.Warehouse = Receiver.Warehouse
		|		AND Source.Purpose = Receiver.Purpose
		|		AND Source.OrderDocument = Receiver.OrderDocument
		|		AND Source.EventDate = Receiver.EventDate
		|WHERE
		|	Source.Products IS NULL
		|	
		|UNION
		|
		// There may not be discrepancies, but there may be tasks for calculating the register of information that will introduce discrepancies.
		|SELECT DISTINCT
		|	Jobs.Products AS Products,
		|	Jobs.Characteristic AS Characteristic,
		|	Jobs.Warehouse AS Warehouse,
		|	Jobs.Purpose AS Purpose,
		|	UNDEFINED AS OrderDocument,
		|	0 AS InStockExpense,
		|	0 AS ReserveAtWarehouse,
		|	0 AS LockedInStockExpense,
		|	0 AS ReserveAtWarehouseFromLocked
		|FROM
		|	MeasurementTable AS Table
		|		
		|		INNER JOIN InformationRegister.JobsForAllocatingInventory AS Jobs
		|		ON Jobs.Products = Table.Products
		|		 AND Jobs.Characteristic = Table.Characteristic
		|		 AND Jobs.Warehouse = Table.Warehouse
		|		 AND Jobs.Purpose = Table.Purpose
		|		
		|INDEX BY
		|	Products, Characteristic, Warehouse, Purpose";
		
	SetPrivilegedMode(True);
	Query.Execute();
	DocumentEmulation = DocumentsPosting.DocumentEmulation(Undefined, Undefined);
	StockAllocationRecords.ReflectInventoryAllocationTasks(DocumentEmulation, TempTablesManager);
	DocumentEmulation = DocumentsPosting.DocumentEmulation(Documents.RegisterAdjustment.EmptyRef(), Undefined); // need a link to the order, for the mechanism of States of customer orders
	If Not InventoryAllocation.CountRegisterWithRoutineTask() Then
		DocumentsStates.ReflectDocumentStates(DocumentEmulation, TempTablesManager);
		OrderStructureDocumentPosting.CreateTasksForCalculatingStructureOfOrderDistributionOfInventoryWhenWritingDocument(DocumentEmulation, TempTablesManager);
	EndIf;
	CheckToRunBackgroundInventoryAllocationJob();
	
EndProcedure

Procedure DiscountsSurchargesReplaceBalanceInWarehouseRedefinable(QueryText) Export
	
	If StrFind(QueryText, "CalculationOfBalancesForSettingActions") = 0 Then
		Return;
	EndIf;
	
	TablesNames = NewTableNamesForCalculatingBalancesForSettingActions();
	TablesNames.Balance = "InventoryAndDemandsBalance"; // @query-part-1
	TablesNames.Result = "CalculationOfBalancesForSettingActions"; // @query-part-1
	CalculationOfBalancesForSettingActions(QueryText, TablesNames);
	
EndProcedure

Function FreeBalancesForProductSelection(Goods, TablePickedUpEarlier, Warehouses, Purpose, Department, ControlledLotReference) Export
	
	// Getting the leftovers.
	Query = New Query();
	Query.SetParameter("Goods", Goods);
	Query.SetParameter("TablePickedUpEarlier", TablePickedUpEarlier);
	Query.SetParameter("Purpose", Purpose);
	Query.SetParameter("Department", Department);
	Query.SetParameter("ControlledLotReference", ControlledLotReference);
	
	Query.Text =
		"SELECT
		|	Goods.Products AS Products,
		|	Goods.Characteristic AS Characteristic
		|INTO Goods
		|FROM
		|	&Goods AS Goods
		|;
		|
		|///////////////////////////////////////
		|SELECT
		|	Goods.Products AS Products,
		|	Goods.Characteristic AS Characteristic,
		|	FALSE AS WithAssignment,
		|	VALUE(Catalog.Assignments.EmptyRef) AS Purpose
		|INTO SelectedProductItems
		|FROM
		|	Goods AS Goods
		|WHERE
		|	Goods.Products.ItemsType IN(
		|		VALUE(Enum.ItemsTypes.OwnGoods),
		|		VALUE(Enum.ItemsTypes.ReusablePackage))
		|
		|UNION ALL
		|
		|SELECT
		|	Goods.Products AS Products,
		|	Goods.Characteristic AS Characteristic,
		|	TRUE AS WithAssignment,
		|	&Purpose AS Purpose
		|FROM
		|	Goods AS Goods
		|WHERE
		|	Goods.Products.ItemsType IN(
		|		VALUE(Enum.ItemsTypes.OwnGoods),
		|		VALUE(Enum.ItemsTypes.ReusablePackage))
		|
		|INDEX BY
		|	Products, Characteristic, Purpose
		|;
		|
		|///////////////////////////////////////
		|SELECT
		|	Goods.Products AS Products,
		|	Goods.Characteristic AS Characteristic,
		|	Goods.WithAssignment AS WithAssignment,
		|	Goods.Purpose AS Purpose,
		|	&ControlledLotReference AS ControlledLotReference,
		|	VALUE(Catalog.Warehouses.EmptyRef) AS Warehouse
		|INTO SelectedProductsBasedOnWarehouse
		|FROM
		|	SelectedProductItems AS Goods
		|INDEX BY
		|	Products, Characteristic, Warehouse, Purpose
		|;
		|
		|///////////////////////////////////////
		|SELECT
		|	Table.Products AS Products,
		|	Table.Characteristic AS Characteristic,
		|	CASE WHEN Table.Warehouse = VALUE(Catalog.Warehouses.EmptyRef) THEN
		|				&Department
		|			ELSE
		|				Table.Warehouse
		|		END AS Warehouse,
		|	CASE WHEN Table.WithAssignment THEN
		|				&Purpose
		|			ELSE
		|				VALUE(Catalog.Assignments.EmptyRef)
		|		END AS Purpose,
		|	&ControlledLotReference AS ControlledLotReference,
		|	CASE
		|		WHEN Table.SupplyOption IN(
		|				VALUE(Enum.SupplyOptions.Ship),
		|				VALUE(Enum.SupplyOptions.FromWarehouse))
		|			THEN Table.Count
		|		ELSE 0
		|	END AS InStock,
		|	Table.Count AS AvailableAndExpected
		|INTO TablePickedUpEarlier
		|FROM
		|	&TablePickedUpEarlier AS Table
		|WHERE
		|	Table.SupplyOption IN(
		|		VALUE(Enum.SupplyOptions.Ship),
		|		VALUE(Enum.SupplyOptions.FromWarehouse),
		|		VALUE(Enum.SupplyOptions.ReserveAsReceived))
		|;
		|
		|///////////////////////////////////////
		|SELECT
		|	Table.Products AS Products,
		|	Table.Characteristic AS Characteristic,
		|	Table.Warehouse AS Warehouse,
		|	Table.Purpose AS Purpose,
		|	Table.ControlledLotReference AS ControlledLotReference,
		|	-SUM(Table.InStock) AS InStock,
		|	-SUM(Table.AvailableAndExpected) AS AvailableAndExpected
		|INTO AdjustingBalance
		|FROM
		|	TablePickedUpEarlier AS Table
		|GROUP BY
		|	Table.Products,
		|	Table.Characteristic,
		|	Table.Warehouse,
		|	Table.Purpose,
		|	Table.ControlledLotReference
		|INDEX BY
		|	Products, Characteristic, Warehouse, Purpose, ControlledLotReference
		|;
		|
		|///////////////////////////////////////
		|SELECT
		|	NULL AS Products,
		|	NULL AS Characteristic,
		|	NULL AS Warehouse,
		|	NULL AS Purpose,
		|	NULL AS ShipmentOrder
		|INTO SelectedOrders_
		|WHERE
		|	FALSE";
	
	Query.TempTablesManager = New TempTablesManager;
	Query.Execute();
	
	WarehouseAndScheduleLeftovers = LeftoversForSelectingWarehouses(Query, Warehouses, 1);
	Return WarehouseAndScheduleLeftovers;
	
EndFunction

Function FillInCollateralFromCollateralStateForm(ActionCode, AddressAnalyst, Form) Export
	
	SupplyOption = Undefined;
	If ActionCode = "ACTION_SHIP_SUPPLIED" Or ActionCode = "ACTION_SHIP_AVAILABLE" Then
		SupplyOption = Enums.SupplyOptions.Ship;
	ElsIf ActionCode = "ACTION_RESERVATION_RESERVED" Then
		SupplyOption = Enums.SupplyOptions.FromWarehouse;
	ElsIf ActionCode = "ACTION_NOTABLE" Then
		SupplyOption = Enums.SupplyOptions.NotRequired;
	EndIf;
	
	// Initialization of parameters and query text, obtaining a temporary document data table for the reflection operation and a temporary reflection table.
	EmbeddingParameters = Form.AvailableRemainingEmbeddingOptions;
	Tables = GetFromTempStorage(EmbeddingParameters.InternalParameters.AddressOfFormDataTable);
	FillInTablesFromFormData(Tables, Form);
	
	Query = New Query();
	Query.TempTablesManager = New TempTablesManager();
	AddTemporaryDocumentDataTable(Query.TempTablesManager, Tables, EmbeddingParameters);
	
	AnalystTable = GetFromTempStorage(AddressAnalyst);
	For Each String In AnalystTable Do
		If TypeOf(String.Action) = Type("String") Then
			String.Action = "";
		EndIf;
	EndDo;
	
	AnalystTable.Columns.Add("ControlledLotReference", New TypeDescription("CatalogRef.ControlledLots"));
	ReserveFromBlocked = Enums.DemandCharacteristics.ReserveUponReceiptFromLocked;
	ReserveAsManyOfBlocked = Enums.DemandCharacteristics.ReserveUponReceiptFromLocked;
	For Each String In AnalystTable Do
		If String.DemandCharacteristic = ReserveFromBlocked
				Or String.DemandCharacteristic = ReserveAsManyOfBlocked Then
			String.ControlledLotReference = String.ShipmentOrder;
		EndIf;
	EndDo;
	KeyColumns_ = "ShipmentOrder,RequestShipmentOn,Products,Characteristic,Warehouse,Purpose,Action,ControlledLotReference,WithAssignment";
	AnalystTable.GroupBy(KeyColumns_, "Count");
	AnalystTable.Indexes.Add(KeyColumns_);
	AnalystSearchStructure = New Structure(KeyColumns_);
	
	Query.SetParameter("AnalystTable", AnalystTable);
	Query.Text =
		"SELECT
		|	AnalystTable.ShipmentOrder AS ShipmentOrder,
		|	AnalystTable.RequestShipmentOn AS RequestShipmentOn,
		|	AnalystTable.Products AS Products,
		|	AnalystTable.Characteristic AS Characteristic,
		|	AnalystTable.Warehouse AS Warehouse,
		|	AnalystTable.Purpose AS Purpose,
		|	AnalystTable.Action AS Action,
		|	AnalystTable.ControlledLotReference AS ControlledLotReference,
		|	AnalystTable.WithAssignment AS WithAssignment,
		|	AnalystTable.Count AS Count
		|INTO AnalystTable
		|FROM
		|	&AnalystTable AS AnalystTable
		|INDEX BY
		|	ShipmentOrder,RequestShipmentOn,Products,Characteristic,Warehouse,Purpose,WithAssignment
		|;
		|
		|/////////////////////////////////////////////////////////////
		|SELECT
		|	DocumentDataTable.GroupOfWarehouses AS GroupOfWarehouses,
		|	DocumentDataTable.Products AS Products,
		|	DocumentDataTable.Characteristic AS Characteristic,
		|	DocumentDataTable.Department AS Department,
		|	DocumentDataTable.Warehouse AS Warehouse,
		|	DocumentDataTable.Purpose AS Purpose,
		|	DocumentDataTable.ControlledLotReference AS ControlledLotReference,
		|	DocumentDataTable.ShipmentOrder AS ShipmentOrder,
		|	DocumentDataTable.DocumentDate AS DocumentDate,
		|	DocumentDataTable.SupplyOption AS SupplyOption,
		|	DocumentDataTable.WithAssignment AS WithAssignment,
		|	DocumentDataTable.Count AS Count,
		|	DocumentDataTable.NumberOfPackages AS NumberOfPackages,
		|	DocumentDataTable.Package AS Package,
		|	DocumentDataTable.ReadyForSupply AS ReadyForSupply,
		|	DocumentDataTable.ReadyToShip AS ReadyToShip,
		|	DocumentDataTable.RequestShipmentOn AS RequestShipmentOn,
		|	DocumentDataTable.Recorder AS Recorder,
		|	DocumentDataTable.Series AS Series,
		|	DocumentDataTable.RowCode AS RowCode,
		|	DocumentDataTable.Canceled AS Canceled,
		|	DocumentDataTable.LineNumber AS CollectionItem,
		|	DocumentDataTable.Priority AS Priority,
		|	DocumentDataTable.TheShipmentDateOfAllLinesIsASingleDate AS TheShipmentDateOfAllLinesIsASingleDate
		|INTO TemporaryDocumentDataTableForSelectedRows
		|FROM
		|	TemporaryDocumentDataTable AS DocumentDataTable
		|WHERE
		|	NOT DocumentDataTable.Canceled
		|		AND TRUE IN(
		|			SELECT TOP 1
		|				TRUE AS ThereAreRecords
		|			FROM
		|				AnalystTable AS AnalystTable
		|			WHERE
		|				AnalystTable.ShipmentOrder = DocumentDataTable.ShipmentOrder
		|				AND AnalystTable.RequestShipmentOn = DocumentDataTable.RequestShipmentOn
		|				AND AnalystTable.Products = DocumentDataTable.Products
		|				AND AnalystTable.Characteristic = DocumentDataTable.Characteristic
		|				AND AnalystTable.Warehouse =
		|					CASE
		|						WHEN CAST(DocumentDataTable.Products AS Catalog.Products).ItemsType = VALUE(Enum.ItemsTypes.Work_5)
		|							THEN DocumentDataTable.Department
		|						ELSE DocumentDataTable.Warehouse
		|					END
		|				AND AnalystTable.Purpose =
		|					CASE
		|						WHEN DocumentDataTable.WithAssignment
		|							THEN DocumentDataTable.Purpose
		|						ELSE VALUE(Catalog.Assignments.EmptyRef)
		|					END
		|				AND AnalystTable.ControlledLotReference = DocumentDataTable.ControlledLotReference
		|				AND AnalystTable.Action = DocumentDataTable.SupplyOption
		|				AND AnalystTable.WithAssignment = DocumentDataTable.WithAssignment)
		|;
		|
		|/////////////////////////////////////////////////////////////
		|SELECT
		|	Table.Package AS Package,
		|	Table.CollectionItem AS CollectionItem,
		|	Table.ShipmentOrder AS ShipmentOrder,
		|	Table.RequestShipmentOn AS RequestShipmentOn,
		|	Table.Products AS Products,
		|	Table.Products.ItemsType AS ItemsType,
		|	Table.Characteristic AS Characteristic,
		|	CASE
		|		WHEN CAST(Table.Products AS Catalog.Products).ItemsType = VALUE(Enum.ItemsTypes.Work_5)
		|			THEN Table.Department
		|		ELSE Table.Warehouse
		|	END AS Warehouse,
		|	CASE
		|		WHEN Table.WithAssignment
		|			THEN Table.Purpose
		|		ELSE VALUE(Catalog.Assignments.EmptyRef)
		|	END AS Purpose,
		|	Table.ControlledLotReference AS ControlledLotReference,
		|	Table.WithAssignment AS WithAssignment,
		|	Table.SupplyOption AS Action,
		|	NOT CAST(Table.Products AS Catalog.Products).ItemsType = VALUE(Enum.ItemsTypes.Work_5)
		|		AND (Table.Warehouse = VALUE(Catalog.Warehouses.EmptyRef)
		|				OR ISNULL(SettingUpCharacteristic.AvailableStockControl,
		|					ISNULL(SettingUpProducts.AvailableStockControl,
		|					ISNULL(SettingUpWarehouse.AvailableStockControl, FALSE)))) AS AvailableStockControl
		|FROM
		|	TemporaryDocumentDataTableForSelectedRows AS Table
		|		
		|		LEFT JOIN InformationRegister.SetUpSupplyControl AS SettingUpCharacteristic
		|		ON SettingUpCharacteristic.Warehouse = Table.Warehouse
		|		 AND SettingUpCharacteristic.Products = Table.Products
		|		 AND SettingUpCharacteristic.Characteristic = Table.Characteristic
		|		
		|		LEFT JOIN InformationRegister.SetUpSupplyControl AS SettingUpProducts
		|		ON SettingUpProducts.Warehouse = Table.Warehouse
		|		 AND SettingUpProducts.Products = Table.Products
		|		 AND SettingUpProducts.Characteristic = VALUE(Catalog.ItemsCharacteristics.EmptyRef)
		|		 AND SettingUpCharacteristic.Warehouse IS NULL
		|		
		|		LEFT JOIN InformationRegister.SetUpSupplyControl AS SettingUpWarehouse
		|		ON SettingUpWarehouse.Warehouse = Table.Warehouse
		|		 AND SettingUpWarehouse.Products = VALUE(Catalog.Products.EmptyRef)
		|		 AND SettingUpWarehouse.Characteristic = VALUE(Catalog.ItemsCharacteristics.EmptyRef)
		|		 AND SettingUpCharacteristic.Warehouse IS NULL
		|		 AND SettingUpProducts.Warehouse IS NULL
		|ORDER BY
		|	CollectionItem";
	
	Table = Query.Execute().Unload();
	
	If ActionCode = "ACTION_SHIP_AVAILABLE" Then
		
		GroupWarehouses_ = GroupWarehouses_(Query);
		
		CorrectionOfRegisteredRecords = ?(EmbeddingParameters.AddressOfMotionCorrection = Undefined,
			Undefined,
			GetFromTempStorage(Form[EmbeddingParameters.AddressOfMotionCorrection]));
		TableDecorated = NewTableIsDecorated();
		
		ArrayOfTexts = New Array();
		Text = TemporaryTableOfDocumentRegisteredRecords();
		ArrayOfTexts.Add(Text);
		Text = StrReplace(Text, "TemporaryDocumentDataTable", "TemporaryDocumentDataTableForSelectedRows");
		Text = StrReplace(Text, "TemporaryTableOfDocumentRegisteredRecords", "TemporaryTableOfDocumentRegisteredRecordsForSelectedRows");
		ArrayOfTexts.Add(Text);
		Query.Text = StrConcat(ArrayOfTexts, Common.QueryBatchSeparator());
		Query.SetParameter("Ref", Undefined);
		Query.SetParameter("NewDestinationLink", Catalogs.Assignments.GetRef());
		Query.Execute();
		
		AddTemporaryTablesToGetBalances(
			Query,
			False,
			CorrectionOfRegisteredRecords,
			False,
			Not SessionParameters.PostWithoutControlOfGoodsReservesUnderOrders);
		
		WarehouseRemnants = LeftoversForSettingActions(Query, GroupWarehouses_);
		SearchFields = "Products,Characteristic,Warehouse,Purpose,ControlledLotReference";
		SearchFieldsWithoutWarehouse = "Products,Characteristic,Purpose,ControlledLotReference";
		RemainderSearchStructure = New Structure(SearchFields);
		StructureOfFindingBalanceWithoutWarehouse = New Structure(SearchFieldsWithoutWarehouse);
		WarehouseRemnants.Indexes.Add(SearchFields);
		WarehouseRemnants.Indexes.Add(SearchFieldsWithoutWarehouse);
		
	EndIf;
	
	ChangesTable = New ValueTable();
	ChangesTable.Columns.Add("NumberOfPackages");
	ChangesTable.Columns.Add("SupplyOption");
	ChangesTable.Columns.Add("Series");
	ChangesTable.Columns.Add("Warehouse");
	ChangesTable.Columns.Add("Id");
	ChangesTable.Columns.Add("String");
	ChangesTable.Columns.Add("IsNewLine", New TypeDescription("Boolean"));
	
	CollectionOnForm = ProvisionInDocumentsClientServer.CollectionOnForm(Form, Form.AvailableRemainingEmbeddingOptions);
	PackingFactors = PackingFactors(Table, CollectionOnForm);
	For IndexOf = 0 To Table.Count() - 1 Do
		
		TableRow = Table[IndexOf];
		
		RowID = TableRow.CollectionItem;
		ZoomRatio = PackingFactors.Get(RowID);
		ZoomRatio = ?(ZoomRatio = Undefined, 1, ZoomRatio);
		
		If ActionCode = "ACTION_SHIP_AVAILABLE" Then
			
			CurSearchStructure = Undefined;
			If Not ValueIsFilled(TableRow.Warehouse)
					And (TableRow.ItemsType = Enums.ItemsTypes.OwnGoods
						Or TableRow.ItemsType = Enums.ItemsTypes.ReusablePackage) Then
				CurSearchStructure = StructureOfFindingBalanceWithoutWarehouse;
			Else
				CurSearchStructure = RemainderSearchStructure;
			EndIf;
			FillPropertyValues(CurSearchStructure, TableRow);
			FoundRemainderRows = WarehouseRemnants.FindRows(CurSearchStructure);
			KeyBalance = 0;
			For Each BalanceLineFound In FoundRemainderRows Do
				KeyBalance = KeyBalance + BalanceLineFound.Count;
			EndDo;
			
		EndIf;
		
		String = CollectionOnForm.FindByID(TableRow.CollectionItem);
		
		FillPropertyValues(AnalystSearchStructure, TableRow);
		DimensionsStrings = AnalystTable.FindRows(AnalystSearchStructure);
		If TableRow.Action = Enums.SupplyOptions.ReserveAsReceived
				Or TableRow.Action = Enums.SupplyOptions.ToSupply Then
			AnalystSearchStructure.Action = "";
			CommonClientServer.SupplementArray(DimensionsStrings, AnalystTable.FindRows(AnalystSearchStructure));
		EndIf;
		
		QuantityChangeTotal = 0;
		For Each AnalyticsLine_ In DimensionsStrings Do
			QuantityChangeTotal = QuantityChangeTotal + AnalyticsLine_.Count;
		EndDo;
		
		WasReserved = String.SupplyOption = Enums.SupplyOptions.Ship
			Or String.SupplyOption = Enums.SupplyOptions.FromWarehouse;
		
		NeedToReserve = ActionCode = "ACTION_SHIP_AVAILABLE";
		
		FillingByBalances = Not WasReserved
			And NeedToReserve
			And TableRow.AvailableStockControl;
		
		If FillingByBalances Then
			QuantityChangeTotal = Min(QuantityChangeTotal, KeyBalance);
		EndIf;
		
		If Not FillingByBalances Then
			
			If String.Count <= QuantityChangeTotal Then // for dimensional units of measurement, rounding of the quantity is possible
				NumberOfPackagesEditTotal = String.NumberOfPackages;
			Else
				NumberOfPackagesEditTotal = QuantityChangeTotal / ZoomRatio;
			EndIf;
			
			NumberOfPackages = Min(NumberOfPackagesEditTotal, String.NumberOfPackages);
				
			If NumberOfPackages = String.NumberOfPackages Then
				
				AddedRow = ChangesTable.Add();
				FillPropertyValues(AddedRow, String);
				AddedRow.SupplyOption = SupplyOption;
				AddedRow.Id = RowID;
				
			ElsIf NumberOfPackages > 0 Then
				
				AddedRow = ChangesTable.Add();
				FillPropertyValues(AddedRow, String);
				AddedRow.NumberOfPackages = AddedRow.NumberOfPackages - NumberOfPackages;
				AddedRow.Id = RowID;
				
				AddedRow = ChangesTable.Add();
				FillPropertyValues(AddedRow, String);
				AddedRow.SupplyOption = SupplyOption;
				AddedRow.NumberOfPackages = NumberOfPackages;
				AddedRow.Id = RowID;
				AddedRow.IsNewLine = True;
				
			EndIf;
			
			QuantityChangedTotal = NumberOfPackages * ZoomRatio;
			
		Else
			
			QuantityChangedTotal = 0;
			For BalanceIndex = 0 To FoundRemainderRows.Count() - 1 Do
				
				RemainderLine = FoundRemainderRows[BalanceIndex];
				QuantityChange = Min(QuantityChangeTotal, RemainderLine.Count);
				
				If String.Count <= QuantityChange Then // for dimensional units of measurement, rounding of the quantity is possible
					NumberOfPackagesEditTotal = String.NumberOfPackages;
					QuantityChange = String.Count;
				Else
					NumberOfPackagesEditTotal = QuantityChange / ZoomRatio;
				EndIf;
				
				NumberOfPackages = Min(NumberOfPackagesEditTotal, String.NumberOfPackages);
				
				QuantityChangeTotal = QuantityChangeTotal - QuantityChange;
				RemainderLine.Count = RemainderLine.Count - QuantityChange;
				
				If NumberOfPackages = String.NumberOfPackages Then
					
					AddedRow = ChangesTable.Add();
					FillPropertyValues(AddedRow, String);
					AddedRow.SupplyOption = SupplyOption;
					AddedRow.Warehouse = RemainderLine.Warehouse;
					AddedRow.Id = RowID;
					
				ElsIf NumberOfPackages > 0 Then
					
					AddedRow = ChangesTable.Add();
					FillPropertyValues(AddedRow, String);
					AddedRow.NumberOfPackages = AddedRow.NumberOfPackages - NumberOfPackages;
					AddedRow.Id = RowID;
					
					AddedRow = ChangesTable.Add();
					FillPropertyValues(AddedRow, String);
					AddedRow.SupplyOption = SupplyOption;
					AddedRow.Warehouse = RemainderLine.Warehouse;
					AddedRow.NumberOfPackages = NumberOfPackages;
					AddedRow.Id = RowID;
					AddedRow.IsNewLine = True;
					
				EndIf;
				QuantityChangedTotal = QuantityChangedTotal + NumberOfPackages * ZoomRatio;
				
			EndDo;
			
		EndIf;
		
		For DimensionIndex = 0 To DimensionsStrings.Count() - 1 Do
			AnalyticsLine_ = DimensionsStrings[DimensionIndex];
			QuantityChange = Min(QuantityChangedTotal, AnalyticsLine_.Count);
			QuantityChangedTotal = QuantityChangedTotal - QuantityChange;
			AnalyticsLine_.Count = AnalyticsLine_.Count - QuantityChange;
		EndDo;
		
	EndDo;
	
	SetActionsFromTable(Form, ChangesTable);
	Return ChangesTable;
	
EndFunction

Procedure BatchProcessingToSupplementDataSourceOfSoftwareInDocuments(StructureOfActions, QueryDetails, CachedValues) Export
	
	Var ObjectData;
	
	QueryOptions = QueryDetails.QueryOptions; // Structure
	QueriesTexts = QueryDetails.QueriesTexts; // ValueList
	ActionParameters = Undefined;
	
	If BatchProcessingOfTablePartServer.YouNeedToPerformAction(
		"CheckSoftwareInSalesDocument,WhenChangingTypeOfProductOrSoftwareOption,FillInAvailableColumn",
		StructureOfActions,
		CachedValues,
		ActionParameters) Then
	
		EmbeddingParameters = ActionParameters.EmbeddingParameters;
		Tables = GetFromTempStorage(EmbeddingParameters.InternalParameters.AddressOfFormDataTable);
		If ActionParameters.Property("ProgramObjectData", ObjectData) Then // call from the client for 1 line
			PopulateTablesFromSerializedObject(Tables, ObjectData, EmbeddingParameters, New Structure);
		ElsIf TypeOf(ActionParameters.Form) = Type("ClientApplicationForm") Then // Calling From The Form
			FillInTablesFromFormData(Tables, ActionParameters.Form, True);
		Else // Calling From An Object
			FillInTablesFromObject(Tables, ActionParameters.Form, True, ActionParameters.EmbeddingParameters);
		EndIf;
		
		NameOfTableBeingProcessed = Undefined;
		
		For Each Item In Tables Do
			
			If Item.Value.TableNameInQuery = EmbeddingParameters.TableName
					Or EmbeddingParameters.TableName = Undefined // header, disassembly order
						And Item.Value.TableNameInQuery = EmbeddingParameters.ObjectName Then
				NameOfTableBeingProcessed = Item.Value.TempTableName;
			Else
				QueryOptions.Insert(Item.Value.TempTableName, Item.Value.Table);
			EndIf;
			
		EndDo;
		LinkID = New UUID("9e1b1ca8-ce19-46d8-a7ef-0292f4cd9799");
		QueryOptions.Insert("NonExistentAssignment", Catalogs.Assignments.GetRef(LinkID));
		
		QueryTextTempTableOfDocumentDataBatchProcessing(
			EmbeddingParameters,
			Tables,
			QueriesTexts,
			NameOfTableBeingProcessed);
		
		QueryText =
			"SELECT
			|	DocumentTable.LineNumber AS IdOfTTRow,
			// FillInAvailableColumn
			|	DocumentTable.Products AS Products,
			|	DocumentTable.Characteristic AS Characteristic,
			|	DocumentTable.Warehouse AS Warehouse,
			|	DocumentTable.Department AS Department,
			|	CASE
			|		WHEN
			|			CAST(DocumentTable.Products AS Catalog.Products).ItemsType IN(
			|				VALUE(Enum.ItemsTypes.OwnGoods),
			|				VALUE(Enum.ItemsTypes.ReusablePackage))
			|			THEN
			|				DocumentTable.Warehouse
			|		ELSE DocumentTable.Department
			|	END AS WarehouseOrDepartment,
			|	CASE
			|		WHEN NOT DocumentTable.WithAssignment
			|			THEN VALUE(Catalog.Assignments.EmptyRef)
			|		WHEN DocumentTable.Purpose = VALUE(Catalog.Assignments.EmptyRef)
						// so that free balances are not selected if the destination for the document is not yet in the database.
			|			THEN &NonExistentAssignment
			|		ELSE DocumentTable.Purpose
			|	END AS Purpose,
			|	DocumentTable.ControlledLotReference AS ControlledLotReference,
			|	DocumentTable.ShipmentOrder AS ShipmentOrder,
			|	DocumentTable.WithAssignment AS WithAssignment,
			|	DocumentTable.Package AS Package,
			|	DocumentTable.Recorder AS Recorder,
			// CheckSoftwareInSalesDocument
			|	CAST(DocumentTable.Products AS Catalog.Products).ItemsType AS ItemsType,
			|	CAST(DocumentTable.Products AS Catalog.Products).AssignedPurchaseSale AS AssignedPurchaseSale,
			// WhenChangingTypeOfProductOrSoftwareOption
			|	CASE
			|		WHEN NOT DocumentTable.Canceled
			|				AND CAST(DocumentTable.Products AS Catalog.Products).ItemsType IN(
			|					VALUE(Enum.ItemsTypes.OwnGoods),
			|					VALUE(Enum.ItemsTypes.ReusablePackage))
			|				AND (DocumentTable.SupplyOption IN(
			|						VALUE(Enum.SupplyOptions.Ship),
			|						VALUE(Enum.SupplyOptions.FromWarehouse))
			|					OR DocumentTable.SupplyOption IN(
			|									VALUE(Enum.SupplyOptions.ReserveAsReceived),
			|									VALUE(Enum.SupplyOptions.ToSupply))
			|						AND DocumentTable.ReadyForSupply)
			|			THEN 1
			|		ELSE 0
			|	END AS WarehouseIsRequired,
			|	CASE
			|		WHEN NOT DocumentTable.Canceled
			|				AND DocumentTable.SupplyOption = VALUE(Enum.SupplyOptions.Ship)
			|				AND DocumentTable.ReadyToShip
			|			THEN 1
			|		ELSE 0
			|	END AS DateOfShipmentRequired_
			|FROM
			|	TemporaryDocumentDataTable AS DocumentTable";
		QueriesTexts.Add(QueryText, "ProvisionInDocuments");
		
	EndIf;
	
EndProcedure

// The event handler for the batch processing of the table part of the server.Check to fill in the support of the Sales document line.
// Event for processing table parts:
//  - "Check to fill in the support of the documentation"
Procedure CheckSoftwareInTSLineOfSalesDocument(CurrentRow, ProgramObjectData, ActionParameters) Export
	
	EmbeddingParameters = ActionParameters.EmbeddingParameters;
	Tables = GetFromTempStorage(EmbeddingParameters.InternalParameters.AddressOfFormDataTable);
	PopulateTablesFromSerializedObject(Tables, ProgramObjectData, EmbeddingParameters, CurrentRow);
	
	TempTablesManager = New TempTablesManager();
	AddTemporaryDocumentDataTable(TempTablesManager, Tables, EmbeddingParameters);
	
	Query = New Query();
	Query.TempTablesManager = TempTablesManager;
	Query.Text =
		"SELECT
		|	DocumentTable.Products                            AS Products,
		|	DocumentTable.Products.ItemsType            AS ItemsType,
		|	DocumentTable.Products.AssignedPurchaseSale AS AssignedPurchaseSale,
		|	DocumentTable.SupplyOption                      AS SupplyOption
		|FROM
		|	TemporaryDocumentDataTable AS DocumentTable";
	Selection = Query.Execute().Select();
	Selection.Next();
	
	If Not ValueIsFilled(Selection.Products) Then
		Return;
	EndIf;
	
	If Selection.ItemsType = PredefinedValue("Enum.ItemsTypes.OwnGoods") Then
		PropertyName = "OwnGoods";
	ElsIf Selection.ItemsType = PredefinedValue("Enum.ItemsTypes.Work_5") Then
		PropertyName = "Work_5";
	ElsIf Selection.ItemsType = PredefinedValue("Enum.ItemsTypes.OperationService") Then
		PropertyName = "OperationService";
	ElsIf Selection.ItemsType = PredefinedValue("Enum.ItemsTypes.ReusablePackage") Then
		PropertyName = "Tara";
	EndIf;
	
	// Filling in the security option.
	SecurityOptionAndFlagSeparately = ActionParameters.SecurityOptionAndFlagSeparately;
	
	If SecurityOptionAndFlagSeparately = Undefined Then
		
		OptionAndFlagAreTemporary = ProvisionInDocumentsClientServer.ProvisionOptionAndFlagAreSeparateByDefault(
			Selection.AssignedPurchaseSale);
		
		SupplyOption = OptionAndFlagAreTemporary[PropertyName].SupplyOption;
		WithAssignment = OptionAndFlagAreTemporary[PropertyName].WithAssignment;
		
	ElsIf SecurityOptionAndFlagSeparately[PropertyName].WithAssignment = Undefined Then // the case when the provision option is overridden and the flag is not.
		
		OptionAndFlagAreTemporary = ProvisionInDocumentsClientServer.ProvisionOptionAndFlagAreSeparateByDefault(
			Selection.AssignedPurchaseSale);
		SupplyOption = SecurityOptionAndFlagSeparately[PropertyName].SupplyOption;
		WithAssignment = OptionAndFlagAreTemporary[PropertyName].WithAssignment;
		If PropertyName = "Work_5" Then
			If WithAssignment And SupplyOption = PredefinedValue("Enum.SupplyOptions.NotRequired") Then
				SupplyOption = PredefinedValue("Enum.SupplyOptions.ToSupply")
			ElsIf Not WithAssignment And SupplyOption = PredefinedValue("Enum.SupplyOptions.ToSupply") Then
				SupplyOption = PredefinedValue("Enum.SupplyOptions.NotRequired");
			EndIf;
		EndIf;
		
	Else
		
		SupplyOption = SecurityOptionAndFlagSeparately[PropertyName].SupplyOption;
		WithAssignment = SecurityOptionAndFlagSeparately[PropertyName].WithAssignment;
		
	EndIf;
	
	CurrentRow.SupplyOption = SupplyOption;
	CurrentRow.WithAssignment        = WithAssignment;
	
EndProcedure

// The event handler for the batch processing of the table part of the server.Filling in the column is not available.
// Event for processing table parts:
//  - "Fill in the column is not available"
Procedure FillInAvailableColumn(CurrentRow, ProgramObjectData, ActionParameters) Export
	
	EmbeddingParameters = ActionParameters.EmbeddingParameters;
	Tables = GetFromTempStorage(EmbeddingParameters.InternalParameters.AddressOfFormDataTable);
	PopulateTablesFromSerializedObject(Tables, ProgramObjectData, EmbeddingParameters, CurrentRow);
	
	TempTablesManager = New TempTablesManager();
	AddTemporaryDocumentDataTable(TempTablesManager, Tables, EmbeddingParameters);
	UpdateColumnIsAvailableWhenProcessingRowOfTablePart(CurrentRow, TempTablesManager, EmbeddingParameters);
	
EndProcedure

// The event handler for the batch processing of the table part of the server.When changing the type of nomenclature or support options.
// Event for processing table parts:
//  - "When changing the type of nomenclature or support options"
Procedure WhenChangingTypeOfProductOrSoftwareOption(CurrentRow, ProgramObjectData, ActionParameters) Export
	
	EmbeddingParameters = ActionParameters.EmbeddingParameters;
	Tables = GetFromTempStorage(EmbeddingParameters.InternalParameters.AddressOfFormDataTable);
	PopulateTablesFromSerializedObject(Tables, ProgramObjectData, EmbeddingParameters, CurrentRow);
	
	Query = New Query();
	Query.TempTablesManager = New TempTablesManager();
	AddTemporaryDocumentDataTable(Query.TempTablesManager, Tables, EmbeddingParameters);
	
	Query.SetParameter("OnlyErrors", False);
	MandatoryTable = MandatoryTableForTemporaryDocumentDataTable(Query);
	
	CurrentRow.DateOfShipmentRequired_ = ?(MandatoryTable[0].DateOfShipmentRequired_, 1, 0);
	CurrentRow.WarehouseIsRequired         = ?(MandatoryTable[0].WarehouseIsRequired, 1, 0);
	
EndProcedure

Procedure YouCanUpdateColumnWhenProcessingRowOfTablePartInBatches(CurrentRow, FillingData, ActionParameters) Export
	
	EmbeddingParameters = ActionParameters.EmbeddingParameters;
	KeyOrders = "Products,Characteristic,Warehouse,Purpose,ControlledLotReference,ShipmentOrder,Package";
	KeyProducts_ = "Products,Characteristic,Warehouse,Purpose,ControlledLotReference,Package";
	SelectingRowsByOrder = New Structure(KeyOrders);
	SelectingRowsByProduct = New Structure(KeyProducts_);
	FillPropertyValues(SelectingRowsByOrder, FillingData[0]);
	FillPropertyValues(SelectingRowsByProduct, FillingData[0]);
	SelectingRowsByOrder.Warehouse = FillingData[0].WarehouseOrDepartment;
	SelectingRowsByProduct.Warehouse = FillingData[0].WarehouseOrDepartment;
	
	Balance = GetFromTempStorage(EmbeddingParameters.AddressOfBalances);
	
	FoundRowsByOrder = Balance.ByOrder.FindRows(SelectingRowsByOrder);
	ProductLinesFound = Balance.ByProduct.FindRows(SelectingRowsByProduct);
	If FoundRowsByOrder.Count() = 0 Or ProductLinesFound.Count() = 0 Then
		
		TableManager = New TempTablesManager();
		
		Query = New Query(
		"SELECT
		|	0 AS LineNumber,
		|	Table.Recorder AS Recorder,
		|	Table.ShipmentOrder AS ShipmentOrder,
		|	Table.Products AS Products,
		|	Table.Characteristic AS Characteristic,
		|	Table.Package AS Package,
		|	Table.Warehouse AS Warehouse,
		|	Table.Department AS Department,
		|	Table.WithAssignment AS WithAssignment,
		|	Table.Purpose AS Purpose,
		|	Table.ControlledLotReference AS ControlledLotReference
		|INTO TemporaryDocumentDataTable
		|FROM
		|	&Table AS Table");
		Query.TempTablesManager = TableManager;
		// You need to take the first row, while saving the types of table values.
		Table = FillingData.Copy(CommonClientServer.ValueInArray(FillingData[0]));
		Query.SetParameter("Table", Table);
		Query.Execute();
		StructureOfResidues = BalancesForColumnAreAvailable(
			TableManager,
			Balance,
			Balance.ChangesToDocument);
		
		AddToTable(Balance.ByOrder, StructureOfResidues.OrderBalances_1, SelectingRowsByOrder);
		AddToTable(Balance.AdjustingOrders, StructureOfResidues.AdjustingOrders, SelectingRowsByOrder);
		AddToTable(Balance.ByProduct, StructureOfResidues.ProductBalances_, SelectingRowsByProduct);
		AddToTable(Balance.AdjustmentOfGoods, StructureOfResidues.AdjustmentOfGoods, SelectingRowsByProduct);
		
	EndIf;
	
	FoundRowsByOrder = Balance.ByOrder.FindRows(SelectingRowsByOrder);
	ProductLinesFound = Balance.ByProduct.FindRows(SelectingRowsByProduct);
	FoundRowsAdjustingOrders = Balance.AdjustingOrders.FindRows(SelectingRowsByOrder);
	FoundRowsAdjustmentOfProducts = Balance.AdjustmentOfGoods.FindRows(SelectingRowsByProduct);
	If ProductLinesFound.Count() > 0 Then // if there is no record-level access to the warehouse, there will be no row.
		
		CurrentRow.Available = ProductLinesFound[0].Count
			+ FoundRowsByOrder[0].Count
			+ FoundRowsAdjustingOrders[0].Count
			+ FoundRowsAdjustmentOfProducts[0].Count;
			
		CurrentRow.ReallocateInventory = ProductLinesFound[0].ReallocateWarehouseInventory;
		CurrentRow.ShipIfAvailable  = ProductLinesFound[0].ShipIfAvailable;
		
	EndIf;
	EmbeddingParameters.AddressOfBalances   = PutToTempStorage(Balance, EmbeddingParameters.AddressOfBalances);
	
	AvailableResiduesSupplementMatchingProducts(
		EmbeddingParameters,
		FillingData[0],
		ActionParameters.IDOfRowReceived);
	
EndProcedure

Procedure CheckNeedToUpdateColumnIsAvailable(String, ActionParameters) Export
	
	If ActionParameters.Property("IDOfRowReceived") Then
		IDOfRowReceived = ActionParameters.IDOfRowReceived; // Batch Processing
	Else
		IDOfRowReceived = String.IDOfRowReceived; // IsOutdated
	EndIf;
	
	Products = GetFromTempStorage(ActionParameters.AddressProductRange);
	HasChanges = True;
	
	Characteristic = Products.Get(String.Products);
	If Characteristic = Undefined Then
		Characteristic = New Map();
		Products.Insert(String.Products, Characteristic);
	EndIf;
	FoundItem = Characteristic.Get(String.Characteristic);
	If FoundItem = Undefined Then
		Characteristic.Insert(String.Characteristic, IDOfRowReceived);
	ElsIf FoundItem = True Or FoundItem <> IDOfRowReceived Then
		Characteristic.Insert(String.Characteristic, True);
		ActionParameters.UpdateColumnAvailable =
			String.SupplyOption = Enums.SupplyOptions.Ship
				Or String.SupplyOption = Enums.SupplyOptions.FromWarehouse;
	Else
		HasChanges = False;
	EndIf;
	
	If HasChanges Then
		PutToTempStorage(Products, ActionParameters.AddressProductRange);
	EndIf;
	
	CurRow = ActionParameters.CurLineCache_;
	Characteristic = Products.Get(CurRow.Products);
	If Characteristic <> Undefined Then
		FoundItem = Characteristic.Get(CurRow.Characteristic);
		If FoundItem = True Then
			ActionParameters.UpdateColumnAvailable =
				ActionParameters.UpdateColumnAvailable
					Or CurRow.SupplyOption = Enums.SupplyOptions.Ship
					Or CurRow.SupplyOption = Enums.SupplyOptions.FromWarehouse;
		EndIf;
	EndIf;
	
EndProcedure

Procedure UpdateProductCache_(String, ActionParameters) Export
	
	If ActionParameters.Property("IDOfRowReceived") Then
		IDOfRowReceived = ActionParameters.IDOfRowReceived; // Batch Processing
	Else
		IDOfRowReceived = String.IDOfRowReceived; // IsOutdated
	EndIf;
	Products = GetFromTempStorage(ActionParameters.AddressProductRange);
	HasChanges = True;
	
	Characteristic = Products.Get(String.Products);
	If Characteristic = Undefined Then
		Characteristic = New Map();
		Products.Insert(String.Products, Characteristic);
	EndIf;
	FoundItem = Characteristic.Get(String.Characteristic);
	If FoundItem = Undefined Then
		Characteristic.Insert(String.Characteristic, IDOfRowReceived);
	ElsIf FoundItem = True Or FoundItem <> IDOfRowReceived Then
		Characteristic.Insert(String.Characteristic, True);
	Else
		HasChanges = False;
	EndIf;
	
	If HasChanges Then
		PutToTempStorage(Products, ActionParameters.AddressProductRange);
	EndIf;
	
EndProcedure

// Checks whether there are inventory allocation tasks for at least one order of a specific document type.
//
// Parameters:
//  FullNamesOfDocuments - String - full names of documents displayed in a comma-separated list.
//
// Returns:
//  Array of AnyRef - orders of tasks from the inventory distribution task register
//
Function TasksForOrdersByType(FullNamesOfDocuments) Export
	
	DocumentNames = StrSplit(FullNamesOfDocuments, ",");
	Types = New Array();
	For Each DocumentName In DocumentNames Do
		ManagerOfDocument = Common.ObjectManagerByFullName(DocumentName);
		Types.Add(TypeOf(ManagerOfDocument.EmptyRef()));
	EndDo;
	Query = New Query();
	Query.SetParameter("Types", Types);
	Query.Text =
	"SELECT DISTINCT
	|	Jobs.ShipmentOrder AS Ref
	|FROM
	|	InformationRegister.JobsForAllocatingInventory AS Jobs
	|WHERE
	|	VALUETYPE(Jobs.ShipmentOrder) IN(&Types)";
	SetPrivilegedMode(True);
	Orders = Query.Execute().Unload().UnloadColumn("Ref");
	Return Orders;
	
EndFunction

// Checks the availability of inventory allocation tasks for orders.
//
// Parameters:
//  Orders - Array of AnyRef - array of orders.
//
// Returns:
//  Boolean - True if there are tasks, False otherwise
//
Function ThereAreTasksForOrders(Orders) Export
	
	Query = New Query();
	Query.SetParameter("Orders", Orders);
	Query.Text =
	"SELECT TOP 1
	|	TRUE AS ThereAreRecords
	|FROM
	|	InformationRegister.JobsForAllocatingInventory AS Jobs
	|WHERE
	|	Jobs.ShipmentOrder IN(&Orders)";
	SetPrivilegedMode(True);
	HasJobs = Not Query.Execute().IsEmpty();
	
	If HasJobs Then
		
		CheckToRunBackgroundInventoryAllocationJob();
		
	EndIf;
	
	Return HasJobs;
	
EndFunction

Procedure FillInEmbeddingServiceParameters(DocumentParameters) Export
	
	InsertEmbeddingServiceParameters(DocumentParameters.EmbeddingParameters, Undefined);
	
EndProcedure

// It is used to check the possibility of opening the processing of filling in the assignment correction.
// Parameters:
//  ThisIsReservation - Boolean - True if it is necessary to open processing for reservation, false if it is necessary to withdraw the reserve.
//  Ref - DefinedType.ExpectedShipment - a link to the order in which the commands for separate reserving and removing the reserve are embedded.
// Returns:
//  Structure - structure with fields:
//   * DocumentAssignment - CatalogRef.Assignments - the purpose of the order.
//   * ThereAreGoodsToSeparateProvision - Boolean - It is true if the order has goods for separate provision.
//   * ThereAreGoodsToThirdPartyStandAloneCollateral - Boolean - True if there are goods to a separate provision used by the order, but not related to the order.
//   * ThereAreGoodsToWithdrawReserve - Boolean - It is true if there are goods on order to remove the separation.
//   * HaveAccessToThirdPartyReserveWithdrawals - Boolean - True, if there are goods to be separated for the purpose used by the order, but not related to the order.
Function CheckingPossibilityOfOpeningFillingInAssignmentCorrection(ThisIsReservation, Ref) Export
	
	Result = New Structure(
		"DocumentAssignment,
		|ThereAreGoodsToSeparateProvision,
		|ThereAreGoodsToThirdPartyStandAloneCollateral,
		|ThereAreGoodsToWithdrawReserve,
		|HaveAccessToThirdPartyReserveWithdrawals");
	Result.DocumentAssignment = Documents.InventoryAssignmentAdjustment.OrderAssignment(Ref);
	If ThisIsReservation Then
		Result.ThereAreGoodsToSeparateProvision
			= Documents.InventoryAssignmentAdjustment.ThereAreGoodsToSeparateProvision(Result.DocumentAssignment);
		Result.ThereAreGoodsToThirdPartyStandAloneCollateral
			= Documents.InventoryAssignmentAdjustment.ThereAreGoodsToThirdPartyStandAloneCollateral(Ref);
	Else
		Result.ThereAreGoodsToWithdrawReserve
			= Documents.InventoryAssignmentAdjustment.ThereAreGoodsToWithdrawReserve(Result.DocumentAssignment);
		Result.HaveAccessToThirdPartyReserveWithdrawals
			= Documents.InventoryAssignmentAdjustment.HaveAccessToThirdPartyReserveWithdrawals(Ref);
	EndIf;
	Return Result;

EndFunction

// Performs the setting of the session. Called from the session module.
//
// Parameters:
//   ParameterName           - String - name of the session parameter.
//   SpecifiedParameters - Array of String - an array of all set parameters of the session.
//
Procedure SetSessionParameters(ParameterName, SpecifiedParameters) Export
	
	SessionParameters.PostWithoutControlOfGoodsReservesUnderOrders = False;
	
	If ParameterName = "PostWithoutControlOfGoodsReservesUnderOrders" Then
		SessionParameters.PostWithoutControlOfGoodsReservesUnderOrders = False;
		SpecifiedParameters.Add(ParameterName);
	EndIf;

EndProcedure

// Returns:
//  String - the text to write to the registration Log.
Function EventNameMonitoringOfItemReservesForOrdersIsDisabled() Export
	
	DefaultLanguageCode = Common.DefaultLanguageCode();
	
	Return NStr("vi = 'Kiểm soát dự phòng hàng hóa theo đơn';
				|ru = 'Контроль резервов товаров по заказам';
				|en = 'Control of goods reserves under orders'; fa = 'Control of goods reserves under orders';
				|it = 'Контроль резервов товаров по заказам';
				|pl = 'Control of goods reserves under orders';
				|tr = 'Siparişlere göre ürün rezervlerinin kontrolü'", DefaultLanguageCode);
	
EndFunction

#Region UpdatingInformationBaseDocuments

#EndRegion

#EndRegion

#Region Private

Procedure InsertEmbeddingServiceParameters(EmbeddingParameters, UUID)
	
	InternalParameters = New Structure();
	InternalParameters.Insert("NeedAvailabilityUpdateHandler", False);
	InternalParameters.Insert("ToUpdateColumnAvailableAfterInventoryAllocation", Undefined);
	InternalParameters.Insert("OrdersToUpdateAvailability", Undefined);
	InternalParameters.Insert("IntervalForStartingHandler", Undefined);
	InternalParameters.Insert("ReadyForSupply", False);
	InternalParameters.Insert("SupplyOptionBeforeChange");
	InternalParameters.Insert("SecurityOptionSelectedValue");
	InternalParameters.Insert("AddressProductRange");
	InternalParameters.Insert("IsDocument", False);
	InternalParameters.Insert("RowData", Undefined);
	InternalParameters.Insert("AddressOfFormDataTable", Undefined);
	InternalParameters.Insert("QueryTextTemporaryDocumentDataTable", Undefined);
	
	EmbeddingParameters.Insert("InternalParameters", InternalParameters);
	
	InternalParameters.IsDocument = StrFind(EmbeddingParameters.ObjectName, "Document.") > 0;
	InternalParameters.RowData = Common.CopyRecursive(EmbeddingParameters.FormDataSerializationPattern);
	
	Tables = New Map();
	InsertTables(Tables, EmbeddingParameters.FormDataSerializationPattern, "");
	FillInTableNamesAsAppropriate(EmbeddingParameters, Tables);
	InternalParameters.AddressOfFormDataTable = PutToTempStorage(Tables, UUID);
	
	InternalParameters.QueryTextTemporaryDocumentDataTable = QueryTextTemporaryDocumentDataTable(
		EmbeddingParameters,
		Tables);
	
EndProcedure

Function PerformActionForOrdersAfterQuestionByBackgroundTask(ProcedureParameters, UUID) Export
	
	ExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(UUID);
	ExecutionParameters.BackgroundJobDescription = NStr("vi = 'Thực hiện thao tác đảm bảo trong danh sách đơn hàng';
														|ru = 'Выполнение действия обеспечения в списке заказов';
														|en = 'Executing a provisioning action on the order list'; fa = 'Executing a provisioning action on the order list';
														|it = 'Esecuzione dell''azione di approvvigionamento nell''elenco degli ordini';
														|pl = 'Wykonanie czynności zaopatrzenia na liście zamówień';
														|tr = 'Bir sipariş listesinde tedarik işlemi gerçekleştirme'");
	
	Return TimeConsumingOperations.ExecuteFunction(
		ExecutionParameters,
		"ProvisionInDocumentsServer.PerformActionForOrdersAfterQuestion",
		ProcedureParameters);
	
EndFunction

Function UploadDocumentChangeTable(TempTablesManager, Form)
	
	EmbeddingParameters = Form.AvailableRemainingEmbeddingOptions;
	Query = New Query();
	Query.TempTablesManager = TempTablesManager;
	
	Texts = New Array();
	QueryText = TemporaryTableOfDocumentRegisteredRecords();
	Query.SetParameter("Ref", Undefined);
	Query.SetParameter("NewDestinationLink", Catalogs.Assignments.GetRef());
	Texts.Add(QueryText);
	
	CorrectionOfRegisteredRecords = ?(EmbeddingParameters.AddressOfMotionCorrection = Undefined,
		Undefined,
		GetFromTempStorage(Form[EmbeddingParameters.AddressOfMotionCorrection]));
	If CorrectionOfRegisteredRecords = Undefined Then
		
		QueryText =
			"SELECT
			|	UNDEFINED AS Products,
			|	UNDEFINED AS Characteristic,
			|	UNDEFINED AS Warehouse,
			|	UNDEFINED AS Purpose,
			|	UNDEFINED AS ControlledLotReference,
			|	UNDEFINED AS ShipmentOrder,
			|	0 AS Ship,
			|	0 AS ToReserve_
			|INTO TemporaryTableAdjustingDocumentRegisteredRecords
			|WHERE
			|	FALSE";
		
	Else
		Query.SetParameter("CorrectionOfRegisteredRecords", CorrectionOfRegisteredRecords.RegisterRecordTable);
		QueryText =
			"SELECT
			|	RegisterRecords.Products AS Products,
			|	RegisterRecords.Characteristic AS Characteristic,
			|	RegisterRecords.Warehouse AS Warehouse,
			|	RegisterRecords.Purpose AS Purpose,
			|	VALUE(Catalog.ControlledLots.EmptyRef) AS ControlledLotReference,
			|	CASE
			|		WHEN RegisterRecords.OrderToShip <> UNDEFINED
			|			THEN RegisterRecords.OrderToShip
			|		ELSE RegisterRecords.OrderDocument
			|	END AS ShipmentOrder,
			|	CASE
			|		WHEN RegisterRecords.RecordType = VALUE(AccumulationRecordType.Expense)
			|			THEN RegisterRecords.InStock - RegisterRecords.LockedInStock
			|		ELSE -(RegisterRecords.InStock - RegisterRecords.LockedInStock)
			|	END AS Ship,
			|	CASE
			|		WHEN RegisterRecords.RecordType = VALUE(AccumulationRecordType.Receipt)
			|			THEN RegisterRecords.ReserveAtWarehouse
			|		ELSE - RegisterRecords.ReserveAtWarehouse
			|	END AS ToReserve_
			|INTO TemporaryTableAdjustingDocumentRegisteredRecords1
			|FROM
			|	&CorrectionOfRegisteredRecords AS RegisterRecords
			|WHERE
			|	RegisterRecords.InStock <> 0
			|		OR RegisterRecords.ReserveAtWarehouse <> 0
			|;
			|
			|//////////////////////////////////////////////////////////////////////////
			|SELECT
			|	RegisterRecords.Products AS Products,
			|	RegisterRecords.Characteristic AS Characteristic,
			|	RegisterRecords.Warehouse AS Warehouse,
			|	RegisterRecords.Purpose AS Purpose,
			|	CASE
			|		WHEN RegisterRecords.OrderToShip <> UNDEFINED
			|			THEN RegisterRecords.OrderToShip
			|		ELSE RegisterRecords.OrderDocument
			|	END AS ControlledLotReference,
			|	CASE
			|		WHEN RegisterRecords.OrderToShip <> UNDEFINED
			|			THEN RegisterRecords.OrderToShip
			|		ELSE RegisterRecords.OrderDocument
			|	END AS ShipmentOrder,
			|	CASE
			|		WHEN RegisterRecords.RecordType = VALUE(AccumulationRecordType.Expense)
			|			THEN RegisterRecords.LockedInStock
			|		ELSE -RegisterRecords.LockedInStock
			|	END AS Ship,
			|	CASE
			|		WHEN RegisterRecords.RecordType = VALUE(AccumulationRecordType.Receipt)
			|			THEN RegisterRecords.ReserveAtWarehouseFromLocked
			|		ELSE - RegisterRecords.ReserveAtWarehouseFromLocked
			|	END AS ToReserve_
			|INTO TemporaryTableAdjustingDocumentRegisteredRecords2
			|FROM
			|	&CorrectionOfRegisteredRecords AS RegisterRecords
			|WHERE
			|	RegisterRecords.LockedInStock <> 0
			|		OR RegisterRecords.ReserveAtWarehouseFromLocked <> 0
			|;
			|
			|//////////////////////////////////////////////////////////////////////////
			|SELECT
			|	Table.Products AS Products,
			|	Table.Characteristic AS Characteristic,
			|	Table.Warehouse AS Warehouse,
			|	Table.Purpose AS Purpose,
			|	Table.ControlledLotReference AS ControlledLotReference,
			|	Table.ShipmentOrder AS ShipmentOrder,
			|	Table.Ship AS Ship,
			|	Table.ToReserve_ AS ToReserve_
			|INTO TemporaryTableAdjustingDocumentRegisteredRecords
			|FROM
			|	TemporaryTableAdjustingDocumentRegisteredRecords1 AS Table
			|
			|UNION ALL
			|
			|SELECT
			|	Table.Products AS Products,
			|	Table.Characteristic AS Characteristic,
			|	Table.Warehouse AS Warehouse,
			|	Table.Purpose AS Purpose,
			|	Table.ControlledLotReference AS ControlledLotReference,
			|	Table.ShipmentOrder AS ShipmentOrder,
			|	Table.Ship AS Ship,
			|	Table.ToReserve_ AS ToReserve_
			|FROM
			|	TemporaryTableAdjustingDocumentRegisteredRecords2 AS Table
			|INDEX BY
			|	Products, Characteristic, Warehouse, Purpose, ControlledLotReference
			|;
			|
			|DROP TemporaryTableAdjustingDocumentRegisteredRecords1;
			|DROP TemporaryTableAdjustingDocumentRegisteredRecords2";
	EndIf;
	Texts.Add(QueryText);
	
	QueryText =
		"SELECT DISTINCT
		|	Table.Products AS Products,
		|	Table.Characteristic AS Characteristic,
		|	CASE
		|		WHEN CAST(Table.Products AS Catalog.Products).ItemsType IN(
		|				VALUE(Enum.ItemsTypes.OwnGoods),
		|				VALUE(Enum.ItemsTypes.ReusablePackage))
		|			THEN Table.Warehouse
		|		ELSE Table.Department
		|	END AS Warehouse,
		|	Table.ShipmentOrder AS ShipmentOrder,
		|	CASE
		|		WHEN Table.WithAssignment
		|			THEN Table.Purpose
		|		ELSE VALUE(Catalog.Assignments.EmptyRef)
		|	END AS Purpose,
		|	Table.ControlledLotReference AS ControlledLotReference
		|INTO SelectedOrders_
		|FROM
		|	TemporaryDocumentDataTable AS Table
		|;
		|
		|//////////////////////////////////////////////
		|SELECT DISTINCT
		|	Orders.Products AS Products,
		|	Orders.Characteristic AS Characteristic,
		|	Orders.Warehouse AS Warehouse,
		|	Orders.Purpose AS Purpose,
		|	Orders.ControlledLotReference AS ControlledLotReference
		|INTO SelectedProductItems
		|FROM
		|	SelectedOrders_ AS Orders";
	
	Query.Text = StrConcat(Texts, Common.QueryBatchSeparator());
	Query.Execute();
	
	Query.Text =
		// Stages of the order to the processor.
		"SELECT DISTINCT
		|	Table.ShipmentOrder AS ShipmentOrder,
		|	Table.Recorder AS Recorder
		|INTO RecordersOtherThanOrder
		|FROM
		|	TemporaryDocumentDataTable AS Table
		|WHERE
		|	Table.ShipmentOrder <> Table.Recorder
		|INDEX BY
		|	Recorder
		|;
		|
		|////////////////////////////////////////////////
		|SELECT
		|	RegisterRecords.Products AS Products,
		|	RegisterRecords.Characteristic AS Characteristic,
		|	RegisterRecords.Warehouse AS Warehouse,
		|	RegisterRecords.Purpose AS Purpose,
		|	RegisterRecords.RecordType AS RecordType,
		// In an unverified order to the processor, the Production Stage will act as the order, you need to replace it with an Order to the processor.
		|	CASE
		|		WHEN RecordersOtherThanOrder.Recorder = RegisterRecords.OrderToShip
		|			THEN RecordersOtherThanOrder.ShipmentOrder
		|		ELSE RegisterRecords.OrderToShip
		|	END AS OrderToShip,
		|	CASE
		|		WHEN RecordersOtherThanOrder.Recorder = RegisterRecords.OrderDocument
		|			THEN RecordersOtherThanOrder.ShipmentOrder
		|		ELSE RegisterRecords.OrderDocument
		|	END AS OrderDocument,
		|	RegisterRecords.InStock AS InStock,
		|	RegisterRecords.LockedInStock AS LockedInStock,
		|	RegisterRecords.ReserveAtWarehouse AS ReserveAtWarehouse,
		|	RegisterRecords.ReserveAsReceived AS ReserveAsReceived,
		|	RegisterRecords.ReserveAtWarehouseFromLocked AS ReserveAtWarehouseFromLocked,
		|	RegisterRecords.ReserveUponReceiptFromLocked AS ReserveUponReceiptFromLocked,
		|	RegisterRecords.Active AS Active
		|INTO LoggerRegisteredRecords_
		|FROM
		|	AccumulationRegister.InventoryAndDemands AS RegisterRecords
		|		LEFT JOIN RecordersOtherThanOrder AS RecordersOtherThanOrder
		|		ON RecordersOtherThanOrder.Recorder = RegisterRecords.Recorder
		|WHERE
		|	RegisterRecords.Recorder IN(
		|		SELECT
		|			Table.Recorder AS Recorder
		|		FROM
		|			TemporaryDocumentDataTable AS Table)
		|INDEX BY
		|	Products, Characteristic, Purpose, Warehouse, Active";
	SetPrivilegedMode(True);
	Query.Execute();
	SetPrivilegedMode(False);
	
	Texts = New Array();
	Texts.Add(QueryText);
	
	QueryText =
		// Imitation of the movements of the edited document.
		"SELECT ALLOWED
		|	Adjusting.Products AS Products,
		|	Adjusting.Characteristic AS Characteristic,
		|	Adjusting.Warehouse AS Warehouse,
		|	Adjusting.Purpose AS Purpose,
		|	Adjusting.ControlledLotReference AS ControlledLotReference,
		|	Adjusting.ShipmentOrder AS ShipmentOrder,
		|	SUM(Adjusting.Ship) AS Ship,
		|	SUM(Adjusting.ToReserve_) AS ToReserve_,
		|	SUM(Adjusting.ReserveAsReceived) > 0
		|		OR -SUM(Adjusting.ReserveAsReceived)
		|				> SUM(Adjusting.Ship + Adjusting.ToReserve_) AS ToUpdateColumnAvailableAfterInventoryAllocation
		|FROM(
		|	SELECT
		|		RegisterRecords.Products AS Products,
		|		RegisterRecords.Characteristic AS Characteristic,
		|		RegisterRecords.Warehouse AS Warehouse,
		|		RegisterRecords.Purpose AS Purpose,
		|		VALUE(Catalog.ControlledLots.EmptyRef) AS ControlledLotReference,
		|		CASE
		|			WHEN RegisterRecords.OrderToShip <> UNDEFINED
		|				THEN RegisterRecords.OrderToShip
		|			ELSE RegisterRecords.OrderDocument
		|		END AS ShipmentOrder,
		|		CASE
		|			WHEN RegisterRecords.RecordType = VALUE(AccumulationRecordType.Receipt)
		|				THEN -(RegisterRecords.InStock - RegisterRecords.LockedInStock)
		|			ELSE RegisterRecords.InStock - RegisterRecords.LockedInStock
		|		END AS Ship,
		|		CASE
		|			WHEN RegisterRecords.RecordType = VALUE(AccumulationRecordType.Expense)
		|				THEN -RegisterRecords.ReserveAtWarehouse
		|			ELSE RegisterRecords.ReserveAtWarehouse
		|		END AS ToReserve_,
		|		CASE
		|			WHEN RegisterRecords.RecordType = VALUE(AccumulationRecordType.Expense)
		|				THEN -RegisterRecords.ReserveAsReceived
		|			ELSE RegisterRecords.ReserveAsReceived
		|		END AS ReserveAsReceived
		|	FROM
		|		TemporaryTableOfDocumentRegisteredRecords AS RegisterRecords
		|	
		|	UNION ALL
		|	
		// A table for correcting document movements.
		|	SELECT
		|		RegisterRecords.Products AS Products,
		|		RegisterRecords.Characteristic AS Characteristic,
		|		RegisterRecords.Warehouse AS Warehouse,
		|		RegisterRecords.Purpose AS Purpose,
		|		RegisterRecords.ControlledLotReference AS ControlledLotReference,
		|		RegisterRecords.ShipmentOrder AS ShipmentOrder,
		|		RegisterRecords.Ship AS Ship,
		|		RegisterRecords.ToReserve_ AS ToReserve_,
		|		0 AS ReserveAsReceived
		|	FROM
		|		SelectedProductItems AS Goods
		|			
		|			LEFT JOIN TemporaryTableAdjustingDocumentRegisteredRecords AS RegisterRecords
		|			ON RegisterRecords.Products = Goods.Products
		|			 AND RegisterRecords.Characteristic = Goods.Characteristic
		|			 AND RegisterRecords.Purpose = Goods.Purpose
		|			 AND RegisterRecords.Warehouse = Goods.Warehouse
		|			 AND RegisterRecords.ControlledLotReference = Goods.ControlledLotReference
		|	WHERE
		|		NOT RegisterRecords.Products IS NULL
		|	
		|	UNION ALL
		|	
		// Reverse recorded document movements.
		|	SELECT
		|		RegisterRecords.Products AS Products,
		|		RegisterRecords.Characteristic AS Characteristic,
		|		RegisterRecords.Warehouse AS Warehouse,
		|		RegisterRecords.Purpose AS Purpose,
		|		VALUE(Catalog.ControlledLots.EmptyRef) AS ControlledLotReference,
		|		CASE
		|			WHEN RegisterRecords.OrderToShip <> UNDEFINED
		|				THEN RegisterRecords.OrderToShip
		|			ELSE RegisterRecords.OrderDocument
		|		END AS ShipmentOrder,
		|		CASE
		|			WHEN RegisterRecords.RecordType = VALUE(AccumulationRecordType.Receipt)
		|				THEN RegisterRecords.InStock - RegisterRecords.LockedInStock
		|			ELSE -(RegisterRecords.InStock - RegisterRecords.LockedInStock)
		|		END AS Ship,
		|		CASE
		|			WHEN RegisterRecords.RecordType = VALUE(AccumulationRecordType.Expense)
		|				THEN RegisterRecords.ReserveAtWarehouse
		|			ELSE -RegisterRecords.ReserveAtWarehouse
		|		END AS ToReserve_,
		|		CASE
		|			WHEN RegisterRecords.RecordType = VALUE(AccumulationRecordType.Expense)
		|				THEN RegisterRecords.ReserveAsReceived
		|			ELSE -RegisterRecords.ReserveAsReceived
		|		END AS ReserveAsReceived
		|	FROM
		|		SelectedProductItems AS Goods
		|			
		|			LEFT JOIN LoggerRegisteredRecords_ AS RegisterRecords
		|			ON RegisterRecords.Products    = Goods.Products
		|			 AND RegisterRecords.Characteristic  = Goods.Characteristic
		|			 AND RegisterRecords.Purpose      = Goods.Purpose
		|			 AND RegisterRecords.Warehouse           = Goods.Warehouse
		|			 AND RegisterRecords.Active
		|	WHERE
		|		NOT RegisterRecords.Products IS NULL
		|	
		|	UNION ALL
		|	
		// Simulation of the Registered Records of the edited document for controlled parties.
		|	SELECT
		|		RegisterRecords.Products AS Products,
		|		RegisterRecords.Characteristic AS Characteristic,
		|		RegisterRecords.Warehouse AS Warehouse,
		|		RegisterRecords.Purpose AS Purpose,
		|		CASE
		|			WHEN RegisterRecords.OrderToShip <> UNDEFINED
		|				THEN RegisterRecords.OrderToShip
		|			ELSE RegisterRecords.OrderDocument
		|		END AS ControlledLotReference,
		|		CASE
		|			WHEN RegisterRecords.OrderToShip <> UNDEFINED
		|				THEN RegisterRecords.OrderToShip
		|			ELSE RegisterRecords.OrderDocument
		|		END AS ShipmentOrder,
		|		CASE
		|			WHEN RegisterRecords.RecordType = VALUE(AccumulationRecordType.Receipt)
		|				THEN -RegisterRecords.LockedInStock
		|			ELSE RegisterRecords.LockedInStock
		|		END AS Ship,
		|		CASE
		|			WHEN RegisterRecords.RecordType = VALUE(AccumulationRecordType.Expense)
		|				THEN -RegisterRecords.ReserveAtWarehouseFromLocked
		|			ELSE RegisterRecords.ReserveAtWarehouseFromLocked
		|		END AS ToReserve_,
		|		CASE
		|			WHEN RegisterRecords.RecordType = VALUE(AccumulationRecordType.Expense)
		|				THEN -RegisterRecords.ReserveUponReceiptFromLocked
		|			ELSE RegisterRecords.ReserveUponReceiptFromLocked
		|		END AS ReserveAsReceived
		|	FROM
		|		TemporaryTableOfDocumentRegisteredRecords AS RegisterRecords
		|	
		|	UNION ALL
		|	
		// Storno of recorded Registered Records of the document on controlled Lots references.
		|	SELECT
		|		RegisterRecords.Products AS Products,
		|		RegisterRecords.Characteristic AS Characteristic,
		|		RegisterRecords.Warehouse AS Warehouse,
		|		RegisterRecords.Purpose AS Purpose,
		|		CASE
		|			WHEN RegisterRecords.OrderToShip <> UNDEFINED
		|				THEN RegisterRecords.OrderToShip
		|			ELSE RegisterRecords.OrderDocument
		|		END AS ControlledLotReference,
		|		CASE
		|			WHEN RegisterRecords.OrderToShip <> UNDEFINED
		|				THEN RegisterRecords.OrderToShip
		|			ELSE RegisterRecords.OrderDocument
		|		END AS ShipmentOrder,
		|		CASE
		|			WHEN RegisterRecords.RecordType = VALUE(AccumulationRecordType.Receipt)
		|				THEN RegisterRecords.LockedInStock
		|			ELSE - RegisterRecords.LockedInStock
		|		END AS Ship,
		|		CASE
		|			WHEN RegisterRecords.RecordType = VALUE(AccumulationRecordType.Expense)
		|				THEN RegisterRecords.ReserveAtWarehouseFromLocked
		|			ELSE -RegisterRecords.ReserveAtWarehouseFromLocked
		|		END AS ToReserve_,
		|		CASE
		|			WHEN RegisterRecords.RecordType = VALUE(AccumulationRecordType.Expense)
		|				THEN RegisterRecords.ReserveUponReceiptFromLocked
		|			ELSE -RegisterRecords.ReserveUponReceiptFromLocked
		|		END AS ReserveAsReceived
		|	FROM
		|		SelectedProductItems AS Goods
		|			
		|			LEFT JOIN LoggerRegisteredRecords_ AS RegisterRecords
		|			ON RegisterRecords.Products    = Goods.Products
		|			 AND RegisterRecords.Characteristic  = Goods.Characteristic
		|			 AND RegisterRecords.Purpose      = Goods.Purpose
		|			 AND RegisterRecords.Warehouse           = Goods.Warehouse
		|			 AND RegisterRecords.Active
		|	WHERE
		|		NOT RegisterRecords.Products IS NULL
		|) AS Adjusting
		|GROUP BY
		|	Adjusting.Products,
		|	Adjusting.Characteristic,
		|	Adjusting.Warehouse,
		|	Adjusting.Purpose,
		|	Adjusting.ControlledLotReference,
		|	Adjusting.ShipmentOrder
		|HAVING
		|	SUM(Adjusting.Ship) <> 0
		|		OR SUM(Adjusting.ToReserve_) <> 0
		// If the document reduced the reserve as needed, not due to the installation of reserve or ship,
		// then the Available column needs to be refilled in the form of a document after completing the inventory allocation tasks by order,
		// as it can reduce auto reserves under the order.
		|		OR SUM(Adjusting.ReserveAsReceived) > 0
		|		OR -SUM(Adjusting.ReserveAsReceived)
		|				> SUM(Adjusting.Ship + Adjusting.ToReserve_)";
	
	Texts.Add(QueryText);
	Query.Text = StrConcat(Texts, Common.QueryBatchSeparator());
	ChangesTable = Query.Execute().Unload();
	
	Return ChangesTable;
	
EndFunction

Function TextAndParametersOfRequestForSecuringShipmentOrders(TempTableName)
	
	QueryOptions = New Structure();
	QueryOptions.Insert("CurrentDayStart");
	QueryOptions.Insert("ShippingOrders");
	
	QueryText =
		"SELECT ALLOWED
		|	OrderState.ShipmentOrder AS ShipmentOrder,
		|	MAX(
		|		CASE
		|			WHEN VALUETYPE(OrderState.ShipmentOrder) = TYPE(Catalog.ControlledLots)
		|				THEN
		|					OrderState.InventoryState IN(
		|						VALUE(Enum.InventoryStates.AvailablePendingUnlocking),
		|						VALUE(Enum.InventoryStates.AvailableNotSubjectToUnlocking))
		|			ELSE OrderState.InventoryState = VALUE(Enum.InventoryStates.InStock)
		|		END) AS CanBeShippedNow,
		|	
		|	MAX(
		|		OrderState.RequestShipmentOn > DATETIME(1,1,1)
		|				AND CASE
		|					WHEN OrderState.RequestShipmentOn < &CurrentDayStart
		|						THEN &CurrentDayStart
		|					ELSE OrderState.RequestShipmentOn
		|				END
		|			< CASE
		|					WHEN OrderState.InventoryState IN(
		|						VALUE(Enum.InventoryStates.ExpectedForReceiptWithoutLock),
		|						VALUE(Enum.InventoryStates.ExpectedForReceiptWithLock),
		|						VALUE(Enum.InventoryStates.ExpectedForReceiptNotSubjectToUnlocking))
		|					THEN
		|						CASE
		|							WHEN VALUETYPE(OrderState.ShipmentOrder) = TYPE(Catalog.ControlledLots)
		|								THEN
		|									CASE
		|										WHEN OrderState.DateOfReceipt < &CurrentDayStart
		|											THEN &CurrentDayStart
		|										ELSE OrderState.DateOfReceipt
		|									END
		|							ELSE
		|								CASE
		|									WHEN OrderState.AvailabilityDate < &CurrentDayStart
		|										THEN &CurrentDayStart
		|									ELSE OrderState.AvailabilityDate
		|								END
		|						END
		|					WHEN OrderState.InventoryState = VALUE(Enum.InventoryStates.NotProvided)
		|							AND NOT OrderState.DemandCharacteristic = VALUE(Enum.DemandCharacteristics.NotProvide)
|								THEN
		|							CASE
		|								WHEN CalculationOfSecurityMethodOverridable.Ref = VALUE(Catalog.ProcurementStrategies.EmptyRef)
		|									THEN DATETIME(1,1,1)
		|								ELSE CalculationOfDeliveryDateOverridable.PlannedDeliveryDate
		|							END
		|						ELSE &CurrentDayStart
		|			END) AS ShipmentDateNotValid,
		|	MAX(
		|		CASE
		|			WHEN OrderState.InventoryState IN(
		|					VALUE(Enum.InventoryStates.ExpectedForReceiptWithoutLock),
		|					VALUE(Enum.InventoryStates.ExpectedForReceiptWithLock),
		|					VALUE(Enum.InventoryStates.AvailablePendingUnlocking),
		|					VALUE(Enum.InventoryStates.AvailableNotSubjectToUnlocking),
		|					VALUE(Enum.InventoryStates.ExpectedForReceiptNotSubjectToUnlocking))
		|				THEN
		|					CASE
		|						WHEN VALUETYPE(OrderState.ShipmentOrder) = TYPE(Catalog.ControlledLots)
		|							THEN
		|								CASE
		|									WHEN OrderState.DateOfReceipt < &CurrentDayStart
		|										THEN &CurrentDayStart
		|									ELSE OrderState.DateOfReceipt
		|								END
		|						ELSE
		|							CASE
		|								WHEN OrderState.AvailabilityDate < &CurrentDayStart
		|									THEN &CurrentDayStart
		|								ELSE OrderState.AvailabilityDate
		|							END
		|					END
		|			WHEN OrderState.InventoryState = VALUE(Enum.InventoryStates.NotProvided)
		|					AND NOT OrderState.DemandCharacteristic = VALUE(Enum.DemandCharacteristics.NotProvide)
		|				THEN
		|					CASE
		|						WHEN CalculationOfSecurityMethodOverridable.Ref = VALUE(Catalog.ProcurementStrategies.EmptyRef)
		|							THEN DATETIME(1,1,1)
		|						ELSE CalculationOfDeliveryDateOverridable.PlannedDeliveryDate
		|					END
		|			ELSE OrderState.AvailabilityDate
		|		END) AS PossibleShippingDate
		|INTO TTOverridable
		|FROM
		|	InformationRegister.InventoryAllocation AS OrderState
		|		
		|		LEFT JOIN CalculationOfSecurityMethodOverridable ON TRUE
		|		
		|		LEFT JOIN CalculationOfDeliveryDateOverridable ON TRUE
		|		
		|WHERE
		|	OrderState.ShipmentOrder IN(&ShippingOrders)
		|		AND OrderState.DemandCharacteristic IN(
		|			VALUE(Enum.DemandCharacteristics.ReserveAtWarehouse),
		|			VALUE(Enum.DemandCharacteristics.ReserveAtWarehouseFromLocked),
		|			VALUE(Enum.DemandCharacteristics.ReserveAsReceived),
		|			VALUE(Enum.DemandCharacteristics.ReserveUponReceiptFromLocked),
		|			VALUE(Enum.DemandCharacteristics.SnoozeReservation),
		|			VALUE(Enum.DemandCharacteristics.ToSupply),
		|			VALUE(Enum.DemandCharacteristics.NotProvide))
		|	
		|GROUP BY
		|	OrderState.ShipmentOrder";
	
	Substitutions = SubstitutionsOfMainMethodOfProviding(
		"OrderState.Products",
		"OrderState.Characteristic",
		"OrderState.Warehouse",
		"OrderState.InventoryState = VALUE(Enum.InventoryStates.NotProvided)
		|	AND NOT OrderState.DemandCharacteristic = VALUE(Enum.DemandCharacteristics.NotProvide)");
	
	QueryText = StrReplace(QueryText, "CalculationOfSecurityMethodOverridable.Ref", Substitutions.Field);
	QueryText = StrReplace(QueryText, "LEFT JOIN CalculationOfSecurityMethodOverridable ON TRUE",
		Substitutions.Joins);
	
	Substitutions = SubstitutionsOfPlannedDeliveryDate(
		Substitutions.Field,
		"&CurrentDayStart",
		"OrderState.Products",
		"OrderState.Warehouse");
	
	QueryText = StrReplace(QueryText, "CalculationOfDeliveryDateOverridable.PlannedDeliveryDate", Substitutions.Field);
	QueryText = StrReplace(QueryText, "LEFT JOIN CalculationOfDeliveryDateOverridable ON TRUE",
		Substitutions.Joins);
		
	QueryText = StrReplace(QueryText, "CalculationOverridable.PlannedDeliveryDate", Substitutions.Field);
	QueryText = StrReplace(QueryText, "LEFT JOIN CalculationOverridable ON TRUE", Substitutions.Joins);
	QueryText = StrReplace(QueryText, "TTOverridable", TempTableName);
	
	Texts = New Array();
	TemporaryTableText = TempTableYearsOfEnterpriseSchedule();
	Texts.Add(TemporaryTableText);
	Texts.Add(QueryText);
	Texts.Add("DROP YearsOfEnterpriseSchedule");
	QueryText = StrConcat(Texts, Common.QueryBatchSeparator());
	TextAndParameters = New Structure("Text,Parameters", QueryText, QueryOptions);
	
	Return TextAndParameters;
	
EndFunction

#Region FillingOutCollateral

Function GroupWarehouses_(Query)
	
	Query.Text =
		"SELECT TOP 1
		|	Table.GroupOfWarehouses AS Ref
		|FROM
		|	TemporaryDocumentDataTableForSelectedRows AS Table";
	Selection = Query.Execute().Select();
	Ref = Undefined;
	If Selection.Next() Then
		Ref = Selection.Ref;
	EndIf;
	
	If ValueIsFilled(Ref) And Catalogs.Warehouses.IsFolder(Ref) Or Ref = Undefined Then
		
		Query.Text =
			"SELECT ALLOWED
			|	Warehouses.Ref
			|FROM
			|	Catalog.Warehouses AS Warehouses
			|WHERE
			|	Warehouses.IsFolder = FALSE
			|	AND Warehouses.DeletionMark = FALSE
			|	AND (Warehouses.Ref IN HIERARCHY(&GroupOfWarehouses)
			|		OR &GroupOfWarehouses = UNDEFINED)";
		
		Query.SetParameter("GroupOfWarehouses", Ref);
		WarehouseArray = Query.Execute().Unload().UnloadColumn("Ref");
		
	Else
		
		WarehouseArray = Undefined;
	
	EndIf;
	
	Return WarehouseArray;
	
EndFunction

// Parameters:
//  TempTablesManager - TempTablesManager
//  SeparateAndNonSeparateBalances - Boolean
//  AdditionalParameters - Structure
Function BalancesForRecordedDocument(TempTablesManager, SeparateAndNonSeparateBalances, AdditionalParameters)
	
	Query = New Query();
	Query.TempTablesManager = TempTablesManager;
	Query.SetParameter("SeparateAndNonSeparateBalances", SeparateAndNonSeparateBalances);
	Texts = New Array();
	QueryText =
		"SELECT DISTINCT
		|	Table.Products AS Products,
		|	Table.Characteristic AS Characteristic,
		|	CASE
		|		WHEN CAST(Table.Products AS Catalog.Products).ItemsType IN(
		|				VALUE(Enum.ItemsTypes.OwnGoods),
		|				VALUE(Enum.ItemsTypes.ReusablePackage))
		|			THEN Table.Warehouse
		|		ELSE Table.Department
		|	END AS Warehouse,
		|	Table.ShipmentOrder AS ShipmentOrder,
		|	CASE
		|		WHEN Table.WithAssignment
		|			THEN Table.Purpose
		|		ELSE VALUE(Catalog.Assignments.EmptyRef)
		|	END AS Purpose,
		|	Table.ControlledLotReference AS ControlledLotReference
		|INTO SelectedOrders_
		|FROM
		|	TemporaryDocumentDataTable AS Table
		|
		|UNION
		|
		|SELECT DISTINCT
		|	Table.Products AS Products,
		|	Table.Characteristic AS Characteristic,
		|	CASE
		|		WHEN CAST(Table.Products AS Catalog.Products).ItemsType IN(
		|				VALUE(Enum.ItemsTypes.OwnGoods),
		|				VALUE(Enum.ItemsTypes.ReusablePackage))
		|			THEN Table.Warehouse
		|		ELSE Table.Department
		|	END AS Warehouse,
		|	Table.ShipmentOrder AS ShipmentOrder,
		|	CASE
		|		WHEN Table.WithAssignment
		|			THEN VALUE(Catalog.Assignments.EmptyRef)
		|		ELSE
		|			CASE
		|				WHEN Table.Purpose = VALUE(Catalog.Assignments.EmptyRef)
		|					THEN UNDEFINED
		|				ELSE Table.Purpose
		|			END
		|	END AS Purpose,
		|	Table.ControlledLotReference AS ControlledLotReference
		|FROM
		|	TemporaryDocumentDataTable AS Table
 		|WHERE
		|	&SeparateAndNonSeparateBalances
		|INDEX BY
		|	Products, Characteristic, Warehouse, Purpose, ShipmentOrder
		|;
		|
		|//////////////////////////////////////////////
		|SELECT DISTINCT
		|	Orders.Products AS Products,
		|	Orders.Characteristic AS Characteristic,
		|	Orders.Warehouse AS Warehouse,
		|	Orders.Purpose AS Purpose,
		|	Orders.ControlledLotReference AS ControlledLotReference
		|INTO SelectedProductItems
		|FROM
		|	SelectedOrders_ AS Orders
		|INDEX BY
		|	Products, Characteristic, Warehouse, Purpose, ControlledLotReference";
	Texts.Add(QueryText);
	
	QueryText =
		"SELECT ALLOWED
		|	Inventories.Products AS Products,
		|	Inventories.Characteristic AS Characteristic,
		|	Inventories.Warehouse AS Warehouse,
		|	Inventories.Purpose AS Purpose,
		|	Inventories.OrderDocument AS OrderDocument,
		|	Inventories.LockedInStockBalance AS LockedInStockBalance,
		|	Inventories.LockedReceiptBalance AS LockedReceiptBalance,
		|	Inventories.ToUnlockBalance AS ToUnlockBalance,
		|	Inventories.ReserveAtWarehouseFromLockedBalance AS ReserveAtWarehouseFromLockedBalance,
		|	Inventories.ReserveUponReceiptFromLockedBalance AS ReserveUponReceiptFromLockedBalance
		|INTO InventoryAndNeedsBalanceOfControlledLotsReference
		|FROM
		|	AccumulationRegister.InventoryAndDemands.Balance(,
		|		(Products, Characteristic, Warehouse, Purpose) IN(
		|			SELECT
		|				Filter.Products AS Products,
		|				Filter.Characteristic AS Characteristic,
		|				Filter.Warehouse AS Warehouse,
		|				Filter.Purpose AS Purpose
		|			FROM
		|				SelectedProductItems AS Filter)) AS Inventories
		|INDEX BY
		|	Products, Characteristic, Warehouse, Purpose
		|;
		|
		|//////////////////////////////////////////////////
		|SELECT ALLOWED
		|	Inventories.Products AS Products,
		|	Inventories.Characteristic AS Characteristic,
		|	Inventories.Warehouse AS Warehouse,
		|	Inventories.Purpose AS Purpose,
		|	Inventories.InStockBalance AS InStockBalance,
		|	Inventories.LockedInStockBalance AS LockedInStockBalance,
		|	Inventories.OrderedBalance AS OrderedBalance,
		|	Inventories.Received_1Balance AS Received_1Balance,
		|	Inventories.LockedReceiptBalance AS LockedReceiptBalance,
		|	Inventories.ReserveAtWarehouseBalance AS ReserveAtWarehouseBalance,
		|	Inventories.ReserveAsReceivedBalance AS ReserveAsReceivedBalance,
		|	Inventories.SnoozeReservationBalance AS SnoozeReservationBalance,
		|	Inventories.ToSupplyBalance AS ToSupplyBalance,
		|	Inventories.NotProvideBalance AS NotProvideBalance
		|INTO InventoryAndDemandsBalance
		|FROM
		|	AccumulationRegister.InventoryAndDemands.Balance(,
		|		(Products, Characteristic, Warehouse, Purpose) IN(
		|			SELECT
		|				Filter.Products AS Products,
		|				Filter.Characteristic AS Characteristic,
		|				Filter.Warehouse AS Warehouse,
		|				Filter.Purpose AS Purpose
		|			FROM
		|				SelectedProductItems AS Filter)) AS Inventories
		|INDEX BY
		|	Products, Characteristic, Warehouse, Purpose
		|;
		|
		|//////////////////////////////////////////////////
		|SELECT
		|	Calculation.Products AS Products,
		|	Calculation.Characteristic AS Characteristic,
		|	Calculation.Warehouse AS Warehouse,
		|	Calculation.Purpose AS Purpose,
		|	Calculation.ControlledLotReference AS ControlledLotReference,
		|	Calculation.QuantityForShipAction AS QuantityForShipAction,
		|	Calculation.QuantityForActionIsReservedAsItBecomesAvailable AS QuantityForActionIsReservedAsItBecomesAvailable
		|INTO TemporaryTableOfBalances
		|FROM
		|	CalculationOfBalancesForSettingActions AS Calculation
		|INDEX BY
		|	Products, Characteristic, Warehouse, Purpose, ControlledLotReference";
	
	TablesNames = NewTableNamesForCalculatingBalancesForSettingActions();
	TablesNames.Balance = "InventoryAndDemandsBalance"; // @query-part-1
	TablesNames.BalanceSheetsOfControlledLotREFERENCES = "InventoryAndNeedsBalanceOfControlledLotsReference"; // @query-part-1
	TablesNames.Analysts = "SelectedProductItems";  // @query-part-1
	TablesNames.Result = "CalculationOfBalancesForSettingActions"; // @query-part-1
	CalculationOfBalancesForSettingActions(QueryText, TablesNames);
	
	Texts.Add(QueryText);
	
	QueryText =
		"SELECT
		|	Changes.Products AS Products,
		|	Changes.Characteristic AS Characteristic,
		|	Changes.Warehouse AS Warehouse,
		|	Changes.Purpose AS Purpose,
		|	Changes.ControlledLotReference AS ControlledLotReference,
		|	SUM(Changes.Available) AS Count,
		|	SUM(Changes.AvailableBasedOnExpectedReceipts) AS QuantityTakingIntoAccountExpectedReceipts
		|INTO BalanceTable
		|FROM(
		// "Soft" reserve under the order.
		|	SELECT
		|		InventoryAllocation.Products AS Products,
		|		InventoryAllocation.Characteristic AS Characteristic,
		|		InventoryAllocation.Warehouse AS Warehouse,
		|		InventoryAllocation.Purpose AS Purpose,
		|		CASE
		|			WHEN InventoryAllocation.InventoryState IN(
		|					VALUE(Enum.InventoryStates.AvailablePendingUnlocking),
		|					VALUE(Enum.InventoryStates.AvailableNotSubjectToUnlocking))
		|				THEN InventoryAllocation.ReceiptOrder
		|			ELSE VALUE(Catalog.ControlledLots.EmptyRef)
		|		END AS ControlledLotReference,
		|		InventoryAllocation.Count AS Available,
		|		0 AS AvailableBasedOnExpectedReceipts
		|	FROM
		|		SelectedOrders_ AS Orders
		|			
		|			LEFT JOIN InformationRegister.InventoryAllocation AS InventoryAllocation
		|			ON InventoryAllocation.DemandCharacteristic IN(
		|					VALUE(Enum.DemandCharacteristics.ReserveAsReceived),
		|					VALUE(Enum.DemandCharacteristics.ReserveUponReceiptFromLocked))
		|			 AND InventoryAllocation.InventoryState IN(
		|					VALUE(Enum.InventoryStates.InStock),
		|					VALUE(Enum.InventoryStates.AvailablePendingUnlocking),
		|					VALUE(Enum.InventoryStates.AvailableNotSubjectToUnlocking))
		|			 AND InventoryAllocation.Products = Orders.Products
		|			 AND InventoryAllocation.Characteristic = Orders.Characteristic
		|			 AND InventoryAllocation.Warehouse = Orders.Warehouse
		|			 AND InventoryAllocation.Purpose = Orders.Purpose
		|			 AND InventoryAllocation.ShipmentOrder = Orders.ShipmentOrder
		|WHERE
		|	NOT InventoryAllocation.Products IS NULL
		|	
		|	UNION ALL
		|	
		// Free stock balance.
		|	SELECT
		|		AvailableStock.Products AS Products,
		|		AvailableStock.Characteristic AS Characteristic,
		|		AvailableStock.Warehouse AS Warehouse,
		|		AvailableStock.Purpose AS Purpose,
		|		AvailableStock.ControlledLotReference AS ControlledLotReference,
		|		AvailableStock.QuantityForShipAction AS Available,
		|		AvailableStock.QuantityForActionIsReservedAsItBecomesAvailable AS AvailableBasedOnExpectedReceipts
		|	FROM
		|		SelectedProductItems AS Goods
		|			
		|			LEFT JOIN TemporaryTableOfBalances AS AvailableStock
		|			ON AvailableStock.Products = Goods.Products
		|			 AND AvailableStock.Characteristic = Goods.Characteristic
		|			 AND AvailableStock.Warehouse = Goods.Warehouse
		|			 AND AvailableStock.Purpose = Goods.Purpose
		|			 AND AvailableStock.ControlledLotReference = Goods.ControlledLotReference
		|WHERE
		|	NOT AvailableStock.Products IS NULL) AS Changes
		|GROUP BY
		|	Changes.Products,
		|	Changes.Characteristic,
		|	Changes.Warehouse,
		|	Changes.Purpose,
		|	Changes.ControlledLotReference
		|HAVING
		|	SUM(Changes.Available) <> 0
		|		OR SUM(Changes.AvailableBasedOnExpectedReceipts) <> 0
		|INDEX BY
		|	Products, Characteristic, Warehouse, Purpose";
	Texts.Add(QueryText);
	Query.Text = StrConcat(Texts, Common.QueryBatchSeparator());
	Query.Execute();
	
	ProvisionInDocumentsOverridable.AddTemporaryTableAvailableBalances(TempTablesManager, AdditionalParameters);
	
	TableName = ?(TempTablesManager.Tables.Find("Available2Balance") <> Undefined, "Available2Balance", "BalanceTable");
	WarehouseRemnants = TempTablesManager.Tables[TableName].GetData().Unload();
	
	Return WarehouseRemnants;
	
EndFunction

Procedure AddTemporaryTablesToGetBalances(
			Query,
			SeparateAndNonSeparateBalances,
			CorrectionOfRegisteredRecords,
			CancelShipInLine,
			TakeIntoAccountReserves)
	
	// The manager should have the following temporary tables:
	// - The time table of the document
	// - Time table of the document movement
	// - The time table of the movement of the document for the selected lines
	// - Time table of the published documents for the selected lines
	
	Query.SetParameter("SeparateAndNonSeparateBalances", SeparateAndNonSeparateBalances);
	Query.SetParameter("TakeIntoAccountReserves", TakeIntoAccountReserves);
	
	If CorrectionOfRegisteredRecords = Undefined Then
		
		Query.Text =
			"SELECT
			|	UNDEFINED AS Products,
			|	UNDEFINED AS Characteristic,
			|	UNDEFINED AS Warehouse,
			|	UNDEFINED AS Purpose,
			|	UNDEFINED AS ControlledLotReference,
			|	UNDEFINED AS ShipmentOrder,
			|	0 AS Ship,
			|	0 AS ToReserve_,
			|	0 AS ReserveAsReceived
			|INTO TemporaryTableAdjustingDocumentRegisteredRecords
			|WHERE
			|	FALSE";
		
	Else
		Query.SetParameter("CorrectionOfRegisteredRecords", CorrectionOfRegisteredRecords.RegisterRecordTable);
		Query.Text =
			"SELECT
			|	RegisterRecords.Products AS Products,
			|	RegisterRecords.Characteristic AS Characteristic,
			|	RegisterRecords.Warehouse AS Warehouse,
			|	RegisterRecords.Purpose AS Purpose,
			|	VALUE(Catalog.ControlledLots.EmptyRef) AS ControlledLotReference,
			|	RegisterRecords.OrderDocument AS ShipmentOrder,
			|	CASE
			|		WHEN RegisterRecords.RecordType = VALUE(AccumulationRecordType.Receipt)
			|			THEN -RegisterRecords.InStock
			|		ELSE RegisterRecords.InStock
			|	END AS Ship,
			|	CASE
			|		WHEN RegisterRecords.RecordType = VALUE(AccumulationRecordType.Receipt)
			|			THEN RegisterRecords.ReserveAtWarehouse
			|		ELSE -RegisterRecords.ReserveAtWarehouse
			|	END AS ToReserve_,
			|	CASE
			|		WHEN RegisterRecords.RecordType = VALUE(AccumulationRecordType.Receipt)
			|			THEN RegisterRecords.ReserveAsReceived
			|		ELSE -RegisterRecords.ReserveAsReceived
			|	END AS ReserveAsReceived
			|INTO TemporaryTableAdjustingDocumentRegisteredRecords
			|FROM
			|	&CorrectionOfRegisteredRecords AS RegisterRecords
			|WHERE
			|	RegisterRecords.InStock <> 0
			|		OR RegisterRecords.ReserveAtWarehouse <> 0
			|		OR RegisterRecords.ReserveAsReceived <> 0
			|INDEX BY
			|	Products, Characteristic, Purpose";
	EndIf;
	Query.Execute();
	
	Query.Text =
		"SELECT DISTINCT
		|	Table.Products AS Products,
		|	Table.Characteristic AS Characteristic,
		|	CASE
		|		WHEN CAST(Table.Products AS Catalog.Products).ItemsType IN(
		|				VALUE(Enum.ItemsTypes.OwnGoods),
		|				VALUE(Enum.ItemsTypes.ReusablePackage))
		|			THEN Table.Warehouse
		|		ELSE Table.Department
		|	END AS Warehouse,
		|	Table.ShipmentOrder AS ShipmentOrder,
		|	Table.WithAssignment AS WithAssignment,
		|	Table.Recorder AS Recorder,
		|	CASE
		|		WHEN Table.WithAssignment
		|			THEN
		|				CASE
		|					WHEN Table.Purpose = VALUE(Catalog.Assignments.EmptyRef)
		|						THEN UNDEFINED
		|					ELSE Table.Purpose
		|				END
		|		ELSE VALUE(Catalog.Assignments.EmptyRef)
		|	END AS Purpose,
		|	Table.ControlledLotReference AS ControlledLotReference
		|INTO SelectedOrdersBasedOnWarehouse
		|FROM
		|	TemporaryDocumentDataTableForSelectedRows AS Table
		|
		|UNION ALL
		|
		|SELECT DISTINCT
		|	Table.Products    AS Products,
		|	Table.Characteristic  AS Characteristic,
		|	CASE
		|		WHEN CAST(Table.Products AS Catalog.Products).ItemsType IN(
		|				VALUE(Enum.ItemsTypes.OwnGoods),
		|				VALUE(Enum.ItemsTypes.ReusablePackage))
		|			THEN Table.Warehouse
		|		ELSE Table.Department
		|	END AS Warehouse,
		|	Table.ShipmentOrder AS ShipmentOrder,
		|	NOT Table.WithAssignment AS WithAssignment,
		|	Table.Recorder AS Recorder,
		|	CASE
		|		WHEN NOT Table.WithAssignment
		|			THEN
		|				CASE
		|					WHEN Table.Purpose = VALUE(Catalog.Assignments.EmptyRef)
		|						THEN UNDEFINED
		|					ELSE Table.Purpose
		|				END
		|		ELSE VALUE(Catalog.Assignments.EmptyRef)
		|	END AS Purpose,
		|	Table.ControlledLotReference AS ControlledLotReference
		|FROM
		|	TemporaryDocumentDataTableForSelectedRows AS Table
		|WHERE
		|	&SeparateAndNonSeparateBalances
		|;
		|
		|//////////////////////////////////////////////
		|SELECT DISTINCT
		|	Orders.Products AS Products,
		|	Orders.Characteristic AS Characteristic,
		|	Orders.Warehouse AS Warehouse,
		|	Orders.Purpose AS Purpose,
		|	Orders.ControlledLotReference AS ControlledLotReference,
		|	Orders.WithAssignment AS WithAssignment
		|INTO SelectedProductsBasedOnWarehouse
		|FROM
		|	SelectedOrdersBasedOnWarehouse AS Orders
		|;
		|
		|//////////////////////////////////////////////
		|SELECT DISTINCT
		|	Orders.Products AS Products,
		|	Orders.Characteristic AS Characteristic,
		|	Orders.Purpose AS Purpose,
		|	Orders.ShipmentOrder AS ShipmentOrder,
		|	Orders.WithAssignment AS WithAssignment,
		|	Orders.Recorder AS Recorder
		|INTO SelectedOrders_
		|FROM
		|	SelectedOrdersBasedOnWarehouse AS Orders
		|;
		|
		|//////////////////////////////////////////////
		|SELECT DISTINCT
		|	Orders.Products AS Products,
		|	Orders.Characteristic AS Characteristic,
		|	Orders.Purpose AS Purpose,
		|	Orders.WithAssignment AS WithAssignment
		|INTO SelectedProductItems
		|FROM
		|	SelectedProductsBasedOnWarehouse AS Orders
		|;
		|
		|//////////////////////////////////////////////
		|SELECT DISTINCT
		|	DocumentData.Recorder AS Recorder
		|INTO AllRegistrars
		|FROM
		|	TemporaryDocumentDataTable AS DocumentData
		|INDEX BY
		|	Recorder
		|;
		|
		|//////////////////////////////////////////////
		|SELECT DISTINCT
		|	Orders.Products AS Products,
		|	Orders.Characteristic AS Characteristic,
		|	Orders.Purpose AS Purpose,
		|	Orders.ShipmentOrder AS ShipmentOrder
		|INTO DedicatedOrdersWithoutRegistrar
		|FROM
		|	SelectedOrders_ AS Orders
		|INDEX BY
		|	Products, Characteristic, Purpose, ShipmentOrder";
	
	Query.Execute();
	
	Query.Text =
		"SELECT
		|	RegisterRecords.Products AS Products,
		|	RegisterRecords.Characteristic AS Characteristic,
		|	RegisterRecords.Warehouse AS Warehouse,
		|	RegisterRecords.Purpose AS Purpose,
		|	RegisterRecords.OrderDocument AS OrderDocument,
		|	RegisterRecords.OrderToShip AS OrderToShip,
		|	RegisterRecords.RecordType AS RecordType,
		|	RegisterRecords.InStock AS InStock,
		|	RegisterRecords.LockedInStock AS LockedInStock,
		|	RegisterRecords.ReserveAtWarehouse AS ReserveAtWarehouse,
		|	RegisterRecords.ReserveAsReceived AS ReserveAsReceived,
		|	RegisterRecords.ReserveAtWarehouseFromLocked AS ReserveAtWarehouseFromLocked,
		|	RegisterRecords.ReserveUponReceiptFromLocked AS ReserveUponReceiptFromLocked,
		|	RegisterRecords.Active AS Active
		|INTO LoggerRegisteredRecords_
		|FROM
		|	AccumulationRegister.InventoryAndDemands AS RegisterRecords
		|WHERE
		|	RegisterRecords.Recorder IN(
		|		SELECT
		|			Table.Recorder AS Recorder
		|		FROM
		|			AllRegistrars AS Table)
		|
		|INDEX BY
		|	Products, Characteristic, Purpose, Active";
	
	SetPrivilegedMode(True);
	Query.Execute();
	SetPrivilegedMode(False);
	
	Query.Text =
		"SELECT
		|	Adjusting.Products AS Products,
		|	Adjusting.Characteristic AS Characteristic,
		|	Adjusting.Warehouse AS Warehouse,
		|	Adjusting.Purpose AS Purpose,
		|	Adjusting.ControlledLotReference AS ControlledLotReference,
		|	SUM(Adjusting.InStock) AS InStock,
		|	SUM(Adjusting.AvailableAndExpected) AS AvailableAndExpected
		|INTO AdjustingBalance
		|FROM
		|	NestedQueryOverridable AS Adjusting
		|GROUP BY
		|	Adjusting.Products,
		|	Adjusting.Characteristic,
		|	Adjusting.Warehouse,
		|	Adjusting.Purpose,
		|	Adjusting.ControlledLotReference";
	
	Text =
		// Imitation of the movements of the edited document.
		"SELECT
		|	RegisterRecords.Products AS Products,
		|	RegisterRecords.Characteristic AS Characteristic,
		|	RegisterRecords.Warehouse AS Warehouse,
		|	RegisterRecords.Purpose AS Purpose,
		|	VALUE(Catalog.ControlledLots.EmptyRef) AS ControlledLotReference,
		|	-CASE
		|		WHEN RegisterRecords.RecordType = VALUE(AccumulationRecordType.Receipt)
		|			THEN - (RegisterRecords.InStock - RegisterRecords.LockedInStock)
		|		ELSE RegisterRecords.InStock - RegisterRecords.LockedInStock
		|	END
		|	-CASE
		|		WHEN RegisterRecords.RecordType = VALUE(AccumulationRecordType.Receipt)
		|			THEN RegisterRecords.ReserveAtWarehouse
		|		ELSE -RegisterRecords.ReserveAtWarehouse
		|	END AS InStock,
		|	-CASE
		|		WHEN RegisterRecords.RecordType = VALUE(AccumulationRecordType.Receipt)
		|			THEN - (RegisterRecords.InStock - RegisterRecords.LockedInStock)
		|		ELSE RegisterRecords.InStock - RegisterRecords.LockedInStock
		|	END
		|	-CASE
		|		WHEN RegisterRecords.RecordType = VALUE(AccumulationRecordType.Receipt)
		|			THEN RegisterRecords.ReserveAtWarehouse + RegisterRecords.ReserveAsReceived
		|		ELSE - RegisterRecords.ReserveAtWarehouse - RegisterRecords.ReserveAsReceived
		|	END AS AvailableAndExpected
		|FROM
		|	SelectedProductItems AS Goods
		|		
		|		LEFT JOIN TemporaryTableOfDocumentRegisteredRecords AS RegisterRecords
		|		ON RegisterRecords.Products   = Goods.Products
		|		 AND RegisterRecords.Characteristic = Goods.Characteristic
		|		 AND RegisterRecords.Purpose     = Goods.Purpose
		|WHERE
		|	NOT RegisterRecords.Products IS NULL
		|
		|UNION ALL
		|
		// Simulation of the Registered Records of the edited document for controlled parties.
		|SELECT
		|	RegisterRecords.Products AS Products,
		|	RegisterRecords.Characteristic AS Characteristic,
		|	RegisterRecords.Warehouse AS Warehouse,
		|	RegisterRecords.Purpose AS Purpose,
		|	CASE
		|		WHEN RegisterRecords.OrderToShip <> UNDEFINED
		|			THEN RegisterRecords.OrderToShip
		|		ELSE RegisterRecords.OrderDocument
		|	END AS ControlledLotReference,
		|	-CASE
		|		WHEN RegisterRecords.RecordType = VALUE(AccumulationRecordType.Receipt)
		|			THEN -RegisterRecords.LockedInStock
		|		ELSE RegisterRecords.LockedInStock
		|	END
		|	-CASE
		|		WHEN RegisterRecords.RecordType = VALUE(AccumulationRecordType.Receipt)
		|			THEN RegisterRecords.ReserveAtWarehouseFromLocked
		|		ELSE -RegisterRecords.ReserveAtWarehouseFromLocked
		|	END AS InStock,
		|	-CASE
		|		WHEN RegisterRecords.RecordType = VALUE(AccumulationRecordType.Receipt)
		|			THEN -RegisterRecords.LockedInStock
		|		ELSE RegisterRecords.LockedInStock
		|	END
		|	-CASE
		|		WHEN RegisterRecords.RecordType = VALUE(AccumulationRecordType.Receipt)
		|			THEN RegisterRecords.ReserveAtWarehouseFromLocked + RegisterRecords.ReserveUponReceiptFromLocked
		|		ELSE - RegisterRecords.ReserveAtWarehouseFromLocked - RegisterRecords.ReserveUponReceiptFromLocked
		|	END AS AvailableAndExpected
		|FROM
		|	SelectedProductItems AS Goods
		|		
		|		LEFT JOIN TemporaryTableOfDocumentRegisteredRecords AS RegisterRecords
		|		ON RegisterRecords.Products   = Goods.Products
		|		 AND RegisterRecords.Characteristic = Goods.Characteristic
		|		 AND RegisterRecords.Purpose     = Goods.Purpose
		|WHERE
		|	NOT RegisterRecords.Products IS NULL
		|
		|UNION ALL
		|
		// A table for correcting document movements.
		|SELECT
		|	RegisterRecords.Products AS Products,
		|	RegisterRecords.Characteristic AS Characteristic,
		|	RegisterRecords.Warehouse AS Warehouse,
		|	RegisterRecords.Purpose AS Purpose,
		|	RegisterRecords.ControlledLotReference AS ControlledLotReference,
		|	- RegisterRecords.Ship - RegisterRecords.ToReserve_ AS InStock,
		|	- RegisterRecords.Ship - RegisterRecords.ToReserve_ - RegisterRecords.ReserveAsReceived AS AvailableAndExpected
		|FROM
		|	SelectedProductItems AS Goods
		|		
		|		LEFT JOIN TemporaryTableAdjustingDocumentRegisteredRecords AS RegisterRecords
		|		ON RegisterRecords.Products = Goods.Products
		|		 AND RegisterRecords.Characteristic = Goods.Characteristic
		|		 AND RegisterRecords.Purpose = Goods.Purpose
		|WHERE
		|	NOT RegisterRecords.Products IS NULL
		|
		|UNION ALL
		|
		// Reverse recorded document movements.
		|SELECT
		|	RegisterRecords.Products AS Products,
		|	RegisterRecords.Characteristic AS Characteristic,
		|	RegisterRecords.Warehouse AS Warehouse,
		|	RegisterRecords.Purpose AS Purpose,
		|	VALUE(Catalog.ControlledLots.EmptyRef) AS ControlledLotReference,
		|	CASE
		|		WHEN RegisterRecords.RecordType = VALUE(AccumulationRecordType.Expense)
		|			THEN RegisterRecords.InStock - RegisterRecords.LockedInStock
		|		ELSE - (RegisterRecords.InStock - RegisterRecords.LockedInStock)
		|	END
		|		+ CASE
		|			WHEN NOT &TakeIntoAccountReserves
		|				THEN 0
		|			WHEN RegisterRecords.RecordType = VALUE(AccumulationRecordType.Receipt)
		|				THEN RegisterRecords.ReserveAtWarehouse
		|			ELSE - RegisterRecords.ReserveAtWarehouse
		|		END AS InStock,
		|	CASE
		|		WHEN RegisterRecords.RecordType = VALUE(AccumulationRecordType.Expense)
		|			THEN RegisterRecords.InStock - RegisterRecords.LockedInStock
		|		ELSE -(RegisterRecords.InStock - RegisterRecords.LockedInStock)
		|	END
		|		+ CASE
		|			WHEN NOT &TakeIntoAccountReserves
		|				THEN 0
		|			WHEN RegisterRecords.RecordType = VALUE(AccumulationRecordType.Receipt)
		|				THEN RegisterRecords.ReserveAtWarehouse + RegisterRecords.ReserveAsReceived
		|			ELSE - RegisterRecords.ReserveAtWarehouse - RegisterRecords.ReserveAsReceived
		|		END AS AvailableAndExpected
		|FROM
		|	SelectedProductItems AS Orders
		|		
		|		LEFT JOIN LoggerRegisteredRecords_ AS RegisterRecords
		|		ON RegisterRecords.Products    = Orders.Products
		|		 AND RegisterRecords.Characteristic  = Orders.Characteristic
		|		 AND RegisterRecords.Purpose      = Orders.Purpose
		|		 AND RegisterRecords.Active
		|WHERE
		|	NOT RegisterRecords.Products IS NULL
		|
		|UNION ALL
		|
		// Storno of recorded Registered Records of the document on controlled Lots references.
		|SELECT
		|	RegisterRecords.Products AS Products,
		|	RegisterRecords.Characteristic AS Characteristic,
		|	RegisterRecords.Warehouse AS Warehouse,
		|	RegisterRecords.Purpose AS Purpose,
		|	CASE
		|		WHEN RegisterRecords.OrderToShip <> UNDEFINED
		|			THEN RegisterRecords.OrderToShip
		|		ELSE RegisterRecords.OrderDocument
		|	END AS ControlledLotReference,
		|	CASE
		|		WHEN RegisterRecords.RecordType = VALUE(AccumulationRecordType.Expense)
		|			THEN RegisterRecords.LockedInStock
		|		ELSE - RegisterRecords.LockedInStock
		|	END
		|		+ CASE
		|			WHEN NOT &TakeIntoAccountReserves
		|				THEN 0
		|			WHEN RegisterRecords.RecordType = VALUE(AccumulationRecordType.Receipt)
		|				THEN RegisterRecords.ReserveAtWarehouseFromLocked
		|			ELSE - RegisterRecords.ReserveAtWarehouseFromLocked
		|		END AS InStock,
		|	CASE
		|		WHEN RegisterRecords.RecordType = VALUE(AccumulationRecordType.Expense)
		|			THEN RegisterRecords.LockedInStock
		|		ELSE - RegisterRecords.LockedInStock
		|	END
		|		+ CASE
		|			WHEN NOT &TakeIntoAccountReserves
		|				THEN 0
		|			WHEN RegisterRecords.RecordType = VALUE(AccumulationRecordType.Receipt)
		|				THEN RegisterRecords.ReserveAtWarehouseFromLocked + RegisterRecords.ReserveUponReceiptFromLocked
		|			ELSE - RegisterRecords.ReserveAtWarehouseFromLocked - RegisterRecords.ReserveUponReceiptFromLocked
		|		END AS AvailableAndExpected
		|FROM
		|	SelectedProductItems AS Orders
		|		
		|		LEFT JOIN LoggerRegisteredRecords_ AS RegisterRecords
		|		ON RegisterRecords.Products = Orders.Products
		|		 AND RegisterRecords.Characteristic = Orders.Characteristic
		|		 AND RegisterRecords.Purpose = Orders.Purpose
		|		 AND RegisterRecords.Active
		|WHERE
		|	NOT RegisterRecords.Products IS NULL
		|
		|UNION ALL
		|
		// "Soft" reserve under the order.
		|SELECT
		|	Set.Products AS Products,
		|	Set.Characteristic AS Characteristic,
		|	Set.Warehouse AS Warehouse,
		|	Set.Purpose AS Purpose,
		|	Set.ControlledLotReference AS ControlledLotReference,
		|	SUM(Set.Count) AS InStock,
		|	0 AS AvailableAndExpected
		|FROM(
		|	SELECT
		|		InventoryAllocation.Products AS Products,
		|		InventoryAllocation.Characteristic AS Characteristic,
		|		InventoryAllocation.Warehouse AS Warehouse,
		|		InventoryAllocation.Purpose AS Purpose,
		|		CASE
		|			WHEN InventoryAllocation.InventoryState IN(
		|					VALUE(Enum.InventoryStates.AvailablePendingUnlocking),
		|					VALUE(Enum.InventoryStates.AvailableNotSubjectToUnlocking))
		|				THEN InventoryAllocation.ReceiptOrder
		|			ELSE VALUE(Catalog.ControlledLots.EmptyRef)
		|		END AS ControlledLotReference,
		|		InventoryAllocation.ShipmentOrder AS ShipmentOrder,
		|		InventoryAllocation.Count AS Count
		|	FROM
		|		InformationRegister.InventoryAllocation AS InventoryAllocation
		|	WHERE
		|		&TakeIntoAccountReserves
		|		AND InventoryAllocation.DemandCharacteristic IN(
		|			VALUE(Enum.DemandCharacteristics.ReserveAsReceived),
		|			VALUE(Enum.DemandCharacteristics.ReserveUponReceiptFromLocked))
		|		AND InventoryAllocation.InventoryState IN(
		|			VALUE(Enum.InventoryStates.InStock),
		|			VALUE(Enum.InventoryStates.AvailablePendingUnlocking),
		|			VALUE(Enum.InventoryStates.AvailableNotSubjectToUnlocking))
		|		AND (InventoryAllocation.Products,
		|				InventoryAllocation.Characteristic,
		|				InventoryAllocation.Purpose,
		|				InventoryAllocation.ShipmentOrder) IN(
		|			SELECT
		|				TheOrdersTable.Products AS Products,
		|				TheOrdersTable.Characteristic AS Characteristic,
		|				TheOrdersTable.Purpose AS Purpose,
		|				TheOrdersTable.ShipmentOrder AS ShipmentOrder
		|			FROM
		|				SelectedOrders_ AS TheOrdersTable)
		|	
		// For an unrecorded order to the processor, the shipment order is empty, but there are registrars - stages.
		|	UNION ALL
		|	
		|	SELECT
		|		TheOrdersTable.Products AS Products,
		|		TheOrdersTable.Characteristic AS Characteristic,
		|		InventoryAllocation.Warehouse AS Warehouse,
		|		TheOrdersTable.Purpose AS Purpose,
		|		CASE
		|			WHEN InventoryAllocation.InventoryState IN(
		|					VALUE(Enum.InventoryStates.AvailablePendingUnlocking),
		|					VALUE(Enum.InventoryStates.AvailableNotSubjectToUnlocking))
		|				THEN InventoryAllocation.ReceiptOrder
		|			ELSE VALUE(Catalog.ControlledLots.EmptyRef)
		|		END AS ControlledLotReference,
		|		TheOrdersTable.ShipmentOrder AS ShipmentOrder,
		|		InventoryAllocation.Count AS Count
		|	FROM
		|		DedicatedOrdersWithoutRegistrar AS TheOrdersTable
		|			INNER JOIN AllRegistrars AS AllRegistrars
		|			ON AllRegistrars.Recorder <> TheOrdersTable.ShipmentOrder
		|			INNER JOIN InformationRegister.InventoryAllocation AS InventoryAllocation
		|			ON InventoryAllocation.Products    = TheOrdersTable.Products
		|			 AND InventoryAllocation.Characteristic  = TheOrdersTable.Characteristic
		|			 AND InventoryAllocation.Purpose      = TheOrdersTable.Purpose
		|			AND InventoryAllocation.DemandCharacteristic IN(
		|				VALUE(Enum.DemandCharacteristics.ReserveAsReceived),
		|				VALUE(Enum.DemandCharacteristics.ReserveUponReceiptFromLocked))
		|			AND InventoryAllocation.InventoryState IN(
		|				VALUE(Enum.InventoryStates.InStock),
		|				VALUE(Enum.InventoryStates.AvailablePendingUnlocking),
		|				VALUE(Enum.InventoryStates.AvailableNotSubjectToUnlocking))
		|			 AND InventoryAllocation.ShipmentOrder = AllRegistrars.Recorder
		|	WHERE
		|		&TakeIntoAccountReserves) AS Set
		|	GROUP BY
		|		Set.Products,
		|		Set.Characteristic,
		|		Set.Warehouse,
		|		Set.Purpose,
		|		Set.ControlledLotReference,
		|		Set.ShipmentOrder";
		
	If CancelShipInLine Then
		
		Texts = New Array();
		Texts.Add(Text);
		Text =
			// Reverse simulation of the movements of the selected lines of the document.
			"SELECT
			|	RegisterRecords.Products AS Products,
			|	RegisterRecords.Characteristic AS Characteristic,
			|	RegisterRecords.Warehouse AS Warehouse,
			|	RegisterRecords.Purpose AS Purpose,
			|	VALUE(Catalog.ControlledLots.EmptyRef) AS ControlledLotReference,
			|	CASE
			|		WHEN RegisterRecords.RecordType = VALUE(AccumulationRecordType.Expense)
			|			THEN RegisterRecords.InStock - RegisterRecords.LockedInStock
			|		ELSE - (RegisterRecords.InStock - RegisterRecords.LockedInStock)
			|	END
			|		+ CASE
			|			WHEN NOT &TakeIntoAccountReserves
			|				THEN 0
			|			WHEN RegisterRecords.RecordType = VALUE(AccumulationRecordType.Receipt)
			|				THEN RegisterRecords.ReserveAtWarehouse
			|			ELSE - RegisterRecords.ReserveAtWarehouse
			|		END AS InStock,
			|	CASE
			|		WHEN RegisterRecords.RecordType = VALUE(AccumulationRecordType.Expense)
			|			THEN RegisterRecords.InStock - RegisterRecords.LockedInStock
			|		ELSE - (RegisterRecords.InStock - RegisterRecords.LockedInStock)
			|	END
			|		+ CASE
			|			WHEN NOT &TakeIntoAccountReserves
			|				THEN 0
			|			WHEN RegisterRecords.RecordType = VALUE(AccumulationRecordType.Receipt)
			|				THEN RegisterRecords.ReserveAtWarehouse + RegisterRecords.ReserveAsReceived
			|			ELSE - RegisterRecords.ReserveAtWarehouse - RegisterRecords.ReserveAsReceived
			|		END AS AvailableAndExpected
			|FROM
			|	SelectedProductItems AS Goods
			|		
			|		LEFT JOIN TemporaryTableOfDocumentRegisteredRecordsForSelectedRows AS RegisterRecords
			|		ON RegisterRecords.Products   = Goods.Products
			|		 AND RegisterRecords.Characteristic = Goods.Characteristic
			|		 AND RegisterRecords.Purpose     = Goods.Purpose
			|WHERE
			|	NOT RegisterRecords.Products IS NULL
			|
			|UNION ALL
			|
			// Storno simulations of Registered Records of selected lines of the document for controlled parties.
			|SELECT
			|	RegisterRecords.Products AS Products,
			|	RegisterRecords.Characteristic AS Characteristic,
			|	RegisterRecords.Warehouse AS Warehouse,
			|	RegisterRecords.Purpose AS Purpose,
			|	CASE
			|		WHEN RegisterRecords.OrderToShip <> UNDEFINED
			|			THEN RegisterRecords.OrderToShip
			|		ELSE RegisterRecords.OrderDocument
			|	END AS ControlledLotReference,
			|	CASE
			|		WHEN RegisterRecords.RecordType = VALUE(AccumulationRecordType.Expense)
			|			THEN RegisterRecords.LockedInStock
			|		ELSE - RegisterRecords.LockedInStock
			|	END
			|		+ CASE
			|			WHEN NOT &TakeIntoAccountReserves
			|				THEN 0
			|			WHEN RegisterRecords.RecordType = VALUE(AccumulationRecordType.Receipt)
			|				THEN RegisterRecords.ReserveAtWarehouseFromLocked
			|			ELSE - RegisterRecords.ReserveAtWarehouseFromLocked
			|		END AS InStock,
			|	CASE
			|		WHEN RegisterRecords.RecordType = VALUE(AccumulationRecordType.Expense)
			|			THEN RegisterRecords.LockedInStock
			|		ELSE - RegisterRecords.LockedInStock
			|	END
			|		+ CASE
			|			WHEN NOT &TakeIntoAccountReserves
			|				THEN 0
			|			WHEN RegisterRecords.RecordType = VALUE(AccumulationRecordType.Receipt)
			|				THEN RegisterRecords.ReserveAtWarehouseFromLocked + RegisterRecords.ReserveUponReceiptFromLocked
			|			ELSE - RegisterRecords.ReserveAtWarehouseFromLocked - RegisterRecords.ReserveUponReceiptFromLocked
			|		END AS AvailableAndExpected
			|FROM
			|	SelectedProductItems AS Goods
			|		
			|		LEFT JOIN TemporaryTableOfDocumentRegisteredRecordsForSelectedRows AS RegisterRecords
			|		ON RegisterRecords.Products   = Goods.Products
			|		 AND RegisterRecords.Characteristic = Goods.Characteristic
			|		 AND RegisterRecords.Purpose     = Goods.Purpose
			|WHERE
			|	NOT RegisterRecords.Products IS NULL";
		Texts.Add(Text);
		Text = StrConcat(Texts, TMCommonUse.QuerySeparatorInJoin());
	EndIf;
	
	Query.Text = StrReplace(Query.Text, "NestedQueryOverridable", StrTemplate("(%1)", Text));
	Query.Execute();
	
EndProcedure

Function LeftoversForSettingActions(Query, GroupWarehouses_)
	
	// The manager should have the following temporary tables:
	// - Highlighted by the accounting table
	// - Adjustment of the stat
	SetPrivilegedMode(True);
	
	Query.SetParameter("GroupWarehouses_", GroupWarehouses_);
	UseWarehouseFromDocumentLine = GroupWarehouses_ = Undefined Or GroupWarehouses_.Count() = 0;
	Query.SetParameter("UseWarehouseFromDocumentLine", UseWarehouseFromDocumentLine);
	Query.SetParameter("PostWithoutReserveControl", SessionParameters.PostWithoutControlOfGoodsReservesUnderOrders);
	Texts = New Array();
	QueryText =
		"SELECT DISTINCT
		|	Goods.Products AS Products,
		|	Goods.Characteristic AS Characteristic,
		|	ISNULL(GroupWarehouses_.Ref, Goods.Warehouse) AS Warehouse,
		|	Goods.Purpose AS Purpose,
		|	Goods.ControlledLotReference AS ControlledLotReference
		|INTO ProductFilterTable
		|FROM
		|	SelectedProductsBasedOnWarehouse AS Goods
		|		
		|		LEFT JOIN Catalog.Warehouses AS GroupWarehouses_
		|		ON GroupWarehouses_.Ref IN(&GroupWarehouses_)
		|			
		|INDEX BY
		|	Products, Characteristic, Warehouse, Purpose, ControlledLotReference";
	Texts.Add(QueryText);
	
	QueryText =
		"SELECT ALLOWED
		|	Inventories.Products AS Products,
		|	Inventories.Characteristic AS Characteristic,
		|	Inventories.Warehouse AS Warehouse,
		|	Inventories.Purpose AS Purpose,
		|	Inventories.OrderDocument AS OrderDocument,
		|	Inventories.LockedInStockBalance AS LockedInStockBalance,
		|	Inventories.LockedReceiptBalance AS LockedReceiptBalance,
		|	Inventories.ToUnlockBalance AS ToUnlockBalance,
		|	Inventories.ReserveAtWarehouseFromLockedBalance AS ReserveAtWarehouseFromLockedBalance,
		|	Inventories.ReserveUponReceiptFromLockedBalance AS ReserveUponReceiptFromLockedBalance
		|INTO InventoryAndNeedsBalanceOfControlledLotsReference
		|FROM
		|	AccumulationRegister.InventoryAndDemands.Balance(,
		|		(Products, Characteristic, Warehouse, Purpose) IN(
		|			SELECT
		|				Filter.Products AS Products,
		|				Filter.Characteristic AS Characteristic,
		|				Filter.Warehouse AS Warehouse,
		|				Filter.Purpose AS Purpose
		|			FROM
		|				ProductFilterTable AS Filter)) AS Inventories
		|INDEX BY
		|	Products, Characteristic, Warehouse, Purpose
		|;
		|
		|//////////////////////////////////////////////////
		|SELECT ALLOWED
		|	Inventories.Products AS Products,
		|	Inventories.Characteristic AS Characteristic,
		|	Inventories.Warehouse AS Warehouse,
		|	Inventories.Purpose AS Purpose,
		|	Inventories.InStockBalance AS InStockBalance,
		|	Inventories.LockedInStockBalance AS LockedInStockBalance,
		|	Inventories.OrderedBalance AS OrderedBalance,
		|	Inventories.Received_1Balance AS Received_1Balance,
		|	Inventories.LockedReceiptBalance AS LockedReceiptBalance,
		|	Inventories.ReserveAtWarehouseBalance AS ReserveAtWarehouseBalance,
		|	Inventories.ReserveAsReceivedBalance AS ReserveAsReceivedBalance,
		|	Inventories.SnoozeReservationBalance AS SnoozeReservationBalance,
		|	Inventories.ToSupplyBalance AS ToSupplyBalance,
		|	Inventories.NotProvideBalance AS NotProvideBalance
		|INTO InventoryAndDemandsBalance
		|FROM
		|	AccumulationRegister.InventoryAndDemands.Balance(,
		|		(Products, Characteristic, Warehouse, Purpose) IN(
		|			SELECT
		|				Filter.Products AS Products,
		|				Filter.Characteristic AS Characteristic,
		|				Filter.Warehouse AS Warehouse,
		|				Filter.Purpose AS Purpose
		|			FROM
		|				ProductFilterTable AS Filter)) AS Inventories
		|INDEX BY
		|	Products, Characteristic, Warehouse, Purpose
		|;
		|
		|//////////////////////////////////////////////////
		|SELECT
		|	Calculation.Products AS Products,
		|	Calculation.Characteristic AS Characteristic,
		|	Calculation.Warehouse AS Warehouse,
		|	Calculation.Purpose AS Purpose,
		|	Calculation.ControlledLotReference AS ControlledLotReference,
		|	CASE
		|		WHEN &PostWithoutReserveControl
		|			THEN
		|				Calculation.QuantityWithoutControlOfReservesForShipAction
		|		ELSE Calculation.QuantityForShipAction
		|	END AS QuantityForShipAction,
		|	Calculation.QuantityForActionIsReservedAsItBecomesAvailable AS QuantityForActionIsReservedAsItBecomesAvailable
		|INTO BalanceTable
		|FROM
		|	CalculationOfBalancesForSettingActions AS Calculation
		|INDEX BY
		|	Products, Characteristic, Warehouse, Purpose, ControlledLotReference";
	
	TablesNames = NewTableNamesForCalculatingBalancesForSettingActions();
	TablesNames.Balance = "InventoryAndDemandsBalance"; // @query-part-1
	TablesNames.BalanceSheetsOfControlledLotREFERENCES = "InventoryAndNeedsBalanceOfControlledLotsReference"; // @query-part-1
	TablesNames.Analysts = "ProductFilterTable"; // @query-part-1
	TablesNames.Result = "CalculationOfBalancesForSettingActions"; // @query-part-1
	CalculationOfBalancesForSettingActions(QueryText, TablesNames);

	Texts.Add(QueryText);
	
	QueryText =
		"SELECT DISTINCT
		|	Orders.Products AS Products,
		|	Orders.Characteristic AS Characteristic,
		|	Orders.Purpose AS Purpose,
		|	Orders.ControlledLotReference AS ControlledLotReference
		|INTO SelectedGoodsExcludingWarehouse
		|FROM
		|	SelectedProductsBasedOnWarehouse AS Orders
		|INDEX BY
		|	Products, Characteristic, Purpose, ControlledLotReference
		|;
		|
		|//////////////////////////////////////////////
		|SELECT
		|	Balance.Products AS Products,
		|	Balance.Characteristic AS Characteristic,
		|	Balance.Warehouse AS Warehouse,
		|	Balance.Purpose AS Purpose,
		|	Balance.ControlledLotReference AS ControlledLotReference,
		|	SUM(Balance.QuantityForShipAction) AS QuantityForShipAction,
		|	SUM(Balance.QuantityForActionIsReservedAsItBecomesAvailable) AS QuantityForActionIsReservedAsItBecomesAvailable
		|INTO BalancesBeforeOrdering
		|FROM(
		|	SELECT
		|		AdjustingBalance.Products AS Products,
		|		AdjustingBalance.Characteristic AS Characteristic,
		|		AdjustingBalance.Warehouse AS Warehouse,
		|		AdjustingBalance.Purpose AS Purpose,
		|		AdjustingBalance.ControlledLotReference AS ControlledLotReference,
		|		AdjustingBalance.InStock AS QuantityForShipAction,
		|		AdjustingBalance.AvailableAndExpected AS QuantityForActionIsReservedAsItBecomesAvailable
		|	FROM
		|		AdjustingBalance AS AdjustingBalance
		|	
		|	UNION ALL
		|	
		// The free Balance in the group's warehouses.
		|	SELECT
		|		Goods.Products AS Products,
		|		Goods.Characteristic AS Characteristic,
		|		GroupWarehouses_.Ref AS Warehouse,
		|		Goods.Purpose AS Purpose,
		|		Goods.ControlledLotReference AS ControlledLotReference,
		|		CASE
		|			WHEN AvailableStock.QuantityForShipAction > 0
		|				THEN AvailableStock.QuantityForShipAction
		|			ELSE 0
		|		END AS QuantityForShipAction,
		|		CASE
		|			WHEN AvailableStock.QuantityForActionIsReservedAsItBecomesAvailable > 0
		|				THEN AvailableStock.QuantityForActionIsReservedAsItBecomesAvailable
		|			ELSE 0
		|		END AS QuantityForActionIsReservedAsItBecomesAvailable
		|	FROM
		|		SelectedGoodsExcludingWarehouse AS Goods
		|			
		|			INNER JOIN Catalog.Warehouses AS GroupWarehouses_
		|			ON GroupWarehouses_.Ref IN(&GroupWarehouses_)
		|			
		|			INNER JOIN BalanceTable AS AvailableStock
		|			ON AvailableStock.Products = Goods.Products
		|			 AND AvailableStock.Characteristic = Goods.Characteristic
		|			 AND AvailableStock.Warehouse = GroupWarehouses_.Ref
		|			 AND AvailableStock.Purpose = Goods.Purpose
		|			 AND AvailableStock.ControlledLotReference = Goods.ControlledLotReference
		|	WHERE
		|		NOT &UseWarehouseFromDocumentLine
		|	
		|	UNION ALL
		|	
		// The free Balance in the warehouse indicated in the line of the document.
		|	SELECT
		|		Goods.Products AS Products,
		|		Goods.Characteristic AS Characteristic,
		|		Goods.Warehouse AS Warehouse,
		|		Goods.Purpose AS Purpose,
		|		Goods.ControlledLotReference AS ControlledLotReference,
		|		CASE
		|			WHEN AvailableStock.QuantityForShipAction > 0
		|				THEN AvailableStock.QuantityForShipAction
		|			ELSE 0
		|		END AS QuantityForShipAction,
		|		CASE
		|			WHEN AvailableStock.QuantityForActionIsReservedAsItBecomesAvailable > 0
		|				THEN AvailableStock.QuantityForActionIsReservedAsItBecomesAvailable
		|			ELSE 0
		|		END AS QuantityForActionIsReservedAsItBecomesAvailable
		|	FROM
		|		SelectedProductsBasedOnWarehouse AS Goods
		|			
		|			INNER JOIN BalanceTable AS AvailableStock
		|			ON AvailableStock.Products = Goods.Products
		|			 AND AvailableStock.Characteristic = Goods.Characteristic
		|			 AND AvailableStock.Warehouse = Goods.Warehouse
		|			 AND AvailableStock.Purpose = Goods.Purpose
		|			 AND AvailableStock.ControlledLotReference = Goods.ControlledLotReference
		|	WHERE
		|		&UseWarehouseFromDocumentLine) AS Balance
		|GROUP BY
		|	Balance.Products,
		|	Balance.Characteristic,
		|	Balance.Warehouse,
		|	Balance.Purpose,
		|	Balance.ControlledLotReference
		|HAVING
		|	SUM(Balance.QuantityForShipAction) <> 0
		|		OR SUM(Balance.QuantityForActionIsReservedAsItBecomesAvailable) <> 0
		|INDEX BY
		|	Products, Characteristic, Warehouse
		|;
		|
		|////////////////////////////////////////
		|DROP SelectedGoodsExcludingWarehouse
		|;
		|
		|////////////////////////////////////////
		|SELECT DISTINCT
		|	Balance.Products AS Products,
		|	Balance.Characteristic AS Characteristic,
		|	Balance.Warehouse AS Warehouse
		|INTO ProductsForSecurityMethods
		|FROM
		|	BalancesBeforeOrdering AS Balance
		|INDEX BY
		|	Products, Characteristic, Warehouse";
	Texts.Add(QueryText);
	Query.Text = StrConcat(Texts, Common.QueryBatchSeparator());
	Query.Execute();
	
	Texts = New Array();
	Text = InformationRegisters.SupplySchemes.TemporaryTableWaysToEnsure("CALCULATE");
	Text = StrReplace(Text, "TTProducts_1", "ProductsForSecurityMethods");
	Texts.Add(Text);
	Text =
		"SELECT
		|	Balance.Products AS Products,
		|	Balance.Characteristic AS Characteristic,
		|	Balance.Warehouse AS Warehouse,
		|	Balance.Purpose AS Purpose,
		|	Balance.ControlledLotReference AS ControlledLotReference,
		|	Balance.QuantityForShipAction AS Count,
		|	Balance.QuantityForActionIsReservedAsItBecomesAvailable AS QuantityTakingIntoAccountExpectedReceipts,
		|	ISNULL(Setting.SecurityTypePriority, 9999) AS MethodPriority,
		|	Balance.Warehouse.Description NameOfTheWarehouse
		|FROM
		|	BalancesBeforeOrdering AS Balance
		|		
		|		LEFT JOIN TTWaysToEnsure AS Setting
		|		ON Setting.Products = Balance.Products
		|		 AND Setting.Characteristic = Balance.Characteristic
		|		 AND Setting.Warehouse = Balance.Warehouse
		|ORDER BY
		|	MethodPriority, NameOfTheWarehouse";
	Texts.Add(Text);
	Query.Text = StrConcat(Texts, Common.QueryBatchSeparator());
	
	Balance = Query.Execute().Unload();
	
	Return Balance;
	
EndFunction

Function LeftoversForSelectingWarehouses(Query, GroupWarehouses_, PackagingFactor)
	
	// The manager should have the following temporary tables:
	// - Highlighted Inventory accounting
	// - Allocated orders
	// - Correction of the stat
	
	Query.SetParameter("GroupWarehouses_", GroupWarehouses_);
	Query.SetParameter("PackagingFactor", PackagingFactor);
	
	Texts = New Array();
	QueryText =
		"SELECT ALLOWED
		|	Goods.Products AS Products,
		|	Goods.Characteristic AS Characteristic,
		|	Warehouses.Ref AS Warehouse,
		|	Goods.Warehouse AS DocumentWarehouse,
		|	Goods.Purpose AS Purpose,
		|	Goods.ControlledLotReference AS ControlledLotReference,
		|	Goods.WithAssignment AS WithAssignment
		|INTO ProductFilterTable
		|FROM
		|	SelectedProductsBasedOnWarehouse AS Goods
		|		
		|		INNER JOIN Catalog.Warehouses AS Warehouses
		|		ON (NOT Warehouses.DeletionMark
		|			OR Warehouses.Ref = Goods.Warehouse)
		|			AND NOT Warehouses.IsFolder
		|INDEX BY
		|	Products, Characteristic, Warehouse, Purpose, ControlledLotReference";
	Texts.Add(QueryText);
	
	QueryText =
		"SELECT ALLOWED
		|	Inventories.Products AS Products,
		|	Inventories.Characteristic AS Characteristic,
		|	Inventories.Warehouse AS Warehouse,
		|	Inventories.Purpose AS Purpose,
		|	Inventories.OrderDocument AS OrderDocument,
		|	Inventories.LockedInStockBalance AS LockedInStockBalance,
		|	Inventories.LockedReceiptBalance AS LockedReceiptBalance,
		|	Inventories.ToUnlockBalance AS ToUnlockBalance,
		|	Inventories.ReserveAtWarehouseFromLockedBalance AS ReserveAtWarehouseFromLockedBalance,
		|	Inventories.ReserveUponReceiptFromLockedBalance AS ReserveUponReceiptFromLockedBalance
		|INTO InventoryAndNeedsBalanceOfControlledLotsReference
		|FROM
		|	AccumulationRegister.InventoryAndDemands.Balance(,
		|		(Products, Characteristic, Warehouse, Purpose) IN(
		|			SELECT
		|				Filter.Products AS Products,
		|				Filter.Characteristic AS Characteristic,
		|				Filter.Warehouse AS Warehouse,
		|				Filter.Purpose AS Purpose
		|			FROM
		|				ProductFilterTable AS Filter)) AS Inventories
		|INDEX BY
		|	Products, Characteristic, Warehouse, Purpose
		|;
		|
		|//////////////////////////////////////////////////
		|SELECT ALLOWED
		|	Inventories.Products AS Products,
		|	Inventories.Characteristic AS Characteristic,
		|	Inventories.Warehouse AS Warehouse,
		|	Inventories.Purpose AS Purpose,
		|	Inventories.InStockBalance AS InStockBalance,
		|	Inventories.LockedInStockBalance AS LockedInStockBalance,
		|	Inventories.OrderedBalance AS OrderedBalance,
		|	Inventories.Received_1Balance AS Received_1Balance,
		|	Inventories.LockedReceiptBalance AS LockedReceiptBalance,
		|	Inventories.ReserveAtWarehouseBalance AS ReserveAtWarehouseBalance,
		|	Inventories.ReserveAsReceivedBalance AS ReserveAsReceivedBalance,
		|	Inventories.SnoozeReservationBalance AS SnoozeReservationBalance,
		|	Inventories.ToSupplyBalance AS ToSupplyBalance,
		|	Inventories.NotProvideBalance AS NotProvideBalance
		|INTO InventoryAndDemandsBalance
		|FROM
		|	AccumulationRegister.InventoryAndDemands.Balance(,
		|		(Products, Characteristic, Warehouse, Purpose) IN(
		|			SELECT
		|				Filter.Products AS Products,
		|				Filter.Characteristic AS Characteristic,
		|				Filter.Warehouse AS Warehouse,
		|				Filter.Purpose AS Purpose
		|			FROM
		|				ProductFilterTable AS Filter)) AS Inventories
		|INDEX BY
		|	Products, Characteristic, Warehouse, Purpose
		|;
		|
		|//////////////////////////////////////////////////
		|SELECT
		|	Set.Products AS Products,
		|	Set.Characteristic AS Characteristic,
		|	Set.Warehouse AS Warehouse,
		|	Set.Purpose AS Purpose,
		|	Set.ControlledLotReference AS ControlledLotReference,
		|	SUM(Set.QuantityForShipAction) AS QuantityForShipAction,
		|	SUM(Set.QuantityForActionIsReservedAsItBecomesAvailable) AS QuantityForActionIsReservedAsItBecomesAvailable
		|INTO TempTableBalance
		|FROM(
		|	SELECT
		|		Calculation.Products AS Products,
		|		Calculation.Characteristic AS Characteristic,
		|		Calculation.Warehouse AS Warehouse,
		|		Calculation.Purpose AS Purpose,
		|		Calculation.ControlledLotReference AS ControlledLotReference,
		|		Calculation.QuantityForShipAction AS QuantityForShipAction,
		|		Calculation.QuantityForActionIsReservedAsItBecomesAvailable AS QuantityForActionIsReservedAsItBecomesAvailable
		|	FROM
		|		CalculationOfBalancesForSettingActions AS Calculation
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		AdjustingBalance.Products AS Products,
		|		AdjustingBalance.Characteristic AS Characteristic,
		|		AdjustingBalance.Warehouse AS Warehouse,
		|		AdjustingBalance.Purpose AS Purpose,
		|		AdjustingBalance.ControlledLotReference AS ControlledLotReference,
		|		AdjustingBalance.InStock AS QuantityForShipAction,
		|		AdjustingBalance.AvailableAndExpected AS QuantityForActionIsReservedAsItBecomesAvailable
		|	FROM
		|		AdjustingBalance AS AdjustingBalance) AS Set
		|GROUP BY
		|	Set.Products,
		|	Set.Characteristic,
		|	Set.Warehouse,
		|	Set.Purpose,
		|	Set.ControlledLotReference
		|INDEX BY
		|	Products, Characteristic, Warehouse, Purpose, ControlledLotReference";
	
	TablesNames = NewTableNamesForCalculatingBalancesForSettingActions();
	TablesNames.Balance = "InventoryAndDemandsBalance"; // @query-part-1
	TablesNames.BalanceSheetsOfControlledLotREFERENCES = "InventoryAndNeedsBalanceOfControlledLotsReference"; // @query-part-1
	TablesNames.Analysts = "ProductFilterTable"; // @query-part-1
	TablesNames.Result = "CalculationOfBalancesForSettingActions"; // @query-part-1
	CalculationOfBalancesForSettingActions(QueryText, TablesNames);
	
	Texts.Add(QueryText);
	
	QueryText =
		// Reserves under the order.
		"SELECT ALLOWED
		|	Goods.Products AS Products,
		|	Goods.Characteristic AS Characteristic,
		|	Goods.Warehouse AS Warehouse,
		|	Goods.Purpose AS Purpose,
		|	Goods.ControlledLotReference AS ControlledLotReference,
		|	SUM(Reserves.Count) AS Count
		|INTO ReservesForOtherOrders
		|FROM
		|	ProductFilterTable AS Goods
		|		
		|		INNER JOIN InformationRegister.InventoryAllocation AS Reserves
		|		ON Reserves.Products = Goods.Products
		|		 AND Reserves.Characteristic = Goods.Characteristic
		|		 AND Reserves.Purpose = Goods.Purpose
		|		 AND Reserves.Warehouse = Goods.Warehouse
		|		 AND (Reserves.ReceiptOrder = UNDEFINED
		|				AND Goods.ControlledLotReference = VALUE(Catalog.ControlledLots.EmptyRef)
		|			OR Reserves.ReceiptOrder = Goods.ControlledLotReference)
		|		 AND Reserves.DemandCharacteristic IN(
		|			VALUE(Enum.DemandCharacteristics.ReserveAtWarehouse),
		|			VALUE(Enum.DemandCharacteristics.ReserveAsReceived))
		|		 AND Reserves.InventoryState IN(
		|			VALUE(Enum.InventoryStates.InStock),
		|			VALUE(Enum.InventoryStates.AvailablePendingUnlocking),
		|			VALUE(Enum.InventoryStates.AvailableNotSubjectToUnlocking))
		|WHERE
		|	NOT TRUE IN(
		|		SELECT TOP 1
		|			TRUE AS ThereAreRecords
		|		FROM
		|			SelectedOrders_ AS Orders
		|		WHERE
		|			Orders.Products = Reserves.Products
		|			AND Orders.Characteristic = Reserves.Characteristic
		|			AND Orders.Purpose = Reserves.Purpose
		|			AND Orders.ShipmentOrder = Reserves.ShipmentOrder)
		|GROUP BY
		|	Goods.Products,
		|	Goods.Characteristic,
		|	Goods.Warehouse,
		|	Goods.Purpose,
		|	Goods.ControlledLotReference
		|INDEX BY
		|	Products, Characteristic, Purpose, Warehouse, ControlledLotReference
		|;
		|
		|///////////////////////////////////////////////////////////
		|SELECT ALLOWED
		|	Goods.Products AS Products,
		|	Goods.Characteristic AS Characteristic,
		|	Goods.Purpose AS Purpose,
		|	Goods.WithAssignment AS WithAssignment,
		|	Goods.ControlledLotReference AS ControlledLotReference,
		|	Goods.Warehouse AS Warehouse,
		|	
		|	ISNULL(AvailableStock.QuantityForShipAction, 0) AS AvailableAtBaseUnit,
		|	ISNULL(ReservesForOtherOrders.Count, 0) AS ReservedAtBaseUnit,
		|	ISNULL(AvailableStock.QuantityForActionIsReservedAsItBecomesAvailable, 0) AS BasedOnScheduleAtBaseUnit,
		|	
		|	CASE
		|		WHEN Goods.WithAssignment
		|			THEN ISNULL(AvailableStock.QuantityForShipAction, 0) / &PackagingFactor
		|		ELSE 0
		|	END AS InStockAssigned,
		|	CASE
		|		WHEN Goods.WithAssignment
		|			THEN
		|				ISNULL(AvailableStock.QuantityForActionIsReservedAsItBecomesAvailable, 0) / &PackagingFactor
		|		ELSE 0
		|	END AS BasedOnScheduleAssigned,
		|	ISNULL(AvailableStock.QuantityForShipAction, 0) / &PackagingFactor AS InStock,
		|	ISNULL(ReservesForOtherOrders.Count, 0) / &PackagingFactor AS InReserve,
		|	ISNULL(AvailableStock.QuantityForActionIsReservedAsItBecomesAvailable, 0) / &PackagingFactor AS OnSchedule,
		|	Goods.Warehouse IN(&GroupWarehouses_)
		|		OR Goods.Warehouse = Goods.DocumentWarehouse AS ThisIsSelectedGroupWarehouse,
		|	ISNULL(SettingUpSecurityControlCharacteristic.AvailableStockControl,
		|		ISNULL(SettingUpControlAndProducts.AvailableStockControl,
		|			ISNULL(SetUpSupplyControl.AvailableStockControl, FALSE))) CheckAvailability
		|FROM
		|	ProductFilterTable AS Goods
		|		
		|		LEFT JOIN TempTableBalance AS AvailableStock
		|			ON AvailableStock.Products = Goods.Products
		|			 AND AvailableStock.Characteristic = Goods.Characteristic
		|			 AND AvailableStock.Purpose = Goods.Purpose
		|			 AND AvailableStock.Warehouse = Goods.Warehouse
		|			 AND AvailableStock.ControlledLotReference = Goods.ControlledLotReference
		|		
		|		LEFT JOIN ReservesForOtherOrders AS ReservesForOtherOrders
		|			ON ReservesForOtherOrders.Products = Goods.Products
		|			 AND ReservesForOtherOrders.Characteristic = Goods.Characteristic
		|			 AND ReservesForOtherOrders.Warehouse = Goods.Warehouse
		|			 AND ReservesForOtherOrders.Purpose = Goods.Purpose
		|			 AND ReservesForOtherOrders.ControlledLotReference = Goods.ControlledLotReference
		|		
		|		LEFT JOIN InformationRegister.SetUpSupplyControl AS SettingUpSecurityControlCharacteristic
		|		ON SettingUpSecurityControlCharacteristic.Warehouse = Goods.Warehouse
		|		 AND SettingUpSecurityControlCharacteristic.Products = Goods.Products
		|		 AND SettingUpSecurityControlCharacteristic.Characteristic = Goods.Characteristic
		|		
		|		LEFT JOIN InformationRegister.SetUpSupplyControl AS SettingUpControlAndProducts
		|		ON SettingUpControlAndProducts.Warehouse = Goods.Warehouse
		|		 AND SettingUpControlAndProducts.Products = Goods.Products
		|		 AND SettingUpControlAndProducts.Characteristic = VALUE(Catalog.ItemsCharacteristics.EmptyRef)
		|		 AND SettingUpSecurityControlCharacteristic.Warehouse IS NULL
		|		
		|		LEFT JOIN InformationRegister.SetUpSupplyControl AS SetUpSupplyControl
		|		ON SetUpSupplyControl.Warehouse = Goods.Warehouse
		|		 AND SetUpSupplyControl.Products = VALUE(Catalog.Products.EmptyRef)
		|		 AND SetUpSupplyControl.Characteristic = VALUE(Catalog.ItemsCharacteristics.EmptyRef)
		|		 AND SettingUpSecurityControlCharacteristic.Warehouse IS NULL
		|		 AND SettingUpControlAndProducts.Warehouse IS NULL";
	Texts.Add(QueryText);
	Query.Text = StrConcat(Texts, Common.QueryBatchSeparator());
	WarehouseAndScheduleLeftovers = Query.Execute().Unload();
	
	Return WarehouseAndScheduleLeftovers;
	
EndFunction

// Returns the table for setting the action
// 
// Parameters:
// 	ActionCode               - String -
// 	FillParameters       - Structure with fields:
// 	Fill
// 	in Whole packages - Boolean - Pick up the layout - Boolean -
// 	Collection                 - ValueTable -
// 	SelectedRows          - Array -
// 	RowsData               - ValueTable -
// 	PackingFactors      - Map -
// 	DataOfAccounting               - Structure - Contains:
//   * WarehouseRemnants - ValueTable -
//   * TableDecorated - ValueTable -
// 
// Returns:
//  ValueTable - Columns:
//   * NumberOfPackages - Number -
//   * SupplyOption - EnumRef.SupplyOptions -
//   * Warehouse - CatalogRef.Warehouses -
//   * Id - Number -
//   * String - FormDataCollectionItem -
//
Function TableForSettingActions(ActionCode, FillParameters, Collection, SelectedRows, RowsData, PackingFactors, DataOfAccounting)
	
	ThisIsInstallationToReserveAsWithControl = ActionCode = "ACTION_RESERVATION_REFERENCES"
		And Constants.ControlBalanceOfGoodsToBeReservedUponReceipt.Get();
	PopulateWithTheWholePackagings = FillParameters.PopulateWithTheWholePackagings;
	PickUpWarehouse = FillParameters.PickUpWarehouse;
	WarehouseRemnants = DataOfAccounting.WarehouseRemnants;
	TableDecorated = DataOfAccounting.TableDecorated; 

	TableDecorated.Indexes.Add("Ref,RowCode");
	
	IsValueTable = TypeOf(Collection) = Type("ValueTable");
	ThisIsDataOfFormCollection = TypeOf(Collection) = Type("FormDataCollection");
	If IsValueTable Then
		Collection.Indexes.Add("RowID");
	EndIf;
	
	RowFilter = New Structure("CollectionItem");
	RowsData.Indexes.Add("CollectionItem");
	
	ChangesTable = New ValueTable();
	ChangesTable.Columns.Add("NumberOfPackages");
	ChangesTable.Columns.Add("SupplyOption");
	ChangesTable.Columns.Add("Warehouse");
	ChangesTable.Columns.Add("WithAssignment");
	ChangesTable.Columns.Add("Id");
	ChangesTable.Columns.Add("String");
	ChangesTable.Columns.Add("IsNewLine", New TypeDescription("Boolean"));
	
	ProductColumns = "Products,Characteristic,Warehouse,Purpose,ControlledLotReference";
	DeliveryOfGoodsWithoutWarehouse = "Products,Characteristic,Purpose,ControlledLotReference";
	WarehouseRemnants.Indexes.Add(ProductColumns);
	WarehouseRemnants.Indexes.Add(DeliveryOfGoodsWithoutWarehouse);
	RemainderSearchStructure = New Structure(ProductColumns);
	StructureOfFindingBalanceWithoutWarehouse = New Structure(DeliveryOfGoodsWithoutWarehouse);
	InvoiceSearchStructure = New Structure("Ref,RowCode");
	
	For Each RowID In SelectedRows Do
		
		If IsValueTable Then
			CollectionRow = Collection.Find(RowID, "RowID");
		ElsIf ThisIsDataOfFormCollection Then
			CollectionRow = Collection.FindByID(RowID);
		Else
			CollectionRow = Collection[RowID - 1];
		EndIf;

		RowFilter.CollectionItem = RowID;
		FoundRows = RowsData.FindRows(RowFilter);
		If FoundRows.Count() = 0 Then
			Continue; // the string does not get into the selection, which means it does not affect the residuals.
		EndIf;
		
		String = FoundRows[0];
		
		If ActionCode = "rollback_Actions_Ship" Then

			If String.SupplyOption <> Enums.SupplyOptions.Ship Then
				Continue;

			ElsIf String.ItemsType = Enums.ItemsTypes.Work_5 Then

				If String.WithAssignment Then
					SupplyOption = Enums.SupplyOptions.ToSupply;
				Else
					SupplyOption = Enums.SupplyOptions.NotRequired;
				EndIf;

			ElsIf String.ItemsType = Enums.ItemsTypes.OperationService Then

				SupplyOption = Enums.SupplyOptions.NotRequired;
			Else
				SupplyOption = Enums.SupplyOptions.FromWarehouse;
			EndIf;

		Else
			SupplyOption = ?(ActionCode = "ACTION_COOPERATION",  Enums.SupplyOptions.ToSupply,
			                     ?(ActionCode = "ACTION_RESERVATION_REFERENCES", Enums.SupplyOptions.ReserveAsReceived,
			                     ?(ActionCode = "ACTION_RESERVE", Enums.SupplyOptions.FromWarehouse,
			                     ?(ActionCode = "Action_ToReserve__PRIORITY_WithAssignment", Enums.SupplyOptions.FromWarehouse,
			                     ?(ActionCode = "ACTION_LOAD",     Enums.SupplyOptions.Ship,
			                     ?(ActionCode = "Action_Ship_PRIORITY_WithAssignment", Enums.SupplyOptions.Ship,
			                     ?(ActionCode = "ACTION_NOTABLE",Enums.SupplyOptions.NotRequired,
			                     ?(ActionCode = "ACTION_TRANSMITTED" ,Enums.SupplyOptions.TransferedEarlier,
			                                                               Undefined))))))));
		EndIf;
		
		If SupplyOption = CollectionRow.SupplyOption Then
			Continue;
		EndIf;
		
		If Not ActionAllowed(SupplyOption, String.WithAssignment, String.ItemsType) Then
			Continue;
		EndIf;
		
		CurSearchStructure = Undefined;
		If Not ValueIsFilled(String.Warehouse)
				And PickUpWarehouse
				And (String.ItemsType = Enums.ItemsTypes.OwnGoods
					Or String.ItemsType = Enums.ItemsTypes.ReusablePackage) Then
			CurSearchStructure = StructureOfFindingBalanceWithoutWarehouse;
		Else
			CurSearchStructure = RemainderSearchStructure;
		EndIf;
		
		If (ActionCode = "Action_ToReserve__PRIORITY_WithAssignment" Or ActionCode = "Action_Ship_PRIORITY_WithAssignment")
				And Not String.WithAssignment 
				And Not String.AssignmentWithoutRegardToFlagIsSeparate.IsEmpty() Then
			FoundRemainderRows = New Array();	
			FillPropertyValues(CurSearchStructure, String);
			CurSearchStructure.Purpose = String.AssignmentWithoutRegardToFlagIsSeparate;
			CommonClientServer.SupplementArray(FoundRemainderRows, WarehouseRemnants.FindRows(CurSearchStructure));
			CurSearchStructure.Purpose = Catalogs.Assignments.EmptyRef();
			CommonClientServer.SupplementArray(FoundRemainderRows, WarehouseRemnants.FindRows(CurSearchStructure));
		Else
			FillPropertyValues(CurSearchStructure, String);
			FoundRemainderRows = WarehouseRemnants.FindRows(CurSearchStructure);
		EndIf;
		
		InvoiceSearchStructure.Ref    = String.ShipmentOrder;
		InvoiceSearchStructure.RowCode = String.RowCode;
		FoundInvoiceLines = TableDecorated.FindRows(InvoiceSearchStructure);
		
		ShipmentControl = String.SupplyOption = Enums.SupplyOptions.Ship
			And (ActionCode <> "ACTION_LOAD" Or ActionCode <> "Action_Ship_PRIORITY_WithAssignment")
			And FoundInvoiceLines.Count() > 0
			And FoundInvoiceLines[0].Count > 0;
		
		WasReserved = CollectionRow.SupplyOption = Enums.SupplyOptions.Ship
			Or CollectionRow.SupplyOption = Enums.SupplyOptions.FromWarehouse;
		
		NeedToReserve = (ActionCode = "ACTION_RESERVE" Or ActionCode = "ACTION_LOAD"
			Or ActionCode = "Action_ToReserve__PRIORITY_WithAssignment" Or ActionCode = "Action_Ship_PRIORITY_WithAssignment");
		
		FillingByBalances = String.AvailableStockControl
			And (Not WasReserved And NeedToReserve
					Or ThisIsInstallationToReserveAsWithControl
						And CollectionRow.SupplyOption <> Enums.SupplyOptions.Ship
						And CollectionRow.SupplyOption <> Enums.SupplyOptions.FromWarehouse
						And CollectionRow.SupplyOption <> Enums.SupplyOptions.ReserveAsReceived);
			
		If IsValueTable Or ThisIsDataOfFormCollection Then
			ZoomRatio = PackingFactors.Get(RowID);
		Else
			ZoomRatio = PackingFactors.Get(CollectionRow);
		EndIf;
		ZoomRatio = ?(ZoomRatio = Undefined, 1, ZoomRatio);
		
		If ShipmentControl Then
			
			NumberOfPackages = String.NumberOfPackages
				- Round(FoundInvoiceLines[0].Count / ZoomRatio, 3, RoundMode.Round15as10);
			
			If NumberOfPackages > 0 Then
				
				AddedRow = ChangesTable.Add();
				FillPropertyValues(AddedRow, String);
				AddedRow.NumberOfPackages = AddedRow.NumberOfPackages - NumberOfPackages;
				AddedRow.Id = RowID;
				
				AddedRow = ChangesTable.Add();
				FillPropertyValues(AddedRow, String);
				AddedRow.SupplyOption = SupplyOption;
				AddedRow.NumberOfPackages = NumberOfPackages;
				AddedRow.Id = RowID;
				AddedRow.IsNewLine = True;
				
			EndIf;
			
		ElsIf Not FillingByBalances Then
			
			AddedRow = ChangesTable.Add();
			FillPropertyValues(AddedRow, String);
			AddedRow.SupplyOption = SupplyOption;
			AddedRow.Id = RowID;
			
		Else
			
			QuantityPerLine = String.Count;
			NumberOfPackagesPerLine = String.NumberOfPackages;
			CurrentRowIndex = ChangesTable.Count();
			HasChanges = False;
			For IndexOf = 0 To FoundRemainderRows.Count() - 1 Do
				
				RemainderLine = FoundRemainderRows[IndexOf];
				If ThisIsInstallationToReserveAsWithControl Then
					CountBalance = RemainderLine.QuantityTakingIntoAccountExpectedReceipts;
				Else
					CountBalance = RemainderLine.Count;
				EndIf;
				NumberOfPackages = 0;
				If CountBalance >= QuantityPerLine Then // the quantity can be rounded up for dimensional packages.
					
					NumberOfPackages = NumberOfPackagesPerLine;
					CountBalance = CountBalance - QuantityPerLine;
					NumberOfPackagesPerLine = 0;
					QuantityPerLine = 0;
					
				ElsIf CountBalance > 0 Then
					
					RemainingPackages = Round(CountBalance / ZoomRatio, 3, RoundMode.Round15as10);
					NumberOfPackages = Min(RemainingPackages, NumberOfPackagesPerLine);
					
					If PopulateWithTheWholePackagings Then
						NumberOfPackages = Int(NumberOfPackages);
					EndIf;
					
					CountBalance = CountBalance - NumberOfPackages * ZoomRatio;
					NumberOfPackagesPerLine = NumberOfPackagesPerLine - NumberOfPackages;
					QuantityPerLine = QuantityPerLine - NumberOfPackages * ZoomRatio;
					
				EndIf;
				
				If NumberOfPackages > 0 Then
					
					AddedRow = ChangesTable.Add();
					FillPropertyValues(AddedRow, String);
					AddedRow.NumberOfPackages = NumberOfPackages;
					AddedRow.SupplyOption = SupplyOption;
					AddedRow.Warehouse = RemainderLine.Warehouse;
					AddedRow.WithAssignment = Not RemainderLine.Purpose.IsEmpty();
					AddedRow.Id = RowID;
					AddedRow.IsNewLine = String.NumberOfPackages <> NumberOfPackages;
					HasChanges = True;
					
				EndIf;
				
				If ThisIsInstallationToReserveAsWithControl Then
					RemainderLine.QuantityTakingIntoAccountExpectedReceipts = CountBalance;
				Else
					RemainderLine.Count = CountBalance;
				EndIf;
				
				If NumberOfPackagesPerLine = 0 Then
					Break;
				EndIf;
				
			EndDo;
			
			If HasChanges And NumberOfPackagesPerLine > 0 Then
				
				AddedRow = ChangesTable.Insert(CurrentRowIndex);
				FillPropertyValues(AddedRow, String);
				AddedRow.NumberOfPackages = NumberOfPackagesPerLine;
				AddedRow.Id = RowID;
				
			EndIf;
			
		EndIf;
		
	EndDo;
	
	Return ChangesTable;
	
EndFunction

Function ActionAllowed(SupplyOption, WithAssignment, ItemsType)
	
	If ItemsType = Enums.ItemsTypes.Work_5 Then
		
		If WithAssignment Then
			Return SupplyOption = Enums.SupplyOptions.Ship
						Or SupplyOption = Enums.SupplyOptions.ToSupply;
		Else
			Return SupplyOption = Enums.SupplyOptions.Ship
						Or SupplyOption = Enums.SupplyOptions.NotRequired;
		EndIf;
		
	ElsIf ItemsType = Enums.ItemsTypes.OperationService Then
		
		Return SupplyOption = Enums.SupplyOptions.Ship
					Or SupplyOption = Enums.SupplyOptions.NotRequired;
		
	EndIf;
	Return True;
	
EndFunction

Function ThereAreFractionalPackagesInChangeTable(ChangesTable, PackingFactors, RowsData)
	
	For Each Update In ChangesTable Do
		
		ZoomRatio = PackingFactors.Get(Update.Id);
		NumberOfPackagesPerLine = RowsData.FindRows(New Structure("CollectionItem",
			Update.Id))[0].NumberOfPackages;
		
		If ZoomRatio <> Undefined
			And NumberOfPackagesPerLine = Int(NumberOfPackagesPerLine)
			And Int(Update.NumberOfPackages) <> Update.NumberOfPackages Then
			Return True;
		EndIf;
		
	EndDo;
	
	Return False;
	
EndFunction

Function InChangesetThereIsShipmentAndShipmentDateOfAllRowsIsOneDateOverdue(ChangesTable, RowsData)
	
	ThereIsShipment = Undefined <>
		ChangesTable.Find(
			Enums.SupplyOptions.Ship,
			"SupplyOption");
	
	Result = ThereIsShipment
		And RowsData[0].TheShipmentDateOfAllLinesIsASingleDate <> Undefined
		And RowsData[0].TheShipmentDateOfAllLinesIsASingleDate < BegOfDay(CurrentSessionDate());
	Return Result;
	
EndFunction

Function PackingFactors(RowsData, FormTable)
	
	PackingDataTable = New ValueTable;
	PackingDataTable.Columns.Add("Products", New TypeDescription("CatalogRef.Products"));
	PackingDataTable.Columns.Add("Package",     New TypeDescription("CatalogRef.PackagesAndUnitsOfMeasure"));
	
	For Each TableRow In RowsData Do
		
		If FormTable <> Undefined Then
			CollectionItem = FormTable.FindByID(TableRow.CollectionItem);
		Else
			CollectionItem = TableRow;
		EndIf;
		If ValueIsFilled(CollectionItem.Package) Then
			NewRow = PackingDataTable.Add();
			FillPropertyValues(NewRow, CollectionItem);
		EndIf;
		
	EndDo;
	
	PackingFactors = Catalogs.PackagesAndUnitsOfMeasure.PackingFactors(PackingDataTable);
	
	Result = New Map();
	For Each TableRow In RowsData Do
		
		If FormTable <> Undefined Then
			CollectionItem = FormTable.FindByID(TableRow.CollectionItem);
		Else
			CollectionItem = TableRow;
		EndIf;
		If ValueIsFilled(CollectionItem.Package) Then
			
			ZoomRatio = PackingFactors[CollectionItem.Products][CollectionItem.Package];
			If FormTable <> Undefined Then
				Result.Insert(TableRow.CollectionItem, ZoomRatio);
			Else
				Result.Insert(TableRow, ZoomRatio);
			EndIf;
			
		EndIf;
		
	EndDo;
	
	Return Result;
	
EndFunction

Function TemporaryTableOfDocumentRegisteredRecords(IgnoreReadinessToProvide = False)
	
	QueryText =
		"SELECT
		|	UNDEFINED AS Ref,
		|	TabPart.DocumentDate AS Period,
		|	TabPart.Products AS Products,
		|	TabPart.Characteristic AS Characteristic,
		|	CASE
		|		WHEN TabPart.Products.ItemsType IN(
		|				VALUE(Enum.ItemsTypes.OwnGoods),
		|				VALUE(Enum.ItemsTypes.ReusablePackage))
		|			THEN TabPart.Warehouse
		|		ELSE TabPart.Department
		|	END AS Warehouse,
		|	CASE
		|		WHEN TabPart.WithAssignment
		|			THEN
		|				CASE
		|					WHEN TabPart.Purpose = VALUE(Catalog.Assignments.EmptyRef)
		|						THEN &NewDestinationLink
		|					ELSE TabPart.Purpose
		|				END
		|		ELSE VALUE(Catalog.Assignments.EmptyRef)
		|	END AS Purpose,
		|	TabPart.ControlledLotReference AS ControlledLotReference,
		|	TabPart.ShipmentOrder AS ShipmentOrder,
		|	CASE
		|		WHEN TabPart.SupplyOption = VALUE(Enum.SupplyOptions.Ship)
		|			THEN TabPart.ShipmentOrder
		|		ELSE UNDEFINED
		|	END AS PlannedConsumptionOfDistributedStock,
		|	TabPart.SupplyOption AS SupplyOption,
		|	TabPart.Count AS Count,
		|	TabPart.ReadyForSupply AS ReadyForSupply,
		|	TabPart.ReadyToShip AS ReadyToShip,
		|	TabPart.RequestShipmentOn AS RequestShipmentOn
		|FROM
		|	TemporaryDocumentDataTable AS TabPart
		|WHERE
		|	NOT TabPart.Canceled";
		
		NestedQuery = StockAllocationRecords.RequestTextOrderForProvisionAndShipment(QueryText,
			IgnoreReadinessToProvide);
		NestedQuery = StrTemplate("(%1)", NestedQuery);
		
		QueryText =
			"SELECT
			|	TabPart.Products AS Products,
			|	TabPart.Characteristic AS Characteristic,
			|	TabPart.Warehouse AS Warehouse,
			|	TabPart.Purpose AS Purpose,
			|	TabPart.OrderDocument AS OrderDocument,
			|	TabPart.OrderToShip AS OrderToShip,
			|	TabPart.Period AS Period,
			|	TabPart.EventDate AS EventDate,
			|	TabPart.RecordType AS RecordType,
			|	TabPart.InStock AS InStock,
			|	TabPart.LockedInStock AS LockedInStock,
			|	TabPart.Received_1 AS Received_1,
			|	TabPart.LockedReceipt AS LockedReceipt,
			|	TabPart.Ordered AS Ordered,
			|	TabPart.ToUnlock AS ToUnlock,
			|	TabPart.SnoozeReservation AS SnoozeReservation,
			|	TabPart.ReserveAtWarehouse AS ReserveAtWarehouse,
			|	TabPart.ReserveAsReceived AS ReserveAsReceived,
			|	TabPart.ReserveAtWarehouseFromLocked AS ReserveAtWarehouseFromLocked,
			|	TabPart.ReserveUponReceiptFromLocked AS ReserveUponReceiptFromLocked,
			|	TabPart.ToSupply AS ToSupply,
			|	TabPart.NotProvide AS NotProvide,
			|	TabPart.CloseReceiptSchedule AS CloseReceiptSchedule,
			|	TabPart.ToControlQuality AS ToControlQuality,
			|	TabPart.SubjectToUnlocking AS SubjectToUnlocking,
			|	TabPart.CloseScheduleShipping AS CloseScheduleShipping,
			|	FALSE AS ReversingEntry
			|INTO TemporaryTableOfDocumentRegisteredRecords
			|FROM
			|	NestedQuery AS TabPart";
		
	QueryText = StrReplace(QueryText, "NestedQuery", NestedQuery);
	Return QueryText;
	
EndFunction

Function NewTableIsDecorated()
	
	NewTable = New ValueTable();
	NewTable.Columns.Add("Products", New TypeDescription("CatalogRef.Products"));
	NewTable.Columns.Add("Characteristic", New TypeDescription("CatalogRef.ItemsCharacteristics"));
	NewTable.Columns.Add("Warehouse", New TypeDescription("CatalogRef.Warehouses"));
	NewTable.Columns.Add("Purpose", New TypeDescription("CatalogRef.Assignments"));
	NewTable.Columns.Add("SupplyOption", New TypeDescription("EnumRef.SupplyOptions"));
	NewTable.Columns.Add("WithAssignment", New TypeDescription("Boolean"));
	NewTable.Columns.Add("Ref", Metadata.DefinedTypes.ExpectedShipment.Type);
	NewTable.Columns.Add("Series", New TypeDescription("CatalogRef.ItemsBatches"));
	NewTable.Columns.Add("RowCode", Common.TypeDescriptionNumber(10, 0));
	NewTable.Columns.Add("Count", Common.TypeDescriptionNumber(15, 3));
	NewTable.Columns.Add("QuantityInOrder", Common.TypeDescriptionNumber(15, 3));
	Return NewTable;
	
EndFunction

#EndRegion

///////////////////////////////////////////////////////
// Official.

#Region ObjectSerialization

Procedure FillInTablesFromFormData(Tables, Form, ExcludeNeedsTable = False)
	
	EmbeddingParameters = Form.AvailableRemainingEmbeddingOptions;
	TablePath = TablePath(EmbeddingParameters);
	
	For Each Item In Tables Do
		
		Table = Item.Value.Table; // ValueTable
		Table.Clear();
		DataObject = Form;
		Paths = StrSplit(Item.Key, ".", False);
		For Each PathElement In Paths Do
			DataObject = DataObject[PathElement];
		EndDo;
		
		If TypeOf(DataObject) = Type("FormDataCollection") Then
			
			ThisIsNeedsTable = Item.Key = TablePath;
			If Not ThisIsNeedsTable Or Not ExcludeNeedsTable Then
				For Each TableRow In DataObject Do
					
					NewRow = Table.Add();
					FillPropertyValues(NewRow, TableRow);
					If ThisIsNeedsTable Then
						NewRow.LineNumber = TableRow.GetID();
					EndIf;
					
				EndDo;
			EndIf;
			
		ElsIf TypeOf(DataObject) = Type("ValueTable") Then
			
			For Each TableRow In DataObject Do
				
				NewRow = Table.Add();
				FillPropertyValues(NewRow, TableRow);
				
			EndDo;
			
		Else
			
			NewRow = Table.Add();
			FillPropertyValues(NewRow, DataObject);
			
		EndIf;
		
	EndDo;
	
EndProcedure

Procedure FillInTablesFromObject(Tables, Object, ExcludeNeedsTable = False, EmbeddingParameters = Undefined)
	
	If ExcludeNeedsTable Then
		TablePath = TablePath(EmbeddingParameters);
	EndIf;
	
	For Each Item In Tables Do
		
		Item.Value.Table.Clear();
		DataObject = Object;
		Paths = StrSplit(Item.Key, ".", False);
		For Each PathElement In Paths Do
			DataObject = DataObject[PathElement];
		EndDo;
		
		If DataObject <> Object.Object Then // this is the tabular part
			
			If Not ExcludeNeedsTable Or Item.Key <> TablePath Then
				
				For Each TableRow In DataObject Do
					
					NewRow = Item.Value.Table.Add();
					FillPropertyValues(NewRow, TableRow); 
					
				EndDo;
				
			EndIf;
			
		Else
			
			NewRow = Item.Value.Table.Add();
			FillPropertyValues(NewRow, DataObject);
			
		EndIf;
		
	EndDo;
	
EndProcedure

Procedure PopulateTablesFromSerializedObject(Tables, RowData, EmbeddingParameters, CurrentRow)
	
	TablePath = TablePath(EmbeddingParameters);
	
	For Each Item In Tables Do
		
		Item.Value.Table.Clear();
		DataObject = RowData;
		Paths = StrSplit(Item.Key, ".");
		For Each PathElement In Paths Do
			DataObject = DataObject[PathElement];
		EndDo;
		
		NewRow = Item.Value.Table.Add();
		FillPropertyValues(NewRow, DataObject);
		
		If Item.Key = TablePath Then
			FillPropertyValues(NewRow, CurrentRow); // these lines could have been changed by previous actions
		EndIf;
		
	EndDo;
	
EndProcedure

// Parameters:
//  TempTableName - String - 
//  Table - ValueTable - 
// Returns:
// String -
Function TemporaryTableQueryTextByTableColumns(TempTableName, Table)
	
	Texts = New Array();
	For Each Column In Table.Columns Do
		
		Texts.Add("Table." + Column.Name + " AS " + Column.Name);
		
	EndDo;
	FieldSubstitution = StrConcat(Texts, "," + Chars.LF);
	Text =
		"SELECT
		|	&FieldSubstitution
		|INTO Substitution_
		|FROM
		|	&SubstitutionTemporaryTableName AS Table";
	Text = StrReplace(Text, "&FieldSubstitution", FieldSubstitution);
	Text = StrReplace(Text, "Substitution_", TempTableName);
	Text = StrReplace(Text, "SubstitutionTemporaryTableName", TempTableName);
	Return Text;
	
EndFunction

Procedure AddTemporaryDocumentDataTable(TempTablesManager, Tables, EmbeddingParameters)
	
	Query = New Query();
	For Each Item In Tables Do
		
		Query.SetParameter(Item.Value.TempTableName, Item.Value.Table);
		
	EndDo;
	
	Query.Text = EmbeddingParameters.InternalParameters.QueryTextTemporaryDocumentDataTable;
	Query.TempTablesManager = TempTablesManager;
	Query.Execute();
	
EndProcedure

Procedure AddTemporaryDocumentDataTableForSelectedRows(Query, LineNumbers)
	
	Query.Text =
		"SELECT
		|	TabPart.GroupOfWarehouses                   AS GroupOfWarehouses,
		|	TabPart.Products                    AS Products,
		|	TabPart.Characteristic                  AS Characteristic,
		|	TabPart.Department                   AS Department,
		|	TabPart.Warehouse                           AS Warehouse,
		|	TabPart.Purpose                      AS Purpose,
		|	TabPart.ControlledLotReference            AS ControlledLotReference,
		|	TabPart.ShipmentOrder                 AS ShipmentOrder,
		|	TabPart.DocumentDate                   AS DocumentDate,
		|	TabPart.SupplyOption              AS SupplyOption,
		|	TabPart.WithAssignment                     AS WithAssignment,
		|	TabPart.Count                      AS Count,
		|	TabPart.NumberOfPackages              AS NumberOfPackages,
		|	TabPart.Package                        AS Package,
		|	TabPart.ReadyForSupply               AS ReadyForSupply,
		|	TabPart.ReadyToShip                  AS ReadyToShip,
		|	TabPart.RequestShipmentOn            AS RequestShipmentOn,
		|	TabPart.Recorder                     AS Recorder,
		|	TabPart.Series                           AS Series,
		|	TabPart.RowCode                       AS RowCode,
		|	TabPart.Canceled                        AS Canceled,
		|	TabPart.LineNumber                     AS LineNumber,
		|	TabPart.Priority                       AS Priority,
		|	TabPart.TheShipmentDateOfAllLinesIsASingleDate AS TheShipmentDateOfAllLinesIsASingleDate
		|INTO TemporaryDocumentDataTableForSelectedRows
		|FROM
		|	TemporaryDocumentDataTable AS TabPart
		|WHERE
		|	TabPart.LineNumber IN(&LineNumbers) OR UNDEFINED IN(&LineNumbers)";
	Query.SetParameter("LineNumbers", LineNumbers);
	Query.Execute();
	
EndProcedure

#EndRegion

Function BalancesForColumnAreAvailable(TempTablesManager, BalanceCache, ChangesTable)
	
	Query = New Query;
	Query.TempTablesManager = TempTablesManager;
	Query.SetParameter("ChangesTable", ChangesTable);
	LinkID = New UUID("9e1b1ca8-ce19-46d8-a7ef-0292f4cd9799");
	Query.SetParameter("NonExistentAssignment", Catalogs.Assignments.GetRef(LinkID));
	
	Texts = New Array();
	
	Query.Text =
		"SELECT ALLOWED DISTINCT
		|	DocumentTable.Recorder     AS Recorder,
		|	DocumentTable.ShipmentOrder AS ShipmentOrder,
		|	DocumentTable.Products    AS Products,
		|	DocumentTable.Characteristic  AS Characteristic,
		|	DocumentTable.Package        AS Package,
		|	
		|	CASE
		|		WHEN CAST(DocumentTable.Products AS Catalog.Products).ItemsType IN(
		|				VALUE(Enum.ItemsTypes.OwnGoods),
		|				VALUE(Enum.ItemsTypes.ReusablePackage))
		|			THEN
						// .Link to believe record-level restrictions.
		|				CAST(DocumentTable.Warehouse AS Catalog.Warehouses).Ref
		|		ELSE
		|			DocumentTable.Department
		|	END AS Warehouse,
		|	
		|	CASE WHEN DocumentTable.WithAssignment THEN
		|				CASE WHEN DocumentTable.Purpose = VALUE(Catalog.Assignments.EmptyRef) THEN
									// so that free balances are not selected if the destination for the document is not yet in the database.
		|							&NonExistentAssignment
		|						ELSE
		|							DocumentTable.Purpose
		|					END
		|			ELSE
		|				VALUE(Catalog.Assignments.EmptyRef)
		|		END AS Purpose,
		|	DocumentTable.ControlledLotReference AS ControlledLotReference
		|INTO TableOfOrdersAndRegistrars
		|FROM
		|	TemporaryDocumentDataTable AS DocumentTable
		|INDEX BY
		|	Products, Characteristic, Warehouse, Purpose, ShipmentOrder, Package
		|;
		|
		|/////////////////////////////////////////////////////////
		|SELECT
		|	Jobs.Products AS Products,
		|	Jobs.Characteristic AS Characteristic,
		|	Jobs.Warehouse AS Warehouse,
		|	Jobs.Purpose AS Purpose,
		|	Jobs.ShipmentOrder AS ShipmentOrder,
		|	Jobs.ToReserveRemoval AS ToReserveRemoval,
		|	Jobs.ToReserveRemovalFromUnlocked AS ToReserveRemovalFromUnlocked
		|INTO TasksToWithdrawReserve
		|FROM
		|	InformationRegister.JobsForAllocatingInventory AS Jobs
		|WHERE
		|	TRUE IN(
		|		SELECT TOP 1
		|			TRUE AS ThereAreRecords
		|		FROM
		|			TableOfOrdersAndRegistrars AS TheOrdersTable
		|		WHERE
		|			TheOrdersTable.Products = Jobs.Products
		|			AND TheOrdersTable.Characteristic = Jobs.Characteristic
		|			AND TheOrdersTable.Warehouse = Jobs.Warehouse
		|			AND TheOrdersTable.Purpose = Jobs.Purpose
		|			AND Jobs.ShipmentOrder IN (TheOrdersTable.ShipmentOrder, TheOrdersTable.Recorder))
		|	AND (Jobs.ToReserveRemoval <> 0 OR Jobs.ToReserveRemovalFromUnlocked <> 0)";
	
	Query.Execute();
	
	Text =
		"SELECT DISTINCT
		|	DocumentTable.ShipmentOrder AS ShipmentOrder,
		|	DocumentTable.Products AS Products,
		|	DocumentTable.Characteristic AS Characteristic,
		|	DocumentTable.Package AS Package,
		|	DocumentTable.Warehouse AS Warehouse,
		|	DocumentTable.Purpose AS Purpose,
		|	DocumentTable.ControlledLotReference AS ControlledLotReference
		|INTO TheOrdersTable
		|FROM
		|	TableOfOrdersAndRegistrars AS DocumentTable
		|INDEX BY
		|	Products, Characteristic, Warehouse, Purpose, ShipmentOrder, Package
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
		|SELECT DISTINCT
		|	TheOrdersTable.Products AS Products,
		|	TheOrdersTable.Characteristic AS Characteristic,
		|	TheOrdersTable.Warehouse AS Warehouse,
		|	TheOrdersTable.Purpose AS Purpose,
		|	TheOrdersTable.ControlledLotReference AS ControlledLotReference,
		|	TheOrdersTable.Package AS Package
		|INTO TableOfGoods
		|FROM
		|	TheOrdersTable AS TheOrdersTable
		|INDEX BY
		|	Products, Characteristic, Warehouse, Purpose, Package
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
		|SELECT DISTINCT
		|	TheOrdersTable.Products AS Products,
		|	TheOrdersTable.Characteristic AS Characteristic,
		|	TheOrdersTable.Warehouse AS Warehouse,
		|	TheOrdersTable.Purpose AS Purpose,
		|	TheOrdersTable.ControlledLotReference AS ControlledLotReference,
		|	TheOrdersTable.ShipmentOrder AS ShipmentOrder
		|INTO TableOfOrdersWithoutPackages
		|FROM
		|	TheOrdersTable AS TheOrdersTable
		|INDEX BY
		|	Products, Characteristic, Warehouse, Purpose, ControlledLotReference, ShipmentOrder
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
		|SELECT DISTINCT
		|	TableOfGoods.Products AS Products,
		|	TableOfGoods.Characteristic AS Characteristic,
		|	TableOfGoods.Warehouse AS Warehouse,
		|	TableOfGoods.Purpose AS Purpose,
		|	TableOfGoods.ControlledLotReference AS ControlledLotReference
		|INTO TableOfGoodsWithoutPackages
		|FROM
		|	TableOfGoods AS TableOfGoods
		|INDEX BY
		|	Products, Characteristic, Warehouse, Purpose, ControlledLotReference
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
		|SELECT ALLOWED
		|	Set.Products AS Products,
		|	Set.Characteristic AS Characteristic,
		|	Set.Warehouse AS Warehouse,
		|	Set.Purpose AS Purpose,
		|	Set.ControlledLotReference AS ControlledLotReference,
		|	Set.ShipmentOrder AS ShipmentOrder,
		|	SUM(Set.Reserved) AS DistributedInWarehouseInSummary
		|INTO ProvidedInStockByLotReference
		|FROM (
		|	SELECT
		|		Jobs.Products AS Products,
		|		Jobs.Characteristic AS Characteristic,
		|		Jobs.Warehouse AS Warehouse,
		|		Jobs.Purpose AS Purpose,
		|		VALUE(Catalog.ControlledLots.EmptyRef) AS ControlledLotReference,
		|		Jobs.ShipmentOrder AS ShipmentOrder,
		|		- Jobs.ToReserveRemoval AS Reserved
		|	FROM
		|		TasksToWithdrawReserve AS Jobs
		|	WHERE
		|		Jobs.ToReserveRemoval <> 0
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		Jobs.Products AS Products,
		|		Jobs.Characteristic AS Characteristic,
		|		Jobs.Warehouse AS Warehouse,
		|		Jobs.Purpose AS Purpose,
		|		Jobs.ShipmentOrder AS ControlledLotReference,
		|		Jobs.ShipmentOrder AS ShipmentOrder,
		|		- Jobs.ToReserveRemovalFromUnlocked AS Reserved
		|	FROM
		|		TasksToWithdrawReserve AS Jobs
		|	WHERE
		|		Jobs.ToReserveRemovalFromUnlocked <> 0
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		InventoryAllocation.Products AS Products,
		|		InventoryAllocation.Characteristic AS Characteristic,
		|		InventoryAllocation.Warehouse AS Warehouse,
		|		InventoryAllocation.Purpose AS Purpose,
		|		CASE
		|			WHEN InventoryAllocation.InventoryState IN(
		|					VALUE(Enum.InventoryStates.AvailablePendingUnlocking),
		|					VALUE(Enum.InventoryStates.AvailableNotSubjectToUnlocking))
		|				THEN InventoryAllocation.ReceiptOrder
		|			ELSE VALUE(Catalog.ControlledLots.EmptyRef)
		|		END AS ControlledLotReference,
		|		InventoryAllocation.ShipmentOrder AS ShipmentOrder,
		|		InventoryAllocation.Count AS Count
		|	FROM
		|		InformationRegister.InventoryAllocation AS InventoryAllocation
		|	WHERE
		|		InventoryAllocation.DemandCharacteristic IN(
		|			VALUE(Enum.DemandCharacteristics.ReserveAsReceived),
		|			VALUE(Enum.DemandCharacteristics.ReserveUponReceiptFromLocked))
		|		AND InventoryAllocation.InventoryState IN(
		|			VALUE(Enum.InventoryStates.InStock),
		|			VALUE(Enum.InventoryStates.AvailablePendingUnlocking),
		|			VALUE(Enum.InventoryStates.AvailableNotSubjectToUnlocking))
		|		AND (
		|			InventoryAllocation.Products,
		|			InventoryAllocation.Characteristic,
		|			InventoryAllocation.Warehouse,
		|			InventoryAllocation.Purpose,
		|			InventoryAllocation.ShipmentOrder) IN(
		|				SELECT
		|					TheOrdersTable.Products AS Products,
		|					TheOrdersTable.Characteristic AS Characteristic,
		|					TheOrdersTable.Warehouse AS Warehouse,
		|					TheOrdersTable.Purpose AS Purpose,
		|					TheOrdersTable.ShipmentOrder AS ShipmentOrder
		|				FROM
		|					TableOfOrdersAndRegistrars AS TheOrdersTable)
		|	
		// For an unrecorded order to the processor, the shipment order is empty, but there are registrars - stages.
		|	UNION ALL
		|	
		|	SELECT
		|		InventoryAllocation.Products AS Products,
		|		InventoryAllocation.Characteristic AS Characteristic,
		|		InventoryAllocation.Warehouse AS Warehouse,
		|		InventoryAllocation.Purpose AS Purpose,
		|		CASE
		|			WHEN InventoryAllocation.InventoryState IN(
		|					VALUE(Enum.InventoryStates.AvailablePendingUnlocking),
		|					VALUE(Enum.InventoryStates.AvailableNotSubjectToUnlocking))
		|				THEN InventoryAllocation.ReceiptOrder
		|			ELSE VALUE(Catalog.ControlledLots.EmptyRef)
		|		END AS ControlledLotReference,
		|		TheOrdersTable.ShipmentOrder AS ShipmentOrder,
		|		InventoryAllocation.Count AS Count
		|	FROM
		|		TableOfOrdersAndRegistrars AS TheOrdersTable
		|			
		|			INNER JOIN InformationRegister.InventoryAllocation AS InventoryAllocation
		|			ON InventoryAllocation.Products = TheOrdersTable.Products
		|			 AND InventoryAllocation.Characteristic = TheOrdersTable.Characteristic
		|			 AND InventoryAllocation.Warehouse = TheOrdersTable.Warehouse
		|			 AND InventoryAllocation.Purpose = TheOrdersTable.Purpose
		|			 AND InventoryAllocation.DemandCharacteristic IN(
		|				VALUE(Enum.DemandCharacteristics.ReserveAsReceived),
		|				VALUE(Enum.DemandCharacteristics.ReserveUponReceiptFromLocked))
		|			AND InventoryAllocation.InventoryState IN(
		|				VALUE(Enum.InventoryStates.InStock),
		|				VALUE(Enum.InventoryStates.AvailablePendingUnlocking),
		|				VALUE(Enum.InventoryStates.AvailableNotSubjectToUnlocking))
		|			 AND InventoryAllocation.ShipmentOrder = TheOrdersTable.Recorder
		|			 AND TheOrdersTable.ShipmentOrder <> TheOrdersTable.Recorder) AS Set
		|	GROUP BY
		|		Set.Products,
		|		Set.Characteristic,
		|		Set.Warehouse,
		|		Set.Purpose,
		|		Set.ControlledLotReference,
		|		Set.ShipmentOrder
		|HAVING
		|	SUM(Set.Reserved) > 0
		|INDEX BY
		|	Products, Characteristic, Warehouse, Purpose, ControlledLotReference, ShipmentOrder
		|;
		|
		|///////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	Set.Products AS Products,
		|	Set.Characteristic AS Characteristic,
		|	Set.Warehouse AS Warehouse,
		|	Set.Purpose AS Purpose,
		|	Set.ControlledLotReference AS ControlledLotReference,
		|	Set.ShipmentOrder AS ShipmentOrder,
		|	SUM(Set.DistributedInWarehouseInSummary) AS DistributedInWarehouseInSummary
		|INTO SuppliedOnWarehouse
		|FROM(
		|	SELECT
		|		Table.Products AS Products,
		|		Table.Characteristic AS Characteristic,
		|		Table.Warehouse AS Warehouse,
		|		Table.Purpose AS Purpose,
		|		Table.ControlledLotReference AS ControlledLotReference,
		|		Table.ShipmentOrder AS ShipmentOrder,
		|		Table.DistributedInWarehouseInSummary AS DistributedInWarehouseInSummary
		|	FROM
		|		ProvidedInStockByLotReference AS Table
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		Table.Products AS Products,
		|		Table.Characteristic AS Characteristic,
		|		Table.Warehouse AS Warehouse,
		|		Table.Purpose AS Purpose,
		|		VALUE(Catalog.ControlledLots.EmptyRef) AS ControlledLotReference,
		|		Table.ShipmentOrder AS ShipmentOrder,
		|		0 AS DistributedInWarehouseInSummary
		|	FROM
		|		ProvidedInStockByLotReference AS Table
		|	WHERE
		|		Table.ControlledLotReference <> VALUE(Catalog.ControlledLots.EmptyRef)) AS Set
		|GROUP BY
		|	Set.Products,
		|	Set.Characteristic,
		|	Set.Warehouse,
		|	Set.Purpose,
		|	Set.ControlledLotReference,
		|	Set.ShipmentOrder
		|INDEX BY
		|	Products, Characteristic, Warehouse, Purpose, ControlledLotReference, ShipmentOrder";
	
	Texts.Add(Text);
	Query.Text = StrConcat(Texts, Common.QueryBatchSeparator());
	Query.Execute();
	Query.Text =
		"SELECT DISTINCT
		|	Table.Products AS Products,
		|	Table.Characteristic AS Characteristic,
		|	Table.Warehouse AS Warehouse,
		|	CAST(Table.Products AS Catalog.Products).ItemsType AS ItemsType
		|INTO TableOfGoodsWithoutPackagesAndWithoutAppointments
		|FROM
		|	TableOfGoodsWithoutPackages AS Table
		|INDEX BY
		|	Products, Characteristic, Warehouse
		|;
		|
		|/////////////////////////////////////////////////
		|SELECT
		|	Table.Products AS Products,
		|	Table.Characteristic AS Characteristic,
		|	Table.Warehouse AS Warehouse,
		|	NOT ISNULL(SettingUpSecurityControlCharacteristic.AvailableStockControl,
		|			ISNULL(SettingUpControlAndProducts.AvailableStockControl,
		|				ISNULL(SetUpSupplyControl.AvailableStockControl, FALSE))) AS ReallocateWarehouseInventory,
		|	ISNULL(SettingUpSecurityControlCharacteristic.AvailableStockControl,
		|			ISNULL(SettingUpControlAndProducts.AvailableStockControl,
		|				ISNULL(SetUpSupplyControl.AvailableStockControl,
		|					Table.ItemsType IN(
		|							VALUE(Enum.ItemsTypes.OwnGoods),
		|							VALUE(Enum.ItemsTypes.ReusablePackage))
		|						AND Table.Warehouse = VALUE(Catalog.Warehouses.EmptyRef)))) AS ShipIfAvailable
		|INTO SecurityControlSettings
		|FROM
		|	TableOfGoodsWithoutPackagesAndWithoutAppointments AS Table
		|		
		|		LEFT JOIN InformationRegister.SetUpSupplyControl AS SettingUpSecurityControlCharacteristic
		|		ON SettingUpSecurityControlCharacteristic.Warehouse = Table.Warehouse
		|		 AND SettingUpSecurityControlCharacteristic.Products = Table.Products
		|		 AND SettingUpSecurityControlCharacteristic.Characteristic = Table.Characteristic
		|		
		|		LEFT JOIN InformationRegister.SetUpSupplyControl AS SettingUpControlAndProducts
		|		ON SettingUpControlAndProducts.Warehouse = Table.Warehouse
		|		 AND SettingUpControlAndProducts.Products = Table.Products
		|		 AND SettingUpControlAndProducts.Characteristic = VALUE(Catalog.ItemsCharacteristics.EmptyRef)
		|		 AND SettingUpSecurityControlCharacteristic.Products IS NULL
		|		
		|		LEFT JOIN InformationRegister.SetUpSupplyControl AS SetUpSupplyControl
		|		ON SetUpSupplyControl.Warehouse = Table.Warehouse
		|		 AND SetUpSupplyControl.Products = VALUE(Catalog.Products.EmptyRef)
		|		 AND SetUpSupplyControl.Characteristic = VALUE(Catalog.ItemsCharacteristics.EmptyRef)
		|		 AND SettingUpSecurityControlCharacteristic.Products IS NULL
		|		 AND SettingUpControlAndProducts.Products IS NULL
		|INDEX BY
		|	Products, Characteristic, Warehouse
		|;
		|DROP TableOfGoodsWithoutPackagesAndWithoutAppointments";
	Query.Execute();
	Texts.Clear();
	
	Text =
		"SELECT ALLOWED
		|	Inventories.Products AS Products,
		|	Inventories.Characteristic AS Characteristic,
		|	Inventories.Warehouse AS Warehouse,
		|	Inventories.Purpose AS Purpose,
		|	Inventories.OrderDocument AS OrderDocument,
		|	Inventories.LockedInStockBalance AS LockedInStockBalance,
		|	Inventories.LockedReceiptBalance AS LockedReceiptBalance,
		|	Inventories.ToUnlockBalance AS ToUnlockBalance,
		|	Inventories.ReserveAtWarehouseFromLockedBalance AS ReserveAtWarehouseFromLockedBalance,
		|	Inventories.ReserveUponReceiptFromLockedBalance AS ReserveUponReceiptFromLockedBalance
		|INTO InventoryAndNeedsBalanceOfControlledLotsReference
		|FROM
		|	AccumulationRegister.InventoryAndDemands.Balance(,
		|		(Products, Characteristic, Warehouse, Purpose) IN(
		|			SELECT
		|				Filter.Products AS Products,
		|				Filter.Characteristic AS Characteristic,
		|				Filter.Warehouse AS Warehouse,
		|				Filter.Purpose AS Purpose
		|			FROM
		|				TableOfGoodsWithoutPackages AS Filter)) AS Inventories
		|INDEX BY
		|	Products, Characteristic, Warehouse, Purpose
		|;
		|
		|///////////////////////////////////////////////
		|SELECT ALLOWED
		|	Inventories.Products AS Products,
		|	Inventories.Characteristic AS Characteristic,
		|	Inventories.Warehouse AS Warehouse,
		|	Inventories.Purpose AS Purpose,
		|	Inventories.InStockBalance AS InStockBalance,
		|	Inventories.LockedInStockBalance AS LockedInStockBalance,
		|	Inventories.OrderedBalance AS OrderedBalance,
		|	Inventories.Received_1Balance AS Received_1Balance,
		|	Inventories.LockedReceiptBalance AS LockedReceiptBalance,
		|	Inventories.ReserveAtWarehouseBalance AS ReserveAtWarehouseBalance,
		|	Inventories.ReserveAsReceivedBalance AS ReserveAsReceivedBalance,
		|	Inventories.SnoozeReservationBalance AS SnoozeReservationBalance,
		|	Inventories.ToSupplyBalance AS ToSupplyBalance,
		|	Inventories.NotProvideBalance AS NotProvideBalance
		|INTO InventoryAndDemandsBalance
		|FROM
		|	AccumulationRegister.InventoryAndDemands.Balance(,
		|		(Products, Characteristic, Warehouse, Purpose) IN(
		|			SELECT
		|				Filter.Products AS Products,
		|				Filter.Characteristic AS Characteristic,
		|				Filter.Warehouse AS Warehouse,
		|				Filter.Purpose AS Purpose
		|			FROM
		|				TableOfGoodsWithoutPackages AS Filter)) AS Inventories
		|INDEX BY
		|	Products, Characteristic, Warehouse, Purpose
		|;
		|
		|///////////////////////////////////////////////
		|SELECT
		|	Calculation.Products AS Products,
		|	Calculation.Characteristic AS Characteristic,
		|	Calculation.Warehouse AS Warehouse,
		|	Calculation.Purpose AS Purpose,
		|	Calculation.ControlledLotReference AS ControlledLotReference,
		|	Calculation.QuantityForShipAction AS QuantityForShipAction
		|INTO TempTableBalance
		|FROM
		|	CalculationOfBalancesForSettingActions AS Calculation
		|
		|INDEX BY
		|	Products, Characteristic, Warehouse, Purpose, ControlledLotReference";
	
	TablesNames = NewTableNamesForCalculatingBalancesForSettingActions();
	TablesNames.Balance = "InventoryAndDemandsBalance"; // @query-part-1
	TablesNames.BalanceSheetsOfControlledLotREFERENCES = "InventoryAndNeedsBalanceOfControlledLotsReference"; // @query-part-1
	TablesNames.Analysts = "TableOfGoodsWithoutPackages"; // @query-part-1
	TablesNames.Result = "CalculationOfBalancesForSettingActions";  // @query-part-1
	CalculationOfBalancesForSettingActions(Text, TablesNames);
	
	Texts.Add(Text);
	
	If BalanceCache = Undefined Then
		
		Text =
			"SELECT
			|	Table.Products AS Products,
			|	Table.Characteristic AS Characteristic,
			|	Table.Warehouse AS Warehouse,
			|	Table.Purpose AS Purpose,
			|	Table.ControlledLotReference AS ControlledLotReference,
			|	Table.ShipmentOrder AS ShipmentOrder,
			|	ISNULL(SuppliedOnWarehouse.DistributedInWarehouseInSummary, 0) AS DistributedInWarehouseInSummary
			|INTO DistributionOfStocksIsProvidedInWarehouse
			|FROM
			|	TableOfOrdersWithoutPackages AS Table
			|		
			|		LEFT JOIN SuppliedOnWarehouse AS SuppliedOnWarehouse
			|		ON SuppliedOnWarehouse.Products = Table.Products
			|		 AND SuppliedOnWarehouse.Characteristic = Table.Characteristic
			|		 AND SuppliedOnWarehouse.Warehouse = Table.Warehouse
			|		 AND SuppliedOnWarehouse.Purpose = Table.Purpose
			|		 AND SuppliedOnWarehouse.ControlledLotReference = Table.ControlledLotReference
			|		 AND SuppliedOnWarehouse.ShipmentOrder = Table.ShipmentOrder
			|INDEX BY
			|	Products, Characteristic, Warehouse, Purpose, ControlledLotReference, ShipmentOrder
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
			|SELECT
			|	Table.Products AS Products,
			|	Table.Characteristic AS Characteristic,
			|	Table.Warehouse AS Warehouse,
			|	Table.Purpose AS Purpose,
			|	Table.ControlledLotReference AS ControlledLotReference,
			|	ISNULL(WarehouseStockBalance.QuantityForShipAction, 0) AS AvailableForInventoryAllocation,
			|	SecurityControlSettings.ReallocateWarehouseInventory AS ReallocateWarehouseInventory,
			|	SecurityControlSettings.ShipIfAvailable AS ShipIfAvailable
			|INTO StockDistributionStockBalance
			|FROM
			|	TableOfGoodsWithoutPackages AS Table
			|		
			|		LEFT JOIN TempTableBalance AS WarehouseStockBalance
			|		ON WarehouseStockBalance.Products = Table.Products
			|		 AND WarehouseStockBalance.Characteristic = Table.Characteristic
			|		 AND WarehouseStockBalance.Warehouse = Table.Warehouse
			|		 AND WarehouseStockBalance.Purpose = Table.Purpose
			|		 AND WarehouseStockBalance.ControlledLotReference = Table.ControlledLotReference
			|		
			|		LEFT JOIN SecurityControlSettings AS SecurityControlSettings
			|		ON SecurityControlSettings.Warehouse = Table.Warehouse
			|		 AND SecurityControlSettings.Products = Table.Products
			|		 AND SecurityControlSettings.Characteristic = Table.Characteristic
			|		
			|INDEX BY
			|	Products, Characteristic, Warehouse, Purpose, ControlledLotReference";
		Texts.Add(Text);
		
	Else
		
		Filter = New Structure("Package", Catalogs.PackagesAndUnitsOfMeasure.EmptyRef());
		Query.SetParameter("TheOrdersTable", BalanceCache.ByOrder.Copy(Filter));
		Query.SetParameter("TableOfGoods", BalanceCache.ByProduct.Copy(Filter));
		
		Text =
			"SELECT
			|	TheOrdersTable.Products AS Products,
			|	TheOrdersTable.Characteristic AS Characteristic,
			|	TheOrdersTable.Warehouse AS Warehouse,
			|	TheOrdersTable.Purpose AS Purpose,
			|	TheOrdersTable.ControlledLotReference AS ControlledLotReference,
			|	TheOrdersTable.ShipmentOrder AS ShipmentOrder,
			|	TheOrdersTable.Count AS DistributedInWarehouseInSummary
			|INTO DistributionOfStocksIsProvidedInCacheWarehouse
			|FROM
			|	&TheOrdersTable AS TheOrdersTable
			|INDEX BY
			|	Products, Characteristic, Warehouse, Purpose, ControlledLotReference, ShipmentOrder
			|;
			|
			|/////////////////////////////////////////////////////////////////////////////
			|SELECT
			|	TableOfGoods.Products AS Products,
			|	TableOfGoods.Characteristic AS Characteristic,
			|	TableOfGoods.Warehouse AS Warehouse,
			|	TableOfGoods.Purpose AS Purpose,
			|	TableOfGoods.ControlledLotReference AS ControlledLotReference,
			|	TableOfGoods.Count AS AvailableForInventoryAllocation,
			|	TableOfGoods.ReallocateWarehouseInventory AS ReallocateWarehouseInventory,
			|	TableOfGoods.ShipIfAvailable AS ShipIfAvailable
			|INTO InventoryAllocationStockBalanceCache
			|	FROM
			|		&TableOfGoods AS TableOfGoods
			|INDEX BY
			|	Products, Characteristic, Warehouse, Purpose, ControlledLotReference
			|;
			|
			|/////////////////////////////////////////////////////////////////////////////
			|SELECT
			|	Table.Products AS Products,
			|	Table.Characteristic  AS Characteristic,
			|	Table.Warehouse AS Warehouse,
			|	Table.Purpose AS Purpose,
			|	Table.ControlledLotReference AS ControlledLotReference,
			|	Table.ShipmentOrder AS ShipmentOrder,
			|	ISNULL(DataOfCache.DistributedInWarehouseInSummary,
			|		ISNULL(SuppliedOnWarehouse.DistributedInWarehouseInSummary, 0)) AS DistributedInWarehouseInSummary
			|INTO DistributionOfStocksIsProvidedInWarehouse
			|FROM
			|	TableOfOrdersWithoutPackages AS Table
			|		
			|		LEFT JOIN DistributionOfStocksIsProvidedInCacheWarehouse AS DataOfCache
			|		ON DataOfCache.Products = Table.Products
			|		 AND DataOfCache.Characteristic = Table.Characteristic
			|		 AND DataOfCache.Warehouse = Table.Warehouse
			|		 AND DataOfCache.Purpose = Table.Purpose
			|		 AND DataOfCache.ControlledLotReference = Table.ControlledLotReference
			|		 AND DataOfCache.ShipmentOrder = Table.ShipmentOrder
			|		
			|		LEFT JOIN SuppliedOnWarehouse AS SuppliedOnWarehouse
			|		ON SuppliedOnWarehouse.Products = Table.Products
			|		 AND SuppliedOnWarehouse.Characteristic = Table.Characteristic
			|		 AND SuppliedOnWarehouse.Warehouse = Table.Warehouse
			|		 AND SuppliedOnWarehouse.Purpose = Table.Purpose
			|		 AND SuppliedOnWarehouse.ControlledLotReference = Table.ControlledLotReference
			|		 AND SuppliedOnWarehouse.ShipmentOrder = Table.ShipmentOrder
			|		 AND DataOfCache.Products IS NULL
			|		
			|INDEX BY
			|	Products, Characteristic, Warehouse, Purpose, ControlledLotReference, ShipmentOrder
			|	
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
			|SELECT ALLOWED
			|	Table.Products AS Products,
			|	Table.Characteristic AS Characteristic,
			|	Table.Warehouse AS Warehouse,
			|	Table.Purpose AS Purpose,
			|	Table.ControlledLotReference AS ControlledLotReference,
			|	ISNULL(DataOfCache.AvailableForInventoryAllocation, ISNULL(WarehouseStockBalance.QuantityForShipAction, 0)) AS AvailableForInventoryAllocation,
			|	ISNULL(DataOfCache.ReallocateWarehouseInventory,
			|		SecurityControlSettings.ReallocateWarehouseInventory) AS ReallocateWarehouseInventory,
			|	ISNULL(DataOfCache.ShipIfAvailable,
			|		SecurityControlSettings.ShipIfAvailable) AS ShipIfAvailable
			|INTO StockDistributionStockBalance
			|FROM
			|	TableOfGoodsWithoutPackages AS Table
			|		
			|		LEFT JOIN InventoryAllocationStockBalanceCache AS DataOfCache
			|		ON DataOfCache.Products = Table.Products
			|		 AND DataOfCache.Characteristic = Table.Characteristic
			|		 AND DataOfCache.Warehouse = Table.Warehouse
			|		 AND DataOfCache.Purpose = Table.Purpose
			|		 AND DataOfCache.ControlledLotReference = Table.ControlledLotReference
			|		
			|		LEFT JOIN TempTableBalance AS WarehouseStockBalance
			|		ON WarehouseStockBalance.Products = Table.Products
			|		 AND WarehouseStockBalance.Characteristic = Table.Characteristic
			|		 AND WarehouseStockBalance.Warehouse= Table.Warehouse
			|		 AND WarehouseStockBalance.Purpose = Table.Purpose
			|		 AND WarehouseStockBalance.ControlledLotReference = Table.ControlledLotReference
			|		 AND DataOfCache.Products IS NULL
			|		
			|		LEFT JOIN SecurityControlSettings AS SecurityControlSettings
			|		ON SecurityControlSettings.Warehouse = Table.Warehouse
			|		 AND SecurityControlSettings.Products = Table.Products
			|		 AND SecurityControlSettings.Characteristic = Table.Characteristic
			|		
			|INDEX BY
			|	Products, Characteristic, Warehouse, Purpose, ControlledLotReference";
		
		Texts.Add(Text);
	EndIf;
	Texts.Add("DROP SecurityControlSettings");
	
	Text =
		"SELECT
		|	Table.Products AS Products,
		|	Table.Characteristic AS Characteristic,
		|	Table.Warehouse AS Warehouse,
		|	Table.Purpose AS Purpose,
		|	Table.ControlledLotReference AS ControlledLotReference,
		|	Table.ShipmentOrder AS ShipmentOrder,
		|	Table.Ship AS Ship,
		|	Table.ToReserve_ AS ToReserve_
		|INTO ChangesTable
		|FROM
		|	&ChangesTable AS Table
		|INDEX BY
		|	Products, Characteristic, Warehouse, Purpose, ControlledLotReference, ShipmentOrder
		|;
		|
		|//////////////////////////////////////////////////
		|SELECT
		|	Table.Products AS Products,
		|	Table.Characteristic AS Characteristic,
		|	Table.Warehouse AS Warehouse,
		|	Table.Purpose AS Purpose,
		|	Table.ControlledLotReference AS ControlledLotReference,
		|	Table.ShipmentOrder AS ShipmentOrder,
		|	CASE WHEN Table.DistributedInWarehouseInSummary > ISNULL(ChangesTable.Ship + ChangesTable.ToReserve_, 0) THEN
		|					- ISNULL(ChangesTable.Ship + ChangesTable.ToReserve_, 0)
		|			ELSE
		|				-Table.DistributedInWarehouseInSummary
		|		END AS AvailableForInventoryAllocation
		|INTO AdjustingOrders
		|FROM
		|	DistributionOfStocksIsProvidedInWarehouse AS Table
		|		
		|		LEFT JOIN ChangesTable AS ChangesTable
		|		ON ChangesTable.Products = Table.Products
		|		 AND ChangesTable.Characteristic = Table.Characteristic
		|		 AND ChangesTable.Warehouse = Table.Warehouse
		|		 AND ChangesTable.Purpose = Table.Purpose
		|		 AND ChangesTable.ControlledLotReference = Table.ControlledLotReference
		|		 AND ChangesTable.ShipmentOrder = Table.ShipmentOrder
		|		 AND ChangesTable.Ship + ChangesTable.ToReserve_ > 0
		|INDEX BY
		|	Products, Characteristic, Warehouse, Purpose, ControlledLotReference, ShipmentOrder
		|;
		|
		|//////////////////////////////////////////////////
		|SELECT
		|	Table.Products AS Products,
		|	Table.Characteristic AS Characteristic,
		|	Table.Warehouse AS Warehouse,
		|	Table.Purpose AS Purpose,
		|	Table.ControlledLotReference AS ControlledLotReference,
		|	SUM(CASE WHEN ISNULL(ChangesTable.Ship + ChangesTable.ToReserve_, 0) > 0 THEN
		|			
		|			CASE WHEN Table.DistributedInWarehouseInSummary < ISNULL(ChangesTable.Ship + ChangesTable.ToReserve_, 0) THEN
		|						Table.DistributedInWarehouseInSummary - ISNULL(ChangesTable.Ship + ChangesTable.ToReserve_, 0)
		|					ELSE
		|						0
		|				END
		|				
		|			ELSE
		|				-ISNULL(ChangesTable.Ship + ChangesTable.ToReserve_, 0)
		|		END) AS AvailableForInventoryAllocation
		|INTO AdjustmentOfGoods
		|FROM
		|	DistributionOfStocksIsProvidedInWarehouse AS Table
		|		
		|		LEFT JOIN ChangesTable AS ChangesTable
		|		ON ChangesTable.Products = Table.Products
		|		 AND ChangesTable.Characteristic = Table.Characteristic
		|		 AND ChangesTable.Warehouse = Table.Warehouse
		|		 AND ChangesTable.Purpose = Table.Purpose
		|		 AND ChangesTable.ControlledLotReference = Table.ControlledLotReference
		|		 AND ChangesTable.ShipmentOrder = Table.ShipmentOrder
		|GROUP BY
		|	Table.Products,
		|	Table.Characteristic,
		|	Table.Warehouse,
		|	Table.Purpose,
		|	Table.ControlledLotReference
		|INDEX BY
		|	Products, Characteristic, Warehouse, Purpose, ControlledLotReference";
		
	Texts.Add(Text);
	
	Text =
		"// Adjustment of orders.
		|SELECT
		|	Table.Products AS Products,
		|	Table.Characteristic AS Characteristic,
		|	Table.Warehouse AS Warehouse,
		|	Table.Purpose AS Purpose,
		|	Table.ControlledLotReference AS ControlledLotReference,
		|	Table.ShipmentOrder AS ShipmentOrder,
		|	Table.Package AS Package,
		|	AdjustingOrders.AvailableForInventoryAllocation / &QueryTextPackagingFactor AS Count
		|FROM
		|	TheOrdersTable AS Table
		|		
		|		LEFT JOIN AdjustingOrders AS AdjustingOrders
		|		ON AdjustingOrders.Products = Table.Products
		|		 AND AdjustingOrders.Characteristic = Table.Characteristic
		|		 AND AdjustingOrders.Warehouse = Table.Warehouse
		|		 AND AdjustingOrders.Purpose = Table.Purpose
		|		 AND AdjustingOrders.ControlledLotReference = Table.ControlledLotReference
		|		 AND AdjustingOrders.ShipmentOrder = Table.ShipmentOrder
		|WHERE
		|	Table.Package <> VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
		|
		|UNION ALL
		|
		|SELECT
		|	Table.Products AS Products,
		|	Table.Characteristic AS Characteristic,
		|	Table.Warehouse AS Warehouse,
		|	Table.Purpose AS Purpose,
		|	Table.ControlledLotReference AS ControlledLotReference,
		|	Table.ShipmentOrder AS ShipmentOrder,
		|	VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef) AS Package,
		|	Table.AvailableForInventoryAllocation AS Count
		|FROM
		|	AdjustingOrders AS Table
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
		|// Adjustment of goods.
		|SELECT
		|	Table.Products AS Products,
		|	Table.Characteristic AS Characteristic,
		|	Table.Warehouse AS Warehouse,
		|	Table.Purpose AS Purpose,
		|	Table.ControlledLotReference AS ControlledLotReference,
		|	Table.Package AS Package,
		|	AdjustmentOfGoods.AvailableForInventoryAllocation / &QueryTextPackagingFactor AS Count
		|FROM
		|	TableOfGoods AS Table
		|		
		|		LEFT JOIN AdjustmentOfGoods AS AdjustmentOfGoods
		|		ON AdjustmentOfGoods.Products = Table.Products
		|		 AND AdjustmentOfGoods.Characteristic = Table.Characteristic
		|		 AND AdjustmentOfGoods.Warehouse = Table.Warehouse
		|		 AND AdjustmentOfGoods.Purpose = Table.Purpose
		|		 AND AdjustmentOfGoods.ControlledLotReference = Table.ControlledLotReference
		|WHERE
		|	Table.Package <> VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
		|
		|UNION ALL
		|
		|SELECT
		|	Table.Products AS Products,
		|	Table.Characteristic AS Characteristic,
		|	Table.Warehouse AS Warehouse,
		|	Table.Purpose AS Purpose,
		|	Table.ControlledLotReference AS ControlledLotReference,
		|	VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef) AS Package,
		|	Table.AvailableForInventoryAllocation AS Count
		|FROM
		|	AdjustmentOfGoods AS Table
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
		|// Leftovers on order.
		|SELECT
		|	Table.Products AS Products,
		|	Table.Characteristic AS Characteristic,
		|	Table.Warehouse AS Warehouse,
		|	Table.Purpose AS Purpose,
		|	Table.ControlledLotReference AS ControlledLotReference,
		|	Table.ShipmentOrder AS ShipmentOrder,
		|	Table.Package AS Package,
		|	InventoryAllocation.DistributedInWarehouseInSummary / &QueryTextPackagingFactor AS Count
		|FROM
		|	TheOrdersTable AS Table
		|		
		|		LEFT JOIN DistributionOfStocksIsProvidedInWarehouse AS InventoryAllocation
		|		ON InventoryAllocation.Products = Table.Products
		|		 AND InventoryAllocation.Characteristic = Table.Characteristic
		|		 AND InventoryAllocation.Warehouse = Table.Warehouse
		|		 AND InventoryAllocation.Purpose = Table.Purpose
		|		 AND InventoryAllocation.ControlledLotReference = Table.ControlledLotReference
		|		 AND InventoryAllocation.ShipmentOrder = Table.ShipmentOrder
		|WHERE
		|	Table.Package <> VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
		|
		|UNION ALL
		|
		|SELECT
		|	Table.Products AS Products,
		|	Table.Characteristic AS Characteristic,
		|	Table.Warehouse AS Warehouse,
		|	Table.Purpose AS Purpose,
		|	Table.ControlledLotReference AS ControlledLotReference,
		|	Table.ShipmentOrder AS ShipmentOrder,
		|	VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef) AS Package,
		|	Table.DistributedInWarehouseInSummary AS Count
		|FROM
		|	DistributionOfStocksIsProvidedInWarehouse AS Table
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
		|// Product balances.
		|SELECT
		|	Table.Products AS Products,
		|	Table.Characteristic AS Characteristic,
		|	Table.Warehouse AS Warehouse,
		|	Table.Purpose AS Purpose,
		|	Table.ControlledLotReference AS ControlledLotReference,
		|	Table.Package AS Package,
		|	InventoryAllocation.AvailableForInventoryAllocation / &QueryTextPackagingFactor AS Count,
		|	InventoryAllocation.ReallocateWarehouseInventory AS ReallocateWarehouseInventory,
		|	InventoryAllocation.ShipIfAvailable AS ShipIfAvailable
		|FROM
		|	TableOfGoods AS Table
		|		
		|		LEFT JOIN StockDistributionStockBalance AS InventoryAllocation
		|		ON InventoryAllocation.Products = Table.Products
		|		 AND InventoryAllocation.Characteristic = Table.Characteristic
		|		 AND InventoryAllocation.Warehouse = Table.Warehouse
		|		 AND InventoryAllocation.Purpose = Table.Purpose
		|		 AND InventoryAllocation.ControlledLotReference = Table.ControlledLotReference
		|WHERE
		|	Table.Package <> VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
		|
		|UNION ALL
		|
		|SELECT
		|	Table.Products AS Products,
		|	Table.Characteristic AS Characteristic,
		|	Table.Warehouse AS Warehouse,
		|	Table.Purpose AS Purpose,
		|	Table.ControlledLotReference AS ControlledLotReference,
		|	VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef) AS Package,
		|	Table.AvailableForInventoryAllocation AS Count,
		|	Table.ReallocateWarehouseInventory AS ReallocateWarehouseInventory,
		|	Table.ShipIfAvailable AS ShipIfAvailable
		|FROM
		|	StockDistributionStockBalance AS Table
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
		|// Document table.
		|SELECT
		|	Table.LineNumber                             AS Id,
		|	WarehouseStockBalance.ReallocateWarehouseInventory AS ReallocateInventory,
		|	WarehouseStockBalance.ShipIfAvailable           AS ShipIfAvailable,
		|	(SuppliedOnWarehouse.DistributedInWarehouseInSummary
		|			+ WarehouseStockBalance.AvailableForInventoryAllocation
		|			+ AdjustmentOfGoods.AvailableForInventoryAllocation
		|			+ AdjustingOrders.AvailableForInventoryAllocation)
		|		/ &QueryTextPackagingFactor          AS Available
		|FROM
		|	TemporaryDocumentDataTable AS Table
		|		
		|		LEFT JOIN DistributionOfStocksIsProvidedInWarehouse AS SuppliedOnWarehouse
		|		ON SuppliedOnWarehouse.Products    = Table.Products
		|		 AND SuppliedOnWarehouse.Characteristic  = Table.Characteristic
		|		 AND SuppliedOnWarehouse.Warehouse =
		|			CASE WHEN Table.Products.ItemsType IN(
		|				VALUE(Enum.ItemsTypes.OwnGoods),
		|				VALUE(Enum.ItemsTypes.ReusablePackage)) THEN
		|					Table.Warehouse
		|				ELSE
		|					Table.Department
		|			END
		|		 AND SuppliedOnWarehouse.Purpose =
		|			CASE WHEN Table.WithAssignment THEN
		|					CASE WHEN Table.Purpose = VALUE(Catalog.Assignments.EmptyRef) THEN
		|								UNDEFINED
		|							ELSE
		|								Table.Purpose
		|						END
		|				ELSE
		|					VALUE(Catalog.Assignments.EmptyRef)
		|			END
		|		 AND SuppliedOnWarehouse.ControlledLotReference = Table.ControlledLotReference
		|		 AND SuppliedOnWarehouse.ShipmentOrder = Table.ShipmentOrder
		|		
		|		LEFT JOIN StockDistributionStockBalance AS WarehouseStockBalance
		|		ON WarehouseStockBalance.Products    = Table.Products
		|		 AND WarehouseStockBalance.Characteristic  = Table.Characteristic
		|		 AND WarehouseStockBalance.Warehouse =
		|			CASE WHEN Table.Products.ItemsType IN(
		|				VALUE(Enum.ItemsTypes.OwnGoods),
		|				VALUE(Enum.ItemsTypes.ReusablePackage)) THEN
		|					Table.Warehouse
		|				ELSE
		|					Table.Department
		|			END
		|		 AND WarehouseStockBalance.Purpose =
		|			CASE WHEN Table.WithAssignment THEN
		|					CASE WHEN Table.Purpose = VALUE(Catalog.Assignments.EmptyRef) THEN
		|								UNDEFINED
		|							ELSE
		|								Table.Purpose
		|						END
		|				ELSE
		|					VALUE(Catalog.Assignments.EmptyRef)
		|			END
		|		 AND WarehouseStockBalance.ControlledLotReference = Table.ControlledLotReference
		|		
		|		LEFT JOIN AdjustingOrders AS AdjustingOrders
		|		ON AdjustingOrders.Products    = Table.Products
		|		 AND AdjustingOrders.Characteristic  = Table.Characteristic
		|		 AND AdjustingOrders.Warehouse =
		|			CASE WHEN Table.Products.ItemsType IN(
		|				VALUE(Enum.ItemsTypes.OwnGoods),
		|				VALUE(Enum.ItemsTypes.ReusablePackage)) THEN
		|					Table.Warehouse
		|				ELSE
		|					Table.Department
		|			END
		|		 AND AdjustingOrders.Purpose =
		|			CASE WHEN Table.WithAssignment THEN
		|					CASE WHEN Table.Purpose = VALUE(Catalog.Assignments.EmptyRef) THEN
		|								UNDEFINED
		|							ELSE
		|								Table.Purpose
		|						END
		|				ELSE
		|					VALUE(Catalog.Assignments.EmptyRef)
		|			END
		|		 AND AdjustingOrders.ControlledLotReference = Table.ControlledLotReference
		|		 AND AdjustingOrders.ShipmentOrder = Table.ShipmentOrder
		|		
		|		LEFT JOIN AdjustmentOfGoods AS AdjustmentOfGoods
		|		ON AdjustmentOfGoods.Products    = Table.Products
		|		 AND AdjustmentOfGoods.Characteristic  = Table.Characteristic
		|		 AND AdjustmentOfGoods.Warehouse =
		|			CASE WHEN Table.Products.ItemsType IN(
		|				VALUE(Enum.ItemsTypes.OwnGoods),
		|				VALUE(Enum.ItemsTypes.ReusablePackage)) THEN
		|					Table.Warehouse
		|				ELSE
		|					Table.Department
		|			END
		|		 AND AdjustmentOfGoods.Purpose =
		|			CASE WHEN Table.WithAssignment THEN
		|					CASE WHEN Table.Purpose = VALUE(Catalog.Assignments.EmptyRef) THEN
		|								UNDEFINED
		|							ELSE
		|								Table.Purpose
		|						END
		|				ELSE
		|					VALUE(Catalog.Assignments.EmptyRef)
		|			END
		|		 AND AdjustmentOfGoods.ControlledLotReference = Table.ControlledLotReference";
	Texts.Add(Text);
	
	Text = StrConcat(Texts, Common.QueryBatchSeparator());
	
	QueryTextPackagingFactor = Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
		"Table.Package",
		"Table.Products");
	
	Query.Text = StrReplace(Text, "&QueryTextPackagingFactor", StrTemplate("ISNULL(%1, 1)", QueryTextPackagingFactor));
	
	ResultsPackage = Query.ExecuteBatch();
	UBound = ResultsPackage.UBound();
	
	Result = New Structure();
	Result.Insert("AdjustingOrders", ResultsPackage[UBound - 4].Unload());
	Result.Insert("AdjustmentOfGoods", ResultsPackage[UBound - 3].Unload());
	Result.Insert("OrderBalances_1",      ResultsPackage[UBound - 2].Unload());
	Result.Insert("ProductBalances_",      ResultsPackage[UBound - 1].Unload());
	Result.Insert("DocumentTable",     ResultsPackage[UBound].Unload());
	Return Result;
	
EndFunction

Procedure UpdateColumnIsAvailableWhenProcessingRowOfTablePart(CurrentRow, TempTablesManager, EmbeddingParameters)
	
	Query = New Query();
	Query.TempTablesManager = TempTablesManager;
	LinkID = New UUID("9e1b1ca8-ce19-46d8-a7ef-0292f4cd9799");
	Query.SetParameter("NonExistentAssignment", Catalogs.Assignments.GetRef(LinkID));
	Query.Text =
		"SELECT
		|	DocumentTable.Products    AS Products,
		|	DocumentTable.Characteristic  AS Characteristic,
		|	DocumentTable.ShipmentOrder AS ShipmentOrder,
		|	DocumentTable.Package        AS Package,
		|	
		|	CASE
		|		WHEN DocumentTable.Products.ItemsType IN(
		|				VALUE(Enum.ItemsTypes.OwnGoods),
		|				VALUE(Enum.ItemsTypes.ReusablePackage))
		|			THEN DocumentTable.Warehouse
		|		ELSE DocumentTable.Department
		|	END AS Warehouse,
		|	
		|	CASE
		|		WHEN DocumentTable.WithAssignment
		|			THEN
		|				CASE
		|					WHEN DocumentTable.Purpose = VALUE(Catalog.Assignments.EmptyRef)
								// so that free balances are not selected if the destination for the document is not yet in the database.
		|						THEN &NonExistentAssignment
		|					ELSE
		|						DocumentTable.Purpose
		|				END
		|		ELSE VALUE(Catalog.Assignments.EmptyRef)
		|	END AS Purpose,
		|	DocumentTable.ControlledLotReference AS ControlledLotReference
		|FROM
		|	TemporaryDocumentDataTable AS DocumentTable";
	Table = Query.Execute().Unload();
	
	KeyOrders = "Products,Characteristic,Warehouse,Purpose,ControlledLotReference,ShipmentOrder,Package";
	KeyProducts_ = "Products,Characteristic,Warehouse,Purpose,ControlledLotReference,Package";
	SelectingRowsByOrder = New Structure(KeyOrders);
	SelectingRowsByProduct = New Structure(KeyProducts_);
	FillPropertyValues(SelectingRowsByOrder, Table[0]);
	FillPropertyValues(SelectingRowsByProduct, Table[0]);
	
	Balance = GetFromTempStorage(EmbeddingParameters.AddressOfBalances);
	
	FoundRowsByOrder = Balance.ByOrder.FindRows(SelectingRowsByOrder);
	ProductLinesFound = Balance.ByProduct.FindRows(SelectingRowsByProduct);
	If FoundRowsByOrder.Count() = 0 Or ProductLinesFound.Count() = 0 Then
		
		StructureOfResidues = BalancesForColumnAreAvailable(
			Query.TempTablesManager,
			Balance,
			Balance.ChangesToDocument);
		
		AddToTable(Balance.ByOrder, StructureOfResidues.OrderBalances_1, SelectingRowsByOrder);
		AddToTable(Balance.AdjustingOrders, StructureOfResidues.AdjustingOrders, SelectingRowsByOrder);
		AddToTable(Balance.ByProduct, StructureOfResidues.ProductBalances_, SelectingRowsByProduct);
		AddToTable(Balance.AdjustmentOfGoods, StructureOfResidues.AdjustmentOfGoods, SelectingRowsByProduct);
		
	EndIf;
	
	FoundRowsByOrder = Balance.ByOrder.FindRows(SelectingRowsByOrder);
	ProductLinesFound = Balance.ByProduct.FindRows(SelectingRowsByProduct);
	FoundRowsAdjustingOrders = Balance.AdjustingOrders.FindRows(SelectingRowsByOrder);
	FoundRowsAdjustmentOfProducts = Balance.AdjustmentOfGoods.FindRows(SelectingRowsByProduct);
	
	If ProductLinesFound.Count() > 0 Then // if there is no record-level access to the warehouse, there will be no row.
		
		CurrentRow.Available = ProductLinesFound[0].Count
			+ FoundRowsByOrder[0].Count
			+ FoundRowsAdjustingOrders[0].Count
			+ FoundRowsAdjustmentOfProducts[0].Count;
			
		CurrentRow.ReallocateInventory = ProductLinesFound[0].ReallocateWarehouseInventory;
		CurrentRow.ShipIfAvailable  = ProductLinesFound[0].ShipIfAvailable;
		
	EndIf;
	
	CurrentRow.ReallocateInventory = ProductLinesFound[0].ReallocateWarehouseInventory;
	CurrentRow.ShipIfAvailable  = ProductLinesFound[0].ShipIfAvailable;
	EmbeddingParameters.AddressOfBalances   = PutToTempStorage(Balance, EmbeddingParameters.AddressOfBalances);
	
	AvailableResiduesSupplementMatchingProducts(EmbeddingParameters, Table[0], CurrentRow.IDOfRowReceived);
	
EndProcedure

Function DefaultSoftwareOptionFillOptions()
	
	Parameters = New Structure();
	Parameters.Insert("ItemsType");
	Parameters.Insert("FillInSeparately");
	Parameters.Insert("UseShipmentByRowsInSalesOrder");
	Parameters.Insert("SalesOrderStatus");
	Return Parameters;
	
EndFunction

Function ProvisionOptionAndFlagAreSeparateByDefault(FillParameters)
	
	ItemsType = FillParameters.ItemsType;
	FillInSeparately = FillParameters.FillInSeparately;
	Status = FillParameters.SalesOrderStatus;
	UseShipmentByRowsInSalesOrder = FillParameters.UseShipmentByRowsInSalesOrder;
	
	// Special filling for Customer Orders (including Refund Requests) in the case when line-by-line shipment is not used.
	ShipStatuses = New Array;
	ShipStatuses.Add(PredefinedValue("Enum.SalesOrderStatuses.ToShip"));
	ShipStatuses.Add(PredefinedValue("Enum.SalesOrderStatuses.Closed"));
	ShipStatuses.Add(PredefinedValue("Enum.StatusesOfRequestsForReturnOfGoodsFromCustomers.ToShip"));
	ShipStatuses.Add(PredefinedValue("Enum.StatusesOfRequestsForReturnOfGoodsFromCustomers.Executed"));
	
	StatusesFromWarehouse = New Array;
	StatusesFromWarehouse.Add(PredefinedValue("Enum.SalesOrderStatuses.ToSupply"));
	StatusesFromWarehouse.Add(PredefinedValue("Enum.StatusesOfRequestsForReturnOfGoodsFromCustomers.ToSupply"));
	
	NoStatusesRequired = New Array;
	NoStatusesRequired.Add(PredefinedValue("Enum.SalesOrderStatuses.NotApproved"));
	NoStatusesRequired.Add(PredefinedValue("Enum.StatusesOfRequestsForReturnOfGoodsFromCustomers.NotAgreedUpon"));
	NoStatusesRequired.Add(PredefinedValue("Enum.StatusesOfRequestsForReturnOfGoodsFromCustomers.ForReturn"));
	NoStatusesRequired.Add(PredefinedValue("Enum.StatusesOfRequestsForReturnOfGoodsFromCustomers.IsRejected"));
	
	SupplyOption = Undefined;
	WithAssignment        = Undefined;
	
	If Not UseShipmentByRowsInSalesOrder
		And ShipStatuses.Find(Status) <> Undefined Then
		
		SupplyOption = PredefinedValue("Enum.SupplyOptions.Ship");
		WithAssignment = False;
		
	ElsIf Not UseShipmentByRowsInSalesOrder
		And StatusesFromWarehouse.Find(Status) <> Undefined Then
		
		If ItemsType = PredefinedValue("Enum.ItemsTypes.Work_5")
				Or ItemsType = PredefinedValue("Enum.ItemsTypes.OperationService") Then
			
			SupplyOption = PredefinedValue("Enum.SupplyOptions.NotRequired");
			WithAssignment = False;
			
		Else
			
			SupplyOption = PredefinedValue("Enum.SupplyOptions.FromWarehouse");
			WithAssignment = False;
			
		EndIf;
		
	ElsIf Not UseShipmentByRowsInSalesOrder
		And NoStatusesRequired.Find(Status) <> Undefined Then
		
		SupplyOption = PredefinedValue("Enum.SupplyOptions.NotRequired");
		WithAssignment = False;
		
		
	ElsIf ItemsType = PredefinedValue("Enum.ItemsTypes.OperationService") Then

		SupplyOption = PredefinedValue("Enum.SupplyOptions.NotRequired");
		WithAssignment = False;

	ElsIf ItemsType = PredefinedValue("Enum.ItemsTypes.Work_5") Then
		
		If FillInSeparately = True Then
			
			SupplyOption = PredefinedValue("Enum.SupplyOptions.ToSupply");
			WithAssignment = True;
			
		Else
			
			SupplyOption = PredefinedValue("Enum.SupplyOptions.NotRequired");
			WithAssignment = False;
			
		EndIf;

	ElsIf ItemsType = PredefinedValue("Enum.ItemsTypes.ReusablePackage") Then

		SupplyOption = PredefinedValue("Enum.SupplyOptions.ToSupply");
		WithAssignment = False;

	Else // OwnGoods

		SupplyOption = PredefinedValue("Enum.SupplyOptions.ToSupply");
		WithAssignment = FillInSeparately = True;

	EndIf;
	
	Return New Structure("SupplyOption,WithAssignment", SupplyOption, WithAssignment);

EndFunction

Function TableDecorated(Query, RegisterManager, NameOfTemporaryTableOfSelectedRows, NameOfTemporaryTableOfAllRows)
	
	Texts = New Array();
	SourceTable =
		"SELECT
		|	Table.Products       AS Products,
		|	Table.Characteristic     AS Characteristic,
		|	CASE
		|		WHEN CAST(Table.Products AS Catalog.Products).ItemsType IN(
		|				VALUE(Enum.ItemsTypes.OwnGoods),
		|				VALUE(Enum.ItemsTypes.ReusablePackage))
		|			THEN Table.Warehouse
		|		ELSE Table.Department
		|	END AS Warehouse,
		|	Table.Series AS Series,
		|	Table.ShipmentOrder AS Ref,
		|	Table.SupplyOption AS SupplyOption,
		|	Table.WithAssignment AS WithAssignment,
		|	Table.RowCode AS RowCode,
		|	Table.Count AS Count,
		|	CASE
		|		WHEN Table.WithAssignment
		|			THEN Table.Purpose
		|		ELSE VALUE(Catalog.Assignments.EmptyRef)
		|	END Purpose,
		|	Table.ControlledLotReference AS ControlledLotReference
		|FROM
		|	TempTableOverridable AS Table";
	
	FilterIssued_1 =
		"SELECT
		|	Table.ShipmentOrder AS Ref,
		|	Table.RowCode AS RowCode
		|FROM
		|	TempTableOverridable AS Table";
	
	FilterGoodsForIssue =
		"SELECT
		|	Table.Products AS Products,
		|	Table.Characteristic AS Characteristic,
		|	Table.Warehouse AS Warehouse,
		|	Table.ShipmentOrder AS Ref,
		|	Table.Series AS Series,
		|	CASE
		|		WHEN Table.WithAssignment
		|			THEN Table.Purpose
		|		ELSE VALUE(Catalog.Assignments.EmptyRef)
		|	END Purpose,
		|	Table.ControlledLotReference AS ControlledLotReference
		|FROM
		|	TempTableOverridable AS Table
		|WHERE
		|	CAST(Table.Products AS Catalog.Products).ItemsType IN(
		|		VALUE(Enum.ItemsTypes.OwnGoods),
		|		VALUE(Enum.ItemsTypes.ReusablePackage))";
	
	AdjustmentOfGoodsForShipment =
		"SELECT
		|	Table.Products AS Products,
		|	Table.Characteristic AS Characteristic,
		|	Table.Warehouse AS Warehouse,
		|	Table.Series AS Series,
		|	-Table.Count AS ToShip,
		|	CASE
		|		WHEN Table.WithAssignment
		|			THEN Table.Purpose
		|		ELSE VALUE(Catalog.Assignments.EmptyRef)
		|	END Purpose,
		|	Table.ControlledLotReference AS ControlledLotReference
		|FROM
		|	TempTableOverridable AS Table
		|WHERE
		|	Table.SupplyOption = VALUE(Enum.SupplyOptions.Ship)
		|		AND CAST(Table.Products AS Catalog.Products).ItemsType IN(
		|			VALUE(Enum.ItemsTypes.OwnGoods),
		|			VALUE(Enum.ItemsTypes.ReusablePackage))
		|
		|UNION ALL
		|
		|SELECT
		|	Table.Products AS Products,
		|	Table.Characteristic AS Characteristic,
		|	Table.Warehouse AS Warehouse,
		|	Table.Series AS Series,
		|	Table.Count AS ToShip,
		|	CASE
		|		WHEN Table.WithAssignment
		|			THEN Table.Purpose
		|		ELSE VALUE(Catalog.Assignments.EmptyRef)
		|	END Purpose,
		|	Table.ControlledLotReference AS ControlledLotReference
		|FROM
		|	TemporaryTableOfAllRowsRedefined AS Table
		|WHERE
		|	Table.SupplyOption = VALUE(Enum.SupplyOptions.Ship)
		|		AND CAST(Table.Products AS Catalog.Products).ItemsType IN(
		|			VALUE(Enum.ItemsTypes.OwnGoods),
		|			VALUE(Enum.ItemsTypes.ReusablePackage))";
	
	Texts = New Array();
	Texts.Add(SourceTable);
	Texts.Add(FilterIssued_1);
	Texts.Add(FilterGoodsForIssue);
	Texts.Add(AdjustmentOfGoodsForShipment);
	
	Text = StrConcat(Texts, Common.QueryBatchSeparator());
	
	Text = StrReplace(Text, "TempTableOverridable", NameOfTemporaryTableOfSelectedRows);
	Text = StrReplace(Text, "TemporaryTableOfAllRowsRedefined", NameOfTemporaryTableOfAllRows);
	
	Query.Text = Text;
	
	RequestResultsPackage = Query.ExecuteBatch();
	SourceTable = RequestResultsPackage[0].Unload();
	FilterIssued_1 = RequestResultsPackage[1].Unload();
	FilterGoodsForIssue = RequestResultsPackage[2].Unload();
	AdjustmentOfGoodsForShipment = RequestResultsPackage[3].Unload();
	
	IssueInvoices = RegisterManager.TableDecorated(FilterIssued_1, Undefined, True);
	ExecuteByOrders = AccumulationRegisters.GoodsForIssue.TableDecorated(
		FilterGoodsForIssue,
		AdjustmentOfGoodsForShipment);
	IssueInvoices.Indexes.Add("RowCode,Ref");
	ExecuteByOrders.Indexes.Add("Products,Characteristic,Warehouse,Purpose,Series");
	ExecuteByOrders.Indexes.Add("Products,Characteristic,Warehouse,Purpose");
	
	ExecuteByOrders.Columns.Add("WrittenOff", Common.TypeDescriptionNumber(15, 3));
	
	NewTable = NewTableIsDecorated();
	
	ByARAPDocuments = NewTable;
	ColumnsToCopy = "Products,Characteristic,Warehouse,Purpose,
		|Series,SupplyOption,WithAssignment,Count";
	ByNotes = NewTable.CopyColumns(ColumnsToCopy);
	ByNotes.Indexes.Add("Products,Characteristic,Warehouse,Purpose,Series");
	ByNotes.Indexes.Add("Products,Characteristic,Warehouse,Purpose");
	
	FilterByARAPDocuments = New Structure("RowCode,Ref");
	FilterByNotes = New Structure("Products,Characteristic,Warehouse,Purpose,Series");
	For Each LineProducts_ In SourceTable Do
		
		// Issued according to invoices.
		FillPropertyValues(FilterByARAPDocuments, LineProducts_);
		FoundRows = IssueInvoices.FindRows(FilterByARAPDocuments);
		
		NewRow = ByARAPDocuments.Add();
		FillPropertyValues(NewRow, LineProducts_);
		
		NewRow.Count = ?(FoundRows.Count() > 0, FoundRows[0].Count, 0);
		NewRow.QuantityInOrder = LineProducts_.Count;
		
	EndDo;
	
	// Write-off of issued invoices.
	For Each LineProducts_ In ByARAPDocuments Do
		
		If LineProducts_.Count > 0 Then
			
			FillPropertyValues(FilterByNotes, LineProducts_);
			FoundRows = ExecuteByOrders.FindRows(FilterByNotes);
			If FoundRows.Count() > 0 Then
				
				FoundRows[0].WrittenOff = FoundRows[0].WrittenOff + LineProducts_.Count;
				
			EndIf;
			
		EndIf;
		
	EndDo;
	
	For Each LineProducts_ In ExecuteByOrders Do
		
		If LineProducts_.Count > LineProducts_.WrittenOff Then // balances not written on invoices
			
			NewRow = ByNotes.Add();
			FillPropertyValues(NewRow, LineProducts_);
			
			NewRow.SupplyOption = Enums.SupplyOptions.Ship;
			NewRow.WithAssignment        = ValueIsFilled(LineProducts_.Purpose);
			NewRow.Count         = LineProducts_.Count - LineProducts_.WrittenOff;
			
		EndIf;
		
	EndDo;
	
	// If less is shipped on invoices in the line than in the order, it is necessary to move the quantity from orders to the invoice data.
	// Example:
	// There are 10 pieces in the order
	// By the way , 5 pieces
	// According to the size of 4 pieces
	// We move 4 pieces to the table by the wayside. As a result, there are 9 pieces on the order, 0 pieces on the order.
	// This move allows you to link the balances received from the table by numbers to the row codes.
	
	For Each LineProducts_ In ByARAPDocuments Do
		
		If LineProducts_.Count = 0 Then
			Continue;
		EndIf;
		
		If LineProducts_.QuantityInOrder > LineProducts_.Count Then
			FillPropertyValues(FilterByNotes, LineProducts_);
			FoundRows = ByNotes.FindRows(FilterByNotes);
			
			If FoundRows.Count() = 0 Then
				SelectionForOrdersWithoutSeries = New Structure("Products,Characteristic,Warehouse,Purpose");
				FillPropertyValues(SelectionForOrdersWithoutSeries, LineProducts_);
				FoundRows = ByNotes.FindRows(SelectionForOrdersWithoutSeries);
			EndIf;
			
			For Each OrderLine_1 In FoundRows Do
				
				ItRemainsToWriteOff = LineProducts_.QuantityInOrder - LineProducts_.Count;
				ForDebiting = ?(ItRemainsToWriteOff > OrderLine_1.Count, OrderLine_1.Count, ItRemainsToWriteOff);
				LineProducts_.Count = LineProducts_.Count + ForDebiting;
				OrderLine_1.Count = OrderLine_1.Count - ForDebiting;
				
			EndDo;
		EndIf;
		
	EndDo;
	
	For Each LineProducts_ In ByARAPDocuments Do
		
		If LineProducts_.QuantityInOrder > LineProducts_.Count Then
			FillPropertyValues(FilterByNotes, LineProducts_);
			FoundRows = ByNotes.FindRows(FilterByNotes);
			
			If FoundRows.Count() = 0 Then
				SelectionForOrdersWithoutSeries = New Structure("Products,Characteristic,Warehouse,Purpose");
				FillPropertyValues(SelectionForOrdersWithoutSeries, LineProducts_);
				FoundRows = ByNotes.FindRows(SelectionForOrdersWithoutSeries);
			EndIf;
			
			For Each OrderLine_1 In FoundRows Do
				
				ItRemainsToWriteOff = LineProducts_.QuantityInOrder - LineProducts_.Count;
				ForDebiting = ?(ItRemainsToWriteOff > OrderLine_1.Count, OrderLine_1.Count, ItRemainsToWriteOff);
				LineProducts_.Count = LineProducts_.Count + ForDebiting;
				OrderLine_1.Count = OrderLine_1.Count - ForDebiting;
				
			EndDo;
		EndIf;
		
	EndDo;
	
	Result = ByARAPDocuments;
	Return Result;
	
EndFunction

Procedure FillInTableNamesAsAppropriate(EmbeddingParameters, Tables)
	
	Counter = 1;
	For Each Item In Tables Do
		
		Item.Value.TableNameInQuery  = ?(EmbeddingParameters.InternalParameters.IsDocument,
			EmbeddingParameters.ObjectName + Mid(Item.Key, StrLen("Object") + 1),
			EmbeddingParameters.ObjectName + "." + Item.Key);
		Item.Value.TempTableName = "TT" + Counter + StrReplace(Item.Value.TableNameInQuery, ".", "");
		
		Counter = Counter + 1;
		
	EndDo;
	
EndProcedure

Function QueryTextTemporaryDocumentDataTable(EmbeddingParameters, Tables)
	
	QueryTexts = New Array();
	QueryText = EmbeddingParameters.DescriptionOfGettingDocumentData;
	TextsOfDestruction = New Array();
	Substitutions_3 = New ValueTable();
	Substitutions_3.Columns.Add("SearchSubstring");
	Substitutions_3.Columns.Add("ReplaceSubstring");
	
	For Each Item In Tables Do
		
		Replacement = Substitutions_3.Add();
		Replacement.SearchSubstring = Item.Value.TableNameInQuery;
		Replacement.ReplaceSubstring = Item.Value.TempTableName;
		
		TemporaryTableQueryText = TemporaryTableQueryTextByTableColumns(
			Item.Value.TempTableName, Item.Value.Table);
		QueryTexts.Add(TemporaryTableQueryText);
		TextsOfDestruction.Add("DROP " + Item.Value.TempTableName);
		
	EndDo;
	
	Substitutions_3.Sort("SearchSubstring Desc");
	For IndexOf = 0 To Substitutions_3.Count() - 1 Do
		Replacement = Substitutions_3[IndexOf];
		QueryText = StrReplace(QueryText, Replacement.SearchSubstring, Replacement.ReplaceSubstring);
	EndDo;
	
	QueryTexts.Add(QueryText);
	CommonClientServer.SupplementArray(QueryTexts, TextsOfDestruction);
	QueryText = StrConcat(QueryTexts, Common.QueryBatchSeparator());
	Return QueryText;
	
EndFunction

Procedure QueryTextTempTableOfDocumentDataBatchProcessing(
			EmbeddingParameters, Tables, QueriesTexts, NameOfTableBeingProcessed)
	
	Substitutions_3 = New ValueTable();
	Substitutions_3.Columns.Add("SearchSubstring");
	Substitutions_3.Columns.Add("ReplaceSubstring");
	
	Replacement = Substitutions_3.Add();
	Replacement.SearchSubstring = "1 AS LineNumber"; // header, disassembly order
	Replacement.ReplaceSubstring = "Attributes.IdOfTTRow AS LineNumber";
	
	For Each Item In Tables Do
		
		Replacement = Substitutions_3.Add();
		Replacement.SearchSubstring = Item.Value.TableNameInQuery;
		Replacement.ReplaceSubstring = Item.Value.TempTableName;
		
	EndDo;
	
	Replacement = Substitutions_3.Add();
	Replacement.SearchSubstring = ".LineNumber";
	Replacement.ReplaceSubstring = ".IdOfTTRow";
		
	Substitutions_3.Sort("SearchSubstring Desc");
	
	For Each Item In Tables Do
		
		If Item.Value.TableNameInQuery = EmbeddingParameters.TableName
				Or EmbeddingParameters.TableName = Undefined // header, disassembly order
					And Item.Value.TableNameInQuery = EmbeddingParameters.ObjectName Then
			Continue;
		EndIf;
		
		Text = TemporaryTableQueryTextByTableColumns(
			Item.Value.TempTableName, Item.Value.Table);
		
		For IndexOf = 0 To Substitutions_3.Count() - 1 Do
			Replacement = Substitutions_3[IndexOf];
			Text = StrReplace(Text, Replacement.SearchSubstring, Replacement.ReplaceSubstring);
		EndDo;
		Text = StrReplace(Text, NameOfTableBeingProcessed, "TTDataSource");
		
		QueriesTexts.Add(Text, Item.Value.TempTableName);
		
	EndDo;
	
	Text = EmbeddingParameters.DescriptionOfGettingDocumentData;
	For IndexOf = 0 To Substitutions_3.Count() - 1 Do
		Replacement = Substitutions_3[IndexOf];
		Text = StrReplace(Text, Replacement.SearchSubstring, Replacement.ReplaceSubstring);
	EndDo;
	Text = StrReplace(Text, NameOfTableBeingProcessed, "TTDataSource");
	Texts = StrSplit(Text, ";");
	If Texts.Count() > 1 Then // there are temporary tables
		For IndexOf = 0 To Texts.Count() - 2 Do
			Text = Texts[IndexOf];
			FoundCharacterIs1 = StrFind(Text, "INTO") + StrLen("INTO");
			FoundSymbol2 = StrFind(Text, Chars.LF, , FoundCharacterIs1);
			TempTableName = TrimAll(Mid(Text, FoundCharacterIs1, FoundSymbol2 - FoundCharacterIs1));
			QueriesTexts.Add(Text, TempTableName);
		EndDo;
		Text = Texts[Texts.Count() - 1];
	EndIf;
	QueriesTexts.Add(Text, "TemporaryDocumentDataTable");
	
EndProcedure

Function MandatoryTableForTemporaryDocumentDataTable(Query)
	
	Query.Text =
		"SELECT
		|	DocumentTable.LineNumber AS LineNumber,
		|	DocumentTable.Warehouse = VALUE(Catalog.Warehouses.EmptyRef) AS WarehouseIsNotFull,
		|	CASE WHEN NOT DocumentTable.Canceled
		|				AND DocumentTable.Products.ItemsType IN(
		|					VALUE(Enum.ItemsTypes.OwnGoods),
		|					VALUE(Enum.ItemsTypes.ReusablePackage))
		|				AND (DocumentTable.SupplyOption IN(
		|						VALUE(Enum.SupplyOptions.Ship),
		|						VALUE(Enum.SupplyOptions.FromWarehouse))
		|					OR DocumentTable.SupplyOption IN(
		|									VALUE(Enum.SupplyOptions.ReserveAsReceived),
		|									VALUE(Enum.SupplyOptions.ToSupply))
		|						AND DocumentTable.ReadyForSupply) THEN
		|				TRUE
		|			ELSE
		|				FALSE
		|		END AS WarehouseIsRequired,
		|	
		|	DocumentTable.RequestShipmentOn = DATETIME(1, 1,1) AS ShipmentDateNotFilledIn,
		|	NOT DocumentTable.Canceled
		|		AND DocumentTable.SupplyOption = VALUE(Enum.SupplyOptions.Ship)
		|		AND DocumentTable.ReadyToShip AS DateOfShipmentRequired_
		|FROM
		|	TemporaryDocumentDataTable AS DocumentTable
		|WHERE
		|	NOT &OnlyErrors
		|		OR CASE WHEN DocumentTable.Warehouse = VALUE(Catalog.Warehouses.EmptyRef)
		|						AND NOT DocumentTable.Canceled
		|						AND DocumentTable.Products.ItemsType IN(
		|							VALUE(Enum.ItemsTypes.OwnGoods),
		|							VALUE(Enum.ItemsTypes.ReusablePackage))
		|						AND (DocumentTable.SupplyOption IN(
		|								VALUE(Enum.SupplyOptions.Ship),
		|								VALUE(Enum.SupplyOptions.FromWarehouse))
		|							OR DocumentTable.SupplyOption IN(
		|									VALUE(Enum.SupplyOptions.ReserveAsReceived),
		|									VALUE(Enum.SupplyOptions.ToSupply))
		|								AND DocumentTable.ReadyForSupply) THEN
		|						TRUE
		|					ELSE
		|						FALSE
		|				END
		|		OR NOT DocumentTable.Canceled
		|				AND DocumentTable.SupplyOption = VALUE(Enum.SupplyOptions.Ship)
		|				AND DocumentTable.ReadyToShip";
		
	Table = Query.Execute().Unload();
	
	Return Table;
	
EndFunction

Procedure FillInEmbeddingParameters(Form, EmbeddingParameters) Export
	
	If Form.AvailableRemainingEmbeddingOptions = Undefined Then
		
		InsertEmbeddingServiceParameters(EmbeddingParameters, Form.UUID);
		Form.AvailableRemainingEmbeddingOptions = EmbeddingParameters;
		
	EndIf;
	
EndProcedure

Function TablePath(EmbeddingParameters)
	
	TablePath = ?(EmbeddingParameters.InternalParameters.IsDocument,
		StrReplace(EmbeddingParameters.TableName, EmbeddingParameters.ObjectName, "Object"),
		StrReplace(EmbeddingParameters.TableName, "Form.", ""));
		
	Return TablePath;
	
EndFunction

Procedure AddToTable(Receiver, Source, Var_Key)
	
	CurKey = Common.CopyRecursive(Var_Key);
	For Each String In Source Do
		FillPropertyValues(CurKey, String);
		FoundRows = Receiver.FindRows(CurKey);
		If FoundRows.Count() = 0 Then
			NewRow = Receiver.Add();
			FillPropertyValues(NewRow, String);
		EndIf;
	EndDo;
	
EndProcedure

Procedure AvailableBalancesFillMatchingProductList(Form)
	
	EmbeddingParameters = Form.AvailableRemainingEmbeddingOptions;
	If EmbeddingParameters.TableName <> Undefined Then
		
		CollectionOnForm = ProvisionInDocumentsClientServer.CollectionOnForm(Form, EmbeddingParameters);
		
		Address = EmbeddingParameters.InternalParameters.AddressProductRange;
		If Not IsTempStorageURL(Address) Then
			Address = Form.UUID;;
		EndIf;
		Products = New Map();
		
		For Each String In CollectionOnForm Do
			
			Characteristic = Products.Get(String.Products);
			If Characteristic = Undefined Then
				Characteristic = New Map();
				Products.Insert(String.Products, Characteristic);
			EndIf;
			FoundItem = Characteristic.Get(String.Characteristic);
			If FoundItem = Undefined Then
				Characteristic.Insert(String.Characteristic, String.GetID());
			ElsIf FoundItem = True Or FoundItem <> String.GetID() Then
				Characteristic.Insert(String.Characteristic, True);
			EndIf;
			
		EndDo;
		
		EmbeddingParameters.InternalParameters.AddressProductRange = PutToTempStorage(Products, Address);
		
	EndIf;
	
EndProcedure

Procedure AvailableResiduesSupplementMatchingProducts(EmbeddingParameters, String, RowID)
	
	If EmbeddingParameters.TableName <> Undefined Then
		
		Products = GetFromTempStorage(EmbeddingParameters.InternalParameters.AddressProductRange);
		
		Characteristic = Products.Get(String.Products);
		If Characteristic = Undefined Then
			Characteristic = New Map();
			Products.Insert(String.Products, Characteristic);
		EndIf;
		FoundItem = Characteristic.Get(String.Characteristic);
		If FoundItem = Undefined Then
			Characteristic.Insert(String.Characteristic, RowID);
		ElsIf FoundItem = True Or FoundItem <> RowID Then
			Characteristic.Insert(String.Characteristic, True);
		EndIf;
		PutToTempStorage(Products, EmbeddingParameters.InternalParameters.AddressProductRange);
		
	EndIf;
	
EndProcedure

Procedure AvailableBalancesToReplenish(Form, FillParameters, Query = Undefined)
	
	If Not AccessRight("Read", Metadata.AccumulationRegisters.InventoryAndDemands) Then
		Return;
	EndIf;
	
	If FillParameters = Undefined Then
		FillParameters = AvailableBalancesFillParameters();
	EndIf;
	
	GettingLeftoversFromCache = FillParameters.GettingLeftoversFromCache;
	
	EmbeddingParameters = Form.AvailableRemainingEmbeddingOptions;
	If Query = Undefined Then // There is no temporary document data table.
		
		Tables = GetFromTempStorage(EmbeddingParameters.InternalParameters.AddressOfFormDataTable);
		FillInTablesFromFormData(Tables, Form);
		
		Query = New Query();
		Query.TempTablesManager = New TempTablesManager();
		AddTemporaryDocumentDataTable(Query.TempTablesManager, Tables, EmbeddingParameters);
		
	EndIf;
	
	ThereIsAddressOfRemnants = EmbeddingParameters.Property("AddressOfBalances");
	Balance          = Undefined;
	ChangesTable = Undefined;
	
	If GettingLeftoversFromCache And ThereIsAddressOfRemnants Then
		
		AddressOfBalances = EmbeddingParameters.AddressOfBalances;
		Balance = GetFromTempStorage(AddressOfBalances);
		ChangesTable = Balance.ChangesToDocument;
		
	Else
		
		ChangesTable = UploadDocumentChangeTable(Query.TempTablesManager, Form);
		
	EndIf;
	
	StructureOfResidues = BalancesForColumnAreAvailable(
		Query.TempTablesManager,
		Balance,
		ChangesTable);
	
	KeyOrders = "Products,Characteristic,Warehouse,Purpose,ControlledLotReference,ShipmentOrder,Package";
	KeyProducts_ = "Products,Characteristic,Warehouse,Purpose,ControlledLotReference,Package";
	
	Balance = New Structure();
	Balance.Insert("ByOrder",             StructureOfResidues.OrderBalances_1);
	Balance.Insert("ByProduct",             StructureOfResidues.ProductBalances_);
	Balance.Insert("AdjustingOrders", StructureOfResidues.AdjustingOrders);
	Balance.Insert("AdjustmentOfGoods", StructureOfResidues.AdjustmentOfGoods);
	Balance.Insert("ChangesToDocument", ChangesTable);
	
	Balance.ByProduct.Indexes.Add(KeyProducts_);
	Balance.ByOrder.Indexes.Add(KeyOrders);
	Balance.AdjustmentOfGoods.Indexes.Add(KeyProducts_);
	Balance.AdjustingOrders.Indexes.Add(KeyOrders);
	
	Address = ?(ThereIsAddressOfRemnants, EmbeddingParameters.AddressOfBalances, Form.UUID);
	AddressOfBalances = PutToTempStorage(Balance, Address);
	
	EmbeddingParameters.Insert("AddressOfBalances", AddressOfBalances);
	
	If EmbeddingParameters.TableName <> Undefined Then
		
		CollectionOnForm = ProvisionInDocumentsClientServer.CollectionOnForm(Form, EmbeddingParameters);
		
		For Each String In StructureOfResidues.DocumentTable Do
			FillPropertyValues(CollectionOnForm.FindByID(String.Id), String);
		EndDo;
		
		AvailableBalancesFillMatchingProductList(Form);
		
	Else
		
		If StructureOfResidues.DocumentTable.Count() > 0 Then
			FillPropertyValues(Form, StructureOfResidues.DocumentTable[0]);
		EndIf;
		
	EndIf;
	
EndProcedure

Procedure InsertTables(Tables, StructureItem, Prefix)
	
	CurrentTable = New ValueTable();
	
	For Each Property In StructureItem Do
		
		If TypeOf(Property.Value) = Type("Structure") Then
			
			NewPrefix = ?(Prefix = "", Property.Key, Prefix + "." + Property.Key);
			InsertTables(Tables, Property.Value, NewPrefix);
			
		Else
			
			CurrentTable.Columns.Add(Property.Key, Property.Value);
			
		EndIf;
		
	EndDo;
	
	If CurrentTable.Columns.Count() > 0 Then
		
		Tables.Insert(Prefix, New Structure("Table,TempTableName,TableNameInQuery", CurrentTable));
		
	EndIf;
	
EndProcedure

Function AvailableBalancesFillParameters()
	
	FillParameters = New Structure();
	FillParameters.Insert("GettingLeftoversFromCache", True);
	
	Return FillParameters;
	
EndFunction

// Performs provisioning actions in order lists, where documents with different provisioning embedding parameters are displayed.
// Parameters:
//  ActionCode - String - "ACTION_LOAD", "ACTION_RESERVE", "ACTION_SUPPLY", "ACTION_SUPPLY".
//  AllOrders - Array - links selected in the list of documents.
//  Ref - DocumentRef - a link to get the object manager module where the parameters function is located.
//  UUID - UUID - id of the document list form.
// Returns:
//  Structure - a lengthy operation or a structure for asking a question.
Function PerformActionInListOfOrdersOfDifferentTypes(ActionCode, AllOrders, Ref, UUID) Export
	
	ObjectManager = Common.ObjectManagerByRef(Ref);
	ActionSettingParameters = ObjectManager.ParametersForExecutingCommandsAndActions(AllOrders, ActionCode);
	If ActionSettingParameters.NeedQuestion Then
		
		Return ActionSettingParameters;
		
	Else
		
		ExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(UUID);
		ExecutionParameters.BackgroundJobDescription = NStr("vi = 'Thực hiện thao tác đảm bảo trong danh sách đơn hàng';
															|ru = 'Выполнение действия обеспечения в списке заказов';
															|en = 'Executing a provisioning action on the order list'; fa = 'Executing a provisioning action on the order list';
															|it = 'Esecuzione dell''azione di approvvigionamento nell''elenco degli ordini';
															|pl = 'Wykonanie czynności zaopatrzenia na liście zamówień';
															|tr = 'Bir sipariş listesinde tedarik işlemi gerçekleştirme'");
		
		Return TimeConsumingOperations.ExecuteFunction(
			ExecutionParameters,
			"ProvisionInDocumentsServer.PerformActionForMultipleOrderTypes",
			ActionSettingParameters);
		
	EndIf;
	
EndFunction

Function PerformActionInListOfOrdersOfDifferentTypesAfterQuestion(ResultOfActions, UUID) Export
	
	ExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(UUID);
	ExecutionParameters.BackgroundJobDescription = NStr("vi = 'Thực hiện thao tác đảm bảo trong danh sách đơn hàng';
														|ru = 'Выполнение действия обеспечения в списке заказов';
														|en = 'Executing a provisioning action on the order list'; fa = 'Executing a provisioning action on the order list';
														|it = 'Esecuzione dell''azione di approvvigionamento nell''elenco degli ordini';
														|pl = 'Wykonanie czynności zaopatrzenia na liście zamówień';
														|tr = 'Bir sipariş listesinde tedarik işlemi gerçekleştirme'");
	
	Return TimeConsumingOperations.ExecuteFunction(
		ExecutionParameters,
		"ProvisionInDocumentsServer.PerformActionForMultipleOrderTypes",
		ResultOfActions);
	
EndFunction

Function TableAddressSelectedEarlier(Query, UUID)
	
	Query.Text =
		"SELECT
		|	AllRows.Series AS Series,
		|	SelectedRows.Products AS Products,
		|	SelectedRows.Characteristic AS Characteristic,
		|	SelectedRows.Warehouse AS Warehouse,
		|	SelectedRows.Department AS Department,
		|	CASE WHEN SelectedRows.WithAssignment THEN
		|			SelectedRows.Purpose
		|		ELSE
		|			VALUE(Catalog.Assignments.EmptyRef)
		|	END AS Purpose,
		|	SUM(AllRows.Count)
		|		- MAX(
		|			CASE WHEN SelectedRows.Series = AllRows.Series
		|							AND SelectedRows.SupplyOption IN(
		|								VALUE(Enum.SupplyOptions.Ship),
		|								VALUE(Enum.SupplyOptions.FromWarehouse)) THEN
		|						SelectedRows.Count
		|					ELSE
		|						0
		|				END) AS Count
		|FROM
		|	TemporaryDocumentDataTableForSelectedRows AS SelectedRows
		|		INNER JOIN TemporaryDocumentDataTable AS AllRows
		|		ON AllRows.Products = SelectedRows.Products
		|		 AND AllRows.Characteristic = SelectedRows.Characteristic
		|		 AND AllRows.Warehouse = SelectedRows.Warehouse
		|		 AND AllRows.Purpose = SelectedRows.Purpose
		|		 AND AllRows.Department = SelectedRows.Department
		|		 AND AllRows.WithAssignment = SelectedRows.WithAssignment
		|		 AND AllRows.Series <> VALUE(Catalog.ItemsBatches.EmptyRef)
		|		 AND AllRows.SupplyOption IN(
		|				VALUE(Enum.SupplyOptions.Ship),
		|				VALUE(Enum.SupplyOptions.FromWarehouse))
		|GROUP BY
		|	SelectedRows.Products,
		|	SelectedRows.Characteristic,
		|	SelectedRows.Warehouse,
		|	SelectedRows.Department,
		|	CASE WHEN SelectedRows.WithAssignment THEN
		|			SelectedRows.Purpose
		|		ELSE
		|			VALUE(Catalog.Assignments.EmptyRef)
		|	END,
		|	AllRows.Series";
	Table = Query.Execute().Unload();
	Result = PutToTempStorage(Table, UUID);
	Return Result;
	
EndFunction

Function NewStructureBalance()
	
	Dimensions = InformationRegisters.InventoryAllocation.CreateRecordSet().Metadata().Dimensions;
	Balance = New Structure();
	
	Table = New ValueTable();
	Table.Columns.Add("ShipmentOrder", Dimensions.ShipmentOrder.Type);
	Table.Columns.Add("Products", Dimensions.Products.Type);
	Table.Columns.Add("Characteristic", Dimensions.Characteristic.Type);
	Table.Columns.Add("Warehouse", Dimensions.Warehouse.Type);
	Table.Columns.Add("Purpose", Dimensions.Purpose.Type);
	Table.Columns.Add("ControlledLotReference", New TypeDescription("CatalogRef.ControlledLots"));
	Table.Columns.Add("Ship", TMCommonUseClientServer.TypeDescriptionNumber(15, 3));
	Table.Columns.Add("ToReserve_", TMCommonUseClientServer.TypeDescriptionNumber(15, 3));
	Table.Columns.Add("ToUpdateColumnAvailableAfterInventoryAllocation", New TypeDescription("Boolean"));
	
	Balance.Insert("ChangesToDocument", Table);
	
	Table = New ValueTable();
	Table.Columns.Add("ShipmentOrder", Dimensions.ShipmentOrder.Type);
	Table.Columns.Add("Products", Dimensions.Products.Type);
	Table.Columns.Add("Characteristic", Dimensions.Characteristic.Type);
	Table.Columns.Add("Warehouse", Dimensions.Warehouse.Type);
	Table.Columns.Add("Purpose", Dimensions.Purpose.Type);
	Table.Columns.Add("ControlledLotReference", New TypeDescription("CatalogRef.ControlledLots"));
	Table.Columns.Add("Count", TMCommonUseClientServer.TypeDescriptionNumber(15, 3));
	Table.Columns.Add("Package", New TypeDescription("CatalogRef.PackagesAndUnitsOfMeasure"));
	
	Balance.Insert("AdjustingOrders", Table);
	
	Table = Balance.AdjustingOrders.Copy();
	Balance.Insert("ByOrder", Table);
	
	Table = New ValueTable();
	Table.Columns.Add("ShipmentOrder", Dimensions.ShipmentOrder.Type);
	Table.Columns.Add("Products", Dimensions.Products.Type);
	Table.Columns.Add("Characteristic", Dimensions.Characteristic.Type);
	Table.Columns.Add("Warehouse", Dimensions.Warehouse.Type);
	Table.Columns.Add("Purpose", Dimensions.Purpose.Type);
	Table.Columns.Add("ControlledLotReference", New TypeDescription("CatalogRef.ControlledLots"));
	Table.Columns.Add("Count", TMCommonUseClientServer.TypeDescriptionNumber(15, 3));
	Table.Columns.Add("Package", New TypeDescription("CatalogRef.PackagesAndUnitsOfMeasure"));
	
	Balance.Insert("AdjustmentOfGoods", Table);
	
	Table = Balance.AdjustmentOfGoods.Copy();
	Table.Columns.Add("ShipIfAvailable", TMCommonUseClientServer.TypeDescriptionNumber(15, 3));
	Table.Columns.Add("ReallocateWarehouseInventory", TMCommonUseClientServer.TypeDescriptionNumber(15, 3));
	Balance.Insert("ByProduct", Table);
	
	Return Balance;
	
EndFunction

Function StepsForOrdersToProcessor(Recorders)
	
	References = New Array();
	
	SetPrivilegedMode(True);
	OrdersToProcessor = New Array();
	For Each Ref In Recorders Do
		If False
		
				
				Or TypeOf(Ref) = Type("DocumentRef.SubcontractOrder2_5") Then
			OrdersToProcessor.Add(Ref);
		EndIf;
	EndDo;
	If OrdersToProcessor.Count() > 0 Then
		Query = New Query();
		Query.SetParameter("OrdersToProcessor", OrdersToProcessor);
		Query.Text =
		"SELECT
		|	Table.Ref AS Ref
		|FROM
		|	Document.ProductionStage2_2 AS Table
		|WHERE
		|	Table.Posted
		|		AND Table.ProductionByThirdParty
		|		AND Table.SubcontractOrder IN(&OrdersToProcessor)";
		SetPrivilegedMode(True);
		References = Query.Execute().Unload().UnloadColumn("Ref");
		SetPrivilegedMode(False);
	EndIf;
	
	Return References;
	
EndFunction

#Region InterfaceRequestsInternal

Procedure DistributionOfInventoryIntoControlledLotsReferenceInternal(Texts, TablesThatAreBeingDestroyed, TablesNames)
	
	BalanceSheetsOfControlledLotREFERENCES = TablesNames.BalanceSheetsOfControlledLotREFERENCES;
	
	#Region Reversal
	
	If TablesNames.ReversingEntry <> "" Then
		
		Text =
			"SELECT
			|	Set.Products AS Products,
			|	Set.Characteristic AS Characteristic,
			|	Set.Warehouse AS Warehouse,
			|	Set.Purpose AS Purpose,
			|	Set.OrderDocument AS OrderDocument,
			|	SUM(Set.LockedInStockBalance) AS LockedInStockBalance,
			|	SUM(Set.LockedReceiptBalance) AS LockedReceiptBalance,
			|	SUM(Set.ToUnlockBalance) AS ToUnlockBalance,
			|	SUM(Set.ReserveAtWarehouseFromLockedBalance) AS ReserveAtWarehouseFromLockedBalance,
			|	SUM(Set.ReserveUponReceiptFromLockedBalance) AS ReserveUponReceiptFromLockedBalance
			|INTO DistributionOfInventoryIntoControlledLotReferencesStage0
			|FROM(
			|	SELECT
			|		Inventories.Products AS Products,
			|		Inventories.Characteristic AS Characteristic,
			|		Inventories.Warehouse AS Warehouse,
			|		Inventories.Purpose AS Purpose,
			|		Inventories.OrderDocument AS OrderDocument,
			|		Inventories.LockedInStockBalance AS LockedInStockBalance,
			|		Inventories.LockedReceiptBalance AS LockedReceiptBalance,
			|		Inventories.ToUnlockBalance AS ToUnlockBalance,
			|		Inventories.ReserveAtWarehouseFromLockedBalance AS ReserveAtWarehouseFromLockedBalance,
			|		Inventories.ReserveUponReceiptFromLockedBalance AS ReserveUponReceiptFromLockedBalance
			|	FROM
			|		BalanceSheetsOfControlledLotREFERENCESOverridable AS Inventories
			|	
			|	UNION ALL
			|	
			|	SELECT
			|		StornoTable.Products AS Products,
			|		StornoTable.Characteristic AS Characteristic,
			|		StornoTable.Warehouse AS Warehouse,
			|		StornoTable.Purpose AS Purpose,
			|		StornoTable.OrderDocument AS OrderDocument,
			|		- StornoTable.LockedInStock AS LockedInStockBalance,
			|		- StornoTable.LockedReceipt AS LockedReceiptBalance,
			|		- StornoTable.ToUnlock AS ToUnlockBalance,
			|		- StornoTable.ReserveAtWarehouseFromLocked AS ReserveAtWarehouseFromLockedBalance,
			|		- StornoTable.ReserveUponReceiptFromLocked AS ReserveUponReceiptFromLockedBalance
			|	FROM
			|		ReversingEntryOverridable AS StornoTable) AS Set
			|GROUP BY
			|	Set.Products,
			|	Set.Characteristic,
			|	Set.Warehouse,
			|	Set.Purpose,
			|	Set.OrderDocument
			|HAVING
			|	SUM(Set.LockedInStockBalance) <> 0
			|		OR SUM(Set.LockedReceiptBalance) <> 0
			|		OR SUM(Set.ToUnlockBalance) <> 0
			|		OR SUM(Set.ReserveAtWarehouseFromLockedBalance) <> 0
			|		OR SUM(Set.ReserveUponReceiptFromLockedBalance) <> 0";
		
		Text = StrReplace(Text, "BalanceSheetsOfControlledLotREFERENCESOverridable", BalanceSheetsOfControlledLotREFERENCES); // @query-part-1
		Text = StrReplace(Text, "ReversingEntryOverridable", TablesNames.ReversingEntry); // @query-part-1
		
		Texts.Add(Text);
		TablesThatAreBeingDestroyed.Add("DistributionOfInventoryIntoControlledLotReferencesStage0"); // @query-part-1
		
		BalanceSheetsOfControlledLotREFERENCES = "DistributionOfInventoryIntoControlledLotReferencesStage0"; // @query-part-1
		
	EndIf;
	
	#EndRegion
	
	Text =
		"SELECT
		|	Table.Products AS Products,
		|	Table.Characteristic AS Characteristic,
		|	Table.Warehouse AS Warehouse,
		|	Table.Purpose AS Purpose,
		|	Table.OrderDocument AS OrderDocument,
		|	Table.ToReserve_ AS ToReserve_,
		|	Table.ToReserveAsNeeded AS ToReserveAsNeeded,
		|	Table.AvailableWithLock AS AvailableWithLock,
		|	Table.ExpectedWithBlocking AS ExpectedWithBlocking,
		|	Table.InStock - Table.AvailableWithLock AS AvailableWithoutUnlocking,
		|	Table.Expected_ - Table.ExpectedWithBlocking AS ExpectedWithoutUnlocking
		|INTO DistributionOfInventoryIntoControlledLotsReferencesStage1
		|FROM(
		|	SELECT
		|		Table.Products AS Products,
		|		Table.Characteristic AS Characteristic,
		|		Table.Warehouse AS Warehouse,
		|		Table.Purpose AS Purpose,
		|		Table.OrderDocument AS OrderDocument,
		|		Table.ReserveAtWarehouseFromLockedBalance AS ToReserve_,
		|		Table.ReserveUponReceiptFromLockedBalance AS ToReserveAsNeeded,
		|		Table.LockedInStockBalance AS InStock,
		|		Table.LockedReceiptBalance AS Expected_,
		|		
		// AvailableWithLock
		|		CASE
		|			WHEN Table.LockedInStockBalance < 0
		|				THEN Table.LockedInStockBalance
		|			WHEN Table.LockedInStockBalance - Table.ToUnlockBalance < 0
		|				THEN Table.LockedInStockBalance
		|			ELSE Table.ToUnlockBalance
		|		END AS AvailableWithLock,
		|		
		// ExpectedWithBlocking
		|		CASE
		|			WHEN Table.LockedInStockBalance < 0
		|				THEN
		|					CASE
		|						WHEN Table.LockedReceiptBalance - Table.ToUnlockBalance < 0
		|							THEN Table.LockedReceiptBalance
		|						ELSE Table.ToUnlockBalance
		|					END
		|			WHEN Table.LockedInStockBalance + Table.LockedReceiptBalance - Table.ToUnlockBalance < 0
		|				THEN Table.LockedReceiptBalance
		|			WHEN Table.LockedInStockBalance - Table.ToUnlockBalance < 0
		|				THEN Table.ToUnlockBalance - Table.LockedInStockBalance
		|			ELSE 0
		|		END AS ExpectedWithBlocking
		|	FROM
		|		BalanceSheetsOfControlledLotREFERENCESOverridable AS Table) AS Table";
		
	Text = StrReplace(Text, "BalanceSheetsOfControlledLotREFERENCESOverridable", BalanceSheetsOfControlledLotREFERENCES); // @query-part-1
	Texts.Add(Text);
	TablesThatAreBeingDestroyed.Add("DistributionOfInventoryIntoControlledLotsReferencesStage1"); // @query-part-1
	
	Text =
		"SELECT
		|	Table.Products AS Products,
		|	Table.Characteristic AS Characteristic,
		|	Table.Warehouse AS Warehouse,
		|	Table.Purpose AS Purpose,
		|	Table.OrderDocument AS OrderDocument,
		|	Table.ToReserve_ AS ToReserve_,
		|	Table.ToReserveAsNeeded AS ToReserveAsNeeded,
		|	Table.AvailableWithLock AS AvailableWithLock,
		|	Table.AvailableWithoutUnlocking AS AvailableWithoutUnlocking,
		|	Table.ExpectedWithBlocking AS ExpectedWithBlocking,
		|	Table.ExpectedWithoutUnlocking AS ExpectedWithoutUnlocking,
		|	Table.AvailableWithLock_Reserve AS AvailableWithLock_Reserve,
		|	Table.AvailableWithoutUnlocking_Reserve AS AvailableWithoutUnlocking_Reserve,
		
		// AvailableWithLock_ReserveAsNeeded
		|	CASE
		|		WHEN Table.AvailableWithLock - Table.AvailableWithLock_Reserve < 0
		|			THEN 0
		|		WHEN Table.AvailableWithLock - Table.AvailableWithLock_Reserve - Table.ToReserveAsNeeded < 0
		|			THEN Table.AvailableWithLock - Table.AvailableWithLock_Reserve
		|		ELSE Table.ToReserveAsNeeded
		|	END AS AvailableWithLock_ReserveAsNeeded,
		|	
		// AvailableWithoutUnlocking_ReserveAsNeeded
		|	CASE
		|		WHEN Table.AvailableWithLock - Table.AvailableWithLock_Reserve < 0
		|			THEN
		|				CASE
		|					WHEN Table.AvailableWithoutUnlocking - Table.AvailableWithoutUnlocking_Reserve - Table.ToReserveAsNeeded < 0
		|						THEN Table.AvailableWithoutUnlocking - Table.AvailableWithoutUnlocking_Reserve
		|					ELSE Table.ToReserveAsNeeded
		|				END
		|		WHEN Table.AvailableWithLock - Table.AvailableWithLock_Reserve - Table.ToReserveAsNeeded < 0
		|			THEN
		|				CASE
		|					WHEN Table.AvailableWithoutUnlocking - Table.AvailableWithoutUnlocking_Reserve
		|							+ Table.AvailableWithLock - Table.AvailableWithLock_Reserve - Table.ToReserveAsNeeded < 0
		|						THEN Table.AvailableWithoutUnlocking - Table.AvailableWithoutUnlocking_Reserve
		|					ELSE - (Table.AvailableWithLock - Table.AvailableWithLock_Reserve - Table.ToReserveAsNeeded)
		|				END
		|		ELSE 0
		|	END AS AvailableWithoutUnlocking_ReserveAsNeeded
		|INTO DistributionOfInventoryIntoControlledLotsReferencesStage2
		|FROM(
		|	SELECT
		|		Table.Products AS Products,
		|		Table.Characteristic AS Characteristic,
		|		Table.Warehouse AS Warehouse,
		|		Table.Purpose AS Purpose,
		|		Table.OrderDocument AS OrderDocument,
		|		Table.ToReserve_ AS ToReserve_,
		|		Table.ToReserveAsNeeded AS ToReserveAsNeeded,
		|		Table.AvailableWithLock AS AvailableWithLock,
		|		Table.AvailableWithoutUnlocking AS AvailableWithoutUnlocking,
		|		Table.ExpectedWithBlocking AS ExpectedWithBlocking,
		|		Table.ExpectedWithoutUnlocking AS ExpectedWithoutUnlocking,
		|	
		// AvailableWithLock_Reserve
		|		CASE
					// If the Balance is negative, the entire reserve in the warehouse is assigned to the Balance to be unlocked.
					// and a negative surplus of the Balance to be controlled is formed.
		|			WHEN Table.AvailableWithLock < 0
		|				THEN Table.ToReserve_
		|			WHEN Table.AvailableWithLock > Table.ToReserve_
		|				THEN Table.ToReserve_
		|			WHEN Table.AvailableWithLock + Table.AvailableWithoutUnlocking > Table.ToReserve_
		|				THEN Table.AvailableWithLock
					// If the reserve in the warehouse is not covered by the total Balance, then the missing is counted for the Balance to be unblocked
					// and a negative surplus of the Balance to be controlled is formed.
		|			ELSE Table.ToReserve_ - Table.AvailableWithoutUnlocking
		|		END AS AvailableWithLock_Reserve,
		|
		// AvailableWithoutUnlocking_Reserve
		|		CASE
		|			WHEN Table.AvailableWithLock < 0
		|				THEN 0
		|			WHEN Table.AvailableWithLock > Table.ToReserve_
		|				THEN 0
		|			WHEN Table.AvailableWithLock + Table.AvailableWithoutUnlocking < Table.ToReserve_
		|				THEN Table.AvailableWithoutUnlocking
		|			ELSE Table.ToReserve_ - Table.AvailableWithLock
		|		END AS AvailableWithoutUnlocking_Reserve
		|	FROM
		|		DistributionOfInventoryIntoControlledLotsReferencesStage1 AS Table) AS Table";
		
	Texts.Add(Text);
	TablesThatAreBeingDestroyed.Add("DistributionOfInventoryIntoControlledLotsReferencesStage2"); // @query-part-1
	
	Text =
		"SELECT
		|	Table.Products AS Products,
		|	Table.Characteristic AS Characteristic,
		|	Table.Warehouse AS Warehouse,
		|	Table.Purpose AS Purpose,
		|	Table.OrderDocument AS OrderDocument,
		|	Table.AvailableWithLock AS AvailableWithLock,
		|	Table.AvailableWithoutUnlocking AS AvailableWithoutUnlocking,
		|	Table.ExpectedWithBlocking AS ExpectedWithBlocking,
		|	Table.ExpectedWithoutUnlocking AS ExpectedWithoutUnlocking,
		|	Table.ToReserve_ AS Reserve_FromBlocked,
		|	Table.ToReserveAsNeeded AS ReserveAsNeeded_FromBlocked,
		|	Table.AvailableWithLock_Reserve AS AvailableWithLock_Reserve_FromBlocked,
		|	Table.AvailableWithLock_ReserveAsNeeded AS AvailableWithLock_ReserveAsNeeded_FromBlocked,
		|	Table.AvailableWithoutUnlocking_Reserve AS AvailableWithoutUnlocking_Reserve_FromLocked,
		|	Table.AvailableWithoutUnlocking_ReserveAsNeeded AS AvailableWithoutUnlocking_ReserveAsNeeded_FromBlocked,
		|	Table.ExpectedWithLock_ReserveAsNeeded AS ExpectedWithLock_ReserveAsNeeded_FromBlocked,
		|	Table.ExpectedWithoutUnlocking_ReserveAsNeeded AS ExpectedWithoutUnlocking_ReserveAsNeeded_FromBlocked,
		|	Table.AvailableWithLock
		|		- Table.AvailableWithLock_Reserve
		|		- Table.AvailableWithLock_ReserveAsNeeded AS AvailableWithLock_Surplus,
		|	Table.AvailableWithoutUnlocking
		|		- Table.AvailableWithoutUnlocking_Reserve
		|		- Table.AvailableWithoutUnlocking_ReserveAsNeeded AS AvailableWithoutUnlocking_Surplus,
		|	Table.ExpectedWithBlocking
		|		- Table.ExpectedWithLock_ReserveAsNeeded AS ExpectedWithLock_Surplus,
		|	Table.ExpectedWithoutUnlocking
		|		- Table.ExpectedWithoutUnlocking_ReserveAsNeeded AS ExpectedWithoutUnlocking_Surplus,
		|	Table.ToReserveAsNeeded
		|		- Table.AvailableWithLock_ReserveAsNeeded
		|		- Table.AvailableWithoutUnlocking_ReserveAsNeeded
		|		- Table.ExpectedWithLock_ReserveAsNeeded
		|		- Table.ExpectedWithoutUnlocking_ReserveAsNeeded AS NotProvided_ReserveAsNeeded_FromBlocked
		|INTO DistributionOfInventoryIntoControlledLotsReferenceOverridable
		|FROM(
		|	SELECT
		|		Table.Products AS Products,
		|		Table.Characteristic AS Characteristic,
		|		Table.Warehouse AS Warehouse,
		|		Table.Purpose AS Purpose,
		|		Table.OrderDocument AS OrderDocument,
		|		Table.ToReserve_ AS ToReserve_,
		|		Table.ToReserveAsNeeded AS ToReserveAsNeeded,
		|		Table.AvailableWithLock AS AvailableWithLock,
		|		Table.AvailableWithoutUnlocking AS AvailableWithoutUnlocking,
		|		Table.ExpectedWithBlocking AS ExpectedWithBlocking,
		|		Table.ExpectedWithoutUnlocking AS ExpectedWithoutUnlocking,
		|		Table.AvailableWithLock_Reserve AS AvailableWithLock_Reserve,
		|		Table.AvailableWithoutUnlocking_Reserve AS AvailableWithoutUnlocking_Reserve,
		|		Table.AvailableWithLock_ReserveAsNeeded AS AvailableWithLock_ReserveAsNeeded,
		|		Table.AvailableWithoutUnlocking_ReserveAsNeeded AS AvailableWithoutUnlocking_ReserveAsNeeded,
		
		// ExpectedWithLock_ReserveAsNeeded
		|		CASE
		|			WHEN Table.ExpectedWithBlocking > Table.ToReserveAsNeeded - Table.AvailableWithLock_ReserveAsNeeded - Table.AvailableWithoutUnlocking_ReserveAsNeeded
		|				THEN Table.ToReserveAsNeeded - Table.AvailableWithLock_ReserveAsNeeded - Table.AvailableWithoutUnlocking_ReserveAsNeeded
		|			ELSE Table.ExpectedWithBlocking
		|		END AS ExpectedWithLock_ReserveAsNeeded,
		
		// ExpectedWithoutUnlocking_ReserveAsNeeded
		|		CASE
		|			WHEN Table.ExpectedWithBlocking > Table.ToReserveAsNeeded - Table.AvailableWithLock_ReserveAsNeeded - Table.AvailableWithoutUnlocking_ReserveAsNeeded
		|				THEN 0
		|			WHEN Table.ExpectedWithoutUnlocking > Table.ToReserveAsNeeded - Table.AvailableWithLock_ReserveAsNeeded - Table.AvailableWithoutUnlocking_ReserveAsNeeded - Table.ExpectedWithBlocking
		|				THEN Table.ToReserveAsNeeded - Table.AvailableWithLock_ReserveAsNeeded - Table.AvailableWithoutUnlocking_ReserveAsNeeded - Table.ExpectedWithBlocking
		|			ELSE Table.ExpectedWithoutUnlocking
		|		END AS ExpectedWithoutUnlocking_ReserveAsNeeded
		|	FROM
		|		DistributionOfInventoryIntoControlledLotsReferencesStage2 AS Table) AS Table";
	Text = StrReplace(Text, "DistributionOfInventoryIntoControlledLotsReferenceOverridable", TablesNames.Result); // @query-part-1
	Texts.Add(Text);
	TablesThatAreBeingDestroyed.Add(TablesNames.Result);
	
EndProcedure

Procedure InsertTempTablesOfInventoryAllocation(QueryText, Substitution, Texts, TablesThatAreBeingDestroyed)
	
	QueryTextUpper = Upper(QueryText);
	SubstitutionInReg = Upper(Substitution);
	InsertedText_ = StrConcat(Texts, Common.QueryBatchSeparator());
	KittingTextsTogether = New Array();
	
	FirstWildcardCharacter = StrFind(QueryTextUpper, SubstitutionInReg);
	Text = "";
	If FirstWildcardCharacter > 0 Then
		
		// Substitution is used in the query, insert the formation of the necessary temporary tables before requesting the use of substitution.
		NumberOfCharactersUpTo = StrFind(QueryTextUpper, ";", SearchDirection.FromEnd, FirstWildcardCharacter);
		If NumberOfCharactersUpTo = 0 Then
			
			KittingTextsTogether.Add(InsertedText_);
			KittingTextsTogether.Add(QueryText);
			For Each TableName In TablesThatAreBeingDestroyed Do
				KittingTextsTogether.Add("DROP " + TableName);
			EndDo;
			Text = StrConcat(KittingTextsTogether, Common.QueryBatchSeparator());
			
		Else
			
			TextBefore = Left(QueryText, NumberOfCharactersUpTo - 1);
			TextAfter = Mid(QueryText, NumberOfCharactersUpTo + 1);
			
			KittingTextsTogether.Add(TextBefore);
			KittingTextsTogether.Add(InsertedText_);
			Text = StrConcat(KittingTextsTogether, Common.QueryBatchSeparator());
			
			KittingTextsTogether.Clear();
			KittingTextsTogether.Add(Text);
			KittingTextsTogether.Add(";");
			KittingTextsTogether.Add(TextAfter);
			Text = StrConcat(KittingTextsTogether);
			
			KittingTextsTogether.Clear();
			KittingTextsTogether.Add(Text);
			For Each TableName In TablesThatAreBeingDestroyed Do
				KittingTextsTogether.Add("DROP " + TableName);
			EndDo;
			Text = StrConcat(KittingTextsTogether, Common.QueryBatchSeparator());
			
		EndIf;
		
	Else
		// Substitution is not used in the query, we insert the formation of the necessary temp tables at the end of the query.
		KittingTextsTogether.Add(QueryText);
		KittingTextsTogether.Add(InsertedText_);
		For Each TableName In TablesThatAreBeingDestroyed Do
			If SubstitutionInReg = Upper(TableName) Then // You cannot destroy the Substitution table in the same Query Text.
				Continue;
			EndIf;
			KittingTextsTogether.Add("DROP " + TableName);
		EndDo;
		Text = StrConcat(KittingTextsTogether, Common.QueryBatchSeparator());
	EndIf;
	
	QueryText = Text;
	
EndProcedure

#EndRegion

#EndRegion
