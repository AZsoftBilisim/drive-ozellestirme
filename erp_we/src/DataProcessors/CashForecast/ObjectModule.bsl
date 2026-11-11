#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Fills in the payment tree
//
// Parameters:
//    CalculationParameters - Structure - Parameters for the calculation, see the parameters of the calculation of the form module calendar.
//
Procedure CalculateCalendarData(CalculationParameters) Export
	
	If CalendarAccountFilter = 2 Then
		Request = Undefined;
		If CalculationParameters.Property("Request", Request) Then
			If ValueIsFilled(Request) Then
				Payments_2 = New ValueList;
				Payments_2.Add(Request);
				BankAccountsOfCheckout = DataProcessors.CashForecast.BankAccountsCashAccountsAvailableForPaymentObject(
					Payments_2, True);
				FilterBankAccountsCashAccounts.LoadValues(BankAccountsOfCheckout);
				FilterBankAccountsCashAccounts.FillChecks(True);
				
				InstallComposerSelectionBySelectionBankAccountsCashAccounts(LinkerSelection, FilterBankAccountsCashAccounts);
			EndIf;
		EndIf;
	EndIf;
	
	DCS = GetTemplate("PaymentTree");
	SettingsOption = DCS.DefaultSettings;
	
	AddDaysColumns(DCS, SettingsOption);
	AddLongTermPlanningColumns(DCS, SettingsOption);
	
	// Configuring the Grouping Resource
	
	ResourceGrouping = DCS.TotalFields.Find("Group");
	
	CashAccountBankExpression = "WHEN EvalExpression(1, ""CashAccountBank"") = 1 THEN CashAccountBank";
	CashTypeExpression = "WHEN EvalExpression(1, ""CashType"") = 1 THEN CashType";
	ExpressionCompany = "WHEN EvalExpression(1, ""Organization"") = 1 THEN Organization";
	
	CashAccountBankLevel = ReportDimensions.FindByValue("CashAccountBank");
	LevelCompany = ReportDimensions.FindByValue("Organization");
	CashTypeLevel = ReportDimensions.FindByValue("CashType");
	
	If LevelCompany = Undefined Then
		ThereIsOrderBankCompany = False;
		ThereIsOrderTypeOfCashCompany = False;
	Else
		ThereIsOrderBankCompany = (CashAccountBankLevel.Check And LevelCompany.Check
			And ReportDimensions.IndexOf(CashAccountBankLevel) < ReportDimensions.IndexOf(LevelCompany));
			
		ThereIsOrderTypeOfCashCompany = (CashTypeLevel.Check And LevelCompany.Check
			And ReportDimensions.IndexOf(CashTypeLevel) < ReportDimensions.IndexOf(LevelCompany));
	EndIf;
	
	If ThereIsOrderBankCompany Then
		ResourceGrouping.Expression = StrReplace(ResourceGrouping.Expression, CashAccountBankExpression, "ExpressionCompany");
		ResourceGrouping.Expression = StrReplace(ResourceGrouping.Expression, ExpressionCompany, "CashAccountBankExpression");
		ResourceGrouping.Expression = StrReplace(ResourceGrouping.Expression, "ExpressionCompany", ExpressionCompany);
		ResourceGrouping.Expression = StrReplace(ResourceGrouping.Expression, "CashAccountBankExpression", CashAccountBankExpression);
	EndIf;
	
	If ThereIsOrderTypeOfCashCompany Then
		ResourceGrouping.Expression = StrReplace(ResourceGrouping.Expression, CashTypeExpression, "ExpressionCompany");
		ResourceGrouping.Expression = StrReplace(ResourceGrouping.Expression, ExpressionCompany, "CashTypeExpression");
		ResourceGrouping.Expression = StrReplace(ResourceGrouping.Expression, "ExpressionCompany", ExpressionCompany);
		ResourceGrouping.Expression = StrReplace(ResourceGrouping.Expression, "CashTypeExpression", CashTypeExpression);
	EndIf;
	
	AvailableSettingsSource = New DataCompositionAvailableSettingsSource(DCS);
	Composer = New DataCompositionSettingsComposer;
	Composer.Initialize(AvailableSettingsSource);
	Composer.LoadSettings(SettingsOption);
	
	DataCompositionClientServer.CopyElements(Composer.Settings.Filter, LinkerSelection.Settings.Filter);
	
	FillInLayoutParameters(Composer.Settings.DataParameters);
	
	// Configuring the report structure
	
	LevelCurrency = ReportDimensions.FindByValue("Currency");
	CompanyLevelIsSet = ?(LevelCompany = Undefined, False, LevelCompany.Check);
	CurrencyLevelIsSet = ?(LevelCurrency = Undefined, False, LevelCurrency.Check);

	RootElementOfStructure = Composer.Settings.Structure;
	
	If Not (CompanyLevelIsSet Or CurrencyLevelIsSet) Then
	
		DCSGrouping = AddRowNotDistributed(RootElementOfStructure,
							Enums.CashFlowTypes.Inpayment);
		RootElementOfStructure.Move(DCSGrouping, -1);
		
		DCSGrouping = AddRowNotDistributed(RootElementOfStructure,
							Enums.CashFlowTypes.WriteOff);
		RootElementOfStructure.Move(DCSGrouping, -1);
	EndIf;
	
	DCSGrouping = Undefined;
	For Each Item In ReportDimensions Do
		
		If Not Item.Check Then
			Continue;
		EndIf;
		
		NameOfDimensionField = ?(Item.Value = "Currency", "CurrencyBalance", Item.Value);
		
		If DCSGrouping = Undefined Then
			DCSGrouping = FinancialReportingServer.NewGrouping(RootElementOfStructure, NameOfDimensionField);
			RootElementOfStructure.Move(DCSGrouping, -1);
		Else
			DCSGrouping = FinancialReportingServer.NewGrouping(DCSGrouping, NameOfDimensionField);
		EndIf;
		
		If Item.Value = "BankAccountCashAccount" Then
			FinancialReportingServer.NewDimensionField(DCSGrouping, "SeparateSDOAccount");
			FinancialReportingServer.NewDimensionField(DCSGrouping, "CashType");
			FinancialReportingServer.NewOrder(DCSGrouping, "OrderValue");
		EndIf;
		
		FinancialReportingServer.NewDimensionField(DCSGrouping, "Currency");
		FinancialReportingServer.SetFilter(DCSGrouping.Filter, NameOfDimensionField,,
			DataCompositionComparisonType.Filled);
		FinancialReportingServer.NewOrder(DCSGrouping, NameOfDimensionField);
			
		// The parameter "Zero Balances and revolutions"
		
		OrGroup1 = FinancialReportingServer.NewFilter(DCSGrouping.Filter, Undefined,,
			Type("DataCompositionFilterItemGroup"));
		OrGroup1.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
		OrGroup1.Use = True;
		
		ParameterZeroBalancesAndRevolutions = New DataCompositionField("DataParameters.ZeroBalancesAndTurnover");
		
		FinancialReportingServer.SetFilter(OrGroup1, ParameterZeroBalancesAndRevolutions, True);
		
		AndGroup = FinancialReportingServer.NewFilter(OrGroup1, Undefined,,
			Type("DataCompositionFilterItemGroup"));
		AndGroup.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
		AndGroup.Use = True;
		
		FinancialReportingServer.SetFilter(AndGroup, ParameterZeroBalancesAndRevolutions, False);
		
		OrGroup2 = FinancialReportingServer.NewFilter(AndGroup, Undefined,,
			Type("DataCompositionFilterItemGroup"));
		OrGroup2.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
		OrGroup2.Use = True;
		
		FinancialReportingServer.SetFilter(OrGroup2, "BalanceAndIrreducibleBalance", 0,
			DataCompositionComparisonType.NotEqual);
		FinancialReportingServer.SetFilter(OrGroup2, "Turnover", 0, DataCompositionComparisonType.NotEqual);
			
		If (Item.Value = "Currency")
			Or (Item.Value = "Organization" And Not CurrencyLevelIsSet) Then
			AddRowNotDistributed(DCSGrouping, Enums.CashFlowTypes.Inpayment);
			AddRowNotDistributed(DCSGrouping, Enums.CashFlowTypes.WriteOff);
		EndIf;
	EndDo;
	
	If Not DCSGrouping = Undefined Then
		DCSGrouping = FinancialReportingServer.NewGrouping(DCSGrouping, "ReceiptIssue");
		FinancialReportingServer.SetFilter(DCSGrouping.Filter, "ReceiptIssue",,
			DataCompositionComparisonType.Filled);
	EndIf;
	
	DCSTemplate = FinancialReportingServer.PrepareLayoutTemplateForUploadingDCS(DCS, Composer);
	
	SetPrivilegedMode(True);
	InformationRegisters.ScheduleOfPayments.CalculatePaymentScheduleForReceiptsFromBankForAcquiring();
	SetPrivilegedMode(False);
	
	PaymentTree = FinancialReportingServer.UploadDCSResultsFromTemplate(DCSTemplate,, True);
	
	For Each TreeRow In PaymentTree.Rows Do
		CashClientServer.RecalculateSubordinateTreeRows(TreeRow, PlanningDays);
		DataProcessors.CashForecast.RecalculateLongTermPeriodsInSubordinateRowsOfTree(TreeRow,
			LongTermPlanningPeriods, PlanningDays);
	EndDo;
	
