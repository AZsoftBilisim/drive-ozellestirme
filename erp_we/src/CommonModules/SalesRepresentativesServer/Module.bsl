#Region Public

// Executes a query based on sales history data.
//
// Parameters:
//  CompositionSettings - DataCompositionSettings - data layout settings for generating a query based on
//  sales history data.
//  BeginOfPeriod - Date - the beginning of the period for which the sales history is analyzed.
//  EndOfPeriod - Date - end of the period for which the sales history is analyzed.
//  Period - String - the period for which the average sales volume is calculated.
//  ItemsDetails - Boolean - indicates whether the item is detailed by item.
//
// Returns:
//  QueryResult - query result.
//
Function MakeRequestForSalesHistory(CompositionSettings, BeginOfPeriod, EndOfPeriod, Period, ItemsDetails) Export

	If ItemsDetails Then
		CompositionSchema = Documents.JobForSalesRepresentative.GetTemplate("LayoutSchemeForAutoFillingWithSalesHistory");
	Else
		CompositionSchema = Documents.JobForSalesRepresentative.GetTemplate("LayoutSchemeForAutoFillingWithSalesHistoryByAmount");
	EndIf;
		
	MobileApps.SetValueOfSettingsParameter(CompositionSettings, "BeginOfPeriod", BeginOfPeriod);
	MobileApps.SetValueOfSettingsParameter(CompositionSettings, "EndOfPeriod", EndOfPeriod);
	MobileApps.SetValueOfSettingsParameter(CompositionSettings, "Period", Period);

	CompositionTemplate = DataCompositionServer.GetLayoutTemplate(CompositionSchema, CompositionSettings);
	
	Query = DataCompositionServer.GETRequestFromLayoutTemplate(CompositionTemplate, "Query");
	
	Return Query.Execute();

EndFunction

// Generates data on the status of payments with the partner.
//
// Parameters:
//  Partner - CatalogRef.Partners - the partner that you want to get data about the status of payments with.
//  TargetDate - Date - planned date of the visit.
//
// Returns:
//  Structure - a structure containing data on the State of settlements with a partner, with the fields:
//  	* TableOfDebts - ValueTable - a table containing information about the debt.
//      * RegisterRecordTable - ValueTable - a table containing information about the movements of the calculations.
//
Function GetDataOnPartnerAccountsReceivable(Partner, TargetDate) Export

	Query = New Query();
	Query.Text = GetRequestTextForAccountsReceivable();
	Query.SetParameter("Partner", Partner);
	Query.SetParameter("TargetDate", TargetDate);
	
	ResultsArray = Query.ExecuteBatch();
	
	QueryResultForDebts = ResultsArray[1];
	QueryResultForRegisteredRecords = ResultsArray[2];
	
	TableOfDebts = QueryResultForDebts.Unload();
	RegisterRecordTable = QueryResultForRegisteredRecords.Unload();
	
	StructureOfData = New Structure();
	StructureOfData.Insert("TableOfDebts", TableOfDebts);
	StructureOfData.Insert("RegisterRecordTable", RegisterRecordTable);
	
	Return StructureOfData;

EndFunction

