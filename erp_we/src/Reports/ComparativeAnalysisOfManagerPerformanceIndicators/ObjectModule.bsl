#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Private

#Region CreatingRequestPackage

Function ExecuteBatchOfRequests(MatchingRequestsData,TreeOfDataSets,GenerationParameters,StructureOfReportGenerationPeriods)

	Query = New Query;
	LastPacketNumber = - 1;
	
	Query.Text = Query.Text + RequestTextAboutManagers(LastPacketNumber,Query);
	Query.Text = Query.Text + RequestTextForWeightedAverageExchangeRates(LastPacketNumber, StructureOfReportGenerationPeriods);
	
	For Each DataGroup In TreeOfDataSets.Rows Do
	
		For Each DataSet In DataGroup.Rows Do
			
			If DataSet.Include = 1 Then
				
				If DataSet["Name"] = "Sales" Then
					Query.Text = Query.Text + SalesRequestText(MatchingRequestsData,LastPacketNumber,StructureOfReportGenerationPeriods);
				ElsIf DataSet["Name"] = "Profit_" Then
					Query.Text = Query.Text + TextOfProfitRequest(MatchingRequestsData,LastPacketNumber,StructureOfReportGenerationPeriods);
				ElsIf DataSet["Name"] = "ReceiptOfCash" Then
					Query.Text = Query.Text + TextOfCashReceiptRequest(MatchingRequestsData,LastPacketNumber,StructureOfReportGenerationPeriods);
				ElsIf DataSet["Name"] = "ReceiptOfDS_MinusCost" Then
					Query.Text = Query.Text + TextOfRequestForReceiptOfDS_MinusCost(MatchingRequestsData,LastPacketNumber,StructureOfReportGenerationPeriods);
				ElsIf DataSet["Name"] = "LossesOverdueReceivables" Then
					
					AdditionalActionsForSetOfLossesOverdueReceivables(Query, StructureOfReportGenerationPeriods);
					Query.Text = Query.Text + TextOfRequestForLossesAsResultOfOverdueReceivables(MatchingRequestsData,LastPacketNumber,StructureOfReportGenerationPeriods);
					
				ElsIf DataSet["Name"] = "ManualDiscountsAreProvided" Then
					Query.Text = Query.Text + RequestTextForManualDiscounts(MatchingRequestsData,LastPacketNumber,StructureOfReportGenerationPeriods);
				ElsIf DataSet["Name"] = "EfficiencyOfOpportunityManagement" Then
					Query.Text = Query.Text + TextOfRequestOnEffectivenessOfTransactions(MatchingRequestsData,LastPacketNumber,StructureOfReportGenerationPeriods);
				ElsIf DataSet["Name"] = "InteractionEfficiency" Then
					Query.Text = Query.Text + RequestTextForEffectiveInteractions(MatchingRequestsData,LastPacketNumber,StructureOfReportGenerationPeriods);
				ElsIf DataSet["Name"] = "SalesPerOpportunity" Then
					Query.Text = Query.Text + TextOfSalesRequestForOneTransaction(MatchingRequestsData,LastPacketNumber,StructureOfReportGenerationPeriods);
				ElsIf DataSet["Name"] = "SalesPerOneInteraction" Then
					Query.Text = Query.Text + TextOfSalesRequestPerInteraction(MatchingRequestsData,LastPacketNumber,StructureOfReportGenerationPeriods);
				ElsIf DataSet["Name"] = "TheMainStagesOfLosses" Then
					Query.Text = Query.Text + RequestTextAboutMainStagesOfLosses(MatchingRequestsData,LastPacketNumber,StructureOfReportGenerationPeriods);
				ElsIf DataSet["Name"] = "ReasonsForLosingSalesOpportunities" Then
					Query.Text = Query.Text +  TextOfRequestAboutReasonsForLosingTrades(MatchingRequestsData,LastPacketNumber,StructureOfReportGenerationPeriods);
				ElsIf DataSet["Name"] = "DissatisfactionWithPrimaryDemand" Then
					Query.Text = Query.Text +  TextOfRequestAboutReasonsForUnsatisfactoryPrimaryDemand(MatchingRequestsData,LastPacketNumber,StructureOfReportGenerationPeriods);
				ElsIf DataSet["Name"] = "CustomerBaseTrends" Then
					Query.Text = Query.Text + QueryTextCustomerBaseTrends(MatchingRequestsData,LastPacketNumber,StructureOfReportGenerationPeriods);
				ElsIf DataSet["Name"] = "SalesToNewCustomers" Then
					Query.Text = Query.Text + QueryTextSalesToNewCustomers(MatchingRequestsData,LastPacketNumber,StructureOfReportGenerationPeriods);
				ElsIf DataSet["Name"] = "IncurredCustomerClaims" Then
					Query.Text = Query.Text + TextOfRequestForCustomerClaims(MatchingRequestsData,LastPacketNumber,StructureOfReportGenerationPeriods);
				ElsIf DataSet["Name"] = "ComplaintReasons" Then
					Query.Text = Query.Text + TextOfRequestAboutReasonsForOccurrenceOfCustomerClaims(MatchingRequestsData,LastPacketNumber,StructureOfReportGenerationPeriods);
				EndIf;
				
			EndIf;
			
		EndDo;
	
	EndDo;
	
	Query.SetParameter("BeginOfPeriod",BegOfDay(StructureOfReportGenerationPeriods.StartDate));
	Query.SetParameter("PeriodEnding",EndOfDay(StructureOfReportGenerationPeriods.EndDate));
	Query.SetParameter("StartDateAdditionalPeriod",BegOfDay(StructureOfReportGenerationPeriods.StartDateAdditionalPeriod));
	Query.SetParameter("EndDateAdditionalPeriod",EndOfDay(StructureOfReportGenerationPeriods.EndDateAdditionalPeriod));
	Query.SetParameter("RecordTypeExpense",AccumulationRecordType.Expense);
	Query.SetParameter("InterestRateOfValueOfMoney",GenerationParameters.InterestRate);
	Query.SetParameter("ManagementAccountingCurrency", Constants.ManagementAccountingCurrency.Get());
	Query.SetParameter("NotSpecified", NStr("vi = 'Chưa chỉ ra';
											|ru = 'Не указан';
											|en = 'Not specified'; fa = 'مشخص نشده';
											|it = 'Non specificato';
											|pl = 'Nie określony';
											|tr = 'Belirtilmemiş'"));
	Query.SetParameter("BaseCurrency", SettingsValueCached.DefaultBaseCurrency());
	
	Return Query.ExecuteBatch();

EndFunction

Function RequestTextAboutManagers(LastPacketNumber,Query)
	
	LastPacketNumber = LastPacketNumber + 1;

	SchemeForUserFilter = Reports.ComparativeAnalysisOfManagerPerformanceIndicators.GetTemplate("SchemeForUserFilter");
	
	TemplateComposer = New DataCompositionTemplateComposer();
	DataCompositionTemplate = TemplateComposer.Execute(SchemeForUserFilter, SettingsComposer.GetSettings(),,,Type("DataCompositionValueCollectionTemplateGenerator"));
	
	QueryText = DataCompositionTemplate.DataSets.MainDataSet.Query;
	
	For Each Parameter In DataCompositionTemplate.ParameterValues Do
		Query.Parameters.Insert(Parameter.Name, Parameter.Value);
	EndDo;
	
	FoundItemFROM = StrFind(QueryText,"FROM");
	If FoundItemFROM <> 0 Then
		QueryText = Left(QueryText,FoundItemFROM - 1) + "  INTO FilterByManagers
		|  " + Right(QueryText,StrLen(QueryText) - FoundItemFROM + 1);
		
	EndIf;
	
	LastPacketNumber = LastPacketNumber + 1;
	QueryText = QueryText + Common.QueryBatchSeparator();
	QueryText = QueryText + "
	|SELECT
	|	ARAPObjects.Ref AS ARAPObject
	|INTO ObjectsOfManagersCalculations
	|FROM
	|	Catalog.ARAPObjects AS ARAPObjects
	|WHERE
	|	ARAPObjects.Manager IN (SELECT Manager FROM FilterByManagers)
	|	AND NOT ARAPObjects.DeletionMark
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|";
	
	Return QueryText;
	
EndFunction

Function RequestTextForWeightedAverageExchangeRates(LastPacketNumber, StructureOfReportGenerationPeriods)
	
	LastPacketNumber = LastPacketNumber + 3;
	
	QueryText = "SELECT TOP 1
	|	NestedQuery.MainEnterpriseCalendar,
	|	NestedQuery.OrderField AS OrderField
	|INTO Calendar
	|FROM
	|	(SELECT TOP 1
	|		Constants.MainEnterpriseCalendar AS MainEnterpriseCalendar,
	|		0 AS OrderField
	|	FROM
	|		Constants AS Constants
	|	
	|	UNION
	|	
	|	SELECT
	|		CalendarSchedules.Calendar,
	|		1
	|	FROM
	|		InformationRegister.CalendarSchedules AS CalendarSchedules
	|	WHERE
	|		CalendarSchedules.ScheduleDate BETWEEN &BeginOfPeriod AND &PeriodEnding) AS NestedQuery
	|WHERE
	|	NestedQuery.MainEnterpriseCalendar <> VALUE(Catalog.Calendars.EmptyRef)
	|
	|ORDER BY
	|	OrderField
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED
	|	CalendarSchedules.ScheduleDate AS ScheduleDate,
	|	ExchangeRates.Currency,
	|	MAX(ExchangeRates.Period) AS Period
	|INTO MatchingCourseDates
	|FROM
	|	InformationRegister.CalendarSchedules AS CalendarSchedules
	|		LEFT JOIN InformationRegister.RelativeExchangeRates AS ExchangeRates
	|		ON CalendarSchedules.ScheduleDate > ExchangeRates.Period
	|			AND ExchangeRates.BaseCurrency = &BaseCurrency
	|WHERE
	|	CalendarSchedules.ScheduleDate BETWEEN &BeginOfPeriod AND &PeriodEnding
	|	AND CalendarSchedules.Calendar IN
	|			(SELECT
	|				Calendar.MainEnterpriseCalendar
	|			FROM
	|				Calendar AS Calendar)
	|
	|GROUP BY
	|	ExchangeRates.Currency,
	|	CalendarSchedules.ScheduleDate
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED
	|	NestedQuery.Currency,
	|	CASE
	|		WHEN DATEDIFF(&BeginOfPeriod, &PeriodEnding, DAY) + 1 = 0
	|			THEN 0
	|		ELSE NestedQuery.Rate / (DATEDIFF(&BeginOfPeriod, &PeriodEnding, DAY) + 1)
	|	END AS WeightedAverageExchangeRate
	|INTO WeightedAverageExchangeRatesForCurPeriod
	|FROM
	|	(SELECT
	|		MatchingCourseDates.Currency AS Currency,
	|		SUM(CASE
	|				WHEN ExchangeRates.CourseDenominator = 0
	|					THEN 0
	|				ELSE ExchangeRates.CourseNumerator / ExchangeRates.CourseDenominator
	|			END) AS Rate
	|	FROM
	|		InformationRegister.RelativeExchangeRates AS ExchangeRates
	|			INNER JOIN MatchingCourseDates AS MatchingCourseDates
	|			ON ExchangeRates.Period = MatchingCourseDates.Period
	|				AND ExchangeRates.Currency = MatchingCourseDates.Currency
	|				AND ExchangeRates.BaseCurrency = &BaseCurrency
	|	
	|	GROUP BY
	|		MatchingCourseDates.Currency) AS NestedQuery
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|";
	
	If StructureOfReportGenerationPeriods.ThereIsExtraPeriod Then
		
		LastPacketNumber = LastPacketNumber + 2;
		
		QueryText = QueryText + "
		|SELECT ALLOWED
		|	CalendarSchedules.ScheduleDate AS ScheduleDate,
		|	ExchangeRates.Currency,
		|	MAX(ExchangeRates.Period) AS Period
		|INTO MatchingCourseDatesAdditionalPeriod
		|FROM
		|	InformationRegister.CalendarSchedules AS CalendarSchedules
		|		LEFT JOIN InformationRegister.RelativeExchangeRates AS ExchangeRates
		|		ON CalendarSchedules.ScheduleDate > ExchangeRates.Period
		|			AND ExchangeRates.BaseCurrency = &BaseCurrency
		|WHERE
		|	CalendarSchedules.ScheduleDate BETWEEN &StartDateAdditionalPeriod AND &EndDateAdditionalPeriod
		|	AND CalendarSchedules.Calendar IN
		|			(SELECT
		|				Calendar.MainEnterpriseCalendar
		|			FROM
		|				Calendar AS Calendar)
		|
		|GROUP BY
		|	ExchangeRates.Currency,
		|	CalendarSchedules.ScheduleDate
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT ALLOWED
		|	NestedQuery.Currency,
		|	CASE
		|		WHEN DATEDIFF(&BeginOfPeriod, &PeriodEnding, DAY) + 1 = 0
		|			THEN 0
		|		ELSE NestedQuery.Rate / (DATEDIFF(&StartDateAdditionalPeriod, &EndDateAdditionalPeriod, DAY) + 1)
		|	END AS WeightedAverageExchangeRate
		|INTO WeightedAverageExchangeRatesForAdditionalPeriod
		|FROM
		|	(SELECT
		|		MatchingCourseDates.Currency AS Currency,
		|		SUM(CASE
		|				WHEN ExchangeRates.CourseDenominator = 0
		|					THEN 0
		|				ELSE ExchangeRates.CourseNumerator / ExchangeRates.CourseDenominator
		|			END) AS Rate
		|	FROM
		|		InformationRegister.RelativeExchangeRates AS ExchangeRates
		|			INNER JOIN MatchingCourseDatesAdditionalPeriod AS MatchingCourseDates
		|			ON ExchangeRates.Period = MatchingCourseDates.Period
		|				AND ExchangeRates.Currency = MatchingCourseDates.Currency
		|				AND ExchangeRates.BaseCurrency = &BaseCurrency
		|	
		|	GROUP BY
		|		MatchingCourseDates.Currency) AS NestedQuery
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|";
		
	EndIf;
	
	Return QueryText;
	
EndFunction

Function TextOfProfitRequest(MatchingRequestsData,LastPacketNumber,StructureOfReportGenerationPeriods)
	
	If StructureOfReportGenerationPeriods.ThereIsExtraPeriod Then
		
		MatchingRequestsData.Insert("Profit_",LastPacketNumber + 3);
		LastPacketNumber = LastPacketNumber + 3;
		
		Return "SELECT ALLOWED
		|	RevenueAndCostOfSalesTurnover.SalesOrder.Manager AS Manager,
		|	SUM(RevenueAndCostOfSalesTurnover.RevenueAmountTurnover - RevenueAndCostOfSalesTurnover.CostTurnover) AS Profit_
		|INTO CurPeriodProfit
		|FROM
		|	AccumulationRegister.RevenueAndCOGS.Turnovers(&BeginOfPeriod, &PeriodEnding, , AccountingDimensionByPartners.Partner <> VALUE(Catalog.Partners.RetailCustomer) AND SalesOrder.Manager IN (SELECT FilterByManagers.Ref FROM FilterByManagers AS FilterByManagers)) AS RevenueAndCostOfSalesTurnover
		|
		|GROUP BY
		|	RevenueAndCostOfSalesTurnover.SalesOrder.Manager
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT ALLOWED
		|	RevenueAndCostOfSalesTurnover.SalesOrder.Manager AS Manager,
		|	SUM(RevenueAndCostOfSalesTurnover.RevenueAmountTurnover - RevenueAndCostOfSalesTurnover.CostTurnover) AS Profit_
		|INTO PreviousPeriodProfit
		|FROM
		|	AccumulationRegister.RevenueAndCOGS.Turnovers(&StartDateAdditionalPeriod, &EndDateAdditionalPeriod, , AccountingDimensionByPartners.Partner <> VALUE(Catalog.Partners.RetailCustomer) AND SalesOrder.Manager IN (SELECT FilterByManagers.Ref FROM FilterByManagers AS FilterByManagers)) AS RevenueAndCostOfSalesTurnover
		|
		|GROUP BY
		|	RevenueAndCostOfSalesTurnover.SalesOrder.Manager
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	ISNULL(NestedQuery.Manager, &NotSpecified) AS Manager,
		|	NestedQuery.Current_,
		|	NestedQuery.Previous,
		|	CASE
		|		WHEN NestedQuery.Current_ - NestedQuery.Previous > 0
		|			THEN NestedQuery.Current_ - NestedQuery.Previous
		|		ELSE 0
		|	END AS Growth,
		|	CASE
		|		WHEN NestedQuery.Current_ - NestedQuery.Previous < 0
		|			THEN NestedQuery.Current_ - NestedQuery.Previous
		|		ELSE 0
		|	END AS Slippage
		|FROM
		|	(SELECT
		|		CASE
		|			WHEN PreviousPeriod_.Manager IS NULL 
		|				THEN CurrentPeriod.Manager
		|			ELSE PreviousPeriod_.Manager
		|		END AS Manager,
		|		SUM(ISNULL(PreviousPeriod_.Profit_, 0)) AS Previous,
		|		SUM(ISNULL(CurrentPeriod.Profit_, 0)) AS Current_
		|	FROM
		|		PreviousPeriodProfit AS PreviousPeriod_
		|			FULL JOIN CurPeriodProfit AS CurrentPeriod
		|			ON PreviousPeriod_.Manager = CurrentPeriod.Manager
		|	
		|	GROUP BY
		|		CASE
		|			WHEN PreviousPeriod_.Manager IS NULL 
		|				THEN CurrentPeriod.Manager
		|			ELSE PreviousPeriod_.Manager
		|		END) AS NestedQuery
		|
		|ORDER BY
		|	NestedQuery.Current_
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|";
		
	Else
		
		MatchingRequestsData.Insert("Profit_",LastPacketNumber + 1);
		LastPacketNumber = LastPacketNumber + 1;
		
		Return "SELECT ALLOWED
		|	CASE
		|		WHEN RevenueAndCostOfSalesTurnover.SalesOrder.Manager IS NULL 
		|			THEN &NotSpecified
		|		ELSE PRESENTATION(RevenueAndCostOfSalesTurnover.SalesOrder.Manager)
		|	END AS Manager,
		|	SUM(RevenueAndCostOfSalesTurnover.RevenueAmountTurnover - RevenueAndCostOfSalesTurnover.CostTurnover) AS Profit_
		|FROM
		|	AccumulationRegister.RevenueAndCOGS.Turnovers(&BeginOfPeriod, &PeriodEnding, , AccountingDimensionByPartners.Partner <> VALUE(Catalog.Partners.RetailCustomer) AND SalesOrder.Manager IN (SELECT FilterByManagers.Ref FROM FilterByManagers AS FilterByManagers)) AS RevenueAndCostOfSalesTurnover
		|
		|GROUP BY
		|	CASE
		|		WHEN RevenueAndCostOfSalesTurnover.SalesOrder.Manager IS NULL 
		|			THEN &NotSpecified
		|		ELSE PRESENTATION(RevenueAndCostOfSalesTurnover.SalesOrder.Manager)
		|	END
		|
		|ORDER BY
		|	Profit_
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|";
		
	EndIf;
	
EndFunction

Function SalesRequestText(MatchingRequestsData,LastPacketNumber, StructureOfReportGenerationPeriods)
	
	If StructureOfReportGenerationPeriods.ThereIsExtraPeriod Then
		
		MatchingRequestsData.Insert("Sales",LastPacketNumber + 3);
		LastPacketNumber = LastPacketNumber + 3;
		
		Return "SELECT ALLOWED
		|	RevenueAndCostOfSalesTurnover.SalesOrder.Manager AS Manager,
		|	SUM(RevenueAndCostOfSalesTurnover.RevenueAmountTurnover) AS Sales
		|INTO CurSalePeriod
		|FROM
		|	AccumulationRegister.RevenueAndCOGS.Turnovers(&BeginOfPeriod, &PeriodEnding, , AccountingDimensionByPartners.Partner <> VALUE(Catalog.Partners.RetailCustomer) AND SalesOrder.Manager IN (SELECT FilterByManagers.Ref FROM FilterByManagers AS FilterByManagers)) AS RevenueAndCostOfSalesTurnover
		|
		|GROUP BY
		|	RevenueAndCostOfSalesTurnover.SalesOrder.Manager
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT ALLOWED
		|	RevenueAndCostOfSalesTurnover.SalesOrder.Manager AS Manager,
		|	SUM(RevenueAndCostOfSalesTurnover.RevenueAmountTurnover) AS Sales
		|INTO PreviousSalePeriod
		|FROM
		|	AccumulationRegister.RevenueAndCOGS.Turnovers(&StartDateAdditionalPeriod, &EndDateAdditionalPeriod, , AccountingDimensionByPartners.Partner <> VALUE(Catalog.Partners.RetailCustomer) AND SalesOrder.Manager IN (SELECT FilterByManagers.Ref FROM FilterByManagers AS FilterByManagers)) AS RevenueAndCostOfSalesTurnover
		|
		|GROUP BY
		|	RevenueAndCostOfSalesTurnover.SalesOrder.Manager
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	ISNULL(NestedQuery.Manager, &NotSpecified) AS Manager,
		|	NestedQuery.Current_,
		|	NestedQuery.Previous,
		|	CASE
		|		WHEN NestedQuery.Current_ - NestedQuery.Previous > 0
		|			THEN NestedQuery.Current_ - NestedQuery.Previous
		|		ELSE 0
		|	END AS Growth,
		|	CASE
		|		WHEN NestedQuery.Current_ - NestedQuery.Previous < 0
		|			THEN NestedQuery.Current_ - NestedQuery.Previous
		|		ELSE 0
		|	END AS Slippage
		|FROM
		|	(SELECT
		|		CASE
		|			WHEN PreviousPeriod_.Manager IS NULL 
		|				THEN CurrentPeriod.Manager
		|			ELSE PreviousPeriod_.Manager
		|		END AS Manager,
		|		SUM(ISNULL(PreviousPeriod_.Sales, 0)) AS Previous,
		|		SUM(ISNULL(CurrentPeriod.Sales, 0)) AS Current_
		|	FROM
		|		PreviousSalePeriod AS PreviousPeriod_
		|			FULL JOIN CurSalePeriod AS CurrentPeriod
		|			ON PreviousPeriod_.Manager = CurrentPeriod.Manager
		|	
		|	GROUP BY
		|		CASE
		|			WHEN PreviousPeriod_.Manager IS NULL 
		|				THEN CurrentPeriod.Manager
		|			ELSE PreviousPeriod_.Manager
		|		END) AS NestedQuery
		|
		|ORDER BY
		|	NestedQuery.Current_
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|";
		
	Else
		
		MatchingRequestsData.Insert("Sales",LastPacketNumber + 1);
		LastPacketNumber = LastPacketNumber + 1;
		
		Return "SELECT ALLOWED
		|	CASE
		|		WHEN RevenueAndCostOfSalesTurnover.SalesOrder.Manager IS NULL 
		|			THEN &NotSpecified
		|		ELSE PRESENTATION(RevenueAndCostOfSalesTurnover.SalesOrder.Manager)
		|	END AS Manager,
		|	SUM(RevenueAndCostOfSalesTurnover.RevenueAmountTurnover) AS Sales
		|FROM
		|	AccumulationRegister.RevenueAndCOGS.Turnovers(&BeginOfPeriod, &PeriodEnding, , AccountingDimensionByPartners.Partner <> VALUE(Catalog.Partners.RetailCustomer) AND SalesOrder.Manager IN (SELECT FilterByManagers.Ref FROM FilterByManagers AS FilterByManagers)) AS RevenueAndCostOfSalesTurnover
		|
		|GROUP BY
		|	CASE
		|		WHEN RevenueAndCostOfSalesTurnover.SalesOrder.Manager IS NULL 
		|			THEN &NotSpecified
		|		ELSE PRESENTATION(RevenueAndCostOfSalesTurnover.SalesOrder.Manager)
		|	END
		|
		|ORDER BY
		|	Sales
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|";
		
	EndIf;
	
EndFunction

Function TextOfCashReceiptRequest(MatchingRequestsData,LastPacketNumber, StructureOfReportGenerationPeriods)
	
	If GetFunctionalOption("NewOnlineARAPAccounting") Then
		
		If StructureOfReportGenerationPeriods.ThereIsExtraPeriod Then
			
			LastPacketNumber = LastPacketNumber + 3;
			MatchingRequestsData.Insert("ReceiptOfCash",LastPacketNumber);
			
			Return "
			|SELECT ALLOWED
			|	CustomersARAPAccountingByDueDates.ARAPObject.Manager                                  AS Manager,
			|	SUM(CustomersARAPAccountingByDueDates.PrepaymentMan + CustomersARAPAccountingByDueDates.ARAPMan) AS Factor
			|INTO CurPeriodReceiptOfCash
			|FROM AccumulationRegister.CustomersARAPAccountingByDueDates AS CustomersARAPAccountingByDueDates
			|WHERE
			|	(CustomersARAPAccountingByDueDates.RecordType = VALUE(AccumulationRecordType.Expense)
			|			AND CustomersARAPAccountingByDueDates.ARAPMan > 0 
			|		OR CustomersARAPAccountingByDueDates.RecordType = VALUE(AccumulationRecordType.Receipt)
			|			AND CustomersARAPAccountingByDueDates.PrepaymentMan > 0)
			|	AND CustomersARAPAccountingByDueDates.ARAPObject IN (SELECT ARAPObject FROM ObjectsOfManagersCalculations)
			|	AND (CustomersARAPAccountingByDueDates.DocumentRecorder REFS Document.CashVoucher
			|			OR CustomersARAPAccountingByDueDates.DocumentRecorder REFS Document.PaymentCardTransaction
			|			OR CustomersARAPAccountingByDueDates.DocumentRecorder REFS Document.BankAccountReceiptNote
			|			OR CustomersARAPAccountingByDueDates.DocumentRecorder REFS Document.CashAccountReceiptNote
			|			OR CustomersARAPAccountingByDueDates.DocumentRecorder REFS Document.BankAccountIssue
			|			OR CustomersARAPAccountingByDueDates.DocumentRecorder REFS Document.ARAPAdjustment)
			|	AND CustomersARAPAccountingByDueDates.Period BETWEEN &BeginOfPeriod AND &PeriodEnding
			|	AND CustomersARAPAccountingByDueDates.ARAPObject.Partner <> VALUE(Catalog.Partners.RetailCustomer)
			|	AND CustomersARAPAccountingByDueDates.Active
			|
			|GROUP BY
			|	CustomersARAPAccountingByDueDates.ARAPObject.Manager
			|
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			|
			|SELECT ALLOWED
			|	CustomersARAPAccountingByDueDates.ARAPObject.Manager                                  AS Manager,
			|	SUM(CustomersARAPAccountingByDueDates.PrepaymentMan + CustomersARAPAccountingByDueDates.ARAPMan) AS Factor
			|INTO PreviousPeriodReceiptOfCash
			|FROM
			|	AccumulationRegister.CustomersARAPAccountingByDueDates AS CustomersARAPAccountingByDueDates
			|WHERE
			|	(CustomersARAPAccountingByDueDates.RecordType = VALUE(AccumulationRecordType.Expense)
			|			AND CustomersARAPAccountingByDueDates.ARAPMan > 0 
			|		OR CustomersARAPAccountingByDueDates.RecordType = VALUE(AccumulationRecordType.Receipt)
			|			AND CustomersARAPAccountingByDueDates.PrepaymentMan > 0)
			|	AND CustomersARAPAccountingByDueDates.ARAPObject IN (SELECT ARAPObject FROM ObjectsOfManagersCalculations)
			|	AND (CustomersARAPAccountingByDueDates.DocumentRecorder REFS Document.CashVoucher
			|			OR CustomersARAPAccountingByDueDates.DocumentRecorder REFS Document.PaymentCardTransaction
			|			OR CustomersARAPAccountingByDueDates.DocumentRecorder REFS Document.BankAccountReceiptNote
			|			OR CustomersARAPAccountingByDueDates.DocumentRecorder REFS Document.CashAccountReceiptNote
			|			OR CustomersARAPAccountingByDueDates.DocumentRecorder REFS Document.BankAccountIssue
			|			OR CustomersARAPAccountingByDueDates.DocumentRecorder REFS Document.ARAPAdjustment)
			|	AND CustomersARAPAccountingByDueDates.Period BETWEEN &StartDateAdditionalPeriod AND &EndDateAdditionalPeriod
			|	AND CustomersARAPAccountingByDueDates.ARAPObject.Partner <> VALUE(Catalog.Partners.RetailCustomer)
			|	AND CustomersARAPAccountingByDueDates.Active
			|
			|GROUP BY
			|	CustomersARAPAccountingByDueDates.ARAPObject.Manager
			|
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			|SELECT
			|	ISNULL(NestedQuery.Manager, &NotSpecified) AS Manager,
			|	NestedQuery.Current_,
			|	NestedQuery.Previous,
			|	CASE
			|		WHEN NestedQuery.Current_ - NestedQuery.Previous > 0
			|			THEN NestedQuery.Current_ - NestedQuery.Previous
			|		ELSE 0
			|	END AS Growth,
			|	CASE
			|		WHEN NestedQuery.Current_ - NestedQuery.Previous < 0
			|			THEN NestedQuery.Current_ - NestedQuery.Previous
			|		ELSE 0
			|	END AS Slippage
			|FROM
			|	(SELECT
			|		CASE
			|			WHEN PreviousPeriod_.Manager IS NULL 
			|				THEN CurrentPeriod.Manager
			|			ELSE PreviousPeriod_.Manager
			|		END AS Manager,
			|		SUM(ISNULL(PreviousPeriod_.Factor, 0)) AS Previous,
			|		SUM(ISNULL(CurrentPeriod.Factor, 0)) AS Current_
			|	FROM
			|		PreviousPeriodReceiptOfCash AS PreviousPeriod_
			|			FULL JOIN CurPeriodReceiptOfCash AS CurrentPeriod
			|			ON PreviousPeriod_.Manager = CurrentPeriod.Manager
			|	
			|	GROUP BY
			|		CASE
			|			WHEN PreviousPeriod_.Manager IS NULL 
			|				THEN CurrentPeriod.Manager
			|			ELSE PreviousPeriod_.Manager
			|		END) AS NestedQuery
			|
			|ORDER BY
			|	NestedQuery.Current_
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			|";
			
		Else
			
			LastPacketNumber = LastPacketNumber + 1;
			MatchingRequestsData.Insert("ReceiptOfCash",LastPacketNumber);
			
			Return "
			|SELECT ALLOWED
			|	CustomersARAPAccountingByDueDates.ARAPObject.Manager                                  AS Manager,
			|	SUM(CustomersARAPAccountingByDueDates.PrepaymentMan + CustomersARAPAccountingByDueDates.ARAPMan) AS ReceiptOfCash
			|FROM
			|	AccumulationRegister.CustomersARAPAccountingByDueDates AS CustomersARAPAccountingByDueDates
			|WHERE
			|	(CustomersARAPAccountingByDueDates.RecordType = VALUE(AccumulationRecordType.Expense)
			|			AND CustomersARAPAccountingByDueDates.ARAPMan > 0 
			|		OR CustomersARAPAccountingByDueDates.RecordType = VALUE(AccumulationRecordType.Receipt)
			|			AND CustomersARAPAccountingByDueDates.PrepaymentMan > 0)
			|	AND CustomersARAPAccountingByDueDates.ARAPObject IN (SELECT ARAPObject FROM ObjectsOfManagersCalculations)
			|	AND (CustomersARAPAccountingByDueDates.DocumentRecorder REFS Document.CashVoucher
			|			OR CustomersARAPAccountingByDueDates.DocumentRecorder REFS Document.PaymentCardTransaction
			|			OR CustomersARAPAccountingByDueDates.DocumentRecorder REFS Document.BankAccountReceiptNote
			|			OR CustomersARAPAccountingByDueDates.DocumentRecorder REFS Document.CashAccountReceiptNote
			|			OR CustomersARAPAccountingByDueDates.DocumentRecorder REFS Document.BankAccountIssue
			|			OR CustomersARAPAccountingByDueDates.DocumentRecorder REFS Document.ARAPAdjustment)
			|	AND CustomersARAPAccountingByDueDates.Period BETWEEN &BeginOfPeriod AND &PeriodEnding
			|	AND CustomersARAPAccountingByDueDates.ARAPObject.Partner <> VALUE(Catalog.Partners.RetailCustomer)
			|	AND CustomersARAPAccountingByDueDates.Active
			|
			|GROUP BY
			|	CustomersARAPAccountingByDueDates.ARAPObject.Manager
			|ORDER BY
			|	ReceiptOfCash DESC
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			|";
			
		EndIf;
		
	Else
	
		If StructureOfReportGenerationPeriods.ThereIsExtraPeriod Then
			
			LastPacketNumber = LastPacketNumber + 5;
			MatchingRequestsData.Insert("ReceiptOfCash",LastPacketNumber);
			
			Return "
			|SELECT ALLOWED
			|	NestedQuery.Manager,
			|	NestedQuery.Currency,
			|	SUM(NestedQuery.ReceiptOfCash) AS ReceiptOfCash
			|INTO CurPeriodReceiptOfCashCurrency
			|FROM
			|	(SELECT
			|		CustomersARAPAccountingByDocuments.SalesOrder.Manager AS Manager,
			|		CustomersARAPAccountingByDocuments.Debt AS ReceiptOfCash,
			|		CustomersARAPAccountingByDocuments.Currency AS Currency
			|	FROM
			|		AccumulationRegister.CustomersARAPAccountingByDocuments AS CustomersARAPAccountingByDocuments
			|	WHERE
			|		CustomersARAPAccountingByDocuments.RecordType = VALUE(AccumulationRecordType.Expense)
			|		AND CustomersARAPAccountingByDocuments.SalesOrder.Manager IN
			|				(SELECT
			|					FilterByManagers.Ref
			|				FROM
			|					FilterByManagers AS FilterByManagers)
			|		AND CustomersARAPAccountingByDocuments.Debt <> 0
			|		AND (CustomersARAPAccountingByDocuments.Recorder REFS Document.CashVoucher
			|				OR CustomersARAPAccountingByDocuments.Recorder REFS Document.PaymentCardTransaction
			|				OR CustomersARAPAccountingByDocuments.Recorder REFS Document.BankAccountReceiptNote
			|				OR CustomersARAPAccountingByDocuments.Recorder REFS Document.CashAccountReceiptNote
			|				OR CustomersARAPAccountingByDocuments.Recorder REFS Document.CashVoucher
			|				OR CustomersARAPAccountingByDocuments.Recorder REFS Document.BankAccountIssue
			|				OR CustomersARAPAccountingByDocuments.Recorder REFS Document.ARAPAdjustment)
			|		AND CustomersARAPAccountingByDocuments.Period BETWEEN &BeginOfPeriod AND &PeriodEnding
			|		AND CustomersARAPAccountingByDocuments.SalesOrder.Partner <> VALUE(Catalog.Partners.RetailCustomer)
			|		AND CustomersARAPAccountingByDocuments.Active
			|	
			|	UNION ALL
			|	
			|	SELECT
			|		CustomersARAPAccountingByDocuments.SalesOrder.Manager,
			|		CustomersARAPAccountingByDocuments.Prepayment,
			|		CustomersARAPAccountingByDocuments.Currency
			|	FROM
			|		AccumulationRegister.CustomersARAPAccountingByDocuments AS CustomersARAPAccountingByDocuments
			|	WHERE
			|		CustomersARAPAccountingByDocuments.RecordType = VALUE(AccumulationRecordType.Receipt)
			|		AND CustomersARAPAccountingByDocuments.Prepayment <> 0
			|		AND CustomersARAPAccountingByDocuments.SalesOrder.Manager IN
			|				(SELECT
			|					FilterByManagers.Ref
			|				FROM
			|					FilterByManagers AS FilterByManagers)
			|		AND (CustomersARAPAccountingByDocuments.Recorder REFS Document.CustomerInvoiceServices
			|				OR CustomersARAPAccountingByDocuments.Recorder REFS Document.SalesOrder
			|				OR CustomersARAPAccountingByDocuments.Recorder REFS Document.SaleAdjustment
			|				OR CustomersARAPAccountingByDocuments.Recorder REFS Document.CustomerInvoice
			|				OR CustomersARAPAccountingByDocuments.Recorder REFS Document.CustomerInvoiceServicesAndAssets)
			|		AND CustomersARAPAccountingByDocuments.Period BETWEEN &BeginOfPeriod AND &PeriodEnding
			|		AND CustomersARAPAccountingByDocuments.SalesOrder.Partner <> VALUE(Catalog.Partners.RetailCustomer)
			|		AND CustomersARAPAccountingByDocuments.Active
			|	
			|	UNION ALL
			|	
			|	SELECT
			|		NestedQuery.CustomerOrderManager,
			|		SUM(NestedQuery.Prepayment),
			|		NestedQuery.Currency
			|	FROM
			|		(SELECT
			|			SUM(CASE
			|					WHEN CustomersARAPAccountingByDocuments.RecordType = VALUE(AccumulationRecordType.Expense)
			|						THEN CustomersARAPAccountingByDocuments.Prepayment
			|					ELSE -CustomersARAPAccountingByDocuments.Prepayment
			|				END) AS Prepayment,
			|			CustomersARAPAccountingByDocuments.SalesOrder.Manager AS CustomerOrderManager,
			|			CustomersARAPAccountingByDocuments.Currency AS Currency,
			|			CustomersARAPAccountingByDocuments.ARAPDocument AS ARAPDocument
			|		FROM
			|			AccumulationRegister.CustomersARAPAccountingByDocuments AS CustomersARAPAccountingByDocuments
			|		WHERE
			|			CustomersARAPAccountingByDocuments.SalesOrder.Manager IN
			|				(SELECT
			|					FilterByManagers.Ref
			|				FROM
			|					FilterByManagers AS FilterByManagers)
			|			AND CustomersARAPAccountingByDocuments.Period BETWEEN &BeginOfPeriod AND &PeriodEnding
			|			AND CustomersARAPAccountingByDocuments.Prepayment <> 0
			|			AND CustomersARAPAccountingByDocuments.SalesOrder.Partner <> VALUE(Catalog.Partners.RetailCustomer)
			|			AND (CustomersARAPAccountingByDocuments.RecordType = VALUE(AccumulationRecordType.Expense)
			|						AND (CustomersARAPAccountingByDocuments.Recorder REFS Document.CashVoucher
			|							OR CustomersARAPAccountingByDocuments.Recorder REFS Document.PaymentCardTransaction
			|							OR CustomersARAPAccountingByDocuments.Recorder REFS Document.BankAccountReceiptNote
			|							OR CustomersARAPAccountingByDocuments.Recorder REFS Document.CashAccountReceiptNote
			|							OR CustomersARAPAccountingByDocuments.Recorder REFS Document.CashVoucher
			|							OR CustomersARAPAccountingByDocuments.Recorder REFS Document.BankAccountIssue
			|							OR CustomersARAPAccountingByDocuments.Recorder REFS Document.ARAPAdjustment)
			|					OR CustomersARAPAccountingByDocuments.RecordType = VALUE(AccumulationRecordType.Receipt)
			|						AND (CustomersARAPAccountingByDocuments.Recorder REFS Document.CustomerInvoiceServices
			|							OR CustomersARAPAccountingByDocuments.Recorder REFS Document.SalesOrder
			|							OR CustomersARAPAccountingByDocuments.Recorder REFS Document.SaleAdjustment
			|							OR CustomersARAPAccountingByDocuments.Recorder REFS Document.CustomerInvoice
			|							OR CustomersARAPAccountingByDocuments.Recorder REFS Document.CustomerInvoiceServicesAndAssets))
			|			AND CustomersARAPAccountingByDocuments.Active
			|		
			|		GROUP BY
			|			CustomersARAPAccountingByDocuments.SalesOrder.Manager,
			|			CustomersARAPAccountingByDocuments.ARAPDocument,
			|			CustomersARAPAccountingByDocuments.Currency
			|		
			|		HAVING
			|			SUM(CASE
			|					WHEN CustomersARAPAccountingByDocuments.RecordType = VALUE(AccumulationRecordType.Expense)
			|						THEN CustomersARAPAccountingByDocuments.Prepayment
			|					ELSE -CustomersARAPAccountingByDocuments.Prepayment
			|				END) > 0) AS NestedQuery
			|	
			|	GROUP BY
			|		NestedQuery.CustomerOrderManager,
			|		NestedQuery.Currency) AS NestedQuery
			|
			|GROUP BY
			|	NestedQuery.Manager,
			|	NestedQuery.Currency
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			|SELECT
			|	CurPeriodReceiptOfCashCurrency.Manager,
			|	SUM(CASE
			|			WHEN CurPeriodReceiptOfCashCurrency.Currency = &ManagementAccountingCurrency
			|				THEN CurPeriodReceiptOfCashCurrency.ReceiptOfCash
			|			ELSE CASE
			|					WHEN ISNULL(ExchangeRateOfManagementAccounting_.WeightedAverageExchangeRate, 0) = 0
			|						THEN 0
			|					ELSE CurPeriodReceiptOfCashCurrency.ReceiptOfCash * ISNULL(OtherCurrencyRates.WeightedAverageExchangeRate, 0) / ISNULL(ExchangeRateOfManagementAccounting_.WeightedAverageExchangeRate, 0)
			|				END
			|		END) AS Factor
			|INTO CurPeriodReceiptOfCash
			|FROM
			|	CurPeriodReceiptOfCashCurrency AS CurPeriodReceiptOfCashCurrency
			|		LEFT JOIN WeightedAverageExchangeRatesForCurPeriod AS OtherCurrencyRates
			|		ON CurPeriodReceiptOfCashCurrency.Currency = OtherCurrencyRates.Currency
			|		LEFT JOIN WeightedAverageExchangeRatesForCurPeriod AS ExchangeRateOfManagementAccounting_
			|		ON (&ManagementAccountingCurrency = ExchangeRateOfManagementAccounting_.Currency)
			|
			|GROUP BY
			|	CurPeriodReceiptOfCashCurrency.Manager
			|
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			|SELECT ALLOWED
			|	NestedQuery.Manager,
			|	NestedQuery.Currency,
			|	SUM(NestedQuery.ReceiptOfCash) AS ReceiptOfCash
			|INTO PreviousPeriodReceiptOfCashCurrency
			|FROM
			|	(SELECT
			|		CustomersARAPAccountingByDocuments.SalesOrder.Manager AS Manager,
			|		CustomersARAPAccountingByDocuments.Debt AS ReceiptOfCash,
			|		CustomersARAPAccountingByDocuments.Currency AS Currency
			|	FROM
			|		AccumulationRegister.CustomersARAPAccountingByDocuments AS CustomersARAPAccountingByDocuments
			|	WHERE
			|		CustomersARAPAccountingByDocuments.RecordType = VALUE(AccumulationRecordType.Expense)
			|		AND CustomersARAPAccountingByDocuments.SalesOrder.Manager IN
			|				(SELECT
			|					FilterByManagers.Ref
			|				FROM
			|					FilterByManagers AS FilterByManagers)
			|		AND CustomersARAPAccountingByDocuments.Debt <> 0
			|		AND (CustomersARAPAccountingByDocuments.Recorder REFS Document.CashVoucher
			|				OR CustomersARAPAccountingByDocuments.Recorder REFS Document.PaymentCardTransaction
			|				OR CustomersARAPAccountingByDocuments.Recorder REFS Document.BankAccountReceiptNote
			|				OR CustomersARAPAccountingByDocuments.Recorder REFS Document.CashAccountReceiptNote
			|				OR CustomersARAPAccountingByDocuments.Recorder REFS Document.CashVoucher
			|				OR CustomersARAPAccountingByDocuments.Recorder REFS Document.BankAccountIssue
			|				OR CustomersARAPAccountingByDocuments.Recorder REFS Document.ARAPAdjustment)
			|		AND CustomersARAPAccountingByDocuments.Period BETWEEN &StartDateAdditionalPeriod AND &EndDateAdditionalPeriod
			|		AND CustomersARAPAccountingByDocuments.SalesOrder.Partner <> VALUE(Catalog.Partners.RetailCustomer)
			|		AND CustomersARAPAccountingByDocuments.Active
			|	
			|	UNION ALL
			|	
			|	SELECT
			|		CustomersARAPAccountingByDocuments.SalesOrder.Manager,
			|		CustomersARAPAccountingByDocuments.Prepayment,
			|		CustomersARAPAccountingByDocuments.Currency
			|	FROM
			|		AccumulationRegister.CustomersARAPAccountingByDocuments AS CustomersARAPAccountingByDocuments
			|	WHERE
			|		CustomersARAPAccountingByDocuments.RecordType = VALUE(AccumulationRecordType.Receipt)
			|		AND CustomersARAPAccountingByDocuments.Prepayment <> 0
			|		AND CustomersARAPAccountingByDocuments.SalesOrder.Manager IN
			|				(SELECT
			|					FilterByManagers.Ref
			|				FROM
			|					FilterByManagers AS FilterByManagers)
			|		AND (CustomersARAPAccountingByDocuments.Recorder REFS Document.CustomerInvoiceServices
			|				OR CustomersARAPAccountingByDocuments.Recorder REFS Document.SalesOrder
			|				OR CustomersARAPAccountingByDocuments.Recorder REFS Document.SaleAdjustment
			|				OR CustomersARAPAccountingByDocuments.Recorder REFS Document.CustomerInvoice
			|				OR CustomersARAPAccountingByDocuments.Recorder REFS Document.CustomerInvoiceServicesAndAssets)
			|		AND CustomersARAPAccountingByDocuments.Period BETWEEN &StartDateAdditionalPeriod AND &EndDateAdditionalPeriod
			|		AND CustomersARAPAccountingByDocuments.SalesOrder.Partner <> VALUE(Catalog.Partners.RetailCustomer)
			|		AND CustomersARAPAccountingByDocuments.Active
			|	
			|	UNION ALL
			|	
			|	SELECT
			|		NestedQuery.CustomerOrderManager,
			|		SUM(NestedQuery.Prepayment),
			|		NestedQuery.Currency
			|	FROM
			|		(SELECT
			|			SUM(CASE
			|					WHEN CustomersARAPAccountingByDocuments.RecordType = VALUE(AccumulationRecordType.Expense)
			|						THEN CustomersARAPAccountingByDocuments.Prepayment
			|					ELSE -CustomersARAPAccountingByDocuments.Prepayment
			|				END) AS Prepayment,
			|			CustomersARAPAccountingByDocuments.SalesOrder.Manager AS CustomerOrderManager,
			|			CustomersARAPAccountingByDocuments.Currency AS Currency,
			|			CustomersARAPAccountingByDocuments.ARAPDocument AS ARAPDocument
			|		FROM
			|			AccumulationRegister.CustomersARAPAccountingByDocuments AS CustomersARAPAccountingByDocuments
			|		WHERE
			|			CustomersARAPAccountingByDocuments.SalesOrder.Manager IN
			|				(SELECT
			|					FilterByManagers.Ref
			|				FROM
			|					FilterByManagers AS FilterByManagers)
			|			AND CustomersARAPAccountingByDocuments.Period BETWEEN &StartDateAdditionalPeriod AND &EndDateAdditionalPeriod
			|			AND CustomersARAPAccountingByDocuments.Prepayment <> 0
			|			AND CustomersARAPAccountingByDocuments.SalesOrder.Partner <> VALUE(Catalog.Partners.RetailCustomer)
			|			AND (CustomersARAPAccountingByDocuments.RecordType = VALUE(AccumulationRecordType.Expense)
			|						AND (CustomersARAPAccountingByDocuments.Recorder REFS Document.CashVoucher
			|							OR CustomersARAPAccountingByDocuments.Recorder REFS Document.PaymentCardTransaction
			|							OR CustomersARAPAccountingByDocuments.Recorder REFS Document.BankAccountReceiptNote
			|							OR CustomersARAPAccountingByDocuments.Recorder REFS Document.CashAccountReceiptNote
			|							OR CustomersARAPAccountingByDocuments.Recorder REFS Document.CashVoucher
			|							OR CustomersARAPAccountingByDocuments.Recorder REFS Document.BankAccountIssue
			|							OR CustomersARAPAccountingByDocuments.Recorder REFS Document.ARAPAdjustment)
			|					OR CustomersARAPAccountingByDocuments.RecordType = VALUE(AccumulationRecordType.Receipt)
			|						AND (CustomersARAPAccountingByDocuments.Recorder REFS Document.CustomerInvoiceServices
			|							OR CustomersARAPAccountingByDocuments.Recorder REFS Document.SalesOrder
			|							OR CustomersARAPAccountingByDocuments.Recorder REFS Document.SaleAdjustment
			|							OR CustomersARAPAccountingByDocuments.Recorder REFS Document.CustomerInvoice
			|							OR CustomersARAPAccountingByDocuments.Recorder REFS Document.CustomerInvoiceServicesAndAssets))
			|			AND CustomersARAPAccountingByDocuments.Active
			|		
			|		GROUP BY
			|			CustomersARAPAccountingByDocuments.ARAPDocument,
			|			CustomersARAPAccountingByDocuments.SalesOrder.Manager,
			|			CustomersARAPAccountingByDocuments.Currency
			|		
			|		HAVING
			|			SUM(CASE
			|					WHEN CustomersARAPAccountingByDocuments.RecordType = VALUE(AccumulationRecordType.Expense)
			|						THEN CustomersARAPAccountingByDocuments.Prepayment
			|					ELSE -CustomersARAPAccountingByDocuments.Prepayment
			|				END) > 0) AS NestedQuery
			|	
			|	GROUP BY
			|		NestedQuery.CustomerOrderManager,
			|		NestedQuery.Currency) AS NestedQuery
			|
			|GROUP BY
			|	NestedQuery.Manager,
			|	NestedQuery.Currency
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			|SELECT
			|	PreviousPeriodReceiptOfCashCurrency.Manager,
			|	SUM(CASE
			|			WHEN PreviousPeriodReceiptOfCashCurrency.Currency = &ManagementAccountingCurrency
			|				THEN PreviousPeriodReceiptOfCashCurrency.ReceiptOfCash
			|			ELSE CASE
			|					WHEN ISNULL(ExchangeRateOfManagementAccounting_.WeightedAverageExchangeRate, 0) = 0
			|						THEN 0
			|					ELSE PreviousPeriodReceiptOfCashCurrency.ReceiptOfCash * ISNULL(OtherCurrencyRates.WeightedAverageExchangeRate, 0) / ISNULL(ExchangeRateOfManagementAccounting_.WeightedAverageExchangeRate, 0)
			|				END
			|		END) AS Factor
			|INTO PreviousPeriodReceiptOfCash
			|FROM
			|	PreviousPeriodReceiptOfCashCurrency AS PreviousPeriodReceiptOfCashCurrency
			|		LEFT JOIN WeightedAverageExchangeRatesForCurPeriod AS OtherCurrencyRates
			|		ON PreviousPeriodReceiptOfCashCurrency.Currency = OtherCurrencyRates.Currency
			|		LEFT JOIN WeightedAverageExchangeRatesForCurPeriod AS ExchangeRateOfManagementAccounting_
			|		ON (&ManagementAccountingCurrency = ExchangeRateOfManagementAccounting_.Currency)
			|
			|GROUP BY
			|	PreviousPeriodReceiptOfCashCurrency.Manager
			|
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			|SELECT
			|	ISNULL(NestedQuery.Manager, &NotSpecified) AS Manager,
			|	NestedQuery.Current_,
			|	NestedQuery.Previous,
			|	CASE
			|		WHEN NestedQuery.Current_ - NestedQuery.Previous > 0
			|			THEN NestedQuery.Current_ - NestedQuery.Previous
			|		ELSE 0
			|	END AS Growth,
			|	CASE
			|		WHEN NestedQuery.Current_ - NestedQuery.Previous < 0
			|			THEN NestedQuery.Current_ - NestedQuery.Previous
			|		ELSE 0
			|	END AS Slippage
			|FROM
			|	(SELECT
			|		CASE
			|			WHEN PreviousPeriod_.Manager IS NULL 
			|				THEN CurrentPeriod.Manager
			|			ELSE PreviousPeriod_.Manager
			|		END AS Manager,
			|		SUM(ISNULL(PreviousPeriod_.Factor, 0)) AS Previous,
			|		SUM(ISNULL(CurrentPeriod.Factor, 0)) AS Current_
			|	FROM
			|		PreviousPeriodReceiptOfCash AS PreviousPeriod_
			|			FULL JOIN CurPeriodReceiptOfCash AS CurrentPeriod
			|			ON PreviousPeriod_.Manager = CurrentPeriod.Manager
			|	
			|	GROUP BY
			|		CASE
			|			WHEN PreviousPeriod_.Manager IS NULL 
			|				THEN CurrentPeriod.Manager
			|			ELSE PreviousPeriod_.Manager
			|		END) AS NestedQuery
			|
			|ORDER BY
			|	NestedQuery.Current_
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			|";
			
		Else
			
			LastPacketNumber = LastPacketNumber + 2;
			MatchingRequestsData.Insert("ReceiptOfCash",LastPacketNumber);
			
			Return "
			|SELECT ALLOWED
			|	NestedQuery.Manager,
			|	NestedQuery.Currency,
			|	SUM(NestedQuery.ReceiptOfCash) AS ReceiptOfCash
			|INTO CurPeriodReceiptOfCashCurrency
			|FROM
			|	(SELECT
			|		CustomersARAPAccountingByDocuments.SalesOrder.Manager AS Manager,
			|		CustomersARAPAccountingByDocuments.Debt AS ReceiptOfCash,
			|		CustomersARAPAccountingByDocuments.Currency AS Currency
			|	FROM
			|		AccumulationRegister.CustomersARAPAccountingByDocuments AS CustomersARAPAccountingByDocuments
			|	WHERE
			|		CustomersARAPAccountingByDocuments.RecordType = VALUE(AccumulationRecordType.Expense)
			|		AND CustomersARAPAccountingByDocuments.SalesOrder.Manager IN
			|				(SELECT
			|					FilterByManagers.Ref
			|				FROM
			|					FilterByManagers AS FilterByManagers)
			|		AND CustomersARAPAccountingByDocuments.Debt <> 0
			|		AND (CustomersARAPAccountingByDocuments.Recorder REFS Document.CashVoucher
			|				OR CustomersARAPAccountingByDocuments.Recorder REFS Document.PaymentCardTransaction
			|				OR CustomersARAPAccountingByDocuments.Recorder REFS Document.BankAccountReceiptNote
			|				OR CustomersARAPAccountingByDocuments.Recorder REFS Document.CashAccountReceiptNote
			|				OR CustomersARAPAccountingByDocuments.Recorder REFS Document.CashVoucher
			|				OR CustomersARAPAccountingByDocuments.Recorder REFS Document.BankAccountIssue
			|				OR CustomersARAPAccountingByDocuments.Recorder REFS Document.ARAPAdjustment)
			|		AND CustomersARAPAccountingByDocuments.Period BETWEEN &BeginOfPeriod AND &PeriodEnding
			|		AND CustomersARAPAccountingByDocuments.SalesOrder.Partner <> VALUE(Catalog.Partners.RetailCustomer)
			|		AND CustomersARAPAccountingByDocuments.Active
			|	
			|	UNION ALL
			|	
			|	SELECT
			|		CustomersARAPAccountingByDocuments.SalesOrder.Manager,
			|		CustomersARAPAccountingByDocuments.Prepayment,
			|		CustomersARAPAccountingByDocuments.Currency
			|	FROM
			|		AccumulationRegister.CustomersARAPAccountingByDocuments AS CustomersARAPAccountingByDocuments
			|	WHERE
			|		CustomersARAPAccountingByDocuments.RecordType = VALUE(AccumulationRecordType.Receipt)
			|		AND CustomersARAPAccountingByDocuments.Prepayment <> 0
			|		AND CustomersARAPAccountingByDocuments.SalesOrder.Manager IN
			|				(SELECT
			|					FilterByManagers.Ref
			|				FROM
			|					FilterByManagers AS FilterByManagers)
			|		AND (CustomersARAPAccountingByDocuments.Recorder REFS Document.CustomerInvoiceServices
			|				OR CustomersARAPAccountingByDocuments.Recorder REFS Document.SalesOrder
			|				OR CustomersARAPAccountingByDocuments.Recorder REFS Document.SaleAdjustment
			|				OR CustomersARAPAccountingByDocuments.Recorder REFS Document.CustomerInvoice
			|				OR CustomersARAPAccountingByDocuments.Recorder REFS Document.CustomerInvoiceServicesAndAssets)
			|		AND CustomersARAPAccountingByDocuments.Period BETWEEN &BeginOfPeriod AND &PeriodEnding
			|		AND CustomersARAPAccountingByDocuments.SalesOrder.Partner <> VALUE(Catalog.Partners.RetailCustomer)
			|		AND CustomersARAPAccountingByDocuments.Active
			|	
			|	UNION ALL
			|	
			|	SELECT
			|		NestedQuery.CustomerOrderManager,
			|		SUM(NestedQuery.Prepayment),
			|		NestedQuery.Currency
			|	FROM
			|		(SELECT
			|			SUM(CASE
			|					WHEN CustomersARAPAccountingByDocuments.RecordType = VALUE(AccumulationRecordType.Expense)
			|						THEN CustomersARAPAccountingByDocuments.Prepayment
			|					ELSE -CustomersARAPAccountingByDocuments.Prepayment
			|				END) AS Prepayment,
			|			CustomersARAPAccountingByDocuments.SalesOrder.Manager AS CustomerOrderManager,
			|			CustomersARAPAccountingByDocuments.Currency AS Currency,
			|			CustomersARAPAccountingByDocuments.ARAPDocument AS ARAPDocument
			|		FROM
			|			AccumulationRegister.CustomersARAPAccountingByDocuments AS CustomersARAPAccountingByDocuments
			|		WHERE
			|			CustomersARAPAccountingByDocuments.SalesOrder.Manager IN
			|				(SELECT
			|					FilterByManagers.Ref
			|				FROM
			|					FilterByManagers AS FilterByManagers)
			|			AND CustomersARAPAccountingByDocuments.Period BETWEEN &BeginOfPeriod AND &PeriodEnding
			|			AND CustomersARAPAccountingByDocuments.Prepayment <> 0
			|			AND CustomersARAPAccountingByDocuments.SalesOrder.Partner <> VALUE(Catalog.Partners.RetailCustomer)
			|			AND (CustomersARAPAccountingByDocuments.RecordType = VALUE(AccumulationRecordType.Expense)
			|						AND (CustomersARAPAccountingByDocuments.Recorder REFS Document.CashVoucher
			|							OR CustomersARAPAccountingByDocuments.Recorder REFS Document.PaymentCardTransaction
			|							OR CustomersARAPAccountingByDocuments.Recorder REFS Document.BankAccountReceiptNote
			|							OR CustomersARAPAccountingByDocuments.Recorder REFS Document.CashAccountReceiptNote
			|							OR CustomersARAPAccountingByDocuments.Recorder REFS Document.CashVoucher
			|							OR CustomersARAPAccountingByDocuments.Recorder REFS Document.BankAccountIssue
			|							OR CustomersARAPAccountingByDocuments.Recorder REFS Document.ARAPAdjustment)
			|					OR CustomersARAPAccountingByDocuments.RecordType = VALUE(AccumulationRecordType.Receipt)
			|						AND (CustomersARAPAccountingByDocuments.Recorder REFS Document.CustomerInvoiceServices
			|							OR CustomersARAPAccountingByDocuments.Recorder REFS Document.SalesOrder
			|							OR CustomersARAPAccountingByDocuments.Recorder REFS Document.SaleAdjustment
			|							OR CustomersARAPAccountingByDocuments.Recorder REFS Document.CustomerInvoice
			|							OR CustomersARAPAccountingByDocuments.Recorder REFS Document.CustomerInvoiceServicesAndAssets))
			|			AND CustomersARAPAccountingByDocuments.Active
			|		
			|		GROUP BY
			|			CustomersARAPAccountingByDocuments.ARAPDocument,
			|			CustomersARAPAccountingByDocuments.SalesOrder.Manager,
			|			CustomersARAPAccountingByDocuments.Currency
			|		
			|		HAVING
			|			SUM(CASE
			|					WHEN CustomersARAPAccountingByDocuments.RecordType = VALUE(AccumulationRecordType.Expense)
			|						THEN CustomersARAPAccountingByDocuments.Prepayment
			|					ELSE -CustomersARAPAccountingByDocuments.Prepayment
			|				END) > 0) AS NestedQuery
			|	
			|	GROUP BY
			|		NestedQuery.CustomerOrderManager,
			|		NestedQuery.Currency) AS NestedQuery
			|
			|GROUP BY
			|	NestedQuery.Manager,
			|	NestedQuery.Currency
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			|SELECT
			|	CurPeriodReceiptOfCashCurrency.Manager,
			|	SUM(CASE
			|			WHEN CurPeriodReceiptOfCashCurrency.Currency = &ManagementAccountingCurrency
			|				THEN CurPeriodReceiptOfCashCurrency.ReceiptOfCash
			|			ELSE CASE
			|					WHEN ISNULL(ExchangeRateOfManagementAccounting_.WeightedAverageExchangeRate, 0) = 0
			|						THEN 0
			|					ELSE CurPeriodReceiptOfCashCurrency.ReceiptOfCash * ISNULL(OtherCurrencyRates.WeightedAverageExchangeRate, 0) / ISNULL(ExchangeRateOfManagementAccounting_.WeightedAverageExchangeRate, 0)
			|				END
			|		END) AS ReceiptOfCash
			|FROM
			|	CurPeriodReceiptOfCashCurrency AS CurPeriodReceiptOfCashCurrency
			|		LEFT JOIN WeightedAverageExchangeRatesForCurPeriod AS OtherCurrencyRates
			|		ON CurPeriodReceiptOfCashCurrency.Currency = OtherCurrencyRates.Currency
			|		LEFT JOIN WeightedAverageExchangeRatesForCurPeriod AS ExchangeRateOfManagementAccounting_
			|		ON (&ManagementAccountingCurrency = ExchangeRateOfManagementAccounting_.Currency)
			|
			|GROUP BY
			|	CurPeriodReceiptOfCashCurrency.Manager
			|
			|ORDER BY
			|	ReceiptOfCash DESC
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			|";
			
		EndIf;
		
	EndIf;
	
EndFunction

Function TextOfRequestForReceiptOfDS_MinusCost(MatchingRequestsData,LastPacketNumber, StructureOfReportGenerationPeriods)
	
	If GetFunctionalOption("NewOnlineARAPAccounting") Then
		
		If StructureOfReportGenerationPeriods.ThereIsExtraPeriod Then
			
			LastPacketNumber = LastPacketNumber + 3;
			MatchingRequestsData.Insert("ReceiptOfDS_MinusCost",LastPacketNumber);
			
			Return "
			|SELECT ALLOWED
			|	ISNULL(NestedQuery.Manager, &NotSpecified) AS Manager,
			|	SUM(NestedQuery.Factor)             AS Factor
			|INTO CurPeriodReceiptOfDS_MinusCostOfSales
			|FROM
			|(SELECT 
			|	CustomersARAPAccountingByDueDates.ARAPObject.Manager                           AS Manager,
			|	CustomersARAPAccountingByDueDates.PrepaymentMan + CustomersARAPAccountingByDueDates.ARAPMan AS Factor
			|FROM
			|	AccumulationRegister.CustomersARAPAccountingByDueDates AS CustomersARAPAccountingByDueDates
			|WHERE
			|	(CustomersARAPAccountingByDueDates.RecordType = VALUE(AccumulationRecordType.Expense)
			|			AND CustomersARAPAccountingByDueDates.ARAPMan > 0 
			|		OR CustomersARAPAccountingByDueDates.RecordType = VALUE(AccumulationRecordType.Receipt)
			|			AND CustomersARAPAccountingByDueDates.PrepaymentMan > 0)
			|	AND CustomersARAPAccountingByDueDates.ARAPObject IN (SELECT ARAPObject FROM ObjectsOfManagersCalculations)
			|	AND (CustomersARAPAccountingByDueDates.DocumentRecorder REFS Document.CashVoucher
			|			OR CustomersARAPAccountingByDueDates.DocumentRecorder REFS Document.PaymentCardTransaction
			|			OR CustomersARAPAccountingByDueDates.DocumentRecorder REFS Document.BankAccountReceiptNote
			|			OR CustomersARAPAccountingByDueDates.DocumentRecorder REFS Document.CashAccountReceiptNote
			|			OR CustomersARAPAccountingByDueDates.DocumentRecorder REFS Document.BankAccountIssue
			|			OR CustomersARAPAccountingByDueDates.DocumentRecorder REFS Document.ARAPAdjustment)
			|	AND CustomersARAPAccountingByDueDates.Period BETWEEN &BeginOfPeriod AND &PeriodEnding
			|	AND CustomersARAPAccountingByDueDates.ARAPObject.Partner <> VALUE(Catalog.Partners.RetailCustomer)
			|	AND CustomersARAPAccountingByDueDates.Active
			|
			|	UNION ALL
			|	
			|	SELECT
			|		RevenueAndCostOfSalesTurnover.SalesOrder.Manager,
			|		-RevenueAndCostOfSalesTurnover.CostTurnover
			|	FROM
			|		AccumulationRegister.RevenueAndCOGS.Turnovers(&BeginOfPeriod, &PeriodEnding, , AccountingDimensionByPartners.Partner <> VALUE(Catalog.Partners.RetailCustomer) AND SalesOrder.Manager IN (SELECT FilterByManagers.Ref FROM FilterByManagers AS FilterByManagers)) AS RevenueAndCostOfSalesTurnover) AS NestedQuery
			|
			|GROUP BY
			|	ISNULL(NestedQuery.Manager, &NotSpecified)
			|
			|;
			|////////////////////////////////////////////////////////////////////////////////
			|
			|SELECT ALLOWED
			|	ISNULL(NestedQuery.Manager, &NotSpecified) AS Manager,
			|	SUM(NestedQuery.Factor)             AS Factor
			|INTO PreviousPeriodReceiptOfDS_MinusCostOfSales
			|FROM
			|(SELECT 
			|	CustomersARAPAccountingByDueDates.ARAPObject.Manager                           AS Manager,
			|	CustomersARAPAccountingByDueDates.PrepaymentMan + CustomersARAPAccountingByDueDates.ARAPMan AS Factor
			|FROM
			|	AccumulationRegister.CustomersARAPAccountingByDueDates AS CustomersARAPAccountingByDueDates
			|WHERE
			|	(CustomersARAPAccountingByDueDates.RecordType = VALUE(AccumulationRecordType.Expense)
			|			AND CustomersARAPAccountingByDueDates.ARAPMan > 0 
			|		OR CustomersARAPAccountingByDueDates.RecordType = VALUE(AccumulationRecordType.Receipt)
			|			AND CustomersARAPAccountingByDueDates.PrepaymentMan > 0)
			|	AND CustomersARAPAccountingByDueDates.ARAPObject IN (SELECT ARAPObject FROM ObjectsOfManagersCalculations)
			|	AND (CustomersARAPAccountingByDueDates.DocumentRecorder REFS Document.CashVoucher
			|			OR CustomersARAPAccountingByDueDates.DocumentRecorder REFS Document.PaymentCardTransaction
			|			OR CustomersARAPAccountingByDueDates.DocumentRecorder REFS Document.BankAccountReceiptNote
			|			OR CustomersARAPAccountingByDueDates.DocumentRecorder REFS Document.CashAccountReceiptNote
			|			OR CustomersARAPAccountingByDueDates.DocumentRecorder REFS Document.BankAccountIssue
			|			OR CustomersARAPAccountingByDueDates.DocumentRecorder REFS Document.ARAPAdjustment)
			|	AND CustomersARAPAccountingByDueDates.Period BETWEEN &StartDateAdditionalPeriod AND &EndDateAdditionalPeriod
			|	AND CustomersARAPAccountingByDueDates.ARAPObject.Partner <> VALUE(Catalog.Partners.RetailCustomer)
			|	AND CustomersARAPAccountingByDueDates.Active
			|
			|	UNION ALL
			|	
			|	SELECT
			|		RevenueAndCostOfSalesTurnover.SalesOrder.Manager,
			|		-RevenueAndCostOfSalesTurnover.CostTurnover
			|	FROM
			|		AccumulationRegister.RevenueAndCOGS.Turnovers(&StartDateAdditionalPeriod, &EndDateAdditionalPeriod, , AccountingDimensionByPartners.Partner <> VALUE(Catalog.Partners.RetailCustomer) AND SalesOrder.Manager IN (SELECT FilterByManagers.Ref FROM FilterByManagers AS FilterByManagers)) AS RevenueAndCostOfSalesTurnover) AS NestedQuery
			|
			|GROUP BY
			|	ISNULL(NestedQuery.Manager, &NotSpecified)
			|
			|;
			|////////////////////////////////////////////////////////////////////////////////
			|
			|SELECT
			|	ISNULL(NestedQuery.Manager, &NotSpecified) AS Manager,
			|	NestedQuery.Current_,
			|	NestedQuery.Previous,
			|	CASE
			|		WHEN NestedQuery.Current_ - NestedQuery.Previous > 0
			|			THEN NestedQuery.Current_ - NestedQuery.Previous
			|		ELSE 0
			|	END AS Growth,
			|	CASE
			|		WHEN NestedQuery.Current_ - NestedQuery.Previous < 0
			|			THEN NestedQuery.Current_ - NestedQuery.Previous
			|		ELSE 0
			|	END AS Slippage
			|FROM
			|	(SELECT
			|		CASE
			|			WHEN PreviousPeriod_.Manager IS NULL 
			|				THEN CurrentPeriod.Manager
			|			ELSE PreviousPeriod_.Manager
			|		END AS Manager,
			|		SUM(ISNULL(PreviousPeriod_.Factor, 0)) AS Previous,
			|		SUM(ISNULL(CurrentPeriod.Factor, 0)) AS Current_
			|	FROM
			|		PreviousPeriodReceiptOfDS_MinusCostOfSales AS PreviousPeriod_
			|			FULL JOIN CurPeriodReceiptOfDS_MinusCostOfSales AS CurrentPeriod
			|			ON PreviousPeriod_.Manager = CurrentPeriod.Manager
			|	
			|	GROUP BY
			|		CASE
			|			WHEN PreviousPeriod_.Manager IS NULL 
			|				THEN CurrentPeriod.Manager
			|			ELSE PreviousPeriod_.Manager
			|		END) AS NestedQuery
			|
			|ORDER BY
			|	NestedQuery.Current_
			|;
			|////////////////////////////////////////////////////////////////////////////////
			|";
			
		Else
			
			LastPacketNumber = LastPacketNumber + 1;
			MatchingRequestsData.Insert("ReceiptOfDS_MinusCost",LastPacketNumber);
			
			Return "
			|SELECT ALLOWED
			|	ISNULL(NestedQuery.Manager, &NotSpecified) AS Manager,
			|	SUM(NestedQuery.Factor) AS ReceiptOfDS_MinusCost
			|FROM
			|(SELECT 
			|	CustomersARAPAccountingByDueDates.ARAPObject.Manager                           AS Manager,
			|	CustomersARAPAccountingByDueDates.PrepaymentMan + CustomersARAPAccountingByDueDates.ARAPMan AS Factor
			|FROM
			|	AccumulationRegister.CustomersARAPAccountingByDueDates AS CustomersARAPAccountingByDueDates
			|WHERE
			|	(CustomersARAPAccountingByDueDates.RecordType = VALUE(AccumulationRecordType.Expense)
			|			AND CustomersARAPAccountingByDueDates.ARAPMan > 0 
			|		OR CustomersARAPAccountingByDueDates.RecordType = VALUE(AccumulationRecordType.Receipt)
			|			AND CustomersARAPAccountingByDueDates.PrepaymentMan > 0)
			|	AND CustomersARAPAccountingByDueDates.ARAPObject IN (SELECT ARAPObject FROM ObjectsOfManagersCalculations)
			|	AND (CustomersARAPAccountingByDueDates.DocumentRecorder REFS Document.CashVoucher
			|			OR CustomersARAPAccountingByDueDates.DocumentRecorder REFS Document.PaymentCardTransaction
			|			OR CustomersARAPAccountingByDueDates.DocumentRecorder REFS Document.BankAccountReceiptNote
			|			OR CustomersARAPAccountingByDueDates.DocumentRecorder REFS Document.CashAccountReceiptNote
			|			OR CustomersARAPAccountingByDueDates.DocumentRecorder REFS Document.BankAccountIssue
			|			OR CustomersARAPAccountingByDueDates.DocumentRecorder REFS Document.ARAPAdjustment)
			|	AND CustomersARAPAccountingByDueDates.Period BETWEEN &BeginOfPeriod AND &PeriodEnding
			|	AND CustomersARAPAccountingByDueDates.ARAPObject.Partner <> VALUE(Catalog.Partners.RetailCustomer)
			|	AND CustomersARAPAccountingByDueDates.Active
			|
			|	UNION ALL
			|	
			|	SELECT
			|		RevenueAndCostOfSalesTurnover.SalesOrder.Manager,
			|		-RevenueAndCostOfSalesTurnover.CostTurnover
			|	FROM
			|		AccumulationRegister.RevenueAndCOGS.Turnovers(&BeginOfPeriod, &PeriodEnding, , AccountingDimensionByPartners.Partner <> VALUE(Catalog.Partners.RetailCustomer) AND SalesOrder.Manager IN (SELECT FilterByManagers.Ref FROM FilterByManagers AS FilterByManagers)) AS RevenueAndCostOfSalesTurnover) AS NestedQuery
			|
			|GROUP BY
			|	ISNULL(NestedQuery.Manager, &NotSpecified)
			|
			|ORDER BY
			|	ReceiptOfDS_MinusCost DESC
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			|";
			
		EndIf;
		
	Else
		
		If StructureOfReportGenerationPeriods.ThereIsExtraPeriod Then
			
			LastPacketNumber = LastPacketNumber + 5;
			MatchingRequestsData.Insert("ReceiptOfDS_MinusCost",LastPacketNumber);
					
			Return "
			|SELECT ALLOWED
			|	NestedQuery.Manager,
			|	NestedQuery.Currency,
			|	SUM(NestedQuery.ReceiptOfCash) AS ReceiptOfCash
			|INTO CurPeriodDs_ReceiptsMinusCostOfCurrencySales
			|FROM
			|	(SELECT
			|		CustomersARAPAccountingByDocuments.SalesOrder.Manager AS Manager,
			|		CustomersARAPAccountingByDocuments.Debt AS ReceiptOfCash,
			|		CustomersARAPAccountingByDocuments.Currency AS Currency
			|	FROM
			|		AccumulationRegister.CustomersARAPAccountingByDocuments AS CustomersARAPAccountingByDocuments
			|	WHERE
			|		CustomersARAPAccountingByDocuments.RecordType = VALUE(AccumulationRecordType.Expense)
			|		AND CustomersARAPAccountingByDocuments.SalesOrder.Manager IN
			|				(SELECT
			|					FilterByManagers.Ref
			|				FROM
			|					FilterByManagers AS FilterByManagers)
			|		AND CustomersARAPAccountingByDocuments.Debt <> 0
			|		AND (CustomersARAPAccountingByDocuments.Recorder REFS Document.CashVoucher
			|				OR CustomersARAPAccountingByDocuments.Recorder REFS Document.PaymentCardTransaction
			|				OR CustomersARAPAccountingByDocuments.Recorder REFS Document.BankAccountReceiptNote
			|				OR CustomersARAPAccountingByDocuments.Recorder REFS Document.CashAccountReceiptNote
			|				OR CustomersARAPAccountingByDocuments.Recorder REFS Document.CashVoucher
			|				OR CustomersARAPAccountingByDocuments.Recorder REFS Document.BankAccountIssue
			|				OR CustomersARAPAccountingByDocuments.Recorder REFS Document.ARAPAdjustment)
			|		AND CustomersARAPAccountingByDocuments.Period BETWEEN &BeginOfPeriod AND &PeriodEnding
			|		AND CustomersARAPAccountingByDocuments.SalesOrder.Partner <> VALUE(Catalog.Partners.RetailCustomer)
			|		AND CustomersARAPAccountingByDocuments.Active
			|	
			|	UNION ALL
			|	
			|	SELECT
			|		CustomersARAPAccountingByDocuments.SalesOrder.Manager,
			|		CustomersARAPAccountingByDocuments.Prepayment,
			|		CustomersARAPAccountingByDocuments.Currency
			|	FROM
			|		AccumulationRegister.CustomersARAPAccountingByDocuments AS CustomersARAPAccountingByDocuments
			|	WHERE
			|		CustomersARAPAccountingByDocuments.RecordType = VALUE(AccumulationRecordType.Receipt)
			|		AND CustomersARAPAccountingByDocuments.Prepayment <> 0
			|		AND CustomersARAPAccountingByDocuments.SalesOrder.Manager IN
			|				(SELECT
			|					FilterByManagers.Ref
			|				FROM
			|					FilterByManagers AS FilterByManagers)
			|		AND (CustomersARAPAccountingByDocuments.Recorder REFS Document.CustomerInvoiceServices
			|				OR CustomersARAPAccountingByDocuments.Recorder REFS Document.SalesOrder
			|				OR CustomersARAPAccountingByDocuments.Recorder REFS Document.SaleAdjustment
			|				OR CustomersARAPAccountingByDocuments.Recorder REFS Document.CustomerInvoice
			|				OR CustomersARAPAccountingByDocuments.Recorder REFS Document.CustomerInvoiceServicesAndAssets)
			|		AND CustomersARAPAccountingByDocuments.Period BETWEEN &BeginOfPeriod AND &PeriodEnding
			|		AND CustomersARAPAccountingByDocuments.SalesOrder.Partner <> VALUE(Catalog.Partners.RetailCustomer)
			|		AND CustomersARAPAccountingByDocuments.Active
			|	
			|	UNION ALL
			|	
			|	SELECT
			|		NestedQuery.CustomerOrderManager,
			|		SUM(NestedQuery.Prepayment),
			|		NestedQuery.Currency
			|	FROM
			|		(SELECT
			|			SUM(CASE
			|					WHEN CustomersARAPAccountingByDocuments.RecordType = VALUE(AccumulationRecordType.Expense)
			|						THEN CustomersARAPAccountingByDocuments.Prepayment
			|					ELSE -CustomersARAPAccountingByDocuments.Prepayment
			|				END) AS Prepayment,
			|			CustomersARAPAccountingByDocuments.SalesOrder.Manager AS CustomerOrderManager,
			|			CustomersARAPAccountingByDocuments.Currency AS Currency,
			|			CustomersARAPAccountingByDocuments.ARAPDocument AS ARAPDocument
			|		FROM
			|			AccumulationRegister.CustomersARAPAccountingByDocuments AS CustomersARAPAccountingByDocuments
			|		WHERE
			|			CustomersARAPAccountingByDocuments.SalesOrder.Manager IN
			|				(SELECT
			|					FilterByManagers.Ref
			|				FROM
			|					FilterByManagers AS FilterByManagers)
			|			AND CustomersARAPAccountingByDocuments.Period BETWEEN &BeginOfPeriod AND &PeriodEnding
			|			AND CustomersARAPAccountingByDocuments.Prepayment <> 0
			|			AND CustomersARAPAccountingByDocuments.SalesOrder.Partner <> VALUE(Catalog.Partners.RetailCustomer)
			|			AND (CustomersARAPAccountingByDocuments.RecordType = VALUE(AccumulationRecordType.Expense)
			|						AND (CustomersARAPAccountingByDocuments.Recorder REFS Document.CashVoucher
			|							OR CustomersARAPAccountingByDocuments.Recorder REFS Document.PaymentCardTransaction
			|							OR CustomersARAPAccountingByDocuments.Recorder REFS Document.BankAccountReceiptNote
			|							OR CustomersARAPAccountingByDocuments.Recorder REFS Document.CashAccountReceiptNote
			|							OR CustomersARAPAccountingByDocuments.Recorder REFS Document.CashVoucher
			|							OR CustomersARAPAccountingByDocuments.Recorder REFS Document.BankAccountIssue
			|							OR CustomersARAPAccountingByDocuments.Recorder REFS Document.ARAPAdjustment)
			|					OR CustomersARAPAccountingByDocuments.RecordType = VALUE(AccumulationRecordType.Receipt)
			|						AND (CustomersARAPAccountingByDocuments.Recorder REFS Document.CustomerInvoiceServices
			|							OR CustomersARAPAccountingByDocuments.Recorder REFS Document.SalesOrder
			|							OR CustomersARAPAccountingByDocuments.Recorder REFS Document.SaleAdjustment
			|							OR CustomersARAPAccountingByDocuments.Recorder REFS Document.CustomerInvoice
			|							OR CustomersARAPAccountingByDocuments.Recorder REFS Document.CustomerInvoiceServicesAndAssets))
			|			AND CustomersARAPAccountingByDocuments.Active
			|		
			|		GROUP BY
			|			CustomersARAPAccountingByDocuments.ARAPDocument,
			|			CustomersARAPAccountingByDocuments.SalesOrder.Manager,
			|			CustomersARAPAccountingByDocuments.Currency
			|		
			|		HAVING
			|			SUM(CASE
			|					WHEN CustomersARAPAccountingByDocuments.RecordType = VALUE(AccumulationRecordType.Expense)
			|						THEN CustomersARAPAccountingByDocuments.Prepayment
			|					ELSE -CustomersARAPAccountingByDocuments.Prepayment
			|				END) > 0) AS NestedQuery
			|	
			|	GROUP BY
			|		NestedQuery.CustomerOrderManager,
			|		NestedQuery.Currency) AS NestedQuery
			|
			|GROUP BY
			|	NestedQuery.Manager,
			|	NestedQuery.Currency
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			|
			|SELECT
			|	ISNULL(NestedQuery.Manager, &NotSpecified) AS Manager,
			|	SUM(NestedQuery.Factor) AS Factor
			|INTO CurPeriodReceiptOfDS_MinusCostOfSales
			|FROM
			|	(SELECT
			|		CurPeriodDs_ReceiptsMinusCostOfCurrencySales.Manager,
			|		CASE
			|			WHEN CurPeriodDs_ReceiptsMinusCostOfCurrencySales.Currency = &ManagementAccountingCurrency
			|				THEN CurPeriodDs_ReceiptsMinusCostOfCurrencySales.ReceiptOfCash
			|			ELSE CASE
			|					WHEN ISNULL(ExchangeRateOfManagementAccounting_.WeightedAverageExchangeRate, 0) = 0
			|						THEN 0
			|					ELSE CurPeriodDs_ReceiptsMinusCostOfCurrencySales.ReceiptOfCash * ISNULL(OtherCurrencyRates.WeightedAverageExchangeRate, 0) / ISNULL(ExchangeRateOfManagementAccounting_.WeightedAverageExchangeRate, 0)
			|				END
			|		END AS Factor
			|	FROM
			|		CurPeriodDs_ReceiptsMinusCostOfCurrencySales AS CurPeriodDs_ReceiptsMinusCostOfCurrencySales
			|			LEFT JOIN WeightedAverageExchangeRatesForCurPeriod AS OtherCurrencyRates
			|			ON CurPeriodDs_ReceiptsMinusCostOfCurrencySales.Currency = OtherCurrencyRates.Currency
			|			LEFT JOIN WeightedAverageExchangeRatesForCurPeriod AS ExchangeRateOfManagementAccounting_
			|			ON (&ManagementAccountingCurrency = ExchangeRateOfManagementAccounting_.Currency)
			|
			|	UNION ALL
			|	
			|	SELECT
			|		RevenueAndCostOfSalesTurnover.SalesOrder.Manager,
			|		-RevenueAndCostOfSalesTurnover.CostTurnover
			|	FROM
			|		AccumulationRegister.RevenueAndCOGS.Turnovers(&BeginOfPeriod, &PeriodEnding, , AccountingDimensionByPartners.Partner <> VALUE(Catalog.Partners.RetailCustomer) AND SalesOrder.Manager IN (SELECT FilterByManagers.Ref FROM FilterByManagers AS FilterByManagers)) AS RevenueAndCostOfSalesTurnover) AS NestedQuery
			|
			|GROUP BY
			|	ISNULL(NestedQuery.Manager, &NotSpecified)
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			|
			|SELECT ALLOWED
			|	NestedQuery.Manager,
			|	NestedQuery.Currency,
			|	SUM(NestedQuery.ReceiptOfCash) AS ReceiptOfCash
			|INTO PreviousPeriodReceiptOfDS_MinusCostOfSalesOfCurrency
			|FROM
			|	(SELECT
			|		CustomersARAPAccountingByDocuments.SalesOrder.Manager AS Manager,
			|		CustomersARAPAccountingByDocuments.Debt AS ReceiptOfCash,
			|		CustomersARAPAccountingByDocuments.Currency AS Currency
			|	FROM
			|		AccumulationRegister.CustomersARAPAccountingByDocuments AS CustomersARAPAccountingByDocuments
			|	WHERE
			|		CustomersARAPAccountingByDocuments.RecordType = VALUE(AccumulationRecordType.Expense)
			|		AND CustomersARAPAccountingByDocuments.SalesOrder.Manager IN
			|				(SELECT
			|					FilterByManagers.Ref
			|				FROM
			|					FilterByManagers AS FilterByManagers)
			|		AND CustomersARAPAccountingByDocuments.Debt <> 0
			|		AND (CustomersARAPAccountingByDocuments.Recorder REFS Document.CashVoucher
			|				OR CustomersARAPAccountingByDocuments.Recorder REFS Document.PaymentCardTransaction
			|				OR CustomersARAPAccountingByDocuments.Recorder REFS Document.BankAccountReceiptNote
			|				OR CustomersARAPAccountingByDocuments.Recorder REFS Document.CashAccountReceiptNote
			|				OR CustomersARAPAccountingByDocuments.Recorder REFS Document.CashVoucher
			|				OR CustomersARAPAccountingByDocuments.Recorder REFS Document.BankAccountIssue
			|				OR CustomersARAPAccountingByDocuments.Recorder REFS Document.ARAPAdjustment)
			|		AND CustomersARAPAccountingByDocuments.Period BETWEEN &StartDateAdditionalPeriod AND &EndDateAdditionalPeriod
			|		AND CustomersARAPAccountingByDocuments.SalesOrder.Partner <> VALUE(Catalog.Partners.RetailCustomer)
			|		AND CustomersARAPAccountingByDocuments.Active
			|	
			|	UNION ALL
			|	
			|	SELECT
			|		CustomersARAPAccountingByDocuments.SalesOrder.Manager,
			|		CustomersARAPAccountingByDocuments.Prepayment,
			|		CustomersARAPAccountingByDocuments.Currency
			|	FROM
			|		AccumulationRegister.CustomersARAPAccountingByDocuments AS CustomersARAPAccountingByDocuments
			|	WHERE
			|		CustomersARAPAccountingByDocuments.RecordType = VALUE(AccumulationRecordType.Receipt)
			|		AND CustomersARAPAccountingByDocuments.Prepayment <> 0
			|		AND CustomersARAPAccountingByDocuments.SalesOrder.Manager IN
			|				(SELECT
			|					FilterByManagers.Ref
			|				FROM
			|					FilterByManagers AS FilterByManagers)
			|		AND (CustomersARAPAccountingByDocuments.Recorder REFS Document.CustomerInvoiceServices
			|				OR CustomersARAPAccountingByDocuments.Recorder REFS Document.SalesOrder
			|				OR CustomersARAPAccountingByDocuments.Recorder REFS Document.SaleAdjustment
			|				OR CustomersARAPAccountingByDocuments.Recorder REFS Document.CustomerInvoice
			|				OR CustomersARAPAccountingByDocuments.Recorder REFS Document.CustomerInvoiceServicesAndAssets)
			|		AND CustomersARAPAccountingByDocuments.Period BETWEEN &StartDateAdditionalPeriod AND &EndDateAdditionalPeriod
			|		AND CustomersARAPAccountingByDocuments.SalesOrder.Partner <> VALUE(Catalog.Partners.RetailCustomer)
			|		AND CustomersARAPAccountingByDocuments.Active
			|	
			|	UNION ALL
			|	
			|	SELECT
			|		NestedQuery.CustomerOrderManager,
			|		SUM(NestedQuery.Prepayment),
			|		NestedQuery.Currency
			|	FROM
			|		(SELECT
			|			SUM(CASE
			|					WHEN CustomersARAPAccountingByDocuments.RecordType = VALUE(AccumulationRecordType.Expense)
			|						THEN CustomersARAPAccountingByDocuments.Prepayment
			|					ELSE -CustomersARAPAccountingByDocuments.Prepayment
			|				END) AS Prepayment,
			|			CustomersARAPAccountingByDocuments.SalesOrder.Manager AS CustomerOrderManager,
			|			CustomersARAPAccountingByDocuments.Currency AS Currency,
			|			CustomersARAPAccountingByDocuments.ARAPDocument AS ARAPDocument
			|		FROM
			|			AccumulationRegister.CustomersARAPAccountingByDocuments AS CustomersARAPAccountingByDocuments
			|		WHERE
			|			CustomersARAPAccountingByDocuments.SalesOrder.Manager IN
			|				(SELECT
			|					FilterByManagers.Ref
			|				FROM
			|					FilterByManagers AS FilterByManagers)
			|			AND CustomersARAPAccountingByDocuments.Period BETWEEN &StartDateAdditionalPeriod AND &EndDateAdditionalPeriod
			|			AND CustomersARAPAccountingByDocuments.Prepayment <> 0
			|			AND CustomersARAPAccountingByDocuments.SalesOrder.Partner <> VALUE(Catalog.Partners.RetailCustomer)
			|			AND (CustomersARAPAccountingByDocuments.RecordType = VALUE(AccumulationRecordType.Expense)
			|						AND (CustomersARAPAccountingByDocuments.Recorder REFS Document.CashVoucher
			|							OR CustomersARAPAccountingByDocuments.Recorder REFS Document.PaymentCardTransaction
			|							OR CustomersARAPAccountingByDocuments.Recorder REFS Document.BankAccountReceiptNote
			|							OR CustomersARAPAccountingByDocuments.Recorder REFS Document.CashAccountReceiptNote
			|							OR CustomersARAPAccountingByDocuments.Recorder REFS Document.CashVoucher
			|							OR CustomersARAPAccountingByDocuments.Recorder REFS Document.BankAccountIssue
			|							OR CustomersARAPAccountingByDocuments.Recorder REFS Document.ARAPAdjustment)
			|					OR CustomersARAPAccountingByDocuments.RecordType = VALUE(AccumulationRecordType.Receipt)
			|						AND (CustomersARAPAccountingByDocuments.Recorder REFS Document.CustomerInvoiceServices
			|							OR CustomersARAPAccountingByDocuments.Recorder REFS Document.SalesOrder
			|							OR CustomersARAPAccountingByDocuments.Recorder REFS Document.SaleAdjustment
			|							OR CustomersARAPAccountingByDocuments.Recorder REFS Document.CustomerInvoice
			|							OR CustomersARAPAccountingByDocuments.Recorder REFS Document.CustomerInvoiceServicesAndAssets))
			|			AND CustomersARAPAccountingByDocuments.Active
			|		
			|		GROUP BY
			|			CustomersARAPAccountingByDocuments.ARAPDocument,
			|			CustomersARAPAccountingByDocuments.SalesOrder.Manager,
			|			CustomersARAPAccountingByDocuments.Currency
			|		
			|		HAVING
			|			SUM(CASE
			|					WHEN CustomersARAPAccountingByDocuments.RecordType = VALUE(AccumulationRecordType.Expense)
			|						THEN CustomersARAPAccountingByDocuments.Prepayment
			|					ELSE -CustomersARAPAccountingByDocuments.Prepayment
			|				END) > 0) AS NestedQuery
			|	
			|	GROUP BY
			|		NestedQuery.CustomerOrderManager,
			|		NestedQuery.Currency) AS NestedQuery
			|
			|GROUP BY
			|	NestedQuery.Manager,
			|	NestedQuery.Currency
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			|
			|SELECT
			|	ISNULL(NestedQuery.Manager, &NotSpecified) AS Manager,
			|	SUM(NestedQuery.Factor) AS Factor
			|INTO PreviousPeriodReceiptOfDS_MinusCostOfSales
			|FROM
			|	(SELECT
			|		PreviousPeriodReceiptOfDS_MinusCostOfSalesOfCurrency.Manager,
			|		CASE
			|			WHEN PreviousPeriodReceiptOfDS_MinusCostOfSalesOfCurrency.Currency = &ManagementAccountingCurrency
			|				THEN PreviousPeriodReceiptOfDS_MinusCostOfSalesOfCurrency.ReceiptOfCash
			|			ELSE CASE
			|					WHEN ISNULL(ExchangeRateOfManagementAccounting_.WeightedAverageExchangeRate, 0) = 0
			|						THEN 0
			|					ELSE PreviousPeriodReceiptOfDS_MinusCostOfSalesOfCurrency.ReceiptOfCash * ISNULL(OtherCurrencyRates.WeightedAverageExchangeRate, 0) / ISNULL(ExchangeRateOfManagementAccounting_.WeightedAverageExchangeRate, 0)
			|				END
			|		END AS Factor
			|	FROM
			|		PreviousPeriodReceiptOfDS_MinusCostOfSalesOfCurrency AS PreviousPeriodReceiptOfDS_MinusCostOfSalesOfCurrency
			|			LEFT JOIN WeightedAverageExchangeRatesForCurPeriod AS OtherCurrencyRates
			|			ON PreviousPeriodReceiptOfDS_MinusCostOfSalesOfCurrency.Currency = OtherCurrencyRates.Currency
			|			LEFT JOIN WeightedAverageExchangeRatesForCurPeriod AS ExchangeRateOfManagementAccounting_
			|			ON (&ManagementAccountingCurrency = ExchangeRateOfManagementAccounting_.Currency)
			|
			|	UNION ALL
			|	
			|	SELECT
			|		RevenueAndCostOfSalesTurnover.SalesOrder.Manager,
			|		-RevenueAndCostOfSalesTurnover.CostTurnover
			|	FROM
			|		AccumulationRegister.RevenueAndCOGS.Turnovers(&StartDateAdditionalPeriod, &EndDateAdditionalPeriod, , AccountingDimensionByPartners.Partner <> VALUE(Catalog.Partners.RetailCustomer) AND SalesOrder.Manager IN (SELECT FilterByManagers.Ref FROM FilterByManagers AS FilterByManagers)) AS RevenueAndCostOfSalesTurnover) AS NestedQuery
			|
			|GROUP BY
			|	ISNULL(NestedQuery.Manager, &NotSpecified)
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			|
			|SELECT
			|	ISNULL(NestedQuery.Manager, &NotSpecified) AS Manager,
			|	NestedQuery.Current_,
			|	NestedQuery.Previous,
			|	CASE
			|		WHEN NestedQuery.Current_ - NestedQuery.Previous > 0
			|			THEN NestedQuery.Current_ - NestedQuery.Previous
			|		ELSE 0
			|	END AS Growth,
			|	CASE
			|		WHEN NestedQuery.Current_ - NestedQuery.Previous < 0
			|			THEN NestedQuery.Current_ - NestedQuery.Previous
			|		ELSE 0
			|	END AS Slippage
			|FROM
			|	(SELECT
			|		CASE
			|			WHEN PreviousPeriod_.Manager IS NULL 
			|				THEN CurrentPeriod.Manager
			|			ELSE PreviousPeriod_.Manager
			|		END AS Manager,
			|		SUM(ISNULL(PreviousPeriod_.Factor, 0)) AS Previous,
			|		SUM(ISNULL(CurrentPeriod.Factor, 0)) AS Current_
			|	FROM
			|		PreviousPeriodReceiptOfDS_MinusCostOfSales AS PreviousPeriod_
			|			FULL JOIN CurPeriodReceiptOfDS_MinusCostOfSales AS CurrentPeriod
			|			ON PreviousPeriod_.Manager = CurrentPeriod.Manager
			|	
			|	GROUP BY
			|		CASE
			|			WHEN PreviousPeriod_.Manager IS NULL 
			|				THEN CurrentPeriod.Manager
			|			ELSE PreviousPeriod_.Manager
			|		END) AS NestedQuery
			|
			|ORDER BY
			|	NestedQuery.Current_
			|;
			|////////////////////////////////////////////////////////////////////////////////
			|";
			
		Else
			
			LastPacketNumber = LastPacketNumber + 2;
			MatchingRequestsData.Insert("ReceiptOfDS_MinusCost",LastPacketNumber);
			
			Return "
			|SELECT ALLOWED
			|	NestedQuery.Manager,
			|	NestedQuery.Currency,
			|	SUM(NestedQuery.ReceiptOfCash) AS ReceiptOfCash
			|INTO CurPeriodDs_ReceiptsMinusCostOfCurrencySales
			|FROM
			|	(SELECT
			|		CustomersARAPAccountingByDocuments.SalesOrder.Manager AS Manager,
			|		CustomersARAPAccountingByDocuments.Debt AS ReceiptOfCash,
			|		CustomersARAPAccountingByDocuments.Currency AS Currency
			|	FROM
			|		AccumulationRegister.CustomersARAPAccountingByDocuments AS CustomersARAPAccountingByDocuments
			|	WHERE
			|		CustomersARAPAccountingByDocuments.RecordType = VALUE(AccumulationRecordType.Expense)
			|		AND CustomersARAPAccountingByDocuments.SalesOrder.Manager IN
			|				(SELECT
			|					FilterByManagers.Ref
			|				FROM
			|					FilterByManagers AS FilterByManagers)
			|		AND CustomersARAPAccountingByDocuments.Debt <> 0
			|		AND (CustomersARAPAccountingByDocuments.Recorder REFS Document.CashVoucher
			|				OR CustomersARAPAccountingByDocuments.Recorder REFS Document.PaymentCardTransaction
			|				OR CustomersARAPAccountingByDocuments.Recorder REFS Document.BankAccountReceiptNote
			|				OR CustomersARAPAccountingByDocuments.Recorder REFS Document.CashAccountReceiptNote
			|				OR CustomersARAPAccountingByDocuments.Recorder REFS Document.CashVoucher
			|				OR CustomersARAPAccountingByDocuments.Recorder REFS Document.BankAccountIssue
			|				OR CustomersARAPAccountingByDocuments.Recorder REFS Document.ARAPAdjustment)
			|		AND CustomersARAPAccountingByDocuments.Period BETWEEN &BeginOfPeriod AND &PeriodEnding
			|		AND CustomersARAPAccountingByDocuments.SalesOrder.Partner <> VALUE(Catalog.Partners.RetailCustomer)
			|		AND CustomersARAPAccountingByDocuments.Active
			|	
			|	UNION ALL
			|	
			|	SELECT
			|		CustomersARAPAccountingByDocuments.SalesOrder.Manager,
			|		CustomersARAPAccountingByDocuments.Prepayment,
			|		CustomersARAPAccountingByDocuments.Currency
			|	FROM
			|		AccumulationRegister.CustomersARAPAccountingByDocuments AS CustomersARAPAccountingByDocuments
			|	WHERE
			|		CustomersARAPAccountingByDocuments.RecordType = VALUE(AccumulationRecordType.Receipt)
			|		AND CustomersARAPAccountingByDocuments.Prepayment <> 0
			|		AND CustomersARAPAccountingByDocuments.SalesOrder.Manager IN
			|				(SELECT
			|					FilterByManagers.Ref
			|				FROM
			|					FilterByManagers AS FilterByManagers)
			|		AND (CustomersARAPAccountingByDocuments.Recorder REFS Document.CustomerInvoiceServices
			|				OR CustomersARAPAccountingByDocuments.Recorder REFS Document.SalesOrder
			|				OR CustomersARAPAccountingByDocuments.Recorder REFS Document.SaleAdjustment
			|				OR CustomersARAPAccountingByDocuments.Recorder REFS Document.CustomerInvoice
			|				OR CustomersARAPAccountingByDocuments.Recorder REFS Document.CustomerInvoiceServicesAndAssets)
			|		AND CustomersARAPAccountingByDocuments.Period BETWEEN &BeginOfPeriod AND &PeriodEnding
			|		AND CustomersARAPAccountingByDocuments.SalesOrder.Partner <> VALUE(Catalog.Partners.RetailCustomer)
			|		AND CustomersARAPAccountingByDocuments.Active
			|	
			|	UNION ALL
			|	
			|	SELECT
			|		NestedQuery.CustomerOrderManager,
			|		SUM(NestedQuery.Prepayment),
			|		NestedQuery.Currency
			|	FROM
			|		(SELECT
			|			SUM(CASE
			|					WHEN CustomersARAPAccountingByDocuments.RecordType = VALUE(AccumulationRecordType.Expense)
			|						THEN CustomersARAPAccountingByDocuments.Prepayment
			|					ELSE -CustomersARAPAccountingByDocuments.Prepayment
			|				END) AS Prepayment,
			|			CustomersARAPAccountingByDocuments.SalesOrder.Manager AS CustomerOrderManager,
			|			CustomersARAPAccountingByDocuments.Currency AS Currency,
			|			CustomersARAPAccountingByDocuments.ARAPDocument AS ARAPDocument
			|		FROM
			|			AccumulationRegister.CustomersARAPAccountingByDocuments AS CustomersARAPAccountingByDocuments
			|		WHERE
			|			CustomersARAPAccountingByDocuments.SalesOrder.Manager IN
			|				(SELECT
			|					FilterByManagers.Ref
			|				FROM
			|					FilterByManagers AS FilterByManagers)
			|			AND CustomersARAPAccountingByDocuments.Period BETWEEN &BeginOfPeriod AND &PeriodEnding
			|			AND CustomersARAPAccountingByDocuments.Prepayment <> 0
			|			AND CustomersARAPAccountingByDocuments.SalesOrder.Partner <> VALUE(Catalog.Partners.RetailCustomer)
			|			AND (CustomersARAPAccountingByDocuments.RecordType = VALUE(AccumulationRecordType.Expense)
			|						AND (CustomersARAPAccountingByDocuments.Recorder REFS Document.CashVoucher
			|							OR CustomersARAPAccountingByDocuments.Recorder REFS Document.PaymentCardTransaction
			|							OR CustomersARAPAccountingByDocuments.Recorder REFS Document.BankAccountReceiptNote
			|							OR CustomersARAPAccountingByDocuments.Recorder REFS Document.CashAccountReceiptNote
			|							OR CustomersARAPAccountingByDocuments.Recorder REFS Document.CashVoucher
			|							OR CustomersARAPAccountingByDocuments.Recorder REFS Document.BankAccountIssue
			|							OR CustomersARAPAccountingByDocuments.Recorder REFS Document.ARAPAdjustment)
			|					OR CustomersARAPAccountingByDocuments.RecordType = VALUE(AccumulationRecordType.Receipt)
			|						AND (CustomersARAPAccountingByDocuments.Recorder REFS Document.CustomerInvoiceServices
			|							OR CustomersARAPAccountingByDocuments.Recorder REFS Document.SalesOrder
			|							OR CustomersARAPAccountingByDocuments.Recorder REFS Document.SaleAdjustment
			|							OR CustomersARAPAccountingByDocuments.Recorder REFS Document.CustomerInvoice
			|							OR CustomersARAPAccountingByDocuments.Recorder REFS Document.CustomerInvoiceServicesAndAssets))
			|			AND CustomersARAPAccountingByDocuments.Active
			|		
			|		GROUP BY
			|			CustomersARAPAccountingByDocuments.ARAPDocument,
			|			CustomersARAPAccountingByDocuments.SalesOrder.Manager,
			|			CustomersARAPAccountingByDocuments.Currency
			|		
			|		HAVING
			|			SUM(CASE
			|					WHEN CustomersARAPAccountingByDocuments.RecordType = VALUE(AccumulationRecordType.Expense)
			|						THEN CustomersARAPAccountingByDocuments.Prepayment
			|					ELSE -CustomersARAPAccountingByDocuments.Prepayment
			|				END) > 0) AS NestedQuery
			|	
			|	GROUP BY
			|		NestedQuery.CustomerOrderManager,
			|		NestedQuery.Currency) AS NestedQuery
			|
			|GROUP BY
			|	NestedQuery.Manager,
			|	NestedQuery.Currency
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			|
			|SELECT
			|	ISNULL(NestedQuery.Manager, &NotSpecified) AS Manager,
			|	SUM(NestedQuery.Factor) AS ReceiptOfDS_MinusCost
			|FROM
			|	(SELECT
			|		CurPeriodDs_ReceiptsMinusCostOfCurrencySales.Manager,
			|		CASE
			|			WHEN CurPeriodDs_ReceiptsMinusCostOfCurrencySales.Currency = &ManagementAccountingCurrency
			|				THEN CurPeriodDs_ReceiptsMinusCostOfCurrencySales.ReceiptOfCash
			|			ELSE CASE
			|					WHEN ISNULL(ExchangeRateOfManagementAccounting_.WeightedAverageExchangeRate, 0) = 0
			|						THEN 0
			|					ELSE CurPeriodDs_ReceiptsMinusCostOfCurrencySales.ReceiptOfCash * ISNULL(OtherCurrencyRates.WeightedAverageExchangeRate, 0) / ISNULL(ExchangeRateOfManagementAccounting_.WeightedAverageExchangeRate, 0)
			|				END
			|		END AS Factor
			|	FROM
			|		CurPeriodDs_ReceiptsMinusCostOfCurrencySales AS CurPeriodDs_ReceiptsMinusCostOfCurrencySales
			|			LEFT JOIN WeightedAverageExchangeRatesForCurPeriod AS OtherCurrencyRates
			|			ON CurPeriodDs_ReceiptsMinusCostOfCurrencySales.Currency = OtherCurrencyRates.Currency
			|			LEFT JOIN WeightedAverageExchangeRatesForCurPeriod AS ExchangeRateOfManagementAccounting_
			|			ON (&ManagementAccountingCurrency = ExchangeRateOfManagementAccounting_.Currency)
			|
			|	UNION ALL
			|	
			|	SELECT
			|		RevenueAndCostOfSalesTurnover.SalesOrder.Manager,
			|		-RevenueAndCostOfSalesTurnover.CostTurnover
			|	FROM
			|		AccumulationRegister.RevenueAndCOGS.Turnovers(&BeginOfPeriod, &PeriodEnding, , AccountingDimensionByPartners.Partner <> VALUE(Catalog.Partners.RetailCustomer) AND SalesOrder.Manager IN (SELECT FilterByManagers.Ref FROM FilterByManagers AS FilterByManagers)) AS RevenueAndCostOfSalesTurnover) AS NestedQuery
			|
			|GROUP BY
			|	ISNULL(NestedQuery.Manager, &NotSpecified)
			|
			|ORDER BY
			|	ReceiptOfDS_MinusCost DESC
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			|";
			
		EndIf;
	
	EndIf;
	
EndFunction

Function TextOfRequestForLossesAsResultOfOverdueReceivables(MatchingRequestsData,LastPacketNumber, StructureOfReportGenerationPeriods)
	
	If StructureOfReportGenerationPeriods.ThereIsExtraPeriod Then
		
		MatchingRequestsData.Insert("LossesOverdueReceivables",LastPacketNumber + 3);
		LastPacketNumber = LastPacketNumber + 3;
		
	Else
		
		MatchingRequestsData.Insert("LossesOverdueReceivables",LastPacketNumber + 1);
		LastPacketNumber = LastPacketNumber + 1;
		
	EndIf;
	
	If GetFunctionalOption("NewOnlineARAPAccounting") Then
		
		If StructureOfReportGenerationPeriods.ThereIsExtraPeriod Then
		
			Return "SELECT ALLOWED
			|	ISNULL(NestedQuery.Manager, &NotSpecified) AS Manager,
			|	SUM(NestedQuery.Factor) AS Factor
			|INTO CurPeriodLossesDueToOverdueReceivables
			|FROM
			|	(SELECT
			|		CustomersARAPAccountingByDueDates.ARAPObject.Manager AS Manager,
			|		-CustomersARAPAccountingByDueDates.ARAPMan * DATEDIFF(BEGINOFPERIOD(CustomersARAPAccountingByDueDates.PlannedRepaymentDate, DAY), CustomersARAPAccountingByDueDates.Period, DAY) * &InterestRateOfValueOfMoney / 36500 AS Factor
			|	FROM
			|		AccumulationRegister.CustomersARAPAccountingByDueDates AS CustomersARAPAccountingByDueDates
			|	WHERE
			|		CustomersARAPAccountingByDueDates.ARAPMan > 0
			|		AND CustomersARAPAccountingByDueDates.RecordType = VALUE(AccumulationRecordType.Expense)
			|		AND BEGINOFPERIOD(CustomersARAPAccountingByDueDates.Period, DAY) > CustomersARAPAccountingByDueDates.PlannedRepaymentDate
			|		AND CustomersARAPAccountingByDueDates.Period BETWEEN &BeginOfPeriod AND &PeriodEnding
			|		AND CustomersARAPAccountingByDueDates.ARAPObject IN (SELECT ARAPObject FROM ObjectsOfManagersCalculations)
			|		AND CustomersARAPAccountingByDueDates.Active
			|	
			|	UNION ALL
			|	
			|	SELECT
			|		CustomersARAPAccountingByDueDatesBalance.ARAPObject.Manager,
			|		CustomersARAPAccountingByDueDatesBalance.ARAPManBalance * DATEDIFF(BEGINOFPERIOD(CustomersARAPAccountingByDueDatesBalance.PlannedRepaymentDate, DAY), &PeriodEnding, DAY) * &InterestRateOfValueOfMoney / 36500
			|	FROM
			|		AccumulationRegister.CustomersARAPAccountingByDueDates.Balance(&PeriodEnding,
			|			ARAPObject IN (SELECT ARAPObject FROM ObjectsOfManagersCalculations)
			|			) AS CustomersARAPAccountingByDueDatesBalance
			|	WHERE
			|		CustomersARAPAccountingByDueDatesBalance.ARAPManBalance > 0
			|		AND CustomersARAPAccountingByDueDatesBalance.PlannedRepaymentDate < &PeriodEnding) AS NestedQuery
			|
			|GROUP BY
			|	ISNULL(NestedQuery.Manager, &NotSpecified)
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			|
			|SELECT ALLOWED
			|	ISNULL(NestedQuery.Manager, &NotSpecified) AS Manager,
			|	SUM(NestedQuery.Factor) AS Factor
			|INTO PreviousPeriodLossesAsResultOfOverdueReceivables
			|FROM
			|	(SELECT
			|		CustomersARAPAccountingByDueDates.ARAPObject.Manager AS Manager,
			|		-CustomersARAPAccountingByDueDates.ARAPMan * DATEDIFF(BEGINOFPERIOD(CustomersARAPAccountingByDueDates.PlannedRepaymentDate, DAY), CustomersARAPAccountingByDueDates.Period, DAY) * &InterestRateOfValueOfMoney / 36500 AS Factor
			|	FROM
			|		AccumulationRegister.CustomersARAPAccountingByDueDates AS CustomersARAPAccountingByDueDates
			|	WHERE
			|		CustomersARAPAccountingByDueDates.ARAPMan > 0
			|		AND CustomersARAPAccountingByDueDates.RecordType = VALUE(AccumulationRecordType.Expense)
			|		AND BEGINOFPERIOD(CustomersARAPAccountingByDueDates.Period, DAY) > CustomersARAPAccountingByDueDates.PlannedRepaymentDate
			|		AND CustomersARAPAccountingByDueDates.Period BETWEEN &StartDateAdditionalPeriod AND &EndDateAdditionalPeriod
			|		AND CustomersARAPAccountingByDueDates.ARAPObject IN (SELECT ARAPObject FROM ObjectsOfManagersCalculations)
			|		AND CustomersARAPAccountingByDueDates.Active
			|	
			|	UNION ALL
			|	
			|	SELECT
			|		CustomersARAPAccountingByDocumentsBalance.ARAPObject.Manager,
			|		CustomersARAPAccountingByDocumentsBalance.ARAPManBalance * DATEDIFF(BEGINOFPERIOD(CustomersARAPAccountingByDocumentsBalance.PlannedRepaymentDate, DAY), &EndDateAdditionalPeriod, DAY) * &InterestRateOfValueOfMoney / 36500
			|	FROM
			|		AccumulationRegister.CustomersARAPAccountingByDueDates.Balance(
			|			&EndDateAdditionalPeriod,
			|			ARAPObject IN (SELECT ARAPObject FROM ObjectsOfManagersCalculations)
			|		) AS CustomersARAPAccountingByDocumentsBalance
			|	WHERE
			|		CustomersARAPAccountingByDocumentsBalance.ARAPManBalance > 0
			|		AND CustomersARAPAccountingByDocumentsBalance.PlannedRepaymentDate < &PeriodEnding) AS NestedQuery
			|	GROUP BY
			|		ISNULL(NestedQuery.Manager, &NotSpecified)
			|
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			|
			|SELECT
			|	ISNULL(NestedQuery.Manager, &NotSpecified) AS Manager,
			|	NestedQuery.Current_,
			|	NestedQuery.Previous,
			|	CASE
			|		WHEN NestedQuery.Current_ - NestedQuery.Previous > 0
			|			THEN NestedQuery.Current_ - NestedQuery.Previous
			|		ELSE 0
			|	END AS Growth,
			|	CASE
			|		WHEN NestedQuery.Current_ - NestedQuery.Previous < 0
			|			THEN NestedQuery.Current_ - NestedQuery.Previous
			|		ELSE 0
			|	END AS Slippage
			|FROM
			|	(SELECT
			|		CASE
			|			WHEN PreviousPeriod_.Manager IS NULL 
			|				THEN CurrentPeriod.Manager
			|			ELSE PreviousPeriod_.Manager
			|		END AS Manager,
			|		SUM(ISNULL(PreviousPeriod_.Factor, 0)) AS Previous,
			|		SUM(ISNULL(CurrentPeriod.Factor, 0)) AS Current_
			|	FROM
			|		PreviousPeriodLossesAsResultOfOverdueReceivables AS PreviousPeriod_
			|			FULL JOIN CurPeriodLossesDueToOverdueReceivables AS CurrentPeriod
			|			ON PreviousPeriod_.Manager = CurrentPeriod.Manager
			|	
			|	GROUP BY
			|		CASE
			|			WHEN PreviousPeriod_.Manager IS NULL 
			|				THEN CurrentPeriod.Manager
			|			ELSE PreviousPeriod_.Manager
			|		END) AS NestedQuery
			|
			|ORDER BY
			|	NestedQuery.Current_
			|;
			|////////////////////////////////////////////////////////////////////////////////
			|";
			
		Else
			
			Return "
			|SELECT ALLOWED
			|	ISNULL(NestedQuery.Manager, &NotSpecified) AS Manager,
			|	SUM(NestedQuery.Factor) AS LossesDebitorka
			|FROM
			|	(SELECT
			|		CustomersARAPAccountingByDueDates.ARAPObject.Manager AS Manager,
			|		-CustomersARAPAccountingByDueDates.ARAPMan * DATEDIFF(BEGINOFPERIOD(CustomersARAPAccountingByDueDates.PlannedRepaymentDate, DAY), CustomersARAPAccountingByDueDates.Period, DAY) * &InterestRateOfValueOfMoney / 36500 AS Factor
			|	FROM
			|		AccumulationRegister.CustomersARAPAccountingByDueDates AS CustomersARAPAccountingByDueDates
			|	WHERE
			|		CustomersARAPAccountingByDueDates.ARAPMan > 0
			|		AND CustomersARAPAccountingByDueDates.RecordType = VALUE(AccumulationRecordType.Expense)
			|		AND BEGINOFPERIOD(CustomersARAPAccountingByDueDates.Period, DAY) > CustomersARAPAccountingByDueDates.PlannedRepaymentDate
			|		AND CustomersARAPAccountingByDueDates.Period BETWEEN &BeginOfPeriod AND &PeriodEnding
			|		AND CustomersARAPAccountingByDueDates.ARAPObject IN (SELECT ARAPObject FROM ObjectsOfManagersCalculations)
			|		AND CustomersARAPAccountingByDueDates.Active
			|	
			|	UNION ALL
			|	
			|	SELECT
			|		CustomersARAPAccountingByDueDatesBalance.ARAPObject.Manager,
			|		CustomersARAPAccountingByDueDatesBalance.ARAPManBalance * DATEDIFF(BEGINOFPERIOD(CustomersARAPAccountingByDueDatesBalance.PlannedRepaymentDate, DAY), &PeriodEnding, DAY) * &InterestRateOfValueOfMoney / 36500
			|	FROM
			|		AccumulationRegister.CustomersARAPAccountingByDueDates.Balance(
			|			&PeriodEnding, ARAPObject IN (SELECT ARAPObject FROM ObjectsOfManagersCalculations)
			|		) AS CustomersARAPAccountingByDueDatesBalance
			|	WHERE
			|		CustomersARAPAccountingByDueDatesBalance.ARAPManBalance > 0
			|		AND CustomersARAPAccountingByDueDatesBalance.PlannedRepaymentDate < &PeriodEnding) AS NestedQuery
			|
			|GROUP BY
			|	ISNULL(NestedQuery.Manager, &NotSpecified)
			|
			|ORDER BY
			|	LossesDebitorka
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			|";
			
		EndIf;
		
	Else
	
		If StructureOfReportGenerationPeriods.ThereIsExtraPeriod Then
			
			Return "SELECT ALLOWED
			|	ISNULL(NestedQuery.CustomerOrderManager, &NotSpecified) AS Manager,
			|	SUM(NestedQuery.Factor) AS Factor
			|INTO CurPeriodLossesDueToOverdueReceivables
			|FROM
			|	(SELECT
			|		CustomersARAPAccountingByDocuments.SalesOrder.Manager AS CustomerOrderManager,
			|		CASE
			|			WHEN CustomersARAPAccountingByDocuments.Currency = Constants.ManagementAccountingCurrency
			|				THEN CustomersARAPAccountingByDocuments.Debt
			|			ELSE CASE
			|					WHEN ISNULL(ExchangeRateOfManagementAccounting_.WeightedAverageExchangeRate, 0) = 0
			|						THEN 0
			|					ELSE CustomersARAPAccountingByDocuments.Debt * ISNULL(OtherCurrencyRates.WeightedAverageExchangeRate, 0) / ISNULL(ExchangeRateOfManagementAccounting_.WeightedAverageExchangeRate, 0)
			|				END
			|		END * DATEDIFF(BEGINOFPERIOD(CustomersARAPAccountingByDocuments.PaymentDate, DAY), CustomersARAPAccountingByDocuments.Recorder.Date, DAY) * &InterestRateOfValueOfMoney / 36500 AS Factor
			|	FROM
			|		AccumulationRegister.CustomersARAPAccountingByDocuments AS CustomersARAPAccountingByDocuments
			|			
			|		LEFT JOIN WeightedAverageExchangeRatesForCurPeriod AS OtherCurrencyRates
			|		ON CustomersARAPAccountingByDocuments.Currency = OtherCurrencyRates.Currency,
			|			Constants AS Constants
			|			
			|		LEFT JOIN WeightedAverageExchangeRatesForCurPeriod AS ExchangeRateOfManagementAccounting_
			|		ON (Constants.ManagementAccountingCurrency = ExchangeRateOfManagementAccounting_.Currency)
			|	WHERE
			|		CustomersARAPAccountingByDocuments.RecordType = &RecordTypeExpense
			|		AND CustomersARAPAccountingByDocuments.Debt > 0
			|		AND BEGINOFPERIOD(CustomersARAPAccountingByDocuments.Period, DAY) > CustomersARAPAccountingByDocuments.PaymentDate
			|		AND CustomersARAPAccountingByDocuments.Recorder.Date BETWEEN &BeginOfPeriod AND &PeriodEnding
			|		AND ExchangeRateOfManagementAccounting_.Currency = Constants.ManagementAccountingCurrency AND SalesOrder.Manager IN (SELECT FilterByManagers.Ref FROM FilterByManagers AS FilterByManagers)
			|		AND CustomersARAPAccountingByDocuments.Active
			|	
			|	UNION ALL
			|	
			|	SELECT
			|		CustomersARAPAccountingByDocumentsBalance.SalesOrder.Manager,
			|		(CASE WHEN CustomersARAPAccountingByDocumentsBalance.Currency = Constants.ManagementAccountingCurrency
			|			THEN CustomersARAPAccountingByDocumentsBalance.DebtBalance
			|			ELSE
			|				CASE WHEN ISNULL(ExchangeRateOfManagementAccounting_.WeightedAverageExchangeRate, 0) = 0
			|					THEN 0
			|					ELSE CustomersARAPAccountingByDocumentsBalance.DebtBalance * ISNULL(OtherCurrencyRates.WeightedAverageExchangeRate, 0) / ISNULL(ExchangeRateOfManagementAccounting_.WeightedAverageExchangeRate, 0)
			|				END
			|		END) * DATEDIFF(BEGINOFPERIOD(Balance.PaymentDate, DAY), &PeriodEnding, DAY)
			|			  * &InterestRateOfValueOfMoney / 36500
			|	FROM
			|		AccumulationRegister.CustomersARAPAccountingByDocuments.Balance(&PeriodEnding,
			|			SalesOrder.Manager IN (
			|				SELECT 
			|					FilterByManagers.Ref 
			|				FROM FilterByManagers AS FilterByManagers
			|			)) AS CustomersARAPAccountingByDocumentsBalance
			|
			|		INNER JOIN CustomerBalanceTable AS Balance
			|		ON CustomersARAPAccountingByDocumentsBalance.AccountingDimensionByPartners = Balance.AccountingDimensionByPartners
			|			AND CustomersARAPAccountingByDocumentsBalance.SalesOrder = Balance.SalesOrder
			|			AND CustomersARAPAccountingByDocumentsBalance.ARAPDocument = Balance.ARAPDocument
			|			AND CustomersARAPAccountingByDocumentsBalance.Currency = Balance.Currency
			|			AND Balance.PaymentDate < &PeriodEnding
			|
			|		LEFT JOIN WeightedAverageExchangeRatesForCurPeriod AS OtherCurrencyRates
			|		ON CustomersARAPAccountingByDocumentsBalance.Currency = OtherCurrencyRates.Currency,
			|		Constants AS Constants
			|
			|		LEFT JOIN WeightedAverageExchangeRatesForCurPeriod AS ExchangeRateOfManagementAccounting_
			|		ON (Constants.ManagementAccountingCurrency = ExchangeRateOfManagementAccounting_.Currency)
			|	WHERE
			|		CustomersARAPAccountingByDocumentsBalance.DebtBalance > 0
			|	) AS NestedQuery
			|
			|GROUP BY
			|	ISNULL(NestedQuery.CustomerOrderManager, &NotSpecified)
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			|
			|SELECT ALLOWED
			|	ISNULL(NestedQuery.CustomerOrderManager, &NotSpecified) AS Manager,
			|	SUM(NestedQuery.Factor) AS Factor
			|INTO PreviousPeriodLossesAsResultOfOverdueReceivables
			|FROM
			|	(SELECT
			|		CustomersARAPAccountingByDocuments.SalesOrder.Manager AS CustomerOrderManager,
			|		CASE
			|			WHEN CustomersARAPAccountingByDocuments.Currency = Constants.ManagementAccountingCurrency
			|				THEN CustomersARAPAccountingByDocuments.Debt
			|			ELSE CASE
			|					WHEN ISNULL(ExchangeRateOfManagementAccounting_.WeightedAverageExchangeRate, 0) = 0
			|						THEN 0
			|					ELSE CustomersARAPAccountingByDocuments.Debt * ISNULL(OtherCurrencyRates.WeightedAverageExchangeRate, 0) / ISNULL(ExchangeRateOfManagementAccounting_.WeightedAverageExchangeRate, 0)
			|				END
			|		END * DATEDIFF(BEGINOFPERIOD(CustomersARAPAccountingByDocuments.PaymentDate, DAY), CustomersARAPAccountingByDocuments.Recorder.Date, DAY) * &InterestRateOfValueOfMoney / 36500 AS Factor
			|	FROM
			|		AccumulationRegister.CustomersARAPAccountingByDocuments AS CustomersARAPAccountingByDocuments
			|			LEFT JOIN WeightedAverageExchangeRatesForAdditionalPeriod AS OtherCurrencyRates
			|			ON CustomersARAPAccountingByDocuments.Currency = OtherCurrencyRates.Currency,
			|		Constants AS Constants
			|			LEFT JOIN WeightedAverageExchangeRatesForAdditionalPeriod AS ExchangeRateOfManagementAccounting_
			|			ON (Constants.ManagementAccountingCurrency = ExchangeRateOfManagementAccounting_.Currency)
			|	WHERE
			|		CustomersARAPAccountingByDocuments.RecordType = &RecordTypeExpense
			|		AND CustomersARAPAccountingByDocuments.Debt > 0
			|		AND BEGINOFPERIOD(CustomersARAPAccountingByDocuments.Period, DAY) > CustomersARAPAccountingByDocuments.PaymentDate
			|		AND CustomersARAPAccountingByDocuments.Recorder.Date BETWEEN &StartDateAdditionalPeriod AND &EndDateAdditionalPeriod
			|		AND ExchangeRateOfManagementAccounting_.Currency = Constants.ManagementAccountingCurrency AND SalesOrder.Manager IN (SELECT FilterByManagers.Ref FROM FilterByManagers AS FilterByManagers)
			|		AND CustomersARAPAccountingByDocuments.Active
			|	
			|	UNION ALL
			|	
			|	SELECT
			|		CustomersARAPAccountingByDocumentsBalance.SalesOrder.Manager,
			|		CASE
			|			WHEN CustomersARAPAccountingByDocumentsBalance.Currency = Constants.ManagementAccountingCurrency
			|				THEN CustomersARAPAccountingByDocumentsBalance.DebtBalance
			|			ELSE CASE
			|					WHEN ISNULL(ExchangeRateOfManagementAccounting_.WeightedAverageExchangeRate, 0) = 0
			|						THEN 0
			|					ELSE CustomersARAPAccountingByDocumentsBalance.DebtBalance * ISNULL(OtherCurrencyRates.WeightedAverageExchangeRate, 0) / ISNULL(ExchangeRateOfManagementAccounting_.WeightedAverageExchangeRate, 0)
			|				END
			|		END * DATEDIFF(BEGINOFPERIOD(Balance.PaymentDate, DAY), &EndDateAdditionalPeriod, DAY) * &InterestRateOfValueOfMoney / 36500
			|	FROM
			|		AccumulationRegister.CustomersARAPAccountingByDocuments.Balance(
			|			&EndDateAdditionalPeriod,
			|			SalesOrder.Manager IN (
			|				SELECT 
			|					FilterByManagers.Ref 
			|				FROM FilterByManagers AS FilterByManagers
			|			)
			|		) AS CustomersARAPAccountingByDocumentsBalance
			|
			|		INNER JOIN CustomerBalanceTable AS Balance
			|		ON CustomersARAPAccountingByDocumentsBalance.AccountingDimensionByPartners = Balance.AccountingDimensionByPartners
			|			AND CustomersARAPAccountingByDocumentsBalance.SalesOrder = Balance.SalesOrder
			|			AND CustomersARAPAccountingByDocumentsBalance.ARAPDocument = Balance.ARAPDocument
			|			AND CustomersARAPAccountingByDocumentsBalance.Currency = Balance.Currency
			|			AND Balance.PaymentDate < &EndDateAdditionalPeriod
			|
			|		LEFT JOIN WeightedAverageExchangeRatesForAdditionalPeriod AS OtherCurrencyRates
			|		ON CustomersARAPAccountingByDocumentsBalance.Currency = OtherCurrencyRates.Currency,
			|		Constants AS Constants
			|
			|		LEFT JOIN WeightedAverageExchangeRatesForAdditionalPeriod AS ExchangeRateOfManagementAccounting_
			|		ON (Constants.ManagementAccountingCurrency = ExchangeRateOfManagementAccounting_.Currency)
			|	WHERE
			|		CustomersARAPAccountingByDocumentsBalance.DebtBalance > 0) AS NestedQuery
			|
			|GROUP BY
			|	ISNULL(NestedQuery.CustomerOrderManager, &NotSpecified)
			|
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			|
			|SELECT
			|	ISNULL(NestedQuery.Manager, &NotSpecified) AS Manager,
			|	NestedQuery.Current_,
			|	NestedQuery.Previous,
			|	CASE
			|		WHEN NestedQuery.Current_ - NestedQuery.Previous > 0
			|			THEN NestedQuery.Current_ - NestedQuery.Previous
			|		ELSE 0
			|	END AS Growth,
			|	CASE
			|		WHEN NestedQuery.Current_ - NestedQuery.Previous < 0
			|			THEN NestedQuery.Current_ - NestedQuery.Previous
			|		ELSE 0
			|	END AS Slippage
			|FROM
			|	(SELECT
			|		CASE
			|			WHEN PreviousPeriod_.Manager IS NULL 
			|				THEN CurrentPeriod.Manager
			|			ELSE PreviousPeriod_.Manager
			|		END AS Manager,
			|		SUM(ISNULL(PreviousPeriod_.Factor, 0)) AS Previous,
			|		SUM(ISNULL(CurrentPeriod.Factor, 0)) AS Current_
			|	FROM
			|		PreviousPeriodLossesAsResultOfOverdueReceivables AS PreviousPeriod_
			|			FULL JOIN CurPeriodLossesDueToOverdueReceivables AS CurrentPeriod
			|			ON PreviousPeriod_.Manager = CurrentPeriod.Manager
			|	
			|	GROUP BY
			|		CASE
			|			WHEN PreviousPeriod_.Manager IS NULL 
			|				THEN CurrentPeriod.Manager
			|			ELSE PreviousPeriod_.Manager
			|		END) AS NestedQuery
			|
			|ORDER BY
			|	NestedQuery.Current_
			|;
			|////////////////////////////////////////////////////////////////////////////////
			|";
			
		Else
			
			Return "SELECT ALLOWED
			|	ISNULL(NestedQuery.CustomerOrderManager, &NotSpecified) AS Manager,
			|	SUM(NestedQuery.Factor) AS LossesDebitorka
			|FROM
			|	(SELECT
			|		CustomersARAPAccountingByDocuments.SalesOrder.Manager AS CustomerOrderManager,
			|		CASE
			|			WHEN CustomersARAPAccountingByDocuments.Currency = Constants.ManagementAccountingCurrency
			|				THEN CustomersARAPAccountingByDocuments.Debt
			|			ELSE CASE
			|					WHEN ISNULL(ExchangeRateOfManagementAccounting_.WeightedAverageExchangeRate, 0) = 0
			|						THEN 0
			|					ELSE CustomersARAPAccountingByDocuments.Debt * ISNULL(OtherCurrencyRates.WeightedAverageExchangeRate, 0) / ISNULL(ExchangeRateOfManagementAccounting_.WeightedAverageExchangeRate, 0)
			|				END
			|		END * DATEDIFF(BEGINOFPERIOD(CustomersARAPAccountingByDocuments.PaymentDate, DAY), CustomersARAPAccountingByDocuments.Recorder.Date, DAY) * &InterestRateOfValueOfMoney / 36500 AS Factor
			|	FROM
			|		AccumulationRegister.CustomersARAPAccountingByDocuments AS CustomersARAPAccountingByDocuments
			|			LEFT JOIN WeightedAverageExchangeRatesForCurPeriod AS OtherCurrencyRates
			|			ON CustomersARAPAccountingByDocuments.Currency = OtherCurrencyRates.Currency,
			|		Constants AS Constants
			|			LEFT JOIN WeightedAverageExchangeRatesForCurPeriod AS ExchangeRateOfManagementAccounting_
			|			ON (Constants.ManagementAccountingCurrency = ExchangeRateOfManagementAccounting_.Currency)
			|	WHERE
			|		CustomersARAPAccountingByDocuments.RecordType = &RecordTypeExpense
			|		AND CustomersARAPAccountingByDocuments.Debt > 0
			|		AND BEGINOFPERIOD(CustomersARAPAccountingByDocuments.Period, DAY) > CustomersARAPAccountingByDocuments.PaymentDate
			|		AND CustomersARAPAccountingByDocuments.Recorder.Date BETWEEN &BeginOfPeriod AND &PeriodEnding
			|		AND ExchangeRateOfManagementAccounting_.Currency = Constants.ManagementAccountingCurrency AND SalesOrder.Manager IN (SELECT FilterByManagers.Ref FROM FilterByManagers AS FilterByManagers)
			|		AND CustomersARAPAccountingByDocuments.Active
			|	
			|	UNION ALL
			|	
			|	SELECT
			|		CustomersARAPAccountingByDocumentsBalance.SalesOrder.Manager,
			|		CASE
			|			WHEN CustomersARAPAccountingByDocumentsBalance.Currency = Constants.ManagementAccountingCurrency
			|				THEN CustomersARAPAccountingByDocumentsBalance.DebtBalance
			|			ELSE CASE
			|					WHEN ISNULL(ExchangeRateOfManagementAccounting_.WeightedAverageExchangeRate, 0) = 0
			|						THEN 0
			|					ELSE CustomersARAPAccountingByDocumentsBalance.DebtBalance * ISNULL(OtherCurrencyRates.WeightedAverageExchangeRate, 0) / ISNULL(ExchangeRateOfManagementAccounting_.WeightedAverageExchangeRate, 0)
			|				END
			|		END * DATEDIFF(BEGINOFPERIOD(Balance.PaymentDate, DAY), &PeriodEnding, DAY) * &InterestRateOfValueOfMoney / 36500
			|	FROM
			|		AccumulationRegister.CustomersARAPAccountingByDocuments.Balance(
			|			&PeriodEnding,SalesOrder.Manager IN (
			|				SELECT 
			|					FilterByManagers.Ref
			|				FROM FilterByManagers AS FilterByManagers
			|			)
			|		) AS CustomersARAPAccountingByDocumentsBalance
			|
			|		INNER JOIN CustomerBalanceTable AS Balance
			|		ON CustomersARAPAccountingByDocumentsBalance.AccountingDimensionByPartners = Balance.AccountingDimensionByPartners
			|			AND CustomersARAPAccountingByDocumentsBalance.SalesOrder = Balance.SalesOrder
			|			AND CustomersARAPAccountingByDocumentsBalance.ARAPDocument = Balance.ARAPDocument
			|			AND CustomersARAPAccountingByDocumentsBalance.Currency = Balance.Currency
			|			AND Balance.PaymentDate < &PeriodEnding
			|
			|		LEFT JOIN WeightedAverageExchangeRatesForCurPeriod AS OtherCurrencyRates
			|		ON CustomersARAPAccountingByDocumentsBalance.Currency = OtherCurrencyRates.Currency,
			|		Constants AS Constants
			|
			|		LEFT JOIN WeightedAverageExchangeRatesForCurPeriod AS ExchangeRateOfManagementAccounting_
			|		ON (Constants.ManagementAccountingCurrency = ExchangeRateOfManagementAccounting_.Currency)
			|	WHERE
			|		CustomersARAPAccountingByDocumentsBalance.DebtBalance > 0) AS NestedQuery
			|
			|GROUP BY
			|	ISNULL(NestedQuery.CustomerOrderManager, &NotSpecified)
			|
			|ORDER BY
			|	LossesDebitorka
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			|";
			
		EndIf;
	
	EndIf;
	
EndFunction

Function RequestTextForManualDiscounts(MatchingRequestsData,LastPacketNumber, StructureOfReportGenerationPeriods)
	
	If StructureOfReportGenerationPeriods.ThereIsExtraPeriod Then
		
		MatchingRequestsData.Insert("ManualDiscountsAreProvided",LastPacketNumber + 3);
		LastPacketNumber = LastPacketNumber + 3;
		
		Return "SELECT ALLOWED
		|	NestedQuery.Manager,
		|	NestedQuery.Profit_ AS Profit_,
		|	NestedQuery.ManualDiscount,
		|	CASE
		|		WHEN NestedQuery.Profit_ = 0
		|			THEN 0
		|		ELSE NestedQuery.ManualDiscount / NestedQuery.Profit_ * 100
		|	END AS ShareOfDiscountFromProfit
		|INTO CurPeriodProvidedManualDiscounts
		|FROM
		|	(SELECT
		|		ISNULL(NestedQuery.Manager, &NotSpecified) AS Manager,
		|		SUM(NestedQuery.Profit_) AS Profit_,
		|		SUM(CASE
		|				WHEN NestedQuery.Currency = Constants.ManagementAccountingCurrency
		|					THEN NestedQuery.ManualDiscount
		|				ELSE CASE
		|						WHEN ISNULL(ExchangeRateOfManagementAccounting_.WeightedAverageExchangeRate, 0) = 0
		|							THEN 0
		|						ELSE NestedQuery.ManualDiscount * ISNULL(OtherCurrencyRates.WeightedAverageExchangeRate, 0) / ISNULL(ExchangeRateOfManagementAccounting_.WeightedAverageExchangeRate, 0)
		|					END
		|			END) AS ManualDiscount
		|	FROM
		|		(SELECT
		|			CustomerInvoice.Manager AS Manager,
		|			CustomerInvoice.Currency AS Currency,
		|			SUM(SalesOfGoodsServicesGoods.ManualDiscount) AS ManualDiscount,
		|			BEGINOFPERIOD(CustomerInvoice.Date, DAY) AS DocumentDate,
		|			0 AS Profit_
		|		FROM
		|			Document.CustomerInvoice.Goods AS SalesOfGoodsServicesGoods
		|				LEFT JOIN Document.CustomerInvoice AS CustomerInvoice
		|				ON SalesOfGoodsServicesGoods.Ref = CustomerInvoice.Ref
		|		WHERE
		|			CustomerInvoice.Posted
		|			AND CustomerInvoice.Goods.ManualDiscount <> 0
		|			AND CustomerInvoice.Date BETWEEN &BeginOfPeriod AND &PeriodEnding
		|			AND CustomerInvoice.Manager IN
		|			(SELECT
		|				FilterByManagers.Ref
		|			FROM
		|				FilterByManagers AS FilterByManagers)
		|		
		|		GROUP BY
		|			CustomerInvoice.Manager,
		|			CustomerInvoice.Currency,
		|			BEGINOFPERIOD(CustomerInvoice.Date, DAY)
		|		
		|		UNION ALL
		|		
		|		SELECT
		|			RevenueAndCostOfSalesTurnover.SalesOrder.Manager,
		|			Constants.ManagementAccountingCurrency,
		|			0,
		|			&PeriodEnding,
		|			SUM(RevenueAndCostOfSalesTurnover.RevenueAmountTurnover - RevenueAndCostOfSalesTurnover.CostTurnover)
		|		FROM
		|			AccumulationRegister.RevenueAndCOGS.Turnovers(&BeginOfPeriod, &PeriodEnding, , AccountingDimensionByPartners.Partner <> VALUE(Catalog.Partners.RetailCustomer) AND SalesOrder.Manager IN (SELECT FilterByManagers.Ref FROM FilterByManagers AS FilterByManagers)) AS RevenueAndCostOfSalesTurnover,
		|			Constants AS Constants
		|		
		|		GROUP BY
		|			RevenueAndCostOfSalesTurnover.SalesOrder.Manager,
		|			Constants.ManagementAccountingCurrency) AS NestedQuery
		|			LEFT JOIN WeightedAverageExchangeRatesForCurPeriod AS ExchangeRateOfManagementAccounting_
		|			ON (TRUE)
		|			LEFT JOIN WeightedAverageExchangeRatesForCurPeriod AS OtherCurrencyRates
		|			ON NestedQuery.Currency = OtherCurrencyRates.Currency,
		|		Constants AS Constants
		|	WHERE
		|		ExchangeRateOfManagementAccounting_.Currency = Constants.ManagementAccountingCurrency
		|	
		|	GROUP BY
		|		NestedQuery.Manager,
		|		CASE
		|			WHEN NestedQuery.Profit_ = 0
		|				THEN 0
		|			ELSE CASE
		|					WHEN NestedQuery.Currency = Constants.ManagementAccountingCurrency
		|						THEN NestedQuery.ManualDiscount
		|					ELSE CASE
		|							WHEN ISNULL(ExchangeRateOfManagementAccounting_.WeightedAverageExchangeRate, 0) = 0
		|								THEN 0
		|							ELSE NestedQuery.ManualDiscount * ISNULL(OtherCurrencyRates.WeightedAverageExchangeRate, 0) / ISNULL(ExchangeRateOfManagementAccounting_.WeightedAverageExchangeRate, 0)
		|						END
		|				END / NestedQuery.Profit_
		|		END) AS NestedQuery
		|
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT ALLOWED
		|	NestedQuery.Manager,
		|	NestedQuery.Profit_ AS Profit_,
		|	NestedQuery.ManualDiscount,
		|	CASE
		|		WHEN NestedQuery.Profit_ = 0
		|			THEN 0
		|		ELSE NestedQuery.ManualDiscount / NestedQuery.Profit_ * 100
		|	END AS ShareOfDiscountFromProfit
		|INTO PreviousPeriodProvidedManualDiscounts
		|FROM
		|	(SELECT
		|		ISNULL(NestedQuery.Manager, &NotSpecified) AS Manager,
		|		SUM(NestedQuery.Profit_) AS Profit_,
		|		SUM(CASE
		|				WHEN NestedQuery.Currency = Constants.ManagementAccountingCurrency
		|					THEN NestedQuery.ManualDiscount
		|				ELSE CASE
		|						WHEN ISNULL(ExchangeRateOfManagementAccounting_.WeightedAverageExchangeRate, 0) = 0
		|							THEN 0
		|						ELSE NestedQuery.ManualDiscount * ISNULL(OtherCurrencyRates.WeightedAverageExchangeRate, 0) / ISNULL(ExchangeRateOfManagementAccounting_.WeightedAverageExchangeRate, 0)
		|					END
		|			END) AS ManualDiscount
		|	FROM
		|		(SELECT
		|			CustomerInvoice.Manager AS Manager,
		|			CustomerInvoice.Currency AS Currency,
		|			SUM(SalesOfGoodsServicesGoods.ManualDiscount) AS ManualDiscount,
		|			BEGINOFPERIOD(CustomerInvoice.Date, DAY) AS DocumentDate,
		|			0 AS Profit_
		|		FROM
		|			Document.CustomerInvoice.Goods AS SalesOfGoodsServicesGoods
		|				LEFT JOIN Document.CustomerInvoice AS CustomerInvoice
		|				ON SalesOfGoodsServicesGoods.Ref = CustomerInvoice.Ref
		|		WHERE
		|			CustomerInvoice.Posted
		|			AND CustomerInvoice.Goods.ManualDiscount <> 0
		|			AND CustomerInvoice.Date BETWEEN &StartDateAdditionalPeriod AND &EndDateAdditionalPeriod
		|			AND CustomerInvoice.Manager IN
		|			(SELECT
		|				FilterByManagers.Ref
		|			FROM
		|				FilterByManagers AS FilterByManagers)
		|		
		|		GROUP BY
		|			CustomerInvoice.Manager,
		|			CustomerInvoice.Currency,
		|			BEGINOFPERIOD(CustomerInvoice.Date, DAY)
		|		
		|		UNION ALL
		|		
		|		SELECT
		|			RevenueAndCostOfSalesTurnover.SalesOrder.Manager,
		|			Constants.ManagementAccountingCurrency,
		|			0,
		|			&PeriodEnding,
		|			SUM(RevenueAndCostOfSalesTurnover.RevenueAmountTurnover - RevenueAndCostOfSalesTurnover.CostTurnover)
		|		FROM
		|			AccumulationRegister.RevenueAndCOGS.Turnovers(&StartDateAdditionalPeriod, &EndDateAdditionalPeriod, , AccountingDimensionByPartners.Partner <> VALUE(Catalog.Partners.RetailCustomer) AND SalesOrder.Manager IN (SELECT FilterByManagers.Ref FROM FilterByManagers AS FilterByManagers)) AS RevenueAndCostOfSalesTurnover,
		|			Constants AS Constants
		|		
		|		GROUP BY
		|			RevenueAndCostOfSalesTurnover.SalesOrder.Manager,
		|			Constants.ManagementAccountingCurrency) AS NestedQuery
		|			LEFT JOIN WeightedAverageExchangeRatesForAdditionalPeriod AS ExchangeRateOfManagementAccounting_
		|			ON (TRUE)
		|			LEFT JOIN WeightedAverageExchangeRatesForAdditionalPeriod AS OtherCurrencyRates
		|			ON NestedQuery.Currency = OtherCurrencyRates.Currency,
		|		Constants AS Constants
		|	WHERE
		|		ExchangeRateOfManagementAccounting_.Currency = Constants.ManagementAccountingCurrency
		|	
		|	GROUP BY
		|		NestedQuery.Manager,
		|		CASE
		|			WHEN NestedQuery.Profit_ = 0
		|				THEN 0
		|			ELSE CASE
		|					WHEN NestedQuery.Currency = Constants.ManagementAccountingCurrency
		|						THEN NestedQuery.ManualDiscount
		|					ELSE CASE
		|							WHEN ISNULL(ExchangeRateOfManagementAccounting_.WeightedAverageExchangeRate, 0) = 0
		|								THEN 0
		|							ELSE NestedQuery.ManualDiscount * ISNULL(OtherCurrencyRates.WeightedAverageExchangeRate, 0) / ISNULL(ExchangeRateOfManagementAccounting_.WeightedAverageExchangeRate, 0)
		|						END
		|				END / NestedQuery.Profit_
		|		END) AS NestedQuery
		|
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|
		|SELECT
		|ISNULL(CurPeriodProvidedManualDiscounts.Manager, PreviousPeriodProvidedManualDiscounts.Manager) AS Manager,
		|ISNULL(CurPeriodProvidedManualDiscounts.Profit_, 0) AS ProfitCur,
		|ISNULL(CurPeriodProvidedManualDiscounts.ManualDiscount, 0) AS AmountOfManualDiscountCur,
		|ISNULL(CurPeriodProvidedManualDiscounts.ShareOfDiscountFromProfit, 0) AS ShareOfDiscountFromProfitCur,
		|ISNULL(PreviousPeriodProvidedManualDiscounts.Profit_, 0) AS ProfitPrevious,
		|ISNULL(PreviousPeriodProvidedManualDiscounts.ManualDiscount, 0) AS AmountOfManualDiscountPrevious,
		|ISNULL(PreviousPeriodProvidedManualDiscounts.ShareOfDiscountFromProfit, 0) AS ShareOfDiscountFromProfitPrevious
		|FROM
		|CurPeriodProvidedManualDiscounts AS CurPeriodProvidedManualDiscounts
		|FULL JOIN PreviousPeriodProvidedManualDiscounts AS PreviousPeriodProvidedManualDiscounts
		|ON CurPeriodProvidedManualDiscounts.Manager = PreviousPeriodProvidedManualDiscounts.Manager
		|
		|ORDER BY
		|	ShareOfDiscountFromProfitCur,
		|	ProfitCur
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|";
		
	Else
		MatchingRequestsData.Insert("ManualDiscountsAreProvided",LastPacketNumber + 1);
		LastPacketNumber = LastPacketNumber + 1;
		
		Return "SELECT ALLOWED
		|	NestedQuery.Manager,
		|	NestedQuery.Profit_ AS Profit_,
		|	NestedQuery.ManualDiscount,
		|	CASE
		|		WHEN NestedQuery.Profit_ = 0
		|			THEN 0
		|		ELSE NestedQuery.ManualDiscount / NestedQuery.Profit_ * 100
		|	END AS ShareOfDiscountFromProfit
		|FROM
		|	(SELECT
		|		ISNULL(NestedQuery.Manager, &NotSpecified) AS Manager,
		|		SUM(NestedQuery.Profit_) AS Profit_,
		|		SUM(CASE
		|				WHEN NestedQuery.Currency = Constants.ManagementAccountingCurrency
		|					THEN NestedQuery.ManualDiscount
		|				ELSE CASE
		|						WHEN ISNULL(ExchangeRateOfManagementAccounting_.WeightedAverageExchangeRate, 0) = 0
		|							THEN 0
		|						ELSE NestedQuery.ManualDiscount * ISNULL(OtherCurrencyRates.WeightedAverageExchangeRate, 0) / ISNULL(ExchangeRateOfManagementAccounting_.WeightedAverageExchangeRate, 0)
		|					END
		|			END) AS ManualDiscount
		|	FROM
		|		(SELECT
		|			CustomerInvoice.Manager AS Manager,
		|			CustomerInvoice.Currency AS Currency,
		|			SUM(SalesOfGoodsServicesGoods.ManualDiscount) AS ManualDiscount,
		|			BEGINOFPERIOD(CustomerInvoice.Date, DAY) AS DocumentDate,
		|			0 AS Profit_
		|		FROM
		|			Document.CustomerInvoice.Goods AS SalesOfGoodsServicesGoods
		|				LEFT JOIN Document.CustomerInvoice AS CustomerInvoice
		|				ON SalesOfGoodsServicesGoods.Ref = CustomerInvoice.Ref
		|		WHERE
		|			CustomerInvoice.Posted
		|			AND CustomerInvoice.Goods.ManualDiscount <> 0
		|			AND CustomerInvoice.Date BETWEEN &BeginOfPeriod AND &PeriodEnding
		|			AND CustomerInvoice.Manager IN
		|					(SELECT
		|						FilterByManagers.Ref
		|					FROM
		|						FilterByManagers AS FilterByManagers)
		|		
		|		GROUP BY
		|			CustomerInvoice.Manager,
		|			CustomerInvoice.Currency,
		|			BEGINOFPERIOD(CustomerInvoice.Date, DAY)
		|		
		|		UNION ALL
		|		
		|		SELECT
		|			RevenueAndCostOfSalesTurnover.SalesOrder.Manager,
		|			Constants.ManagementAccountingCurrency,
		|			0,
		|			&PeriodEnding,
		|			SUM(RevenueAndCostOfSalesTurnover.RevenueAmountTurnover - RevenueAndCostOfSalesTurnover.CostTurnover)
		|		FROM
		|			AccumulationRegister.RevenueAndCOGS.Turnovers(
		|					&BeginOfPeriod,
		|					&PeriodEnding,
		|					,
		|					SalesOrder.Manager IN
		|						(SELECT
		|							FilterByManagers.Ref
		|						FROM
		|							FilterByManagers AS FilterByManagers) AND SalesOrder.Partner <> VALUE(Catalog.Partners.RetailCustomer)) AS RevenueAndCostOfSalesTurnover,
		|			Constants AS Constants
		|		
		|		GROUP BY
		|			RevenueAndCostOfSalesTurnover.SalesOrder.Manager,
		|			Constants.ManagementAccountingCurrency) AS NestedQuery
		|			LEFT JOIN WeightedAverageExchangeRatesForCurPeriod AS ExchangeRateOfManagementAccounting_
		|			ON (TRUE)
		|			LEFT JOIN WeightedAverageExchangeRatesForCurPeriod AS OtherCurrencyRates
		|			ON NestedQuery.Currency = OtherCurrencyRates.Currency,
		|		Constants AS Constants
		|	WHERE
		|		ExchangeRateOfManagementAccounting_.Currency = Constants.ManagementAccountingCurrency
		|	
		|	GROUP BY
		|		NestedQuery.Manager,
		|		CASE
		|			WHEN NestedQuery.Profit_ = 0
		|				THEN 0
		|			ELSE CASE
		|					WHEN NestedQuery.Currency = Constants.ManagementAccountingCurrency
		|						THEN NestedQuery.ManualDiscount
		|					ELSE CASE
		|							WHEN ISNULL(ExchangeRateOfManagementAccounting_.WeightedAverageExchangeRate, 0) = 0
		|								THEN 0
		|							ELSE NestedQuery.ManualDiscount * ISNULL(OtherCurrencyRates.WeightedAverageExchangeRate, 0) / ISNULL(ExchangeRateOfManagementAccounting_.WeightedAverageExchangeRate, 0)
		|						END
		|				END / NestedQuery.Profit_
		|		END) AS NestedQuery
		|
		|ORDER BY
		|	ShareOfDiscountFromProfit,
		|	Profit_
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|";
		
	EndIf;
	
EndFunction

Function TextOfRequestOnEffectivenessOfTransactions(MatchingRequestsData,LastPacketNumber, StructureOfReportGenerationPeriods)
	
	If StructureOfReportGenerationPeriods.ThereIsExtraPeriod Then
		
		MatchingRequestsData.Insert("EfficiencyOfOpportunityManagement",LastPacketNumber + 3);
		LastPacketNumber = LastPacketNumber + 3;
		
		Return "SELECT ALLOWED
		|	NestedQuery.Manager,
		|	NestedQuery.Won AS WonDeals,
		|	NestedQuery.WasLost AS LostDeals,
		|	CASE
		|		WHEN NestedQuery.Won + NestedQuery.WasLost = 0
		|			THEN 0
		|		ELSE NestedQuery.Won / (NestedQuery.Won + NestedQuery.WasLost) * 100
		|	END AS ShareOfDealsWon
		|INTO EfficiencyOfTransactionsCur
		|FROM
		|	(SELECT
		|		CASE
		|			WHEN SalesOpportunitiesToCustomer.EmployeeResponsible = VALUE(Catalog.Users.EmptyRef)
		|				THEN &NotSpecified
		|			ELSE SalesOpportunitiesToCustomer.EmployeeResponsible
		|		END AS Manager,
		|		SUM(CASE
		|				WHEN SalesOpportunitiesToCustomer.Status = VALUE(Enum.OpportunityStatuses.Won)
		|					THEN 1
		|				ELSE 0
		|			END) AS Won,
		|		SUM(CASE
		|				WHEN SalesOpportunitiesToCustomer.Status = VALUE(Enum.OpportunityStatuses.Lost)
		|					THEN 1
		|				ELSE 0
		|			END) AS WasLost
		|	FROM
		|		Catalog.SalesOpportunitiesToCustomer AS SalesOpportunitiesToCustomer
		|	WHERE
		|		(NOT SalesOpportunitiesToCustomer.DeletionMark)
		|		AND SalesOpportunitiesToCustomer.Closed_
		|		AND SalesOpportunitiesToCustomer.EndDate BETWEEN &BeginOfPeriod AND &PeriodEnding
		|		AND SalesOpportunitiesToCustomer.EmployeeResponsible IN
		|			(SELECT
		|				FilterByManagers.Ref
		|			FROM
		|				FilterByManagers AS FilterByManagers)
		|	
		|	GROUP BY
		|		CASE
		|			WHEN SalesOpportunitiesToCustomer.EmployeeResponsible = VALUE(Catalog.Users.EmptyRef)
		|				THEN &NotSpecified
		|			ELSE SalesOpportunitiesToCustomer.EmployeeResponsible
		|		END) AS NestedQuery
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT ALLOWED
		|	NestedQuery.Manager,
		|	NestedQuery.Won AS WonDeals,
		|	NestedQuery.WasLost AS LostDeals,
		|	CASE
		|		WHEN NestedQuery.Won + NestedQuery.WasLost = 0
		|			THEN 0
		|		ELSE NestedQuery.Won / (NestedQuery.Won + NestedQuery.WasLost) * 100
		|	END AS ShareOfDealsWon
		|INTO TransactionEfficiencyPrevious
		|FROM
		|	(SELECT
		|		CASE
		|			WHEN SalesOpportunitiesToCustomer.EmployeeResponsible = VALUE(Catalog.Users.EmptyRef)
		|				THEN &NotSpecified
		|			ELSE SalesOpportunitiesToCustomer.EmployeeResponsible
		|		END AS Manager,
		|		SUM(CASE
		|				WHEN SalesOpportunitiesToCustomer.Status = VALUE(Enum.OpportunityStatuses.Won)
		|					THEN 1
		|				ELSE 0
		|			END) AS Won,
		|		SUM(CASE
		|				WHEN SalesOpportunitiesToCustomer.Status = VALUE(Enum.OpportunityStatuses.Lost)
		|					THEN 1
		|				ELSE 0
		|			END) AS WasLost
		|	FROM
		|		Catalog.SalesOpportunitiesToCustomer AS SalesOpportunitiesToCustomer
		|	WHERE
		|		(NOT SalesOpportunitiesToCustomer.DeletionMark)
		|		AND SalesOpportunitiesToCustomer.Closed_
		|		AND SalesOpportunitiesToCustomer.EndDate BETWEEN &StartDateAdditionalPeriod AND &EndDateAdditionalPeriod
		|		AND SalesOpportunitiesToCustomer.EmployeeResponsible IN
		|			(SELECT
		|				FilterByManagers.Ref
		|			FROM
		|				FilterByManagers AS FilterByManagers)
	|	
		|	GROUP BY
		|		CASE
		|			WHEN SalesOpportunitiesToCustomer.EmployeeResponsible = VALUE(Catalog.Users.EmptyRef)
		|				THEN &NotSpecified
		|			ELSE SalesOpportunitiesToCustomer.EmployeeResponsible
		|		END) AS NestedQuery
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|
		|SELECT
		|	ISNULL(EfficiencyOfTransactionsCur.Manager, TransactionEfficiencyPrevious.Manager) AS Manager,
		|	ISNULL(EfficiencyOfTransactionsCur.WonDeals, 0) AS WonDealsCur,
		|	ISNULL(EfficiencyOfTransactionsCur.LostDeals, 0) AS LostTradesCur,
		|	ISNULL(EfficiencyOfTransactionsCur.ShareOfDealsWon, 0) AS ShareOfDealsWonCur,
		|	ISNULL(TransactionEfficiencyPrevious.WonDeals, 0) AS WonDealsPrevious,
		|	ISNULL(TransactionEfficiencyPrevious.LostDeals, 0) AS LostTradesPrevious,
		|	ISNULL(TransactionEfficiencyPrevious.ShareOfDealsWon, 0) AS ShareOfDealsWonPrevious
		|FROM
		|	EfficiencyOfTransactionsCur AS EfficiencyOfTransactionsCur
		|FULL JOIN TransactionEfficiencyPrevious AS TransactionEfficiencyPrevious
		|	ON EfficiencyOfTransactionsCur.Manager = TransactionEfficiencyPrevious.Manager
		|
		|ORDER BY
		|	ShareOfDealsWonCur,
		|	WonDealsCur,
		|	LostTradesCur DESC
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|";
		
	Else
		
		MatchingRequestsData.Insert("EfficiencyOfOpportunityManagement",LastPacketNumber + 1);
		LastPacketNumber = LastPacketNumber + 1;
		
		Return "SELECT ALLOWED
		|	NestedQuery.Manager,
		|	NestedQuery.Won AS WonDeals,
		|	NestedQuery.WasLost AS LostDeals,
		|	CASE
		|		WHEN NestedQuery.Won + NestedQuery.WasLost = 0
		|			THEN 0
		|		ELSE NestedQuery.Won / (NestedQuery.Won + NestedQuery.WasLost) * 100
		|	END AS ShareOfDealsWon
		|FROM
		|	(SELECT
		|		CASE
		|			WHEN SalesOpportunitiesToCustomer.EmployeeResponsible = VALUE(Catalog.Users.EmptyRef)
		|				THEN &NotSpecified
		|			ELSE SalesOpportunitiesToCustomer.EmployeeResponsible
		|		END AS Manager,
		|		SUM(CASE
		|				WHEN SalesOpportunitiesToCustomer.Status = VALUE(Enum.OpportunityStatuses.Won)
		|					THEN 1
		|				ELSE 0
		|			END) AS Won,
		|		SUM(CASE
		|				WHEN SalesOpportunitiesToCustomer.Status = VALUE(Enum.OpportunityStatuses.Lost)
		|					THEN 1
		|				ELSE 0
		|			END) AS WasLost
		|	FROM
		|		Catalog.SalesOpportunitiesToCustomer AS SalesOpportunitiesToCustomer
		|	WHERE
		|		(NOT SalesOpportunitiesToCustomer.DeletionMark)
		|		AND SalesOpportunitiesToCustomer.Closed_
		|		AND SalesOpportunitiesToCustomer.EndDate BETWEEN &BeginOfPeriod AND &PeriodEnding
		|		AND SalesOpportunitiesToCustomer.EmployeeResponsible IN
		|			(SELECT
		|				FilterByManagers.Ref
		|			FROM
		|				FilterByManagers AS FilterByManagers)
		|	
		|	GROUP BY
		|		CASE
		|			WHEN SalesOpportunitiesToCustomer.EmployeeResponsible = VALUE(Catalog.Users.EmptyRef)
		|				THEN &NotSpecified
		|			ELSE SalesOpportunitiesToCustomer.EmployeeResponsible
		|		END) AS NestedQuery
		|
		|ORDER BY
		|	ShareOfDealsWon,
		|	WonDeals,
		|	LostDeals DESC
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|";
		
	EndIf;
	
EndFunction

Function RequestTextForEffectiveInteractions(MatchingRequestsData,LastPacketNumber, StructureOfReportGenerationPeriods)
	
	If StructureOfReportGenerationPeriods.ThereIsExtraPeriod Then
		
		MatchingRequestsData.Insert("InteractionEfficiency",LastPacketNumber + 7);
		LastPacketNumber = LastPacketNumber + 7;
		
		Return "SELECT ALLOWED
		        |	NestedQuery.EmployeeResponsible AS Manager,
		        |	SUM(NestedQuery.Ref) AS OtherItems
		        |INTO OtherInteractions
		        |FROM
		        |	(SELECT
		        |		OutgoingEmail.EmployeeResponsible AS EmployeeResponsible,
		        |		COUNT(DISTINCT OutgoingEmail.Ref) AS Ref
		        |	FROM
		        |		Document.OutgoingEmail AS OutgoingEmail
		        |			LEFT JOIN InformationRegister.InteractionsFolderSubjects AS InteractionsFolderSubjects
		        |			ON (InteractionsFolderSubjects.Interaction = OutgoingEmail.Ref)
		        |	WHERE
		        |		NOT InteractionsFolderSubjects.SubjectOf REFS Catalog.SalesOpportunitiesToCustomer
		        |		AND NOT OutgoingEmail.DeletionMark
		        |		AND OutgoingEmail.Date BETWEEN &BeginOfPeriod AND &PeriodEnding
		        |		AND OutgoingEmail.EmailStatus = VALUE(Enum.OutgoingEmailStatuses.Sent)
		        |		AND OutgoingEmail.EmployeeResponsible IN
		        |				(SELECT
		        |					FilterByManagers.Ref
		        |				FROM
		        |					FilterByManagers AS FilterByManagers)
		        |	
		        |	GROUP BY
		        |		OutgoingEmail.EmployeeResponsible
		        |	
		        |	UNION ALL
		        |	
		        |	SELECT
		        |		IncomingEmail.EmployeeResponsible,
		        |		COUNT(DISTINCT IncomingEmail.Ref)
		        |	FROM
		        |		Document.IncomingEmail AS IncomingEmail
		        |			LEFT JOIN InformationRegister.InteractionsFolderSubjects AS InteractionsFolderSubjects
		        |			ON (InteractionsFolderSubjects.Interaction = IncomingEmail.Ref)
		        |	WHERE
		        |		NOT InteractionsFolderSubjects.SubjectOf REFS Catalog.SalesOpportunitiesToCustomer
		        |		AND NOT IncomingEmail.DeletionMark
		        |		AND IncomingEmail.Date BETWEEN &BeginOfPeriod AND &PeriodEnding
		        |		AND IncomingEmail.EmployeeResponsible IN
		        |				(SELECT
		        |					FilterByManagers.Ref
		        |				FROM
		        |					FilterByManagers AS FilterByManagers)
		        |	
		        |	GROUP BY
		        |		IncomingEmail.EmployeeResponsible
		        |	
		        |	UNION ALL
		        |	
		        |	SELECT
		        |		PhoneCall.EmployeeResponsible,
		        |		COUNT(DISTINCT PhoneCall.Ref)
		        |	FROM
		        |		Document.PhoneCall AS PhoneCall
		        |			LEFT JOIN InformationRegister.InteractionsFolderSubjects AS InteractionsFolderSubjects
		        |			ON (InteractionsFolderSubjects.Interaction = PhoneCall.Ref)
		        |	WHERE
		        |		NOT InteractionsFolderSubjects.SubjectOf REFS Catalog.SalesOpportunitiesToCustomer
		        |		AND NOT PhoneCall.DeletionMark
		        |		AND PhoneCall.Date BETWEEN &BeginOfPeriod AND &PeriodEnding
		        |		AND PhoneCall.EmployeeResponsible IN
		        |				(SELECT
		        |					FilterByManagers.Ref
		        |				FROM
		        |					FilterByManagers AS FilterByManagers)
		        |	
		        |	GROUP BY
		        |		PhoneCall.EmployeeResponsible
		        |	
		        |	UNION ALL
		        |	
		        |	SELECT
		        |		Meeting.EmployeeResponsible,
		        |		COUNT(DISTINCT Meeting.Ref)
		        |	FROM
		        |		Document.Meeting AS Meeting
		        |			LEFT JOIN InformationRegister.InteractionsFolderSubjects AS InteractionsFolderSubjects
		        |			ON (InteractionsFolderSubjects.Interaction = Meeting.Ref)
		        |	WHERE
		        |		NOT InteractionsFolderSubjects.SubjectOf REFS Catalog.SalesOpportunitiesToCustomer
		        |		AND NOT Meeting.DeletionMark
		        |		AND Meeting.Date BETWEEN &BeginOfPeriod AND &PeriodEnding
		        |		AND Meeting.EmployeeResponsible IN
		        |				(SELECT
		        |					FilterByManagers.Ref
		        |				FROM
		        |					FilterByManagers AS FilterByManagers)
		        |	
		        |	GROUP BY
		        |		Meeting.EmployeeResponsible) AS NestedQuery
		        |
		        |GROUP BY
		        |	NestedQuery.EmployeeResponsible
		        |;
		        |
		        |////////////////////////////////////////////////////////////////////////////////
		        |SELECT ALLOWED
		        |	NestedQuery.EmployeeResponsible AS Manager,
		        |	SUM(NestedQuery.Won) AS Won
		        |INTO TransactionInteractions
		        |FROM
		        |	(SELECT
		        |		OutgoingEmail.EmployeeResponsible AS EmployeeResponsible,
		        |		SUM(CASE
		        |				WHEN SalesOpportunitiesToCustomer.Status = VALUE(Enum.OpportunityStatuses.Won)
		        |					THEN 1
		        |				ELSE 0
		        |			END) AS Won,
		        |		SUM(CASE
		        |				WHEN SalesOpportunitiesToCustomer.Status = VALUE(Enum.OpportunityStatuses.Lost)
		        |					THEN 1
		        |				ELSE 0
		        |			END) AS Lost
		        |	FROM
		        |		Document.OutgoingEmail AS OutgoingEmail
		        |			LEFT JOIN InformationRegister.InteractionsFolderSubjects AS InteractionsFolderSubjects
		        |				LEFT JOIN Catalog.SalesOpportunitiesToCustomer AS SalesOpportunitiesToCustomer
		        |				ON (SalesOpportunitiesToCustomer.Ref = InteractionsFolderSubjects.SubjectOf)
		        |			ON (InteractionsFolderSubjects.Interaction = OutgoingEmail.Ref)
		        |	WHERE
		        |		InteractionsFolderSubjects.SubjectOf REFS Catalog.SalesOpportunitiesToCustomer
		        |		AND NOT OutgoingEmail.DeletionMark
		        |		AND OutgoingEmail.Date BETWEEN &BeginOfPeriod AND &PeriodEnding
		        |		AND OutgoingEmail.EmailStatus = VALUE(Enum.OutgoingEmailStatuses.Sent)
		        |		AND NOT SalesOpportunitiesToCustomer.DeletionMark
		        |		AND SalesOpportunitiesToCustomer.Closed_
		        |		AND OutgoingEmail.EmployeeResponsible IN
		        |				(SELECT
		        |					FilterByManagers.Ref
		        |				FROM
		        |					FilterByManagers AS FilterByManagers)
		        |	
		        |	GROUP BY
		        |		OutgoingEmail.EmployeeResponsible
		        |	
		        |	UNION ALL
		        |	
		        |	SELECT
		        |		IncomingEmail.EmployeeResponsible,
		        |		CASE
		        |			WHEN SalesOpportunitiesToCustomer.Status = VALUE(Enum.OpportunityStatuses.Won)
		        |				THEN 1
		        |			ELSE 0
		        |		END,
		        |		CASE
		        |			WHEN SalesOpportunitiesToCustomer.Status = VALUE(Enum.OpportunityStatuses.Lost)
		        |				THEN 1
		        |			ELSE 0
		        |		END
		        |	FROM
		        |		Document.IncomingEmail AS IncomingEmail
		        |			LEFT JOIN InformationRegister.InteractionsFolderSubjects AS InteractionsFolderSubjects
		        |				LEFT JOIN Catalog.SalesOpportunitiesToCustomer AS SalesOpportunitiesToCustomer
		        |				ON (SalesOpportunitiesToCustomer.Ref = InteractionsFolderSubjects.SubjectOf)
		        |			ON (InteractionsFolderSubjects.Interaction = IncomingEmail.Ref)
		        |	WHERE
		        |		InteractionsFolderSubjects.SubjectOf REFS Catalog.SalesOpportunitiesToCustomer
		        |		AND NOT IncomingEmail.DeletionMark
		        |		AND IncomingEmail.Date BETWEEN &BeginOfPeriod AND &PeriodEnding
		        |		AND NOT SalesOpportunitiesToCustomer.DeletionMark
		        |		AND SalesOpportunitiesToCustomer.Closed_
		        |		AND IncomingEmail.EmployeeResponsible IN
		        |				(SELECT
		        |					FilterByManagers.Ref
		        |				FROM
		        |					FilterByManagers AS FilterByManagers)
		        |	
		        |	UNION ALL
		        |	
		        |	SELECT
		        |		PhoneCall.EmployeeResponsible,
		        |		CASE
		        |			WHEN SalesOpportunitiesToCustomer.Status = VALUE(Enum.OpportunityStatuses.Won)
		        |				THEN 1
		        |			ELSE 0
		        |		END,
		        |		CASE
		        |			WHEN SalesOpportunitiesToCustomer.Status = VALUE(Enum.OpportunityStatuses.Lost)
		        |				THEN 1
		        |			ELSE 0
		        |		END
		        |	FROM
		        |		Document.PhoneCall AS PhoneCall
		        |			LEFT JOIN InformationRegister.InteractionsFolderSubjects AS InteractionsFolderSubjects
		        |				LEFT JOIN Catalog.SalesOpportunitiesToCustomer AS SalesOpportunitiesToCustomer
		        |				ON (SalesOpportunitiesToCustomer.Ref = InteractionsFolderSubjects.SubjectOf)
		        |			ON (InteractionsFolderSubjects.Interaction = PhoneCall.Ref)
		        |	WHERE
		        |		InteractionsFolderSubjects.SubjectOf REFS Catalog.SalesOpportunitiesToCustomer
		        |		AND NOT PhoneCall.DeletionMark
		        |		AND PhoneCall.Date BETWEEN &BeginOfPeriod AND &PeriodEnding
		        |		AND NOT SalesOpportunitiesToCustomer.DeletionMark
		        |		AND SalesOpportunitiesToCustomer.Closed_
		        |		AND PhoneCall.EmployeeResponsible IN
		        |				(SELECT
		        |					FilterByManagers.Ref
		        |				FROM
		        |					FilterByManagers AS FilterByManagers)
		        |	
		        |	UNION ALL
		        |	
		        |	SELECT
		        |		Meeting.EmployeeResponsible,
		        |		CASE
		        |			WHEN SalesOpportunitiesToCustomer.Status = VALUE(Enum.OpportunityStatuses.Won)
		        |				THEN 1
		        |			ELSE 0
		        |		END,
		        |		CASE
		        |			WHEN SalesOpportunitiesToCustomer.Status = VALUE(Enum.OpportunityStatuses.Lost)
		        |				THEN 1
		        |			ELSE 0
		        |		END
		        |	FROM
		        |		Document.Meeting AS Meeting
		        |			LEFT JOIN InformationRegister.InteractionsFolderSubjects AS InteractionsFolderSubjects
		        |				LEFT JOIN Catalog.SalesOpportunitiesToCustomer AS SalesOpportunitiesToCustomer
		        |				ON (SalesOpportunitiesToCustomer.Ref = InteractionsFolderSubjects.SubjectOf)
		        |			ON (InteractionsFolderSubjects.Interaction = Meeting.Ref)
		        |	WHERE
		        |		InteractionsFolderSubjects.SubjectOf REFS Catalog.SalesOpportunitiesToCustomer
		        |		AND NOT Meeting.DeletionMark
		        |		AND Meeting.Date BETWEEN &BeginOfPeriod AND &PeriodEnding
		        |		AND NOT SalesOpportunitiesToCustomer.DeletionMark
		        |		AND SalesOpportunitiesToCustomer.Closed_
		        |		AND Meeting.EmployeeResponsible IN
		        |				(SELECT
		        |					FilterByManagers.Ref
		        |				FROM
		        |					FilterByManagers AS FilterByManagers)) AS NestedQuery
		        |
		        |GROUP BY
		        |	NestedQuery.EmployeeResponsible
		        |;
		        |
		        |////////////////////////////////////////////////////////////////////////////////
		        |SELECT
		        |	NestedQuery.Manager,
		        |	NestedQuery.Won,
		        |	NestedQuery.Lost,
		        |	NestedQuery.OtherItems,
		        |	CASE
		        |		WHEN NestedQuery.Won + NestedQuery.Lost + NestedQuery.OtherItems = 0
		        |			THEN 0
		        |		ELSE NestedQuery.Won / (NestedQuery.Won + NestedQuery.Lost + NestedQuery.OtherItems) * 100
		        |	END AS ShareOfWinnings
		        |INTO EffectivenessOfInteractionsCurPeriod
		        |FROM
		        |	(SELECT
		        |		CASE
		        |			WHEN NestedQuery.Manager = VALUE(Catalog.Users.EmptyRef)
		        |				THEN &NotSpecified
		        |			ELSE NestedQuery.Manager
		        |		END AS Manager,
		        |		SUM(NestedQuery.Won) AS Won,
		        |		SUM(NestedQuery.Lost) AS Lost,
		        |		SUM(NestedQuery.OtherItems) AS OtherItems
		        |	FROM
		        |		(SELECT
		        |			TransactionInteractions.Manager AS Manager,
		        |			TransactionInteractions.Won AS Won,
		        |			NULL AS Lost,
		        |			0 AS OtherItems
		        |		FROM
		        |			TransactionInteractions AS TransactionInteractions
		        |		
		        |		UNION ALL
		        |		
		        |		SELECT
		        |			OtherInteractions.Manager,
		        |			0,
		        |			0,
		        |			OtherInteractions.OtherItems
		        |		FROM
		        |			OtherInteractions AS OtherInteractions) AS NestedQuery
		        |	
		        |	GROUP BY
		        |		CASE
		        |			WHEN NestedQuery.Manager = VALUE(Catalog.Users.EmptyRef)
		        |				THEN &NotSpecified
		        |			ELSE NestedQuery.Manager
		        |		END) AS NestedQuery
		        |;
		        |
		        |////////////////////////////////////////////////////////////////////////////////
		        |SELECT ALLOWED
		        |	NestedQuery.EmployeeResponsible AS Manager,
		        |	SUM(NestedQuery.Ref) AS OtherItems
		        |INTO OtherInteractionsPriorPeriod
		        |FROM
		        |	(SELECT
		        |		OutgoingEmail.EmployeeResponsible AS EmployeeResponsible,
		        |		COUNT(DISTINCT OutgoingEmail.Ref) AS Ref
		        |	FROM
		        |		Document.OutgoingEmail AS OutgoingEmail
		        |			LEFT JOIN InformationRegister.InteractionsFolderSubjects AS InteractionsFolderSubjects
		        |			ON (InteractionsFolderSubjects.Interaction = OutgoingEmail.Ref)
		        |	WHERE
		        |		NOT InteractionsFolderSubjects.SubjectOf REFS Catalog.SalesOpportunitiesToCustomer
		        |		AND NOT OutgoingEmail.DeletionMark
		        |		AND OutgoingEmail.Date BETWEEN &StartDateAdditionalPeriod AND &EndDateAdditionalPeriod
		        |		AND OutgoingEmail.EmailStatus = VALUE(Enum.OutgoingEmailStatuses.Sent)
		        |		AND OutgoingEmail.EmployeeResponsible IN
		        |				(SELECT
		        |					FilterByManagers.Ref
		        |				FROM
		        |					FilterByManagers AS FilterByManagers)
		        |	
		        |	GROUP BY
		        |		OutgoingEmail.EmployeeResponsible
		        |	
		        |	UNION ALL
		        |	
		        |	SELECT
		        |		IncomingEmail.EmployeeResponsible,
		        |		COUNT(DISTINCT IncomingEmail.Ref)
		        |	FROM
		        |		Document.IncomingEmail AS IncomingEmail
		        |			LEFT JOIN InformationRegister.InteractionsFolderSubjects AS InteractionsFolderSubjects
		        |			ON (InteractionsFolderSubjects.Interaction = IncomingEmail.Ref)
		        |	WHERE
		        |		NOT InteractionsFolderSubjects.SubjectOf REFS Catalog.SalesOpportunitiesToCustomer
		        |		AND NOT IncomingEmail.DeletionMark
		        |		AND IncomingEmail.Date BETWEEN &StartDateAdditionalPeriod AND &EndDateAdditionalPeriod
		        |		AND IncomingEmail.EmployeeResponsible IN
		        |				(SELECT
		        |					FilterByManagers.Ref
		        |				FROM
		        |					FilterByManagers AS FilterByManagers)
		        |	
		        |	GROUP BY
		        |		IncomingEmail.EmployeeResponsible
		        |	
		        |	UNION ALL
		        |	
		        |	SELECT
		        |		PhoneCall.EmployeeResponsible,
		        |		COUNT(DISTINCT PhoneCall.Ref)
		        |	FROM
		        |		Document.PhoneCall AS PhoneCall
		        |			LEFT JOIN InformationRegister.InteractionsFolderSubjects AS InteractionsFolderSubjects
		        |			ON (InteractionsFolderSubjects.Interaction = PhoneCall.Ref)
		        |	WHERE
		        |		NOT InteractionsFolderSubjects.SubjectOf REFS Catalog.SalesOpportunitiesToCustomer
		        |		AND NOT PhoneCall.DeletionMark
		        |		AND PhoneCall.Date BETWEEN &StartDateAdditionalPeriod AND &EndDateAdditionalPeriod
		        |		AND PhoneCall.EmployeeResponsible IN
		        |				(SELECT
		        |					FilterByManagers.Ref
		        |				FROM
		        |					FilterByManagers AS FilterByManagers)
		        |	
		        |	GROUP BY
		        |		PhoneCall.EmployeeResponsible
		        |	
		        |	UNION ALL
		        |	
		        |	SELECT
		        |		Meeting.EmployeeResponsible,
		        |		COUNT(DISTINCT Meeting.Ref)
		        |	FROM
		        |		Document.Meeting AS Meeting
		        |			LEFT JOIN InformationRegister.InteractionsFolderSubjects AS InteractionsFolderSubjects
		        |			ON (InteractionsFolderSubjects.Interaction = Meeting.Ref)
		        |	WHERE
		        |		NOT InteractionsFolderSubjects.SubjectOf REFS Catalog.SalesOpportunitiesToCustomer
		        |		AND NOT Meeting.DeletionMark
		        |		AND Meeting.Date BETWEEN &StartDateAdditionalPeriod AND &EndDateAdditionalPeriod
		        |		AND Meeting.EmployeeResponsible IN
		        |				(SELECT
		        |					FilterByManagers.Ref
		        |				FROM
		        |					FilterByManagers AS FilterByManagers)
		        |	
		        |	GROUP BY
		        |		Meeting.EmployeeResponsible) AS NestedQuery
		        |
		        |GROUP BY
		        |	NestedQuery.EmployeeResponsible
		        |;
		        |
		        |////////////////////////////////////////////////////////////////////////////////
		        |SELECT ALLOWED
		        |	NestedQuery.EmployeeResponsible AS Manager,
		        |	SUM(NestedQuery.Won) AS Won,
		        |	SUM(NestedQuery.Lost) AS Lost
		        |INTO InteractionsOnTransactionsPreviousPeriod
		        |FROM
		        |	(SELECT
		        |		OutgoingEmail.EmployeeResponsible AS EmployeeResponsible,
		        |		SUM(CASE
		        |				WHEN SalesOpportunitiesToCustomer.Status = VALUE(Enum.OpportunityStatuses.Won)
		        |					THEN 1
		        |				ELSE 0
		        |			END) AS Won,
		        |		SUM(CASE
		        |				WHEN SalesOpportunitiesToCustomer.Status = VALUE(Enum.OpportunityStatuses.Lost)
		        |					THEN 1
		        |				ELSE 0
		        |			END) AS Lost
		        |	FROM
		        |		Document.OutgoingEmail AS OutgoingEmail
		        |			LEFT JOIN InformationRegister.InteractionsFolderSubjects AS InteractionsFolderSubjects
		        |			ON (InteractionsFolderSubjects.Interaction = OutgoingEmail.Ref)
		        |			LEFT JOIN Catalog.SalesOpportunitiesToCustomer AS SalesOpportunitiesToCustomer
		        |			ON (InteractionsFolderSubjects.SubjectOf = SalesOpportunitiesToCustomer.Ref)
		        |	WHERE
		        |		InteractionsFolderSubjects.SubjectOf REFS Catalog.SalesOpportunitiesToCustomer
		        |		AND NOT OutgoingEmail.DeletionMark
		        |		AND OutgoingEmail.Date BETWEEN &StartDateAdditionalPeriod AND &EndDateAdditionalPeriod
		        |		AND OutgoingEmail.EmailStatus = VALUE(Enum.OutgoingEmailStatuses.Sent)
		        |		AND NOT SalesOpportunitiesToCustomer.DeletionMark
		        |		AND SalesOpportunitiesToCustomer.Closed_
		        |		AND OutgoingEmail.EmployeeResponsible IN
		        |				(SELECT
		        |					FilterByManagers.Ref
		        |				FROM
		        |					FilterByManagers AS FilterByManagers)
		        |	
		        |	GROUP BY
		        |		OutgoingEmail.EmployeeResponsible
		        |	
		        |	UNION ALL
		        |	
		        |	SELECT
		        |		IncomingEmail.EmployeeResponsible,
		        |		CASE
		        |			WHEN SalesOpportunitiesToCustomer.Status = VALUE(Enum.OpportunityStatuses.Won)
		        |				THEN 1
		        |			ELSE 0
		        |		END,
		        |		CASE
		        |			WHEN SalesOpportunitiesToCustomer.Status = VALUE(Enum.OpportunityStatuses.Lost)
		        |				THEN 1
		        |			ELSE 0
		        |		END
		        |	FROM
		        |		Document.IncomingEmail AS IncomingEmail
		        |			LEFT JOIN InformationRegister.InteractionsFolderSubjects AS InteractionsFolderSubjects
		        |			ON (InteractionsFolderSubjects.Interaction = IncomingEmail.Ref)
		        |			LEFT JOIN Catalog.SalesOpportunitiesToCustomer AS SalesOpportunitiesToCustomer
		        |			ON (InteractionsFolderSubjects.SubjectOf = SalesOpportunitiesToCustomer.Ref)
		        |	WHERE
		        |		InteractionsFolderSubjects.SubjectOf REFS Catalog.SalesOpportunitiesToCustomer
		        |		AND NOT IncomingEmail.DeletionMark
		        |		AND IncomingEmail.Date BETWEEN &StartDateAdditionalPeriod AND &EndDateAdditionalPeriod
		        |		AND NOT SalesOpportunitiesToCustomer.DeletionMark
		        |		AND SalesOpportunitiesToCustomer.Closed_
		        |		AND IncomingEmail.EmployeeResponsible IN
		        |				(SELECT
		        |					FilterByManagers.Ref
		        |				FROM
		        |					FilterByManagers AS FilterByManagers)
		        |	
		        |	UNION ALL
		        |	
		        |	SELECT
		        |		PhoneCall.EmployeeResponsible,
		        |		CASE
		        |			WHEN SalesOpportunitiesToCustomer.Status = VALUE(Enum.OpportunityStatuses.Won)
		        |				THEN 1
		        |			ELSE 0
		        |		END,
		        |		CASE
		        |			WHEN SalesOpportunitiesToCustomer.Status = VALUE(Enum.OpportunityStatuses.Lost)
		        |				THEN 1
		        |			ELSE 0
		        |		END
		        |	FROM
		        |		Document.PhoneCall AS PhoneCall
		        |			LEFT JOIN InformationRegister.InteractionsFolderSubjects AS InteractionsFolderSubjects
		        |			ON (InteractionsFolderSubjects.Interaction = PhoneCall.Ref)
		        |			LEFT JOIN Catalog.SalesOpportunitiesToCustomer AS SalesOpportunitiesToCustomer
		        |			ON (InteractionsFolderSubjects.SubjectOf = SalesOpportunitiesToCustomer.Ref)
		        |	WHERE
		        |		InteractionsFolderSubjects.SubjectOf REFS Catalog.SalesOpportunitiesToCustomer
		        |		AND NOT PhoneCall.DeletionMark
		        |		AND PhoneCall.Date BETWEEN &StartDateAdditionalPeriod AND &EndDateAdditionalPeriod
		        |		AND NOT SalesOpportunitiesToCustomer.DeletionMark
		        |		AND SalesOpportunitiesToCustomer.Closed_
		        |		AND PhoneCall.EmployeeResponsible IN
		        |				(SELECT
		        |					FilterByManagers.Ref
		        |				FROM
		        |					FilterByManagers AS FilterByManagers)
		        |	
		        |	UNION ALL
		        |	
		        |	SELECT
		        |		Meeting.EmployeeResponsible,
		        |		CASE
		        |			WHEN SalesOpportunitiesToCustomer.Status = VALUE(Enum.OpportunityStatuses.Won)
		        |				THEN 1
		        |			ELSE 0
		        |		END,
		        |		CASE
		        |			WHEN SalesOpportunitiesToCustomer.Status = VALUE(Enum.OpportunityStatuses.Lost)
		        |				THEN 1
		        |			ELSE 0
		        |		END
		        |	FROM
		        |		Document.Meeting AS Meeting
		        |			LEFT JOIN InformationRegister.InteractionsFolderSubjects AS InteractionsFolderSubjects
		        |			ON (InteractionsFolderSubjects.Interaction = Meeting.Ref)
		        |			LEFT JOIN Catalog.SalesOpportunitiesToCustomer AS SalesOpportunitiesToCustomer
		        |			ON (InteractionsFolderSubjects.SubjectOf = SalesOpportunitiesToCustomer.Ref)
		        |	WHERE
		        |		InteractionsFolderSubjects.SubjectOf REFS Catalog.SalesOpportunitiesToCustomer
		        |		AND NOT Meeting.DeletionMark
		        |		AND Meeting.Date BETWEEN &StartDateAdditionalPeriod AND &EndDateAdditionalPeriod
		        |		AND NOT SalesOpportunitiesToCustomer.DeletionMark
		        |		AND SalesOpportunitiesToCustomer.Closed_
		        |		AND Meeting.EmployeeResponsible IN
		        |				(SELECT
		        |					FilterByManagers.Ref
		        |				FROM
		        |					FilterByManagers AS FilterByManagers)) AS NestedQuery
		        |
		        |GROUP BY
		        |	NestedQuery.EmployeeResponsible
		        |;
		        |
		        |////////////////////////////////////////////////////////////////////////////////
		        |SELECT
		        |	NestedQuery.Manager,
		        |	NestedQuery.Won,
		        |	NestedQuery.Lost,
		        |	NestedQuery.OtherItems,
		        |	CASE
		        |		WHEN NestedQuery.Won + NestedQuery.Lost + NestedQuery.OtherItems = 0
		        |			THEN 0
		        |		ELSE NestedQuery.Won / (NestedQuery.Won + NestedQuery.Lost + NestedQuery.OtherItems) * 100
		        |	END AS ShareOfWinnings
		        |INTO EffectivenessOfInteractionsPreviousPeriod
		        |FROM
		        |	(SELECT
		        |		CASE
		        |			WHEN NestedQuery.Manager = VALUE(Catalog.Users.EmptyRef)
		        |				THEN &NotSpecified
		        |			ELSE NestedQuery.Manager
		        |		END AS Manager,
		        |		SUM(NestedQuery.Won) AS Won,
		        |		SUM(NestedQuery.Lost) AS Lost,
		        |		SUM(NestedQuery.OtherItems) AS OtherItems
		        |	FROM
		        |		(SELECT
		        |			TransactionInteractions.Manager AS Manager,
		        |			TransactionInteractions.Won AS Won,
		        |			TransactionInteractions.Lost AS Lost,
		        |			0 AS OtherItems
		        |		FROM
		        |			InteractionsOnTransactionsPreviousPeriod AS TransactionInteractions
		        |		
		        |		UNION ALL
		        |		
		        |		SELECT
		        |			OtherInteractions.Manager,
		        |			0,
		        |			0,
		        |			OtherInteractions.OtherItems
		        |		FROM
		        |			OtherInteractionsPriorPeriod AS OtherInteractions) AS NestedQuery
		        |	
		        |	GROUP BY
		        |		CASE
		        |			WHEN NestedQuery.Manager = VALUE(Catalog.Users.EmptyRef)
		        |				THEN &NotSpecified
		        |			ELSE NestedQuery.Manager
		        |		END) AS NestedQuery
		        |;
		        |
		        |////////////////////////////////////////////////////////////////////////////////
		        |SELECT
		        |	ISNULL(EffectivenessOfInteractionsCurPeriod.Manager, EffectivenessOfInteractionsPreviousPeriod.Manager) AS Manager,
		        |	ISNULL(EffectivenessOfInteractionsCurPeriod.Won, 0) AS InteractionsOnWonDealsCur,
		        |	ISNULL(EffectivenessOfInteractionsCurPeriod.Lost, 0) AS InteractionsOnLostTradesCur,
		        |	ISNULL(EffectivenessOfInteractionsCurPeriod.OtherItems, 0) AS OtherInteractionsCur,
		        |	ISNULL(EffectivenessOfInteractionsCurPeriod.ShareOfWinnings, 0) AS ShareOfInteractionsOnWonTransactionsCur,
		        |	ISNULL(EffectivenessOfInteractionsPreviousPeriod.Won, 0) AS InteractionsOnWonDeals,
		        |	ISNULL(EffectivenessOfInteractionsPreviousPeriod.Lost, 0) AS InteractionsOnLostTradesPrevious,
		        |	ISNULL(EffectivenessOfInteractionsPreviousPeriod.OtherItems, 0) AS OtherInteractionsPrevious,
		        |	ISNULL(EffectivenessOfInteractionsPreviousPeriod.ShareOfWinnings, 0) AS ShareOfInteractionsOnWonTransactionsPrevious
		        |FROM
		        |	EffectivenessOfInteractionsCurPeriod AS EffectivenessOfInteractionsCurPeriod
		        |		FULL JOIN EffectivenessOfInteractionsPreviousPeriod AS EffectivenessOfInteractionsPreviousPeriod
		        |		ON EffectivenessOfInteractionsCurPeriod.Manager = EffectivenessOfInteractionsPreviousPeriod.Manager
		        |
		        |ORDER BY
		        |	ShareOfInteractionsOnWonTransactionsCur,
		        |	InteractionsOnWonDealsCur
		        |;
		        |
		        |////////////////////////////////////////////////////////////////////////////////
		        |";
		
	Else
		
		MatchingRequestsData.Insert("InteractionEfficiency",LastPacketNumber + 3);
		LastPacketNumber = LastPacketNumber + 3;
		
		Return "SELECT ALLOWED
		        |	NestedQuery.EmployeeResponsible AS Manager,
		        |	SUM(NestedQuery.Ref) AS OtherItems
		        |INTO OtherInteractions
		        |FROM
		        |	(SELECT
		        |		OutgoingEmail.EmployeeResponsible AS EmployeeResponsible,
		        |		COUNT(DISTINCT OutgoingEmail.Ref) AS Ref
		        |	FROM
		        |		Document.OutgoingEmail AS OutgoingEmail
		        |			LEFT JOIN InformationRegister.InteractionsFolderSubjects AS InteractionsFolderSubjects
		        |			ON (InteractionsFolderSubjects.Interaction = OutgoingEmail.Ref)
		        |	WHERE
		        |		NOT InteractionsFolderSubjects.SubjectOf REFS Catalog.SalesOpportunitiesToCustomer
		        |		AND NOT OutgoingEmail.DeletionMark
		        |		AND OutgoingEmail.Date BETWEEN &BeginOfPeriod AND &PeriodEnding
		        |		AND OutgoingEmail.EmailStatus = VALUE(Enum.OutgoingEmailStatuses.Sent)
		        |		AND OutgoingEmail.EmployeeResponsible IN
		        |				(SELECT
		        |					FilterByManagers.Ref
		        |				FROM
		        |					FilterByManagers AS FilterByManagers)
		        |	
		        |	GROUP BY
		        |		OutgoingEmail.EmployeeResponsible
		        |	
		        |	UNION ALL
		        |	
		        |	SELECT
		        |		IncomingEmail.EmployeeResponsible,
		        |		COUNT(DISTINCT IncomingEmail.Ref)
		        |	FROM
		        |		Document.IncomingEmail AS IncomingEmail
		        |			LEFT JOIN InformationRegister.InteractionsFolderSubjects AS InteractionsFolderSubjects
		        |			ON (InteractionsFolderSubjects.Interaction = IncomingEmail.Ref)
		        |	WHERE
		        |		NOT InteractionsFolderSubjects.SubjectOf REFS Catalog.SalesOpportunitiesToCustomer
		        |		AND NOT IncomingEmail.DeletionMark
		        |		AND IncomingEmail.Date BETWEEN &BeginOfPeriod AND &PeriodEnding
		        |		AND IncomingEmail.EmployeeResponsible IN
		        |				(SELECT
		        |					FilterByManagers.Ref
		        |				FROM
		        |					FilterByManagers AS FilterByManagers)
		        |	
		        |	GROUP BY
		        |		IncomingEmail.EmployeeResponsible
		        |	
		        |	UNION ALL
		        |	
		        |	SELECT
		        |		PhoneCall.EmployeeResponsible,
		        |		COUNT(DISTINCT PhoneCall.Ref)
		        |	FROM
		        |		Document.PhoneCall AS PhoneCall
		        |			LEFT JOIN InformationRegister.InteractionsFolderSubjects AS InteractionsFolderSubjects
		        |			ON (InteractionsFolderSubjects.Interaction = PhoneCall.Ref)
		        |	WHERE
		        |		NOT InteractionsFolderSubjects.SubjectOf REFS Catalog.SalesOpportunitiesToCustomer
		        |		AND NOT PhoneCall.DeletionMark
		        |		AND PhoneCall.Date BETWEEN &BeginOfPeriod AND &PeriodEnding
		        |		AND PhoneCall.EmployeeResponsible IN
		        |				(SELECT
		        |					FilterByManagers.Ref
		        |				FROM
		        |					FilterByManagers AS FilterByManagers)
		        |	
		        |	GROUP BY
		        |		PhoneCall.EmployeeResponsible
		        |	
		        |	UNION ALL
		        |	
		        |	SELECT
		        |		Meeting.EmployeeResponsible,
		        |		COUNT(DISTINCT Meeting.Ref)
		        |	FROM
		        |		Document.Meeting AS Meeting
		        |			LEFT JOIN InformationRegister.InteractionsFolderSubjects AS InteractionsFolderSubjects
		        |			ON (InteractionsFolderSubjects.Interaction = Meeting.Ref)
		        |	WHERE
		        |		NOT InteractionsFolderSubjects.SubjectOf REFS Catalog.SalesOpportunitiesToCustomer
		        |		AND NOT Meeting.DeletionMark
		        |		AND Meeting.Date BETWEEN &BeginOfPeriod AND &PeriodEnding
		        |		AND Meeting.EmployeeResponsible IN
		        |				(SELECT
		        |					FilterByManagers.Ref
		        |				FROM
		        |					FilterByManagers AS FilterByManagers)
		        |	
		        |	GROUP BY
		        |		Meeting.EmployeeResponsible) AS NestedQuery
		        |
		        |GROUP BY
		        |	NestedQuery.EmployeeResponsible
		        |;
		        |
		        |////////////////////////////////////////////////////////////////////////////////
		        |SELECT ALLOWED
		        |	NestedQuery.EmployeeResponsible AS Manager,
		        |	SUM(NestedQuery.Won) AS Won,
		        |	SUM(NestedQuery.Lost) AS Lost
		        |INTO TransactionInteractions
		        |FROM
		        |	(SELECT
		        |		OutgoingEmail.EmployeeResponsible AS EmployeeResponsible,
		        |		SUM(CASE
		        |				WHEN SalesOpportunitiesToCustomer.Status = VALUE(Enum.OpportunityStatuses.Won)
		        |					THEN 1
		        |				ELSE 0
		        |			END) AS Won,
		        |		SUM(CASE
		        |				WHEN SalesOpportunitiesToCustomer.Status = VALUE(Enum.OpportunityStatuses.Lost)
		        |					THEN 1
		        |				ELSE 0
		        |			END) AS Lost
		        |	FROM
		        |		Document.OutgoingEmail AS OutgoingEmail
		        |			LEFT JOIN InformationRegister.InteractionsFolderSubjects AS InteractionsFolderSubjects
		        |			ON (InteractionsFolderSubjects.Interaction = OutgoingEmail.Ref)
		        |			LEFT JOIN Catalog.SalesOpportunitiesToCustomer AS SalesOpportunitiesToCustomer
		        |			ON (InteractionsFolderSubjects.SubjectOf = SalesOpportunitiesToCustomer.Ref)
		        |	WHERE
		        |		InteractionsFolderSubjects.SubjectOf REFS Catalog.SalesOpportunitiesToCustomer
		        |		AND NOT OutgoingEmail.DeletionMark
		        |		AND OutgoingEmail.Date BETWEEN &BeginOfPeriod AND &PeriodEnding
		        |		AND OutgoingEmail.EmailStatus = VALUE(Enum.OutgoingEmailStatuses.Sent)
		        |		AND NOT SalesOpportunitiesToCustomer.DeletionMark
		        |		AND SalesOpportunitiesToCustomer.Closed_
		        |		AND OutgoingEmail.EmployeeResponsible IN
		        |				(SELECT
		        |					FilterByManagers.Ref
		        |				FROM
		        |					FilterByManagers AS FilterByManagers)
		        |	
		        |	GROUP BY
		        |		OutgoingEmail.EmployeeResponsible
		        |	
		        |	UNION ALL
		        |	
		        |	SELECT
		        |		IncomingEmail.EmployeeResponsible,
		        |		CASE
		        |			WHEN SalesOpportunitiesToCustomer.Status = VALUE(Enum.OpportunityStatuses.Won)
		        |				THEN 1
		        |			ELSE 0
		        |		END,
		        |		CASE
		        |			WHEN SalesOpportunitiesToCustomer.Status = VALUE(Enum.OpportunityStatuses.Lost)
		        |				THEN 1
		        |			ELSE 0
		        |		END
		        |	FROM
		        |		Document.IncomingEmail AS IncomingEmail
		        |			LEFT JOIN InformationRegister.InteractionsFolderSubjects AS InteractionsFolderSubjects
		        |			ON (InteractionsFolderSubjects.Interaction = IncomingEmail.Ref)
		        |			LEFT JOIN Catalog.SalesOpportunitiesToCustomer AS SalesOpportunitiesToCustomer
		        |			ON (InteractionsFolderSubjects.SubjectOf = SalesOpportunitiesToCustomer.Ref)
		        |	WHERE
		        |		InteractionsFolderSubjects.SubjectOf REFS Catalog.SalesOpportunitiesToCustomer
		        |		AND NOT IncomingEmail.DeletionMark
		        |		AND IncomingEmail.Date BETWEEN &BeginOfPeriod AND &PeriodEnding
		        |		AND NOT SalesOpportunitiesToCustomer.DeletionMark
		        |		AND SalesOpportunitiesToCustomer.Closed_
		        |		AND IncomingEmail.EmployeeResponsible IN
		        |				(SELECT
		        |					FilterByManagers.Ref
		        |				FROM
		        |					FilterByManagers AS FilterByManagers)
		        |	
		        |	UNION ALL
		        |	
		        |	SELECT
		        |		PhoneCall.EmployeeResponsible,
		        |		CASE
		        |			WHEN SalesOpportunitiesToCustomer.Status = VALUE(Enum.OpportunityStatuses.Won)
		        |				THEN 1
		        |			ELSE 0
		        |		END,
		        |		CASE
		        |			WHEN SalesOpportunitiesToCustomer.Status = VALUE(Enum.OpportunityStatuses.Lost)
		        |				THEN 1
		        |			ELSE 0
		        |		END
		        |	FROM
		        |		Document.PhoneCall AS PhoneCall
		        |			LEFT JOIN InformationRegister.InteractionsFolderSubjects AS InteractionsFolderSubjects
		        |			ON (InteractionsFolderSubjects.Interaction = PhoneCall.Ref)
		        |			LEFT JOIN Catalog.SalesOpportunitiesToCustomer AS SalesOpportunitiesToCustomer
		        |			ON (InteractionsFolderSubjects.SubjectOf = SalesOpportunitiesToCustomer.Ref)
		        |	WHERE
		        |		InteractionsFolderSubjects.SubjectOf REFS Catalog.SalesOpportunitiesToCustomer
		        |		AND NOT PhoneCall.DeletionMark
		        |		AND PhoneCall.Date BETWEEN &BeginOfPeriod AND &PeriodEnding
		        |		AND NOT SalesOpportunitiesToCustomer.DeletionMark
		        |		AND SalesOpportunitiesToCustomer.Closed_
		        |		AND PhoneCall.EmployeeResponsible IN
		        |				(SELECT
		        |					FilterByManagers.Ref
		        |				FROM
		        |					FilterByManagers AS FilterByManagers)
		        |	
		        |	UNION ALL
		        |	
		        |	SELECT
		        |		Meeting.EmployeeResponsible,
		        |		CASE
		        |			WHEN SalesOpportunitiesToCustomer.Status = VALUE(Enum.OpportunityStatuses.Won)
		        |				THEN 1
		        |			ELSE 0
		        |		END,
		        |		CASE
		        |			WHEN SalesOpportunitiesToCustomer.Status = VALUE(Enum.OpportunityStatuses.Lost)
		        |				THEN 1
		        |			ELSE 0
		        |		END
		        |	FROM
		        |		Document.Meeting AS Meeting
		        |			LEFT JOIN InformationRegister.InteractionsFolderSubjects AS InteractionsFolderSubjects
		        |			ON (InteractionsFolderSubjects.Interaction = Meeting.Ref)
		        |			LEFT JOIN Catalog.SalesOpportunitiesToCustomer AS SalesOpportunitiesToCustomer
		        |			ON (InteractionsFolderSubjects.SubjectOf = SalesOpportunitiesToCustomer.Ref)
		        |	WHERE
		        |		InteractionsFolderSubjects.SubjectOf REFS Catalog.SalesOpportunitiesToCustomer
		        |		AND NOT Meeting.DeletionMark
		        |		AND Meeting.Date BETWEEN &BeginOfPeriod AND &PeriodEnding
		        |		AND NOT SalesOpportunitiesToCustomer.DeletionMark
		        |		AND SalesOpportunitiesToCustomer.Closed_
		        |		AND Meeting.EmployeeResponsible IN
		        |				(SELECT
		        |					FilterByManagers.Ref
		        |				FROM
		        |					FilterByManagers AS FilterByManagers)) AS NestedQuery
		        |
		        |GROUP BY
		        |	NestedQuery.EmployeeResponsible
		        |;
		        |
		        |////////////////////////////////////////////////////////////////////////////////
		        |SELECT
		        |	NestedQuery.Manager,
		        |	NestedQuery.Won AS InteractionsOnWonTrades,
		        |	NestedQuery.Lost AS InteractionsOnLostTrades,
		        |	NestedQuery.OtherItems AS OtherInteractions,
		        |	CASE
		        |		WHEN NestedQuery.Won + NestedQuery.Lost + NestedQuery.OtherItems = 0
		        |			THEN 0
		        |		ELSE NestedQuery.Won / (NestedQuery.Won + NestedQuery.Lost + NestedQuery.OtherItems) * 100
		        |	END AS ShareOfInteractionsOnWonDeals
		        |FROM
		        |	(SELECT
		        |		CASE
		        |			WHEN NestedQuery.Manager = VALUE(Catalog.Users.EmptyRef)
		        |				THEN &NotSpecified
		        |			ELSE NestedQuery.Manager
		        |		END AS Manager,
		        |		SUM(NestedQuery.Won) AS Won,
		        |		SUM(NestedQuery.Lost) AS Lost,
		        |		SUM(NestedQuery.OtherItems) AS OtherItems
		        |	FROM
		        |		(SELECT
		        |			TransactionInteractions.Manager AS Manager,
		        |			TransactionInteractions.Won AS Won,
		        |			TransactionInteractions.Lost AS Lost,
		        |			0 AS OtherItems
		        |		FROM
		        |			TransactionInteractions AS TransactionInteractions
		        |		
		        |		UNION ALL
		        |		
		        |		SELECT
		        |			OtherInteractions.Manager,
		        |			0,
		        |			0,
		        |			OtherInteractions.OtherItems
		        |		FROM
		        |			OtherInteractions AS OtherInteractions) AS NestedQuery
		        |	
		        |	GROUP BY
		        |		CASE
		        |			WHEN NestedQuery.Manager = VALUE(Catalog.Users.EmptyRef)
		        |				THEN &NotSpecified
		        |			ELSE NestedQuery.Manager
		        |		END) AS NestedQuery
		        |
		        |ORDER BY
		        |	ShareOfInteractionsOnWonDeals,
		        |	InteractionsOnWonTrades
		        |;
		        |
		        |////////////////////////////////////////////////////////////////////////////////
		        |";
		
	EndIf;
	
EndFunction

Function TextOfSalesRequestForOneTransaction(MatchingRequestsData,LastPacketNumber, StructureOfReportGenerationPeriods)
	
	If StructureOfReportGenerationPeriods.ThereIsExtraPeriod Then
		
		MatchingRequestsData.Insert("SalesPerOpportunity",LastPacketNumber + 3);
		LastPacketNumber = LastPacketNumber + 3;
		
		Return "SELECT ALLOWED
		|	NestedQuery.EmployeeResponsible AS Manager,
		|	NestedQuery.RevenueAmountTurnover / NestedQuery.TransactionNumber AS Factor
		|INTO SalesPerTransactionCur
		|FROM
		|	(SELECT
		|		NestedQuery.EmployeeResponsible AS EmployeeResponsible,
		|		SUM(NestedQuery.Ref) AS TransactionNumber,
		|		SUM(NestedQuery.RevenueAmountTurnover) AS RevenueAmountTurnover
		|	FROM
		|		(SELECT
		|			COUNT(DISTINCT SalesOpportunitiesToCustomer.Ref) AS Ref,
		|			CASE
		|				WHEN SalesOpportunitiesToCustomer.EmployeeResponsible = VALUE(Catalog.Users.EmptyRef)
		|					THEN &NotSpecified
		|				ELSE SalesOpportunitiesToCustomer.EmployeeResponsible
		|			END AS EmployeeResponsible,
		|			0 AS RevenueAmountTurnover
		|		FROM
		|			Catalog.SalesOpportunitiesToCustomer AS SalesOpportunitiesToCustomer
		|		WHERE
		|			(NOT SalesOpportunitiesToCustomer.DeletionMark)
		|			AND SalesOpportunitiesToCustomer.Closed_
		|			AND SalesOpportunitiesToCustomer.EndDate BETWEEN &BeginOfPeriod AND &PeriodEnding
		|		AND SalesOpportunitiesToCustomer.EmployeeResponsible IN
		|			(SELECT
		|				FilterByManagers.Ref
		|			FROM
		|				FilterByManagers AS FilterByManagers)
		|		
		|		GROUP BY
		|			CASE
		|				WHEN SalesOpportunitiesToCustomer.EmployeeResponsible = VALUE(Catalog.Users.EmptyRef)
		|					THEN &NotSpecified
		|				ELSE SalesOpportunitiesToCustomer.EmployeeResponsible
		|			END
		|		
		|		UNION ALL
		|		
		|		SELECT
		|			0,
		|			ISNULL(RevenueAndCostOfSalesTurnover.SalesOrder.Manager, &NotSpecified),
		|			RevenueAndCostOfSalesTurnover.RevenueAmountTurnover
		|		FROM
		|			AccumulationRegister.RevenueAndCOGS.Turnovers(&BeginOfPeriod, &PeriodEnding, ,AccountingDimensionByPartners.Partner <> VALUE(Catalog.Partners.RetailCustomer) AND SalesOrder.Manager IN (SELECT FilterByManagers.Ref FROM FilterByManagers AS FilterByManagers)) AS RevenueAndCostOfSalesTurnover) AS NestedQuery
		|	
		|	GROUP BY
		|		NestedQuery.EmployeeResponsible
		|	
		|	HAVING
		|		SUM(NestedQuery.Ref) > 0 AND SUM(NestedQuery.RevenueAmountTurnover) > 0) AS NestedQuery
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT ALLOWED
		|	NestedQuery.EmployeeResponsible AS Manager,
		|	NestedQuery.RevenueAmountTurnover / NestedQuery.TransactionNumber AS Factor
		|INTO SalesPerTransactionPrevious
		|FROM
		|	(SELECT
		|		NestedQuery.EmployeeResponsible AS EmployeeResponsible,
		|		SUM(NestedQuery.Ref) AS TransactionNumber,
		|		SUM(NestedQuery.RevenueAmountTurnover) AS RevenueAmountTurnover
		|	FROM
		|		(SELECT
		|			COUNT(DISTINCT SalesOpportunitiesToCustomer.Ref) AS Ref,
		|			CASE
		|				WHEN SalesOpportunitiesToCustomer.EmployeeResponsible = VALUE(Catalog.Users.EmptyRef)
		|					THEN &NotSpecified
		|				ELSE SalesOpportunitiesToCustomer.EmployeeResponsible
		|			END AS EmployeeResponsible,
		|			0 AS RevenueAmountTurnover
		|		FROM
		|			Catalog.SalesOpportunitiesToCustomer AS SalesOpportunitiesToCustomer
		|		WHERE
		|			(NOT SalesOpportunitiesToCustomer.DeletionMark)
		|			AND SalesOpportunitiesToCustomer.Closed_
		|			AND SalesOpportunitiesToCustomer.EndDate BETWEEN &StartDateAdditionalPeriod AND &EndDateAdditionalPeriod
		|		AND SalesOpportunitiesToCustomer.EmployeeResponsible IN
		|			(SELECT
		|				FilterByManagers.Ref
		|			FROM
		|				FilterByManagers AS FilterByManagers)
		|		
		|		GROUP BY
		|			CASE
		|				WHEN SalesOpportunitiesToCustomer.EmployeeResponsible = VALUE(Catalog.Users.EmptyRef)
		|					THEN &NotSpecified
		|				ELSE SalesOpportunitiesToCustomer.EmployeeResponsible
		|			END
		|		
		|		UNION ALL
		|		
		|		SELECT
		|			0,
		|			ISNULL(RevenueAndCostOfSalesTurnover.SalesOrder.Manager, &NotSpecified),
		|			RevenueAndCostOfSalesTurnover.RevenueAmountTurnover
		|		FROM
		|			AccumulationRegister.RevenueAndCOGS.Turnovers(&StartDateAdditionalPeriod, &EndDateAdditionalPeriod, ,AccountingDimensionByPartners.Partner <> VALUE(Catalog.Partners.RetailCustomer) AND SalesOrder.Manager IN (SELECT FilterByManagers.Ref FROM FilterByManagers AS FilterByManagers)) AS RevenueAndCostOfSalesTurnover) AS NestedQuery
		|	
		|	GROUP BY
		|		NestedQuery.EmployeeResponsible
		|	
		|	HAVING
		|		SUM(NestedQuery.Ref) > 0 AND SUM(NestedQuery.RevenueAmountTurnover) > 0) AS NestedQuery
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	ISNULL(NestedQuery.Manager, &NotSpecified) AS Manager,
		|	NestedQuery.Current_,
		|	NestedQuery.Previous,
		|	CASE
		|		WHEN NestedQuery.Current_ - NestedQuery.Previous > 0
		|			THEN NestedQuery.Current_ - NestedQuery.Previous
		|		ELSE 0
		|	END AS Growth,
		|	CASE
		|		WHEN NestedQuery.Current_ - NestedQuery.Previous < 0
		|			THEN NestedQuery.Current_ - NestedQuery.Previous
		|		ELSE 0
		|	END AS Slippage
		|FROM
		|	(SELECT
		|		CASE
		|			WHEN PreviousPeriod_.Manager IS NULL 
		|				THEN CurrentPeriod.Manager
		|			ELSE PreviousPeriod_.Manager
		|		END AS Manager,
		|		SUM(ISNULL(PreviousPeriod_.Factor, 0)) AS Previous,
		|		SUM(ISNULL(CurrentPeriod.Factor, 0)) AS Current_
		|	FROM
		|		SalesPerTransactionPrevious AS PreviousPeriod_
		|			FULL JOIN SalesPerTransactionCur AS CurrentPeriod
		|			ON PreviousPeriod_.Manager = CurrentPeriod.Manager
		|	
		|	GROUP BY
		|		CASE
		|			WHEN PreviousPeriod_.Manager IS NULL 
		|				THEN CurrentPeriod.Manager
		|			ELSE PreviousPeriod_.Manager
		|		END) AS NestedQuery
		|
		|ORDER BY
		|	NestedQuery.Current_
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|";
		
	Else
		
		MatchingRequestsData.Insert("SalesPerOpportunity",LastPacketNumber + 1);
		LastPacketNumber = LastPacketNumber + 1;
		
		Return "SELECT ALLOWED
		|	NestedQuery.EmployeeResponsible AS Manager,
		|	NestedQuery.RevenueAmountTurnover / NestedQuery.TransactionNumber AS SalesPerTransaction
		|FROM
		|	(SELECT
		|		NestedQuery.EmployeeResponsible AS EmployeeResponsible,
		|		SUM(NestedQuery.Ref) AS TransactionNumber,
		|		SUM(NestedQuery.RevenueAmountTurnover) AS RevenueAmountTurnover
		|	FROM
		|		(SELECT
		|			COUNT(DISTINCT SalesOpportunitiesToCustomer.Ref) AS Ref,
		|			CASE
		|				WHEN SalesOpportunitiesToCustomer.EmployeeResponsible = VALUE(Catalog.Users.EmptyRef)
		|					THEN &NotSpecified
		|				ELSE SalesOpportunitiesToCustomer.EmployeeResponsible
		|			END AS EmployeeResponsible,
		|			0 AS RevenueAmountTurnover
		|		FROM
		|			Catalog.SalesOpportunitiesToCustomer AS SalesOpportunitiesToCustomer
		|		WHERE
		|			(NOT SalesOpportunitiesToCustomer.DeletionMark)
		|			AND SalesOpportunitiesToCustomer.Closed_
		|			AND SalesOpportunitiesToCustomer.EndDate BETWEEN &BeginOfPeriod AND &PeriodEnding
		|		AND SalesOpportunitiesToCustomer.EmployeeResponsible IN
		|			(SELECT
		|				FilterByManagers.Ref
		|			FROM
		|				FilterByManagers AS FilterByManagers)
		|		
		|		GROUP BY
		|			CASE
		|				WHEN SalesOpportunitiesToCustomer.EmployeeResponsible = VALUE(Catalog.Users.EmptyRef)
		|					THEN &NotSpecified
		|				ELSE SalesOpportunitiesToCustomer.EmployeeResponsible
		|			END
		|		
		|		UNION ALL
		|		
		|		SELECT
		|			0,
		|			ISNULL(RevenueAndCostOfSalesTurnover.SalesOrder.Manager, &NotSpecified),
		|			RevenueAndCostOfSalesTurnover.RevenueAmountTurnover
		|		FROM
		|			AccumulationRegister.RevenueAndCOGS.Turnovers(&BeginOfPeriod, &PeriodEnding, ,AccountingDimensionByPartners.Partner <> VALUE(Catalog.Partners.RetailCustomer) AND SalesOrder.Manager IN (SELECT FilterByManagers.Ref FROM FilterByManagers AS FilterByManagers)) AS RevenueAndCostOfSalesTurnover) AS NestedQuery
		|	
		|	GROUP BY
		|		NestedQuery.EmployeeResponsible
		|	
		|	HAVING
		|		SUM(NestedQuery.Ref) > 0 AND SUM(NestedQuery.RevenueAmountTurnover) > 0) AS NestedQuery
		|
		|ORDER BY
		|	SalesPerTransaction
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|";
		
	EndIf;
	
EndFunction

Function TextOfSalesRequestPerInteraction(MatchingRequestsData, LastPacketNumber, StructureOfReportGenerationPeriods)
	
	If StructureOfReportGenerationPeriods.ThereIsExtraPeriod Then
		
		MatchingRequestsData.Insert("SalesPerOneInteraction",LastPacketNumber + 3);
		LastPacketNumber = LastPacketNumber + 3;
		
		Return "SELECT ALLOWED
		        |	NestedQuery.EmployeeResponsible AS Manager,
		        |	NestedQuery.Sales / NestedQuery.Interactions AS Factor
		        |INTO SalesPerInteractionCur
		        |FROM
		        |	(SELECT
		        |		NestedQuery.EmployeeResponsible AS EmployeeResponsible,
		        |		SUM(NestedQuery.Ref) AS Interactions,
		        |		SUM(NestedQuery.Sales) AS Sales
		        |	FROM
		        |		(SELECT
		        |			COUNT(DISTINCT NestedQuery.Ref) AS Ref,
		        |			NestedQuery.EmployeeResponsible AS EmployeeResponsible,
		        |			0 AS Sales
		        |		FROM
		        |			(SELECT
		        |				OutgoingEmail.EmployeeResponsible AS EmployeeResponsible,
		        |				OutgoingEmail.Ref AS Ref
		        |			FROM
		        |				Document.OutgoingEmail AS OutgoingEmail
		        |			WHERE
		        |				NOT OutgoingEmail.DeletionMark
		        |				AND OutgoingEmail.Date BETWEEN &BeginOfPeriod AND &PeriodEnding
		        |				AND OutgoingEmail.EmailStatus = VALUE(Enum.OutgoingEmailStatuses.Sent)
		        |				AND OutgoingEmail.EmployeeResponsible IN
		        |						(SELECT
		        |							FilterByManagers.Ref
		        |						FROM
		        |							FilterByManagers AS FilterByManagers)
		        |			
		        |			UNION ALL
		        |			
		        |			SELECT
		        |				IncomingEmail.EmployeeResponsible,
		        |				IncomingEmail.Ref
		        |			FROM
		        |				Document.IncomingEmail AS IncomingEmail
		        |			WHERE
		        |				NOT IncomingEmail.DeletionMark
		        |				AND IncomingEmail.Date BETWEEN &BeginOfPeriod AND &PeriodEnding
		        |				AND IncomingEmail.EmployeeResponsible IN
		        |						(SELECT
		        |							FilterByManagers.Ref
		        |						FROM
		        |							FilterByManagers AS FilterByManagers)
		        |			
		        |			UNION ALL
		        |			
		        |			SELECT DISTINCT
		        |				PhoneCall.EmployeeResponsible,
		        |				PhoneCall.Ref
		        |			FROM
		        |				Document.PhoneCall AS PhoneCall
		        |			WHERE
		        |				NOT PhoneCall.DeletionMark
		        |				AND PhoneCall.Date BETWEEN &BeginOfPeriod AND &PeriodEnding
		        |				AND PhoneCall.EmployeeResponsible IN
		        |						(SELECT
		        |							FilterByManagers.Ref
		        |						FROM
		        |							FilterByManagers AS FilterByManagers)
		        |			
		        |			UNION ALL
		        |			
		        |			SELECT DISTINCT
		        |				Meeting.EmployeeResponsible,
		        |				Meeting.Ref
		        |			FROM
		        |				Document.Meeting AS Meeting
		        |			WHERE
		        |				NOT Meeting.DeletionMark
		        |				AND Meeting.Date BETWEEN &BeginOfPeriod AND &PeriodEnding
		        |				AND Meeting.EmployeeResponsible IN
		        |						(SELECT
		        |							FilterByManagers.Ref
		        |						FROM
		        |							FilterByManagers AS FilterByManagers)) AS NestedQuery
		        |		
		        |		GROUP BY
		        |			NestedQuery.EmployeeResponsible
		        |		
		        |		UNION ALL
		        |		
		        |		SELECT
		        |			0,
		        |			ISNULL(RevenueAndCostOfSalesTurnover.SalesOrder.Manager, &NotSpecified),
		        |			RevenueAndCostOfSalesTurnover.RevenueAmountTurnover
		        |		FROM
		        |			AccumulationRegister.RevenueAndCOGS.Turnovers(
		        |					&BeginOfPeriod,
		        |					&PeriodEnding,
		        |					,
		        |					SalesOrder.Manager IN
		        |						(SELECT
		        |							FilterByManagers.Ref
		        |						FROM
		        |							FilterByManagers AS FilterByManagers)) AS RevenueAndCostOfSalesTurnover) AS NestedQuery
		        |	
		        |	GROUP BY
		        |		NestedQuery.EmployeeResponsible
		        |	
		        |	HAVING
		        |		SUM(NestedQuery.Ref) > 0 AND
		        |		SUM(NestedQuery.Sales) > 0) AS NestedQuery
		        |;
		        |
		        |////////////////////////////////////////////////////////////////////////////////
		        |SELECT ALLOWED
		        |	NestedQuery.EmployeeResponsible AS Manager,
		        |	NestedQuery.Sales / NestedQuery.Interactions AS Factor
		        |INTO SalesPerInteractionPrevious
		        |FROM
		        |	(SELECT
		        |		NestedQuery.EmployeeResponsible AS EmployeeResponsible,
		        |		SUM(NestedQuery.Ref) AS Interactions,
		        |		SUM(NestedQuery.Sales) AS Sales
		        |	FROM
		        |		(SELECT
		        |			COUNT(DISTINCT NestedQuery.Ref) AS Ref,
		        |			NestedQuery.EmployeeResponsible AS EmployeeResponsible,
		        |			0 AS Sales
		        |		FROM
		        |			(SELECT
		        |				OutgoingEmail.EmployeeResponsible AS EmployeeResponsible,
		        |				OutgoingEmail.Ref AS Ref
		        |			FROM
		        |				Document.OutgoingEmail AS OutgoingEmail
		        |			WHERE
		        |				NOT OutgoingEmail.DeletionMark
		        |				AND OutgoingEmail.Date BETWEEN &StartDateAdditionalPeriod AND &EndDateAdditionalPeriod
		        |				AND OutgoingEmail.EmailStatus = VALUE(Enum.OutgoingEmailStatuses.Sent)
		        |				AND OutgoingEmail.EmployeeResponsible IN
		        |						(SELECT
		        |							FilterByManagers.Ref
		        |						FROM
		        |							FilterByManagers AS FilterByManagers)
		        |			
		        |			UNION ALL
		        |			
		        |			SELECT
		        |				IncomingEmail.EmployeeResponsible,
		        |				IncomingEmail.Ref
		        |			FROM
		        |				Document.IncomingEmail AS IncomingEmail
		        |			WHERE
		        |				NOT IncomingEmail.DeletionMark
		        |				AND IncomingEmail.Date BETWEEN &StartDateAdditionalPeriod AND &EndDateAdditionalPeriod
		        |				AND IncomingEmail.EmployeeResponsible IN
		        |						(SELECT
		        |							FilterByManagers.Ref
		        |						FROM
		        |							FilterByManagers AS FilterByManagers)
		        |			
		        |			UNION ALL
		        |			
		        |			SELECT DISTINCT
		        |				PhoneCall.EmployeeResponsible,
		        |				PhoneCall.Ref
		        |			FROM
		        |				Document.PhoneCall AS PhoneCall
		        |			WHERE
		        |				NOT PhoneCall.DeletionMark
		        |				AND PhoneCall.Date BETWEEN &StartDateAdditionalPeriod AND &EndDateAdditionalPeriod
		        |				AND PhoneCall.EmployeeResponsible IN
		        |						(SELECT
		        |							FilterByManagers.Ref
		        |						FROM
		        |							FilterByManagers AS FilterByManagers)
		        |			
		        |			UNION ALL
		        |			
		        |			SELECT DISTINCT
		        |				Meeting.EmployeeResponsible,
		        |				Meeting.Ref
		        |			FROM
		        |				Document.Meeting AS Meeting
		        |			WHERE
		        |				NOT Meeting.DeletionMark
		        |				AND Meeting.Date BETWEEN &StartDateAdditionalPeriod AND &EndDateAdditionalPeriod
		        |				AND Meeting.EmployeeResponsible IN
		        |						(SELECT
		        |							FilterByManagers.Ref
		        |						FROM
		        |							FilterByManagers AS FilterByManagers)) AS NestedQuery
		        |		
		        |		GROUP BY
		        |			NestedQuery.EmployeeResponsible
		        |		
		        |		UNION ALL
		        |		
		        |		SELECT
		        |			0,
		        |			ISNULL(RevenueAndCostOfSalesTurnover.SalesOrder.Manager, &NotSpecified),
		        |			RevenueAndCostOfSalesTurnover.RevenueAmountTurnover
		        |		FROM
		        |			AccumulationRegister.RevenueAndCOGS.Turnovers(&StartDateAdditionalPeriod, &EndDateAdditionalPeriod, , ) AS RevenueAndCostOfSalesTurnover) AS NestedQuery
		        |	
		        |	GROUP BY
		        |		NestedQuery.EmployeeResponsible
		        |	
		        |	HAVING
		        |		SUM(NestedQuery.Ref) > 0 AND
		        |		SUM(NestedQuery.Sales) > 0) AS NestedQuery
		        |;
		        |
		        |////////////////////////////////////////////////////////////////////////////////
		        |SELECT
		        |	ISNULL(NestedQuery.Manager, &NotSpecified) AS Manager,
		        |	NestedQuery.Current_,
		        |	NestedQuery.Previous,
		        |	CASE
		        |		WHEN NestedQuery.Current_ - NestedQuery.Previous > 0
		        |			THEN NestedQuery.Current_ - NestedQuery.Previous
		        |		ELSE 0
		        |	END AS Growth,
		        |	CASE
		        |		WHEN NestedQuery.Current_ - NestedQuery.Previous < 0
		        |			THEN NestedQuery.Current_ - NestedQuery.Previous
		        |		ELSE 0
		        |	END AS Slippage
		        |FROM
		        |	(SELECT
		        |		CASE
		        |			WHEN PreviousPeriod_.Manager IS NULL
		        |				THEN CurrentPeriod.Manager
		        |			ELSE PreviousPeriod_.Manager
		        |		END AS Manager,
		        |		SUM(ISNULL(PreviousPeriod_.Factor, 0)) AS Previous,
		        |		SUM(ISNULL(CurrentPeriod.Factor, 0)) AS Current_
		        |	FROM
		        |		SalesPerInteractionPrevious AS PreviousPeriod_
		        |			FULL JOIN SalesPerInteractionCur AS CurrentPeriod
		        |			ON PreviousPeriod_.Manager = CurrentPeriod.Manager
		        |	
		        |	GROUP BY
		        |		CASE
		        |			WHEN PreviousPeriod_.Manager IS NULL
		        |				THEN CurrentPeriod.Manager
		        |			ELSE PreviousPeriod_.Manager
		        |		END) AS NestedQuery
		        |
		        |ORDER BY
		        |	NestedQuery.Current_
		        |;
		        |
		        |////////////////////////////////////////////////////////////////////////////////
		        |";
		
	Else
		
		MatchingRequestsData.Insert("SalesPerOneInteraction",LastPacketNumber + 1);
		LastPacketNumber = LastPacketNumber + 1;
		
		Return "SELECT ALLOWED
		        |	NestedQuery.EmployeeResponsible AS Manager,
		        |	NestedQuery.Sales / NestedQuery.Interactions AS InteractionSales
		        |FROM
		        |	(SELECT
		        |		NestedQuery.EmployeeResponsible AS EmployeeResponsible,
		        |		SUM(NestedQuery.Ref) AS Interactions,
		        |		SUM(NestedQuery.Sales) AS Sales
		        |	FROM
		        |		(SELECT
		        |			COUNT(DISTINCT NestedQuery.Ref) AS Ref,
		        |			NestedQuery.EmployeeResponsible AS EmployeeResponsible,
		        |			0 AS Sales
		        |		FROM
		        |			(SELECT
		        |				OutgoingEmail.EmployeeResponsible AS EmployeeResponsible,
		        |				OutgoingEmail.Ref AS Ref
		        |			FROM
		        |				Document.OutgoingEmail AS OutgoingEmail
		        |			WHERE
		        |				NOT OutgoingEmail.DeletionMark
		        |				AND OutgoingEmail.Date BETWEEN &BeginOfPeriod AND &PeriodEnding
		        |				AND OutgoingEmail.EmailStatus = VALUE(Enum.OutgoingEmailStatuses.Sent)
		        |				AND OutgoingEmail.EmployeeResponsible IN
		        |						(SELECT
		        |							FilterByManagers.Ref
		        |						FROM
		        |							FilterByManagers AS FilterByManagers)
		        |			
		        |			UNION ALL
		        |			
		        |			SELECT
		        |				IncomingEmail.EmployeeResponsible,
		        |				IncomingEmail.Ref
		        |			FROM
		        |				Document.IncomingEmail AS IncomingEmail
		        |			WHERE
		        |				NOT IncomingEmail.DeletionMark
		        |				AND IncomingEmail.Date BETWEEN &BeginOfPeriod AND &PeriodEnding
		        |				AND IncomingEmail.EmployeeResponsible IN
		        |						(SELECT
		        |							FilterByManagers.Ref
		        |						FROM
		        |							FilterByManagers AS FilterByManagers)
		        |			
		        |			UNION ALL
		        |			
		        |			SELECT DISTINCT
		        |				PhoneCall.EmployeeResponsible,
		        |				PhoneCall.Ref
		        |			FROM
		        |				Document.PhoneCall AS PhoneCall
		        |			WHERE
		        |				NOT PhoneCall.DeletionMark
		        |				AND PhoneCall.Date BETWEEN &BeginOfPeriod AND &PeriodEnding
		        |				AND PhoneCall.EmployeeResponsible IN
		        |						(SELECT
		        |							FilterByManagers.Ref
		        |						FROM
		        |							FilterByManagers AS FilterByManagers)
		        |			
		        |			UNION ALL
		        |			
		        |			SELECT DISTINCT
		        |				Meeting.EmployeeResponsible,
		        |				Meeting.Ref
		        |			FROM
		        |				Document.Meeting AS Meeting
		        |			WHERE
		        |				NOT Meeting.DeletionMark
		        |				AND Meeting.Date BETWEEN &BeginOfPeriod AND &PeriodEnding
		        |				AND Meeting.EmployeeResponsible IN
		        |						(SELECT
		        |							FilterByManagers.Ref
		        |						FROM
		        |							FilterByManagers AS FilterByManagers)) AS NestedQuery
		        |		
		        |		GROUP BY
		        |			NestedQuery.EmployeeResponsible
		        |		
		        |		UNION ALL
		        |		
		        |		SELECT
		        |			0,
		        |			ISNULL(RevenueAndCostOfSalesTurnover.SalesOrder.Manager, &NotSpecified),
		        |			RevenueAndCostOfSalesTurnover.RevenueAmountTurnover
		        |		FROM
		        |			AccumulationRegister.RevenueAndCOGS.Turnovers(&BeginOfPeriod, &PeriodEnding, , ) AS RevenueAndCostOfSalesTurnover) AS NestedQuery
		        |	
		        |	GROUP BY
		        |		NestedQuery.EmployeeResponsible
		        |	
		        |	HAVING
		        |		SUM(NestedQuery.Ref) > 0 AND
		        |		SUM(NestedQuery.Sales) > 0) AS NestedQuery
		        |
		        |ORDER BY
		        |	InteractionSales
		        |;
		        |
		        |////////////////////////////////////////////////////////////////////////////////
		        |";
		
	EndIf;
	
EndFunction

Function TextOfRequestAboutReasonsForLosingTrades(MatchingRequestsData,LastPacketNumber, StructureOfReportGenerationPeriods)
	
	If StructureOfReportGenerationPeriods.ThereIsExtraPeriod Then
		
		MatchingRequestsData.Insert("ReasonsForLosingSalesOpportunities",LastPacketNumber + 3);
		LastPacketNumber = LastPacketNumber + 3;
		
		Return "SELECT ALLOWED TOP 5
		|	PRESENTATION(SalesOpportunitiesToCustomer.EmployeeResponsible) AS Manager,
		|	PRESENTATION(SalesOpportunitiesToCustomer.ReasonForLosingSalesOpportunity),
		|	SUM(1) AS Count
		|INTO ReasonsForLosingTradesCur
		|FROM
		|	Catalog.SalesOpportunitiesToCustomer AS SalesOpportunitiesToCustomer
		|WHERE
		|	SalesOpportunitiesToCustomer.EndDate BETWEEN &BeginOfPeriod AND &PeriodEnding
		|	AND SalesOpportunitiesToCustomer.Closed_
		|	AND (NOT SalesOpportunitiesToCustomer.DeletionMark)
		|	AND SalesOpportunitiesToCustomer.Status = VALUE(Enum.OpportunityStatuses.Lost)
		|	AND SalesOpportunitiesToCustomer.EmployeeResponsible IN
		|		(SELECT
		|			FilterByManagers.Ref
		|		FROM
		|			FilterByManagers AS FilterByManagers)
		|
		|GROUP BY
		|	PRESENTATION(SalesOpportunitiesToCustomer.EmployeeResponsible),
		|	PRESENTATION(SalesOpportunitiesToCustomer.ReasonForLosingSalesOpportunity)
		|
		|ORDER BY
		|	Count DESC
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT ALLOWED TOP 5
		|	PRESENTATION(SalesOpportunitiesToCustomer.EmployeeResponsible) AS Manager,
		|	PRESENTATION(SalesOpportunitiesToCustomer.ReasonForLosingSalesOpportunity),
		|	SUM(1) AS Count
		|INTO ReasonsForLosingTradesPrevious
		|FROM
		|	Catalog.SalesOpportunitiesToCustomer AS SalesOpportunitiesToCustomer
		|WHERE
		|	SalesOpportunitiesToCustomer.EndDate BETWEEN &StartDateAdditionalPeriod AND &EndDateAdditionalPeriod
		|	AND SalesOpportunitiesToCustomer.Closed_
		|	AND (NOT SalesOpportunitiesToCustomer.DeletionMark)
		|	AND SalesOpportunitiesToCustomer.Status = VALUE(Enum.OpportunityStatuses.Lost)
		|	AND SalesOpportunitiesToCustomer.EmployeeResponsible IN
		|		(SELECT
		|			FilterByManagers.Ref
		|		FROM
		|			FilterByManagers AS FilterByManagers)
		|
		|GROUP BY
		|	PRESENTATION(SalesOpportunitiesToCustomer.EmployeeResponsible),
		|	PRESENTATION(SalesOpportunitiesToCustomer.ReasonForLosingSalesOpportunity)
		|
		|ORDER BY
		|	Count DESC
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	ReasonsForLosingTradesPrevious.Manager,
		|	ReasonsForLosingTradesPrevious.ReasonForLosingSalesOpportunityPresentation,
		|	ReasonsForLosingTradesPrevious.Count AS IndicatorValue,
		|	""Previous"" AS Period
		|FROM
		|	ReasonsForLosingTradesPrevious AS ReasonsForLosingTradesPrevious
		|
		|UNION ALL
		|
		|SELECT
		|	ReasonsForLosingTradesCur.Manager,
		|	ReasonsForLosingTradesCur.ReasonForLosingSalesOpportunityPresentation,
		|	ReasonsForLosingTradesCur.Count,
		|	""Current_""
		|FROM
		|	ReasonsForLosingTradesCur AS ReasonsForLosingTradesCur
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|";
		
	Else
	
		MatchingRequestsData.Insert("ReasonsForLosingSalesOpportunities",LastPacketNumber + 1);
		LastPacketNumber = LastPacketNumber + 1;
		
		Return "SELECT ALLOWED TOP 5
		|	PRESENTATION(SalesOpportunitiesToCustomer.EmployeeResponsible) AS Manager,
		|	PRESENTATION(SalesOpportunitiesToCustomer.ReasonForLosingSalesOpportunity),
		|	SUM(1) AS Count
		|FROM
		|	Catalog.SalesOpportunitiesToCustomer AS SalesOpportunitiesToCustomer
		|WHERE
		|	SalesOpportunitiesToCustomer.EndDate BETWEEN &BeginOfPeriod AND &PeriodEnding
		|	AND SalesOpportunitiesToCustomer.Closed_
		|	AND (NOT SalesOpportunitiesToCustomer.DeletionMark)
		|	AND SalesOpportunitiesToCustomer.Status = VALUE(Enum.OpportunityStatuses.Lost)
		|	AND SalesOpportunitiesToCustomer.EmployeeResponsible IN
		|		(SELECT
		|			FilterByManagers.Ref
		|		FROM
		|			FilterByManagers AS FilterByManagers)
		|
		|GROUP BY
		|	PRESENTATION(SalesOpportunitiesToCustomer.EmployeeResponsible),
		|	PRESENTATION(SalesOpportunitiesToCustomer.ReasonForLosingSalesOpportunity)
		|
		|ORDER BY
		|	Count DESC
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|";
		
	EndIf;
	
EndFunction

Function RequestTextAboutMainStagesOfLosses(MatchingRequestsData,LastPacketNumber, StructureOfReportGenerationPeriods)
	
	If StructureOfReportGenerationPeriods.ThereIsExtraPeriod Then
		
		MatchingRequestsData.Insert("TheMainStagesOfLosses",LastPacketNumber + 3);
		LastPacketNumber = LastPacketNumber + 3;
		
		Return "SELECT ALLOWED TOP 5
		|	PRESENTATION(StatisticsOfCustomerOpportunities.EmployeeResponsible) AS Manager,
		|	PRESENTATION(StatisticsOfCustomerOpportunities.ProcessStep),
		|	SUM(1) AS Count
		|INTO MainStagesOfLossesCur
		|FROM
		|	InformationRegister.StatisticsOfCustomerOpportunities AS StatisticsOfCustomerOpportunities
		|WHERE
		|	StatisticsOfCustomerOpportunities.EndDate BETWEEN &BeginOfPeriod AND &PeriodEnding
		|	AND StatisticsOfCustomerOpportunities.Result = VALUE(Enum.OpportunityStatuses.Lost)
		|	AND StatisticsOfCustomerOpportunities.EmployeeResponsible IN
		|		(SELECT
		|			FilterByManagers.Ref
		|		FROM
		|			FilterByManagers AS FilterByManagers)
		|
		|GROUP BY
		|	StatisticsOfCustomerOpportunities.EmployeeResponsible,
		|	StatisticsOfCustomerOpportunities.ProcessStep
		|
		|ORDER BY
		|	Count DESC
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT ALLOWED TOP 5
		|	PRESENTATION(StatisticsOfCustomerOpportunities.EmployeeResponsible) AS Manager,
		|	PRESENTATION(StatisticsOfCustomerOpportunities.ProcessStep),
		|	SUM(1) AS Count
		|INTO MainStagesOfLossesPrevious
		|FROM
		|	InformationRegister.StatisticsOfCustomerOpportunities AS StatisticsOfCustomerOpportunities
		|WHERE
		|	StatisticsOfCustomerOpportunities.EndDate BETWEEN &StartDateAdditionalPeriod AND &EndDateAdditionalPeriod
		|	AND StatisticsOfCustomerOpportunities.Result = VALUE(Enum.OpportunityStatuses.Lost)
		|	AND StatisticsOfCustomerOpportunities.EmployeeResponsible IN
		|		(SELECT
		|			FilterByManagers.Ref
		|		FROM
		|			FilterByManagers AS FilterByManagers)
		|
		|GROUP BY
		|	StatisticsOfCustomerOpportunities.EmployeeResponsible,
		|	StatisticsOfCustomerOpportunities.ProcessStep
		|
		|ORDER BY
		|	Count DESC
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|	SELECT
		|	MainStagesOfLossesPrevious.Manager,
		|	MainStagesOfLossesPrevious.ProcessStepPresentation,
		|	MainStagesOfLossesPrevious.Count AS IndicatorValue,
		|	""Previous"" AS Period
		|FROM
		|	MainStagesOfLossesPrevious AS MainStagesOfLossesPrevious
		|
		|UNION ALL
		|
		|SELECT
		|	MainStagesOfLossesCur.Manager,
		|	MainStagesOfLossesCur.ProcessStepPresentation,
		|	MainStagesOfLossesCur.Count,
		|	""Current_""
		|FROM
		|	MainStagesOfLossesCur AS MainStagesOfLossesCur
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|";
		
	Else
	
	MatchingRequestsData.Insert("TheMainStagesOfLosses",LastPacketNumber + 1);
	LastPacketNumber = LastPacketNumber + 1;
	
	Return "SELECT ALLOWED TOP 5
	|	PRESENTATION(StatisticsOfCustomerOpportunities.EmployeeResponsible) AS Manager,
	|	PRESENTATION(StatisticsOfCustomerOpportunities.ProcessStep),
	|	SUM(1) AS Count
	|FROM
	|	InformationRegister.StatisticsOfCustomerOpportunities AS StatisticsOfCustomerOpportunities
	|WHERE
	|	StatisticsOfCustomerOpportunities.EndDate BETWEEN &BeginOfPeriod AND &PeriodEnding
	|	AND StatisticsOfCustomerOpportunities.Result = VALUE(Enum.OpportunityStatuses.Lost)
	|	AND StatisticsOfCustomerOpportunities.EmployeeResponsible IN
	|		(SELECT
	|			FilterByManagers.Ref
	|		FROM
	|			FilterByManagers AS FilterByManagers)
	|
	|GROUP BY
	|	StatisticsOfCustomerOpportunities.EmployeeResponsible,
	|	StatisticsOfCustomerOpportunities.ProcessStep
	|
	|ORDER BY
	|	Count DESC
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|";
	
	EndIf;
	
EndFunction

Function TextOfRequestAboutReasonsForUnsatisfactoryPrimaryDemand(MatchingRequestsData,LastPacketNumber,StructureOfReportGenerationPeriods)
	
	If StructureOfReportGenerationPeriods.ThereIsExtraPeriod Then
		
		MatchingRequestsData.Insert("DissatisfactionWithPrimaryDemand",LastPacketNumber + 3);
		LastPacketNumber = LastPacketNumber + 3;
		
		Return "SELECT ALLOWED TOP 5
		|	CASE
		|		WHEN SalesOpportunitiesToCustomer.EmployeeResponsible = VALUE(Catalog.Users.EmptyRef)
		|			THEN &NotSpecified
		|		ELSE SalesOpportunitiesToCustomer.EmployeeResponsible
		|	END AS Manager,
		|	PRESENTATION(SalesOpportunitiesToCustomerPrimaryDemand.ReasonForNonFulfillment) AS ReasonForNonFulfillment,
		|	SUM(SalesOpportunitiesToCustomerPrimaryDemand.Sum - SalesOpportunitiesToCustomerPrimaryDemand.Sum * SalesOpportunitiesToCustomerPrimaryDemand.SatisfactionPercentage / 100) AS UnfulfilledDemandAmount
		|INTO DissatisfactionWithPrimaryDemandCur
		|FROM
		|	Catalog.SalesOpportunitiesToCustomer.PrimaryDemand AS SalesOpportunitiesToCustomerPrimaryDemand
		|		INNER JOIN Catalog.SalesOpportunitiesToCustomer AS SalesOpportunitiesToCustomer
		|		ON SalesOpportunitiesToCustomerPrimaryDemand.Ref = SalesOpportunitiesToCustomer.Ref
		|WHERE
		|	SalesOpportunitiesToCustomer.Closed_
		|	AND (NOT SalesOpportunitiesToCustomer.DeletionMark)
		|	AND SalesOpportunitiesToCustomer.EndDate BETWEEN &BeginOfPeriod AND &PeriodEnding
		|	AND SalesOpportunitiesToCustomerPrimaryDemand.SatisfactionPercentage < 100
		|	AND SalesOpportunitiesToCustomer.EmployeeResponsible IN
		|		(SELECT
		|			FilterByManagers.Ref
		|		FROM
		|			FilterByManagers AS FilterByManagers)
		|
		|GROUP BY
		|	CASE
		|		WHEN SalesOpportunitiesToCustomer.EmployeeResponsible = VALUE(Catalog.Users.EmptyRef)
		|			THEN &NotSpecified
		|		ELSE SalesOpportunitiesToCustomer.EmployeeResponsible
		|	END,
		|	PRESENTATION(SalesOpportunitiesToCustomerPrimaryDemand.ReasonForNonFulfillment)
		|
		|HAVING
		|	SUM(SalesOpportunitiesToCustomerPrimaryDemand.Sum - SalesOpportunitiesToCustomerPrimaryDemand.Sum * SalesOpportunitiesToCustomerPrimaryDemand.SatisfactionPercentage / 100) > 0
		|
		|ORDER BY
		|	UnfulfilledDemandAmount DESC
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT ALLOWED TOP 5
		|	CASE
		|		WHEN SalesOpportunitiesToCustomer.EmployeeResponsible = VALUE(Catalog.Users.EmptyRef)
		|			THEN &NotSpecified
		|		ELSE SalesOpportunitiesToCustomer.EmployeeResponsible
		|	END AS Manager,
		|	PRESENTATION(SalesOpportunitiesToCustomerPrimaryDemand.ReasonForNonFulfillment) AS ReasonForNonFulfillment,
		|	SUM(SalesOpportunitiesToCustomerPrimaryDemand.Sum - SalesOpportunitiesToCustomerPrimaryDemand.Sum * SalesOpportunitiesToCustomerPrimaryDemand.SatisfactionPercentage / 100) AS UnfulfilledDemandAmount
		|INTO DissatisfactionWithPrimaryDemandPrevious
		|FROM
		|	Catalog.SalesOpportunitiesToCustomer.PrimaryDemand AS SalesOpportunitiesToCustomerPrimaryDemand
		|		INNER JOIN Catalog.SalesOpportunitiesToCustomer AS SalesOpportunitiesToCustomer
		|		ON SalesOpportunitiesToCustomerPrimaryDemand.Ref = SalesOpportunitiesToCustomer.Ref
		|WHERE
		|	SalesOpportunitiesToCustomer.Closed_
		|	AND (NOT SalesOpportunitiesToCustomer.DeletionMark)
		|	AND SalesOpportunitiesToCustomer.EndDate BETWEEN &StartDateAdditionalPeriod AND &EndDateAdditionalPeriod
		|	AND SalesOpportunitiesToCustomerPrimaryDemand.SatisfactionPercentage < 100
		|	AND SalesOpportunitiesToCustomer.EmployeeResponsible IN
		|		(SELECT
		|			FilterByManagers.Ref
		|		FROM
		|			FilterByManagers AS FilterByManagers)
		|
		|GROUP BY
		|	CASE
		|		WHEN SalesOpportunitiesToCustomer.EmployeeResponsible = VALUE(Catalog.Users.EmptyRef)
		|			THEN &NotSpecified
		|		ELSE SalesOpportunitiesToCustomer.EmployeeResponsible
		|	END,
		|	PRESENTATION(SalesOpportunitiesToCustomerPrimaryDemand.ReasonForNonFulfillment)
		|
		|HAVING
		|	SUM(SalesOpportunitiesToCustomerPrimaryDemand.Sum - SalesOpportunitiesToCustomerPrimaryDemand.Sum * SalesOpportunitiesToCustomerPrimaryDemand.SatisfactionPercentage / 100) > 0
		|
		|ORDER BY
		|	UnfulfilledDemandAmount DESC
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	CASE
		|		WHEN DissatisfactionWithPrimaryDemandPrevious.Manager = VALUE(Catalog.Users.EmptyRef)
		|			THEN &NotSpecified
		|		ELSE PRESENTATION(DissatisfactionWithPrimaryDemandPrevious.Manager)
		|	END AS Manager,
		|	DissatisfactionWithPrimaryDemandPrevious.ReasonForNonFulfillment,
		|	DissatisfactionWithPrimaryDemandPrevious.UnfulfilledDemandAmount AS IndicatorValue,
		|	""Previous"" AS Period
		|FROM
		|	DissatisfactionWithPrimaryDemandPrevious AS DissatisfactionWithPrimaryDemandPrevious
		|
		|UNION ALL
		|
		|SELECT
		|	CASE
		|		WHEN DissatisfactionWithPrimaryDemandCur.Manager = VALUE(Catalog.Users.EmptyRef)
		|			THEN &NotSpecified
		|		ELSE PRESENTATION(DissatisfactionWithPrimaryDemandCur.Manager)
		|	END,
		|	DissatisfactionWithPrimaryDemandCur.ReasonForNonFulfillment,
		|	DissatisfactionWithPrimaryDemandCur.UnfulfilledDemandAmount,
		|	""Current_""
		|FROM
		|	DissatisfactionWithPrimaryDemandCur AS DissatisfactionWithPrimaryDemandCur
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|";
		
	Else
	
	MatchingRequestsData.Insert("DissatisfactionWithPrimaryDemand",LastPacketNumber + 1);
	LastPacketNumber = LastPacketNumber + 1;
	
	Return "SELECT ALLOWED TOP 5
	|	CASE
	|		WHEN SalesOpportunitiesToCustomer.EmployeeResponsible = VALUE(Catalog.Users.EmptyRef)
	|			THEN &NotSpecified
	|		ELSE PRESENTATION(SalesOpportunitiesToCustomer.EmployeeResponsible)
	|	END AS Manager,
	|	PRESENTATION(SalesOpportunitiesToCustomerPrimaryDemand.ReasonForNonFulfillment) AS ReasonForNonFulfillment,
	|	SUM(SalesOpportunitiesToCustomerPrimaryDemand.Sum - SalesOpportunitiesToCustomerPrimaryDemand.Sum * SalesOpportunitiesToCustomerPrimaryDemand.SatisfactionPercentage / 100) AS UnfulfilledDemandAmount
	|FROM
	|	Catalog.SalesOpportunitiesToCustomer.PrimaryDemand AS SalesOpportunitiesToCustomerPrimaryDemand
	|		INNER JOIN Catalog.SalesOpportunitiesToCustomer AS SalesOpportunitiesToCustomer
	|		ON SalesOpportunitiesToCustomerPrimaryDemand.Ref = SalesOpportunitiesToCustomer.Ref
	|WHERE
	|	SalesOpportunitiesToCustomer.Closed_
	|	AND (NOT SalesOpportunitiesToCustomer.DeletionMark)
	|	AND SalesOpportunitiesToCustomer.EndDate BETWEEN &BeginOfPeriod AND &PeriodEnding
	|	AND SalesOpportunitiesToCustomerPrimaryDemand.SatisfactionPercentage < 100
	|	AND SalesOpportunitiesToCustomer.EmployeeResponsible IN
	|		(SELECT
	|			FilterByManagers.Ref
	|		FROM
	|			FilterByManagers AS FilterByManagers)
	|
	|GROUP BY
	|	CASE
	|		WHEN SalesOpportunitiesToCustomer.EmployeeResponsible = VALUE(Catalog.Users.EmptyRef)
	|			THEN &NotSpecified
	|		ELSE PRESENTATION(SalesOpportunitiesToCustomer.EmployeeResponsible)
	|	END,
	|	PRESENTATION(SalesOpportunitiesToCustomerPrimaryDemand.ReasonForNonFulfillment)
	|
	|HAVING
	|	SUM(SalesOpportunitiesToCustomerPrimaryDemand.Sum - SalesOpportunitiesToCustomerPrimaryDemand.Sum * SalesOpportunitiesToCustomerPrimaryDemand.SatisfactionPercentage / 100) > 0
	|
	|ORDER BY
	|	UnfulfilledDemandAmount DESC
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|";
	
	EndIf;
	
EndFunction

Function QueryTextCustomerBaseTrends(MatchingRequestsData,LastPacketNumber, StructureOfReportGenerationPeriods)
	
	If StructureOfReportGenerationPeriods.ThereIsExtraPeriod Then
		
		MatchingRequestsData.Insert("CustomerBaseTrends",LastPacketNumber + 9);
		LastPacketNumber = LastPacketNumber + 9;
		
		Return "SELECT ALLOWED DISTINCT
		|	ABCXYZCustomerClassification.Partner,
		|	CASE
		|		WHEN ABCXYZCustomerClassification.Class = VALUE(Enum.ABCClassification.NotClassified)
		|			THEN FALSE
		|		ELSE TRUE
		|	END AS Classified
		|INTO LatestClassification
		|FROM
		|	InformationRegister.ABCXYZCustomerClassification AS ABCXYZCustomerClassification
		|WHERE
		|	ABCXYZCustomerClassification.ClassificationType = VALUE(Enum.TypesOfClassification.ABC)
		|	AND ABCXYZCustomerClassification.Period IN
		|			(SELECT
		|				MAX(ABCXYZCustomerClassification.Period) AS Period
		|			FROM
		|				InformationRegister.ABCXYZCustomerClassification AS ABCXYZCustomerClassification
		|			WHERE
		|				ABCXYZCustomerClassification.Period >= &PeriodEnding)
		|	AND ABCXYZCustomerClassification.Partner <> VALUE(Catalog.Partners.RetailCustomer)
		|	AND ABCXYZCustomerClassification.Partner.MainManager IN
		|		(SELECT
		|			FilterByManagers.Ref
		|		FROM
		|			FilterByManagers AS FilterByManagers)
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT ALLOWED DISTINCT
		|	ABCXYZCustomerClassificationSliceLast.Partner,
		|	CASE
		|		WHEN ABCXYZCustomerClassificationSliceLast.Class = VALUE(Enum.ABCClassification.NotClassified)
		|			THEN FALSE
		|		ELSE TRUE
		|	END AS Classified
		|INTO AsOfThePeriodStart
		|FROM
		|	InformationRegister.ABCXYZCustomerClassification.SliceLast(&BeginOfPeriod, Partner <> VALUE(Catalog.Partners.RetailCustomer) AND Partner.MainManager IN
		|		(SELECT
		|			FilterByManagers.Ref
		|		FROM
		|			FilterByManagers AS FilterByManagers)) AS ABCXYZCustomerClassificationSliceLast
		|WHERE
		|	ABCXYZCustomerClassificationSliceLast.ClassificationType = VALUE(Enum.TypesOfClassification.ABC)
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	NestedQuery.Client,
		|	NestedQuery.ClientStatus
		|INTO ClientsStatuses
		|FROM
		|	(SELECT
		|		ISNULL(AsOfThePeriodStart.Partner, LatestClassification.Partner) AS Client,
		|		CASE
		|			WHEN AsOfThePeriodStart.Classified IS NULL 
		|				THEN CASE
		|						WHEN LatestClassification.Classified
		|							THEN ""New""
		|					END
		|			ELSE CASE
		|					WHEN AsOfThePeriodStart.Classified
		|							AND (NOT ISNULL(LatestClassification.Classified, FALSE))
		|						THEN ""Lost""
		|					ELSE CASE
		|							WHEN (NOT AsOfThePeriodStart.Classified)
		|									AND ISNULL(LatestClassification.Classified, FALSE)
		|								THEN ""Returnee""
		|						END
		|				END
		|		END AS ClientStatus
		|	FROM
		|		AsOfThePeriodStart AS AsOfThePeriodStart
		|			FULL JOIN LatestClassification AS LatestClassification
		|			ON AsOfThePeriodStart.Partner = LatestClassification.Partner) AS NestedQuery
		|WHERE
		|	(NOT NestedQuery.ClientStatus IS NULL )
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	NestedQuery.Manager,
		|	NestedQuery.Lost_,
		|	NestedQuery.New_Items AS New_Items,
		|	NestedQuery.WasReturned,
		|	CASE
		|		WHEN (NestedQuery.New_Items + NestedQuery.Lost_) = 0
		|			THEN 0
		|		ELSE NestedQuery.New_Items / (NestedQuery.New_Items + NestedQuery.Lost_)
		|	END AS ShareOfNewCustomers
		|INTO CurCustomerBaseDynamics
		|FROM
		|	(SELECT
		|		CASE
		|			WHEN ClientsStatuses.Client.MainManager = VALUE(Catalog.Users.EmptyRef)
		|				THEN &NotSpecified
		|			ELSE ClientsStatuses.Client.MainManager
		|		END AS Manager,
		|		SUM(CASE
		|				WHEN ClientsStatuses.ClientStatus = ""Lost""
		|					THEN -1
		|				ELSE 0
		|			END) AS Lost_,
		|		SUM(CASE
		|				WHEN ClientsStatuses.ClientStatus = ""New""
		|					THEN 1
		|				ELSE 0
		|			END) AS New_Items,
		|		SUM(CASE
		|				WHEN ClientsStatuses.ClientStatus = ""Returnee""
		|					THEN 1
		|				ELSE 0
		|			END) AS WasReturned
		|	FROM
		|		ClientsStatuses AS ClientsStatuses
		|	
		|	GROUP BY
		|		CASE
		|			WHEN ClientsStatuses.Client.MainManager = VALUE(Catalog.Users.EmptyRef)
		|				THEN &NotSpecified
		|			ELSE ClientsStatuses.Client.MainManager
		|		END) AS NestedQuery
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT ALLOWED DISTINCT
		|	ABCXYZCustomerClassification.Partner,
		|	CASE
		|		WHEN ABCXYZCustomerClassification.Class = VALUE(Enum.ABCClassification.NotClassified)
		|			THEN FALSE
		|		ELSE TRUE
		|	END AS Classified
		|INTO LastClassificationPrevious
		|FROM
		|	InformationRegister.ABCXYZCustomerClassification AS ABCXYZCustomerClassification
		|WHERE
		|	ABCXYZCustomerClassification.ClassificationType = VALUE(Enum.TypesOfClassification.ABC)
		|	AND ABCXYZCustomerClassification.Period IN
		|			(SELECT
		|				MAX(ABCXYZCustomerClassification.Period) AS Period
		|			FROM
		|				InformationRegister.ABCXYZCustomerClassification AS ABCXYZCustomerClassification
		|			WHERE
		|				ABCXYZCustomerClassification.Period >= &EndDateAdditionalPeriod)
		|	AND ABCXYZCustomerClassification.Partner <> VALUE(Catalog.Partners.RetailCustomer)
		|	AND Partner.MainManager IN
		|		(SELECT
		|			FilterByManagers.Ref
		|		FROM
		|			FilterByManagers AS FilterByManagers)
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT ALLOWED DISTINCT
		|	ABCXYZCustomerClassificationSliceLast.Partner,
		|	CASE
		|		WHEN ABCXYZCustomerClassificationSliceLast.Class = VALUE(Enum.ABCClassification.NotClassified)
		|			THEN FALSE
		|		ELSE TRUE
		|	END AS Classified
		|INTO AtBeginningOfPreviousPeriod
		|FROM
		|	InformationRegister.ABCXYZCustomerClassification.SliceLast(&StartDateAdditionalPeriod, Partner <> VALUE(Catalog.Partners.RetailCustomer) AND Partner.MainManager IN
		|		(SELECT
		|			FilterByManagers.Ref
		|		FROM
		|			FilterByManagers AS FilterByManagers)) AS ABCXYZCustomerClassificationSliceLast
		|WHERE
		|	ABCXYZCustomerClassificationSliceLast.ClassificationType = VALUE(Enum.TypesOfClassification.ABC)
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	NestedQuery.Client,
		|	NestedQuery.ClientStatus
		|INTO ClientsPreviousStatuses
		|FROM
		|	(SELECT
		|		ISNULL(AsOfThePeriodStart.Partner, LatestClassification.Partner) AS Client,
		|		CASE
		|			WHEN AsOfThePeriodStart.Classified IS NULL 
		|				THEN CASE
		|						WHEN LatestClassification.Classified
		|							THEN ""New""
		|					END
		|			ELSE CASE
		|					WHEN AsOfThePeriodStart.Classified
		|							AND (NOT ISNULL(LatestClassification.Classified, FALSE))
		|						THEN ""Lost""
		|					ELSE CASE
		|							WHEN (NOT AsOfThePeriodStart.Classified)
		|									AND ISNULL(LatestClassification.Classified, FALSE)
		|								THEN ""Returnee""
		|						END
		|				END
		|		END AS ClientStatus
		|	FROM
		|		AtBeginningOfPreviousPeriod AS AsOfThePeriodStart
		|			FULL JOIN LastClassificationPrevious AS LatestClassification
		|			ON AsOfThePeriodStart.Partner = LatestClassification.Partner) AS NestedQuery
		|WHERE
		|	(NOT NestedQuery.ClientStatus IS NULL )
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	NestedQuery.Manager,
		|	NestedQuery.Lost_,
		|	NestedQuery.New_Items AS New_Items,
		|	NestedQuery.WasReturned,
		|	CASE
		|		WHEN (NestedQuery.New_Items + NestedQuery.Lost_) = 0
		|			THEN 0
		|		ELSE NestedQuery.New_Items / (NestedQuery.New_Items + NestedQuery.Lost_)
		|	END AS ShareOfNewCustomers
		|INTO DynamicsOfClientBase
		|FROM
		|	(SELECT
		|		CASE
		|			WHEN ClientsStatuses.Client.MainManager = VALUE(Catalog.Users.EmptyRef)
		|				THEN &NotSpecified
		|			ELSE ClientsStatuses.Client.MainManager
		|		END AS Manager,
		|		SUM(CASE
		|				WHEN ClientsStatuses.ClientStatus = ""Lost""
		|					THEN -1
		|				ELSE 0
		|			END) AS Lost_,
		|		SUM(CASE
		|				WHEN ClientsStatuses.ClientStatus = ""New""
		|					THEN 1
		|				ELSE 0
		|			END) AS New_Items,
		|		SUM(CASE
		|				WHEN ClientsStatuses.ClientStatus = ""Returnee""
		|					THEN 1
		|				ELSE 0
		|			END) AS WasReturned
		|	FROM
		|		ClientsPreviousStatuses AS ClientsStatuses
		|	
		|	GROUP BY
		|		CASE
		|			WHEN ClientsStatuses.Client.MainManager = VALUE(Catalog.Users.EmptyRef)
		|				THEN &NotSpecified
		|			ELSE ClientsStatuses.Client.MainManager
		|		END) AS NestedQuery
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	ISNULL(CurCustomerBaseDynamics.Manager, DynamicsOfClientBase.Manager) AS Manager,
		|	ISNULL(CurCustomerBaseDynamics.Lost_, 0) AS LostCur,
		|	ISNULL(CurCustomerBaseDynamics.New_Items, 0) AS NewCur,
		|	ISNULL(CurCustomerBaseDynamics.WasReturned, 0) AS ReturnedCur,
		|	ISNULL(CurCustomerBaseDynamics.ShareOfNewCustomers, 0) AS ShareOfNewCustomersCur,
		|	ISNULL(DynamicsOfClientBase.Lost_, 0) AS LostSouls,
		|	ISNULL(DynamicsOfClientBase.New_Items, 0) AS NewFeatures,
		|	ISNULL(DynamicsOfClientBase.WasReturned, 0) AS ReturningGuests,
		|	ISNULL(DynamicsOfClientBase.ShareOfNewCustomers, 0) AS ShareOfNewCustomersPrevious
		|FROM
		|	CurCustomerBaseDynamics AS CurCustomerBaseDynamics
		|		FULL JOIN DynamicsOfClientBase AS DynamicsOfClientBase
		|		ON CurCustomerBaseDynamics.Manager = DynamicsOfClientBase.Manager
		|
		|ORDER BY
		|	ShareOfNewCustomersCur,
		|	NewCur
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|";
		
	Else
	
	MatchingRequestsData.Insert("CustomerBaseTrends",LastPacketNumber + 4);
	LastPacketNumber = LastPacketNumber + 4;
	
	Return "SELECT ALLOWED DISTINCT
	|	ABCXYZCustomerClassification.Partner,
	|	CASE
	|		WHEN ABCXYZCustomerClassification.Class = VALUE(Enum.ABCClassification.NotClassified)
	|			THEN FALSE
	|		ELSE TRUE
	|	END AS Classified
	|INTO LatestClassification
	|FROM
	|	InformationRegister.ABCXYZCustomerClassification AS ABCXYZCustomerClassification
	|WHERE
	|	ABCXYZCustomerClassification.ClassificationType = VALUE(Enum.TypesOfClassification.ABC)
	|	AND ABCXYZCustomerClassification.Period IN
	|			(SELECT
	|				MAX(ABCXYZCustomerClassification.Period) AS Period
	|			FROM
	|				InformationRegister.ABCXYZCustomerClassification AS ABCXYZCustomerClassification
	|			WHERE
	|				ABCXYZCustomerClassification.Period >= &PeriodEnding)
	|	AND ABCXYZCustomerClassification.Partner <> VALUE(Catalog.Partners.RetailCustomer)
	|	AND Partner.MainManager IN
	|		(SELECT
	|			FilterByManagers.Ref
	|		FROM
	|			FilterByManagers AS FilterByManagers)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED DISTINCT
	|	ABCXYZCustomerClassificationSliceLast.Partner,
	|	CASE
	|		WHEN ABCXYZCustomerClassificationSliceLast.Class = VALUE(Enum.ABCClassification.NotClassified)
	|			THEN FALSE
	|		ELSE TRUE
	|	END AS Classified
	|INTO AsOfThePeriodStart
	|FROM
	|	InformationRegister.ABCXYZCustomerClassification.SliceLast(&BeginOfPeriod, Partner <> VALUE(Catalog.Partners.RetailCustomer)	AND Partner.MainManager IN
	|		(SELECT
	|			FilterByManagers.Ref
	|		FROM
	|			FilterByManagers AS FilterByManagers)) AS ABCXYZCustomerClassificationSliceLast
	|WHERE
	|	ABCXYZCustomerClassificationSliceLast.ClassificationType = VALUE(Enum.TypesOfClassification.ABC)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	NestedQuery.Client,
	|	NestedQuery.ClientStatus
	|INTO ClientsStatuses
	|FROM
	|	(SELECT
	|		ISNULL(AsOfThePeriodStart.Partner, LatestClassification.Partner) AS Client,
	|		CASE
	|			WHEN AsOfThePeriodStart.Classified IS NULL 
	|				THEN CASE
	|						WHEN LatestClassification.Classified
	|							THEN ""New""
	|					END
	|			ELSE CASE
	|					WHEN AsOfThePeriodStart.Classified
	|							AND (NOT ISNULL(LatestClassification.Classified, FALSE))
	|						THEN ""Lost""
	|					ELSE CASE
	|							WHEN (NOT AsOfThePeriodStart.Classified)
	|									AND ISNULL(LatestClassification.Classified, FALSE)
	|								THEN ""Returnee""
	|						END
	|				END
	|		END AS ClientStatus
	|	FROM
	|		AsOfThePeriodStart AS AsOfThePeriodStart
	|			FULL JOIN LatestClassification AS LatestClassification
	|			ON AsOfThePeriodStart.Partner = LatestClassification.Partner) AS NestedQuery
	|WHERE
	|	(NOT NestedQuery.ClientStatus IS NULL )
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	NestedQuery.Manager,
	|	NestedQuery.Lost_,
	|	NestedQuery.New_Items AS New_Items,
	|	NestedQuery.WasReturned,
	|	CASE
	|		WHEN (NestedQuery.New_Items + NestedQuery.Lost_) = 0
	|			THEN 0
	|		ELSE NestedQuery.New_Items / (NestedQuery.New_Items + NestedQuery.Lost_)
	|	END AS ShareOfNewCustomers
	|FROM
	|	(SELECT
	|		CASE
	|			WHEN ClientsStatuses.Client.MainManager = VALUE(Catalog.Users.EmptyRef)
	|				THEN &NotSpecified
	|			ELSE ClientsStatuses.Client.MainManager
	|		END AS Manager,
	|		SUM(CASE
	|				WHEN ClientsStatuses.ClientStatus = ""Lost""
	|					THEN -1
	|				ELSE 0
	|			END) AS Lost_,
	|		SUM(CASE
	|				WHEN ClientsStatuses.ClientStatus = ""New""
	|					THEN 1
	|				ELSE 0
	|			END) AS New_Items,
	|		SUM(CASE
	|				WHEN ClientsStatuses.ClientStatus = ""Returnee""
	|					THEN 1
	|				ELSE 0
	|			END) AS WasReturned
	|	FROM
	|		ClientsStatuses AS ClientsStatuses
	|	
	|	GROUP BY
	|		CASE
	|			WHEN ClientsStatuses.Client.MainManager = VALUE(Catalog.Users.EmptyRef)
	|				THEN &NotSpecified
	|			ELSE ClientsStatuses.Client.MainManager
	|		END) AS NestedQuery
	|
	|ORDER BY
	|	ShareOfNewCustomers,
	|	New_Items
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|";
	
EndIf;

EndFunction

Function QueryTextSalesToNewCustomers(MatchingRequestsData,LastPacketNumber, StructureOfReportGenerationPeriods)
	
	If StructureOfReportGenerationPeriods.ThereIsExtraPeriod Then
		
		MatchingRequestsData.Insert("SalesToNewCustomers",LastPacketNumber + 3);
		LastPacketNumber = LastPacketNumber + 3;
		
		Return "SELECT
		|	CASE
		|		WHEN RevenueAndCostOfSalesTurnover.SalesOrder.Manager IS NULL 
		|			THEN &NotSpecified
		|		ELSE RevenueAndCostOfSalesTurnover.SalesOrder.Manager
		|	END AS Manager,
		|	SUM(RevenueAndCostOfSalesTurnover.RevenueAmountTurnover) AS Factor
		|INTO SalesToNewCustomersCur
		|FROM
		|	AccumulationRegister.RevenueAndCOGS.Turnovers(
		|			&BeginOfPeriod,
		|			&PeriodEnding,
		|			,
		|			(NOT AccountingDimensionByPartners.Partner IN
		|						(SELECT DISTINCT
		|							ABCXYZCustomerClassificationSliceLast.Partner
		|						FROM
		|							InformationRegister.ABCXYZCustomerClassification.SliceLast(&BeginOfPeriod, ) AS ABCXYZCustomerClassificationSliceLast))
		|				AND AccountingDimensionByPartners.Partner <> VALUE(Catalog.Partners.RetailCustomer) AND SalesOrder.Manager IN
		|						(SELECT
		|							FilterByManagers.Ref
		|						FROM 
		|							FilterByManagers AS FilterByManagers)) AS RevenueAndCostOfSalesTurnover
		|
		|GROUP BY
		|	CASE
		|		WHEN RevenueAndCostOfSalesTurnover.SalesOrder.Manager IS NULL 
		|			THEN &NotSpecified
		|		ELSE RevenueAndCostOfSalesTurnover.SalesOrder.Manager
		|	END
		|
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	CASE
		|		WHEN RevenueAndCostOfSalesTurnover.SalesOrder.Manager IS NULL 
		|			THEN &NotSpecified
		|		ELSE RevenueAndCostOfSalesTurnover.SalesOrder.Manager
		|	END AS Manager,
		|	SUM(RevenueAndCostOfSalesTurnover.RevenueAmountTurnover) AS Factor
		|INTO SalesToNewCustomersPrevious
		|FROM
		|	AccumulationRegister.RevenueAndCOGS.Turnovers(
		|			&BeginOfPeriod,
		|			&PeriodEnding,
		|			,
		|			(NOT AccountingDimensionByPartners.Partner IN
		|						(SELECT DISTINCT
		|							ABCXYZCustomerClassificationSliceLast.Partner
		|						FROM
		|							InformationRegister.ABCXYZCustomerClassification.SliceLast(&StartDateAdditionalPeriod, ) AS ABCXYZCustomerClassificationSliceLast))
		|				AND AccountingDimensionByPartners.Partner <> VALUE(Catalog.Partners.RetailCustomer) AND SalesOrder.Manager IN
		|						(SELECT
		|							FilterByManagers.Ref
		|						FROM 
		|							FilterByManagers AS FilterByManagers)) AS RevenueAndCostOfSalesTurnover
		|
		|GROUP BY
		|	CASE
		|		WHEN RevenueAndCostOfSalesTurnover.SalesOrder.Manager IS NULL 
		|			THEN &NotSpecified
		|		ELSE RevenueAndCostOfSalesTurnover.SalesOrder.Manager
		|	END
		|
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	ISNULL(NestedQuery.Manager, &NotSpecified) AS Manager,
		|	NestedQuery.Current_,
		|	NestedQuery.Previous,
		|	CASE
		|		WHEN NestedQuery.Current_ - NestedQuery.Previous > 0
		|			THEN NestedQuery.Current_ - NestedQuery.Previous
		|		ELSE 0
		|	END AS Growth,
		|	CASE
		|		WHEN NestedQuery.Current_ - NestedQuery.Previous < 0
		|			THEN NestedQuery.Current_ - NestedQuery.Previous
		|		ELSE 0
		|	END AS Slippage
		|FROM
		|	(SELECT
		|		CASE
		|			WHEN PreviousPeriod_.Manager IS NULL 
		|				THEN CurrentPeriod.Manager
		|			ELSE PreviousPeriod_.Manager
		|		END AS Manager,
		|		SUM(ISNULL(PreviousPeriod_.Factor, 0)) AS Previous,
		|		SUM(ISNULL(CurrentPeriod.Factor, 0)) AS Current_
		|	FROM
		|		SalesToNewCustomersPrevious AS PreviousPeriod_
		|			FULL JOIN SalesToNewCustomersCur AS CurrentPeriod
		|			ON PreviousPeriod_.Manager = CurrentPeriod.Manager
		|	
		|	GROUP BY
		|		CASE
		|			WHEN PreviousPeriod_.Manager IS NULL 
		|				THEN CurrentPeriod.Manager
		|			ELSE PreviousPeriod_.Manager
		|		END) AS NestedQuery
		|
		|ORDER BY
		|	NestedQuery.Current_
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|";
		
	Else
		
		MatchingRequestsData.Insert("SalesToNewCustomers",LastPacketNumber + 1);
		LastPacketNumber = LastPacketNumber + 1;
		
		Return "SELECT
		|	CASE
		|		WHEN RevenueAndCostOfSalesTurnover.SalesOrder.Manager IS NULL 
		|			THEN &NotSpecified
		|		ELSE PRESENTATION(RevenueAndCostOfSalesTurnover.SalesOrder.Manager)
		|	END AS Manager,
		|	SUM(RevenueAndCostOfSalesTurnover.RevenueAmountTurnover) AS Sales
		|FROM
		|	AccumulationRegister.RevenueAndCOGS.Turnovers(
		|			&BeginOfPeriod,
		|			&PeriodEnding,
		|			,
		|			(NOT AccountingDimensionByPartners.Partner IN
		|						(SELECT DISTINCT
		|							ABCXYZCustomerClassificationSliceLast.Partner
		|						FROM
		|							InformationRegister.ABCXYZCustomerClassification.SliceLast(&BeginOfPeriod, ) AS ABCXYZCustomerClassificationSliceLast))
		|				AND AccountingDimensionByPartners.Partner <> VALUE(Catalog.Partners.RetailCustomer) AND SalesOrder.Manager IN
		|						(SELECT
		|							FilterByManagers.Ref
		|						FROM 
		|							FilterByManagers AS FilterByManagers)) AS RevenueAndCostOfSalesTurnover
		|
		|GROUP BY
		|	CASE
		|		WHEN RevenueAndCostOfSalesTurnover.SalesOrder.Manager IS NULL 
		|			THEN &NotSpecified
		|		ELSE PRESENTATION(RevenueAndCostOfSalesTurnover.SalesOrder.Manager)
		|	END
		|
		|ORDER BY
		|	Sales ASC
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|";
		
	EndIf;
	
EndFunction

Function TextOfRequestForCustomerClaims(MatchingRequestsData,LastPacketNumber, StructureOfReportGenerationPeriods)
	
	If StructureOfReportGenerationPeriods.ThereIsExtraPeriod Then
		
		MatchingRequestsData.Insert("IncurredCustomerClaims",LastPacketNumber + 3);
		LastPacketNumber = LastPacketNumber + 3;
		
		Return "SELECT
		|	CASE
		|		WHEN CustomerClaims.EmployeeResponsible = VALUE(Catalog.Users.EmptyRef)
		|			THEN &NotSpecified
		|		ELSE CustomerClaims.EmployeeResponsible
		|	END AS Manager,
		|	COUNT(DISTINCT CustomerClaims.Ref) AS Factor
		|INTO ArisingCustomerClaimsCur
		|FROM
		|	Catalog.Complaints AS CustomerClaims
		|WHERE
		|	(NOT CustomerClaims.DeletionMark)
		|	AND CustomerClaims.RegistrationDate BETWEEN &BeginOfPeriod AND &PeriodEnding
		|	AND CustomerClaims.EmployeeResponsible IN
		|		(SELECT
		|			FilterByManagers.Ref
		|		FROM
		|			FilterByManagers AS FilterByManagers)
		|
		|GROUP BY
		|	CASE
		|		WHEN CustomerClaims.EmployeeResponsible = VALUE(Catalog.Users.EmptyRef)
		|			THEN &NotSpecified
		|		ELSE CustomerClaims.EmployeeResponsible
		|	END
		|
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	CASE
		|		WHEN CustomerClaims.EmployeeResponsible = VALUE(Catalog.Users.EmptyRef)
		|			THEN &NotSpecified
		|		ELSE CustomerClaims.EmployeeResponsible
		|	END AS Manager,
		|	COUNT(DISTINCT CustomerClaims.Ref) AS Factor
		|INTO ArisingCustomerClaims
		|FROM
		|	Catalog.Complaints AS CustomerClaims
		|WHERE
		|	(NOT CustomerClaims.DeletionMark)
		|	AND CustomerClaims.RegistrationDate BETWEEN &StartDateAdditionalPeriod AND &EndDateAdditionalPeriod
		|	AND CustomerClaims.EmployeeResponsible IN
		|		(SELECT
		|			FilterByManagers.Ref
		|		FROM
		|			FilterByManagers AS FilterByManagers)
		|
		|GROUP BY
		|	CASE
		|		WHEN CustomerClaims.EmployeeResponsible = VALUE(Catalog.Users.EmptyRef)
		|			THEN &NotSpecified
		|		ELSE CustomerClaims.EmployeeResponsible
		|	END
		|
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	ISNULL(NestedQuery.Manager, &NotSpecified) AS Manager,
		|	NestedQuery.Current_,
		|	NestedQuery.Previous,
		|	CASE
		|		WHEN NestedQuery.Current_ - NestedQuery.Previous > 0
		|			THEN NestedQuery.Current_ - NestedQuery.Previous
		|		ELSE 0
		|	END AS Growth,
		|	CASE
		|		WHEN NestedQuery.Current_ - NestedQuery.Previous < 0
		|			THEN NestedQuery.Current_ - NestedQuery.Previous
		|		ELSE 0
		|	END AS Slippage
		|FROM
		|	(SELECT
		|		CASE
		|			WHEN PreviousPeriod_.Manager IS NULL 
		|				THEN CurrentPeriod.Manager
		|			ELSE PreviousPeriod_.Manager
		|		END AS Manager,
		|		SUM(ISNULL(PreviousPeriod_.Factor, 0)) AS Previous,
		|		SUM(ISNULL(CurrentPeriod.Factor, 0)) AS Current_
		|	FROM
		|		ArisingCustomerClaims AS PreviousPeriod_
		|			FULL JOIN ArisingCustomerClaimsCur AS CurrentPeriod
		|			ON PreviousPeriod_.Manager = CurrentPeriod.Manager
		|	
		|	GROUP BY
		|		CASE
		|			WHEN PreviousPeriod_.Manager IS NULL 
		|				THEN CurrentPeriod.Manager
		|			ELSE PreviousPeriod_.Manager
		|		END) AS NestedQuery
		|
		|ORDER BY
		|	NestedQuery.Current_
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|";
		
	Else
		
		MatchingRequestsData.Insert("IncurredCustomerClaims",LastPacketNumber + 1);
		LastPacketNumber = LastPacketNumber + 1;
		
		Return "SELECT
		|	CASE
		|		WHEN CustomerClaims.EmployeeResponsible = VALUE(Catalog.Users.EmptyRef)
		|			THEN &NotSpecified
		|		ELSE PRESENTATION(CustomerClaims.EmployeeResponsible)
		|	END AS Manager,
		|	COUNT(DISTINCT CustomerClaims.Ref) AS Count
		|FROM
		|	Catalog.Complaints AS CustomerClaims
		|WHERE
		|	(NOT CustomerClaims.DeletionMark)
		|	AND CustomerClaims.RegistrationDate BETWEEN &BeginOfPeriod AND &PeriodEnding
		|	AND CustomerClaims.EmployeeResponsible IN
		|		(SELECT
		|			FilterByManagers.Ref
		|		FROM
		|			FilterByManagers AS FilterByManagers)
		|
		|GROUP BY
		|	CASE
		|		WHEN CustomerClaims.EmployeeResponsible = VALUE(Catalog.Users.EmptyRef)
		|			THEN &NotSpecified
		|		ELSE PRESENTATION(CustomerClaims.EmployeeResponsible)
		|	END
		|
		|ORDER BY
		|	Count
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|";
		
	EndIf;
	
EndFunction

Function TextOfRequestAboutReasonsForOccurrenceOfCustomerClaims(MatchingRequestsData,LastPacketNumber, StructureOfReportGenerationPeriods)
	
	If StructureOfReportGenerationPeriods.ThereIsExtraPeriod Then
		
		MatchingRequestsData.Insert("ComplaintReasons",LastPacketNumber + 3);
		LastPacketNumber = LastPacketNumber + 3;
		
		Return "SELECT ALLOWED TOP 5
		|	CustomerClaims.EmployeeResponsible AS Manager,
		|	PRESENTATION(CustomerClaims.ReasonForIncurrence) AS ReasonForIncurrence,
		|	COUNT(DISTINCT CustomerClaims.Ref) AS Count
		|INTO ReasonsForClaimsCur
		|FROM
		|	Catalog.Complaints AS CustomerClaims
		|WHERE
		|	(NOT CustomerClaims.DeletionMark)
		|	AND CustomerClaims.RegistrationDate BETWEEN &BeginOfPeriod AND &PeriodEnding
		|	AND CustomerClaims.EmployeeResponsible IN
		|		(SELECT
		|			FilterByManagers.Ref
		|		FROM
		|			FilterByManagers AS FilterByManagers)
		|
		|GROUP BY
		|	CustomerClaims.ReasonForIncurrence,
		|	CustomerClaims.EmployeeResponsible 
		|
		|ORDER BY
		|	Count DESC
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT ALLOWED TOP 5
		|	CustomerClaims.EmployeeResponsible AS Manager,
		|	PRESENTATION(CustomerClaims.ReasonForIncurrence) AS ReasonForIncurrence,
		|	COUNT(DISTINCT CustomerClaims.Ref) AS Count
		|INTO CausesOfClaimsPrevious
		|FROM
		|	Catalog.Complaints AS CustomerClaims
		|WHERE
		|	(NOT CustomerClaims.DeletionMark)
		|	AND CustomerClaims.RegistrationDate BETWEEN &StartDateAdditionalPeriod AND &EndDateAdditionalPeriod
		|	AND CustomerClaims.EmployeeResponsible IN
		|		(SELECT
		|			FilterByManagers.Ref
		|		FROM
		|			FilterByManagers AS FilterByManagers)
		|
		|GROUP BY
		|	CustomerClaims.ReasonForIncurrence,
		|	CustomerClaims.EmployeeResponsible
		|
		|ORDER BY
		|	Count DESC
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	CASE
		|		WHEN CausesOfClaimsPrevious.Manager = VALUE(Catalog.Users.EmptyRef)
		|			THEN &NotSpecified
		|		ELSE PRESENTATION(CausesOfClaimsPrevious.Manager)
		|	END AS Manager,
		|	CausesOfClaimsPrevious.ReasonForIncurrence,
		|	CausesOfClaimsPrevious.Count AS IndicatorValue,
		|	""Previous"" AS Period
		|FROM
		|	CausesOfClaimsPrevious AS CausesOfClaimsPrevious
		|
		|UNION ALL
		|
		|SELECT
		|	CASE
		|		WHEN ReasonsForClaimsCur.Manager = VALUE(Catalog.Users.EmptyRef)
		|			THEN &NotSpecified
		|		ELSE PRESENTATION(ReasonsForClaimsCur.Manager)
		|	END,
		|	ReasonsForClaimsCur.ReasonForIncurrence,
		|	ReasonsForClaimsCur.Count,
		|	""Current_""
		|FROM
		|	ReasonsForClaimsCur AS ReasonsForClaimsCur
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|";
		
	Else
		
		MatchingRequestsData.Insert("ComplaintReasons",LastPacketNumber + 1);
		LastPacketNumber = LastPacketNumber + 1;
		
		Return "SELECT ALLOWED TOP 5
		|	CASE
		|		WHEN CustomerClaims.EmployeeResponsible = VALUE(Catalog.Users.EmptyRef)
		|			THEN &NotSpecified
		|		ELSE PRESENTATION(CustomerClaims.EmployeeResponsible)
		|	END AS Manager,
		|	PRESENTATION(CustomerClaims.ReasonForIncurrence) AS ReasonForIncurrence,
		|	COUNT(DISTINCT CustomerClaims.Ref) AS Count
		|FROM
		|	Catalog.Complaints AS CustomerClaims
		|WHERE
		|	(NOT CustomerClaims.DeletionMark)
		|	AND CustomerClaims.RegistrationDate BETWEEN &BeginOfPeriod AND &PeriodEnding
		|	AND CustomerClaims.EmployeeResponsible IN
		|		(SELECT
		|			FilterByManagers.Ref
		|		FROM
		|			FilterByManagers AS FilterByManagers)
		|
		|GROUP BY
		|	CustomerClaims.ReasonForIncurrence,
		|	CASE
		|		WHEN CustomerClaims.EmployeeResponsible = VALUE(Catalog.Users.EmptyRef)
		|			THEN &NotSpecified
		|		ELSE PRESENTATION(CustomerClaims.EmployeeResponsible)
		|	END
		|
		|ORDER BY
		|	Count DESC
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|";
		
	EndIf;
	
EndFunction

Procedure AdditionalActionsForSetOfLossesOverdueReceivables(Query, StructureOfReportGenerationPeriods)
	
	If Query.TempTablesManager = Undefined Then
		Query.TempTablesManager = New TempTablesManager;
	EndIf;
	
	If Not GetFunctionalOption("NewOnlineARAPAccounting") Then
		ARAPAccountingServer.CalculateCustomerPaymentDates(Query.TempTablesManager, EndOfDay(StructureOfReportGenerationPeriods.EndDate));
	EndIf;

EndProcedure

#EndRegion

#Region DataOutput


// Outputs data to a report for a dataset
// 
// Parameters:
//  QueryResult - QueryResult - result of the executed request.
//  ReportTable - SpreadsheetDocument - report table.
//  GenerationParameters - Structure - 
//   DataSet - Structure - Contains:
// 	  * Description - String - name of the data set.
// 	ManagementAccountingCurrency - CatalogRef.Currencies - currency of management accounting.
// 	StructureOfReportGenerationPeriods - Structure - LongDesc:
// * EndDateAdditionalPeriod - Date - end date of the additional period.
// * StartDateAdditionalPeriod - Date - start date of the additional period.
// * ThereIsExtraPeriod - Boolean - indicates whether there is an additional period.
// 	Template - SpreadsheetDocument - report layout
//
Procedure OutputData(QueryResult,
	                    ReportTable,
	                    GenerationParameters,
	                    DataSet,
	                    ManagementAccountingCurrency, 
	                    StructureOfReportGenerationPeriods,
	                    Template)
	
	If QueryResult.IsEmpty() Then
		Return;
	EndIf;
	
	SetName      = DataSet.Name ;
	TitleText = DataSet.Description ;
	
	PrintDataSetHeader(ReportTable,TitleText,StructureOfReportGenerationPeriods.ThereIsExtraPeriod, Template);
	
	ReportTable.StartRowGroup(SetName);
	
	If GenerationParameters.DisplayLegend Then
	
		OutputLegend(ReportTable,
		               SetName,
		               StructureOfReportGenerationPeriods.ThereIsExtraPeriod,
		               GenerationParameters,
		               ManagementAccountingCurrency,
		               StructureOfReportGenerationPeriods,
		               Template);
	
	EndIf;
	
	DataTable = QueryResult.Unload();
	
	If GenerationParameters.DisplayCharts Then
		
		OutputDiagram(DataTable,ReportTable,SetName,True, StructureOfReportGenerationPeriods, Template);
		If StructureOfReportGenerationPeriods.ThereIsExtraPeriod Then
			OutputDiagram(DataTable, ReportTable, SetName, False, StructureOfReportGenerationPeriods, Template);
		EndIf;
		
	EndIf;
	
	If GenerationParameters.DisplayTables Then
		
		OutputTable_(DataTable,ReportTable,GenerationParameters,SetName,StructureOfReportGenerationPeriods, Template);
		
	EndIf;
	
	ReportTable.EndRowGroup();
	
EndProcedure

Procedure OutputLegend(ReportTable,DataSetName,ThereIsExtraPeriod,GenerationParameters, ManagementAccountingCurrency, StructureOfReportGenerationPeriods, Template)

	OutputAreaWithoutParameters("IsBlankString",ReportTable, Template);
	
	Area = Template.GetArea("Legend|LegendIndent");
	ReportTable.Put(Area);
	
	Area = Template.GetArea("Legend|LegendColumn");
	LegendText = LegendText(DataSetName, False, ManagementAccountingCurrency, StructureOfReportGenerationPeriods);
	If ThereIsExtraPeriod And (Not GenerationParameters.DisplayCharts) Then
		
		LegendText = LegendText +"
		                             |";
		
		LegendText = LegendText
		               + StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = 'Đang thực hiện so sánh với dữ liệu trong kỳ từ %1 đến %2';
																						|ru = 'Выполняется сравнение с данными за период с %1 по %2';
																						|en = 'Comparing with data for the period from %1 to %2'; fa = 'Comparing with data for the period from %1 to %2';
																						|it = 'Viene eseguito il confronto con i dati nel periodo da %1 a %2';
																						|pl = 'Trwa porównanie z danymi za okres od %1 do %2';
																						|tr = '%2 ilişkin %1dönemine ait verilerle bir karşılaştırma yapılmıştır. '") + " ",
		                 Format(StructureOfReportGenerationPeriods.StartDateAdditionalPeriod,"DLF=D"),
		                 Format(StructureOfReportGenerationPeriods.EndDateAdditionalPeriod,"DLF=D"));
		
	EndIf;
	Area.Parameters.LegendText = LegendText;
	ReportTable.Join(Area);
	
	If ThereIsExtraPeriod And GenerationParameters.DisplayCharts Then
		Area = Template.GetArea("Legend|LegendColumn");
		Area.Parameters.LegendText = LegendText(DataSetName, True, ManagementAccountingCurrency, StructureOfReportGenerationPeriods);
		ReportTable.Join(Area);
	EndIf;
	
	OutputAreaWithoutParameters("IsBlankString",ReportTable, Template);

EndProcedure

Procedure OutputDiagram(DataTable, ReportTable, SetName, MainPeriodIsDisplayed, StructureOfReportGenerationPeriods, Template)
	
	If MainPeriodIsDisplayed Then
		Area = Template.GetArea("Chart|DiagramIndentation");
		ReportTable.Put(Area);
	EndIf;
	
	Area = Template.GetArea("Chart|ChartColumn");
	
	Drawing = Area.Drawings.D1;
	ObjectDiagram = Drawing.Object;
	
	TablePreparedData = ConvertDataTableToChart(SetName,DataTable,MainPeriodIsDisplayed,StructureOfReportGenerationPeriods.ThereIsExtraPeriod);
	
	If MainPeriodIsDisplayed Then
		
		If SetName = "Profit_" Or SetName = "Sales"
			Or SetName = "ReceiptOfCash" Or SetName = "ReceiptOfDS_MinusCost" 
			Or SetName = "LossesOverdueReceivables" Or SetName = "SalesPerOpportunity"
			Or SetName = "SalesPerOneInteraction" Or SetName = "SalesToNewCustomers"
			Or SetName = "IncurredCustomerClaims" Then
			
			ObjectDiagram.ChartType = ChartType.Bar;
			ObjectDiagram.SeriesInRows  = False;
			ObjectDiagram.LabelType    = ChartLabelType.Value;
			
		EndIf;
		
	Else
		
		If SetName = "Profit_" Or SetName = "Sales"
			Or SetName = "ReceiptOfCash" Or SetName = "ReceiptOfDS_MinusCost" 
			Or SetName = "LossesOverdueReceivables" Or SetName = "SalesPerOpportunity"
			Or SetName = "SalesPerOneInteraction" Or SetName = "SalesToNewCustomers"
			Or SetName = "IncurredCustomerClaims" Then
			
			ObjectDiagram.ChartType   = ChartType.StackedBar;
			ObjectDiagram.SeriesInRows  = False;
			ObjectDiagram.LabelType    = ChartLabelType.Value;
			
		EndIf;
		
	EndIf;
	
	If SetName = "ManualDiscountsAreProvided" Or SetName = "EfficiencyOfOpportunityManagement"
		Or SetName = "InteractionEfficiency"  Then
		
		ObjectDiagram.ChartType = ChartType.StackedBar;
		ObjectDiagram.SeriesInRows  = False;
		ObjectDiagram.LabelType    = ChartLabelType.Value;
		
	ElsIf SetName = "CustomerBaseTrends" Then
		
		ObjectDiagram.ChartType = ChartType.Bar ;
		ObjectDiagram.LabelType  = ChartLabelType.Value;
		ObjectDiagram.SeriesInRows  = False;
		
	ElsIf  SetName = "ReasonsForLosingSalesOpportunities" Or SetName = "TheMainStagesOfLosses" 
			Or SetName = "DissatisfactionWithPrimaryDemand" Or SetName = "ComplaintReasons" Then
			
			ObjectDiagram.ChartType = ChartType.Pie ;
			ObjectDiagram.LabelType  = ChartLabelType.SeriesPercent;
		
	EndIf;
	
	ObjectDiagram.LabelValueFormat = "NFD=2; DLF=D";
	
	ObjectDiagram.DataSource = TablePreparedData;
	ObjectDiagram.DataSource = Undefined;
	
	ConvertColorNamesOfChartPointSeries(SetName,ObjectDiagram.Series);
	
	ReportTable.Join(Area);
	
EndProcedure

Procedure ConvertColorNamesOfChartPointSeries(SetName,Series)
	
	ColorBlueWithSteelTint = WebColors.SteelBlue;
	ColorProfitGain          = New Color(55,201,117);
	LossColor                  = New Color(216,216,216);
	ColorOtherInteractions    = New Color(179,172,134);
	ColorCircularFirst          = New Color(55,201,117);
	ColorCircularSecond          = WebColors.SteelBlue;
	ColorCircularThird          = New Color(0,70,110);
	ColorCircularShape_       = New Color(216,216,216);
	ColorCircularShape           = New Color(62,72,55);
	
	If SetName = "Sales" Then
		
		For Each OneSeries In Series Do
			If OneSeries.Text = "Sales" Or OneSeries.Text = "Current_" Then
				OneSeries.Text = NStr("vi = 'Bán hàng';
										|ru = 'Продажи';
										|en = 'Sales'; fa = 'فروش';
										|it = 'Vendite';
										|pl = 'Sales';
										|tr = 'Satışlar'");
				OneSeries.Color = ColorBlueWithSteelTint;
			ElsIf OneSeries.Text = "Previous" Then
				OneSeries.Text = NStr("vi = 'Bán hàng trong kỳ trước';
										|ru = 'Продажи предыдущего периода';
										|en = 'Sales of the previous period'; fa = 'Sales of the previous period';
										|it = 'Vendite periodo precedente';
										|pl = 'Sprzedaż w poprzednim okresie';
										|tr = 'Önceki dönem satışları'");
				OneSeries.Color = ColorBlueWithSteelTint;
			ElsIf OneSeries.Text = "Growth" Then
				OneSeries.Text = NStr("vi = 'Tăng bán hàng trong kỳ hiện tại';
										|ru = 'Прирост продаж в текущем периоде';
										|en = 'Sales growth in the current period'; fa = 'Sales growth in the current period';
										|it = 'Aumento vendite nel periodo corrente';
										|pl = 'Wzrost sprzedaży w bieżącym okresie';
										|tr = 'Cari dönemde satışlardaki artış'");
				OneSeries.Color = ColorProfitGain;
			ElsIf OneSeries.Text = "Slippage" Then
				OneSeries.Text = NStr("vi = 'Giảm bán hàng trong kỳ hiện tại';
										|ru = 'Уменьшение продаж в текущем периоде';
										|en = 'Sales decrease in the current period'; fa = 'Sales decrease in the current period';
										|it = 'Calo vendite nel periodo corrente';
										|pl = 'Spadek sprzedaży w bieżącym okresie';
										|tr = 'Cari dönemde satışlardaki azalma'");
				OneSeries.Color = LossColor;
			EndIf;
		EndDo;
		
	ElsIf SetName = "Profit_" Then
		
		For Each OneSeries In Series Do
			If OneSeries.Text = "Profit_" Or OneSeries.Text = "Current_" Then
				OneSeries.Text = NStr("vi = 'Lợi nhuận';
										|ru = 'Прибыль';
										|en = 'Profit'; fa = 'سود';
										|it = 'Utile';
										|pl = 'Profit';
										|tr = 'Kâr'");
				OneSeries.Color = ColorBlueWithSteelTint;
			ElsIf OneSeries.Text = "Previous" Then
				OneSeries.Text = NStr("vi = 'Lãi trong kỳ trước';
										|ru = 'Прибыль в предыдущем периоде';
										|en = 'Profit in the previous period'; fa = 'Profit in the previous period';
										|it = 'Utile del periodo precedente';
										|pl = 'Zysk w poprzednim okresie';
										|tr = 'Önceki dönem kârı'");
				OneSeries.Color = ColorBlueWithSteelTint;
			ElsIf OneSeries.Text = "Growth" Then
				OneSeries.Text = NStr("vi = 'Tăng lợi nhuận trong kỳ hiện tại';
										|ru = 'Прирост прибыли в текущем периоде';
										|en = 'Profit growth in the current period'; fa = 'Profit growth in the current period';
										|it = 'Aumento utile nel periodo corrente';
										|pl = 'Wzrost zysku w bieżącym okresie';
										|tr = 'Cari dönemdeki kâr artışı'");
				OneSeries.Color = ColorProfitGain;
			ElsIf OneSeries.Text = "Slippage" Then
				OneSeries.Text = NStr("vi = 'Giảm lợi nhuận trong kỳ hiện tại';
										|ru = 'Уменьшение прибыли в текущем периоде';
										|en = 'Profit decrease in the current period'; fa = 'Profit decrease in the current period';
										|it = 'Calo utile nel periodo corrente';
										|pl = 'Zmniejszenie zysku w bieżącym okresie';
										|tr = 'Cari dönemdeki kârda azalma'");
				OneSeries.Color = LossColor;
			EndIf;
		EndDo;
		
	ElsIf SetName = "ReceiptOfCash" Then
		
		For Each OneSeries In Series Do
			If OneSeries.Text = "ReceiptOfCash" Or OneSeries.Text = "Current_" Then
				OneSeries.Text = NStr("vi = 'Thu tiền';
										|ru = 'Поступление денежных средств';
										|en = 'Incoming payment'; fa = 'دریافت ورودی';
										|it = 'Flusso di cassa';
										|pl = 'Wpływ środków pieniężnych';
										|tr = 'Nakit girişi'");
				OneSeries.Color = ColorBlueWithSteelTint;
			ElsIf OneSeries.Text = "Previous" Then
				OneSeries.Text = NStr("vi = 'Thu tiền trong kỳ trước';
										|ru = 'Поступление денежных средств в предыдущем периоде';
										|en = 'Incoming payment in the previous period'; fa = 'Incoming payment in the previous period';
										|it = 'Flusso di cassa nel periodo precedente';
										|pl = 'Wpływy gotówkowe w poprzednim okresie';
										|tr = 'Önceki dönemdeki nakit girişi'");
				OneSeries.Color = ColorBlueWithSteelTint;
			ElsIf OneSeries.Text = "Growth" Then
				OneSeries.Text = NStr("vi = 'Tăng thu tiền trong kỳ hiện tại';
										|ru = 'Прирост поступления денежных средств в текущем периоде';
										|en = 'Growth of cash received in the current period'; fa = 'Growth of cash received in the current period';
										|it = 'Aumento flusso di cassa nel periodo corrente';
										|pl = 'Wzrost przepływów pieniężnych w bieżącym okresie';
										|tr = 'Cari dönemde nakit girişlerindeki artış'");
				OneSeries.Color = ColorProfitGain;
			ElsIf OneSeries.Text = "Slippage" Then
				OneSeries.Text = NStr("vi = 'Giảm thu tiền trong kỳ hiện tại';
										|ru = 'Уменьшение поступления денежных средств в текущем периоде';
										|en = 'Decrease in bank account receipt note in the current period'; fa = 'Decrease in bank account receipt note in the current period';
										|it = 'Calo flusso di cassa nel periodo corrente';
										|pl = 'Zmniejszenie przepływów pieniężnych w bieżącym okresie';
										|tr = 'Cari dönemde nakit girişlerindeki azalma'");
				OneSeries.Color = LossColor;
			EndIf;
		EndDo;
		
	ElsIf SetName = "ReceiptOfDS_MinusCost" Then
		
		For Each OneSeries In Series Do
			If OneSeries.Text = "ReceiptOfDS_MinusCost" Or OneSeries.Text = "Current_" Then
				OneSeries.Text = NStr("vi = 'Doanh thu (khi thanh toán) trừ giá vốn (khi giao hàng)';
										|ru = 'Выручка (по оплате) минус себестоимость (по отгрузке)';
										|en = 'Revenue (by payment) minus cost (by shipment)'; fa = 'Revenue (by payment) minus cost (by shipment)';
										|it = 'Entrate (pagamenti) meno costo (alla spedizione)';
										|pl = 'Przychód (przy płatności) minus koszt własny (przy wysyłce)';
										|tr = 'Gelir (ödemede) eksi satışların maliyeti (sevkiyatta)'");
				OneSeries.Color = ColorBlueWithSteelTint;
			ElsIf OneSeries.Text = "Previous" Then
				OneSeries.Text = NStr("vi = 'Giá trị chỉ số trong kỳ trước';
										|ru = 'Значение показателя в предыдущем периоде';
										|en = 'Indicator value in the previous period'; fa = 'Indicator value in the previous period';
										|it = 'Valore indicatore nel periodo precedente';
										|pl = 'Wartość wskaźnika w poprzednim okresie';
										|tr = 'Önceki dönemdeki gösterge değeri'");
				OneSeries.Color = ColorBlueWithSteelTint;
			ElsIf OneSeries.Text = "Growth" Then
				OneSeries.Text = NStr("vi = 'Tăng chỉ tiêu trong kỳ hiện tại';
										|ru = 'Прирост показателя в текущем периоде';
										|en = 'Indicator growth in the current period'; fa = 'Indicator growth in the current period';
										|it = 'Aumento indicatore nel periodo corrente';
										|pl = 'Wzrost wartości w bieżącym okresie';
										|tr = 'Cari dönemde göstergelerdeki artış'");
				OneSeries.Color = ColorProfitGain;
			ElsIf OneSeries.Text = "Slippage" Then
				OneSeries.Text = NStr("vi = 'Giảm chỉ tiêu trong kỳ hiện tại';
										|ru = 'Уменьшение показателя в текущем периоде';
										|en = 'Indicator decrease in the current period'; fa = 'Indicator decrease in the current period';
										|it = 'Calo indicatore nel periodo corrente';
										|pl = 'Spadek wskaźnika w bieżącym okresie';
										|tr = 'Cari dönemde göstergelerdeki azalma'");
				OneSeries.Color = LossColor;
			EndIf;
		EndDo;
		
	ElsIf SetName = "LossesOverdueReceivables" Then
		
		For Each OneSeries In Series Do
			If OneSeries.Text = "LossesDebitorka" Or OneSeries.Text = "Current_" Then
				OneSeries.Text = NStr("vi = 'Mất';
										|ru = 'Потери';
										|en = 'Losses'; fa = 'Losses';
										|it = 'Perdite';
										|pl = 'Losses';
										|tr = 'Zararlar'");
				OneSeries.Color = LossColor;
			ElsIf OneSeries.Text = "Previous" Then
				OneSeries.Text = NStr("vi = 'Giá trị chỉ số trong kỳ trước';
										|ru = 'Значение показателя в предыдущем периоде';
										|en = 'Indicator value in the previous period'; fa = 'Indicator value in the previous period';
										|it = 'Valore indicatore nel periodo precedente';
										|pl = 'Wartość wskaźnika w poprzednim okresie';
										|tr = 'Önceki dönemdeki gösterge değeri'");
				OneSeries.Color = ColorBlueWithSteelTint;
			ElsIf OneSeries.Text = "Growth" Then
				OneSeries.Text = NStr("vi = 'Tăng chỉ tiêu trong kỳ hiện tại';
										|ru = 'Прирост показателя в текущем периоде';
										|en = 'Indicator growth in the current period'; fa = 'Indicator growth in the current period';
										|it = 'Aumento indicatore nel periodo corrente';
										|pl = 'Wzrost wartości w bieżącym okresie';
										|tr = 'Cari dönemde göstergelerdeki artış'");
				OneSeries.Color = LossColor;
			ElsIf OneSeries.Text = "Slippage" Then
				OneSeries.Text = NStr("vi = 'Giảm chỉ tiêu trong kỳ hiện tại';
										|ru = 'Уменьшение показателя в текущем периоде';
										|en = 'Indicator decrease in the current period'; fa = 'Indicator decrease in the current period';
										|it = 'Calo indicatore nel periodo corrente';
										|pl = 'Spadek wskaźnika w bieżącym okresie';
										|tr = 'Cari dönemde göstergelerdeki azalma'");
				OneSeries.Color = ColorProfitGain;
			EndIf;
		EndDo;
		
	ElsIf SetName = "ManualDiscountsAreProvided" Then
		
		For Each OneSeries In Series Do
			If OneSeries.Text = "Profit_" Or OneSeries.Text = "ProfitCur"Then
				OneSeries.Text = NStr("vi = 'Lợi nhuận';
										|ru = 'Прибыль';
										|en = 'Profit'; fa = 'سود';
										|it = 'Utile';
										|pl = 'Profit';
										|tr = 'Kâr'");
				OneSeries.Color = ColorBlueWithSteelTint;
			ElsIf OneSeries.Text = "ManualDiscount" Or OneSeries.Text = "AmountOfManualDiscountCur" Then
				OneSeries.Text = NStr("vi = 'Số tiền chiết khấu thủ công';
										|ru = 'Сумма ручной скидки';
										|en = 'Discount adjustment amount'; fa = 'مبلغ اصلاح تخفیف';
										|it = 'Somma dello sconto da inserire manualmente';
										|pl = 'Suma rabatu ręcznego';
										|tr = 'İndirim düzeltmesi tutarı'");
				OneSeries.Color = LossColor;
			ElsIf OneSeries.Text = "ProfitPrevious" Then
				OneSeries.Text = NStr("vi = 'Lãi trong kỳ trước';
										|ru = 'Прибыль в предыдущем периоде';
										|en = 'Profit in the previous period'; fa = 'Profit in the previous period';
										|it = 'Utile del periodo precedente';
										|pl = 'Zysk w poprzednim okresie';
										|tr = 'Önceki dönem kârı'");
				OneSeries.Color = ColorBlueWithSteelTint;
			ElsIf OneSeries.Text = "AmountOfManualDiscountPrevious" Then
				OneSeries.Text = NStr("vi = 'Chiết khấu thủ công trong kỳ trước';
										|ru = 'Сумма ручной скидки в предыдущем периоде';
										|en = 'Discount adjustment amount in the previous period'; fa = 'Discount adjustment amount in the previous period';
										|it = 'Somma dello sconto da inserire manualmente nel periodo precedente';
										|pl = 'Suma rabatu ręcznego w poprzednim okresie';
										|tr = 'Önceki dönemdeki indirim düzeltmesi tutarı'");
				OneSeries.Color = ColorProfitGain;
				OneSeries.Color = LossColor;
			EndIf;
		EndDo;
		
	ElsIf SetName = "EfficiencyOfOpportunityManagement" Then
		
		For Each OneSeries In Series Do
			If OneSeries.Text = "WonDeals" Or OneSeries.Text = "WonDealsCur"Then
				OneSeries.Text = NStr("vi = 'Vụ việc đã giành được';
										|ru = 'Выиграно сделок';
										|en = 'Won sales opportunities'; fa = 'فرصت‌های فروش موفق';
										|it = 'Accordi vinti/conclusi';
										|pl = 'Wygrane transakcji';
										|tr = 'Kazanılan anlaşmalar'");
				OneSeries.Color = ColorBlueWithSteelTint;
			ElsIf OneSeries.Text = "LostDeals" Or OneSeries.Text = "LostTradesCur" Then
				OneSeries.Text = NStr("vi = 'Vụ việc thất bại';
										|ru = 'Проиграно сделок';
										|en = 'Lost sales opportunities'; fa = 'فرصت‌های فروش از دست رفته';
										|it = 'Accordi persi';
										|pl = 'Utracone transakcje';
										|tr = 'Kaybedilen anlaşmalar'");
				OneSeries.Color = LossColor;
			ElsIf OneSeries.Text = "WonDealsPrevious" Then
				OneSeries.Text = NStr("vi = 'Vụ việc đã giành được trong kỳ trước';
										|ru = 'Выиграно сделок в предыдущем периоде';
										|en = 'Sales opportunities won in the previous period'; fa = 'Sales opportunities won in the previous period';
										|it = 'Accordi vinti/conclusi nel periodo precedente';
										|pl = 'Wygrana transakcji w poprzednim okresie';
										|tr = 'Önceki dönemde kazanılan anlaşmalar'");
				OneSeries.Color = ColorBlueWithSteelTint;
			ElsIf OneSeries.Text = "LostTradesPrevious" Then
				OneSeries.Text = NStr("vi = 'Vụ việc thất bại trong kỳ trước';
										|ru = 'Проиграно сделок в предыдущем периоде';
										|en = 'Sales opportunities lost in the previous period'; fa = 'Sales opportunities lost in the previous period';
										|it = 'Accordi persi nel periodo precedente';
										|pl = 'Przegrane transakcji w poprzednim okresie';
										|tr = 'Önceki dönemde kaybedilen anlaşmalar'");
				OneSeries.Color = ColorProfitGain;
				OneSeries.Color = LossColor;
			EndIf;
		EndDo;
		
	ElsIf SetName = "InteractionEfficiency" Then
		
		For Each OneSeries In Series Do
			If OneSeries.Text = "InteractionsOnWonTrades" Or OneSeries.Text = "InteractionsOnWonDealsCur"Then
				OneSeries.Text = NStr("vi = 'Giao tiếp theo vụ việc đã thất bại';
										|ru = 'Взаимодействий по выигранным сделкам';
										|en = 'Interactions on won sales opportunities'; fa = 'Interactions on won sales opportunities';
										|it = 'Interazioni con accordi vinti/conclusi';
										|pl = 'Interakcje wg wygranych umów';
										|tr = 'Kazanılan anlaşmalarla ilgili etkileşimler'");
				OneSeries.Color = ColorBlueWithSteelTint;
			ElsIf OneSeries.Text = "InteractionsOnLostTrades" Or OneSeries.Text = "InteractionsOnLostTradesCur" Then
				OneSeries.Text = NStr("vi = 'Giao tiếp theo vụ việc đã thất bại';
										|ru = 'Взаимодействий по проигранным сделкам';
										|en = 'Interactions on lost sales opportunities'; fa = 'Interactions on lost sales opportunities';
										|it = 'Interazioni con accordi persi';
										|pl = 'Interakcje wg przegranych umów';
										|tr = 'Kaybedilen anlaşmalarla ilgili etkileşimler'");
				OneSeries.Color = LossColor;
			ElsIf OneSeries.Text = "OtherInteractions" Or OneSeries.Text = "OtherInteractionsCur" Then
				OneSeries.Text = NStr("vi = 'Giao tiếp khác';
										|ru = 'Прочие взаимодействия';
										|en = 'Other interactions'; fa = 'Other interactions';
										|it = 'Altre interazioni';
										|pl = 'Inne interakcje';
										|tr = 'Diğer etkileşimler'");
				OneSeries.Color = ColorOtherInteractions;
			ElsIf OneSeries.Text = "InteractionsOnWonDeals" Then
				OneSeries.Text = NStr("vi = 'Giao tiếp theo vụ việc đã thất bại trong kỳ trước';
										|ru = 'Взаимодействий по выигранным сделкам в предыдущем периоде';
										|en = 'Interactions on won sales opportunities in the previous period'; fa = 'Interactions on won sales opportunities in the previous period';
										|it = 'Interazioni con accordi vinti/conclusi nel precedente periodo';
										|pl = 'Interakcje za wygrane umowy w poprzednim okresie';
										|tr = 'Önceki dönemde kazanılan anlaşmalarla ilgili etkileşimler'");
				OneSeries.Color = ColorBlueWithSteelTint;
			ElsIf OneSeries.Text = "InteractionsOnLostTradesPrevious" Then
				OneSeries.Text = NStr("vi = 'Giao tiếp theo vụ việc đã thất bại trong kỳ trước';
										|ru = 'Взаимодействий по проигранным сделкам в предыдущем периоде';
										|en = 'Interactions on lost sales opportunities in the previous period'; fa = 'Interactions on lost sales opportunities in the previous period';
										|it = 'Interazioni con accordi persi nel precedente periodo';
										|pl = 'Interakcje dotyczące przegranych umów w poprzednim okresie';
										|tr = 'Önceki dönemde kaybedilen anlaşmalarla ilgili etkileşimler'");
				OneSeries.Color = ColorProfitGain;
				OneSeries.Color = LossColor;
			ElsIf OneSeries.Text = "OtherInteractionsPrevious" Then
				OneSeries.Text = NStr("vi = 'Giao tiếp khác trong kỳ trước';
										|ru = 'Прочие взаимодействия в предыдущем периоде';
										|en = 'Other interactions in the previous period'; fa = 'Other interactions in the previous period';
										|it = 'Altre interazioni nel precedente periodo';
										|pl = 'Inne interakcje w poprzednim okresie';
										|tr = 'Önceki dönemde gerçekleşen diğer etkileşimler'");
				OneSeries.Color = ColorOtherInteractions;
			EndIf;
		EndDo;
		
	ElsIf SetName = "SalesPerOpportunity" Then
		
		For Each OneSeries In Series Do
			If OneSeries.Text = "SalesPerTransaction" Or OneSeries.Text = "Current_" Then
				OneSeries.Text = NStr("vi = 'Bán hàng trên một vụ việc';
										|ru = 'Продажи на одну сделку';
										|en = 'Sales per sales opportunity'; fa = 'Sales per sales opportunity';
										|it = 'Vendite per un accordo';
										|pl = 'Sprzedaż w jednej umowie';
										|tr = 'İşlem başına satışlar'");
				OneSeries.Color = ColorBlueWithSteelTint;
			ElsIf OneSeries.Text = "Previous" Then
				OneSeries.Text = NStr("vi = 'Bán hàng trên một vụ việc trong kỳ trước';
										|ru = 'Продажи на одну сделку в предыдущем периоде';
										|en = 'Sales per sales opportunity in the previous period'; fa = 'Sales per sales opportunity in the previous period';
										|it = 'Vendite per un accordo nel precedente periodo';
										|pl = 'Sprzedaży za jedną umowę w poprzednim okresie';
										|tr = 'Önceki dönemdeki işlem başına satışlar'");
				OneSeries.Color = ColorBlueWithSteelTint;
			ElsIf OneSeries.Text = "Growth" Then
				OneSeries.Text = NStr("vi = 'Tăng bán hàng trên một vụ việc trong kỳ hiện tại';
										|ru = 'Прирост продаж на одну сделку в текущем периоде';
										|en = 'Growth of sales per sales opportunity in the current period'; fa = 'Growth of sales per sales opportunity in the current period';
										|it = 'Aumento vendite per un accordo nel periodo corrente';
										|pl = 'Wzrost sprzedaży za jedną umowę w bieżącym okresie';
										|tr = 'Cari dönemde işlem başına satışlardaki artış'");
				OneSeries.Color = ColorProfitGain;
			ElsIf OneSeries.Text = "Slippage" Then
				OneSeries.Text = NStr("vi = 'Giảm bán hàng trên một vụ việc trong kỳ hiện tại';
										|ru = 'Уменьшение продаж на одну сделку в текущем периоде';
										|en = 'Decrease in sales per sales opportunity in the current period'; fa = 'Decrease in sales per sales opportunity in the current period';
										|it = 'Calo vendite per un accordo nel periodo corrente';
										|pl = 'Spadek sprzedaży za jedną umowę w bieżącym okresie';
										|tr = 'Cari dönemde işlem başına satışlardaki azalma'");
				OneSeries.Color = LossColor;
			EndIf;
		EndDo;
		
	ElsIf SetName = "SalesPerOneInteraction" Then
		
		For Each OneSeries In Series Do
			If OneSeries.Text = "InteractionSales" Or OneSeries.Text = "Current_" Then
				OneSeries.Text = NStr("vi = 'Bán hàng trên một lần giao tiếp';
										|ru = 'Продажи на одно взаимодействие';
										|en = 'Sales per one interaction'; fa = 'Sales per one interaction';
										|it = 'Vendite per una interazione';
										|pl = 'Sprzedaż w jednej interakcji';
										|tr = 'Etkileşim başına satışlar'");
				OneSeries.Color = ColorBlueWithSteelTint;
			ElsIf OneSeries.Text = "Previous" Then
				OneSeries.Text = NStr("vi = 'Bán hàng trên một lần giao tiếp trong kỳ trước';
										|ru = 'Продажи на одно взаимодействие в предыдущем периоде';
										|en = 'Sales per one interaction in the previous period'; fa = 'Sales per one interaction in the previous period';
										|it = 'Vendite per una interazione nel precedente periodo';
										|pl = 'Sprzedaży za jedną interakcję w poprzednim okresie';
										|tr = 'Önceki dönemde etkileşim başına satışlar'");
				OneSeries.Color = ColorBlueWithSteelTint;
			ElsIf OneSeries.Text = "Growth" Then
				OneSeries.Text = NStr("vi = 'Tăng bán hàng trên một lần giao tiếp trong kỳ hiện tại';
										|ru = 'Прирост продаж на одно взаимодействие в текущем периоде';
										|en = 'Sales growth on one interaction in the current period'; fa = 'Sales growth on one interaction in the current period';
										|it = 'Aumento vendite per una interazione nel periodo corrente';
										|pl = 'Wzrost sprzedaży w jednej interakcji w bieżącym okresie';
										|tr = 'Cari dönemde etkileşim başına satışlarda artış'");
				OneSeries.Color = ColorProfitGain;
			ElsIf OneSeries.Text = "Slippage" Then
				OneSeries.Text = NStr("vi = 'Giảm bán hàng trên một giao tiếp trong kỳ hiện tại';
										|ru = 'Уменьшение продаж на одно взаимодействие в текущем периоде';
										|en = 'Decrease in sales on one interaction in the current period'; fa = 'Decrease in sales on one interaction in the current period';
										|it = 'Calo vendite per una interazione nel periodo corrente';
										|pl = 'Spadek sprzedaży w jednej interakcji w bieżącym okresie';
										|tr = 'Cari dönemde etkileşim başına satışlarda azalma'");
				OneSeries.Color = LossColor;
			EndIf;
		EndDo;
		
	ElsIf SetName = "TheMainStagesOfLosses" Or SetName = "ReasonsForLosingSalesOpportunities"
		Or SetName = "DissatisfactionWithPrimaryDemand" Or SetName = "ComplaintReasons" Then
		
		If Series.Count() > 0 Then
			Series[0].Color = ColorCircularFirst;
		EndIf;
		If Series.Count() > 1 Then
			Series[1].Color = ColorCircularSecond;
		EndIf;
		If Series.Count() > 2 Then
			Series[2].Color = ColorCircularThird;
		EndIf;
		If Series.Count() > 3 Then
			Series[3].Color = ColorCircularShape_;
		EndIf;
		If Series.Count() > 4 Then
			Series[4].Color = ColorCircularShape;
		EndIf;
		
	ElsIf SetName = "SalesToNewCustomers" Then
		
		For Each OneSeries In Series Do
			If OneSeries.Text = "Sales" Or OneSeries.Text = "Current_" Then
				OneSeries.Text = NStr("vi = 'Bán hàng';
										|ru = 'Продажи';
										|en = 'Sales'; fa = 'فروش';
										|it = 'Vendite';
										|pl = 'Sales';
										|tr = 'Satışlar'");
				OneSeries.Color = ColorBlueWithSteelTint;
			ElsIf OneSeries.Text = "Previous" Then
				OneSeries.Text = NStr("vi = 'Bán hàng cho khách hàng mới trong kỳ trước';
										|ru = 'Продажи новым клиентам в предыдущем периоде';
										|en = 'Sales to new customers in the previous period'; fa = 'Sales to new customers in the previous period';
										|it = 'Vendite a nuovi clienti nel periodo precedente';
										|pl = 'Sprzedaż dla nowych klientów w poprzednim okresie';
										|tr = 'Önceki dönemde yeni müşterilere yapılan satışlar'");
				OneSeries.Color = ColorBlueWithSteelTint;
			ElsIf OneSeries.Text = "Growth" Then
				OneSeries.Text = NStr("vi = 'Tăng bán hàng cho khách hàng mới trong kỳ hiện tại';
										|ru = 'Прирост продаж новым клиентам в текущем периоде';
										|en = 'Growth of sales to new customers in the current period'; fa = 'Growth of sales to new customers in the current period';
										|it = 'Aumento delle vendite a nuovi clienti nel periodo corrente';
										|pl = 'Wzrost sprzedaży dla nowych klientów w bieżącym okresie';
										|tr = 'Cari dönemde yeni müşterilere yapılan satışlardaki artış'");
				OneSeries.Color = ColorProfitGain;
			ElsIf OneSeries.Text = "Slippage" Then
				OneSeries.Text = NStr("vi = 'Giảm bán hàng cho khách hàng mới trong kỳ hiện tại';
										|ru = 'Уменьшение продаж новым клиентам в текущем периоде';
										|en = 'Decrease in sales to new customers in the current period'; fa = 'Decrease in sales to new customers in the current period';
										|it = 'Calo vendite a nuovi clienti nel periodo corrente';
										|pl = 'Spadek sprzedaży dla nowych klientów w bieżącym okresie';
										|tr = 'Cari dönemde yeni müşterilere yapılan satışlardaki azalma'");
				OneSeries.Color = LossColor;
			EndIf;
		EndDo;
		
		ElsIf SetName = "IncurredCustomerClaims" Then
		
		For Each OneSeries In Series Do
			If OneSeries.Text = "Count" Or OneSeries.Text = "Current_" Then
				OneSeries.Text = NStr("vi = 'Số lượng khiếu nại';
										|ru = 'Количество претензий';
										|en = 'Number of complaints'; fa = 'Number of complaints';
										|it = 'Numero reclami';
										|pl = 'Liczba roszczeń';
										|tr = 'Tazminat talebi miktarı'");
				OneSeries.Color = LossColor;
			ElsIf OneSeries.Text = "Previous" Then
				OneSeries.Text = NStr("vi = 'Số lượng khiếu nại trong kỳ trước';
										|ru = 'Количество претензий в предыдущем периоде';
										|en = 'Number of complaints in the previous period'; fa = 'Number of complaints in the previous period';
										|it = 'Numero reclami nel precedente periodo';
										|pl = 'Liczba roszczeń w poprzednim okresie';
										|tr = 'Önceki dönemdeki tazminat talebi miktarı'");
				OneSeries.Color = ColorBlueWithSteelTint;
			ElsIf OneSeries.Text = "Growth" Then
				OneSeries.Text = NStr("vi = 'Tăng khiếu nại được ghi nhận trong kỳ hiện tại';
										|ru = 'Прирост зарегистрированных претензий в текущем периоде';
										|en = 'Growth of the registered complaints in the current period'; fa = 'Growth of the registered complaints in the current period';
										|it = 'Aumento dei reclami registrati nel periodo corrente';
										|pl = 'Wzrost roszczeń zarejestrowanych w bieżącym okresie';
										|tr = 'Cari dönemde kayıtlı tazminat taleplerinde artış'");
				OneSeries.Color = LossColor;
			ElsIf OneSeries.Text = "Slippage" Then
				OneSeries.Text = NStr("vi = 'Giảm khiếu nại đã ghi nhận trong kỳ hiện tại';
										|ru = 'Уменьшение зарегистрированных претензий в текущем периоде';
										|en = 'Decrease of registered complaints in the current period'; fa = 'Decrease of registered complaints in the current period';
										|it = 'Calo dei reclami registrati nel periodo corrente';
										|pl = 'Spadek roszczeń zarejestrowanych w bieżącym okresie';
										|tr = 'Cari dönemde kayıtlı tazminat taleplerinde azalma'");
				OneSeries.Color = ColorProfitGain;
			EndIf;
		EndDo;
		
		ElsIf SetName = "CustomerBaseTrends" Then
		
		For Each OneSeries In Series Do
			If OneSeries.Text = "New_Items" Or OneSeries.Text = "NewCur" Then
				OneSeries.Text = NStr("vi = 'Khách hàng mới';
										|ru = 'Новые клиенты';
										|en = 'New customers'; fa = 'New customers';
										|it = 'Nuovi clienti';
										|pl = 'Nowi klienci';
										|tr = 'Yeni müşteriler'");
				OneSeries.Color = ColorProfitGain;
			ElsIf OneSeries.Text = "Lost_" Or OneSeries.Text = "LostCur" Then
				OneSeries.Text = NStr("vi = 'Khách hàng bị mất';
										|ru = 'Потерянные клиенты';
										|en = 'Lost customers'; fa = 'Lost customers';
										|it = 'Clienti persi';
										|pl = 'Utracone klienci';
										|tr = 'Kaybedilen müşteriler'");
				OneSeries.Color = LossColor;
			ElsIf OneSeries.Text = "WasReturned" Or OneSeries.Text = "ReturnedCur"Then
				OneSeries.Text = NStr("vi = 'Khách hàng quay trở lại';
										|ru = 'Вернувшиеся клиенты';
										|en = 'Returned customers'; fa = 'Returned customers';
										|it = 'Clienti ritornati';
										|pl = 'Powracające klienci';
										|tr = 'Geri dönen müşteriler'");
				OneSeries.Color = ColorBlueWithSteelTint;
			ElsIf OneSeries.Text = "NewFeatures" Then
				OneSeries.Text = NStr("vi = 'Khách hàng mới trong kỳ trước';
										|ru = 'Новые клиенты в предыдущем периоде';
										|en = 'New customers in the previous period'; fa = 'New customers in the previous period';
										|it = 'Nuovi clienti nel precedente periodo';
										|pl = 'Nowe klienci w poprzednim okresie';
										|tr = 'Önceki dönemdeki yeni müşteriler'");
				OneSeries.Color = ColorProfitGain;
			ElsIf OneSeries.Text = "ReturningGuests" Then
				OneSeries.Text = NStr("vi = 'Khách hàng quay trở lại trong kỳ trước';
										|ru = 'Вернувшиеся клиенты в предыдущем периоде';
										|en = 'Customers returned in the previous period'; fa = 'Customers returned in the previous period';
										|it = 'Clienti ritornati nel precedente periodo';
										|pl = 'Powracający klienci w poprzednim okresie';
										|tr = 'Önceki dönemde geri dönen müşteriler'");
				OneSeries.Color = ColorBlueWithSteelTint;
			ElsIf OneSeries.Text = "LostSouls" Then
				OneSeries.Text = NStr("vi = 'Khách hàng bị mất trong kỳ trước';
										|ru = 'Потерянные клиенты в предыдущем периоде';
										|en = 'Lost customers in the previous period'; fa = 'Lost customers in the previous period';
										|it = 'Clienti persi nel precedente periodo';
										|pl = 'Utracono klientów w poprzednim okresie';
										|tr = 'Önceki dönemde kaybedilen müşteriler'");
				OneSeries.Color = LossColor;
			EndIf;
		EndDo;
		
	EndIf;
	
EndProcedure

Function LegendText(DataSetName, ForAdditionalPeriod, ManagementAccountingCurrency, StructureOfReportGenerationPeriods)
	
	If Not ForAdditionalPeriod Then
		
		StartDate = Format(StructureOfReportGenerationPeriods.StartDate,"DLF=D");
		EndDate = Format(StructureOfReportGenerationPeriods.EndDate,"DLF=D");
		
	Else
		
		StartDate = Format(StructureOfReportGenerationPeriods.StartDateAdditionalPeriod,"DLF=D");
		EndDate = Format(StructureOfReportGenerationPeriods.EndDateAdditionalPeriod,"DLF=D");
		
	EndIf;
	
	If DataSetName = "Sales" Then
		
		If Not ForAdditionalPeriod Then
			
			LegendText = StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = 'Thông tin về số tiền bán hàng trong kỳ từ %1 đến %2 theo tiền tệ kế toán quản trị (%3).
			                                                                       |Thực hiện sắp xếp theo trình tự giảm dần doanh thu.';
			                                                                       |ru = 'Информация о продажах за период с %1 по %2 в валюте управленческого учета (%3). 
			                                                                       |Сортировка производится в порядке убывания продаж.';
			                                                                       |en = 'Information about sales for the period from %1 to %2 in the currency of management accounting (%3).
			                                                                       |Sales have been ordered in descending order.'; fa = 'Information about sales for the period from %1 to %2 in the currency of management accounting (%3).
			                                                                       |Sales have been ordered in descending order.';
			                                                                       |it = 'Informazioni sulle vendite per il periodo da %1 a %2 sono nella valuta della contabilità di gestione (%3).
			                                                                       | L''ordinamento viene eseguito in ordine decrescente di vendite.';
			                                                                       |pl = 'Informacje o sprzedaży za okres od %1 do %2 w walucie ewidencji zarządczej (%3). 
			                                                                       |Sortowanie odbywa się wg sprzedaży malejącego.';
			                                                                       |tr = 'Yönetim muhasebesi para biriminde (%3)%1 ile %2arasındaki dönem için satış bilgileri.
			                                                                       | Azalan satış sırasına göre sıralanır.'"),
			                                                                       StartDate,
			                                                                       EndDate,
			                                                                       ManagementAccountingCurrency);
			
		Else
			LegendText = StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = 'So sánh với doanh số bán hàng trong kỳ từ %1 đến %2 theo tiền tệ kế toán quản trị (%3).
			                                                                       |Hiển thị thông tin bán hàng kỳ trước. Nếu trong kỳ này, số tiền bán hàng tăng 
			                                                                       |so với kỳ trước thì số tiền tăng thêm (màu xanh lá cây) là số tiền bán hàng
			                                                                       |tăng so với kỳ trước. Nếu số tiền bán hàng của kỳ này giảm
			                                                                       |so với kỳ trước thì số tiền bán hàng giảm này sẽ hiển thị màu xám.';
			                                                                       |ru = 'Сравнение с продажами за период с %1 по %2 в валюте управленческого учета (%3).
			                                                                       |Выводится информация о продажах предыдущего периода. Если в текущем периоде сумма продаж увеличилась 
			                                                                       |по сравнению с предыдущим периодом, то дополнительно (зеленым цветом) отображается сумма, на которую
			                                                                       |увеличились продажи по сравнению с предыдущим периодом. Если суммы продаж в текущем периоде уменьшились
			                                                                       |по сравнению с предыдущим периодом, то суммы, на которую уменьшились продажи отображаются серым цветом.';
			                                                                       |en = 'Comparison with sales for the period from %1 to %2 in management accounting currency (%3).
			                                                                       |Information about sales of the previous period is displayed. If sales amount for the current period is greater 
			                                                                       |than for the previous period, 
			                                                                       | difference amount is highlighted in green additionally. If the sales amounts for the current period are less 
			                                                                       | for the previous period, difference amounts are highlighted in gray.'; fa = 'Comparison with sales for the period from %1 to %2 in management accounting currency (%3).
			                                                                       |Information about sales of the previous period is displayed. If sales amount for the current period is greater 
			                                                                       |than for the previous period, 
			                                                                       | difference amount is highlighted in green additionally. If the sales amounts for the current period are less 
			                                                                       | for the previous period, difference amounts are highlighted in gray.';
			                                                                       |it = 'Confronto con le vendite del periodo da %1 a %2 nella valuta della contabilità di gestione (%3).
			                                                                       | Vengono fornite le informazioni sulle vendite del periodo precedente. Se nel periodo corrente l''importo delle vendite è aumentato
			                                                                       | rispetto al periodo precedente, alla somma viene aggiunto (in verde)  l''importo di vendita
			                                                                       | aumentato rispetto al periodo precedente. Se gli importi delle vendite nel periodo corrente sono diminuiti
			                                                                       | rispetto al periodo precedente, gli importi con cui le vendite sono diminuite vengono visualizzati in grigio.';
			                                                                       |pl = 'Porównaj sprzedaży za okres od %1 do %2 w walucie ewidencji zarządczej (%3).
			                                                                       |Wyświetlane są informacje o sprzedaży z poprzedniego okresu. Jeśli w bieżącym okresie kwota sprzedaży wzrosła 
			                                                                       |w porównaniu z poprzednim okresem, wtedy dodatkowo (na zielono) wyświetlana jest kwota, o którą
			                                                                       |wzrosła sprzedaż w porównaniu z poprzednim okresem. Jeśli kwoty sprzedaży w bieżącym okresie spadły
			                                                                       |w porównaniu z poprzednim okresem, to kwoty, na którą spadła sprzedaż są wyświetlane w kolorze szarym.';
			                                                                       |tr = 'Yönetim muhasebesi para biriminde (%3) %1ile %2arasındaki döneme ait satışlarla karşılaştırma.
			                                                                       | Önceki döneme ait satışlar görüntülenir. Cari dönem satışları bir önceki döneme göre artmışsa,
			                                                                       | ek olarak (yeşil renkte) satışların bir önceki döneme göre arttığı 
			                                                                       |miktar gösterilir. Cari dönem satışları bir önceki döneme göre azalmışsa,
			                                                                       | satışların azaldığı miktar gri renkte gösterilir.'"),
			                                                                       StartDate,
			                                                                       EndDate,
			                                                                       ManagementAccountingCurrency);
			
		EndIf;
		
	ElsIf DataSetName = "Profit_" Then
		
		If Not ForAdditionalPeriod Then
			
			LegendText = StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = 'Thông tin về lợi nhuận trong kỳ từ %1 đến %2 theo tiền tệ kế toán quản trị (%3).
			                                                                       |Thực hiện sắp xếp theo trình tự giảm dần lợi nhuận.';
			                                                                       |ru = 'Информация о прибыли полученной за период с %1 по %2 в валюте управленческого учета (%3). 
			                                                                       |Сортировка производится в порядке убывания прибыли.';
			                                                                       |en = 'Information about income received for the period from %1 to %2 in management accounting currency (%3). 
			                                                                       |Income is sorted in descending order.'; fa = 'Information about income received for the period from %1 to %2 in management accounting currency (%3). 
			                                                                       |Income is sorted in descending order.';
			                                                                       |it = 'Informazioni sugli utili per il periodo da %1 a%2 nella valuta della contabilità di gestione (%3).
			                                                                       | L''ordinamente viene eseguito in ordine decrescente di utile.';
			                                                                       |pl = 'Informacje o zysku, uzyskanym za okres od %1 do %2 w walucie ewidencji zarządczej (%3). 
			                                                                       |Sortowanie odbywa się wg zysku malejącego.';
			                                                                       |tr = 'Yönetim muhasebesi para birimi (%3) cinsinden %1itibaren %2kadar dönem kârına ilişkin bilgiler.
			                                                                       | Azalan kâr sırasına göre sıralanmıştır.'"),
			                                                                       StartDate,
			                                                                       EndDate,
			                                                                       ManagementAccountingCurrency);
			
		Else
			LegendText = StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = 'So sánh với lợi nhuận nhận được trong kỳ từ %1 đến %2 theo tiền tệ kế toán quản trị (%3). 
			                                                                       |Hiển thị thông tin lợi nhuận của kỳ trước. Nếu trong kỳ này, lợi nhuận tăng 
			                                                                       |so với kỳ trước thì số tiền tăng thêm (màu xanh lá cây) là số tiền lợi nhuận
			                                                                       |tăng so với kỳ trước. Nếu số tiền bán hàng của kỳ này giảm
			                                                                       |so với kỳ trước thì số tiền bán hàng giảm này sẽ hiển thị màu xám.';
			                                                                       |ru = 'Сравнение с прибылью полученной за период с %1 по %2 в валюте управленческого учета (%3). 
			                                                                       |Выводится информация о полученной прибыли в предыдущем периоде. Если в текущем периоде прибыль увеличилась 
			                                                                       |по сравнению с предыдущим периодом, то дополнительно (зеленым цветом) отображается сумма, на которую
			                                                                       |увеличилась прибыль по сравнению с предыдущим периодом. Если прибыль в текущем периоде уменьшилась
			                                                                       |по сравнению с предыдущим периодом, то сумма, на которую уменьшилась прибыль отображается серым цветом.';
			                                                                       |en = 'Comparison with the profit received for the period from %1 to %2 in management accounting currency (%3).
			                                                                       |Information about the received profit for the previous period is displayed. If the profit for the current period is greater 
			                                                                       |than for the previous period, 
			                                                                       |the difference amount is highlighted in green additionally. 
			                                                                       |If the profit for the current period is less than for the previous period, the difference amount is highlighted in gray.'; fa = 'Comparison with the profit received for the period from %1 to %2 in management accounting currency (%3).
			                                                                       |Information about the received profit for the previous period is displayed. If the profit for the current period is greater 
			                                                                       |than for the previous period, 
			                                                                       |the difference amount is highlighted in green additionally. 
			                                                                       |If the profit for the current period is less than for the previous period, the difference amount is highlighted in gray.';
			                                                                       |it = 'Confronto con gli utili del periodo da %1 a %2 nella valuta della contabilità di gestione (%3).
			                                                                       | Vengono fornite le informazioni sugli utili del periodo precedente. Se nel periodo corrente l''importo degli utili è aumentato
			                                                                       | rispetto al periodo precedente, alla somma viene aggiunto (in verde)  l''importo di utile
			                                                                       | aumentato rispetto al periodo precedente. Se gli importi degli utili  nel periodo corrente sono diminuiti
			                                                                       | rispetto al periodo precedente, gli importi con cui gli utili sono diminuite vengono visualizzati in grigio.';
			                                                                       |pl = 'Porównanie z zyskami uzyskanymi za okres od %1 po %2 w walucie ewidencji zarządczej (%3). 
			                                                                       |Wyświetlane są informacje na temat uzyskanego dochodu w poprzednim okresie. Jeśli w bieżącym okresie zysk wzrósł 
			                                                                       |w porównaniu z poprzednim okresem, to dodatkowo (na zielono) wyświetlana jest kwota, o którą 
			                                                                       |wzrósł zysk w porównaniu z poprzednim okresem. Jeśli zysk w bieżącym okresie spadł
			                                                                       |w porównaniu z poprzednim okresem, to kwota, o którą spadł zysk jest wyświetlana na szaro.';
			                                                                       |tr = 'Yönetim muhasebesi para birimi (%3) cinsinden %1itibaren %2 kadar dönem kârı ile karşılaştırma. 
			                                                                       |Önceki dönem kârına ilişkin bilgiler görüntülenir. Cari dönem kârı bir önceki döneme göre artmışsa, 
			                                                                       |kârın bir önceki döneme göre arttığı 
			                                                                       |tutar yeşil renkte gösterilir. Cari dönem kârı bir önceki döneme göre azalmışsa,
			                                                                       | kârın azaldığı miktar gri renkte görüntülenir.'"),
			                                                                       StartDate,
			                                                                       EndDate,
			                                                                       ManagementAccountingCurrency);
			
		EndIf;
		
	ElsIf DataSetName = "ReceiptOfCash" Then
		
		If Not ForAdditionalPeriod Then
			
			LegendText = StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = 'Thông tin thu tiền trong kỳ từ %1 đến %2 theo tiền tệ kế toán quản trị (%3). 
			                                                                       |Thực hiện sắp xếp theo trình tự giảm dần số tiền đã thu.';
			                                                                       |ru = 'Информация о поступлении денежных средств за период с %1 по %2 в валюте управленческого учета (%3). 
			                                                                       |Сортировка производится в порядке убывания суммы поступивших денежных средств.';
			                                                                       |en = 'Information about received cash for the period from %1 to %2 in currency of management accounting (%3).
			                                                                       |Sorted in descending order by the received cash.'; fa = 'Information about received cash for the period from %1 to %2 in currency of management accounting (%3).
			                                                                       |Sorted in descending order by the received cash.';
			                                                                       |it = 'Informazioni sul flusso di cassa per il periodo da %1 a%2 nella valuta della contabilità di gestione (%3).
			                                                                       | L''ordinamento viene eseguito in ordine decrescente di flusso di cassa.';
			                                                                       |pl = 'Informacja o wpływach pieniężnych za okres od %1 do %2 w walucie ewidencji zarządczej (%3). 
			                                                                       |Sortowanie odbywa się malejąco do kwoty otrzymanych środków pieniężnych.';
			                                                                       |tr = 'Yönetim muhasebesi para biriminde (%3) bugüne kadar olan %1itibaren %2 kadar dönem için nakit makbuzları hakkında bilgi.
			                                                                       | Nakit makbuzlarının azalan sırasına göre sıralanmıştır.'"),
			                                                                       StartDate,
			                                                                       EndDate,
			                                                                       ManagementAccountingCurrency);
			
		Else
			LegendText = StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = 'So sánh với số tiền đã thu trong kỳ từ %1 đến %2 theo tiền tệ kế toán quản trị (%3).
			                                                                       |Hiển thị thông tin thu tiền kỳ trước. Nếu trong kỳ này, số tiền thu được tăng
			                                                                       |so với kỳ trước thì số tiền tăng thêm (màu xanh lá cây) là số tiền thu
			                                                                       |tăng so với kỳ trước. Nếu số tiền thu được của kỳ này giảm
			                                                                       |so với kỳ trước thì số tiền thu giảm
			                                                                       |này sẽ hiển thị màu xám.';
			                                                                       |ru = 'Сравнение с поступившими денежными средствами за период с %1 по %2 в валюте управленческого учета (%3). 
			                                                                       |Выводится информация о поступивших денежных средствах в предыдущем периоде. Если в текущем периоде сумма поступивших
			                                                                       |денежных средств увеличилась по сравнению с предыдущим периодом, то дополнительно (зеленым цветом) отображается сумма, 
			                                                                       |на которую увеличилось поступление денежных средств по сравнению с предыдущим периодом. Если сумма поступления денежных 
			                                                                       |средств в текущем периоде уменьшилась по сравнению с предыдущим периодом, то сумма, на которую уменьшилось поступление
			                                                                       |денежных средств, отображается серым цветом.';
			                                                                       |en = 'Compare with cash received for the period from %1 to %2 in the currency of management accounting (%3). 
			                                                                       |Information about received cash for the previous period is displayed. If the amount of received cash for the current period
			                                                                       |is greater than that of the previous period, 
			                                                                       |the difference amount is displayed in green color additionally. If the amount of 
			                                                                       |received cash for the current period is less compared to the previous period, 
			                                                                       |the difference amount is displayed in gray color.'; fa = 'Compare with cash received for the period from %1 to %2 in the currency of management accounting (%3). 
			                                                                       |Information about received cash for the previous period is displayed. If the amount of received cash for the current period
			                                                                       |is greater than that of the previous period, 
			                                                                       |the difference amount is displayed in green color additionally. If the amount of 
			                                                                       |received cash for the current period is less compared to the previous period, 
			                                                                       |the difference amount is displayed in gray color.';
			                                                                       |it = 'Confronto con i flussi di cassa del periodo da %1 a %2 nella valuta della contabilità di gestione (%3).
			                                                                       | Vengono fornite le informazioni sui flussi di cassa del periodo precedente. Se nel periodo corrente l''importo dei flussi di cassa è aumentato
			                                                                       | rispetto al periodo precedente, alla somma viene aggiunto (in verde) l''importo dei flussi di cassa
			                                                                       | aumentato rispetto al periodo precedente. Se gli importi dei flussi di cassa nel periodo corrente sono diminuiti
			                                                                       | rispetto al periodo precedente, gli importi con cui i 
			                                                                       | flussi di cassa sono diminuiti vengono visualizzati in grigio.';
			                                                                       |pl = 'Porównanie z otrzymanymi środkami pieniężnymi za okres od %1 do %2 w walucie ewidencji zarządczej (%3). 
			                                                                       |Wyświetlane są informacje na temat przyjętych środków pieniężnych w poprzednim okresie. Jeśli w bieżącym okresie kwota otrzymanych
			                                                                       |środków pieniężnych wzrosła w porównaniu z poprzednim okresem, to dodatkowo (na zielono) wyświetlana jest kwota, 
			                                                                       |o którą wzrósł przepływ środków pieniężnych w porównaniu z poprzednim okresem. Jeśli suma wpływów środków
			                                                                       |pieniężnych w bieżącym okresie spadł w porównaniu z poprzednim okresem, to kwota, o którą spadły otrzymane
			                                                                       |środki pieniężne, jest wyświetlana na szaro.';
			                                                                       |tr = 'Yönetim muhasebesi para biriminde (%3) %1ile %2dönem arasındaki nakit girişleri ile karşılaştırma.
			                                                                       |Önceki döneme ait nakit girişi gösterilir. Cari dönem nakit girişi
			                                                                       | bir önceki döneme göre artmışsa,
			                                                                       | ek olarak (yeşil) nakit girişinin
			                                                                       | bir önceki döneme göre ne kadar arttığını gösterir. Cari dönem nakit girişi bir önceki döneme göre azalmışsa, nakit girişinin
			                                                                       | azaldığı miktar gri renkte gösterilir.'"),
			                                                                       StartDate,
			                                                                       EndDate,
			                                                                       ManagementAccountingCurrency);
			
		EndIf;
		
	ElsIf DataSetName = "ReceiptOfDS_MinusCost" Then
		
		If Not ForAdditionalPeriod Then
			
			LegendText = StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = 'Thông tin thu tiền khấu trừ giá vốn trong kỳ từ %1 đến %2
			                                                                       |theo tiền tệ kế toán quản trị (%3). Thực hiện sắp xếp theo trình tự giảm dần chỉ tiêu.';
			                                                                       |ru = 'Информация о поступивших денежных средствах за вычетом себестоимости продаж в период с %1 по %2
			                                                                       |в валюте управленческого учета (%3). Сортировка производится в порядке убывания показателя.';
			                                                                       |en = 'Information on received cash excluding cost of goods sold for the period from %1 to %2 
			                                                                       |in management accounting currency (%3). Sorted in descending order by the indicator.'; fa = 'Information on received cash excluding cost of goods sold for the period from %1 to %2 
			                                                                       |in management accounting currency (%3). Sorted in descending order by the indicator.';
			                                                                       |it = 'Informazioni sui flussi di cassa meno il costo delle vendite nel periodo da %1 a %2
			                                                                       | nella valuta della contabilità di gestione (%3). L''ordinamento viene eseguito in ordine decrescente dell''indicatore.';
			                                                                       |pl = 'Informacja o uzyskanych środkach pieniężnych pomniejszona o wartość własną sprzedaży w okresie od %1 do %2
			                                                                       |w walucie ewidencji zarządczej (%3). Sortowanie jest dokonywane w trybie spadu wskaźnika.';
			                                                                       |tr = 'Yönetim muhasebesi para biriminde (%3)%1 ile %2
			                                                                       |arasındaki dönemde satışların maliyeti düşülmüş nakit girişleri hakkında bilgi. Azalan sırada sıralanmıştır.'"),
			                                                                       StartDate,
			                                                                       EndDate,
			                                                                       ManagementAccountingCurrency);
			
		Else
			LegendText = StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = 'So sánh với giá trị chỉ tiêu trong kỳ từ %1 đến %2 theo tiền tệ kế toán quản trị (%3). 
			                                                                       |Hiển thị thông tin về giá trị chỉ số trong kỳ trước. Nếu trong kỳ này, giá trị chỉ số tăng
			                                                                       |so với kỳ trước, thì hiển thị thêm (bằng màu xanh lá cây) giá trị mà chỉ số tăng lên
			                                                                       | so với kỳ trước. Nếu giá trị của chỉ số trong kỳ này giảm so với kỳ trước,
			                                                                       |thì giá trị mà chỉ số đã giảm sẽ được hiển thị bằng màu xám.';
			                                                                       |ru = 'Сравнение со значением показателя за период с %1 по %2 в валюте управленческого учета (%3). 
			                                                                       |Выводится информация о значении показателя в предыдущем периоде. Если в текущем периоде значение показателя выросло
			                                                                       |по сравнению с предыдущим периодом,то дополнительно (зеленым цветом) отображается значение, на которое увеличился показатель
			                                                                       |по сравнению с предыдущим периодом. Если значение показателя в текущем периоде уменьшилось по сравнению с предыдущим периодом,
			                                                                       |то значение, на которое уменьшился показатель отображается серым цветом.';
			                                                                       |en = 'Comparison with the indicator value for the period from %1 to %2 in management accounting currency (%3).
			                                                                       |Information about the indicator value for the previous period is displayed. If the indicator value for the current period is greater than
			                                                                       | those for the previous period, the difference value is highlighted in green additionally.
			                                                                       | If the indicator value for the current period is less than those for the previous period, 
			                                                                       |the difference value is highlighted in gray.'; fa = 'Comparison with the indicator value for the period from %1 to %2 in management accounting currency (%3).
			                                                                       |Information about the indicator value for the previous period is displayed. If the indicator value for the current period is greater than
			                                                                       | those for the previous period, the difference value is highlighted in green additionally.
			                                                                       | If the indicator value for the current period is less than those for the previous period, 
			                                                                       |the difference value is highlighted in gray.';
			                                                                       |it = 'Confronto con il valore dell''indicatore da %1 a %2 nella valuta della contabilità di gestione (%3).
			                                                                       | Vengono fornite le informazioni sul valore dell''indicatore del periodo precedente. Se nel periodo corrente il valore dell''indicatore è aumentato
			                                                                       | rispetto al periodo precedente, alla somma viene aggiunto (in verde)  il valore
			                                                                       | aumentato rispetto al periodo precedente. Se il valore dell''indicatore nel periodo corrente è diminuito
			                                                                       | rispetto al periodo precedente, la misura in cui il valore dell''indicatore è diminuto viene visualizzato in grigio.';
			                                                                       |pl = 'Porównanie z wartością wskaźnika za okres od %1 po %2 w walucie ewidencji zarządczej (%3). 
			                                                                       |Wyświetlane są informacje o wartości wskaźnika w poprzednim okresie. Jeśli w bieżącym okresie wartość wskaźnika wzrosła
			                                                                       |w porównaniu z poprzednim okresem, wtedy dodatkowo (na zielono) wyświetlana jest wartość, o jaką wzrosła w porównaniu z poprzednim okresem. Jeśli wartość wskaźnika w bieżącym okresie spadła
			                                                                       |w porównaniu z poprzednim okresem,
			                                                                       |to wartość, o którą spadła wartość jest wyświetlana na szaro.';
			                                                                       |tr = 'Yönetim muhasebesi para biriminde (%3) %1ile %2arasındaki dönem için göstergenin değeri ile karşılaştırma. 
			                                                                       |Göstergenin önceki dönemdeki değerine ilişkin bilgiler görüntülenir. Göstergenin cari dönem değeri bir önceki döneme göre artmışsa, 
			                                                                       |göstergenin bir önceki döneme göre arttığı değer ek olarak görüntülenir 
			                                                                       |(yeşil renkte). Göstergenin cari dönemdeki değeri bir önceki döneme göre azalmışsa,
			                                                                       | göstergenin azaldığı değer gri renkte gösterilir.'"),
			                                                                       StartDate,
			                                                                       EndDate,
			                                                                       ManagementAccountingCurrency);
			
		EndIf;
		
	ElsIf DataSetName = "LossesOverdueReceivables" Then
		
		If Not ForAdditionalPeriod Then
			
			LegendText = StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = 'Thông tin về các khoản thiệt hại mà công ty phải chịu do khách hàng không tuân thủ thời hạn thanh toán của hợp đồng
			                                                                       |trong kỳ từ %1 đến %2 theo đơn vị tiền tệ kế toán quản trị (%3). Chỉ tiêu được tính theo công thức: 
			                                                                       |Khoản thiệt hại = Số nợ quá hạn * Số ngày nợ quá hạn * Lãi năm để tính các khoản thiệt hại
			                                                                       |tài chính /(100 * 365).
			                                                                       |Việc phân loại được thực hiện theo thứ tự giảm dần của chỉ tiêu.';
			                                                                       |ru = 'Информация о потерях, понесенных компанией в результате несоблюдения договорных сроков оплаты клиентами
			                                                                       |в период с %1 по %2 в валюте управленческого учета (%3). Показатель рассчитывается по формуле: 
			                                                                       |Потери = Сумма просроченной задолженности * Дни просроченной задолженности * Годовая ставка для расчета финансовых
			                                                                       |потерь / (100*365).
			                                                                       |Сортировка производится в порядке убывания показателя.';
			                                                                       |en = 'Information about losses the company had due to failure to meet the contract payment terms by customers 
			                                                                       |for the period from %1 to %2 in management accounting currency (%3). Indicator is calculated using the formula:
			                                                                       |Losses = Overdue debt amount * AR/AP overdue period * Yearly rate for calculation 
			                                                                       |of financial losses / (100*365).
			                                                                       |Sorted in descending order by the indicator.'; fa = 'Information about losses the company had due to failure to meet the contract payment terms by customers 
			                                                                       |for the period from %1 to %2 in management accounting currency (%3). Indicator is calculated using the formula:
			                                                                       |Losses = Overdue debt amount * AR/AP overdue period * Yearly rate for calculation 
			                                                                       |of financial losses / (100*365).
			                                                                       |Sorted in descending order by the indicator.';
			                                                                       |it = 'Informazioni sulle perdite subite dalla società a causa dell''inosservanza delle condizioni contrattuali di pagamento da parte dei clienti 
			                                                                       | nel periodo da %1 a %2 nella valuta della contabilità di gestione (%3). L''indicatore è calcolato secondo la formula:
			                                                                       | Perdite = Ammontare degli arretrati * Giorni di arretrati * Tasso annuale per il calcolo delle perdite finanziarie
			                                                                       | / (100 * 365)
			                                                                       | L''ordinamento viene eseguito in ordine decrescente dell''indicatore.';
			                                                                       |pl = 'Informacje o stratach, poniesionych przez spółkę w wyniku niedotrzymania umownych terminów płatności przez klientów
			                                                                       |w okresie od %1 do %2 w walucie ewidencji zarządczej (%3). Wskaźnik oblicza się wg wzoru:
			                                                                       |Straty = Wartość zadłużenia * Dni zadłużenia * Roczna stopa do obliczania strat
			                                                                       |finansowych / (100*365).
			                                                                       |Sortowanie odbywa się w malejącej kolejności wskaźnika.';
			                                                                       |tr = 'Yönetim muhasebesi para biriminde (%3) %1''den %2e kadar olan dönemde
			                                                                       |müşteriler tarafından sözleşmeye dayalı son ödeme tarihlerine uyulmaması nedeniyle şirketin maruz kaldığı zararlar hakkında bilgi. Gösterge aşağıdaki formüle göre hesaplanır:
			                                                                       |Kayıplar = Vadesi geçmiş tutar * Vadesi geçmiş günler * Finansal
			                                                                       | kayıpları hesaplamak için yıllık oran / (100*365) 
			                                                                       |Gösterge azalan sırada sıralanır.'"),
			                                                                       StartDate,
			                                                                       EndDate,
			                                                                       ManagementAccountingCurrency);
			
		Else
			LegendText = StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = 'So sánh với giá trị chỉ tiêu trong kỳ từ %1 đến %2 theo tiền tệ kế toán quản trị (%3). 
			                                                                       |Hiển thị thông tin về giá trị chỉ số trong kỳ trước. Nếu trong kỳ này, giá trị chỉ số tăng
			                                                                       |so với kỳ trước, thì hiển thị thêm (bằng màu xám) giá trị mà chỉ số tăng lên
			                                                                       | so với kỳ trước. Nếu giá trị của chỉ số trong kỳ này giảm so với kỳ trước,
			                                                                       |thì giá trị mà chỉ số đã giảm sẽ được hiển thị bằng màu xanh lá cây.';
			                                                                       |ru = 'Сравнение со значением показателя за период с %1 по %2 в валюте управленческого учета (%3). 
			                                                                       |Выводится информация о значении показателя в предыдущем периоде. Если в текущем периоде значение показателя выросло
			                                                                       |по сравнению с предыдущим периодом,то дополнительно (серым цветом) отображается значение, на которое увеличился показатель
			                                                                       |по сравнению с предыдущим периодом. Если значение показателя в текущем периоде уменьшилось по сравнению с предыдущим периодом,
			                                                                       |то значение, на которое уменьшился показатель, отображается зеленым цветом.';
			                                                                       |en = 'Comparison with the indicator value for the period from %1 to %2 in management accounting currency (%3).
			                                                                       |Information about the indicator value for the previous period is displayed. If the indicator value for the current period is greater 
			                                                                       |than for the previous period, the difference value is highlighted in gray additionally. 
			                                                                       |If the indicator value for the current period is less than for the previous period,
			                                                                       |the difference value is highlighted in green.'; fa = 'Comparison with the indicator value for the period from %1 to %2 in management accounting currency (%3).
			                                                                       |Information about the indicator value for the previous period is displayed. If the indicator value for the current period is greater 
			                                                                       |than for the previous period, the difference value is highlighted in gray additionally. 
			                                                                       |If the indicator value for the current period is less than for the previous period,
			                                                                       |the difference value is highlighted in green.';
			                                                                       |it = 'Confronto con il valore dell''indicatore da %1 a %2 nella valuta della contabilità di gestione (%3).
			                                                                       | Vengono fornite le informazioni sul valore dell''indicatore del periodo precedente. Se nel periodo corrente il valore dell''indicatore è aumentato
			                                                                       | rispetto al periodo precedente, alla somma viene aggiunto (in grigio) il valore
			                                                                       | aumentato rispetto al periodo precedente. Se il valore dell''indicatore nel periodo corrente è diminuito
			                                                                       | rispetto al periodo precedente, la misura in cui il valore dell''indicatore è diminuto viene visualizzato in verde.';
			                                                                       |pl = 'Porównanie z wartością wskaźnika za okres od %1 po %2 w walucie ewidencji zarządczej (%3). 
			                                                                       |Wyświetlane są informacje o wartości wskaźnika w poprzednim okresie. Jeśli w bieżącym okresie wartość wskaźnika wzrosła
			                                                                       |w porównaniu z poprzednim okresem, wtedy dodatkowo (na szaro) wyświetlana jest wartość, o jaką wzrosła w porównaniu z poprzednim okresem. Jeśli wartość wskaźnika w bieżącym okresie spadła
			                                                                       |w porównaniu z poprzednim okresem,
			                                                                       |to wartość, o którą spadła wartość jest wyświetlana na zielono.';
			                                                                       |tr = 'Yönetim muhasebesi para biriminde (%3) %1 ile %2 arasındaki dönem için göstergenin değeri ile karşılaştırma. 
			                                                                       |Göstergenin önceki dönemdeki değerine ilişkin bilgiler görüntülenir. Göstergenin değeri cari dönemde bir önceki döneme göre artmışsa, 
			                                                                       | göstergenin bir önceki döneme göre arttığı değer ek olarak 
			                                                                       | görüntülenir (gri renkte). Göstergenin cari dönemdeki değeri bir önceki döneme kıyasla azalmışsa,
			                                                                       | göstergenin azaldığı değer yeşil renkte görüntülenir.'"),
			                                                                       StartDate,
			                                                                       EndDate,
			                                                                       ManagementAccountingCurrency);
			
		EndIf;
		
	ElsIf DataSetName = "ManualDiscountsAreProvided" Then
		
		If Not ForAdditionalPeriod Then
			
			LegendText = StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = 'Thông tin về lợi nhuận đã nhận và chiết khấu thủ công được phép trong kỳ từ %1 đến %2 theo tiền tệ kế toán quản trị (%3).
			                                                                       |Tiến hành sắp xếp theo trình tự giảm dần tỷ lệ chiết khấu thủ công được phép so với lợi nhuận nhận được.';
			                                                                       |ru = 'Информация о полученной прибыли и предоставленных ручных скидках в период с %1 по %2 в валюте управленческого учета (%3).
			                                                                       |Сортировка производится в порядке убывания доли предоставленных ручных скидок относительно полученной прибыли.';
			                                                                       |en = 'Information about received profit and provided discount adjustments in the period from %1 till %2 in management accounting currency (%3). 
			                                                                       |Sorting is performed in descending order of percentage of the provided discount adjustments in regard to the received profit.'; fa = 'Information about received profit and provided discount adjustments in the period from %1 till %2 in management accounting currency (%3). 
			                                                                       |Sorting is performed in descending order of percentage of the provided discount adjustments in regard to the received profit.';
			                                                                       |it = 'Informazioni su utili e sconti inseriti manualmente forniti nel periodo da %1 a %2 nella valuta della contabilità di gestione (%3).
			                                                                       | L''ordinamento viene effettuato in ordine decrescente della quota degli sconti inseriti manualmente indicati relativamente agli utili.';
			                                                                       |pl = 'Informacje o otrzymanym zysku i udzielonych ręcznych rabatów w okresie od %1 do %2 w walucie ewidencji zarządczej (%3).
			                                                                       |Sortowanie odbywa się w kolejności malejącej udziału udzielonych rabatów ręcznych w stosunku do otrzymanego zysku.';
			                                                                       |tr = 'Yönetim muhasebesi para birimi (%3) cinsinden kazanılan kârlar ve %1 ile %2 dönem içinde verilen indirim düzeltmeleri hakkında bilgiler
			                                                                       | Kazanılan kârlara göre verilen indirim düzeltmelerinin oranına göre azalan sırada sıralanmıştır.'"),
			                                                                       StartDate,
			                                                                       EndDate,
			                                                                       ManagementAccountingCurrency);
			
		Else
			LegendText = StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = 'Thông tin về lợi nhuận nhận được và chiết khấu thủ công đã cung cấp trong kỳ từ %1 đến %2 bằng tiền tệ của kế toán quản trị (%3).';
																						|ru = 'Информация о полученной прибыли и предоставленных ручных скидках в период с %1 по %2 в валюте управленческого учета (%3).';
																						|en = 'Information about received profit and provided discount adjustments in the period from %1 till %2 in management accounting currency (%3).'; fa = 'Information about received profit and provided discount adjustments in the period from %1 till %2 in management accounting currency (%3).';
																						|it = 'Informazioni su utili e sconti inseriti manualmente forniti nel periodo da %1 a %2 nella valuta della contabilità di gestione (%3)';
																						|pl = 'Informacja o zysku otrzymanym i ręcznych rabatach udzielonych w okresie od %1 do %2 w walucie ewidencji zarządczej (%3).';
																						|tr = 'Yönetim muhasebesi para birimi (%3) cinsinden %1 ile %2 dönem boyunca kazanılan kârlar ve verilen indirim düzeltmeleri hakkında bilgiler.'"),
			                                                                       StartDate,
			                                                                       EndDate,
			                                                                       ManagementAccountingCurrency);
			
		EndIf;
		
	ElsIf DataSetName = "EfficiencyOfOpportunityManagement" Then
		
		If Not ForAdditionalPeriod Then
			
			LegendText = StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = 'Thông tin về các vụ việc thắng và thua đã kết thúc trong kỳ từ %1 đến %2.
			                                                                       |Thực hiện sắp xếp thứ tự giảm dần theo tỷ lệ vụ việc giành được.';
			                                                                       |ru = 'Информация о выигранных и проигранных сделках, завершившихся в период с %1 по %2.
			                                                                       |Сортировка производится в порядке убывания доли выигранных сделок.';
			                                                                       |en = 'Information about won and lost sales opportunities closed in the period from %1 till %2.
			                                                                       |It is sorted in descending order of share of won sales opportunities.'; fa = 'Information about won and lost sales opportunities closed in the period from %1 till %2.
			                                                                       |It is sorted in descending order of share of won sales opportunities.';
			                                                                       |it = 'Informazioni sugli accordi vinti e persi terminati nel periodo da %1 a %2.
			                                                                       | L''ordinamento viene effettuato in ordine decrescente della quota di offerte vinte.';
			                                                                       |pl = 'Informacje o wygranych i przegranych umowach, które zakończyły się w okresie od %1 do %2.
			                                                                       |Sortowanie odbywa się w kolejności malejącej udziału wygranych umów.';
			                                                                       |tr = '%1den %2''ye kadar olan dönemde sona eren kazanan ve kaybeden işlemlere ilişkin bilgiler.
			                                                                       | Sıralama, kazanan işlemlerin payına göre azalan sırada yapılır.'"),
			                                                                       StartDate,
			                                                                       EndDate);
			
		Else
			LegendText = StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = 'Thông tin về vụ việc giành được và thất bại đã kết thúc trong kỳ từ %1 đến %2.';
																						|ru = 'Информация о выигранных и проигранных сделках, завершившихся в период с %1 по %2.';
																						|en = 'Information about won and lost sales opportunities closed between %1 and %2.'; fa = 'Information about won and lost sales opportunities closed between %1 and %2.';
																						|it = 'Informazioni sugli accordi vinti e persi terminati nel periodo da %1 a %2.';
																						|pl = 'Informacje o wygranych i utraconych umowach, które zakończyły się w okresie od %1 do %2.';
																						|tr = '%1''den %2ye kadar olan dönem boyunca tamamlanan kazanılan ve kaybedilen işlemlere ilişkin bilgiler.'"),
			                                                                       StartDate,
			                                                                       EndDate);
			
		EndIf;
		
	ElsIf DataSetName = "InteractionEfficiency" Then
		
		If Not ForAdditionalPeriod Then
			
		LegendText = StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = 'Thông tin về các tương tác cho những vụ việc đã giành được, thất bại, cũng như 
			                                                                       |những tương tác khác được ghi nhận trong kỳ từ %1 đến %2.
			                                                                       |Thực hiện sắp xếp theo trình tự giảm dần tỷ lệ tương tác đối với các vụ việc đã giành được.';
			                                                                       |ru = 'Информация о взаимодействиях, посвященных выигранным, проигранным сделкам, а также 
			                                                                       |прочим взаимодействиям, зарегистрированным в период с %1 по %2.
			                                                                       |Сортировка производится в порядке убывания доли взаимодействий, посвященным выигранным сделкам.';
			                                                                       |en = 'Information on interactions on won and lost sales opportunities, and other interactions registered between %1 and %2. It is sorted in the descending order of percentage of interactions on won sales opportunities.
			                                                                       |
			                                                                       |'; fa = 'Information on interactions on won and lost sales opportunities, and other interactions registered between %1 and %2. It is sorted in the descending order of percentage of interactions on won sales opportunities.
			                                                                       |
			                                                                       |';
			                                                                       |it = 'Informazioni sulle interazioni, collegate agli accordi vinti e persi,
			                                                                       | e anche circa le altre interazioni, sono registrate nel periodo da %1 a %2.
			                                                                       | L''ordinamento viene eseguito in ordine decrescente dalla quota di interazioni dedicata agli accordi vinti.';
			                                                                       |pl = 'Informacje o interakcjach, poświęconych wygranym, przegranym umowom oraz 
			                                                                       |innym interakcjom, zarejestrowanym w okresie od %1 do %2.
			                                                                       | Sortowanie odbywa się w kolejności malejącej udziału interakcji dedykowanych wygranym umowom.';
			                                                                       |tr = '%1den %2''a kadar olan dönemde kaydedilen kazanılan,
			                                                                       | kaybedilen ve diğer etkileşimlere adanmış etkileşimlere ilişkin bilgiler. 
			                                                                       | Kazanılan işlemlere adanmış etkileşimlerin oranına göre azalan sırada sıralanmıştır.'"),
			                                                                       StartDate,
			                                                                       EndDate);
			
		Else
			
			LegendText = StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = 'Thông tin về tương tác cho vụ việc đã giành được, thất bại, cũng như 
			                                                                       |những tương tác khác đã ghi nhận trong kỳ từ %1 đến %2.';
			                                                                       |ru = 'Информация о взаимодействиях, посвященных выигранным, проигранным сделкам, а также 
			                                                                       |прочим взаимодействиям, зарегистрированным в период с %1 по %2.';
			                                                                       |en = 'Information on interactions on won and lost sales opportunities
			                                                                       |and other interactions registered between %1 and %2.'; fa = 'Information on interactions on won and lost sales opportunities
			                                                                       |and other interactions registered between %1 and %2.';
			                                                                       |it = 'Informazioni sulle interazioni, collegate agli accordi vinti e persi, e anche 
			                                                                       | circa le altre interazioni, sono registrate nel periodo da %1 a %2.';
			                                                                       |pl = 'Informacje o interakcjach, poświęconych wygranym, przegranym umowom oraz 
			                                                                       |innym interakcjom, zarejestrowanym w okresie od %1 do %2.';
			                                                                       |tr = '%1''den itibaren%2 dönem boyunca kaydedilen kazanılan,
			                                                                       | kaybedilen ve diğer etkileşimlere ilişkin bilgiler.'"),
			                                                                       StartDate,
			                                                                       EndDate);
			
		EndIf;
		
	ElsIf DataSetName = "SalesPerOpportunity" Then
		
		If Not ForAdditionalPeriod Then
			
			LegendText = StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = 'Thông tin về số tiền bán hàng trong một vụ việc đã kết thúc trong kỳ từ %1 đến %2 theo tiền tệ kế toán quản trị (%3).
			                                                                       |Thực hiện sắp xếp theo trình tự giảm dần doanh thu.';
			                                                                       |ru = 'Информация о сумме продаж на одну завершенную сделку в период с %1 по %2 в валюте управленческого учета (%3). 
			                                                                       |Сортировка производится в порядке убывания продаж.';
			                                                                       |en = 'Information about sales amount per completed sales opportunity between %1 and %2 in management accounting currency (%3). 
			                                                                       |Sales are sorted in the descending order.'; fa = 'Information about sales amount per completed sales opportunity between %1 and %2 in management accounting currency (%3). 
			                                                                       |Sales are sorted in the descending order.';
			                                                                       |it = 'Informazioni circa il totale delle vendite per un accordo concluso nel periodo da %1 a%2 nella valuta della contabilità di gestione(%3).
			                                                                       | L''ordinamento viene eseguito in ordine decrescente di vendita.';
			                                                                       |pl = 'Informacje o kwocie sprzedaży za jedną zakończoną umowę za okres od %1 do %2 w walucie ewidencji zarządczej (%3). 
			                                                                       |Sortowanie odbywa się wg sprzedaży malejącej.';
			                                                                       |tr = 'Yönetim muhasebesi para biriminde (%3)%1 ile%2 arasındaki dönemde tamamlanan işlem başına satış miktarı hakkında bilgi.
			                                                                       | Azalan satış sırasına göre sıralanmıştır.'"),
			                                                                       StartDate,
			                                                                       EndDate,
			                                                                       ManagementAccountingCurrency);
			
		Else
			LegendText = StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = 'So sánh với doanh số bán hàng cho một vụ việc đã kết thúc từ %1 đến %2 theo tiền tệ kế toán quản trị (%3). 
			                                                                       |Hiển thị thông tin về giá trị chỉ số trong kỳ trước. Nếu trong kỳ này, giá trị chỉ số tăng
			                                                                       |so với kỳ trước, thì hiển thị thêm (bằng màu xanh lá cây) giá trị mà chỉ số tăng lên
			                                                                       | so với kỳ trước. Nếu giá trị của chỉ số trong kỳ này giảm so với kỳ trước,
			                                                                       |thì giá trị mà chỉ số đã giảm sẽ được hiển thị bằng màu xám.';
			                                                                       |ru = 'Сравнение с продажами на одну завершенную сделку в с %1 по %2 в валюте управленческого учета (%3). 
			                                                                       |Выводится информация о значении показателя в предыдущем периоде. Если в текущем периоде значение показателя выросло
			                                                                       |по сравнению с предыдущим периодом,то дополнительно(зеленым цветом) отображается значение, на которое увеличился показатель
			                                                                       |по сравнению с предыдущим периодом. Если значение показателя в текущем периоде уменьшилось по сравнению с предыдущим периодом,
			                                                                       |то значение, на которое уменьшился показатель отображается серым цветом.';
			                                                                       |en = 'Comparison with sales per completed sales opportunity between %1 and %2 in management accounting currency (%3).
			                                                                       |Information about the indicator value for the previous period is displayed. If the indicator value for the current period is greater
			                                                                       | than those for the previous period, the difference value is highlighted in green additionally.
			                                                                       | If the indicator value for the current period is less than those for the previous period, 
			                                                                       |the difference value is highlighted in gray.'; fa = 'Comparison with sales per completed sales opportunity between %1 and %2 in management accounting currency (%3).
			                                                                       |Information about the indicator value for the previous period is displayed. If the indicator value for the current period is greater
			                                                                       | than those for the previous period, the difference value is highlighted in green additionally.
			                                                                       | If the indicator value for the current period is less than those for the previous period, 
			                                                                       |the difference value is highlighted in gray.';
			                                                                       |it = 'Confronto con le vendite per un accordo concluso da %1 a %2 nella valuta della contabilità di gestione (%3).
			                                                                       | Vengono fornite le informazioni sul valore dell''indicatore del periodo precedente. Se nel periodo corrente il valore dell''indicatore è aumentato
			                                                                       | rispetto al periodo precedente, alla somma viene aggiunto (in verde)  il valore
			                                                                       | aumentato rispetto al periodo precedente. Se il valore dell''indicatore nel periodo corrente è diminuito
			                                                                       | rispetto al periodo precedente, la misura in cui il valore dell''indicatore è diminuto viene visualizzato in grigio.';
			                                                                       |pl = 'Porównanie ze sprzedażą dla jednej zakończonej umowy za okres od %1 do %2 w walucie ewidencji zarządczej (%3). 
			                                                                       |Wyświetlane są informacje o wartości wskaźnika w poprzednim okresie. Jeśli w bieżącym okresie wartość wskaźnika wzrosła
			                                                                       |w porównaniu z poprzednim okresem, wtedy dodatkowo(na zielono) wyświetlana jest wartość, o jaką wzrosła w porównaniu z poprzednim okresem. Jeśli wartość wskaźnika w bieżącym okresie spadła
			                                                                       |w porównaniu z poprzednim okresem,
			                                                                       |to wartość, o którą spadła wartość jest wyświetlana na szaro.';
			                                                                       |tr = 'Yönetim muhasebesi para biriminde (%3) %1 ile %2 arasında tamamlanan işlem başına satışlarla karşılaştırma.
			                                                                       | Göstergenin önceki dönemdeki değerine ilişkin bilgiler görüntülenir. Cari dönem göstergesi bir önceki döneme göre artmışsa,
			                                                                       | göstergenin bir önceki döneme göre arttığı değer ek olarak
			                                                                       | görüntülenir (yeşil renkte). Göstergenin cari dönemdeki değeri bir önceki döneme göre azalmışsa,
			                                                                       | göstergenin azaldığı değer gri renkte görüntülenir.'"),
			                                                                       StartDate,
			                                                                       EndDate,
			                                                                       ManagementAccountingCurrency);
			
		EndIf;
		
	ElsIf DataSetName = "SalesPerOneInteraction" Then
		
		If Not ForAdditionalPeriod Then
			
			LegendText = StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = 'Thông tin về số tiền bán hàng trong một tương tác đã ghi nhận trong kỳ từ %1 đến %2 theo tiền tệ kế toán quản trị (%3). 
			                                                                       |Thực hiện sắp xếp theo trình tự giảm dần doanh thu.';
			                                                                       |ru = 'Информация о сумме продаж на одно зарегистрированное взаимодействие в период с %1 по %2 в валюте управленческого учета (%3). 
			                                                                       |Сортировка производится в порядке убывания продаж.';
			                                                                       |en = 'Information about sales amount on one registered interaction for the period from %1 to %2 in currency of management accounting (%3).
			                                                                       |Sales are sorted in descending order.'; fa = 'Information about sales amount on one registered interaction for the period from %1 to %2 in currency of management accounting (%3).
			                                                                       |Sales are sorted in descending order.';
			                                                                       |it = 'Informazioni circa il totale delle vendite per una interazione registrata nel periodo da %1 a%2 nella valuta della contabilità di gestione(%3).
			                                                                       | L''ordinamento viene eseguito in ordine decrescente di vendita.';
			                                                                       |pl = 'Informacje o wielkości sprzedaży za jedną zarejestrowaną interakcję za okres od %1 do %2 w walucie ewidencji zarządczej (%3). 
			                                                                       |Sortowanie odbywa się wg sprzedaży malejącej.';
			                                                                       |tr = 'Yönetim muhasebesi para biriminde (%3) %1 ile %2 arasındaki dönemde kaydedilen etkileşim başına satış miktarı hakkında bilgi.
			                                                                       | Azalan satış sırasına göre sıralanmıştır.'"),
			                                                                       StartDate,
			                                                                       EndDate,
			                                                                       ManagementAccountingCurrency);
			
		Else
			LegendText = StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = 'So sánh với doanh số bán hàng, một tương tác được ghi nhận từ %1 đến %2 theo tiền tệ kế toán quản trị (%3). 
			                                                                       |Hiển thị thông tin về giá trị chỉ số trong kỳ trước. Nếu trong kỳ này, giá trị chỉ số tăng
			                                                                       |so với kỳ trước, thì hiển thị thêm (bằng màu xanh lá cây) giá trị mà chỉ số tăng lên
			                                                                       | so với kỳ trước. Nếu giá trị của chỉ số trong kỳ này giảm so với kỳ trước,
			                                                                       |thì giá trị mà chỉ số đã giảm sẽ được hiển thị bằng màu xám.';
			                                                                       |ru = 'Сравнение с продажами одно зарегистрированное взаимодействие в с %1 по %2 в валюте управленческого учета (%3). 
			                                                                       |Выводится информация о значении показателя в предыдущем периоде. Если в текущем периоде значение показателя выросло
			                                                                       |по сравнению с предыдущим периодом,то дополнительно (зеленым цветом) отображается значение, на которое увеличился показатель
			                                                                       |по сравнению с предыдущим периодом. Если значение показателя в текущем периоде уменьшилось по сравнению с предыдущим периодом,
			                                                                       |то значение, на которое уменьшился показатель, отображается серым цветом.';
			                                                                       |en = 'Compare with sales one registered interaction from %1 to %2 in the currency of management accounting (%3). 
			                                                                       |Information about the indicator value for the previous period is displayed. If the indicator value for the current period is greater 
			                                                                       |than that of the previous period, the difference value is displayed in green color additionally. 
			                                                                       |If the indicator value for the current period is less, 
			                                                                       |the difference value is displayed in gray color.'; fa = 'Compare with sales one registered interaction from %1 to %2 in the currency of management accounting (%3). 
			                                                                       |Information about the indicator value for the previous period is displayed. If the indicator value for the current period is greater 
			                                                                       |than that of the previous period, the difference value is displayed in green color additionally. 
			                                                                       |If the indicator value for the current period is less, 
			                                                                       |the difference value is displayed in gray color.';
			                                                                       |it = 'Confronto con le vendite per una interazione registrata da %1 a %2 nella valuta della contabilità di gestione (%3).
			                                                                       | Vengono fornite le informazioni sul valore dell''indicatore del periodo precedente. Se nel periodo corrente il valore dell''indicatore è aumentato
			                                                                       | rispetto al periodo precedente, alla somma viene aggiunto (in verde) il valore
			                                                                       | aumentato rispetto al periodo precedente. Se il valore dell''indicatore nel periodo corrente è diminuito
			                                                                       | rispetto al periodo precedente, la misura in cui il valore dell''indicatore è diminuto viene visualizzato in grigio.';
			                                                                       |pl = 'Porównanie ze sprzedażą jednej zarejestrowanej interakcji w za od %1 po %2 w walucie ewidencji zarządczej (%3). 
			                                                                       |Wyświetlane są informacje o wartości wskaźnika w poprzednim okresie. Jeśli w bieżącym okresie wartość wskaźnika wzrosła
			                                                                       |w porównaniu z poprzednim okresem, wtedy dodatkowo (na zielono) wyświetlana jest wartość, o jaką wzrosła w porównaniu z poprzednim okresem. Jeśli wartość wskaźnika w bieżącym okresie spadła
			                                                                       |w porównaniu z poprzednim okresem,
			                                                                       |to wartość, o którą spadła wartość, jest wyświetlana na szaro.';
			                                                                       |tr = 'Yönetim muhasebesi para biriminde (%3%1 ile %2 arasında kaydedilen bir satış etkileşimi ile karşılaştırma.
			                                                                       | Göstergenin önceki dönemdeki değeri hakkında bilgi görüntülenir. Cari dönem göstergesi bir önceki döneme göre artmışsa, 
			                                                                       |göstergenin bir önceki döneme göre arttığı değer ek olarak 
			                                                                       |görüntülenir (yeşil renkte). Göstergenin cari dönemdeki değeri bir önceki döneme göre azalmışsa,
			                                                                       | göstergenin azaldığı değer gri renkte görüntülenir.'"),
			                                                                       StartDate,
			                                                                       EndDate,
			                                                                       ManagementAccountingCurrency);
			
		EndIf;
		
	ElsIf DataSetName = "TheMainStagesOfLosses" Then
		
		If Not ForAdditionalPeriod Then
			
		LegendText = StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = 'Thông tin về 5 điều thường gặp nhất trong các vụ việc thất bại trong kỳ từ %1 đến %2
			                                                                  |kết hợp giữa ""người quản lý - giai đoạn vụ việc"".';
			                                                                  |ru = 'Информация о 5 наиболее часто встречающихся при проигрыше сделок в период с %1 по %2
			                                                                  |сочетаниях ""менеджер - этап сделки"".';
			                                                                  |en = 'Information about 5 mostly used combinations ""Manager: opportunity stage"" 
			                                                                  |for sales opportunities lost between %1 and %2.'; fa = 'Information about 5 mostly used combinations ""Manager: opportunity stage"" 
			                                                                  |for sales opportunities lost between %1 and %2.';
			                                                                  |it = 'Informazioni circa i 5 accordi persi riscontrati più frequentemente nel periodo da %1 a %2
			                                                                  | nelle combinazioni ""manager - fase accordo"".';
			                                                                  |pl = 'Informacje dotyczące 5 najczęściej spotykanych w przypadku przegranej umowy za okres od %1 do %2
			                                                                  | kombinacjami ""menedżer - etap umowy"".';
			                                                                  |tr = '%1 itibaren %2kadar anlaşmaları kaybederken 
			                                                                  |en yaygın 5 ""yönetici - anlaşma aşaması"" kombinasyonu hakkında bilgi.'"),
			                                                                  StartDate,
			                                                                  EndDate,
			                                                                  ManagementAccountingCurrency);
			
		Else
			
		LegendText = StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = 'Thông tin về 5 điều thường gặp nhất trong các vụ việc thất bại trong kỳ từ %1 đến %2
			                                                                  |kết hợp giữa ""người quản lý - giai đoạn vụ việc"".';
			                                                                  |ru = 'Информация о 5 наиболее часто встречающихся при проигрыше сделок в период с %1 по %2
			                                                                  |сочетаниях ""менеджер - этап сделки"".';
			                                                                  |en = 'Information about 5 mostly used combinations ""Manager: opportunity stage"" 
			                                                                  |for sales opportunities lost between %1 and %2.'; fa = 'Information about 5 mostly used combinations ""Manager: opportunity stage"" 
			                                                                  |for sales opportunities lost between %1 and %2.';
			                                                                  |it = 'Informazioni circa i 5 accordi persi riscontrati più frequentemente nel periodo da %1 a %2
			                                                                  | nelle combinazioni ""manager - fase accordo"".';
			                                                                  |pl = 'Informacje dotyczące 5 najczęściej spotykanych w przypadku przegranej umowy za okres od %1 do %2
			                                                                  | kombinacjami ""menedżer - etap umowy"".';
			                                                                  |tr = '%1 itibaren %2kadar anlaşmaları kaybederken 
			                                                                  |en yaygın 5 ""yönetici - anlaşma aşaması"" kombinasyonu hakkında bilgi.'"),
			                                                                  StartDate,
			                                                                  EndDate,
			                                                                  ManagementAccountingCurrency);
			
		EndIf
		
	ElsIf DataSetName = "ReasonsForLosingSalesOpportunities" Then
		
		If Not ForAdditionalPeriod Then
			
		LegendText = StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = 'Thông tin về 5 điều thường gặp nhất trong các vụ việc thất bại trong kỳ từ %1 đến %2
			                                                                  |kết hợp giữa ""người quản lý - nguyên nhân thất bại vụ việc"".';
			                                                                  |ru = 'Информация о 5 наиболее часто встречающихся при проигрыше сделок в период с %1 по %2
			                                                                  |сочетаниях ""менеджер - причина проигрыша сделки"".';
			                                                                  |en = 'Information about 5 mostly used combinations ""Manager: reason for losing"" 
			                                                                  |for sales opportunities lost between %1 and %2.'; fa = 'Information about 5 mostly used combinations ""Manager: reason for losing"" 
			                                                                  |for sales opportunities lost between %1 and %2.';
			                                                                  |it = 'Informazioni circa i 5 accordi persi riscontrati più frequentemente nel periodo da %1 a %2
			                                                                  | nelle combinazioni ""manager - causa perdita accordo"".';
			                                                                  |pl = 'Informacje na temat 5 najczęściej spotykanych w przypadku straty umowy  za okres od %1 do %2
			                                                                  |w kombinacjach ""manager - przyczyna przegranej umowy"".';
			                                                                  |tr = '%1 ve %2 arasındaki dönemde
			                                                                  | en yaygın 5 ""yönetici - anlaşma kaybetme nedeni"" kombinasyonu hakkında bilgi.'"),
			                                                                  StartDate,
			                                                                  EndDate);
			
		Else
			
		LegendText = StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = 'Thông tin về 5 điều thường gặp nhất trong các vụ việc thất bại trong kỳ từ %1 đến %2
			                                                                  |kết hợp giữa ""người quản lý - nguyên nhân thất bại vụ việc"".';
			                                                                  |ru = 'Информация о 5 наиболее часто встречающихся при проигрыше сделок в период с %1 по %2
			                                                                  |сочетаниях ""менеджер - причина проигрыша сделки"".';
			                                                                  |en = 'Information about 5 mostly used combinations ""Manager: reason for losing"" 
			                                                                  |for sales opportunities lost between %1 and %2.'; fa = 'Information about 5 mostly used combinations ""Manager: reason for losing"" 
			                                                                  |for sales opportunities lost between %1 and %2.';
			                                                                  |it = 'Informazioni circa i 5 accordi persi riscontrati più frequentemente nel periodo da %1 a %2
			                                                                  | nelle combinazioni ""manager - causa perdita accordo"".';
			                                                                  |pl = 'Informacje na temat 5 najczęściej spotykanych w przypadku straty umowy  za okres od %1 do %2
			                                                                  |w kombinacjach ""manager - przyczyna przegranej umowy"".';
			                                                                  |tr = '%1 ve %2 arasındaki dönemde
			                                                                  | en yaygın 5 ""yönetici - anlaşma kaybetme nedeni"" kombinasyonu hakkında bilgi.'"),
			                                                                  StartDate,
			                                                                  EndDate);
			
		EndIf;
		
	ElsIf DataSetName = "DissatisfactionWithPrimaryDemand" Then
		
		If Not ForAdditionalPeriod Then
			
		LegendText = StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = 'Thông tin về 5 điều thường gặp nhất đối với các vụ việc đã đóng trong kỳ từ %1 đến %2
			                                                                  |kết hợp giữa ""người quản lý - nguyên nhân không đáp ứng nhu cầu ban đầu"".
			                                                                  |Thông tin hiển thị theo tiền tệ kế toán quản trị (%3)';
			                                                                  |ru = 'Информация о 5 наиболее часто встречающихся для закрытых в период с %1 по %2 сделок
			                                                                  |сочетаниях ""менеджер - причина неудовлетворения первичного спроса"".
			                                                                  |Информация выводится в валюте управленческого учета (%3)';
			                                                                  |en = 'Information about 5 mostly used combinations ""Manager: reason for primary demand non-fulfillment"" 
			                                                                  |for sales opportunities closed between %1 and %2.
			                                                                  |Information is displayed in management accounting currency (%3)'; fa = 'Information about 5 mostly used combinations ""Manager: reason for primary demand non-fulfillment"" 
			                                                                  |for sales opportunities closed between %1 and %2.
			                                                                  |Information is displayed in management accounting currency (%3)';
			                                                                  |it = 'Informazioni circa i 5 accordi persi riscontrati più frequentemente nel periodo da %1 a %2
			                                                                  | nelle combinazioni ""manager - motivo insoddisfazione domanda primaria"".
			                                                                  | Informazioni fornite  nella valuta della contabilità di gestione (%3).';
			                                                                  |pl = 'Informacje o 5 najczęściej spotykanych dla zamkniętych w okresie od %1 do %2 transakcji
			                                                                  | w kombinacji ""menedżer - przyczyna niezadowolenia z pierwotnego popytu"".
			                                                                  |Informacje są wyświetlane w walucie ewidencji zarządczej (%3)';
			                                                                  |tr = '%1''den %2''ye kadar olan dönemde 
			                                                                  |kapatılan işlemler için en sık görülen 5 ""yönetici - birincil talebi karşılayamama nedeni"" kombinasyonuna ilişkin bilgiler.
			                                                                  | Bilgiler yönetim muhasebesi para biriminde (%3) gösterilir'"),
			                                                                  StartDate,
			                                                                  EndDate,
			                                                                  ManagementAccountingCurrency);
			
		Else
			
		LegendText = StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = 'Thông tin về 5 điều thường gặp nhất đối với các vụ việc đã đóng trong kỳ từ %1 đến %2
			                                                                  |kết hợp giữa ""người quản lý - nguyên nhân không đáp ứng nhu cầu ban đầu"".
			                                                                  |Thông tin hiển thị theo tiền tệ kế toán quản trị (%3)';
			                                                                  |ru = 'Информация о 5 наиболее часто встречающихся для закрытых в период с %1 по %2 сделок
			                                                                  |сочетаниях ""менеджер - причина неудовлетворения первичного спроса"".
			                                                                  |Информация выводится в валюте управленческого учета (%3)';
			                                                                  |en = 'Information about 5 mostly used combinations ""Manager: reason for primary demand non-fulfillment"" 
			                                                                  |for sales opportunities closed between %1 and %2.
			                                                                  |Information is displayed in management accounting currency (%3)'; fa = 'Information about 5 mostly used combinations ""Manager: reason for primary demand non-fulfillment"" 
			                                                                  |for sales opportunities closed between %1 and %2.
			                                                                  |Information is displayed in management accounting currency (%3)';
			                                                                  |it = 'Informazioni circa i 5 accordi persi riscontrati più frequentemente nel periodo da %1 a %2
			                                                                  | nelle combinazioni ""manager - motivo insoddisfazione domanda primaria"".
			                                                                  | Informazioni fornite  nella valuta della contabilità di gestione (%3).';
			                                                                  |pl = 'Informacje o 5 najczęściej spotykanych dla zamkniętych w okresie od %1 do %2 transakcji
			                                                                  | w kombinacji ""menedżer - przyczyna niezadowolenia z pierwotnego popytu"".
			                                                                  |Informacje są wyświetlane w walucie ewidencji zarządczej (%3)';
			                                                                  |tr = '%1''den %2''ye kadar olan dönemde 
			                                                                  |kapatılan işlemler için en sık görülen 5 ""yönetici - birincil talebi karşılayamama nedeni"" kombinasyonuna ilişkin bilgiler.
			                                                                  | Bilgiler yönetim muhasebesi para biriminde (%3) gösterilir'"),
			                                                                  StartDate,
			                                                                  EndDate,
			                                                                  ManagementAccountingCurrency);
			
		EndIf;	
		
	ElsIf DataSetName = "CustomerBaseTrends" Then
		
		If Not ForAdditionalPeriod Then
			
		LegendText = StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = 'Thông tin về khách hàng mới, khách hàng quay lại và khách hàng bị mất trong kỳ từ %1 đến %2';
																					|ru = 'Информация о новых, вернувшихся и потерянных в период с %1 по %2 клиентах';
																					|en = 'Information about new, returned and lost customers for the period from %1 to %2'; fa = 'Information about new, returned and lost customers for the period from %1 to %2';
																					|it = 'Informazioni circa i clienti nuovi, ritornati e persi nel periodo da %1 a %2';
																					|pl = 'Informacje o klientach nowych, utraconych, oraz tych, którzy wróciły się w okresie od %1 do %2';
																					|tr = '%1''den %2''ye kadar olan dönemde yeni, geri dönen ve kaybedilen müşterilere ilişkin bilgiler'"),
			                                                                  StartDate,
			                                                                  EndDate);
		Else
			
		LegendText = StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = 'Thông tin về khách hàng mới, khách hàng quay lại và khách hàng bị mất trong kỳ từ %1 đến %2';
																					|ru = 'Информация о новых, вернувшихся и потерянных в период с %1 по %2 клиентах';
																					|en = 'Information about new, returned and lost customers for the period from %1 to %2'; fa = 'Information about new, returned and lost customers for the period from %1 to %2';
																					|it = 'Informazioni circa i clienti nuovi, ritornati e persi nel periodo da %1 a %2';
																					|pl = 'Informacje o klientach nowych, utraconych, oraz tych, którzy wróciły się w okresie od %1 do %2';
																					|tr = '%1''den %2''ye kadar olan dönemde yeni, geri dönen ve kaybedilen müşterilere ilişkin bilgiler'"),
			                                                                  StartDate,
			                                                                  EndDate);
		EndIf;
		
	ElsIf DataSetName = "SalesToNewCustomers" Then
		
		If Not ForAdditionalPeriod Then
			
			LegendText = StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = 'Thông tin về số tiền bán hàng cho khách hàng mới trong kỳ từ %1 đến %2 theo tiền tệ kế toán quản trị (%3).
			                                                                       |Thực hiện sắp xếp theo trình tự giảm dần doanh thu cho khách hàng mới.';
			                                                                       |ru = 'Информация о продажах новым клиентам за период с %1 по %2 в валюте управленческого учета (%3). 
			                                                                       |Сортировка производится в порядке убывания продаж новым клиентам.';
			                                                                       |en = 'Information about sales to new customers for the period from %1 to %2 in currency of management accounting (%3).
			                                                                       |Sales to new customers are sorted in descending order.'; fa = 'Information about sales to new customers for the period from %1 to %2 in currency of management accounting (%3).
			                                                                       |Sales to new customers are sorted in descending order.';
			                                                                       |it = 'Informazioni sulle vendite a nuovi clienti per il periodo da %1 a %2 sono nella valuta della contabilità di gestione (%3).
			                                                                       | L''ordinamento viene eseguito in ordine decrescente di vendite a nuovi clienti.';
			                                                                       |pl = 'Informacje o sprzedaży na rzecz nowych klientów za okres od %1 do %2 w walucie ewidencji zarządczej (%3). 
			                                                                       |Sortowanie odbywa się wg nowych klientów malejąco.';
			                                                                       |tr = 'Yönetim muhasebesi para biriminde (%3) %1ile başlayan %2kadar dönem için yeni müşterilere yapılan satışlar hakkında bilgiler.
			                                                                       | Yeni müşterilere yapılan satışların azalan sırasına göre sıralanmıştır.'"),
			                                                                       StartDate,
			                                                                       EndDate,
			                                                                       ManagementAccountingCurrency);
			
		Else
			LegendText = StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = 'So sánh với doanh số bán hàng cho khách hàng mới trong kỳ từ %1 đến %2 theo tiền tệ kế toán quản trị (%3). 
			                                                                       |Hiển thị thông tin về doanh số bán hàng cho khách hàng mới trong kỳ trước. Nếu trong kỳ này, giá trị chỉ số tăng
			                                                                       |so với kỳ trước, thì hiển thị thêm (bằng màu xanh lá cây) giá trị mà chỉ số tăng lên
			                                                                       | so với kỳ trước. Nếu giá trị của chỉ số trong kỳ này giảm so với kỳ trước,
			                                                                       |thì giá trị mà chỉ số đã giảm sẽ được hiển thị bằng màu xám.';
			                                                                       |ru = 'Сравнение с продажами новым клиентам за период с %1 по %2 в валюте управленческого учета (%3). 
			                                                                       |Выводится информация о продажах новым клиентам предыдущего периода. Если в текущем периоде значение показателя выросло
			                                                                       |по сравнению с предыдущим периодом,то дополнительно (зеленым цветом) отображается значение, на которое увеличился показатель
			                                                                       |по сравнению с предыдущим периодом. Если значение показателя в текущем периоде уменьшилось по сравнению с предыдущим периодом,
			                                                                       |то значение, на которое уменьшился показатель, отображается серым цветом.';
			                                                                       |en = 'Comparison with sales to new customers for the period from %1 to %2 in management accounting currency (%3).
			                                                                       |Information about sales to new customers of the previous period is displayed. If the indicator value for the current period is greater 
			                                                                       |than for the previous period, the difference value is highlighted in green additionally. 
			                                                                       |If the indicator value for the current period is less than for the previous period,
			                                                                       |the difference value is highlighted in gray.'; fa = 'Comparison with sales to new customers for the period from %1 to %2 in management accounting currency (%3).
			                                                                       |Information about sales to new customers of the previous period is displayed. If the indicator value for the current period is greater 
			                                                                       |than for the previous period, the difference value is highlighted in green additionally. 
			                                                                       |If the indicator value for the current period is less than for the previous period,
			                                                                       |the difference value is highlighted in gray.';
			                                                                       |it = 'Confronto con le vendite  a nuovi clienti da %1 a %2 nella valuta della contabilità di gestione (%3).
			                                                                       | Vengono fornite le informazioni sulle vendite a nuovi clienti del periodo precedente. Se nel periodo corrente il valore dell''indicatore è aumentato
			                                                                       | rispetto al periodo precedente, alla somma viene aggiunto (in verde)  il valore
			                                                                       | aumentato rispetto al periodo precedente. Se il valore dell''indicatore nel periodo corrente è diminuito
			                                                                       | rispetto al periodo precedente, la misura in cui il valore dell''indicatore è diminuto viene visualizzato in grigio.';
			                                                                       |pl = 'Porównanie ze sprzedażą dla nowych klientów za okres od %1 do %2 w walucie ewidencji zarządczej (%3). 
			                                                                       |Wyświetlane są informacje o sprzedaży nowych klientów z poprzedniego okresu. Jeśli w bieżącym okresie wartość wskaźnika wzrosła
			                                                                       |w porównaniu z poprzednim okresem, wtedy dodatkowo (na zielono) wyświetlana jest wartość, o jaką wzrosła w porównaniu z poprzednim okresem. Jeśli wartość wskaźnika w bieżącym okresie spadła
			                                                                       |w porównaniu z poprzednim okresem,
			                                                                       |to wartość, o którą spadła wartość jest wyświetlana na szaro.';
			                                                                       |tr = 'Yönetim muhasebesi para biriminde (%3)%1 ile %2arasındaki dönem için yeni müşterilere yapılan satışlarla karşılaştırma.
			                                                                       |Önceki döneme ait yeni müşterilere yapılan satışlar görüntülenir. Cari dönem göstergesi bir önceki döneme göre artmışsa
			                                                                       |, göstergenin bir önceki döneme göre arttığı değer ek olarak
			                                                                       | görüntülenir (yeşil renkte). Cari dönemdeki göstergenin değeri bir önceki döneme göre azalmışsa,
			                                                                       | göstergenin azaldığı değer gri renkte görüntülenir.'"),
			                                                                       StartDate,
			                                                                       EndDate,
			                                                                       ManagementAccountingCurrency);
			
		EndIf;
		
	ElsIf DataSetName = "IncurredCustomerClaims" Then
		
		If Not ForAdditionalPeriod Then
			
			LegendText = StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = 'Thông tin về số lượng phát sinh khiếu nại của khách hàng trong kỳ từ %1 đến %2. 
			                                                                       |Thực hiện sắp xếp theo trình tự giảm dần số lượng phát sinh khiếu nại của khách hàng.';
			                                                                       |ru = 'Информация о количестве возникших в период с %1 по %2 претензий клиентах. 
			                                                                       |Сортировка производится в порядке убывания количества возникших претензий клиентов.';
			                                                                       |en = 'Information about customer complaints that arose in the period from %1 till %2.
			                                                                       |It is sorted in descending order of a number of customer complaints.'; fa = 'Information about customer complaints that arose in the period from %1 till %2.
			                                                                       |It is sorted in descending order of a number of customer complaints.';
			                                                                       |it = 'Informazioni circa i reclami presentati dai clienti nel periodo da %1 a %2. 
			                                                                       | L''ordinamento viene eseguito in ordine di reclami presentati dai clienti.';
			                                                                       |pl = 'Informacje o liczbie reklamacji od klientów powstających w okresie od %1 do %2. 
			                                                                       |Sortowanie odbywa się malejąco wg liczby powstałych reklamacji klientów.';
			                                                                       |tr = '%1den %2''a kadar olan dönemde ortaya çıkan müşteri şikayetlerinin sayısı hakkında bilgi.
			                                                                       | Yapılan müşteri şikayetlerinin sayısına göre azalan sırada sıralanmıştır.'"),
			                                                                       StartDate,
			                                                                       EndDate);
			
		Else
			LegendText = StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = 'So sánh với số lượng phát sinh khiếu nại của khách hàng trong kỳ từ %1 đến %2. 
			                                                                       |Hiển thị thông tin về số lượng phát sinh khiếu nại của khách hàng trong kỳ trước. Nếu trong kỳ này, giá trị chỉ số tăng
			                                                                       |so với kỳ trước, thì hiển thị thêm (bằng màu xám) giá trị mà chỉ số tăng lên
			                                                                       | so với kỳ trước. Nếu giá trị của chỉ số trong kỳ này giảm so với kỳ trước,
			                                                                       |thì giá trị mà chỉ số đã giảm sẽ được hiển thị bằng màu xanh lá cây.';
			                                                                       |ru = 'Сравнение с количеством возникших в период с %1 по %2 претензий клиентов. 
			                                                                       |Выводится информация о количестве возникших в предыдущий период претензий клиентов. Если в текущем периоде значение показателя выросло
			                                                                       |по сравнению с предыдущим периодом,то дополнительно (серым цветом) отображается значение, на которое увеличился показатель
			                                                                       |по сравнению с предыдущим периодом. Если значение показателя в текущем периоде уменьшилось по сравнению с предыдущим периодом,
			                                                                       |то значение, на которое уменьшился показатель отображается зеленым цветом.';
			                                                                       |en = 'Comparison with the number of customer complaints occurred during the period from %1 to %2. 
			                                                                       |Information about the number of customer complaints occurred in the previous period. If indicator value for the current period is greater 
			                                                                       |than those for the previous period, the difference value is highlighted in gray. 
			                                                                       |If the indicator value for the current period is less than those for the previous period,
			                                                                       |the difference value is highlighted in green.'; fa = 'Comparison with the number of customer complaints occurred during the period from %1 to %2. 
			                                                                       |Information about the number of customer complaints occurred in the previous period. If indicator value for the current period is greater 
			                                                                       |than those for the previous period, the difference value is highlighted in gray. 
			                                                                       |If the indicator value for the current period is less than those for the previous period,
			                                                                       |the difference value is highlighted in green.';
			                                                                       |it = 'Confronto con la quantità di reclami presentati dai clienti nel periodo da %1 a %2.
			                                                                       | Vengono fornite le informazioni sulla quantità di reclami esposti dai clienti mel periodo precedente. Se nel periodo corrente il valore dell''indicatore è aumentato
			                                                                       | rispetto al periodo precedente, alla somma viene aggiunto (in grigio)  il valore
			                                                                       | aumentato rispetto al periodo precedente. Se il valore dell''indicatore nel periodo corrente è diminuito
			                                                                       | rispetto al periodo precedente, la misura in cui il valore dell''indicatore è diminuto viene visualizzato in verde.';
			                                                                       |pl = 'Porównanie z ilością powstałych w okresie od %1 do %2 roszczeń klientów. 
			                                                                       |Wyświetlane są informacje o ilości powstałych w poprzednim okresie roszczeń klientów. Jeśli w bieżącym okresie wartość wskaźnika wzrosła
			                                                                       |w porównaniu z poprzednim okresem, wtedy dodatkowo (na szaro) wyświetlana jest wartość, o jaką wzrosła w porównaniu z poprzednim okresem. Jeśli wartość wskaźnika
			                                                                       |w bieżącym okresie spadła w porównaniu z poprzednim okresem,
			                                                                       |to wartość, o którą spadła wartość jest wyświetlana na zielono.';
			                                                                       |tr = '%1den %2 kadar dönemdeki müşteri şikayeti sayısı ile karşılaştırma.
			                                                                       | Önceki dönemdeki müşteri şikayetlerinin sayısına ilişkin bilgiler görüntülenir. Cari dönemde göstergenin değeri bir önceki döneme göre artmışsa,
			                                                                       | göstergenin bir önceki döneme göre arttığı değer ek olarak
			                                                                       | gösterilir (gri renkte). Cari dönemde göstergenin değeri bir önceki döneme kıyasla azalmışsa,
			                                                                       | göstergenin azaldığı değer yeşil renkte gösterilir.'"),
			                                                                       StartDate,
			                                                                       EndDate);
			
		EndIf;
		
	ElsIf DataSetName = "ComplaintReasons" Then
		
		If Not ForAdditionalPeriod Then
			
			LegendText = StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = 'Thông tin về 5 điều thường gặp nhất đối với các khiếu nại trong kỳ từ %1 đến %2
			                                                                       |kết hợp giữa ""người quản lý - nguyên nhân phát sinh khiếu nại"".';
			                                                                       |ru = 'Информация о 5 наиболее часто встречающихся для зарегистрированных в период с %1 по %2 претензий клиентов
			                                                                       |сочетаниях ""менеджер - причина возникновения претензии"".';
			                                                                       |en = 'Information about 5 mostly used combinations ""Manager: root cause"" 
			                                                                       | for the complaints registered in the period from %1 till %2.'; fa = 'Information about 5 mostly used combinations ""Manager: root cause"" 
			                                                                       | for the complaints registered in the period from %1 till %2.';
			                                                                       |it = 'Informazioni circa i 5 reclami riscontrati più frequentemente nel periodo da %1 a %2
			                                                                       | nelle combinazioni ""manager - causa reclami"".';
			                                                                       |pl = 'Informacje na temat 5 najczęściej spotykanych dla zarejestrowanych za okres od %1 do %2 skarg klientów 
			                                                                       |w kombinacjach ""manager - przyczyna roszczenia"".';
			                                                                       |tr = '%1 ve %2 arasında kaydedilen 
			                                                                       |müşteri talepleri için en yaygın 5 ""yönetici - şikayet nedeni"" kombinasyonuna ilişkin bilgiler.'"),
			                                                                       StartDate,
			                                                                       EndDate);
			
		Else
			
			LegendText = StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = 'Thông tin về 5 điều thường gặp nhất đối với các khiếu nại trong kỳ từ %1 đến %2
			                                                                       |kết hợp giữa ""người quản lý - nguyên nhân phát sinh khiếu nại"".';
			                                                                       |ru = 'Информация о 5 наиболее часто встречающихся для зарегистрированных в период с %1 по %2 претензий клиентов
			                                                                       |сочетаниях ""менеджер - причина возникновения претензии"".';
			                                                                       |en = 'Information about 5 mostly used combinations ""Manager: root cause"" 
			                                                                       | for the complaints registered in the period from %1 till %2.'; fa = 'Information about 5 mostly used combinations ""Manager: root cause"" 
			                                                                       | for the complaints registered in the period from %1 till %2.';
			                                                                       |it = 'Informazioni circa i 5 reclami riscontrati più frequentemente nel periodo da %1 a %2
			                                                                       | nelle combinazioni ""manager - causa reclami"".';
			                                                                       |pl = 'Informacje na temat 5 najczęściej spotykanych dla zarejestrowanych za okres od %1 do %2 skarg klientów 
			                                                                       |w kombinacjach ""manager - przyczyna roszczenia"".';
			                                                                       |tr = '%1 ve %2 arasında kaydedilen 
			                                                                       |müşteri talepleri için en yaygın 5 ""yönetici - şikayet nedeni"" kombinasyonuna ilişkin bilgiler.'"),
			                                                                       StartDate,
			                                                                       EndDate);
			
		EndIf;

	EndIf;
	
	Return LegendText; 
	
EndFunction

Procedure OutputTable_(DataTable,ReportTable,GenerationParameters,SetName, StructureOfReportGenerationPeriods, Template)
	
	OutputAreaWithoutParameters("IsBlankString",ReportTable, Template);
	
	TablePreparedData = DataTableForTabularOutput(SetName,DataTable,StructureOfReportGenerationPeriods.ThereIsExtraPeriod);
	
	For Indus = 0 To TablePreparedData.Columns.Count() - 1 Do
		
		If Indus = 0 Then
			Area = Template.GetArea("TableHeader|Indent");
			ReportTable.Put(Area);
		EndIf;
		Area = Template.GetArea("TableHeader|Factor");
		TableColumn2 = TablePreparedData.Columns[Indus]; // ValueTableColumn
		Area.Parameters.IndicatorName = TableColumn2.Title;
		ReportTable.Join(Area);
		
	EndDo;
	
	For Each TableRow In TablePreparedData Do
		
		For Indus = 0 To TablePreparedData.Columns.Count() - 1 Do
			
			If Indus = 0 Then
				Area = Template.GetArea("TableHeader|Indent");
				ReportTable.Put(Area);
			EndIf;
			Area = Template.GetArea("TableRow|Factor");
			Area.Parameters.IndicatorValue = TableRow[Indus];
			ReportTable.Join(Area);
			
		EndDo;
		
	EndDo;
	
	OutputAreaWithoutParameters("IsBlankString",ReportTable, Template);
	
EndProcedure

Function DataTableForTabularOutput(SetName,DataTable,ThereIsExtraPeriod)
	
	TableForReturn = DataTable.Copy();
	
	If Not ThereIsExtraPeriod Then
		
		If SetName = "Profit_" Or SetName = "Sales" 
			Or SetName = "ReceiptOfCash" Or SetName = "ReceiptOfDS_MinusCost" 
			Or SetName = "LossesOverdueReceivables" Or SetName = "SalesPerOpportunity"
			Or SetName = "SalesPerOneInteraction" Or SetName = "SalesToNewCustomers"
			Or SetName = "IncurredCustomerClaims"Then
			
			TableForReturn.Sort(TableForReturn.Columns[1].Name + " DESC");
			TableForReturn.Columns[1].Title = IndicatorTitle(SetName);
			
		ElsIf SetName = "ManualDiscountsAreProvided" Then
			
			TableForReturn.Sort(TableForReturn.Columns[3].Name + " DESC," + TableForReturn.Columns[1].Name + " DESC");
			For Indus = 1 To TableForReturn.Columns.Count() - 1 Do
				TableColumn2 = TableForReturn.Columns[Indus]; // ValueTableColumn
				TableColumn2.Title = IndicatorTitle(TableColumn2.Name);
			EndDo;
		
		ElsIf SetName = "EfficiencyOfOpportunityManagement" Then
			
			TableForReturn.Sort(TableForReturn.Columns[3].Name + " DESC," + TableForReturn.Columns[1].Name + " DESC,"+ TableForReturn.Columns[2].Name + " ASC");
			For Indus = 1 To TableForReturn.Columns.Count() - 1 Do
				TableColumn2 = TableForReturn.Columns[Indus]; // ValueTableColumn
				TableColumn2.Title = IndicatorTitle(TableColumn2.Name);
			EndDo;
			
		ElsIf SetName = "InteractionEfficiency" Then
			
			TableForReturn.Sort(TableForReturn.Columns[4].Name + " DESC," + TableForReturn.Columns[1].Name + " DESC");
			For Indus = 1 To TableForReturn.Columns.Count() - 1 Do
				TableColumn2 = TableForReturn.Columns[Indus]; // ValueTableColumn
				TableColumn2.Title = IndicatorTitle(TableColumn2.Name);
			EndDo;
			
		ElsIf SetName = "CustomerBaseTrends" Then
			
			TableForReturn.Sort(TableForReturn.Columns[4].Name + " DESC," + TableForReturn.Columns[1].Name + " DESC");
			For Indus = 1 To TableForReturn.Columns.Count() - 1 Do
				TableColumn2 = TableForReturn.Columns[Indus]; // ValueTableColumn
				TableColumn2.Title = IndicatorTitle(TableColumn2.Name);
			EndDo;
			
			For Each TableRowToReturn In TableForReturn Do
				TableRowToReturn.Lost_ = - TableRowToReturn.Lost_;
			EndDo;
			
		ElsIf SetName = "ReasonsForLosingSalesOpportunities" Or SetName = "TheMainStagesOfLosses" 
			Or SetName = "DissatisfactionWithPrimaryDemand" Or SetName = "ComplaintReasons" Then
			
			For Each TableRow In TableForReturn Do
			
				TableRow[0] = TableRow[0] + " - " + TableRow[1];
			
			EndDo;
			
			TableForReturn.Columns.Delete(1);
			TableColumn2 = TableForReturn.Columns[0]; // ValueTableColumn
			TableColumn2.Title = IndicatorTitle(SetName);
			
		EndIf;
		
	Else
		
		If SetName = "Profit_" Or SetName = "Sales" 
			Or SetName = "ReceiptOfCash" Or SetName = "ReceiptOfDS_MinusCost" 
			Or SetName = "LossesOverdueReceivables" Or SetName = "SalesPerOpportunity"
			Or SetName = "SalesPerOneInteraction" Or SetName = "SalesToNewCustomers"
			Or SetName = "IncurredCustomerClaims" Then
			
			TableColumn2 = TableForReturn.Columns[1]; // ValueTableColumn
			TableForReturn.Sort(TableColumn2.Name + " DESC");
			For Each TableRow In TableForReturn Do
				
				AbsoluteUpdate = TableRow[3] + TableRow[4];
				
				TableRow[3] = TableRow[3] + TableRow[4];
				TableRow[4] = ?(TableRow[1] = 0 Or TableRow[2] = 0 , 0 , AbsoluteUpdate / TableRow[2] * 100);
				
			EndDo;
			
			TableColumn21 = TableForReturn.Columns[1]; // ValueTableColumn
			TableColumn22 = TableForReturn.Columns[2]; // ValueTableColumn
			TableColumn23 = TableForReturn.Columns[3]; // ValueTableColumn
			TableColumn24 = TableForReturn.Columns[4]; // ValueTableColumn
			
			TableColumn21.Title = StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = '%1 trong kỳ hiện tại';
																								|ru = '%1 в текущем периоде';
																								|en = '%1 in the current period'; fa = '%1 in the current period';
																								|it = '%1 nel corrente periodo';
																								|pl = '%1 w bieżącym okresie';
																								|tr = 'cari dönemde %1'"),IndicatorTitle(SetName));
			TableColumn22.Title = StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = '%1 trong kỳ trước';
																								|ru = '%1 в предыдущем периоде';
																								|en = '%1 in the previous period'; fa = '%1 in the previous period';
																								|it = '%1 nel precedente periodo';
																								|pl = '%1 w poprzednim okresie';
																								|tr = 'önceki dönemde %1'"),IndicatorTitle(SetName));
			TableColumn23.Title = NStr("vi = 'Thay đổi tuyệt đối';
										|ru = 'Абсолютное изменение';
										|en = 'Absolute change'; fa = 'Absolute change';
										|it = 'Modifica totale';
										|pl = 'Bezwzględna zmiana';
										|tr = 'Mutlak değişiklik'");
			TableColumn24.Title = NStr("vi = 'Thay đổi tương đối(%)';
										|ru = 'Относительное изменение(%)';
										|en = 'Relative variation (%)'; fa = 'Relative variation (%)';
										|it = 'Modifica parziale(%)';
										|pl = 'Względna zmiana(%)';
										|tr = 'Göreceli değişim (%)'");
			
		ElsIf SetName = "ManualDiscountsAreProvided" Then
			
			TableColumn23 = TableForReturn.Columns[3];  // ValueTableColumn
			TableColumn21 = TableForReturn.Columns[1]; // ValueTableColumn
			
			TableForReturn.Sort(TableColumn23.Name + " DESC," + TableColumn21.Name + " DESC");
			For Indus = 1 To TableForReturn.Columns.Count() - 1 Do
				TableColumn2 = TableForReturn.Columns[Indus]; // ValueTableColumn
				TableColumn2.Title = IndicatorTitle(TableColumn2.Name);
			EndDo;
			
		ElsIf SetName = "EfficiencyOfOpportunityManagement" Then
			
			TableColumn21 = TableForReturn.Columns[1]; // ValueTableColumn
			TableColumn22 = TableForReturn.Columns[2]; // ValueTableColumn
			TableColumn23 = TableForReturn.Columns[3]; // ValueTableColumn
			
			TableForReturn.Sort(TableColumn23.Name + " DESC," + TableColumn21.Name + " DESC,"+ TableColumn22.Name + " ASC");
			For Indus = 1 To TableForReturn.Columns.Count() - 1 Do
				TableColumn2 = TableForReturn.Columns[Indus]; // ValueTableColumn
				TableColumn2.Title = IndicatorTitle(TableColumn2.Name);
			EndDo;
			
		ElsIf SetName = "InteractionEfficiency" Then
			
			TableColumn21 = TableForReturn.Columns[1]; // ValueTableColumn
			TableColumn24 = TableForReturn.Columns[4]; // ValueTableColumn
			
			TableForReturn.Sort(TableColumn24.Name + " DESC," + TableColumn21.Name + " DESC");
			For Indus = 1 To TableForReturn.Columns.Count() - 1 Do
				TableColumn2 = TableForReturn.Columns[Indus]; // ValueTableColumn
				TableColumn2.Title = IndicatorTitle(TableColumn2.Name);
			EndDo;
			
		ElsIf SetName = "CustomerBaseTrends" Then
			
			TableColumn21 = TableForReturn.Columns[1]; // ValueTableColumn
			TableColumn24 = TableForReturn.Columns[4]; // ValueTableColumn
			
			TableForReturn.Sort(TableColumn24.Name + " DESC," + TableColumn21.Name + " DESC");
			For Indus = 1 To TableForReturn.Columns.Count() - 1 Do
				TableColumn2 = TableForReturn.Columns[Indus]; // ValueTableColumn
				TableColumn2.Title = IndicatorTitle(TableColumn2.Name);
			EndDo;
			
			For Each TableRowToReturn In TableForReturn Do
				TableRowToReturn.LostSouls = - TableRowToReturn.LostSouls;
				TableRowToReturn.LostCur    = - TableRowToReturn.LostCur;
			EndDo;
			
		ElsIf SetName = "ReasonsForLosingSalesOpportunities" Or SetName = "TheMainStagesOfLosses" 
			Or SetName = "DissatisfactionWithPrimaryDemand" Or SetName = "ComplaintReasons" Then
			
			For Each TableRow In TableForReturn Do
			
				TableRow[0] = TableRow[0] + " - " + TableRow[1];
			
			EndDo;
			
			TableForReturn.Columns.Delete(1);
			
			TableForConversion = New ValueTable;
			TableForConversion.Columns.Add("IndicatorNameCur");
			TableForConversion.Columns.Add("CurrentIndicatorValue");
			TableForConversion.Columns.Add("IndicatorNamePrevious");
			TableForConversion.Columns.Add("IndicatorValuePrevious");
			
			LineNumberCurPeriod = 1;
			
			For Each TableRow In TableForReturn Do
			
				If TableRow.Period = "Previous" Then
					
					TableRowForConversion = TableForConversion.Add();
					TableRowForConversion.IndicatorNamePrevious = TableRow.Manager;
					TableRowForConversion.IndicatorValuePrevious = TableRow.IndicatorValue;
					
				Else
					
					If LineNumberCurPeriod > TableForConversion.Count() Then
						TableRowForConversion = TableForConversion.Add();
					Else
						TableRowForConversion = TableForConversion[LineNumberCurPeriod - 1];
					EndIf;
					
					LineNumberCurPeriod = LineNumberCurPeriod + 1;
					
					TableRowForConversion.IndicatorNameCur = TableRow.Manager;
					TableRowForConversion.CurrentIndicatorValue = TableRow.IndicatorValue;
					
				EndIf;
			
			EndDo;
			
			TableForReturn = TableForConversion.Copy();
			
			TableColumn20 = TableForReturn.Columns[0]; // ValueTableColumn
			TableColumn21 = TableForReturn.Columns[1]; // ValueTableColumn
			TableColumn22 = TableForReturn.Columns[2]; // ValueTableColumn
			TableColumn23 = TableForReturn.Columns[3]; // ValueTableColumn
			
			TableColumn20.Title = IndicatorTitle(SetName + "IndicatorName" + "Current_");
			TableColumn21.Title = IndicatorTitle(SetName + "IndicatorValue" + "Current_");
			TableColumn22.Title = IndicatorTitle(SetName + "IndicatorName" + "Previous");
			TableColumn23.Title = IndicatorTitle(SetName + "IndicatorValue" + "Previous");
			
		EndIf;
		
	EndIf;
	
	Return TableForReturn;

EndFunction 

Function IndicatorTitle(IndicatorName)
	
	IndicatorTitle = IndicatorName;
	ThisIsOutputOfCurPeriodHeader = False;
	ThisIsOutputOfPreviousPeriodHeader = False;
	
	If StrOccurrenceCount(IndicatorTitle,"Current_") > 0 Then 
		
		IndicatorTitle = Left(IndicatorTitle,StrLen(IndicatorTitle) - StrLen("Current_"));
		ThisIsOutputOfCurPeriodHeader = True;
		
	ElsIf StrOccurrenceCount(IndicatorTitle,"Previous") > 0 Then
		
		IndicatorTitle = Left(IndicatorTitle,StrLen(IndicatorTitle) - StrLen("Previous"));
		ThisIsOutputOfPreviousPeriodHeader = True;
		
	EndIf;
	
	If IndicatorTitle = "ReceiptOfCash" Then
		
		IndicatorTitle = NStr("vi = 'Thu tiền';
								|ru = 'Поступление денежных средств';
								|en = 'Incoming payment'; fa = 'دریافت ورودی';
								|it = 'Flusso di cassa';
								|pl = 'Wpływ środków pieniężnych';
								|tr = 'Nakit girişi'");
		
	ElsIf  IndicatorTitle = "ReceiptOfDS_MinusCost" Then
		
		IndicatorTitle = NStr("vi = 'Doanh thu (khi thanh toán) trừ giá vốn (khi giao hàng)';
								|ru = 'Выручка (по оплате) минус себестоимость (по отгрузке)';
								|en = 'Revenue (by payment) minus cost (by shipment)'; fa = 'Revenue (by payment) minus cost (by shipment)';
								|it = 'Entrate (pagamenti) meno costo (alla spedizione)';
								|pl = 'Przychód (przy płatności) minus koszt własny (przy wysyłce)';
								|tr = 'Gelir (ödemede) eksi satışların maliyeti (sevkiyatta)'");
		
	ElsIf  IndicatorTitle = "LossesOverdueReceivables" Then
		
		IndicatorTitle = NStr("vi = 'Mất';
								|ru = 'Потери';
								|en = 'Losses'; fa = 'Losses';
								|it = 'Perdite';
								|pl = 'Straty';
								|tr = 'Zararlar'");
		
	ElsIf  IndicatorTitle = "SalesPerOpportunity" Then
		
		IndicatorTitle = NStr("vi = 'Bán hàng trên một vụ việc';
								|ru = 'Продажи на одну сделку';
								|en = 'Sales per sales opportunity'; fa = 'Sales per sales opportunity';
								|it = 'Vendite per un accordo';
								|pl = 'Sprzedaż w jednej umowie';
								|tr = 'İşlem başına satışlar'");
		
	ElsIf IndicatorTitle = "SalesPerOneInteraction" Then
		
		IndicatorTitle = NStr("vi = 'Bán hàng trên một lần giao tiếp';
								|ru = 'Продажи на одно взаимодействие';
								|en = 'Sales per one interaction'; fa = 'Sales per one interaction';
								|it = 'Vendite per una interazione';
								|pl = 'Sprzedaż w jednej interakcji';
								|tr = 'Etkileşim başına satışlar'");
		
	ElsIf IndicatorTitle = "SalesToNewCustomers" Then
		
		IndicatorTitle = NStr("vi = 'Bán hàng cho khách hàng mới';
								|ru = 'Продажи новым клиентам';
								|en = 'Sales to new customers'; fa = 'Sales to new customers';
								|it = 'Vendite a nuovi clienti';
								|pl = 'Sprzedaży na rzecz nowych klientów';
								|tr = 'Yeni müşterilere satışlar'");
		
	ElsIf IndicatorTitle = "ManualDiscount" Then
		
		IndicatorTitle = NStr("vi = 'Số tiền chiết khấu thủ công';
								|ru = 'Сумма ручной скидки';
								|en = 'Discount adjustment amount'; fa = 'مبلغ اصلاح تخفیف';
								|it = 'Somma dello sconto da inserire manualmente';
								|pl = 'Suma rabatu ręcznego';
								|tr = 'İndirim düzeltmesi tutarı'");
		
	ElsIf IndicatorTitle = "ShareOfDiscountFromProfit" Then
		
		IndicatorTitle = NStr("vi = 'Tỷ lệ chiết khấu thủ công trong doanh thu (%)';
								|ru = 'Доля предоставленной ручной скидки от прибыли (%)';
								|en = 'Share of the provided discount adjustment from profit (%)'; fa = 'Share of the provided discount adjustment from profit (%)';
								|it = 'Quota di sconti da inserire manualmente verificatisi in relazione agli utili (%)';
								|pl = 'Udział podanej ręcznej zniżki od zysku (%)';
								|tr = 'Kârlara verilen indirim düzeltmesi payı (%)'");
		
	ElsIf IndicatorTitle = "WonDeals" Then
		
		IndicatorTitle = NStr("vi = 'Vụ việc đã giành được';
								|ru = 'Выиграно сделок';
								|en = 'Won sales opportunities'; fa = 'فرصت‌های فروش موفق';
								|it = 'Accordi vinti/conclusi';
								|pl = 'Wygrane transakcji';
								|tr = 'Kazanılan anlaşmalar'");
		
	ElsIf IndicatorTitle = "LostDeals" Then
		
		IndicatorTitle = NStr("vi = 'Vụ việc thất bại';
								|ru = 'Проиграно сделок';
								|en = 'Lost sales opportunities'; fa = 'فرصت‌های فروش از دست رفته';
								|it = 'Accordi persi';
								|pl = 'Utracone transakcje';
								|tr = 'Kaybedilen anlaşmalar'");
		
	ElsIf IndicatorTitle = "ShareOfDealsWon" Then
		
		IndicatorTitle = NStr("vi = 'Tỷ lệ vụ việc giành được (%)';
								|ru = 'Доля выигранных сделок (%)';
								|en = 'Percentage of won sales opportunities (%)'; fa = 'Percentage of won sales opportunities (%)';
								|it = 'Percentuale accordi persi';
								|pl = 'Udział wygranych transakcji (%)';
								|tr = 'Kazanılan anlaşmaların payı (%)'");
		
	ElsIf IndicatorTitle = "InteractionsOnWonTrades" Then
		
		IndicatorTitle = NStr("vi = 'Giao tiếp theo vụ việc đã thất bại';
								|ru = 'Взаимодействий по выигранным сделкам';
								|en = 'Interactions on won sales opportunities'; fa = 'Interactions on won sales opportunities';
								|it = 'Interazioni con accordi vinti/conclusi';
								|pl = 'Interakcje w wygranych umowach';
								|tr = 'Kazanılan anlaşmalarla ilgili etkileşimler'");
		
	ElsIf IndicatorTitle = "InteractionsOnLostTrades" Then
		
		IndicatorTitle = NStr("vi = 'Giao tiếp theo vụ việc đã thất bại';
								|ru = 'Взаимодействий по проигранным сделкам';
								|en = 'Interactions on lost sales opportunities'; fa = 'Interactions on lost sales opportunities';
								|it = 'Interazioni con accordi persi';
								|pl = 'Interakcje w przegranych umowach';
								|tr = 'Kaybedilen anlaşmalarla ilgili etkileşimler'");
		
	ElsIf IndicatorTitle = "OtherInteractions" Then
		
		IndicatorTitle = NStr("vi = 'Giao tiếp khác';
								|ru = 'Прочие взаимодействия';
								|en = 'Other interactions'; fa = 'Other interactions';
								|it = 'Altre interazioni';
								|pl = 'Inne interakcje';
								|tr = 'Diğer etkileşimler'");
		
	ElsIf IndicatorTitle = "ShareOfInteractionsOnWonDeals" Then
		
		IndicatorTitle = NStr("vi = 'Tỷ lệ giao tiếp theo vụ việc giành được (%)';
								|ru = 'Доля взаимодействий по выигранным сделкам(%)';
								|en = 'Percentage of interactions on won sales opportunities (%)'; fa = 'Percentage of interactions on won sales opportunities (%)';
								|it = 'Percentuale interazione per accordi persi';
								|pl = 'Udział interakcji w wygranych umowach(%)';
								|tr = 'Kazanılan anlaşmalarda etkileşimlerin payı (%)'");
		
	ElsIf IndicatorTitle = "New_Items" Then
		
		IndicatorTitle = NStr("vi = 'Khách hàng mới';
								|ru = 'Новые клиенты';
								|en = 'New customers'; fa = 'New customers';
								|it = 'Nuovi clienti';
								|pl = 'Nowi klienci';
								|tr = 'Yeni müşteriler'");
		
	ElsIf IndicatorTitle = "Lost_" Then
		
		IndicatorTitle = NStr("vi = 'Khách hàng bị mất';
								|ru = 'Потерянные клиенты';
								|en = 'Lost customers'; fa = 'Lost customers';
								|it = 'Clienti persi';
								|pl = 'Utracone klienci';
								|tr = 'Kaybedilen müşteriler'");
		
	ElsIf IndicatorTitle = "Profit_" Then
		
		IndicatorTitle = NStr("vi = 'Lợi nhuận';
								|ru = 'Прибыль';
								|en = 'Profit'; fa = 'سود';
								|it = 'Utile';
								|pl = 'Zysk';
								|tr = 'Kâr'");
		
	ElsIf IndicatorTitle = "Sales" Then
		
		IndicatorTitle = NStr("vi = 'Bán hàng';
								|ru = 'Продажи';
								|en = 'Sales'; fa = 'فروش';
								|it = 'Vendite';
								|pl = 'Sprzedaż';
								|tr = 'Satışlar'");
		
	ElsIf IndicatorTitle = "WasReturned" Then
		
		IndicatorTitle = NStr("vi = 'Khách hàng quay trở lại';
								|ru = 'Вернувшиеся клиенты';
								|en = 'Returned customers'; fa = 'Returned customers';
								|it = 'Clienti ritornati';
								|pl = 'Powracające klienci';
								|tr = 'Geri dönen müşteriler'");
		
	ElsIf IndicatorTitle = "ShareOfNewCustomers" Then
		
		IndicatorTitle = NStr("vi = 'Tỷ lệ khách hàng mới (%)';
								|ru = 'Доля новых клиентов (%)';
								|en = 'Percentage of new customers (%)'; fa = 'Percentage of new customers (%)';
								|it = 'Percentuale nuovi clienti';
								|pl = 'Udział nowych klientów (%)';
								|tr = 'Yeni müşterilerin payı (%)'");
		
	ElsIf IndicatorTitle = "IncurredCustomerClaims" Then
		
		IndicatorTitle = NStr("vi = 'Khiếu nại phát sinh';
								|ru = 'Возникшие претензии';
								|en = 'Incurred complaints'; fa = 'Incurred complaints';
								|it = 'Reclami esposti';
								|pl = 'Powstałe roszczenia';
								|tr = 'Oluşan şikayetler'");
		
	ElsIf IndicatorTitle = "ReasonsForLosingSalesOpportunities" Or IndicatorTitle = "ReasonsForLosingSalesOpportunities" + "IndicatorName" Then
		
		IndicatorTitle = NStr("vi = '""Người quản lý - nguyên nhân thất bại""';
								|ru = '""Менеджер - причина проигрыша""';
								|en = '""Manager: reason for losing""'; fa = '""Manager: reason for losing""';
								|it = '""manager - causa perdita""';
								|pl = '""Manager - powód przegranej""';
								|tr = '""Yönetici - kaybın sebebi""'");
		
	ElsIf IndicatorTitle = "TheMainStagesOfLosses" Or IndicatorTitle = "TheMainStagesOfLosses" + "IndicatorName" Then
		
		IndicatorTitle = NStr("vi = '""Người quản lý - giai đoạn của vụ việc""';
								|ru = '""Менеджер - этап сделки""';
								|en = '""Manager: sales opportunity stage""'; fa = '""Manager: sales opportunity stage""';
								|it = '""manager - fase accordo""';
								|pl = '""Manager - etap umowy""';
								|tr = '""Yönetici - anlaşma aşaması""'");
		
	ElsIf IndicatorTitle = "TheMainStagesOfLosses" + "IndicatorValue" Or IndicatorTitle = "ReasonsForLosingSalesOpportunities" + "IndicatorValue"
		Or IndicatorTitle = "ComplaintReasons" + "IndicatorValue" Then
		
		IndicatorTitle = NStr("vi = 'Số lượng';
								|ru = 'Количество';
								|en = 'Quantity'; fa = 'مقدار';
								|it = 'Quantità';
								|pl = 'Ilość';
								|tr = 'Miktar'");
		
	ElsIf IndicatorTitle = "DissatisfactionWithPrimaryDemand" Or IndicatorTitle = "DissatisfactionWithPrimaryDemand" + "IndicatorName" Then
		
		IndicatorTitle = NStr("vi = '""Người quản lý - nguyên nhân không đảm bảo""';
								|ru = '""Менеджер - причина неудовлетворения""';
								|en = '""Manager: reason for non-fulfillment""'; fa = '""Manager: reason for non-fulfillment""';
								|it = '""manager - causa insoddisfazione""';
								|pl = '""Manager - powód niezadowolenia""';
								|tr = '""Yönetici - karşılanmama sebebi""'");
		
	ElsIf IndicatorTitle = "AmountOfPrimaryDemand" Or IndicatorTitle = "DissatisfactionWithPrimaryDemand" + "IndicatorValue" Then
		
		IndicatorTitle = NStr("vi = 'Tổng số nhu cầu chưa đảm bảo';
								|ru = 'Сумма неудовлетворенного спроса';
								|en = 'Unfulfilled demand amount'; fa = 'مبلغ نیاز تأمین‌نشده';
								|it = 'Quantità di domanda insoddisfatta';
								|pl = 'Wartość niezaspokojonego popytu';
								|tr = 'Karşılanmayan talep miktarı'");
		
	ElsIf IndicatorTitle = "ComplaintReasons" Or IndicatorTitle = "ComplaintReasons" + "IndicatorName" Then
		
		IndicatorTitle = NStr("vi = '""Người quản lý - nguyên nhân phát sinh""';
								|ru = '""Менеджер - причина возникновения""';
								|en = '""Manager: root cause""'; fa = '""Manager: root cause""';
								|it = '""manager - causa ""';
								|pl = '""Manager - powód powstania""';
								|tr = '""Yönetici - olayın sebebi""'");
		
	EndIf;
	
	If ThisIsOutputOfCurPeriodHeader Then
	
		IndicatorTitle = IndicatorTitle + " " + NStr("vi = 'trong kỳ này';
													|ru = 'в текущем периоде';
													|en = 'in the current period'; fa = 'in the current period';
													|it = 'nel corrente periodo';
													|pl = 'w bieżącym okresie';
													|tr = 'cari dönemde'");
	
	ElsIf ThisIsOutputOfPreviousPeriodHeader Then
	
		IndicatorTitle = IndicatorTitle + " " + NStr("vi = 'trong giai đoạn trước';
													|ru = 'в предыдущем периоде';
													|en = 'in the previous period'; fa = 'in the previous period';
													|it = 'nel precedente periodo';
													|pl = 'w poprzednim okresie';
													|tr = 'önceki dönemde'");
	
	EndIf;
	
	Return IndicatorTitle;
	
EndFunction

Function ConvertDataTableToChart(SetName,DataTable,MainPeriodIsDisplayed,ThereIsExtraPeriod)
	
	TableForReturn = DataTable.Copy();
	
	If SetName = "Profit_" Or SetName = "Sales" 
		Or SetName = "ReceiptOfCash" Or SetName = "ReceiptOfDS_MinusCost" 
		Or SetName = "LossesOverdueReceivables" Or SetName = "SalesPerOpportunity"
		Or SetName = "SalesPerOneInteraction" Or SetName = "SalesToNewCustomers"
		Or SetName = "IncurredCustomerClaims"Then
		
		TableColumn21 = TableForReturn.Columns[1]; // ValueTableColumn
		TableForReturn.Sort(TableColumn21.Name + " DESC");
		
	ElsIf SetName = "ManualDiscountsAreProvided" Then
		
		TableColumn21 = TableForReturn.Columns[1]; // ValueTableColumn
		TableColumn23 = TableForReturn.Columns[3]; // ValueTableColumn
		TableForReturn.Sort(TableColumn23.Name + " DESC," + TableColumn21.Name + " DESC");
	
	ElsIf SetName = "EfficiencyOfOpportunityManagement" Then
		
		TableColumn21 = TableForReturn.Columns[1]; // ValueTableColumn
		TableColumn22 = TableForReturn.Columns[2]; // ValueTableColumn
		TableColumn23 = TableForReturn.Columns[3]; // ValueTableColumn
		
		TableForReturn.Sort(TableColumn23.Name + " DESC," + TableColumn21.Name + " DESC,"+ TableColumn22.Name + " ASC");
		
	ElsIf SetName = "InteractionEfficiency" Then
		
		TableColumn21 = TableForReturn.Columns[1]; // ValueTableColumn
		TableColumn24 = TableForReturn.Columns[4]; // ValueTableColumn
		
		TableForReturn.Sort(TableColumn24.Name + " DESC," + TableColumn21.Name + " DESC");
		
	ElsIf SetName = "CustomerBaseTrends" Then
		
		TableColumn21 = TableForReturn.Columns[1]; // ValueTableColumn
		TableColumn24 = TableForReturn.Columns[4]; // ValueTableColumn
		
		TableForReturn.Sort(TableColumn24.Name + " DESC," + TableColumn21.Name + " DESC");
		
	EndIf;
	
	If Not ThereIsExtraPeriod Then
		
		If SetName = "ManualDiscountsAreProvided" Or SetName = "EfficiencyOfOpportunityManagement" Then
			
				TableForReturn.Columns.Delete(3);
				
		ElsIf SetName = "CustomerBaseTrends" Or SetName = "InteractionEfficiency" Then
			
				TableForReturn.Columns.Delete(4);
			
		EndIf;
		
	Else
		
		If MainPeriodIsDisplayed Then
			
			If SetName = "Profit_" Or SetName = "Sales" 
				Or SetName = "ReceiptOfCash" Or SetName = "ReceiptOfDS_MinusCost" 
				Or SetName = "LossesOverdueReceivables" Or SetName = "SalesPerOpportunity"
				Or SetName = "SalesPerOneInteraction" Or SetName = "SalesToNewCustomers"
				Or SetName = "IncurredCustomerClaims" Then
				
				TableForReturn.Columns.Delete(2);
				TableForReturn.Columns.Delete(2);
				TableForReturn.Columns.Delete(2);
				
			ElsIf SetName = "ManualDiscountsAreProvided" Or SetName = "EfficiencyOfOpportunityManagement" Then
			
				TableForReturn.Columns.Delete(3);
				TableForReturn.Columns.Delete(3);
				TableForReturn.Columns.Delete(3);
				TableForReturn.Columns.Delete(3);
				
			ElsIf SetName = "InteractionEfficiency" Or SetName = "CustomerBaseTrends" Then
				
				TableForReturn.Columns.Delete(4);
				TableForReturn.Columns.Delete(4);
				TableForReturn.Columns.Delete(4);
				TableForReturn.Columns.Delete(4);
				TableForReturn.Columns.Delete(4);
				
			ElsIf SetName = "ReasonsForLosingSalesOpportunities" Or SetName = "TheMainStagesOfLosses"
				Or SetName = "DissatisfactionWithPrimaryDemand" Or SetName = "ComplaintReasons" Then
				
				RowsCount = TableForReturn.Count();
				
				For Indus = 1  To RowsCount Do
					
					If TableForReturn[RowsCount - Indus].Period = "Previous" Then 
						TableForReturn.Delete(RowsCount - Indus);
					EndIf;
					
				EndDo;
				
				TableForReturn.Columns.Delete(3);
				
			EndIf;
			
		Else
			
			If SetName = "Profit_" Or SetName = "Sales"
				Or SetName = "ReceiptOfCash"  Or SetName = "ReceiptOfDS_MinusCost"
				Or SetName = "LossesOverdueReceivables" Or  SetName = "SalesPerOpportunity"
				Or SetName = "SalesPerOneInteraction" Or SetName = "SalesToNewCustomers"
				Or SetName = "IncurredCustomerClaims" Then
				
				TableForReturn.Columns.Delete(1);
				
			ElsIf SetName = "ManualDiscountsAreProvided" Or SetName = "EfficiencyOfOpportunityManagement" Then
				
				TableForReturn.Columns.Delete(1);
				TableForReturn.Columns.Delete(1);
				TableForReturn.Columns.Delete(1);
				TableForReturn.Columns.Delete(3);
				
			ElsIf SetName = "InteractionEfficiency" Or SetName = "CustomerBaseTrends" Then
				
				TableForReturn.Columns.Delete(1);
				TableForReturn.Columns.Delete(1);
				TableForReturn.Columns.Delete(1);
				TableForReturn.Columns.Delete(1);
				TableForReturn.Columns.Delete(4);
				
			ElsIf SetName = "ReasonsForLosingSalesOpportunities" Or SetName = "TheMainStagesOfLosses"
				Or SetName = "DissatisfactionWithPrimaryDemand"  Or SetName = "ComplaintReasons" Then
				
				RowsCount = TableForReturn.Count();
				
				For Indus = 1  To RowsCount Do
					
					If TableForReturn[RowsCount - Indus].Period = "Current_" Then 
						TableForReturn.Delete(RowsCount - Indus);
					EndIf;
					
				EndDo;
				
				TableForReturn.Columns.Delete(3);
				
			EndIf;
			
		EndIf;
		
	EndIf;
	
	If SetName = "ReasonsForLosingSalesOpportunities" Or SetName = "TheMainStagesOfLosses" Or SetName = "DissatisfactionWithPrimaryDemand"
		Or SetName = "ComplaintReasons" Then
		
		For Each TableRow In TableForReturn Do
		
			TableRow[0] = TableRow[0] + " - " + TableRow[1];
		
		EndDo;
		
		TableForReturn.Columns.Delete(1);
		
	EndIf;
	
	Return TableForReturn;
	
EndFunction

#EndRegion

#Region Other

// Generates a report
//
// Parameters:
//  ReportTable         - SpreadsheetDocument - Table document to display the report in
//  GenerationParameters - Structure - structure of report generation parameters.
//
Procedure GenerateReport(ReportTable,GenerationParameters) Export
	
	Template = GetTemplate("ManagersComparativeAnalysis");
	
	StructureOfReportGenerationPeriods = StructureOfReportGenerationPeriods_(GenerationParameters);
	ManagementAccountingCurrency = Constants.ManagementAccountingCurrency.Get();
	
	TreeOfDataSets = GetFromTempStorage(GenerationParameters.TreeOfDataSets);
	
	MatchingRequestsData = New Map;
	QueryResultsArray1 = ExecuteBatchOfRequests(MatchingRequestsData,TreeOfDataSets,GenerationParameters, StructureOfReportGenerationPeriods);
	
	For Each DataGroup In TreeOfDataSets.Rows Do
		
		If DataGroup.Include <> 0 Then
			
			DisplayDataGroupHeader(ReportTable,DataGroup["Description"], Template);
			ReportTable.StartRowGroup(DataGroup["Name"]);
			OutputAreaWithoutParameters("IsBlankString",ReportTable, Template);
			
			For Each DataSet In DataGroup.Rows Do
				
				If DataSet.Include = 1 Then
					
					OutputData(QueryResultsArray1[MatchingRequestsData[DataSet["Name"]]],
					              ReportTable,
					              GenerationParameters,
					              DataSet,
					              ManagementAccountingCurrency,
					              StructureOfReportGenerationPeriods,
					              Template);
					
				EndIf;
				
			EndDo;
			
			ReportTable.EndRowGroup();
			OutputAreaWithoutParameters("IsBlankString",ReportTable, Template);
			
		EndIf;
	EndDo;
	
EndProcedure

Function StructureOfReportGenerationPeriods_(GenerationParameters)
	
	ReportGenerationPeriod       = GenerationParameters.ReportGenerationPeriod; // StandardPeriod
	AdditionalPeriodForAnalysis = GenerationParameters.AdditionalPeriodForAnalysis; // StandardPeriod
	
	StructureToReturn = New Structure;
	StructureToReturn.Insert("StartDate",                        ReportGenerationPeriod.StartDate);
	StructureToReturn.Insert("EndDate",                     ReportGenerationPeriod.EndDate);
	StructureToReturn.Insert("ThereIsExtraPeriod",          False);
	StructureToReturn.Insert("StartDateAdditionalPeriod",    Date(1,1,1));
	StructureToReturn.Insert("EndDateAdditionalPeriod", Date(1,1,1));
	
	If AdditionalPeriodForAnalysis = "LastYear" Then
		
		StructureToReturn.ThereIsExtraPeriod                = True;
		StructureToReturn.StartDateAdditionalPeriod          = AddMonth(ReportGenerationPeriod.StartDate, -12);
		StructureToReturn.EndDateAdditionalPeriod       = AddMonth(ReportGenerationPeriod.EndDate, -12);
		
	ElsIf AdditionalPeriodForAnalysis = "PreviousPeriod_" Then 
		
		Value_Period =  ReportGenerationPeriod.EndDate - ReportGenerationPeriod.StartDate + 1;
		
		StructureToReturn.ThereIsExtraPeriod                = True;
		StructureToReturn.StartDateAdditionalPeriod          = ReportGenerationPeriod.StartDate - Value_Period;
		StructureToReturn.EndDateAdditionalPeriod       = ReportGenerationPeriod.EndDate - Value_Period;
		
	EndIf;
	
	Return StructureToReturn;
	
EndFunction

Procedure PrintDataSetHeader(ReportTable,TitleText,ThereIsExtraPeriod, Template)

	Area = Template.GetArea("DataSetHeader|DiagramIndentation");
	ReportTable.Put(Area);
	
	Area = Template.GetArea("DataSetHeader|ChartColumn");
	DataAreaParameters = DataAreaParameters(TitleText);
	FillPropertyValues(Area.Parameters, DataAreaParameters);
	ReportTable.Join(Area);
	If ThereIsExtraPeriod Then
		DataAreaParameters = DataAreaParameters("");
		FillPropertyValues(Area.Parameters, DataAreaParameters);
		ReportTable.Join(Area);
	EndIf;

EndProcedure

// LongDesc
// 
// Parameters:
// 	ReportTable  - SpreadsheetDocument - report table. 
// 	TitleText - String - header line.
// 	Template          - SpreadsheetDocument- report layout.
//
Procedure DisplayDataGroupHeader(ReportTable,TitleText, Template)

	Area = Template.GetArea("DataGroupHeader");
	DataAreaParameters = DataAreaParameters(TitleText);
	FillPropertyValues(Area.Parameters, DataAreaParameters);
	ReportTable.Put(Area);

EndProcedure

// Generates and fills in the data area parameters of a table document
// 
// Parameters:
// 	TitleText - String - the header region.
// Returns:
// 	Structure - Contains:
//    * TitleText - String - the header region
//
Function DataAreaParameters(TitleText)
	
	AreaParameters_ = New Structure;
	AreaParameters_.Insert("TitleText", TitleText);
	
	Return AreaParameters_;
	
EndFunction

Procedure OutputAreaWithoutParameters(AreaName,ReportTable, Template)

	Area = Template.GetArea(AreaName);
	ReportTable.Put(Area);

EndProcedure

#EndRegion

#EndRegion

#EndIf