EndProcedure

#EndRegion

#Region Private

Procedure AddDaysColumns(DCS, Settings)
	
	FieldExpressionTemplate = "
	|CASE WHEN PaymentDate = DATEADD(&CurrentDate, ""Day"", %1 - 1) THEN
	|	%2
	|ELSE 0 END";
	
	FieldExpressionTemplateHasError = "
	|CASE WHEN PaymentDate = DATEADD(&CurrentDate, ""Day"", %1 - 1) THEN
	|	%2
	|ELSE FALSE END";
	
	ExpressionFields = New Map;
	ExpressionFields.Insert("Turnover", "InCurrency");
	ExpressionFields.Insert("TurnoverInOneCurrency", "InOneCurrency");
	
	ExpressionFieldsHaveError = New Array;
	ExpressionFieldsHaveError.Add("ThereIsErrorApplicationWasNotCreated");
	ExpressionFieldsHaveError.Add("ThereIsInitialPaymentDateLessThanRescheduledOne");
	ExpressionFieldsHaveError.Add("ThereIsDifferenceBetweenPaymentCurrencyAndCashAccountAccount");
	
	For Indus = 0 To PlanningDays Do
		
		DataPath = "Day" + String(Indus);
		
		NewDay = FinancialReportingServer.NewCalculatedResource(DCS, DataPath, "1-1", "Sum");
		FinancialReportingServer.NewSelectionField(Settings, NewDay.DataPath);
		
		For Each Field In ExpressionFields Do
		
			FieldExpression = StrTemplate(FieldExpressionTemplate, Indus, Field.Key);
			NewDaySum = FinancialReportingServer.NewCalculatedResource(DCS, DataPath + Field.Value,
				FieldExpression, "Sum",
				"ISNULL(SUM(" + FieldExpression + "), 0)");
			FinancialReportingServer.NewSelectionField(Settings, NewDaySum.DataPath);
		EndDo;
		
		NewDayErrorCriticalBalance = FinancialReportingServer.NewCalculatedResource(DCS,
			DataPath + "ErrorCriticalBalance", "FALSE");
		FinancialReportingServer.NewSelectionField(Settings, NewDayErrorCriticalBalance.DataPath);
		
		For Each Field In ExpressionFieldsHaveError Do

			FieldExpression = StrTemplate(FieldExpressionTemplateHasError, Indus, Field);
			NewDayThereIsMistake = FinancialReportingServer.NewCalculatedResource(DCS, DataPath + Field,
				FieldExpression,, "MAX(" + FieldExpression + ")");
			FinancialReportingServer.NewSelectionField(Settings, NewDayThereIsMistake.DataPath);
		EndDo;
	EndDo;
	