// Returns a structure containing the values of details related to the date and time of the session.
//
// Parameters:
//  EstimatedDate - Date - the date on which the session is scheduled.
//  VisitSchedule - ValueTable - with columns:
//   *WeekDay - EnumRef.WeekDays - weekday.
//	 *BeginTime - Date - start time of the session.
//   *EndTime - Date - end time of the session.
//
// Returns:
//  Structure - a structure containing the values of Attributes related to the date and time of the session, with the fields:
//  	* PlannedVisitDate - Date - planned date of the session.
//  	* BeginTime - Date - start time of the session.
//  	* EndTime - Date - end time of the session.
//
Function SessionDetails_(EstimatedDate, VisitSchedule) Export

	AttributesStructure1 = New Structure();
	AttributesStructure1.Insert("PlannedVisitDate", '00010101000000');
	AttributesStructure1.Insert("BeginTime", '00010101000000');
	AttributesStructure1.Insert("EndTime", '00010101000000');

	If VisitSchedule.Count() = 0 Then
		Return AttributesStructure1;
	EndIf;

	VisitSchedule.Columns.Add("DueDate");

	CurDayNumber = WeekDay(EstimatedDate);

	For Each PlotLine In VisitSchedule Do

		If PlotLine.WeekDay = Enums.WeekDays.Monday Then
			 PlotLine.DueDate = CalculateTermFromDay(CurDayNumber, 1);
		ElsIf PlotLine.WeekDay = Enums.WeekDays.Tuesday Then
			PlotLine.DueDate = CalculateTermFromDay(CurDayNumber, 2);
		ElsIf PlotLine.WeekDay = Enums.WeekDays.Wednesday Then
			PlotLine.DueDate = CalculateTermFromDay(CurDayNumber, 3);
		ElsIf PlotLine.WeekDay = Enums.WeekDays.Thursday Then
			PlotLine.DueDate = CalculateTermFromDay(CurDayNumber, 4);
		ElsIf PlotLine.WeekDay = Enums.WeekDays.Friday Then
			PlotLine.DueDate = CalculateTermFromDay(CurDayNumber, 5);
		ElsIf PlotLine.WeekDay = Enums.WeekDays.Saturday Then
			PlotLine.DueDate = CalculateTermFromDay(CurDayNumber, 6);
		ElsIf PlotLine.WeekDay = Enums.WeekDays.Sunday Then
			PlotLine.DueDate = CalculateTermFromDay(CurDayNumber, 7);
		EndIf;

	EndDo;
	
	VisitSchedule.Sort("DueDate Asc");
	PlotLine = VisitSchedule[0];

	AttributesStructure1.Insert("PlannedVisitDate",EstimatedDate + PlotLine.DueDate*86400);
	AttributesStructure1.Insert("BeginTime", PlotLine.BeginTime);
	AttributesStructure1.Insert("EndTime", PlotLine.EndTime);

	Return AttributesStructure1;

EndFunction