EndProcedure

Procedure AddLongTermPlanningColumns(DCS, Settings)
	
	FieldExpressionTemplate = "
	|CASE
	|	WHEN PaymentDate = DATEADD(BEGINOFPERIOD(&CurrentDate, ""%1""), ""%1"", %2)
	|	THEN %3
	|	ELSE 0
	|END";
	
	FieldExpressionTemplateHasError = "
	|CASE
	|	WHEN PaymentDate = DATEADD(BEGINOFPERIOD(&CurrentDate, ""%1""), ""%1"", %2)
	|	THEN %3
	|	ELSE FALSE
	|END";
	
	ExpressionFields = New Map;
	ExpressionFields.Insert("Turnover", "InCurrency");
	ExpressionFields.Insert("TurnoverInOneCurrency", "InOneCurrency");
	
	ExpressionFieldsHaveError = New Array;
	ExpressionFieldsHaveError.Add("ThereIsErrorApplicationWasNotCreated");
	ExpressionFieldsHaveError.Add("ThereIsInitialPaymentDateLessThanRescheduledOne");
	ExpressionFieldsHaveError.Add("ThereIsDifferenceBetweenPaymentCurrencyAndCashAccountAccount");
	
	For Indus = 1 To LongTermPlanningPeriods Do
		
		DataPath = "LongTermPeriod" + String(Indus);
		
		NewLongTermPeriod = FinancialReportingServer.NewCalculatedResource(DCS,
			DataPath,
			"1-1",
			"Sum");
		FinancialReportingServer.NewSelectionField(Settings, NewLongTermPeriod.DataPath);

		For Each Field In ExpressionFields Do
			
			FieldExpression = StrTemplate(FieldExpressionTemplate, String(LongTermPlanningTimeFence), Indus, Field.Key);
			NewLongTermPeriodAmount = FinancialReportingServer.NewCalculatedResource(DCS,
				DataPath + Field.Value,
				FieldExpression,
				"Sum",
				"ISNULL(SUM(" + FieldExpression + "), 0)");
			FinancialReportingServer.NewSelectionField(Settings, NewLongTermPeriodAmount.DataPath);
		EndDo;
		
		NewLongTermPeriodErrorCriticalBalance = FinancialReportingServer.NewCalculatedResource(DCS,
			DataPath + "ErrorCriticalBalance", "FALSE");
		FinancialReportingServer.NewSelectionField(Settings, NewLongTermPeriodErrorCriticalBalance.DataPath);
		
		For Each Field In ExpressionFieldsHaveError Do
		
			FieldExpression = StrTemplate(FieldExpressionTemplateHasError, String(LongTermPlanningTimeFence), Indus,
				Field);
			NewDayThereIsMistake = FinancialReportingServer.NewCalculatedResource(DCS, DataPath + Field,
				FieldExpression,, "MAX(" + FieldExpression + ")");
			FinancialReportingServer.NewSelectionField(Settings, NewDayThereIsMistake.DataPath);
		EndDo;
	EndDo;
	