// Performs task generation for the specified sales representative for the specified period.
//
// Parameters:
//  SalesRepresentative - CatalogRef.Users - the sales representative for whom the terms of service are selected.
//  InitialPlanningDate - Date - the date from which you want to analyze the need for a session based on the terms of service.
//  PlanningEndDate - Date - the date by which you want to analyze the need for a session under the terms of service.
//
Procedure GenerateJobs(SalesRepresentative, InitialPlanningDate, PlanningEndDate) Export
	
	TableOfTermsOfService = GetTermsOfServiceForCreatingTasks(SalesRepresentative, InitialPlanningDate, PlanningEndDate);
	
	For Each TableRow In TableOfTermsOfService Do
		
		Job = Documents.JobForSalesRepresentative.CreateDocument();
		Job.Date = CurrentSessionDate();
		
		FillingData = New Structure();
		FillingData.Insert("Partner", TableRow.Partner);
		FillingData.Insert("ServiceTerms", TableRow.ServiceTerms);
		FillingData.Insert("PlannedVisitDate", TableRow.ScheduledVisitDate);
		FillingData.Insert("Supervisor_", SalesRepresentative);
		FillingData.Insert("SalesRepresentative", SalesRepresentative);
		
		Job.Fill(FillingData);
		Job.Status = Enums.SalesRepresentativeTaskStatuses.ToProcessing;
		
		Try
			Job.Write();
		Except
			DefaultLanguageCode = CommonClientServer.DefaultLanguageCode();
		
			MessageText = ErrorInfo().Description;
			WriteLogEvent(NStr("vi = 'Lỗi ghi công việc cho đại diện bán hàng';
								|ru = 'Ошибка при записи задания торговому представителю';
								|en = 'An error occurred when saving a sales representative task'; fa = 'An error occurred when saving a sales representative task';
								|it = 'Errore durante la scrittura di un lavoro a un rappresentante di vendita';
								|pl = 'Błąd podczas zapisu zadania przedstawiciela handlowego';
								|tr = 'Satış temsilcisine görev yazılırken hata oluştu'", DefaultLanguageCode),
								EventLogLevel.Error,
								,
								,
								MessageText);
		EndTry;
		
	EndDo;
	
EndProcedure

#Region ProceduresForInitializingTermsOfService

// Returns the structure of the terms of service.
//
// Parameters:
//  ServiceTerms - CatalogRef.TermsAndConditionsOfServicesProvidedToCustomersBySalesRepresentatives - link to the terms of service.
//
// Returns:
//  Structure - a structure that includes terms of service, with fields:
//		* ServiceTerms - CatalogRef.TermsAndConditionsOfServicesProvidedToCustomersBySalesRepresentatives - the terms of service.
//      * Terms - CatalogRef.TermsOfSale - agreement with the client.
//      * Supervisor_ - CatalogRef.Users - curator.
//      * SalesRepresentative - CatalogRef.Users - sales representative.
//
Function GetTermsOfService(Val ServiceTerms) Export
	
	FilterParameters = New Structure;
	FilterParameters.Insert("Ref", ServiceTerms);
	
	Return GetTermsOfServiceData(FilterParameters);
	
EndFunction

// Returns the structure of the terms of service for the partner.
//
// Parameters:
//  Partner - CatalogRef.Partners - link to the partner to get the terms of service for.
//
// Returns:
//  Structure - a structure that includes terms of service, with fields:
//  	* ServiceTerms - CatalogRef.TermsAndConditionsOfServicesProvidedToCustomersBySalesRepresentatives - the terms of service.
//      * Terms - CatalogRef.TermsOfSale - agreement with the client.
//      * Supervisor_ - CatalogRef.Users - curator.
//      * SalesRepresentative - CatalogRef.Users - sales representative.
//
Function GetDefaultTermsOfService(Val Partner) Export
	
	If Not ValueIsFilled(Partner) Then
		Return Undefined;
	EndIf;
	
	FilterParameters = New Structure;
	FilterParameters.Insert("Owner",        Partner);
	FilterParameters.Insert("DeletionMark", False);
	
	Return GetTermsOfServiceData(FilterParameters);
	
EndFunction

#EndRegion

#EndRegion

#Region Private

// Generates the request text for getting data about the status of payments with the partner.
//
// Returns:
//  String - the generated request text.
//
Function GetRequestTextForAccountsReceivable()
	
	QueryText = 
	"SELECT ALLOWED
	|	SettlementsWithCustomersBalancesDebts.ARAPObject AS SalesOrder,
	|	SettlementsWithCustomersBalancesDebts.Currency,
	|	SUM(CASE
	|		WHEN SettlementsWithCustomersBalancesDebts.SumBalance < 0
	|			THEN -SettlementsWithCustomersBalancesDebts.SumBalance
	|		ELSE NULL
	|	END) AS AccountsPayableOfCompany,
	|	SUM(CASE
	|		WHEN SettlementsWithCustomersBalancesDebts.SumBalance > 0
	|			THEN SettlementsWithCustomersBalancesDebts.SumBalance
	|		ELSE NULL
	|	END) AS CustomerAccountsReceivable,
	|	PRESENTATION(SettlementsWithCustomersBalancesDebts.ARAPObject) AS OrderPresentation,
	|	SUM(CASE
	|		WHEN SettlementsWithCustomersBalancesOverdueDebts.AmountDueBalance > 0
	|			THEN SettlementsWithCustomersBalancesOverdueDebts.AmountDueBalance
	|		ELSE NULL
	|	END) AS ForPaymentOverdue,
	|	SUM(-SettlementsWithCustomersBalancesOverdueDebts.ToShipBalance) AS ToShipOverdue
	|INTO ARAPByOrders
	|FROM
	|	AccumulationRegister.CustomersARAPAccounting.Balance(, VALUETYPE(ARAPObject) = TYPE(Document.SalesOrder)
	|	AND ARAPObject.Partner = &Partner) AS SettlementsWithCustomersBalancesDebts
	|		LEFT JOIN AccumulationRegister.CustomersARAPAccounting.Balance(&TargetDate,
	|			VALUETYPE(ARAPObject) = TYPE(Document.SalesOrder)
	|		AND ARAPObject.Partner = &Partner) AS SettlementsWithCustomersBalancesOverdueDebts
	|		ON SettlementsWithCustomersBalancesDebts.ARAPObject = SettlementsWithCustomersBalancesOverdueDebts.ARAPObject
	|WHERE
	|	SettlementsWithCustomersBalancesDebts.SumBalance <> 0
	|GROUP BY
	|	SettlementsWithCustomersBalancesDebts.Currency,
	|	SettlementsWithCustomersBalancesDebts.ARAPObject
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED
	|	ARAPByOrders.SalesOrder,
	|	ARAPByOrders.Currency,
	|	ARAPByOrders.OrderPresentation,
	|	ARAPByOrders.AccountsPayableOfCompany,
	|	ARAPByOrders.CustomerAccountsReceivable,
	|	ARAPByOrders.ForPaymentOverdue,
	|	ARAPByOrders.ToShipOverdue
	|FROM
	|	ARAPByOrders AS ARAPByOrders
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED
	|	SUM(CustomersARAPAccountingBalanceAndTurnovers.SumReceipt) AS DebtIncrease,
	|	SUM(CustomersARAPAccountingBalanceAndTurnovers.SumExpense) AS DebtDecrease,
	|	CustomersARAPAccountingBalanceAndTurnovers.Recorder AS ARAPDocument,
	|	CustomersARAPAccountingBalanceAndTurnovers.SecondPeriod AS Date,
	|	CustomersARAPAccountingBalanceAndTurnovers.ARAPObject,
	|	PRESENTATION(CustomersARAPAccountingBalanceAndTurnovers.Recorder) AS ARAPDocumentPresentation
	|FROM
	|	AccumulationRegister.CustomersARAPAccounting.BalanceAndTurnovers(,, Auto,, ARAPObject IN
	|		(SELECT
	|			ARAPByOrders.SalesOrder
	|		FROM
	|			ARAPByOrders)) AS CustomersARAPAccountingBalanceAndTurnovers
	|GROUP BY
	|	CustomersARAPAccountingBalanceAndTurnovers.Recorder,
	|	CustomersARAPAccountingBalanceAndTurnovers.SecondPeriod,
	|	CustomersARAPAccountingBalanceAndTurnovers.ARAPObject
	|ORDER BY
	|	Date"
	;
	
	Return QueryText
	
EndFunction

// Calculates the period from one day of the week to another.
//
// Parameters:
//  SourceDayNumber - Number - the number of the day of the week from which the deadline is calculated.
//  BillingDayNumber - Number - the number of the day of the week to which you want to calculate the deadline.
//
// Returns:
//  Number - the number of days from one day to the next.
//
Function CalculateTermFromDay(SourceDayNumber, BillingDayNumber)

	If BillingDayNumber > SourceDayNumber Then
		DueDate = BillingDayNumber - SourceDayNumber;
	Else
		DueDate = BillingDayNumber - SourceDayNumber + 7;
	EndIf;

	Return DueDate;

EndFunction

// Generates a table of values containing a list of partner service conditions.
//
// Parameters:
//  SalesRepresentative - CatalogRef.Users - the sales representative for whom the terms of service are selected.
//  InitialPlanningDate - Date - the date from which you want to analyze the need for a session based on the terms of service.
//  PlanningEndDate - Date - the date by which you want to analyze the need for a session under the terms of service.
//
// Returns:
//  ValueTable - a table containing a list of the terms of service of partners, including the dates of the visit according to the schedule.
//
Function GetTermsOfServiceForCreatingTasks(SalesRepresentative, InitialPlanningDate, PlanningEndDate)
	
	Query = New Query();
	Query.Text = GetRequestTextForPartnerTermsOfService();
	
	Query.SetParameter("SalesRepresentative", SalesRepresentative);
	Query.SetParameter("InitialPlanningDate", Max(InitialPlanningDate, BegOfDay(CurrentSessionDate())));
	Query.SetParameter("PlanningEndDate", PlanningEndDate);
	Query.SetParameter("DateEmpty", '00010101000000');
	
	Query.SetParameter("Monday", Enums.WeekDays.Monday);
	Query.SetParameter("Tuesday", Enums.WeekDays.Tuesday);
	Query.SetParameter("Wednesday", Enums.WeekDays.Wednesday);
	Query.SetParameter("Thursday", Enums.WeekDays.Thursday);
	Query.SetParameter("Friday", Enums.WeekDays.Friday);
	Query.SetParameter("Saturday", Enums.WeekDays.Saturday);
	Query.SetParameter("Sunday", Enums.WeekDays.Sunday);
	
	Return Query.Execute().Unload();
	
EndFunction

// Generates the request text according to the partners ' terms of service.
//
// Returns:
//  String - query text.
//
Function GetRequestTextForPartnerTermsOfService()
	
	QueryText = 
	"SELECT ALLOWED
	|	RequestForTermsOfService.Partner,
	|	RequestForTermsOfService.ServiceTerms,
	|	RequestForTermsOfService.Terms,
	|	MIN(RequestForTermsOfService.ScheduledVisitDate) AS ScheduledVisitDate
	|FROM
	|	(SELECT
	|		TermsAndConditionsOfServicesProvidedToCustomersBySalesRepresentativesVisitSchedule.Ref AS ServiceTerms,
	|		TermsAndConditionsOfServicesProvidedToCustomersBySalesRepresentativesVisitSchedule.Ref.Owner AS Partner,
	|		TermsAndConditionsOfServicesProvidedToCustomersBySalesRepresentativesVisitSchedule.Ref.Terms AS Terms,
	|		CASE
	|			WHEN TermsAndConditionsOfServicesProvidedToCustomersBySalesRepresentativesVisitSchedule.WeekDay = &Monday
	|				THEN CASE
	|						WHEN WEEKDAY(&InitialPlanningDate) > 1
	|							THEN DATEADD(&InitialPlanningDate, DAY, 1 - WEEKDAY(&InitialPlanningDate) + 7)
	|						ELSE DATEADD(&InitialPlanningDate, DAY, 1 - WEEKDAY(&InitialPlanningDate))
	|					END
	|			WHEN TermsAndConditionsOfServicesProvidedToCustomersBySalesRepresentativesVisitSchedule.WeekDay = &Tuesday
	|				THEN CASE
	|						WHEN WEEKDAY(&InitialPlanningDate) > 2
	|							THEN DATEADD(&InitialPlanningDate, DAY, 2 - WEEKDAY(&InitialPlanningDate) + 7)
	|						ELSE DATEADD(&InitialPlanningDate, DAY, 2 - WEEKDAY(&InitialPlanningDate))
	|					END
	|			WHEN TermsAndConditionsOfServicesProvidedToCustomersBySalesRepresentativesVisitSchedule.WeekDay = &Wednesday
	|				THEN CASE
	|						WHEN WEEKDAY(&InitialPlanningDate) > 3
	|							THEN DATEADD(&InitialPlanningDate, DAY, 3 - WEEKDAY(&InitialPlanningDate) + 7)
	|						ELSE DATEADD(&InitialPlanningDate, DAY, 3 - WEEKDAY(&InitialPlanningDate))
	|					END
	|			WHEN TermsAndConditionsOfServicesProvidedToCustomersBySalesRepresentativesVisitSchedule.WeekDay = &Thursday
	|				THEN CASE
	|						WHEN WEEKDAY(&InitialPlanningDate) > 4
	|							THEN DATEADD(&InitialPlanningDate, DAY, 4 - WEEKDAY(&InitialPlanningDate) + 7)
	|						ELSE DATEADD(&InitialPlanningDate, DAY, 4 - WEEKDAY(&InitialPlanningDate))
	|					END
	|			WHEN TermsAndConditionsOfServicesProvidedToCustomersBySalesRepresentativesVisitSchedule.WeekDay = &Friday
	|				THEN CASE
	|						WHEN WEEKDAY(&InitialPlanningDate) > 5
	|							THEN DATEADD(&InitialPlanningDate, DAY, 5 - WEEKDAY(&InitialPlanningDate) + 7)
	|						ELSE DATEADD(&InitialPlanningDate, DAY, 5 - WEEKDAY(&InitialPlanningDate))
	|					END
	|			WHEN TermsAndConditionsOfServicesProvidedToCustomersBySalesRepresentativesVisitSchedule.WeekDay = &Saturday
	|				THEN CASE
	|						WHEN WEEKDAY(&InitialPlanningDate) > 6
	|							THEN DATEADD(&InitialPlanningDate, DAY, 6 - WEEKDAY(&InitialPlanningDate) + 7)
	|						ELSE DATEADD(&InitialPlanningDate, DAY, 6 - WEEKDAY(&InitialPlanningDate))
	|					END
	|			WHEN TermsAndConditionsOfServicesProvidedToCustomersBySalesRepresentativesVisitSchedule.WeekDay = &Sunday
	|				THEN CASE
	|						WHEN WEEKDAY(&InitialPlanningDate) > 7
	|							THEN DATEADD(&InitialPlanningDate, DAY, 7 - WEEKDAY(&InitialPlanningDate) + 7)
	|						ELSE DATEADD(&InitialPlanningDate, DAY, 7 - WEEKDAY(&InitialPlanningDate))
	|					END
	|			ELSE &DateEmpty
	|		END AS ScheduledVisitDate
	|	FROM
	|		Catalog.TermsAndConditionsOfServicesProvidedToCustomersBySalesRepresentatives.VisitSchedule AS TermsAndConditionsOfServicesProvidedToCustomersBySalesRepresentativesVisitSchedule
	|	WHERE
	|		(NOT TermsAndConditionsOfServicesProvidedToCustomersBySalesRepresentativesVisitSchedule.Ref.DeletionMark)
	|		AND TermsAndConditionsOfServicesProvidedToCustomersBySalesRepresentativesVisitSchedule.Ref.Owner.ServedBySalesRepresentatives
	|		AND TermsAndConditionsOfServicesProvidedToCustomersBySalesRepresentativesVisitSchedule.Ref.SalesRepresentative = &SalesRepresentative
	|		AND TermsAndConditionsOfServicesProvidedToCustomersBySalesRepresentativesVisitSchedule.Ref.Terms <> VALUE(Catalog.TermsOfSale.EmptyRef)) AS RequestForTermsOfService
	|		LEFT JOIN Document.JobForSalesRepresentative AS JobForSalesRepresentative
	|		ON RequestForTermsOfService.ServiceTerms = JobForSalesRepresentative.ServiceTerms
	|			AND RequestForTermsOfService.ScheduledVisitDate = JobForSalesRepresentative.PlannedVisitDate
	|WHERE
	|	JobForSalesRepresentative.Ref IS NULL 
	|	AND (RequestForTermsOfService.ScheduledVisitDate <= &PlanningEndDate
	|			OR &PlanningEndDate = &DateEmpty)
	|
	|GROUP BY
	|	RequestForTermsOfService.ServiceTerms,
	|	RequestForTermsOfService.Partner,
	|	RequestForTermsOfService.Terms"
	;
	
	Return QueryText;
	
EndFunction

#Region ProceduresForInitializingTermsOfService

// Forms a structure containing data about the terms of service.
//
// Parameters:
// FilterParameters - Structure - contains parameters for selecting terms of service.
//
// Returns:
//  Structure - a structure containing data about the terms of service.
//
Function GetTermsOfServiceData(FilterParameters)
	
	QueryText = 
	"SELECT ALLOWED
	|	TermsAndConditionsOfServicesProvidedToCustomersBySalesRepresentatives.Ref                AS ServiceTerms,
	|	TermsAndConditionsOfServicesProvidedToCustomersBySalesRepresentatives.Terms            AS Terms,
	|	TermsAndConditionsOfServicesProvidedToCustomersBySalesRepresentatives.Supervisor_               AS Supervisor_,
	|	TermsAndConditionsOfServicesProvidedToCustomersBySalesRepresentatives.SalesRepresentative AS SalesRepresentative,
	|	TermsAndConditionsOfServicesProvidedToCustomersBySalesRepresentatives.VisitSchedule.(
	|		Ref,
	|		LineNumber,
	|		WeekDay,
	|		BeginTime,
	|		EndTime
	|	) AS VisitSchedule
	|FROM
	|	Catalog.TermsAndConditionsOfServicesProvidedToCustomersBySalesRepresentatives AS TermsAndConditionsOfServicesProvidedToCustomersBySalesRepresentatives"
	;
	
	QuerySchema = New QuerySchema;
	QuerySchema.SetQueryText(QueryText);
	
	Query = New Query;
	
	Filter = QuerySchema.QueryBatch[0].Operators[0].Filter;
	For Each CurItem In FilterParameters Do
		FilterName = CurItem.Key;
		Filter.Add(FilterName + "=&"+FilterName);
		Query.SetParameter(FilterName, CurItem.Value);
	EndDo;
	
	Query.Text = QuerySchema.GetQueryText();
	
	QueryResult = Query.Execute();
	If QueryResult.IsEmpty() Then
		Return Undefined;
	EndIf;
	
	Selection = QueryResult.Select();
	Selection.Next();
	
	StructureOfData = DescriptionOfTermsOfService();
	FillPropertyValues(StructureOfData, Selection);
	StructureOfData.VisitSchedule = Selection.VisitSchedule.Unload();
	
	SessionStructure_ =
		SalesRepresentativesServer.SessionDetails_(CurrentSessionDate(), StructureOfData.VisitSchedule);
		
	FillPropertyValues(StructureOfData, SessionStructure_);
	
	Return StructureOfData;
	
EndFunction

Function DescriptionOfTermsOfService()
	
	Return New Structure("
		|ServiceTerms,
		|Terms,
		|Supervisor_,
		|SalesRepresentative,
		|VisitSchedule,
		|PlannedVisitDate,
		|BeginTime,
		|EndTime
		|");
		
EndFunction

#EndRegion

#EndRegion