EndProcedure

Procedure FillInLayoutParameters(DataParameters) Export
	
	FinancialReportingServer.SetParameter(DataParameters, "CurrentDate", PlanFromDate);
	FinancialReportingServer.SetParameter(DataParameters, "EndingDate", EndDate);
	FinancialReportingServer.SetParameter(DataParameters, "EndDateOfPlanningByDay",
		EndDateOfPlanningByDay);
	FinancialReportingServer.SetParameter(DataParameters, "LongTermPlanningTimeFence",
		LongTermPlanningTimeFence);
	FinancialReportingServer.SetParameter(DataParameters, "ZeroBalancesAndTurnover", ZeroBalancesAndTurnover);
	StartDateForDisplayingOverduePayments = DataProcessors.CashForecast.StartDateForDisplayingOverduePayments(
		PlanFromDate, DepthOfDisplayOfOverduePayments);
	FinancialReportingServer.SetParameter(DataParameters, "StartDateForDisplayingOverduePayments",
		StartDateForDisplayingOverduePayments);
	FinancialReportingServer.SetParameter(DataParameters, "CashAccounts", NStr("vi = 'Quỹ tiền mặt';
																				|ru = 'Кассы';
																				|en = 'Cash accounts'; fa = 'صندوق‌ها';
																				|it = 'Cash accounts';
																				|pl = 'Cash accounts';
																				|tr = 'Kasa hesapları'"));
	
	FinancialReportingServer.SetParameter(DataParameters, "TotalCurrency", TotalCurrency);
	
	PlanningAreas = PlanningAreas();
	FinancialReportingServer.SetParameter(DataParameters, "PlanningAreas", PlanningAreas);
	FinancialReportingServer.SetParameter(DataParameters, "DoNotFilterByPlanningAreas",
		Not PlanningAreas.Count());
	
EndProcedure

Function PlanningAreas() Export
	
	PlanningAreas = New Array;
	
	UseLoanAndDepositContracts = GetFunctionalOption("UseLoanAndDepositContracts");
	VNAManagementIsUsed = NonCurrentAssets.VNAManagementIsUsed();
	LoansOrBorrowingsReceivedInclude = (LoansOrBorrowingsReceived And UseLoanAndDepositContracts
		Or Not LoansOrBorrowingsReceived And Not UseLoanAndDepositContracts);
	DepositsInclude = (Deposits And UseLoanAndDepositContracts
		Or Not Deposits And Not UseLoanAndDepositContracts);
	LoansIssuedInclude = (IssuedBorrowings And UseLoanAndDepositContracts
		Or Not IssuedBorrowings And Not UseLoanAndDepositContracts);
	LeasingInclude = (Lease And VNAManagementIsUsed
		Or Not Lease And Not VNAManagementIsUsed);
	ThereIsSelectionOfAreas = Not (SalesOrders And PurchaseOrders And ReturnsToCustomers And ReturnsFromVendors And RequestsPendingApproval And PlannedCashReceipts
		And LeasingInclude
		And LoansOrBorrowingsReceivedInclude And DepositsInclude And LoansIssuedInclude);
		
	If ThereIsSelectionOfAreas Then
		
		PlanningAreas.Add(Enums.PaymentPlanningAreas.CashPaymentRequests);
		PlanningAreas.Add(Enums.PaymentPlanningAreas.ReferencesForCashTransfer);
		PlanningAreas.Add(Enums.PaymentPlanningAreas.CashInTransit);
		
		If RequestsPendingApproval Then
			PlanningAreas.Add(Enums.PaymentPlanningAreas.PaymentRequestsPendingApproval);
			PlanningAreas.Add(Enums.PaymentPlanningAreas.ReferencesForCashTransferPendingApproval);
		EndIf;
		
		If PlannedCashReceipts Then
			PlanningAreas.Add(Enums.PaymentPlanningAreas.PlannedCashReceipts);
		EndIf;
		
		If SalesOrders Then
			PlanningAreas.Add(Enums.PaymentPlanningAreas.CustomersARAPAccounting);
		EndIf;
		If PurchaseOrders Then
			PlanningAreas.Add(Enums.PaymentPlanningAreas.VendorsARAPAccounting);
		EndIf;
		If ReturnsToCustomers Then
			PlanningAreas.Add(Enums.PaymentPlanningAreas.ReturnsToCustomers);
		EndIf;
		If ReturnsFromVendors Then
			PlanningAreas.Add(Enums.PaymentPlanningAreas.ReturnsFromVendors);
		EndIf;
		
		If LoansOrBorrowingsReceived Then
			PlanningAreas.Add(Enums.PaymentPlanningAreas.LoansOrBorrowingsReceived);
		EndIf;
		If Deposits Then
			PlanningAreas.Add(Enums.PaymentPlanningAreas.Deposits);
		EndIf;
		If IssuedBorrowings Then
			PlanningAreas.Add(Enums.PaymentPlanningAreas.IssuedBorrowings);
		EndIf;
		If Lease Then
			PlanningAreas.Add(Enums.PaymentPlanningAreas.Lease);
		EndIf;
	EndIf;
	
	Return PlanningAreas;
	
EndFunction

Function AddRowNotDistributed(DCStructure, TypeOfRegisteredRecordsOfFunds)
	
	If TypeOfRegisteredRecordsOfFunds = Enums.CashFlowTypes.Inpayment Then
		NameOfDimensionField = "RevenueNotDistributed";
	ElsIf TypeOfRegisteredRecordsOfFunds = Enums.CashFlowTypes.WriteOff Then
		NameOfDimensionField = "WriteOffsNotAllocated";
	Else
		Return Undefined;
	EndIf;

	Group = FinancialReportingServer.NewGrouping(DCStructure, NameOfDimensionField);
	FinancialReportingServer.NewDimensionField(Group, "ReceiptIssue");
	FinancialReportingServer.NewDimensionField(Group, "Currency");
	
	FinancialReportingServer.SetFilter(Group.Filter, "BankAccountCashAccount");
	FinancialReportingServer.SetFilter(Group.Filter, "ReceiptIssue", TypeOfRegisteredRecordsOfFunds);
	FinancialReportingServer.SetFilter(Group.Filter, "Currency",,
		DataCompositionComparisonType.Filled);
		
	Return Group;
	
EndFunction

#Region SettingsAndSelections

Procedure InstallComposerSelectionBySelectionBankAccountsCashAccounts(LinkerSelection, Val FilterBankAccountsCashAccounts)

	BankAccountsCashAccounts = New ValueList;
	For Each FilterElement In FilterBankAccountsCashAccounts Do
		If FilterElement.Check Then
			BankAccountsCashAccounts.Add(FilterElement.Value);
		EndIf;
	EndDo;
	
	ListIsNotEmpty = (BankAccountsCashAccounts.Count() > 0);
	SetSelectionWithoutSearchingInGroups(LinkerSelection.Settings.Filter, "BankAccountCashAccount", BankAccountsCashAccounts,,
		ListIsNotEmpty);

EndProcedure

// Sets a new selection in the passed selection of the data layout scheme.
//
// Parameters:
//  FilterDQ - DataCompositionFilter - the selection of the layout in which you want to add a new item.
//  LeftValue - String, DataCompositionField - the layout field for which you want to set the selection.
//  RightValue  - Arbitrary - the value of the selection (optional).
//  Var_ComparisonType  - DataCompositionComparisonType - data layout comparison view (optional).
//  Use  - Boolean - using a new selection element (optional, True by default).
//
Procedure SetSelectionWithoutSearchingInGroups(FilterDQ, LeftValue, RightValue = Undefined,
	Var_ComparisonType = Undefined, Use = True)
	
	FilterElement = FindSelectionItemWithoutSearchingInGroupsEqualToInList(FilterDQ, LeftValue);
	If FilterElement = Undefined Then
		FilterElement = FinancialReportingServer.NewFilter(FilterDQ, LeftValue, RightValue);
	EndIf;
	FilterElement.Use = Use;
	If Var_ComparisonType <> Undefined Then
		FilterElement.ComparisonType = Var_ComparisonType;
	EndIf;
	If Use Then
		FilterElement.RightValue = RightValue;
	EndIf;
	
EndProcedure

// Returns a reference to the selection element in the passed selection of the data layout schema.
//
// Parameters:
//  FilterDQ - DataCompositionFilter - the selection of the layout in which you want to add a new item.
//  TagName - String - name of the layout field to use to find the selection element.
//
// Returns:
//   DataCompositionFilterItem - a link to the found selection element of the data layout scheme.
//
Function FindSelectionItemWithoutSearchingInGroupsEqualToInList(FilterDQ, TagName)
	
	Result = Undefined;
	For Each FilterElement In FilterDQ.Items Do
		If TypeOf(FilterElement) <> Type("DataCompositionFilterItemGroup")
			And FilterElement.LeftValue = New DataCompositionField(TagName) Then
			If FilterElement.ComparisonType = DataCompositionComparisonType.Equal
				Or FilterElement.ComparisonType = DataCompositionComparisonType.InList Then
				Result = FilterElement;
				Break;
			EndIf;
		EndIf;
	EndDo;
	Return Result;
	
EndFunction

#EndRegion

#EndRegion

#EndIf